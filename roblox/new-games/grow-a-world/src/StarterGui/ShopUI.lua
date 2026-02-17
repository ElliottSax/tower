--[[
	ShopUI.lua - Grow a World
	Robux shop - Game Passes and Developer Products
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local ShopUI = {}
local screenGui, shopFrame, isOpen = nil, nil, false

function ShopUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	ShopUI.CreateShopFrame()

	remoteEvents:WaitForChild("ShopData").OnClientEvent:Connect(function(shopData)
		ShopUI.PopulateShop(shopData)
		ShopUI.Open()
	end)
end

function ShopUI.CreateShopFrame()
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			ShopUI.Close()
		end
	end)

	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(0.7, 0, 0.75, 0)
	shopFrame.Position = UDim2.new(0.15, 0, 0.125, 0)
	shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	shopFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = shopFrame

	-- Title
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(233, 30, 99)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = shopFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Premium Shop"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
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
		ShopUI.Close()
	end)

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 40)
	tabBar.Position = UDim2.new(0, 0, 0, 50)
	tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	tabBar.BorderSizePixel = 0
	tabBar.Parent = shopFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Parent = tabBar

	for _, tabName in ipairs({"Game Passes", "Boosts & Items"}) do
		local tab = Instance.new("TextButton")
		tab.Name = tabName
		tab.Size = UDim2.new(0.5, 0, 1, 0)
		tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		tab.Text = tabName
		tab.TextColor3 = Color3.fromRGB(200, 200, 200)
		tab.TextSize = 15
		tab.Font = Enum.Font.GothamBold
		tab.BorderSizePixel = 0
		tab.Parent = tabBar

		tab.Activated:Connect(function()
			ShopUI.SwitchTab(tabName)
		end)
	end

	-- Content
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -100)
	content.Position = UDim2.new(0, 10, 0, 95)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = Color3.fromRGB(233, 30, 99)
	content.Parent = shopFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 220, 0, 200)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = content
end

function ShopUI.PopulateShop(shopData)
	if not shopData then return end
	ShopUI._shopData = shopData
	ShopUI.SwitchTab("Game Passes")
end

function ShopUI.SwitchTab(tabName)
	local content = shopFrame:FindFirstChild("Content")
	if not content or not ShopUI._shopData then return end

	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Update tab visuals
	local tabBar = shopFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == tabName then
					tab.BackgroundColor3 = Color3.fromRGB(233, 30, 99)
					tab.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
					tab.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end

	local i = 0
	if tabName == "Game Passes" then
		for name, pass in pairs(ShopUI._shopData.GamePasses or {}) do
			i = i + 1
			local card = ShopUI.CreatePassCard(name, pass, i)
			card.Parent = content
		end
	else
		for name, product in pairs(ShopUI._shopData.DevProducts or {}) do
			i = i + 1
			local card = ShopUI.CreateProductCard(name, product, i)
			card.Parent = content
		end
	end

	local grid = content:FindFirstChild("UIGridLayout")
	if grid then
		content.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
	end
end

function ShopUI.CreatePassCard(name, pass, index)
	local card = Instance.new("Frame")
	card.Name = name
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	card.BorderSizePixel = 0
	card.LayoutOrder = index

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 35)
	nameLabel.Position = UDim2.new(0, 5, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = pass.Name or name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 60)
	descLabel.Position = UDim2.new(0, 5, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = pass.Description or ""
	descLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	descLabel.TextSize = 11
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0, 25)
	priceLabel.Position = UDim2.new(0, 0, 0, 110)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "R$ " .. tostring(pass.Price or 0)
	priceLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
	priceLabel.TextSize = 16
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 35)
	btn.Position = UDim2.new(0, 10, 1, -45)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	if pass.Owned then
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Text = "Owned"
	else
		btn.BackgroundColor3 = Color3.fromRGB(233, 30, 99)
		btn.Text = "Purchase"
		btn.Activated:Connect(function()
			remoteEvents.PurchaseGamePass:FireServer(name)
		end)
	end

	return card
end

function ShopUI.CreateProductCard(name, product, index)
	local card = Instance.new("Frame")
	card.Name = name
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	card.BorderSizePixel = 0
	card.LayoutOrder = index

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 35)
	nameLabel.Position = UDim2.new(0, 5, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = product.Name or name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 60)
	descLabel.Position = UDim2.new(0, 5, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = product.Description or ""
	descLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	descLabel.TextSize = 11
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0, 25)
	priceLabel.Position = UDim2.new(0, 0, 0, 110)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "R$ " .. tostring(product.Price or 0)
	priceLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
	priceLabel.TextSize = 16
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 35)
	btn.Position = UDim2.new(0, 10, 1, -45)
	btn.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
	btn.Text = "Buy Now"
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	btn.Activated:Connect(function()
		remoteEvents.PurchaseDevProduct:FireServer(name)
	end)

	return card
end

function ShopUI.Open()
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

function ShopUI.Close()
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

ShopUI.Init()

return ShopUI
