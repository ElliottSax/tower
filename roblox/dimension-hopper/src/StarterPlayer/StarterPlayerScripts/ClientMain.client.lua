--[[
	ClientMain.client.lua
	Main client controller for Dimension Hopper

	Handles:
	- Client-side service initialization
	- Remote event connections
	- Input handling
	- Camera management
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[ClientMain] RemoteEvents folder not found!")
	return
end

print("[ClientMain] Starting client...")

-- ============================================================================
-- CLIENT STATE
-- ============================================================================

local ClientState = {
	CurrentDimension = nil,
	GravityDirection = Vector3.new(0, -1, 0),
	PlayerScale = 1,
	IsGliding = false,
	BoostMeter = 100,
	RaceState = "Idle",
}

-- ============================================================================
-- GRAVITY HANDLING
-- ============================================================================

local function OnGravityFlip(data)
	if not data then return end

	local oldDirection = data.OldDirection
	local newDirection = data.NewDirection
	local duration = data.Duration or 0.3

	print(string.format("[ClientMain] Gravity flip: %s -> %s",
		tostring(oldDirection), tostring(newDirection)))

	ClientState.GravityDirection = newDirection

	-- Play flip animation/effect
	-- Camera roll effect during flip
	local character = player.Character
	if not character then return end

	-- Calculate rotation
	local upVector = -newDirection
	local defaultUp = Vector3.new(0, 1, 0)

	-- Screen shake during transition
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < duration do
			local shake = (math.random() - 0.5) * 0.02
			camera.CFrame = camera.CFrame * CFrame.Angles(shake, shake, 0)
			task.wait()
		end
	end)
end

local function OnGravitySync(direction)
	ClientState.GravityDirection = direction
end

-- Connect gravity remotes
if RemoteEvents:FindFirstChild("GravityFlip") then
	RemoteEvents.GravityFlip.OnClientEvent:Connect(OnGravityFlip)
end

if RemoteEvents:FindFirstChild("GravitySync") then
	RemoteEvents.GravitySync.OnClientEvent:Connect(OnGravitySync)
end

-- ============================================================================
-- SCALE HANDLING
-- ============================================================================

local function OnScaleChange(data)
	if not data then return end

	local oldScale = data.OldScale
	local newScale = data.NewScale
	local duration = data.Duration or 0.5

	print(string.format("[ClientMain] Scale: %.2fx -> %.2fx", oldScale, newScale))

	ClientState.PlayerScale = newScale

	-- Play shrink/grow effect
	-- Sound effect
	local shrinking = newScale < oldScale

	-- Visual particle burst
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Create temporary particles
			local particles = Instance.new("ParticleEmitter")
			particles.Color = ColorSequence.new(
				shrinking and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
			)
			particles.Size = NumberSequence.new(shrinking and 0.5 or 1)
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Rate = 50
			particles.Speed = NumberRange.new(5, 10)
			particles.SpreadAngle = Vector2.new(180, 180)
			particles.Parent = rootPart

			-- Remove after burst
			task.delay(0.5, function()
				particles.Enabled = false
				task.delay(1, function()
					particles:Destroy()
				end)
			end)
		end
	end
end

local function OnScaleSync(scale, cameraMultiplier)
	ClientState.PlayerScale = scale

	-- Adjust camera distance for tiny scales
	if cameraMultiplier and cameraMultiplier > 1 then
		-- Smoothly adjust camera zoom
		local player = Players.LocalPlayer
		if player then
			local playerScripts = player:FindFirstChild("PlayerScripts")
			if playerScripts then
				-- Adjust camera subject distance using properties
				local camera = workspace.CurrentCamera
				if camera then
					-- Calculate new camera offset based on scale
					local baseDistance = 15 -- Default camera distance
					local targetDistance = baseDistance * cameraMultiplier

					-- Tween the camera FieldOfView for zoom effect
					local targetFOV = math.clamp(70 / cameraMultiplier, 40, 120)
					TweenService:Create(camera, TweenInfo.new(0.5), {
						FieldOfView = targetFOV
					}):Play()
				end
			end
		end
	else
		-- Reset camera FOV when back to normal scale
		local camera = workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.5), {
				FieldOfView = 70
			}):Play()
		end
	end
end

-- Connect scale remotes
if RemoteEvents:FindFirstChild("ScaleChange") then
	RemoteEvents.ScaleChange.OnClientEvent:Connect(OnScaleChange)
