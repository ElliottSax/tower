--[[
	SpectatorUI.client.lua
	Client UI for spectator mode

	Features:
	- Shows current spectate target
	- Previous/Next player buttons
	- Target player info (name, section, placement)
	- Camera control instructions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[SpectatorUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local isSpectating = false
local spectatorData = nil
local cameraConnection = nil

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectatorUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main frame (bottom center)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 1)
mainFrame.Position = UDim2.new(0.5, 0, 1, -20)
mainFrame.Size = UDim2.new(0, 400, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.3
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 150)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Spectating label
local spectatingLabel = Instance.new("TextLabel")
spectatingLabel.Name = "SpectatingLabel"
spectatingLabel.Position = UDim2.new(0, 10, 0, 5)
spectatingLabel.Size = UDim2.new(1, -20, 0, 20)
spectatingLabel.BackgroundTransparency = 1
spectatingLabel.Font = Enum.Font.Gotham
spectatingLabel.TextSize = 14
spectatingLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
spectatingLabel.Text = "👁️ SPECTATING"
spectatingLabel.Parent = mainFrame

-- Target name
local targetNameLabel = Instance.new("TextLabel")
targetNameLabel.Name = "TargetName"
targetNameLabel.Position = UDim2.new(0, 10, 0, 25)
targetNameLabel.Size = UDim2.new(1, -20, 0, 35)
targetNameLabel.BackgroundTransparency = 1
targetNameLabel.Font = Enum.Font.GothamBold
targetNameLabel.TextSize = 28
targetNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetNameLabel.Text = "Player Name"
targetNameLabel.Parent = mainFrame

-- Controls hint
local controlsLabel = Instance.new("TextLabel")
controlsLabel.Name = "ControlsLabel"
controlsLabel.Position = UDim2.new(0, 10, 0, 65)
controlsLabel.Size = UDim2.new(1, -20, 0, 25)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextSize = 12
controlsLabel.TextColor3 = Color3.fromRGB(100, 100, 150)
controlsLabel.Text = "[Q] Previous  |  [E] Next  |  [ESC] Exit Spectator"
controlsLabel.Parent = mainFrame

-- Previous button
local prevButton = Instance.new("TextButton")
prevButton.Name = "PrevButton"
prevButton.Position = UDim2.new(0, 10, 0.5, -20)
prevButton.Size = UDim2.new(0, 50, 0, 40)
prevButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
prevButton.Font = Enum.Font.GothamBold
prevButton.TextSize = 20
prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
prevButton.Text = "◀"
prevButton.Parent = mainFrame

local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0, 8)
prevCorner.Parent = prevButton

-- Next button
local nextButton = Instance.new("TextButton")
nextButton.Name = "NextButton"
nextButton.AnchorPoint = Vector2.new(1, 0)
nextButton.Position = UDim2.new(1, -10, 0.5, -20)
nextButton.Size = UDim2.new(0, 50, 0, 40)
nextButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
nextButton.Font = Enum.Font.GothamBold
nextButton.TextSize = 20
nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextButton.Text = "▶"
nextButton.Parent = mainFrame

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 8)
nextCorner.Parent = nextButton

-- Exit button (top right)
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.AnchorPoint = Vector2.new(1, 0)
exitButton.Position = UDim2.new(1, -20, 0, 20)
exitButton.Size = UDim2.new(0, 120, 0, 40)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
exitButton.Font = Enum.Font.GothamBold
exitButton.TextSize = 16
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.Text = "Exit Spectator"
exitButton.Parent = screenGui

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 8)
exitCorner.Parent = exitButton

-- ============================================================================
-- CAMERA HANDLING
-- ============================================================================

local function UpdateCamera()
	if not isSpectating or not spectatorData then return end

	local targetPlayer = Players:GetPlayerByUserId(spectatorData.TargetUserId)
	if not targetPlayer then return end

	local character = targetPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Follow camera behind the target
	local offset = Vector3.new(0, 8, 15)
	local lookAt = rootPart.Position + Vector3.new(0, 2, 0)
	local cameraPos = rootPart.Position + (rootPart.CFrame.LookVector * -offset.Z) + Vector3.new(0, offset.Y, 0)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = camera.CFrame:Lerp(
		CFrame.new(cameraPos, lookAt),
		0.1
	)
end

local function StartCameraFollow()
	if cameraConnection then
		cameraConnection:Disconnect()
	end

	cameraConnection = RunService.RenderStepped:Connect(UpdateCamera)
end

local function StopCameraFollow()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	camera.CameraType = Enum.CameraType.Custom
end

-- ============================================================================
-- UI UPDATES
-- ============================================================================

local function UpdateUI()
	if not spectatorData then
		screenGui.Enabled = false
		return
	end

	screenGui.Enabled = true

	targetNameLabel.Text = spectatorData.TargetName or "Unknown"

	-- Update racer count in label
	spectatingLabel.Text = string.format("👁️ SPECTATING (%d/%d)",
		1, spectatorData.TotalRacers or 1)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function OnSpectatorSync(data)
	spectatorData = data

	if data then
		isSpectating = true
		UpdateUI()
		StartCameraFollow()
	else
		isSpectating = false
		screenGui.Enabled = false
		StopCameraFollow()
	end
end

-- Connect remote
if RemoteEvents:FindFirstChild("SpectatorSync") then
	RemoteEvents.SpectatorSync.OnClientEvent:Connect(OnSpectatorSync)
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isSpectating then return end

	-- Previous target (Q)
	if input.KeyCode == Enum.KeyCode.Q then
		if RemoteEvents:FindFirstChild("CycleSpectateTarget") then
			RemoteEvents.CycleSpectateTarget:FireServer(-1)
		end
	end

	-- Next target (E)
	if input.KeyCode == Enum.KeyCode.E then
		if RemoteEvents:FindFirstChild("CycleSpectateTarget") then
			RemoteEvents.CycleSpectateTarget:FireServer(1)
		end
	end

	-- Exit (Escape)
	if input.KeyCode == Enum.KeyCode.Escape then
		if RemoteEvents:FindFirstChild("ExitSpectatorMode") then
			RemoteEvents.ExitSpectatorMode:FireServer()
		end
	end
end)

-- Button handlers
prevButton.MouseButton1Click:Connect(function()
	if RemoteEvents:FindFirstChild("CycleSpectateTarget") then
		RemoteEvents.CycleSpectateTarget:FireServer(-1)
	end
end)

nextButton.MouseButton1Click:Connect(function()
	if RemoteEvents:FindFirstChild("CycleSpectateTarget") then
		RemoteEvents.CycleSpectateTarget:FireServer(1)
	end
end)

exitButton.MouseButton1Click:Connect(function()
	if RemoteEvents:FindFirstChild("ExitSpectatorMode") then
		RemoteEvents.ExitSpectatorMode:FireServer()
	end
end)

-- Button hover effects
for _, button in ipairs({prevButton, nextButton, exitButton}) do
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		local targetColor = button.Name == "ExitButton"
			and Color3.fromRGB(200, 60, 60)
			or Color3.fromRGB(60, 60, 80)

		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = targetColor
		}):Play()
	end)
end

print("[SpectatorUI] Initialized")
