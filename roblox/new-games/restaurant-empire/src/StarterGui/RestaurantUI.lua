--[[
	RestaurantUI.lua - Restaurant Empire
	Main HUD: restaurant view, cooking minigame, staff panel, menu, upgrades
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

local sg = Instance.new("ScreenGui"); sg.Name = "RestaurantUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- Top HUD (coins, stars, level, location)
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.55, 0, 0, 45); topBar.Position = UDim2.new(0.225, 0, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(30, 15, 10); topBar.BackgroundTransparency = 0.3
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local coinLabel = Instance.new("TextLabel"); coinLabel.Name = "Coins"
coinLabel.Size = UDim2.new(0.25, 0, 1, 0); coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"; coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true; coinLabel.Font = Enum.Font.GothamBold; coinLabel.Parent = topBar

local starLabel = Instance.new("TextLabel"); starLabel.Name = "Stars"
starLabel.Size = UDim2.new(0.25, 0, 1, 0); starLabel.Position = UDim2.new(0.25, 0, 0, 0)
starLabel.BackgroundTransparency = 1; starLabel.Text = "Stars: 0"
starLabel.TextColor3 = Color3.fromRGB(255, 200, 50); starLabel.TextScaled = true
starLabel.Font = Enum.Font.GothamBold; starLabel.Parent = topBar

local levelLabel = Instance.new("TextLabel"); levelLabel.Name = "Level"
levelLabel.Size = UDim2.new(0.25, 0, 1, 0); levelLabel.Position = UDim2.new(0.5, 0, 0, 0)
levelLabel.BackgroundTransparency = 1; levelLabel.Text = "Lv. 1"
levelLabel.TextColor3 = Color3.fromRGB(150, 255, 150); levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold; levelLabel.Parent = topBar

local locLabel = Instance.new("TextLabel"); locLabel.Name = "Location"
locLabel.Size = UDim2.new(0.25, 0, 1, 0); locLabel.Position = UDim2.new(0.75, 0, 0, 0)
locLabel.BackgroundTransparency = 1; locLabel.Text = "Food Cart"
locLabel.TextColor3 = Color3.fromRGB(200, 150, 100); locLabel.TextScaled = true
locLabel.Font = Enum.Font.GothamBold; locLabel.Parent = topBar

-- Navigation tabs
local tabFrame = Instance.new("Frame"); tabFrame.Name = "Tabs"
tabFrame.Size = UDim2.new(0.6, 0, 0, 35); tabFrame.Position = UDim2.new(0.2, 0, 0, 58)
tabFrame.BackgroundTransparency = 1; tabFrame.Parent = sg
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 6); tabLayout.Parent = tabFrame

local tabNames = { "Cook", "Menu", "Staff", "Decor", "Expand", "Shop" }
local tabColors = {
	Cook = Color3.fromRGB(220, 80, 20),
	Menu = Color3.fromRGB(50, 150, 50),
	Staff = Color3.fromRGB(80, 80, 200),
	Decor = Color3.fromRGB(200, 100, 200),
	Expand = Color3.fromRGB(200, 180, 50),
	Shop = Color3.fromRGB(0, 180, 200),
}

local panels = {}

for _, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton"); btn.Name = name
	btn.Size = UDim2.new(0, 80, 1, 0); btn.BackgroundColor3 = tabColors[name]
	btn.Text = name; btn.TextColor3 = Color3.new(1, 1, 1); btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold; btn.Parent = tabFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(panels) do p.Visible = false end
		if panels[name] then panels[name].Visible = true end
		if name == "Staff" then re:FindFirstChild("GetStaff"):FireServer()
		elseif name == "Shop" then re:FindFirstChild("GetShopData"):FireServer()
		end
	end)
end

-- Create main panels
local function createPanel(name)
	local panel = Instance.new("Frame"); panel.Name = name .. "Panel"
	panel.Size = UDim2.new(0.6, 0, 0.6, 0); panel.Position = UDim2.new(0.2, 0, 0.18, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 20, 15); panel.Visible = false
	panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1; title.Text = string.upper(name)
	title.TextColor3 = tabColors[name] or Color3.new(1, 1, 1)
	title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = panel

	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"
	scroll.Size = UDim2.new(0.9, 0, 0.84, 0); scroll.Position = UDim2.new(0.05, 0, 0.1, 0)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5
	scroll.Parent = panel

	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll

	panels[name] = panel
	return panel, scroll
