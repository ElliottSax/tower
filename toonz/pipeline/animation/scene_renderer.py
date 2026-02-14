"""Scene renderer for compositing and video output.

Combines all animation systems into final video frames.
"""

import os
import subprocess
import tempfile
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional, Callable
from PIL import Image, ImageDraw

from .scene import Scene, SceneLayer
from .character import Character
from .camera import Camera, ParallaxCamera
from .effects import ParticleEmitter, apply_vignette, apply_color_grade
from .expressions import FacialAnimator, Emotion
from .motion_presets import MotionBlender, Pose, create_idle, create_breathing


@dataclass
class RenderSettings:
    """Settings for video rendering."""
    width: int = 1920
    height: int = 1080
    fps: int = 30
    codec: str = 'libx264'
    quality: str = 'high'  # 'draft', 'medium', 'high', 'best'
    format: str = 'mp4'

    # Quality presets (CRF values for x264)
    QUALITY_CRF = {
        'draft': 28,
        'medium': 23,
        'high': 18,
        'best': 15
    }

    def get_crf(self) -> int:
        return self.QUALITY_CRF.get(self.quality, 18)


@dataclass
class RenderProgress:
    """Progress information during rendering."""
    current_frame: int = 0
    total_frames: int = 0
    stage: str = 'initializing'
    percent: float = 0.0


class AnimatedCharacter:
    """Character with all animation controllers."""

    def __init__(self, character: Character):
        self.character = character
        self.facial = FacialAnimator()
        self.motion = MotionBlender()
        self.position = (0.0, 0.0)
        self.scale = 1.0
        self.visible = True

        # Set up default animations
        self.motion.set_base_motion(create_idle())

        # Gesture generator for speaking
        from .motion_presets import GestureGenerator
        self.gesture_gen = GestureGenerator()

    def set_emotion(self, emotion: Emotion) -> None:
        """Set character emotion."""
        self.facial.set_emotion(emotion)

    def set_speaking(self, speaking: bool) -> None:
        """Set speaking state for gesture generation."""
        self.gesture_gen.set_speaking(speaking)

    def set_lip_sync_shape(self, shape: str) -> None:
        """Set lip sync mouth shape."""
        self.facial.set_lip_sync_shape(shape)

    def update(self, dt: float) -> tuple:
        """Update all animation systems.

        Returns:
            (face_state, body_pose)
        """
        face = self.facial.update(dt)
        pose = self.motion.update(dt)

        # Generate gestures while speaking
        gesture = self.gesture_gen.update(dt)
        if gesture:
            self.motion.play_overlay(gesture, weight=0.8)

        return face, pose


