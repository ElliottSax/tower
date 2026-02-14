"""Timeline and sequencer for animation orchestration.

Provides a timeline system for coordinating animations, events, and audio.
"""

from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Tuple, Union
import bisect


class EventType(Enum):
    """Types of timeline events."""
    # Animation events
    SET_EMOTION = auto()
    PLAY_MOTION = auto()
    SET_POSE = auto()

    # Lip sync
    SET_MOUTH_SHAPE = auto()
    START_SPEAKING = auto()
    STOP_SPEAKING = auto()

    # Camera
    CAMERA_MOVE = auto()
    CAMERA_ZOOM = auto()
    CAMERA_SHAKE = auto()

    # Effects
    START_PARTICLES = auto()
    STOP_PARTICLES = auto()
    TRIGGER_TRANSITION = auto()

    # Audio
    PLAY_AUDIO = auto()
    STOP_AUDIO = auto()

    # Scene
    SHOW_LAYER = auto()
    HIDE_LAYER = auto()
    SET_BACKGROUND = auto()

    # Custom
    CALLBACK = auto()


@dataclass
class TimelineEvent:
    """An event on the timeline."""
    time: float  # Time in seconds
    event_type: EventType
    target: str  # Target object (character name, layer name, etc.)
    params: Dict[str, Any] = field(default_factory=dict)
    duration: float = 0.0  # For events that span time

    def __lt__(self, other: 'TimelineEvent') -> bool:
        return self.time < other.time


@dataclass
class TimelineTrack:
    """A track containing events for a specific target."""
    name: str
    target: str
    events: List[TimelineEvent] = field(default_factory=list)
    muted: bool = False
    solo: bool = False

    def add_event(self, event: TimelineEvent) -> None:
        """Add event in sorted order."""
        bisect.insort(self.events, event)

    def get_events_in_range(self, start: float, end: float) -> List[TimelineEvent]:
        """Get all events between start and end time."""
        return [e for e in self.events if start <= e.time < end]

    def get_active_event(self, time: float) -> Optional[TimelineEvent]:
        """Get the event active at a specific time (for duration events)."""
        for event in reversed(self.events):
            if event.time <= time:
                if event.duration > 0:
                    if time < event.time + event.duration:
                        return event
                else:
                    return event
        return None


