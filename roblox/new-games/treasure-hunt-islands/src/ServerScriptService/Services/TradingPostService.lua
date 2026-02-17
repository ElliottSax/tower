--[[
	TradingPostService.lua - Treasure Hunt Islands
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local TradingPostService = {}

function TradingPostService.Init()
	local DataService = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetTradingPost").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player); if not data then return end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local tp = reEvents:FindFirstChild("TradingPostData")
			if tp then tp:FireClient(player, {
				Collection = data.TreasureCollection,
				Tools = GameConfig.Tools,
				CurrentTool = data.CurrentTool,
			}) end
		end
	end)
end

return TradingPostService
