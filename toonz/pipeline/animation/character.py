"""Character definition and rigging for animation pipeline."""

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from PIL import Image

from ..lipsync.rhubarb import LipSyncData


@dataclass
class LayerDefinition:
    """Definition of a character layer (body part)."""
    name: str
    image_path: str
    anchor: Tuple[float, float] = (0.5, 0.5)  # Normalized anchor point
    z_order: int = 0
    visible: bool = True
    opacity: float = 1.0

    def get_anchor_pixels(self, width: int, height: int) -> Tuple[int, int]:
        """Get anchor point in pixel coordinates."""
        return (int(self.anchor[0] * width), int(self.anchor[1] * height))


@dataclass
class CharacterRig:
    """Character rig definition with all assets and layers.

    A rig defines the structure of a character:
    - Body layers (torso, arms, legs, head, etc.)
    - Mouth shapes for lip sync (A-X)
    - Eye states (open, half, closed, etc.)
    - Anchor points for positioning
    """
    name: str
    base_path: str = ""

    # Layer definitions
    body_layers: Dict[str, LayerDefinition] = field(default_factory=dict)
    mouth_shapes: Dict[str, str] = field(default_factory=dict)  # shape_code -> image_path
    eye_states: Dict[str, str] = field(default_factory=dict)    # state_name -> image_path

    # Positioning
    mouth_offset: Tuple[int, int] = (0, 0)  # Offset from body anchor
    eye_offset: Tuple[int, int] = (0, 0)

    # Default state
    default_pose: str = "idle"
    default_mouth: str = "X"
    default_eyes: str = "open"

    def get_mouth_path(self, shape: str) -> Optional[str]:
        """Get full path to mouth shape image."""
        if shape not in self.mouth_shapes:
            # Fall back to rest position
            shape = "X" if "X" in self.mouth_shapes else "A"

        rel_path = self.mouth_shapes.get(shape)
        if rel_path and self.base_path:
            return str(Path(self.base_path) / rel_path)
        return rel_path

    def get_eye_path(self, state: str) -> Optional[str]:
        """Get full path to eye state image."""
        if state not in self.eye_states:
            state = self.default_eyes

        rel_path = self.eye_states.get(state)
        if rel_path and self.base_path:
            return str(Path(self.base_path) / rel_path)
        return rel_path

    def get_body_layer_path(self, layer_name: str) -> Optional[str]:
        """Get full path to body layer image."""
        layer = self.body_layers.get(layer_name)
        if layer:
            if self.base_path:
                return str(Path(self.base_path) / layer.image_path)
            return layer.image_path
        return None

    @classmethod
    def load(cls, path: str) -> "CharacterRig":
        """Load character rig from JSON file."""
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Parse body layers
        body_layers = {}
        for name, layer_data in data.get('body_layers', {}).items():
            if isinstance(layer_data, str):
                # Simple format: just the path
                body_layers[name] = LayerDefinition(name=name, image_path=layer_data)
            else:
                # Full format with all properties
                body_layers[name] = LayerDefinition(
                    name=name,
                    image_path=layer_data.get('path', ''),
                    anchor=tuple(layer_data.get('anchor', [0.5, 0.5])),
                    z_order=layer_data.get('z_order', 0),
                    visible=layer_data.get('visible', True),
                    opacity=layer_data.get('opacity', 1.0)
                )

        base_path = str(Path(path).parent)

        return cls(
            name=data.get('name', 'unnamed'),
            base_path=base_path,
            body_layers=body_layers,
            mouth_shapes=data.get('mouth_shapes', {}),
            eye_states=data.get('eye_states', {}),
            mouth_offset=tuple(data.get('mouth_offset', [0, 0])),
            eye_offset=tuple(data.get('eye_offset', [0, 0])),
            default_pose=data.get('default_pose', 'idle'),
            default_mouth=data.get('default_mouth', 'X'),
            default_eyes=data.get('default_eyes', 'open')
        )

    def save(self, path: str) -> None:
        """Save character rig to JSON file."""
        data = {
            'name': self.name,
            'body_layers': {
                name: {
                    'path': layer.image_path,
                    'anchor': list(layer.anchor),
                    'z_order': layer.z_order,
                    'visible': layer.visible,
                    'opacity': layer.opacity
                }
                for name, layer in self.body_layers.items()
            },
            'mouth_shapes': self.mouth_shapes,
            'eye_states': self.eye_states,
            'mouth_offset': list(self.mouth_offset),
            'eye_offset': list(self.eye_offset),
            'default_pose': self.default_pose,
            'default_mouth': self.default_mouth,
            'default_eyes': self.default_eyes
        }

        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)

    @classmethod
    def create_from_directory(cls, path: str, name: str = None) -> "CharacterRig":
        """Auto-detect character rig from directory structure.

        Expected structure:
            character_dir/
            ├── body/
            │   ├── idle.png
            │   └── ...
            ├── mouth/
            │   ├── A.png, B.png, C.png, D.png, E.png, F.png
            │   └── G.png, H.png, X.png (optional)
            └── eyes/
                ├── open.png
                ├── half.png
                └── closed.png
        """
        path = Path(path)
        name = name or path.name

        rig = cls(name=name, base_path=str(path))

        # Scan body directory
        body_dir = path / "body"
        if body_dir.exists():
            for img_path in body_dir.glob("*.png"):
                layer_name = img_path.stem
                rig.body_layers[layer_name] = LayerDefinition(
                    name=layer_name,
                    image_path=f"body/{img_path.name}"
                )

        # Scan mouth directory
        mouth_dir = path / "mouth"
        if mouth_dir.exists():
            for shape in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'X']:
                for ext in ['.png', '.PNG']:
                    img_path = mouth_dir / f"{shape}{ext}"
                    if img_path.exists():
                        rig.mouth_shapes[shape] = f"mouth/{img_path.name}"
                        break

        # Scan eyes directory
        eyes_dir = path / "eyes"
        if eyes_dir.exists():
            for img_path in eyes_dir.glob("*.png"):
                state_name = img_path.stem
                rig.eye_states[state_name] = f"eyes/{img_path.name}"

        return rig


