--[[
	TreasureService.lua - Treasure Hunt Islands
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local TreasureService = {}

function TreasureService.Init()
	local DataService = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("Dig").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player); if not data then return end
		-- Get tool speed
		local digSpeed = 1
		for _, tool in ipairs(GameConfig.Tools) do
			if tool.Name == data.CurrentTool then digSpeed = tool.DigSpeed; break end
		end
		-- Get island difficulty for rarity weights
		local island = nil
		for _, i in ipairs(GameConfig.Islands) do if i.Name == data.CurrentIsland then island = i; break end end
		if not island then return end

		-- Roll treasure
		local luckMult = 1
		if data.GamePasses and data.GamePasses.DoubleTreasure then luckMult = 2 end

		local weights = { Common = 50, Uncommon = 25, Rare = 15, Epic = 7, Legendary = 2, Mythical = 1 }
		-- Higher difficulty = better loot
		weights.Common = weights.Common - island.Difficulty * 2
		weights.Rare = weights.Rare + island.Difficulty
		if weights.Common < 10 then weights.Common = 10 end

		for r, w in pairs(weights) do
			if r ~= "Common" and r ~= "Uncommon" then weights[r] = w * luckMult end
		end

		local total = 0; for _, w in pairs(weights) do total = total + w end
		local roll = math.random() * total; local cum = 0; local rarity = "Common"
		for _, r in ipairs({"Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}) do
			cum = cum + (weights[r] or 0)
			if roll <= cum then rarity = r; break end
		end

		local valid = {}
		for _, t in ipairs(GameConfig.Treasures) do if t.Rarity == rarity then table.insert(valid, t) end end
		if #valid == 0 then return end

		local treasure = valid[math.random(#valid)]
		local value = math.floor(treasure.Value * island.Difficulty)

		DataService.AddCoins(player, value)
		data.TreasuresDug = data.TreasuresDug + 1
		data.TreasureCollection[treasure.Name] = (data.TreasureCollection[treasure.Name] or 0) + 1

		local ls = player:FindFirstChild("leaderstats")
		if ls then local t = ls:FindFirstChild("Treasures"); if t then t.Value = data.TreasuresDug end end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local dr = reEvents:FindFirstChild("DigResult")
			if dr then dr:FireClient(player, { Name = treasure.Name, Rarity = treasure.Rarity, Value = value }) end
		end
	end)

	re:WaitForChild("BuyTool").OnServerEvent:Connect(function(player, toolName)
		if type(toolName) ~= "string" then return end
		local data = DataService.GetFullData(player); if not data then return end
		for _, tool in ipairs(GameConfig.Tools) do
			if tool.Name == toolName then
				if DataService.SpendCoins(player, tool.Cost) then data.CurrentTool = toolName end
				return
			end
		end
	end)

	re:WaitForChild("SellTreasure").OnServerEvent:Connect(function(player, treasureName, amount)
		if type(treasureName) ~= "string" or type(amount) ~= "number" then return end
		local data = DataService.GetFullData(player); if not data then return end
		local owned = data.TreasureCollection[treasureName] or 0
		if owned < amount then return end
		for _, t in ipairs(GameConfig.Treasures) do
			if t.Name == treasureName then
				data.TreasureCollection[treasureName] = owned - amount
				DataService.AddCoins(player, t.Value * amount)
				return
			end
		end
	end)
end

return TreasureService
