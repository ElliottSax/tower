--[[
	DailyChallengeUI.client.lua
	Client UI for daily and weekly challenges

	Features:
	- Shows current daily dimension
	- Time until reset
	- Leaderboard display
	- Start challenge button
	- Completion notification
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[DailyChallengeUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local challengeInfo = nil
local isLeaderboardOpen = false

-- Dimension colors
local DIMENSION_COLORS = {
	Gravity = Color3.fromRGB(150, 50, 255),
	Tiny = Color3.fromRGB(50, 200, 50),
	Void = Color3.fromRGB(150, 40, 40),
	Sky = Color3.fromRGB(100, 180, 255),
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyChallengeUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Daily Challenge Card (top right)
local challengeCard = Instance.new("Frame")
challengeCard.Name = "ChallengeCard"
challengeCard.AnchorPoint = Vector2.new(1, 0)
challengeCard.Position = UDim2.new(1, -20, 0, 80)
challengeCard.Size = UDim2.new(0, 220, 0, 120)
challengeCard.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
challengeCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 10)
cardCorner.Parent = challengeCard

local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 55)),
})
cardGradient.Rotation = 90
cardGradient.Parent = challengeCard

-- Daily label
local dailyLabel = Instance.new("TextLabel")
dailyLabel.Name = "DailyLabel"
dailyLabel.Position = UDim2.new(0, 10, 0, 5)
dailyLabel.Size = UDim2.new(1, -20, 0, 20)
dailyLabel.BackgroundTransparency = 1
dailyLabel.Font = Enum.Font.GothamBold
dailyLabel.TextSize = 12
dailyLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
dailyLabel.Text = "DAILY CHALLENGE"
dailyLabel.TextXAlignment = Enum.TextXAlignment.Left
dailyLabel.Parent = challengeCard

-- Dimension name
local dimensionLabel = Instance.new("TextLabel")
dimensionLabel.Name = "DimensionLabel"
dimensionLabel.Position = UDim2.new(0, 10, 0, 25)
dimensionLabel.Size = UDim2.new(1, -20, 0, 30)
dimensionLabel.BackgroundTransparency = 1
dimensionLabel.Font = Enum.Font.GothamBold
dimensionLabel.TextSize = 24
dimensionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dimensionLabel.Text = "Loading..."
dimensionLabel.TextXAlignment = Enum.TextXAlignment.Left
dimensionLabel.Parent = challengeCard

-- Timer
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Position = UDim2.new(0, 10, 0, 55)
timerLabel.Size = UDim2.new(1, -20, 0, 16)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextSize = 12
timerLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
timerLabel.Text = "Resets in: --:--:--"
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = challengeCard

-- Start button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Position = UDim2.new(0, 10, 0, 80)
startButton.Size = UDim2.new(0.5, -15, 0, 30)
startButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 14
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.Text = "Play"
startButton.Parent = challengeCard

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 6)
startCorner.Parent = startButton

-- Leaderboard button
local leaderboardButton = Instance.new("TextButton")
leaderboardButton.Name = "LeaderboardButton"
leaderboardButton.Position = UDim2.new(0.5, 5, 0, 80)
leaderboardButton.Size = UDim2.new(0.5, -15, 0, 30)
leaderboardButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
leaderboardButton.Font = Enum.Font.GothamBold
leaderboardButton.TextSize = 14
leaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
leaderboardButton.Text = "Rankings"
leaderboardButton.Parent = challengeCard

local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 6)
lbCorner.Parent = leaderboardButton

-- Leaderboard Panel
local leaderboardPanel = Instance.new("Frame")
leaderboardPanel.Name = "LeaderboardPanel"
leaderboardPanel.AnchorPoint = Vector2.new(0.5, 0.5)
leaderboardPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
leaderboardPanel.Size = UDim2.new(0, 350, 0, 400)
leaderboardPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
leaderboardPanel.Visible = false
leaderboardPanel.Parent = screenGui

