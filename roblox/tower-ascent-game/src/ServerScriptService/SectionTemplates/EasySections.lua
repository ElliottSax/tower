--[[
	EasySections.lua
	Template definitions for Easy difficulty sections (Sections 1-10)

	Design Guidelines:
	- Wide platforms (10-12 studs wide)
	- Small gaps (3-6 studs)
	- Forgiving jumps
	- Clear visual guidance
	- Minimal obstacles
	- No precision required

	Section Count: 5 templates
	Usage: Randomly selected for tower sections 1-10

	Week 6: Initial implementation
--]]

local SectionBuilder = require(script.Parent.Parent.Utilities.SectionBuilder)

local EasySections = {}

-- ============================================================================
-- EASY_01: STRAIGHT PATH
-- ============================================================================

function EasySections.Straight()
	--[[
		A simple straight platform with no obstacles.
		Perfect for beginners to get comfortable with movement.

		Difficulty: 1/10
		Length: 30 studs
		Obstacles: None
	--]]

	return SectionBuilder.new("Easy_Straight", "Easy")
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(30, 2, 12))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:Build()
end

-- ============================================================================
-- EASY_02: SMALL GAP
-- ============================================================================

function EasySections.SmallGap()
	--[[
		Two platforms with a small 3-stud gap.
		Teaches basic jumping.

		Difficulty: 2/10
		Gap Size: 3 studs
		Jump Required: Yes (easy)
	--]]

	return SectionBuilder.new("Easy_SmallGap", "Easy")
		-- First platform
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(12, 2, 12))
		-- Small gap (3 studs)
		:AddGap(Vector3.new(-4, 0, 0), Vector3.new(-1, 0, 0))
		-- Second platform
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(18, 2, 12))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:Build()
end

-- ============================================================================
-- EASY_03: STAIRS UP
-- ============================================================================

function EasySections.StairsUp()
	--[[
		Gentle staircase going upward.
		Introduces vertical movement.
		WEEK 9: Added spikes hazard on step 2 (teaches hazard avoidance)

		Difficulty: 2/10
		Height Gain: 6 studs
		Steps: 4
		Hazards: Spikes (static, avoidable)
	--]]

	return SectionBuilder.new("Easy_StairsUp", "Easy")
		-- Step 1 (lowest)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 12))
		-- Step 2 WITH SPIKES
		:AddPlatform(Vector3.new(-4, 2, 0), Vector3.new(8, 2, 12))
		:AddSpikes(Vector3.new(-4, 4.5, 0), Vector3.new(4, 2, 4), false) -- Static spikes on step 2
		-- Step 3 (safe path around spikes)
		:AddPlatform(Vector3.new(4, 4, 0), Vector3.new(8, 2, 12))
		-- Step 4 (highest)
		:AddPlatform(Vector3.new(12, 6, 0), Vector3.new(8, 2, 12))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0), -- Start at bottom
			Vector3.new(15, 7, 0)   -- End at top
		)
		:Build()
end

-- ============================================================================
-- EASY_04: ZIGZAG PATH
-- ============================================================================

function EasySections.Zigzag()
	--[[
		Platforms arranged in a zigzag pattern.
		Teaches diagonal movement.

		Difficulty: 3/10
		Platforms: 4
		Width: Varies (left-right)
	--]]

	return SectionBuilder.new("Easy_Zigzag", "Easy")
		-- Platform 1 (left)
		:AddPlatform(Vector3.new(-12, 0, -4), Vector3.new(10, 2, 8))
		-- Platform 2 (right)
		:AddPlatform(Vector3.new(-4, 0, 4), Vector3.new(10, 2, 8))
		-- Platform 3 (left)
		:AddPlatform(Vector3.new(4, 0, -4), Vector3.new(10, 2, 8))
		-- Platform 4 (right)
		:AddPlatform(Vector3.new(12, 0, 4), Vector3.new(10, 2, 8))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:Build()
end

-- ============================================================================
-- EASY_05: JUMP PAD INTRO
-- ============================================================================

function EasySections.JumpPad()
	--[[
		Introduces jump pads in a safe environment.
		Gap is impossible without jump pad.

		Difficulty: 3/10
		Features: Jump Pad (100 power)
		Gap: 12 studs
	--]]

	return SectionBuilder.new("Easy_JumpPad", "Easy")
		-- First platform
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(12, 2, 12))
		-- Jump pad
		:AddJumpPad(Vector3.new(-4, 2.5, 0), Vector3.new(6, 1, 6))
		-- Large gap
		:AddGap(Vector3.new(-4, 0, 0), Vector3.new(4, 0, 0))
		-- Landing platform
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(18, 2, 12))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		-- Decoration (arrow pointing to jump pad)
		:AddDecoration(Vector3.new(-4, 6, 0), Vector3.new(2, 2, 2), "Sphere", Color3.fromRGB(255, 255, 0))
		:Build()
end

-- ============================================================================
-- EASY_06: WIDE PLATFORM HOP
-- ============================================================================