class Character:
    """An animated character instance with current state.

    Usage:
        rig = CharacterRig.load("assets/characters/narrator/character.json")
        character = Character(rig)

        # Apply lip sync
        lipsync = rhubarb.analyze("audio.wav")
        character.apply_lipsync(lipsync, fps=30)

        # Get frame
        for frame in range(total_frames):
            mouth_shape = character.get_mouth_at_frame(frame)
            image = character.render_frame(frame)
    """

    def __init__(
        self,
        rig: CharacterRig,
        position: Tuple[int, int] = (0, 0),
        scale: float = 1.0,
        name: str = None
    ):
        """Initialize character instance.

        Args:
            rig: Character rig definition
            position: Position in scene (x, y)
            scale: Scale factor
            name: Instance name (defaults to rig name)
        """
        self.rig = rig
        self.name = name or rig.name
        self.position = position
        self.scale = scale

        # Current state
        self.current_pose = rig.default_pose
        self.current_mouth = rig.default_mouth
        self.current_eyes = rig.default_eyes
        self.opacity = 1.0
        self.visible = True

        # Animation data
        self.lipsync_data: Optional[LipSyncData] = None
        self.lipsync_fps: float = 30.0

        # Blink animation
        self.blink_frames: List[int] = []
        self.blink_duration: int = 3  # frames

        # Image cache
        self._image_cache: Dict[str, Image.Image] = {}

    def apply_lipsync(self, lipsync: LipSyncData, fps: float = 30.0) -> None:
        """Apply lip sync data to this character.

        Args:
            lipsync: LipSyncData from Rhubarb analysis
            fps: Frames per second for conversion
        """
        self.lipsync_data = lipsync
        self.lipsync_fps = fps
        # Set fps on lipsync data for frame-based lookups
        self.lipsync_data.fps = int(fps)

    def get_mouth_at_frame(self, frame: int) -> str:
        """Get mouth shape at a specific frame."""
        if self.lipsync_data:
            return self.lipsync_data.get_shape_at_frame(frame)
        return self.current_mouth

    def get_mouth_at_time(self, time: float) -> str:
        """Get mouth shape at a specific time."""
        if self.lipsync_data:
            return self.lipsync_data.get_shape_at_time(time)
        return self.current_mouth

    def add_blink(self, frame: int) -> None:
        """Add a blink at the specified frame."""
        self.blink_frames.append(frame)

    def add_random_blinks(self, total_frames: int, interval: Tuple[int, int] = (60, 180)) -> None:
        """Add random blinks throughout the animation.

        Args:
            total_frames: Total number of frames
            interval: Min and max frames between blinks
        """
        import random
        frame = random.randint(interval[0], interval[1])
        while frame < total_frames:
            self.blink_frames.append(frame)
            frame += random.randint(interval[0], interval[1])

    def get_eyes_at_frame(self, frame: int) -> str:
        """Get eye state at a specific frame (handles blinking)."""
        for blink_frame in self.blink_frames:
            if blink_frame <= frame < blink_frame + self.blink_duration:
                blink_progress = frame - blink_frame
                if blink_progress == 0:
                    return "half" if "half" in self.rig.eye_states else "closed"
                elif blink_progress == 1:
                    return "closed" if "closed" in self.rig.eye_states else "half"
                else:
                    return "half" if "half" in self.rig.eye_states else "open"
        return self.current_eyes

    def _load_image(self, path: str) -> Optional[Image.Image]:
        """Load and cache an image."""
        if path not in self._image_cache:
            try:
                self._image_cache[path] = Image.open(path).convert('RGBA')
            except (FileNotFoundError, IOError):
                return None
        return self._image_cache[path]

    def render_frame(self, frame: int, canvas_size: Tuple[int, int] = None) -> Image.Image:
        """Render character at a specific frame.

        Args:
            frame: Frame number
            canvas_size: Output canvas size (width, height)

        Returns:
            Composite image of character at this frame
        """
        # Get current states
        mouth_shape = self.get_mouth_at_frame(frame)
        eye_state = self.get_eyes_at_frame(frame)

        # Collect layers to render
        layers: List[Tuple[Image.Image, int, int, int]] = []  # (image, x, y, z_order)

        # Add body layers
        for layer_name, layer_def in sorted(
            self.rig.body_layers.items(),
            key=lambda x: x[1].z_order
        ):
            if not layer_def.visible:
                continue

            path = self.rig.get_body_layer_path(layer_name)
            if path:
                img = self._load_image(path)
                if img:
                    if self.scale != 1.0:
                        new_size = (int(img.width * self.scale), int(img.height * self.scale))
                        img = img.resize(new_size, Image.Resampling.LANCZOS)

                    x = self.position[0] - int(img.width * layer_def.anchor[0])
                    y = self.position[1] - int(img.height * layer_def.anchor[1])
                    layers.append((img, x, y, layer_def.z_order))

        # Add mouth
        mouth_path = self.rig.get_mouth_path(mouth_shape)
        if mouth_path:
            img = self._load_image(mouth_path)
            if img:
                if self.scale != 1.0:
                    new_size = (int(img.width * self.scale), int(img.height * self.scale))
                    img = img.resize(new_size, Image.Resampling.LANCZOS)

                x = self.position[0] + int(self.rig.mouth_offset[0] * self.scale) - img.width // 2
                y = self.position[1] + int(self.rig.mouth_offset[1] * self.scale) - img.height // 2
                layers.append((img, x, y, 100))  # Mouth on top of body

        # Add eyes
        eye_path = self.rig.get_eye_path(eye_state)
        if eye_path:
            img = self._load_image(eye_path)
            if img:
                if self.scale != 1.0:
                    new_size = (int(img.width * self.scale), int(img.height * self.scale))
                    img = img.resize(new_size, Image.Resampling.LANCZOS)

                x = self.position[0] + int(self.rig.eye_offset[0] * self.scale) - img.width // 2
                y = self.position[1] + int(self.rig.eye_offset[1] * self.scale) - img.height // 2
                layers.append((img, x, y, 101))  # Eyes on top of mouth

        # Determine canvas size if not provided
        if canvas_size is None:
            if layers:
                min_x = min(l[1] for l in layers)
                min_y = min(l[2] for l in layers)
                max_x = max(l[1] + l[0].width for l in layers)
                max_y = max(l[2] + l[0].height for l in layers)
                canvas_size = (max_x - min_x, max_y - min_y)
                # Adjust positions
                layers = [(img, x - min_x, y - min_y, z) for img, x, y, z in layers]
            else:
                canvas_size = (100, 100)

        # Create composite
        canvas = Image.new('RGBA', canvas_size, (0, 0, 0, 0))

        # Sort by z-order and composite
        for img, x, y, _ in sorted(layers, key=lambda l: l[3]):
            canvas.paste(img, (x, y), img)

        return canvas

    def clear_cache(self) -> None:
        """Clear the image cache."""
        self._image_cache.clear()
