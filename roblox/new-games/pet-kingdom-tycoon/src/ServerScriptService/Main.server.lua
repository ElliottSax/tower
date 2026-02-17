--[[
	Main.server.lua - Pet Kingdom Tycoon
	Entry point - init all services
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

print("=== Pet Kingdom Tycoon - Starting... ===")

local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

local PetService = require(ServerScriptService.Services.PetService)
PetService.Init()

local BreedingService = require(ServerScriptService.Services.BreedingService)
BreedingService.Init()

local KingdomService = require(ServerScriptService.Services.KingdomService)
KingdomService.Init()

local WorldService = require(ServerScriptService.Services.WorldService)
WorldService.Init()

local TradingService = require(ServerScriptService.Services.TradingService)
TradingService.Init()

local DailyRewardService = require(ServerScriptService.Services.DailyRewardService)
DailyRewardService.Init()

local LeaderboardService = require(ServerScriptService.Services.LeaderboardService)
LeaderboardService.Init()

local MonetizationService = require(ServerScriptService.Services.Monetization.MonetizationService)
MonetizationService.Init()

Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	task.wait(1)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local data = DataService.GetFullData(player)
	if data then
		local coins = Instance.new("NumberValue")
		coins.Name = "Coins"
		coins.Value = data.Coins
		coins.Parent = leaderstats

		local pets = Instance.new("NumberValue")
		pets.Name = "Pets"
		local petCount = 0
		for _ in pairs(data.Pets) do petCount = petCount + 1 end
		pets.Value = petCount
		pets.Parent = leaderstats
	end

	-- Check daily reward
	DataService.CheckDailyReward(player)

	-- Start passive coin generation
	PetService.StartCoinGeneration(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do DataService.SavePlayer(p) end
	task.wait(3)
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, p in ipairs(Players:GetPlayers()) do DataService.SavePlayer(p) end
	end
end)

print("=== Pet Kingdom Tycoon - Ready! ===")