function EasySections.WidePlatformHop()
	--[[
		Three wide platforms with small gaps.
		Very forgiving, hard to fall.

		Difficulty: 2/10
		Platforms: 3 (all 12 studs wide)
		Gaps: 2 studs each
	--]]

	return SectionBuilder.new("Easy_WidePlatformHop", "Easy")
		-- Platform 1
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(10, 2, 12))
		-- Platform 2
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(10, 2, 12))
		-- Platform 3
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(10, 2, 12))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:Build()
end

-- ============================================================================
-- EASY_07: GENTLE SLOPE
-- ============================================================================

function EasySections.GentleSlope()
	--[[
		Gradual slope upward using overlapping platforms.
		No jumping required.

		Difficulty: 1/10
		Height Gain: 8 studs
		Slope: Gentle
	--]]

	return SectionBuilder.new("Easy_GentleSlope", "Easy")
		-- Bottom platform
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(10, 2, 12))
		-- Slope platforms (overlapping)
		:AddPlatform(Vector3.new(-6, 2, 0), Vector3.new(10, 2, 12))
		:AddPlatform(Vector3.new(0, 4, 0), Vector3.new(10, 2, 12))
		:AddPlatform(Vector3.new(6, 6, 0), Vector3.new(10, 2, 12))
		-- Top platform
		:AddPlatform(Vector3.new(12, 8, 0), Vector3.new(10, 2, 12))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(15, 9, 0)
		)
		:Build()
end

-- ============================================================================
-- EASY_08: L-SHAPE TURN
-- ============================================================================

function EasySections.LShapeTurn()
	--[[
		L-shaped path that turns 90 degrees.
		Teaches navigation and spatial awareness.

		Difficulty: 2/10
		Turn: 90 degrees
		Width: 10 studs (wide)
	--]]

	return SectionBuilder.new("Easy_LShapeTurn", "Easy")
		-- First leg (horizontal)
		:AddPlatform(Vector3.new(-8, 0, 0), Vector3.new(16, 2, 10))
		-- Corner platform
		:AddPlatform(Vector3.new(4, 0, 0), Vector3.new(10, 2, 10))
		-- Second leg (perpendicular)
		:AddPlatform(Vector3.new(8, 0, 8), Vector3.new(10, 2, 16))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(8, 1, 15)
		)
		:Build()
end

-- ============================================================================
-- EASY_09: CHECKPOINT REST
-- ============================================================================

function EasySections.CheckpointRest()
	--[[
		Large, safe platform for players to rest.
		Acts as a "safe zone" checkpoint.

		Difficulty: 1/10
		Size: Extra large
		Obstacles: None
	--]]

	return SectionBuilder.new("Easy_CheckpointRest", "Easy")
		-- Large platform
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(35, 2, 16))
		:AddCheckpoint(Vector3.new(0, 4, 0))
		-- Decorative pillars at corners
		:AddDecoration(Vector3.new(-16, 4, 7), Vector3.new(2, 6, 2), "Cylinder", Color3.fromRGB(150, 150, 150))
		:AddDecoration(Vector3.new(-16, 4, -7), Vector3.new(2, 6, 2), "Cylinder", Color3.fromRGB(150, 150, 150))
		:AddDecoration(Vector3.new(16, 4, 7), Vector3.new(2, 6, 2), "Cylinder", Color3.fromRGB(150, 150, 150))
		:AddDecoration(Vector3.new(16, 4, -7), Vector3.new(2, 6, 2), "Cylinder", Color3.fromRGB(150, 150, 150))
		:Build()
end

-- ============================================================================
-- EASY_10: TWO GAP SEQUENCE
-- ============================================================================

function EasySections.TwoGapSequence()
	--[[
		Two small gaps in sequence.
		Builds confidence with consecutive jumps.

		Difficulty: 3/10
		Gaps: 2 (both 3 studs)
		Platforms: 3
	--]]

	return SectionBuilder.new("Easy_TwoGapSequence", "Easy")
		-- Platform 1
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(10, 2, 12))
		-- Gap 1
		:AddGap(Vector3.new(-5, 0, 0), Vector3.new(-2, 0, 0))
		-- Platform 2
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(8, 2, 12))
		-- Gap 2
		:AddGap(Vector3.new(4, 0, 0), Vector3.new(7, 0, 0))
		-- Platform 3
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(12, 2, 12))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:Build()
end

-- ============================================================================
-- TEMPLATE REGISTRY
-- ============================================================================

-- Return all template functions
return {
	Straight = EasySections.Straight,
	SmallGap = EasySections.SmallGap,
	StairsUp = EasySections.StairsUp,
	Zigzag = EasySections.Zigzag,
	JumpPad = EasySections.JumpPad,
	WidePlatformHop = EasySections.WidePlatformHop,
	GentleSlope = EasySections.GentleSlope,
	LShapeTurn = EasySections.LShapeTurn,
	CheckpointRest = EasySections.CheckpointRest,
	TwoGapSequence = EasySections.TwoGapSequence,
}
