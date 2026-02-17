--[[
	DailyRewardService.lua - Anime Training Simulator
	Login streak rewards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DailyRewardService = {}
DailyRewardService.DataService = nil

function DailyRewardService.Init()
	print("[DailyRewardService] Initializing...")
	DailyRewardService.DataService = require(ServerScriptService.Services.DataService)
	print("[DailyRewardService] Initialized")
end

function DailyRewardService.CheckDailyReward(player)
	local data = DailyRewardService.DataService.GetFullData(player)
	if not data then return end

	local today = os.date("%Y-%m-%d")
	if today == data.LastLoginDate then return end

	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	if data.LastLoginDate == yesterday then
		data.LoginStreak = (data.LoginStreak or 0) + 1
	else
		data.LoginStreak = 1
	end

	data.LastLoginDate = today

	local dayIndex = ((data.LoginStreak - 1) % 7) + 1
	local reward = GameConfig.DailyRewards[dayIndex]
	if not reward then return end

	if reward.Reward == "Coins" then
		DailyRewardService.DataService.AddCoins(player, reward.Amount)
	elseif reward.Reward == "Egg" then
		-- Give a free egg hatch
		local PetService = require(ServerScriptService.Services.PetService)
		PetService.HatchEgg(player, reward.EggType)
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local dailyReward = remoteEvents:FindFirstChild("DailyReward")
		if dailyReward then
			dailyReward:FireClient(player, {
				Day = dayIndex,
				Streak = data.LoginStreak,
				Reward = reward,
			})
		end
	end
end

return DailyRewardService
