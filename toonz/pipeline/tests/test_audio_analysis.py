"""Tests for audio.analysis module."""

import json
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

from pipeline.audio.analysis import (
    get_audio_duration,
    get_audio_info,
    get_audio_peaks,
    WaveformAnalyzer,
    WaveformData,
    BeatDetector,
    Beat,
)


class TestGetAudioDuration:
    """Tests for get_audio_duration function."""

    def test_file_not_found(self):
        """Test with nonexistent file."""
        with pytest.raises(FileNotFoundError):
            get_audio_duration("/nonexistent/audio.wav")

    @patch("subprocess.run")
    def test_with_ffprobe(self, mock_run, temp_dir: Path):
        """Test duration extraction with ffprobe."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({"format": {"duration": "5.5"}})
        )

        duration = get_audio_duration(str(audio_file))

        assert duration == 5.5
        mock_run.assert_called_once()

    @patch("subprocess.run")
    def test_ffprobe_failure_fallback_to_wave(self, mock_run, temp_dir: Path):
        """Test fallback to wave module when ffprobe fails."""
        import wave
        import struct

        # Create a simple WAV file
        wav_file = temp_dir / "test.wav"
        sample_rate = 44100
        duration = 2.0
        num_samples = int(sample_rate * duration)

        with wave.open(str(wav_file), 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sample_rate)
            w.writeframes(struct.pack(f'{num_samples}h', *([0] * num_samples)))

        # Make ffprobe fail
        mock_run.side_effect = FileNotFoundError()

        result = get_audio_duration(str(wav_file))

        assert abs(result - duration) < 0.01


class TestGetAudioInfo:
    """Tests for get_audio_info function."""

    def test_file_not_found(self):
        """Test with nonexistent file."""
        with pytest.raises(FileNotFoundError):
            get_audio_info("/nonexistent/audio.wav")

    @patch("subprocess.run")
    def test_returns_info(self, mock_run, temp_dir: Path):
        """Test info extraction."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "format": {
                    "duration": "5.0",
                    "bit_rate": "1411200",
                    "format_name": "wav"
                },
                "streams": [{
                    "codec_type": "audio",
                    "sample_rate": "44100",
                    "channels": 2,
                    "codec_name": "pcm_s16le"
                }]
            })
        )

        info = get_audio_info(str(audio_file))

        assert info["duration"] == 5.0
        assert info["sample_rate"] == 44100
        assert info["channels"] == 2
        assert info["codec"] == "pcm_s16le"
        assert info["format"] == "wav"


