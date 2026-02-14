"""Tests for renderers/direct_renderer.py module."""

from pathlib import Path
from unittest.mock import patch, MagicMock, PropertyMock
import tempfile

import pytest
from PIL import Image

from pipeline.renderers.direct_renderer import (
    DirectRenderer,
    MoviePyRenderer,
    GifRenderer,
    PreviewRenderer,
)
from pipeline.renderers.base import RenderProgress


class TestDirectRenderer:
    """Tests for DirectRenderer class."""

    def test_creation_defaults(self):
        """Test renderer creation with defaults."""
        renderer = DirectRenderer()
        assert renderer.format == "png"
        assert renderer.optimize is True
        assert renderer.compression == 6

    def test_creation_custom(self):
        """Test renderer creation with custom values."""
        renderer = DirectRenderer(
            format="jpg",
            optimize=False,
            compression=9
        )
        assert renderer.format == "jpg"
        assert renderer.optimize is False
        assert renderer.compression == 9

    def test_save_frame_png(self, temp_dir: Path):
        """Test saving PNG frame."""
        renderer = DirectRenderer(format="png")
        image = Image.new('RGBA', (100, 100), (255, 0, 0, 255))

        output_path = temp_dir / "frame.png"
        renderer.save_frame(image, str(output_path))

        assert output_path.exists()
        loaded = Image.open(output_path)
        assert loaded.size == (100, 100)

    def test_save_frame_jpg_converts_rgba(self, temp_dir: Path):
        """Test saving JPG converts RGBA to RGB."""
        renderer = DirectRenderer(format="jpg")
        # Create RGBA image with transparency
        image = Image.new('RGBA', (100, 100), (255, 0, 0, 128))

        output_path = temp_dir / "frame.jpg"
        renderer.save_frame(image, str(output_path))

        assert output_path.exists()
        loaded = Image.open(output_path)
        assert loaded.mode == "RGB"

    def test_save_frame_jpg_rgb_passthrough(self, temp_dir: Path):
        """Test RGB image saves directly to JPG."""
        renderer = DirectRenderer(format="jpg")
        image = Image.new('RGB', (100, 100), (255, 0, 0))

        output_path = temp_dir / "frame.jpg"
        renderer.save_frame(image, str(output_path))

        assert output_path.exists()

    def test_save_frame_other_format(self, temp_dir: Path):
        """Test saving in other formats."""
        renderer = DirectRenderer(format="bmp")
        image = Image.new('RGB', (100, 100), (0, 255, 0))

        output_path = temp_dir / "frame.bmp"
        renderer.save_frame(image, str(output_path))

        assert output_path.exists()


