--[[
	DailyRewardService.lua - Pet Kingdom Tycoon
	7-day streak daily rewards with coins and eggs
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DailyRewardService = {}

local REWARDS = {
	{ Day = 1, Type = "Coins", Amount = 200 },
	{ Day = 2, Type = "Coins", Amount = 400 },
	{ Day = 3, Type = "Egg", EggType = "Forest Egg", Amount = 1 },
	{ Day = 4, Type = "Coins", Amount = 800 },
	{ Day = 5, Type = "Coins", Amount = 1200 },
	{ Day = 6, Type = "Egg", EggType = "Ocean Egg", Amount = 1 },
	{ Day = 7, Type = "Coins", Amount = 2500 },
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
		if reward then
			if reward.Type == "Coins" then DS.AddCoins(player, reward.Amount) end
		end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local du = reEvents:FindFirstChild("DailyUpdate")
			if du then du:FireClient(player, { Day = data.DailyStreak, Reward = reward, Coins = data.Coins }) end
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
