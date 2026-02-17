--[[
	GeneratorService.lua - Merge Mania
	Auto-spawning generators that produce tier 1+ items on the grid at intervals

	Players buy generators -> generators auto-spawn items -> players merge items
	Generator speed can be boosted by: upgrades, game passes, prestige, collections
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GeneratorService = {}
GeneratorService.DataService = nil
GeneratorService.MergeService = nil
GeneratorService.SecurityManager = nil

-- Active generator loops per player
local ActiveGeneratorLoops = {} -- [UserId] = { [GeneratorIndex] = true }
local GeneratorTimers = {} -- [UserId] = { [GeneratorIndex] = lastSpawnTime }

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GeneratorService.Init()
	print("[GeneratorService] Initializing...")

	GeneratorService.DataService = require(ServerScriptService.Services.DataService)
	GeneratorService.MergeService = require(ServerScriptService.Services.MergeService)
	GeneratorService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	GeneratorService.SetupRemotes()
	GeneratorService.StartGlobalLoop()

	print("[GeneratorService] Initialized")
end

function GeneratorService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("BuyGenerator").OnServerEvent:Connect(function(player, generatorIndex)
		local allowed = GeneratorService.SecurityManager.CheckRateLimit(player, "BuyGenerator")
		if not allowed then return end

		GeneratorService.BuyGenerator(player, generatorIndex)
	end)

	remoteEvents:WaitForChild("UpgradeGenerator").OnServerEvent:Connect(function(player, ownedIndex)
		local allowed = GeneratorService.SecurityManager.CheckRateLimit(player, "UpgradeGenerator")
		if not allowed then return end

		GeneratorService.UpgradeGenerator(player, ownedIndex)
	end)

	remoteEvents:WaitForChild("GetGenerators").OnServerEvent:Connect(function(player)
		GeneratorService.SendGeneratorList(player)
	end)
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

function GeneratorService.SetupPlayer(player)
	ActiveGeneratorLoops[player.UserId] = {}
	GeneratorTimers[player.UserId] = {}

	-- Initialize generator timers
	local data = GeneratorService.DataService.GetFullData(player)
	if data and data.OwnedGenerators then
		for i, gen in ipairs(data.OwnedGenerators) do
			GeneratorTimers[player.UserId][i] = gen.LastSpawnTime or os.time()
		end
	end
end

function GeneratorService.CleanupPlayer(player)
	ActiveGeneratorLoops[player.UserId] = nil
	GeneratorTimers[player.UserId] = nil
end

-- ============================================================================
-- GLOBAL GENERATOR TICK (runs every second)
-- ============================================================================

function GeneratorService.StartGlobalLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			GeneratorService.TickAllGenerators()
		end
	end)
end

function GeneratorService.TickAllGenerators()
	local now = os.time()

	for _, player in ipairs(Players:GetPlayers()) do
		local data = GeneratorService.DataService.GetFullData(player)
		if not data or not data.OwnedGenerators then continue end

		local timers = GeneratorTimers[player.UserId]
		if not timers then continue end

		for i, ownedGen in ipairs(data.OwnedGenerators) do
			local genConfig = GeneratorService.GetGeneratorConfig(ownedGen.GeneratorName)
			if not genConfig then continue end

			-- Calculate effective interval (with speed boosts)
			local interval = GeneratorService.GetEffectiveInterval(player, data, genConfig)

			local lastSpawn = timers[i] or now
			if now - lastSpawn >= interval then
				-- Check if grid has space
				if not GeneratorService.MergeService.IsGridFull(player) then
					-- Spawn item
					local spawnTier = genConfig.SpawnTier or 1
					local success = GeneratorService.MergeService.PlaceItem(
						player,
						genConfig.Path,
						spawnTier,
						false -- not golden from generators
					)

					if success then
						timers[i] = now
						ownedGen.LastSpawnTime = now

						-- Notify client
						local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
						if remoteEvents then
							local spawnEvent = remoteEvents:FindFirstChild("GeneratorSpawn")
							if spawnEvent then
								spawnEvent:FireClient(player, {
									GeneratorName = ownedGen.GeneratorName,
									Path = genConfig.Path,
									Tier = spawnTier,
								})
							end
						end
					end
				end
			end
		end
	end
end

function GeneratorService.GetEffectiveInterval(player, data, genConfig)
	local baseInterval = genConfig.IntervalSec

	-- Generator level speed bonus (10% faster per level)
	-- Level is stored on the owned generator instance
	-- This is handled per-generator in BuyGenerator/UpgradeGenerator

	-- Speed boost from dev product
	if GeneratorService.DataService.HasActiveBoost(player, "SpeedBoost") then
		baseInterval = baseInterval * 0.5 -- 2x speed
	end

	-- Premium generators pass: 25% faster
	if data.GamePasses and data.GamePasses["PremiumGenerators"] then
		baseInterval = baseInterval * 0.75
	end

	-- Collection bonus: Food path gives generator speed bonus
	if data.Collections then
		for collName, collData in pairs(data.Collections) do
			local collConfig = GameConfig.Collections[collName]
			if collConfig and collData.Completed then
				if collConfig.Path == "Food" or collConfig.Path == "ALL" then
					local bonus = GameConfig.MergePaths.Food and GameConfig.MergePaths.Food.BonusAmount or 0.08
					baseInterval = baseInterval * (1 - bonus)
				end
			end
		end
	end

	-- Minimum interval of 1 second
	return math.max(1, baseInterval)
end

-- ============================================================================
-- BUY GENERATOR
-- ============================================================================

function GeneratorService.BuyGenerator(player, generatorIndex)
	local data = GeneratorService.DataService.GetFullData(player)
	if not data then return end

	-- Validate index
	if not GeneratorService.SecurityManager.ValidateInteger(generatorIndex, 1, #GameConfig.Generators) then
		return
	end

	local genConfig = GameConfig.Generators[generatorIndex]
	if not genConfig then return end

	-- Check prestige requirement
	if genConfig.UnlockPrestige > (data.PrestigeLevel or 0) then
		GeneratorService.Notify(player, "Need Prestige " .. genConfig.UnlockPrestige .. " to unlock!", GameConfig.Theme.ErrorColor)
		return
	end

	-- Check if path is unlocked
	local pathUnlocked = false
	for _, unlockedPath in ipairs(data.UnlockedPaths) do
		if unlockedPath == genConfig.Path then
			pathUnlocked = true
			break
		end
	end
	if not pathUnlocked then
		GeneratorService.Notify(player, "Unlock the " .. genConfig.Path .. " path first!", GameConfig.Theme.ErrorColor)
		return
	end

	-- Check cost
	if not GeneratorService.SecurityManager.ValidatePurchase(data.Coins, genConfig.Cost) then
		GeneratorService.Notify(player, "Not enough coins! Need " .. GameConfig.FormatNumber(genConfig.Cost), GameConfig.Theme.ErrorColor)
		return
	end

	-- Purchase
	GeneratorService.DataService.RemoveCoins(player, genConfig.Cost)

	-- Add to owned generators
	data.OwnedGenerators = data.OwnedGenerators or {}
	local newGen = {
		GeneratorName = genConfig.Name,
		Level = 1,
		LastSpawnTime = os.time(),
	}
	table.insert(data.OwnedGenerators, newGen)

	-- Initialize timer
	local timers = GeneratorTimers[player.UserId] or {}
	timers[#data.OwnedGenerators] = os.time()
	GeneratorTimers[player.UserId] = timers

	GeneratorService.Notify(player, "Bought " .. genConfig.Name .. "!", GameConfig.Theme.SuccessColor)
	GeneratorService.SendGeneratorList(player)
end

-- ============================================================================
-- UPGRADE GENERATOR
-- ============================================================================

function GeneratorService.UpgradeGenerator(player, ownedIndex)
	local data = GeneratorService.DataService.GetFullData(player)
	if not data or not data.OwnedGenerators then return end

	if not GeneratorService.SecurityManager.ValidateInteger(ownedIndex, 1, #data.OwnedGenerators) then
		return
	end

	local ownedGen = data.OwnedGenerators[ownedIndex]
	if not ownedGen then return end

	local genConfig = GeneratorService.GetGeneratorConfig(ownedGen.GeneratorName)
	if not genConfig then return end

	-- Max level 10
	if ownedGen.Level >= 10 then
		GeneratorService.Notify(player, "Generator is max level!", GameConfig.Theme.WarningColor)
		return
	end

	-- Upgrade cost scales with level: baseCost * level * 2
	local upgradeCost = math.floor(genConfig.Cost * ownedGen.Level * 2)

	if not GeneratorService.SecurityManager.ValidatePurchase(data.Coins, upgradeCost) then
		GeneratorService.Notify(player, "Not enough coins! Need " .. GameConfig.FormatNumber(upgradeCost), GameConfig.Theme.ErrorColor)
		return
	end

	GeneratorService.DataService.RemoveCoins(player, upgradeCost)
	ownedGen.Level = ownedGen.Level + 1

	GeneratorService.Notify(player, ownedGen.GeneratorName .. " upgraded to level " .. ownedGen.Level .. "!", GameConfig.Theme.SuccessColor)
	GeneratorService.SendGeneratorList(player)
end

-- ============================================================================
-- QUERY HELPERS
-- ============================================================================

function GeneratorService.GetGeneratorConfig(generatorName)
	for _, gen in ipairs(GameConfig.Generators) do
		if gen.Name == generatorName then
			return gen
		end
	end
	return nil
end

function GeneratorService.SendGeneratorList(player)
	local data = GeneratorService.DataService.GetFullData(player)
	if not data then return end

	local available = GameConfig.GetGeneratorsByPrestige(data.PrestigeLevel or 0)
	local owned = data.OwnedGenerators or {}

	-- Build available list with ownership status
	local availableList = {}
	for i, gen in ipairs(available) do
		-- Check if path is unlocked
		local pathUnlocked = false
		for _, unlockedPath in ipairs(data.UnlockedPaths) do
			if unlockedPath == gen.Path then
				pathUnlocked = true
				break
			end
		end

		table.insert(availableList, {
			Index = i,
			Name = gen.Name,
			Path = gen.Path,
			SpawnTier = gen.SpawnTier,
			IntervalSec = gen.IntervalSec,
			Cost = gen.Cost,
			UnlockPrestige = gen.UnlockPrestige,
			PathUnlocked = pathUnlocked,
			Color = gen.Color,
		})
	end

	-- Build owned list
	local ownedList = {}
	for i, gen in ipairs(owned) do
		local config = GeneratorService.GetGeneratorConfig(gen.GeneratorName)
		table.insert(ownedList, {
			OwnedIndex = i,
			Name = gen.GeneratorName,
			Level = gen.Level,
			Path = config and config.Path or "Unknown",
			SpawnTier = config and config.SpawnTier or 1,
			BaseInterval = config and config.IntervalSec or 10,
			EffectiveInterval = config and GeneratorService.GetEffectiveInterval(player, data, config) or 10,
			UpgradeCost = config and math.floor(config.Cost * gen.Level * 2) or 0,
			MaxLevel = 10,
		})
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local listEvent = remoteEvents:FindFirstChild("GeneratorList")
		if listEvent then
			listEvent:FireClient(player, {
				Available = availableList,
				Owned = ownedList,
			})
		end
	end
end

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

function GeneratorService.Notify(player, text, color)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Text = text, Color = color })
		end
	end
end

return GeneratorService