class Timeline:
    """Main timeline for sequencing animations.

    Usage:
        timeline = Timeline(duration=30.0, fps=30)

        # Add character emotion changes
        timeline.add_event(0.0, EventType.SET_EMOTION, "narrator",
                          emotion="happy")
        timeline.add_event(5.0, EventType.SET_EMOTION, "narrator",
                          emotion="surprised")

        # Add motion
        timeline.add_event(1.0, EventType.PLAY_MOTION, "narrator",
                          motion="wave")

        # Add camera shake
        timeline.add_event(5.0, EventType.CAMERA_SHAKE, "main_camera",
                          shake_type="impact", intensity=0.5)

        # Playback
        for frame in range(timeline.total_frames):
            events = timeline.get_events_at_frame(frame)
            for event in events:
                # Process event
                pass
    """

    def __init__(self, duration: float = 10.0, fps: int = 30):
        """Initialize timeline.

        Args:
            duration: Total duration in seconds
            fps: Frames per second
        """
        self.duration = duration
        self.fps = fps
        self.tracks: Dict[str, TimelineTrack] = {}

        # Playback state
        self._current_time = 0.0
        self._is_playing = False
        self._loop = False

        # Event handlers
        self._event_handlers: Dict[EventType, List[Callable]] = {}

        # Markers
        self._markers: Dict[str, float] = {}

    @property
    def total_frames(self) -> int:
        """Total number of frames."""
        return int(self.duration * self.fps)

    @property
    def frame_duration(self) -> float:
        """Duration of a single frame in seconds."""
        return 1.0 / self.fps

    @property
    def current_time(self) -> float:
        """Current playback time."""
        return self._current_time

    @property
    def current_frame(self) -> int:
        """Current frame number."""
        return int(self._current_time * self.fps)

    def add_track(self, name: str, target: str) -> TimelineTrack:
        """Add a new track."""
        track = TimelineTrack(name=name, target=target)
        self.tracks[name] = track
        return track

    def get_or_create_track(self, target: str) -> TimelineTrack:
        """Get existing track for target or create new one."""
        track_name = f"track_{target}"
        if track_name not in self.tracks:
            self.add_track(track_name, target)
        return self.tracks[track_name]

    def add_event(self, time: float, event_type: EventType, target: str,
                  duration: float = 0.0, **params) -> TimelineEvent:
        """Add an event to the timeline.

        Args:
            time: Event time in seconds
            event_type: Type of event
            target: Target object name
            duration: Event duration (0 for instant events)
            **params: Event-specific parameters

        Returns:
            The created event
        """
        event = TimelineEvent(
            time=time,
            event_type=event_type,
            target=target,
            params=params,
            duration=duration
        )

        track = self.get_or_create_track(target)
        track.add_event(event)

        return event

    def add_marker(self, name: str, time: float) -> None:
        """Add a named marker at a specific time."""
        self._markers[name] = time

    def get_marker(self, name: str) -> Optional[float]:
        """Get time of a named marker."""
        return self._markers.get(name)

    def goto_marker(self, name: str) -> bool:
        """Jump to a named marker."""
        if name in self._markers:
            self._current_time = self._markers[name]
            return True
        return False

    def get_events_at_time(self, time: float) -> List[TimelineEvent]:
        """Get all events that trigger at a specific time."""
        events = []
        for track in self.tracks.values():
            if track.muted:
                continue
            for event in track.events:
                if abs(event.time - time) < self.frame_duration / 2:
                    events.append(event)
        return events

    def get_events_at_frame(self, frame: int) -> List[TimelineEvent]:
        """Get all events that trigger at a specific frame."""
        time = frame / self.fps
        return self.get_events_at_time(time)

    def get_events_in_range(self, start_time: float, end_time: float) -> List[TimelineEvent]:
        """Get all events in a time range."""
        events = []
        for track in self.tracks.values():
            if track.muted:
                continue
            events.extend(track.get_events_in_range(start_time, end_time))
        return sorted(events, key=lambda e: e.time)

    def get_active_events(self, time: float) -> List[TimelineEvent]:
        """Get all events that are currently active (for duration events)."""
        events = []
        for track in self.tracks.values():
            if track.muted:
                continue
            active = track.get_active_event(time)
            if active:
                events.append(active)
        return events

    def register_handler(self, event_type: EventType,
                        handler: Callable[[TimelineEvent], None]) -> None:
        """Register an event handler."""
        if event_type not in self._event_handlers:
            self._event_handlers[event_type] = []
        self._event_handlers[event_type].append(handler)

    def _dispatch_event(self, event: TimelineEvent) -> None:
        """Dispatch an event to registered handlers."""
        handlers = self._event_handlers.get(event.event_type, [])
        for handler in handlers:
            handler(event)

    def update(self, dt: float) -> List[TimelineEvent]:
        """Advance timeline and return triggered events.

        Args:
            dt: Delta time in seconds

        Returns:
            List of events triggered this update
        """
        if not self._is_playing:
            return []

        prev_time = self._current_time
        self._current_time += dt

        # Handle loop or end
        if self._current_time >= self.duration:
            if self._loop:
                self._current_time = self._current_time % self.duration
            else:
                self._current_time = self.duration
                self._is_playing = False

        # Get events in this time slice
        events = self.get_events_in_range(prev_time, self._current_time)

        # Dispatch events
        for event in events:
            self._dispatch_event(event)

        return events

    def play(self, loop: bool = False) -> None:
        """Start playback."""
        self._is_playing = True
        self._loop = loop

    def pause(self) -> None:
        """Pause playback."""
        self._is_playing = False

    def stop(self) -> None:
        """Stop and reset to beginning."""
        self._is_playing = False
        self._current_time = 0.0

    def seek(self, time: float) -> None:
        """Seek to a specific time."""
        self._current_time = max(0, min(time, self.duration))

    def seek_frame(self, frame: int) -> None:
        """Seek to a specific frame."""
        self.seek(frame / self.fps)


