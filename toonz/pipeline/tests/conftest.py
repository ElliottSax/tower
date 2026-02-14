"""Pytest configuration and shared fixtures for animation pipeline tests."""

import json
import os
import tempfile
from pathlib import Path
from typing import Generator
from unittest.mock import MagicMock

import pytest
from PIL import Image


@pytest.fixture
def temp_dir() -> Generator[Path, None, None]:
    """Create a temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmp:
        yield Path(tmp)


@pytest.fixture
def sample_config_data() -> dict:
    """Sample configuration data."""
    return {
        "name": "test_project",
        "version": "1.0",
        "project_dir": ".",
        "assets_dir": "assets",
        "output_dir": "output",
        "cache_dir": ".cache",
        "output": {
            "format": "mp4",
            "codec": "h264",
            "quality": "high",
            "width": 1920,
            "height": 1080,
            "fps": 30.0
        },
        "rhubarb": {
            "executable": "rhubarb",
            "extended_shapes": "GHX",
            "recognizer": "pocketSphinx"
        },
        "ffmpeg_executable": "ffmpeg"
    }


@pytest.fixture
def sample_project_dir(temp_dir: Path, sample_config_data: dict) -> Path:
    """Create a sample project directory structure."""
    # Create directories
    (temp_dir / "assets" / "characters").mkdir(parents=True)
    (temp_dir / "assets" / "backgrounds").mkdir(parents=True)
    (temp_dir / "assets" / "audio").mkdir(parents=True)
    (temp_dir / "output").mkdir(parents=True)
    (temp_dir / ".cache").mkdir(parents=True)

    # Write config
    sample_config_data["project_dir"] = str(temp_dir)
    with open(temp_dir / "pipeline.json", 'w') as f:
        json.dump(sample_config_data, f)

    return temp_dir


@pytest.fixture
def sample_character_rig_data() -> dict:
    """Sample character rig data."""
    return {
        "name": "test_character",
        "body_layers": {
            "body": {
                "path": "body/idle.png",
                "anchor": [0.5, 1.0],
                "z_order": 0,
                "visible": True,
                "opacity": 1.0
            }
        },
        "mouth_shapes": {
            "A": "mouth/A.png",
            "B": "mouth/B.png",
            "C": "mouth/C.png",
            "D": "mouth/D.png",
            "E": "mouth/E.png",
            "F": "mouth/F.png",
            "X": "mouth/X.png"
        },
        "eye_states": {
            "open": "eyes/open.png",
            "half": "eyes/half.png",
            "closed": "eyes/closed.png"
        },
        "mouth_offset": [0, -150],
        "eye_offset": [0, -200],
        "default_pose": "idle",
        "default_mouth": "X",
        "default_eyes": "open"
    }


@pytest.fixture
def sample_character_dir(temp_dir: Path, sample_character_rig_data: dict) -> Path:
    """Create a sample character directory with images."""
    char_dir = temp_dir / "test_character"
    char_dir.mkdir()

    # Create subdirectories
    (char_dir / "body").mkdir()
    (char_dir / "mouth").mkdir()
    (char_dir / "eyes").mkdir()

    # Create sample images (1x1 transparent PNGs)
    def create_sample_image(path: Path, color: tuple = (255, 0, 0, 255)):
        img = Image.new('RGBA', (100, 100), color)
        img.save(path)

    # Body
    create_sample_image(char_dir / "body" / "idle.png", (100, 100, 100, 255))

    # Mouth shapes
    for shape in ['A', 'B', 'C', 'D', 'E', 'F', 'X']:
        create_sample_image(char_dir / "mouth" / f"{shape}.png", (200, 50, 50, 255))

    # Eyes
    create_sample_image(char_dir / "eyes" / "open.png", (50, 50, 200, 255))
    create_sample_image(char_dir / "eyes" / "half.png", (50, 100, 200, 255))
    create_sample_image(char_dir / "eyes" / "closed.png", (50, 150, 200, 255))

    # Write character.json
    with open(char_dir / "character.json", 'w') as f:
        json.dump(sample_character_rig_data, f)

    return char_dir


@pytest.fixture
def sample_lipsync_data() -> dict:
    """Sample lip sync data."""
    return {
        "duration": 5.0,
        "sound_offset": 0.0,
        "fps": 30,
        "audio_path": "audio/speech.wav",
        "transcript": "Hello world",
        "mouthCues": [
            {"start": 0.0, "end": 0.3, "value": "X"},
            {"start": 0.3, "end": 0.5, "value": "C"},
            {"start": 0.5, "end": 0.7, "value": "B"},
            {"start": 0.7, "end": 1.0, "value": "E"},
            {"start": 1.0, "end": 1.3, "value": "X"},
            {"start": 1.3, "end": 1.6, "value": "F"},
            {"start": 1.6, "end": 2.0, "value": "C"},
            {"start": 2.0, "end": 5.0, "value": "X"},
        ]
    }


@pytest.fixture
def mock_image() -> Image.Image:
    """Create a mock PIL Image."""
    return Image.new('RGBA', (100, 100), (255, 0, 0, 255))


@pytest.fixture
def mock_scene() -> MagicMock:
    """Create a mock Scene object for renderer tests."""
    scene = MagicMock()
    scene.total_frames = 10
    scene.fps = 30.0
    scene.width = 1920
    scene.height = 1080
    scene.audio_path = None
    scene.render_frame = MagicMock(
        return_value=Image.new('RGBA', (1920, 1080), (0, 0, 0, 255))
    )
    return scene
