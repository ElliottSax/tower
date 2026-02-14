"""Keyframe animation system for the pipeline."""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Callable, Union
from enum import Enum
import math


class EasingType(Enum):
    """Animation easing functions."""
    LINEAR = "linear"
    EASE_IN = "ease_in"
    EASE_OUT = "ease_out"
    EASE_IN_OUT = "ease_in_out"
    EASE_IN_QUAD = "ease_in_quad"
    EASE_OUT_QUAD = "ease_out_quad"
    EASE_IN_OUT_QUAD = "ease_in_out_quad"
    EASE_IN_CUBIC = "ease_in_cubic"
    EASE_OUT_CUBIC = "ease_out_cubic"
    EASE_IN_OUT_CUBIC = "ease_in_out_cubic"
    EASE_IN_ELASTIC = "ease_in_elastic"
    EASE_OUT_ELASTIC = "ease_out_elastic"
    EASE_OUT_BOUNCE = "ease_out_bounce"
    STEP = "step"


def ease_linear(t: float) -> float:
    """Linear interpolation."""
    return t


def ease_in_quad(t: float) -> float:
    """Quadratic ease in."""
    return t * t


def ease_out_quad(t: float) -> float:
    """Quadratic ease out."""
    return 1 - (1 - t) * (1 - t)


def ease_in_out_quad(t: float) -> float:
    """Quadratic ease in/out."""
    return 2 * t * t if t < 0.5 else 1 - pow(-2 * t + 2, 2) / 2


def ease_in_cubic(t: float) -> float:
    """Cubic ease in."""
    return t * t * t


def ease_out_cubic(t: float) -> float:
    """Cubic ease out."""
    return 1 - pow(1 - t, 3)


def ease_in_out_cubic(t: float) -> float:
    """Cubic ease in/out."""
    return 4 * t * t * t if t < 0.5 else 1 - pow(-2 * t + 2, 3) / 2


def ease_in_elastic(t: float) -> float:
    """Elastic ease in."""
    if t == 0 or t == 1:
        return t
    return -pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * (2 * math.pi / 3))


def ease_out_elastic(t: float) -> float:
    """Elastic ease out."""
    if t == 0 or t == 1:
        return t
    return pow(2, -10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi / 3)) + 1


def ease_out_bounce(t: float) -> float:
    """Bounce ease out."""
    n1 = 7.5625
    d1 = 2.75
    if t < 1 / d1:
        return n1 * t * t
    elif t < 2 / d1:
        t -= 1.5 / d1
        return n1 * t * t + 0.75
    elif t < 2.5 / d1:
        t -= 2.25 / d1
        return n1 * t * t + 0.9375
    else:
        t -= 2.625 / d1
        return n1 * t * t + 0.984375


def step(t: float) -> float:
    """Step function (no interpolation)."""
    return 0.0 if t < 1.0 else 1.0


EASING_FUNCTIONS: Dict[EasingType, Callable[[float], float]] = {
    EasingType.LINEAR: ease_linear,
    EasingType.EASE_IN: ease_in_quad,
    EasingType.EASE_OUT: ease_out_quad,
    EasingType.EASE_IN_OUT: ease_in_out_quad,
    EasingType.EASE_IN_QUAD: ease_in_quad,
    EasingType.EASE_OUT_QUAD: ease_out_quad,
    EasingType.EASE_IN_OUT_QUAD: ease_in_out_quad,
    EasingType.EASE_IN_CUBIC: ease_in_cubic,
    EasingType.EASE_OUT_CUBIC: ease_out_cubic,
    EasingType.EASE_IN_OUT_CUBIC: ease_in_out_cubic,
    EasingType.EASE_IN_ELASTIC: ease_in_elastic,
    EasingType.EASE_OUT_ELASTIC: ease_out_elastic,
    EasingType.EASE_OUT_BOUNCE: ease_out_bounce,
    EasingType.STEP: step,
}


@dataclass
class Keyframe:
    """A single keyframe with value and easing.

    Attributes:
        frame: Frame number
        value: Value at this keyframe (can be any type)
        easing: Easing function to use when interpolating TO this keyframe
    """
    frame: int
    value: Any
    easing: EasingType = EasingType.LINEAR

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "frame": self.frame,
            "value": self._serialize_value(self.value),
            "easing": self.easing.value
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Keyframe":
        """Create from dictionary."""
        return cls(
            frame=data["frame"],
            value=data["value"],
            easing=EasingType(data.get("easing", "linear"))
        )

    def _serialize_value(self, value: Any) -> Any:
        """Serialize value for JSON."""
        if isinstance(value, (tuple, list)):
            return list(value)
        return value


def interpolate_value(start_value: Any, end_value: Any, t: float) -> Any:
    """Interpolate between two values.

    Supports:
    - Numbers (int, float)
    - Tuples/lists of numbers
    - Strings (returns start_value until t >= 1)
    """
    if isinstance(start_value, (int, float)) and isinstance(end_value, (int, float)):
        result = start_value + (end_value - start_value) * t
        return int(result) if isinstance(start_value, int) and isinstance(end_value, int) else result

    if isinstance(start_value, (tuple, list)) and isinstance(end_value, (tuple, list)):
        if len(start_value) != len(end_value):
            raise ValueError("Cannot interpolate sequences of different lengths")

        result = []
        for s, e in zip(start_value, end_value):
            if isinstance(s, (int, float)) and isinstance(e, (int, float)):
                v = s + (e - s) * t
                result.append(int(v) if isinstance(s, int) and isinstance(e, int) else v)
            else:
                result.append(s if t < 1 else e)

        return tuple(result) if isinstance(start_value, tuple) else result

    # For non-interpolatable types, return start until t >= 1
    return end_value if t >= 1.0 else start_value


