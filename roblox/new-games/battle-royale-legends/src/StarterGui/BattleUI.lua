--[[
	BattleUI.lua - Battle Royale Legends
	Main HUD: health/shield bars, alive count, inventory, minimap, kill feed
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local re = RS:WaitForChild("RemoteEvents")

-- Screen GUI
local sg = Instance.new("ScreenGui"); sg.Name = "BattleUI"; sg.ResetOnSpawn = false; sg.Parent = pg

-- HUD Top Bar (alive count, storm phase)
local topBar = Instance.new("Frame"); topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.4, 0, 0, 40); topBar.Position = UDim2.new(0.3, 0, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0); topBar.BackgroundTransparency = 0.5
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local aliveLabel = Instance.new("TextLabel"); aliveLabel.Name = "Alive"
aliveLabel.Size = UDim2.new(0.5, 0, 1, 0); aliveLabel.Position = UDim2.new(0, 0, 0, 0)
aliveLabel.BackgroundTransparency = 1; aliveLabel.Text = "Alive: --"
aliveLabel.TextColor3 = Color3.new(1, 1, 1); aliveLabel.TextScaled = true
aliveLabel.Font = Enum.Font.GothamBold; aliveLabel.Parent = topBar

local stormLabel = Instance.new("TextLabel"); stormLabel.Name = "Storm"
stormLabel.Size = UDim2.new(0.5, 0, 1, 0); stormLabel.Position = UDim2.new(0.5, 0, 0, 0)
stormLabel.BackgroundTransparency = 1; stormLabel.Text = "Storm: Safe"
stormLabel.TextColor3 = Color3.fromRGB(150, 80, 255); stormLabel.TextScaled = true
stormLabel.Font = Enum.Font.GothamBold; stormLabel.Parent = topBar

-- Health & Shield Bars
local barsFrame = Instance.new("Frame"); barsFrame.Name = "Bars"
barsFrame.Size = UDim2.new(0.3, 0, 0, 50); barsFrame.Position = UDim2.new(0.35, 0, 1, -70)
barsFrame.BackgroundTransparency = 1; barsFrame.Parent = sg

local function createBar(name, color, yOffset)
	local bg = Instance.new("Frame"); bg.Name = name .. "BG"
	bg.Size = UDim2.new(1, 0, 0, 20); bg.Position = UDim2.new(0, 0, 0, yOffset)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bg.Parent = barsFrame
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame"); fill.Name = name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = color
	fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local label = Instance.new("TextLabel"); label.Name = name .. "Label"
	label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
	label.Text = "100"; label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true; label.Font = Enum.Font.GothamBold; label.Parent = bg
	return fill, label
end

local hpFill, hpLabel = createBar("HP", Color3.fromRGB(0, 200, 0), 0)
local shieldFill, shieldLabel = createBar("Shield", Color3.fromRGB(0, 150, 255), 25)

-- Kill Feed
local killFeed = Instance.new("Frame"); killFeed.Name = "KillFeed"
killFeed.Size = UDim2.new(0.25, 0, 0.3, 0); killFeed.Position = UDim2.new(0.74, 0, 0.05, 0)
killFeed.BackgroundTransparency = 1; killFeed.Parent = sg
local killLayout = Instance.new("UIListLayout"); killLayout.SortOrder = Enum.SortOrder.LayoutOrder
killLayout.Padding = UDim.new(0, 2); killLayout.Parent = killFeed

-- Inventory Bar
local invBar = Instance.new("Frame"); invBar.Name = "Inventory"
invBar.Size = UDim2.new(0.4, 0, 0, 50); invBar.Position = UDim2.new(0.3, 0, 1, -130)
invBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); invBar.BackgroundTransparency = 0.4
invBar.Parent = sg
Instance.new("UICorner", invBar).CornerRadius = UDim.new(0, 8)
local invLayout = Instance.new("UIListLayout"); invLayout.FillDirection = Enum.FillDirection.Horizontal
invLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
invLayout.Padding = UDim.new(0, 5); invLayout.Parent = invBar

-- Center message (countdown, elimination, victory)
local centerMsg = Instance.new("TextLabel"); centerMsg.Name = "CenterMessage"
centerMsg.Size = UDim2.new(0.6, 0, 0.15, 0); centerMsg.Position = UDim2.new(0.2, 0, 0.35, 0)
centerMsg.BackgroundTransparency = 1; centerMsg.Text = ""
centerMsg.TextColor3 = Color3.new(1, 1, 1); centerMsg.TextScaled = true
centerMsg.Font = Enum.Font.GothamBlack; centerMsg.TextStrokeTransparency = 0.5
centerMsg.Visible = false; centerMsg.Parent = sg

