--[[
	SecurityManager.lua - Merge Mania
	Anti-exploit protection: rate limiting, input validation, sanity checks
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SecurityManager = {}

-- ============================================================================
-- RATE LIMITS (per action)
-- ============================================================================
local RATE_LIMITS = {
	MergeItems      = { MaxPerMinute = 60,  Cooldown = 0.3 },
	MoveItem        = { MaxPerMinute = 60,  Cooldown = 0.3 },
	SellItem        = { MaxPerMinute = 30,  Cooldown = 0.5 },
	BuyGenerator    = { MaxPerMinute = 10,  Cooldown = 2 },
	UpgradeGenerator= { MaxPerMinute = 10,  Cooldown = 2 },
	UnlockPath      = { MaxPerMinute = 5,   Cooldown = 3 },
	Prestige        = { MaxPerMinute = 1,   Cooldown = 30 },
	CollectOffline  = { MaxPerMinute = 2,   Cooldown = 10 },
	PurchaseGamePass    = { MaxPerMinute = 5, Cooldown = 5 },
	PurchaseDevProduct  = { MaxPerMinute = 5, Cooldown = 5 },
}

-- Track actions per player
local PlayerActions = {} -- [UserId] = { [ActionName] = { Count, LastReset, LastAction } }

-- Track suspicious behavior
local SuspiciousPlayers = {} -- [UserId] = { Strikes, LastStrike }
local MAX_STRIKES = 10
local STRIKE_DECAY_SECONDS = 300 -- Strikes decay after 5 minutes

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SecurityManager.Init()
	print("[SecurityManager] Initializing anti-exploit systems...")

	Players.PlayerAdded:Connect(function(player)
		PlayerActions[player.UserId] = {}
		SuspiciousPlayers[player.UserId] = { Strikes = 0, LastStrike = 0 }
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerActions[player.UserId] = nil
		SuspiciousPlayers[player.UserId] = nil
	end)

	print("[SecurityManager] Initialized with", 0, "pre-existing players")

	-- Initialize for already-connected players
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerActions[player.UserId] = {}
		SuspiciousPlayers[player.UserId] = { Strikes = 0, LastStrike = 0 }
	end
end

-- ============================================================================
-- RATE LIMITING
-- ============================================================================

function SecurityManager.CheckRateLimit(player, actionName)
	local limit = RATE_LIMITS[actionName]
	if not limit then return true end

	local actions = PlayerActions[player.UserId]
	if not actions then return false end

	local actionData = actions[actionName]
	if not actionData then
		actions[actionName] = { Count = 1, LastReset = os.time(), LastAction = tick() }
		return true
	end

	local now = os.time()
	local nowTick = tick()

	-- Reset counter every minute
	if now - actionData.LastReset >= 60 then
		actionData.Count = 0
		actionData.LastReset = now
	end

	-- Check cooldown (use tick() for sub-second precision)
	if nowTick - actionData.LastAction < limit.Cooldown then
		SecurityManager.AddStrike(player, "RateLimit_Cooldown_" .. actionName)
		return false, "Too fast"
	end

	-- Check rate limit
	if actionData.Count >= limit.MaxPerMinute then
		SecurityManager.AddStrike(player, "RateLimit_Max_" .. actionName)
		return false, "Rate limited"
	end

	actionData.Count = actionData.Count + 1
	actionData.LastAction = nowTick
	return true
end

-- ============================================================================
-- STRIKE SYSTEM
-- ============================================================================

function SecurityManager.AddStrike(player, reason)
	local data = SuspiciousPlayers[player.UserId]
	if not data then return end

	local now = os.time()

	-- Decay old strikes
	if now - data.LastStrike > STRIKE_DECAY_SECONDS then
		data.Strikes = math.max(0, data.Strikes - 3)
	end

	data.Strikes = data.Strikes + 1
	data.LastStrike = now

	if data.Strikes >= MAX_STRIKES then
		warn("[SecurityManager] KICKED", player.Name, "for excessive violations:", reason)
		player:Kick("Unusual activity detected. Please rejoin.")
	elseif data.Strikes >= MAX_STRIKES / 2 then
		warn("[SecurityManager] WARNING", player.Name, "has", data.Strikes, "strikes:", reason)
	end
end

-- ============================================================================
-- INPUT VALIDATION
-- ============================================================================

function SecurityManager.ValidateNumber(value, min, max)
	if type(value) ~= "number" then return false end
	if value ~= value then return false end -- NaN check
	if value == math.huge or value == -math.huge then return false end
	if min and value < min then return false end
	if max and value > max then return false end
	return true
end

function SecurityManager.ValidateInteger(value, min, max)
	if not SecurityManager.ValidateNumber(value, min, max) then return false end
	if value ~= math.floor(value) then return false end
	return true
end

function SecurityManager.ValidateString(value, maxLength)
	if type(value) ~= "string" then return false end
	if maxLength and #value > maxLength then return false end
	return true
end

function SecurityManager.ValidateGridPosition(row, col, maxRows, maxCols)
	if not SecurityManager.ValidateInteger(row, 1, maxRows) then return false end
	if not SecurityManager.ValidateInteger(col, 1, maxCols) then return false end
	return true
end

-- ============================================================================
-- MERGE VALIDATION
-- ============================================================================

function SecurityManager.ValidateMerge(gridData, fromRow, fromCol, toRow, toCol, maxRows, maxCols)
	-- Validate positions
	if not SecurityManager.ValidateGridPosition(fromRow, fromCol, maxRows, maxCols) then
		return false, "Invalid source position"
	end
	if not SecurityManager.ValidateGridPosition(toRow, toCol, maxRows, maxCols) then
		return false, "Invalid target position"
	end

	-- Cannot merge with self
	if fromRow == toRow and fromCol == toCol then
		return false, "Cannot merge with self"
	end

	-- Check both cells have items
	local fromKey = fromRow .. "_" .. fromCol
	local toKey = toRow .. "_" .. toCol
	local fromItem = gridData[fromKey]
	local toItem = gridData[toKey]

	if not fromItem then return false, "Source cell empty" end
	if not toItem then return false, "Target cell empty" end

	-- Items must be same path and same tier
	if fromItem.Path ~= toItem.Path then return false, "Different paths" end
	if fromItem.Tier ~= toItem.Tier then return false, "Different tiers" end

	-- Cannot merge max tier items
	if fromItem.Tier >= 20 then return false, "Max tier reached" end

	return true
end

-- ============================================================================
-- ECONOMY VALIDATION
-- ============================================================================

function SecurityManager.ValidatePurchase(playerCoins, cost)
	if not SecurityManager.ValidateNumber(cost, 0) then return false end
	if playerCoins < cost then return false end
	return true
end

function SecurityManager.ValidateEarnings(amount, maxExpected)
	-- Sanity check: earnings should not be astronomically higher than expected
	if not SecurityManager.ValidateNumber(amount, 0) then return false end
	if maxExpected and amount > maxExpected * 1.1 then -- 10% tolerance
		return false
	end
	return true
end

return SecurityManager
