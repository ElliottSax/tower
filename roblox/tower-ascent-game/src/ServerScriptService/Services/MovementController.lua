--[[
	MovementController.lua
	Advanced movement system with combos, momentum, and skill progression

	Features:
	- Movement combo system
	- Momentum-based physics
	- Skill chaining
	- Movement mastery levels
	- Parkour techniques
	- Grappling hook mechanics
	- Slide and roll mechanics
	- Wall running
	- Advanced air control

	Created: 2025-12-03
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MovementController = {}
MovementController.Enabled = true

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Base movement
	BaseWalkSpeed = 16,
	BaseJumpPower = 50,
	SprintMultiplier = 1.5,

	-- Momentum system
	MaxMomentum = 3.0,
	MomentumBuildRate = 0.1,
	MomentumDecayRate = 0.05,
	MomentumSpeedBonus = 0.5, -- Per momentum point

	-- Combo system
	ComboWindow = 1.5, -- Seconds to chain moves
	ComboMultiplier = 1.2, -- Speed/power bonus per combo
	MaxComboChain = 10,

	-- Advanced moves
	WallRunDuration = 3,
	WallRunSpeed = 20,
	GrappleRange = 100,
	GrappleSpeed = 50,
	SlideSpeedBoost = 1.8,
	SlideDuration = 2,
	RollDamageReduction = 0.5,

	-- Stamina
	MaxStamina = 100,
	StaminaRegenRate = 10, -- Per second
	MoveStaminaCosts = {
		DoubleJump = 15,
		AirDash = 20,
		WallRun = 5, -- Per second
		Grapple = 25,
		Slide = 10,
		Roll = 5
	},

	-- Mastery
	ExpPerMove = {
		Jump = 1,
		DoubleJump = 3,
		WallJump = 5,
		AirDash = 5,
		WallRun = 10,
		Grapple = 15,
		PerfectLanding = 20,
		ComboChain = 25
	}
}

-- Movement techniques
local TECHNIQUES = {
	WALL_JUMP = {
		Name = "Wall Jump",
		Description = "Jump off walls to gain height",
		UnlockLevel = 1,
		Cooldown = 0.5
	},
	WALL_RUN = {
		Name = "Wall Run",
		Description = "Run along walls horizontally",
		UnlockLevel = 5,
		Cooldown = 2
	},
	LONG_JUMP = {
		Name = "Long Jump",
		Description = "Jump further with momentum",
		UnlockLevel = 3,
		Cooldown = 1
	},
	GROUND_POUND = {
		Name = "Ground Pound",
		Description = "Slam down from the air",
		UnlockLevel = 7,
		Cooldown = 3
	},
	LEDGE_GRAB = {
		Name = "Ledge Grab",
		Description = "Grab and climb ledges",
		UnlockLevel = 2,
		Cooldown = 0
	},
	GRAPPLE_HOOK = {
		Name = "Grapple Hook",
		Description = "Swing from anchor points",
		UnlockLevel = 10,
		Cooldown = 5
	},
	SLIDE = {
		Name = "Slide",
		Description = "Slide under obstacles",
		UnlockLevel = 4,
		Cooldown = 2
	},
	ROLL = {
		Name = "Combat Roll",
		Description = "Roll to avoid damage",
		UnlockLevel = 6,
		Cooldown = 1
	},
	VAULT = {
		Name = "Vault",
		Description = "Quickly vault over obstacles",
		UnlockLevel = 8,
		Cooldown = 0.5
	},
	WING_SUIT = {
		Name = "Wing Suit",
		Description = "Glide through the air",
		UnlockLevel = 15,
		Cooldown = 10
	}
}

-- Combo chains
local COMBOS = {
	SPEED_BURST = {
		Sequence = {"Sprint", "Jump", "AirDash"},
		Reward = {SpeedBoost = 2, Duration = 3},
		Points = 50
	},
	AERIAL_MASTER = {
		Sequence = {"Jump", "DoubleJump", "AirDash", "GroundPound"},
		Reward = {JumpBoost = 1.5, Duration = 5},
		Points = 100
	},
	WALL_MASTER = {
		Sequence = {"WallRun", "WallJump", "WallRun", "WallJump"},
		Reward = {WallRunDuration = 2, StaminaRefund = 50},
		Points = 150
	},
	MOMENTUM_CHAIN = {
		Sequence = {"Sprint", "Slide", "Jump", "AirDash", "Roll"},
		Reward = {MomentumBoost = 2, SpeedBoost = 3},
		Points = 200
	},
	PERFECT_FLOW = {
		Sequence = {"WallRun", "Grapple", "AirDash", "Roll", "Slide"},
		Reward = {StaminaInfinite = 5, SpeedBoost = 4},
		Points = 500
	}
}

-- ============================================================================
-- PLAYER MOVEMENT DATA
-- ============================================================================

local PlayerMovement = {}
PlayerMovement.__index = PlayerMovement

function PlayerMovement.new(player: Player)
	local self = setmetatable({}, PlayerMovement)

	self.Player = player
	self.Character = player.Character
	self.Humanoid = self.Character and self.Character:FindFirstChild("Humanoid")
	self.RootPart = self.Character and self.Character:FindFirstChild("HumanoidRootPart")

	-- Movement state
	self.Momentum = 0
	self.Stamina = CONFIG.MaxStamina
	self.ComboChain = {}
	self.ComboTimer = 0
	self.LastMoveTime = 0

	-- Abilities
	self.UnlockedTechniques = {}
	self.TechniqueCooldowns = {}
	self.MasteryLevel = 1
	self.MasteryExp = 0

	-- Movement flags
	self.IsWallRunning = false
	self.IsSliding = false
	self.IsGrappling = false
	self.IsGrounded = true
	self.InAir = false
	self.AirJumpsRemaining = 1

	-- Physics
	self.Velocity = Vector3.new()
	self.LastPosition = nil
	self.GroundNormal = Vector3.new(0, 1, 0)

	-- Effects
	self.ActiveEffects = {}
	self.TrailEffect = nil

	return self
end

function PlayerMovement:Initialize()
	if not self.Character or not self.Humanoid then
		return
	end

	-- Set base stats
	self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed
	self.Humanoid.JumpPower = CONFIG.BaseJumpPower

	-- Unlock basic techniques
	self:UnlockTechnique("WALL_JUMP")
	self:UnlockTechnique("LEDGE_GRAB")

	-- Connect events
	self:ConnectEvents()

	-- Start update loop
	self:StartUpdateLoop()
end

function PlayerMovement:ConnectEvents()
	-- Jump detection
	self.Humanoid.Jumping:Connect(function()
		self:OnJump()
	end)

	-- Landing detection
	self.Humanoid.FreeFalling:Connect(function(active)
		if not active and self.InAir then
			self:OnLanded()
		elseif active then
			self.InAir = true
			self.IsGrounded = false
		end
	end)

	-- State changes
	self.Humanoid.StateChanged:Connect(function(old, new)
		self:OnStateChanged(old, new)
	end)
end

-- ============================================================================
-- MOVEMENT TECHNIQUES
-- ============================================================================

function PlayerMovement:PerformTechnique(techniqueName: string): boolean
	local technique = TECHNIQUES[techniqueName]
	if not technique then
		return false
	end

	-- Check if unlocked
	if not self:IsTechniqueUnlocked(techniqueName) then
		return false
	end

	-- Check cooldown
	if self:IsOnCooldown(techniqueName) then
		return false
	end

	-- Check stamina
	local staminaCost = CONFIG.MoveStaminaCosts[techniqueName] or 10
	if self.Stamina < staminaCost then
		return false
	end

	-- Perform the technique
	local success = false

	if techniqueName == "WALL_RUN" then
		success = self:StartWallRun()
	elseif techniqueName == "WALL_JUMP" then
		success = self:PerformWallJump()
	elseif techniqueName == "LONG_JUMP" then
		success = self:PerformLongJump()
	elseif techniqueName == "GROUND_POUND" then
		success = self:PerformGroundPound()
	elseif techniqueName == "LEDGE_GRAB" then
		success = self:AttemptLedgeGrab()
	elseif techniqueName == "GRAPPLE_HOOK" then
		success = self:FireGrappleHook()
	elseif techniqueName == "SLIDE" then
		success = self:StartSlide()
	elseif techniqueName == "ROLL" then
		success = self:PerformRoll()
	elseif techniqueName == "VAULT" then
		success = self:PerformVault()
	elseif techniqueName == "WING_SUIT" then
		success = self:ActivateWingSuit()
	end

	if success then
		-- Consume stamina
		self:ConsumeStamina(staminaCost)

		-- Set cooldown
		self:SetCooldown(techniqueName, technique.Cooldown)

		-- Add to combo chain
		self:AddToCombo(techniqueName)

		-- Grant experience
		self:GainMasteryExp(CONFIG.ExpPerMove[techniqueName] or 5)

		-- Build momentum
		self:BuildMomentum(0.2)
	end

	return success
end

function PlayerMovement:StartWallRun()
	if self.IsWallRunning then
		return false
	end

	-- Find nearby wall
	local wall = self:FindNearbyWall()
	if not wall then
		return false
	end

	self.IsWallRunning = true
	self.WallRunTime = CONFIG.WallRunDuration
	self.WallRunSurface = wall

	-- Apply wall run physics
	local wallNormal = self:GetWallNormal(wall)
	local runDirection = wallNormal:Cross(Vector3.new(0, 1, 0))

	-- Align character to wall
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 0, 4000)
	bodyPosition.Position = self.RootPart.Position
	bodyPosition.Parent = self.RootPart

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = runDirection * CONFIG.WallRunSpeed
	bodyVelocity.Parent = self.RootPart

	-- Store for cleanup
	self.WallRunConstraints = {bodyPosition, bodyVelocity}

	-- Visual effects
	self:CreateWallRunEffect()

	return true
