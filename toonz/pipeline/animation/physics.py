"""Physics-based animation for secondary motion.

Provides procedural animation effects:
- Spring dynamics (hair, cloth, bounce effects)
- Pendulum motion (swinging objects)
- Breathing animation
- Procedural eye movement (look-at, wander)
- Squash and stretch deformation
- Inertia/follow-through
"""

import math
import random
from dataclasses import dataclass, field
from typing import Tuple, List, Optional, Callable
from .bones import Vec2


@dataclass
class SpringState:
    """Current state of a spring simulation."""
    position: float = 0.0
    velocity: float = 0.0
    target: float = 0.0


class Spring:
    """Damped spring simulation for smooth, bouncy motion.

    Usage:
        spring = Spring(stiffness=300, damping=15)

        # Each frame:
        spring.set_target(mouse_x)
        value = spring.update(delta_time)
    """

    def __init__(
        self,
        stiffness: float = 300.0,
        damping: float = 15.0,
        mass: float = 1.0,
        initial_value: float = 0.0
    ):
        """Initialize spring.

        Args:
            stiffness: Spring constant (higher = faster response)
            damping: Damping coefficient (higher = less oscillation)
            mass: Virtual mass (affects inertia)
            initial_value: Starting value
        """
        self.stiffness = stiffness
        self.damping = damping
        self.mass = mass

        self.state = SpringState(
            position=initial_value,
            velocity=0.0,
            target=initial_value
        )

    @property
    def value(self) -> float:
        """Current spring value."""
        return self.state.position

    def set_target(self, target: float) -> None:
        """Set target value to move towards."""
        self.state.target = target

    def update(self, dt: float) -> float:
        """Update spring simulation.

        Args:
            dt: Time delta in seconds

        Returns:
            Current spring value
        """
        # Calculate spring force
        displacement = self.state.target - self.state.position
        spring_force = displacement * self.stiffness

        # Calculate damping force
        damping_force = -self.state.velocity * self.damping

        # Calculate acceleration
        acceleration = (spring_force + damping_force) / self.mass

        # Update velocity and position
        self.state.velocity += acceleration * dt
        self.state.position += self.state.velocity * dt

        return self.state.position

    def reset(self, value: float = 0.0) -> None:
        """Reset spring to a value with zero velocity."""
        self.state.position = value
        self.state.velocity = 0.0
        self.state.target = value

    def nudge(self, impulse: float) -> None:
        """Apply an impulse to the spring."""
        self.state.velocity += impulse / self.mass


class Spring2D:
    """2D spring for position-based motion."""

    def __init__(
        self,
        stiffness: float = 300.0,
        damping: float = 15.0,
        mass: float = 1.0,
        initial_position: Tuple[float, float] = (0, 0)
    ):
        self.x = Spring(stiffness, damping, mass, initial_position[0])
        self.y = Spring(stiffness, damping, mass, initial_position[1])

    @property
    def value(self) -> Tuple[float, float]:
        return (self.x.value, self.y.value)

    def set_target(self, target: Tuple[float, float]) -> None:
        self.x.set_target(target[0])
        self.y.set_target(target[1])

    def update(self, dt: float) -> Tuple[float, float]:
        return (self.x.update(dt), self.y.update(dt))

    def reset(self, position: Tuple[float, float] = (0, 0)) -> None:
        self.x.reset(position[0])
        self.y.reset(position[1])


@dataclass
class ChainSegment:
    """A segment in a physics chain (for hair/cloth)."""
    position: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    prev_position: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    length: float = 20.0
    mass: float = 1.0


