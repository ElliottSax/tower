--[[
	DataService.lua - Pet Kingdom Tycoon
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}
local PlayerData = {}
local dataStore = DataStoreService:GetDataStore("PetKingdomTycoon_v1")

function DataService.Init() print("[DataService] Initialized") end

function DataService.LoadPlayer(player)
	local userId = player.UserId
	local success, data = pcall(function() return dataStore:GetAsync("Player_" .. userId) end)

	if success and data then
		for key, default in pairs(GameConfig.DefaultData) do
			if data[key] == nil then data[key] = default end
		end
		PlayerData[userId] = data
	else
		local newData = {}
		for key, value in pairs(GameConfig.DefaultData) do
			if type(value) == "table" then
				newData[key] = {}
				for k, v in pairs(value) do newData[key][k] = v end
			else newData[key] = value end
		end
		PlayerData[userId] = newData
	end
end

function DataService.SavePlayer(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	pcall(function() dataStore:SetAsync("Player_" .. player.UserId, data) end)
end

function DataService.GetFullData(player) return PlayerData[player.UserId] end

function DataService.AddCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	local mult = 1
	if data.GamePasses and data.GamePasses.VIP then mult = mult * 2 end
	mult = mult * (1 + data.PrestigeLevel * GameConfig.Prestige.BoostPerLevel)
	local final = math.floor(amount * mult)
	data.Coins = data.Coins + final
	data.TotalCoinsEarned = data.TotalCoinsEarned + final
	local ls = player:FindFirstChild("leaderstats")
	if ls then local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end end
	return final
end

function DataService.SpendCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data or data.Coins < amount then return false end
	data.Coins = data.Coins - amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end end
	return true
end

function DataService.CheckDailyReward(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	local today = os.date("%Y-%m-%d")
	if today == data.LastLoginDate then return end
	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	data.LoginStreak = (data.LastLoginDate == yesterday) and (data.LoginStreak + 1) or 1
	data.LastLoginDate = today
	local dayIndex = ((data.LoginStreak - 1) % 7) + 1
	local reward = GameConfig.DailyRewards[dayIndex]
	if not reward then return end
	if reward.Reward == "Coins" then DataService.AddCoins(player, reward.Amount) end
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then local dr = re:FindFirstChild("DailyReward"); if dr then dr:FireClient(player, { Day = dayIndex, Streak = data.LoginStreak, Reward = reward }) end end
end

return DataService
