--[[
	PetUI.lua - Pet Kingdom Tycoon
	Main HUD: pet inventory, egg hatching, breeding, kingdom, world select
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

local sg = Instance.new("ScreenGui"); sg.Name = "PetUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- Top Bar (coins, world)
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.4, 0, 0, 40); topBar.Position = UDim2.new(0.3, 0, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(20, 30, 50); topBar.BackgroundTransparency = 0.3
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local coinLabel = Instance.new("TextLabel"); coinLabel.Name = "Coins"
coinLabel.Size = UDim2.new(0.5, 0, 1, 0); coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"; coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true; coinLabel.Font = Enum.Font.GothamBold; coinLabel.Parent = topBar

local worldLabel = Instance.new("TextLabel"); worldLabel.Name = "World"
worldLabel.Size = UDim2.new(0.5, 0, 1, 0); worldLabel.Position = UDim2.new(0.5, 0, 0, 0)
worldLabel.BackgroundTransparency = 1; worldLabel.Text = "World: Forest"
worldLabel.TextColor3 = Color3.fromRGB(100, 255, 100); worldLabel.TextScaled = true
worldLabel.Font = Enum.Font.GothamBold; worldLabel.Parent = topBar

-- Navigation Buttons (left side)
local navFrame = Instance.new("Frame"); navFrame.Name = "Nav"
navFrame.Size = UDim2.new(0, 55, 0.5, 0); navFrame.Position = UDim2.new(0, 8, 0.25, 0)
navFrame.BackgroundTransparency = 1; navFrame.Parent = sg
local navLayout = Instance.new("UIListLayout"); navLayout.Padding = UDim.new(0, 8)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder; navLayout.Parent = navFrame

local navButtons = { "Pets", "Eggs", "Breed", "Kingdom", "Worlds", "Shop" }
local navColors = {
	Pets = Color3.fromRGB(255, 150, 50),
	Eggs = Color3.fromRGB(200, 100, 255),
	Breed = Color3.fromRGB(255, 100, 150),
	Kingdom = Color3.fromRGB(100, 200, 50),
	Worlds = Color3.fromRGB(50, 150, 255),
	Shop = Color3.fromRGB(255, 200, 0),
}

local panels = {}
for i, name in ipairs(navButtons) do
	local btn = Instance.new("TextButton"); btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 45); btn.BackgroundColor3 = navColors[name]
	btn.Text = name; btn.TextColor3 = Color3.new(1, 1, 1); btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold; btn.LayoutOrder = i; btn.Parent = navFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		for _, p in pairs(panels) do p.Visible = false end
		if panels[name] then panels[name].Visible = true end
		if name == "Pets" then re:FindFirstChild("GetPets"):FireServer()
		elseif name == "Eggs" then re:FindFirstChild("GetEggs"):FireServer()
		elseif name == "Breed" then re:FindFirstChild("GetBreedingStatus"):FireServer()
		elseif name == "Kingdom" then re:FindFirstChild("GetKingdom"):FireServer()
		elseif name == "Worlds" then re:FindFirstChild("GetWorlds"):FireServer()
		elseif name == "Shop" then re:FindFirstChild("GetShopData"):FireServer()
		end
	end)
end

