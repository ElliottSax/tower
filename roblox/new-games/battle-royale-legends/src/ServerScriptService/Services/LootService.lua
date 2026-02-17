--[[
	LootService.lua - Battle Royale Legends
	Handles ground loot spawning, chest loot, and loot drops
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local LootService = {}

function LootService.Init()
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("OpenChest").OnServerEvent:Connect(function(player, chestId)
		if type(chestId) ~= "string" then return end
		local CombatService = require(SSS.Services.CombatService)
		local loot = LootService.GenerateLoot(3)
		for _, item in ipairs(loot) do
			CombatService.AddToInventory(player, item.Name, item.Type)
		end
		re:FindFirstChild("LootDrop"):FireClient(player, loot)
	end)

	re:WaitForChild("PickupLoot").OnServerEvent:Connect(function(player, itemName, itemType)
		if type(itemName) ~= "string" or type(itemType) ~= "string" then return end
		local CombatService = require(SSS.Services.CombatService)
		CombatService.AddToInventory(player, itemName, itemType)
		re:FindFirstChild("LootDrop"):FireClient(player, {{ Name = itemName, Type = itemType }})
	end)
end

function LootService.GenerateLoot(count)
	local loot = {}
	for i = 1, count do
		local roll = math.random(1, 100)
		if roll <= 40 then
			-- Weapon
			local w = LootService.WeightedRandom(GC.Weapons)
			table.insert(loot, { Name = w.Name, Type = "Weapon", Rarity = w.Rarity, Damage = w.Damage })
		elseif roll <= 60 then
			-- Shield
			local s = LootService.WeightedRandom(GC.Shields)
			table.insert(loot, { Name = s.Name, Type = "Shield", Rarity = s.Rarity, Amount = s.Amount })
		elseif roll <= 80 then
			-- Heal
			local h = LootService.WeightedRandom(GC.Heals)
			table.insert(loot, { Name = h.Name, Type = "Heal", Rarity = h.Rarity, Amount = h.Amount })
		else
			-- Materials
			local m = LootService.WeightedRandom(GC.Materials)
			local amount = math.random(10, 50)
			table.insert(loot, { Name = m.Name, Type = "Material", Amount = amount })
		end
	end
	return loot
end

function LootService.WeightedRandom(items)
	local totalWeight = 0
	for _, item in ipairs(items) do totalWeight = totalWeight + (item.DropWeight or 10) end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, item in ipairs(items) do
		cumulative = cumulative + (item.DropWeight or 10)
		if roll <= cumulative then return item end
	end
	return items[#items]
end

return LootService
