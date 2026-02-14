--[[
	MovingPlatformService.lua
	Handles animated moving platforms in tower sections

	Features:
	- Detects platforms with IsMovingPlatform attribute
	- Animates platforms between start and end positions
	- Supports different speeds per platform
	- Uses TweenService for smooth animation
	- Automatic cleanup
	- Performance optimized

	Usage:
	Platforms created with SectionBuilder:AddMovingPlatform() are
	automatically detected and animated by this service.

	Attributes Required:
	- IsMovingPlatform (boolean)
	- StartPosition (Vector3)
	- EndPosition (Vector3)
	- Speed (number, studs per second)

	Week 7: Initial implementation
--]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MovingPlatformService = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local EASING_STYLE = Enum.EasingStyle.Sine
local EASING_DIRECTION = Enum.EasingDirection.InOut

-- Track active platforms and tweens
local ActivePlatforms = {} -- {platform -> {tween, startPos, endPos, speed}}

-- ============================================================================
-- PLATFORM DETECTION
-- ============================================================================

function MovingPlatformService.DetectPlatforms(tower: Model)
	--[[
		Scans tower for platforms with IsMovingPlatform attribute.
		Initializes animation for each platform.
	--]]

	local count = 0

	for _, descendant in ipairs(tower:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsMovingPlatform") then
			local success = MovingPlatformService.InitializePlatform(descendant)
			if success then
				count = count + 1
			end
		end
	end

	print(string.format("[MovingPlatformService] Initialized %d moving platforms", count))
	return count
end

-- ============================================================================
-- PLATFORM INITIALIZATION
-- ============================================================================

function MovingPlatformService.InitializePlatform(platform: BasePart): boolean
	--[[
		Sets up a moving platform for animation.
		Returns true if successful.
	--]]

	-- Get attributes
	local startPos = platform:GetAttribute("StartPosition")
	local endPos = platform:GetAttribute("EndPosition")
	local speed = platform:GetAttribute("Speed") or 5

	-- Validate attributes
	if not startPos or not endPos then
		warn(string.format(
			"[MovingPlatformService] Platform '%s' missing StartPosition or EndPosition",
			platform:GetFullName()
		))
		return false
	end

	-- Validate speed
	if speed <= 0 then
		warn(string.format(
			"[MovingPlatformService] Platform '%s' has invalid speed (%.1f), using default (5)",
			platform:GetFullName(),
			speed
		))
		speed = 5
	end

	-- Ensure platform is anchored
	platform.Anchored = true

	-- Remove existing BodyPosition if present (from SectionBuilder)
	local bodyPosition = platform:FindFirstChildOfClass("BodyPosition")
	if bodyPosition then
		bodyPosition:Destroy()
	end

	-- Calculate duration based on distance and speed
	local distance = (endPos - startPos).Magnitude
	local duration = distance / speed

	-- Store platform data
	ActivePlatforms[platform] = {
		StartPosition = startPos,
		EndPosition = endPos,
		Speed = speed,
		Duration = duration,
		CurrentTween = nil,
	}

	-- Start animation
	MovingPlatformService.AnimatePlatform(platform, true) -- Start moving to end position

	return true
end

-- ============================================================================
-- ANIMATION
-- ============================================================================

function MovingPlatformService.AnimatePlatform(platform: BasePart, moveToEnd: boolean)
	--[[
		Animates a platform from start to end (or end to start).
		Creates ping-pong looping animation.
	--]]

	local data = ActivePlatforms[platform]
	if not data then
		warn("[MovingPlatformService] Platform not initialized:", platform:GetFullName())
		return
	end

	-- Determine target position
	local targetPos = moveToEnd and data.EndPosition or data.StartPosition

	-- Create tween info
	local tweenInfo = TweenInfo.new(
		data.Duration,
		EASING_STYLE,
		EASING_DIRECTION,
		0, -- RepeatCount (0 = don't repeat, we'll handle it manually)
		false, -- Reverses (false, we manually reverse)
		0 -- DelayTime
	)

	-- Create tween
	local tween = TweenService:Create(platform, tweenInfo, {
		Position = targetPos
	})

	-- Store current tween
	data.CurrentTween = tween

	-- Play tween
	tween:Play()

	-- When tween completes, reverse direction
	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			-- Only reverse if platform still exists and is active
			if platform.Parent and ActivePlatforms[platform] then
				-- Reverse direction
				MovingPlatformService.AnimatePlatform(platform, not moveToEnd)
			end
		end
	end)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function MovingPlatformService.CleanupPlatform(platform: BasePart)
	--[[
		Stops and removes a moving platform from tracking.
	--]]

	local data = ActivePlatforms[platform]
	if not data then
		return
	end

	-- Cancel current tween
	if data.CurrentTween then
		data.CurrentTween:Cancel()
		data.CurrentTween = nil
	end

	-- Remove from tracking
	ActivePlatforms[platform] = nil
end

function MovingPlatformService.CleanupAll()
	--[[
		Stops all moving platforms.
	--]]

	local count = 0
	for platform, _ in pairs(ActivePlatforms) do
		MovingPlatformService.CleanupPlatform(platform)
		count = count + 1
	end

	print(string.format("[MovingPlatformService] Cleaned up %d moving platforms", count))
end

-- ============================================================================
-- PAUSE/RESUME (for round system)
-- ============================================================================

function MovingPlatformService.PauseAll()
	--[[
		Pauses all moving platform animations.
		Useful for intermission periods.
	--]]

	for platform, data in pairs(ActivePlatforms) do
		if data.CurrentTween then
			data.CurrentTween:Pause()
		end
	end

	print("[MovingPlatformService] All platforms paused")
end

function MovingPlatformService.ResumeAll()
	--[[
		Resumes all moving platform animations.
	--]]

	for platform, data in pairs(ActivePlatforms) do
		if data.CurrentTween then
			data.CurrentTween:Play()
		end
	end

	print("[MovingPlatformService] All platforms resumed")
end

-- ============================================================================
-- STATS
-- ============================================================================

function MovingPlatformService.GetActivePlatformCount(): number
	local count = 0
	for _, _ in pairs(ActivePlatforms) do
		count = count + 1
	end
	return count
end

function MovingPlatformService.DebugPrintStats()
	--[[
		Prints statistics about active moving platforms.
	--]]

	print("=== MOVING PLATFORM STATS ===")
	print(string.format("Active Platforms: %d", MovingPlatformService.GetActivePlatformCount()))

	for platform, data in pairs(ActivePlatforms) do
		print(string.format(
			"  - %s: Speed=%.1f, Distance=%.1f, Duration=%.1fs",
			platform.Name,
			data.Speed,
			(data.EndPosition - data.StartPosition).Magnitude,
			data.Duration
		))
	end

	print("=============================")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MovingPlatformService.Init(tower: Model?)
	print("[MovingPlatformService] Initializing...")

	if tower then
		-- Detect and initialize all moving platforms in tower
		MovingPlatformService.DetectPlatforms(tower)
	end

	-- Listen for tower regeneration
	-- (This will be called from RoundService when tower regenerates)

	print("[MovingPlatformService] Initialized")
end

function MovingPlatformService.OnNewTower(tower: Model)
	--[[
		Called when a new tower is generated.
		Cleans up old platforms and initializes new ones.
	--]]

	print("[MovingPlatformService] New tower detected, re-initializing...")

	-- Cleanup old platforms
	MovingPlatformService.CleanupAll()

	-- Detect new platforms
	MovingPlatformService.DetectPlatforms(tower)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return MovingPlatformService
