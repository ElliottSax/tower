"""Audio analysis utilities.

Provides waveform analysis, beat detection, and audio info extraction.
"""

import os
import subprocess
import json
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


def get_audio_duration(path: str) -> float:
    """Get audio file duration in seconds.

    Args:
        path: Path to audio file

    Returns:
        Duration in seconds
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Audio file not found: {path}")

    # Try ffprobe first
    try:
        cmd = [
            'ffprobe',
            '-v', 'quiet',
            '-show_entries', 'format=duration',
            '-of', 'json',
            path
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        return float(data['format']['duration'])
    except (subprocess.CalledProcessError, FileNotFoundError, KeyError):
        pass

    # Try wave module for WAV files
    if path.lower().endswith('.wav'):
        try:
            with wave.open(path, 'rb') as wav:
                frames = wav.getnframes()
                rate = wav.getframerate()
                return frames / rate
        except Exception:
            pass

    raise RuntimeError(f"Could not determine duration of: {path}")


def get_audio_info(path: str) -> dict:
    """Get detailed audio file information.

    Args:
        path: Path to audio file

    Returns:
        Dictionary with audio metadata
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Audio file not found: {path}")

    try:
        cmd = [
            'ffprobe',
            '-v', 'quiet',
            '-show_format',
            '-show_streams',
            '-of', 'json',
            path
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)

        # Extract relevant info
        format_info = data.get('format', {})
        stream_info = next(
            (s for s in data.get('streams', []) if s.get('codec_type') == 'audio'),
            {}
        )

        return {
            'duration': float(format_info.get('duration', 0)),
            'sample_rate': int(stream_info.get('sample_rate', 0)),
            'channels': stream_info.get('channels', 0),
            'codec': stream_info.get('codec_name', 'unknown'),
            'bit_rate': int(format_info.get('bit_rate', 0)),
            'format': format_info.get('format_name', 'unknown'),
        }
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        raise RuntimeError(f"Could not analyze audio: {e}")


