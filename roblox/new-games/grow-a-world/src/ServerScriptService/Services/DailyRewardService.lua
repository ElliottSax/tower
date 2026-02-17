--[[
	DailyRewardService.lua - Grow a World
	Login streak rewards to drive daily retention
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
	local lastLogin = data.LastLoginDate or ""

	if today == lastLogin then return end -- Already claimed today

	-- Check if streak continues or resets
	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	if lastLogin == yesterday then
		data.LoginStreak = (data.LoginStreak or 0) + 1
	else
		data.LoginStreak = 1
	end

	data.LastLoginDate = today

	-- Determine reward (cycle through 7-day rewards)
	local dayIndex = ((data.LoginStreak - 1) % 7) + 1
	local reward = GameConfig.DailyRewards[dayIndex]

	if not reward then return end

	-- Grant reward
	if reward.Reward == "Coins" then
		DailyRewardService.DataService.AddCoins(player, reward.Amount)
	elseif reward.Reward == "Seeds" then
		local GardenService = require(ServerScriptService.Services.GardenService)
		-- Give random seeds of the specified rarity
		local validSeeds = {}
		for _, seed in ipairs(GameConfig.Seeds) do
			if seed.Rarity == reward.Rarity then
				table.insert(validSeeds, seed)
			end
		end
		for _ = 1, reward.Amount do
			if #validSeeds > 0 then
				local picked = validSeeds[math.random(#validSeeds)]
				GardenService.AddSeedToInventory(player, picked.Name, picked.Rarity, picked.Biome, 1)
			end
		end
	end

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local dailyRemote = remoteEvents:FindFirstChild("DailyReward")
		if dailyRemote then
			dailyRemote:FireClient(player, {
				Day = dayIndex,
				Streak = data.LoginStreak,
				Reward = reward,
			})
		end
	end

	print("[DailyRewardService]", player.Name, "claimed day", dayIndex, "reward (streak:", data.LoginStreak, ")")
end

return DailyRewardService
