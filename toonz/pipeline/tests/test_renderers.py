"""Tests for renderers module."""

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image

from pipeline.renderers.base import (
    RenderProgress,
    BaseRenderer,
    FrameRenderer,
    VideoRenderer,
)


class TestRenderProgress:
    """Tests for RenderProgress class."""

    def test_creation(self):
        """Test progress creation."""
        progress = RenderProgress(total_frames=100)
        assert progress.total_frames == 100
        assert progress.current_frame == 0
        assert progress.phase == "initializing"
        assert progress.message == ""

    def test_progress_property(self):
        """Test progress fraction calculation."""
        progress = RenderProgress(total_frames=100)

        progress.current_frame = 0
        assert progress.progress == 0.0

        progress.current_frame = 50
        assert progress.progress == 0.5

        progress.current_frame = 100
        assert progress.progress == 1.0

    def test_progress_property_zero_frames(self):
        """Test progress with zero total frames."""
        progress = RenderProgress(total_frames=0)
        assert progress.progress == 0.0

    def test_percent_property(self):
        """Test percent calculation."""
        progress = RenderProgress(total_frames=100)

        progress.current_frame = 0
        assert progress.percent == 0

        progress.current_frame = 50
        assert progress.percent == 50

        progress.current_frame = 100
        assert progress.percent == 100

    def test_percent_rounds_to_int(self):
        """Test percent is rounded to integer."""
        progress = RenderProgress(total_frames=3)
        progress.current_frame = 1  # 33.33%
        assert progress.percent == 33
        assert isinstance(progress.percent, int)


class TestFrameRenderer:
    """Tests for FrameRenderer class."""

    def test_creation(self):
        """Test frame renderer creation."""
        renderer = FrameRenderer(format="png")
        assert renderer.format == "png"

    def test_supported_formats(self):
        """Test supported formats."""
        renderer = FrameRenderer()
        formats = renderer.get_supported_formats()

        assert "png" in formats
        assert "jpg" in formats
        assert "jpeg" in formats
        assert "tiff" in formats
        assert "bmp" in formats
        assert "webp" in formats

    def test_validate_output_path_creates_directory(self, temp_dir: Path):
        """Test output path validation creates directory."""
        renderer = FrameRenderer()
        new_dir = temp_dir / "output_frames"

        result = renderer.validate_output_path(str(new_dir), is_directory=True)

        assert new_dir.exists()
        assert result == new_dir

    def test_validate_output_path_creates_parent(self, temp_dir: Path):
        """Test output path validation creates parent directory."""
        renderer = FrameRenderer()
        file_path = temp_dir / "subdir" / "output.png"

        result = renderer.validate_output_path(str(file_path), is_directory=False)

        assert (temp_dir / "subdir").exists()
        assert result == file_path

    def test_save_frame_png(self, temp_dir: Path, mock_image: Image.Image):
        """Test saving frame as PNG."""
        renderer = FrameRenderer(format="png")
        output_path = temp_dir / "frame.png"

        renderer.save_frame(mock_image, str(output_path))

        assert output_path.exists()
        loaded = Image.open(output_path)
        assert loaded.size == mock_image.size

    def test_save_frame_jpg_converts_rgba(self, temp_dir: Path):
        """Test saving RGBA frame as JPG converts to RGB."""
        renderer = FrameRenderer(format="jpg")
        output_path = temp_dir / "frame.jpg"

        # Create RGBA image
        rgba_image = Image.new('RGBA', (100, 100), (255, 0, 0, 128))

        renderer.save_frame(rgba_image, str(output_path))

        assert output_path.exists()
        loaded = Image.open(output_path)
        assert loaded.mode == "RGB"

    def test_render_creates_frames(self, temp_dir: Path, mock_scene: MagicMock):
        """Test render creates frame files."""
        renderer = FrameRenderer(format="png")
        output_dir = temp_dir / "frames"
        mock_scene.total_frames = 5

        progress_calls = []

        def track_progress(p):
            progress_calls.append((p.phase, p.current_frame))

        result = renderer.render(mock_scene, str(output_dir), on_progress=track_progress)

        # Check output directory exists and has frames
        assert Path(result).exists()
        for i in range(5):
            assert (Path(result) / f"frame_{i:06d}.png").exists()

        # Check progress was reported
        assert len(progress_calls) > 0
        assert progress_calls[-1][0] == "complete"

    def test_render_calls_scene_render_frame(self, temp_dir: Path, mock_scene: MagicMock):
        """Test render calls scene.render_frame for each frame."""
        renderer = FrameRenderer()
        output_dir = temp_dir / "frames"
        mock_scene.total_frames = 3

        renderer.render(mock_scene, str(output_dir))

        assert mock_scene.render_frame.call_count == 3
        mock_scene.render_frame.assert_any_call(0)
        mock_scene.render_frame.assert_any_call(1)
        mock_scene.render_frame.assert_any_call(2)


