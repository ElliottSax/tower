--[[
	ThemeDefinitions.lua
	Defines environmental themes for tower sections

	Themes:
	1. Grasslands (Sections 1-15) - Bright, natural, beginner-friendly
	2. Desert (Sections 16-30) - Warm, sandy, mid-difficulty
	3. Snow (Sections 31-40) - Cold, icy, advanced
	4. Volcano (Sections 41-50) - Dark, fiery, expert

	Each theme defines:
	- Materials (Platform, Wall, Decoration)
	- Colors (Platform, Wall, Accent)
	- Lighting (Ambient, Brightness, Fog, Time)
	- Particles (Type, Rate, Color)
	- Decorations (Props, Spawn Chance)
	- Music (Track Name)

	Week 8: Initial implementation
--]]

local ThemeDefinitions = {}

-- ============================================================================
-- GRASSLANDS THEME (Sections 1-15)
-- ============================================================================

ThemeDefinitions.Grasslands = {
	Name = "Grasslands",
	Description = "Lush green fields with bright skies",

	-- Materials
	Materials = {
		Platform = Enum.Material.Grass,
		Wall = Enum.Material.Cobblestone,
		Decoration = Enum.Material.Wood,
	},

	-- Colors
	Colors = {
		Platform = Color3.fromRGB(120, 200, 90),  -- Bright green
		Wall = Color3.fromRGB(140, 140, 140),      -- Gray stone
		Accent = Color3.fromRGB(100, 150, 70),     -- Dark green
	},

	-- Lighting
	Lighting = {
		Ambient = Color3.fromRGB(180, 200, 220),          -- Bright sky blue
		OutdoorAmbient = Color3.fromRGB(200, 220, 240),   -- Very bright
		Brightness = 2,
		FogColor = Color3.fromRGB(200, 220, 240),
		FogEnd = 500,
		FogStart = 100,
		ClockTime = 12, -- Noon (bright daylight)
	},

	-- Particles
	Particles = {
		Enabled = true,
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Rate = 2,
		Lifetime = 5,
		Speed = 2,
		SpreadAngle = 180,
		Color = Color3.fromRGB(255, 255, 200), -- Light yellow (pollen/fireflies)
		Size = 0.3,
		Transparency = 0.5,
	},

	-- Decorations
	Decorations = {
		Enabled = true,
		SpawnChance = 0.2, -- 20% chance per section
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(100, 70, 40), -- Brown (trees)
		MeshType = Enum.MeshType.Cylinder,
		MeshScale = Vector3.new(1, 2, 1),
	},

	-- Music
	Music = {
		TrackName = "GrasslandsTheme",
		AssetId = "rbxassetid://1234567890", -- Placeholder
		Volume = 0.5,
	},
}

-- ============================================================================
-- DESERT THEME (Sections 16-30)
-- ============================================================================

ThemeDefinitions.Desert = {
	Name = "Desert",
	Description = "Hot sandy dunes under a blazing sun",

	-- Materials
	Materials = {
		Platform = Enum.Material.Sand,
		Wall = Enum.Material.Sandstone,
		Decoration = Enum.Material.Rock,
	},

	-- Colors
	Colors = {
		Platform = Color3.fromRGB(210, 180, 140),  -- Sandy tan
		Wall = Color3.fromRGB(180, 150, 120),       -- Darker sand
		Accent = Color3.fromRGB(230, 200, 160),     -- Light sand
	},

	-- Lighting
	Lighting = {
		Ambient = Color3.fromRGB(220, 200, 180),          -- Warm orange
		OutdoorAmbient = Color3.fromRGB(240, 220, 200),   -- Very warm
		Brightness = 2.5,
		FogColor = Color3.fromRGB(240, 220, 180),
		FogEnd = 400,
		FogStart = 80,
		ClockTime = 14, -- Afternoon (harsh sun)
	},

	-- Particles
	Particles = {
		Enabled = true,
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Rate = 5,
		Lifetime = 4,
		Speed = 3,
		SpreadAngle = 90,
		Color = Color3.fromRGB(230, 200, 160), -- Sandy dust
		Size = 1,
		Transparency = 0.7,
	},

	-- Decorations
	Decorations = {
		Enabled = true,
		SpawnChance = 0.15, -- 15% chance (sparse desert)
		Material = Enum.Material.Cactus,
		Color = Color3.fromRGB(80, 120, 60), -- Green (cacti)
		MeshType = Enum.MeshType.Sphere,
		MeshScale = Vector3.new(0.5, 2, 0.5),
	},

	-- Music
	Music = {
		TrackName = "DesertTheme",
		AssetId = "rbxassetid://1234567891", -- Placeholder
		Volume = 0.5,
	},
}

