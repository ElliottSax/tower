--[[
	StatsService.lua
	Tracks and provides detailed player statistics

	Features:
	- Race statistics (wins, losses, placements)
	- Dimension-specific stats
	- Personal bests tracking
	- Play time tracking
	- Historical data
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatsService = {}

-- ============================================================================
-- STAT DEFINITIONS
-- ============================================================================

StatsService.StatCategories = {
	General = {
		"total_races",
		"total_wins",
		"total_placements_top3",
		"total_play_time",
		"total_xp_earned",
		"current_level",
		"fragments_collected",
		"checkpoints_reached",
		"deaths",
	},
	Racing = {
		"races_gravity",
		"races_tiny",
		"races_void",
		"races_sky",
		"races_marathon",
		"wins_gravity",
		"wins_tiny",
		"wins_void",
		"wins_sky",
		"wins_marathon",
		"best_win_streak",
		"current_win_streak",
	},
	PersonalBests = {
		"pb_gravity",
		"pb_tiny",
		"pb_void",
		"pb_sky",
		"pb_marathon",
		"pb_daily",
	},
	Dimensions = {
		"gravity_flips",
		"scale_changes",
		"void_near_misses",
		"glide_distance",
		"glide_time",
		"updrafts_used",
		"crumbling_platforms_escaped",
	},
	Social = {
		"races_with_friends",
		"spectator_time",
		"players_spectated",
	},
	Daily = {
		"daily_completions",
		"daily_best_placement",
		"daily_current_streak",
		"daily_best_streak",
		"weekly_completions",
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { stats = {}, personalBests = {}, sessionStart = tick() }
StatsService.PlayerStats = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function StatsService.Init()
	print("[StatsService] Initializing...")

	StatsService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		StatsService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		StatsService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		StatsService.OnPlayerJoin(player)
	end

	-- Update play time every minute
	task.spawn(function()
		while true do
			task.wait(60)
			StatsService.UpdatePlayTimes()
		end
	end)

	print("[StatsService] Initialized")
end

function StatsService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Get stats
	if not remoteFolder:FindFirstChild("GetPlayerStats") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetPlayerStats"
		func.Parent = remoteFolder
	end

	-- Get leaderboard stats
	if not remoteFolder:FindFirstChild("GetGlobalStats") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetGlobalStats"
		func.Parent = remoteFolder
	end

	-- Stats updated event
	if not remoteFolder:FindFirstChild("StatsUpdated") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StatsUpdated"
		event.Parent = remoteFolder
	end

	StatsService.Remotes = {
		GetPlayerStats = remoteFolder.GetPlayerStats,
		GetGlobalStats = remoteFolder.GetGlobalStats,
		StatsUpdated = remoteFolder.StatsUpdated,
	}

	StatsService.Remotes.GetPlayerStats.OnServerInvoke = function(player, targetUserId)
		targetUserId = targetUserId or player.UserId
		return StatsService.GetStats(targetUserId)
	end

	StatsService.Remotes.GetGlobalStats.OnServerInvoke = function(player, statName, limit)
		return StatsService.GetGlobalLeaderboard(statName, limit or 10)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function StatsService.OnPlayerJoin(player: Player)
	StatsService.PlayerStats[player.UserId] = {
		stats = StatsService.GetDefaultStats(),
		personalBests = {},
		sessionStart = tick(),
	}

	StatsService.LoadPlayerStats(player)
end

function StatsService.OnPlayerLeave(player: Player)
	-- Update final play time
	local data = StatsService.PlayerStats[player.UserId]
	if data then
		local sessionTime = tick() - data.sessionStart
		data.stats.total_play_time = (data.stats.total_play_time or 0) + sessionTime
	end

	StatsService.SavePlayerStats(player)
	StatsService.PlayerStats[player.UserId] = nil
end

function StatsService.GetDefaultStats(): table
	local stats = {}
	for _, category in pairs(StatsService.StatCategories) do
		for _, statName in ipairs(category) do
			stats[statName] = 0
		end
	end
	return stats
end

function StatsService.LoadPlayerStats(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data then
		local playerData = StatsService.PlayerStats[player.UserId]
		if playerData then
			if data.Stats then
				for key, value in pairs(data.Stats) do
					playerData.stats[key] = value
				end
			end
			if data.PersonalBests then
				playerData.personalBests = data.PersonalBests
			end
		end
	end
end

function StatsService.SavePlayerStats(player: Player)
	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			Stats = playerData.stats,
			PersonalBests = playerData.personalBests,
		})
	end
end

function StatsService.UpdatePlayTimes()
	for userId, data in pairs(StatsService.PlayerStats) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local sessionTime = tick() - data.sessionStart
			-- Don't save yet, just track
		end
	end
end

-- ============================================================================
-- STAT OPERATIONS
-- ============================================================================

function StatsService.IncrementStat(player: Player, statName: string, amount: number?)
	amount = amount or 1

	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return end

	playerData.stats[statName] = (playerData.stats[statName] or 0) + amount

	-- Notify client
	StatsService.Remotes.StatsUpdated:FireClient(player, {
		stat = statName,
		value = playerData.stats[statName],
	})
end

function StatsService.SetStat(player: Player, statName: string, value: any)
	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return end

	playerData.stats[statName] = value

	StatsService.Remotes.StatsUpdated:FireClient(player, {
		stat = statName,
		value = value,
	})
end

function StatsService.GetStat(player: Player, statName: string): any
	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return nil end
	return playerData.stats[statName]
end

-- ============================================================================
-- PERSONAL BESTS
-- ============================================================================

function StatsService.RecordPersonalBest(player: Player, category: string, time: number): boolean
	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return false end

	local pbKey = "pb_" .. string.lower(category)
	local currentPB = playerData.personalBests[pbKey]

	if not currentPB or time < currentPB then
		playerData.personalBests[pbKey] = time
		playerData.stats[pbKey] = time

		-- Notify client of new PB
		StatsService.Remotes.StatsUpdated:FireClient(player, {
			type = "personal_best",
			category = category,
			time = time,
			previousBest = currentPB,
		})

		print(string.format("[StatsService] %s set new PB in %s: %.2fs (was %.2fs)",
			player.Name, category, time, currentPB or 0))

		return true
	end

	return false
end

function StatsService.GetPersonalBest(player: Player, category: string): number?
	local playerData = StatsService.PlayerStats[player.UserId]
	if not playerData then return nil end

	local pbKey = "pb_" .. string.lower(category)
	return playerData.personalBests[pbKey]
end

-- ============================================================================
-- RACE EVENT HANDLERS
-- ============================================================================

function StatsService.OnRaceComplete(player: Player, dimension: string, time: number, placement: number, totalRacers: number)
	-- General stats
	StatsService.IncrementStat(player, "total_races")

	-- Dimension-specific races
	local dimKey = "races_" .. string.lower(dimension)
	StatsService.IncrementStat(player, dimKey)

	-- Wins
	if placement == 1 then
		StatsService.IncrementStat(player, "total_wins")
		StatsService.IncrementStat(player, "wins_" .. string.lower(dimension))

		-- Win streak
		local currentStreak = (StatsService.GetStat(player, "current_win_streak") or 0) + 1
		StatsService.SetStat(player, "current_win_streak", currentStreak)

		local bestStreak = StatsService.GetStat(player, "best_win_streak") or 0
		if currentStreak > bestStreak then
			StatsService.SetStat(player, "best_win_streak", currentStreak)
		end
	else
		StatsService.SetStat(player, "current_win_streak", 0)
	end

	-- Top 3
	if placement <= 3 then
		StatsService.IncrementStat(player, "total_placements_top3")
	end

	-- Personal best
	StatsService.RecordPersonalBest(player, dimension, time)
end

function StatsService.OnMarathonComplete(player: Player, time: number, placement: number)
	StatsService.IncrementStat(player, "races_marathon")

	if placement == 1 then
		StatsService.IncrementStat(player, "wins_marathon")
	end

	StatsService.RecordPersonalBest(player, "marathon", time)
end

function StatsService.OnDailyComplete(player: Player, time: number, placement: number)
	StatsService.IncrementStat(player, "daily_completions")

	-- Best placement
	local bestPlacement = StatsService.GetStat(player, "daily_best_placement") or 999
	if placement < bestPlacement then
		StatsService.SetStat(player, "daily_best_placement", placement)
	end

	-- Daily streak (would need date tracking)
	StatsService.IncrementStat(player, "daily_current_streak")

	local currentStreak = StatsService.GetStat(player, "daily_current_streak") or 0
	local bestStreak = StatsService.GetStat(player, "daily_best_streak") or 0
	if currentStreak > bestStreak then
		StatsService.SetStat(player, "daily_best_streak", currentStreak)
	end

	StatsService.RecordPersonalBest(player, "daily", time)
end

-- ============================================================================
-- API
-- ============================================================================

function StatsService.GetStats(userId: number): table
	local playerData = StatsService.PlayerStats[userId]
	if not playerData then return {} end

	-- Add session time to play time for display
	local sessionTime = tick() - playerData.sessionStart
	local displayStats = {}

	for key, value in pairs(playerData.stats) do
		displayStats[key] = value
	end

	displayStats.total_play_time = (displayStats.total_play_time or 0) + sessionTime
	displayStats.personal_bests = playerData.personalBests

	return displayStats
end

function StatsService.GetGlobalLeaderboard(statName: string, limit: number): table
	-- This would query OrderedDataStore in production
	-- For now, return current session data
	local leaderboard = {}

	for userId, data in pairs(StatsService.PlayerStats) do
		local player = Players:GetPlayerByUserId(userId)
		if player and data.stats[statName] then
			table.insert(leaderboard, {
				userId = userId,
				name = player.Name,
				value = data.stats[statName],
			})
		end
	end

	table.sort(leaderboard, function(a, b)
		return a.value > b.value
	end)

	-- Limit results
	local result = {}
	for i = 1, math.min(limit, #leaderboard) do
		leaderboard[i].rank = i
		table.insert(result, leaderboard[i])
	end

	return result
end

function StatsService.FormatPlayTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

function StatsService.FormatRaceTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%05.2f", mins, secs)
end

return StatsService