class TestVideoRenderer:
    """Tests for VideoRenderer class."""

    def test_creation(self):
        """Test video renderer creation."""
        renderer = MockVideoRenderer(codec="h265", quality="medium", audio=False)
        assert renderer.codec == "h265"
        assert renderer.quality == "medium"
        assert renderer.include_audio is False

    def test_supported_formats(self):
        """Test supported video formats."""
        renderer = MockVideoRenderer()
        formats = renderer.get_supported_formats()

        assert "mp4" in formats
        assert "webm" in formats
        assert "mov" in formats
        assert "avi" in formats

    def test_render_calls_encode_video(self, temp_dir: Path, mock_scene: MagicMock):
        """Test render calls encode_video with frames."""
        renderer = MockVideoRenderer()
        output_file = temp_dir / "output.mp4"
        mock_scene.total_frames = 3

        renderer.render(mock_scene, str(output_file))

        assert renderer.encode_video_called
        assert len(renderer.encoded_frames) == 3
        assert renderer.encoded_fps == mock_scene.fps

    def test_render_reports_progress(self, temp_dir: Path, mock_scene: MagicMock):
        """Test render reports progress through phases."""
        renderer = MockVideoRenderer()
        output_file = temp_dir / "output.mp4"
        mock_scene.total_frames = 3

        phases = []

        def track_progress(p):
            phases.append(p.phase)

        renderer.render(mock_scene, str(output_file), on_progress=track_progress)

        assert "rendering" in phases
        assert "encoding" in phases
        assert "complete" in phases


class MockVideoRenderer(VideoRenderer):
    """Mock video renderer for testing."""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.encode_video_called = False
        self.encoded_frames = []
        self.encoded_fps = 0

    def encode_video(self, frames, output_path, fps, audio_path=None, on_progress=None):
        """Mock encode implementation."""
        self.encode_video_called = True
        self.encoded_frames = frames
        self.encoded_fps = fps
        return output_path

    def get_supported_formats(self):
        return ["mp4", "webm", "mov", "avi"]


class TestDirectRenderer:
    """Tests for DirectRenderer (from direct_renderer.py)."""

    def test_import(self):
        """Test that DirectRenderer can be imported."""
        from pipeline.renderers.direct_renderer import DirectRenderer
        assert DirectRenderer is not None

    def test_direct_renderer_inherits_frame_renderer(self):
        """Test DirectRenderer inherits from FrameRenderer."""
        from pipeline.renderers.direct_renderer import DirectRenderer
        assert issubclass(DirectRenderer, FrameRenderer)


class TestFFmpegRenderer:
    """Tests for FFmpegRenderer (from ffmpeg_renderer.py)."""

    def test_import(self):
        """Test that FFmpegRenderer can be imported."""
        from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer
        assert FFmpegRenderer is not None

    def test_ffmpeg_renderer_inherits_video_renderer(self):
        """Test FFmpegRenderer inherits from VideoRenderer."""
        from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer
        assert issubclass(FFmpegRenderer, VideoRenderer)
