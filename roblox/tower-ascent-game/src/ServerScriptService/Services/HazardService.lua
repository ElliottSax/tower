--[[
	HazardService.lua
	Manages all environmental hazards in Tower Ascent

	Responsibilities:
	- Initialize hazards in tower sections
	- Handle player-hazard interactions
	- Manage hazard behaviors (damage, knockback, slow, etc.)
	- Apply visual/audio effects to hazards
	- Handle timed hazards (falling platforms, retractable spikes)

	Week 9 Implementation
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local HazardDefinitions = require(ServerScriptService.HazardDefinitions.HazardDefinitions)

local HazardService = {}

-- ============================================================================
-- STATE
-- ============================================================================

local ActiveHazards = {} -- [hazard instance] = {type, behavior, effects}
local PlayerCooldowns = {} -- [player][hazard] = tick()
local HazardConnections = {} -- Cleanup connections

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
	Initialize HazardService
	Scans tower for hazards and sets up behaviors
	@param tower Model - The tower model
--]]
function HazardService.Init(tower: Model?)
	print("[HazardService] Initializing...")

	-- Clean up PlayerCooldowns when players leave to prevent memory leaks
	Players.PlayerRemoving:Connect(function(player)
		PlayerCooldowns[player] = nil
	end)

	if not tower then
		warn("[HazardService] No tower provided, hazards will be initialized on demand")
		return
	end

	-- Scan tower for hazards
	local hazardCount = HazardService.InitializeTowerHazards(tower)

	print(string.format("[HazardService] Initialized %d hazards", hazardCount))
end

--[[
	Initialize all hazards in a tower
	@param tower Model - The tower model
	@return number - Number of hazards initialized
--]]
function HazardService.InitializeTowerHazards(tower: Model): number
	local hazardCount = 0

	for _, section in ipairs(tower:GetChildren()) do
		if section:IsA("Model") and section.Name:match("^Section_") then
			hazardCount = hazardCount + HazardService.InitializeSectionHazards(section)
		end
	end

	return hazardCount
end

