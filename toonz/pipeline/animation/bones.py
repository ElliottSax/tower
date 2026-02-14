"""Skeletal animation system with inverse kinematics.

Provides bone-based character rigging with:
- Hierarchical bone structure
- Forward and inverse kinematics (FABRIK algorithm)
- Bone constraints (angle limits, length)
- Mesh deformation via bone weights
"""

import math
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Callable
from .keyframes import KeyframeTrack, AnimationClip, EasingType


@dataclass
class Vec2:
    """2D vector for bone calculations."""
    x: float = 0.0
    y: float = 0.0

    def __add__(self, other: "Vec2") -> "Vec2":
        return Vec2(self.x + other.x, self.y + other.y)

    def __sub__(self, other: "Vec2") -> "Vec2":
        return Vec2(self.x - other.x, self.y - other.y)

    def __mul__(self, scalar: float) -> "Vec2":
        return Vec2(self.x * scalar, self.y * scalar)

    def __rmul__(self, scalar: float) -> "Vec2":
        return self.__mul__(scalar)

    def magnitude(self) -> float:
        return math.sqrt(self.x * self.x + self.y * self.y)

    def normalized(self) -> "Vec2":
        mag = self.magnitude()
        if mag == 0:
            return Vec2(0, 0)
        return Vec2(self.x / mag, self.y / mag)

    def angle(self) -> float:
        """Get angle in radians from positive x-axis."""
        return math.atan2(self.y, self.x)

    def rotate(self, angle: float) -> "Vec2":
        """Rotate vector by angle in radians."""
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        return Vec2(
            self.x * cos_a - self.y * sin_a,
            self.x * sin_a + self.y * cos_a
        )

    def distance_to(self, other: "Vec2") -> float:
        return (self - other).magnitude()

    def lerp(self, other: "Vec2", t: float) -> "Vec2":
        """Linear interpolation between vectors."""
        return Vec2(
            self.x + (other.x - self.x) * t,
            self.y + (other.y - self.y) * t
        )

    def to_tuple(self) -> Tuple[float, float]:
        return (self.x, self.y)

    @staticmethod
    def from_tuple(t: Tuple[float, float]) -> "Vec2":
        return Vec2(t[0], t[1])

    @staticmethod
    def from_angle(angle: float, length: float = 1.0) -> "Vec2":
        """Create vector from angle (radians) and length."""
        return Vec2(math.cos(angle) * length, math.sin(angle) * length)


@dataclass
class BoneConstraint:
    """Constraints for bone rotation/position."""
    min_angle: float = -math.pi  # Minimum rotation in radians
    max_angle: float = math.pi   # Maximum rotation in radians
    stiffness: float = 1.0       # How resistant to movement (0-1)

    def clamp_angle(self, angle: float) -> float:
        """Clamp angle to constraint limits."""
        # Normalize to -pi to pi
        while angle > math.pi:
            angle -= 2 * math.pi
        while angle < -math.pi:
            angle += 2 * math.pi
        return max(self.min_angle, min(self.max_angle, angle))


@dataclass
class Bone:
    """A single bone in a skeleton.

    Bones form a hierarchical tree structure where each bone's transform
    is relative to its parent.
    """
    name: str
    length: float = 50.0
    angle: float = 0.0  # Local rotation in radians
    parent: Optional["Bone"] = None
    constraint: Optional[BoneConstraint] = None

    # Child bones
    children: List["Bone"] = field(default_factory=list)

    # Visual properties
    visible: bool = True
    color: Tuple[int, int, int] = (255, 255, 255)
    sprite_path: Optional[str] = None
    sprite_offset: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    sprite_rotation: float = 0.0

    # Calculated world position (updated by skeleton)
    _world_start: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    _world_end: Vec2 = field(default_factory=lambda: Vec2(0, 0))
    _world_angle: float = 0.0

    def add_child(self, child: "Bone") -> "Bone":
        """Add a child bone."""
        child.parent = self
        self.children.append(child)
        return child

    def get_world_angle(self) -> float:
        """Get absolute world angle."""
        if self.parent:
            return self.parent.get_world_angle() + self.angle
        return self.angle

    def get_world_start(self) -> Vec2:
        """Get world position of bone start."""
        return self._world_start

    def get_world_end(self) -> Vec2:
        """Get world position of bone end."""
        return self._world_end

    def set_angle(self, angle: float, apply_constraints: bool = True) -> None:
        """Set bone angle, optionally applying constraints."""
        if apply_constraints and self.constraint:
            angle = self.constraint.clamp_angle(angle)
        self.angle = angle

    def rotate(self, delta: float, apply_constraints: bool = True) -> None:
        """Rotate bone by delta radians."""
        self.set_angle(self.angle + delta, apply_constraints)


