"""Tests for animation/motion_presets.py."""

import math
import pytest
from unittest.mock import MagicMock, patch

from pipeline.animation.motion_presets import (
    # Data classes
    Transform,
    Pose,
    MotionType,
    # Base class
    MotionPreset,
    # Motion classes
    IdleMotion,
    BreathingMotion,
    TalkingGesture,
    ShrugMotion,
    WaveMotion,
    PointMotion,
    ThinkingMotion,
    CelebrateMotion,
    WalkCycle,
    RunCycle,
    # Utility classes
    MotionBlender,
    GestureGenerator,
    # Factory functions
    create_idle,
    create_breathing,
    create_wave,
    create_point,
    create_shrug,
    create_thinking,
    create_celebrate,
    create_walk,
    create_run,
)


# ============================================================================
# TRANSFORM TESTS
# ============================================================================

class TestTransform:
    """Tests for Transform dataclass."""

    def test_default_values(self):
        """Test default transform values."""
        t = Transform()
        assert t.x == 0.0
        assert t.y == 0.0
        assert t.rotation == 0.0
        assert t.scale_x == 1.0
        assert t.scale_y == 1.0

    def test_custom_values(self):
        """Test transform with custom values."""
        t = Transform(x=10, y=20, rotation=45, scale_x=1.5, scale_y=2.0)
        assert t.x == 10
        assert t.y == 20
        assert t.rotation == 45
        assert t.scale_x == 1.5
        assert t.scale_y == 2.0

    def test_lerp_at_zero(self):
        """Test lerp at t=0 returns self."""
        t1 = Transform(x=0, y=0, rotation=0)
        t2 = Transform(x=100, y=100, rotation=90)
        result = t1.lerp(t2, 0)
        assert result.x == 0
        assert result.y == 0
        assert result.rotation == 0

    def test_lerp_at_one(self):
        """Test lerp at t=1 returns other."""
        t1 = Transform(x=0, y=0, rotation=0)
        t2 = Transform(x=100, y=100, rotation=90)
        result = t1.lerp(t2, 1)
        assert result.x == 100
        assert result.y == 100
        assert result.rotation == 90

    def test_lerp_at_half(self):
        """Test lerp at t=0.5 returns midpoint."""
        t1 = Transform(x=0, y=0, rotation=0, scale_x=1.0, scale_y=1.0)
        t2 = Transform(x=100, y=100, rotation=90, scale_x=2.0, scale_y=3.0)
        result = t1.lerp(t2, 0.5)
        assert result.x == 50
        assert result.y == 50
        assert result.rotation == 45
        assert result.scale_x == 1.5
        assert result.scale_y == 2.0

    def test_apply_additive(self):
        """Test apply combines transforms additively."""
        t1 = Transform(x=10, y=20, rotation=30, scale_x=1.5, scale_y=2.0)
        t2 = Transform(x=5, y=10, rotation=15, scale_x=2.0, scale_y=0.5)
        result = t1.apply(t2)
        assert result.x == 15  # 10 + 5
        assert result.y == 30  # 20 + 10
        assert result.rotation == 45  # 30 + 15
        assert result.scale_x == 3.0  # 1.5 * 2.0
        assert result.scale_y == 1.0  # 2.0 * 0.5


# ============================================================================
# POSE TESTS
# ============================================================================

class TestPose:
    """Tests for Pose dataclass."""

    def test_default_values(self):
        """Test default pose has neutral transforms."""
        pose = Pose()
        assert pose.body.x == 0
        assert pose.head.rotation == 0
        assert pose.left_arm.scale_x == 1.0

    def test_lerp_poses(self):
        """Test lerping between poses."""
        pose1 = Pose(
            body=Transform(x=0, y=0),
            head=Transform(rotation=0)
        )
        pose2 = Pose(
            body=Transform(x=100, y=100),
            head=Transform(rotation=90)
        )
        result = pose1.lerp(pose2, 0.5)
        assert result.body.x == 50
        assert result.body.y == 50
        assert result.head.rotation == 45

    def test_apply_poses(self):
        """Test applying poses together."""
        pose1 = Pose(
            body=Transform(x=10, y=20),
            head=Transform(rotation=15)
        )
        pose2 = Pose(
            body=Transform(x=5, y=5),
            head=Transform(rotation=10)
        )
        result = pose1.apply(pose2)
        assert result.body.x == 15
        assert result.body.y == 25
        assert result.head.rotation == 25


