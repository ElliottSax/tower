--[[
	QuestService.lua (Adapted for Adventure Story Obby)
	Quest system for story progression and daily challenges

	Features:
	- Story quests (main narrative progression)
	- Daily quests (3 random quests, reset at midnight UTC)
	- Progress tracking per objective
	- Reward claiming
	- Integration with StoryService and DataService
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local QuestDefinitions = require(ReplicatedStorage.Shared.Data.QuestDefinitions)

local QuestService = {}
local DataService = nil -- Lazy loaded

-- Active quest progress (runtime tracking)
-- Format: [Player] = {QuestId = {ObjectiveType = Progress}}
local ActiveQuestProgress = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function QuestService.Init()
	print("[QuestService] Initializing...")

	-- Lazy load DataService
	DataService = require(ServerScriptService.Services.DataService)

	-- Setup remote handlers
	QuestService.SetupRemoteHandlers()

	-- Player management
	Players.PlayerAdded:Connect(function(player)
		QuestService.OnPlayerJoin(player)
	end)

	print("[QuestService] Initialized")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function QuestService.OnPlayerJoin(player: Player)
	-- Initialize quest progress tracking
	ActiveQuestProgress[player] = {}

	-- Refresh daily quests if needed
	task.defer(function()
		QuestService.RefreshDailyQuests(player)
	end)

	-- Auto-start story quests
	task.defer(function()
		QuestService.CheckAutoStartQuests(player)
	end)
end

-- ============================================================================
-- QUEST MANAGEMENT
-- ============================================================================

function QuestService.StartQuest(player: Player, questId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	-- Get quest definition
	local questDef = QuestDefinitions.GetQuest(questId)
	if not questDef then
		warn("[QuestService] Quest not found:", questId)
		return false
	end

	-- Check if already active
	for _, activeQuest in ipairs(profile.Data.Quests.Active) do
		if activeQuest.Id == questId then
			warn("[QuestService] Quest already active:", questId)
			return false
		end
	end

	-- Check if already completed
	if profile.Data.Quests.Completed[questId] then
		-- Allow replaying daily quests, but not story quests
		if questDef.Type == "Story" then
			warn("[QuestService] Story quest already completed:", questId)
			return false
		end
	end

	-- Add to active quests
	table.insert(profile.Data.Quests.Active, {
		Id = questId,
		Type = questDef.Type,
		StartedAt = os.time(),
	})

	-- Initialize progress tracking
	if not profile.Data.Quests.Progress[questId] then
		profile.Data.Quests.Progress[questId] = {}
	end

	-- Initialize progress for each objective
	for i, objective in ipairs(questDef.Objectives) do
		local objectiveKey = string.format("Objective%d", i)
		if not profile.Data.Quests.Progress[questId][objectiveKey] then
			profile.Data.Quests.Progress[questId][objectiveKey] = 0
		end
	end

	-- Initialize active progress
	ActiveQuestProgress[player][questId] = {}

	print(string.format("[QuestService] %s started quest: %s", player.Name, questId))

	-- Notify client
	QuestService.NotifyQuestUpdate(player, questId)

	return true
end

function QuestService.CheckAutoStartQuests(player: Player)
	-- Check for auto-start quests (TutorialComplete)
	local tutorialQuest = QuestDefinitions.GetQuest("TutorialComplete")
	if tutorialQuest and tutorialQuest.AutoStart then
		QuestService.StartQuest(player, "TutorialComplete")
	end
end

-- ============================================================================
-- QUEST PROGRESS
-- ============================================================================

function QuestService.UpdateQuestProgress(player: Player, objectiveType: string, target: string, amount: number)
	local profile = DataService.GetProfile(player)
	if not profile then return end

	-- Check all active quests
	for _, activeQuest in ipairs(profile.Data.Quests.Active) do
		local questDef = QuestDefinitions.GetQuest(activeQuest.Id)
		if not questDef then continue end

		-- Check each objective
		for i, objective in ipairs(questDef.Objectives) do
			-- Match objective type and target
			if objective.Type == objectiveType and (objective.Target == target or objective.Target == "Any") then
				local objectiveKey = string.format("Objective%d", i)

				-- Update progress
				local currentProgress = profile.Data.Quests.Progress[activeQuest.Id][objectiveKey] or 0
				local newProgress = math.min(currentProgress + amount, objective.Count)

				profile.Data.Quests.Progress[activeQuest.Id][objectiveKey] = newProgress

				print(string.format("[QuestService] %s quest %s progress: %s = %d/%d",
					player.Name, activeQuest.Id, objectiveKey, newProgress, objective.Count))

				-- Check if quest is complete
				if QuestService.IsQuestComplete(player, activeQuest.Id) then
					QuestService.OnQuestComplete(player, activeQuest.Id)
				else
					-- Notify client of progress update
					QuestService.NotifyQuestUpdate(player, activeQuest.Id)
				end
			end
		end
	end
end

function QuestService.IsQuestComplete(player: Player, questId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	local questDef = QuestDefinitions.GetQuest(questId)
	if not questDef then return false end

	-- Check all objectives
	for i, objective in ipairs(questDef.Objectives) do
		local objectiveKey = string.format("Objective%d", i)
		local progress = profile.Data.Quests.Progress[questId][objectiveKey] or 0

		if progress < objective.Count then
			return false -- Not all objectives complete
		end
	end

	return true -- All objectives complete
end

function QuestService.OnQuestComplete(player: Player, questId: string)
	print(string.format("[QuestService] %s completed quest: %s", player.Name, questId))

	-- Mark as ready to claim (don't auto-claim to give player control)
	QuestService.NotifyQuestUpdate(player, questId)
end

-- ============================================================================
-- REWARD CLAIMING
-- ============================================================================

function QuestService.ClaimQuestReward(player: Player, questId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	-- Check if quest is complete
	if not QuestService.IsQuestComplete(player, questId) then
		warn("[QuestService] Quest not complete:", questId)
		return false
	end

	-- Get quest definition
	local questDef = QuestDefinitions.GetQuest(questId)
	if not questDef then return false end

	-- Remove from active quests
	for i, activeQuest in ipairs(profile.Data.Quests.Active) do
		if activeQuest.Id == questId then
			table.remove(profile.Data.Quests.Active, i)
			break
		end
	end

	-- Mark as completed
	profile.Data.Quests.Completed[questId] = os.time()

	-- Award rewards
	if questDef.Rewards then
		if questDef.Rewards.Coins then
			DataService.AddCoins(player, questDef.Rewards.Coins)
		end
		-- Experience, titles, etc. can be added here
	end

	print(string.format("[QuestService] %s claimed reward for quest: %s (+%d coins)",
		player.Name, questId, questDef.Rewards.Coins or 0))

	-- Notify client
	QuestService.NotifyQuestUpdate(player, questId)

	-- Check for follow-up quests
	QuestService.CheckQuestChain(player, questDef)

	return true
end

function QuestService.CheckQuestChain(player: Player, completedQuestDef: {})
	-- Check if this quest unlocks another quest
	-- For example, completing ForestTrailQuest unlocks RiverCrossingQuest
	local nextQuestId = nil

	if completedQuestDef.Id == "TutorialComplete" then
		nextQuestId = "ForestTrailQuest"
	elseif completedQuestDef.Id == "ForestTrailQuest" then
		nextQuestId = "RiverCrossingQuest"
	elseif completedQuestDef.Id == "RiverCrossingQuest" then
		nextQuestId = "RuinsQuest"
	elseif completedQuestDef.Id == "RuinsQuest" then
		nextQuestId = "GuardiansGateQuest"
	end

	if nextQuestId then
		-- Auto-start next quest
		QuestService.StartQuest(player, nextQuestId)
	end
end

-- ============================================================================
-- DAILY QUESTS
-- ============================================================================

function QuestService.RefreshDailyQuests(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then return end

	-- Check if daily reset is needed
	local lastReset = profile.Data.Quests.LastDailyReset or 0
	local currentDay = math.floor(os.time() / 86400) -- Days since epoch

	if lastReset >= currentDay then
		-- Already refreshed today
		return
	end

	-- Remove old daily quests from active
	for i = #profile.Data.Quests.Active, 1, -1 do
		local quest = profile.Data.Quests.Active[i]
		if quest.Type == "Daily" then
			table.remove(profile.Data.Quests.Active, i)
		end
	end

	-- Generate new daily quests
	local dailyQuests = QuestDefinitions.GetRandomDailyQuests(3)
	for _, quest in ipairs(dailyQuests) do
		QuestService.StartQuest(player, quest.Id)
	end

	-- Update last reset time
	profile.Data.Quests.LastDailyReset = currentDay

	print(string.format("[QuestService] Refreshed daily quests for %s", player.Name))
end

-- ============================================================================
-- QUEST DATA
-- ============================================================================

function QuestService.GetActiveQuests(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then return {} end

	local activeQuests = {}

	for _, activeQuest in ipairs(profile.Data.Quests.Active) do
		local questDef = QuestDefinitions.GetQuest(activeQuest.Id)
		if questDef then
			table.insert(activeQuests, {
				Id = activeQuest.Id,
				Name = questDef.Name,
				Description = questDef.Description,
				Type = questDef.Type,
				Objectives = questDef.Objectives,
				Progress = profile.Data.Quests.Progress[activeQuest.Id] or {},
				Rewards = questDef.Rewards,
				IsComplete = QuestService.IsQuestComplete(player, activeQuest.Id),
			})
		end
	end

	return activeQuests
end

function QuestService.GetQuestProgress(player: Player, questId: string)
	local profile = DataService.GetProfile(player)
	if not profile then return {} end

	return profile.Data.Quests.Progress[questId] or {}
end

-- ============================================================================
-- CLIENT COMMUNICATION
-- ============================================================================

function QuestService.NotifyQuestUpdate(player: Player, questId: string)
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local questUpdateRemote = RemoteEventsInit.GetRemote("QuestUpdate")

	if questUpdateRemote and questUpdateRemote.Remote then
		questUpdateRemote.Remote:FireClient(player, questId)
	end
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function QuestService.SetupRemoteHandlers()
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

	-- GetActiveQuests
	local getActiveQuestsRemote = RemoteEventsInit.GetRemote("GetActiveQuests")
	if getActiveQuestsRemote and getActiveQuestsRemote.Remote then
		getActiveQuestsRemote.Remote.OnServerInvoke = function(player)
			return QuestService.GetActiveQuests(player)
		end
	end

	-- GetQuestProgress
	local getQuestProgressRemote = RemoteEventsInit.GetRemote("GetQuestProgress")
	if getQuestProgressRemote and getQuestProgressRemote.Remote then
		getQuestProgressRemote.Remote.OnServerInvoke = function(player, questId)
			return QuestService.GetQuestProgress(player, questId)
		end
	end

	-- ClaimQuestReward
	local claimQuestRewardRemote = RemoteEventsInit.GetRemote("ClaimQuestReward")
	if claimQuestRewardRemote and claimQuestRewardRemote.Remote then
		claimQuestRewardRemote.Remote.OnServerInvoke = function(player, questId)
			return QuestService.ClaimQuestReward(player, questId)
		end
	end

	print("[QuestService] Remote handlers setup complete")
end

return QuestService
