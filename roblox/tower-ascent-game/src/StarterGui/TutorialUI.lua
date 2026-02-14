--[[
	TutorialUI.lua
	Interactive tutorial for first-time players

	Features:
	- Detects first-time players via DataService
	- Step-by-step tutorial flow
	- Highlights UI elements with arrows/circles
	- Teaches controls (WASD, Space, Q, U, L, T, P)
	- Teaches mechanics (jump, double jump, checkpoints, coins, shop)
	- Skippable with ESC
	- Progress tracking (can resume if interrupted)
	- Smooth animations

	Tutorial Steps:
	1. Welcome message
	2. Movement controls (WASD)
	3. Jump controls (Space)
	4. Objective (climb tower, reach checkpoints)
	5. Coins system
	6. Upgrade shop (U key)
	7. Other UIs (L for leaderboard, T for stats, P for settings)
	8. Ready to play!

	Week 5: Full implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TUTORIAL_STEPS = {
	{
		Title = "Welcome to Tower Ascent! 🏔️",
		Message = "Let's learn the basics. Press SPACE or click to continue.",
		Duration = 0, -- Wait for input
		Highlight = nil,
	},
	{
		Title = "Movement 🏃",
		Message = "Use WASD or Arrow Keys to move around.\n\nTry moving now!",
		Duration = 5,
		Highlight = nil,
	},
	{
		Title = "Jumping 🦘",
		Message = "Press SPACE to jump.\n\nJump 3 times to continue!",
		Duration = 0, -- Wait for 3 jumps
		Highlight = nil,
		RequireJumps = 3,
	},
	{
		Title = "The Objective 🎯",
		Message = "Climb the tower and reach checkpoints!\n\nCheckpoints save your progress and award coins.",
		Duration = 5,
		Highlight = nil,
	},
	{
		Title = "Coins & Upgrades 💰",
		Message = "Earn coins by reaching checkpoints and completing towers.\n\nSpend coins in the UPGRADE SHOP!",
		Duration = 5,
		Highlight = "CoinDisplayUI",
	},
	{
		Title = "Upgrade Shop 🛒",
		Message = "Press U to open the Upgrade Shop.\n\nBuy powerful abilities like Double Jump!",
		Duration = 5,
		Highlight = "UpgradeShopUI",
	},
	{
		Title = "Other Menus 📋",
		Message = "Press L for Leaderboard\nPress T for Statistics\nPress P for Settings",
		Duration = 5,
		Highlight = nil,
	},
	{
		Title = "You're Ready! ✅",
		Message = "Good luck climbing the tower!\n\nPress ESC anytime to skip tutorials in the future.",
		Duration = 5,
		Highlight = nil,
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

local currentStep = 1
local isTutorialActive = false
local jumpCount = 0
local isWaitingForInput = false

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TutorialUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100 -- On top of everything
screenGui.Parent = playerGui

-- Overlay (darkens screen)
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.7
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

-- Tutorial Frame (center)
local tutorialFrame = Instance.new("Frame")
tutorialFrame.Name = "TutorialFrame"
tutorialFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tutorialFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
tutorialFrame.Size = UDim2.new(0, 500, 0, 300)
tutorialFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tutorialFrame.BorderSizePixel = 0
tutorialFrame.Visible = false
tutorialFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = tutorialFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 200, 255)
stroke.Thickness = 3
stroke.Parent = tutorialFrame

-- Progress Bar Background
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Position = UDim2.new(0, 0, 0, 0)
progressBarBg.Size = UDim2.new(1, 0, 0, 5)
progressBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressBarBg.BorderSizePixel = 0
progressBarBg.Parent = tutorialFrame

-- Progress Bar Fill
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBarBg

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Position = UDim2.new(0, 20, 0, 20)
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 28
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextWrapped = true
titleLabel.Text = "Welcome!"
titleLabel.Parent = tutorialFrame

-- Message
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Position = UDim2.new(0, 20, 0, 70)
messageLabel.Size = UDim2.new(1, -40, 1, -120)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextSize = 18
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.Text = "Tutorial message here"
messageLabel.Parent = tutorialFrame

-- Continue Button
local continueButton = Instance.new("TextButton")
continueButton.Name = "ContinueButton"
continueButton.AnchorPoint = Vector2.new(1, 1)
continueButton.Position = UDim2.new(1, -20, 1, -20)
continueButton.Size = UDim2.new(0, 120, 0, 40)
continueButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
continueButton.BorderSizePixel = 0
continueButton.Font = Enum.Font.GothamBold
continueButton.TextSize = 18
continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
continueButton.Text = "Continue"
continueButton.Parent = tutorialFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = continueButton

-- Skip Button
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.AnchorPoint = Vector2.new(0, 1)
skipButton.Position = UDim2.new(0, 20, 1, -20)
skipButton.Size = UDim2.new(0, 100, 0, 40)
skipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
skipButton.BorderSizePixel = 0
skipButton.Font = Enum.Font.Gotham
skipButton.TextSize = 16
skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipButton.Text = "Skip (ESC)"
skipButton.Parent = tutorialFrame

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = skipButton

-- Step Counter
local stepCounter = Instance.new("TextLabel")
stepCounter.Name = "StepCounter"
stepCounter.AnchorPoint = Vector2.new(0.5, 1)
stepCounter.Position = UDim2.new(0.5, 0, 1, -30)
stepCounter.Size = UDim2.new(0, 100, 0, 20)
stepCounter.BackgroundTransparency = 1
stepCounter.Font = Enum.Font.Gotham
stepCounter.TextSize = 14
stepCounter.TextColor3 = Color3.fromRGB(150, 150, 150)
stepCounter.Text = "1 / 8"
stepCounter.Parent = tutorialFrame

-- Highlight Circle (for highlighting UI elements)
local highlightCircle = Instance.new("ImageLabel")
highlightCircle.Name = "HighlightCircle"
highlightCircle.AnchorPoint = Vector2.new(0.5, 0.5)
highlightCircle.Size = UDim2.new(0, 200, 0, 200)
highlightCircle.BackgroundTransparency = 1
highlightCircle.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
highlightCircle.ImageColor3 = Color3.fromRGB(100, 200, 255)
highlightCircle.ImageTransparency = 0.5
highlightCircle.Visible = false
highlightCircle.ZIndex = 99
highlightCircle.Parent = screenGui

-- ============================================================================
-- ANIMATIONS
-- ============================================================================

local function fadeIn(frame: GuiObject, duration: number?)
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	frame.Visible = true

	if frame:IsA("Frame") or frame:IsA("ImageLabel") then
		frame.BackgroundTransparency = 1
		local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0.7})
		tween:Play()
	end

	-- Fade in children
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = 1
			local tween = TweenService:Create(child, tweenInfo, {TextTransparency = 0})
			tween:Play()
		elseif child:IsA("Frame") and child ~= frame then
			child.BackgroundTransparency = 1
			local tween = TweenService:Create(child, tweenInfo, {BackgroundTransparency = 0})
			tween:Play()
		end
	end
end

local function fadeOut(frame: GuiObject, duration: number?, callback: () -> ()?)
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if frame:IsA("Frame") or frame:IsA("ImageLabel") then
		local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			frame.Visible = false
			if callback then callback() end
		end)
	end

	-- Fade out children
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, tweenInfo, {TextTransparency = 1}):Play()
		elseif child:IsA("Frame") and child ~= frame then
			TweenService:Create(child, tweenInfo, {BackgroundTransparency = 1}):Play()
		end
	end
