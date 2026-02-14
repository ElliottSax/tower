"""FFmpeg-based video renderer for the animation pipeline."""

import subprocess
import tempfile
import shutil
from pathlib import Path
from typing import Optional, Callable, List, Dict
from PIL import Image

from .base import VideoRenderer, RenderProgress
from ..animation.scene import Scene


class FFmpegRenderer(VideoRenderer):
    """Video renderer using FFmpeg directly.

    Uses FFmpeg subprocess for high-quality video encoding with
    full control over encoding parameters.

    Usage:
        renderer = FFmpegRenderer(codec="h264", quality="high")
        renderer.render(scene, "output/video.mp4")
    """

    # Quality presets for different codecs
    PRESETS = {
        "h264": {
            "low": {"crf": "28", "preset": "veryfast"},
            "medium": {"crf": "23", "preset": "medium"},
            "high": {"crf": "18", "preset": "slow"},
            "lossless": {"crf": "0", "preset": "veryslow"}
        },
        "h265": {
            "low": {"crf": "32", "preset": "veryfast"},
            "medium": {"crf": "28", "preset": "medium"},
            "high": {"crf": "22", "preset": "slow"},
            "lossless": {"crf": "0", "preset": "veryslow"}
        },
        "vp9": {
            "low": {"crf": "35", "cpu-used": "4"},
            "medium": {"crf": "30", "cpu-used": "2"},
            "high": {"crf": "25", "cpu-used": "1"},
            "lossless": {"crf": "0", "cpu-used": "0"}
        },
        "prores": {
            "low": {"profile": "0"},
            "medium": {"profile": "2"},
            "high": {"profile": "3"},
            "lossless": {"profile": "4"}
        }
    }

    # Codec mappings
    CODEC_LIBS = {
        "h264": "libx264",
        "h265": "libx265",
        "hevc": "libx265",
        "vp9": "libvpx-vp9",
        "vp8": "libvpx",
        "prores": "prores_ks",
        "mpeg4": "mpeg4",
        "gif": "gif"
    }

    def __init__(
        self,
        codec: str = "h264",
        quality: str = "high",
        audio: bool = True,
        ffmpeg_path: str = "ffmpeg",
        threads: int = 0,
        pixel_format: str = "yuv420p",
        extra_args: Optional[List[str]] = None
    ):
        """Initialize FFmpeg renderer.

        Args:
            codec: Video codec (h264, h265, vp9, prores, etc.)
            quality: Quality preset (low, medium, high, lossless)
            audio: Whether to include audio
            ffmpeg_path: Path to ffmpeg executable
            threads: Number of threads (0 = auto)
            pixel_format: Output pixel format
            extra_args: Additional FFmpeg arguments
        """
        super().__init__(codec, quality, audio)
        self.ffmpeg_path = ffmpeg_path
        self.threads = threads
        self.pixel_format = pixel_format
        self.extra_args = extra_args or []

        # Verify FFmpeg is available
        self._verify_ffmpeg()

    def _verify_ffmpeg(self) -> None:
        """Verify FFmpeg is installed and accessible."""
        try:
            result = subprocess.run(
                [self.ffmpeg_path, "-version"],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                raise RuntimeError(f"FFmpeg returned error: {result.stderr}")
        except FileNotFoundError:
            raise RuntimeError(
                f"FFmpeg not found at '{self.ffmpeg_path}'. "
                "Please install FFmpeg or provide the correct path."
            )

    def _get_codec_args(self) -> List[str]:
        """Get FFmpeg arguments for the selected codec and quality."""
        lib_codec = self.CODEC_LIBS.get(self.codec.lower(), self.codec)
        presets = self.PRESETS.get(self.codec.lower(), self.PRESETS["h264"])
        quality_settings = presets.get(self.quality, presets["high"])

        args = ["-c:v", lib_codec]

        # Add quality settings
        for key, value in quality_settings.items():
            if key == "crf":
                args.extend(["-crf", value])
            elif key == "preset":
                args.extend(["-preset", value])
            elif key == "profile":
                args.extend(["-profile:v", value])
            elif key == "cpu-used":
                args.extend(["-cpu-used", value])
            else:
                args.extend([f"-{key}", value])

        # Add pixel format
        if self.pixel_format:
            args.extend(["-pix_fmt", self.pixel_format])

        return args

    def _get_audio_args(self, audio_path: str) -> List[str]:
        """Get FFmpeg arguments for audio."""
        if not audio_path or not self.include_audio:
            return ["-an"]  # No audio

        return [
            "-i", audio_path,
            "-c:a", "aac",
            "-b:a", "192k",
            "-shortest"  # Match shortest stream
        ]

    def encode_video(
        self,
        frames: List[Image.Image],
        output_path: str,
        fps: float,
        audio_path: Optional[str] = None,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Encode frames to video using FFmpeg.

        Args:
            frames: List of frame images
            output_path: Output video path
            fps: Frames per second
            audio_path: Optional audio file
            on_progress: Progress callback

        Returns:
            Path to output video
        """
        if not frames:
            raise ValueError("No frames to encode")

        # Create temporary directory for frames
        temp_dir = tempfile.mkdtemp(prefix="ffmpeg_render_")

        try:
            progress = RenderProgress(len(frames))
            progress.phase = "writing frames"

            # Write frames to temp directory
            for i, frame in enumerate(frames):
                frame_path = Path(temp_dir) / f"frame_{i:06d}.png"

                # Convert RGBA to RGB for video
                if frame.mode == 'RGBA':
                    rgb_frame = Image.new('RGB', frame.size, (0, 0, 0))
                    rgb_frame.paste(frame, mask=frame.split()[3])
                    frame = rgb_frame

                frame.save(str(frame_path), format='PNG')

                progress.current_frame = i + 1
                if on_progress:
                    on_progress(progress)

            # Build FFmpeg command
            progress.phase = "encoding"
            progress.current_frame = 0
            if on_progress:
                on_progress(progress)

            input_pattern = str(Path(temp_dir) / "frame_%06d.png")

            cmd = [
                self.ffmpeg_path,
                "-y",  # Overwrite output
                "-framerate", str(fps),
                "-i", input_pattern,
            ]

            # Add audio
            cmd.extend(self._get_audio_args(audio_path))

            # Add codec settings
            cmd.extend(self._get_codec_args())

            # Add threading
            if self.threads > 0:
                cmd.extend(["-threads", str(self.threads)])

            # Add extra arguments
            cmd.extend(self.extra_args)

            # Output file
            cmd.append(output_path)

            # Run FFmpeg
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Wait for completion
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                raise RuntimeError(f"FFmpeg encoding failed: {stderr}")

            progress.phase = "complete"
            progress.current_frame = len(frames)
            if on_progress:
                on_progress(progress)

            return output_path

        finally:
            # Clean up temp directory
            shutil.rmtree(temp_dir, ignore_errors=True)

    def render_direct(
        self,
        scene: Scene,
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Render directly to video using pipe to FFmpeg.

        More memory-efficient for large animations as frames are not
        stored in memory.

        Args:
            scene: Scene to render
            output_path: Output video path
            on_progress: Progress callback

        Returns:
            Path to output video
        """
        progress = RenderProgress(scene.total_frames)
        progress.phase = "encoding"

        # Build FFmpeg command for pipe input
        cmd = [
            self.ffmpeg_path,
            "-y",
            "-f", "rawvideo",
            "-vcodec", "rawvideo",
            "-s", f"{scene.width}x{scene.height}",
            "-pix_fmt", "rgb24",
            "-r", str(scene.fps),
            "-i", "-",  # Pipe input
        ]

        # Add audio
        if scene.audio_path and self.include_audio:
            cmd.extend([
                "-i", scene.audio_path,
                "-c:a", "aac",
                "-b:a", "192k",
                "-shortest"
            ])
        else:
            cmd.append("-an")

        # Add codec settings
        cmd.extend(self._get_codec_args())

        # Add threading
        if self.threads > 0:
            cmd.extend(["-threads", str(self.threads)])

        # Add extra arguments
        cmd.extend(self.extra_args)

        # Output file
        cmd.append(output_path)

        # Start FFmpeg process
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        try:
            # Pipe frames to FFmpeg
            for frame in range(scene.total_frames):
                image = scene.render_frame(frame)

                # Convert to RGB bytes
                if image.mode == 'RGBA':
                    rgb_image = Image.new('RGB', image.size, (0, 0, 0))
                    rgb_image.paste(image, mask=image.split()[3])
                    image = rgb_image

                # Write raw bytes to pipe
                process.stdin.write(image.tobytes())

                progress.current_frame = frame + 1
                progress.message = f"Encoding frame {frame + 1}/{scene.total_frames}"
                if on_progress:
                    on_progress(progress)

            # Close input and wait
            process.stdin.close()
            process.wait()

            if process.returncode != 0:
                stderr = process.stderr.read().decode()
                raise RuntimeError(f"FFmpeg encoding failed: {stderr}")

            progress.phase = "complete"
            if on_progress:
                on_progress(progress)

            return output_path

        except BrokenPipeError:
            stderr = process.stderr.read().decode()
            raise RuntimeError(f"FFmpeg pipe broken: {stderr}")

    def concatenate_videos(
        self,
        video_paths: List[str],
        output_path: str,
        on_progress: Optional[Callable[[RenderProgress], None]] = None
    ) -> str:
        """Concatenate multiple videos into one.

        Args:
            video_paths: List of video file paths
            output_path: Output video path
            on_progress: Progress callback

        Returns:
            Path to concatenated video
        """
        if not video_paths:
            raise ValueError("No videos to concatenate")

        # Create concat file
        temp_file = tempfile.NamedTemporaryFile(
            mode='w',
            suffix='.txt',
            delete=False
        )

        try:
            # Write file list
            for path in video_paths:
                temp_file.write(f"file '{path}'\n")
            temp_file.close()

            # Build FFmpeg command
            cmd = [
                self.ffmpeg_path,
                "-y",
                "-f", "concat",
                "-safe", "0",
                "-i", temp_file.name,
                "-c", "copy",
                output_path
            ]

            # Run FFmpeg
            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode != 0:
                raise RuntimeError(f"FFmpeg concat failed: {result.stderr}")

            return output_path

        finally:
            Path(temp_file.name).unlink(missing_ok=True)

    def add_audio_to_video(
        self,
        video_path: str,
        audio_path: str,
        output_path: str,
        audio_offset: float = 0.0
    ) -> str:
        """Add or replace audio in a video.

        Args:
            video_path: Input video path
            audio_path: Audio file path
            output_path: Output video path
            audio_offset: Audio offset in seconds

        Returns:
            Path to output video
        """
        cmd = [
            self.ffmpeg_path,
            "-y",
            "-i", video_path,
            "-i", audio_path,
            "-c:v", "copy",
            "-c:a", "aac",
            "-b:a", "192k",
            "-map", "0:v:0",
            "-map", "1:a:0",
            "-shortest"
        ]

        if audio_offset != 0:
            cmd.extend(["-itsoffset", str(audio_offset)])

        cmd.append(output_path)

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"FFmpeg audio merge failed: {result.stderr}")

        return output_path

    def get_supported_formats(self) -> List[str]:
        """Get supported video formats."""
        return ["mp4", "webm", "mov", "avi", "mkv", "flv", "wmv", "gif"]


class FFmpegProbeInfo:
    """Helper class to probe media files with FFmpeg."""

    def __init__(self, ffprobe_path: str = "ffprobe"):
        self.ffprobe_path = ffprobe_path

    def get_duration(self, path: str) -> float:
        """Get duration of a media file in seconds."""
        import json

        cmd = [
            self.ffprobe_path,
            "-v", "quiet",
            "-show_entries", "format=duration",
            "-of", "json",
            path
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"FFprobe failed: {result.stderr}")

        data = json.loads(result.stdout)
        return float(data["format"]["duration"])

    def get_video_info(self, path: str) -> Dict:
        """Get video stream information."""
        import json

        cmd = [
            self.ffprobe_path,
            "-v", "quiet",
            "-show_entries", "stream=width,height,r_frame_rate,codec_name,duration",
            "-select_streams", "v:0",
            "-of", "json",
            path
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"FFprobe failed: {result.stderr}")

        data = json.loads(result.stdout)

        if not data.get("streams"):
            raise ValueError(f"No video stream found in {path}")

        stream = data["streams"][0]

        # Parse frame rate
        fps_str = stream.get("r_frame_rate", "30/1")
        if "/" in fps_str:
            num, den = fps_str.split("/")
            fps = float(num) / float(den)
        else:
            fps = float(fps_str)

        return {
            "width": stream.get("width"),
            "height": stream.get("height"),
            "fps": fps,
            "codec": stream.get("codec_name"),
            "duration": float(stream.get("duration", 0))
        }
