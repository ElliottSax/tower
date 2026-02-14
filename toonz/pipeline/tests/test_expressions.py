"""Tests for animation/expressions.py module."""

import math
from unittest.mock import patch

import pytest

from pipeline.animation.expressions import (
    Emotion,
    EyebrowState,
    EyeState,
    MouthState,
    FaceState,
    EMOTION_TEMPLATES,
    ExpressionController,
    BlinkController,
    LipSyncBlender,
    HeadMotionController,
    FacialAnimator,
)


class TestEmotion:
    """Tests for Emotion enum."""

    def test_all_emotions_defined(self):
        """Test all expected emotions exist."""
        assert Emotion.NEUTRAL.value == "neutral"
        assert Emotion.HAPPY.value == "happy"
        assert Emotion.SAD.value == "sad"
        assert Emotion.ANGRY.value == "angry"
        assert Emotion.SURPRISED.value == "surprised"
        assert Emotion.FEARFUL.value == "fearful"
        assert Emotion.DISGUSTED.value == "disgusted"
        assert Emotion.CONFUSED.value == "confused"


class TestEyebrowState:
    """Tests for EyebrowState dataclass."""

    def test_default_values(self):
        """Test default eyebrow state."""
        state = EyebrowState()
        assert state.height == 0.0
        assert state.inner_raise == 0.0
        assert state.furrow == 0.0

    def test_custom_values(self):
        """Test custom eyebrow state."""
        state = EyebrowState(height=0.5, inner_raise=0.3, furrow=0.2)
        assert state.height == 0.5
        assert state.inner_raise == 0.3
        assert state.furrow == 0.2

    def test_lerp_midpoint(self):
        """Test interpolation at midpoint."""
        a = EyebrowState(height=0.0, inner_raise=0.0, furrow=0.0)
        b = EyebrowState(height=1.0, inner_raise=0.6, furrow=0.4)

        result = a.lerp(b, 0.5)

        assert result.height == 0.5
        assert result.inner_raise == 0.3
        assert result.furrow == 0.2

    def test_lerp_at_zero(self):
        """Test interpolation at t=0."""
        a = EyebrowState(height=0.0)
        b = EyebrowState(height=1.0)

        result = a.lerp(b, 0.0)
        assert result.height == 0.0

    def test_lerp_at_one(self):
        """Test interpolation at t=1."""
        a = EyebrowState(height=0.0)
        b = EyebrowState(height=1.0)

        result = a.lerp(b, 1.0)
        assert result.height == 1.0


class TestEyeState:
    """Tests for EyeState dataclass."""

    def test_default_values(self):
        """Test default eye state."""
        state = EyeState()
        assert state.openness == 1.0
        assert state.squint == 0.0
        assert state.pupil_size == 1.0

    def test_custom_values(self):
        """Test custom eye state."""
        state = EyeState(openness=0.5, squint=0.3, pupil_size=1.2)
        assert state.openness == 0.5
        assert state.squint == 0.3
        assert state.pupil_size == 1.2

    def test_lerp(self):
        """Test eye state interpolation."""
        a = EyeState(openness=1.0, squint=0.0, pupil_size=1.0)
        b = EyeState(openness=0.0, squint=1.0, pupil_size=1.5)

        result = a.lerp(b, 0.5)

        assert result.openness == 0.5
        assert result.squint == 0.5
        assert result.pupil_size == 1.25


class TestMouthState:
    """Tests for MouthState dataclass."""

    def test_default_values(self):
        """Test default mouth state."""
        state = MouthState()
        assert state.smile == 0.0
        assert state.open == 0.0
        assert state.pucker == 0.0
        assert state.width == 1.0

    def test_custom_values(self):
        """Test custom mouth state."""
        state = MouthState(smile=0.8, open=0.5, pucker=0.2, width=1.2)
        assert state.smile == 0.8
        assert state.open == 0.5
        assert state.pucker == 0.2
        assert state.width == 1.2

    def test_lerp(self):
        """Test mouth state interpolation."""
        a = MouthState(smile=0.0, open=0.0, pucker=0.0, width=1.0)
        b = MouthState(smile=1.0, open=1.0, pucker=0.5, width=1.5)

        result = a.lerp(b, 0.5)

        assert result.smile == 0.5
        assert result.open == 0.5
        assert result.pucker == 0.25
        assert result.width == 1.25


