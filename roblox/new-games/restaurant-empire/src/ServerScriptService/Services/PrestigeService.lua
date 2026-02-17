--[[
	PrestigeService.lua - Restaurant Empire
	Prestige resets restaurant for permanent earning multipliers
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local PrestigeService = {}

local PRESTIGE_COSTS = {
	500000, 2000000, 8000000, 30000000, 100000000,
	500000000, 2000000000, 10000000000,
}

local PRESTIGE_REWARDS = {
	{ Level = 1, Bonus = "1.3x earnings", Mult = 1.3 },
	{ Level = 2, Bonus = "1.6x earnings", Mult = 1.6 },
	{ Level = 3, Bonus = "2x earnings + unlock recipe", Mult = 2.0 },
	{ Level = 4, Bonus = "2.5x earnings", Mult = 2.5 },
	{ Level = 5, Bonus = "3x earnings + VIP decor", Mult = 3.0 },
	{ Level = 6, Bonus = "4x earnings", Mult = 4.0 },
	{ Level = 7, Bonus = "5x earnings", Mult = 5.0 },
	{ Level = 8, Bonus = "7x earnings + Golden Chef", Mult = 7.0 },
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

		-- Reset progress, keep prestige
		data.Coins = 500
		data.Level = 1
		data.XP = 0
		data.UnlockedLocations = { "Food Cart" }
		data.CurrentLocation = "Food Cart"
		data.UnlockedRecipes = { "Burger", "Fries" }
		data.Furniture = {}
		data.Staff = {}
		data.CustomersServed = 0
		data.StarRating = 1
		data.Satisfaction = 50
		data.PrestigeLevel = nextLevel

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local pu = reEvents:FindFirstChild("PrestigeUpdate")
			if pu then pu:FireClient(player, {
				Level = nextLevel,
				Mult = PRESTIGE_REWARDS[nextLevel] and PRESTIGE_REWARDS[nextLevel].Mult or 1,
				Bonus = PRESTIGE_REWARDS[nextLevel] and PRESTIGE_REWARDS[nextLevel].Bonus or "",
			}) end
		end

		-- Update leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local c = ls:FindFirstChild("Coins"); if c then c.Value = data.Coins end
			local s = ls:FindFirstChild("Stars"); if s then s.Value = data.StarRating end
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