--[[
	Initialize hazards in a section
	@param section Model - The section model
	@return number - Number of hazards initialized
--]]
function HazardService.InitializeSectionHazards(section: Model): number
	local hazardCount = 0

	for _, descendant in ipairs(section:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("HazardType") then
			local hazardType = descendant:GetAttribute("HazardType")
			HazardService.InitializeHazard(descendant, hazardType)
			hazardCount = hazardCount + 1
		end
	end

	return hazardCount
end

-- ============================================================================
-- HAZARD INITIALIZATION
-- ============================================================================

--[[
	Initialize a single hazard
	@param part BasePart - The hazard part
	@param hazardType string - Type of hazard (Lava, Spikes, etc.)
--]]
function HazardService.InitializeHazard(part: BasePart, hazardType: string)
	local hazardDef = HazardDefinitions.GetHazard(hazardType)
	if not hazardDef then
		warn("[HazardService] Unknown hazard type:", hazardType)
		return
	end

	-- Apply visual properties
	HazardService.ApplyHazardVisuals(part, hazardDef)

	-- Apply effects (particles, sounds, lights)
	HazardService.ApplyHazardEffects(part, hazardDef)

	-- Set up behavior
	HazardService.SetupHazardBehavior(part, hazardDef)

	-- Store in active hazards
	ActiveHazards[part] = {
		Type = hazardType,
		Definition = hazardDef,
		OriginalPosition = part.Position,
		OriginalCFrame = part.CFrame,
	}
end

--[[
	Apply visual properties to hazard
	@param part BasePart - The hazard part
	@param hazardDef table - Hazard definition
--]]
function HazardService.ApplyHazardVisuals(part: BasePart, hazardDef: table)
	-- Don't override if part already has custom material/color
	if not part:GetAttribute("CustomVisuals") then
		part.Material = hazardDef.Material
		part.Color = hazardDef.Color

		if hazardDef.Transparency then
			part.Transparency = hazardDef.Transparency
		end

		if hazardDef.Reflectance then
			part.Reflectance = hazardDef.Reflectance
		end
	end
end

--[[
	Apply effects to hazard (particles, sounds, lights)
	@param part BasePart - The hazard part
	@param hazardDef table - Hazard definition
--]]
function HazardService.ApplyHazardEffects(part: BasePart, hazardDef: table)
	-- Particles
	if hazardDef.Particles and hazardDef.Particles.Enabled then
		local particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Parent = part

		local pDef = hazardDef.Particles
		if pDef.Color then particleEmitter.Color = pDef.Color end
		if pDef.Size then particleEmitter.Size = pDef.Size end
		if pDef.Lifetime then particleEmitter.Lifetime = pDef.Lifetime end
		if pDef.Rate then particleEmitter.Rate = pDef.Rate end
		if pDef.Speed then particleEmitter.Speed = pDef.Speed end
		if pDef.Transparency then particleEmitter.Transparency = pDef.Transparency end

		if pDef.SpreadAngle then
			particleEmitter.SpreadAngle = pDef.SpreadAngle
		end

		if pDef.Velocity then
			particleEmitter.EmissionDirection = Enum.NormalId.Top
			particleEmitter.Acceleration = pDef.Velocity
		end
	end

	-- Looped sound
	if hazardDef.Sound and hazardDef.Sound.Looped then
		local sound = Instance.new("Sound")
		sound.SoundId = hazardDef.Sound.SoundId
		sound.Volume = hazardDef.Sound.Volume or 0.5
		sound.Looped = true
		sound.Parent = part
		sound:Play()
	end

	-- Light
	if hazardDef.Light and hazardDef.Light.Enabled then
		local light = Instance.new("PointLight")
		light.Brightness = hazardDef.Light.Brightness or 1
		light.Color = hazardDef.Light.Color or Color3.new(1, 1, 1)
		light.Range = hazardDef.Light.Range or 10
		light.Parent = part
	end
end

-- ============================================================================
-- HAZARD BEHAVIORS
-- ============================================================================

--[[
	Set up hazard behavior (touch events, timers, etc.)
	@param part BasePart - The hazard part
	@param hazardDef table - Hazard definition
--]]
function HazardService.SetupHazardBehavior(part: BasePart, hazardDef: table)
	local hazardType = hazardDef.Type

	if hazardType == "InstantDeath" then
		HazardService.SetupInstantDeathHazard(part, hazardDef)

	elseif hazardType == "Damage" then
		HazardService.SetupDamageHazard(part, hazardDef)

	elseif hazardType == "DamageOverTime" then
		HazardService.SetupDamageOverTimeHazard(part, hazardDef)

	elseif hazardType == "Knockback" then
		HazardService.SetupKnockbackHazard(part, hazardDef)

	elseif hazardType == "Force" then
		HazardService.SetupForceHazard(part, hazardDef)

	elseif hazardType == "Surface" then
		HazardService.SetupSurfaceHazard(part, hazardDef)

	elseif hazardType == "Slow" then
		HazardService.SetupSlowHazard(part, hazardDef)

	elseif hazardType == "Timed" then
		HazardService.SetupTimedHazard(part, hazardDef)
	end
end

--[[
	Setup instant death hazard (Lava)
--]]
function HazardService.SetupInstantDeathHazard(part: BasePart, hazardDef: table)
	local connection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or not player.Character then return end

		-- Instant death
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)

	table.insert(HazardConnections, connection)
end

--[[
	Setup damage hazard (Spikes)
--]]
function HazardService.SetupDamageHazard(part: BasePart, hazardDef: table)
	local connection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player then return end

		-- Check cooldown
		if HazardService.IsOnCooldown(player, part) then return end

		-- Apply damage
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(hazardDef.Damage)

			-- Play sound effect
			if hazardDef.Sound and hazardDef.Sound.OnTouch then
				HazardService.PlaySound(part, hazardDef.Sound.OnTouch, hazardDef.Sound.Volume)
			end

			-- Set cooldown
			HazardService.SetCooldown(player, part, hazardDef.TouchCooldown or 1)
		end
	end)

	table.insert(HazardConnections, connection)

	-- Setup retractable spikes if enabled
	if hazardDef.Retractable and hazardDef.Retractable.Enabled then
		HazardService.SetupRetractableSpikes(part, hazardDef.Retractable)
	end
