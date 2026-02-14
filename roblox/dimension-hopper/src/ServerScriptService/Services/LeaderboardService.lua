--[[
	LeaderboardService.lua
	Global leaderboard system for Dimension Hopper

	Features:
	- Multiple leaderboard categories
	- Best times per dimension
	- Total XP rankings
	- Race wins tracking
	- Weekly/All-time boards
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local LeaderboardService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local LEADERBOARD_CATEGORIES = {
	"TotalXP",
	"RaceWins",
	"GravityBestTime",
	"TinyBestTime",
	"VoidBestTime",
	"SkyBestTime",
	"MarathonBestTime",
	"SectionsCompleted",
	"LoginStreak",
}

local CACHE_DURATION = 60 -- Seconds to cache leaderboard data
local ENTRIES_PER_PAGE = 100

-- ============================================================================
-- STATE
-- ============================================================================

LeaderboardService.DataStores = {}
LeaderboardService.CachedLeaderboards = {} -- [category] = { data, lastUpdate }
LeaderboardService.PlayerRanks = {} -- [UserId][category] = rank

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function LeaderboardService.Init()
	print("[LeaderboardService] Initializing...")

	-- Create DataStores for each category
	for _, category in ipairs(LEADERBOARD_CATEGORIES) do
		local success, store = pcall(function()
			return DataStoreService:GetOrderedDataStore("Leaderboard_" .. category)
		end)

		if success then
			LeaderboardService.DataStores[category] = store
		else
			warn(string.format("[LeaderboardService] Failed to create DataStore for %s", category))
		end
	end

	-- Create remotes
	LeaderboardService.CreateRemotes()

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		LeaderboardService.OnPlayerJoin(player)
	end)

	-- Start periodic updates
	LeaderboardService.StartPeriodicUpdates()

	print("[LeaderboardService] Initialized")
end

function LeaderboardService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not remoteFunctions then
		remoteFunctions = Instance.new("Folder")
		remoteFunctions.Name = "RemoteFunctions"
		remoteFunctions.Parent = ReplicatedStorage
	end

	-- Get leaderboard data
	if not remoteFunctions:FindFirstChild("GetLeaderboard") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetLeaderboard"
		func.Parent = remoteFunctions

		func.OnServerInvoke = function(player, category, page)
			return LeaderboardService.GetLeaderboard(category, page)
		end
	end

	-- Get player rank
	if not remoteFunctions:FindFirstChild("GetPlayerRank") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetPlayerRank"
		func.Parent = remoteFunctions

		func.OnServerInvoke = function(player, category)
			return LeaderboardService.GetPlayerRank(player, category)
		end
	end

	-- Leaderboard update notification
	if not remoteFolder:FindFirstChild("LeaderboardUpdate") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LeaderboardUpdate"
		event.Parent = remoteFolder
	end

	LeaderboardService.Remotes = {
		LeaderboardUpdate = remoteFolder.LeaderboardUpdate,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function LeaderboardService.OnPlayerJoin(player: Player)
	LeaderboardService.PlayerRanks[player.UserId] = {}

	-- Fetch player's ranks in all categories
	task.spawn(function()
		for _, category in ipairs(LEADERBOARD_CATEGORIES) do
			LeaderboardService.UpdatePlayerRank(player, category)
		end
	end)
end

-- ============================================================================
-- SCORE SUBMISSION
-- ============================================================================

function LeaderboardService.SubmitScore(player: Player, category: string, score: number, isTime: boolean?)
	local store = LeaderboardService.DataStores[category]
	if not store then return false end

	-- For time-based leaderboards, we want lower = better
	-- OrderedDataStore sorts descending by default, so we invert times
	local storeValue = score
	if isTime then
		-- Store as negative for ascending sort, multiply by 1000 for precision
		storeValue = -math.floor(score * 1000)
	end

	local success, err = pcall(function()
		store:SetAsync(tostring(player.UserId), storeValue)
	end)

	if success then
		-- Invalidate cache
		LeaderboardService.CachedLeaderboards[category] = nil

		-- Update player's rank
		LeaderboardService.UpdatePlayerRank(player, category)

		print(string.format("[LeaderboardService] %s submitted score %d to %s",
			player.Name, score, category))
		return true
	else
		warn(string.format("[LeaderboardService] Failed to submit score: %s", tostring(err)))
		return false
	end
end

function LeaderboardService.SubmitBestTime(player: Player, dimension: string, time: number)
	local category = dimension .. "BestTime"

	-- Check if this is actually a new best
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if DataService then
		local isNewBest = DataService.SetBestTime(player, dimension, time)
		if isNewBest then
			LeaderboardService.SubmitScore(player, category, time, true)
			return true
		end
	end

	return false
end

function LeaderboardService.UpdateTotalXP(player: Player, totalXP: number)
	LeaderboardService.SubmitScore(player, "TotalXP", totalXP, false)
end

function LeaderboardService.UpdateRaceWins(player: Player, wins: number)
	LeaderboardService.SubmitScore(player, "RaceWins", wins, false)
end

function LeaderboardService.UpdateSectionsCompleted(player: Player, sections: number)
	LeaderboardService.SubmitScore(player, "SectionsCompleted", sections, false)
end

function LeaderboardService.UpdateLoginStreak(player: Player, streak: number)
	LeaderboardService.SubmitScore(player, "LoginStreak", streak, false)
end

-- ============================================================================
-- LEADERBOARD RETRIEVAL
-- ============================================================================

function LeaderboardService.GetLeaderboard(category: string, page: number?): table?
	page = page or 1

	-- Check cache
	local cached = LeaderboardService.CachedLeaderboards[category]
	if cached and (tick() - cached.lastUpdate) < CACHE_DURATION then
		return LeaderboardService.PaginateData(cached.data, page)
	end

	-- Fetch from DataStore
	local store = LeaderboardService.DataStores[category]
	if not store then return nil end

	local success, pages = pcall(function()
		return store:GetSortedAsync(false, ENTRIES_PER_PAGE * 5) -- Get top 500
	end)

	if not success then
		warn(string.format("[LeaderboardService] Failed to fetch %s leaderboard", category))
		return nil
	end

	-- Process entries
	local entries = {}
	local isTimeBased = string.find(category, "BestTime") ~= nil

	local pageData = pages:GetCurrentPage()
	local rank = 1

	for _, entry in ipairs(pageData) do
		local userId = tonumber(entry.key)
		local score = entry.value

		-- Convert time values back
		if isTimeBased then
			score = -score / 1000 -- Convert back to positive seconds
		end

		-- Get player name
		local playerName = "Unknown"
		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if success then
			playerName = name
		end

		table.insert(entries, {
			Rank = rank,
			UserId = userId,
			Name = playerName,
			Score = score,
		})

		rank = rank + 1
	end

	-- Cache results
	LeaderboardService.CachedLeaderboards[category] = {
		data = entries,
		lastUpdate = tick(),
	}

	return LeaderboardService.PaginateData(entries, page)
end

function LeaderboardService.PaginateData(data: table, page: number): table
	local startIndex = (page - 1) * 10 + 1
	local endIndex = math.min(startIndex + 9, #data)

	local pageData = {}
	for i = startIndex, endIndex do
		table.insert(pageData, data[i])
	end

	return {
		Entries = pageData,
		Page = page,
		TotalPages = math.ceil(#data / 10),
		TotalEntries = #data,
	}
end

-- ============================================================================
-- PLAYER RANK
-- ============================================================================

function LeaderboardService.GetPlayerRank(player: Player, category: string): table?
	local store = LeaderboardService.DataStores[category]
	if not store then return nil end

	-- Get player's score
	local success, score = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)

	if not success or not score then
		return { Rank = nil, Score = nil }
	end

	-- Get rank
	local rankSuccess, rank = pcall(function()
		return store:GetRankAsync(tostring(player.UserId))
	end)

	local isTimeBased = string.find(category, "BestTime") ~= nil
	local displayScore = score
	if isTimeBased then
		displayScore = -score / 1000
	end

	return {
		Rank = rankSuccess and rank or nil,
		Score = displayScore,
	}
end

function LeaderboardService.UpdatePlayerRank(player: Player, category: string)
	local rankData = LeaderboardService.GetPlayerRank(player, category)

	if LeaderboardService.PlayerRanks[player.UserId] then
		LeaderboardService.PlayerRanks[player.UserId][category] = rankData
	end
end

-- ============================================================================
-- PERIODIC UPDATES
-- ============================================================================

function LeaderboardService.StartPeriodicUpdates()
	-- Update player stats periodically
	task.spawn(function()
		while true do
			task.wait(300) -- Every 5 minutes

			for _, player in ipairs(Players:GetPlayers()) do
				LeaderboardService.SyncPlayerStats(player)
			end
		end
	end)
end

function LeaderboardService.SyncPlayerStats(player: Player)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local data = DataService.GetData(player)
	if not data then return end

	-- Update all stats
	if data.TotalXP then
		LeaderboardService.SubmitScore(player, "TotalXP", data.TotalXP, false)
	end

	if data.Stats then
		if data.Stats.RacesWon then
			LeaderboardService.SubmitScore(player, "RaceWins", data.Stats.RacesWon, false)
		end

		if data.Stats.SectionsCompleted then
			LeaderboardService.SubmitScore(player, "SectionsCompleted", data.Stats.SectionsCompleted, false)
		end

		-- Best times
		if data.Stats.BestTimes then
			for dimension, time in pairs(data.Stats.BestTimes) do
				if time then
					LeaderboardService.SubmitScore(player, dimension .. "BestTime", time, true)
				end
			end
		end
	end

	if data.Daily and data.Daily.LoginStreak then
		LeaderboardService.SubmitScore(player, "LoginStreak", data.Daily.LoginStreak, false)
	end
end

-- ============================================================================
-- FORMATTING
-- ============================================================================

function LeaderboardService.FormatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%05.2f", minutes, secs)
end

function LeaderboardService.FormatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function LeaderboardService.DebugPrintLeaderboard(category: string)
	local data = LeaderboardService.GetLeaderboard(category, 1)
	if not data then
		print("[LeaderboardService] No data for " .. category)
		return
	end

	print("=== LEADERBOARD: " .. category .. " ===")
	for _, entry in ipairs(data.Entries) do
		print(string.format("  #%d %s: %s",
			entry.Rank, entry.Name, tostring(entry.Score)))
	end
	print("=====================================")
end

return LeaderboardService
