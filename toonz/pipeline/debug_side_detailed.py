#!/usr/bin/env python3
"""Detailed debug - trace actual drawing coordinates."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion
from fullbody_animation import FullBodyCharacter, BodyProportions
import math

def main():
    WIDTH, HEIGHT = 1600, 1000

    print("Detailed side profile debug")

    # Create two images - one for front view, one for side view
    img = Image.new('RGBA', (WIDTH, HEIGHT), (30, 30, 40))
    draw = ImageDraw.Draw(img)

    ground_y = int(HEIGHT * 0.9)
    scale = 1.5

    # Create two characters
    char_front = FullBodyCharacter(WIDTH // 4, ground_y, scale=scale)
    char_side = FullBodyCharacter(WIDTH * 3 // 4, ground_y, scale=scale)
    char_side.set_view(90)

    p = char_front.proportions
    s = scale

    # Draw titles
    draw.text((WIDTH // 4, 30), "FRONT VIEW", fill=(255, 255, 255), anchor="mm")
    draw.text((WIDTH * 3 // 4, 30), "SIDE VIEW", fill=(255, 255, 255), anchor="mm")

    # Draw ground line
    draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(100, 100, 100), width=2)

    # Create facial state
    facial = FacialAnimator()
    facial.set_emotion(Emotion.NEUTRAL)
    dt = 1.0 / 24
    face = facial.update(dt)

    # Update both characters
    anim_front = char_front.update(dt, 0, 24, time=0, target_pos=(WIDTH // 4, ground_y))
    anim_side = char_side.update(dt, 0, 24, time=0, target_pos=(WIDTH * 3 // 4, ground_y))

    # Draw both characters
    char_front.draw(img, face, anim_front, (0, 0))
    char_side.draw(img, face, anim_side, (0, 0))

    # Now draw debug markers at key positions for BOTH views
    for char_x, label, color in [(WIDTH // 4, "FRONT", (100, 255, 100)),
                                   (WIDTH * 3 // 4, "SIDE", (255, 100, 100))]:
        # Calculate positions
        top_of_head = ground_y - p.total_height
        head_center = top_of_head + p.head_size * 0.5
        chin_y = top_of_head + p.chin_y
        shoulder_y = top_of_head + p.shoulder_y
        nipple_y = top_of_head + p.nipple_y
        navel_y = top_of_head + p.navel_y
        crotch_y = top_of_head + p.crotch_y
        knee_y = top_of_head + p.knee_y

        # Draw markers
        marker_size = 8

        def draw_marker(y, text, offset=0):
            marker_x = char_x + offset
            draw.ellipse([marker_x - marker_size, y - marker_size,
                         marker_x + marker_size, y + marker_size],
                        fill=color, outline=(255, 255, 255))
            draw.text((marker_x + marker_size + 5, y - 8), text, fill=color)

        # Draw all key positions
        markers = [
            (top_of_head, "TOP", 80),
            (head_center, "HEAD", 80),
            (chin_y, "CHIN", 80),
            (shoulder_y, "SHLD", 80),
            (nipple_y, "NIP", 80),
            (navel_y, "NAVL", 80),
            (crotch_y, "CRCH", 80),
            (knee_y, "KNEE", 80),
            (ground_y, "GND", 80),
        ]

        for y, text, offset in markers:
            draw_marker(y, text, offset)

    # Add some measurements
    draw.text((10, HEIGHT - 100), f"Scale: {scale}", fill=(200, 200, 200))
    draw.text((10, HEIGHT - 80), f"Head size: {p.head_size:.1f}px", fill=(200, 200, 200))
    draw.text((10, HEIGHT - 60), f"Total height: {p.total_height:.1f}px", fill=(200, 200, 200))
    draw.text((10, HEIGHT - 40), f"Ground Y: {ground_y}", fill=(200, 200, 200))
    draw.text((10, HEIGHT - 20), f"Top of head: {ground_y - p.total_height:.0f}", fill=(200, 200, 200))

    # Draw dividing line
    draw.line([(WIDTH // 2, 50), (WIDTH // 2, HEIGHT - 120)], fill=(80, 80, 100), width=2)

    output_path = "debug_side_detailed.png"
    img.save(output_path)
    print(f"Output: {output_path}")

    # Also create a version showing just the side view parts individually
    print("\n=== Creating parts breakdown ===")
    create_parts_breakdown()


def create_parts_breakdown():
    """Draw each body part separately to debug."""
    WIDTH, HEIGHT = 1800, 600

    img = Image.new('RGBA', (WIDTH, HEIGHT), (30, 30, 40))
    draw = ImageDraw.Draw(img)

    scale = 1.5
    ground_y = HEIGHT - 80

    # Create character
    char = FullBodyCharacter(100, ground_y, scale=scale)
    char.set_view(90)

    p = char.proportions
    s = char.scale

    # Get animation state
    facial = FacialAnimator()
    facial.set_emotion(Emotion.NEUTRAL)
    face = facial.update(1/24)
    anim = char.update(1/24, 0, 24, time=0, target_pos=(100, ground_y))

    walk = anim['walk']
    weight = anim['weight']
    breath = anim['breath']

    # Calculate buffer coordinates (same as in draw())
    char_width = int(p.shoulder_width * 2.5 + 100 * s)
    char_height = int(p.total_height + 50 * s)
    char_ground_y = char_height - int(25 * s)
    char_center_x = char_width // 2

    body_bob = walk['body_bob']
    hip_sway = walk['hip_sway']
    torso_x = char_center_x + hip_sway
    torso_y = char_ground_y - p.crotch_y + body_bob
    head_y = char_ground_y - p.total_height + p.head_size * 0.5 + body_bob + breath['shoulders'] * 0.5
    shoulder_y = char_ground_y - p.total_height + p.shoulder_y + body_bob + breath['shoulders'] * 2
    neck_y = char_ground_y - p.total_height + p.chin_y + body_bob + breath['shoulders']

    parts = [
        ("Hair Back", lambda d, x, y: char._draw_hair_side_back(d, x, y + head_y, s, walk)),
        ("Legs", lambda d, x, y: char._draw_legs_side(d, x + char_center_x, y + char_ground_y, s, walk, weight)),
        ("Body", lambda d, x, y: char._draw_body_side(d, x, y + torso_y, s, breath, walk, weight)),
        ("Arms", lambda d, x, y: char._draw_arms_side(d, x, y + shoulder_y, s, breath, walk)),
        ("Neck", lambda d, x, y: char._draw_neck_side(d, x, y + neck_y, s, breath)),
        ("Head", lambda d, x, y: char._draw_head_side(d, x, y + head_y, s, face, anim)),
        ("Hair Front", lambda d, x, y: char._draw_hair_side_front(d, x, y + head_y, s)),
    ]

    spacing = WIDTH // (len(parts) + 1)

    for i, (name, draw_func) in enumerate(parts):
        part_x = spacing * (i + 1)

        # Create a small buffer for this part
        buf = Image.new('RGBA', (300, 700), (50, 50, 60))
        buf_draw = ImageDraw.Draw(buf)

        # Draw ground line in buffer
        buf_ground = 600
        buf_draw.line([(0, buf_ground), (300, buf_ground)], fill=(100, 100, 100), width=1)

        # Draw the part centered in buffer
        try:
            draw_func(buf_draw, 150, buf_ground - char_ground_y)
        except Exception as e:
            buf_draw.text((10, 300), f"ERROR: {e}", fill=(255, 0, 0))

        # Add label
        buf_draw.text((150, 20), name, fill=(255, 255, 255), anchor="mm")

        # Draw coordinate markers
        buf_draw.line([(140, buf_ground - char_ground_y + head_y - 5),
                       (160, buf_ground - char_ground_y + head_y + 5)],
                      fill=(255, 100, 100), width=2)
        buf_draw.text((165, buf_ground - char_ground_y + head_y), "head_y", fill=(255, 100, 100))

        # Paste onto main image
        img.paste(buf, (part_x - 150, 0))

    output_path = "debug_parts_breakdown.png"
    img.save(output_path)
    print(f"Parts output: {output_path}")


if __name__ == "__main__":
    main()
