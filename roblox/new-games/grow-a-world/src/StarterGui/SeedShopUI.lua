--[[
	SeedShopUI.lua - Grow a World
	Seed shop interface - browse seeds, buy individual seeds and gacha packs
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local SeedShopUI = {}
local screenGui, shopFrame, isOpen = nil, nil, false

local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(76, 175, 80),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7),
	Mythical = Color3.fromRGB(255, 87, 34),
	Divine = Color3.fromRGB(233, 30, 99),
}

-- ============================================================================
-- UI CREATION
-- ============================================================================

function SeedShopUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SeedShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	SeedShopUI.CreateShopFrame()

	remoteEvents:WaitForChild("SeedShopData").OnClientEvent:Connect(function(shopData)
		SeedShopUI.PopulateShop(shopData)
		SeedShopUI.Open()
	end)

	remoteEvents:WaitForChild("SeedPackResult").OnClientEvent:Connect(function(results)
		SeedShopUI.ShowPackResults(results)
	end)
end

function SeedShopUI.CreateShopFrame()
	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SeedShopUI.Close()
		end
	end)

	-- Main shop frame
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(0.7, 0, 0.75, 0)
	shopFrame.Position = UDim2.new(0.15, 0, 0.125, 0)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	shopFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = shopFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = shopFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Seed Shop"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		SeedShopUI.Close()
	end)

	-- Tab buttons (Seeds / Packs)
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 40)
	tabBar.Position = UDim2.new(0, 0, 0, 50)
	tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	tabBar.BorderSizePixel = 0
	tabBar.Parent = shopFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Parent = tabBar

	for _, tabName in ipairs({"Seeds", "Seed Packs"}) do
		local tab = Instance.new("TextButton")
		tab.Name = tabName
		tab.Size = UDim2.new(0.5, 0, 1, 0)
		tab.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		tab.Text = tabName
		tab.TextColor3 = Color3.fromRGB(200, 200, 200)
		tab.TextSize = 16
		tab.Font = Enum.Font.GothamBold
		tab.BorderSizePixel = 0
		tab.Parent = tabBar

		tab.Activated:Connect(function()
			SeedShopUI.SwitchTab(tabName)
		end)
	end

	-- Content area
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -100)
	content.Position = UDim2.new(0, 10, 0, 95)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = Color3.fromRGB(156, 39, 176)
	content.Parent = shopFrame

	local contentLayout = Instance.new("UIGridLayout")
	contentLayout.CellSize = UDim2.new(0, 180, 0, 220)
	contentLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content
end

-- ============================================================================
-- SHOP POPULATION
-- ============================================================================

function SeedShopUI.PopulateShop(shopData)
	local content = shopFrame:FindFirstChild("Content")
	if not content then return end

	-- Clear existing items
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Add individual seeds
	for i, seed in ipairs(GameConfig.Seeds) do
		local card = SeedShopUI.CreateSeedCard(seed, i)
		card.Parent = content
	end

	-- Update canvas size
	local layout = content:FindFirstChild("UIGridLayout")
	if layout then
		content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end
end

function SeedShopUI.CreateSeedCard(seed, index)
	local card = Instance.new("Frame")
	card.Name = seed.Name
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	card.BorderSizePixel = 0
	card.LayoutOrder = index

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	-- Rarity stripe
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(1, 0, 0, 4)
	stripe.BackgroundColor3 = RARITY_COLORS[seed.Rarity] or Color3.fromRGB(150, 150, 150)
	stripe.BorderSizePixel = 0
	stripe.Parent = card

	-- Seed name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = seed.Name
	nameLabel.TextColor3 = RARITY_COLORS[seed.Rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -10, 0, 20)
	rarityLabel.Position = UDim2.new(0, 5, 0, 38)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = seed.Rarity
	rarityLabel.TextColor3 = RARITY_COLORS[seed.Rarity] or Color3.fromRGB(150, 150, 150)
	rarityLabel.TextSize = 11
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Parent = card

	-- Stats
	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.new(1, -10, 0, 50)
	stats.Position = UDim2.new(0, 5, 0, 65)
	stats.BackgroundTransparency = 1
	stats.Text = string.format("Grow: %ds\nValue: %d\nBiome: %s", seed.GrowTime, seed.Value, seed.Biome)
	stats.TextColor3 = Color3.fromRGB(180, 180, 180)
	stats.TextSize = 11
	stats.Font = Enum.Font.Gotham
	stats.TextWrapped = true
	stats.TextYAlignment = Enum.TextYAlignment.Top
	stats.Parent = card

	-- Price
	local price = seed.Value * 3
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -10, 0, 20)
	priceLabel.Position = UDim2.new(0, 5, 0, 150)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = tostring(price) .. " coins"
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	priceLabel.TextSize = 13
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(1, -20, 0, 35)
	buyBtn.Position = UDim2.new(0, 10, 1, -45)
	buyBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	buyBtn.Text = "Buy Seed"
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextSize = 14
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyBtn

	buyBtn.Activated:Connect(function()
		remoteEvents.BuySeed:FireServer(seed.Name)
	end)

	return card
