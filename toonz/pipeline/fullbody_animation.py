#!/usr/bin/env python3
"""Full-body character animation with anatomically correct proportions.

Features:
- 8-head canon proportions for realistic human figure
- Full leg animation with thigh, calf, and foot
- Procedural walking using sine-wave gait cycles
- IK-based foot placement with ground contact
- Weight distribution and balance physics
- Detailed shoe/foot rendering
- Smooth transitions between idle and walking
"""

import math
import random
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict
from PIL import Image, ImageDraw, ImageFilter

from pipeline.animation import (
    Vec2, Spring, Spring2D, PhysicsChain,
    BreathingAnimation, EyeController, Wobble,
    Emotion, FacialAnimator,
    Camera, ShakeType,
    apply_vignette, apply_color_grade,
    QuickRenderer,
)
from pipeline.animation.bones import (
    Skeleton, BoneConstraint, create_humanoid_skeleton,
    solve_two_bone_ik, solve_leg_ik
)
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer


FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"


# =============================================================================
# 8-HEAD PROPORTIONS SYSTEM
# =============================================================================

@dataclass
class BodyProportions:
    """8-head canon proportions for anatomically correct figure.

    Head counts from top:
    - Head 1: Top of head to chin
    - Head 2: Chin to underarm/nipple line
    - Head 3: Underarm to navel
    - Head 4: Navel to crotch (halfway point!)
    - Head 5: Crotch to mid-thigh
    - Head 6: Mid-thigh to below knee
    - Head 7: Below knee to mid-calf
    - Head 8: Mid-calf to feet
    """
    head_size: float = 100.0  # One head unit

    @property
    def total_height(self) -> float:
        return self.head_size * 8

    @property
    def chin_y(self) -> float:
        """Y position of chin (1 head from top)."""
        return self.head_size

    @property
    def shoulder_y(self) -> float:
        """Y position of shoulders (~1.5 heads)."""
        return self.head_size * 1.5

    @property
    def nipple_y(self) -> float:
        """Y position of nipple line (~2 heads)."""
        return self.head_size * 2

    @property
    def navel_y(self) -> float:
        """Y position of navel (~3 heads)."""
        return self.head_size * 3

    @property
    def crotch_y(self) -> float:
        """Y position of crotch (4 heads - halfway)."""
        return self.head_size * 4

    @property
    def knee_y(self) -> float:
        """Y position of knees (~6 heads)."""
        return self.head_size * 6

    @property
    def foot_y(self) -> float:
        """Y position of feet (8 heads - ground)."""
        return self.head_size * 8

    # Widths
    @property
    def shoulder_width(self) -> float:
        """Shoulder width (~2 heads)."""
        return self.head_size * 2

    @property
    def hip_width(self) -> float:
        """Hip width (~1.5 heads)."""
        return self.head_size * 1.5

    @property
    def thigh_length(self) -> float:
        """Thigh length (crotch to knee = 2 heads)."""
        return self.head_size * 2

    @property
    def calf_length(self) -> float:
        """Calf length (knee to ankle = 1.8 heads)."""
        return self.head_size * 1.8

    @property
    def foot_length(self) -> float:
        """Foot length (~1 head)."""
        return self.head_size * 1.0

    @property
    def arm_length(self) -> float:
        """Total arm length (~3.5 heads)."""
        return self.head_size * 3.5

    @property
    def upper_arm_length(self) -> float:
        """Upper arm (shoulder to elbow ~1.5 heads)."""
        return self.head_size * 1.5

    @property
    def forearm_length(self) -> float:
        """Forearm (elbow to wrist ~1.25 heads)."""
        return self.head_size * 1.25


# =============================================================================
# PROCEDURAL WALKING SYSTEM
# =============================================================================

@dataclass
class FootState:
    """State of a single foot during walking."""
    position: Tuple[float, float] = (0, 0)
    grounded: bool = True
    lift_height: float = 0.0
    angle: float = 0.0  # Foot angle
    step_progress: float = 0.0  # 0-1 through current step
    target_position: Tuple[float, float] = (0, 0)


class ProceduralWalk:
    """Procedural walking animation using sine-wave gait cycles.

    Based on research:
    - Each leg follows opposite phase of sine wave
    - Contact -> Push-off -> Swing -> Contact cycle
    - Weight shifts opposite to lifted leg
    - Hips rotate slightly during walk
    """

    def __init__(self, stride_length: float = 80, step_height: float = 40):
        self.stride_length = stride_length
        self.step_height = step_height
        self.walk_speed = 1.2  # Cycles per second (natural walking ~90-110 steps/min)

        # Foot states
        self.left_foot = FootState()
        self.right_foot = FootState()

        # Phase (0 to 2*pi for full gait cycle)
        self.phase = 0.0

        # Walk blend (0 = idle, 1 = full walk)
        # Higher damping for smoother, less bouncy transitions
        self.walk_blend = Spring(stiffness=60, damping=12)
        self._target_blend = 0.0

        # Body dynamics - slightly softer for more natural movement
        self.body_bob = Spring(stiffness=120, damping=14)
        self.hip_sway = Spring(stiffness=80, damping=12)
        self.hip_rotation = Spring(stiffness=100, damping=12)

        # Ground level
        self.ground_y = 0.0

        # Stopping state - completes stride to natural position
        self._stopping = False

    def set_walking(self, walking: bool):
        """Enable/disable walking."""
        self._target_blend = 1.0 if walking else 0.0
        self.walk_blend.set_target(self._target_blend)
        self._stopping = not walking  # Track if we're stopping

    def update(self, dt: float, base_x: float, base_y: float) -> Dict:
        """Update walking animation.

        Returns dict with leg positions, body offsets, etc.
        """
        blend = self.walk_blend.update(dt)

        if blend > 0.01:
            # Advance phase
            self.phase += dt * self.walk_speed * 2 * math.pi
            if self.phase >= 2 * math.pi:
                self.phase -= 2 * math.pi

            # When stopping, try to reach a natural stopping position
            # Natural stops are at phase ≈ 0.3*pi or ≈ 1.3*pi (both feet grounded)
            if self._stopping and blend < 0.3:
                # Find nearest natural stop point
                target_phase = 0.0 if self.phase < math.pi else math.pi
                # Gradually pull phase toward target
                phase_diff = target_phase - self.phase
                if abs(phase_diff) > math.pi:
                    phase_diff = phase_diff - 2 * math.pi * (1 if phase_diff > 0 else -1)
                self.phase += phase_diff * 0.1  # Gradual adjustment

        # Calculate foot positions using improved timing
        # Left foot: offset by 0, right foot: offset by pi
        # Real walking: stance phase ~60%, swing phase ~40%

        left_phase = self.phase
        right_phase = self.phase + math.pi

        # IMPROVED: Horizontal motion matches lift timing
        # At heel strike: foot in front (+0.5)
        # During stance: body moves over foot (foot appears to slide back)
        # At toe-off: foot in back (-0.5)
        # During swing: foot swings forward for next heel strike
        def x_profile(phase):
            """X offset for natural walking gait."""
            t = (phase % (2 * math.pi)) / (2 * math.pi)
            # Stance phase (0-60%): front to back (body passes over planted foot)
            if t < 0.6:
                return 0.5 - (t / 0.6)  # +0.5 to -0.5
            # Swing phase (60-100%): back to front (foot swings forward)
            else:
                swing_t = (t - 0.6) / 0.4  # 0 to 1
                # Ease-out: fast start, slows before landing
                eased = 1 - (1 - swing_t) ** 2
                return -0.5 + eased  # -0.5 to +0.5

        left_x_offset = x_profile(left_phase) * self.stride_length * blend
        right_x_offset = x_profile(right_phase) * self.stride_length * blend

        # Vertical lift with asymmetric timing
        # Feet stay grounded longer (60% stance), quick swing (40%)
        def lift_profile(phase):
            """Asymmetric lift profile - grounded longer, quick swing."""
            # Normalize phase to 0-1
            t = (phase % (2 * math.pi)) / (2 * math.pi)
            # Foot is grounded for first 60% of cycle
            if t < 0.6:
                return 0.0
            # Quick lift during 60-80%
            elif t < 0.8:
                swing_t = (t - 0.6) / 0.2  # 0 to 1 during swing up
                return math.sin(swing_t * math.pi * 0.5) ** 0.8  # Quick up
            # Quick down during 80-100%
            else:
                swing_t = (t - 0.8) / 0.2  # 0 to 1 during swing down
                return math.cos(swing_t * math.pi * 0.5) ** 0.8  # Quick down

        left_lift_raw = lift_profile(left_phase)
        right_lift_raw = lift_profile(right_phase)
        left_lift = left_lift_raw * self.step_height * blend
        right_lift = right_lift_raw * self.step_height * blend

        # Foot angle (toe points up during swing, heel-strike on landing)
        left_toe_angle = left_lift_raw * 0.4 * blend  # More toe lift
        right_toe_angle = right_lift_raw * 0.4 * blend

        # Update foot states
        self.left_foot.position = (base_x + left_x_offset, self.ground_y - left_lift)
        self.left_foot.grounded = left_lift < 2
        self.left_foot.lift_height = left_lift
        self.left_foot.angle = left_toe_angle

        self.right_foot.position = (base_x + right_x_offset, self.ground_y - right_lift)
        self.right_foot.grounded = right_lift < 2
        self.right_foot.lift_height = right_lift
        self.right_foot.angle = right_toe_angle

        # Body dynamics - matches foot phases
        # Body is lowest at heel strikes (phase=0 for left, phase=π for right)
        # Body is highest at mid-stance (between heel strikes)
        def bob_profile(phase):
            """Body drops on heel strikes (2x per cycle), rises during stance."""
            # Simple 2x frequency: lowest at 0 and π, highest at π/2 and 3π/2
            return -math.cos(phase * 2)

        body_bob_offset = bob_profile(self.phase) * 8 * blend  # Slightly reduced for natural look
        self.body_bob.set_target(-body_bob_offset)
        bob = self.body_bob.update(dt)

        # Hip sway (side to side, shifts toward weight-bearing leg)
        # Sway peaks when one leg is in swing phase (60-100% of its cycle)
        # sin(phase) naturally peaks at π/2 and 3π/2, which is mid-swing
        hip_sway_target = math.sin(self.phase) * 12 * blend
        self.hip_sway.set_target(hip_sway_target)
        sway = self.hip_sway.update(dt)

        # Hip rotation (subtle twist during walk)
        hip_rot_target = math.sin(self.phase) * 0.08 * blend
        self.hip_rotation.set_target(hip_rot_target)
        hip_rot = self.hip_rotation.update(dt)

        # Shoulder counter-rotation
        shoulder_rot = -hip_rot * 0.6

        return {
            'left_foot': self.left_foot,
            'right_foot': self.right_foot,
            'body_bob': bob,
            'hip_sway': sway,
            'hip_rotation': hip_rot,
            'shoulder_rotation': shoulder_rot,
            'walk_blend': blend,
            'phase': self.phase,
        }


# =============================================================================
# FULL-BODY CHARACTER
# =============================================================================

@dataclass
class Finger:
    """Individual finger with joints."""
    base_angle: float = 0.0
    mid_angle: float = 0.0
    tip_angle: float = 0.0
    spread: float = 0.0


@dataclass
class Hand:
    """Detailed hand with all fingers."""
    thumb: Finger = field(default_factory=Finger)
    index: Finger = field(default_factory=Finger)
    middle: Finger = field(default_factory=Finger)
    ring: Finger = field(default_factory=Finger)
    pinky: Finger = field(default_factory=Finger)
    wrist_angle: float = 0.0

    def set_pose(self, pose_name: str):
        """Set hand to a predefined pose."""
        if pose_name == "relaxed":
            for f in [self.index, self.middle, self.ring, self.pinky]:
                f.base_angle = 0.15
                f.mid_angle = 0.2
                f.tip_angle = 0.15
            self.thumb.base_angle = 0.3
            self.thumb.mid_angle = 0.1
        elif pose_name == "open":
            for f in [self.thumb, self.index, self.middle, self.ring, self.pinky]:
                f.base_angle = 0.0
                f.mid_angle = 0.0
                f.tip_angle = 0.0


