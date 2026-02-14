--[[
	MediumSections.lua
	Template definitions for Medium difficulty sections (Sections 11-30)

	Design Guidelines:
	- Medium platforms (6-10 studs wide)
	- Medium gaps (5-8 studs)
	- Requires timing and planning
	- More obstacles (walls, kill bricks)
	- Some precision required
	- Upgrades helpful but not required

	Section Count: 15 templates
	Usage: Randomly selected for tower sections 11-30

	Week 6: Initial implementation
--]]

local SectionBuilder = require(script.Parent.Parent.Utilities.SectionBuilder)

local MediumSections = {}

-- ============================================================================
-- MEDIUM_01: MEDIUM GAP JUMP
-- ============================================================================

function MediumSections.MediumGap()
	--[[
		Two platforms with a 6-stud gap.
		Requires confident jumping.

		Difficulty: 4/10
		Gap Size: 6 studs
		Platform Width: 10 studs
	--]]

	return SectionBuilder.new("Medium_MediumGap", "Medium")
		-- First platform
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(12, 2, 10))
		-- Gap
		:AddGap(Vector3.new(-4, 0, 0), Vector3.new(2, 0, 0))
		-- Second platform
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(16, 2, 10))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_02: WALL OBSTACLE
-- ============================================================================

function MediumSections.WallObstacle()
	--[[
		Platform with walls creating a narrow path.
		Tests navigation skills.

		Difficulty: 4/10
		Path Width: 4 studs (narrow)
		Walls: 2
	--]]

	return SectionBuilder.new("Medium_WallObstacle", "Medium")
		-- Main platform
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(30, 2, 12))
		-- Left wall
		:AddWall(Vector3.new(-8, 3, -2), Vector3.new(2, 6, 8), 0)
		-- Right wall
		:AddWall(Vector3.new(8, 3, 2), Vector3.new(2, 6, 8), 0)
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_03: STAIR DESCENT
-- ============================================================================

function MediumSections.StairsDown()
	--[[
		Stairs going downward. Harder than going up.
		Risk of falling off.

		Difficulty: 5/10
		Height Loss: 8 studs
		Steps: 5
	--]]

	return SectionBuilder.new("Medium_StairsDown", "Medium")
		-- Step 1 (highest)
		:AddPlatform(Vector3.new(-12, 8, 0), Vector3.new(8, 2, 10))
		-- Step 2
		:AddPlatform(Vector3.new(-6, 6, 0), Vector3.new(8, 2, 10))
		-- Step 3
		:AddPlatform(Vector3.new(0, 4, 0), Vector3.new(8, 2, 10))
		-- Step 4
		:AddPlatform(Vector3.new(6, 2, 0), Vector3.new(8, 2, 10))
		-- Step 5 (lowest)
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(8, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 10, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 9, 0), -- Start at top
			Vector3.new(15, 1, 0)   -- End at bottom
		)
		:Build()
end

-- ============================================================================
-- MEDIUM_04: TRIPLE GAP
-- ============================================================================

function MediumSections.TripleGap()
	--[[
		Three consecutive gaps.
		Tests sustained jumping accuracy.
		WEEK 9: Added spikes on platforms 2 & 3 (precise landing required)

		Difficulty: 5/10
		Gaps: 3 (5 studs each)
		Platforms: 4 (narrow)
		Hazards: Spikes on middle platforms
	--]]

	return SectionBuilder.new("Medium_TripleGap", "Medium")
		-- Platform 1 (safe start)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 10))
		-- Platform 2 WITH SPIKES
		:AddPlatform(Vector3.new(-4, 0, 0), Vector3.new(6, 2, 10))
		:AddSpikes(Vector3.new(-4, 2.5, -2), Vector3.new(3, 2, 3), false) -- Spikes on edge
		-- Platform 3 WITH SPIKES
		:AddPlatform(Vector3.new(4, 0, 0), Vector3.new(6, 2, 10))
		:AddSpikes(Vector3.new(4, 2.5, 2), Vector3.new(3, 2, 3), false) -- Spikes on opposite edge
		-- Platform 4 (safe landing)
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(8, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_05: KILL BRICK FLOOR
-- ============================================================================

function MediumSections.KillBrickFloor()
	--[[
		Platforms over a kill brick floor.
		Punishes falling.

		Difficulty: 5/10
		Kill Brick: Below platforms
		Safe Platforms: 3
	--]]

	return SectionBuilder.new("Medium_KillBrickFloor", "Medium")
		-- Kill brick floor (below)
		:AddKillBrick(Vector3.new(0, -6, 0), Vector3.new(40, 2, 20))
		-- Platform 1
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(10, 2, 10))
		-- Platform 2
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(8, 2, 10))
		-- Platform 3
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_06: SPIRAL ASCENT
-- ============================================================================

