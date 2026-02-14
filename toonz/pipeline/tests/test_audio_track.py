"""Tests for audio.track module."""

from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

from pipeline.audio.track import (
    AudioEvent,
    AudioTrack,
    AudioMixer,
    AudioTimeline,
)


class TestAudioEvent:
    """Tests for AudioEvent dataclass."""

    def test_creation(self):
        """Test audio event creation."""
        event = AudioEvent(path="audio.wav", start_time=1.0)
        assert event.path == "audio.wav"
        assert event.start_time == 1.0
        assert event.volume == 1.0
        assert event.loop is False
        assert event.fade_in == 0.0
        assert event.fade_out == 0.0
        assert event.offset == 0.0
        assert event.duration is None

    def test_creation_with_options(self):
        """Test event with all options."""
        event = AudioEvent(
            path="music.mp3",
            start_time=0.0,
            volume=0.5,
            loop=True,
            fade_in=1.0,
            fade_out=2.0,
            offset=10.0,
            duration=60.0
        )
        assert event.volume == 0.5
        assert event.loop is True
        assert event.fade_in == 1.0
        assert event.fade_out == 2.0
        assert event.offset == 10.0
        assert event.duration == 60.0


class TestAudioTrack:
    """Tests for AudioTrack class."""

    def test_creation(self):
        """Test track creation."""
        track = AudioTrack(name="dialogue")
        assert track.name == "dialogue"
        assert len(track.events) == 0
        assert track.volume == 1.0
        assert track.pan == 0.0
        assert track.muted is False
        assert track.solo is False

    def test_add_audio(self):
        """Test adding audio to track."""
        track = AudioTrack(name="sfx")
        event = track.add_audio("explosion.wav", start_time=5.0, volume=0.8)

        assert len(track.events) == 1
        assert event.path == "explosion.wav"
        assert event.start_time == 5.0
        assert event.volume == 0.8

    def test_add_audio_with_options(self):
        """Test adding audio with all options."""
        track = AudioTrack(name="music")
        event = track.add_audio(
            "background.mp3",
            start_time=0.0,
            volume=0.5,
            loop=True,
            fade_in=2.0
        )

        assert event.loop is True
        assert event.fade_in == 2.0

    def test_get_events_at_time(self):
        """Test getting events playing at a time."""
        track = AudioTrack(name="test")
        # Use explicit duration instead of relying on _get_duration
        track.add_audio("clip1.wav", start_time=0.0, duration=5.0)
        track.add_audio("clip2.wav", start_time=3.0, duration=5.0)
        track.add_audio("clip3.wav", start_time=10.0, duration=5.0)

        # At time 2.0, only clip1 should be playing
        events = track.get_events_at_time(2.0)
        assert len(events) == 1
        assert events[0].path == "clip1.wav"

        # At time 4.0, clip1 and clip2 should be playing
        events = track.get_events_at_time(4.0)
        assert len(events) == 2

        # At time 8.0, only clip2 should be playing (clip1 ended at 5.0)
        events = track.get_events_at_time(6.0)
        assert len(events) == 1
        assert events[0].path == "clip2.wav"

    def test_get_events_at_time_looping(self):
        """Test looping events are always playing after start."""
        track = AudioTrack(name="music")
        track.add_audio("loop.mp3", start_time=0.0, loop=True)

        # Should still be playing at any time after start
        events = track.get_events_at_time(100.0)
        assert len(events) == 1


class TestAudioMixer:
    """Tests for AudioMixer class."""

    def test_creation(self):
        """Test mixer creation."""
        mixer = AudioMixer()
        assert len(mixer.tracks) == 0
        assert mixer.master_volume == 1.0

    def test_add_track(self):
        """Test adding tracks."""
        mixer = AudioMixer()
        track = mixer.add_track("dialogue", volume=1.0)

        assert track.name == "dialogue"
        assert "dialogue" in mixer.tracks

    def test_get_track(self):
        """Test getting track by name."""
        mixer = AudioMixer()
        mixer.add_track("test")

        assert mixer.get_track("test") is not None
        assert mixer.get_track("nonexistent") is None

    def test_remove_track(self):
        """Test removing track."""
        mixer = AudioMixer()
        mixer.add_track("test")

        assert mixer.remove_track("test") is True
        assert mixer.get_track("test") is None
        assert mixer.remove_track("nonexistent") is False

    @patch("subprocess.run")
    def test_export_empty_creates_silence(self, mock_run, temp_dir: Path):
        """Test exporting empty mixer creates silent audio."""
        mock_run.return_value = MagicMock(returncode=0)

        mixer = AudioMixer()
        output_path = temp_dir / "output.wav"

        result = mixer.export(str(output_path), duration=10.0)

        assert result is True
        # Check FFmpeg was called with silence generation
        call_args = mock_run.call_args[0][0]
        assert "anullsrc" in str(call_args)

    @patch("subprocess.run")
    def test_export_with_audio(self, mock_run, temp_dir: Path):
        """Test exporting with audio."""
        mock_run.return_value = MagicMock(returncode=0)

        # Create fake audio file
        audio_file = temp_dir / "clip.wav"
        audio_file.touch()

        mixer = AudioMixer()
        track = mixer.add_track("dialogue")
        track.add_audio(str(audio_file), start_time=0.0)

        output_path = temp_dir / "output.wav"
        result = mixer.export(str(output_path), duration=10.0)

        assert result is True

    @patch("subprocess.run")
    def test_export_respects_muted_tracks(self, mock_run, temp_dir: Path):
        """Test muted tracks are excluded from export."""
        mock_run.return_value = MagicMock(returncode=0)

        audio_file = temp_dir / "clip.wav"
        audio_file.touch()

        mixer = AudioMixer()
        track = mixer.add_track("muted")
        track.add_audio(str(audio_file), start_time=0.0)
        track.muted = True

        output_path = temp_dir / "output.wav"
        mixer.export(str(output_path), duration=10.0)

        # Should create silent audio since only track is muted
        call_args = mock_run.call_args[0][0]
        assert "anullsrc" in str(call_args)

    def test_export_ffmpeg_not_found(self, temp_dir: Path):
        """Test export handles missing FFmpeg."""
        mixer = AudioMixer()
        output_path = temp_dir / "output.wav"

        with patch("subprocess.run", side_effect=FileNotFoundError()):
            result = mixer.export(str(output_path), duration=10.0)

        assert result is False

    def test_get_timeline_events(self, temp_dir: Path):
        """Test getting sorted timeline events."""
        mixer = AudioMixer()

        track1 = mixer.add_track("dialogue")
        track1.add_audio("clip1.wav", start_time=1.0)

        track2 = mixer.add_track("sfx")
        track2.add_audio("clip2.wav", start_time=0.5)
        track2.add_audio("clip3.wav", start_time=2.0)

        events = mixer.get_timeline_events()

        assert len(events) == 3
        # Should be sorted by time
        assert events[0][0] == 0.5
        assert events[1][0] == 1.0
        assert events[2][0] == 2.0