local lbPanelCorner = Instance.new("UICorner")
lbPanelCorner.CornerRadius = UDim.new(0, 12)
lbPanelCorner.Parent = leaderboardPanel

local lbPanelStroke = Instance.new("UIStroke")
lbPanelStroke.Color = Color3.fromRGB(100, 100, 150)
lbPanelStroke.Thickness = 2
lbPanelStroke.Parent = leaderboardPanel

-- Leaderboard title
local lbTitle = Instance.new("TextLabel")
lbTitle.Name = "Title"
lbTitle.Position = UDim2.new(0, 0, 0, 10)
lbTitle.Size = UDim2.new(1, 0, 0, 30)
lbTitle.BackgroundTransparency = 1
lbTitle.Font = Enum.Font.GothamBold
lbTitle.TextSize = 22
lbTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
lbTitle.Text = "Daily Leaderboard"
lbTitle.Parent = leaderboardPanel

-- Leaderboard scroll frame
local lbScroll = Instance.new("ScrollingFrame")
lbScroll.Name = "EntriesScroll"
lbScroll.Position = UDim2.new(0, 15, 0, 50)
lbScroll.Size = UDim2.new(1, -30, 1, -100)
lbScroll.BackgroundTransparency = 1
lbScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
lbScroll.ScrollBarThickness = 6
lbScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
lbScroll.Parent = leaderboardPanel

local lbLayout = Instance.new("UIListLayout")
lbLayout.SortOrder = Enum.SortOrder.LayoutOrder
lbLayout.Padding = UDim.new(0, 5)
lbLayout.Parent = lbScroll

-- Close leaderboard button
local closeLbButton = Instance.new("TextButton")
closeLbButton.Name = "Close"
closeLbButton.AnchorPoint = Vector2.new(0.5, 1)
closeLbButton.Position = UDim2.new(0.5, 0, 1, -15)
closeLbButton.Size = UDim2.new(0, 100, 0, 35)
closeLbButton.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
closeLbButton.Font = Enum.Font.GothamBold
closeLbButton.TextSize = 14
closeLbButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeLbButton.Text = "Close"
closeLbButton.Parent = leaderboardPanel

local closeLbCorner = Instance.new("UICorner")
closeLbCorner.CornerRadius = UDim.new(0, 6)
closeLbCorner.Parent = closeLbButton

-- Completion notification
local completionFrame = Instance.new("Frame")
completionFrame.Name = "Completion"
completionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
completionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
completionFrame.Size = UDim2.new(0, 300, 0, 200)
completionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
completionFrame.Visible = false
completionFrame.Parent = screenGui

local completionCorner = Instance.new("UICorner")
completionCorner.CornerRadius = UDim.new(0, 12)
completionCorner.Parent = completionFrame

local completionStroke = Instance.new("UIStroke")
completionStroke.Color = Color3.fromRGB(255, 200, 100)
completionStroke.Thickness = 3
completionStroke.Parent = completionFrame

local completionTitle = Instance.new("TextLabel")
completionTitle.Name = "Title"
completionTitle.Position = UDim2.new(0, 0, 0, 20)
completionTitle.Size = UDim2.new(1, 0, 0, 30)
completionTitle.BackgroundTransparency = 1
completionTitle.Font = Enum.Font.GothamBold
completionTitle.TextSize = 24
completionTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
completionTitle.Text = "Daily Complete!"
completionTitle.Parent = completionFrame

local completionTime = Instance.new("TextLabel")
completionTime.Name = "Time"
completionTime.Position = UDim2.new(0, 0, 0, 60)
completionTime.Size = UDim2.new(1, 0, 0, 40)
completionTime.BackgroundTransparency = 1
completionTime.Font = Enum.Font.GothamBold
completionTime.TextSize = 32
completionTime.TextColor3 = Color3.fromRGB(255, 255, 255)
completionTime.Text = "0:00.00"
completionTime.Parent = completionFrame

