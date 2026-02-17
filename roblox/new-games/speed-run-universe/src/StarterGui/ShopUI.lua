--[[
	ShopUI.lua - Speed Run Universe
	Shop interface for trails, win effects, world unlocks, game passes, and dev products.
	Toggle with M key or shop button.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local ShopUI = {}
local screenGui
local mainFrame
local isOpen = false
local currentTab = "Trails"

-- ============================================================================
-- COLORS
-- ============================================================================
local Colors = {
	Background = Color3.fromRGB(15, 15, 25),
	Panel = Color3.fromRGB(22, 22, 36),
	CardBg = Color3.fromRGB(30, 30, 48),
	CardHover = Color3.fromRGB(40, 40, 60),
	Accent = Color3.fromRGB(0, 200, 255),
	Gold = Color3.fromRGB(255, 200, 0),
	Green = Color3.fromRGB(0, 255, 120),
	Red = Color3.fromRGB(255, 60, 60),
	Purple = Color3.fromRGB(180, 80, 255),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	TextMuted = Color3.fromRGB(100, 100, 120),
	Owned = Color3.fromRGB(60, 180, 60),
}

-- ============================================================================
-- INIT
-- ============================================================================
function ShopUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	ShopUI._CreateToggleButton()
	ShopUI._CreateMainFrame()

	-- Key binding: M to toggle
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.M then
			ShopUI.Toggle()
		end
	end)

	-- Listen for shop data
	remoteEvents:WaitForChild("ShopData").OnClientEvent:Connect(function(data)
		ShopUI._PopulateShop(data)
	end)

	-- Listen for cosmetic sync (to update owned status)
	remoteEvents:WaitForChild("CosmeticSync").OnClientEvent:Connect(function(data)
		ShopUI._UpdateOwnedStatus(data)
	end)
end

-- ============================================================================
-- TOGGLE BUTTON
-- ============================================================================
function ShopUI._CreateToggleButton()
	local btn = Instance.new("TextButton")
	btn.Name = "ShopToggle"
	btn.Size = UDim2.new(0, 80, 0, 32)
	btn.Position = UDim2.new(1, -260, 0, 8)
	btn.BackgroundColor3 = Colors.Purple
	btn.BorderSizePixel = 0
	btn.Text = "SHOP [M]"
	btn.TextColor3 = Colors.TextPrimary
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		ShopUI.Toggle()
	end)
end

-- ============================================================================
-- MAIN FRAME
-- ============================================================================
function ShopUI._CreateMainFrame()
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "ShopMain"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Colors.Background
	mainFrame.BackgroundTransparency = 0.05
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Accent
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Colors.Panel
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SPEED RUN SHOP"
	titleLabel.TextColor3 = Colors.Accent
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Colors.Red
	closeBtn.BackgroundTransparency = 0.5
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Colors.TextPrimary
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		ShopUI.Toggle()
	end)

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 36)
	tabBar.Position = UDim2.new(0, 10, 0, 45)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabBar

	local tabs = { "Trails", "Effects", "Worlds", "Passes", "Products" }
	for _, tabName in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. tabName
		tab.Size = UDim2.new(0, 120, 0, 32)
		tab.BackgroundColor3 = tabName == currentTab and Colors.Accent or Colors.CardBg
		tab.BackgroundTransparency = tabName == currentTab and 0.2 or 0.5
		tab.BorderSizePixel = 0
		tab.Text = tabName
		tab.TextColor3 = tabName == currentTab and Colors.TextPrimary or Colors.TextSecondary
		tab.TextSize = 12
		tab.Font = Enum.Font.GothamBold
		tab.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			ShopUI._SwitchTab(tabName)
		end)
	end

	-- Content area (scrolling frame)
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -20, 1, -95)
	contentFrame.Position = UDim2.new(0, 10, 0, 85)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 6
	contentFrame.ScrollBarImageColor3 = Colors.Accent
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = mainFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.Name = "GridLayout"
	gridLayout.CellSize = UDim2.new(0, 210, 0, 120)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = contentFrame
end

-- ============================================================================
-- TAB SWITCHING
-- ============================================================================
function ShopUI._SwitchTab(tabName)
	currentTab = tabName

	-- Update tab visual
	local tabBar = mainFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				local isActive = tab.Name == "Tab_" .. tabName
				tab.BackgroundColor3 = isActive and Colors.Accent or Colors.CardBg
				tab.BackgroundTransparency = isActive and 0.2 or 0.5
				tab.TextColor3 = isActive and Colors.TextPrimary or Colors.TextSecondary
			end
		end
	end

	-- Request fresh data and repopulate
	remoteEvents:WaitForChild("GetShopData"):FireServer()
