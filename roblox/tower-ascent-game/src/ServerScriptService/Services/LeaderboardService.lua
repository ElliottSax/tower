--[[
	LeaderboardService.lua
	Manages global leaderboards using OrderedDataStores

	Features:
	- Top 100 players tracked
	- Multiple leaderboard types:
	  * HighestStage - Best stage reached
	  * TowersCompleted - Most towers finished
	  * TotalCoins - Total coins earned (all-time)
	- Updates every 60 seconds
	- Caches results for performance
	- RemoteFunction for client queries
	- Handles rate limits gracefully

	How it works:
	1. When player data changes, update OrderedDataStore
	2. Every 60s, fetch top 100 from each leaderboard
	3. Cache results in memory
	4. Clients query cached data (no DataStore calls)

	OrderedDataStore structure:
	- Key: "Player_" .. UserId
	- Value: Stat value (number)
	- Sorted automatically by value (descending)

	Week 3: Full implementation
	Week 4+: Add daily/weekly leaderboards, friends leaderboard
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

local LeaderboardService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local UPDATE_INTERVAL = 60 -- Update leaderboards every 60 seconds
local TOP_PLAYER_COUNT = 100 -- Top 100 players
local RETRY_DELAY = 5 -- Retry after 5 seconds if DataStore fails

-- ============================================================================
-- ORDERED DATASTORES
-- ============================================================================

local OrderedDataStores = {}

-- Initialize OrderedDataStores (with pcall for Studio testing)
local success, err = pcall(function()
	OrderedDataStores.HighestStage = DataStoreService:GetOrderedDataStore("Leaderboard_HighestStage")
	OrderedDataStores.TowersCompleted = DataStoreService:GetOrderedDataStore("Leaderboard_TowersCompleted")
	OrderedDataStores.TotalCoins = DataStoreService:GetOrderedDataStore("Leaderboard_TotalCoins")
end)

if not success then
	warn("[LeaderboardService] Failed to get OrderedDataStores:", err)
	warn("[LeaderboardService] Leaderboards will not function (Studio mode?)")
end

-- ============================================================================
-- CACHE
-- ============================================================================

LeaderboardService.Cache = {
	HighestStage = {},
	TowersCompleted = {},
	TotalCoins = {},
}

LeaderboardService.LastUpdate = {
	HighestStage = 0,
	TowersCompleted = 0,
	TotalCoins = 0,
}

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

LeaderboardService.RemoteEvents = {}

local function setupRemoteEvents()
	-- Use centralized RemoteEventsInit (single source of truth for all remotes)
	LeaderboardService.RemoteEvents.GetLeaderboard = RemoteEventsInit.GetRemote("GetLeaderboard")

	-- Setup callback using SecureRemotes API
	local getLeaderboardRemote = LeaderboardService.RemoteEvents.GetLeaderboard
	if getLeaderboardRemote and getLeaderboardRemote.OnServerInvoke then
		getLeaderboardRemote:OnServerInvoke(function(player, leaderboardType)
			return LeaderboardService.GetLeaderboard(leaderboardType)
		end)
	end

	print("[LeaderboardService] RemoteEvents setup complete (using RemoteEventsInit)")
end

-- ============================================================================
-- UPDATE PLAYER STAT
-- ============================================================================

function LeaderboardService.UpdatePlayerStat(userId: number, leaderboardType: string, value: number)
	if not OrderedDataStores[leaderboardType] then
		warn("[LeaderboardService] Invalid leaderboard type:", leaderboardType)
		return false
	end

	-- Update OrderedDataStore (async)
	task.spawn(function()
		local success, err = pcall(function()
			local key = "Player_" .. tostring(userId)
			OrderedDataStores[leaderboardType]:SetAsync(key, value)
		end)

		if not success then
			warn(string.format(
				"[LeaderboardService] Failed to update %s for user %d: %s",
				leaderboardType,
				userId,
				tostring(err)
			))
		end
	end)

	return true
end

-- ============================================================================
-- FETCH LEADERBOARD
-- ============================================================================

function LeaderboardService.FetchLeaderboard(leaderboardType: string)
	if not OrderedDataStores[leaderboardType] then
		warn("[LeaderboardService] Invalid leaderboard type:", leaderboardType)
		return {}
	end

	local leaderboard = {}

	local success, err = pcall(function()
		-- Get top players (descending order)
		local pages = OrderedDataStores[leaderboardType]:GetSortedAsync(
			false, -- Descending (highest first)
			TOP_PLAYER_COUNT
		)

		local currentPage = pages:GetCurrentPage()

		-- Key format is "Player_UserId" - extract UserId efficiently
		-- "Player_" is 7 characters, so UserId starts at position 8
		local PLAYER_PREFIX_LEN = 7

		for rank, entry in ipairs(currentPage) do
			-- entry.key = "Player_UserId"
			-- entry.value = stat value

			-- Efficient extraction: skip regex, use substring
			local userId = tonumber(string.sub(entry.key, PLAYER_PREFIX_LEN + 1))

			if userId then
				-- Get player name (if online) or use UserId
				local player = Players:GetPlayerByUserId(userId)
				local playerName = player and player.Name or ("Player " .. userId)

				table.insert(leaderboard, {
					Rank = rank,
					UserId = userId,
					PlayerName = playerName,
					Value = entry.value,
				})
			end
		end
	end)

	if not success then
		warn(string.format(
			"[LeaderboardService] Failed to fetch %s leaderboard: %s",
			leaderboardType,
			tostring(err)
		))
		return {}
	end

	return leaderboard
end

-- ============================================================================
-- UPDATE ALL LEADERBOARDS
-- ============================================================================

function LeaderboardService.UpdateAllLeaderboards()
	print("[LeaderboardService] Updating all leaderboards...")

	for leaderboardType, _ in pairs(OrderedDataStores) do
		local leaderboard = LeaderboardService.FetchLeaderboard(leaderboardType)

		if #leaderboard > 0 then
			LeaderboardService.Cache[leaderboardType] = leaderboard
			LeaderboardService.LastUpdate[leaderboardType] = tick()

			print(string.format(
				"[LeaderboardService] Updated %s (%d entries)",
				leaderboardType,
				#leaderboard
			))
		end
	end

	print("[LeaderboardService] Leaderboard update complete")
end

-- ============================================================================
-- GET LEADERBOARD (CACHED)
-- ============================================================================

function LeaderboardService.GetLeaderboard(leaderboardType: string): {}
	if not LeaderboardService.Cache[leaderboardType] then
		warn("[LeaderboardService] Invalid leaderboard type:", leaderboardType)
		return {}
	end

	return LeaderboardService.Cache[leaderboardType]
end

-- ============================================================================
-- GET PLAYER RANK
-- ============================================================================

function LeaderboardService.GetPlayerRank(userId: number, leaderboardType: string): number?
	local leaderboard = LeaderboardService.GetLeaderboard(leaderboardType)

	for _, entry in ipairs(leaderboard) do
		if entry.UserId == userId then
			return entry.Rank
		end
	end

	return nil -- Not in top 100
end

-- ============================================================================
-- PLAYER DATA SYNC
-- ============================================================================

-- Maximum reasonable values for each leaderboard type (anti-exploit)
local MAX_LEADERBOARD_VALUES = {
	HighestStage = 1000,      -- No tower should have more than 1000 stages
	TowersCompleted = 100000, -- Reasonable lifetime limit
	TotalCoins = 999999999,   -- Match GameConfig max
}

function LeaderboardService.OnPlayerDataChanged(player: Player, dataType: string, value: number)
	-- Update leaderboard when player data changes
	local leaderboardType = nil

	if dataType == "HighestStage" then
		leaderboardType = "HighestStage"
	elseif dataType == "TowersCompleted" then
		leaderboardType = "TowersCompleted"
	elseif dataType == "TotalCoinsEarned" then
		leaderboardType = "TotalCoins"
	end

	if leaderboardType then
		-- Validate value is reasonable (anti-exploit)
		if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
			warn(string.format(
				"[LeaderboardService] Invalid value for %s from %s: %s",
				leaderboardType,
				player.Name,
				tostring(value)
			))
			return
		end

		-- Enforce maximum values
		local maxValue = MAX_LEADERBOARD_VALUES[leaderboardType]
		if maxValue and value > maxValue then
			warn(string.format(
				"[LeaderboardService] Value exceeds max for %s from %s: %d > %d",
				leaderboardType,
				player.Name,
				value,
				maxValue
			))
			value = maxValue
		end

		LeaderboardService.UpdatePlayerStat(player.UserId, leaderboardType, value)
	end
end

-- ============================================================================
-- PERIODIC UPDATE LOOP
-- ============================================================================

function LeaderboardService.StartUpdateLoop()
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)

			-- Update all leaderboards
			local success, err = pcall(function()
				LeaderboardService.UpdateAllLeaderboards()
			end)

			if not success then
				warn("[LeaderboardService] Update loop error:", err)
				task.wait(RETRY_DELAY)
			end
		end
	end)

	print("[LeaderboardService] Update loop started (interval: " .. UPDATE_INTERVAL .. "s)")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function LeaderboardService.OnPlayerAdded(player: Player)
	-- Sync current player data to leaderboards
	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	if profile and profile.Data then
		local data = profile.Data

		-- Update all leaderboard stats
		LeaderboardService.UpdatePlayerStat(player.UserId, "HighestStage", data.Stats.HighestStage)
		LeaderboardService.UpdatePlayerStat(player.UserId, "TowersCompleted", data.Stats.TowersCompleted)
		LeaderboardService.UpdatePlayerStat(player.UserId, "TotalCoins", data.Stats.TotalCoinsEarned or data.Coins)

		print(string.format(
			"[LeaderboardService] Synced %s to leaderboards",
			player.Name
		))
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function LeaderboardService.Init()
	print("[LeaderboardService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Do initial leaderboard fetch
	task.spawn(function()
		task.wait(5) -- Wait for server to fully start
		LeaderboardService.UpdateAllLeaderboards()
	end)

	-- Start periodic update loop
	LeaderboardService.StartUpdateLoop()

	-- Listen for player joins (sync their data)
	Players.PlayerAdded:Connect(function(player)
		-- Wait for DataService to load profile
		task.wait(2)
		LeaderboardService.OnPlayerAdded(player)
	end)

	-- Sync existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(2)
			LeaderboardService.OnPlayerAdded(player)
		end)
	end

	print("[LeaderboardService] Initialized")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return LeaderboardService
