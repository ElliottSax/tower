--[[
	SectionTemplates.lua
	Pre-designed section templates for each dimension

	Each template defines:
	- Layout pattern
	- Mechanic placements
	- Difficulty parameters
	- Visual theme elements

	Templates are used by SectionBuilder for variety in generated levels
]]

local SectionTemplates = {}

-- ============================================================================
-- GRAVITY DIMENSION TEMPLATES
-- ============================================================================

SectionTemplates.Gravity = {
	-- Template 1: Simple Up-Down
	SimpleUpDown = {
		Difficulty = "Easy",
		Description = "Basic gravity flip introduction",
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(15, 2, 15)},
			{Offset = Vector3.new(0, 10, 25), Size = Vector3.new(12, 2, 12)},
			{Offset = Vector3.new(0, 0, 50), Size = Vector3.new(15, 2, 15)},
		},
		GravityZones = {
			{Offset = Vector3.new(0, 5, 35), Size = Vector3.new(10, 10, 5), Direction = Vector3.new(0, -1, 0)},
		},
	},

	-- Template 2: Wall Walk
	WallWalk = {
		Difficulty = "Medium",
		Description = "Walk on walls with horizontal gravity",
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(15, 2, 15)},
			{Offset = Vector3.new(15, 10, 25), Size = Vector3.new(2, 15, 15), Rotation = CFrame.Angles(0, 0, math.rad(90))},
			{Offset = Vector3.new(0, 20, 50), Size = Vector3.new(15, 2, 15)},
		},
		GravityZones = {
			{Offset = Vector3.new(8, 5, 15), Size = Vector3.new(5, 10, 10), Direction = Vector3.new(1, 0, 0)},
			{Offset = Vector3.new(8, 15, 40), Size = Vector3.new(5, 10, 10), Direction = Vector3.new(0, -1, 0)},
		},
	},

	-- Template 3: Ceiling Run
	CeilingRun = {
		Difficulty = "Medium",
		Description = "Run on the ceiling to avoid gaps",
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(15, 2, 15)},
			{Offset = Vector3.new(0, 30, 25), Size = Vector3.new(30, 2, 40)}, -- Ceiling
			{Offset = Vector3.new(0, 0, 60), Size = Vector3.new(15, 2, 15)},
		},
		GravityZones = {
			{Offset = Vector3.new(0, 15, 10), Size = Vector3.new(10, 10, 5), Direction = Vector3.new(0, 1, 0)}, -- Up
			{Offset = Vector3.new(0, 15, 55), Size = Vector3.new(10, 10, 5), Direction = Vector3.new(0, -1, 0)}, -- Down
		},
	},

	-- Template 4: Multi-Flip Maze
	MultiFlipMaze = {
		Difficulty = "Hard",
		Description = "Navigate through multiple gravity shifts",
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(12, 2, 12)},
			{Offset = Vector3.new(15, 15, 20), Size = Vector3.new(12, 2, 12)},
			{Offset = Vector3.new(0, 30, 40), Size = Vector3.new(12, 2, 12)},
			{Offset = Vector3.new(-15, 15, 60), Size = Vector3.new(12, 2, 12)},
			{Offset = Vector3.new(0, 0, 80), Size = Vector3.new(12, 2, 12)},
		},
		GravityZones = {
			{Offset = Vector3.new(8, 8, 10), Size = Vector3.new(8, 8, 5), Direction = Vector3.new(0, 1, 0)},
			{Offset = Vector3.new(8, 22, 30), Size = Vector3.new(8, 8, 5), Direction = Vector3.new(0, 1, 0)},
			{Offset = Vector3.new(-8, 22, 50), Size = Vector3.new(8, 8, 5), Direction = Vector3.new(0, -1, 0)},
			{Offset = Vector3.new(-8, 8, 70), Size = Vector3.new(8, 8, 5), Direction = Vector3.new(0, -1, 0)},
		},
	},

	-- Template 5: Spiral Ascent
	SpiralAscent = {
		Difficulty = "Expert",
		Description = "Spiral upward with constant gravity changes",
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(15, 10, 15), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(0, 20, 30), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(-15, 30, 45), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(0, 40, 60), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(15, 50, 75), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(0, 60, 90), Size = Vector3.new(15, 2, 15)},
		},
		GravityZones = {
			{Offset = Vector3.new(8, 5, 8), Size = Vector3.new(6, 6, 6), Direction = Vector3.new(0, 1, 0)},
			{Offset = Vector3.new(8, 15, 22), Size = Vector3.new(6, 6, 6), Direction = Vector3.new(-1, 0, 0)},
			{Offset = Vector3.new(-8, 25, 38), Size = Vector3.new(6, 6, 6), Direction = Vector3.new(0, 1, 0)},
			{Offset = Vector3.new(-8, 35, 52), Size = Vector3.new(6, 6, 6), Direction = Vector3.new(1, 0, 0)},
			{Offset = Vector3.new(8, 45, 68), Size = Vector3.new(6, 6, 6), Direction = Vector3.new(0, -1, 0)},
		},
	},
}

