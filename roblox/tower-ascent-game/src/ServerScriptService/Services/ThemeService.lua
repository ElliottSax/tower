--[[
	ThemeService.lua
	Applies environmental themes to tower sections

	Features:
	- 4 environmental themes (Grasslands, Desert, Snow, Volcano)
	- Automatic theme assignment based on section number
	- Material and color application
	- Theme-specific lighting
	- Particle effects per theme
	- Background music transitions

	Theme Ranges:
	- Grasslands: Sections 1-15
	- Desert: Sections 16-30
	- Snow: Sections 31-40
	- Volcano: Sections 41-50

	Week 8: Initial implementation
--]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThemeDefinitions = require(script.Parent.Parent.ThemeDefinitions.ThemeDefinitions)

local ThemeService = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Theme assignment by section number
local THEME_RANGES = {
	{range = {1, 15},   theme = "Grasslands"},
	{range = {16, 30},  theme = "Desert"},
	{range = {31, 40},  theme = "Snow"},
	{range = {41, 50},  theme = "Volcano"},
}

-- Track current theme
local CurrentTheme = nil

-- ============================================================================
-- THEME DETECTION
-- ============================================================================

function ThemeService.GetThemeForSection(sectionNumber: number): string
	--[[
		Returns the theme name for a given section number.
	--]]

	for _, themeRange in ipairs(THEME_RANGES) do
		if sectionNumber >= themeRange.range[1] and sectionNumber <= themeRange.range[2] then
			return themeRange.theme
		end
	end

	-- Default fallback
	return "Grasslands"
end

-- ============================================================================
-- SECTION THEMING
-- ============================================================================

function ThemeService.ApplyThemeToSection(section: Model, sectionNumber: number)
	--[[
		Applies theme to a single tower section.
		Changes materials, colors, and adds decorations.
	--]]

	local themeName = ThemeService.GetThemeForSection(sectionNumber)
	local theme = ThemeDefinitions[themeName]

	if not theme then
		warn(string.format("[ThemeService] Theme not found: %s", themeName))
		return
	end

	-- Apply to all parts in section
	for _, descendant in ipairs(section:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Skip certain parts (checkpoints, kill bricks)
			if descendant.Name == "Checkpoint" or descendant:GetAttribute("IsKillBrick") then
				-- Don't theme these
				continue
			end

			-- Apply theme material and color
			if descendant.Name:match("Platform") then
				-- Platform parts get platform material
				descendant.Material = theme.Materials.Platform
				descendant.Color = theme.Colors.Platform
			elseif descendant.Name:match("Wall") then
				-- Wall parts get wall material
				descendant.Material = theme.Materials.Wall or theme.Materials.Platform
				descendant.Color = theme.Colors.Wall or theme.Colors.Platform
			elseif descendant.Name:match("Decoration") then
				-- Decorations keep their color but change material
				descendant.Material = theme.Materials.Decoration or Enum.Material.SmoothPlastic
			else
				-- Default theming
				descendant.Material = theme.Materials.Platform
				descendant.Color = theme.Colors.Platform
			end
		end
	end

	-- Add theme-specific particles (if any)
	if theme.Particles then
		ThemeService.AddThemeParticles(section, theme)
	end

	-- Store theme on section
	section:SetAttribute("Theme", themeName)
end

-- ============================================================================
-- TOWER THEMING
-- ============================================================================

function ThemeService.ApplyThemesToTower(tower: Model)
	--[[
		Applies themes to entire tower.
		Each section gets themed based on its section number.
	--]]

	local sectionCount = 0
	local themeCount = {}

	-- Find all sections
	for _, child in ipairs(tower:GetChildren()) do
		if child:IsA("Model") and child.Name:match("Section_") then
			-- Extract section number from name (e.g., "Section_15_Easy_Straight")
			local sectionNumber = tonumber(child.Name:match("Section_(%d+)"))

			if sectionNumber then
				ThemeService.ApplyThemeToSection(child, sectionNumber)
				sectionCount = sectionCount + 1

				-- Track theme counts
				local themeName = ThemeService.GetThemeForSection(sectionNumber)
				themeCount[themeName] = (themeCount[themeName] or 0) + 1
			end
		end
	end

	-- Log results
	print(string.format("[ThemeService] Applied themes to %d sections", sectionCount))
	for themeName, count in pairs(themeCount) do
		print(string.format("  - %s: %d sections", themeName, count))
	end

	-- Apply global lighting for first theme
	if sectionCount > 0 then
		local firstTheme = ThemeService.GetThemeForSection(1)
		ThemeService.ApplyGlobalLighting(firstTheme)
	end
end

-- ============================================================================
-- LIGHTING
-- ============================================================================

function ThemeService.ApplyGlobalLighting(themeName: string)
	--[[
		Applies global lighting settings for a theme.
		Affects ambient, outdoor ambient, fog, etc.
	--]]

	local theme = ThemeDefinitions[themeName]
	if not theme or not theme.Lighting then
		return
	end

	local lighting = theme.Lighting

	-- Apply lighting properties
	if lighting.Ambient then
		Lighting.Ambient = lighting.Ambient
	end

	if lighting.OutdoorAmbient then
		Lighting.OutdoorAmbient = lighting.OutdoorAmbient
	end

	if lighting.Brightness then
		Lighting.Brightness = lighting.Brightness
	end

	if lighting.FogColor then
		Lighting.FogColor = lighting.FogColor
	end

	if lighting.FogEnd then
		Lighting.FogEnd = lighting.FogEnd
	end

	if lighting.FogStart then
		Lighting.FogStart = lighting.FogStart
	end

	if lighting.ClockTime then
		Lighting.ClockTime = lighting.ClockTime
	end

	CurrentTheme = themeName

	print(string.format("[ThemeService] Applied %s lighting", themeName))
end

-- ============================================================================
-- PARTICLES
-- ============================================================================

function ThemeService.AddThemeParticles(section: Model, theme: {})
	--[[
		Adds theme-specific particle effects to a section.
		Examples: falling snow, dust, embers
	--]]

	if not theme.Particles or not theme.Particles.Enabled then
		return
	end

	-- Get section bounds
	local primaryPart = section.PrimaryPart
	if not primaryPart then
		return
	end

	local position = primaryPart.Position
	local size = primaryPart.Size

	-- Create particle emitter part (invisible)
	local particlePart = Instance.new("Part")
	particlePart.Name = "ThemeParticles"
	particlePart.Size = Vector3.new(size.X, 1, size.Z)
	particlePart.Position = position + Vector3.new(0, size.Y / 2 + 5, 0)
	particlePart.Anchored = true
	particlePart.CanCollide = false
	particlePart.Transparency = 1
	particlePart.Parent = section

	-- Create particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ThemeEmitter"

	-- Apply particle properties from theme
	local particleConfig = theme.Particles

	emitter.Texture = particleConfig.Texture or "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = particleConfig.Rate or 10
	emitter.Lifetime = NumberRange.new(particleConfig.Lifetime or 5)
	emitter.Speed = NumberRange.new(particleConfig.Speed or 5)
	emitter.SpreadAngle = Vector2.new(particleConfig.SpreadAngle or 45, particleConfig.SpreadAngle or 45)

	if particleConfig.Color then
		emitter.Color = ColorSequence.new(particleConfig.Color)
	end

	if particleConfig.Size then
		emitter.Size = NumberSequence.new(particleConfig.Size)
	end

	if particleConfig.Transparency then
		emitter.Transparency = NumberSequence.new(particleConfig.Transparency)
	end

	emitter.Parent = particlePart
end

-- ============================================================================
-- THEME TRANSITIONS
-- ============================================================================

function ThemeService.OnSectionEntered(player: Player, sectionNumber: number)
	--[[
		Called when player enters a new section.
		Handles theme transitions (music, lighting changes, weather).
		WEEK 10: Added weather integration
	--]]

	local newTheme = ThemeService.GetThemeForSection(sectionNumber)

	-- Check if theme changed
	if newTheme ~= CurrentTheme then
		print(string.format(
			"[ThemeService] Player %s entered %s theme (Section %d)",
			player.Name,
			newTheme,
			sectionNumber
		))

		-- Apply new lighting
		ThemeService.ApplyGlobalLighting(newTheme)

		-- WEEK 10: Change weather to match new theme
		local WeatherService = _G.TowerAscent and _G.TowerAscent.WeatherService
		if WeatherService and WeatherService.SetWeatherByTheme then
			WeatherService.SetWeatherByTheme(newTheme)
		end

		-- Trigger music change (client-side)
		local changeThemeMusicEvent = ReplicatedStorage.Events:FindFirstChild("ChangeThemeMusic")
		if changeThemeMusicEvent then
			changeThemeMusicEvent:FireClient(player, newTheme)
		end
	end
end

-- ============================================================================
-- DECORATIONS
-- ============================================================================

function ThemeService.AddThemeDecorations(section: Model, themeName: string)
	--[[
		Adds theme-specific decorations to sections.
		Examples: trees (grasslands), cacti (desert), ice crystals (snow)
	--]]

	local theme = ThemeDefinitions[themeName]
	if not theme or not theme.Decorations then
		return
	end

	-- Get section bounds
	local primaryPart = section.PrimaryPart
	if not primaryPart then
		return
	end

	local decorationConfig = theme.Decorations

	-- Random chance to add decoration
	if math.random() > (decorationConfig.SpawnChance or 0.3) then
		return
	end

	-- Create decoration based on theme
	-- This is a simple implementation - can be expanded
	local decoration = Instance.new("Part")
	decoration.Name = "ThemeDecoration"
	decoration.Size = Vector3.new(2, 4, 2)
	decoration.Position = primaryPart.Position + Vector3.new(
		math.random(-10, 10),
		2,
		math.random(-5, 5)
	)
	decoration.Anchored = true
	decoration.Material = decorationConfig.Material or Enum.Material.Wood
	decoration.Color = decorationConfig.Color or Color3.fromRGB(100, 100, 100)
	decoration.Parent = section

	-- Add mesh if specified
	if decorationConfig.MeshType then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = decorationConfig.MeshType
		mesh.Scale = decorationConfig.MeshScale or Vector3.new(1, 1, 1)
		mesh.Parent = decoration
	end
end

-- ============================================================================
-- STATS
-- ============================================================================

function ThemeService.GetCurrentTheme(): string?
	return CurrentTheme
end

function ThemeService.DebugPrintThemeRanges()
	--[[
		Prints theme assignment ranges.
	--]]

	print("=== THEME RANGES ===")
	for _, themeRange in ipairs(THEME_RANGES) do
		print(string.format(
			"Sections %d-%d: %s",
			themeRange.range[1],
			themeRange.range[2],
			themeRange.theme
		))
	end
	print("====================")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ThemeService.Init(tower: Model?)
	print("[ThemeService] Initializing...")

	-- Setup RemoteEvents for theme music changes
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	-- Create ChangeThemeMusic event if it doesn't exist
	if not eventsFolder:FindFirstChild("ChangeThemeMusic") then
		local changeThemeMusicEvent = Instance.new("RemoteEvent")
		changeThemeMusicEvent.Name = "ChangeThemeMusic"
		changeThemeMusicEvent.Parent = eventsFolder
		print("[ThemeService] Created ChangeThemeMusic RemoteEvent")
	end

	if tower then
		-- Apply themes to initial tower
		ThemeService.ApplyThemesToTower(tower)
	end

	print("[ThemeService] Initialized")
end

function ThemeService.OnNewTower(tower: Model)
	--[[
		Called when a new tower is generated.
		Applies themes to all sections.
	--]]

	print("[ThemeService] New tower detected, applying themes...")
	ThemeService.ApplyThemesToTower(tower)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ThemeService