-- Create panels for each section
local function createPanel(name)
	local panel = Instance.new("Frame"); panel.Name = name .. "Panel"
	panel.Size = UDim2.new(0.6, 0, 0.65, 0); panel.Position = UDim2.new(0.2, 0, 0.15, 0)
	panel.BackgroundColor3 = Color3.fromRGB(25, 30, 45); panel.Visible = false
	panel.Parent = sg
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel"); title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 35); title.BackgroundTransparency = 1
	title.Text = string.upper(name); title.TextColor3 = navColors[name] or Color3.new(1, 1, 1)
	title.TextScaled = true; title.Font = Enum.Font.GothamBlack; title.Parent = panel

	local close = Instance.new("TextButton"); close.Name = "Close"
	close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -35, 0, 5)
	close.BackgroundColor3 = Color3.fromRGB(200, 50, 50); close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1); close.TextScaled = true
	close.Font = Enum.Font.GothamBold; close.Parent = panel
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
	close.MouseButton1Click:Connect(function() panel.Visible = false end)

	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "Content"
	scroll.Size = UDim2.new(0.9, 0, 0.82, 0); scroll.Position = UDim2.new(0.05, 0, 0.12, 0)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5
	scroll.Parent = panel

	local layout = Instance.new("UIGridLayout"); layout.CellSize = UDim2.new(0, 130, 0, 140)
	layout.CellPadding = UDim2.new(0, 8, 0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	panels[name] = panel
	return panel, scroll
end

local petsPanel, petsScroll = createPanel("Pets")
local eggsPanel, eggsScroll = createPanel("Eggs")
local breedPanel, breedScroll = createPanel("Breed")
local kingdomPanel, kingdomScroll = createPanel("Kingdom")
local worldsPanel, worldsScroll = createPanel("Worlds")
local shopPanel, shopScroll = createPanel("Shop")

-- Center message
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMsg"
centerMsg.Size = UDim2.new(0.5, 0, 0.1, 0); centerMsg.Position = UDim2.new(0.25, 0, 0.4, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Visible = false
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Parent = sg

-- Egg Hatch Animation Overlay
local hatchOverlay = Instance.new("Frame"); hatchOverlay.Name = "HatchOverlay"
hatchOverlay.Size = UDim2.new(1, 0, 1, 0); hatchOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
hatchOverlay.BackgroundTransparency = 0.7; hatchOverlay.Visible = false; hatchOverlay.Parent = sg

local hatchLabel = Instance.new("TextLabel"); hatchLabel.Name = "HatchResult"
hatchLabel.Size = UDim2.new(0.5, 0, 0.2, 0); hatchLabel.Position = UDim2.new(0.25, 0, 0.35, 0)
hatchLabel.BackgroundTransparency = 1; hatchLabel.TextScaled = true
hatchLabel.Font = Enum.Font.GothamBlack; hatchLabel.TextStrokeTransparency = 0.3
hatchLabel.Parent = hatchOverlay

local rarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(0, 200, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(180, 0, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythical = Color3.fromRGB(255, 50, 100),
}

local function showCenter(text, dur, color)
	centerMsg.Text = text; centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(dur or 3, function() centerMsg.Visible = false end)
end

local function clearScroll(scroll)
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
	end
end

local function createPetCard(parent, pet, order, actionName, actionText)
	local card = Instance.new("Frame"); card.Name = pet.Name
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 60); card.LayoutOrder = order
	card.Parent = parent
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local accent = Instance.new("Frame"); accent.Size = UDim2.new(1, 0, 0, 4)
	accent.BackgroundColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
	accent.Position = UDim2.new(0, 0, 0, 0); accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 4)

	local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(1, 0, 0, 22)
	nameL.Position = UDim2.new(0, 0, 0, 8); nameL.BackgroundTransparency = 1
	nameL.Text = pet.Name; nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.TextScaled = true; nameL.Font = Enum.Font.GothamBold; nameL.Parent = card

	local rarityL = Instance.new("TextLabel"); rarityL.Size = UDim2.new(1, 0, 0, 16)
	rarityL.Position = UDim2.new(0, 0, 0, 30); rarityL.BackgroundTransparency = 1
	rarityL.Text = pet.Rarity .. (pet.Stage and (" Stg " .. pet.Stage) or "")
	rarityL.TextColor3 = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
	rarityL.TextScaled = true; rarityL.Font = Enum.Font.Gotham; rarityL.Parent = card

	local infoL = Instance.new("TextLabel"); infoL.Size = UDim2.new(1, 0, 0, 16)
	infoL.Position = UDim2.new(0, 0, 0, 48); infoL.BackgroundTransparency = 1
	infoL.Text = pet.Level and ("Lv " .. pet.Level .. " | " .. (pet.CoinPerSec or 0) .. "/s") or ""
	infoL.TextColor3 = Color3.fromRGB(180, 180, 180); infoL.TextScaled = true
	infoL.Font = Enum.Font.Gotham; infoL.Parent = card

	if actionName then
		local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0.8, 0, 0, 28)
		btn.Position = UDim2.new(0.1, 0, 1, -35); btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
		btn.Text = actionText or "Action"; btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true; btn.Font = Enum.Font.GothamBold; btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			re:FindFirstChild(actionName):FireServer(pet.Name or pet.Id)
		end)
	end

	return card
