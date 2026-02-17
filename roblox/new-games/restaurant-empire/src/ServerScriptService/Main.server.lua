--[[
	Main.server.lua - Restaurant Empire
]]
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

print("=== Restaurant Empire - Starting... ===")
require(SSS.Utilities.RemoteEventsInit).Init()
require(SSS.Security.SecurityManager).Init()
local DataService = require(SSS.Services.DataService); DataService.Init()
require(SSS.Services.RestaurantService).Init()
require(SSS.Services.CookingService).Init()
require(SSS.Services.CustomerService).Init()
require(SSS.Services.StaffService).Init()
require(SSS.Services.PrestigeService).Init()
require(SSS.Services.DailyRewardService).Init()
require(SSS.Services.LeaderboardService).Init()
require(SSS.Services.Monetization.MonetizationService).Init()

Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player); task.wait(1)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	local data = DataService.GetFullData(player)
	if data then
		local c = Instance.new("NumberValue"); c.Name = "Coins"; c.Value = data.Coins; c.Parent = ls
		local s = Instance.new("NumberValue"); s.Name = "Stars"; s.Value = data.StarRating; s.Parent = ls
	end
	require(SSS.Services.CustomerService).StartCustomerLoop(player)
end)

Players.PlayerRemoving:Connect(function(p) DataService.SavePlayer(p) end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do DataService.SavePlayer(p) end; task.wait(3) end)
print("=== Restaurant Empire - Ready! ===")
