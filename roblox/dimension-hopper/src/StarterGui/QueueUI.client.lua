--[[
	QueueUI.client.lua
	Queue and matchmaking interface

	Features:
	- Join/leave queue
	- Dimension selection
	- Queue status display
	- Match countdown
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[QueueUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QueueUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Play button (always visible in lobby)
local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 1)
playButton.Position = UDim2.new(0.5, 0, 1, -30)
playButton.Size = UDim2.new(0, 200, 0, 60)
playButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
playButton.Font = Enum.Font.GothamBold
playButton.TextSize = 24
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Text = "PLAY"
playButton.Parent = screenGui

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 15)
playCorner.Parent = playButton

local playStroke = Instance.new("UIStroke")
playStroke.Color = Color3.fromRGB(60, 180, 60)
playStroke.Thickness = 3
playStroke.Parent = playButton

-- Dimension selection panel
local dimensionPanel = Instance.new("Frame")
dimensionPanel.Name = "DimensionPanel"
dimensionPanel.AnchorPoint = Vector2.new(0.5, 1)
dimensionPanel.Position = UDim2.new(0.5, 0, 1, -120)
dimensionPanel.Size = UDim2.new(0, 400, 0, 150)
dimensionPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
dimensionPanel.Visible = false
dimensionPanel.Parent = screenGui

local dimCorner = Instance.new("UICorner")
dimCorner.CornerRadius = UDim.new(0, 12)
dimCorner.Parent = dimensionPanel

local dimStroke = Instance.new("UIStroke")
dimStroke.Color = Color3.fromRGB(100, 80, 200)
dimStroke.Thickness = 2
dimStroke.Parent = dimensionPanel

local dimTitle = Instance.new("TextLabel")
dimTitle.Position = UDim2.new(0, 15, 0, 10)
dimTitle.Size = UDim2.new(1, -30, 0, 25)
dimTitle.BackgroundTransparency = 1
dimTitle.Font = Enum.Font.GothamBold
dimTitle.TextSize = 16
dimTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
dimTitle.Text = "Select Dimension"
dimTitle.TextXAlignment = Enum.TextXAlignment.Left
dimTitle.Parent = dimensionPanel

local dimClose = Instance.new("TextButton")
dimClose.AnchorPoint = Vector2.new(1, 0)
dimClose.Position = UDim2.new(1, -10, 0, 10)
dimClose.Size = UDim2.new(0, 25, 0, 25)
dimClose.BackgroundTransparency = 1
dimClose.Font = Enum.Font.GothamBold
dimClose.TextSize = 18
dimClose.TextColor3 = Color3.fromRGB(180, 180, 180)
dimClose.Text = "X"
dimClose.Parent = dimensionPanel

-- Dimension buttons
local dimensionContainer = Instance.new("Frame")
dimensionContainer.Position = UDim2.new(0, 15, 0, 45)
dimensionContainer.Size = UDim2.new(1, -30, 0, 90)
dimensionContainer.BackgroundTransparency = 1
dimensionContainer.Parent = dimensionPanel

local dimLayout = Instance.new("UIGridLayout")
dimLayout.CellSize = UDim2.new(0, 85, 0, 40)
dimLayout.CellPadding = UDim2.new(0, 10, 0, 5)
dimLayout.Parent = dimensionContainer

local dimensions = {
	{ id = nil, name = "Any", color = Color3.fromRGB(100, 100, 120), icon = "?" },
	{ id = "Gravity", name = "Gravity", color = Color3.fromRGB(150, 50, 255), icon = "arrow" },
	{ id = "Tiny", name = "Tiny", color = Color3.fromRGB(255, 200, 100), icon = "small" },
	{ id = "Void", name = "Void", color = Color3.fromRGB(50, 0, 80), icon = "O" },
	{ id = "Sky", name = "Sky", color = Color3.fromRGB(100, 180, 255), icon = "cloud" },
}

local dimensionButtons = {}

for _, dim in ipairs(dimensions) do
	local btn = Instance.new("TextButton")
	btn.Name = dim.name
	btn.Size = UDim2.new(0, 85, 0, 40)
	btn.BackgroundColor3 = dim.color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = dim.name
	btn.Parent = dimensionContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	dimensionButtons[dim.id or "any"] = btn
end

-- Queue status panel
local queuePanel = Instance.new("Frame")
queuePanel.Name = "QueuePanel"
queuePanel.AnchorPoint = Vector2.new(0.5, 1)
queuePanel.Position = UDim2.new(0.5, 0, 1, -30)
queuePanel.Size = UDim2.new(0, 250, 0, 80)
queuePanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
queuePanel.Visible = false
queuePanel.Parent = screenGui

local queueCorner = Instance.new("UICorner")
queueCorner.CornerRadius = UDim.new(0, 12)
queueCorner.Parent = queuePanel

local queueStroke = Instance.new("UIStroke")
queueStroke.Color = Color3.fromRGB(255, 180, 50)
queueStroke.Thickness = 2
queueStroke.Parent = queuePanel

local queueTitle = Instance.new("TextLabel")
queueTitle.Position = UDim2.new(0, 15, 0, 10)
queueTitle.Size = UDim2.new(1, -30, 0, 20)
queueTitle.BackgroundTransparency = 1
queueTitle.Font = Enum.Font.GothamBold
queueTitle.TextSize = 14
queueTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
queueTitle.Text = "Finding Match..."
queueTitle.TextXAlignment = Enum.TextXAlignment.Left
queueTitle.Parent = queuePanel

local queueStatus = Instance.new("TextLabel")
queueStatus.Name = "Status"
queueStatus.Position = UDim2.new(0, 15, 0, 32)
queueStatus.Size = UDim2.new(1, -30, 0, 18)
queueStatus.BackgroundTransparency = 1
queueStatus.Font = Enum.Font.Gotham
queueStatus.TextSize = 12
queueStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
queueStatus.Text = "Players in queue: 1"
queueStatus.TextXAlignment = Enum.TextXAlignment.Left
queueStatus.Parent = queuePanel

local cancelButton = Instance.new("TextButton")
cancelButton.Position = UDim2.new(0.5, -50, 1, -35)
cancelButton.Size = UDim2.new(0, 100, 0, 28)
cancelButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
cancelButton.Font = Enum.Font.GothamBold
cancelButton.TextSize = 12
cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelButton.Text = "Cancel"
cancelButton.Parent = queuePanel

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 6)
cancelCorner.Parent = cancelButton