end

local cookPanel, cookScroll = createPanel("Cook")
local menuPanel, menuScroll = createPanel("Menu")
local staffPanel, staffScroll = createPanel("Staff")
local decorPanel, decorScroll = createPanel("Decor")
local expandPanel, expandScroll = createPanel("Expand")
local shopPanel, shopScroll = createPanel("Shop")

-- Cooking minigame area
local cookingArea = Instance.new("Frame"); cookingArea.Name = "CookingArea"
cookingArea.Size = UDim2.new(0.4, 0, 0.25, 0); cookingArea.Position = UDim2.new(0.3, 0, 0.7, 0)
cookingArea.BackgroundColor3 = Color3.fromRGB(40, 25, 15); cookingArea.BackgroundTransparency = 0.3
cookingArea.Visible = false; cookingArea.Parent = sg
Instance.new("UICorner", cookingArea).CornerRadius = UDim.new(0, 10)

local cookingLabel = Instance.new("TextLabel"); cookingLabel.Name = "CookingLabel"
cookingLabel.Size = UDim2.new(1, 0, 0.4, 0); cookingLabel.BackgroundTransparency = 1
cookingLabel.Text = "Cooking..."; cookingLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
cookingLabel.TextScaled = true; cookingLabel.Font = Enum.Font.GothamBold
cookingLabel.Parent = cookingArea

local cookingBar = Instance.new("Frame"); cookingBar.Name = "BarBG"
cookingBar.Size = UDim2.new(0.8, 0, 0, 20); cookingBar.Position = UDim2.new(0.1, 0, 0.5, 0)
cookingBar.BackgroundColor3 = Color3.fromRGB(60, 30, 10); cookingBar.Parent = cookingArea
Instance.new("UICorner", cookingBar).CornerRadius = UDim.new(0, 4)

local cookingFill = Instance.new("Frame"); cookingFill.Name = "Fill"
cookingFill.Size = UDim2.new(0, 0, 1, 0); cookingFill.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
cookingFill.Parent = cookingBar
Instance.new("UICorner", cookingFill).CornerRadius = UDim.new(0, 4)

local cookBtn = Instance.new("TextButton"); cookBtn.Name = "StopCook"
cookBtn.Size = UDim2.new(0.4, 0, 0, 30); cookBtn.Position = UDim2.new(0.3, 0, 0.72, 0)
cookBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80); cookBtn.Text = "SERVE!"
cookBtn.TextColor3 = Color3.new(1, 1, 1); cookBtn.TextScaled = true
cookBtn.Font = Enum.Font.GothamBold; cookBtn.Parent = cookingArea
Instance.new("UICorner", cookBtn).CornerRadius = UDim.new(0, 6)

-- Customer order popup
local orderPopup = Instance.new("Frame"); orderPopup.Name = "OrderPopup"
orderPopup.Size = UDim2.new(0.3, 0, 0, 50); orderPopup.Position = UDim2.new(0.35, 0, 0.62, 0)
orderPopup.BackgroundColor3 = Color3.fromRGB(50, 30, 10); orderPopup.Visible = false
orderPopup.Parent = sg
Instance.new("UICorner", orderPopup).CornerRadius = UDim.new(0, 8)

local orderText = Instance.new("TextLabel"); orderText.Size = UDim2.new(1, 0, 1, 0)
orderText.BackgroundTransparency = 1; orderText.TextScaled = true
orderText.Font = Enum.Font.GothamBold; orderText.TextColor3 = Color3.new(1, 1, 1)
orderText.Parent = orderPopup

