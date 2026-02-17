--[[
	TreasureUI.lua - Treasure Hunt Islands
	Main HUD: island map, digging, ship management, treasure inventory, trading post
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

local sg = Instance.new("ScreenGui"); sg.Name = "TreasureUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- Top HUD (gold, island, tool)
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.5, 0, 0, 40); topBar.Position = UDim2.new(0.25, 0, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(30, 20, 10); topBar.BackgroundTransparency = 0.3
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local goldLabel = Instance.new("TextLabel"); goldLabel.Name = "Gold"
goldLabel.Size = UDim2.new(0.33, 0, 1, 0); goldLabel.BackgroundTransparency = 1
goldLabel.Text = "Gold: 0"; goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
goldLabel.TextScaled = true; goldLabel.Font = Enum.Font.GothamBold; goldLabel.Parent = topBar

local islandLabel = Instance.new("TextLabel"); islandLabel.Name = "Island"
islandLabel.Size = UDim2.new(0.33, 0, 1, 0); islandLabel.Position = UDim2.new(0.33, 0, 0, 0)
islandLabel.BackgroundTransparency = 1; islandLabel.Text = "Starter Beach"
islandLabel.TextColor3 = Color3.fromRGB(100, 200, 255); islandLabel.TextScaled = true
islandLabel.Font = Enum.Font.GothamBold; islandLabel.Parent = topBar

local toolLabel = Instance.new("TextLabel"); toolLabel.Name = "Tool"
toolLabel.Size = UDim2.new(0.33, 0, 1, 0); toolLabel.Position = UDim2.new(0.66, 0, 0, 0)
toolLabel.BackgroundTransparency = 1; toolLabel.Text = "Wooden Shovel"
toolLabel.TextColor3 = Color3.fromRGB(180, 140, 80); toolLabel.TextScaled = true
toolLabel.Font = Enum.Font.GothamBold; toolLabel.Parent = topBar

-- Dig Button (center bottom)
local digBtn = Instance.new("TextButton"); digBtn.Name = "Dig"
digBtn.Size = UDim2.new(0, 120, 0, 120); digBtn.Position = UDim2.new(0.5, -60, 1, -145)
digBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 30); digBtn.Text = "DIG!"
digBtn.TextColor3 = Color3.new(1, 1, 1); digBtn.TextScaled = true
digBtn.Font = Enum.Font.GothamBlack; digBtn.Parent = sg
local digCorner = Instance.new("UICorner"); digCorner.CornerRadius = UDim.new(0.5, 0); digCorner.Parent = digBtn

digBtn.MouseButton1Click:Connect(function()
	re:FindFirstChild("Dig"):FireServer()
	-- Button press animation
	TweenService:Create(digBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0.5, -50, 1, -135) }):Play()
	task.delay(0.1, function()
		TweenService:Create(digBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 120, 0, 120), Position = UDim2.new(0.5, -60, 1, -145) }):Play()
	end)
end)

-- Navigation (left side)
local navFrame = Instance.new("Frame"); navFrame.Name = "Nav"
navFrame.Size = UDim2.new(0, 55, 0.45, 0); navFrame.Position = UDim2.new(0, 8, 0.25, 0)
navFrame.BackgroundTransparency = 1; navFrame.Parent = sg
local navLayout = Instance.new("UIListLayout"); navLayout.Padding = UDim.new(0, 8)
navLayout.Parent = navFrame

local navBtns = { "Islands", "Treasure", "Ships", "Crew", "Trade", "Shop" }
local navColors = {
	Islands = Color3.fromRGB(50, 150, 255),
	Treasure = Color3.fromRGB(255, 200, 0),
	Ships = Color3.fromRGB(100, 80, 60),
	Crew = Color3.fromRGB(200, 100, 50),
	Trade = Color3.fromRGB(0, 180, 100),
	Shop = Color3.fromRGB(200, 50, 200),
}

local panels = {}

for i, name in ipairs(navBtns) do
	local btn = Instance.new("TextButton"); btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 42); btn.BackgroundColor3 = navColors[name]
	btn.Text = name; btn.TextColor3 = Color3.new(1, 1, 1); btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold; btn.LayoutOrder = i; btn.Parent = navFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(panels) do p.Visible = false end
		if panels[name] then panels[name].Visible = true end
	end)
end

