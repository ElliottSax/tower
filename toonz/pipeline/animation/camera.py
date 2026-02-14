"""Camera system with effects for the animation pipeline.

Provides:
- Virtual camera with pan, zoom, rotation
- Parallax depth layers
- Camera shake effects
- Focus/depth of field simulation
- Smooth camera following
- Cinematic transitions
"""

import math
import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Callable
from PIL import Image, ImageFilter, ImageEnhance

from .keyframes import KeyframeTrack, AnimationClip, EasingType
from .physics import Spring, Spring2D


@dataclass
class CameraState:
    """Current camera state."""
    position: Tuple[float, float] = (0, 0)  # Center position in world space
    zoom: float = 1.0                        # Zoom level (1.0 = 100%)
    rotation: float = 0.0                    # Rotation in degrees


class Camera:
    """Virtual camera for scene rendering.

    Features:
    - Pan/zoom/rotation with keyframe animation
    - Shake effects (impact, handheld)
    - Smooth following with springy motion
    - Parallax layer support

    Usage:
        camera = Camera(viewport_size=(1920, 1080))

        # Set up animation
        camera.animation = AnimationClip("camera_move")
        camera.animation.add_track("position").add_keyframe(0, (960, 540))
        camera.animation.add_track("position").add_keyframe(60, (1500, 800))
        camera.animation.add_track("zoom").add_keyframe(0, 1.0)
        camera.animation.add_track("zoom").add_keyframe(60, 1.5)

        # Add shake on impact
        camera.add_shake(ShakeEffect.IMPACT, intensity=0.3, duration=0.5)

        # Each frame:
        camera.update(frame, fps=30)
        transformed_image = camera.apply(scene_image)
    """

    def __init__(
        self,
        viewport_size: Tuple[int, int] = (1920, 1080),
        bounds: Optional[Tuple[int, int, int, int]] = None
    ):
        """Initialize camera.

        Args:
            viewport_size: Output viewport size (width, height)
            bounds: Optional world bounds (x, y, width, height) to clamp camera
        """
        self.viewport_size = viewport_size
        self.bounds = bounds

        # Current state
        self.state = CameraState(
            position=(viewport_size[0] / 2, viewport_size[1] / 2)
        )

        # Animation
        self.animation: Optional[AnimationClip] = None

        # Following
        self._follow_target: Optional[Tuple[float, float]] = None
        self._follow_spring = Spring2D(stiffness=100, damping=15)
        self._follow_offset = (0, 0)
        self._follow_lead = 0.0  # Look-ahead amount

        # Shake effects
        self._shake_offset = (0, 0)
        self._shake_rotation = 0.0
        self._active_shakes: List["ShakeInstance"] = []

        # Zoom smoothing
        self._zoom_spring = Spring(stiffness=200, damping=20, initial_value=1.0)

    @property
    def position(self) -> Tuple[float, float]:
        """Current camera center position."""
        return self.state.position

    @position.setter
    def position(self, value: Tuple[float, float]) -> None:
        self.state.position = value

    @property
    def zoom(self) -> float:
        """Current zoom level."""
        return self.state.zoom

    @zoom.setter
    def zoom(self, value: float) -> None:
        self.state.zoom = max(0.1, value)

    @property
    def rotation(self) -> float:
        """Current rotation in degrees."""
        return self.state.rotation

    @rotation.setter
    def rotation(self, value: float) -> None:
        self.state.rotation = value

    def follow(
        self,
        target: Tuple[float, float],
        offset: Tuple[float, float] = (0, 0),
        lead: float = 0.0
    ) -> None:
        """Set camera to follow a target.

        Args:
            target: Target position to follow
            offset: Offset from target
            lead: Look-ahead amount (anticipates movement)
        """
        self._follow_target = target
        self._follow_offset = offset
        self._follow_lead = lead

    def stop_following(self) -> None:
        """Stop following target."""
        self._follow_target = None

    def add_shake(
        self,
        shake_type: "ShakeType",
        intensity: float = 1.0,
        duration: float = 0.5,
        frequency: float = 30.0
    ) -> None:
        """Add a shake effect.

        Args:
            shake_type: Type of shake effect
            intensity: Shake intensity multiplier
            duration: Duration in seconds
            frequency: Shake frequency in Hz
        """
        shake = ShakeInstance(
            shake_type=shake_type,
            intensity=intensity,
            duration=duration,
            frequency=frequency,
            start_time=0  # Will be set in update
        )
        shake._started = False
        self._active_shakes.append(shake)

    def update(self, frame: int, fps: float = 30.0) -> None:
        """Update camera state for frame.

        Args:
            frame: Current frame number
            fps: Frames per second
        """
        time = frame / fps
        dt = 1.0 / fps

        # Apply animation
        if self.animation:
            pos = self.animation.get_value("position", frame)
            if pos:
                self.state.position = tuple(pos) if isinstance(pos, list) else pos

            zoom = self.animation.get_value("zoom", frame)
            if zoom is not None:
                self._zoom_spring.set_target(zoom)

            rot = self.animation.get_value("rotation", frame)
            if rot is not None:
                self.state.rotation = rot

        # Apply following
        if self._follow_target:
            target = (
                self._follow_target[0] + self._follow_offset[0],
                self._follow_target[1] + self._follow_offset[1]
            )
            self._follow_spring.set_target(target)
            self.state.position = self._follow_spring.update(dt)

        # Smooth zoom
        self.state.zoom = self._zoom_spring.update(dt)

        # Apply bounds
        if self.bounds:
            self.state.position = self._clamp_to_bounds(self.state.position)

        # Update shakes
        self._shake_offset = (0, 0)
        self._shake_rotation = 0.0
        remaining_shakes = []

        for shake in self._active_shakes:
            if not shake._started:
                shake.start_time = time
                shake._started = True

            offset, rotation = shake.sample(time)
            self._shake_offset = (
                self._shake_offset[0] + offset[0],
                self._shake_offset[1] + offset[1]
            )
            self._shake_rotation += rotation

            if not shake.is_finished(time):
                remaining_shakes.append(shake)

        self._active_shakes = remaining_shakes

    def _clamp_to_bounds(self, pos: Tuple[float, float]) -> Tuple[float, float]:
        """Clamp position to camera bounds."""
        if not self.bounds:
            return pos

        half_w = self.viewport_size[0] / 2 / self.state.zoom
        half_h = self.viewport_size[1] / 2 / self.state.zoom

        bx, by, bw, bh = self.bounds

        x = max(bx + half_w, min(bx + bw - half_w, pos[0]))
        y = max(by + half_h, min(by + bh - half_h, pos[1]))

        return (x, y)

    def get_view_rect(self) -> Tuple[float, float, float, float]:
        """Get the visible rectangle in world coordinates.

        Returns:
            (x, y, width, height) of visible area
        """
        w = self.viewport_size[0] / self.state.zoom
        h = self.viewport_size[1] / self.state.zoom
        x = self.state.position[0] - w / 2
        y = self.state.position[1] - h / 2
        return (x, y, w, h)

    def world_to_screen(self, world_pos: Tuple[float, float]) -> Tuple[int, int]:
        """Convert world position to screen position."""
        # Apply shake
        cam_x = self.state.position[0] + self._shake_offset[0]
        cam_y = self.state.position[1] + self._shake_offset[1]

        # Translate relative to camera
        rel_x = world_pos[0] - cam_x
        rel_y = world_pos[1] - cam_y

        # Apply zoom
        rel_x *= self.state.zoom
        rel_y *= self.state.zoom

        # Apply rotation
        if self.state.rotation != 0 or self._shake_rotation != 0:
            angle = math.radians(-(self.state.rotation + self._shake_rotation))
            cos_a = math.cos(angle)
            sin_a = math.sin(angle)
            new_x = rel_x * cos_a - rel_y * sin_a
            new_y = rel_x * sin_a + rel_y * cos_a
            rel_x, rel_y = new_x, new_y

        # Center on viewport
        screen_x = rel_x + self.viewport_size[0] / 2
        screen_y = rel_y + self.viewport_size[1] / 2

        return (int(screen_x), int(screen_y))

    def screen_to_world(self, screen_pos: Tuple[int, int]) -> Tuple[float, float]:
        """Convert screen position to world position."""
        # Center relative
        rel_x = screen_pos[0] - self.viewport_size[0] / 2
        rel_y = screen_pos[1] - self.viewport_size[1] / 2

        # Apply inverse rotation
        if self.state.rotation != 0 or self._shake_rotation != 0:
            angle = math.radians(self.state.rotation + self._shake_rotation)
            cos_a = math.cos(angle)
            sin_a = math.sin(angle)
            new_x = rel_x * cos_a - rel_y * sin_a
            new_y = rel_x * sin_a + rel_y * cos_a
            rel_x, rel_y = new_x, new_y

        # Apply inverse zoom
        rel_x /= self.state.zoom
        rel_y /= self.state.zoom

        # Translate to world
        cam_x = self.state.position[0] + self._shake_offset[0]
        cam_y = self.state.position[1] + self._shake_offset[1]

        return (rel_x + cam_x, rel_y + cam_y)

    def apply(self, image: Image.Image) -> Image.Image:
        """Apply camera transform to an image.

        Args:
            image: Source image (full scene render)

        Returns:
            Transformed image matching viewport size
        """
        # Get effective camera position with shake
        cam_x = self.state.position[0] + self._shake_offset[0]
        cam_y = self.state.position[1] + self._shake_offset[1]
        cam_rot = self.state.rotation + self._shake_rotation

        # Calculate crop region at 100% zoom
        vw, vh = self.viewport_size
        scaled_w = vw / self.state.zoom
        scaled_h = vh / self.state.zoom

        left = cam_x - scaled_w / 2
        top = cam_y - scaled_h / 2
        right = left + scaled_w
        bottom = top + scaled_h

        # Handle rotation by expanding crop area
        if cam_rot != 0:
            # Expand crop to fit rotated viewport
            diagonal = math.sqrt(scaled_w**2 + scaled_h**2)
            expand = (diagonal - min(scaled_w, scaled_h)) / 2
            left -= expand
            top -= expand
            right += expand
            bottom += expand

        # Clamp to image bounds and pad if needed
        iw, ih = image.size
        pad_left = max(0, -int(left))
        pad_top = max(0, -int(top))
        pad_right = max(0, int(right) - iw)
        pad_bottom = max(0, int(bottom) - ih)

        # Crop
        crop_left = max(0, int(left))
        crop_top = max(0, int(top))
        crop_right = min(iw, int(right))
        crop_bottom = min(ih, int(bottom))

        cropped = image.crop((crop_left, crop_top, crop_right, crop_bottom))

        # Add padding if needed
        if pad_left > 0 or pad_top > 0 or pad_right > 0 or pad_bottom > 0:
            padded = Image.new('RGBA', (
                cropped.width + pad_left + pad_right,
                cropped.height + pad_top + pad_bottom
            ), (0, 0, 0, 255))
            padded.paste(cropped, (pad_left, pad_top))
            cropped = padded

        # Apply rotation
        if cam_rot != 0:
            cropped = cropped.rotate(
                cam_rot,
                expand=False,
                resample=Image.Resampling.BILINEAR,
                center=(cropped.width / 2, cropped.height / 2)
            )
            # Crop back to viewport size ratio
            cw, ch = cropped.size
            new_left = (cw - scaled_w) / 2
            new_top = (ch - scaled_h) / 2
            cropped = cropped.crop((
                int(new_left),
                int(new_top),
                int(new_left + scaled_w),
                int(new_top + scaled_h)
            ))

        # Scale to viewport size
        if cropped.size != self.viewport_size:
            cropped = cropped.resize(self.viewport_size, Image.Resampling.LANCZOS)

        return cropped


