--[[
	Main.server.lua - Merge Mania Entry Point
	Merge/Idle Game: Combine items on a grid to create higher-tier items

	Core Loop: Generators spawn items -> Merge same-tier items -> Earn passive coins
	           -> Buy better generators -> Prestige for permanent multipliers
	           -> Collect sets for permanent bonuses

	4 Merge Paths: Weapons, Pets, Food, Gems (each with 20 tiers)
	Features: Lucky merges, collections, prestige, offline earnings, events
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- ============================================================================
-- SERVICE INITIALIZATION ORDER
-- ============================================================================

print("========================================")
print("  MERGE MANIA - Server Starting...")
print("========================================")

-- Step 1: Initialize RemoteEvents first (all services depend on them)
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

-- Step 2: Core data service (all services depend on it)
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

-- Step 3: Security manager
local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

-- Step 4: Core game services
local MergeService = require(ServerScriptService.Services.MergeService)
MergeService.Init()

local GeneratorService = require(ServerScriptService.Services.GeneratorService)
GeneratorService.Init()

local EarningsService = require(ServerScriptService.Services.EarningsService)
EarningsService.Init()

local CollectionService = require(ServerScriptService.Services.CollectionService)
CollectionService.Init()

local PrestigeService = require(ServerScriptService.Services.PrestigeService)
PrestigeService.Init()

local MonetizationService = require(ServerScriptService.Services.MonetizationService)
MonetizationService.Init()

-- Step 5: Late initialization (resolve circular dependencies)
MergeService.LateInit()
CollectionService.LateInit()
PrestigeService.LateInit()
MonetizationService.LateInit()

-- Step 6: Start auto-merge loop for game pass holders
MonetizationService.StartAutoMergeLoop()

-- ============================================================================
-- PATH UNLOCK HANDLING
-- ============================================================================

local function HandlePathUnlock(player, pathName)
	local allowed = SecurityManager.CheckRateLimit(player, "UnlockPath")
	if not allowed then return end

	if type(pathName) ~= "string" or #pathName > 32 then return end

	local data = DataService.GetFullData(player)
	if not data then return end

	-- Check if path exists
	local pathConfig = GameConfig and GameConfig.MergePaths[pathName]
	if not pathConfig then
		-- Load config if not cached
		local GameConfigModule = require(ReplicatedStorage.Shared.Config.GameConfig)
		pathConfig = GameConfigModule.MergePaths[pathName]
	end
	if not pathConfig then return end

	-- Check if already unlocked
	for _, unlockedPath in ipairs(data.UnlockedPaths) do
		if unlockedPath == pathName then return end
	end

	-- Check cost
	if data.Coins < pathConfig.UnlockCost then
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local notif = remoteEvents:FindFirstChild("Notification")
			if notif then
				local GameConfigModule = require(ReplicatedStorage.Shared.Config.GameConfig)
				notif:FireClient(player, {
					Text = "Need " .. GameConfigModule.FormatNumber(pathConfig.UnlockCost) .. " coins!",
					Color = Color3.fromRGB(255, 60, 60),
				})
			end
		end
		return
	end

	-- Purchase path
	DataService.RemoveCoins(player, pathConfig.UnlockCost)
	table.insert(data.UnlockedPaths, pathName)

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local pathUnlocked = remoteEvents:FindFirstChild("PathUnlocked")
		if pathUnlocked then
			pathUnlocked:FireClient(player, {
				Path = pathName,
				Color = pathConfig.Color,
				UnlockedPaths = data.UnlockedPaths,
			})
		end

		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, {
				Text = pathName .. " path unlocked!",
				Color = Color3.fromRGB(50, 200, 80),
			})
		end
	end

	-- Sync grid (may now show new path items)
	MergeService.SyncGrid(player)

	print("[Main]", player.Name, "unlocked path:", pathName)
end

-- Connect path unlock remote
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
remoteEvents:WaitForChild("UnlockPath").OnServerEvent:Connect(HandlePathUnlock)

-- ============================================================================
-- PLAYER CONNECTION
-- ============================================================================

Players.PlayerAdded:Connect(function(player)
	print("[Main] Player joined:", player.Name)

	-- Load player data
	local success = DataService.LoadProfile(player)
	if not success then
		player:Kick("Failed to load data. Please rejoin.")
		return
	end

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = DataService.GetData(player, "Coins") or 0
	coinsValue.Parent = leaderstats

	local prestigeValue = Instance.new("IntValue")
	prestigeValue.Name = "Prestige"
	prestigeValue.Value = DataService.GetData(player, "PrestigeLevel") or 0
	prestigeValue.Parent = leaderstats

	-- Initialize player systems (order matters)
	MergeService.SetupPlayer(player)
	GeneratorService.SetupPlayer(player)
	CollectionService.SetupPlayer(player)
	EarningsService.SetupPlayer(player)

	-- Send initial data
	local data = DataService.GetFullData(player)
	if data then
		local stats = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if stats then
			local playerStats = stats:FindFirstChild("PlayerStats")
			if playerStats then
				playerStats:FireClient(player, {
					Coins = data.Coins,
					PrestigeLevel = data.PrestigeLevel,
					TotalMerges = data.TotalMerges,
					GoldenMerges = data.GoldenMerges,
					UnlockedPaths = data.UnlockedPaths,
					TotalCoinsEarned = data.TotalCoinsEarned,
				})
			end
		end
	end

	print("[Main] Player setup complete:", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	print("[Main] Player left:", player.Name)

	-- Record last online time for offline earnings
	local data = DataService.GetFullData(player)
	if data then
		data.LastOnlineTime = os.time()
		data.OfflineEarningsCollected = false
	end

	-- Cleanup service states
	EarningsService.CleanupPlayer(player)
	GeneratorService.CleanupPlayer(player)
	MergeService.CleanupPlayer(player)

	-- Save and release profile
	DataService.ReleaseProfile(player)
end)

-- ============================================================================
-- GRACEFUL SHUTDOWN
-- ============================================================================

game:BindToClose(function()
	print("[Main] Server shutting down, saving all profiles...")
	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.GetFullData(player)
		if data then
			data.LastOnlineTime = os.time()
			data.OfflineEarningsCollected = false
		end
		DataService.SaveProfile(player)
	end
	task.wait(2)
	print("[Main] All profiles saved.")
end)

-- ============================================================================
-- PLAYER DATA REQUEST (RemoteFunction)
-- ============================================================================

local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
remoteFunctions:WaitForChild("GetPlayerData").OnServerInvoke = function(player)
	local data = DataService.GetFullData(player)
	if not data then return {} end

	local GameConfigModule = require(ReplicatedStorage.Shared.Config.GameConfig)

	return {
		Coins = data.Coins,
		PrestigeLevel = data.PrestigeLevel,
		TotalMerges = data.TotalMerges or 0,
		GoldenMerges = data.GoldenMerges or 0,
		TotalCoinsEarned = data.TotalCoinsEarned or 0,
		TotalItemsSold = data.TotalItemsSold or 0,
		UnlockedPaths = data.UnlockedPaths,
		HighestTiers = data.HighestTiers,
		OwnedGenerators = #(data.OwnedGenerators or {}),
		GamePasses = data.GamePasses or {},
		GridRows = data.GridRows or 6,
		GridCols = data.GridCols or 6,
		CoinsPerSec = EarningsService.GetCoinsPerSec(player),
		ActiveBoosts = data.ActiveBoosts or {},
	}
end

print("========================================")
print("  MERGE MANIA - Server Ready!")
print("  Paths: 4 | Tiers: 20 | Generators: " .. #require(ReplicatedStorage.Shared.Config.GameConfig).Generators)
print("  Collections: " .. (function()
	local count = 0
	for _ in pairs(require(ReplicatedStorage.Shared.Config.GameConfig).Collections) do
		count = count + 1
	end
	return count
end)())
print("========================================")
