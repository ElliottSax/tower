"""Tests for audio.lipsync module."""

import json
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

from pipeline.audio.lipsync import (
    MouthCue,
    LipSyncData,
    RhubarbLipSync,
    generate_lipsync,
)


class TestMouthCue:
    """Tests for MouthCue dataclass."""

    def test_creation(self):
        """Test mouth cue creation."""
        cue = MouthCue(start=0.5, end=1.0, shape="A")
        assert cue.start == 0.5
        assert cue.end == 1.0
        assert cue.shape == "A"

    def test_duration(self):
        """Test duration property."""
        cue = MouthCue(start=0.5, end=1.5, shape="B")
        assert cue.duration == 1.0

    def test_contains_time_inside(self):
        """Test contains_time for time inside cue."""
        cue = MouthCue(start=1.0, end=2.0, shape="C")
        assert cue.contains_time(1.0) is True
        assert cue.contains_time(1.5) is True
        assert cue.contains_time(1.99) is True

    def test_contains_time_outside(self):
        """Test contains_time for time outside cue."""
        cue = MouthCue(start=1.0, end=2.0, shape="C")
        assert cue.contains_time(0.5) is False
        assert cue.contains_time(2.0) is False  # End is exclusive
        assert cue.contains_time(3.0) is False


class TestLipSyncData:
    """Tests for LipSyncData class."""

    def test_creation(self):
        """Test basic creation."""
        data = LipSyncData(duration=5.0)
        assert data.duration == 5.0
        assert len(data.cues) == 0
        assert data.sound_offset == 0.0
        assert data.fps == 30

    def test_get_shape_at_time_basic(self):
        """Test getting shape at specific time."""
        data = LipSyncData(
            duration=3.0,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
                MouthCue(2.0, 3.0, "C"),
            ]
        )

        assert data.get_shape_at_time(0.5) == "A"
        assert data.get_shape_at_time(1.5) == "B"
        assert data.get_shape_at_time(2.5) == "C"

    def test_get_shape_at_time_no_match(self):
        """Test getting shape returns X when no match."""
        data = LipSyncData(
            duration=5.0,
            cues=[
                MouthCue(1.0, 2.0, "A"),
            ]
        )

        # Before cue
        assert data.get_shape_at_time(0.0) == "X"
        # After cue
        assert data.get_shape_at_time(3.0) == "X"

    def test_get_shape_at_time_with_offset(self):
        """Test shape lookup with sound offset."""
        data = LipSyncData(
            duration=3.0,
            sound_offset=0.5,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
            ]
        )

        # At time 1.0 with offset 0.5, effective time is 0.5 -> shape A
        assert data.get_shape_at_time(1.0) == "A"
        # At time 1.5 with offset 0.5, effective time is 1.0 -> shape B
        assert data.get_shape_at_time(1.5) == "B"

    def test_get_shape_at_frame(self):
        """Test getting shape at frame number."""
        data = LipSyncData(
            duration=2.0,
            fps=30,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
            ]
        )

        # Frame 15 at 30fps = 0.5 seconds -> shape A
        assert data.get_shape_at_frame(15) == "A"
        # Frame 45 at 30fps = 1.5 seconds -> shape B
        assert data.get_shape_at_frame(45) == "B"

    def test_get_cues_in_range(self):
        """Test getting cues in time range."""
        data = LipSyncData(
            duration=5.0,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
                MouthCue(2.0, 3.0, "C"),
                MouthCue(3.0, 4.0, "D"),
            ]
        )

        # Get cues from 0.5 to 2.5
        cues = data.get_cues_in_range(0.5, 2.5)
        assert len(cues) == 3
        shapes = [c.shape for c in cues]
        assert "A" in shapes
        assert "B" in shapes
        assert "C" in shapes
        assert "D" not in shapes

    def test_to_dict(self):
        """Test serialization to dictionary."""
        data = LipSyncData(
            duration=2.0,
            audio_path="test.wav",
            transcript="Hello",
            sound_offset=0.1,
            fps=24,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
            ]
        )

        d = data.to_dict()

        assert d["duration"] == 2.0
        assert d["audio_path"] == "test.wav"
        assert d["transcript"] == "Hello"
        assert d["sound_offset"] == 0.1
        assert d["fps"] == 24
        assert len(d["mouthCues"]) == 2
        assert d["mouthCues"][0]["value"] == "A"

    def test_from_dict(self, sample_lipsync_data: dict):
        """Test deserialization from dictionary."""
        data = LipSyncData.from_dict(sample_lipsync_data)

        assert data.duration == 5.0
        assert data.audio_path == "audio/speech.wav"
        assert data.transcript == "Hello world"
        assert len(data.cues) == 8
        assert data.cues[0].shape == "X"
        assert data.cues[1].shape == "C"

    def test_save_and_load(self, temp_dir: Path, sample_lipsync_data: dict):
        """Test saving and loading from file."""
        data = LipSyncData.from_dict(sample_lipsync_data)
        save_path = temp_dir / "lipsync.json"

        data.save(str(save_path))

        assert save_path.exists()

        loaded = LipSyncData.load(str(save_path))

        assert loaded.duration == data.duration
        assert len(loaded.cues) == len(data.cues)
        assert loaded.cues[0].shape == data.cues[0].shape


