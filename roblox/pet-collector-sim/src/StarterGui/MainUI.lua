--[[
	MainUI.lua - Pet Collector Simulator
	Main HUD: coins display, egg hatching, pet inventory, world select, shop, trading
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")
local GC = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local sg = Instance.new("ScreenGui"); sg.Name = "MainUI"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = pg

-- ============================================================================
-- TOP BAR (Coins, Level, World)
-- ============================================================================
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.5, 0, 0, 45); topBar.Position = UDim2.new(0.25, 0, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35); topBar.BackgroundTransparency = 0.2
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local coinIcon = Instance.new("TextLabel"); coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.new(0, 35, 0, 35); coinIcon.Position = UDim2.new(0, 8, 0, 5)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 215, 0); coinIcon.Text = "$"
coinIcon.TextColor3 = Color3.fromRGB(100, 70, 0); coinIcon.TextScaled = true
coinIcon.Font = Enum.Font.GothamBlack; coinIcon.Parent = topBar
Instance.new("UICorner", coinIcon).CornerRadius = UDim.new(0.5, 0)

local coinLabel = Instance.new("TextLabel"); coinLabel.Name = "Coins"
coinLabel.Size = UDim2.new(0.35, 0, 1, 0); coinLabel.Position = UDim2.new(0, 48, 0, 0)
coinLabel.BackgroundTransparency = 1; coinLabel.Text = "0"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0); coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold; coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = topBar

local worldLabel = Instance.new("TextLabel"); worldLabel.Name = "World"
worldLabel.Size = UDim2.new(0.35, 0, 1, 0); worldLabel.Position = UDim2.new(0.5, 0, 0, 0)
worldLabel.BackgroundTransparency = 1; worldLabel.Text = "Starter Island"
worldLabel.TextColor3 = Color3.fromRGB(100, 255, 200); worldLabel.TextScaled = true
worldLabel.Font = Enum.Font.GothamBold; worldLabel.Parent = topBar

local petCountLabel = Instance.new("TextLabel"); petCountLabel.Name = "PetCount"
petCountLabel.Size = UDim2.new(0.15, 0, 1, 0); petCountLabel.Position = UDim2.new(0.85, 0, 0, 0)
petCountLabel.BackgroundTransparency = 1; petCountLabel.Text = "0/20"
petCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200); petCountLabel.TextScaled = true
petCountLabel.Font = Enum.Font.Gotham; petCountLabel.Parent = topBar

-- ============================================================================
-- NAVIGATION BUTTONS (bottom)
-- ============================================================================
local navBar = Instance.new("Frame"); navBar.Name = "NavBar"
navBar.Size = UDim2.new(0.6, 0, 0, 55); navBar.Position = UDim2.new(0.2, 0, 1, -65)
navBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25); navBar.BackgroundTransparency = 0.2
navBar.Parent = sg
Instance.new("UICorner", navBar).CornerRadius = UDim.new(0, 12)
local navLayout = Instance.new("UIListLayout"); navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.Padding = UDim.new(0, 8); navLayout.Parent = navBar

local navItems = {
	{ Name = "Hatch", Icon = "Egg", Color = Color3.fromRGB(255, 180, 50) },
	{ Name = "Pets", Icon = "Paw", Color = Color3.fromRGB(100, 200, 255) },
	{ Name = "Worlds", Icon = "Globe", Color = Color3.fromRGB(100, 255, 150) },
	{ Name = "Shop", Icon = "Cart", Color = Color3.fromRGB(255, 100, 200) },
	{ Name = "Trade", Icon = "Swap", Color = Color3.fromRGB(200, 150, 255) },
}

local panels = {}
for _, item in ipairs(navItems) do
	local btn = Instance.new("TextButton"); btn.Name = item.Name
	btn.Size = UDim2.new(0, 85, 0, 42); btn.BackgroundColor3 = item.Color
	btn.Text = item.Name; btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true; btn.Font = Enum.Font.GothamBold; btn.Parent = navBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(panels) do p.Visible = false end
		if panels[item.Name] then panels[item.Name].Visible = not panels[item.Name].Visible end
	end)