class WeightDistribution:
    """Manages body weight distribution for natural balance.

    During standing: weight shifts between legs
    During walking: weight follows planted foot
    """

    def __init__(self):
        self.left_weight = 0.5  # 0-1, portion of weight on left leg
        self.right_weight = 0.5

        self.hip_offset = Spring2D(stiffness=60, damping=8)
        self.shoulder_tilt = Spring(stiffness=80, damping=9)

        self._shift_timer = 0.0
        self._idle_shift_interval = 3.0

    def update(self, dt: float, walk_state: Dict) -> Dict:
        """Update weight distribution based on walk state."""
        walk_blend = walk_state.get('walk_blend', 0)

        if walk_blend > 0.1:
            # During walk: weight follows planted foot
            left_grounded = walk_state['left_foot'].grounded
            right_grounded = walk_state['right_foot'].grounded

            if left_grounded and not right_grounded:
                self.left_weight = 0.85
                self.right_weight = 0.15
            elif right_grounded and not left_grounded:
                self.left_weight = 0.15
                self.right_weight = 0.85
            else:
                # Both grounded (double support phase)
                self.left_weight = 0.5
                self.right_weight = 0.5
        else:
            # Idle: periodic weight shifts
            self._shift_timer += dt
            if self._shift_timer >= self._idle_shift_interval:
                self._shift_timer = 0.0
                self._idle_shift_interval = random.uniform(2.5, 4.5)

                # Random weight shift
                new_left = random.choice([0.3, 0.5, 0.7])
                self.left_weight = new_left
                self.right_weight = 1.0 - new_left

        # Hip offset based on weight
        weight_diff = self.left_weight - self.right_weight
        hip_target = (weight_diff * 15, abs(weight_diff) * 5)
        self.hip_offset.set_target(hip_target)
        hip = self.hip_offset.update(dt)

        # Shoulder counter-tilt
        self.shoulder_tilt.set_target(-weight_diff * 0.05)
        shoulder = self.shoulder_tilt.update(dt)

        return {
            'left_weight': self.left_weight,
            'right_weight': self.right_weight,
            'hip_offset': hip,
            'shoulder_tilt': shoulder,
        }