class TestRhubarbLipSync:
    """Tests for RhubarbLipSync class."""

    def test_shapes_constant(self):
        """Test SHAPES constant has all shapes."""
        assert "A" in RhubarbLipSync.SHAPES
        assert "X" in RhubarbLipSync.SHAPES
        assert len(RhubarbLipSync.SHAPES) == 9

    @patch("subprocess.run")
    def test_verify_installation_success(self, mock_run):
        """Test installation verification success."""
        mock_run.return_value = MagicMock(returncode=0)

        rhubarb = RhubarbLipSync()
        # _verify_installation is called in __init__
        assert rhubarb.is_available is True

    @patch("subprocess.run")
    def test_verify_installation_failure(self, mock_run):
        """Test installation verification failure."""
        mock_run.side_effect = FileNotFoundError()

        rhubarb = RhubarbLipSync()
        assert rhubarb.is_available is False

    def test_analyze_file_not_found(self):
        """Test analyze with nonexistent file."""
        with patch.object(RhubarbLipSync, "_verify_installation", return_value=True):
            rhubarb = RhubarbLipSync()

            with pytest.raises(FileNotFoundError):
                rhubarb.analyze("/nonexistent/audio.wav")

    @patch("subprocess.Popen")
    def test_analyze_success(self, mock_popen, temp_dir: Path):
        """Test successful analysis."""
        # Create mock audio file
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        # Mock Rhubarb output
        rhubarb_output = json.dumps({
            "metadata": {"duration": 2.0},
            "mouthCues": [
                {"start": 0.0, "end": 1.0, "value": "A"},
                {"start": 1.0, "end": 2.0, "value": "B"},
            ]
        })

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = (rhubarb_output, "")
        mock_process.stderr = iter([])
        mock_popen.return_value = mock_process

        with patch.object(RhubarbLipSync, "_verify_installation", return_value=True):
            rhubarb = RhubarbLipSync()
            result = rhubarb.analyze(str(audio_file))

        assert result.duration == 2.0
        assert len(result.cues) == 2
        assert result.cues[0].shape == "A"

    def test_simulate_lipsync_with_transcript(self):
        """Test simulated lip sync with transcript."""
        with patch.object(RhubarbLipSync, "_verify_installation", return_value=True):
            rhubarb = RhubarbLipSync()

            data = LipSyncData(duration=2.0)
            rhubarb._generate_cues_from_text(data, "hello", 2.0)

            assert len(data.cues) > 0
            # 'h' should produce B (consonant)
            # 'e' should produce C (vowel)
            # 'l' should produce H (L sound)
            shapes = [c.shape for c in data.cues]
            assert any(s in shapes for s in ["B", "C", "H"])

    def test_simulate_lipsync_generic(self):
        """Test simulated lip sync without transcript."""
        with patch.object(RhubarbLipSync, "_verify_installation", return_value=True):
            rhubarb = RhubarbLipSync()

            data = LipSyncData(duration=2.0)
            rhubarb._generate_generic_cues(data, 2.0)

            assert len(data.cues) > 0
            # Generic cues should fill the duration
            assert data.cues[-1].end <= 2.0


class TestGenerateLipsync:
    """Tests for generate_lipsync convenience function."""

    @patch.object(RhubarbLipSync, "analyze_with_fallback")
    @patch.object(RhubarbLipSync, "_verify_installation", return_value=True)
    def test_generate_basic(self, mock_verify, mock_analyze, temp_dir: Path):
        """Test basic lip sync generation."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_data = LipSyncData(duration=2.0)
        mock_data.cues.append(MouthCue(0.0, 1.0, "A"))
        mock_analyze.return_value = mock_data

        result = generate_lipsync(str(audio_file))

        assert result is mock_data
        mock_analyze.assert_called_once()

    @patch.object(RhubarbLipSync, "analyze_with_fallback")
    @patch.object(RhubarbLipSync, "_verify_installation", return_value=True)
    def test_generate_with_save(self, mock_verify, mock_analyze, temp_dir: Path):
        """Test lip sync generation with save."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()
        output_file = temp_dir / "output.json"

        mock_data = LipSyncData(duration=2.0)
        mock_data.cues.append(MouthCue(0.0, 1.0, "A"))
        mock_analyze.return_value = mock_data

        result = generate_lipsync(str(audio_file), output_path=str(output_file))

        assert output_file.exists()
        loaded = LipSyncData.load(str(output_file))
        assert loaded.duration == 2.0