end

function PlayerMovement:PerformWallJump()
	if not self.IsWallRunning and not self:IsNearWall() then
		return false
	end

	local wall = self.WallRunSurface or self:FindNearbyWall()
	if not wall then
		return false
	end

	-- Calculate jump direction
	local wallNormal = self:GetWallNormal(wall)
	local jumpDirection = (wallNormal + Vector3.new(0, 1, 0)).Unit

	-- Apply jump impulse
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
	bodyVelocity.Velocity = jumpDirection * (CONFIG.BaseJumpPower * 1.5)
	bodyVelocity.Parent = self.RootPart

	Debris:AddItem(bodyVelocity, 0.2)

	-- End wall run if active
	if self.IsWallRunning then
		self:EndWallRun()
	end

	-- Reset air jumps
	self.AirJumpsRemaining = 1

	-- Effects
	self:CreateJumpEffect()

	return true
end

function PlayerMovement:PerformLongJump()
	if not self.IsGrounded then
		return false
	end

	-- Requires momentum
	if self.Momentum < 1 then
		return false
	end

	-- Calculate jump power based on momentum
	local jumpPower = CONFIG.BaseJumpPower * (1 + self.Momentum * 0.3)
	local jumpDirection = self.RootPart.CFrame.LookVector + Vector3.new(0, 0.5, 0)

	-- Apply jump
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
	bodyVelocity.Velocity = jumpDirection.Unit * jumpPower
	bodyVelocity.Parent = self.RootPart

	Debris:AddItem(bodyVelocity, 0.3)

	-- Effects
	self:CreateLongJumpEffect()

	return true
