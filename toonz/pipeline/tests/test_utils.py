"""Tests for core.utils module."""

import json
import os
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

from pipeline.core.utils import (
    ensure_dir,
    find_executable,
    load_json,
    save_json,
    frames_to_time,
    time_to_frames,
)


class TestEnsureDir:
    """Tests for ensure_dir function."""

    def test_creates_new_directory(self, temp_dir: Path):
        """Test creating a new directory."""
        new_dir = temp_dir / "new_folder"
        assert not new_dir.exists()

        result = ensure_dir(str(new_dir))

        assert new_dir.exists()
        assert result == new_dir

    def test_creates_nested_directories(self, temp_dir: Path):
        """Test creating nested directories."""
        nested_dir = temp_dir / "level1" / "level2" / "level3"
        assert not nested_dir.exists()

        result = ensure_dir(str(nested_dir))

        assert nested_dir.exists()
        assert result == nested_dir

    def test_existing_directory(self, temp_dir: Path):
        """Test with existing directory (should not raise)."""
        existing_dir = temp_dir / "existing"
        existing_dir.mkdir()

        result = ensure_dir(str(existing_dir))

        assert result == existing_dir


class TestFindExecutable:
    """Tests for find_executable function."""

    def test_find_in_path(self):
        """Test finding executable in system PATH."""
        # Python should be in PATH
        result = find_executable("python")
        if result:
            assert os.path.isfile(result)

    def test_executable_not_found(self):
        """Test with nonexistent executable."""
        result = find_executable("nonexistent_executable_xyz123")
        assert result is None

    def test_find_in_custom_paths(self, temp_dir: Path):
        """Test finding executable in custom paths."""
        # Create a fake executable
        fake_exe = temp_dir / "fake_tool"
        fake_exe.touch()
        fake_exe.chmod(0o755)

        result = find_executable("fake_tool", paths=[str(temp_dir)])

        assert result == str(fake_exe)

    def test_find_with_extension(self, temp_dir: Path):
        """Test finding executable with extension."""
        # Create a fake executable with .exe extension
        fake_exe = temp_dir / "tool.exe"
        fake_exe.touch()
        fake_exe.chmod(0o755)

        result = find_executable("tool", paths=[str(temp_dir)])

        # Should find the .exe version
        if result:
            assert os.path.isfile(result)


class TestLoadJson:
    """Tests for load_json function."""

    def test_load_valid_json(self, temp_dir: Path):
        """Test loading valid JSON file."""
        json_file = temp_dir / "data.json"
        test_data = {"name": "test", "value": 42, "nested": {"key": "value"}}

        with open(json_file, 'w') as f:
            json.dump(test_data, f)

        result = load_json(str(json_file))

        assert result == test_data

    def test_load_nonexistent_file(self, temp_dir: Path):
        """Test loading nonexistent file raises error."""
        with pytest.raises(FileNotFoundError):
            load_json(str(temp_dir / "nonexistent.json"))

    def test_load_invalid_json(self, temp_dir: Path):
        """Test loading invalid JSON raises error."""
        json_file = temp_dir / "invalid.json"
        json_file.write_text("not valid json {")

        with pytest.raises(json.JSONDecodeError):
            load_json(str(json_file))


class TestSaveJson:
    """Tests for save_json function."""

    def test_save_json_pretty(self, temp_dir: Path):
        """Test saving JSON with pretty printing."""
        json_file = temp_dir / "output.json"
        test_data = {"name": "test", "value": 42}

        save_json(str(json_file), test_data, pretty=True)

        content = json_file.read_text()
        assert "  " in content  # Indentation present

        loaded = json.loads(content)
        assert loaded == test_data

    def test_save_json_compact(self, temp_dir: Path):
        """Test saving JSON without pretty printing."""
        json_file = temp_dir / "compact.json"
        test_data = {"name": "test", "value": 42}

        save_json(str(json_file), test_data, pretty=False)

        content = json_file.read_text()
        assert "\n" not in content  # No newlines

        loaded = json.loads(content)
        assert loaded == test_data

    def test_save_unicode(self, temp_dir: Path):
        """Test saving JSON with unicode characters."""
        json_file = temp_dir / "unicode.json"
        test_data = {"emoji": "🎬", "japanese": "日本語"}

        save_json(str(json_file), test_data)

        loaded = load_json(str(json_file))
        assert loaded == test_data


class TestTimeConversion:
    """Tests for time conversion functions."""

    def test_frames_to_time_30fps(self):
        """Test frame to time conversion at 30 fps."""
        assert frames_to_time(0, 30.0) == 0.0
        assert frames_to_time(30, 30.0) == 1.0
        assert frames_to_time(60, 30.0) == 2.0
        assert frames_to_time(15, 30.0) == 0.5

    def test_frames_to_time_24fps(self):
        """Test frame to time conversion at 24 fps."""
        assert frames_to_time(24, 24.0) == 1.0
        assert frames_to_time(48, 24.0) == 2.0
        assert frames_to_time(12, 24.0) == 0.5

    def test_time_to_frames_30fps(self):
        """Test time to frame conversion at 30 fps."""
        assert time_to_frames(0.0, 30.0) == 0
        assert time_to_frames(1.0, 30.0) == 30
        assert time_to_frames(2.0, 30.0) == 60
        assert time_to_frames(0.5, 30.0) == 15

    def test_time_to_frames_24fps(self):
        """Test time to frame conversion at 24 fps."""
        assert time_to_frames(1.0, 24.0) == 24
        assert time_to_frames(2.0, 24.0) == 48

    def test_time_to_frames_rounds_down(self):
        """Test that time_to_frames rounds down."""
        # 0.5 seconds at 30fps = 15 frames
        # 0.51 seconds at 30fps = 15.3 frames -> 15
        assert time_to_frames(0.51, 30.0) == 15
        assert time_to_frames(0.99, 30.0) == 29

    def test_roundtrip_conversion(self):
        """Test that conversion roundtrips correctly."""
        fps = 30.0
        for frame in [0, 15, 30, 45, 60, 100]:
            time = frames_to_time(frame, fps)
            result = time_to_frames(time, fps)
            assert result == frame