end

--[[
	Setup damage over time hazard (Poison Gas)
--]]
function HazardService.SetupDamageOverTimeHazard(part: BasePart, hazardDef: table)
	local playersInZone = {}

	-- Entered zone
	local enterConnection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or not player.Character or playersInZone[player] then return end

		playersInZone[player] = true

		-- Start damage loop
		-- Track the character that entered so we stop if they die/respawn
		local enteredCharacter = player.Character
		task.spawn(function()
			while playersInZone[player] and part.Parent do
				-- Stop if player left, character changed (respawned), or part was destroyed
				if not player.Parent or player.Character ~= enteredCharacter then
					playersInZone[player] = nil
					break
				end

				local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid:TakeDamage(hazardDef.Damage)
				else
					-- Player died, stop damage loop
					playersInZone[player] = nil
					break
				end

				task.wait(hazardDef.TickRate or 0.5)
			end
		end)
	end)

	-- Exited zone
	local exitConnection = part.TouchEnded:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player then return end

		playersInZone[player] = nil
	end)

	table.insert(HazardConnections, enterConnection)
	table.insert(HazardConnections, exitConnection)
end

--[[
	Setup knockback hazard (Rotating Obstacle)
--]]
function HazardService.SetupKnockbackHazard(part: BasePart, hazardDef: table)
	-- Continuous rotation
	task.spawn(function()
		while part.Parent do
			local rotationSpeed = hazardDef.RotationSpeed or 30
			local axis = hazardDef.RotationAxis or Vector3.new(0, 1, 0)

			part.CFrame = part.CFrame * CFrame.Angles(
				math.rad(axis.X * rotationSpeed / 60),
				math.rad(axis.Y * rotationSpeed / 60),
				math.rad(axis.Z * rotationSpeed / 60)
			)

			task.wait(1 / 60) -- 60 FPS
		end
	end)

	-- Knockback on touch
	local connection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or not player.Character then return end

		-- Check cooldown
		if HazardService.IsOnCooldown(player, part) then return end

		-- Apply knockback
		local humanoid = player.Character:FindFirstChild("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart then
			-- Damage
			if hazardDef.Damage > 0 then
				humanoid:TakeDamage(hazardDef.Damage)
			end

			-- Knockback force
			local direction = (rootPart.Position - part.Position).Unit
			local force = Instance.new("BodyVelocity")
			force.Velocity = direction * (hazardDef.KnockbackForce or 50)
			force.MaxForce = Vector3.new(4000, 4000, 4000)
			force.Parent = rootPart

			task.delay(0.1, function()
				force:Destroy()
			end)

			-- Set cooldown
			HazardService.SetCooldown(player, part, 1)
		end
	end)

	table.insert(HazardConnections, connection)
end

--[[
	Setup force hazard (Wind Zone)
--]]
function HazardService.SetupForceHazard(part: BasePart, hazardDef: table)
	-- Create BodyForce inside the zone
	local bodyForce = Instance.new("BodyForce")
	bodyForce.Force = (hazardDef.WindDirection.Unit * hazardDef.WindForce) * workspace.Gravity
	bodyForce.Parent = part

	-- Apply force to players in zone
	local connection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player then return end

		local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Create temporary force
			local force = Instance.new("BodyVelocity")
			force.Velocity = hazardDef.WindDirection.Unit * hazardDef.WindForce
			force.MaxForce = Vector3.new(4000, 0, 4000) -- No Y-axis force
			force.Parent = rootPart

			-- Remove after short duration
			task.delay(0.5, function()
				if force.Parent then
					force:Destroy()
				end
			end)
		end
	end)

	table.insert(HazardConnections, connection)
