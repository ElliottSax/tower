--[[
	StatsUI.client.lua
	Player statistics and profile display

	Features:
	- Overall stats overview
	- Personal bests display
	- Dimension-specific stats
	- Play time tracking
	- Win rate calculations
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[StatsUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Stats button
local statsButton = Instance.new("TextButton")
statsButton.Name = "StatsButton"
statsButton.AnchorPoint = Vector2.new(1, 0)
statsButton.Position = UDim2.new(1, -20, 0, 330)
statsButton.Size = UDim2.new(0, 50, 0, 50)
statsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
statsButton.Font = Enum.Font.GothamBold
statsButton.TextSize = 22
statsButton.TextColor3 = Color3.fromRGB(100, 200, 255)
statsButton.Text = "📊"
statsButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = statsButton

-- Stats panel
local panel = Instance.new("Frame")
panel.Name = "StatsPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 550, 0, 450)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(80, 80, 120)
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.Size = UDim2.new(0.5, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
titleLabel.Text = "Statistics"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = panel

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -15, 0, 12)
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Tab container
local tabContainer = Instance.new("Frame")
tabContainer.Position = UDim2.new(0, 15, 0, 55)
tabContainer.Size = UDim2.new(1, -30, 0, 30)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local tabs = {"Overview", "Racing", "Personal Bests", "Dimensions"}
local tabButtons = {}
local selectedTab = "Overview"

for i, tabName in ipairs(tabs) do
	local tab = Instance.new("TextButton")
	tab.Name = tabName
	tab.Size = UDim2.new(0, 120, 1, 0)
	tab.LayoutOrder = i
	tab.BackgroundColor3 = i == 1 and Color3.fromRGB(60, 60, 90) or Color3.fromRGB(40, 40, 55)
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 12
	tab.TextColor3 = Color3.fromRGB(200, 200, 220)
	tab.Text = tabName
	tab.Parent = tabContainer

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tab

	tabButtons[tabName] = tab
end

-- Content area
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "Content"
contentFrame.Position = UDim2.new(0, 15, 0, 95)
contentFrame.Size = UDim2.new(1, -30, 1, -110)
contentFrame.BackgroundTransparency = 1
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
contentFrame.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = contentFrame

-- ============================================================================
-- STAT CARD COMPONENTS
-- ============================================================================

local function CreateStatCard(title: string, layoutOrder: number): Frame
	local card = Instance.new("Frame")
	card.Name = title
	card.Size = UDim2.new(1, 0, 0, 0) -- Auto-size
	card.LayoutOrder = layoutOrder
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = contentFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 10)
	cardPadding.PaddingBottom = UDim.new(0, 10)
	cardPadding.PaddingLeft = UDim.new(0, 15)
	cardPadding.PaddingRight = UDim.new(0, 15)
	cardPadding.Parent = card

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 8)
	cardLayout.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.LayoutOrder = 0
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
	titleLabel.Text = string.upper(title)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = card

	return card
end

local function CreateStatRow(parent: Frame, label: string, value: string, layoutOrder: number, color: Color3?): Frame
	local row = Instance.new("Frame")
	row.Name = label
	row.Size = UDim2.new(1, 0, 0, 25)
	row.LayoutOrder = layoutOrder
	row.BackgroundTransparency = 1
	row.Parent = parent

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(0.6, 0, 1, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font = Enum.Font.Gotham
	labelText.TextSize = 14
	labelText.TextColor3 = Color3.fromRGB(180, 180, 200)
	labelText.Text = label
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = row

	local valueText = Instance.new("TextLabel")
	valueText.Name = "Value"
	valueText.AnchorPoint = Vector2.new(1, 0)
	valueText.Position = UDim2.new(1, 0, 0, 0)
	valueText.Size = UDim2.new(0.4, 0, 1, 0)
	valueText.BackgroundTransparency = 1
	valueText.Font = Enum.Font.GothamBold
	valueText.TextSize = 14
	valueText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	valueText.Text = value
	valueText.TextXAlignment = Enum.TextXAlignment.Right
	valueText.Parent = row

	return row
end

local function CreatePBRow(parent: Frame, dimension: string, time: number?, layoutOrder: number): Frame
	local colors = {
		Gravity = Color3.fromRGB(150, 50, 255),
		Tiny = Color3.fromRGB(50, 200, 50),
		Void = Color3.fromRGB(200, 80, 80),
		Sky = Color3.fromRGB(100, 180, 255),
		Marathon = Color3.fromRGB(255, 215, 0),
		Daily = Color3.fromRGB(255, 200, 100),
	}

	local timeStr = time and string.format("%d:%05.2f", math.floor(time / 60), time % 60) or "No record"
	return CreateStatRow(parent, dimension, timeStr, layoutOrder, colors[dimension])
end

-- ============================================================================
-- TAB CONTENT
-- ============================================================================

local function ClearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function FormatPlayTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

local function FormatPercent(value: number): string
	return string.format("%.1f%%", value * 100)
end

local function ShowOverviewTab(stats)
	ClearContent()

	-- General stats
	local general = CreateStatCard("General", 1)
	CreateStatRow(general, "Total Races", tostring(stats.total_races or 0), 1)
	CreateStatRow(general, "Total Wins", tostring(stats.total_wins or 0), 2, Color3.fromRGB(100, 255, 100))
	CreateStatRow(general, "Top 3 Finishes", tostring(stats.total_placements_top3 or 0), 3)
	CreateStatRow(general, "Play Time", FormatPlayTime(stats.total_play_time or 0), 4)

	-- Win rate
	local winRate = stats.total_races > 0 and (stats.total_wins or 0) / stats.total_races or 0
	CreateStatRow(general, "Win Rate", FormatPercent(winRate), 5, Color3.fromRGB(255, 200, 100))

	-- Level
	local level = CreateStatCard("Progression", 2)
	CreateStatRow(level, "Current Level", tostring(stats.current_level or 1), 1, Color3.fromRGB(100, 200, 255))
	CreateStatRow(level, "Total XP Earned", tostring(stats.total_xp_earned or 0), 2)

	-- Streaks
	local streaks = CreateStatCard("Streaks", 3)
	CreateStatRow(streaks, "Current Win Streak", tostring(stats.current_win_streak or 0), 1)
	CreateStatRow(streaks, "Best Win Streak", tostring(stats.best_win_streak or 0), 2, Color3.fromRGB(255, 200, 100))
	CreateStatRow(streaks, "Daily Challenge Streak", tostring(stats.daily_current_streak or 0), 3)

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

local function ShowRacingTab(stats)
	ClearContent()

	-- Races by dimension
	local races = CreateStatCard("Races by Dimension", 1)
	CreateStatRow(races, "Gravity", tostring(stats.races_gravity or 0), 1, Color3.fromRGB(150, 50, 255))
	CreateStatRow(races, "Tiny", tostring(stats.races_tiny or 0), 2, Color3.fromRGB(50, 200, 50))
	CreateStatRow(races, "Void", tostring(stats.races_void or 0), 3, Color3.fromRGB(200, 80, 80))
	CreateStatRow(races, "Sky", tostring(stats.races_sky or 0), 4, Color3.fromRGB(100, 180, 255))
	CreateStatRow(races, "Marathon", tostring(stats.races_marathon or 0), 5, Color3.fromRGB(255, 215, 0))

	-- Wins by dimension
	local wins = CreateStatCard("Wins by Dimension", 2)
	CreateStatRow(wins, "Gravity", tostring(stats.wins_gravity or 0), 1, Color3.fromRGB(150, 50, 255))
	CreateStatRow(wins, "Tiny", tostring(stats.wins_tiny or 0), 2, Color3.fromRGB(50, 200, 50))
	CreateStatRow(wins, "Void", tostring(stats.wins_void or 0), 3, Color3.fromRGB(200, 80, 80))
	CreateStatRow(wins, "Sky", tostring(stats.wins_sky or 0), 4, Color3.fromRGB(100, 180, 255))
	CreateStatRow(wins, "Marathon", tostring(stats.wins_marathon or 0), 5, Color3.fromRGB(255, 215, 0))

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

local function ShowPersonalBestsTab(stats)
	ClearContent()

	local pbs = stats.personal_bests or {}

	local card = CreateStatCard("Personal Best Times", 1)
	CreatePBRow(card, "Gravity", pbs.pb_gravity, 1)
	CreatePBRow(card, "Tiny", pbs.pb_tiny, 2)
	CreatePBRow(card, "Void", pbs.pb_void, 3)
	CreatePBRow(card, "Sky", pbs.pb_sky, 4)
	CreatePBRow(card, "Marathon", pbs.pb_marathon, 5)
	CreatePBRow(card, "Daily", pbs.pb_daily, 6)

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

local function ShowDimensionsTab(stats)
	ClearContent()

	-- Gravity stats
	local gravity = CreateStatCard("Gravity Dimension", 1)
	CreateStatRow(gravity, "Gravity Flips", tostring(stats.gravity_flips or 0), 1)

	-- Tiny stats
	local tiny = CreateStatCard("Tiny Dimension", 2)
	CreateStatRow(tiny, "Scale Changes", tostring(stats.scale_changes or 0), 1)

	-- Void stats
	local void = CreateStatCard("Void Dimension", 3)
	CreateStatRow(void, "Near Misses", tostring(stats.void_near_misses or 0), 1)
	CreateStatRow(void, "Platforms Escaped", tostring(stats.crumbling_platforms_escaped or 0), 2)

	-- Sky stats
	local sky = CreateStatCard("Sky Dimension", 4)
	CreateStatRow(sky, "Glide Distance", string.format("%.0f studs", stats.glide_distance or 0), 1)
	CreateStatRow(sky, "Glide Time", FormatPlayTime(stats.glide_time or 0), 2)
	CreateStatRow(sky, "Updrafts Used", tostring(stats.updrafts_used or 0), 3)

	contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local currentStats = nil

local function RefreshStats()
	local getStats = RemoteEvents:FindFirstChild("GetPlayerStats")
	if not getStats then return end

	currentStats = getStats:InvokeServer()
	if not currentStats then return end

	-- Show current tab
	if selectedTab == "Overview" then
		ShowOverviewTab(currentStats)
	elseif selectedTab == "Racing" then
		ShowRacingTab(currentStats)
	elseif selectedTab == "Personal Bests" then
		ShowPersonalBestsTab(currentStats)
	elseif selectedTab == "Dimensions" then
		ShowDimensionsTab(currentStats)
	end
end

local function SelectTab(tabName: string)
	selectedTab = tabName

	for name, button in pairs(tabButtons) do
		button.BackgroundColor3 = name == tabName
			and Color3.fromRGB(60, 60, 90)
			or Color3.fromRGB(40, 40, 55)
	end

	if currentStats then
		if tabName == "Overview" then
			ShowOverviewTab(currentStats)
		elseif tabName == "Racing" then
			ShowRacingTab(currentStats)
		elseif tabName == "Personal Bests" then
			ShowPersonalBestsTab(currentStats)
		elseif tabName == "Dimensions" then
			ShowDimensionsTab(currentStats)
		end
	end
end

local function OpenPanel()
	panel.Visible = true
	RefreshStats()
end

local function ClosePanel()
	panel.Visible = false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

statsButton.MouseButton1Click:Connect(OpenPanel)
closeButton.MouseButton1Click:Connect(ClosePanel)

for tabName, button in pairs(tabButtons) do
	button.MouseButton1Click:Connect(function()
		SelectTab(tabName)
	end)
end

-- Stats updated
local statsUpdated = RemoteEvents:FindFirstChild("StatsUpdated")
if statsUpdated then
	statsUpdated.OnClientEvent:Connect(function(data)
		if panel.Visible then
			RefreshStats()
		end
	end)
end

-- Button hover effects
local buttons = {statsButton, closeButton}
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

print("[StatsUI] Initialized")