end

-- ============================================================================
-- EGG HATCHING PANEL
-- ============================================================================
local hatchPanel = Instance.new("Frame"); hatchPanel.Name = "HatchPanel"
hatchPanel.Size = UDim2.new(0.55, 0, 0.55, 0); hatchPanel.Position = UDim2.new(0.225, 0, 0.15, 0)
hatchPanel.BackgroundColor3 = Color3.fromRGB(25, 20, 40); hatchPanel.Visible = false
hatchPanel.Parent = sg
Instance.new("UICorner", hatchPanel).CornerRadius = UDim.new(0, 12)
panels.Hatch = hatchPanel

local hatchTitle = Instance.new("TextLabel"); hatchTitle.Size = UDim2.new(1, 0, 0, 35)
hatchTitle.BackgroundTransparency = 1; hatchTitle.Text = "HATCH EGGS"
hatchTitle.TextColor3 = Color3.fromRGB(255, 180, 50); hatchTitle.TextScaled = true
hatchTitle.Font = Enum.Font.GothamBlack; hatchTitle.Parent = hatchPanel

local eggScroll = Instance.new("ScrollingFrame"); eggScroll.Name = "EggList"
eggScroll.Size = UDim2.new(0.9, 0, 0.82, 0); eggScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
eggScroll.BackgroundTransparency = 1; eggScroll.ScrollBarThickness = 5
eggScroll.Parent = hatchPanel
local eggGrid = Instance.new("UIGridLayout"); eggGrid.CellSize = UDim2.new(0, 140, 0, 170)
eggGrid.CellPadding = UDim2.new(0, 10, 0, 10); eggGrid.SortOrder = Enum.SortOrder.LayoutOrder
eggGrid.Parent = eggScroll

local rarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(100, 100, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythic = Color3.fromRGB(255, 50, 50),
}

-- Populate egg cards
local eggOrder = 0
for eggKey, egg in pairs(GC.Eggs) do
	eggOrder = eggOrder + 1
	local card = Instance.new("Frame"); card.Name = eggKey
	card.BackgroundColor3 = Color3.fromRGB(40, 35, 55); card.LayoutOrder = eggOrder
	card.Parent = eggScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	-- Egg visual
	local eggVisual = Instance.new("Frame"); eggVisual.Size = UDim2.new(0.6, 0, 0, 60)
	eggVisual.Position = UDim2.new(0.2, 0, 0, 10)
	eggVisual.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
	eggVisual.Parent = card
	Instance.new("UICorner", eggVisual).CornerRadius = UDim.new(0.3, 0)

	local eggLabel = Instance.new("TextLabel"); eggLabel.Size = UDim2.new(1, 0, 1, 0)
	eggLabel.BackgroundTransparency = 1; eggLabel.Text = "?"
	eggLabel.TextColor3 = Color3.fromRGB(150, 100, 50); eggLabel.TextScaled = true
	eggLabel.Font = Enum.Font.GothamBlack; eggLabel.Parent = eggVisual

	local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(1, 0, 0, 20)
	nameL.Position = UDim2.new(0, 0, 0, 72); nameL.BackgroundTransparency = 1
	nameL.Text = egg.Name; nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.TextScaled = true; nameL.Font = Enum.Font.GothamBold; nameL.Parent = card

	local costL = Instance.new("TextLabel"); costL.Size = UDim2.new(1, 0, 0, 16)
	costL.Position = UDim2.new(0, 0, 0, 92); costL.BackgroundTransparency = 1
	costL.Text = egg.Cost .. " coins"; costL.TextColor3 = Color3.fromRGB(255, 215, 0)
	costL.TextScaled = true; costL.Font = Enum.Font.Gotham; costL.Parent = card

	local hatchBtn = Instance.new("TextButton"); hatchBtn.Size = UDim2.new(0.8, 0, 0, 30)
	hatchBtn.Position = UDim2.new(0.1, 0, 1, -38); hatchBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	hatchBtn.Text = "HATCH"; hatchBtn.TextColor3 = Color3.new(1, 1, 1)
	hatchBtn.TextScaled = true; hatchBtn.Font = Enum.Font.GothamBold; hatchBtn.Parent = card
	Instance.new("UICorner", hatchBtn).CornerRadius = UDim.new(0, 6)

	hatchBtn.MouseButton1Click:Connect(function()
		re:FindFirstChild("HatchEgg"):FireServer(eggKey)
		-- Wobble animation on egg
		local wobble = TweenService:Create(eggVisual, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), { Rotation = 10 })
		wobble:Play()
	end)

	if egg.RequiresVIP then
		hatchBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 200)
		hatchBtn.Text = "VIP"
	end
