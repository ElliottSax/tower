"""Tests for animation.keyframes module."""

import math
import pytest

from pipeline.animation.keyframes import (
    EasingType,
    Keyframe,
    KeyframeTrack,
    AnimationClip,
    interpolate_value,
    ease_linear,
    ease_in_quad,
    ease_out_quad,
    ease_in_out_quad,
    ease_in_cubic,
    ease_out_cubic,
    ease_in_out_cubic,
    ease_in_elastic,
    ease_out_elastic,
    ease_out_bounce,
    step,
    EASING_FUNCTIONS,
)


class TestEasingFunctions:
    """Tests for easing functions."""

    def test_ease_linear(self):
        """Test linear easing."""
        assert ease_linear(0.0) == 0.0
        assert ease_linear(0.5) == 0.5
        assert ease_linear(1.0) == 1.0

    def test_ease_in_quad(self):
        """Test quadratic ease in."""
        assert ease_in_quad(0.0) == 0.0
        assert ease_in_quad(0.5) == 0.25
        assert ease_in_quad(1.0) == 1.0

    def test_ease_out_quad(self):
        """Test quadratic ease out."""
        assert ease_out_quad(0.0) == 0.0
        assert ease_out_quad(0.5) == 0.75
        assert ease_out_quad(1.0) == 1.0

    def test_ease_in_out_quad(self):
        """Test quadratic ease in/out."""
        assert ease_in_out_quad(0.0) == 0.0
        assert ease_in_out_quad(0.5) == 0.5
        assert ease_in_out_quad(1.0) == 1.0
        # First half should be slower
        assert ease_in_out_quad(0.25) < 0.25
        # Second half should be faster
        assert ease_in_out_quad(0.75) > 0.75

    def test_ease_in_cubic(self):
        """Test cubic ease in."""
        assert ease_in_cubic(0.0) == 0.0
        assert ease_in_cubic(0.5) == 0.125
        assert ease_in_cubic(1.0) == 1.0

    def test_ease_out_cubic(self):
        """Test cubic ease out."""
        assert ease_out_cubic(0.0) == 0.0
        assert ease_out_cubic(0.5) == 0.875
        assert ease_out_cubic(1.0) == 1.0

    def test_ease_in_out_cubic(self):
        """Test cubic ease in/out."""
        assert ease_in_out_cubic(0.0) == 0.0
        assert ease_in_out_cubic(0.5) == 0.5
        assert ease_in_out_cubic(1.0) == 1.0

    def test_ease_in_elastic_boundaries(self):
        """Test elastic ease in at boundaries."""
        assert ease_in_elastic(0.0) == 0.0
        assert ease_in_elastic(1.0) == 1.0

    def test_ease_out_elastic_boundaries(self):
        """Test elastic ease out at boundaries."""
        assert ease_out_elastic(0.0) == 0.0
        assert ease_out_elastic(1.0) == 1.0

    def test_ease_out_bounce(self):
        """Test bounce ease out."""
        assert ease_out_bounce(0.0) == 0.0
        assert ease_out_bounce(1.0) == 1.0
        # Should bounce (go above target)
        mid_value = ease_out_bounce(0.5)
        assert 0 < mid_value < 1

    def test_step(self):
        """Test step function."""
        assert step(0.0) == 0.0
        assert step(0.5) == 0.0
        assert step(0.99) == 0.0
        assert step(1.0) == 1.0

    def test_all_easings_in_dict(self):
        """Test all easing types have functions."""
        for easing_type in EasingType:
            assert easing_type in EASING_FUNCTIONS
            func = EASING_FUNCTIONS[easing_type]
            assert callable(func)
            # All should return 0 at t=0 and 1 at t=1
            assert func(0.0) == 0.0
            assert func(1.0) == 1.0


