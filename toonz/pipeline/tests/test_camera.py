"""Tests for animation/camera.py module."""

import math
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from PIL import Image

from pipeline.animation.camera import (
    CameraState,
    Camera,
    ShakeType,
    ShakeInstance,
    ParallaxLayer,
    ParallaxCamera,
    DepthOfField,
)
from pipeline.animation.keyframes import AnimationClip


class TestCameraState:
    """Tests for CameraState dataclass."""

    def test_default_values(self):
        """Test default camera state."""
        state = CameraState()
        assert state.position == (0, 0)
        assert state.zoom == 1.0
        assert state.rotation == 0.0

    def test_custom_values(self):
        """Test camera state with custom values."""
        state = CameraState(
            position=(100, 200),
            zoom=1.5,
            rotation=45.0
        )
        assert state.position == (100, 200)
        assert state.zoom == 1.5
        assert state.rotation == 45.0


class TestCamera:
    """Tests for Camera class."""

    def test_creation_default(self):
        """Test camera creation with defaults."""
        camera = Camera()
        assert camera.viewport_size == (1920, 1080)
        assert camera.bounds is None
        # Initial position should be center of viewport
        assert camera.position == (960, 540)
        assert camera.zoom == 1.0
        assert camera.rotation == 0.0

    def test_creation_custom_viewport(self):
        """Test camera with custom viewport."""
        camera = Camera(viewport_size=(1280, 720))
        assert camera.viewport_size == (1280, 720)
        assert camera.position == (640, 360)

    def test_creation_with_bounds(self):
        """Test camera with world bounds."""
        camera = Camera(
            viewport_size=(1920, 1080),
            bounds=(0, 0, 3840, 2160)
        )
        assert camera.bounds == (0, 0, 3840, 2160)

    def test_position_property(self):
        """Test position getter and setter."""
        camera = Camera()
        camera.position = (500, 600)
        assert camera.position == (500, 600)
        assert camera.state.position == (500, 600)

    def test_zoom_property(self):
        """Test zoom getter and setter."""
        camera = Camera()
        camera.zoom = 2.0
        assert camera.zoom == 2.0

    def test_zoom_clamped_minimum(self):
        """Test zoom is clamped to minimum."""
        camera = Camera()
        camera.zoom = 0.05
        assert camera.zoom == 0.1

    def test_rotation_property(self):
        """Test rotation getter and setter."""
        camera = Camera()
        camera.rotation = 45.0
        assert camera.rotation == 45.0

    def test_follow(self):
        """Test camera follow setup."""
        camera = Camera()
        camera.follow(target=(100, 200), offset=(10, 20), lead=0.5)

        assert camera._follow_target == (100, 200)
        assert camera._follow_offset == (10, 20)
        assert camera._follow_lead == 0.5

    def test_stop_following(self):
        """Test stop following."""
        camera = Camera()
        camera.follow(target=(100, 200))
        camera.stop_following()

        assert camera._follow_target is None

    def test_add_shake(self):
        """Test adding shake effect."""
        camera = Camera()
        camera.add_shake(
            shake_type=ShakeType.IMPACT,
            intensity=0.5,
            duration=1.0,
            frequency=20.0
        )

        assert len(camera._active_shakes) == 1
        shake = camera._active_shakes[0]
        assert shake.shake_type == ShakeType.IMPACT
        assert shake.intensity == 0.5
        assert shake.duration == 1.0

    def test_update_basic(self):
        """Test basic update."""
        camera = Camera()
        camera.update(frame=0, fps=30.0)
        # Should not raise, camera state should be valid
        assert camera.position is not None

    def test_update_with_animation(self):
        """Test update with animation."""
        camera = Camera()
        animation = AnimationClip("camera_move")
        pos_track = animation.add_track("position")
        pos_track.add_keyframe(0, [100, 200])
        pos_track.add_keyframe(30, [300, 400])
        camera.animation = animation

        camera.update(frame=0, fps=30.0)
        # Position should be from animation
        assert camera.state.position == (100, 200)

    def test_update_with_follow(self):
        """Test update with follow target."""
        camera = Camera()
        camera.follow(target=(500, 500))

        # Update multiple times to let spring settle
        for frame in range(60):
            camera.update(frame=frame, fps=30.0)

        # Position should be near target
        pos = camera.position
        assert abs(pos[0] - 500) < 50
        assert abs(pos[1] - 500) < 50

    def test_update_clamps_to_bounds(self):
        """Test update respects camera bounds."""
        camera = Camera(
            viewport_size=(100, 100),
            bounds=(0, 0, 200, 200)
        )
        camera.position = (10, 10)  # Too close to edge
        camera.update(frame=0, fps=30.0)

        # Position should be clamped
        pos = camera.position
        assert pos[0] >= 50  # Half viewport width
        assert pos[1] >= 50  # Half viewport height

    def test_update_shake_expires(self):
        """Test shakes are removed when expired."""
        camera = Camera()
        camera.add_shake(ShakeType.IMPACT, duration=0.1)

        camera.update(frame=0, fps=30.0)
        assert len(camera._active_shakes) == 1

        # After shake duration, it should be removed
        for frame in range(10):
            camera.update(frame=frame, fps=30.0)

        assert len(camera._active_shakes) == 0

    def test_get_view_rect(self):
        """Test getting visible rectangle."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (960, 540)
        camera.zoom = 1.0

        rect = camera.get_view_rect()
        assert rect == (0, 0, 1920, 1080)

    def test_get_view_rect_zoomed(self):
        """Test view rect with zoom."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (960, 540)
        camera.zoom = 2.0

        rect = camera.get_view_rect()
        # Zoomed in 2x, visible area is half
        assert rect[2] == 960  # width
        assert rect[3] == 540  # height

    def test_world_to_screen_center(self):
        """Test world to screen conversion at center."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (960, 540)

        screen_pos = camera.world_to_screen((960, 540))
        # Center of world should map to center of screen
        assert screen_pos == (960, 540)

    def test_world_to_screen_offset(self):
        """Test world to screen with offset."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (1000, 600)

        screen_pos = camera.world_to_screen((1000, 600))
        # Camera position should map to screen center
        assert screen_pos == (960, 540)

    def test_world_to_screen_zoomed(self):
        """Test world to screen with zoom."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (960, 540)
        camera.zoom = 2.0

        # Point 100 pixels from center in world
        screen_pos = camera.world_to_screen((1060, 540))
        # Should appear 200 pixels from center on screen (2x zoom)
        assert screen_pos == (1160, 540)

    def test_screen_to_world_center(self):
        """Test screen to world conversion at center."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (960, 540)

        world_pos = camera.screen_to_world((960, 540))
        assert abs(world_pos[0] - 960) < 0.1
        assert abs(world_pos[1] - 540) < 0.1

    def test_screen_to_world_roundtrip(self):
        """Test screen/world conversion roundtrip."""
        camera = Camera(viewport_size=(1920, 1080))
        camera.position = (500, 300)
        camera.zoom = 1.5

        original = (700, 400)
        screen = camera.world_to_screen(original)
        back = camera.screen_to_world(screen)

        assert abs(back[0] - original[0]) < 1
        assert abs(back[1] - original[1]) < 1

    def test_apply_basic(self):
        """Test apply transform to image."""
        camera = Camera(viewport_size=(100, 100))
        camera.position = (50, 50)
        camera.zoom = 1.0

        # Create larger source image
        source = Image.new('RGBA', (200, 200), (255, 0, 0, 255))

        result = camera.apply(source)

        assert result.size == (100, 100)

    def test_apply_zoomed(self):
        """Test apply with zoom."""
        camera = Camera(viewport_size=(100, 100))
        camera.position = (100, 100)
        camera.zoom = 2.0

        source = Image.new('RGBA', (200, 200), (255, 0, 0, 255))

        result = camera.apply(source)

        assert result.size == (100, 100)

    def test_apply_rotated(self):
        """Test apply with rotation."""
        camera = Camera(viewport_size=(100, 100))
        camera.position = (100, 100)
        camera.rotation = 45.0

        source = Image.new('RGBA', (200, 200), (255, 0, 0, 255))

        result = camera.apply(source)

        assert result.size == (100, 100)


