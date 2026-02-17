--[[
	DataService.lua - Treasure Hunt Islands
]]
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS.Shared.Config.GameConfig)
local DataService = {}
local PlayerData = {}
local ds = DSS:GetDataStore("TreasureHuntIslands_v1")

function DataService.Init() end

function DataService.LoadPlayer(player)
	local ok, data = pcall(function() return ds:GetAsync("P_" .. player.UserId) end)
	if ok and data then
		for k, v in pairs(GameConfig.DefaultData) do if data[k] == nil then data[k] = v end end
		PlayerData[player.UserId] = data
	else
		local d = {}; for k, v in pairs(GameConfig.DefaultData) do
			if type(v) == "table" then d[k] = {}; for k2, v2 in pairs(v) do d[k][k2] = v2 end
			else d[k] = v end
		end; PlayerData[player.UserId] = d
	end
end

function DataService.SavePlayer(player)
	local data = PlayerData[player.UserId]; if not data then return end
	pcall(function() ds:SetAsync("P_" .. player.UserId, data) end)
end

function DataService.GetFullData(player) return PlayerData[player.UserId] end

function DataService.AddCoins(player, amount)
	local data = PlayerData[player.UserId]; if not data then return 0 end
	local mult = 1 + data.PrestigeLevel * 0.25
	local final = math.floor(amount * mult)
	data.Coins = data.Coins + final; data.TotalCoinsEarned = data.TotalCoinsEarned + final
	local ls = player:FindFirstChild("leaderstats")
	if ls then local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end end
	return final
end

function DataService.SpendCoins(player, amount)
	local data = PlayerData[player.UserId]; if not data or data.Coins < amount then return false end
	data.Coins = data.Coins - amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end end
	return true
end

return DataService