end

-- ============================================================================
-- POPULATE SHOP
-- ============================================================================
function ShopUI._PopulateShop(shopData)
	local content = mainFrame:FindFirstChild("Content")
	if not content then return end

	-- Clear existing cards
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if currentTab == "Trails" then
		ShopUI._PopulateTrails(content, shopData)
	elseif currentTab == "Effects" then
		ShopUI._PopulateEffects(content, shopData)
	elseif currentTab == "Worlds" then
		ShopUI._PopulateWorlds(content, shopData)
	elseif currentTab == "Passes" then
		ShopUI._PopulatePasses(content, shopData)
	elseif currentTab == "Products" then
		ShopUI._PopulateProducts(content, shopData)
	end

	-- Update canvas size
	task.wait()
	local gridLayout = content:FindFirstChild("GridLayout")
	if gridLayout then
		content.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end
end

function ShopUI._PopulateTrails(content, shopData)
	for i, trail in ipairs(GameConfig.Trails) do
		local isOwned = shopData and shopData.OwnedPasses and false -- Will be updated by cosmetic sync
		ShopUI._CreateCard(content, {
			LayoutOrder = i,
			Title = trail.Name,
			Description = trail.Category,
			Cost = trail.Cost,
			CostLabel = "coins",
			Color1 = trail.Color1,
			Color2 = trail.Color2,
			IsOwned = isOwned,
			OnClick = function()
				remoteEvents:WaitForChild("BuyTrail"):FireServer({ TrailId = trail.Id })
			end,
			OnEquip = function()
				remoteEvents:WaitForChild("EquipTrail"):FireServer({ TrailId = trail.Id })
			end,
		})
	end
end

function ShopUI._PopulateEffects(content, shopData)
	for i, effect in ipairs(GameConfig.WinEffects) do
		ShopUI._CreateCard(content, {
			LayoutOrder = i,
			Title = effect.Name,
			Description = effect.Description,
			Cost = effect.Cost,
			CostLabel = "coins",
			IsOwned = false,
			OnClick = function()
				remoteEvents:WaitForChild("BuyWinEffect"):FireServer({ EffectId = effect.Id })
			end,
			OnEquip = function()
				remoteEvents:WaitForChild("EquipWinEffect"):FireServer({ EffectId = effect.Id })
			end,
		})
	end
end

function ShopUI._PopulateWorlds(content, shopData)
	for i, world in ipairs(GameConfig.Worlds) do
		local isUnlocked = false
		-- Check from player data
		if shopData then
			-- We'll rely on notification sync
		end

		if world.UnlockCost == 0 then isUnlocked = true end

		ShopUI._CreateCard(content, {
			LayoutOrder = i,
			Title = world.Name,
			Description = "Difficulty: " .. world.Difficulty .. "/10 | " .. world.StageCount .. " stages",
			Cost = world.UnlockCost,
			CostLabel = "coins",
			IsOwned = isUnlocked,
			OwnedLabel = "UNLOCKED",
			Color1 = world.BackgroundColor,
			OnClick = function()
				remoteEvents:WaitForChild("UnlockWorld"):FireServer({ WorldId = world.Id })
			end,
		})
	end
end

function ShopUI._PopulatePasses(content, shopData)
	local i = 1
	for name, cfg in pairs(GameConfig.GamePasses) do
		local isOwned = shopData and shopData.OwnedPasses and shopData.OwnedPasses[name] or false
		ShopUI._CreateCard(content, {
			LayoutOrder = i,
			Title = cfg.Name,
			Description = cfg.Description,
			Cost = cfg.Price,
			CostLabel = "R$",
			IsOwned = isOwned,
			OwnedLabel = "OWNED",
			AccentColor = Colors.Purple,
			OnClick = function()
				remoteEvents:WaitForChild("PurchaseGamePass"):FireServer(name)
			end,
		})
		i = i + 1
	end
end

function ShopUI._PopulateProducts(content, shopData)
	local i = 1
	for name, cfg in pairs(GameConfig.DevProducts) do
		ShopUI._CreateCard(content, {
			LayoutOrder = i,
			Title = cfg.Name,
			Description = cfg.Description or "",
			Cost = cfg.Price,
			CostLabel = "R$",
			IsOwned = false,
			AccentColor = Colors.Gold,
			OnClick = function()
				remoteEvents:WaitForChild("PurchaseDevProduct"):FireServer(name)
			end,
		})
		i = i + 1
	end
end

