#!/usr/bin/env python3
"""Debug side profile - visualize coordinate positions."""
import sys
sys.path.insert(0, '/mnt/e/projects/toonz')

from PIL import Image, ImageDraw, ImageFont
from pipeline.animation import FacialAnimator, Emotion
from fullbody_animation import FullBodyCharacter, BodyProportions

def main():
    WIDTH, HEIGHT = 1400, 900

    print("Debug side profile - showing coordinate markers")

    img = Image.new('RGBA', (WIDTH, HEIGHT), (30, 30, 40))
    draw = ImageDraw.Draw(img)

    # Create character
    ground_y = int(HEIGHT * 0.9)
    char_x = WIDTH // 2
    scale = 1.5

    character = FullBodyCharacter(char_x, ground_y, scale=scale)
    character.set_view(90)  # Side profile

    p = character.proportions
    s = character.scale

    # Draw ground line
    draw.line([(0, ground_y), (WIDTH, ground_y)], fill=(100, 100, 100), width=2)
    draw.text((10, ground_y + 5), f"GROUND (y={ground_y})", fill=(150, 150, 150))

    # Calculate key positions (same as in draw() method)
    char_width = int(p.shoulder_width * 2.5 + 100 * s)
    char_height = int(p.total_height + 50 * s)
    char_ground_y = char_height - int(25 * s)
    char_center_x = char_width // 2

    # These are positions WITHIN the temp buffer
    body_bob = 0
    hip_sway = 0
    torso_x = char_center_x + hip_sway
    torso_y = char_ground_y - p.crotch_y + body_bob  # This is CROTCH Y in buffer

    head_y_buffer = char_ground_y - p.total_height + p.head_size * 0.5 + body_bob
    shoulder_y_buffer = char_ground_y - p.total_height + p.shoulder_y + body_bob
    neck_y_buffer = char_ground_y - p.total_height + p.chin_y + body_bob

    # Convert to screen coordinates
    paste_x = int(char_x - char_width // 2)
    paste_y = int(ground_y - char_height + 25 * s)

    # Screen positions
    screen_ground = ground_y
    screen_top = paste_y
    screen_head_center = paste_y + head_y_buffer
    screen_chin = paste_y + neck_y_buffer
    screen_shoulder = paste_y + shoulder_y_buffer
    screen_crotch = paste_y + torso_y
    screen_center_x = char_x

    # Draw debug info
    draw.text((10, 10), f"Scale: {scale}", fill=(200, 200, 200))
    draw.text((10, 30), f"Head size: {p.head_size:.1f}px", fill=(200, 200, 200))
    draw.text((10, 50), f"Total height: {p.total_height:.1f}px", fill=(200, 200, 200))
    draw.text((10, 70), f"Char buffer: {char_width}x{char_height}", fill=(200, 200, 200))
    draw.text((10, 90), f"char_ground_y (buffer): {char_ground_y}", fill=(200, 200, 200))

    # Draw proportions reference on the left
    ref_x = 100
    ref_ground = ground_y
    ref_top = ref_ground - p.total_height

    draw.text((10, 120), "8-HEAD PROPORTIONS:", fill=(255, 255, 100))

    colors = [
        (255, 100, 100),  # Head 1
        (255, 150, 100),  # Head 2
        (255, 200, 100),  # Head 3
        (255, 255, 100),  # Head 4
        (200, 255, 100),  # Head 5
        (100, 255, 100),  # Head 6
        (100, 255, 200),  # Head 7
        (100, 200, 255),  # Head 8
    ]

    labels = ["1:Head", "2:Chest", "3:Navel", "4:Crotch", "5:Thigh", "6:Knee", "7:Calf", "8:Ankle"]

    for i in range(8):
        y_top = ref_top + i * p.head_size
        y_bot = y_top + p.head_size
        draw.rectangle([ref_x - 20, y_top, ref_x + 20, y_bot], outline=colors[i], width=2)
        draw.text((ref_x + 30, y_top + p.head_size/2 - 8), labels[i], fill=colors[i])

    # Draw vertical line at character center
    draw.line([(screen_center_x, screen_top), (screen_center_x, screen_ground)],
              fill=(80, 80, 100), width=1)

    # Draw horizontal markers at key positions
    marker_len = 60

    def draw_marker(y, label, color, offset=0):
        draw.line([(screen_center_x - marker_len + offset, y),
                   (screen_center_x + marker_len + offset, y)], fill=color, width=2)
        draw.text((screen_center_x + marker_len + 10 + offset, y - 8),
                  f"{label} (y={y:.0f})", fill=color)

    draw_marker(screen_top, "TOP OF HEAD", (255, 100, 100))
    draw_marker(screen_head_center, "HEAD CENTER", (255, 150, 100))
    draw_marker(screen_chin, "CHIN", (255, 200, 100))
    draw_marker(screen_shoulder, "SHOULDER", (200, 255, 100))
    draw_marker(screen_crotch, "CROTCH/TORSO_Y", (100, 255, 200))
    draw_marker(screen_ground, "GROUND", (100, 100, 255))

    # Now render the actual character
    facial = FacialAnimator()
    facial.set_emotion(Emotion.NEUTRAL)

    dt = 1.0 / 24
    face = facial.update(dt)
    anim_state = character.update(dt, 0, 24, time=0, target_pos=(char_x, ground_y))

    # Draw character
    character.draw(img, face, anim_state, (0, 0))

    # Draw buffer outline where character is pasted
    draw.rectangle([paste_x, paste_y, paste_x + char_width, paste_y + char_height],
                   outline=(255, 0, 255, 128), width=1)
    draw.text((paste_x, paste_y - 15), "CHAR BUFFER", fill=(255, 0, 255))

    # Print debug values
    print(f"\n=== COORDINATE DEBUG ===")
    print(f"Ground Y: {ground_y}")
    print(f"Character center X: {char_x}")
    print(f"Scale: {scale}")
    print(f"")
    print(f"Proportions:")
    print(f"  head_size: {p.head_size}")
    print(f"  total_height: {p.total_height}")
    print(f"  chin_y: {p.chin_y} (from top)")
    print(f"  shoulder_y: {p.shoulder_y} (from top)")
    print(f"  crotch_y: {p.crotch_y} (from top)")
    print(f"")
    print(f"Buffer coordinates:")
    print(f"  char_ground_y: {char_ground_y}")
    print(f"  head_y: {head_y_buffer}")
    print(f"  neck_y: {neck_y_buffer}")
    print(f"  shoulder_y: {shoulder_y_buffer}")
    print(f"  torso_y (crotch): {torso_y}")
    print(f"")
    print(f"Screen coordinates:")
    print(f"  paste position: ({paste_x}, {paste_y})")
    print(f"  head center: {screen_head_center}")
    print(f"  shoulder: {screen_shoulder}")
    print(f"  crotch: {screen_crotch}")

    output_path = "debug_side_profile.png"
    img.save(output_path)
    print(f"\nOutput: {output_path}")

if __name__ == "__main__":
    main()
