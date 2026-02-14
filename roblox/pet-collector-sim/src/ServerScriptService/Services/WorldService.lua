--[[
	WorldService.lua
	Pet Collector Simulator - World Management

	Handles:
	- World unlocking (progression gates)
	- World teleportation
	- Coin multipliers per world
	- World-specific content
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}
WorldService.DataService = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function WorldService.Init()
	print("[WorldService] Initializing...")

	-- Setup remote events
	WorldService.SetupRemotes()

	print("[WorldService] Initialized")
end

function WorldService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Unlock world
	local unlockWorldRemote = remoteEvents:WaitForChild("UnlockWorld")
	unlockWorldRemote.OnServerEvent:Connect(function(player, worldId)
		WorldService.UnlockWorld(player, worldId)
	end)

	-- Teleport to world
	local teleportWorldRemote = remoteEvents:WaitForChild("TeleportToWorld")
	teleportWorldRemote.OnServerEvent:Connect(function(player, worldId)
		WorldService.TeleportToWorld(player, worldId)
	end)

	-- Get unlocked worlds
	local getUnlockedWorldsRemote = remoteEvents:WaitForChild("GetUnlockedWorlds")
	getUnlockedWorldsRemote.OnServerInvoke = function(player)
		return WorldService.GetUnlockedWorlds(player)
	end

	-- Get current world
	local getCurrentWorldRemote = remoteEvents:WaitForChild("GetCurrentWorld")
	getCurrentWorldRemote.OnServerInvoke = function(player)
		return WorldService.GetCurrentWorld(player)
	end
end

-- ============================================================================
-- WORLD UNLOCKING
-- ============================================================================

function WorldService.UnlockWorld(player: Player, worldId: number)
	if not WorldService.DataService then
		WorldService.DataService = require(ServerScriptService.Services.DataService)
	end

	-- Get world data
	local worldData = GameConfig.Worlds[worldId]
	if not worldData then
		warn(string.format("[WorldService] Invalid world ID: %d", worldId))
		return false
	end

	-- Check if already unlocked
	local playerData = WorldService.DataService.GetData(player)
	if not playerData then return false end

	if table.find(playerData.UnlockedWorlds, worldId) then
		warn(string.format("[WorldService] %s already unlocked World %d", player.Name, worldId))
		return false
	end

	-- Check VIP requirement
	if worldData.RequiresVIP then
		local MonetizationService = require(ServerScriptService.Services.MonetizationService)
		if not MonetizationService.HasGamePass(player, "VIP") then
			warn(string.format("[WorldService] %s needs VIP for World %d", player.Name, worldId))
			return false
		end
	end

	-- Check coin cost
	if playerData.Coins < worldData.UnlockCost then
		warn(string.format("[WorldService] %s cannot afford World %d (has %d, needs %d)",
			player.Name, worldId, playerData.Coins, worldData.UnlockCost))
		return false
	end

	-- Check pet requirement
	if #playerData.Pets < worldData.RequiredPets then
		warn(string.format("[WorldService] %s needs %d pets to unlock World %d (has %d)",
			player.Name, worldData.RequiredPets, worldId, #playerData.Pets))
		return false
	end

	-- Deduct cost
	WorldService.DataService.AddCoins(player, -worldData.UnlockCost)

	-- Unlock world
	table.insert(playerData.UnlockedWorlds, worldId)
	playerData.Stats.WorldsUnlocked = #playerData.UnlockedWorlds

	print(string.format("[WorldService] %s unlocked World %d: %s",
		player.Name, worldId, worldData.Name))

	-- Notify player
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
	if notifyRemote then
		notifyRemote:FireClient(player,
			string.format("Unlocked %s!", worldData.Name),
			"Success")
	end

	return true
end

function WorldService.GetUnlockedWorlds(player: Player)
	if not WorldService.DataService then
		WorldService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = WorldService.DataService.GetData(player)
	if not playerData then return {1} end

	return playerData.UnlockedWorlds or {1}
end

function WorldService.IsWorldUnlocked(player: Player, worldId: number)
	local unlocked = WorldService.GetUnlockedWorlds(player)
	return table.find(unlocked, worldId) ~= nil
end

-- ============================================================================
-- TELEPORTATION
-- ============================================================================

function WorldService.TeleportToWorld(player: Player, worldId: number)
	-- Check if unlocked
	if not WorldService.IsWorldUnlocked(player, worldId) then
		warn(string.format("[WorldService] %s tried to teleport to locked World %d", player.Name, worldId))
		return false
	end

	-- Find spawn point in world
	local worldFolder = workspace:FindFirstChild(string.format("World%d", worldId))
	if not worldFolder then
		warn(string.format("[WorldService] World %d folder not found in workspace", worldId))
		return false
	end

	local spawnPoint = worldFolder:FindFirstChild("SpawnPoint")
	if not spawnPoint then
		warn(string.format("[WorldService] SpawnPoint not found in World %d", worldId))
		return false
	end

	-- Teleport character
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)

			-- Update current world
			if not WorldService.DataService then
				WorldService.DataService = require(ServerScriptService.Services.DataService)
			end
			local playerData = WorldService.DataService.GetData(player)
			if playerData then
				playerData.CurrentWorld = worldId
			end

			print(string.format("[WorldService] Teleported %s to World %d", player.Name, worldId))
			return true
		end
	end

	return false
end

function WorldService.GetCurrentWorld(player: Player)
	if not WorldService.DataService then
		WorldService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = WorldService.DataService.GetData(player)
	if not playerData then return 1 end

	return playerData.CurrentWorld or 1
end

-- ============================================================================
-- WORLD BENEFITS
-- ============================================================================

function WorldService.GetWorldMultiplier(player: Player)
	local worldId = WorldService.GetCurrentWorld(player)
	local worldData = GameConfig.Worlds[worldId]

	if worldData then
		return worldData.CoinMultiplier or 1
	end

	return 1
end

function WorldService.GetAvailableEggs(player: Player)
	local worldId = WorldService.GetCurrentWorld(player)
	local worldData = GameConfig.Worlds[worldId]

	if worldData then
		return worldData.EggTypes or {"Basic"}
	end

	return {"Basic"}
end

return WorldService
