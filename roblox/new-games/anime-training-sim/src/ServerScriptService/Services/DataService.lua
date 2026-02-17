--[[
	DataService.lua - Anime Training Simulator
	ProfileService-based data persistence with session locking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}

local PlayerData = {} -- [UserId] = data table
local dataStore = DataStoreService:GetDataStore("AnimeTrainingSim_v1")

function DataService.Init()
	print("[DataService] Initializing...")
	print("[DataService] Initialized")
end

function DataService.LoadPlayer(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync("Player_" .. userId)
	end)

	if success and data then
		-- Merge with defaults for new fields
		for key, default in pairs(GameConfig.DefaultData) do
			if data[key] == nil then
				data[key] = default
			end
		end
		PlayerData[userId] = data
	else
		-- New player - use defaults
		local newData = {}
		for key, value in pairs(GameConfig.DefaultData) do
			if type(value) == "table" then
				newData[key] = {}
				for k, v in pairs(value) do
					newData[key][k] = v
				end
			else
				newData[key] = value
			end
		end
		PlayerData[userId] = newData
	end

	print("[DataService] Loaded data for", player.Name)
end

function DataService.SavePlayer(player)
	local userId = player.UserId
	local data = PlayerData[userId]
	if not data then return end

	local success, err = pcall(function()
		dataStore:SetAsync("Player_" .. userId, data)
	end)

	if not success then
		warn("[DataService] Failed to save", player.Name, err)
	end
end

function DataService.GetFullData(player)
	return PlayerData[player.UserId]
end

function DataService.GetStat(player, stat)
	local data = PlayerData[player.UserId]
	if data then return data[stat] end
	return nil
end

function DataService.AddCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end

	-- Apply multipliers
	local mult = 1
	if data.GamePasses and data.GamePasses.DoubleCoins then
		mult = mult * 2
	end
	if data.GamePasses and data.GamePasses.VIP then
		mult = mult * 1.5
	end
	-- Rebirth bonus
	mult = mult * (1 + data.RebirthLevel * GameConfig.Rebirth.BoostPerLevel)

	local finalAmount = math.floor(amount * mult)
	data.Coins = data.Coins + finalAmount
	data.TotalCoinsEarned = data.TotalCoinsEarned + finalAmount

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then coinsValue.Value = data.Coins end
	end

	return finalAmount
end

function DataService.SpendCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return false end
	if data.Coins < amount then return false end

	data.Coins = data.Coins - amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then coinsValue.Value = data.Coins end
	end

	return true
end

function DataService.GetTotalPower(player)
	local data = PlayerData[player.UserId]
	if not data then return 0 end
	return data.Strength + data.Defense + data.Speed + data.Spirit
end

function DataService.UpdateLeaderstats(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local power = leaderstats:FindFirstChild("Power")
	if power then
		power.Value = data.Strength + data.Defense + data.Speed + data.Spirit
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then coins.Value = data.Coins end

	local rebirth = leaderstats:FindFirstChild("Rebirth")
	if rebirth then rebirth.Value = data.RebirthLevel end
end

function DataService.CleanupPlayer(player)
	PlayerData[player.UserId] = nil
end

return DataService
