"""Tests for animation.timeline module."""

import pytest

from pipeline.animation.timeline import (
    EventType,
    TimelineEvent,
    TimelineTrack,
    Timeline,
    TimelineBuilder,
    LipSyncTimeline,
    AnimationSequence,
    create_greeting_sequence,
    create_reaction_sequence,
    create_thinking_sequence,
    create_celebration_sequence,
)


class TestEventType:
    """Tests for EventType enum."""

    def test_all_event_types_exist(self):
        """Test all expected event types exist."""
        assert EventType.SET_EMOTION
        assert EventType.PLAY_MOTION
        assert EventType.SET_MOUTH_SHAPE
        assert EventType.CAMERA_MOVE
        assert EventType.CAMERA_SHAKE
        assert EventType.PLAY_AUDIO
        assert EventType.SHOW_LAYER
        assert EventType.HIDE_LAYER
        assert EventType.CALLBACK


class TestTimelineEvent:
    """Tests for TimelineEvent dataclass."""

    def test_creation(self):
        """Test event creation."""
        event = TimelineEvent(
            time=1.5,
            event_type=EventType.SET_EMOTION,
            target="character",
            params={"emotion": "happy"}
        )
        assert event.time == 1.5
        assert event.event_type == EventType.SET_EMOTION
        assert event.target == "character"
        assert event.params["emotion"] == "happy"
        assert event.duration == 0.0

    def test_ordering(self):
        """Test event ordering by time."""
        event1 = TimelineEvent(time=1.0, event_type=EventType.SET_EMOTION, target="a")
        event2 = TimelineEvent(time=2.0, event_type=EventType.SET_EMOTION, target="b")
        event3 = TimelineEvent(time=0.5, event_type=EventType.SET_EMOTION, target="c")

        sorted_events = sorted([event1, event2, event3])

        assert sorted_events[0].target == "c"
        assert sorted_events[1].target == "a"
        assert sorted_events[2].target == "b"


class TestTimelineTrack:
    """Tests for TimelineTrack class."""

    def test_creation(self):
        """Test track creation."""
        track = TimelineTrack(name="emotions", target="character")
        assert track.name == "emotions"
        assert track.target == "character"
        assert len(track.events) == 0
        assert track.muted is False

    def test_add_event_sorted(self):
        """Test events are added in sorted order."""
        track = TimelineTrack(name="test", target="char")

        event2 = TimelineEvent(time=2.0, event_type=EventType.SET_EMOTION, target="char")
        event1 = TimelineEvent(time=1.0, event_type=EventType.SET_EMOTION, target="char")
        event3 = TimelineEvent(time=3.0, event_type=EventType.SET_EMOTION, target="char")

        track.add_event(event2)
        track.add_event(event1)
        track.add_event(event3)

        assert track.events[0].time == 1.0
        assert track.events[1].time == 2.0
        assert track.events[2].time == 3.0

    def test_get_events_in_range(self):
        """Test getting events in time range."""
        track = TimelineTrack(name="test", target="char")
        track.add_event(TimelineEvent(time=1.0, event_type=EventType.SET_EMOTION, target="char"))
        track.add_event(TimelineEvent(time=2.0, event_type=EventType.SET_EMOTION, target="char"))
        track.add_event(TimelineEvent(time=3.0, event_type=EventType.SET_EMOTION, target="char"))
        track.add_event(TimelineEvent(time=4.0, event_type=EventType.SET_EMOTION, target="char"))

        events = track.get_events_in_range(1.5, 3.5)

        assert len(events) == 2
        assert events[0].time == 2.0
        assert events[1].time == 3.0

    def test_get_active_event(self):
        """Test getting active event at time."""
        track = TimelineTrack(name="test", target="char")
        track.add_event(TimelineEvent(
            time=1.0,
            event_type=EventType.PLAY_MOTION,
            target="char",
            duration=2.0
        ))
        track.add_event(TimelineEvent(
            time=5.0,
            event_type=EventType.PLAY_MOTION,
            target="char",
            duration=1.0
        ))

        # During first event
        active = track.get_active_event(2.0)
        assert active is not None
        assert active.time == 1.0

        # Between events
        active = track.get_active_event(4.0)
        # Returns last non-duration event or None
        assert active is None or active.time == 1.0

        # During second event
        active = track.get_active_event(5.5)
        assert active is not None
        assert active.time == 5.0


