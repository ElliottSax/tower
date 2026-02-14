--[[
	ParticleService.lua
	Centralized particle effect management

	Features:
	- Spawn particle effects at positions
	- Predefined effect templates
	- Automatic cleanup after duration
	- RemoteEvent to trigger effects on clients
	- Performance management (limit active particles)

	Effects (Week 3 placeholders, Week 4+ full implementation):
	- Checkpoint reached (confetti)
	- Tower completion (fireworks)
	- Coin pickup (sparkles)
	- Double jump (trail)
	- Air dash (speed lines)
	- Wall grip (dust particles)
	- Level up (glow)
	- Purchase upgrade (flash)

	Week 3: Basic structure
	Week 4+: Full particle effects with colors, sizes, speeds
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParticleService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MAX_ACTIVE_PARTICLES = 100 -- Performance limit
local DEFAULT_DURATION = 2 -- Seconds

-- ============================================================================
-- STATE
-- ============================================================================

ParticleService.ActiveParticles = {}

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

ParticleService.RemoteEvents = {}

local function setupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- SpawnParticle: Server → Client (spawn effect on client)
	local spawnParticleEvent = Instance.new("RemoteEvent")
	spawnParticleEvent.Name = "SpawnParticle"
	spawnParticleEvent.Parent = remoteFolder
	ParticleService.RemoteEvents.SpawnParticle = spawnParticleEvent

	print("[ParticleService] RemoteEvents setup complete")
end

-- ============================================================================
-- PARTICLE TEMPLATES (WEEK 4 IMPLEMENTATION)
-- ============================================================================

ParticleService.Templates = {
	CheckpointReached = {
		Type = "Confetti",
		Duration = 2,
		Color = Color3.fromRGB(255, 255, 0),
		-- Week 4: Add ParticleEmitter properties
	},

	TowerCompleted = {
		Type = "Fireworks",
		Duration = 3,
		Color = Color3.fromRGB(255, 215, 0),
		-- Week 4: Add ParticleEmitter properties
	},

	CoinPickup = {
		Type = "Sparkles",
		Duration = 1,
		Color = Color3.fromRGB(255, 215, 0),
		-- Week 4: Add ParticleEmitter properties
	},

	DoubleJump = {
		Type = "Trail",
		Duration = 0.5,
		Color = Color3.fromRGB(100, 200, 255),
		-- Week 4: Add ParticleEmitter properties
	},

	AirDash = {
		Type = "SpeedLines",
		Duration = 0.3,
		Color = Color3.fromRGB(100, 200, 255),
		-- Week 4: Add ParticleEmitter properties
	},

	WallGrip = {
		Type = "Dust",
		Duration = 1,
		Color = Color3.fromRGB(150, 150, 150),
		-- Week 4: Add ParticleEmitter properties
	},

	LevelUp = {
		Type = "Glow",
		Duration = 2,
		Color = Color3.fromRGB(255, 215, 0),
		-- Week 4: Add ParticleEmitter properties
	},

	UpgradePurchased = {
		Type = "Flash",
		Duration = 1,
		Color = Color3.fromRGB(100, 255, 100),
		-- Week 4: Add ParticleEmitter properties
	},
}

-- ============================================================================
-- SPAWN PARTICLE
-- ============================================================================

function ParticleService.SpawnParticle(effectName: string, position: Vector3, target: Player?)
	-- Week 4: Full implementation with actual ParticleEmitter
	-- For now, just log and send to clients

	local template = ParticleService.Templates[effectName]
	if not template then
		warn("[ParticleService] Unknown effect:", effectName)
		return
	end

	print(string.format(
		"[ParticleService] Spawning %s at %s",
		effectName,
		tostring(position)
	))

	-- Send to clients
	if target then
		-- Send to specific player
		ParticleService.RemoteEvents.SpawnParticle:FireClient(target, effectName, position)
	else
		-- Send to all players
		ParticleService.RemoteEvents.SpawnParticle:FireAllClients(effectName, position)
	end

	-- Week 4: Create actual ParticleEmitter
	-- local particle = createParticleEmitter(template)
	-- particle.Position = position
	-- particle.Parent = workspace
	-- cleanup after duration
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function ParticleService.CleanupOldParticles()
	-- Week 4: Remove old particle effects to maintain performance
	-- For now, no-op (placeholder)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ParticleService.Init()
	print("[ParticleService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Start cleanup loop (Week 4)
	-- task.spawn(function()
	-- 	while true do
	-- 		task.wait(5)
	-- 		ParticleService.CleanupOldParticles()
	-- 	end
	-- end)

	print("[ParticleService] Initialized (Week 3 placeholder)")
	print("[ParticleService] Full effects coming in Week 4")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ParticleService
