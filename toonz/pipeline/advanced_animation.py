#!/usr/bin/env python3
"""Advanced animation demo showcasing sophisticated techniques.

Features:
- Skeleton-based character with IK
- Physics-based hair simulation
- Procedural eye movement with blinking
- Breathing animation
- Squash and stretch on impacts
- Inertia following for accessories
- Particle effects with physics
"""

import math
import random
from PIL import Image, ImageDraw

from pipeline.animation import (
    # Skeletal
    Skeleton, Bone, Vec2, BoneConstraint,
    # Physics
    Spring, Spring2D, PhysicsChain, BreathingAnimation,
    EyeController, SquashStretch, InertiaFollow, Wobble,
    # Expression/Motion
    Emotion, FacialAnimator,
    MotionBlender, create_idle, create_wave, create_celebrate,
    # Effects
    create_sparkle_emitter, create_confetti_emitter,
    apply_vignette, apply_color_grade,
    BezierPath, PathFollower,
    # Camera
    Camera, ShakeType,
    # Rendering
    QuickRenderer,
)
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer


FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"


class SkeletalCharacter:
    """Character with full skeletal animation and physics."""

    def __init__(self, x, y, scale=1.0):
        self.base_x = x
        self.base_y = y
        self.scale = scale

        # Color palette
        self.skin = (255, 218, 195)
        self.skin_shadow = (235, 188, 165)
        self.hair = (45, 35, 55)
        self.hair_light = (75, 60, 90)
        self.outfit = (75, 115, 175)
        self.outfit_light = (105, 150, 210)
        self.eye_color = (80, 140, 190)
        self.accessory_color = (255, 180, 100)

        # Build skeleton
        self._build_skeleton()

        # Physics systems
        self.hair_chain = PhysicsChain(
            anchor=(x, y - 120 * scale),
            segments=6,
            segment_length=18 * scale,
            gravity=(0, 180),
            damping=0.92,
            stiffness=0.85
        )

        self.ponytail = PhysicsChain(
            anchor=(x + 25 * scale, y - 100 * scale),
            segments=5,
            segment_length=22 * scale,
            gravity=(0, 150),
            damping=0.88,
            stiffness=0.8
        )

        self.earring_left = PhysicsChain(
            anchor=(x - 45 * scale, y - 80 * scale),
            segments=3,
            segment_length=8 * scale,
            gravity=(0, 200),
            damping=0.9,
            stiffness=0.95
        )

        self.earring_right = PhysicsChain(
            anchor=(x + 45 * scale, y - 80 * scale),
            segments=3,
            segment_length=8 * scale,
            gravity=(0, 200),
            damping=0.9,
            stiffness=0.95
        )

        # Procedural animation
        self.breathing = BreathingAnimation(rate=14, depth=1.0)
        self.eyes = EyeController(max_offset=8 * scale)
        self.squash = SquashStretch(intensity=0.15)
        self.wobble = Wobble(frequency=4.0, amplitude=0.08)

        # Inertia for body follow-through
        self.body_inertia = InertiaFollow(delay_frames=3, overshoot=0.15)

        # Springs for smooth movement
        self.position_spring = Spring2D(stiffness=200, damping=18, initial_position=(x, y))

        # State
        self.prev_pos = (x, y)
        self.velocity = (0, 0)

    def _build_skeleton(self):
        """Build character skeleton with proper proportions."""
        self.skeleton = Skeleton("character", Vec2(self.base_x, self.base_y))
        s = self.scale

        # Root and spine
        root = self.skeleton.add_bone("root", length=0)
        spine = self.skeleton.add_bone("spine", length=70 * s, angle=-math.pi/2, parent=root)
        chest = self.skeleton.add_bone("chest", length=50 * s, angle=0, parent=spine)
        neck = self.skeleton.add_bone("neck", length=20 * s, angle=0, parent=chest)
        head = self.skeleton.add_bone("head", length=40 * s, angle=0, parent=neck)

        # Left arm
        l_shoulder = self.skeleton.add_bone("l_shoulder", length=15 * s, angle=math.pi*0.6, parent=chest)
        l_upper_arm = self.skeleton.add_bone("l_upper_arm", length=45 * s, angle=math.pi*0.4, parent=l_shoulder,
                                              constraint=BoneConstraint(-math.pi*0.8, math.pi*0.8))
        l_lower_arm = self.skeleton.add_bone("l_lower_arm", length=40 * s, angle=0.2, parent=l_upper_arm,
                                              constraint=BoneConstraint(-2.2, 0.1))
        l_hand = self.skeleton.add_bone("l_hand", length=15 * s, angle=0, parent=l_lower_arm)

        # Right arm
        r_shoulder = self.skeleton.add_bone("r_shoulder", length=15 * s, angle=-math.pi*0.6, parent=chest)
        r_upper_arm = self.skeleton.add_bone("r_upper_arm", length=45 * s, angle=-math.pi*0.4, parent=r_shoulder,
                                              constraint=BoneConstraint(-math.pi*0.8, math.pi*0.8))
        r_lower_arm = self.skeleton.add_bone("r_lower_arm", length=40 * s, angle=-0.2, parent=r_upper_arm,
                                              constraint=BoneConstraint(-0.1, 2.2))
        r_hand = self.skeleton.add_bone("r_hand", length=15 * s, angle=0, parent=r_lower_arm)

        # Create IK chains
        self.skeleton.create_ik_chain("left_arm", ["l_upper_arm", "l_lower_arm", "l_hand"])
        self.skeleton.create_ik_chain("right_arm", ["r_upper_arm", "r_lower_arm", "r_hand"])

        self.skeleton.update()

    def update(self, dt, frame, fps, target_pos=None):
        """Update all animation systems."""
        # Update position with spring
        if target_pos:
            self.position_spring.set_target(target_pos)
        pos = self.position_spring.update(dt)

        # Calculate velocity
        self.velocity = (pos[0] - self.prev_pos[0], pos[1] - self.prev_pos[1])
        self.prev_pos = pos

        # Update skeleton position
        self.skeleton.position = Vec2(pos[0], pos[1])

        # Breathing affects skeleton
        breath = self.breathing.update(frame, fps)
        chest_bone = self.skeleton.get_bone("chest")
        if chest_bone:
            chest_bone.angle = breath['chest'] * 0.03

        # Update physics chains with character movement
        head_bone = self.skeleton.get_bone("head")
        if head_bone:
            head_pos = head_bone.get_world_end().to_tuple()
            # Hair follows head with offset
            self.hair_chain.set_anchor((head_pos[0] - 5 * self.scale, head_pos[1] - 30 * self.scale))
            self.ponytail.set_anchor((head_pos[0] + 30 * self.scale, head_pos[1] - 15 * self.scale))
            self.earring_left.set_anchor((head_pos[0] - 48 * self.scale, head_pos[1] + 5 * self.scale))
            self.earring_right.set_anchor((head_pos[0] + 48 * self.scale, head_pos[1] + 5 * self.scale))

        # Apply velocity force to hair
        if abs(self.velocity[0]) > 0.5 or abs(self.velocity[1]) > 0.5:
            force = (-self.velocity[0] * 2, -self.velocity[1] * 1.5)
            self.hair_chain.apply_force(force)
            self.ponytail.apply_force((force[0] * 1.2, force[1]))
            self.earring_left.apply_force((force[0] * 0.5, force[1] * 0.3))
            self.earring_right.apply_force((force[0] * 0.5, force[1] * 0.3))

        # Update physics
        self.hair_chain.update(dt)
        self.ponytail.update(dt)
        self.earring_left.update(dt)
        self.earring_right.update(dt)

        # Update eyes
        self.eye_state = self.eyes.update(frame, fps)

        # Update wobble
        self.wobble_value = self.wobble.update(dt)

        # Update squash/stretch
        self.squash_scale = self.squash.calculate(self.velocity, dt)

        # Update skeleton
        self.skeleton.update()

        return breath

    def trigger_impact(self, intensity=1.0):
        """Trigger impact effects."""
        self.wobble.trigger(intensity)
        # Add impulse to physics
        force = (random.uniform(-20, 20) * intensity, -30 * intensity)
        self.hair_chain.apply_force(force)
        self.ponytail.apply_force((force[0] * 1.5, force[1]))

    def reach_to(self, target, arm="right"):
        """Use IK to reach toward a target."""
        chain = "right_arm" if arm == "right" else "left_arm"
        self.skeleton.solve_ik(chain, target, iterations=15)

    def draw(self, img, face_state, pose_state, shake=(0, 0)):
        """Render the character with all effects."""
        draw = ImageDraw.Draw(img)
        s = self.scale
        pos = self.skeleton.position
        x, y = pos.x + shake[0], pos.y + shake[1]

        # Apply wobble
        wobble_offset = self.wobble_value * 10 * s

        # Ground shadow
        self._draw_shadow(draw, x, y + 100 * s, s)

        # Draw hair back layer (physics-based)
        self._draw_hair_back(draw, shake)

        # Draw body using skeleton
        self._draw_skeleton_body(draw, shake, wobble_offset)

        # Draw head and face
        head_bone = self.skeleton.get_bone("head")
        if head_bone:
            head_pos = head_bone.get_world_start()
            hx = head_pos.x + shake[0]
            hy = head_pos.y + shake[1] + wobble_offset
            self._draw_head(draw, hx, hy, face_state, s)

        # Draw hair front and physics elements
        self._draw_hair_front(draw, shake)
        self._draw_ponytail(draw, shake)
        self._draw_earrings(draw, shake)

    def _draw_shadow(self, draw, x, y, s):
        """Soft ground shadow."""
        for i in range(4):
            size = (60 - i * 12) * s
            alpha = 12 + i * 8
            draw.ellipse([
                x - size, y - size * 0.25,
                x + size, y + size * 0.25
            ], fill=(0, 0, 0, alpha))

    def _draw_skeleton_body(self, draw, shake, wobble_offset):
        """Draw body parts based on skeleton."""
        s = self.scale

        # Get bone positions
        spine = self.skeleton.get_bone("spine")
        chest = self.skeleton.get_bone("chest")

        if spine and chest:
            # Draw torso
            spine_start = spine.get_world_start()
            chest_end = chest.get_world_end()

            cx = (spine_start.x + chest_end.x) / 2 + shake[0]
            cy = (spine_start.y + chest_end.y) / 2 + shake[1] + wobble_offset

            # Main body ellipse
            draw.ellipse([
                cx - 50 * s, cy - 65 * s,
                cx + 50 * s, cy + 65 * s
            ], fill=self.outfit)

            # Highlight
            draw.ellipse([
                cx - 40 * s, cy - 55 * s,
                cx + 25 * s, cy + 35 * s
            ], fill=self.outfit_light)

        # Draw arms
        self._draw_arm(draw, "l_upper_arm", "l_lower_arm", "l_hand", shake, wobble_offset)
        self._draw_arm(draw, "r_upper_arm", "r_lower_arm", "r_hand", shake, wobble_offset)

        # Neck
        neck = self.skeleton.get_bone("neck")
        if neck:
            ns = neck.get_world_start()
            ne = neck.get_world_end()
            draw.line([
                ns.x + shake[0], ns.y + shake[1] + wobble_offset,
                ne.x + shake[0], ne.y + shake[1] + wobble_offset
            ], fill=self.skin, width=int(22 * s))

    def _draw_arm(self, draw, upper_name, lower_name, hand_name, shake, wobble_offset):
        """Draw an arm from skeleton bones."""
        s = self.scale
        upper = self.skeleton.get_bone(upper_name)
        lower = self.skeleton.get_bone(lower_name)
        hand = self.skeleton.get_bone(hand_name)

        if upper and lower and hand:
            # Upper arm
            us = upper.get_world_start()
            ue = upper.get_world_end()
            draw.line([
                us.x + shake[0], us.y + shake[1] + wobble_offset,
                ue.x + shake[0], ue.y + shake[1] + wobble_offset
            ], fill=self.skin, width=int(20 * s))

            # Lower arm
            ls = lower.get_world_start()
            le = lower.get_world_end()
            draw.line([
                ls.x + shake[0], ls.y + shake[1] + wobble_offset,
                le.x + shake[0], le.y + shake[1] + wobble_offset
            ], fill=self.skin, width=int(17 * s))

            # Elbow joint
            draw.ellipse([
                ue.x + shake[0] - 10 * s, ue.y + shake[1] + wobble_offset - 10 * s,
                ue.x + shake[0] + 10 * s, ue.y + shake[1] + wobble_offset + 10 * s
            ], fill=self.skin)

            # Hand
            hs = hand.get_world_start()
            he = hand.get_world_end()
            hand_cx = (hs.x + he.x) / 2 + shake[0]
            hand_cy = (hs.y + he.y) / 2 + shake[1] + wobble_offset
            draw.ellipse([
                hand_cx - 14 * s, hand_cy - 14 * s,
                hand_cx + 14 * s, hand_cy + 14 * s
            ], fill=self.skin)

    def _draw_hair_back(self, draw, shake):
        """Draw back layer of hair using physics chain."""
        points = self.hair_chain.get_points()
        s = self.scale

        # Draw as thick curved shape
        if len(points) >= 2:
            # Main hair mass
            for i in range(len(points) - 1):
                p1 = points[i]
                p2 = points[i + 1]

                # Thickness decreases toward tips
                thickness = (35 - i * 4) * s

                x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                # Draw segment
                draw.line([x1, y1, x2, y2], fill=self.hair, width=int(thickness))

                # Add highlight on first segments
                if i < 2:
                    draw.line([x1 - 8 * s, y1, x2 - 8 * s, y2],
                             fill=self.hair_light, width=int(thickness * 0.3))

    def _draw_hair_front(self, draw, shake):
        """Draw front bangs."""
        s = self.scale
        head = self.skeleton.get_bone("head")
        if not head:
            return

        hp = head.get_world_start()
        hx, hy = hp.x + shake[0], hp.y + shake[1]

        # Bangs
        draw.ellipse([
            hx - 55 * s, hy - 60 * s,
            hx + 55 * s, hy - 10 * s
        ], fill=self.hair)

        # Forehead showing
        draw.ellipse([
            hx - 40 * s, hy - 45 * s,
            hx + 40 * s, hy - 8 * s
        ], fill=self.skin)

        # Hair strands
        for offset in [-40, -18, 14, 35]:
            sx = hx + offset * s
            draw.ellipse([
                sx - 14 * s, hy - 65 * s,
                sx + 14 * s, hy - 22 * s
            ], fill=self.hair)

    def _draw_ponytail(self, draw, shake):
        """Draw ponytail using physics chain."""
        points = self.ponytail.get_points()
        s = self.scale

        if len(points) >= 2:
            # Draw ribbon at base
            p0 = points[0]
            draw.ellipse([
                p0[0] + shake[0] - 10 * s, p0[1] + shake[1] - 6 * s,
                p0[0] + shake[0] + 10 * s, p0[1] + shake[1] + 6 * s
            ], fill=self.accessory_color)

            # Draw ponytail segments
            for i in range(len(points) - 1):
                p1 = points[i]
                p2 = points[i + 1]

                thickness = (28 - i * 5) * s

                x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                draw.line([x1, y1, x2, y2], fill=self.hair, width=int(thickness))

                # Highlight
                if thickness > 10:
                    draw.line([x1 + 4 * s, y1, x2 + 4 * s, y2],
                             fill=self.hair_light, width=int(thickness * 0.25))

    def _draw_earrings(self, draw, shake):
        """Draw dangling earrings."""
        s = self.scale

        for chain in [self.earring_left, self.earring_right]:
            points = chain.get_points()
            if len(points) >= 2:
                # Draw chain links
                for i in range(len(points) - 1):
                    p1 = points[i]
                    p2 = points[i + 1]

                    x1, y1 = p1[0] + shake[0], p1[1] + shake[1]
                    x2, y2 = p2[0] + shake[0], p2[1] + shake[1]

                    draw.line([x1, y1, x2, y2], fill=self.accessory_color, width=int(3 * s))

                # Draw gem at end
                last = points[-1]
                gx, gy = last[0] + shake[0], last[1] + shake[1]

                # Glow
                draw.ellipse([
                    gx - 8 * s, gy - 8 * s,
                    gx + 8 * s, gy + 8 * s
                ], fill=(255, 220, 150, 80))

                # Gem
                draw.ellipse([
                    gx - 5 * s, gy - 5 * s,
                    gx + 5 * s, gy + 5 * s
                ], fill=self.accessory_color)

    def _draw_head(self, draw, x, y, face, s):
        """Draw head with expressions."""
        # Face shape
        draw.ellipse([
            x - 52 * s, y - 50 * s,
            x + 52 * s, y + 52 * s
        ], fill=self.skin)

        # Face shadow
        draw.ellipse([
            x - 50 * s, y + 12 * s,
            x + 50 * s, y + 54 * s
        ], fill=self.skin_shadow)

        # Eyes with procedural movement
        self._draw_eyes(draw, x, y, face, s)

        # Eyebrows
        self._draw_eyebrows(draw, x, y, face, s)

        # Nose
        draw.ellipse([
            x - 5 * s, y + 6 * s,
            x + 5 * s, y + 18 * s
        ], fill=self.skin_shadow)

        # Mouth
        self._draw_mouth(draw, x, y, face, s)

        # Blush
        if face.mouth.smile > 0.2:
            alpha = int(min(70, face.mouth.smile * 90))
            for bx in [-34, 34]:
                draw.ellipse([
                    x + bx * s - 18 * s, y + 14 * s,
                    x + bx * s + 18 * s, y + 30 * s
                ], fill=(255, 188, 198, alpha))

    def _draw_eyes(self, draw, x, y, face, s):
        """Draw eyes with procedural animation."""
        # Get eye offsets from controller
        left_offset = self.eye_state['left']
        right_offset = self.eye_state['right']
        blink = self.eye_state['blink']

        for side, eye, offset in [(-1, face.left_eye, left_offset), (1, face.right_eye, right_offset)]:
            eye_x = x + side * 24 * s + offset[0]
            eye_y = y - 10 * s + offset[1]

            # Openness affected by blink
            openness = eye.openness * (1 - blink)
            height = max(3, 24 * openness) * s
            width = 17 * s

            # Eye white
            draw.ellipse([
                eye_x - width, eye_y - height,
                eye_x + width, eye_y + height
            ], fill=(255, 255, 255))

            if openness > 0.1:
                # Iris
                iris_r = 14 * s * min(1.0, openness + 0.2)
                draw.ellipse([
                    eye_x - iris_r, eye_y - iris_r,
                    eye_x + iris_r, eye_y + iris_r
                ], fill=self.eye_color)

                # Pupil (size varies)
                pupil_size = self.eye_state['pupil_size']
                pupil_r = 7 * s * min(1.0, openness + 0.2) * pupil_size
                draw.ellipse([
                    eye_x - pupil_r, eye_y - pupil_r,
                    eye_x + pupil_r, eye_y + pupil_r
                ], fill=(22, 28, 40))

                # Highlights
                hl_x = eye_x - 5 * s
                hl_y = eye_y - 7 * s
                draw.ellipse([
                    hl_x - 5 * s, hl_y - 5 * s,
                    hl_x + 5 * s, hl_y + 5 * s
                ], fill=(255, 255, 255))

                hl2_x = eye_x + 4 * s
                hl2_y = eye_y + 4 * s
                draw.ellipse([
                    hl2_x - 2.5 * s, hl2_y - 2.5 * s,
                    hl2_x + 2.5 * s, hl2_y + 2.5 * s
                ], fill=(255, 255, 255, 180))

    def _draw_eyebrows(self, draw, x, y, face, s):
        """Draw expressive eyebrows."""
        for side, brow in [(-1, face.left_eyebrow), (1, face.right_eyebrow)]:
            brow_x = x + side * 24 * s
            brow_y = y - 40 * s - brow.height * 12 * s

            if side == -1:
                draw.line([
                    brow_x - 22 * s, brow_y + 4 * s,
                    brow_x + 12 * s, brow_y
                ], fill=self.hair, width=int(6 * s))
            else:
                draw.line([
                    brow_x - 12 * s, brow_y,
                    brow_x + 22 * s, brow_y + 4 * s
                ], fill=self.hair, width=int(6 * s))

    def _draw_mouth(self, draw, x, y, face, s):
        """Draw mouth."""
        mouth_y = y + 32 * s
        smile = face.mouth.smile
        openness = face.mouth.open
        width = 24 * s

        if openness > 0.3:
            height = openness * 18 * s
            draw.ellipse([
                x - width, mouth_y - height,
                x + width, mouth_y + height
            ], fill=(215, 100, 110))

            if openness > 0.4:
                draw.ellipse([
                    x - width * 0.72, mouth_y - height * 0.72,
                    x + width * 0.72, mouth_y - height * 0.12
                ], fill=(255, 255, 255))

            if openness > 0.6:
                draw.ellipse([
                    x - width * 0.42, mouth_y,
                    x + width * 0.42, mouth_y + height * 0.78
                ], fill=(230, 130, 140))
        else:
            if smile > 0.3:
                draw.arc([
                    x - width, mouth_y - 14 * s,
                    x + width, mouth_y + 14 * s
                ], 10, 170, fill=(215, 100, 110), width=int(5 * s))
            elif smile < -0.3:
                draw.arc([
                    x - width, mouth_y,
                    x + width, mouth_y + 28 * s
                ], 190, 350, fill=(215, 100, 110), width=int(5 * s))
            else:
                draw.line([
                    x - width * 0.62, mouth_y,
                    x + width * 0.62, mouth_y
                ], fill=(215, 100, 110), width=int(5 * s))


