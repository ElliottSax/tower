"""Tests for animation.scene module."""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image

from pipeline.animation.scene import Scene, SceneLayer
from pipeline.animation.keyframes import AnimationClip, EasingType


class TestSceneLayer:
    """Tests for SceneLayer dataclass."""

    def test_default_values(self):
        """Test default layer values."""
        layer = SceneLayer(name="test")
        assert layer.z_order == 0
        assert layer.visible is True
        assert layer.opacity == 1.0
        assert layer.position == (0, 0)
        assert layer.scale == 1.0
        assert layer.rotation == 0.0
        assert layer.image_path is None
        assert layer.character is None
        assert layer.color is None

    def test_get_animated_properties_no_animation(self):
        """Test properties without animation."""
        layer = SceneLayer(
            name="test",
            position=(100, 200),
            scale=1.5,
            rotation=45.0,
            opacity=0.8
        )

        props = layer.get_animated_properties(0)

        assert props["position"] == (100, 200)
        assert props["scale"] == 1.5
        assert props["rotation"] == 45.0
        assert props["opacity"] == 0.8
        assert props["visible"] is True

    def test_get_animated_properties_with_animation(self):
        """Test properties with animation."""
        layer = SceneLayer(name="test", position=(0, 0))
        layer.animation = AnimationClip("test_anim")
        layer.animation.add_track("position").add_keyframe(0, (0, 0)).add_keyframe(10, (100, 100))
        layer.animation.add_track("opacity").add_keyframe(0, 1.0).add_keyframe(10, 0.5)

        props_start = layer.get_animated_properties(0)
        props_mid = layer.get_animated_properties(5)
        props_end = layer.get_animated_properties(10)

        # Start
        assert props_start["position"] == (0, 0)
        assert props_start["opacity"] == 1.0

        # Mid (interpolated)
        assert props_mid["position"] == (50, 50)
        assert props_mid["opacity"] == 0.75

        # End
        assert props_end["position"] == (100, 100)
        assert props_end["opacity"] == 0.5

    def test_load_image(self, temp_dir: Path):
        """Test image loading."""
        # Create test image
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (100, 100), (255, 0, 0, 255)).save(img_path)

        layer = SceneLayer(name="test", image_path=str(img_path))
        loaded = layer.load_image()

        assert loaded is not None
        assert loaded.size == (100, 100)
        assert loaded.mode == "RGBA"

    def test_load_image_caching(self, temp_dir: Path):
        """Test image caching."""
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (100, 100), (255, 0, 0, 255)).save(img_path)

        layer = SceneLayer(name="test", image_path=str(img_path))

        img1 = layer.load_image()
        img2 = layer.load_image()

        assert img1 is img2  # Same object (cached)

    def test_load_image_not_found(self):
        """Test loading nonexistent image."""
        layer = SceneLayer(name="test", image_path="/nonexistent/image.png")
        assert layer.load_image() is None

    def test_render_invisible_layer(self):
        """Test rendering invisible layer returns None."""
        layer = SceneLayer(name="test", visible=False)
        result = layer.render(0, (100, 100))
        assert result is None

    def test_render_zero_opacity(self):
        """Test rendering zero opacity layer returns None."""
        layer = SceneLayer(name="test", opacity=0.0)
        result = layer.render(0, (100, 100))
        assert result is None

    def test_render_color_layer(self):
        """Test rendering solid color layer."""
        layer = SceneLayer(name="bg", color=(255, 0, 0, 255))
        result = layer.render(0, (100, 100))

        assert result is not None
        assert result.size == (100, 100)
        # Check pixel color
        assert result.getpixel((50, 50)) == (255, 0, 0, 255)

    def test_render_image_layer(self, temp_dir: Path):
        """Test rendering image layer."""
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (50, 50), (0, 255, 0, 255)).save(img_path)

        layer = SceneLayer(name="test", image_path=str(img_path))
        result = layer.render(0, (100, 100))

        assert result is not None
        assert result.size == (50, 50)

    def test_render_with_scale(self, temp_dir: Path):
        """Test rendering with scale."""
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (100, 100), (0, 255, 0, 255)).save(img_path)

        layer = SceneLayer(name="test", image_path=str(img_path), scale=2.0)
        result = layer.render(0, (400, 400))

        assert result is not None
        assert result.size == (200, 200)

    def test_clear_cache(self, temp_dir: Path):
        """Test cache clearing."""
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (100, 100), (255, 0, 0, 255)).save(img_path)

        layer = SceneLayer(name="test", image_path=str(img_path))
        layer.load_image()
        assert layer._cached_image is not None

        layer.clear_cache()
        assert layer._cached_image is None


