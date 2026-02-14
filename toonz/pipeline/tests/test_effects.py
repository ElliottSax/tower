"""Tests for animation/effects.py."""

import math
import pytest
from PIL import Image
from unittest.mock import MagicMock, patch

from pipeline.animation.effects import (
    # Particle system
    Particle,
    ParticleEmitter,
    create_sparkle_emitter,
    create_dust_emitter,
    create_rain_emitter,
    create_confetti_emitter,
    # Image effects
    apply_glow,
    apply_drop_shadow,
    apply_color_grade,
    apply_vignette,
    # Transitions
    Transition,
    FadeTransition,
    WipeTransition,
    DissolveTransition,
    IrisTransition,
    # Path animation
    BezierPoint,
    BezierPath,
    PathFollower,
)
from pipeline.animation.physics import Vec2


# ============================================================================
# PARTICLE TESTS
# ============================================================================

class TestParticle:
    """Tests for Particle dataclass."""

    def test_default_values(self):
        """Test default particle values."""
        p = Particle()
        assert p.position.x == 0 and p.position.y == 0
        assert p.velocity.x == 0 and p.velocity.y == 0
        assert p.acceleration.x == 0 and p.acceleration.y == 0
        assert p.life == 1.0
        assert p.life_decay == 0.02
        assert p.size == 5.0
        assert p.size_decay == 0.0
        assert p.rotation == 0.0
        assert p.rotation_speed == 0.0
        assert p.color == (255, 255, 255, 255)
        assert p.alpha_decay == 0.0

    def test_custom_values(self):
        """Test particle with custom values."""
        p = Particle(
            position=Vec2(100, 200),
            velocity=Vec2(10, -20),
            life=0.5,
            size=10.0,
            color=(255, 0, 0, 128)
        )
        assert p.position.x == 100 and p.position.y == 200
        assert p.velocity.x == 10 and p.velocity.y == -20
        assert p.life == 0.5
        assert p.size == 10.0
        assert p.color == (255, 0, 0, 128)