class TestFaceState:
    """Tests for FaceState dataclass."""

    def test_default_values(self):
        """Test default face state."""
        state = FaceState()

        assert state.left_eyebrow.height == 0.0
        assert state.right_eyebrow.height == 0.0
        assert state.left_eye.openness == 1.0
        assert state.right_eye.openness == 1.0
        assert state.mouth.smile == 0.0
        assert state.head_tilt == 0.0
        assert state.head_nod == 0.0

    def test_custom_values(self):
        """Test face state with custom components."""
        state = FaceState(
            left_eyebrow=EyebrowState(height=0.5),
            right_eyebrow=EyebrowState(height=0.3),
            head_tilt=0.2,
            head_nod=-0.1
        )

        assert state.left_eyebrow.height == 0.5
        assert state.right_eyebrow.height == 0.3
        assert state.head_tilt == 0.2
        assert state.head_nod == -0.1

    def test_lerp(self):
        """Test face state interpolation."""
        a = FaceState(head_tilt=0.0, head_nod=0.0)
        b = FaceState(head_tilt=1.0, head_nod=-1.0)

        result = a.lerp(b, 0.5)

        assert result.head_tilt == 0.5
        assert result.head_nod == -0.5


class TestEmotionTemplates:
    """Tests for EMOTION_TEMPLATES."""

    def test_all_emotions_have_templates(self):
        """Test all emotions have templates."""
        for emotion in Emotion:
            assert emotion in EMOTION_TEMPLATES

    def test_neutral_is_default(self):
        """Test neutral template is at defaults."""
        neutral = EMOTION_TEMPLATES[Emotion.NEUTRAL]
        assert neutral.head_tilt == 0.0
        assert neutral.head_nod == 0.0

    def test_happy_has_smile(self):
        """Test happy template has smile."""
        happy = EMOTION_TEMPLATES[Emotion.HAPPY]
        assert happy.mouth.smile > 0.5

    def test_sad_has_frown(self):
        """Test sad template has frown."""
        sad = EMOTION_TEMPLATES[Emotion.SAD]
        assert sad.mouth.smile < 0

    def test_angry_has_furrowed_brows(self):
        """Test angry template has furrowed brows."""
        angry = EMOTION_TEMPLATES[Emotion.ANGRY]
        assert angry.left_eyebrow.furrow > 0.5
        assert angry.right_eyebrow.furrow > 0.5

    def test_surprised_has_wide_eyes(self):
        """Test surprised template has wide eyes."""
        surprised = EMOTION_TEMPLATES[Emotion.SURPRISED]
        assert surprised.left_eye.openness > 1.0
        assert surprised.right_eye.openness > 1.0


class TestExpressionController:
    """Tests for ExpressionController class."""

    def test_creation(self):
        """Test controller creation."""
        controller = ExpressionController()

        assert controller.current_state is not None
        assert controller.target_state is not None
        assert Emotion.NEUTRAL in controller.emotion_weights

    def test_set_emotion_replace(self):
        """Test setting emotion without blending."""
        controller = ExpressionController()
        controller.set_emotion(Emotion.HAPPY, weight=1.0, blend=False)

        assert Emotion.HAPPY in controller.emotion_weights
        assert controller.emotion_weights[Emotion.HAPPY] == 1.0
        assert controller.transition_progress == 0.0

    def test_set_emotion_blend(self):
        """Test setting emotion with blending."""
        controller = ExpressionController()
        controller.set_emotion(Emotion.HAPPY, weight=0.5, blend=True)

        # Should have both neutral and happy
        assert len(controller.emotion_weights) == 2
        assert Emotion.NEUTRAL in controller.emotion_weights
        assert Emotion.HAPPY in controller.emotion_weights

    def test_clear_emotions(self):
        """Test clearing to neutral."""
        controller = ExpressionController()
        controller.set_emotion(Emotion.HAPPY, blend=False)
        controller.clear_emotions()

        assert controller.emotion_weights == {Emotion.NEUTRAL: 1.0}

    def test_update_transitions(self):
        """Test update transitions toward target."""
        controller = ExpressionController()
        controller.set_emotion(Emotion.HAPPY, blend=False)

        # Transition should progress
        controller.update(0.1)

        assert controller.transition_progress > 0.0

    def test_update_completes_transition(self):
        """Test update completes transition eventually."""
        controller = ExpressionController()
        controller.set_emotion(Emotion.HAPPY, blend=False)

        # Many updates should complete transition
        for _ in range(100):
            controller.update(0.05)

        assert controller.transition_progress == 1.0

    def test_update_returns_face_state(self):
        """Test update returns FaceState."""
        controller = ExpressionController()
        result = controller.update(0.1)

        assert isinstance(result, FaceState)

    @patch('random.random', return_value=0.0)
    def test_micro_expressions_trigger(self, mock_random):
        """Test micro expressions can trigger."""
        controller = ExpressionController()
        controller.micro_expressions_enabled = True
        controller.micro_expression_interval = 0.1

        # Update enough to trigger
        for _ in range(20):
            controller.update(0.1)

        # Micro expression should have triggered at some point