class Skeleton:
    """A complete skeleton with bones and IK chains.

    Usage:
        skeleton = Skeleton("character")

        # Build bone hierarchy
        root = skeleton.add_bone("root", length=0)
        spine = skeleton.add_bone("spine", length=100, parent=root)
        head = skeleton.add_bone("head", length=50, parent=spine)

        # Create IK chain for arm
        shoulder = skeleton.add_bone("shoulder", length=60, parent=spine)
        elbow = skeleton.add_bone("elbow", length=50, parent=shoulder)
        hand = skeleton.add_bone("hand", length=30, parent=elbow)
        skeleton.create_ik_chain("right_arm", ["shoulder", "elbow", "hand"])

        # Animate
        skeleton.solve_ik("right_arm", target=(300, 200))
        skeleton.update()
    """

    def __init__(self, name: str, root_position: Vec2 = None):
        """Initialize skeleton.

        Args:
            name: Skeleton name
            root_position: World position of skeleton root
        """
        self.name = name
        self.position = root_position or Vec2(0, 0)
        self.rotation = 0.0  # Global rotation
        self.scale = 1.0

        self.bones: Dict[str, Bone] = {}
        self.root_bones: List[Bone] = []
        self.ik_chains: Dict[str, List[str]] = {}  # chain_name -> bone names

        # Animation
        self.animation: Optional[AnimationClip] = None

    def add_bone(
        self,
        name: str,
        length: float = 50.0,
        angle: float = 0.0,
        parent: Bone = None,
        constraint: BoneConstraint = None,
        **kwargs
    ) -> Bone:
        """Add a bone to the skeleton.

        Args:
            name: Unique bone name
            length: Bone length in pixels
            angle: Initial angle in radians
            parent: Parent bone (or None for root bone)
            constraint: Optional angle constraints
            **kwargs: Additional bone properties

        Returns:
            The created bone
        """
        bone = Bone(
            name=name,
            length=length,
            angle=angle,
            constraint=constraint,
            **kwargs
        )

        if parent:
            parent.add_child(bone)
        else:
            self.root_bones.append(bone)

        self.bones[name] = bone
        return bone

    def get_bone(self, name: str) -> Optional[Bone]:
        """Get bone by name."""
        return self.bones.get(name)

    def create_ik_chain(self, name: str, bone_names: List[str]) -> None:
        """Create an IK chain from a list of bones.

        The chain goes from root to tip (first to last bone in list).

        Args:
            name: Chain name for referencing
            bone_names: List of bone names in order
        """
        # Validate bones exist and are connected
        for i, bone_name in enumerate(bone_names):
            if bone_name not in self.bones:
                raise ValueError(f"Bone '{bone_name}' not found")
            if i > 0:
                bone = self.bones[bone_name]
                parent_name = bone_names[i - 1]
                if bone.parent is None or bone.parent.name != parent_name:
                    raise ValueError(
                        f"Bone '{bone_name}' is not a child of '{parent_name}'"
                    )

        self.ik_chains[name] = bone_names

    def update(self) -> None:
        """Update all bone world positions."""
        for root in self.root_bones:
            self._update_bone_recursive(root, self.position, self.rotation)

    def _update_bone_recursive(
        self,
        bone: Bone,
        parent_end: Vec2,
        parent_world_angle: float
    ) -> None:
        """Recursively update bone positions."""
        bone._world_start = parent_end
        bone._world_angle = parent_world_angle + bone.angle

        # Calculate end position
        direction = Vec2.from_angle(bone._world_angle, bone.length * self.scale)
        bone._world_end = bone._world_start + direction

        # Update children
        for child in bone.children:
            self._update_bone_recursive(child, bone._world_end, bone._world_angle)

    def solve_ik(
        self,
        chain_name: str,
        target: Tuple[float, float],
        iterations: int = 10,
        tolerance: float = 0.5
    ) -> bool:
        """Solve inverse kinematics for a chain using FABRIK algorithm.

        Args:
            chain_name: Name of IK chain to solve
            target: Target position (x, y)
            iterations: Maximum iterations
            tolerance: Distance tolerance to target

        Returns:
            True if solved within tolerance
        """
        if chain_name not in self.ik_chains:
            return False

        bone_names = self.ik_chains[chain_name]
        if len(bone_names) < 2:
            return False

        target_vec = Vec2.from_tuple(target)

        # Get chain bones
        bones = [self.bones[name] for name in bone_names]

        # Ensure positions are up to date
        self.update()

        # Get joint positions
        positions = [bones[0]._world_start]
        for bone in bones:
            positions.append(bone._world_end)

        # Check if target is reachable
        total_length = sum(b.length * self.scale for b in bones)
        root_to_target = target_vec.distance_to(positions[0])

        if root_to_target > total_length:
            # Target unreachable, stretch towards it
            direction = (target_vec - positions[0]).normalized()
            for i, bone in enumerate(bones):
                positions[i + 1] = positions[i] + direction * (bone.length * self.scale)
        else:
            # FABRIK algorithm
            for _ in range(iterations):
                # Check if close enough
                if positions[-1].distance_to(target_vec) < tolerance:
                    break

                # Backward pass (from end to root)
                positions[-1] = target_vec
                for i in range(len(bones) - 1, -1, -1):
                    bone = bones[i]
                    direction = (positions[i] - positions[i + 1]).normalized()
                    positions[i] = positions[i + 1] + direction * (bone.length * self.scale)

                # Forward pass (from root to end)
                positions[0] = bones[0]._world_start
                for i, bone in enumerate(bones):
                    direction = (positions[i + 1] - positions[i]).normalized()
                    positions[i + 1] = positions[i] + direction * (bone.length * self.scale)

        # Apply new angles to bones
        for i, bone in enumerate(bones):
            # Calculate new angle
            direction = positions[i + 1] - positions[i]
            new_world_angle = direction.angle()

            # Convert to local angle
            if bone.parent:
                new_local_angle = new_world_angle - bone.parent._world_angle
            else:
                new_local_angle = new_world_angle - self.rotation

            bone.set_angle(new_local_angle)

        # Update all positions
        self.update()

        return positions[-1].distance_to(target_vec) < tolerance

    def apply_animation(self, frame: int) -> None:
        """Apply animation clip values to skeleton at frame.

        Tracks should be named as "bone_name.property":
        - "spine.angle": Bone rotation
        - "root.position": Root position override
        """
        if not self.animation:
            return

        # Apply root position
        pos = self.animation.get_value("position", frame)
        if pos:
            self.position = Vec2.from_tuple(pos) if isinstance(pos, tuple) else pos

        rot = self.animation.get_value("rotation", frame)
        if rot is not None:
            self.rotation = rot

        # Apply bone angles
        for bone_name, bone in self.bones.items():
            angle = self.animation.get_value(f"{bone_name}.angle", frame)
            if angle is not None:
                bone.angle = angle

        self.update()

    def to_dict(self) -> dict:
        """Serialize skeleton to dictionary."""
        def bone_to_dict(bone: Bone) -> dict:
            return {
                "name": bone.name,
                "length": bone.length,
                "angle": bone.angle,
                "visible": bone.visible,
                "color": list(bone.color),
                "sprite_path": bone.sprite_path,
                "sprite_offset": bone.sprite_offset.to_tuple(),
                "sprite_rotation": bone.sprite_rotation,
                "constraint": {
                    "min_angle": bone.constraint.min_angle,
                    "max_angle": bone.constraint.max_angle,
                    "stiffness": bone.constraint.stiffness
                } if bone.constraint else None,
                "children": [bone_to_dict(c) for c in bone.children]
            }

        return {
            "name": self.name,
            "position": self.position.to_tuple(),
            "rotation": self.rotation,
            "scale": self.scale,
            "bones": [bone_to_dict(b) for b in self.root_bones],
            "ik_chains": self.ik_chains
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Skeleton":
        """Deserialize skeleton from dictionary."""
        skeleton = cls(
            name=data["name"],
            root_position=Vec2.from_tuple(data.get("position", (0, 0)))
        )
        skeleton.rotation = data.get("rotation", 0.0)
        skeleton.scale = data.get("scale", 1.0)

        def add_bones_recursive(bone_data: dict, parent: Bone = None):
            constraint = None
            if bone_data.get("constraint"):
                c = bone_data["constraint"]
                constraint = BoneConstraint(
                    min_angle=c["min_angle"],
                    max_angle=c["max_angle"],
                    stiffness=c.get("stiffness", 1.0)
                )

            bone = skeleton.add_bone(
                name=bone_data["name"],
                length=bone_data["length"],
                angle=bone_data.get("angle", 0.0),
                parent=parent,
                constraint=constraint,
                visible=bone_data.get("visible", True),
                color=tuple(bone_data.get("color", [255, 255, 255])),
                sprite_path=bone_data.get("sprite_path"),
            )
            bone.sprite_offset = Vec2.from_tuple(
                bone_data.get("sprite_offset", (0, 0))
            )
            bone.sprite_rotation = bone_data.get("sprite_rotation", 0.0)

            for child_data in bone_data.get("children", []):
                add_bones_recursive(child_data, bone)

        for bone_data in data.get("bones", []):
            add_bones_recursive(bone_data)

        for chain_name, bone_names in data.get("ik_chains", {}).items():
            skeleton.ik_chains[chain_name] = bone_names

        skeleton.update()
        return skeleton


# Pre-built skeleton templates

def create_humanoid_skeleton(
    name: str = "humanoid",
    body_height: float = 200,
    arm_length: float = 120,
    leg_length: float = 140
) -> Skeleton:
    """Create a basic humanoid skeleton.

    Structure:
        root
        └── spine (torso)
            ├── head
            ├── left_shoulder
            │   ├── left_upper_arm
            │   └── left_lower_arm
            │       └── left_hand
            ├── right_shoulder
            │   ├── right_upper_arm
            │   └── right_lower_arm
            │       └── right_hand
            └── hips
                ├── left_upper_leg
                │   └── left_lower_leg
                │       └── left_foot
                └── right_upper_leg
                    └── right_lower_leg
                        └── right_foot
    """
    skeleton = Skeleton(name)

    # Proportions
    spine_len = body_height * 0.35
    head_len = body_height * 0.15
    shoulder_offset = body_height * 0.05
    upper_arm = arm_length * 0.5
    lower_arm = arm_length * 0.5
    hand_len = arm_length * 0.15
    upper_leg = leg_length * 0.5
    lower_leg = leg_length * 0.5
    foot_len = leg_length * 0.1

    # Build skeleton
    root = skeleton.add_bone("root", length=0)

    # Spine and head (pointing up: -pi/2)
    spine = skeleton.add_bone("spine", length=spine_len, angle=-math.pi/2, parent=root)
    head = skeleton.add_bone("head", length=head_len, angle=0, parent=spine)

    # Arms (left arm angle points left, right points right)
    left_shoulder = skeleton.add_bone("left_shoulder", length=shoulder_offset,
                                       angle=math.pi/2, parent=spine)
    left_upper_arm = skeleton.add_bone("left_upper_arm", length=upper_arm,
                                        angle=math.pi/2, parent=left_shoulder,
                                        constraint=BoneConstraint(-math.pi, math.pi))
    left_lower_arm = skeleton.add_bone("left_lower_arm", length=lower_arm,
                                        angle=0, parent=left_upper_arm,
                                        constraint=BoneConstraint(-2.5, 0))  # Elbow bends inward
    left_hand = skeleton.add_bone("left_hand", length=hand_len,
                                   angle=0, parent=left_lower_arm)

    right_shoulder = skeleton.add_bone("right_shoulder", length=shoulder_offset,
                                        angle=-math.pi/2, parent=spine)
    right_upper_arm = skeleton.add_bone("right_upper_arm", length=upper_arm,
                                         angle=-math.pi/2, parent=right_shoulder,
                                         constraint=BoneConstraint(-math.pi, math.pi))
    right_lower_arm = skeleton.add_bone("right_lower_arm", length=lower_arm,
                                         angle=0, parent=right_upper_arm,
                                         constraint=BoneConstraint(0, 2.5))
    right_hand = skeleton.add_bone("right_hand", length=hand_len,
                                    angle=0, parent=right_lower_arm)

    # Hips and legs
    hips = skeleton.add_bone("hips", length=0, angle=math.pi, parent=root)

    left_upper_leg = skeleton.add_bone("left_upper_leg", length=upper_leg,
                                        angle=math.pi/6, parent=hips,
                                        constraint=BoneConstraint(-0.5, math.pi/2))
    left_lower_leg = skeleton.add_bone("left_lower_leg", length=lower_leg,
                                        angle=0, parent=left_upper_leg,
                                        constraint=BoneConstraint(0, 2.5))
    left_foot = skeleton.add_bone("left_foot", length=foot_len,
                                   angle=-math.pi/2, parent=left_lower_leg)

    right_upper_leg = skeleton.add_bone("right_upper_leg", length=upper_leg,
                                         angle=-math.pi/6, parent=hips,
                                         constraint=BoneConstraint(-math.pi/2, 0.5))
    right_lower_leg = skeleton.add_bone("right_lower_leg", length=lower_leg,
                                         angle=0, parent=right_upper_leg,
                                         constraint=BoneConstraint(-2.5, 0))
    right_foot = skeleton.add_bone("right_foot", length=foot_len,
                                    angle=math.pi/2, parent=right_lower_leg)

    # Create IK chains
    skeleton.create_ik_chain("left_arm",
                             ["left_upper_arm", "left_lower_arm", "left_hand"])
    skeleton.create_ik_chain("right_arm",
                             ["right_upper_arm", "right_lower_arm", "right_hand"])
    skeleton.create_ik_chain("left_leg",
                             ["left_upper_leg", "left_lower_leg", "left_foot"])
    skeleton.create_ik_chain("right_leg",
                             ["right_upper_leg", "right_lower_leg", "right_foot"])

    skeleton.update()
    return skeleton


def create_arm_skeleton(name: str = "arm", length: float = 150) -> Skeleton:
    """Create a simple 3-bone arm skeleton for testing."""
    skeleton = Skeleton(name)

    upper = length * 0.4
    lower = length * 0.35
    hand = length * 0.25

    root = skeleton.add_bone("shoulder", length=upper, angle=0)
    elbow = skeleton.add_bone("elbow", length=lower, angle=0, parent=root,
                               constraint=BoneConstraint(-math.pi, 0))
    wrist = skeleton.add_bone("wrist", length=hand, angle=0, parent=elbow)

    skeleton.create_ik_chain("arm", ["shoulder", "elbow", "wrist"])
    skeleton.update()

    return skeleton


def solve_two_bone_ik(
    root_pos: Tuple[float, float],
    target_pos: Tuple[float, float],
    bone1_length: float,
    bone2_length: float,
    pole_vector: Optional[Tuple[float, float]] = None,
    bend_direction: float = 1.0
) -> Tuple[Tuple[float, float], float, float]:
    """Solve two-bone IK with pole vector support.

    This implements the analytical two-bone IK solution using the law of cosines,
    with pole vector support for controlling the bend plane direction.

    Based on techniques from:
    - littlepolygon.com procedural animation blog
    - ozz-animation library
    - Ryan Juckett's analytic 2D IK

    Args:
        root_pos: Start position (shoulder/hip)
        target_pos: End effector target position (hand/foot)
        bone1_length: Length of first bone (upper arm/thigh)
        bone2_length: Length of second bone (forearm/calf)
        pole_vector: Optional direction hint for middle joint (elbow/knee)
                     If None, defaults to bending based on bend_direction
        bend_direction: 1.0 for forward/outward bend, -1.0 for backward/inward

    Returns:
        Tuple of:
        - mid_pos: Position of middle joint (elbow/knee)
        - bone1_angle: World angle of first bone in radians
        - bone2_angle: World angle of second bone in radians
    """
    root = Vec2.from_tuple(root_pos)
    target = Vec2.from_tuple(target_pos)

    # Vector from root to target
    to_target = target - root
    dist = to_target.magnitude()

    # Clamp distance to valid range
    max_reach = bone1_length + bone2_length - 0.001  # Small epsilon for numerical stability
    min_reach = abs(bone1_length - bone2_length) + 0.001

    if dist < min_reach:
        dist = min_reach
    elif dist > max_reach:
        dist = max_reach

    # Law of cosines to find angles
    # For triangle with sides: bone1_length, bone2_length, dist
    # cos(angle_at_root) = (bone1^2 + dist^2 - bone2^2) / (2 * bone1 * dist)
    cos_angle1 = (bone1_length**2 + dist**2 - bone2_length**2) / (2 * bone1_length * dist)
    cos_angle1 = max(-1.0, min(1.0, cos_angle1))
    angle1_offset = math.acos(cos_angle1)

    # Angle from root to target
    angle_to_target = to_target.angle()

    # Calculate bend direction
    if pole_vector is not None:
        # Use pole vector to determine bend direction
        pole = Vec2.from_tuple(pole_vector)
        # Project pole onto plane perpendicular to root-target line
        to_target_norm = to_target.normalized()

        # In 2D, the perpendicular is simply (-y, x) or (y, -x)
        perp = Vec2(-to_target_norm.y, to_target_norm.x)

        # Dot product with pole to determine which side
        pole_relative = pole - root
        dot = pole_relative.x * perp.x + pole_relative.y * perp.y

        bend_direction = 1.0 if dot >= 0 else -1.0

    # First bone angle (root to mid)
    bone1_angle = angle_to_target + angle1_offset * bend_direction

    # Calculate middle joint position
    mid_pos = root + Vec2.from_angle(bone1_angle, bone1_length)

    # Second bone angle (mid to target)
    to_end = target - mid_pos
    bone2_angle = to_end.angle()

    return (mid_pos.to_tuple(), bone1_angle, bone2_angle)


def solve_leg_ik(
    hip_pos: Tuple[float, float],
    foot_target: Tuple[float, float],
    thigh_length: float,
    calf_length: float,
    knee_forward: bool = True
) -> Tuple[Tuple[float, float], float, float]:
    """Convenience function for leg IK.

    Args:
        hip_pos: Hip joint position
        foot_target: Target foot position
        thigh_length: Length of thigh bone
        calf_length: Length of calf bone
        knee_forward: If True, knee bends forward (natural walking)
                      If False, knee bends backward (sitting)

    Returns:
        Tuple of (knee_pos, thigh_angle, calf_angle)
    """
    # For legs, the pole vector is typically in front of the leg
    # to make the knee bend forward
    hip = Vec2.from_tuple(hip_pos)
    target = Vec2.from_tuple(foot_target)

    # Pole vector: point in front of the hip at mid-height
    mid_y = (hip.y + target.y) / 2
    pole_x = hip.x + (100 if knee_forward else -100)  # In front or behind
    pole = (pole_x, mid_y)

    return solve_two_bone_ik(
        hip_pos, foot_target,
        thigh_length, calf_length,
        pole_vector=pole,
        bend_direction=1.0 if knee_forward else -1.0
    )


def solve_arm_ik(
    shoulder_pos: Tuple[float, float],
    hand_target: Tuple[float, float],
    upper_arm_length: float,
    forearm_length: float,
    elbow_out: bool = True,
    side: int = 1  # 1 for right arm, -1 for left arm
) -> Tuple[Tuple[float, float], float, float]:
    """Convenience function for arm IK.

    Args:
        shoulder_pos: Shoulder joint position
        hand_target: Target hand position
        upper_arm_length: Length of upper arm
        forearm_length: Length of forearm
        elbow_out: If True, elbow points outward (natural)
                   If False, elbow points inward
        side: 1 for right arm, -1 for left arm

    Returns:
        Tuple of (elbow_pos, upper_arm_angle, forearm_angle)
    """
    shoulder = Vec2.from_tuple(shoulder_pos)
    target = Vec2.from_tuple(hand_target)

    # For arms, pole vector typically points outward and slightly back
    mid_y = (shoulder.y + target.y) / 2
    pole_x = shoulder.x + side * (80 if elbow_out else -80)
    pole_y = mid_y - 50  # Slightly above
    pole = (pole_x, pole_y)

    return solve_two_bone_ik(
        shoulder_pos, hand_target,
        upper_arm_length, forearm_length,
        pole_vector=pole,
        bend_direction=side if elbow_out else -side
    )