class FullBodyCharacter:
    """Complete character with full body, legs, and walking animation.

    Uses 8-head proportions for anatomically correct figure.
    """

    def __init__(self, x: float, y: float, scale: float = 1.0):
        self.base_x = x
        self.base_y = y  # This is the ground level (foot position)
        self.scale = scale

        # 8-head proportions
        self.proportions = BodyProportions(head_size=45 * scale)

        # Calculate body anchor (hips at head 4)
        self.hip_y = y - self.proportions.crotch_y  # Hips above ground

        # Colors with gradient tones
        self.colors = {
            # Skin tones
            'skin_light': (255, 225, 205),
            'skin_mid': (245, 205, 180),
            'skin_shadow': (220, 175, 150),
            'skin_deep': (195, 145, 120),
            # Hair
            'hair_light': (85, 70, 95),
            'hair_mid': (55, 45, 65),
            'hair_dark': (35, 28, 42),
            'hair_highlight': (120, 100, 130),
            # Eyes
            'eye_white': (252, 252, 255),
            'iris_outer': (95, 155, 200),
            'iris_inner': (65, 120, 170),
            'pupil': (18, 22, 32),
            # Lips
            'lip': (210, 135, 140),
            'lip_shadow': (180, 100, 110),
            'blush': (255, 190, 195),
            # Clothing - top
            'top_light': (115, 155, 210),
            'top_mid': (85, 125, 185),
            'top_shadow': (60, 95, 155),
            'top_fold': (50, 80, 135),
            # Clothing - pants
            'pants_light': (75, 85, 100),
            'pants_mid': (55, 65, 80),
            'pants_shadow': (40, 48, 62),
            'pants_fold': (30, 38, 50),
            # Shoes
            'shoe_light': (90, 70, 65),
            'shoe_mid': (65, 50, 45),
            'shoe_shadow': (45, 35, 30),
            'shoe_sole': (25, 22, 20),
        }

        # Animation systems
        self.breathing = BreathingAnimation(rate=13, depth=1.0, variation=0.15)
        self.eyes = EyeController(max_offset=5 * scale, blink_interval=(2.5, 5.5))
        self.wobble = Wobble(frequency=5.0, amplitude=0.04)

        # Walking system
        self.walk = ProceduralWalk(
            stride_length=60 * scale,
            step_height=30 * scale
        )
        self.walk.ground_y = y

        # Weight distribution
        self.weight = WeightDistribution()

        # Physics for hair
        p = self.proportions
        head_y = y - p.total_height + p.head_size * 0.5
        self.hair_strands = [
            PhysicsChain(anchor=(x - 25*scale, head_y - 30*scale), segments=5,
                        segment_length=14*scale, gravity=(0, 100), damping=0.9, stiffness=0.85),
            PhysicsChain(anchor=(x, head_y - 38*scale), segments=6,
                        segment_length=16*scale, gravity=(0, 85), damping=0.88, stiffness=0.82),
            PhysicsChain(anchor=(x + 22*scale, head_y - 32*scale), segments=5,
                        segment_length=13*scale, gravity=(0, 110), damping=0.91, stiffness=0.87),
        ]

        # Side hair
        self.side_hair_left = PhysicsChain(
            anchor=(x - 48*scale, head_y + 15*scale), segments=7,
            segment_length=18*scale, gravity=(0, 75), damping=0.85, stiffness=0.75
        )
        self.side_hair_right = PhysicsChain(
            anchor=(x + 48*scale, head_y + 15*scale), segments=7,
            segment_length=18*scale, gravity=(0, 75), damping=0.85, stiffness=0.75
        )

        # Hands
        self.left_hand = Hand()
        self.right_hand = Hand()
        self.left_hand.set_pose("relaxed")
        self.right_hand.set_pose("relaxed")

        # Position spring for movement
        self.position = Spring2D(stiffness=100, damping=12, initial_position=(x, y))

        # State
        self.prev_pos = (x, y)
        self.velocity = (0, 0)
        self.is_walking = False
        self.walk_direction = 1  # 1 = right, -1 = left
        self.facing = 1  # 1 = facing right, -1 = facing left
        self.view_angle = 0  # 0 = front view, 90 = side view (combined with facing for direction)

    def set_facing(self, direction: int):
        """Set which direction the character faces (1=right, -1=left)."""
        self.facing = 1 if direction >= 0 else -1

    def set_view(self, angle: float):
        """Set the view angle.

        Args:
            angle: 0 = front view (facing camera)
                   90 = side view (profile)
                   Values between 0-90 will interpolate (future feature)
        """
        self.view_angle = max(0, min(90, angle))

    def set_walking(self, walking: bool, direction: int = 1):
        """Enable/disable walking animation.

        Args:
            walking: Whether to walk
            direction: 1 = right, -1 = left (also sets facing direction)
        """
        self.is_walking = walking
        self.walk_direction = direction
        self.facing = 1 if direction >= 0 else -1  # Update facing when walking
        self.walk.set_walking(walking)

    def update(self, dt: float, frame: int, fps: float, time: float = 0, target_pos=None) -> Dict:
        """Update all animation systems."""
        # Position
        if target_pos:
            self.position.set_target(target_pos)
        pos = self.position.update(dt)

        # Velocity for physics
        self.velocity = (pos[0] - self.prev_pos[0], pos[1] - self.prev_pos[1])
        self.prev_pos = pos

        # Update walk first
        walk_state = self.walk.update(dt, pos[0], pos[1])

        # Update weight distribution
        weight_state = self.weight.update(dt, walk_state)

        # Core animation
        breath = self.breathing.update(frame, fps)
        eye_state = self.eyes.update(frame, fps)
        wobble_val = self.wobble.update(dt)

        # Apply velocity to hair
        if abs(self.velocity[0]) > 0.3 or abs(self.velocity[1]) > 0.3:
            force = (-self.velocity[0] * 3, -self.velocity[1] * 2)
            for strand in self.hair_strands:
                strand.apply_force(force)
            self.side_hair_left.apply_force((force[0] * 1.3, force[1]))
            self.side_hair_right.apply_force((force[0] * 1.3, force[1]))

        # Walk adds extra force to hair
        if walk_state['walk_blend'] > 0.1:
            walk_force = (
                -walk_state['hip_sway'] * 0.8,
                walk_state['body_bob'] * 0.5
            )
            for strand in self.hair_strands:
                strand.apply_force(walk_force)

        # Update hair physics
        for strand in self.hair_strands:
            strand.update(dt)
        self.side_hair_left.update(dt)
        self.side_hair_right.update(dt)

        return {
            'position': pos,
            'walk': walk_state,
            'weight': weight_state,
            'breath': breath,
            'eyes': eye_state,
            'wobble': wobble_val,
        }

    def trigger_impact(self, intensity: float = 1.0):
        """Trigger impact reaction."""
        self.wobble.trigger(intensity)
        force = (random.uniform(-20, 20) * intensity, -30 * intensity)
        for strand in self.hair_strands:
            strand.apply_force(force)

    def draw(self, img: Image.Image, face_state, anim_state: Dict, shake=(0, 0)):
        """Render the full character.

        Supports horizontal flipping based on self.facing direction.
        Supports side profile view when view_angle >= 45.
        """
        s = self.scale
        p = self.proportions

        pos = anim_state['position']
        walk = anim_state['walk']
        weight = anim_state['weight']
        breath = anim_state['breath']

        # Calculate character bounding box for flip buffer
        char_width = int(p.shoulder_width * 2.5 + 100 * s)  # Extra padding for arms/hair
        char_height = int(p.total_height + 50 * s)  # Extra padding

        # Create temporary image for character (allows flipping)
        char_img = Image.new('RGBA', (char_width, char_height), (0, 0, 0, 0))
        char_draw = ImageDraw.Draw(char_img)

        # Character is drawn centered horizontally, with feet at bottom
        char_center_x = char_width // 2
        char_ground_y = char_height - int(25 * s)  # Ground position in temp image

        # Calculate offsets for drawing (relative to character center)
        body_bob = walk['body_bob']
        hip_sway = walk['hip_sway']

        # Torso position
        torso_x = char_center_x + hip_sway
        torso_y = char_ground_y - p.crotch_y + body_bob

        # Draw ground shadow on main image (not flipped)
        main_draw = ImageDraw.Draw(img)
        shadow_x = pos[0] + shake[0]
        shadow_y = pos[1] + shake[1]
        self._draw_ground_shadow(main_draw, shadow_x, shadow_y, s, walk)

        # Check if drawing in side profile view
        use_side_view = self.view_angle >= 45

        if use_side_view:
            # SIDE PROFILE VIEW
            # Calculate positions first
            head_y = char_ground_y - p.total_height + p.head_size * 0.5 + body_bob + breath['shoulders'] * 0.5
            shoulder_y = char_ground_y - p.total_height + p.shoulder_y + body_bob + breath['shoulders'] * 2
            neck_y = char_ground_y - p.total_height + p.chin_y + body_bob + breath['shoulders']

            # Draw character parts in side profile (back to front order)
            # 1. Back hair (behind everything)
            self._draw_hair_side_back(char_draw, torso_x, head_y, s, walk)

            # 2. Far arm (behind body, only visible when swinging forward)
            self._draw_far_arm_side(char_draw, torso_x, shoulder_y, s, breath, walk)

            # 3. Legs (side view)
            self._draw_legs_side(char_draw, char_center_x, char_ground_y, s, walk, weight)

            # 4. Body/torso (side view)
            self._draw_body_side(char_draw, torso_x, torso_y, s, breath, walk, weight)

            # 5. Near arm (in front of body)
            self._draw_arms_side(char_draw, torso_x, shoulder_y, s, breath, walk)

            # 6. Neck (side view)
            self._draw_neck_side(char_draw, torso_x, neck_y, s, breath)

            # 7. Head (side view)
            self._draw_head_side(char_draw, torso_x, head_y, s, face_state, anim_state)

            # 8. Front hair/bangs (in front of face)
            self._draw_hair_side_front(char_draw, torso_x, head_y, s)
        else:
            # FRONT VIEW
            # Draw character parts to temp image
            # Back hair
            self._draw_back_hair(char_draw, torso_x, char_ground_y, s, (0, 0), walk)

            # Legs
            self._draw_legs(char_draw, char_center_x, char_ground_y, s, walk, weight, char_center_x)

            # Body/torso
            self._draw_body(char_draw, torso_x, torso_y, s, breath, walk, weight)

            # Arms
            shoulder_y = char_ground_y - p.total_height + p.shoulder_y + body_bob + breath['shoulders'] * 2
            self._draw_arms(char_draw, torso_x, shoulder_y, s, breath, walk)

            # Neck
            neck_y = char_ground_y - p.total_height + p.chin_y + body_bob + breath['shoulders']
            self._draw_neck(char_draw, torso_x, neck_y, s, breath)

            # Head
            head_y = char_ground_y - p.total_height + p.head_size * 0.5 + body_bob + breath['shoulders'] * 0.5
            self._draw_head(char_draw, torso_x, head_y, s, face_state, anim_state)

            # Front hair
            self._draw_front_hair(char_draw, torso_x, head_y, s, (0, 0))

        # Flip horizontally if facing left
        if self.facing < 0:
            char_img = char_img.transpose(Image.FLIP_LEFT_RIGHT)

        # Calculate paste position on main image
        paste_x = int(pos[0] + shake[0] - char_width // 2)
        paste_y = int(pos[1] + shake[1] - char_height + 25 * s)

        # Composite character onto main image
        img.paste(char_img, (paste_x, paste_y), char_img)

        # Side hair (physics-based, needs special handling for flip)
        # Only draw in front view - side view has integrated hair
        if not use_side_view:
            self._draw_side_hair_flipped(img, shake, pos)

    def _draw_ground_shadow(self, draw, x, y, s, walk):
        """Dynamic ground shadow that responds to walking."""
        # Shadow stretches/shrinks based on movement
        walk_blend = walk['walk_blend']
        shadow_stretch = 1.0 + walk_blend * 0.2

        for i in range(6):
            size = (65 - i * 7) * s * shadow_stretch
            alpha = 8 + i * 4
            offset_y = i * 1.5

            # Shadow moves slightly with body
            shadow_x = x + walk['hip_sway'] * 0.3

            draw.ellipse([
                shadow_x - size, y - size * 0.18 + offset_y,
                shadow_x + size, y + size * 0.18 + offset_y
            ], fill=(0, 0, 0, alpha))

    def _draw_legs(self, draw, base_x, base_y, s, walk, weight, original_x):
        """Draw detailed legs with thigh, calf, and foot using pole vector IK."""
        p = self.proportions

        # Get weight-based offsets
        hip_weight_offset = weight.get('hip_offset', (0, 0))

        hip_y = base_y - p.crotch_y + walk['body_bob'] + hip_weight_offset[1]
        hip_rotation = walk['hip_rotation']
        hip_sway = walk['hip_sway']

        for side, foot_state in [(-1, walk['left_foot']), (1, walk['right_foot'])]:
            # Hip position: base has shake, add sway + weight shift
            hip_x = base_x + side * (p.hip_width * 0.35) + hip_sway + hip_weight_offset[0]

            # Get foot X offset (foot_state.position was computed with original_x)
            # Add shake (from base_x) but NOT sway (foot stays planted)
            foot_x_offset = foot_state.position[0] - original_x
            foot_x = base_x + foot_x_offset  # Now has shake but not sway
            foot_y = base_y - foot_state.lift_height

            # Use improved pole vector IK solver
            # This ensures knees always bend forward consistently
            thigh_len = p.thigh_length
            calf_len = p.calf_length

            # Solve leg IK with pole vector (knee bends forward)
            (knee_x, knee_y), thigh_angle, calf_angle = solve_leg_ik(
                hip_pos=(hip_x, hip_y),
                foot_target=(foot_x, foot_y),
                thigh_length=thigh_len,
                calf_length=calf_len,
                knee_forward=True  # Natural walking - knee bends forward
            )

            # Calculate actual foot position (may be clamped by IK)
            actual_foot_x = knee_x + math.cos(calf_angle) * calf_len
            actual_foot_y = knee_y + math.sin(calf_angle) * calf_len

            # Calculate knee bend angle for details
            knee_bend_angle = abs(thigh_angle - calf_angle)
            cos_knee = math.cos(knee_bend_angle) if knee_bend_angle < math.pi else -1

            # Draw thigh
            self._draw_leg_segment(
                draw, hip_x, hip_y, knee_x, knee_y,
                32 * s, 24 * s,  # Thigh is thicker
                self.colors['pants_light'], self.colors['pants_mid'], self.colors['pants_shadow']
            )

            # Add cloth wrinkles on thigh
            self._draw_cloth_wrinkles(draw, hip_x, hip_y, knee_x, knee_y, s, side,
                                      walk['walk_blend'], walk['phase'])

            # Draw calf with muscle definition
            # FIXED: Use actual foot position after IK clamping
            ankle_x = actual_foot_x
            ankle_y = actual_foot_y - 8 * s  # Ankle slightly above foot

            self._draw_leg_segment(
                draw, knee_x, knee_y, ankle_x, ankle_y,
                22 * s, 14 * s,  # Calf tapers more
                self.colors['pants_light'], self.colors['pants_mid'], self.colors['pants_shadow'],
                is_calf=True, muscle_bulge=8 * s  # Add calf muscle bulge
            )

            # Add detailed knee with kneecap
            # Use the knee bend angle we calculated earlier
            self._draw_knee_detail(draw, knee_x, knee_y, s, knee_bend_angle, side)

            # Draw foot/shoe - use actual clamped position
            self._draw_foot(draw, ankle_x, ankle_y, actual_foot_y, s, side, foot_state)

    def _draw_leg_segment(self, draw, x1, y1, x2, y2, width1, width2, light, mid, shadow,
                          is_calf: bool = False, muscle_bulge: float = 0.0):
        """Draw a leg segment with proper cylindrical shape and muscle definition."""
        dx, dy = x2 - x1, y2 - y1
        length = math.sqrt(dx * dx + dy * dy)
        if length == 0:
            return

        # Normal vector (perpendicular to leg direction)
        nx, ny = -dy / length, dx / length

        # Create polygon points for cylindrical shape with taper
        # Multiple points along the length for smoother shape
        steps = 8
        shadow_points = []
        mid_points = []
        highlight_points = []

        for i in range(steps + 1):
            t = i / steps
            # Position along leg
            px = x1 + dx * t
            py = y1 + dy * t

            # Width at this point (interpolate with taper)
            w = width1 + (width2 - width1) * t

            # Add muscle bulge for calf (peaks at ~40% down the segment)
            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5  # Peak at 0.4
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge

            # Outer edge (shadow side)
            shadow_points.append((px - nx * w * 0.5, py - ny * w * 0.5))

        # Reverse path for other side
        for i in range(steps, -1, -1):
            t = i / steps
            px = x1 + dx * t
            py = y1 + dy * t
            w = width1 + (width2 - width1) * t

            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge

            shadow_points.append((px + nx * w * 0.5, py + ny * w * 0.5))

        # Draw the main shape
        draw.polygon(shadow_points, fill=shadow)

        # Mid-tone layer (slightly inset)
        mid_offset = 2
        mid_points = []
        for i in range(steps + 1):
            t = i / steps
            px = x1 + dx * t
            py = y1 + dy * t
            w = (width1 + (width2 - width1) * t) * 0.88

            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge * 0.85

            mid_points.append((px - nx * w * 0.45 + mid_offset, py - ny * w * 0.45))

        for i in range(steps, -1, -1):
            t = i / steps
            px = x1 + dx * t
            py = y1 + dy * t
            w = (width1 + (width2 - width1) * t) * 0.88

            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge * 0.85

            mid_points.append((px + nx * w * 0.45 + mid_offset, py + ny * w * 0.45))

        draw.polygon(mid_points, fill=mid)

        # Highlight stripe along the light side
        highlight_offset = 4
        highlight_points = []
        for i in range(steps + 1):
            t = i / steps
            px = x1 + dx * t
            py = y1 + dy * t
            w = (width1 + (width2 - width1) * t) * 0.35

            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge * 0.3

            highlight_points.append((
                px + nx * w * 0.3 + highlight_offset,
                py + ny * w * 0.3
            ))

        for i in range(steps, -1, -1):
            t = i / steps
            px = x1 + dx * t
            py = y1 + dy * t
            w = (width1 + (width2 - width1) * t) * 0.2

            if is_calf and muscle_bulge > 0:
                bulge_t = 1 - abs(t - 0.4) * 2.5
                bulge_t = max(0, bulge_t) ** 1.5
                w += bulge_t * muscle_bulge * 0.15

            highlight_points.append((
                px + nx * w * 0.5 + highlight_offset * 1.5,
                py + ny * w * 0.5
            ))

        draw.polygon(highlight_points, fill=light)

        # Joint circle at the end (knee/ankle)
        joint_r = width2 * 0.55
        draw.ellipse([
            x2 - joint_r, y2 - joint_r,
            x2 + joint_r, y2 + joint_r
        ], fill=mid)

        # Joint highlight
        joint_hr = joint_r * 0.5
        draw.ellipse([
            x2 - joint_hr + 2, y2 - joint_hr - 1,
            x2 + joint_hr + 2, y2 + joint_hr - 1
        ], fill=light)

    def _draw_cloth_wrinkles(self, draw, hip_x, hip_y, knee_x, knee_y, s, side,
                              walk_blend: float, walk_phase: float):
        """Draw cloth wrinkles and folds on pants during movement."""
        # Calculate leg direction
        dx, dy = knee_x - hip_x, knee_y - hip_y
        length = math.sqrt(dx * dx + dy * dy)
        if length == 0:
            return

        # Normal perpendicular to leg
        nx, ny = -dy / length, dx / length

        # Wrinkle intensity based on walking
        wrinkle_intensity = 0.3 + walk_blend * 0.7

        # Phase offset for this leg
        phase_offset = 0 if side < 0 else math.pi
        leg_phase = walk_phase + phase_offset

        # Create dynamic wrinkles that move with walking
        wrinkle_color = (*self.colors['pants_fold'], int(80 * wrinkle_intensity))
        highlight_color = (*self.colors['pants_light'], int(50 * wrinkle_intensity))

        # Wrinkles near hip (always present, more pronounced when walking)
        for i in range(3):
            t = 0.1 + i * 0.08
            # Position along thigh
            wx = hip_x + dx * t
            wy = hip_y + dy * t

            # Wrinkle curves across the fabric - draw as lines instead of arcs
            curve_offset = math.sin(leg_phase + i * 0.5) * 3 * s * walk_blend
            w_width = (18 - i * 3) * s

            # Dark fold line - use bezier-like curve with line segments
            fold_points = []
            for j in range(5):
                ct = j / 4
                # Curve across the leg
                px = wx + nx * w_width * (ct - 0.5) * 2 + curve_offset
                py = wy + ny * w_width * (ct - 0.5) * 2
                # Add curve to the fold
                py += math.sin(ct * math.pi) * 4 * s
                fold_points.append((px, py))

            if len(fold_points) >= 2:
                draw.line(fold_points, fill=wrinkle_color, width=max(1, int(1.5 * s)))

                # Light highlight above fold
                highlight_points = [(p[0] + 2, p[1] - 2 * s) for p in fold_points]
                draw.line(highlight_points, fill=highlight_color, width=max(1, int(1 * s)))

        # Knee area wrinkles (more when knee is bent)
        knee_bend = abs(math.atan2(dy, dx) - math.pi / 2)
        bend_amount = knee_bend * 0.3

        if bend_amount > 0.1:
            for i in range(2):
                t = 0.85 + i * 0.06
                wx = hip_x + dx * t
                wy = hip_y + dy * t

                w_width = (12 - i * 2) * s
                fold_depth = int(40 + bend_amount * 60)

                # Draw knee wrinkles as curved lines
                knee_fold = []
                for j in range(5):
                    ct = j / 4
                    px = wx + nx * w_width * (ct - 0.5) * 2
                    py = wy + ny * w_width * (ct - 0.5) * 2
                    py -= math.sin(ct * math.pi) * 3 * s
                    knee_fold.append((px, py))

                if len(knee_fold) >= 2:
                    draw.line(knee_fold, fill=(*self.colors['pants_fold'], fold_depth),
                             width=max(1, int(1.5 * s)))

        # Side seam line
        seam_color = (*self.colors['pants_shadow'], 60)
        seam_points = [
            (hip_x + nx * 14 * s, hip_y + ny * 14 * s),
            (hip_x + dx * 0.5 + nx * 10 * s, hip_y + dy * 0.5 + ny * 10 * s),
            (knee_x + nx * 8 * s, knee_y + ny * 8 * s),
        ]
        draw.line(seam_points, fill=seam_color, width=max(1, int(1 * s)))

    def _draw_knee_detail(self, draw, knee_x, knee_y, s, knee_bend: float, side: int):
        """Draw detailed knee with kneecap and joint articulation."""
        # Kneecap (patella) - more visible when leg is extended
        knee_visibility = 1.0 - min(1.0, knee_bend * 0.8)

        if knee_visibility > 0.2:
            # Kneecap shape
            kneecap_w = max(1, 10 * s * knee_visibility)
            kneecap_h = max(1, 12 * s * knee_visibility)

            # Position slightly forward of knee joint
            kneecap_x = knee_x + side * 2 * s
            kneecap_y = knee_y - 2 * s

            # Kneecap outline
            draw.ellipse([
                kneecap_x - kneecap_w, kneecap_y - kneecap_h,
                kneecap_x + kneecap_w, kneecap_y + kneecap_h
            ], fill=self.colors['pants_mid'])

            # Kneecap highlight
            highlight_w = max(1, kneecap_w * 0.6)
            highlight_h = max(1, kneecap_h * 0.6)
            draw.ellipse([
                kneecap_x - highlight_w + 2, kneecap_y - highlight_h - 1,
                kneecap_x + highlight_w + 2, kneecap_y + highlight_h - 1
            ], fill=self.colors['pants_light'])

        # Knee crease when bent
        if knee_bend > 0.3:
            crease_intensity = min(1.0, (knee_bend - 0.3) * 2)
            crease_color = (*self.colors['pants_shadow'], int(100 * crease_intensity))

            # Horizontal crease behind knee - draw as curved line
            crease_w = 8 * s
            crease_points = []
            for i in range(5):
                t = i / 4
                px = knee_x + crease_w * (t - 0.5) * 2
                py = knee_y + math.sin(t * math.pi) * 4 * s
                crease_points.append((px, py))

            if len(crease_points) >= 2:
                draw.line(crease_points, fill=crease_color,
                         width=max(1, int(2 * s * crease_intensity)))

    def _draw_foot(self, draw, ankle_x, ankle_y, ground_y, s, side, foot_state: FootState):
        """Draw detailed foot/shoe with laces, stitching, and 3D shading."""
        p = self.proportions

        # Foot angle (toe up during swing) - both feet point forward
        angle = foot_state.angle  # Removed * side - angle is always in walk direction

        # Shoe dimensions
        shoe_length = p.foot_length * 0.75
        shoe_height = 20 * s

        # Shoe rotates around ankle
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)

        # Key positions - both feet point forward (positive X direction)
        # Heel is behind ankle, toe is in front
        heel_x = ankle_x - shoe_length * 0.35 * cos_a
        heel_y = ankle_y + shoe_height * 0.35
        toe_x = ankle_x + shoe_length * 0.65 * cos_a
        toe_y = ground_y - 4 * s + sin_a * shoe_length * 0.5
        mid_x = (heel_x + toe_x) / 2
        mid_y = (heel_y + toe_y) / 2

        # ========== SOLE ==========
        # Thick rubber sole with tread
        sole_thickness = 6 * s
        sole_points = [
            (heel_x - 14 * s * side, heel_y + sole_thickness),
            (heel_x - 10 * s * side, ankle_y + shoe_height + 2 * s),
            (toe_x - 8 * s * side, toe_y + 10 * s),
            (toe_x + 12 * s * side, toe_y + 5 * s),
            (toe_x + 10 * s * side, toe_y + 2 * s),
            (heel_x + 8 * s * side, ankle_y + shoe_height - 2 * s),
        ]
        draw.polygon(sole_points, fill=self.colors['shoe_sole'])

        # Sole edge highlight
        draw.line([
            (heel_x - 14 * s * side, heel_y + sole_thickness),
            (toe_x + 12 * s * side, toe_y + 5 * s),
        ], fill=(35, 30, 28), width=max(1, int(2 * s)))

        # Midsole (white stripe)
        midsole_points = [
            (heel_x - 12 * s * side, heel_y + 2 * s),
            (heel_x - 8 * s * side, ankle_y + shoe_height - 4 * s),
            (toe_x - 6 * s * side, toe_y + 6 * s),
            (toe_x + 10 * s * side, toe_y + 2 * s),
        ]
        draw.line(midsole_points, fill=(200, 200, 205), width=max(1, int(3 * s)))

        # ========== SHOE BODY ==========
        # Main upper
        upper_points = [
            (heel_x - 12 * s * side, heel_y - 2 * s),
            (ankle_x - 8 * s * side, ankle_y - 8 * s),  # Ankle collar
            (ankle_x + 5 * s * side, ankle_y - 6 * s),
            (ankle_x + 12 * s * side, ankle_y - 2 * s),
            (toe_x + 6 * s * side, toe_y - 4 * s),
            (toe_x + 10 * s * side, toe_y),
            (toe_x + 8 * s * side, toe_y + 4 * s),
            (heel_x + 6 * s * side, ankle_y + shoe_height - 5 * s),
            (heel_x - 8 * s * side, heel_y + 3 * s),
        ]
        draw.polygon(upper_points, fill=self.colors['shoe_mid'])

        # Shadow side
        shadow_points = [
            (heel_x - 12 * s * side, heel_y - 2 * s),
            (heel_x - 8 * s * side, heel_y + 3 * s),
            (heel_x + 6 * s * side, ankle_y + shoe_height - 5 * s),
            (mid_x + 5 * s * side, mid_y + 5 * s),
            (ankle_x - 5 * s * side, ankle_y + 8 * s),
            (ankle_x - 8 * s * side, ankle_y - 2 * s),
        ]
        draw.polygon(shadow_points, fill=self.colors['shoe_shadow'])

        # Highlight side
        highlight_points = [
            (ankle_x + 3 * s * side, ankle_y - 4 * s),
            (ankle_x + 12 * s * side, ankle_y),
            (toe_x + 4 * s * side, toe_y - 5 * s),
            (toe_x + 8 * s * side, toe_y - 2 * s),
            (mid_x + 8 * s * side, mid_y - 3 * s),
        ]
        draw.polygon(highlight_points, fill=self.colors['shoe_light'])

        # ========== TOE CAP ==========
        toe_cap_points = [
            (toe_x - 5 * s * side, toe_y - 6 * s),
            (toe_x + 6 * s * side, toe_y - 4 * s),
            (toe_x + 10 * s * side, toe_y),
            (toe_x + 8 * s * side, toe_y + 4 * s),
            (toe_x - 2 * s * side, toe_y + 2 * s),
        ]
        draw.polygon(toe_cap_points, fill=(55, 42, 38))  # Darker toe cap

        # Toe cap stitching - draw as curved line to avoid arc coordinate issues
        stitch_color = (120, 100, 85)
        stitch_points = []
        for i in range(7):
            t = i / 6
            # Arc around toe cap
            angle = math.pi * (0.2 + t * 0.6) if side > 0 else math.pi * (0.8 - t * 0.6)
            sx = toe_x + math.cos(angle) * 10 * s
            sy = toe_y - 2 * s + math.sin(angle) * 6 * s
            stitch_points.append((sx, sy))
        if len(stitch_points) >= 2:
            draw.line(stitch_points, fill=stitch_color, width=max(1, int(1.5 * s)))

        # ========== TONGUE ==========
        tongue_points = [
            (ankle_x - 6 * s * side, ankle_y - 10 * s),
            (ankle_x + 2 * s * side, ankle_y - 12 * s),
            (ankle_x + 8 * s * side, ankle_y - 8 * s),
            (ankle_x + 10 * s * side, ankle_y + 2 * s),
            (ankle_x - 2 * s * side, ankle_y + 5 * s),
            (ankle_x - 8 * s * side, ankle_y - 2 * s),
        ]
        draw.polygon(tongue_points, fill=self.colors['shoe_mid'])

        # Tongue highlight
        draw.polygon([
            (ankle_x - 4 * s * side, ankle_y - 8 * s),
            (ankle_x + 4 * s * side, ankle_y - 10 * s),
            (ankle_x + 6 * s * side, ankle_y - 4 * s),
            (ankle_x - 2 * s * side, ankle_y - 2 * s),
        ], fill=self.colors['shoe_light'])

        # ========== LACES ==========
        lace_color = (240, 240, 245)
        lace_shadow = (180, 180, 185)
        num_laces = 4

        for i in range(num_laces):
            t = (i + 0.5) / num_laces
            lace_y = ankle_y - 6 * s + t * 14 * s
            lace_x_left = ankle_x - 5 * s * side + t * 3 * s * side
            lace_x_right = ankle_x + 5 * s * side + t * 2 * s * side

            # Lace crossing
            draw.line([
                (lace_x_left, lace_y - 1 * s),
                (lace_x_right, lace_y + 1 * s),
            ], fill=lace_shadow, width=max(1, int(2 * s)))
            draw.line([
                (lace_x_left, lace_y),
                (lace_x_right, lace_y + 2 * s),
            ], fill=lace_color, width=max(1, int(1.5 * s)))

            # Eyelet holes
            eyelet_r = 1.5 * s
            for ex in [lace_x_left - 2 * s * side, lace_x_right + 2 * s * side]:
                draw.ellipse([
                    ex - eyelet_r, lace_y - eyelet_r,
                    ex + eyelet_r, lace_y + eyelet_r
                ], fill=(50, 45, 42), outline=(70, 65, 60))

        # ========== ANKLE COLLAR ==========
        collar_points = [
            (heel_x - 8 * s * side, heel_y - 8 * s),
            (ankle_x - 10 * s * side, ankle_y - 12 * s),
            (ankle_x, ankle_y - 14 * s),
            (ankle_x + 8 * s * side, ankle_y - 10 * s),
            (heel_x + 4 * s * side, heel_y - 5 * s),
        ]
        draw.line(collar_points, fill=(45, 38, 35), width=max(1, int(3 * s)))

        # Collar padding
        draw.line([
            (heel_x - 6 * s * side, heel_y - 6 * s),
            (ankle_x - 8 * s * side, ankle_y - 10 * s),
        ], fill=self.colors['shoe_light'], width=max(1, int(2 * s)))

    def _draw_body(self, draw, x, y, s, breath, walk, weight):
        """Draw torso with clothing.

        Note: y parameter is the CROTCH position. Torso is drawn ABOVE this point.
        """
        p = self.proportions

        chest_expand = 1.0 + breath['chest'] * 0.012
        hip_rotation = walk['hip_rotation']

        # Torso dimensions - full height from shoulders to crotch
        # y is at crotch level, so torso extends upward from there
        torso_w = p.shoulder_width * 0.45 * chest_expand
        torso_h = p.crotch_y - p.shoulder_y  # Full torso height (about 2.5 heads)

        # Hip area (pants top) - at crotch level (y)
        hip_w = p.hip_width * 0.45
        hip_h = 35 * s

        # Draw pants waistband - centered around crotch (y)
        draw.ellipse([
            x - hip_w, y - hip_h * 0.4,
            x + hip_w, y + hip_h * 0.6
        ], fill=self.colors['pants_shadow'])

        draw.ellipse([
            x - hip_w * 0.95, y - hip_h * 0.35,
            x + hip_w * 0.9, y + hip_h * 0.55
        ], fill=self.colors['pants_mid'])

        # Draw shirt/top - from shoulder level down to just above crotch
        # Top of shirt at y - torso_h (shoulder level)
        # Bottom of shirt overlaps waistband slightly
        draw.ellipse([
            x - torso_w, y - torso_h * 0.95,
            x + torso_w, y + torso_h * 0.08
        ], fill=self.colors['top_shadow'])

        draw.ellipse([
            x - torso_w * 0.95, y - torso_h * 0.92,
            x + torso_w * 0.88, y + torso_h * 0.05
        ], fill=self.colors['top_mid'])

        draw.ellipse([
            x - torso_w * 0.8, y - torso_h * 0.85,
            x + torso_w * 0.6, y - torso_h * 0.2
        ], fill=self.colors['top_light'])

        # Collar - near top of torso (shoulder level)
        collar_y = y - torso_h * 0.88
        draw.arc([
            x - 28 * s, collar_y - 12 * s,
            x + 28 * s, collar_y + 18 * s
        ], 0, 180, fill=self.colors['top_shadow'], width=int(4 * s))

        # Center fold line
        draw.line([
            x, y - torso_h * 0.82,
            x + 3 * s, y - torso_h * 0.1
        ], fill=(*self.colors['top_fold'], 70), width=int(2 * s))

    def _draw_neck(self, draw, x, y, s, breath):
        """Draw neck."""
        neck_h = 25 * s

        draw.ellipse([
            x - 16 * s, y - neck_h,
            x + 16 * s, y + 5 * s
        ], fill=self.colors['skin_shadow'])

        draw.ellipse([
            x - 14 * s, y - neck_h + 2 * s,
            x + 12 * s, y + 2 * s
        ], fill=self.colors['skin_mid'])

        draw.ellipse([
            x - 10 * s, y - neck_h + 3 * s,
            x + 6 * s, y - 5 * s
        ], fill=self.colors['skin_light'])

    def _draw_arms(self, draw, x, y, s, breath, walk):
        """Draw arms with natural swing during walk."""
        p = self.proportions

        shoulder_rot = walk['shoulder_rotation']
        walk_blend = walk['walk_blend']

        for side in [-1, 1]:
            shoulder_x = x + side * p.shoulder_width * 0.4
            shoulder_y = y

            # Arm swing during walk (opposite to same-side leg = matches contra-lateral leg)
            # Increased magnitude for more visible swing (~35 degrees max)
            arm_swing = math.sin(walk['phase'] + math.pi * (1 if side == 1 else 0)) * 0.6 * walk_blend

            # Upper arm angle (pi/2 = hanging down, less = forward, more = backward)
            # arm_swing positive = backward swing, negative = forward swing
            upper_angle = math.pi / 2 + side * 0.25 + arm_swing
            upper_len = p.upper_arm_length

            elbow_x = shoulder_x + math.cos(upper_angle) * upper_len
            elbow_y = shoulder_y + math.sin(upper_angle) * upper_len

            # Lower arm - natural elbow behavior:
            # Forward swing (arm_swing < 0): elbow bends more
            # Backward swing (arm_swing > 0): elbow straightens
            elbow_bend = 0.35 - arm_swing * 0.3  # Opposite of swing direction
            lower_angle = upper_angle + elbow_bend
            lower_len = p.forearm_length

            wrist_x = elbow_x + math.cos(lower_angle) * lower_len
            wrist_y = elbow_y + math.sin(lower_angle) * lower_len

            # Draw upper arm
            self._draw_limb_segment(
                draw, shoulder_x, shoulder_y, elbow_x, elbow_y,
                20 * s, 16 * s,
                self.colors['skin_light'], self.colors['skin_mid'], self.colors['skin_shadow']
            )

            # Draw lower arm
            self._draw_limb_segment(
                draw, elbow_x, elbow_y, wrist_x, wrist_y,
                16 * s, 12 * s,
                self.colors['skin_light'], self.colors['skin_mid'], self.colors['skin_shadow']
            )

            # Hand
            hand = self.right_hand if side == 1 else self.left_hand
            self._draw_hand(draw, wrist_x, wrist_y, s, side, hand)

    def _draw_limb_segment(self, draw, x1, y1, x2, y2, width1, width2, light, mid, shadow):
        """Draw limb with gradient shading."""
        dx, dy = x2 - x1, y2 - y1
        length = math.sqrt(dx * dx + dy * dy)
        if length == 0:
            return
        nx, ny = -dy / length, dx / length

        draw.line([x1, y1, x2, y2], fill=shadow, width=int(width1))

        offset = 2
        draw.line([
            x1 + nx * offset, y1 + ny * offset,
            x2 + nx * offset, y2 + ny * offset
        ], fill=mid, width=int(width1 * 0.85))

        draw.line([
            x1 + nx * offset * 2, y1 + ny * offset * 2,
            x2 + nx * offset * 2, y2 + ny * offset * 2
        ], fill=light, width=int(width1 * 0.5))

        # Joints
        draw.ellipse([x1 - width1/2, y1 - width1/2, x1 + width1/2, y1 + width1/2], fill=mid)
        draw.ellipse([x2 - width2/2, y2 - width2/2, x2 + width2/2, y2 + width2/2], fill=mid)

    def _draw_hand(self, draw, x, y, s, side, hand: Hand):
        """Draw simplified hand."""
        palm_w = 14 * s
        palm_h = 16 * s

        draw.ellipse([x - palm_w, y - palm_h, x + palm_w, y + palm_h], fill=self.colors['skin_mid'])
        draw.ellipse([x - palm_w * 0.7, y - palm_h * 0.8, x + palm_w * 0.5, y + palm_h * 0.5],
                    fill=self.colors['skin_light'])

        # Simplified fingers
        for i, (angle_off, length_mult) in enumerate([(-0.3, 0.9), (-0.1, 1.0), (0.1, 1.0), (0.3, 0.85)]):
            finger_angle = -math.pi / 2 + angle_off * side
            finger_len = 18 * s * length_mult

            fx = x + math.cos(finger_angle) * palm_h * 0.3
            fy = y + math.sin(finger_angle) * palm_h * 0.3

            end_x = fx + math.cos(finger_angle) * finger_len
            end_y = fy + math.sin(finger_angle) * finger_len

            draw.line([fx, fy, end_x, end_y], fill=self.colors['skin_mid'], width=int(5 * s))
            draw.ellipse([end_x - 3*s, end_y - 3*s, end_x + 3*s, end_y + 3*s], fill=self.colors['skin_light'])

    def _draw_head(self, draw, x, y, s, face, anim_state):
        """Draw head with features."""
        p = self.proportions

        head_w = p.head_size * 0.62
        head_h = p.head_size * 0.68

        # Head shape
        draw.ellipse([x - head_w, y - head_h * 0.9, x + head_w, y + head_h], fill=self.colors['skin_shadow'])
        draw.ellipse([x - head_w * 0.97, y - head_h * 0.92, x + head_w * 0.95, y + head_h * 0.97],
                    fill=self.colors['skin_mid'])
        draw.ellipse([x - head_w * 0.75, y - head_h * 0.85, x + head_w * 0.6, y + head_h * 0.3],
                    fill=self.colors['skin_light'])

        # Eyes with proper eyelids
        eye_state = anim_state['eyes']
        blink = eye_state['blink']

        for side in [-1, 1]:
            eye_x = x + side * 22 * s + eye_state['left' if side == -1 else 'right'][0]
            eye_y = y - 5 * s + eye_state['left' if side == -1 else 'right'][1]

            eye_w = 16 * s
            eye_h_full = 12 * s  # Full open height
            eye_h = max(1 * s, eye_h_full * (1 - blink))

            # Eye white (visible area between eyelids)
            if eye_h > 1 * s:
                draw.ellipse([eye_x - eye_w, eye_y - eye_h, eye_x + eye_w, eye_y + eye_h],
                            fill=self.colors['eye_white'])

                if (1 - blink) > 0.15:
                    # Iris
                    iris_r = 10 * s * min(1.0, (1 - blink) + 0.1)
                    draw.ellipse([eye_x - iris_r, eye_y - iris_r, eye_x + iris_r, eye_y + iris_r],
                                fill=self.colors['iris_outer'])

                    # Pupil
                    pupil_r = 5 * s
                    draw.ellipse([eye_x - pupil_r, eye_y - pupil_r, eye_x + pupil_r, eye_y + pupil_r],
                                fill=self.colors['pupil'])

                    # Highlight
                    draw.ellipse([eye_x - 6*s, eye_y - 6*s, eye_x - 2*s, eye_y - 2*s], fill=(255, 255, 255))

            # Upper eyelid - skin colored crease above eye
            upper_lid_y = eye_y - eye_h_full + blink * eye_h_full * 0.8
            draw.arc([eye_x - eye_w * 1.1, upper_lid_y - 3 * s,
                     eye_x + eye_w * 1.1, upper_lid_y + eye_h_full + 3 * s],
                    200, 340, fill=self.colors['skin_shadow'], width=int(2 * s))

            # Lower eyelid line (subtle)
            lower_lid_y = eye_y + eye_h_full - blink * eye_h_full * 0.6
            draw.arc([eye_x - eye_w * 0.9, lower_lid_y - eye_h_full,
                     eye_x + eye_w * 0.9, lower_lid_y + 2 * s],
                    20, 160, fill=self.colors['skin_shadow'], width=int(1.5 * s))

            # Eyelashes on upper lid
            if blink < 0.6:
                for i in range(4):
                    lash_x = eye_x + (i - 1.5) * 8 * s
                    lash_y = eye_y - eye_h - 1 * s
                    draw.line([
                        (lash_x, lash_y + 2 * s),
                        (lash_x + side * 2 * s, lash_y - 3 * s)
                    ], fill=self.colors['hair_dark'], width=int(1.5 * s))

        # Eyebrows - arched above eyes
        for side in [-1, 1]:
            brow_x = x + side * 22 * s
            brow_y = y - 28 * s

            # Curved eyebrow using arc
            draw.arc([brow_x - 18 * s, brow_y - 5 * s,
                     brow_x + 14 * s, brow_y + 12 * s],
                    190 if side == -1 else 170, 350 if side == -1 else 10,
                    fill=self.colors['hair_mid'], width=int(4 * s))

        # Nose
        draw.ellipse([x - 5 * s, y + 5 * s, x + 5 * s, y + 18 * s], fill=self.colors['skin_mid'])
        draw.ellipse([x - 3 * s, y + 8 * s, x + 3 * s, y + 14 * s], fill=self.colors['skin_light'])

        # Mouth
        mouth_y = y + 28 * s
        draw.arc([x - 18 * s, mouth_y - 8 * s, x + 18 * s, mouth_y + 8 * s],
                15, 165, fill=self.colors['lip'], width=int(4 * s))

        # Ears
        for side in [-1, 1]:
            ear_x = x + side * head_w * 0.95
            draw.ellipse([ear_x - 8*s, y - 12*s, ear_x + 6*s, y + 12*s], fill=self.colors['skin_mid'])

    def _draw_back_hair(self, draw, x, y, s, shake, walk):
        """Draw back hair layer."""
        p = self.proportions
        head_y = y - p.total_height + p.head_size * 0.5 + walk['body_bob']

        draw.ellipse([
            x - 55 * s, head_y - 40 * s,
            x + 55 * s, head_y + 55 * s
        ], fill=self.colors['hair_dark'])

        draw.ellipse([
            x - 50 * s, head_y - 38 * s,
            x + 48 * s, head_y + 48 * s
        ], fill=self.colors['hair_mid'])

    def _draw_front_hair(self, draw, x, y, s, shake):
        """Draw front bangs."""
        # Bangs base
        draw.ellipse([x - 50*s, y - 55*s, x + 50*s, y - 5*s], fill=self.colors['hair_mid'])

        # Forehead visible
        draw.ellipse([x - 36*s, y - 42*s, x + 36*s, y - 3*s], fill=self.colors['skin_light'])

        # Individual bang strands
        for i, offset in enumerate([-38, -22, -5, 12, 28, 38]):
            strand_x = x + offset * s
            strand_h = (42 + (i % 3) * 6) * s
            strand_w = (14 - abs(i - 2.5) * 1.5) * s

            draw.ellipse([strand_x - strand_w, y - 60*s, strand_x + strand_w, y - 60*s + strand_h],
                        fill=self.colors['hair_mid'])

            if i % 2 == 0:
                draw.ellipse([strand_x - strand_w*0.5, y - 58*s, strand_x + strand_w*0.3, y - 58*s + strand_h*0.6],
                            fill=self.colors['hair_light'])

    def _draw_side_hair(self, draw, shake):
        """Draw physics-based side hair (legacy, not flipped)."""
        s = self.scale

        for chain in [self.side_hair_left, self.side_hair_right]:
            points = chain.get_points()
            if len(points) >= 2:
                for i in range(len(points) - 1):
                    p1, p2 = points[i], points[i + 1]
                    thickness = (18 - i * 2.5) * s

                    x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                    x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                    draw.line([x1 + 2, y1 + 2, x2 + 2, y2 + 2], fill=self.colors['hair_dark'], width=int(thickness))
                    draw.line([x1, y1, x2, y2], fill=self.colors['hair_mid'], width=int(thickness * 0.9))
                    if i < 3:
                        draw.line([x1 - 2, y1, x2 - 2, y2], fill=self.colors['hair_light'], width=int(thickness * 0.3))

    def _draw_side_hair_flipped(self, img: Image.Image, shake, pos):
        """Draw physics-based side hair with flip support.

        Physics chains have world positions, so we mirror X around character center when flipped.
        """
        draw = ImageDraw.Draw(img)
        s = self.scale
        center_x = pos[0]

        for chain in [self.side_hair_left, self.side_hair_right]:
            points = chain.get_points()
            if len(points) >= 2:
                for i in range(len(points) - 1):
                    p1, p2 = points[i], points[i + 1]
                    thickness = (18 - i * 2.5) * s

                    x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                    x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                    # Mirror X coordinates if facing left
                    if self.facing < 0:
                        x1 = center_x + (center_x - x1) + shake[0]
                        x2 = center_x + (center_x - x2) + shake[0]

                    draw.line([x1 + 2, y1 + 2, x2 + 2, y2 + 2], fill=self.colors['hair_dark'], width=int(thickness))
                    draw.line([x1, y1, x2, y2], fill=self.colors['hair_mid'], width=int(thickness * 0.9))
                    if i < 3:
                        draw.line([x1 - 2, y1, x2 - 2, y2], fill=self.colors['hair_light'], width=int(thickness * 0.3))

    # =========================================================================
    # SIDE PROFILE VIEW METHODS
    # =========================================================================

    def _draw_head_side(self, draw, x, y, s, face, anim_state):
        """Draw head in side profile view.

        In profile, we see only ONE side of the face. The character faces RIGHT.
        - Back of head is on the LEFT (negative X from center)
        - Face features (eye, nose, mouth) are on the RIGHT (positive X)
        - Ear is at center X (it's on the SIDE of the head, visible in profile)
        """
        p = self.proportions

        # Side profile head dimensions
        head_w = p.head_size * 0.45  # Narrower from side
        head_h = p.head_size * 0.68

        # Head shape - profile silhouette
        # Back of head (left side) curves outward, face (right side) is flatter
        # Only show the visible side - no elements on "far side"

        # Main head shape - shadow (back of head bulges)
        draw.ellipse([
            x - head_w * 0.6, y - head_h * 0.9,  # Back of head (limited, not too far left)
            x + head_w * 1.1, y + head_h
        ], fill=self.colors['skin_shadow'])

        # Main head shape - mid tone
        draw.ellipse([
            x - head_w * 0.55, y - head_h * 0.87,
            x + head_w * 1.0, y + head_h * 0.97
        ], fill=self.colors['skin_mid'])

        # Forehead highlight - only on VISIBLE side (right/front)
        draw.ellipse([
            x + head_w * 0.1, y - head_h * 0.8,  # Starts at center, goes right
            x + head_w * 0.7, y - head_h * 0.2
        ], fill=self.colors['skin_light'])

        # EAR - drawn FIRST (behind face features)
        # Ear is at the CENTER of the head (it's on the side, not the back)
        ear_x = x  # Center X position - ear is ON the side of the head
        ear_y = y
        # Outer ear
        draw.ellipse([
            ear_x - 10 * s, ear_y - 15 * s,
            ear_x + 8 * s, ear_y + 15 * s
        ], fill=self.colors['skin_mid'])
        # Inner ear detail
        draw.ellipse([
            ear_x - 6 * s, ear_y - 10 * s,
            ear_x + 4 * s, ear_y + 10 * s
        ], fill=self.colors['skin_shadow'])
        draw.ellipse([
            ear_x - 3 * s, ear_y - 6 * s,
            ear_x + 2 * s, ear_y + 6 * s
        ], fill=self.colors['skin_deep'])

        # Profile eye - proper side view with eyelids
        eye_state = anim_state['eyes']
        blink = eye_state['blink']
        eye_x = x + head_w * 0.5  # Eye position on face
        eye_y = y - 3 * s

        # Eye dimensions for side profile (narrower than front)
        eye_w = 14 * s
        eye_h_full = 10 * s
        eye_h = eye_h_full * (1 - blink)  # Shrinks when blinking

        # Draw eye white (visible part between eyelids)
        if eye_h > 1 * s:
            # Simple ellipse for eye white in profile
            draw.ellipse([
                eye_x - eye_w * 0.3, eye_y - eye_h * 0.5,
                eye_x + eye_w * 0.7, eye_y + eye_h * 0.5
            ], fill=self.colors['eye_white'])

            if (1 - blink) > 0.15:
                # Iris - circular, positioned toward front of eye
                iris_r = 6 * s * min(1.0, (1 - blink) + 0.1)
                iris_x = eye_x + eye_w * 0.25
                draw.ellipse([
                    iris_x - iris_r, eye_y - iris_r,
                    iris_x + iris_r, eye_y + iris_r
                ], fill=self.colors['iris_outer'])

                # Pupil
                pupil_r = 3 * s
                draw.ellipse([
                    iris_x - pupil_r, eye_y - pupil_r,
                    iris_x + pupil_r, eye_y + pupil_r
                ], fill=self.colors['pupil'])

                # Eye highlight
                draw.ellipse([
                    iris_x - 4*s, eye_y - 4*s,
                    iris_x - 1*s, eye_y - 1*s
                ], fill=(255, 255, 255))

        # Upper eyelid line (curves over eye)
        upper_lid_y = eye_y - eye_h_full * 0.5 + blink * eye_h_full * 0.4
        draw.arc([
            eye_x - eye_w * 0.4, upper_lid_y - 4 * s,
            eye_x + eye_w * 0.8, upper_lid_y + 8 * s
        ], 200, 340, fill=self.colors['skin_deep'], width=int(2 * s))

        # Lower eyelid line (subtle)
        lower_lid_y = eye_y + eye_h_full * 0.4 - blink * eye_h_full * 0.3
        draw.arc([
            eye_x - eye_w * 0.3, lower_lid_y - 6 * s,
            eye_x + eye_w * 0.7, lower_lid_y + 4 * s
        ], 20, 160, fill=self.colors['skin_shadow'], width=int(1.5 * s))

        # Eyelashes (small lines on upper lid)
        if blink < 0.7:
            for i in range(3):
                lash_x = eye_x + eye_w * (0.1 + i * 0.2)
                lash_y = upper_lid_y + 2 * s
                draw.line([
                    (lash_x, lash_y),
                    (lash_x + 3 * s, lash_y - 4 * s)
                ], fill=self.colors['hair_dark'], width=int(1.5 * s))

        # Profile eyebrow - arched above eye
        brow_x = eye_x - eye_w * 0.2
        brow_y = eye_y - eye_h_full - 8 * s
        draw.arc([
            brow_x - 5 * s, brow_y - 3 * s,
            brow_x + 20 * s, brow_y + 10 * s
        ], 200, 320, fill=self.colors['hair_mid'], width=int(3.5 * s))

        # Profile nose (protruding toward the right)
        nose_tip_x = x + head_w * 1.3
        nose_tip_y = y + 12 * s
        nose_bridge_y = y - 8 * s

        # Nose bridge and tip
        nose_points = [
            (x + head_w * 0.5, nose_bridge_y - 5 * s),  # Bridge top
            (x + head_w * 0.6, nose_bridge_y),  # Bridge
            (nose_tip_x, nose_tip_y - 5 * s),  # Tip top
            (nose_tip_x - 2 * s, nose_tip_y),  # Tip
            (x + head_w * 0.7, nose_tip_y + 5 * s),  # Nostril
            (x + head_w * 0.4, nose_tip_y),  # Under nose
        ]
        draw.polygon(nose_points, fill=self.colors['skin_mid'])

        # Nose highlight
        draw.line([
            (x + head_w * 0.55, nose_bridge_y - 3 * s),
            (nose_tip_x - 3 * s, nose_tip_y - 6 * s)
        ], fill=self.colors['skin_light'], width=int(3 * s))

        # Profile mouth
        mouth_y = y + 28 * s
        mouth_x = x + head_w * 0.6
        # Upper lip
        draw.arc([
            mouth_x - 8 * s, mouth_y - 6 * s,
            mouth_x + 12 * s, mouth_y + 6 * s
        ], 180, 270, fill=self.colors['lip'], width=int(3 * s))
        # Lower lip
        draw.arc([
            mouth_x - 6 * s, mouth_y - 4 * s,
            mouth_x + 10 * s, mouth_y + 8 * s
        ], 270, 360, fill=self.colors['lip_shadow'], width=int(3 * s))

        # Chin definition
        chin_y = y + head_h * 0.85
        draw.arc([
            x + head_w * 0.2, chin_y - 15 * s,
            x + head_w * 1.0, chin_y + 5 * s
        ], 0, 90, fill=self.colors['skin_shadow'], width=int(2 * s))

    def _draw_neck_side(self, draw, x, y, s, breath):
        """Draw neck in side profile."""
        neck_w = 14 * s  # Narrower from side
        neck_h = 28 * s

        # Neck tilts slightly forward
        neck_front = x + 8 * s
        neck_back = x - 12 * s

        # Neck shape (trapezoid-ish)
        neck_points = [
            (neck_back, y - neck_h * 0.3),  # Back top
            (neck_front + 5 * s, y - neck_h * 0.2),  # Front top
            (neck_front + 10 * s, y + 5 * s),  # Front bottom
            (neck_back - 5 * s, y + 8 * s),  # Back bottom
        ]
        draw.polygon(neck_points, fill=self.colors['skin_shadow'])

        # Highlight
        highlight_points = [
            (neck_back + 5 * s, y - neck_h * 0.25),
            (neck_front, y - neck_h * 0.15),
            (neck_front + 5 * s, y + 2 * s),
            (neck_back, y + 5 * s),
        ]
        draw.polygon(highlight_points, fill=self.colors['skin_mid'])

    def _draw_body_side(self, draw, x, y, s, breath, walk, weight):
        """Draw torso in side profile view."""
        p = self.proportions

        chest_expand = 1.0 + breath['chest'] * 0.012
        torso_h = p.crotch_y - p.shoulder_y

        # Side view torso is much narrower (showing depth)
        torso_depth = p.shoulder_width * 0.25 * chest_expand

        # Chest/shirt area (profile)
        chest_front = x + torso_depth * 0.6
        chest_back = x - torso_depth * 0.8

        # Upper body silhouette
        body_points = [
            (chest_back - 5 * s, y - torso_h * 0.9),  # Back shoulder
            (chest_front + 10 * s, y - torso_h * 0.85),  # Front shoulder
            (chest_front + 15 * s, y - torso_h * 0.5),  # Chest
            (chest_front + 8 * s, y - torso_h * 0.1),  # Waist front
            (chest_back - 8 * s, y),  # Waist back
            (chest_back - 15 * s, y - torso_h * 0.4),  # Back curve
        ]
        draw.polygon(body_points, fill=self.colors['top_shadow'])

        # Mid-tone layer
        mid_points = [
            (chest_back, y - torso_h * 0.88),
            (chest_front + 5 * s, y - torso_h * 0.83),
            (chest_front + 10 * s, y - torso_h * 0.5),
            (chest_front + 4 * s, y - torso_h * 0.12),
            (chest_back - 3 * s, y - torso_h * 0.05),
            (chest_back - 10 * s, y - torso_h * 0.4),
        ]
        draw.polygon(mid_points, fill=self.colors['top_mid'])

        # Highlight on chest
        highlight_points = [
            (chest_front - 5 * s, y - torso_h * 0.8),
            (chest_front + 5 * s, y - torso_h * 0.75),
            (chest_front + 8 * s, y - torso_h * 0.5),
            (chest_front, y - torso_h * 0.3),
        ]
        draw.polygon(highlight_points, fill=self.colors['top_light'])

        # Pants/hip area
        hip_front = x + torso_depth * 0.5
        hip_back = x - torso_depth * 0.6

        pants_points = [
            (hip_back - 5 * s, y - 5 * s),
            (hip_front + 5 * s, y - 8 * s),
            (hip_front + 8 * s, y + 20 * s),
            (hip_back - 8 * s, y + 25 * s),
        ]
        draw.polygon(pants_points, fill=self.colors['pants_shadow'])

        pants_mid_points = [
            (hip_back, y - 3 * s),
            (hip_front, y - 6 * s),
            (hip_front + 4 * s, y + 18 * s),
            (hip_back - 4 * s, y + 22 * s),
        ]
        draw.polygon(pants_mid_points, fill=self.colors['pants_mid'])

    def _draw_far_arm_side(self, draw, x, y, s, breath, walk):
        """Draw the FAR arm in side profile (the one on the opposite side of body).

        This should be called BEFORE the body is drawn so it appears behind.
        The far arm is only visible when it swings forward (in front of the body plane).
        """
        p = self.proportions

        walk_blend = walk['walk_blend']
        walk_phase = walk['phase']

        upper_len = p.upper_arm_length
        lower_len = p.forearm_length

        # Near arm swing
        near_arm_swing = math.sin(walk_phase) * 0.5 * walk_blend
        # Far arm swings in opposition
        far_arm_swing = -near_arm_swing

        shoulder_y = y

        # Only draw far arm when it swings forward (positive = toward viewer)
        if far_arm_swing > 0.05:
            # Far arm shoulder is offset back slightly
            far_shoulder_x = x - 5 * s

            far_upper_angle = math.pi / 2 + far_arm_swing
            far_elbow_x = far_shoulder_x + math.cos(far_upper_angle) * upper_len
            far_elbow_y = shoulder_y + math.sin(far_upper_angle) * upper_len

            far_elbow_bend = 0.4 + far_arm_swing * 0.3
            far_lower_angle = far_upper_angle - far_elbow_bend
            far_wrist_x = far_elbow_x + math.cos(far_lower_angle) * lower_len
            far_wrist_y = far_elbow_y + math.sin(far_lower_angle) * lower_len

            # Draw far arm in darker/muted colors (it's further away)
            far_arm_width = 14 * s  # Thinner due to perspective
            draw.line([far_shoulder_x, shoulder_y, far_elbow_x, far_elbow_y],
                      fill=self.colors['skin_deep'], width=int(far_arm_width))

            draw.line([far_elbow_x, far_elbow_y, far_wrist_x, far_wrist_y],
                      fill=self.colors['skin_deep'], width=int(far_arm_width * 0.8))

            # Far hand (smaller)
            far_hand_size = 9 * s
            draw.ellipse([
                far_wrist_x - far_hand_size, far_wrist_y - far_hand_size,
                far_wrist_x + far_hand_size, far_wrist_y + far_hand_size
            ], fill=self.colors['skin_shadow'])

    def _draw_arms_side(self, draw, x, y, s, breath, walk):
        """Draw the NEAR arm in side profile view (the one closer to camera).

        This should be called AFTER the body is drawn so it appears in front.
        """
        p = self.proportions

        walk_blend = walk['walk_blend']
        walk_phase = walk['phase']

        upper_len = p.upper_arm_length
        lower_len = p.forearm_length

        # Arm swing during walk (near arm)
        near_arm_swing = math.sin(walk_phase) * 0.5 * walk_blend

        shoulder_x = x
        shoulder_y = y

        # Arm hangs down with swing (forward = positive angle from vertical)
        upper_angle = math.pi / 2 + near_arm_swing
        elbow_x = shoulder_x + math.cos(upper_angle) * upper_len
        elbow_y = shoulder_y + math.sin(upper_angle) * upper_len

        # Forearm - elbow bends BACKWARD (toward back of body)
        elbow_bend = 0.4 + near_arm_swing * 0.3
        lower_angle = upper_angle - elbow_bend
        wrist_x = elbow_x + math.cos(lower_angle) * lower_len
        wrist_y = elbow_y + math.sin(lower_angle) * lower_len

        # Draw upper arm
        arm_width = 18 * s
        draw.line([shoulder_x, shoulder_y, elbow_x, elbow_y],
                  fill=self.colors['skin_shadow'], width=int(arm_width))
        draw.line([shoulder_x + 2, shoulder_y, elbow_x + 2, elbow_y],
                  fill=self.colors['skin_mid'], width=int(arm_width * 0.85))

        # Shoulder joint
        draw.ellipse([
            shoulder_x - arm_width/2, shoulder_y - arm_width/2,
            shoulder_x + arm_width/2, shoulder_y + arm_width/2
        ], fill=self.colors['skin_mid'])

        # Elbow joint
        draw.ellipse([
            elbow_x - arm_width*0.4, elbow_y - arm_width*0.4,
            elbow_x + arm_width*0.4, elbow_y + arm_width*0.4
        ], fill=self.colors['skin_mid'])

        # Draw forearm
        forearm_width = 14 * s
        draw.line([elbow_x, elbow_y, wrist_x, wrist_y],
                  fill=self.colors['skin_shadow'], width=int(forearm_width))
        draw.line([elbow_x + 2, elbow_y, wrist_x + 2, wrist_y],
                  fill=self.colors['skin_mid'], width=int(forearm_width * 0.85))

        # Hand
        hand_size = 12 * s
        draw.ellipse([
            wrist_x - hand_size, wrist_y - hand_size,
            wrist_x + hand_size, wrist_y + hand_size * 1.2
        ], fill=self.colors['skin_mid'])

    def _draw_legs_side(self, draw, base_x, base_y, s, walk, weight):
        """Draw legs in side profile view using proper IK for foot grounding."""
        p = self.proportions

        walk_blend = walk['walk_blend']
        walk_phase = walk['phase']
        body_bob = walk['body_bob']
        hip_sway = walk['hip_sway']

        # Get weight offset like front view does
        hip_weight_offset = weight.get('hip_offset', (0, 0))

        # Hip Y position (consistent with body drawing)
        hip_y = base_y - p.crotch_y + body_bob + hip_weight_offset[1]

        thigh_len = p.thigh_length
        calf_len = p.calf_length

        # Ground level for feet
        ground_y = base_y - 10 * s

        # Draw both legs (back leg first for proper layering, then front leg)
        for leg_idx, phase_offset in enumerate([math.pi, 0]):  # Back leg, then front leg
            leg_phase = walk_phase + phase_offset

            # Depth offset for layering (back leg slightly behind)
            depth_offset = -8 * s if leg_idx == 0 else 8 * s

            # Hip position includes sway and weight offset
            hip_x = base_x + depth_offset + hip_sway + hip_weight_offset[0]

            # Calculate walk cycle phase (0 to 1)
            t = (leg_phase % (2 * math.pi)) / (2 * math.pi)

            # --- FOOT TARGET CALCULATION ---
            # In side view, legs swing forward (positive X) and backward (negative X)
            # Swing range: how far forward/back the foot goes from hip
            max_stride = 60 * s * walk_blend  # Forward/back distance

            # Swing position: sin wave creates smooth forward-back motion
            # At t=0.25, foot is furthest forward; at t=0.75, furthest back
            swing_x = math.sin(leg_phase) * max_stride

            # Foot X target: hip position + swing offset
            foot_target_x = hip_x + swing_x

            # Foot lift: foot lifts during swing phase (roughly t=0.5 to t=1.0)
            # This is when the leg is swinging forward
            foot_lift = 0
            if 0.5 < t < 1.0:
                # Smooth arc using sin
                lift_t = (t - 0.5) / 0.5
                foot_lift = math.sin(lift_t * math.pi) * 35 * s * walk_blend

            # Foot Y target: ground level minus lift
            foot_target_y = ground_y - foot_lift

            # --- SOLVE IK ---
            # Use the proper IK solver like front view does
            # For side profile, pole vector determines knee bend direction
            # Knee should bend FORWARD (in the direction character faces)
            # If character faces right (+X), knee bends in +X direction relative to leg
            # The pole vector is placed in front of the mid-point of the leg

            mid_y = (hip_y + foot_target_y) / 2
            # Pole in front of leg (positive X = forward for right-facing character)
            pole_x = hip_x + 80 * s
            pole_vector = (pole_x, mid_y)

            (knee_x, knee_y), thigh_angle, calf_angle = solve_leg_ik(
                hip_pos=(hip_x, hip_y),
                foot_target=(foot_target_x, foot_target_y),
                thigh_length=thigh_len,
                calf_length=calf_len,
                knee_forward=True  # Knee bends forward naturally
            )

            # Calculate actual foot position from IK (may differ slightly due to clamping)
            actual_foot_x = knee_x + math.cos(calf_angle) * calf_len
            actual_foot_y = knee_y + math.sin(calf_angle) * calf_len

            # Ensure foot doesn't go below ground
            if actual_foot_y > ground_y:
                actual_foot_y = ground_y

            # Colors (back leg slightly darker for depth)
            if leg_idx == 0:
                thigh_color = self.colors['pants_shadow']
                calf_color = self.colors['pants_fold']
                shoe_color = self.colors['shoe_shadow']
            else:
                thigh_color = self.colors['pants_mid']
                calf_color = self.colors['pants_light']
                shoe_color = self.colors['shoe_mid']

            # --- DRAW THIGH ---
            thigh_width = 28 * s if leg_idx == 1 else 24 * s
            draw.line([hip_x, hip_y, knee_x, knee_y],
                      fill=thigh_color, width=int(thigh_width))

            # Knee joint
            knee_r = 12 * s if leg_idx == 1 else 10 * s
            draw.ellipse([
                knee_x - knee_r, knee_y - knee_r,
                knee_x + knee_r, knee_y + knee_r
            ], fill=thigh_color)

            # --- DRAW CALF ---
            # Ankle is slightly above the foot
            ankle_x = actual_foot_x
            ankle_y = actual_foot_y - 8 * s

            calf_width = 20 * s if leg_idx == 1 else 16 * s
            draw.line([knee_x, knee_y, ankle_x, ankle_y],
                      fill=calf_color, width=int(calf_width))

            # --- DRAW FOOT/SHOE ---
            foot_len = 30 * s
            foot_h = 12 * s
            foot_bottom_y = actual_foot_y

            # Shoe shape - properly attached to ankle
            shoe_points = [
                (ankle_x - 8 * s, ankle_y),                          # Ankle back
                (ankle_x + foot_len * 0.3, ankle_y - 3 * s),         # Ankle front curve
                (ankle_x + foot_len, ankle_y + foot_h * 0.3),        # Toe top
                (ankle_x + foot_len, foot_bottom_y),                 # Toe bottom
                (ankle_x - 10 * s, foot_bottom_y),                   # Heel bottom
            ]
            draw.polygon(shoe_points, fill=shoe_color)

            # Sole
            draw.line([
                (ankle_x - 10 * s, foot_bottom_y),
                (ankle_x + foot_len, foot_bottom_y)
            ], fill=self.colors['shoe_sole'], width=int(4 * s))

    def _draw_hair_side_back(self, draw, x, y, s, walk):
        """Draw back hair in side profile view (behind body/head).

        Args:
            x: Head center X
            y: Head center Y (NOT ground Y!)
        """
        p = self.proportions

        head_w = p.head_size * 0.45
        head_h = p.head_size * 0.68

        # Back of head hair (large mass) - extends behind and below head
        draw.ellipse([
            x - head_w * 1.5, y - head_h * 1.0,
            x + head_w * 0.3, y + head_h * 0.8
        ], fill=self.colors['hair_dark'])

        draw.ellipse([
            x - head_w * 1.4, y - head_h * 0.95,
            x + head_w * 0.2, y + head_h * 0.75
        ], fill=self.colors['hair_mid'])

        # Top of head hair (behind the face area)
        draw.ellipse([
            x - head_w * 0.8, y - head_h * 1.1,
            x + head_w * 0.6, y - head_h * 0.3
        ], fill=self.colors['hair_mid'])

        # Hair highlight on back
        draw.ellipse([
            x - head_w * 0.6, y - head_h * 1.0,
            x + head_w * 0.1, y - head_h * 0.5
        ], fill=self.colors['hair_light'])

        # Side hair strands (hang down behind shoulders)
        for i in range(3):
            strand_y = y + head_h * 0.2 + i * 20 * s
            strand_len = (50 - i * 8) * s
            strand_points = [
                (x - head_w * 1.0, strand_y - 8 * s),
                (x - head_w * 1.0 - strand_len * 0.3, strand_y),
                (x - head_w * 1.0 - strand_len * 0.2, strand_y + 15 * s),
                (x - head_w * 0.8, strand_y + 10 * s),
            ]
            draw.polygon(strand_points, fill=self.colors['hair_mid'] if i % 2 == 0 else self.colors['hair_dark'])

    def _draw_hair_side_front(self, draw, x, y, s):
        """Draw front bangs in side profile view (in front of face).

        Args:
            x: Head center X
            y: Head center Y (NOT ground Y!)
        """
        p = self.proportions

        head_w = p.head_size * 0.45
        head_h = p.head_size * 0.68

        # Bangs in profile (side-swept, in front of forehead)
        bang_points = [
            (x + head_w * 0.3, y - head_h * 0.9),   # Top back
            (x + head_w * 0.8, y - head_h * 0.5),   # Top front
            (x + head_w * 0.6, y - head_h * 0.2),   # Bottom front
            (x + head_w * 0.2, y - head_h * 0.3),   # Mid
            (x - head_w * 0.2, y - head_h * 0.7),   # Back
        ]
        draw.polygon(bang_points, fill=self.colors['hair_mid'])

        # Bang highlight
        highlight_points = [
            (x + head_w * 0.35, y - head_h * 0.85),
            (x + head_w * 0.65, y - head_h * 0.55),
            (x + head_w * 0.5, y - head_h * 0.45),
            (x + head_w * 0.2, y - head_h * 0.65),
        ]
        draw.polygon(highlight_points, fill=self.colors['hair_light'])


