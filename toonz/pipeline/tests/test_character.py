"""Tests for animation.character module."""

import json
from pathlib import Path

import pytest
from PIL import Image

from pipeline.animation.character import (
    LayerDefinition,
    CharacterRig,
    Character,
)
from pipeline.audio.lipsync import LipSyncData, MouthCue


class TestLayerDefinition:
    """Tests for LayerDefinition dataclass."""

    def test_default_values(self):
        """Test default layer values."""
        layer = LayerDefinition(name="body", image_path="body.png")
        assert layer.anchor == (0.5, 0.5)
        assert layer.z_order == 0
        assert layer.visible is True
        assert layer.opacity == 1.0

    def test_custom_values(self):
        """Test custom layer values."""
        layer = LayerDefinition(
            name="arm",
            image_path="arm.png",
            anchor=(0.0, 0.5),
            z_order=10,
            visible=False,
            opacity=0.5
        )
        assert layer.name == "arm"
        assert layer.anchor == (0.0, 0.5)
        assert layer.z_order == 10
        assert layer.visible is False
        assert layer.opacity == 0.5

    def test_get_anchor_pixels(self):
        """Test anchor point conversion to pixels."""
        layer = LayerDefinition(name="body", image_path="body.png", anchor=(0.5, 1.0))
        pixels = layer.get_anchor_pixels(100, 200)
        assert pixels == (50, 200)

    def test_get_anchor_pixels_corner(self):
        """Test anchor at corner."""
        layer = LayerDefinition(name="body", image_path="body.png", anchor=(0.0, 0.0))
        pixels = layer.get_anchor_pixels(100, 200)
        assert pixels == (0, 0)


class TestCharacterRig:
    """Tests for CharacterRig class."""

    def test_creation(self):
        """Test basic rig creation."""
        rig = CharacterRig(name="test_char")
        assert rig.name == "test_char"
        assert rig.base_path == ""
        assert rig.mouth_offset == (0, 0)
        assert rig.eye_offset == (0, 0)
        assert rig.default_mouth == "X"
        assert rig.default_eyes == "open"

    def test_get_mouth_path_with_base(self, temp_dir: Path):
        """Test getting mouth path with base path."""
        rig = CharacterRig(
            name="test",
            base_path=str(temp_dir),
            mouth_shapes={"A": "mouth/A.png", "X": "mouth/X.png"}
        )
        path = rig.get_mouth_path("A")
        assert path == str(temp_dir / "mouth/A.png")

    def test_get_mouth_path_fallback_to_x(self, temp_dir: Path):
        """Test mouth path fallback to X."""
        rig = CharacterRig(
            name="test",
            base_path=str(temp_dir),
            mouth_shapes={"A": "mouth/A.png", "X": "mouth/X.png"}
        )
        # Unknown shape should fall back to X
        path = rig.get_mouth_path("Z")
        assert path == str(temp_dir / "mouth/X.png")

    def test_get_mouth_path_fallback_to_a(self, temp_dir: Path):
        """Test mouth path fallback to A when X not present."""
        rig = CharacterRig(
            name="test",
            base_path=str(temp_dir),
            mouth_shapes={"A": "mouth/A.png", "B": "mouth/B.png"}
        )
        # Unknown shape, no X, should fall back to A
        path = rig.get_mouth_path("Z")
        assert path == str(temp_dir / "mouth/A.png")

    def test_get_eye_path(self, temp_dir: Path):
        """Test getting eye path."""
        rig = CharacterRig(
            name="test",
            base_path=str(temp_dir),
            eye_states={"open": "eyes/open.png", "closed": "eyes/closed.png"}
        )
        path = rig.get_eye_path("open")
        assert path == str(temp_dir / "eyes/open.png")

    def test_get_eye_path_fallback(self, temp_dir: Path):
        """Test eye path fallback to default."""
        rig = CharacterRig(
            name="test",
            base_path=str(temp_dir),
            eye_states={"open": "eyes/open.png"},
            default_eyes="open"
        )
        # Unknown state should fall back to default
        path = rig.get_eye_path("winking")
        assert path == str(temp_dir / "eyes/open.png")

    def test_load_from_file(self, sample_character_dir: Path):
        """Test loading rig from JSON file."""
        rig = CharacterRig.load(str(sample_character_dir / "character.json"))

        assert rig.name == "test_character"
        assert "body" in rig.body_layers
        assert rig.body_layers["body"].z_order == 0
        assert "A" in rig.mouth_shapes
        assert "open" in rig.eye_states
        assert rig.mouth_offset == (0, -150)

    def test_save_and_reload(self, temp_dir: Path):
        """Test saving and reloading rig."""
        rig = CharacterRig(
            name="my_char",
            mouth_shapes={"A": "mouth/A.png"},
            eye_states={"open": "eyes/open.png"},
            mouth_offset=(10, -100)
        )
        rig.body_layers["body"] = LayerDefinition(
            name="body",
            image_path="body/idle.png",
            anchor=(0.5, 1.0),
            z_order=5
        )

        save_path = temp_dir / "rig.json"
        rig.save(str(save_path))

        # Reload
        loaded = CharacterRig.load(str(save_path))
        assert loaded.name == "my_char"
        assert loaded.mouth_offset == (10, -100)
        assert loaded.body_layers["body"].z_order == 5

    def test_create_from_directory(self, sample_character_dir: Path):
        """Test auto-detection from directory structure."""
        rig = CharacterRig.create_from_directory(str(sample_character_dir))

        assert rig.name == "test_character"
        assert "idle" in rig.body_layers
        assert len(rig.mouth_shapes) >= 6  # A-F at minimum
        assert "open" in rig.eye_states
        assert "closed" in rig.eye_states


