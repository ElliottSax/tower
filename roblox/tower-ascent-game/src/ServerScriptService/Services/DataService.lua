--[[
	DataService.lua
	Player data persistence using ProfileService

	Handles:
	- Loading/saving player data
	- Session locking (prevents data loss)
	- Automatic saving every 60 seconds
	- Safe shutdown handling
	- Data migration

	Data Structure:
	{
		Coins = 0,
		Upgrades = {},
		HighestStage = 0,
		TowersCompleted = 0,
		TotalPlayTime = 0,
		LastLogin = 0,
		Settings = {},
	}

	ProfileService prevents data loss via session locking.
	Never modify player data without ProfileService!

	Week 1: Basic implementation
	Week 2: Add achievements, statistics
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)

local DataService = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local PROFILE_STORE_NAME = "PlayerData_V1" -- Increment when changing data structure
local AUTOSAVE_INTERVAL = 60 -- seconds
local PROFILE_LOAD_TIMEOUT = 30 -- seconds - max time to wait for profile load

-- Default player data template
local DEFAULT_DATA = {
	Coins = 0,

	Upgrades = {
		DoubleJump = 0,    -- 0 = not owned, 1 = owned
		SpeedBoost = 0,    -- 0-5 levels
		AirDash = 0,       -- 0 = not owned, 1 = owned
		WallGrip = 0,      -- 0-3 levels
	},

	Stats = {
		HighestStage = 0,
		TowersCompleted = 0,
		TotalPlaytime = 0,
		Deaths = 0,
		TotalJumps = 0,
		RoundsPlayed = 0,
		TotalCoinsEarned = 0,
		BestCompletionTime = nil,
		DistanceTraveled = 0,
	},

	Timestamps = {
		Created = 0,
		LastLogin = 0,
		LastSave = 0,
	},

	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.7,
		ShowTutorial = true,
	},

	-- Week 15: Tutorial
	TutorialCompleted = false,
	TutorialSkipped = false,
	TutorialCompletedAt = 0,

	-- Week 15: Achievements
	Achievements = {}, -- {AchievementId = {Unlocked, UnlockedAt}}
	UnlockedTitles = {},
	UnlockedTrails = {},

	-- Week 15: Daily Rewards
	DailyReward = {
		LastClaim = 0,
		Streak = 0,
		DayInCycle = 0,
		TotalClaims = 0,
		StreakRecord = 0,
	},

	-- Week 15: Quests
	Quests = {
		Daily = {},
		Weekly = {},
		LastDailyReset = 0,
		LastWeeklyReset = 0,
	},

	-- Metadata
	DataVersion = 1,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Profile store
local ProfileStore = ProfileService.GetProfileStore(
	PROFILE_STORE_NAME,
	DEFAULT_DATA
)

-- Active profiles
-- Format: [Player] = Profile
local Profiles = {}

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function DataService.OnPlayerAdded(player: Player)
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[DataService] Invalid player object in OnPlayerAdded")
		return
	end

	-- Load profile with timeout protection
	local profileKey = "Player_" .. player.UserId
	local profile = nil
	local loadComplete = false

	-- Timeout handler
	task.spawn(function()
		task.wait(PROFILE_LOAD_TIMEOUT)
		if not loadComplete and player:IsDescendantOf(Players) then
			warn(string.format("[DataService] Profile load timeout for %s after %ds",
				player.Name, PROFILE_LOAD_TIMEOUT))
			player:Kick("Data loading timed out. Please rejoin.")
		end
	end)

	-- Attempt to load profile
	local success, result = pcall(function()
		return ProfileStore:LoadProfileAsync(profileKey)
	end)

	loadComplete = true

	if not success then
		warn(string.format("[DataService] Profile load error for %s: %s", player.Name, tostring(result)))
		if player:IsDescendantOf(Players) then
			player:Kick("Failed to load data. Please rejoin.")
		end
		return
	end

	profile = result

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance

		profile:Reconcile() -- Fill in missing data from DEFAULT_DATA

		profile:ListenToRelease(function()
			-- Profile released (player joined on another server)
			Profiles[player] = nil
			player:Kick("Data loaded on another server")
		end)

		if player:IsDescendantOf(Players) then
			-- Player still in game
			Profiles[player] = profile

			-- Update timestamps
			local now = os.time()
			if profile.Data.Timestamps.Created == 0 then
				profile.Data.Timestamps.Created = now
			end
			profile.Data.Timestamps.LastLogin = now

			-- Initialize leaderstats
			DataService.SetupLeaderstats(player, profile)

			print(string.format(
				"[DataService] Loaded profile for %s (Coins: %d, Highest Stage: %d)",
				player.Name,
				profile.Data.Coins,
				profile.Data.Stats.HighestStage
			))
		else
			-- Player left before profile loaded
			profile:Release()
		end
	else
		-- Profile failed to load
		warn(string.format("[DataService] Failed to load profile for %s", player.Name))
		player:Kick("Failed to load data. Please rejoin.")
	end
end

function DataService.OnPlayerRemoving(player: Player)
	local profile = Profiles[player]

	if profile ~= nil then
		-- Update last save timestamp
		profile.Data.Timestamps.LastSave = os.time()

		-- Release profile (auto-saves)
		profile:Release()
		Profiles[player] = nil

		print(string.format("[DataService] Released profile for %s", player.Name))
	end
end

-- ============================================================================
-- LEADERSTATS
-- ============================================================================

function DataService.SetupLeaderstats(player: Player, profile)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	-- Coins
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = profile.Data.Coins
	coins.Parent = leaderstats

	-- Stage (current progress in round)
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0 -- Resets each round
	stage.Parent = leaderstats

	-- Highest Stage (all-time)
	local highestStage = Instance.new("IntValue")
	highestStage.Name = "Best"
	highestStage.Value = profile.Data.Stats.HighestStage
	highestStage.Parent = leaderstats

	leaderstats.Parent = player

	-- NOTE: Removed bidirectional coin sync (leaderstats → profile) to prevent exploits.
	-- Coins should ONLY be modified through DataService.AddCoins/RemoveCoins,
	-- which updates both the profile AND leaderstats in a controlled manner.
	-- This prevents exploiters from modifying their coin count via GUI manipulation.
end

-- ============================================================================
-- DATA ACCESS
-- ============================================================================

function DataService.GetProfile(player: Player)
	return Profiles[player]
end

function DataService.GetData(player: Player)
	local profile = Profiles[player]
	return profile and profile.Data or nil
end

-- ============================================================================
-- COINS
-- ============================================================================

function DataService.AddCoins(player: Player, amount: number): boolean
	-- Input validation
	if not player or not player:IsA("Player") then
		warn("[DataService] Invalid player in AddCoins")
		return false
	end

	if type(amount) ~= "number" or amount <= 0 or amount ~= amount or math.abs(amount) == math.huge then -- NaN and infinity check
		warn("[DataService] Invalid amount in AddCoins:", amount)
		return false
	end

	-- Enforce integer amounts to prevent fractional coin exploits
	amount = math.floor(amount)
	if amount <= 0 then
		return false
	end

	local profile = Profiles[player]
	if not profile then
		warn("[DataService] No profile found for player:", player.Name)
		return false
	end

	-- SECURITY: Enforce MaxCoins cap at data layer (defense in depth)
	local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)
	local maxCoins = GameConfig.Progression.MaxCoins
	local newTotal = profile.Data.Coins + amount
	if newTotal > maxCoins then
		amount = maxCoins - profile.Data.Coins
		if amount <= 0 then
			return false -- Already at cap
		end
	end

	profile.Data.Coins = profile.Data.Coins + amount

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = profile.Data.Coins
		end
	end

	return true
