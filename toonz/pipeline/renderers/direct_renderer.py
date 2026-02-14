"""Direct renderer using PIL for frame rendering."""

from pathlib import Path
from typing import Optional, Callable, List
from PIL import Image
import tempfile
import shutil

from .base import FrameRenderer, VideoRenderer, RenderProgress
from ..animation.scene import Scene


class DirectRenderer(FrameRenderer):
    """Direct frame renderer using PIL.

    Renders scenes to individual PNG/JPG frames. For video output,
    use FFmpegRenderer or MoviePyRenderer.

    Usage:
        renderer = DirectRenderer(format="png")
        renderer.render(scene, "output/frames/")
    """

    def __init__(
        self,
        format: str = "png",
        optimize: bool = True,
        compression: int = 6
    ):
        """Initialize direct renderer.

        Args:
            format: Output format (png, jpg, etc.)
            optimize: Whether to optimize output files
            compression: PNG compression level (0-9)
        """
        super().__init__(format)
        self.optimize = optimize
        self.compression = compression

    def save_frame(self, image: Image.Image, path: str) -> None:
        """Save frame with optimization settings."""
        # Convert to RGB for formats that don't support alpha
        if self.format.lower() in ('jpg', 'jpeg'):
            if image.mode == 'RGBA':
                background = Image.new('RGB', image.size, (255, 255, 255))
                background.paste(image, mask=image.split()[3])
                image = background
            image.save(path, optimize=self.optimize, quality=95)
        elif self.format.lower() == 'png':
            image.save(path, optimize=self.optimize, compress_level=self.compression)
        else:
            image.save(path)


