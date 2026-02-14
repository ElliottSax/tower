"""Scene composition for animation pipeline."""

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union
from PIL import Image

from .character import Character, CharacterRig
from .keyframes import KeyframeTrack, AnimationClip, EasingType


@dataclass
class SceneLayer:
    """A layer in the scene (background, character, overlay, etc.).

    Layers are composited in order of their z_order value.
    """
    name: str
    z_order: int = 0
    visible: bool = True
    opacity: float = 1.0
    position: Tuple[int, int] = (0, 0)
    scale: float = 1.0
    rotation: float = 0.0

    # Content (one of these should be set)
    image_path: Optional[str] = None
    character: Optional[Character] = None
    color: Optional[Tuple[int, int, int, int]] = None  # Solid color fill

    # Animation
    animation: Optional[AnimationClip] = None

    # Cached image
    _cached_image: Optional[Image.Image] = field(default=None, repr=False)

    def get_animated_properties(self, frame: int) -> dict:
        """Get animated property values at a specific frame."""
        props = {
            "position": self.position,
            "scale": self.scale,
            "rotation": self.rotation,
            "opacity": self.opacity,
            "visible": self.visible
        }

        if self.animation:
            for prop_name in props.keys():
                value = self.animation.get_value(prop_name, frame)
                if value is not None:
                    props[prop_name] = value

        return props

    def load_image(self) -> Optional[Image.Image]:
        """Load and cache the layer image."""
        if self._cached_image:
            return self._cached_image

        if self.image_path:
            try:
                self._cached_image = Image.open(self.image_path).convert('RGBA')
                return self._cached_image
            except (FileNotFoundError, IOError):
                return None

        return None

    def render(self, frame: int, canvas_size: Tuple[int, int]) -> Optional[Image.Image]:
        """Render this layer at a specific frame.

        Args:
            frame: Frame number to render
            canvas_size: Size of the output canvas

        Returns:
            Layer image composited at correct position, or None if invisible
        """
        props = self.get_animated_properties(frame)

        if not props["visible"] or props["opacity"] <= 0:
            return None

        # Create layer image
        layer_image = None

        if self.character:
            # Render character
            self.character.position = props["position"]
            self.character.scale = props["scale"]
            self.character.opacity = props["opacity"]
            layer_image = self.character.render_frame(frame, canvas_size)

        elif self.image_path:
            # Static or animated image
            base_image = self.load_image()
            if base_image:
                layer_image = base_image.copy()

        elif self.color:
            # Solid color fill
            layer_image = Image.new('RGBA', canvas_size, self.color)

        if layer_image is None:
            return None

        # Apply transformations
        if props["scale"] != 1.0 and not self.character:  # Character handles its own scaling
            new_size = (
                int(layer_image.width * props["scale"]),
                int(layer_image.height * props["scale"])
            )
            layer_image = layer_image.resize(new_size, Image.Resampling.LANCZOS)

        if props["rotation"] != 0:
            layer_image = layer_image.rotate(
                -props["rotation"],  # PIL uses opposite rotation direction
                expand=True,
                resample=Image.Resampling.BICUBIC
            )

        if props["opacity"] < 1.0:
            # Apply opacity
            alpha = layer_image.split()[3]
            alpha = alpha.point(lambda p: int(p * props["opacity"]))
            layer_image.putalpha(alpha)

        return layer_image

    def clear_cache(self) -> None:
        """Clear cached image."""
        self._cached_image = None


