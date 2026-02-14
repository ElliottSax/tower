--[[
	SpeedBoost.lua
	Client-side speed boost mechanic

	Features:
	- Increases WalkSpeed by 10% per level
	- 5 levels total (10%, 20%, 30%, 40%, 50% boost)
	- Base WalkSpeed: 16 (Roblox default)
	- Level 5 WalkSpeed: 24 (50% faster)
	- Auto-updates when player buys more levels
	- Integrates with UpgradeService

	How it works:
	1. Character spawns → check SpeedBoost level
	2. Calculate new WalkSpeed = 16 * (1 + 0.1 * level)
	3. Apply to Humanoid.WalkSpeed
	4. Re-check every 5 seconds (for mid-game purchases)

	Week 3: Full implementation
	Week 4+: Add visual trail effects, sprint particles
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[SpeedBoost] RemoteEvents folder not found!")
	return
end

local getUpgradeLevelFunction = remoteFolder:WaitForChild("GetUpgradeLevel", 10)
if not getUpgradeLevelFunction then
	warn("[SpeedBoost] GetUpgradeLevel RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local BASE_WALKSPEED = 16 -- Roblox default
local SPEED_BOOST_PER_LEVEL = 0.1 -- 10% per level
local MAX_LEVEL = 5

-- ============================================================================
-- STATE
-- ============================================================================

local currentLevel = 0
local currentWalkSpeed = BASE_WALKSPEED

-- ============================================================================
-- SPEED CALCULATION
-- ============================================================================

local function calculateWalkSpeed(level: number): number
	-- WalkSpeed = Base * (1 + 0.1 * level)
	-- Level 0: 16 * 1.0 = 16
	-- Level 1: 16 * 1.1 = 17.6
	-- Level 2: 16 * 1.2 = 19.2
	-- Level 3: 16 * 1.3 = 20.8
	-- Level 4: 16 * 1.4 = 22.4
	-- Level 5: 16 * 1.5 = 24.0

	local multiplier = 1 + (SPEED_BOOST_PER_LEVEL * level)
	return BASE_WALKSPEED * multiplier
end

-- ============================================================================
-- APPLY SPEED BOOST
-- ============================================================================

local function applySpeedBoost(level: number)
	if level == currentLevel then
		return -- No change
	end

	currentLevel = level
	currentWalkSpeed = calculateWalkSpeed(level)

	-- Apply to humanoid
	humanoid.WalkSpeed = currentWalkSpeed

	if level > 0 then
		print(string.format(
			"[SpeedBoost] Applied level %d boost (WalkSpeed: %.1f)",
			level,
			currentWalkSpeed
		))
	end
end

-- ============================================================================
-- CHECK UPGRADE LEVEL
-- ============================================================================

local function checkSpeedBoostLevel()
	local success, level = pcall(function()
		return getUpgradeLevelFunction:InvokeServer("SpeedBoost")
	end)

	if success and level then
		applySpeedBoost(level)
	else
		warn("[SpeedBoost] Failed to get upgrade level:", level)
		-- Default to level 0
		applySpeedBoost(0)
	end
end

-- ============================================================================
-- SPEED PRESERVATION
-- ============================================================================

-- Prevent other scripts from overriding WalkSpeed
humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	-- If WalkSpeed was changed by something else (not us)
	if humanoid.WalkSpeed ~= currentWalkSpeed then
		-- Check if this is a valid change (e.g., status effects)
		-- For now, we'll allow temporary changes but restore after delay
		task.wait(0.1)

		-- Restore our calculated speed if still different
		if math.abs(humanoid.WalkSpeed - currentWalkSpeed) > 0.1 then
			-- Only restore if player still has SpeedBoost
			if currentLevel > 0 then
				-- Allow temporary speed changes (like slow effects)
				-- but restore to boosted speed after they wear off
				task.wait(1)
				if humanoid and humanoid.Parent then
					humanoid.WalkSpeed = currentWalkSpeed
				end
			end
		end
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Initial check
checkSpeedBoostLevel()

-- Re-check periodically (in case player buys more levels)
task.spawn(function()
	while character and character.Parent do
		task.wait(5)
		checkSpeedBoostLevel()
	end
end)

-- Reset on respawn
humanoid.Died:Connect(function()
	currentLevel = 0
	currentWalkSpeed = BASE_WALKSPEED
end)

print("[SpeedBoost] Script initialized")
