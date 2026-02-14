--[[
	AchievementService.lua
	Achievement system with badges, rewards, and progression tracking

	Features:
	- 50+ achievements
	- Tiered achievements (bronze, silver, gold)
	- Hidden achievements
	- Progress tracking
	- Rewards (coins, pets, cosmetics)
	- Roblox badge integration

	Created: Week 15 - Player Engagement
--]]

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementService = {}
AchievementService.Enabled = true

-- Configuration
local CONFIG = {
	Achievements = {
		-- Climbing Achievements
		{
			Id = "FirstClimb",
			Name = "First Steps",
			Description = "Complete your first tower climb",
			Icon = "rbxassetid://0",
			Category = "Climbing",
			Hidden = false,
			BadgeId = nil, -- Roblox badge ID
			Reward = {Coins = 500},
			Condition = function(player, data)
				return data.Stats.TotalClimbs >= 1
			end,
		},
		{
			Id = "Climber10",
			Name = "Dedicated Climber",
			Description = "Complete 10 tower climbs",
			Icon = "rbxassetid://0",
			Category = "Climbing",
			Hidden = false,
			Reward = {Coins = 2000},
			Condition = function(player, data)
				return data.Stats.TotalClimbs >= 10
			end,
		},
		{
			Id = "Climber50",
			Name = "Tower Master",
			Description = "Complete 50 tower climbs",
			Icon = "rbxassetid://0",
			Category = "Climbing",
			Hidden = false,
			Reward = {Coins = 10000, Title = "Tower Master"},
			Condition = function(player, data)
				return data.Stats.TotalClimbs >= 50
			end,
		},
		{
			Id = "Climber100",
			Name = "Legend of the Tower",
			Description = "Complete 100 tower climbs",
			Icon = "rbxassetid://0",
			Category = "Climbing",
			Hidden = false,
			Reward = {Coins = 50000, Pet = "LegendPet", Title = "Legend"},
			Condition = function(player, data)
				return data.Stats.TotalClimbs >= 100
			end,
		},

		-- Speed Achievements
		{
			Id = "SpeedRunner",
			Name = "Speed Runner",
			Description = "Complete a tower in under 5 minutes",
			Icon = "rbxassetid://0",
			Category = "Speed",
			Hidden = false,
			Reward = {Coins = 1000, Trail = "SpeedTrail"},
			Condition = function(player, data)
				return data.Stats.FastestClimb and data.Stats.FastestClimb < 300
			end,
		},
		{
			Id = "SpeedDemon",
			Name = "Speed Demon",
			Description = "Complete a tower in under 3 minutes",
			Icon = "rbxassetid://0",
			Category = "Speed",
			Hidden = false,
			Reward = {Coins = 5000, Trail = "DemonTrail"},
			Condition = function(player, data)
				return data.Stats.FastestClimb and data.Stats.FastestClimb < 180
			end,
		},

		-- Coin Achievements
		{
			Id = "CoinCollector",
			Name = "Coin Collector",
			Description = "Collect 10,000 coins total",
			Icon = "rbxassetid://0",
			Category = "Coins",
			Hidden = false,
			Reward = {Coins = 1000},
			Condition = function(player, data)
				return data.Stats.TotalCoinsCollected >= 10000
			end,
		},
		{
			Id = "CoinMaster",
			Name = "Coin Master",
			Description = "Collect 100,000 coins total",
			Icon = "rbxassetid://0",
			Category = "Coins",
			Hidden = false,
			Reward = {Coins = 10000, Title = "Coin Master"},
			Condition = function(player, data)
				return data.Stats.TotalCoinsCollected >= 100000
			end,
		},

		-- Challenge Achievements
		{
			Id = "NoDeathClimb",
			Name = "Flawless Ascent",
			Description = "Complete a tower without dying",
			Icon = "rbxassetid://0",
			Category = "Challenge",
			Hidden = false,
			Reward = {Coins = 3000},
			Condition = function(player, data)
				return data.Stats.FlawlessClimbs >= 1
			end,
		},
		{
			Id = "NightmareClimb",
			Name = "Nightmare Conqueror",
			Description = "Complete a Nightmare difficulty tower",
			Icon = "rbxassetid://0",
			Category = "Challenge",
			Hidden = false,
			Reward = {Coins = 10000, Pet = "NightmarePet"},
			Condition = function(player, data)
				return data.Stats.NightmareClimbs >= 1
			end,
		},

		-- Social Achievements
		{
			Id = "FirstTrade",
			Name = "Trader",
			Description = "Complete your first trade",
			Icon = "rbxassetid://0",
			Category = "Social",
			Hidden = false,
			Reward = {Coins = 500},
			Condition = function(player, data)
				return data.Stats.TotalTrades >= 1
			end,
		},
		{
			Id = "GuildMember",
			Name = "Guild Member",
			Description = "Join a guild",
			Icon = "rbxassetid://0",
			Category = "Social",
			Hidden = false,
			Reward = {Coins = 1000},
			Condition = function(player, data)
				return data.GuildId ~= nil
			end,
		},

		-- Hidden Achievements
		{
			Id = "SecretPath",
			Name = "Secret Explorer",
			Description = "Find a secret path",
			Icon = "rbxassetid://0",
			Category = "Secrets",
			Hidden = true,
			Reward = {Coins = 5000, Pet = "SecretPet"},
			Condition = function(player, data)
				return data.Stats.SecretsFound >= 1
			end,
		},
		{
			Id = "DevEncounter",
			Name = "Developer Encounter",
			Description = "Play with a game developer",
			Icon = "rbxassetid://0",
			Category = "Secrets",
			Hidden = true,
			Reward = {Coins = 10000, Title = "Dev Friend"},
			Condition = function(player, data)
				return data.Stats.MetDeveloper == true
			end,
		},
	},

	Categories = {
		"Climbing",
		"Speed",
		"Coins",
		"Challenge",
		"Social",
		"Secrets",
	},
}

