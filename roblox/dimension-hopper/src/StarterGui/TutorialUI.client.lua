--[[
	TutorialUI.client.lua
	Client UI for interactive tutorials

	Features:
	- Step-by-step tutorial display
	- Highlight objects in world
	- Progress indicator
	- Skip button
	- Completion celebration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[TutorialUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local currentTutorial = nil
local currentStep = nil
local highlightedObject = nil
local highlightGui = nil

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TutorialUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100 -- Above most UI
screenGui.Parent = playerGui

-- Tutorial panel
local tutorialPanel = Instance.new("Frame")
tutorialPanel.Name = "TutorialPanel"
tutorialPanel.AnchorPoint = Vector2.new(0.5, 1)
tutorialPanel.Position = UDim2.new(0.5, 0, 1, -30)
tutorialPanel.Size = UDim2.new(0, 500, 0, 150)
tutorialPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
tutorialPanel.BackgroundTransparency = 0.1
tutorialPanel.Visible = false
tutorialPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = tutorialPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(80, 150, 255)
panelStroke.Thickness = 2
panelStroke.Parent = tutorialPanel

-- Tutorial label
local tutorialLabel = Instance.new("TextLabel")
tutorialLabel.Name = "TutorialLabel"
tutorialLabel.Position = UDim2.new(0, 15, 0, 8)
tutorialLabel.Size = UDim2.new(1, -30, 0, 18)
tutorialLabel.BackgroundTransparency = 1
tutorialLabel.Font = Enum.Font.GothamBold
tutorialLabel.TextSize = 12
tutorialLabel.TextColor3 = Color3.fromRGB(80, 150, 255)
tutorialLabel.Text = "TUTORIAL"
tutorialLabel.TextXAlignment = Enum.TextXAlignment.Left
tutorialLabel.Parent = tutorialPanel

-- Progress label
local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.AnchorPoint = Vector2.new(1, 0)
progressLabel.Position = UDim2.new(1, -60, 0, 8)
progressLabel.Size = UDim2.new(0, 80, 0, 18)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextSize = 12
progressLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
progressLabel.Text = "1/5"
progressLabel.TextXAlignment = Enum.TextXAlignment.Right
progressLabel.Parent = tutorialPanel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 15, 0, 30)
titleLabel.Size = UDim2.new(1, -30, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Step Title"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = tutorialPanel

-- Description
local descriptionLabel = Instance.new("TextLabel")
descriptionLabel.Name = "Description"
descriptionLabel.Position = UDim2.new(0, 15, 0, 60)
descriptionLabel.Size = UDim2.new(1, -30, 0, 45)
descriptionLabel.BackgroundTransparency = 1
descriptionLabel.Font = Enum.Font.Gotham
descriptionLabel.TextSize = 16
descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
descriptionLabel.Text = "Step description goes here..."
descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
descriptionLabel.TextWrapped = true
descriptionLabel.Parent = tutorialPanel

-- Continue button
local continueButton = Instance.new("TextButton")
continueButton.Name = "Continue"
continueButton.AnchorPoint = Vector2.new(1, 1)
continueButton.Position = UDim2.new(1, -15, 1, -15)
continueButton.Size = UDim2.new(0, 120, 0, 35)
continueButton.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
continueButton.Font = Enum.Font.GothamBold
continueButton.TextSize = 14
continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
continueButton.Text = "Continue"
continueButton.Visible = false
continueButton.Parent = tutorialPanel

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 6)
continueCorner.Parent = continueButton

-- Action hint (when waiting for player action)
local actionHint = Instance.new("TextLabel")
actionHint.Name = "ActionHint"
actionHint.AnchorPoint = Vector2.new(1, 1)
actionHint.Position = UDim2.new(1, -15, 1, -15)
actionHint.Size = UDim2.new(0, 200, 0, 35)
actionHint.BackgroundTransparency = 1
actionHint.Font = Enum.Font.GothamBold
actionHint.TextSize = 14
actionHint.TextColor3 = Color3.fromRGB(255, 200, 100)
actionHint.Text = "Press SPACE to jump!"
actionHint.Visible = false
actionHint.Parent = tutorialPanel

-- Skip button
local skipButton = Instance.new("TextButton")
skipButton.Name = "Skip"
skipButton.AnchorPoint = Vector2.new(0, 1)
skipButton.Position = UDim2.new(0, 15, 1, -15)
skipButton.Size = UDim2.new(0, 80, 0, 30)
skipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
skipButton.Font = Enum.Font.Gotham
skipButton.TextSize = 12
skipButton.TextColor3 = Color3.fromRGB(180, 180, 200)
skipButton.Text = "Skip"
skipButton.Parent = tutorialPanel

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 6)
skipCorner.Parent = skipButton

-- Completion popup
local completionPopup = Instance.new("Frame")
completionPopup.Name = "Completion"
completionPopup.AnchorPoint = Vector2.new(0.5, 0.5)
completionPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
completionPopup.Size = UDim2.new(0, 350, 0, 200)
completionPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
completionPopup.Visible = false
completionPopup.Parent = screenGui

local completionCorner = Instance.new("UICorner")
completionCorner.CornerRadius = UDim.new(0, 12)
completionCorner.Parent = completionPopup

local completionStroke = Instance.new("UIStroke")
completionStroke.Color = Color3.fromRGB(100, 255, 100)
completionStroke.Thickness = 3
completionStroke.Parent = completionPopup

local completionTitle = Instance.new("TextLabel")
completionTitle.Name = "Title"
completionTitle.Position = UDim2.new(0, 0, 0, 30)
completionTitle.Size = UDim2.new(1, 0, 0, 35)
completionTitle.BackgroundTransparency = 1
completionTitle.Font = Enum.Font.GothamBold
completionTitle.TextSize = 26
completionTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
completionTitle.Text = "Tutorial Complete!"
completionTitle.Parent = completionPopup

local completionMessage = Instance.new("TextLabel")
completionMessage.Name = "Message"
completionMessage.Position = UDim2.new(0, 20, 0, 70)
completionMessage.Size = UDim2.new(1, -40, 0, 50)
completionMessage.BackgroundTransparency = 1
completionMessage.Font = Enum.Font.Gotham
completionMessage.TextSize = 16
completionMessage.TextColor3 = Color3.fromRGB(200, 200, 220)
completionMessage.Text = "You've learned the basics!"
completionMessage.TextWrapped = true
completionMessage.Parent = completionPopup

local completionXP = Instance.new("TextLabel")
completionXP.Name = "XP"
completionXP.Position = UDim2.new(0, 0, 0, 120)
completionXP.Size = UDim2.new(1, 0, 0, 25)
completionXP.BackgroundTransparency = 1
completionXP.Font = Enum.Font.GothamBold
completionXP.TextSize = 20
completionXP.TextColor3 = Color3.fromRGB(255, 200, 100)
completionXP.Text = "+50 XP"
completionXP.Parent = completionPopup

local completionClose = Instance.new("TextButton")
completionClose.Name = "Close"
completionClose.AnchorPoint = Vector2.new(0.5, 1)
completionClose.Position = UDim2.new(0.5, 0, 1, -15)
completionClose.Size = UDim2.new(0, 100, 0, 35)
completionClose.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
completionClose.Font = Enum.Font.GothamBold
completionClose.TextSize = 14
completionClose.TextColor3 = Color3.fromRGB(255, 255, 255)
completionClose.Text = "Got it!"
completionClose.Parent = completionPopup

local completionCloseCorner = Instance.new("UICorner")
completionCloseCorner.CornerRadius = UDim.new(0, 6)
completionCloseCorner.Parent = completionClose

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function ClearHighlight()
	if highlightGui then
		highlightGui:Destroy()
		highlightGui = nil
	end
	highlightedObject = nil
end

local function HighlightObject(tag: string)
	ClearHighlight()

	local CollectionService = game:GetService("CollectionService")
	local objects = CollectionService:GetTagged(tag)

	if #objects == 0 then return end

	-- Find closest object
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local closest = nil
	local closestDist = math.huge

	for _, obj in ipairs(objects) do
		if obj:IsA("BasePart") then
			local dist = (obj.Position - rootPart.Position).Magnitude
			if dist < closestDist then
				closest = obj
				closestDist = dist
			end
		end
	end

	if not closest then return end

	highlightedObject = closest

	-- Create highlight
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(80, 150, 255)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(80, 150, 255)
	highlight.OutlineTransparency = 0
	highlight.Adornee = closest
	highlight.Parent = closest

	highlightGui = highlight

	-- Pulse animation
	task.spawn(function()
		while highlightGui and highlightGui.Parent do
			for i = 0, 1, 0.05 do
				if not highlightGui or not highlightGui.Parent then break end
				highlightGui.FillTransparency = 0.5 + (math.sin(i * math.pi * 2) * 0.3)
				task.wait(0.05)
			end
		end
	end)
end

local function GetActionHintText(action: string): string
	local hints = {
		jump = "Press SPACE to jump!",
		checkpoint = "Touch the checkpoint!",
		gravityflip = "Enter the gravity zone!",
		glider = "Hold SPACE while falling!",
		continue = nil, -- No hint, show continue button
	}
	return hints[action]
end

local function ShowStep(stepData)
	currentStep = stepData.step

	tutorialLabel.Text = string.upper(stepData.tutorialName) .. " TUTORIAL"
	progressLabel.Text = string.format("%d/%d", stepData.stepNumber, stepData.totalSteps)
	titleLabel.Text = stepData.step.title
	descriptionLabel.Text = stepData.step.description

	-- Handle highlight
	if stepData.step.highlight then
		HighlightObject(stepData.step.highlight)
	else
		ClearHighlight()
	end

	-- Handle action
	local hintText = GetActionHintText(stepData.step.action)
	if hintText then
		continueButton.Visible = false
		actionHint.Visible = true
		actionHint.Text = hintText
	else
		continueButton.Visible = true
		actionHint.Visible = false
	end

	tutorialPanel.Visible = true

	-- Animate in
	tutorialPanel.Position = UDim2.new(0.5, 0, 1, 50)
	TweenService:Create(tutorialPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 1, -30)
	}):Play()