# =============================================================================
# BACKGROUND
# =============================================================================

def create_starfield(width, height, num_stars=180):
    """Create starfield."""
    random.seed(42)
    return [{
        'x': random.randint(0, width),
        'y': random.randint(0, int(height * 0.7)),
        'size': random.uniform(0.4, 3.0),
        'brightness': random.uniform(0.5, 1.0),
        'twinkle_speed': random.uniform(1.8, 4.2),
        'twinkle_offset': random.uniform(0, math.pi * 2)
    } for _ in range(num_stars)]


def draw_background(draw, width, height, time, stars, shake, walk_blend=0):
    """Draw animated background with ground plane."""
    # Sky gradient
    hue_shift = math.sin(time * 0.15) * 10

    for y in range(0, height, 2):
        t = y / height
        r = int(28 + t * 35 + hue_shift)
        g = int(26 + t * 30)
        b = int(55 + t * 35 - hue_shift * 0.4)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    # Stars
    for star in stars:
        twinkle = (math.sin(time * star['twinkle_speed'] + star['twinkle_offset']) + 1) / 2
        brightness = int(100 + twinkle * 150 * star['brightness'])
        size = star['size'] * (0.8 + twinkle * 0.4)

        sx = star['x'] + shake[0]
        sy = star['y'] + shake[1]

        if size > 2.0:
            draw.ellipse([sx - size*2.5, sy - size*2.5, sx + size*2.5, sy + size*2.5],
                        fill=(brightness, brightness, 255, 20))

        draw.ellipse([sx - size, sy - size, sx + size, sy + size],
                    fill=(brightness, brightness, min(255, brightness + 30)))

    # Ground plane
    ground_y = int(height * 0.88)

    # Ground gradient
    for y in range(ground_y, height, 2):
        t = (y - ground_y) / (height - ground_y)
        r = int(35 + t * 20)
        g = int(38 + t * 25)
        b = int(42 + t * 15)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    # Ground line
    draw.line([0, ground_y, width, ground_y], fill=(50, 55, 60), width=3)

    # Ground details (subtle lines for depth)
    for i in range(5):
        line_y = ground_y + 20 + i * 35
        alpha = max(0, 40 - i * 8)
        if line_y < height:
            draw.line([0, line_y, width, line_y], fill=(55, 60, 65, alpha), width=1)