class ShakeType:
    """Types of camera shake effects."""
    IMPACT = "impact"          # Single impact, fast decay
    EXPLOSION = "explosion"    # Large impact with rotation
    HANDHELD = "handheld"      # Continuous subtle shake
    EARTHQUAKE = "earthquake"  # Low frequency, high amplitude
    VIBRATION = "vibration"    # High frequency, low amplitude


@dataclass
class ShakeInstance:
    """An active shake effect."""
    shake_type: str
    intensity: float = 1.0
    duration: float = 0.5
    frequency: float = 30.0
    start_time: float = 0.0

    _started: bool = field(default=False, repr=False)
    _seed: float = field(default_factory=random.random, repr=False)

    def sample(self, time: float) -> Tuple[Tuple[float, float], float]:
        """Sample shake at time.

        Returns:
            ((offset_x, offset_y), rotation_degrees)
        """
        elapsed = time - self.start_time
        if elapsed < 0 or elapsed > self.duration:
            return ((0, 0), 0.0)

        # Calculate decay
        progress = elapsed / self.duration
        decay = 1.0 - progress  # Linear decay

        if self.shake_type == ShakeType.IMPACT:
            decay = math.pow(decay, 2)  # Faster decay
            amplitude = 20 * self.intensity * decay
            t = elapsed * self.frequency
            offset = (
                math.sin(t * 2 + self._seed * 10) * amplitude,
                math.cos(t * 3 + self._seed * 5) * amplitude * 0.7
            )
            rotation = math.sin(t + self._seed) * 2 * self.intensity * decay
            return (offset, rotation)

        elif self.shake_type == ShakeType.EXPLOSION:
            decay = math.pow(decay, 1.5)
            amplitude = 40 * self.intensity * decay
            t = elapsed * self.frequency * 0.8
            offset = (
                math.sin(t * 2 + self._seed * 10) * amplitude,
                math.cos(t * 2.5 + self._seed * 7) * amplitude
            )
            rotation = math.sin(t * 0.7 + self._seed) * 5 * self.intensity * decay
            return (offset, rotation)

        elif self.shake_type == ShakeType.HANDHELD:
            # Continuous, subtle motion
            amplitude = 3 * self.intensity
            t = elapsed * self.frequency * 0.3
            offset = (
                (math.sin(t * 1.1) + math.sin(t * 2.3 + 1)) * amplitude,
                (math.cos(t * 0.9) + math.cos(t * 1.7 + 2)) * amplitude * 0.6
            )
            rotation = math.sin(t * 0.5) * 0.5 * self.intensity
            return (offset, rotation * decay)

        elif self.shake_type == ShakeType.EARTHQUAKE:
            decay = math.pow(decay, 0.5)  # Slower decay
            amplitude = 30 * self.intensity * decay
            t = elapsed * self.frequency * 0.4
            offset = (
                math.sin(t * 1.5 + self._seed * 10) * amplitude,
                abs(math.sin(t * 2 + self._seed * 5)) * amplitude * 1.5  # More vertical
            )
            rotation = math.sin(t * 0.3 + self._seed) * 3 * self.intensity * decay
            return (offset, rotation)

        elif self.shake_type == ShakeType.VIBRATION:
            amplitude = 5 * self.intensity * decay
            t = elapsed * self.frequency * 2
            offset = (
                (random.random() - 0.5) * 2 * amplitude,
                (random.random() - 0.5) * 2 * amplitude
            )
            return (offset, 0.0)

        return ((0, 0), 0.0)

    def is_finished(self, time: float) -> bool:
        """Check if shake has finished."""
        return time - self.start_time > self.duration


