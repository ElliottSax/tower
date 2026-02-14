"""Facial expression system for character animation.

Provides emotion blending, eyebrow control, and procedural facial animation.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import math
import random


class Emotion(Enum):
    """Base emotions for expression blending."""
    NEUTRAL = "neutral"
    HAPPY = "happy"
    SAD = "sad"
    ANGRY = "angry"
    SURPRISED = "surprised"
    FEARFUL = "fearful"
    DISGUSTED = "disgusted"
    CONFUSED = "confused"


@dataclass
class EyebrowState:
    """Eyebrow position and shape.

    Values range from -1.0 to 1.0:
    - height: -1 = lowered, 0 = neutral, 1 = raised
    - inner_raise: inner brow raise (for sad/worried)
    - furrow: brow furrow/squeeze together
    """
    height: float = 0.0
    inner_raise: float = 0.0
    furrow: float = 0.0

    def lerp(self, other: 'EyebrowState', t: float) -> 'EyebrowState':
        """Interpolate between eyebrow states."""
        return EyebrowState(
            height=self.height + (other.height - self.height) * t,
            inner_raise=self.inner_raise + (other.inner_raise - self.inner_raise) * t,
            furrow=self.furrow + (other.furrow - self.furrow) * t
        )


@dataclass
class EyeState:
    """Eye openness and shape.

    Values:
    - openness: 0 = closed, 0.5 = half, 1 = normal, 1.5 = wide
    - squint: 0 = none, 1 = full squint
    - pupil_size: 0.5 = constricted, 1 = normal, 1.5 = dilated
    """
    openness: float = 1.0
    squint: float = 0.0
    pupil_size: float = 1.0

    def lerp(self, other: 'EyeState', t: float) -> 'EyeState':
        """Interpolate between eye states."""
        return EyeState(
            openness=self.openness + (other.openness - self.openness) * t,
            squint=self.squint + (other.squint - self.squint) * t,
            pupil_size=self.pupil_size + (other.pupil_size - self.pupil_size) * t
        )


@dataclass
class MouthState:
    """Mouth shape beyond lip sync.

    Values:
    - smile: -1 = frown, 0 = neutral, 1 = smile
    - open: 0 = closed, 1 = open
    - pucker: 0 = none, 1 = puckered
    - width: 0.5 = narrow, 1 = normal, 1.5 = wide
    """
    smile: float = 0.0
    open: float = 0.0
    pucker: float = 0.0
    width: float = 1.0

    def lerp(self, other: 'MouthState', t: float) -> 'MouthState':
        """Interpolate between mouth states."""
        return MouthState(
            smile=self.smile + (other.smile - self.smile) * t,
            open=self.open + (other.open - self.open) * t,
            pucker=self.pucker + (other.pucker - self.pucker) * t,
            width=self.width + (other.width - self.width) * t
        )


@dataclass
class FaceState:
    """Complete facial state combining all features."""
    left_eyebrow: EyebrowState = field(default_factory=EyebrowState)
    right_eyebrow: EyebrowState = field(default_factory=EyebrowState)
    left_eye: EyeState = field(default_factory=EyeState)
    right_eye: EyeState = field(default_factory=EyeState)
    mouth: MouthState = field(default_factory=MouthState)
    head_tilt: float = 0.0  # -1 to 1 (left to right)
    head_nod: float = 0.0   # -1 to 1 (down to up)

    def lerp(self, other: 'FaceState', t: float) -> 'FaceState':
        """Interpolate between face states."""
        return FaceState(
            left_eyebrow=self.left_eyebrow.lerp(other.left_eyebrow, t),
            right_eyebrow=self.right_eyebrow.lerp(other.right_eyebrow, t),
            left_eye=self.left_eye.lerp(other.left_eye, t),
            right_eye=self.right_eye.lerp(other.right_eye, t),
            mouth=self.mouth.lerp(other.mouth, t),
            head_tilt=self.head_tilt + (other.head_tilt - self.head_tilt) * t,
            head_nod=self.head_nod + (other.head_nod - self.head_nod) * t
        )


# Pre-defined emotion templates
EMOTION_TEMPLATES: dict[Emotion, FaceState] = {
    Emotion.NEUTRAL: FaceState(),

    Emotion.HAPPY: FaceState(
        left_eyebrow=EyebrowState(height=0.2),
        right_eyebrow=EyebrowState(height=0.2),
        left_eye=EyeState(openness=0.9, squint=0.3),
        right_eye=EyeState(openness=0.9, squint=0.3),
        mouth=MouthState(smile=0.8, width=1.2),
    ),

    Emotion.SAD: FaceState(
        left_eyebrow=EyebrowState(height=-0.2, inner_raise=0.6),
        right_eyebrow=EyebrowState(height=-0.2, inner_raise=0.6),
        left_eye=EyeState(openness=0.7),
        right_eye=EyeState(openness=0.7),
        mouth=MouthState(smile=-0.5, width=0.9),
        head_nod=-0.2,
    ),

    Emotion.ANGRY: FaceState(
        left_eyebrow=EyebrowState(height=-0.4, furrow=0.8),
        right_eyebrow=EyebrowState(height=-0.4, furrow=0.8),
        left_eye=EyeState(openness=0.8, squint=0.4),
        right_eye=EyeState(openness=0.8, squint=0.4),
        mouth=MouthState(smile=-0.3, width=0.8),
        head_nod=0.1,
    ),

    Emotion.SURPRISED: FaceState(
        left_eyebrow=EyebrowState(height=0.8),
        right_eyebrow=EyebrowState(height=0.8),
        left_eye=EyeState(openness=1.4, pupil_size=1.3),
        right_eye=EyeState(openness=1.4, pupil_size=1.3),
        mouth=MouthState(open=0.6, width=0.9),
    ),

    Emotion.FEARFUL: FaceState(
        left_eyebrow=EyebrowState(height=0.5, inner_raise=0.7),
        right_eyebrow=EyebrowState(height=0.5, inner_raise=0.7),
        left_eye=EyeState(openness=1.3, pupil_size=0.7),
        right_eye=EyeState(openness=1.3, pupil_size=0.7),
        mouth=MouthState(open=0.3, width=1.1),
        head_nod=-0.1,
    ),

    Emotion.DISGUSTED: FaceState(
        left_eyebrow=EyebrowState(height=-0.2, furrow=0.4),
        right_eyebrow=EyebrowState(height=0.1),
        left_eye=EyeState(openness=0.7, squint=0.5),
        right_eye=EyeState(openness=0.9),
        mouth=MouthState(smile=-0.2, pucker=0.3, width=0.85),
        head_tilt=-0.1,
    ),

    Emotion.CONFUSED: FaceState(
        left_eyebrow=EyebrowState(height=-0.1, furrow=0.3),
        right_eyebrow=EyebrowState(height=0.4),
        left_eye=EyeState(openness=0.9),
        right_eye=EyeState(openness=1.1),
        mouth=MouthState(smile=-0.1, pucker=0.2),
        head_tilt=0.15,
    ),
}


class ExpressionController:
    """Controls facial expressions with blending and transitions."""

    def __init__(self):
        self.current_state = FaceState()
        self.target_state = FaceState()
        self.transition_speed = 5.0  # Units per second
        self.transition_progress = 1.0

        # Emotion blend weights (can blend multiple emotions)
        self.emotion_weights: dict[Emotion, float] = {
            Emotion.NEUTRAL: 1.0
        }

        # Micro-expression system
        self.micro_expressions_enabled = True
        self.micro_expression_timer = 0.0
        self.micro_expression_interval = 3.0  # Seconds between micro-expressions
        self.current_micro_expression: Optional[FaceState] = None
        self.micro_expression_blend = 0.0

    def set_emotion(self, emotion: Emotion, weight: float = 1.0,
                    blend: bool = True) -> None:
        """Set the target emotion.

        Args:
            emotion: The emotion to transition to
            weight: How strongly to apply (0-1)
            blend: If True, blend with current. If False, replace.
        """
        if blend:
            # Normalize existing weights
            total = sum(self.emotion_weights.values()) + weight
            if total > 0:
                for e in self.emotion_weights:
                    self.emotion_weights[e] /= total
                self.emotion_weights[emotion] = weight / total
        else:
            self.emotion_weights = {emotion: weight}

        # Calculate blended target state
        self._update_target_state()
        self.transition_progress = 0.0

    def clear_emotions(self) -> None:
        """Reset to neutral expression."""
        self.emotion_weights = {Emotion.NEUTRAL: 1.0}
        self._update_target_state()
        self.transition_progress = 0.0

    def _update_target_state(self) -> None:
        """Calculate target state from emotion weights."""
        # Start with neutral
        result = FaceState()

        # Blend all active emotions
        for emotion, weight in self.emotion_weights.items():
            if weight > 0 and emotion in EMOTION_TEMPLATES:
                template = EMOTION_TEMPLATES[emotion]
                result = result.lerp(template, weight)

        self.target_state = result

    def update(self, dt: float) -> FaceState:
        """Update expression state.

        Args:
            dt: Delta time in seconds

        Returns:
            Current face state
        """
        # Transition toward target
        if self.transition_progress < 1.0:
            self.transition_progress += self.transition_speed * dt
            self.transition_progress = min(1.0, self.transition_progress)

            # Smooth easing
            t = self._ease_in_out(self.transition_progress)
            self.current_state = self.current_state.lerp(self.target_state, t)

        # Micro-expressions
        if self.micro_expressions_enabled:
            self._update_micro_expressions(dt)

        # Apply micro-expression overlay
        if self.current_micro_expression and self.micro_expression_blend > 0:
            return self.current_state.lerp(
                self.current_micro_expression,
                self.micro_expression_blend * 0.3  # Subtle effect
            )

        return self.current_state

    def _ease_in_out(self, t: float) -> float:
        """Smooth easing function."""
        return t * t * (3 - 2 * t)

    def _update_micro_expressions(self, dt: float) -> None:
        """Update micro-expression system."""
        self.micro_expression_timer += dt

        # Fade out current micro-expression
        if self.micro_expression_blend > 0:
            self.micro_expression_blend -= dt * 2.0
            self.micro_expression_blend = max(0, self.micro_expression_blend)

        # Trigger new micro-expression
        if self.micro_expression_timer >= self.micro_expression_interval:
            self.micro_expression_timer = 0
            self.micro_expression_interval = 2.0 + random.random() * 4.0

            # Random subtle expression
            self.current_micro_expression = self._generate_micro_expression()
            self.micro_expression_blend = 1.0

    def _generate_micro_expression(self) -> FaceState:
        """Generate a random subtle micro-expression."""
        state = FaceState()

        # Random eyebrow twitch
        if random.random() < 0.3:
            brow = EyebrowState(
                height=random.uniform(-0.1, 0.2),
                inner_raise=random.uniform(0, 0.15)
            )
            if random.random() < 0.5:
                state.left_eyebrow = brow
            else:
                state.right_eyebrow = brow

        # Slight eye movement
        if random.random() < 0.3:
            state.left_eye = EyeState(openness=random.uniform(0.9, 1.1))
            state.right_eye = EyeState(openness=random.uniform(0.9, 1.1))

        # Subtle mouth movement
        if random.random() < 0.2:
            state.mouth = MouthState(
                smile=random.uniform(-0.1, 0.1),
                pucker=random.uniform(0, 0.1)
            )

        return state


class BlinkController:
    """Procedural blinking with natural timing."""

    def __init__(self):
        self.blink_duration = 0.15  # Seconds for full blink
        self.min_interval = 2.0    # Minimum seconds between blinks
        self.max_interval = 6.0    # Maximum seconds between blinks

        self.time_to_next_blink = self._random_interval()
        self.blink_progress = 1.0  # 0 = closed, 1 = open
        self.is_blinking = False

        # Double blink probability
        self.double_blink_chance = 0.15
        self.pending_double_blink = False

    def _random_interval(self) -> float:
        """Get random time until next blink."""
        return self.min_interval + random.random() * (self.max_interval - self.min_interval)

    def trigger_blink(self) -> None:
        """Force a blink."""
        self.is_blinking = True
        self.blink_progress = 1.0

    def update(self, dt: float) -> float:
        """Update blink state.

        Args:
            dt: Delta time in seconds

        Returns:
            Eye openness (0 = closed, 1 = open)
        """
        if self.is_blinking:
            # Blink animation
            self.blink_progress -= dt / (self.blink_duration / 2)

            if self.blink_progress <= 0:
                # Eyes fully closed, start opening
                self.blink_progress = 0
                self.is_blinking = False

                # Check for double blink
                if random.random() < self.double_blink_chance:
                    self.pending_double_blink = True
        else:
            # Opening or waiting
            if self.blink_progress < 1.0:
                self.blink_progress += dt / (self.blink_duration / 2)
                self.blink_progress = min(1.0, self.blink_progress)

                # Trigger second blink if pending
                if self.blink_progress >= 1.0 and self.pending_double_blink:
                    self.pending_double_blink = False
                    self.time_to_next_blink = 0.1  # Quick second blink
            else:
                # Countdown to next blink
                self.time_to_next_blink -= dt
                if self.time_to_next_blink <= 0:
                    self.trigger_blink()
                    self.time_to_next_blink = self._random_interval()

        # Smooth the blink curve
        return self._blink_curve(self.blink_progress)

    def _blink_curve(self, t: float) -> float:
        """Easing curve for natural blink motion."""
        # Fast close, slower open
        if t < 0.5:
            return 1 - (1 - t * 2) ** 2
        else:
            return ((t - 0.5) * 2) ** 0.5


class LipSyncBlender:
    """Blends lip sync mouth shapes with expression mouth state."""

    # Mouth shape definitions (matching Rhubarb output)
    MOUTH_SHAPES = {
        'X': MouthState(open=0.0, smile=0.0, width=1.0),      # Rest
        'A': MouthState(open=0.0, smile=0.0, width=1.0),      # Closed
        'B': MouthState(open=0.2, smile=0.0, width=1.0),      # Teeth visible
        'C': MouthState(open=0.5, smile=0.0, width=1.1),      # Open
        'D': MouthState(open=0.7, smile=0.0, width=1.2),      # Wide open
        'E': MouthState(open=0.4, smile=0.0, width=0.9),      # Rounded
        'F': MouthState(open=0.2, pucker=0.6, width=0.8),     # Puckered (F/V)
        'G': MouthState(open=0.1, smile=0.0, width=0.9),      # F/V sound
        'H': MouthState(open=0.3, smile=0.1, width=1.0),      # L sound
    }

    def __init__(self):
        self.current_shape = 'X'
        self.target_shape = 'X'
        self.blend_progress = 1.0
        self.blend_speed = 15.0  # Fast for lip sync

    def set_shape(self, shape: str) -> None:
        """Set target mouth shape from lip sync."""
        if shape != self.target_shape:
            self.current_shape = self.target_shape
            self.target_shape = shape
            self.blend_progress = 0.0

    def update(self, dt: float) -> MouthState:
        """Update and return current mouth state."""
        if self.blend_progress < 1.0:
            self.blend_progress += self.blend_speed * dt
            self.blend_progress = min(1.0, self.blend_progress)

        current = self.MOUTH_SHAPES.get(self.current_shape, self.MOUTH_SHAPES['X'])
        target = self.MOUTH_SHAPES.get(self.target_shape, self.MOUTH_SHAPES['X'])

        return current.lerp(target, self.blend_progress)

    def blend_with_expression(self, lip_sync_mouth: MouthState,
                              expression_mouth: MouthState,
                              lip_sync_weight: float = 0.8) -> MouthState:
        """Blend lip sync with expression.

        Args:
            lip_sync_mouth: Mouth state from lip sync
            expression_mouth: Mouth state from expression
            lip_sync_weight: How much lip sync dominates (0-1)

        Returns:
            Blended mouth state
        """
        # Lip sync controls open/width, expression controls smile/pucker overlay
        return MouthState(
            open=lip_sync_mouth.open * lip_sync_weight + expression_mouth.open * (1 - lip_sync_weight),
            smile=expression_mouth.smile * 0.5 + lip_sync_mouth.smile * 0.5,
            pucker=max(lip_sync_mouth.pucker, expression_mouth.pucker * 0.3),
            width=lip_sync_mouth.width * lip_sync_weight + expression_mouth.width * (1 - lip_sync_weight)
        )


class HeadMotionController:
    """Procedural head motion for natural movement."""

    def __init__(self):
        self.base_tilt = 0.0
        self.base_nod = 0.0

        # Idle motion parameters
        self.idle_amplitude = 0.05
        self.idle_frequency = 0.3  # Hz

        # Nod/shake for emphasis
        self.nod_queue: list[tuple[float, float]] = []  # (intensity, duration)
        self.current_nod_time = 0.0
        self.current_nod_intensity = 0.0
        self.current_nod_duration = 0.0

        self.time = 0.0

    def nod_yes(self, intensity: float = 0.3, duration: float = 0.5) -> None:
        """Queue a nodding motion."""
        self.nod_queue.append((intensity, duration))

    def shake_no(self, intensity: float = 0.3, duration: float = 0.6) -> None:
        """Queue a head shake."""
        self.nod_queue.append((-intensity, duration))  # Negative for shake

    def update(self, dt: float) -> tuple[float, float]:
        """Update head motion.

        Returns:
            (tilt, nod) values
        """
        self.time += dt

        # Base idle motion (subtle figure-8 pattern)
        idle_tilt = math.sin(self.time * self.idle_frequency * 2 * math.pi) * self.idle_amplitude
        idle_nod = math.sin(self.time * self.idle_frequency * 1.3 * 2 * math.pi) * self.idle_amplitude * 0.7

        # Process nod/shake queue
        nod_tilt = 0.0
        nod_nod = 0.0

        if self.current_nod_duration > 0:
            self.current_nod_time += dt

            if self.current_nod_time >= self.current_nod_duration:
                self.current_nod_duration = 0
                self.current_nod_time = 0

                # Get next from queue
                if self.nod_queue:
                    intensity, duration = self.nod_queue.pop(0)
                    self.current_nod_intensity = intensity
                    self.current_nod_duration = duration
            else:
                # Animate current nod/shake
                progress = self.current_nod_time / self.current_nod_duration
                wave = math.sin(progress * math.pi * 3) * (1 - progress)  # Damped oscillation

                if self.current_nod_intensity > 0:
                    # Nodding (up/down)
                    nod_nod = wave * self.current_nod_intensity
                else:
                    # Shaking (left/right)
                    nod_tilt = wave * abs(self.current_nod_intensity)
        elif self.nod_queue:
            intensity, duration = self.nod_queue.pop(0)
            self.current_nod_intensity = intensity
            self.current_nod_duration = duration
            self.current_nod_time = 0

        return (
            self.base_tilt + idle_tilt + nod_tilt,
            self.base_nod + idle_nod + nod_nod
        )


class FacialAnimator:
    """Complete facial animation controller combining all systems."""

    def __init__(self):
        self.expression = ExpressionController()
        self.blink = BlinkController()
        self.lip_sync = LipSyncBlender()
        self.head_motion = HeadMotionController()

        self.is_speaking = False

    def set_emotion(self, emotion: Emotion, weight: float = 1.0) -> None:
        """Set the current emotion."""
        self.expression.set_emotion(emotion, weight, blend=False)

    def blend_emotion(self, emotion: Emotion, weight: float = 0.5) -> None:
        """Blend an emotion with current state."""
        self.expression.set_emotion(emotion, weight, blend=True)

    def set_lip_sync_shape(self, shape: str) -> None:
        """Set mouth shape from lip sync."""
        self.lip_sync.set_shape(shape)
        self.is_speaking = shape not in ('X', 'A')

    def nod(self) -> None:
        """Trigger a head nod."""
        self.head_motion.nod_yes()

    def shake(self) -> None:
        """Trigger a head shake."""
        self.head_motion.shake_no()

    def blink_now(self) -> None:
        """Trigger an immediate blink."""
        self.blink.trigger_blink()

    def update(self, dt: float) -> FaceState:
        """Update all facial animation systems.

        Args:
            dt: Delta time in seconds

        Returns:
            Complete face state for rendering
        """
        # Get expression state
        face = self.expression.update(dt)

        # Apply blink
        blink_openness = self.blink.update(dt)
        face.left_eye.openness *= blink_openness
        face.right_eye.openness *= blink_openness

        # Apply lip sync
        lip_sync_mouth = self.lip_sync.update(dt)
        face.mouth = self.lip_sync.blend_with_expression(
            lip_sync_mouth,
            face.mouth,
            lip_sync_weight=0.9 if self.is_speaking else 0.3
        )

        # Apply head motion
        tilt, nod = self.head_motion.update(dt)
        face.head_tilt += tilt
        face.head_nod += nod

        return face

    def get_asset_keys(self, face: FaceState) -> dict[str, str]:
        """Convert face state to asset layer keys.

        Returns dict mapping layer names to asset variant keys.
        """
        keys = {}

        # Eyebrow variants based on state
        avg_brow_height = (face.left_eyebrow.height + face.right_eyebrow.height) / 2
        if avg_brow_height > 0.3:
            keys['eyebrows'] = 'raised'
        elif avg_brow_height < -0.2:
            if face.left_eyebrow.furrow > 0.4:
                keys['eyebrows'] = 'angry'
            else:
                keys['eyebrows'] = 'sad'
        else:
            keys['eyebrows'] = 'neutral'

        # Eye variants based on openness
        avg_openness = (face.left_eye.openness + face.right_eye.openness) / 2
        if avg_openness < 0.2:
            keys['eyes'] = 'closed'
        elif avg_openness < 0.6:
            keys['eyes'] = 'half'
        elif avg_openness > 1.2:
            keys['eyes'] = 'wide'
        else:
            keys['eyes'] = 'open'

        # Mouth - defer to lip sync system for actual shape
        # This is just for expression overlay
        if face.mouth.smile > 0.4:
            keys['mouth_expression'] = 'smile'
        elif face.mouth.smile < -0.3:
            keys['mouth_expression'] = 'frown'
        else:
            keys['mouth_expression'] = 'neutral'

        return keys
