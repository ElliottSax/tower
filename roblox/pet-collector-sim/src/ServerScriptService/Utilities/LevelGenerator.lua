--[[
	LevelGenerator.lua
	Helper utility for auto-generating basic level templates

	Usage (in Command Bar):
	local LevelGen = require(game.ServerScriptService.Utilities.LevelGenerator)
	LevelGen.GenerateBasicLevel(1, 1, 8) -- World 1, Level 1, 8 platforms

	Features:
	- Auto-generates platform paths
	- Creates checkpoints
	- Adds finish line
	- Includes scripts
	- Customizable parameters

	NOTE: Run in Studio Command Bar, not in game!
--]]

local LevelGenerator = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DEFAULTS = {
	PlatformSize = Vector3.new(10, 1, 10),
	PlatformSpacing = 15,
	PlatformColor = Color3.fromRGB(130, 80, 50), -- Wood brown
	CheckpointColor = Color3.fromRGB(255, 255, 0), -- Yellow
	FinishColor = Color3.fromRGB(100, 255, 100), -- Green
	StartPosition = Vector3.new(200, 10, 0),
}

-- ============================================================================
-- LEVEL GENERATION
-- ============================================================================

function LevelGenerator.GenerateBasicLevel(worldId: number, levelId: number, platformCount: number)
	print(string.format("[LevelGenerator] Generating World%d_Level%d with %d platforms...",
		worldId, levelId, platformCount))

	local Workspace = game:GetService("Workspace")

	-- Create level folder
	local levelFolder = Instance.new("Folder")
	levelFolder.Name = string.format("World%d_Level%d", worldId, levelId)
	levelFolder.Parent = Workspace

	-- Create spawn point
	local spawn = LevelGenerator.CreateSpawn(DEFAULTS.StartPosition)
	spawn.Parent = levelFolder

	-- Generate platform path
	local platforms = LevelGenerator.GeneratePlatforms(platformCount, DEFAULTS.StartPosition)
	for _, platform in ipairs(platforms) do
		platform.Parent = levelFolder
	end

	-- Create checkpoints (every 3 platforms)
	local checkpointPositions = {}
	for i = 3, platformCount - 1, 3 do
		table.insert(checkpointPositions, i)
	end

	for checkpointIndex, platformIndex in ipairs(checkpointPositions) do
		local checkpoint = LevelGenerator.CreateCheckpoint(
			checkpointIndex,
			platforms[platformIndex].Position
		)
		checkpoint.Parent = levelFolder
	end

	-- Create finish line at end
	local lastPlatform = platforms[#platforms]
	local finish = LevelGenerator.CreateFinish(lastPlatform.Position + Vector3.new(DEFAULTS.PlatformSpacing, 0, 0))
	finish.Parent = levelFolder

	print(string.format("[LevelGenerator] ✓ Generated level with %d platforms, %d checkpoints",
		platformCount, #checkpointPositions))

	return levelFolder
end

-- ============================================================================
-- COMPONENTS
-- ============================================================================

function LevelGenerator.CreateSpawn(position: Vector3)
	local spawn = Instance.new("Part")
	spawn.Name = "Spawn"
	spawn.Size = DEFAULTS.PlatformSize
	spawn.Position = position
	spawn.Anchored = true
	spawn.Material = Enum.Material.Neon
	spawn.BrickColor = BrickColor.new("Lime green")
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth

	return spawn
end

function LevelGenerator.GeneratePlatforms(count: number, startPosition: Vector3)
	local platforms = {}
	local currentPos = startPosition + Vector3.new(DEFAULTS.PlatformSpacing, 0, 0)

	for i = 1, count do
		local platform = Instance.new("Part")
		platform.Name = string.format("Platform%d", i)
		platform.Size = DEFAULTS.PlatformSize
		platform.Position = currentPos
		platform.Anchored = true
		platform.Material = Enum.Material.Plastic
		platform.Color = DEFAULTS.PlatformColor
		platform.TopSurface = Enum.SurfaceType.Smooth
		platform.BottomSurface = Enum.SurfaceType.Smooth

		table.insert(platforms, platform)

		-- Move to next position
		currentPos = currentPos + Vector3.new(DEFAULTS.PlatformSpacing, 0, 0)
	end

	return platforms
end

function LevelGenerator.CreateCheckpoint(checkpointId: number, position: Vector3)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = string.format("Checkpoint%d", checkpointId)
	checkpoint.Size = DEFAULTS.PlatformSize
	checkpoint.Position = position
	checkpoint.Anchored = true
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = DEFAULTS.CheckpointColor
	checkpoint.Transparency = 0.5
	checkpoint.TopSurface = Enum.SurfaceType.Smooth
	checkpoint.BottomSurface = Enum.SurfaceType.Smooth

	-- Add checkpoint script
	local script = Instance.new("Script")
	script.Name = "CheckpointScript"
	script.Source = LevelGenerator.GetCheckpointScript(checkpointId)
	script.Parent = checkpoint

	return checkpoint
end

function LevelGenerator.CreateFinish(position: Vector3)
	local finish = Instance.new("Part")
	finish.Name = "Finish"
	finish.Size = Vector3.new(12, 8, 1)
	finish.Position = position
	finish.Anchored = true
	finish.Material = Enum.Material.Neon
	finish.Color = DEFAULTS.FinishColor
	finish.TopSurface = Enum.SurfaceType.Smooth
	finish.BottomSurface = Enum.SurfaceType.Smooth

	-- Add finish script
	local script = Instance.new("Script")
	script.Name = "FinishScript"
	script.Source = LevelGenerator.GetFinishScript()
	script.Parent = finish

	return finish
end

-- ============================================================================
-- SCRIPTS
-- ============================================================================

function LevelGenerator.GetCheckpointScript(checkpointId: number)
	return string.format([[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local setCheckpointRemote = remoteEvents:WaitForChild("SetCheckpoint")

local CHECKPOINT_ID = %d

script.Parent.Touched:Connect(function(hit)
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			setCheckpointRemote:FireServer(CHECKPOINT_ID, script.Parent.CFrame)
			print("Checkpoint", CHECKPOINT_ID, "saved for", player.Name)
		end
	end
end)
]], checkpointId)
end

function LevelGenerator.GetFinishScript()
	return [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local completeLevelEvent = remoteEvents:WaitForChild("CompleteLevelEvent")

local debounce = {}

script.Parent.Touched:Connect(function(hit)
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player and not debounce[player] then
			debounce[player] = true

			print(player.Name, "completed the level!")
			completeLevelEvent:FireServer()

			-- Show completion message
			local gui = Instance.new("ScreenGui")
			gui.ResetOnSpawn = false

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0.2, 0)
			label.Position = UDim2.new(0, 0, 0.4, 0)
			label.BackgroundTransparency = 1
			label.Text = "LEVEL COMPLETE!"
			label.TextColor3 = Color3.new(0, 1, 0)
			label.TextScaled = true
			label.Font = Enum.Font.SourceSansBold
			label.Parent = gui

			gui.Parent = player.PlayerGui

			wait(2)
			gui:Destroy()

			task.wait(1)
			debounce[player] = nil
		end
	end
end)
]]
end

-- ============================================================================
-- ADVANCED GENERATION
-- ============================================================================

function LevelGenerator.GenerateZigzagLevel(worldId: number, levelId: number, sections: number)
	-- Generate a level with zigzag pattern
	print(string.format("[LevelGenerator] Generating zigzag World%d_Level%d...", worldId, levelId))

	local Workspace = game:GetService("Workspace")
	local levelFolder = Instance.new("Folder")
	levelFolder.Name = string.format("World%d_Level%d", worldId, levelId)
	levelFolder.Parent = Workspace

	-- Create spawn
	local spawn = LevelGenerator.CreateSpawn(DEFAULTS.StartPosition)
	spawn.Parent = levelFolder

	-- Generate zigzag platforms
	local currentPos = DEFAULTS.StartPosition + Vector3.new(DEFAULTS.PlatformSpacing, 0, 0)
	local direction = 1 -- 1 or -1 for zigzag
	local platformCount = 0

	for section = 1, sections do
		-- Create 3 platforms in current direction
		for i = 1, 3 do
			platformCount = platformCount + 1
			local platform = Instance.new("Part")
			platform.Name = string.format("Platform%d", platformCount)
			platform.Size = DEFAULTS.PlatformSize
			platform.Position = currentPos
			platform.Anchored = true
			platform.Material = Enum.Material.Plastic
			platform.Color = DEFAULTS.PlatformColor
			platform.Parent = levelFolder

			-- Move forward and sideways
			currentPos = currentPos + Vector3.new(DEFAULTS.PlatformSpacing * 0.7, 0, DEFAULTS.PlatformSpacing * 0.5 * direction)
		end

		-- Reverse direction
		direction = direction * -1

		-- Add checkpoint
		if section % 2 == 0 then
			local checkpoint = LevelGenerator.CreateCheckpoint(section / 2, currentPos)
			checkpoint.Parent = levelFolder
		end
	end

	-- Create finish
	local finish = LevelGenerator.CreateFinish(currentPos + Vector3.new(DEFAULTS.PlatformSpacing, 0, 0))
	finish.Parent = levelFolder

	print(string.format("[LevelGenerator] ✓ Generated zigzag level with %d platforms", platformCount))

	return levelFolder
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function LevelGenerator.DeleteLevel(worldId: number, levelId: number)
	local Workspace = game:GetService("Workspace")
	local levelName = string.format("World%d_Level%d", worldId, levelId)
	local level = Workspace:FindFirstChild(levelName)

	if level then
		level:Destroy()
		print(string.format("[LevelGenerator] Deleted %s", levelName))
	else
		warn(string.format("[LevelGenerator] Level not found: %s", levelName))
	end
end

function LevelGenerator.ListGeneratedLevels()
	local Workspace = game:GetService("Workspace")
	print("[LevelGenerator] Generated levels:")

	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name:match("^World%d+_Level%d+$") then
			local platformCount = 0
			for _, part in ipairs(child:GetChildren()) do
				if part.Name:match("^Platform%d+$") then
					platformCount = platformCount + 1
				end
			end
			print(string.format("  - %s (%d platforms)", child.Name, platformCount))
		end
	end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

print([[
[LevelGenerator] Loaded! Usage:

Basic level:
local LevelGen = require(game.ServerScriptService.Utilities.LevelGenerator)
LevelGen.GenerateBasicLevel(1, 1, 8)  -- World, Level, Platforms

Zigzag level:
LevelGen.GenerateZigzagLevel(1, 2, 5)  -- World, Level, Sections

Utilities:
LevelGen.ListGeneratedLevels()
LevelGen.DeleteLevel(1, 1)  -- Delete World1_Level1
]])

return LevelGenerator