end
eggScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(eggOrder / 3) * 180)

-- ============================================================================
-- PET INVENTORY PANEL
-- ============================================================================
local petPanel = Instance.new("Frame"); petPanel.Name = "PetPanel"
petPanel.Size = UDim2.new(0.6, 0, 0.6, 0); petPanel.Position = UDim2.new(0.2, 0, 0.13, 0)
petPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 40); petPanel.Visible = false
petPanel.Parent = sg
Instance.new("UICorner", petPanel).CornerRadius = UDim.new(0, 12)
panels.Pets = petPanel

local petTitle = Instance.new("TextLabel"); petTitle.Size = UDim2.new(1, 0, 0, 35)
petTitle.BackgroundTransparency = 1; petTitle.Text = "MY PETS"
petTitle.TextColor3 = Color3.fromRGB(100, 200, 255); petTitle.TextScaled = true
petTitle.Font = Enum.Font.GothamBlack; petTitle.Parent = petPanel

local petScroll = Instance.new("ScrollingFrame"); petScroll.Name = "PetList"
petScroll.Size = UDim2.new(0.9, 0, 0.82, 0); petScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
petScroll.BackgroundTransparency = 1; petScroll.ScrollBarThickness = 5
petScroll.Parent = petPanel
local petGrid = Instance.new("UIGridLayout"); petGrid.CellSize = UDim2.new(0, 120, 0, 130)
petGrid.CellPadding = UDim2.new(0, 8, 0, 8); petGrid.SortOrder = Enum.SortOrder.LayoutOrder
petGrid.Parent = petScroll

-- ============================================================================
-- WORLD SELECT PANEL
-- ============================================================================
local worldPanel = Instance.new("Frame"); worldPanel.Name = "WorldPanel"
worldPanel.Size = UDim2.new(0.55, 0, 0.55, 0); worldPanel.Position = UDim2.new(0.225, 0, 0.15, 0)
worldPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 25); worldPanel.Visible = false
worldPanel.Parent = sg
Instance.new("UICorner", worldPanel).CornerRadius = UDim.new(0, 12)
panels.Worlds = worldPanel

local worldTitle = Instance.new("TextLabel"); worldTitle.Size = UDim2.new(1, 0, 0, 35)
worldTitle.BackgroundTransparency = 1; worldTitle.Text = "WORLDS"
worldTitle.TextColor3 = Color3.fromRGB(100, 255, 150); worldTitle.TextScaled = true
worldTitle.Font = Enum.Font.GothamBlack; worldTitle.Parent = worldPanel

local worldScroll = Instance.new("ScrollingFrame"); worldScroll.Name = "WorldList"
worldScroll.Size = UDim2.new(0.9, 0, 0.82, 0); worldScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
worldScroll.BackgroundTransparency = 1; worldScroll.ScrollBarThickness = 5
worldScroll.Parent = worldPanel
local worldLayout = Instance.new("UIListLayout"); worldLayout.Padding = UDim.new(0, 8)
worldLayout.SortOrder = Enum.SortOrder.LayoutOrder; worldLayout.Parent = worldScroll

