--[[
	DataService.lua - Escape the Factory
	Player data persistence with DataStoreService
]]
local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local store = DSS:GetDataStore("EscapeFactoryV1")
local DataService = {}
local cache = {}

local DEFAULT = {
	Coins = 0,
	TotalEscapes = 0,
	UnlockedFactories = { "Toy Factory" },
	FactoryStars = {},
	BestTimes = {},
	Upgrades = {},
	OwnedCompanions = {},
	EquippedCompanion = "",
	Collectibles = { Bronze = 0, Silver = 0, Gold = 0, Diamond = 0, Void = 0 },
	DailyStreak = 0,
	LastDaily = 0,
	Deaths = 0,
}

function DataService.Init()
	Players.PlayerAdded:Connect(function(p)
		local ok, data = pcall(function() return store:GetAsync("player_" .. p.UserId) end)
		if ok and data then
			for k, v in pairs(DEFAULT) do if data[k] == nil then data[k] = v end end
			cache[p.UserId] = data
		else
			cache[p.UserId] = {}
			for k, v in pairs(DEFAULT) do
				if type(v) == "table" then
					local t = {}
					if #v > 0 then for i, x in ipairs(v) do t[i] = x end
					else for kk, vv in pairs(v) do t[kk] = vv end end
					cache[p.UserId][k] = t
				else
					cache[p.UserId][k] = v
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p) DataService.Save(p); cache[p.UserId] = nil end)
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do DataService.Save(p) end
	end)
end

function DataService.Save(player)
	local data = cache[player.UserId]; if not data then return end
	pcall(function() store:SetAsync("player_" .. player.UserId, data) end)
end

function DataService.GetData(player) return cache[player.UserId] end

function DataService.AddCoins(player, amount)
	local data = cache[player.UserId]; if not data then return end
	data.Coins = data.Coins + amount
end

function DataService.SpendCoins(player, amount)
	local data = cache[player.UserId]; if not data then return false end
	if data.Coins < amount then return false end
	data.Coins = data.Coins - amount; return true
end

function DataService.GetUpgradeLevel(player, upgradeName)
	local data = cache[player.UserId]; if not data then return 0 end
	return data.Upgrades[upgradeName] or 0
end

function DataService.SetUpgradeLevel(player, upgradeName, level)
	local data = cache[player.UserId]; if not data then return end
	data.Upgrades[upgradeName] = level
end

return DataService