end

function PlayerMovement:PerformGroundPound()
	if self.IsGrounded or self.IsGroundPounding then
		return false
	end

	self.IsGroundPounding = true

	-- Stop all upward momentum
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, 10000, 0)
	bodyVelocity.Velocity = Vector3.new(0, -100, 0)
	bodyVelocity.Parent = self.RootPart

	self.GroundPoundVelocity = bodyVelocity

	-- Create impact detection
	task.spawn(function()
		while self.IsGroundPounding do
			if self.IsGrounded then
				self:GroundPoundImpact()
				break
			end
			task.wait()
		end
	end)

	-- Visual effect
	self:CreateGroundPoundEffect()

	return true
end

function PlayerMovement:GroundPoundImpact()
	if not self.IsGroundPounding then
		return
	end

	self.IsGroundPounding = false

	-- Clean up velocity
	if self.GroundPoundVelocity then
		self.GroundPoundVelocity:Destroy()
		self.GroundPoundVelocity = nil
	end

	-- Create shockwave
	local shockwave = Instance.new("Part")
	shockwave.Name = "Shockwave"
	shockwave.Size = Vector3.new(1, 0.5, 1)
	shockwave.Material = Enum.Material.ForceField
	shockwave.BrickColor = BrickColor.new("Electric blue")
	shockwave.Transparency = 0.5
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.CFrame = CFrame.new(self.RootPart.Position - Vector3.new(0, 3, 0))
	shockwave.Parent = workspace

	-- Expand shockwave
	local tween = TweenService:Create(shockwave,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(30, 0.5, 30), Transparency = 1}
	)
	tween:Play()

	Debris:AddItem(shockwave, 0.6)

	-- Damage/knockback nearby players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self.Player and player.Character then
			local distance = (player.Character.PrimaryPart.Position - self.RootPart.Position).Magnitude
			if distance < 15 then
				local knockback = (player.Character.PrimaryPart.Position - self.RootPart.Position).Unit * 50
				knockback = knockback + Vector3.new(0, 30, 0)

				local bodyVel = Instance.new("BodyVelocity")
				bodyVel.MaxForce = Vector3.new(10000, 10000, 10000)
				bodyVel.Velocity = knockback
				bodyVel.Parent = player.Character.PrimaryPart

				Debris:AddItem(bodyVel, 0.2)
			end
		end
	end

	-- Grant combo points
	self:AddToCombo("GroundPound")
	self:BuildMomentum(0.5)