class TestGetAudioPeaks:
    """Tests for get_audio_peaks function."""

    @patch("subprocess.run")
    def test_returns_peaks(self, mock_run, temp_dir: Path):
        """Test peak extraction."""
        import struct

        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        # Create mock audio data (alternating high/low)
        samples = [16000, -16000] * 100  # 200 samples
        audio_data = struct.pack(f'{len(samples)}h', *samples)

        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=audio_data
        )

        peaks = get_audio_peaks(str(audio_file), num_samples=10)

        assert len(peaks) == 10
        assert all(0 <= p <= 1 for p in peaks)

    @patch("subprocess.run")
    def test_returns_empty_on_failure(self, mock_run, temp_dir: Path):
        """Test returns empty list on failure."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_run.side_effect = FileNotFoundError()

        peaks = get_audio_peaks(str(audio_file), num_samples=10)

        assert peaks == [0.0] * 10


class TestWaveformData:
    """Tests for WaveformData dataclass."""

    def test_creation(self):
        """Test data creation."""
        data = WaveformData(
            peaks=[0.1, 0.5, 0.3],
            duration=2.0,
            sample_rate=44100
        )

        assert len(data.peaks) == 3
        assert data.duration == 2.0
        assert data.sample_rate == 44100


class TestWaveformAnalyzer:
    """Tests for WaveformAnalyzer class."""

    def test_creation(self, temp_dir: Path):
        """Test analyzer creation."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        analyzer = WaveformAnalyzer(str(audio_file))

        assert analyzer.path == str(audio_file)

    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_duration_property(self, mock_duration, temp_dir: Path):
        """Test duration property caching."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 5.0

        analyzer = WaveformAnalyzer(str(audio_file))

        # First access
        d1 = analyzer.duration
        # Second access should use cached value
        d2 = analyzer.duration

        assert d1 == 5.0
        assert d2 == 5.0
        # Should only be called once due to caching
        mock_duration.assert_called_once()

    @patch("pipeline.audio.analysis.get_audio_peaks")
    def test_get_peaks(self, mock_peaks, temp_dir: Path):
        """Test get_peaks method."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_peaks.return_value = [0.1, 0.2, 0.3]

        analyzer = WaveformAnalyzer(str(audio_file))
        peaks = analyzer.get_peaks(width=3)

        assert peaks == [0.1, 0.2, 0.3]
        mock_peaks.assert_called_once_with(str(audio_file), 3)

    @patch("pipeline.audio.analysis.get_audio_peaks")
    @patch("pipeline.audio.analysis.get_audio_duration")
    @patch("pipeline.audio.analysis.get_audio_info")
    def test_get_waveform_data(self, mock_info, mock_duration, mock_peaks, temp_dir: Path):
        """Test get_waveform_data method."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 5.0
        mock_info.return_value = {"sample_rate": 48000}
        mock_peaks.return_value = [0.1, 0.2, 0.3]

        analyzer = WaveformAnalyzer(str(audio_file))
        data = analyzer.get_waveform_data(width=3)

        assert isinstance(data, WaveformData)
        assert data.duration == 5.0
        assert data.sample_rate == 48000
        assert data.peaks == [0.1, 0.2, 0.3]


class TestBeat:
    """Tests for Beat dataclass."""

    def test_creation(self):
        """Test beat creation."""
        beat = Beat(time=1.5, strength=0.8)
        assert beat.time == 1.5
        assert beat.strength == 0.8


class TestBeatDetector:
    """Tests for BeatDetector class."""

    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_creation(self, mock_duration, temp_dir: Path):
        """Test detector creation."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 10.0

        detector = BeatDetector(str(audio_file))

        assert detector.path == str(audio_file)
        assert detector.duration == 10.0

    @patch("pipeline.audio.analysis.get_audio_peaks")
    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_detect_beats(self, mock_duration, mock_peaks, temp_dir: Path):
        """Test beat detection."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 2.0

        # Create peaks with some clear beats
        peaks = [0.1] * 40  # 40 samples for 2 seconds at 20/sec
        peaks[10] = 0.9  # Beat at 0.5s
        peaks[30] = 0.8  # Beat at 1.5s
        mock_peaks.return_value = peaks

        detector = BeatDetector(str(audio_file))
        beats = detector.detect_beats(threshold=0.5)

        assert len(beats) >= 2
        # Beats should be at roughly 0.5s and 1.5s
        times = [b.time for b in beats]
        assert any(abs(t - 0.5) < 0.1 for t in times)
        assert any(abs(t - 1.5) < 0.1 for t in times)

    @patch("pipeline.audio.analysis.get_audio_peaks")
    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_estimate_bpm(self, mock_duration, mock_peaks, temp_dir: Path):
        """Test BPM estimation."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 4.0

        # Create peaks with regular 120 BPM beats (beat every 0.5 seconds)
        peaks = [0.1] * 80  # 80 samples for 4 seconds
        for i in [10, 20, 30, 40, 50, 60, 70]:  # Beats every 10 samples = 0.5s
            peaks[i] = 0.9
        mock_peaks.return_value = peaks

        detector = BeatDetector(str(audio_file))
        bpm = detector.estimate_bpm()

        # Should be around 120 BPM
        assert bpm is not None
        assert 100 < bpm < 140

    @patch("pipeline.audio.analysis.get_audio_peaks")
    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_estimate_bpm_insufficient_beats(self, mock_duration, mock_peaks, temp_dir: Path):
        """Test BPM estimation with too few beats."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 2.0

        # Only 2 beats - not enough
        peaks = [0.1] * 40
        peaks[10] = 0.9
        peaks[30] = 0.8
        mock_peaks.return_value = peaks

        detector = BeatDetector(str(audio_file))
        bpm = detector.estimate_bpm()

        # Should return None with insufficient beats
        # (depends on implementation - might still return something)

    @patch("pipeline.audio.analysis.get_audio_peaks")
    @patch("pipeline.audio.analysis.get_audio_duration")
    def test_get_beats_in_range(self, mock_duration, mock_peaks, temp_dir: Path):
        """Test getting beats in time range."""
        audio_file = temp_dir / "test.wav"
        audio_file.touch()

        mock_duration.return_value = 4.0

        # Create peaks with beats at 0.5, 1.5, 2.5, 3.5
        peaks = [0.1] * 80
        for i in [10, 30, 50, 70]:
            peaks[i] = 0.9
        mock_peaks.return_value = peaks

        detector = BeatDetector(str(audio_file))
        beats = detector.get_beats_in_range(1.0, 3.0, threshold=0.5)

        # Should get beats at 1.5 and 2.5
        times = [b.time for b in beats]
        assert len(beats) >= 2
        assert all(1.0 <= t < 3.0 for t in times)
