--[[
	DimensionService.lua
	Core service managing dimension loading, switching, and state

	Responsibilities:
	- Load/unload dimension environments
	- Apply dimension-specific settings (lighting, fog, etc.)
	- Coordinate with dimension-specific services
	- Track player progress through dimensions

	Each dimension has unique mechanics handled by dedicated services:
	- GravityService (Gravity Dimension)
	- ScaleService (Tiny Dimension)
	- VoidService (Void Dimension)
	- GliderService (Sky Dimension)
--]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Optional LevelGenerator for procedural generation
local LevelGenerator = nil
local function TryLoadLevelGenerator()
	local Utilities = ServerScriptService:FindFirstChild("Utilities")
	if Utilities then
		local generatorModule = Utilities:FindFirstChild("LevelGenerator")
		if generatorModule then
			local success, result = pcall(require, generatorModule)
			if success then
				LevelGenerator = result
				print("[DimensionService] LevelGenerator loaded for procedural generation")
			end
		end
	end
end

local DimensionService = {}

-- ============================================================================
-- STATE
-- ============================================================================

DimensionService.CurrentDimension = nil -- Current active dimension name
DimensionService.LoadedSections = {} -- Currently loaded section instances
DimensionService.PlayerProgress = {} -- [UserId] = { dimension, section, checkpoint }
DimensionService.IsTransitioning = false

-- Dimension-specific services (loaded on demand)
DimensionService.DimensionHandlers = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DimensionService.Init()
	print("[DimensionService] Initializing...")

	-- Try to load LevelGenerator for advanced procedural generation
	TryLoadLevelGenerator()

	-- Create RemoteEvents
	DimensionService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		DimensionService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DimensionService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		DimensionService.OnPlayerJoin(player)
	end

	print("[DimensionService] Initialized")
end

function DimensionService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Dimension changed event (server -> client)
	if not remoteFolder:FindFirstChild("DimensionChanged") then
		local event = Instance.new("RemoteEvent")
		event.Name = "DimensionChanged"
		event.Parent = remoteFolder
	end

	-- Section reached event
	if not remoteFolder:FindFirstChild("SectionReached") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SectionReached"
		event.Parent = remoteFolder
	end

	-- Dimension effects event (for client-side visuals)
	if not remoteFolder:FindFirstChild("DimensionEffect") then
		local event = Instance.new("RemoteEvent")
		event.Name = "DimensionEffect"
		event.Parent = remoteFolder
	end

	-- Practice mode events
	if not remoteFolder:FindFirstChild("StartPractice") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StartPractice"
		event.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("StopPractice") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StopPractice"
		event.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("RestartPractice") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RestartPractice"
		event.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("NextPracticeSection") then
		local event = Instance.new("RemoteEvent")
		event.Name = "NextPracticeSection"
		event.Parent = remoteFolder
	end

	DimensionService.Remotes = {
		DimensionChanged = remoteFolder.DimensionChanged,
		SectionReached = remoteFolder.SectionReached,
		DimensionEffect = remoteFolder.DimensionEffect,
		StartPractice = remoteFolder.StartPractice,
		StopPractice = remoteFolder.StopPractice,
		RestartPractice = remoteFolder.RestartPractice,
		NextPracticeSection = remoteFolder.NextPracticeSection,
	}

	-- Connect practice mode events
	DimensionService.Remotes.StartPractice.OnServerEvent:Connect(function(player, dimensionName, sectionNumber)
		DimensionService.StartPracticeMode(player, dimensionName, sectionNumber)
	end)

	DimensionService.Remotes.StopPractice.OnServerEvent:Connect(function(player)
		DimensionService.StopPracticeMode(player)
	end)

	DimensionService.Remotes.RestartPractice.OnServerEvent:Connect(function(player)
		DimensionService.RestartPracticeSection(player)
	end)

	DimensionService.Remotes.NextPracticeSection.OnServerEvent:Connect(function(player)
		DimensionService.AdvancePracticeSection(player)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function DimensionService.OnPlayerJoin(player: Player)
	DimensionService.PlayerProgress[player.UserId] = {
		dimension = nil,
		section = 0,
		checkpoint = nil,
		startTime = 0,
		finished = false,
	}

	print(string.format("[DimensionService] Initialized player: %s", player.Name))
end

function DimensionService.OnPlayerLeave(player: Player)
	DimensionService.PlayerProgress[player.UserId] = nil
end

function DimensionService.GetPlayerProgress(player: Player)
	return DimensionService.PlayerProgress[player.UserId]
end

function DimensionService.ResetPlayerProgress(player: Player)
	local progress = DimensionService.PlayerProgress[player.UserId]
	if progress then
		progress.section = 0
		progress.checkpoint = nil
		progress.startTime = tick()
		progress.finished = false
	end
end

-- ============================================================================
-- DIMENSION LOADING
-- ============================================================================

function DimensionService.LoadDimension(dimensionName: string): boolean
	local config = GameConfig.Dimensions[dimensionName]
	if not config then
		warn("[DimensionService] Unknown dimension: " .. tostring(dimensionName))
		return false
	end

	if DimensionService.IsTransitioning then
		warn("[DimensionService] Already transitioning dimensions")
		return false
	end

	DimensionService.IsTransitioning = true

	print(string.format("[DimensionService] Loading dimension: %s", dimensionName))

	-- Unload current dimension if any
	if DimensionService.CurrentDimension then
		DimensionService.UnloadCurrentDimension()
	end

	-- Apply dimension theme (lighting, fog, etc.)
	DimensionService.ApplyDimensionTheme(config.Theme)

	-- Generate dimension sections
	DimensionService.GenerateDimensionSections(dimensionName, config)

	-- Initialize dimension-specific handler
	DimensionService.InitializeDimensionHandler(dimensionName)

	-- Set current dimension
	DimensionService.CurrentDimension = dimensionName

	-- Notify all clients
	DimensionService.Remotes.DimensionChanged:FireAllClients(dimensionName, config)

	-- Reset all player progress
	for _, player in ipairs(Players:GetPlayers()) do
		DimensionService.ResetPlayerProgress(player)
	end

	DimensionService.IsTransitioning = false

	print(string.format("[DimensionService] Dimension loaded: %s (%d sections)",
		dimensionName, config.Settings.SectionCount))

	return true
end

function DimensionService.UnloadCurrentDimension()
	if not DimensionService.CurrentDimension then return end

	print(string.format("[DimensionService] Unloading dimension: %s",
		DimensionService.CurrentDimension))

	-- Cleanup dimension handler
	local handler = DimensionService.DimensionHandlers[DimensionService.CurrentDimension]
	if handler and handler.Cleanup then
		handler.Cleanup()
	end

	-- Destroy loaded sections
	for _, section in ipairs(DimensionService.LoadedSections) do
		if section and section.Parent then
			section:Destroy()
		end
	end
	DimensionService.LoadedSections = {}

	DimensionService.CurrentDimension = nil
end

-- ============================================================================
-- DIMENSION THEME
-- ============================================================================

function DimensionService.ApplyDimensionTheme(theme)
	if not theme then return end

	-- Tween lighting changes for smooth transition
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)

	-- Ambient
	if theme.Ambient then
		TweenService:Create(Lighting, tweenInfo, {
			Ambient = theme.Ambient
		}):Play()
	end

	-- Fog
	if theme.FogColor then
		TweenService:Create(Lighting, tweenInfo, {
			FogColor = theme.FogColor,
			FogEnd = theme.FogEnd or 1000,
		}):Play()
	end

	-- Brightness (handled separately as it's not always tweened well)
	Lighting.Brightness = 2

	print("[DimensionService] Applied dimension theme")
end

-- ============================================================================
-- SECTION GENERATION
-- ============================================================================

-- Configuration for generation mode
DimensionService.UseProceduralGeneration = true -- Set to false for basic generation
DimensionService.CurrentSeed = nil -- Current level seed for reproducibility

function DimensionService.GenerateDimensionSections(dimensionName: string, config)
	-- Create dimension container
	local dimensionFolder = Instance.new("Folder")
	dimensionFolder.Name = dimensionName .. "Dimension"
	dimensionFolder.Parent = workspace

	table.insert(DimensionService.LoadedSections, dimensionFolder)

	-- Use LevelGenerator if available and procedural generation is enabled
	if LevelGenerator and DimensionService.UseProceduralGeneration then
		DimensionService.GenerateProceduralLevel(dimensionFolder, dimensionName, config)
	else
		DimensionService.GenerateBasicLevel(dimensionFolder, dimensionName, config)
	end
end

function DimensionService.GenerateProceduralLevel(folder: Folder, dimensionName: string, config)
	-- Generate a seed for reproducibility (can be set externally for daily challenges)
	local seed = DimensionService.CurrentSeed or os.time()
	DimensionService.CurrentSeed = seed

	print(string.format("[DimensionService] Generating procedural level with seed: %d", seed))

	-- Use LevelGenerator
	local levelModel = LevelGenerator.GenerateDimensionLevel(dimensionName, {
		seed = seed,
		sectionCount = config.Settings.SectionCount,
		difficulty = "normal", -- Can be adjusted based on game mode
	})

	if levelModel then
		levelModel.Parent = folder
		table.insert(DimensionService.LoadedSections, levelModel)

		-- Store section count for reference
		folder:SetAttribute("TotalSections", config.Settings.SectionCount)
		folder:SetAttribute("Seed", seed)

		print(string.format("[DimensionService] Procedural level generated: %d sections",
			config.Settings.SectionCount))
	else
		warn("[DimensionService] Procedural generation failed, falling back to basic")
		DimensionService.GenerateBasicLevel(folder, dimensionName, config)
	end
end

function DimensionService.GenerateBasicLevel(folder: Folder, dimensionName: string, config)
	-- Original basic generation
	local sectionCount = config.Settings.SectionCount

	for i = 1, sectionCount do
		local section = DimensionService.CreateSection(dimensionName, i, config)
		section.Parent = folder
		table.insert(DimensionService.LoadedSections, section)
	end

	-- Create start platform
	local startPlatform = DimensionService.CreateStartPlatform(dimensionName, config)
	startPlatform.Parent = folder

	-- Create finish line
	local finishLine = DimensionService.CreateFinishLine(dimensionName, sectionCount, config)
	finishLine.Parent = folder

	folder:SetAttribute("TotalSections", sectionCount)
end

-- Set custom seed for reproducible levels (daily challenges, etc.)
function DimensionService.SetLevelSeed(seed: number)
	DimensionService.CurrentSeed = seed
end

-- Generate a daily challenge level
function DimensionService.LoadDailyChallenge(dimensionName: string): boolean
	-- Use date as seed for consistent daily levels
	local date = os.date("*t")
	local dailySeed = date.year * 10000 + date.month * 100 + date.day

	DimensionService.SetLevelSeed(dailySeed)
	return DimensionService.LoadDimension(dimensionName)
end

function DimensionService.CreateSection(dimensionName: string, sectionNumber: number, config): Model
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNumber
	section:SetAttribute("SectionNumber", sectionNumber)
	section:SetAttribute("Dimension", dimensionName)

	-- Calculate section position
	local sectionLength = 60
	local sectionHeight = 20
	local yOffset = (sectionNumber - 1) * sectionHeight

	-- Create base platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(20, 3, 20)
	platform.Position = Vector3.new(0, yOffset + 1.5, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = config.Theme.PrimaryColor
	platform.Parent = section

	-- Create checkpoint
	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Size = Vector3.new(15, 1, 15)
	checkpoint.Position = Vector3.new(0, yOffset + 3.5, 0)
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.Transparency = 0.5
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = config.Theme.AccentColor
	checkpoint.Parent = section

	-- Tag for CollectionService
	local CollectionService = game:GetService("CollectionService")
	CollectionService:AddTag(checkpoint, "Checkpoint")

	-- Add dimension-specific elements
	DimensionService.AddDimensionElements(section, dimensionName, sectionNumber, config)

	-- Set PrimaryPart
	section.PrimaryPart = platform

	return section
end

function DimensionService.AddDimensionElements(section: Model, dimensionName: string, sectionNumber: number, config)
	-- Add elements based on dimension type
	if dimensionName == "Gravity" then
		DimensionService.AddGravityElements(section, sectionNumber, config)
	elseif dimensionName == "Tiny" then
		DimensionService.AddTinyElements(section, sectionNumber, config)
	elseif dimensionName == "Void" then
		DimensionService.AddVoidElements(section, sectionNumber, config)
	elseif dimensionName == "Sky" then
		DimensionService.AddSkyElements(section, sectionNumber, config)
	end
end

-- ============================================================================
-- DIMENSION-SPECIFIC ELEMENTS
-- ============================================================================

function DimensionService.AddGravityElements(section: Model, sectionNumber: number, config)
	local CollectionService = game:GetService("CollectionService")
	local platform = section:FindFirstChild("Platform")
	if not platform then return end

	-- Add gravity flip zones based on difficulty
	local difficulty = DimensionService.GetSectionDifficulty(sectionNumber, config.Difficulty)
	local flipsPerSection = difficulty.FlipsPerSection or 1

	for i = 1, flipsPerSection do
		local flipZone = Instance.new("Part")
		flipZone.Name = "GravityFlip_" .. i
		flipZone.Size = Vector3.new(10, 10, 2)
		flipZone.Position = platform.Position + Vector3.new(
			math.random(-5, 5),
			5 + (i * 3),
			10 + (i * 5)
		)
		flipZone.Anchored = true
		flipZone.CanCollide = false
		flipZone.Transparency = 0.7
		flipZone.Material = Enum.Material.ForceField
		flipZone.Color = Color3.fromRGB(150, 50, 255)
		flipZone.Parent = section

		-- Set flip direction
		local directions = {"Up", "Down", "Left", "Right"}
		flipZone:SetAttribute("FlipDirection", directions[math.random(1, #directions)])

		CollectionService:AddTag(flipZone, "GravityFlip")
	end
end

function DimensionService.AddTinyElements(section: Model, sectionNumber: number, config)
	local CollectionService = game:GetService("CollectionService")
	local platform = section:FindFirstChild("Platform")
	if not platform then return end

	-- Add shrink zone at certain sections
	local shrinkSections = {5, 10, 15, 18}
	if table.find(shrinkSections, sectionNumber) then
		local shrinkZone = Instance.new("Part")
		shrinkZone.Name = "ShrinkZone"
		shrinkZone.Size = Vector3.new(15, 5, 15)
		shrinkZone.Position = platform.Position + Vector3.new(0, 5, 0)
		shrinkZone.Anchored = true
		shrinkZone.CanCollide = false
		shrinkZone.Transparency = 0.8
		shrinkZone.Material = Enum.Material.ForceField
		shrinkZone.Color = Color3.fromRGB(50, 255, 50)
		shrinkZone.Parent = section

		-- Calculate target scale
		local scaleIndex = table.find(shrinkSections, sectionNumber)
		local targetScale = config.Settings.ScaleLevels[scaleIndex + 1] or 0.1
		shrinkZone:SetAttribute("TargetScale", targetScale)

		CollectionService:AddTag(shrinkZone, "ShrinkZone")
	end

	-- Add oversized objects as obstacles
	local objects = {"Pencil", "Coin", "Leaf", "Pebble"}
	local objType = objects[math.random(1, #objects)]

	local obstacle = Instance.new("Part")
	obstacle.Name = objType
	obstacle.Size = Vector3.new(
		math.random(5, 15),
		math.random(3, 8),
		math.random(5, 15)
	)
	obstacle.Position = platform.Position + Vector3.new(
		math.random(-8, 8),
		math.random(5, 15),
		math.random(-8, 8)
	)
	obstacle.Anchored = true
	obstacle.Material = Enum.Material.Wood
	obstacle.Color = Color3.fromRGB(139, 90, 43)
	obstacle.Parent = section
end

function DimensionService.AddVoidElements(section: Model, sectionNumber: number, config)
	local CollectionService = game:GetService("CollectionService")
	local platform = section:FindFirstChild("Platform")
	if not platform then return end

	-- Mark platforms as crumbling
	CollectionService:AddTag(platform, "CrumblingPlatform")

	local difficulty = DimensionService.GetSectionDifficulty(sectionNumber, config.Difficulty)
	platform:SetAttribute("CrumbleDelay", difficulty.CrumbleDelay or 2.5)

	-- Add additional stepping stone platforms
	local stoneCount = math.random(2, 4)
	for i = 1, stoneCount do
		local stone = Instance.new("Part")
		stone.Name = "SteppingStone_" .. i
		stone.Size = Vector3.new(
			math.random(4, 8),
			2,
			math.random(4, 8)
		)
		stone.Position = platform.Position + Vector3.new(
			math.random(-15, 15),
			math.random(3, 10),
			math.random(5, 20)
		)
		stone.Anchored = true
		stone.Material = Enum.Material.Slate
		stone.Color = Color3.fromRGB(40, 20, 20)
		stone.Parent = section

		stone:SetAttribute("CrumbleDelay", difficulty.CrumbleDelay or 2.5)
		CollectionService:AddTag(stone, "CrumblingPlatform")
	end

	-- Add red glow effect
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 0, 0)
	glow.Brightness = 0.5
	glow.Range = 30
	glow.Parent = platform
end

function DimensionService.AddSkyElements(section: Model, sectionNumber: number, config)
	local CollectionService = game:GetService("CollectionService")
	local platform = section:FindFirstChild("Platform")
	if not platform then return end

	local difficulty = DimensionService.GetSectionDifficulty(sectionNumber, config.Difficulty)

	-- Add wind current
	local windCurrent = Instance.new("Part")
	windCurrent.Name = "WindCurrent"
	windCurrent.Size = Vector3.new(15, 50, 15)
	windCurrent.Position = platform.Position + Vector3.new(
		math.random(-10, 10),
		25,
		math.random(10, 30)
	)
	windCurrent.Anchored = true
	windCurrent.CanCollide = false
	windCurrent.Transparency = 0.9
	windCurrent.Material = Enum.Material.ForceField
	windCurrent.Color = Color3.fromRGB(200, 230, 255)
	windCurrent.Parent = section

	-- Set wind direction and strength
	local directions = {
		Vector3.new(0, 1, 0), -- Up
		Vector3.new(1, 0.5, 0), -- Right-Up
		Vector3.new(-1, 0.5, 0), -- Left-Up
	}
	windCurrent:SetAttribute("WindDirection", directions[math.random(1, #directions)])
	windCurrent:SetAttribute("WindStrength", difficulty.WindStrength or 30)

	CollectionService:AddTag(windCurrent, "WindCurrent")

	-- Add updraft zone (refills glider boost)
	local updraft = Instance.new("Part")
	updraft.Name = "Updraft"
	updraft.Size = Vector3.new(20, 100, 20)
	updraft.Position = platform.Position + Vector3.new(0, 50, 0)
	updraft.Anchored = true
	updraft.CanCollide = false
	updraft.Transparency = 0.95
	updraft.Parent = section

	CollectionService:AddTag(updraft, "Updraft")

	-- Add cloud platforms
	local cloudCount = math.random(2, 4)
	for i = 1, cloudCount do
		local cloud = Instance.new("Part")
		cloud.Name = "CloudPlatform_" .. i
		cloud.Size = Vector3.new(
			math.random(8, 15),
			3,
			math.random(8, 15)
		)
		cloud.Position = platform.Position + Vector3.new(
			math.random(-20, 20),
			math.random(10, 40),
			math.random(10, 40)
		)
		cloud.Anchored = true
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Transparency = 0.3
		cloud.Parent = section

		-- Some clouds are fake (fall through)
		if math.random() < 0.2 then
			cloud.CanCollide = false
			cloud:SetAttribute("FakeCloud", true)
		end
	end
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function DimensionService.GetSectionDifficulty(sectionNumber: number, difficultyConfig)
	for difficulty, data in pairs(difficultyConfig) do
		local sections = data.Sections
		if sectionNumber >= sections[1] and sectionNumber <= sections[2] then
			return data
		end
	end
	return difficultyConfig.Easy -- Default
end

function DimensionService.CreateStartPlatform(dimensionName: string, config): Part
	local startPlatform = Instance.new("Part")
	startPlatform.Name = "StartPlatform"
	startPlatform.Size = Vector3.new(40, 5, 40)
	startPlatform.Position = Vector3.new(0, -10, 0)
	startPlatform.Anchored = true
	startPlatform.Material = Enum.Material.Neon
	startPlatform.Color = config.Theme.AccentColor

	-- Add spawn locations
	for i = 1, 16 do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn_" .. i
		spawn.Size = Vector3.new(4, 1, 4)
		spawn.Position = startPlatform.Position + Vector3.new(
			((i - 1) % 4 - 1.5) * 8,
			3,
			(math.floor((i - 1) / 4) - 1.5) * 8
		)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.CanCollide = false
		spawn.Transparency = 1
		spawn.Parent = startPlatform
	end

	return startPlatform
end

function DimensionService.CreateFinishLine(dimensionName: string, sectionCount: number, config): Part
	local yOffset = sectionCount * 20

	local finishLine = Instance.new("Part")
	finishLine.Name = "FinishLine"
	finishLine.Size = Vector3.new(30, 10, 5)
	finishLine.Position = Vector3.new(0, yOffset + 15, 0)
	finishLine.Anchored = true
	finishLine.CanCollide = false
	finishLine.Material = Enum.Material.Neon
	finishLine.Color = Color3.fromRGB(255, 215, 0)

	local CollectionService = game:GetService("CollectionService")
	CollectionService:AddTag(finishLine, "FinishLine")

	return finishLine
end

-- ============================================================================
-- DIMENSION HANDLERS
-- ============================================================================

function DimensionService.InitializeDimensionHandler(dimensionName: string)
	-- Load dimension-specific service
	local handlerName = dimensionName .. "Handler"

	-- Try to load handler (may not exist yet)
	local success, handler = pcall(function()
		return require(script.Parent:FindFirstChild(handlerName))
	end)

	if success and handler then
		DimensionService.DimensionHandlers[dimensionName] = handler
		if handler.Init then
			handler.Init()
		end
		print(string.format("[DimensionService] Initialized handler: %s", handlerName))
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function DimensionService.GetCurrentDimension(): string?
	return DimensionService.CurrentDimension
end

function DimensionService.GetDimensionConfig(dimensionName: string)
	return GameConfig.Dimensions[dimensionName]
end

function DimensionService.GetAllDimensions(): {string}
	local dimensions = {}
	for name, _ in pairs(GameConfig.Dimensions) do
		table.insert(dimensions, name)
	end
	return dimensions
end

function DimensionService.OnPlayerReachSection(player: Player, sectionNumber: number)
	local progress = DimensionService.PlayerProgress[player.UserId]
	if not progress then return end

	-- Only count forward progress
	if sectionNumber <= progress.section then return end

	progress.section = sectionNumber

	-- Notify client
	DimensionService.Remotes.SectionReached:FireClient(player, sectionNumber)

	print(string.format("[DimensionService] %s reached section %d", player.Name, sectionNumber))
end

function DimensionService.OnPlayerFinish(player: Player)
	local progress = DimensionService.PlayerProgress[player.UserId]
	if not progress or progress.finished then return end

	progress.finished = true
	progress.finishTime = tick() - progress.startTime

	print(string.format("[DimensionService] %s finished in %.2f seconds",
		player.Name, progress.finishTime))

	return progress.finishTime
end

-- ============================================================================
-- PRACTICE MODE
-- ============================================================================

DimensionService.PracticeInstances = {} -- [UserId] = { dimension, section, instance }

function DimensionService.StartPracticeMode(player: Player, dimensionName: string, sectionNumber: number?): boolean
	local config = GameConfig.Dimensions[dimensionName]
	if not config then
		warn("[DimensionService] Unknown dimension for practice: " .. tostring(dimensionName))
		return false
	end

	-- Clean up any existing practice instance
	DimensionService.StopPracticeMode(player)

	sectionNumber = sectionNumber or 1

	-- Create personal practice area
	local practiceFolder = Instance.new("Folder")
	practiceFolder.Name = string.format("Practice_%s_%d", player.Name, player.UserId)
	practiceFolder.Parent = workspace

	-- Generate a smaller practice level
	if LevelGenerator then
		local practiceLevel = LevelGenerator.GeneratePracticeSection(dimensionName, sectionNumber, {
			seed = os.time() + player.UserId,
		})
		if practiceLevel then
			practiceLevel.Parent = practiceFolder
		end
	else
		-- Fallback: create a basic practice section
		local section = DimensionService.CreateSection(dimensionName, sectionNumber, config)
		section.Parent = practiceFolder

		-- Add a start spawn
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PracticeSpawn"
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.Position = Vector3.new(0, (sectionNumber - 1) * 20 - 5, 0)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Parent = practiceFolder
	end

	-- Store practice instance
	DimensionService.PracticeInstances[player.UserId] = {
		dimension = dimensionName,
		section = sectionNumber,
		instance = practiceFolder,
	}

	-- Teleport player to practice area
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local spawnPoint = practiceFolder:FindFirstChild("PracticeSpawn")
		if rootPart and spawnPoint then
			rootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
		end
	end

	-- Notify client
	DimensionService.Remotes.DimensionChanged:FireClient(player, dimensionName, {
		IsPractice = true,
		Section = sectionNumber,
	})

	print(string.format("[DimensionService] %s started practice mode: %s Section %d",
		player.Name, dimensionName, sectionNumber))

	return true
end

function DimensionService.StopPracticeMode(player: Player)
	local practice = DimensionService.PracticeInstances[player.UserId]
	if not practice then return end

	-- Destroy practice instance
	if practice.instance and practice.instance.Parent then
		practice.instance:Destroy()
	end

	DimensionService.PracticeInstances[player.UserId] = nil

	-- Notify client
	DimensionService.Remotes.DimensionChanged:FireClient(player, nil, {
		IsPractice = false,
	})

	print(string.format("[DimensionService] %s ended practice mode", player.Name))
end

function DimensionService.RestartPracticeSection(player: Player)
	local practice = DimensionService.PracticeInstances[player.UserId]
	if not practice then return end

	-- Restart same section
	DimensionService.StartPracticeMode(player, practice.dimension, practice.section)
end

function DimensionService.AdvancePracticeSection(player: Player)
	local practice = DimensionService.PracticeInstances[player.UserId]
	if not practice then return end

	local config = GameConfig.Dimensions[practice.dimension]
	if not config then return end

	local nextSection = practice.section + 1
	if nextSection > config.Settings.SectionCount then
		nextSection = 1 -- Loop back to start
	end

	DimensionService.StartPracticeMode(player, practice.dimension, nextSection)
end

function DimensionService.IsInPracticeMode(player: Player): boolean
	return DimensionService.PracticeInstances[player.UserId] ~= nil
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function DimensionService.DebugPrint()
	print("=== DIMENSION SERVICE STATUS ===")
	print(string.format("Current Dimension: %s", DimensionService.CurrentDimension or "None"))
	print(string.format("Loaded Sections: %d", #DimensionService.LoadedSections))
	print(string.format("Is Transitioning: %s", tostring(DimensionService.IsTransitioning)))

	print("\nPlayer Progress:")
	for userId, progress in pairs(DimensionService.PlayerProgress) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Section %d, Finished: %s",
				player.Name, progress.section, tostring(progress.finished)))
		end
	end
	print("=================================")
end

return DimensionService
