--[[
	ShopUI.client.lua
	In-game shop for purchasing cosmetics, emotes, and passes

	Features:
	- Category tabs (Cosmetics, Emotes, Passes)
	- Item preview
	- Currency display
	- Purchase confirmation
	- Featured items
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[ShopUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CATEGORIES = {
	{ id = "featured", name = "Featured", icon = "⭐" },
	{ id = "trails", name = "Trails", icon = "✨" },
	{ id = "auras", name = "Auras", icon = "🔮" },
	{ id = "emotes", name = "Emotes", icon = "💃" },
	{ id = "passes", name = "Passes", icon = "🎫" },
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Legendary = Color3.fromRGB(255, 180, 50),
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Shop button
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.AnchorPoint = Vector2.new(1, 0)
shopButton.Position = UDim2.new(1, -20, 0, 390)
shopButton.Size = UDim2.new(0, 50, 0, 50)
shopButton.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
shopButton.Font = Enum.Font.GothamBold
shopButton.TextSize = 22
shopButton.TextColor3 = Color3.fromRGB(100, 255, 100)
shopButton.Text = "🛒"
shopButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = shopButton

-- Main shop panel
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.Size = UDim2.new(0, 700, 0, 500)
shopPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
shopPanel.Visible = false
shopPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = shopPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(100, 255, 100)
panelStroke.Thickness = 2
panelStroke.Parent = shopPanel

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
header.Parent = shopPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Fix bottom corners
local headerFix = Instance.new("Frame")
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 26
titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
titleLabel.Text = "🛒 Shop"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Currency display
local currencyFrame = Instance.new("Frame")
currencyFrame.Name = "Currency"
currencyFrame.AnchorPoint = Vector2.new(1, 0.5)
currencyFrame.Position = UDim2.new(1, -70, 0.5, 0)
currencyFrame.Size = UDim2.new(0, 150, 0, 35)
currencyFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
currencyFrame.Parent = header

local currencyCorner = Instance.new("UICorner")
currencyCorner.CornerRadius = UDim.new(0, 8)
currencyCorner.Parent = currencyFrame

local coinIcon = Instance.new("TextLabel")
coinIcon.Position = UDim2.new(0, 10, 0, 0)
coinIcon.Size = UDim2.new(0, 25, 1, 0)
coinIcon.BackgroundTransparency = 1
coinIcon.Font = Enum.Font.GothamBold
coinIcon.TextSize = 18
coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
coinIcon.Text = "🪙"
coinIcon.Parent = currencyFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "Amount"
coinLabel.Position = UDim2.new(0, 35, 0, 0)
coinLabel.Size = UDim2.new(1, -45, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 16
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.Text = "0"
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = currencyFrame

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
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Category tabs
local tabContainer = Instance.new("Frame")
tabContainer.Name = "Tabs"
tabContainer.Position = UDim2.new(0, 15, 0, 70)
tabContainer.Size = UDim2.new(1, -30, 0, 35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = shopPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local categoryButtons = {}
local selectedCategory = "featured"

for i, category in ipairs(CATEGORIES) do
	local tab = Instance.new("TextButton")
	tab.Name = category.id
	tab.Size = UDim2.new(0, 120, 1, 0)
	tab.LayoutOrder = i
	tab.BackgroundColor3 = i == 1 and Color3.fromRGB(60, 70, 60) or Color3.fromRGB(40, 40, 50)
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 13
	tab.TextColor3 = Color3.fromRGB(200, 200, 220)
	tab.Text = category.icon .. " " .. category.name
	tab.Parent = tabContainer

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tab

	categoryButtons[category.id] = tab
end

-- Items container
local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Name = "Items"
itemsFrame.Position = UDim2.new(0, 15, 0, 115)
itemsFrame.Size = UDim2.new(0.65, -20, 1, -130)
itemsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
itemsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsFrame.ScrollBarThickness = 6
itemsFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
itemsFrame.Parent = shopPanel

local itemsCorner = Instance.new("UICorner")
itemsCorner.CornerRadius = UDim.new(0, 8)
itemsCorner.Parent = itemsFrame

local itemsGrid = Instance.new("UIGridLayout")
itemsGrid.CellSize = UDim2.new(0, 140, 0, 160)
itemsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
itemsGrid.Parent = itemsFrame

local itemsPadding = Instance.new("UIPadding")
itemsPadding.PaddingTop = UDim.new(0, 10)
itemsPadding.PaddingLeft = UDim.new(0, 10)
itemsPadding.Parent = itemsFrame

-- Preview panel
local previewPanel = Instance.new("Frame")
previewPanel.Name = "Preview"
previewPanel.AnchorPoint = Vector2.new(1, 0)
previewPanel.Position = UDim2.new(1, -15, 0, 115)
previewPanel.Size = UDim2.new(0.35, -20, 1, -130)
previewPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
previewPanel.Parent = shopPanel

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = previewPanel

-- Preview content
local previewImage = Instance.new("Frame")
previewImage.Name = "Image"
previewImage.Position = UDim2.new(0.5, 0, 0, 20)
previewImage.AnchorPoint = Vector2.new(0.5, 0)
previewImage.Size = UDim2.new(0, 120, 0, 120)
previewImage.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
previewImage.Parent = previewPanel

local previewImageCorner = Instance.new("UICorner")
previewImageCorner.CornerRadius = UDim.new(0, 10)
previewImageCorner.Parent = previewImage

local previewIcon = Instance.new("TextLabel")
previewIcon.Name = "Icon"
previewIcon.Size = UDim2.new(1, 0, 1, 0)
previewIcon.BackgroundTransparency = 1
previewIcon.Font = Enum.Font.GothamBold
previewIcon.TextSize = 50
previewIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
previewIcon.Text = "?"
previewIcon.Parent = previewImage

local previewName = Instance.new("TextLabel")
previewName.Name = "Name"
previewName.Position = UDim2.new(0, 15, 0, 150)
previewName.Size = UDim2.new(1, -30, 0, 25)
previewName.BackgroundTransparency = 1
previewName.Font = Enum.Font.GothamBold
previewName.TextSize = 18
previewName.TextColor3 = Color3.fromRGB(255, 255, 255)
previewName.Text = "Select an item"
previewName.Parent = previewPanel

local previewRarity = Instance.new("TextLabel")
previewRarity.Name = "Rarity"
previewRarity.Position = UDim2.new(0, 15, 0, 175)
previewRarity.Size = UDim2.new(1, -30, 0, 20)
previewRarity.BackgroundTransparency = 1
previewRarity.Font = Enum.Font.Gotham
previewRarity.TextSize = 14
previewRarity.TextColor3 = Color3.fromRGB(150, 150, 150)
previewRarity.Text = ""
previewRarity.Parent = previewPanel

local previewDesc = Instance.new("TextLabel")
previewDesc.Name = "Description"
previewDesc.Position = UDim2.new(0, 15, 0, 200)
previewDesc.Size = UDim2.new(1, -30, 0, 60)
previewDesc.BackgroundTransparency = 1
previewDesc.Font = Enum.Font.Gotham
previewDesc.TextSize = 12
previewDesc.TextColor3 = Color3.fromRGB(180, 180, 200)
previewDesc.Text = "Browse the shop to see item details."
previewDesc.TextWrapped = true
previewDesc.TextYAlignment = Enum.TextYAlignment.Top
previewDesc.Parent = previewPanel

local buyButton = Instance.new("TextButton")
buyButton.Name = "Buy"
buyButton.AnchorPoint = Vector2.new(0.5, 1)
buyButton.Position = UDim2.new(0.5, 0, 1, -15)
buyButton.Size = UDim2.new(1, -30, 0, 45)
buyButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
buyButton.Font = Enum.Font.GothamBold
buyButton.TextSize = 16
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyButton.Text = "Select Item"
buyButton.Visible = true
buyButton.Parent = previewPanel

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 8)
buyCorner.Parent = buyButton

-- ============================================================================
-- STATE
-- ============================================================================

local shopItems = {}
local selectedItem = nil
local playerCoins = 0

-- ============================================================================
-- MOCK SHOP DATA (would come from server in production)
-- ============================================================================

local SHOP_DATA = {
	featured = {
		{ id = "trail_rainbow", name = "Rainbow Trail", icon = "🌈", price = 500, rarity = "Legendary", description = "Leave a colorful rainbow trail behind you!" },
		{ id = "aura_fire", name = "Fire Aura", icon = "🔥", price = 300, rarity = "Epic", description = "Engulf yourself in flames!" },
	},
	trails = {
		{ id = "trail_sparkle", name = "Sparkle Trail", icon = "✨", price = 100, rarity = "Common", description = "A simple sparkle effect." },
		{ id = "trail_star", name = "Star Trail", icon = "⭐", price = 150, rarity = "Uncommon", description = "Leave stars in your wake." },
		{ id = "trail_rainbow", name = "Rainbow Trail", icon = "🌈", price = 500, rarity = "Legendary", description = "Leave a colorful rainbow trail behind you!" },
		{ id = "trail_void", name = "Void Trail", icon = "🌑", price = 400, rarity = "Epic", description = "A trail of darkness." },
	},
	auras = {
		{ id = "aura_glow", name = "Glow Aura", icon = "💡", price = 100, rarity = "Common", description = "A soft glow around your character." },
		{ id = "aura_fire", name = "Fire Aura", icon = "🔥", price = 300, rarity = "Epic", description = "Engulf yourself in flames!" },
		{ id = "aura_ice", name = "Ice Aura", icon = "❄️", price = 300, rarity = "Epic", description = "Freezing cold aura." },
		{ id = "aura_electric", name = "Electric Aura", icon = "⚡", price = 350, rarity = "Epic", description = "Crackling electricity!" },
	},
	emotes = {
		{ id = "emote_dance", name = "Dance", icon = "💃", price = 150, rarity = "Uncommon", description = "Show off your moves!" },
		{ id = "emote_laugh", name = "Laugh", icon = "😂", price = 100, rarity = "Common", description = "Have a good laugh." },
		{ id = "emote_victory", name = "Victory", icon = "🏆", price = 200, rarity = "Rare", description = "Celebrate your win!" },
	},
	passes = {
		{ id = "pass_vip", name = "VIP Pass", icon = "👑", price = 499, rarity = "Legendary", description = "2x XP, exclusive cosmetics, and more!", isRobux = true },
		{ id = "pass_coins", name = "1000 Coins", icon = "🪙", price = 99, rarity = "Common", description = "Get 1000 coins instantly!", isRobux = true },
	},
}

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function CreateItemCard(item, index): Frame
	local card = Instance.new("Frame")
	card.Name = item.id
	card.Size = UDim2.new(0, 140, 0, 160)
	card.LayoutOrder = index
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Rarity border
	local rarityColor = RARITY_COLORS[item.rarity] or RARITY_COLORS.Common
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card

	-- Icon
	local iconFrame = Instance.new("Frame")
	iconFrame.Position = UDim2.new(0.5, 0, 0, 15)
	iconFrame.AnchorPoint = Vector2.new(0.5, 0)
	iconFrame.Size = UDim2.new(0, 70, 0, 70)
	iconFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	iconFrame.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 35
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.Text = item.icon or "?"
	iconLabel.Parent = iconFrame

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 5, 0, 90)
	nameLabel.Size = UDim2.new(1, -10, 0, 35)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = item.name
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Position = UDim2.new(0, 5, 1, -30)
	priceLabel.Size = UDim2.new(1, -10, 0, 25)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 14
	priceLabel.TextColor3 = item.isRobux and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 215, 0)
	priceLabel.Text = item.isRobux and ("R$ " .. item.price) or ("🪙 " .. item.price)
	priceLabel.Parent = card

	-- Click handler
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 1, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.Parent = card

	clickButton.MouseButton1Click:Connect(function()
		SelectItem(item)
	end)

	-- Hover effect
	clickButton.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(55, 55, 65)
		}):Play()
	end)

	clickButton.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		}):Play()
	end)

	return card