# ============================================================================
# MOTION TYPE TESTS
# ============================================================================

class TestMotionType:
    """Tests for MotionType enum."""

    def test_motion_types_exist(self):
        """Test all motion types are defined."""
        assert MotionType.IDLE
        assert MotionType.BREATHING
        assert MotionType.TALKING
        assert MotionType.WAVE
        assert MotionType.WALK
        assert MotionType.RUN


# ============================================================================
# MOTION PRESET BASE TESTS
# ============================================================================

class TestMotionPreset:
    """Tests for base MotionPreset class."""

    def test_default_creation(self):
        """Test default preset creation."""
        preset = MotionPreset()
        assert preset.duration == 1.0
        assert preset.loop is False
        assert preset.time == 0.0
        assert preset.is_finished is False

    def test_custom_creation(self):
        """Test preset with custom values."""
        preset = MotionPreset(duration=2.0, loop=True)
        assert preset.duration == 2.0
        assert preset.loop is True

    def test_reset(self):
        """Test reset returns to start."""
        preset = MotionPreset(duration=1.0)
        preset.time = 0.5
        preset.is_finished = True
        preset.reset()
        assert preset.time == 0.0
        assert preset.is_finished is False

    def test_update_advances_time(self):
        """Test update advances time."""
        preset = MotionPreset(duration=1.0)
        preset.update(0.3)
        assert preset.time == pytest.approx(0.3)

    def test_update_finishes_when_done(self):
        """Test update marks finished when duration reached."""
        preset = MotionPreset(duration=1.0, loop=False)
        preset.update(1.5)
        assert preset.is_finished is True
        assert preset.time == 1.0

    def test_update_loops(self):
        """Test update loops when enabled."""
        preset = MotionPreset(duration=1.0, loop=True)
        preset.update(1.5)
        assert preset.is_finished is False
        assert preset.time == pytest.approx(0.5)

    def test_evaluate_returns_pose(self):
        """Test _evaluate returns a Pose."""
        preset = MotionPreset()
        pose = preset._evaluate(0.5)
        assert isinstance(pose, Pose)


# ============================================================================
# IDLE MOTION TESTS
# ============================================================================

class TestIdleMotion:
    """Tests for IdleMotion class."""

    def test_creation(self):
        """Test idle motion creation."""
        idle = IdleMotion()
        assert idle.duration == 4.0
        assert idle.loop is True
        assert idle.intensity == 1.0

    def test_custom_intensity(self):
        """Test custom intensity."""
        idle = IdleMotion(intensity=0.5)
        assert idle.intensity == 0.5

    def test_evaluate_returns_pose(self):
        """Test evaluation returns valid pose."""
        idle = IdleMotion()
        pose = idle._evaluate(0.5)
        assert isinstance(pose, Pose)
        # Body should have some sway
        assert pose.body.x != 0 or pose.body.y != 0

    def test_update_and_loop(self):
        """Test idle loops correctly."""
        idle = IdleMotion()
        for _ in range(100):
            pose = idle.update(0.1)
        assert not idle.is_finished
        assert isinstance(pose, Pose)


# ============================================================================
# BREATHING MOTION TESTS
# ============================================================================

class TestBreathingMotion:
    """Tests for BreathingMotion class."""

    def test_default_creation(self):
        """Test default breathing motion."""
        breath = BreathingMotion()
        assert breath.duration == 4.0  # 1 / 0.25
        assert breath.loop is True
        assert breath.depth == 1.0

    def test_custom_rate(self):
        """Test custom breathing rate."""
        breath = BreathingMotion(rate=0.5)  # Faster breathing
        assert breath.duration == 2.0  # 1 / 0.5

    def test_evaluate_inhale(self):
        """Test inhale phase (first 40%)."""
        breath = BreathingMotion()
        pose = breath._evaluate(0.2)  # Middle of inhale
        # Body should be rising
        assert pose.body.y != 0

    def test_evaluate_exhale(self):
        """Test exhale phase (last 60%)."""
        breath = BreathingMotion()
        pose = breath._evaluate(0.7)  # Middle of exhale
        assert isinstance(pose, Pose)


# ============================================================================
# TALKING GESTURE TESTS
# ============================================================================

