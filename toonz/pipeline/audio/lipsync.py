"""Lip sync integration with Rhubarb.

Provides wrapper for Rhubarb lip sync tool and data structures.
"""

import json
import os
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional, Tuple


@dataclass
class MouthCue:
    """A single mouth shape cue."""
    start: float  # Start time in seconds
    end: float    # End time in seconds
    shape: str    # Mouth shape (A, B, C, D, E, F, G, H, X)

    @property
    def duration(self) -> float:
        """Duration of this cue."""
        return self.end - self.start

    def contains_time(self, time: float) -> bool:
        """Check if time falls within this cue."""
        return self.start <= time < self.end


@dataclass
class LipSyncData:
    """Complete lip sync data for an audio file."""
    duration: float  # Total audio duration
    cues: List[MouthCue] = field(default_factory=list)
    audio_path: Optional[str] = None
    transcript: Optional[str] = None

    # Metadata
    sound_offset: float = 0.0  # Offset for audio sync
    fps: int = 30  # Frame rate for frame-based lookups

    def get_shape_at_time(self, time: float) -> str:
        """Get the mouth shape at a specific time.

        Args:
            time: Time in seconds

        Returns:
            Mouth shape code (A-H, X)
        """
        adjusted_time = time - self.sound_offset
        for cue in self.cues:
            if cue.contains_time(adjusted_time):
                return cue.shape
        return 'X'  # Rest position

    def get_shape_at_frame(self, frame: int) -> str:
        """Get the mouth shape at a specific frame.

        Args:
            frame: Frame number

        Returns:
            Mouth shape code
        """
        time = frame / self.fps
        return self.get_shape_at_time(time)

    def get_cues_in_range(self, start: float, end: float) -> List[MouthCue]:
        """Get all cues that overlap with a time range."""
        return [
            cue for cue in self.cues
            if cue.end > start and cue.start < end
        ]

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            'duration': self.duration,
            'sound_offset': self.sound_offset,
            'fps': self.fps,
            'audio_path': self.audio_path,
            'transcript': self.transcript,
            'mouthCues': [
                {'start': c.start, 'end': c.end, 'value': c.shape}
                for c in self.cues
            ]
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'LipSyncData':
        """Create from dictionary."""
        lip_sync = cls(
            duration=data.get('duration', 0),
            sound_offset=data.get('sound_offset', 0),
            fps=data.get('fps', 30),
            audio_path=data.get('audio_path'),
            transcript=data.get('transcript')
        )
        for cue_data in data.get('mouthCues', []):
            lip_sync.cues.append(MouthCue(
                start=cue_data['start'],
                end=cue_data['end'],
                shape=cue_data['value']
            ))
        return lip_sync

    def save(self, path: str) -> None:
        """Save to JSON file."""
        with open(path, 'w') as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def load(cls, path: str) -> 'LipSyncData':
        """Load from JSON file."""
        with open(path) as f:
            return cls.from_dict(json.load(f))


