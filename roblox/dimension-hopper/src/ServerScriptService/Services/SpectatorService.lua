--[[
	SpectatorService.lua
	Handles spectator mode for watching races

	Features:
	- Spectate players who finished or are racing
	- Cycle through active players
	- Free camera mode
	- UI for spectator controls
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SpectatorService = {}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { mode, targetUserId, freeCamPosition }
SpectatorService.Spectators = {}

-- List of active racers to spectate
SpectatorService.ActiveRacers = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SpectatorService.Init()
	print("[SpectatorService] Initializing...")

	SpectatorService.CreateRemotes()

	-- Player connections
	Players.PlayerAdded:Connect(function(player)
		SpectatorService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		SpectatorService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		SpectatorService.OnPlayerJoin(player)
	end

	print("[SpectatorService] Initialized")
end

function SpectatorService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Enter spectator mode
	if not remoteFolder:FindFirstChild("EnterSpectatorMode") then
		local event = Instance.new("RemoteEvent")
		event.Name = "EnterSpectatorMode"
		event.Parent = remoteFolder
	end

	-- Exit spectator mode
	if not remoteFolder:FindFirstChild("ExitSpectatorMode") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ExitSpectatorMode"
		event.Parent = remoteFolder
	end

	-- Spectate target update
	if not remoteFolder:FindFirstChild("SpectateTarget") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SpectateTarget"
		event.Parent = remoteFolder
	end

	-- Spectator sync
	if not remoteFolder:FindFirstChild("SpectatorSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SpectatorSync"
		event.Parent = remoteFolder
	end

	-- Cycle spectate target
	if not remoteFolder:FindFirstChild("CycleSpectateTarget") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CycleSpectateTarget"
		event.Parent = remoteFolder
	end

	SpectatorService.Remotes = {
		EnterSpectatorMode = remoteFolder.EnterSpectatorMode,
		ExitSpectatorMode = remoteFolder.ExitSpectatorMode,
		SpectateTarget = remoteFolder.SpectateTarget,
		SpectatorSync = remoteFolder.SpectatorSync,
		CycleSpectateTarget = remoteFolder.CycleSpectateTarget,
	}

	-- Connect events
	SpectatorService.Remotes.EnterSpectatorMode.OnServerEvent:Connect(function(player)
		SpectatorService.EnterSpectatorMode(player)
	end)

	SpectatorService.Remotes.ExitSpectatorMode.OnServerEvent:Connect(function(player)
		SpectatorService.ExitSpectatorMode(player)
	end)

	SpectatorService.Remotes.CycleSpectateTarget.OnServerEvent:Connect(function(player, direction)
		SpectatorService.CycleTarget(player, direction)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function SpectatorService.OnPlayerJoin(player: Player)
	SpectatorService.Spectators[player.UserId] = nil
end

function SpectatorService.OnPlayerLeave(player: Player)
	-- Remove from spectators
	SpectatorService.Spectators[player.UserId] = nil

	-- Update any spectators watching this player
	for userId, specData in pairs(SpectatorService.Spectators) do
		if specData.targetUserId == player.UserId then
			local spectator = Players:GetPlayerByUserId(userId)
			if spectator then
				SpectatorService.CycleTarget(spectator, 1)
			end
		end
	end

	-- Remove from active racers
	SpectatorService.RemoveRacer(player)
end

-- ============================================================================
-- SPECTATOR MODE
-- ============================================================================

function SpectatorService.EnterSpectatorMode(player: Player)
	if SpectatorService.Spectators[player.UserId] then
		return -- Already spectating
	end

	-- Check if there are racers to spectate
	if #SpectatorService.ActiveRacers == 0 then
		warn("[SpectatorService] No active racers to spectate")
		return
	end

	-- Hide player character
	local character = player.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
				part.CanCollide = false
			end
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	-- Setup spectator state
	local firstTarget = SpectatorService.ActiveRacers[1]
	SpectatorService.Spectators[player.UserId] = {
		mode = "follow",
		targetUserId = firstTarget.UserId,
		freeCamPosition = nil,
	}

	-- Notify client
	SpectatorService.SyncToClient(player)

	print(string.format("[SpectatorService] %s entered spectator mode", player.Name))
end

function SpectatorService.ExitSpectatorMode(player: Player)
	local specData = SpectatorService.Spectators[player.UserId]
	if not specData then return end

	-- Restore character
	local character = player.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0
				part.CanCollide = true
			end
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = GameConfig.Player.BaseWalkSpeed
			humanoid.JumpPower = GameConfig.Player.BaseJumpPower
		end
	end

	-- Clear spectator state
	SpectatorService.Spectators[player.UserId] = nil

	-- Notify client
	SpectatorService.Remotes.SpectatorSync:FireClient(player, nil)

	print(string.format("[SpectatorService] %s exited spectator mode", player.Name))
end

function SpectatorService.CycleTarget(player: Player, direction: number)
	local specData = SpectatorService.Spectators[player.UserId]
	if not specData then return end

	if #SpectatorService.ActiveRacers == 0 then return end

	-- Find current index
	local currentIndex = 1
	for i, racer in ipairs(SpectatorService.ActiveRacers) do
		if racer.UserId == specData.targetUserId then
			currentIndex = i
			break
		end
	end

	-- Calculate new index
	local newIndex = currentIndex + (direction or 1)
	if newIndex < 1 then
		newIndex = #SpectatorService.ActiveRacers
	elseif newIndex > #SpectatorService.ActiveRacers then
		newIndex = 1
	end

	-- Update target
	specData.targetUserId = SpectatorService.ActiveRacers[newIndex].UserId

	-- Sync to client
	SpectatorService.SyncToClient(player)
end

function SpectatorService.SetTarget(spectator: Player, target: Player)
	local specData = SpectatorService.Spectators[spectator.UserId]
	if not specData then return end

	specData.targetUserId = target.UserId
	SpectatorService.SyncToClient(spectator)
end

-- ============================================================================
-- RACER TRACKING
-- ============================================================================

function SpectatorService.AddRacer(player: Player)
	-- Don't add duplicates
	for _, racer in ipairs(SpectatorService.ActiveRacers) do
		if racer.UserId == player.UserId then
			return
		end
	end

	table.insert(SpectatorService.ActiveRacers, player)
	print(string.format("[SpectatorService] Added racer: %s", player.Name))
end

function SpectatorService.RemoveRacer(player: Player)
	for i, racer in ipairs(SpectatorService.ActiveRacers) do
		if racer.UserId == player.UserId then
			table.remove(SpectatorService.ActiveRacers, i)
			print(string.format("[SpectatorService] Removed racer: %s", player.Name))
			break
		end
	end
end

function SpectatorService.ClearRacers()
	SpectatorService.ActiveRacers = {}
end

function SpectatorService.SetRacers(racers: {Player})
	SpectatorService.ActiveRacers = racers

	-- Update spectator targets if their target left
	for userId, specData in pairs(SpectatorService.Spectators) do
		local found = false
		for _, racer in ipairs(racers) do
			if racer.UserId == specData.targetUserId then
				found = true
				break
			end
		end

		if not found and #racers > 0 then
			specData.targetUserId = racers[1].UserId
			local spectator = Players:GetPlayerByUserId(userId)
			if spectator then
				SpectatorService.SyncToClient(spectator)
			end
		end
	end
end

-- ============================================================================
-- SYNC
-- ============================================================================

function SpectatorService.SyncToClient(player: Player)
	local specData = SpectatorService.Spectators[player.UserId]
	if not specData then return end

	local targetPlayer = Players:GetPlayerByUserId(specData.targetUserId)
	local targetName = targetPlayer and targetPlayer.Name or "Unknown"

	local syncData = {
		Mode = specData.mode,
		TargetUserId = specData.targetUserId,
		TargetName = targetName,
		TotalRacers = #SpectatorService.ActiveRacers,
	}

	-- Include target position for camera
	if targetPlayer and targetPlayer.Character then
		local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			syncData.TargetPosition = rootPart.Position
		end
	end

	SpectatorService.Remotes.SpectatorSync:FireClient(player, syncData)
end

function SpectatorService.SyncAllSpectators()
	for userId in pairs(SpectatorService.Spectators) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			SpectatorService.SyncToClient(player)
		end
	end
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function SpectatorService.IsSpectating(player: Player): boolean
	return SpectatorService.Spectators[player.UserId] ~= nil
end

function SpectatorService.GetSpectatorCount(): number
	local count = 0
	for _ in pairs(SpectatorService.Spectators) do
		count = count + 1
	end
	return count
end

function SpectatorService.GetActiveRacerCount(): number
	return #SpectatorService.ActiveRacers
end

return SpectatorService
