--[[
	ExpertSections.lua
	Template definitions for Expert difficulty sections (Sections 46-50)

	Design Guidelines:
	- Extreme precision required (pixel-perfect jumps)
	- All upgrades REQUIRED (DoubleJump, AirDash, WallGrip, SpeedBoost)
	- Combination of multiple mechanics
	- Very narrow platforms (2-4 studs)
	- Very large gaps (12+ studs)
	- Multi-stage challenges
	- High-risk environments (instant death)
	- "Final boss" difficulty

	Section Count: 10 templates
	Usage: Randomly selected for tower sections 46-50

	Week 7: Initial implementation
--]]

local SectionBuilder = require(script.Parent.Parent.Utilities.SectionBuilder)

local ExpertSections = {}

-- ============================================================================
-- EXPERT_01: THE IMPOSSIBLE GAP
-- ============================================================================

function ExpertSections.TheImpossibleGap()
	--[[
		15-stud gap requiring DoubleJump + AirDash.
		Impossible without upgrades.
		WEEK 9: LAVA BELOW GAP - Instant death if you fall!

		Difficulty: 9/10
		Gap Size: 15 studs
		Platform Width: 4 studs
		Required: DoubleJump + AirDash (mandatory)
		Hazards: LAVA POOL below gap (instant death)
	--]]

	return SectionBuilder.new("Expert_TheImpossibleGap", "Expert")
		-- Starting platform
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 4))
		-- MASSIVE gap (15 studs)
		:AddGap(Vector3.new(-11, 0, 0), Vector3.new(4, 0, 0))
		-- LAVA POOL BELOW GAP (instant death!)
		:AddLava(Vector3.new(0, -8, 0), Vector3.new(30, 3, 20))
		-- Landing platform (small)
		:AddPlatform(Vector3.new(15, 0, 0), Vector3.new(8, 2, 4))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		-- Kill brick deeper abyss
		:AddKillBrick(Vector3.new(0, -20, 0), Vector3.new(40, 2, 20))
		-- Warning decorations (orange for lava)
		:AddDecoration(Vector3.new(0, 5, 0), Vector3.new(2, 2, 2), "Sphere", Color3.fromRGB(255, 100, 0))
		:Build()
end

-- ============================================================================
-- EXPERT_02: ULTRA NARROW GAUNTLET
-- ============================================================================

function ExpertSections.UltraNarrowGauntlet()
	--[[
		1-stud wide path for 40 studs.
		One pixel off = death.
		WEEK 9: LAVA ON BOTH SIDES - Pixel-perfect or die!

		Difficulty: 10/10
		Width: 1 stud (single block)
		Length: 40 studs
		Difficulty: Extreme precision
		Hazards: LAVA ON BOTH SIDES + BELOW (instant death!)
	--]]

	return SectionBuilder.new("Expert_UltraNarrowGauntlet", "Expert")
		-- Ultra-thin platform (1 stud wide!)
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(40, 2, 1))
		-- LAVA ON BOTH SIDES (instant death!)
		:AddLava(Vector3.new(0, 0, 5), Vector3.new(40, 4, 8))
		:AddLava(Vector3.new(0, 0, -5), Vector3.new(40, 4, 8))
		-- LAVA BELOW
		:AddLava(Vector3.new(0, -6, 0), Vector3.new(40, 3, 20))
		-- Kill brick even deeper
		:AddKillBrick(Vector3.new(0, -15, 0), Vector3.new(40, 2, 25))
		:AddCheckpoint(Vector3.new(-20, 4, 0))
		-- Orange warning lights (lava color)
		:AddDecoration(Vector3.new(-15, 3, 0), Vector3.new(0.5, 0.5, 0.5), "Sphere", Color3.fromRGB(255, 100, 0))
		:AddDecoration(Vector3.new(0, 3, 0), Vector3.new(0.5, 0.5, 0.5), "Sphere", Color3.fromRGB(255, 100, 0))
		:AddDecoration(Vector3.new(15, 3, 0), Vector3.new(0.5, 0.5, 0.5), "Sphere", Color3.fromRGB(255, 100, 0))
		:Build()