local completionXP = Instance.new("TextLabel")
completionXP.Name = "XP"
completionXP.Position = UDim2.new(0, 0, 0, 100)
completionXP.Size = UDim2.new(1, 0, 0, 25)
completionXP.BackgroundTransparency = 1
completionXP.Font = Enum.Font.Gotham
completionXP.TextSize = 18
completionXP.TextColor3 = Color3.fromRGB(100, 255, 100)
completionTime.Text = "+100 XP"
completionXP.Parent = completionFrame

local completionPlacement = Instance.new("TextLabel")
completionPlacement.Name = "Placement"
completionPlacement.Position = UDim2.new(0, 0, 0, 125)
completionPlacement.Size = UDim2.new(1, 0, 0, 25)
completionPlacement.BackgroundTransparency = 1
completionPlacement.Font = Enum.Font.Gotham
completionPlacement.TextSize = 16
completionPlacement.TextColor3 = Color3.fromRGB(180, 180, 200)
completionPlacement.Text = "Rank: #1"
completionPlacement.Parent = completionFrame

local completionClose = Instance.new("TextButton")
completionClose.Name = "Close"
completionClose.AnchorPoint = Vector2.new(0.5, 1)
completionClose.Position = UDim2.new(0.5, 0, 1, -15)
completionClose.Size = UDim2.new(0, 100, 0, 35)
completionClose.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
completionClose.Font = Enum.Font.GothamBold
completionClose.TextSize = 14
completionClose.TextColor3 = Color3.fromRGB(255, 255, 255)
completionClose.Text = "OK"
completionClose.Parent = completionFrame

local completionCloseCorner = Instance.new("UICorner")
completionCloseCorner.CornerRadius = UDim.new(0, 6)
completionCloseCorner.Parent = completionClose

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function FormatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%05.2f", mins, secs)
end