local worldColors = {
	Color3.fromRGB(80, 180, 80), Color3.fromRGB(0, 130, 60),
	Color3.fromRGB(100, 150, 255), Color3.fromRGB(255, 100, 30), Color3.fromRGB(200, 50, 200),
}

for i, world in ipairs(GC.Worlds) do
	local card = Instance.new("Frame"); card.Name = world.Name
	card.Size = UDim2.new(1, 0, 0, 65); card.BackgroundColor3 = Color3.fromRGB(35, 45, 35)
	card.LayoutOrder = i; card.Parent = worldScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local accent = Instance.new("Frame"); accent.Size = UDim2.new(0, 6, 1, 0)
	accent.BackgroundColor3 = worldColors[i] or Color3.new(1, 1, 1); accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)

	local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(0.5, 0, 0.5, 0)
	nameL.Position = UDim2.new(0.05, 0, 0, 0); nameL.BackgroundTransparency = 1
	nameL.Text = world.Name; nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.TextScaled = true; nameL.Font = Enum.Font.GothamBold
	nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.Parent = card

	local descL = Instance.new("TextLabel"); descL.Size = UDim2.new(0.5, 0, 0.5, 0)
	descL.Position = UDim2.new(0.05, 0, 0.5, 0); descL.BackgroundTransparency = 1
	descL.Text = world.Description; descL.TextColor3 = Color3.fromRGB(150, 150, 150)
	descL.TextScaled = true; descL.Font = Enum.Font.Gotham
	descL.TextXAlignment = Enum.TextXAlignment.Left; descL.Parent = card

	local costL = Instance.new("TextLabel"); costL.Size = UDim2.new(0.2, 0, 0.5, 0)
	costL.Position = UDim2.new(0.55, 0, 0, 0); costL.BackgroundTransparency = 1
	costL.Text = world.UnlockCost > 0 and (world.UnlockCost .. " coins") or (world.RequiresVIP and "VIP" or "FREE")
	costL.TextColor3 = Color3.fromRGB(255, 215, 0); costL.TextScaled = true
	costL.Font = Enum.Font.Gotham; costL.Parent = card

	local goBtn = Instance.new("TextButton"); goBtn.Size = UDim2.new(0.2, 0, 0.6, 0)
	goBtn.Position = UDim2.new(0.77, 0, 0.2, 0)
	goBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80); goBtn.Text = "GO"
	goBtn.TextColor3 = Color3.new(1, 1, 1); goBtn.TextScaled = true
	goBtn.Font = Enum.Font.GothamBold; goBtn.Parent = card
	Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 6)

	goBtn.MouseButton1Click:Connect(function()
		re:FindFirstChild("TeleportToWorld"):FireServer(world.Id)
	end)
