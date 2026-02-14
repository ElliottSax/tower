--[[
	DailyRewardService.lua
	Daily login reward system to encourage player retention

	Features:
	- Daily rewards (coins, pets, cosmetics)
	- Streak bonuses (consecutive days)
	- Monthly calendar
	- VIP bonus rewards
	- Streak recovery (grace period)

	Created: Week 15 - Retention Mechanics
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailyRewardService = {}
DailyRewardService.Enabled = true

-- Configuration
local CONFIG = {
	-- Daily rewards (7-day cycle)
	Rewards = {
		{
			Day = 1,
			Name = "Day 1 Reward",
			Description = "Welcome back!",
			Coins = 500,
		},
		{
			Day = 2,
			Name = "Day 2 Reward",
			Description = "Keep climbing!",
			Coins = 750,
		},
		{
			Day = 3,
			Name = "Day 3 Reward",
			Description = "You're on a roll!",
			Coins = 1000,
			Pet = "CommonPet",
		},
		{
			Day = 4,
			Name = "Day 4 Reward",
			Description = "Halfway there!",
			Coins = 1250,
		},
		{
			Day = 5,
			Name = "Day 5 Reward",
			Description = "Almost at the weekly bonus!",
			Coins = 1500,
		},
		{
			Day = 6,
			Name = "Day 6 Reward",
			Description = "One more day!",
			Coins = 2000,
		},
		{
			Day = 7,
			Name = "Weekly Bonus!",
			Description = "Amazing streak!",
			Coins = 5000,
			Pet = "RarePet",
			BattlePassXP = 500,
		},
	},

	-- Streak milestones
	StreakMilestones = {
		{Days = 7, Reward = {Coins = 5000, Title = "Dedicated"}},
		{Days = 14, Reward = {Coins = 10000, Pet = "EpicPet"}},
		{Days = 30, Reward = {Coins = 25000, Pet = "LegendaryPet", Title = "Committed"}},
		{Days = 60, Reward = {Coins = 50000, Pet = "MythicPet", Title = "Devoted"}},
		{Days = 100, Reward = {Coins = 100000, Pet = "UltraRarePet", Title = "Legend"}},
	},

	-- VIP multipliers
	VIPBonusMultiplier = 2.0, -- VIP players get 2x coins

	-- Streak recovery
	GracePeriodHours = 24, -- Can claim late without breaking streak
	MaxStreakRecovery = 3, -- Max days that can be recovered
	RecoveryCost = 100, -- Robux per day to recover
}

-- Player daily reward data
local playerRewards = {} -- [userId] = {LastClaim, Streak, DayInCycle}

-- Remote events
local Events = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DailyRewardService.Init()
	print("[DailyRewardService] Initializing...")

	-- Create remote events
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local dailyRewardEvent = eventsFolder:FindFirstChild("DailyRewardEvent")
	if not dailyRewardEvent then
		dailyRewardEvent = Instance.new("RemoteEvent")
		dailyRewardEvent.Name = "DailyRewardEvent"
		dailyRewardEvent.Parent = eventsFolder
	end

	Events = {
		DailyReward = dailyRewardEvent,
	}

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		DailyRewardService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DailyRewardService.OnPlayerLeave(player)
	end)

	-- Connect remote events
	Events.DailyReward.OnServerEvent:Connect(function(player, action)
		-- SECURITY: Validate action is a string
		if type(action) ~= "string" then return end

		if action == "ClaimReward" then
			DailyRewardService.ClaimDailyReward(player)
		elseif action == "RecoverStreak" then
			DailyRewardService.RecoverStreak(player)
		end
	end)

	print("[DailyRewardService] Initialized successfully")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function DailyRewardService.OnPlayerJoin(player: Player)
	if not DailyRewardService.Enabled then return end

	-- Load daily reward data from DataService
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		warn("[DailyRewardService] DataService not available")
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	-- Initialize daily reward data if not exists
	if not profile.Data.DailyReward then
		profile.Data.DailyReward = {
			LastClaim = 0,
			Streak = 0,
			DayInCycle = 0,
			TotalClaims = 0,
			StreakRecord = 0,
		}
	end

	-- Cache data
	playerRewards[player.UserId] = profile.Data.DailyReward

	-- Check if reward is available
	task.delay(2, function()
		DailyRewardService.CheckRewardAvailability(player)
	end)
end

function DailyRewardService.OnPlayerLeave(player: Player)
	-- Cleanup
	playerRewards[player.UserId] = nil
end

-- ============================================================================
-- REWARD CLAIMING
-- ============================================================================

function DailyRewardService.CheckRewardAvailability(player: Player)
	local rewardData = playerRewards[player.UserId]
	if not rewardData then return end

	local now = os.time()
	local lastClaim = rewardData.LastClaim

	-- Check if 24 hours have passed
	local hoursSinceClaim = (now - lastClaim) / 3600

	if hoursSinceClaim >= 24 then
		-- Reward available
		local canClaim = true
		local streakBroken = false

		-- Check if streak is broken (more than 24 + grace period hours)
		if hoursSinceClaim > (24 + CONFIG.GracePeriodHours) and rewardData.Streak > 0 then
			streakBroken = true
		end

		-- Notify client
		Events.DailyReward:FireClient(player, "RewardAvailable", {
			CanClaim = canClaim,
			StreakBroken = streakBroken,
			CurrentStreak = rewardData.Streak,
			NextReward = DailyRewardService.GetNextReward(rewardData),
		})
	end
end

function DailyRewardService.ClaimDailyReward(player: Player)
	local rewardData = playerRewards[player.UserId]
	if not rewardData then return end

	local now = os.time()
	local lastClaim = rewardData.LastClaim

	-- Check if 24 hours have passed
	local hoursSinceClaim = (now - lastClaim) / 3600

	if hoursSinceClaim < 24 then
		-- Too soon to claim
		Events.DailyReward:FireClient(player, "ClaimFailed", {
			Reason = "TooSoon",
			HoursRemaining = 24 - hoursSinceClaim,
		})
		return
	end

	-- Check if streak is broken
	local streakBroken = false
	if hoursSinceClaim > (24 + CONFIG.GracePeriodHours) and rewardData.Streak > 0 then
		streakBroken = true
		rewardData.Streak = 0
		rewardData.DayInCycle = 0
	end

	-- Increment streak and day in cycle
	rewardData.Streak = rewardData.Streak + 1
	rewardData.DayInCycle = rewardData.DayInCycle + 1

	-- Reset cycle if completed
	if rewardData.DayInCycle > 7 then
		rewardData.DayInCycle = 1
	end

	-- Update last claim time
	rewardData.LastClaim = now
	rewardData.TotalClaims = rewardData.TotalClaims + 1

	-- Update streak record
	if rewardData.Streak > rewardData.StreakRecord then
		rewardData.StreakRecord = rewardData.Streak
	end

	-- Get reward for current day
	local reward = CONFIG.Rewards[rewardData.DayInCycle]

	-- Apply VIP bonus
	local isVIP = false
	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if VIPService then
		isVIP = VIPService.IsVIP(player)
	end

	local coinReward = reward.Coins or 0
	if isVIP then
		coinReward = coinReward * CONFIG.VIPBonusMultiplier
	end

	-- Award rewards
	DailyRewardService.GiveReward(player, reward, coinReward)

	-- Check for streak milestones
	DailyRewardService.CheckStreakMilestones(player, rewardData.Streak)

	-- Notify client
	Events.DailyReward:FireClient(player, "RewardClaimed", {
		Reward = reward,
		CoinReward = coinReward,
		Streak = rewardData.Streak,
		DayInCycle = rewardData.DayInCycle,
		IsVIP = isVIP,
		StreakBroken = streakBroken,
	})

	print(string.format(
		"[DailyRewardService] %s claimed Day %d reward (Streak: %d)",
		player.Name,
		rewardData.DayInCycle,
		rewardData.Streak
	))
end

function DailyRewardService.GiveReward(player: Player, reward, coinReward: number)
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	local BattlePassService = _G.TowerAscent and _G.TowerAscent.BattlePassService

	-- Coins
	if coinReward and CoinService then
		CoinService.AddCoins(player, coinReward)
	end

	-- Battle Pass XP
	if reward.BattlePassXP and BattlePassService then
		BattlePassService.AddXP(player, reward.BattlePassXP)
	end

	-- Pet
	if reward.Pet then
		-- PetService integration (Week 37+)
		local PetService = _G.TowerAscent and _G.TowerAscent.PetService
		if PetService then
			-- PetService.GivePet(player, reward.Pet)
		end
	end

	-- Title
	if reward.Title then
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService then
			local profile = DataService.GetProfile(player)
			if profile and profile.Data then
				if not profile.Data.UnlockedTitles then
					profile.Data.UnlockedTitles = {}
				end
				table.insert(profile.Data.UnlockedTitles, reward.Title)
			end
		end
	end
end

function DailyRewardService.CheckStreakMilestones(player: Player, streak: number)
	for _, milestone in ipairs(CONFIG.StreakMilestones) do
		if streak == milestone.Days then
			-- Milestone reached!
			DailyRewardService.GiveReward(player, milestone.Reward, milestone.Reward.Coins or 0)

			-- Notify client
			Events.DailyReward:FireClient(player, "MilestoneReached", {
				Milestone = milestone,
			})

			print(string.format(
				"[DailyRewardService] %s reached %d-day streak milestone!",
				player.Name,
				milestone.Days
			))
		end
	end
end

-- ============================================================================
-- STREAK RECOVERY
-- ============================================================================

function DailyRewardService.RecoverStreak(player: Player)
	local rewardData = playerRewards[player.UserId]
	if not rewardData then return end

	local now = os.time()
	local lastClaim = rewardData.LastClaim

	-- Check if streak is broken
	local hoursSinceClaim = (now - lastClaim) / 3600
	local daysMissed = math.floor(hoursSinceClaim / 24)

	if daysMissed <= 1 then
		-- Streak not broken yet
		Events.DailyReward:FireClient(player, "RecoveryFailed", {
			Reason = "StreakNotBroken",
		})
		return
	end

	if daysMissed > CONFIG.MaxStreakRecovery then
		-- Too many days missed
		Events.DailyReward:FireClient(player, "RecoveryFailed", {
			Reason = "TooManyDaysMissed",
			DaysMissed = daysMissed,
			MaxRecovery = CONFIG.MaxStreakRecovery,
		})
		return
	end

	-- Calculate recovery cost
	local cost = CONFIG.RecoveryCost * (daysMissed - 1) -- First missed day is free (grace period)

	-- Prompt player to purchase recovery
	-- (This would integrate with MarketplaceService)
	-- For now, just notify client with cost
	Events.DailyReward:FireClient(player, "RecoveryPrompt", {
		Cost = cost,
		DaysMissed = daysMissed,
	})
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function DailyRewardService.GetNextReward(rewardData)
	local nextDay = rewardData.DayInCycle + 1
	if nextDay > 7 then
		nextDay = 1
	end
	return CONFIG.Rewards[nextDay]
end

function DailyRewardService.GetPlayerRewardData(player: Player)
	return playerRewards[player.UserId]
end

-- ============================================================================
-- ADMIN/DEBUG
-- ============================================================================

function DailyRewardService.ResetStreak(player: Player)
	local rewardData = playerRewards[player.UserId]
	if not rewardData then return end

	rewardData.Streak = 0
	rewardData.DayInCycle = 0
	rewardData.LastClaim = 0

	print(string.format("[DailyRewardService] Reset streak for %s", player.Name))
end

function DailyRewardService.ForceClaimAvailable(player: Player)
	local rewardData = playerRewards[player.UserId]
	if not rewardData then return end

	-- Set last claim to 25 hours ago
	rewardData.LastClaim = os.time() - (25 * 3600)

	DailyRewardService.CheckRewardAvailability(player)
end

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

return DailyRewardService