local function FormatCountdown(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function UpdateChallengeCard()
	if not challengeInfo or not challengeInfo.daily then return end

	local daily = challengeInfo.daily
	dimensionLabel.Text = daily.dimension
	dimensionLabel.TextColor3 = DIMENSION_COLORS[daily.dimension] or Color3.fromRGB(255, 255, 255)
end

local function UpdateTimer()
	if not challengeInfo or not challengeInfo.daily then return end

	local timeRemaining = challengeInfo.daily.timeUntilReset
	if timeRemaining and timeRemaining > 0 then
		timerLabel.Text = "Resets in: " .. FormatCountdown(timeRemaining)
		challengeInfo.daily.timeUntilReset = timeRemaining - 1
	else
		timerLabel.Text = "Resetting..."
	end
end

local function CreateLeaderboardEntry(entry, index)
	local entryFrame = Instance.new("Frame")
	entryFrame.Name = "Entry_" .. index
	entryFrame.Size = UDim2.new(1, 0, 0, 40)
	entryFrame.LayoutOrder = index
	entryFrame.BackgroundTransparency = 1

	-- Placement badge
	local placementBadge = Instance.new("TextLabel")
	placementBadge.Position = UDim2.new(0, 0, 0, 0)
	placementBadge.Size = UDim2.new(0, 40, 1, 0)
	placementBadge.BackgroundTransparency = 1
	placementBadge.Font = Enum.Font.GothamBold
	placementBadge.TextSize = 18
	placementBadge.Parent = entryFrame

	if entry.placement == 1 then
		placementBadge.Text = "#1"
		placementBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif entry.placement == 2 then
		placementBadge.Text = "#2"
		placementBadge.TextColor3 = Color3.fromRGB(192, 192, 192)
	elseif entry.placement == 3 then
		placementBadge.Text = "#3"
		placementBadge.TextColor3 = Color3.fromRGB(205, 127, 50)
	else
		placementBadge.Text = "#" .. entry.placement
		placementBadge.TextColor3 = Color3.fromRGB(150, 150, 180)
	end

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 50, 0, 0)
	nameLabel.Size = UDim2.new(1, -130, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = entry.name
	nameLabel.Parent = entryFrame

	-- Time
	local timeLabel = Instance.new("TextLabel")
	timeLabel.AnchorPoint = Vector2.new(1, 0)
	timeLabel.Position = UDim2.new(1, 0, 0, 0)
	timeLabel.Size = UDim2.new(0, 80, 1, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 14
	timeLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Text = FormatTime(entry.time)
	timeLabel.Parent = entryFrame

	-- Highlight if current player
	if entry.userId == player.UserId then
		local highlight = Instance.new("Frame")
		highlight.Size = UDim2.new(1, 0, 1, 0)
		highlight.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
		highlight.ZIndex = 0
		highlight.Parent = entryFrame

		local highlightCorner = Instance.new("UICorner")
		highlightCorner.CornerRadius = UDim.new(0, 6)
		highlightCorner.Parent = highlight
	end

	return entryFrame
end

local function RefreshLeaderboard()
	-- Clear existing entries
	for _, child in ipairs(lbScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get leaderboard
	local getDailyLeaderboard = RemoteEvents:FindFirstChild("GetDailyLeaderboard")
	if not getDailyLeaderboard then return end

	local leaderboard = getDailyLeaderboard:InvokeServer()
	if not leaderboard or #leaderboard == 0 then
		local noData = Instance.new("TextLabel")
		noData.Size = UDim2.new(1, 0, 0, 40)
		noData.BackgroundTransparency = 1
		noData.Font = Enum.Font.Gotham
		noData.TextSize = 14
		noData.TextColor3 = Color3.fromRGB(150, 150, 180)
		noData.Text = "No times recorded yet. Be the first!"
		noData.Parent = lbScroll
		return
	end

	-- Create entries
	for i, entry in ipairs(leaderboard) do
		local entryFrame = CreateLeaderboardEntry(entry, i)
		entryFrame.Parent = lbScroll
	end

	-- Update canvas size
	lbScroll.CanvasSize = UDim2.new(0, 0, 0, lbLayout.AbsoluteContentSize.Y + 10)
end

local function ShowLeaderboard()
	RefreshLeaderboard()
	leaderboardPanel.Visible = true
	isLeaderboardOpen = true
end

local function HideLeaderboard()
	leaderboardPanel.Visible = false
	isLeaderboardOpen = false
end

local function ShowCompletion(data)
	completionTime.Text = FormatTime(data.time)
	completionXP.Text = "+" .. tostring(data.xpAwarded) .. " XP"
	completionPlacement.Text = "Rank: #" .. tostring(data.placement)

	completionFrame.Visible = true

	-- Auto-hide after 10 seconds
	task.delay(10, function()
		if completionFrame.Visible then
			completionFrame.Visible = false
		end
	end)
end

local function StartDailyChallenge()
	local startDaily = RemoteEvents:FindFirstChild("StartDailyChallenge")
	if startDaily then
		startDaily:FireServer()
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

startButton.MouseButton1Click:Connect(StartDailyChallenge)
leaderboardButton.MouseButton1Click:Connect(ShowLeaderboard)
closeLbButton.MouseButton1Click:Connect(HideLeaderboard)
completionClose.MouseButton1Click:Connect(function()
	completionFrame.Visible = false
end)

-- Sync event from server
local dailySync = RemoteEvents:FindFirstChild("DailyChallengeSync")
if dailySync then
	dailySync.OnClientEvent:Connect(function(data)
		if data.type == "init" or data.type == "reset" then
			challengeInfo = data.daily
			UpdateChallengeCard()
		elseif data.type == "complete" then
			ShowCompletion(data)
		end
	end)
end

-- Timer update loop
task.spawn(function()
	while true do
		task.wait(1)
		UpdateTimer()
	end
end)

-- Initial fetch
local getDailyChallenge = RemoteEvents:FindFirstChild("GetDailyChallenge")
if getDailyChallenge then
	task.spawn(function()
		local info = getDailyChallenge:InvokeServer()
		if info then
			challengeInfo = info
			UpdateChallengeCard()
		end
	end)
end

-- Button hover effects
local buttons = {startButton, leaderboardButton, closeLbButton, completionClose}
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

print("[DailyChallengeUI] Initialized")
