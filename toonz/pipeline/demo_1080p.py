#!/usr/bin/env python3
"""1080p high-quality demo with enhanced visuals."""

import math
import random
from PIL import Image, ImageDraw, ImageFilter

from pipeline.animation import (
    Emotion, FacialAnimator,
    MotionBlender, create_idle, create_wave, create_celebrate,
    create_sparkle_emitter, create_confetti_emitter,
    apply_vignette, apply_color_grade,
    BezierPath, PathFollower,
    Camera, ShakeType,
    QuickRenderer,
)


class PremiumCharacter:
    """High-quality character with anti-aliased rendering."""

    def __init__(self, x, y, scale=1.0):
        self.x = x
        self.y = y
        self.scale = scale
        # Color palette
        self.skin = (255, 218, 190)
        self.skin_shadow = (235, 190, 165)
        self.hair = (45, 35, 55)
        self.hair_highlight = (75, 60, 90)
        self.outfit = (65, 105, 165)
        self.outfit_light = (95, 140, 200)
        self.eye_color = (70, 130, 180)

    def draw(self, img, face, pose, shake=(0, 0)):
        """Draw character with layered rendering for quality."""
        draw = ImageDraw.Draw(img)
        s = self.scale
        x = self.x + shake[0]
        y = self.y + shake[1] + pose.body.y * s

        # Ground shadow (soft)
        self._draw_shadow(draw, x, y + 90 * s, s)

        # Body
        self._draw_body(draw, x, y, pose, s)

        # Arms
        self._draw_arms(draw, x, y, pose, s)

        # Head
        head_x = x + pose.head.rotation * s * 0.3
        head_y = y - 95 * s + pose.head.y * s
        self._draw_head(draw, head_x, head_y, face, s)

    def _draw_shadow(self, draw, x, y, s):
        """Soft ground shadow."""
        for i in range(3):
            size = (50 - i * 8) * s
            alpha = 20 + i * 10
            draw.ellipse([
                x - size, y - size * 0.3,
                x + size, y + size * 0.3
            ], fill=(0, 0, 0, alpha))

    def _draw_body(self, draw, x, y, pose, s):
        """Draw torso with shading."""
        # Main body shape
        draw.ellipse([
            x - 45 * s, y - 55 * s,
            x + 45 * s, y + 55 * s
        ], fill=self.outfit)

        # Highlight
        draw.ellipse([
            x - 35 * s, y - 50 * s,
            x + 20 * s, y + 30 * s
        ], fill=self.outfit_light)

        # Neck
        draw.ellipse([
            x - 15 * s, y - 70 * s,
            x + 15 * s, y - 45 * s
        ], fill=self.skin)

        # Collar detail
        draw.arc([
            x - 25 * s, y - 55 * s,
            x + 25 * s, y - 35 * s
        ], 0, 180, fill=self.outfit_light, width=int(3 * s))

    def _draw_arms(self, draw, x, y, pose, s):
        """Draw articulated arms."""
        arm_len = 60 * s
        forearm_len = 55 * s

        for side, arm_pose in [(-1, pose.left_arm), (1, pose.right_arm)]:
            shoulder_x = x + side * 50 * s
            shoulder_y = y - 35 * s + arm_pose.y * s

            if side == -1:
                angle = math.radians(arm_pose.rotation + 145)
            else:
                angle = math.radians(-arm_pose.rotation + 35)

            elbow_x = shoulder_x + math.cos(angle) * arm_len
            elbow_y = shoulder_y + math.sin(angle) * arm_len

            # Upper arm
            self._draw_limb(draw, shoulder_x, shoulder_y, elbow_x, elbow_y,
                           int(18 * s), self.skin, self.skin_shadow)

            # Forearm
            forearm_angle = angle + math.radians(side * 25)
            hand_x = elbow_x + math.cos(forearm_angle) * forearm_len
            hand_y = elbow_y + math.sin(forearm_angle) * forearm_len

            self._draw_limb(draw, elbow_x, elbow_y, hand_x, hand_y,
                           int(15 * s), self.skin, self.skin_shadow)

            # Hand
            draw.ellipse([
                hand_x - 12 * s, hand_y - 12 * s,
                hand_x + 12 * s, hand_y + 12 * s
            ], fill=self.skin)

    def _draw_limb(self, draw, x1, y1, x2, y2, width, color, shadow):
        """Draw a limb with thickness."""
        draw.line([x1, y1, x2, y2], fill=color, width=width)
        # Add joint circles
        draw.ellipse([
            x1 - width//2, y1 - width//2,
            x1 + width//2, y1 + width//2
        ], fill=color)

    def _draw_head(self, draw, x, y, face, s):
        """Draw detailed head with expressions."""
        # Hair back
        draw.ellipse([
            x - 55 * s, y - 50 * s,
            x + 55 * s, y + 30 * s
        ], fill=self.hair)

        # Face
        draw.ellipse([
            x - 48 * s, y - 45 * s,
            x + 48 * s, y + 48 * s
        ], fill=self.skin)

        # Face shadow
        draw.ellipse([
            x - 45 * s, y + 10 * s,
            x + 45 * s, y + 50 * s
        ], fill=self.skin_shadow)

        # Hair front (bangs)
        self._draw_bangs(draw, x, y, s)

        # Eyes
        self._draw_eyes(draw, x, y, face, s)

        # Eyebrows
        self._draw_eyebrows(draw, x, y, face, s)

        # Nose
        draw.ellipse([
            x - 5 * s, y + 5 * s,
            x + 5 * s, y + 15 * s
        ], fill=self.skin_shadow)

        # Mouth
        self._draw_mouth(draw, x, y, face, s)

        # Blush
        if face.mouth.smile > 0.2:
            alpha = int(min(60, face.mouth.smile * 80))
            for bx in [-30, 30]:
                draw.ellipse([
                    x + bx * s - 15 * s, y + 10 * s,
                    x + bx * s + 15 * s, y + 25 * s
                ], fill=(255, 180, 190, alpha))

    def _draw_bangs(self, draw, x, y, s):
        """Draw stylized hair bangs."""
        # Main bangs
        draw.ellipse([
            x - 52 * s, y - 55 * s,
            x + 52 * s, y - 10 * s
        ], fill=self.hair)

        # Forehead showing through
        draw.ellipse([
            x - 35 * s, y - 40 * s,
            x + 35 * s, y - 5 * s
        ], fill=self.skin)

        # Hair strands
        for i, offset in enumerate([-35, -15, 10, 30]):
            strand_x = x + offset * s
            draw.ellipse([
                strand_x - 12 * s, y - 60 * s,
                strand_x + 12 * s, y - 20 * s
            ], fill=self.hair)

        # Highlights
        draw.arc([
            x - 40 * s, y - 55 * s,
            x - 10 * s, y - 30 * s
        ], 200, 340, fill=self.hair_highlight, width=int(3 * s))

    def _draw_eyes(self, draw, x, y, face, s):
        """Draw expressive anime-style eyes."""
        for side, eye in [(-1, face.left_eye), (1, face.right_eye)]:
            eye_x = x + side * 20 * s
            eye_y = y - 10 * s

            openness = eye.openness
            height = max(3, 20 * openness) * s
            width = 15 * s

            # Eye white
            draw.ellipse([
                eye_x - width, eye_y - height,
                eye_x + width, eye_y + height
            ], fill=(255, 255, 255))

            if openness > 0.1:
                # Iris
                iris_r = 12 * s * min(1.0, openness + 0.2)
                draw.ellipse([
                    eye_x - iris_r, eye_y - iris_r,
                    eye_x + iris_r, eye_y + iris_r
                ], fill=self.eye_color)

                # Pupil
                pupil_r = 6 * s * min(1.0, openness + 0.2)
                draw.ellipse([
                    eye_x - pupil_r, eye_y - pupil_r,
                    eye_x + pupil_r, eye_y + pupil_r
                ], fill=(20, 25, 35))

                # Highlight (top-left)
                hl_x = eye_x - 4 * s
                hl_y = eye_y - 5 * s
                draw.ellipse([
                    hl_x - 4 * s, hl_y - 4 * s,
                    hl_x + 4 * s, hl_y + 4 * s
                ], fill=(255, 255, 255))

                # Secondary highlight
                hl2_x = eye_x + 3 * s
                hl2_y = eye_y + 3 * s
                draw.ellipse([
                    hl2_x - 2 * s, hl2_y - 2 * s,
                    hl2_x + 2 * s, hl2_y + 2 * s
                ], fill=(255, 255, 255, 180))

    def _draw_eyebrows(self, draw, x, y, face, s):
        """Draw expressive eyebrows."""
        for side, brow in [(-1, face.left_eyebrow), (1, face.right_eyebrow)]:
            brow_x = x + side * 20 * s
            brow_y = y - 35 * s - brow.height * 10 * s

            # Thick eyebrow
            if side == -1:
                draw.line([
                    brow_x - 18 * s, brow_y + 3 * s,
                    brow_x + 10 * s, brow_y
                ], fill=self.hair, width=int(5 * s))
            else:
                draw.line([
                    brow_x - 10 * s, brow_y,
                    brow_x + 18 * s, brow_y + 3 * s
                ], fill=self.hair, width=int(5 * s))

    def _draw_mouth(self, draw, x, y, face, s):
        """Draw expressive mouth."""
        mouth_y = y + 28 * s
        smile = face.mouth.smile
        openness = face.mouth.open
        width = 20 * s

        if openness > 0.3:
            # Open mouth
            height = openness * 15 * s
            draw.ellipse([
                x - width, mouth_y - height,
                x + width, mouth_y + height
            ], fill=(200, 90, 100))

            # Teeth
            if openness > 0.4:
                draw.ellipse([
                    x - width * 0.7, mouth_y - height * 0.7,
                    x + width * 0.7, mouth_y - height * 0.1
                ], fill=(255, 255, 255))

            # Tongue hint
            if openness > 0.6:
                draw.ellipse([
                    x - width * 0.4, mouth_y,
                    x + width * 0.4, mouth_y + height * 0.8
                ], fill=(220, 120, 130))
        else:
            # Closed mouth
            if smile > 0.3:
                draw.arc([
                    x - width, mouth_y - 12 * s,
                    x + width, mouth_y + 12 * s
                ], 10, 170, fill=(200, 90, 100), width=int(4 * s))
            elif smile < -0.3:
                draw.arc([
                    x - width, mouth_y,
                    x + width, mouth_y + 25 * s
                ], 190, 350, fill=(200, 90, 100), width=int(4 * s))
            else:
                draw.line([
                    x - width * 0.6, mouth_y,
                    x + width * 0.6, mouth_y
                ], fill=(200, 90, 100), width=int(4 * s))


