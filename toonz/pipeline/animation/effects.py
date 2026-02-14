"""Visual effects for the animation pipeline.

Provides:
- Particle systems (sparkles, dust, smoke, rain, confetti)
- Image effects (glow, blur, drop shadow, color grading)
- Transitions (fade, wipe, dissolve, morphing)
- Path animation (bezier curves with objects following)
"""

import math
import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Callable
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops

from .physics import Vec2


# ============================================================================
# PARTICLE SYSTEM
# ============================================================================

@dataclass
class Particle:
    """A single particle."""
    position: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    velocity: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    acceleration: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    life: float = 1.0           # Remaining life (0-1)
    life_decay: float = 0.02    # Life decrease per frame
    size: float = 5.0
    size_decay: float = 0.0     # Size change per frame
    rotation: float = 0.0
    rotation_speed: float = 0.0
    color: Tuple[int, int, int, int] = (255, 255, 255, 255)
    alpha_decay: float = 0.0    # Alpha decrease per frame


class ParticleEmitter:
    """Particle emitter for various effects.

    Usage:
        # Create sparkle effect
        emitter = ParticleEmitter(
            position=(500, 500),
            emission_rate=20,
            particle_life=1.0,
            particle_speed=(50, 100),
            gravity=(0, 50),
            colors=[(255, 255, 200, 255), (255, 200, 100, 255)]
        )

        # Each frame:
        emitter.update(dt)
        particles_image = emitter.render(canvas_size)
    """

    def __init__(
        self,
        position: Tuple[float, float] = (0, 0),
        emission_rate: float = 10.0,
        particle_life: float = 1.0,
        particle_life_variance: float = 0.2,
        particle_speed: Tuple[float, float] = (50, 100),
        direction: float = -90.0,  # Degrees, -90 = up
        spread: float = 360.0,     # Degrees of spread
        gravity: Tuple[float, float] = (0, 100),
        particle_size: Tuple[float, float] = (5, 10),
        size_decay: float = 0.0,
        colors: List[Tuple[int, int, int, int]] = None,
        fade_out: bool = True,
        rotation_speed: Tuple[float, float] = (0, 0),
        max_particles: int = 500
    ):
        """Initialize particle emitter.

        Args:
            position: Emitter position
            emission_rate: Particles per second
            particle_life: Base particle lifetime in seconds
            particle_life_variance: Random variance in lifetime
            particle_speed: (min, max) speed range
            direction: Emission direction in degrees
            spread: Emission spread angle
            gravity: Gravity force (x, y)
            particle_size: (min, max) size range
            size_decay: Size change per second (negative = shrink)
            colors: List of possible particle colors
            fade_out: Whether particles fade as they die
            rotation_speed: (min, max) rotation speed in degrees/sec
            max_particles: Maximum particle count
        """
        self.position = Vec2.from_tuple(position)
        self.emission_rate = emission_rate
        self.particle_life = particle_life
        self.particle_life_variance = particle_life_variance
        self.particle_speed = particle_speed
        self.direction = math.radians(direction)
        self.spread = math.radians(spread)
        self.gravity = Vec2.from_tuple(gravity)
        self.particle_size = particle_size
        self.size_decay = size_decay
        self.colors = colors or [(255, 255, 255, 255)]
        self.fade_out = fade_out
        self.rotation_speed = rotation_speed
        self.max_particles = max_particles

        self.particles: List[Particle] = []
        self._emission_accumulator = 0.0
        self.active = True

    def update(self, dt: float) -> None:
        """Update particle system.

        Args:
            dt: Time delta in seconds
        """
        # Emit new particles
        if self.active:
            self._emission_accumulator += self.emission_rate * dt
            while self._emission_accumulator >= 1.0 and len(self.particles) < self.max_particles:
                self._emit_particle()
                self._emission_accumulator -= 1.0

        # Update existing particles
        alive_particles = []
        for p in self.particles:
            # Apply physics
            p.velocity = p.velocity + self.gravity * dt
            p.position = p.position + p.velocity * dt
            p.rotation += p.rotation_speed * dt

            # Apply decay
            p.life -= p.life_decay * dt
            p.size += self.size_decay * dt

            if p.life > 0 and p.size > 0:
                alive_particles.append(p)

        self.particles = alive_particles

    def _emit_particle(self) -> None:
        """Emit a single particle."""
        # Random angle within spread
        angle = self.direction + (random.random() - 0.5) * self.spread

        # Random speed
        speed = random.uniform(*self.particle_speed)

        # Create velocity
        velocity = Vec2.from_angle(angle, speed)

        # Random size
        size = random.uniform(*self.particle_size)

        # Random life
        life_variance = random.uniform(-self.particle_life_variance, self.particle_life_variance)
        life = self.particle_life + life_variance

        # Random color
        color = random.choice(self.colors)

        # Random rotation speed
        rot_speed = random.uniform(*self.rotation_speed)

        particle = Particle(
            position=Vec2(self.position.x, self.position.y),
            velocity=velocity,
            life=1.0,
            life_decay=1.0 / (life * 60),  # Convert to per-frame
            size=size,
            rotation=random.random() * 360,
            rotation_speed=rot_speed,
            color=color
        )

        self.particles.append(particle)

    def render(
        self,
        canvas_size: Tuple[int, int],
        particle_image: Image.Image = None
    ) -> Image.Image:
        """Render particles to an image.

        Args:
            canvas_size: Output size (width, height)
            particle_image: Optional image for each particle

        Returns:
            RGBA image with rendered particles
        """
        canvas = Image.new('RGBA', canvas_size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(canvas)

        for p in self.particles:
            x, y = int(p.position.x), int(p.position.y)
            size = max(1, int(p.size))

            # Calculate alpha based on life
            alpha = int(p.color[3] * p.life) if self.fade_out else p.color[3]
            color = (p.color[0], p.color[1], p.color[2], alpha)

            if particle_image:
                # Use custom particle image
                scaled = particle_image.resize(
                    (size * 2, size * 2),
                    Image.Resampling.LANCZOS
                )
                if p.rotation != 0:
                    scaled = scaled.rotate(p.rotation, expand=True)
                # Apply color tint and alpha
                canvas.paste(
                    scaled,
                    (x - scaled.width // 2, y - scaled.height // 2),
                    scaled
                )
            else:
                # Draw circle
                draw.ellipse(
                    [x - size, y - size, x + size, y + size],
                    fill=color
                )

        return canvas

    def burst(self, count: int) -> None:
        """Emit a burst of particles."""
        for _ in range(count):
            if len(self.particles) < self.max_particles:
                self._emit_particle()


# Pre-configured particle effects

def create_sparkle_emitter(
    position: Tuple[float, float],
    intensity: float = 1.0
) -> ParticleEmitter:
    """Create a sparkle/glitter effect."""
    return ParticleEmitter(
        position=position,
        emission_rate=20 * intensity,
        particle_life=0.5,
        particle_speed=(100, 200),
        direction=-90,
        spread=360,
        gravity=(0, 50),
        particle_size=(2, 5),
        colors=[
            (255, 255, 200, 255),
            (255, 220, 150, 255),
            (255, 200, 100, 255),
        ],
        fade_out=True
    )


def create_dust_emitter(
    position: Tuple[float, float],
    direction: float = 0
) -> ParticleEmitter:
    """Create a dust cloud effect."""
    return ParticleEmitter(
        position=position,
        emission_rate=30,
        particle_life=1.5,
        particle_speed=(20, 60),
        direction=direction,
        spread=90,
        gravity=(0, -10),  # Rises slightly
        particle_size=(3, 8),
        size_decay=-2,
        colors=[
            (200, 180, 150, 150),
            (180, 160, 130, 120),
            (160, 140, 110, 100),
        ],
        fade_out=True
    )


def create_rain_emitter(
    area: Tuple[float, float, float, float],  # x, y, width, height
    intensity: float = 1.0
) -> ParticleEmitter:
    """Create a rain effect."""
    # Emit across the width
    class RainEmitter(ParticleEmitter):
        def __init__(self, area, intensity):
            super().__init__(
                position=(area[0] + area[2] / 2, area[1]),
                emission_rate=100 * intensity,
                particle_life=1.0,
                particle_speed=(400, 600),
                direction=100,  # Slightly angled
                spread=10,
                gravity=(0, 200),
                particle_size=(1, 3),
                colors=[(200, 220, 255, 180)],
                fade_out=False
            )
            self.area = area

        def _emit_particle(self):
            # Emit across the width
            self.position.x = self.area[0] + random.random() * self.area[2]
            self.position.y = self.area[1]
            super()._emit_particle()

    return RainEmitter(area, intensity)


def create_confetti_emitter(
    position: Tuple[float, float]
) -> ParticleEmitter:
    """Create a confetti burst effect."""
    return ParticleEmitter(
        position=position,
        emission_rate=0,  # Use burst mode
        particle_life=3.0,
        particle_speed=(100, 300),
        direction=-90,
        spread=120,
        gravity=(0, 150),
        particle_size=(5, 15),
        colors=[
            (255, 50, 50, 255),   # Red
            (50, 255, 50, 255),   # Green
            (50, 50, 255, 255),   # Blue
            (255, 255, 50, 255),  # Yellow
            (255, 50, 255, 255),  # Magenta
            (50, 255, 255, 255),  # Cyan
        ],
        rotation_speed=(-720, 720),
        fade_out=False
    )


# ============================================================================
# IMAGE EFFECTS
# ============================================================================

def apply_glow(
    image: Image.Image,
    radius: float = 10.0,
    intensity: float = 1.0,
    color: Tuple[int, int, int] = None
) -> Image.Image:
    """Apply glow effect to an image.

    Args:
        image: Source image (RGBA)
        radius: Glow radius
        intensity: Glow intensity (0-2)
        color: Optional glow color override

    Returns:
        Image with glow effect
    """
    # Create glow layer
    if color:
        glow = Image.new('RGBA', image.size, color + (0,))
        glow.paste(image, mask=image.split()[3])
    else:
        glow = image.copy()

    # Blur for glow
    glow = glow.filter(ImageFilter.GaussianBlur(radius=radius))

    # Enhance brightness
    if intensity != 1.0:
        enhancer = ImageEnhance.Brightness(glow)
        glow = enhancer.enhance(intensity)

    # Composite
    result = Image.alpha_composite(glow, image)
    return result


def apply_drop_shadow(
    image: Image.Image,
    offset: Tuple[int, int] = (5, 5),
    blur: float = 5.0,
    color: Tuple[int, int, int, int] = (0, 0, 0, 128)
) -> Image.Image:
    """Apply drop shadow to an image.

    Args:
        image: Source image (RGBA)
        offset: Shadow offset (x, y)
        blur: Shadow blur radius
        color: Shadow color with alpha

    Returns:
        Image with shadow (may be larger than original)
    """
    # Create shadow
    shadow = Image.new('RGBA', image.size, (0, 0, 0, 0))
    shadow_color = Image.new('RGBA', image.size, color)
    shadow.paste(shadow_color, mask=image.split()[3])

    # Blur shadow
    if blur > 0:
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=blur))

    # Create output with room for shadow
    margin = max(abs(offset[0]), abs(offset[1])) + int(blur * 2)
    result = Image.new('RGBA', (
        image.width + margin * 2,
        image.height + margin * 2
    ), (0, 0, 0, 0))

    # Paste shadow
    result.paste(shadow, (margin + offset[0], margin + offset[1]), shadow)

    # Paste original
    result.paste(image, (margin, margin), image)

    return result


