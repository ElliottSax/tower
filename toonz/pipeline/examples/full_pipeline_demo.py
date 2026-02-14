#!/usr/bin/env python3
"""Full Pipeline Demo with Audio Integration.

This demo showcases the complete animation pipeline:
- Timeline-based sequencing
- Lip sync integration
- Expression and motion systems
- Camera and effects
- Audio track mixing

Run: python -m pipeline.examples.full_pipeline_demo
"""

import os
import sys
from pathlib import Path

# Add pipeline to path
pipeline_dir = Path(__file__).parent.parent.parent
sys.path.insert(0, str(pipeline_dir))

from PIL import Image, ImageDraw, ImageFont

from pipeline.animation import (
    # Core
    SceneRenderer, RenderSettings, QuickRenderer,
    # Skeleton
    Skeleton, create_arm_skeleton,
    # Physics
    Spring, PhysicsChain, BreathingAnimation,
    # Camera
    Camera, ShakeType,
    # Effects
    ParticleEmitter, create_sparkle_emitter, BezierPath, PathFollower,
    apply_vignette,
    # Expressions
    FacialAnimator, Emotion,
    # Motion
    MotionBlender, IdleMotion, BreathingMotion, WaveMotion, CelebrateMotion,
)

from pipeline.animation.timeline import (
    Timeline, TimelineBuilder, EventType,
    create_greeting_sequence, create_celebration_sequence,
)

from pipeline.audio import (
    LipSyncData, MouthCue,
    AudioMixer, AudioTimeline,
    BeatDetector, WaveformAnalyzer,
)


def create_simulated_lipsync(duration: float = 5.0) -> LipSyncData:
    """Create simulated lip sync data for demo."""
    lip_sync = LipSyncData(duration=duration)

    # Simulate speaking pattern
    shapes = ['A', 'C', 'D', 'B', 'E', 'C', 'B', 'X', 'A', 'C', 'D', 'E', 'F', 'B', 'X']
    time_per_shape = duration / len(shapes)

    for i, shape in enumerate(shapes):
        start = i * time_per_shape
        end = start + time_per_shape
        lip_sync.cues.append(MouthCue(start=start, end=end, shape=shape))

    return lip_sync


def demo_timeline_sequencing():
    """Demo 1: Timeline-based animation sequencing."""
    print("\n=== Demo 1: Timeline Sequencing ===")

    # Build a timeline with fluent API
    timeline = (TimelineBuilder(duration=10.0, fps=30)
        # Opening
        .at(0.0).emotion("character", "neutral")
        .at(0.0).marker("intro")

        # Wave hello
        .at(0.5).emotion("character", "happy")
        .at(0.5).motion("character", "wave")

        # Speak
        .at(2.0).marker("speech_start")
        .at(2.0).speak("character", duration=3.0)

        # React
        .at(5.5).emotion("character", "surprised")
        .at(5.5).camera_shake("impact", intensity=0.5)

        # Celebrate
        .at(6.5).emotion("character", "happy")
        .at(6.5).motion("character", "celebrate")
        .at(6.5).particles("confetti", "confetti", position=(400, 100), duration=2.0)

        # End
        .at(9.0).emotion("character", "neutral")
        .at(9.5).marker("outro")
        .build()
    )

    # Show timeline info
    print(f"Timeline duration: {timeline.duration}s")
    print(f"Total events: {sum(len(t.events) for t in timeline.tracks.values())}")
    print(f"Markers: {list(timeline._markers.keys())}")

    # Sample events at different times
    for time in [0.0, 2.0, 5.5, 7.0]:
        events = timeline.get_events_at_time(time)
        print(f"  t={time:.1f}s: {len(events)} events")

    return timeline


