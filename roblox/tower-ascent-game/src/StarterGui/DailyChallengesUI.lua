--[[
	DailyChallengesUI.lua
	Client-side UI for displaying daily and weekly challenges

	Features:
	- HUD tracker showing active challenges
	- Daily reset timer countdown
	- Completion animations
	- Reward claim flow
	- Progress bars with visual feedback
	- Toggle to show/hide challenges panel

	Created: Week 16-17 - Daily Challenges System
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- UI positioning
	AnchorPoint = Vector2.new(1, 0), -- Top-right
	Position = UDim2.new(1, -20, 0, 100),

	-- Colors
	BackgroundColor = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.2,
	AccentColor = Color3.fromRGB(255, 215, 0), -- Gold
	CompletedColor = Color3.fromRGB(50, 205, 50), -- Lime green
	TextColor = Color3.fromRGB(255, 255, 255),
	ProgressBarBG = Color3.fromRGB(40, 40, 50),
	ProgressBarFill = Color3.fromRGB(100, 200, 255),

	-- Sizing
	TrackerWidth = 350,
	ChallengeCardHeight = 80,

	-- Animations
	CompletionAnimationDuration = 1,
	PulseAnimationDuration = 0.5,

	-- Update frequency
	TimerUpdateInterval = 1, -- Update countdown every second
}

-- ============================================================================
-- STATE
-- ============================================================================

local challengesData = {
	Daily = {},
	Weekly = {},
	Stats = {},
}

local isVisible = true
local nextDailyReset = 0
local nextWeeklyReset = 0

-- ============================================================================
-- UI ELEMENTS
-- ============================================================================

local screenGui = nil
local mainFrame = nil
local toggleButton = nil
local contentFrame = nil
local dailySection = nil
local weeklySection = nil
local timerLabel = nil

-- Remote events
local Events = nil

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function CreateScreenGui()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyChallengesUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	return screenGui
end

local function CreateMainFrame()
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = CONFIG.AnchorPoint
	mainFrame.Position = CONFIG.Position
	mainFrame.Size = UDim2.new(0, CONFIG.TrackerWidth, 0, 500)
	mainFrame.BackgroundColor3 = CONFIG.BackgroundColor
	mainFrame.BackgroundTransparency = CONFIG.BackgroundTransparency
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	return mainFrame
end

local function CreateToggleButton()
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.AnchorPoint = Vector2.new(1, 0)
	toggleButton.Position = UDim2.new(1, -20, 0, 20)
	toggleButton.Size = UDim2.new(0, 50, 0, 50)
	toggleButton.BackgroundColor3 = CONFIG.BackgroundColor
	toggleButton.BackgroundTransparency = 0.3
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "📋"
	toggleButton.TextSize = 24
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextColor3 = CONFIG.TextColor
	toggleButton.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toggleButton

	-- Toggle visibility on click
	toggleButton.MouseButton1Click:Connect(function()
		isVisible = not isVisible
		mainFrame.Visible = isVisible

		-- Animate toggle button
		local rotation = isVisible and 0 or 180
		local tween = TweenService:Create(
			toggleButton,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Rotation = rotation}
		)
		tween:Play()
	end)

	return toggleButton
end

local function CreateHeader()
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = CONFIG.AccentColor
	header.BackgroundTransparency = 0.8
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Daily Challenges"
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = CONFIG.TextColor
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, -20, 0, 20)
	timerLabel.Position = UDim2.new(0, 10, 0, 35)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Resets in: 00:00:00"
	timerLabel.TextSize = 14
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextColor3 = CONFIG.TextColor
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Parent = header

	return header
end

local function CreateContentFrame()
	contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Position = UDim2.new(0, 0, 0, 65)
	contentFrame.Size = UDim2.new(1, 0, 1, -65)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 6
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentFrame

	-- Auto-resize canvas
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)

	return contentFrame
end

