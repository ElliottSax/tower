--[[
	GameHUD.client.lua
	Main game HUD for Dimension Hopper

	Displays:
	- Current dimension info
	- Race position and timer
	- Boost meter (Sky Dimension)
	- Section progress
	- Void proximity warning
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[GameHUD] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE HUD
-- ============================================================================

local function CreateHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- ========================================
	-- TOP BAR (Dimension + Timer)
	-- ========================================

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundTransparency = 1
	topBar.Parent = screenGui

	-- Dimension Display
	local dimensionFrame = Instance.new("Frame")
	dimensionFrame.Name = "DimensionFrame"
	dimensionFrame.Size = UDim2.new(0, 200, 0, 50)
	dimensionFrame.Position = UDim2.new(0, 20, 0, 10)
	dimensionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	dimensionFrame.BackgroundTransparency = 0.3
	dimensionFrame.Parent = topBar

	local dimensionCorner = Instance.new("UICorner")
	dimensionCorner.CornerRadius = UDim.new(0, 8)
	dimensionCorner.Parent = dimensionFrame

	local dimensionIcon = Instance.new("TextLabel")
	dimensionIcon.Name = "Icon"
	dimensionIcon.Size = UDim2.new(0, 40, 1, 0)
	dimensionIcon.Position = UDim2.new(0, 5, 0, 0)
	dimensionIcon.BackgroundTransparency = 1
	dimensionIcon.Text = "🌀"
	dimensionIcon.TextSize = 28
	dimensionIcon.Font = Enum.Font.GothamBold
	dimensionIcon.TextColor3 = Color3.new(1, 1, 1)
	dimensionIcon.Parent = dimensionFrame

	local dimensionName = Instance.new("TextLabel")
	dimensionName.Name = "Name"
	dimensionName.Size = UDim2.new(1, -50, 1, 0)
	dimensionName.Position = UDim2.new(0, 50, 0, 0)
	dimensionName.BackgroundTransparency = 1
	dimensionName.Text = "GRAVITY"
	dimensionName.TextSize = 20
	dimensionName.Font = Enum.Font.GothamBold
	dimensionName.TextColor3 = Color3.new(1, 1, 1)
	dimensionName.TextXAlignment = Enum.TextXAlignment.Left
	dimensionName.Parent = dimensionFrame

	-- Timer Display
	local timerFrame = Instance.new("Frame")
	timerFrame.Name = "TimerFrame"
	timerFrame.Size = UDim2.new(0, 150, 0, 50)
	timerFrame.Position = UDim2.new(0.5, -75, 0, 10)
	timerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	timerFrame.BackgroundTransparency = 0.3
	timerFrame.Parent = topBar

	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0, 8)
	timerCorner.Parent = timerFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(1, 0, 1, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "00:00.00"
	timerLabel.TextSize = 26
	timerLabel.Font = Enum.Font.Code
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.Parent = timerFrame

	-- ========================================
	-- RIGHT SIDE (Position Leaderboard)
	-- ========================================

	local positionFrame = Instance.new("Frame")
	positionFrame.Name = "PositionFrame"
	positionFrame.Size = UDim2.new(0, 180, 0, 200)
	positionFrame.Position = UDim2.new(1, -200, 0, 80)
	positionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	positionFrame.BackgroundTransparency = 0.3
	positionFrame.Parent = screenGui

	local positionCorner = Instance.new("UICorner")
	positionCorner.CornerRadius = UDim.new(0, 8)
	positionCorner.Parent = positionFrame

	local positionTitle = Instance.new("TextLabel")
	positionTitle.Name = "Title"
	positionTitle.Size = UDim2.new(1, 0, 0, 30)
	positionTitle.BackgroundTransparency = 1
	positionTitle.Text = "POSITIONS"
	positionTitle.TextSize = 14
	positionTitle.Font = Enum.Font.GothamBold
	positionTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	positionTitle.Parent = positionFrame

	local positionList = Instance.new("Frame")
	positionList.Name = "List"
	positionList.Size = UDim2.new(1, -10, 1, -35)
	positionList.Position = UDim2.new(0, 5, 0, 30)
	positionList.BackgroundTransparency = 1
	positionList.Parent = positionFrame

	local positionLayout = Instance.new("UIListLayout")
	positionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	positionLayout.Padding = UDim.new(0, 2)
	positionLayout.Parent = positionList

	-- ========================================
	-- LEFT SIDE (Section Progress)
	-- ========================================

	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = "SectionFrame"
	sectionFrame.Size = UDim2.new(0, 60, 0, 200)
	sectionFrame.Position = UDim2.new(0, 20, 0.5, -100)
	sectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	sectionFrame.BackgroundTransparency = 0.3
	sectionFrame.Parent = screenGui

	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 8)
	sectionCorner.Parent = sectionFrame

	local sectionLabel = Instance.new("TextLabel")
	sectionLabel.Name = "Section"
	sectionLabel.Size = UDim2.new(1, 0, 0, 40)
	sectionLabel.Position = UDim2.new(0, 0, 0, 10)
	sectionLabel.BackgroundTransparency = 1
	sectionLabel.Text = "1"
	sectionLabel.TextSize = 32
	sectionLabel.Font = Enum.Font.GothamBold
	sectionLabel.TextColor3 = Color3.new(1, 1, 1)
	sectionLabel.Parent = sectionFrame

	local sectionSubLabel = Instance.new("TextLabel")
	sectionSubLabel.Name = "SubLabel"
	sectionSubLabel.Size = UDim2.new(1, 0, 0, 20)
	sectionSubLabel.Position = UDim2.new(0, 0, 0, 45)
	sectionSubLabel.BackgroundTransparency = 1
	sectionSubLabel.Text = "/ 20"
	sectionSubLabel.TextSize = 14
	sectionSubLabel.Font = Enum.Font.Gotham
	sectionSubLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	sectionSubLabel.Parent = sectionFrame

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 8, 0, 120)
	progressBg.Position = UDim2.new(0.5, -4, 0, 70)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	progressBg.Parent = sectionFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(1, 0, 0.05, 0)
	progressFill.Position = UDim2.new(0, 0, 0.95, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill

	-- ========================================
	-- BOTTOM (Boost Meter - Sky Dimension)
	-- ========================================

	local boostFrame = Instance.new("Frame")
	boostFrame.Name = "BoostFrame"
	boostFrame.Size = UDim2.new(0, 300, 0, 30)
	boostFrame.Position = UDim2.new(0.5, -150, 1, -60)
	boostFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	boostFrame.BackgroundTransparency = 0.3
	boostFrame.Visible = false -- Only show in Sky dimension
	boostFrame.Parent = screenGui

	local boostCorner = Instance.new("UICorner")
	boostCorner.CornerRadius = UDim.new(0, 6)
	boostCorner.Parent = boostFrame

	local boostBg = Instance.new("Frame")
	boostBg.Name = "BoostBg"
	boostBg.Size = UDim2.new(1, -20, 0, 12)
	boostBg.Position = UDim2.new(0, 10, 0.5, -6)
	boostBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	boostBg.Parent = boostFrame

	local boostBgCorner = Instance.new("UICorner")
	boostBgCorner.CornerRadius = UDim.new(0, 4)
	boostBgCorner.Parent = boostBg

	local boostFill = Instance.new("Frame")
	boostFill.Name = "Fill"
	boostFill.Size = UDim2.new(1, 0, 1, 0)
	boostFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	boostFill.Parent = boostBg

	local boostFillCorner = Instance.new("UICorner")
	boostFillCorner.CornerRadius = UDim.new(0, 4)
	boostFillCorner.Parent = boostFill

	local boostLabel = Instance.new("TextLabel")
	boostLabel.Name = "Label"
	boostLabel.Size = UDim2.new(0, 50, 1, 0)
	boostLabel.Position = UDim2.new(0, -55, 0, 0)
	boostLabel.BackgroundTransparency = 1
	boostLabel.Text = "BOOST"
	boostLabel.TextSize = 12
	boostLabel.Font = Enum.Font.GothamBold
	boostLabel.TextColor3 = Color3.new(1, 1, 1)
	boostLabel.Parent = boostFrame

	-- ========================================
	-- CENTER (Countdown / Big Messages)
	-- ========================================

	local centerFrame = Instance.new("Frame")
	centerFrame.Name = "CenterFrame"
	centerFrame.Size = UDim2.new(0, 400, 0, 200)
	centerFrame.Position = UDim2.new(0.5, -200, 0.4, -100)
	centerFrame.BackgroundTransparency = 1
	centerFrame.Visible = false
	centerFrame.Parent = screenGui

	local centerText = Instance.new("TextLabel")
	centerText.Name = "Text"
	centerText.Size = UDim2.new(1, 0, 1, 0)
	centerText.BackgroundTransparency = 1
	centerText.Text = "3"
	centerText.TextSize = 120
	centerText.Font = Enum.Font.GothamBold
	centerText.TextColor3 = Color3.new(1, 1, 1)
	centerText.TextStrokeTransparency = 0.5
	centerText.TextStrokeColor3 = Color3.new(0, 0, 0)
	centerText.Parent = centerFrame

	return screenGui
end

local HUD = CreateHUD()

-- ============================================================================
-- HUD UPDATE FUNCTIONS
-- ============================================================================

local currentSection = 0
local totalSections = 20
local raceStartTime = 0
local isRacing = false
local currentDimension = nil

local function UpdateDimension(dimensionName, icon)
	local dimensionFrame = HUD.TopBar.DimensionFrame
	dimensionFrame.Name.Text = string.upper(dimensionName or "LOBBY")
	dimensionFrame.Icon.Text = icon or "🎮"

	currentDimension = dimensionName

	-- Show/hide boost meter for Sky dimension
	HUD.BoostFrame.Visible = (dimensionName == "Sky")

	-- Update dimension frame color
	local colors = {
		Gravity = Color3.fromRGB(138, 43, 226),
		Tiny = Color3.fromRGB(34, 139, 34),
		Void = Color3.fromRGB(139, 0, 0),
		Sky = Color3.fromRGB(135, 206, 235),
	}

	local color = colors[dimensionName] or Color3.fromRGB(100, 100, 100)
	TweenService:Create(dimensionFrame, TweenInfo.new(0.3), {
		BackgroundColor3 = color
	}):Play()
end

local function UpdateSection(section)
	currentSection = section

	local sectionFrame = HUD.SectionFrame
	sectionFrame.Section.Text = tostring(section)

	-- Update progress bar
	local progress = section / totalSections
	local fill = sectionFrame.ProgressBg.Fill

	TweenService:Create(fill, TweenInfo.new(0.3), {
		Size = UDim2.new(1, 0, progress, 0),
		Position = UDim2.new(0, 0, 1 - progress, 0),
	}):Play()
end

local function UpdatePositions(positions)
	local list = HUD.PositionFrame.List

	-- Clear existing
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add position entries
	for i, pos in ipairs(positions) do
		if i > 8 then break end -- Max 8 visible

		local entry = Instance.new("Frame")
		entry.Name = "Position" .. i
		entry.Size = UDim2.new(1, 0, 0, 20)
		entry.BackgroundTransparency = 1
		entry.LayoutOrder = i
		entry.Parent = list

		local posNum = Instance.new("TextLabel")
		posNum.Size = UDim2.new(0, 25, 1, 0)
		posNum.BackgroundTransparency = 1
		posNum.Text = pos.Finished and "🏁" or tostring(pos.Position or i)
		posNum.TextSize = 14
		posNum.Font = Enum.Font.GothamBold
		posNum.TextColor3 = pos.UserId == player.UserId
			and Color3.fromRGB(255, 215, 0)
			or Color3.fromRGB(200, 200, 200)
		posNum.TextXAlignment = Enum.TextXAlignment.Left
		posNum.Parent = entry

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -30, 1, 0)
		nameLabel.Position = UDim2.new(0, 30, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = pos.Name or "Player"
		nameLabel.TextSize = 12
		nameLabel.Font = pos.UserId == player.UserId and Enum.Font.GothamBold or Enum.Font.Gotham
		nameLabel.TextColor3 = pos.UserId == player.UserId
			and Color3.fromRGB(255, 215, 0)
			or Color3.new(1, 1, 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = entry
	end
end

local function UpdateBoostMeter(amount)
	local fill = HUD.BoostFrame.BoostBg.Fill
	local percent = math.clamp(amount / 100, 0, 1)

	TweenService:Create(fill, TweenInfo.new(0.1), {
		Size = UDim2.new(percent, 0, 1, 0)
	}):Play()

	-- Color based on amount
	local color
	if percent > 0.5 then
		color = Color3.fromRGB(255, 200, 50)
	elseif percent > 0.25 then
		color = Color3.fromRGB(255, 150, 50)
	else
		color = Color3.fromRGB(255, 80, 50)
	end

	fill.BackgroundColor3 = color
end

local function ShowCountdown(number)
	local centerFrame = HUD.CenterFrame
	local centerText = centerFrame.Text

	centerFrame.Visible = true
	centerText.Text = tostring(number)
	centerText.TextSize = 20

	-- Pop animation
	TweenService:Create(centerText, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 120
	}):Play()

	task.delay(0.8, function()
		TweenService:Create(centerText, TweenInfo.new(0.2), {
			TextSize = 60,
			TextTransparency = 1,
		}):Play()
	end)
end

local function ShowGo()
	local centerFrame = HUD.CenterFrame
	local centerText = centerFrame.Text

	centerFrame.Visible = true
	centerText.Text = "GO!"
	centerText.TextSize = 20
	centerText.TextTransparency = 0
	centerText.TextColor3 = Color3.fromRGB(100, 255, 100)

	TweenService:Create(centerText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 140
	}):Play()

	task.delay(1, function()
		TweenService:Create(centerText, TweenInfo.new(0.3), {
			TextTransparency = 1
		}):Play()

		task.delay(0.3, function()
			centerFrame.Visible = false
			centerText.TextColor3 = Color3.new(1, 1, 1)
		end)
	end)