class TimelineBuilder:
    """Fluent builder for creating timelines.

    Usage:
        timeline = (TimelineBuilder(duration=30.0)
            .at(0.0).emotion("narrator", "happy")
            .at(2.0).motion("narrator", "wave")
            .at(5.0).camera_shake("impact", 0.5)
            .at(10.0).emotion("narrator", "surprised")
            .build())
    """

    def __init__(self, duration: float = 10.0, fps: int = 30):
        self.timeline = Timeline(duration=duration, fps=fps)
        self._current_time = 0.0
        self._current_target = "default"

    def at(self, time: float) -> 'TimelineBuilder':
        """Set current time for next events."""
        self._current_time = time
        return self

    def after(self, delay: float) -> 'TimelineBuilder':
        """Add delay from current time."""
        self._current_time += delay
        return self

    def target(self, name: str) -> 'TimelineBuilder':
        """Set current target for next events."""
        self._current_target = name
        return self

    def marker(self, name: str) -> 'TimelineBuilder':
        """Add a marker at current time."""
        self.timeline.add_marker(name, self._current_time)
        return self

    # Character events
    def emotion(self, target: str, emotion: str) -> 'TimelineBuilder':
        """Set character emotion."""
        self.timeline.add_event(
            self._current_time, EventType.SET_EMOTION, target,
            emotion=emotion
        )
        return self

    def motion(self, target: str, motion: str, **params) -> 'TimelineBuilder':
        """Play a motion preset."""
        self.timeline.add_event(
            self._current_time, EventType.PLAY_MOTION, target,
            motion=motion, **params
        )
        return self

    def mouth(self, target: str, shape: str) -> 'TimelineBuilder':
        """Set mouth shape."""
        self.timeline.add_event(
            self._current_time, EventType.SET_MOUTH_SHAPE, target,
            shape=shape
        )
        return self

    def speak(self, target: str, duration: float) -> 'TimelineBuilder':
        """Mark speaking period."""
        self.timeline.add_event(
            self._current_time, EventType.START_SPEAKING, target
        )
        self.timeline.add_event(
            self._current_time + duration, EventType.STOP_SPEAKING, target
        )
        return self

    # Camera events
    def camera_move(self, x: float, y: float, duration: float = 0.0) -> 'TimelineBuilder':
        """Move camera."""
        self.timeline.add_event(
            self._current_time, EventType.CAMERA_MOVE, "camera",
            x=x, y=y, duration=duration
        )
        return self

    def camera_zoom(self, zoom: float, duration: float = 0.0) -> 'TimelineBuilder':
        """Zoom camera."""
        self.timeline.add_event(
            self._current_time, EventType.CAMERA_ZOOM, "camera",
            zoom=zoom, duration=duration
        )
        return self

    def camera_shake(self, shake_type: str, intensity: float = 1.0,
                    duration: float = 0.5) -> 'TimelineBuilder':
        """Add camera shake."""
        self.timeline.add_event(
            self._current_time, EventType.CAMERA_SHAKE, "camera",
            shake_type=shake_type, intensity=intensity, duration=duration
        )
        return self

    # Effect events
    def particles(self, name: str, emitter_type: str,
                 position: Tuple[float, float],
                 duration: float = 1.0) -> 'TimelineBuilder':
        """Spawn particles."""
        self.timeline.add_event(
            self._current_time, EventType.START_PARTICLES, name,
            emitter_type=emitter_type, position=position, duration=duration
        )
        self.timeline.add_event(
            self._current_time + duration, EventType.STOP_PARTICLES, name
        )
        return self

    def transition(self, transition_type: str, duration: float = 1.0) -> 'TimelineBuilder':
        """Trigger a transition."""
        self.timeline.add_event(
            self._current_time, EventType.TRIGGER_TRANSITION, "scene",
            transition_type=transition_type, duration=duration
        )
        return self

    # Scene events
    def show(self, layer: str) -> 'TimelineBuilder':
        """Show a layer."""
        self.timeline.add_event(
            self._current_time, EventType.SHOW_LAYER, layer
        )
        return self

    def hide(self, layer: str) -> 'TimelineBuilder':
        """Hide a layer."""
        self.timeline.add_event(
            self._current_time, EventType.HIDE_LAYER, layer
        )
        return self

    def background(self, path: str) -> 'TimelineBuilder':
        """Set background."""
        self.timeline.add_event(
            self._current_time, EventType.SET_BACKGROUND, "scene",
            path=path
        )
        return self

    # Audio events
    def audio(self, path: str, volume: float = 1.0) -> 'TimelineBuilder':
        """Play audio."""
        self.timeline.add_event(
            self._current_time, EventType.PLAY_AUDIO, "audio",
            path=path, volume=volume
        )
        return self

    # Custom events
    def callback(self, target: str, callback: Callable) -> 'TimelineBuilder':
        """Add a custom callback."""
        self.timeline.add_event(
            self._current_time, EventType.CALLBACK, target,
            callback=callback
        )
        return self

    def build(self) -> Timeline:
        """Build and return the timeline."""
        return self.timeline


