--[[
	Main.server.lua - Grow a World Entry Point
	Farming Simulator - Multi-biome growing, trading, prestige

	Core Loop: Plant seeds -> Water & grow -> Harvest -> Sell -> Buy better seeds -> Unlock biomes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- ============================================================================
-- SERVICE INITIALIZATION ORDER
-- ============================================================================

print("========================================")
print("  GROW A WORLD - Server Starting...")
print("========================================")

-- Initialize RemoteEvents first
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

-- Core services (order matters)
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

local GardenService = require(ServerScriptService.Services.GardenService)
GardenService.Init()

local SeedService = require(ServerScriptService.Services.SeedService)
SeedService.Init()

local BiomeService = require(ServerScriptService.Services.BiomeService)
BiomeService.Init()

local TradingService = require(ServerScriptService.Services.TradingService)
TradingService.Init()

local PrestigeService = require(ServerScriptService.Services.PrestigeService)
PrestigeService.Init()

local LeaderboardService = require(ServerScriptService.Services.LeaderboardService)
LeaderboardService.Init()

local DailyRewardService = require(ServerScriptService.Services.DailyRewardService)
DailyRewardService.Init()

local MonetizationService = require(ServerScriptService.Services.Monetization.MonetizationService)
MonetizationService.Init()

-- Security
local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

-- ============================================================================
-- PLAYER CONNECTION
-- ============================================================================

Players.PlayerAdded:Connect(function(player)
	print("[Main] Player joined:", player.Name)

	-- Load player data
	local success = DataService.LoadProfile(player)
	if not success then
		player:Kick("Failed to load data. Please rejoin.")
		return
	end

	-- Initialize player systems
	GardenService.SetupPlayer(player)
	DailyRewardService.CheckDailyReward(player)
	LeaderboardService.UpdatePlayer(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = DataService.GetData(player, "Coins") or 0
	coinsValue.Parent = leaderstats

	local prestigeValue = Instance.new("IntValue")
	prestigeValue.Name = "Prestige"
	prestigeValue.Value = DataService.GetData(player, "PrestigeLevel") or 0
	prestigeValue.Parent = leaderstats
end)

Players.PlayerRemoving:Connect(function(player)
	print("[Main] Player left:", player.Name)
	GardenService.CleanupPlayer(player)
	DataService.SaveProfile(player)
end)

-- ============================================================================
-- GRACEFUL SHUTDOWN
-- ============================================================================

game:BindToClose(function()
	print("[Main] Server shutting down, saving all profiles...")
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SaveProfile(player)
	end
	task.wait(2)
	print("[Main] All profiles saved.")
end)

print("========================================")
print("  GROW A WORLD - Server Ready!")
print("  Biomes: 8 | Seeds: 40+ | Trading: ON")
print("========================================")