end

if RemoteEvents:FindFirstChild("ScaleSync") then
	RemoteEvents.ScaleSync.OnClientEvent:Connect(OnScaleSync)
end

-- ============================================================================
-- VOID HANDLING
-- ============================================================================

local VoidWarningGui = nil

local function OnVoidUpdate(position, speed)
	-- Track void position for visual effects
	-- Could add screen edge glow when void is near
end

local function OnVoidWarning(warningType, intensity)
	if warningType == "NEAR" then
		-- Show proximity warning
		-- Red screen vignette based on intensity
		if not VoidWarningGui then
			VoidWarningGui = Instance.new("ScreenGui")
			VoidWarningGui.Name = "VoidWarning"
			VoidWarningGui.Parent = player.PlayerGui

			local frame = Instance.new("Frame")
			frame.Name = "Vignette"
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			frame.BackgroundTransparency = 1
			frame.BorderSizePixel = 0
			frame.Parent = VoidWarningGui

			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new(Color3.new(1, 0, 0))
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.3, 1),
				NumberSequenceKeypoint.new(0.7, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			gradient.Parent = frame
		end

		local frame = VoidWarningGui:FindFirstChild("Vignette")
		if frame then
			frame.BackgroundTransparency = 1 - (intensity * 0.5)
		end

	elseif warningType == "CAUGHT" then
		-- Death by void - dramatic effect
		if VoidWarningGui then
			local frame = VoidWarningGui:FindFirstChild("Vignette")
			if frame then
				TweenService:Create(frame, TweenInfo.new(0.5), {
					BackgroundTransparency = 0
				}):Play()
			end
		end
	end
end

-- Connect void remotes
if RemoteEvents:FindFirstChild("VoidUpdate") then
	RemoteEvents.VoidUpdate.OnClientEvent:Connect(OnVoidUpdate)
end

if RemoteEvents:FindFirstChild("VoidWarning") then
	RemoteEvents.VoidWarning.OnClientEvent:Connect(OnVoidWarning)
end

-- ============================================================================
-- GLIDER HANDLING
-- ============================================================================

local GliderModel = nil
local GliderTrail = nil

local function OnGliderState(data)
	if not data then return end

	if data.State == "Deploy" then
		ClientState.IsGliding = true
		ClientState.BoostMeter = data.BoostMeter or 100

		-- Create/show glider visual
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				-- Simple glider visual (wings)
				if not GliderModel then
					GliderModel = Instance.new("Part")
					GliderModel.Name = "GliderWings"
					GliderModel.Size = Vector3.new(8, 0.2, 4)
					GliderModel.Color = Color3.fromRGB(100, 150, 255)
					GliderModel.Material = Enum.Material.SmoothPlastic
					GliderModel.Transparency = 0.3
					GliderModel.CanCollide = false
					GliderModel.Massless = true

					local weld = Instance.new("Weld")
					weld.Part0 = rootPart
					weld.Part1 = GliderModel
					weld.C0 = CFrame.new(0, 1, 1)
					weld.Parent = GliderModel

					GliderModel.Parent = character
				end

				GliderModel.Transparency = 0.3

				-- Add trail
				if not GliderTrail then
					GliderTrail = Instance.new("Trail")
					GliderTrail.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
					GliderTrail.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.3),
						NumberSequenceKeypoint.new(1, 1),
					})
					GliderTrail.Lifetime = 1
					GliderTrail.WidthScale = NumberSequence.new(1)

					local att1 = Instance.new("Attachment")
					att1.Position = Vector3.new(-4, 0, 0)
					att1.Parent = GliderModel

					local att2 = Instance.new("Attachment")
					att2.Position = Vector3.new(4, 0, 0)
					att2.Parent = GliderModel

					GliderTrail.Attachment0 = att1
					GliderTrail.Attachment1 = att2
					GliderTrail.Parent = GliderModel
				end
			end
		end

	elseif data.State == "Retract" then
		ClientState.IsGliding = false

		-- Hide glider
		if GliderModel then
			GliderModel.Transparency = 1
		end
	end
end

local function OnBoostMeterUpdate(amount)
	ClientState.BoostMeter = amount
	-- Update UI
end

