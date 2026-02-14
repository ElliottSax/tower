--[[
	ScaleService.lua
	Handles player scaling for the Tiny Dimension

	Features:
	- Scale zones that shrink/grow players
	- Multiple scale levels (1x, 0.5x, 0.25x, 0.1x, 0.05x)
	- Smooth scaling transitions
	- Camera distance adjustments
	- Physics adjustments for tiny players

	How it works:
	1. Player touches ScaleZone
	2. Server calculates new scale based on zone type
	3. Player smoothly transitions to new size
	4. Jump power and speed adjusted accordingly
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ScaleService = {}

-- ============================================================================
-- STATE
-- ============================================================================

-- Track each player's scale state
-- [UserId] = { scale = number, isScaling = bool, lastScaleTime = number }
ScaleService.PlayerScale = {}

-- Scale levels available
ScaleService.ScaleLevels = {1, 0.5, 0.25, 0.1, 0.05}

-- Configuration
local CONFIG = {
	ScaleCooldown = 0.3, -- Seconds between scale changes
	ScaleTransitionTime = 0.5, -- Seconds for scale animation
	MinScale = 0.05,
	MaxScale = 1,

	-- Physics adjustments per scale
	JumpPowerMultiplier = 1.2, -- Smaller = slightly higher relative jump
	WalkSpeedMultiplier = 0.9, -- Smaller = slightly slower

	-- Camera
	CameraDistanceMultiplier = 1.5, -- Zoom out when tiny to see more
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ScaleService.Init()
	print("[ScaleService] Initializing...")

	-- Create remotes
	ScaleService.CreateRemotes()

	-- Setup player tracking
	Players.PlayerAdded:Connect(function(player)
		ScaleService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ScaleService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		ScaleService.OnPlayerJoin(player)
	end

	-- Setup scale zone detection
	ScaleService.SetupScaleZones()

	print("[ScaleService] Initialized")
end

function ScaleService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Scale change event (server -> client)
	if not remoteFolder:FindFirstChild("ScaleChange") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ScaleChange"
		event.Parent = remoteFolder
	end

	-- Scale sync for camera adjustments
	if not remoteFolder:FindFirstChild("ScaleSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ScaleSync"
		event.Parent = remoteFolder
	end

	ScaleService.Remotes = {
		ScaleChange = remoteFolder.ScaleChange,
		ScaleSync = remoteFolder.ScaleSync,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function ScaleService.OnPlayerJoin(player: Player)
	ScaleService.PlayerScale[player.UserId] = {
		scale = 1,
		targetScale = 1,
		isScaling = false,
		lastScaleTime = 0,
	}

	-- Setup character scaling when spawned
	player.CharacterAdded:Connect(function(character)
		ScaleService.OnCharacterAdded(player, character)
	end)

	if player.Character then
		ScaleService.OnCharacterAdded(player, player.Character)
	end
end

function ScaleService.OnPlayerLeave(player: Player)
	ScaleService.PlayerScale[player.UserId] = nil
end

function ScaleService.OnCharacterAdded(player: Player, character: Model)
	-- Reset scale when character spawns
	ScaleService.ResetScale(player)

	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Apply current scale state
	local scaleState = ScaleService.PlayerScale[player.UserId]
	if scaleState then
		ScaleService.ApplyScaleToCharacter(character, scaleState.scale, true) -- Instant on spawn
	end
end

-- ============================================================================
-- SCALE ZONES
-- ============================================================================

function ScaleService.SetupScaleZones()
	-- Connect to existing scale zones
	for _, zone in ipairs(CollectionService:GetTagged("ScaleZone")) do
		ScaleService.ConnectScaleZone(zone)
	end

	-- Listen for new scale zones
	CollectionService:GetInstanceAddedSignal("ScaleZone"):Connect(function(zone)
		ScaleService.ConnectScaleZone(zone)
	end)
end

function ScaleService.ConnectScaleZone(zone: BasePart)
	zone.Touched:Connect(function(hit)
		ScaleService.OnScaleZoneTouched(zone, hit)
	end)
end

function ScaleService.OnScaleZoneTouched(zone: BasePart, hit: BasePart)
	-- Verify it's a player
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check cooldown
	local scaleState = ScaleService.PlayerScale[player.UserId]
	if not scaleState then return end

	local now = tick()
	if scaleState.isScaling or (now - scaleState.lastScaleTime) < CONFIG.ScaleCooldown then
		return
	end

	-- Get target scale from zone
	local targetScale = zone:GetAttribute("TargetScale")
	local scaleMode = zone:GetAttribute("ScaleMode") or "Set" -- "Set", "Shrink", "Grow"

	if scaleMode == "Shrink" then
		-- Go to next smaller scale level
		targetScale = ScaleService.GetNextSmallerScale(scaleState.scale)
	elseif scaleMode == "Grow" then
		-- Go to next larger scale level
		targetScale = ScaleService.GetNextLargerScale(scaleState.scale)
	elseif not targetScale then
		-- Default to shrink by half
		targetScale = scaleState.scale * 0.5
	end

	-- Clamp scale
	targetScale = math.clamp(targetScale, CONFIG.MinScale, CONFIG.MaxScale)

	-- Skip if already at target scale
	if math.abs(scaleState.scale - targetScale) < 0.01 then return end

	-- Execute scale change
	ScaleService.SetScale(player, targetScale)
end

-- ============================================================================
-- SCALE MANIPULATION
-- ============================================================================

function ScaleService.SetScale(player: Player, targetScale: number)
	local scaleState = ScaleService.PlayerScale[player.UserId]
	if not scaleState then return end

	local character = player.Character
	if not character then return end

	-- Mark as scaling
	scaleState.isScaling = true
	scaleState.lastScaleTime = tick()
	scaleState.targetScale = targetScale

	local oldScale = scaleState.scale

	-- Notify client for visual/sound effects
	ScaleService.Remotes.ScaleChange:FireClient(player, {
		OldScale = oldScale,
		NewScale = targetScale,
		Duration = CONFIG.ScaleTransitionTime,
	})

	-- Animate scale transition
	ScaleService.AnimateScale(character, oldScale, targetScale, function()
		-- Update state after animation
		scaleState.scale = targetScale
		scaleState.isScaling = false

		-- Sync camera settings
		ScaleService.Remotes.ScaleSync:FireClient(player, targetScale, CONFIG.CameraDistanceMultiplier)
	end)

	print(string.format("[ScaleService] %s scaled from %.2fx to %.2fx",
		player.Name, oldScale, targetScale))
end

function ScaleService.AnimateScale(character: Model, fromScale: number, toScale: number, onComplete: () -> ())
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		if onComplete then onComplete() end
		return
	end

	-- Get humanoid description for scaling
	local description = humanoid:GetAppliedDescription()
	if not description then
		-- Fallback: just apply instantly
		ScaleService.ApplyScaleToCharacter(character, toScale, true)
		if onComplete then onComplete() end
		return
	end

	-- Tween the scale values
	local startTime = tick()
	local duration = CONFIG.ScaleTransitionTime

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.clamp(elapsed / duration, 0, 1)

		-- Ease out cubic for smooth feel
		local easedProgress = 1 - math.pow(1 - progress, 3)

		-- Interpolate scale
		local currentScale = fromScale + (toScale - fromScale) * easedProgress

		-- Apply scale
		ScaleService.ApplyScaleToCharacter(character, currentScale, true)

		if progress >= 1 then
			connection:Disconnect()
			if onComplete then onComplete() end
		end
	end)
end

function ScaleService.ApplyScaleToCharacter(character: Model, scale: number, instant: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Scale using Humanoid Description
	local description = humanoid:GetAppliedDescription()
	if description then
		-- Apply uniform scale
		description.BodyTypeScale = 0 -- Use standard body
		description.DepthScale = scale
		description.HeadScale = scale
		description.HeightScale = scale
		description.ProportionScale = 0
		description.WidthScale = scale

		-- Apply description (this actually scales the character)
		humanoid:ApplyDescription(description)
	end

	-- Adjust physics for scale
	local baseWalkSpeed = GameConfig.Player.BaseWalkSpeed or 16
	local baseJumpPower = GameConfig.Player.BaseJumpPower or 50

	-- Smaller = relatively slower but higher jump feel
	local speedMultiplier = math.pow(scale, 0.3) * CONFIG.WalkSpeedMultiplier
	local jumpMultiplier = math.pow(scale, 0.5) * CONFIG.JumpPowerMultiplier

	humanoid.WalkSpeed = baseWalkSpeed * speedMultiplier
	humanoid.JumpPower = baseJumpPower * jumpMultiplier

	-- Store scale on character for other systems to read
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart:SetAttribute("PlayerScale", scale)
	end
end

-- ============================================================================
-- SCALE LEVEL HELPERS
-- ============================================================================

function ScaleService.GetNextSmallerScale(currentScale: number): number
	-- Find next smaller scale level
	for i = #ScaleService.ScaleLevels, 1, -1 do
		local level = ScaleService.ScaleLevels[i]
		if level < currentScale - 0.01 then
			return level
		end
	end
	return ScaleService.ScaleLevels[#ScaleService.ScaleLevels] -- Smallest
end

function ScaleService.GetNextLargerScale(currentScale: number): number
	-- Find next larger scale level
	for i = 1, #ScaleService.ScaleLevels do
		local level = ScaleService.ScaleLevels[i]
		if level > currentScale + 0.01 then
			return level
		end
	end
	return ScaleService.ScaleLevels[1] -- Largest (1x)
end

function ScaleService.GetScaleLevelIndex(scale: number): number
	-- Find which scale level index this scale is closest to
	local closestIndex = 1
	local closestDiff = math.huge

	for i, level in ipairs(ScaleService.ScaleLevels) do
		local diff = math.abs(level - scale)
		if diff < closestDiff then
			closestDiff = diff
			closestIndex = i
		end
	end

	return closestIndex
end

-- ============================================================================
-- RESET & UTILITIES
-- ============================================================================

function ScaleService.ResetScale(player: Player)
	local scaleState = ScaleService.PlayerScale[player.UserId]
	if scaleState then
		scaleState.scale = 1
		scaleState.targetScale = 1
		scaleState.isScaling = false
	end

	if player.Character then
		ScaleService.ApplyScaleToCharacter(player.Character, 1, true)
	end

	-- Notify client
	ScaleService.Remotes.ScaleSync:FireClient(player, 1, 1)
end

function ScaleService.GetPlayerScale(player: Player): number
	local scaleState = ScaleService.PlayerScale[player.UserId]
	return scaleState and scaleState.scale or 1
end

function ScaleService.IsPlayerScaling(player: Player): boolean
	local scaleState = ScaleService.PlayerScale[player.UserId]
	return scaleState and scaleState.isScaling or false
end

-- ============================================================================
-- SPECIAL SCALE FEATURES
-- ============================================================================

-- Giant objects that only tiny players can pass through
function ScaleService.CanPassThrough(player: Player, object: BasePart): boolean
	local requiredScale = object:GetAttribute("MaxScaleToPass")
	if not requiredScale then return true end

	local playerScale = ScaleService.GetPlayerScale(player)
	return playerScale <= requiredScale
end

-- Tiny tunnels/passages
function ScaleService.SetupTinyPassages()
	for _, passage in ipairs(CollectionService:GetTagged("TinyPassage")) do
		-- These are passages only small players can fit through
		-- The passage has a trigger zone that checks scale
		local trigger = passage:FindFirstChild("Trigger")
		if trigger then
			trigger.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then return end

				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				local requiredScale = passage:GetAttribute("RequiredScale") or 0.25
				local playerScale = ScaleService.GetPlayerScale(player)

				if playerScale > requiredScale then
					-- Player is too big - push them back or block
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						-- Apply knockback
						local rootPart = character:FindFirstChild("HumanoidRootPart")
						if rootPart then
							local knockback = -trigger.CFrame.LookVector * 20
							rootPart.AssemblyLinearVelocity = knockback
						end
					end
				end
			end)
		end
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function ScaleService.Cleanup()
	-- Reset all players to normal scale
	for _, player in ipairs(Players:GetPlayers()) do
		ScaleService.ResetScale(player)
	end

	print("[ScaleService] Cleaned up")
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function ScaleService.DebugPrint()
	print("=== SCALE SERVICE STATUS ===")

	for userId, state in pairs(ScaleService.PlayerScale) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Scale=%.2fx, Scaling=%s",
				player.Name,
				state.scale,
				tostring(state.isScaling)
			))
		end
	end

	print("============================")
end

return ScaleService
