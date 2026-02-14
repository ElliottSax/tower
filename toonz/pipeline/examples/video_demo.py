#!/usr/bin/env python3
"""Video demo - produces actual animated video output.

This demo showcases all animation features in rendered video form:
- Facial expressions and emotions
- Motion presets (idle, gestures, etc.)
- Physics (springs, particles)
- Camera effects
- Path animation
"""

import os
import sys
import math

# Add pipeline directory to path for imports
pipeline_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, pipeline_dir)
# Also add parent to find the pipeline package
sys.path.insert(0, os.path.dirname(pipeline_dir))

from PIL import Image, ImageDraw, ImageFont

from pipeline.animation import (
    # Physics
    Spring, PhysicsChain, ChainSegment,
    # Camera
    Camera, ShakeType,
    # Effects
    ParticleEmitter, create_sparkle_emitter, create_confetti_emitter,
    apply_vignette, apply_color_grade,
    BezierPath, BezierPoint, PathFollower,
    # Expressions
    Emotion, FacialAnimator, FaceState,
    # Motion
    MotionBlender, Pose, Transform,
    create_idle, create_wave, create_celebrate, create_thinking,
    # Rendering
    QuickRenderer,
)


def draw_simple_character(draw: ImageDraw.ImageDraw, x: float, y: float,
                          face: FaceState, pose: Pose, scale: float = 1.0):
    """Draw a simple character with expression and pose."""
    # Body (affected by pose)
    body_y = y + pose.body.y * scale
    body_rot = pose.body.rotation

    # Torso
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

    # Left eye
    left_eye_x = head_x - 12 * scale
    left_eye_y = head_y - 5 * scale
    draw.ellipse([
        left_eye_x - 8 * scale, left_eye_y - eye_height / 2,
        left_eye_x + 8 * scale, left_eye_y + eye_height / 2
    ], fill=(255, 255, 255, 255))
    if eye_openness > 0.2:
        draw.ellipse([
            left_eye_x - 4 * scale, left_eye_y - 4 * scale,
            left_eye_x + 4 * scale, left_eye_y + 4 * scale
        ], fill=(50, 50, 50, 255))

    # Right eye
    right_eye_x = head_x + 12 * scale
    right_eye_y = head_y - 5 * scale
    draw.ellipse([
        right_eye_x - 8 * scale, right_eye_y - eye_height / 2,
        right_eye_x + 8 * scale, right_eye_y + eye_height / 2
    ], fill=(255, 255, 255, 255))
    if eye_openness > 0.2:
        draw.ellipse([
            right_eye_x - 4 * scale, right_eye_y - 4 * scale,
            right_eye_x + 4 * scale, right_eye_y + 4 * scale
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
        # Open mouth
        draw.ellipse([
            head_x - 10 * scale, mouth_y - mouth_open / 2,
            head_x + 10 * scale, mouth_y + mouth_open / 2
        ], fill=(150, 80, 80, 255))
    else:
        # Closed mouth (smile/neutral/frown)
        if smile > 0.2:
            # Smile
            draw.arc([
                head_x - 12 * scale, mouth_y - 8 * scale,
                head_x + 12 * scale, mouth_y + 8 * scale
            ], 0, 180, fill=(150, 80, 80, 255), width=int(3 * scale))
        elif smile < -0.2:
            # Frown
            draw.arc([
                head_x - 12 * scale, mouth_y,
                head_x + 12 * scale, mouth_y + 16 * scale
            ], 180, 360, fill=(150, 80, 80, 255), width=int(3 * scale))
        else:
            # Neutral
            draw.line([
                head_x - 10 * scale, mouth_y,
                head_x + 10 * scale, mouth_y
            ], fill=(150, 80, 80, 255), width=int(3 * scale))

    # Arms
    arm_len = 40 * scale
    # Left arm
    left_arm_rot = math.radians(pose.left_arm.rotation + 160)
    left_arm_x = x - 30 * scale
    left_arm_y = body_y - 20 * scale + pose.left_arm.y * scale
    left_arm_end_x = left_arm_x + math.cos(left_arm_rot) * arm_len
    left_arm_end_y = left_arm_y + math.sin(left_arm_rot) * arm_len
    draw.line([left_arm_x, left_arm_y, left_arm_end_x, left_arm_end_y],
              fill=(255, 220, 180, 255), width=int(10 * scale))

    # Right arm
    right_arm_rot = math.radians(-pose.right_arm.rotation + 20)
    right_arm_x = x + 30 * scale
    right_arm_y = body_y - 20 * scale + pose.right_arm.y * scale
    right_arm_end_x = right_arm_x + math.cos(right_arm_rot) * arm_len
    right_arm_end_y = right_arm_y + math.sin(right_arm_rot) * arm_len
    draw.line([right_arm_x, right_arm_y, right_arm_end_x, right_arm_end_y],
              fill=(255, 220, 180, 255), width=int(10 * scale))


def render_expression_demo():
    """Demo: Character cycling through emotions."""
    print("Rendering: Expression Demo")

    renderer = QuickRenderer(400, 300, fps=30)
    facial = FacialAnimator()

    # Emotion sequence
    emotions = [
        (Emotion.NEUTRAL, "Neutral"),
        (Emotion.HAPPY, "Happy"),
        (Emotion.SAD, "Sad"),
        (Emotion.ANGRY, "Angry"),
        (Emotion.SURPRISED, "Surprised"),
        (Emotion.CONFUSED, "Confused"),
    ]
    emotion_duration = 1.5  # seconds per emotion

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)

        # Background
        draw.rectangle([0, 0, 400, 300], fill=(40, 45, 55, 255))

        # Determine current emotion
        emotion_idx = int(time / emotion_duration) % len(emotions)
        emotion, name = emotions[emotion_idx]

        # Set emotion at start of each period
        if frame_num % int(emotion_duration * 30) == 0:
            facial.set_emotion(emotion)

        # Update facial animation
        dt = 1.0 / 30
        face = facial.update(dt)

        # Draw character
        motion = MotionBlender()
        motion.set_base_motion(create_idle(intensity=0.5))
        pose = motion.update(dt)

        draw_simple_character(draw, 200, 180, face, pose, scale=1.5)

        # Label
        draw.text((200, 270), name, fill=(255, 255, 255, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_expressions.gif")
    renderer.render_gif(output, len(emotions) * emotion_duration)
    print(f"  Saved: {output}")
    return output


def render_motion_demo():
    """Demo: Character performing various motions."""
    print("Rendering: Motion Demo")

    renderer = QuickRenderer(400, 300, fps=30)
    motion = MotionBlender()
    motion.set_base_motion(create_idle())
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    # Motion sequence with timing
    motion_sequence = [
        (0.0, "wave", create_wave(waves=3)),
        (2.0, "celebrate", create_celebrate()),
        (4.0, "thinking", create_thinking(duration=1.5)),
    ]
    current_motion_idx = 0
    last_trigger_time = -1.0

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        nonlocal current_motion_idx, last_trigger_time

        draw = ImageDraw.Draw(frame)
        draw.rectangle([0, 0, 400, 300], fill=(50, 60, 70, 255))

        dt = 1.0 / 30

        # Trigger motions at scheduled times
        for i, (trigger_time, name, motion_preset) in enumerate(motion_sequence):
            if time >= trigger_time and trigger_time > last_trigger_time:
                motion.play_overlay(motion_preset)
                last_trigger_time = trigger_time
                current_motion_idx = i

        # Update
        pose = motion.update(dt)
        face = facial.update(dt)

        # Draw
        draw_simple_character(draw, 200, 180, face, pose, scale=1.5)

        # Label current motion
        if current_motion_idx < len(motion_sequence):
            name = motion_sequence[current_motion_idx][1]
            draw.text((200, 270), name.title(), fill=(255, 255, 255, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_motions.gif")
    renderer.render_gif(output, 6.0)
    print(f"  Saved: {output}")
    return output


def render_physics_demo():
    """Demo: Physics chain with particles."""
    print("Rendering: Physics Demo")

    renderer = QuickRenderer(400, 300, fps=30)

    # Physics chain (pendulum/hair)
    chain = PhysicsChain(
        anchor=(100, 50),
        segments=5,
        segment_length=20,
        gravity=(0, 150),
        damping=0.96,
        stiffness=0.85
    )

    # Sparkle particles
    sparkles = create_sparkle_emitter(position=(300, 150))
    sparkles.emission_rate = 15

    # Spring for bouncing
    spring = Spring(stiffness=80, damping=8)
    spring.target = 200

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        draw.rectangle([0, 0, 400, 300], fill=(30, 35, 45, 255))

        dt = 1.0 / 30

        # Swing chain anchor point
        anchor_x = 100 + math.sin(time * 2) * 50
        chain.anchor = chain.anchor.__class__(anchor_x, 50)
        chain.update(dt)

        # Draw chain - get_points returns list of (x,y) tuples
        points = chain.get_points()
        for i in range(len(points) - 1):
            draw.line([points[i], points[i + 1]], fill=(200, 100, 100, 255), width=4)
        for p in points:
            draw.ellipse([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=(255, 150, 150, 255))

        # Bouncing ball with spring
        spring.target = 200 + math.sin(time * 3) * 80
        ball_y = spring.update(dt)
        draw.ellipse([290, ball_y - 15, 320, ball_y + 15], fill=(100, 200, 255, 255))

        # Update and draw particles
        sparkles.update(dt)
        for p in sparkles.particles:
            if p.life > 0:
                alpha = int(255 * p.life / sparkles.particle_life)
                px, py = p.position.x, p.position.y
                draw.ellipse([
                    int(px - p.size), int(py - p.size),
                    int(px + p.size), int(py + p.size)
                ], fill=(255, 255, 200, alpha))

        # Labels
        draw.text((100, 20), "Physics Chain", fill=(200, 200, 200, 255), anchor="mm")
        draw.text((300, 20), "Spring + Particles", fill=(200, 200, 200, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_physics.gif")
    renderer.render_gif(output, 4.0)
    print(f"  Saved: {output}")
    return output


def render_path_demo():
    """Demo: Object following a bezier path."""
    print("Rendering: Path Demo")

    renderer = QuickRenderer(400, 300, fps=30)

    # Create bezier path
    path = BezierPath()
    path.add_point((50, 150), control_out=(100, 50))
    path.add_point((200, 50), control_in=(150, 50), control_out=(250, 50))
    path.add_point((350, 150), control_in=(300, 50), control_out=(350, 200))
    path.add_point((200, 250), control_in=(350, 250), control_out=(100, 250))
    path.add_point((50, 150), control_in=(50, 200))

    follower = PathFollower(path, duration=5.0, loop=True)

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        draw.rectangle([0, 0, 400, 300], fill=(45, 50, 60, 255))

        dt = 1.0 / 30

        # Draw path
        num_segments = 50
        path_points = [path.get_point(t / num_segments) for t in range(num_segments + 1)]
        for i in range(len(path_points) - 1):
            p1 = path_points[i]
            p2 = path_points[i + 1]
            draw.line([int(p1[0]), int(p1[1]), int(p2[0]), int(p2[1])],
                      fill=(100, 100, 120, 255), width=2)

        # Draw control points
        for bp in path.points:
            px, py = int(bp.position[0]), int(bp.position[1])
            draw.ellipse([px - 4, py - 4, px + 4, py + 4], fill=(150, 150, 180, 255))

        # Update and draw follower
        follower.update(dt)
        pos = follower.position
        rotation = follower.rotation
        fx, fy = int(pos[0]), int(pos[1])

        # Draw as arrow
        arrow_len = 15
        rad = math.radians(rotation)
        ax = fx + math.cos(rad) * arrow_len
        ay = fy + math.sin(rad) * arrow_len

        draw.ellipse([fx - 10, fy - 10, fx + 10, fy + 10], fill=(255, 150, 100, 255))
        draw.line([fx, fy, int(ax), int(ay)], fill=(255, 200, 150, 255), width=3)

        # Trail
        for i in range(5):
            t = max(0, follower.progress - i * 0.02)
            tp = path.get_point(t % 1.0)
            alpha = 200 - i * 40
            draw.ellipse([
                int(tp[0]) - 5, int(tp[1]) - 5,
                int(tp[0]) + 5, int(tp[1]) + 5
            ], fill=(255, 150, 100, alpha))

        draw.text((200, 20), "Bezier Path Following", fill=(200, 200, 200, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_path.gif")
    renderer.render_gif(output, 5.0)
    print(f"  Saved: {output}")
    return output


def render_camera_demo():
    """Demo: Camera shake and effects."""
    print("Rendering: Camera Demo")

    renderer = QuickRenderer(400, 300, fps=30)
    camera = Camera((400, 300))

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)

        dt = 1.0 / 30

        # Trigger shakes at intervals
        if frame_num == 30:  # 1 second
            camera.add_shake(ShakeType.IMPACT, intensity=1.0)
        elif frame_num == 90:  # 3 seconds
            camera.add_shake(ShakeType.EXPLOSION, intensity=0.8)
        elif frame_num == 150:  # 5 seconds
            camera.add_shake(ShakeType.EARTHQUAKE, intensity=0.6, duration=1.5)

        camera.update(dt)
        offset = camera._shake_offset

        # Background with shake offset
        bg_x = int(offset[0])
        bg_y = int(offset[1])

        # Draw grid (to show shake)
        draw.rectangle([0, 0, 400, 300], fill=(50, 55, 65, 255))
        for i in range(-2, 12):
            x = i * 40 + bg_x % 40
            draw.line([x, 0, x, 300], fill=(60, 65, 75, 255), width=1)
        for i in range(-2, 10):
            y = i * 40 + bg_y % 40
            draw.line([0, y, 400, y], fill=(60, 65, 75, 255), width=1)

        # Static elements
        draw.ellipse([180 + bg_x, 130 + bg_y, 220 + bg_x, 170 + bg_y],
                     fill=(200, 100, 100, 255))

        # Label based on current shake
        if 30 <= frame_num < 60:
            label = "Impact Shake"
        elif 90 <= frame_num < 120:
            label = "Explosion Shake"
        elif 150 <= frame_num < 195:
            label = "Earthquake Shake"
        else:
            label = "Camera Shake Demo"

        draw.text((200, 20), label, fill=(255, 255, 255, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_camera.gif")
    renderer.render_gif(output, 7.0)
    print(f"  Saved: {output}")
    return output


def render_combined_demo():
    """Demo: All features combined."""
    print("Rendering: Combined Demo")

    renderer = QuickRenderer(640, 480, fps=30)

    # Components
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)
    motion = MotionBlender()
    motion.set_base_motion(create_idle())
    camera = Camera((640, 480))
    sparkles = create_sparkle_emitter(position=(320, 240))
    sparkles.emission_rate = 10

    # Path for floating object
    path = BezierPath()
    path.add_point((100, 100), control_out=(200, 50))
    path.add_point((540, 100), control_in=(440, 50), control_out=(540, 200))
    path.add_point((540, 380), control_in=(540, 280))
    path.add_point((100, 380), control_in=(200, 430))
    path.add_point((100, 100), control_in=(100, 200))
    follower = PathFollower(path, duration=7.0, loop=True)

    # Event timeline
    events = {
        1.0: lambda: motion.play_overlay(create_wave()),
        3.0: lambda: facial.set_emotion(Emotion.SURPRISED),
        3.5: lambda: camera.add_shake(ShakeType.IMPACT, 0.5),
        4.0: lambda: facial.set_emotion(Emotion.HAPPY),
        5.0: lambda: motion.play_overlay(create_celebrate()),
    }
    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / 30

        # Trigger events
        for event_time, event_func in events.items():
            if time >= event_time and event_time not in triggered:
                event_func()
                triggered.add(event_time)

        # Update all systems
        face = facial.update(dt)
        pose = motion.update(dt)
        camera.update(dt)
        sparkles.update(dt)
        follower.update(dt)
        path_pos = follower.position
        path_rot = follower.rotation

        # Camera offset
        shake = camera._shake_offset

        # Background gradient
        for y in range(0, 480, 4):
            brightness = 40 + int(y / 480 * 30)
            draw.rectangle([0, y, 640, y + 4], fill=(brightness, brightness + 5, brightness + 15, 255))

        # Path visualization
        for i in range(50):
            t = i / 50
            p = path.get_point(t)
            alpha = 80 + int(t * 40)
            draw.ellipse([
                int(p[0] + shake[0]) - 2, int(p[1] + shake[1]) - 2,
                int(p[0] + shake[0]) + 2, int(p[1] + shake[1]) + 2
            ], fill=(100, 120, 150, alpha))

        # Path follower (star shape)
        fx, fy = int(path_pos[0] + shake[0]), int(path_pos[1] + shake[1])
        for i in range(5):
            angle = math.radians(path_rot + i * 72 - 90)
            sx = fx + math.cos(angle) * 15
            sy = fy + math.sin(angle) * 15
            draw.line([fx, fy, int(sx), int(sy)], fill=(255, 220, 100, 255), width=3)
        draw.ellipse([fx - 6, fy - 6, fx + 6, fy + 6], fill=(255, 240, 150, 255))

        # Particles around star
        # Update sparkle position to follow the path
        sparkles.position.x = path_pos[0]
        sparkles.position.y = path_pos[1]
        for p in sparkles.particles:
            if p.life > 0:
                alpha = int(255 * p.life / sparkles.particle_life)
                px = int(p.position.x + shake[0])
                py = int(p.position.y + shake[1])
                draw.ellipse([px - 3, py - 3, px + 3, py + 3],
                             fill=(255, 255, 200, alpha))

        # Character
        char_x = 320 + shake[0]
        char_y = 320 + shake[1]
        draw_simple_character(draw, char_x, char_y, face, pose, scale=1.8)

        # Title
        draw.text((320, 30), "Animation Pipeline Demo",
                  fill=(255, 255, 255, 255), anchor="mm")

    renderer.on_frame(draw_frame)

    output = os.path.join(os.path.dirname(__file__), "demo_combined.gif")
    renderer.render_gif(output, 7.0)
    print(f"  Saved: {output}")
    return output


def main():
    """Run all demos."""
    print("=" * 60)
    print("ANIMATION PIPELINE - VIDEO DEMOS")
    print("=" * 60)
    print()

    demos = [
        ("Expressions", render_expression_demo),
        ("Motions", render_motion_demo),
        ("Physics", render_physics_demo),
        ("Path Animation", render_path_demo),
        ("Camera Effects", render_camera_demo),
        ("Combined", render_combined_demo),
    ]

    outputs = []
    for name, func in demos:
        print(f"\n[{name}]")
        try:
            output = func()
            outputs.append(output)
        except Exception as e:
            print(f"  Error: {e}")
            import traceback
            traceback.print_exc()

    print()
    print("=" * 60)
    print("DEMOS COMPLETE")
    print("=" * 60)
    print()
    print("Generated files:")
    for output in outputs:
        print(f"  - {output}")

    # Open the combined demo
    if outputs:
        print()
        print(f"Opening: {outputs[-1]}")


if __name__ == "__main__":
    main()
