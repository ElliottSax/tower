--[[
	ParticleHandler.lua
	Client-side particle effect spawner

	Features:
	- Listens to SpawnParticle RemoteEvent
	- Creates actual ParticleEmitter objects
	- Auto-cleanup after duration
	- Performance management (max 50 active particles)
	- Different particle types for different events

	Particle Effects:
	- CheckpointReached (confetti burst)
	- TowerCompleted (fireworks explosion)
	- CoinPickup (gold sparkles)
	- DoubleJump (blue trail)
	- AirDash (cyan speed lines)
	- WallGrip (gray dust)
	- LevelUp (golden glow)
	- UpgradePurchased (green flash)

	Week 4: Full implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[ParticleHandler] RemoteEvents folder not found!")
	return
end

local spawnParticleEvent = remoteFolder:WaitForChild("SpawnParticle", 10)
if not spawnParticleEvent then
	warn("[ParticleHandler] SpawnParticle event not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MAX_ACTIVE_PARTICLES = 50
local activeParticleCount = 0

-- ============================================================================
-- PARTICLE CREATORS
-- ============================================================================

local function createConfettiParticle(position: Vector3)
	-- Checkpoint reached effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 100
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(10, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	-- Burst effect
	emitter:Emit(30)

	Debris:AddItem(part, 2)
	return part
end

local function createFireworksParticle(position: Vector3)
	-- Tower completed effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position + Vector3.new(0, 10, 0) -- Spawn above
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 200
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Speed = NumberRange.new(15, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(100, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	-- Multiple bursts
	emitter:Emit(50)
	task.delay(0.2, function() emitter:Emit(40) end)
	task.delay(0.4, function() emitter:Emit(30) end)

	Debris:AddItem(part, 3)
	return part
end

local function createSparklesParticle(position: Vector3)
	-- Coin pickup effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 50
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Acceleration = Vector3.new(0, 5, 0) -- Float upward
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	emitter:Emit(15)

	Debris:AddItem(part, 1)
	return part
end

local function createTrailParticle(position: Vector3)
	-- Double jump trail effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 80
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	emitter:Emit(20)

	Debris:AddItem(part, 0.5)
	return part
end

local function createSpeedLinesParticle(position: Vector3, direction: Vector3?)
	-- Air dash effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 100
	emitter.Lifetime = NumberRange.new(0.2, 0.3)
	emitter.Speed = NumberRange.new(5, 15)
	emitter.SpreadAngle = Vector2.new(10, 10)
	emitter.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.Parent = part

	emitter:Emit(25)

	Debris:AddItem(part, 0.3)
	return part
end

local function createDustParticle(position: Vector3)
	-- Wall grip effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 30
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part

	emitter:Emit(10)

	Debris:AddItem(part, 1)
	return part
end

local function createGlowParticle(position: Vector3)
	-- Level up effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, 10, 0)
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.Parent = part

	emitter:Emit(40)

	Debris:AddItem(part, 2)
	return part
end

local function createFlashParticle(position: Vector3)
	-- Upgrade purchased effect
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 100
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(8, 15)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.8
	emitter.Parent = part

	emitter:Emit(35)

	Debris:AddItem(part, 1)
	return part
end

-- ============================================================================
-- PARTICLE SPAWNER
-- ============================================================================

local ParticleCreators = {
	CheckpointReached = createConfettiParticle,
	TowerCompleted = createFireworksParticle,
	CoinPickup = createSparklesParticle,
	DoubleJump = createTrailParticle,
	AirDash = createSpeedLinesParticle,
	WallGrip = createDustParticle,
	LevelUp = createGlowParticle,
	UpgradePurchased = createFlashParticle,
}

local function spawnParticle(effectName: string, position: Vector3)
	-- Check performance limit
	if activeParticleCount >= MAX_ACTIVE_PARTICLES then
		-- Skip particle (performance)
		return
	end

	local creator = ParticleCreators[effectName]
	if not creator then
		warn("[ParticleHandler] Unknown effect:", effectName)
		return
	end

	-- Create particle
	activeParticleCount = activeParticleCount + 1

	local particle = creator(position)

	-- Track cleanup
	task.delay(3, function()
		activeParticleCount = math.max(0, activeParticleCount - 1)
	end)

	print(string.format(
		"[ParticleHandler] Spawned %s at %s (Active: %d)",
		effectName,
		tostring(position),
		activeParticleCount
	))
end

-- ============================================================================
-- REMOTE EVENT LISTENER
-- ============================================================================

spawnParticleEvent.OnClientEvent:Connect(function(effectName: string, position: Vector3)
	spawnParticle(effectName, position)
end)

print("[ParticleHandler] Initialized (listening for particle events)")
