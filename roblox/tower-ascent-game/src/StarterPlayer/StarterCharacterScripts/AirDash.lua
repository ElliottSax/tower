--[[
	AirDash.lua
	Client-side air dash mechanic

	Features:
	- Dash forward in mid-air (camera direction)
	- Press Q (or Shift on mobile) to dash
	- Only works if player owns AirDash upgrade (250 coins)
	- Cooldown: 3 seconds
	- Dash power: 60 studs/s horizontal
	- Resets on landing
	- Visual trail effect (Week 4+)

	How it works:
	1. Character spawns → check if owns AirDash
	2. Player presses Q in mid-air
	3. Get camera look direction (horizontal only)
	4. Apply BodyVelocity for 0.3s
	5. Cooldown starts

	Controls:
	- Desktop: Q key
	- Mobile/Console: Shift key (alternative)

	Week 3: Full implementation
	Week 4+: Add trail VFX, dash sound, screen shake
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[AirDash] RemoteEvents folder not found!")
	return
end

local hasUpgradeFunction = remoteFolder:WaitForChild("HasUpgrade", 10)
if not hasUpgradeFunction then
	warn("[AirDash] HasUpgrade RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local DASH_POWER = 60 -- Horizontal velocity for dash
local DASH_DURATION = 0.3 -- How long the dash lasts
local COOLDOWN = 3 -- Seconds between dashes
local UPWARD_BOOST = 5 -- Small upward boost to prevent falling during dash

-- ============================================================================
-- STATE
-- ============================================================================

local hasAirDash = false
local canDash = true
local isDashing = false
local lastDashTime = 0

-- ============================================================================
-- CHECK UPGRADE OWNERSHIP
-- ============================================================================

local function checkAirDashOwnership()
	local success, result = pcall(function()
		return hasUpgradeFunction:InvokeServer("AirDash")
	end)

	if success then
		hasAirDash = result
		print(string.format("[AirDash] Player has AirDash: %s", tostring(hasAirDash)))
	else
		warn("[AirDash] Failed to check upgrade ownership:", result)
		hasAirDash = false
	end
end

-- ============================================================================
-- AIR DASH LOGIC
-- ============================================================================

local function performAirDash()
	if not hasAirDash then return end
	if not canDash then return end
	if isDashing then return end

	-- Check if in mid-air
	local state = humanoid:GetState()
	if state ~= Enum.HumanoidStateType.Freefall
		and state ~= Enum.HumanoidStateType.Jumping then
		return -- Not in air
	end

	-- Check cooldown
	if tick() - lastDashTime < COOLDOWN then
		return
	end

	isDashing = true
	canDash = false
	lastDashTime = tick()

	-- Get camera look direction (horizontal only)
	local camera = Workspace.CurrentCamera
	local cameraCF = camera.CFrame
	local lookVector = cameraCF.LookVector

	-- Remove vertical component (dash horizontally)
	local dashDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

	-- Apply dash velocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = dashDirection * DASH_POWER + Vector3.new(0, UPWARD_BOOST, 0)
	bodyVelocity.Parent = rootPart

	-- Remove after dash duration
	task.delay(DASH_DURATION, function()
		if bodyVelocity then
			bodyVelocity:Destroy()
		end
		isDashing = false
	end)

	-- Visual feedback (placeholder - Week 4 will add trail)
	-- TODO: Add dash trail particle effect
	-- TODO: Add dash sound effect
	-- TODO: Add screen shake

	print(string.format("[AirDash] Dash activated! (Cooldown: %ds)", COOLDOWN))

	-- Cooldown
	task.delay(COOLDOWN, function()
		canDash = true
		print("[AirDash] Dash ready!")
	end)
end

-- ============================================================================
-- UI COOLDOWN INDICATOR (Optional)
-- ============================================================================

local function createCooldownUI()
	-- Create a simple cooldown indicator
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AirDashCooldownUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Cooldown frame (bottom-center)
	local cooldownFrame = Instance.new("Frame")
	cooldownFrame.Name = "CooldownFrame"
	cooldownFrame.AnchorPoint = Vector2.new(0.5, 1)
	cooldownFrame.Position = UDim2.new(0.5, -80, 1, -100)
	cooldownFrame.Size = UDim2.new(0, 60, 0, 60)
	cooldownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	cooldownFrame.BackgroundTransparency = 0.3
	cooldownFrame.BorderSizePixel = 0
	cooldownFrame.Visible = hasAirDash -- Only show if owned
	cooldownFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = cooldownFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = cooldownFrame

	-- Icon/Label
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 32
	iconLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	iconLabel.Text = "Q"
	iconLabel.Parent = cooldownFrame

	-- Cooldown overlay
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0) -- Grows from bottom
	cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
	cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownOverlay.BackgroundTransparency = 0.5
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.Visible = false
	cooldownOverlay.Parent = cooldownFrame

	-- Update cooldown visual
	task.spawn(function()
		while character and character.Parent do
			if not canDash and hasAirDash then
				-- Show cooldown
				cooldownOverlay.Visible = true
				iconLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

				local timeElapsed = tick() - lastDashTime
				local progress = math.clamp(timeElapsed / COOLDOWN, 0, 1)

				-- Grow overlay from bottom to top as cooldown progresses
				cooldownOverlay.Size = UDim2.new(1, 0, 1 - progress, 0)
			else
				-- Ready
				cooldownOverlay.Visible = false
				cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
				iconLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			end

			task.wait(0.05)
		end
	end)

	return screenGui
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	-- Q key or LeftShift for dash
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
		performAirDash()
	end
end

-- ============================================================================
-- MOBILE SUPPORT (TOUCH BUTTON)
-- ============================================================================

local function createMobileDashButton()
	if not UserInputService.TouchEnabled then
		return -- Not mobile
	end

	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AirDashMobileUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Dash button (right side, above jump)
	local dashButton = Instance.new("TextButton")
	dashButton.Name = "DashButton"
	dashButton.AnchorPoint = Vector2.new(1, 1)
	dashButton.Position = UDim2.new(1, -20, 1, -120)
	dashButton.Size = UDim2.new(0, 70, 0, 70)
	dashButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	dashButton.BackgroundTransparency = 0.3
	dashButton.BorderSizePixel = 0
	dashButton.Font = Enum.Font.GothamBold
	dashButton.TextSize = 24
	dashButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	dashButton.Text = "DASH"
	dashButton.Visible = hasAirDash
	dashButton.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 35)
	corner.Parent = dashButton

	dashButton.MouseButton1Click:Connect(performAirDash)

	return screenGui
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Check if player owns AirDash
checkAirDashOwnership()

-- Create UI elements
if hasAirDash then
	createCooldownUI()
	createMobileDashButton()
end

-- Listen for keyboard input
UserInputService.InputBegan:Connect(onInputBegan)

-- Reset on landing
humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		-- Don't reset cooldown, just allow dashing again when back in air
		-- Cooldown continues even on ground
	end
end)

-- Listen for death (cleanup)
humanoid.Died:Connect(function()
	canDash = true
	isDashing = false
end)

-- Re-check upgrade ownership periodically (in case they buy it mid-game)
task.spawn(function()
	while character and character.Parent do
		task.wait(5)
		local hadAirDash = hasAirDash
		checkAirDashOwnership()

		-- If they just bought it, create UI
		if hasAirDash and not hadAirDash then
			createCooldownUI()
			createMobileDashButton()
		end
	end
end)

print("[AirDash] Script initialized (Press Q to dash in mid-air)")