class TestTimeline:
    """Tests for Timeline class."""

    def test_creation(self):
        """Test timeline creation."""
        timeline = Timeline(duration=30.0, fps=30)
        assert timeline.duration == 30.0
        assert timeline.fps == 30
        assert timeline.total_frames == 900

    def test_frame_duration(self):
        """Test frame duration calculation."""
        timeline = Timeline(fps=30)
        assert timeline.frame_duration == pytest.approx(1/30)

        timeline24 = Timeline(fps=24)
        assert timeline24.frame_duration == pytest.approx(1/24)

    def test_add_track(self):
        """Test adding tracks."""
        timeline = Timeline()
        track = timeline.add_track("emotions", "character")

        assert track.name == "emotions"
        assert "emotions" in timeline.tracks

    def test_get_or_create_track(self):
        """Test get or create track."""
        timeline = Timeline()

        # Create new
        track1 = timeline.get_or_create_track("character")
        assert track1 is not None

        # Get existing
        track2 = timeline.get_or_create_track("character")
        assert track2 is track1

    def test_add_event(self):
        """Test adding events."""
        timeline = Timeline()
        event = timeline.add_event(1.0, EventType.SET_EMOTION, "character", emotion="happy")

        assert event.time == 1.0
        assert event.params["emotion"] == "happy"
        assert len(timeline.tracks) == 1

    def test_add_marker(self):
        """Test adding markers."""
        timeline = Timeline()
        timeline.add_marker("intro_end", 5.0)
        timeline.add_marker("climax", 20.0)

        assert timeline.get_marker("intro_end") == 5.0
        assert timeline.get_marker("climax") == 20.0
        assert timeline.get_marker("nonexistent") is None

    def test_goto_marker(self):
        """Test jumping to markers."""
        timeline = Timeline()
        timeline.add_marker("start", 5.0)

        assert timeline.goto_marker("start") is True
        assert timeline.current_time == 5.0

        assert timeline.goto_marker("nonexistent") is False

    def test_get_events_at_time(self):
        """Test getting events at specific time."""
        timeline = Timeline(fps=30)
        timeline.add_event(1.0, EventType.SET_EMOTION, "char1", emotion="happy")
        timeline.add_event(1.0, EventType.SET_EMOTION, "char2", emotion="sad")
        timeline.add_event(2.0, EventType.SET_EMOTION, "char1", emotion="neutral")

        events = timeline.get_events_at_time(1.0)
        assert len(events) == 2

        events = timeline.get_events_at_time(2.0)
        assert len(events) == 1

    def test_get_events_at_frame(self):
        """Test getting events at specific frame."""
        timeline = Timeline(fps=30)
        timeline.add_event(1.0, EventType.SET_EMOTION, "char", emotion="happy")

        # Frame 30 at 30fps = 1.0 second
        events = timeline.get_events_at_frame(30)
        assert len(events) == 1

    def test_get_events_in_range(self):
        """Test getting events in time range."""
        timeline = Timeline()
        timeline.add_event(1.0, EventType.SET_EMOTION, "char")
        timeline.add_event(2.0, EventType.SET_EMOTION, "char")
        timeline.add_event(3.0, EventType.SET_EMOTION, "char")

        events = timeline.get_events_in_range(1.5, 2.5)
        assert len(events) == 1
        assert events[0].time == 2.0

    def test_muted_tracks_excluded(self):
        """Test muted tracks are excluded from queries."""
        timeline = Timeline()
        timeline.add_event(1.0, EventType.SET_EMOTION, "char1")
        timeline.add_event(1.0, EventType.SET_EMOTION, "char2")

        # Mute one track
        timeline.tracks["track_char1"].muted = True

        events = timeline.get_events_at_time(1.0)
        assert len(events) == 1
        assert events[0].target == "char2"

    def test_play_pause_stop(self):
        """Test playback controls."""
        timeline = Timeline()

        assert timeline._is_playing is False

        timeline.play()
        assert timeline._is_playing is True

        timeline.pause()
        assert timeline._is_playing is False

        timeline.seek(5.0)
        assert timeline.current_time == 5.0

        timeline.stop()
        assert timeline._is_playing is False
        assert timeline.current_time == 0.0

    def test_seek(self):
        """Test seeking."""
        timeline = Timeline(duration=10.0)

        timeline.seek(5.0)
        assert timeline.current_time == 5.0

        # Clamp to bounds
        timeline.seek(-1.0)
        assert timeline.current_time == 0.0

        timeline.seek(100.0)
        assert timeline.current_time == 10.0

    def test_seek_frame(self):
        """Test seeking by frame."""
        timeline = Timeline(duration=10.0, fps=30)

        timeline.seek_frame(150)  # 5 seconds
        assert timeline.current_time == 5.0

    def test_update(self):
        """Test timeline update."""
        timeline = Timeline(duration=10.0)
        timeline.add_event(0.5, EventType.SET_EMOTION, "char", emotion="happy")
        timeline.play()

        events = timeline.update(1.0)

        assert timeline.current_time == 1.0
        assert len(events) == 1

    def test_update_loop(self):
        """Test timeline looping."""
        timeline = Timeline(duration=2.0)
        timeline.play(loop=True)

        timeline.update(3.0)

        assert timeline.current_time == pytest.approx(1.0)
        assert timeline._is_playing is True

    def test_register_handler(self):
        """Test event handler registration."""
        timeline = Timeline()
        timeline.add_event(0.5, EventType.SET_EMOTION, "char")

        handled_events = []

        def handler(event):
            handled_events.append(event)

        timeline.register_handler(EventType.SET_EMOTION, handler)
        timeline.play()
        timeline.update(1.0)

        assert len(handled_events) == 1


