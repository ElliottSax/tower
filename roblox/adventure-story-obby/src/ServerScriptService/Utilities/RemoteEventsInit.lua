--[[
	RemoteEventsInit.lua
	Centralized initialization of all RemoteEvents and RemoteFunctions

	MUST RUN FIRST before any other services!

	This ensures:
	- RemoteEvents folder exists before client/server scripts load
	- All remotes are created with proper configuration
	- SecureRemotes wrapper is applied consistently
	- No race conditions during initialization

	Created: 2025-12-17
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SecureRemotes = require(ServerScriptService.Security.SecureRemotes)

local RemoteEventsInit = {}
RemoteEventsInit.Remotes = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RemoteEventsInit.Initialize()
	print("[RemoteEventsInit] Creating RemoteEvents folder...")

	-- Create RemoteEvents folder
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	print("[RemoteEventsInit] Setting up secure remotes...")

	-- ========================================================================
	-- COIN SERVICE REMOTES
	-- ========================================================================

	-- CoinUpdate: Server → Client (notify of coin change)
	local coinUpdateEvent = SecureRemotes.CreateRemoteEvent("CoinUpdate", {
		RequiresAuth = false, -- Server-to-client only
		MaxCallsPerSecond = 20
	})
	RemoteEventsInit.Remotes.CoinUpdate = coinUpdateEvent

	-- GetCoins: Client → Server (query current coins)
	local getCoinFunction = SecureRemotes.CreateRemoteFunction("GetCoins", {
		MaxCallsPerSecond = 5,
		TypeSchema = {}, -- No arguments
		ReturnSchema = "number"
	})
	RemoteEventsInit.Remotes.GetCoins = getCoinFunction

	-- ========================================================================
	-- UPGRADE SERVICE REMOTES
	-- ========================================================================

	-- HasUpgrade: Client → Server (check if player owns upgrade)
	local hasUpgradeFunction = SecureRemotes.CreateRemoteFunction("HasUpgrade", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string"}, -- upgradeName
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.HasUpgrade = hasUpgradeFunction

	-- PurchaseUpgrade: Client → Server (attempt to buy upgrade)
	-- Note: Using RemoteEvent + response pattern for better UX
	local purchaseUpgradeEvent = SecureRemotes.CreateRemoteEvent("PurchaseUpgrade", {
		MaxCallsPerSecond = 2,
		TypeSchema = {"string"} -- upgradeName
	})
	RemoteEventsInit.Remotes.PurchaseUpgrade = purchaseUpgradeEvent

	-- GetUpgradeLevel: Client → Server (get current upgrade level)
	local getUpgradeLevelFunction = SecureRemotes.CreateRemoteFunction("GetUpgradeLevel", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"string"}, -- upgradeName
		ReturnSchema = "number"
	})
	RemoteEventsInit.Remotes.GetUpgradeLevel = getUpgradeLevelFunction

	-- GetAllUpgrades: Client → Server (get all owned upgrades)
	local getAllUpgradesFunction = SecureRemotes.CreateRemoteFunction("GetAllUpgrades", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetAllUpgrades = getAllUpgradesFunction

	-- GetUpgradeCost: Client → Server (get cost for upgrade level)
	local getUpgradeCostFunction = SecureRemotes.CreateRemoteFunction("GetUpgradeCost", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"string", "number?"}, -- upgradeName, level
		ReturnSchema = "number"
	})
	RemoteEventsInit.Remotes.GetUpgradeCost = getUpgradeCostFunction

	-- ========================================================================
	-- THEME SERVICE REMOTES
	-- ========================================================================

	-- ChangeThemeMusic: Server → Client (update background music)
	local changeThemeMusicEvent = SecureRemotes.CreateRemoteEvent("ChangeThemeMusic", {
		RequiresAuth = false, -- Server-to-client only
		MaxCallsPerSecond = 10
	})
	RemoteEventsInit.Remotes.ChangeThemeMusic = changeThemeMusicEvent

	-- ========================================================================
	-- BUG REPORT REMOTES
	-- ========================================================================

	-- ReportBug: Client → Server (submit bug report)
	local reportBugFunction = SecureRemotes.CreateRemoteFunction("ReportBug", {
		MaxCallsPerSecond = 1, -- Prevent spam
		MaxDataSize = 5000, -- Larger for bug descriptions
		TypeSchema = {"string", "string", "table?"}, -- category, description, metadata
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.ReportBug = reportBugFunction

	-- ========================================================================
	-- LEADERBOARD SERVICE REMOTES
	-- ========================================================================

	-- GetLeaderboard: Client → Server (query leaderboard data)
	local getLeaderboardFunction = SecureRemotes.CreateRemoteFunction("GetLeaderboard", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string"}, -- leaderboardType
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetLeaderboard = getLeaderboardFunction

	-- ========================================================================
	-- STATISTICS SERVICE REMOTES
	-- ========================================================================

	-- GetStatistics: Client → Server (query player stats)
	local getStatisticsFunction = SecureRemotes.CreateRemoteFunction("GetStatistics", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetStatistics = getStatisticsFunction

	-- ========================================================================
	-- ADMIN REMOTES
	-- ========================================================================

	-- AdminCommand: Client → Server (execute admin command)
	local adminCommandFunction = SecureRemotes.CreateRemoteFunction("AdminCommand", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string", "table?"}, -- commandName, args
		ReturnSchema = "string" -- Result message
	})
	RemoteEventsInit.Remotes.AdminCommand = adminCommandFunction

	-- ========================================================================
	-- SETTINGS & TUTORIAL REMOTES
	-- ========================================================================

	-- GetSetting: Client → Server (get a player setting)
	local getSettingFunction = SecureRemotes.CreateRemoteFunction("GetSetting", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"string"}, -- settingName
		ReturnSchema = "any"
	})
	RemoteEventsInit.Remotes.GetSetting = getSettingFunction

	-- SetSetting: Client → Server (update a player setting)
	local setSettingFunction = SecureRemotes.CreateRemoteFunction("SetSetting", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string", "any"}, -- settingName, value
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.SetSetting = setSettingFunction

	-- GetTutorialStatus: Client → Server (check if tutorial completed)
	local getTutorialStatusFunction = SecureRemotes.CreateRemoteFunction("GetTutorialStatus", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "table" -- {completed, skipped}
	})
	RemoteEventsInit.Remotes.GetTutorialStatus = getTutorialStatusFunction

	-- SetTutorialComplete: Client → Server (mark tutorial as done)
	local setTutorialCompleteFunction = SecureRemotes.CreateRemoteFunction("SetTutorialComplete", {
		MaxCallsPerSecond = 2,
		TypeSchema = {"boolean"}, -- completed (true) or skipped (false)
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.SetTutorialComplete = setTutorialCompleteFunction

	-- ========================================================================
	-- STORY SERVICE REMOTES (Adventure Story Obby)
	-- ========================================================================

	-- CompleteLevel: Client → Server (mark level as complete)
	local completeLevelFunction = SecureRemotes.CreateRemoteFunction("CompleteLevel", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"number", "number"}, -- worldId, levelId
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.CompleteLevel = completeLevelFunction

	-- GetStoryData: Client → Server (get current story progression)
	local getStoryDataFunction = SecureRemotes.CreateRemoteFunction("GetStoryData", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetStoryData = getStoryDataFunction

	-- GetLevelInfo: Client → Server (get level metadata)
	local getLevelInfoFunction = SecureRemotes.CreateRemoteFunction("GetLevelInfo", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"number", "number"}, -- worldId, levelId
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetLevelInfo = getLevelInfoFunction

	-- IsLevelUnlocked: Client → Server (check if level is accessible)
	local isLevelUnlockedFunction = SecureRemotes.CreateRemoteFunction("IsLevelUnlocked", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"number", "number"}, -- worldId, levelId
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.IsLevelUnlocked = isLevelUnlockedFunction

	-- ========================================================================
	-- DIALOGUE SERVICE REMOTES
	-- ========================================================================

	-- StartDialogue: Client → Server (begin NPC conversation)
	local startDialogueFunction = SecureRemotes.CreateRemoteFunction("StartDialogue", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string"}, -- npcName
		ReturnSchema = "table" -- {NPC, DialogueId, Text, Choices}
	})
	RemoteEventsInit.Remotes.StartDialogue = startDialogueFunction

	-- MakeChoice: Client → Server (select dialogue option)
	local makeChoiceFunction = SecureRemotes.CreateRemoteFunction("MakeChoice", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"number"}, -- choiceIndex
		ReturnSchema = "table" -- Next dialogue or end
	})
	RemoteEventsInit.Remotes.MakeChoice = makeChoiceFunction

	-- EndDialogue: Client → Server (close dialogue)
	local endDialogueEvent = SecureRemotes.CreateRemoteEvent("EndDialogue", {
		MaxCallsPerSecond = 5,
		TypeSchema = {}
	})
	RemoteEventsInit.Remotes.EndDialogue = endDialogueEvent

	-- ========================================================================
	-- NPC SERVICE REMOTES
	-- ========================================================================

	-- NPCInteract: Server → Client (trigger dialogue UI)
	local npcInteractEvent = SecureRemotes.CreateRemoteEvent("NPCInteract", {
		RequiresAuth = false, -- Server-to-client only
		MaxCallsPerSecond = 10
	})
	RemoteEventsInit.Remotes.NPCInteract = npcInteractEvent

	-- ========================================================================
	-- WORLD SERVICE REMOTES
	-- ========================================================================

	-- TeleportToLevel: Client → Server (enter a level)
	local teleportToLevelFunction = SecureRemotes.CreateRemoteFunction("TeleportToLevel", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"number", "number"}, -- worldId, levelId
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.TeleportToLevel = teleportToLevelFunction

	-- TeleportToHub: Client → Server (return to hub)
	local teleportToHubFunction = SecureRemotes.CreateRemoteFunction("TeleportToHub", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.TeleportToHub = teleportToHubFunction

	-- CompleteLevelEvent: Client → Server (finish current level)
	local completeLevelEventEvent = SecureRemotes.CreateRemoteEvent("CompleteLevelEvent", {
		MaxCallsPerSecond = 5,
		TypeSchema = {}
	})
	RemoteEventsInit.Remotes.CompleteLevelEvent = completeLevelEventEvent

	-- SetCheckpoint: Client → Server (update checkpoint position)
	local setCheckpointEvent = SecureRemotes.CreateRemoteEvent("SetCheckpoint", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"number", "CFrame"} -- checkpointId, checkpointCFrame
	})
	RemoteEventsInit.Remotes.SetCheckpoint = setCheckpointEvent

	-- ========================================================================
	-- QUEST SERVICE REMOTES
	-- ========================================================================

	-- GetActiveQuests: Client → Server (get all active quests)
	local getActiveQuestsFunction = SecureRemotes.CreateRemoteFunction("GetActiveQuests", {
		MaxCallsPerSecond = 5,
		TypeSchema = {},
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetActiveQuests = getActiveQuestsFunction

	-- GetQuestProgress: Client → Server (get progress for a quest)
	local getQuestProgressFunction = SecureRemotes.CreateRemoteFunction("GetQuestProgress", {
		MaxCallsPerSecond = 10,
		TypeSchema = {"string"}, -- questId
		ReturnSchema = "table"
	})
	RemoteEventsInit.Remotes.GetQuestProgress = getQuestProgressFunction

	-- ClaimQuestReward: Client → Server (claim completed quest)
	local claimQuestRewardFunction = SecureRemotes.CreateRemoteFunction("ClaimQuestReward", {
		MaxCallsPerSecond = 5,
		TypeSchema = {"string"}, -- questId
		ReturnSchema = "boolean"
	})
	RemoteEventsInit.Remotes.ClaimQuestReward = claimQuestRewardFunction

	-- QuestUpdate: Server → Client (notify of quest progress)
	local questUpdateEvent = SecureRemotes.CreateRemoteEvent("QuestUpdate", {
		RequiresAuth = false, -- Server-to-client only
		MaxCallsPerSecond = 20
	})
	RemoteEventsInit.Remotes.QuestUpdate = questUpdateEvent

	-- ========================================================================
	-- UI REMOTES (Notifications, etc.)
	-- ========================================================================

	-- ShowNotification: Server → Client (display notification)
	local showNotificationEvent = SecureRemotes.CreateRemoteEvent("ShowNotification", {
		RequiresAuth = false, -- Server-to-client only
		MaxCallsPerSecond = 10
	})
	RemoteEventsInit.Remotes.ShowNotification = showNotificationEvent

	print("[RemoteEventsInit] ✅ All remotes initialized successfully")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function RemoteEventsInit.GetRemote(remoteName: string)
	return RemoteEventsInit.Remotes[remoteName]
end

function RemoteEventsInit.GetAllRemotes()
	return RemoteEventsInit.Remotes
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return RemoteEventsInit