class TestBlinkController:
    """Tests for BlinkController class."""

    def test_creation(self):
        """Test controller creation."""
        controller = BlinkController()

        assert controller.blink_duration == 0.15
        assert controller.time_to_next_blink > 0
        assert controller.blink_progress == 1.0
        assert controller.is_blinking is False

    def test_trigger_blink(self):
        """Test triggering a blink."""
        controller = BlinkController()
        controller.trigger_blink()

        assert controller.is_blinking is True
        assert controller.blink_progress == 1.0

    def test_blink_closes_eyes(self):
        """Test blink animation closes eyes."""
        controller = BlinkController()
        controller.trigger_blink()

        # Update to progress blink
        openness = controller.update(0.1)

        # Eyes should be closing (openness decreasing)
        assert openness < 1.0

    def test_blink_completes(self):
        """Test blink animation completes."""
        controller = BlinkController()
        controller.trigger_blink()

        # Update enough to complete blink
        for _ in range(20):
            openness = controller.update(0.02)

        assert controller.is_blinking is False
        assert openness > 0.9  # Eyes should be open again

    def test_automatic_blink(self):
        """Test automatic blinking."""
        controller = BlinkController()
        controller.time_to_next_blink = 0.1

        # Update past the interval
        controller.update(0.2)

        # Should have triggered a blink
        assert controller.is_blinking is True

    def test_update_returns_openness(self):
        """Test update returns valid openness value."""
        controller = BlinkController()

        openness = controller.update(0.1)

        assert 0.0 <= openness <= 1.0


