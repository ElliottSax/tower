"""Pre-built motion presets for character animation.

Provides reusable animations like idle, gestures, reactions, and walk cycles.
"""

from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional, Callable
import math
import random


@dataclass
class Transform:
    """2D transform for a body part."""
    x: float = 0.0
    y: float = 0.0
    rotation: float = 0.0  # Degrees
    scale_x: float = 1.0
    scale_y: float = 1.0

    def lerp(self, other: 'Transform', t: float) -> 'Transform':
        """Interpolate between transforms."""
        return Transform(
            x=self.x + (other.x - self.x) * t,
            y=self.y + (other.y - self.y) * t,
            rotation=self.rotation + (other.rotation - self.rotation) * t,
            scale_x=self.scale_x + (other.scale_x - self.scale_x) * t,
            scale_y=self.scale_y + (other.scale_y - self.scale_y) * t
        )

    def apply(self, other: 'Transform') -> 'Transform':
        """Combine with another transform (additive)."""
        return Transform(
            x=self.x + other.x,
            y=self.y + other.y,
            rotation=self.rotation + other.rotation,
            scale_x=self.scale_x * other.scale_x,
            scale_y=self.scale_y * other.scale_y
        )


@dataclass
class Pose:
    """A complete character pose with all body part transforms."""
    body: Transform = field(default_factory=Transform)
    head: Transform = field(default_factory=Transform)
    left_arm: Transform = field(default_factory=Transform)
    right_arm: Transform = field(default_factory=Transform)
    left_hand: Transform = field(default_factory=Transform)
    right_hand: Transform = field(default_factory=Transform)
    left_leg: Transform = field(default_factory=Transform)
    right_leg: Transform = field(default_factory=Transform)

    def lerp(self, other: 'Pose', t: float) -> 'Pose':
        """Interpolate between poses."""
        return Pose(
            body=self.body.lerp(other.body, t),
            head=self.head.lerp(other.head, t),
            left_arm=self.left_arm.lerp(other.left_arm, t),
            right_arm=self.right_arm.lerp(other.right_arm, t),
            left_hand=self.left_hand.lerp(other.left_hand, t),
            right_hand=self.right_hand.lerp(other.right_hand, t),
            left_leg=self.left_leg.lerp(other.left_leg, t),
            right_leg=self.right_leg.lerp(other.right_leg, t)
        )

    def apply(self, other: 'Pose') -> 'Pose':
        """Combine with another pose (additive)."""
        return Pose(
            body=self.body.apply(other.body),
            head=self.head.apply(other.head),
            left_arm=self.left_arm.apply(other.left_arm),
            right_arm=self.right_arm.apply(other.right_arm),
            left_hand=self.left_hand.apply(other.left_hand),
            right_hand=self.right_hand.apply(other.right_hand),
            left_leg=self.left_leg.apply(other.left_leg),
            right_leg=self.right_leg.apply(other.right_leg)
        )


class MotionType(Enum):
    """Types of motion animations."""
    IDLE = auto()
    BREATHING = auto()
    TALKING = auto()
    GESTURE_LEFT = auto()
    GESTURE_RIGHT = auto()
    GESTURE_BOTH = auto()
    SHRUG = auto()
    NOD = auto()
    SHAKE_HEAD = auto()
    WAVE = auto()
    POINT_LEFT = auto()
    POINT_RIGHT = auto()
    THINKING = auto()
    CELEBRATE = auto()
    CLAP = auto()
    WALK = auto()
    RUN = auto()


class MotionPreset:
    """Base class for motion presets."""

    def __init__(self, duration: float = 1.0, loop: bool = False):
        self.duration = duration
        self.loop = loop
        self.time = 0.0
        self.is_finished = False

    def reset(self) -> None:
        """Reset animation to start."""
        self.time = 0.0
        self.is_finished = False

    def update(self, dt: float) -> Pose:
        """Update animation and return current pose.

        Args:
            dt: Delta time in seconds

        Returns:
            Current pose
        """
        self.time += dt

        if self.loop:
            self.time = self.time % self.duration
        elif self.time >= self.duration:
            self.time = self.duration
            self.is_finished = True

        progress = self.time / self.duration
        return self._evaluate(progress)

    def _evaluate(self, progress: float) -> Pose:
        """Evaluate pose at given progress (0-1). Override in subclasses."""
        return Pose()


