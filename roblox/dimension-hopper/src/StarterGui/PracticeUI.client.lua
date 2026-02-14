--[[
	PracticeUI.client.lua
	Client UI for practice mode

	Features:
	- Dimension selection
	- Section selection
	- Restart/Next section buttons
	- Exit practice button
	- Controls hint
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[PracticeUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local isPracticing = false
local currentDimension = nil
local currentSection = 1

-- ============================================================================
-- DIMENSIONS CONFIG
-- ============================================================================

local DIMENSIONS = {
	{ name = "Gravity", color = Color3.fromRGB(150, 50, 255) },
	{ name = "Tiny", color = Color3.fromRGB(50, 200, 50) },
	{ name = "Void", color = Color3.fromRGB(100, 20, 20) },
	{ name = "Sky", color = Color3.fromRGB(135, 206, 235) },
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PracticeUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Start Practice Button (shows in main menu)
local startButton = Instance.new("TextButton")
startButton.Name = "StartPracticeButton"
startButton.AnchorPoint = Vector2.new(0, 1)
startButton.Position = UDim2.new(0, 20, 1, -20)
startButton.Size = UDim2.new(0, 150, 0, 50)
startButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 18
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.Text = "Practice Mode"
startButton.Parent = screenGui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

-- Dimension Selection Panel
local selectionPanel = Instance.new("Frame")
selectionPanel.Name = "SelectionPanel"
selectionPanel.AnchorPoint = Vector2.new(0.5, 0.5)
selectionPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
selectionPanel.Size = UDim2.new(0, 400, 0, 350)
selectionPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
selectionPanel.BackgroundTransparency = 0.1
selectionPanel.Visible = false
selectionPanel.Parent = screenGui

local selectionCorner = Instance.new("UICorner")
selectionCorner.CornerRadius = UDim.new(0, 12)
selectionCorner.Parent = selectionPanel

local selectionStroke = Instance.new("UIStroke")
selectionStroke.Color = Color3.fromRGB(100, 100, 150)
selectionStroke.Thickness = 2
selectionStroke.Parent = selectionPanel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Practice Mode"
titleLabel.Parent = selectionPanel

-- Dimension buttons container
local dimensionContainer = Instance.new("Frame")
dimensionContainer.Name = "Dimensions"
dimensionContainer.Position = UDim2.new(0, 20, 0, 60)
dimensionContainer.Size = UDim2.new(1, -40, 0, 180)
dimensionContainer.BackgroundTransparency = 1
dimensionContainer.Parent = selectionPanel

local dimensionLayout = Instance.new("UIGridLayout")
dimensionLayout.CellSize = UDim2.new(0.5, -10, 0, 80)
dimensionLayout.CellPadding = UDim2.new(0, 10, 0, 10)
dimensionLayout.Parent = dimensionContainer

-- Create dimension buttons
local dimensionButtons = {}
for _, dim in ipairs(DIMENSIONS) do
	local button = Instance.new("TextButton")
	button.Name = dim.name
	button.BackgroundColor3 = dim.color
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = dim.name
	button.Parent = dimensionContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	dimensionButtons[dim.name] = button
end

-- Section selector
local sectionFrame = Instance.new("Frame")
sectionFrame.Name = "SectionSelector"
sectionFrame.Position = UDim2.new(0, 20, 0, 250)
sectionFrame.Size = UDim2.new(1, -40, 0, 40)
sectionFrame.BackgroundTransparency = 1
sectionFrame.Parent = selectionPanel

local sectionLabel = Instance.new("TextLabel")
sectionLabel.Name = "Label"
sectionLabel.Position = UDim2.new(0, 0, 0, 0)
sectionLabel.Size = UDim2.new(0, 100, 1, 0)
sectionLabel.BackgroundTransparency = 1
sectionLabel.Font = Enum.Font.Gotham
sectionLabel.TextSize = 16
sectionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sectionLabel.Text = "Section:"
sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel.Parent = sectionFrame

local sectionDown = Instance.new("TextButton")
sectionDown.Name = "Down"
sectionDown.Position = UDim2.new(0, 100, 0, 0)
sectionDown.Size = UDim2.new(0, 40, 1, 0)
sectionDown.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
sectionDown.Font = Enum.Font.GothamBold
sectionDown.TextSize = 20
sectionDown.TextColor3 = Color3.fromRGB(255, 255, 255)
sectionDown.Text = "-"
sectionDown.Parent = sectionFrame

local sectionCorner1 = Instance.new("UICorner")
sectionCorner1.CornerRadius = UDim.new(0, 6)
sectionCorner1.Parent = sectionDown

local sectionNumber = Instance.new("TextLabel")
sectionNumber.Name = "Number"
sectionNumber.Position = UDim2.new(0, 150, 0, 0)
sectionNumber.Size = UDim2.new(0, 60, 1, 0)
sectionNumber.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
sectionNumber.Font = Enum.Font.GothamBold
sectionNumber.TextSize = 18
sectionNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
sectionNumber.Text = "1"
sectionNumber.Parent = sectionFrame

local sectionCorner2 = Instance.new("UICorner")
sectionCorner2.CornerRadius = UDim.new(0, 6)
sectionCorner2.Parent = sectionNumber

local sectionUp = Instance.new("TextButton")
sectionUp.Name = "Up"
sectionUp.Position = UDim2.new(0, 220, 0, 0)
sectionUp.Size = UDim2.new(0, 40, 1, 0)
sectionUp.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
sectionUp.Font = Enum.Font.GothamBold
sectionUp.TextSize = 20
sectionUp.TextColor3 = Color3.fromRGB(255, 255, 255)
sectionUp.Text = "+"
sectionUp.Parent = sectionFrame

local sectionCorner3 = Instance.new("UICorner")
sectionCorner3.CornerRadius = UDim.new(0, 6)
sectionCorner3.Parent = sectionUp

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Parent = selectionPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Practice Controls (visible during practice)
local practiceControls = Instance.new("Frame")
practiceControls.Name = "PracticeControls"
practiceControls.AnchorPoint = Vector2.new(0, 0)
practiceControls.Position = UDim2.new(0, 20, 0, 100)
practiceControls.Size = UDim2.new(0, 200, 0, 160)
practiceControls.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
practiceControls.BackgroundTransparency = 0.3
practiceControls.Visible = false
practiceControls.Parent = screenGui

local controlsCorner = Instance.new("UICorner")
controlsCorner.CornerRadius = UDim.new(0, 10)
controlsCorner.Parent = practiceControls

local practiceTitle = Instance.new("TextLabel")
practiceTitle.Name = "Title"
practiceTitle.Position = UDim2.new(0, 10, 0, 5)
practiceTitle.Size = UDim2.new(1, -20, 0, 25)
practiceTitle.BackgroundTransparency = 1
practiceTitle.Font = Enum.Font.GothamBold
practiceTitle.TextSize = 14
practiceTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
practiceTitle.Text = "PRACTICE MODE"
practiceTitle.Parent = practiceControls

local practiceInfo = Instance.new("TextLabel")
practiceInfo.Name = "Info"
practiceInfo.Position = UDim2.new(0, 10, 0, 30)
practiceInfo.Size = UDim2.new(1, -20, 0, 20)
practiceInfo.BackgroundTransparency = 1
practiceInfo.Font = Enum.Font.Gotham
practiceInfo.TextSize = 12
practiceInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
practiceInfo.Text = "Section 1"
practiceInfo.Parent = practiceControls

local restartButton = Instance.new("TextButton")
restartButton.Name = "Restart"
restartButton.Position = UDim2.new(0, 10, 0, 60)
restartButton.Size = UDim2.new(1, -20, 0, 30)
restartButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
restartButton.Font = Enum.Font.GothamBold
restartButton.TextSize = 14
restartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
restartButton.Text = "Restart Section"
restartButton.Parent = practiceControls

local restartCorner = Instance.new("UICorner")
restartCorner.CornerRadius = UDim.new(0, 6)
restartCorner.Parent = restartButton

local nextSectionButton = Instance.new("TextButton")
nextSectionButton.Name = "NextSection"
nextSectionButton.Position = UDim2.new(0, 10, 0, 95)
nextSectionButton.Size = UDim2.new(1, -20, 0, 30)
nextSectionButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
nextSectionButton.Font = Enum.Font.GothamBold
nextSectionButton.TextSize = 14
nextSectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextSectionButton.Text = "Next Section"
nextSectionButton.Parent = practiceControls

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 6)
nextCorner.Parent = nextSectionButton

local exitPracticeButton = Instance.new("TextButton")
exitPracticeButton.Name = "Exit"
exitPracticeButton.Position = UDim2.new(0, 10, 0, 130)
exitPracticeButton.Size = UDim2.new(1, -20, 0, 25)
exitPracticeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
exitPracticeButton.Font = Enum.Font.GothamBold
exitPracticeButton.TextSize = 12
exitPracticeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitPracticeButton.Text = "Exit Practice"
exitPracticeButton.Parent = practiceControls

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 6)
exitCorner.Parent = exitPracticeButton

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function UpdateSectionDisplay()
	sectionNumber.Text = tostring(currentSection)
	practiceInfo.Text = string.format("%s - Section %d", currentDimension or "None", currentSection)
end

local function ShowSelectionPanel()
	selectionPanel.Visible = true
	startButton.Visible = false
end

local function HideSelectionPanel()
	selectionPanel.Visible = false
	if not isPracticing then
		startButton.Visible = true
	end
end

local function StartPractice(dimension, section)
	if RemoteEvents:FindFirstChild("StartPractice") then
		RemoteEvents.StartPractice:FireServer(dimension, section)
		isPracticing = true
		currentDimension = dimension
		currentSection = section
		HideSelectionPanel()
		practiceControls.Visible = true
		startButton.Visible = false
		UpdateSectionDisplay()
	end
end

local function StopPractice()
	if RemoteEvents:FindFirstChild("StopPractice") then
		RemoteEvents.StopPractice:FireServer()
		isPracticing = false
		practiceControls.Visible = false
		startButton.Visible = true
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

startButton.MouseButton1Click:Connect(ShowSelectionPanel)
closeButton.MouseButton1Click:Connect(HideSelectionPanel)

-- Dimension selection
for name, button in pairs(dimensionButtons) do
	button.MouseButton1Click:Connect(function()
		currentDimension = name
		StartPractice(name, currentSection)
	end)
end

-- Section selector
sectionDown.MouseButton1Click:Connect(function()
	currentSection = math.max(1, currentSection - 1)
	UpdateSectionDisplay()
end)

sectionUp.MouseButton1Click:Connect(function()
	currentSection = math.min(20, currentSection + 1)
	UpdateSectionDisplay()
end)

-- Practice controls
restartButton.MouseButton1Click:Connect(function()
	if RemoteEvents:FindFirstChild("RestartPractice") then
		RemoteEvents.RestartPractice:FireServer()
	end
end)

nextSectionButton.MouseButton1Click:Connect(function()
	if RemoteEvents:FindFirstChild("NextPracticeSection") then
		RemoteEvents.NextPracticeSection:FireServer()
		currentSection = currentSection + 1
		UpdateSectionDisplay()
	end
end)

exitPracticeButton.MouseButton1Click:Connect(function()
	StopPractice()
end)

-- Listen for dimension changes (server may force exit practice)
if RemoteEvents:FindFirstChild("DimensionChanged") then
	RemoteEvents.DimensionChanged.OnClientEvent:Connect(function(dimensionName, data)
		if data and data.IsPractice then
			isPracticing = true
			currentDimension = dimensionName
			currentSection = data.Section or currentSection
			practiceControls.Visible = true
			startButton.Visible = false
			UpdateSectionDisplay()
		elseif data and not data.IsPractice and isPracticing then
			isPracticing = false
			practiceControls.Visible = false
			startButton.Visible = true
		end
	end)
end

-- Button hover effects
local allButtons = {startButton, closeButton, sectionDown, sectionUp, restartButton, nextSectionButton, exitPracticeButton}
for _, dimData in ipairs(DIMENSIONS) do
	table.insert(allButtons, dimensionButtons[dimData.name])
end

for _, button in ipairs(allButtons) do
	local originalColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.2)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

print("[PracticeUI] Initialized")
