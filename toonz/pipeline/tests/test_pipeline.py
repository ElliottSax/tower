"""Tests for core.pipeline module."""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image

from pipeline.core.pipeline import AnimationPipeline, create_project
from pipeline.core.config import Config, OutputConfig
from pipeline.animation.scene import Scene
from pipeline.animation.character import Character


class TestAnimationPipeline:
    """Tests for AnimationPipeline class."""

    @pytest.fixture
    def pipeline(self, sample_project_dir: Path) -> AnimationPipeline:
        """Create a pipeline instance."""
        return AnimationPipeline(str(sample_project_dir))

    def test_creation(self, sample_project_dir: Path):
        """Test pipeline creation."""
        pipeline = AnimationPipeline(str(sample_project_dir))

        assert pipeline.project_dir == sample_project_dir.resolve()
        assert pipeline.config is not None
        assert pipeline.rhubarb is not None

    def test_setup_project(self, sample_project_dir: Path):
        """Test project setup creates directories."""
        pipeline = AnimationPipeline(str(sample_project_dir))
        pipeline.setup_project()

        assets_path = pipeline.config.get_assets_path()
        assert (assets_path / "characters").exists()
        assert (assets_path / "backgrounds").exists()
        assert (assets_path / "audio").exists()

    def test_generate_lipsync_with_cache(self, sample_project_dir: Path):
        """Test lip sync generation with caching."""
        # Create audio file
        audio_path = sample_project_dir / "audio.wav"
        audio_path.touch()

        # Mock rhubarb
        mock_lipsync = MagicMock()
        mock_lipsync.duration = 5.0

        pipeline = AnimationPipeline(str(sample_project_dir))
        pipeline.rhubarb = MagicMock()
        pipeline.rhubarb.analyze.return_value = mock_lipsync

        # First call - should analyze
        result1 = pipeline.generate_lipsync(str(audio_path), cache=True)

        # Second call - should use cache
        result2 = pipeline.generate_lipsync(str(audio_path), cache=True)

        assert result1 is result2
        pipeline.rhubarb.analyze.assert_called_once()

    def test_generate_lipsync_no_cache(self, sample_project_dir: Path):
        """Test lip sync generation without caching."""
        audio_path = sample_project_dir / "audio.wav"
        audio_path.touch()

        mock_lipsync = MagicMock()

        pipeline = AnimationPipeline(str(sample_project_dir))
        pipeline.rhubarb = MagicMock()
        pipeline.rhubarb.analyze.return_value = mock_lipsync

        # Both calls should analyze
        pipeline.generate_lipsync(str(audio_path), cache=False)
        pipeline.generate_lipsync(str(audio_path), cache=False)

        assert pipeline.rhubarb.analyze.call_count == 2

    def test_load_character_from_directory(self, sample_project_dir: Path, sample_character_dir: Path):
        """Test loading character from directory."""
        # Copy character to assets
        import shutil
        assets_chars = sample_project_dir / "assets" / "characters"
        assets_chars.mkdir(parents=True, exist_ok=True)
        dest = assets_chars / "test_char"
        shutil.copytree(sample_character_dir, dest)

        pipeline = AnimationPipeline(str(sample_project_dir))
        character = pipeline.load_character("characters/test_char", position=(100, 200), scale=1.5)

        assert character is not None
        assert character.position == (100, 200)
        assert character.scale == 1.5

    def test_load_character_caching(self, sample_project_dir: Path, sample_character_dir: Path):
        """Test character instances are cached."""
        import shutil
        assets_chars = sample_project_dir / "assets" / "characters"
        assets_chars.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sample_character_dir, assets_chars / "test_char")

        pipeline = AnimationPipeline(str(sample_project_dir))
        char1 = pipeline.load_character("characters/test_char")
        char2 = pipeline._characters.get(char1.name)

        assert char2 is char1

    def test_create_scene(self, sample_project_dir: Path):
        """Test scene creation with project defaults."""
        pipeline = AnimationPipeline(str(sample_project_dir))
        scene = pipeline.create_scene("test_scene", duration=30.0)

        assert scene.name == "test_scene"
        assert scene.duration == 30.0
        # Should use config defaults
        assert scene.width == pipeline.config.output.width
        assert scene.height == pipeline.config.output.height
        assert scene.fps == pipeline.config.output.fps

    def test_create_scene_custom(self, sample_project_dir: Path):
        """Test scene creation with custom values."""
        pipeline = AnimationPipeline(str(sample_project_dir))
        scene = pipeline.create_scene(
            "custom",
            duration=10.0,
            width=1280,
            height=720,
            fps=24.0,
            background_color=(255, 255, 255, 255)
        )

        assert scene.width == 1280
        assert scene.height == 720
        assert scene.fps == 24.0
        assert scene.background_color == (255, 255, 255, 255)

    @patch("pipeline.core.pipeline.DirectRenderer")
    def test_render_image_format(self, mock_renderer_class, sample_project_dir: Path):
        """Test rendering with image format uses DirectRenderer."""
        mock_renderer = MagicMock()
        mock_renderer.render.return_value = "output.png"
        mock_renderer_class.return_value = mock_renderer

        pipeline = AnimationPipeline(str(sample_project_dir))
        scene = pipeline.create_scene("test")

        pipeline.render(scene, format="png")

        mock_renderer_class.assert_called_once_with(format="png")

    @patch("pipeline.core.pipeline.FFmpegRenderer")
    def test_render_video_format(self, mock_renderer_class, sample_project_dir: Path):
        """Test rendering with video format uses FFmpegRenderer."""
        mock_renderer = MagicMock()
        mock_renderer.render.return_value = "output.mp4"
        mock_renderer_class.return_value = mock_renderer

        pipeline = AnimationPipeline(str(sample_project_dir))
        scene = pipeline.create_scene("test")

        pipeline.render(scene, format="mp4")

        mock_renderer_class.assert_called_once()

    @patch("pipeline.core.pipeline.PreviewRenderer")
    def test_render_preview(self, mock_renderer_class, sample_project_dir: Path):
        """Test preview rendering."""
        mock_renderer = MagicMock()
        mock_renderer.render.return_value = "preview"
        mock_renderer_class.return_value = mock_renderer

        pipeline = AnimationPipeline(str(sample_project_dir))
        scene = pipeline.create_scene("test")

        pipeline.render_preview(scene, scale=0.5, skip_frames=2)

        mock_renderer_class.assert_called_once_with(scale=0.5, skip_frames=2)

    def test_resolve_path_absolute(self, sample_project_dir: Path):
        """Test path resolution with absolute path."""
        pipeline = AnimationPipeline(str(sample_project_dir))

        abs_path = "/absolute/path/file.txt"
        result = pipeline._resolve_path(abs_path)

        assert result == abs_path

    def test_resolve_path_relative(self, sample_project_dir: Path):
        """Test path resolution with relative path."""
        pipeline = AnimationPipeline(str(sample_project_dir))

        rel_path = "audio/test.wav"
        result = pipeline._resolve_path(rel_path)

        expected = str(sample_project_dir / rel_path)
        assert result == expected

    def test_resolve_asset_path(self, sample_project_dir: Path):
        """Test asset path resolution."""
        pipeline = AnimationPipeline(str(sample_project_dir))

        result = pipeline._resolve_asset_path("characters/test")

        expected = sample_project_dir / "assets" / "characters" / "test"
        assert result == expected

    @patch.object(AnimationPipeline, "generate_lipsync")
    def test_create_character_animation(self, mock_lipsync, sample_project_dir: Path, sample_character_dir: Path):
        """Test complete character animation creation."""
        import shutil
        assets_chars = sample_project_dir / "assets" / "characters"
        assets_chars.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sample_character_dir, assets_chars / "test_char")

        # Create audio file
        audio_path = sample_project_dir / "audio.wav"
        audio_path.touch()

        # Mock lipsync
        mock_data = MagicMock()
        mock_data.duration = 5.0
        mock_lipsync.return_value = mock_data

        pipeline = AnimationPipeline(str(sample_project_dir))
        character = pipeline.load_character("characters/test_char")

        scene = pipeline.create_character_animation(
            character,
            str(audio_path),
            add_blinks=True
        )

        assert scene is not None
        assert scene.duration == 5.0
        assert len(scene.layers) > 0

    def test_load_project(self, sample_project_dir: Path):
        """Test loading project file."""
        project_data = {
            "name": "test_project",
            "width": 1280,
            "height": 720,
            "duration": 30.0
        }

        project_file = sample_project_dir / "test.charproj"
        with open(project_file, 'w') as f:
            json.dump(project_data, f)

        pipeline = AnimationPipeline(str(sample_project_dir))
        loaded = pipeline.load_project(str(project_file))

        assert loaded["name"] == "test_project"
        assert loaded["width"] == 1280