end

function DataService.RemoveCoins(player: Player, amount: number): boolean
	-- Input validation
	if not player or not player:IsA("Player") then
		warn("[DataService] Invalid player in RemoveCoins")
		return false
	end

	if type(amount) ~= "number" or amount <= 0 or amount ~= amount or math.abs(amount) == math.huge then -- NaN and infinity check
		warn("[DataService] Invalid amount in RemoveCoins:", amount)
		return false
	end

	local profile = Profiles[player]
	if not profile then
		warn("[DataService] No profile found for player:", player.Name)
		return false
	end

	if profile.Data.Coins < amount then
		warn(string.format("[DataService] %s has insufficient coins (Has: %d, Needs: %d)",
			player.Name, profile.Data.Coins, amount))
		return false -- Not enough coins
	end

	-- Calculate new value
	local newCoins = profile.Data.Coins - amount

	-- SECURITY FIX: Prevent negative underflow
	if newCoins < 0 then
		warn(string.format("[DataService] Coin underflow prevented for %s: %d - %d",
			player.Name, profile.Data.Coins, amount))
		newCoins = 0
	end

	profile.Data.Coins = newCoins

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = profile.Data.Coins
		end
	end

	return true
end

function DataService.GetCoins(player: Player): number
	local profile = Profiles[player]
	return profile and profile.Data.Coins or 0
end