end

-- Event Listeners
re:WaitForChild("PetSync").OnClientEvent:Connect(function(data)
	if data.Coins then coinLabel.Text = "Coins: " .. data.Coins end
	if data.Pets then
		clearScroll(petsScroll)
		for i, pet in ipairs(data.Pets) do
			createPetCard(petsScroll, pet, i, "FeedPet", "Feed")
		end
		petsScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#data.Pets / 3) * 148)
	end
end)

re:WaitForChild("EggResult").OnClientEvent:Connect(function(data)
	if data.Pet then
		hatchOverlay.Visible = true
		hatchLabel.Text = data.Pet.Name .. "\n" .. data.Pet.Rarity
		hatchLabel.TextColor3 = rarityColors[data.Pet.Rarity] or Color3.new(1, 1, 1)
		-- Scale animation
		hatchLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
		hatchLabel.Position = UDim2.new(0.45, 0, 0.45, 0)
		TweenService:Create(hatchLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
			Size = UDim2.new(0.5, 0, 0.2, 0),
			Position = UDim2.new(0.25, 0, 0.35, 0)
		}):Play()
		task.delay(2.5, function() hatchOverlay.Visible = false end)
	end
	if data.Coins then coinLabel.Text = "Coins: " .. data.Coins end
end)

re:WaitForChild("BreedingUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "Started" then
		showCenter("Breeding started! " .. data.Time .. "s remaining", 3, Color3.fromRGB(255, 100, 150))
	elseif data.Type == "Complete" then
		showCenter("Breeding complete! Got: " .. data.Pet.Name .. " (" .. data.Pet.Rarity .. ")", 4, Color3.fromRGB(255, 100, 150))
	end
end)

re:WaitForChild("KingdomSync").OnClientEvent:Connect(function(data)
	clearScroll(kingdomScroll)
	if data.Structures then
		for i, s in ipairs(data.Structures) do
			local card = Instance.new("Frame"); card.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
			card.LayoutOrder = i; card.Parent = kingdomScroll
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local nameL = Instance.new("TextLabel"); nameL.Size = UDim2.new(1, 0, 0.4, 0)
			nameL.BackgroundTransparency = 1; nameL.Text = s.Name
			nameL.TextColor3 = Color3.new(1, 1, 1); nameL.TextScaled = true
			nameL.Font = Enum.Font.GothamBold; nameL.Parent = card

			local infoL = Instance.new("TextLabel"); infoL.Size = UDim2.new(1, 0, 0.3, 0)
			infoL.Position = UDim2.new(0, 0, 0.4, 0); infoL.BackgroundTransparency = 1
			infoL.Text = s.Effect; infoL.TextColor3 = Color3.fromRGB(150, 255, 150)
			infoL.TextScaled = true; infoL.Font = Enum.Font.Gotham; infoL.Parent = card
		end
		kingdomScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#data.Structures / 3) * 148)
	end
end)

re:WaitForChild("WorldSync").OnClientEvent:Connect(function(data)
	if data.World then worldLabel.Text = "World: " .. data.World end
end)

re:WaitForChild("Notification").OnClientEvent:Connect(function(data)
	showCenter(data.Message or data, data.Duration or 3, data.Color and Color3.fromRGB(unpack(data.Color)) or nil)
end)
