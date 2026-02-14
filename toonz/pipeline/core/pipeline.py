"""Main animation pipeline orchestrator."""

import json
from pathlib import Path
from typing import Optional, Callable, Dict, List, Union

from .config import Config
from .utils import ensure_dir, load_json, save_json
from ..lipsync.rhubarb import RhubarbWrapper, LipSyncData, RhubarbError
from ..animation.character import Character, CharacterRig
from ..animation.scene import Scene, SceneLayer
from ..animation.keyframes import AnimationClip, EasingType
from ..renderers.base import BaseRenderer, RenderProgress
from ..renderers.direct_renderer import DirectRenderer, PreviewRenderer
from ..renderers.ffmpeg_renderer import FFmpegRenderer


class AnimationPipeline:
    """Main orchestrator for the animation pipeline.

    The AnimationPipeline provides a high-level API for:
    - Loading and managing project configuration
    - Generating lip sync data from audio
    - Creating and animating characters
    - Composing scenes with layers
    - Rendering to video or frame sequences

    Usage:
        # Initialize pipeline
        pipeline = AnimationPipeline("/path/to/project")

        # Generate lip sync from audio
        lipsync = pipeline.generate_lipsync("audio/narration.wav")

        # Load character
        character = pipeline.load_character("characters/narrator")
        character.apply_lipsync(lipsync, fps=30)

        # Create scene
        scene = pipeline.create_scene("intro", duration=30.0)
        scene.add_layer("background", image_path="backgrounds/office.png")
        scene.add_character_layer("narrator", character)

        # Render
        pipeline.render(scene, "output/intro.mp4")
    """

    def __init__(self, project_dir: str):
        """Initialize animation pipeline.

        Args:
            project_dir: Path to project directory
        """
        self.project_dir = Path(project_dir).resolve()
        self.config = Config.load(str(self.project_dir))

        # Initialize tools
        self.rhubarb = RhubarbWrapper(self.config.rhubarb.executable)

        # Cache
        self._characters: Dict[str, Character] = {}
        self._lipsync_cache: Dict[str, LipSyncData] = {}

    def setup_project(self) -> None:
        """Create project directory structure."""
        self.config.ensure_directories()

        # Create additional directories
        assets_path = self.config.get_assets_path()
        (assets_path / "characters").mkdir(exist_ok=True)
        (assets_path / "backgrounds").mkdir(exist_ok=True)
        (assets_path / "audio").mkdir(exist_ok=True)

    def generate_lipsync(
        self,
        audio_path: str,
        transcript_path: Optional[str] = None,
        cache: bool = True,
        on_progress: Optional[Callable[[float], None]] = None
    ) -> LipSyncData:
        """Generate lip sync data from audio.

        Args:
            audio_path: Path to audio file (relative to project or absolute)
            transcript_path: Optional path to transcript file
            cache: Whether to cache/reuse results
            on_progress: Progress callback (0.0 to 1.0)

        Returns:
            LipSyncData with mouth cues
        """
        # Resolve paths
        audio_path = self._resolve_path(audio_path)
        if transcript_path:
            transcript_path = self._resolve_path(transcript_path)

        # Check cache
        cache_key = str(audio_path)
        if cache and cache_key in self._lipsync_cache:
            return self._lipsync_cache[cache_key]

        # Check for cached file
        cache_file = self.config.get_cache_path() / f"{Path(audio_path).stem}_lipsync.json"
        if cache and cache_file.exists():
            lipsync = LipSyncData.load(str(cache_file))
            self._lipsync_cache[cache_key] = lipsync
            return lipsync

        # Generate lip sync
        try:
            lipsync = self.rhubarb.analyze(
                audio_path,
                transcript_path,
                extended_shapes=self.config.rhubarb.extended_shapes,
                recognizer=self.config.rhubarb.recognizer,
                on_progress=on_progress
            )

            # Cache result
            if cache:
                self.config.get_cache_path().mkdir(parents=True, exist_ok=True)
                lipsync.save(str(cache_file))
                self._lipsync_cache[cache_key] = lipsync

            return lipsync

        except RhubarbError as e:
            raise RuntimeError(f"Lip sync generation failed: {e}")

    def load_character(
        self,
        path: str,
        position: tuple = (0, 0),
        scale: float = 1.0,
        name: str = None
    ) -> Character:
        """Load a character from assets.

        Args:
            path: Path to character directory or rig file (relative to assets)
            position: Initial position
            scale: Scale factor
            name: Optional instance name

        Returns:
            Character instance
        """
        # Resolve path
        full_path = self._resolve_asset_path(path)

        # Load rig
        if full_path.is_dir():
            # Auto-detect from directory
            rig_file = full_path / "character.json"
            if rig_file.exists():
                rig = CharacterRig.load(str(rig_file))
            else:
                rig = CharacterRig.create_from_directory(str(full_path))
        else:
            # Load from file
            rig = CharacterRig.load(str(full_path))

        # Create character instance
        character = Character(rig, position=position, scale=scale, name=name)

        # Cache
        self._characters[character.name] = character

        return character

    def create_scene(
        self,
        name: str = "untitled",
        duration: float = None,
        width: int = None,
        height: int = None,
        fps: float = None,
        background_color: tuple = None
    ) -> Scene:
        """Create a new scene.

        Uses project configuration for default values.

        Args:
            name: Scene name
            duration: Duration in seconds
            width: Width in pixels
            height: Height in pixels
            fps: Frames per second
            background_color: RGBA background color

        Returns:
            Scene instance
        """
        return Scene(
            name=name,
            width=width or self.config.output.width,
            height=height or self.config.output.height,
            fps=fps or self.config.output.fps,
            duration=duration or 10.0,
            background_color=background_color or (0, 0, 0, 255)
        )

    def render(
        self,
        scene: Scene,
        output_path: str = None,
        format: str = None,
        quality: str = None,
        renderer: BaseRenderer = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render scene to output.

        Args:
            scene: Scene to render
            output_path: Output path (default: output directory)
            format: Output format (mp4, webm, png, etc.)
            quality: Quality preset (low, medium, high, lossless)
            renderer: Custom renderer (optional)
            on_progress: Progress callback

        Returns:
            Path to rendered output
        """
        # Determine output path
        if output_path is None:
            format = format or self.config.output.format
            output_path = self.config.get_output_path() / f"{scene.name}.{format}"
        else:
            output_path = Path(output_path)
            if not output_path.is_absolute():
                output_path = self.config.get_output_path() / output_path

        # Create output directory
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Determine format
        format = format or output_path.suffix.lstrip('.') or self.config.output.format
        quality = quality or self.config.output.quality

        # Select renderer
        if renderer is None:
            if format in ('png', 'jpg', 'jpeg', 'tiff', 'bmp'):
                renderer = DirectRenderer(format=format)
            else:
                renderer = FFmpegRenderer(
                    codec=self.config.output.codec,
                    quality=quality
                )

        # Render
        return renderer.render(scene, str(output_path), on_progress)

    def render_preview(
        self,
        scene: Scene,
        output_path: str = None,
        scale: float = 0.5,
        skip_frames: int = 1,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render a quick preview of the scene.

        Args:
            scene: Scene to render
            output_path: Output path
            scale: Scale factor (0.5 = half resolution)
            skip_frames: Skip every N frames
            on_progress: Progress callback

        Returns:
            Path to preview output
        """
        if output_path is None:
            output_path = self.config.get_output_path() / "preview" / scene.name

        renderer = PreviewRenderer(scale=scale, skip_frames=skip_frames)
        return renderer.render(scene, str(output_path), on_progress)

    def create_character_animation(
        self,
        character: Character,
        audio_path: str,
        transcript_path: Optional[str] = None,
        add_blinks: bool = True,
        blink_interval: tuple = (60, 180)
    ) -> Scene:
        """Create a complete character animation from audio.

        Convenience method that:
        1. Generates lip sync
        2. Applies lip sync to character
        3. Adds random blinks
        4. Creates scene with character

        Args:
            character: Character to animate
            audio_path: Path to audio file
            transcript_path: Optional transcript for better accuracy
            add_blinks: Whether to add random blinks
            blink_interval: Min/max frames between blinks

        Returns:
            Scene with animated character
        """
        # Generate lip sync
        lipsync = self.generate_lipsync(audio_path, transcript_path)

        # Apply to character
        fps = self.config.output.fps
        character.apply_lipsync(lipsync, fps=fps)

        # Add blinks
        if add_blinks:
            total_frames = int(lipsync.duration * fps)
            character.add_random_blinks(total_frames, blink_interval)

        # Create scene
        scene = self.create_scene(
            name=f"{character.name}_animation",
            duration=lipsync.duration
        )

        # Add character
        scene.add_character_layer(character.name, character, z_order=10)

        # Set audio
        scene.set_audio(self._resolve_path(audio_path))

        return scene

    def load_project(self, project_path: str) -> Dict:
        """Load a .charproj project file.

        Args:
            project_path: Path to project file

        Returns:
            Project data dictionary
        """
        return load_json(project_path)

    def render_project(
        self,
        project_path: str,
        output_path: str = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render a complete .charproj project file.

        Args:
            project_path: Path to project file
            output_path: Output path (optional)
            on_progress: Progress callback

        Returns:
            Path to rendered output
        """
        project = self.load_project(project_path)

        # Create scene from project
        scene = Scene(
            name=project.get("name", "project"),
            width=project.get("width", self.config.output.width),
            height=project.get("height", self.config.output.height),
            fps=project.get("fps", self.config.output.fps),
            duration=project.get("duration", 10.0)
        )

        # Load background
        if project.get("background"):
            bg_path = self._resolve_path(project["background"])
            scene.add_layer("background", image_path=bg_path, z_order=0)

        # Load characters
        for char_data in project.get("characters", []):
            char_path = char_data.get("rig")
            if char_path:
                character = self.load_character(
                    char_path,
                    position=tuple(char_data.get("position", [0, 0])),
                    scale=char_data.get("scale", 1.0)
                )

                # Apply lip sync if enabled
                if char_data.get("lipsync") and project.get("audio"):
                    lipsync = self.generate_lipsync(
                        project["audio"],
                        project.get("transcript")
                    )
                    character.apply_lipsync(lipsync, fps=scene.fps)

                scene.add_character_layer(
                    character.name,
                    character,
                    z_order=10
                )

        # Set audio
        if project.get("audio"):
            scene.set_audio(self._resolve_path(project["audio"]))

        # Render
        if output_path is None:
            output_config = project.get("output", {})
            fmt = output_config.get("format", self.config.output.format)
            output_path = self.config.get_output_path() / f"{scene.name}.{fmt}"

        return self.render(
            scene,
            str(output_path),
            format=project.get("output", {}).get("format"),
            quality=project.get("output", {}).get("quality"),
            on_progress=on_progress
        )

    def _resolve_path(self, path: str) -> str:
        """Resolve a path relative to project directory."""
        p = Path(path)
        if p.is_absolute():
            return str(p)
        return str(self.project_dir / path)

    def _resolve_asset_path(self, path: str) -> Path:
        """Resolve a path relative to assets directory."""
        p = Path(path)
        if p.is_absolute():
            return p
        return self.config.get_assets_path() / path


def create_project(
    path: str,
    name: str = "New Project",
    width: int = 1920,
    height: int = 1080,
    fps: float = 30.0
) -> AnimationPipeline:
    """Create a new animation project.

    Args:
        path: Project directory path
        name: Project name
        width: Output width
        height: Output height
        fps: Frames per second

    Returns:
        Initialized AnimationPipeline
    """
    from .config import Config, OutputConfig

    project_dir = Path(path)
    project_dir.mkdir(parents=True, exist_ok=True)

    # Create config
    config = Config(
        name=name,
        project_dir=str(project_dir),
        output=OutputConfig(
            width=width,
            height=height,
            fps=fps
        )
    )
    config.save()

    # Create and setup pipeline
    pipeline = AnimationPipeline(str(project_dir))
    pipeline.setup_project()

    return pipeline
