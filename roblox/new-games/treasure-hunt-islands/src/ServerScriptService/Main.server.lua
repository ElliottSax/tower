--[[
	Main.server.lua - Treasure Hunt Islands
]]
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

print("=== Treasure Hunt Islands - Starting... ===")

require(SSS.Utilities.RemoteEventsInit).Init()
require(SSS.Security.SecurityManager).Init()

local DataService = require(SSS.Services.DataService)
DataService.Init()
require(SSS.Services.IslandService).Init()
require(SSS.Services.TreasureService).Init()
require(SSS.Services.ShipService).Init()
require(SSS.Services.CombatService).Init()
require(SSS.Services.TradingPostService).Init()
require(SSS.Services.PrestigeService).Init()
require(SSS.Services.DailyRewardService).Init()
require(SSS.Services.LeaderboardService).Init()
require(SSS.Services.Monetization.MonetizationService).Init()

Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	task.wait(1)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	local data = DataService.GetFullData(player)
	if data then
		local c = Instance.new("NumberValue"); c.Name = "Coins"; c.Value = data.Coins; c.Parent = ls
		local t = Instance.new("NumberValue"); t.Name = "Treasures"; t.Value = data.TreasuresDug; t.Parent = ls
	end
end)

Players.PlayerRemoving:Connect(function(p) DataService.SavePlayer(p) end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do DataService.SavePlayer(p) end; task.wait(3) end)
print("=== Treasure Hunt Islands - Ready! ===")
