#!/usr/bin/env python3
"""Production video render - outputs high-quality MP4."""

import math
import random
from pathlib import Path
from PIL import Image, ImageDraw

from pipeline.animation import (
    Emotion, FacialAnimator,
    MotionBlender, create_idle, create_wave, create_celebrate,
    create_sparkle_emitter, create_confetti_emitter,
    apply_vignette, apply_color_grade,
    BezierPath, PathFollower,
    Camera, ShakeType,
    QuickRenderer,
)
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer


# FFmpeg path - using imageio_ffmpeg binary
FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"


class AnimatedCharacter:
    """Production-quality animated character."""

    def __init__(self, x, y, scale=1.0):
        self.x = x
        self.y = y
        self.scale = scale

        # Color palette - soft, appealing colors
        self.skin = (255, 220, 195)
        self.skin_shadow = (240, 195, 170)
        self.hair = (50, 40, 55)
        self.hair_highlight = (80, 65, 90)
        self.outfit = (75, 115, 175)
        self.outfit_light = (105, 150, 210)
        self.eye_color = (80, 140, 190)

    def draw(self, img, face, pose, shake=(0, 0)):
        """Render the character with all animation applied."""
        draw = ImageDraw.Draw(img)
        s = self.scale
        x = self.x + shake[0]
        y = self.y + shake[1] + pose.body.y * s

        # Ground shadow
        self._draw_shadow(draw, x, y + 95 * s, s)

        # Body
        self._draw_body(draw, x, y, pose, s)

        # Arms
        self._draw_arms(draw, x, y, pose, s)

        # Head
        head_x = x + pose.head.rotation * s * 0.3
        head_y = y - 100 * s + pose.head.y * s
        self._draw_head(draw, head_x, head_y, face, s)

    def _draw_shadow(self, draw, x, y, s):
        """Soft ground shadow."""
        for i in range(4):
            size = (55 - i * 10) * s
            alpha = 15 + i * 10
            draw.ellipse([
                x - size, y - size * 0.3,
                x + size, y + size * 0.3
            ], fill=(0, 0, 0, alpha))

    def _draw_body(self, draw, x, y, pose, s):
        """Draw torso with shading."""
        # Main body
        draw.ellipse([
            x - 48 * s, y - 58 * s,
            x + 48 * s, y + 58 * s
        ], fill=self.outfit)

        # Highlight
        draw.ellipse([
            x - 38 * s, y - 52 * s,
            x + 22 * s, y + 32 * s
        ], fill=self.outfit_light)

        # Neck
        draw.ellipse([
            x - 16 * s, y - 72 * s,
            x + 16 * s, y - 46 * s
        ], fill=self.skin)

        # Collar
        draw.arc([
            x - 28 * s, y - 58 * s,
            x + 28 * s, y - 38 * s
        ], 0, 180, fill=self.outfit_light, width=int(3 * s))

    def _draw_arms(self, draw, x, y, pose, s):
        """Draw articulated arms."""
        arm_len = 62 * s
        forearm_len = 58 * s

        for side, arm_pose in [(-1, pose.left_arm), (1, pose.right_arm)]:
            shoulder_x = x + side * 52 * s
            shoulder_y = y - 38 * s + arm_pose.y * s

            if side == -1:
                angle = math.radians(arm_pose.rotation + 145)
            else:
                angle = math.radians(-arm_pose.rotation + 35)

            elbow_x = shoulder_x + math.cos(angle) * arm_len
            elbow_y = shoulder_y + math.sin(angle) * arm_len

            # Upper arm
            self._draw_limb(draw, shoulder_x, shoulder_y, elbow_x, elbow_y,
                           int(19 * s), self.skin)

            # Forearm
            forearm_angle = angle + math.radians(side * 25)
            hand_x = elbow_x + math.cos(forearm_angle) * forearm_len
            hand_y = elbow_y + math.sin(forearm_angle) * forearm_len

            self._draw_limb(draw, elbow_x, elbow_y, hand_x, hand_y,
                           int(16 * s), self.skin)

            # Hand
            draw.ellipse([
                hand_x - 13 * s, hand_y - 13 * s,
                hand_x + 13 * s, hand_y + 13 * s
            ], fill=self.skin)

    def _draw_limb(self, draw, x1, y1, x2, y2, width, color):
        """Draw a limb segment."""
        draw.line([x1, y1, x2, y2], fill=color, width=width)
        draw.ellipse([
            x1 - width//2, y1 - width//2,
            x1 + width//2, y1 + width//2
        ], fill=color)

    def _draw_head(self, draw, x, y, face, s):
        """Draw head with facial expressions."""
        # Hair back
        draw.ellipse([
            x - 58 * s, y - 52 * s,
            x + 58 * s, y + 32 * s
        ], fill=self.hair)

        # Face
        draw.ellipse([
            x - 50 * s, y - 48 * s,
            x + 50 * s, y + 50 * s
        ], fill=self.skin)

        # Face shadow
        draw.ellipse([
            x - 48 * s, y + 12 * s,
            x + 48 * s, y + 52 * s
        ], fill=self.skin_shadow)

        # Hair bangs
        self._draw_bangs(draw, x, y, s)

        # Eyes
        self._draw_eyes(draw, x, y, face, s)

        # Eyebrows
        self._draw_eyebrows(draw, x, y, face, s)

        # Nose
        draw.ellipse([
            x - 5 * s, y + 6 * s,
            x + 5 * s, y + 16 * s
        ], fill=self.skin_shadow)

        # Mouth
        self._draw_mouth(draw, x, y, face, s)

        # Blush when happy
        if face.mouth.smile > 0.2:
            alpha = int(min(65, face.mouth.smile * 85))
            for bx in [-32, 32]:
                draw.ellipse([
                    x + bx * s - 16 * s, y + 12 * s,
                    x + bx * s + 16 * s, y + 27 * s
                ], fill=(255, 185, 195, alpha))

    def _draw_bangs(self, draw, x, y, s):
        """Draw hair bangs."""
        draw.ellipse([
            x - 54 * s, y - 58 * s,
            x + 54 * s, y - 12 * s
        ], fill=self.hair)

        # Forehead
        draw.ellipse([
            x - 38 * s, y - 42 * s,
            x + 38 * s, y - 6 * s
        ], fill=self.skin)

        # Hair strands
        for offset in [-38, -16, 12, 32]:
            strand_x = x + offset * s
            draw.ellipse([
                strand_x - 13 * s, y - 62 * s,
                strand_x + 13 * s, y - 22 * s
            ], fill=self.hair)

        # Highlight
        draw.arc([
            x - 42 * s, y - 58 * s,
            x - 12 * s, y - 32 * s
        ], 200, 340, fill=self.hair_highlight, width=int(3 * s))

    def _draw_eyes(self, draw, x, y, face, s):
        """Draw expressive eyes."""
        for side, eye in [(-1, face.left_eye), (1, face.right_eye)]:
            eye_x = x + side * 22 * s
            eye_y = y - 10 * s

            openness = eye.openness
            height = max(3, 22 * openness) * s
            width = 16 * s

            # Eye white
            draw.ellipse([
                eye_x - width, eye_y - height,
                eye_x + width, eye_y + height
            ], fill=(255, 255, 255))

            if openness > 0.1:
                # Iris
                iris_r = 13 * s * min(1.0, openness + 0.2)
                draw.ellipse([
                    eye_x - iris_r, eye_y - iris_r,
                    eye_x + iris_r, eye_y + iris_r
                ], fill=self.eye_color)

                # Pupil
                pupil_r = 7 * s * min(1.0, openness + 0.2)
                draw.ellipse([
                    eye_x - pupil_r, eye_y - pupil_r,
                    eye_x + pupil_r, eye_y + pupil_r
                ], fill=(22, 28, 38))

                # Highlights
                hl_x = eye_x - 4 * s
                hl_y = eye_y - 6 * s
                draw.ellipse([
                    hl_x - 4 * s, hl_y - 4 * s,
                    hl_x + 4 * s, hl_y + 4 * s
                ], fill=(255, 255, 255))

                hl2_x = eye_x + 3 * s
                hl2_y = eye_y + 3 * s
                draw.ellipse([
                    hl2_x - 2 * s, hl2_y - 2 * s,
                    hl2_x + 2 * s, hl2_y + 2 * s
                ], fill=(255, 255, 255, 180))

    def _draw_eyebrows(self, draw, x, y, face, s):
        """Draw eyebrows."""
        for side, brow in [(-1, face.left_eyebrow), (1, face.right_eyebrow)]:
            brow_x = x + side * 22 * s
            brow_y = y - 38 * s - brow.height * 10 * s

            if side == -1:
                draw.line([
                    brow_x - 20 * s, brow_y + 3 * s,
                    brow_x + 11 * s, brow_y
                ], fill=self.hair, width=int(5 * s))
            else:
                draw.line([
                    brow_x - 11 * s, brow_y,
                    brow_x + 20 * s, brow_y + 3 * s
                ], fill=self.hair, width=int(5 * s))

    def _draw_mouth(self, draw, x, y, face, s):
        """Draw mouth with expression."""
        mouth_y = y + 30 * s
        smile = face.mouth.smile
        openness = face.mouth.open
        width = 22 * s

        if openness > 0.3:
            height = openness * 16 * s
            draw.ellipse([
                x - width, mouth_y - height,
                x + width, mouth_y + height
            ], fill=(210, 95, 105))

            if openness > 0.4:
                draw.ellipse([
                    x - width * 0.7, mouth_y - height * 0.7,
                    x + width * 0.7, mouth_y - height * 0.1
                ], fill=(255, 255, 255))

            if openness > 0.6:
                draw.ellipse([
                    x - width * 0.4, mouth_y,
                    x + width * 0.4, mouth_y + height * 0.8
                ], fill=(225, 125, 135))
        else:
            if smile > 0.3:
                draw.arc([
                    x - width, mouth_y - 13 * s,
                    x + width, mouth_y + 13 * s
                ], 10, 170, fill=(210, 95, 105), width=int(4 * s))
            elif smile < -0.3:
                draw.arc([
                    x - width, mouth_y,
                    x + width, mouth_y + 26 * s
                ], 190, 350, fill=(210, 95, 105), width=int(4 * s))
            else:
                draw.line([
                    x - width * 0.6, mouth_y,
                    x + width * 0.6, mouth_y
                ], fill=(210, 95, 105), width=int(4 * s))