end

function PlayerMovement:FireGrappleHook()
	if self.IsGrappling then
		return false
	end

	-- Find grapple point
	local grapplePoint = self:FindGrapplePoint()
	if not grapplePoint then
		return false
	end

	self.IsGrappling = true
	self.GrapplePoint = grapplePoint

	-- Create rope visual
	local rope = Instance.new("RopeConstraint")
	rope.Visible = true
	rope.Color = BrickColor.new("Dark grey")
	rope.Thickness = 0.2
	rope.Parent = self.RootPart

	local attachment1 = Instance.new("Attachment", self.RootPart)
	local attachment2 = Instance.new("Attachment", grapplePoint)

	rope.Attachment0 = attachment1
	rope.Attachment1 = attachment2
	rope.Length = (grapplePoint.Position - self.RootPart.Position).Magnitude

	-- Create swing physics
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.Position = grapplePoint.Position
	bodyPosition.Parent = self.RootPart

	self.GrappleConstraints = {rope, attachment1, attachment2, bodyPosition}

	-- Auto-release after time
	task.wait(3)
	self:ReleaseGrapple()

	return true
end

function PlayerMovement:ReleaseGrapple()
	if not self.IsGrappling then
		return
	end

	self.IsGrappling = false

	-- Clean up constraints
	if self.GrappleConstraints then
		for _, obj in ipairs(self.GrappleConstraints) do
			obj:Destroy()
		end
		self.GrappleConstraints = nil
	end

	-- Maintain momentum
	self:BuildMomentum(0.3)
end

function PlayerMovement:StartSlide()
	if self.IsSliding or not self.IsGrounded then
		return false
	end

	self.IsSliding = true
	self.SlideTime = CONFIG.SlideDuration

	-- Lower character height
	self.Humanoid.HipHeight = -1

	-- Boost speed
	self.SlideSpeedBoost = CONFIG.SlideSpeedBoost
	self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed * self.SlideSpeedBoost

	-- Add slide physics
	local slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	slideVelocity.Velocity = self.RootPart.CFrame.LookVector * (CONFIG.BaseWalkSpeed * CONFIG.SlideSpeedBoost)
	slideVelocity.Parent = self.RootPart

	self.SlideVelocity = slideVelocity

	-- Visual effect
	self:CreateSlideEffect()

	-- End slide after duration
	task.wait(CONFIG.SlideDuration)
	self:EndSlide()

	return true
end

function PlayerMovement:EndSlide()
	if not self.IsSliding then
		return
	end

	self.IsSliding = false

	-- Reset height
	self.Humanoid.HipHeight = 0

	-- Reset speed
	self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed * (1 + self.Momentum * CONFIG.MomentumSpeedBonus)

	-- Clean up velocity
	if self.SlideVelocity then
		self.SlideVelocity:Destroy()
		self.SlideVelocity = nil
	end
end

function PlayerMovement:PerformRoll()
	if self.IsRolling then
		return false
	end

	self.IsRolling = true
	self.RollInvulnerable = true

	-- Roll animation (rotate character)
	local rollTween = TweenService:Create(self.RootPart,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{CFrame = self.RootPart.CFrame * CFrame.Angles(math.rad(360), 0, 0)}
	)
	rollTween:Play()

	-- Move forward
	local rollVelocity = Instance.new("BodyVelocity")
	rollVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	rollVelocity.Velocity = self.RootPart.CFrame.LookVector * 30
	rollVelocity.Parent = self.RootPart

	Debris:AddItem(rollVelocity, 0.5)

	-- Invulnerability frames
	task.wait(0.5)
	self.IsRolling = false
	self.RollInvulnerable = false

	return true
end

-- ============================================================================
-- MOMENTUM SYSTEM
-- ============================================================================

function PlayerMovement:UpdateMomentum(deltaTime: number)
	-- Build momentum while moving fast
	local speed = self.Humanoid.MoveVelocity.Magnitude
	if speed > CONFIG.BaseWalkSpeed then
		self:BuildMomentum(CONFIG.MomentumBuildRate * deltaTime)
	else
		-- Decay momentum when slow/stopped
		self.Momentum = math.max(0, self.Momentum - CONFIG.MomentumDecayRate * deltaTime)
	end

	-- Apply momentum to speed
	local speedMultiplier = 1 + (self.Momentum * CONFIG.MomentumSpeedBonus)
	if not self.IsSliding then
		self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed * speedMultiplier
	end

	-- Visual feedback for high momentum
	if self.Momentum >= 2 then
		if not self.TrailEffect then
			self:CreateMomentumTrail()
		end
	elseif self.TrailEffect then
		self.TrailEffect:Destroy()
		self.TrailEffect = nil
	end
