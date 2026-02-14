"""Tests for animation/scene_renderer.py module."""

import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock, PropertyMock

import pytest
from PIL import Image

from pipeline.animation.scene_renderer import (
    RenderSettings,
    RenderProgress,
    AnimatedCharacter,
    SceneRenderer,
    QuickRenderer,
)
from pipeline.animation.scene import Scene
from pipeline.animation.character import Character
from pipeline.animation.camera import Camera, ParallaxCamera
from pipeline.animation.expressions import Emotion


class TestRenderSettings:
    """Tests for RenderSettings dataclass."""

    def test_default_values(self):
        """Test default render settings."""
        settings = RenderSettings()

        assert settings.width == 1920
        assert settings.height == 1080
        assert settings.fps == 30
        assert settings.codec == 'libx264'
        assert settings.quality == 'high'
        assert settings.format == 'mp4'

    def test_custom_values(self):
        """Test custom render settings."""
        settings = RenderSettings(
            width=1280,
            height=720,
            fps=24,
            codec='libx265',
            quality='best',
            format='mkv'
        )

        assert settings.width == 1280
        assert settings.height == 720
        assert settings.fps == 24
        assert settings.codec == 'libx265'
        assert settings.quality == 'best'
        assert settings.format == 'mkv'

    def test_quality_crf_mapping(self):
        """Test quality to CRF mapping."""
        settings = RenderSettings()

        assert settings.QUALITY_CRF['draft'] == 28
        assert settings.QUALITY_CRF['medium'] == 23
        assert settings.QUALITY_CRF['high'] == 18
        assert settings.QUALITY_CRF['best'] == 15

    def test_get_crf_high(self):
        """Test get_crf for high quality."""
        settings = RenderSettings(quality='high')
        assert settings.get_crf() == 18

    def test_get_crf_low(self):
        """Test get_crf for low quality."""
        settings = RenderSettings(quality='draft')
        assert settings.get_crf() == 28

    def test_get_crf_unknown(self):
        """Test get_crf for unknown quality defaults to 18."""
        settings = RenderSettings(quality='unknown')
        assert settings.get_crf() == 18


class TestRenderProgress:
    """Tests for RenderProgress dataclass."""

    def test_default_values(self):
        """Test default progress values."""
        progress = RenderProgress()

        assert progress.current_frame == 0
        assert progress.total_frames == 0
        assert progress.stage == 'initializing'
        assert progress.percent == 0.0

    def test_custom_values(self):
        """Test custom progress values."""
        progress = RenderProgress(
            current_frame=50,
            total_frames=100,
            stage='rendering',
            percent=50.0
        )

        assert progress.current_frame == 50
        assert progress.total_frames == 100
        assert progress.stage == 'rendering'
        assert progress.percent == 50.0


class TestAnimatedCharacter:
    """Tests for AnimatedCharacter class."""

    @pytest.fixture
    def mock_character(self):
        """Create a mock character."""
        character = MagicMock(spec=Character)
        character.rig = None
        return character

    def test_creation(self, mock_character):
        """Test animated character creation."""
        anim_char = AnimatedCharacter(mock_character)

        assert anim_char.character is mock_character
        assert anim_char.facial is not None
        assert anim_char.motion is not None
        assert anim_char.position == (0.0, 0.0)
        assert anim_char.scale == 1.0
        assert anim_char.visible is True

    def test_set_emotion(self, mock_character):
        """Test setting emotion."""
        anim_char = AnimatedCharacter(mock_character)
        anim_char.set_emotion(Emotion.HAPPY)

        assert Emotion.HAPPY in anim_char.facial.expression.emotion_weights

    def test_set_lip_sync_shape(self, mock_character):
        """Test setting lip sync shape."""
        anim_char = AnimatedCharacter(mock_character)
        anim_char.set_lip_sync_shape('C')

        assert anim_char.facial.lip_sync.target_shape == 'C'

    def test_update(self, mock_character):
        """Test update returns face and pose."""
        anim_char = AnimatedCharacter(mock_character)
        face, pose = anim_char.update(0.033)

        assert face is not None
        assert pose is not None


