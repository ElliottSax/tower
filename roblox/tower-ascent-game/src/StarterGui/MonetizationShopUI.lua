--[[
	MonetizationShopUI.lua
	Comprehensive monetization shop for Tower Ascent

	Features:
	- VIP Pass purchase (500 Robux)
	- Battle Pass purchase (99 Robux)
	- Game Passes (5 passes, 79-199 Robux)
	- Developer Products (8 products, 19-399 Robux)
	- Tabs: VIP, Battle Pass, Game Passes, Boosts
	- Visual indicators (owned, benefits, pricing)
	- Purchase confirmation dialogs
	- Auto-refresh on purchases

	Controls:
	- 'M' key or shop button to toggle
	- Tab buttons to switch categories
	- Buy buttons to initiate purchases

	Week 15: Monetization Shop UI implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[MonetizationShopUI] RemoteEvents folder not found!")
	return
end

-- VIP RemoteEvents
local vipStatusUpdate = remoteFolder:FindFirstChild("VIPStatusUpdate")
local promptVIPPurchase = remoteFolder:FindFirstChild("PromptVIPPurchase")

-- Battle Pass RemoteEvents
local battlePassStatusUpdate = remoteFolder:FindFirstChild("BattlePassStatusUpdate")
local promptBattlePassPurchase = remoteFolder:FindFirstChild("PromptBattlePassPurchase")

-- ============================================================================
-- STATE
-- ============================================================================

local isShopOpen = false
local currentTab = "VIP" -- VIP, BattlePass, GamePasses, Boosts
local isVIP = false
local hasPremiumBattlePass = false
local ownedGamePasses = {}
local purchaseInProgress = false

-- Product Definitions (must match server-side configs)
local PRODUCTS = {
	VIP = {
		Name = "Tower Ascent VIP",
		Price = 500,
		Description = "🌟 2x Coins Forever + VIP Tag + Exclusive Benefits",
		Benefits = {
			"• 2x Coins on every climb",
			"• Gold ⭐ VIP tag above your name",
			"• Reach max upgrades in 2-3 climbs",
			"• Premium status symbol",
		},
	},
	BattlePass = {
		Name = "Premium Battle Pass - Season 1",
		Price = 99,
		Description = "🏆 Unlock 50 Premium Rewards",
		Benefits = {
			"• 50 exclusive cosmetics",
			"• 15 particle trails",
			"• 10 exclusive titles",
			"• 10 emotes",
			"• Bonus coins & XP boosts",
		},
	},
	GamePasses = {
		{
			Name = "Particle Effects Pack",
			Price = 149,
			Icon = "✨",
			Description = "5 exclusive particle trails",
			Benefits = {"Fire", "Ice", "Electric", "Rainbow", "Galaxy"},
		},
		{
			Name = "Emote Pack",
			Price = 99,
			Icon = "😎",
			Description = "5 social emotes",
			Benefits = {"Wave", "Dance", "Cheer", "Laugh", "Flex"},
		},
		{
			Name = "Double XP",
			Price = 199,
			Icon = "⚡",
			Description = "2x Battle Pass XP forever",
			Benefits = {"Permanent 2x XP multiplier", "Reach max tier twice as fast"},
		},
		{
			Name = "Checkpoint Skip",
			Price = 79,
			Icon = "⏩",
			Description = "Skip ahead 5 sections",
			Benefits = {"Unlimited uses (3 per day)", "Bypass frustrating obstacles"},
		},
		{
			Name = "Speed Demon",
			Price = 149,
			Icon = "🏃",
			Description = "+5% permanent speed boost",
			Benefits = {"Stacks with upgrades", "Perfect for speedrunning"},
		},
	},
	DeveloperProducts = {
		-- Coin Packs
		{
			Name = "500 Coins",
			Price = 49,
			Icon = "💰",
			Type = "Coins",
			Amount = 500,
			Description = "Instant coins",
		},
		{
			Name = "1,500 Coins",
			Price = 99,
			Icon = "💰",
			Type = "Coins",
			Amount = 1500,
			Description = "20% bonus!",
		},
		{
			Name = "4,000 Coins",
			Price = 199,
			Icon = "💰",
			Type = "Coins",
			Amount = 4000,
			Description = "60% bonus!",
		},
		{
			Name = "10,000 Coins",
			Price = 399,
			Icon = "💰",
			Type = "Coins",
			Amount = 10000,
			Description = "150% bonus - Best Value!",
		},
		-- XP Boosts
		{
			Name = "30 Min XP Boost",
			Price = 29,
			Icon = "⚡",
			Type = "XPBoost",
			Duration = "30 min",
			Description = "2x Battle Pass XP",
		},
		{
			Name = "1 Hour XP Boost",
			Price = 49,
			Icon = "⚡",
			Type = "XPBoost",
			Duration = "1 hour",
			Description = "2x Battle Pass XP",
		},
		{
			Name = "3 Hour XP Boost",
			Price = 99,
			Icon = "⚡",
			Type = "XPBoost",
			Duration = "3 hours",
			Description = "2x XP - Best Value!",
		},
		-- Respawn Skip
		{
			Name = "Respawn Skip",
			Price = 19,
			Icon = "❤️",
			Type = "Respawn",
			Description = "Skip one death penalty",
		},
	},
}

-- ============================================================================
-- CREATE UI STRUCTURE
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonetizationShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background overlay (darkens screen)
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.6
background.BorderSizePixel = 0
background.Visible = false
background.ZIndex = 10
background.Parent = screenGui

-- Main shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 800, 0, 600)
shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 11
shopFrame.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 20)
shopCorner.Parent = shopFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
header.BorderSizePixel = 0
header.ZIndex = 12
header.Parent = shopFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💎 PREMIUM SHOP"
title.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.ZIndex = 13
title.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -20, 0.5, 0)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 24
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 13
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Position = UDim2.new(0, 0, 0, 60)
tabBar.Size = UDim2.new(1, 0, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 12
tabBar.Parent = shopFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 0)
tabLayout.Parent = tabBar

