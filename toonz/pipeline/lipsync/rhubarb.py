"""Rhubarb Lip Sync integration.

This module wraps the Rhubarb CLI tool for generating lip sync data from audio.
Rhubarb analyzes audio and outputs mouth shape cues (A-F, optionally G, H, X)
with precise timing information.

Mouth Shapes:
    A - Closed mouth (P, B, M sounds)
    B - Clenched teeth (K, S, T consonants)
    C - Open mouth (E, AE vowels)
    D - Wide open (AA vowels)
    E - Slightly rounded (AO, ER sounds)
    F - Puckered lips (UW, OW, W sounds)
    G - Upper teeth on lower lip (F, V sounds) - optional
    H - Tongue raised (L sounds) - optional
    X - Rest/idle position - optional
"""

import subprocess
import json
from dataclasses import dataclass
from typing import Optional, Callable, List
from pathlib import Path


@dataclass
class MouthCue:
    """A single mouth shape cue with timing information."""
    start: float  # Start time in seconds
    end: float    # End time in seconds
    shape: str    # Mouth shape code (A, B, C, D, E, F, G, H, X)

    @property
    def duration(self) -> float:
        """Duration of this cue in seconds."""
        return self.end - self.start

    def get_frame_range(self, fps: float) -> tuple[int, int]:
        """Get the frame range for this cue at the given FPS."""
        start_frame = int(self.start * fps)
        end_frame = int(self.end * fps)
        return start_frame, end_frame


@dataclass
class LipSyncData:
    """Complete lip sync data from Rhubarb analysis."""
    duration: float           # Total audio duration in seconds
    cues: List[MouthCue]      # List of mouth shape cues
    audio_path: Optional[str] = None
    fps: float = 30.0         # Frame rate for frame-based lookups

    def get_shape_at_time(self, time: float) -> str:
        """Get the mouth shape at a specific time."""
        for cue in self.cues:
            if cue.start <= time < cue.end:
                return cue.shape
        return 'X'  # Default to rest position

    def get_shape_at_frame(self, frame: int, fps: Optional[float] = None) -> str:
        """Get the mouth shape at a specific frame.

        Args:
            frame: Frame number
            fps: Frames per second. If None, uses self.fps.
        """
        effective_fps = fps if fps is not None else self.fps
        time = frame / effective_fps
        return self.get_shape_at_time(time)

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "metadata": {
                "duration": self.duration,
                "soundFile": self.audio_path
            },
            "mouthCues": [
                {"start": c.start, "end": c.end, "value": c.shape}
                for c in self.cues
            ]
        }

    @classmethod
    def from_dict(cls, data: dict) -> "LipSyncData":
        """Create from dictionary (Rhubarb JSON output format)."""
        metadata = data.get("metadata", {})
        cues = [
            MouthCue(
                start=c["start"],
                end=c["end"],
                shape=c["value"]
            )
            for c in data.get("mouthCues", [])
        ]
        return cls(
            duration=metadata.get("duration", 0),
            cues=cues,
            audio_path=metadata.get("soundFile")
        )

    def save(self, path: str) -> None:
        """Save lip sync data to JSON file."""
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2)

    @classmethod
    def load(cls, path: str) -> "LipSyncData":
        """Load lip sync data from JSON file."""
        with open(path, 'r', encoding='utf-8') as f:
            return cls.from_dict(json.load(f))


class RhubarbError(Exception):
    """Error from Rhubarb processing."""
    pass