-- ============================================================================
-- TINY DIMENSION TEMPLATES
-- ============================================================================

SectionTemplates.Tiny = {
	-- Template 1: Desktop Dash
	DesktopDash = {
		Difficulty = "Easy",
		Description = "Run across a giant desk",
		Scale = 0.5,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(40, 4, 80), Material = "Wood"}, -- Desk surface
		},
		Obstacles = {
			{Type = "Pencil", Offset = Vector3.new(10, 2, 20)},
			{Type = "Button", Offset = Vector3.new(-15, 2, 40)},
			{Type = "Book", Offset = Vector3.new(5, 2, 60)},
		},
		ScaleZones = {
			{Offset = Vector3.new(0, 4, 5), Size = Vector3.new(10, 8, 5), TargetScale = 0.5},
		},
	},

	-- Template 2: Kitchen Adventure
	KitchenAdventure = {
		Difficulty = "Medium",
		Description = "Navigate giant kitchen items",
		Scale = 0.25,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(30, 2, 30)}, -- Plate
			{Offset = Vector3.new(0, 20, 40), Size = Vector3.new(15, 60, 15)}, -- Cup (climbbale)
			{Offset = Vector3.new(0, 0, 80), Size = Vector3.new(50, 3, 50)}, -- Cutting board
		},
		ScaleZones = {
			{Offset = Vector3.new(0, 4, 5), Size = Vector3.new(10, 10, 5), TargetScale = 0.25},
		},
	},

	-- Template 3: Garden Trek
	GardenTrek = {
		Difficulty = "Medium",
		Description = "Travel through oversized plants",
		Scale = 0.25,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(20, 2, 20), Material = "Grass"},
			{Offset = Vector3.new(10, 10, 30), Size = Vector3.new(30, 3, 8), Material = "Fabric"}, -- Leaf
			{Offset = Vector3.new(-10, 20, 60), Size = Vector3.new(25, 3, 8), Material = "Fabric"}, -- Leaf
			{Offset = Vector3.new(0, 5, 90), Size = Vector3.new(25, 2, 25), Material = "Grass"},
		},
		ScaleZones = {
			{Offset = Vector3.new(0, 4, 5), Size = Vector3.new(10, 10, 5), TargetScale = 0.25},
		},
	},

	-- Template 4: Toy Room
	ToyRoom = {
		Difficulty = "Hard",
		Description = "Tiny among giant toys",
		Scale = 0.1,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(15, 2, 15)},
			{Offset = Vector3.new(20, 15, 30), Size = Vector3.new(60, 10, 60)}, -- Toy block
			{Offset = Vector3.new(-20, 30, 70), Size = Vector3.new(40, 8, 40)}, -- Another block
			{Offset = Vector3.new(0, 10, 110), Size = Vector3.new(20, 2, 20)},
		},
		ScaleZones = {
			{Offset = Vector3.new(0, 4, 5), Size = Vector3.new(10, 10, 5), TargetScale = 0.1},
		},
	},

	-- Template 5: Micro World
	MicroWorld = {
		Difficulty = "Expert",
		Description = "Smallest scale - massive obstacles",
		Scale = 0.05,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(10, 2, 10)},
			{Offset = Vector3.new(0, 50, 50), Size = Vector3.new(100, 5, 100)}, -- Coin (giant)
			{Offset = Vector3.new(0, 100, 120), Size = Vector3.new(200, 20, 50)}, -- Ruler
			{Offset = Vector3.new(0, 50, 180), Size = Vector3.new(15, 2, 15)},
		},
		ScaleZones = {
			{Offset = Vector3.new(0, 4, 5), Size = Vector3.new(10, 10, 5), TargetScale = 0.05},
		},
	},
}