end

local function HideTutorial()
	ClearHighlight()

	TweenService:Create(tutorialPanel, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, 0, 1, 50)
	}):Play()

	task.delay(0.2, function()
		tutorialPanel.Visible = false
	end)

	currentTutorial = nil
	currentStep = nil
end

local function ShowCompletion(tutorialName: string, rewardXP: number)
	completionMessage.Text = "You've completed the " .. tutorialName .. " tutorial!"
	completionXP.Text = "+" .. tostring(rewardXP) .. " XP"

	completionPopup.Visible = true
	completionPopup.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(completionPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 350, 0, 200)
	}):Play()
end

local function ReportAction(action: string)
	local tutorialAction = RemoteEvents:FindFirstChild("TutorialAction")
	if tutorialAction then
		tutorialAction:FireServer(action)
	end
end

-- ============================================================================
-- INPUT DETECTION
-- ============================================================================

-- Detect jump
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if currentStep and currentStep.action == "jump" then
		if input.KeyCode == Enum.KeyCode.Space then
			ReportAction("jump")
		end
	end
end)

-- Detect glider (holding space while falling)
local isGliding = false
game:GetService("RunService").Heartbeat:Connect(function()
	if currentStep and currentStep.action == "glider" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					if not isGliding then
						isGliding = true
						ReportAction("glider")
					end
				else
					isGliding = false
				end
			end
		end
	end
end)

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

continueButton.MouseButton1Click:Connect(function()
	ReportAction("continue")
end)

skipButton.MouseButton1Click:Connect(function()
	if currentTutorial then
		local skipTutorial = RemoteEvents:FindFirstChild("SkipTutorial")
		if skipTutorial then
			skipTutorial:FireServer(currentTutorial)
		end
		HideTutorial()
	end
end)

completionClose.MouseButton1Click:Connect(function()
	TweenService:Create(completionPopup, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(0.2, function()
		completionPopup.Visible = false
	end)
end)

-- Server events
local tutorialStep = RemoteEvents:FindFirstChild("TutorialStep")
if tutorialStep then
	tutorialStep.OnClientEvent:Connect(function(data)
		if data.complete then
			HideTutorial()
			ShowCompletion(data.tutorialName, data.rewardXP or 0)
		elseif data.skipped then
			HideTutorial()
		else
			currentTutorial = data.tutorialName
			ShowStep(data)
		end
	end)
end

-- Button hover effects
local buttons = {continueButton, skipButton, completionClose}
for _, button in ipairs(buttons) do
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

print("[TutorialUI] Initialized")
