--[[
	HardSections.lua
	Template definitions for Hard difficulty sections (Sections 31-45)

	Design Guidelines:
	- Narrow platforms (4-6 studs wide)
	- Large gaps (8-12 studs)
	- Moving platforms and obstacles
	- Precision required
	- Upgrades recommended (AirDash, WallGrip, SpeedBoost)
	- High-risk environments (kill bricks, narrow paths)
	- Combination mechanics

	Section Count: 15 templates
	Usage: Randomly selected for tower sections 31-45

	Week 7: Initial implementation
--]]

local SectionBuilder = require(script.Parent.Parent.Utilities.SectionBuilder)

local HardSections = {}

-- ============================================================================
-- HARD_01: LARGE GAP JUMP
-- ============================================================================

function HardSections.LargeGap()
	--[[
		Two platforms with a 10-stud gap.
		Requires AirDash or perfect jump timing.

		Difficulty: 7/10
		Gap Size: 10 studs
		Platform Width: 6 studs
		Upgrades: AirDash recommended
	--]]

	return SectionBuilder.new("Hard_LargeGap", "Hard")
		-- First platform
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(10, 2, 6))
		-- Large gap (10 studs)
		:AddGap(Vector3.new(-7, 0, 0), Vector3.new(3, 0, 0))
		-- Second platform
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(16, 2, 6))
		-- Spikes on landing area (Week 9: Hazards)
		:AddSpikes(Vector3.new(5, 2.5, 0), Vector3.new(4, 2, 4))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		-- Kill brick below to punish falls
		:AddKillBrick(Vector3.new(0, -8, 0), Vector3.new(30, 2, 20))
		:Build()
end

-- ============================================================================
-- HARD_02: MOVING PLATFORM SEQUENCE
-- ============================================================================