class TestLipSyncBlender:
    """Tests for LipSyncBlender class."""

    def test_creation(self):
        """Test blender creation."""
        blender = LipSyncBlender()

        assert blender.current_shape == 'X'
        assert blender.target_shape == 'X'
        assert blender.blend_progress == 1.0

    def test_mouth_shapes_defined(self):
        """Test all mouth shapes are defined."""
        shapes = ['X', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
        for shape in shapes:
            assert shape in LipSyncBlender.MOUTH_SHAPES
            assert isinstance(LipSyncBlender.MOUTH_SHAPES[shape], MouthState)

    def test_set_shape(self):
        """Test setting target shape."""
        blender = LipSyncBlender()
        blender.set_shape('C')

        assert blender.target_shape == 'C'
        assert blender.blend_progress == 0.0

    def test_set_same_shape_no_change(self):
        """Test setting same shape doesn't reset blend."""
        blender = LipSyncBlender()
        blender.blend_progress = 0.5
        blender.set_shape('X')

        # Should not reset since already at X
        assert blender.blend_progress == 0.5

    def test_update_returns_mouth_state(self):
        """Test update returns MouthState."""
        blender = LipSyncBlender()
        result = blender.update(0.1)

        assert isinstance(result, MouthState)

    def test_update_blends_shapes(self):
        """Test update blends between shapes."""
        blender = LipSyncBlender()
        blender.set_shape('D')  # Wide open

        # Get intermediate state
        result = blender.update(0.03)

        # Should be between X (closed) and D (open)
        assert result.open > 0
        assert result.open < 0.7

    def test_blend_with_expression(self):
        """Test blending with expression."""
        blender = LipSyncBlender()

        lip_sync = MouthState(open=0.5, smile=0.0)
        expression = MouthState(open=0.0, smile=0.8)

        result = blender.blend_with_expression(
            lip_sync, expression, lip_sync_weight=0.8
        )

        # Open should be dominated by lip sync
        assert result.open > 0.3
        # Smile should be partially from expression
        assert result.smile > 0


class TestHeadMotionController:
    """Tests for HeadMotionController class."""

    def test_creation(self):
        """Test controller creation."""
        controller = HeadMotionController()

        assert controller.base_tilt == 0.0
        assert controller.base_nod == 0.0
        assert controller.idle_amplitude > 0

    def test_nod_yes(self):
        """Test queuing a nod."""
        controller = HeadMotionController()
        controller.nod_yes(intensity=0.5, duration=0.3)

        assert len(controller.nod_queue) == 1
        assert controller.nod_queue[0] == (0.5, 0.3)

    def test_shake_no(self):
        """Test queuing a head shake."""
        controller = HeadMotionController()
        controller.shake_no(intensity=0.5, duration=0.3)

        # Shake uses negative intensity
        assert len(controller.nod_queue) == 1
        assert controller.nod_queue[0] == (-0.5, 0.3)

    def test_update_returns_tuple(self):
        """Test update returns (tilt, nod) tuple."""
        controller = HeadMotionController()
        result = controller.update(0.1)

        assert isinstance(result, tuple)
        assert len(result) == 2

    def test_update_idle_motion(self):
        """Test idle motion produces movement."""
        controller = HeadMotionController()

        # Collect motion over time
        values = []
        for _ in range(10):
            tilt, nod = controller.update(0.1)
            values.append((tilt, nod))

        # Should have varying values
        tilts = [v[0] for v in values]
        assert max(tilts) != min(tilts)

    def test_update_processes_nod_queue(self):
        """Test update processes nod queue."""
        controller = HeadMotionController()
        controller.nod_yes(intensity=0.5, duration=0.1)

        # Update to start processing
        controller.update(0.01)

        # Nod should be active
        assert controller.current_nod_duration > 0

        # Queue should be empty after starting
        assert len(controller.nod_queue) == 0


class TestFacialAnimator:
    """Tests for FacialAnimator class."""

    def test_creation(self):
        """Test animator creation."""
        animator = FacialAnimator()

        assert animator.expression is not None
        assert animator.blink is not None
        assert animator.lip_sync is not None
        assert animator.head_motion is not None
        assert animator.is_speaking is False

    def test_set_emotion(self):
        """Test setting emotion."""
        animator = FacialAnimator()
        animator.set_emotion(Emotion.HAPPY)

        assert Emotion.HAPPY in animator.expression.emotion_weights

    def test_blend_emotion(self):
        """Test blending emotion."""
        animator = FacialAnimator()
        animator.set_emotion(Emotion.NEUTRAL)
        animator.blend_emotion(Emotion.SAD, weight=0.3)

        assert Emotion.SAD in animator.expression.emotion_weights

    def test_set_lip_sync_shape(self):
        """Test setting lip sync shape."""
        animator = FacialAnimator()
        animator.set_lip_sync_shape('C')

        assert animator.lip_sync.target_shape == 'C'
        assert animator.is_speaking is True

    def test_set_lip_sync_rest_not_speaking(self):
        """Test rest shapes mark not speaking."""
        animator = FacialAnimator()
        animator.set_lip_sync_shape('X')

        assert animator.is_speaking is False

    def test_nod(self):
        """Test nod method."""
        animator = FacialAnimator()
        animator.nod()

        assert len(animator.head_motion.nod_queue) == 1

    def test_shake(self):
        """Test shake method."""
        animator = FacialAnimator()
        animator.shake()

        assert len(animator.head_motion.nod_queue) == 1

    def test_blink_now(self):
        """Test immediate blink."""
        animator = FacialAnimator()
        animator.blink_now()

        assert animator.blink.is_blinking is True

    def test_update_returns_face_state(self):
        """Test update returns FaceState."""
        animator = FacialAnimator()
        result = animator.update(0.1)

        assert isinstance(result, FaceState)

    def test_update_applies_blink(self):
        """Test update applies blink to eyes."""
        animator = FacialAnimator()
        animator.blink_now()

        # Update to progress blink
        result = animator.update(0.05)

        # Eyes should be affected by blink (less than fully open)
        assert result.left_eye.openness < 1.0
        assert result.right_eye.openness < 1.0

    def test_update_applies_head_motion(self):
        """Test update applies head motion."""
        animator = FacialAnimator()
        animator.nod()

        # Update multiple times to progress nod
        results = []
        for _ in range(10):
            result = animator.update(0.05)
            results.append(result.head_nod)

        # Head nod should vary
        assert max(results) != min(results)

    def test_get_asset_keys_neutral(self):
        """Test getting asset keys for neutral face."""
        animator = FacialAnimator()
        face = FaceState()

        keys = animator.get_asset_keys(face)

        assert keys['eyebrows'] == 'neutral'
        assert keys['eyes'] == 'open'
        assert keys['mouth_expression'] == 'neutral'

    def test_get_asset_keys_raised_brows(self):
        """Test asset keys for raised brows."""
        animator = FacialAnimator()
        face = FaceState(
            left_eyebrow=EyebrowState(height=0.5),
            right_eyebrow=EyebrowState(height=0.5)
        )

        keys = animator.get_asset_keys(face)

        assert keys['eyebrows'] == 'raised'

    def test_get_asset_keys_closed_eyes(self):
        """Test asset keys for closed eyes."""
        animator = FacialAnimator()
        face = FaceState(
            left_eye=EyeState(openness=0.1),
            right_eye=EyeState(openness=0.1)
        )

        keys = animator.get_asset_keys(face)

        assert keys['eyes'] == 'closed'

    def test_get_asset_keys_smiling(self):
        """Test asset keys for smiling."""
        animator = FacialAnimator()
        face = FaceState(
            mouth=MouthState(smile=0.7)
        )

        keys = animator.get_asset_keys(face)

        assert keys['mouth_expression'] == 'smile'


class TestExpressionsIntegration:
    """Integration tests for expression system."""

    def test_emotion_transition_workflow(self):
        """Test complete emotion transition."""
        animator = FacialAnimator()

        # Start neutral
        face1 = animator.update(0.1)
        assert face1.mouth.smile == pytest.approx(0.0, abs=0.1)

        # Transition to happy
        animator.set_emotion(Emotion.HAPPY)

        # Animate transition
        for _ in range(50):
            face = animator.update(0.05)

        # Should have raised eyebrows (happy expression)
        # Note: smile is blended with lip sync, so check eyebrows instead
        assert face.left_eyebrow.height > 0.1
        assert face.right_eyebrow.height > 0.1

    def test_speaking_animation(self):
        """Test speaking with lip sync."""
        animator = FacialAnimator()

        # Simulate speaking sequence
        shapes = ['X', 'B', 'C', 'D', 'B', 'X']
        mouth_opens = []

        for shape in shapes:
            animator.set_lip_sync_shape(shape)
            for _ in range(3):
                face = animator.update(0.033)
                mouth_opens.append(face.mouth.open)

        # Should have variation in mouth opening
        assert max(mouth_opens) > min(mouth_opens)

    def test_combined_animation(self):
        """Test all systems working together."""
        animator = FacialAnimator()

        # Set up various animations
        animator.set_emotion(Emotion.HAPPY)
        animator.set_lip_sync_shape('C')
        animator.nod()

        # Run animation
        results = []
        for _ in range(30):
            face = animator.update(0.033)
            results.append({
                'smile': face.mouth.smile,
                'head_nod': face.head_nod,
                'left_eye': face.left_eye.openness
            })

        # Verify all components animate
        smiles = [r['smile'] for r in results]
        nods = [r['head_nod'] for r in results]

        # Should see progression
        assert len(set(smiles)) > 1
        assert len(set(nods)) > 1