local function OnWindEffect(windDirection, strength)
	-- Visual wind effect (particles)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create wind particles
	local windParticles = Instance.new("ParticleEmitter")
	windParticles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	windParticles.Size = NumberSequence.new(0.1, 0.3)
	windParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	windParticles.Lifetime = NumberRange.new(0.3, 0.5)
	windParticles.Rate = 30
	windParticles.Speed = NumberRange.new(20, 30)

	-- Emit in wind direction
	local emitDir = (windDirection or Vector3.new(0, 1, 0)).Unit
	windParticles.EmissionDirection = Enum.NormalId.Front
	windParticles.Parent = rootPart

	-- Brief burst
	task.delay(0.5, function()
		windParticles:Destroy()
	end)
end

-- Connect glider remotes
if RemoteEvents:FindFirstChild("GliderState") then
	RemoteEvents.GliderState.OnClientEvent:Connect(OnGliderState)
end

if RemoteEvents:FindFirstChild("BoostMeterUpdate") then
	RemoteEvents.BoostMeterUpdate.OnClientEvent:Connect(OnBoostMeterUpdate)
end

if RemoteEvents:FindFirstChild("WindEffect") then
	RemoteEvents.WindEffect.OnClientEvent:Connect(OnWindEffect)
end

-- ============================================================================
-- PLATFORM CRUMBLING
-- ============================================================================

local function OnPlatformCrumble(platform, state, delay)
	if not platform then return end

	if state == "WARNING" then
		-- Flash warning effect
		task.spawn(function()
			local originalColor = platform.Color
			local warningTime = delay or 2.5
			local startTime = tick()

			while tick() - startTime < warningTime and platform.Parent do
				local flash = math.sin((tick() - startTime) * 15) > 0
				platform.Color = flash and Color3.fromRGB(255, 100, 100) or originalColor
				task.wait()
			end
		end)

	elseif state == "CRUMBLE" then
		-- Crumbling particles
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(platform.Color)
		particles.Size = NumberSequence.new(0.3, 0.1)
		particles.Transparency = NumberSequence.new(0, 1)
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Rate = 50
		particles.Speed = NumberRange.new(5, 15)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = platform

		task.delay(0.5, function()
			particles.Enabled = false
			task.delay(1, function()
				if particles.Parent then
					particles:Destroy()
				end
			end)
		end)

	elseif state == "DESTROYED" then
		-- Final destruction effect (already handled server-side)
	end
end

-- Connect platform remotes
if RemoteEvents:FindFirstChild("PlatformCrumble") then
	RemoteEvents.PlatformCrumble.OnClientEvent:Connect(OnPlatformCrumble)
end

-- ============================================================================
-- RACE UI
-- ============================================================================

local RaceUIGui = nil

