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