end
worldScroll.CanvasSize = UDim2.new(0, 0, 0, #GC.Worlds * 73)

-- ============================================================================
-- SHOP PANEL
-- ============================================================================
local shopPanel = Instance.new("Frame"); shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.new(0.55, 0, 0.6, 0); shopPanel.Position = UDim2.new(0.225, 0, 0.13, 0)
shopPanel.BackgroundColor3 = Color3.fromRGB(30, 15, 30); shopPanel.Visible = false
shopPanel.Parent = sg
Instance.new("UICorner", shopPanel).CornerRadius = UDim.new(0, 12)
panels.Shop = shopPanel

local shopTitle = Instance.new("TextLabel"); shopTitle.Size = UDim2.new(1, 0, 0, 35)
shopTitle.BackgroundTransparency = 1; shopTitle.Text = "ROBUX SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 100, 200); shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.GothamBlack; shopTitle.Parent = shopPanel

local shopScroll = Instance.new("ScrollingFrame"); shopScroll.Name = "ShopList"
shopScroll.Size = UDim2.new(0.9, 0, 0.82, 0); shopScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
shopScroll.BackgroundTransparency = 1; shopScroll.ScrollBarThickness = 5
shopScroll.Parent = shopPanel
local shopLayout = Instance.new("UIListLayout"); shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder; shopLayout.Parent = shopScroll

-- Game Passes
local passOrder = 0
for passKey, pass in pairs(GC.GamePasses) do
	passOrder = passOrder + 1
	local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, 55)
	card.BackgroundColor3 = Color3.fromRGB(50, 30, 50); card.LayoutOrder = passOrder
	card.Parent = shopScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(0.4, 0, 0.5, 0)
	nameL.BackgroundTransparency = 1; nameL.Text = passKey
	nameL.TextColor3 = Color3.fromRGB(255, 200, 100); nameL.TextScaled = true
	nameL.Font = Enum.Font.GothamBold; nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.Position = UDim2.new(0.03, 0, 0, 0); nameL.Parent = card

	local descL = Instance.new("TextLabel"); descL.Size = UDim2.new(0.4, 0, 0.5, 0)
	descL.Position = UDim2.new(0.03, 0, 0.5, 0); descL.BackgroundTransparency = 1
	descL.Text = pass.Benefits[1] or ""; descL.TextColor3 = Color3.fromRGB(150, 150, 150)
	descL.TextScaled = true; descL.Font = Enum.Font.Gotham
	descL.TextXAlignment = Enum.TextXAlignment.Left; descL.Parent = card

	local buyBtn = Instance.new("TextButton"); buyBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
	buyBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
	buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100); buyBtn.Text = pass.Price .. " R$"
	buyBtn.TextColor3 = Color3.new(1, 1, 1); buyBtn.TextScaled = true
	buyBtn.Font = Enum.Font.GothamBold; buyBtn.Parent = card
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

	buyBtn.MouseButton1Click:Connect(function()
		re:FindFirstChild("PurchaseProduct"):FireServer("GamePass", passKey)
	end)
end
shopScroll.CanvasSize = UDim2.new(0, 0, 0, passOrder * 63)

-- ============================================================================
-- TRADE PANEL (placeholder)
-- ============================================================================
local tradePanel = Instance.new("Frame"); tradePanel.Name = "TradePanel"
tradePanel.Size = UDim2.new(0.5, 0, 0.5, 0); tradePanel.Position = UDim2.new(0.25, 0, 0.18, 0)
tradePanel.BackgroundColor3 = Color3.fromRGB(25, 20, 35); tradePanel.Visible = false
tradePanel.Parent = sg
Instance.new("UICorner", tradePanel).CornerRadius = UDim.new(0, 12)
panels.Trade = tradePanel

local tradeTitle = Instance.new("TextLabel"); tradeTitle.Size = UDim2.new(1, 0, 0, 35)
tradeTitle.BackgroundTransparency = 1; tradeTitle.Text = "TRADING"
tradeTitle.TextColor3 = Color3.fromRGB(200, 150, 255); tradeTitle.TextScaled = true
tradeTitle.Font = Enum.Font.GothamBlack; tradeTitle.Parent = tradePanel

local tradeInfo = Instance.new("TextLabel"); tradeInfo.Size = UDim2.new(0.8, 0, 0.3, 0)
tradeInfo.Position = UDim2.new(0.1, 0, 0.3, 0); tradeInfo.BackgroundTransparency = 1
tradeInfo.Text = "Walk up to another player and click them to trade!\nMax " .. GC.Trading.MaxPetsPerTrade .. " pets per trade"
tradeInfo.TextColor3 = Color3.fromRGB(180, 180, 180); tradeInfo.TextScaled = true
tradeInfo.Font = Enum.Font.Gotham; tradeInfo.TextWrapped = true; tradeInfo.Parent = tradePanel

-- ============================================================================
-- HATCH RESULT OVERLAY
-- ============================================================================
local hatchOverlay = Instance.new("Frame"); hatchOverlay.Name = "HatchOverlay"
hatchOverlay.Size = UDim2.new(1, 0, 1, 0); hatchOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
hatchOverlay.BackgroundTransparency = 0.7; hatchOverlay.Visible = false; hatchOverlay.Parent = sg

