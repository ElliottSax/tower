--[[
	PrestigeService.lua - Grow a World
	Rebirth/Prestige system - reset progress for permanent multipliers
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PrestigeService = {}
PrestigeService.DataService = nil

function PrestigeService.Init()
	print("[PrestigeService] Initializing...")
	PrestigeService.DataService = require(ServerScriptService.Services.DataService)
	PrestigeService.SetupRemotes()
	print("[PrestigeService] Initialized")
end

function PrestigeService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("Prestige").OnServerEvent:Connect(function(player)
		PrestigeService.DoPrestige(player)
	end)

	remoteEvents:WaitForChild("GetPrestigeInfo").OnServerEvent:Connect(function(player)
		PrestigeService.SendPrestigeInfo(player)
	end)
end

function PrestigeService.DoPrestige(player)
	local data = PrestigeService.DataService.GetFullData(player)
	if not data then return false, "No data" end

	local currentLevel = data.PrestigeLevel or 0
	if currentLevel >= GameConfig.Prestige.MaxLevel then
		return false, "Max prestige reached"
	end

	-- Check coin requirement (scales with prestige level)
	local requiredCoins = GameConfig.Prestige.RequiredCoins * (1 + currentLevel * 0.5)
	if data.Coins < requiredCoins then
		return false, "Not enough coins (need " .. math.floor(requiredCoins) .. ")"
	end

	-- Prestige! Reset progress but keep permanent bonuses
	local newLevel = currentLevel + 1

	-- Reset
	data.Coins = 0
	data.SeedInventory = {}
	data.HarvestedPlants = {}
	data.WateringCanLevel = 1
	data.FertilizerLevel = 1
	data.UnlockedBiomes = { "Meadow" }

	-- Clear gardens
	local GardenService = require(ServerScriptService.Services.GardenService)
	GardenService.PlayerGardens[player.UserId] = {
		Meadow = { Plots = {} },
	}

	-- Set new prestige level
	data.PrestigeLevel = newLevel

	-- Check for prestige rewards
	local reward = GameConfig.Prestige.Rewards[newLevel]

	-- Give starter seeds again
	GardenService.GiveStarterSeeds(player)

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then coinsValue.Value = 0 end
		local prestigeValue = leaderstats:FindFirstChild("Prestige")
		if prestigeValue then prestigeValue.Value = newLevel end
	end

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local prestigeRemote = remoteEvents:FindFirstChild("PrestigeComplete")
		if prestigeRemote then
			prestigeRemote:FireClient(player, {
				NewLevel = newLevel,
				Multiplier = 1 + (newLevel * GameConfig.Prestige.Multiplier),
				Reward = reward,
			})
		end
	end

	print("[PrestigeService]", player.Name, "prestiged to level", newLevel)
	return true
end

function PrestigeService.SendPrestigeInfo(player)
	local data = PrestigeService.DataService.GetFullData(player)
	if not data then return end

	local currentLevel = data.PrestigeLevel or 0
	local requiredCoins = GameConfig.Prestige.RequiredCoins * (1 + currentLevel * 0.5)

	local info = {
		CurrentLevel = currentLevel,
		MaxLevel = GameConfig.Prestige.MaxLevel,
		CurrentMultiplier = 1 + (currentLevel * GameConfig.Prestige.Multiplier),
		NextMultiplier = 1 + ((currentLevel + 1) * GameConfig.Prestige.Multiplier),
		RequiredCoins = math.floor(requiredCoins),
		CurrentCoins = data.Coins,
		CanPrestige = data.Coins >= requiredCoins and currentLevel < GameConfig.Prestige.MaxLevel,
		NextReward = GameConfig.Prestige.Rewards[currentLevel + 1],
		AllRewards = GameConfig.Prestige.Rewards,
	}

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local prestigeInfoRemote = remoteEvents:FindFirstChild("PrestigeInfo")
		if prestigeInfoRemote then
			prestigeInfoRemote:FireClient(player, info)
		end
	end
end

return PrestigeService
