--[[
	PrestigeService.lua - Treasure Hunt Islands
	Prestige resets islands for permanent treasure multipliers
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local PrestigeService = {}

local PRESTIGE_COSTS = {
	1000000, 5000000, 25000000, 100000000, 500000000,
	2000000000, 10000000000, 50000000000,
}

local PRESTIGE_REWARDS = {
	{ Level = 1, Bonus = "1.5x treasure value", Mult = 1.5 },
	{ Level = 2, Bonus = "2x treasure value", Mult = 2.0 },
	{ Level = 3, Bonus = "2.5x + lucky treasure", Mult = 2.5 },
	{ Level = 4, Bonus = "3x treasure value", Mult = 3.0 },
	{ Level = 5, Bonus = "4x + premium crew", Mult = 4.0 },
	{ Level = 6, Bonus = "5x treasure value", Mult = 5.0 },
	{ Level = 7, Bonus = "7x treasure value", Mult = 7.0 },
	{ Level = 8, Bonus = "10x + Golden Compass", Mult = 10.0 },
}

function PrestigeService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("Prestige").OnServerEvent:Connect(function(player)
		local data = DS.GetFullData(player); if not data then return end
		local nextLevel = (data.PrestigeLevel or 0) + 1
		if nextLevel > #PRESTIGE_COSTS then return end

		local cost = PRESTIGE_COSTS[nextLevel]
		if data.TotalCoinsEarned < cost then return end

		-- Reset progress, keep prestige and collection
		data.Coins = 500
		data.UnlockedIslands = { "Starter Beach" }
		data.CurrentIsland = "Starter Beach"
		data.CurrentTool = "Wooden Shovel"
		data.CurrentShip = "Rowboat"
		data.Treasures = {}
		data.Crew = {}
		data.PiratesDefeated = 0
		data.PrestigeLevel = nextLevel
		-- Keep: TreasureCollection, TotalCoinsEarned, TreasuresDug, GamePasses

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local pu = reEvents:FindFirstChild("PrestigeUpdate")
			if pu then pu:FireClient(player, {
				Level = nextLevel,
				Mult = PRESTIGE_REWARDS[nextLevel] and PRESTIGE_REWARDS[nextLevel].Mult or 1,
				Bonus = PRESTIGE_REWARDS[nextLevel] and PRESTIGE_REWARDS[nextLevel].Bonus or "",
			}) end
		end

		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end
		end
	end)

	re:WaitForChild("GetPrestigeInfo").OnServerEvent:Connect(function(player)
		local data = DS.GetFullData(player); if not data then return end
		local nextLevel = (data.PrestigeLevel or 0) + 1
		local cost = nextLevel <= #PRESTIGE_COSTS and PRESTIGE_COSTS[nextLevel] or 0
		local canPrestige = data.TotalCoinsEarned >= cost and nextLevel <= #PRESTIGE_COSTS

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local pu = reEvents:FindFirstChild("PrestigeUpdate")
			if pu then pu:FireClient(player, {
				CurrentLevel = data.PrestigeLevel or 0,
				NextCost = cost,
				CanPrestige = canPrestige,
				TotalEarned = data.TotalCoinsEarned,
				Rewards = PRESTIGE_REWARDS,
				CurrentMult = PRESTIGE_REWARDS[data.PrestigeLevel] and PRESTIGE_REWARDS[data.PrestigeLevel].Mult or 1,
			}) end
		end
	end)
end

return PrestigeService
