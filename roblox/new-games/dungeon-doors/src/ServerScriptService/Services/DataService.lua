--[[
	DataService.lua - Dungeon Doors
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}
local PlayerData = {}
local dataStore = DataStoreService:GetDataStore("DungeonDoors_v1")

function DataService.Init() print("[DataService] Initialized") end

function DataService.LoadPlayer(player)
	local success, data = pcall(function() return dataStore:GetAsync("Player_" .. player.UserId) end)
	if success and data then
		for key, default in pairs(GameConfig.DefaultData) do
			if data[key] == nil then data[key] = default end
		end
		PlayerData[player.UserId] = data
	else
		local newData = {}
		for key, value in pairs(GameConfig.DefaultData) do
			if type(value) == "table" then newData[key] = {} for k,v in pairs(value) do newData[key][k] = v end
			else newData[key] = value end
		end
		PlayerData[player.UserId] = newData
	end
end

function DataService.SavePlayer(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	pcall(function() dataStore:SetAsync("Player_" .. player.UserId, data) end)
end

function DataService.GetFullData(player) return PlayerData[player.UserId] end

function DataService.AddSouls(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return 0 end
	local mult = 1
	if data.GamePasses and data.GamePasses.DoubleSouls then mult = 2 end
	-- Soul magnet upgrade
	for _, upgrade in pairs(data.Upgrades or {}) do
		if upgrade.Effect == "soul_mult" then mult = mult + upgrade.Amount * upgrade.Level end
	end
	local final = math.floor(amount * mult)
	data.Souls = data.Souls + final
	data.TotalSoulsEarned = data.TotalSoulsEarned + final
	local ls = player:FindFirstChild("leaderstats")
	if ls then local s = ls:FindFirstChild("Souls"); if s then s.Value = data.Souls end end
	return final
end

function DataService.SpendSouls(player, amount)
	local data = PlayerData[player.UserId]
	if not data or data.Souls < amount then return false end
	data.Souls = data.Souls - amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then local s = ls:FindFirstChild("Souls"); if s then s.Value = data.Souls end end
	return true
end

return DataService