class TestInterpolateValue:
    """Tests for interpolate_value function."""

    def test_interpolate_integers(self):
        """Test interpolating integers."""
        assert interpolate_value(0, 100, 0.0) == 0
        assert interpolate_value(0, 100, 0.5) == 50
        assert interpolate_value(0, 100, 1.0) == 100

    def test_interpolate_floats(self):
        """Test interpolating floats."""
        assert interpolate_value(0.0, 10.0, 0.0) == 0.0
        assert interpolate_value(0.0, 10.0, 0.5) == 5.0
        assert interpolate_value(0.0, 10.0, 1.0) == 10.0

    def test_interpolate_tuples(self):
        """Test interpolating tuples."""
        result = interpolate_value((0, 0), (100, 200), 0.5)
        assert result == (50, 100)

    def test_interpolate_lists(self):
        """Test interpolating lists."""
        result = interpolate_value([0, 0, 0], [100, 200, 300], 0.5)
        assert result == [50, 100, 150]

    def test_interpolate_preserves_type(self):
        """Test that interpolation preserves input type."""
        # Integer inputs should produce integer results
        result = interpolate_value(0, 100, 0.5)
        assert isinstance(result, int)

        # Float inputs should produce float results
        result = interpolate_value(0.0, 100.0, 0.5)
        assert isinstance(result, float)

        # Tuple inputs should produce tuple results
        result = interpolate_value((0, 0), (100, 100), 0.5)
        assert isinstance(result, tuple)

        # List inputs should produce list results
        result = interpolate_value([0, 0], [100, 100], 0.5)
        assert isinstance(result, list)

    def test_interpolate_strings(self):
        """Test non-interpolatable strings."""
        # Strings should return start until t >= 1
        assert interpolate_value("hello", "world", 0.0) == "hello"
        assert interpolate_value("hello", "world", 0.5) == "hello"
        assert interpolate_value("hello", "world", 1.0) == "world"

    def test_interpolate_different_length_error(self):
        """Test interpolating sequences of different lengths raises error."""
        with pytest.raises(ValueError, match="different lengths"):
            interpolate_value((0, 0), (100, 100, 100), 0.5)


class TestKeyframe:
    """Tests for Keyframe dataclass."""

    def test_creation(self):
        """Test keyframe creation."""
        kf = Keyframe(frame=10, value=100)
        assert kf.frame == 10
        assert kf.value == 100
        assert kf.easing == EasingType.LINEAR

    def test_creation_with_easing(self):
        """Test keyframe creation with easing."""
        kf = Keyframe(frame=10, value=100, easing=EasingType.EASE_OUT)
        assert kf.easing == EasingType.EASE_OUT

    def test_to_dict(self):
        """Test serialization to dict."""
        kf = Keyframe(frame=10, value=(100, 200), easing=EasingType.EASE_IN)
        d = kf.to_dict()
        assert d["frame"] == 10
        assert d["value"] == [100, 200]
        assert d["easing"] == "ease_in"

    def test_from_dict(self):
        """Test deserialization from dict."""
        d = {"frame": 10, "value": 100, "easing": "ease_out"}
        kf = Keyframe.from_dict(d)
        assert kf.frame == 10
        assert kf.value == 100
        assert kf.easing == EasingType.EASE_OUT

    def test_from_dict_default_easing(self):
        """Test deserialization with missing easing uses default."""
        d = {"frame": 10, "value": 100}
        kf = Keyframe.from_dict(d)
        assert kf.easing == EasingType.LINEAR


