--[[
	DataService.lua - Battle Royale Legends
	Player data persistence with DataStoreService
]]
local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local store = DSS:GetDataStore("BattleRoyaleV1")
local DataService = {}
local cache = {}

local DEFAULT = {
	Coins = 0,
	XP = 0,
	Wins = 0,
	Kills = 0,
	GamesPlayed = 0,
	BestPlacement = 999,
	OwnedSkins = { "Default" },
	EquippedSkin = "Default",
	DailyStreak = 0,
	LastDaily = 0,
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
					local t = {}; for i, x in ipairs(v) do t[i] = x end
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

function DataService.AddXP(player, amount)
	local data = cache[player.UserId]; if not data then return end
	data.XP = data.XP + amount
end

function DataService.RecordMatch(player, placement, kills)
	local data = cache[player.UserId]; if not data then return end
	data.GamesPlayed = data.GamesPlayed + 1
	data.Kills = data.Kills + kills
	if placement < data.BestPlacement then data.BestPlacement = placement end
	if placement == 1 then data.Wins = data.Wins + 1 end
end

return DataService
