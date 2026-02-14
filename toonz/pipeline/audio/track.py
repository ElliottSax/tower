"""Audio track management for animation.

Provides audio track and mixer for multi-track audio.
"""

import os
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass
class AudioEvent:
    """An audio event on the timeline."""
    path: str
    start_time: float  # When to start playing
    volume: float = 1.0
    loop: bool = False
    fade_in: float = 0.0
    fade_out: float = 0.0
    offset: float = 0.0  # Start offset within audio file
    duration: Optional[float] = None  # Override audio duration


@dataclass
class AudioTrack:
    """A single audio track.

    Represents one audio layer (e.g., dialogue, music, sfx).
    """
    name: str
    events: List[AudioEvent] = field(default_factory=list)
    volume: float = 1.0
    pan: float = 0.0  # -1 to 1 (left to right)
    muted: bool = False
    solo: bool = False

    def add_audio(
        self,
        path: str,
        start_time: float = 0.0,
        volume: float = 1.0,
        **kwargs
    ) -> AudioEvent:
        """Add an audio event to this track.

        Args:
            path: Path to audio file
            start_time: When to start playing (seconds)
            volume: Volume multiplier (0-1)
            **kwargs: Additional AudioEvent parameters

        Returns:
            The created AudioEvent
        """
        event = AudioEvent(
            path=path,
            start_time=start_time,
            volume=volume,
            **kwargs
        )
        self.events.append(event)
        return event

    def get_events_at_time(self, time: float) -> List[AudioEvent]:
        """Get all events playing at a specific time."""
        playing = []
        for event in self.events:
            if event.start_time <= time:
                # Check if still playing
                duration = event.duration or self._get_duration(event.path)
                if duration and time < event.start_time + duration:
                    playing.append(event)
                elif event.loop:
                    playing.append(event)
        return playing

    def _get_duration(self, path: str) -> Optional[float]:
        """Get audio duration (requires ffprobe)."""
        try:
            from .analysis import get_audio_duration
            return get_audio_duration(path)
        except Exception:
            return None


class AudioMixer:
    """Multi-track audio mixer.

    Combines multiple audio tracks into a single output.

    Usage:
        mixer = AudioMixer()

        # Add tracks
        dialogue = mixer.add_track("dialogue")
        music = mixer.add_track("music", volume=0.5)
        sfx = mixer.add_track("sfx")

        # Add audio to tracks
        dialogue.add_audio("narration.wav", start_time=0)
        music.add_audio("background.mp3", start_time=0, loop=True)
        sfx.add_audio("explosion.wav", start_time=5.5)

        # Export final audio
        mixer.export("output.wav", duration=30.0)
    """

    def __init__(self):
        self.tracks: Dict[str, AudioTrack] = {}
        self.master_volume: float = 1.0

    def add_track(self, name: str, volume: float = 1.0) -> AudioTrack:
        """Add a new audio track.

        Args:
            name: Track name
            volume: Track volume

        Returns:
            The created track
        """
        track = AudioTrack(name=name, volume=volume)
        self.tracks[name] = track
        return track

    def get_track(self, name: str) -> Optional[AudioTrack]:
        """Get a track by name."""
        return self.tracks.get(name)

    def remove_track(self, name: str) -> bool:
        """Remove a track."""
        if name in self.tracks:
            del self.tracks[name]
            return True
        return False

    def export(
        self,
        output_path: str,
        duration: float,
        sample_rate: int = 44100,
        channels: int = 2
    ) -> bool:
        """Export mixed audio to file.

        Uses FFmpeg to mix all tracks.

        Args:
            output_path: Output file path
            duration: Total duration in seconds
            sample_rate: Audio sample rate
            channels: Number of audio channels

        Returns:
            True if successful
        """
        # Collect all audio events with timing
        inputs = []
        filter_parts = []

        for track_name, track in self.tracks.items():
            if track.muted:
                continue

            track_volume = track.volume * self.master_volume

            for i, event in enumerate(track.events):
                if not os.path.exists(event.path):
                    continue

                input_idx = len(inputs)
                inputs.extend(['-i', event.path])

                # Build filter for this event
                label = f"a{input_idx}"
                event_volume = event.volume * track_volume

                # Delay, volume, and pan
                filters = []

                # Delay to start time
                if event.start_time > 0:
                    delay_ms = int(event.start_time * 1000)
                    filters.append(f"adelay={delay_ms}|{delay_ms}")

                # Volume
                if event_volume != 1.0:
                    filters.append(f"volume={event_volume}")

                # Fade in/out
                if event.fade_in > 0:
                    filters.append(f"afade=t=in:st={event.start_time}:d={event.fade_in}")
                if event.fade_out > 0 and event.duration:
                    fade_start = event.start_time + event.duration - event.fade_out
                    filters.append(f"afade=t=out:st={fade_start}:d={event.fade_out}")

                # Pan
                if track.pan != 0:
                    # Convert -1..1 to left/right volumes
                    left = 1.0 - max(0, track.pan)
                    right = 1.0 + min(0, track.pan)
                    filters.append(f"pan=stereo|c0={left}*c0|c1={right}*c1")

                if filters:
                    filter_str = ",".join(filters)
                    filter_parts.append(f"[{input_idx}:a]{filter_str}[{label}]")
                else:
                    filter_parts.append(f"[{input_idx}:a]acopy[{label}]")

        if not inputs:
            # No audio - create silent audio
            cmd = [
                'ffmpeg', '-y',
                '-f', 'lavfi',
                '-i', f'anullsrc=r={sample_rate}:cl=stereo',
                '-t', str(duration),
                output_path
            ]
        else:
            # Build mix command
            num_streams = len(filter_parts)
            mix_labels = "".join(f"[a{i}]" for i in range(num_streams))
            filter_parts.append(f"{mix_labels}amix=inputs={num_streams}:duration=longest[out]")

            filter_complex = ";".join(filter_parts)

            cmd = [
                'ffmpeg', '-y',
                *inputs,
                '-filter_complex', filter_complex,
                '-map', '[out]',
                '-t', str(duration),
                '-ar', str(sample_rate),
                '-ac', str(channels),
                output_path
            ]

        try:
            result = subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"FFmpeg error: {e.stderr.decode()}")
            return False
        except FileNotFoundError:
            print("FFmpeg not found")
            return False

    def get_timeline_events(self) -> List[Tuple[float, str, AudioEvent]]:
        """Get all audio events sorted by time.

        Returns:
            List of (time, track_name, event) tuples
        """
        events = []
        for track_name, track in self.tracks.items():
            for event in track.events:
                events.append((event.start_time, track_name, event))
        return sorted(events, key=lambda x: x[0])


