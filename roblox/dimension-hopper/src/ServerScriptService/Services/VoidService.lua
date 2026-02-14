--[[
	VoidService.lua
	Handles the chasing void mechanic for the Void Dimension

	Features:
	- The Void chases players from behind
	- Platforms crumble after being touched
	- Checkpoints create safe zones (pause Void)
	- Tension audio cues when Void is near
	- Instant death if caught by Void

	How it works:
	1. Void starts at beginning of dimension
	2. Void moves forward at increasing speed
	3. Players must stay ahead of the Void
	4. Platforms crumble X seconds after touch
	5. Checkpoints pause Void for Y seconds
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local VoidService = {}

-- ============================================================================
-- STATE
-- ============================================================================

VoidService.IsActive = false
VoidService.VoidPosition = 0 -- Y position of the Void
VoidService.VoidSpeed = 15 -- Current speed (increases over time)
VoidService.BaseSpeed = 15
VoidService.IsPaused = false
VoidService.PauseEndTime = 0

VoidService.VoidPart = nil -- Visual representation
VoidService.CrumblingPlatforms = {} -- [Part] = { touchTime, isCrumbling }
VoidService.PlayerLastSection = {} -- Track player progress for speed scaling

VoidService.UpdateConnection = nil

-- Configuration (from dimension config)
local CONFIG = {
	BaseSpeed = 15,
	Acceleration = 0.5, -- Speed increase per section
	MaxSpeed = 50,
	CrumbleDelay = 2.5,
	CrumbleDuration = 0.5,
	SafeZoneDuration = 5,
	KillHeight = -50, -- Below this Y = death
	VoidDamage = math.huge, -- Instant kill
	WarningDistance = 30, -- Start warning sounds at this distance
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function VoidService.Init()
	print("[VoidService] Initializing...")

	-- Create remotes
	VoidService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		VoidService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		VoidService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		VoidService.OnPlayerJoin(player)
	end

	-- Setup crumbling platform detection
	VoidService.SetupCrumblingPlatforms()

	print("[VoidService] Initialized")
end

function VoidService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Void position update (for client visuals)
	if not remoteFolder:FindFirstChild("VoidUpdate") then
		local event = Instance.new("RemoteEvent")
		event.Name = "VoidUpdate"
		event.Parent = remoteFolder
	end

	-- Void warning (proximity alert)
	if not remoteFolder:FindFirstChild("VoidWarning") then
		local event = Instance.new("RemoteEvent")
		event.Name = "VoidWarning"
		event.Parent = remoteFolder
	end

	-- Platform crumble
	if not remoteFolder:FindFirstChild("PlatformCrumble") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlatformCrumble"
		event.Parent = remoteFolder
	end

	VoidService.Remotes = {
		VoidUpdate = remoteFolder.VoidUpdate,
		VoidWarning = remoteFolder.VoidWarning,
		PlatformCrumble = remoteFolder.PlatformCrumble,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function VoidService.OnPlayerJoin(player: Player)
	VoidService.PlayerLastSection[player.UserId] = 0

	player.CharacterAdded:Connect(function(character)
		VoidService.OnCharacterAdded(player, character)
	end)
end

function VoidService.OnPlayerLeave(player: Player)
	VoidService.PlayerLastSection[player.UserId] = nil
end

function VoidService.OnCharacterAdded(player: Player, character: Model)
	-- Setup death detection
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			-- Player died, respawn at checkpoint
		end)
	end
end

-- ============================================================================
-- VOID CONTROL
-- ============================================================================

function VoidService.Start(startPosition: number?)
	if VoidService.IsActive then return end

	VoidService.IsActive = true
	VoidService.VoidPosition = startPosition or -20
	VoidService.VoidSpeed = CONFIG.BaseSpeed
	VoidService.IsPaused = false

	-- Create void visual
	VoidService.CreateVoidVisual()

	-- Start update loop
	VoidService.UpdateConnection = RunService.Heartbeat:Connect(function(dt)
		VoidService.Update(dt)
	end)

	print("[VoidService] Void started at position:", VoidService.VoidPosition)
end

function VoidService.Stop()
	if not VoidService.IsActive then return end

	VoidService.IsActive = false

	-- Disconnect update
	if VoidService.UpdateConnection then
		VoidService.UpdateConnection:Disconnect()
		VoidService.UpdateConnection = nil
	end

	-- Destroy void visual
	if VoidService.VoidPart then
		VoidService.VoidPart:Destroy()
		VoidService.VoidPart = nil
	end

	-- Reset crumbling platforms
	for platform, data in pairs(VoidService.CrumblingPlatforms) do
		if platform and platform.Parent then
			platform.Transparency = 0
			platform.CanCollide = true
		end
	end
	VoidService.CrumblingPlatforms = {}

	print("[VoidService] Void stopped")
end

function VoidService.Pause(duration: number)
	VoidService.IsPaused = true
	VoidService.PauseEndTime = tick() + duration

	print(string.format("[VoidService] Void paused for %.1f seconds", duration))
end

function VoidService.CreateVoidVisual()
	-- Create the visual representation of the Void
	local voidPart = Instance.new("Part")
	voidPart.Name = "TheVoid"
	voidPart.Size = Vector3.new(500, 10, 500)
	voidPart.Position = Vector3.new(0, VoidService.VoidPosition, 0)
	voidPart.Anchored = true
	voidPart.CanCollide = false
	voidPart.Material = Enum.Material.Neon
	voidPart.Color = Color3.fromRGB(20, 0, 0)
	voidPart.Transparency = 0.3

	-- Add creepy effects
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 5),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(2, 4)
	particles.Rate = 50
	particles.Speed = NumberRange.new(10, 20)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = voidPart

	-- Add glow
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 0, 0)
	light.Brightness = 2
	light.Range = 60
	light.Parent = voidPart

	voidPart.Parent = workspace
	VoidService.VoidPart = voidPart
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function VoidService.Update(dt: number)
	if not VoidService.IsActive then return end

	-- Check if paused
	if VoidService.IsPaused then
		if tick() >= VoidService.PauseEndTime then
			VoidService.IsPaused = false
			print("[VoidService] Void resumed")
		else
			return -- Still paused
		end
	end

	-- Move void forward
	VoidService.VoidPosition = VoidService.VoidPosition + (VoidService.VoidSpeed * dt)

	-- Update void visual
	if VoidService.VoidPart then
		VoidService.VoidPart.Position = Vector3.new(0, VoidService.VoidPosition, 0)
	end

	-- Increase speed over time (based on highest player section)
	VoidService.UpdateSpeed()

	-- Check for player catches
	VoidService.CheckPlayerCatches()

	-- Update crumbling platforms
	VoidService.UpdateCrumblingPlatforms(dt)

	-- Send position update to clients
	VoidService.Remotes.VoidUpdate:FireAllClients(VoidService.VoidPosition, VoidService.VoidSpeed)

	-- Send warnings to nearby players
	VoidService.SendProximityWarnings()
end

function VoidService.UpdateSpeed()
	-- Find highest player section
	local highestSection = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local section = VoidService.PlayerLastSection[player.UserId] or 0
		if section > highestSection then
			highestSection = section
		end
	end

	-- Scale speed based on section
	local targetSpeed = CONFIG.BaseSpeed + (highestSection * CONFIG.Acceleration)
	targetSpeed = math.min(targetSpeed, CONFIG.MaxSpeed)

	-- Smooth speed transition
	VoidService.VoidSpeed = VoidService.VoidSpeed + (targetSpeed - VoidService.VoidSpeed) * 0.1
end

function VoidService.CheckPlayerCatches()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		-- Check if player is below void
		if rootPart.Position.Y < VoidService.VoidPosition then
			-- Caught by the void!
			VoidService.OnPlayerCaught(player)
		end
	end
end

function VoidService.OnPlayerCaught(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	print(string.format("[VoidService] %s was caught by the Void!", player.Name))

	-- Kill player
	humanoid.Health = 0

	-- Notify client (for death effect)
	VoidService.Remotes.VoidWarning:FireClient(player, "CAUGHT")
end

function VoidService.SendProximityWarnings()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end

		local distance = rootPart.Position.Y - VoidService.VoidPosition

		if distance < CONFIG.WarningDistance then
			-- Calculate intensity (0-1, higher = closer)
			local intensity = 1 - (distance / CONFIG.WarningDistance)
			intensity = math.clamp(intensity, 0, 1)

			VoidService.Remotes.VoidWarning:FireClient(player, "NEAR", intensity)
		end
	end
end

-- ============================================================================
-- CRUMBLING PLATFORMS
-- ============================================================================

function VoidService.SetupCrumblingPlatforms()
	-- Connect to existing platforms
	for _, platform in ipairs(CollectionService:GetTagged("CrumblingPlatform")) do
		VoidService.ConnectCrumblingPlatform(platform)
	end

	-- Listen for new platforms
	CollectionService:GetInstanceAddedSignal("CrumblingPlatform"):Connect(function(platform)
		VoidService.ConnectCrumblingPlatform(platform)
	end)

	-- Cleanup removed platforms
	CollectionService:GetInstanceRemovedSignal("CrumblingPlatform"):Connect(function(platform)
		VoidService.CrumblingPlatforms[platform] = nil
	end)
end

function VoidService.ConnectCrumblingPlatform(platform: BasePart)
	platform.Touched:Connect(function(hit)
		VoidService.OnPlatformTouched(platform, hit)
	end)
end

function VoidService.OnPlatformTouched(platform: BasePart, hit: BasePart)
	-- Check if void is active
	if not VoidService.IsActive then return end

	-- Check if already crumbling
	if VoidService.CrumblingPlatforms[platform] then return end

	-- Verify it's a player
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Start crumble timer
	local crumbleDelay = platform:GetAttribute("CrumbleDelay") or CONFIG.CrumbleDelay

	VoidService.CrumblingPlatforms[platform] = {
		touchTime = tick(),
		crumbleDelay = crumbleDelay,
		isCrumbling = false,
		originalColor = platform.Color,
		originalTransparency = platform.Transparency,
	}

	-- Notify clients to show warning effect
	VoidService.Remotes.PlatformCrumble:FireAllClients(platform, "WARNING", crumbleDelay)

	print(string.format("[VoidService] Platform touched, crumbling in %.1fs", crumbleDelay))
end

function VoidService.UpdateCrumblingPlatforms(dt: number)
	local now = tick()

	for platform, data in pairs(VoidService.CrumblingPlatforms) do
		if not platform or not platform.Parent then
			VoidService.CrumblingPlatforms[platform] = nil
			continue
		end

		local elapsed = now - data.touchTime

		if not data.isCrumbling then
			-- Warning phase - show visual warning
			local warningProgress = elapsed / data.crumbleDelay
			warningProgress = math.clamp(warningProgress, 0, 1)

			-- Flash red based on progress
			local flashIntensity = math.sin(elapsed * 10) * 0.5 + 0.5
			platform.Color = data.originalColor:Lerp(
				Color3.fromRGB(255, 50, 50),
				warningProgress * flashIntensity
			)

			-- Start crumbling when delay reached
			if elapsed >= data.crumbleDelay then
				data.isCrumbling = true
				data.crumbleStartTime = now

				-- Notify clients
				VoidService.Remotes.PlatformCrumble:FireAllClients(platform, "CRUMBLE")
			end
		else
			-- Crumbling phase
			local crumbleElapsed = now - data.crumbleStartTime
			local crumbleProgress = crumbleElapsed / CONFIG.CrumbleDuration

			if crumbleProgress < 1 then
				-- Fade out and shake
				platform.Transparency = data.originalTransparency + (1 - data.originalTransparency) * crumbleProgress

				-- Shake effect
				local shake = Vector3.new(
					math.random() - 0.5,
					math.random() - 0.5,
					math.random() - 0.5
				) * (1 - crumbleProgress) * 0.5

				platform.CFrame = platform.CFrame + shake
			else
				-- Fully crumbled - disable collision
				platform.CanCollide = false
				platform.Transparency = 1

				-- Remove from tracking (but keep part for potential reset)
				VoidService.CrumblingPlatforms[platform] = nil

				-- Notify clients
				VoidService.Remotes.PlatformCrumble:FireAllClients(platform, "DESTROYED")
			end
		end
	end
end

-- ============================================================================
-- CHECKPOINT INTEGRATION
-- ============================================================================

function VoidService.OnPlayerReachCheckpoint(player: Player, sectionNumber: number)
	-- Update player's section
	VoidService.PlayerLastSection[player.UserId] = sectionNumber

	-- Pause void at checkpoints
	if VoidService.IsActive then
		VoidService.Pause(CONFIG.SafeZoneDuration)
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function VoidService.Cleanup()
	VoidService.Stop()

	-- Reset all platform states
	for _, platform in ipairs(CollectionService:GetTagged("CrumblingPlatform")) do
		if platform and platform.Parent then
			platform.Transparency = 0
			platform.CanCollide = true
		end
	end

	print("[VoidService] Cleaned up")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function VoidService.DebugPrint()
	print("=== VOID SERVICE STATUS ===")
	print(string.format("Active: %s", tostring(VoidService.IsActive)))
	print(string.format("Position: %.1f", VoidService.VoidPosition))
	print(string.format("Speed: %.1f / %.1f", VoidService.VoidSpeed, CONFIG.MaxSpeed))
	print(string.format("Paused: %s", tostring(VoidService.IsPaused)))
	print(string.format("Crumbling Platforms: %d", VoidService.CountTable(VoidService.CrumblingPlatforms)))
	print("============================")
end

function VoidService.CountTable(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

return VoidService