end

function PlayerMovement:BuildMomentum(amount: number)
	self.Momentum = math.min(CONFIG.MaxMomentum, self.Momentum + amount)

	-- Momentum milestone effects
	if self.Momentum == CONFIG.MaxMomentum then
		self:OnMaxMomentum()
	end
end

function PlayerMovement:OnMaxMomentum()
	-- Grant temporary abilities
	self.MaxMomentumBonus = {
		SpeedBoost = 2,
		JumpBoost = 1.5,
		StaminaRegenBoost = 2,
		Duration = 5
	}

	-- Visual effect
	self:CreateMaxMomentumEffect()

	-- Award points
	self:GainMasteryExp(100)
end

-- ============================================================================
-- COMBO SYSTEM
-- ============================================================================

function PlayerMovement:AddToCombo(move: string)
	local now = tick()

	-- Check if combo window expired
	if now - self.LastMoveTime > CONFIG.ComboWindow then
		self.ComboChain = {}
	end

	-- Add move to chain
	table.insert(self.ComboChain, move)
	self.LastMoveTime = now

	-- Check for combo completion
	self:CheckCombos()

	-- Apply combo multiplier
	local comboLength = #self.ComboChain
	if comboLength > 1 then
		local multiplier = math.min(CONFIG.MaxComboChain, comboLength) * CONFIG.ComboMultiplier
		self.ComboMultiplier = multiplier

		-- Visual feedback
		self:ShowComboCounter(comboLength)
	end
end

function PlayerMovement:CheckCombos()
	for comboName, combo in pairs(COMBOS) do
		if self:MatchesCombo(combo.Sequence) then
			self:ActivateCombo(comboName, combo)
			self.ComboChain = {} -- Reset after successful combo
			break
		end
	end
end

function PlayerMovement:MatchesCombo(sequence: {}): boolean
	if #self.ComboChain < #sequence then
		return false
	end

	-- Check if recent moves match sequence
	local startIndex = #self.ComboChain - #sequence + 1
	for i, move in ipairs(sequence) do
		if self.ComboChain[startIndex + i - 1] ~= move then
			return false
		end
	end

	return true
end

function PlayerMovement:ActivateCombo(name: string, combo: {})
	print(string.format("COMBO! %s (+%d points)", name, combo.Points))

	-- Apply rewards
	local reward = combo.Reward
	if reward.SpeedBoost then
		self.Humanoid.WalkSpeed = self.Humanoid.WalkSpeed * reward.SpeedBoost
		task.wait(reward.Duration or 3)
		self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed * (1 + self.Momentum * CONFIG.MomentumSpeedBonus)
	end

	if reward.JumpBoost then
		self.Humanoid.JumpPower = self.Humanoid.JumpPower * reward.JumpBoost
		task.wait(reward.Duration or 3)
		self.Humanoid.JumpPower = CONFIG.BaseJumpPower
	end

	if reward.StaminaRefund then
		self.Stamina = math.min(CONFIG.MaxStamina, self.Stamina + reward.StaminaRefund)
	end

	if reward.StaminaInfinite then
		self.InfiniteStamina = true
		task.wait(reward.StaminaInfinite)
		self.InfiniteStamina = false
	end

	if reward.MomentumBoost then
		self:BuildMomentum(reward.MomentumBoost)
	end

	-- Grant experience
	self:GainMasteryExp(combo.Points)

	-- Visual effect
	self:CreateComboEffect(name)
end

-- ============================================================================
-- STAMINA SYSTEM
-- ============================================================================

function PlayerMovement:UpdateStamina(deltaTime: number)
	if self.InfiniteStamina then
		self.Stamina = CONFIG.MaxStamina
		return
	end

	-- Regenerate stamina
	if not self.IsWallRunning and not self.IsGrappling then
		self.Stamina = math.min(CONFIG.MaxStamina, self.Stamina + CONFIG.StaminaRegenRate * deltaTime)
	end

	-- Drain stamina for continuous abilities
	if self.IsWallRunning then
		self:ConsumeStamina(CONFIG.MoveStaminaCosts.WallRun * deltaTime)
	end

	-- Check stamina depletion
	if self.Stamina <= 0 then
		self:OnStaminaDepleted()
	end
end

function PlayerMovement:ConsumeStamina(amount: number)
	if self.InfiniteStamina then
		return
	end

	self.Stamina = math.max(0, self.Stamina - amount)
end