class TestTimelineBuilder:
    """Tests for TimelineBuilder fluent interface."""

    def test_basic_build(self):
        """Test basic timeline building."""
        timeline = (TimelineBuilder(duration=10.0, fps=30)
            .at(0.0).emotion("character", "happy")
            .at(5.0).emotion("character", "sad")
            .build())

        assert timeline.duration == 10.0
        events = timeline.get_events_in_range(0, 10)
        assert len(events) == 2

    def test_chaining(self):
        """Test method chaining."""
        builder = TimelineBuilder(duration=10.0)

        result = builder.at(1.0)
        assert result is builder

        result = builder.emotion("char", "happy")
        assert result is builder

        result = builder.after(1.0)
        assert result is builder
        assert builder._current_time == 2.0

    def test_marker(self):
        """Test adding markers via builder."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(5.0).marker("halfway")
            .build())

        assert timeline.get_marker("halfway") == 5.0

    def test_speak(self):
        """Test speak helper."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(1.0).speak("narrator", 2.0)
            .build())

        events = timeline.get_events_in_range(0, 5)
        # Should have START_SPEAKING at 1.0 and STOP_SPEAKING at 3.0
        event_types = [e.event_type for e in events]
        assert EventType.START_SPEAKING in event_types
        assert EventType.STOP_SPEAKING in event_types

    def test_camera_shake(self):
        """Test camera shake helper."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(2.0).camera_shake("impact", intensity=0.5, duration=0.5)
            .build())

        events = timeline.get_events_at_time(2.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.CAMERA_SHAKE
        assert events[0].params["shake_type"] == "impact"
        assert events[0].params["intensity"] == 0.5


class TestLipSyncTimeline:
    """Tests for LipSyncTimeline class."""

    def test_creation(self):
        """Test creation."""
        ls = LipSyncTimeline("narrator")
        assert ls.character == "narrator"
        assert len(ls.cues) == 0

    def test_add_cue(self):
        """Test adding cues."""
        ls = LipSyncTimeline("char")
        ls.add_cue(0.0, 0.5, "A")
        ls.add_cue(0.5, 1.0, "B")

        assert len(ls.cues) == 2

    def test_add_invalid_cue(self):
        """Test invalid shape is ignored."""
        ls = LipSyncTimeline("char")
        ls.add_cue(0.0, 0.5, "Z")  # Invalid shape

        assert len(ls.cues) == 0

    def test_load_from_rhubarb_json(self):
        """Test loading from Rhubarb format."""
        data = {
            "mouthCues": [
                {"start": 0.0, "end": 0.5, "value": "A"},
                {"start": 0.5, "end": 1.0, "value": "B"},
                {"start": 1.0, "end": 1.5, "value": "C"},
            ]
        }

        ls = LipSyncTimeline("char")
        ls.load_from_rhubarb_json(data)

        assert len(ls.cues) == 3

    def test_get_shape_at_time(self):
        """Test getting shape at time."""
        ls = LipSyncTimeline("char")
        ls.add_cue(0.0, 1.0, "A")
        ls.add_cue(1.0, 2.0, "B")

        assert ls.get_shape_at_time(0.5) == "A"
        assert ls.get_shape_at_time(1.5) == "B"
        assert ls.get_shape_at_time(3.0) == "X"  # Rest

    def test_to_timeline_events(self):
        """Test converting to timeline events."""
        ls = LipSyncTimeline("char")
        ls.add_cue(0.0, 0.5, "A")
        ls.add_cue(0.5, 1.0, "B")

        timeline = Timeline(duration=5.0)
        ls.to_timeline_events(timeline)

        events = timeline.get_events_in_range(0, 2)
        assert len(events) == 2
        assert all(e.event_type == EventType.SET_MOUTH_SHAPE for e in events)


class TestAnimationSequence:
    """Tests for AnimationSequence class."""

    def test_creation(self):
        """Test sequence creation."""
        seq = AnimationSequence("test", duration=2.0)
        assert seq.name == "test"
        assert seq._duration == 2.0

    def test_duration_auto(self):
        """Test auto duration calculation."""
        seq = AnimationSequence("test")
        seq.add_event(0.0, EventType.SET_EMOTION, "char")
        seq.add_event(1.0, EventType.SET_EMOTION, "char", duration=0.5)

        assert seq.duration == 1.5

    def test_add_event(self):
        """Test adding events returns self for chaining."""
        seq = AnimationSequence("test")
        result = seq.add_event(0.0, EventType.SET_EMOTION, "char")

        assert result is seq
        assert len(seq.events) == 1

    def test_insert_into_timeline(self):
        """Test inserting sequence into timeline."""
        seq = AnimationSequence("wave")
        seq.add_event(0.0, EventType.SET_EMOTION, "char", emotion="happy")
        seq.add_event(0.5, EventType.PLAY_MOTION, "char", motion="wave")

        timeline = Timeline(duration=10.0)
        seq.insert_into(timeline, start_time=2.0)

        events = timeline.get_events_in_range(0, 5)
        assert len(events) == 2
        assert events[0].time == 2.0
        assert events[1].time == 2.5

    def test_insert_with_target_mapping(self):
        """Test inserting with target remapping."""
        seq = AnimationSequence("generic")
        seq.add_event(0.0, EventType.SET_EMOTION, "character", emotion="happy")

        timeline = Timeline(duration=10.0)
        seq.insert_into(timeline, 0.0, target_mapping={"character": "narrator"})

        events = timeline.get_events_at_time(0.0)
        assert events[0].target == "narrator"


class TestPrebuildSequences:
    """Tests for pre-built sequences."""

    def test_greeting_sequence(self):
        """Test greeting sequence."""
        seq = create_greeting_sequence("char")
        assert seq.name == "greeting"
        assert seq.duration == 2.0
        assert len(seq.events) > 0

    def test_reaction_sequence(self):
        """Test reaction sequence."""
        seq = create_reaction_sequence("char", "surprised")
        assert seq.name == "reaction"
        assert len(seq.events) > 0

        # Should include camera shake for surprised
        event_types = [e.event_type for e in seq.events]
        assert EventType.CAMERA_SHAKE in event_types

    def test_thinking_sequence(self):
        """Test thinking sequence."""
        seq = create_thinking_sequence("char")
        assert seq.name == "thinking"
        assert seq.duration == 3.0
        assert len(seq.events) > 0

        # Should have emotion changes
        event_types = [e.event_type for e in seq.events]
        assert EventType.SET_EMOTION in event_types
        assert EventType.PLAY_MOTION in event_types

    def test_thinking_sequence_custom_duration(self):
        """Test thinking sequence with custom duration."""
        seq = create_thinking_sequence("char", duration=5.0)
        assert seq.duration == 5.0

    def test_celebration_sequence(self):
        """Test celebration sequence."""
        seq = create_celebration_sequence("char")
        assert seq.name == "celebration"
        assert seq.duration == 2.0
        assert len(seq.events) > 0

        # Should include particles and camera effects
        event_types = [e.event_type for e in seq.events]
        assert EventType.SET_EMOTION in event_types
        assert EventType.START_PARTICLES in event_types
        assert EventType.CAMERA_SHAKE in event_types


class TestTimelineTrackAdditional:
    """Additional tests for TimelineTrack."""

    def test_get_active_event_non_duration(self):
        """Test getting active event for instant (non-duration) events."""
        track = TimelineTrack(name="test", target="char")
        # Add instant event (duration=0)
        track.add_event(TimelineEvent(
            time=1.0,
            event_type=EventType.SET_EMOTION,
            target="char",
            duration=0  # Instant event
        ))

        # After the event time, it should still be "active" as last event
        active = track.get_active_event(2.0)
        assert active is not None
        assert active.time == 1.0


class TestTimelineAdditional:
    """Additional tests for Timeline class."""

    def test_current_frame_property(self):
        """Test current_frame property."""
        timeline = Timeline(duration=10.0, fps=30)
        timeline.seek(2.0)
        assert timeline.current_frame == 60  # 2.0 * 30 = 60

    def test_get_active_events(self):
        """Test get_active_events method."""
        timeline = Timeline(duration=10.0)
        # Add duration event
        timeline.add_event(1.0, EventType.PLAY_MOTION, "char1", duration=2.0, motion="wave")
        timeline.add_event(1.5, EventType.PLAY_MOTION, "char2", duration=1.0, motion="nod")

        # At time 2.0, both should be active
        active = timeline.get_active_events(2.0)
        assert len(active) == 2

    def test_get_active_events_muted_track(self):
        """Test get_active_events skips muted tracks."""
        timeline = Timeline(duration=10.0)
        timeline.add_event(1.0, EventType.PLAY_MOTION, "char1", duration=2.0)
        timeline.add_event(1.0, EventType.PLAY_MOTION, "char2", duration=2.0)

        # Mute one track
        timeline.tracks["track_char1"].muted = True

        active = timeline.get_active_events(1.5)
        assert len(active) == 1
        assert active[0].target == "char2"

    def test_get_events_in_range_muted_track(self):
        """Test muted tracks are excluded from range queries."""
        timeline = Timeline(duration=10.0)
        timeline.add_event(1.0, EventType.SET_EMOTION, "char1")
        timeline.add_event(1.0, EventType.SET_EMOTION, "char2")

        timeline.tracks["track_char1"].muted = True

        events = timeline.get_events_in_range(0, 5)
        assert len(events) == 1
        assert events[0].target == "char2"

    def test_update_not_playing_returns_empty(self):
        """Test update returns empty when not playing."""
        timeline = Timeline(duration=10.0)
        timeline.add_event(0.5, EventType.SET_EMOTION, "char")

        # Not playing, should return empty
        events = timeline.update(1.0)
        assert events == []

    def test_update_stops_at_end(self):
        """Test update stops at end when not looping."""
        timeline = Timeline(duration=2.0)
        timeline.add_event(1.0, EventType.SET_EMOTION, "char")
        timeline.play(loop=False)

        # Update past duration
        timeline.update(3.0)

        assert timeline._is_playing is False
        assert timeline.current_time == 2.0


class TestTimelineBuilderAdditional:
    """Additional tests for TimelineBuilder."""

    def test_target_method(self):
        """Test target method sets current target."""
        builder = TimelineBuilder()
        result = builder.target("narrator")
        assert result is builder
        assert builder._current_target == "narrator"

    def test_motion_method(self):
        """Test motion helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(1.0).motion("char", "wave", speed=1.5)
            .build())

        events = timeline.get_events_at_time(1.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.PLAY_MOTION
        assert events[0].params["motion"] == "wave"
        assert events[0].params["speed"] == 1.5

    def test_mouth_method(self):
        """Test mouth shape helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(0.5).mouth("narrator", "A")
            .build())

        events = timeline.get_events_at_time(0.5)
        assert len(events) == 1
        assert events[0].event_type == EventType.SET_MOUTH_SHAPE
        assert events[0].params["shape"] == "A"

    def test_camera_move_method(self):
        """Test camera move helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(1.0).camera_move(100, 200, duration=0.5)
            .build())

        events = timeline.get_events_at_time(1.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.CAMERA_MOVE
        assert events[0].params["x"] == 100
        assert events[0].params["y"] == 200

    def test_camera_zoom_method(self):
        """Test camera zoom helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(2.0).camera_zoom(1.5, duration=1.0)
            .build())

        events = timeline.get_events_at_time(2.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.CAMERA_ZOOM
        assert events[0].params["zoom"] == 1.5

    def test_particles_method(self):
        """Test particles helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(1.0).particles("sparkles", "sparkle", (400, 300), duration=2.0)
            .build())

        events = timeline.get_events_in_range(0, 5)
        # Should have START and STOP events
        start_events = [e for e in events if e.event_type == EventType.START_PARTICLES]
        stop_events = [e for e in events if e.event_type == EventType.STOP_PARTICLES]
        assert len(start_events) == 1
        assert len(stop_events) == 1
        assert start_events[0].time == 1.0
        assert stop_events[0].time == 3.0

    def test_transition_method(self):
        """Test transition helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(5.0).transition("fade", duration=1.5)
            .build())

        events = timeline.get_events_at_time(5.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.TRIGGER_TRANSITION
        assert events[0].params["transition_type"] == "fade"

    def test_show_method(self):
        """Test show layer helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(2.0).show("overlay_layer")
            .build())

        events = timeline.get_events_at_time(2.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.SHOW_LAYER
        assert events[0].target == "overlay_layer"

    def test_hide_method(self):
        """Test hide layer helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(3.0).hide("overlay_layer")
            .build())

        events = timeline.get_events_at_time(3.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.HIDE_LAYER

    def test_background_method(self):
        """Test background helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(0.0).background("/path/to/bg.png")
            .build())

        events = timeline.get_events_at_time(0.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.SET_BACKGROUND
        assert events[0].params["path"] == "/path/to/bg.png"

    def test_audio_method(self):
        """Test audio helper method."""
        timeline = (TimelineBuilder(duration=10.0)
            .at(1.0).audio("/path/to/sound.wav", volume=0.8)
            .build())

        events = timeline.get_events_at_time(1.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.PLAY_AUDIO
        assert events[0].params["path"] == "/path/to/sound.wav"
        assert events[0].params["volume"] == 0.8

    def test_callback_method(self):
        """Test callback helper method."""
        def my_callback():
            pass

        timeline = (TimelineBuilder(duration=10.0)
            .at(5.0).callback("custom", my_callback)
            .build())

        events = timeline.get_events_at_time(5.0)
        assert len(events) == 1
        assert events[0].event_type == EventType.CALLBACK
        assert events[0].params["callback"] == my_callback


class TestLipSyncTimelineAdditional:
    """Additional tests for LipSyncTimeline."""

    def test_to_builder_events(self):
        """Test adding lip sync events via builder."""
        ls = LipSyncTimeline("narrator")
        ls.add_cue(0.0, 0.5, "A")
        ls.add_cue(0.5, 1.0, "B")
        ls.add_cue(1.0, 1.5, "E")

        builder = TimelineBuilder(duration=5.0)
        ls.to_builder_events(builder)
        timeline = builder.build()

        events = timeline.get_events_in_range(0, 2)
        assert len(events) == 3
        # Events should be in order
        assert events[0].time == 0.0
        assert events[1].time == 0.5
        assert events[2].time == 1.0


class TestAnimationSequenceAdditional:
    """Additional tests for AnimationSequence."""

    def test_duration_no_events(self):
        """Test duration with no events returns 0."""
        seq = AnimationSequence("empty")
        assert seq.duration == 0

    def test_duration_explicit_override(self):
        """Test explicit duration overrides calculated duration."""
        seq = AnimationSequence("test", duration=10.0)
        seq.add_event(0.0, EventType.SET_EMOTION, "char")
        seq.add_event(5.0, EventType.SET_EMOTION, "char", duration=2.0)

        # Explicit duration should be used
        assert seq.duration == 10.0