class PhysicsChain:
    """Verlet integration chain for hair/cloth/rope simulation.

    Usage:
        chain = PhysicsChain(
            anchor=(100, 100),
            segments=5,
            segment_length=20.0,
            gravity=(0, 100)
        )

        # Each frame:
        chain.update(dt)
        points = chain.get_points()  # List of (x, y) tuples
    """

    def __init__(
        self,
        anchor: Tuple[float, float],
        segments: int = 5,
        segment_length: float = 20.0,
        gravity: Tuple[float, float] = (0, 100),
        damping: float = 0.98,
        stiffness: float = 0.9
    ):
        """Initialize physics chain.

        Args:
            anchor: Fixed anchor point
            segments: Number of chain segments
            segment_length: Length of each segment
            gravity: Gravity force (x, y)
            damping: Velocity damping (0-1)
            stiffness: Constraint stiffness (0-1)
        """
        self.anchor = Vec2.from_tuple(anchor)
        self.gravity = Vec2.from_tuple(gravity)
        self.damping = damping
        self.stiffness = stiffness
        self.iterations = 3  # Constraint solving iterations

        # Create segments
        self.segments: List[ChainSegment] = []
        pos = self.anchor
        for i in range(segments):
            next_pos = pos + Vec2(0, segment_length)
            seg = ChainSegment(
                position=next_pos,
                prev_position=next_pos,
                length=segment_length
            )
            self.segments.append(seg)
            pos = next_pos

    def update(self, dt: float) -> None:
        """Update physics simulation.

        Args:
            dt: Time delta in seconds
        """
        # Verlet integration for each segment
        # Using scaled gravity for visible effect at typical frame rates
        # Standard Verlet: pos += velocity + accel * dt^2
        # We scale by dt (not dt^2) for more practical behavior
        gravity_step = self.gravity * dt
        for seg in self.segments:
            velocity = (seg.position - seg.prev_position) * self.damping
            seg.prev_position = seg.position
            seg.position = seg.position + velocity + gravity_step

        # Solve distance constraints
        for _ in range(self.iterations):
            self._solve_constraints()

    def _solve_constraints(self) -> None:
        """Solve distance constraints between segments."""
        # Anchor constraint
        if self.segments:
            seg = self.segments[0]
            direction = seg.position - self.anchor
            dist = direction.magnitude()
            if dist > 0:
                correction = direction.normalized() * (dist - seg.length)
                seg.position = seg.position - correction * self.stiffness

        # Inter-segment constraints
        for i in range(1, len(self.segments)):
            prev_seg = self.segments[i - 1]
            seg = self.segments[i]

            direction = seg.position - prev_seg.position
            dist = direction.magnitude()
            if dist > 0:
                error = dist - seg.length
                correction = direction.normalized() * error * 0.5 * self.stiffness

                # Move both segments (unless previous is anchored)
                if i == 1:
                    seg.position = seg.position - correction * 2
                else:
                    prev_seg.position = prev_seg.position + correction
                    seg.position = seg.position - correction

    def set_anchor(self, position: Tuple[float, float]) -> None:
        """Update anchor position."""
        self.anchor = Vec2.from_tuple(position)

    def get_points(self) -> List[Tuple[float, float]]:
        """Get all points in the chain including anchor."""
        points = [self.anchor.to_tuple()]
        for seg in self.segments:
            points.append(seg.position.to_tuple())
        return points

    def apply_force(self, force: Tuple[float, float], index: int = -1) -> None:
        """Apply force to a segment (or all if index=-1)."""
        force_vec = Vec2.from_tuple(force)
        if index == -1:
            for seg in self.segments:
                seg.position = seg.position + force_vec
        elif 0 <= index < len(self.segments):
            self.segments[index].position = self.segments[index].position + force_vec


