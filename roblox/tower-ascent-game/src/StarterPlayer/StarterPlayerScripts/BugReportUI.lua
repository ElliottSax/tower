--[[
	BugReportUI.lua
	Client-side bug reporting interface

	Features:
	- In-game bug report form
	- Category selection
	- Screenshot capture
	- Automatic context collection
	- Reproduction step recording

	Usage:
	   Press F9 or click bug button to open
	   Fill out form and submit

	Created: 2025-12-02 (Player Bug Reporting)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote events (these should be created by server)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bugReportRemote = ReplicatedStorage:WaitForChild("BugReport", 5)

local BugReportUI = {}
BugReportUI.Visible = false
BugReportUI.Recording = false
BugReportUI.ReproductionSteps = {}
BugReportUI.LastReport = 0

-- Categories
local CATEGORIES = {
	{Name = "Crash/Error", Value = "CRASH", Color = Color3.fromRGB(255, 0, 0)},
	{Name = "Data Loss", Value = "DATA", Color = Color3.fromRGB(255, 100, 0)},
	{Name = "Gameplay", Value = "GAMEPLAY", Color = Color3.fromRGB(255, 200, 0)},
	{Name = "Visual", Value = "VISUAL", Color = Color3.fromRGB(255, 255, 0)},
	{Name = "Performance", Value = "PERFORMANCE", Color = Color3.fromRGB(200, 150, 0)},
	{Name = "Other", Value = "OTHER", Color = Color3.fromRGB(150, 150, 150)}
}

-- ============================================================================
-- UI CREATION
-- ============================================================================

function BugReportUI.CreateUI()
	-- Main screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BugReportUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Background blur
	local blur = Instance.new("Frame")
	blur.Name = "Blur"
	blur.Size = UDim2.new(1, 0, 1, 0)
	blur.BackgroundColor3 = Color3.new(0, 0, 0)
	blur.BackgroundTransparency = 0.5
	blur.Visible = false
	blur.Parent = screenGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 600)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Fix header corner (only round top)
	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0, 12)
	headerFix.Position = UDim2.new(0, 0, 1, -12)
	headerFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐛 Report a Bug"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = header

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0.5, -20)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Content frame
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -70)
	content.Position = UDim2.new(0, 10, 0, 60)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.CanvasSize = UDim2.new(0, 0, 0, 800)
	content.Parent = mainFrame

	-- Category selection
	local categoryLabel = Instance.new("TextLabel")
	categoryLabel.Size = UDim2.new(1, 0, 0, 30)
	categoryLabel.Position = UDim2.new(0, 0, 0, 0)
	categoryLabel.BackgroundTransparency = 1
	categoryLabel.Text = "Category:"
	categoryLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	categoryLabel.TextScaled = true
	categoryLabel.Font = Enum.Font.SourceSans
	categoryLabel.Parent = content

	local categoryFrame = Instance.new("Frame")
	categoryFrame.Size = UDim2.new(1, 0, 0, 40)
	categoryFrame.Position = UDim2.new(0, 0, 0, 35)
	categoryFrame.BackgroundTransparency = 1
	categoryFrame.Parent = content

	local categoryList = Instance.new("UIListLayout")
	categoryList.FillDirection = Enum.FillDirection.Horizontal
	categoryList.Padding = UDim.new(0, 5)
	categoryList.Parent = categoryFrame

	-- Create category buttons
	local selectedCategory = nil
	local categoryButtons = {}

	for _, category in ipairs(CATEGORIES) do
		local button = Instance.new("TextButton")
		button.Name = category.Value
		button.Size = UDim2.new(0, 75, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.Text = category.Name
		button.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		button.TextScaled = true
		button.Font = Enum.Font.SourceSans
		button.Parent = categoryFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		categoryButtons[category.Value] = button

		button.MouseButton1Click:Connect(function()
			-- Deselect all
			for _, btn in pairs(categoryButtons) do
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
			end

			-- Select this one
			button.BackgroundColor3 = category.Color
			button.TextColor3 = Color3.new(1, 1, 1)
			selectedCategory = category.Value
		end)
	end

	-- Description input
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0, 30)
	descLabel.Position = UDim2.new(0, 0, 0, 85)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = "Description:"
	descLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.SourceSans
	descLabel.Parent = content

	local descBox = Instance.new("TextBox")
	descBox.Name = "DescriptionBox"
	descBox.Size = UDim2.new(1, 0, 0, 150)
	descBox.Position = UDim2.new(0, 0, 0, 120)
	descBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	descBox.Text = ""
	descBox.PlaceholderText = "Describe the bug in detail..."
	descBox.TextColor3 = Color3.new(1, 1, 1)
	descBox.PlaceholderColor3 = Color3.new(0.5, 0.5, 0.5)
	descBox.TextXAlignment = Enum.TextXAlignment.Left
	descBox.TextYAlignment = Enum.TextYAlignment.Top
	descBox.TextWrapped = true
	descBox.ClearTextOnFocus = false
	descBox.MultiLine = true
	descBox.Font = Enum.Font.SourceSans
	descBox.TextSize = 16
	descBox.Parent = content

	local descCorner = Instance.new("UICorner")
	descCorner.CornerRadius = UDim.new(0, 6)
	descCorner.Parent = descBox

	-- Steps to reproduce
	local stepsLabel = Instance.new("TextLabel")
	stepsLabel.Size = UDim2.new(1, 0, 0, 30)
	stepsLabel.Position = UDim2.new(0, 0, 0, 280)
	stepsLabel.BackgroundTransparency = 1
	stepsLabel.Text = "Steps to Reproduce (optional):"
	stepsLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	stepsLabel.TextXAlignment = Enum.TextXAlignment.Left
	stepsLabel.TextScaled = true
	stepsLabel.Font = Enum.Font.SourceSans
	stepsLabel.Parent = content

	local stepsBox = Instance.new("TextBox")
	stepsBox.Name = "StepsBox"
	stepsBox.Size = UDim2.new(1, 0, 0, 100)
	stepsBox.Position = UDim2.new(0, 0, 0, 315)
	stepsBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	stepsBox.Text = ""
	stepsBox.PlaceholderText = "1. Do this\n2. Then this\n3. Bug happens"
	stepsBox.TextColor3 = Color3.new(1, 1, 1)
	stepsBox.PlaceholderColor3 = Color3.new(0.5, 0.5, 0.5)
	stepsBox.TextXAlignment = Enum.TextXAlignment.Left
	stepsBox.TextYAlignment = Enum.TextYAlignment.Top
	stepsBox.TextWrapped = true
	stepsBox.ClearTextOnFocus = false
	stepsBox.MultiLine = true
	stepsBox.Font = Enum.Font.SourceSans
	stepsBox.TextSize = 16
	stepsBox.Parent = content

	local stepsCorner = Instance.new("UICorner")
	stepsCorner.CornerRadius = UDim.new(0, 6)
	stepsCorner.Parent = stepsBox

	-- Additional options
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Size = UDim2.new(1, 0, 0, 40)
	optionsFrame.Position = UDim2.new(0, 0, 0, 425)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Parent = content

	-- Include screenshot checkbox
	local screenshotCheck = Instance.new("TextButton")
	screenshotCheck.Size = UDim2.new(0, 30, 0, 30)
	screenshotCheck.Position = UDim2.new(0, 0, 0, 5)
	screenshotCheck.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	screenshotCheck.Text = ""
	screenshotCheck.Parent = optionsFrame

	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(0, 6)
	checkCorner.Parent = screenshotCheck

	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Text = "✓"
	checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
	checkmark.TextScaled = true
	checkmark.Visible = false
	checkmark.Parent = screenshotCheck

	local includeScreenshot = false
	screenshotCheck.MouseButton1Click:Connect(function()
		includeScreenshot = not includeScreenshot
		checkmark.Visible = includeScreenshot
	end)

	local screenshotLabel = Instance.new("TextLabel")
	screenshotLabel.Size = UDim2.new(0, 200, 1, 0)
	screenshotLabel.Position = UDim2.new(0, 40, 0, 0)
	screenshotLabel.BackgroundTransparency = 1
	screenshotLabel.Text = "Include Screenshot"
	screenshotLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	screenshotLabel.TextXAlignment = Enum.TextXAlignment.Left
	screenshotLabel.TextScaled = true
	screenshotLabel.Font = Enum.Font.SourceSans
	screenshotLabel.Parent = optionsFrame

	-- Submit button
	local submitButton = Instance.new("TextButton")
	submitButton.Name = "SubmitButton"
	submitButton.Size = UDim2.new(0, 200, 0, 40)
	submitButton.Position = UDim2.new(0.5, -100, 0, 480)
	submitButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	submitButton.Text = "Submit Report"
	submitButton.TextColor3 = Color3.new(1, 1, 1)
	submitButton.TextScaled = true
	submitButton.Font = Enum.Font.SourceSansBold
	submitButton.Parent = content

	local submitCorner = Instance.new("UICorner")
	submitCorner.CornerRadius = UDim.new(0, 8)
	submitCorner.Parent = submitButton

	-- Status message
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 30)
	statusLabel.Position = UDim2.new(0, 0, 0, 530)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.Parent = content

	-- Bug button (always visible)
	local bugButton = Instance.new("ImageButton")
	bugButton.Name = "BugButton"
	bugButton.Size = UDim2.new(0, 50, 0, 50)
	bugButton.Position = UDim2.new(1, -60, 1, -60)
	bugButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	bugButton.Image = "rbxasset://textures/ui/Settings/Help/Bug.png"
	bugButton.Parent = screenGui

	local bugCorner = Instance.new("UICorner")
	bugCorner.CornerRadius = UDim.new(0.5, 0)
	bugCorner.Parent = bugButton

	-- Store references
	BugReportUI.GUI = screenGui
	BugReportUI.MainFrame = mainFrame
	BugReportUI.Blur = blur
	BugReportUI.DescBox = descBox
	BugReportUI.StepsBox = stepsBox
	BugReportUI.StatusLabel = statusLabel

	-- Button handlers
	closeButton.MouseButton1Click:Connect(function()
		BugReportUI.Hide()
	end)

	bugButton.MouseButton1Click:Connect(function()
		BugReportUI.Toggle()
	end)

	submitButton.MouseButton1Click:Connect(function()
		if not selectedCategory then
			statusLabel.Text = "Please select a category"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			return
		end

		if descBox.Text == "" then
			statusLabel.Text = "Please describe the bug"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			return
		end

		-- Rate limiting
		if tick() - BugReportUI.LastReport < 60 then
			local remaining = math.ceil(60 - (tick() - BugReportUI.LastReport))
			statusLabel.Text = string.format("Please wait %d seconds", remaining)
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			return
		end

		-- Submit report
		BugReportUI.SubmitReport(selectedCategory, descBox.Text, stepsBox.Text, includeScreenshot)
	end)

	return screenGui