class TestSceneRenderer:
    """Tests for SceneRenderer class."""

    @pytest.fixture
    def mock_scene(self):
        """Create a mock scene."""
        scene = MagicMock(spec=Scene)
        scene.background = None
        scene.layers = []
        return scene

    def test_creation_default_settings(self, mock_scene):
        """Test renderer creation with default settings."""
        renderer = SceneRenderer(mock_scene)

        assert renderer.scene is mock_scene
        assert renderer.settings is not None
        assert renderer.settings.width == 1920

    def test_creation_custom_settings(self, mock_scene):
        """Test renderer creation with custom settings."""
        settings = RenderSettings(width=1280, height=720)
        renderer = SceneRenderer(mock_scene, settings)

        assert renderer.settings.width == 1280
        assert renderer.settings.height == 720

    def test_initial_state(self, mock_scene):
        """Test initial renderer state."""
        renderer = SceneRenderer(mock_scene)

        assert renderer.time == 0.0
        assert renderer.frame == 0
        assert renderer.camera is None
        assert renderer.parallax_camera is None
        assert len(renderer.animated_characters) == 0
        assert len(renderer.particle_emitters) == 0
        assert len(renderer.post_effects) == 0

    def test_add_character(self, mock_scene):
        """Test adding an animated character."""
        renderer = SceneRenderer(mock_scene)
        mock_char = MagicMock(spec=Character)
        mock_char.rig = None

        anim_char = renderer.add_character(
            "test_char",
            mock_char,
            position=(100, 200),
            scale=1.5
        )

        assert "test_char" in renderer.animated_characters
        assert anim_char.position == (100, 200)
        assert anim_char.scale == 1.5

    def test_set_camera(self, mock_scene):
        """Test setting camera."""
        renderer = SceneRenderer(mock_scene)
        camera = Camera()

        renderer.set_camera(camera)

        assert renderer.camera is camera

    def test_set_parallax_camera(self, mock_scene):
        """Test setting parallax camera."""
        renderer = SceneRenderer(mock_scene)
        camera = ParallaxCamera()

        renderer.set_parallax_camera(camera)

        assert renderer.parallax_camera is camera

    def test_add_particle_emitter(self, mock_scene):
        """Test adding particle emitter."""
        renderer = SceneRenderer(mock_scene)
        emitter = MagicMock()

        renderer.add_particle_emitter(emitter)

        assert emitter in renderer.particle_emitters

    def test_add_post_effect(self, mock_scene):
        """Test adding post effect."""
        renderer = SceneRenderer(mock_scene)

        def my_effect(img):
            return img

        renderer.add_post_effect(my_effect)

        assert my_effect in renderer.post_effects

    def test_render_frame_basic(self, mock_scene):
        """Test basic frame rendering."""
        renderer = SceneRenderer(mock_scene)

        frame = renderer.render_frame(0, 0.033)

        assert isinstance(frame, Image.Image)
        assert frame.size == (1920, 1080)
        assert frame.mode == 'RGBA'

    def test_render_frame_with_camera(self, mock_scene):
        """Test frame rendering with camera."""
        renderer = SceneRenderer(mock_scene)
        camera = MagicMock(spec=Camera)
        camera.vignette_intensity = 0  # No vignette effect
        renderer.set_camera(camera)

        frame = renderer.render_frame(0, 0.033)

        assert isinstance(frame, Image.Image)
        camera.update.assert_called_once()

    def test_render_frame_with_post_effects(self, mock_scene):
        """Test frame rendering with post effects."""
        renderer = SceneRenderer(mock_scene)

        effect_called = []
        def tracking_effect(img):
            effect_called.append(True)
            return img

        renderer.add_post_effect(tracking_effect)
        renderer.render_frame(0, 0.033)

        assert len(effect_called) == 1