class TestCreateProject:
    """Tests for create_project function."""

    def test_create_new_project(self, temp_dir: Path):
        """Test creating a new project."""
        project_path = temp_dir / "new_project"

        pipeline = create_project(
            str(project_path),
            name="My Project",
            width=1280,
            height=720,
            fps=24.0
        )

        assert pipeline is not None
        assert project_path.exists()
        assert (project_path / "pipeline.json").exists()
        assert (project_path / "assets").exists()
        assert (project_path / "output").exists()

        # Check config values
        assert pipeline.config.name == "My Project"
        assert pipeline.config.output.width == 1280
        assert pipeline.config.output.height == 720
        assert pipeline.config.output.fps == 24.0

    def test_create_project_in_existing_dir(self, temp_dir: Path):
        """Test creating project in existing directory."""
        project_path = temp_dir / "existing"
        project_path.mkdir()

        pipeline = create_project(str(project_path), name="Existing")

        assert pipeline is not None
        assert (project_path / "pipeline.json").exists()


class TestPipelineIntegration:
    """Integration tests for pipeline workflow."""

    def test_full_workflow_mock(self, sample_project_dir: Path, sample_character_dir: Path):
        """Test full pipeline workflow with mocked external tools."""
        import shutil

        # Setup project structure
        assets_chars = sample_project_dir / "assets" / "characters"
        assets_chars.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sample_character_dir, assets_chars / "narrator")

        # Create audio file
        audio_path = sample_project_dir / "assets" / "audio" / "speech.wav"
        audio_path.parent.mkdir(parents=True, exist_ok=True)
        audio_path.touch()

        # Create background
        bg_path = sample_project_dir / "assets" / "backgrounds" / "bg.png"
        bg_path.parent.mkdir(parents=True, exist_ok=True)
        Image.new('RGBA', (1920, 1080), (100, 100, 200, 255)).save(bg_path)

        pipeline = AnimationPipeline(str(sample_project_dir))

        # Load character
        character = pipeline.load_character("characters/narrator", position=(960, 800))
        assert character is not None

        # Create scene
        scene = pipeline.create_scene("intro", duration=5.0)
        scene.add_layer("background", image_path=str(bg_path), z_order=0)
        scene.add_character_layer("narrator", character, z_order=10)

        # Verify scene structure
        assert len(scene.layers) == 2
        assert scene.get_layer("background") is not None
        assert scene.get_layer("narrator") is not None

        # Render single frame (without external tools)
        frame = scene.render_frame(0)
        assert frame is not None
        assert frame.size == (scene.width, scene.height)