-- ============================================================================
-- VOID DIMENSION TEMPLATES
-- ============================================================================

SectionTemplates.Void = {
	-- Template 1: Simple Escape
	SimpleEscape = {
		Difficulty = "Easy",
		Description = "Run from the void on stable platforms",
		VoidSpeed = 12,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(15, 2, 15), Crumbles = false}, -- Safe start
			{Offset = Vector3.new(0, 0, 25), Size = Vector3.new(12, 2, 12), Crumbles = true, Delay = 3},
			{Offset = Vector3.new(0, 0, 50), Size = Vector3.new(12, 2, 12), Crumbles = true, Delay = 3},
			{Offset = Vector3.new(0, 0, 75), Size = Vector3.new(12, 2, 12), Crumbles = true, Delay = 3},
			{Offset = Vector3.new(0, 0, 100), Size = Vector3.new(15, 2, 15), Crumbles = false}, -- Safe end
		},
		SafeZones = {
			{Offset = Vector3.new(0, 1, 0), Size = Vector3.new(15, 1, 15)},
			{Offset = Vector3.new(0, 1, 100), Size = Vector3.new(15, 1, 15)},
		},
	},

	-- Template 2: Zigzag Sprint
	ZigzagSprint = {
		Difficulty = "Medium",
		Description = "Zigzag path with crumbling platforms",
		VoidSpeed = 18,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(12, 2, 12), Crumbles = false},
			{Offset = Vector3.new(15, 0, 20), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2.5},
			{Offset = Vector3.new(-15, 0, 40), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2.5},
			{Offset = Vector3.new(15, 0, 60), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2.5},
			{Offset = Vector3.new(-15, 0, 80), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2.5},
			{Offset = Vector3.new(0, 0, 100), Size = Vector3.new(12, 2, 12), Crumbles = false},
		},
		SafeZones = {
			{Offset = Vector3.new(0, 1, 0), Size = Vector3.new(12, 1, 12)},
			{Offset = Vector3.new(0, 1, 100), Size = Vector3.new(12, 1, 12)},
		},
	},

	-- Template 3: Leap of Faith
	LeapOfFaith = {
		Difficulty = "Medium",
		Description = "Platforming with height changes",
		VoidSpeed = 18,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(12, 2, 12), Crumbles = false},
			{Offset = Vector3.new(0, 10, 25), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2},
			{Offset = Vector3.new(0, 20, 50), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2},
			{Offset = Vector3.new(0, 10, 75), Size = Vector3.new(10, 2, 10), Crumbles = true, Delay = 2},
			{Offset = Vector3.new(0, 0, 100), Size = Vector3.new(12, 2, 12), Crumbles = false},
		},
		SafeZones = {
			{Offset = Vector3.new(0, 1, 0), Size = Vector3.new(12, 1, 12)},
			{Offset = Vector3.new(0, 1, 100), Size = Vector3.new(12, 1, 12)},
		},
	},

	-- Template 4: Crumble Cascade
	CrumbleCascade = {
		Difficulty = "Hard",
		Description = "Rapidly crumbling platforms",
		VoidSpeed = 25,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(10, 2, 10), Crumbles = false},
			{Offset = Vector3.new(8, 0, 15), Size = Vector3.new(8, 2, 8), Crumbles = true, Delay = 1.5},
			{Offset = Vector3.new(-8, 0, 30), Size = Vector3.new(8, 2, 8), Crumbles = true, Delay = 1.5},
			{Offset = Vector3.new(8, 0, 45), Size = Vector3.new(8, 2, 8), Crumbles = true, Delay = 1.5},
			{Offset = Vector3.new(-8, 0, 60), Size = Vector3.new(8, 2, 8), Crumbles = true, Delay = 1.5},
			{Offset = Vector3.new(8, 0, 75), Size = Vector3.new(8, 2, 8), Crumbles = true, Delay = 1.5},
			{Offset = Vector3.new(0, 0, 90), Size = Vector3.new(10, 2, 10), Crumbles = false},
		},
		SafeZones = {
			{Offset = Vector3.new(0, 1, 0), Size = Vector3.new(10, 1, 10)},
			{Offset = Vector3.new(0, 1, 90), Size = Vector3.new(10, 1, 10)},
		},
	},

	-- Template 5: Void Gauntlet
	VoidGauntlet = {
		Difficulty = "Expert",
		Description = "The ultimate void challenge",
		VoidSpeed = 35,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Size = Vector3.new(8, 2, 8), Crumbles = false},
			{Offset = Vector3.new(10, 5, 12), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(-10, 10, 24), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(10, 5, 36), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(-10, 10, 48), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(10, 5, 60), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(-10, 10, 72), Size = Vector3.new(6, 2, 6), Crumbles = true, Delay = 1},
			{Offset = Vector3.new(0, 0, 85), Size = Vector3.new(8, 2, 8), Crumbles = false},
		},
		SafeZones = {
			{Offset = Vector3.new(0, 1, 0), Size = Vector3.new(8, 1, 8)},
			{Offset = Vector3.new(0, 1, 85), Size = Vector3.new(8, 1, 8)},
		},
	},
}