-- Content area (scrollable)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Position = UDim2.new(0, 0, 0, 110)
contentFrame.Size = UDim2.new(1, 0, 1, -110)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.ZIndex = 12
contentFrame.Parent = shopFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 15)
contentLayout.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.Parent = contentFrame

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function CreateTab(name, icon, order)
	local tab = Instance.new("TextButton")
	tab.Name = name .. "Tab"
	tab.Size = UDim2.new(0.25, 0, 1, 0)
	tab.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	tab.BorderSizePixel = 0
	tab.Text = icon .. " " .. name
	tab.TextColor3 = Color3.fromRGB(180, 180, 180)
	tab.TextSize = 18
	tab.Font = Enum.Font.GothamSemibold
	tab.LayoutOrder = order
	tab.ZIndex = 13
	tab.Parent = tabBar

	return tab
end

local function UpdateTabStyles()
	for _, tab in ipairs(tabBar:GetChildren()) do
		if tab:IsA("TextButton") then
			local tabName = tab.Name:gsub("Tab", "")
			if tabName == currentTab then
				tab.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- Active
				tab.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
			else
				tab.BackgroundColor3 = Color3.fromRGB(40, 40, 45) -- Inactive
				tab.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end
	end
end

local function CreateProductCard(product, isOwned, productType)
	local card = Instance.new("Frame")
	card.Name = "ProductCard"
	card.Size = UDim2.new(1, -40, 0, 150)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 13

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- Product name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Position = UDim2.new(0, 15, 0, 10)
	nameLabel.Size = UDim2.new(1, -150, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = (product.Icon or "💎") .. " " .. product.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 14
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Position = UDim2.new(0, 15, 0, 45)
	descLabel.Size = UDim2.new(1, -150, 0, 25)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = product.Description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Font = Enum.Font.Gotham
	descLabel.ZIndex = 14
	descLabel.Parent = card

	-- Benefits list
	if product.Benefits then
		local benefitsText = table.concat(product.Benefits, "\n")
		local benefitsLabel = Instance.new("TextLabel")
		benefitsLabel.Name = "BenefitsLabel"
		benefitsLabel.Position = UDim2.new(0, 15, 0, 75)
		benefitsLabel.Size = UDim2.new(1, -150, 0, 60)
		benefitsLabel.BackgroundTransparency = 1
		benefitsLabel.Text = benefitsText
		benefitsLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
		benefitsLabel.TextSize = 12
		benefitsLabel.TextXAlignment = Enum.TextXAlignment.Left
		benefitsLabel.TextYAlignment = Enum.TextYAlignment.Top
		benefitsLabel.Font = Enum.Font.Gotham
		benefitsLabel.ZIndex = 14
		benefitsLabel.Parent = card
	end

	-- Price label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.AnchorPoint = Vector2.new(1, 0)
	priceLabel.Position = UDim2.new(1, -15, 0, 50)
	priceLabel.Size = UDim2.new(0, 100, 0, 30)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "R$ " .. product.Price
	priceLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
	priceLabel.TextSize = 18
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.ZIndex = 14
	priceLabel.Parent = card

	-- Buy button or Owned badge
	if isOwned then
		local ownedBadge = Instance.new("TextLabel")
		ownedBadge.Name = "OwnedBadge"
		ownedBadge.AnchorPoint = Vector2.new(1, 1)
		ownedBadge.Position = UDim2.new(1, -15, 1, -15)
		ownedBadge.Size = UDim2.new(0, 100, 0, 35)
		ownedBadge.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		ownedBadge.Text = "✓ OWNED"
		ownedBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		ownedBadge.TextSize = 14
		ownedBadge.Font = Enum.Font.GothamBold
		ownedBadge.ZIndex = 14
		ownedBadge.Parent = card

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 8)
		badgeCorner.Parent = ownedBadge
	else
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.AnchorPoint = Vector2.new(1, 1)
		buyButton.Position = UDim2.new(1, -15, 1, -15)
		buyButton.Size = UDim2.new(0, 100, 0, 35)
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		buyButton.Text = "BUY"
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 16
		buyButton.Font = Enum.Font.GothamBold
		buyButton.ZIndex = 14
		buyButton.Parent = card

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		-- Purchase logic
		buyButton.MouseButton1Click:Connect(function()
			if purchaseInProgress then return end
			purchaseInProgress = true

			-- Visual feedback
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
			buyButton.Text = "LOADING..."

			task.wait(0.5)

			-- Trigger purchase based on product type
			if productType == "VIP" and promptVIPPurchase then
				promptVIPPurchase:FireServer()
			elseif productType == "BattlePass" and promptBattlePassPurchase then
				promptBattlePassPurchase:FireServer()
			else
				warn("[MonetizationShopUI] Purchase type not implemented:", productType)
			end

			task.wait(1)
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			buyButton.Text = "BUY"
			purchaseInProgress = false
		end)
	end

	return card
