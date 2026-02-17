--[[
	AbilityController.lua - Speed Run Universe (Client)
	Handles ability keybind detection, visual effects, and communication with server.
	Runs in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local AbilityController = {}

-- ============================================================================
-- STATE
-- ============================================================================
local equippedAbilities = {}   -- { abilityId -> config }
local abilityCooldowns = {}    -- { abilityId -> cooldownEndTick }
local abilityCharges = {}      -- { abilityId -> remainingCharges }
local isGliding = false
local doubleJumpReady = false
local hasJumped = false

-- Visual effect references
local glideWings = nil
local dashTrail = nil

-- ============================================================================
-- INIT
-- ============================================================================
function AbilityController.Init()
	-- Input handling
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		AbilityController._OnInput(input)
	end)

	-- Jump detection for double jump
	UserInputService.JumpRequest:Connect(function()
		AbilityController._OnJumpRequest()
	end)

	-- Listen for ability sync from server
	remoteEvents:WaitForChild("AbilitySync").OnClientEvent:Connect(function(data)
		AbilityController._OnAbilitySync(data)
	end)

	-- Listen for ability unlocks
	remoteEvents:WaitForChild("UnlockAbility").OnClientEvent:Connect(function(data)
		AbilityController._OnAbilityUnlocked(data)
	end)

	-- Character tracking for jump state
	player.CharacterAdded:Connect(function(character)
		AbilityController._SetupCharacter(character)
	end)
	if player.Character then
		AbilityController._SetupCharacter(player.Character)
	end

	-- Cooldown tick
	RunService.Heartbeat:Connect(function(dt)
		AbilityController._Tick(dt)
	end)

	print("[AbilityController] Initialized")
end

-- ============================================================================
-- CHARACTER SETUP
-- ============================================================================
function AbilityController._SetupCharacter(character)
	hasJumped = false
	doubleJumpReady = false
	isGliding = false

	local humanoid = character:WaitForChild("Humanoid")

	-- Track jump state for double jump
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			hasJumped = true
			doubleJumpReady = true
		elseif newState == Enum.HumanoidStateType.Landed then
			hasJumped = false
			doubleJumpReady = false
			isGliding = false

			-- Reset double jump charges
			if abilityCharges["DoubleJump"] ~= nil then
				local cfg = GameConfig.AbilityById["DoubleJump"]
				abilityCharges["DoubleJump"] = cfg and cfg.MaxCharges or 1
			end
		elseif newState == Enum.HumanoidStateType.Freefall then
			doubleJumpReady = true
		end
	end)
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================
function AbilityController._OnInput(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	for abilityId, cfg in pairs(equippedAbilities) do
		if input.KeyCode == cfg.KeyBind then
			-- Special handling for glide toggle
			if abilityId == "Glide" then
				if isGliding then
					isGliding = false
					AbilityController._StopGlideVisuals()
					return
				end
			end

			AbilityController._TryUseAbility(abilityId)
			return
		end
	end
end

function AbilityController._OnJumpRequest()
	-- Double jump check
	if not equippedAbilities["DoubleJump"] then return end
	if not doubleJumpReady then return end
	if not hasJumped then return end

	local charges = abilityCharges["DoubleJump"] or 0
	if charges <= 0 then return end

	-- Check cooldown
	if AbilityController._IsOnCooldown("DoubleJump") then return end

	-- Use the ability
	abilityCharges["DoubleJump"] = charges - 1
	AbilityController._TryUseAbility("DoubleJump")
	doubleJumpReady = false
end

-- ============================================================================
-- ABILITY EXECUTION
-- ============================================================================
function AbilityController._TryUseAbility(abilityId)
	local cfg = equippedAbilities[abilityId]
	if not cfg then return end

	-- Check cooldown
	if AbilityController._IsOnCooldown(abilityId) then return end

	-- Set cooldown
	if cfg.Cooldown > 0 then
		abilityCooldowns[abilityId] = tick() + cfg.Cooldown
	end

	-- Fire to server for validation and physics
	remoteEvents:WaitForChild("UseAbility"):FireServer({ AbilityId = abilityId })

	-- Play local visual effects (immediate feedback)
	AbilityController._PlayAbilityVisuals(abilityId, cfg)
end

function AbilityController._IsOnCooldown(abilityId)
	local endTime = abilityCooldowns[abilityId]
	if not endTime then return false end
	return tick() < endTime
end

-- ============================================================================
-- VISUAL EFFECTS (client-side for responsiveness)
-- ============================================================================
function AbilityController._PlayAbilityVisuals(abilityId, cfg)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if abilityId == "DoubleJump" then
		-- Burst particle effect
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Lifetime = NumberRange.new(0.3, 0.5)
		particles.Rate = 100
		particles.Speed = NumberRange.new(5, 10)
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Parent = hrp

		task.delay(0.15, function()
			particles.Enabled = false
			task.delay(0.5, function()
				if particles.Parent then particles:Destroy() end
			end)
		end)

	elseif abilityId == "Dash" then
		-- Speed lines / trail burst
		AbilityController._CreateDashTrail(hrp, cfg.Duration)

		-- Camera shake
		AbilityController._CameraShake(0.1, 2)

	elseif abilityId == "WallRun" then
		-- Running sparkles along walls
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Lifetime = NumberRange.new(0.2, 0.4)
		particles.Rate = 50
		particles.Speed = NumberRange.new(2, 5)
		particles.Parent = hrp

		task.delay(cfg.Duration, function()
			particles.Enabled = false
			task.delay(0.5, function()
				if particles.Parent then particles:Destroy() end
			end)
		end)

	elseif abilityId == "Grapple" then
		-- Grapple visual is mostly handled by server (beam)
		-- Add a small launch particle
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
		particles.Size = NumberSequence.new(0.2)
		particles.Lifetime = NumberRange.new(0.1, 0.3)
		particles.Rate = 30
		particles.Speed = NumberRange.new(10, 20)
		particles.SpreadAngle = Vector2.new(15, 15)
		particles.Parent = hrp

		task.delay(0.3, function()
			particles.Enabled = false
			task.delay(0.3, function()
				if particles.Parent then particles:Destroy() end
			end)
		end)

	elseif abilityId == "Glide" then
		isGliding = true
		AbilityController._StartGlideVisuals(hrp, cfg.Duration)

	elseif abilityId == "Teleport" then
		-- Flash effect at origin
		AbilityController._CreateTeleportFlash(hrp.Position)

		-- Brief screen effect
		AbilityController._ScreenFlash(Color3.fromRGB(180, 80, 255), 0.2)
	end
end

-- ============================================================================
-- SPECIFIC VISUAL HELPERS
-- ============================================================================
function AbilityController._CreateDashTrail(hrp, duration)
	-- Create short burst trail
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 1, 0)
	attachment0.Parent = hrp

	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, -1, 0)
	attachment1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.3
	trail.MinLength = 0
	trail.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(0, 100, 200))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.LightEmission = 1
	trail.Parent = hrp

	task.delay(duration + 0.3, function()
		if trail.Parent then trail:Destroy() end
		if attachment0.Parent then attachment0:Destroy() end
		if attachment1.Parent then attachment1:Destroy() end
	end)