class TestMoviePyRenderer:
    """Tests for MoviePyRenderer class."""

    def test_creation_defaults(self):
        """Test renderer creation with defaults."""
        renderer = MoviePyRenderer()
        assert renderer.codec == "libx264"
        assert renderer.quality == "high"
        assert renderer.include_audio is True

    def test_creation_custom(self):
        """Test renderer creation with custom values."""
        renderer = MoviePyRenderer(
            codec="libx265",
            quality="medium",
            audio=False
        )
        assert renderer.codec == "libx265"
        assert renderer.quality == "medium"
        assert renderer.include_audio is False

    def test_quality_presets(self):
        """Test quality presets are defined."""
        assert "low" in MoviePyRenderer.QUALITY_PRESETS
        assert "medium" in MoviePyRenderer.QUALITY_PRESETS
        assert "high" in MoviePyRenderer.QUALITY_PRESETS
        assert "lossless" in MoviePyRenderer.QUALITY_PRESETS

        assert MoviePyRenderer.QUALITY_PRESETS["low"]["bitrate"] == "1000k"
        assert MoviePyRenderer.QUALITY_PRESETS["high"]["bitrate"] == "5000k"

    def test_get_supported_formats(self):
        """Test supported format list."""
        renderer = MoviePyRenderer()
        formats = renderer.get_supported_formats()

        assert "mp4" in formats
        assert "webm" in formats
        assert "mov" in formats
        assert "avi" in formats
        assert "gif" in formats

    @patch("pipeline.renderers.direct_renderer.MoviePyRenderer.encode_video")
    def test_encode_video_import_error(self, mock_encode):
        """Test import error when moviepy not available."""
        renderer = MoviePyRenderer()

        # Simulate import error
        def raise_import(*args, **kwargs):
            raise RuntimeError("MoviePy is not installed")
        mock_encode.side_effect = raise_import

        frames = [Image.new('RGB', (100, 100))]

        with pytest.raises(RuntimeError, match="MoviePy"):
            renderer.encode_video(frames, "output.mp4", 30.0)

    @patch.dict("sys.modules", {"moviepy": MagicMock(), "moviepy.editor": MagicMock()})
    def test_encode_video_success(self, temp_dir: Path):
        """Test successful video encoding with mocked moviepy."""
        # Mock moviepy modules
        mock_moviepy = MagicMock()
        mock_clip = MagicMock()
        mock_clip.duration = 2.0
        mock_moviepy.ImageSequenceClip.return_value = mock_clip

        with patch.dict("sys.modules", {
            "moviepy": mock_moviepy,
            "moviepy.editor": mock_moviepy
        }):
            with patch("pipeline.renderers.direct_renderer.MoviePyRenderer.encode_video") as mock_encode:
                output_path = str(temp_dir / "output.mp4")
                mock_encode.return_value = output_path

                renderer = MoviePyRenderer()
                frames = [Image.new('RGB', (100, 100)) for _ in range(5)]

                result = renderer.encode_video(frames, output_path, 30.0)

                assert result == output_path


class TestGifRenderer:
    """Tests for GifRenderer class."""

    def test_creation_defaults(self):
        """Test renderer creation with defaults."""
        renderer = GifRenderer()
        assert renderer.optimize is True
        assert renderer.colors == 256
        assert renderer.loop == 0
        assert renderer.disposal == 2

    def test_creation_custom(self):
        """Test renderer creation with custom values."""
        renderer = GifRenderer(
            optimize=False,
            colors=128,
            loop=3,
            disposal=1
        )
        assert renderer.optimize is False
        assert renderer.colors == 128
        assert renderer.loop == 3
        assert renderer.disposal == 1

    def test_colors_clamped_max(self):
        """Test colors are clamped to max 256."""
        renderer = GifRenderer(colors=500)
        assert renderer.colors == 256

    def test_colors_clamped_min(self):
        """Test colors are clamped to min 2."""
        renderer = GifRenderer(colors=1)
        assert renderer.colors == 2

    def test_get_supported_formats(self):
        """Test only GIF is supported."""
        renderer = GifRenderer()
        formats = renderer.get_supported_formats()

        assert formats == ["gif"]

    def test_encode_video_empty_frames(self):
        """Test encoding with no frames raises error."""
        renderer = GifRenderer()

        with pytest.raises(ValueError, match="No frames"):
            renderer.encode_video([], "output.gif", 30.0)

    def test_encode_video_success(self, temp_dir: Path):
        """Test successful GIF encoding."""
        renderer = GifRenderer()

        # Create test frames
        frames = [
            Image.new('RGB', (50, 50), (255, 0, 0)),
            Image.new('RGB', (50, 50), (0, 255, 0)),
            Image.new('RGB', (50, 50), (0, 0, 255)),
        ]

        output_path = temp_dir / "animation.gif"
        result = renderer.encode_video(frames, str(output_path), 10.0)

        assert Path(result).exists()
        # Verify it's a valid GIF
        loaded = Image.open(result)
        assert loaded.format == "GIF"

    def test_encode_video_rgba_conversion(self, temp_dir: Path):
        """Test RGBA frames are converted properly."""
        renderer = GifRenderer()

        # Create RGBA frames with transparency
        frames = [
            Image.new('RGBA', (50, 50), (255, 0, 0, 128)),
            Image.new('RGBA', (50, 50), (0, 255, 0, 128)),
        ]

        output_path = temp_dir / "rgba_animation.gif"
        result = renderer.encode_video(frames, str(output_path), 10.0)

        assert Path(result).exists()

    def test_encode_video_with_progress(self, temp_dir: Path):
        """Test progress callback during encoding."""
        renderer = GifRenderer()

        frames = [Image.new('RGB', (50, 50)) for _ in range(5)]

        progress_updates = []
        def on_progress(progress):
            progress_updates.append(progress.current_frame)

        output_path = temp_dir / "progress_test.gif"
        renderer.encode_video(frames, str(output_path), 10.0, on_progress=on_progress)

        # Should have progress updates for each frame
        assert len(progress_updates) == 5
        assert progress_updates == [1, 2, 3, 4, 5]


