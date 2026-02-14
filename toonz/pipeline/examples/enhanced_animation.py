#!/usr/bin/env python3
"""
Enhanced Animation Examples

This example demonstrates the advanced animation features:
- Skeletal animation with IK
- Physics-based secondary motion
- Camera system with parallax and shake
- Particle effects and transitions
- Path animation

Run: python -m pipeline.examples.enhanced_animation
"""

import sys
import math
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw

# Import enhanced animation modules
from pipeline.animation import (
    # Skeletal
    Skeleton, Bone, BoneConstraint, Vec2,
    create_humanoid_skeleton, create_arm_skeleton,
    # Physics
    Spring, Spring2D, PhysicsChain,
    BreathingAnimation, EyeController, SquashStretch, InertiaFollow, Wobble,
    # Camera
    Camera, ParallaxCamera, ShakeType, DepthOfField,
    # Effects
    ParticleEmitter, create_sparkle_emitter, create_confetti_emitter,
    apply_glow, apply_drop_shadow, apply_color_grade, apply_vignette,
    FadeTransition, WipeTransition, DissolveTransition, IrisTransition,
    BezierPath, PathFollower,
    # Core
    AnimationClip, EasingType
)


def demo_skeleton():
    """Demonstrate skeletal animation with IK."""
    print("\n" + "=" * 60)
    print("SKELETAL ANIMATION DEMO")
    print("=" * 60)

    # Create a simple arm skeleton
    skeleton = create_arm_skeleton("demo_arm", length=150)
    skeleton.position = Vec2(200, 200)

    print(f"\nArm skeleton: {skeleton.name}")
    print(f"Bones: {list(skeleton.bones.keys())}")
    print(f"IK chains: {list(skeleton.ik_chains.keys())}")
    print(f"Total arm length: 150 (can reach ~150px from origin)")

    # Show IK solving - targets within reach of 150px arm
    targets = [(300, 200), (320, 150), (280, 100), (250, 250)]

    for target in targets:
        solved = skeleton.solve_ik("arm", target)
        end_pos = skeleton.get_bone("wrist").get_world_end()
        print(f"\nTarget: {target}")
        print(f"  Solved: {solved}")
        print(f"  End position: ({end_pos.x:.1f}, {end_pos.y:.1f})")
        print(f"  Bone angles: ", end="")
        for name, bone in skeleton.bones.items():
            print(f"{name}={math.degrees(bone.angle):.1f}° ", end="")
        print()

    # Create humanoid skeleton
    humanoid = create_humanoid_skeleton("character", body_height=200)
    print(f"\nHumanoid skeleton: {humanoid.name}")
    print(f"Total bones: {len(humanoid.bones)}")
    print(f"IK chains: {list(humanoid.ik_chains.keys())}")


def demo_physics():
    """Demonstrate physics-based secondary motion."""
    print("\n" + "=" * 60)
    print("PHYSICS ANIMATION DEMO")
    print("=" * 60)

    # Spring demonstration
    print("\n--- Spring Demo ---")
    spring = Spring(stiffness=300, damping=15, initial_value=0)
    spring.set_target(100)

    print("Spring settling to target=100:")
    for frame in range(10):
        value = spring.update(1/30)
        print(f"  Frame {frame}: {value:.2f}")

    # Physics chain (hair/cloth simulation)
    print("\n--- Physics Chain Demo (Hair/Cloth) ---")
    chain = PhysicsChain(
        anchor=(100, 50),
        segments=5,
        segment_length=20,
        gravity=(0, 100),
        damping=0.98
    )

    print("Chain points after simulation:")
    for frame in range(10):
        chain.update(1/30)

    points = chain.get_points()
    for i, (x, y) in enumerate(points):
        print(f"  Segment {i}: ({x:.1f}, {y:.1f})")

    # Breathing animation
    print("\n--- Breathing Animation Demo ---")
    breathing = BreathingAnimation(rate=12, depth=1.0)

    print("Breathing values over 1 second (30 frames):")
    for frame in [0, 7, 15, 22, 29]:
        values = breathing.update(frame, fps=30)
        print(f"  Frame {frame}: chest={values['chest']:.2f}, "
              f"shoulders={values['shoulders']:.2f}, "
              f"inhaling={values['inhaling']}")

    # Eye controller
    print("\n--- Eye Controller Demo ---")
    eyes = EyeController(eye_distance=30, max_offset=10)

    print("Eye positions with wandering gaze:")
    for frame in [0, 15, 30, 45, 60]:
        values = eyes.update(frame, fps=30)
        print(f"  Frame {frame}: left={values['left']}, "
              f"right={values['right']}, blink={values['blink']:.2f}")

    # Squash and stretch
    print("\n--- Squash & Stretch Demo ---")
    ss = SquashStretch(intensity=0.3)

    velocities = [(0, 0), (50, 0), (100, 0), (0, 100), (0, -100)]
    for vel in velocities:
        scale = ss.calculate(vel, dt=1/30)
        print(f"  Velocity {vel}: scale=({scale[0]:.2f}, {scale[1]:.2f})")


