--[[
	AchievementService.lua
	Tracks and awards achievements for player accomplishments

	Features:
	- Multiple achievement categories
	- Progress tracking for incremental achievements
	- Reward XP and cosmetic unlocks
	- Achievement notifications
	- Statistics tracking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AchievementService = {}

-- ============================================================================
-- ACHIEVEMENT DEFINITIONS
-- ============================================================================

AchievementService.Achievements = {
	-- Progression Achievements
	first_finish = {
		id = "first_finish",
		name = "First Steps",
		description = "Complete your first race",
		icon = "finish",
		category = "Progression",
		rewardXP = 50,
		hidden = false,
	},
	complete_all_dimensions = {
		id = "complete_all_dimensions",
		name = "Dimension Master",
		description = "Complete a race in every dimension",
		icon = "dimensions",
		category = "Progression",
		rewardXP = 500,
		hidden = false,
		requirement = { type = "collection", dimensions = {"Gravity", "Tiny", "Void", "Sky"} },
	},
	reach_level_10 = {
		id = "reach_level_10",
		name = "Rising Star",
		description = "Reach level 10",
		icon = "star",
		category = "Progression",
		rewardXP = 200,
		hidden = false,
	},
	reach_level_50 = {
		id = "reach_level_50",
		name = "Veteran Hopper",
		description = "Reach level 50",
		icon = "star_gold",
		category = "Progression",
		rewardXP = 1000,
		hidden = false,
	},

	-- Race Achievements
	first_place = {
		id = "first_place",
		name = "Champion",
		description = "Win a multiplayer race",
		icon = "trophy",
		category = "Racing",
		rewardXP = 100,
		hidden = false,
	},
	win_streak_3 = {
		id = "win_streak_3",
		name = "Hot Streak",
		description = "Win 3 races in a row",
		icon = "fire",
		category = "Racing",
		rewardXP = 200,
		hidden = false,
	},
	win_streak_10 = {
		id = "win_streak_10",
		name = "Unstoppable",
		description = "Win 10 races in a row",
		icon = "fire_gold",
		category = "Racing",
		rewardXP = 500,
		hidden = false,
	},
	races_10 = {
		id = "races_10",
		name = "Regular Racer",
		description = "Complete 10 races",
		icon = "race",
		category = "Racing",
		rewardXP = 100,
		hidden = false,
		requirement = { type = "count", stat = "races_completed", target = 10 },
	},
	races_100 = {
		id = "races_100",
		name = "Marathon Runner",
		description = "Complete 100 races",
		icon = "race_gold",
		category = "Racing",
		rewardXP = 500,
		hidden = false,
		requirement = { type = "count", stat = "races_completed", target = 100 },
	},

	-- Dimension-Specific Achievements
	gravity_master = {
		id = "gravity_master",
		name = "Gravity Defier",
		description = "Flip gravity 100 times",
		icon = "gravity",
		category = "Gravity",
		rewardXP = 150,
		hidden = false,
		requirement = { type = "count", stat = "gravity_flips", target = 100 },
	},
	gravity_no_fall = {
		id = "gravity_no_fall",
		name = "Perfect Orientation",
		description = "Complete Gravity dimension without falling",
		icon = "gravity_gold",
		category = "Gravity",
		rewardXP = 300,
		hidden = false,
	},
	tiny_speed_run = {
		id = "tiny_speed_run",
		name = "Small but Fast",
		description = "Complete Tiny dimension in under 2 minutes",
		icon = "tiny",
		category = "Tiny",
		rewardXP = 200,
		hidden = false,
	},
	void_escape = {
		id = "void_escape",
		name = "Void Survivor",
		description = "Escape the void 50 times",
		icon = "void",
		category = "Void",
		rewardXP = 150,
		hidden = false,
		requirement = { type = "count", stat = "void_escapes", target = 50 },
	},
	void_close_call = {
		id = "void_close_call",
		name = "Too Close!",
		description = "Finish with the void less than 5 studs behind you",
		icon = "void_gold",
		category = "Void",
		rewardXP = 250,
		hidden = true,
	},
	sky_glide_distance = {
		id = "sky_glide_distance",
		name = "Frequent Flyer",
		description = "Glide a total of 10,000 studs",
		icon = "sky",
		category = "Sky",
		rewardXP = 150,
		hidden = false,
		requirement = { type = "count", stat = "glide_distance", target = 10000 },
	},
	sky_no_land = {
		id = "sky_no_land",
		name = "Airborne",
		description = "Complete Sky dimension touching only 3 platforms",
		icon = "sky_gold",
		category = "Sky",
		rewardXP = 400,
		hidden = true,
	},

	-- Daily Challenge Achievements
	daily_first = {
		id = "daily_first",
		name = "Daily Competitor",
		description = "Complete your first daily challenge",
		icon = "daily",
		category = "Daily",
		rewardXP = 75,
		hidden = false,
	},
	daily_streak_7 = {
		id = "daily_streak_7",
		name = "Week Warrior",
		description = "Complete daily challenges 7 days in a row",
		icon = "calendar",
		category = "Daily",
		rewardXP = 300,
		hidden = false,
	},
	daily_streak_30 = {
		id = "daily_streak_30",
		name = "Dedicated",
		description = "Complete daily challenges 30 days in a row",
		icon = "calendar_gold",
		category = "Daily",
		rewardXP = 1000,
		rewardCosmetic = "dedicated_trail",
		hidden = false,
	},
	daily_top_10 = {
		id = "daily_top_10",
		name = "Leaderboard",
		description = "Place in the top 10 on a daily challenge",
		icon = "leaderboard",
		category = "Daily",
		rewardXP = 200,
		hidden = false,
	},
	daily_first_place = {
		id = "daily_first_place",
		name = "Daily Champion",
		description = "Get first place on a daily challenge",
		icon = "crown",
		category = "Daily",
		rewardXP = 500,
		hidden = false,
	},

	-- Secret/Hidden Achievements
	secret_area = {
		id = "secret_area",
		name = "Explorer",
		description = "Find a secret area",
		icon = "secret",
		category = "Secret",
		rewardXP = 100,
		hidden = true,
	},
	all_fragments = {
		id = "all_fragments",
		name = "Collector",
		description = "Collect all fragments in a single race",
		icon = "fragment",
		category = "Secret",
		rewardXP = 250,
		hidden = true,
	},
	marathon_complete = {
		id = "marathon_complete",
		name = "Marathon Finisher",
		description = "Complete a marathon (all 4 dimensions in one run)",
		icon = "marathon",
		category = "Special",
		rewardXP = 750,
		hidden = false,
	},
	marathon_first = {
		id = "marathon_first",
		name = "Marathon Champion",
		description = "Win a marathon race",
		icon = "marathon_gold",
		category = "Special",
		rewardXP = 1500,
		hidden = false,
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { unlockedAchievements = {}, progress = {}, stats = {} }
AchievementService.PlayerData = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function AchievementService.Init()
	print("[AchievementService] Initializing...")

	AchievementService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		AchievementService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		AchievementService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		AchievementService.OnPlayerJoin(player)
	end

	print("[AchievementService] Initialized with", AchievementService.GetAchievementCount(), "achievements")
end

function AchievementService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Achievement unlocked notification
	if not remoteFolder:FindFirstChild("AchievementUnlocked") then
		local event = Instance.new("RemoteEvent")
		event.Name = "AchievementUnlocked"
		event.Parent = remoteFolder
	end

	-- Get achievements
	if not remoteFolder:FindFirstChild("GetAchievements") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetAchievements"
		func.Parent = remoteFolder
	end

	-- Progress update
	if not remoteFolder:FindFirstChild("AchievementProgress") then
		local event = Instance.new("RemoteEvent")
		event.Name = "AchievementProgress"
		event.Parent = remoteFolder
	end

	AchievementService.Remotes = {
		AchievementUnlocked = remoteFolder.AchievementUnlocked,
		GetAchievements = remoteFolder.GetAchievements,
		AchievementProgress = remoteFolder.AchievementProgress,
	}

	-- Connect handlers
	AchievementService.Remotes.GetAchievements.OnServerInvoke = function(player)
		return AchievementService.GetPlayerAchievements(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function AchievementService.OnPlayerJoin(player: Player)
	AchievementService.PlayerData[player.UserId] = {
		unlockedAchievements = {},
		progress = {},
		stats = {
			races_completed = 0,
			races_won = 0,
			win_streak = 0,
			gravity_flips = 0,
			void_escapes = 0,
			glide_distance = 0,
			daily_streak = 0,
			dimensions_completed = {},
		},
	}

	AchievementService.LoadPlayerData(player)
end

function AchievementService.OnPlayerLeave(player: Player)
	AchievementService.SavePlayerData(player)
	AchievementService.PlayerData[player.UserId] = nil
end

function AchievementService.LoadPlayerData(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data then
		local playerData = AchievementService.PlayerData[player.UserId]
		if playerData then
			if data.Achievements then
				playerData.unlockedAchievements = data.Achievements
			end
			if data.AchievementProgress then
				playerData.progress = data.AchievementProgress
			end
			if data.Stats then
				for key, value in pairs(data.Stats) do
					playerData.stats[key] = value
				end
			end
		end
	end
end

function AchievementService.SavePlayerData(player: Player)
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			Achievements = playerData.unlockedAchievements,
			AchievementProgress = playerData.progress,
			Stats = playerData.stats,
		})
	end
end

-- ============================================================================
-- ACHIEVEMENT UNLOCKING
-- ============================================================================

function AchievementService.UnlockAchievement(player: Player, achievementId: string): boolean
	local achievement = AchievementService.Achievements[achievementId]
	if not achievement then
		warn("[AchievementService] Unknown achievement: " .. achievementId)
		return false
	end

	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return false end

	-- Already unlocked?
	if playerData.unlockedAchievements[achievementId] then
		return false
	end

	-- Unlock it
	playerData.unlockedAchievements[achievementId] = {
		unlockedAt = os.time(),
	}

	-- Award XP
	if achievement.rewardXP then
		local DimensionHopper = _G.DimensionHopper
		if DimensionHopper then
			local DataService = DimensionHopper.GetService("DataService")
			if DataService and DataService.AddXP then
				DataService.AddXP(player, achievement.rewardXP)
			end
		end
	end

	-- Award cosmetic
	if achievement.rewardCosmetic then
		local DimensionHopper = _G.DimensionHopper
		if DimensionHopper then
			local CosmeticsService = DimensionHopper.GetService("CosmeticsService")
			if CosmeticsService and CosmeticsService.UnlockCosmetic then
				CosmeticsService.UnlockCosmetic(player, achievement.rewardCosmetic)
			end
		end
	end

	-- Notify client
	AchievementService.Remotes.AchievementUnlocked:FireClient(player, {
		achievement = achievement,
		rewardXP = achievement.rewardXP,
		rewardCosmetic = achievement.rewardCosmetic,
	})

	print(string.format("[AchievementService] %s unlocked: %s", player.Name, achievement.name))

	return true
end

-- ============================================================================
-- STAT TRACKING
-- ============================================================================

function AchievementService.IncrementStat(player: Player, statName: string, amount: number?)
	amount = amount or 1

	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return end

	playerData.stats[statName] = (playerData.stats[statName] or 0) + amount

	-- Check for stat-based achievements
	AchievementService.CheckStatAchievements(player, statName, playerData.stats[statName])
end

function AchievementService.SetStat(player: Player, statName: string, value: any)
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return end

	playerData.stats[statName] = value

	-- Check for stat-based achievements if numeric
	if type(value) == "number" then
		AchievementService.CheckStatAchievements(player, statName, value)
	end
end

function AchievementService.GetStat(player: Player, statName: string): any
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return nil end
	return playerData.stats[statName]
end

function AchievementService.CheckStatAchievements(player: Player, statName: string, value: number)
	for id, achievement in pairs(AchievementService.Achievements) do
		if achievement.requirement and achievement.requirement.type == "count" then
			if achievement.requirement.stat == statName then
				if value >= achievement.requirement.target then
					AchievementService.UnlockAchievement(player, id)
				else
					-- Update progress
					AchievementService.UpdateProgress(player, id, value, achievement.requirement.target)
				end
			end
		end
	end
end

function AchievementService.UpdateProgress(player: Player, achievementId: string, current: number, target: number)
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return end

	-- Already unlocked?
	if playerData.unlockedAchievements[achievementId] then return end

	local oldProgress = playerData.progress[achievementId] or 0
	local newProgress = math.min(current, target)

	-- Only update if progress increased
	if newProgress > oldProgress then
		playerData.progress[achievementId] = newProgress

		-- Notify client of progress
		AchievementService.Remotes.AchievementProgress:FireClient(player, {
			achievementId = achievementId,
			current = newProgress,
			target = target,
		})
	end
end

-- ============================================================================
-- EVENT HANDLERS (called by other services)
-- ============================================================================

function AchievementService.OnRaceComplete(player: Player, placement: number, dimension: string, time: number)
	AchievementService.IncrementStat(player, "races_completed")

	-- First finish
	if AchievementService.GetStat(player, "races_completed") == 1 then
		AchievementService.UnlockAchievement(player, "first_finish")
	end

	-- Track dimension completion
	local playerData = AchievementService.PlayerData[player.UserId]
	if playerData then
		playerData.stats.dimensions_completed[dimension] = true

		-- Check if all dimensions completed
		local allComplete = true
		for _, dim in ipairs({"Gravity", "Tiny", "Void", "Sky"}) do
			if not playerData.stats.dimensions_completed[dim] then
				allComplete = false
				break
			end
		end
		if allComplete then
			AchievementService.UnlockAchievement(player, "complete_all_dimensions")
		end
	end

	-- Win tracking
	if placement == 1 then
		AchievementService.IncrementStat(player, "races_won")
		AchievementService.UnlockAchievement(player, "first_place")

		local winStreak = (AchievementService.GetStat(player, "win_streak") or 0) + 1
		AchievementService.SetStat(player, "win_streak", winStreak)

		if winStreak >= 3 then
			AchievementService.UnlockAchievement(player, "win_streak_3")
		end
		if winStreak >= 10 then
			AchievementService.UnlockAchievement(player, "win_streak_10")
		end
	else
		AchievementService.SetStat(player, "win_streak", 0)
	end

	-- Dimension-specific time achievements
	if dimension == "Tiny" and time < 120 then
		AchievementService.UnlockAchievement(player, "tiny_speed_run")
	end
end

function AchievementService.OnGravityFlip(player: Player)
	AchievementService.IncrementStat(player, "gravity_flips")
end

function AchievementService.OnVoidEscape(player: Player)
	AchievementService.IncrementStat(player, "void_escapes")
end

function AchievementService.OnGlide(player: Player, distance: number)
	AchievementService.IncrementStat(player, "glide_distance", distance)
end

function AchievementService.OnDailyComplete(player: Player, placement: number)
	AchievementService.IncrementStat(player, "daily_completions")

	if AchievementService.GetStat(player, "daily_completions") == 1 then
		AchievementService.UnlockAchievement(player, "daily_first")
	end

	if placement == 1 then
		AchievementService.UnlockAchievement(player, "daily_first_place")
	elseif placement <= 10 then
		AchievementService.UnlockAchievement(player, "daily_top_10")
	end
end

function AchievementService.OnMarathonComplete(player: Player, placement: number)
	AchievementService.UnlockAchievement(player, "marathon_complete")

	if placement == 1 then
		AchievementService.UnlockAchievement(player, "marathon_first")
	end
end

function AchievementService.OnLevelUp(player: Player, newLevel: number)
	if newLevel >= 10 then
		AchievementService.UnlockAchievement(player, "reach_level_10")
	end
	if newLevel >= 50 then
		AchievementService.UnlockAchievement(player, "reach_level_50")
	end
end

-- ============================================================================
-- API
-- ============================================================================

function AchievementService.GetPlayerAchievements(player: Player): table
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return {} end

	local result = {
		unlocked = {},
		locked = {},
		progress = playerData.progress,
	}

	for id, achievement in pairs(AchievementService.Achievements) do
		local isUnlocked = playerData.unlockedAchievements[id] ~= nil

		local achievementData = {
			id = id,
			name = achievement.name,
			description = achievement.description,
			icon = achievement.icon,
			category = achievement.category,
			rewardXP = achievement.rewardXP,
			hidden = achievement.hidden,
			unlocked = isUnlocked,
		}

		if isUnlocked then
			achievementData.unlockedAt = playerData.unlockedAchievements[id].unlockedAt
			table.insert(result.unlocked, achievementData)
		else
			-- For hidden achievements, only show if there's progress
			if achievement.hidden and not playerData.progress[id] then
				achievementData.name = "???"
				achievementData.description = "Hidden achievement"
			end
			table.insert(result.locked, achievementData)
		end
	end

	return result
end

function AchievementService.HasAchievement(player: Player, achievementId: string): boolean
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return false end
	return playerData.unlockedAchievements[achievementId] ~= nil
end

function AchievementService.GetAchievementCount(): number
	local count = 0
	for _ in pairs(AchievementService.Achievements) do
		count = count + 1
	end
	return count
end

function AchievementService.GetPlayerUnlockedCount(player: Player): number
	local playerData = AchievementService.PlayerData[player.UserId]
	if not playerData then return 0 end

	local count = 0
	for _ in pairs(playerData.unlockedAchievements) do
		count = count + 1
	end
	return count
end

return AchievementService
