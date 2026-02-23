--[[
	WorldService.lua
	Manages world loading, transitions, and checkpoints

	Handles:
	- Level loading/unloading
	- Teleportation between levels
	- Checkpoint system
	- Level boundaries
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local StoryChapters = require(ReplicatedStorage.Shared.Data.StoryChapters)

local WorldService = {}
local StoryService = nil -- Lazy loaded
local NotificationService = nil -- Lazy loaded

-- Player checkpoint tracking
-- Format: [Player] = {WorldId = 1, LevelId = 1, CheckpointId = 1}
local PlayerCheckpoints = {}

-- Level start times (for speed run tracking)
local LevelStartTimes = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function WorldService.Init()
	print("[WorldService] Initializing...")

	-- Lazy load services
	StoryService = require(ServerScriptService.Services.StoryService)
	NotificationService = require(ServerScriptService.Utilities.NotificationService)

	-- Setup remote handlers
	WorldService.SetupRemoteHandlers()

	-- Player character respawn handling
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			WorldService.OnCharacterAdded(player, character)
		end)
	end)

	print("[WorldService] Initialized")
end

-- ============================================================================
-- LEVEL TRANSITIONS
-- ============================================================================

function WorldService.TeleportToLevel(player: Player, worldId: number, levelId: number): boolean
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[WorldService] Invalid player in TeleportToLevel")
		return false
	end

	-- Check if level is unlocked
	if not StoryService.IsLevelUnlocked(player, worldId, levelId) then
		warn(string.format("[WorldService] %s tried to enter locked level: World%d_Level%d",
			player.Name, worldId, levelId))
		return false
	end

	-- Find level spawn location
	local levelKey = string.format("World%d_Level%d", worldId, levelId)
	local spawnLocation = Workspace:FindFirstChild(levelKey, true)

	if not spawnLocation then
		-- Try finding in a Levels folder
		local levelsFolder = Workspace:FindFirstChild("Levels")
		if levelsFolder then
			spawnLocation = levelsFolder:FindFirstChild(levelKey, true)
		end
	end

	if not spawnLocation or not spawnLocation:FindFirstChild("Spawn") then
		warn(string.format("[WorldService] Spawn location not found for %s", levelKey))
		return false
	end

	-- Get character
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[WorldService] Character not found for player:", player.Name)
		return false
	end

	-- Teleport
	local spawn = spawnLocation:FindFirstChild("Spawn")
	character:SetPrimaryPartCFrame(spawn.CFrame + Vector3.new(0, 5, 0))

	-- Reset checkpoint
	PlayerCheckpoints[player] = {
		WorldId = worldId,
		LevelId = levelId,
		CheckpointId = 1,
		SpawnCFrame = spawn.CFrame,
	}

	-- Track level start time
	LevelStartTimes[player] = os.clock()

	print(string.format("[WorldService] Teleported %s to World%d_Level%d",
		player.Name, worldId, levelId))

	return true
end

function WorldService.TeleportToHub(player: Player): boolean
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[WorldService] Invalid player in TeleportToHub")
		return false
	end

	-- Find hub spawn
	local hubSpawn = Workspace:FindFirstChild("HubSpawn", true)
	if not hubSpawn then
		warn("[WorldService] Hub spawn not found")
		return false
	end

	-- Get character
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[WorldService] Character not found for player:", player.Name)
		return false
	end

	-- Teleport
	character:SetPrimaryPartCFrame(hubSpawn.CFrame + Vector3.new(0, 5, 0))

	-- Clear checkpoint
	PlayerCheckpoints[player] = nil
	LevelStartTimes[player] = nil

	print(string.format("[WorldService] Teleported %s to Hub", player.Name))

	return true
end

-- ============================================================================
-- CHECKPOINTS
-- ============================================================================

function WorldService.SetCheckpoint(player: Player, checkpointId: number, checkpointCFrame: CFrame)
	-- CRITICAL FIX: Server-authoritative checkpoint validation
	-- NEVER trust client-provided CFrame - exploiters can teleport anywhere

	local checkpoint = PlayerCheckpoints[player]
	if not checkpoint then
		warn("[WorldService] No active level for player:", player.Name)
		return
	end

	-- Validate checkpointId
	if type(checkpointId) ~= "number" or checkpointId < 1 or checkpointId ~= math.floor(checkpointId) then
		warn(string.format("[WorldService] Invalid checkpointId from %s: %s", player.Name, tostring(checkpointId)))
		return
	end

	-- Find checkpoint part in workspace (server-authoritative)
	local checkpointPart = workspace:FindFirstChild("Checkpoints")
	if not checkpointPart then
		warn("[WorldService] Checkpoints folder not found in workspace")
		return
	end

	local checkpointObj = checkpointPart:FindFirstChild("Checkpoint_" .. tostring(checkpointId))
	if not checkpointObj or not checkpointObj:IsA("BasePart") then
		warn(string.format("[WorldService] Checkpoint %d not found in workspace", checkpointId))
		return
	end

	-- Validate player is near checkpoint (anti-exploit: must be within 50 studs)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local distance = (humanoidRootPart.Position - checkpointObj.Position).Magnitude
	if distance > 50 then
		warn(string.format("[WorldService] %s too far from checkpoint %d (%.1f studs)",
			player.Name, checkpointId, distance))
		-- Flag potential exploiter
		if WorldService.SecurityManager then
			WorldService.SecurityManager._FlagPlayer(player, "CheckpointTooFar_" .. tostring(checkpointId))
		end
		return
	end

	-- Update checkpoint using SERVER position (not client-provided CFrame)
	checkpoint.CheckpointId = checkpointId
	checkpoint.SpawnCFrame = checkpointObj.CFrame + Vector3.new(0, 3, 0) -- Spawn slightly above checkpoint

	print(string.format("[WorldService] %s reached checkpoint %d", player.Name, checkpointId))
