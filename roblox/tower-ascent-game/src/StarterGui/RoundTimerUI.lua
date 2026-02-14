--[[
	RoundTimerUI.lua
	Displays round state and timer in top-right corner

	Features:
	- Shows current round state (Intermission, Starting, InProgress, Ended)
	- Displays countdown timer
	- Color-coded states (blue, yellow, green, red)
	- Auto-updates from server RemoteEvents

	Week 2: Full implementation
	Week 3+: Add animations, sound effects
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[RoundTimerUI] RemoteEvents folder not found!")
	return
end

local roundStateValue = remoteFolder:WaitForChild("RoundState", 10)
local roundTimerValue = remoteFolder:WaitForChild("RoundTimer", 10)
local roundNumberValue = remoteFolder:WaitForChild("RoundNumber", 10)

if not roundStateValue or not roundTimerValue or not roundNumberValue then
	warn("[RoundTimerUI] Missing RemoteEvent values!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundTimerUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Frame (top-right corner)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -20, 0, 20)
mainFrame.Size = UDim2.new(0, 250, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2
stroke.Transparency = 0.7
stroke.Parent = mainFrame

-- State Label
local stateLabel = Instance.new("TextLabel")
stateLabel.Name = "StateLabel"
stateLabel.Position = UDim2.new(0, 0, 0, 10)
stateLabel.Size = UDim2.new(1, 0, 0, 30)
stateLabel.BackgroundTransparency = 1
stateLabel.Font = Enum.Font.GothamBold
stateLabel.TextSize = 20
stateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
stateLabel.Text = "INTERMISSION"
stateLabel.Parent = mainFrame

-- Timer Label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Position = UDim2.new(0, 0, 0, 45)
timerLabel.Size = UDim2.new(1, 0, 0, 35)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 32
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Text = "0:00"
timerLabel.Parent = mainFrame

-- Round Number Label (small, bottom)
local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.Position = UDim2.new(0, 0, 1, -20)
roundLabel.Size = UDim2.new(1, 0, 0, 15)
roundLabel.BackgroundTransparency = 1
roundLabel.Font = Enum.Font.Gotham
roundLabel.TextSize = 12
roundLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
roundLabel.Text = "Round #0"
roundLabel.Parent = mainFrame

-- ============================================================================
-- STATE COLORS
-- ============================================================================

local StateColors = {
	Intermission = Color3.fromRGB(52, 152, 219),   -- Blue
	Starting = Color3.fromRGB(241, 196, 15),       -- Yellow
	InProgress = Color3.fromRGB(46, 204, 113),     -- Green
	Ended = Color3.fromRGB(231, 76, 60),           -- Red
}

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", minutes, secs)
end

local function updateState(newState: string)
	stateLabel.Text = string.upper(newState)

	-- Update color
	local color = StateColors[newState] or Color3.fromRGB(255, 255, 255)
	stroke.Color = color
	stateLabel.TextColor3 = color

	print(string.format("[RoundTimerUI] State updated: %s", newState))
end

local function updateTimer(seconds: number)
	timerLabel.Text = formatTime(seconds)

	-- Flash when time is low (last 10 seconds in InProgress)
	if roundStateValue.Value == "InProgress" and seconds <= 10 and seconds > 0 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function updateRoundNumber(roundNumber: number)
	roundLabel.Text = string.format("Round #%d", roundNumber)
end

-- ============================================================================
-- LISTEN FOR CHANGES
-- ============================================================================

-- Initial values
updateState(roundStateValue.Value)
updateTimer(roundTimerValue.Value)
updateRoundNumber(roundNumberValue.Value)

-- Listen for changes
roundStateValue.Changed:Connect(updateState)
roundTimerValue.Changed:Connect(updateTimer)
roundNumberValue.Changed:Connect(updateRoundNumber)

print("[RoundTimerUI] Initialized")