def create_starfield(width, height, num_stars=150):
    """Create twinkling starfield."""
    random.seed(42)
    return [{
        'x': random.randint(0, width),
        'y': random.randint(0, int(height * 0.75)),
        'size': random.uniform(0.5, 3.0),
        'brightness': random.uniform(0.5, 1.0),
        'twinkle_speed': random.uniform(2, 5),
        'twinkle_offset': random.uniform(0, math.pi * 2)
    } for _ in range(num_stars)]


def draw_background(draw, width, height, time, stars, shake):
    """Draw animated gradient background with stars."""
    hue_shift = math.sin(time * 0.22) * 14

    for y in range(0, height, 2):
        t = y / height
        r = int(30 + t * 40 + hue_shift)
        g = int(28 + t * 30)
        b = int(60 + t * 35 - hue_shift * 0.5)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    for star in stars:
        twinkle = (math.sin(time * star['twinkle_speed'] + star['twinkle_offset']) + 1) / 2
        brightness = int(100 + twinkle * 155 * star['brightness'])
        size = star['size'] * (0.8 + twinkle * 0.4)

        sx = star['x'] + shake[0]
        sy = star['y'] + shake[1]

        if size > 2.0:
            draw.ellipse([
                sx - size * 2.5, sy - size * 2.5,
                sx + size * 2.5, sy + size * 2.5
            ], fill=(brightness, brightness, 255, 28))

        draw.ellipse([
            sx - size, sy - size,
            sx + size, sy + size
        ], fill=(brightness, brightness, min(255, brightness + 40)))