@dataclass
class KeyframeTrack:
    """A track of keyframes for animating a single property.

    Usage:
        track = KeyframeTrack("position")
        track.add_keyframe(0, (0, 0))
        track.add_keyframe(30, (100, 50), EasingType.EASE_OUT)
        track.add_keyframe(60, (200, 0), EasingType.EASE_IN_OUT)

        for frame in range(61):
            pos = track.get_value(frame)
    """
    name: str
    keyframes: List[Keyframe] = field(default_factory=list)
    default_value: Any = None

    def add_keyframe(
        self,
        frame: int,
        value: Any,
        easing: EasingType = EasingType.LINEAR
    ) -> "KeyframeTrack":
        """Add a keyframe to the track.

        Returns self for chaining.
        """
        # Remove existing keyframe at same frame
        self.keyframes = [k for k in self.keyframes if k.frame != frame]

        # Add new keyframe and sort
        self.keyframes.append(Keyframe(frame, value, easing))
        self.keyframes.sort(key=lambda k: k.frame)

        return self

    def remove_keyframe(self, frame: int) -> bool:
        """Remove keyframe at specified frame. Returns True if removed."""
        initial_len = len(self.keyframes)
        self.keyframes = [k for k in self.keyframes if k.frame != frame]
        return len(self.keyframes) < initial_len

    def get_value(self, frame: int) -> Any:
        """Get interpolated value at a specific frame."""
        if not self.keyframes:
            return self.default_value

        # Before first keyframe
        if frame <= self.keyframes[0].frame:
            return self.keyframes[0].value

        # After last keyframe
        if frame >= self.keyframes[-1].frame:
            return self.keyframes[-1].value

        # Find surrounding keyframes
        for i, kf in enumerate(self.keyframes[:-1]):
            next_kf = self.keyframes[i + 1]
            if kf.frame <= frame < next_kf.frame:
                # Calculate t (0-1 progress between keyframes)
                duration = next_kf.frame - kf.frame
                t = (frame - kf.frame) / duration

                # Apply easing (using next keyframe's easing)
                easing_func = EASING_FUNCTIONS.get(next_kf.easing, ease_linear)
                t = easing_func(t)

                # Interpolate
                return interpolate_value(kf.value, next_kf.value, t)

        return self.default_value

    def get_frame_range(self) -> tuple[int, int]:
        """Get the frame range covered by this track."""
        if not self.keyframes:
            return (0, 0)
        return (self.keyframes[0].frame, self.keyframes[-1].frame)

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "name": self.name,
            "keyframes": [k.to_dict() for k in self.keyframes],
            "default_value": self.default_value
        }

    @classmethod
    def from_dict(cls, data: dict) -> "KeyframeTrack":
        """Create from dictionary."""
        track = cls(
            name=data["name"],
            default_value=data.get("default_value")
        )
        for kf_data in data.get("keyframes", []):
            track.keyframes.append(Keyframe.from_dict(kf_data))
        return track


@dataclass
class AnimationClip:
    """Collection of keyframe tracks for an object.

    Usage:
        clip = AnimationClip("character_walk")
        clip.add_track("position").add_keyframe(0, (0, 0)).add_keyframe(30, (100, 0))
        clip.add_track("rotation").add_keyframe(0, 0).add_keyframe(30, 15)

        for frame in range(31):
            pos = clip.get_value("position", frame)
            rot = clip.get_value("rotation", frame)
    """
    name: str
    tracks: Dict[str, KeyframeTrack] = field(default_factory=dict)
    loop: bool = False

    def add_track(self, name: str, default_value: Any = None) -> KeyframeTrack:
        """Add a new track or get existing one."""
        if name not in self.tracks:
            self.tracks[name] = KeyframeTrack(name, default_value=default_value)
        return self.tracks[name]

    def get_track(self, name: str) -> Optional[KeyframeTrack]:
        """Get a track by name."""
        return self.tracks.get(name)

    def get_value(self, track_name: str, frame: int) -> Any:
        """Get value from a track at a specific frame."""
        track = self.tracks.get(track_name)
        if track:
            return track.get_value(frame)
        return None

    def get_frame_range(self) -> tuple[int, int]:
        """Get the total frame range covered by all tracks."""
        if not self.tracks:
            return (0, 0)

        ranges = [t.get_frame_range() for t in self.tracks.values()]
        return (
            min(r[0] for r in ranges),
            max(r[1] for r in ranges)
        )

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "name": self.name,
            "tracks": {name: track.to_dict() for name, track in self.tracks.items()},
            "loop": self.loop
        }

    @classmethod
    def from_dict(cls, data: dict) -> "AnimationClip":
        """Create from dictionary."""
        clip = cls(
            name=data["name"],
            loop=data.get("loop", False)
        )
        for name, track_data in data.get("tracks", {}).items():
            clip.tracks[name] = KeyframeTrack.from_dict(track_data)
        return clip
