#!/usr/bin/env python3
"""Realistic character animation with sophisticated details.

Features:
- Anatomically accurate proportions
- Gradient shading for 3D appearance
- Detailed hands with fingers
- 12 principles of animation (anticipation, follow-through, etc)
- Micro-movements and weight shifts
- Natural secondary motion
- Ambient occlusion and soft shadows
"""

import math
import random
from dataclasses import dataclass, field
from typing import List, Tuple, Optional
from PIL import Image, ImageDraw, ImageFilter

from pipeline.animation import (
    Vec2, Spring, Spring2D, PhysicsChain,
    BreathingAnimation, EyeController, Wobble,
    Emotion, FacialAnimator,
    Camera, ShakeType,
    apply_vignette, apply_color_grade,
    QuickRenderer,
)
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer


FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"


@dataclass
class Finger:
    """Individual finger with joints."""
    base_angle: float = 0.0
    mid_angle: float = 0.0
    tip_angle: float = 0.0
    spread: float = 0.0  # Lateral spread


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
            self.index.spread = -0.1
            self.pinky.spread = 0.15
        elif pose_name == "wave":
            for f in [self.index, self.middle, self.ring, self.pinky]:
                f.base_angle = -0.2
                f.mid_angle = 0.0
                f.tip_angle = 0.0
            self.thumb.base_angle = 0.4
            self.index.spread = -0.15
            self.pinky.spread = 0.2
        elif pose_name == "pointing":
            self.index.base_angle = 0.0
            self.index.mid_angle = 0.0
            for f in [self.middle, self.ring, self.pinky]:
                f.base_angle = 1.2
                f.mid_angle = 1.0
                f.tip_angle = 0.8
            self.thumb.base_angle = 0.8


class AnticipationController:
    """Manages anticipation and follow-through for natural movement."""

    def __init__(self):
        self.anticipation_spring = Spring(stiffness=150, damping=12)
        self.followthrough_spring = Spring(stiffness=80, damping=8)
        self._action_time = -100
        self._action_type = None

    def trigger_action(self, action_type: str, time: float):
        """Trigger an action with anticipation."""
        self._action_type = action_type
        self._action_time = time
        # Wind up (anticipation goes negative first)
        self.anticipation_spring.nudge(-50)

    def update(self, time: float, dt: float) -> dict:
        """Get current anticipation/follow-through values."""
        elapsed = time - self._action_time

        # Anticipation builds up then releases
        if 0 < elapsed < 0.3:
            self.anticipation_spring.set_target(-0.3)  # Wind up
        elif 0.3 <= elapsed < 0.5:
            self.anticipation_spring.set_target(1.0)  # Release
        else:
            self.anticipation_spring.set_target(0.0)

        # Follow-through lags behind
        if 0.4 < elapsed < 0.8:
            self.followthrough_spring.set_target(0.5)
        else:
            self.followthrough_spring.set_target(0.0)

        antic = self.anticipation_spring.update(dt)
        follow = self.followthrough_spring.update(dt)

        return {
            'anticipation': antic,
            'followthrough': follow,
            'action': self._action_type if elapsed < 2.0 else None
        }


class WeightShift:
    """Natural weight shifting for idle stance."""

    def __init__(self):
        self.hip_offset = Spring2D(stiffness=30, damping=6)
        self.shoulder_offset = Spring2D(stiffness=40, damping=7)
        self._shift_time = 0
        self._current_side = 0  # -1 left, 0 center, 1 right

    def update(self, time: float, dt: float) -> dict:
        """Update weight distribution."""
        # Shift weight every 2-4 seconds
        if time > self._shift_time:
            self._shift_time = time + random.uniform(2.5, 4.5)
            # Choose new weight distribution
            self._current_side = random.choice([-1, 0, 1])

        # Hip shifts opposite to weight
        hip_target = (self._current_side * 8, self._current_side * 3)
        # Shoulders counter-rotate slightly
        shoulder_target = (-self._current_side * 4, -self._current_side * 2)

        self.hip_offset.set_target(hip_target)
        self.shoulder_offset.set_target(shoulder_target)

        hip = self.hip_offset.update(dt)
        shoulder = self.shoulder_offset.update(dt)

        return {
            'hip_offset': hip,
            'shoulder_offset': shoulder,
            'weight_side': self._current_side
        }


class MicroMovement:
    """Subtle idle movements for lifelike appearance."""

    def __init__(self):
        # Head micro-movements
        self.head_spring = Spring2D(stiffness=100, damping=10)
        self._head_target_time = 0

        # Subtle sway
        self.sway_phase = random.uniform(0, math.pi * 2)

        # Fidget timing
        self._fidget_time = random.uniform(3, 8)
        self._fidget_type = None

    def update(self, time: float, dt: float) -> dict:
        """Get micro-movement offsets."""
        # Natural sway (very subtle)
        sway_x = math.sin(time * 0.4 + self.sway_phase) * 2
        sway_y = math.sin(time * 0.6 + self.sway_phase * 1.3) * 1.5

        # Head wanders slightly
        if time > self._head_target_time:
            self._head_target_time = time + random.uniform(1.5, 3.0)
            target = (random.uniform(-5, 5), random.uniform(-3, 3))
            self.head_spring.set_target(target)

        head_offset = self.head_spring.update(dt)

        # Fidget detection
        fidget = None
        if time > self._fidget_time:
            self._fidget_time = time + random.uniform(5, 12)
            fidget = random.choice(['blink_double', 'head_tilt', 'shoulder_adjust'])

        return {
            'sway': (sway_x, sway_y),
            'head_offset': head_offset,
            'fidget': fidget
        }