def demo_lipsync_integration():
    """Demo 2: Lip sync with expressions."""
    print("\n=== Demo 2: Lip Sync Integration ===")

    # Create simulated lip sync
    lip_sync = create_simulated_lipsync(5.0)

    # Create facial animator
    animator = FacialAnimator()
    animator.set_emotion(Emotion.HAPPY, 0.7)

    # Render a few frames showing lip sync
    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)

    renderer = QuickRenderer(width=400, height=300, fps=30)

    # Mouth shape colors for visualization
    shape_colors = {
        'A': '#FF6B6B',  # Red - closed
        'B': '#4ECDC4',  # Teal - teeth
        'C': '#45B7D1',  # Blue - open
        'D': '#F7DC6F',  # Yellow - wide
        'E': '#BB8FCE',  # Purple - rounded
        'F': '#58D68D',  # Green - puckered
        'X': '#95A5A6',  # Gray - rest
    }

    def render_lipsync_frame(img: Image.Image, t: float, frame_num: int) -> None:
        draw = ImageDraw.Draw(img)

        # Get current mouth shape
        shape = lip_sync.get_shape_at_time(t)
        color = shape_colors.get(shape, '#FFFFFF')

        # Update facial animator with lip sync
        animator.set_lip_sync_shape(shape)
        face = animator.update(1/30)

        # Draw simple face
        # Head
        draw.ellipse([100, 50, 300, 250], fill='#FFEAA7', outline='#F39C12', width=3)

        # Eyes (affected by expression/blink)
        eye_height = int(30 * face.left_eye.openness)
        draw.ellipse([140, 100-eye_height//2, 170, 100+eye_height//2], fill='white', outline='#2C3E50')
        draw.ellipse([230, 100-eye_height//2, 260, 100+eye_height//2], fill='white', outline='#2C3E50')
        draw.ellipse([148, 95, 162, 109], fill='#2C3E50')  # Left pupil
        draw.ellipse([238, 95, 252, 109], fill='#2C3E50')  # Right pupil

        # Mouth (lip sync shape)
        mouth_sizes = {
            'A': (40, 10),   # Closed
            'B': (50, 20),   # Teeth
            'C': (60, 40),   # Open
            'D': (70, 50),   # Wide
            'E': (50, 45),   # Rounded
            'F': (30, 35),   # Puckered
            'X': (35, 5),    # Rest
        }
        mw, mh = mouth_sizes.get(shape, (50, 30))
        mx, my = 200 - mw//2, 180

        if shape in ('E', 'F'):  # Rounded shapes
            draw.ellipse([mx, my, mx+mw, my+mh], fill=color, outline='#8B4513', width=2)
        else:
            draw.rounded_rectangle([mx, my, mx+mw, my+mh], radius=10, fill=color, outline='#8B4513', width=2)

        # Show info
        draw.text((10, 10), f"Time: {t:.2f}s", fill='#2C3E50')
        draw.text((10, 30), f"Shape: {shape}", fill=color)
        draw.text((10, 50), f"Emotion: happy", fill='#2C3E50')

    renderer.on_frame(render_lipsync_frame)
    output_path = output_dir / "demo_lipsync.gif"
    renderer.render_gif(str(output_path), duration=5.0)
    print(f"  Rendered: {output_path}")

    return lip_sync


def demo_audio_mixing():
    """Demo 3: Audio track mixing."""
    print("\n=== Demo 3: Audio Mixing ===")

    # Create audio timeline
    audio_timeline = AudioTimeline(duration=30.0)

    # Add tracks (with fake paths for demo)
    audio_timeline.add_dialogue("voice/narration.wav", start=0.0)
    audio_timeline.add_music("music/background.mp3", start=0.0, volume=0.3, loop=True)
    audio_timeline.add_sfx("sfx/whoosh.wav", start=5.0)
    audio_timeline.add_sfx("sfx/impact.wav", start=10.0)
    audio_timeline.add_ambient("ambient/room_tone.wav", start=0.0, volume=0.2, loop=True)

    # Show mix info
    events = audio_timeline.mixer.get_timeline_events()
    print(f"  Audio events: {len(events)}")
    for time, track, event in events[:5]:
        print(f"    {time:.1f}s [{track}]: {Path(event.path).name}")

    return audio_timeline


def demo_beat_sync():
    """Demo 4: Beat-synchronized animation."""
    print("\n=== Demo 4: Beat Sync Animation ===")

    # Since we don't have actual audio, simulate beat data
    # In real usage, this would come from BeatDetector
    simulated_beats = [
        0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0,  # Regular beats
        4.25, 4.5, 4.75, 5.0,  # Double-time
    ]

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)

    renderer = QuickRenderer(width=400, height=300, fps=30)

    # Animation state
    state = {'shake_intensity': 0.0}

    def render_beat_frame(img: Image.Image, t: float, frame_num: int) -> None:
        draw = ImageDraw.Draw(img)

        # Check if we're near a beat
        on_beat = any(abs(t - beat) < 0.05 for beat in simulated_beats)

        if on_beat:
            state['shake_intensity'] = 1.0
        else:
            state['shake_intensity'] *= 0.9  # Decay

        shake = state['shake_intensity']

        # Background color pulses on beat
        bg_value = int(40 + 30 * shake)
        img.paste((bg_value, bg_value, bg_value + 10), [0, 0, img.width, img.height])

        # Draw waveform visualization
        for i in range(20):
            x = 30 + i * 17
            height = int(20 + (50 * shake if on_beat else 20) * (0.5 + 0.5 * ((i + int(t*10)) % 5) / 5))
            draw.rectangle([x, 150-height//2, x+12, 150+height//2], fill='#3498DB')

        # Beat indicator
        if on_beat:
            draw.ellipse([170, 20, 230, 80], fill='#E74C3C')
            draw.text((183, 40), "BEAT", fill='white')

        # Time display
        draw.text((10, 270), f"Time: {t:.2f}s", fill='white')

        # Show next beat
        future_beats = [b for b in simulated_beats if b > t]
        if future_beats:
            draw.text((250, 270), f"Next: {future_beats[0]:.2f}s", fill='#95A5A6')

    renderer.on_frame(render_beat_frame)
    output_path = output_dir / "demo_beat_sync.gif"
    renderer.render_gif(str(output_path), duration=5.0)
    print(f"  Rendered: {output_path}")


def demo_combined_pipeline():
    """Demo 5: Full combined pipeline."""
    print("\n=== Demo 5: Combined Pipeline ===")

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)

    # Setup all systems
    animator = FacialAnimator()
    motion_blender = MotionBlender()
    motion_blender.set_base_motion(IdleMotion())
    motion_blender.set_base_motion(BreathingMotion())

    camera = Camera(viewport_size=(400, 300))
    particles = create_sparkle_emitter(position=(350, 50))

    # Lip sync
    lip_sync = create_simulated_lipsync(8.0)

    # Build timeline
    timeline = (TimelineBuilder(duration=8.0, fps=30)
        .at(0.0).emotion("char", "neutral")
        .at(1.0).emotion("char", "happy")
        .at(1.0).motion("char", "wave")
        .at(2.5).camera_shake("impact", 0.3)
        .at(3.0).emotion("char", "surprised")
        .at(4.0).emotion("char", "happy")
        .at(4.0).motion("char", "celebrate")
        .at(6.0).emotion("char", "neutral")
        .build()
    )

    # Emotion mapping
    emotion_map = {
        "neutral": Emotion.NEUTRAL,
        "happy": Emotion.HAPPY,
        "surprised": Emotion.SURPRISED,
    }
    current_emotion = Emotion.NEUTRAL

    renderer = QuickRenderer(width=400, height=300, fps=30)

    mouth_colors = {
        'A': '#FF6B6B', 'B': '#4ECDC4', 'C': '#45B7D1',
        'D': '#F7DC6F', 'E': '#BB8FCE', 'F': '#58D68D', 'X': '#95A5A6',
    }

    # State for closure
    state = {'current_emotion': current_emotion}

    def render_combined_frame(img: Image.Image, t: float, frame_num: int) -> None:
        draw = ImageDraw.Draw(img)
        dt = 1/30

        # Process timeline events
        events = timeline.get_events_at_time(t)
        for event in events:
            if event.event_type == EventType.SET_EMOTION:
                em_name = event.params.get('emotion', 'neutral')
                if em_name in emotion_map:
                    state['current_emotion'] = emotion_map[em_name]
                    animator.set_emotion(state['current_emotion'], 0.8)
            elif event.event_type == EventType.CAMERA_SHAKE:
                camera.add_shake(ShakeType.IMPACT,
                               intensity=event.params.get('intensity', 0.5))

        # Update systems
        shape = lip_sync.get_shape_at_time(t)
        animator.set_lip_sync_shape(shape)
        face = animator.update(dt)

        motion_blender.update(dt)
        camera.update(frame=int(t*30), fps=30)
        particles.update(dt)

        # Get camera offset
        shake_x, shake_y = camera._shake_offset

        # Draw background with gradient
        for y in range(img.height):
            shade = int(40 + 20 * y / img.height)
            draw.line([(0, y), (img.width, y)], fill=(shade, shade, shade + 10))

        # Character position with camera shake
        char_x = int(200 + shake_x)
        char_y = int(150 + shake_y)

        # Draw character body
        draw.ellipse([char_x-60, char_y, char_x+60, char_y+100], fill='#3498DB')

        # Draw head
        draw.ellipse([char_x-45, char_y-90, char_x+45, char_y+10], fill='#FFEAA7', outline='#F39C12', width=2)

        # Eyes
        eye_h = int(20 * face.left_eye.openness)
        draw.ellipse([char_x-30, char_y-55, char_x-10, char_y-55+eye_h], fill='white')
        draw.ellipse([char_x+10, char_y-55, char_x+30, char_y-55+eye_h], fill='white')
        if eye_h > 5:
            draw.ellipse([char_x-25, char_y-52, char_x-15, char_y-42], fill='#2C3E50')
            draw.ellipse([char_x+15, char_y-52, char_x+25, char_y-42], fill='#2C3E50')

        # Mouth
        mouth_color = mouth_colors.get(shape, '#FFFFFF')
        mouth_sizes = {'A': (25, 8), 'B': (35, 15), 'C': (40, 25),
                      'D': (50, 35), 'E': (35, 30), 'F': (20, 25), 'X': (25, 5)}
        mw, mh = mouth_sizes.get(shape, (30, 20))
        draw.rounded_rectangle([char_x-mw//2, char_y-20, char_x+mw//2, char_y-20+mh],
                              radius=8, fill=mouth_color, outline='#8B4513')

        # Draw particles
        for p in particles.particles:
            if p.life > 0:
                px, py = int(p.position.x + shake_x), int(p.position.y + shake_y)
                draw.ellipse([px-3, py-3, px+3, py+3], fill='#F1C40F')

        # HUD
        draw.rectangle([0, 0, 400, 25], fill='#2C3E50')
        draw.text((10, 5), f"t={t:.2f}s | Emotion: {state['current_emotion'].name} | Mouth: {shape}", fill='white')

    renderer.on_frame(render_combined_frame)
    output_path = output_dir / "demo_full_pipeline.gif"
    renderer.render_gif(str(output_path), duration=8.0)

    # Apply vignette to final result
    print(f"  Rendered: {output_path}")


def main():
    """Run all demos."""
    print("=" * 60)
    print("FULL PIPELINE DEMO")
    print("=" * 60)

    # Demo 1: Timeline
    timeline = demo_timeline_sequencing()

    # Demo 2: Lip sync
    lip_sync = demo_lipsync_integration()

    # Demo 3: Audio mixing
    audio = demo_audio_mixing()

    # Demo 4: Beat sync
    demo_beat_sync()

    # Demo 5: Combined
    demo_combined_pipeline()

    print("\n" + "=" * 60)
    print("All demos complete!")
    print("Check output files in: pipeline/examples/output/")
    print("=" * 60)


if __name__ == "__main__":
    main()
