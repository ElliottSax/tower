--[[
	HazardDefinitions.lua
	Defines all environmental hazard types for Tower Ascent

	Hazards add challenge and variety to sections:
	- Lava (instant death)
	- Spikes (damage on touch)
	- Rotating obstacles (moving barriers)
	- Wind zones (push player)
	- Ice (slippery surfaces)
	- Quicksand (slow movement)
	- Poison gas (damage over time)
	- Falling platforms (collapse after stepping)

	Week 9 Implementation
--]]

local HazardDefinitions = {}

-- ============================================================================
-- HAZARD TYPES
-- ============================================================================

--[[
	LAVA
	Instant death on touch
	Visual: Bright orange/red, particle effects
	Theme: Volcano (sections 41-50)
--]]
HazardDefinitions.Lava = {
	Name = "Lava",
	Type = "InstantDeath",

	-- Visual properties
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(255, 100, 0),
	Transparency = 0.3,

	-- Behavior
	Damage = math.huge, -- Instant death
	TouchCooldown = 0, -- No cooldown (instant)

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Fire",
		Color = ColorSequence.new(Color3.fromRGB(255, 150, 0)),
		Size = NumberSequence.new(2, 0),
		Lifetime = NumberRange.new(1, 2),
		Rate = 50,
		Speed = NumberRange.new(5, 10),
		SpreadAngle = Vector2.new(30, 30),
	},

	Sound = {
		SoundId = "rbxassetid://5801257793", -- Lava bubbling
		Volume = 0.3,
		Looped = true,
	},

	-- Glow effect
	Light = {
		Enabled = true,
		Brightness = 2,
		Color = Color3.fromRGB(255, 100, 0),
		Range = 20,
	},
}

--[[
	SPIKES
	Damage on touch, can be retractable
	Visual: Gray metallic spikes
	Theme: All themes (color varies)
--]]
HazardDefinitions.Spikes = {
	Name = "Spikes",
	Type = "Damage",

	-- Visual properties
	Material = Enum.Material.Metal,
	Color = Color3.fromRGB(100, 100, 100),
	Transparency = 0,

	-- Behavior
	Damage = 40, -- High damage but not instant death
	TouchCooldown = 1, -- 1 second cooldown between hits

	-- Retractable variant
	Retractable = {
		Enabled = false, -- Set to true for moving spikes
		ExtendedTime = 2, -- Seconds spikes are out
		RetractedTime = 2, -- Seconds spikes are in
		TransitionTime = 0.3, -- Animation time
	},

	-- Effects
	Particles = {
		Enabled = false, -- No particles for spikes
	},

	Sound = {
		OnTouch = "rbxassetid://9114397505", -- Metal clang
		Volume = 0.5,
	},
}

--[[
	ROTATING OBSTACLE
	Large rotating barrier that pushes players off
	Visual: Large metallic bar
	Theme: Hard/Expert sections
--]]
HazardDefinitions.RotatingObstacle = {
	Name = "RotatingObstacle",
	Type = "Knockback",

	-- Visual properties
	Material = Enum.Material.Metal,
	Color = Color3.fromRGB(150, 150, 150),
	Transparency = 0,

	-- Behavior
	RotationSpeed = 30, -- Degrees per second
	RotationAxis = Vector3.new(0, 1, 0), -- Y-axis (horizontal rotation)
	KnockbackForce = 50, -- Push strength
	Damage = 20, -- Minor damage on hit

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Sparkles",
		Color = ColorSequence.new(Color3.fromRGB(200, 200, 255)),
		Size = NumberSequence.new(0.5),
		Rate = 10,
	},

	Sound = {
		SoundId = "rbxassetid://9114221327", -- Mechanical whirring
		Volume = 0.4,
		Looped = true,
	},
}

--[[
	WIND ZONE
	Invisible zone that pushes player in direction
	Visual: Transparent blue zone with particle effects
	Theme: Snow (sections 31-40)
--]]
HazardDefinitions.WindZone = {
	Name = "WindZone",
	Type = "Force",

	-- Visual properties
	Material = Enum.Material.ForceField,
	Color = Color3.fromRGB(150, 200, 255),
	Transparency = 0.8,

	-- Behavior
	WindForce = 30, -- Push strength
	WindDirection = Vector3.new(1, 0, 0), -- Direction (normalized)
	Damage = 0, -- No damage

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Wind",
		Color = ColorSequence.new(Color3.fromRGB(200, 220, 255)),
		Size = NumberSequence.new(0.3, 0.1),
		Lifetime = NumberRange.new(1, 3),
		Rate = 30,
		Speed = NumberRange.new(10, 20),
		Velocity = Vector3.new(10, 0, 0), -- Wind direction
		SpreadAngle = Vector2.new(5, 5),
	},

	Sound = {
		SoundId = "rbxassetid://9113646183", -- Wind howling
		Volume = 0.3,
		Looped = true,
	},
}

