--[[
	PlayerHUD.client.lua
	Main player HUD showing XP, level, and coins

	Features:
	- XP bar with progress
	- Level display
	- Coin counter
	- XP/coin gain popups
	- Level up celebration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[PlayerHUD] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Top bar container
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Position = UDim2.new(0, 10, 0, 10)
topBar.Size = UDim2.new(0, 300, 0, 50)
topBar.BackgroundTransparency = 1
topBar.Parent = screenGui

-- Level badge
local levelBadge = Instance.new("Frame")
levelBadge.Name = "LevelBadge"
levelBadge.Size = UDim2.new(0, 50, 0, 50)
levelBadge.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
levelBadge.Parent = topBar

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 10)
badgeCorner.Parent = levelBadge

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "Level"
levelLabel.Size = UDim2.new(1, 0, 0.7, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 22
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.Text = "1"
levelLabel.Parent = levelBadge

local levelText = Instance.new("TextLabel")
levelText.Position = UDim2.new(0, 0, 0.6, 0)
levelText.Size = UDim2.new(1, 0, 0.4, 0)
levelText.BackgroundTransparency = 1
levelText.Font = Enum.Font.Gotham
levelText.TextSize = 8
levelText.TextColor3 = Color3.fromRGB(200, 200, 220)
levelText.Text = "LEVEL"
levelText.Parent = levelBadge

-- XP bar container
local xpContainer = Instance.new("Frame")
xpContainer.Position = UDim2.new(0, 60, 0, 5)
xpContainer.Size = UDim2.new(0, 180, 0, 20)
xpContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
xpContainer.Parent = topBar

local xpContainerCorner = Instance.new("UICorner")
xpContainerCorner.CornerRadius = UDim.new(0, 6)
xpContainerCorner.Parent = xpContainer

-- XP fill bar
local xpFill = Instance.new("Frame")
xpFill.Name = "Fill"
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
xpFill.Parent = xpContainer

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(0, 6)
xpFillCorner.Parent = xpFill

-- XP text
local xpText = Instance.new("TextLabel")
xpText.Name = "XPText"
xpText.Size = UDim2.new(1, 0, 1, 0)
xpText.BackgroundTransparency = 1
xpText.Font = Enum.Font.GothamBold
xpText.TextSize = 10
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.Text = "0 / 100 XP"
xpText.ZIndex = 2
xpText.Parent = xpContainer

-- Coins display
local coinsDisplay = Instance.new("Frame")
coinsDisplay.Position = UDim2.new(0, 60, 0, 30)
coinsDisplay.Size = UDim2.new(0, 100, 0, 18)
coinsDisplay.BackgroundTransparency = 1
coinsDisplay.Parent = topBar

local coinIcon = Instance.new("TextLabel")
coinIcon.Size = UDim2.new(0, 18, 0, 18)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
coinIcon.Font = Enum.Font.GothamBold
coinIcon.TextSize = 12
coinIcon.TextColor3 = Color3.fromRGB(150, 100, 0)
coinIcon.Text = "$"
coinIcon.Parent = coinsDisplay

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coinIcon

local coinText = Instance.new("TextLabel")
coinText.Name = "CoinText"
coinText.Position = UDim2.new(0, 22, 0, 0)
coinText.Size = UDim2.new(1, -22, 1, 0)
coinText.BackgroundTransparency = 1
coinText.Font = Enum.Font.GothamBold
coinText.TextSize = 14
coinText.TextColor3 = Color3.fromRGB(255, 200, 50)
coinText.Text = "0"
coinText.TextXAlignment = Enum.TextXAlignment.Left
coinText.Parent = coinsDisplay

-- XP gain popup container
local xpPopupContainer = Instance.new("Frame")
xpPopupContainer.Position = UDim2.new(0, 250, 0, 5)
xpPopupContainer.Size = UDim2.new(0, 100, 0, 100)
xpPopupContainer.BackgroundTransparency = 1
xpPopupContainer.Parent = topBar

-- Level up celebration
local levelUpOverlay = Instance.new("Frame")
levelUpOverlay.Name = "LevelUpOverlay"
levelUpOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
levelUpOverlay.Position = UDim2.new(0.5, 0, 0.4, 0)
levelUpOverlay.Size = UDim2.new(0, 0, 0, 0)
levelUpOverlay.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
levelUpOverlay.BackgroundTransparency = 0.2
levelUpOverlay.Visible = false
levelUpOverlay.Parent = screenGui

local levelUpCorner = Instance.new("UICorner")
levelUpCorner.CornerRadius = UDim.new(0, 20)
levelUpCorner.Parent = levelUpOverlay

local levelUpStroke = Instance.new("UIStroke")
levelUpStroke.Color = Color3.fromRGB(255, 215, 0)
levelUpStroke.Thickness = 4
levelUpStroke.Parent = levelUpOverlay

local levelUpTitle = Instance.new("TextLabel")
levelUpTitle.Position = UDim2.new(0, 0, 0, 30)
levelUpTitle.Size = UDim2.new(1, 0, 0, 40)
levelUpTitle.BackgroundTransparency = 1
levelUpTitle.Font = Enum.Font.GothamBold
levelUpTitle.TextSize = 32
levelUpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
levelUpTitle.Text = "LEVEL UP!"
levelUpTitle.Parent = levelUpOverlay

local levelUpNumber = Instance.new("TextLabel")
levelUpNumber.Name = "LevelNumber"
levelUpNumber.Position = UDim2.new(0, 0, 0, 80)
levelUpNumber.Size = UDim2.new(1, 0, 0, 60)
levelUpNumber.BackgroundTransparency = 1
levelUpNumber.Font = Enum.Font.GothamBold
levelUpNumber.TextSize = 48
levelUpNumber.TextColor3 = Color3.fromRGB(255, 215, 0)
levelUpNumber.Text = "2"
levelUpNumber.Parent = levelUpOverlay

-- ============================================================================
-- STATE
-- ============================================================================

local currentLevel = 1
local currentXP = 0
local currentXPRequired = 100
local currentCoins = 0

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function FormatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

local function UpdateDisplay()
	levelLabel.Text = tostring(currentLevel)
	xpText.Text = string.format("%s / %s XP", FormatNumber(currentXP), FormatNumber(currentXPRequired))
	coinText.Text = FormatNumber(currentCoins)

	-- Update XP bar
	local xpPercent = math.clamp(currentXP / currentXPRequired, 0, 1)
	TweenService:Create(xpFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Size = UDim2.new(xpPercent, 0, 1, 0)
	}):Play()
end

local function CreateXPPopup(amount: number, reason: string?)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(1, 0, 0, 20)
	popup.Position = UDim2.new(0, 0, 0, 0)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 14
	popup.TextColor3 = amount > 0 and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
	popup.Text = (amount > 0 and "+" or "") .. tostring(amount) .. " XP"
	popup.TextXAlignment = Enum.TextXAlignment.Left
	popup.Parent = xpPopupContainer

	-- Animate up and fade
	TweenService:Create(popup, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, 0, 0, -50),
		TextTransparency = 1,
	}):Play()

	task.delay(1.5, function()
		popup:Destroy()
	end)