class TestTalkingGesture:
    """Tests for TalkingGesture class."""

    def test_default_creation(self):
        """Test default talking gesture."""
        gesture = TalkingGesture()
        assert gesture.duration == 0.8
        assert gesture.loop is False
        assert gesture.intensity == 1.0
        assert gesture.hand == 'right'

    def test_right_hand(self):
        """Test right hand gesture."""
        gesture = TalkingGesture(hand='right')
        pose = gesture._evaluate(0.15)  # Raising phase
        assert pose.right_arm.y != 0

    def test_left_hand(self):
        """Test left hand gesture."""
        gesture = TalkingGesture(hand='left')
        pose = gesture._evaluate(0.15)
        assert pose.left_arm.y != 0

    def test_both_hands(self):
        """Test both hands gesture."""
        gesture = TalkingGesture(hand='both')
        pose = gesture._evaluate(0.15)
        assert pose.left_arm.y != 0
        assert pose.right_arm.y != 0


# ============================================================================
# SHRUG MOTION TESTS
# ============================================================================

class TestShrugMotion:
    """Tests for ShrugMotion class."""

    def test_creation(self):
        """Test shrug motion creation."""
        shrug = ShrugMotion()
        assert shrug.duration == 0.6
        assert shrug.loop is False
        assert shrug.intensity == 1.0

    def test_evaluate_peak(self):
        """Test shrug at peak (hold phase)."""
        shrug = ShrugMotion()
        pose = shrug._evaluate(0.4)  # In hold phase (0.25-0.5)
        # Shoulders should be raised (negative y = up)
        assert pose.left_arm.y < 0
        assert pose.right_arm.y < 0


# ============================================================================
# WAVE MOTION TESTS
# ============================================================================

class TestWaveMotion:
    """Tests for WaveMotion class."""

    def test_default_creation(self):
        """Test default wave motion."""
        wave = WaveMotion()
        assert wave.waves == 3
        assert wave.hand == 'right'
        assert wave.duration == 1.2  # 0.3 + 3*0.3

    def test_custom_waves(self):
        """Test wave with custom count."""
        wave = WaveMotion(waves=5)
        assert wave.waves == 5
        assert wave.duration == 1.8  # 0.3 + 5*0.3

    def test_left_hand(self):
        """Test left hand wave."""
        wave = WaveMotion(hand='left')
        pose = wave._evaluate(0.5)  # During wave
        assert pose.left_arm.y != 0

    def test_waving_phase(self):
        """Test hand movement during wave."""
        wave = WaveMotion(waves=3)
        # After raise phase (0.3 / 1.2 = 0.25)
        pose1 = wave._evaluate(0.3)
        pose2 = wave._evaluate(0.5)
        # Hand rotation should change during wave
        assert pose1.right_hand.rotation != pose2.right_hand.rotation


# ============================================================================
# POINT MOTION TESTS
# ============================================================================

class TestPointMotion:
    """Tests for PointMotion class."""

    def test_default_creation(self):
        """Test default point motion."""
        point = PointMotion()
        assert point.direction == 'right'
        assert point.hold_time == 0.5
        assert point.duration == 1.2  # 0.4 + 0.5 + 0.3

    def test_right_direction(self):
        """Test pointing right."""
        point = PointMotion(direction='right')
        pose = point._evaluate(0.5)  # During hold
        assert pose.body.rotation < 0  # Body turns right
        assert pose.right_arm.x > 0

    def test_left_direction(self):
        """Test pointing left."""
        point = PointMotion(direction='left')
        pose = point._evaluate(0.5)
        assert pose.body.rotation > 0  # Body turns left
        assert pose.left_arm.x < 0


# ============================================================================
# THINKING MOTION TESTS
# ============================================================================

class TestThinkingMotion:
    """Tests for ThinkingMotion class."""

    def test_creation(self):
        """Test thinking motion creation."""
        think = ThinkingMotion()
        assert think.duration == 2.0
        assert think.loop is False

    def test_custom_duration(self):
        """Test custom duration."""
        think = ThinkingMotion(duration=5.0)
        assert think.duration == 5.0

    def test_thinking_pose(self):
        """Test thinking pose (hand near chin)."""
        think = ThinkingMotion()
        pose = think._evaluate(0.5)  # In hold phase
        # Right arm should be raised
        assert pose.right_arm.y < 0
        # Head should be tilted
        assert pose.head.rotation != 0


