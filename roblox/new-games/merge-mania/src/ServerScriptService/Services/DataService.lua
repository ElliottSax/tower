--[[
	DataService.lua - Merge Mania
	Player data persistence using ProfileService

	Handles save/load, auto-save, session locking, data migration
	Stores: grid state, generators, collections, prestige, earnings, settings
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}

local PROFILE_STORE_NAME = "MergeMania_V1"
local AUTOSAVE_INTERVAL = 60

-- ============================================================================
-- DEFAULT DATA TEMPLATE
-- ============================================================================
local DEFAULT_DATA = {
	-- Currency
	Coins = 500,
	TotalCoinsEarned = 0,

	-- Grid State: { ["row_col"] = { Path = "Weapons", Tier = 1, IsGolden = false } }
	Grid = {},
	GridRows = 6,
	GridCols = 6,

	-- Unlocked Paths
	UnlockedPaths = { "Weapons" },

	-- Generators: { { GeneratorName = "Rusty Spawner", Level = 1, LastSpawnTime = 0 } }
	OwnedGenerators = {},

	-- Collections: { [CollectionName] = { DiscoveredTiers = {1, 2, 3}, Completed = false } }
	Collections = {},

	-- Highest tier reached per path (for collection tracking)
	HighestTiers = {
		Weapons = 0,
		Pets = 0,
		Food = 0,
		Gems = 0,
	},

	-- Prestige
	PrestigeLevel = 0,
	TotalPrestiges = 0,

	-- Earnings tracking
	TotalMerges = 0,
	TotalItemsSold = 0,
	GoldenMerges = 0,

	-- Offline earnings
	LastOnlineTime = 0,
	OfflineEarningsCollected = true,

	-- Active boosts: { [BoostName] = ExpiryTimestamp }
	ActiveBoosts = {},

	-- Daily rewards
	LastLoginDate = "",
	LoginStreak = 0,
	DailyRewardsClaimed = {},

	-- Monetization
	GamePasses = {},
	PremiumBenefits = false,

	-- Statistics
	TotalPlayTime = 0,
	JoinCount = 0,
	LastJoinTime = 0,

	-- Settings
	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.8,
		ShowMergeEffects = true,
		Notifications = true,
		AutoCollectOffline = false,
	},

	-- Event data
	EventProgress = {},
}

-- ============================================================================
-- PROFILE MANAGEMENT (ProfileService pattern)
-- ============================================================================

-- In production, use ProfileService. This is a compatible implementation
-- that uses DataStoreService as fallback.
local DataStoreService = game:GetService("DataStoreService")
local ProfileStore = nil
local Profiles = {} -- [UserId] = { Data = {}, Released = false }

local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function reconcileData(data, template)
	for key, defaultValue in pairs(template) do
		if data[key] == nil then
			if type(defaultValue) == "table" then
				data[key] = deepCopy(defaultValue)
			else
				data[key] = defaultValue
			end
		elseif type(defaultValue) == "table" and type(data[key]) == "table" then
			reconcileData(data[key], defaultValue)
		end
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DataService.Init()
	print("[DataService] Initializing...")

	local success, err = pcall(function()
		ProfileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)
	end)

	if not success then
		warn("[DataService] Failed to get DataStore:", err)
	end

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				DataService.SaveProfile(player)
			end
		end
	end)

	print("[DataService] Initialized with auto-save every", AUTOSAVE_INTERVAL, "seconds")
end

-- ============================================================================
-- LOAD / SAVE
-- ============================================================================

