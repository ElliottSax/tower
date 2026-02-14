"""Tests for animation/bones.py module."""

import math
import pytest
from unittest.mock import MagicMock, patch

from pipeline.animation.bones import (
    Vec2,
    BoneConstraint,
    Bone,
    Skeleton,
    create_humanoid_skeleton,
    create_arm_skeleton,
)
from pipeline.animation.keyframes import AnimationClip


# ============================================================================
# VEC2 TESTS
# ============================================================================

class TestVec2:
    """Tests for Vec2 dataclass."""

    def test_default_values(self):
        """Test default vector is origin."""
        v = Vec2()
        assert v.x == 0.0
        assert v.y == 0.0

    def test_custom_values(self):
        """Test vector with custom values."""
        v = Vec2(3.0, 4.0)
        assert v.x == 3.0
        assert v.y == 4.0

    def test_add(self):
        """Test vector addition."""
        v1 = Vec2(1, 2)
        v2 = Vec2(3, 4)
        result = v1 + v2
        assert result.x == 4
        assert result.y == 6

    def test_sub(self):
        """Test vector subtraction."""
        v1 = Vec2(5, 7)
        v2 = Vec2(2, 3)
        result = v1 - v2
        assert result.x == 3
        assert result.y == 4

    def test_mul(self):
        """Test scalar multiplication."""
        v = Vec2(2, 3)
        result = v * 2
        assert result.x == 4
        assert result.y == 6

    def test_rmul(self):
        """Test reverse scalar multiplication."""
        v = Vec2(2, 3)
        result = 2 * v
        assert result.x == 4
        assert result.y == 6

    def test_magnitude(self):
        """Test vector magnitude (3-4-5 triangle)."""
        v = Vec2(3, 4)
        assert v.magnitude() == 5.0

    def test_magnitude_zero(self):
        """Test zero vector magnitude."""
        v = Vec2(0, 0)
        assert v.magnitude() == 0.0

    def test_normalized(self):
        """Test vector normalization."""
        v = Vec2(3, 4)
        n = v.normalized()
        assert n.x == pytest.approx(0.6)
        assert n.y == pytest.approx(0.8)
        assert n.magnitude() == pytest.approx(1.0)

    def test_normalized_zero_vector(self):
        """Test normalizing zero vector returns zero."""
        v = Vec2(0, 0)
        n = v.normalized()
        assert n.x == 0
        assert n.y == 0

    def test_angle(self):
        """Test angle from x-axis."""
        # Pointing right
        assert Vec2(1, 0).angle() == pytest.approx(0)
        # Pointing up
        assert Vec2(0, 1).angle() == pytest.approx(math.pi / 2)
        # Pointing left
        assert Vec2(-1, 0).angle() == pytest.approx(math.pi)
        # Pointing down
        assert Vec2(0, -1).angle() == pytest.approx(-math.pi / 2)

    def test_rotate(self):
        """Test vector rotation."""
        v = Vec2(1, 0)
        # Rotate 90 degrees
        rotated = v.rotate(math.pi / 2)
        assert rotated.x == pytest.approx(0, abs=1e-10)
        assert rotated.y == pytest.approx(1)

    def test_rotate_180(self):
        """Test 180 degree rotation."""
        v = Vec2(1, 0)
        rotated = v.rotate(math.pi)
        assert rotated.x == pytest.approx(-1)
        assert rotated.y == pytest.approx(0, abs=1e-10)

    def test_distance_to(self):
        """Test distance between vectors."""
        v1 = Vec2(0, 0)
        v2 = Vec2(3, 4)
        assert v1.distance_to(v2) == 5.0

    def test_lerp_at_zero(self):
        """Test lerp at t=0."""
        v1 = Vec2(0, 0)
        v2 = Vec2(10, 10)
        result = v1.lerp(v2, 0)
        assert result.x == 0
        assert result.y == 0

    def test_lerp_at_one(self):
        """Test lerp at t=1."""
        v1 = Vec2(0, 0)
        v2 = Vec2(10, 10)
        result = v1.lerp(v2, 1)
        assert result.x == 10
        assert result.y == 10

    def test_lerp_at_half(self):
        """Test lerp at t=0.5."""
        v1 = Vec2(0, 0)
        v2 = Vec2(10, 10)
        result = v1.lerp(v2, 0.5)
        assert result.x == 5
        assert result.y == 5

    def test_to_tuple(self):
        """Test conversion to tuple."""
        v = Vec2(3, 4)
        assert v.to_tuple() == (3, 4)

    def test_from_tuple(self):
        """Test creation from tuple."""
        v = Vec2.from_tuple((3, 4))
        assert v.x == 3
        assert v.y == 4

    def test_from_angle(self):
        """Test creation from angle."""
        # Pointing right
        v = Vec2.from_angle(0, 5)
        assert v.x == pytest.approx(5)
        assert v.y == pytest.approx(0, abs=1e-10)

    def test_from_angle_with_length(self):
        """Test creation from angle with length."""
        v = Vec2.from_angle(math.pi / 2, 10)
        assert v.x == pytest.approx(0, abs=1e-10)
        assert v.y == pytest.approx(10)


