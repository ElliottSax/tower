--[[
	MergeService.lua - Merge Mania
	Core merge mechanics: grid management, merge logic, tier progression, lucky merges

	Grid is stored as a flat dictionary: { ["row_col"] = { Path, Tier, IsGolden } }
	Merging two same-tier same-path items produces one item of the next tier.
	Lucky merges have a chance to create golden items (5x value).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MergeService = {}
MergeService.DataService = nil
MergeService.SecurityManager = nil
MergeService.CollectionService = nil
MergeService.EarningsService = nil

-- Cache player grid state for fast access
local PlayerGrids = {} -- [UserId] = grid reference from DataService

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MergeService.Init()
	print("[MergeService] Initializing...")

	MergeService.DataService = require(ServerScriptService.Services.DataService)
	MergeService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	MergeService.SetupRemotes()
	MergeService.SetupRemoteFunctions()

	print("[MergeService] Initialized")
end

-- Late-init for circular dependencies
function MergeService.LateInit()
	MergeService.CollectionService = require(ServerScriptService.Services.CollectionService)
	MergeService.EarningsService = require(ServerScriptService.Services.EarningsService)
end

function MergeService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("MergeItems").OnServerEvent:Connect(function(player, fromRow, fromCol, toRow, toCol)
		-- Rate limit check
		local allowed, reason = MergeService.SecurityManager.CheckRateLimit(player, "MergeItems")
		if not allowed then return end

		MergeService.TryMerge(player, fromRow, fromCol, toRow, toCol)
	end)

	remoteEvents:WaitForChild("MoveItem").OnServerEvent:Connect(function(player, fromRow, fromCol, toRow, toCol)
		local allowed, reason = MergeService.SecurityManager.CheckRateLimit(player, "MoveItem")
		if not allowed then return end

		MergeService.TryMove(player, fromRow, fromCol, toRow, toCol)
	end)

	remoteEvents:WaitForChild("SellItem").OnServerEvent:Connect(function(player, row, col)
		local allowed, reason = MergeService.SecurityManager.CheckRateLimit(player, "SellItem")
		if not allowed then return end

		MergeService.SellItem(player, row, col)
	end)
end

function MergeService.SetupRemoteFunctions()
	local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

	remoteFunctions:WaitForChild("GetGridState").OnServerInvoke = function(player)
		return MergeService.GetGridState(player)
	end
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

function MergeService.SetupPlayer(player)
	local grid = MergeService.DataService.GetGrid(player)
	PlayerGrids[player.UserId] = grid

	-- Send initial grid state
	MergeService.SyncGrid(player)
end

function MergeService.CleanupPlayer(player)
	PlayerGrids[player.UserId] = nil
end

-- ============================================================================
-- GRID STATE
-- ============================================================================

function MergeService.GetGridState(player)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return {} end

	local rows, cols = MergeService.DataService.GetGridSize(player)

	return {
		Grid = data.Grid,
		Rows = rows,
		Cols = cols,
		UnlockedPaths = data.UnlockedPaths,
	}
end

function MergeService.SyncGrid(player)
	local state = MergeService.GetGridState(player)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local gridUpdate = remoteEvents:FindFirstChild("GridUpdate")
		if gridUpdate then
			gridUpdate:FireClient(player, state)
		end
	end
end

function MergeService.SyncCell(player, row, col, itemData)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local cellUpdate = remoteEvents:FindFirstChild("GridCellUpdate")
		if cellUpdate then
			cellUpdate:FireClient(player, row, col, itemData)
		end
	end
end

-- ============================================================================
-- MERGE LOGIC
-- ============================================================================

function MergeService.TryMerge(player, fromRow, fromCol, toRow, toCol)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return end

	local rows, cols = MergeService.DataService.GetGridSize(player)

	-- Validate inputs
	if not MergeService.SecurityManager.ValidateGridPosition(fromRow, fromCol, rows, cols) then return end
	if not MergeService.SecurityManager.ValidateGridPosition(toRow, toCol, rows, cols) then return end

	local grid = data.Grid

	-- Validate merge
	local valid, err = MergeService.SecurityManager.ValidateMerge(grid, fromRow, fromCol, toRow, toCol, rows, cols)
	if not valid then
		MergeService.SendMergeResult(player, false, err)
		return
	end

	local fromKey = fromRow .. "_" .. fromCol
	local toKey = toRow .. "_" .. toCol
	local fromItem = grid[fromKey]
	local toItem = grid[toKey]

	local path = fromItem.Path
	local currentTier = fromItem.Tier
	local newTier = currentTier + 1

	-- Check for skip-tier (prestige 25 reward: 5% chance to triple merge)
	local prestigeLevel = data.PrestigeLevel or 0
	if prestigeLevel >= 25 and math.random() < 0.05 then
		newTier = math.min(currentTier + 2, GameConfig.GetMaxTier())
	end

	-- Check for skip-tier from dev product boost
	if MergeService.DataService.HasActiveBoost(player, "SkipTierMerge") then
		newTier = math.min(currentTier + 2, GameConfig.GetMaxTier())
		-- Remove the one-time boost
		data.ActiveBoosts["SkipTierMerge"] = nil
	end

	-- Determine if golden merge
	local isGolden = MergeService.RollGoldenMerge(player, data)

	-- Inherit golden status: if both source items are golden, result is golden
	if fromItem.IsGolden and toItem.IsGolden then
		isGolden = true
	end

	-- Create merged item
	local mergedItem = {
		Path = path,
		Tier = newTier,
		IsGolden = isGolden,
	}

	-- Clear source, place merged item at target
	grid[fromKey] = nil
	grid[toKey] = mergedItem

	-- Update highest tier tracking
	data.HighestTiers = data.HighestTiers or {}
	if not data.HighestTiers[path] or newTier > data.HighestTiers[path] then
		data.HighestTiers[path] = newTier
	end

	-- Increment merge counter
	data.TotalMerges = (data.TotalMerges or 0) + 1
	if isGolden then
		data.GoldenMerges = (data.GoldenMerges or 0) + 1
	end

	-- Check collections
	if MergeService.CollectionService then
		MergeService.CollectionService.OnItemMerged(player, path, newTier)
	end

	-- Update earnings cache
	if MergeService.EarningsService then
		MergeService.EarningsService.RecalculateEarnings(player)
	end

	-- Sync to client
	MergeService.SyncCell(player, fromRow, fromCol, nil)
	MergeService.SyncCell(player, toRow, toCol, mergedItem)

	-- Send merge result
	local tierData = GameConfig.GetTierData(path, newTier)
	MergeService.SendMergeResult(player, true, nil, {
		Path = path,
		Tier = newTier,
		Name = tierData and tierData.Name or ("Tier " .. newTier),
		IsGolden = isGolden,
		CoinPerSec = tierData and tierData.CoinPerSec or 0,
	})
end

function MergeService.RollGoldenMerge(player, data)
	local chance = GameConfig.LuckyMerge.BaseChance

	-- Lucky Merger pass: double chance
	if data.GamePasses and data.GamePasses["LuckyMerger"] then
		chance = chance * 2
	end

	-- Lucky boost active
	if MergeService.DataService.HasActiveBoost(player, "LuckyBoost") then
		chance = chance * 3
	end

	-- Prestige rewards
	local prestigeLevel = data.PrestigeLevel or 0
	if prestigeLevel >= 7 then chance = chance + 0.05 end
	if prestigeLevel >= 15 then chance = chance + 0.10 end
	if prestigeLevel >= 30 then chance = chance + 0.15 end

	-- Collection bonuses (Gems path bonus type: LuckyMerge)
	if data.Collections then
		for collName, collData in pairs(data.Collections) do
			local collConfig = GameConfig.Collections[collName]
			if collConfig and collConfig.Path == "Gems" and collData.Completed then
				chance = chance + (collConfig.Multiplier - 1) * GameConfig.MergePaths.Gems.BonusAmount
			end
		end
	end

	-- Cap at max chance
	chance = math.min(chance, GameConfig.LuckyMerge.MaxChance)

	return math.random() < chance
end

-- ============================================================================
-- MOVE ITEM
-- ============================================================================

function MergeService.TryMove(player, fromRow, fromCol, toRow, toCol)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return end

	local rows, cols = MergeService.DataService.GetGridSize(player)

	-- Validate positions
	if not MergeService.SecurityManager.ValidateGridPosition(fromRow, fromCol, rows, cols) then return end
	if not MergeService.SecurityManager.ValidateGridPosition(toRow, toCol, rows, cols) then return end
	if fromRow == toRow and fromCol == toCol then return end

	local grid = data.Grid
	local fromKey = fromRow .. "_" .. fromCol
	local toKey = toRow .. "_" .. toCol

	local fromItem = grid[fromKey]
	if not fromItem then return end

	-- If target is occupied, check if it is a valid merge
	local toItem = grid[toKey]
	if toItem then
		-- Try merge instead of move
		if toItem.Path == fromItem.Path and toItem.Tier == fromItem.Tier and fromItem.Tier < GameConfig.GetMaxTier() then
			MergeService.TryMerge(player, fromRow, fromCol, toRow, toCol)
		end
		-- If not mergeable, do nothing
		return
	end

	-- Move item
	grid[toKey] = fromItem
	grid[fromKey] = nil

	-- Sync to client
	MergeService.SyncCell(player, fromRow, fromCol, nil)
	MergeService.SyncCell(player, toRow, toCol, fromItem)
end

-- ============================================================================
-- SELL ITEM
-- ============================================================================

function MergeService.SellItem(player, row, col)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return end

	local rows, cols = MergeService.DataService.GetGridSize(player)
	if not MergeService.SecurityManager.ValidateGridPosition(row, col, rows, cols) then return end

	local grid = data.Grid
	local key = row .. "_" .. col
	local item = grid[key]
	if not item then return end

	-- Get tier data for sell value
	local tierData = GameConfig.GetTierData(item.Path, item.Tier)
	if not tierData then return end

	local sellValue = tierData.MergeValue
	if item.IsGolden then
		sellValue = sellValue * GameConfig.LuckyMerge.GoldenMultiplier
	end

	-- Add coins
	MergeService.DataService.AddCoins(player, sellValue)

	-- Remove item
	grid[key] = nil
	data.TotalItemsSold = (data.TotalItemsSold or 0) + 1

	-- Sync to client
	MergeService.SyncCell(player, row, col, nil)

	-- Notify
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, {
				Text = "Sold " .. tierData.Name .. " for " .. GameConfig.FormatNumber(sellValue) .. " coins!",
				Color = GameConfig.Theme.SuccessColor,
			})
		end
	end

	-- Recalculate earnings
	if MergeService.EarningsService then
		MergeService.EarningsService.RecalculateEarnings(player)
	end
end

-- ============================================================================
-- ITEM PLACEMENT (used by GeneratorService)
-- ============================================================================

function MergeService.PlaceItem(player, path, tier, isGolden)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return false end

	local rows, cols = MergeService.DataService.GetGridSize(player)

	-- Find empty cell
	local emptyRow, emptyCol = MergeService.FindEmptyCell(data.Grid, rows, cols)
	if not emptyRow then
		return false -- Grid is full
	end

	local item = {
		Path = path,
		Tier = tier,
		IsGolden = isGolden or false,
	}

	local key = emptyRow .. "_" .. emptyCol
	data.Grid[key] = item

	-- Sync to client
	MergeService.SyncCell(player, emptyRow, emptyCol, item)

	-- Update highest tier if needed
	data.HighestTiers = data.HighestTiers or {}
	if not data.HighestTiers[path] or tier > data.HighestTiers[path] then
		data.HighestTiers[path] = tier
	end

	-- Check collections for new tier discovery
	if MergeService.CollectionService then
		MergeService.CollectionService.OnItemMerged(player, path, tier)
	end

	-- Recalculate earnings
	if MergeService.EarningsService then
		MergeService.EarningsService.RecalculateEarnings(player)
	end

	return true
end

function MergeService.FindEmptyCell(grid, rows, cols)
	-- Scan grid for empty cell (prefer center-out for aesthetics)
	local centerRow = math.ceil(rows / 2)
	local centerCol = math.ceil(cols / 2)

	-- Spiral outward from center
	for dist = 0, math.max(rows, cols) do
		for dr = -dist, dist do
			for dc = -dist, dist do
				if math.abs(dr) == dist or math.abs(dc) == dist then
					local r = centerRow + dr
					local c = centerCol + dc
					if r >= 1 and r <= rows and c >= 1 and c <= cols then
						local key = r .. "_" .. c
						if not grid[key] then
							return r, c
						end
					end
				end
			end
		end
	end

	return nil, nil -- Grid full
end

-- ============================================================================
-- GRID QUERIES
-- ============================================================================

function MergeService.GetItemCount(player)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return 0 end

	local count = 0
	for _ in pairs(data.Grid) do
		count = count + 1
	end
	return count
end

function MergeService.IsGridFull(player)
	local rows, cols = MergeService.DataService.GetGridSize(player)
	return MergeService.GetItemCount(player) >= (rows * cols)
end

function MergeService.ClearGrid(player, collectCoins)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return end

	if collectCoins then
		-- Sell everything on grid
		for key, item in pairs(data.Grid) do
			local tierData = GameConfig.GetTierData(item.Path, item.Tier)
			if tierData then
				local value = tierData.MergeValue
				if item.IsGolden then
					value = value * GameConfig.LuckyMerge.GoldenMultiplier
				end
				MergeService.DataService.AddCoins(player, value)
			end
		end
	end

	data.Grid = {}

	-- Sync full grid
	MergeService.SyncGrid(player)

	-- Recalculate earnings
	if MergeService.EarningsService then
		MergeService.EarningsService.RecalculateEarnings(player)
	end
end

-- ============================================================================
-- AUTO MERGE (for AutoMerge game pass)
-- ============================================================================

function MergeService.AutoMergeOnce(player)
	local data = MergeService.DataService.GetFullData(player)
	if not data then return false end

	-- Check auto merge pass
	if not data.GamePasses or not data.GamePasses["AutoMerge"] then return false end

	local rows, cols = MergeService.DataService.GetGridSize(player)
	local grid = data.Grid

	-- Find first pair of matching items
	local items = {}
	for key, item in pairs(grid) do
		local identifier = item.Path .. "_" .. item.Tier
		if not items[identifier] then
			items[identifier] = {}
		end
		table.insert(items[identifier], key)
	end

	-- Merge first pair found
	for _, keys in pairs(items) do
		if #keys >= 2 then
			local key1 = keys[1]
			local key2 = keys[2]

			local r1, c1 = key1:match("(%d+)_(%d+)")
			local r2, c2 = key2:match("(%d+)_(%d+)")

			if r1 and c1 and r2 and c2 then
				MergeService.TryMerge(player, tonumber(r1), tonumber(c1), tonumber(r2), tonumber(c2))
				return true
			end
		end
	end

	return false
end

-- ============================================================================
-- RESULT NOTIFICATION
-- ============================================================================

function MergeService.SendMergeResult(player, success, errorMsg, resultData)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local mergeResult = remoteEvents:FindFirstChild("MergeResult")
		if mergeResult then
			mergeResult:FireClient(player, {
				Success = success,
				Error = errorMsg,
				Data = resultData,
			})
		end
	end
end

return MergeService