end

function WorldService.RespawnAtCheckpoint(player: Player)
	local checkpoint = PlayerCheckpoints[player]
	if not checkpoint or not checkpoint.SpawnCFrame then
		-- No checkpoint, respawn at hub
		WorldService.TeleportToHub(player)
		return
	end

	-- Get character
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[WorldService] Character not found for player:", player.Name)
		return
	end

	-- Teleport to checkpoint
	character:SetPrimaryPartCFrame(checkpoint.SpawnCFrame + Vector3.new(0, 5, 0))

	print(string.format("[WorldService] Respawned %s at checkpoint %d",
		player.Name, checkpoint.CheckpointId))
end

function WorldService.OnCharacterAdded(player: Player, character: Instance)
	-- Wait for character to load
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Connect death handler
	humanoid.Died:Connect(function()
		WorldService.OnPlayerDeath(player)
	end)

	-- If player has active checkpoint, respawn there after short delay
	task.wait(0.5)
	if PlayerCheckpoints[player] then
		WorldService.RespawnAtCheckpoint(player)
	end
end

function WorldService.OnPlayerDeath(player: Player)
	print(string.format("[WorldService] %s died", player.Name))

	-- Track death stat
	local DataService = require(ServerScriptService.Services.DataService)
	DataService.IncrementDeaths(player)

	-- Respawn will be handled by OnCharacterAdded
end

-- ============================================================================
-- LEVEL COMPLETION
-- ============================================================================

function WorldService.CompleteCurrentLevel(player: Player): boolean
	local checkpoint = PlayerCheckpoints[player]
	if not checkpoint then
		warn("[WorldService] No active level for player:", player.Name)
		return false
	end

	-- Calculate completion time
	local completionTime = nil
	if LevelStartTimes[player] then
		completionTime = os.clock() - LevelStartTimes[player]
	end

	-- Complete level via StoryService
	local success = StoryService.CompleteLevel(player, checkpoint.WorldId, checkpoint.LevelId)

	if success then
		print(string.format("[WorldService] %s completed World%d_Level%d in %.1fs",
			player.Name, checkpoint.WorldId, checkpoint.LevelId, completionTime or 0))

		-- Send notification
		if NotificationService then
			NotificationService.Success(player, string.format("Level %d Complete! ✓", checkpoint.LevelId))
		end

		-- Clear checkpoint and timer
		PlayerCheckpoints[player] = nil
		LevelStartTimes[player] = nil

		-- Teleport back to hub
		task.wait(2) -- Give time for celebration
		WorldService.TeleportToHub(player)
	end

	return success
end

-- ============================================================================
-- PLAYER STATE
-- ============================================================================

function WorldService.GetPlayerLevel(player: Player)
	return PlayerCheckpoints[player]
end

function WorldService.IsInLevel(player: Player): boolean
	return PlayerCheckpoints[player] ~= nil
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function WorldService.SetupRemoteHandlers()
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

	-- TeleportToLevel
	local teleportToLevelRemote = RemoteEventsInit.GetRemote("TeleportToLevel")
	if teleportToLevelRemote and teleportToLevelRemote.Remote then
		teleportToLevelRemote.Remote.OnServerInvoke = function(player, worldId, levelId)
			return WorldService.TeleportToLevel(player, worldId, levelId)
		end
	end

	-- TeleportToHub
	local teleportToHubRemote = RemoteEventsInit.GetRemote("TeleportToHub")
	if teleportToHubRemote and teleportToHubRemote.Remote then
		teleportToHubRemote.Remote.OnServerInvoke = function(player)
			return WorldService.TeleportToHub(player)
		end
	end

	-- CompleteLevel
	local completeLevelRemote = RemoteEventsInit.GetRemote("CompleteLevelEvent")
	if completeLevelRemote and completeLevelRemote.Remote then
		completeLevelRemote.Remote.OnServerEvent:Connect(function(player)
			WorldService.CompleteCurrentLevel(player)
		end)
	end

	-- SetCheckpoint
	local setCheckpointRemote = RemoteEventsInit.GetRemote("SetCheckpoint")
	if setCheckpointRemote and setCheckpointRemote.Remote then
		setCheckpointRemote.Remote.OnServerEvent:Connect(function(player, checkpointId, checkpointCFrame)
			WorldService.SetCheckpoint(player, checkpointId, checkpointCFrame)
		end)
	end

	print("[WorldService] Remote handlers setup complete")
end

return WorldService
