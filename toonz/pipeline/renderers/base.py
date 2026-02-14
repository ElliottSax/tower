"""Base renderer interface for the animation pipeline."""

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional, Callable, List, Tuple
from PIL import Image

from ..animation.scene import Scene


class RenderProgress:
    """Progress information for rendering operations."""

    def __init__(self, total_frames: int):
        self.total_frames = total_frames
        self.current_frame = 0
        self.phase = "initializing"
        self.message = ""

    @property
    def progress(self) -> float:
        """Progress as a fraction (0.0 to 1.0)."""
        if self.total_frames == 0:
            return 0.0
        return self.current_frame / self.total_frames

    @property
    def percent(self) -> int:
        """Progress as a percentage (0 to 100)."""
        return int(self.progress * 100)


class BaseRenderer(ABC):
    """Abstract base class for renderers.

    Renderers take a Scene and produce output (frames or video).

    Usage:
        renderer = DirectRenderer(output_dir="output/frames")
        renderer.render(scene, on_progress=lambda p: print(f"{p.percent}%"))
    """

    def __init__(self):
        """Initialize renderer."""
        self.output_path: Optional[str] = None

    @abstractmethod
    def render(
        self,
        scene: Scene,
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render the scene to output.

        Args:
            scene: Scene to render
            output_path: Output path (file or directory)
            on_progress: Progress callback

        Returns:
            Path to rendered output
        """
        pass

    @abstractmethod
    def get_supported_formats(self) -> List[str]:
        """Get list of supported output formats."""
        pass

    def validate_output_path(self, path: str, is_directory: bool = False) -> Path:
        """Validate and prepare output path.

        Args:
            path: Output path
            is_directory: Whether path should be a directory

        Returns:
            Validated Path object
        """
        p = Path(path)

        if is_directory:
            p.mkdir(parents=True, exist_ok=True)
        else:
            p.parent.mkdir(parents=True, exist_ok=True)

        return p


class FrameRenderer(BaseRenderer):
    """Base class for renderers that output individual frames.

    Subclasses implement render_frame() to produce each frame.
    """

    def __init__(self, format: str = "png"):
        """Initialize frame renderer.

        Args:
            format: Output format (png, jpg, tiff, etc.)
        """
        super().__init__()
        self.format = format

    def render(
        self,
        scene: Scene,
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render scene to individual frame files.

        Args:
            scene: Scene to render
            output_path: Output directory path
            on_progress: Progress callback

        Returns:
            Path to output directory
        """
        output_dir = self.validate_output_path(output_path, is_directory=True)

        progress = RenderProgress(scene.total_frames)
        progress.phase = "rendering"

        for frame in range(scene.total_frames):
            # Render frame
            image = self.render_frame(scene, frame)

            # Save frame
            frame_path = output_dir / f"frame_{frame:06d}.{self.format}"
            self.save_frame(image, str(frame_path))

            # Update progress
            progress.current_frame = frame + 1
            progress.message = f"Rendered frame {frame + 1}/{scene.total_frames}"
            if on_progress:
                on_progress(progress)

        progress.phase = "complete"
        if on_progress:
            on_progress(progress)

        return str(output_dir)

    def render_frame(self, scene: Scene, frame: int) -> Image.Image:
        """Render a single frame.

        Default implementation uses scene.render_frame().
        Subclasses can override for custom rendering.

        Args:
            scene: Scene to render
            frame: Frame number

        Returns:
            Rendered frame as PIL Image
        """
        return scene.render_frame(frame)

    def save_frame(self, image: Image.Image, path: str) -> None:
        """Save a rendered frame to disk.

        Args:
            image: Frame image
            path: Output path
        """
        # Convert to RGB for formats that don't support alpha
        if self.format.lower() in ('jpg', 'jpeg'):
            if image.mode == 'RGBA':
                background = Image.new('RGB', image.size, (255, 255, 255))
                background.paste(image, mask=image.split()[3])
                image = background

        image.save(path)

    def get_supported_formats(self) -> List[str]:
        """Get supported frame formats."""
        return ["png", "jpg", "jpeg", "tiff", "bmp", "webp"]


class VideoRenderer(BaseRenderer):
    """Base class for renderers that output video files.

    Subclasses implement encode_video() to produce final video.
    """

    def __init__(
        self,
        codec: str = "h264",
        quality: str = "high",
        audio: bool = True
    ):
        """Initialize video renderer.

        Args:
            codec: Video codec (h264, h265, vp9, etc.)
            quality: Quality preset (low, medium, high, lossless)
            audio: Whether to include audio
        """
        super().__init__()
        self.codec = codec
        self.quality = quality
        self.include_audio = audio

    @abstractmethod
    def encode_video(
        self,
        frames: List[Image.Image],
        output_path: str,
        fps: float,
        audio_path: Optional[str] = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Encode frames to video.

        Args:
            frames: List of frame images
            output_path: Output video path
            fps: Frames per second
            audio_path: Optional audio file to include
            on_progress: Progress callback

        Returns:
            Path to output video
        """
        pass

    def render(
        self,
        scene: Scene,
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render scene to video file.

        Args:
            scene: Scene to render
            output_path: Output video path
            on_progress: Progress callback

        Returns:
            Path to output video
        """
        output_file = self.validate_output_path(output_path)

        progress = RenderProgress(scene.total_frames)
        progress.phase = "rendering"

        # Render all frames
        frames = []
        for frame in range(scene.total_frames):
            image = scene.render_frame(frame)
            frames.append(image)

            progress.current_frame = frame + 1
            progress.message = f"Rendered frame {frame + 1}/{scene.total_frames}"
            if on_progress:
                on_progress(progress)

        # Encode video
        progress.phase = "encoding"
        progress.current_frame = 0
        if on_progress:
            on_progress(progress)

        audio_path = scene.audio_path if self.include_audio else None

        result = self.encode_video(
            frames,
            str(output_file),
            scene.fps,
            audio_path,
            on_progress
        )

        progress.phase = "complete"
        progress.current_frame = scene.total_frames
        if on_progress:
            on_progress(progress)

        return result

    def get_supported_formats(self) -> List[str]:
        """Get supported video formats."""
        return ["mp4", "webm", "mov", "avi"]
