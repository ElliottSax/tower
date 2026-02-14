"""Tests for core.config module."""

import json
from pathlib import Path

import pytest

from pipeline.core.config import Config, OutputConfig, RhubarbConfig


class TestOutputConfig:
    """Tests for OutputConfig dataclass."""

    def test_default_values(self):
        """Test default configuration values."""
        config = OutputConfig()
        assert config.format == "mp4"
        assert config.codec == "h264"
        assert config.quality == "high"
        assert config.width == 1920
        assert config.height == 1080
        assert config.fps == 30.0

    def test_custom_values(self):
        """Test custom configuration values."""
        config = OutputConfig(
            format="webm",
            codec="vp9",
            quality="medium",
            width=1280,
            height=720,
            fps=24.0
        )
        assert config.format == "webm"
        assert config.codec == "vp9"
        assert config.quality == "medium"
        assert config.width == 1280
        assert config.height == 720
        assert config.fps == 24.0


class TestRhubarbConfig:
    """Tests for RhubarbConfig dataclass."""

    def test_default_values(self):
        """Test default Rhubarb configuration."""
        config = RhubarbConfig()
        assert config.executable == "rhubarb"
        assert config.extended_shapes == "GHX"
        assert config.recognizer == "pocketSphinx"

    def test_custom_values(self):
        """Test custom Rhubarb configuration."""
        config = RhubarbConfig(
            executable="/opt/rhubarb/rhubarb",
            extended_shapes="GH",
            recognizer="phonetic"
        )
        assert config.executable == "/opt/rhubarb/rhubarb"
        assert config.extended_shapes == "GH"
        assert config.recognizer == "phonetic"


class TestConfig:
    """Tests for Config dataclass."""

    def test_default_values(self):
        """Test default project configuration."""
        config = Config()
        assert config.name == "untitled"
        assert config.version == "1.0"
        assert config.project_dir == "."
        assert config.assets_dir == "assets"
        assert config.output_dir == "output"
        assert config.cache_dir == ".cache"
        assert isinstance(config.output, OutputConfig)
        assert isinstance(config.rhubarb, RhubarbConfig)
        assert config.ffmpeg_executable == "ffmpeg"

    def test_load_from_file(self, sample_project_dir: Path):
        """Test loading configuration from file."""
        config = Config.load(str(sample_project_dir))

        assert config.name == "test_project"
        assert config.version == "1.0"
        assert config.project_dir == str(sample_project_dir)
        assert config.output.format == "mp4"
        assert config.output.width == 1920
        assert config.rhubarb.recognizer == "pocketSphinx"

    def test_load_nonexistent_creates_default(self, temp_dir: Path):
        """Test loading from nonexistent file creates default config."""
        config = Config.load(str(temp_dir))
        assert config.name == "untitled"
        assert config.project_dir == str(temp_dir)

    def test_save_and_reload(self, temp_dir: Path):
        """Test saving and reloading configuration."""
        config = Config(
            name="my_project",
            version="2.0",
            project_dir=str(temp_dir)
        )
        config.output = OutputConfig(width=1280, height=720)

        config.save()

        # Verify file exists
        config_path = temp_dir / "pipeline.json"
        assert config_path.exists()

        # Reload and verify
        loaded = Config.load(str(temp_dir))
        assert loaded.name == "my_project"
        assert loaded.version == "2.0"
        assert loaded.output.width == 1280
        assert loaded.output.height == 720

    def test_get_assets_path(self, temp_dir: Path):
        """Test getting assets directory path."""
        config = Config(project_dir=str(temp_dir), assets_dir="my_assets")
        expected = temp_dir / "my_assets"
        assert config.get_assets_path() == expected

    def test_get_output_path(self, temp_dir: Path):
        """Test getting output directory path."""
        config = Config(project_dir=str(temp_dir), output_dir="renders")
        expected = temp_dir / "renders"
        assert config.get_output_path() == expected

    def test_get_cache_path(self, temp_dir: Path):
        """Test getting cache directory path."""
        config = Config(project_dir=str(temp_dir), cache_dir=".my_cache")
        expected = temp_dir / ".my_cache"
        assert config.get_cache_path() == expected

    def test_ensure_directories(self, temp_dir: Path):
        """Test creating project directories."""
        config = Config(
            project_dir=str(temp_dir),
            assets_dir="custom_assets",
            output_dir="custom_output",
            cache_dir=".custom_cache"
        )

        config.ensure_directories()

        assert (temp_dir / "custom_assets").exists()
        assert (temp_dir / "custom_output").exists()
        assert (temp_dir / ".custom_cache").exists()
