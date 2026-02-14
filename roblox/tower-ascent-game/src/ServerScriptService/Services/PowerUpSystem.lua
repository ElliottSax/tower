--[[
	PowerUpSystem.lua
	Dynamic power-up and ability system

	Features:
	- Spawnable power-ups throughout tower
	- Temporary abilities and buffs
	- Stackable effects
	- Rare and legendary power-ups
	- Power-up combinations
	- Visual indicators
	- Strategic placement

	Created: 2025-12-03
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local PowerUpSystem = {}
PowerUpSystem.Enabled = true

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Spawn settings
	SpawnInterval = 30, -- Seconds between spawns
	MaxActivePowerUps = 10,
	DespawnTime = 60, -- Seconds before despawn
	RespawnDelay = 20,

	-- Rarity weights
	RarityWeights = {
		Common = 50,
		Uncommon = 30,
		Rare = 15,
		Epic = 4,
		Legendary = 1
	},

	-- Power-up duration defaults
	DefaultDuration = {
		Common = 15,
		Uncommon = 20,
		Rare = 25,
		Epic = 30,
		Legendary = 45
	},

	-- Visual settings
	RotationSpeed = 2,
	BobAmount = 0.5,
	BobSpeed = 1,
	PickupRange = 5
}

-- ============================================================================
-- POWER-UP DEFINITIONS
-- ============================================================================

local POWER_UPS = {
	-- Common Power-Ups
	SPEED_BOOST = {
		Name = "Speed Boost",
		Rarity = "Common",
		Icon = "🏃",
		Color = Color3.fromRGB(0, 255, 0),
		Duration = 15,
		Effect = function(player, data)
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then
				local originalSpeed = humanoid.WalkSpeed
				humanoid.WalkSpeed = humanoid.WalkSpeed * 1.5
				return function() -- Cleanup
					humanoid.WalkSpeed = originalSpeed
				end
			end
		end,
		Description = "50% speed increase"
	},

	JUMP_BOOST = {
		Name = "Jump Boost",
		Rarity = "Common",
		Icon = "⬆️",
		Color = Color3.fromRGB(100, 255, 100),
		Duration = 15,
		Effect = function(player, data)
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then
				local originalPower = humanoid.JumpPower
				humanoid.JumpPower = humanoid.JumpPower * 1.5
				return function()
					humanoid.JumpPower = originalPower
				end
			end
		end,
		Description = "50% jump power increase"
	},

	COIN_MAGNET = {
		Name = "Coin Magnet",
		Rarity = "Common",
		Icon = "🧲",
		Color = Color3.fromRGB(255, 215, 0),
		Duration = 20,
		Effect = function(player, data)
			data.CoinMagnetActive = true
			data.MagnetRange = 20
			return function()
				data.CoinMagnetActive = false
			end
		end,
		Description = "Attracts nearby coins"
	},

	-- Uncommon Power-Ups
	DOUBLE_COINS = {
		Name = "Double Coins",
		Rarity = "Uncommon",
		Icon = "💰",
		Color = Color3.fromRGB(255, 255, 0),
		Duration = 30,
		Effect = function(player, data)
			data.CoinMultiplier = (data.CoinMultiplier or 1) * 2
			return function()
				data.CoinMultiplier = (data.CoinMultiplier or 2) / 2
			end
		end,
		Description = "Doubles coin collection"
	},

	SHIELD = {
		Name = "Shield",
		Rarity = "Uncommon",
		Icon = "🛡️",
		Color = Color3.fromRGB(100, 100, 255),
		Duration = 20,
		Effect = function(player, data)
			data.ShieldActive = true
			data.ShieldHits = 3
			-- Create visual shield
			local shield = Instance.new("Part")
			shield.Name = "Shield"
			shield.Size = Vector3.new(6, 6, 6)
			shield.Material = Enum.Material.ForceField
			shield.BrickColor = BrickColor.new("Cyan")
			shield.Transparency = 0.7
			shield.Shape = Enum.PartType.Ball
			shield.Anchored = false
			shield.CanCollide = false
			shield.Parent = player.Character

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = shield
			weld.Part1 = player.Character.HumanoidRootPart
			weld.Parent = shield

			data.ShieldPart = shield
			return function()
				data.ShieldActive = false
				if data.ShieldPart then
					data.ShieldPart:Destroy()
				end
			end
		end,
		Description = "Blocks 3 hits"
	},

	GRAVITY_REDUCTION = {
		Name = "Low Gravity",
		Rarity = "Uncommon",
		Icon = "🪐",
		Color = Color3.fromRGB(200, 100, 255),
		Duration = 25,
		Effect = function(player, data)
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then
				local originalGravity = workspace.Gravity
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
				bodyVelocity.Velocity = Vector3.new(0, 10, 0)
				bodyVelocity.Parent = player.Character.HumanoidRootPart
				data.GravityModifier = bodyVelocity
				return function()
					if data.GravityModifier then
						data.GravityModifier:Destroy()
					end
				end
			end
		end,
		Description = "Reduces gravity by 50%"
	},

	-- Rare Power-Ups
	TELEPORT_CHECKPOINT = {
		Name = "Checkpoint Teleport",
		Rarity = "Rare",
		Icon = "✨",
		Color = Color3.fromRGB(255, 0, 255),
		Duration = 0, -- Instant
		Effect = function(player, data)
			-- Teleport to next checkpoint
			local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
			if CheckpointService then
				local nextCheckpoint = CheckpointService.GetNextCheckpoint(player)
				if nextCheckpoint then
					player.Character:SetPrimaryPartCFrame(nextCheckpoint.CFrame + Vector3.new(0, 5, 0))
				end
			end
		end,
		Description = "Teleport to next checkpoint",
		Instant = true
	},

	INVINCIBILITY = {
		Name = "Invincibility",
		Rarity = "Rare",
		Icon = "⭐",
		Color = Color3.fromRGB(255, 215, 0),
		Duration = 10,
		Effect = function(player, data)
			data.Invincible = true
			local character = player.Character
			if character then
				-- Rainbow effect
				local parts = {}
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						table.insert(parts, part)
						part.Material = Enum.Material.Neon
					end
				end

				local rainbow = coroutine.create(function()
					while data.Invincible do
						for i = 0, 1, 0.05 do
							if not data.Invincible then break end
							local color = Color3.fromHSV(i, 1, 1)
							for _, part in ipairs(parts) do
								if part and part.Parent then
									part.Color = color
								end
							end
							task.wait(0.05)
						end
					end
				end)
				coroutine.resume(rainbow)

				return function()
					data.Invincible = false
					-- Reset materials
					for _, part in ipairs(parts) do
						if part and part.Parent then
							part.Material = Enum.Material.Plastic
						end
					end
				end
			end
		end,
		Description = "Complete invincibility"
	},

	TRIPLE_JUMP = {
		Name = "Triple Jump",
		Rarity = "Rare",
		Icon = "3️⃣",
		Color = Color3.fromRGB(100, 255, 255),
		Duration = 30,
		Effect = function(player, data)
			data.ExtraJumps = 2
			data.JumpsRemaining = 2
			return function()
				data.ExtraJumps = 0
				data.JumpsRemaining = 0
			end
		end,
		Description = "Allows triple jumping"
	},

	-- Epic Power-Ups
	TIME_SLOW = {
		Name = "Time Dilation",
		Rarity = "Epic",
		Icon = "⏰",
		Color = Color3.fromRGB(100, 100, 200),
		Duration = 15,
		Effect = function(player, data)
			-- Slow everything except player
			data.TimeSlowActive = true

			-- Speed up player relatively
			local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = humanoid.WalkSpeed * 2
				humanoid.JumpPower = humanoid.JumpPower * 1.5
			end

			-- Visual effect
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Brightness = -0.1
			cc.Contrast = 0.2
			cc.Saturation = -0.5
			cc.TintColor = Color3.fromRGB(150, 150, 255)
			cc.Parent = game.Lighting
			data.TimeEffect = cc

			return function()
				data.TimeSlowActive = false
				if humanoid then
					humanoid.WalkSpeed = humanoid.WalkSpeed / 2
					humanoid.JumpPower = humanoid.JumpPower / 1.5
				end
				if data.TimeEffect then
					data.TimeEffect:Destroy()
				end
			end
		end,
		Description = "Slows time around you"
	},

	GHOST_MODE = {
		Name = "Ghost Mode",
		Rarity = "Epic",
		Icon = "👻",
		Color = Color3.fromRGB(200, 200, 255),
		Duration = 20,
		Effect = function(player, data)
			data.GhostMode = true
			local character = player.Character
			if character then
				-- Make translucent
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 0.5
						part.CanCollide = false
					end
				end

				return function()
					data.GhostMode = false
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.CanCollide = true
						end
					end
				end
			end
		end,
		Description = "Phase through obstacles"
	},

	TELEKINESIS = {
		Name = "Telekinesis",
		Rarity = "Epic",
		Icon = "🧠",
		Color = Color3.fromRGB(255, 100, 255),
		Duration = 25,
		Effect = function(player, data)
			data.TelekinesisActive = true
			-- Allow player to move platforms
			return function()
				data.TelekinesisActive = false
			end
		end,
		Description = "Move platforms with your mind"
	},

	-- Legendary Power-Ups
	FLYING = {
		Name = "Flight",
		Rarity = "Legendary",
		Icon = "🦅",
		Color = Color3.fromRGB(255, 255, 255),
		Duration = 30,
		Effect = function(player, data)
			data.FlyingActive = true
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
					bodyVelocity.Velocity = Vector3.new(0, 0, 0)
					bodyVelocity.Parent = rootPart
					data.FlyVelocity = bodyVelocity

					local bodyGyro = Instance.new("BodyGyro")
					bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
					bodyGyro.CFrame = rootPart.CFrame
					bodyGyro.Parent = rootPart
					data.FlyGyro = bodyGyro

					-- Wings visual
					local wing1 = Instance.new("Part")
					wing1.Name = "Wing1"
					wing1.Size = Vector3.new(3, 4, 0.5)
					wing1.Material = Enum.Material.Neon
					wing1.BrickColor = BrickColor.new("White")
					wing1.Transparency = 0.3
					wing1.Anchored = false
					wing1.CanCollide = false
					wing1.Parent = character

					local wing2 = wing1:Clone()
					wing2.Name = "Wing2"
					wing2.Parent = character

					local weld1 = Instance.new("WeldConstraint")
					weld1.Part0 = wing1
					weld1.Part1 = rootPart
					weld1.Parent = wing1
					wing1.CFrame = rootPart.CFrame * CFrame.new(-2, 0, 1)

					local weld2 = Instance.new("WeldConstraint")
					weld2.Part0 = wing2
					weld2.Part1 = rootPart
					weld2.Parent = wing2
					wing2.CFrame = rootPart.CFrame * CFrame.new(2, 0, 1)

					data.Wings = {wing1, wing2}

					return function()
						data.FlyingActive = false
						if data.FlyVelocity then data.FlyVelocity:Destroy() end
						if data.FlyGyro then data.FlyGyro:Destroy() end
						if data.Wings then
							for _, wing in ipairs(data.Wings) do
								wing:Destroy()
							end
						end
					end
				end
			end
		end,
		Description = "Grants temporary flight"
	},

	GOD_MODE = {
		Name = "God Mode",
		Rarity = "Legendary",
		Icon = "⚡",
		Color = Color3.fromRGB(255, 215, 0),
		Duration = 20,
		Effect = function(player, data)
			data.GodMode = true
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					-- Max stats
					humanoid.WalkSpeed = 50
					humanoid.JumpPower = 100
					data.GodModeInvincible = true

					-- Golden aura
					local aura = Instance.new("SelectionSphere")
					aura.Color3 = Color3.fromRGB(255, 215, 0)
					aura.SurfaceTransparency = 0.5
					aura.Transparency = 0.3
					aura.Adornee = character.HumanoidRootPart
					aura.Parent = character
					data.GodAura = aura

					-- Lightning effect
					local lightning = Instance.new("ParticleEmitter")
					lightning.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					lightning.Rate = 100
					lightning.Lifetime = NumberRange.new(1)
					lightning.VelocitySpreadAngle = Vector2.new(360, 360)
					lightning.Speed = NumberRange.new(10)
					lightning.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
					lightning.Parent = character.HumanoidRootPart
					data.GodLightning = lightning

					return function()
						data.GodMode = false
						data.GodModeInvincible = false
						humanoid.WalkSpeed = 16
						humanoid.JumpPower = 50
						if data.GodAura then data.GodAura:Destroy() end
						if data.GodLightning then data.GodLightning:Destroy() end
					end
				end
			end
		end,
		Description = "Ultimate power"
	},

	REWIND = {
		Name = "Time Rewind",
		Rarity = "Legendary",
		Icon = "⏪",
		Color = Color3.fromRGB(255, 100, 100),
		Duration = 0, -- Instant
		Effect = function(player, data)
			-- Rewind player position by 10 seconds
			if data.PositionHistory and #data.PositionHistory > 0 then
				local rewindPosition = data.PositionHistory[math.max(1, #data.PositionHistory - 100)]
				player.Character:SetPrimaryPartCFrame(CFrame.new(rewindPosition))

				-- Visual effect
				local effect = Instance.new("Part")
				effect.Name = "RewindEffect"
				effect.Size = Vector3.new(10, 10, 10)
				effect.Material = Enum.Material.ForceField
				effect.BrickColor = BrickColor.new("Really red")
				effect.Transparency = 0
				effect.Anchored = true
				effect.CanCollide = false
				effect.Shape = Enum.PartType.Ball
				effect.CFrame = player.Character.HumanoidRootPart.CFrame
				effect.Parent = workspace

				local tween = TweenService:Create(effect,
					TweenInfo.new(1, Enum.EasingStyle.Linear),
					{Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}
				)
				tween:Play()
				Debris:AddItem(effect, 1.1)
			end
		end,
		Description = "Rewind time by 10 seconds",
		Instant = true
	}
}

-- Power-up combinations
local COMBINATIONS = {
	{
		PowerUps = {"SPEED_BOOST", "JUMP_BOOST"},
		Result = "SUPER_MOBILITY",
		Bonus = function(player, data)
			-- Extra dash ability
			data.DashesAvailable = 3
		end
	},
	{
		PowerUps = {"SHIELD", "INVINCIBILITY"},
		Result = "IMMORTALITY",
		Bonus = function(player, data)
			-- Reflect damage
			data.ReflectDamage = true
		end
	},
	{
		PowerUps = {"COIN_MAGNET", "DOUBLE_COINS"},
		Result = "TREASURE_HUNTER",
		Bonus = function(player, data)
			-- Triple coins instead
			data.CoinMultiplier = 3
		end
	}
}

-- ============================================================================
-- POWER-UP SPAWNING
-- ============================================================================

local activePowerUps = {}
local playerPowerUpData = {}

function PowerUpSystem.SpawnPowerUp(position: Vector3?, powerUpId: string?)
	if #activePowerUps >= CONFIG.MaxActivePowerUps then
		return nil
	end

	-- Choose power-up
	local chosenPowerUp
	if powerUpId and POWER_UPS[powerUpId] then
		chosenPowerUp = POWER_UPS[powerUpId]
	else
		chosenPowerUp = PowerUpSystem.ChooseRandomPowerUp()
	end

	if not chosenPowerUp then
		return nil
	end

	-- Find spawn position if not provided
	if not position then
		position = PowerUpSystem.FindSpawnPosition()
		if not position then
			return nil
		end
	end

	-- Create power-up model
	local powerUpModel = Instance.new("Model")
	powerUpModel.Name = "PowerUp_" .. chosenPowerUp.Name

	-- Main part
	local mainPart = Instance.new("Part")
	mainPart.Name = "MainPart"
	mainPart.Size = Vector3.new(3, 3, 3)
	mainPart.Material = Enum.Material.Neon
	mainPart.BrickColor = BrickColor.new(chosenPowerUp.Color)
	mainPart.Transparency = 0.3
	mainPart.Anchored = true
	mainPart.CanCollide = false
	mainPart.Shape = Enum.PartType.Ball
	mainPart.Position = position
	mainPart.Parent = powerUpModel

	powerUpModel.PrimaryPart = mainPart

	-- Rarity indicator
	local rarityPart = Instance.new("Part")
	rarityPart.Name = "RarityIndicator"
	rarityPart.Size = Vector3.new(4, 0.5, 4)
	rarityPart.Material = Enum.Material.Neon
	rarityPart.Transparency = 0.5
	rarityPart.Anchored = true
	rarityPart.CanCollide = false
	rarityPart.Position = position + Vector3.new(0, -2, 0)
	rarityPart.Parent = powerUpModel

	-- Set rarity color
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Uncommon = Color3.fromRGB(100, 255, 100),
		Rare = Color3.fromRGB(100, 100, 255),
		Epic = Color3.fromRGB(255, 100, 255),
		Legendary = Color3.fromRGB(255, 215, 0)
	}
	rarityPart.Color = rarityColors[chosenPowerUp.Rarity] or Color3.fromRGB(255, 255, 255)

	-- Create light
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = chosenPowerUp.Color
	light.Range = 10
	light.Parent = mainPart

	-- Create billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = mainPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = chosenPowerUp.Icon
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.Parent = billboard

	-- Store power-up data
	local powerUpData = {
		Model = powerUpModel,
		PowerUp = chosenPowerUp,
		Position = position,
		SpawnTime = tick(),
		Claimed = false
	}

	table.insert(activePowerUps, powerUpData)
	powerUpModel.Parent = workspace

	-- Start animation
	PowerUpSystem.AnimatePowerUp(powerUpData)

	-- Setup despawn timer
	task.spawn(function()
		task.wait(CONFIG.DespawnTime)
		if not powerUpData.Claimed then
			PowerUpSystem.DespawnPowerUp(powerUpData)
		end
	end)

	return powerUpData
end

function PowerUpSystem.ChooseRandomPowerUp()
	-- Calculate total weight
	local totalWeight = 0
	for rarity, weight in pairs(CONFIG.RarityWeights) do
		totalWeight = totalWeight + weight
	end

	-- Random selection
	local random = math.random() * totalWeight
	local currentWeight = 0

	local chosenRarity = "Common"
	for rarity, weight in pairs(CONFIG.RarityWeights) do
		currentWeight = currentWeight + weight
		if random <= currentWeight then
			chosenRarity = rarity
			break
		end
	end

	-- Get power-ups of chosen rarity
	local eligiblePowerUps = {}
	for id, powerUp in pairs(POWER_UPS) do
		if powerUp.Rarity == chosenRarity then
			table.insert(eligiblePowerUps, powerUp)
		end
	end

	if #eligiblePowerUps > 0 then
		return eligiblePowerUps[math.random(#eligiblePowerUps)]
	end

	return nil
end

function PowerUpSystem.FindSpawnPosition(): Vector3?
	-- Find platforms in the tower
	local platforms = {}
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:find("Platform") then
			table.insert(platforms, part)
		end
	end

	if #platforms > 0 then
		local platform = platforms[math.random(#platforms)]
		return platform.Position + Vector3.new(0, 5, 0)
	end

	return nil
end

function PowerUpSystem.AnimatePowerUp(powerUpData: {})
	local model = powerUpData.Model
	local mainPart = model.PrimaryPart

	-- Rotation animation
	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if powerUpData.Claimed or not mainPart.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime

		-- Rotation
		mainPart.CFrame = mainPart.CFrame * CFrame.Angles(0, math.rad(CONFIG.RotationSpeed), 0)

		-- Bobbing
		local bobOffset = math.sin(elapsed * CONFIG.BobSpeed) * CONFIG.BobAmount
		mainPart.Position = powerUpData.Position + Vector3.new(0, bobOffset, 0)

		-- Check for nearby players
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character.PrimaryPart then
				local distance = (player.Character.PrimaryPart.Position - mainPart.Position).Magnitude
				if distance <= CONFIG.PickupRange then
					PowerUpSystem.CollectPowerUp(player, powerUpData)
					connection:Disconnect()
					break
				end
			end
		end
	end)
end

function PowerUpSystem.DespawnPowerUp(powerUpData: {})
	powerUpData.Claimed = true

	-- Fade out effect
	local model = powerUpData.Model
	if model and model.Parent then
		local mainPart = model.PrimaryPart
		if mainPart then
			local tween = TweenService:Create(mainPart,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad),
				{Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1)}
			)
			tween:Play()
			tween.Completed:Connect(function()
				model:Destroy()
			end)
		else
			model:Destroy()
		end
	end

	-- Remove from active list
	for i, data in ipairs(activePowerUps) do
		if data == powerUpData then
			table.remove(activePowerUps, i)
			break
		end
	end
end

-- ============================================================================
-- POWER-UP COLLECTION
-- ============================================================================

function PowerUpSystem.CollectPowerUp(player: Player, powerUpData: {})
	if powerUpData.Claimed then
		return
	end

	powerUpData.Claimed = true
	local powerUp = powerUpData.PowerUp

	print(string.format("%s collected %s!", player.Name, powerUp.Name))

	-- Initialize player data if needed
	if not playerPowerUpData[player] then
		playerPowerUpData[player] = {
			ActivePowerUps = {},
			PowerUpHistory = {},
			PositionHistory = {},
			CoinMultiplier = 1
		}
	end

	local playerData = playerPowerUpData[player]

	-- Check for combinations
	PowerUpSystem.CheckCombinations(player, powerUp)

	-- Apply power-up effect
	if powerUp.Effect then
		local cleanup = powerUp.Effect(player, playerData)

		if not powerUp.Instant then
			-- Schedule cleanup
			local duration = powerUp.Duration or CONFIG.DefaultDuration[powerUp.Rarity] or 15
			local powerUpInstance = {
				PowerUp = powerUp,
				StartTime = tick(),
				Duration = duration,
				Cleanup = cleanup
			}
			table.insert(playerData.ActivePowerUps, powerUpInstance)

			-- Create UI indicator
			PowerUpSystem.CreatePowerUpIndicator(player, powerUpInstance)

			-- Schedule removal
			task.spawn(function()
				task.wait(duration)
				PowerUpSystem.RemovePowerUp(player, powerUpInstance)
			end)
		elseif cleanup then
			-- Instant power-ups might still have cleanup
			cleanup()
		end
	end

	-- Add to history
	table.insert(playerData.PowerUpHistory, {
		PowerUp = powerUp.Name,
		Time = tick()
	})

	-- Collection effect
	PowerUpSystem.CreateCollectionEffect(player, powerUpData)

	-- Despawn the power-up
	PowerUpSystem.DespawnPowerUp(powerUpData)

	-- Award points/coins
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if CoinService then
		local coinReward = 10 * ({Common=1, Uncommon=2, Rare=5, Epic=10, Legendary=25})[powerUp.Rarity]
		CoinService.AwardCoins(player, coinReward)
	end
end

function PowerUpSystem.RemovePowerUp(player: Player, powerUpInstance: {})
	local playerData = playerPowerUpData[player]
	if not playerData then
		return
	end

	-- Call cleanup function
	if powerUpInstance.Cleanup then
		powerUpInstance.Cleanup()
	end

	-- Remove from active list
	for i, instance in ipairs(playerData.ActivePowerUps) do
		if instance == powerUpInstance then
			table.remove(playerData.ActivePowerUps, i)
			break
		end
	end

	print(string.format("%s expired for %s", powerUpInstance.PowerUp.Name, player.Name))
end

function PowerUpSystem.CheckCombinations(player: Player, newPowerUp: {})
	local playerData = playerPowerUpData[player]
	if not playerData then
		return
	end

	-- Check active power-ups for combinations
	for _, combo in ipairs(COMBINATIONS) do
		local hasAll = true
		for _, requiredPowerUp in ipairs(combo.PowerUps) do
			local found = false
			for _, active in ipairs(playerData.ActivePowerUps) do
				if active.PowerUp.Name == POWER_UPS[requiredPowerUp].Name then
					found = true
					break
				end
			end
			if not found and newPowerUp.Name ~= POWER_UPS[requiredPowerUp].Name then
				hasAll = false
				break
			end
		end

		if hasAll then
			print(string.format("COMBINATION! %s activated for %s", combo.Result, player.Name))
			if combo.Bonus then
				combo.Bonus(player, playerData)
			end
		end
	end
end

-- ============================================================================
-- VISUAL EFFECTS
-- ============================================================================

function PowerUpSystem.CreateCollectionEffect(player: Player, powerUpData: {})
	local model = powerUpData.Model
	local powerUp = powerUpData.PowerUp

	if not model or not model.PrimaryPart then
		return
	end

	-- Particle burst
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(1)
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Speed = NumberRange.new(10)
	emitter.VelocitySpreadAngle = Vector2.new(360, 360)
	emitter.Color = ColorSequence.new(powerUp.Color)
	emitter.Parent = model.PrimaryPart

	emitter:Emit(50)
	Debris:AddItem(emitter, 2)

	-- Sound effect (if SoundService available)
	local SoundService = _G.TowerAscent and _G.TowerAscent.SoundService
	if SoundService then
		SoundService.PlaySound("PowerUpCollect", model.PrimaryPart.Position)
	end
end

function PowerUpSystem.CreatePowerUpIndicator(player: Player, powerUpInstance: {})
	-- This would create a UI element showing active power-up
	-- For now, we'll create a simple particle effect
	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end

	local indicator = Instance.new("ParticleEmitter")
	indicator.Name = "PowerUpIndicator"
	indicator.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	indicator.Rate = 20
	indicator.Lifetime = NumberRange.new(1)
	indicator.VelocityInheritance = 0
	indicator.EmissionDirection = Enum.NormalId.Top
	indicator.Speed = NumberRange.new(2)
	indicator.SpreadAngle = Vector2.new(10, 10)
	indicator.Color = ColorSequence.new(powerUpInstance.PowerUp.Color)
	indicator.Parent = character.PrimaryPart

	powerUpInstance.Indicator = indicator

	-- Remove when power-up expires
	task.spawn(function()
		task.wait(powerUpInstance.Duration)
		if indicator and indicator.Parent then
			indicator:Destroy()
		end
	end)
end

-- ============================================================================
-- SPECIAL ABILITIES
-- ============================================================================

function PowerUpSystem.UpdateFlight(player: Player)
	local playerData = playerPowerUpData[player]
	if not playerData or not playerData.FlyingActive then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return
	end

	-- Get camera direction for flight control
	local camera = workspace.CurrentCamera
	if camera then
		local moveVector = humanoid.MoveVector
		local cameraLook = camera.CFrame.LookVector
		local cameraRight = camera.CFrame.RightVector

		local flyDirection = (cameraLook * moveVector.Z + cameraRight * moveVector.X)
		flyDirection = flyDirection + Vector3.new(0, moveVector.Y, 0)

		if playerData.FlyVelocity then
			playerData.FlyVelocity.Velocity = flyDirection * 50
		end

		if playerData.FlyGyro then
			playerData.FlyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flyDirection)
		end
	end
end

function PowerUpSystem.UpdateCoinMagnet(player: Player)
	local playerData = playerPowerUpData[player]
	if not playerData or not playerData.CoinMagnetActive then
		return
	end

	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end

	-- Find nearby coins
	for _, coin in ipairs(workspace:GetDescendants()) do
		if coin:IsA("BasePart") and coin.Name == "Coin" then
			local distance = (coin.Position - character.PrimaryPart.Position).Magnitude
			if distance <= playerData.MagnetRange then
				-- Move coin toward player
				coin.CFrame = coin.CFrame:Lerp(character.PrimaryPart.CFrame, 0.2)
			end
		end
	end
end

-- ============================================================================
-- SPAWN MANAGEMENT
-- ============================================================================

function PowerUpSystem.StartSpawnLoop()
	task.spawn(function()
		while PowerUpSystem.Enabled do
			task.wait(CONFIG.SpawnInterval)

			-- Check if round is active
			local RoundService = _G.TowerAscent and _G.TowerAscent.RoundService
			if RoundService and RoundService.CurrentState == "InProgress" then
				PowerUpSystem.SpawnPowerUp()
			end
		end
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

local function onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Initialize player data
	if not playerPowerUpData[player] then
		playerPowerUpData[player] = {
			ActivePowerUps = {},
			PowerUpHistory = {},
			PositionHistory = {},
			CoinMultiplier = 1
		}
	end

	-- Start position tracking for rewind
	local data = playerPowerUpData[player]
	task.spawn(function()
		while player.Character == character do
			if character.PrimaryPart then
				table.insert(data.PositionHistory, character.PrimaryPart.Position)
				-- Keep only last 200 positions (20 seconds at 0.1s intervals)
				while #data.PositionHistory > 200 do
					table.remove(data.PositionHistory, 1)
				end
			end
			task.wait(0.1)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	-- Clean up player data
	local playerData = playerPowerUpData[player]
	if playerData then
		-- Clean up active power-ups
		for _, powerUpInstance in ipairs(playerData.ActivePowerUps) do
			if powerUpInstance.Cleanup then
				powerUpInstance.Cleanup()
			end
			if powerUpInstance.Indicator then
				powerUpInstance.Indicator:Destroy()
			end
		end
		playerPowerUpData[player] = nil
	end
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function PowerUpSystem.StartUpdateLoop()
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local playerData = playerPowerUpData[player]
			if playerData then
				-- Update special abilities
				PowerUpSystem.UpdateFlight(player)
				PowerUpSystem.UpdateCoinMagnet(player)
			end
		end
	end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PowerUpSystem.GetActiveP