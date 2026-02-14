#!/usr/bin/env python3
"""Create a short test video demonstrating the animation pipeline."""

import math
from PIL import Image, ImageDraw

from pipeline.animation import (
    # Expressions
    Emotion, FacialAnimator,
    # Motion
    MotionBlender, create_idle, create_wave,
    # Effects
    create_sparkle_emitter,
    # Camera
    Camera, ShakeType,
    # Rendering
    QuickRenderer,
)


def draw_character(draw, x, y, face, pose, scale=1.0):
    """Draw a simple animated character."""
    # Body
    body_y = y + pose.body.y * scale
    draw.ellipse([
        x - 30 * scale, body_y - 40 * scale,
        x + 30 * scale, body_y + 40 * scale
    ], fill=(100, 150, 200, 255))

    # Head
    head_x = x + pose.head.rotation * scale
    head_y = body_y - 70 * scale + pose.head.y * scale
    draw.ellipse([
        head_x - 35 * scale, head_y - 35 * scale,
        head_x + 35 * scale, head_y + 35 * scale
    ], fill=(255, 220, 180, 255))

    # Eyes
    eye_openness = (face.left_eye.openness + face.right_eye.openness) / 2
    eye_height = max(2, 12 * eye_openness) * scale

    for eye_offset in [-12, 12]:
        eye_x = head_x + eye_offset * scale
        eye_y = head_y - 5 * scale
        draw.ellipse([
            eye_x - 8 * scale, eye_y - eye_height / 2,
            eye_x + 8 * scale, eye_y + eye_height / 2
        ], fill=(255, 255, 255, 255))
        if eye_openness > 0.2:
            draw.ellipse([
                eye_x - 4 * scale, eye_y - 4 * scale,
                eye_x + 4 * scale, eye_y + 4 * scale
            ], fill=(50, 50, 50, 255))

    # Eyebrows
    brow_height = face.left_eyebrow.height * 5 * scale
    draw.line([
        head_x - 20 * scale, head_y - 18 * scale - brow_height,
        head_x - 5 * scale, head_y - 20 * scale - brow_height
    ], fill=(80, 60, 40, 255), width=int(3 * scale))
    draw.line([
        head_x + 5 * scale, head_y - 20 * scale - brow_height,
        head_x + 20 * scale, head_y - 18 * scale - brow_height
    ], fill=(80, 60, 40, 255), width=int(3 * scale))

    # Mouth
    mouth_y = head_y + 15 * scale
    smile = face.mouth.smile
    mouth_open = face.mouth.open * 8 * scale

    if mouth_open > 2:
        draw.ellipse([
            head_x - 10 * scale, mouth_y - mouth_open / 2,
            head_x + 10 * scale, mouth_y + mouth_open / 2
        ], fill=(150, 80, 80, 255))
    elif smile > 0.2:
        draw.arc([
            head_x - 12 * scale, mouth_y - 8 * scale,
            head_x + 12 * scale, mouth_y + 8 * scale
        ], 0, 180, fill=(150, 80, 80, 255), width=int(3 * scale))
    else:
        draw.line([
            head_x - 10 * scale, mouth_y,
            head_x + 10 * scale, mouth_y
        ], fill=(150, 80, 80, 255), width=int(3 * scale))

    # Arms
    arm_len = 40 * scale
    # Left arm
    left_rot = math.radians(pose.left_arm.rotation + 160)
    left_x = x - 30 * scale
    left_y = body_y - 20 * scale + pose.left_arm.y * scale
    draw.line([
        left_x, left_y,
        left_x + math.cos(left_rot) * arm_len,
        left_y + math.sin(left_rot) * arm_len
    ], fill=(255, 220, 180, 255), width=int(10 * scale))

    # Right arm
    right_rot = math.radians(-pose.right_arm.rotation + 20)
    right_x = x + 30 * scale
    right_y = body_y - 20 * scale + pose.right_arm.y * scale
    draw.line([
        right_x, right_y,
        right_x + math.cos(right_rot) * arm_len,
        right_y + math.sin(right_rot) * arm_len
    ], fill=(255, 220, 180, 255), width=int(10 * scale))


def main():
    print("Creating test video...")

    # Setup
    renderer = QuickRenderer(480, 360, fps=30)
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)
    motion = MotionBlender()
    motion.set_base_motion(create_idle())
    camera = Camera((480, 360))
    sparkles = create_sparkle_emitter(position=(240, 100))
    sparkles.emission_rate = 15

    # Track triggered events
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / 30

        # Events timeline
        if time >= 0.5 and 'wave' not in triggered:
            motion.play_overlay(create_wave(waves=2))
            triggered.add('wave')

        if time >= 2.0 and 'surprise' not in triggered:
            facial.set_emotion(Emotion.SURPRISED)
            camera.add_shake(ShakeType.IMPACT, intensity=0.6)
            triggered.add('surprise')

        if time >= 2.5 and 'happy' not in triggered:
            facial.set_emotion(Emotion.HAPPY)
            triggered.add('happy')

        # Update systems
        face = facial.update(dt)
        pose = motion.update(dt)
        camera.update(dt)
        sparkles.update(dt)

        shake = camera._shake_offset

        # Background gradient
        for y in range(0, 360, 4):
            brightness = 35 + int(y / 360 * 25)
            draw.rectangle([0, y, 480, y + 4],
                          fill=(brightness, brightness + 10, brightness + 20, 255))

        # Title
        draw.text((240 + shake[0], 30 + shake[1]), "Animation Pipeline Test",
                  fill=(255, 255, 255, 255), anchor="mm")

        # Draw sparkle particles
        for p in sparkles.particles:
            if p.life > 0:
                alpha = int(255 * p.life / sparkles.particle_life)
                px = int(p.position.x + shake[0])
                py = int(p.position.y + shake[1])
                size = max(1, int(p.size))
                draw.ellipse([px - size, py - size, px + size, py + size],
                            fill=(255, 255, 200, alpha))

        # Draw character
        char_x = 240 + shake[0]
        char_y = 220 + shake[1]
        draw_character(draw, char_x, char_y, face, pose, scale=1.5)

        # Progress indicator
        progress = time / 3.0
        bar_width = int(200 * progress)
        draw.rectangle([140, 340, 340, 350], fill=(60, 60, 80, 255))
        draw.rectangle([140, 340, 140 + bar_width, 350], fill=(100, 180, 255, 255))

    renderer.on_frame(draw_frame)

    # Render as GIF (widely viewable)
    output_gif = "test_animation.gif"
    renderer.render_gif(output_gif, duration=3.0)
    print(f"Saved: {output_gif}")

    # Also try MP4 if ffmpeg is available
    try:
        output_mp4 = "test_animation.mp4"
        renderer.render_video(output_mp4, duration=3.0)
        print(f"Saved: {output_mp4}")
    except Exception as e:
        print(f"MP4 rendering skipped (ffmpeg not available): {e}")

    print("Done!")


if __name__ == "__main__":
    main()