class BreathingAnimation:
    """Procedural breathing animation.

    Generates smooth oscillating values for chest expansion,
    shoulder movement, and subtle body sway.

    Usage:
        breathing = BreathingAnimation(rate=12)  # breaths per minute

        # Each frame:
        values = breathing.update(frame, fps=30)
        chest_scale = 1.0 + values['chest'] * 0.02
        shoulder_offset = values['shoulders'] * 5
    """

    def __init__(
        self,
        rate: float = 12.0,
        depth: float = 1.0,
        variation: float = 0.1
    ):
        """Initialize breathing animation.

        Args:
            rate: Breaths per minute
            depth: Breathing depth multiplier (0-2)
            variation: Random variation amount
        """
        self.rate = rate
        self.depth = depth
        self.variation = variation

        # Add slight randomness to period
        self._phase_offset = random.random() * math.pi * 2

    def update(self, frame: int, fps: float = 30.0) -> dict:
        """Get breathing values at frame.

        Args:
            frame: Current frame number
            fps: Frames per second

        Returns:
            Dictionary with animation values:
            - chest: Chest expansion (-1 to 1)
            - shoulders: Shoulder lift (0 to 1)
            - sway: Subtle body sway (-1 to 1)
        """
        time = frame / fps
        period = 60.0 / self.rate
        t = (time / period) * math.pi * 2 + self._phase_offset

        # Main breath cycle (sine wave)
        breath = math.sin(t) * self.depth

        # Shoulders follow with delay
        shoulders = max(0, math.sin(t - 0.3)) * self.depth

        # Subtle sway at half frequency
        sway = math.sin(t * 0.5 + 1.0) * 0.3 * self.depth

        # Add variation
        if self.variation > 0:
            noise = math.sin(t * 7.3) * self.variation
            breath += noise * 0.2
            shoulders += noise * 0.1

        return {
            'chest': breath,
            'shoulders': shoulders,
            'sway': sway,
            'inhaling': math.cos(t) > 0
        }


class EyeController:
    """Procedural eye animation controller.

    Handles:
    - Look-at targeting with smooth following
    - Random wandering gaze
    - Blink timing
    - Pupil dilation

    Usage:
        eyes = EyeController()

        # Each frame:
        values = eyes.update(frame, fps=30)
        left_eye_offset = values['left']
        right_eye_offset = values['right']
        blink = values['blink']  # 0 = open, 1 = closed
    """

    def __init__(
        self,
        eye_distance: float = 30.0,
        max_offset: float = 10.0,
        blink_interval: Tuple[float, float] = (2.0, 6.0)
    ):
        """Initialize eye controller.

        Args:
            eye_distance: Distance between eyes
            max_offset: Maximum pupil offset from center
            blink_interval: Min/max seconds between blinks
        """
        self.eye_distance = eye_distance
        self.max_offset = max_offset
        self.blink_interval = blink_interval

        # Target tracking
        self.look_target: Optional[Tuple[float, float]] = None
        self.eye_position = (0, 0)  # Character's eye center position

        # Springs for smooth eye movement
        self.left_spring = Spring2D(stiffness=400, damping=20)
        self.right_spring = Spring2D(stiffness=400, damping=20)

        # Wandering
        self.wandering = True
        self._wander_target = (0, 0)
        self._wander_change_time = 0

        # Blinking
        self._next_blink_time = random.uniform(*blink_interval)
        self._blink_start = -10
        self._blink_duration = 0.15  # seconds

    def set_look_target(self, target: Optional[Tuple[float, float]]) -> None:
        """Set a target for eyes to look at (or None for wandering)."""
        self.look_target = target
        self.wandering = target is None

    def trigger_blink(self) -> None:
        """Trigger a blink immediately."""
        self._blink_start = 0  # Will be set properly in update

    def update(self, frame: int, fps: float = 30.0) -> dict:
        """Update eye animation.

        Args:
            frame: Current frame number
            fps: Frames per second

        Returns:
            Dictionary with:
            - left: (x, y) offset for left pupil
            - right: (x, y) offset for right pupil
            - blink: 0-1 blink amount
            - pupil_size: Relative pupil size
        """
        time = frame / fps
        dt = 1.0 / fps

        # Handle wandering
        if self.wandering:
            if time > self._wander_change_time:
                self._wander_target = (
                    random.uniform(-self.max_offset, self.max_offset),
                    random.uniform(-self.max_offset * 0.5, self.max_offset * 0.5)
                )
                self._wander_change_time = time + random.uniform(0.5, 2.0)

            target = self._wander_target
        elif self.look_target:
            # Calculate direction to target
            dx = self.look_target[0] - self.eye_position[0]
            dy = self.look_target[1] - self.eye_position[1]
            dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0:
                # Clamp offset
                factor = min(1.0, self.max_offset / (dist * 0.1))
                target = (dx * factor * 0.1, dy * factor * 0.1)
            else:
                target = (0, 0)
        else:
            target = (0, 0)

        # Update eye springs (slight parallax between eyes)
        self.left_spring.set_target((target[0] - 1, target[1]))
        self.right_spring.set_target((target[0] + 1, target[1]))

        left_pos = self.left_spring.update(dt)
        right_pos = self.right_spring.update(dt)

        # Handle blinking
        if time > self._next_blink_time:
            self._blink_start = time
            self._next_blink_time = time + random.uniform(*self.blink_interval)

        blink_progress = (time - self._blink_start) / self._blink_duration
        if blink_progress < 0 or blink_progress > 1:
            blink = 0.0
        elif blink_progress < 0.4:
            # Closing
            blink = blink_progress / 0.4
        elif blink_progress < 0.5:
            # Closed
            blink = 1.0
        else:
            # Opening
            blink = 1.0 - (blink_progress - 0.5) / 0.5

        # Subtle pupil size variation
        pupil_size = 1.0 + math.sin(time * 0.5) * 0.05

        return {
            'left': left_pos,
            'right': right_pos,
            'blink': blink,
            'pupil_size': pupil_size
        }


