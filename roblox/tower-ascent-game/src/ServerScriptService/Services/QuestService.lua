--[[
	QuestService.lua
	Daily and weekly quest/challenge system for player engagement

	Features:
	- Daily quests (3 quests, easier difficulty, reset at midnight UTC)
	- Weekly quests (3 quests, harder difficulty, reset on Monday)
	- Quest types: CollectCoins, ReachStage, CompleteTower, DefeatHazards, PlayRounds
	- Progress tracking and reward claiming
	- Integration with other services
	- Auto-refresh on login

	Created: Week 15-20 - Retention & Engagement
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestService = {}
QuestService.Enabled = true

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Daily quest configuration
	Daily = {
		QuestCount = 3,
		ResetTimeUTC = 0, -- Midnight UTC (0 hours)

		-- Reward ranges
		MinCoins = 500,
		MaxCoins = 1000,
		MinXP = 100,
		MaxXP = 200,

		-- Target ranges (easier)
		CollectCoinsRange = {50, 200},
		ReachStageRange = {5, 15},
		DefeatHazardsRange = {3, 8},
		PlayRoundsRange = {1, 3},
		SurviveStreakRange = {3, 7}, -- Survive 3-7 sections without dying
		SpeedRunStageRange = {5, 15}, -- Which stage to speed run
		SpeedRunTimeRange = {30, 60}, -- Complete in 30-60 seconds
	},

	-- Weekly quest configuration
	Weekly = {
		QuestCount = 3,
		ResetDayOfWeek = 2, -- Monday (1 = Sunday, 2 = Monday, etc.)
		ResetTimeUTC = 0, -- Midnight UTC

		-- Reward ranges
		MinCoins = 2000,
		MaxCoins = 5000,
		MinXP = 500,
		MaxXP = 1000,

		-- Target ranges (harder)
		CollectCoinsRange = {500, 1500},
		ReachStageRange = {20, 40},
		CompleteTowerRange = {1, 3},
		DefeatHazardsRange = {15, 30},
		PlayRoundsRange = {5, 10},
		SurviveStreakRange = {10, 20}, -- Survive 10-20 sections without dying
		SpeedRunStageRange = {15, 30}, -- Which stage to speed run
		SpeedRunTimeRange = {20, 45}, -- Complete in 20-45 seconds

		-- Cosmetic rewards (pool)
		CosmeticRewards = {
			"QuestTrail_Weekly1",
			"QuestTitle_Challenger",
			"QuestPet_Rare1",
			"QuestEmote_Victory",
		},
	},

	-- Quest types with descriptions
	QuestTypes = {
		CollectCoins = {
			Name = "Coin Collector",
			DescriptionTemplate = "Collect %d coins in a single run",
			Icon = "rbxassetid://0",
		},
		ReachStage = {
			Name = "Tower Climber",
			DescriptionTemplate = "Reach stage %d",
			Icon = "rbxassetid://0",
		},
		CompleteTower = {
			Name = "Tower Champion",
			DescriptionTemplate = "Complete %d tower(s)",
			Icon = "rbxassetid://0",
		},
		DefeatHazards = {
			Name = "Hazard Survivor",
			DescriptionTemplate = "Survive %d hazards",
			Icon = "rbxassetid://0",
		},
		PlayRounds = {
			Name = "Dedicated Player",
			DescriptionTemplate = "Play %d round(s)",
			Icon = "rbxassetid://0",
		},
		SurviveStreak = {
			Name = "Streak Master",
			DescriptionTemplate = "Survive %d sections without dying",
			Icon = "rbxassetid://0",
		},
		SpeedRun = {
			Name = "Speed Demon",
			DescriptionTemplate = "Complete section %d in under %d seconds",
			Icon = "rbxassetid://0",
		},
	},
}

-- Player quest data
local playerQuests = {} -- [userId] = {Daily = {}, Weekly = {}, LastRefresh = {}}

-- Remote events
local Events = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function QuestService.Init()
	print("[QuestService] Initializing...")

	-- Create remote events
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local questEvent = eventsFolder:FindFirstChild("QuestEvent")
	if not questEvent then
		questEvent = Instance.new("RemoteEvent")
		questEvent.Name = "QuestEvent"
		questEvent.Parent = eventsFolder
	end

	Events = {
		Quest = questEvent,
	}

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		QuestService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		QuestService.OnPlayerLeave(player)
	end)

	-- Connect remote events
	Events.Quest.OnServerEvent:Connect(function(player, action, ...)
		-- SECURITY: Validate action is a string
		if type(action) ~= "string" then return end

		if action == "GetQuests" then
			QuestService.SendQuestsToClient(player)
		elseif action == "ClaimReward" then
			local questId = ...
			-- SECURITY: Validate questId type and length
			if type(questId) ~= "string" or #questId > 50 then return end
			QuestService.ClaimQuestReward(player, questId)
		elseif action == "RefreshQuests" then
			QuestService.RefreshPlayerQuests(player)
		end
	end)

	-- Start daily refresh check
	QuestService.StartRefreshTimer()

	print("[QuestService] Initialized successfully")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function QuestService.OnPlayerJoin(player: Player)
	if not QuestService.Enabled then return end

	-- Load quest data from DataService
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		warn("[QuestService] DataService not available")
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	-- Initialize quest data if not exists
	if not profile.Data.Quests then
		profile.Data.Quests = {
			Daily = {},
			Weekly = {},
			LastRefresh = {
				Daily = 0,
				Weekly = 0,
			},
			Stats = {
				DailyCompleted = 0,
				WeeklyCompleted = 0,
				TotalQuestsCompleted = 0,
			},
		}
	end

	-- Cache data
	playerQuests[player.UserId] = profile.Data.Quests

	-- Refresh quests if needed
	task.defer(function()
		QuestService.RefreshPlayerQuests(player)
	end)
