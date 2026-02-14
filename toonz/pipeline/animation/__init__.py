"""Animation and character components.

This module provides comprehensive animation capabilities:

Core Animation:
- Character: Character instances with lip sync and poses
- CharacterRig: Character rig definitions with assets
- Scene: Scene composition with layers
- SceneLayer: Individual layers with animation
- Keyframe, KeyframeTrack, AnimationClip: Keyframe animation system
- EasingType: Animation easing functions

Skeletal Animation (bones):
- Skeleton: Full skeletal rig with bones and IK
- Bone: Individual bone with constraints
- Vec2: 2D vector for bone math
- BoneConstraint: Angle limits for bones
- create_humanoid_skeleton: Pre-built humanoid template
- create_arm_skeleton: Simple arm for testing

Physics Animation (physics):
- Spring, Spring2D: Damped spring simulation
- PhysicsChain: Verlet chain for hair/cloth/rope
- BreathingAnimation: Procedural breathing
- EyeController: Eye movement and blinking
- SquashStretch: Squash and stretch deformation
- InertiaFollow: Following with overshoot
- Wobble: Jiggle/bounce effects

Camera System (camera):
- Camera: Virtual camera with zoom/rotation
- ParallaxCamera: Camera with depth layers
- ShakeType, ShakeInstance: Camera shake effects
- ParallaxLayer: Layer with depth
- DepthOfField: Focus blur effect

Effects (effects):
- ParticleEmitter: Particle system
- create_sparkle_emitter, create_dust_emitter, etc: Pre-configured effects
- apply_glow, apply_drop_shadow, apply_color_grade, apply_vignette: Image effects
- FadeTransition, WipeTransition, DissolveTransition, IrisTransition: Transitions
- BezierPath: Bezier curve paths
- PathFollower: Object following a path

Expressions (expressions):
- Emotion: Base emotion types (happy, sad, angry, etc.)
- FacialAnimator: Complete facial animation controller
- ExpressionController: Emotion blending and transitions
- BlinkController: Procedural blinking
- LipSyncBlender: Blend lip sync with expressions

Motion Presets (motion_presets):
- IdleMotion, BreathingMotion: Ambient animations
- TalkingGesture, ShrugMotion, WaveMotion: Gestures
- PointMotion, ThinkingMotion, CelebrateMotion: Actions
- WalkCycle, RunCycle: Locomotion
- MotionBlender: Combine multiple motions

Scene Rendering (scene_renderer):
- SceneRenderer: Full scene composition to video
- QuickRenderer: Fast rendering for tests
- RenderSettings: Output configuration
- AnimatedCharacter: Character with all animation systems
"""

# Core
from .character import Character, CharacterRig, LayerDefinition
from .scene import Scene, SceneLayer
from .keyframes import Keyframe, KeyframeTrack, AnimationClip, EasingType

# Skeletal animation
from .bones import (
    Vec2,
    Bone,
    BoneConstraint,
    Skeleton,
    create_humanoid_skeleton,
    create_arm_skeleton,
    solve_two_bone_ik,
    solve_leg_ik,
    solve_arm_ik,
)

# Physics animation
from .physics import (
    Spring,
    Spring2D,
    SpringState,
    PhysicsChain,
    ChainSegment,
    BreathingAnimation,
    EyeController,
    SquashStretch,
    InertiaFollow,
    Wobble,
)

# Camera system
from .camera import (
    Camera,
    CameraState,
    ParallaxCamera,
    ParallaxLayer,
    ShakeType,
    ShakeInstance,
    DepthOfField,
)

# Effects
from .effects import (
    # Particles
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

# Expressions
from .expressions import (
    Emotion,
    EyebrowState,
    EyeState,
    MouthState,
    FaceState,
    ExpressionController,
    BlinkController,
    LipSyncBlender,
    HeadMotionController,
    FacialAnimator,
)

# Motion presets
from .motion_presets import (
    Transform,
    Pose,
    MotionType,
    MotionPreset,
    IdleMotion,
    BreathingMotion,
    TalkingGesture,
    ShrugMotion,
    WaveMotion,
    PointMotion,
    ThinkingMotion,
    CelebrateMotion,
    WalkCycle,
    RunCycle,
    MotionBlender,
    GestureGenerator,
    create_idle,
    create_breathing,
    create_wave,
    create_point,
    create_shrug,
    create_thinking,
    create_celebrate,
    create_walk,
    create_run,
)

# Scene rendering
from .scene_renderer import (
    RenderSettings,
    RenderProgress,
    AnimatedCharacter,
    SceneRenderer,
    QuickRenderer,
    render_test_animation,
)

__all__ = [
    # Core
    "Character",
    "CharacterRig",
    "LayerDefinition",
    "Scene",
    "SceneLayer",
    "Keyframe",
    "KeyframeTrack",
    "AnimationClip",
    "EasingType",
    # Bones
    "Vec2",
    "Bone",
    "BoneConstraint",
    "Skeleton",
    "create_humanoid_skeleton",
    "create_arm_skeleton",
    "solve_two_bone_ik",
    "solve_leg_ik",
    "solve_arm_ik",
    # Physics
    "Spring",
    "Spring2D",
    "SpringState",
    "PhysicsChain",
    "ChainSegment",
    "BreathingAnimation",
    "EyeController",
    "SquashStretch",
    "InertiaFollow",
    "Wobble",
    # Camera
    "Camera",
    "CameraState",
    "ParallaxCamera",
    "ParallaxLayer",
    "ShakeType",
    "ShakeInstance",
    "DepthOfField",
    # Effects
    "Particle",
    "ParticleEmitter",
    "create_sparkle_emitter",
    "create_dust_emitter",
    "create_rain_emitter",
    "create_confetti_emitter",
    "apply_glow",
    "apply_drop_shadow",
    "apply_color_grade",
    "apply_vignette",
    "Transition",
    "FadeTransition",
    "WipeTransition",
    "DissolveTransition",
    "IrisTransition",
    "BezierPoint",
    "BezierPath",
    "PathFollower",
    # Expressions
    "Emotion",
    "EyebrowState",
    "EyeState",
    "MouthState",
    "FaceState",
    "ExpressionController",
    "BlinkController",
    "LipSyncBlender",
    "HeadMotionController",
    "FacialAnimator",
    # Motion presets
    "Transform",
    "Pose",
    "MotionType",
    "MotionPreset",
    "IdleMotion",
    "BreathingMotion",
    "TalkingGesture",
    "ShrugMotion",
    "WaveMotion",
    "PointMotion",
    "ThinkingMotion",
    "CelebrateMotion",
    "WalkCycle",
    "RunCycle",
    "MotionBlender",
    "GestureGenerator",
    "create_idle",
    "create_breathing",
    "create_wave",
    "create_point",
    "create_shrug",
    "create_thinking",
    "create_celebrate",
    "create_walk",
    "create_run",
    # Scene rendering
    "RenderSettings",
    "RenderProgress",
    "AnimatedCharacter",
    "SceneRenderer",
    "QuickRenderer",
    "render_test_animation",
]