class SquashStretch:
    """Apply squash and stretch deformation.

    Classic animation principle - objects compress when
    accelerating and stretch when decelerating.

    Usage:
        ss = SquashStretch(intensity=0.3)

        # Each frame:
        velocity = current_pos - prev_pos
        scale_x, scale_y = ss.calculate(velocity)
        # Apply scale_x, scale_y to your sprite
    """

    def __init__(
        self,
        intensity: float = 0.3,
        volume_preserve: bool = True
    ):
        """Initialize squash/stretch.

        Args:
            intensity: Effect intensity (0-1)
            volume_preserve: Maintain constant area
        """
        self.intensity = intensity
        self.volume_preserve = volume_preserve

        self._prev_velocity = Vec2(0, 0)
        self._spring = Spring(stiffness=500, damping=25)

    def calculate(
        self,
        velocity: Tuple[float, float],
        dt: float = 1/30
    ) -> Tuple[float, float]:
        """Calculate squash/stretch scale.

        Args:
            velocity: Current velocity (x, y)
            dt: Time delta

        Returns:
            (scale_x, scale_y) to apply
        """
        vel = Vec2.from_tuple(velocity)
        speed = vel.magnitude()

        # Calculate stretch based on speed
        stretch_amount = min(speed * 0.01 * self.intensity, self.intensity)

        # Smooth with spring
        self._spring.set_target(stretch_amount)
        stretch = self._spring.update(dt)

        # Apply stretch along velocity direction
        if speed > 0.1:
            angle = vel.angle()
            # Stretch along velocity
            scale_along = 1.0 + stretch
            scale_perp = 1.0 / scale_along if self.volume_preserve else 1.0 - stretch * 0.5
        else:
            scale_along = 1.0
            scale_perp = 1.0
            angle = 0

        # Convert to x/y based on velocity angle
        cos_a = abs(math.cos(angle))
        sin_a = abs(math.sin(angle))

        scale_x = scale_along * cos_a + scale_perp * sin_a
        scale_y = scale_along * sin_a + scale_perp * cos_a

        return (scale_x, scale_y)