# ============================================================================
# CELEBRATE MOTION TESTS
# ============================================================================

class TestCelebrateMotion:
    """Tests for CelebrateMotion class."""

    def test_creation(self):
        """Test celebrate motion creation."""
        celebrate = CelebrateMotion()
        assert celebrate.duration == 1.2
        assert celebrate.loop is False
        assert celebrate.intensity == 1.0

    def test_arms_raised(self):
        """Test arms are raised during celebration."""
        celebrate = CelebrateMotion()
        pose = celebrate._evaluate(0.5)  # During bounce phase
        # Arms should be raised (negative y = up)
        assert pose.left_arm.y < 0
        assert pose.right_arm.y < 0


# ============================================================================
# WALK CYCLE TESTS
# ============================================================================

class TestWalkCycle:
    """Tests for WalkCycle class."""

    def test_default_creation(self):
        """Test default walk cycle."""
        walk = WalkCycle()
        assert walk.duration == 1.0
        assert walk.loop is True
        assert walk.speed == 1.0

    def test_custom_speed(self):
        """Test walk with custom speed."""
        walk = WalkCycle(speed=2.0)
        assert walk.duration == 0.5  # 1.0 / 2.0

    def test_opposite_leg_phases(self):
        """Test legs move in opposite phases."""
        walk = WalkCycle()
        pose = walk._evaluate(0.25)
        # Legs should be in opposite positions
        # One forward, one back
        assert pose.left_leg.rotation != pose.right_leg.rotation

    def test_opposite_arm_phases(self):
        """Test arms swing opposite to legs."""
        walk = WalkCycle()
        pose = walk._evaluate(0.25)
        # Arms opposite to legs
        assert pose.left_arm.rotation != pose.right_arm.rotation


# ============================================================================
# RUN CYCLE TESTS
# ============================================================================

class TestRunCycle:
    """Tests for RunCycle class."""

    def test_default_creation(self):
        """Test default run cycle."""
        run = RunCycle()
        assert run.duration == 0.5
        assert run.loop is True
        assert run.speed == 1.0

    def test_faster_than_walk(self):
        """Test run is faster than walk."""
        walk = WalkCycle()
        run = RunCycle()
        assert run.duration < walk.duration

    def test_forward_lean(self):
        """Test body leans forward when running."""
        run = RunCycle()
        pose = run._evaluate(0.5)
        assert pose.body.rotation > 0  # Forward lean


# ============================================================================
# MOTION BLENDER TESTS
# ============================================================================

class TestMotionBlender:
    """Tests for MotionBlender class."""

    def test_creation(self):
        """Test blender creation."""
        blender = MotionBlender()
        assert blender.base_motion is None
        assert len(blender.overlay_motions) == 0

    def test_set_base_motion(self):
        """Test setting base motion."""
        blender = MotionBlender()
        idle = IdleMotion()
        blender.set_base_motion(idle)
        assert blender.base_motion == idle

    def test_play_overlay(self):
        """Test playing overlay motion."""
        blender = MotionBlender()
        blender.play_overlay(WaveMotion(), weight=1.0)
        assert len(blender.overlay_motions) == 1

    def test_update_with_base_only(self):
        """Test update with base motion only."""
        blender = MotionBlender()
        blender.set_base_motion(IdleMotion())
        pose = blender.update(0.1)
        assert isinstance(pose, Pose)

    def test_update_with_overlay(self):
        """Test update with overlay motion."""
        blender = MotionBlender()
        blender.set_base_motion(IdleMotion())
        blender.play_overlay(WaveMotion())
        pose = blender.update(0.1)
        assert isinstance(pose, Pose)

    def test_overlay_removed_when_finished(self):
        """Test overlay is removed when finished."""
        blender = MotionBlender()
        blender.set_base_motion(IdleMotion())
        wave = WaveMotion()
        blender.play_overlay(wave)
        assert len(blender.overlay_motions) == 1

        # Update until wave finishes
        for _ in range(50):
            blender.update(0.1)

        assert len(blender.overlay_motions) == 0

    def test_transition_smoothing(self):
        """Test smooth transition when changing base motion."""
        blender = MotionBlender()
        blender.set_base_motion(IdleMotion())
        blender.update(0.5)

        # Change base motion
        blender.set_base_motion(BreathingMotion())
        assert blender.transition_progress == 0.0

        # Transition should progress
        blender.update(0.1)
        assert blender.transition_progress > 0.0

    def test_scale_pose(self):
        """Test pose scaling."""
        blender = MotionBlender()
        pose = Pose(body=Transform(x=100, y=50))
        scaled = blender._scale_pose(pose, 0.5)
        assert scaled.body.x == 50
        assert scaled.body.y == 25