end

--[[
	Setup surface hazard (Ice)
--]]
function HazardService.SetupSurfaceHazard(part: BasePart, hazardDef: table)
	-- Reduce friction
	local friction = hazardDef.FrictionMultiplier or 0.1
	part.CustomPhysicalProperties = PhysicalProperties.new(
		0.7, -- Density
		friction,
		0.5, -- Elasticity
		1, -- Friction weight
		1  -- Elasticity weight
	)

	-- Optional: Play sound on step
	if hazardDef.Sound and hazardDef.Sound.OnStep then
		local connection = part.Touched:Connect(function(hit)
			local player = HazardService.GetPlayerFromPart(hit)
			if not player then return end

			if not HazardService.IsOnCooldown(player, part) then
				HazardService.PlaySound(part, hazardDef.Sound.OnStep, hazardDef.Sound.Volume)
				HazardService.SetCooldown(player, part, 0.5)
			end
		end)

		table.insert(HazardConnections, connection)
	end
end

--[[
	Setup slow hazard (Quicksand)
--]]
function HazardService.SetupSlowHazard(part: BasePart, hazardDef: table)
	local playersInZone = {} -- [player] = originalSpeed

	-- Entered zone
	local enterConnection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or not player.Character or playersInZone[player] then return end

		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if not humanoid then return end

		-- Store original speed so we can restore it correctly
		playersInZone[player] = humanoid.WalkSpeed

		-- Apply slow
		humanoid.WalkSpeed = playersInZone[player] * (hazardDef.SpeedMultiplier or 0.3)

		-- Play enter sound
		if hazardDef.Sound and hazardDef.Sound.OnEnter then
			HazardService.PlaySound(part, hazardDef.Sound.OnEnter, hazardDef.Sound.Volume)
		end
	end)

	-- Exited zone
	local exitConnection = part.TouchEnded:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or not playersInZone[player] then return end

		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			-- Restore the actual original speed instead of hardcoded 16
			humanoid.WalkSpeed = playersInZone[player]
		end

		playersInZone[player] = nil
	end)

	table.insert(HazardConnections, enterConnection)
	table.insert(HazardConnections, exitConnection)
end

--[[
	Setup timed hazard (Falling Platform)
--]]
function HazardService.SetupTimedHazard(part: BasePart, hazardDef: table)
	local triggered = false
	local originalCFrame = part.CFrame

	local connection = part.Touched:Connect(function(hit)
		local player = HazardService.GetPlayerFromPart(hit)
		if not player or triggered then return end

		triggered = true

		-- Warning phase
		if hazardDef.Warning and hazardDef.Warning.Enabled then
			-- Shake platform
			task.spawn(function()
				for i = 1, 10 do
					part.CFrame = originalCFrame * CFrame.new(
						math.random(-hazardDef.Warning.ShakeMagnitude, hazardDef.Warning.ShakeMagnitude),
						0,
						math.random(-hazardDef.Warning.ShakeMagnitude, hazardDef.Warning.ShakeMagnitude)
					)
					task.wait(0.05)
				end
			end)

			-- Color change
			if hazardDef.Warning.ColorChange then
				part.Color = hazardDef.Warning.ColorChange
			end

			-- Transparency change
			if hazardDef.Warning.TransparencyChange then
				part.Transparency = hazardDef.Warning.TransparencyChange
			end

			-- Play warning sound
			if hazardDef.Sound and hazardDef.Sound.OnTrigger then
				HazardService.PlaySound(part, hazardDef.Sound.OnTrigger, hazardDef.Sound.Volume)
			end
		end

		-- Wait for fall delay
		task.wait(hazardDef.FallDelay or 0.5)

		-- Play fall sound
		if hazardDef.Sound and hazardDef.Sound.OnFall then
			HazardService.PlaySound(part, hazardDef.Sound.OnFall, hazardDef.Sound.Volume)
		end

		-- Fall animation
		local fallTween = TweenService:Create(part, TweenInfo.new(
			hazardDef.FallSpeed or 2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		), {
			Position = part.Position - Vector3.new(0, 200, 0),
			Transparency = 1
		})

		fallTween:Play()
		fallTween.Completed:Wait()

		-- Respawn platform
		task.wait(hazardDef.RespawnTime or 5)

		part.CFrame = originalCFrame
		part.Transparency = 0
		triggered = false
	end)

	table.insert(HazardConnections, connection)