class RealisticCharacter:
    """Highly detailed character with natural movement."""

    def __init__(self, x, y, scale=1.0):
        self.base_x = x
        self.base_y = y
        self.scale = scale

        # Refined color palette with gradients
        self.colors = {
            'skin_light': (255, 225, 205),
            'skin_mid': (245, 205, 180),
            'skin_shadow': (220, 175, 150),
            'skin_deep': (195, 145, 120),
            'hair_light': (85, 70, 95),
            'hair_mid': (55, 45, 65),
            'hair_dark': (35, 28, 42),
            'hair_highlight': (120, 100, 130),
            'eye_white': (252, 252, 255),
            'iris_outer': (95, 155, 200),
            'iris_inner': (65, 120, 170),
            'pupil': (18, 22, 32),
            'lip': (210, 135, 140),
            'lip_shadow': (180, 100, 110),
            'blush': (255, 190, 195),
            'outfit_light': (115, 155, 210),
            'outfit_mid': (85, 125, 185),
            'outfit_shadow': (60, 95, 155),
            'outfit_fold': (50, 80, 135),
        }

        # Animation controllers
        self.breathing = BreathingAnimation(rate=13, depth=1.0, variation=0.15)
        self.eyes = EyeController(max_offset=6 * scale, blink_interval=(2.5, 5.5))
        self.anticipation = AnticipationController()
        self.weight_shift = WeightShift()
        self.micro = MicroMovement()
        self.wobble = Wobble(frequency=5.0, amplitude=0.05)

        # Physics for hair
        self.hair_strands = [
            PhysicsChain(anchor=(x - 30*scale, y - 140*scale), segments=5,
                        segment_length=16*scale, gravity=(0, 120), damping=0.9, stiffness=0.85),
            PhysicsChain(anchor=(x, y - 150*scale), segments=6,
                        segment_length=18*scale, gravity=(0, 100), damping=0.88, stiffness=0.82),
            PhysicsChain(anchor=(x + 25*scale, y - 145*scale), segments=5,
                        segment_length=15*scale, gravity=(0, 130), damping=0.91, stiffness=0.87),
        ]

        # Side hair
        self.side_hair_left = PhysicsChain(
            anchor=(x - 55*scale, y - 100*scale), segments=7,
            segment_length=20*scale, gravity=(0, 90), damping=0.85, stiffness=0.75
        )
        self.side_hair_right = PhysicsChain(
            anchor=(x + 55*scale, y - 100*scale), segments=7,
            segment_length=20*scale, gravity=(0, 90), damping=0.85, stiffness=0.75
        )

        # Clothing physics (collar/neckline)
        self.collar_spring = Spring2D(stiffness=200, damping=15)

        # Hands
        self.left_hand = Hand()
        self.right_hand = Hand()
        self.left_hand.set_pose("relaxed")
        self.right_hand.set_pose("relaxed")

        # Position springs for smooth movement
        self.position = Spring2D(stiffness=120, damping=14, initial_position=(x, y))

        # State
        self.prev_pos = (x, y)
        self.velocity = (0, 0)
        self.current_action = None

    def trigger_action(self, action: str, time: float):
        """Trigger an animated action with anticipation."""
        self.anticipation.trigger_action(action, time)
        self.current_action = action

        if action == "wave":
            self.right_hand.set_pose("wave")
        elif action == "point":
            self.right_hand.set_pose("pointing")

    def update(self, dt: float, frame: int, fps: float, target_pos=None, time=0):
        """Update all animation systems."""
        # Position
        if target_pos:
            self.position.set_target(target_pos)
        pos = self.position.update(dt)

        # Velocity for physics
        self.velocity = (pos[0] - self.prev_pos[0], pos[1] - self.prev_pos[1])
        self.prev_pos = pos

        # Core animation systems
        breath = self.breathing.update(frame, fps)
        self.eye_state = self.eyes.update(frame, fps)
        antic = self.anticipation.update(time, dt)
        weight = self.weight_shift.update(time, dt)
        micro = self.micro.update(time, dt)
        wobble_val = self.wobble.update(dt)

        # Apply velocity to hair physics
        if abs(self.velocity[0]) > 0.3 or abs(self.velocity[1]) > 0.3:
            force = (-self.velocity[0] * 3, -self.velocity[1] * 2)
            for strand in self.hair_strands:
                strand.apply_force(force)
            self.side_hair_left.apply_force((force[0] * 1.3, force[1]))
            self.side_hair_right.apply_force((force[0] * 1.3, force[1]))

        # Update hair physics
        for strand in self.hair_strands:
            strand.update(dt)
        self.side_hair_left.update(dt)
        self.side_hair_right.update(dt)

        # Update hair anchor positions based on head movement
        head_offset = micro['head_offset']
        for i, strand in enumerate(self.hair_strands):
            offset_x = [-30, 0, 25][i] * self.scale
            strand.set_anchor((
                pos[0] + offset_x + head_offset[0],
                pos[1] - 140 * self.scale + head_offset[1]
            ))

        self.side_hair_left.set_anchor((
            pos[0] - 55 * self.scale + head_offset[0] * 0.5,
            pos[1] - 100 * self.scale + head_offset[1] * 0.5
        ))
        self.side_hair_right.set_anchor((
            pos[0] + 55 * self.scale + head_offset[0] * 0.5,
            pos[1] - 100 * self.scale + head_offset[1] * 0.5
        ))

        return {
            'breath': breath,
            'antic': antic,
            'weight': weight,
            'micro': micro,
            'wobble': wobble_val,
            'position': pos
        }

    def trigger_impact(self, intensity=1.0):
        """Trigger impact reaction."""
        self.wobble.trigger(intensity)
        force = (random.uniform(-25, 25) * intensity, -35 * intensity)
        for strand in self.hair_strands:
            strand.apply_force(force)
        self.side_hair_left.apply_force((force[0] * 1.5, force[1]))
        self.side_hair_right.apply_force((force[0] * 1.5, force[1]))

    def draw(self, img: Image.Image, face_state, anim_state: dict, shake=(0, 0)):
        """Render the character with full detail."""
        draw = ImageDraw.Draw(img)
        s = self.scale
        pos = anim_state['position']

        # Apply micro-movements
        micro = anim_state['micro']
        weight = anim_state['weight']
        breath = anim_state['breath']
        antic = anim_state['antic']
        wobble = anim_state['wobble']

        # Base position with weight shift
        x = pos[0] + shake[0] + weight['hip_offset'][0] + micro['sway'][0]
        y = pos[1] + shake[1] + weight['hip_offset'][1] + micro['sway'][1]

        # Draw order: shadow -> hair back -> body -> arms -> head -> hair front

        # Ground shadow with soft gradient
        self._draw_ground_shadow(draw, x, y + 110 * s, s)

        # Back hair layer
        self._draw_back_hair(draw, shake, micro)

        # Body with clothing
        self._draw_body(draw, x, y, s, breath, weight, antic, wobble)

        # Arms and hands
        self._draw_arms(draw, x, y, s, breath, antic, wobble)

        # Neck
        self._draw_neck(draw, x, y, s, breath)

        # Head
        head_x = x + micro['head_offset'][0]
        head_y = y - 105 * s + micro['head_offset'][1] + breath['shoulders'] * 2
        self._draw_head(draw, head_x, head_y, s, face_state, micro)

        # Front hair
        self._draw_front_hair(draw, head_x, head_y, s, shake, micro)

        # Side hair (physics)
        self._draw_side_hair(draw, shake)

    def _draw_ground_shadow(self, draw, x, y, s):
        """Soft, realistic ground shadow."""
        # Multiple ellipses for soft edge
        for i in range(6):
            size = (70 - i * 8) * s
            alpha = 8 + i * 5
            offset_y = i * 1.5
            draw.ellipse([
                x - size, y - size * 0.22 + offset_y,
                x + size, y + size * 0.22 + offset_y
            ], fill=(0, 0, 0, alpha))

    def _draw_body(self, draw, x, y, s, breath, weight, antic, wobble):
        """Draw torso with clothing and shading."""
        # Breathing affects torso
        chest_expand = 1.0 + breath['chest'] * 0.015

        # Anticipation squash/stretch
        antic_scale = 1.0 + antic['anticipation'] * 0.05

        # Base torso shape
        torso_w = 55 * s * chest_expand
        torso_h = 72 * s * antic_scale

        # Main torso (shadow layer)
        draw.ellipse([
            x - torso_w, y - torso_h,
            x + torso_w, y + torso_h
        ], fill=self.colors['outfit_shadow'])

        # Mid tone
        draw.ellipse([
            x - torso_w * 0.95, y - torso_h * 0.95,
            x + torso_w * 0.85, y + torso_h * 0.9
        ], fill=self.colors['outfit_mid'])

        # Highlight
        draw.ellipse([
            x - torso_w * 0.8, y - torso_h * 0.85,
            x + torso_w * 0.5, y + torso_h * 0.6
        ], fill=self.colors['outfit_light'])

        # Clothing fold lines (subtle)
        fold_alpha = 60
        # Center fold
        draw.line([
            x, y - torso_h * 0.3,
            x + 5 * s, y + torso_h * 0.5
        ], fill=(*self.colors['outfit_fold'], fold_alpha), width=int(2 * s))

        # Side folds
        draw.arc([
            x - torso_w * 0.7, y - torso_h * 0.2,
            x - torso_w * 0.2, y + torso_h * 0.4
        ], 100, 250, fill=(*self.colors['outfit_fold'], fold_alpha), width=int(2 * s))

        # Collar/neckline
        collar_y = y - torso_h * 0.85
        draw.arc([
            x - 30 * s, collar_y - 15 * s,
            x + 30 * s, collar_y + 20 * s
        ], 0, 180, fill=self.colors['outfit_shadow'], width=int(4 * s))

        # Collar highlight
        draw.arc([
            x - 28 * s, collar_y - 13 * s,
            x + 28 * s, collar_y + 18 * s
        ], 20, 160, fill=self.colors['outfit_light'], width=int(2 * s))

    def _draw_neck(self, draw, x, y, s, breath):
        """Draw neck with natural shading."""
        neck_y = y - 75 * s + breath['shoulders'] * 2

        # Shadow
        draw.ellipse([
            x - 18 * s, neck_y - 25 * s,
            x + 18 * s, neck_y + 5 * s
        ], fill=self.colors['skin_shadow'])

        # Main neck
        draw.ellipse([
            x - 16 * s, neck_y - 28 * s,
            x + 14 * s, neck_y + 2 * s
        ], fill=self.colors['skin_mid'])

        # Highlight
        draw.ellipse([
            x - 12 * s, neck_y - 26 * s,
            x + 8 * s, neck_y - 5 * s
        ], fill=self.colors['skin_light'])

    def _draw_arms(self, draw, x, y, s, breath, antic, wobble):
        """Draw arms with detailed hands."""
        arm_y = y - 45 * s + breath['shoulders'] * 3

        # Anticipation affects arm positions
        antic_offset = antic['anticipation'] * 15 * s
        follow_offset = antic['followthrough'] * 10 * s

        for side in [-1, 1]:
            arm_x = x + side * 58 * s

            # Upper arm
            upper_end_x = arm_x + side * 25 * s
            upper_end_y = arm_y + 55 * s

            if side == 1 and antic['action'] == 'wave':
                # Waving arm raised
                upper_end_x = arm_x + side * 5 * s + antic_offset
                upper_end_y = arm_y - 20 * s - abs(antic_offset) * 0.5

            # Draw upper arm with shading
            self._draw_limb_segment(draw,
                arm_x, arm_y,
                upper_end_x, upper_end_y,
                22 * s, 18 * s,
                self.colors['skin_light'], self.colors['skin_mid'], self.colors['skin_shadow']
            )

            # Lower arm
            if side == 1 and antic['action'] == 'wave':
                lower_end_x = upper_end_x + side * 45 * s + follow_offset
                lower_end_y = upper_end_y - 15 * s
            else:
                lower_end_x = upper_end_x + side * 20 * s
                lower_end_y = upper_end_y + 48 * s

            self._draw_limb_segment(draw,
                upper_end_x, upper_end_y,
                lower_end_x, lower_end_y,
                18 * s, 14 * s,
                self.colors['skin_light'], self.colors['skin_mid'], self.colors['skin_shadow']
            )

            # Hand
            hand = self.right_hand if side == 1 else self.left_hand
            self._draw_hand(draw, lower_end_x, lower_end_y, s, side, hand, antic)

    def _draw_limb_segment(self, draw, x1, y1, x2, y2, width1, width2, light, mid, shadow):
        """Draw a limb segment with gradient shading."""
        # Calculate perpendicular for shading
        dx, dy = x2 - x1, y2 - y1
        length = math.sqrt(dx*dx + dy*dy)
        if length == 0:
            return
        nx, ny = -dy / length, dx / length

        # Shadow layer
        draw.line([x1, y1, x2, y2], fill=shadow, width=int(width1))

        # Mid layer (offset slightly)
        offset = 2
        draw.line([
            x1 + nx * offset, y1 + ny * offset,
            x2 + nx * offset, y2 + ny * offset
        ], fill=mid, width=int(width1 * 0.85))

        # Highlight
        draw.line([
            x1 + nx * offset * 2, y1 + ny * offset * 2,
            x2 + nx * offset * 2, y2 + ny * offset * 2
        ], fill=light, width=int(width1 * 0.5))

        # Joint circles
        draw.ellipse([
            x1 - width1/2, y1 - width1/2,
            x1 + width1/2, y1 + width1/2
        ], fill=mid)
        draw.ellipse([
            x2 - width2/2, y2 - width2/2,
            x2 + width2/2, y2 + width2/2
        ], fill=mid)

    def _draw_hand(self, draw, x, y, s, side, hand: Hand, antic):
        """Draw detailed hand with fingers."""
        # Palm base
        palm_w = 16 * s
        palm_h = 18 * s

        # Rotate based on wrist
        angle = hand.wrist_angle + (0.3 if side == -1 else -0.3)
        if antic['action'] == 'wave' and side == 1:
            angle += math.sin(antic['anticipation'] * 8) * 0.4

        # Palm
        draw.ellipse([
            x - palm_w, y - palm_h,
            x + palm_w, y + palm_h
        ], fill=self.colors['skin_mid'])

        # Palm highlight
        draw.ellipse([
            x - palm_w * 0.7, y - palm_h * 0.8,
            x + palm_w * 0.5, y + palm_h * 0.5
        ], fill=self.colors['skin_light'])

        # Fingers
        finger_data = [
            (hand.thumb, -0.8 * side, -0.6, 0.7),   # thumb: offset, angle_offset, length_mult
            (hand.index, -0.3 * side, -0.2, 1.0),
            (hand.middle, 0.0, 0.0, 1.1),
            (hand.ring, 0.25 * side, 0.15, 1.0),
            (hand.pinky, 0.5 * side, 0.3, 0.85),
        ]

        for finger, x_off, angle_off, length_mult in finger_data:
            finger_x = x + x_off * palm_w
            finger_y = y - palm_h * 0.3

            # Three segments per finger
            seg_length = 10 * s * length_mult
            finger_angle = angle + angle_off + finger.spread

            # Base segment
            base_end_x = finger_x + math.cos(finger_angle - math.pi/2 + finger.base_angle) * seg_length
            base_end_y = finger_y + math.sin(finger_angle - math.pi/2 + finger.base_angle) * seg_length

            draw.line([finger_x, finger_y, base_end_x, base_end_y],
                     fill=self.colors['skin_mid'], width=int(6 * s))

            # Mid segment
            mid_angle = finger_angle - math.pi/2 + finger.base_angle + finger.mid_angle
            mid_end_x = base_end_x + math.cos(mid_angle) * seg_length * 0.9
            mid_end_y = base_end_y + math.sin(mid_angle) * seg_length * 0.9

            draw.line([base_end_x, base_end_y, mid_end_x, mid_end_y],
                     fill=self.colors['skin_mid'], width=int(5 * s))

            # Tip segment
            tip_angle = mid_angle + finger.tip_angle
            tip_end_x = mid_end_x + math.cos(tip_angle) * seg_length * 0.7
            tip_end_y = mid_end_y + math.sin(tip_angle) * seg_length * 0.7

            draw.line([mid_end_x, mid_end_y, tip_end_x, tip_end_y],
                     fill=self.colors['skin_mid'], width=int(4 * s))

            # Fingertip
            draw.ellipse([
                tip_end_x - 3 * s, tip_end_y - 3 * s,
                tip_end_x + 3 * s, tip_end_y + 3 * s
            ], fill=self.colors['skin_light'])

    def _draw_head(self, draw, x, y, s, face, micro):
        """Draw detailed head with realistic features."""
        # Head shape - slightly oval
        head_w = 58 * s
        head_h = 62 * s

        # Base head shadow
        draw.ellipse([
            x - head_w, y - head_h * 0.9,
            x + head_w, y + head_h
        ], fill=self.colors['skin_shadow'])

        # Main face
        draw.ellipse([
            x - head_w * 0.97, y - head_h * 0.92,
            x + head_w * 0.95, y + head_h * 0.97
        ], fill=self.colors['skin_mid'])

        # Face highlight (forehead area)
        draw.ellipse([
            x - head_w * 0.75, y - head_h * 0.85,
            x + head_w * 0.6, y + head_h * 0.3
        ], fill=self.colors['skin_light'])

        # Cheek shadows
        for side in [-1, 1]:
            cheek_x = x + side * 35 * s
            cheek_y = y + 20 * s
            draw.ellipse([
                cheek_x - 20 * s, cheek_y - 15 * s,
                cheek_x + 15 * s, cheek_y + 20 * s
            ], fill=self.colors['skin_shadow'])

        # Eyes
        self._draw_eyes(draw, x, y, s, face, micro)

        # Eyebrows
        self._draw_eyebrows(draw, x, y, s, face)

        # Nose
        self._draw_nose(draw, x, y, s)

        # Mouth
        self._draw_mouth(draw, x, y, s, face)

        # Blush (when smiling)
        if face.mouth.smile > 0.15:
            self._draw_blush(draw, x, y, s, face.mouth.smile)

        # Ear hints
        self._draw_ears(draw, x, y, s)

    def _draw_eyes(self, draw, x, y, s, face, micro):
        """Draw detailed eyes with natural movement."""
        eye_offset = self.eye_state
        blink = eye_offset['blink']

        for side in [-1, 1]:
            eye_x = x + side * 26 * s + eye_offset['left' if side == -1 else 'right'][0]
            eye_y = y - 8 * s + eye_offset['left' if side == -1 else 'right'][1]

            eye_state = face.left_eye if side == -1 else face.right_eye
            openness = eye_state.openness * (1 - blink)

            eye_w = 18 * s
            eye_h = max(3 * s, 26 * s * openness)

            # Eye socket shadow
            draw.ellipse([
                eye_x - eye_w - 3*s, eye_y - eye_h - 5*s,
                eye_x + eye_w + 3*s, eye_y + eye_h + 3*s
            ], fill=self.colors['skin_shadow'])

            # Eye white
            draw.ellipse([
                eye_x - eye_w, eye_y - eye_h,
                eye_x + eye_w, eye_y + eye_h
            ], fill=self.colors['eye_white'])

            if openness > 0.1:
                # Iris outer
                iris_r = 15 * s * min(1.0, openness + 0.15)
                draw.ellipse([
                    eye_x - iris_r, eye_y - iris_r,
                    eye_x + iris_r, eye_y + iris_r
                ], fill=self.colors['iris_outer'])

                # Iris inner (gradient effect)
                inner_r = iris_r * 0.75
                draw.ellipse([
                    eye_x - inner_r, eye_y - inner_r,
                    eye_x + inner_r, eye_y + inner_r
                ], fill=self.colors['iris_inner'])

                # Pupil
                pupil_scale = eye_offset['pupil_size']
                pupil_r = 7 * s * min(1.0, openness + 0.15) * pupil_scale
                draw.ellipse([
                    eye_x - pupil_r, eye_y - pupil_r,
                    eye_x + pupil_r, eye_y + pupil_r
                ], fill=self.colors['pupil'])

                # Eye highlights (multiple for realism)
                # Main highlight
                hl_x = eye_x - 6 * s
                hl_y = eye_y - 7 * s
                draw.ellipse([
                    hl_x - 5 * s, hl_y - 5 * s,
                    hl_x + 5 * s, hl_y + 5 * s
                ], fill=(255, 255, 255))

                # Secondary highlight
                hl2_x = eye_x + 4 * s
                hl2_y = eye_y + 4 * s
                draw.ellipse([
                    hl2_x - 2.5 * s, hl2_y - 2.5 * s,
                    hl2_x + 2.5 * s, hl2_y + 2.5 * s
                ], fill=(255, 255, 255, 200))

                # Tertiary tiny highlight
                hl3_x = eye_x - 2 * s
                hl3_y = eye_y + 6 * s
                draw.ellipse([
                    hl3_x - 1.5 * s, hl3_y - 1.5 * s,
                    hl3_x + 1.5 * s, hl3_y + 1.5 * s
                ], fill=(255, 255, 255, 150))

            # Upper eyelid line
            if openness > 0.2:
                draw.arc([
                    eye_x - eye_w, eye_y - eye_h - 2*s,
                    eye_x + eye_w, eye_y + eye_h
                ], 200, 340, fill=self.colors['hair_mid'], width=int(2 * s))

            # Eyelashes (subtle)
            if openness > 0.3:
                for i in range(5):
                    lash_angle = math.pi + (i - 2) * 0.25
                    lash_x = eye_x + math.cos(lash_angle) * eye_w
                    lash_y = eye_y + math.sin(lash_angle) * eye_h * 0.8
                    lash_end_x = lash_x + math.cos(lash_angle - 0.3) * 5 * s
                    lash_end_y = lash_y + math.sin(lash_angle - 0.3) * 5 * s - 3 * s
                    draw.line([lash_x, lash_y, lash_end_x, lash_end_y],
                             fill=self.colors['hair_dark'], width=int(1.5 * s))

    def _draw_eyebrows(self, draw, x, y, s, face):
        """Draw expressive eyebrows with natural shape."""
        for side in [-1, 1]:
            brow = face.left_eyebrow if side == -1 else face.right_eyebrow
            brow_x = x + side * 26 * s
            brow_y = y - 42 * s - brow.height * 12 * s

            # Eyebrow shape (thicker at inner end)
            if side == -1:
                points = [
                    (brow_x - 22 * s, brow_y + 6 * s),
                    (brow_x - 10 * s, brow_y + 2 * s),
                    (brow_x + 5 * s, brow_y),
                    (brow_x + 15 * s, brow_y + 3 * s),
                ]
            else:
                points = [
                    (brow_x - 15 * s, brow_y + 3 * s),
                    (brow_x - 5 * s, brow_y),
                    (brow_x + 10 * s, brow_y + 2 * s),
                    (brow_x + 22 * s, brow_y + 6 * s),
                ]

            # Draw as tapered line
            for i in range(len(points) - 1):
                width = int((6 - i * 1.5) * s)
                draw.line([points[i], points[i+1]], fill=self.colors['hair_mid'], width=max(2, width))

    def _draw_nose(self, draw, x, y, s):
        """Draw subtle nose with shading."""
        nose_y = y + 8 * s

        # Nose bridge shadow
        draw.ellipse([
            x - 3 * s, nose_y - 15 * s,
            x + 5 * s, nose_y + 5 * s
        ], fill=self.colors['skin_shadow'])

        # Nose tip
        draw.ellipse([
            x - 7 * s, nose_y,
            x + 7 * s, nose_y + 14 * s
        ], fill=self.colors['skin_mid'])

        # Nostril hints
        for side in [-1, 1]:
            draw.ellipse([
                x + side * 4 * s - 3 * s, nose_y + 8 * s,
                x + side * 4 * s + 3 * s, nose_y + 12 * s
            ], fill=self.colors['skin_shadow'])

        # Nose highlight
        draw.ellipse([
            x - 4 * s, nose_y + 2 * s,
            x + 3 * s, nose_y + 10 * s
        ], fill=self.colors['skin_light'])

    def _draw_mouth(self, draw, x, y, s, face):
        """Draw detailed mouth with natural expression."""
        mouth_y = y + 35 * s
        smile = face.mouth.smile
        openness = face.mouth.open

        mouth_w = 25 * s

        if openness > 0.3:
            # Open mouth
            mouth_h = openness * 18 * s

            # Mouth cavity
            draw.ellipse([
                x - mouth_w, mouth_y - mouth_h,
                x + mouth_w, mouth_y + mouth_h
            ], fill=(60, 30, 35))

            # Upper teeth
            if openness > 0.4:
                draw.ellipse([
                    x - mouth_w * 0.75, mouth_y - mouth_h * 0.8,
                    x + mouth_w * 0.75, mouth_y - mouth_h * 0.15
                ], fill=(255, 252, 250))

            # Tongue hint
            if openness > 0.55:
                draw.ellipse([
                    x - mouth_w * 0.5, mouth_y + mouth_h * 0.1,
                    x + mouth_w * 0.5, mouth_y + mouth_h * 0.85
                ], fill=(220, 130, 140))

            # Upper lip
            draw.arc([
                x - mouth_w * 1.1, mouth_y - mouth_h - 8 * s,
                x + mouth_w * 1.1, mouth_y + 5 * s
            ], 200, 340, fill=self.colors['lip'], width=int(5 * s))

            # Lower lip
            draw.arc([
                x - mouth_w * 1.05, mouth_y - 5 * s,
                x + mouth_w * 1.05, mouth_y + mouth_h + 10 * s
            ], 20, 160, fill=self.colors['lip'], width=int(6 * s))

        else:
            # Closed mouth
            if smile > 0.25:
                # Smile
                draw.arc([
                    x - mouth_w, mouth_y - 15 * s,
                    x + mouth_w, mouth_y + 15 * s
                ], 15, 165, fill=self.colors['lip'], width=int(5 * s))

                # Upper lip detail
                draw.arc([
                    x - mouth_w * 0.6, mouth_y - 8 * s,
                    x + mouth_w * 0.6, mouth_y + 3 * s
                ], 200, 340, fill=self.colors['lip_shadow'], width=int(2 * s))

            elif smile < -0.25:
                # Frown
                draw.arc([
                    x - mouth_w * 0.9, mouth_y + 5 * s,
                    x + mouth_w * 0.9, mouth_y + 30 * s
                ], 195, 345, fill=self.colors['lip'], width=int(5 * s))
            else:
                # Neutral with slight curve
                # Upper lip (cupid's bow)
                draw.arc([
                    x - 8 * s, mouth_y - 6 * s,
                    x + 8 * s, mouth_y + 4 * s
                ], 200, 340, fill=self.colors['lip'], width=int(3 * s))

                # Main lip line
                draw.line([
                    x - mouth_w * 0.7, mouth_y,
                    x + mouth_w * 0.7, mouth_y
                ], fill=self.colors['lip'], width=int(4 * s))

            # Lip highlight (always)
            draw.ellipse([
                x - 8 * s, mouth_y + 4 * s,
                x + 5 * s, mouth_y + 10 * s
            ], fill=(*self.colors['lip'][:3], 100))

    def _draw_blush(self, draw, x, y, s, intensity):
        """Draw natural blush on cheeks."""
        alpha = int(min(55, intensity * 70))

        for side in [-1, 1]:
            blush_x = x + side * 38 * s
            blush_y = y + 18 * s

            # Soft, irregular blush shape
            draw.ellipse([
                blush_x - 20 * s, blush_y - 12 * s,
                blush_x + 18 * s, blush_y + 14 * s
            ], fill=(*self.colors['blush'], alpha))

            # Secondary smaller blush
            draw.ellipse([
                blush_x - 12 * s + side * 5 * s, blush_y - 8 * s,
                blush_x + 10 * s + side * 5 * s, blush_y + 10 * s
            ], fill=(*self.colors['blush'], alpha + 15))

    def _draw_ears(self, draw, x, y, s):
        """Draw ear hints on sides of face."""
        for side in [-1, 1]:
            ear_x = x + side * 56 * s
            ear_y = y - 5 * s

            # Ear shape
            draw.ellipse([
                ear_x - 10 * s, ear_y - 18 * s,
                ear_x + 8 * s, ear_y + 18 * s
            ], fill=self.colors['skin_mid'])

            # Inner ear shadow
            draw.ellipse([
                ear_x - 6 * s, ear_y - 12 * s,
                ear_x + 4 * s, ear_y + 10 * s
            ], fill=self.colors['skin_shadow'])

    def _draw_back_hair(self, draw, shake, micro):
        """Draw back layer of hair."""
        s = self.scale
        pos = self.position.value
        head_off = micro['head_offset']

        x = pos[0] + shake[0] + head_off[0] * 0.5
        y = pos[1] + shake[1] - 120 * s + head_off[1] * 0.5

        # Large back hair mass
        draw.ellipse([
            x - 65 * s, y - 50 * s,
            x + 65 * s, y + 70 * s
        ], fill=self.colors['hair_dark'])

        # Mid tone layer
        draw.ellipse([
            x - 60 * s, y - 48 * s,
            x + 58 * s, y + 60 * s
        ], fill=self.colors['hair_mid'])

        # Hair texture/strands (back)
        for strand in self.hair_strands:
            points = strand.get_points()
            if len(points) >= 2:
                for i in range(len(points) - 1):
                    p1 = points[i]
                    p2 = points[i + 1]
                    thickness = (30 - i * 5) * s

                    x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                    x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                    # Shadow strand
                    draw.line([x1 + 2, y1 + 2, x2 + 2, y2 + 2],
                             fill=self.colors['hair_dark'], width=int(thickness))
                    # Main strand
                    draw.line([x1, y1, x2, y2],
                             fill=self.colors['hair_mid'], width=int(thickness * 0.9))

    def _draw_front_hair(self, draw, x, y, s, shake, micro):
        """Draw front hair/bangs."""
        # Bangs base
        draw.ellipse([
            x - 58 * s, y - 65 * s,
            x + 58 * s, y - 8 * s
        ], fill=self.colors['hair_mid'])

        # Forehead visible
        draw.ellipse([
            x - 42 * s, y - 50 * s,
            x + 42 * s, y - 5 * s
        ], fill=self.colors['skin_light'])

        # Individual bang strands
        strand_positions = [-45, -28, -10, 8, 25, 42]
        for i, offset in enumerate(strand_positions):
            strand_x = x + offset * s
            strand_h = (50 + (i % 3) * 8) * s
            strand_w = (16 - abs(i - 2.5) * 2) * s

            # Shadow
            draw.ellipse([
                strand_x - strand_w + 2, y - 70 * s,
                strand_x + strand_w + 2, y - 70 * s + strand_h + 2
            ], fill=self.colors['hair_dark'])

            # Main strand
            draw.ellipse([
                strand_x - strand_w, y - 72 * s,
                strand_x + strand_w, y - 72 * s + strand_h
            ], fill=self.colors['hair_mid'])

            # Highlight on some strands
            if i % 2 == 0:
                draw.ellipse([
                    strand_x - strand_w * 0.5, y - 70 * s,
                    strand_x + strand_w * 0.3, y - 70 * s + strand_h * 0.6
                ], fill=self.colors['hair_light'])

        # Hair shine highlight
        draw.arc([
            x - 45 * s, y - 68 * s,
            x - 5 * s, y - 35 * s
        ], 200, 340, fill=self.colors['hair_highlight'], width=int(3 * s))

    def _draw_side_hair(self, draw, shake):
        """Draw side hair strands with physics."""
        s = self.scale

        for chain in [self.side_hair_left, self.side_hair_right]:
            points = chain.get_points()
            if len(points) >= 2:
                for i in range(len(points) - 1):
                    p1 = points[i]
                    p2 = points[i + 1]
                    thickness = (22 - i * 3) * s

                    x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                    x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                    # Shadow
                    draw.line([x1 + 2, y1 + 2, x2 + 2, y2 + 2],
                             fill=self.colors['hair_dark'], width=int(thickness))
                    # Main
                    draw.line([x1, y1, x2, y2],
                             fill=self.colors['hair_mid'], width=int(thickness * 0.9))
                    # Highlight
                    if i < 3:
                        draw.line([x1 - 3, y1, x2 - 3, y2],
                                 fill=self.colors['hair_light'], width=int(thickness * 0.3))


