--[[
	FactoryUI.lua - Escape the Factory
	Main HUD: HP bar, room progress, timer, factory select, upgrades
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

local sg = Instance.new("ScreenGui"); sg.Name = "FactoryUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- Top HUD (room progress, HP, timer)
local topHud = Instance.new("Frame"); topHud.Name = "TopHUD"
topHud.Size = UDim2.new(0.5, 0, 0, 50); topHud.Position = UDim2.new(0.25, 0, 0, 10)
topHud.BackgroundColor3 = Color3.fromRGB(20, 20, 30); topHud.BackgroundTransparency = 0.3
topHud.Parent = sg
Instance.new("UICorner", topHud).CornerRadius = UDim.new(0, 10)

local roomLabel = Instance.new("TextLabel"); roomLabel.Name = "Room"
roomLabel.Size = UDim2.new(0.33, 0, 1, 0); roomLabel.Position = UDim2.new(0, 0, 0, 0)
roomLabel.BackgroundTransparency = 1; roomLabel.Text = "Room: --/--"
roomLabel.TextColor3 = Color3.new(1, 1, 1); roomLabel.TextScaled = true
roomLabel.Font = Enum.Font.GothamBold; roomLabel.Parent = topHud

local timerLabel = Instance.new("TextLabel"); timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(0.33, 0, 1, 0); timerLabel.Position = UDim2.new(0.33, 0, 0, 0)
timerLabel.BackgroundTransparency = 1; timerLabel.Text = "0:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 0); timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold; timerLabel.Parent = topHud

local livesLabel = Instance.new("TextLabel"); livesLabel.Name = "Lives"
livesLabel.Size = UDim2.new(0.33, 0, 1, 0); livesLabel.Position = UDim2.new(0.66, 0, 0, 0)
livesLabel.BackgroundTransparency = 1; livesLabel.Text = "Lives: 1"
livesLabel.TextColor3 = Color3.fromRGB(255, 100, 100); livesLabel.TextScaled = true
livesLabel.Font = Enum.Font.GothamBold; livesLabel.Parent = topHud

-- HP Bar
local hpBg = Instance.new("Frame"); hpBg.Name = "HPBarBG"
hpBg.Size = UDim2.new(0.3, 0, 0, 16); hpBg.Position = UDim2.new(0.35, 0, 0, 65)
hpBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50); hpBg.Parent = sg
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

local hpFill = Instance.new("Frame"); hpFill.Name = "HPFill"
hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
hpFill.Parent = hpBg
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

local hpText = Instance.new("TextLabel"); hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0); hpText.BackgroundTransparency = 1
hpText.Text = "100/100"; hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.TextScaled = true; hpText.Font = Enum.Font.GothamBold; hpText.Parent = hpBg

-- Center message
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMsg"
centerMsg.Size = UDim2.new(0.6, 0, 0.12, 0); centerMsg.Position = UDim2.new(0.2, 0, 0.35, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Text = ""; centerMsg.Visible = false
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Parent = sg

-- Factory Select Panel
local factoryPanel = Instance.new("Frame"); factoryPanel.Name = "FactoryPanel"
factoryPanel.Size = UDim2.new(0.6, 0, 0.7, 0); factoryPanel.Position = UDim2.new(0.2, 0, 0.15, 0)
factoryPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40); factoryPanel.Visible = true
factoryPanel.Parent = sg
Instance.new("UICorner", factoryPanel).CornerRadius = UDim.new(0, 12)

local panelTitle = Instance.new("TextLabel"); panelTitle.Name = "Title"
panelTitle.Size = UDim2.new(1, 0, 0, 40); panelTitle.Position = UDim2.new(0, 0, 0, 5)
panelTitle.BackgroundTransparency = 1; panelTitle.Text = "SELECT FACTORY"
panelTitle.TextColor3 = Color3.fromRGB(255, 200, 0); panelTitle.TextScaled = true
panelTitle.Font = Enum.Font.GothamBlack; panelTitle.Parent = factoryPanel

local factoryScroll = Instance.new("ScrollingFrame"); factoryScroll.Name = "FactoryList"
factoryScroll.Size = UDim2.new(0.9, 0, 0.8, 0); factoryScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
factoryScroll.BackgroundTransparency = 1; factoryScroll.ScrollBarThickness = 6
factoryScroll.Parent = factoryPanel
local factLayout = Instance.new("UIListLayout"); factLayout.Padding = UDim.new(0, 8)
factLayout.SortOrder = Enum.SortOrder.LayoutOrder; factLayout.Parent = factoryScroll

-- Populate factory cards
local GC = require(RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))
local themeColors = {
	Colorful = Color3.fromRGB(255, 150, 50),
	Industrial = Color3.fromRGB(150, 150, 150),
	Toxic = Color3.fromRGB(0, 200, 50),
	Mechanical = Color3.fromRGB(100, 150, 200),
	Radioactive = Color3.fromRGB(200, 255, 0),
	Dark = Color3.fromRGB(80, 0, 120),
	SciFi = Color3.fromRGB(0, 200, 255),
	Void = Color3.fromRGB(30, 0, 50),
}

