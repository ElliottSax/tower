--[[
	StatisticsUI.lua
	Displays player statistics (session + all-time)

	Features:
	- Press 'T' to toggle statistics
	- 2 tabs: Session Stats, All-Time Stats
	- Displays:
	  * Playtime
	  * Jumps
	  * Deaths
	  * Rounds played
	  * Coins earned
	  * Highest stage
	  * Distance traveled
	  * Towers completed (all-time only)
	- Auto-refreshes every 5 seconds
	- Formatted numbers and times

	Week 4: Full implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[StatisticsUI] RemoteEvents folder not found!")
	return
end

local getStatisticsFunction = remoteFolder:WaitForChild("GetStatistics", 10)
if not getStatisticsFunction then
	warn("[StatisticsUI] GetStatistics RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local REFRESH_INTERVAL = 5 -- Refresh every 5 seconds

-- ============================================================================
-- STATE
-- ============================================================================

local isStatsOpen = false
local currentTab = "Session"
local stats = {
	Session = {},
	AllTime = {},
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatisticsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.5
background.BorderSizePixel = 0
background.Visible = false
background.Parent = screenGui

-- Stats Frame (center-right)
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.AnchorPoint = Vector2.new(1, 0.5)
statsFrame.Position = UDim2.new(1, -50, 0.5, 0)
statsFrame.Size = UDim2.new(0, 450, 0, 600)
statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false
statsFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = statsFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 200, 255)
stroke.Thickness = 3
stroke.Parent = statsFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 28
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
titleLabel.Text = "📊 STATISTICS 📊"
titleLabel.Parent = statsFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "✕"
closeButton.Parent = statsFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 10, 0, 70)
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = statsFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabContainer

-- Stats Display (ScrollingFrame)
local statsDisplay = Instance.new("ScrollingFrame")
statsDisplay.Name = "StatsDisplay"
statsDisplay.Position = UDim2.new(0, 10, 0, 120)
statsDisplay.Size = UDim2.new(1, -20, 1, -130)
statsDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statsDisplay.BackgroundTransparency = 0.5
statsDisplay.BorderSizePixel = 0
statsDisplay.ScrollBarThickness = 8
statsDisplay.Parent = statsFrame

local displayCorner = Instance.new("UICorner")
displayCorner.CornerRadius = UDim.new(0, 12)
displayCorner.Parent = statsDisplay

local displayLayout = Instance.new("UIListLayout")
displayLayout.SortOrder = Enum.SortOrder.LayoutOrder
displayLayout.Padding = UDim.new(0, 8)
displayLayout.Parent = statsDisplay

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function formatTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

local function formatNumber(num: number): string
	local formatted = tostring(math.floor(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function formatDistance(studs: number): string
	if studs >= 1000 then
		return string.format("%.1fk studs", studs / 1000)
	else
		return string.format("%d studs", math.floor(studs))
	end
end

-- ============================================================================
-- CREATE STAT ENTRY
-- ============================================================================

local function createStatEntry(name: string, value: string, icon: string, layoutOrder: number)
	local entry = Instance.new("Frame")
	entry.Name = name .. "Entry"
	entry.Size = UDim2.new(1, 0, 0, 50)
	entry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	entry.BorderSizePixel = 0
	entry.LayoutOrder = layoutOrder
	entry.Parent = statsDisplay

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 10)
	entryCorner.Parent = entry

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Position = UDim2.new(0, 15, 0, 0)
	iconLabel.Size = UDim2.new(0, 40, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 24
	iconLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	iconLabel.Text = icon
	iconLabel.Parent = entry

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 65, 0, 0)
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = name
	nameLabel.Parent = entry

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.Size = UDim2.new(0.5, -15, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 18
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = value
	valueLabel.Parent = entry

	return entry
end

-- ============================================================================
-- CREATE TAB BUTTONS
-- ============================================================================

local tabButtons = {}

local function createTabButton(name: string, text: string)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(0, 200, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.Text = text
	button.AutoButtonColor = false
	button.Parent = tabContainer

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	tabButtons[name] = button

	return button
end

-- ============================================================================
-- UPDATE STATISTICS
-- ============================================================================

local function updateStatistics(tabType: string)
	-- Clear existing stats
	for _, child in ipairs(statsDisplay:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get statistics from server
	local success, result = pcall(function()
		return getStatisticsFunction:InvokeServer()
	end)

	if not success or not result then
		warn("[StatisticsUI] Failed to get statistics:", result)
		return
	end

	stats = result

	local data = tabType == "Session" and stats.Session or stats.AllTime

	if tabType == "Session" then
		-- Session stats
		createStatEntry("Playtime", formatTime(data.Playtime or 0), "⏱️", 1)
		createStatEntry("Jumps", formatNumber(data.Jumps or 0), "🦘", 2)
		createStatEntry("Deaths", formatNumber(data.Deaths or 0), "💀", 3)
		createStatEntry("Rounds Played", formatNumber(data.RoundsPlayed or 0), "🔄", 4)
		createStatEntry("Coins Earned", formatNumber(data.CoinsEarned or 0), "💰", 5)
		createStatEntry("Highest Stage", formatNumber(data.HighestStage or 0), "🏔️", 6)
		createStatEntry("Distance Traveled", formatDistance(data.DistanceTraveled or 0), "📏", 7)
	else
		-- All-time stats
		createStatEntry("Total Playtime", formatTime(data.TotalPlaytime or 0), "⏱️", 1)
		createStatEntry("Total Jumps", formatNumber(data.TotalJumps or 0), "🦘", 2)
		createStatEntry("Total Deaths", formatNumber(data.TotalDeaths or 0), "💀", 3)
		createStatEntry("Rounds Played", formatNumber(data.RoundsPlayed or 0), "🔄", 4)
		createStatEntry("Highest Stage", formatNumber(data.HighestStage or 0), "🏔️", 5)
		createStatEntry("Towers Completed", formatNumber(data.TowersCompleted or 0), "🏆", 6)
		createStatEntry("Total Coins Earned", formatNumber(data.TotalCoinsEarned or 0), "💰", 7)
	end

	-- Update canvas size
	statsDisplay.CanvasSize = UDim2.new(0, 0, 0, displayLayout.AbsoluteContentSize.Y + 10)
end

-- ============================================================================
-- TAB SWITCHING
-- ============================================================================

local function switchTab(tabType: string)
	currentTab = tabType

	-- Update tab button visuals
	for name, button in pairs(tabButtons) do
		if name == tabType then
			button.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
			button.TextColor3 = Color3.fromRGB(0, 0, 0)
		else
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			button.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	-- Update statistics
	updateStatistics(tabType)
end

-- ============================================================================
-- STATISTICS TOGGLE
-- ============================================================================

local function openStatistics()
	isStatsOpen = true
	background.Visible = true
	statsFrame.Visible = true

	-- Refresh statistics
	updateStatistics(currentTab)

	print("[StatisticsUI] Statistics opened")
end

local function closeStatistics()
	isStatsOpen = false
	background.Visible = false
	statsFrame.Visible = false

	print("[StatisticsUI] Statistics closed")
end

local function toggleStatistics()
	if isStatsOpen then
		closeStatistics()
	else
		openStatistics()
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.T then
		toggleStatistics()
	elseif input.KeyCode == Enum.KeyCode.Escape and isStatsOpen then
		closeStatistics()
	end
end)

-- Close button
closeButton.MouseButton1Click:Connect(closeStatistics)

-- Background click to close
background.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closeStatistics()
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Create tab buttons
local sessionTab = createTabButton("Session", "📅 SESSION")
local allTimeTab = createTabButton("AllTime", "🏆 ALL-TIME")

sessionTab.MouseButton1Click:Connect(function()
	switchTab("Session")
end)

allTimeTab.MouseButton1Click:Connect(function()
	switchTab("AllTime")
end)

-- Set initial tab
switchTab("Session")

-- Auto-refresh loop
task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL)

		if isStatsOpen then
			updateStatistics(currentTab)
		end
	end
end)

-- Update canvas size when content changes
displayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	statsDisplay.CanvasSize = UDim2.new(0, 0, 0, displayLayout.AbsoluteContentSize.Y + 10)
end)

print("[StatisticsUI] Initialized (Press 'T' to open)")