end

local function CreateCoinPopup(amount: number)
	local popup = Instance.new("TextLabel")
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.Size = UDim2.new(0, 80, 0, 20)
	popup.Position = UDim2.new(0.5, 0, 0, 50)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 16
	popup.TextColor3 = Color3.fromRGB(255, 200, 50)
	popup.Text = "+" .. tostring(amount)
	popup.Parent = coinsDisplay

	-- Animate up and fade
	TweenService:Create(popup, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0.5, 0, 0, -30),
		TextTransparency = 1,
	}):Play()

	task.delay(1.2, function()
		popup:Destroy()
	end)
end

local function ShowLevelUpCelebration(newLevel: number)
	levelUpNumber.Text = tostring(newLevel)
	levelUpOverlay.Visible = true
	levelUpOverlay.Size = UDim2.new(0, 0, 0, 0)

	-- Expand animation
	TweenService:Create(levelUpOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 300, 0, 180)
	}):Play()

	-- Pulse the level badge
	TweenService:Create(levelBadge, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 60, 0, 60),
		BackgroundColor3 = Color3.fromRGB(255, 215, 0),
	}):Play()

	task.delay(0.2, function()
		TweenService:Create(levelBadge, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 50, 0, 50),
			BackgroundColor3 = Color3.fromRGB(100, 80, 200),
		}):Play()
	end)

	-- Hide after delay
	task.delay(2.5, function()
		TweenService:Create(levelUpOverlay, TweenInfo.new(0.2), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.wait(0.2)
		levelUpOverlay.Visible = false
	end)
end

local function FetchInitialData()
	local getStats = RemoteEvents:FindFirstChild("GetRewardStats")
	if getStats then
		local stats = getStats:InvokeServer()
		if stats then
			currentLevel = stats.level or 1
			currentXP = stats.xp or 0
			currentXPRequired = stats.xpRequired or 100
			currentCoins = stats.coins or 0
			UpdateDisplay()
		end
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local xpGained = RemoteEvents:FindFirstChild("XPGained")
if xpGained then
	xpGained.OnClientEvent:Connect(function(data)
		currentXP = data.newXP
		currentLevel = data.level
		currentXPRequired = data.xpRequired

		CreateXPPopup(data.amount, data.reason)
		UpdateDisplay()
	end)
end

local coinsGained = RemoteEvents:FindFirstChild("CoinsGained")
if coinsGained then
	coinsGained.OnClientEvent:Connect(function(data)
		currentCoins = data.totalCoins
		CreateCoinPopup(data.amount)
		UpdateDisplay()
	end)
end

local levelUp = RemoteEvents:FindFirstChild("LevelUp")
if levelUp then
	levelUp.OnClientEvent:Connect(function(data)
		currentLevel = data.newLevel
		UpdateDisplay()
		ShowLevelUpCelebration(data.newLevel)
	end)
end

-- Initial data fetch
task.spawn(function()
	task.wait(1)
	FetchInitialData()
end)

print("[PlayerHUD] Initialized")
