--[[
	GravityService.lua
	Handles gravity manipulation for the Gravity Dimension

	Features:
	- Gravity flip zones (90° and 180° rotations)
	- Per-player gravity direction tracking
	- Smooth gravity transitions
	- Momentum preservation through flips

	How it works:
	1. Player touches GravityFlip zone
	2. Server calculates new gravity direction
	3. Player rotates smoothly to new orientation
	4. Gravity vector changes for that player only
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GravityService = {}

-- ============================================================================
-- STATE
-- ============================================================================

-- Track each player's gravity state
-- [UserId] = { direction = Vector3, isFlipping = bool, lastFlipTime = number }
GravityService.PlayerGravity = {}

-- Gravity directions
GravityService.Directions = {
	Down = Vector3.new(0, -1, 0),
	Up = Vector3.new(0, 1, 0),
	Left = Vector3.new(-1, 0, 0),
	Right = Vector3.new(1, 0, 0),
	Forward = Vector3.new(0, 0, -1),
	Back = Vector3.new(0, 0, 1),
}

-- Configuration
local CONFIG = {
	FlipCooldown = 0.5, -- Seconds between flips
	FlipDuration = 0.3, -- Seconds for rotation animation
	GravityStrength = 196.2, -- Standard Roblox gravity
	MomentumPreservation = 0.8, -- How much velocity to keep through flip
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GravityService.Init()
	print("[GravityService] Initializing...")

	-- Create remotes
	GravityService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		GravityService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GravityService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		GravityService.OnPlayerJoin(player)
	end

	-- Setup gravity flip zone detection
	GravityService.SetupFlipZones()

	print("[GravityService] Initialized")
end

function GravityService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Gravity flip event (server -> client)
	if not remoteFolder:FindFirstChild("GravityFlip") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GravityFlip"
		event.Parent = remoteFolder
	end

	-- Gravity state sync
	if not remoteFolder:FindFirstChild("GravitySync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GravitySync"
		event.Parent = remoteFolder
	end

	GravityService.Remotes = {
		GravityFlip = remoteFolder.GravityFlip,
		GravitySync = remoteFolder.GravitySync,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function GravityService.OnPlayerJoin(player: Player)
	GravityService.PlayerGravity[player.UserId] = {
		direction = GravityService.Directions.Down,
		isFlipping = false,
		lastFlipTime = 0,
	}

	-- Setup character gravity when spawned
	player.CharacterAdded:Connect(function(character)
		GravityService.OnCharacterAdded(player, character)
	end)

	if player.Character then
		GravityService.OnCharacterAdded(player, player.Character)
	end
end

function GravityService.OnPlayerLeave(player: Player)
	GravityService.PlayerGravity[player.UserId] = nil
end

function GravityService.OnCharacterAdded(player: Player, character: Model)
	-- Reset gravity to normal when character spawns
	GravityService.ResetGravity(player)

	-- Apply current gravity state
	local gravityState = GravityService.PlayerGravity[player.UserId]
	if gravityState then
		GravityService.ApplyGravityToCharacter(character, gravityState.direction)
	end
end

-- ============================================================================
-- GRAVITY FLIP ZONES
-- ============================================================================

function GravityService.SetupFlipZones()
	-- Connect to existing flip zones
	for _, zone in ipairs(CollectionService:GetTagged("GravityFlip")) do
		GravityService.ConnectFlipZone(zone)
	end

	-- Listen for new flip zones
	CollectionService:GetInstanceAddedSignal("GravityFlip"):Connect(function(zone)
		GravityService.ConnectFlipZone(zone)
	end)
end

function GravityService.ConnectFlipZone(zone: BasePart)
	zone.Touched:Connect(function(hit)
		GravityService.OnFlipZoneTouched(zone, hit)
	end)
end

function GravityService.OnFlipZoneTouched(zone: BasePart, hit: BasePart)
	-- Verify it's a player
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check cooldown
	local gravityState = GravityService.PlayerGravity[player.UserId]
	if not gravityState then return end

	local now = tick()
	if gravityState.isFlipping or (now - gravityState.lastFlipTime) < CONFIG.FlipCooldown then
		return
	end

	-- Get flip direction from zone
	local flipDirection = zone:GetAttribute("FlipDirection") or "Down"

	-- Execute gravity flip
	GravityService.FlipGravity(player, flipDirection)
end

-- ============================================================================
-- GRAVITY MANIPULATION
-- ============================================================================

function GravityService.FlipGravity(player: Player, direction: string)
	local gravityState = GravityService.PlayerGravity[player.UserId]
	if not gravityState then return end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Mark as flipping
	gravityState.isFlipping = true
	gravityState.lastFlipTime = tick()

	-- Calculate new gravity direction
	local newDirection = GravityService.CalculateNewDirection(gravityState.direction, direction)
	local oldDirection = gravityState.direction

	-- Store current velocity for momentum preservation
	local currentVelocity = humanoidRootPart.AssemblyLinearVelocity

	-- Update gravity state
	gravityState.direction = newDirection

	-- Notify client to play flip animation
	GravityService.Remotes.GravityFlip:FireClient(player, {
		OldDirection = oldDirection,
		NewDirection = newDirection,
		Duration = CONFIG.FlipDuration,
	})

	-- Apply gravity change after animation
	task.delay(CONFIG.FlipDuration, function()
		if player.Character == character then
			GravityService.ApplyGravityToCharacter(character, newDirection)

			-- Apply preserved momentum in new orientation
			if CONFIG.MomentumPreservation > 0 then
				local preservedVelocity = GravityService.TransformVelocity(
					currentVelocity, oldDirection, newDirection
				) * CONFIG.MomentumPreservation

				humanoidRootPart.AssemblyLinearVelocity = preservedVelocity
			end

			gravityState.isFlipping = false
		end
	end)

	print(string.format("[GravityService] %s gravity flipped to %s",
		player.Name, direction))
end

function GravityService.CalculateNewDirection(currentDirection: Vector3, flipType: string): Vector3
	-- Calculate new gravity direction based on flip type
	if flipType == "Up" then
		return GravityService.Directions.Up
	elseif flipType == "Down" then
		return GravityService.Directions.Down
	elseif flipType == "Left" then
		return GravityService.Directions.Left
	elseif flipType == "Right" then
		return GravityService.Directions.Right
	elseif flipType == "Reverse" then
		return -currentDirection
	elseif flipType == "Random" then
		local directions = {"Down", "Up", "Left", "Right"}
		return GravityService.Directions[directions[math.random(1, #directions)]]
	end

	return currentDirection
end

function GravityService.ApplyGravityToCharacter(character: Model, direction: Vector3)
	-- Use BodyForce or custom gravity controller
	-- For simplicity, we'll use character attributes that the client reads

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Set gravity direction attribute (client will handle physics)
	rootPart:SetAttribute("GravityDirection", direction)

	-- Calculate rotation to align with gravity
	local upVector = -direction
	local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(0, 0, -1))

	-- Adjust for non-standard gravity
	if direction ~= GravityService.Directions.Down then
		-- Calculate rotation needed
		local defaultUp = Vector3.new(0, 1, 0)
		local rotationAxis = defaultUp:Cross(upVector)

		if rotationAxis.Magnitude > 0.001 then
			local angle = math.acos(math.clamp(defaultUp:Dot(upVector), -1, 1))
			local rotation = CFrame.fromAxisAngle(rotationAxis.Unit, angle)
			targetCFrame = rotation * targetCFrame
		elseif upVector.Y < 0 then
			-- 180 degree flip
			targetCFrame = CFrame.Angles(math.pi, 0, 0) * targetCFrame
		end
	end

	rootPart:SetAttribute("TargetOrientation", targetCFrame)
end

function GravityService.TransformVelocity(velocity: Vector3, oldDir: Vector3, newDir: Vector3): Vector3
	-- Transform velocity from old gravity frame to new gravity frame
	-- This preserves momentum through gravity changes

	-- Calculate rotation between directions
	local rotationAxis = oldDir:Cross(newDir)
	if rotationAxis.Magnitude < 0.001 then
		-- Parallel or anti-parallel
		if oldDir:Dot(newDir) < 0 then
			-- 180 degree flip - invert vertical component
			return Vector3.new(velocity.X, -velocity.Y, velocity.Z)
		end
		return velocity
	end

	local angle = math.acos(math.clamp(oldDir:Dot(newDir), -1, 1))
	local rotation = CFrame.fromAxisAngle(rotationAxis.Unit, angle)

	return rotation:VectorToWorldSpace(velocity)
end

-- ============================================================================
-- RESET & UTILITIES
-- ============================================================================

function GravityService.ResetGravity(player: Player)
	local gravityState = GravityService.PlayerGravity[player.UserId]
	if gravityState then
		gravityState.direction = GravityService.Directions.Down
		gravityState.isFlipping = false
	end

	if player.Character then
		GravityService.ApplyGravityToCharacter(player.Character, GravityService.Directions.Down)
	end

	-- Notify client
	GravityService.Remotes.GravitySync:FireClient(player, GravityService.Directions.Down)
end

function GravityService.GetPlayerGravity(player: Player): Vector3
	local gravityState = GravityService.PlayerGravity[player.UserId]
	return gravityState and gravityState.direction or GravityService.Directions.Down
end

function GravityService.IsPlayerFlipping(player: Player): boolean
	local gravityState = GravityService.PlayerGravity[player.UserId]
	return gravityState and gravityState.isFlipping or false
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function GravityService.Cleanup()
	-- Reset all players to normal gravity
	for _, player in ipairs(Players:GetPlayers()) do
		GravityService.ResetGravity(player)
	end

	print("[GravityService] Cleaned up")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function GravityService.DebugPrint()
	print("=== GRAVITY SERVICE STATUS ===")

	for userId, state in pairs(GravityService.PlayerGravity) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Direction=%s, Flipping=%s",
				player.Name,
				tostring(state.direction),
				tostring(state.isFlipping)
			))
		end
	end

	print("===============================")
end

return GravityService
