--[[
	SeedService.lua - Grow a World
	Seed shop, random seed packs, seed discovery

	Handles buying seeds, opening random packs, and tracking collection
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SeedService = {}
SeedService.DataService = nil

function SeedService.Init()
	print("[SeedService] Initializing...")

	local DataService = require(ServerScriptService.Services.DataService)
	SeedService.DataService = DataService

	SeedService.SetupRemotes()
	print("[SeedService] Initialized with", #GameConfig.Seeds, "seed types")
end

function SeedService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("BuySeed").OnServerEvent:Connect(function(player, seedName, quantity)
		SeedService.BuySeed(player, seedName, quantity or 1)
	end)

	remoteEvents:WaitForChild("BuySeedPack").OnServerEvent:Connect(function(player, packType)
		SeedService.BuySeedPack(player, packType)
	end)

	remoteEvents:WaitForChild("GetSeedShop").OnServerEvent:Connect(function(player)
		SeedService.SendSeedShop(player)
	end)
end

-- ============================================================================
-- SEED SHOP
-- ============================================================================

-- Calculate buy price (3x the harvest value)
function SeedService.GetSeedPrice(seedConfig)
	local rarityConfig = GameConfig.Rarities[seedConfig.Rarity]
	local basePrice = seedConfig.Value * 3
	return math.floor(basePrice)
end

function SeedService.BuySeed(player, seedName, quantity)
	quantity = math.clamp(quantity or 1, 1, 99)

	local seedConfig = nil
	for _, seed in ipairs(GameConfig.Seeds) do
		if seed.Name == seedName then
			seedConfig = seed
			break
		end
	end

	if not seedConfig then return false, "Unknown seed" end

	-- Check biome unlocked
	local data = SeedService.DataService.GetFullData(player)
	if not data then return false, "No data" end

	local unlocked = false
	for _, b in ipairs(data.UnlockedBiomes or {}) do
		if b == seedConfig.Biome then unlocked = true break end
	end
	if not unlocked then return false, "Biome locked" end

	-- Calculate cost
	local unitPrice = SeedService.GetSeedPrice(seedConfig)
	local totalCost = unitPrice * quantity

	-- Check and deduct coins
	if not SeedService.DataService.RemoveCoins(player, totalCost) then
		return false, "Not enough coins"
	end

	-- Add seeds to inventory
	local GardenService = require(ServerScriptService.Services.GardenService)
	GardenService.AddSeedToInventory(player, seedConfig.Name, seedConfig.Rarity, seedConfig.Biome, quantity)

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notifyRemote = remoteEvents:FindFirstChild("Notification")
		if notifyRemote then
			notifyRemote:FireClient(player, "SeedPurchase", {
				SeedName = seedConfig.Name,
				Quantity = quantity,
				Cost = totalCost,
			})
		end
	end

	print("[SeedService]", player.Name, "bought", quantity, "x", seedName, "for", totalCost, "coins")
	return true
end

-- ============================================================================
-- SEED PACKS (Gacha-style random seeds)
-- ============================================================================

local SEED_PACKS = {
	Basic = {
		Cost = 100,
		SeedCount = 3,
		MinRarity = "Common",
		MaxRarity = "Rare",
		Description = "3 random seeds (Common to Rare)",
	},
	Premium = {
		Cost = 500,
		SeedCount = 3,
		MinRarity = "Uncommon",
		MaxRarity = "Epic",
		Description = "3 random seeds (Uncommon to Epic)",
	},
	Legendary = {
		Cost = 2500,
		SeedCount = 3,
		MinRarity = "Rare",
		MaxRarity = "Legendary",
		Description = "3 random seeds (Rare to Legendary)",
	},
	Mythical = {
		Cost = 15000,
		SeedCount = 3,
		MinRarity = "Epic",
		MaxRarity = "Mythical",
		Description = "3 random seeds (Epic to Mythical)",
	},
	Divine = {
		Cost = 100000,
		SeedCount = 3,
		MinRarity = "Legendary",
		MaxRarity = "Divine",
		Description = "3 random seeds (Legendary to Divine)",
	},
}

function SeedService.BuySeedPack(player, packType)
	local pack = SEED_PACKS[packType]
	if not pack then return false, "Unknown pack" end

	local data = SeedService.DataService.GetFullData(player)
	if not data then return false, "No data" end

	if not SeedService.DataService.RemoveCoins(player, pack.Cost) then
		return false, "Not enough coins"
	end

	-- Determine valid rarity range
	local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine" }
	local minIndex, maxIndex = 1, #rarityOrder
	for i, r in ipairs(rarityOrder) do
		if r == pack.MinRarity then minIndex = i end
		if r == pack.MaxRarity then maxIndex = i end
	end

	-- Build weighted pool from valid seeds
	local validSeeds = {}
	for _, seed in ipairs(GameConfig.Seeds) do
		local seedRarityIndex = 0
		for i, r in ipairs(rarityOrder) do
			if r == seed.Rarity then seedRarityIndex = i break end
		end

		if seedRarityIndex >= minIndex and seedRarityIndex <= maxIndex then
			local rarityConfig = GameConfig.Rarities[seed.Rarity]
			if rarityConfig then
				-- Apply luck boost
				local weight = rarityConfig.Weight
				if data.GamePasses and data.GamePasses["LuckBoost"] then
					-- Increase weight of rarer items
					if seedRarityIndex > 3 then
						weight = weight * 2
					end
				end
				for _ = 1, weight do
					table.insert(validSeeds, seed)
				end
			end
		end
	end

	if #validSeeds == 0 then
		-- Refund if no valid seeds
		SeedService.DataService.AddCoins(player, pack.Cost)
		return false, "No seeds available"
	end

	-- Roll seeds
	local results = {}
	local GardenService = require(ServerScriptService.Services.GardenService)

	for _ = 1, pack.SeedCount do
		local rolled = validSeeds[math.random(#validSeeds)]
		GardenService.AddSeedToInventory(player, rolled.Name, rolled.Rarity, rolled.Biome, 1)
		table.insert(results, {
			Name = rolled.Name,
			Rarity = rolled.Rarity,
			Biome = rolled.Biome,
		})
	end

	-- Notify client with results (for reveal animation)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local packResultRemote = remoteEvents:FindFirstChild("SeedPackResult")
		if packResultRemote then
			packResultRemote:FireClient(player, packType, results)
		end
	end

	print("[SeedService]", player.Name, "opened", packType, "pack:", #results, "seeds")
	return true, results
end

-- ============================================================================
-- SEED SHOP DATA
-- ============================================================================

function SeedService.SendSeedShop(player)
	local data = SeedService.DataService.GetFullData(player)
	if not data then return end

	local shopData = {
		Seeds = {},
		Packs = SEED_PACKS,
	}

	-- Build available seeds list (only from unlocked biomes)
	for _, seed in ipairs(GameConfig.Seeds) do
		local unlocked = false
		for _, b in ipairs(data.UnlockedBiomes or {}) do
			if b == seed.Biome then unlocked = true break end
		end
		if unlocked then
			table.insert(shopData.Seeds, {
				Name = seed.Name,
				Biome = seed.Biome,
				Rarity = seed.Rarity,
				GrowTime = seed.GrowTime,
				Value = seed.Value,
				Price = SeedService.GetSeedPrice(seed),
				Description = seed.Description,
			})
		end
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local shopRemote = remoteEvents:FindFirstChild("SeedShopData")
		if shopRemote then
			shopRemote:FireClient(player, shopData)
		end
	end
end

return SeedService