def create_starfield(width, height, num_stars=120):
    """Create twinkling stars."""
    random.seed(42)
    stars = []
    for _ in range(num_stars):
        stars.append({
            'x': random.randint(0, width),
            'y': random.randint(0, int(height * 0.75)),
            'size': random.uniform(0.5, 2.8),
            'brightness': random.uniform(0.5, 1.0),
            'twinkle_speed': random.uniform(2, 5),
            'twinkle_offset': random.uniform(0, math.pi * 2)
        })
    return stars


def draw_background(draw, width, height, time, stars, shake):
    """Draw animated gradient background with stars."""
    hue_shift = math.sin(time * 0.25) * 12

    for y in range(0, height, 2):
        t = y / height
        r = int(28 + t * 38 + hue_shift)
        g = int(32 + t * 28)
        b = int(58 + t * 32 - hue_shift * 0.5)
        draw.rectangle([0, y, width, y + 2], fill=(r, g, b))

    # Stars with twinkle
    for star in stars:
        twinkle = (math.sin(time * star['twinkle_speed'] + star['twinkle_offset']) + 1) / 2
        brightness = int(100 + twinkle * 155 * star['brightness'])
        size = star['size'] * (0.8 + twinkle * 0.4)

        sx = star['x'] + shake[0]
        sy = star['y'] + shake[1]

        if size > 1.8:
            draw.ellipse([
                sx - size * 2.5, sy - size * 2.5,
                sx + size * 2.5, sy + size * 2.5
            ], fill=(brightness, brightness, 255, 25))

        draw.ellipse([
            sx - size, sy - size,
            sx + size, sy + size
        ], fill=(brightness, brightness, min(255, brightness + 35)))