end

local function ClearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "ProductCard" then
			child:Destroy()
		end
	end
end

local function PopulateVIPTab()
	ClearContent()

	local vipCard = CreateProductCard(PRODUCTS.VIP, isVIP, "VIP")
	vipCard.Parent = contentFrame
end

local function PopulateBattlePassTab()
	ClearContent()

	local bpCard = CreateProductCard(PRODUCTS.BattlePass, hasPremiumBattlePass, "BattlePass")
	bpCard.Parent = contentFrame
end

local function PopulateGamePassesTab()
	ClearContent()

	for _, pass in ipairs(PRODUCTS.GamePasses) do
		local isOwned = ownedGamePasses[pass.Name] or false
		local passCard = CreateProductCard(pass, isOwned, "GamePass")
		passCard.Parent = contentFrame
	end
end

local function PopulateBoostsTab()
	ClearContent()

	for _, product in ipairs(PRODUCTS.DeveloperProducts) do
		local productCard = CreateProductCard(product, false, "DevProduct")
		productCard.Parent = contentFrame
	end
end

local function SwitchTab(tabName)
	currentTab = tabName
	UpdateTabStyles()

	if tabName == "VIP" then
		PopulateVIPTab()
	elseif tabName == "BattlePass" then
		PopulateBattlePassTab()
	elseif tabName == "GamePasses" then
		PopulateGamePassesTab()
	elseif tabName == "Boosts" then
		PopulateBoostsTab()
	end
end

-- ============================================================================
-- SHOP TOGGLE
-- ============================================================================

local function ToggleShop()
	isShopOpen = not isShopOpen
	background.Visible = isShopOpen
	shopFrame.Visible = isShopOpen

	if isShopOpen then
		-- Refresh current tab
		SwitchTab(currentTab)
	end
end

-- ============================================================================
-- CREATE TABS
-- ============================================================================

local vipTab = CreateTab("VIP", "⭐", 1)
local battlePassTab = CreateTab("BattlePass", "🏆", 2)
local gamePassesTab = CreateTab("GamePasses", "✨", 3)
local boostsTab = CreateTab("Boosts", "⚡", 4)

vipTab.MouseButton1Click:Connect(function() SwitchTab("VIP") end)
battlePassTab.MouseButton1Click:Connect(function() SwitchTab("BattlePass") end)
gamePassesTab.MouseButton1Click:Connect(function() SwitchTab("GamePasses") end)
boostsTab.MouseButton1Click:Connect(function() SwitchTab("Boosts") end)

closeButton.MouseButton1Click:Connect(function() ToggleShop() end)
background.MouseButton1Click:Connect(function() ToggleShop() end)

-- ============================================================================
-- KEYBOARD INPUT
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.M then
		ToggleShop()
	end
end)

-- ============================================================================
-- STATUS UPDATES FROM SERVER
-- ============================================================================

if vipStatusUpdate then
	vipStatusUpdate.OnClientEvent:Connect(function(isVIPStatus)
		isVIP = isVIPStatus
		if currentTab == "VIP" and isShopOpen then
			PopulateVIPTab()
		end
	end)
end

if battlePassStatusUpdate then
	battlePassStatusUpdate.OnClientEvent:Connect(function(hasPremium)
		hasPremiumBattlePass = hasPremium
		if currentTab == "BattlePass" and isShopOpen then
			PopulateBattlePassTab()
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Set default tab
UpdateTabStyles()
PopulateVIPTab()

print("[MonetizationShopUI] Shop initialized. Press 'M' to open.")