def draw_particles(draw, emitter, shake):
    """Draw sparkle particles."""
    for p in emitter.particles:
        if p.life > 0:
            life_ratio = p.life / emitter.particle_life
            alpha = int(255 * life_ratio)
            px = int(p.position.x + shake[0])
            py = int(p.position.y + shake[1])
            size = max(1, int(p.size * (0.5 + life_ratio * 0.5)))

            for glow in [size + 8, size + 4]:
                draw.ellipse([
                    px - glow, py - glow,
                    px + glow, py + glow
                ], fill=(255, 255, 200, int(alpha * 0.2)))

            draw.ellipse([
                px - size, py - size,
                px + size, py + size
            ], fill=(255, 255, 235, alpha))


def main():
    print("=" * 65)
    print("ADVANCED ANIMATION DEMO")
    print("Skeletal IK + Physics Hair + Procedural Eyes")
    print("=" * 65)
    print()

    # Settings
    WIDTH, HEIGHT = 1920, 1080
    FPS = 30
    DURATION = 12.0

    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Duration: {DURATION}s at {FPS}fps")
    print(f"Total frames: {int(DURATION * FPS)}")
    print()

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Create character with physics
    character = SkeletalCharacter(WIDTH // 2, HEIGHT // 2 + 100, scale=3.0)

    # Animation systems
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    motion = MotionBlender()
    motion.set_base_motion(create_idle(intensity=0.6))

    camera = Camera((WIDTH, HEIGHT))

    # Particles
    sparkles = create_sparkle_emitter(position=(WIDTH // 2, 250))
    sparkles.emission_rate = 40
    sparkles.particle_size = (5, 10)

    confetti = create_confetti_emitter(position=(WIDTH // 2, 200))
    confetti.active = False

    # Starfield
    stars = create_starfield(WIDTH, HEIGHT, 200)

    # IK target path
    ik_path = BezierPath()
    ik_path.add_point((WIDTH // 2 + 300, HEIGHT // 2 - 100))
    ik_path.add_point((WIDTH // 2 + 400, HEIGHT // 2 - 200))
    ik_path.add_point((WIDTH // 2 + 350, HEIGHT // 2))
    ik_path.add_point((WIDTH // 2 + 200, HEIGHT // 2 + 50))
    ik_follower = PathFollower(ik_path, duration=3.0, loop=False)

    # Movement path for character
    move_path = BezierPath()
    cx, cy = WIDTH // 2, HEIGHT // 2 + 100
    move_path.add_point((cx, cy))
    move_path.add_point((cx - 150, cy))
    move_path.add_point((cx + 150, cy))
    move_path.add_point((cx, cy))
    move_follower = PathFollower(move_path, duration=4.0, loop=True)

    # Timeline
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline events
        if time >= 1.0 and 'wave' not in triggered:
            motion.play_overlay(create_wave(waves=2))
            triggered.add('wave')

        if time >= 3.5 and 'impact1' not in triggered:
            character.trigger_impact(1.2)
            camera.add_shake(ShakeType.IMPACT, intensity=0.9)
            facial.set_emotion(Emotion.SURPRISED)
            triggered.add('impact1')

        if time >= 4.2 and 'happy' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy')

        if time >= 5.0 and 'reach_start' not in triggered:
            ik_follower.reset()
            triggered.add('reach_start')

        if time >= 8.0 and 'celebrate' not in triggered:
            motion.play_overlay(create_celebrate())
            confetti.active = True
            confetti.burst(120)
            character.trigger_impact(0.8)
            camera.add_shake(ShakeType.VIBRATION, intensity=0.35, duration=1.8)
            triggered.add('celebrate')

        if time >= 10.0 and 'impact2' not in triggered:
            character.trigger_impact(1.5)
            camera.add_shake(ShakeType.IMPACT, intensity=1.0)
            triggered.add('impact2')

        # Update systems
        face = facial.update(dt)
        pose = motion.update(dt)
        camera.update(dt)
        sparkles.update(dt)
        confetti.update(dt)
        move_follower.update(dt)

        # Character movement
        move_pos = move_follower.position if time > 1.5 else (cx, cy)

        # Update character with physics
        breath = character.update(dt, frame_num, FPS, target_pos=move_pos)

        # IK reaching
        if 5.0 <= time < 8.0:
            ik_follower.update(dt)
            ik_target = ik_follower.position
            character.reach_to(ik_target, arm="right")

        shake = camera._shake_offset

        # === RENDER ===

        # Background
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake)

        # Sparkles (behind character)
        draw_particles(draw, sparkles, shake)

        # IK target indicator (when reaching)
        if 5.0 <= time < 8.0:
            tx, ty = ik_follower.position
            tx += shake[0]
            ty += shake[1]

            # Glow
            for r in [35, 25, 15]:
                alpha = int(60 * (35 - r) / 25)
                draw.ellipse([tx - r, ty - r, tx + r, ty + r],
                            fill=(255, 200, 100, alpha))
            draw.ellipse([tx - 8, ty - 8, tx + 8, ty + 8], fill=(255, 240, 180))

        # Character
        character.draw(frame, face, pose, shake)

        # Confetti
        for p in confetti.particles:
            if p.life > 0:
                px = int(p.position.x + shake[0])
                py = int(p.position.y + shake[1])
                sz = max(3, int(p.size))
                color = p.color[:3] + (int(255 * p.life),)
                draw.polygon([
                    (px - sz, py - sz//2),
                    (px + sz, py - sz//2),
                    (px + sz, py + sz//2),
                    (px - sz, py + sz//2)
                ], fill=color)

        # Title
        title_y = 60 + math.sin(time * 1.5) * 6
        draw.text((WIDTH // 2 + 3, title_y + 3), "Advanced Animation",
                  fill=(0, 0, 0, 100), anchor="mm")
        draw.text((WIDTH // 2, title_y), "Advanced Animation",
                  fill=(255, 255, 255), anchor="mm")

        # Feature labels
        subtitles = [
            (0, 1.0, "Physics-Based Hair & Accessories"),
            (1.0, 3.5, "Procedural Eyes + Wave"),
            (3.5, 4.2, "Impact Wobble!"),
            (4.2, 5.0, "Breathing Animation"),
            (5.0, 8.0, "Inverse Kinematics Reaching"),
            (8.0, 10.0, "Celebration with Physics"),
            (10.0, 99, "Secondary Motion"),
        ]
        for start, end, text in subtitles:
            if start <= time < end:
                draw.text((WIDTH // 2, HEIGHT - 60), text,
                          fill=(230, 230, 250, 220), anchor="mm")
                break

        # Progress bar
        bar_w = 500
        bar_x = (WIDTH - bar_w) // 2
        bar_y = HEIGHT - 30
        progress = time / DURATION

        draw.rectangle([bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + 12],
                      fill=(35, 35, 55))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_w * progress), bar_y + 10],
                      fill=(110, 170, 255))

    renderer.on_frame(draw_frame)

    # Render
    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    # Post-processing
    print("Applying post-processing...")
    processed = []
    for i, frame in enumerate(frames):
        frame = apply_vignette(frame, intensity=0.26, radius=0.88)
        frame = apply_color_grade(frame, brightness=1.02, contrast=1.06,
                                  saturation=1.12, tint=(255, 248, 235),
                                  tint_strength=0.05)
        processed.append(frame)

        if (i + 1) % 60 == 0:
            print(f"  Post-processed {i + 1}/{len(frames)} frames")

    # Encode
    print()
    print("Encoding to MP4...")
    output_path = "advanced_animation.mp4"

    try:
        ffmpeg_renderer = FFmpegRenderer(
            codec="h264",
            quality="high",
            ffmpeg_path=FFMPEG_PATH
        )

        def on_progress(progress):
            if progress.current_frame % 90 == 0:
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
        print("=" * 65)
        print("ADVANCED ANIMATION COMPLETE")
        print("=" * 65)
        print(f"Output: {output_path}")
        print(f"Size: {size_mb:.1f} MB")
        print(f"Resolution: {WIDTH}x{HEIGHT}")
        print(f"Duration: {DURATION}s")
        print(f"Frames: {len(processed)}")
        print()
        print("Features demonstrated:")
        print("  - Skeletal animation with IK reaching")
        print("  - Physics-based hair (Verlet integration)")
        print("  - Physics-based ponytail and earrings")
        print("  - Procedural eye movement with blinking")
        print("  - Breathing animation")
        print("  - Squash & stretch on impacts")
        print("  - Wobble/jiggle effects")
        print("  - Inertia follow-through")
        print("  - Particle effects")
        print("  - Camera shake")

    except Exception as e:
        print(f"FFmpeg encoding failed: {e}")
        import traceback
        traceback.print_exc()

        print("Falling back to GIF output...")
        gif_output = "advanced_animation.gif"
        processed[0].save(
            gif_output,
            save_all=True,
            append_images=processed[1:],
            duration=int(1000 / FPS),
            loop=0,
            optimize=False
        )
        print(f"Saved fallback GIF: {gif_output}")


if __name__ == "__main__":
    main()