--[[
	ICE (SLIPPERY SURFACE)
	Platform with reduced friction
	Visual: Icy blue material
	Theme: Snow (sections 31-40)
--]]
HazardDefinitions.Ice = {
	Name = "Ice",
	Type = "Surface",

	-- Visual properties
	Material = Enum.Material.Ice,
	Color = Color3.fromRGB(150, 200, 255),
	Transparency = 0.3,
	Reflectance = 0.5,

	-- Behavior
	FrictionMultiplier = 0.1, -- Very slippery (90% friction reduction)
	Damage = 0, -- No damage

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Sparkles",
		Color = ColorSequence.new(Color3.fromRGB(200, 230, 255)),
		Size = NumberSequence.new(0.2),
		Rate = 5,
	},

	Sound = {
		OnStep = "rbxassetid://9113994318", -- Ice cracking
		Volume = 0.2,
	},
}

--[[
	QUICKSAND
	Slows player movement dramatically
	Visual: Sandy brown material
	Theme: Desert (sections 16-30)
--]]
HazardDefinitions.Quicksand = {
	Name = "Quicksand",
	Type = "Slow",

	-- Visual properties
	Material = Enum.Material.Sand,
	Color = Color3.fromRGB(200, 180, 140),
	Transparency = 0,

	-- Behavior
	SpeedMultiplier = 0.3, -- 70% speed reduction
	SinkDepth = 2, -- Studs player sinks into quicksand
	Damage = 0, -- No damage

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Dust",
		Color = ColorSequence.new(Color3.fromRGB(200, 180, 140)),
		Size = NumberSequence.new(1, 0),
		Lifetime = NumberRange.new(0.5, 1),
		Rate = 20,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(45, 45),
	},

	Sound = {
		OnEnter = "rbxassetid://9114221327", -- Sinking sound
		Volume = 0.3,
	},
}

--[[
	POISON GAS
	Damage over time zone
	Visual: Green transparent zone with particles
	Theme: All themes (color varies)
--]]
HazardDefinitions.PoisonGas = {
	Name = "PoisonGas",
	Type = "DamageOverTime",

	-- Visual properties
	Material = Enum.Material.ForceField,
	Color = Color3.fromRGB(100, 255, 100),
	Transparency = 0.7,

	-- Behavior
	DamagePerSecond = 10,
	TickRate = 0.5, -- Damage every 0.5 seconds
	Damage = 5, -- Damage per tick (10 DPS)

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Smoke",
		Color = ColorSequence.new(Color3.fromRGB(100, 200, 100)),
		Size = NumberSequence.new(3, 5),
		Lifetime = NumberRange.new(2, 4),
		Rate = 30,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(30, 30),
		Transparency = NumberSequence.new(0.5, 1),
	},

	Sound = {
		SoundId = "rbxassetid://9113706391", -- Gas hissing
		Volume = 0.3,
		Looped = true,
	},
}

--[[
	FALLING PLATFORM
	Platform that collapses after player steps on it
	Visual: Normal platform with cracks
	Theme: Hard/Expert sections
--]]
HazardDefinitions.FallingPlatform = {
	Name = "FallingPlatform",
	Type = "Timed",

	-- Visual properties
	Material = Enum.Material.Concrete,
	Color = Color3.fromRGB(150, 150, 150),
	Transparency = 0,

	-- Behavior
	FallDelay = 0.5, -- Time before platform falls (seconds)
	FallSpeed = 50, -- How fast platform falls
	RespawnTime = 5, -- Time before platform respawns
	Damage = 0, -- Fall kills player, not platform

	-- Visual warning
	Warning = {
		Enabled = true,
		ShakeMagnitude = 0.3, -- Platform shakes before falling
		ColorChange = Color3.fromRGB(255, 100, 100), -- Turns red
		TransparencyChange = 0.3, -- Becomes slightly transparent
	},

	-- Effects
	Particles = {
		Enabled = true,
		ParticleType = "Debris",
		Color = ColorSequence.new(Color3.fromRGB(150, 150, 150)),
		Size = NumberSequence.new(0.5, 0.1),
		Lifetime = NumberRange.new(1, 2),
		Rate = 50,
		Speed = NumberRange.new(5, 10),
	},

	Sound = {
		OnTrigger = "rbxassetid://9114221327", -- Cracking sound
		OnFall = "rbxassetid://9114046294", -- Rumble
		Volume = 0.5,
	},
}

-- ============================================================================
-- THEME-SPECIFIC HAZARD MAPPINGS
-- ============================================================================