-- ============================================================================
-- SKY DIMENSION TEMPLATES
-- ============================================================================

SectionTemplates.Sky = {
	-- Template 1: Cloud Hopping
	CloudHopping = {
		Difficulty = "Easy",
		Description = "Jump between fluffy clouds",
		GapDistance = 30,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Type = "Island", Radius = 15},
			{Offset = Vector3.new(10, 5, 40), Type = "Cloud", Size = Vector3.new(20, 6, 20)},
			{Offset = Vector3.new(-10, 10, 80), Type = "Cloud", Size = Vector3.new(18, 5, 18)},
			{Offset = Vector3.new(0, 15, 120), Type = "Island", Radius = 12},
		},
		WindCurrents = {
			{Offset = Vector3.new(5, 5, 60), Size = Vector3.new(15, 25, 15), Direction = Vector3.new(0, 0.5, 1), Strength = 20},
		},
		Updrafts = {
			{Offset = Vector3.new(-5, 5, 100), Size = Vector3.new(12, 40, 12), Strength = 50},
		},
	},

	-- Template 2: Glider Run
	GliderRun = {
		Difficulty = "Medium",
		Description = "Use glider to cross large gaps",
		GapDistance = 80,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Type = "Island", Radius = 18},
			{Offset = Vector3.new(0, -10, 100), Type = "Cloud", Size = Vector3.new(25, 8, 25)},
			{Offset = Vector3.new(0, 0, 200), Type = "Island", Radius = 15},
		},
		WindCurrents = {
			{Offset = Vector3.new(0, 10, 50), Size = Vector3.new(30, 50, 40), Direction = Vector3.new(0, 0.3, 1), Strength = 35},
			{Offset = Vector3.new(0, 10, 150), Size = Vector3.new(30, 50, 40), Direction = Vector3.new(0, 0.3, 1), Strength = 35},
		},
		Updrafts = {
			{Offset = Vector3.new(0, 0, 100), Size = Vector3.new(20, 60, 20), Strength = 70},
		},
	},

	-- Template 3: Wind Tunnel
	WindTunnel = {
		Difficulty = "Medium",
		Description = "Navigate strong wind currents",
		GapDistance = 60,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Type = "Island", Radius = 15},
			{Offset = Vector3.new(30, 0, 60), Type = "Cloud", Size = Vector3.new(15, 5, 15)},
			{Offset = Vector3.new(-30, 0, 120), Type = "Cloud", Size = Vector3.new(15, 5, 15)},
			{Offset = Vector3.new(0, 0, 180), Type = "Island", Radius = 15},
		},
		WindCurrents = {
			{Offset = Vector3.new(15, 0, 30), Size = Vector3.new(20, 30, 30), Direction = Vector3.new(1, 0, 0.5), Strength = 40},
			{Offset = Vector3.new(-15, 0, 90), Size = Vector3.new(20, 30, 30), Direction = Vector3.new(-1, 0, 0.5), Strength = 40},
			{Offset = Vector3.new(15, 0, 150), Size = Vector3.new(20, 30, 30), Direction = Vector3.new(1, 0, 0.5), Strength = 40},
		},
	},

	-- Template 4: Thermal Climbing
	ThermalClimbing = {
		Difficulty = "Hard",
		Description = "Use updrafts to climb high",
		GapDistance = 100,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Type = "Island", Radius = 12},
			{Offset = Vector3.new(20, 50, 80), Type = "Cloud", Size = Vector3.new(12, 4, 12)},
			{Offset = Vector3.new(-20, 100, 160), Type = "Cloud", Size = Vector3.new(12, 4, 12)},
			{Offset = Vector3.new(0, 150, 240), Type = "Island", Radius = 15},
		},
		Updrafts = {
			{Offset = Vector3.new(10, 25, 40), Size = Vector3.new(15, 80, 15), Strength = 80},
			{Offset = Vector3.new(-10, 75, 120), Size = Vector3.new(15, 80, 15), Strength = 80},
			{Offset = Vector3.new(0, 125, 200), Size = Vector3.new(15, 80, 15), Strength = 80},
		},
		WindCurrents = {
			{Offset = Vector3.new(0, 50, 80), Size = Vector3.new(40, 20, 20), Direction = Vector3.new(-1, 0.2, 0), Strength = 50},
			{Offset = Vector3.new(0, 100, 160), Size = Vector3.new(40, 20, 20), Direction = Vector3.new(1, 0.2, 0), Strength = 50},
		},
	},

	-- Template 5: Storm Chase
	StormChase = {
		Difficulty = "Expert",
		Description = "Navigate through chaotic winds",
		GapDistance = 150,
		Platforms = {
			{Offset = Vector3.new(0, 0, 0), Type = "Island", Radius = 10},
			{Offset = Vector3.new(40, 30, 100), Type = "Cloud", Size = Vector3.new(10, 4, 10)},
			{Offset = Vector3.new(-40, 60, 200), Type = "Cloud", Size = Vector3.new(10, 4, 10)},
			{Offset = Vector3.new(40, 30, 300), Type = "Cloud", Size = Vector3.new(10, 4, 10)},
			{Offset = Vector3.new(0, 0, 400), Type = "Island", Radius = 15},
		},
		Updrafts = {
			{Offset = Vector3.new(20, 15, 50), Size = Vector3.new(12, 60, 12), Strength = 90},
			{Offset = Vector3.new(-20, 45, 150), Size = Vector3.new(12, 60, 12), Strength = 90},
			{Offset = Vector3.new(20, 15, 250), Size = Vector3.new(12, 60, 12), Strength = 90},
			{Offset = Vector3.new(0, 0, 350), Size = Vector3.new(15, 50, 15), Strength = 100},
		},
		WindCurrents = {
			{Offset = Vector3.new(30, 30, 75), Size = Vector3.new(25, 40, 25), Direction = Vector3.new(-0.5, 0.5, 0.5), Strength = 60},
			{Offset = Vector3.new(-30, 60, 175), Size = Vector3.new(25, 40, 25), Direction = Vector3.new(0.5, 0.2, 0.5), Strength = 60},
			{Offset = Vector3.new(30, 30, 275), Size = Vector3.new(25, 40, 25), Direction = Vector3.new(-0.5, 0.5, 0.5), Strength = 70},
		},
	},
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function SectionTemplates.GetTemplatesForDimension(dimension: string): table
	return SectionTemplates[dimension] or {}
end

function SectionTemplates.GetTemplatesByDifficulty(dimension: string, difficulty: string): table
	local templates = SectionTemplates[dimension]
	if not templates then return {} end

	local result = {}
	for name, template in pairs(templates) do
		if template.Difficulty == difficulty then
			result[name] = template
		end
	end
	return result
end

function SectionTemplates.GetRandomTemplate(dimension: string, difficulty: string?): (string, table)?
	local templates = difficulty
		and SectionTemplates.GetTemplatesByDifficulty(dimension, difficulty)
		or SectionTemplates[dimension]

	if not templates then return nil end

	local names = {}
	for name in pairs(templates) do
		table.insert(names, name)
	end

	if #names == 0 then return nil end

	local randomName = names[math.random(1, #names)]
	return randomName, templates[randomName]
end

return SectionTemplates