-- ============================================================================
-- CREATE CARD
-- ============================================================================
function ShopUI._CreateCard(parent, options)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. (options.Title or "Unknown")
	card.BackgroundColor3 = Colors.CardBg
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.LayoutOrder = options.LayoutOrder or 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	-- Color strip at top
	if options.Color1 then
		local strip = Instance.new("Frame")
		strip.Size = UDim2.new(1, 0, 0, 4)
		strip.BackgroundColor3 = options.Color1
		strip.BorderSizePixel = 0
		strip.Parent = card

		local stripCorner = Instance.new("UICorner")
		stripCorner.CornerRadius = UDim.new(0, 10)
		stripCorner.Parent = strip
	end

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -10, 0, 20)
	title.Position = UDim2.new(0, 8, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = options.Title or "Item"
	title.TextColor3 = Colors.TextPrimary
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -10, 0, 30)
	desc.Position = UDim2.new(0, 8, 0, 30)
	desc.BackgroundTransparency = 1
	desc.Text = options.Description or ""
	desc.TextColor3 = Colors.TextMuted
	desc.TextSize = 10
	desc.Font = Enum.Font.GothamMedium
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = card

	-- Price / Buy button
	if options.IsOwned then
		local ownedLabel = Instance.new("TextLabel")
		ownedLabel.Size = UDim2.new(1, -16, 0, 28)
		ownedLabel.Position = UDim2.new(0, 8, 1, -34)
		ownedLabel.BackgroundColor3 = Colors.Owned
		ownedLabel.BackgroundTransparency = 0.5
		ownedLabel.Text = options.OwnedLabel or "OWNED"
		ownedLabel.TextColor3 = Colors.Green
		ownedLabel.TextSize = 12
		ownedLabel.Font = Enum.Font.GothamBold
		ownedLabel.Parent = card

		local ownedCorner = Instance.new("UICorner")
		ownedCorner.CornerRadius = UDim.new(0, 6)
		ownedCorner.Parent = ownedLabel

		-- Equip button if applicable
		if options.OnEquip then
			local equipBtn = Instance.new("TextButton")
			equipBtn.Size = UDim2.new(0.5, -4, 0, 28)
			equipBtn.Position = UDim2.new(0.5, 4, 1, -34)
			equipBtn.BackgroundColor3 = Colors.Accent
			equipBtn.BackgroundTransparency = 0.3
			equipBtn.BorderSizePixel = 0
			equipBtn.Text = "EQUIP"
			equipBtn.TextColor3 = Colors.TextPrimary
			equipBtn.TextSize = 11
			equipBtn.Font = Enum.Font.GothamBold
			equipBtn.Parent = card

			ownedLabel.Size = UDim2.new(0.5, -4, 0, 28)

			local equipCorner = Instance.new("UICorner")
			equipCorner.CornerRadius = UDim.new(0, 6)
			equipCorner.Parent = equipBtn

			equipBtn.MouseButton1Click:Connect(function()
				if options.OnEquip then options.OnEquip() end
			end)
		end
	else
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(1, -16, 0, 28)
		buyBtn.Position = UDim2.new(0, 8, 1, -34)
		buyBtn.BackgroundColor3 = options.AccentColor or Colors.Accent
		buyBtn.BackgroundTransparency = 0.2
		buyBtn.BorderSizePixel = 0
		buyBtn.Text = (options.CostLabel or "") .. " " .. tostring(options.Cost or 0)
		buyBtn.TextColor3 = Colors.TextPrimary
		buyBtn.TextSize = 12
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = card

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 6)
		buyCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			if options.OnClick then options.OnClick() end
		end)

		-- Hover effect
		buyBtn.MouseEnter:Connect(function()
			TweenService:Create(buyBtn, TweenInfo.new(0.15), {
				BackgroundTransparency = 0,
			}):Play()
		end)
		buyBtn.MouseLeave:Connect(function()
			TweenService:Create(buyBtn, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.2,
			}):Play()
		end)
	end
end

-- ============================================================================
-- UPDATE OWNED STATUS
-- ============================================================================
function ShopUI._UpdateOwnedStatus(cosmeticData)
	-- Re-request shop data to refresh display
	if isOpen then
		remoteEvents:WaitForChild("GetShopData"):FireServer()
	end
end

-- ============================================================================
-- TOGGLE
-- ============================================================================
function ShopUI.Toggle()
	isOpen = not isOpen
	mainFrame.Visible = isOpen

	if isOpen then
		-- Request shop data
		remoteEvents:WaitForChild("GetShopData"):FireServer()
	end
end

-- ============================================================================
-- BOOTSTRAP
-- ============================================================================
ShopUI.Init()

return ShopUI