function MediumSections.SpiralAscent()
	--[[
		Platforms arranged in a spiral going up.
		360-degree turn while climbing.
		WEEK 9: Added quicksand on platforms 3 & 5 (slows spiral climb)

		Difficulty: 6/10
		Height Gain: 12 studs
		Platforms: 6 (circular arrangement)
		Hazards: Quicksand on platforms 3 & 5
	--]]

	return SectionBuilder.new("Medium_SpiralAscent", "Medium")
		-- Platform 1 (0°) - safe start
		:AddPlatform(Vector3.new(-8, 0, 0), Vector3.new(8, 2, 8))
		-- Platform 2 (60°)
		:AddPlatform(Vector3.new(-4, 2, 7), Vector3.new(8, 2, 8))
		-- Platform 3 (120°) WITH QUICKSAND
		:AddPlatform(Vector3.new(4, 4, 7), Vector3.new(8, 2, 8))
		:AddQuicksand(Vector3.new(4, 6, 7), Vector3.new(6, 1, 6)) -- Quicksand on platform 3
		-- Platform 4 (180°)
		:AddPlatform(Vector3.new(8, 6, 0), Vector3.new(8, 2, 8))
		-- Platform 5 (240°) WITH QUICKSAND
		:AddPlatform(Vector3.new(4, 8, -7), Vector3.new(8, 2, 8))
		:AddQuicksand(Vector3.new(4, 10, -7), Vector3.new(6, 1, 6)) -- Quicksand on platform 5
		-- Platform 6 (300°)
		:AddPlatform(Vector3.new(-4, 10, -7), Vector3.new(8, 2, 8))
		-- Final platform (360°/0°) - safe landing
		:AddPlatform(Vector3.new(-8, 12, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-8, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-12, 1, 0),
			Vector3.new(-12, 13, 0)
		)
		:Build()
end

-- ============================================================================
-- MEDIUM_07: NARROW BRIDGE
-- ============================================================================

function MediumSections.NarrowBridge()
	--[[
		Very narrow platform (3 studs wide).
		Easy to fall off sides.
		WEEK 9: Added quicksand in center (slow movement on narrow path)

		Difficulty: 5/10
		Width: 3 studs (very narrow)
		Length: 30 studs
		Hazards: Quicksand (center section)
	--]]

	return SectionBuilder.new("Medium_NarrowBridge", "Medium")
		-- Narrow platform (first third - safe)
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(10, 2, 3))
		-- Middle section WITH QUICKSAND (challenging!)
		:AddQuicksand(Vector3.new(0, 2, 0), Vector3.new(10, 1, 3)) -- Quicksand on surface
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(10, 2, 3))
		-- Final third (safe)
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(10, 2, 3))
		-- Kill bricks on sides
		:AddKillBrick(Vector3.new(0, -2, 8), Vector3.new(30, 1, 8))
		:AddKillBrick(Vector3.new(0, -2, -8), Vector3.new(30, 1, 8))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		-- Decorative pillars for depth perception
		:AddDecoration(Vector3.new(-12, 4, 0), Vector3.new(1, 6, 1), "Cylinder", Color3.fromRGB(200, 200, 200))
		:AddDecoration(Vector3.new(0, 4, 0), Vector3.new(1, 6, 1), "Cylinder", Color3.fromRGB(200, 200, 200))
		:AddDecoration(Vector3.new(12, 4, 0), Vector3.new(1, 6, 1), "Cylinder", Color3.fromRGB(200, 200, 200))
		:Build()
end

-- ============================================================================
-- MEDIUM_08: JUMP PAD SEQUENCE
-- ============================================================================

function MediumSections.JumpPadSequence()
	--[[
		Two jump pads in sequence.
		Requires mid-air control.

		Difficulty: 6/10
		Jump Pads: 2
		Landing Platforms: Small
	--]]

	return SectionBuilder.new("Medium_JumpPadSequence", "Medium")
		-- Platform 1
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(10, 2, 10))
		-- Jump pad 1
		:AddJumpPad(Vector3.new(-7, 2.5, 0), Vector3.new(5, 1, 5))
		-- Mid platform
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(8, 2, 8))
		-- Jump pad 2
		:AddJumpPad(Vector3.new(4, 2.5, 0), Vector3.new(5, 1, 5))
		-- Landing platform
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_09: ALTERNATING HEIGHTS
-- ============================================================================