def demo_camera():
    """Demonstrate camera system with effects."""
    print("\n" + "=" * 60)
    print("CAMERA SYSTEM DEMO")
    print("=" * 60)

    # Basic camera
    camera = Camera(viewport_size=(1920, 1080))
    camera.position = (960, 540)  # Center

    print(f"\nCamera viewport: {camera.viewport_size}")
    print(f"Camera position: {camera.position}")

    # World to screen conversion
    world_points = [(960, 540), (0, 0), (1920, 1080), (500, 500)]
    print("\nWorld to Screen conversion:")
    for wp in world_points:
        sp = camera.world_to_screen(wp)
        print(f"  World {wp} -> Screen {sp}")

    # Camera animation
    print("\n--- Camera Animation ---")
    camera.animation = AnimationClip("camera_move")
    camera.animation.add_track("position").add_keyframe(0, (960, 540))
    camera.animation.add_track("position").add_keyframe(60, (1200, 600), EasingType.EASE_IN_OUT)
    camera.animation.add_track("zoom").add_keyframe(0, 1.0)
    camera.animation.add_track("zoom").add_keyframe(60, 1.5, EasingType.EASE_IN_OUT)

    for frame in [0, 15, 30, 45, 60]:
        camera.update(frame, fps=30)
        print(f"  Frame {frame}: pos={camera.position}, zoom={camera.zoom:.2f}")

    # Camera shake
    print("\n--- Camera Shake Demo ---")
    camera2 = Camera(viewport_size=(1920, 1080))
    camera2.add_shake(ShakeType.IMPACT, intensity=1.0, duration=0.5)

    print("Shake offset over time:")
    for frame in range(15):
        camera2.update(frame, fps=30)
        print(f"  Frame {frame}: offset={camera2._shake_offset}")

    # Parallax layers
    print("\n--- Parallax Camera Demo ---")
    parallax_cam = ParallaxCamera(viewport_size=(1920, 1080))
    parallax_cam.add_parallax_layer("sky", depth=0.0, z_order=-100)
    parallax_cam.add_parallax_layer("mountains", depth=0.3, z_order=-50)
    parallax_cam.add_parallax_layer("trees", depth=0.7, z_order=-10)

    print("Parallax layer offsets as camera moves:")
    for cam_x in [0, 100, 200]:
        parallax_cam.position = (960 + cam_x, 540)
        print(f"\n  Camera X offset: {cam_x}")
        for name, layer in parallax_cam.parallax_layers.items():
            offset = parallax_cam.calculate_layer_offset(layer)
            print(f"    {name} (depth={layer.depth}): offset=({offset[0]:.1f}, {offset[1]:.1f})")


def demo_particles():
    """Demonstrate particle effects."""
    print("\n" + "=" * 60)
    print("PARTICLE EFFECTS DEMO")
    print("=" * 60)

    # Sparkle emitter
    print("\n--- Sparkle Emitter ---")
    sparkle = create_sparkle_emitter(position=(500, 500), intensity=1.0)
    print(f"Emission rate: {sparkle.emission_rate}/sec")
    print(f"Colors: {sparkle.colors}")

    # Simulate a few frames
    for i in range(5):
        sparkle.update(1/30)
    print(f"Active particles after 5 frames: {len(sparkle.particles)}")

    # Confetti burst
    print("\n--- Confetti Burst ---")
    confetti = create_confetti_emitter(position=(960, 200))
    confetti.burst(50)  # Emit 50 particles
    print(f"Particles after burst: {len(confetti.particles)}")

    # Simulate
    for i in range(30):
        confetti.update(1/30)
    print(f"Particles after 1 second: {len(confetti.particles)}")

    # Custom emitter
    print("\n--- Custom Particle Emitter ---")
    custom = ParticleEmitter(
        position=(500, 500),
        emission_rate=50,
        particle_life=2.0,
        particle_speed=(100, 200),
        direction=-90,  # Up
        spread=45,
        gravity=(0, -50),  # Rise up
        particle_size=(3, 8),
        colors=[(255, 100, 100, 255), (100, 255, 100, 255), (100, 100, 255, 255)]
    )
    print(f"Custom emitter: rate={custom.emission_rate}, "
          f"life={custom.particle_life}s, colors={len(custom.colors)}")


