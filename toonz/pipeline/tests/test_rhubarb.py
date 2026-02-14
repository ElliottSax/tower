"""Tests for lipsync/rhubarb.py module."""

import json
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

from pipeline.lipsync.rhubarb import (
    MouthCue,
    LipSyncData,
    RhubarbError,
    RhubarbWrapper,
)


class TestMouthCue:
    """Tests for MouthCue dataclass."""

    def test_creation(self):
        """Test cue creation."""
        cue = MouthCue(start=0.5, end=1.5, shape="A")
        assert cue.start == 0.5
        assert cue.end == 1.5
        assert cue.shape == "A"

    def test_duration_property(self):
        """Test duration calculation."""
        cue = MouthCue(start=1.0, end=3.5, shape="B")
        assert cue.duration == 2.5

    def test_get_frame_range(self):
        """Test frame range calculation."""
        cue = MouthCue(start=0.5, end=1.5, shape="C")

        # At 30 fps: 0.5s = frame 15, 1.5s = frame 45
        start, end = cue.get_frame_range(30.0)
        assert start == 15
        assert end == 45

        # At 24 fps: 0.5s = frame 12, 1.5s = frame 36
        start, end = cue.get_frame_range(24.0)
        assert start == 12
        assert end == 36


class TestLipSyncData:
    """Tests for LipSyncData dataclass."""

    def test_creation(self):
        """Test creation."""
        data = LipSyncData(duration=5.0, cues=[])
        assert data.duration == 5.0
        assert len(data.cues) == 0
        assert data.audio_path is None

    def test_get_shape_at_time(self):
        """Test getting shape at time."""
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

    def test_get_shape_at_time_returns_x_for_gaps(self):
        """Test default X shape for gaps."""
        data = LipSyncData(
            duration=5.0,
            cues=[
                MouthCue(1.0, 2.0, "A"),
            ]
        )

        # Before cue
        assert data.get_shape_at_time(0.5) == "X"
        # After cue
        assert data.get_shape_at_time(3.0) == "X"

    def test_get_shape_at_frame(self):
        """Test getting shape at frame."""
        data = LipSyncData(
            duration=2.0,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
            ]
        )

        # At 30 fps, frame 15 = 0.5s (shape A), frame 45 = 1.5s (shape B)
        assert data.get_shape_at_frame(15, 30.0) == "A"
        assert data.get_shape_at_frame(45, 30.0) == "B"

    def test_to_dict(self):
        """Test serialization."""
        data = LipSyncData(
            duration=2.0,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
            ],
            audio_path="test.wav"
        )

        d = data.to_dict()

        assert d["metadata"]["duration"] == 2.0
        assert d["metadata"]["soundFile"] == "test.wav"
        assert len(d["mouthCues"]) == 2
        assert d["mouthCues"][0]["value"] == "A"

    def test_from_dict(self):
        """Test deserialization."""
        d = {
            "metadata": {
                "duration": 3.0,
                "soundFile": "audio.wav"
            },
            "mouthCues": [
                {"start": 0.0, "end": 1.0, "value": "A"},
                {"start": 1.0, "end": 2.0, "value": "B"},
            ]
        }

        data = LipSyncData.from_dict(d)

        assert data.duration == 3.0
        assert data.audio_path == "audio.wav"
        assert len(data.cues) == 2
        assert data.cues[0].shape == "A"

    def test_save_and_load(self, temp_dir: Path):
        """Test save and load roundtrip."""
        data = LipSyncData(
            duration=5.0,
            cues=[
                MouthCue(0.0, 1.0, "A"),
                MouthCue(1.0, 2.0, "B"),
                MouthCue(2.0, 3.0, "C"),
            ],
            audio_path="test.wav"
        )

        save_path = temp_dir / "lipsync.json"
        data.save(str(save_path))

        assert save_path.exists()

        loaded = LipSyncData.load(str(save_path))

        assert loaded.duration == data.duration
        assert len(loaded.cues) == len(data.cues)
        assert loaded.cues[0].shape == "A"


class TestRhubarbError:
    """Tests for RhubarbError exception."""

    def test_exception_message(self):
        """Test exception carries message."""
        with pytest.raises(RhubarbError) as exc_info:
            raise RhubarbError("Test error message")

        assert "Test error message" in str(exc_info.value)