class IdleMotion(MotionPreset):
    """Subtle idle animation with breathing and weight shifts."""

    def __init__(self, intensity: float = 1.0):
        super().__init__(duration=4.0, loop=True)
        self.intensity = intensity

        # Randomize phases
        self.breath_phase = random.random() * math.pi * 2
        self.sway_phase = random.random() * math.pi * 2

    def _evaluate(self, progress: float) -> Pose:
        t = progress * math.pi * 2

        # Breathing
        breath = math.sin(t * 0.5 + self.breath_phase) * 0.02 * self.intensity

        # Subtle body sway
        sway_x = math.sin(t * 0.25 + self.sway_phase) * 2 * self.intensity
        sway_rot = math.sin(t * 0.25 + self.sway_phase) * 0.5 * self.intensity

        # Head follows slightly
        head_rot = math.sin(t * 0.3 + self.sway_phase) * 1.0 * self.intensity

        # Arms hang with slight sway
        arm_rot = math.sin(t * 0.2) * 2 * self.intensity

        return Pose(
            body=Transform(
                x=sway_x,
                y=breath * 10,
                rotation=sway_rot,
                scale_y=1.0 + breath
            ),
            head=Transform(rotation=head_rot),
            left_arm=Transform(rotation=arm_rot),
            right_arm=Transform(rotation=-arm_rot)
        )


class BreathingMotion(MotionPreset):
    """Breathing animation for chest/shoulders."""

    def __init__(self, rate: float = 0.25, depth: float = 1.0):
        """
        Args:
            rate: Breaths per second (0.25 = 15 breaths/min)
            depth: Breathing intensity
        """
        super().__init__(duration=1.0 / rate, loop=True)
        self.depth = depth

    def _evaluate(self, progress: float) -> Pose:
        # Asymmetric breathing: faster inhale, slower exhale
        if progress < 0.4:
            # Inhale
            breath = math.sin(progress / 0.4 * math.pi / 2) ** 0.8
        else:
            # Exhale
            breath = math.cos((progress - 0.4) / 0.6 * math.pi / 2)

        return Pose(
            body=Transform(
                y=breath * 3 * self.depth,
                scale_y=1.0 + breath * 0.02 * self.depth
            ),
            left_arm=Transform(
                y=-breath * 2 * self.depth,
                rotation=-breath * 2 * self.depth
            ),
            right_arm=Transform(
                y=-breath * 2 * self.depth,
                rotation=breath * 2 * self.depth
            )
        )


class TalkingGesture(MotionPreset):
    """Hand gestures while speaking."""

    def __init__(self, intensity: float = 1.0, hand: str = 'right'):
        super().__init__(duration=0.8, loop=False)
        self.intensity = intensity
        self.hand = hand

    def _evaluate(self, progress: float) -> Pose:
        # Quick up, slower down with overshoot
        if progress < 0.3:
            # Raise hand
            amount = self._ease_out(progress / 0.3)
        else:
            # Lower with slight bounce
            t = (progress - 0.3) / 0.7
            amount = 1.0 - self._ease_in_out(t) + math.sin(t * math.pi * 2) * 0.1 * (1 - t)

        hand_y = -30 * amount * self.intensity
        hand_rot = 15 * amount * self.intensity

        if self.hand == 'right':
            return Pose(
                right_arm=Transform(y=hand_y, rotation=-hand_rot),
                right_hand=Transform(rotation=hand_rot * 0.5)
            )
        elif self.hand == 'left':
            return Pose(
                left_arm=Transform(y=hand_y, rotation=hand_rot),
                left_hand=Transform(rotation=-hand_rot * 0.5)
            )
        else:  # both
            return Pose(
                left_arm=Transform(y=hand_y * 0.8, rotation=hand_rot * 0.8),
                right_arm=Transform(y=hand_y, rotation=-hand_rot),
                left_hand=Transform(rotation=-hand_rot * 0.4),
                right_hand=Transform(rotation=hand_rot * 0.5)
            )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 2

    def _ease_in_out(self, t: float) -> float:
        return t * t * (3 - 2 * t)


