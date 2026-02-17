--[[
	BiomeService.lua - Grow a World
	Manages biome unlocking, teleportation, and biome-specific mechanics
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local BiomeService = {}
BiomeService.DataService = nil

function BiomeService.Init()
	print("[BiomeService] Initializing...")
	BiomeService.DataService = require(ServerScriptService.Services.DataService)
	BiomeService.SetupRemotes()
	print("[BiomeService] Initialized with", BiomeService.CountBiomes(), "biomes")
end

function BiomeService.CountBiomes()
	local count = 0
	for _ in pairs(GameConfig.Biomes) do count = count + 1 end
	return count
end

function BiomeService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("UnlockBiome").OnServerEvent:Connect(function(player, biomeName)
		BiomeService.UnlockBiome(player, biomeName)
	end)

	remoteEvents:WaitForChild("TeleportToBiome").OnServerEvent:Connect(function(player, biomeName)
		BiomeService.TeleportToBiome(player, biomeName)
	end)

	remoteEvents:WaitForChild("GetBiomeInfo").OnServerEvent:Connect(function(player)
		BiomeService.SendBiomeInfo(player)
	end)
end

function BiomeService.UnlockBiome(player, biomeName)
	local biomeConfig = GameConfig.Biomes[biomeName]
	if not biomeConfig then return false, "Invalid biome" end

	local data = BiomeService.DataService.GetFullData(player)
	if not data then return false, "No data" end

	-- Check already unlocked
	for _, b in ipairs(data.UnlockedBiomes or {}) do
		if b == biomeName then return false, "Already unlocked" end
	end

	-- Check prerequisite (must unlock biomes in order)
	local previousBiomeUnlocked = true
	for name, config in pairs(GameConfig.Biomes) do
		if config.Order == biomeConfig.Order - 1 then
			local found = false
			for _, b in ipairs(data.UnlockedBiomes or {}) do
				if b == name then found = true break end
			end
			if not found then
				previousBiomeUnlocked = false
				break
			end
		end
	end

	if not previousBiomeUnlocked then
		return false, "Must unlock previous biome first"
	end

	-- Check cost
	if biomeConfig.UnlockCost > 0 then
		if not BiomeService.DataService.RemoveCoins(player, biomeConfig.UnlockCost) then
			return false, "Not enough coins"
		end
	end

	-- Unlock biome
	data.UnlockedBiomes = data.UnlockedBiomes or {}
	table.insert(data.UnlockedBiomes, biomeName)

	-- Initialize garden for new biome
	local GardenService = require(ServerScriptService.Services.GardenService)
	local gardens = GardenService.PlayerGardens[player.UserId]
	if gardens then
		gardens[biomeName] = { Plots = {} }
	end

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notifyRemote = remoteEvents:FindFirstChild("Notification")
		if notifyRemote then
			notifyRemote:FireClient(player, "BiomeUnlocked", {
				BiomeName = biomeName,
				PlotCount = biomeConfig.PlotCount,
				GrowthMultiplier = biomeConfig.GrowthMultiplier,
			})
		end
	end

	print("[BiomeService]", player.Name, "unlocked biome:", biomeName)
	return true
end

function BiomeService.TeleportToBiome(player, biomeName)
	local data = BiomeService.DataService.GetFullData(player)
	if not data then return false end

	-- Check biome unlocked
	local unlocked = false
	for _, b in ipairs(data.UnlockedBiomes or {}) do
		if b == biomeName then unlocked = true break end
	end
	if not unlocked then return false, "Biome locked" end

	-- Find biome spawn point in workspace
	local biomeFolder = workspace:FindFirstChild("Biomes")
	if biomeFolder then
		local biomeModel = biomeFolder:FindFirstChild(biomeName)
		if biomeModel then
			local spawnPoint = biomeModel:FindFirstChild("SpawnPoint")
			if spawnPoint and player.Character then
				local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
				end
			end
		end
	end

	return true
end

function BiomeService.SendBiomeInfo(player)
	local data = BiomeService.DataService.GetFullData(player)
	if not data then return end

	local biomeInfo = {}
	for name, config in pairs(GameConfig.Biomes) do
		local unlocked = false
		for _, b in ipairs(data.UnlockedBiomes or {}) do
			if b == name then unlocked = true break end
		end

		biomeInfo[name] = {
			Order = config.Order,
			UnlockCost = config.UnlockCost,
			PlotCount = config.PlotCount,
			GrowthMultiplier = config.GrowthMultiplier,
			Color = config.Color,
			Unlocked = unlocked,
		}
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local biomeRemote = remoteEvents:FindFirstChild("BiomeInfo")
		if biomeRemote then
			biomeRemote:FireClient(player, biomeInfo)
		end
	end
end

return BiomeService