local function CreateRaceUI()
	if RaceUIGui then return end

	RaceUIGui = Instance.new("ScreenGui")
	RaceUIGui.Name = "RaceUI"
	RaceUIGui.ResetOnSpawn = false
	RaceUIGui.Parent = player.PlayerGui

	-- State label (top center)
	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "StateLabel"
	stateLabel.AnchorPoint = Vector2.new(0.5, 0)
	stateLabel.Position = UDim2.new(0.5, 0, 0.05, 0)
	stateLabel.Size = UDim2.new(0.3, 0, 0.05, 0)
	stateLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	stateLabel.BackgroundTransparency = 0.5
	stateLabel.Font = Enum.Font.GothamBold
	stateLabel.TextSize = 20
	stateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stateLabel.Text = ""
	stateLabel.Parent = RaceUIGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = stateLabel

	-- Countdown label (center)
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	countdownLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
	countdownLabel.Size = UDim2.new(0.2, 0, 0.15, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.TextSize = 72
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	countdownLabel.TextStrokeTransparency = 0.5
	countdownLabel.Text = ""
	countdownLabel.Visible = false
	countdownLabel.Parent = RaceUIGui

	-- Results frame (center)
	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "ResultsFrame"
	resultsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultsFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	resultsFrame.BackgroundTransparency = 0.2
	resultsFrame.Visible = false
	resultsFrame.Parent = RaceUIGui

	local resultsCorner = Instance.new("UICorner")
	resultsCorner.CornerRadius = UDim.new(0, 12)
	resultsCorner.Parent = resultsFrame

	local resultsTitle = Instance.new("TextLabel")
	resultsTitle.Name = "Title"
	resultsTitle.Position = UDim2.new(0, 0, 0, 0)
	resultsTitle.Size = UDim2.new(1, 0, 0.15, 0)
	resultsTitle.BackgroundTransparency = 1
	resultsTitle.Font = Enum.Font.GothamBold
	resultsTitle.TextSize = 28
	resultsTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	resultsTitle.Text = "🏆 RACE RESULTS 🏆"
	resultsTitle.Parent = resultsFrame

	local resultsList = Instance.new("ScrollingFrame")
	resultsList.Name = "ResultsList"
	resultsList.Position = UDim2.new(0.05, 0, 0.18, 0)
	resultsList.Size = UDim2.new(0.9, 0, 0.75, 0)
	resultsList.BackgroundTransparency = 1
	resultsList.ScrollBarThickness = 4
	resultsList.Parent = resultsFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = resultsList
end

local function OnRaceState(state, data)
	ClientState.RaceState = state
	print(string.format("[ClientMain] Race state: %s", state))

	CreateRaceUI()
	if not RaceUIGui then return end

	local stateLabel = RaceUIGui:FindFirstChild("StateLabel")
	local resultsFrame = RaceUIGui:FindFirstChild("ResultsFrame")

	if stateLabel then
		if state == "Lobby" then
			stateLabel.Text = "⏳ Waiting for players..."
			stateLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		elseif state == "Countdown" then
			stateLabel.Text = "🏁 Get Ready!"
			stateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		elseif state == "Racing" then
			stateLabel.Text = "🏃 RACE IN PROGRESS"
			stateLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		elseif state == "Results" then
			stateLabel.Text = "🏆 Race Complete!"
			stateLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		else
			stateLabel.Text = ""
		end
	end

	-- Hide results when not in results state
	if resultsFrame and state ~= "Results" then
		resultsFrame.Visible = false
	end
end

local function OnRaceCountdown(count)
	print(string.format("[ClientMain] Countdown: %d", count))

	CreateRaceUI()
	if not RaceUIGui then return end

	local countdownLabel = RaceUIGui:FindFirstChild("CountdownLabel")
	if not countdownLabel then return end

	countdownLabel.Visible = true

	if count > 0 then
		countdownLabel.Text = tostring(count)
		countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

		-- Scale animation
		countdownLabel.Size = UDim2.new(0.3, 0, 0.2, 0)
		TweenService:Create(countdownLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
			Size = UDim2.new(0.2, 0, 0.15, 0)
		}):Play()
	else
		countdownLabel.Text = "GO!"
		countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Flash and hide
		task.delay(1, function()
			countdownLabel.Visible = false
		end)
	end
end

local function OnRacePositions(positions)
	-- Update leaderboard/position display
	-- positions = array of {UserId, Name, Section, Placement}
end

local function OnRaceResults(results)
	print("[ClientMain] Race results received")

	CreateRaceUI()
	if not RaceUIGui then return end

	local resultsFrame = RaceUIGui:FindFirstChild("ResultsFrame")
	if not resultsFrame then return end

	local resultsList = resultsFrame:FindFirstChild("ResultsList")
	if not resultsList then return end

	-- Clear old results
	for _, child in ipairs(resultsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add new results
	for i, result in ipairs(results) do
		local entry = Instance.new("Frame")
		entry.Name = "Result_" .. i
		entry.Size = UDim2.new(1, 0, 0, 35)
		entry.BackgroundColor3 = i <= 3 and Color3.fromRGB(60, 60, 70) or Color3.fromRGB(40, 40, 50)
		entry.BackgroundTransparency = 0.3
		entry.LayoutOrder = i
		entry.Parent = resultsList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 6)
		entryCorner.Parent = entry

		-- Placement
		local placeLabel = Instance.new("TextLabel")
		placeLabel.Size = UDim2.new(0.15, 0, 1, 0)
		placeLabel.BackgroundTransparency = 1
		placeLabel.Font = Enum.Font.GothamBold
		placeLabel.TextSize = 18
		placeLabel.Text = i == 1 and "🥇" or i == 2 and "🥈" or i == 3 and "🥉" or "#" .. i
		placeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		placeLabel.Parent = entry

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = result.Name or "Unknown"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Parent = entry

		-- Time
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Position = UDim2.new(0.7, 0, 0, 0)
		timeLabel.Size = UDim2.new(0.3, 0, 1, 0)
		timeLabel.BackgroundTransparency = 1
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.TextSize = 14
		timeLabel.Text = result.Time and string.format("%.2fs", result.Time) or "DNF"
		timeLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		timeLabel.Parent = entry
	end

	-- Update canvas size
	resultsList.CanvasSize = UDim2.new(0, 0, 0, #results * 40)

	-- Show results
	resultsFrame.Visible = true
	resultsFrame.BackgroundTransparency = 1
	TweenService:Create(resultsFrame, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.2
	}):Play()

	-- Auto-hide after 10 seconds
	task.delay(10, function()
		if resultsFrame and resultsFrame.Visible then
			TweenService:Create(resultsFrame, TweenInfo.new(0.3), {
				BackgroundTransparency = 1
			}):Play()
			task.delay(0.3, function()
				resultsFrame.Visible = false
			end)
		end
	end)