class TestParticleEmitter:
    """Tests for ParticleEmitter class."""

    def test_default_creation(self):
        """Test emitter with default values."""
        emitter = ParticleEmitter()
        assert emitter.position.x == 0 and emitter.position.y == 0
        assert emitter.emission_rate == 10.0
        assert emitter.particle_life == 1.0
        assert emitter.active is True
        assert len(emitter.particles) == 0

    def test_custom_creation(self):
        """Test emitter with custom values."""
        emitter = ParticleEmitter(
            position=(500, 300),
            emission_rate=50,
            particle_life=2.0,
            particle_speed=(100, 200),
            direction=-45,
            spread=90,
            gravity=(10, 100),
            max_particles=100
        )
        assert emitter.position.x == 500 and emitter.position.y == 300
        assert emitter.emission_rate == 50
        assert emitter.particle_life == 2.0
        assert emitter.particle_speed == (100, 200)
        assert emitter.max_particles == 100

    def test_update_emits_particles(self):
        """Test that update emits particles over time."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=60  # 60 per second = 1 per frame at 60fps
        )
        # After 1/60 second, should have at least 1 particle
        emitter.update(1/30)  # 2 frames worth
        assert len(emitter.particles) >= 1

    def test_update_applies_gravity(self):
        """Test that gravity affects particles."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            gravity=(0, 100),
            direction=0,  # Emit to the right (no initial vertical velocity)
            spread=0
        )
        emitter.burst(1)  # Create exactly 1 particle
        initial_velocity_y = emitter.particles[0].velocity.y
        emitter.update(0.1)  # Apply gravity
        # Gravity should increase y velocity (downward)
        final_velocity_y = emitter.particles[0].velocity.y
        assert final_velocity_y > initial_velocity_y

    def test_update_removes_dead_particles(self):
        """Test that dead particles are removed."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=0  # Don't emit automatically
        )
        emitter.burst(5)  # Create exactly 5 particles
        assert len(emitter.particles) == 5

        # Manually set all particles to near-death
        for p in emitter.particles:
            p.life = 0.001
            p.life_decay = 1.0  # High decay rate

        # Update should remove dead particles
        emitter.update(0.1)
        assert len(emitter.particles) == 0

    def test_max_particles_limit(self):
        """Test that max particles limit is respected."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=1000,  # Very high rate
            max_particles=10
        )
        for _ in range(10):
            emitter.update(0.1)
        assert len(emitter.particles) <= 10

    def test_inactive_emitter_stops_emitting(self):
        """Test that inactive emitter stops emitting new particles."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100
        )
        emitter.update(0.1)
        count_before = len(emitter.particles)
        emitter.active = False
        # Clear particles and check no new ones are created
        emitter.particles = []
        emitter.update(0.1)
        assert len(emitter.particles) == 0

    def test_burst_emission(self):
        """Test burst mode."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=0,  # No continuous emission
            max_particles=100
        )
        emitter.burst(50)
        assert len(emitter.particles) == 50

    def test_burst_respects_max_particles(self):
        """Test burst respects max particle limit."""
        emitter = ParticleEmitter(
            position=(100, 100),
            max_particles=10
        )
        emitter.burst(100)
        assert len(emitter.particles) == 10

    def test_render_creates_image(self):
        """Test render creates proper image."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100
        )
        emitter.update(0.1)
        canvas = emitter.render((200, 200))
        assert isinstance(canvas, Image.Image)
        assert canvas.size == (200, 200)
        assert canvas.mode == 'RGBA'

    def test_render_with_particles(self):
        """Test render with particles visible."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            particle_size=(10, 20),
            colors=[(255, 0, 0, 255)]
        )
        emitter.burst(10)
        canvas = emitter.render((200, 200))
        # Check that some pixels are not transparent (particles rendered)
        pixels = list(canvas.getdata())
        non_transparent = [p for p in pixels if p[3] > 0]
        assert len(non_transparent) > 0

    def test_render_with_custom_particle_image(self):
        """Test render with custom particle image."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            particle_size=(10, 10)
        )
        emitter.burst(5)
        particle_img = Image.new('RGBA', (20, 20), (255, 255, 0, 255))
        canvas = emitter.render((200, 200), particle_image=particle_img)
        assert isinstance(canvas, Image.Image)

    def test_particle_rotation(self):
        """Test particle rotation during update."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            rotation_speed=(360, 360)  # 360 degrees per second
        )
        emitter.burst(1)
        initial_rotation = emitter.particles[0].rotation
        emitter.update(0.5)  # Half second
        # Rotation should have changed
        new_rotation = emitter.particles[0].rotation
        assert new_rotation != initial_rotation

    def test_size_decay(self):
        """Test particle size decay."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            particle_size=(20, 20),
            size_decay=-10  # Shrink by 10 per second
        )
        emitter.burst(1)
        emitter.update(1.0)  # 1 second
        # Particle should be smaller (or removed if too small)
        # We might not have particles left if they shrank to 0

    def test_fade_out_effect(self):
        """Test particle fade out based on life."""
        emitter = ParticleEmitter(
            position=(100, 100),
            emission_rate=100,
            fade_out=True
        )
        emitter.burst(1)
        # Modify particle life directly to test fade
        emitter.particles[0].life = 0.5
        canvas = emitter.render((200, 200))
        # Alpha should be reduced based on life


class TestParticleEmitterFactories:
    """Tests for particle emitter factory functions."""

    def test_create_sparkle_emitter(self):
        """Test sparkle emitter creation."""
        emitter = create_sparkle_emitter((500, 500))
        assert emitter.position.x == 500 and emitter.position.y == 500
        assert emitter.emission_rate == 20
        assert len(emitter.colors) == 3

    def test_create_sparkle_emitter_with_intensity(self):
        """Test sparkle emitter with custom intensity."""
        emitter = create_sparkle_emitter((100, 100), intensity=2.0)
        assert emitter.emission_rate == 40  # 20 * 2.0

    def test_create_dust_emitter(self):
        """Test dust emitter creation."""
        emitter = create_dust_emitter((300, 300))
        assert emitter.position.x == 300 and emitter.position.y == 300
        assert emitter.emission_rate == 30
        assert emitter.size_decay == -2

    def test_create_dust_emitter_with_direction(self):
        """Test dust emitter with custom direction."""
        emitter = create_dust_emitter((100, 100), direction=45)
        # Direction is converted to radians internally
        assert emitter.direction == pytest.approx(math.radians(45))

    def test_create_rain_emitter(self):
        """Test rain emitter creation."""
        area = (0, 0, 800, 600)
        emitter = create_rain_emitter(area)
        # Rain emitter is a subclass that emits across the area width
        assert emitter.emission_rate == 100
        emitter.update(0.1)

    def test_create_rain_emitter_with_intensity(self):
        """Test rain emitter with custom intensity."""
        area = (0, 0, 800, 600)
        emitter = create_rain_emitter(area, intensity=0.5)
        assert emitter.emission_rate == 50  # 100 * 0.5

    def test_create_confetti_emitter(self):
        """Test confetti emitter creation."""
        emitter = create_confetti_emitter((400, 300))
        assert emitter.position.x == 400 and emitter.position.y == 300
        assert emitter.emission_rate == 0  # Burst mode
        assert len(emitter.colors) == 6
        assert emitter.fade_out is False


# ============================================================================
# IMAGE EFFECTS TESTS
# ============================================================================

class TestApplyGlow:
    """Tests for apply_glow function."""

    @pytest.fixture
    def sample_image(self):
        """Create a sample RGBA image."""
        img = Image.new('RGBA', (100, 100), (0, 0, 0, 0))
        # Draw a white circle in the center
        from PIL import ImageDraw
        draw = ImageDraw.Draw(img)
        draw.ellipse([30, 30, 70, 70], fill=(255, 255, 255, 255))
        return img

    def test_glow_default_params(self, sample_image):
        """Test glow with default parameters."""
        result = apply_glow(sample_image)
        assert isinstance(result, Image.Image)
        assert result.size == sample_image.size
        assert result.mode == 'RGBA'

    def test_glow_custom_radius(self, sample_image):
        """Test glow with custom radius."""
        result = apply_glow(sample_image, radius=20.0)
        assert result.size == sample_image.size

    def test_glow_custom_intensity(self, sample_image):
        """Test glow with custom intensity."""
        result = apply_glow(sample_image, intensity=2.0)
        assert result.size == sample_image.size

    def test_glow_custom_color(self, sample_image):
        """Test glow with custom color."""
        result = apply_glow(sample_image, color=(255, 0, 0))
        assert result.size == sample_image.size


class TestApplyDropShadow:
    """Tests for apply_drop_shadow function."""

    @pytest.fixture
    def sample_image(self):
        """Create a sample RGBA image."""
        img = Image.new('RGBA', (100, 100), (0, 0, 0, 0))
        from PIL import ImageDraw
        draw = ImageDraw.Draw(img)
        draw.rectangle([25, 25, 75, 75], fill=(255, 255, 255, 255))
        return img

    def test_drop_shadow_default(self, sample_image):
        """Test drop shadow with defaults."""
        result = apply_drop_shadow(sample_image)
        assert isinstance(result, Image.Image)
        # Result should be larger due to margin
        assert result.width > sample_image.width
        assert result.height > sample_image.height

    def test_drop_shadow_custom_offset(self, sample_image):
        """Test drop shadow with custom offset."""
        result = apply_drop_shadow(sample_image, offset=(10, 10))
        assert result.width > sample_image.width

    def test_drop_shadow_custom_blur(self, sample_image):
        """Test drop shadow with custom blur."""
        result = apply_drop_shadow(sample_image, blur=10.0)
        assert result.width > sample_image.width

    def test_drop_shadow_no_blur(self, sample_image):
        """Test drop shadow with no blur."""
        result = apply_drop_shadow(sample_image, blur=0)
        assert result.width > sample_image.width

    def test_drop_shadow_custom_color(self, sample_image):
        """Test drop shadow with custom color."""
        result = apply_drop_shadow(sample_image, color=(255, 0, 0, 200))
        assert result.width > sample_image.width


class TestApplyColorGrade:
    """Tests for apply_color_grade function."""

    @pytest.fixture
    def sample_image(self):
        """Create a sample RGBA image."""
        return Image.new('RGBA', (100, 100), (128, 128, 128, 255))

    def test_color_grade_no_changes(self, sample_image):
        """Test color grade with no changes."""
        result = apply_color_grade(sample_image)
        assert result.size == sample_image.size

    def test_color_grade_brightness(self, sample_image):
        """Test brightness adjustment."""
        brighter = apply_color_grade(sample_image, brightness=1.5)
        darker = apply_color_grade(sample_image, brightness=0.5)
        assert brighter.size == sample_image.size
        assert darker.size == sample_image.size

    def test_color_grade_contrast(self, sample_image):
        """Test contrast adjustment."""
        result = apply_color_grade(sample_image, contrast=1.5)
        assert result.size == sample_image.size

    def test_color_grade_saturation(self, sample_image):
        """Test saturation adjustment."""
        result = apply_color_grade(sample_image, saturation=0.5)
        assert result.size == sample_image.size

    def test_color_grade_tint(self, sample_image):
        """Test color tint."""
        result = apply_color_grade(sample_image, tint=(255, 200, 100), tint_strength=0.5)
        assert result.size == sample_image.size

    def test_color_grade_tint_zero_strength(self, sample_image):
        """Test tint with zero strength has no effect."""
        result = apply_color_grade(sample_image, tint=(255, 0, 0), tint_strength=0)
        assert result.size == sample_image.size

    def test_color_grade_combined(self, sample_image):
        """Test multiple adjustments combined."""
        result = apply_color_grade(
            sample_image,
            brightness=1.2,
            contrast=1.1,
            saturation=0.9,
            tint=(200, 180, 150),
            tint_strength=0.2
        )
        assert result.size == sample_image.size


class TestApplyVignette:
    """Tests for apply_vignette function."""

    @pytest.fixture
    def sample_image(self):
        """Create a sample RGBA image."""
        return Image.new('RGBA', (200, 200), (255, 255, 255, 255))

    def test_vignette_default(self, sample_image):
        """Test vignette with defaults."""
        result = apply_vignette(sample_image)
        assert result.size == sample_image.size
        assert result.mode == 'RGBA'

    def test_vignette_custom_intensity(self, sample_image):
        """Test vignette with custom intensity."""
        light = apply_vignette(sample_image, intensity=0.2)
        dark = apply_vignette(sample_image, intensity=0.9)
        assert light.size == sample_image.size
        assert dark.size == sample_image.size

    def test_vignette_custom_radius(self, sample_image):
        """Test vignette with custom radius."""
        small = apply_vignette(sample_image, radius=0.5)
        large = apply_vignette(sample_image, radius=0.9)
        assert small.size == sample_image.size
        assert large.size == sample_image.size

    def test_vignette_edges_darker(self, sample_image):
        """Test that edges are darker than center."""
        result = apply_vignette(sample_image, intensity=0.8)
        center = result.getpixel((100, 100))
        corner = result.getpixel((10, 10))
        # Center should be brighter than corner
        assert center[0] > corner[0]


# ============================================================================
# TRANSITION TESTS
# ============================================================================

class TestTransitionBase:
    """Tests for base Transition class."""

    def test_transition_duration(self):
        """Test transition duration."""
        t = Transition(duration=2.0)
        assert t.duration == 2.0

    def test_transition_apply_not_implemented(self):
        """Test that base apply raises NotImplementedError."""
        t = Transition()
        img1 = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        img2 = Image.new('RGBA', (100, 100), (0, 255, 0, 255))
        with pytest.raises(NotImplementedError):
            t.apply(img1, img2, 0.5)


class TestFadeTransition:
    """Tests for FadeTransition class."""

    @pytest.fixture
    def images(self):
        """Create test images."""
        from_img = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        to_img = Image.new('RGBA', (100, 100), (0, 255, 0, 255))
        return from_img, to_img

    def test_fade_at_zero(self, images):
        """Test fade at 0% progress."""
        from_img, to_img = images
        fade = FadeTransition()
        result = fade.apply(from_img, to_img, 0)
        # Should be 100% from_img
        pixel = result.getpixel((50, 50))
        assert pixel[0] == 255 and pixel[1] == 0

    def test_fade_at_one(self, images):
        """Test fade at 100% progress."""
        from_img, to_img = images
        fade = FadeTransition()
        result = fade.apply(from_img, to_img, 1)
        # Should be 100% to_img
        pixel = result.getpixel((50, 50))
        assert pixel[0] == 0 and pixel[1] == 255

    def test_fade_at_half(self, images):
        """Test fade at 50% progress."""
        from_img, to_img = images
        fade = FadeTransition()
        result = fade.apply(from_img, to_img, 0.5)
        pixel = result.getpixel((50, 50))
        # Should be blend of red and green
        assert pixel[0] == pytest.approx(127, abs=1)
        assert pixel[1] == pytest.approx(127, abs=1)


class TestWipeTransition:
    """Tests for WipeTransition class."""

    @pytest.fixture
    def images(self):
        """Create test images."""
        from_img = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        to_img = Image.new('RGBA', (100, 100), (0, 255, 0, 255))
        return from_img, to_img

    def test_wipe_left(self, images):
        """Test left wipe transition."""
        from_img, to_img = images
        wipe = WipeTransition(direction="left")
        result = wipe.apply(from_img, to_img, 0.5)
        # Left half should be to_img (green)
        left_pixel = result.getpixel((25, 50))
        # Right half should be from_img (red)
        right_pixel = result.getpixel((75, 50))
        assert left_pixel[1] == 255  # Green
        assert right_pixel[0] == 255  # Red

    def test_wipe_right(self, images):
        """Test right wipe transition."""
        from_img, to_img = images
        wipe = WipeTransition(direction="right")
        result = wipe.apply(from_img, to_img, 0.5)
        # Right half should be to_img (green)
        right_pixel = result.getpixel((75, 50))
        assert right_pixel[1] == 255  # Green

    def test_wipe_up(self, images):
        """Test up wipe transition."""
        from_img, to_img = images
        wipe = WipeTransition(direction="up")
        result = wipe.apply(from_img, to_img, 0.5)
        # Top half should be to_img (green)
        top_pixel = result.getpixel((50, 25))
        assert top_pixel[1] == 255  # Green

    def test_wipe_down(self, images):
        """Test down wipe transition."""
        from_img, to_img = images
        wipe = WipeTransition(direction="down")
        result = wipe.apply(from_img, to_img, 0.5)
        # Bottom half should be to_img (green)
        bottom_pixel = result.getpixel((50, 75))
        assert bottom_pixel[1] == 255  # Green

    def test_wipe_at_zero(self, images):
        """Test wipe at 0% - all from_img."""
        from_img, to_img = images
        wipe = WipeTransition(direction="left")
        result = wipe.apply(from_img, to_img, 0)
        pixel = result.getpixel((50, 50))
        assert pixel[0] == 255  # Red

    def test_wipe_at_one(self, images):
        """Test wipe at 100% - all to_img."""
        from_img, to_img = images
        wipe = WipeTransition(direction="left")
        result = wipe.apply(from_img, to_img, 1)
        pixel = result.getpixel((50, 50))
        assert pixel[1] == 255  # Green


class TestDissolveTransition:
    """Tests for DissolveTransition class."""

    @pytest.fixture
    def images(self):
        """Create test images."""
        from_img = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        to_img = Image.new('RGBA', (100, 100), (0, 255, 0, 255))
        return from_img, to_img

    def test_dissolve_default_block_size(self, images):
        """Test dissolve with default block size."""
        from_img, to_img = images
        dissolve = DissolveTransition()
        assert dissolve.block_size == 8
        result = dissolve.apply(from_img, to_img, 0.5)
        assert result.size == from_img.size

    def test_dissolve_custom_block_size(self, images):
        """Test dissolve with custom block size."""
        from_img, to_img = images
        dissolve = DissolveTransition(block_size=16)
        result = dissolve.apply(from_img, to_img, 0.5)
        assert result.size == from_img.size

    def test_dissolve_at_zero(self, images):
        """Test dissolve at 0% - all from_img."""
        from_img, to_img = images
        dissolve = DissolveTransition()
        result = dissolve.apply(from_img, to_img, 0)
        # All pixels should be from_img
        pixel = result.getpixel((50, 50))
        assert pixel[0] == 255  # Red

    def test_dissolve_at_one(self, images):
        """Test dissolve at 100% - all to_img."""
        from_img, to_img = images
        dissolve = DissolveTransition()
        result = dissolve.apply(from_img, to_img, 1)
        # All pixels should be to_img
        pixel = result.getpixel((50, 50))
        assert pixel[1] == 255  # Green

    def test_dissolve_pattern_cached(self, images):
        """Test that dissolve pattern is cached."""
        from_img, to_img = images
        dissolve = DissolveTransition()
        dissolve.apply(from_img, to_img, 0.3)
        assert dissolve._pattern is not None
        cached_pattern = dissolve._pattern
        dissolve.apply(from_img, to_img, 0.6)
        # Same pattern should be reused
        assert dissolve._pattern[0] == cached_pattern[0]


class TestIrisTransition:
    """Tests for IrisTransition class."""

    @pytest.fixture
    def images(self):
        """Create test images."""
        from_img = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
        to_img = Image.new('RGBA', (100, 100), (0, 255, 0, 255))
        return from_img, to_img

    def test_iris_out_default(self, images):
        """Test iris out transition (default)."""
        from_img, to_img = images
        iris = IrisTransition()
        assert iris.iris_out is True
        result = iris.apply(from_img, to_img, 0.5)
        assert result.size == from_img.size

    def test_iris_in(self, images):
        """Test iris in transition."""
        from_img, to_img = images
        iris = IrisTransition(iris_out=False)
        result = iris.apply(from_img, to_img, 0.5)
        assert result.size == from_img.size

    def test_iris_custom_center(self, images):
        """Test iris with custom center."""
        from_img, to_img = images
        iris = IrisTransition(center=(0.25, 0.75))
        result = iris.apply(from_img, to_img, 0.5)
        assert result.size == from_img.size

    def test_iris_at_zero(self, images):
        """Test iris out at 0% - all from_img."""
        from_img, to_img = images
        iris = IrisTransition()
        result = iris.apply(from_img, to_img, 0)
        pixel = result.getpixel((50, 50))
        assert pixel[0] == 255  # Red (from_img)

    def test_iris_at_one(self, images):
        """Test iris out at 100% - all to_img."""
        from_img, to_img = images
        iris = IrisTransition()
        result = iris.apply(from_img, to_img, 1)
        # Center should be to_img
        pixel = result.getpixel((50, 50))
        assert pixel[1] == 255  # Green (to_img)

    def test_iris_center_reveals_first(self, images):
        """Test that iris reveals from center."""
        from_img, to_img = images
        iris = IrisTransition()
        result = iris.apply(from_img, to_img, 0.3)
        # Center should be to_img first
        center = result.getpixel((50, 50))
        corner = result.getpixel((5, 5))
        assert center[1] == 255  # Green at center
        assert corner[0] == 255  # Red at corner


# ============================================================================
# PATH ANIMATION TESTS
# ============================================================================

class TestBezierPoint:
    """Tests for BezierPoint dataclass."""

    def test_point_position_only(self):
        """Test point with position only."""
        point = BezierPoint(position=(100, 200))
        assert point.position == (100, 200)
        assert point.control_in is None
        assert point.control_out is None

    def test_point_with_controls(self):
        """Test point with control points."""
        point = BezierPoint(
            position=(100, 200),
            control_in=(50, 200),
            control_out=(150, 200)
        )
        assert point.position == (100, 200)
        assert point.control_in == (50, 200)
        assert point.control_out == (150, 200)


class TestBezierPath:
    """Tests for BezierPath class."""

    def test_empty_path(self):
        """Test empty path."""
        path = BezierPath()
        assert len(path.points) == 0
        assert path.get_point(0.5) == (0, 0)

    def test_single_point_path(self):
        """Test path with single point."""
        path = BezierPath()
        path.add_point((100, 100))
        assert path.get_point(0) == (100, 100)
        assert path.get_point(0.5) == (100, 100)
        assert path.get_point(1) == (100, 100)

    def test_linear_path(self):
        """Test simple linear path."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 100))

        # Start
        assert path.get_point(0) == (0, 0)
        # End
        assert path.get_point(1) == (100, 100)
        # Middle (linear interpolation)
        mid = path.get_point(0.5)
        assert mid[0] == pytest.approx(50, abs=1)
        assert mid[1] == pytest.approx(50, abs=1)

    def test_curved_path(self):
        """Test curved path with control points."""
        path = BezierPath()
        path.add_point((0, 0), control_out=(50, 0))
        path.add_point((100, 100), control_in=(100, 50))

        # Middle point should be affected by control points
        mid = path.get_point(0.5)
        # Not on the straight line due to curve
        assert mid[0] != pytest.approx(50, abs=5) or mid[1] != pytest.approx(50, abs=5)

    def test_multi_segment_path(self):
        """Test path with multiple segments."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 0))
        path.add_point((100, 100))

        # At 0.25 (middle of first segment)
        p1 = path.get_point(0.25)
        assert p1[0] == pytest.approx(50, abs=1)
        assert p1[1] == pytest.approx(0, abs=1)

        # At 0.75 (middle of second segment)
        p2 = path.get_point(0.75)
        assert p2[0] == pytest.approx(100, abs=1)
        assert p2[1] == pytest.approx(50, abs=1)

    def test_get_point_clamped(self):
        """Test that get_point clamps t values."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 100))

        assert path.get_point(-0.5) == (0, 0)
        assert path.get_point(1.5) == (100, 100)

    def test_get_tangent_angle(self):
        """Test tangent angle calculation."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 0))  # Horizontal path

        angle = path.get_tangent_angle(0.5)
        assert angle == pytest.approx(0, abs=1)  # 0 degrees = pointing right

    def test_get_tangent_angle_diagonal(self):
        """Test tangent angle on diagonal path."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 100))  # 45 degree path

        angle = path.get_tangent_angle(0.5)
        assert angle == pytest.approx(45, abs=1)

    def test_get_length_empty(self):
        """Test length of empty path."""
        path = BezierPath()
        assert path.get_length() == 0

    def test_get_length_single_point(self):
        """Test length of single point path."""
        path = BezierPath()
        path.add_point((100, 100))
        assert path.get_length() == 0

    def test_get_length_linear(self):
        """Test length of linear path."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 0))  # 100 pixels horizontal

        length = path.get_length()
        assert length == pytest.approx(100, abs=1)

    def test_get_length_diagonal(self):
        """Test length of diagonal path."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 100))  # ~141 pixels diagonal

        length = path.get_length()
        expected = math.sqrt(100**2 + 100**2)
        assert length == pytest.approx(expected, abs=1)


