--[[
	Main.server.lua - Anime Training Simulator
	Entry point - initializes all services in dependency order
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("==============================================")
print("  Anime Training Simulator - Starting...")
print("==============================================")

-- Initialize utility systems first
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

-- Initialize core services
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

local TrainingService = require(ServerScriptService.Services.TrainingService)
TrainingService.Init()

local PetService = require(ServerScriptService.Services.PetService)
PetService.Init()

local TransformationService = require(ServerScriptService.Services.TransformationService)
TransformationService.Init()

local AbilityService = require(ServerScriptService.Services.AbilityService)
AbilityService.Init()

local PvPService = require(ServerScriptService.Services.PvPService)
PvPService.Init()

local QuestService = require(ServerScriptService.Services.QuestService)
QuestService.Init()

local RebirthService = require(ServerScriptService.Services.RebirthService)
RebirthService.Init()

local ZoneService = require(ServerScriptService.Services.ZoneService)
ZoneService.Init()

local DailyRewardService = require(ServerScriptService.Services.DailyRewardService)
DailyRewardService.Init()

local MonetizationService = require(ServerScriptService.Services.Monetization.MonetizationService)
MonetizationService.Init()

local LeaderboardService = require(ServerScriptService.Services.LeaderboardService)
LeaderboardService.Init()

-- Player setup
Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	task.wait(1)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local data = DataService.GetFullData(player)
	if data then
		local power = Instance.new("NumberValue")
		power.Name = "Power"
		power.Value = data.Strength + data.Defense + data.Speed + data.Spirit
		power.Parent = leaderstats

		local coins = Instance.new("NumberValue")
		coins.Name = "Coins"
		coins.Value = data.Coins
		coins.Parent = leaderstats

		local rebirth = Instance.new("NumberValue")
		rebirth.Name = "Rebirth"
		rebirth.Value = data.RebirthLevel
		rebirth.Parent = leaderstats
	end

	-- Check daily reward
	DailyRewardService.CheckDailyReward(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

-- Graceful shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
	task.wait(3)
end)

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.SavePlayer(player)
		end
	end
end)

print("==============================================")
print("  Anime Training Simulator - Ready!")
print("==============================================")