def get_audio_peaks(
    path: str,
    num_samples: int = 100,
    channel: int = 0
) -> List[float]:
    """Get audio peak levels for visualization.

    Args:
        path: Path to audio file
        num_samples: Number of peak samples to return
        channel: Audio channel (0=left, 1=right)

    Returns:
        List of peak values (0.0-1.0)
    """
    try:
        # Use ffmpeg to extract audio data
        cmd = [
            'ffmpeg',
            '-i', path,
            '-ac', '1',  # Mono
            '-f', 's16le',  # Raw 16-bit
            '-ar', '8000',  # Low sample rate
            '-'
        ]
        result = subprocess.run(cmd, capture_output=True, check=True)

        # Parse raw audio data
        import struct
        data = result.stdout
        samples = struct.unpack(f'{len(data)//2}h', data)

        # Calculate peaks for each segment
        segment_size = max(1, len(samples) // num_samples)
        peaks = []

        for i in range(num_samples):
            start = i * segment_size
            end = min(start + segment_size, len(samples))
            if start >= len(samples):
                peaks.append(0.0)
            else:
                segment = samples[start:end]
                peak = max(abs(s) for s in segment) / 32768.0
                peaks.append(peak)

        return peaks

    except (subprocess.CalledProcessError, FileNotFoundError):
        # Return empty peaks
        return [0.0] * num_samples


@dataclass
class WaveformData:
    """Waveform visualization data."""
    peaks: List[float]
    duration: float
    sample_rate: int


class WaveformAnalyzer:
    """Analyzes audio for waveform visualization.

    Usage:
        analyzer = WaveformAnalyzer("audio.wav")
        peaks = analyzer.get_peaks(width=800)

        # Draw waveform
        for i, peak in enumerate(peaks):
            height = int(peak * 100)
            draw.line([i, 50 - height, i, 50 + height], fill="blue")
    """

    def __init__(self, path: str):
        """Initialize with audio file.

        Args:
            path: Path to audio file
        """
        self.path = path
        self._duration: Optional[float] = None
        self._info: Optional[dict] = None

    @property
    def duration(self) -> float:
        """Audio duration in seconds."""
        if self._duration is None:
            self._duration = get_audio_duration(self.path)
        return self._duration

    @property
    def info(self) -> dict:
        """Audio file information."""
        if self._info is None:
            try:
                self._info = get_audio_info(self.path)
            except RuntimeError:
                self._info = {'duration': self.duration}
        return self._info

    def get_peaks(self, width: int = 100) -> List[float]:
        """Get peak values for visualization.

        Args:
            width: Number of samples (typically pixel width)

        Returns:
            List of peak values (0.0-1.0)
        """
        return get_audio_peaks(self.path, width)

    def get_waveform_data(self, width: int = 100) -> WaveformData:
        """Get complete waveform data.

        Args:
            width: Number of samples

        Returns:
            WaveformData with peaks and metadata
        """
        return WaveformData(
            peaks=self.get_peaks(width),
            duration=self.duration,
            sample_rate=self.info.get('sample_rate', 44100)
        )


@dataclass
class Beat:
    """A detected beat."""
    time: float
    strength: float  # 0.0-1.0


class BeatDetector:
    """Simple beat detection for music synchronization.

    Usage:
        detector = BeatDetector("music.mp3")
        beats = detector.detect_beats()

        for beat in beats:
            # Trigger animation on beat
            timeline.add_event(beat.time, EventType.CAMERA_SHAKE, ...)
    """

    def __init__(self, path: str):
        """Initialize with audio file.

        Args:
            path: Path to audio file
        """
        self.path = path
        self._duration = get_audio_duration(path)

    @property
    def duration(self) -> float:
        """Audio duration."""
        return self._duration

    def detect_beats(
        self,
        threshold: float = 0.5,
        min_interval: float = 0.25
    ) -> List[Beat]:
        """Detect beats in audio.

        Simple onset detection based on energy peaks.

        Args:
            threshold: Detection threshold (0.0-1.0)
            min_interval: Minimum time between beats

        Returns:
            List of detected beats
        """
        # Get dense peak data
        peaks = get_audio_peaks(self.path, num_samples=int(self._duration * 20))

        if not peaks:
            return []

        beats = []
        last_beat_time = -min_interval

        for i, peak in enumerate(peaks):
            time = i / 20  # 20 samples per second

            # Check if this is a significant peak
            if peak > threshold and (time - last_beat_time) >= min_interval:
                # Check if it's a local maximum
                is_local_max = True
                window = 3
                for j in range(max(0, i - window), min(len(peaks), i + window + 1)):
                    if j != i and peaks[j] > peak:
                        is_local_max = False
                        break

                if is_local_max:
                    beats.append(Beat(time=time, strength=peak))
                    last_beat_time = time

        return beats

    def estimate_bpm(self) -> Optional[float]:
        """Estimate beats per minute.

        Returns:
            Estimated BPM or None if not enough data
        """
        beats = self.detect_beats()

        if len(beats) < 4:
            return None

        # Calculate intervals between beats
        intervals = []
        for i in range(1, len(beats)):
            intervals.append(beats[i].time - beats[i-1].time)

        if not intervals:
            return None

        # Average interval
        avg_interval = sum(intervals) / len(intervals)

        if avg_interval <= 0:
            return None

        return 60.0 / avg_interval

    def get_beats_in_range(
        self,
        start: float,
        end: float,
        **kwargs
    ) -> List[Beat]:
        """Get beats within a time range.

        Args:
            start: Start time in seconds
            end: End time in seconds
            **kwargs: Arguments for detect_beats

        Returns:
            List of beats in range
        """
        all_beats = self.detect_beats(**kwargs)
        return [b for b in all_beats if start <= b.time < end]