def create_starfield(width, height, num_stars=100):
    """Create a static starfield layer."""
    random.seed(42)
    stars = []
    for _ in range(num_stars):
        stars.append({
            'x': random.randint(0, width),
            'y': random.randint(0, int(height * 0.7)),
            'size': random.uniform(0.5, 2.5),
            'brightness': random.uniform(0.5, 1.0),
            'twinkle_speed': random.uniform(2, 5),
            'twinkle_offset': random.uniform(0, math.pi * 2)
        })
    return stars


def draw_background(draw, width, height, time, stars, shake):
    """Draw animated gradient background with stars."""
    # Animated gradient
    hue_shift = math.sin(time * 0.3) * 10

    for y in range(0, height, 2):
        t = y / height
        r = int(25 + t * 35 + hue_shift)
        g = int(30 + t * 25)
        b = int(55 + t * 30 - hue_shift * 0.5)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    # Draw stars with twinkle
    for star in stars:
        twinkle = (math.sin(time * star['twinkle_speed'] + star['twinkle_offset']) + 1) / 2
        brightness = int(100 + twinkle * 155 * star['brightness'])
        size = star['size'] * (0.8 + twinkle * 0.4)

        sx = star['x'] + shake[0]
        sy = star['y'] + shake[1]

        if size > 1.5:
            # Larger stars get a glow
            draw.ellipse([
                sx - size * 2, sy - size * 2,
                sx + size * 2, sy + size * 2
            ], fill=(brightness, brightness, 255, 30))

        draw.ellipse([
            sx - size, sy - size,
            sx + size, sy + size
        ], fill=(brightness, brightness, min(255, brightness + 30)))