class TestAudioTimeline:
    """Tests for AudioTimeline simplified interface."""

    def test_creation(self):
        """Test timeline creation."""
        timeline = AudioTimeline(duration=60.0)
        assert timeline.duration == 60.0
        assert timeline.mixer is not None
        # Should have pre-created tracks
        assert timeline.dialogue_track is not None
        assert timeline.music_track is not None
        assert timeline.sfx_track is not None
        assert timeline.ambient_track is not None

    def test_add_dialogue(self):
        """Test adding dialogue."""
        timeline = AudioTimeline()
        event = timeline.add_dialogue("speech.wav", start=5.0, volume=0.9)

        assert event.path == "speech.wav"
        assert event.start_time == 5.0
        assert event.volume == 0.9
        assert len(timeline.dialogue_track.events) == 1

    def test_add_music(self):
        """Test adding music."""
        timeline = AudioTimeline()
        event = timeline.add_music("bg.mp3", start=0.0, volume=0.3, loop=True)

        assert event.path == "bg.mp3"
        assert event.loop is True
        assert event.volume == 0.3
        assert len(timeline.music_track.events) == 1

    def test_add_sfx(self):
        """Test adding sound effect."""
        timeline = AudioTimeline()
        event = timeline.add_sfx("explosion.wav", start=10.0)

        assert event.path == "explosion.wav"
        assert event.start_time == 10.0
        assert len(timeline.sfx_track.events) == 1

    def test_add_ambient(self):
        """Test adding ambient sound."""
        timeline = AudioTimeline()
        event = timeline.add_ambient("forest.wav", start=0.0, loop=True)

        assert event.loop is True
        assert len(timeline.ambient_track.events) == 1

    @patch("subprocess.run")
    def test_export(self, mock_run, temp_dir: Path):
        """Test exporting timeline."""
        mock_run.return_value = MagicMock(returncode=0)

        timeline = AudioTimeline(duration=30.0)
        output_path = temp_dir / "final.wav"

        result = timeline.export(str(output_path))

        assert result is True
        # Check duration was passed correctly
        call_args = mock_run.call_args[0][0]
        assert "30.0" in str(call_args) or "30" in str(call_args)


class TestAudioTrackIntegration:
    """Integration tests for audio track system."""

    def test_multiple_tracks_with_events(self):
        """Test mixer with multiple tracks and events."""
        mixer = AudioMixer()
        mixer.master_volume = 0.8

        dialogue = mixer.add_track("dialogue", volume=1.0)
        dialogue.add_audio("intro.wav", start_time=0.0)
        dialogue.add_audio("main.wav", start_time=10.0)

        music = mixer.add_track("music", volume=0.5)
        music.add_audio("bg.mp3", start_time=0.0, loop=True, fade_in=2.0)

        sfx = mixer.add_track("sfx", volume=0.8)
        sfx.add_audio("impact.wav", start_time=5.0)
        sfx.add_audio("whoosh.wav", start_time=15.0)

        # Check all events are present
        all_events = mixer.get_timeline_events()
        assert len(all_events) == 5

        # Check sorting
        times = [e[0] for e in all_events]
        assert times == sorted(times)

    def test_track_volume_inheritance(self):
        """Test volume hierarchy (event * track * master)."""
        mixer = AudioMixer()
        mixer.master_volume = 0.5

        track = mixer.add_track("test", volume=0.8)
        event = track.add_audio("clip.wav", volume=0.5)

        # Final volume would be: 0.5 * 0.8 * 0.5 = 0.2
        # (This is calculated during export)
        assert event.volume == 0.5
        assert track.volume == 0.8
        assert mixer.master_volume == 0.5
