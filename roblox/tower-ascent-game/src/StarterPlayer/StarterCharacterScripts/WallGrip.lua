--[[
	WallGrip.lua
	Client-side wall grip mechanic

	Features:
	- Slide down walls slower when touching them
	- 3 levels (+1 second grip time per level)
	- Base slide speed: -10 studs/s (normal fall: -50)
	- Level 1: 1s grip time
	- Level 2: 2s grip time
	- Level 3: 3s grip time
	- Auto-detects walls via raycasting
	- Jump off walls with Space

	How it works:
	1. Character is falling + touching wall
	2. Apply BodyVelocity to slow descent
	3. Timer counts down based on level
	4. When timer expires, normal fall speed resumes
	5. Resets when landing or jumping

	Controls:
	- Automatic (no input needed)
	- Space to jump off wall

	Week 3: Full implementation
	Week 4+: Add wall particles, grip sound
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
	warn("[WallGrip] RemoteEvents folder not found!")
	return
end

local getUpgradeLevelFunction = remoteFolder:WaitForChild("GetUpgradeLevel", 10)
if not getUpgradeLevelFunction then
	warn("[WallGrip] GetUpgradeLevel RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local WALL_SLIDE_SPEED = -10 -- Slower descent than normal fall
local NORMAL_FALL_SPEED = -50 -- Default gravity
local GRIP_TIME_PER_LEVEL = 1 -- Seconds per level
local MAX_LEVEL = 3
local WALL_DETECTION_DISTANCE = 2.5 -- Studs
local RAYCAST_DIRECTIONS = 8 -- Check 8 directions around player

-- ============================================================================
-- STATE
-- ============================================================================

local wallGripLevel = 0
local isGrippingWall = false
local gripTimeRemaining = 0
local maxGripTime = 0
local currentBodyVelocity = nil

-- Raycast params (ignore character)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- ============================================================================
-- CHECK UPGRADE LEVEL
-- ============================================================================

local function checkWallGripLevel()
	local success, level = pcall(function()
		return getUpgradeLevelFunction:InvokeServer("WallGrip")
	end)

	if success and level then
		wallGripLevel = level
		maxGripTime = GRIP_TIME_PER_LEVEL * level

		if level > 0 then
			print(string.format(
				"[WallGrip] Level %d active (Grip time: %.1fs)",
				level,
				maxGripTime
			))
		end
	else
		warn("[WallGrip] Failed to get upgrade level:", level)
		wallGripLevel = 0
		maxGripTime = 0
	end
end

-- ============================================================================
-- WALL DETECTION
-- ============================================================================

local function isNearWall(): boolean
	if wallGripLevel == 0 then return false end

	-- Update raycast filter to ignore character
	raycastParams.FilterDescendantsInstances = {character}

	-- Check multiple directions around player
	for i = 0, RAYCAST_DIRECTIONS - 1 do
		local angle = (i / RAYCAST_DIRECTIONS) * math.pi * 2
		local direction = Vector3.new(
			math.cos(angle),
			0, -- Don't check up/down
			math.sin(angle)
		)

		local origin = rootPart.Position
		local rayResult = Workspace:Raycast(
			origin,
			direction * WALL_DETECTION_DISTANCE,
			raycastParams
		)

		if rayResult then
			-- Found a wall, check if it's vertical enough
			local normal = rayResult.Normal
			local verticalAngle = math.acos(math.abs(normal.Y))

			-- Wall is vertical if angle is close to 90 degrees (1.57 radians)
			if verticalAngle > math.rad(60) then
				return true
			end
		end
	end

	return false
end

-- ============================================================================
-- WALL GRIP LOGIC
-- ============================================================================

local function startWallGrip()
	if isGrippingWall then return end
	if gripTimeRemaining <= 0 then return end

	isGrippingWall = true

	-- Apply slow descent
	if not currentBodyVelocity then
		currentBodyVelocity = Instance.new("BodyVelocity")
		currentBodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		currentBodyVelocity.Parent = rootPart
	end

	currentBodyVelocity.Velocity = Vector3.new(0, WALL_SLIDE_SPEED, 0)

	print(string.format("[WallGrip] Started wall grip (%.1fs remaining)", gripTimeRemaining))
end

local function stopWallGrip()
	if not isGrippingWall then return end

	isGrippingWall = false

	-- Remove slow descent
	if currentBodyVelocity then
		currentBodyVelocity:Destroy()
		currentBodyVelocity = nil
	end

	print("[WallGrip] Stopped wall grip")
end

local function resetWallGrip()
	stopWallGrip()
	gripTimeRemaining = maxGripTime
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

local function onUpdate(deltaTime: number)
	if wallGripLevel == 0 then return end

	local state = humanoid:GetState()

	-- Check if falling
	local isFalling = state == Enum.HumanoidStateType.Freefall

	if isFalling then
		-- Check if near wall
		if isNearWall() and gripTimeRemaining > 0 then
			-- Start gripping
			if not isGrippingWall then
				startWallGrip()
			end

			-- Countdown timer
			gripTimeRemaining = math.max(0, gripTimeRemaining - deltaTime)

			-- Update velocity (keep sliding)
			if currentBodyVelocity then
				currentBodyVelocity.Velocity = Vector3.new(0, WALL_SLIDE_SPEED, 0)
			end

			-- Stop if timer runs out
			if gripTimeRemaining <= 0 then
				stopWallGrip()
			end
		else
			-- Not near wall or out of time
			if isGrippingWall then
				stopWallGrip()
			end
		end
	else
		-- Not falling, stop gripping
		if isGrippingWall then
			stopWallGrip()
		end
	end
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

humanoid.StateChanged:Connect(function(oldState, newState)
	-- Reset grip time when landing
	if newState == Enum.HumanoidStateType.Landed then
		resetWallGrip()
	end

	-- Stop gripping when jumping
	if newState == Enum.HumanoidStateType.Jumping then
		stopWallGrip()
	end
end)

-- ============================================================================
-- UI INDICATOR (Optional)
-- ============================================================================

local function createGripUI()
	if wallGripLevel == 0 then return end

	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WallGripUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- Grip meter (bottom-center, right of AirDash)
	local gripFrame = Instance.new("Frame")
	gripFrame.Name = "GripFrame"
	gripFrame.AnchorPoint = Vector2.new(0.5, 1)
	gripFrame.Position = UDim2.new(0.5, 0, 1, -100)
	gripFrame.Size = UDim2.new(0, 150, 0, 20)
	gripFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	gripFrame.BackgroundTransparency = 0.3
	gripFrame.BorderSizePixel = 0
	gripFrame.Visible = false -- Only show when gripping
	gripFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = gripFrame

	-- Grip bar (fills based on remaining time)
	local gripBar = Instance.new("Frame")
	gripBar.Name = "GripBar"
	gripBar.Size = UDim2.new(1, 0, 1, 0)
	gripBar.BackgroundColor3 = Color3.fromRGB(255, 150, 50) -- Orange
	gripBar.BorderSizePixel = 0
	gripBar.Parent = gripFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = gripBar

	-- Label
	local gripLabel = Instance.new("TextLabel")
	gripLabel.Size = UDim2.new(1, 0, 1, 0)
	gripLabel.BackgroundTransparency = 1
	gripLabel.Font = Enum.Font.GothamBold
	gripLabel.TextSize = 12
	gripLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	gripLabel.Text = "WALL GRIP"
	gripLabel.Parent = gripFrame

	-- Update loop
	task.spawn(function()
		while character and character.Parent do
			if isGrippingWall then
				gripFrame.Visible = true

				-- Update bar width
				local progress = gripTimeRemaining / maxGripTime
				gripBar.Size = UDim2.new(progress, 0, 1, 0)

				-- Change color as time runs out
				if progress > 0.5 then
					gripBar.BackgroundColor3 = Color3.fromRGB(255, 150, 50) -- Orange
				elseif progress > 0.25 then
					gripBar.BackgroundColor3 = Color3.fromRGB(255, 100, 0) -- Dark orange
				else
					gripBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
				end
			else
				gripFrame.Visible = false
			end

			task.wait(0.05)
		end
	end)

	return screenGui
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Check upgrade level
checkWallGripLevel()

-- Create UI if owned
if wallGripLevel > 0 then
	createGripUI()
	resetWallGrip()
end

-- Start update loop
local updateConnection = RunService.Heartbeat:Connect(onUpdate)

-- Cleanup on death
humanoid.Died:Connect(function()
	stopWallGrip()
	if updateConnection then
		updateConnection:Disconnect()
	end
end)

-- Re-check level periodically
task.spawn(function()
	while character and character.Parent do
		task.wait(5)
		local oldLevel = wallGripLevel
		checkWallGripLevel()

		if wallGripLevel > oldLevel and wallGripLevel > 0 then
			createGripUI()
			resetWallGrip()
		end
	end
end)

print("[WallGrip] Script initialized")
