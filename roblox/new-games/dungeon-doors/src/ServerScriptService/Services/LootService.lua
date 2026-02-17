--[[
	LootService.lua - Dungeon Doors
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local LootService = {}

function LootService.Init() print("[LootService] Initialized") end

function LootService.GenerateLoot(floor, lootLuck)
	local rarityWeights = {
		Common = 50, Uncommon = 25, Rare = 15, Epic = 7, Legendary = 2.5, Mythical = 0.5,
	}

	-- Apply luck
	for rarity, _ in pairs(rarityWeights) do
		if rarity ~= "Common" then
			rarityWeights[rarity] = rarityWeights[rarity] * (1 + lootLuck)
		end
	end

	-- Higher floors = better loot
	if floor > 20 then rarityWeights.Common = rarityWeights.Common * 0.5 end
	if floor > 50 then rarityWeights.Uncommon = rarityWeights.Uncommon * 0.7 end

	local total = 0
	for _, w in pairs(rarityWeights) do total = total + w end

	local roll = math.random() * total
	local cum = 0
	local chosenRarity = "Common"

	for _, r in ipairs({"Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}) do
		cum = cum + (rarityWeights[r] or 0)
		if roll <= cum then chosenRarity = r; break end
	end

	local valid = {}
	for _, w in ipairs(GameConfig.Weapons) do
		if w.Rarity == chosenRarity then table.insert(valid, w) end
	end
	if #valid == 0 then return nil end

	local weapon = valid[math.random(#valid)]
	return { Name = weapon.Name, Type = weapon.Type, Damage = weapon.Damage, Speed = weapon.Speed, Rarity = weapon.Rarity }
end

return LootService
