--[[
	AchievementUI.client.lua
	Client UI for achievements

	Features:
	- Achievement unlock notification
	- Achievement list/browser
	- Progress tracking display
	- Category filtering
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[AchievementUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CATEGORY COLORS
-- ============================================================================

local CATEGORY_COLORS = {
	Progression = Color3.fromRGB(100, 200, 100),
	Racing = Color3.fromRGB(255, 150, 50),
	Gravity = Color3.fromRGB(150, 50, 255),
	Tiny = Color3.fromRGB(50, 200, 50),
	Void = Color3.fromRGB(150, 40, 40),
	Sky = Color3.fromRGB(100, 180, 255),
	Daily = Color3.fromRGB(255, 200, 100),
	Secret = Color3.fromRGB(200, 100, 255),
	Special = Color3.fromRGB(255, 215, 0),
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AchievementUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 150 -- Above tutorial
screenGui.Parent = playerGui

-- Unlock notification (pops in from right)
local notification = Instance.new("Frame")
notification.Name = "Notification"
notification.AnchorPoint = Vector2.new(1, 0)
notification.Position = UDim2.new(1, 350, 0, 200) -- Start off screen
notification.Size = UDim2.new(0, 320, 0, 80)
notification.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
notification.Parent = screenGui

local notificationCorner = Instance.new("UICorner")
notificationCorner.CornerRadius = UDim.new(0, 10)
notificationCorner.Parent = notification

local notificationStroke = Instance.new("UIStroke")
notificationStroke.Color = Color3.fromRGB(255, 215, 0)
notificationStroke.Thickness = 2
notificationStroke.Parent = notification

-- Achievement icon background
local iconBg = Instance.new("Frame")
iconBg.Name = "IconBg"
iconBg.Position = UDim2.new(0, 10, 0.5, -25)
iconBg.Size = UDim2.new(0, 50, 0, 50)
iconBg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
iconBg.Parent = notification

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = iconBg

local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "Icon"
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextSize = 28
iconLabel.TextColor3 = Color3.fromRGB(30, 30, 45)
iconLabel.Text = "★"
iconLabel.Parent = iconBg

-- Unlocked label
local unlockedLabel = Instance.new("TextLabel")
unlockedLabel.Name = "Unlocked"
unlockedLabel.Position = UDim2.new(0, 70, 0, 8)
unlockedLabel.Size = UDim2.new(1, -80, 0, 16)
unlockedLabel.BackgroundTransparency = 1
unlockedLabel.Font = Enum.Font.GothamBold
unlockedLabel.TextSize = 11
unlockedLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
unlockedLabel.Text = "ACHIEVEMENT UNLOCKED!"
unlockedLabel.TextXAlignment = Enum.TextXAlignment.Left
unlockedLabel.Parent = notification

-- Achievement name
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "Name"
nameLabel.Position = UDim2.new(0, 70, 0, 25)
nameLabel.Size = UDim2.new(1, -80, 0, 22)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 18
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Text = "Achievement Name"
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = notification

-- XP reward
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XP"
xpLabel.Position = UDim2.new(0, 70, 0, 50)
xpLabel.Size = UDim2.new(1, -80, 0, 18)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.Gotham
xpLabel.TextSize = 14
xpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
xpLabel.Text = "+100 XP"
xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Parent = notification

-- Achievements button (to open browser)
local achievementsButton = Instance.new("TextButton")
achievementsButton.Name = "AchievementsButton"
achievementsButton.AnchorPoint = Vector2.new(1, 0)
achievementsButton.Position = UDim2.new(1, -20, 0, 210)
achievementsButton.Size = UDim2.new(0, 50, 0, 50)
achievementsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
achievementsButton.Font = Enum.Font.GothamBold
achievementsButton.TextSize = 24
achievementsButton.TextColor3 = Color3.fromRGB(255, 215, 0)
achievementsButton.Text = "★"
achievementsButton.Parent = screenGui

local achieveCorner = Instance.new("UICorner")
achieveCorner.CornerRadius = UDim.new(0, 10)
achieveCorner.Parent = achievementsButton

-- Achievement browser panel
local browserPanel = Instance.new("Frame")
browserPanel.Name = "Browser"
browserPanel.AnchorPoint = Vector2.new(0.5, 0.5)
browserPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
browserPanel.Size = UDim2.new(0, 600, 0, 450)
browserPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
browserPanel.Visible = false
browserPanel.Parent = screenGui

local browserCorner = Instance.new("UICorner")
browserCorner.CornerRadius = UDim.new(0, 12)
browserCorner.Parent = browserPanel

local browserStroke = Instance.new("UIStroke")
browserStroke.Color = Color3.fromRGB(80, 80, 120)
browserStroke.Thickness = 2
browserStroke.Parent = browserPanel

-- Browser title
local browserTitle = Instance.new("TextLabel")
browserTitle.Name = "Title"
browserTitle.Position = UDim2.new(0, 20, 0, 15)
browserTitle.Size = UDim2.new(0.5, 0, 0, 30)
browserTitle.BackgroundTransparency = 1
browserTitle.Font = Enum.Font.GothamBold
browserTitle.TextSize = 24
browserTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
browserTitle.Text = "Achievements"
browserTitle.TextXAlignment = Enum.TextXAlignment.Left
browserTitle.Parent = browserPanel

-- Progress counter
local progressCounter = Instance.new("TextLabel")
progressCounter.Name = "Progress"
progressCounter.AnchorPoint = Vector2.new(1, 0)
progressCounter.Position = UDim2.new(1, -60, 0, 15)
progressCounter.Size = UDim2.new(0, 150, 0, 30)
progressCounter.BackgroundTransparency = 1
progressCounter.Font = Enum.Font.Gotham
progressCounter.TextSize = 16
progressCounter.TextColor3 = Color3.fromRGB(150, 150, 180)
progressCounter.Text = "0/25 Unlocked"
progressCounter.TextXAlignment = Enum.TextXAlignment.Right
progressCounter.Parent = browserPanel

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
closeButton.Parent = browserPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Category tabs
local tabContainer = Instance.new("Frame")
tabContainer.Name = "Tabs"
tabContainer.Position = UDim2.new(0, 15, 0, 55)
tabContainer.Size = UDim2.new(1, -30, 0, 30)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = browserPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

-- Category buttons
local categories = {"All", "Progression", "Racing", "Gravity", "Tiny", "Void", "Sky", "Daily", "Special"}
local categoryButtons = {}
local selectedCategory = "All"

for i, category in ipairs(categories) do
	local tab = Instance.new("TextButton")
	tab.Name = category
	tab.Size = UDim2.new(0, 70, 1, 0)
	tab.LayoutOrder = i
	tab.BackgroundColor3 = i == 1 and Color3.fromRGB(60, 60, 90) or Color3.fromRGB(40, 40, 55)
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 11
	tab.TextColor3 = Color3.fromRGB(200, 200, 220)
	tab.Text = category
	tab.Parent = tabContainer

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tab

	categoryButtons[category] = tab
end

-- Scroll frame for achievements
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "AchievementsList"
scrollFrame.Position = UDim2.new(0, 15, 0, 95)
scrollFrame.Size = UDim2.new(1, -30, 1, -110)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
scrollFrame.Parent = browserPanel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 270, 0, 70)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local notificationQueue = {}
local isShowingNotification = false

local function ShowNotification(achievement, rewardXP)
	nameLabel.Text = achievement.name
	xpLabel.Text = rewardXP and ("+" .. tostring(rewardXP) .. " XP") or ""

	local categoryColor = CATEGORY_COLORS[achievement.category] or Color3.fromRGB(255, 215, 0)
	iconBg.BackgroundColor3 = categoryColor
	notificationStroke.Color = categoryColor

	-- Slide in
	notification.Position = UDim2.new(1, 350, 0, 200)
	TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(1, -20, 0, 200)
	}):Play()

	-- Wait and slide out
	task.wait(4)

	TweenService:Create(notification, TweenInfo.new(0.3), {
		Position = UDim2.new(1, 350, 0, 200)
	}):Play()

	task.wait(0.3)
end

local function ProcessNotificationQueue()
	if isShowingNotification then return end
	if #notificationQueue == 0 then return end

	isShowingNotification = true

	local data = table.remove(notificationQueue, 1)
	ShowNotification(data.achievement, data.rewardXP)

	isShowingNotification = false

	-- Check for more
	ProcessNotificationQueue()
end

local function QueueNotification(achievement, rewardXP)
	table.insert(notificationQueue, {
		achievement = achievement,
		rewardXP = rewardXP,
	})
	task.spawn(ProcessNotificationQueue)
end

local function CreateAchievementCard(data, index): Frame
	local card = Instance.new("Frame")
	card.Name = data.id
	card.Size = UDim2.new(0, 270, 0, 70)
	card.LayoutOrder = index
	card.BackgroundColor3 = data.unlocked and Color3.fromRGB(40, 50, 40) or Color3.fromRGB(35, 35, 45)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Icon
	local icon = Instance.new("Frame")
	icon.Position = UDim2.new(0, 8, 0.5, -22)
	icon.Size = UDim2.new(0, 44, 0, 44)
	icon.BackgroundColor3 = data.unlocked
		and (CATEGORY_COLORS[data.category] or Color3.fromRGB(100, 100, 150))
		or Color3.fromRGB(60, 60, 70)
	icon.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = icon

	local iconText = Instance.new("TextLabel")
	iconText.Size = UDim2.new(1, 0, 1, 0)
	iconText.BackgroundTransparency = 1
	iconText.Font = Enum.Font.GothamBold
	iconText.TextSize = 22
	iconText.TextColor3 = data.unlocked and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(100, 100, 110)
	iconText.Text = data.unlocked and "★" or "?"
	iconText.Parent = icon

	-- Name
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 60, 0, 8)
	name.Size = UDim2.new(1, -70, 0, 20)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextColor3 = data.unlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
	name.Text = data.name
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Position = UDim2.new(0, 60, 0, 28)
	desc.Size = UDim2.new(1, -70, 0, 32)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 11
	desc.TextColor3 = Color3.fromRGB(130, 130, 150)
	desc.Text = data.description
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Parent = card

	-- XP reward
	if data.rewardXP then
		local xp = Instance.new("TextLabel")
		xp.AnchorPoint = Vector2.new(1, 0)
		xp.Position = UDim2.new(1, -8, 0, 8)
		xp.Size = UDim2.new(0, 50, 0, 16)
		xp.BackgroundTransparency = 1
		xp.Font = Enum.Font.GothamBold
		xp.TextSize = 11
		xp.TextColor3 = data.unlocked and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 100)
		xp.Text = "+" .. tostring(data.rewardXP)
		xp.TextXAlignment = Enum.TextXAlignment.Right
		xp.Parent = card
	end

	-- Unlocked checkmark
	if data.unlocked then
		local check = Instance.new("TextLabel")
		check.AnchorPoint = Vector2.new(1, 1)
		check.Position = UDim2.new(1, -8, 1, -8)
		check.Size = UDim2.new(0, 20, 0, 20)
		check.BackgroundTransparency = 1
		check.Font = Enum.Font.GothamBold
		check.TextSize = 16
		check.TextColor3 = Color3.fromRGB(100, 255, 100)
		check.Text = "✓"
		check.Parent = card
	end

	return card