def demo_effects():
    """Demonstrate image effects."""
    print("\n" + "=" * 60)
    print("IMAGE EFFECTS DEMO")
    print("=" * 60)

    # Create a test image
    size = (200, 200)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([50, 50, 150, 150], fill=(255, 100, 100, 255))

    print(f"\nTest image: {size}")

    # Glow
    glowed = apply_glow(img, radius=10, intensity=1.5)
    print(f"Glow effect applied: radius=10, intensity=1.5")

    # Drop shadow
    shadowed = apply_drop_shadow(img, offset=(10, 10), blur=5)
    print(f"Drop shadow applied: offset=(10,10), blur=5")
    print(f"  Original size: {img.size}, With shadow: {shadowed.size}")

    # Color grading
    graded = apply_color_grade(
        img,
        brightness=1.2,
        contrast=1.1,
        saturation=0.8,
        tint=(100, 150, 255),
        tint_strength=0.2
    )
    print("Color grade applied: brightness=1.2, contrast=1.1, saturation=0.8")

    # Vignette
    vignette_img = Image.new('RGBA', (400, 300), (200, 200, 200, 255))
    vignetted = apply_vignette(vignette_img, intensity=0.5, radius=0.7)
    print("Vignette applied: intensity=0.5, radius=0.7")


def demo_transitions():
    """Demonstrate transition effects."""
    print("\n" + "=" * 60)
    print("TRANSITION EFFECTS DEMO")
    print("=" * 60)

    # Create test images
    size = (400, 300)
    img1 = Image.new('RGBA', size, (255, 100, 100, 255))  # Red
    img2 = Image.new('RGBA', size, (100, 100, 255, 255))  # Blue

    print(f"\nTransition between red and blue images ({size})")

    # Fade
    fade = FadeTransition(duration=1.0)
    result = fade.apply(img1, img2, 0.5)
    print(f"Fade at 50%: center pixel = {result.getpixel((200, 150))[:3]}")

    # Wipe
    wipe = WipeTransition(duration=1.0, direction="left")
    result = wipe.apply(img1, img2, 0.5)
    left_pixel = result.getpixel((100, 150))[:3]  # Should be blue
    right_pixel = result.getpixel((300, 150))[:3]  # Should be red
    print(f"Wipe left at 50%: left={left_pixel}, right={right_pixel}")

    # Dissolve
    dissolve = DissolveTransition(duration=1.0, block_size=16)
    result = dissolve.apply(img1, img2, 0.5)
    print(f"Dissolve at 50%: block_size=16")

    # Iris
    iris = IrisTransition(duration=1.0, iris_out=True)
    result = iris.apply(img1, img2, 0.5)
    center = result.getpixel((200, 150))[:3]
    edge = result.getpixel((10, 10))[:3]
    print(f"Iris out at 50%: center={center}, edge={edge}")


def demo_path_animation():
    """Demonstrate path-based animation."""
    print("\n" + "=" * 60)
    print("PATH ANIMATION DEMO")
    print("=" * 60)

    # Create a bezier path
    path = BezierPath()
    path.add_point((100, 100))
    path.add_point((500, 100), control_out=(300, 50))
    path.add_point((500, 400), control_in=(550, 250))
    path.add_point((100, 400))

    print(f"\nBezier path with {len(path.points)} points")
    print(f"Approximate length: {path.get_length():.1f} pixels")

    # Sample path
    print("\nPath positions:")
    for t in [0, 0.25, 0.5, 0.75, 1.0]:
        pos = path.get_point(t)
        angle = path.get_tangent_angle(t)
        print(f"  t={t}: pos=({pos[0]:.1f}, {pos[1]:.1f}), angle={angle:.1f}°")

    # Path follower
    print("\n--- Path Follower ---")
    follower = PathFollower(
        path=path,
        duration=2.0,
        orient_to_path=True,
        loop=False
    )

    print("Follower positions over 2 seconds:")
    for frame in [0, 15, 30, 45, 60]:
        follower.update(1/30)
        print(f"  Frame {frame}: pos=({follower.position[0]:.1f}, "
              f"{follower.position[1]:.1f}), rot={follower.rotation:.1f}°")


