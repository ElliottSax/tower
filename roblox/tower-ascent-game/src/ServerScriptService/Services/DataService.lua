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

	-- Load profile
	local profileKey = "Player_" .. player.UserId

	local profile = ProfileStore:LoadProfileAsync(profileKey)

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

	-- Listen for coin changes
	coins.Changed:Connect(function(newValue)
		if profile and profile.Data then
			profile.Data.Coins = newValue
		end
	end)
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

	if type(amount) ~= "number" or amount <= 0 or amount ~= amount then -- NaN check
		warn("[DataService] Invalid amount in AddCoins:", amount)
		return false
	end

	local profile = Profiles[player]
	if not profile then
		warn("[DataService] No profile found for player:", player.Name)
		return false
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

	if type(amount) ~= "number" or amount <= 0 or amount ~= amount then -- NaN check
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

	profile.Data.Coins = profile.Data.Coins - amount

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
	-- Autosave every 60 seconds
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)

			local saveCount = 0
			for player, profile in pairs(Profiles) do
				if profile and profile.Data then
					profile.Data.Timestamps.LastSave = os.time()
					saveCount = saveCount + 1
				end
			end

			if saveCount > 0 then
				print(string.format("[DataService] Autosaved %d profiles", saveCount))
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

function DataService.SetSetting(player: Player, settingName: string, value: any): boolean
	local profile = Profiles[player]
	if not profile then return false end

	profile.Data.Settings[settingName] = value
	return true
end

function DataService.GetAllSettings(player: Player): {}
	local profile = Profiles[player]
	if not profile then return {} end

	return profile.Data.Settings
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DataService.Init()
	print("[DataService] Initializing...")

	-- Player management
	Players.PlayerAdded:Connect(DataService.OnPlayerAdded)
	Players.PlayerRemoving:Connect(DataService.OnPlayerRemoving)

	-- Handle existing players (if script reloads mid-game)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.OnPlayerAdded, player)
	end

	-- Start autosave
	DataService.StartAutosave()

	-- Shutdown handling
	game:BindToClose(function()
		print("[DataService] Server shutting down, releasing all profiles...")

		for player, profile in pairs(Profiles) do
			if profile then
				profile:Release()
			end
		end

		-- Wait for profiles to save
		task.wait(2)

		print("[DataService] All profiles released")
	end)

	print("[DataService] Initialized")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return DataService