end

-- ============================================================================
-- EXPERT_03: TRIPLE SPIRAL ASCENT
-- ============================================================================

function ExpertSections.TripleSpiralAscent()
	--[[
		Three complete 360° spirals stacked vertically.
		30 studs vertical climb.
		WEEK 9: EVERY OTHER PLATFORM FALLS (speed climbing required!)

		Difficulty: 9/10
		Height Gain: 30 studs
		Rotations: 3 full circles (1080°)
		Platforms: 18 (9 stable, 9 falling)
		Hazards: FALLING PLATFORMS (must climb quickly!)
	--]]

	local builder = SectionBuilder.new("Expert_TripleSpiralAscent", "Expert")

	-- Generate 3 spirals (6 platforms per spiral)
	local platformCount = 0
	for spiral = 0, 2 do
		local baseHeight = spiral * 10
		for i = 0, 5 do
			local angle = (i / 6) * math.pi * 2
			local radius = 6
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = baseHeight + (i * 1.5)

			-- Every other platform is FALLING!
			if platformCount % 2 == 1 then
				builder:AddFallingPlatform(
					Vector3.new(x, y, z),
					Vector3.new(4, 2, 4),
					0.5 -- Falls after 0.5 seconds
				)
			else
				builder:AddPlatform(
					Vector3.new(x, y, z),
					Vector3.new(4, 2, 4)
				)
			end
			platformCount = platformCount + 1
		end
	end

	-- Final platform at top (safe landing)
	return builder
		:AddPlatform(Vector3.new(0, 30, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(6, 2, 0))
		:AddKillBrick(Vector3.new(0, -5, 0), Vector3.new(25, 2, 25))
		:SetConnectionPoints(
			Vector3.new(6, 1, 0),
			Vector3.new(0, 31, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_04: MOVING PLATFORM HELL
-- ============================================================================

function ExpertSections.MovingPlatformHell()
	--[[
		6 moving platforms, all moving differently.
		Requires perfect timing across all jumps.
		WEEK 9: LAVA BELOW ALL PLATFORMS - No safety net!

		Difficulty: 9/10
		Moving Platforms: 6
		Patterns: Different speeds and directions
		Required: Perfect timing + AirDash
		Hazards: LAVA SEA below (instant death if you fall!)
	--]]

	return SectionBuilder.new("Expert_MovingPlatformHell", "Expert")
		-- Starting platform
		:AddPlatform(Vector3.new(-20, 0, 0), Vector3.new(8, 2, 8))
		-- Moving platform 1 (slow horizontal)
		:AddMovingPlatform(
			Vector3.new(-12, 0, -6),
			Vector3.new(-12, 0, 6),
			Vector3.new(4, 2, 4),
			3
		)
		-- Moving platform 2 (fast horizontal, opposite)
		:AddMovingPlatform(
			Vector3.new(-6, 0, 6),
			Vector3.new(-6, 0, -6),
			Vector3.new(4, 2, 4),
			7
		)
		-- Moving platform 3 (vertical)
		:AddMovingPlatform(
			Vector3.new(0, 0, 0),
			Vector3.new(0, 6, 0),
			Vector3.new(4, 2, 4),
			4
		)
		-- Moving platform 4 (diagonal)
		:AddMovingPlatform(
			Vector3.new(6, 0, -4),
			Vector3.new(6, 4, 4),
			Vector3.new(4, 2, 4),
			5
		)
		-- Moving platform 5 (fast horizontal)
		:AddMovingPlatform(
			Vector3.new(12, 0, 6),
			Vector3.new(12, 0, -6),
			Vector3.new(4, 2, 4),
			8
		)
		-- Moving platform 6 (slow horizontal)
		:AddMovingPlatform(
			Vector3.new(18, 0, -6),
			Vector3.new(18, 0, 6),
			Vector3.new(4, 2, 4),
			3
		)
		-- Landing platform
		:AddPlatform(Vector3.new(24, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-20, 4, 0))
		-- MASSIVE LAVA SEA BELOW (instant death!)
		:AddLava(Vector3.new(2, -8, 0), Vector3.new(55, 4, 30))
		-- Kill brick even deeper
		:AddKillBrick(Vector3.new(2, -20, 0), Vector3.new(55, 2, 30))
		:SetConnectionPoints(
			Vector3.new(-23, 1, 0),
			Vector3.new(27, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_05: THE VOID WALKER
-- ============================================================================

function ExpertSections.TheVoidWalker()
	--[[
		Tiny platforms (2x2) scattered in void.
		12+ stud gaps between each platform.

		Difficulty: 10/10
		Platform Size: 2x2 (absolutely tiny)
		Gaps: 12-14 studs
		Platforms: 10
		Required: All upgrades + perfect precision
	--]]

	return SectionBuilder.new("Expert_TheVoidWalker", "Expert")
		-- Starting platform (slightly larger)
		:AddPlatform(Vector3.new(-18, 0, 0), Vector3.new(6, 2, 6))
		-- Micro platforms with huge gaps
		:AddPlatform(Vector3.new(-12, 0, 4), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(-5, 0, -3), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(2, 0, 5), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(9, 0, -4), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(16, 0, 2), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(23, 0, -5), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(30, 0, 3), Vector3.new(2, 2, 2))
		:AddPlatform(Vector3.new(37, 0, -2), Vector3.new(2, 2, 2))
		-- Landing platform
		:AddPlatform(Vector3.new(44, 0, 0), Vector3.new(6, 2, 6))
		:AddCheckpoint(Vector3.new(-18, 4, 0))
		:AddKillBrick(Vector3.new(13, -10, 0), Vector3.new(70, 2, 30))
		:SetConnectionPoints(
			Vector3.new(-21, 1, 0),
			Vector3.new(47, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_06: WALL CLIMB EXTREME
-- ============================================================================

function ExpertSections.WallClimbExtreme()
	--[[
		Climb 35 studs using tiny ledges.
		Requires WallGrip Level 3.

		Difficulty: 9/10
		Height Gain: 35 studs
		Ledge Size: 3x3 (tiny)
		Ledges: 12
		Required: WallGrip Level 3
	--]]

	return SectionBuilder.new("Expert_WallClimbExtreme", "Expert")
		-- Bottom platform
		:AddPlatform(Vector3.new(-15, 0, 0), Vector3.new(8, 2, 8))
		-- Massive vertical wall
		:AddWall(Vector3.new(-10, 17, 0), Vector3.new(2, 35, 12), 0)
		-- Tiny ledges (alternating sides)
		:AddPlatform(Vector3.new(-8, 3, -3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 6, 3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 9, -3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 12, 3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 15, -3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 18, 3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 21, -3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 24, 3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 27, -3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 30, 3), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-8, 33, -3), Vector3.new(3, 1, 3))
		-- Top platform
		:AddPlatform(Vector3.new(-5, 35, 0), Vector3.new(10, 2, 10))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:AddKillBrick(Vector3.new(-10, -5, 0), Vector3.new(20, 2, 20))
		:SetConnectionPoints(
			Vector3.new(-18, 1, 0),
			Vector3.new(-2, 36, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_07: SPEED RUN GAUNTLET
-- ============================================================================

function ExpertSections.SpeedRunGauntlet()
	--[[
		Long course requiring SpeedBoost Level 5.
		Must complete quickly or fall behind.
		WEEK 9: ROTATING OBSTACLES in wall slalom (extreme timing!)

		Difficulty: 9/10
		Length: 60 studs
		Features: Gaps, walls, narrow paths
		Required: SpeedBoost Level 5
		Time Pressure: High
		Hazards: ROTATING OBSTACLES at walls (must time dodges!)
	--]]

	return SectionBuilder.new("Expert_SpeedRunGauntlet", "Expert")
		-- Starting platform
		:AddPlatform(Vector3.new(-25, 0, 0), Vector3.new(8, 2, 6))
		-- Section 1: Gap sequence
		:AddPlatform(Vector3.new(-18, 0, 0), Vector3.new(5, 2, 5))
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(5, 2, 5))
		:AddPlatform(Vector3.new(-6, 0, 0), Vector3.new(5, 2, 5))
		-- Section 2: Wall slalom WITH ROTATING OBSTACLES!
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(20, 2, 4))
		:AddWall(Vector3.new(-4, 3, 0), Vector3.new(2, 6, 4), 0)
		:AddRotatingObstacle(Vector3.new(-4, 3, 0), Vector3.new(12, 2, 2), 60) -- Fast rotation at wall 1
		:AddWall(Vector3.new(4, 3, 0), Vector3.new(2, 6, 4), 0)
		:AddRotatingObstacle(Vector3.new(4, 3, 0), Vector3.new(12, 2, 2), 60) -- Fast rotation at wall 2
		:AddWall(Vector3.new(12, 3, 0), Vector3.new(2, 6, 4), 0)
		:AddRotatingObstacle(Vector3.new(12, 3, 0), Vector3.new(12, 2, 2), 60) -- Fast rotation at wall 3
		-- Section 3: Narrow bridge
		:AddPlatform(Vector3.new(25, 0, 0), Vector3.new(15, 2, 2))
		-- Section 4: Final gaps
		:AddPlatform(Vector3.new(36, 0, 0), Vector3.new(5, 2, 5))
		:AddPlatform(Vector3.new(42, 0, 0), Vector3.new(5, 2, 5))
		-- Finish platform
		:AddPlatform(Vector3.new(48, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-25, 4, 0))
		:AddKillBrick(Vector3.new(12, -8, 0), Vector3.new(80, 2, 25))
		:SetConnectionPoints(
			Vector3.new(-28, 1, 0),
			Vector3.new(51, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_08: THE PENDULUM OF DOOM
-- ============================================================================

function ExpertSections.ThePendulumOfDoom()
	--[[
		Moving platforms swinging over kill brick abyss.
		Must jump between swinging platforms.
		WEEK 9: LAVA BELOW SWINGING PLATFORMS - Ultimate danger!

		Difficulty: 10/10
		Moving Platforms: 5 (all swinging)
		Below: LAVA ABYSS
		Required: Perfect timing + AirDash
		Hazards: LAVA below pendulums (instant death!)
	--]]

	return SectionBuilder.new("Expert_ThePendulumOfDoom", "Expert")
		-- Starting platform
		:AddPlatform(Vector3.new(-20, 0, 0), Vector3.new(8, 2, 8))
		-- Swinging platforms (large amplitude)
		:AddMovingPlatform(
			Vector3.new(-12, 0, -10),
			Vector3.new(-12, 0, 10),
			Vector3.new(4, 2, 4),
			7
		)
		:AddMovingPlatform(
			Vector3.new(-5, 0, 10),
			Vector3.new(-5, 0, -10),
			Vector3.new(4, 2, 4),
			7
		)
		:AddMovingPlatform(
			Vector3.new(2, 0, -10),
			Vector3.new(2, 0, 10),
			Vector3.new(4, 2, 4),
			7
		)
		:AddMovingPlatform(
			Vector3.new(9, 0, 10),
			Vector3.new(9, 0, -10),
			Vector3.new(4, 2, 4),
			7
		)
		:AddMovingPlatform(
			Vector3.new(16, 0, -10),
			Vector3.new(16, 0, 10),
			Vector3.new(4, 2, 4),
			7
		)
		-- Landing platform
		:AddPlatform(Vector3.new(24, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-20, 4, 0))
		-- MASSIVE LAVA ABYSS BELOW (instant death!)
		:AddLava(Vector3.new(2, -12, 0), Vector3.new(50, 6, 35))
		-- Kill brick even deeper
		:AddKillBrick(Vector3.new(2, -25, 0), Vector3.new(50, 5, 35))
		:SetConnectionPoints(
			Vector3.new(-23, 1, 0),
			Vector3.new(27, 1, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_09: COMBINATION CHAOS
-- ============================================================================

function ExpertSections.CombinationChaos()
	--[[
		Every mechanic in one section.
		Ultimate skill test.
		WEEK 9: POISON GAS in moving platform section (DoT pressure!)

		Difficulty: 10/10
		Features: ALL mechanics
		- Large gaps
		- Moving platforms
		- Wall climbing
		- Narrow paths
		- Jump pads
		Required: All upgrades + mastery
		Hazards: POISON GAS (damage over time during moving platforms!)
	--]]

	return SectionBuilder.new("Expert_CombinationChaos", "Expert")
		-- Stage 1: Large gap
		:AddPlatform(Vector3.new(-25, 0, 0), Vector3.new(6, 2, 6))
		:AddPlatform(Vector3.new(-14, 0, 0), Vector3.new(5, 2, 5))
		-- Stage 2: Wall climb
		:AddWall(Vector3.new(-8, 8, 0), Vector3.new(2, 16, 8), 0)
		:AddPlatform(Vector3.new(-6, 4, 0), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-6, 8, 0), Vector3.new(3, 1, 3))
		:AddPlatform(Vector3.new(-6, 12, 0), Vector3.new(3, 1, 3))
		-- Stage 3: Jump pad to moving platform WITH POISON GAS!
		:AddPlatform(Vector3.new(-2, 12, 0), Vector3.new(6, 2, 6))
		:AddJumpPad(Vector3.new(1, 14.5, 0), Vector3.new(4, 1, 4))
		:AddPoisonGas(Vector3.new(8, 12, 0), Vector3.new(12, 15, 15)) -- Poison gas around moving platform
		:AddMovingPlatform(
			Vector3.new(8, 12, -6),
			Vector3.new(8, 12, 6),
			Vector3.new(5, 2, 5),
			6
		)
		-- Stage 4: Narrow bridge
		:AddPlatform(Vector3.new(14, 12, 0), Vector3.new(10, 2, 2))
		-- Stage 5: Final gap to finish
		:AddPlatform(Vector3.new(26, 12, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-25, 4, 0))
		:AddKillBrick(Vector3.new(0, -5, 0), Vector3.new(60, 2, 30))
		:SetConnectionPoints(
			Vector3.new(-28, 1, 0),
			Vector3.new(29, 13, 0)
		)
		:Build()
end

-- ============================================================================
-- EXPERT_10: THE FINAL TRIAL
-- ============================================================================

function ExpertSections.TheFinalTrial()
	--[[
		The ultimate challenge.
		Longest, hardest section in the game.
		Tests EVERYTHING.
		WEEK 9: ALL HAZARDS - LAVA + SPIKES + POISON GAS + FALLING PLATFORMS!

		Difficulty: 10/10
		Length: Extra long (70+ studs)
		Checkpoints: 3 (for mercy)
		Features: All mechanics combined
		Required: Perfect mastery of all skills
		Hazards: ULTIMATE - ALL HAZARDS COMBINED!
	--]]

	return SectionBuilder.new("Expert_TheFinalTrial", "Expert")
		-- PHASE 1: Precision Platforming WITH SPIKES!
		:AddPlatform(Vector3.new(-30, 0, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(-30, 4, 0))
		:AddPlatform(Vector3.new(-24, 0, 0), Vector3.new(3, 2, 3))
		:AddSpikes(Vector3.new(-24, 2.5, 0), Vector3.new(1.5, 2, 1.5), false) -- Spikes on platform!
		:AddPlatform(Vector3.new(-18, 0, 0), Vector3.new(3, 2, 3))
		:AddPlatform(Vector3.new(-12, 0, 0), Vector3.new(3, 2, 3))
		:AddSpikes(Vector3.new(-12, 2.5, 0), Vector3.new(1.5, 2, 1.5), false) -- More spikes!

		-- PHASE 2: Moving Platform Maze WITH POISON GAS!
		:AddPlatform(Vector3.new(-6, 0, 0), Vector3.new(6, 2, 6))
		:AddCheckpoint(Vector3.new(-6, 4, 0))
		:AddPoisonGas(Vector3.new(3, 5, 0), Vector3.new(15, 12, 15)) -- Poison gas in maze!
		:AddMovingPlatform(
			Vector3.new(0, 0, -6),
			Vector3.new(0, 0, 6),
			Vector3.new(4, 2, 4),
			6
		)
		:AddMovingPlatform(
			Vector3.new(6, 0, 6),
			Vector3.new(6, 0, -6),
			Vector3.new(4, 2, 4),
			6
		)

		-- PHASE 3: Vertical Ascent WITH FALLING PLATFORMS!
		:AddPlatform(Vector3.new(12, 0, 0), Vector3.new(6, 2, 6))
		:AddWall(Vector3.new(16, 10, 0), Vector3.new(2, 20, 8), 0)
		:AddFallingPlatform(Vector3.new(18, 5, 0), Vector3.new(3, 1, 3), 0.6) -- Falling!
		:AddPlatform(Vector3.new(18, 10, 0), Vector3.new(3, 1, 3))
		:AddFallingPlatform(Vector3.new(18, 15, 0), Vector3.new(3, 1, 3), 0.6) -- Falling!

		-- PHASE 4: Ultra Narrow Bridge WITH SPIKES!
		:AddPlatform(Vector3.new(24, 15, 0), Vector3.new(8, 2, 8))
		:AddCheckpoint(Vector3.new(24, 19, 0))
		:AddPlatform(Vector3.new(32, 15, 0), Vector3.new(15, 2, 1))
		:AddSpikes(Vector3.new(32, 17, 0), Vector3.new(2, 2, 0.5), false) -- Spikes on narrow bridge!

		-- PHASE 5: The Impossible Gap WITH LAVA BELOW!
		:AddPlatform(Vector3.new(42, 15, 0), Vector3.new(5, 2, 5))
		:AddLava(Vector3.new(50, 10, 0), Vector3.new(16, 4, 20)) -- LAVA UNDER GAP!
		:AddPlatform(Vector3.new(58, 15, 0), Vector3.new(10, 2, 10))

		-- VICTORY PLATFORM (safe zone!)
		:AddPlatform(Vector3.new(70, 15, 0), Vector3.new(15, 2, 15))
		:AddCheckpoint(Vector3.new(70, 19, 0))

		-- LAVA SEA BELOW EVERYTHING!
		:AddLava(Vector3.new(20, -8, 0), Vector3.new(120, 5, 40))
		-- Kill brick even deeper
		:AddKillBrick(Vector3.new(20, -20, 0), Vector3.new(120, 2, 40))

		-- Decorations (victory markers)
		:AddDecoration(Vector3.new(70, 20, 0), Vector3.new(3, 3, 3), "Sphere", Color3.fromRGB(255, 215, 0))

		:SetConnectionPoints(
			Vector3.new(-33, 1, 0),
			Vector3.new(77, 16, 0)
		)
		:Build()
end

-- ============================================================================
-- TEMPLATE REGISTRY
-- ============================================================================

return {
	TheImpossibleGap = ExpertSections.TheImpossibleGap,
	UltraNarrowGauntlet = ExpertSections.UltraNarrowGauntlet,
	TripleSpiralAscent = ExpertSections.TripleSpiralAscent,
	MovingPlatformHell = ExpertSections.MovingPlatformHell,
	TheVoidWalker = ExpertSections.TheVoidWalker,
	WallClimbExtreme = ExpertSections.WallClimbExtreme,
	SpeedRunGauntlet = ExpertSections.SpeedRunGauntlet,
	ThePendulumOfDoom = ExpertSections.ThePendulumOfDoom,
	CombinationChaos = ExpertSections.CombinationChaos,
	TheFinalTrial = ExpertSections.TheFinalTrial,
}
