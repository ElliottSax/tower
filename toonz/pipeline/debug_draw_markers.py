#!/usr/bin/env python3
"""Debug by patching draw methods to add markers."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion
import fullbody_animation as fb
import math

# Store original methods
_orig_draw_hair_side_back = fb.FullBodyCharacter._draw_hair_side_back
_orig_draw_legs_side = fb.FullBodyCharacter._draw_legs_side
_orig_draw_body_side = fb.FullBodyCharacter._draw_body_side
_orig_draw_arms_side = fb.FullBodyCharacter._draw_arms_side
_orig_draw_neck_side = fb.FullBodyCharacter._draw_neck_side
_orig_draw_head_side = fb.FullBodyCharacter._draw_head_side
_orig_draw_hair_side_front = fb.FullBodyCharacter._draw_hair_side_front

# Patched methods that add debug markers
def patched_draw_hair_side_back(self, draw, x, y, s, walk):
    # Draw marker at position
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(255, 0, 0), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"HAIR_BACK y={y:.0f}", fill=(255, 0, 0))
    _orig_draw_hair_side_back(self, draw, x, y, s, walk)

def patched_draw_legs_side(self, draw, base_x, base_y, s, walk, weight):
    draw.ellipse([base_x-5, base_y-5, base_x+5, base_y+5], fill=(0, 255, 0), outline=(255, 255, 255))
    draw.text((base_x+10, base_y-5), f"LEGS base_y={base_y:.0f}", fill=(0, 255, 0))
    _orig_draw_legs_side(self, draw, base_x, base_y, s, walk, weight)

def patched_draw_body_side(self, draw, x, y, s, breath, walk, weight):
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(0, 0, 255), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"BODY y={y:.0f}", fill=(0, 0, 255))
    _orig_draw_body_side(self, draw, x, y, s, breath, walk, weight)

def patched_draw_arms_side(self, draw, x, y, s, breath, walk):
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(255, 255, 0), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"ARMS y={y:.0f}", fill=(255, 255, 0))
    _orig_draw_arms_side(self, draw, x, y, s, breath, walk)

def patched_draw_neck_side(self, draw, x, y, s, breath):
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(255, 0, 255), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"NECK y={y:.0f}", fill=(255, 0, 255))
    _orig_draw_neck_side(self, draw, x, y, s, breath)

def patched_draw_head_side(self, draw, x, y, s, face, anim_state):
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(0, 255, 255), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"HEAD y={y:.0f}", fill=(0, 255, 255))
    _orig_draw_head_side(self, draw, x, y, s, face, anim_state)

def patched_draw_hair_side_front(self, draw, x, y, s):
    draw.ellipse([x-5, y-5, x+5, y+5], fill=(255, 128, 0), outline=(255, 255, 255))
    draw.text((x+10, y-5), f"HAIR_FRT y={y:.0f}", fill=(255, 128, 0))
    _orig_draw_hair_side_front(self, draw, x, y, s)

def main():
    # Patch the methods
    fb.FullBodyCharacter._draw_hair_side_back = patched_draw_hair_side_back
    fb.FullBodyCharacter._draw_legs_side = patched_draw_legs_side
    fb.FullBodyCharacter._draw_body_side = patched_draw_body_side
    fb.FullBodyCharacter._draw_arms_side = patched_draw_arms_side
    fb.FullBodyCharacter._draw_neck_side = patched_draw_neck_side
    fb.FullBodyCharacter._draw_head_side = patched_draw_head_side
    fb.FullBodyCharacter._draw_hair_side_front = patched_draw_hair_side_front

    WIDTH, HEIGHT = 1400, 900
    img = Image.new('RGBA', (WIDTH, HEIGHT), (30, 30, 40))
    draw = ImageDraw.Draw(img)

    ground_y = int(HEIGHT * 0.88)
    scale = 1.5

    # Side view character
    char = fb.FullBodyCharacter(WIDTH // 2, ground_y, scale=scale)
    char.set_view(90)

    p = char.proportions

    # Draw ground
    draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(100, 100, 100), width=2)
    draw.text((10, ground_y+5), f"GROUND y={ground_y}", fill=(100, 100, 100))

    # Create face/animation state
    facial = FacialAnimator()
    facial.set_emotion(Emotion.NEUTRAL)
    face = facial.update(1/24)
    anim = char.update(1/24, 0, 24, time=0, target_pos=(WIDTH // 2, ground_y))

    # Draw character
    char.draw(img, face, anim, (0, 0))

    # Draw legend
    legend_y = 50
    draw.text((20, legend_y), "DEBUG MARKERS:", fill=(255, 255, 255))
    legend_items = [
        ("HAIR_BACK", (255, 0, 0)),
        ("LEGS", (0, 255, 0)),
        ("BODY (crotch)", (0, 0, 255)),
        ("ARMS (shoulder)", (255, 255, 0)),
        ("NECK (chin)", (255, 0, 255)),
        ("HEAD (center)", (0, 255, 255)),
        ("HAIR_FRONT", (255, 128, 0)),
    ]
    for i, (label, color) in enumerate(legend_items):
        y = legend_y + 25 + i * 22
        draw.ellipse([20, y, 30, y+10], fill=color)
        draw.text((40, y-2), label, fill=color)

    # Print buffer info
    char_width = int(p.shoulder_width * 2.5 + 100 * scale)
    char_height = int(p.total_height + 50 * scale)
    char_ground_y = char_height - int(25 * scale)

    info = [
        f"Char buffer: {char_width}x{char_height}",
        f"char_ground_y (in buffer): {char_ground_y}",
        f"head_size: {p.head_size:.1f}",
        f"total_height: {p.total_height:.1f}",
    ]
    for i, text in enumerate(info):
        draw.text((WIDTH - 300, 50 + i * 20), text, fill=(180, 180, 180))

    output_path = "debug_draw_markers.png"
    img.save(output_path)
    print(f"Output: {output_path}")

    # Print expected Y positions
    body_bob = anim['walk']['body_bob']
    breath_shoulders = anim['breath']['shoulders']

    print(f"\n=== Expected Y positions (in buffer) ===")
    print(f"char_ground_y: {char_ground_y}")
    print(f"head_y: {char_ground_y - p.total_height + p.head_size * 0.5 + body_bob + breath_shoulders * 0.5:.1f}")
    print(f"neck_y: {char_ground_y - p.total_height + p.chin_y + body_bob + breath_shoulders:.1f}")
    print(f"shoulder_y: {char_ground_y - p.total_height + p.shoulder_y + body_bob + breath_shoulders * 2:.1f}")
    print(f"torso_y: {char_ground_y - p.crotch_y + body_bob:.1f}")

if __name__ == "__main__":
    main()
