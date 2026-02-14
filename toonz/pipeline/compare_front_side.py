#!/usr/bin/env python3
"""Side-by-side comparison of front and side views."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion
from fullbody_animation import FullBodyCharacter, draw_background, create_starfield

def main():
    WIDTH, HEIGHT = 1600, 900
    FPS = 24

    print("Creating side-by-side comparison...")

    img = Image.new('RGBA', (WIDTH, HEIGHT), (35, 32, 50))
    draw = ImageDraw.Draw(img)

    ground_y = int(HEIGHT * 0.88)
    scale = 1.8  # Larger for better visibility

    # Calculate positions
    front_x = WIDTH // 4
    side_x = WIDTH * 3 // 4

    # Create characters
    char_front = FullBodyCharacter(front_x, ground_y, scale=scale)
    char_side = FullBodyCharacter(side_x, ground_y, scale=scale)
    char_side.set_view(90)

    p = char_front.proportions

    # Create animation state
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    dt = 1.0 / FPS
    face = facial.update(dt)

    # Update characters
    anim_front = char_front.update(dt, 0, FPS, time=0, target_pos=(front_x, ground_y))
    anim_side = char_side.update(dt, 0, FPS, time=0, target_pos=(side_x, ground_y))

    # Draw background gradient
    for y in range(HEIGHT):
        t = y / HEIGHT
        r = int(35 + t * 20)
        g = int(32 + t * 20)
        b = int(50 + t * 15)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))

    # Draw ground
    draw.rectangle([0, ground_y, WIDTH, HEIGHT], fill=(45, 42, 60))
    draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(80, 75, 95), width=3)

    # Draw characters
    char_front.draw(img, face, anim_front, (0, 0))
    char_side.draw(img, face, anim_side, (0, 0))

    # Draw labels
    draw.text((front_x, 40), "FRONT VIEW", fill=(255, 255, 255), anchor="mm")
    draw.text((side_x, 40), "SIDE VIEW", fill=(255, 255, 255), anchor="mm")

    # Draw dividing line
    draw.line([(WIDTH // 2, 60), (WIDTH // 2, ground_y - 20)], fill=(100, 95, 115), width=2)

    # Draw height reference lines
    top_y = ground_y - p.total_height
    for view_x in [front_x, side_x]:
        # Dotted vertical guide
        for y in range(int(top_y), int(ground_y), 10):
            if (y // 10) % 2 == 0:
                draw.line([(view_x + 120, y), (view_x + 120, y + 5)], fill=(60, 60, 80), width=1)

    # Print info
    print(f"Scale: {scale}")
    print(f"Head size: {p.head_size:.1f}px")
    print(f"Total height: {p.total_height:.1f}px")
    print(f"Ground Y: {ground_y}")

    output_path = "compare_front_side.png"
    img.save(output_path)
    print(f"Output: {output_path}")

    # Also test with walking
    print("\nCreating walking comparison...")

    img2 = Image.new('RGBA', (WIDTH, HEIGHT), (35, 32, 50))
    draw2 = ImageDraw.Draw(img2)

    # Background
    for y in range(HEIGHT):
        t = y / HEIGHT
        r = int(35 + t * 20)
        g = int(32 + t * 20)
        b = int(50 + t * 15)
        draw2.line([(0, y), (WIDTH, y)], fill=(r, g, b))

    draw2.rectangle([0, ground_y, WIDTH, HEIGHT], fill=(45, 42, 60))
    draw2.line([(0, ground_y), (WIDTH, ground_y)], fill=(80, 75, 95), width=3)

    # Reset characters with walking
    char_front2 = FullBodyCharacter(front_x, ground_y, scale=scale)
    char_side2 = FullBodyCharacter(side_x, ground_y, scale=scale)
    char_side2.set_view(90)
    char_front2.set_walking(True)
    char_side2.set_walking(True)

    # Advance a few frames into the walk cycle
    for i in range(15):
        anim_front2 = char_front2.update(dt, i, FPS, time=i*dt, target_pos=(front_x, ground_y))
        anim_side2 = char_side2.update(dt, i, FPS, time=i*dt, target_pos=(side_x, ground_y))

    face2 = facial.update(dt)

    char_front2.draw(img2, face2, anim_front2, (0, 0))
    char_side2.draw(img2, face2, anim_side2, (0, 0))

    draw2.text((front_x, 40), "FRONT VIEW (WALKING)", fill=(255, 255, 255), anchor="mm")
    draw2.text((side_x, 40), "SIDE VIEW (WALKING)", fill=(255, 255, 255), anchor="mm")
    draw2.line([(WIDTH // 2, 60), (WIDTH // 2, ground_y - 20)], fill=(100, 95, 115), width=2)

    output_path2 = "compare_walking.png"
    img2.save(output_path2)
    print(f"Output: {output_path2}")

if __name__ == "__main__":
    main()