end

function SelectItem(item)
	selectedItem = item

	previewIcon.Text = item.icon or "?"
	previewName.Text = item.name
	previewRarity.Text = item.rarity
	previewRarity.TextColor3 = RARITY_COLORS[item.rarity] or RARITY_COLORS.Common
	previewDesc.Text = item.description or "No description."

	if item.isRobux then
		buyButton.Text = "R$ " .. item.price
		buyButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
	else
		buyButton.Text = "🪙 " .. item.price
		if playerCoins >= item.price then
			buyButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end
	end
end

local function LoadCategory(categoryId: string)
	-- Clear existing items
	for _, child in ipairs(itemsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local items = SHOP_DATA[categoryId] or {}

	for i, item in ipairs(items) do
		local card = CreateItemCard(item, i)
		card.Parent = itemsFrame
	end

	-- Update canvas size
	itemsFrame.CanvasSize = UDim2.new(0, 0, 0, itemsGrid.AbsoluteContentSize.Y + 20)
end

local function SelectCategory(categoryId: string)
	selectedCategory = categoryId
	selectedItem = nil

	-- Reset preview
	previewIcon.Text = "?"
	previewName.Text = "Select an item"
	previewRarity.Text = ""
	previewDesc.Text = "Browse the shop to see item details."
	buyButton.Text = "Select Item"
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

	for id, button in pairs(categoryButtons) do
		button.BackgroundColor3 = id == categoryId
			and Color3.fromRGB(60, 70, 60)
			or Color3.fromRGB(40, 40, 50)
	end

	LoadCategory(categoryId)
end

local function OpenShop()
	shopPanel.Visible = true
	SelectCategory("featured")

	-- Fetch player coins
	-- In production, this would come from DataService
	playerCoins = 500
	coinLabel.Text = tostring(playerCoins)
end

local function CloseShop()
	shopPanel.Visible = false
end

local function PurchaseItem()
	if not selectedItem then return end

	if selectedItem.isRobux then
		-- Open Roblox purchase prompt
		-- MarketplaceService:PromptProductPurchase(player, productId)
		print("[ShopUI] Would prompt Robux purchase for", selectedItem.name)
	else
		if playerCoins >= selectedItem.price then
			-- Send purchase request to server
			local purchaseItem = RemoteEvents:FindFirstChild("PurchaseShopItem")
			if purchaseItem then
				purchaseItem:FireServer(selectedItem.id)
			end

			-- Optimistic update
			playerCoins = playerCoins - selectedItem.price
			coinLabel.Text = tostring(playerCoins)

			-- Show notification
			if _G.NotificationUI then
				_G.NotificationUI.Success("Purchased!", selectedItem.name)
			end
		else
			if _G.NotificationUI then
				_G.NotificationUI.Error("Not Enough Coins", "You need " .. (selectedItem.price - playerCoins) .. " more coins.")
			end
		end
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

shopButton.MouseButton1Click:Connect(OpenShop)
closeButton.MouseButton1Click:Connect(CloseShop)
buyButton.MouseButton1Click:Connect(PurchaseItem)

for categoryId, button in pairs(categoryButtons) do
	button.MouseButton1Click:Connect(function()
		SelectCategory(categoryId)
	end)
end

-- Button hover effects
local buttons = {shopButton, closeButton, buyButton}
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

print("[ShopUI] Initialized")
