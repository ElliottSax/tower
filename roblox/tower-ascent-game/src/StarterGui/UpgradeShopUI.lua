--[[
	UpgradeShopUI.lua
	Upgrade shop interface with purchase buttons

	Features:
	- Toggle shop with 'U' key
	- Shows all upgrades from GameConfig
	- Displays cost, level, description
	- Buy buttons with validation
	- Purchase confirmation messages
	- Auto-updates when coins change

	Upgrades:
	- DoubleJump (1 level) - 100 coins
	- SpeedBoost (5 levels) - 150/300/450/600/750 coins
	- AirDash (1 level) - 250 coins
	- WallGrip (3 levels) - 200/400/600 coins

	Week 2: Full implementation
	Week 3+: Add icons, animations, tabs
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load GameConfig
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[UpgradeShopUI] RemoteEvents folder not found!")
	return
end

local purchaseUpgradeEvent = remoteFolder:WaitForChild("PurchaseUpgrade", 10)
local getUpgradeLevelFunction = remoteFolder:WaitForChild("GetUpgradeLevel", 10)
local getAllUpgradesFunction = remoteFolder:WaitForChild("GetAllUpgrades", 10)
local getCoinFunction = remoteFolder:WaitForChild("GetCoins", 10)
local getUpgradeCostFunction = remoteFolder:WaitForChild("GetUpgradeCost", 10)

if not purchaseUpgradeEvent or not getUpgradeLevelFunction or not getAllUpgradesFunction or not getCoinFunction then
	warn("[UpgradeShopUI] Missing upgrade RemoteEvents!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local isShopOpen = false
local currentCoins = 0
local playerUpgrades = {}
local purchaseInProgress = false -- Prevent double-clicks during purchase
local upgradeCostCache = {} -- Cache costs from server to avoid repeated calls

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShopUI"
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

-- Shop Frame (center)
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 600, 0, 500)
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = shopFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 3
stroke.Parent = shopFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 32
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.Text = "⚡ UPGRADE SHOP ⚡"
titleLabel.Parent = shopFrame

-- Coin Display (top-right in shop)
local shopCoinLabel = Instance.new("TextLabel")
shopCoinLabel.Name = "ShopCoinLabel"
shopCoinLabel.Position = UDim2.new(1, -150, 0, 15)
shopCoinLabel.Size = UDim2.new(0, 140, 0, 30)
shopCoinLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shopCoinLabel.BackgroundTransparency = 0.3
shopCoinLabel.BorderSizePixel = 0
shopCoinLabel.Font = Enum.Font.GothamBold
shopCoinLabel.TextSize = 18
shopCoinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
shopCoinLabel.Text = "💰 0"
shopCoinLabel.Parent = shopFrame

local shopCoinCorner = Instance.new("UICorner")
shopCoinCorner.CornerRadius = UDim.new(0, 8)
shopCoinCorner.Parent = shopCoinLabel

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
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Upgrade List (ScrollingFrame)
local upgradeList = Instance.new("ScrollingFrame")
upgradeList.Name = "UpgradeList"
upgradeList.Position = UDim2.new(0, 20, 0, 70)
upgradeList.Size = UDim2.new(1, -40, 1, -90)
upgradeList.BackgroundTransparency = 1
upgradeList.BorderSizePixel = 0
upgradeList.ScrollBarThickness = 8
upgradeList.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = upgradeList

-- Message Label (for purchase feedback)
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.AnchorPoint = Vector2.new(0.5, 0)
messageLabel.Position = UDim2.new(0.5, 0, 0, 70)
messageLabel.Size = UDim2.new(0, 400, 0, 40)
messageLabel.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
messageLabel.BackgroundTransparency = 1
messageLabel.BorderSizePixel = 0
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 18
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.Text = ""
messageLabel.Visible = false
messageLabel.Parent = screenGui

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 12)
messageCorner.Parent = messageLabel

-- ============================================================================
-- UPGRADE COST CALCULATION (Server-Authoritative)
-- ============================================================================

local function getUpgradeCost(upgradeName: string, currentLevel: number): number
	-- Use server's cost calculation (single source of truth)
	-- Cache results to avoid excessive remote calls
	local cacheKey = upgradeName .. "_" .. (currentLevel + 1)

	if upgradeCostCache[cacheKey] then
		return upgradeCostCache[cacheKey]
	end

	-- If GetUpgradeCost remote exists, use it
	if getUpgradeCostFunction then
		local success, cost = pcall(function()
			return getUpgradeCostFunction:InvokeServer(upgradeName, currentLevel + 1)
		end)

		if success and type(cost) == "number" then
			upgradeCostCache[cacheKey] = cost
			return cost
		end
	end

	-- Fallback to local calculation if remote fails (display only, server validates)
	local upgradeData = GameConfig.Upgrades[upgradeName]
	if not upgradeData then return 0 end

	local targetLevel = currentLevel + 1

	if upgradeName == "SpeedBoost" or upgradeName == "WallGrip" then
		return upgradeData.Cost * targetLevel
	else
		return upgradeData.Cost
	end
end

-- Clear cost cache when upgrades change
local function clearCostCache()
	upgradeCostCache = {}
end

-- ============================================================================
-- CREATE UPGRADE CARDS
-- ============================================================================

local function createUpgradeCard(upgradeName: string, layoutOrder: number)
	local upgradeData = GameConfig.Upgrades[upgradeName]

	-- Card Frame
	local card = Instance.new("Frame")
	card.Name = upgradeName .. "Card"
	card.Size = UDim2.new(1, 0, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = upgradeList

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(100, 100, 100)
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card

	-- Upgrade Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 15, 0, 10)
	nameLabel.Size = UDim2.new(0.5, 0, 0, 25)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 20
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = upgradeData.Name
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Position = UDim2.new(0, 15, 0, 40)
	descLabel.Size = UDim2.new(0.6, 0, 0, 20)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 14
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = upgradeData.Description
	descLabel.Parent = card

	-- Level Label
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Position = UDim2.new(0, 15, 0, 65)
	levelLabel.Size = UDim2.new(0.4, 0, 0, 20)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextSize = 14
	levelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = "Level: 0 / " .. upgradeData.MaxLevel
	levelLabel.Parent = card

	-- Buy Button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Position = UDim2.new(1, -120, 0.5, -20)
	buyButton.Size = UDim2.new(0, 110, 0, 40)
	buyButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 16
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.Text = "💰 " .. upgradeData.Cost
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	-- Store references
	card:SetAttribute("UpgradeName", upgradeName)
	card.LevelLabel = levelLabel
	card.BuyButton = buyButton

	return card
end

-- ============================================================================
-- UPDATE UPGRADE CARDS
-- ============================================================================

local function updateUpgradeCard(card: Frame)
	local upgradeName = card:GetAttribute("UpgradeName")
	local upgradeData = GameConfig.Upgrades[upgradeName]
	local currentLevel = playerUpgrades[upgradeName] or 0

	-- Bounds checking: ensure level is valid
	if currentLevel < 0 then
		warn(string.format("[UpgradeShopUI] Invalid negative level for %s: %d", upgradeName, currentLevel))
		currentLevel = 0
	end
	if currentLevel > upgradeData.MaxLevel then
		warn(string.format("[UpgradeShopUI] Level exceeds max for %s: %d > %d", upgradeName, currentLevel, upgradeData.MaxLevel))
		currentLevel = upgradeData.MaxLevel
	end

	-- Update level label
	card.LevelLabel.Text = string.format("Level: %d / %d", currentLevel, upgradeData.MaxLevel)

	-- Update buy button
	local buyButton = card.BuyButton

	if currentLevel >= upgradeData.MaxLevel then
		-- Max level
		buyButton.Text = "MAX LEVEL"
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		buyButton.AutoButtonColor = false
	else
		-- Calculate cost for next level
		local cost = getUpgradeCost(upgradeName, currentLevel)
		buyButton.Text = "💰 " .. cost

		-- Check if can afford (and not mid-purchase)
		if purchaseInProgress then
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray during purchase
			buyButton.AutoButtonColor = false
		elseif currentCoins >= cost then
			buyButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
			buyButton.AutoButtonColor = true
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50) -- Dark red
			buyButton.AutoButtonColor = false
		end
	end