class AudioTimeline:
    """Simplified audio timeline for common use cases.

    Usage:
        timeline = AudioTimeline(duration=60.0)

        # Add audio clips
        timeline.add_dialogue("intro.wav", start=0)
        timeline.add_music("background.mp3", start=0, volume=0.3)
        timeline.add_sfx("whoosh.wav", start=5.0)

        # Export
        timeline.export("final_audio.wav")
    """

    def __init__(self, duration: float = 60.0):
        self.duration = duration
        self.mixer = AudioMixer()

        # Pre-create common tracks
        self.dialogue_track = self.mixer.add_track("dialogue", volume=1.0)
        self.music_track = self.mixer.add_track("music", volume=0.5)
        self.sfx_track = self.mixer.add_track("sfx", volume=0.8)
        self.ambient_track = self.mixer.add_track("ambient", volume=0.3)

    def add_dialogue(
        self,
        path: str,
        start: float = 0.0,
        volume: float = 1.0,
        **kwargs
    ) -> AudioEvent:
        """Add dialogue audio."""
        return self.dialogue_track.add_audio(path, start, volume, **kwargs)

    def add_music(
        self,
        path: str,
        start: float = 0.0,
        volume: float = 0.5,
        loop: bool = True,
        **kwargs
    ) -> AudioEvent:
        """Add background music."""
        return self.music_track.add_audio(path, start, volume, loop=loop, **kwargs)

    def add_sfx(
        self,
        path: str,
        start: float = 0.0,
        volume: float = 0.8,
        **kwargs
    ) -> AudioEvent:
        """Add sound effect."""
        return self.sfx_track.add_audio(path, start, volume, **kwargs)

    def add_ambient(
        self,
        path: str,
        start: float = 0.0,
        volume: float = 0.3,
        loop: bool = True,
        **kwargs
    ) -> AudioEvent:
        """Add ambient sound."""
        return self.ambient_track.add_audio(path, start, volume, loop=loop, **kwargs)

    def export(self, output_path: str) -> bool:
        """Export mixed audio."""
        return self.mixer.export(output_path, self.duration)
