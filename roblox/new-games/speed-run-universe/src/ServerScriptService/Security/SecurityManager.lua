--[[
	SecurityManager.lua - Speed Run Universe
	Rate limiting, anti-exploit detection, speedrun time validation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SecurityManager = {}

-- ============================================================================
-- RATE LIMITS (per-action throttles)
-- ============================================================================
local RATE_LIMITS = {
	CheckpointReached = { MaxPerMinute = 30, Cooldown = 0.5 },
	CoinCollected = { MaxPerMinute = 120, Cooldown = 0.1 },
	UseAbility = { MaxPerMinute = 60, Cooldown = 0.3 },
	BuyTrail = { MaxPerMinute = 10, Cooldown = 2 },
	BuyWinEffect = { MaxPerMinute = 10, Cooldown = 2 },
	EquipTrail = { MaxPerMinute = 20, Cooldown = 1 },
	EquipWinEffect = { MaxPerMinute = 20, Cooldown = 1 },
	EquipAbility = { MaxPerMinute = 20, Cooldown = 1 },
	UnlockWorld = { MaxPerMinute = 5, Cooldown = 3 },
	TeleportToStage = { MaxPerMinute = 10, Cooldown = 2 },
	ClaimChallengeReward = { MaxPerMinute = 10, Cooldown = 2 },
	RequestLeaderboard = { MaxPerMinute = 10, Cooldown = 3 },
	RequestGhost = { MaxPerMinute = 10, Cooldown = 3 },
	PurchaseGamePass = { MaxPerMinute = 5, Cooldown = 5 },
	PurchaseDevProduct = { MaxPerMinute = 10, Cooldown = 3 },
}

-- ============================================================================
-- SPEEDRUN VALIDATION
-- ============================================================================
-- Minimum possible times per world (in seconds) - prevents impossible times
local MIN_POSSIBLE_TIMES = {
	Grass = 15,
	Lava = 20,
	Ice = 25,
	Space = 30,
	Underwater = 35,
	Neon = 40,
	Candy = 45,
	Haunted = 50,
	Clockwork = 55,
	Void = 60,
}

-- Minimum per-stage time (seconds)
local MIN_STAGE_TIME = 1.5

-- Maximum speed a player should move (studs/second) - catches speed exploits
local MAX_SPEED_THRESHOLD = 120 -- generous to account for dashes + grapple

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================
local PlayerActions = {}    -- userId -> { actionName -> { Count, LastReset, LastAction } }
local PlayerPositions = {}  -- userId -> { Position, LastCheck, Violations }
local FlaggedPlayers = {}   -- userId -> { Reason, Timestamp, Count }

-- ============================================================================
-- INIT
-- ============================================================================
function SecurityManager.Init()
	Players.PlayerAdded:Connect(function(player)
		PlayerActions[player.UserId] = {}
		PlayerPositions[player.UserId] = { Position = nil, LastCheck = 0, Violations = 0 }
		FlaggedPlayers[player.UserId] = nil
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerActions[player.UserId] = nil
		PlayerPositions[player.UserId] = nil
		FlaggedPlayers[player.UserId] = nil
	end)

	-- Periodic speed check
	task.spawn(function()
		while true do
			task.wait(1)
			SecurityManager._CheckAllPlayerSpeeds()
		end
	end)

	print("[SecurityManager] Initialized with", 0, "active monitors")
end

-- ============================================================================
-- RATE LIMITING
-- ============================================================================
function SecurityManager.CheckRateLimit(player, actionName)
	local limit = RATE_LIMITS[actionName]
	if not limit then return true end -- No rate limit defined = allow

	local actions = PlayerActions[player.UserId]
	if not actions then return false end

	local actionData = actions[actionName]
	local now = tick()

	if not actionData then
		actions[actionName] = { Count = 1, LastReset = now, LastAction = now }
		return true
	end

	-- Reset counter every minute
	if now - actionData.LastReset >= 60 then
		actionData.Count = 0
		actionData.LastReset = now
	end

	-- Check cooldown
	if now - actionData.LastAction < limit.Cooldown then
		SecurityManager._FlagPlayer(player, "RateLimit_Cooldown_" .. actionName)
		return false
	end

	-- Check max per minute
	if actionData.Count >= limit.MaxPerMinute then
		SecurityManager._FlagPlayer(player, "RateLimit_MaxPerMinute_" .. actionName)
		return false
	end

	actionData.Count = actionData.Count + 1
	actionData.LastAction = now
	return true
end

-- ============================================================================
-- SPEEDRUN TIME VALIDATION
-- ============================================================================
function SecurityManager.ValidateSpeedrunTime(player, worldId, stageNum, timeSeconds)
	-- Check minimum stage time
	if stageNum and timeSeconds < MIN_STAGE_TIME then
		SecurityManager._FlagPlayer(player, "ImpossibleStageTime_" .. worldId .. "_" .. tostring(stageNum))
		return false, "Time too fast for stage"
	end

	-- Check minimum world time
	if not stageNum then
		local minTime = MIN_POSSIBLE_TIMES[worldId]
		if minTime and timeSeconds < minTime then
			SecurityManager._FlagPlayer(player, "ImpossibleWorldTime_" .. worldId)
			return false, "Time too fast for world"
		end
	end

	-- Check if player is flagged
	if FlaggedPlayers[player.UserId] and FlaggedPlayers[player.UserId].Count >= 5 then
		return false, "Player flagged for suspicious activity"
	end

	return true, "Valid"
end

-- ============================================================================
-- COIN VALIDATION
-- ============================================================================
function SecurityManager.ValidateCoinCollection(player, worldId, stageNum, coinIndex)
	-- Basic validation: coinIndex must be positive integer
	if type(coinIndex) ~= "number" or coinIndex < 1 or coinIndex ~= math.floor(coinIndex) then
		SecurityManager._FlagPlayer(player, "InvalidCoinIndex")
		return false
	end

	-- Coins per stage max is 20 (from config)
	if coinIndex > 25 then
		SecurityManager._FlagPlayer(player, "CoinIndexTooHigh")
		return false
	end

	return SecurityManager.CheckRateLimit(player, "CoinCollected")
end

-- ============================================================================
-- POSITION / SPEED MONITORING
-- ============================================================================
function SecurityManager._CheckAllPlayerSpeeds()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then continue end

		local posData = PlayerPositions[player.UserId]
		if not posData then continue end

		local currentPos = humanoidRootPart.Position
		local now = tick()

		if posData.Position then
			local delta = now - posData.LastCheck
			if delta > 0.5 then
				local distance = (currentPos - posData.Position).Magnitude
				local speed = distance / delta

				if speed > MAX_SPEED_THRESHOLD then
					posData.Violations = posData.Violations + 1
					if posData.Violations >= 3 then
						SecurityManager._FlagPlayer(player, "SpeedExploit_" .. tostring(math.floor(speed)))
					end
				else
					-- Decay violations over time
					posData.Violations = math.max(0, posData.Violations - 0.5)
				end
			end
		end

		posData.Position = currentPos
		posData.LastCheck = now
	end
end

-- ============================================================================
-- PLAYER FLAGGING
-- ============================================================================
function SecurityManager._FlagPlayer(player, reason)
	local existing = FlaggedPlayers[player.UserId]
	if not existing then
		FlaggedPlayers[player.UserId] = { Reason = reason, Timestamp = tick(), Count = 1 }
	else
		existing.Count = existing.Count + 1
		existing.Reason = reason
		existing.Timestamp = tick()
	end

	warn("[SecurityManager] Player", player.Name, "flagged:", reason,
		"(total flags:", FlaggedPlayers[player.UserId].Count, ")")
end

-- ============================================================================
-- PUBLIC QUERY
-- ============================================================================
function SecurityManager.IsPlayerFlagged(player)
	local flag = FlaggedPlayers[player.UserId]
	return flag ~= nil and flag.Count >= 5
end

function SecurityManager.GetPlayerFlagCount(player)
	local flag = FlaggedPlayers[player.UserId]
	return flag and flag.Count or 0
end

function SecurityManager.ResetPlayerFlags(player)
	FlaggedPlayers[player.UserId] = nil
end

return SecurityManager