end

local function RefreshAchievementList()
	-- Clear existing
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get achievements from server
	local getAchievements = RemoteEvents:FindFirstChild("GetAchievements")
	if not getAchievements then return end

	local data = getAchievements:InvokeServer()
	if not data then return end

	-- Combine and sort
	local allAchievements = {}
	for _, a in ipairs(data.unlocked) do
		table.insert(allAchievements, a)
	end
	for _, a in ipairs(data.locked) do
		table.insert(allAchievements, a)
	end

	-- Filter by category
	local filtered = {}
	for _, a in ipairs(allAchievements) do
		if selectedCategory == "All" or a.category == selectedCategory then
			table.insert(filtered, a)
		end
	end

	-- Sort: unlocked first, then by name
	table.sort(filtered, function(a, b)
		if a.unlocked ~= b.unlocked then
			return a.unlocked
		end
		return a.name < b.name
	end)

	-- Create cards
	for i, achievement in ipairs(filtered) do
		local card = CreateAchievementCard(achievement, i)
		card.Parent = scrollFrame
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)

	-- Update progress counter
	progressCounter.Text = string.format("%d/%d Unlocked", #data.unlocked, #data.unlocked + #data.locked)
end

local function SelectCategory(category: string)
	selectedCategory = category

	for cat, button in pairs(categoryButtons) do
		button.BackgroundColor3 = cat == category
			and Color3.fromRGB(60, 60, 90)
			or Color3.fromRGB(40, 40, 55)
	end

	RefreshAchievementList()
end

local function OpenBrowser()
	browserPanel.Visible = true
	RefreshAchievementList()
end

local function CloseBrowser()
	browserPanel.Visible = false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

achievementsButton.MouseButton1Click:Connect(OpenBrowser)
closeButton.MouseButton1Click:Connect(CloseBrowser)

for category, button in pairs(categoryButtons) do
	button.MouseButton1Click:Connect(function()
		SelectCategory(category)
	end)
end

-- Achievement unlocked from server
local achievementUnlocked = RemoteEvents:FindFirstChild("AchievementUnlocked")
if achievementUnlocked then
	achievementUnlocked.OnClientEvent:Connect(function(data)
		QueueNotification(data.achievement, data.rewardXP)
	end)
end

-- Progress update
local achievementProgress = RemoteEvents:FindFirstChild("AchievementProgress")
if achievementProgress then
	achievementProgress.OnClientEvent:Connect(function(data)
		-- Could show a small progress popup
		-- For now, just refresh if browser is open
		if browserPanel.Visible then
			RefreshAchievementList()
		end
	end)
end

-- Button hover effects
local buttons = {achievementsButton, closeButton}
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

print("[AchievementUI] Initialized")
