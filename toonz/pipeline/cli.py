#!/usr/bin/env python3
"""Command-line interface for the animation pipeline.

Usage:
    # Initialize new project
    python -m pipeline init my_project

    # Generate lip sync from audio
    python -m pipeline lipsync audio.wav --transcript script.txt -o lipsync.json

    # Preview animation (low-res, fast)
    python -m pipeline preview project.charproj

    # Full render
    python -m pipeline render project.charproj -o output.mp4 --quality high

    # Create character animation from audio
    python -m pipeline animate characters/narrator audio/speech.wav -o output.mp4
"""

import argparse
import sys
from pathlib import Path
from typing import Optional

from .core.pipeline import AnimationPipeline, create_project
from .core.config import Config
from .renderers.base import RenderProgress


def progress_bar(progress: RenderProgress) -> None:
    """Display a text progress bar."""
    width = 40
    filled = int(width * progress.progress)
    bar = '█' * filled + '░' * (width - filled)
    print(f"\r[{bar}] {progress.percent}% {progress.phase}: {progress.message}", end='', flush=True)
    if progress.phase == 'complete':
        print()  # New line at end


def progress_simple(value: float) -> None:
    """Simple progress callback for lip sync."""
    print(f"\rAnalyzing audio: {int(value * 100)}%", end='', flush=True)
    if value >= 1.0:
        print()


def cmd_init(args: argparse.Namespace) -> int:
    """Initialize a new project."""
    print(f"Creating project: {args.name}")

    pipeline = create_project(
        args.path or args.name,
        name=args.name,
        width=args.width,
        height=args.height,
        fps=args.fps
    )

    print(f"Project created at: {pipeline.project_dir}")
    print("\nDirectory structure:")
    print("  assets/")
    print("    characters/")
    print("    backgrounds/")
    print("    audio/")
    print("  output/")
    print("  .cache/")
    print("  pipeline.json")

    return 0


def cmd_lipsync(args: argparse.Namespace) -> int:
    """Generate lip sync data from audio."""
    from .lipsync.rhubarb import RhubarbWrapper, RhubarbError

    print(f"Analyzing: {args.audio}")

    rhubarb = RhubarbWrapper(args.rhubarb or "rhubarb")

    try:
        lipsync = rhubarb.analyze(
            args.audio,
            transcript_path=args.transcript,
            extended_shapes=args.shapes,
            on_progress=progress_simple if not args.quiet else None
        )

        # Output
        if args.output:
            lipsync.save(args.output)
            print(f"Saved to: {args.output}")
        else:
            # Print to stdout
            import json
            print(json.dumps(lipsync.to_dict(), indent=2))

        print(f"\nDuration: {lipsync.duration:.2f}s")
        print(f"Mouth cues: {len(lipsync.cues)}")

        return 0

    except RhubarbError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def cmd_render(args: argparse.Namespace) -> int:
    """Render a project or scene."""
    project_path = Path(args.input)

    if project_path.suffix in ('.charproj', '.json'):
        # Render project file
        project_dir = project_path.parent
        pipeline = AnimationPipeline(str(project_dir))

        print(f"Rendering project: {project_path}")

        try:
            output = pipeline.render_project(
                str(project_path),
                args.output,
                on_progress=progress_bar if not args.quiet else None
            )
            print(f"\nOutput: {output}")
            return 0

        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            return 1

    else:
        print(f"Unsupported file type: {project_path.suffix}", file=sys.stderr)
        return 1


def cmd_preview(args: argparse.Namespace) -> int:
    """Render a quick preview."""
    project_path = Path(args.input)

    if project_path.suffix in ('.charproj', '.json'):
        project_dir = project_path.parent
        pipeline = AnimationPipeline(str(project_dir))

        # Load project to create scene
        project = pipeline.load_project(str(project_path))
        scene = pipeline.create_scene(
            name=project.get("name", "preview"),
            duration=project.get("duration", 10.0)
        )

        print(f"Rendering preview: {project_path}")
        print(f"  Scale: {args.scale}")
        print(f"  Skip frames: {args.skip}")

        output = pipeline.render_preview(
            scene,
            args.output,
            scale=args.scale,
            skip_frames=args.skip,
            on_progress=progress_bar if not args.quiet else None
        )

        print(f"\nPreview: {output}")
        return 0

    else:
        print(f"Unsupported file type: {project_path.suffix}", file=sys.stderr)
        return 1