end

local function HideCenter()
	HUD.CenterFrame.Visible = false
end

-- ============================================================================
-- TIMER UPDATE
-- ============================================================================

RunService.Heartbeat:Connect(function()
	if isRacing and raceStartTime > 0 then
		local elapsed = tick() - raceStartTime
		local minutes = math.floor(elapsed / 60)
		local seconds = elapsed % 60

		HUD.TopBar.TimerFrame.Timer.Text = string.format("%02d:%05.2f", minutes, seconds)
	end
end)

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

-- Race state
if RemoteEvents:FindFirstChild("RaceState") then
	RemoteEvents.RaceState.OnClientEvent:Connect(function(state, data)
		if state == "RaceStart" then
			isRacing = true
			raceStartTime = tick()
			ShowGo()

			if data and data.Dimension then
				local icons = {
					Gravity = "🌀",
					Tiny = "🐜",
					Void = "👁️",
					Sky = "🦅",
				}
				UpdateDimension(data.Dimension, icons[data.Dimension])
			end

		elseif state == "Results" then
			isRacing = false

		elseif state == "Idle" then
			isRacing = false
			raceStartTime = 0
			HUD.TopBar.TimerFrame.Timer.Text = "00:00.00"
			UpdateDimension("LOBBY", "🎮")
		end
	end)
