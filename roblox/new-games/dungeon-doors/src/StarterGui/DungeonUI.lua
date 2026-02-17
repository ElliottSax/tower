--[[
	DungeonUI.lua - Dungeon Doors
	Main HUD: door choices, HP bar, floor progress, souls counter, inventory, combat log
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

local sg = Instance.new("ScreenGui"); sg.Name = "DungeonUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- Top HUD (floor, souls, class)
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.5, 0, 0, 45); topBar.Position = UDim2.new(0.25, 0, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(15, 10, 25); topBar.BackgroundTransparency = 0.3
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local floorLabel = Instance.new("TextLabel"); floorLabel.Name = "Floor"
floorLabel.Size = UDim2.new(0.33, 0, 1, 0); floorLabel.BackgroundTransparency = 1
floorLabel.Text = "Floor: 1"; floorLabel.TextColor3 = Color3.new(1, 1, 1)
floorLabel.TextScaled = true; floorLabel.Font = Enum.Font.GothamBlack; floorLabel.Parent = topBar

local soulsLabel = Instance.new("TextLabel"); soulsLabel.Name = "Souls"
soulsLabel.Size = UDim2.new(0.33, 0, 1, 0); soulsLabel.Position = UDim2.new(0.33, 0, 0, 0)
soulsLabel.BackgroundTransparency = 1; soulsLabel.Text = "Souls: 0"
soulsLabel.TextColor3 = Color3.fromRGB(100, 200, 255); soulsLabel.TextScaled = true
soulsLabel.Font = Enum.Font.GothamBold; soulsLabel.Parent = topBar

local classLabel = Instance.new("TextLabel"); classLabel.Name = "Class"
classLabel.Size = UDim2.new(0.33, 0, 1, 0); classLabel.Position = UDim2.new(0.66, 0, 0, 0)
classLabel.BackgroundTransparency = 1; classLabel.Text = "Warrior"
classLabel.TextColor3 = Color3.fromRGB(255, 200, 0); classLabel.TextScaled = true
classLabel.Font = Enum.Font.GothamBold; classLabel.Parent = topBar

-- HP Bar
local hpBg = Instance.new("Frame"); hpBg.Name = "HPBar"
hpBg.Size = UDim2.new(0.3, 0, 0, 18); hpBg.Position = UDim2.new(0.35, 0, 0, 58)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 0, 0); hpBg.Parent = sg
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

local hpFill = Instance.new("Frame"); hpFill.Name = "Fill"
hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
hpFill.Parent = hpBg
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

local hpText = Instance.new("TextLabel"); hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1; hpText.Text = "100/100"
hpText.TextColor3 = Color3.new(1, 1, 1); hpText.TextScaled = true
hpText.Font = Enum.Font.GothamBold; hpText.Parent = hpBg

-- Door Choice Panel (center)
local doorPanel = Instance.new("Frame"); doorPanel.Name = "Doors"
doorPanel.Size = UDim2.new(0.7, 0, 0.35, 0); doorPanel.Position = UDim2.new(0.15, 0, 0.32, 0)
doorPanel.BackgroundTransparency = 1; doorPanel.Visible = false; doorPanel.Parent = sg

local doorTitle = Instance.new("TextLabel"); doorTitle.Name = "Title"
doorTitle.Size = UDim2.new(1, 0, 0, 40); doorTitle.BackgroundTransparency = 1
doorTitle.Text = "CHOOSE A DOOR"; doorTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
doorTitle.TextScaled = true; doorTitle.Font = Enum.Font.GothamBlack; doorTitle.Parent = doorPanel

local doorContainer = Instance.new("Frame"); doorContainer.Name = "Container"
doorContainer.Size = UDim2.new(1, 0, 1, -45); doorContainer.Position = UDim2.new(0, 0, 0, 45)
doorContainer.BackgroundTransparency = 1; doorContainer.Parent = doorPanel
local doorLayout = Instance.new("UIListLayout"); doorLayout.FillDirection = Enum.FillDirection.Horizontal
doorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
doorLayout.Padding = UDim.new(0, 20); doorLayout.Parent = doorContainer

-- Combat Log (right side)
local combatLog = Instance.new("ScrollingFrame"); combatLog.Name = "CombatLog"
combatLog.Size = UDim2.new(0.22, 0, 0.4, 0); combatLog.Position = UDim2.new(0.77, 0, 0.1, 0)
combatLog.BackgroundColor3 = Color3.fromRGB(10, 5, 15); combatLog.BackgroundTransparency = 0.4
combatLog.ScrollBarThickness = 4; combatLog.Parent = sg
Instance.new("UICorner", combatLog).CornerRadius = UDim.new(0, 6)
local logLayout = Instance.new("UIListLayout"); logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 2); logLayout.Parent = combatLog