@dataclass
class ParallaxLayer:
    """A layer with parallax depth."""
    name: str
    image: Optional[Image.Image] = None
    image_path: Optional[str] = None
    depth: float = 1.0      # 0 = background (slow), 1 = camera plane, 2+ = foreground (fast)
    offset: Tuple[float, float] = (0, 0)
    tile: bool = False      # Tile horizontally for infinite scrolling
    z_order: int = 0


class ParallaxCamera(Camera):
    """Camera with parallax layer support.

    Layers move at different speeds based on their depth value:
    - depth 0: Completely static (distant background)
    - depth 0.5: Moves at half speed (mid-ground)
    - depth 1.0: Moves with camera (main action plane)
    - depth 1.5: Moves faster (foreground)

    Usage:
        camera = ParallaxCamera(viewport_size=(1920, 1080))

        # Add parallax layers
        camera.add_parallax_layer("sky", "sky.png", depth=0.0, z_order=-100)
        camera.add_parallax_layer("mountains", "mountains.png", depth=0.3, z_order=-50)
        camera.add_parallax_layer("trees", "trees.png", depth=0.7, z_order=-10)
        # Main scene rendered separately at depth=1.0

        # Render with parallax
        final = camera.render_parallax(main_scene_image)
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.parallax_layers: Dict[str, ParallaxLayer] = {}

    def add_parallax_layer(
        self,
        name: str,
        image_path: str = None,
        image: Image.Image = None,
        depth: float = 0.5,
        offset: Tuple[float, float] = (0, 0),
        tile: bool = False,
        z_order: int = 0
    ) -> ParallaxLayer:
        """Add a parallax layer.

        Args:
            name: Layer name
            image_path: Path to layer image
            image: Pre-loaded image
            depth: Parallax depth (0 = static, 1 = normal)
            offset: Base offset
            tile: Tile horizontally for infinite scroll
            z_order: Render order

        Returns:
            Created layer
        """
        layer = ParallaxLayer(
            name=name,
            image=image,
            image_path=image_path,
            depth=depth,
            offset=offset,
            tile=tile,
            z_order=z_order
        )
        self.parallax_layers[name] = layer

        # Load image if path provided
        if image_path and not image:
            try:
                layer.image = Image.open(image_path).convert('RGBA')
            except (FileNotFoundError, IOError):
                pass

        return layer

    def remove_parallax_layer(self, name: str) -> bool:
        """Remove a parallax layer."""
        if name in self.parallax_layers:
            del self.parallax_layers[name]
            return True
        return False

    def calculate_layer_offset(
        self,
        layer: ParallaxLayer,
        reference_position: Tuple[float, float] = None
    ) -> Tuple[float, float]:
        """Calculate the offset for a parallax layer.

        Args:
            layer: The parallax layer
            reference_position: Reference position (default: viewport center)

        Returns:
            (x, y) offset to apply to layer
        """
        if reference_position is None:
            reference_position = (
                self.viewport_size[0] / 2,
                self.viewport_size[1] / 2
            )

        # Camera offset from reference
        cam_offset_x = self.state.position[0] - reference_position[0]
        cam_offset_y = self.state.position[1] - reference_position[1]

        # Apply parallax (subtract to move opposite direction)
        parallax_x = -cam_offset_x * (1 - layer.depth)
        parallax_y = -cam_offset_y * (1 - layer.depth)

        return (
            layer.offset[0] + parallax_x,
            layer.offset[1] + parallax_y
        )

    def render_parallax(
        self,
        main_layer: Image.Image,
        main_depth: float = 1.0
    ) -> Image.Image:
        """Render all parallax layers with main scene.

        Args:
            main_layer: The main scene image (rendered separately)
            main_depth: Depth of main layer (usually 1.0)

        Returns:
            Composited image with all parallax layers
        """
        # Get all layers sorted by z_order
        all_layers = sorted(
            self.parallax_layers.values(),
            key=lambda l: l.z_order
        )

        # Create output canvas
        canvas = Image.new('RGBA', self.viewport_size, (0, 0, 0, 0))

        # Find where to insert main layer
        main_z = 0  # Default z for main layer

        for layer in all_layers:
            if layer.z_order >= main_z and layer.depth <= main_depth:
                # Render layers behind main
                self._render_parallax_layer(canvas, layer)

        # Render main layer
        main_offset = (
            int(-self.state.position[0] + self.viewport_size[0] / 2),
            int(-self.state.position[1] + self.viewport_size[1] / 2)
        )
        temp = Image.new('RGBA', self.viewport_size, (0, 0, 0, 0))
        temp.paste(main_layer, main_offset)
        canvas = Image.alpha_composite(canvas, temp)

        # Render foreground layers
        for layer in all_layers:
            if layer.z_order > main_z or layer.depth > main_depth:
                self._render_parallax_layer(canvas, layer)

        # Apply camera effects (zoom, rotation)
        return self.apply(canvas)

    def _render_parallax_layer(
        self,
        canvas: Image.Image,
        layer: ParallaxLayer
    ) -> None:
        """Render a single parallax layer onto canvas."""
        if layer.image is None:
            return

        offset = self.calculate_layer_offset(layer)
        x, y = int(offset[0]), int(offset[1])

        if layer.tile:
            # Tile horizontally
            iw = layer.image.width
            start_x = x % iw - iw
            for tile_x in range(start_x, self.viewport_size[0] + iw, iw):
                canvas.paste(layer.image, (tile_x, y), layer.image)
        else:
            canvas.paste(layer.image, (x, y), layer.image)


class DepthOfField:
    """Depth of field (focus blur) effect.

    Blurs layers based on their distance from the focal point.

    Usage:
        dof = DepthOfField(focal_distance=1.0, aperture=0.3)

        for layer in layers:
            blurred = dof.apply(layer.image, layer.depth)
    """

    def __init__(
        self,
        focal_distance: float = 1.0,
        aperture: float = 0.3,
        max_blur: float = 10.0
    ):
        """Initialize depth of field.

        Args:
            focal_distance: Distance that's in focus (depth value)
            aperture: Aperture size (larger = more blur at distance)
            max_blur: Maximum blur radius
        """
        self.focal_distance = focal_distance
        self.aperture = aperture
        self.max_blur = max_blur

    def calculate_blur(self, depth: float) -> float:
        """Calculate blur amount for a given depth.

        Args:
            depth: Layer depth value

        Returns:
            Blur radius (0 = in focus)
        """
        distance_from_focus = abs(depth - self.focal_distance)
        blur = distance_from_focus * self.aperture * self.max_blur
        return min(blur, self.max_blur)

    def apply(self, image: Image.Image, depth: float) -> Image.Image:
        """Apply depth-of-field blur to an image.

        Args:
            image: Source image
            depth: Layer depth

        Returns:
            Blurred image (or original if in focus)
        """
        blur_radius = self.calculate_blur(depth)

        if blur_radius < 0.5:
            return image

        return image.filter(ImageFilter.GaussianBlur(radius=blur_radius))
