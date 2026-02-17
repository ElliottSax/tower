--[[
	CollectionService.lua - Merge Mania
	Tracks which tiers players have discovered in each path.
	Completing collections (sets of tiers) grants permanent boosts.

	Collections include:
	- Per-path milestone sets (tiers 1-5, 1-10, 1-20)
	- Cross-path achievements (tier 5/10/20 in all paths)
	Each completion grants a permanent multiplier to earnings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MergeCollectionService = {}
MergeCollectionService.DataService = nil
MergeCollectionService.EarningsService = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MergeCollectionService.Init()
	print("[CollectionService] Initializing...")

	MergeCollectionService.DataService = require(ServerScriptService.Services.DataService)

	MergeCollectionService.SetupRemotes()

	print("[CollectionService] Initialized")
end

-- Late init to resolve circular dependency with EarningsService
function MergeCollectionService.LateInit()
	MergeCollectionService.EarningsService = require(ServerScriptService.Services.EarningsService)
end

function MergeCollectionService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetCollections").OnServerEvent:Connect(function(player)
		MergeCollectionService.SendCollectionData(player)
	end)
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

function MergeCollectionService.SetupPlayer(player)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data then return end

	-- Initialize collections data if needed
	data.Collections = data.Collections or {}
	data.HighestTiers = data.HighestTiers or { Weapons = 0, Pets = 0, Food = 0, Gems = 0 }

	-- Initialize discovered tiers tracking per path
	data._DiscoveredTiers = data._DiscoveredTiers or { Weapons = {}, Pets = {}, Food = {}, Gems = {} }

	-- Rebuild discovered tiers from highest tier (in case of data migration)
	for path, highest in pairs(data.HighestTiers) do
		if not data._DiscoveredTiers[path] then
			data._DiscoveredTiers[path] = {}
		end
		for tier = 1, highest do
			data._DiscoveredTiers[path][tier] = true
		end
	end

	-- Check all collections on login (in case we added new ones)
	MergeCollectionService.RecheckAllCollections(player)
end

-- ============================================================================
-- ON ITEM MERGED (called by MergeService when a merge occurs)
-- ============================================================================

function MergeCollectionService.OnItemMerged(player, path, tier)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data then return end

	-- Track discovered tier
	data._DiscoveredTiers = data._DiscoveredTiers or { Weapons = {}, Pets = {}, Food = {}, Gems = {} }
	if not data._DiscoveredTiers[path] then
		data._DiscoveredTiers[path] = {}
	end

	-- Check if this tier was already discovered
	if data._DiscoveredTiers[path][tier] then return end

	-- New tier discovered!
	data._DiscoveredTiers[path][tier] = true

	-- Update highest tier
	data.HighestTiers = data.HighestTiers or {}
	if not data.HighestTiers[path] or tier > data.HighestTiers[path] then
		data.HighestTiers[path] = tier
	end

	-- Notify about new tier discovery
	local tierData = GameConfig.GetTierData(path, tier)
	if tierData then
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local notif = remoteEvents:FindFirstChild("Notification")
			if notif then
				notif:FireClient(player, {
					Text = "New Discovery: " .. tierData.Name .. " (Tier " .. tier .. " " .. path .. ")!",
					Color = GameConfig.Theme.WarningColor,
				})
			end
		end
	end

	-- Check collections that might have been completed
	MergeCollectionService.CheckCollections(player, path, tier)
end

-- ============================================================================
-- COLLECTION CHECKING
-- ============================================================================

function MergeCollectionService.CheckCollections(player, triggerPath, triggerTier)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data then return end

	data.Collections = data.Collections or {}

	for collName, collConfig in pairs(GameConfig.Collections) do
		-- Skip already completed
		if data.Collections[collName] and data.Collections[collName].Completed then
			continue
		end

		-- Check if this collection is relevant to the trigger
		local relevant = false
		if collConfig.Path == triggerPath then
			relevant = true
		elseif collConfig.Path == "ALL" then
			relevant = true
		end

		if not relevant then continue end

		-- Check if all required tiers are discovered
		local complete = MergeCollectionService.IsCollectionComplete(data, collConfig)

		if complete then
			-- Collection completed!
			data.Collections[collName] = data.Collections[collName] or {}
			data.Collections[collName].Completed = true
			data.Collections[collName].CompletedAt = os.time()

			-- Notify player
			local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remoteEvents then
				local completeEvent = remoteEvents:FindFirstChild("CollectionComplete")
				if completeEvent then
					completeEvent:FireClient(player, {
						CollectionName = collName,
						Reward = collConfig.Reward,
						Multiplier = collConfig.Multiplier,
						Description = collConfig.Description,
					})
				end
			end

			-- Recalculate earnings with new multiplier
			if MergeCollectionService.EarningsService then
				MergeCollectionService.EarningsService.RecalculateEarnings(player)
			end

			print("[CollectionService]", player.Name, "completed collection:", collName, "Reward:", collConfig.Reward)
		end
	end
end

function MergeCollectionService.IsCollectionComplete(data, collConfig)
	local discoveredTiers = data._DiscoveredTiers or {}

	if collConfig.Path == "ALL" then
		-- Cross-path collection: need all required tiers in ALL paths
		local paths = { "Weapons", "Pets", "Food", "Gems" }
		for _, path in ipairs(paths) do
			local pathDiscovered = discoveredTiers[path] or {}
			for _, requiredTier in ipairs(collConfig.RequiredTiers) do
				if not pathDiscovered[requiredTier] then
					return false
				end
			end
		end
		return true
	else
		-- Single-path collection
		local pathDiscovered = discoveredTiers[collConfig.Path] or {}
		for _, requiredTier in ipairs(collConfig.RequiredTiers) do
			if not pathDiscovered[requiredTier] then
				return false
			end
		end
		return true
	end
end

function MergeCollectionService.RecheckAllCollections(player)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data then return end

	data.Collections = data.Collections or {}

	for collName, collConfig in pairs(GameConfig.Collections) do
		if data.Collections[collName] and data.Collections[collName].Completed then
			continue
		end

		local complete = MergeCollectionService.IsCollectionComplete(data, collConfig)
		if complete then
			data.Collections[collName] = data.Collections[collName] or {}
			data.Collections[collName].Completed = true
			data.Collections[collName].CompletedAt = os.time()

			print("[CollectionService]", player.Name, "had already completed:", collName, "(retroactive)")
		end
	end
end

-- ============================================================================
-- SEND COLLECTION DATA TO CLIENT
-- ============================================================================

function MergeCollectionService.SendCollectionData(player)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data then return end

	local collectionsInfo = {}

	for collName, collConfig in pairs(GameConfig.Collections) do
		local collData = data.Collections and data.Collections[collName] or {}
		local discoveredTiers = data._DiscoveredTiers or {}

		-- Count progress
		local totalRequired = #collConfig.RequiredTiers
		local discovered = 0

		if collConfig.Path == "ALL" then
			-- For cross-path, count minimum across all paths
			local paths = { "Weapons", "Pets", "Food", "Gems" }
			local minDiscovered = totalRequired
			for _, path in ipairs(paths) do
				local pathDiscovered = discoveredTiers[path] or {}
				local pathCount = 0
				for _, tier in ipairs(collConfig.RequiredTiers) do
					if pathDiscovered[tier] then
						pathCount = pathCount + 1
					end
				end
				minDiscovered = math.min(minDiscovered, pathCount)
			end
			discovered = minDiscovered
		else
			local pathDiscovered = discoveredTiers[collConfig.Path] or {}
			for _, tier in ipairs(collConfig.RequiredTiers) do
				if pathDiscovered[tier] then
					discovered = discovered + 1
				end
			end
		end

		collectionsInfo[collName] = {
			Name = collName,
			Path = collConfig.Path,
			Reward = collConfig.Reward,
			Multiplier = collConfig.Multiplier,
			Description = collConfig.Description,
			TotalRequired = totalRequired,
			Discovered = discovered,
			Completed = collData.Completed or false,
			CompletedAt = collData.CompletedAt,
			Progress = discovered / totalRequired,
		}
	end

	-- Also send highest tiers for display
	local highestTiers = data.HighestTiers or {}

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local collUpdate = remoteEvents:FindFirstChild("CollectionUpdate")
		if collUpdate then
			collUpdate:FireClient(player, {
				Collections = collectionsInfo,
				HighestTiers = highestTiers,
				DiscoveredTiers = data._DiscoveredTiers,
			})
		end
	end
end

-- ============================================================================
-- PUBLIC: Get collection multiplier for a path
-- ============================================================================

function MergeCollectionService.GetPathMultiplier(player, path)
	local data = MergeCollectionService.DataService.GetFullData(player)
	if not data or not data.Collections then return 1 end

	local multiplier = 1.0
	for collName, collData in pairs(data.Collections) do
		if collData.Completed then
			local collConfig = GameConfig.Collections[collName]
			if collConfig and (collConfig.Path == path or collConfig.Path == "ALL") then
				multiplier = multiplier * collConfig.Multiplier
			end
		end
	end

	return multiplier
end

return MergeCollectionService