-- Create panels
local function createPanel(name)
	local panel = Instance.new("Frame"); panel.Name = name .. "Panel"
	panel.Size = UDim2.new(0.55, 0, 0.6, 0); panel.Position = UDim2.new(0.22, 0, 0.15, 0)
	panel.BackgroundColor3 = Color3.fromRGB(25, 18, 10); panel.Visible = false
	panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1; title.Text = string.upper(name)
	title.TextColor3 = navColors[name] or Color3.new(1, 1, 1)
	title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = panel

	local close = Instance.new("TextButton"); close.Size = UDim2.new(0, 28, 0, 28)
	close.Position = UDim2.new(1, -32, 0, 4); close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	close.Text = "X"; close.TextColor3 = Color3.new(1, 1, 1); close.TextScaled = true
	close.Font = Enum.Font.GothamBold; close.Parent = panel
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
	close.MouseButton1Click:Connect(function() panel.Visible = false end)

	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"
	scroll.Size = UDim2.new(0.9, 0, 0.82, 0); scroll.Position = UDim2.new(0.05, 0, 0.11, 0)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5; scroll.Parent = panel
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll

	panels[name] = panel
	return panel, scroll
end

createPanel("Islands"); createPanel("Treasure"); createPanel("Ships")
createPanel("Crew"); createPanel("Trade"); createPanel("Shop")

-- Center message
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMsg"
centerMsg.Size = UDim2.new(0.5, 0, 0.1, 0); centerMsg.Position = UDim2.new(0.25, 0, 0.35, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Visible = false
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Parent = sg

-- Treasure found popup
local treasurePopup = Instance.new("Frame"); treasurePopup.Name = "TreasurePopup"
treasurePopup.Size = UDim2.new(0.3, 0, 0.15, 0); treasurePopup.Position = UDim2.new(0.35, 0, 0.25, 0)
treasurePopup.BackgroundColor3 = Color3.fromRGB(40, 30, 10); treasurePopup.Visible = false
treasurePopup.Parent = sg
Instance.new("UICorner", treasurePopup).CornerRadius = UDim.new(0, 10)

local treasureName = Instance.new("TextLabel"); treasureName.Size = UDim2.new(1, 0, 0.5, 0)
treasureName.BackgroundTransparency = 1; treasureName.TextScaled = true
treasureName.Font = Enum.Font.GothamBlack; treasureName.Parent = treasurePopup

local treasureValue = Instance.new("TextLabel"); treasureValue.Size = UDim2.new(1, 0, 0.5, 0)
treasureValue.Position = UDim2.new(0, 0, 0.5, 0); treasureValue.BackgroundTransparency = 1
treasureValue.TextScaled = true; treasureValue.Font = Enum.Font.GothamBold
treasureValue.TextColor3 = Color3.fromRGB(255, 215, 0); treasureValue.Parent = treasurePopup

local rarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(0, 200, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(180, 0, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
}

local function showCenter(text, dur, color)
	centerMsg.Text = text; centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(dur or 3, function() centerMsg.Visible = false end)
end

-- Event Listeners
re:WaitForChild("DigResult").OnClientEvent:Connect(function(data)
	if data.Found then
		treasureName.Text = data.Treasure.Name
		treasureName.TextColor3 = rarityColors[data.Treasure.Rarity] or Color3.new(1, 1, 1)
		treasureValue.Text = "Value: " .. data.Treasure.Value .. " gold"
		treasurePopup.Visible = true
		-- Pop animation
		treasurePopup.Size = UDim2.new(0.1, 0, 0.05, 0)
		treasurePopup.Position = UDim2.new(0.45, 0, 0.4, 0)
		TweenService:Create(treasurePopup, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
			Size = UDim2.new(0.3, 0, 0.15, 0),
			Position = UDim2.new(0.35, 0, 0.25, 0),
		}):Play()
		task.delay(2.5, function() treasurePopup.Visible = false end)
	elseif data.Nothing then
		showCenter("Nothing here...", 1.5, Color3.fromRGB(150, 150, 150))
	end
	if data.Gold then goldLabel.Text = "Gold: " .. data.Gold end
end)

re:WaitForChild("IslandSync").OnClientEvent:Connect(function(data)
	if data.Island then islandLabel.Text = data.Island end
	if data.Gold then goldLabel.Text = "Gold: " .. data.Gold end
end)

re:WaitForChild("ShipSync").OnClientEvent:Connect(function(data)
	if data.Ship then
		showCenter("Sailing on: " .. data.Ship, 2, Color3.fromRGB(100, 80, 60))
	end
end)

re:WaitForChild("CombatResult").OnClientEvent:Connect(function(data)
	if data.Won then
		showCenter("VICTORY! +" .. (data.Reward or 0) .. " gold", 3, Color3.fromRGB(255, 215, 0))
	else
		showCenter("DEFEATED! Lost some treasure", 3, Color3.fromRGB(255, 50, 50))
	end
end)

re:WaitForChild("Notification").OnClientEvent:Connect(function(data)
	local msg = type(data) == "string" and data or (data.Message or "")
	showCenter(msg, 3)
end)
