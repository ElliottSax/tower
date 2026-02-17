--[[
	DailyRewardService.lua - Treasure Hunt Islands
	7-day streak daily rewards with gold
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DailyRewardService = {}

local REWARDS = {
	{ Day = 1, Type = "Gold", Amount = 100 },
	{ Day = 2, Type = "Gold", Amount = 250 },
	{ Day = 3, Type = "Gold", Amount = 500 },
	{ Day = 4, Type = "Gold", Amount = 750 },
	{ Day = 5, Type = "Gold", Amount = 1200 },
	{ Day = 6, Type = "Gold", Amount = 2000 },
	{ Day = 7, Type = "Gold", Amount = 5000 },
}

function DailyRewardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("ClaimDaily").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local now = os.time()
		if (now - (data.LastDaily or 0)) < 72000 then return end
		if (now - (data.LastDaily or 0)) > 172800 then data.DailyStreak = 0 end
		data.DailyStreak = (data.DailyStreak or 0) + 1
		if data.DailyStreak > 7 then data.DailyStreak = 1 end
		data.LastDaily = now

		local reward = REWARDS[data.DailyStreak]
		if reward and reward.Type == "Gold" then DS.AddCoins(player, reward.Amount) end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local du = reEvents:FindFirstChild("DailyUpdate")
			if du then du:FireClient(player, { Day = data.DailyStreak, Reward = reward, Gold = data.Coins }) end
		end
	end)

	re:WaitForChild("GetDailyStatus").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local canClaim = (os.time() - (data.LastDaily or 0)) >= 72000
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local du = reEvents:FindFirstChild("DailyUpdate")
			if du then du:FireClient(player, { Streak = data.DailyStreak or 0, CanClaim = canClaim, Rewards = REWARDS }) end
		end
	end)
end

return DailyRewardService
