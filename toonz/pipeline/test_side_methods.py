#!/usr/bin/env python3
"""Test all side profile methods individually."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw
from pipeline.animation import FacialAnimator, Emotion
from fullbody_animation import FullBodyCharacter

def test_method(name, method, args, img_size=(400, 600)):
    """Test a single drawing method."""
    try:
        img = Image.new('RGBA', img_size, (50, 50, 60))
        draw = ImageDraw.Draw(img)
        method(draw, *args)
        return True, img
    except Exception as e:
        return False, str(e)

def main():
    print("Testing all side profile methods...")

    # Create character
    char = FullBodyCharacter(200, 500, scale=1.5)
    char.set_view(90)
    p = char.proportions
    s = char.scale

    # Get animation state
    facial = FacialAnimator()
    facial.set_emotion(Emotion.NEUTRAL)
    face = facial.update(1/24)
    anim = char.update(1/24, 0, 24, time=0, target_pos=(200, 500))

    walk = anim['walk']
    weight = anim['weight']
    breath = anim['breath']

    # Test coordinates
    x = 200
    ground_y = 500
    head_y = ground_y - p.total_height + p.head_size * 0.5
    neck_y = ground_y - p.total_height + p.chin_y
    shoulder_y = ground_y - p.total_height + p.shoulder_y
    torso_y = ground_y - p.crotch_y

    print(f"\n=== Test coordinates ===")
    print(f"ground_y: {ground_y}")
    print(f"head_y: {head_y:.1f}")
    print(f"neck_y: {neck_y:.1f}")
    print(f"shoulder_y: {shoulder_y:.1f}")
    print(f"torso_y: {torso_y:.1f}")

    # Test each method
    methods = [
        ("_draw_hair_side_back", char._draw_hair_side_back, (x, head_y, s, walk)),
        ("_draw_legs_side", char._draw_legs_side, (x, ground_y, s, walk, weight)),
        ("_draw_body_side", char._draw_body_side, (x, torso_y, s, breath, walk, weight)),
        ("_draw_arms_side", char._draw_arms_side, (x, shoulder_y, s, breath, walk)),
        ("_draw_neck_side", char._draw_neck_side, (x, neck_y, s, breath)),
        ("_draw_head_side", char._draw_head_side, (x, head_y, s, face, anim)),
        ("_draw_hair_side_front", char._draw_hair_side_front, (x, head_y, s)),
    ]

    print(f"\n=== Method Tests ===")
    all_passed = True
    images = {}

    for name, method, args in methods:
        success, result = test_method(name, method, args)
        status = "✓ PASS" if success else f"✗ FAIL: {result}"
        print(f"{name}: {status}")
        if success:
            images[name] = result
        else:
            all_passed = False

    if all_passed:
        print("\n✓ All methods execute without errors")

        # Create combined output
        combined = Image.new('RGBA', (400 * len(images), 600), (30, 30, 40))
        for i, (name, img) in enumerate(images.items()):
            combined.paste(img, (i * 400, 0))
            draw = ImageDraw.Draw(combined)
            draw.text((i * 400 + 200, 20), name.replace("_draw_", ""), fill=(255, 255, 255), anchor="mm")

        combined.save("test_side_methods.png")
        print("\nOutput: test_side_methods.png")
    else:
        print("\n✗ Some methods failed!")

    return all_passed

if __name__ == "__main__":
    main()