class TestScene:
    """Tests for Scene class."""

    def test_creation(self):
        """Test scene creation with defaults."""
        scene = Scene()
        assert scene.name == "untitled"
        assert scene.width == 1920
        assert scene.height == 1080
        assert scene.fps == 30.0
        assert scene.duration == 10.0
        assert scene.background_color == (0, 0, 0, 255)

    def test_creation_custom(self):
        """Test scene creation with custom values."""
        scene = Scene(
            name="intro",
            width=1280,
            height=720,
            fps=24.0,
            duration=5.0,
            background_color=(255, 255, 255, 255)
        )
        assert scene.name == "intro"
        assert scene.width == 1280
        assert scene.height == 720
        assert scene.fps == 24.0
        assert scene.duration == 5.0

    def test_total_frames(self):
        """Test total frames calculation."""
        scene = Scene(fps=30.0, duration=10.0)
        assert scene.total_frames == 300

        scene2 = Scene(fps=24.0, duration=5.0)
        assert scene2.total_frames == 120

    def test_canvas_size(self):
        """Test canvas size property."""
        scene = Scene(width=1920, height=1080)
        assert scene.canvas_size == (1920, 1080)

    def test_add_layer(self):
        """Test adding a layer."""
        scene = Scene()
        layer = scene.add_layer("background", z_order=-10, position=(0, 0))

        assert layer.name == "background"
        assert layer.z_order == -10
        assert "background" in scene.layers

    def test_add_layer_with_image(self, temp_dir: Path):
        """Test adding layer with image."""
        img_path = temp_dir / "bg.png"
        Image.new('RGBA', (100, 100), (0, 0, 255, 255)).save(img_path)

        scene = Scene()
        layer = scene.add_layer("background", image_path=str(img_path))

        assert layer.image_path == str(img_path)

    def test_add_character_layer(self):
        """Test adding character layer."""
        scene = Scene()

        mock_character = MagicMock()
        mock_character.position = (960, 540)

        layer = scene.add_character_layer("narrator", mock_character, z_order=10)

        assert layer.character is mock_character
        assert layer.z_order == 10
        assert layer.position == (960, 540)

    def test_add_color_layer(self):
        """Test adding solid color layer."""
        scene = Scene()
        layer = scene.add_color_layer("bg", (0, 0, 0, 255), z_order=-100)

        assert layer.color == (0, 0, 0, 255)
        assert layer.z_order == -100

    def test_get_layer(self):
        """Test getting layer by name."""
        scene = Scene()
        scene.add_layer("test")

        assert scene.get_layer("test") is not None
        assert scene.get_layer("nonexistent") is None

    def test_remove_layer(self):
        """Test removing layer."""
        scene = Scene()
        scene.add_layer("test")

        assert scene.remove_layer("test") is True
        assert scene.get_layer("test") is None
        assert scene.remove_layer("nonexistent") is False

    def test_get_sorted_layers(self):
        """Test layer sorting by z_order."""
        scene = Scene()
        scene.add_layer("top", z_order=100)
        scene.add_layer("middle", z_order=50)
        scene.add_layer("bottom", z_order=0)

        sorted_layers = scene.get_sorted_layers()

        assert sorted_layers[0].name == "bottom"
        assert sorted_layers[1].name == "middle"
        assert sorted_layers[2].name == "top"

    def test_set_audio(self):
        """Test setting audio."""
        scene = Scene()
        scene.set_audio("audio.wav", offset=0.5)

        assert scene.audio_path == "audio.wav"
        assert scene.audio_offset == 0.5

    def test_render_frame_empty_scene(self):
        """Test rendering empty scene."""
        scene = Scene(width=100, height=100, background_color=(255, 0, 0, 255))
        frame = scene.render_frame(0)

        assert frame.size == (100, 100)
        assert frame.getpixel((50, 50)) == (255, 0, 0, 255)

    def test_render_frame_with_color_layer(self):
        """Test rendering with color layer."""
        scene = Scene(width=100, height=100)
        scene.add_color_layer("overlay", (0, 255, 0, 128), z_order=10)

        frame = scene.render_frame(0)

        assert frame.size == (100, 100)
        # Should be blended color

    def test_render_frames(self):
        """Test rendering multiple frames."""
        scene = Scene(width=100, height=100, fps=10, duration=1.0)

        frames = scene.render_frames(0, 5)

        assert len(frames) == 5
        assert all(isinstance(f, Image.Image) for f in frames)

    def test_render_frames_with_progress(self):
        """Test rendering frames with progress callback."""
        scene = Scene(width=100, height=100, fps=10, duration=1.0)

        progress_calls = []
        def on_progress(current, total):
            progress_calls.append((current, total))

        frames = scene.render_frames(0, 5, on_progress=on_progress)

        assert len(progress_calls) == 5
        assert progress_calls[-1] == (5, 5)

    def test_to_dict(self):
        """Test serialization to dictionary."""
        scene = Scene(name="test", width=1280, height=720)
        scene.add_layer("bg", z_order=0)
        scene.add_color_layer("overlay", (255, 255, 255, 128), z_order=10)
        scene.set_audio("audio.wav", offset=0.5)
        scene.metadata["version"] = "1.0"

        d = scene.to_dict()

        assert d["name"] == "test"
        assert d["width"] == 1280
        assert d["height"] == 720
        assert d["audio_path"] == "audio.wav"
        assert d["audio_offset"] == 0.5
        assert len(d["layers"]) == 2
        assert d["metadata"]["version"] == "1.0"

    def test_save_and_load(self, temp_dir: Path):
        """Test saving and loading scene."""
        scene = Scene(name="test", width=1280, height=720, fps=24.0, duration=5.0)
        scene.add_layer("bg", z_order=0, position=(10, 20))
        scene.add_color_layer("fill", (100, 100, 100, 255), z_order=-10)

        save_path = temp_dir / "scene.json"
        scene.save(str(save_path))

        loaded = Scene.load(str(save_path))

        assert loaded.name == "test"
        assert loaded.width == 1280
        assert loaded.height == 720
        assert loaded.fps == 24.0
        assert loaded.duration == 5.0
        assert len(loaded.layers) == 2
        assert loaded.get_layer("bg") is not None
        assert loaded.get_layer("fill") is not None

    def test_load_with_animation(self, temp_dir: Path):
        """Test loading scene with layer animation."""
        scene = Scene(name="animated")
        layer = scene.add_layer("moving", position=(0, 0))
        layer.animation = AnimationClip("move")
        layer.animation.add_track("position").add_keyframe(0, (0, 0)).add_keyframe(30, (100, 100))

        save_path = temp_dir / "animated.json"
        scene.save(str(save_path))

        loaded = Scene.load(str(save_path))
        loaded_layer = loaded.get_layer("moving")

        assert loaded_layer.animation is not None
        # Note: lists after JSON roundtrip
        assert loaded_layer.animation.get_value("position", 15) == [50, 50]

    def test_clear_caches(self, temp_dir: Path):
        """Test clearing all caches."""
        img_path = temp_dir / "test.png"
        Image.new('RGBA', (100, 100), (255, 0, 0, 255)).save(img_path)

        scene = Scene()
        layer = scene.add_layer("img", image_path=str(img_path))
        layer.load_image()

        assert layer._cached_image is not None

        scene.clear_caches()

        assert layer._cached_image is None
