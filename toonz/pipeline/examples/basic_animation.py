#!/usr/bin/env python3
"""
Basic Animation Example

This example demonstrates how to create a simple character animation
with lip sync from audio using the pipeline.

Prerequisites:
- Rhubarb Lip Sync installed and in PATH
- FFmpeg installed and in PATH
- Pillow (pip install Pillow)
"""

import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from pipeline import (
    AnimationPipeline,
    create_project,
    Scene,
    Character,
    CharacterRig,
    EasingType
)


def create_sample_project():
    """Create a sample project with all required directories."""
    # Create project
    pipeline = create_project(
        "sample_project",
        name="Sample Animation",
        width=1920,
        height=1080,
        fps=30
    )

    print(f"Project created at: {pipeline.project_dir}")
    return pipeline


def basic_scene_example():
    """Create a basic scene without characters."""
    from pipeline import Scene, SceneLayer

    # Create scene
    scene = Scene(
        name="basic_scene",
        width=1920,
        height=1080,
        fps=30,
        duration=5.0,
        background_color=(50, 50, 80, 255)  # Dark blue
    )

    # Add a color layer as background
    scene.add_color_layer(
        "background",
        color=(100, 150, 200, 255),  # Light blue
        z_order=-10
    )

    print(f"Scene: {scene.name}")
    print(f"Duration: {scene.duration}s ({scene.total_frames} frames)")
    print(f"Resolution: {scene.width}x{scene.height}")

    return scene


def animation_with_keyframes():
    """Example showing keyframe animation."""
    from pipeline import Scene, AnimationClip, EasingType

    # Create scene
    scene = Scene(name="keyframe_demo", duration=3.0, fps=30)

    # Add a layer (you would normally add an image here)
    layer = scene.add_color_layer(
        "animated_square",
        color=(255, 100, 100, 255),
        z_order=10
    )

    # Create animation clip
    clip = AnimationClip("move_and_fade")

    # Animate position
    position_track = clip.add_track("position", default_value=(100, 100))
    position_track.add_keyframe(0, (100, 100))
    position_track.add_keyframe(30, (500, 100), EasingType.EASE_OUT)
    position_track.add_keyframe(60, (500, 400), EasingType.EASE_IN_OUT)
    position_track.add_keyframe(90, (100, 400), EasingType.EASE_OUT_BOUNCE)

    # Animate opacity
    opacity_track = clip.add_track("opacity", default_value=1.0)
    opacity_track.add_keyframe(0, 1.0)
    opacity_track.add_keyframe(45, 0.5, EasingType.EASE_IN_OUT)
    opacity_track.add_keyframe(90, 1.0, EasingType.EASE_IN_OUT)

    # Apply animation to layer
    layer.animation = clip

    # Test keyframe interpolation
    for frame in [0, 15, 30, 45, 60, 75, 90]:
        props = layer.get_animated_properties(frame)
        print(f"Frame {frame}: pos={props['position']}, opacity={props['opacity']:.2f}")

    return scene


def character_lipsync_example(pipeline: AnimationPipeline, audio_path: str):
    """Example showing character lip sync animation.

    Args:
        pipeline: Initialized AnimationPipeline
        audio_path: Path to audio file
    """
    # Generate lip sync data
    print("Generating lip sync data...")
    lipsync = pipeline.generate_lipsync(
        audio_path,
        on_progress=lambda p: print(f"  {int(p * 100)}%")
    )

    print(f"\nLip sync generated:")
    print(f"  Duration: {lipsync.duration:.2f}s")
    print(f"  Mouth cues: {len(lipsync.cues)}")

    # Show first 10 cues
    print("\nFirst 10 mouth cues:")
    for cue in lipsync.cues[:10]:
        print(f"  {cue.start:.2f}s - {cue.end:.2f}s: {cue.shape}")

    return lipsync


def render_example(pipeline: AnimationPipeline, scene: Scene):
    """Example showing scene rendering.

    Args:
        pipeline: Initialized AnimationPipeline
        scene: Scene to render
    """
    from pipeline import RenderProgress

    def on_progress(progress: RenderProgress):
        print(f"  {progress.phase}: {progress.percent}% - {progress.message}")

    print(f"\nRendering scene: {scene.name}")

    # Render to video
    output_path = pipeline.render(
        scene,
        f"{scene.name}.mp4",
        quality="high",
        on_progress=on_progress
    )

    print(f"\nOutput: {output_path}")
    return output_path


if __name__ == "__main__":
    print("=" * 60)
    print("Pipeline Examples")
    print("=" * 60)

    # Example 1: Basic scene
    print("\n1. Basic Scene Example")
    print("-" * 40)
    scene = basic_scene_example()

    # Example 2: Keyframe animation
    print("\n2. Keyframe Animation Example")
    print("-" * 40)
    animated_scene = animation_with_keyframes()

    # Example 3: Project creation
    print("\n3. Project Creation Example")
    print("-" * 40)
    # Uncomment to create a project:
    # pipeline = create_sample_project()

    print("\n" + "=" * 60)
    print("Examples completed!")
    print("=" * 60)