def apply_color_grade(
    image: Image.Image,
    brightness: float = 1.0,
    contrast: float = 1.0,
    saturation: float = 1.0,
    tint: Tuple[int, int, int] = None,
    tint_strength: float = 0.3
) -> Image.Image:
    """Apply color grading to an image.

    Args:
        image: Source image
        brightness: Brightness adjustment (1.0 = no change)
        contrast: Contrast adjustment (1.0 = no change)
        saturation: Saturation adjustment (1.0 = no change)
        tint: Optional color tint
        tint_strength: Tint blend strength (0-1)

    Returns:
        Color-graded image
    """
    result = image.copy()

    # Brightness
    if brightness != 1.0:
        enhancer = ImageEnhance.Brightness(result)
        result = enhancer.enhance(brightness)

    # Contrast
    if contrast != 1.0:
        enhancer = ImageEnhance.Contrast(result)
        result = enhancer.enhance(contrast)

    # Saturation
    if saturation != 1.0:
        enhancer = ImageEnhance.Color(result)
        result = enhancer.enhance(saturation)

    # Tint
    if tint and tint_strength > 0:
        tint_layer = Image.new('RGBA', image.size, tint + (255,))
        result = Image.blend(result, tint_layer, tint_strength)

    return result


def apply_vignette(
    image: Image.Image,
    intensity: float = 0.5,
    radius: float = 0.8
) -> Image.Image:
    """Apply vignette effect.

    Args:
        image: Source image
        intensity: Darkness intensity (0-1)
        radius: Vignette radius (0 = all dark, 1 = edge dark)

    Returns:
        Image with vignette
    """
    width, height = image.size

    # Create radial gradient mask using concentric ellipses (fast)
    mask = Image.new('L', (width, height), 255)
    draw = ImageDraw.Draw(mask)

    # Draw from outside in with decreasing darkness
    max_dim = max(width, height)
    center_x, center_y = width // 2, height // 2

    # Number of gradient steps (more = smoother)
    steps = 50

    for i in range(steps):
        # Progress from edge (0) to center (1)
        t = i / steps

        # Calculate ellipse size (larger at start, smaller at end)
        # Scale goes from 1.5 (outside image) down to radius
        scale = 1.5 - t * (1.5 - radius)
        ellipse_w = int(width * scale)
        ellipse_h = int(height * scale)

        # Calculate brightness: edges are dark, center is bright
        if t < (1 - radius):
            # In the vignette zone
            brightness = int(255 * (1 - intensity * (1 - t / (1 - radius))))
        else:
            brightness = 255

        # Draw filled ellipse
        x0 = center_x - ellipse_w // 2
        y0 = center_y - ellipse_h // 2
        x1 = center_x + ellipse_w // 2
        y1 = center_y + ellipse_h // 2
        draw.ellipse([x0, y0, x1, y1], fill=brightness)

    # Blur the mask for smooth gradient
    mask = mask.filter(ImageFilter.GaussianBlur(radius=max_dim // 20))

    # Apply mask: composite original over black using mask
    dark = Image.new('RGBA', image.size, (0, 0, 0, 255))
    result = Image.composite(image, dark, mask)

    return result


# ============================================================================
# TRANSITIONS
# ============================================================================

class Transition:
    """Base class for transitions between images/scenes."""

    def __init__(self, duration: float = 1.0):
        """Initialize transition.

        Args:
            duration: Transition duration in seconds
        """
        self.duration = duration

    def apply(
        self,
        from_image: Image.Image,
        to_image: Image.Image,
        progress: float
    ) -> Image.Image:
        """Apply transition at given progress.

        Args:
            from_image: Starting image
            to_image: Ending image
            progress: Transition progress (0-1)

        Returns:
            Blended image
        """
        raise NotImplementedError


class FadeTransition(Transition):
    """Simple cross-fade transition."""

    def apply(
        self,
        from_image: Image.Image,
        to_image: Image.Image,
        progress: float
    ) -> Image.Image:
        return Image.blend(from_image, to_image, progress)


class WipeTransition(Transition):
    """Wipe transition in a direction."""

    def __init__(
        self,
        duration: float = 1.0,
        direction: str = "left"  # left, right, up, down
    ):
        super().__init__(duration)
        self.direction = direction

    def apply(
        self,
        from_image: Image.Image,
        to_image: Image.Image,
        progress: float
    ) -> Image.Image:
        width, height = from_image.size
        result = from_image.copy()

        if self.direction == "left":
            x = int(width * progress)
            crop = to_image.crop((0, 0, x, height))
            result.paste(crop, (0, 0))
        elif self.direction == "right":
            x = int(width * (1 - progress))
            crop = to_image.crop((x, 0, width, height))
            result.paste(crop, (x, 0))
        elif self.direction == "up":
            y = int(height * progress)
            crop = to_image.crop((0, 0, width, y))
            result.paste(crop, (0, 0))
        elif self.direction == "down":
            y = int(height * (1 - progress))
            crop = to_image.crop((0, y, width, height))
            result.paste(crop, (0, y))

        return result


class DissolveTransition(Transition):
    """Pixel dissolve transition."""

    def __init__(
        self,
        duration: float = 1.0,
        block_size: int = 8
    ):
        super().__init__(duration)
        self.block_size = block_size
        self._pattern = None

    def apply(
        self,
        from_image: Image.Image,
        to_image: Image.Image,
        progress: float
    ) -> Image.Image:
        width, height = from_image.size

        # Generate pattern on first use
        if self._pattern is None or self._pattern[0] != (width, height):
            blocks_x = (width + self.block_size - 1) // self.block_size
            blocks_y = (height + self.block_size - 1) // self.block_size
            pattern = list(range(blocks_x * blocks_y))
            random.shuffle(pattern)
            self._pattern = ((width, height), pattern, blocks_x)

        _, pattern, blocks_x = self._pattern
        threshold = int(len(pattern) * progress)

        mask = Image.new('L', (width, height), 0)
        draw = ImageDraw.Draw(mask)

        for i, block_idx in enumerate(pattern):
            if i < threshold:
                bx = (block_idx % blocks_x) * self.block_size
                by = (block_idx // blocks_x) * self.block_size
                draw.rectangle(
                    [bx, by, bx + self.block_size, by + self.block_size],
                    fill=255
                )

        return Image.composite(to_image, from_image, mask)


class IrisTransition(Transition):
    """Circular iris in/out transition."""

    def __init__(
        self,
        duration: float = 1.0,
        iris_out: bool = True,  # True = iris out, False = iris in
        center: Tuple[float, float] = (0.5, 0.5)
    ):
        super().__init__(duration)
        self.iris_out = iris_out
        self.center = center

    def apply(
        self,
        from_image: Image.Image,
        to_image: Image.Image,
        progress: float
    ) -> Image.Image:
        if not self.iris_out:
            progress = 1 - progress
            from_image, to_image = to_image, from_image

        width, height = from_image.size
        center_x = int(width * self.center[0])
        center_y = int(height * self.center[1])
        max_radius = math.sqrt(
            max(center_x, width - center_x) ** 2 +
            max(center_y, height - center_y) ** 2
        )
        radius = int(max_radius * progress)

        mask = Image.new('L', (width, height), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse(
            [center_x - radius, center_y - radius,
             center_x + radius, center_y + radius],
            fill=255
        )

        return Image.composite(to_image, from_image, mask)


# ============================================================================
# PATH ANIMATION
# ============================================================================

@dataclass
class BezierPoint:
    """A point on a bezier curve."""
    position: Tuple[float, float]
    control_in: Optional[Tuple[float, float]] = None   # Control point coming in
    control_out: Optional[Tuple[float, float]] = None  # Control point going out


class BezierPath:
    """Bezier curve path for object animation.

    Usage:
        path = BezierPath()
        path.add_point((100, 100))
        path.add_point((500, 100), control_out=(200, 50))
        path.add_point((500, 400), control_in=(550, 200))
        path.add_point((100, 400))

        for t in range(100):
            x, y = path.get_point(t / 100)
            angle = path.get_tangent_angle(t / 100)
    """

    def __init__(self):
        self.points: List[BezierPoint] = []

    def add_point(
        self,
        position: Tuple[float, float],
        control_in: Tuple[float, float] = None,
        control_out: Tuple[float, float] = None
    ) -> None:
        """Add a point to the path."""
        self.points.append(BezierPoint(position, control_in, control_out))

    def get_point(self, t: float) -> Tuple[float, float]:
        """Get position at t (0-1) along the path.

        Args:
            t: Progress along path (0-1)

        Returns:
            (x, y) position
        """
        if not self.points:
            return (0, 0)
        if len(self.points) == 1:
            return self.points[0].position
        if t <= 0:
            return self.points[0].position
        if t >= 1:
            return self.points[-1].position

        # Find segment
        num_segments = len(self.points) - 1
        segment_progress = t * num_segments
        segment_index = int(segment_progress)
        if segment_index >= num_segments:
            segment_index = num_segments - 1
        local_t = segment_progress - segment_index

        # Get segment points
        p0 = self.points[segment_index]
        p1 = self.points[segment_index + 1]

        # Calculate control points
        c0 = p0.control_out or p0.position
        c1 = p1.control_in or p1.position

        # Cubic bezier
        return self._cubic_bezier(p0.position, c0, c1, p1.position, local_t)

    def _cubic_bezier(
        self,
        p0: Tuple[float, float],
        c0: Tuple[float, float],
        c1: Tuple[float, float],
        p1: Tuple[float, float],
        t: float
    ) -> Tuple[float, float]:
        """Calculate cubic bezier point."""
        t2 = t * t
        t3 = t2 * t
        mt = 1 - t
        mt2 = mt * mt
        mt3 = mt2 * mt

        x = mt3 * p0[0] + 3 * mt2 * t * c0[0] + 3 * mt * t2 * c1[0] + t3 * p1[0]
        y = mt3 * p0[1] + 3 * mt2 * t * c0[1] + 3 * mt * t2 * c1[1] + t3 * p1[1]

        return (x, y)

    def get_tangent_angle(self, t: float) -> float:
        """Get tangent angle at t in degrees.

        Args:
            t: Progress along path

        Returns:
            Angle in degrees
        """
        # Sample two nearby points
        delta = 0.001
        p1 = self.get_point(max(0, t - delta))
        p2 = self.get_point(min(1, t + delta))

        dx = p2[0] - p1[0]
        dy = p2[1] - p1[1]

        return math.degrees(math.atan2(dy, dx))

    def get_length(self, samples: int = 100) -> float:
        """Approximate path length.

        Args:
            samples: Number of samples for approximation

        Returns:
            Approximate path length in pixels
        """
        if len(self.points) < 2:
            return 0

        total = 0
        prev = self.get_point(0)
        for i in range(1, samples + 1):
            t = i / samples
            curr = self.get_point(t)
            total += math.sqrt(
                (curr[0] - prev[0]) ** 2 +
                (curr[1] - prev[1]) ** 2
            )
            prev = curr
        return total


class PathFollower:
    """Object that follows a bezier path.

    Usage:
        path = BezierPath()
        path.add_point((100, 100))
        path.add_point((500, 400))

        follower = PathFollower(path, duration=2.0, orient_to_path=True)

        for frame in range(60):
            follower.update(1/30)
            x, y = follower.position
            angle = follower.rotation
    """

    def __init__(
        self,
        path: BezierPath,
        duration: float = 1.0,
        orient_to_path: bool = False,
        loop: bool = False,
        easing: Callable[[float], float] = None
    ):
        """Initialize path follower.

        Args:
            path: Path to follow
            duration: Time to traverse path in seconds
            orient_to_path: Rotate to face movement direction
            loop: Loop back to start
            easing: Optional easing function
        """
        self.path = path
        self.duration = duration
        self.orient_to_path = orient_to_path
        self.loop = loop
        self.easing = easing or (lambda t: t)

        self._time = 0
        self._position = path.get_point(0)
        self._rotation = 0

    @property
    def position(self) -> Tuple[float, float]:
        """Current position."""
        return self._position

    @property
    def rotation(self) -> float:
        """Current rotation in degrees."""
        return self._rotation

    @property
    def progress(self) -> float:
        """Current progress (0-1)."""
        return min(1.0, self._time / self.duration)

    @property
    def finished(self) -> bool:
        """Whether path traversal is complete."""
        return not self.loop and self._time >= self.duration

    def update(self, dt: float) -> None:
        """Update position along path.

        Args:
            dt: Time delta in seconds
        """
        self._time += dt

        if self.loop and self._time > self.duration:
            self._time = self._time % self.duration

        t = min(1.0, self._time / self.duration)
        eased_t = self.easing(t)

        self._position = self.path.get_point(eased_t)

        if self.orient_to_path:
            self._rotation = self.path.get_tangent_angle(eased_t)

    def reset(self) -> None:
        """Reset to start of path."""
        self._time = 0
        self._position = self.path.get_point(0)
        self._rotation = 0 if not self.orient_to_path else self.path.get_tangent_angle(0)