class TestRhubarbWrapper:
    """Tests for RhubarbWrapper class."""

    def test_creation(self):
        """Test wrapper creation."""
        wrapper = RhubarbWrapper()
        assert wrapper.executable == "rhubarb"

        wrapper_custom = RhubarbWrapper("/custom/path/rhubarb")
        assert wrapper_custom.executable == "/custom/path/rhubarb"

    def test_constants(self):
        """Test shape constants."""
        assert "A" in RhubarbWrapper.BASIC_SHAPES
        assert "F" in RhubarbWrapper.BASIC_SHAPES
        assert "G" in RhubarbWrapper.EXTENDED_SHAPES
        assert "X" in RhubarbWrapper.EXTENDED_SHAPES
        assert len(RhubarbWrapper.ALL_SHAPES) == 9

    def test_analyze_file_not_found(self):
        """Test analyze with missing audio file."""
        wrapper = RhubarbWrapper()

        with pytest.raises(FileNotFoundError):
            wrapper.analyze("/nonexistent/audio.wav")

    def test_analyze_transcript_not_found(self, temp_dir: Path):
        """Test analyze with missing transcript file."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        wrapper = RhubarbWrapper()

        with pytest.raises(FileNotFoundError):
            wrapper.analyze(str(audio_file), transcript_path="/nonexistent/transcript.txt")

    @patch("subprocess.Popen")
    def test_analyze_success(self, mock_popen, temp_dir: Path):
        """Test successful analysis."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        # Mock Rhubarb output
        rhubarb_output = json.dumps({
            "metadata": {"duration": 2.0, "soundFile": str(audio_file)},
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

        wrapper = RhubarbWrapper()
        result = wrapper.analyze(str(audio_file))

        assert result.duration == 2.0
        assert len(result.cues) == 2
        assert result.cues[0].shape == "A"

    @patch("subprocess.Popen")
    def test_analyze_with_progress(self, mock_popen, temp_dir: Path):
        """Test analysis with progress callback."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        # Mock Rhubarb output with progress events
        rhubarb_output = json.dumps({
            "metadata": {"duration": 2.0},
            "mouthCues": [{"start": 0.0, "end": 2.0, "value": "X"}]
        })

        progress_events = [
            '{"type": "progress", "value": 0.25}',
            '{"type": "progress", "value": 0.5}',
            '{"type": "progress", "value": 0.75}',
            '{"type": "progress", "value": 1.0}',
        ]

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = (rhubarb_output, "")
        mock_process.stderr = iter(progress_events)
        mock_popen.return_value = mock_process

        progress_values = []
        def on_progress(value):
            progress_values.append(value)

        wrapper = RhubarbWrapper()
        wrapper.analyze(str(audio_file), on_progress=on_progress)

        assert len(progress_values) == 4
        assert progress_values[-1] == 1.0

    @patch("subprocess.Popen")
    def test_analyze_failure_from_stderr(self, mock_popen, temp_dir: Path):
        """Test failure event from stderr."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_process.stderr = iter(['{"type": "failure", "reason": "Invalid audio format"}'])
        mock_popen.return_value = mock_process

        wrapper = RhubarbWrapper()

        with pytest.raises(RhubarbError, match="Invalid audio format"):
            wrapper.analyze(str(audio_file))

    @patch("subprocess.Popen")
    def test_analyze_nonzero_exit(self, mock_popen, temp_dir: Path):
        """Test handling non-zero exit code."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_process = MagicMock()
        mock_process.returncode = 1
        mock_process.communicate.return_value = ("", "")
        mock_process.stderr = iter(["Some error message"])
        mock_popen.return_value = mock_process

        wrapper = RhubarbWrapper()

        with pytest.raises(RhubarbError, match="exited with code 1"):
            wrapper.analyze(str(audio_file))

    @patch("subprocess.Popen")
    def test_analyze_empty_output(self, mock_popen, temp_dir: Path):
        """Test handling empty output."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_process.stderr = iter([])
        mock_popen.return_value = mock_process

        wrapper = RhubarbWrapper()

        with pytest.raises(RhubarbError, match="no output"):
            wrapper.analyze(str(audio_file))

    def test_analyze_executable_not_found(self, temp_dir: Path):
        """Test handling missing executable."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        wrapper = RhubarbWrapper("/nonexistent/rhubarb")

        with pytest.raises(RhubarbError, match="not found"):
            wrapper.analyze(str(audio_file))

    @patch("subprocess.Popen")
    def test_analyze_to_file(self, mock_popen, temp_dir: Path):
        """Test analyze_to_file saves result."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()
        output_file = temp_dir / "lipsync.json"

        rhubarb_output = json.dumps({
            "metadata": {"duration": 2.0},
            "mouthCues": [{"start": 0.0, "end": 2.0, "value": "X"}]
        })

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = (rhubarb_output, "")
        mock_process.stderr = iter([])
        mock_popen.return_value = mock_process

        wrapper = RhubarbWrapper()
        result = wrapper.analyze_to_file(str(audio_file), str(output_file))

        assert output_file.exists()
        assert result.duration == 2.0

    def test_get_shape_description(self):
        """Test shape descriptions."""
        assert "Closed" in RhubarbWrapper.get_shape_description("A")
        assert "Puckered" in RhubarbWrapper.get_shape_description("F")
        assert "Rest" in RhubarbWrapper.get_shape_description("X")
        assert "Unknown" in RhubarbWrapper.get_shape_description("Z")
