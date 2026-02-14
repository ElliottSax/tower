#!/usr/bin/env python3
"""Test side profile view in video."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion, QuickRenderer
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer
from fullbody_animation import FullBodyCharacter

FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"

def main():
    WIDTH, HEIGHT = 1280, 720
    FPS = 24
    DURATION = 4.0

    print(f"Side profile video test: {WIDTH}x{HEIGHT}, {DURATION}s at {FPS}fps")

    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)
    ground_y = int(HEIGHT * 0.88)

    # Create character in side view
    character = FullBodyCharacter(WIDTH // 2, ground_y, scale=1.5)
    character.set_view(90)  # Side profile

    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    triggered = set()

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS

        # Fill background
        for y in range(HEIGHT):
            t = y / HEIGHT
            r = int(40 + t * 20)
            g = int(35 + t * 20)
            b = int(60 + t * 20)
            draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))

        # Start walking after 0.5s
        if time >= 0.5 and 'walk' not in triggered:
            character.set_walking(True)
            triggered.add('walk')

        # Stop at 3s
        if time >= 3.0 and 'stop' not in triggered:
            character.set_walking(False)
            triggered.add('stop')

        face = facial.update(dt)
        target = (WIDTH // 2, ground_y)
        anim_state = character.update(dt, frame_num, FPS, time=time, target_pos=target)

        # Draw ground
        draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(60, 55, 80), width=2)

        # Draw character
        character.draw(frame, face, anim_state, (0, 0))

        # Title
        draw.text((WIDTH // 2, 30), "Side Profile View Test", fill=(255, 255, 255), anchor="mm")

    renderer.on_frame(draw_frame)
    frames = renderer.render_frames(DURATION)

    output_path = "side_profile_video_test.mp4"
    ffmpeg = FFmpegRenderer(codec="h264", quality="high", ffmpeg_path=FFMPEG_PATH)
    ffmpeg.encode_video(frames, output_path, fps=FPS)

    import os
    print(f"Output: {output_path} ({os.path.getsize(output_path) / 1024:.0f} KB)")

if __name__ == "__main__":
    main()
