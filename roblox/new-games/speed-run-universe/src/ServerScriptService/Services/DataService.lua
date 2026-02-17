--[[
	DataService.lua - Speed Run Universe
	Player data persistence using DataStoreService.
	Handles loading, saving, coin management, daily rewards, and data queries.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}
local PlayerData = {}  -- userId -> data table
local PlayerLoaded = {} -- userId -> boolean

local mainStore = DataStoreService:GetDataStore("SpeedRunUniverse_v1")
local ghostStore = DataStoreService:GetDataStore("SpeedRunUniverse_Ghosts_v1")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function DataService.Init()
	print("[DataService] Initialized")
end

-- ============================================================================
-- PLAYER DATA LOADING
-- ============================================================================
function DataService.LoadPlayer(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return mainStore:GetAsync(key)
	end)

	if success and data then
		-- Migrate: fill in any missing keys from DefaultData
		for k, defaultVal in pairs(GameConfig.DefaultData) do
			if data[k] == nil then
				if type(defaultVal) == "table" then
					data[k] = {}
					for dk, dv in pairs(defaultVal) do
						data[k][dk] = dv
					end
				else
					data[k] = defaultVal
				end
			end
		end
		PlayerData[userId] = data
	else
		-- New player: deep copy defaults
		local newData = {}
		for k, v in pairs(GameConfig.DefaultData) do
			if type(v) == "table" then
				newData[k] = {}
				for dk, dv in pairs(v) do
					newData[k][dk] = dv
				end
			else
				newData[k] = v
			end
		end
		PlayerData[userId] = newData
	end

	PlayerLoaded[userId] = true
	print("[DataService] Loaded data for", player.Name)
end

-- ============================================================================
-- PLAYER DATA SAVING
-- ============================================================================
function DataService.SavePlayer(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local success, err = pcall(function()
		mainStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("[DataService] Failed to save data for", player.Name, ":", err)
	end
end

function DataService.CleanupPlayer(player)
	DataService.SavePlayer(player)
	PlayerData[player.UserId] = nil
	PlayerLoaded[player.UserId] = nil
end

-- ============================================================================
-- DATA ACCESS
-- ============================================================================
function DataService.GetFullData(player)
	return PlayerData[player.UserId]
end

function DataService.IsLoaded(player)
	return PlayerLoaded[player.UserId] == true
end

-- ============================================================================
-- COIN MANAGEMENT
-- ============================================================================
function DataService.AddCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return 0 end

	-- Apply multipliers from game passes
	local multiplier = 1
	if data.GamePasses and data.GamePasses.DoubleCoins then
		multiplier = multiplier * 2
	end
	if data.GamePasses and data.GamePasses.VIP then
		multiplier = multiplier * GameConfig.GamePasses.VIP.CoinMultiplier
	end

	local finalAmount = math.floor(amount * multiplier)
	data.Coins = data.Coins + finalAmount
	data.TotalCoinsEarned = data.TotalCoinsEarned + finalAmount

	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then coinsVal.Value = data.Coins end
	end

	-- Fire coin sync to client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local coinSync = re:FindFirstChild("CoinSync")
		if coinSync then
			coinSync:FireClient(player, { Coins = data.Coins, Added = finalAmount })
		end
	end

	return finalAmount
end

function DataService.SpendCoins(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return false end
	if data.Coins < amount then return false end

	data.Coins = data.Coins - amount

	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then coinsVal.Value = data.Coins end
	end

	-- Fire coin sync to client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local coinSync = re:FindFirstChild("CoinSync")
		if coinSync then
			coinSync:FireClient(player, { Coins = data.Coins, Spent = amount })
		end
	end

	return true
end

function DataService.GetCoins(player)
	local data = PlayerData[player.UserId]
	return data and data.Coins or 0
end

-- ============================================================================
-- GHOST DATA (separate datastore to avoid size limits)
-- ============================================================================
function DataService.SaveGhostData(player, stageKey, ghostData)
	local ghostKey = "Ghost_" .. player.UserId .. "_" .. stageKey
	local success, err = pcall(function()
		ghostStore:SetAsync(ghostKey, ghostData)
	end)

	if success then
		local data = PlayerData[player.UserId]
		if data then
			data.GhostKeys[stageKey] = ghostKey
		end
	else
		warn("[DataService] Failed to save ghost for", player.Name, stageKey, ":", err)
	end

	return success
end

function DataService.LoadGhostData(player, stageKey)
	local data = PlayerData[player.UserId]
	if not data then return nil end

	local ghostKey = data.GhostKeys and data.GhostKeys[stageKey]
	if not ghostKey then return nil end

	local success, ghostData = pcall(function()
		return ghostStore:GetAsync(ghostKey)
	end)

	if success then
		return ghostData
	end
	return nil
end

-- ============================================================================
-- DAILY REWARD
-- ============================================================================
function DataService.CheckDailyReward(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local today = os.date("%Y-%m-%d")
	if today == data.LastLoginDate then return end

	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	if data.LastLoginDate == yesterday then
		data.LoginStreak = data.LoginStreak + 1
	else
		data.LoginStreak = 1
	end
	data.LastLoginDate = today

	local dayIndex = ((data.LoginStreak - 1) % 7) + 1
	local reward = GameConfig.DailyRewards[dayIndex]
	if not reward then return end

	-- Grant the reward
	if reward.Reward == "Coins" then
		DataService.AddCoins(player, reward.Amount)
	elseif reward.Reward == "Trail" then
		if not data.OwnedTrails then data.OwnedTrails = {} end
		data.OwnedTrails[reward.TrailId] = true
	elseif reward.Reward == "WinEffect" then
		if not data.OwnedWinEffects then data.OwnedWinEffects = {} end
		data.OwnedWinEffects[reward.EffectId] = true
	end

	-- Notify client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local dr = re:FindFirstChild("DailyReward")
		if dr then
			dr:FireClient(player, {
				Day = dayIndex,
				Streak = data.LoginStreak,
				Reward = reward,
			})
		end
	end
end

-- ============================================================================
-- PROGRESSION QUERIES
-- ============================================================================
function DataService.HasCompletedStage(player, worldId, stageNum)
	local data = PlayerData[player.UserId]
	if not data then return false end
	local key = worldId .. "_" .. tostring(stageNum)
	return data.CompletedStages[key] == true
end

function DataService.HasUnlockedWorld(player, worldId)
	local data = PlayerData[player.UserId]
	if not data then return false end
	for _, w in ipairs(data.UnlockedWorlds) do
		if w == worldId then return true end
	end
	return false
end

function DataService.GetPersonalBest(player, key)
	local data = PlayerData[player.UserId]
	if not data then return nil end
	return data.PersonalBests[key]
end

function DataService.SetPersonalBest(player, key, timeSeconds)
	local data = PlayerData[player.UserId]
	if not data then return false end

	local current = data.PersonalBests[key]
	if current == nil or timeSeconds < current then
		data.PersonalBests[key] = timeSeconds
		return true -- New PB
	end
	return false -- Not a PB
end

function DataService.GetSpeedMultiplier(player)
	local data = PlayerData[player.UserId]
	if not data then return 1 end

	local mult = 1
	if data.GamePasses and data.GamePasses.SpeedBoost then
		mult = mult * GameConfig.GamePasses.SpeedBoost.SpeedMultiplier
	end
	if data.GamePasses and data.GamePasses.VIP then
		mult = mult * GameConfig.GamePasses.VIP.SpeedMultiplier
	end
	return mult
end

return DataService