function PlayerMovement:OnStaminaDepleted()
	-- Cancel active abilities
	if self.IsWallRunning then
		self:EndWallRun()
	end

	if self.IsGrappling then
		self:ReleaseGrapple()
	end

	-- Apply exhaustion
	self.Exhausted = true
	self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed * 0.5
	self.Humanoid.JumpPower = CONFIG.BaseJumpPower * 0.5

	-- Recover after delay
	task.wait(2)
	self.Exhausted = false
	self.Humanoid.WalkSpeed = CONFIG.BaseWalkSpeed
	self.Humanoid.JumpPower = CONFIG.BaseJumpPower
end

-- ============================================================================
-- MASTERY SYSTEM
-- ============================================================================

function PlayerMovement:GainMasteryExp(amount: number)
	self.MasteryExp = self.MasteryExp + amount

	-- Check for level up
	local requiredExp = self.MasteryLevel * 100
	if self.MasteryExp >= requiredExp then
		self:LevelUpMastery()
	end
end

function PlayerMovement:LevelUpMastery()
	self.MasteryLevel = self.MasteryLevel + 1
	self.MasteryExp = 0

	print(string.format("Movement Mastery Level %d!", self.MasteryLevel))

	-- Check for new technique unlocks
	for techniqueName, technique in pairs(TECHNIQUES) do
		if technique.UnlockLevel == self.MasteryLevel then
			self:UnlockTechnique(techniqueName)
			print(string.format("Unlocked: %s", technique.Name))
		end
	end

	-- Stat bonuses
	if self.MasteryLevel % 5 == 0 then
		CONFIG.MaxStamina = CONFIG.MaxStamina + 10
		CONFIG.StaminaRegenRate = CONFIG.StaminaRegenRate + 1
	end

	-- Visual effect
	self:CreateLevelUpEffect()
end

function PlayerMovement:UnlockTechnique(techniqueName: string)
	self.UnlockedTechniques[techniqueName] = true
end

function PlayerMovement:IsTechniqueUnlocked(techniqueName: string): boolean
	return self.UnlockedTechniques[techniqueName] == true
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function PlayerMovement:FindNearbyWall(): BasePart?
	local maxDistance = 5
	local rayDirections = {
		self.RootPart.CFrame.RightVector,
		-self.RootPart.CFrame.RightVector,
		self.RootPart.CFrame.LookVector,
		-self.RootPart.CFrame.LookVector
	}

	for _, direction in ipairs(rayDirections) do
		local ray = workspace:Raycast(self.RootPart.Position, direction * maxDistance)
		if ray and ray.Instance then
			return ray.Instance
		end
	end

	return nil
end

function PlayerMovement:IsNearWall(): boolean
	return self:FindNearbyWall() ~= nil
end

function PlayerMovement:GetWallNormal(wall: BasePart): Vector3
	local ray = workspace:Raycast(self.RootPart.Position,
		(wall.Position - self.RootPart.Position).Unit * 10)
	if ray then
		return ray.Normal
	end
	return (self.RootPart.Position - wall.Position).Unit
end

function PlayerMovement:FindGrapplePoint(): BasePart?
	-- Look for grapple anchors in range
	local maxRange = CONFIG.GrappleRange
	local anchors = workspace:GetDescendants()

	for _, obj in ipairs(anchors) do
		if obj:IsA("BasePart") and obj.Name == "GrapplePoint" then
			local distance = (obj.Position - self.RootPart.Position).Magnitude
			if distance <= maxRange then
				-- Check line of sight
				local ray = workspace:Raycast(self.RootPart.Position,
					(obj.Position - self.RootPart.Position).Unit * distance)
				if not ray or ray.Instance == obj then
					return obj
				end
			end
		end
	end

	return nil
end

function PlayerMovement:SetCooldown(techniqueName: string, duration: number)
	self.TechniqueCooldowns[techniqueName] = tick() + duration
end

function PlayerMovement:IsOnCooldown(techniqueName: string): boolean
	local cooldownEnd = self.TechniqueCooldowns[techniqueName]
	if not cooldownEnd then
		return false
	end
	return tick() < cooldownEnd
end

function PlayerMovement:EndWallRun()
	if not self.IsWallRunning then
		return
	end

	self.IsWallRunning = false

	-- Clean up constraints
	if self.WallRunConstraints then
		for _, constraint in ipairs(self.WallRunConstraints) do
			constraint:Destroy()
		end
		self.WallRunConstraints = nil
	end
end

function PlayerMovement:OnJump()
	-- Add to combo
	self:AddToCombo("Jump")

	-- Grant exp
	self:GainMasteryExp(CONFIG.ExpPerMove.Jump)

	-- Build momentum
	self:BuildMomentum(0.1)
end