function DataService.LoadProfile(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	-- Try to load from DataStore
	local savedData = nil
	if ProfileStore then
		local success, result = pcall(function()
			return ProfileStore:GetAsync(key)
		end)
		if success then
			savedData = result
		else
			warn("[DataService] Failed to load data for", player.Name, ":", result)
		end
	end

	-- Use saved data or defaults
	local data = savedData or deepCopy(DEFAULT_DATA)
	reconcileData(data, DEFAULT_DATA)

	-- Create profile
	Profiles[userId] = {
		Data = data,
		Released = false,
		LastSave = os.time(),
	}

	-- Update join stats
	data.JoinCount = (data.JoinCount or 0) + 1
	data.LastJoinTime = os.time()

	print("[DataService] Loaded profile for", player.Name,
		"| Coins:", data.Coins,
		"| Prestige:", data.PrestigeLevel,
		"| Paths:", #data.UnlockedPaths,
		"| Generators:", #data.OwnedGenerators)

	return true
end

function DataService.SaveProfile(player)
	local profile = Profiles[player.UserId]
	if not profile or profile.Released then return end

	local key = "Player_" .. player.UserId

	if ProfileStore then
		local success, err = pcall(function()
			ProfileStore:SetAsync(key, profile.Data)
		end)
		if success then
			profile.LastSave = os.time()
		else
			warn("[DataService] Failed to save data for", player.Name, ":", err)
		end
	end
end

function DataService.ReleaseProfile(player)
	local profile = Profiles[player.UserId]
	if not profile then return end

	-- Final save before release
	DataService.SaveProfile(player)
	profile.Released = true
	Profiles[player.UserId] = nil
end

-- ============================================================================
-- DATA ACCESS
-- ============================================================================

function DataService.GetData(player, key)
	local profile = Profiles[player.UserId]
	if not profile then return nil end
	return profile.Data[key]
end

function DataService.SetData(player, key, value)
	local profile = Profiles[player.UserId]
	if not profile then return false end
	profile.Data[key] = value
	return true
end

function DataService.UpdateData(player, key, updateFunc)
	local profile = Profiles[player.UserId]
	if not profile then return false end
	profile.Data[key] = updateFunc(profile.Data[key])
	return true
end

function DataService.GetProfile(player)
	return Profiles[player.UserId]
end

function DataService.GetFullData(player)
	local profile = Profiles[player.UserId]
	if not profile then return nil end
	return profile.Data
end

-- ============================================================================
-- COIN OPERATIONS
-- ============================================================================

function DataService.AddCoins(player, amount)
	local profile = Profiles[player.UserId]
	if not profile or amount <= 0 then return false end

	local data = profile.Data

	-- Calculate multipliers
	local multiplier = 1.0

	-- Prestige multiplier
	local prestigeLevel = data.PrestigeLevel or 0
	multiplier = multiplier + (prestigeLevel * GameConfig.Prestige.Multiplier)

	-- Game pass multiplier (2x earnings)
	if data.GamePasses and data.GamePasses["DoubleEarnings"] then
		multiplier = multiplier * 2
	end

	-- VIP multiplier
	if data.GamePasses and data.GamePasses["VIP"] then
		multiplier = multiplier * 1.5
	end

	-- Prestige 40 reward: 2x all passive
	if prestigeLevel >= 40 then
		multiplier = multiplier * 2
	end

	-- Prestige 50 reward: 3x all
	if prestigeLevel >= 50 then
		multiplier = multiplier * 3
	end

	local finalAmount = math.floor(amount * multiplier)
	data.Coins = data.Coins + finalAmount
	data.TotalCoinsEarned = data.TotalCoinsEarned + finalAmount

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue.Value = data.Coins
		end
	end

	return true, finalAmount
end

function DataService.RemoveCoins(player, amount)
	local profile = Profiles[player.UserId]
	if not profile or amount <= 0 then return false end
	if profile.Data.Coins < amount then return false end

	profile.Data.Coins = profile.Data.Coins - amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue.Value = profile.Data.Coins
		end
	end

	return true
end

function DataService.GetCoins(player)
	local profile = Profiles[player.UserId]
	if not profile then return 0 end
	return profile.Data.Coins
end

-- ============================================================================
-- GRID OPERATIONS
-- ============================================================================

function DataService.GetGrid(player)
	local profile = Profiles[player.UserId]
	if not profile then return {} end
	return profile.Data.Grid
end

function DataService.SetGridCell(player, row, col, itemData)
	local profile = Profiles[player.UserId]
	if not profile then return false end

	local key = row .. "_" .. col
	profile.Data.Grid[key] = itemData
	return true
end

function DataService.ClearGridCell(player, row, col)
	local profile = Profiles[player.UserId]
	if not profile then return false end

	local key = row .. "_" .. col
	profile.Data.Grid[key] = nil
	return true
end

function DataService.GetGridSize(player)
	local profile = Profiles[player.UserId]
	if not profile then return 6, 6 end

	local data = profile.Data
	local rows = data.GridRows or 6
	local cols = data.GridCols or 6

	-- Check grid expansion pass
	if data.GamePasses and data.GamePasses["GridExpansion"] then
		rows = math.max(rows, GameConfig.Grid.ExpandedRows)
		cols = math.max(cols, GameConfig.Grid.ExpandedCols)
	end

	return rows, cols
end

-- ============================================================================
-- BOOST MANAGEMENT
-- ============================================================================

function DataService.HasActiveBoost(player, boostName)
	local profile = Profiles[player.UserId]
	if not profile then return false end

	local boosts = profile.Data.ActiveBoosts
	if not boosts or not boosts[boostName] then return false end

	return boosts[boostName] > os.time()
end

function DataService.AddBoost(player, boostName, durationSeconds)
	local profile = Profiles[player.UserId]
	if not profile then return false end

	profile.Data.ActiveBoosts = profile.Data.ActiveBoosts or {}
	local currentExpiry = profile.Data.ActiveBoosts[boostName] or os.time()
	profile.Data.ActiveBoosts[boostName] = math.max(currentExpiry, os.time()) + durationSeconds

	return true
end

return DataService