def cmd_animate(args: argparse.Namespace) -> int:
    """Create character animation from audio."""
    print(f"Creating animation:")
    print(f"  Character: {args.character}")
    print(f"  Audio: {args.audio}")

    # Determine project directory
    project_dir = args.project or Path.cwd()
    pipeline = AnimationPipeline(str(project_dir))

    try:
        # Load character
        print("Loading character...")
        character = pipeline.load_character(
            args.character,
            position=(args.x, args.y),
            scale=args.scale
        )

        # Create animation
        print("Generating lip sync...")
        scene = pipeline.create_character_animation(
            character,
            args.audio,
            transcript_path=args.transcript,
            add_blinks=not args.no_blinks
        )

        # Add background if specified
        if args.background:
            scene.add_layer(
                "background",
                image_path=pipeline._resolve_path(args.background),
                z_order=-1
            )

        # Render
        print("Rendering...")
        output = pipeline.render(
            scene,
            args.output,
            format=args.format,
            quality=args.quality,
            on_progress=progress_bar if not args.quiet else None
        )

        print(f"\nOutput: {output}")
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def cmd_test(args: argparse.Namespace) -> int:
    """Run pipeline tests to verify installation."""
    print("Running pipeline tests...\n")

    tests_passed = 0
    tests_failed = 0

    # Test 1: Core imports
    print("1. Testing core imports...")
    try:
        from .animation import (
            Skeleton, Bone,
            Spring, Spring2D, PhysicsChain,
            Camera, ShakeType, ShakeInstance,
            ParticleEmitter, create_sparkle_emitter,
            PathFollower, BezierPath, BezierPoint,
            FacialAnimator, Emotion,
            MotionBlender, IdleMotion,
            SceneRenderer, RenderSettings
        )
        from .audio import (
            RhubarbLipSync, LipSyncData,
            AudioMixer, AudioTrack,
            WaveformAnalyzer, BeatDetector
        )
        print("   OK - All imports successful")
        tests_passed += 1
    except ImportError as e:
        print(f"   FAIL - Import error: {e}")
        tests_failed += 1

    # Test 2: Skeleton system
    print("2. Testing skeleton system...")
    try:
        from .animation import Skeleton

        skeleton = Skeleton("test")
        root = skeleton.add_bone("root", length=50)
        skeleton.add_bone("arm", length=40, parent=root)  # Pass Bone object

        # Use built-in solve_ik method
        skeleton.solve_ik("arm", (80, 50), iterations=10)

        print("   OK - Skeleton and IK working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 3: Physics system
    print("3. Testing physics system...")
    try:
        from .animation import Spring, Spring2D, PhysicsChain

        spring = Spring(stiffness=100, damping=10)
        spring.set_target(50)
        spring.update(1/60)

        chain = PhysicsChain(anchor=(50, 50), segments=3, segment_length=20)
        chain.update(1/60)

        print("   OK - Physics simulation working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 4: Camera system
    print("4. Testing camera system...")
    try:
        from .animation import Camera, ShakeType

        camera = Camera(viewport_size=(800, 600))  # Takes tuple
        camera.add_shake(ShakeType.IMPACT, intensity=5.0, duration=0.5)
        camera.update(frame=1, fps=30.0)  # Takes frame and fps

        print("   OK - Camera system working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 5: Particle system
    print("5. Testing particle system...")
    try:
        from .animation import ParticleEmitter, create_sparkle_emitter

        emitter = ParticleEmitter(position=(100, 100), emission_rate=10)
        emitter.update(1/60)

        sparkles = create_sparkle_emitter(position=(100, 100))
        sparkles.update(1/60)

        print("   OK - Particle system working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 6: Path following
    print("6. Testing path system...")
    try:
        from .animation import PathFollower, BezierPath

        path = BezierPath()
        path.add_point((0, 0))  # add_point takes tuple directly
        path.add_point((100, 100))

        follower = PathFollower(path, duration=2.0)
        follower.update(0.5)
        _ = follower.position  # Access position

        print("   OK - Path following working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 7: Expressions
    print("7. Testing expression system...")
    try:
        from .animation import FacialAnimator, Emotion

        animator = FacialAnimator()
        animator.set_emotion(Emotion.HAPPY, 0.8)
        face_state = animator.update(1/60)  # update() returns FaceState

        print("   OK - Expression system working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 8: Motion presets
    print("8. Testing motion presets...")
    try:
        from .animation import MotionBlender, IdleMotion, BreathingMotion

        blender = MotionBlender()
        blender.set_base_motion(IdleMotion())  # set_base_motion, not add
        blender.play_overlay(BreathingMotion(), weight=0.5)
        pose = blender.update(1/60)

        print("   OK - Motion presets working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 9: Lip sync data
    print("9. Testing lip sync system...")
    try:
        from .audio import LipSyncData, MouthCue

        lip_sync = LipSyncData(duration=5.0)
        lip_sync.cues.append(MouthCue(start=0.0, end=0.5, shape='A'))
        lip_sync.cues.append(MouthCue(start=0.5, end=1.0, shape='C'))

        shape = lip_sync.get_shape_at_time(0.3)
        assert shape == 'A', f"Expected 'A', got '{shape}'"

        shape = lip_sync.get_shape_at_time(0.7)
        assert shape == 'C', f"Expected 'C', got '{shape}'"

        print("   OK - Lip sync data working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 10: Audio mixer
    print("10. Testing audio mixer...")
    try:
        from .audio import AudioMixer

        mixer = AudioMixer()
        track = mixer.add_track("dialogue", volume=1.0)
        track.add_audio("/fake/path.wav", start_time=0.0)

        mixer.get_timeline_events()

        print("   OK - Audio mixer working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Test 11: Timeline
    print("11. Testing timeline system...")
    try:
        from .animation.timeline import Timeline, TimelineBuilder

        # Use fluent API
        timeline = (TimelineBuilder(duration=30.0, fps=30)
            .at(0.0).emotion("narrator", "happy")
            .at(1.0).motion("narrator", "wave")
            .build())

        events = timeline.get_events_at_time(0.5)

        print("   OK - Timeline system working")
        tests_passed += 1
    except Exception as e:
        print(f"   FAIL - {e}")
        tests_failed += 1

    # Summary
    print(f"\n{'='*40}")
    print(f"Tests passed: {tests_passed}")
    print(f"Tests failed: {tests_failed}")
    print(f"{'='*40}")

    # Optional render test
    if args.render:
        print("\nRunning render test...")
        try:
            from .animation import QuickRenderer
            import tempfile
            import os

            renderer = QuickRenderer(width=200, height=150, fps=10)

            with tempfile.NamedTemporaryFile(suffix='.gif', delete=False) as f:
                output_path = f.name

            def simple_render(t, img):
                from PIL import ImageDraw
                draw = ImageDraw.Draw(img)
                x = int(50 + t * 100)
                draw.ellipse([x-10, 70, x+10, 90], fill='blue')
                return img

            renderer.render_gif(simple_render, duration=1.0, output_path=output_path)

            if os.path.exists(output_path):
                size = os.path.getsize(output_path)
                print(f"   OK - Test GIF rendered ({size} bytes)")
                os.unlink(output_path)
                tests_passed += 1
            else:
                print("   FAIL - Output file not created")
                tests_failed += 1

        except Exception as e:
            print(f"   FAIL - Render error: {e}")
            tests_failed += 1

    return 0 if tests_failed == 0 else 1


def cmd_info(args: argparse.Namespace) -> int:
    """Show information about a project or file."""
    path = Path(args.input)

    if path.suffix in ('.charproj', '.json'):
        # Project file
        import json
        with open(path) as f:
            data = json.load(f)

        print(f"Project: {data.get('name', 'Unknown')}")
        print(f"Version: {data.get('version', '1.0')}")
        print(f"Resolution: {data.get('width', '?')}x{data.get('height', '?')}")
        print(f"FPS: {data.get('fps', '?')}")
        print(f"Duration: {data.get('duration', '?')}s")

        if data.get('characters'):
            print(f"\nCharacters ({len(data['characters'])}):")
            for char in data['characters']:
                name = char.get('name', char.get('rig', 'Unknown'))
                print(f"  - {name}")

        if data.get('audio'):
            print(f"\nAudio: {data['audio']}")

    elif path.is_dir():
        # Project directory
        config_path = path / "pipeline.json"
        if config_path.exists():
            config = Config.load(str(path))
            print(f"Project: {config.name}")
            print(f"Directory: {path}")
            print(f"Resolution: {config.output.width}x{config.output.height}")
            print(f"FPS: {config.output.fps}")
        else:
            print(f"Not a pipeline project: {path}")
            return 1

    else:
        print(f"Unknown file type: {path}")
        return 1

    return 0


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        prog="pipeline",
        description="Programmatic 2D animation pipeline"
    )
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 0.1.0"
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # init command
    init_parser = subparsers.add_parser("init", help="Initialize new project")
    init_parser.add_argument("name", help="Project name")
    init_parser.add_argument("--path", help="Project path (default: name)")
    init_parser.add_argument("--width", type=int, default=1920, help="Output width")
    init_parser.add_argument("--height", type=int, default=1080, help="Output height")
    init_parser.add_argument("--fps", type=float, default=30.0, help="Frames per second")

    # lipsync command
    lipsync_parser = subparsers.add_parser("lipsync", help="Generate lip sync data")
    lipsync_parser.add_argument("audio", help="Audio file path")
    lipsync_parser.add_argument("-t", "--transcript", help="Transcript file path")
    lipsync_parser.add_argument("-o", "--output", help="Output JSON file")
    lipsync_parser.add_argument("--shapes", default="GHX", help="Extended shapes (GHX)")
    lipsync_parser.add_argument("--rhubarb", help="Path to Rhubarb executable")
    lipsync_parser.add_argument("-q", "--quiet", action="store_true", help="Suppress progress")

    # render command
    render_parser = subparsers.add_parser("render", help="Render project to video")
    render_parser.add_argument("input", help="Project file (.charproj)")
    render_parser.add_argument("-o", "--output", help="Output path")
    render_parser.add_argument("-f", "--format", help="Output format (mp4, webm, etc.)")
    render_parser.add_argument("--quality", choices=["low", "medium", "high", "lossless"],
                              default="high", help="Quality preset")
    render_parser.add_argument("-q", "--quiet", action="store_true", help="Suppress progress")

    # preview command
    preview_parser = subparsers.add_parser("preview", help="Render quick preview")
    preview_parser.add_argument("input", help="Project file (.charproj)")
    preview_parser.add_argument("-o", "--output", help="Output directory")
    preview_parser.add_argument("--scale", type=float, default=0.5, help="Scale factor")
    preview_parser.add_argument("--skip", type=int, default=1, help="Skip every N frames")
    preview_parser.add_argument("-q", "--quiet", action="store_true", help="Suppress progress")

    # animate command
    animate_parser = subparsers.add_parser("animate", help="Create character animation")
    animate_parser.add_argument("character", help="Character path (relative to assets)")
    animate_parser.add_argument("audio", help="Audio file path")
    animate_parser.add_argument("-o", "--output", help="Output path")
    animate_parser.add_argument("-t", "--transcript", help="Transcript file")
    animate_parser.add_argument("-b", "--background", help="Background image")
    animate_parser.add_argument("--project", help="Project directory")
    animate_parser.add_argument("--scale", type=float, default=1.0, help="Character scale")
    animate_parser.add_argument("--x", type=int, default=960, help="Character X position")
    animate_parser.add_argument("--y", type=int, default=540, help="Character Y position")
    animate_parser.add_argument("-f", "--format", default="mp4", help="Output format")
    animate_parser.add_argument("--quality", default="high", help="Quality preset")
    animate_parser.add_argument("--no-blinks", action="store_true", help="Disable auto blinks")
    animate_parser.add_argument("-q", "--quiet", action="store_true", help="Suppress progress")

    # info command
    info_parser = subparsers.add_parser("info", help="Show project information")
    info_parser.add_argument("input", help="Project file or directory")

    # test command
    test_parser = subparsers.add_parser("test", help="Run pipeline tests")
    test_parser.add_argument("-r", "--render", action="store_true",
                            help="Include render test (creates temp GIF)")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    # Dispatch to command handler
    commands = {
        "init": cmd_init,
        "lipsync": cmd_lipsync,
        "render": cmd_render,
        "preview": cmd_preview,
        "animate": cmd_animate,
        "info": cmd_info,
        "test": cmd_test,
    }

    handler = commands.get(args.command)
    if handler:
        return handler(args)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