local hatchResultFrame = Instance.new("Frame"); hatchResultFrame.Size = UDim2.new(0.3, 0, 0.3, 0)
hatchResultFrame.Position = UDim2.new(0.35, 0, 0.3, 0)
hatchResultFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 45); hatchResultFrame.Parent = hatchOverlay
Instance.new("UICorner", hatchResultFrame).CornerRadius = UDim.new(0, 16)

local hatchPetName = Instance.new("TextLabel"); hatchPetName.Name = "PetName"
hatchPetName.Size = UDim2.new(1, 0, 0.35, 0); hatchPetName.Position = UDim2.new(0, 0, 0.1, 0)
hatchPetName.BackgroundTransparency = 1; hatchPetName.TextScaled = true
hatchPetName.Font = Enum.Font.GothamBlack; hatchPetName.Parent = hatchResultFrame

local hatchRarity = Instance.new("TextLabel"); hatchRarity.Name = "Rarity"
hatchRarity.Size = UDim2.new(1, 0, 0.2, 0); hatchRarity.Position = UDim2.new(0, 0, 0.45, 0)
hatchRarity.BackgroundTransparency = 1; hatchRarity.TextScaled = true
hatchRarity.Font = Enum.Font.GothamBold; hatchRarity.Parent = hatchResultFrame

local hatchMultLabel = Instance.new("TextLabel"); hatchMultLabel.Name = "Mult"
hatchMultLabel.Size = UDim2.new(1, 0, 0.15, 0); hatchMultLabel.Position = UDim2.new(0, 0, 0.65, 0)
hatchMultLabel.BackgroundTransparency = 1; hatchMultLabel.TextScaled = true
hatchMultLabel.Font = Enum.Font.Gotham; hatchMultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hatchMultLabel.Parent = hatchResultFrame

local tapToDismiss = Instance.new("TextButton"); tapToDismiss.Size = UDim2.new(1, 0, 0.15, 0)
tapToDismiss.Position = UDim2.new(0, 0, 0.82, 0); tapToDismiss.BackgroundTransparency = 1
tapToDismiss.Text = "Tap to dismiss"; tapToDismiss.TextColor3 = Color3.fromRGB(150, 150, 150)
tapToDismiss.TextScaled = true; tapToDismiss.Font = Enum.Font.Gotham
tapToDismiss.Parent = hatchResultFrame
tapToDismiss.MouseButton1Click:Connect(function() hatchOverlay.Visible = false end)

-- ============================================================================
-- CENTER NOTIFICATION
-- ============================================================================
local notifFrame = Instance.new("Frame"); notifFrame.Name = "Notifications"
notifFrame.Size = UDim2.new(0.3, 0, 0.25, 0); notifFrame.Position = UDim2.new(0.01, 0, 0.7, 0)
notifFrame.BackgroundTransparency = 1; notifFrame.Parent = sg
local notifLayout = Instance.new("UIListLayout"); notifLayout.Padding = UDim.new(0, 4)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder; notifLayout.Parent = notifFrame

local function showNotif(text, color, duration)
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30); label.BackgroundTransparency = 0.4
	label.Text = text; label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = true; label.Font = Enum.Font.GothamBold; label.Parent = notifFrame
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)
	task.delay(duration or 3, function()
		local fade = TweenService:Create(label, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 })
		fade:Play(); fade.Completed:Connect(function() label:Destroy() end)
	end)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Coin updates
re:WaitForChild("CoinUpdate").OnClientEvent:Connect(function(amount)
	coinLabel.Text = tostring(amount)
end)