def draw_particles(draw, emitter, shake):
    """Draw sparkle particles with glow."""
    for p in emitter.particles:
        if p.life > 0:
            life_ratio = p.life / emitter.particle_life
            alpha = int(255 * life_ratio)
            px = int(p.position.x + shake[0])
            py = int(p.position.y + shake[1])
            size = max(1, int(p.size * (0.5 + life_ratio * 0.5)))

            for glow in [size + 7, size + 4]:
                glow_alpha = int(alpha * 0.2)
                draw.ellipse([
                    px - glow, py - glow,
                    px + glow, py + glow
                ], fill=(255, 255, 200, glow_alpha))

            draw.ellipse([
                px - size, py - size,
                px + size, py + size
            ], fill=(255, 255, 235, alpha))


def main():
    print("=" * 60)
    print("PRODUCTION VIDEO RENDER")
    print("=" * 60)
    print()

    # 1080p settings
    WIDTH, HEIGHT = 1920, 1080
    FPS = 30
    DURATION = 8.0

    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Duration: {DURATION}s at {FPS}fps")
    print(f"Total frames: {int(DURATION * FPS)}")
    print()

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Animation systems
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    motion = MotionBlender()
    motion.set_base_motion(create_idle(intensity=0.7))

    camera = Camera((WIDTH, HEIGHT))

    # Particles
    sparkles = create_sparkle_emitter(position=(WIDTH // 2, 220))
    sparkles.emission_rate = 35
    sparkles.particle_size = (4, 9)

    confetti = create_confetti_emitter(position=(WIDTH // 2, 180))
    confetti.active = False

    # Starfield
    stars = create_starfield(WIDTH, HEIGHT, num_stars=180)

    # Orbital path
    orbit = BezierPath()
    cx, cy = WIDTH // 2, HEIGHT // 2 - 120
    r = 300
    orbit.add_point((cx + r, cy), control_out=(cx + r, cy - 170))
    orbit.add_point((cx, cy - r), control_in=(cx + 170, cy - r), control_out=(cx - 170, cy - r))
    orbit.add_point((cx - r, cy), control_in=(cx - r, cy - 170), control_out=(cx - r, cy + 170))
    orbit.add_point((cx, cy + r), control_in=(cx - 170, cy + r), control_out=(cx + 170, cy + r))
    orbit.add_point((cx + r, cy), control_in=(cx + r, cy + 170))

    orbiter = PathFollower(orbit, duration=6.0, loop=True, orient_to_path=True)

    # Character
    character = AnimatedCharacter(WIDTH // 2, HEIGHT // 2 + 140, scale=3.2)

    # Timeline events
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline
        if time >= 0.8 and 'wave' not in triggered:
            motion.play_overlay(create_wave(waves=3))
            triggered.add('wave')

        if time >= 3.0 and 'surprise' not in triggered:
            facial.set_emotion(Emotion.SURPRISED)
            camera.add_shake(ShakeType.IMPACT, intensity=0.8)
            triggered.add('surprise')

        if time >= 3.8 and 'happy' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy')

        if time >= 5.5 and 'celebrate' not in triggered:
            motion.play_overlay(create_celebrate())
            confetti.active = True
            confetti.burst(100)
            camera.add_shake(ShakeType.VIBRATION, intensity=0.3, duration=1.5)
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

        # Background
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake)

        # Orbit path
        for i in range(70):
            t = i / 70
            p = orbit.get_point(t)
            alpha = 28 + int(16 * math.sin(time * 2 + i * 0.2))
            draw.ellipse([
                int(p[0] + shake[0]) - 3, int(p[1] + shake[1]) - 3,
                int(p[0] + shake[0]) + 3, int(p[1] + shake[1]) + 3
            ], fill=(155, 165, 205, alpha))

        # Orbiting light
        orb_pos = orbiter.position
        ox, oy = int(orb_pos[0] + shake[0]), int(orb_pos[1] + shake[1])

        for glow_r in [45, 35, 25, 15]:
            alpha = int(85 * (45 - glow_r) / 35)
            draw.ellipse([ox - glow_r, oy - glow_r, ox + glow_r, oy + glow_r],
                        fill=(255, 225, 155, alpha))
        draw.ellipse([ox - 10, oy - 10, ox + 10, oy + 10], fill=(255, 252, 235))

        # Sparkles
        draw_particles(draw, sparkles, shake)

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
        title_y = 65 + math.sin(time * 1.5) * 6
        draw.text((WIDTH // 2 + 3, title_y + 3), "Animation Pipeline",
                  fill=(0, 0, 0, 100), anchor="mm")
        draw.text((WIDTH // 2, title_y), "Animation Pipeline",
                  fill=(255, 255, 255), anchor="mm")

        # Subtitle
        subtitles = [
            (0, 0.8, "Procedural Animation"),
            (0.8, 3.0, "Wave Gesture"),
            (3.0, 3.8, "Surprise!"),
            (3.8, 5.5, "Facial Expressions"),
            (5.5, 99, "Celebration!"),
        ]
        for start, end, text in subtitles:
            if start <= time < end:
                draw.text((WIDTH // 2, HEIGHT - 65), text,
                          fill=(225, 225, 245, 210), anchor="mm")
                break

        # Progress bar
        bar_w = 450
        bar_x = (WIDTH - bar_w) // 2
        bar_y = HEIGHT - 35
        progress = time / DURATION

        draw.rectangle([bar_x - 2, bar_y - 2, bar_x + bar_w + 2, bar_y + 12],
                      fill=(35, 35, 55))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_w * progress), bar_y + 10],
                      fill=(105, 165, 255))

    renderer.on_frame(draw_frame)

    # Render frames
    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    # Post-processing
    print("Applying post-processing...")
    processed = []
    for i, frame in enumerate(frames):
        frame = apply_vignette(frame, intensity=0.28, radius=0.86)
        frame = apply_color_grade(frame, brightness=1.02, contrast=1.05,
                                  saturation=1.1, tint=(255, 250, 238),
                                  tint_strength=0.06)
        processed.append(frame)

        if (i + 1) % 60 == 0:
            print(f"  Post-processed {i + 1}/{len(frames)} frames")

    # Encode to MP4
    print()
    print("Encoding to MP4...")
    output_path = "production_demo.mp4"

    try:
        ffmpeg_renderer = FFmpegRenderer(
            codec="h264",
            quality="high",
            ffmpeg_path=FFMPEG_PATH
        )

        def on_progress(progress):
            if progress.current_frame % 60 == 0:
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
        print("=" * 60)
        print("PRODUCTION COMPLETE")
        print("=" * 60)
        print(f"Output: {output_path}")
        print(f"Size: {size_mb:.1f} MB")
        print(f"Resolution: {WIDTH}x{HEIGHT}")
        print(f"Duration: {DURATION}s")
        print(f"Frames: {len(processed)}")
        print(f"Codec: H.264 (High Quality)")

    except Exception as e:
        print(f"FFmpeg encoding failed: {e}")
        print("Falling back to GIF output...")

        gif_output = "production_demo.gif"
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