class LipSyncTimeline:
    """Specialized timeline for lip sync data.

    Converts Rhubarb lip sync data to timeline events.
    """

    # Rhubarb mouth shapes
    SHAPES = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'X']

    def __init__(self, character: str):
        """Initialize lip sync timeline.

        Args:
            character: Character name to apply lip sync to
        """
        self.character = character
        self.cues: List[Tuple[float, float, str]] = []  # (start, end, shape)

    def add_cue(self, start: float, end: float, shape: str) -> None:
        """Add a mouth cue."""
        if shape in self.SHAPES:
            self.cues.append((start, end, shape))

    def load_from_rhubarb_json(self, data: dict) -> None:
        """Load from Rhubarb JSON output.

        Expected format:
        {
            "mouthCues": [
                {"start": 0.0, "end": 0.5, "value": "A"},
                ...
            ]
        }
        """
        for cue in data.get('mouthCues', []):
            self.add_cue(
                cue['start'],
                cue['end'],
                cue['value']
            )

    def get_shape_at_time(self, time: float) -> str:
        """Get the mouth shape at a specific time."""
        for start, end, shape in self.cues:
            if start <= time < end:
                return shape
        return 'X'  # Rest position

    def to_timeline_events(self, timeline: Timeline) -> None:
        """Add lip sync events to a timeline."""
        for start, end, shape in self.cues:
            timeline.add_event(
                start, EventType.SET_MOUTH_SHAPE, self.character,
                shape=shape, duration=end - start
            )

    def to_builder_events(self, builder: TimelineBuilder) -> TimelineBuilder:
        """Add lip sync events via builder."""
        for start, end, shape in sorted(self.cues, key=lambda c: c[0]):
            builder.at(start).mouth(self.character, shape)
        return builder


class AnimationSequence:
    """A reusable sequence of animation events.

    Can be inserted into timelines at different times.
    """

    def __init__(self, name: str, duration: float = 0.0):
        """Initialize sequence.

        Args:
            name: Sequence name
            duration: Sequence duration (0 = auto from events)
        """
        self.name = name
        self._duration = duration
        self.events: List[TimelineEvent] = []

    @property
    def duration(self) -> float:
        """Get sequence duration."""
        if self._duration > 0:
            return self._duration
        if not self.events:
            return 0
        return max(e.time + e.duration for e in self.events)

    def add_event(self, time: float, event_type: EventType, target: str,
                  duration: float = 0.0, **params) -> 'AnimationSequence':
        """Add event to sequence (relative time)."""
        event = TimelineEvent(
            time=time,
            event_type=event_type,
            target=target,
            params=params,
            duration=duration
        )
        self.events.append(event)
        return self

    def insert_into(self, timeline: Timeline, start_time: float,
                   target_mapping: Optional[Dict[str, str]] = None) -> None:
        """Insert sequence into timeline at specified time.

        Args:
            timeline: Target timeline
            start_time: Start time for sequence
            target_mapping: Optional mapping to rename targets
        """
        for event in self.events:
            target = event.target
            if target_mapping and target in target_mapping:
                target = target_mapping[target]

            timeline.add_event(
                start_time + event.time,
                event.event_type,
                target,
                event.duration,
                **event.params
            )


# Pre-built animation sequences
def create_greeting_sequence(character: str) -> AnimationSequence:
    """Create a greeting animation sequence."""
    seq = AnimationSequence("greeting", duration=2.0)
    seq.add_event(0.0, EventType.SET_EMOTION, character, emotion="happy")
    seq.add_event(0.2, EventType.PLAY_MOTION, character, motion="wave")
    seq.add_event(0.0, EventType.START_SPEAKING, character)
    seq.add_event(1.5, EventType.STOP_SPEAKING, character)
    return seq


def create_reaction_sequence(character: str,
                            reaction: str = "surprised") -> AnimationSequence:
    """Create a reaction animation sequence."""
    seq = AnimationSequence("reaction", duration=1.5)
    seq.add_event(0.0, EventType.SET_EMOTION, character, emotion=reaction)

    if reaction == "surprised":
        seq.add_event(0.0, EventType.CAMERA_SHAKE, "camera",
                     shake_type="impact", intensity=0.3)

    return seq


def create_thinking_sequence(character: str,
                            duration: float = 3.0) -> AnimationSequence:
    """Create a thinking animation sequence."""
    seq = AnimationSequence("thinking", duration=duration)
    seq.add_event(0.0, EventType.SET_EMOTION, character, emotion="confused")
    seq.add_event(0.2, EventType.PLAY_MOTION, character, motion="thinking")
    seq.add_event(duration * 0.8, EventType.SET_EMOTION, character, emotion="happy")
    return seq


def create_celebration_sequence(character: str) -> AnimationSequence:
    """Create a celebration animation sequence."""
    seq = AnimationSequence("celebration", duration=2.0)
    seq.add_event(0.0, EventType.SET_EMOTION, character, emotion="happy")
    seq.add_event(0.1, EventType.PLAY_MOTION, character, motion="celebrate")
    seq.add_event(0.0, EventType.START_PARTICLES, "confetti",
                 emitter_type="confetti", position=(400, 0), duration=2.0)
    seq.add_event(0.5, EventType.CAMERA_SHAKE, "camera",
                 shake_type="vibration", intensity=0.2)
    return seq