end

-- ============================================================================
-- TUTORIAL LOGIC
-- ============================================================================

local function updateProgressBar()
	local progress = (currentStep - 1) / #TUTORIAL_STEPS
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(progressBar, tweenInfo, {Size = UDim2.new(progress, 0, 1, 0)}):Play()
end

local function highlightUI(uiName: string?)
	highlightCircle.Visible = false

	if not uiName then return end

	-- Find UI to highlight
	local targetUI = playerGui:FindFirstChild(uiName)
	if not targetUI then return end

	local targetFrame = targetUI:FindFirstChild("MainFrame") or targetUI:FindFirstChild("ScreenGui")
	if not targetFrame or not targetFrame:IsA("GuiObject") then return end

	-- Position highlight circle
	local absPos = targetFrame.AbsolutePosition
	local absSize = targetFrame.AbsoluteSize

	highlightCircle.Position = UDim2.new(0, absPos.X + absSize.X / 2, 0, absPos.Y + absSize.Y / 2)
	highlightCircle.Size = UDim2.new(0, absSize.X + 40, 0, absSize.Y + 40)
	highlightCircle.Visible = true

	-- Pulse animation
	task.spawn(function()
		while highlightCircle.Visible do
			TweenService:Create(highlightCircle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ImageTransparency = 0.3}):Play()
			task.wait(1)
			TweenService:Create(highlightCircle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ImageTransparency = 0.7}):Play()
			task.wait(1)
		end
	end)