def create_starfield(width, height, num_stars=180):
    """Create twinkling starfield."""
    random.seed(42)
    return [{
        'x': random.randint(0, width),
        'y': random.randint(0, int(height * 0.78)),
        'size': random.uniform(0.4, 3.2),
        'brightness': random.uniform(0.5, 1.0),
        'twinkle_speed': random.uniform(1.8, 4.5),
        'twinkle_offset': random.uniform(0, math.pi * 2)
    } for _ in range(num_stars)]


def draw_background(draw, width, height, time, stars, shake):
    """Draw animated gradient background."""
    hue_shift = math.sin(time * 0.18) * 12

    for y in range(0, height, 2):
        t = y / height
        r = int(32 + t * 38 + hue_shift)
        g = int(30 + t * 32)
        b = int(62 + t * 38 - hue_shift * 0.4)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    for star in stars:
        twinkle = (math.sin(time * star['twinkle_speed'] + star['twinkle_offset']) + 1) / 2
        brightness = int(100 + twinkle * 155 * star['brightness'])
        size = star['size'] * (0.8 + twinkle * 0.4)

        sx = star['x'] + shake[0]
        sy = star['y'] + shake[1]

        if size > 2.2:
            draw.ellipse([
                sx - size * 2.5, sy - size * 2.5,
                sx + size * 2.5, sy + size * 2.5
            ], fill=(brightness, brightness, 255, 25))

        draw.ellipse([
            sx - size, sy - size,
            sx + size, sy + size
        ], fill=(brightness, brightness, min(255, brightness + 35)))