end

function QuestService.OnPlayerLeave(player: Player)
	-- Cleanup
	playerQuests[player.UserId] = nil
end

-- ============================================================================
-- QUEST GENERATION
-- ============================================================================

function QuestService.GenerateDailyQuests(): {any}
	local quests = {}
	local usedTypes = {} -- Prevent duplicate quest types

	for i = 1, CONFIG.Daily.QuestCount do
		local quest = QuestService.GenerateRandomQuest("Daily", usedTypes)
		if quest then
			table.insert(quests, quest)
			usedTypes[quest.QuestType] = true
		end
	end

	return quests
end

function QuestService.GenerateWeeklyQuests(): {any}
	local quests = {}
	local usedTypes = {} -- Prevent duplicate quest types

	for i = 1, CONFIG.Weekly.QuestCount do
		local quest = QuestService.GenerateRandomQuest("Weekly", usedTypes)
		if quest then
			table.insert(quests, quest)
			usedTypes[quest.QuestType] = true
		end
	end

	return quests
end

function QuestService.GenerateRandomQuest(questType: string, usedTypes: {[string]: boolean}): any?
	local config = CONFIG[questType]
	if not config then return nil end

	-- Get available quest types
	local availableTypes = {}
	for typeName, typeData in pairs(CONFIG.QuestTypes) do
		-- Skip if already used
		if not usedTypes[typeName] then
			-- Skip CompleteTower for daily (too hard)
			if questType == "Daily" and typeName == "CompleteTower" then
				continue
			end

			table.insert(availableTypes, typeName)
		end
	end

	if #availableTypes == 0 then
		warn("[QuestService] No available quest types")
		return nil
	end

	-- Pick random quest type
	local randomType = availableTypes[math.random(1, #availableTypes)]
	local typeData = CONFIG.QuestTypes[randomType]

	-- Generate target value based on type
	local target = 0
	local targetStage = nil -- For SpeedRun quests
	local targetTime = nil -- For SpeedRun quests

	if randomType == "CollectCoins" then
		local range = config.CollectCoinsRange
		target = math.random(range[1], range[2])
	elseif randomType == "ReachStage" then
		local range = config.ReachStageRange
		target = math.random(range[1], range[2])
	elseif randomType == "CompleteTower" then
		local range = config.CompleteTowerRange
		target = math.random(range[1], range[2])
	elseif randomType == "DefeatHazards" then
		local range = config.DefeatHazardsRange
		target = math.random(range[1], range[2])
	elseif randomType == "PlayRounds" then
		local range = config.PlayRoundsRange
		target = math.random(range[1], range[2])
	elseif randomType == "SurviveStreak" then
		local range = config.SurviveStreakRange
		target = math.random(range[1], range[2])
	elseif randomType == "SpeedRun" then
		local stageRange = config.SpeedRunStageRange
		local timeRange = config.SpeedRunTimeRange
		targetStage = math.random(stageRange[1], stageRange[2])
		targetTime = math.random(timeRange[1], timeRange[2])
		target = targetTime -- Store time as primary target
	end

	-- Generate reward
	local reward = QuestService.GenerateReward(questType, randomType)

	-- Create quest with dynamic description
	local description = ""
	if randomType == "SpeedRun" then
		description = string.format(typeData.DescriptionTemplate, targetStage, targetTime)
	else
		description = string.format(typeData.DescriptionTemplate, target)
	end

	local quest = {
		Id = QuestService.GenerateQuestId(),
		Type = questType, -- "Daily" or "Weekly"
		QuestType = randomType, -- "CollectCoins", "ReachStage", etc.
		Description = description,
		Target = target,
		TargetStage = targetStage, -- For SpeedRun quests
		Progress = 0,
		Completed = false,
		Claimed = false,
		Reward = reward,
		CreatedAt = os.time(),
	}

	return quest
end

function QuestService.GenerateReward(questType: string, randomType: string): {Coins: number, XP: number, Items: {any}?}
	local config = CONFIG[questType]

	-- Generate coin reward
	local coins = math.random(config.MinCoins, config.MaxCoins)

	-- Generate XP reward
	local xp = math.random(config.MinXP, config.MaxXP)

	-- Weekly quests can have cosmetic rewards
	local items = nil
	if questType == "Weekly" and math.random() < 0.5 then -- 50% chance for cosmetic
		local cosmeticPool = CONFIG.Weekly.CosmeticRewards
		local randomCosmetic = cosmeticPool[math.random(1, #cosmeticPool)]
		items = {randomCosmetic}
	end

	return {
		Coins = coins,
		XP = xp,
		Items = items,
	}
end

function QuestService.GenerateQuestId(): string
	return string.format("Quest_%d_%d", os.time(), math.random(1000, 9999))
end

-- ============================================================================
-- QUEST REFRESH
-- ============================================================================

function QuestService.ShouldRefreshDaily(lastRefresh: number): boolean
	local now = os.time()
	local lastRefreshDate = os.date("!*t", lastRefresh)
	local nowDate = os.date("!*t", now)

	-- Check if a day has passed
	if nowDate.year > lastRefreshDate.year or
	   nowDate.yday > lastRefreshDate.yday then
		return true
	end

	return false
end

function QuestService.ShouldRefreshWeekly(lastRefresh: number): boolean
	local now = os.time()
	local lastRefreshDate = os.date("!*t", lastRefresh)
	local nowDate = os.date("!*t", now)

	-- Check if we've crossed Monday midnight UTC
	local lastWeekStart = QuestService.GetWeekStart(lastRefresh)
	local currentWeekStart = QuestService.GetWeekStart(now)

	return currentWeekStart > lastWeekStart
end

function QuestService.GetWeekStart(timestamp: number): number
	local date = os.date("!*t", timestamp)

	-- Calculate days since Monday (wday: 1=Sunday, 2=Monday, etc.)
	local daysSinceMonday = (date.wday - 2) % 7

	-- Go back to Monday midnight
	local mondayMidnight = timestamp - (daysSinceMonday * 86400) - (date.hour * 3600) - (date.min * 60) - date.sec

	return mondayMidnight
end

function QuestService.RefreshPlayerQuests(player: Player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local refreshed = false

	-- Check if daily quests need refresh
	if QuestService.ShouldRefreshDaily(questData.LastRefresh.Daily) then
		questData.Daily = QuestService.GenerateDailyQuests()
		questData.LastRefresh.Daily = os.time()
		refreshed = true

		print(string.format("[QuestService] Generated new daily quests for %s", player.Name))
	end

	-- Check if weekly quests need refresh
	if QuestService.ShouldRefreshWeekly(questData.LastRefresh.Weekly) then
		questData.Weekly = QuestService.GenerateWeeklyQuests()
		questData.LastRefresh.Weekly = os.time()
		refreshed = true

		print(string.format("[QuestService] Generated new weekly quests for %s", player.Name))
	end

	-- Generate initial quests if player has none
	if #questData.Daily == 0 then
		questData.Daily = QuestService.GenerateDailyQuests()
		questData.LastRefresh.Daily = os.time()
		refreshed = true
	end

	if #questData.Weekly == 0 then
		questData.Weekly = QuestService.GenerateWeeklyQuests()
		questData.LastRefresh.Weekly = os.time()
		refreshed = true
	end

	-- Send updated quests to client
	if refreshed then
		QuestService.SendQuestsToClient(player)
	end
end

function QuestService.StartRefreshTimer()
	-- Check for quest refreshes every 5 minutes
	task.spawn(function()
		while true do
			task.wait(300) -- 5 minutes

			for userId, questData in pairs(playerQuests) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					QuestService.RefreshPlayerQuests(player)
				end
			end
		end
	end)
end

-- ============================================================================
-- QUEST PROGRESS TRACKING
-- ============================================================================

function QuestService.CheckQuestProgress(player: Player, questType: string, amount: number)
	if not QuestService.Enabled then return end

	local questData = playerQuests[player.UserId]
	if not questData then return end

	-- Check both daily and weekly quests
	local updated = false

	for _, quest in ipairs(questData.Daily) do
		if quest.QuestType == questType and not quest.Completed then
			quest.Progress = math.min(quest.Progress + amount, quest.Target)

			if quest.Progress >= quest.Target then
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Daily")
			end

			updated = true
		end
	end

	for _, quest in ipairs(questData.Weekly) do
		if quest.QuestType == questType and not quest.Completed then
			quest.Progress = math.min(quest.Progress + amount, quest.Target)

			if quest.Progress >= quest.Target then
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Weekly")
			end

			updated = true
		end
	end

	-- Send update to client
	if updated then
		QuestService.SendQuestsToClient(player)
	end
end

function QuestService.OnQuestCompleted(player: Player, quest: any, questType: string)
	print(string.format(
		"[QuestService] %s completed %s quest: %s",
		player.Name,
		questType,
		quest.Description
	))

	-- Notify client
	Events.Quest:FireClient(player, "QuestCompleted", {
		Quest = quest,
		Type = questType,
	})
end

-- ============================================================================
-- REWARD CLAIMING
-- ============================================================================

function QuestService.ClaimQuestReward(player: Player, questId: string)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	-- Find quest in daily or weekly
	local quest = nil
	local questType = nil

	for _, q in ipairs(questData.Daily) do
		if q.Id == questId then
			quest = q
			questType = "Daily"
			break
		end
	end

	if not quest then
		for _, q in ipairs(questData.Weekly) do
			if q.Id == questId then
				quest = q
				questType = "Weekly"
				break
			end
		end
	end

	if not quest then
		warn(string.format("[QuestService] Quest not found: %s", questId))
		return
	end

	-- Validate quest state
	if not quest.Completed then
		Events.Quest:FireClient(player, "ClaimFailed", {
			Reason = "NotCompleted",
			QuestId = questId,
		})
		return
	end

	if quest.Claimed then
		Events.Quest:FireClient(player, "ClaimFailed", {
			Reason = "AlreadyClaimed",
			QuestId = questId,
		})
		return
	end

	-- Award rewards
	QuestService.GiveQuestReward(player, quest)

	-- Mark as claimed
	quest.Claimed = true

	-- Update stats
	questData.Stats.TotalQuestsCompleted = questData.Stats.TotalQuestsCompleted + 1
	if questType == "Daily" then
		questData.Stats.DailyCompleted = questData.Stats.DailyCompleted + 1
	else
		questData.Stats.WeeklyCompleted = questData.Stats.WeeklyCompleted + 1
	end

	-- Notify client
	Events.Quest:FireClient(player, "RewardClaimed", {
		Quest = quest,
		Type = questType,
	})

	print(string.format(
		"[QuestService] %s claimed %s quest reward: %d coins, %d XP",
		player.Name,
		questType,
		quest.Reward.Coins,
		quest.Reward.XP
	))

	-- Send updated quests
	QuestService.SendQuestsToClient(player)
end

function QuestService.GiveQuestReward(player: Player, quest: any)
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	local BattlePassService = _G.TowerAscent and _G.TowerAscent.BattlePassService
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService

	-- Give coins
	if quest.Reward.Coins and CoinService then
		CoinService.AddCoins(player, quest.Reward.Coins, "Quest")
	end

	-- Give XP
	if quest.Reward.XP and BattlePassService then
		BattlePassService.AddXP(player, quest.Reward.XP)
	end

	-- Give items (cosmetics)
	if quest.Reward.Items and DataService then
		local profile = DataService.GetProfile(player)
		if profile and profile.Data then
			if not profile.Data.UnlockedCosmetics then
				profile.Data.UnlockedCosmetics = {}
			end

			for _, item in ipairs(quest.Reward.Items) do
				table.insert(profile.Data.UnlockedCosmetics, item)
			end
		end
	end
end

-- ============================================================================
-- CLIENT COMMUNICATION
-- ============================================================================

function QuestService.SendQuestsToClient(player: Player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	Events.Quest:FireClient(player, "QuestsUpdate", {
		Daily = questData.Daily,
		Weekly = questData.Weekly,
		Stats = questData.Stats,
	})
end

-- ============================================================================
-- PUBLIC API (Integration Points)
-- ============================================================================

-- Called by CoinService when coins are collected in a run
function QuestService.OnCoinsCollected(player: Player, amount: number)
	QuestService.CheckQuestProgress(player, "CollectCoins", amount)
end

-- Called by CheckpointService when player reaches a stage
function QuestService.OnStageReached(player: Player, stage: number)
	-- Update progress for all ReachStage quests that match or are below this stage
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local updated = false

	for _, quest in ipairs(questData.Daily) do
		if quest.QuestType == "ReachStage" and not quest.Completed then
			if stage >= quest.Target then
				quest.Progress = quest.Target
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Daily")
				updated = true
			end
		end
	end

	for _, quest in ipairs(questData.Weekly) do
		if quest.QuestType == "ReachStage" and not quest.Completed then
			if stage >= quest.Target then
				quest.Progress = quest.Target
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Weekly")
				updated = true
			end
		end
	end

	if updated then
		QuestService.SendQuestsToClient(player)
	end
end

-- Called by RoundService when tower is completed
function QuestService.OnTowerCompleted(player: Player)
	QuestService.CheckQuestProgress(player, "CompleteTower", 1)
end

-- Called by HazardService when player survives a hazard
function QuestService.OnHazardDefeated(player: Player)
	QuestService.CheckQuestProgress(player, "DefeatHazards", 1)
end

-- Called by RoundService when player starts/completes a round
function QuestService.OnRoundPlayed(player: Player)
	QuestService.CheckQuestProgress(player, "PlayRounds", 1)
end

-- Called by CheckpointService to track streak progress
function QuestService.OnSectionSurvived(player: Player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local updated = false

	for _, quest in ipairs(questData.Daily) do
		if quest.QuestType == "SurviveStreak" and not quest.Completed then
			quest.Progress = quest.Progress + 1

			if quest.Progress >= quest.Target then
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Daily")
			end

			updated = true
		end
	end

	for _, quest in ipairs(questData.Weekly) do
		if quest.QuestType == "SurviveStreak" and not quest.Completed then
			quest.Progress = quest.Progress + 1

			if quest.Progress >= quest.Target then
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Weekly")
			end

			updated = true
		end
	end

	if updated then
		QuestService.SendQuestsToClient(player)
	end
end

-- Called by CheckpointService when player dies (resets streak)
function QuestService.OnPlayerDied(player: Player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local updated = false

	-- Reset streak progress on death
	for _, quest in ipairs(questData.Daily) do
		if quest.QuestType == "SurviveStreak" and not quest.Completed then
			if quest.Progress > 0 then
				quest.Progress = 0
				updated = true
			end
		end
	end

	for _, quest in ipairs(questData.Weekly) do
		if quest.QuestType == "SurviveStreak" and not quest.Completed then
			if quest.Progress > 0 then
				quest.Progress = 0
				updated = true
			end
		end
	end

	if updated then
		QuestService.SendQuestsToClient(player)
	end
end

-- Called by CheckpointService with completion time for speed run tracking
function QuestService.OnSectionCompleted(player: Player, stage: number, completionTime: number)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local updated = false

	-- Check daily speed run quests
	for _, quest in ipairs(questData.Daily) do
		if quest.QuestType == "SpeedRun" and not quest.Completed then
			-- Check if this is the target stage and time is under target
			if stage == quest.TargetStage and completionTime <= quest.Target then
				quest.Progress = quest.Target
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Daily")
				updated = true
			end
		end
	end

	-- Check weekly speed run quests
	for _, quest in ipairs(questData.Weekly) do
		if quest.QuestType == "SpeedRun" and not quest.Completed then
			-- Check if this is the target stage and time is under target
			if stage == quest.TargetStage and completionTime <= quest.Target then
				quest.Progress = quest.Target
				quest.Completed = true
				QuestService.OnQuestCompleted(player, quest, "Weekly")
				updated = true
			end
		end
	end

	if updated then
		QuestService.SendQuestsToClient(player)
	end
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function QuestService.GetPlayerQuests(player: Player): any?
	return playerQuests[player.UserId]
end

function QuestService.GetQuestById(player: Player, questId: string): any?
	local questData = playerQuests[player.UserId]
	if not questData then return nil end

	-- Search daily quests
	for _, quest in ipairs(questData.Daily) do
		if quest.Id == questId then
			return quest
		end
	end

	-- Search weekly quests
	for _, quest in ipairs(questData.Weekly) do
		if quest.Id == questId then
			return quest
		end
	end

	return nil
end

-- ============================================================================
-- ADMIN/DEBUG
-- ============================================================================

function QuestService.ForceRefreshQuests(player: Player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	questData.Daily = QuestService.GenerateDailyQuests()
	questData.Weekly = QuestService.GenerateWeeklyQuests()
	questData.LastRefresh.Daily = os.time()
	questData.LastRefresh.Weekly = os.time()

	QuestService.SendQuestsToClient(player)

	print(string.format("[QuestService] Force refreshed quests for %s", player.Name))
end

function QuestService.ForceCompleteQuest(player: Player, questId: string)
	local quest = QuestService.GetQuestById(player, questId)
	if not quest then
		warn(string.format("[QuestService] Quest not found: %s", questId))
		return
	end

	quest.Progress = quest.Target
	quest.Completed = true

	QuestService.SendQuestsToClient(player)

	print(string.format("[QuestService] Force completed quest %s for %s", questId, player.Name))
end

function QuestService.ResetQuests(player: Player)
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then return end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	profile.Data.Quests = {
		Daily = {},
		Weekly = {},
		LastRefresh = {
			Daily = 0,
			Weekly = 0,
		},
		Stats = {
			DailyCompleted = 0,
			WeeklyCompleted = 0,
			TotalQuestsCompleted = 0,
		},
	}

	playerQuests[player.UserId] = profile.Data.Quests
	QuestService.RefreshPlayerQuests(player)

	print(string.format("[QuestService] Reset quests for %s", player.Name))
end

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

return QuestService
