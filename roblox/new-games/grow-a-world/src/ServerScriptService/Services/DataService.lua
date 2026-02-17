--[[
	DataService.lua - Grow a World
	Player data persistence using ProfileService

	Handles save/load, auto-save, session locking, data migration
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)

local DataService = {}

local PROFILE_STORE_NAME = "GrowAWorld_V1"
local AUTOSAVE_INTERVAL = 60

local DEFAULT_DATA = {
	Coins = 100,
	TotalCoinsEarned = 0,

	-- Garden State
	Gardens = {}, -- [BiomeName] = { Plots = { [slotIndex] = { SeedName, PlantedAt, Watered } } }
	UnlockedBiomes = { "Meadow" },

	-- Inventory
	SeedInventory = {}, -- { {Name, Rarity, Biome, Count} }
	HarvestedPlants = {}, -- { {Name, Rarity, Count} }

	-- Tools
	WateringCanLevel = 1,
	FertilizerLevel = 1,

	-- Progression
	PrestigeLevel = 0,
	PlantsHarvested = 0,
	RarestPlantFound = "Common",

	-- Daily Rewards
	LastLoginDate = "",
	LoginStreak = 0,
	DailyRewardsClaimed = {},

	-- Trading
	TradesCompleted = 0,

	-- Statistics
	TotalPlayTime = 0,
	JoinCount = 0,
	LastJoinTime = 0,

	-- Monetization
	GamePasses = {},
	PremiumBenefits = false,

	-- Settings
	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.8,
		ShowTrails = true,
		Notifications = true,
	},
}

-- ============================================================================
-- PROFILE MANAGEMENT
-- ============================================================================

local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, DEFAULT_DATA)
local Profiles = {}

function DataService.Init()
	print("[DataService] Initializing...")

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

function DataService.LoadProfile(player)
	local profile = ProfileStore:LoadProfileAsync(
		"Player_" .. player.UserId,
		"ForceLoad"
	)

	if not profile then
		warn("[DataService] Failed to load profile for", player.Name)
		return false
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile() -- Fill in missing default values

	-- Handle session lock release (player left before load finished)
	profile:ListenToRelease(function()
		Profiles[player.UserId] = nil
		if player:IsDescendantOf(Players) then
			player:Kick("Data session released. Please rejoin.")
		end
	end)

	-- Player already left
	if not player:IsDescendantOf(Players) then
		profile:Release()
		return false
	end

	Profiles[player.UserId] = profile

	-- Update join stats
	profile.Data.JoinCount = (profile.Data.JoinCount or 0) + 1
	profile.Data.LastJoinTime = os.time()

	print("[DataService] Loaded profile for", player.Name, "| Coins:", profile.Data.Coins, "| Prestige:", profile.Data.PrestigeLevel)
	return true
end

function DataService.SaveProfile(player)
	local profile = Profiles[player.UserId]
	if profile then
		profile:Release()
	end
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

	-- Apply prestige multiplier
	local prestigeLevel = profile.Data.PrestigeLevel or 0
	local multiplier = 1 + (prestigeLevel * 0.25)

	-- Apply VIP multiplier
	if profile.Data.GamePasses and profile.Data.GamePasses["VIP"] then
		multiplier = multiplier * 2
	end

	local finalAmount = math.floor(amount * multiplier)
	profile.Data.Coins = profile.Data.Coins + finalAmount
	profile.Data.TotalCoinsEarned = profile.Data.TotalCoinsEarned + finalAmount

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue.Value = profile.Data.Coins
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

return DataService