class SceneRenderer:
    """Renders animated scenes to video."""

    def __init__(self, scene: Scene, settings: Optional[RenderSettings] = None):
        self.scene = scene
        self.settings = settings or RenderSettings()

        # Animation state
        self.time = 0.0
        self.frame = 0

        # Camera
        self.camera: Optional[Camera] = None
        self.parallax_camera: Optional[ParallaxCamera] = None

        # Characters with animation
        self.animated_characters: dict[str, AnimatedCharacter] = {}

        # Effects
        self.particle_emitters: list[ParticleEmitter] = []
        self.post_effects: list[Callable[[Image.Image], Image.Image]] = []

        # Rendering
        self.temp_dir: Optional[Path] = None
        self.on_progress: Optional[Callable[[RenderProgress], None]] = None

    def add_character(self, name: str, character: Character,
                      position: tuple[float, float] = (0, 0),
                      scale: float = 1.0) -> AnimatedCharacter:
        """Add an animated character to the scene."""
        anim_char = AnimatedCharacter(character)
        anim_char.position = position
        anim_char.scale = scale
        self.animated_characters[name] = anim_char
        return anim_char

    def set_camera(self, camera: Camera) -> None:
        """Set the main camera."""
        self.camera = camera

    def set_parallax_camera(self, camera: ParallaxCamera) -> None:
        """Set parallax camera for depth layers."""
        self.parallax_camera = camera

    def add_particle_emitter(self, emitter: ParticleEmitter) -> None:
        """Add a particle emitter to the scene."""
        self.particle_emitters.append(emitter)

    def add_post_effect(self, effect: Callable[[Image.Image], Image.Image]) -> None:
        """Add a post-processing effect."""
        self.post_effects.append(effect)

    def render_frame(self, frame_num: int, dt: float) -> Image.Image:
        """Render a single frame.

        Args:
            frame_num: Frame number
            dt: Delta time since last frame

        Returns:
            Rendered frame as PIL Image
        """
        width = self.settings.width
        height = self.settings.height

        # Create frame buffer
        frame = Image.new('RGBA', (width, height), (0, 0, 0, 255))

        # Update camera
        if self.camera:
            self.camera.update(dt)

        # Render background layers
        frame = self._render_background(frame, dt)

        # Update and render characters
        for name, anim_char in self.animated_characters.items():
            if anim_char.visible:
                face, pose = anim_char.update(dt)
                frame = self._render_character(frame, anim_char, face, pose)

        # Update and render particles
        for emitter in self.particle_emitters:
            emitter.update(dt)
            frame = self._render_particles(frame, emitter)

        # Render foreground layers
        frame = self._render_foreground(frame, dt)

        # Apply post effects
        for effect in self.post_effects:
            frame = effect(frame)

        # Apply camera effects (vignette, color grading, etc.)
        if self.camera and self.camera.vignette_intensity > 0:
            frame = apply_vignette(frame, self.camera.vignette_intensity)

        return frame

    def _render_background(self, frame: Image.Image, dt: float) -> Image.Image:
        """Render background layers."""
        if self.parallax_camera:
            # Render parallax layers
            for layer in sorted(self.parallax_camera.layers, key=lambda l: l.depth):
                if layer.image:
                    offset = self.parallax_camera.get_layer_offset(layer.name)
                    # Position layer with parallax offset
                    layer_pos = (int(offset[0]), int(offset[1]))
                    frame.paste(layer.image, layer_pos, layer.image if layer.image.mode == 'RGBA' else None)
        elif self.scene.background:
            # Simple background
            bg = Image.open(self.scene.background).convert('RGBA')
            bg = bg.resize((self.settings.width, self.settings.height))
            frame = Image.alpha_composite(frame, bg)

        return frame

    def _render_character(self, frame: Image.Image,
                          anim_char: AnimatedCharacter,
                          face, pose: Pose) -> Image.Image:
        """Render an animated character."""
        character = anim_char.character

        # Get character layers and compose
        # This is a simplified version - full implementation would
        # apply pose transforms to each layer

        if character.rig:
            # Render each layer with transforms
            for layer_name in character.rig.layer_order:
                layer_def = character.rig.layers.get(layer_name)
                if not layer_def:
                    continue

                # Get the appropriate asset variant
                asset_key = self._get_layer_asset_key(layer_name, face, pose)
                asset_path = layer_def.assets.get(asset_key) or layer_def.assets.get('default')

                if asset_path and os.path.exists(asset_path):
                    layer_img = Image.open(asset_path).convert('RGBA')

                    # Apply transform from pose
                    transform = self._get_layer_transform(layer_name, pose)
                    layer_img = self._apply_transform(layer_img, transform, anim_char.scale)

                    # Position on frame
                    pos = (
                        int(anim_char.position[0] + layer_def.offset[0] + transform.x),
                        int(anim_char.position[1] + layer_def.offset[1] + transform.y)
                    )

                    # Composite
                    frame.paste(layer_img, pos, layer_img)

        return frame

    def _get_layer_asset_key(self, layer_name: str, face, pose) -> str:
        """Determine which asset variant to use for a layer."""
        # Mouth shape from lip sync
        if layer_name == 'mouth':
            return face.mouth.open > 0.1 and 'open' or 'closed'

        # Eyes based on blink/expression
        if layer_name == 'eyes':
            openness = (face.left_eye.openness + face.right_eye.openness) / 2
            if openness < 0.2:
                return 'closed'
            elif openness < 0.6:
                return 'half'
            return 'open'

        # Eyebrows from expression
        if layer_name == 'eyebrows':
            height = (face.left_eyebrow.height + face.right_eyebrow.height) / 2
            if height > 0.3:
                return 'raised'
            elif height < -0.2:
                return 'lowered'
            return 'neutral'

        return 'default'

    def _get_layer_transform(self, layer_name: str, pose: Pose):
        """Get transform for a layer from pose."""
        from .motion_presets import Transform

        mapping = {
            'body': pose.body,
            'head': pose.head,
            'left_arm': pose.left_arm,
            'right_arm': pose.right_arm,
            'left_hand': pose.left_hand,
            'right_hand': pose.right_hand,
            'left_leg': pose.left_leg,
            'right_leg': pose.right_leg,
        }

        return mapping.get(layer_name, Transform())

    def _apply_transform(self, img: Image.Image, transform, scale: float) -> Image.Image:
        """Apply a transform to an image."""
        from .motion_presets import Transform

        # Scale
        new_width = int(img.width * scale * transform.scale_x)
        new_height = int(img.height * scale * transform.scale_y)
        if new_width > 0 and new_height > 0:
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Rotate
        if abs(transform.rotation) > 0.1:
            img = img.rotate(-transform.rotation, expand=True, resample=Image.Resampling.BICUBIC)

        return img

    def _render_particles(self, frame: Image.Image,
                          emitter: ParticleEmitter) -> Image.Image:
        """Render particle effects."""
        draw = ImageDraw.Draw(frame)

        for particle in emitter.particles:
            if particle.life <= 0:
                continue

            # Calculate alpha based on life
            life_ratio = particle.life / emitter.lifetime
            alpha = int(particle.color[3] * life_ratio)
            color = (*particle.color[:3], alpha)

            # Draw particle
            x, y = int(particle.x), int(particle.y)
            size = max(1, int(particle.size * life_ratio))

            draw.ellipse(
                [x - size, y - size, x + size, y + size],
                fill=color
            )

        return frame

    def _render_foreground(self, frame: Image.Image, dt: float) -> Image.Image:
        """Render foreground layers."""
        # Foreground layers from scene
        for layer in self.scene.layers:
            if layer.z_index >= 100 and layer.visible:  # Foreground layers
                if layer.image:
                    layer_img = Image.open(layer.image).convert('RGBA')
                    pos = (int(layer.position[0]), int(layer.position[1]))
                    frame.paste(layer_img, pos, layer_img)

        return frame

    def render_video(self, output_path: str, duration: float,
                     on_progress: Optional[Callable[[RenderProgress], None]] = None) -> bool:
        """Render the scene to a video file.

        Args:
            output_path: Output video file path
            duration: Video duration in seconds
            on_progress: Progress callback

        Returns:
            True if successful
        """
        self.on_progress = on_progress
        total_frames = int(duration * self.settings.fps)
        dt = 1.0 / self.settings.fps

        # Create temp directory for frames
        self.temp_dir = Path(tempfile.mkdtemp(prefix='animation_'))

        try:
            # Render all frames
            progress = RenderProgress(total_frames=total_frames, stage='rendering')

            for frame_num in range(total_frames):
                progress.current_frame = frame_num
                progress.percent = frame_num / total_frames * 50  # First 50% is rendering
                progress.stage = 'rendering'

                if self.on_progress:
                    self.on_progress(progress)

                # Render frame
                frame = self.render_frame(frame_num, dt)

                # Save frame
                frame_path = self.temp_dir / f'frame_{frame_num:06d}.png'
                frame.save(frame_path)

                self.time += dt
                self.frame = frame_num

            # Encode video with FFmpeg
            progress.stage = 'encoding'
            progress.percent = 50

            if self.on_progress:
                self.on_progress(progress)

            success = self._encode_video(output_path, total_frames)

            progress.percent = 100
            progress.stage = 'complete'

            if self.on_progress:
                self.on_progress(progress)

            return success

        finally:
            # Cleanup temp files
            if self.temp_dir and self.temp_dir.exists():
                shutil.rmtree(self.temp_dir)

    def _encode_video(self, output_path: str, total_frames: int) -> bool:
        """Encode frames to video using FFmpeg."""
        if not self.temp_dir:
            return False

        frame_pattern = self.temp_dir / 'frame_%06d.png'

        cmd = [
            'ffmpeg',
            '-y',  # Overwrite output
            '-framerate', str(self.settings.fps),
            '-i', str(frame_pattern),
            '-c:v', self.settings.codec,
            '-crf', str(self.settings.get_crf()),
            '-pix_fmt', 'yuv420p',
            '-movflags', '+faststart',
            output_path
        ]

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            return True
        except subprocess.CalledProcessError as e:
            print(f"FFmpeg error: {e.stderr}")
            return False
        except FileNotFoundError:
            print("FFmpeg not found. Please install FFmpeg.")
            return False