-- Match found banner
local matchBanner = Instance.new("Frame")
matchBanner.Name = "MatchBanner"
matchBanner.AnchorPoint = Vector2.new(0.5, 0.5)
matchBanner.Position = UDim2.new(0.5, 0, 0.5, 0)
matchBanner.Size = UDim2.new(0, 400, 0, 150)
matchBanner.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
matchBanner.Visible = false
matchBanner.Parent = screenGui

local matchCorner = Instance.new("UICorner")
matchCorner.CornerRadius = UDim.new(0, 15)
matchCorner.Parent = matchBanner

local matchStroke = Instance.new("UIStroke")
matchStroke.Color = Color3.fromRGB(80, 200, 80)
matchStroke.Thickness = 3
matchStroke.Parent = matchBanner

local matchTitle = Instance.new("TextLabel")
matchTitle.Position = UDim2.new(0, 0, 0, 20)
matchTitle.Size = UDim2.new(1, 0, 0, 35)
matchTitle.BackgroundTransparency = 1
matchTitle.Font = Enum.Font.GothamBold
matchTitle.TextSize = 28
matchTitle.TextColor3 = Color3.fromRGB(80, 200, 80)
matchTitle.Text = "MATCH FOUND!"
matchTitle.Parent = matchBanner

local matchDimension = Instance.new("TextLabel")
matchDimension.Name = "Dimension"
matchDimension.Position = UDim2.new(0, 0, 0, 55)
matchDimension.Size = UDim2.new(1, 0, 0, 25)
matchDimension.BackgroundTransparency = 1
matchDimension.Font = Enum.Font.GothamBold
matchDimension.TextSize = 18
matchDimension.TextColor3 = Color3.fromRGB(255, 255, 255)
matchDimension.Text = "Gravity Dimension"
matchDimension.Parent = matchBanner

local matchCountdown = Instance.new("TextLabel")
matchCountdown.Name = "Countdown"
matchCountdown.Position = UDim2.new(0, 0, 0, 90)
matchCountdown.Size = UDim2.new(1, 0, 0, 40)
matchCountdown.BackgroundTransparency = 1
matchCountdown.Font = Enum.Font.GothamBold
matchCountdown.TextSize = 32
matchCountdown.TextColor3 = Color3.fromRGB(255, 180, 50)
matchCountdown.Text = "10"
matchCountdown.Parent = matchBanner

-- Loading spinner for queue
local spinnerContainer = Instance.new("Frame")
spinnerContainer.AnchorPoint = Vector2.new(1, 0.5)
spinnerContainer.Position = UDim2.new(1, -15, 0.35, 0)
spinnerContainer.Size = UDim2.new(0, 20, 0, 20)
spinnerContainer.BackgroundTransparency = 1
spinnerContainer.Parent = queuePanel

