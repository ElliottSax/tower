--[[
	GardenService.lua - Grow a World
	Core farming mechanics: planting, watering, growing, harvesting

	This is the HEART of the game - the main gameplay loop
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GardenService = {}
GardenService.DataService = nil
GardenService.PlayerGardens = {} -- [UserId] = { [BiomeName] = { Plots = {} } }
GardenService.GrowthTimers = {} -- Active growth timers

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GardenService.Init()
	print("[GardenService] Initializing...")

	local DataService = require(ServerScriptService.Services.DataService)
	GardenService.DataService = DataService

	GardenService.SetupRemotes()
	GardenService.StartGrowthLoop()

	print("[GardenService] Initialized")
end

function GardenService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Plant a seed
	remoteEvents:WaitForChild("PlantSeed").OnServerEvent:Connect(function(player, biome, plotIndex, seedName)
		GardenService.PlantSeed(player, biome, plotIndex, seedName)
	end)

	-- Water a plant
	remoteEvents:WaitForChild("WaterPlant").OnServerEvent:Connect(function(player, biome, plotIndex)
		GardenService.WaterPlant(player, biome, plotIndex)
	end)

	-- Harvest a plant
	remoteEvents:WaitForChild("HarvestPlant").OnServerEvent:Connect(function(player, biome, plotIndex)
		GardenService.HarvestPlant(player, biome, plotIndex)
	end)

	-- Harvest all mature plants
	remoteEvents:WaitForChild("HarvestAll").OnServerEvent:Connect(function(player, biome)
		GardenService.HarvestAll(player, biome)
	end)

	-- Get garden state (client request)
	remoteEvents:WaitForChild("GetGardenState").OnServerEvent:Connect(function(player)
		GardenService.SendGardenState(player)
	end)
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

function GardenService.SetupPlayer(player)
	local data = GardenService.DataService.GetFullData(player)
	if not data then return end

	-- Initialize gardens from saved data or create fresh
	GardenService.PlayerGardens[player.UserId] = data.Gardens or {}

	-- Ensure Meadow garden exists
	if not GardenService.PlayerGardens[player.UserId]["Meadow"] then
		GardenService.PlayerGardens[player.UserId]["Meadow"] = {
			Plots = {},
		}
	end

	-- Give starter seeds if new player
	if data.JoinCount <= 1 then
		GardenService.GiveStarterSeeds(player)
	end

	GardenService.SendGardenState(player)
end

function GardenService.CleanupPlayer(player)
	-- Save garden state to DataService before cleanup
	local gardens = GardenService.PlayerGardens[player.UserId]
	if gardens then
		GardenService.DataService.SetData(player, "Gardens", gardens)
	end
	GardenService.PlayerGardens[player.UserId] = nil
end

function GardenService.GiveStarterSeeds(player)
	local data = GardenService.DataService.GetFullData(player)
	if not data then return end

	data.SeedInventory = data.SeedInventory or {}

	-- Give 5 starter seeds
	local starterSeeds = {
		{ Name = "Daisy", Rarity = "Common", Biome = "Meadow", Count = 3 },
		{ Name = "Sunflower", Rarity = "Common", Biome = "Meadow", Count = 2 },
	}

	for _, seed in ipairs(starterSeeds) do
		table.insert(data.SeedInventory, seed)
	end

	print("[GardenService] Gave starter seeds to", player.Name)
end

-- ============================================================================
-- CORE MECHANICS
-- ============================================================================

function GardenService.PlantSeed(player, biomeName, plotIndex, seedName)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if not gardens then return false, "No garden data" end

	-- Validate biome is unlocked
	local data = GardenService.DataService.GetFullData(player)
	local unlockedBiomes = data.UnlockedBiomes or { "Meadow" }
	local biomeUnlocked = false
	for _, b in ipairs(unlockedBiomes) do
		if b == biomeName then biomeUnlocked = true break end
	end
	if not biomeUnlocked then return false, "Biome not unlocked" end

	-- Validate biome config
	local biomeConfig = GameConfig.Biomes[biomeName]
	if not biomeConfig then return false, "Invalid biome" end

	-- Check extra plots game pass
	local maxPlots = biomeConfig.PlotCount
	if data.GamePasses and data.GamePasses["ExtraPlots"] then
		maxPlots = maxPlots + 4
	end

	-- Validate plot index
	if plotIndex < 1 or plotIndex > maxPlots then return false, "Invalid plot" end

	-- Ensure garden exists for biome
	gardens[biomeName] = gardens[biomeName] or { Plots = {} }

	-- Check plot is empty
	if gardens[biomeName].Plots[tostring(plotIndex)] then
		return false, "Plot occupied"
	end

	-- Find seed in inventory
	local seedConfig = GardenService.FindSeedConfig(seedName)
	if not seedConfig then return false, "Unknown seed" end
	if seedConfig.Biome ~= biomeName then return false, "Wrong biome for seed" end

	-- Remove seed from inventory
	local removed = GardenService.RemoveSeedFromInventory(player, seedName, 1)
	if not removed then return false, "No seeds available" end

	-- Calculate grow time with bonuses
	local growTime = seedConfig.GrowTime

	-- Watering can speed boost
	local canLevel = data.WateringCanLevel or 1
	local canConfig = GameConfig.Tools.WateringCan.Levels[canLevel]
	if canConfig then
		growTime = growTime / canConfig.SpeedBoost
	end

	-- Biome growth multiplier
	growTime = growTime / biomeConfig.GrowthMultiplier

	-- Speed Grow game pass
	if data.GamePasses and data.GamePasses["SpeedGrow"] then
		growTime = growTime * 0.5
	end

	-- Plant the seed
	gardens[biomeName].Plots[tostring(plotIndex)] = {
		SeedName = seedName,
		Rarity = seedConfig.Rarity,
		PlantedAt = os.time(),
		GrowTime = math.max(5, math.floor(growTime)),
		Watered = false,
		Value = seedConfig.Value,
	}

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local updateRemote = remoteEvents:FindFirstChild("GardenUpdate")
		if updateRemote then
			updateRemote:FireClient(player, "planted", biomeName, plotIndex, gardens[biomeName].Plots[tostring(plotIndex)])
		end
	end

	print("[GardenService]", player.Name, "planted", seedName, "in", biomeName, "plot", plotIndex)
	return true
end

function GardenService.WaterPlant(player, biomeName, plotIndex)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if not gardens or not gardens[biomeName] then return false end

	local plot = gardens[biomeName].Plots[tostring(plotIndex)]
	if not plot then return false, "Empty plot" end
	if plot.Watered then return false, "Already watered" end

	-- Water reduces grow time by 20%
	plot.Watered = true
	plot.GrowTime = math.max(3, math.floor(plot.GrowTime * 0.8))

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local updateRemote = remoteEvents:FindFirstChild("GardenUpdate")
		if updateRemote then
			updateRemote:FireClient(player, "watered", biomeName, plotIndex, plot)
		end
	end

	return true
end

function GardenService.HarvestPlant(player, biomeName, plotIndex)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if not gardens or not gardens[biomeName] then return false end

	local plot = gardens[biomeName].Plots[tostring(plotIndex)]
	if not plot then return false, "Empty plot" end

	-- Check if mature
	local elapsed = os.time() - plot.PlantedAt
	if elapsed < plot.GrowTime then
		return false, "Not ready yet"
	end

	-- Calculate harvest value
	local value = plot.Value
	local data = GardenService.DataService.GetFullData(player)

	-- Fertilizer value boost
	local fertLevel = data.FertilizerLevel or 1
	local fertConfig = GameConfig.Tools.Fertilizer.Levels[fertLevel]
	if fertConfig then
		value = math.floor(value * fertConfig.ValueBoost)
	end

	-- Rarity multiplier
	local rarityConfig = GameConfig.Rarities[plot.Rarity]
	if rarityConfig then
		value = math.floor(value * rarityConfig.Multiplier)
	end

	-- Add coins
	local success, finalAmount = GardenService.DataService.AddCoins(player, value)

	-- Track statistics
	data.PlantsHarvested = (data.PlantsHarvested or 0) + 1

	-- Track rarest plant
	local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythical = 6, Divine = 7 }
	local currentRarest = rarityOrder[data.RarestPlantFound or "Common"] or 0
	local thisRarity = rarityOrder[plot.Rarity] or 0
	if thisRarity > currentRarest then
		data.RarestPlantFound = plot.Rarity
	end

	-- Chance for bonus seed drop
	GardenService.CheckBonusSeedDrop(player, plot.Rarity, biomeName)

	-- Clear the plot
	gardens[biomeName].Plots[tostring(plotIndex)] = nil

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local updateRemote = remoteEvents:FindFirstChild("GardenUpdate")
		if updateRemote then
			updateRemote:FireClient(player, "harvested", biomeName, plotIndex, {
				SeedName = plot.SeedName,
				Value = finalAmount or value,
				Rarity = plot.Rarity,
			})
		end
	end

	print("[GardenService]", player.Name, "harvested", plot.SeedName, "for", finalAmount or value, "coins")
	return true, finalAmount or value
end

function GardenService.HarvestAll(player, biomeName)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if not gardens or not gardens[biomeName] then return 0 end

	local totalHarvested = 0
	local totalValue = 0

	for plotIndex, plot in pairs(gardens[biomeName].Plots) do
		local elapsed = os.time() - plot.PlantedAt
		if elapsed >= plot.GrowTime then
			local success, value = GardenService.HarvestPlant(player, biomeName, tonumber(plotIndex))
			if success then
				totalHarvested = totalHarvested + 1
				totalValue = totalValue + (value or 0)
			end
		end
	end

	return totalHarvested, totalValue
end

-- ============================================================================
-- SEED MANAGEMENT
-- ============================================================================

function GardenService.FindSeedConfig(seedName)
	for _, seed in ipairs(GameConfig.Seeds) do
		if seed.Name == seedName then return seed end
	end
	return nil
end

function GardenService.RemoveSeedFromInventory(player, seedName, count)
	local data = GardenService.DataService.GetFullData(player)
	if not data or not data.SeedInventory then return false end

	for i, seed in ipairs(data.SeedInventory) do
		if seed.Name == seedName and seed.Count >= count then
			seed.Count = seed.Count - count
			if seed.Count <= 0 then
				table.remove(data.SeedInventory, i)
			end
			return true
		end
	end
	return false
end

function GardenService.AddSeedToInventory(player, seedName, rarity, biome, count)
	local data = GardenService.DataService.GetFullData(player)
	if not data then return false end
	data.SeedInventory = data.SeedInventory or {}

	-- Check if seed already in inventory
	for _, seed in ipairs(data.SeedInventory) do
		if seed.Name == seedName then
			seed.Count = seed.Count + count
			return true
		end
	end

	-- Add new entry
	table.insert(data.SeedInventory, {
		Name = seedName,
		Rarity = rarity,
		Biome = biome,
		Count = count,
	})
	return true
end

function GardenService.CheckBonusSeedDrop(player, harvestRarity, biomeName)
	-- 15% chance to get a bonus seed on harvest
	local dropChance = 0.15
	local data = GardenService.DataService.GetFullData(player)

	-- Luck boost game pass doubles chance
	if data.GamePasses and data.GamePasses["LuckBoost"] then
		dropChance = dropChance * 2
	end

	if math.random() > dropChance then return end

	-- Pick a random seed from the same biome
	local biomeSeedPool = {}
	for _, seed in ipairs(GameConfig.Seeds) do
		if seed.Biome == biomeName then
			local rarityConfig = GameConfig.Rarities[seed.Rarity]
			if rarityConfig then
				for _ = 1, rarityConfig.Weight do
					table.insert(biomeSeedPool, seed)
				end
			end
		end
	end

	if #biomeSeedPool == 0 then return end

	local bonusSeed = biomeSeedPool[math.random(#biomeSeedPool)]
	GardenService.AddSeedToInventory(player, bonusSeed.Name, bonusSeed.Rarity, bonusSeed.Biome, 1)

	-- Notify client of bonus seed
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notifyRemote = remoteEvents:FindFirstChild("Notification")
		if notifyRemote then
			notifyRemote:FireClient(player, "BonusSeed", {
				SeedName = bonusSeed.Name,
				Rarity = bonusSeed.Rarity,
			})
		end
	end
end

-- ============================================================================
-- GROWTH LOOP (Server-side tick for auto-harvest)
-- ============================================================================

function GardenService.StartGrowthLoop()
	task.spawn(function()
		while true do
			task.wait(5) -- Check every 5 seconds

			for userId, gardens in pairs(GardenService.PlayerGardens) do
				local player = game:GetService("Players"):GetPlayerByUserId(userId)
				if not player then continue end

				local data = GardenService.DataService.GetFullData(player)
				if not data then continue end

				-- Auto-harvest for game pass holders
				if data.GamePasses and data.GamePasses["AutoHarvest"] then
					for biomeName, garden in pairs(gardens) do
						for plotIndex, plot in pairs(garden.Plots) do
							local elapsed = os.time() - plot.PlantedAt
							if elapsed >= plot.GrowTime then
								GardenService.HarvestPlant(player, biomeName, tonumber(plotIndex))
							end
						end
					end
				end
			end
		end
	end)
end

-- ============================================================================
-- STATE SYNC
-- ============================================================================

function GardenService.SendGardenState(player)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if not gardens then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local stateRemote = remoteEvents:FindFirstChild("GardenState")
		if stateRemote then
			stateRemote:FireClient(player, gardens)
		end
	end
end

return GardenService
