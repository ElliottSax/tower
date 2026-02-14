#!/usr/bin/env python3
"""Quick test - 3 seconds."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import (
    FacialAnimator, Emotion, Camera, ShakeType,
    apply_vignette, apply_color_grade, QuickRenderer
)
from pipeline.renderers.ffmpeg_renderer import FFmpegRenderer
from fullbody_animation import FullBodyCharacter, create_starfield, draw_background

FFMPEG_PATH = "/mnt/e/projects/pod/venv/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"

def main():
    WIDTH, HEIGHT = 1280, 720  # Smaller for speed
    FPS = 24
    DURATION = 4.0  # Short test
    
    print(f"Quick test: {WIDTH}x{HEIGHT}, {DURATION}s at {FPS}fps")
    
    renderer = QuickRenderer(WIDTH, HEIGHT, fps=FPS)
    ground_y = int(HEIGHT * 0.88)
    character = FullBodyCharacter(WIDTH // 2, ground_y, scale=1.5)
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)
    camera = Camera((WIDTH, HEIGHT))
    stars = create_starfield(WIDTH, HEIGHT, 100)
    
    triggered = set()
    
    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)
        dt = 1.0 / FPS
        
        # Start walking after 1s
        if time >= 1.0 and 'walk' not in triggered:
            character.set_walking(True)
            triggered.add('walk')
        
        # Stop at 3s
        if time >= 3.0 and 'stop' not in triggered:
            character.set_walking(False)
            triggered.add('stop')
        
        face = facial.update(dt)
        camera.update(dt)
        
        walk_state = character.walk.walk_blend.value
        target = (WIDTH // 2, ground_y)
        anim_state = character.update(dt, frame_num, FPS, time=time, target_pos=target)
        shake = camera._shake_offset
        
        draw_background(draw, WIDTH, HEIGHT, time, stars, shake, walk_state)
        character.draw(frame, face, anim_state, shake)
        
        draw.text((WIDTH // 2, 30), "Full-Body Test", fill=(255, 255, 255), anchor="mm")
    
    renderer.on_frame(draw_frame)
    frames = renderer.render_frames(DURATION)
    
    # Apply post-processing
    processed = [apply_vignette(f, intensity=0.2) for f in frames]
    
    output_path = "quick_test.mp4"
    ffmpeg = FFmpegRenderer(codec="h264", quality="high", ffmpeg_path=FFMPEG_PATH)
    ffmpeg.encode_video(processed, output_path, fps=FPS)
    
    import os
    print(f"Output: {output_path} ({os.path.getsize(output_path) / 1024:.0f} KB)")

if __name__ == "__main__":
    main()