function HardSections.MovingPlatformSequence()
	--[[
		Three moving platforms in sequence.
		Must time jumps with platform movement.

		Difficulty: 8/10
		Moving Platforms: 3
		Speed: 5 studs/second
		Requires: Good timing
	--]]

	return SectionBuilder.new("Hard_MovingPlatformSequence", "Hard")
		-- Starting platform
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 8))
		-- Moving platform 1 (left-right)
		:AddMovingPlatform(
			Vector3.new(-8, 0, 0),
			Vector3.new(-8, 0, 8),
			Vector3.new(6, 2, 6),
			5
		)
		-- Poison gas cloud between platforms (Week 9: Hazards)
		:AddPoisonGas(Vector3.new(-4, 8, 0), Vector3.new(8, 12, 8))
		-- Moving platform 2 (right-left)
		:AddMovingPlatform(
			Vector3.new(0, 0, 8),
			Vector3.new(0, 0, -8),
			Vector3.new(6, 2, 6),
			5
		)
		-- Moving platform 3 (left-right)
		:AddMovingPlatform(
			Vector3.new(8, 0, -8),
			Vector3.new(8, 0, 0),
			Vector3.new(6, 2, 6),
			5
		)
		-- Landing platform
		:AddPlatform(Vector3.new(15, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:AddKillBrick(Vector3.new(0, -8, 0), Vector3.new(40, 2, 25))
		:Build()
end

-- ============================================================================
-- HARD_03: PRECISION PLATFORMING
-- ============================================================================

function HardSections.PrecisionPlatforming()
	--[[
		Very small platforms (4x4) with 6-stud gaps.
		Requires pixel-perfect jumps.

		Difficulty: 8/10
		Platform Size: 4x4 (tiny)
		Gaps: 6 studs
		Platforms: 6
	--]]

	return SectionBuilder.new("Hard_PrecisionPlatforming", "Hard")
		-- Create 6 small platforms
		:AddPlatform(Vector3.new(-14, 0, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(-8, 0, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(-2, 0, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(4, 0, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(10, 0, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(16, 0, 0), Vector3.new(6, 2, 6))
		:AddCheckpoint(Vector3.new(-14, 4, 0))
		-- Kill brick floor (very punishing)
		:AddKillBrick(Vector3.new(0, -5, 0), Vector3.new(40, 2, 20))
		:Build()
end

-- ============================================================================
-- HARD_04: VERTICAL WALL CLIMB
-- ============================================================================

function HardSections.VerticalWallClimb()
	--[[
		Climb 20 studs using wall grip mechanic.
		Platforms on vertical wall surface.
		WEEK 9: Added ice to ledges 2 & 3 (slippery climbing)

		Difficulty: 7/10
		Height Gain: 20 studs
		Requires: WallGrip upgrade
		Alternative: Difficult without upgrade
		Hazards: Ice on ledges (slippery grip)
	--]]

	return SectionBuilder.new("Hard_VerticalWallClimb", "Hard")
		-- Bottom platform (safe start)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 8))
		-- Vertical wall
		:AddWall(Vector3.new(-8, 10, 0), Vector3.new(2, 20, 10), 0)
		-- Ledge 1 (safe)
		:AddPlatform(Vector3.new(-6, 4, 0), Vector3.new(4, 1, 6))
		-- Ledge 2 WITH ICE
		:AddIce(Vector3.new(-6, 8, 2), Vector3.new(4, 1, 6))
		-- Ledge 3 WITH ICE
		:AddIce(Vector3.new(-6, 12, -2), Vector3.new(4, 1, 6))
		-- Ledge 4 (safe)
		:AddPlatform(Vector3.new(-6, 16, 0), Vector3.new(4, 1, 6))
		-- Top platform (safe landing)
		:AddPlatform(Vector3.new(0, 20, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(4, 21, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_05: DIAGONAL LEAP SEQUENCE
-- ============================================================================

function HardSections.DiagonalLeapSequence()
	--[[
		Platforms arranged diagonally with large gaps.
		Must jump diagonally (not straight).
		WEEK 9: Added cross-wind zones (push perpendicular to jump direction)

		Difficulty: 7/10
		Gaps: 8 studs (diagonal)
		Platforms: 5 (narrow)
		Hazards: Wind zones push sideways during jumps
	--]]

	return SectionBuilder.new("Hard_DiagonalLeapSequence", "Hard")
		-- Platform 1 (bottom-left - safe)
		:AddPlatform(Vector3.new(-12, 0, -8), Vector3.new(6, 2, 6))
		-- WIND ZONE 1 (pushes left during jump)
		:AddWindZone(Vector3.new(-9, 5, -5), Vector3.new(6, 10, 6), Vector3.new(-1, 0, 0), 25)
		-- Platform 2
		:AddPlatform(Vector3.new(-6, 2, -2), Vector3.new(5, 2, 5))
		-- Platform 3
		:AddPlatform(Vector3.new(0, 4, 4), Vector3.new(5, 2, 5))
		-- WIND ZONE 2 (pushes right during jump)
		:AddWindZone(Vector3.new(3, 8, 7), Vector3.new(6, 10, 6), Vector3.new(1, 0, 0), 25)
		-- Platform 4
		:AddPlatform(Vector3.new(6, 6, 10), Vector3.new(5, 2, 5))
		-- Platform 5 (top-right - safe landing)
		:AddPlatform(Vector3.new(12, 8, 16), Vector3.new(6, 2, 6))
		:AddCheckpoint(Vector3.new(-12, 4, -8))
		:AddKillBrick(Vector3.new(0, -8, 4), Vector3.new(30, 2, 30))
		:SetConnectionPoints(
			Vector3.new(-15, 1, -8),
			Vector3.new(15, 9, 16)
		)
		:Build()
end

-- ============================================================================
-- HARD_06: GAUNTLET OF DEATH
-- ============================================================================

function HardSections.GauntletOfDeath()
	--[[
		Long narrow bridge with kill bricks on sides.
		One mistake = death.
		WEEK 9: CENTER SECTION IS ICE - Ultra-narrow + slippery = EXTREME

		Difficulty: 8/10
		Width: 2 studs (extremely narrow)
		Length: 35 studs
		Kill Bricks: Both sides
		Hazards: ICE on center section (slippery narrow bridge)
	--]]

	return SectionBuilder.new("Hard_GauntletOfDeath", "Hard")
		-- First third (safe)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(11, 2, 2))
		-- CENTER THIRD WITH ICE (EXTREME CHALLENGE!)
		:AddIce(Vector3.new(0, 0, 0), Vector3.new(13, 2, 2))
		-- Final third (safe)
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(11, 2, 2))
		-- Kill bricks on both sides (instant death)
		:AddKillBrick(Vector3.new(0, 0, 6), Vector3.new(35, 4, 6))
		:AddKillBrick(Vector3.new(0, 0, -6), Vector3.new(35, 4, 6))
		-- Kill brick below
		:AddKillBrick(Vector3.new(0, -8, 0), Vector3.new(35, 2, 15))
		:AddCheckpoint(Vector3.new(-17, 4, 0))
		-- Warning decorations (red spheres)
		:AddDecoration(Vector3.new(-15, 3, 0), Vector3.new(1, 1, 1), "Sphere", Color3.fromRGB(255, 0, 0))
		:AddDecoration(Vector3.new(0, 3, 0), Vector3.new(1, 1, 1), "Sphere", Color3.fromRGB(255, 255, 0)) -- Yellow warning for ice
		:AddDecoration(Vector3.new(15, 3, 0), Vector3.new(1, 1, 1), "Sphere", Color3.fromRGB(255, 0, 0))
		:Build()
end

-- ============================================================================
-- HARD_07: JUMP PAD GAUNTLET
-- ============================================================================

function HardSections.JumpPadGauntlet()
	--[[
		Multiple jump pads launching to small platforms.
		Mid-air control critical.

		Difficulty: 7/10
		Jump Pads: 3
		Landing Platforms: Small (5x5)
		Requires: Air control, AirDash helpful
	--]]

	return SectionBuilder.new("Hard_JumpPadGauntlet", "Hard")
		-- Platform 1
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 8))
		-- Jump pad 1
		:AddJumpPad(Vector3.new(-11, 2.5, 0), Vector3.new(5, 1, 5))
		-- Small landing 1
		:AddPlatform(Vector3.new(-5, 0, 0), Vector3.new(5, 2, 5))
		-- Jump pad 2
		:AddJumpPad(Vector3.new(-2, 2.5, 0), Vector3.new(5, 1, 5))
		-- Small landing 2
		:AddPlatform(Vector3.new(5, 0, 0), Vector3.new(5, 2, 5))
		-- Jump pad 3
		:AddJumpPad(Vector3.new(8, 2.5, 0), Vector3.new(5, 1, 5))
		-- Final platform
		:AddPlatform(Vector3.new(15, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:AddKillBrick(Vector3.new(0, -8, 0), Vector3.new(40, 2, 20))
		:Build()
end

-- ============================================================================
-- HARD_08: SPIRAL DESCENT
-- ============================================================================

function HardSections.SpiralDescent()
	--[[
		Spiral going DOWN (harder than up).
		360-degree turn while descending.
		WEEK 9: Added ice to platforms 3, 4, 5 (slippery descent)

		Difficulty: 7/10
		Height Loss: 15 studs
		Platforms: 7 (narrow)
		Direction: Clockwise descent
		Hazards: Ice on middle platforms (slippery downward spiral)
	--]]

	return SectionBuilder.new("Hard_SpiralDescent", "Hard")
		-- Top platform (0°) - safe start
		:AddPlatform(Vector3.new(-8, 15, 0), Vector3.new(6, 2, 6))
		-- Platform 2 (60°)
		:AddPlatform(Vector3.new(-4, 12, 7), Vector3.new(5, 2, 5))
		-- Platform 3 (120°) WITH ICE
		:AddIce(Vector3.new(4, 9, 7), Vector3.new(5, 2, 5))
		-- Platform 4 (180°) WITH ICE
		:AddIce(Vector3.new(8, 6, 0), Vector3.new(5, 2, 5))
		-- Platform 5 (240°) WITH ICE
		:AddIce(Vector3.new(4, 3, -7), Vector3.new(5, 2, 5))
		-- Platform 6 (300°)
		:AddPlatform(Vector3.new(-4, 1, -7), Vector3.new(5, 2, 5))
		-- Bottom platform (360°/0°) - safe landing
		:AddPlatform(Vector3.new(-8, 0, 0), Vector3.new(6, 2, 6))
		:AddCheckpoint(Vector3.new(-8, 17, 0))
		:AddKillBrick(Vector3.new(0, -5, 0), Vector3.new(25, 2, 25))
		:SetConnectionPoints(
			Vector3.new(-12, 16, 0),
			Vector3.new(-12, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_09: ALTERNATING WALL JUMPS
-- ============================================================================

function HardSections.AlternatingWallJumps()
	--[[
		Jump between two parallel walls.
		Zigzag pattern requiring wall grip.

		Difficulty: 8/10
		Walls: 2 (parallel)
		Distance: 12 studs apart
		Requires: WallGrip highly recommended
	--]]

	return SectionBuilder.new("Hard_AlternatingWallJumps", "Hard")
		-- Starting platform
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 6))
		-- Left wall
		:AddWall(Vector3.new(-8, 8, -6), Vector3.new(2, 16, 6), 0)
		-- Right wall
		:AddWall(Vector3.new(-8, 8, 6), Vector3.new(2, 16, 6), 0)
		-- Platforms on walls (alternating)
		:AddPlatform(Vector3.new(-12, 2, -4), Vector3.new(4, 1, 4)) -- Left
		:AddPlatform(Vector3.new(-10, 4, 4), Vector3.new(4, 1, 4))  -- Right
		:AddPlatform(Vector3.new(-8, 6, -4), Vector3.new(4, 1, 4))  -- Left
		:AddPlatform(Vector3.new(-6, 8, 4), Vector3.new(4, 1, 4))   -- Right
		:AddPlatform(Vector3.new(-4, 10, -4), Vector3.new(4, 1, 4)) -- Left
		-- Top platform
		:AddPlatform(Vector3.new(0, 12, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-18, 1, 0),
			Vector3.new(4, 13, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_10: TIMED OBSTACLE COURSE
-- ============================================================================

function HardSections.TimedObstacleCourse()
	--[[
		Multiple obstacles requiring quick reactions.
		Speed boost recommended.
		WEEK 9: Added wind zone in section 2 (pushes during gap jump)

		Difficulty: 7/10
		Obstacles: Walls, gaps, kill bricks
		Length: Long (40 studs)
		Requires: SpeedBoost helpful
		Hazards: Wind zone pushes during gap jump
	--]]

	return SectionBuilder.new("Hard_TimedObstacleCourse", "Hard")
		-- Section 1: Narrow path
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(10, 2, 4))
		:AddWall(Vector3.new(-10, 3, 0), Vector3.new(2, 6, 4), 0)
		-- Section 2: Gap WITH WIND ZONE
		:AddPlatform(Vector3.new(-2, 0, 0), Vector3.new(8, 2, 6))
		:AddWindZone(Vector3.new(2, 4, 0), Vector3.new(8, 8, 8), Vector3.new(0, 0, 1), 30) -- Wind pushes sideways
		-- Section 3: Kill brick sides
		:AddPlatform(Vector3.new(6, 0, 0), Vector3.new(8, 2, 4))
		:AddKillBrick(Vector3.new(6, 0, 4), Vector3.new(8, 3, 2))
		:AddKillBrick(Vector3.new(6, 0, -4), Vector3.new(8, 3, 2))
		-- Section 4: Wall
		:AddPlatform(Vector3.new(14, 0, 0), Vector3.new(10, 2, 6))
		:AddWall(Vector3.new(19, 3, 0), Vector3.new(2, 6, 6), 0)
		-- Final platform
		:AddPlatform(Vector3.new(24, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:SetConnectionPoints(
			Vector3.new(-19, 1, 0),
			Vector3.new(27, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_11: FLOATING MICRO ISLANDS
-- ============================================================================

function HardSections.FloatingMicroIslands()
	--[[
		Tiny platforms (3x3) scattered in space.
		Extreme precision required.
		WEEK 9: Platforms 3, 5, 7 are FALLING PLATFORMS (speed required!)

		Difficulty: 8/10
		Platform Size: 3x3 (micro)
		Platforms: 8
		Spacing: Large gaps (7-9 studs)
		Hazards: Falling platforms (must move quickly!)
	--]]

	return SectionBuilder.new("Hard_FloatingMicroIslands", "Hard")
		-- Platform 1 (safe start)
		:AddPlatform(Vector3.new(-14, 0, 0), Vector3.new(5, 2, 5))
		-- Platform 2
		:AddPlatform(Vector3.new(-9, 0, 3), Vector3.new(3, 2, 3))
		-- Platform 3 FALLING
		:AddFallingPlatform(Vector3.new(-4, 0, -3), Vector3.new(3, 2, 3), 0.6)
		-- Platform 4
		:AddPlatform(Vector3.new(1, 0, 2), Vector3.new(3, 2, 3))
		-- Platform 5 FALLING
		:AddFallingPlatform(Vector3.new(6, 0, -2), Vector3.new(3, 2, 3), 0.6)
		-- Platform 6
		:AddPlatform(Vector3.new(11, 0, 1), Vector3.new(3, 2, 3))
		-- Platform 7 FALLING
		:AddFallingPlatform(Vector3.new(16, 0, -1), Vector3.new(3, 2, 3), 0.6)
		-- Platform 8 (safe landing)
		:AddPlatform(Vector3.new(20, 0, 0), Vector3.new(5, 2, 5))
		:AddCheckpoint(Vector3.new(-14, 4, 0))
		:AddKillBrick(Vector3.new(3, -8, 0), Vector3.new(45, 2, 25))
		-- Visual guides (yellow = safe, red = falling)
		:AddDecoration(Vector3.new(3, 5, 0), Vector3.new(1, 8, 1), "Cylinder", Color3.fromRGB(255, 100, 100))
		:Build()
end

-- ============================================================================
-- HARD_12: UPWARD SPIRAL GAUNTLET
-- ============================================================================

function HardSections.UpwardSpiralGauntlet()
	--[[
		Tight spiral going up with narrow platforms.
		Combines height, rotation, and precision.

		Difficulty: 8/10
		Height Gain: 18 studs
		Platform Width: 4 studs
		Turns: 540° (1.5 rotations)
	--]]

	return SectionBuilder.new("Hard_UpwardSpiralGauntlet", "Hard")
		-- Create tight spiral (1.5 rotations = 9 platforms)
		:AddPlatform(Vector3.new(-6, 0, 0), Vector3.new(5, 2, 5))
		:AddPlatform(Vector3.new(-3, 2, 5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(3, 4, 5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(6, 6, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(3, 8, -5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(-3, 10, -5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(-6, 12, 0), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(-3, 14, 5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(3, 16, 5), Vector3.new(4, 2, 4))
		:AddPlatform(Vector3.new(6, 18, 0), Vector3.new(5, 2, 5))
		:AddCheckpoint(Vector3.new(-6, 4, 0))
		:AddKillBrick(Vector3.new(0, -5, 0), Vector3.new(20, 2, 20))
		:SetConnectionPoints(
			Vector3.new(-9, 1, 0),
			Vector3.new(9, 19, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_13: PENDULUM PLATFORMS
-- ============================================================================

function HardSections.PendulumPlatforms()
	--[[
		Moving platforms swinging like pendulums.
		Must time jumps with swing motion.

		Difficulty: 8/10
		Moving Platforms: 4 (swinging motion)
		Pattern: Alternating swing directions
	--]]

	return SectionBuilder.new("Hard_PendulumPlatforms", "Hard")
		-- Starting platform
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 8))
		-- Pendulum platform 1 (swings left-right)
		:AddMovingPlatform(
			Vector3.new(-8, 0, -6),
			Vector3.new(-8, 0, 6),
			Vector3.new(5, 2, 5),
			6
		)
		-- Pendulum platform 2 (swings right-left, offset)
		:AddMovingPlatform(
			Vector3.new(0, 0, 6),
			Vector3.new(0, 0, -6),
			Vector3.new(5, 2, 5),
			6
		)
		-- Pendulum platform 3 (swings left-right)
		:AddMovingPlatform(
			Vector3.new(8, 0, -6),
			Vector3.new(8, 0, 6),
			Vector3.new(5, 2, 5),
			6
		)
		-- Landing platform
		:AddPlatform(Vector3.new(15, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:AddKillBrick(Vector3.new(0, -8, 0), Vector3.new(40, 2, 25))
		:Build()
end

-- ============================================================================
-- HARD_14: INVERSE STAIRCASE
-- ============================================================================

function HardSections.InverseStaircase()
	--[[
		Platforms getting SMALLER as you climb.
		Psychological difficulty + precision.

		Difficulty: 7/10
		Pattern: 8x8 → 6x6 → 4x4 → 3x3
		Height Gain: 12 studs
		Requires: Confidence + precision
	--]]

	return SectionBuilder.new("Hard_InverseStaircase", "Hard")
		-- Step 1 (largest - 8x8)
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(8, 2, 8))
		-- Step 2 (6x6)
		:AddPlatform(Vector3.new(-6, 3, 0), Vector3.new(6, 2, 6))
		-- Step 3 (5x5)
		:AddPlatform(Vector3.new(0, 6, 0), Vector3.new(5, 2, 5))
		-- Step 4 (4x4)
		:AddPlatform(Vector3.new(6, 9, 0), Vector3.new(4, 2, 4))
		-- Step 5 (smallest - 3x3)
		:AddPlatform(Vector3.new(12, 12, 0), Vector3.new(3, 2, 3))
		-- Final platform (relief - 8x8 again)
		:AddPlatform(Vector3.new(18, 12, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-12, 4, 0))
		:AddKillBrick(Vector3.new(3, -5, 0), Vector3.new(40, 2, 20))
		:SetConnectionPoints(
			Vector3.new(-15, 1, 0),
			Vector3.new(21, 13, 0)
		)
		:Build()
end

-- ============================================================================
-- HARD_15: THE FINAL APPROACH
-- ============================================================================

function HardSections.TheFinalApproach()
	--[[
		Combination challenge: gaps, walls, moving platforms.
		Tests all skills learned so far.
		WEEK 9: HARD FINALE - Ice + Wind + Spikes ALL HAZARDS!

		Difficulty: 8/10
		Features: All mechanics
		Length: Extra long
		Checkpoints: 2 (mid and end)
		Hazards: ICE + WIND + SPIKES (Ultimate Hard challenge!)
	--]]

	return SectionBuilder.new("Hard_TheFinalApproach", "Hard")
		-- Section 1: Large gap WITH SPIKES
		:AddPlatform(Vector3.new(-20, 0, 0), Vector3.new(8, 2, 6))
		:AddPlatform(Vector3.new(-10, 0, 0), Vector3.new(6, 2, 6))
		:AddSpikes(Vector3.new(-10, 2.5, 0), Vector3.new(3, 2, 3), false) -- Spikes on landing
		-- Section 2: Wall obstacle WITH WIND
		:AddPlatform(Vector3.new(-4, 0, 0), Vector3.new(8, 2, 8))
		:AddWall(Vector3.new(0, 3, 0), Vector3.new(2, 6, 8), 0)
		:AddWindZone(Vector3.new(0, 4, 0), Vector3.new(8, 8, 10), Vector3.new(1, 0, 0), 25) -- Wind pushes at wall
		-- Mid checkpoint (SAFE ZONE)
		:AddPlatform(Vector3.new(4, 0, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(4, 4, 0))
		-- Section 3: Moving platform WITH ICE
		:AddMovingPlatform(
			Vector3.new(10, 0, -4),
			Vector3.new(10, 0, 4),
			Vector3.new(6, 2, 6),
			5
		)
		-- Section 4: Narrow bridge WITH ICE (EXTREME!)
		:AddIce(Vector3.new(16, 0, 0), Vector3.new(8, 2, 3)) -- Narrow + slippery!
		-- Section 5: Final gap WITH WIND + SPIKES (ULTIMATE!)
		:AddWindZone(Vector3.new(20, 4, 0), Vector3.new(8, 8, 8), Vector3.new(0, 0, -1), 30) -- Cross-wind
		:AddPlatform(Vector3.new(24, 0, 0), Vector3.new(10, 2, 10))
		:AddSpikes(Vector3.new(24, 2.5, 0), Vector3.new(4, 2, 4), false) -- Spikes on final platform
		:AddKillBrick(Vector3.new(2, -8, 0), Vector3.new(50, 2, 25))
		:SetConnectionPoints(
			Vector3.new(-23, 1, 0),
			Vector3.new(28, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- TEMPLATE REGISTRY
-- ============================================================================

return {
	LargeGap = HardSections.LargeGap,
	MovingPlatformSequence = HardSections.MovingPlatformSequence,
	PrecisionPlatforming = HardSections.PrecisionPlatforming,
	VerticalWallClimb = HardSections.VerticalWallClimb,
	DiagonalLeapSequence = HardSections.DiagonalLeapSequence,
	GauntletOfDeath = HardSections.GauntletOfDeath,
	JumpPadGauntlet = HardSections.JumpPadGauntlet,
	SpiralDescent = HardSections.SpiralDescent,
	AlternatingWallJumps = HardSections.AlternatingWallJumps,
	TimedObstacleCourse = HardSections.TimedObstacleCourse,
	FloatingMicroIslands = HardSections.FloatingMicroIslands,
	UpwardSpiralGauntlet = HardSections.UpwardSpiralGauntlet,
	PendulumPlatforms = HardSections.PendulumPlatforms,
	InverseStaircase = HardSections.InverseStaircase,
	TheFinalApproach = HardSections.TheFinalApproach,
}