local spinner = Instance.new("ImageLabel")
spinner.Size = UDim2.new(1, 0, 1, 0)
spinner.BackgroundTransparency = 1
spinner.Image = "rbxassetid://0" -- Placeholder
spinner.Parent = spinnerContainer

-- ============================================================================
-- STATE
-- ============================================================================

local inQueue = false
local selectedDimension = nil
local currentMatch = nil

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetRemotes()
	return {
		JoinQueue = RemoteEvents:FindFirstChild("JoinQueue"),
		LeaveQueue = RemoteEvents:FindFirstChild("LeaveQueue"),
		GetQueueStatus = RemoteEvents:FindFirstChild("GetQueueStatus"),
	}
end

local function UpdateQueueDisplay(status)
	queueStatus.Text = string.format("Players in queue: %d/%d", status.queueSize, status.minPlayers)

	if status.queueSize >= status.minPlayers then
		queueTitle.Text = "Match Starting Soon..."
	else
		queueTitle.Text = "Finding Match..."
	end
end

local function ShowDimensionPanel()
	dimensionPanel.Visible = true
end

local function HideDimensionPanel()
	dimensionPanel.Visible = false
end

local function JoinQueue(dimension)
	local remotes = GetRemotes()
	if remotes.JoinQueue then
		remotes.JoinQueue:FireServer(dimension)
		inQueue = true
		selectedDimension = dimension

		playButton.Visible = false
		HideDimensionPanel()
		queuePanel.Visible = true
	end
end

local function LeaveQueue()
	local remotes = GetRemotes()
	if remotes.LeaveQueue then
		remotes.LeaveQueue:FireServer()
		inQueue = false

		queuePanel.Visible = false
		matchBanner.Visible = false
		playButton.Visible = true
	end
end

local function ShowMatchFound(data)
	currentMatch = data
	queuePanel.Visible = false
	matchBanner.Visible = true

	matchDimension.Text = data.dimension .. " Dimension"
	matchCountdown.Text = tostring(data.countdown)

	-- Animate entrance
	matchBanner.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(matchBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 400, 0, 150)
	}):Play()
end

local function UpdateMatchCountdown(countdown)
	matchCountdown.Text = tostring(countdown)

	-- Pulse animation
	TweenService:Create(matchCountdown, TweenInfo.new(0.1), {
		TextSize = 40
	}):Play()

	task.delay(0.1, function()
		TweenService:Create(matchCountdown, TweenInfo.new(0.2), {
			TextSize = 32
		}):Play()
	end)

	if countdown <= 0 then
		matchBanner.Visible = false
		playButton.Visible = false
		queuePanel.Visible = false
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

playButton.MouseButton1Click:Connect(function()
	ShowDimensionPanel()
end)

dimClose.MouseButton1Click:Connect(HideDimensionPanel)

cancelButton.MouseButton1Click:Connect(LeaveQueue)

-- Dimension buttons
for dimId, btn in pairs(dimensionButtons) do
	btn.MouseButton1Click:Connect(function()
		local dimension = dimId == "any" and nil or dimId
		JoinQueue(dimension)
	end)
end

-- Server events
local queueStatusUpdate = RemoteEvents:FindFirstChild("QueueStatusUpdate")
if queueStatusUpdate then
	queueStatusUpdate.OnClientEvent:Connect(function(status)
		if status.inQueue then
			UpdateQueueDisplay(status)
		else
			inQueue = false
			queuePanel.Visible = false
			if not matchBanner.Visible then
				playButton.Visible = true
			end
		end
	end)
end

local matchFound = RemoteEvents:FindFirstChild("MatchFound")
if matchFound then
	matchFound.OnClientEvent:Connect(function(data)
		ShowMatchFound(data)
	end)
end

local matchCountdownEvent = RemoteEvents:FindFirstChild("MatchCountdown")
if matchCountdownEvent then
	matchCountdownEvent.OnClientEvent:Connect(function(data)
		UpdateMatchCountdown(data.countdown)
	end)
end

-- Hover effects
playButton.MouseEnter:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 220, 0, 66)
	}):Play()
end)

playButton.MouseLeave:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 200, 0, 60)
	}):Play()
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		if inQueue then
			LeaveQueue()
		elseif dimensionPanel.Visible then
			HideDimensionPanel()
		else
			ShowDimensionPanel()
		end
	end
end)

-- Spinner animation
task.spawn(function()
	local rotation = 0
	while true do
		rotation = (rotation + 5) % 360
		spinnerContainer.Rotation = rotation
		task.wait(0.03)
	end
end)

print("[QueueUI] Initialized - Press Q or click PLAY to queue")
