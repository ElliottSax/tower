--[[
	DataService.lua
	Handles player data persistence for Dimension Hopper

	Features:
	- Player profile management
	- XP and leveling
	- Dimension mastery tracking
	- Cosmetic unlocks
	- Statistics tracking
	- Auto-save and session locking

	Uses ProfileService pattern for robust data handling
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DATA_STORE_NAME = "DimensionHopper_PlayerData_v1"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes
local SESSION_LOCK_TIMEOUT = 1800 -- 30 minutes

-- Default player data template
local DEFAULT_DATA = {
	-- Progression
	Level = 1,
	TotalXP = 0,
	CurrentXP = 0, -- XP towards next level

	-- Dimension Mastery (XP per dimension)
	DimensionMastery = {
		Gravity = 0,
		Tiny = 0,
		Void = 0,
		Sky = 0,
	},

	-- Statistics
	Stats = {
		TotalRaces = 0,
		RacesWon = 0,
		TotalPlayTime = 0, -- Seconds
		BestTimes = {
			Gravity = nil,
			Tiny = nil,
			Void = nil,
			Sky = nil,
			Marathon = nil,
		},
		SectionsCompleted = 0,
		DeathCount = 0,
		GravityFlips = 0,
		TimesShrank = 0,
		VoidEscapes = 0, -- Narrow escapes
		GlideTime = 0, -- Seconds spent gliding
	},

	-- Collectibles
	Collectibles = {
		Gravity = {}, -- Array of collected fragment IDs
		Tiny = {},
		Void = {},
		Sky = {},
	},

	-- Unlocks
	Unlocks = {
		Trails = {"Default"},
		Wings = {},
		Titles = {"Newcomer"},
		Auras = {},
		Emotes = {"Wave"},
	},

	-- Equipped cosmetics
	Equipped = {
		Trail = "Default",
		Wings = nil,
		Title = "Newcomer",
		Aura = nil,
	},

	-- Settings
	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.7,
		ShowTrails = true,
		ShowOtherPlayers = true,
		ReducedEffects = false,
	},

	-- Monetization
	Purchases = {
		DimensionPass = false,
		DimensionPassTier = 0,
		DimensionPassXP = 0,
		VIP = false,
		GamePasses = {},
		AdsWatchedToday = 0,
		LastAdDate = "",
	},

	-- Daily tracking
	Daily = {
		LastLoginDate = "",
		LoginStreak = 0,
		DailyChallengesCompleted = {},
		FirstWinClaimed = false,
	},

	-- Metadata
	Version = 1,
	FirstJoinDate = "",
	LastSaveDate = "",
}

-- ============================================================================
-- STATE
-- ============================================================================

DataService.PlayerData = {} -- [UserId] = data
DataService.DataStore = nil
DataService.SessionStartTimes = {} -- [UserId] = tick()

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DataService.Init()
	print("[DataService] Initializing...")

	-- Get DataStore (only in non-Studio or with API access)
	local success, store = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)

	if success then
		DataService.DataStore = store
		print("[DataService] DataStore connected")
	else
		warn("[DataService] DataStore unavailable - using session-only data")
	end

	-- Create remotes
	DataService.CreateRemotes()

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		DataService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DataService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.OnPlayerJoin, player)
	end

	-- Start auto-save loop
	DataService.StartAutoSave()

	-- Handle server shutdown
	game:BindToClose(function()
		DataService.OnServerShutdown()
	end)

	print("[DataService] Initialized")
end