-- Queue button
local queueBtn = Instance.new("TextButton"); queueBtn.Name = "QueueBtn"
queueBtn.Size = UDim2.new(0, 200, 0, 60); queueBtn.Position = UDim2.new(0.5, -100, 0.8, 0)
queueBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); queueBtn.Text = "JOIN BATTLE"
queueBtn.TextColor3 = Color3.new(1, 1, 1); queueBtn.TextScaled = true
queueBtn.Font = Enum.Font.GothamBlack; queueBtn.Parent = sg
Instance.new("UICorner", queueBtn).CornerRadius = UDim.new(0, 12)

local inQueue = false
queueBtn.MouseButton1Click:Connect(function()
	if not inQueue then
		re:FindFirstChild("JoinQueue"):FireServer()
		queueBtn.Text = "LEAVE QUEUE"; queueBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		inQueue = true
	else
		re:FindFirstChild("LeaveQueue"):FireServer()
		queueBtn.Text = "JOIN BATTLE"; queueBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		inQueue = false
	end
end)

local function showCenter(text, duration, color)
	centerMsg.Text = text
	centerMsg.TextColor3 = color or Color3.new(1, 1, 1)
	centerMsg.Visible = true
	task.delay(duration or 3, function() centerMsg.Visible = false end)
end

local function addKillFeedEntry(text)
	local entry = Instance.new("TextLabel")
	entry.Size = UDim2.new(1, 0, 0, 20); entry.BackgroundTransparency = 0.6
	entry.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	entry.Text = text; entry.TextColor3 = Color3.fromRGB(255, 80, 80)
	entry.TextScaled = true; entry.Font = Enum.Font.Gotham
	entry.Parent = killFeed
	Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
	task.delay(5, function() if entry.Parent then entry:Destroy() end end)
end

-- Event handlers
re:WaitForChild("MatchUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "Queue" then
		showCenter("Queue: " .. data.Count .. "/" .. data.Needed, 2)
	elseif data.Type == "Countdown" then
		showCenter(tostring(data.Time), 1, Color3.fromRGB(255, 200, 0))
		queueBtn.Visible = false
	elseif data.Type == "Start" then
		showCenter("DROP: " .. data.DropLocation, 3, Color3.fromRGB(0, 255, 100))
		aliveLabel.Text = "Alive: " .. data.AliveCount
	elseif data.Type == "AliveUpdate" then
		aliveLabel.Text = "Alive: " .. data.Count
	elseif data.Type == "Eliminated" then
		showCenter("ELIMINATED #" .. data.Placement, 4, Color3.fromRGB(255, 50, 50))
		queueBtn.Visible = true; queueBtn.Text = "JOIN BATTLE"
		queueBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); inQueue = false
	elseif data.Type == "MatchEnd" then
		local msg = data.Placement == 1 and "VICTORY ROYALE!" or "#" .. data.Placement .. " - " .. data.Kills .. " Kills"
		local color = data.Placement == 1 and Color3.fromRGB(255, 215, 0) or Color3.new(1, 1, 1)
		showCenter(msg .. "\n+" .. data.XPEarned .. " XP", 6, color)
		queueBtn.Visible = true; queueBtn.Text = "JOIN BATTLE"
		queueBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); inQueue = false
	end
end)

re:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "DamageTaken" then
		hpFill.Size = UDim2.new(math.max(0, data.HP / 100), 0, 1, 0)
		hpLabel.Text = tostring(data.HP)
		shieldFill.Size = UDim2.new(math.max(0, data.Shield / 100), 0, 1, 0)
		shieldLabel.Text = tostring(data.Shield)
	elseif data.Type == "Healed" then
		hpFill.Size = UDim2.new(data.HP / 100, 0, 1, 0)
		hpLabel.Text = tostring(data.HP)
	elseif data.Type == "Shielded" then
		shieldFill.Size = UDim2.new(data.Shield / 100, 0, 1, 0)
		shieldLabel.Text = tostring(data.Shield)
	elseif data.Type == "DamageDealt" then
		addKillFeedEntry("Hit for " .. data.Amount .. " damage!")
	end
end)

re:WaitForChild("StormUpdate").OnClientEvent:Connect(function(data)
	if data.Type == "PhaseWarning" then
		stormLabel.Text = "Storm Phase " .. data.Phase .. " in " .. data.Delay .. "s"
	elseif data.Type == "Shrinking" then
		stormLabel.Text = "STORM CLOSING - Phase " .. data.Phase
		stormLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	end
end)

re:WaitForChild("LootDrop").OnClientEvent:Connect(function(loot)
	for _, item in ipairs(loot) do
		addKillFeedEntry("+ " .. item.Name .. " (" .. (item.Rarity or item.Type) .. ")")
	end
end)