function MediumSections.AlternatingHeights()
	--[[
		Platforms at alternating heights.
		Constant jumping up and down.

		Difficulty: 5/10
		Height Variation: 4 studs
		Platforms: 5
	--]]

	return SectionBuilder.new("Medium_AlternatingHeights", "Medium")
		-- Low
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 10))
		-- High
		:AddPlatform(Vector3.new(-6, 4, 0), Vector3.new(8, 2, 10))
		-- Low
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(8, 2, 10))
		-- High
		:AddPlatform(Vector3.new(6, 4, 0), Vector3.new(8, 2, 10))
		-- Low
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(8, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_10: CORNER MAZE
-- ============================================================================

function MediumSections.CornerMaze()
	--[[
		Multiple 90-degree turns creating a maze.
		Tests navigation.
		WEEK 9: Added rotating obstacle at turn 2 (dynamic hazard)

		Difficulty: 5/10
		Turns: 3
		Path Width: 8 studs
		Hazards: Rotating obstacle at center
	--]]

	return SectionBuilder.new("Medium_CornerMaze", "Medium")
		-- Start platform
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(12, 2, 8))
		-- Turn 1 (right)
		:AddPlatform(Vector3.new(-4, 0, 6), Vector3.new(8, 2, 10))
		-- Turn 2 (left) WITH ROTATING OBSTACLE
		:AddPlatform(Vector3.new(4, 0, 10), Vector3.new(12, 2, 8))
		:AddRotatingObstacle(Vector3.new(4, 4, 10), Vector3.new(16, 2, 2), 45) -- Rotating bar at center
		-- Turn 3 (right)
		:AddPlatform(Vector3.new(10, 0, 4), Vector3.new(8, 2, 10))
		-- End platform
		:AddPlatform(Vector3.new(10, 0, -4), Vector3.new(8, 2, 10))
		:AddCheckpoint(Vector3.new(-10, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(10, 1, -8)
		)
		:Build()
end

-- ============================================================================
-- MEDIUM_11: FLOATING ISLANDS
-- ============================================================================

function MediumSections.FloatingIslands()
	--[[
		Small platforms scattered in space.
		Requires precise jumping.
		WEEK 9: Added spikes on platforms 3 & 5 (precise landing required)

		Difficulty: 6/10
		Platforms: 6 (small)
		Spacing: Varied
		Hazards: Spikes on platforms 3 & 5
	--]]

	return SectionBuilder.new("Medium_FloatingIslands", "Medium")
		-- Platform 1 (safe start)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(6, 2, 6))
		-- Platform 2 (offset right)
		:AddPlatform(Vector3.new(-6, 0, 3), Vector3.new(5, 2, 5))
		-- Platform 3 (offset left) WITH SPIKES
		:AddPlatform(Vector3.new(-1, 0, -3), Vector3.new(5, 2, 5))
		:AddSpikes(Vector3.new(-1, 2.5, -3), Vector3.new(3, 2, 3), false) -- Center spikes
		-- Platform 4 (center)
		:AddPlatform(Vector3.new(4, 0, 0), Vector3.new(6, 2, 6))
		-- Platform 5 (offset right) WITH SPIKES
		:AddPlatform(Vector3.new(9, 0, 4), Vector3.new(5, 2, 5))
		:AddSpikes(Vector3.new(9, 2.5, 4), Vector3.new(3, 2, 3), false) -- Center spikes
		-- Platform 6 (final - safe)
		:AddPlatform(Vector3.new(13, 0, 0), Vector3.new(7, 2, 7))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_12: WALL JUMP PATH
-- ============================================================================