-- ============================================================================
-- UPGRADES
-- ============================================================================

function DataService.HasUpgrade(player: Player, upgradeName: string): boolean
	local profile = Profiles[player]
	if not profile then return false end

	local level = profile.Data.Upgrades[upgradeName]
	return level and level > 0
end

function DataService.GetUpgradeLevel(player: Player, upgradeName: string): number
	local profile = Profiles[player]
	if not profile then return 0 end

	return profile.Data.Upgrades[upgradeName] or 0
end

function DataService.GrantUpgrade(player: Player, upgradeName: string, level: number): boolean
	local profile = Profiles[player]
	if not profile then return false end

	if not profile.Data.Upgrades[upgradeName] then
		warn(string.format("[DataService] Unknown upgrade: %s", upgradeName))
		return false
	end

	profile.Data.Upgrades[upgradeName] = level

	return true
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function DataService.UpdateHighestStage(player: Player, stage: number)
	local profile = Profiles[player]
	if not profile then return end

	if stage > profile.Data.Stats.HighestStage then
		profile.Data.Stats.HighestStage = stage

		-- Update leaderstats
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local best = leaderstats:FindFirstChild("Best")
			if best then
				best.Value = stage
			end
		end
	end
end

function DataService.IncrementTowersCompleted(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.Stats.TowersCompleted = profile.Data.Stats.TowersCompleted + 1
end

function DataService.IncrementDeaths(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.Stats.Deaths = profile.Data.Stats.Deaths + 1
end

-- ============================================================================
-- AUTOSAVE
-- ============================================================================

function DataService.StartAutosave()
	-- OPTIMIZATION: Stagger autosaves instead of saving all at once
	-- This prevents lag spikes with many players
	task.spawn(function()
		local lastFullCycle = os.time()

		while true do
			-- Get all players with profiles
			local playersToSave = {}
			for player, profile in pairs(Profiles) do
				if profile and profile.Data then
					table.insert(playersToSave, {player = player, profile = profile})
				end
			end

			local playerCount = #playersToSave
			if playerCount > 0 then
				-- Stagger saves across the interval
				-- Save 2-3 profiles per second (spreads load evenly)
				local savesPerTick = math.min(3, math.max(1, math.ceil(playerCount / AUTOSAVE_INTERVAL)))
				local delayBetweenSaves = AUTOSAVE_INTERVAL / playerCount

				for i, data in ipairs(playersToSave) do
					-- Update timestamp (ProfileService auto-saves on data changes)
					data.profile.Data.Timestamps.LastSave = os.time()

					-- Wait before next save (stagger across interval)
					if i < playerCount then
						task.wait(delayBetweenSaves)
					end
				end

				local cycleDuration = os.time() - lastFullCycle
				print(string.format(
					"[DataService] Autosaved %d profiles (staggered over %ds)",
					playerCount,
					cycleDuration
				))
				lastFullCycle = os.time()
			else
				-- No profiles to save, just wait
				task.wait(AUTOSAVE_INTERVAL)
			end
		end
	end)
end

-- ============================================================================
-- SETTINGS (Week 5)
-- ============================================================================

function DataService.GetSetting(player: Player, settingName: string): any
	local profile = Profiles[player]
	if not profile then return nil end

	return profile.Data.Settings[settingName]
end

-- Whitelist of valid settings and their expected types
local VALID_SETTINGS = {
	MusicVolume = "number",
	SFXVolume = "number",
	ShowTutorial = "boolean",
}

function DataService.SetSetting(player: Player, settingName: string, value: any): boolean
	local profile = Profiles[player]
	if not profile then return false end

	-- SECURITY: Validate setting name against whitelist to prevent arbitrary data injection
	if type(settingName) ~= "string" then
		warn("[DataService] Invalid setting name type from", player.Name)
		return false
	end

	local expectedType = VALID_SETTINGS[settingName]
	if not expectedType then
		warn(string.format("[DataService] Unknown setting '%s' from %s", settingName, player.Name))
		return false
	end

	-- SECURITY: Validate value type matches expected type
	if type(value) ~= expectedType then
		warn(string.format("[DataService] Invalid value type for setting '%s' from %s: expected %s, got %s",
			settingName, player.Name, expectedType, type(value)))
		return false
	end

	-- SECURITY: Validate numeric ranges for volume settings
	if expectedType == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			warn(string.format("[DataService] Invalid number for setting '%s' from %s", settingName, player.Name))
			return false
		end
		value = math.clamp(value, 0, 1)
	end

	profile.Data.Settings[settingName] = value
	return true
end

function DataService.GetAllSettings(player: Player): {}
	local profile = Profiles[player]
	if not profile then return {} end

	return profile.Data.Settings
end

-- ============================================================================
-- TUTORIAL STATUS
-- ============================================================================

function DataService.GetTutorialStatus(player: Player): {}
	local profile = Profiles[player]
	if not profile then return {completed = false, skipped = false} end

	return {
		completed = profile.Data.TutorialCompleted or false,
		skipped = profile.Data.TutorialSkipped or false,
		completedAt = profile.Data.TutorialCompletedAt or 0
	}
end

function DataService.SetTutorialComplete(player: Player, completed: boolean): boolean
	local profile = Profiles[player]
	if not profile then return false end

	if completed then
		profile.Data.TutorialCompleted = true
		profile.Data.TutorialCompletedAt = os.time()
	else
		-- Skipped
		profile.Data.TutorialSkipped = true
	end

	print(string.format("[DataService] Tutorial %s for %s",
		completed and "completed" or "skipped",
		player.Name))

	return true
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function DataService.SetupRemoteHandlers()
	local ServerScriptService = game:GetService("ServerScriptService")

	-- Safe require of RemoteEventsInit
	local success, RemoteEventsInit = pcall(function()
		return require(ServerScriptService.Utilities.RemoteEventsInit)
	end)

	if not success or not RemoteEventsInit then
		warn("[DataService] RemoteEventsInit not available, skipping remote handlers")
		return
	end

	-- GetSetting handler
	local getSettingRemote = RemoteEventsInit.GetRemote("GetSetting")
	if getSettingRemote and getSettingRemote.Remote then
		getSettingRemote.Remote.OnServerInvoke = function(player, settingName)
			-- SECURITY: Validate settingName is a string
			if type(settingName) ~= "string" then return nil end
			return DataService.GetSetting(player, settingName)
		end
	end

	-- SetSetting handler
	local setSettingRemote = RemoteEventsInit.GetRemote("SetSetting")
	if setSettingRemote and setSettingRemote.Remote then
		setSettingRemote.Remote.OnServerInvoke = function(player, settingName, value)
			return DataService.SetSetting(player, settingName, value)
		end
	end

	-- GetTutorialStatus handler
	local getTutorialStatusRemote = RemoteEventsInit.GetRemote("GetTutorialStatus")
	if getTutorialStatusRemote and getTutorialStatusRemote.Remote then
		getTutorialStatusRemote.Remote.OnServerInvoke = function(player)
			return DataService.GetTutorialStatus(player)
		end
	end

	-- SetTutorialComplete handler
	local setTutorialCompleteRemote = RemoteEventsInit.GetRemote("SetTutorialComplete")
	if setTutorialCompleteRemote and setTutorialCompleteRemote.Remote then
		setTutorialCompleteRemote.Remote.OnServerInvoke = function(player, completed)
			-- SECURITY: Validate completed is a boolean
			if type(completed) ~= "boolean" then
				warn("[DataService] Invalid completed type from", player.Name)
				return false
			end
			return DataService.SetTutorialComplete(player, completed)
		end
	end

	print("[DataService] Remote handlers setup complete")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DataService.Init()
	print("[DataService] Initializing...")

	-- Setup remote event handlers for settings and tutorial
	DataService.SetupRemoteHandlers()

	-- Player management
	Players.PlayerAdded:Connect(DataService.OnPlayerAdded)
	Players.PlayerRemoving:Connect(DataService.OnPlayerRemoving)

	-- Handle existing players (if script reloads mid-game)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.OnPlayerAdded, player)
	end

	-- Start autosave
	DataService.StartAutosave()

	-- Shutdown handling with timeout protection
	game:BindToClose(function()
		print("[DataService] Server shutting down, releasing all profiles...")

		local releaseCount = 0
		local totalProfiles = 0

		for _ in pairs(Profiles) do
			totalProfiles = totalProfiles + 1
		end

		-- Release all profiles with pcall protection
		for player, profile in pairs(Profiles) do
			if profile then
				local success, err = pcall(function()
					profile:Release()
				end)
				if success then
					releaseCount = releaseCount + 1
				else
					warn(string.format("[DataService] Failed to release profile for %s: %s",
						tostring(player), tostring(err)))
				end
			end
		end

		-- Wait for profiles to save (max 5 seconds to avoid Roblox timeout)
		local waitTime = math.min(5, totalProfiles * 0.5)
		task.wait(waitTime)

		print(string.format("[DataService] Released %d/%d profiles", releaseCount, totalProfiles))
	end)

	print("[DataService] Initialized")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return DataService