local logTitle = Instance.new("TextLabel"); logTitle.Size = UDim2.new(1, 0, 0, 20)
logTitle.BackgroundTransparency = 1; logTitle.Text = "Combat Log"
logTitle.TextColor3 = Color3.fromRGB(150, 150, 150); logTitle.TextScaled = true
logTitle.Font = Enum.Font.GothamBold; logTitle.Parent = combatLog

-- Inventory panel (bottom)
local invPanel = Instance.new("Frame"); invPanel.Name = "Inventory"
invPanel.Size = UDim2.new(0.5, 0, 0, 60); invPanel.Position = UDim2.new(0.25, 0, 1, -75)
invPanel.BackgroundColor3 = Color3.fromRGB(20, 15, 30); invPanel.BackgroundTransparency = 0.3
invPanel.Parent = sg
Instance.new("UICorner", invPanel).CornerRadius = UDim.new(0, 8)

local invTitle = Instance.new("TextLabel"); invTitle.Size = UDim2.new(1, 0, 0, 16)
invTitle.BackgroundTransparency = 1; invTitle.Text = "Weapon: None"
invTitle.TextColor3 = Color3.fromRGB(255, 200, 0); invTitle.TextScaled = true
invTitle.Font = Enum.Font.GothamBold; invTitle.Parent = invPanel

-- Center message
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMsg"
centerMsg.Size = UDim2.new(0.6, 0, 0.12, 0); centerMsg.Position = UDim2.new(0.2, 0, 0.2, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Text = ""; centerMsg.Visible = false
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Parent = sg

-- Souls Shop button
local shopBtn = Instance.new("TextButton"); shopBtn.Name = "SoulsShop"
shopBtn.Size = UDim2.new(0, 140, 0, 40); shopBtn.Position = UDim2.new(0, 15, 0.5, 0)
shopBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 120); shopBtn.Text = "Souls Shop"
shopBtn.TextColor3 = Color3.new(1, 1, 1); shopBtn.TextScaled = true
shopBtn.Font = Enum.Font.GothamBold; shopBtn.Parent = sg
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 8)

-- Start Run button
local startBtn = Instance.new("TextButton"); startBtn.Name = "StartRun"
startBtn.Size = UDim2.new(0, 220, 0, 60); startBtn.Position = UDim2.new(0.5, -110, 0.75, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0); startBtn.Text = "ENTER THE DUNGEON"
startBtn.TextColor3 = Color3.new(1, 1, 1); startBtn.TextScaled = true
startBtn.Font = Enum.Font.GothamBlack; startBtn.Parent = sg
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 12)

-- Helpers
local logCount = 0
local function addLog(text, color)
	logCount = logCount + 1
	local entry = Instance.new("TextLabel"); entry.Size = UDim2.new(1, -4, 0, 18)
	entry.BackgroundTransparency = 1; entry.Text = text
	entry.TextColor3 = color or Color3.new(1, 1, 1); entry.TextScaled = true
	entry.Font = Enum.Font.Gotham; entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.LayoutOrder = logCount; entry.Parent = combatLog
	combatLog.CanvasSize = UDim2.new(0, 0, 0, logCount * 20 + 20)
	combatLog.CanvasPosition = Vector2.new(0, math.max(0, logCount * 20 - 200))
end

local function showCenter(text, dur, color)
	centerMsg.Text = text; centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(dur or 3, function() centerMsg.Visible = false end)
end