end

--[[
	Setup retractable spikes
--]]
function HazardService.SetupRetractableSpikes(part: BasePart, retractableDef: table)
	local originalY = part.Position.Y
	local retractedY = originalY - (part.Size.Y * 0.9) -- Almost fully retracted

	task.spawn(function()
		while part.Parent do
			-- Extended phase
			part.CanCollide = true
			task.wait(retractableDef.ExtendedTime or 2)

			-- Retract
			local retractTween = TweenService:Create(part, TweenInfo.new(
				retractableDef.TransitionTime or 0.3,
				Enum.EasingStyle.Quad
			), {
				Position = Vector3.new(part.Position.X, retractedY, part.Position.Z)
			})
			retractTween:Play()
			retractTween.Completed:Wait()

			-- Retracted phase
			part.CanCollide = false
			task.wait(retractableDef.RetractedTime or 2)

			-- Extend
			local extendTween = TweenService:Create(part, TweenInfo.new(
				retractableDef.TransitionTime or 0.3,
				Enum.EasingStyle.Quad
			), {
				Position = Vector3.new(part.Position.X, originalY, part.Position.Z)
			})
			extendTween:Play()
			extendTween.Completed:Wait()
		end
	end)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
	Get player from touched part
	@param part BasePart - The part that was touched
	@return Player? - The player who touched it
--]]
function HazardService.GetPlayerFromPart(part: BasePart): Player?
	local character = part.Parent
	if not character then return nil end

	local player = Players:GetPlayerFromCharacter(character)
	return player
end

--[[
	Check if player is on cooldown for hazard
	@param player Player - The player
	@param hazard BasePart - The hazard
	@return boolean - True if on cooldown
--]]
function HazardService.IsOnCooldown(player: Player, hazard: BasePart): boolean
	if not PlayerCooldowns[player] then
		PlayerCooldowns[player] = {}
	end

	local lastTouch = PlayerCooldowns[player][hazard]
	if not lastTouch then return false end

	return (tick() - lastTouch) < 1
end

--[[
	Set cooldown for player on hazard
	@param player Player - The player
	@param hazard BasePart - The hazard
	@param duration number - Cooldown duration
--]]
function HazardService.SetCooldown(player: Player, hazard: BasePart, duration: number)
	if not PlayerCooldowns[player] then
		PlayerCooldowns[player] = {}
	end

	PlayerCooldowns[player][hazard] = tick()
end

--[[
	Play sound effect
	@param parent Instance - Parent for sound
	@param soundId string - Sound asset ID
	@param volume number - Volume (0-1)
--]]
function HazardService.PlaySound(parent: Instance, soundId: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = parent
	sound:Play()

	-- Cleanup after playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

--[[
	Cleanup all hazard connections
--]]
function HazardService.Cleanup()
	print("[HazardService] Cleaning up...")

	for _, connection in ipairs(HazardConnections) do
		connection:Disconnect()
	end

	HazardConnections = {}
	ActiveHazards = {}
	PlayerCooldowns = {}

	print("[HazardService] Cleanup complete")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function HazardService.GetActiveHazardCount(): number
	local count = 0
	for _ in pairs(ActiveHazards) do
		count = count + 1
	end
	return count
end

function HazardService.DebugPrintStats()
	print("=== HAZARD SERVICE STATS ===")
	print(string.format("Active hazards: %d", HazardService.GetActiveHazardCount()))
	print(string.format("Active connections: %d", #HazardConnections))
	print("============================")
end

return HazardService