class ShrugMotion(MotionPreset):
    """Shoulder shrug gesture."""

    def __init__(self, intensity: float = 1.0):
        super().__init__(duration=0.6, loop=False)
        self.intensity = intensity

    def _evaluate(self, progress: float) -> Pose:
        # Quick up, hold, slow down
        if progress < 0.25:
            amount = self._ease_out(progress / 0.25)
        elif progress < 0.5:
            amount = 1.0
        else:
            amount = 1.0 - self._ease_in_out((progress - 0.5) / 0.5)

        shoulder_y = -15 * amount * self.intensity
        head_tilt = 5 * amount * self.intensity

        return Pose(
            head=Transform(rotation=head_tilt, y=-3 * amount),
            left_arm=Transform(y=shoulder_y, rotation=10 * amount),
            right_arm=Transform(y=shoulder_y, rotation=-10 * amount),
            left_hand=Transform(rotation=-20 * amount, y=-5 * amount),
            right_hand=Transform(rotation=20 * amount, y=-5 * amount)
        )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 3

    def _ease_in_out(self, t: float) -> float:
        return t * t * (3 - 2 * t)


class WaveMotion(MotionPreset):
    """Waving hand gesture."""

    def __init__(self, waves: int = 3, hand: str = 'right'):
        super().__init__(duration=0.3 + waves * 0.3, loop=False)
        self.waves = waves
        self.hand = hand

    def _evaluate(self, progress: float) -> Pose:
        duration = self.duration

        # Raise hand phase
        raise_time = 0.3 / duration
        wave_time = (duration - 0.3) / duration

        if progress < raise_time:
            # Raise arm
            t = progress / raise_time
            arm_y = -50 * self._ease_out(t)
            arm_rot = -60 * self._ease_out(t)
            hand_rot = 0
        else:
            # Wave
            wave_progress = (progress - raise_time) / wave_time
            arm_y = -50
            arm_rot = -60

            # Multiple waves
            wave_angle = math.sin(wave_progress * self.waves * math.pi * 2) * 20
            hand_rot = wave_angle

            # Slight fade out at end
            if wave_progress > 0.8:
                fade = (1 - wave_progress) / 0.2
                arm_y *= fade
                arm_rot *= fade
                hand_rot *= fade

        if self.hand == 'right':
            return Pose(
                right_arm=Transform(y=arm_y, rotation=arm_rot),
                right_hand=Transform(rotation=hand_rot)
            )
        else:
            return Pose(
                left_arm=Transform(y=arm_y, rotation=-arm_rot),
                left_hand=Transform(rotation=-hand_rot)
            )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 2


class PointMotion(MotionPreset):
    """Pointing gesture."""

    def __init__(self, direction: str = 'right', hold_time: float = 0.5):
        super().__init__(duration=0.4 + hold_time + 0.3, loop=False)
        self.direction = direction
        self.hold_time = hold_time

    def _evaluate(self, progress: float) -> Pose:
        total = self.duration
        extend_time = 0.4 / total
        hold_end = (0.4 + self.hold_time) / total

        if progress < extend_time:
            # Extend arm
            t = progress / extend_time
            amount = self._ease_out(t)
        elif progress < hold_end:
            # Hold
            amount = 1.0
        else:
            # Retract
            t = (progress - hold_end) / (1 - hold_end)
            amount = 1.0 - self._ease_in(t)

        # Pointing pose
        if self.direction == 'right':
            return Pose(
                body=Transform(rotation=-5 * amount),
                right_arm=Transform(
                    x=20 * amount,
                    y=-20 * amount,
                    rotation=-45 * amount
                ),
                right_hand=Transform(rotation=-15 * amount)
            )
        else:
            return Pose(
                body=Transform(rotation=5 * amount),
                left_arm=Transform(
                    x=-20 * amount,
                    y=-20 * amount,
                    rotation=45 * amount
                ),
                left_hand=Transform(rotation=15 * amount)
            )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 2

    def _ease_in(self, t: float) -> float:
        return t ** 2


class ThinkingMotion(MotionPreset):
    """Hand on chin thinking pose."""

    def __init__(self, duration: float = 2.0):
        super().__init__(duration=duration, loop=False)

    def _evaluate(self, progress: float) -> Pose:
        # Move to thinking pose
        if progress < 0.2:
            amount = self._ease_out(progress / 0.2)
        elif progress < 0.8:
            amount = 1.0
            # Subtle idle motion while thinking
            idle_t = (progress - 0.2) / 0.6
            head_tilt = math.sin(idle_t * math.pi * 2) * 2
        else:
            amount = 1.0 - self._ease_in((progress - 0.8) / 0.2)

        head_tilt = 8 * amount if progress < 0.2 or progress >= 0.8 else 8 + math.sin((progress - 0.2) / 0.6 * math.pi * 2) * 2

        return Pose(
            head=Transform(rotation=head_tilt, y=-3 * amount),
            right_arm=Transform(
                y=-40 * amount,
                x=-10 * amount,
                rotation=-80 * amount
            ),
            right_hand=Transform(
                y=-10 * amount,
                rotation=60 * amount
            )
        )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 2

    def _ease_in(self, t: float) -> float:
        return t ** 2