class QuickRenderer:
    """Simplified renderer for quick tests."""

    def __init__(self, width: int = 800, height: int = 600, fps: int = 30):
        self.width = width
        self.height = height
        self.fps = fps
        self.frame_callbacks: list[Callable[[Image.Image, float, int], None]] = []

    def on_frame(self, callback: Callable[[Image.Image, float, int], None]) -> None:
        """Register a frame rendering callback.

        Callback signature: (frame_image, time, frame_number) -> None
        """
        self.frame_callbacks.append(callback)

    def render_frames(self, duration: float) -> list[Image.Image]:
        """Render frames and return as list."""
        frames = []
        total_frames = int(duration * self.fps)
        dt = 1.0 / self.fps

        for frame_num in range(total_frames):
            time = frame_num * dt
            frame = Image.new('RGBA', (self.width, self.height), (40, 40, 50, 255))

            for callback in self.frame_callbacks:
                callback(frame, time, frame_num)

            frames.append(frame)

        return frames

    def render_gif(self, output_path: str, duration: float,
                   optimize: bool = True) -> bool:
        """Render to animated GIF."""
        frames = self.render_frames(duration)

        if not frames:
            return False

        # Convert to RGB for GIF
        rgb_frames = [f.convert('RGB') for f in frames]

        frame_duration = int(1000 / self.fps)  # ms per frame

        rgb_frames[0].save(
            output_path,
            save_all=True,
            append_images=rgb_frames[1:],
            duration=frame_duration,
            loop=0,
            optimize=optimize
        )

        return True

    def render_video(self, output_path: str, duration: float) -> bool:
        """Render to video file."""
        frames = self.render_frames(duration)

        if not frames:
            return False

        # Save frames to temp dir
        temp_dir = Path(tempfile.mkdtemp(prefix='quick_render_'))

        try:
            for i, frame in enumerate(frames):
                frame.save(temp_dir / f'frame_{i:06d}.png')

            # Encode with FFmpeg
            cmd = [
                'ffmpeg',
                '-y',
                '-framerate', str(self.fps),
                '-i', str(temp_dir / 'frame_%06d.png'),
                '-c:v', 'libx264',
                '-crf', '23',
                '-pix_fmt', 'yuv420p',
                output_path
            ]

            result = subprocess.run(cmd, capture_output=True)
            return result.returncode == 0

        finally:
            shutil.rmtree(temp_dir)