# ============================================================================
# BONE CONSTRAINT TESTS
# ============================================================================

class TestBoneConstraint:
    """Tests for BoneConstraint dataclass."""

    def test_default_values(self):
        """Test default constraint allows full rotation."""
        c = BoneConstraint()
        assert c.min_angle == -math.pi
        assert c.max_angle == math.pi
        assert c.stiffness == 1.0

    def test_custom_values(self):
        """Test constraint with custom values."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0, stiffness=0.5)
        assert c.min_angle == -1.0
        assert c.max_angle == 1.0
        assert c.stiffness == 0.5

    def test_clamp_angle_within_range(self):
        """Test angle within range is unchanged."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        assert c.clamp_angle(0.5) == 0.5

    def test_clamp_angle_above_max(self):
        """Test angle above max is clamped."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        assert c.clamp_angle(2.0) == 1.0

    def test_clamp_angle_below_min(self):
        """Test angle below min is clamped."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        assert c.clamp_angle(-2.0) == -1.0

    def test_clamp_angle_normalizes_large(self):
        """Test large angles are normalized before clamping."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        # 4*pi is equivalent to 0
        result = c.clamp_angle(4 * math.pi)
        assert result == pytest.approx(0, abs=1e-10)

    def test_clamp_angle_normalizes_negative(self):
        """Test negative large angles are normalized."""
        c = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        # -4*pi is equivalent to 0
        result = c.clamp_angle(-4 * math.pi)
        assert result == pytest.approx(0, abs=1e-10)


# ============================================================================
# BONE TESTS
# ============================================================================

class TestBone:
    """Tests for Bone dataclass."""

    def test_default_values(self):
        """Test default bone values."""
        bone = Bone(name="test")
        assert bone.name == "test"
        assert bone.length == 50.0
        assert bone.angle == 0.0
        assert bone.parent is None
        assert bone.constraint is None
        assert bone.visible is True
        assert len(bone.children) == 0

    def test_custom_values(self):
        """Test bone with custom values."""
        constraint = BoneConstraint()
        bone = Bone(
            name="arm",
            length=100.0,
            angle=1.5,
            constraint=constraint
        )
        assert bone.name == "arm"
        assert bone.length == 100.0
        assert bone.angle == 1.5
        assert bone.constraint == constraint

    def test_add_child(self):
        """Test adding child bone."""
        parent = Bone(name="parent")
        child = Bone(name="child")
        result = parent.add_child(child)

        assert result == child
        assert child.parent == parent
        assert child in parent.children

    def test_add_multiple_children(self):
        """Test adding multiple children."""
        parent = Bone(name="parent")
        child1 = Bone(name="child1")
        child2 = Bone(name="child2")

        parent.add_child(child1)
        parent.add_child(child2)

        assert len(parent.children) == 2
        assert child1.parent == parent
        assert child2.parent == parent

    def test_get_world_angle_no_parent(self):
        """Test world angle without parent."""
        bone = Bone(name="test", angle=0.5)
        assert bone.get_world_angle() == 0.5

    def test_get_world_angle_with_parent(self):
        """Test world angle with parent."""
        parent = Bone(name="parent", angle=0.5)
        child = Bone(name="child", angle=0.3)
        parent.add_child(child)
        assert child.get_world_angle() == pytest.approx(0.8)

    def test_get_world_start(self):
        """Test getting world start position."""
        bone = Bone(name="test")
        bone._world_start = Vec2(100, 200)
        assert bone.get_world_start().x == 100
        assert bone.get_world_start().y == 200

    def test_get_world_end(self):
        """Test getting world end position."""
        bone = Bone(name="test")
        bone._world_end = Vec2(150, 250)
        assert bone.get_world_end().x == 150
        assert bone.get_world_end().y == 250

    def test_set_angle(self):
        """Test setting angle."""
        bone = Bone(name="test")
        bone.set_angle(1.0)
        assert bone.angle == 1.0

    def test_set_angle_with_constraint(self):
        """Test setting angle with constraint."""
        bone = Bone(
            name="test",
            constraint=BoneConstraint(min_angle=-0.5, max_angle=0.5)
        )
        bone.set_angle(1.0)  # Should be clamped to 0.5
        assert bone.angle == 0.5

    def test_set_angle_skip_constraint(self):
        """Test setting angle bypassing constraint."""
        bone = Bone(
            name="test",
            constraint=BoneConstraint(min_angle=-0.5, max_angle=0.5)
        )
        bone.set_angle(1.0, apply_constraints=False)
        assert bone.angle == 1.0

    def test_rotate(self):
        """Test rotating bone."""
        bone = Bone(name="test", angle=0.5)
        bone.rotate(0.3)
        assert bone.angle == pytest.approx(0.8)

    def test_rotate_with_constraint(self):
        """Test rotating with constraint."""
        bone = Bone(
            name="test",
            angle=0.3,
            constraint=BoneConstraint(min_angle=-0.5, max_angle=0.5)
        )
        bone.rotate(0.5)  # 0.3 + 0.5 = 0.8, clamped to 0.5
        assert bone.angle == 0.5


# ============================================================================
# SKELETON TESTS
# ============================================================================

class TestSkeleton:
    """Tests for Skeleton class."""

    def test_creation(self):
        """Test skeleton creation."""
        skeleton = Skeleton("test")
        assert skeleton.name == "test"
        assert skeleton.position.x == 0
        assert skeleton.position.y == 0
        assert skeleton.rotation == 0.0
        assert skeleton.scale == 1.0
        assert len(skeleton.bones) == 0
        assert len(skeleton.root_bones) == 0

    def test_creation_with_position(self):
        """Test skeleton creation with position."""
        skeleton = Skeleton("test", root_position=Vec2(100, 200))
        assert skeleton.position.x == 100
        assert skeleton.position.y == 200

    def test_add_bone_root(self):
        """Test adding root bone."""
        skeleton = Skeleton("test")
        bone = skeleton.add_bone("root", length=50)

        assert bone.name == "root"
        assert bone.length == 50
        assert "root" in skeleton.bones
        assert bone in skeleton.root_bones

    def test_add_bone_with_parent(self):
        """Test adding bone with parent."""
        skeleton = Skeleton("test")
        root = skeleton.add_bone("root", length=50)
        child = skeleton.add_bone("child", length=30, parent=root)

        assert child.parent == root
        assert child in root.children
        assert child not in skeleton.root_bones

    def test_add_bone_with_constraint(self):
        """Test adding bone with constraint."""
        skeleton = Skeleton("test")
        constraint = BoneConstraint(min_angle=-1.0, max_angle=1.0)
        bone = skeleton.add_bone("arm", constraint=constraint)

        assert bone.constraint == constraint

    def test_get_bone(self):
        """Test getting bone by name."""
        skeleton = Skeleton("test")
        bone = skeleton.add_bone("test_bone")

        assert skeleton.get_bone("test_bone") == bone
        assert skeleton.get_bone("nonexistent") is None

    def test_create_ik_chain(self):
        """Test creating IK chain."""
        skeleton = Skeleton("test")
        root = skeleton.add_bone("shoulder", length=50)
        elbow = skeleton.add_bone("elbow", length=40, parent=root)
        hand = skeleton.add_bone("hand", length=30, parent=elbow)

        skeleton.create_ik_chain("arm", ["shoulder", "elbow", "hand"])

        assert "arm" in skeleton.ik_chains
        assert skeleton.ik_chains["arm"] == ["shoulder", "elbow", "hand"]

    def test_create_ik_chain_invalid_bone(self):
        """Test creating IK chain with invalid bone."""
        skeleton = Skeleton("test")
        skeleton.add_bone("root")

        with pytest.raises(ValueError, match="not found"):
            skeleton.create_ik_chain("arm", ["root", "nonexistent"])

    def test_create_ik_chain_disconnected(self):
        """Test creating IK chain with disconnected bones."""
        skeleton = Skeleton("test")
        root1 = skeleton.add_bone("root1")
        root2 = skeleton.add_bone("root2")  # Not connected to root1

        with pytest.raises(ValueError, match="not a child"):
            skeleton.create_ik_chain("bad", ["root1", "root2"])

    def test_update(self):
        """Test skeleton update calculates positions."""
        skeleton = Skeleton("test", root_position=Vec2(100, 100))
        bone = skeleton.add_bone("test", length=50, angle=0)

        skeleton.update()

        assert bone._world_start.x == 100
        assert bone._world_start.y == 100
        assert bone._world_end.x == 150  # 100 + 50 (pointing right)
        assert bone._world_end.y == 100

    def test_update_with_rotation(self):
        """Test update with global rotation."""
        skeleton = Skeleton("test", root_position=Vec2(100, 100))
        skeleton.rotation = math.pi / 2  # 90 degrees
        bone = skeleton.add_bone("test", length=50, angle=0)

        skeleton.update()

        # Bone should point up
        assert bone._world_end.x == pytest.approx(100, abs=1e-10)
        assert bone._world_end.y == pytest.approx(150)

    def test_update_with_scale(self):
        """Test update with scale."""
        skeleton = Skeleton("test", root_position=Vec2(100, 100))
        skeleton.scale = 2.0
        bone = skeleton.add_bone("test", length=50, angle=0)

        skeleton.update()

        assert bone._world_end.x == 200  # 100 + 50*2

    def test_update_hierarchy(self):
        """Test update propagates through hierarchy."""
        skeleton = Skeleton("test", root_position=Vec2(0, 0))
        root = skeleton.add_bone("root", length=50, angle=0)
        child = skeleton.add_bone("child", length=30, angle=0, parent=root)

        skeleton.update()

        assert child._world_start.x == 50  # At end of root
        assert child._world_end.x == 80   # 50 + 30

    def test_solve_ik_invalid_chain(self):
        """Test solve_ik with invalid chain name."""
        skeleton = Skeleton("test")
        result = skeleton.solve_ik("nonexistent", (100, 100))
        assert result is False

    def test_solve_ik_short_chain(self):
        """Test solve_ik with single bone chain."""
        skeleton = Skeleton("test")
        skeleton.add_bone("single")
        skeleton.ik_chains["short"] = ["single"]

        result = skeleton.solve_ik("short", (100, 100))
        assert result is False

    def test_solve_ik_reachable_target(self):
        """Test solve_ik with reachable target."""
        skeleton = Skeleton("test", root_position=Vec2(0, 0))
        root = skeleton.add_bone("shoulder", length=50, angle=0)
        elbow = skeleton.add_bone("elbow", length=50, angle=0, parent=root)
        hand = skeleton.add_bone("hand", length=50, angle=0, parent=elbow)

        skeleton.create_ik_chain("arm", ["shoulder", "elbow", "hand"])
        skeleton.update()

        # Target within reach but off-axis (total length = 150)
        result = skeleton.solve_ik("arm", (100, 50), iterations=20)

        # Should reach close to target
        assert hand._world_end.distance_to(Vec2(100, 50)) < 10

    def test_solve_ik_unreachable_target(self):
        """Test solve_ik with unreachable target (stretches towards it)."""
        skeleton = Skeleton("test", root_position=Vec2(0, 0))
        root = skeleton.add_bone("shoulder", length=50, angle=0)
        elbow = skeleton.add_bone("elbow", length=50, angle=0, parent=root)
        hand = skeleton.add_bone("hand", length=50, angle=0, parent=elbow)

        skeleton.create_ik_chain("arm", ["shoulder", "elbow", "hand"])
        skeleton.update()

        # Target way out of reach (total length = 150)
        skeleton.solve_ik("arm", (500, 0))

        # Should stretch towards target
        assert hand._world_end.x > 100  # Extended

    def test_apply_animation(self):
        """Test applying animation to skeleton."""
        skeleton = Skeleton("test")
        skeleton.add_bone("root", length=50)

        # Create animation
        clip = AnimationClip(name="test_clip")
        track = clip.add_track("root.angle")
        track.add_keyframe(0, 0.0)
        track.add_keyframe(30, 1.0)

        skeleton.animation = clip
        skeleton.apply_animation(15)  # Midpoint

        assert skeleton.bones["root"].angle == pytest.approx(0.5)

    def test_apply_animation_no_animation(self):
        """Test apply_animation when no animation is set."""
        skeleton = Skeleton("test")
        skeleton.add_animation = None
        # Should not raise
        skeleton.apply_animation(0)

    def test_to_dict(self):
        """Test skeleton serialization."""
        skeleton = Skeleton("test", root_position=Vec2(100, 200))
        skeleton.rotation = 0.5
        skeleton.scale = 1.5

        root = skeleton.add_bone("root", length=50, angle=0.3)
        child = skeleton.add_bone("child", length=30, parent=root,
                                   constraint=BoneConstraint(-1, 1, 0.8))

        skeleton.create_ik_chain("arm", ["root", "child"])

        data = skeleton.to_dict()

        assert data["name"] == "test"
        assert data["position"] == (100, 200)
        assert data["rotation"] == 0.5
        assert data["scale"] == 1.5
        assert len(data["bones"]) == 1
        assert data["bones"][0]["name"] == "root"
        assert data["ik_chains"] == {"arm": ["root", "child"]}

    def test_from_dict(self):
        """Test skeleton deserialization."""
        data = {
            "name": "restored",
            "position": (50, 100),
            "rotation": 0.25,
            "scale": 2.0,
            "bones": [
                {
                    "name": "root",
                    "length": 60,
                    "angle": 0.5,
                    "visible": True,
                    "color": [255, 0, 0],
                    "sprite_path": None,
                    "sprite_offset": (0, 0),
                    "sprite_rotation": 0.0,
                    "constraint": None,
                    "children": [
                        {
                            "name": "child",
                            "length": 40,
                            "angle": 0.3,
                            "visible": True,
                            "color": [0, 255, 0],
                            "sprite_path": None,
                            "sprite_offset": (5, 10),
                            "sprite_rotation": 0.1,
                            "constraint": {
                                "min_angle": -1.0,
                                "max_angle": 1.0,
                                "stiffness": 0.5
                            },
                            "children": []
                        }
                    ]
                }
            ],
            "ik_chains": {"arm": ["root", "child"]}
        }

        skeleton = Skeleton.from_dict(data)

        assert skeleton.name == "restored"
        assert skeleton.position.x == 50
        assert skeleton.position.y == 100
        assert skeleton.rotation == 0.25
        assert skeleton.scale == 2.0

        assert "root" in skeleton.bones
        assert "child" in skeleton.bones

        root = skeleton.bones["root"]
        assert root.length == 60
        assert root.angle == 0.5

        child = skeleton.bones["child"]
        assert child.length == 40
        assert child.parent == root
        assert child.constraint is not None
        assert child.constraint.min_angle == -1.0

    def test_round_trip_serialization(self):
        """Test serialization round-trip."""
        original = Skeleton("roundtrip", root_position=Vec2(10, 20))
        original.rotation = 0.1
        original.scale = 1.2

        root = original.add_bone("root", length=40)
        child = original.add_bone("child", length=25, parent=root,
                                   constraint=BoneConstraint(-0.5, 0.5))

        original.create_ik_chain("chain", ["root", "child"])
        original.update()

        # Serialize and deserialize
        data = original.to_dict()
        restored = Skeleton.from_dict(data)

        assert restored.name == original.name
        assert restored.position.x == original.position.x
        assert restored.rotation == original.rotation
        assert restored.scale == original.scale
        assert len(restored.bones) == len(original.bones)
        assert "chain" in restored.ik_chains


# ============================================================================
# FACTORY FUNCTION TESTS
# ============================================================================

class TestCreateHumanoidSkeleton:
    """Tests for create_humanoid_skeleton function."""

    def test_default_creation(self):
        """Test creating default humanoid skeleton."""
        skeleton = create_humanoid_skeleton()

        assert skeleton.name == "humanoid"
        assert "root" in skeleton.bones
        assert "spine" in skeleton.bones
        assert "head" in skeleton.bones
        assert "left_upper_arm" in skeleton.bones
        assert "right_upper_arm" in skeleton.bones
        assert "left_upper_leg" in skeleton.bones
        assert "right_upper_leg" in skeleton.bones

    def test_custom_name(self):
        """Test humanoid with custom name."""
        skeleton = create_humanoid_skeleton(name="player")
        assert skeleton.name == "player"

    def test_custom_proportions(self):
        """Test humanoid with custom proportions."""
        skeleton = create_humanoid_skeleton(
            body_height=300,
            arm_length=180,
            leg_length=210
        )

        # Spine should be 35% of body height
        spine = skeleton.bones["spine"]
        assert spine.length == pytest.approx(105)  # 300 * 0.35

    def test_has_ik_chains(self):
        """Test humanoid has IK chains."""
        skeleton = create_humanoid_skeleton()

        assert "left_arm" in skeleton.ik_chains
        assert "right_arm" in skeleton.ik_chains
        assert "left_leg" in skeleton.ik_chains
        assert "right_leg" in skeleton.ik_chains

    def test_bones_have_constraints(self):
        """Test appropriate bones have constraints."""
        skeleton = create_humanoid_skeleton()

        # Elbow should have constraint
        left_lower_arm = skeleton.bones["left_lower_arm"]
        assert left_lower_arm.constraint is not None

    def test_skeleton_is_updated(self):
        """Test skeleton positions are calculated."""
        skeleton = create_humanoid_skeleton()

        # Check that update was called (positions calculated)
        root = skeleton.bones["root"]
        assert root._world_start.x == 0
        assert root._world_start.y == 0


class TestCreateArmSkeleton:
    """Tests for create_arm_skeleton function."""

    def test_default_creation(self):
        """Test creating default arm skeleton."""
        skeleton = create_arm_skeleton()

        assert skeleton.name == "arm"
        assert "shoulder" in skeleton.bones
        assert "elbow" in skeleton.bones
        assert "wrist" in skeleton.bones

    def test_custom_name(self):
        """Test arm with custom name."""
        skeleton = create_arm_skeleton(name="right_arm")
        assert skeleton.name == "right_arm"

    def test_custom_length(self):
        """Test arm with custom length."""
        skeleton = create_arm_skeleton(length=200)

        # Upper should be 40% of total
        shoulder = skeleton.bones["shoulder"]
        assert shoulder.length == pytest.approx(80)  # 200 * 0.4

    def test_has_ik_chain(self):
        """Test arm has IK chain."""
        skeleton = create_arm_skeleton()

        assert "arm" in skeleton.ik_chains
        assert skeleton.ik_chains["arm"] == ["shoulder", "elbow", "wrist"]

    def test_elbow_has_constraint(self):
        """Test elbow has constraint."""
        skeleton = create_arm_skeleton()

        elbow = skeleton.bones["elbow"]
        assert elbow.constraint is not None
        assert elbow.constraint.max_angle == 0  # Only bends one way

    def test_ik_solving(self):
        """Test IK works on arm skeleton."""
        skeleton = create_arm_skeleton(length=150)
        skeleton.position = Vec2(0, 0)
        skeleton.update()

        # Move hand to a reachable position (accounting for elbow constraint)
        result = skeleton.solve_ik("arm", (100, 30), iterations=20)

        # Should be reasonably close to target (constraints may limit precision)
        wrist = skeleton.bones["wrist"]
        assert wrist._world_end.distance_to(Vec2(100, 30)) < 20


# ============================================================================
# INTEGRATION TESTS
# ============================================================================

class TestSkeletonIntegration:
    """Integration tests for skeleton system."""

    def test_full_workflow(self):
        """Test complete skeleton workflow."""
        # Create skeleton
        skeleton = Skeleton("character", root_position=Vec2(400, 300))

        # Build hierarchy
        root = skeleton.add_bone("root", length=0)
        spine = skeleton.add_bone("spine", length=80, angle=-math.pi/2, parent=root)
        head = skeleton.add_bone("head", length=40, parent=spine)

        arm = skeleton.add_bone("upper_arm", length=50, angle=math.pi/2, parent=spine)
        forearm = skeleton.add_bone("forearm", length=40, parent=arm,
                                     constraint=BoneConstraint(-math.pi, 0))
        hand = skeleton.add_bone("hand", length=20, parent=forearm)

        # Create IK chain
        skeleton.create_ik_chain("arm", ["upper_arm", "forearm", "hand"])

        # Update positions
        skeleton.update()

        # Verify hierarchy
        assert head.parent == spine
        assert spine.parent == root
        assert hand.parent == forearm

        # Test IK
        skeleton.solve_ik("arm", (500, 250), iterations=15)

        # Serialize and restore
        data = skeleton.to_dict()
        restored = Skeleton.from_dict(data)

        assert len(restored.bones) == len(skeleton.bones)
        assert "arm" in restored.ik_chains