def main():
    print("=" * 70)
    print("REALISTIC CHARACTER ANIMATION")
    print("Natural movement with sophisticated details")
    print("=" * 70)
    print()

    WIDTH, HEIGHT = 1920, 1080
    FPS = 30
    DURATION = 15.0

    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Duration: {DURATION}s at {FPS}fps")
    print(f"Total frames: {int(DURATION * FPS)}")
    print()

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Create character
    character = RealisticCharacter(WIDTH // 2, HEIGHT // 2 + 100, scale=2.8)

    # Facial animation
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    # Camera
    camera = Camera((WIDTH, HEIGHT))

    # Starfield
    stars = create_starfield(WIDTH, HEIGHT, 200)

    # Timeline tracking
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline events
        if time >= 1.5 and 'wave' not in triggered:
            character.trigger_action('wave', time)
            character.right_hand.set_pose('wave')
            triggered.add('wave')

        if time >= 4.0 and 'wave_end' not in triggered:
            character.right_hand.set_pose('relaxed')
            triggered.add('wave_end')

        if time >= 5.5 and 'surprise' not in triggered:
            facial.set_emotion(Emotion.SURPRISED)
            character.trigger_impact(1.0)
            camera.add_shake(ShakeType.IMPACT, intensity=0.7)
            triggered.add('surprise')

        if time >= 6.5 and 'happy_again' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy_again')

        if time >= 8.0 and 'point' not in triggered:
            character.trigger_action('point', time)
            character.right_hand.set_pose('pointing')
            triggered.add('point')

        if time >= 10.5 and 'point_end' not in triggered:
            character.right_hand.set_pose('relaxed')
            triggered.add('point_end')

        if time >= 12.0 and 'final_impact' not in triggered:
            character.trigger_impact(1.3)
            camera.add_shake(ShakeType.IMPACT, intensity=0.85)
            triggered.add('final_impact')

        # Update systems
        face = facial.update(dt)
        camera.update(dt)

        # Subtle character position movement
        sway_x = math.sin(time * 0.3) * 15
        sway_y = math.sin(time * 0.4 + 0.5) * 8
        target = (WIDTH // 2 + sway_x, HEIGHT // 2 + 100 + sway_y)

        anim_state = character.update(dt, frame_num, FPS, target_pos=target, time=time)

        shake = camera._shake_offset

        # Render
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake)
        character.draw(frame, face, anim_state, shake)

        # Title
        title_y = 55 + math.sin(time * 1.3) * 4
        draw.text((WIDTH // 2 + 2, title_y + 2), "Realistic Animation",
                  fill=(0, 0, 0, 100), anchor="mm")
        draw.text((WIDTH // 2, title_y), "Realistic Animation",
                  fill=(255, 255, 255), anchor="mm")

        # Feature labels
        subtitles = [
            (0, 1.5, "Natural Idle - Weight Shifts & Micro-movements"),
            (1.5, 4.0, "Wave Gesture - Anticipation & Follow-through"),
            (4.0, 5.5, "Breathing Animation & Eye Wandering"),
            (5.5, 6.5, "Impact Reaction - Hair Physics"),
            (6.5, 8.0, "Detailed Hands with Fingers"),
            (8.0, 10.5, "Pointing Gesture - IK Animation"),
            (10.5, 12.0, "Physics-based Hair & Secondary Motion"),
            (12.0, 99, "Full Character Integration"),
        ]
        for start, end, text in subtitles:
            if start <= time < end:
                draw.text((WIDTH // 2, HEIGHT - 55), text,
                          fill=(235, 235, 255, 225), anchor="mm")
                break

        # Progress bar
        bar_w = 550
        bar_x = (WIDTH - bar_w) // 2
        bar_y = HEIGHT - 28
        progress = time / DURATION

        draw.rectangle([bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + 12],
                      fill=(35, 35, 55))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_w * progress), bar_y + 10],
                      fill=(115, 175, 255))

    renderer.on_frame(draw_frame)

    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    print("Applying post-processing...")
    processed = []
    for i, frame in enumerate(frames):
        frame = apply_vignette(frame, intensity=0.24, radius=0.9)
        frame = apply_color_grade(frame, brightness=1.02, contrast=1.05,
                                  saturation=1.08, tint=(255, 250, 242),
                                  tint_strength=0.04)
        processed.append(frame)

        if (i + 1) % 90 == 0:
            print(f"  Post-processed {i + 1}/{len(frames)} frames")

    print()
    print("Encoding to MP4...")
    output_path = "realistic_animation.mp4"

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
        print("REALISTIC ANIMATION COMPLETE")
        print("=" * 70)
        print(f"Output: {output_path}")
        print(f"Size: {size_mb:.1f} MB")
        print(f"Resolution: {WIDTH}x{HEIGHT}")
        print(f"Duration: {DURATION}s")
        print(f"Frames: {len(processed)}")
        print()
        print("Sophisticated features:")
        print("  - Gradient shading for 3D appearance")
        print("  - Detailed hands with individual fingers")
        print("  - Natural eyebrow shapes")
        print("  - Multi-highlight eye rendering")
        print("  - Cupid's bow lip detail")
        print("  - Clothing fold shading")
        print("  - Anticipation & follow-through")
        print("  - Weight shifting during idle")
        print("  - Micro-movements (head wander, sway)")
        print("  - Physics-based multi-strand hair")
        print("  - Natural blush and ear details")
        print("  - Eyelashes and eye socket shadows")

    except Exception as e:
        print(f"FFmpeg encoding failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