end

-- Countdown
if RemoteEvents:FindFirstChild("RaceCountdown") then
	RemoteEvents.RaceCountdown.OnClientEvent:Connect(function(count)
		ShowCountdown(count)
	end)
end

-- Positions
if RemoteEvents:FindFirstChild("RacePositions") then
	RemoteEvents.RacePositions.OnClientEvent:Connect(function(positions)
		UpdatePositions(positions)
	end)
end

-- Checkpoint
if RemoteEvents:FindFirstChild("CheckpointReached") then
	RemoteEvents.CheckpointReached.OnClientEvent:Connect(function(data)
		if data and data.Section then
			UpdateSection(data.Section)
		end
	end)
end

-- Boost meter
if RemoteEvents:FindFirstChild("BoostMeterUpdate") then
	RemoteEvents.BoostMeterUpdate.OnClientEvent:Connect(function(amount)
		UpdateBoostMeter(amount)
	end)
end

-- Dimension change
if RemoteEvents:FindFirstChild("DimensionChange") then
	RemoteEvents.DimensionChange.OnClientEvent:Connect(function(dimensionName)
		local icons = {
			Gravity = "🌀",
			Tiny = "🐜",
			Void = "👁️",
			Sky = "🦅",
		}
		UpdateDimension(dimensionName, icons[dimensionName])
	end)
end

-- ============================================================================
-- INITIAL STATE
-- ============================================================================

UpdateDimension("LOBBY", "🎮")
UpdateSection(0)
UpdateBoostMeter(100)

print("[GameHUD] HUD initialized")