class Scene:
    """A complete animation scene with layers, characters, and audio.

    Usage:
        scene = Scene("intro", width=1920, height=1080, fps=30, duration=60)

        # Add background
        scene.add_layer("background", image_path="bg.png", z_order=0)

        # Add character
        rig = CharacterRig.load("character.json")
        character = Character(rig, position=(960, 800))
        scene.add_character_layer("narrator", character, z_order=10)

        # Animate
        layer = scene.get_layer("narrator")
        layer.animation = AnimationClip("narrator_anim")
        layer.animation.add_track("position").add_keyframe(0, (960, 800))

        # Render
        for frame in range(scene.total_frames):
            image = scene.render_frame(frame)
            image.save(f"frame_{frame:04d}.png")
    """

    def __init__(
        self,
        name: str = "untitled",
        width: int = 1920,
        height: int = 1080,
        fps: float = 30.0,
        duration: float = 10.0,
        background_color: Tuple[int, int, int, int] = (0, 0, 0, 255)
    ):
        """Initialize scene.

        Args:
            name: Scene name
            width: Output width in pixels
            height: Output height in pixels
            fps: Frames per second
            duration: Duration in seconds
            background_color: RGBA background color
        """
        self.name = name
        self.width = width
        self.height = height
        self.fps = fps
        self.duration = duration
        self.background_color = background_color

        # Layers
        self.layers: Dict[str, SceneLayer] = {}

        # Audio
        self.audio_path: Optional[str] = None
        self.audio_offset: float = 0.0

        # Metadata
        self.metadata: Dict[str, any] = {}

    @property
    def total_frames(self) -> int:
        """Total number of frames in the scene."""
        return int(self.duration * self.fps)

    @property
    def canvas_size(self) -> Tuple[int, int]:
        """Canvas size as tuple."""
        return (self.width, self.height)

    def add_layer(
        self,
        name: str,
        image_path: Optional[str] = None,
        z_order: int = 0,
        position: Tuple[int, int] = (0, 0),
        **kwargs
    ) -> SceneLayer:
        """Add a new layer to the scene.

        Args:
            name: Layer name (must be unique)
            image_path: Path to layer image
            z_order: Stacking order (higher = on top)
            position: Initial position
            **kwargs: Additional layer properties

        Returns:
            The created layer
        """
        layer = SceneLayer(
            name=name,
            image_path=image_path,
            z_order=z_order,
            position=position,
            **kwargs
        )
        self.layers[name] = layer
        return layer

    def add_character_layer(
        self,
        name: str,
        character: Character,
        z_order: int = 10,
        **kwargs
    ) -> SceneLayer:
        """Add a character layer to the scene.

        Args:
            name: Layer name
            character: Character instance
            z_order: Stacking order
            **kwargs: Additional layer properties

        Returns:
            The created layer
        """
        layer = SceneLayer(
            name=name,
            character=character,
            z_order=z_order,
            position=character.position,
            **kwargs
        )
        self.layers[name] = layer
        return layer

    def add_color_layer(
        self,
        name: str,
        color: Tuple[int, int, int, int],
        z_order: int = -100,
        **kwargs
    ) -> SceneLayer:
        """Add a solid color layer (useful for backgrounds).

        Args:
            name: Layer name
            color: RGBA color tuple
            z_order: Stacking order
            **kwargs: Additional layer properties

        Returns:
            The created layer
        """
        layer = SceneLayer(
            name=name,
            color=color,
            z_order=z_order,
            **kwargs
        )
        self.layers[name] = layer
        return layer

    def get_layer(self, name: str) -> Optional[SceneLayer]:
        """Get a layer by name."""
        return self.layers.get(name)

    def remove_layer(self, name: str) -> bool:
        """Remove a layer by name. Returns True if removed."""
        if name in self.layers:
            del self.layers[name]
            return True
        return False

    def get_sorted_layers(self) -> List[SceneLayer]:
        """Get layers sorted by z_order (bottom to top)."""
        return sorted(self.layers.values(), key=lambda l: l.z_order)

    def set_audio(self, audio_path: str, offset: float = 0.0) -> None:
        """Set the audio track for this scene.

        Args:
            audio_path: Path to audio file
            offset: Audio start offset in seconds
        """
        self.audio_path = audio_path
        self.audio_offset = offset

    def render_frame(self, frame: int) -> Image.Image:
        """Render a single frame of the scene.

        Args:
            frame: Frame number to render

        Returns:
            Composited frame image
        """
        # Create canvas with background color
        canvas = Image.new('RGBA', self.canvas_size, self.background_color)

        # Render and composite each layer
        for layer in self.get_sorted_layers():
            layer_image = layer.render(frame, self.canvas_size)
            if layer_image:
                props = layer.get_animated_properties(frame)
                x, y = props["position"]

                # Handle image positioning
                if layer.character:
                    # Character handles its own positioning
                    canvas = Image.alpha_composite(canvas, layer_image)
                else:
                    # Paste at position
                    paste_image = Image.new('RGBA', self.canvas_size, (0, 0, 0, 0))
                    paste_image.paste(layer_image, (x, y))
                    canvas = Image.alpha_composite(canvas, paste_image)

        return canvas

    def render_frames(
        self,
        start_frame: int = 0,
        end_frame: int = None,
        on_progress: Optional[callable] = None
    ) -> List[Image.Image]:
        """Render a range of frames.

        Args:
            start_frame: First frame to render
            end_frame: Last frame to render (default: total_frames)
            on_progress: Progress callback (frame, total)

        Returns:
            List of rendered frame images
        """
        if end_frame is None:
            end_frame = self.total_frames

        frames = []
        total = end_frame - start_frame

        for i, frame in enumerate(range(start_frame, end_frame)):
            frames.append(self.render_frame(frame))
            if on_progress:
                on_progress(i + 1, total)

        return frames

    def to_dict(self) -> dict:
        """Convert scene to dictionary for serialization."""
        return {
            "name": self.name,
            "width": self.width,
            "height": self.height,
            "fps": self.fps,
            "duration": self.duration,
            "background_color": list(self.background_color),
            "audio_path": self.audio_path,
            "audio_offset": self.audio_offset,
            "layers": [
                {
                    "name": layer.name,
                    "z_order": layer.z_order,
                    "visible": layer.visible,
                    "opacity": layer.opacity,
                    "position": list(layer.position),
                    "scale": layer.scale,
                    "rotation": layer.rotation,
                    "image_path": layer.image_path,
                    "color": list(layer.color) if layer.color else None,
                    "animation": layer.animation.to_dict() if layer.animation else None
                }
                for layer in self.get_sorted_layers()
                if not layer.character  # Characters are saved separately
            ],
            "metadata": self.metadata
        }

    def save(self, path: str) -> None:
        """Save scene to JSON file."""
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def load(cls, path: str) -> "Scene":
        """Load scene from JSON file."""
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        scene = cls(
            name=data.get("name", "untitled"),
            width=data.get("width", 1920),
            height=data.get("height", 1080),
            fps=data.get("fps", 30.0),
            duration=data.get("duration", 10.0),
            background_color=tuple(data.get("background_color", [0, 0, 0, 255]))
        )

        scene.audio_path = data.get("audio_path")
        scene.audio_offset = data.get("audio_offset", 0.0)
        scene.metadata = data.get("metadata", {})

        # Load layers
        for layer_data in data.get("layers", []):
            from .keyframes import AnimationClip

            layer = SceneLayer(
                name=layer_data["name"],
                z_order=layer_data.get("z_order", 0),
                visible=layer_data.get("visible", True),
                opacity=layer_data.get("opacity", 1.0),
                position=tuple(layer_data.get("position", [0, 0])),
                scale=layer_data.get("scale", 1.0),
                rotation=layer_data.get("rotation", 0.0),
                image_path=layer_data.get("image_path"),
                color=tuple(layer_data["color"]) if layer_data.get("color") else None
            )

            if layer_data.get("animation"):
                layer.animation = AnimationClip.from_dict(layer_data["animation"])

            scene.layers[layer.name] = layer

        return scene

    def clear_caches(self) -> None:
        """Clear all image caches."""
        for layer in self.layers.values():
            layer.clear_cache()
            if layer.character:
                layer.character.clear_cache()