end

local function OnPlayerFinished(data)
	print(string.format("[ClientMain] %s finished in position %d!",
		data.FinisherName, data.Placement))
end

-- Connect race remotes
if RemoteEvents:FindFirstChild("RaceState") then
	RemoteEvents.RaceState.OnClientEvent:Connect(OnRaceState)
end

if RemoteEvents:FindFirstChild("RaceCountdown") then
	RemoteEvents.RaceCountdown.OnClientEvent:Connect(OnRaceCountdown)
end

if RemoteEvents:FindFirstChild("RacePositions") then
	RemoteEvents.RacePositions.OnClientEvent:Connect(OnRacePositions)
end

if RemoteEvents:FindFirstChild("RaceResults") then
	RemoteEvents.RaceResults.OnClientEvent:Connect(OnRaceResults)
end

if RemoteEvents:FindFirstChild("PlayerFinished") then
	RemoteEvents.PlayerFinished.OnClientEvent:Connect(OnPlayerFinished)
end

-- ============================================================================
-- CHECKPOINT
-- ============================================================================

local function OnCheckpointReached(data)
	print(string.format("[ClientMain] Checkpoint reached: Section %d", data.Section))

	-- Flash green effect
	local gui = Instance.new("ScreenGui")
	gui.Name = "CheckpointFlash"
	gui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	frame.BackgroundTransparency = 0.7
	frame.BorderSizePixel = 0
	frame.Parent = gui

	TweenService:Create(frame, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	}):Play()

	task.delay(0.6, function()
		gui:Destroy()
	end)
end

if RemoteEvents:FindFirstChild("CheckpointReached") then
	RemoteEvents.CheckpointReached.OnClientEvent:Connect(OnCheckpointReached)
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

-- Glider deployment (hold space while in air)
local holdingJump = false
local jumpHoldStart = 0

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space then
		holdingJump = true
		jumpHoldStart = tick()
	end

	-- Boost (Shift while gliding)
	if input.KeyCode == Enum.KeyCode.LeftShift and ClientState.IsGliding then
		if RemoteEvents:FindFirstChild("GliderBoost") then
			RemoteEvents.GliderBoost:FireServer(true)
		end
	end

	-- Respawn (R key)
	if input.KeyCode == Enum.KeyCode.R then
		if RemoteEvents:FindFirstChild("RequestRespawn") then
			RemoteEvents.RequestRespawn:FireServer()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space then
		holdingJump = false
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if RemoteEvents:FindFirstChild("GliderBoost") then
			RemoteEvents.GliderBoost:FireServer(false)
		end
	end
end)

-- Check for glider deployment (hold jump in air)
RunService.Heartbeat:Connect(function()
	if not holdingJump then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if in air and holding jump long enough
	local inAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local holdDuration = tick() - jumpHoldStart

	if inAir and holdDuration > 0.3 and not ClientState.IsGliding then
		-- Request glider deploy
		if RemoteEvents:FindFirstChild("DeployGlider") then
			RemoteEvents.DeployGlider:FireServer()
		end
	end
end)

-- ============================================================================
-- DIMENSION THEME APPLICATION
-- ============================================================================

local function OnDimensionChange(dimensionName, themeData)
	ClientState.CurrentDimension = dimensionName
	print(string.format("[ClientMain] Dimension changed to: %s", dimensionName))

	-- Apply client-side theme effects
	-- (Lighting is handled server-side, but we can add client particles, etc.)
end

if RemoteEvents:FindFirstChild("DimensionChange") then
	RemoteEvents.DimensionChange.OnClientEvent:Connect(OnDimensionChange)
end

-- ============================================================================
-- COMPLETE
-- ============================================================================

print("[ClientMain] Client initialized successfully")