def render_test_frame():
    """Render a test frame showing multiple effects."""
    print("\n" + "=" * 60)
    print("RENDERING TEST FRAME")
    print("=" * 60)

    # Create canvas
    width, height = 1920, 1080
    canvas = Image.new('RGBA', (width, height), (30, 30, 50, 255))
    draw = ImageDraw.Draw(canvas)

    # Draw section labels
    draw.text((350, 100), "SKELETON + IK", fill=(255, 255, 255, 200))
    draw.text((750, 100), "PHYSICS CHAIN", fill=(255, 255, 255, 200))
    draw.text((1150, 100), "PARTICLES", fill=(255, 255, 255, 200))
    draw.text((1550, 700), "BEZIER PATH", fill=(255, 255, 255, 200))

    # Draw skeleton visualization
    skeleton = create_arm_skeleton("arm", length=200)
    skeleton.position = Vec2(300, 400)

    # Draw IK target
    target = (450, 300)
    draw.ellipse([target[0]-10, target[1]-10, target[0]+10, target[1]+10],
                 outline=(255, 100, 100, 255), width=2)
    draw.text((target[0]+15, target[1]-10), "target", fill=(255, 100, 100, 200))

    skeleton.solve_ik("arm", target)

    # Draw bones with thicker lines
    for bone in skeleton.bones.values():
        start = bone.get_world_start()
        end = bone.get_world_end()
        draw.line(
            [start.x, start.y, end.x, end.y],
            fill=(255, 255, 100, 255),
            width=8
        )
        draw.ellipse(
            [start.x - 8, start.y - 8, start.x + 8, start.y + 8],
            fill=(255, 100, 100, 255)
        )
    # Draw end effector
    end = skeleton.get_bone("wrist").get_world_end()
    draw.ellipse([end.x - 6, end.y - 6, end.x + 6, end.y + 6],
                 fill=(100, 255, 100, 255))

    # Draw physics chain with more simulation time
    chain = PhysicsChain(
        anchor=(800, 200),
        segments=10,
        segment_length=40,
        gravity=(50, 150),
        damping=0.95
    )
    # Simulate more frames for visible swing
    for _ in range(60):
        chain.update(1/30)

    points = chain.get_points()
    for i in range(len(points) - 1):
        p1, p2 = points[i], points[i + 1]
        draw.line([p1[0], p1[1], p2[0], p2[1]], fill=(100, 255, 100, 255), width=4)

    # Add particles
    sparkle = create_sparkle_emitter((1200, 400), intensity=2.0)
    for _ in range(30):
        sparkle.update(1/30)
    particle_layer = sparkle.render((width, height))
    canvas = Image.alpha_composite(canvas, particle_layer)

    # Recreate draw object after composite (old one is invalid)
    draw = ImageDraw.Draw(canvas)

    # Draw bezier path
    path = BezierPath()
    path.add_point((1400, 800))
    path.add_point((1600, 600), control_out=(1500, 750))
    path.add_point((1800, 800), control_in=(1700, 600))

    prev = None
    for t in range(51):
        pos = path.get_point(t / 50)
        if prev:
            draw.line([prev[0], prev[1], pos[0], pos[1]], fill=(100, 100, 255, 255), width=3)
        prev = pos

    # Apply post-effects
    canvas = apply_vignette(canvas, intensity=0.3, radius=0.8)

    # Save
    output_path = "/mnt/e/projects/toonz/pipeline/examples/test_frame.png"
    canvas.save(output_path)
    print(f"\nTest frame saved to: {output_path}")
    print(f"Size: {canvas.size}")


if __name__ == "__main__":
    print("=" * 60)
    print("ENHANCED ANIMATION PIPELINE DEMO")
    print("=" * 60)
    print("\nThis demo shows the advanced animation capabilities:")
    print("- Skeletal animation with inverse kinematics")
    print("- Physics-based secondary motion (springs, chains)")
    print("- Camera system (parallax, shake, zoom)")
    print("- Particle effects (sparkles, confetti, etc.)")
    print("- Image effects (glow, shadow, color grading)")
    print("- Transitions (fade, wipe, dissolve, iris)")
    print("- Path animation (bezier curves)")

    # Run all demos
    demo_skeleton()
    demo_physics()
    demo_camera()
    demo_particles()
    demo_effects()
    demo_transitions()
    demo_path_animation()
    render_test_frame()

    print("\n" + "=" * 60)
    print("DEMO COMPLETE")
    print("=" * 60)
