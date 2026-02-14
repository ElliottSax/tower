#!/usr/bin/env python3
"""Test side profile view."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion
from fullbody_animation import FullBodyCharacter

def main():
    WIDTH, HEIGHT = 1280, 720
    FPS = 24

    print("Side profile test - comparing front and side views")

    # Create output image
    img = Image.new('RGBA', (WIDTH, HEIGHT), (40, 35, 60))
    draw = ImageDraw.Draw(img)

    # Draw title
    draw.text((WIDTH // 2, 30), "Side Profile Test", fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH // 4, 60), "Front View", fill=(200, 200, 200), anchor="mm")
    draw.text((WIDTH * 3 // 4, 60), "Side View", fill=(200, 200, 200), anchor="mm")

    ground_y = int(HEIGHT * 0.88)

    # Create two characters
    char_front = FullBodyCharacter(WIDTH // 4, ground_y, scale=1.2)
    char_side = FullBodyCharacter(WIDTH * 3 // 4, ground_y, scale=1.2)

    # Set side view for second character
    char_side.set_view(90)  # 90 degrees = full side profile

    # Create facial animator
    facial = FacialAnimator()
    facial.set_emotion(Emotion.HAPPY)

    # Update both characters
    dt = 1.0 / FPS
    face = facial.update(dt)

    anim_front = char_front.update(dt, 0, FPS, time=0, target_pos=(WIDTH // 4, ground_y))
    anim_side = char_side.update(dt, 0, FPS, time=0, target_pos=(WIDTH * 3 // 4, ground_y))

    # Draw ground line
    draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(60, 55, 80), width=2)

    # Draw both characters
    char_front.draw(img, face, anim_front, (0, 0))
    char_side.draw(img, face, anim_side, (0, 0))

    # Draw dividing line
    draw.line([(WIDTH // 2, 80), (WIDTH // 2, HEIGHT - 50)], fill=(80, 75, 100), width=2)

    # Save output
    output_path = "side_profile_test.png"
    img.save(output_path)
    print(f"Output: {output_path}")

    # Also test with walking
    img2 = Image.new('RGBA', (WIDTH, HEIGHT), (40, 35, 60))
    draw2 = ImageDraw.Draw(img2)

    draw2.text((WIDTH // 2, 30), "Side Profile Walking Test", fill=(255, 255, 255), anchor="mm")
    draw2.text((WIDTH // 4, 60), "Front View (Walking)", fill=(200, 200, 200), anchor="mm")
    draw2.text((WIDTH * 3 // 4, 60), "Side View (Walking)", fill=(200, 200, 200), anchor="mm")

    # Reset characters with walking
    char_front2 = FullBodyCharacter(WIDTH // 4, ground_y, scale=1.2)
    char_side2 = FullBodyCharacter(WIDTH * 3 // 4, ground_y, scale=1.2)

    char_side2.set_view(90)
    char_front2.set_walking(True)
    char_side2.set_walking(True)

    # Simulate a few frames to get into walking pose
    for i in range(12):
        anim_front2 = char_front2.update(dt, i, FPS, time=i*dt, target_pos=(WIDTH // 4, ground_y))
        anim_side2 = char_side2.update(dt, i, FPS, time=i*dt, target_pos=(WIDTH * 3 // 4, ground_y))

    face2 = facial.update(dt)

    # Draw ground line
    draw2.line([(0, ground_y), (WIDTH, ground_y)], fill=(60, 55, 80), width=2)

    # Draw both characters
    char_front2.draw(img2, face2, anim_front2, (0, 0))
    char_side2.draw(img2, face2, anim_side2, (0, 0))

    # Draw dividing line
    draw2.line([(WIDTH // 2, 80), (WIDTH // 2, HEIGHT - 50)], fill=(80, 75, 100), width=2)

    output_path2 = "side_profile_walking_test.png"
    img2.save(output_path2)
    print(f"Output: {output_path2}")

if __name__ == "__main__":
    main()