-- ============================================================================
-- SNOW THEME (Sections 31-40)
-- ============================================================================

ThemeDefinitions.Snow = {
	Name = "Snow",
	Description = "Frozen peaks with falling snow",

	-- Materials
	Materials = {
		Platform = Enum.Material.Ice,
		Wall = Enum.Material.Glacier,
		Decoration = Enum.Material.Ice,
	},

	-- Colors
	Colors = {
		Platform = Color3.fromRGB(240, 250, 255),  -- White/light blue
		Wall = Color3.fromRGB(200, 220, 240),       -- Ice blue
		Accent = Color3.fromRGB(180, 210, 240),     -- Sky blue
	},

	-- Lighting
	Lighting = {
		Ambient = Color3.fromRGB(180, 200, 220),          -- Cool blue
		OutdoorAmbient = Color3.fromRGB(200, 220, 240),   -- Icy blue
		Brightness = 1.8,
		FogColor = Color3.fromRGB(220, 230, 240),
		FogEnd = 300,
		FogStart = 50,
		ClockTime = 16, -- Late afternoon (cooler light)
	},

	-- Particles
	Particles = {
		Enabled = true,
		Texture = "rbxasset://textures/particles/snow_main.dds",
		Rate = 20,
		Lifetime = 8,
		Speed = 5,
		SpreadAngle = 30,
		Color = Color3.fromRGB(255, 255, 255), -- White (snowflakes)
		Size = 0.5,
		Transparency = 0.3,
	},

	-- Decorations
	Decorations = {
		Enabled = true,
		SpawnChance = 0.25, -- 25% chance
		Material = Enum.Material.Ice,
		Color = Color3.fromRGB(200, 230, 255), -- Light blue (ice crystals)
		MeshType = Enum.MeshType.Wedge,
		MeshScale = Vector3.new(1, 2, 1),
	},

	-- Music
	Music = {
		TrackName = "SnowTheme",
		AssetId = "rbxassetid://1234567892", -- Placeholder
		Volume = 0.5,
	},
}

-- ============================================================================
-- VOLCANO THEME (Sections 41-50)
-- ============================================================================

ThemeDefinitions.Volcano = {
	Name = "Volcano",
	Description = "Molten lava and scorching heat",

	-- Materials
	Materials = {
		Platform = Enum.Material.Basalt,
		Wall = Enum.Material.CrackedLava,
		Decoration = Enum.Material.Volcanic,
	},

	-- Colors
	Colors = {
		Platform = Color3.fromRGB(60, 50, 50),     -- Dark volcanic rock
		Wall = Color3.fromRGB(80, 60, 50),          -- Lighter volcanic rock
		Accent = Color3.fromRGB(255, 100, 50),      -- Orange lava glow
	},

	-- Lighting
	Lighting = {
		Ambient = Color3.fromRGB(150, 80, 60),            -- Dark red
		OutdoorAmbient = Color3.fromRGB(180, 100, 80),    -- Orange glow
		Brightness = 1.5,
		FogColor = Color3.fromRGB(120, 60, 40),
		FogEnd = 250,
		FogStart = 30,
		ClockTime = 20, -- Night/dusk (dark, fiery)
	},

	-- Particles
	Particles = {
		Enabled = true,
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Rate = 15,
		Lifetime = 3,
		Speed = 8,
		SpreadAngle = 60,
		Color = Color3.fromRGB(255, 150, 50), -- Orange/yellow (embers)
		Size = 1.5,
		Transparency = 0.4,
	},

	-- Decorations
	Decorations = {
		Enabled = true,
		SpawnChance = 0.3, -- 30% chance
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 100, 0), -- Bright orange (lava pools)
		MeshType = Enum.MeshType.Sphere,
		MeshScale = Vector3.new(1.5, 0.3, 1.5),
	},

	-- Music
	Music = {
		TrackName = "VolcanoTheme",
		AssetId = "rbxassetid://1234567893", -- Placeholder
		Volume = 0.6,
	},
}

-- ============================================================================
-- EXPORT
-- ============================================================================

return ThemeDefinitions