end

function AbilityController._StartGlideVisuals(hrp, maxDuration)
	-- Create wing-like particle effect
	local leftWing = Instance.new("ParticleEmitter")
	leftWing.Name = "GlideWingLeft"
	leftWing.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	leftWing.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	leftWing.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	leftWing.Lifetime = NumberRange.new(0.3, 0.6)
	leftWing.Rate = 20
	leftWing.Speed = NumberRange.new(1, 3)
	leftWing.SpreadAngle = Vector2.new(30, 10)
	leftWing.Rotation = NumberRange.new(-10, 10)
	leftWing.LightEmission = 0.5
	leftWing.Parent = hrp

	glideWings = leftWing

	-- Auto-stop after max duration
	task.delay(maxDuration, function()
		isGliding = false
		AbilityController._StopGlideVisuals()
	end)
end

function AbilityController._StopGlideVisuals()
	if glideWings and glideWings.Parent then
		glideWings.Enabled = false
		task.delay(1, function()
			if glideWings and glideWings.Parent then glideWings:Destroy() end
			glideWings = nil
		end)
	end
end

function AbilityController._CreateTeleportFlash(position)
	-- Origin flash
	local part = Instance.new("Part")
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(180, 80, 255)
	part.Transparency = 0
	part.Shape = Enum.PartType.Ball
	part.Parent = workspace

	local tween = TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(6, 6, 6),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
	end)
end

function AbilityController._CameraShake(duration, intensity)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local startTime = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			return
		end

		local progress = elapsed / duration
		local dampedIntensity = intensity * (1 - progress)
		local offset = CFrame.new(
			(math.random() - 0.5) * dampedIntensity * 0.1,
			(math.random() - 0.5) * dampedIntensity * 0.1,
			0
		)
		camera.CFrame = camera.CFrame * offset
	end)
end