function PlayerMovement:OnLanded()
	self.InAir = false
	self.IsGrounded = true
	self.AirJumpsRemaining = 1

	-- Check for perfect landing
	if self.Momentum >= 2 then
		self:GainMasteryExp(CONFIG.ExpPerMove.PerfectLanding)
		self:CreatePerfectLandingEffect()
	end

	-- End ground pound if active
	if self.IsGroundPounding then
		self:GroundPoundImpact()
	end
end

function PlayerMovement:OnStateChanged(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	-- Handle state-specific logic
	if new == Enum.HumanoidStateType.Freefall then
		self.InAir = true
		self.IsGrounded = false
	elseif new == Enum.HumanoidStateType.Landed then
		self:OnLanded()
	end
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function PlayerMovement:StartUpdateLoop()
	self.UpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:Update(deltaTime)
	end)
end

function PlayerMovement:Update(deltaTime: number)
	-- Update systems
	self:UpdateMomentum(deltaTime)
	self:UpdateStamina(deltaTime)

	-- Update wall run
	if self.IsWallRunning then
		self.WallRunTime = self.WallRunTime - deltaTime
		if self.WallRunTime <= 0 then
			self:EndWallRun()
		end
	end

	-- Update physics
	if self.LastPosition then
		self.Velocity = (self.RootPart.Position - self.LastPosition) / deltaTime
	end
	self.LastPosition = self.RootPart.Position
end

function PlayerMovement:Destroy()
	if self.UpdateConnection then
		self.UpdateConnection:Disconnect()
		self.UpdateConnection = nil
	end

	-- Clean up any active effects
	if self.TrailEffect then
		self.TrailEffect:Destroy()
		self.TrailEffect = nil
	end

	-- Clean up constraints
	if self.WallRunConstraints then
		for _, constraint in ipairs(self.WallRunConstraints) do
			constraint:Destroy()
		end
	end

	if self.GrappleConstraints then
		for _, constraint in ipairs(self.GrappleConstraints) do
			constraint:Destroy()
		end
	end

	if self.SlideVelocity then
		self.SlideVelocity:Destroy()
	end

	if self.GroundPoundVelocity then
		self.GroundPoundVelocity:Destroy()
	end
end

-- ============================================================================
-- VISUAL EFFECTS
-- ============================================================================

function PlayerMovement:CreateMomentumTrail()
	local trail = Instance.new("Trail")
	trail.Lifetime = 0.5
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 162, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})

	local attachment0 = Instance.new("Attachment", self.RootPart)
	attachment0.Position = Vector3.new(0, -2, 0)
	local attachment1 = Instance.new("Attachment", self.RootPart)
	attachment1.Position = Vector3.new(0, 2, 0)

	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Parent = self.RootPart

	self.TrailEffect = trail
end

function PlayerMovement:CreateWallRunEffect()
	-- Particles for wall contact
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 50
	emitter.Lifetime = NumberRange.new(0.5)
	emitter.VelocityInheritance = 0.5
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.Speed = NumberRange.new(5)
	emitter.SpreadAngle = Vector2.new(10, 10)
	emitter.Parent = self.RootPart

	Debris:AddItem(emitter, CONFIG.WallRunDuration)
end

function PlayerMovement:CreateJumpEffect()
	-- Jump ring effect
	local ring = Instance.new("Part")
	ring.Name = "JumpRing"
	ring.Size = Vector3.new(4, 0.2, 4)
	ring.Material = Enum.Material.Neon
	ring.BrickColor = BrickColor.new("Cyan")
	ring.Transparency = 0.5
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(self.RootPart.Position - Vector3.new(0, 3, 0))
	ring.Parent = workspace

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = ring

	local tween = TweenService:Create(ring,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(8, 0.2, 8), Transparency = 1}
	)
	tween:Play()

	Debris:AddItem(ring, 0.4)
end

function PlayerMovement:CreateLongJumpEffect()
	-- Speed lines
	local lines = Instance.new("Part")
	lines.Name = "SpeedLines"
	lines.Size = Vector3.new(10, 10, 20)
	lines.Material = Enum.Material.ForceField
	lines.BrickColor = BrickColor.new("White")
	lines.Transparency = 0.7
	lines.Anchored = true
	lines.CanCollide = false
	lines.CFrame = self.RootPart.CFrame
	lines.Parent = workspace

	Debris:AddItem(lines, 0.5)
end

function PlayerMovement:CreateGroundPoundEffect()
	-- Falling aura
	local aura = Instance.new("SelectionSphere")
	aura.Transparency = 0.5
	aura.Color3 = Color3.fromRGB(255, 100, 0)
	aura.SurfaceTransparency = 0.5
	aura.Adornee = self.RootPart
	aura.Parent = self.RootPart

	self.GroundPoundAura = aura