end

function SeedShopUI.SwitchTab(tabName)
	local content = shopFrame:FindFirstChild("Content")
	if not content then return end

	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if tabName == "Seeds" then
		for i, seed in ipairs(GameConfig.Seeds) do
			local card = SeedShopUI.CreateSeedCard(seed, i)
			card.Parent = content
		end
	elseif tabName == "Seed Packs" then
		SeedShopUI.PopulatePacks(content)
	end

	-- Update tab visuals
	local tabBar = shopFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == tabName then
					tab.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
					tab.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tab.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
					tab.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end
end

function SeedShopUI.PopulatePacks(content)
	for i, pack in ipairs(GameConfig.SeedPacks) do
		local card = Instance.new("Frame")
		card.Name = pack.Name
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		card.BorderSizePixel = 0
		card.LayoutOrder = i

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		-- Pack name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 30)
		nameLabel.Position = UDim2.new(0, 5, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = pack.Name .. " Pack"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Parent = card

		-- Seeds count
		local seedsLabel = Instance.new("TextLabel")
		seedsLabel.Size = UDim2.new(1, -10, 0, 20)
		seedsLabel.Position = UDim2.new(0, 5, 0, 40)
		seedsLabel.BackgroundTransparency = 1
		seedsLabel.Text = pack.SeedCount .. " Seeds"
		seedsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		seedsLabel.TextSize = 13
		seedsLabel.Font = Enum.Font.Gotham
		seedsLabel.Parent = card

		-- Rarity odds
		local oddsText = ""
		for rarity, weight in pairs(pack.Weights) do
			if weight > 0 then
				oddsText = oddsText .. rarity .. ": " .. weight .. "%\n"
			end
		end

		local oddsLabel = Instance.new("TextLabel")
		oddsLabel.Size = UDim2.new(1, -10, 0, 80)
		oddsLabel.Position = UDim2.new(0, 5, 0, 65)
		oddsLabel.BackgroundTransparency = 1
		oddsLabel.Text = oddsText
		oddsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		oddsLabel.TextSize = 10
		oddsLabel.Font = Enum.Font.Gotham
		oddsLabel.TextWrapped = true
		oddsLabel.TextYAlignment = Enum.TextYAlignment.Top
		oddsLabel.Parent = card

		-- Price
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -10, 0, 20)
		priceLabel.Position = UDim2.new(0, 5, 0, 150)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = tostring(pack.Price) .. " coins"
		priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		priceLabel.TextSize = 14
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Parent = card

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(1, -20, 0, 35)
		buyBtn.Position = UDim2.new(0, 10, 1, -45)
		buyBtn.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
		buyBtn.Text = "Open Pack!"
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.TextSize = 14
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = card

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyBtn

		buyBtn.Activated:Connect(function()
			remoteEvents.BuySeedPack:FireServer(pack.Name)
		end)

		card.Parent = content
	end
end

-- ============================================================================
-- PACK RESULTS SCREEN
-- ============================================================================

function SeedShopUI.ShowPackResults(results)
	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "PackResults"
	resultsFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
	resultsFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	resultsFrame.ZIndex = 10
	resultsFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = resultsFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Seeds Obtained!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.Parent = resultsFrame

	local resultLayout = Instance.new("UIListLayout")
	resultLayout.Padding = UDim.new(0, 5)
	resultLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local resultContent = Instance.new("Frame")
	resultContent.Size = UDim2.new(1, -20, 1, -60)
	resultContent.Position = UDim2.new(0, 10, 0, 45)
	resultContent.BackgroundTransparency = 1
	resultContent.Parent = resultsFrame

	resultLayout.Parent = resultContent

	for _, seed in ipairs(results) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Text = seed.Name .. " (" .. seed.Rarity .. ")"
		row.TextColor3 = RARITY_COLORS[seed.Rarity] or Color3.fromRGB(255, 255, 255)
		row.TextSize = 16
		row.Font = Enum.Font.GothamBold
		row.Parent = resultContent
	end

	-- Auto-close after 5 seconds
	task.delay(5, function()
		if resultsFrame and resultsFrame.Parent then
			TweenService:Create(resultsFrame, TweenInfo.new(0.3), {
				BackgroundTransparency = 1,
			}):Play()
			task.wait(0.3)
			resultsFrame:Destroy()
		end
	end)
end

-- ============================================================================
-- OPEN / CLOSE
-- ============================================================================

function SeedShopUI.Open()
	if isOpen then return end
	isOpen = true

	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = true end
	shopFrame.Visible = true

	shopFrame.Position = UDim2.new(0.15, 0, 1, 0)
	TweenService:Create(shopFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.15, 0, 0.125, 0),
	}):Play()
end

function SeedShopUI.Close()
	if not isOpen then return end

	TweenService:Create(shopFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0.15, 0, 1, 0),
	}):Play()

	task.wait(0.2)
	shopFrame.Visible = false
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = false end
	isOpen = false
end

function SeedShopUI.IsOpen()
	return isOpen
end

SeedShopUI.Init()

return SeedShopUI