end

-- ============================================================================
-- UI CONTROL
-- ============================================================================

function BugReportUI.Show()
	if not BugReportUI.GUI then
		BugReportUI.CreateUI()
	end

	BugReportUI.Visible = true
	BugReportUI.MainFrame.Visible = true
	BugReportUI.Blur.Visible = true

	-- Animate in
	BugReportUI.MainFrame.Position = UDim2.new(0.5, -250, 0.5, -400)
	local tween = TweenService:Create(BugReportUI.MainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back),
		{Position = UDim2.new(0.5, -250, 0.5, -300)})
	tween:Play()
end

function BugReportUI.Hide()
	if not BugReportUI.GUI then
		return
	end

	-- Animate out
	local tween = TweenService:Create(BugReportUI.MainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{Position = UDim2.new(0.5, -250, 0.5, -400)})

	tween.Completed:Connect(function()
		BugReportUI.MainFrame.Visible = false
		BugReportUI.Blur.Visible = false
		BugReportUI.Visible = false

		-- Clear form
		BugReportUI.DescBox.Text = ""
		BugReportUI.StepsBox.Text = ""
		BugReportUI.StatusLabel.Text = ""
	end)

	tween:Play()
end

function BugReportUI.Toggle()
	if BugReportUI.Visible then
		BugReportUI.Hide()
	else
		BugReportUI.Show()
	end