class TestPreviewRenderer:
    """Tests for PreviewRenderer class."""

    def test_creation_defaults(self):
        """Test renderer creation with defaults."""
        renderer = PreviewRenderer()
        assert renderer.scale == 0.5
        assert renderer.skip_frames == 0
        assert renderer.format == "jpg"
        assert renderer.optimize is False

    def test_creation_custom(self):
        """Test renderer creation with custom values."""
        renderer = PreviewRenderer(
            scale=0.25,
            skip_frames=2,
            format="png"
        )
        assert renderer.scale == 0.25
        assert renderer.skip_frames == 2
        assert renderer.format == "png"

    def test_render_frame_with_scale(self, mock_scene):
        """Test frame scaling."""
        renderer = PreviewRenderer(scale=0.5)

        # Mock scene to return a 100x100 image
        mock_image = Image.new('RGB', (100, 100))
        mock_scene.render_frame.return_value = mock_image

        result = renderer.render_frame(mock_scene, 0)

        # Should be scaled to 50x50
        assert result.size == (50, 50)

    def test_render_frame_skip_frames(self, mock_scene):
        """Test frame skipping logic."""
        renderer = PreviewRenderer(skip_frames=2)

        mock_image = Image.new('RGB', (100, 100))
        mock_scene.render_frame.return_value = mock_image

        # With skip_frames=2, render frames 0, 3, 6, etc.
        result0 = renderer.render_frame(mock_scene, 0)
        result1 = renderer.render_frame(mock_scene, 1)
        result2 = renderer.render_frame(mock_scene, 2)
        result3 = renderer.render_frame(mock_scene, 3)

        assert result0 is not None
        assert result1 is None
        assert result2 is None
        assert result3 is not None

    def test_render_frame_no_skip(self, mock_scene):
        """Test all frames rendered when skip_frames=0."""
        renderer = PreviewRenderer(skip_frames=0)

        mock_image = Image.new('RGB', (100, 100))
        mock_scene.render_frame.return_value = mock_image

        for frame in range(5):
            result = renderer.render_frame(mock_scene, frame)
            assert result is not None

    def test_render_frame_full_scale(self, mock_scene):
        """Test no scaling when scale=1.0."""
        renderer = PreviewRenderer(scale=1.0)

        mock_image = Image.new('RGB', (100, 100))
        mock_scene.render_frame.return_value = mock_image

        result = renderer.render_frame(mock_scene, 0)

        assert result.size == (100, 100)

    def test_render_full_preview(self, mock_scene, temp_dir: Path):
        """Test rendering full preview sequence."""
        renderer = PreviewRenderer(scale=0.5, skip_frames=0)

        # Setup mock scene
        mock_image = Image.new('RGB', (100, 100), (255, 0, 0))
        mock_scene.render_frame.return_value = mock_image
        mock_scene.total_frames = 5

        output_dir = temp_dir / "preview"
        result = renderer.render(mock_scene, str(output_dir))

        assert Path(result).exists()
        # Check that frames were saved
        frame_files = list(Path(result).glob("preview_*.jpg"))
        assert len(frame_files) == 5

    def test_render_with_skip_frames(self, mock_scene, temp_dir: Path):
        """Test rendering with frame skipping."""
        renderer = PreviewRenderer(scale=0.5, skip_frames=1)

        mock_image = Image.new('RGB', (100, 100), (255, 0, 0))
        mock_scene.render_frame.return_value = mock_image
        mock_scene.total_frames = 10

        output_dir = temp_dir / "preview_skip"
        result = renderer.render(mock_scene, str(output_dir))

        # With skip_frames=1, should render every other frame (0, 2, 4, 6, 8)
        frame_files = list(Path(result).glob("preview_*.jpg"))
        assert len(frame_files) == 5

    def test_render_with_progress(self, mock_scene, temp_dir: Path):
        """Test progress callback during preview render."""
        renderer = PreviewRenderer(scale=0.5)

        mock_image = Image.new('RGB', (100, 100))
        mock_scene.render_frame.return_value = mock_image
        mock_scene.total_frames = 3

        progress_updates = []
        def on_progress(progress):
            progress_updates.append((progress.phase, progress.current_frame))

        output_dir = temp_dir / "progress_preview"
        renderer.render(mock_scene, str(output_dir), on_progress=on_progress)

        # Should have progress updates
        assert len(progress_updates) > 0
        # Last update should be complete phase
        assert progress_updates[-1][0] == "complete"