class RhubarbLipSync:
    """Wrapper for Rhubarb Lip Sync tool.

    Rhubarb analyzes audio files and generates mouth shape timing data.

    Usage:
        rhubarb = RhubarbLipSync()

        # Generate lip sync
        lip_sync = rhubarb.analyze("audio.wav")

        # With transcript for better accuracy
        lip_sync = rhubarb.analyze("audio.wav", transcript="Hello world")

        # Use the data
        for frame in range(total_frames):
            shape = lip_sync.get_shape_at_frame(frame)
            character.set_mouth_shape(shape)
    """

    # Standard mouth shapes
    SHAPES = {
        'A': 'Closed mouth (M, B, P)',
        'B': 'Slightly open, teeth visible (most consonants)',
        'C': 'Open mouth (most vowels)',
        'D': 'Wide open (AH sound)',
        'E': 'Rounded open (O sound)',
        'F': 'Puckered (OO, W)',
        'G': 'F, V sounds (teeth on lip)',
        'H': 'L sound (tongue visible)',
        'X': 'Rest/silence',
    }

    def __init__(self, executable: str = 'rhubarb'):
        """Initialize Rhubarb wrapper.

        Args:
            executable: Path to rhubarb executable
        """
        self.executable = executable
        self._verify_installation()

    def _verify_installation(self) -> bool:
        """Check if Rhubarb is installed and accessible."""
        try:
            result = subprocess.run(
                [self.executable, '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.SubprocessError, FileNotFoundError):
            return False

    @property
    def is_available(self) -> bool:
        """Check if Rhubarb is available."""
        return self._verify_installation()

    def analyze(
        self,
        audio_path: str,
        transcript: Optional[str] = None,
        transcript_file: Optional[str] = None,
        extended_shapes: str = "GHX",
        recognizer: str = "pocketSphinx",
        on_progress: Optional[Callable[[float, str], None]] = None
    ) -> LipSyncData:
        """Analyze audio file and generate lip sync data.

        Args:
            audio_path: Path to audio file (WAV, OGG, MP3)
            transcript: Optional transcript text
            transcript_file: Optional path to transcript file
            extended_shapes: Extended mouth shapes to use (G, H, X)
            recognizer: Speech recognizer (pocketSphinx, phonetic)
            on_progress: Progress callback (progress: float, message: str)

        Returns:
            LipSyncData with mouth cues

        Raises:
            FileNotFoundError: If audio file doesn't exist
            RuntimeError: If Rhubarb fails
        """
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        # Build command
        cmd = [
            self.executable,
            '-f', 'json',
            '--machineReadable',
            '-r', recognizer,
        ]

        if extended_shapes:
            cmd.extend(['--extendedShapes', extended_shapes])

        # Handle transcript
        temp_transcript = None
        if transcript:
            # Write transcript to temp file
            temp_transcript = tempfile.NamedTemporaryFile(
                mode='w', suffix='.txt', delete=False
            )
            temp_transcript.write(transcript)
            temp_transcript.close()
            cmd.extend(['--dialogFile', temp_transcript.name])
        elif transcript_file:
            cmd.extend(['--dialogFile', transcript_file])

        cmd.append(audio_path)

        try:
            # Run Rhubarb
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Parse progress from stderr
            if on_progress:
                for line in process.stderr:
                    try:
                        event = json.loads(line.strip())
                        if event.get('type') == 'progress':
                            on_progress(event['value'], event.get('log', ''))
                    except json.JSONDecodeError:
                        pass

            stdout, stderr = process.communicate()

            if process.returncode != 0:
                raise RuntimeError(f"Rhubarb failed: {stderr}")

            # Parse output
            result = json.loads(stdout)

            # Create LipSyncData
            lip_sync = LipSyncData(
                duration=result.get('metadata', {}).get('duration', 0),
                audio_path=audio_path,
                transcript=transcript
            )

            for cue_data in result.get('mouthCues', []):
                lip_sync.cues.append(MouthCue(
                    start=cue_data['start'],
                    end=cue_data['end'],
                    shape=cue_data['value']
                ))

            return lip_sync

        finally:
            # Cleanup temp transcript
            if temp_transcript and os.path.exists(temp_transcript.name):
                os.unlink(temp_transcript.name)

    def analyze_with_fallback(
        self,
        audio_path: str,
        transcript: Optional[str] = None,
        **kwargs
    ) -> LipSyncData:
        """Analyze with fallback to simulated data if Rhubarb unavailable.

        This allows development/testing without Rhubarb installed.
        """
        if self.is_available:
            return self.analyze(audio_path, transcript, **kwargs)
        else:
            print("Warning: Rhubarb not available, using simulated lip sync")
            return self._simulate_lipsync(audio_path, transcript)

    def _simulate_lipsync(
        self,
        audio_path: str,
        transcript: Optional[str] = None
    ) -> LipSyncData:
        """Generate simulated lip sync data for testing.

        Creates rough lip sync based on transcript or generic patterns.
        """
        # Try to get audio duration
        try:
            from .analysis import get_audio_duration
            duration = get_audio_duration(audio_path)
        except Exception:
            duration = 5.0  # Default fallback

        lip_sync = LipSyncData(
            duration=duration,
            audio_path=audio_path,
            transcript=transcript
        )

        if transcript:
            # Generate cues from transcript
            self._generate_cues_from_text(lip_sync, transcript, duration)
        else:
            # Generate generic speaking pattern
            self._generate_generic_cues(lip_sync, duration)

        return lip_sync

    def _generate_cues_from_text(
        self,
        lip_sync: LipSyncData,
        text: str,
        duration: float
    ) -> None:
        """Generate approximate cues from text."""
        # Simple phoneme mapping
        vowels = 'aeiouAEIOU'
        consonants = 'bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ'

        # Calculate timing
        chars = [c for c in text if c.isalpha()]
        if not chars:
            return

        char_duration = duration / len(chars)
        current_time = 0.0

        for char in text:
            if not char.isalpha():
                if char == ' ':
                    # Brief pause at word boundaries
                    lip_sync.cues.append(MouthCue(
                        current_time, current_time + char_duration * 0.3, 'X'
                    ))
                    current_time += char_duration * 0.3
                continue

            # Map character to mouth shape
            if char.lower() in 'aei':
                shape = 'C'  # Open
            elif char.lower() == 'o':
                shape = 'E'  # Rounded
            elif char.lower() == 'u':
                shape = 'F'  # Puckered
            elif char.lower() in 'mbp':
                shape = 'A'  # Closed
            elif char.lower() in 'fv':
                shape = 'G'  # F/V
            elif char.lower() == 'l':
                shape = 'H'  # L
            else:
                shape = 'B'  # General consonant

            end_time = current_time + char_duration
            lip_sync.cues.append(MouthCue(current_time, end_time, shape))
            current_time = end_time

    def _generate_generic_cues(
        self,
        lip_sync: LipSyncData,
        duration: float
    ) -> None:
        """Generate generic speaking pattern."""
        import random

        shapes = ['B', 'C', 'D', 'E', 'B', 'C', 'A', 'X']
        current_time = 0.0

        while current_time < duration:
            shape = random.choice(shapes)
            cue_duration = random.uniform(0.05, 0.15)

            end_time = min(current_time + cue_duration, duration)
            lip_sync.cues.append(MouthCue(current_time, end_time, shape))
            current_time = end_time


def generate_lipsync(
    audio_path: str,
    transcript: Optional[str] = None,
    transcript_file: Optional[str] = None,
    output_path: Optional[str] = None,
    **kwargs
) -> LipSyncData:
    """Convenience function to generate lip sync data.

    Args:
        audio_path: Path to audio file
        transcript: Optional transcript text
        transcript_file: Optional transcript file path
        output_path: Optional path to save lip sync JSON
        **kwargs: Additional arguments for RhubarbLipSync.analyze

    Returns:
        LipSyncData
    """
    rhubarb = RhubarbLipSync()
    lip_sync = rhubarb.analyze_with_fallback(
        audio_path,
        transcript=transcript,
        transcript_file=transcript_file,
        **kwargs
    )

    if output_path:
        lip_sync.save(output_path)

    return lip_sync