function AbilityController._ScreenFlash(color, duration)
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return end

	local screenGui = gui:FindFirstChild("SpeedrunUI")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "AbilityFlashGui"
		screenGui.Parent = gui
	end

	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.6
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = screenGui

	local tween = TweenService:Create(flash, TweenInfo.new(duration), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

-- ============================================================================
-- ABILITY SYNC
-- ============================================================================
function AbilityController._OnAbilitySync(data)
	equippedAbilities = {}

	if data.EquippedAbilities then
		for _, abilityId in ipairs(data.EquippedAbilities) do
			local cfg = GameConfig.AbilityById[abilityId]
			if cfg then
				equippedAbilities[abilityId] = cfg

				-- Initialize charges
				if cfg.MaxCharges then
					abilityCharges[abilityId] = cfg.MaxCharges
				end
			end
		end
	end

	-- Sync cooldowns from server
	if data.Cooldowns then
		for abilityId, remaining in pairs(data.Cooldowns) do
			abilityCooldowns[abilityId] = tick() + remaining
		end
	end

	print("[AbilityController] Synced", 0, "equipped abilities")
	local count = 0
	for _ in pairs(equippedAbilities) do count = count + 1 end
	print("[AbilityController] Synced", count, "equipped abilities")
end

function AbilityController._OnAbilityUnlocked(data)
	print("[AbilityController] Ability unlocked:", data.AbilityName)
end

-- ============================================================================
-- TICK (update cooldown displays, glide check)
-- ============================================================================
function AbilityController._Tick(dt)
	-- The cooldown display update is handled by SpeedrunUI through AbilitySync events.
	-- Here we just manage the glide direction update.
	if isGliding then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Landed then
				isGliding = false
				AbilityController._StopGlideVisuals()
			end
		end
	end
end

-- ============================================================================
-- WIN EFFECT PLAYBACK (client-side visual effects)
-- ============================================================================
remoteEvents:WaitForChild("PlayWinEffect").OnClientEvent:Connect(function(data)
	local effectId = data.EffectId
	local position = data.Position

	if effectId == "Confetti" then
		-- Colorful confetti particles
		local emitter = Instance.new("Part")
		emitter.Size = Vector3.new(1, 1, 1)
		emitter.Position = position + Vector3.new(0, 5, 0)
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.Transparency = 1
		emitter.Parent = workspace

		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
		})
		particles.Size = NumberSequence.new(0.3)
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Rate = 200
		particles.Speed = NumberRange.new(10, 20)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.RotSpeed = NumberRange.new(-200, 200)
		particles.Parent = emitter

		task.delay(0.5, function() particles.Enabled = false end)
		task.delay(3, function() emitter:Destroy() end)

	elseif effectId == "Fireworks" then
		for i = 1, 3 do
			task.delay(i * 0.3, function()
				local burst = Instance.new("Part")
				burst.Size = Vector3.new(1, 1, 1)
				burst.Position = position + Vector3.new(math.random(-5, 5), math.random(5, 15), math.random(-5, 5))
				burst.Anchored = true
				burst.CanCollide = false
				burst.Transparency = 1
				burst.Parent = workspace

				local particles = Instance.new("ParticleEmitter")
				particles.Color = ColorSequence.new(
					Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
				)
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.5),
					NumberSequenceKeypoint.new(1, 0),
				})
				particles.Lifetime = NumberRange.new(0.5, 1)
				particles.Rate = 500
				particles.Speed = NumberRange.new(15, 25)
				particles.SpreadAngle = Vector2.new(360, 360)
				particles.LightEmission = 1
				particles.Parent = burst

				task.delay(0.15, function() particles.Enabled = false end)
				task.delay(2, function() burst:Destroy() end)
			end)
		end

	elseif effectId == "Lightning" then
		-- Flash + neon bolt
		local bolt = Instance.new("Part")
		bolt.Size = Vector3.new(0.3, 20, 0.3)
		bolt.Position = position + Vector3.new(0, 10, 0)
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(150, 200, 255)
		bolt.Parent = workspace

		local flash = Instance.new("PointLight")
		flash.Color = Color3.fromRGB(150, 200, 255)
		flash.Brightness = 10
		flash.Range = 50
		flash.Parent = bolt

		task.delay(0.15, function()
			bolt.Transparency = 0.5
			flash.Brightness = 3
		end)
		task.delay(0.3, function()
			bolt:Destroy()
		end)

	elseif effectId == "Shockwave" then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.5, 2, 2)
		ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(0, 200, 255)
		ring.Parent = workspace

		local tween = TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.5, 40, 40),
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			ring:Destroy()
		end)

	elseif effectId == "StarBurst" then
		for i = 1, 8 do
			local angle = (i / 8) * math.pi * 2
			local star = Instance.new("Part")
			star.Size = Vector3.new(0.5, 0.5, 0.5)
			star.Position = position
			star.Anchored = true
			star.CanCollide = false
			star.Material = Enum.Material.Neon
			star.Color = Color3.fromRGB(255, 255, 100)
			star.Shape = Enum.PartType.Ball
			star.Parent = workspace

			local targetPos = position + Vector3.new(math.cos(angle) * 15, 5, math.sin(angle) * 15)
			local tween = TweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = targetPos,
				Size = Vector3.new(0.1, 0.1, 0.1),
				Transparency = 1,
			})
			tween:Play()
			tween.Completed:Connect(function()
				star:Destroy()
			end)
		end

	elseif effectId == "VoidCollapse" then
		local sphere = Instance.new("Part")
		sphere.Size = Vector3.new(20, 20, 20)
		sphere.Position = position
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.Material = Enum.Material.ForceField
		sphere.Color = Color3.fromRGB(20, 0, 40)
		sphere.Transparency = 0.5
		sphere.Shape = Enum.PartType.Ball
		sphere.Parent = workspace

		local tween = TweenService:Create(sphere, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = Vector3.new(0.5, 0.5, 0.5),
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			sphere:Destroy()
		end)
	end
end)

-- ============================================================================
-- BOOTSTRAP
-- ============================================================================
AbilityController.Init()

return AbilityController