end

-- ============================================================================
-- REPORT SUBMISSION
-- ============================================================================

function BugReportUI.SubmitReport(category: string, description: string, steps: string, screenshot: boolean)
	if not bugReportRemote then
		BugReportUI.StatusLabel.Text = "Bug reporting not available"
		BugReportUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	-- Collect context
	local context = {
		Position = player.Character and player.Character.PrimaryPart and
			player.Character.PrimaryPart.Position,
		CameraPosition = workspace.CurrentCamera.CFrame.Position,
		FPS = math.floor(1 / RunService.RenderStepped:Wait()),
		Memory = Stats:GetTotalMemoryUsageMb(),
		Ping = player:GetNetworkPing()
	}

	-- Send report
	local success = pcall(function()
		bugReportRemote:FireServer({
			Category = category,
			Description = description,
			Steps = steps,
			Screenshot = screenshot,
			Context = context,
			ReproductionSteps = BugReportUI.ReproductionSteps
		})
	end)

	if success then
		BugReportUI.LastReport = tick()
		BugReportUI.StatusLabel.Text = "Report submitted successfully!"
		BugReportUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Auto-hide after 2 seconds
		task.wait(2)
		BugReportUI.Hide()
	else
		BugReportUI.StatusLabel.Text = "Failed to submit report"
		BugReportUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