local function CreateSectionLabel(text, order)
	local label = Instance.new("TextLabel")
	label.Name = text
	label.Size = UDim2.new(1, -20, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = CONFIG.AccentColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = contentFrame

	return label
end

-- ============================================================================
-- CHALLENGE CARD CREATION
-- ============================================================================

local function CreateChallengeCard(quest, questType, order)
	local card = Instance.new("Frame")
	card.Name = "ChallengeCard_" .. quest.Id
	card.Size = UDim2.new(1, -20, 0, CONFIG.ChallengeCardHeight)
	card.BackgroundColor3 = CONFIG.BackgroundColor
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = contentFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Challenge name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.Size = UDim2.new(1, -20, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = quest.Description
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = CONFIG.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Position = UDim2.new(0, 10, 0, 28)
	progressText.Size = UDim2.new(1, -20, 0, 15)
	progressText.BackgroundTransparency = 1
	progressText.Text = string.format("%d / %d", quest.Progress, quest.Target)
	progressText.TextSize = 12
	progressText.Font = Enum.Font.Gotham
	progressText.TextColor3 = CONFIG.TextColor
	progressText.TextXAlignment = Enum.TextXAlignment.Left
	progressText.Parent = card

	-- Progress bar background
	local progressBG = Instance.new("Frame")
	progressBG.Name = "ProgressBG"
	progressBG.Position = UDim2.new(0, 10, 1, -25)
	progressBG.Size = UDim2.new(1, -20, 0, 8)
	progressBG.BackgroundColor3 = CONFIG.ProgressBarBG
	progressBG.BorderSizePixel = 0
	progressBG.Parent = card

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressBG

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	local progressPercent = math.clamp(quest.Progress / quest.Target, 0, 1)
	progressFill.Size = UDim2.new(progressPercent, 0, 1, 0)
	progressFill.BackgroundColor3 = quest.Completed and CONFIG.CompletedColor or CONFIG.ProgressBarFill
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBG

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill

	-- Reward label
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name = "RewardLabel"
	rewardLabel.Position = UDim2.new(0, 10, 1, -17)
	rewardLabel.Size = UDim2.new(0, 200, 0, 12)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = string.format("Reward: %d coins, %d XP", quest.Reward.Coins, quest.Reward.XP)
	rewardLabel.TextSize = 10
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.TextColor3 = CONFIG.AccentColor
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.Parent = card

	-- Claim button (if completed)
	if quest.Completed and not quest.Claimed then
		local claimButton = Instance.new("TextButton")
		claimButton.Name = "ClaimButton"
		claimButton.AnchorPoint = Vector2.new(1, 0.5)
		claimButton.Position = UDim2.new(1, -10, 0.5, 0)
		claimButton.Size = UDim2.new(0, 70, 0, 30)
		claimButton.BackgroundColor3 = CONFIG.CompletedColor
		claimButton.BorderSizePixel = 0
		claimButton.Text = "CLAIM"
		claimButton.TextSize = 12
		claimButton.Font = Enum.Font.GothamBold
		claimButton.TextColor3 = CONFIG.TextColor
		claimButton.Parent = card

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = claimButton

		-- Claim reward on click
		claimButton.MouseButton1Click:Connect(function()
			if Events and Events.Quest then
				Events.Quest:FireServer("ClaimReward", quest.Id)

				-- Disable button immediately (prevent double-claim)
				claimButton.Active = false
				claimButton.BackgroundColor3 = CONFIG.ProgressBarBG
				claimButton.Text = "CLAIMED"
			end
		end)
	elseif quest.Claimed then
		-- Show "Claimed" badge
		local claimedBadge = Instance.new("TextLabel")
		claimedBadge.Name = "ClaimedBadge"
		claimedBadge.AnchorPoint = Vector2.new(1, 0.5)
		claimedBadge.Position = UDim2.new(1, -10, 0.5, 0)
		claimedBadge.Size = UDim2.new(0, 70, 0, 30)
		claimedBadge.BackgroundColor3 = CONFIG.ProgressBarBG
		claimedBadge.BackgroundTransparency = 0.5
		claimedBadge.BorderSizePixel = 0
		claimedBadge.Text = "✓ CLAIMED"
		claimedBadge.TextSize = 10
		claimedBadge.Font = Enum.Font.GothamBold
		claimedBadge.TextColor3 = CONFIG.CompletedColor
		claimedBadge.Parent = card

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 6)
		badgeCorner.Parent = claimedBadge
	end

	return card
end

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================

local function UpdateChallengeCard(quest)
	local cardName = "ChallengeCard_" .. quest.Id
	local card = contentFrame:FindFirstChild(cardName)
	if not card then return end

	-- Update progress text
	local progressText = card:FindFirstChild("ProgressText")
	if progressText then
		progressText.Text = string.format("%d / %d", quest.Progress, quest.Target)
	end

	-- Update progress bar
	local progressBG = card:FindFirstChild("ProgressBG")
	if progressBG then
		local progressFill = progressBG:FindFirstChild("ProgressFill")
		if progressFill then
			local progressPercent = math.clamp(quest.Progress / quest.Target, 0, 1)

			-- Animate progress bar
			local tween = TweenService:Create(
				progressFill,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(progressPercent, 0, 1, 0)}
			)
			tween:Play()

			-- Change color if completed
			if quest.Completed then
				progressFill.BackgroundColor3 = CONFIG.CompletedColor
			end
		end
	end

	-- Add claim button if completed
	if quest.Completed and not quest.Claimed and not card:FindFirstChild("ClaimButton") then
		local claimButton = Instance.new("TextButton")
		claimButton.Name = "ClaimButton"
		claimButton.AnchorPoint = Vector2.new(1, 0.5)
		claimButton.Position = UDim2.new(1, -10, 0.5, 0)
		claimButton.Size = UDim2.new(0, 70, 0, 30)
		claimButton.BackgroundColor3 = CONFIG.CompletedColor
		claimButton.BorderSizePixel = 0
		claimButton.Text = "CLAIM"
		claimButton.TextSize = 12
		claimButton.Font = Enum.Font.GothamBold
		claimButton.TextColor3 = CONFIG.TextColor
		claimButton.Parent = card

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = claimButton

		claimButton.MouseButton1Click:Connect(function()
			if Events and Events.Quest then
				Events.Quest:FireServer("ClaimReward", quest.Id)
				claimButton.Active = false
				claimButton.BackgroundColor3 = CONFIG.ProgressBarBG
				claimButton.Text = "CLAIMED"
			end
		end)

		-- Pulse animation for claim button
		local pulseTween = TweenService:Create(
			claimButton,
			TweenInfo.new(CONFIG.PulseAnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
			{Size = UDim2.new(0, 75, 0, 32)}
		)
		pulseTween:Play()
	end
end

local function RebuildChallengesList()
	-- Clear existing cards
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 0

	-- Add daily challenges
	if #challengesData.Daily > 0 then
		CreateSectionLabel("📅 Daily Challenges", order)
		order = order + 1

		for _, quest in ipairs(challengesData.Daily) do
			CreateChallengeCard(quest, "Daily", order)
			order = order + 1
		end
	end

	-- Add weekly challenges
	if #challengesData.Weekly > 0 then
		CreateSectionLabel("📆 Weekly Challenges", order)
		order = order + 1

		for _, quest in ipairs(challengesData.Weekly) do
			CreateChallengeCard(quest, "Weekly", order)
			order = order + 1
		end
	end
end

local function UpdateResetTimer()
	local now = os.time()

	-- Calculate time until next daily reset (midnight UTC)
	local nowUTC = os.date("!*t", now)
	local secondsSinceMidnight = nowUTC.hour * 3600 + nowUTC.min * 60 + nowUTC.sec
	local secondsUntilMidnight = 86400 - secondsSinceMidnight

	nextDailyReset = now + secondsUntilMidnight

	-- Format timer
	local hours = math.floor(secondsUntilMidnight / 3600)
	local minutes = math.floor((secondsUntilMidnight % 3600) / 60)
	local seconds = secondsUntilMidnight % 60

	if timerLabel then
		timerLabel.Text = string.format("Daily resets in: %02d:%02d:%02d", hours, minutes, seconds)
	end
end

-- ============================================================================
-- NETWORK EVENTS
-- ============================================================================

local function SetupNetworkEvents()
	local eventsFolder = ReplicatedStorage:WaitForChild("Events")
	local questEvent = eventsFolder:WaitForChild("QuestEvent")

	Events = {
		Quest = questEvent,
	}

	-- Listen for quest updates
	Events.Quest.OnClientEvent:Connect(function(action, data)
		if action == "QuestsUpdate" then
			-- Update local data
			challengesData.Daily = data.Daily or {}
			challengesData.Weekly = data.Weekly or {}
			challengesData.Stats = data.Stats or {}

			-- Rebuild UI
			RebuildChallengesList()

		elseif action == "QuestCompleted" then
			-- Show completion animation
			local quest = data.Quest
			if quest then
				UpdateChallengeCard(quest)

				-- TODO: Play celebration particle effect
				print("[DailyChallengesUI] Quest completed:", quest.Description)
			end

		elseif action == "RewardClaimed" then
			-- Update card to show "Claimed"
			local quest = data.Quest
			if quest then
				UpdateChallengeCard(quest)
				print("[DailyChallengesUI] Reward claimed:", quest.Reward.Coins, "coins")
			end

		elseif action == "ClaimFailed" then
			warn("[DailyChallengesUI] Claim failed:", data.Reason)
		end
	end)

	-- Request initial quest data
	Events.Quest:FireServer("GetQuests")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
	print("[DailyChallengesUI] Initializing...")

	-- Create UI
	CreateScreenGui()
	CreateMainFrame()
	CreateToggleButton()
	CreateHeader()
	CreateContentFrame()

	-- Setup network
	SetupNetworkEvents()

	-- Start timer update loop
	task.spawn(function()
		while true do
			UpdateResetTimer()
			task.wait(CONFIG.TimerUpdateInterval)
		end
	end)

	print("[DailyChallengesUI] Initialized successfully")
end

-- Start on spawn
Initialize()