class TestKeyframeTrack:
    """Tests for KeyframeTrack class."""

    def test_empty_track(self):
        """Test empty track returns default value."""
        track = KeyframeTrack("test", default_value=50)
        assert track.get_value(0) == 50
        assert track.get_value(100) == 50

    def test_add_keyframe(self):
        """Test adding keyframes."""
        track = KeyframeTrack("position")
        track.add_keyframe(0, (0, 0))
        track.add_keyframe(30, (100, 100))

        assert len(track.keyframes) == 2
        assert track.keyframes[0].frame == 0
        assert track.keyframes[1].frame == 30

    def test_add_keyframe_chaining(self):
        """Test keyframe chaining."""
        track = KeyframeTrack("position")
        result = track.add_keyframe(0, 0).add_keyframe(30, 100)
        assert result is track
        assert len(track.keyframes) == 2

    def test_add_keyframe_replaces_existing(self):
        """Test adding keyframe at same frame replaces existing."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(10, 200)

        assert len(track.keyframes) == 1
        assert track.keyframes[0].value == 200

    def test_add_keyframe_sorts(self):
        """Test keyframes are automatically sorted."""
        track = KeyframeTrack("value")
        track.add_keyframe(30, 300)
        track.add_keyframe(10, 100)
        track.add_keyframe(20, 200)

        assert track.keyframes[0].frame == 10
        assert track.keyframes[1].frame == 20
        assert track.keyframes[2].frame == 30

    def test_remove_keyframe(self):
        """Test removing keyframes."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(20, 200)

        result = track.remove_keyframe(10)

        assert result is True
        assert len(track.keyframes) == 1
        assert track.keyframes[0].frame == 20

    def test_remove_nonexistent_keyframe(self):
        """Test removing nonexistent keyframe."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)

        result = track.remove_keyframe(99)

        assert result is False
        assert len(track.keyframes) == 1

    def test_get_value_before_first(self):
        """Test getting value before first keyframe."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(20, 200)

        assert track.get_value(0) == 100
        assert track.get_value(5) == 100

    def test_get_value_after_last(self):
        """Test getting value after last keyframe."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(20, 200)

        assert track.get_value(30) == 200
        assert track.get_value(100) == 200

    def test_get_value_exact_keyframe(self):
        """Test getting value at exact keyframe."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(20, 200)

        assert track.get_value(10) == 100
        assert track.get_value(20) == 200

    def test_get_value_interpolated(self):
        """Test interpolated values between keyframes."""
        track = KeyframeTrack("value")
        track.add_keyframe(0, 0)
        track.add_keyframe(10, 100)

        assert track.get_value(5) == 50

    def test_get_value_with_easing(self):
        """Test interpolation with easing."""
        track = KeyframeTrack("value")
        track.add_keyframe(0, 0.0)
        track.add_keyframe(10, 100.0, EasingType.EASE_IN_QUAD)

        # At t=0.5 with ease_in_quad: t*t = 0.25
        mid = track.get_value(5)
        assert mid == pytest.approx(25.0, rel=0.01)

    def test_get_value_tuple_interpolation(self):
        """Test interpolating tuple values."""
        track = KeyframeTrack("position")
        track.add_keyframe(0, (0, 0))
        track.add_keyframe(10, (100, 200))

        result = track.get_value(5)
        assert result == (50, 100)

    def test_get_frame_range(self):
        """Test getting frame range."""
        track = KeyframeTrack("value")
        track.add_keyframe(10, 100)
        track.add_keyframe(50, 500)

        assert track.get_frame_range() == (10, 50)

    def test_get_frame_range_empty(self):
        """Test frame range of empty track."""
        track = KeyframeTrack("value")
        assert track.get_frame_range() == (0, 0)

    def test_serialization_roundtrip(self):
        """Test serialization and deserialization."""
        track = KeyframeTrack("position")
        track.add_keyframe(0, (0, 0))
        track.add_keyframe(30, (100, 100), EasingType.EASE_OUT)

        d = track.to_dict()
        restored = KeyframeTrack.from_dict(d)

        assert restored.name == track.name
        assert len(restored.keyframes) == 2
        assert restored.keyframes[1].easing == EasingType.EASE_OUT


class TestAnimationClip:
    """Tests for AnimationClip class."""

    def test_creation(self):
        """Test clip creation."""
        clip = AnimationClip("walk")
        assert clip.name == "walk"
        assert len(clip.tracks) == 0
        assert clip.loop is False

    def test_add_track(self):
        """Test adding tracks."""
        clip = AnimationClip("walk")
        track = clip.add_track("position")

        assert isinstance(track, KeyframeTrack)
        assert "position" in clip.tracks

    def test_add_track_returns_existing(self):
        """Test add_track returns existing track if present."""
        clip = AnimationClip("walk")
        track1 = clip.add_track("position")
        track1.add_keyframe(0, (0, 0))

        track2 = clip.add_track("position")
        assert track2 is track1
        assert len(track2.keyframes) == 1

    def test_get_track(self):
        """Test getting tracks."""
        clip = AnimationClip("walk")
        clip.add_track("position")

        assert clip.get_track("position") is not None
        assert clip.get_track("nonexistent") is None

    def test_get_value(self):
        """Test getting values from clip."""
        clip = AnimationClip("walk")
        clip.add_track("position").add_keyframe(0, 0).add_keyframe(10, 100)
        clip.add_track("rotation").add_keyframe(0, 0).add_keyframe(10, 360)

        assert clip.get_value("position", 5) == 50
        assert clip.get_value("rotation", 5) == 180
        assert clip.get_value("nonexistent", 5) is None

    def test_get_frame_range(self):
        """Test getting total frame range."""
        clip = AnimationClip("walk")
        clip.add_track("position").add_keyframe(10, 0).add_keyframe(30, 100)
        clip.add_track("rotation").add_keyframe(0, 0).add_keyframe(50, 360)

        assert clip.get_frame_range() == (0, 50)

    def test_get_frame_range_empty(self):
        """Test frame range of empty clip."""
        clip = AnimationClip("empty")
        assert clip.get_frame_range() == (0, 0)

    def test_serialization_roundtrip(self):
        """Test clip serialization."""
        clip = AnimationClip("walk", loop=True)
        clip.add_track("position").add_keyframe(0, (0, 0)).add_keyframe(30, (100, 100))
        clip.add_track("rotation").add_keyframe(0, 0).add_keyframe(30, 90)

        d = clip.to_dict()
        restored = AnimationClip.from_dict(d)

        assert restored.name == "walk"
        assert restored.loop is True
        assert len(restored.tracks) == 2
        # Note: tuples become lists after JSON serialization
        assert restored.get_value("position", 15) == [50, 50]
