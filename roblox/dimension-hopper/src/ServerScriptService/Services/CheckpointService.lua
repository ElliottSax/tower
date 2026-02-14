--[[
	CheckpointService.lua
	Handles checkpoint/section progression for Dimension Hopper

	Features:
	- Section-based checkpoints
	- Respawn at last checkpoint
	- Progress tracking per player
	- Integration with RaceService
	- Dimension-specific checkpoint handling
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CheckpointService = {}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { currentSection, lastCheckpoint, respawnCFrame }
CheckpointService.PlayerProgress = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CheckpointService.Init()
	print("[CheckpointService] Initializing...")

	-- Create remotes
	CheckpointService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		CheckpointService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CheckpointService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		CheckpointService.OnPlayerJoin(player)
	end

	-- Setup checkpoint detection
	CheckpointService.SetupCheckpoints()

	print("[CheckpointService] Initialized")
end

function CheckpointService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Checkpoint reached
	if not remoteFolder:FindFirstChild("CheckpointReached") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CheckpointReached"
		event.Parent = remoteFolder
	end

	-- Request respawn (client -> server)
	if not remoteFolder:FindFirstChild("RequestRespawn") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RequestRespawn"
		event.Parent = remoteFolder
	end

	CheckpointService.Remotes = {
		CheckpointReached = remoteFolder.CheckpointReached,
		RequestRespawn = remoteFolder.RequestRespawn,
	}

	-- Handle respawn requests
	CheckpointService.Remotes.RequestRespawn.OnServerEvent:Connect(function(player)
		CheckpointService.RespawnPlayer(player)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function CheckpointService.OnPlayerJoin(player: Player)
	CheckpointService.PlayerProgress[player.UserId] = {
		currentSection = 0,
		lastCheckpoint = nil,
		respawnCFrame = nil,
	}

	player.CharacterAdded:Connect(function(character)
		CheckpointService.OnCharacterAdded(player, character)
	end)
end

function CheckpointService.OnPlayerLeave(player: Player)
	CheckpointService.PlayerProgress[player.UserId] = nil
end

function CheckpointService.OnCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Handle death
	humanoid.Died:Connect(function()
		task.delay(GameConfig.Player.RespawnTime or 1, function()
			CheckpointService.RespawnPlayer(player)
		end)
	end)

	-- Teleport to last checkpoint if we have one
	local progress = CheckpointService.PlayerProgress[player.UserId]
	if progress and progress.respawnCFrame then
		task.wait(0.1) -- Wait for character to fully load
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = progress.respawnCFrame
		end
	end
end

-- ============================================================================
-- CHECKPOINT DETECTION
-- ============================================================================

function CheckpointService.SetupCheckpoints()
	-- Connect to existing checkpoints
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		CheckpointService.ConnectCheckpoint(checkpoint)
	end

	-- Listen for new checkpoints
	CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(function(checkpoint)
		CheckpointService.ConnectCheckpoint(checkpoint)
	end)
end

function CheckpointService.ConnectCheckpoint(checkpoint: BasePart)
	checkpoint.Touched:Connect(function(hit)
		CheckpointService.OnCheckpointTouched(checkpoint, hit)
	end)
end

function CheckpointService.OnCheckpointTouched(checkpoint: BasePart, hit: BasePart)
	-- Verify it's a player
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local progress = CheckpointService.PlayerProgress[player.UserId]
	if not progress then return end

	-- Get section number
	local sectionNumber = checkpoint:GetAttribute("Section") or 1

	-- Only progress forward
	if sectionNumber <= progress.currentSection then return end

	-- Update progress
	progress.currentSection = sectionNumber
	progress.lastCheckpoint = checkpoint
	progress.respawnCFrame = checkpoint.CFrame + Vector3.new(0, 3, 0)

	-- Notify client
	CheckpointService.Remotes.CheckpointReached:FireClient(player, {
		Section = sectionNumber,
		Dimension = checkpoint:GetAttribute("Dimension"),
	})

	-- Notify other services
	CheckpointService.NotifyServices(player, sectionNumber)

	print(string.format("[CheckpointService] %s reached section %d",
		player.Name, sectionNumber))
end

function CheckpointService.NotifyServices(player: Player, sectionNumber: number)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	-- Notify RaceService
	local RaceService = DimensionHopper.GetService("RaceService")
	if RaceService and RaceService.OnPlayerReachSection then
		RaceService.OnPlayerReachSection(player, sectionNumber)
	end

	-- Notify VoidService (for safe zones)
	local VoidService = DimensionHopper.GetService("VoidService")
	if VoidService and VoidService.OnPlayerReachCheckpoint then
		VoidService.OnPlayerReachCheckpoint(player, sectionNumber)
	end
end

-- ============================================================================
-- RESPAWN
-- ============================================================================

function CheckpointService.RespawnPlayer(player: Player)
	local character = player.Character
	if not character then
		player:LoadCharacter()
		return
	end

	local progress = CheckpointService.PlayerProgress[player.UserId]
	if not progress or not progress.respawnCFrame then
		-- No checkpoint - use default spawn
		player:LoadCharacter()
		return
	end

	-- Respawn at checkpoint
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if rootPart and humanoid then
		-- Heal and teleport
		humanoid.Health = humanoid.MaxHealth
		rootPart.CFrame = progress.respawnCFrame

		-- Reset velocity
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero

		print(string.format("[CheckpointService] Respawned %s at section %d",
			player.Name, progress.currentSection))
	else
		-- Character broken - reload
		player:LoadCharacter()
	end
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function CheckpointService.GetPlayerSection(player: Player): number
	local progress = CheckpointService.PlayerProgress[player.UserId]
	return progress and progress.currentSection or 0
end

function CheckpointService.ResetPlayerProgress(player: Player)
	local progress = CheckpointService.PlayerProgress[player.UserId]
	if progress then
		progress.currentSection = 0
		progress.lastCheckpoint = nil
		progress.respawnCFrame = nil
	end
end

function CheckpointService.ResetAllProgress()
	for userId in pairs(CheckpointService.PlayerProgress) do
		CheckpointService.PlayerProgress[userId] = {
			currentSection = 0,
			lastCheckpoint = nil,
			respawnCFrame = nil,
		}
	end
end

function CheckpointService.GetTotalSections(): number
	-- Count total checkpoints tagged in the game
	local checkpoints = CollectionService:GetTagged("Checkpoint")
	return #checkpoints
end

function CheckpointService.SkipToSection(player: Player, targetSection: number): boolean
	local progress = CheckpointService.PlayerProgress[player.UserId]
	if not progress then return false end

	-- Find the checkpoint for target section
	local targetCheckpoint = nil
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		local sectionNum = checkpoint:GetAttribute("Section")
		if sectionNum == targetSection then
			targetCheckpoint = checkpoint
			break
		end
	end

	if not targetCheckpoint then
		warn(string.format("[CheckpointService] No checkpoint found for section %d", targetSection))
		return false
	end

	-- Update progress
	progress.currentSection = targetSection
	progress.lastCheckpoint = targetCheckpoint
	progress.respawnCFrame = targetCheckpoint.CFrame + Vector3.new(0, 3, 0)

	-- Teleport player
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = progress.respawnCFrame
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end

	-- Notify client
	CheckpointService.Remotes.CheckpointReached:FireClient(player, {
		Section = targetSection,
		Dimension = targetCheckpoint:GetAttribute("Dimension"),
		Skipped = true,
	})

	print(string.format("[CheckpointService] Skipped %s to section %d", player.Name, targetSection))
	return true
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function CheckpointService.DebugPrint()
	print("=== CHECKPOINT SERVICE STATUS ===")

	for userId, progress in pairs(CheckpointService.PlayerProgress) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Section %d",
				player.Name, progress.currentSection))
		end
	end

	print("=================================")
end

return CheckpointService