-- Pet hatched
re:WaitForChild("UpdateClientData").OnClientEvent:Connect(function(data)
	if data.Coins then coinLabel.Text = tostring(data.Coins) end
	if data.PetCount and data.MaxPets then petCountLabel.Text = data.PetCount .. "/" .. data.MaxPets end
	if data.World then worldLabel.Text = data.World end

	if data.HatchResult then
		local pet = data.HatchResult
		hatchPetName.Text = pet.Name
		hatchPetName.TextColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
		hatchRarity.Text = pet.Rarity
		hatchRarity.TextColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
		hatchMultLabel.Text = pet.CoinMultiplier .. "x Coin Multiplier"
		hatchOverlay.Visible = true

		-- Pop-in animation
		hatchResultFrame.Size = UDim2.new(0.05, 0, 0.05, 0)
		hatchResultFrame.Position = UDim2.new(0.475, 0, 0.475, 0)
		TweenService:Create(hatchResultFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
			Size = UDim2.new(0.3, 0, 0.3, 0),
			Position = UDim2.new(0.35, 0, 0.3, 0),
		}):Play()

		task.delay(3, function() hatchOverlay.Visible = false end)
	end

	-- Update pet inventory display
	if data.Pets then
		for _, c in ipairs(petScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for idx, pet in ipairs(data.Pets) do
			local card = Instance.new("Frame"); card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
			card.LayoutOrder = idx; card.Parent = petScroll
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local rBar = Instance.new("Frame"); rBar.Size = UDim2.new(1, 0, 0, 4)
			rBar.BackgroundColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
			rBar.Parent = card
			Instance.new("UICorner", rBar).CornerRadius = UDim.new(0, 2)

			local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(1, 0, 0, 22)
			nameL.Position = UDim2.new(0, 0, 0, 8); nameL.BackgroundTransparency = 1
			nameL.Text = pet.Name; nameL.TextColor3 = Color3.new(1, 1, 1)
			nameL.TextScaled = true; nameL.Font = Enum.Font.GothamBold; nameL.Parent = card

			local rarL = Instance.new("TextLabel"); rarL.Size = UDim2.new(1, 0, 0, 16)
			rarL.Position = UDim2.new(0, 0, 0, 30); rarL.BackgroundTransparency = 1
			rarL.Text = pet.Rarity; rarL.TextColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
			rarL.TextScaled = true; rarL.Font = Enum.Font.Gotham; rarL.Parent = card

			local multL = Instance.new("TextLabel"); multL.Size = UDim2.new(1, 0, 0, 14)
			multL.Position = UDim2.new(0, 0, 0, 48); multL.BackgroundTransparency = 1
			multL.Text = pet.CoinMultiplier .. "x"; multL.TextColor3 = Color3.fromRGB(255, 215, 0)
			multL.TextScaled = true; multL.Font = Enum.Font.Gotham; multL.Parent = card

			local equipped = pet.Equipped
			local equipBtn = Instance.new("TextButton"); equipBtn.Size = UDim2.new(0.8, 0, 0, 24)
			equipBtn.Position = UDim2.new(0.1, 0, 1, -30)
			equipBtn.BackgroundColor3 = equipped and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 80)
			equipBtn.Text = equipped and "Unequip" or "Equip"
			equipBtn.TextColor3 = Color3.new(1, 1, 1); equipBtn.TextScaled = true
			equipBtn.Font = Enum.Font.GothamBold; equipBtn.Parent = card
			Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 4)

			equipBtn.MouseButton1Click:Connect(function()
				if equipped then
					re:FindFirstChild("UnequipPet"):FireServer(pet.Id)
				else
					re:FindFirstChild("EquipPet"):FireServer(pet.Id)
				end
			end)
		end
		petScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#data.Pets / 4) * 138)
	end
end)

-- Notifications
re:WaitForChild("ShowNotification").OnClientEvent:Connect(function(data)
	local text = type(data) == "string" and data or (data.Message or data.Text or "")
	local color = data and data.Color and Color3.fromRGB(unpack(data.Color)) or Color3.new(1, 1, 1)
	showNotif(text, color, data and data.Duration or 3)
end)

-- Close panels on click outside (click topbar area)
hatchOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		hatchOverlay.Visible = false
	end
end)
