--[[
	DoubleJump.lua (LocalScript)
	Place this inside StarterPlayer > StarterCharacterScripts

	Features:
	- Enables double jump for players who own the upgrade
	- Detects jump input while in mid-air
	- Resets on landing
	- Server-validated (checks upgrade ownership)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Wait for RemoteEvents
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[DoubleJump] RemoteEvents folder not found!")
	return
end

local hasUpgradeFunction = remoteFolder:WaitForChild("HasUpgrade", 10)
if not hasUpgradeFunction then
	warn("[DoubleJump] HasUpgrade function not found!")
	return
end

-- Double jump state
local hasDoubleJump = false
local canDoubleJump = false
local doubleJumpUsed = false

-- Jump power configuration
local DOUBLE_JUMP_POWER = 50 -- Same as default jump power

-- Check if player owns double jump upgrade
local function checkUpgradeOwnership()
	local success, result = pcall(function()
		return hasUpgradeFunction:InvokeServer("DoubleJump")
	end)

	if success then
		hasDoubleJump = result
		print("[DoubleJump] Upgrade status:", hasDoubleJump and "OWNED" or "NOT OWNED")
	else
		warn("[DoubleJump] Failed to check upgrade ownership:", result)
		hasDoubleJump = false
	end
end

-- Perform double jump
local function performDoubleJump()
	if not hasDoubleJump then
		return -- Don't have upgrade
	end

	if doubleJumpUsed then
		return -- Already used double jump
	end

	if humanoid:GetState() == Enum.HumanoidStateType.Freefall or
	   humanoid:GetState() == Enum.HumanoidStateType.Flying then

		-- Perform double jump
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		-- Apply jump force
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, DOUBLE_JUMP_POWER, 0)
			bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
			bodyVelocity.Parent = rootPart

			-- Remove after brief moment
			task.wait(0.1)
			bodyVelocity:Destroy()
		end

		doubleJumpUsed = true
		print("[DoubleJump] Double jump activated!")

		-- Visual feedback (optional: add particle effect here)
	end
end

-- Reset double jump when player lands
local function onStateChanged(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		doubleJumpUsed = false
		canDoubleJump = true
	elseif newState == Enum.HumanoidStateType.Jumping then
		-- First jump
		task.wait(0.1) -- Small delay to allow for double jump
		canDoubleJump = true
	end
end

-- Listen for jump input
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.Touch then
		if canDoubleJump then
			performDoubleJump()
		end
	end
end

-- Mobile jump button support
local function onJumpRequest()
	if canDoubleJump then
		performDoubleJump()
	end
end

-- Initialize
local function initialize()
	-- Check upgrade ownership
	checkUpgradeOwnership()

	-- Listen for state changes
	humanoid.StateChanged:Connect(onStateChanged)

	-- Listen for jump input (PC)
	UserInputService.InputBegan:Connect(onInputBegan)

	-- Listen for jump button (Mobile)
	humanoid.JumpRequest:Connect(onJumpRequest)

	print("[DoubleJump] Initialized for", player.Name)
end

-- Run initialization
initialize()

-- Re-check upgrade ownership periodically (in case they buy it mid-game)
task.spawn(function()
	while task.wait(5) do
		if not hasDoubleJump then
			checkUpgradeOwnership()
		end
	end
end)
