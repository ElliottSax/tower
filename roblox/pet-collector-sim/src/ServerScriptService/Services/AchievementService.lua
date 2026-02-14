--[[
	AchievementService.lua
	Pet Collector Simulator - Achievements & Progression

	Handles:
	- Achievement unlocking
	- Progress tracking
	- Reward distribution
	- Achievement categories
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AchievementService = {}
AchievementService.DataService = nil

-- ============================================================================
-- ACHIEVEMENT DEFINITIONS
-- ============================================================================

local ACHIEVEMENTS = {
	-- Collection Achievements
	FirstPet = {
		Id = "FirstPet",
		Name = "First Steps",
		Description = "Hatch your first pet",
		Category = "Collection",
		Target = 1,
		Condition = "PetsOwned",
		Reward = {Coins = 500, Essence = 10, Title = "Newcomer"},
	},
	GrowingCollection = {
		Id = "GrowingCollection",
		Name = "Growing Collection",
		Description = "Collect 10 pets",
		Category = "Collection",
		Target = 10,
		Condition = "PetsOwned",
		Reward = {Coins = 2000, Essence = 50, Badge = "Collector"},
	},
	PetEnthusiast = {
		Id = "PetEnthusiast",
		Name = "Pet Enthusiast",
		Description = "Collect 25 pets",
		Category = "Collection",
		Target = 25,
		Condition = "PetsOwned",
		Reward = {Coins = 5000, Essence = 100, Badge = "Enthusiast"},
	},
	SeriousCollector = {
		Id = "SeriousCollector",
		Name = "Serious Collector",
		Description = "Collect 50 pets",
		Category = "Collection",
		Target = 50,
		Condition = "PetsOwned",
		Reward = {Coins = 10000, Essence = 250, Title = "Dedicated Collector"},
	},
	MasterCollector = {
		Id = "MasterCollector",
		Name = "Master Collector",
		Description = "Collect all 60+ pets",
		Category = "Collection",
		Target = 60,
		Condition = "PetsOwned",
		Reward = {Coins = 50000, Essence = 500, Title = "Master", Badge = "Elite"},
	},

	-- Rarity Achievements
	FindRare = {
		Id = "FindRare",
		Name = "Lucky Find",
		Description = "Hatch a Rare pet",
		Category = "Rarity",
		Target = 1,
		Condition = "RarePetsOwned",
		Reward = {Coins = 3000, Essence = 75, Badge = "Lucky"},
	},
	FindLegendary = {
		Id = "FindLegendary",
		Name = "Legendary Hunter",
		Description = "Hatch a Legendary pet",
		Category = "Rarity",
		Target = 1,
		Condition = "LegendaryPetsOwned",
		Reward = {Coins = 10000, Essence = 200, Title = "Legend"},
	},
	FindMythic = {
		Id = "FindMythic",
		Name = "Mythic Master",
		Description = "Hatch a Mythic pet",
		Category = "Rarity",
		Target = 1,
		Condition = "MythicPetsOwned",
		Reward = {Coins = 50000, Essence = 500, Title = "Mythic Master", Badge = "Godly"},
	},

	-- Progression Achievements
	ReachWorld2 = {
		Id = "ReachWorld2",
		Name = "World Explorer",
		Description = "Unlock World 2",
		Category = "Progression",
		Target = 2,
		Condition = "WorldsUnlocked",
		Reward = {Coins = 2000, Essence = 50},
	},
	ReachWorld3 = {
		Id = "ReachWorld3",
		Name = "Seasoned Traveler",
		Description = "Unlock World 3",
		Category = "Progression",
		Target = 3,
		Condition = "WorldsUnlocked",
		Reward = {Coins = 5000, Essence = 100, Title = "Traveler"},
	},
	ReachWorld4 = {
		Id = "ReachWorld4",
		Name = "World Master",
		Description = "Unlock World 4",
		Category = "Progression",
		Target = 4,
		Condition = "WorldsUnlocked",
		Reward = {Coins = 10000, Essence = 200},
	},
	ReachWorld5 = {
		Id = "ReachWorld5",
		Name = "Paradise Seeker",
		Description = "Unlock World 5 (VIP)",
		Category = "Progression",
		Target = 5,
		Condition = "WorldsUnlocked",
		Reward = {Coins = 25000, Essence = 500, Title = "VIP Paradise", Badge = "Premium"},
	},

	-- Hatching Achievements
	HatchHundred = {
		Id = "HatchHundred",
		Name = "Hatcher",
		Description = "Hatch 100 eggs",
		Category = "Hatching",
		Target = 100,
		Condition = "EggsHatched",
		Reward = {Coins = 5000, Essence = 100},
	},
	HatchThousand = {
		Id = "HatchThousand",
		Name = "Master Hatcher",
		Description = "Hatch 1,000 eggs",
		Category = "Hatching",
		Target = 1000,
		Condition = "EggsHatched",
		Reward = {Coins = 50000, Essence = 500, Title = "Hatcher Supreme"},
	},

	-- Spending Achievements
	FirstSpend = {
		Id = "FirstSpend",
		Name = "First Purchase",
		Description = "Make your first purchase",
		Category = "Spending",
		Target = 1,
		Condition = "Purchases",
		Reward = {Coins = 1000, Essence = 25},
	},
	BigSpender = {
		Id = "BigSpender",
		Name = "Big Spender",
		Description = "Spend 1,000 Robux",
		Category = "Spending",
		Target = 1000,
		Condition = "RobuxSpent",
		Reward = {Coins = 25000, Essence = 500, Title = "Big Spender"},
	},
	Whale = {
		Id = "Whale",
		Name = "Whale",
		Description = "Spend 10,000 Robux",
		Category = "Spending",
		Target = 10000,
		Condition = "RobuxSpent",
		Reward = {Coins = 100000, Essence = 2000, Title = "Whale", Badge = "Legendary Supporter"},
	},

	-- Streak Achievements
	WeekWarrior = {
		Id = "WeekWarrior",
		Name = "Week Warrior",
		Description = "Achieve a 7-day login streak",
		Category = "Streak",
		Target = 7,
		Condition = "LoginStreak",
		Reward = {Coins = 5000, Essence = 100, Badge = "Dedicated"},
	},
	MonthWarrior = {
		Id = "MonthWarrior",
		Name = "Month Warrior",
		Description = "Achieve a 30-day login streak",
		Category = "Streak",
		Target = 30,
		Condition = "LoginStreak",
		Reward = {Coins = 25000, Essence = 500, Title = "Month Warrior"},
	},
	CenturyPlayer = {
		Id = "CenturyPlayer",
		Name = "Century Player",
		Description = "Achieve a 100-day login streak",
		Category = "Streak",
		Target = 100,
		Condition = "LoginStreak",
		Reward = {Coins = 100000, Essence = 2000, Title = "Century Legend", Badge = "Eternal"},
	},

	-- Earning Achievements
	EarnMillion = {
		Id = "EarnMillion",
		Name = "Millionaire",
		Description = "Earn 1,000,000 coins lifetime",
		Category = "Earning",
		Target = 1000000,
		Condition = "CoinsEarned",
		Reward = {Coins = 50000, Essence = 500, Title = "Millionaire", Badge = "Wealth"},
	},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function AchievementService.Init()
	print("[AchievementService] Initializing...")

	-- Setup remote events
	AchievementService.SetupRemotes()

	print("[AchievementService] Initialized - Achievements tracking active")
end

function AchievementService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Get achievements
	local getAchievementsRemote = remoteEvents:WaitForChild("GetAchievements")
	getAchievementsRemote.OnServerInvoke = function(player)
		return AchievementService.GetAchievements(player)
	end

	-- Get achievement progress
	local getProgressRemote = remoteEvents:WaitForChild("GetAchievementProgress")
	getProgressRemote.OnServerInvoke = function(player, achievementId)
		return AchievementService.GetAchievementProgress(player, achievementId)
	end
end

-- ============================================================================
-- ACHIEVEMENT UNLOCKING
-- ============================================================================

function AchievementService.CheckAndUnlock(player: Player, condition: string, value: number)
	if not AchievementService.DataService then
		AchievementService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = AchievementService.DataService.GetData(player)
	if not playerData then return end

	if not playerData.Achievements then
		playerData.Achievements = {}
	end

	-- Check all achievements for this condition
	for achievementId, achievementDef in pairs(ACHIEVEMENTS) do
		if achievementDef.Condition == condition then
			-- Check if already unlocked
			if playerData.Achievements[achievementId] and playerData.Achievements[achievementId].Unlocked then
				goto continue
			end

			-- Initialize achievement if not exists
			if not playerData.Achievements[achievementId] then
				playerData.Achievements[achievementId] = {
					Unlocked = false,
					Progress = 0,
					UnlockedAt = 0,
				}
			end

			-- Update progress
			playerData.Achievements[achievementId].Progress = value

			-- Check if target reached
			if value >= achievementDef.Target then
				AchievementService.UnlockAchievement(player, achievementId)
			end

			::continue::
		end
	end
end

function AchievementService.UnlockAchievement(player: Player, achievementId: string)
	if not AchievementService.DataService then
		AchievementService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = AchievementService.DataService.GetData(player)
	if not playerData then return end

	if not playerData.Achievements then
		playerData.Achievements = {}
	end

	-- Check if already unlocked
	if playerData.Achievements[achievementId] and playerData.Achievements[achievementId].Unlocked then
		return
	end

	local achievement = ACHIEVEMENTS[achievementId]
	if not achievement then
		warn(string.format("[AchievementService] Unknown achievement: %s", achievementId))
		return
	end

	-- Mark as unlocked
	if not playerData.Achievements[achievementId] then
		playerData.Achievements[achievementId] = {}
	end

	playerData.Achievements[achievementId].Unlocked = true
	playerData.Achievements[achievementId].UnlockedAt = os.time()

	-- Grant rewards
	if achievement.Reward then
		if achievement.Reward.Coins then
			playerData.Coins = (playerData.Coins or 0) + achievement.Reward.Coins
		end
		if achievement.Reward.Essence then
			playerData.Essence = (playerData.Essence or 0) + achievement.Reward.Essence
		end
		if achievement.Reward.Title then
			if not playerData.UnlockedTitles then
				playerData.UnlockedTitles = {}
			end
			table.insert(playerData.UnlockedTitles, achievement.Reward.Title)
		end
		if achievement.Reward.Badge then
			if not playerData.UnlockedBadges then
				playerData.UnlockedBadges = {}
			end
			table.insert(playerData.UnlockedBadges, achievement.Reward.Badge)
		end
	end

	print(string.format("[AchievementService] %s unlocked achievement: %s",
		player.Name, achievement.Name))

	-- Notify player
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
	if notifyRemote then
		notifyRemote:FireClient(player, string.format(
			"Achievement Unlocked: %s! +%d coins",
			achievement.Name, achievement.Reward.Coins or 0
		), "success")
	end
end

-- ============================================================================
-- ACHIEVEMENT INFO
-- ============================================================================

function AchievementService.GetAchievements(player: Player): table
	if not AchievementService.DataService then
		AchievementService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = AchievementService.DataService.GetData(player)
	if not playerData then return {} end

	local achievements = {}
	for achievementId, achievementDef in pairs(ACHIEVEMENTS) do
		local playerAchievement = playerData.Achievements and playerData.Achievements[achievementId] or {}

		table.insert(achievements, {
			Id = achievementId,
			Name = achievementDef.Name,
			Description = achievementDef.Description,
			Category = achievementDef.Category,
			Unlocked = playerAchievement.Unlocked or false,
			Progress = playerAchievement.Progress or 0,
			Target = achievementDef.Target,
			UnlockedAt = playerAchievement.UnlockedAt or 0,
			Reward = achievementDef.Reward,
		})
	end

	return achievements
end

function AchievementService.GetAchievementProgress(player: Player, achievementId: string): table
	if not AchievementService.DataService then
		AchievementService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = AchievementService.DataService.GetData(player)
	if not playerData then return {} end

	local achievement = ACHIEVEMENTS[achievementId]
	if not achievement then
		warn(string.format("[AchievementService] Unknown achievement: %s", achievementId))
		return {}
	end

	local playerAchievement = playerData.Achievements and playerData.Achievements[achievementId] or {}

	return {
		Id = achievementId,
		Name = achievement.Name,
		Description = achievement.Description,
		Category = achievement.Category,
		Unlocked = playerAchievement.Unlocked or false,
		Progress = playerAchievement.Progress or 0,
		Target = achievement.Target,
		PercentComplete = math.min(100, math.floor(((playerAchievement.Progress or 0) / achievement.Target) * 100)),
		UnlockedAt = playerAchievement.UnlockedAt or 0,
		Reward = achievement.Reward,
	}
end

function AchievementService.GetAllAchievements(): table
	local achievements = {}
	for achievementId, achievementDef in pairs(ACHIEVEMENTS) do
		table.insert(achievements, {
			Id = achievementId,
			Name = achievementDef.Name,
			Description = achievementDef.Description,
			Category = achievementDef.Category,
			Target = achievementDef.Target,
			Reward = achievementDef.Reward,
		})
	end
	return achievements
end

return AchievementService
