--[[
	DoubleJump.lua
	Client-side double jump mechanic

	Features:
	- Only works if player owns DoubleJump upgrade
	- Press Space in mid-air to double jump
	- Visual feedback (particle effect placeholder)
	- Sound effect placeholder
	- Integrates with UpgradeService

	How it works:
	1. Character spawns → check if player has DoubleJump upgrade
	2. Listen for Jump input
	3. If in mid-air and haven't double jumped → apply upward velocity
	4. Reset on landing

	Week 2: Full implementation
	Week 3+: Add VFX, sound effects, air dash integration
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[DoubleJump] RemoteEvents folder not found!")
	return
end

local hasUpgradeFunction = remoteFolder:WaitForChild("HasUpgrade", 10)
if not hasUpgradeFunction then
	warn("[DoubleJump] HasUpgrade RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DOUBLE_JUMP_POWER = 50 -- Vertical velocity for double jump
local COOLDOWN = 0.1 -- Prevent spam

-- ============================================================================
-- STATE
-- ============================================================================

local hasDoubleJump = false
local canDoubleJump = false
local hasUsedDoubleJump = false
local lastJumpTime = 0

-- ============================================================================
-- CHECK UPGRADE OWNERSHIP
-- ============================================================================

local function checkDoubleJumpOwnership()
	local success, result = pcall(function()
		return hasUpgradeFunction:InvokeServer("DoubleJump")
	end)

	if success then
		hasDoubleJump = result
		print(string.format("[DoubleJump] Player has DoubleJump: %s", tostring(hasDoubleJump)))
	else
		warn("[DoubleJump] Failed to check upgrade ownership:", result)
		hasDoubleJump = false
	end
end

-- ============================================================================
-- DOUBLE JUMP LOGIC
-- ============================================================================

local function performDoubleJump()
	if not hasDoubleJump then return end
	if not canDoubleJump then return end
	if hasUsedDoubleJump then return end

	-- Cooldown check
	if tick() - lastJumpTime < COOLDOWN then return end

	-- Apply upward velocity using modern LinearVelocity (replaces deprecated BodyVelocity)
	local attachment = Instance.new("Attachment")
	attachment.Name = "DoubleJumpAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DoubleJumpVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = Vector3.new(0, DOUBLE_JUMP_POWER, 0)
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	-- Remove after short duration
	task.delay(0.2, function()
		if linearVelocity and linearVelocity.Parent then
			linearVelocity:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)

	hasUsedDoubleJump = true
	lastJumpTime = tick()

	-- Visual feedback (placeholder - Week 3 will add particles)
	-- TODO: Add particle effect
	-- TODO: Add sound effect

	print("[DoubleJump] Double jump activated!")
end

-- ============================================================================
-- STATE TRACKING
-- ============================================================================

local function onStateChanged(oldState, newState)
	-- When player jumps from ground
	if newState == Enum.HumanoidStateType.Jumping then
		-- First jump - enable double jump
		canDoubleJump = true
		hasUsedDoubleJump = false
	end

	-- When player lands
	if newState == Enum.HumanoidStateType.Landed then
		-- Reset double jump
		canDoubleJump = false
		hasUsedDoubleJump = false
	end

	-- When player is falling (walked off edge)
	if newState == Enum.HumanoidStateType.Freefall then
		-- Enable double jump if not already used
		if not hasUsedDoubleJump then
			canDoubleJump = true
		end
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- Jump input (Space bar)
	if input.KeyCode == Enum.KeyCode.Space then
		-- Check if should double jump
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall
			or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
			performDoubleJump()
		end
	end
end

-- ============================================================================
-- MOBILE SUPPORT (TOUCH)
-- ============================================================================

-- Listen for jump request from mobile controls
humanoid.Jumping:Connect(function()
	-- If already in air, this is a double jump attempt
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall
		or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
		-- Small delay to prevent first jump from triggering double jump
		if tick() - lastJumpTime > 0.2 then
			performDoubleJump()
		end
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Check if player owns DoubleJump upgrade
checkDoubleJumpOwnership()

-- Listen for state changes
humanoid.StateChanged:Connect(onStateChanged)

-- Listen for keyboard input
UserInputService.InputBegan:Connect(onInputBegan)

-- Listen for death (cleanup)
humanoid.Died:Connect(function()
	canDoubleJump = false
	hasUsedDoubleJump = false
end)

-- Re-check upgrade ownership periodically (in case they buy it mid-game)
task.spawn(function()
	while character and character.Parent do
		task.wait(5)
		checkDoubleJumpOwnership()
	end
end)

print("[DoubleJump] Script initialized")
