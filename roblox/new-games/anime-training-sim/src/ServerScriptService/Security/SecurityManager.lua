--[[
	SecurityManager.lua - Anime Training Simulator
	Rate limiting and input validation
]]

local Players = game:GetService("Players")

local SecurityManager = {}

local RATE_LIMITS = {
	Train = { MaxPerMinute = 120, Cooldown = 0.3 },
	HatchEgg = { MaxPerMinute = 20, Cooldown = 2 },
	BuyAbility = { MaxPerMinute = 10, Cooldown = 3 },
	JoinPvPQueue = { MaxPerMinute = 5, Cooldown = 10 },
	Rebirth = { MaxPerMinute = 2, Cooldown = 15 },
}

local PlayerActions = {}

function SecurityManager.Init()
	print("[SecurityManager] Initializing...")

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

	if now - actionData.LastReset >= 60 then
		actionData.Count = 0
		actionData.LastReset = now
	end

	if now - actionData.LastAction < limit.Cooldown then
		return false
	end

	if actionData.Count >= limit.MaxPerMinute then
		return false
	end

	actionData.Count = actionData.Count + 1
	actionData.LastAction = now
	return true
end

return SecurityManager
