--[[
	RewardsService.lua
	Handles XP, coins, leveling, and rewards

	Features:
	- XP gain and leveling
	- Coin rewards
	- Level-up notifications
	- Reward multipliers (VIP, etc.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardsService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- XP required per level (formula: baseXP * level^1.5)
local BASE_XP = 100
local XP_EXPONENT = 1.5
local MAX_LEVEL = 100

-- Reward amounts
local REWARDS = {
	-- Race completion
	raceFinish = { xp = 50, coins = 10 },
	raceFirst = { xp = 150, coins = 50 },
	raceSecond = { xp = 100, coins = 30 },
	raceThird = { xp = 75, coins = 20 },

	-- Achievements
	achievement = { xp = 100, coins = 25 },
	achievementRare = { xp = 250, coins = 75 },

	-- Daily
	dailyLogin = { xp = 25, coins = 15 },
	dailyChallengeComplete = { xp = 200, coins = 50 },
	weeklyChallengeComplete = { xp = 500, coins = 150 },

	-- Milestones
	firstWin = { xp = 200, coins = 100 },
	tenWins = { xp = 500, coins = 200 },
	fiftyWins = { xp = 1000, coins = 500 },
	hundredWins = { xp = 2500, coins = 1000 },

	-- Dimension mastery
	dimensionComplete = { xp = 300, coins = 100 },
	allDimensionsComplete = { xp = 1000, coins = 500 },

	-- Level up bonuses
	levelUp = { coins = 25 }, -- Per level
	levelMilestone10 = { coins = 100 },
	levelMilestone25 = { coins = 250 },
	levelMilestone50 = { coins = 500 },
	levelMilestone100 = { coins = 1000 },

	-- Tutorial
	tutorialComplete = { xp = 100, coins = 50 },

	-- Personal best
	personalBest = { xp = 50, coins = 15 },
}

-- ============================================================================
-- STATE
-- ============================================================================

-- Cache player data for quick access
-- [UserId] = { level, xp, coins, vipMultiplier }
RewardsService.PlayerCache = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RewardsService.Init()
	print("[RewardsService] Initializing...")

	RewardsService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		RewardsService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		RewardsService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		RewardsService.OnPlayerJoin(player)
	end

	print("[RewardsService] Initialized")
end

function RewardsService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- XP gained
	if not remoteFolder:FindFirstChild("XPGained") then
		local event = Instance.new("RemoteEvent")
		event.Name = "XPGained"
		event.Parent = remoteFolder
	end

	-- Coins gained
	if not remoteFolder:FindFirstChild("CoinsGained") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CoinsGained"
		event.Parent = remoteFolder
	end

	-- Level up
	if not remoteFolder:FindFirstChild("LevelUp") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LevelUp"
		event.Parent = remoteFolder
	end

	-- Get player stats
	if not remoteFolder:FindFirstChild("GetRewardStats") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetRewardStats"
		func.Parent = remoteFolder
	end

	RewardsService.Remotes = {
		XPGained = remoteFolder.XPGained,
		CoinsGained = remoteFolder.CoinsGained,
		LevelUp = remoteFolder.LevelUp,
		GetRewardStats = remoteFolder.GetRewardStats,
	}

	RewardsService.Remotes.GetRewardStats.OnServerInvoke = function(player)
		return RewardsService.GetPlayerStats(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function RewardsService.OnPlayerJoin(player: Player)
	RewardsService.PlayerCache[player.UserId] = {
		level = 1,
		xp = 0,
		coins = 0,
		vipMultiplier = 1.0,
	}

	RewardsService.LoadPlayerData(player)
end

function RewardsService.OnPlayerLeave(player: Player)
	RewardsService.SavePlayerData(player)
	RewardsService.PlayerCache[player.UserId] = nil
end

function RewardsService.LoadPlayerData(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data then
		local cache = RewardsService.PlayerCache[player.UserId]
		if cache then
			cache.level = data.Level or 1
			cache.xp = data.XP or 0
			cache.coins = data.Coins or 0

			-- Check VIP status
			local MonetizationService = DimensionHopper.GetService("MonetizationService")
			if MonetizationService and MonetizationService.HasVIP then
				cache.vipMultiplier = MonetizationService.HasVIP(player) and 2.0 or 1.0
			end
		end
	end
end

function RewardsService.SavePlayerData(player: Player)
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			Level = cache.level,
			XP = cache.xp,
			Coins = cache.coins,
		})
	end
end

-- ============================================================================
-- XP SYSTEM
-- ============================================================================

function RewardsService.GetXPForLevel(level: number): number
	return math.floor(BASE_XP * math.pow(level, XP_EXPONENT))
end

function RewardsService.GetTotalXPForLevel(level: number): number
	local total = 0
	for i = 1, level - 1 do
		total = total + RewardsService.GetXPForLevel(i)
	end
	return total
end

function RewardsService.CalculateLevelFromXP(totalXP: number): (number, number)
	local level = 1
	local xpRequired = RewardsService.GetXPForLevel(1)
	local currentLevelXP = totalXP

	while currentLevelXP >= xpRequired and level < MAX_LEVEL do
		currentLevelXP = currentLevelXP - xpRequired
		level = level + 1
		xpRequired = RewardsService.GetXPForLevel(level)
	end

	return level, currentLevelXP
end

function RewardsService.AddXP(player: Player, amount: number, reason: string?)
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return end

	-- Apply multiplier
	local multipliedAmount = math.floor(amount * cache.vipMultiplier)

	local oldLevel = cache.level
	cache.xp = cache.xp + multipliedAmount

	-- Check for level up
	local xpRequired = RewardsService.GetXPForLevel(cache.level)
	while cache.xp >= xpRequired and cache.level < MAX_LEVEL do
		cache.xp = cache.xp - xpRequired
		cache.level = cache.level + 1
		xpRequired = RewardsService.GetXPForLevel(cache.level)

		-- Level up rewards
		RewardsService.OnLevelUp(player, cache.level)
	end

	-- Notify client
	RewardsService.Remotes.XPGained:FireClient(player, {
		amount = multipliedAmount,
		baseAmount = amount,
		multiplier = cache.vipMultiplier,
		reason = reason,
		newXP = cache.xp,
		xpRequired = xpRequired,
		level = cache.level,
	})

	-- Notify if leveled up
	if cache.level > oldLevel then
		RewardsService.Remotes.LevelUp:FireClient(player, {
			newLevel = cache.level,
			oldLevel = oldLevel,
		})

		-- Notify other services
		local DimensionHopper = _G.DimensionHopper
		if DimensionHopper then
			local EmoteService = DimensionHopper.GetService("EmoteService")
			if EmoteService and EmoteService.OnLevelUp then
				EmoteService.OnLevelUp(player, cache.level)
			end

			local TrailsService = DimensionHopper.GetService("TrailsService")
			if TrailsService and TrailsService.OnLevelUp then
				TrailsService.OnLevelUp(player, cache.level)
			end
		end
	end

	if reason then
		print(string.format("[RewardsService] %s gained %d XP (%s)", player.Name, multipliedAmount, reason))
	end
end

function RewardsService.OnLevelUp(player: Player, newLevel: number)
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return end

	-- Level up coin bonus
	local levelCoins = REWARDS.levelUp.coins
	cache.coins = cache.coins + levelCoins

	-- Milestone bonuses
	if newLevel == 10 then
		cache.coins = cache.coins + REWARDS.levelMilestone10.coins
	elseif newLevel == 25 then
		cache.coins = cache.coins + REWARDS.levelMilestone25.coins
	elseif newLevel == 50 then
		cache.coins = cache.coins + REWARDS.levelMilestone50.coins
	elseif newLevel == 100 then
		cache.coins = cache.coins + REWARDS.levelMilestone100.coins
	end

	-- Notification
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		local NotificationService = DimensionHopper.GetService("NotificationService")
		if NotificationService then
			NotificationService.Send(player, "LEVEL_UP", "Level Up!", "You reached level " .. newLevel)
		end
	end

	print(string.format("[RewardsService] %s leveled up to %d", player.Name, newLevel))
end

-- ============================================================================
-- COINS SYSTEM
-- ============================================================================

function RewardsService.AddCoins(player: Player, amount: number, reason: string?)
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return end

	-- Apply multiplier for VIP
	local multipliedAmount = math.floor(amount * cache.vipMultiplier)
	cache.coins = cache.coins + multipliedAmount

	-- Notify client
	RewardsService.Remotes.CoinsGained:FireClient(player, {
		amount = multipliedAmount,
		baseAmount = amount,
		multiplier = cache.vipMultiplier,
		reason = reason,
		totalCoins = cache.coins,
	})

	if reason then
		print(string.format("[RewardsService] %s gained %d coins (%s)", player.Name, multipliedAmount, reason))
	end
end

function RewardsService.SpendCoins(player: Player, amount: number): boolean
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return false end

	if cache.coins < amount then
		return false
	end

	cache.coins = cache.coins - amount
	return true
end

function RewardsService.HasCoins(player: Player, amount: number): boolean
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then return false end
	return cache.coins >= amount
end

-- ============================================================================
-- REWARD GRANTING
-- ============================================================================

function RewardsService.GiveReward(player: Player, rewardType: string)
	local reward = REWARDS[rewardType]
	if not reward then
		warn("[RewardsService] Unknown reward type:", rewardType)
		return
	end

	if reward.xp then
		RewardsService.AddXP(player, reward.xp, rewardType)
	end

	if reward.coins then
		RewardsService.AddCoins(player, reward.coins, rewardType)
	end
end

function RewardsService.GiveRaceReward(player: Player, position: number)
	if position == 1 then
		RewardsService.GiveReward(player, "raceFirst")
	elseif position == 2 then
		RewardsService.GiveReward(player, "raceSecond")
	elseif position == 3 then
		RewardsService.GiveReward(player, "raceThird")
	else
		RewardsService.GiveReward(player, "raceFinish")
	end
end

-- ============================================================================
-- API
-- ============================================================================

function RewardsService.GetPlayerStats(player: Player): table
	local cache = RewardsService.PlayerCache[player.UserId]
	if not cache then
		return {
			level = 1,
			xp = 0,
			coins = 0,
			xpRequired = RewardsService.GetXPForLevel(1),
			vipMultiplier = 1.0,
		}
	end

	return {
		level = cache.level,
		xp = cache.xp,
		coins = cache.coins,
		xpRequired = RewardsService.GetXPForLevel(cache.level),
		vipMultiplier = cache.vipMultiplier,
		maxLevel = MAX_LEVEL,
	}
end

function RewardsService.GetLevel(player: Player): number
	local cache = RewardsService.PlayerCache[player.UserId]
	return cache and cache.level or 1
end

function RewardsService.GetCoins(player: Player): number
	local cache = RewardsService.PlayerCache[player.UserId]
	return cache and cache.coins or 0
end

function RewardsService.SetVIPMultiplier(player: Player, multiplier: number)
	local cache = RewardsService.PlayerCache[player.UserId]
	if cache then
		cache.vipMultiplier = multiplier
	end
end

return RewardsService