class TestCharacter:
    """Tests for Character class."""

    @pytest.fixture
    def basic_rig(self, sample_character_dir: Path) -> CharacterRig:
        """Create a basic character rig for testing."""
        return CharacterRig.load(str(sample_character_dir / "character.json"))

    def test_creation(self, basic_rig: CharacterRig):
        """Test character creation."""
        char = Character(basic_rig, position=(100, 200), scale=1.5)

        assert char.rig is basic_rig
        assert char.name == basic_rig.name
        assert char.position == (100, 200)
        assert char.scale == 1.5
        assert char.visible is True
        assert char.opacity == 1.0

    def test_default_states(self, basic_rig: CharacterRig):
        """Test default state values."""
        char = Character(basic_rig)

        assert char.current_mouth == basic_rig.default_mouth
        assert char.current_eyes == basic_rig.default_eyes
        assert char.lipsync_data is None

    def test_apply_lipsync(self, basic_rig: CharacterRig):
        """Test applying lip sync data."""
        char = Character(basic_rig)

        lipsync = LipSyncData(
            duration=5.0,
            cues=[
                MouthCue(0.0, 0.5, "A"),
                MouthCue(0.5, 1.0, "B"),
            ]
        )

        char.apply_lipsync(lipsync, fps=30.0)

        assert char.lipsync_data is lipsync
        assert char.lipsync_fps == 30.0

    def test_get_mouth_at_frame_without_lipsync(self, basic_rig: CharacterRig):
        """Test mouth shape without lip sync returns default."""
        char = Character(basic_rig)
        char.current_mouth = "C"

        assert char.get_mouth_at_frame(0) == "C"
        assert char.get_mouth_at_frame(100) == "C"

    def test_get_mouth_at_frame_with_lipsync(self, basic_rig: CharacterRig):
        """Test mouth shape with lip sync."""
        char = Character(basic_rig)

        lipsync = LipSyncData(
            duration=2.0,
            fps=30,
            cues=[
                MouthCue(0.0, 0.5, "A"),
                MouthCue(0.5, 1.0, "B"),
                MouthCue(1.0, 2.0, "C"),
            ]
        )
        char.apply_lipsync(lipsync, fps=30.0)

        # Frame 0 = time 0.0 -> shape A
        assert char.get_mouth_at_frame(0) == "A"
        # Frame 15 = time 0.5 -> shape B
        assert char.get_mouth_at_frame(15) == "B"
        # Frame 45 = time 1.5 -> shape C
        assert char.get_mouth_at_frame(45) == "C"

    def test_get_mouth_at_time(self, basic_rig: CharacterRig):
        """Test mouth shape at specific time."""
        char = Character(basic_rig)

        lipsync = LipSyncData(
            duration=2.0,
            cues=[
                MouthCue(0.0, 0.5, "A"),
                MouthCue(0.5, 1.0, "B"),
            ]
        )
        char.apply_lipsync(lipsync, fps=30.0)

        assert char.get_mouth_at_time(0.25) == "A"
        assert char.get_mouth_at_time(0.75) == "B"

    def test_add_blink(self, basic_rig: CharacterRig):
        """Test adding blinks."""
        char = Character(basic_rig)
        char.add_blink(30)
        char.add_blink(90)

        assert 30 in char.blink_frames
        assert 90 in char.blink_frames

    def test_add_random_blinks(self, basic_rig: CharacterRig):
        """Test adding random blinks."""
        char = Character(basic_rig)
        char.add_random_blinks(total_frames=300, interval=(50, 100))

        assert len(char.blink_frames) > 0
        # All blinks should be within range
        for frame in char.blink_frames:
            assert 0 <= frame < 300

    def test_get_eyes_at_frame_normal(self, basic_rig: CharacterRig):
        """Test eye state when not blinking."""
        char = Character(basic_rig)
        char.current_eyes = "open"

        assert char.get_eyes_at_frame(0) == "open"
        assert char.get_eyes_at_frame(50) == "open"

    def test_get_eyes_at_frame_blinking(self, basic_rig: CharacterRig):
        """Test eye state during blink."""
        char = Character(basic_rig)
        char.current_eyes = "open"
        char.blink_duration = 3
        char.add_blink(10)

        # Before blink
        assert char.get_eyes_at_frame(9) == "open"

        # During blink (half -> closed -> half)
        eyes_10 = char.get_eyes_at_frame(10)
        eyes_11 = char.get_eyes_at_frame(11)
        eyes_12 = char.get_eyes_at_frame(12)

        assert eyes_10 in ["half", "closed"]
        assert eyes_11 in ["half", "closed"]
        assert eyes_12 in ["half", "open"]

        # After blink
        assert char.get_eyes_at_frame(13) == "open"

    def test_render_frame(self, basic_rig: CharacterRig, sample_character_dir: Path):
        """Test rendering a frame."""
        # Set base path so images can be found
        basic_rig.base_path = str(sample_character_dir)
        char = Character(basic_rig, position=(50, 50))

        frame = char.render_frame(0, canvas_size=(200, 200))

        assert isinstance(frame, Image.Image)
        assert frame.size == (200, 200)
        assert frame.mode == "RGBA"

    def test_render_frame_auto_size(self, basic_rig: CharacterRig, sample_character_dir: Path):
        """Test rendering with automatic canvas size."""
        basic_rig.base_path = str(sample_character_dir)
        char = Character(basic_rig, position=(100, 100))

        frame = char.render_frame(0)

        assert isinstance(frame, Image.Image)
        # Size should be determined by rendered layers

    def test_clear_cache(self, basic_rig: CharacterRig):
        """Test clearing image cache."""
        char = Character(basic_rig)

        # Add something to cache
        char._image_cache["test"] = Image.new("RGBA", (10, 10))
        assert len(char._image_cache) > 0

        char.clear_cache()

        assert len(char._image_cache) == 0
