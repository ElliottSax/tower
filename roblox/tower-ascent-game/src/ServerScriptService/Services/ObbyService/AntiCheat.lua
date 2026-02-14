--[[
	AntiCheat.lua
	Server-side anti-exploit system

	Detects and prevents:
	- Speed hacks (moving too fast)
	- Flying (sustained vertical movement)
	- Teleporting (instant position changes)
	- Stage skipping (bypassing checkpoints)
	- Noclip (passing through walls)

	Actions:
	- Log violation
	- Warn player (first offense)
	- Kick player (repeat offense)
	- Ban (extreme cases - Week 3+)

	Critical: All validation server-side only!
	Never trust client data for progression.

	Week 1: Basic implementation
	Week 3: Add ban system, analytics integration
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Lazy-loaded services (to avoid circular dependency at module load time)
local DataService = nil
local CheckpointService = nil

local function getDataService()
	if not DataService then
		DataService = require(ServerScriptService.Services.DataService)
	end
	return DataService
end

local function getCheckpointService()
	if not CheckpointService then
		CheckpointService = require(ServerScriptService.Services.CheckpointService)
	end
	return CheckpointService
end

local AntiCheat = {}
AntiCheat.__index = AntiCheat

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local ENABLED = GameConfig.AntiCheat.Enabled
local MAX_SPEED = GameConfig.AntiCheat.MaxSpeed or 100
local MAX_VERTICAL_SPEED = GameConfig.AntiCheat.MaxVerticalSpeed or 200
local TELEPORT_THRESHOLD = GameConfig.AntiCheat.TeleportThreshold or 100
local MAX_STAGE_SKIP = GameConfig.AntiCheat.MaxStageSkip or 2
local CHECK_INTERVAL = GameConfig.AntiCheat.CheckInterval or 0.5
local ACTION = GameConfig.AntiCheat.Action or "Kick"
local LOG_VIOLATIONS = GameConfig.AntiCheat.LogViolations

-- Memory management for violation logs
local MAX_GLOBAL_VIOLATIONS = 1000 -- Max entries in global violation log
local MAX_PLAYER_VIOLATIONS = 100  -- Max entries per player

-- Violation types
local ViolationType = {
	SPEED_HACK = "SpeedHack",
	FLYING = "Flying",
	TELEPORT = "Teleport",
	STAGE_SKIP = "StageSkip",
	NOCLIP = "Noclip",
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function AntiCheat.new()
	local self = setmetatable({}, AntiCheat)

	-- Track player data
	-- Format: [UserId] = { lastPosition, lastCheck, violations, warnings }
	self.PlayerData = {}

	-- Violation log
	self.ViolationLog = {}

	-- Heartbeat connection
	self.CheckConnection = nil

	-- Stats
	self.TotalViolations = 0
	self.TotalKicks = 0

	return self
end

-- ============================================================================
-- START/STOP
-- ============================================================================

function AntiCheat:Start()
	if not ENABLED then
		print("[AntiCheat] Disabled in GameConfig")
		return
	end

	print("[AntiCheat] Starting...")

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self:OnPlayerAdded(player)
	end

	-- Start check loop
	self:StartCheckLoop()

	print("[AntiCheat] Started")
end

function AntiCheat:Stop()
	if self.CheckConnection then
		self.CheckConnection:Disconnect()
		self.CheckConnection = nil
	end

	print("[AntiCheat] Stopped")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function AntiCheat:OnPlayerAdded(player: Player)
	self.PlayerData[player.UserId] = {
		LastPosition = nil,
		LastCheck = tick(),
		Violations = {},
		Warnings = 0,
		TotalViolations = 0,
	}

	-- Track character spawns
	player.CharacterAdded:Connect(function(character)
		self:OnCharacterAdded(player, character)
	end)

	if player.Character then
		self:OnCharacterAdded(player, player.Character)
	end
end

function AntiCheat:OnCharacterAdded(player: Player, character: Model)
	local data = self.PlayerData[player.UserId]
	if not data then return end

	-- Reset position tracking
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if rootPart then
		data.LastPosition = rootPart.Position
		data.LastCheck = tick()
	end
end

function AntiCheat:OnPlayerRemoving(player: Player)
	self.PlayerData[player.UserId] = nil
end

-- ============================================================================
-- CHECK LOOP (OPTIMIZED)
-- ============================================================================

function AntiCheat:StartCheckLoop()
	-- OPTIMIZATION: Stagger player checks instead of checking all at once
	-- This prevents lag spikes with many players
	local playerCheckIndex = 1
	local lastFullCycle = tick()

	self.CheckConnection = RunService.Heartbeat:Connect(function()
		local allPlayers = Players:GetPlayers()
		local playerCount = #allPlayers

		if playerCount == 0 then return end

		-- Check 1-2 players per heartbeat (staggered approach)
		local checksThisFrame = math.min(2, playerCount)

		for i = 1, checksThisFrame do
			-- Wrap around using modulo
			local player = allPlayers[((playerCheckIndex - 1) % playerCount) + 1]
			if player then
				local success, error = pcall(function()
					self:CheckPlayer(player)
				end)

				if not success then
					warn(string.format("[AntiCheat] Error checking player %s: %s", player.Name, error))
				end
			end

			playerCheckIndex = playerCheckIndex + 1
		end

		-- Log completion of full cycle (useful for debugging)
		local now = tick()
		if playerCheckIndex > playerCount then
			playerCheckIndex = 1
			local cycleDuration = now - lastFullCycle
			lastFullCycle = now

			-- Debug log every 30 seconds
			if math.floor(now) % 30 < 0.1 then
				print(string.format(
					"[AntiCheat] Full cycle: %d players checked in %.2fs (%.2f checks/sec)",
					playerCount,
					cycleDuration,
					playerCount / cycleDuration
				))
			end
		end
	end)
end

-- Legacy function kept for compatibility (now uses staggered approach)
function AntiCheat:CheckAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local success, error = pcall(function()
			self:CheckPlayer(player)
		end)

		if not success then
			warn(string.format("[AntiCheat] Error checking player %s: %s", player.Name, error))
		end
	end
end

function AntiCheat:CheckPlayer(player: Player)
	local data = self.PlayerData[player.UserId]
	if not data then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	-- Skip if dead
	if humanoid.Health <= 0 then return end

	-- Get current state
	local currentPosition = rootPart.Position
	local currentTime = tick()
	local deltaTime = currentTime - data.LastCheck

	if deltaTime <= 0 then return end -- Prevent division by zero

	-- Check 1: Speed hack
	if data.LastPosition then
		self:CheckSpeed(player, data, currentPosition, deltaTime)
	end

	-- Check 2: Flying
	self:CheckFlying(player, data, humanoid, currentPosition, deltaTime)

	-- Check 3: Teleporting
	if data.LastPosition then
		self:CheckTeleport(player, data, currentPosition)
	end

	-- Update tracking
	data.LastPosition = currentPosition
	data.LastCheck = currentTime
end

-- ============================================================================
-- SPEED DETECTION
-- ============================================================================

function AntiCheat:CheckSpeed(player: Player, data: {}, currentPosition: Vector3, deltaTime: number)
	local distance = (currentPosition - data.LastPosition).Magnitude
	local speed = distance / deltaTime

	-- Ignore vertical component (jumping is allowed)
	local horizontalDistance = Vector2.new(
		currentPosition.X - data.LastPosition.X,
		currentPosition.Z - data.LastPosition.Z
	).Magnitude
	local horizontalSpeed = horizontalDistance / deltaTime

	-- Account for SpeedBoost upgrade (prevents false positives)
	local speedBoostLevel = getDataService().GetUpgradeLevel(player, "SpeedBoost")

	-- Base max speed + 10% per SpeedBoost level
	-- Level 0: 100 studs/s
	-- Level 1: 110 studs/s
	-- Level 2: 120 studs/s
	-- Level 3: 130 studs/s
	-- Level 4: 140 studs/s
	-- Level 5: 150 studs/s
	local maxAllowedSpeed = MAX_SPEED * (1 + (speedBoostLevel * 0.1))

	if horizontalSpeed > maxAllowedSpeed then
		self:LogViolation(player, ViolationType.SPEED_HACK, {
			speed = horizontalSpeed,
			maxSpeed = maxAllowedSpeed,
			speedBoostLevel = speedBoostLevel,
			distance = horizontalDistance,
			deltaTime = deltaTime,
		})
	end
end

-- ============================================================================
-- FLYING DETECTION
-- ============================================================================

function AntiCheat:CheckFlying(player: Player, data: {}, humanoid: Humanoid, currentPosition: Vector3, deltaTime: number)
	-- Check if player is in freefall/flying state
	local state = humanoid:GetState()

	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Flying then
		-- Check vertical speed
		if data.LastPosition then
			local verticalDistance = math.abs(currentPosition.Y - data.LastPosition.Y)
			local verticalSpeed = verticalDistance / deltaTime

			-- Allow some tolerance for jumping/falling
			if verticalSpeed > MAX_VERTICAL_SPEED then
				self:LogViolation(player, ViolationType.FLYING, {
					verticalSpeed = verticalSpeed,
					maxVerticalSpeed = MAX_VERTICAL_SPEED,
					state = tostring(state),
				})
			end
		end
	end
end

-- ============================================================================
-- TELEPORT DETECTION
-- ============================================================================

function AntiCheat:CheckTeleport(player: Player, data: {}, currentPosition: Vector3)
	local distance = (currentPosition - data.LastPosition).Magnitude

	-- Ignore if player just respawned (position changed legitimately)
	-- Use server-side tracking instead of client-controllable attributes
	if getCheckpointService().DidRecentlyRespawn(player) then
		return -- Recently respawned, teleport is legitimate
	end

	if distance > TELEPORT_THRESHOLD then
		self:LogViolation(player, ViolationType.TELEPORT, {
			distance = distance,
			threshold = TELEPORT_THRESHOLD,
			from = data.LastPosition,
			to = currentPosition,
		})
	end
end

-- ============================================================================
-- STAGE SKIP DETECTION
-- ============================================================================

function AntiCheat:CheckStageProgression(player: Player, oldStage: number, newStage: number)
	--[[
		Called by CheckpointService when player reaches new checkpoint
		Validates they didn't skip too many stages
	--]]

	local stageJump = newStage - oldStage

	if stageJump > MAX_STAGE_SKIP then
		self:LogViolation(player, ViolationType.STAGE_SKIP, {
			oldStage = oldStage,
			newStage = newStage,
			jump = stageJump,
			maxAllowed = MAX_STAGE_SKIP,
		})

		-- Revert to old stage (prevent cheating benefit)
		return false
	end

	return true
end

-- ============================================================================
-- VIOLATION HANDLING
-- ============================================================================

function AntiCheat:LogViolation(player: Player, violationType: string, details: {})
	local data = self.PlayerData[player.UserId]
	if not data then return end

	-- Record violation
	local violation = {
		Type = violationType,
		Player = player.Name,
		UserId = player.UserId,
		Timestamp = tick(),
		Details = details,
	}

	-- Add to global log with size limit (removes oldest entries)
	table.insert(self.ViolationLog, violation)
	while #self.ViolationLog > MAX_GLOBAL_VIOLATIONS do
		table.remove(self.ViolationLog, 1)
	end

	-- Add to player log with size limit
	table.insert(data.Violations, violation)
	while #data.Violations > MAX_PLAYER_VIOLATIONS do
		table.remove(data.Violations, 1)
	end

	data.TotalViolations = data.TotalViolations + 1
	self.TotalViolations = self.TotalViolations + 1

	if LOG_VIOLATIONS then
		warn(string.format(
			"[AntiCheat] %s detected for %s (Violation #%d)",
			violationType,
			player.Name,
			data.TotalViolations
		))
	end

	-- Take action
	self:TakeAction(player, data, violationType)
end

function AntiCheat:TakeAction(player: Player, data: {}, violationType: string)
	-- First offense: Warning
	if data.TotalViolations == 1 then
		data.Warnings = data.Warnings + 1
		-- Could send warning message to player here
		return
	end

	-- Second+ offense: Escalate
	if ACTION == "Kick" then
		self:KickPlayer(player, violationType)
	elseif ACTION == "Warn" then
		data.Warnings = data.Warnings + 1
		-- Send another warning
	elseif ACTION == "Log" then
		-- Just log, no action
	end
end

function AntiCheat:KickPlayer(player: Player, violationType: string)
	self.TotalKicks = self.TotalKicks + 1

	local message = string.format(
		"You have been removed for suspicious activity: %s. If this was a mistake, please contact support.",
		violationType
	)

	warn(string.format(
		"[AntiCheat] Kicking %s for %s (Total kicks: %d)",
		player.Name,
		violationType,
		self.TotalKicks
	))

	player:Kick(message)
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function AntiCheat:GetStats(): {}
	return {
		TotalViolations = self.TotalViolations,
		TotalKicks = self.TotalKicks,
		ActivePlayers = #self.PlayerData,
		ViolationLog = self.ViolationLog,
	}
end

function AntiCheat:GetPlayerViolations(player: Player): {}
	local data = self.PlayerData[player.UserId]
	if not data then return {} end

	return data.Violations
end

-- ============================================================================
-- TESTING UTILITIES
-- ============================================================================

function AntiCheat:ForceCheck(player: Player)
	self:CheckPlayer(player)
end

function AntiCheat:ClearViolations(player: Player)
	local data = self.PlayerData[player.UserId]
	if data then
		data.Violations = {}
		data.Warnings = 0
		data.TotalViolations = 0
	end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return AntiCheat