function DataService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not remoteFunctions then
		remoteFunctions = Instance.new("Folder")
		remoteFunctions.Name = "RemoteFunctions"
		remoteFunctions.Parent = ReplicatedStorage
	end

	-- Data sync event
	if not remoteFolder:FindFirstChild("DataSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "DataSync"
		event.Parent = remoteFolder
	end

	-- Level up notification
	if not remoteFolder:FindFirstChild("LevelUp") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LevelUp"
		event.Parent = remoteFolder
	end

	-- XP gained notification
	if not remoteFolder:FindFirstChild("XPGained") then
		local event = Instance.new("RemoteEvent")
		event.Name = "XPGained"
		event.Parent = remoteFolder
	end

	-- Unlock notification
	if not remoteFolder:FindFirstChild("ItemUnlocked") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ItemUnlocked"
		event.Parent = remoteFolder
	end

	-- Get player data (client -> server)
	if not remoteFunctions:FindFirstChild("GetPlayerData") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetPlayerData"
		func.Parent = remoteFunctions

		func.OnServerInvoke = function(player)
			return DataService.GetData(player)
		end
	end

	-- Update settings (client -> server)
	if not remoteFolder:FindFirstChild("UpdateSettings") then
		local event = Instance.new("RemoteEvent")
		event.Name = "UpdateSettings"
		event.Parent = remoteFolder
	end

	-- Equip cosmetic (client -> server)
	if not remoteFolder:FindFirstChild("EquipCosmetic") then
		local event = Instance.new("RemoteEvent")
		event.Name = "EquipCosmetic"
		event.Parent = remoteFolder
	end

	DataService.Remotes = {
		DataSync = remoteFolder.DataSync,
		LevelUp = remoteFolder.LevelUp,
		XPGained = remoteFolder.XPGained,
		ItemUnlocked = remoteFolder.ItemUnlocked,
		UpdateSettings = remoteFolder.UpdateSettings,
		EquipCosmetic = remoteFolder.EquipCosmetic,
	}

	-- Connect client requests
	DataService.Remotes.UpdateSettings.OnServerEvent:Connect(function(player, settings)
		DataService.UpdateSettings(player, settings)
	end)

	DataService.Remotes.EquipCosmetic.OnServerEvent:Connect(function(player, category, itemId)
		DataService.EquipCosmetic(player, category, itemId)
	end)
end

-- ============================================================================
-- PLAYER DATA MANAGEMENT
-- ============================================================================

function DataService.OnPlayerJoin(player: Player)
	print(string.format("[DataService] Loading data for %s", player.Name))

	DataService.SessionStartTimes[player.UserId] = tick()

	-- Load or create data
	local data = DataService.LoadData(player)

	-- Update daily login
	DataService.ProcessDailyLogin(player, data)

	-- Store in memory
	DataService.PlayerData[player.UserId] = data

	-- Sync to client
	DataService.SyncToClient(player)

	print(string.format("[DataService] %s data loaded (Level %d, %d XP)",
		player.Name, data.Level, data.TotalXP))
end

function DataService.OnPlayerLeave(player: Player)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	-- Update play time
	local sessionTime = tick() - (DataService.SessionStartTimes[player.UserId] or tick())
	data.Stats.TotalPlayTime = data.Stats.TotalPlayTime + sessionTime

	-- Save data
	DataService.SaveData(player)

	-- Cleanup
	DataService.PlayerData[player.UserId] = nil
	DataService.SessionStartTimes[player.UserId] = nil

	print(string.format("[DataService] Saved and cleaned up data for %s", player.Name))
end

function DataService.LoadData(player: Player): table
	local data = nil

	-- Try to load from DataStore
	if DataService.DataStore then
		local success, result = pcall(function()
			return DataService.DataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and result then
			data = result
			print(string.format("[DataService] Loaded saved data for %s", player.Name))
		elseif not success then
			warn(string.format("[DataService] Failed to load data for %s: %s",
				player.Name, tostring(result)))
		end
	end

	-- Use default if no saved data
	if not data then
		data = DataService.DeepCopy(DEFAULT_DATA)
		data.FirstJoinDate = os.date("%Y-%m-%d")
		print(string.format("[DataService] Created new data for %s", player.Name))
	end

	-- Migrate old data versions if needed
	data = DataService.MigrateData(data)

	return data
end

function DataService.SaveData(player: Player): boolean
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	data.LastSaveDate = os.date("%Y-%m-%d %H:%M:%S")

	if not DataService.DataStore then
		return true -- Session-only, no actual save
	end

	local success, err = pcall(function()
		DataService.DataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn(string.format("[DataService] Failed to save data for %s: %s",
			player.Name, tostring(err)))
		return false
	end

	return true
end

function DataService.MigrateData(data: table): table
	-- Handle data version migrations
	local currentVersion = 1

	if not data.Version then
		data.Version = 1
	end

	-- Add migration logic here as versions increase
	-- if data.Version < 2 then
	--     -- Migrate from v1 to v2
	--     data.Version = 2
	-- end

	-- Ensure all default fields exist (for new features)
	for key, defaultValue in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			data[key] = DataService.DeepCopy(defaultValue)
		elseif type(defaultValue) == "table" then
			for subKey, subDefault in pairs(defaultValue) do
				if data[key][subKey] == nil then
					data[key][subKey] = DataService.DeepCopy(subDefault)
				end
			end
		end
	end

	return data
end

-- ============================================================================
-- XP & LEVELING
-- ============================================================================

function DataService.AddXP(player: Player, amount: number, source: string?)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	-- Apply multipliers
	local multiplier = 1

	-- VIP multiplier
	if data.Purchases.VIP then
		multiplier = multiplier * (GameConfig.Monetization.VIP.XPMultiplier or 2)
	end

	-- Double XP game pass
	if data.Purchases.GamePasses and data.Purchases.GamePasses["DoubleXP"] then
		multiplier = multiplier * 2
	end

	-- Dimension Pass bonus
	if data.Purchases.DimensionPass then
		multiplier = multiplier * (GameConfig.Monetization.DimensionPass.BonusXPMultiplier or 1.25)
	end

	local finalAmount = math.floor(amount * multiplier)

	data.TotalXP = data.TotalXP + finalAmount
	data.CurrentXP = data.CurrentXP + finalAmount

	-- Notify client
	DataService.Remotes.XPGained:FireClient(player, finalAmount, source)

	-- Check for level up
	DataService.CheckLevelUp(player)

	print(string.format("[DataService] %s gained %d XP (%s)", player.Name, finalAmount, source or "unknown"))
end

function DataService.AddDimensionXP(player: Player, dimension: string, amount: number)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	if not data.DimensionMastery[dimension] then
		data.DimensionMastery[dimension] = 0
	end

	data.DimensionMastery[dimension] = data.DimensionMastery[dimension] + amount

	-- Also add to total XP
	DataService.AddXP(player, amount, "Dimension: " .. dimension)
end

function DataService.CheckLevelUp(player: Player)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	local levelsGained = 0

	while data.CurrentXP >= DataService.GetXPForLevel(data.Level + 1) do
		local required = DataService.GetXPForLevel(data.Level + 1)
		data.CurrentXP = data.CurrentXP - required
		data.Level = data.Level + 1
		levelsGained = levelsGained + 1

		-- Check for level rewards
		local reward = GameConfig.Progression.LevelRewards[data.Level]
		if reward then
			DataService.UnlockItem(player, reward.Type, reward.Id)
		end
	end

	if levelsGained > 0 then
		-- Notify client
		DataService.Remotes.LevelUp:FireClient(player, data.Level, levelsGained)

		-- Sync updated data
		DataService.SyncToClient(player)

		print(string.format("[DataService] %s leveled up to %d!", player.Name, data.Level))
	end
end

function DataService.GetXPForLevel(level: number): number
	local baseXP = GameConfig.Progression.BaseXPPerLevel or 100
	local scaling = GameConfig.Progression.XPScaling or 1.08

	return math.floor(baseXP * math.pow(scaling, level - 1))
end

function DataService.GetMasteryTier(player: Player, dimension: string): string
	local data = DataService.PlayerData[player.UserId]
	if not data then return "Bronze" end

	local xp = data.DimensionMastery[dimension] or 0
	local masteryConfig = GameConfig.Dimensions[dimension] and GameConfig.Dimensions[dimension].Mastery

	if not masteryConfig then return "Bronze" end

	local tier = "Bronze"
	for tierName, requiredXP in pairs(masteryConfig) do
		if xp >= requiredXP then
			tier = tierName
		end
	end

	return tier
end

-- ============================================================================
-- UNLOCKS
-- ============================================================================

function DataService.UnlockItem(player: Player, category: string, itemId: string)
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	-- Map category to unlock table
	local categoryMap = {
		Trail = "Trails",
		Wing = "Wings",
		Title = "Titles",
		Aura = "Auras",
		Emote = "Emotes",
	}

	local unlockCategory = categoryMap[category] or category

	if not data.Unlocks[unlockCategory] then
		data.Unlocks[unlockCategory] = {}
	end

	-- Check if already unlocked
	for _, item in ipairs(data.Unlocks[unlockCategory]) do
		if item == itemId then
			return false -- Already unlocked
		end
	end

	-- Unlock
	table.insert(data.Unlocks[unlockCategory], itemId)

	-- Notify client
	DataService.Remotes.ItemUnlocked:FireClient(player, category, itemId)

	print(string.format("[DataService] %s unlocked %s: %s", player.Name, category, itemId))

	return true
end

function DataService.HasUnlock(player: Player, category: string, itemId: string): boolean
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	local categoryMap = {
		Trail = "Trails",
		Wing = "Wings",
		Title = "Titles",
		Aura = "Auras",
		Emote = "Emotes",
	}

	local unlockCategory = categoryMap[category] or category

	if not data.Unlocks[unlockCategory] then return false end

	for _, item in ipairs(data.Unlocks[unlockCategory]) do
		if item == itemId then
			return true
		end
	end

	return false
end

function DataService.EquipCosmetic(player: Player, category: string, itemId: string)
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	-- Verify player has the item (or it's nil to unequip)
	if itemId and not DataService.HasUnlock(player, category, itemId) then
		return false
	end

	data.Equipped[category] = itemId

	-- Sync to client
	DataService.SyncToClient(player)

	return true
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function DataService.IncrementStat(player: Player, statName: string, amount: number?)
	local data = DataService.PlayerData[player.UserId]
	if not data or not data.Stats then return end

	amount = amount or 1

	if data.Stats[statName] ~= nil then
		data.Stats[statName] = data.Stats[statName] + amount
	end
end

function DataService.SetBestTime(player: Player, dimension: string, time: number)
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	local currentBest = data.Stats.BestTimes[dimension]

	if not currentBest or time < currentBest then
		data.Stats.BestTimes[dimension] = time
		return true -- New record!
	end

	return false
end

function DataService.RecordRaceResult(player: Player, dimension: string, finishTime: number?, placement: number?)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	data.Stats.TotalRaces = data.Stats.TotalRaces + 1

	if placement == 1 then
		data.Stats.RacesWon = data.Stats.RacesWon + 1
	end

	if finishTime then
		DataService.SetBestTime(player, dimension, finishTime)
	end
end

-- ============================================================================
-- COLLECTIBLES
-- ============================================================================

function DataService.CollectFragment(player: Player, dimension: string, fragmentId: string): boolean
	local data = DataService.PlayerData[player.UserId]
	if not data then return false end

	if not data.Collectibles[dimension] then
		data.Collectibles[dimension] = {}
	end

	-- Check if already collected
	for _, id in ipairs(data.Collectibles[dimension]) do
		if id == fragmentId then
			return false -- Already collected
		end
	end

	-- Collect it
	table.insert(data.Collectibles[dimension], fragmentId)

	-- Award XP
	DataService.AddXP(player, GameConfig.Collectibles.FragmentXP or 25, "Fragment")

	-- Check for all fragments collected
	local totalFragments = GameConfig.Collectibles.FragmentsPerDimension or 50
	if #data.Collectibles[dimension] >= totalFragments then
		-- Award completion reward
		local reward = GameConfig.Collectibles.AllFragmentsReward[dimension]
		if reward then
			DataService.UnlockItem(player, reward.Type, reward.Id)
		end
	end

	return true
end

-- ============================================================================
-- DAILY LOGIN
-- ============================================================================

function DataService.ProcessDailyLogin(player: Player, data: table)
	local today = os.date("%Y-%m-%d")

	if data.Daily.LastLoginDate ~= today then
		-- New day!
		local yesterday = os.date("%Y-%m-%d", os.time() - 86400)

		if data.Daily.LastLoginDate == yesterday then
			-- Consecutive day
			data.Daily.LoginStreak = data.Daily.LoginStreak + 1
		else
			-- Streak broken
			data.Daily.LoginStreak = 1
		end

		data.Daily.LastLoginDate = today
		data.Daily.FirstWinClaimed = false
		data.Daily.DailyChallengesCompleted = {}
		data.Purchases.AdsWatchedToday = 0
		data.Purchases.LastAdDate = today

		-- Streak bonus XP
		local streakBonus = math.min(data.Daily.LoginStreak * 10, 100)
		DataService.AddXP(player, streakBonus, "Login Streak")

		print(string.format("[DataService] %s daily login - Streak: %d days",
			player.Name, data.Daily.LoginStreak))
	end
end

-- ============================================================================
-- SETTINGS
-- ============================================================================

function DataService.UpdateSettings(player: Player, newSettings: table)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	-- Validate and apply settings
	for key, value in pairs(newSettings) do
		if data.Settings[key] ~= nil then
			-- Type check
			if typeof(value) == typeof(data.Settings[key]) then
				data.Settings[key] = value
			end
		end
	end
end

-- ============================================================================
-- DATA ACCESS
-- ============================================================================

function DataService.GetData(player: Player): table?
	return DataService.PlayerData[player.UserId]
end

function DataService.SyncToClient(player: Player)
	local data = DataService.PlayerData[player.UserId]
	if not data then return end

	-- Send safe copy to client (exclude sensitive data if any)
	local clientData = {
		Level = data.Level,
		TotalXP = data.TotalXP,
		CurrentXP = data.CurrentXP,
		XPToNextLevel = DataService.GetXPForLevel(data.Level + 1),
		DimensionMastery = data.DimensionMastery,
		Stats = data.Stats,
		Collectibles = data.Collectibles,
		Unlocks = data.Unlocks,
		Equipped = data.Equipped,
		Settings = data.Settings,
		Daily = {
			LoginStreak = data.Daily.LoginStreak,
			FirstWinClaimed = data.Daily.FirstWinClaimed,
		},
		Purchases = {
			DimensionPass = data.Purchases.DimensionPass,
			DimensionPassTier = data.Purchases.DimensionPassTier,
			VIP = data.Purchases.VIP,
			GamePasses = data.Purchases.GamePasses,
		},
	}

	DataService.Remotes.DataSync:FireClient(player, clientData)
end

-- ============================================================================
-- AUTO-SAVE
-- ============================================================================

function DataService.StartAutoSave()
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)

			for _, player in ipairs(Players:GetPlayers()) do
				if DataService.PlayerData[player.UserId] then
					DataService.SaveData(player)
				end
			end

			print("[DataService] Auto-save complete")
		end
	end)
end

function DataService.OnServerShutdown()
	print("[DataService] Server shutting down - saving all data...")

	for _, player in ipairs(Players:GetPlayers()) do
		if DataService.PlayerData[player.UserId] then
			-- Update play time
			local sessionTime = tick() - (DataService.SessionStartTimes[player.UserId] or tick())
			DataService.PlayerData[player.UserId].Stats.TotalPlayTime =
				DataService.PlayerData[player.UserId].Stats.TotalPlayTime + sessionTime

			DataService.SaveData(player)
		end
	end

	print("[DataService] All data saved")
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function DataService.DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in pairs(original) do
		copy[key] = DataService.DeepCopy(value)
	end

	return copy
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function DataService.DebugPrint(player: Player)
	local data = DataService.PlayerData[player.UserId]
	if not data then
		print("[DataService] No data for " .. player.Name)
		return
	end

	print("=== DATA SERVICE - " .. player.Name .. " ===")
	print(string.format("  Level: %d", data.Level))
	print(string.format("  Total XP: %d", data.TotalXP))
	print(string.format("  Current XP: %d / %d", data.CurrentXP, DataService.GetXPForLevel(data.Level + 1)))
	print(string.format("  Races: %d (Won: %d)", data.Stats.TotalRaces, data.Stats.RacesWon))
	print(string.format("  Login Streak: %d days", data.Daily.LoginStreak))
	print("==========================================")
end

return DataService