class TestShakeType:
    """Tests for ShakeType constants."""

    def test_shake_types_exist(self):
        """Test all shake types are defined."""
        assert ShakeType.IMPACT == "impact"
        assert ShakeType.EXPLOSION == "explosion"
        assert ShakeType.HANDHELD == "handheld"
        assert ShakeType.EARTHQUAKE == "earthquake"
        assert ShakeType.VIBRATION == "vibration"


class TestShakeInstance:
    """Tests for ShakeInstance class."""

    def test_creation(self):
        """Test shake instance creation."""
        shake = ShakeInstance(
            shake_type=ShakeType.IMPACT,
            intensity=0.5,
            duration=1.0,
            frequency=30.0
        )
        assert shake.shake_type == ShakeType.IMPACT
        assert shake.intensity == 0.5
        assert shake.duration == 1.0
        assert shake.frequency == 30.0

    def test_sample_before_start(self):
        """Test sampling before shake starts."""
        shake = ShakeInstance(shake_type=ShakeType.IMPACT, start_time=1.0)
        offset, rotation = shake.sample(0.5)

        assert offset == (0, 0)
        assert rotation == 0.0

    def test_sample_after_end(self):
        """Test sampling after shake ends."""
        shake = ShakeInstance(
            shake_type=ShakeType.IMPACT,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(2.0)

        assert offset == (0, 0)
        assert rotation == 0.0

    def test_sample_impact(self):
        """Test impact shake produces offset."""
        shake = ShakeInstance(
            shake_type=ShakeType.IMPACT,
            intensity=1.0,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(0.1)

        # Should produce non-zero offset
        assert offset != (0, 0)

    def test_sample_explosion(self):
        """Test explosion shake produces larger effects."""
        shake = ShakeInstance(
            shake_type=ShakeType.EXPLOSION,
            intensity=1.0,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(0.1)

        assert offset != (0, 0)
        # Explosion should have significant rotation
        assert abs(rotation) > 0

    def test_sample_handheld(self):
        """Test handheld shake is subtle."""
        shake = ShakeInstance(
            shake_type=ShakeType.HANDHELD,
            intensity=1.0,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(0.5)

        # Handheld should produce small offsets
        assert abs(offset[0]) < 10
        assert abs(offset[1]) < 10

    def test_sample_earthquake(self):
        """Test earthquake shake."""
        shake = ShakeInstance(
            shake_type=ShakeType.EARTHQUAKE,
            intensity=1.0,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(0.1)

        assert offset != (0, 0)

    def test_sample_vibration(self):
        """Test vibration shake has no rotation."""
        shake = ShakeInstance(
            shake_type=ShakeType.VIBRATION,
            intensity=1.0,
            start_time=0.0,
            duration=1.0
        )
        offset, rotation = shake.sample(0.1)

        assert rotation == 0.0

    def test_is_finished_before_end(self):
        """Test is_finished returns False during shake."""
        shake = ShakeInstance(
            shake_type=ShakeType.IMPACT,
            start_time=0.0,
            duration=1.0
        )
        assert shake.is_finished(0.5) is False

    def test_is_finished_after_end(self):
        """Test is_finished returns True after shake."""
        shake = ShakeInstance(
            shake_type=ShakeType.IMPACT,
            start_time=0.0,
            duration=1.0
        )
        assert shake.is_finished(1.5) is True


class TestParallaxLayer:
    """Tests for ParallaxLayer dataclass."""

    def test_creation_defaults(self):
        """Test layer creation with defaults."""
        layer = ParallaxLayer(name="background")

        assert layer.name == "background"
        assert layer.image is None
        assert layer.depth == 1.0
        assert layer.offset == (0, 0)
        assert layer.tile is False
        assert layer.z_order == 0

    def test_creation_custom(self):
        """Test layer creation with custom values."""
        image = Image.new('RGBA', (100, 100))
        layer = ParallaxLayer(
            name="mountains",
            image=image,
            depth=0.5,
            offset=(50, 100),
            tile=True,
            z_order=-10
        )

        assert layer.name == "mountains"
        assert layer.image is image
        assert layer.depth == 0.5
        assert layer.offset == (50, 100)
        assert layer.tile is True
        assert layer.z_order == -10


class TestParallaxCamera:
    """Tests for ParallaxCamera class."""

    def test_creation(self):
        """Test parallax camera creation."""
        camera = ParallaxCamera(viewport_size=(1920, 1080))

        assert camera.viewport_size == (1920, 1080)
        assert len(camera.parallax_layers) == 0

    def test_add_parallax_layer_with_image(self):
        """Test adding layer with image."""
        camera = ParallaxCamera()
        image = Image.new('RGBA', (1920, 1080), (100, 150, 200, 255))

        layer = camera.add_parallax_layer(
            name="sky",
            image=image,
            depth=0.0,
            z_order=-100
        )

        assert "sky" in camera.parallax_layers
        assert layer.image is image
        assert layer.depth == 0.0
        assert layer.z_order == -100

    def test_add_parallax_layer_with_path(self, temp_dir: Path):
        """Test adding layer with image path."""
        # Create test image
        image = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        image_path = temp_dir / "bg.png"
        image.save(image_path)

        camera = ParallaxCamera()
        layer = camera.add_parallax_layer(
            name="background",
            image_path=str(image_path),
            depth=0.3
        )

        assert layer.image is not None
        assert layer.image.size == (100, 100)

    def test_add_parallax_layer_missing_path(self):
        """Test adding layer with missing image path."""
        camera = ParallaxCamera()
        layer = camera.add_parallax_layer(
            name="missing",
            image_path="/nonexistent/path.png"
        )

        # Should not raise, image remains None
        assert layer.image is None

    def test_remove_parallax_layer(self):
        """Test removing parallax layer."""
        camera = ParallaxCamera()
        camera.add_parallax_layer(name="test", image=Image.new('RGBA', (100, 100)))

        assert camera.remove_parallax_layer("test") is True
        assert "test" not in camera.parallax_layers

    def test_remove_parallax_layer_not_found(self):
        """Test removing nonexistent layer."""
        camera = ParallaxCamera()

        assert camera.remove_parallax_layer("nonexistent") is False

    def test_calculate_layer_offset_static(self):
        """Test layer offset for static background."""
        camera = ParallaxCamera(viewport_size=(1920, 1080))
        camera.position = (1000, 600)

        layer = ParallaxLayer(name="static", depth=0.0)
        offset = camera.calculate_layer_offset(layer)

        # Static layer (depth 0) should counter camera movement
        # Camera moved 40 right, 60 down from center
        # Layer moves opposite: -cam_offset * (1 - depth)
        assert offset[0] == -40  # -(1000 - 960) * (1 - 0)
        assert offset[1] == -60  # -(600 - 540) * (1 - 0)

    def test_calculate_layer_offset_normal(self):
        """Test layer offset for normal depth."""
        camera = ParallaxCamera(viewport_size=(1920, 1080))
        camera.position = (1000, 600)

        layer = ParallaxLayer(name="normal", depth=1.0)
        offset = camera.calculate_layer_offset(layer)

        # Normal depth (1.0) should not add parallax offset
        assert offset == (0, 0)

    def test_calculate_layer_offset_mid(self):
        """Test layer offset for mid-ground."""
        camera = ParallaxCamera(viewport_size=(1920, 1080))
        camera.position = (1000, 600)

        layer = ParallaxLayer(name="mid", depth=0.5)
        offset = camera.calculate_layer_offset(layer)

        # Should be half the parallax of static (negative direction)
        assert offset[0] == -20  # -40 * 0.5
        assert offset[1] == -30  # -60 * 0.5

    def test_render_parallax_basic(self):
        """Test basic parallax rendering."""
        camera = ParallaxCamera(viewport_size=(200, 200))
        camera.position = (100, 100)

        # Add a background layer
        bg = Image.new('RGBA', (200, 200), (0, 0, 255, 255))
        camera.add_parallax_layer("bg", image=bg, depth=0.0, z_order=-10)

        # Main layer
        main = Image.new('RGBA', (200, 200), (255, 0, 0, 128))

        result = camera.render_parallax(main)

        assert result.size == (200, 200)
        # Result should have content from both layers


class TestDepthOfField:
    """Tests for DepthOfField class."""

    def test_creation_defaults(self):
        """Test DOF creation with defaults."""
        dof = DepthOfField()

        assert dof.focal_distance == 1.0
        assert dof.aperture == 0.3
        assert dof.max_blur == 10.0

    def test_creation_custom(self):
        """Test DOF creation with custom values."""
        dof = DepthOfField(
            focal_distance=0.5,
            aperture=0.5,
            max_blur=20.0
        )

        assert dof.focal_distance == 0.5
        assert dof.aperture == 0.5
        assert dof.max_blur == 20.0

    def test_calculate_blur_at_focus(self):
        """Test blur is zero at focal distance."""
        dof = DepthOfField(focal_distance=1.0)
        blur = dof.calculate_blur(1.0)

        assert blur == 0.0

    def test_calculate_blur_away_from_focus(self):
        """Test blur increases with distance from focus."""
        dof = DepthOfField(focal_distance=1.0, aperture=0.5, max_blur=10.0)

        blur_near = dof.calculate_blur(0.5)
        blur_far = dof.calculate_blur(2.0)

        assert blur_near > 0
        assert blur_far > 0
        assert blur_far > blur_near  # Further from focus = more blur

    def test_calculate_blur_clamped_to_max(self):
        """Test blur is clamped to max_blur."""
        dof = DepthOfField(focal_distance=1.0, aperture=1.0, max_blur=5.0)

        blur = dof.calculate_blur(100.0)  # Very far from focus

        assert blur == 5.0

    def test_apply_no_blur_at_focus(self):
        """Test apply returns original when in focus."""
        dof = DepthOfField(focal_distance=1.0)
        image = Image.new('RGBA', (100, 100), (255, 0, 0, 255))

        result = dof.apply(image, 1.0)

        # Should be the same image (not blurred)
        assert result is image

    def test_apply_blurs_out_of_focus(self):
        """Test apply blurs out-of-focus images."""
        dof = DepthOfField(focal_distance=1.0, aperture=0.5, max_blur=10.0)

        # Create sharp edge image
        image = Image.new('RGBA', (100, 100), (255, 255, 255, 255))
        for x in range(50, 100):
            for y in range(100):
                image.putpixel((x, y), (0, 0, 0, 255))

        result = dof.apply(image, 2.0)

        # Result should be different (blurred)
        assert result is not image
        # Edge pixels should be softened
        edge_pixel = result.getpixel((50, 50))
        # Should be grayish instead of pure black/white
        assert edge_pixel != (0, 0, 0, 255)
        assert edge_pixel != (255, 255, 255, 255)


class TestCameraIntegration:
    """Integration tests for camera system."""

    def test_camera_animation_workflow(self):
        """Test complete camera animation workflow."""
        camera = Camera(viewport_size=(800, 600))

        # Set up animation
        animation = AnimationClip("pan_and_zoom")
        pos_track = animation.add_track("position")
        pos_track.add_keyframe(0, [400, 300])
        pos_track.add_keyframe(30, [600, 400])

        zoom_track = animation.add_track("zoom")
        zoom_track.add_keyframe(0, 1.0)
        zoom_track.add_keyframe(30, 1.5)

        camera.animation = animation

        # Simulate animation
        positions = []
        zooms = []
        for frame in range(31):
            camera.update(frame, fps=30.0)
            positions.append(camera.position)
            zooms.append(camera.zoom)

        # Check interpolation occurred
        assert positions[0] == (400, 300)
        assert positions[-1] == (600, 400)
        # Mid-frame should be interpolated
        assert positions[15][0] > 400 and positions[15][0] < 600

    def test_shake_during_animation(self):
        """Test shake effect during camera movement."""
        camera = Camera(viewport_size=(800, 600))
        camera.position = (400, 300)

        # Add shake
        camera.add_shake(ShakeType.IMPACT, intensity=1.0, duration=0.5)

        # Track shake offsets
        offsets = []
        for frame in range(30):
            camera.update(frame, fps=30.0)
            offsets.append(camera._shake_offset)

        # Shake should produce varying offsets
        unique_offsets = set(offsets)
        assert len(unique_offsets) > 1

        # Later offsets should be smaller on average (decay)
        # Compare peak magnitudes over early vs late windows to avoid
        # flakiness from sinusoidal phase at individual frames
        magnitudes = [math.sqrt(o[0]**2 + o[1]**2) for o in offsets]
        early_peak = max(magnitudes[:8])   # First ~0.27s
        late_peak = max(magnitudes[10:18])  # ~0.33s-0.60s
        assert late_peak < early_peak or all(m == 0 for m in magnitudes[10:18])

    def test_parallax_camera_complete(self):
        """Test parallax camera with multiple layers."""
        camera = ParallaxCamera(viewport_size=(400, 300))
        camera.position = (200, 150)

        # Add background layers
        sky = Image.new('RGBA', (400, 300), (135, 206, 235, 255))
        camera.add_parallax_layer("sky", image=sky, depth=0.0, z_order=-50)

        mountains = Image.new('RGBA', (400, 300), (100, 100, 100, 128))
        camera.add_parallax_layer("mountains", image=mountains, depth=0.3, z_order=-30)

        trees = Image.new('RGBA', (400, 300), (34, 139, 34, 128))
        camera.add_parallax_layer("trees", image=trees, depth=0.7, z_order=-10)

        # Main scene
        main = Image.new('RGBA', (400, 300), (255, 255, 255, 128))

        # Render
        result = camera.render_parallax(main)

        assert result.size == (400, 300)
        assert result.mode == 'RGBA'