# ============================================================================
# GESTURE GENERATOR TESTS
# ============================================================================

class TestGestureGenerator:
    """Tests for GestureGenerator class."""

    def test_creation(self):
        """Test generator creation."""
        gen = GestureGenerator()
        assert gen.gesture_interval == 2.0
        assert gen.is_speaking is False
        assert len(gen.available_gestures) == 4

    def test_set_speaking(self):
        """Test setting speaking state."""
        gen = GestureGenerator()
        gen.set_speaking(True)
        assert gen.is_speaking is True
        # Should be ready to gesture soon
        assert gen.time_since_gesture > 0

    def test_no_gesture_when_not_speaking(self):
        """Test no gestures when not speaking."""
        gen = GestureGenerator()
        gen.set_speaking(False)
        gesture = gen.update(10.0)  # Long time
        assert gesture is None

    def test_gesture_when_speaking(self):
        """Test gestures generated when speaking."""
        gen = GestureGenerator()
        gen.set_speaking(True)
        # Force gesture by accumulating time
        gen.time_since_gesture = 10.0
        gesture = gen.update(0.1)
        assert gesture is not None
        assert isinstance(gesture, MotionPreset)

    def test_gesture_interval(self):
        """Test gestures respect interval."""
        gen = GestureGenerator()
        gen.set_speaking(True)
        gen.time_since_gesture = 0

        # First update should not generate (interval not reached)
        gesture = gen.update(0.1)
        # May or may not return gesture depending on random variance


# ============================================================================
# FACTORY FUNCTION TESTS
# ============================================================================

class TestFactoryFunctions:
    """Tests for convenience factory functions."""

    def test_create_idle(self):
        """Test create_idle function."""
        idle = create_idle()
        assert isinstance(idle, IdleMotion)
        assert idle.intensity == 1.0

        idle2 = create_idle(intensity=0.5)
        assert idle2.intensity == 0.5

    def test_create_breathing(self):
        """Test create_breathing function."""
        breath = create_breathing()
        assert isinstance(breath, BreathingMotion)

        breath2 = create_breathing(rate=0.5, depth=2.0)
        assert breath2.depth == 2.0

    def test_create_wave(self):
        """Test create_wave function."""
        wave = create_wave()
        assert isinstance(wave, WaveMotion)
        assert wave.waves == 3
        assert wave.hand == 'right'

        wave2 = create_wave(waves=5, hand='left')
        assert wave2.waves == 5
        assert wave2.hand == 'left'

    def test_create_point(self):
        """Test create_point function."""
        point = create_point()
        assert isinstance(point, PointMotion)
        assert point.direction == 'right'

        point2 = create_point(direction='left', hold=1.0)
        assert point2.direction == 'left'
        assert point2.hold_time == 1.0

    def test_create_shrug(self):
        """Test create_shrug function."""
        shrug = create_shrug()
        assert isinstance(shrug, ShrugMotion)
        assert shrug.intensity == 1.0

    def test_create_thinking(self):
        """Test create_thinking function."""
        think = create_thinking()
        assert isinstance(think, ThinkingMotion)
        assert think.duration == 2.0

        think2 = create_thinking(duration=5.0)
        assert think2.duration == 5.0

    def test_create_celebrate(self):
        """Test create_celebrate function."""
        celebrate = create_celebrate()
        assert isinstance(celebrate, CelebrateMotion)
        assert celebrate.intensity == 1.0

    def test_create_walk(self):
        """Test create_walk function."""
        walk = create_walk()
        assert isinstance(walk, WalkCycle)
        assert walk.speed == 1.0

        walk2 = create_walk(speed=2.0)
        assert walk2.speed == 2.0

    def test_create_run(self):
        """Test create_run function."""
        run = create_run()
        assert isinstance(run, RunCycle)
        assert run.speed == 1.0