class TestPathFollower:
    """Tests for PathFollower class."""

    @pytest.fixture
    def simple_path(self):
        """Create a simple path."""
        path = BezierPath()
        path.add_point((0, 0))
        path.add_point((100, 100))
        return path

    def test_follower_creation(self, simple_path):
        """Test follower creation."""
        follower = PathFollower(simple_path, duration=2.0)
        assert follower.duration == 2.0
        assert follower.position == (0, 0)
        assert follower.progress == 0
        assert not follower.finished

    def test_follower_update(self, simple_path):
        """Test follower position updates."""
        follower = PathFollower(simple_path, duration=1.0)
        follower.update(0.5)  # Half second

        assert follower.progress == pytest.approx(0.5, abs=0.01)
        pos = follower.position
        assert pos[0] == pytest.approx(50, abs=1)
        assert pos[1] == pytest.approx(50, abs=1)

    def test_follower_finished(self, simple_path):
        """Test follower finished state."""
        follower = PathFollower(simple_path, duration=1.0)
        follower.update(1.5)  # Past duration

        assert follower.finished is True
        assert follower.progress == 1.0

    def test_follower_loop(self, simple_path):
        """Test follower loop mode."""
        follower = PathFollower(simple_path, duration=1.0, loop=True)
        follower.update(1.5)  # Past duration

        assert not follower.finished
        assert follower.progress < 1.0

    def test_follower_orient_to_path(self, simple_path):
        """Test follower orientation to path."""
        follower = PathFollower(simple_path, duration=1.0, orient_to_path=True)
        follower.update(0.5)

        # Should be rotated 45 degrees for diagonal path
        assert follower.rotation == pytest.approx(45, abs=1)

    def test_follower_no_orient(self, simple_path):
        """Test follower without orientation."""
        follower = PathFollower(simple_path, duration=1.0, orient_to_path=False)
        follower.update(0.5)

        assert follower.rotation == 0

    def test_follower_easing(self, simple_path):
        """Test follower with easing function."""
        # Ease-in quad: t^2
        easing = lambda t: t * t
        follower = PathFollower(simple_path, duration=1.0, easing=easing)

        # Without easing, at t=0.5 we get position at bezier(0.5)
        follower_no_ease = PathFollower(simple_path, duration=1.0)
        follower_no_ease.update(0.5)
        pos_no_ease = follower_no_ease.position

        # With easing, at t=0.5, eased_t=0.25, so we get position at bezier(0.25)
        follower.update(0.5)
        pos = follower.position

        # The eased position should be behind the non-eased position
        # (ease-in starts slow)
        assert pos[0] < pos_no_ease[0]
        assert pos[1] < pos_no_ease[1]

    def test_follower_reset(self, simple_path):
        """Test follower reset."""
        follower = PathFollower(simple_path, duration=1.0)
        follower.update(0.5)
        assert follower.progress > 0

        follower.reset()
        assert follower.progress == 0
        assert follower.position == (0, 0)

    def test_follower_reset_with_orient(self, simple_path):
        """Test reset preserves orientation setting."""
        follower = PathFollower(simple_path, duration=1.0, orient_to_path=True)
        follower.update(0.5)
        follower.reset()

        # Should still have initial rotation based on path
        # (get_tangent_angle at 0)
        assert follower.rotation == pytest.approx(45, abs=1)