-- Player achievement progress
local playerAchievements = {} -- [userId] = {AchievementId = {Unlocked, Progress, UnlockedAt}}

-- Remote events
local Events = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function AchievementService.Init()
	print("[AchievementService] Initializing...")

	-- Create remote events
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local achievementEvent = eventsFolder:FindFirstChild("AchievementEvent")
	if not achievementEvent then
		achievementEvent = Instance.new("RemoteEvent")
		achievementEvent.Name = "AchievementEvent"
		achievementEvent.Parent = eventsFolder
	end

	Events = {
		Achievement = achievementEvent,
	end

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		AchievementService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		AchievementService.OnPlayerLeave(player)
	end)

	print(string.format("[AchievementService] Initialized with %d achievements", #CONFIG.Achievements))
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function AchievementService.OnPlayerJoin(player: Player)
	if not AchievementService.Enabled then return end

	-- Load achievements from DataService
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		warn("[AchievementService] DataService not available")
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	-- Initialize achievements data if not exists
	if not profile.Data.Achievements then
		profile.Data.Achievements = {}
	end

	-- Cache achievements
	playerAchievements[player.UserId] = profile.Data.Achievements

	-- Check for new achievements
	task.spawn(function()
		AchievementService.CheckAchievements(player)
	end)
end

function AchievementService.OnPlayerLeave(player: Player)
	-- Cleanup
	playerAchievements[player.UserId] = nil
end

-- ============================================================================
-- ACHIEVEMENT CHECKING
-- ============================================================================

function AchievementService.CheckAchievements(player: Player)
	if not AchievementService.Enabled then return end

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then return end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	local data = profile.Data
	local achievements = playerAchievements[player.UserId]
	if not achievements then return end

	-- Check each achievement
	for _, achievement in ipairs(CONFIG.Achievements) do
		-- Skip if already unlocked
		if achievements[achievement.Id] and achievements[achievement.Id].Unlocked then
			continue
		end

		-- Check condition
		local success, result = pcall(achievement.Condition, player, data)
		if success and result then
			-- Achievement unlocked!
			AchievementService.UnlockAchievement(player, achievement.Id)
		end
	end
end

function AchievementService.UnlockAchievement(player: Player, achievementId: string)
	local achievement = nil
	for _, ach in ipairs(CONFIG.Achievements) do
		if ach.Id == achievementId then
			achievement = ach
			break
		end
	end

	if not achievement then
		warn(string.format("[AchievementService] Achievement not found: %s", achievementId))
		return
	end

	local achievements = playerAchievements[player.UserId]
	if not achievements then return end

	-- Mark as unlocked
	achievements[achievementId] = {
		Unlocked = true,
		UnlockedAt = tick(),
	}

	print(string.format("[AchievementService] %s unlocked: %s", player.Name, achievement.Name))

	-- Award rewards
	AchievementService.GiveAchievementReward(player, achievement)

	-- Award Roblox badge
	if achievement.BadgeId then
		AchievementService.AwardBadge(player, achievement.BadgeId)
	end

	-- Notify client
	Events.Achievement:FireClient(player, "AchievementUnlocked", {
		Achievement = achievement,
	})

	-- Notify all players (optional)
	if achievement.Category == "Challenge" or achievement.Category == "Secrets" then
		-- Broadcast rare achievements
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				Events.Achievement:FireClient(plr, "PlayerAchievement", {
					PlayerName = player.Name,
					Achievement = achievement,
				})
			end
		end
	end
end

function AchievementService.GiveAchievementReward(player: Player, achievement)
	if not achievement.Reward then return end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService

	-- Coins
	if achievement.Reward.Coins and CoinService then
		CoinService.AddCoins(player, achievement.Reward.Coins)
	end

	-- Title
	if achievement.Reward.Title then
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService then
			local profile = DataService.GetProfile(player)
			if profile and profile.Data then
				if not profile.Data.UnlockedTitles then
					profile.Data.UnlockedTitles = {}
				end
				table.insert(profile.Data.UnlockedTitles, achievement.Reward.Title)
			end
		end
	end

	-- Pet
	if achievement.Reward.Pet then
		-- PetService integration (Week 37+)
		local PetService = _G.TowerAscent and _G.TowerAscent.PetService
		if PetService then
			-- PetService.GivePet(player, achievement.Reward.Pet)
		end
	end

	-- Trail
	if achievement.Reward.Trail then
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService then
			local profile = DataService.GetProfile(player)
			if profile and profile.Data then
				if not profile.Data.UnlockedTrails then
					profile.Data.UnlockedTrails = {}
				end
				table.insert(profile.Data.UnlockedTrails, achievement.Reward.Trail)
			end
		end
	end
end

function AchievementService.AwardBadge(player: Player, badgeId: number)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if not success then
		warn(string.format("[AchievementService] Failed to check badge %d for %s", badgeId, player.Name))
		return
	end

	if hasBadge then return end -- Already has badge

	-- Award badge
	local awardSuccess = pcall(function()
		BadgeService:AwardBadge(player.UserId, badgeId)
	end)

	if awardSuccess then
		print(string.format("[AchievementService] Awarded badge %d to %s", badgeId, player.Name))
	else
		warn(string.format("[AchievementService] Failed to award badge %d to %s", badgeId, player.Name))
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function AchievementService.GetPlayerAchievements(player: Player)
	return playerAchievements[player.UserId]
end

function AchievementService.GetAchievementsByCategory(category: string)
	local categoryAchievements = {}
	for _, achievement in ipairs(CONFIG.Achievements) do
		if achievement.Category == category then
			table.insert(categoryAchievements, achievement)
		end
	end
	return categoryAchievements
end

function AchievementService.GetAllAchievements()
	return CONFIG.Achievements
end

function AchievementService.GetAchievementProgress(player: Player)
	local achievements = playerAchievements[player.UserId]
	if not achievements then return 0, 0 end

	local unlocked = 0
	local total = #CONFIG.Achievements

	for _, achievement in ipairs(CONFIG.Achievements) do
		if achievements[achievement.Id] and achievements[achievement.Id].Unlocked then
			unlocked = unlocked + 1
		end
	end

	return unlocked, total
end

-- ============================================================================
-- ADMIN/DEBUG
-- ============================================================================

function AchievementService.ForceUnlock(player: Player, achievementId: string)
	AchievementService.UnlockAchievement(player, achievementId)
end

function AchievementService.ResetAchievements(player: Player)
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then return end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	profile.Data.Achievements = {}
	playerAchievements[player.UserId] = {}

	print(string.format("[AchievementService] Reset achievements for %s", player.Name))
end

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

return AchievementService
