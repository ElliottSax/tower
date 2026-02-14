#!/usr/bin/env python3
"""Create an impressive demo video showcasing the animation pipeline."""

import math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

from pipeline.animation import (
    # Expressions
    Emotion, FacialAnimator,
    # Motion
    MotionBlender, create_idle, create_wave, create_celebrate,
    # Effects
    create_sparkle_emitter, create_confetti_emitter,
    apply_vignette, apply_glow, apply_color_grade,
    BezierPath, PathFollower,
    # Camera
    Camera, ShakeType,
    # Rendering
    QuickRenderer,
)


class Character:
    """Enhanced character with smoother rendering."""

    def __init__(self, x, y, scale=1.0):
        self.x = x
        self.y = y
        self.scale = scale
        self.skin_color = (255, 218, 185)
        self.hair_color = (60, 40, 30)
        self.shirt_color = (70, 130, 180)
        self.eye_color = (50, 100, 150)

    def draw(self, draw, face, pose, shake=(0, 0)):
        s = self.scale
        x = self.x + shake[0]
        y = self.y + shake[1] + pose.body.y * s

        # Shadow under character
        shadow_y = y + 60 * s
        draw.ellipse([
            x - 40 * s, shadow_y - 8 * s,
            x + 40 * s, shadow_y + 8 * s
        ], fill=(0, 0, 0, 40))

        # Body/Torso
        self._draw_body(draw, x, y, pose)

        # Arms (behind body layer for some poses)
        self._draw_arms(draw, x, y, pose)

        # Head
        head_x = x + pose.head.rotation * s * 0.5
        head_y = y - 75 * s + pose.head.y * s
        self._draw_head(draw, head_x, head_y, face)

    def _draw_body(self, draw, x, y, pose):
        s = self.scale

        # Torso - rounded rectangle effect with ellipses
        body_color = self.shirt_color

        # Main body
        draw.ellipse([
            x - 35 * s, y - 45 * s,
            x + 35 * s, y + 45 * s
        ], fill=body_color)

        # Shoulders
        draw.ellipse([
            x - 45 * s, y - 35 * s,
            x - 15 * s, y - 5 * s
        ], fill=body_color)
        draw.ellipse([
            x + 15 * s, y - 35 * s,
            x + 45 * s, y - 5 * s
        ], fill=body_color)

        # Neck
        neck_color = self.skin_color
        draw.ellipse([
            x - 12 * s, y - 55 * s,
            x + 12 * s, y - 35 * s
        ], fill=neck_color)

    def _draw_arms(self, draw, x, y, pose):
        s = self.scale
        skin = self.skin_color

        arm_length = 50 * s
        forearm_length = 45 * s

        # Left arm
        left_shoulder_x = x - 40 * s
        left_shoulder_y = y - 25 * s + pose.left_arm.y * s
        left_angle = math.radians(pose.left_arm.rotation + 150)
        left_elbow_x = left_shoulder_x + math.cos(left_angle) * arm_length
        left_elbow_y = left_shoulder_y + math.sin(left_angle) * arm_length

        # Upper arm
        draw.line([left_shoulder_x, left_shoulder_y, left_elbow_x, left_elbow_y],
                  fill=skin, width=int(14 * s))

        # Forearm (bends at elbow)
        forearm_angle = left_angle + math.radians(pose.left_hand.rotation * 0.5 + 20)
        left_hand_x = left_elbow_x + math.cos(forearm_angle) * forearm_length
        left_hand_y = left_elbow_y + math.sin(forearm_angle) * forearm_length
        draw.line([left_elbow_x, left_elbow_y, left_hand_x, left_hand_y],
                  fill=skin, width=int(12 * s))

        # Hand
        draw.ellipse([
            left_hand_x - 8 * s, left_hand_y - 8 * s,
            left_hand_x + 8 * s, left_hand_y + 8 * s
        ], fill=skin)

        # Right arm
        right_shoulder_x = x + 40 * s
        right_shoulder_y = y - 25 * s + pose.right_arm.y * s
        right_angle = math.radians(-pose.right_arm.rotation + 30)
        right_elbow_x = right_shoulder_x + math.cos(right_angle) * arm_length
        right_elbow_y = right_shoulder_y + math.sin(right_angle) * arm_length

        draw.line([right_shoulder_x, right_shoulder_y, right_elbow_x, right_elbow_y],
                  fill=skin, width=int(14 * s))

        forearm_angle = right_angle + math.radians(-pose.right_hand.rotation * 0.5 - 20)
        right_hand_x = right_elbow_x + math.cos(forearm_angle) * forearm_length
        right_hand_y = right_elbow_y + math.sin(forearm_angle) * forearm_length
        draw.line([right_elbow_x, right_elbow_y, right_hand_x, right_hand_y],
                  fill=skin, width=int(12 * s))

        draw.ellipse([
            right_hand_x - 8 * s, right_hand_y - 8 * s,
            right_hand_x + 8 * s, right_hand_y + 8 * s
        ], fill=skin)

    def _draw_head(self, draw, x, y, face):
        s = self.scale
        skin = self.skin_color

        # Hair (back layer)
        hair_y = y - 5 * s
        draw.ellipse([
            x - 42 * s, hair_y - 40 * s,
            x + 42 * s, hair_y + 20 * s
        ], fill=self.hair_color)

        # Face shape
        draw.ellipse([
            x - 38 * s, y - 38 * s,
            x + 38 * s, y + 38 * s
        ], fill=skin)

        # Hair (front layer - bangs)
        draw.ellipse([
            x - 40 * s, y - 45 * s,
            x + 40 * s, y - 15 * s
        ], fill=self.hair_color)

        # Forehead visible
        draw.ellipse([
            x - 30 * s, y - 35 * s,
            x + 30 * s, y - 10 * s
        ], fill=skin)

        # Eyes
        self._draw_eyes(draw, x, y, face)

        # Eyebrows
        self._draw_eyebrows(draw, x, y, face)

        # Nose (subtle)
        draw.ellipse([
            x - 4 * s, y + 2 * s,
            x + 4 * s, y + 10 * s
        ], fill=(245, 200, 175))

        # Mouth
        self._draw_mouth(draw, x, y, face)

        # Blush when happy
        if face.mouth.smile > 0.3:
            blush_alpha = int(min(80, face.mouth.smile * 100))
            draw.ellipse([
                x - 32 * s, y + 5 * s,
                x - 18 * s, y + 15 * s
            ], fill=(255, 180, 180, blush_alpha))
            draw.ellipse([
                x + 18 * s, y + 5 * s,
                x + 32 * s, y + 15 * s
            ], fill=(255, 180, 180, blush_alpha))

    def _draw_eyes(self, draw, x, y, face):
        s = self.scale

        for side, eye_state in [(-1, face.left_eye), (1, face.right_eye)]:
            eye_x = x + side * 15 * s
            eye_y = y - 8 * s

            openness = eye_state.openness
            eye_height = max(2, 14 * openness) * s
            eye_width = 12 * s

            # Eye white
            draw.ellipse([
                eye_x - eye_width, eye_y - eye_height,
                eye_x + eye_width, eye_y + eye_height
            ], fill=(255, 255, 255))

            if openness > 0.15:
                # Iris
                iris_size = 9 * s * min(1, openness + 0.3)
                draw.ellipse([
                    eye_x - iris_size, eye_y - iris_size,
                    eye_x + iris_size, eye_y + iris_size
                ], fill=self.eye_color)

                # Pupil
                pupil_size = 5 * s * min(1, openness + 0.3)
                draw.ellipse([
                    eye_x - pupil_size, eye_y - pupil_size,
                    eye_x + pupil_size, eye_y + pupil_size
                ], fill=(20, 20, 30))

                # Eye shine
                shine_x = eye_x - 3 * s
                shine_y = eye_y - 3 * s
                draw.ellipse([
                    shine_x - 2 * s, shine_y - 2 * s,
                    shine_x + 2 * s, shine_y + 2 * s
                ], fill=(255, 255, 255))

    def _draw_eyebrows(self, draw, x, y, face):
        s = self.scale

        left_height = face.left_eyebrow.height * 8 * s
        right_height = face.right_eyebrow.height * 8 * s

        # Left eyebrow
        draw.line([
            x - 25 * s, y - 22 * s - left_height,
            x - 8 * s, y - 25 * s - left_height
        ], fill=self.hair_color, width=int(4 * s))

        # Right eyebrow
        draw.line([
            x + 8 * s, y - 25 * s - right_height,
            x + 25 * s, y - 22 * s - right_height
        ], fill=self.hair_color, width=int(4 * s))

    def _draw_mouth(self, draw, x, y, face):
        s = self.scale
        mouth_y = y + 20 * s
        smile = face.mouth.smile
        openness = face.mouth.open

        mouth_width = 15 * s

        if openness > 0.3:
            # Open mouth
            mouth_height = openness * 12 * s
            draw.ellipse([
                x - mouth_width, mouth_y - mouth_height,
                x + mouth_width, mouth_y + mouth_height
            ], fill=(180, 80, 80))

            # Teeth hint
            if openness > 0.5:
                draw.ellipse([
                    x - mouth_width * 0.8, mouth_y - mouth_height * 0.6,
                    x + mouth_width * 0.8, mouth_y - mouth_height * 0.2
                ], fill=(255, 255, 255))
        else:
            # Closed mouth
            if smile > 0.2:
                # Smile
                draw.arc([
                    x - mouth_width, mouth_y - 10 * s,
                    x + mouth_width, mouth_y + 10 * s
                ], 10, 170, fill=(180, 80, 80), width=int(4 * s))
            elif smile < -0.2:
                # Frown
                draw.arc([
                    x - mouth_width, mouth_y,
                    x + mouth_width, mouth_y + 20 * s
                ], 190, 350, fill=(180, 80, 80), width=int(4 * s))
            else:
                # Neutral
                draw.line([
                    x - mouth_width * 0.7, mouth_y,
                    x + mouth_width * 0.7, mouth_y
                ], fill=(180, 80, 80), width=int(3 * s))