class CelebrateMotion(MotionPreset):
    """Arms up celebration."""

    def __init__(self, intensity: float = 1.0):
        super().__init__(duration=1.2, loop=False)
        self.intensity = intensity

    def _evaluate(self, progress: float) -> Pose:
        if progress < 0.2:
            # Quick raise
            amount = self._ease_out(progress / 0.2)
        elif progress < 0.7:
            # Celebrate with bounces
            amount = 1.0
            bounce = math.sin((progress - 0.2) / 0.5 * math.pi * 4) * 0.1
        else:
            # Lower
            amount = 1.0 - self._ease_in((progress - 0.7) / 0.3)

        bounce = 0
        if 0.2 <= progress < 0.7:
            bounce = math.sin((progress - 0.2) / 0.5 * math.pi * 4) * 0.1

        return Pose(
            body=Transform(
                y=(-10 + bounce * 50) * amount * self.intensity,
                scale_y=1.0 + bounce * 0.05
            ),
            head=Transform(y=-5 * amount),
            left_arm=Transform(
                y=-60 * amount * self.intensity,
                rotation=30 * amount * self.intensity
            ),
            right_arm=Transform(
                y=-60 * amount * self.intensity,
                rotation=-30 * amount * self.intensity
            ),
            left_hand=Transform(rotation=-20 * amount),
            right_hand=Transform(rotation=20 * amount)
        )

    def _ease_out(self, t: float) -> float:
        return 1 - (1 - t) ** 3

    def _ease_in(self, t: float) -> float:
        return t ** 2


class WalkCycle(MotionPreset):
    """Walking animation cycle."""

    def __init__(self, speed: float = 1.0):
        super().__init__(duration=1.0 / speed, loop=True)
        self.speed = speed

    def _evaluate(self, progress: float) -> Pose:
        t = progress * math.pi * 2

        # Body bob
        body_y = abs(math.sin(t)) * 5

        # Leg swing (opposite phases)
        left_leg_rot = math.sin(t) * 25
        right_leg_rot = math.sin(t + math.pi) * 25

        # Arm swing (opposite to legs)
        left_arm_rot = math.sin(t + math.pi) * 20
        right_arm_rot = math.sin(t) * 20

        # Slight body rotation
        body_rot = math.sin(t) * 3

        return Pose(
            body=Transform(y=-body_y, rotation=body_rot),
            head=Transform(rotation=-body_rot * 0.5),
            left_arm=Transform(rotation=left_arm_rot),
            right_arm=Transform(rotation=right_arm_rot),
            left_leg=Transform(rotation=left_leg_rot),
            right_leg=Transform(rotation=right_leg_rot)
        )


class RunCycle(MotionPreset):
    """Running animation cycle."""

    def __init__(self, speed: float = 1.0):
        super().__init__(duration=0.5 / speed, loop=True)
        self.speed = speed

    def _evaluate(self, progress: float) -> Pose:
        t = progress * math.pi * 2

        # More pronounced body bob
        body_y = abs(math.sin(t)) * 15

        # Bigger leg swing
        left_leg_rot = math.sin(t) * 40
        right_leg_rot = math.sin(t + math.pi) * 40

        # Bigger arm swing
        left_arm_rot = math.sin(t + math.pi) * 35
        right_arm_rot = math.sin(t) * 35

        # Forward lean
        body_lean = 10

        return Pose(
            body=Transform(y=-body_y, rotation=body_lean),
            head=Transform(rotation=-body_lean * 0.3),
            left_arm=Transform(rotation=left_arm_rot, y=-10),
            right_arm=Transform(rotation=right_arm_rot, y=-10),
            left_leg=Transform(rotation=left_leg_rot),
            right_leg=Transform(rotation=right_leg_rot)
        )


