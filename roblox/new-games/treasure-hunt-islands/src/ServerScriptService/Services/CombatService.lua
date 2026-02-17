--[[
	CombatService.lua - Treasure Hunt Islands
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local CombatService = {}

function CombatService.Init()
	local DataService = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("FightPirate").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player); if not data then return end
		local island = nil
		for _, i in ipairs(GameConfig.Islands) do if i.Name == data.CurrentIsland then island = i; break end end
		if not island then return end

		-- Pick pirate based on difficulty
		local validPirates = {}
		for _, p in ipairs(GameConfig.Pirates) do
			if p.HP <= island.Difficulty * 100 then table.insert(validPirates, p) end
		end
		if #validPirates == 0 then validPirates = { GameConfig.Pirates[1] } end

		local pirate = validPirates[math.random(#validPirates)]
		local combatBonus = 1
		for _, c in ipairs(data.Crew) do
			for _, crew in ipairs(GameConfig.Crew) do
				if crew.Name == c and crew.Ability == "combat" then combatBonus = combatBonus * crew.Bonus end
			end
		end

		local won = math.random() < (0.5 + combatBonus * 0.1)
		if won then
			local reward = math.floor(pirate.Coins * island.Difficulty)
			DataService.AddCoins(player, reward)
			data.PiratesDefeated = data.PiratesDefeated + 1
			local reEvents = RS:FindFirstChild("RemoteEvents")
			if reEvents then local cr = reEvents:FindFirstChild("CombatResult"); if cr then cr:FireClient(player, { Won = true, Pirate = pirate.Name, Coins = reward }) end end
		else
			local reEvents = RS:FindFirstChild("RemoteEvents")
			if reEvents then local cr = reEvents:FindFirstChild("CombatResult"); if cr then cr:FireClient(player, { Won = false, Pirate = pirate.Name }) end end
		end
	end)
end

return CombatService