class InertiaFollow:
    """Smooth following with inertia (overshoot and settle).

    Use for elements that should follow movement with delay
    and overshoot, like ponytails, capes, or dangly accessories.

    Usage:
        follower = InertiaFollow(
            delay_frames=5,
            overshoot=0.2,
            settle_time=10
        )

        # Each frame:
        leader_pos = character.position
        follower_pos = follower.update(leader_pos, frame)
    """

    def __init__(
        self,
        delay_frames: int = 5,
        overshoot: float = 0.2,
        settle_time: int = 10
    ):
        """Initialize inertia follower.

        Args:
            delay_frames: Frames of delay behind leader
            overshoot: How much to overshoot (0-1)
            settle_time: Frames to settle after stopping
        """
        self.delay_frames = delay_frames
        self.overshoot = overshoot
        self.settle_time = settle_time

        self._history: List[Tuple[float, float]] = []
        self._spring = Spring2D(
            stiffness=150 / (settle_time / 10),
            damping=10 / (settle_time / 10)
        )

    def update(
        self,
        leader_position: Tuple[float, float],
        frame: int = 0
    ) -> Tuple[float, float]:
        """Update and get follower position.

        Args:
            leader_position: Current leader position
            frame: Current frame number

        Returns:
            Follower position with inertia
        """
        # Add to history
        self._history.append(leader_position)

        # Keep only needed history
        while len(self._history) > self.delay_frames + 1:
            self._history.pop(0)

        # Get delayed target
        if len(self._history) > self.delay_frames:
            delayed = self._history[0]
        else:
            delayed = leader_position

        # Add overshoot based on velocity
        if len(self._history) >= 2:
            vel_x = leader_position[0] - self._history[-2][0]
            vel_y = leader_position[1] - self._history[-2][1]
            target = (
                delayed[0] - vel_x * self.overshoot * self.delay_frames,
                delayed[1] - vel_y * self.overshoot * self.delay_frames
            )
        else:
            target = delayed

        # Smooth with spring
        self._spring.set_target(target)
        return self._spring.update(1/30)

    def reset(self, position: Tuple[float, float]) -> None:
        """Reset to position with no history."""
        self._history = [position]
        self._spring.reset(position)


class Wobble:
    """Procedural wobble/jiggle effect.

    Creates organic wobbling motion, useful for:
    - Jelly/soft body effects
    - Impact reactions
    - Idle bobbing

    Usage:
        wobble = Wobble(frequency=3.0, amplitude=0.1)

        # Trigger wobble on impact
        wobble.trigger(intensity=1.0)

        # Each frame:
        offset = wobble.update(dt)
    """

    def __init__(
        self,
        frequency: float = 3.0,
        amplitude: float = 0.1,
        decay: float = 3.0
    ):
        """Initialize wobble.

        Args:
            frequency: Wobble frequency in Hz
            amplitude: Base amplitude
            decay: How fast wobble dies down
        """
        self.frequency = frequency
        self.amplitude = amplitude
        self.decay = decay

        self._time = 0
        self._intensity = 0
        self._trigger_time = -100

    def trigger(self, intensity: float = 1.0) -> None:
        """Trigger a wobble with given intensity."""
        self._intensity = intensity
        self._trigger_time = self._time

    def update(self, dt: float) -> float:
        """Update and get current wobble offset.

        Args:
            dt: Time delta

        Returns:
            Wobble offset (-1 to 1 range * amplitude)
        """
        self._time += dt

        # Calculate decay
        elapsed = self._time - self._trigger_time
        current_intensity = self._intensity * math.exp(-elapsed * self.decay)

        # Generate wobble
        wobble = math.sin(elapsed * self.frequency * math.pi * 2)

        return wobble * current_intensity * self.amplitude

    @property
    def is_active(self) -> bool:
        """Check if wobble is still visible."""
        elapsed = self._time - self._trigger_time
        return self._intensity * math.exp(-elapsed * self.decay) > 0.01