-- ============================================================================
-- REPRODUCTION RECORDING
-- ============================================================================

function BugReportUI.StartRecording()
	BugReportUI.Recording = true
	BugReportUI.ReproductionSteps = {}
	print("[BugReport] Started recording reproduction steps")
end

function BugReportUI.StopRecording()
	BugReportUI.Recording = false
	print(string.format("[BugReport] Stopped recording. %d steps recorded",
		#BugReportUI.ReproductionSteps))
end

function BugReportUI.RecordStep(action: string, data: {}?)
	if not BugReportUI.Recording then
		return
	end

	table.insert(BugReportUI.ReproductionSteps, {
		Action = action,
		Data = data,
		Timestamp = tick()
	})
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- F9 to open bug report
	if input.KeyCode == Enum.KeyCode.F9 then
		BugReportUI.Toggle()
	end

	-- Record inputs if recording
	if BugReportUI.Recording then
		BugReportUI.RecordStep("Input", {
			KeyCode = input.KeyCode.Name,
			UserInputType = input.UserInputType.Name
		})
	end
end)

-- ============================================================================
-- AUTO-CAPTURE
-- ============================================================================

-- Capture errors
game:GetService("ScriptContext").Error:Connect(function(message, stack, script)
	-- Auto-report critical errors
	if message:find("DataService") or message:find("data loss") then
		warn("[BugReport] Critical error detected, auto-reporting...")

		if bugReportRemote then
			bugReportRemote:FireServer({
				Category = "CRASH",
				Description = "Auto-detected critical error",
				Error = message,
				Stack = stack,
				Script = script and script:GetFullName()
			})
		end
	end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BugReportUI.Initialize()
	-- Create UI
	BugReportUI.CreateUI()

	print("[BugReport] UI initialized. Press F9 to report bugs.")
end

-- Initialize on start
BugReportUI.Initialize()

return BugReportUI