def draw_gradient_background(draw, width, height, color1, color2):
    """Draw a smooth gradient background."""
    for y in range(height):
        t = y / height
        r = int(color1[0] + (color2[0] - color1[0]) * t)
        g = int(color1[1] + (color2[1] - color1[1]) * t)
        b = int(color1[2] + (color2[2] - color1[2]) * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))


def draw_stars(draw, width, height, time, shake=(0, 0)):
    """Draw twinkling background stars."""
    import random
    random.seed(42)  # Consistent star positions

    for i in range(30):
        star_x = random.randint(20, width - 20) + shake[0]
        star_y = random.randint(20, height // 2) + shake[1]

        # Twinkle effect
        twinkle = (math.sin(time * 3 + i * 0.5) + 1) / 2
        alpha = int(100 + twinkle * 155)
        size = 1 + twinkle * 2

        draw.ellipse([
            star_x - size, star_y - size,
            star_x + size, star_y + size
        ], fill=(255, 255, 255, alpha))


def draw_floating_particles(draw, emitter, shake=(0, 0)):
    """Draw particles with glow effect."""
    for p in emitter.particles:
        if p.life > 0:
            life_ratio = p.life / emitter.particle_life
            alpha = int(255 * life_ratio)
            px = int(p.position.x + shake[0])
            py = int(p.position.y + shake[1])
            size = max(1, int(p.size * life_ratio))

            # Outer glow
            glow_size = size + 4
            glow_alpha = int(alpha * 0.3)
            draw.ellipse([
                px - glow_size, py - glow_size,
                px + glow_size, py + glow_size
            ], fill=(255, 255, 200, glow_alpha))

            # Core
            draw.ellipse([
                px - size, py - size,
                px + size, py + size
            ], fill=(255, 255, 220, alpha))


def draw_title(draw, text, x, y, time):
    """Draw animated title with subtle effect."""
    # Shadow
    draw.text((x + 2, y + 2), text, fill=(0, 0, 0, 100), anchor="mm")

    # Main text with slight glow cycle
    glow = (math.sin(time * 2) + 1) / 2
    brightness = int(220 + glow * 35)
    draw.text((x, y), text, fill=(brightness, brightness, 255), anchor="mm")


def main():
    print("Creating impressive demo video...")
    print("Resolution: 720p (1280x720)")
    print("Duration: 6 seconds")
    print()

    # High resolution
    WIDTH, HEIGHT = 1280, 720
    FPS = 30
    DURATION = 6.0

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)

    # Animation systems
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    motion = MotionBlender()
    motion.set_base_motion(create_idle(intensity=0.8))

    camera = Camera((WIDTH, HEIGHT))

    # Multiple particle systems
    sparkles = create_sparkle_emitter(position=(WIDTH // 2, 150))
    sparkles.emission_rate = 25

    confetti = create_confetti_emitter(position=(WIDTH // 2, 100))
    confetti.active = False

    # Path for orbiting effect
    orbit_path = BezierPath()
    cx, cy = WIDTH // 2, HEIGHT // 2 - 50
    radius = 200
    orbit_path.add_point((cx + radius, cy), control_out=(cx + radius, cy - 100))
    orbit_path.add_point((cx, cy - radius), control_in=(cx + 100, cy - radius), control_out=(cx - 100, cy - radius))
    orbit_path.add_point((cx - radius, cy), control_in=(cx - radius, cy - 100), control_out=(cx - radius, cy + 100))
    orbit_path.add_point((cx, cy + radius), control_in=(cx - 100, cy + radius), control_out=(cx + 100, cy + radius))
    orbit_path.add_point((cx + radius, cy), control_in=(cx + radius, cy + 100))

    orbiter = PathFollower(orbit_path, duration=4.0, loop=True, orient_to_path=True)

    # Character
    character = Character(WIDTH // 2, HEIGHT // 2 + 80, scale=2.2)

    # Event tracking
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Timeline events
        if time >= 0.5 and 'wave' not in triggered:
            motion.play_overlay(create_wave(waves=2))
            triggered.add('wave')

        if time >= 2.5 and 'surprised' not in triggered:
            facial.set_emotion(Emotion.SURPRISED)
            camera.add_shake(ShakeType.IMPACT, intensity=0.8)
            triggered.add('surprised')

        if time >= 3.0 and 'happy_again' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy_again')

        if time >= 4.0 and 'celebrate' not in triggered:
            motion.play_overlay(create_celebrate())
            confetti.active = True
            confetti.burst(50)
            camera.add_shake(ShakeType.VIBRATION, intensity=0.3, duration=1.0)
            triggered.add('celebrate')

        # Update all systems
        face = facial.update(dt)
        pose = motion.update(dt)
        camera.update(dt)
        sparkles.update(dt)
        confetti.update(dt)
        orbiter.update(dt)

        shake = camera._shake_offset

        # === RENDER LAYERS ===

        # 1. Background gradient
        draw_gradient_background(draw, WIDTH, HEIGHT, (25, 30, 50), (60, 40, 80))

        # 2. Stars
        draw_stars(draw, WIDTH, HEIGHT, time, shake)

        # 3. Orbit path (subtle)
        for i in range(40):
            t = i / 40
            p = orbit_path.get_point(t)
            alpha = 30 + int(20 * math.sin(time * 2 + i * 0.3))
            draw.ellipse([
                int(p[0] + shake[0]) - 2, int(p[1] + shake[1]) - 2,
                int(p[0] + shake[0]) + 2, int(p[1] + shake[1]) + 2
            ], fill=(150, 150, 200, alpha))

        # 4. Orbiting object
        orb_pos = orbiter.position
        orb_x = int(orb_pos[0] + shake[0])
        orb_y = int(orb_pos[1] + shake[1])

        # Glow
        for glow_size in [25, 18, 12]:
            glow_alpha = int(60 * (25 - glow_size) / 15)
            draw.ellipse([
                orb_x - glow_size, orb_y - glow_size,
                orb_x + glow_size, orb_y + glow_size
            ], fill=(255, 200, 100, glow_alpha))

        # Core
        draw.ellipse([orb_x - 8, orb_y - 8, orb_x + 8, orb_y + 8],
                    fill=(255, 240, 200))

        # 5. Sparkle particles (behind character)
        draw_floating_particles(draw, sparkles, shake)

        # 6. Character
        character.draw(draw, face, pose, shake)

        # 7. Confetti (in front)
        if confetti.active or len(confetti.particles) > 0:
            for p in confetti.particles:
                if p.life > 0:
                    px = int(p.position.x + shake[0])
                    py = int(p.position.y + shake[1])
                    size = max(2, int(p.size))
                    color = p.color[:3] + (int(255 * p.life),)
                    draw.rectangle([px - size, py - size // 2, px + size, py + size // 2],
                                  fill=color)

        # 8. Title
        draw_title(draw, "Animation Pipeline Demo", WIDTH // 2, 50, time)

        # 9. Subtitle based on current action
        subtitle = ""
        if time < 0.5:
            subtitle = "Idle Animation"
        elif time < 2.5:
            subtitle = "Wave Gesture"
        elif time < 3.0:
            subtitle = "Surprise!"
        elif time < 4.0:
            subtitle = "Emotions"
        else:
            subtitle = "Celebration!"

        draw.text((WIDTH // 2, HEIGHT - 40), subtitle,
                  fill=(200, 200, 220, 200), anchor="mm")

        # 10. Progress bar
        bar_width = 300
        bar_x = (WIDTH - bar_width) // 2
        bar_y = HEIGHT - 20
        progress = time / DURATION

        draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + 6],
                      fill=(40, 40, 60))
        draw.rectangle([bar_x, bar_y, bar_x + int(bar_width * progress), bar_y + 6],
                      fill=(100, 150, 255))

    renderer.on_frame(draw_frame)

    # Render frames
    print("Rendering frames...")
    frames = renderer.render_frames(DURATION)

    # Apply post-processing to each frame
    print("Applying post-processing...")
    processed_frames = []
    for i, frame in enumerate(frames):
        # Apply vignette
        frame = apply_vignette(frame, intensity=0.3, radius=0.85)

        # Subtle color grading (warm tones)
        frame = apply_color_grade(
            frame,
            brightness=1.02,
            contrast=1.05,
            saturation=1.1,
            tint=(255, 245, 230),
            tint_strength=0.08
        )

        processed_frames.append(frame)

        if (i + 1) % 30 == 0:
            print(f"  Processed {i + 1}/{len(frames)} frames")

    # Save GIF
    print("Saving GIF...")
    output_gif = "impressive_demo.gif"
    processed_frames[0].save(
        output_gif,
        save_all=True,
        append_images=processed_frames[1:],
        duration=int(1000 / FPS),
        loop=0,
        optimize=False
    )
    print(f"Saved: {output_gif}")

    print("\nDone!")
    print(f"\nOutput: {output_gif}")
    print(f"  Resolution: {WIDTH}x{HEIGHT}")
    print(f"  Duration: {DURATION}s")
    print(f"  Frames: {len(processed_frames)}")


if __name__ == "__main__":
    main()