def draw_particles_premium(draw, emitter, shake):
    """Draw particles with glow effect."""
    for p in emitter.particles:
        if p.life > 0:
            life_ratio = p.life / emitter.particle_life
            alpha = int(255 * life_ratio)
            px = int(p.position.x + shake[0])
            py = int(p.position.y + shake[1])
            size = max(1, int(p.size * (0.5 + life_ratio * 0.5)))

            # Outer glow
            for glow in [size + 6, size + 3]:
                glow_alpha = int(alpha * 0.2)
                draw.ellipse([
                    px - glow, py - glow,
                    px + glow, py + glow
                ], fill=(255, 255, 200, glow_alpha))

            # Core
            draw.ellipse([
                px - size, py - size,
                px + size, py + size
            ], fill=(255, 255, 230, alpha))


def main():
    print("=" * 60)
    print("1080p HIGH QUALITY DEMO")
    print("=" * 60)
    print()

    # 1080p settings
    WIDTH, HEIGHT = 1920, 1080
    FPS = 30
    DURATION = 6.0

    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Duration: {DURATION}s at {FPS}fps")
    print(f"Total frames: {int(DURATION * FPS)}")
    print()

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Initialize systems
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    motion = MotionBlender()
    motion.set_base_motion(create_idle(intensity=0.7))

    camera = Camera((WIDTH, HEIGHT))

    # Particles
    sparkles = create_sparkle_emitter(position=(WIDTH // 2, 200))
    sparkles.emission_rate = 30
    sparkles.particle_size = (4, 8)

    confetti = create_confetti_emitter(position=(WIDTH // 2, 150))
    confetti.active = False

    # Create starfield
    stars = create_starfield(WIDTH, HEIGHT, num_stars=150)

    # Orbiting light path
    orbit = BezierPath()
    cx, cy = WIDTH // 2, HEIGHT // 2 - 100
    r = 280
    orbit.add_point((cx + r, cy), control_out=(cx + r, cy - 150))
    orbit.add_point((cx, cy - r), control_in=(cx + 150, cy - r), control_out=(cx - 150, cy - r))
    orbit.add_point((cx - r, cy), control_in=(cx - r, cy - 150), control_out=(cx - r, cy + 150))
    orbit.add_point((cx, cy + r), control_in=(cx - 150, cy + r), control_out=(cx + 150, cy + r))
    orbit.add_point((cx + r, cy), control_in=(cx + r, cy + 150))

    orbiter = PathFollower(orbit, duration=5.0, loop=True, orient_to_path=True)

    # Character (scaled for 1080p)
    character = PremiumCharacter(WIDTH // 2, HEIGHT // 2 + 120, scale=3.0)

    # Events
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline
        if time >= 0.5 and 'wave' not in triggered:
            motion.play_overlay(create_wave(waves=2))
            triggered.add('wave')

        if time >= 2.5 and 'surprise' not in triggered:
            facial.set_emotion(Emotion.SURPRISED)
            camera.add_shake(ShakeType.IMPACT, intensity=0.7)
            triggered.add('surprise')

        if time >= 3.2 and 'happy' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy')

        if time >= 4.2 and 'celebrate' not in triggered:
            motion.play_overlay(create_celebrate())
            confetti.active = True
            confetti.burst(80)
            camera.add_shake(ShakeType.VIBRATION, intensity=0.25, duration=1.2)
            triggered.add('celebrate')

        # Update
        face = facial.update(dt)
        pose = motion.update(dt)
        camera.update(dt)
        sparkles.update(dt)
        confetti.update(dt)
        orbiter.update(dt)

        shake = camera._shake_offset

        # === RENDER ===

        # 1. Background
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake)

        # 2. Orbit path
        for i in range(60):
            t = i / 60
            p = orbit.get_point(t)
            alpha = 25 + int(15 * math.sin(time * 2 + i * 0.2))
            draw.ellipse([
                int(p[0] + shake[0]) - 3, int(p[1] + shake[1]) - 3,
                int(p[0] + shake[0]) + 3, int(p[1] + shake[1]) + 3
            ], fill=(150, 160, 200, alpha))

        # 3. Orbiting light
        orb_pos = orbiter.position
        ox, oy = int(orb_pos[0] + shake[0]), int(orb_pos[1] + shake[1])

        for glow_r in [40, 30, 20, 12]:
            alpha = int(80 * (40 - glow_r) / 30)
            draw.ellipse([ox - glow_r, oy - glow_r, ox + glow_r, oy + glow_r],
                        fill=(255, 220, 150, alpha))
        draw.ellipse([ox - 8, oy - 8, ox + 8, oy + 8], fill=(255, 250, 230))

        # 4. Sparkles
        draw_particles_premium(draw, sparkles, shake)

        # 5. Character
        character.draw(frame, face, pose, shake)

        # 6. Confetti
        for p in confetti.particles:
            if p.life > 0:
                px = int(p.position.x + shake[0])
                py = int(p.position.y + shake[1])
                sz = max(3, int(p.size))
                rot = p.rotation
                color = p.color[:3] + (int(255 * p.life),)

                # Rotated rectangle
                draw.polygon([
                    (px - sz, py - sz//2),
                    (px + sz, py - sz//2),
                    (px + sz, py + sz//2),
                    (px - sz, py + sz//2)
                ], fill=color)

        # 7. Title
        title_y = 60 + math.sin(time * 1.5) * 5
        draw.text((WIDTH // 2 + 3, title_y + 3), "Animation Pipeline Demo",
                  fill=(0, 0, 0, 100), anchor="mm")
        draw.text((WIDTH // 2, title_y), "Animation Pipeline Demo",
                  fill=(255, 255, 255), anchor="mm")

        # 8. Subtitle
        subtitles = [
            (0, 0.5, "Idle Animation"),
            (0.5, 2.5, "Wave Gesture"),
            (2.5, 3.2, "Surprise!"),
            (3.2, 4.2, "Happy"),
            (4.2, 99, "Celebration!"),
        ]
        for start, end, text in subtitles:
            if start <= time < end:
                draw.text((WIDTH // 2, HEIGHT - 60), text,
                          fill=(220, 220, 240, 200), anchor="mm")
                break

        # 9. Progress bar
        bar_w = 400
        bar_x = (WIDTH - bar_w) // 2
        bar_y = HEIGHT - 30
        progress = time / DURATION

        draw.rectangle([bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + 10],
                      fill=(30, 30, 50))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_w * progress), bar_y + 8],
                      fill=(100, 160, 255))

    renderer.on_frame(draw_frame)

    # Render
    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    # Post-processing
    print("Applying post-processing...")
    processed = []
    for i, frame in enumerate(frames):
        frame = apply_vignette(frame, intensity=0.25, radius=0.88)
        frame = apply_color_grade(frame, brightness=1.02, contrast=1.04,
                                  saturation=1.08, tint=(255, 248, 235),
                                  tint_strength=0.06)
        processed.append(frame)

        if (i + 1) % 60 == 0:
            print(f"  {i + 1}/{len(frames)} frames")

    # Save
    print("Saving...")
    output = "demo_1080p.gif"
    processed[0].save(output, save_all=True, append_images=processed[1:],
                     duration=int(1000 / FPS), loop=0, optimize=False)

    import os
    size_mb = os.path.getsize(output) / (1024 * 1024)
    print(f"\nOutput: {output}")
    print(f"Size: {size_mb:.1f} MB")
    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Frames: {len(processed)}")


if __name__ == "__main__":
    main()
