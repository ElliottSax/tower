"""
Programmatic 2D Animation Pipeline

A Python framework for creating character lip-sync animations
from audio using Rhubarb and rendering to video.

Usage:
    from pipeline import AnimationPipeline, create_project

    # Create new project
    pipeline = create_project("my_project")

    # Or use existing project
    pipeline = AnimationPipeline("existing_project")

    # Generate lip sync from audio
    lipsync = pipeline.generate_lipsync("audio.wav", "transcript.txt")

    # Load character and apply lip sync
    character = pipeline.load_character("characters/narrator")
    character.apply_lipsync(lipsync, fps=30)

    # Create scene
    scene = pipeline.create_scene("intro", duration=lipsync.duration)
    scene.add_layer("background", image_path="backgrounds/office.png")
    scene.add_character_layer("narrator", character)
    scene.set_audio("audio.wav")

    # Render to video
    pipeline.render(scene, "output.mp4")

CLI Usage:
    # Initialize project
    python -m pipeline init my_project

    # Generate lip sync
    python -m pipeline lipsync audio.wav -o lipsync.json

    # Render project
    python -m pipeline render project.charproj -o output.mp4

    # Quick character animation
    python -m pipeline animate characters/narrator audio.wav -o output.mp4
"""

__version__ = "0.1.0"

# Core
from .core.pipeline import AnimationPipeline, create_project
from .core.config import Config, OutputConfig, RhubarbConfig

# Lip sync
from .lipsync.rhubarb import RhubarbWrapper, LipSyncData, MouthCue, RhubarbError

# Animation
from .animation.character import Character, CharacterRig, LayerDefinition
from .animation.scene import Scene, SceneLayer
from .animation.keyframes import Keyframe, KeyframeTrack, AnimationClip, EasingType

# Renderers
from .renderers.base import BaseRenderer, RenderProgress
from .renderers.direct_renderer import DirectRenderer, PreviewRenderer, GifRenderer
from .renderers.ffmpeg_renderer import FFmpegRenderer

__all__ = [
    # Core
    "AnimationPipeline",
    "create_project",
    "Config",
    "OutputConfig",
    "RhubarbConfig",
    # Lip sync
    "RhubarbWrapper",
    "LipSyncData",
    "MouthCue",
    "RhubarbError",
    # Animation
    "Character",
    "CharacterRig",
    "LayerDefinition",
    "Scene",
    "SceneLayer",
    "Keyframe",
    "KeyframeTrack",
    "AnimationClip",
    "EasingType",
    # Renderers
    "BaseRenderer",
    "RenderProgress",
    "DirectRenderer",
    "PreviewRenderer",
    "GifRenderer",
    "FFmpegRenderer",
]