end

function PlayerMovement:CreateSlideEffect()
	-- Dust trail
	local dust = Instance.new("ParticleEmitter")
	dust.Rate = 100
	dust.Lifetime = NumberRange.new(1)
	dust.VelocityInheritance = 0
	dust.EmissionDirection = Enum.NormalId.Bottom
	dust.Speed = NumberRange.new(5)
	dust.SpreadAngle = Vector2.new(45, 45)
	dust.Color = ColorSequence.new(Color3.fromRGB(139, 90, 43))
	dust.Parent = self.RootPart

	Debris:AddItem(dust, CONFIG.SlideDuration)
end

function PlayerMovement:CreatePerfectLandingEffect()
	-- Landing shockwave
	local wave = Instance.new("Part")
	wave.Name = "LandingWave"
	wave.Size = Vector3.new(2, 0.2, 2)
	wave.Material = Enum.Material.Neon
	wave.BrickColor = BrickColor.new("Lime green")
	wave.Transparency = 0.3
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(self.RootPart.Position - Vector3.new(0, 3, 0))
	wave.Parent = workspace

	local tween = TweenService:Create(wave,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(10, 0.2, 10), Transparency = 1}
	)
	tween:Play()

	Debris:AddItem(wave, 0.4)
end

function PlayerMovement:CreateMaxMomentumEffect()
	-- Full body aura
	local aura = Instance.new("PointLight")
	aura.Brightness = 2
	aura.Color = Color3.fromRGB(0, 162, 255)
	aura.Range = 10
	aura.Parent = self.RootPart

	Debris:AddItem(aura, 5)
end

function PlayerMovement:CreateComboEffect(comboName: string)
	-- Combo text popup
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Parent = self.RootPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = comboName .. "!"
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.Parent = billboard

	-- Animate popup
	local tween = TweenService:Create(billboard,
		TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{StudsOffset = Vector3.new(0, 10, 0)}
	)
	tween:Play()

	Debris:AddItem(billboard, 1.5)
end

function PlayerMovement:CreateLevelUpEffect()
	-- Level up burst
	local burst = Instance.new("Part")
	burst.Name = "LevelUpBurst"
	burst.Size = Vector3.new(1, 1, 1)
	burst.Material = Enum.Material.Neon
	burst.BrickColor = BrickColor.new("Gold")
	burst.Transparency = 0
	burst.Anchored = true
	burst.CanCollide = false
	burst.Shape = Enum.PartType.Ball
	burst.CFrame = self.RootPart.CFrame
	burst.Parent = workspace

	local tween = TweenService:Create(burst,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(20, 20, 20), Transparency = 1}
	)
	tween:Play()

	Debris:AddItem(burst, 1.1)
end

function PlayerMovement:ShowComboCounter(count: number)
	-- Update or create combo counter UI
	-- This would interface with the player's GUI
	print(string.format("Combo x%d!", count))
end

-- ============================================================================
-- MODULE MANAGEMENT
-- ============================================================================

local playerMovementData = {}

local function onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Clean up old data
	if playerMovementData[player] then
		playerMovementData[player]:Destroy()
	end

	-- Create new movement controller
	local movement = PlayerMovement.new(player)
	movement:Initialize()
	playerMovementData[player] = movement
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	if playerMovementData[player] then
		playerMovementData[player]:Destroy()
		playerMovementData[player] = nil
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function MovementController.GetPlayerMovement(player: Player): PlayerMovement?
	return playerMovementData[player]
end

function MovementController.PerformTechnique(player: Player, techniqueName: string): boolean
	local movement = playerMovementData[player]
	if not movement then
		return false
	end

	return movement:PerformTechnique(techniqueName)
end

function MovementController.GetMasteryLevel(player: Player): number
	local movement = playerMovementData[player]
	if not movement then
		return 0
	end

	return movement.MasteryLevel
end

function MovementController.GetMomentum(player: Player): number
	local movement = playerMovementData[player]
	if not movement then
		return 0
	end

	return movement.Momentum
end

function MovementController.GetStamina(player: Player): number
	local movement = playerMovementData[player]
	if not movement then
		return 0
	end

	return movement.Stamina
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MovementController.Initialize()
	print("[MovementController] Initializing advanced movement system...")

	-- Connect players
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- Register with global table
	if _G.TowerAscent then
		_G.TowerAscent.MovementController = MovementController
	end

	print("[MovementController] ✅ Advanced movement system ready")
end

-- Auto-initialize
task.spawn(function()
	task.wait(1)
	MovementController.Initialize()
end)

-- ============================================================================
-- EXPORT
-- ============================================================================

return MovementController