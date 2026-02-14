# Programmatic 2D Animation Pipeline

A Python framework for creating character lip-sync animations entirely through code.

## Features

- **Lip Sync Generation**: Integrates with Rhubarb Lip Sync for automatic mouth shape detection
- **Character System**: Modular character rigs with body parts, mouth shapes, and eye states
- **Keyframe Animation**: Full keyframe animation system with multiple easing functions
- **Scene Composition**: Layer-based scene composition with backgrounds, characters, and overlays
- **Multiple Renderers**: Output to video (MP4, WebM), GIF, or frame sequences
- **Project Format**: JSON-based project files (.charproj) for declarative animation definition
- **CLI Interface**: Command-line tools for all operations

## Installation

```bash
# Install Python dependencies
pip install Pillow

# Optional: Install MoviePy for additional video features
pip install moviepy

# External tools (install separately):
# - Rhubarb Lip Sync: https://github.com/DanielSWolf/rhubarb-lip-sync
# - FFmpeg: https://ffmpeg.org/
```

## Quick Start

### Python API

```python
from pipeline import AnimationPipeline, create_project

# Create a new project
pipeline = create_project("my_animation")

# Generate lip sync from audio
lipsync = pipeline.generate_lipsync("audio/speech.wav", "audio/transcript.txt")

# Load character and apply lip sync
character = pipeline.load_character("characters/narrator", position=(960, 540))
character.apply_lipsync(lipsync, fps=30)
character.add_random_blinks(total_frames=lipsync.duration * 30)

# Create scene
scene = pipeline.create_scene("main", duration=lipsync.duration)
scene.add_layer("background", image_path="backgrounds/office.png")
scene.add_character_layer("narrator", character)
scene.set_audio("audio/speech.wav")

# Render to video
pipeline.render(scene, "output/video.mp4")
```

### CLI

```bash
# Initialize a new project
python -m pipeline init my_project

# Generate lip sync data
python -m pipeline lipsync audio.wav --transcript script.txt -o lipsync.json

# Render a project file
python -m pipeline render project.charproj -o output.mp4

# Quick character animation from audio
python -m pipeline animate characters/narrator audio.wav -o output.mp4

# Fast preview (half resolution, skip frames)
python -m pipeline preview project.charproj --scale 0.5 --skip 1
```

## Project Structure

```
my_project/
├── pipeline.json          # Project configuration
├── assets/
│   ├── characters/
│   │   └── narrator/
│   │       ├── character.json   # Character rig definition
│   │       ├── body/
│   │       │   └── idle.png
│   │       ├── mouth/
│   │       │   ├── A.png - F.png  # Basic mouth shapes
│   │       │   └── G.png, H.png, X.png  # Extended shapes
│   │       └── eyes/
│   │           ├── open.png
│   │           ├── half.png
│   │           └── closed.png
│   ├── backgrounds/
│   │   └── office.png
│   └── audio/
│       ├── narration.wav
│       └── narration.txt    # Optional transcript
├── output/
│   └── video.mp4
└── .cache/
    └── narration_lipsync.json  # Cached lip sync data
```

## Character Rig Format

```json
{
  "name": "narrator",
  "body_layers": {
    "body": {
      "path": "body/idle.png",
      "anchor": [0.5, 1.0],
      "z_order": 0
    }
  },
  "mouth_shapes": {
    "A": "mouth/A.png",
    "B": "mouth/B.png",
    "C": "mouth/C.png",
    "D": "mouth/D.png",
    "E": "mouth/E.png",
    "F": "mouth/F.png",
    "X": "mouth/X.png"
  },
  "eye_states": {
    "open": "eyes/open.png",
    "half": "eyes/half.png",
    "closed": "eyes/closed.png"
  },
  "mouth_offset": [0, -150],
  "eye_offset": [0, -200]
}
```

## Mouth Shapes

The pipeline uses Rhubarb's mouth shape system:

| Shape | Description | Phonemes |
|-------|-------------|----------|
| A | Closed mouth | P, B, M |
| B | Clenched teeth | K, S, T consonants |
| C | Open mouth | E, AE vowels |
| D | Wide open | AA vowels |
| E | Slightly rounded | AO, ER sounds |
| F | Puckered lips | UW, OW, W sounds |
| G | Upper teeth on lower lip (optional) | F, V sounds |
| H | Tongue raised (optional) | L sounds |
| X | Rest/idle position (optional) | Silence |

## Keyframe Animation

```python
from pipeline import AnimationClip, EasingType

# Create animation clip
clip = AnimationClip("character_move")

# Add position animation
position = clip.add_track("position")
position.add_keyframe(0, (100, 100))
position.add_keyframe(30, (500, 100), EasingType.EASE_OUT)
position.add_keyframe(60, (500, 400), EasingType.EASE_IN_OUT)

# Available easing functions:
# LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT
# EASE_IN_QUAD, EASE_OUT_QUAD, EASE_IN_OUT_QUAD
# EASE_IN_CUBIC, EASE_OUT_CUBIC, EASE_IN_OUT_CUBIC
# EASE_IN_ELASTIC, EASE_OUT_ELASTIC, EASE_OUT_BOUNCE
# STEP
```

## Renderers

| Renderer | Output | Features |
|----------|--------|----------|
| DirectRenderer | PNG/JPG frames | Fast, simple |
| FFmpegRenderer | MP4/WebM/MOV | Full codec control |
| MoviePyRenderer | MP4/WebM/GIF | Easy audio handling |
| GifRenderer | Animated GIF | Optimized for GIF |
| PreviewRenderer | Low-res frames | Fast previews |

## Requirements

- Python 3.10+
- Pillow (required)
- MoviePy (optional, for MoviePyRenderer)
- Rhubarb Lip Sync (external, for lip sync generation)
- FFmpeg (external, for video encoding)

## License

MIT License