class MotionBlender:
    """Blends multiple motion presets together."""

    def __init__(self):
        self.base_motion: Optional[MotionPreset] = None
        self.overlay_motions: list[tuple[MotionPreset, float]] = []  # (motion, weight)
        self.transition_speed = 5.0

        # For smooth transitions
        self.previous_pose = Pose()
        self.transition_progress = 1.0

    def set_base_motion(self, motion: MotionPreset) -> None:
        """Set the base/idle motion."""
        if self.base_motion:
            self.previous_pose = self.base_motion._evaluate(
                self.base_motion.time / self.base_motion.duration
            )
            self.transition_progress = 0.0
        self.base_motion = motion
        motion.reset()

    def play_overlay(self, motion: MotionPreset, weight: float = 1.0) -> None:
        """Play a motion on top of base."""
        motion.reset()
        self.overlay_motions.append((motion, weight))

    def update(self, dt: float) -> Pose:
        """Update all motions and blend."""
        result = Pose()

        # Base motion
        if self.base_motion:
            base_pose = self.base_motion.update(dt)

            # Smooth transition from previous
            if self.transition_progress < 1.0:
                self.transition_progress += self.transition_speed * dt
                self.transition_progress = min(1.0, self.transition_progress)
                t = self._ease_in_out(self.transition_progress)
                base_pose = self.previous_pose.lerp(base_pose, t)

            result = base_pose

        # Overlay motions (additive)
        finished = []
        for i, (motion, weight) in enumerate(self.overlay_motions):
            overlay_pose = motion.update(dt)

            # Scale by weight
            scaled = self._scale_pose(overlay_pose, weight)
            result = result.apply(scaled)

            if motion.is_finished:
                finished.append(i)

        # Remove finished overlays
        for i in reversed(finished):
            self.overlay_motions.pop(i)

        return result

    def _scale_pose(self, pose: Pose, scale: float) -> Pose:
        """Scale a pose's transforms."""
        neutral = Pose()
        return neutral.lerp(pose, scale)

    def _ease_in_out(self, t: float) -> float:
        return t * t * (3 - 2 * t)


class GestureGenerator:
    """Generates contextual gestures for speaking characters."""

    def __init__(self):
        self.gesture_interval = 2.0  # Seconds between gestures
        self.time_since_gesture = 0.0
        self.is_speaking = False

        # Gesture pool
        self.available_gestures = [
            lambda: TalkingGesture(intensity=0.8, hand='right'),
            lambda: TalkingGesture(intensity=0.6, hand='left'),
            lambda: TalkingGesture(intensity=0.7, hand='both'),
            lambda: ShrugMotion(intensity=0.5),
        ]

    def set_speaking(self, speaking: bool) -> None:
        """Update speaking state."""
        self.is_speaking = speaking
        if speaking:
            self.time_since_gesture = self.gesture_interval * 0.5  # Start with gesture soon

    def update(self, dt: float) -> Optional[MotionPreset]:
        """Update and potentially return a new gesture.

        Returns:
            A new gesture to play, or None
        """
        if not self.is_speaking:
            return None

        self.time_since_gesture += dt

        # Random variation in timing
        interval = self.gesture_interval + random.uniform(-0.5, 0.5)

        if self.time_since_gesture >= interval:
            self.time_since_gesture = 0.0
            # Pick random gesture
            gesture_factory = random.choice(self.available_gestures)
            return gesture_factory()

        return None


# Convenience functions for creating common motions
def create_idle(intensity: float = 1.0) -> MotionPreset:
    """Create an idle animation."""
    return IdleMotion(intensity=intensity)


def create_breathing(rate: float = 0.25, depth: float = 1.0) -> MotionPreset:
    """Create a breathing animation."""
    return BreathingMotion(rate=rate, depth=depth)


def create_wave(waves: int = 3, hand: str = 'right') -> MotionPreset:
    """Create a wave gesture."""
    return WaveMotion(waves=waves, hand=hand)


def create_point(direction: str = 'right', hold: float = 0.5) -> MotionPreset:
    """Create a pointing gesture."""
    return PointMotion(direction=direction, hold_time=hold)


def create_shrug(intensity: float = 1.0) -> MotionPreset:
    """Create a shrug gesture."""
    return ShrugMotion(intensity=intensity)


def create_thinking(duration: float = 2.0) -> MotionPreset:
    """Create a thinking pose."""
    return ThinkingMotion(duration=duration)


def create_celebrate(intensity: float = 1.0) -> MotionPreset:
    """Create a celebration animation."""
    return CelebrateMotion(intensity=intensity)


def create_walk(speed: float = 1.0) -> MotionPreset:
    """Create a walk cycle."""
    return WalkCycle(speed=speed)


def create_run(speed: float = 1.0) -> MotionPreset:
    """Create a run cycle."""
    return RunCycle(speed=speed)
