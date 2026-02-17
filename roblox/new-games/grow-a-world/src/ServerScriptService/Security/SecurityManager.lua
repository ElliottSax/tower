--[[
	SecurityManager.lua - Grow a World
	Anti-exploit protection for farming simulator
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SecurityManager = {}

local RATE_LIMITS = {
	PlantSeed = { MaxPerMinute = 30, Cooldown = 1 },
	HarvestPlant = { MaxPerMinute = 60, Cooldown = 0.5 },
	BuySeed = { MaxPerMinute = 20, Cooldown = 2 },
	BuySeedPack = { MaxPerMinute = 10, Cooldown = 3 },
	RequestTrade = { MaxPerMinute = 5, Cooldown = 10 },
	Prestige = { MaxPerMinute = 1, Cooldown = 30 },
}

local PlayerActions = {} -- [UserId] = { [ActionName] = { Count, LastReset, LastAction } }

function SecurityManager.Init()
	print("[SecurityManager] Initializing anti-exploit systems...")

	Players.PlayerAdded:Connect(function(player)
		PlayerActions[player.UserId] = {}
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerActions[player.UserId] = nil
	end)

	print("[SecurityManager] Initialized")
end

function SecurityManager.CheckRateLimit(player, actionName)
	local limit = RATE_LIMITS[actionName]
	if not limit then return true end

	local actions = PlayerActions[player.UserId]
	if not actions then return false end

	local actionData = actions[actionName]
	if not actionData then
		actions[actionName] = { Count = 1, LastReset = os.time(), LastAction = os.time() }
		return true
	end

	local now = os.time()

	-- Reset counter every minute
	if now - actionData.LastReset >= 60 then
		actionData.Count = 0
		actionData.LastReset = now
	end

	-- Check cooldown
	if now - actionData.LastAction < limit.Cooldown then
		return false, "Too fast"
	end

	-- Check rate limit
	if actionData.Count >= limit.MaxPerMinute then
		return false, "Rate limited"
	end

	actionData.Count = actionData.Count + 1
	actionData.LastAction = now
	return true
end

function SecurityManager.ValidateNumber(value, min, max)
	if type(value) ~= "number" then return false end
	if value ~= value then return false end -- NaN check
	if value == math.huge or value == -math.huge then return false end
	if min and value < min then return false end
	if max and value > max then return false end
	return true
end

function SecurityManager.ValidateString(value, maxLength)
	if type(value) ~= "string" then return false end
	if maxLength and #value > maxLength then return false end
	return true
end

return SecurityManager
