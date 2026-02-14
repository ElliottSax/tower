--[[
	GliderService.lua
	Handles glider mechanics for the Sky Dimension

	Features:
	- Glider deployment (hold jump in air)
	- Glide physics (forward movement, slow descent)
	- Boost meter (depletes while boosting, refills in updrafts)
	- Wind currents (push player in direction)
	- Updrafts (vertical lift + boost refill)

	How it works:
	1. Player jumps and holds jump button
	2. Glider deploys after short delay
	3. Player glides forward with slow descent
	4. Boost can be used for speed
	5. Wind currents affect movement
	6. Updrafts provide lift and refill boost
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local GliderService = {}

-- ============================================================================
-- STATE
-- ============================================================================

-- Per-player glider state
-- [UserId] = { isGliding, boostMeter, isInUpdraft, isInWindCurrent }
GliderService.PlayerGliders = {}

GliderService.IsActive = false
GliderService.UpdateConnection = nil

-- Configuration
local CONFIG = {
	-- Glider
	DeployDelay = 0.3, -- Seconds of airtime before glider can deploy
	GlideSpeed = 50, -- Forward speed while gliding
	GlideFallSpeed = 20, -- Descent rate while gliding
	GlideBoostSpeed = 80, -- Speed while boosting

	-- Boost
	BoostMeterMax = 100,
	BoostDrainRate = 25, -- Per second while boosting
	BoostRechargeRate = 10, -- Per second in updraft
	BoostRechargeIdle = 2, -- Per second while not boosting (slow regen)

	-- Wind
	WindForceMultiplier = 1,

	-- Updraft
	UpdraftLiftForce = 50,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GliderService.Init()
	print("[GliderService] Initializing...")

	-- Create remotes
	GliderService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		GliderService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GliderService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		GliderService.OnPlayerJoin(player)
	end

	-- Setup wind and updraft detection
	GliderService.SetupWindCurrents()
	GliderService.SetupUpdrafts()

	print("[GliderService] Initialized")
end

function GliderService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Glider deploy/retract
	if not remoteFolder:FindFirstChild("GliderToggle") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GliderToggle"
		event.Parent = remoteFolder

		-- Client tells server they want to toggle glider
		event.OnServerEvent:Connect(function(player, action)
			if action == "deploy" then
				GliderService.DeployGlider(player)
			elseif action == "retract" then
				GliderService.RetractGlider(player)
			elseif action == "boost_start" then
				GliderService.StartBoost(player)
			elseif action == "boost_stop" then
				GliderService.StopBoost(player)
			end
		end)
	end

	-- Glider state update (server -> client)
	if not remoteFolder:FindFirstChild("GliderUpdate") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GliderUpdate"
		event.Parent = remoteFolder
	end

	-- Boost meter update
	if not remoteFolder:FindFirstChild("BoostUpdate") then
		local event = Instance.new("RemoteEvent")
		event.Name = "BoostUpdate"
		event.Parent = remoteFolder
	end

	GliderService.Remotes = {
		GliderToggle = remoteFolder.GliderToggle,
		GliderUpdate = remoteFolder.GliderUpdate,
		BoostUpdate = remoteFolder.BoostUpdate,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function GliderService.OnPlayerJoin(player: Player)
	GliderService.PlayerGliders[player.UserId] = {
		isGliding = false,
		isBoosting = false,
		boostMeter = CONFIG.BoostMeterMax,
		isInUpdraft = false,
		isInWindCurrent = false,
		currentWindDirection = Vector3.zero,
		currentWindStrength = 0,
		airTime = 0,
	}

	player.CharacterAdded:Connect(function(character)
		GliderService.OnCharacterAdded(player, character)
	end)

	if player.Character then
		GliderService.OnCharacterAdded(player, player.Character)
	end
end

function GliderService.OnPlayerLeave(player: Player)
	GliderService.PlayerGliders[player.UserId] = nil
end

function GliderService.OnCharacterAdded(player: Player, character: Model)
	-- Reset glider state on respawn
	local state = GliderService.PlayerGliders[player.UserId]
	if state then
		state.isGliding = false
		state.isBoosting = false
		state.boostMeter = CONFIG.BoostMeterMax
		state.airTime = 0
	end

	-- Track airtime
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.StateChanged:Connect(function(oldState, newState)
			GliderService.OnHumanoidStateChanged(player, oldState, newState)
		end)
	end
end

function GliderService.OnHumanoidStateChanged(player: Player, oldState, newState)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	if newState == Enum.HumanoidStateType.Freefall then
		-- Started falling
		state.airTime = 0
	elseif newState == Enum.HumanoidStateType.Landed then
		-- Landed - retract glider
		if state.isGliding then
			GliderService.RetractGlider(player)
		end
		state.airTime = 0
	end
end

-- ============================================================================
-- GLIDER CONTROL
-- ============================================================================

function GliderService.Start()
	if GliderService.IsActive then return end

	GliderService.IsActive = true

	-- Start update loop
	GliderService.UpdateConnection = RunService.Heartbeat:Connect(function(dt)
		GliderService.Update(dt)
	end)

	print("[GliderService] Started")
end

function GliderService.Stop()
	if not GliderService.IsActive then return end

	GliderService.IsActive = false

	if GliderService.UpdateConnection then
		GliderService.UpdateConnection:Disconnect()
		GliderService.UpdateConnection = nil
	end

	-- Retract all gliders
	for _, player in ipairs(Players:GetPlayers()) do
		GliderService.RetractGlider(player)
	end

	print("[GliderService] Stopped")
end

function GliderService.DeployGlider(player: Player)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	-- Check if can deploy
	if state.isGliding then return end
	if state.airTime < CONFIG.DeployDelay then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Must be in air
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end

	-- Deploy glider
	state.isGliding = true

	-- Create glider visual
	GliderService.CreateGliderVisual(character)

	-- Notify client
	GliderService.Remotes.GliderUpdate:FireClient(player, "deployed")

	print(string.format("[GliderService] %s deployed glider", player.Name))
end

function GliderService.RetractGlider(player: Player)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	if not state.isGliding then return end

	state.isGliding = false
	state.isBoosting = false

	-- Remove glider visual
	local character = player.Character
	if character then
		local glider = character:FindFirstChild("Glider")
		if glider then
			glider:Destroy()
		end
	end

	-- Notify client
	GliderService.Remotes.GliderUpdate:FireClient(player, "retracted")

	print(string.format("[GliderService] %s retracted glider", player.Name))
end

function GliderService.CreateGliderVisual(character: Model)
	-- Remove existing glider
	local existing = character:FindFirstChild("Glider")
	if existing then existing:Destroy() end

	-- Create simple glider model
	local glider = Instance.new("Model")
	glider.Name = "Glider"

	local wing = Instance.new("Part")
	wing.Name = "Wing"
	wing.Size = Vector3.new(12, 0.5, 4)
	wing.Material = Enum.Material.SmoothPlastic
	wing.Color = Color3.fromRGB(255, 255, 255)
	wing.CanCollide = false
	wing.Massless = true
	wing.Parent = glider

	-- Weld to character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = wing
		weld.Parent = wing

		wing.CFrame = rootPart.CFrame * CFrame.new(0, 2, 0)
	end

	glider.Parent = character
end

-- ============================================================================
-- BOOST
-- ============================================================================

function GliderService.StartBoost(player: Player)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	if not state.isGliding then return end
	if state.boostMeter <= 0 then return end

	state.isBoosting = true
end

function GliderService.StopBoost(player: Player)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	state.isBoosting = false
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function GliderService.Update(dt: number)
	for _, player in ipairs(Players:GetPlayers()) do
		GliderService.UpdatePlayer(player, dt)
	end
end

function GliderService.UpdatePlayer(player: Player, dt: number)
	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Track airtime
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		state.airTime = state.airTime + dt
	end

	-- Update boost meter
	GliderService.UpdateBoostMeter(player, state, dt)

	-- Apply gliding physics
	if state.isGliding then
		GliderService.ApplyGlidePhysics(player, state, rootPart, dt)
	end

	-- Apply wind effects (even when not gliding)
	if state.isInWindCurrent then
		GliderService.ApplyWindForce(player, state, rootPart, dt)
	end

	-- Apply updraft effects
	if state.isInUpdraft then
		GliderService.ApplyUpdraftForce(player, state, rootPart, dt)
	end
end

function GliderService.UpdateBoostMeter(player: Player, state, dt: number)
	local oldMeter = state.boostMeter

	if state.isBoosting and state.isGliding then
		-- Drain boost
		state.boostMeter = state.boostMeter - (CONFIG.BoostDrainRate * dt)
		state.boostMeter = math.max(0, state.boostMeter)

		if state.boostMeter <= 0 then
			state.isBoosting = false
		end
	elseif state.isInUpdraft then
		-- Fast recharge in updraft
		state.boostMeter = state.boostMeter + (CONFIG.BoostRechargeRate * dt)
		state.boostMeter = math.min(CONFIG.BoostMeterMax, state.boostMeter)
	else
		-- Slow idle recharge
		state.boostMeter = state.boostMeter + (CONFIG.BoostRechargeIdle * dt)
		state.boostMeter = math.min(CONFIG.BoostMeterMax, state.boostMeter)
	end

	-- Notify client if changed significantly
	if math.abs(state.boostMeter - oldMeter) > 1 then
		GliderService.Remotes.BoostUpdate:FireClient(player, state.boostMeter, CONFIG.BoostMeterMax)
	end
end

function GliderService.ApplyGlidePhysics(player: Player, state, rootPart: BasePart, dt: number)
	-- Calculate glide velocity
	local lookVector = rootPart.CFrame.LookVector
	local speed = state.isBoosting and CONFIG.GlideBoostSpeed or CONFIG.GlideSpeed
	local fallSpeed = CONFIG.GlideFallSpeed

	-- Reduce fall speed while gliding
	local currentVel = rootPart.AssemblyLinearVelocity

	-- Forward movement
	local horizontalVel = Vector3.new(lookVector.X, 0, lookVector.Z).Unit * speed

	-- Controlled descent
	local verticalVel = math.max(currentVel.Y, -fallSpeed)

	-- Apply velocity
	rootPart.AssemblyLinearVelocity = Vector3.new(
		horizontalVel.X,
		verticalVel,
		horizontalVel.Z
	)
end

function GliderService.ApplyWindForce(player: Player, state, rootPart: BasePart, dt: number)
	if state.currentWindStrength <= 0 then return end

	local force = state.currentWindDirection * state.currentWindStrength * CONFIG.WindForceMultiplier * dt
	rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + force
end

function GliderService.ApplyUpdraftForce(player: Player, state, rootPart: BasePart, dt: number)
	local liftForce = Vector3.new(0, CONFIG.UpdraftLiftForce * dt, 0)
	rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + liftForce
end

-- ============================================================================
-- WIND CURRENTS
-- ============================================================================

function GliderService.SetupWindCurrents()
	for _, current in ipairs(CollectionService:GetTagged("WindCurrent")) do
		GliderService.ConnectWindCurrent(current)
	end

	CollectionService:GetInstanceAddedSignal("WindCurrent"):Connect(function(current)
		GliderService.ConnectWindCurrent(current)
	end)
end

function GliderService.ConnectWindCurrent(current: BasePart)
	current.Touched:Connect(function(hit)
		GliderService.OnWindCurrentEnter(current, hit)
	end)

	current.TouchEnded:Connect(function(hit)
		GliderService.OnWindCurrentExit(current, hit)
	end)
end

function GliderService.OnWindCurrentEnter(current: BasePart, hit: BasePart)
	local player = GliderService.GetPlayerFromHit(hit)
	if not player then return end

	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	state.isInWindCurrent = true
	state.currentWindDirection = current:GetAttribute("WindDirection") or Vector3.new(0, 1, 0)
	state.currentWindStrength = current:GetAttribute("WindStrength") or 30
end

function GliderService.OnWindCurrentExit(current: BasePart, hit: BasePart)
	local player = GliderService.GetPlayerFromHit(hit)
	if not player then return end

	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	state.isInWindCurrent = false
	state.currentWindStrength = 0
end

-- ============================================================================
-- UPDRAFTS
-- ============================================================================

function GliderService.SetupUpdrafts()
	for _, updraft in ipairs(CollectionService:GetTagged("Updraft")) do
		GliderService.ConnectUpdraft(updraft)
	end

	CollectionService:GetInstanceAddedSignal("Updraft"):Connect(function(updraft)
		GliderService.ConnectUpdraft(updraft)
	end)
end

function GliderService.ConnectUpdraft(updraft: BasePart)
	updraft.Touched:Connect(function(hit)
		GliderService.OnUpdraftEnter(updraft, hit)
	end)

	updraft.TouchEnded:Connect(function(hit)
		GliderService.OnUpdraftExit(updraft, hit)
	end)
end

function GliderService.OnUpdraftEnter(updraft: BasePart, hit: BasePart)
	local player = GliderService.GetPlayerFromHit(hit)
	if not player then return end

	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	state.isInUpdraft = true
end

function GliderService.OnUpdraftExit(updraft: BasePart, hit: BasePart)
	local player = GliderService.GetPlayerFromHit(hit)
	if not player then return end

	local state = GliderService.PlayerGliders[player.UserId]
	if not state then return end

	state.isInUpdraft = false
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function GliderService.GetPlayerFromHit(hit: BasePart): Player?
	local character = hit.Parent
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	return Players:GetPlayerFromCharacter(character)
end

function GliderService.Cleanup()
	GliderService.Stop()
	print("[GliderService] Cleaned up")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function GliderService.DebugPrint()
	print("=== GLIDER SERVICE STATUS ===")
	print(string.format("Active: %s", tostring(GliderService.IsActive)))

	for userId, state in pairs(GliderService.PlayerGliders) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Gliding=%s, Boosting=%s, Boost=%.0f%%",
				player.Name,
				tostring(state.isGliding),
				tostring(state.isBoosting),
				(state.boostMeter / CONFIG.BoostMeterMax) * 100
			))
		end
	end

	print("==============================")
end

return GliderService