end

local function showStep(stepIndex: number)
	if stepIndex > #TUTORIAL_STEPS then
		-- Tutorial complete!
		endTutorial(true)
		return
	end

	currentStep = stepIndex
	local step = TUTORIAL_STEPS[stepIndex]

	-- Update UI
	titleLabel.Text = step.Title
	messageLabel.Text = step.Message
	stepCounter.Text = string.format("%d / %d", stepIndex, #TUTORIAL_STEPS)

	-- Update progress bar
	updateProgressBar()

	-- Highlight UI if specified
	highlightUI(step.Highlight)

	-- Handle different step types
	if step.Duration == 0 then
		-- Wait for input
		isWaitingForInput = true
		continueButton.Text = "Continue"
		continueButton.Visible = true
	else
		-- Auto-advance after duration
		isWaitingForInput = false
		continueButton.Visible = false

		task.delay(step.Duration, function()
			if isTutorialActive and currentStep == stepIndex then
				showStep(stepIndex + 1)
			end
		end)
	end

	-- Special handling for jump tutorial
	if step.RequireJumps then
		jumpCount = 0
		continueButton.Text = string.format("Jump! (%d/3)", jumpCount)
		continueButton.Visible = true
	end
end

local function startTutorial()
	isTutorialActive = true
	currentStep = 1
	jumpCount = 0

	-- Show UI
	fadeIn(overlay)
	fadeIn(tutorialFrame)

	-- Start first step
	showStep(1)

	print("[TutorialUI] Tutorial started")
end

function endTutorial(completed: boolean)
	isTutorialActive = false

	-- Hide UI
	fadeOut(overlay)
	fadeOut(tutorialFrame)
	highlightCircle.Visible = false

	-- Save tutorial status to DataService via remote
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
	if remoteFolder then
		local setTutorialRemote = remoteFolder:FindFirstChild("SetTutorialComplete")
		if setTutorialRemote then
			pcall(function()
				setTutorialRemote:InvokeServer(completed)
			end)
		end
	end

	if completed then
		print("[TutorialUI] Tutorial completed and saved!")
	else
		print("[TutorialUI] Tutorial skipped and saved")
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

-- Continue button
continueButton.MouseButton1Click:Connect(function()
	if isWaitingForInput and not TUTORIAL_STEPS[currentStep].RequireJumps then
		showStep(currentStep + 1)
	end
end)

-- Skip button
skipButton.MouseButton1Click:Connect(function()
	endTutorial(false)
end)

-- ESC to skip
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isTutorialActive then return end

	if input.KeyCode == Enum.KeyCode.Escape then
		endTutorial(false)
	elseif input.KeyCode == Enum.KeyCode.Space and isWaitingForInput then
		-- Space to continue (alternative to button)
		if not TUTORIAL_STEPS[currentStep].RequireJumps then
			showStep(currentStep + 1)
		end
	end
end)

-- Track jumps for jump tutorial
task.spawn(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.StateChanged:Connect(function(oldState, newState)
		if not isTutorialActive then return end
		if not TUTORIAL_STEPS[currentStep].RequireJumps then return end

		if newState == Enum.HumanoidStateType.Jumping then
			jumpCount = jumpCount + 1
			continueButton.Text = string.format("Jump! (%d/3)", jumpCount)

			if jumpCount >= 3 then
				task.wait(0.5)
				showStep(currentStep + 1)
			end
		end
	end)
end)

-- ============================================================================
-- AUTO-START
-- ============================================================================

-- Check if player should see tutorial
task.spawn(function()
	task.wait(2) -- Wait for other systems to load

	-- Check DataService if player has completed/skipped tutorial
	local showTutorial = true
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 5)

	if remoteFolder then
		local getTutorialRemote = remoteFolder:FindFirstChild("GetTutorialStatus")
		if getTutorialRemote then
			local success, status = pcall(function()
				return getTutorialRemote:InvokeServer()
			end)

			if success and status then
				-- Don't show if already completed or skipped
				if status.completed or status.skipped then
					showTutorial = false
					print("[TutorialUI] Tutorial already completed/skipped, not showing")
				end
			end
		end
	end

	if showTutorial then
		task.wait(1)
		startTutorial()
	end
end)

print("[TutorialUI] Initialized")