end

local function updateAllCards()
	for _, card in ipairs(upgradeList:GetChildren()) do
		if card:IsA("Frame") and card:GetAttribute("UpgradeName") then
			updateUpgradeCard(card)
		end
	end
end

-- ============================================================================
-- PURCHASE HANDLER
-- ============================================================================

local function showMessage(text: string, isSuccess: boolean)
	messageLabel.Text = text
	messageLabel.BackgroundColor3 = isSuccess
		and Color3.fromRGB(46, 204, 113) -- Green
		or Color3.fromRGB(231, 76, 60) -- Red
	messageLabel.BackgroundTransparency = 0
	messageLabel.Visible = true

	-- Fade out after 2 seconds
	task.delay(2, function()
		local tween = TweenService:Create(messageLabel, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			messageLabel.Visible = false
			messageLabel.TextTransparency = 0
		end)
	end)
end

local function onPurchaseUpgrade(upgradeName: string)
	-- Prevent double-clicks during purchase
	if purchaseInProgress then
		return
	end

	local upgradeData = GameConfig.Upgrades[upgradeName]
	local currentLevel = playerUpgrades[upgradeName] or 0
	local cost = getUpgradeCost(upgradeName, currentLevel)

	-- Client-side validation
	if currentLevel >= upgradeData.MaxLevel then
		showMessage("Already at max level!", false)
		return
	end

	if currentCoins < cost then
		showMessage("Not enough coins!", false)
		return
	end

	-- Set purchase in progress (loading state)
	purchaseInProgress = true
	updateAllCards() -- Update UI to show loading state

	-- Send purchase request to server
	print(string.format("[UpgradeShopUI] Requesting purchase: %s", upgradeName))
	purchaseUpgradeEvent:FireServer(upgradeName)

	-- Timeout after 10 seconds if no response
	task.delay(10, function()
		if purchaseInProgress then
			purchaseInProgress = false
			updateAllCards()
			showMessage("Purchase timed out. Please try again.", false)
		end
	end)
