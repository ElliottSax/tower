--[[
	LeaderboardUI.lua
	Displays global leaderboards

	Features:
	- Press 'L' to toggle leaderboard
	- 3 tabs: Highest Stage, Towers Completed, Total Coins
	- Shows top 100 players
	- Highlights current player (if in top 100)
	- Auto-refreshes every 60 seconds
	- Scrollable list
	- Shows rank, name, value

	Week 3: Full implementation
	Week 4+: Add daily/weekly tabs, friends leaderboard
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
	warn("[LeaderboardUI] RemoteEvents folder not found!")
	return
end

local getLeaderboardFunction = remoteFolder:WaitForChild("GetLeaderboard", 10)
if not getLeaderboardFunction then
	warn("[LeaderboardUI] GetLeaderboard RemoteFunction not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local REFRESH_INTERVAL = 60 -- Refresh every 60 seconds
local LEADERBOARD_TYPES = {
	{Id = "HighestStage", Name = "🏔️ HIGHEST STAGE", Suffix = ""},
	{Id = "TowersCompleted", Name = "🏆 TOWERS COMPLETED", Suffix = ""},
	{Id = "TotalCoins", Name = "💰 TOTAL COINS", Suffix = ""},
}

-- ============================================================================
-- STATE
-- ============================================================================

local isLeaderboardOpen = false
local currentTab = "HighestStage"
local leaderboardData = {}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background (blur/darken screen)
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.5
background.BorderSizePixel = 0
background.Visible = false
background.Parent = screenGui

-- Leaderboard Frame (center-left)
local leaderboardFrame = Instance.new("Frame")
leaderboardFrame.Name = "LeaderboardFrame"
leaderboardFrame.AnchorPoint = Vector2.new(0, 0.5)
leaderboardFrame.Position = UDim2.new(0, 50, 0.5, 0)
leaderboardFrame.Size = UDim2.new(0, 500, 0, 700)
leaderboardFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
leaderboardFrame.BorderSizePixel = 0
leaderboardFrame.Visible = false
leaderboardFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = leaderboardFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 3
stroke.Parent = leaderboardFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 28
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.Text = "🏆 LEADERBOARD 🏆"
titleLabel.Parent = leaderboardFrame

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
closeButton.Parent = leaderboardFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 10, 0, 70)
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = leaderboardFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

-- Leaderboard List (ScrollingFrame)
local leaderboardList = Instance.new("ScrollingFrame")
leaderboardList.Name = "LeaderboardList"
leaderboardList.Position = UDim2.new(0, 10, 0, 120)
leaderboardList.Size = UDim2.new(1, -20, 1, -130)
leaderboardList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
leaderboardList.BackgroundTransparency = 0.5
leaderboardList.BorderSizePixel = 0
leaderboardList.ScrollBarThickness = 8
leaderboardList.Parent = leaderboardFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 12)
listCorner.Parent = leaderboardList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = leaderboardList

-- ============================================================================
-- CREATE TAB BUTTONS
-- ============================================================================

local tabButtons = {}

local function createTabButton(leaderboardType)
	local button = Instance.new("TextButton")
	button.Name = leaderboardType.Id .. "Tab"
	button.Size = UDim2.new(0, 150, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.Text = leaderboardType.Name
	button.AutoButtonColor = false
	button.Parent = tabContainer

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	tabButtons[leaderboardType.Id] = button

	return button
end

-- ============================================================================
-- CREATE LEADERBOARD ENTRY
-- ============================================================================

local function createLeaderboardEntry(rank: number, playerName: string, value: number, isCurrentPlayer: boolean)
	local entry = Instance.new("Frame")
	entry.Name = "Entry" .. rank
	entry.Size = UDim2.new(1, 0, 0, 40)
	entry.BackgroundColor3 = isCurrentPlayer
		and Color3.fromRGB(255, 215, 0, 0.2) -- Gold highlight for player
		or Color3.fromRGB(40, 40, 40)
	entry.BorderSizePixel = 0
	entry.LayoutOrder = rank
	entry.Parent = leaderboardList

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry

	-- Rank Label
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Position = UDim2.new(0, 10, 0, 0)
	rankLabel.Size = UDim2.new(0, 40, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextSize = 18
	rankLabel.TextColor3 = getRankColor(rank)
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Text = "#" .. rank
	rankLabel.Parent = entry

	-- Player Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 60, 0, 0)
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = isCurrentPlayer and Enum.Font.GothamBold or Enum.Font.Gotham
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = isCurrentPlayer
		and Color3.fromRGB(255, 215, 0)
		or Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = playerName
	nameLabel.Parent = entry

	-- Value Label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valueLabel.Size = UDim2.new(0.4, -10, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 18
	valueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = formatNumber(value)
	valueLabel.Parent = entry

	return entry
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function getRankColor(rank: number): Color3
	if rank == 1 then
		return Color3.fromRGB(255, 215, 0) -- Gold
	elseif rank == 2 then
		return Color3.fromRGB(192, 192, 192) -- Silver
	elseif rank == 3 then
		return Color3.fromRGB(205, 127, 50) -- Bronze
	else
		return Color3.fromRGB(200, 200, 200) -- Gray
	end
end

function formatNumber(num: number): string
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- ============================================================================
-- UPDATE LEADERBOARD
-- ============================================================================

local function updateLeaderboard(leaderboardType: string)
	-- Clear existing entries
	for _, child in ipairs(leaderboardList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get leaderboard data
	local success, data = pcall(function()
		return getLeaderboardFunction:InvokeServer(leaderboardType)
	end)

	if not success or not data then
		warn("[LeaderboardUI] Failed to get leaderboard:", data)
		return
	end

	leaderboardData[leaderboardType] = data

	-- Create entries
	for _, entry in ipairs(data) do
		local isCurrentPlayer = entry.UserId == player.UserId

		createLeaderboardEntry(
			entry.Rank,
			entry.PlayerName,
			entry.Value,
			isCurrentPlayer
		)
	end

	-- Update canvas size
	leaderboardList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)

	print(string.format(
		"[LeaderboardUI] Updated %s leaderboard (%d entries)",
		leaderboardType,
		#data
	))
end

-- ============================================================================
-- TAB SWITCHING
-- ============================================================================

local function switchTab(leaderboardType: string)
	currentTab = leaderboardType

	-- Update tab button visuals
	for id, button in pairs(tabButtons) do
		if id == leaderboardType then
			button.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			button.TextColor3 = Color3.fromRGB(0, 0, 0)
		else
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			button.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	-- Update leaderboard
	updateLeaderboard(leaderboardType)
end

-- ============================================================================
-- LEADERBOARD TOGGLE
-- ============================================================================

local function openLeaderboard()
	isLeaderboardOpen = true
	background.Visible = true
	leaderboardFrame.Visible = true

	-- Refresh current tab
	updateLeaderboard(currentTab)

	print("[LeaderboardUI] Leaderboard opened")
end

local function closeLeaderboard()
	isLeaderboardOpen = false
	background.Visible = false
	leaderboardFrame.Visible = false

	print("[LeaderboardUI] Leaderboard closed")
end

local function toggleLeaderboard()
	if isLeaderboardOpen then
		closeLeaderboard()
	else
		openLeaderboard()
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.L then
		toggleLeaderboard()
	elseif input.KeyCode == Enum.KeyCode.Escape and isLeaderboardOpen then
		closeLeaderboard()
	end
end)

-- Close button
closeButton.MouseButton1Click:Connect(closeLeaderboard)

-- Background click to close
background.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closeLeaderboard()
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Create tab buttons
for _, leaderboardType in ipairs(LEADERBOARD_TYPES) do
	local button = createTabButton(leaderboardType)

	button.MouseButton1Click:Connect(function()
		switchTab(leaderboardType.Id)
	end)
end

-- Set initial tab
switchTab(LEADERBOARD_TYPES[1].Id)

-- Auto-refresh loop
task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL)

		if isLeaderboardOpen then
			updateLeaderboard(currentTab)
		end
	end
end)

-- Update canvas size when content changes
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	leaderboardList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

print("[LeaderboardUI] Initialized (Press 'L' to open)")