class MoviePyRenderer(VideoRenderer):
    """Video renderer using MoviePy.

    Renders scenes directly to video using MoviePy for encoding.
    Requires moviepy package to be installed.

    Usage:
        renderer = MoviePyRenderer(codec="h264", quality="high")
        renderer.render(scene, "output/video.mp4")
    """

    QUALITY_PRESETS = {
        "low": {"bitrate": "1000k", "fps_scale": 0.5},
        "medium": {"bitrate": "2500k", "fps_scale": 1.0},
        "high": {"bitrate": "5000k", "fps_scale": 1.0},
        "lossless": {"bitrate": "10000k", "fps_scale": 1.0}
    }

    def __init__(
        self,
        codec: str = "libx264",
        quality: str = "high",
        audio: bool = True
    ):
        """Initialize MoviePy renderer.

        Args:
            codec: FFmpeg codec name (libx264, libx265, libvpx, etc.)
            quality: Quality preset (low, medium, high, lossless)
            audio: Whether to include audio
        """
        super().__init__(codec, quality, audio)

    def encode_video(
        self,
        frames: List[Image.Image],
        output_path: str,
        fps: float,
        audio_path: Optional[str] = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Encode frames to video using MoviePy.

        Args:
            frames: List of frame images
            output_path: Output video path
            fps: Frames per second
            audio_path: Optional audio file
            on_progress: Progress callback

        Returns:
            Path to output video
        """
        try:
            from moviepy.editor import ImageSequenceClip, AudioFileClip
        except ImportError:
            raise RuntimeError(
                "MoviePy is not installed. Install with: pip install moviepy"
            )

        import numpy as np

        # Convert PIL images to numpy arrays
        frame_arrays = [np.array(frame.convert('RGB')) for frame in frames]

        # Create video clip
        preset = self.QUALITY_PRESETS.get(self.quality, self.QUALITY_PRESETS["high"])
        effective_fps = fps * preset.get("fps_scale", 1.0)

        clip = ImageSequenceClip(frame_arrays, fps=effective_fps)

        # Add audio if provided
        if audio_path and self.include_audio:
            try:
                audio = AudioFileClip(audio_path)
                # Trim audio to video length
                if audio.duration > clip.duration:
                    audio = audio.subclip(0, clip.duration)
                clip = clip.set_audio(audio)
            except Exception as e:
                print(f"Warning: Could not add audio: {e}")

        # Determine output format
        output_path = str(output_path)
        ext = Path(output_path).suffix.lower()

        # Set codec and parameters
        if ext in ('.mp4', '.m4v'):
            codec = 'libx264'
            audio_codec = 'aac'
        elif ext == '.webm':
            codec = 'libvpx'
            audio_codec = 'libvorbis'
        elif ext == '.mov':
            codec = 'libx264'
            audio_codec = 'aac'
        elif ext == '.avi':
            codec = 'mpeg4'
            audio_codec = 'mp3'
        else:
            codec = self.codec
            audio_codec = 'aac'

        # Write video
        clip.write_videofile(
            output_path,
            codec=codec,
            audio_codec=audio_codec,
            bitrate=preset.get("bitrate", "5000k"),
            logger=None  # Suppress MoviePy output
        )

        clip.close()

        return output_path

    def get_supported_formats(self) -> List[str]:
        """Get supported video formats."""
        return ["mp4", "webm", "mov", "avi", "gif"]


class GifRenderer(VideoRenderer):
    """Animated GIF renderer using PIL/MoviePy.

    Optimized for creating animated GIFs from scenes.

    Usage:
        renderer = GifRenderer(optimize=True, colors=256)
        renderer.render(scene, "output/animation.gif")
    """

    def __init__(
        self,
        optimize: bool = True,
        colors: int = 256,
        loop: int = 0,
        disposal: int = 2
    ):
        """Initialize GIF renderer.

        Args:
            optimize: Whether to optimize the GIF
            colors: Number of colors (max 256)
            loop: Loop count (0 = infinite)
            disposal: Frame disposal method
        """
        super().__init__(codec="gif", quality="high", audio=False)
        self.optimize = optimize
        self.colors = min(256, max(2, colors))
        self.loop = loop
        self.disposal = disposal

    def encode_video(
        self,
        frames: List[Image.Image],
        output_path: str,
        fps: float,
        audio_path: Optional[str] = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Encode frames to animated GIF.

        Args:
            frames: List of frame images
            output_path: Output GIF path
            fps: Frames per second
            audio_path: Ignored (GIFs don't support audio)
            on_progress: Progress callback

        Returns:
            Path to output GIF
        """
        if not frames:
            raise ValueError("No frames to encode")

        # Calculate frame duration in milliseconds
        duration = int(1000 / fps)

        # Convert frames to palette mode for GIF
        converted_frames = []
        for i, frame in enumerate(frames):
            # Convert RGBA to RGB with white background
            if frame.mode == 'RGBA':
                background = Image.new('RGB', frame.size, (255, 255, 255))
                background.paste(frame, mask=frame.split()[3])
                frame = background

            # Convert to palette mode
            frame = frame.convert('P', palette=Image.Palette.ADAPTIVE, colors=self.colors)
            converted_frames.append(frame)

            if on_progress:
                progress = RenderProgress(len(frames))
                progress.phase = "converting"
                progress.current_frame = i + 1
                on_progress(progress)

        # Save as animated GIF
        converted_frames[0].save(
            output_path,
            save_all=True,
            append_images=converted_frames[1:],
            duration=duration,
            loop=self.loop,
            optimize=self.optimize,
            disposal=self.disposal
        )

        return output_path

    def get_supported_formats(self) -> List[str]:
        """Get supported formats (only GIF)."""
        return ["gif"]


class PreviewRenderer(DirectRenderer):
    """Fast preview renderer with reduced quality.

    Renders at lower resolution for quick previews.

    Usage:
        renderer = PreviewRenderer(scale=0.5)
        renderer.render(scene, "output/preview/")
    """

    def __init__(
        self,
        scale: float = 0.5,
        skip_frames: int = 0,
        format: str = "jpg"
    ):
        """Initialize preview renderer.

        Args:
            scale: Scale factor (0.25 = quarter resolution)
            skip_frames: Skip every N frames (0 = render all)
            format: Output format (jpg for speed)
        """
        super().__init__(format=format, optimize=False)
        self.scale = scale
        self.skip_frames = skip_frames

    def render_frame(self, scene: Scene, frame: int) -> Image.Image:
        """Render frame at reduced resolution."""
        # Skip frames if configured
        if self.skip_frames > 0 and frame % (self.skip_frames + 1) != 0:
            return None

        # Render at full resolution
        image = scene.render_frame(frame)

        # Scale down
        if self.scale != 1.0:
            new_size = (
                int(image.width * self.scale),
                int(image.height * self.scale)
            )
            image = image.resize(new_size, Image.Resampling.BILINEAR)

        return image

    def render(
        self,
        scene: Scene,
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render preview frames."""
        output_dir = self.validate_output_path(output_path, is_directory=True)

        effective_frames = scene.total_frames
        if self.skip_frames > 0:
            effective_frames = scene.total_frames // (self.skip_frames + 1)

        progress = RenderProgress(effective_frames)
        progress.phase = "rendering"

        frame_count = 0
        for frame in range(scene.total_frames):
            image = self.render_frame(scene, frame)

            if image is not None:
                frame_path = output_dir / f"preview_{frame_count:06d}.{self.format}"
                self.save_frame(image, str(frame_path))
                frame_count += 1

                progress.current_frame = frame_count
                progress.message = f"Preview frame {frame_count}/{effective_frames}"
                if on_progress:
                    on_progress(progress)

        progress.phase = "complete"
        if on_progress:
            on_progress(progress)

        return str(output_dir)