end

-- Listen for purchase results
purchaseUpgradeEvent.OnClientEvent:Connect(function(success: boolean, message: string, upgradeName: string)
	-- Clear purchase in progress
	purchaseInProgress = false

	if success then
		-- Clear cost cache (costs may have changed)
		clearCostCache()

		-- Refresh player upgrades
		local newUpgrades = getAllUpgradesFunction:InvokeServer()
		if newUpgrades then
			playerUpgrades = newUpgrades
		end

		-- Refresh coins
		local newCoins = getCoinFunction:InvokeServer()
		if newCoins then
			currentCoins = newCoins
			shopCoinLabel.Text = "💰 " .. currentCoins
		end

		-- Update UI
		updateAllCards()

		showMessage("✓ " .. message, true)
	else
		-- Update UI (re-enable buttons)
		updateAllCards()

		showMessage("✗ " .. message, false)
	end
end)

-- ============================================================================
-- SHOP TOGGLE
-- ============================================================================

local function openShop()
	isShopOpen = true
	background.Visible = true
	shopFrame.Visible = true

	-- Refresh data
	local newCoins = getCoinFunction:InvokeServer()
	if newCoins then
		currentCoins = newCoins
		shopCoinLabel.Text = "💰 " .. currentCoins
	end

	local newUpgrades = getAllUpgradesFunction:InvokeServer()
	if newUpgrades then
		playerUpgrades = newUpgrades
	end

	updateAllCards()

	print("[UpgradeShopUI] Shop opened")
end

local function closeShop()
	isShopOpen = false
	background.Visible = false
	shopFrame.Visible = false

	print("[UpgradeShopUI] Shop closed")
end

local function toggleShop()
	if isShopOpen then
		closeShop()
	else
		openShop()
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.U then
		toggleShop()
	elseif input.KeyCode == Enum.KeyCode.Escape and isShopOpen then
		closeShop()
	end
end)

-- Close button
closeButton.MouseButton1Click:Connect(closeShop)

-- Background click to close
background.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closeShop()
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Create upgrade cards
local upgradeOrder = {
	"DoubleJump",
	"SpeedBoost",
	"AirDash",
	"WallGrip",
}

for i, upgradeName in ipairs(upgradeOrder) do
	local card = createUpgradeCard(upgradeName, i)

	-- Connect buy button
	card.BuyButton.MouseButton1Click:Connect(function()
		onPurchaseUpgrade(upgradeName)
	end)
end

-- Get initial data
local initialCoins = getCoinFunction:InvokeServer()
if initialCoins then
	currentCoins = initialCoins
	shopCoinLabel.Text = "💰 " .. currentCoins
end

local initialUpgrades = getAllUpgradesFunction:InvokeServer()
if initialUpgrades then
	playerUpgrades = initialUpgrades
end

updateAllCards()

-- Update canvas size for scrolling
upgradeList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	upgradeList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

print("[UpgradeShopUI] Initialized (Press 'U' to open shop)")