local function createDoors(doors)
	for _, child in ipairs(doorContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	doorPanel.Visible = true

	local doorColors = {
		Monster = Color3.fromRGB(200, 0, 0),
		Treasure = Color3.fromRGB(255, 200, 0),
		Trap = Color3.fromRGB(200, 100, 0),
		Safe = Color3.fromRGB(0, 180, 0),
		Shop = Color3.fromRGB(100, 0, 200),
		Boss = Color3.fromRGB(255, 0, 100),
		Mimic = Color3.fromRGB(200, 180, 0),
		Mystery = Color3.fromRGB(100, 100, 100),
	}

	for i, door in ipairs(doors) do
		local btn = Instance.new("TextButton"); btn.Name = "Door" .. i
		btn.Size = UDim2.new(0, 130, 1, 0)
		btn.BackgroundColor3 = doorColors[door.Hint] or Color3.fromRGB(80, 80, 80)
		btn.Text = "Door " .. i .. "\n" .. (door.Hint or "???")
		btn.TextColor3 = Color3.new(1, 1, 1); btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold; btn.Parent = doorContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

		btn.MouseButton1Click:Connect(function()
			re:FindFirstChild("ChooseDoor"):FireServer(i)
			doorPanel.Visible = false
		end)
	end
end

startBtn.MouseButton1Click:Connect(function()
	re:FindFirstChild("StartRun"):FireServer()
	startBtn.Visible = false
end)

shopBtn.MouseButton1Click:Connect(function()
	re:FindFirstChild("GetSoulsShop"):FireServer()
end)

-- Event Listeners
re:WaitForChild("DungeonUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "RunStarted" then
		floorLabel.Text = "Floor: 1"
		hpFill.Size = UDim2.new(1, 0, 1, 0)
		hpText.Text = data.HP .. "/" .. data.MaxHP
		classLabel.Text = data.Class or "Warrior"
		showCenter("ENTERING THE DUNGEON", 2, Color3.fromRGB(200, 0, 0))
		logCount = 0
		for _, c in ipairs(combatLog:GetChildren()) do if c:IsA("TextLabel") and c.Name ~= "Title" then c:Destroy() end end

	elseif data.Type == "Doors" then
		floorLabel.Text = "Floor: " .. (data.Floor or "?")
		createDoors(data.Doors)

	elseif data.Type == "RoomResult" then
		addLog(data.Message, data.Color and Color3.fromRGB(unpack(data.Color)) or nil)
		if data.HP then
			hpFill.Size = UDim2.new(math.max(0, data.HP / data.MaxHP), 0, 1, 0)
			hpText.Text = data.HP .. "/" .. data.MaxHP
			if data.HP < data.MaxHP * 0.3 then
				hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 0)
			else
				hpFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			end
		end
		if data.Souls then soulsLabel.Text = "Souls: " .. data.Souls end
		if data.Weapon then invTitle.Text = "Weapon: " .. data.Weapon end

	elseif data.Type == "CombatLog" then
		for _, line in ipairs(data.Lines or {}) do
			addLog(line.Text, line.Color and Color3.fromRGB(unpack(line.Color)) or nil)
		end

	elseif data.Type == "RunEnd" then
		local color = data.Won and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
		local msg = data.Won and ("DUNGEON CLEARED!\nFloor " .. data.Floor .. " | " .. data.SoulsEarned .. " Souls") or ("DEFEATED on Floor " .. data.Floor .. "\n+" .. data.SoulsEarned .. " Souls")
		showCenter(msg, 5, color)
		startBtn.Visible = true
		doorPanel.Visible = false
		soulsLabel.Text = "Souls: " .. (data.TotalSouls or 0)

	elseif data.Type == "BossPhase" then
		showCenter("BOSS FIGHT - " .. data.BossName, 3, Color3.fromRGB(255, 0, 100))
		addLog("BOSS: " .. data.BossName .. " appears!", Color3.fromRGB(255, 0, 100))
	end
end)

re:WaitForChild("SoulsShopData").OnClientEvent:Connect(function(data)
	-- Display souls shop in a simple overlay
	showCenter("Souls Shop - " .. #(data.Upgrades or {}) .. " upgrades available", 3, Color3.fromRGB(100, 0, 200))
end)
