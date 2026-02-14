--[[
	DailyChallengeService.lua
	Manages daily and weekly challenge levels

	Features:
	- Daily rotating challenge with consistent seed
	- Weekly marathon challenge
	- Leaderboards for each challenge
	- Bonus rewards for daily participation
	- Streak tracking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DailyChallengeService = {}

-- ============================================================================
-- STATE
-- ============================================================================

DailyChallengeService.CurrentDaily = nil
DailyChallengeService.CurrentWeekly = nil
DailyChallengeService.DailyLeaderboard = {} -- [UserId] = { time, name, date }
DailyChallengeService.WeeklyLeaderboard = {} -- [UserId] = { time, name, week }

-- Challenge rotation (each day of week focuses on different dimension)
DailyChallengeService.DimensionRotation = {
	"Gravity", -- Sunday
	"Tiny",    -- Monday
	"Void",    -- Tuesday
	"Sky",     -- Wednesday
	"Gravity", -- Thursday
	"Tiny",    -- Friday
	"Void",    -- Saturday
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DailyChallengeService.Init()
	print("[DailyChallengeService] Initializing...")

	DailyChallengeService.CreateRemotes()
	DailyChallengeService.GenerateCurrentChallenges()

	-- Check for daily reset periodically
	task.spawn(function()
		while true do
			task.wait(60) -- Check every minute
			DailyChallengeService.CheckDailyReset()
		end
	end)

	-- Player connections
	Players.PlayerAdded:Connect(function(player)
		DailyChallengeService.OnPlayerJoin(player)
	end)

	print("[DailyChallengeService] Initialized")
end

function DailyChallengeService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Get daily info
	if not remoteFolder:FindFirstChild("GetDailyChallenge") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetDailyChallenge"
		func.Parent = remoteFolder
	end

	-- Start daily challenge
	if not remoteFolder:FindFirstChild("StartDailyChallenge") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StartDailyChallenge"
		event.Parent = remoteFolder
	end

	-- Submit daily time
	if not remoteFolder:FindFirstChild("SubmitDailyTime") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SubmitDailyTime"
		event.Parent = remoteFolder
	end

	-- Get leaderboard
	if not remoteFolder:FindFirstChild("GetDailyLeaderboard") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetDailyLeaderboard"
		func.Parent = remoteFolder
	end

	-- Daily challenge sync
	if not remoteFolder:FindFirstChild("DailyChallengeSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "DailyChallengeSync"
		event.Parent = remoteFolder
	end

	DailyChallengeService.Remotes = {
		GetDailyChallenge = remoteFolder.GetDailyChallenge,
		StartDailyChallenge = remoteFolder.StartDailyChallenge,
		SubmitDailyTime = remoteFolder.SubmitDailyTime,
		GetDailyLeaderboard = remoteFolder.GetDailyLeaderboard,
		DailyChallengeSync = remoteFolder.DailyChallengeSync,
	}

	-- Connect handlers
	DailyChallengeService.Remotes.GetDailyChallenge.OnServerInvoke = function(player)
		return DailyChallengeService.GetChallengeInfo()
	end

	DailyChallengeService.Remotes.StartDailyChallenge.OnServerEvent:Connect(function(player)
		DailyChallengeService.StartChallenge(player, "daily")
	end)

	DailyChallengeService.Remotes.SubmitDailyTime.OnServerEvent:Connect(function(player, time)
		DailyChallengeService.SubmitTime(player, time, "daily")
	end)

	DailyChallengeService.Remotes.GetDailyLeaderboard.OnServerInvoke = function(player)
		return DailyChallengeService.GetLeaderboard("daily")
	end
end

-- ============================================================================
-- CHALLENGE GENERATION
-- ============================================================================

function DailyChallengeService.GenerateCurrentChallenges()
	local date = os.date("*t")

	-- Daily challenge seed
	local dailySeed = date.year * 10000 + date.month * 100 + date.day
	local dayOfWeek = date.wday -- 1 = Sunday
	local dimension = DailyChallengeService.DimensionRotation[dayOfWeek]

	DailyChallengeService.CurrentDaily = {
		seed = dailySeed,
		dimension = dimension,
		date = string.format("%04d-%02d-%02d", date.year, date.month, date.day),
		sectionCount = 15, -- Fixed section count for fairness
		difficulty = "normal",
		bonusXP = 100,
		streakBonus = 50, -- Additional XP per day of streak
	}

	-- Weekly challenge (marathon mode)
	local weekNumber = math.floor((date.yday - 1) / 7) + 1
	local weeklySeed = date.year * 100 + weekNumber

	DailyChallengeService.CurrentWeekly = {
		seed = weeklySeed,
		mode = "marathon",
		week = weekNumber,
		dimensions = {"Gravity", "Tiny", "Void", "Sky"},
		bonusXP = 500,
	}

	print(string.format("[DailyChallengeService] Daily: %s (seed: %d), Weekly: Week %d",
		dimension, dailySeed, weekNumber))
end

function DailyChallengeService.CheckDailyReset()
	local date = os.date("*t")
	local currentDate = string.format("%04d-%02d-%02d", date.year, date.month, date.day)

	if DailyChallengeService.CurrentDaily.date ~= currentDate then
		print("[DailyChallengeService] New day detected - resetting daily challenge")

		-- Clear daily leaderboard
		DailyChallengeService.DailyLeaderboard = {}

		-- Generate new challenges
		DailyChallengeService.GenerateCurrentChallenges()

		-- Notify all players
		for _, player in ipairs(Players:GetPlayers()) do
			DailyChallengeService.Remotes.DailyChallengeSync:FireClient(player, {
				type = "reset",
				daily = DailyChallengeService.GetChallengeInfo(),
			})
		end
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function DailyChallengeService.OnPlayerJoin(player: Player)
	-- Send current challenge info
	task.wait(2) -- Wait for client to load

	DailyChallengeService.Remotes.DailyChallengeSync:FireClient(player, {
		type = "init",
		daily = DailyChallengeService.GetChallengeInfo(),
	})
end

-- ============================================================================
-- CHALLENGE API
-- ============================================================================

function DailyChallengeService.GetChallengeInfo()
	local daily = DailyChallengeService.CurrentDaily
	local weekly = DailyChallengeService.CurrentWeekly

	-- Calculate time until reset
	local now = os.time()
	local tomorrow = os.time({
		year = os.date("%Y"),
		month = os.date("%m"),
		day = os.date("%d") + 1,
		hour = 0,
		min = 0,
		sec = 0,
	})
	local timeUntilReset = tomorrow - now

	return {
		daily = {
			dimension = daily.dimension,
			date = daily.date,
			bonusXP = daily.bonusXP,
			sectionCount = daily.sectionCount,
			timeUntilReset = timeUntilReset,
		},
		weekly = {
			mode = weekly.mode,
			week = weekly.week,
			bonusXP = weekly.bonusXP,
		},
	}
end

function DailyChallengeService.StartChallenge(player: Player, challengeType: string)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DimensionService = DimensionHopper.GetService("DimensionService")
	if not DimensionService then return end

	if challengeType == "daily" then
		local daily = DailyChallengeService.CurrentDaily

		-- Set seed for consistent generation
		DimensionService.SetLevelSeed(daily.seed)

		-- Load dimension
		DimensionService.LoadDimension(daily.dimension)

		-- Mark player as in daily challenge
		player:SetAttribute("InDailyChallenge", true)
		player:SetAttribute("DailyChallengeStart", tick())

		print(string.format("[DailyChallengeService] %s started daily challenge (%s)",
			player.Name, daily.dimension))
	elseif challengeType == "weekly" then
		-- Start marathon mode with weekly seed
		local weekly = DailyChallengeService.CurrentWeekly
		DimensionService.SetLevelSeed(weekly.seed)

		-- Start first dimension
		DimensionService.LoadDimension("Gravity")

		player:SetAttribute("InWeeklyChallenge", true)
		player:SetAttribute("WeeklyChallengeStart", tick())

		print(string.format("[DailyChallengeService] %s started weekly marathon challenge",
			player.Name))
	end
end

function DailyChallengeService.SubmitTime(player: Player, finishTime: number, challengeType: string)
	if challengeType == "daily" then
		if not player:GetAttribute("InDailyChallenge") then
			return -- Not in a daily challenge
		end

		-- Validate time
		local startTime = player:GetAttribute("DailyChallengeStart")
		if not startTime then return end

		local calculatedTime = tick() - startTime
		local timeDiff = math.abs(calculatedTime - finishTime)

		-- Allow small discrepancy for network latency
		if timeDiff > 5 then
			warn(string.format("[DailyChallengeService] Time mismatch for %s: client=%.2f, server=%.2f",
				player.Name, finishTime, calculatedTime))
			finishTime = calculatedTime -- Use server time
		end

		-- Check if this is a new best for the player
		local existing = DailyChallengeService.DailyLeaderboard[player.UserId]
		if existing and existing.time <= finishTime then
			-- Not a new best
			return
		end

		-- Record time
		DailyChallengeService.DailyLeaderboard[player.UserId] = {
			time = finishTime,
			name = player.Name,
			date = DailyChallengeService.CurrentDaily.date,
		}

		-- Clear challenge status
		player:SetAttribute("InDailyChallenge", nil)
		player:SetAttribute("DailyChallengeStart", nil)

		-- Award XP
		local xpReward = DailyChallengeService.CalculateReward(player, finishTime, challengeType)
		DailyChallengeService.AwardReward(player, xpReward)

		-- Notify player
		DailyChallengeService.Remotes.DailyChallengeSync:FireClient(player, {
			type = "complete",
			time = finishTime,
			xpAwarded = xpReward,
			placement = DailyChallengeService.GetPlayerPlacement(player.UserId, "daily"),
		})

		print(string.format("[DailyChallengeService] %s completed daily in %.2fs (placement: %d)",
			player.Name, finishTime, DailyChallengeService.GetPlayerPlacement(player.UserId, "daily")))
	end
end

function DailyChallengeService.CalculateReward(player: Player, time: number, challengeType: string): number
	local baseXP = 0

	if challengeType == "daily" then
		baseXP = DailyChallengeService.CurrentDaily.bonusXP

		-- Placement bonus
		local placement = DailyChallengeService.GetPlayerPlacement(player.UserId, "daily")
		if placement == 1 then
			baseXP = baseXP * 3
		elseif placement == 2 then
			baseXP = baseXP * 2
		elseif placement == 3 then
			baseXP = baseXP * 1.5
		end

		-- Streak bonus (would require persistence)
		-- local streak = DataService.GetDailyStreak(player)
		-- baseXP = baseXP + (streak * DailyChallengeService.CurrentDaily.streakBonus)
	elseif challengeType == "weekly" then
		baseXP = DailyChallengeService.CurrentWeekly.bonusXP
	end

	return math.floor(baseXP)
end

function DailyChallengeService.AwardReward(player: Player, xp: number)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.AddXP then
		DataService.AddXP(player, xp)
	end

	print(string.format("[DailyChallengeService] Awarded %d XP to %s", xp, player.Name))
end

-- ============================================================================
-- LEADERBOARD
-- ============================================================================

function DailyChallengeService.GetLeaderboard(challengeType: string): table
	local leaderboard = {}

	local source = challengeType == "daily"
		and DailyChallengeService.DailyLeaderboard
		or DailyChallengeService.WeeklyLeaderboard

	-- Convert to array
	for userId, data in pairs(source) do
		table.insert(leaderboard, {
			userId = userId,
			name = data.name,
			time = data.time,
		})
	end

	-- Sort by time (ascending)
	table.sort(leaderboard, function(a, b)
		return a.time < b.time
	end)

	-- Add placement numbers
	for i, entry in ipairs(leaderboard) do
		entry.placement = i
	end

	return leaderboard
end

function DailyChallengeService.GetPlayerPlacement(userId: number, challengeType: string): number
	local leaderboard = DailyChallengeService.GetLeaderboard(challengeType)

	for _, entry in ipairs(leaderboard) do
		if entry.userId == userId then
			return entry.placement
		end
	end

	return #leaderboard + 1
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function DailyChallengeService.GetTodaysDimension(): string
	return DailyChallengeService.CurrentDaily.dimension
end

function DailyChallengeService.GetDailySeed(): number
	return DailyChallengeService.CurrentDaily.seed
end

function DailyChallengeService.IsPlayerInChallenge(player: Player): boolean
	return player:GetAttribute("InDailyChallenge") or player:GetAttribute("InWeeklyChallenge")
end

return DailyChallengeService