--[[
	Maps themes to their primary hazards
	Used by ThemeService to auto-apply theme-appropriate hazards
--]]
HazardDefinitions.ThemeHazards = {
	Grasslands = {
		Primary = {"Spikes"},
		Secondary = {},
		Rare = {"RotatingObstacle"},
	},

	Desert = {
		Primary = {"Quicksand", "Spikes"},
		Secondary = {"PoisonGas"},
		Rare = {"RotatingObstacle"},
	},

	Snow = {
		Primary = {"Ice", "WindZone"},
		Secondary = {"Spikes"},
		Rare = {"FallingPlatform"},
	},

	Volcano = {
		Primary = {"Lava", "Spikes"},
		Secondary = {"PoisonGas"},
		Rare = {"RotatingObstacle", "FallingPlatform"},
	},
}

-- ============================================================================
-- DIFFICULTY-BASED HAZARD FREQUENCY
-- ============================================================================

--[[
	How often hazards appear based on section difficulty
--]]
HazardDefinitions.DifficultyFrequency = {
	Easy = {
		HazardChance = 0.1, -- 10% of platforms have hazards
		MultiHazardChance = 0, -- Never multiple hazards
		ComplexHazards = false, -- No complex hazards (rotating, falling)
	},

	Medium = {
		HazardChance = 0.3, -- 30% of platforms have hazards
		MultiHazardChance = 0.1, -- 10% chance of multiple hazards
		ComplexHazards = false,
	},

	Hard = {
		HazardChance = 0.5, -- 50% of platforms have hazards
		MultiHazardChance = 0.25, -- 25% chance of multiple hazards
		ComplexHazards = true, -- Can use rotating obstacles, etc.
	},

	Expert = {
		HazardChance = 0.7, -- 70% of platforms have hazards
		MultiHazardChance = 0.4, -- 40% chance of multiple hazards
		ComplexHazards = true,
	},
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
	Get hazard definition by name
	@param hazardName string - Name of hazard
	@return table - Hazard definition
--]]
function HazardDefinitions.GetHazard(hazardName: string): table?
	return HazardDefinitions[hazardName]
end

--[[
	Get hazards for a specific theme
	@param themeName string - Theme name (Grasslands, Desert, etc.)
	@param difficulty string - Section difficulty tier
	@return table - Array of hazard names
--]]
function HazardDefinitions.GetHazardsForTheme(themeName: string, difficulty: string): {string}
	local themeHazards = HazardDefinitions.ThemeHazards[themeName]
	if not themeHazards then
		warn("[HazardDefinitions] Unknown theme:", themeName)
		return {}
	end

	local hazards = {}

	-- Add primary hazards
	for _, hazard in ipairs(themeHazards.Primary) do
		table.insert(hazards, hazard)
	end

	-- Add secondary hazards
	for _, hazard in ipairs(themeHazards.Secondary) do
		table.insert(hazards, hazard)
	end

	-- Add rare hazards for Hard/Expert
	if difficulty == "Hard" or difficulty == "Expert" then
		for _, hazard in ipairs(themeHazards.Rare) do
			table.insert(hazards, hazard)
		end
	end

	return hazards
end

--[[
	Get hazard frequency for difficulty
	@param difficulty string - Easy, Medium, Hard, Expert
	@return table - Frequency settings
--]]
function HazardDefinitions.GetFrequency(difficulty: string): table
	return HazardDefinitions.DifficultyFrequency[difficulty] or HazardDefinitions.DifficultyFrequency.Easy
end

--[[
	Validate hazard definition
	@param hazard table - Hazard definition
	@return boolean - Valid
	@return string? - Error message
--]]
function HazardDefinitions.ValidateHazard(hazard: table): (boolean, string?)
	if not hazard.Name then
		return false, "Missing Name"
	end

	if not hazard.Type then
		return false, "Missing Type"
	end

	if not hazard.Material then
		return false, "Missing Material"
	end

	if not hazard.Color then
		return false, "Missing Color"
	end

	return true
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function HazardDefinitions.DebugPrintAll()
	print("=== HAZARD DEFINITIONS ===")

	local hazardTypes = {
		"Lava", "Spikes", "RotatingObstacle", "WindZone",
		"Ice", "Quicksand", "PoisonGas", "FallingPlatform"
	}

	for _, hazardName in ipairs(hazardTypes) do
		local hazard = HazardDefinitions[hazardName]
		print(string.format("- %s (%s)", hazard.Name, hazard.Type))
	end

	print("\n=== THEME HAZARDS ===")
	for themeName, themeHazards in pairs(HazardDefinitions.ThemeHazards) do
		print(string.format("%s: %s", themeName, table.concat(themeHazards.Primary, ", ")))
	end

	print("==========================")
end

return HazardDefinitions
