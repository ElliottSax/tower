--[[
	DailyRewardService.lua - Escape the Factory
	7-day streak daily rewards
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local DailyRewardService = {}

function DailyRewardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("ClaimDaily").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local now = os.time()
		local lastClaim = data.LastDaily or 0
		local elapsed = now - lastClaim

		if elapsed < 72000 then return end -- 20 hours minimum

		if elapsed > 172800 then data.DailyStreak = 0 end -- Reset if >48h gap
		data.DailyStreak = data.DailyStreak + 1
		if data.DailyStreak > 7 then data.DailyStreak = 1 end
		data.LastDaily = now

		local reward = GC.DailyRewards[data.DailyStreak]
		if reward then
			if reward.Reward == "Coins" then
				DS.AddCoins(player, reward.Amount)
			end
		end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local du = reEvents:FindFirstChild("DailyUpdate")
			if du then du:FireClient(player, {
				Type = "Claimed",
				Day = data.DailyStreak,
				Reward = reward,
				Coins = data.Coins,
			}) end
		end
	end)

	re:WaitForChild("GetDailyStatus").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local canClaim = (os.time() - (data.LastDaily or 0)) >= 72000
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local du = reEvents:FindFirstChild("DailyUpdate")
			if du then du:FireClient(player, {
				Type = "Status",
				Streak = data.DailyStreak,
				CanClaim = canClaim,
				Rewards = GC.DailyRewards,
			}) end
		end
	end)
end

return DailyRewardService
