--[[
	EarningsService.lua - Merge Mania
	Passive income calculation, offline earnings, multiplier stacking

	Every item on the grid produces coins per second based on its tier.
	Multipliers stack from: prestige, collections, game passes, boosts, golden items.
	Offline earnings accrue at 50% rate (75% VIP), capped at 4-12 hours.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local EarningsService = {}
EarningsService.DataService = nil
EarningsService.SecurityManager = nil

-- Cached earnings per player (recalculated on grid changes)
local PlayerEarnings = {} -- [UserId] = { CoinsPerSec, LastTickTime, PathBreakdown }

local EARNINGS_TICK_INTERVAL = 1 -- Process earnings every second
local EARNINGS_SYNC_INTERVAL = 5 -- Sync to client every 5 seconds

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function EarningsService.Init()
	print("[EarningsService] Initializing...")

	EarningsService.DataService = require(ServerScriptService.Services.DataService)
	EarningsService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	EarningsService.SetupRemotes()
	EarningsService.StartEarningsLoop()
	EarningsService.StartSyncLoop()

	print("[EarningsService] Initialized")
end

function EarningsService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("CollectOffline").OnServerEvent:Connect(function(player)
		local allowed = EarningsService.SecurityManager.CheckRateLimit(player, "CollectOffline")
		if not allowed then return end

		EarningsService.CollectOfflineEarnings(player)
	end)

	remoteEvents:WaitForChild("GetEarnings").OnServerEvent:Connect(function(player)
		EarningsService.SendEarningsUpdate(player)
	end)
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

function EarningsService.SetupPlayer(player)
	PlayerEarnings[player.UserId] = {
		CoinsPerSec = 0,
		LastTickTime = os.time(),
		PathBreakdown = {},
	}

	-- Calculate initial earnings
	EarningsService.RecalculateEarnings(player)

	-- Check offline earnings
	EarningsService.CheckOfflineEarnings(player)
end

function EarningsService.CleanupPlayer(player)
	-- Record last online time for offline earnings
	local data = EarningsService.DataService.GetFullData(player)
	if data then
		data.LastOnlineTime = os.time()
		data.OfflineEarningsCollected = false
	end

	PlayerEarnings[player.UserId] = nil
end

-- ============================================================================
-- EARNINGS CALCULATION
-- ============================================================================

function EarningsService.RecalculateEarnings(player)
	local data = EarningsService.DataService.GetFullData(player)
	if not data then return end

	local grid = data.Grid
	local pathTotals = { Weapons = 0, Pets = 0, Food = 0, Gems = 0 }

	-- Sum up base CoinPerSec for all items on grid
	for key, item in pairs(grid) do
		local tierData = GameConfig.GetTierData(item.Path, item.Tier)
		if tierData then
			local baseCps = tierData.CoinPerSec

			-- Golden items earn 5x
			if item.IsGolden then
				baseCps = baseCps * GameConfig.LuckyMerge.GoldenCoinPerSecMultiplier
			end

			pathTotals[item.Path] = (pathTotals[item.Path] or 0) + baseCps
		end
	end

	-- Apply per-path collection multipliers
	local pathMultipliers = EarningsService.GetPathMultipliers(data)

	local totalCps = 0
	local breakdown = {}
	for path, baseCps in pairs(pathTotals) do
		local multiplier = pathMultipliers[path] or 1
		local finalCps = baseCps * multiplier
		breakdown[path] = {
			BaseCps = baseCps,
			Multiplier = multiplier,
			FinalCps = finalCps,
		}
		totalCps = totalCps + finalCps
	end

	-- Apply global multipliers
	local globalMultiplier = EarningsService.GetGlobalMultiplier(data)
	totalCps = totalCps * globalMultiplier

	-- Store cached value
	PlayerEarnings[player.UserId] = {
		CoinsPerSec = totalCps,
		LastTickTime = os.time(),
		PathBreakdown = breakdown,
		GlobalMultiplier = globalMultiplier,
	}
end

function EarningsService.GetPathMultipliers(data)
	local multipliers = { Weapons = 1, Pets = 1, Food = 1, Gems = 1 }

	if not data.Collections then return multipliers end

	for collName, collData in pairs(data.Collections) do
		if collData.Completed then
			local collConfig = GameConfig.Collections[collName]
			if collConfig then
				if collConfig.Path == "ALL" then
					-- Cross-path bonus applies to all
					for path in pairs(multipliers) do
						multipliers[path] = multipliers[path] * collConfig.Multiplier
					end
				elseif multipliers[collConfig.Path] then
					multipliers[collConfig.Path] = multipliers[collConfig.Path] * collConfig.Multiplier
				end
			end
		end
	end

	return multipliers
end

function EarningsService.GetGlobalMultiplier(data)
	local multiplier = 1.0

	-- Prestige multiplier
	local prestigeLevel = data.PrestigeLevel or 0
	multiplier = multiplier + (prestigeLevel * GameConfig.Prestige.Multiplier)

	-- Double earnings pass
	if data.GamePasses and data.GamePasses["DoubleEarnings"] then
		multiplier = multiplier * 2
	end

	-- VIP pass
	if data.GamePasses and data.GamePasses["VIP"] then
		multiplier = multiplier * 1.5
	end

	-- Prestige milestone rewards
	if prestigeLevel >= 40 then
		multiplier = multiplier * 2 -- Cosmic Power
	end
	if prestigeLevel >= 50 then
		multiplier = multiplier * 3 -- Universe Master
	end

	-- Pets path passive boost (from completed collections)
	if data.Collections then
		for collName, collData in pairs(data.Collections) do
			if collData.Completed then
				local collConfig = GameConfig.Collections[collName]
				if collConfig and collConfig.Path == "Pets" then
					multiplier = multiplier * (1 + GameConfig.MergePaths.Pets.BonusAmount)
				end
			end
		end
	end

	return multiplier
end

-- ============================================================================
-- EARNINGS LOOP (processes coins every second)
-- ============================================================================

function EarningsService.StartEarningsLoop()
	task.spawn(function()
		while true do
			task.wait(EARNINGS_TICK_INTERVAL)
			EarningsService.TickEarnings()
		end
	end)
end

function EarningsService.TickEarnings()
	local now = os.time()

	for _, player in ipairs(Players:GetPlayers()) do
		local earnings = PlayerEarnings[player.UserId]
		if not earnings or earnings.CoinsPerSec <= 0 then continue end

		local data = EarningsService.DataService.GetFullData(player)
		if not data then continue end

		local elapsed = now - earnings.LastTickTime
		if elapsed < 1 then continue end

		local coinsToAdd = earnings.CoinsPerSec * elapsed
		if coinsToAdd > 0 then
			EarningsService.DataService.AddCoins(player, math.floor(coinsToAdd))
		end

		earnings.LastTickTime = now
	end
end

-- ============================================================================
-- SYNC LOOP (sends earnings data to clients periodically)
-- ============================================================================

function EarningsService.StartSyncLoop()
	task.spawn(function()
		while true do
			task.wait(EARNINGS_SYNC_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				EarningsService.SendEarningsUpdate(player)
			end
		end
	end)
end

function EarningsService.SendEarningsUpdate(player)
	local earnings = PlayerEarnings[player.UserId]
	if not earnings then return end

	local data = EarningsService.DataService.GetFullData(player)
	if not data then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local earningsUpdate = remoteEvents:FindFirstChild("EarningsUpdate")
		if earningsUpdate then
			earningsUpdate:FireClient(player, {
				CoinsPerSec = earnings.CoinsPerSec,
				CurrentCoins = data.Coins,
				TotalEarned = data.TotalCoinsEarned,
				PathBreakdown = earnings.PathBreakdown,
				GlobalMultiplier = earnings.GlobalMultiplier,
				PrestigeLevel = data.PrestigeLevel,
				ActiveBoosts = data.ActiveBoosts,
			})
		end
	end
end

-- ============================================================================
-- OFFLINE EARNINGS
-- ============================================================================

function EarningsService.CheckOfflineEarnings(player)
	local data = EarningsService.DataService.GetFullData(player)
	if not data then return end

	-- Skip if first join or already collected
	if data.LastOnlineTime == 0 then
		data.LastOnlineTime = os.time()
		data.OfflineEarningsCollected = true
		return
	end

	if data.OfflineEarningsCollected then return end

	local now = os.time()
	local offlineSeconds = now - data.LastOnlineTime

	-- Minimum 60 seconds offline
	if offlineSeconds < 60 then
		data.OfflineEarningsCollected = true
		return
	end

	-- Cap offline time
	local maxOfflineSeconds = GameConfig.GetOfflineCap(data.PrestigeLevel or 0)
	offlineSeconds = math.min(offlineSeconds, maxOfflineSeconds)

	-- Calculate offline earnings
	local earnings = PlayerEarnings[player.UserId]
	local cps = earnings and earnings.CoinsPerSec or 0

	if cps <= 0 then
		data.OfflineEarningsCollected = true
		return
	end

	-- Apply offline efficiency
	local efficiency = GameConfig.OfflineEarnings.OfflineEfficiency
	if data.GamePasses and data.GamePasses["VIP"] then
		efficiency = GameConfig.OfflineEarnings.VIPEfficiency
	end

	local offlineCoins = math.floor(cps * offlineSeconds * efficiency)

	if offlineCoins > 0 then
		-- Send offline earnings info to client (don't auto-collect)
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local offlineEvent = remoteEvents:FindFirstChild("OfflineEarnings")
			if offlineEvent then
				local hours = math.floor(offlineSeconds / 3600)
				local minutes = math.floor((offlineSeconds % 3600) / 60)

				offlineEvent:FireClient(player, {
					Coins = offlineCoins,
					TimeAway = offlineSeconds,
					TimeString = hours .. "h " .. minutes .. "m",
					Efficiency = efficiency,
				})
			end
		end

		-- Store pending offline earnings
		data._PendingOfflineCoins = offlineCoins
	else
		data.OfflineEarningsCollected = true
	end
end

function EarningsService.CollectOfflineEarnings(player)
	local data = EarningsService.DataService.GetFullData(player)
	if not data then return end

	local pending = data._PendingOfflineCoins
	if not pending or pending <= 0 then return end

	EarningsService.DataService.AddCoins(player, pending)
	data._PendingOfflineCoins = nil
	data.OfflineEarningsCollected = true

	-- Notify
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, {
				Text = "Collected " .. GameConfig.FormatNumber(pending) .. " offline coins!",
				Color = GameConfig.Theme.SuccessColor,
			})
		end
	end
end

-- ============================================================================
-- PUBLIC HELPERS
-- ============================================================================

function EarningsService.GetCoinsPerSec(player)
	local earnings = PlayerEarnings[player.UserId]
	if not earnings then return 0 end
	return earnings.CoinsPerSec
end

return EarningsService