class TestSceneRendererGetAssetKey:
    """Tests for _get_layer_asset_key method."""

    @pytest.fixture
    def renderer(self):
        """Create a renderer."""
        scene = MagicMock()
        scene.background = None
        scene.layers = []
        return SceneRenderer(scene)

    def test_mouth_open(self, renderer):
        """Test mouth asset key when open."""
        face = MagicMock()
        face.mouth.open = 0.5
        pose = MagicMock()

        key = renderer._get_layer_asset_key('mouth', face, pose)

        assert key == 'open'

    def test_mouth_closed(self, renderer):
        """Test mouth asset key when closed."""
        face = MagicMock()
        face.mouth.open = 0.0
        pose = MagicMock()

        key = renderer._get_layer_asset_key('mouth', face, pose)

        assert key == 'closed'

    def test_eyes_open(self, renderer):
        """Test eyes asset key when open."""
        face = MagicMock()
        face.left_eye.openness = 1.0
        face.right_eye.openness = 1.0
        pose = MagicMock()

        key = renderer._get_layer_asset_key('eyes', face, pose)

        assert key == 'open'

    def test_eyes_closed(self, renderer):
        """Test eyes asset key when closed."""
        face = MagicMock()
        face.left_eye.openness = 0.1
        face.right_eye.openness = 0.1
        pose = MagicMock()

        key = renderer._get_layer_asset_key('eyes', face, pose)

        assert key == 'closed'

    def test_eyes_half(self, renderer):
        """Test eyes asset key when half open."""
        face = MagicMock()
        face.left_eye.openness = 0.5
        face.right_eye.openness = 0.5
        pose = MagicMock()

        key = renderer._get_layer_asset_key('eyes', face, pose)

        assert key == 'half'

    def test_eyebrows_raised(self, renderer):
        """Test eyebrows asset key when raised."""
        face = MagicMock()
        face.left_eyebrow.height = 0.5
        face.right_eyebrow.height = 0.5
        pose = MagicMock()

        key = renderer._get_layer_asset_key('eyebrows', face, pose)

        assert key == 'raised'

    def test_eyebrows_lowered(self, renderer):
        """Test eyebrows asset key when lowered."""
        face = MagicMock()
        face.left_eyebrow.height = -0.5
        face.right_eyebrow.height = -0.5
        pose = MagicMock()

        key = renderer._get_layer_asset_key('eyebrows', face, pose)

        assert key == 'lowered'

    def test_default_layer(self, renderer):
        """Test default asset key for unknown layer."""
        face = MagicMock()
        pose = MagicMock()

        key = renderer._get_layer_asset_key('unknown_layer', face, pose)

        assert key == 'default'


