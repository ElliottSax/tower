--[[
	Main.server.lua - Speed Run Universe
	Entry point: initializes all services, handles player lifecycle.

	Game: Obby/parkour speedrun game with 10 themed worlds, 100 stages,
	movement abilities, ghost replays, leaderboards, cosmetics, and tournaments.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== Speed Run Universe - Starting... ===")

-- ============================================================================
-- PHASE 1: Core Infrastructure
-- ============================================================================
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

-- ============================================================================
-- PHASE 2: Game Systems
-- ============================================================================
local SpeedrunService = require(ServerScriptService.Services.SpeedrunService)
SpeedrunService.Init()

local StageService = require(ServerScriptService.Services.StageService)
StageService.Init()

local AbilityService = require(ServerScriptService.Services.AbilityService)
AbilityService.Init()

local CosmeticsService = require(ServerScriptService.Services.CosmeticsService)
CosmeticsService.Init()

local ChallengeService = require(ServerScriptService.Services.ChallengeService)
ChallengeService.Init()

local LeaderboardService = require(ServerScriptService.Services.LeaderboardService)
LeaderboardService.Init()

-- ============================================================================
-- PHASE 3: Monetization
-- ============================================================================
local MonetizationService = require(ServerScriptService.Services.Monetization.MonetizationService)
MonetizationService.Init()

-- ============================================================================
-- REMOTE FUNCTION HANDLERS
-- ============================================================================
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

remoteFunctions:WaitForChild("GetPlayerData").OnServerInvoke = function(player)
	local data = DataService.GetFullData(player)
	if not data then return nil end

	-- Return a safe copy of player data for client use
	return {
		Coins = data.Coins,
		UnlockedWorlds = data.UnlockedWorlds,
		CompletedStages = data.CompletedStages,
		CurrentWorld = data.CurrentWorld,
		CurrentStage = data.CurrentStage,
		FurthestWorld = data.FurthestWorld,
		FurthestStage = data.FurthestStage,
		PersonalBests = data.PersonalBests,
		TotalStagesCompleted = data.TotalStagesCompleted,
		UnlockedAbilities = data.UnlockedAbilities,
		EquippedAbilities = data.EquippedAbilities,
		OwnedTrails = data.OwnedTrails,
		OwnedWinEffects = data.OwnedWinEffects,
		EquippedTrail = data.EquippedTrail,
		EquippedWinEffect = data.EquippedWinEffect,
		TotalDeaths = data.TotalDeaths,
		TotalPlayTime = data.TotalPlayTime,
		TotalCoinsCollected = data.TotalCoinsCollected,
		LoginStreak = data.LoginStreak,
		GamePasses = data.GamePasses,
		ShowGhosts = data.ShowGhosts,
		ShowTrails = data.ShowTrails,
		MusicVolume = data.MusicVolume,
		SFXVolume = data.SFXVolume,
	}
end

remoteFunctions:WaitForChild("GetGhostList").OnServerInvoke = function(player)
	local data = DataService.GetFullData(player)
	if not data then return {} end
	return data.GhostKeys or {}
end

-- ============================================================================
-- PLAYER LIFECYCLE
-- ============================================================================
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

Players.PlayerAdded:Connect(function(player)
	-- Load player data
	DataService.LoadPlayer(player)
	task.wait(1)

	-- Setup leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local data = DataService.GetFullData(player)
	if data then
		local coins = Instance.new("NumberValue")
		coins.Name = "Coins"
		coins.Value = data.Coins
		coins.Parent = leaderstats

		local stages = Instance.new("NumberValue")
		stages.Name = "Stages"
		stages.Value = data.TotalStagesCompleted
		stages.Parent = leaderstats
	end

	-- Check daily reward
	DataService.CheckDailyReward(player)

	-- Generate challenges
	ChallengeService.EnsureDailyChallenges(player)
	ChallengeService.EnsureWeeklyChallenges(player)

	-- Submit stats to leaderboards
	if data then
		if data.TotalCoinsEarned > 0 then
			LeaderboardService.SubmitStat(player, "TotalCoins", data.TotalCoinsEarned)
		end
		if data.TotalStagesCompleted > 0 then
			LeaderboardService.SubmitStat(player, "StagesCompleted", data.TotalStagesCompleted)
		end
	end

	-- Apply speed multiplier from game passes
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local speedMult = DataService.GetSpeedMultiplier(player)
			humanoid.WalkSpeed = GameConfig.SpeedModifiers.Default * speedMult
		end
	end)

	print("[Main]", player.Name, "joined - data loaded")
end)

-- ============================================================================
-- PLAYER LEAVING
-- ============================================================================
Players.PlayerRemoving:Connect(function(player)
	-- Cancel any active speedrun
	if SpeedrunService.IsInRun(player) then
		SpeedrunService.StopRun(player)
	end

	-- Track play time
	local data = DataService.GetFullData(player)
	if data then
		-- Submit final stats to leaderboards
		LeaderboardService.SubmitStat(player, "TotalCoins", data.TotalCoinsEarned)
		LeaderboardService.SubmitStat(player, "StagesCompleted", data.TotalStagesCompleted)
	end

	-- Save and cleanup
	DataService.CleanupPlayer(player)
	print("[Main]", player.Name, "left - data saved")
end)

-- ============================================================================
-- SERVER SHUTDOWN
-- ============================================================================
game:BindToClose(function()
	print("[Main] Server shutting down - saving all players...")
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
	task.wait(3)
end)

-- ============================================================================
-- AUTO-SAVE LOOP (every 60 seconds)
-- ============================================================================
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.SavePlayer(player)

			-- Track play time
			local data = DataService.GetFullData(player)
			if data then
				data.TotalPlayTime = data.TotalPlayTime + 60
			end
		end
	end
end)

-- ============================================================================
-- SETTINGS HANDLER
-- ============================================================================
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
remoteEvents:WaitForChild("UpdateSettings").OnServerEvent:Connect(function(player, settings)
	if not settings or type(settings) ~= "table" then return end

	local data = DataService.GetFullData(player)
	if not data then return end

	-- Only allow updating specific settings
	if settings.ShowGhosts ~= nil and type(settings.ShowGhosts) == "boolean" then
		data.ShowGhosts = settings.ShowGhosts
	end
	if settings.ShowTrails ~= nil and type(settings.ShowTrails) == "boolean" then
		data.ShowTrails = settings.ShowTrails
	end
	if settings.MusicVolume ~= nil and type(settings.MusicVolume) == "number" then
		data.MusicVolume = math.clamp(settings.MusicVolume, 0, 1)
	end
	if settings.SFXVolume ~= nil and type(settings.SFXVolume) == "number" then
		data.SFXVolume = math.clamp(settings.SFXVolume, 0, 1)
	end
end)

-- ============================================================================
-- GHOST REQUEST HANDLER
-- ============================================================================
remoteEvents:WaitForChild("RequestGhost").OnServerEvent:Connect(function(player, data)
	if not data or not data.StageKey then return end
	SpeedrunService.HandleGhostRequest(player, data.StageKey)
end)

-- ============================================================================
-- GHOST TOGGLE
-- ============================================================================
remoteEvents:WaitForChild("ToggleGhosts").OnServerEvent:Connect(function(player, enabled)
	local data = DataService.GetFullData(player)
	if data then
		data.ShowGhosts = enabled == true
	end
end)

print("=== Speed Run Universe - Ready! ===")
print("  Worlds:", #GameConfig.Worlds)
print("  Abilities:", #GameConfig.Abilities)
print("  Trails:", #GameConfig.Trails)
print("  Win Effects:", #GameConfig.WinEffects)