# =============================================================================
# MAIN
# =============================================================================

def main():
    print("=" * 70)
    print("FULL-BODY CHARACTER ANIMATION")
    print("8-head proportions with walking and leg physics")
    print("=" * 70)
    print()

    WIDTH, HEIGHT = 1920, 1080
    FPS = 30
    DURATION = 18.0

    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Duration: {DURATION}s at {FPS}fps")
    print(f"Total frames: {int(DURATION * FPS)}")
    print()

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Ground level (character's feet position)
    ground_y = int(HEIGHT * 0.88)

    # Create full-body character
    character = FullBodyCharacter(WIDTH // 2, ground_y, scale=2.2)

    # Facial animation
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    # Camera
    camera = Camera((WIDTH, HEIGHT))

    # Starfield
    stars = create_starfield(WIDTH, HEIGHT, 180)

    # Timeline tracking
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline events
        if time >= 1.0 and 'start_walk' not in triggered:
            character.set_walking(True)
            triggered.add('start_walk')

        if time >= 5.0 and 'stop_walk' not in triggered:
            character.set_walking(False)
            triggered.add('stop_walk')

        if time >= 6.5 and 'impact' not in triggered:
            character.trigger_impact(1.2)
            camera.add_shake(ShakeType.IMPACT, intensity=0.8)
            facial.set_emotion(Emotion.SURPRISED)
            triggered.add('impact')

        if time >= 7.5 and 'happy_again' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy_again')

        if time >= 9.0 and 'walk_again' not in triggered:
            character.set_walking(True)
            triggered.add('walk_again')

        if time >= 13.0 and 'final_stop' not in triggered:
            character.set_walking(False)
            triggered.add('final_stop')

        if time >= 15.0 and 'final_impact' not in triggered:
            character.trigger_impact(1.0)
            camera.add_shake(ShakeType.IMPACT, intensity=0.6)
            triggered.add('final_impact')

        # Update systems
        face = facial.update(dt)
        camera.update(dt)

        # Character position (slight sway when idle, forward movement when walking)
        walk_state = character.walk.walk_blend.value
        sway_x = math.sin(time * 0.3) * 12 * (1 - walk_state * 0.7)
        target = (WIDTH // 2 + sway_x, ground_y)

        anim_state = character.update(dt, frame_num, FPS, time=time, target_pos=target)

        shake = camera._shake_offset

        # Render
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake, walk_state)
        character.draw(frame, face, anim_state, shake)

        # Title
        title_y = 50 + math.sin(time * 1.2) * 3
        draw.text((WIDTH // 2 + 2, title_y + 2), "Full-Body Animation", fill=(0, 0, 0, 100), anchor="mm")
        draw.text((WIDTH // 2, title_y), "Full-Body Animation", fill=(255, 255, 255), anchor="mm")

        # Feature labels
        subtitles = [
            (0, 1.0, "8-Head Proportions - Anatomically Correct"),
            (1.0, 5.0, "Procedural Walking - Sine Wave Gait Cycle"),
            (5.0, 6.5, "Idle Stance - Weight Distribution"),
            (6.5, 7.5, "Impact Reaction - Hair Physics"),
            (7.5, 9.0, "Natural Idle - Hip Sway & Breathing"),
            (9.0, 13.0, "Full Walk Cycle - IK Legs & Arm Swing"),
            (13.0, 15.0, "Smooth Walk-to-Idle Transition"),
            (15.0, 99, "Complete Full-Body Integration"),
        ]
        for start, end, text in subtitles:
            if start <= time < end:
                draw.text((WIDTH // 2, HEIGHT - 50), text, fill=(235, 235, 255, 220), anchor="mm")
                break

        # Progress bar
        bar_w = 500
        bar_x = (WIDTH - bar_w) // 2
        bar_y = HEIGHT - 25
        progress = time / DURATION

        draw.rectangle([bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + 10], fill=(35, 35, 50))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_w * progress), bar_y + 8], fill=(115, 170, 255))

    renderer.on_frame(draw_frame)

    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    print("Applying post-processing...")
    processed = []
    for i, frame in enumerate(frames):
        frame = apply_vignette(frame, intensity=0.22, radius=0.9)
        frame = apply_color_grade(frame, brightness=1.02, contrast=1.04,
                                  saturation=1.06, tint=(255, 250, 245),
                                  tint_strength=0.03)
        processed.append(frame)

        if (i + 1) % 90 == 0:
            print(f"  Post-processed {i + 1}/{len(frames)} frames")

    print()
    print("Encoding to MP4...")
    output_path = "fullbody_animation.mp4"

    try:
        ffmpeg_renderer = FFmpegRenderer(
            codec="h264",
            quality="high",
            ffmpeg_path=FFMPEG_PATH
        )

        def on_progress(progress):
            if progress.current_frame % 100 == 0:
                print(f"  Encoding: {progress.current_frame}/{len(processed)} frames")

        ffmpeg_renderer.encode_video(
            processed,
            output_path,
            fps=FPS,
            on_progress=on_progress
        )

        import os
        size_mb = os.path.getsize(output_path) / (1024 * 1024)

        print()
        print("=" * 70)
        print("FULL-BODY ANIMATION COMPLETE")
        print("=" * 70)
        print(f"Output: {output_path}")
        print(f"Size: {size_mb:.1f} MB")
        print(f"Resolution: {WIDTH}x{HEIGHT}")
        print(f"Duration: {DURATION}s")
        print(f"Frames: {len(processed)}")
        print()
        print("Features:")
        print("  - 8-head canon proportions (anatomically correct)")
        print("  - Full legs with thigh, calf, and foot")
        print("  - IK-based leg positioning")
        print("  - Procedural walking (sine wave gait)")
        print("  - Foot lift and ground contact")
        print("  - Hip sway and body bob during walk")
        print("  - Arm swing synchronized with legs")
        print("  - Weight distribution system")
        print("  - Smooth walk/idle transitions")
        print("  - Detailed shoe rendering")
        print("  - Physics-based hair")
        print("  - Breathing animation")

    except Exception as e:
        print(f"FFmpeg encoding failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