def render_test_animation(output_path: str = 'test_animation.gif',
                          duration: float = 2.0) -> None:
    """Render a simple test animation."""
    import math

    renderer = QuickRenderer(400, 300, fps=24)

    def draw_frame(frame: Image.Image, time: float, frame_num: int):
        draw = ImageDraw.Draw(frame)

        # Bouncing ball
        x = 200 + math.sin(time * 3) * 150
        y = 150 + math.sin(time * 5) * 100

        # Trail
        for i in range(5):
            t = time - i * 0.05
            tx = 200 + math.sin(t * 3) * 150
            ty = 150 + math.sin(t * 5) * 100
            alpha = 255 - i * 50
            draw.ellipse(
                [tx - 15, ty - 15, tx + 15, ty + 15],
                fill=(100, 150, 255, alpha)
            )

        # Main ball
        draw.ellipse(
            [x - 20, y - 20, x + 20, y + 20],
            fill=(100, 200, 255, 255)
        )

        # Highlight
        draw.ellipse(
            [x - 10, y - 12, x - 4, y - 6],
            fill=(200, 230, 255, 255)
        )

    renderer.on_frame(draw_frame)

    if output_path.endswith('.gif'):
        renderer.render_gif(output_path, duration)
    else:
        renderer.render_video(output_path, duration)

    print(f"Test animation saved to: {output_path}")