class TestQuickRenderer:
    """Tests for QuickRenderer class."""

    def test_creation_defaults(self):
        """Test quick renderer creation with defaults."""
        renderer = QuickRenderer()

        assert renderer.width == 800
        assert renderer.height == 600
        assert renderer.fps == 30
        assert len(renderer.frame_callbacks) == 0

    def test_creation_custom(self):
        """Test quick renderer creation with custom values."""
        renderer = QuickRenderer(width=1920, height=1080, fps=60)

        assert renderer.width == 1920
        assert renderer.height == 1080
        assert renderer.fps == 60

    def test_on_frame_registers_callback(self):
        """Test on_frame registers callback."""
        renderer = QuickRenderer()

        def my_callback(frame, time, frame_num):
            pass

        renderer.on_frame(my_callback)

        assert my_callback in renderer.frame_callbacks

    def test_render_frames_basic(self):
        """Test basic frame rendering."""
        renderer = QuickRenderer(width=100, height=100, fps=10)

        frames = renderer.render_frames(0.5)

        assert len(frames) == 5  # 0.5s * 10fps
        assert all(isinstance(f, Image.Image) for f in frames)
        assert all(f.size == (100, 100) for f in frames)

    def test_render_frames_with_callback(self):
        """Test frame rendering with callback."""
        renderer = QuickRenderer(width=100, height=100, fps=10)

        callback_calls = []
        def tracking_callback(frame, time, frame_num):
            callback_calls.append((time, frame_num))

        renderer.on_frame(tracking_callback)
        frames = renderer.render_frames(0.3)

        assert len(callback_calls) == 3
        assert callback_calls[0][1] == 0
        assert callback_calls[2][1] == 2

    def test_render_gif(self, temp_dir):
        """Test GIF rendering."""
        renderer = QuickRenderer(width=50, height=50, fps=5)

        output_path = str(temp_dir / "test.gif")
        result = renderer.render_gif(output_path, 0.4)

        assert result is True
        assert Path(output_path).exists()

        # Verify it's a valid GIF
        gif = Image.open(output_path)
        assert gif.format == "GIF"

    def test_render_gif_empty(self):
        """Test GIF rendering with no frames."""
        renderer = QuickRenderer(fps=10)

        # Duration 0 = no frames
        result = renderer.render_gif("output.gif", 0.0)

        assert result is False

    @patch("subprocess.run")
    def test_render_video(self, mock_run, temp_dir):
        """Test video rendering."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = QuickRenderer(width=100, height=100, fps=10)

        output_path = str(temp_dir / "test.mp4")
        result = renderer.render_video(output_path, 0.3)

        assert result is True
        mock_run.assert_called_once()

    @patch("subprocess.run")
    def test_render_video_ffmpeg_failure(self, mock_run, temp_dir):
        """Test video rendering with FFmpeg failure."""
        mock_run.return_value = MagicMock(returncode=1)

        renderer = QuickRenderer(width=100, height=100, fps=10)

        output_path = str(temp_dir / "test.mp4")
        result = renderer.render_video(output_path, 0.3)

        assert result is False

    def test_render_video_no_frames(self):
        """Test video rendering with no frames."""
        renderer = QuickRenderer(fps=10)

        result = renderer.render_video("output.mp4", 0.0)

        assert result is False


class TestSceneRendererVideo:
    """Tests for video rendering methods."""

    @pytest.fixture
    def renderer_with_mock_scene(self):
        """Create renderer with mock scene."""
        scene = MagicMock()
        scene.background = None
        scene.layers = []
        settings = RenderSettings(width=100, height=100, fps=10)
        return SceneRenderer(scene, settings)

    @patch("subprocess.run")
    @patch("shutil.rmtree")
    def test_render_video_success(self, mock_rmtree, mock_run, renderer_with_mock_scene, temp_dir):
        """Test successful video rendering."""
        mock_run.return_value = MagicMock(returncode=0)

        output_path = str(temp_dir / "output.mp4")
        result = renderer_with_mock_scene.render_video(output_path, 0.3)

        assert result is True

    @patch("subprocess.run")
    @patch("shutil.rmtree")
    def test_render_video_with_progress(self, mock_rmtree, mock_run, renderer_with_mock_scene, temp_dir):
        """Test video rendering with progress callback."""
        mock_run.return_value = MagicMock(returncode=0)

        progress_updates = []
        def on_progress(progress):
            progress_updates.append(progress.stage)

        output_path = str(temp_dir / "output.mp4")
        renderer_with_mock_scene.render_video(output_path, 0.2, on_progress=on_progress)

        assert 'rendering' in progress_updates
        assert 'encoding' in progress_updates

    @patch("subprocess.run")
    @patch("shutil.rmtree")
    def test_render_video_cleans_up(self, mock_rmtree, mock_run, renderer_with_mock_scene, temp_dir):
        """Test temp files are cleaned up."""
        mock_run.return_value = MagicMock(returncode=0)

        output_path = str(temp_dir / "output.mp4")
        renderer_with_mock_scene.render_video(output_path, 0.1)

        mock_rmtree.assert_called_once()

    @patch("subprocess.run")
    def test_encode_video_no_temp_dir(self, mock_run, renderer_with_mock_scene):
        """Test encode_video returns False without temp dir."""
        renderer_with_mock_scene.temp_dir = None

        result = renderer_with_mock_scene._encode_video("output.mp4", 10)

        assert result is False

    @patch("subprocess.run", side_effect=FileNotFoundError())
    def test_encode_video_ffmpeg_not_found(self, mock_run, renderer_with_mock_scene, temp_dir):
        """Test encode_video handles missing FFmpeg."""
        renderer_with_mock_scene.temp_dir = temp_dir

        result = renderer_with_mock_scene._encode_video("output.mp4", 10)

        assert result is False


class TestSceneRendererIntegration:
    """Integration tests for scene renderer."""

    def test_full_render_pipeline(self):
        """Test complete render pipeline."""
        # Create scene
        scene = MagicMock()
        scene.background = None
        scene.layers = []

        # Create settings
        settings = RenderSettings(width=200, height=150, fps=10)

        # Create renderer
        renderer = SceneRenderer(scene, settings)

        # Add mock camera
        camera = MagicMock(spec=Camera)
        camera.vignette_intensity = 0
        renderer.set_camera(camera)

        # Add post effect
        def grayscale(img):
            return img.convert('L').convert('RGBA')

        renderer.add_post_effect(grayscale)

        # Render multiple frames
        frames = []
        for i in range(5):
            frame = renderer.render_frame(i, 0.1)
            frames.append(frame)
            renderer.time += 0.1
            renderer.frame = i

        assert len(frames) == 5
        assert all(f.size == (200, 150) for f in frames)

    def test_quick_renderer_with_drawing(self):
        """Test quick renderer with custom drawing."""
        renderer = QuickRenderer(width=100, height=100, fps=10)

        from PIL import ImageDraw

        def draw_circle(frame, time, frame_num):
            draw = ImageDraw.Draw(frame)
            x = 50 + int(time * 20) % 40
            draw.ellipse([x-10, 40, x+10, 60], fill=(255, 0, 0, 255))

        renderer.on_frame(draw_circle)
        frames = renderer.render_frames(0.5)

        # Verify frames have different content (circle moves)
        assert len(frames) == 5
        # First and last frame should be different
        assert frames[0].tobytes() != frames[-1].tobytes()