class RhubarbWrapper:
    """Wrapper for the Rhubarb Lip Sync CLI tool.

    Usage:
        rhubarb = RhubarbWrapper()
        lipsync = rhubarb.analyze("audio.wav", "transcript.txt")
        for cue in lipsync.cues:
            print(f"{cue.start:.2f}s - {cue.end:.2f}s: {cue.shape}")
    """

    # Standard Rhubarb mouth shapes
    BASIC_SHAPES = ['A', 'B', 'C', 'D', 'E', 'F']
    EXTENDED_SHAPES = ['G', 'H', 'X']
    ALL_SHAPES = BASIC_SHAPES + EXTENDED_SHAPES

    def __init__(self, executable: str = "rhubarb"):
        """Initialize Rhubarb wrapper.

        Args:
            executable: Path to Rhubarb executable (default: "rhubarb" in PATH)
        """
        self.executable = executable

    def analyze(
        self,
        audio_path: str,
        transcript_path: Optional[str] = None,
        extended_shapes: str = "GHX",
        recognizer: str = "pocketSphinx",
        on_progress: Optional[Callable[[float], None]] = None
    ) -> LipSyncData:
        """Analyze audio and generate lip sync data.

        Args:
            audio_path: Path to audio file (.wav, .ogg, etc.)
            transcript_path: Optional path to transcript file for better accuracy
            extended_shapes: Which extended shapes to include ("G", "H", "X", or combination)
            recognizer: Speech recognizer to use ("pocketSphinx" or "phonetic")
            on_progress: Optional callback for progress updates (0.0 to 1.0)

        Returns:
            LipSyncData with mouth cues

        Raises:
            RhubarbError: If Rhubarb processing fails
            FileNotFoundError: If audio file not found
        """
        audio_path = str(Path(audio_path).resolve())

        if not Path(audio_path).exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        # Build command
        cmd = [
            self.executable,
            "-f", "json",
            "--machineReadable",
            "-r", recognizer,
            audio_path
        ]

        if extended_shapes:
            cmd.extend(["--extendedShapes", extended_shapes])

        if transcript_path:
            transcript_path = str(Path(transcript_path).resolve())
            if not Path(transcript_path).exists():
                raise FileNotFoundError(f"Transcript file not found: {transcript_path}")
            cmd.extend(["--dialogFile", transcript_path])

        try:
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Parse progress from stderr (machine-readable JSON events)
            stderr_lines = []
            for line in process.stderr:
                line = line.strip()
                if not line:
                    continue
                stderr_lines.append(line)

                try:
                    event = json.loads(line)
                    if event.get('type') == 'progress' and on_progress:
                        on_progress(event.get('value', 0))
                    elif event.get('type') == 'failure':
                        raise RhubarbError(event.get('reason', 'Unknown error'))
                except json.JSONDecodeError:
                    # Not all lines are JSON
                    pass

            stdout, _ = process.communicate()

            if process.returncode != 0:
                raise RhubarbError(
                    f"Rhubarb exited with code {process.returncode}. "
                    f"stderr: {' '.join(stderr_lines[-5:])}"
                )

            if not stdout.strip():
                raise RhubarbError("Rhubarb produced no output")

            # Parse JSON result
            result = json.loads(stdout)
            lipsync = LipSyncData.from_dict(result)
            lipsync.audio_path = audio_path
            return lipsync

        except FileNotFoundError:
            raise RhubarbError(
                f"Rhubarb executable not found: {self.executable}. "
                "Make sure Rhubarb is installed and in PATH."
            )
        except json.JSONDecodeError as e:
            raise RhubarbError(f"Failed to parse Rhubarb output: {e}")

    def analyze_to_file(
        self,
        audio_path: str,
        output_path: str,
        transcript_path: Optional[str] = None,
        extended_shapes: str = "GHX",
        recognizer: str = "pocketSphinx",
        on_progress: Optional[Callable[[float], None]] = None
    ) -> LipSyncData:
        """Analyze audio and save lip sync data to file.

        Same as analyze() but also saves the result to a JSON file.
        """
        lipsync = self.analyze(
            audio_path,
            transcript_path,
            extended_shapes,
            recognizer,
            on_progress
        )
        lipsync.save(output_path)
        return lipsync

    @staticmethod
    def get_shape_description(shape: str) -> str:
        """Get a human-readable description of a mouth shape."""
        descriptions = {
            'A': "Closed mouth (P, B, M)",
            'B': "Clenched teeth (K, S, T)",
            'C': "Open mouth (E, AE)",
            'D': "Wide open (AA)",
            'E': "Slightly rounded (AO, ER)",
            'F': "Puckered lips (UW, OW, W)",
            'G': "Upper teeth on lower lip (F, V)",
            'H': "Tongue raised (L)",
            'X': "Rest/idle position"
        }
        return descriptions.get(shape, f"Unknown shape: {shape}")