-- Center message
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMsg"
centerMsg.Size = UDim2.new(0.5, 0, 0.1, 0); centerMsg.Position = UDim2.new(0.25, 0, 0.35, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Visible = false
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Parent = sg

local function showCenter(text, dur, color)
	centerMsg.Text = text; centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(dur or 3, function() centerMsg.Visible = false end)
end

-- Cooking state
local isCooking = false
local cookStartTime = 0
local cookDuration = 0

cookBtn.MouseButton1Click:Connect(function()
	if isCooking then
		re:FindFirstChild("CookDish"):FireServer("serve")
		isCooking = false; cookingArea.Visible = false
	end
end)

-- Event Listeners
re:WaitForChild("RestaurantSync").OnClientEvent:Connect(function(data)
	if data.Coins then coinLabel.Text = "Coins: " .. data.Coins end
	if data.Stars then starLabel.Text = "Stars: " .. string.format("%.1f", data.Stars) end
	if data.Level then levelLabel.Text = "Lv. " .. data.Level end
	if data.Location then locLabel.Text = data.Location end
end)

re:WaitForChild("CustomerOrder").OnClientEvent:Connect(function(data)
	orderPopup.Visible = true
	orderText.Text = "Order: " .. (data.Recipe or "Unknown") .. " (" .. (data.Cuisine or "") .. ")"
	task.delay(5, function() orderPopup.Visible = false end)
end)

re:WaitForChild("CookResult").OnClientEvent:Connect(function(data)
	isCooking = false; cookingArea.Visible = false
	if data.Quality then
		local qualStr = data.Quality >= 0.8 and "PERFECT!" or (data.Quality >= 0.5 and "Good" or "Burnt")
		local color = data.Quality >= 0.8 and Color3.fromRGB(255, 215, 0) or (data.Quality >= 0.5 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 50, 50))
		showCenter(qualStr .. " +" .. (data.CoinsEarned or 0) .. " coins\nSatisfaction: " .. math.floor((data.Satisfaction or 0) * 100) .. "%", 3, color)
	end
end)

re:WaitForChild("StaffSync").OnClientEvent:Connect(function(staffList)
	for _, c in ipairs(staffScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	if type(staffList) == "table" then
		for i, s in ipairs(staffList) do
			local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, 50)
			card.BackgroundColor3 = Color3.fromRGB(40, 30, 20); card.LayoutOrder = i
			card.Parent = staffScroll
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

			local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(0.4, 0, 1, 0)
			nameL.BackgroundTransparency = 1; nameL.Text = s.Name .. " (" .. s.Type .. ")"
			nameL.TextColor3 = Color3.new(1, 1, 1); nameL.TextScaled = true
			nameL.Font = Enum.Font.GothamBold; nameL.TextXAlignment = Enum.TextXAlignment.Left
			nameL.Parent = card

			local skillL = Instance.new("TextLabel"); skillL.Size = UDim2.new(0.3, 0, 1, 0)
			skillL.Position = UDim2.new(0.4, 0, 0, 0); skillL.BackgroundTransparency = 1
			skillL.Text = "Skill: " .. (s.Skill or 0)
			skillL.TextColor3 = Color3.fromRGB(150, 255, 150); skillL.TextScaled = true
			skillL.Font = Enum.Font.Gotham; skillL.Parent = card

			local fireBtn = Instance.new("TextButton"); fireBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
			fireBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
			fireBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); fireBtn.Text = "Fire"
			fireBtn.TextColor3 = Color3.new(1, 1, 1); fireBtn.TextScaled = true
			fireBtn.Font = Enum.Font.GothamBold; fireBtn.Parent = card
			Instance.new("UICorner", fireBtn).CornerRadius = UDim.new(0, 4)
			fireBtn.MouseButton1Click:Connect(function()
				re:FindFirstChild("FireStaff"):FireServer(i)
			end)
		end
		staffScroll.CanvasSize = UDim2.new(0, 0, 0, #staffList * 56)
	end
end)

re:WaitForChild("ShopData").OnClientEvent:Connect(function(data)
	showCenter("Shop loaded!", 1.5, Color3.fromRGB(0, 180, 200))
end)

re:WaitForChild("Notification").OnClientEvent:Connect(function(data)
	local msg = type(data) == "string" and data or (data.Message or "")
	showCenter(msg, 3)
end)