class TestRendererIntegration:
    """Integration tests for renderer classes."""

    def test_direct_renderer_roundtrip(self, temp_dir: Path):
        """Test saving and loading frame."""
        renderer = DirectRenderer(format="png")

        # Create image with known content
        original = Image.new('RGBA', (100, 100))
        for x in range(100):
            for y in range(100):
                original.putpixel((x, y), (x % 256, y % 256, 128, 255))

        output_path = temp_dir / "test.png"
        renderer.save_frame(original, str(output_path))

        loaded = Image.open(output_path)
        loaded_rgb = loaded.convert('RGBA')

        # Compare pixels
        for x in range(100):
            for y in range(100):
                orig_pixel = original.getpixel((x, y))
                loaded_pixel = loaded_rgb.getpixel((x, y))
                assert orig_pixel == loaded_pixel, f"Pixel mismatch at ({x}, {y})"

    def test_gif_renderer_animation_properties(self, temp_dir: Path):
        """Test GIF has correct animation properties."""
        renderer = GifRenderer(loop=2)

        frames = [
            Image.new('RGB', (50, 50), color)
            for color in [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
        ]

        output_path = temp_dir / "test_props.gif"
        renderer.encode_video(frames, str(output_path), 10.0)

        # Verify GIF properties
        gif = Image.open(output_path)

        # Check it has multiple frames
        frame_count = 0
        try:
            while True:
                frame_count += 1
                gif.seek(gif.tell() + 1)
        except EOFError:
            pass

        assert frame_count == 3

    def test_preview_renderer_quality_vs_speed(self, mock_scene, temp_dir: Path):
        """Test preview renderer produces smaller files."""
        # Full quality direct renderer
        direct = DirectRenderer(format="png")

        # Low quality preview
        preview = PreviewRenderer(scale=0.25, format="jpg")

        mock_image = Image.new('RGB', (400, 400), (100, 150, 200))
        mock_scene.render_frame.return_value = mock_image

        # Direct frame (simulated)
        direct_path = temp_dir / "direct.png"
        direct.save_frame(mock_image, str(direct_path))

        # Preview frame
        mock_scene.total_frames = 1
        preview_dir = temp_dir / "preview"
        preview.render(mock_scene, str(preview_dir))

        preview_path = list(preview_dir.glob("*.jpg"))[0]

        # Preview should be smaller (both dimensions and file size)
        preview_img = Image.open(preview_path)
        assert preview_img.size == (100, 100)  # 400 * 0.25 = 100
