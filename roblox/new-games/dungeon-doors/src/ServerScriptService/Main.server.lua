--[[
	Main.server.lua - Dungeon Doors
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

print("=== Dungeon Doors - Starting... ===")

local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

local DungeonService = require(ServerScriptService.Services.DungeonService)
DungeonService.Init()

local CombatService = require(ServerScriptService.Services.CombatService)
CombatService.Init()

local LootService = require(ServerScriptService.Services.LootService)
LootService.Init()

local SoulsShopService = require(ServerScriptService.Services.SoulsShopService)
SoulsShopService.Init()

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
		local souls = Instance.new("NumberValue")
		souls.Name = "Souls"
		souls.Value = data.Souls
		souls.Parent = leaderstats

		local floor = Instance.new("NumberValue")
		floor.Name = "Best Floor"
		floor.Value = data.HighestFloor
		floor.Parent = leaderstats
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do DataService.SavePlayer(p) end
	task.wait(3)
end)

print("=== Dungeon Doors - Ready! ===")