function MediumSections.WallJumpPath()
	--[[
		Walls positioned to encourage wall grip usage.
		Optional: use wall grip or go around.

		Difficulty: 5/10
		Walls: 4 (climbable with WallGrip upgrade)
		Alternative: Jump around
	--]]

	return SectionBuilder.new("Medium_WallJumpPath", "Medium")
		-- Starting platform
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 10))
		-- Wall 1 (vertical obstacle)
		:AddWall(Vector3.new(-6, 5, 0), Vector3.new(2, 10, 10), 0)
		-- Mid platform (behind wall)
		:AddPlatform(Vector3.new(0, 4, 0), Vector3.new(8, 2, 10))
		-- Wall 2
		:AddWall(Vector3.new(6, 9, 0), Vector3.new(2, 10, 10), 0)
		-- End platform (above wall 2)
		:AddPlatform(Vector3.new(12, 8, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(15, 9, 0)
		)
		:Build()
end

-- ============================================================================
-- MEDIUM_13: TIMED JUMP SEQUENCE
-- ============================================================================

function MediumSections.TimedJumpSequence()
	--[[
		Platforms that require rhythmic jumping.
		Equal spacing for consistent timing.

		Difficulty: 6/10
		Platforms: 8 (evenly spaced)
		Gap: 4 studs each
	--]]

	return SectionBuilder.new("Medium_TimedJumpSequence", "Medium")
		-- Create 8 platforms with equal spacing
		:AddPlatform(Vector3.new(-14, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(-6, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(-2, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(2, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(6, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(5, 2, 8))
		:AddPlatform(Vector3.new(14, 0, 0), Vector3.new(5, 2, 8))
		:AddCheckpoint(Vector3.new(-14, 4, 0))
		:Build()
end

-- ============================================================================
-- MEDIUM_14: DIAGONAL ASCENT
-- ============================================================================

function MediumSections.DiagonalAscent()
	--[[
		Platforms going up diagonally.
		Combines height and distance challenges.

		Difficulty: 6/10
		Height Gain: 10 studs
		Direction: Diagonal
	--]]

	return SectionBuilder.new("Medium_DiagonalAscent", "Medium")
		-- Platform 1 (lowest)
		:AddPlatform(Vector3.new(-12, 0, -8), Vector3.new(8, 2, 8))
		-- Platform 2
		:AddPlatform(Vector3.new(-6, 2, -4), Vector3.new(7, 2, 7))
		-- Platform 3
		:AddPlatform(Vector3.new(0, 4, 0), Vector3.new(7, 2, 7))
		-- Platform 4
		:AddPlatform(Vector3.new(6, 6, 4), Vector3.new(7, 2, 7))
		-- Platform 5 (highest)
		:AddPlatform(Vector3.new(12, 8, 8), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-12, 4, -8))
		:SetConnectionPoints(
			Vector3.new(-15, 1, -8),
			Vector3.new(15, 9, 8)
		)
		:Build()
end

-- ============================================================================
-- MEDIUM_15: CHECKPOINT GAUNTLET
-- ============================================================================

function MediumSections.CheckpointGauntlet()
	--[[
		Long section with multiple challenges.
		Checkpoint in middle for safety.
		WEEK 9: Added spikes (first half) + quicksand (second half) - FINALE CHALLENGE

		Difficulty: 6/10
		Length: Extra long
		Challenges: Multiple
		Hazards: Spikes + Quicksand (ultimate Medium test)
	--]]

	return SectionBuilder.new("Medium_CheckpointGauntlet", "Medium")
		-- First half WITH SPIKES
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 10))
		:AddPlatform(Vector3.new(-8, 0, 0), Vector3.new(6, 2, 10))
		:AddSpikes(Vector3.new(-8, 2.5, 0), Vector3.new(3, 2, 3), false) -- Spikes on platform 2
		:AddPlatform(Vector3.new(-2, 2, 0), Vector3.new(6, 2, 10))
		-- Mid checkpoint (SAFE ZONE)
		:AddPlatform(Vector3.new(4, 2, 0), Vector3.new(10, 2, 12))
		:AddCheckpoint(Vector3.new(4, 6, 0))
		-- Second half WITH QUICKSAND
		:AddPlatform(Vector3.new(10, 2, 0), Vector3.new(6, 2, 10))
		:AddPlatform(Vector3.new(16, 0, 0), Vector3.new(6, 2, 10))
		:AddQuicksand(Vector3.new(16, 2, 0), Vector3.new(5, 1, 8)) -- Quicksand on platform 6
		:AddPlatform(Vector3.new(22, 0, 0), Vector3.new(8, 2, 10))
		:SetConnectionPoints(
			Vector3.new(-18, 1, 0),
			Vector3.new(25, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- TEMPLATE REGISTRY
-- ============================================================================

return {
	MediumGap = MediumSections.MediumGap,
	WallObstacle = MediumSections.WallObstacle,
	StairsDown = MediumSections.StairsDown,
	TripleGap = MediumSections.TripleGap,
	KillBrickFloor = MediumSections.KillBrickFloor,
	SpiralAscent = MediumSections.SpiralAscent,
	NarrowBridge = MediumSections.NarrowBridge,
	JumpPadSequence = MediumSections.JumpPadSequence,
	AlternatingHeights = MediumSections.AlternatingHeights,
	CornerMaze = MediumSections.CornerMaze,
	FloatingIslands = MediumSections.FloatingIslands,
	WallJumpPath = MediumSections.WallJumpPath,
	TimedJumpSequence = MediumSections.TimedJumpSequence,
	DiagonalAscent = MediumSections.DiagonalAscent,
	CheckpointGauntlet = MediumSections.CheckpointGauntlet,
}
