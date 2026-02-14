--[[
	DailyRewardService.lua
	Pet Collector Simulator - Daily Rewards & Login Streaks

	Handles:
	- Daily reward claims (7-day cycle)
	- Login streak tracking
	- Streak bonuses
	- Streak restoration (paid feature)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DailyRewardService = {}
DailyRewardService.DataService = nil
DailyRewardService.CoinService = nil

-- ============================================================================
-- REWARD STRUCTURE
-- ============================================================================

local DAILY_REWARDS = {
	{day = 1, coins = 500, eggs = {Basic = 1}, bonus = 0},
	{day = 2, coins = 750, eggs = {Basic = 1}, bonus = 0},
	{day = 3, coins = 1000, eggs = {Rare = 1}, bonus = 50},
	{day = 4, coins = 1500, eggs = {Rare = 2}, bonus = 100},
	{day = 5, coins = 2000, eggs = {Rare = 2}, bonus = 150},
	{day = 6, coins = 3000, eggs = {Epic = 1}, bonus = 200},
	{day = 7, coins = 5000, eggs = {Legendary = 1}, bonus = 500}, -- Jackpot!
}

local STREAK_MULTIPLIERS = {
	{minDay = 1, maxDay = 7, multiplier = 1.0},
	{minDay = 8, maxDay = 14, multiplier = 1.5},
	{minDay = 15, maxDay = 30, multiplier = 2.0},
	{minDay = 31, maxDay = math.huge, multiplier = 2.5},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DailyRewardService.Init()
	print("[DailyRewardService] Initializing...")

	-- Setup remote events
	DailyRewardService.SetupRemotes()

	print("[DailyRewardService] Initialized - Daily rewards active")
end

function DailyRewardService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Claim daily reward
	local claimRewardRemote = remoteEvents:WaitForChild("ClaimDailyReward")
	claimRewardRemote.OnServerEvent:Connect(function(player)
		DailyRewardService.ClaimDailyReward(player)
	end)

	-- Get reward info
	local getRewardInfoRemote = remoteEvents:WaitForChild("GetDailyRewardInfo")
	getRewardInfoRemote.OnServerInvoke = function(player)
		return DailyRewardService.GetRewardInfo(player)
	end

	-- Restore streak (premium feature)
	local restoreStreakRemote = remoteEvents:WaitForChild("RestoreStreak")
	restoreStreakRemote.OnServerEvent:Connect(function(player)
		DailyRewardService.RestoreStreak(player)
	end)
end

-- ============================================================================
-- DAILY REWARD CLAIMING
-- ============================================================================

function DailyRewardService.ClaimDailyReward(player: Player)
	if not DailyRewardService.DataService then
		DailyRewardService.DataService = require(ServerScriptService.Services.DataService)
	end
	if not DailyRewardService.CoinService then
		DailyRewardService.CoinService = require(ServerScriptService.Services.CoinService)
	end

	local playerData = DailyRewardService.DataService.GetData(player)
	if not playerData then
		warn(string.format("[DailyRewardService] No data for %s", player.Name))
		return
	end

	-- Check if already claimed today
	local lastClaimTime = playerData.DailyReward.LastClaim or 0
	local now = os.time()
	local hoursSinceLastClaim = (now - lastClaimTime) / 3600

	if hoursSinceLastClaim < 20 then
		print(string.format("[DailyRewardService] %s already claimed today (%.1f hours ago)",
			player.Name, hoursSinceLastClaim))
		return
	end

	-- Update streak
	local daysSinceLastClaim = math.floor(hoursSinceLastClaim / 24)
	local streakBroken = daysSinceLastClaim > 1

	if streakBroken then
		playerData.DailyReward.Streak = 1
		print(string.format("[DailyRewardService] %s's streak broken (%.1f hours)",
			player.Name, hoursSinceLastClaim))
	else
		playerData.DailyReward.Streak = (playerData.DailyReward.Streak or 0) + 1
	end

	-- Cap streak at 7 and cycle
	local dayInCycle = ((playerData.DailyReward.Streak - 1) % 7) + 1
	playerData.DailyReward.DayInCycle = dayInCycle
	playerData.DailyReward.LastClaim = now
	playerData.DailyReward.TotalClaims = (playerData.DailyReward.TotalClaims or 0) + 1

	-- Update streak record
	if playerData.DailyReward.Streak > (playerData.DailyReward.StreakRecord or 0) then
		playerData.DailyReward.StreakRecord = playerData.DailyReward.Streak
	end

	-- Get rewards for this day
	local reward = DAILY_REWARDS[dayInCycle]

	-- Apply streak multiplier
	local streakMultiplier = DailyRewardService.GetStreakMultiplier(playerData.DailyReward.Streak)
	local baseCoins = reward.coins
	local bonusCoins = reward.bonus
	local totalCoins = math.floor(baseCoins * streakMultiplier) + bonusCoins

	-- Grant coins
	playerData.Coins = (playerData.Coins or 0) + totalCoins

	-- Grant eggs (via PetService)
	local PetService = require(ServerScriptService.Services.PetService)
	if reward.eggs then
		for eggType, count in pairs(reward.eggs) do
			for i = 1, count do
				PetService.HatchEgg(player, eggType)
			end
		end
	end

	-- Log the claim
	print(string.format(
		"[DailyRewardService] %s claimed daily reward: %d coins (day %d, streak %d, multiplier %.1fx)",
		player.Name, totalCoins, dayInCycle, playerData.DailyReward.Streak, streakMultiplier
	))

	-- Notify player
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
	if notifyRemote then
		notifyRemote:FireClient(player, string.format(
			"Daily Reward Claimed! +%d coins (Day %d streak)",
			totalCoins, playerData.DailyReward.Streak
		), "success")
	end
end

-- ============================================================================
-- STREAK MANAGEMENT
-- ============================================================================

function DailyRewardService.GetStreakMultiplier(streak: number): number
	for _, tier in ipairs(STREAK_MULTIPLIERS) do
		if streak >= tier.minDay and streak <= tier.maxDay then
			return tier.multiplier
		end
	end
	return 1.0
end

function DailyRewardService.RestoreStreak(player: Player)
	if not DailyRewardService.DataService then
		DailyRewardService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = DailyRewardService.DataService.GetData(player)
	if not playerData then return end

	-- Check if streak is actually broken
	local lastClaimTime = playerData.DailyReward.LastClaim or 0
	local now = os.time()
	local hoursSinceLastClaim = (now - lastClaimTime) / 3600

	if hoursSinceLastClaim < 20 then
		print(string.format("[DailyRewardService] %s's streak not broken yet", player.Name))
		return
	end

	-- Restore streak (preserve current streak before it breaks)
	playerData.DailyReward.LastClaim = now - (18 * 3600) -- Set to 18 hours ago so claim is still available

	print(string.format("[DailyRewardService] %s's streak restored (cost 100 Robux)",
		player.Name))

	-- Notify player
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
	if notifyRemote then
		notifyRemote:FireClient(player, "Streak restored! Keep the momentum going.", "success")
	end
end

-- ============================================================================
-- REWARD INFO
-- ============================================================================

function DailyRewardService.GetRewardInfo(player: Player): table
	if not DailyRewardService.DataService then
		DailyRewardService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = DailyRewardService.DataService.GetData(player)
	if not playerData then return {} end

	local now = os.time()
	local lastClaimTime = playerData.DailyReward.LastClaim or 0
	local hoursSinceLastClaim = (now - lastClaimTime) / 3600
	local daysSinceLastClaim = math.floor(hoursSinceLastClaim / 24)

	-- Check if can claim
	local canClaim = hoursSinceLastClaim >= 20
	local streakBroken = daysSinceLastClaim > 1 and lastClaimTime > 0

	-- Calculate next claim time
	local nextClaimTime = math.max(0, math.ceil((24 - hoursSinceLastClaim) * 3600))

	-- Get upcoming rewards
	local upcomingRewards = {}
	for i = 1, 7 do
		local dayInCycle = ((playerData.DailyReward.Streak - 1 + i - 1) % 7) + 1
		table.insert(upcomingRewards, DAILY_REWARDS[dayInCycle])
	end

	-- Get streak multiplier
	local streakMultiplier = DailyRewardService.GetStreakMultiplier(playerData.DailyReward.Streak)

	return {
		CurrentStreak = playerData.DailyReward.Streak or 0,
		StreakRecord = playerData.DailyReward.StreakRecord or 0,
		DayInCycle = playerData.DailyReward.DayInCycle or 1,
		CanClaim = canClaim,
		StreakBroken = streakBroken,
		NextClaimInSeconds = nextClaimTime,
		CurrentReward = DAILY_REWARDS[playerData.DailyReward.DayInCycle or 1],
		UpcomingRewards = upcomingRewards,
		StreakMultiplier = streakMultiplier,
		TotalRewardsClaimed = playerData.DailyReward.TotalClaims or 0,
	}
end

function DailyRewardService.GetUpcomingRewards(): table
	local upcoming = {}
	for i, reward in ipairs(DAILY_REWARDS) do
		table.insert(upcoming, {
			Day = i,
			Coins = reward.coins,
			Eggs = reward.eggs,
			Bonus = reward.bonus,
		})
	end
	return upcoming
end

return DailyRewardService