for i, factory in ipairs(GC.Factories) do
	local card = Instance.new("Frame"); card.Name = factory.Name
	card.Size = UDim2.new(1, 0, 0, 70); card.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	card.LayoutOrder = i; card.Parent = factoryScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local accent = Instance.new("Frame"); accent.Size = UDim2.new(0, 6, 1, 0)
	accent.BackgroundColor3 = themeColors[factory.Theme] or Color3.new(1, 1, 1)
	accent.Parent = card
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.5, 0); nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1; nameLabel.Text = factory.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1); nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0.5, 0, 0.5, 0); infoLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Difficulty: " .. factory.Difficulty .. " | Rooms: " .. factory.Rooms
	infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180); infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.Gotham; infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = card

	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0.25, 0, 0.6, 0); playBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
	playBtn.BackgroundColor3 = factory.UnlockCost == 0 and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 150, 0)
	playBtn.Text = factory.UnlockCost == 0 and "PLAY" or (factory.UnlockCost .. " coins")
	playBtn.TextColor3 = Color3.new(1, 1, 1); playBtn.TextScaled = true
	playBtn.Font = Enum.Font.GothamBold; playBtn.Parent = card
	Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

	playBtn.MouseButton1Click:Connect(function()
		re:FindFirstChild("StartRun"):FireServer(factory.Name)
	end)
end
factoryScroll.CanvasSize = UDim2.new(0, 0, 0, #GC.Factories * 78)

local function showCenter(text, duration, color)
	centerMsg.Text = text; centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(duration or 3, function() centerMsg.Visible = false end)
end

local runTimer = nil
local function startTimer()
	local start = tick()
	runTimer = task.spawn(function()
		while true do
			local elapsed = tick() - start
			local mins = math.floor(elapsed / 60)
			local secs = math.floor(elapsed % 60)
			timerLabel.Text = string.format("%d:%02d", mins, secs)
			task.wait(0.5)
		end
	end)
end

-- Event handlers
re:WaitForChild("RunUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "RunStarted" then
		factoryPanel.Visible = false
		roomLabel.Text = "Room: " .. data.Room .. "/" .. data.TotalRooms
		livesLabel.Text = "Lives: " .. data.Lives
		hpFill.Size = UDim2.new(data.HP / data.MaxHP, 0, 1, 0)
		hpText.Text = data.HP .. "/" .. data.MaxHP
		showCenter("ENTERING: " .. data.Factory, 3, Color3.fromRGB(255, 200, 0))
		startTimer()
	elseif data.Type == "NextRoom" then
		roomLabel.Text = "Room: " .. data.Room .. "/" .. data.TotalRooms
		showCenter("Room " .. data.Room, 1.5)
	elseif data.Type == "Respawn" then
		livesLabel.Text = "Lives: " .. data.Lives
		hpFill.Size = UDim2.new(1, 0, 1, 0)
		showCenter("RESPAWNED", 2, Color3.fromRGB(0, 200, 255))
	elseif data.Type == "RunFailed" then
		showCenter("FAILED at Room " .. data.Room .. "\n+" .. data.CoinsEarned .. " coins", 4, Color3.fromRGB(255, 50, 50))
		factoryPanel.Visible = true
		if runTimer then task.cancel(runTimer); runTimer = nil end
	elseif data.Type == "RunComplete" then
		local stars = string.rep("*", data.Stars)
		showCenter("ESCAPED! " .. stars .. "\n+" .. data.CoinsEarned .. " coins\nTime: " .. string.format("%.1f", data.Time) .. "s", 5, Color3.fromRGB(255, 215, 0))
		factoryPanel.Visible = true
		if runTimer then task.cancel(runTimer); runTimer = nil end
	elseif data.Type == "FactoryUnlocked" then
		showCenter(data.Factory .. " UNLOCKED!", 3, Color3.fromRGB(0, 255, 100))
	elseif data.Type == "RoomSkipped" then
		roomLabel.Text = "Room: " .. data.Room .. "/" .. data.TotalRooms
		showCenter("Room Skipped!", 1.5, Color3.fromRGB(200, 200, 0))
	end
end)

re:WaitForChild("TrapUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "TrapDamage" then
		hpFill.Size = UDim2.new(math.max(0, data.HP / 100), 0, 1, 0)
		hpText.Text = tostring(math.max(0, data.HP))
		-- Flash red
		hpFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		task.delay(0.3, function() hpFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0) end)
	elseif data.Type == "GearCollected" then
		showCenter("+" .. data.Value .. " " .. data.Gear, 1.5, Color3.fromRGB(255, 215, 0))
	elseif data.Type == "PowerupActivated" then
		showCenter(data.Powerup .. " Active! (" .. data.Duration .. "s)", 2, Color3.fromRGB(0, 255, 200))
	end
end)

re:WaitForChild("PuzzleUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "PuzzleSolved" then
		showCenter("PUZZLE SOLVED! +" .. data.Bonus .. " coins", 2, Color3.fromRGB(0, 255, 100))
	elseif data.Type == "PuzzleFailed" then
		showCenter("PUZZLE FAILED!", 2, Color3.fromRGB(255, 50, 50))
	end
end)
