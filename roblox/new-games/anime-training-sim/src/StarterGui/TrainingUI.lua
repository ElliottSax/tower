--[[
	TrainingUI.lua - Anime Training Simulator
	Main training interface - stat displays, train buttons, zone info
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local TrainingUI = {}
local screenGui

local STAT_COLORS = {
	Strength = Color3.fromRGB(244, 67, 54),
	Defense = Color3.fromRGB(33, 150, 243),
	Speed = Color3.fromRGB(76, 175, 80),
	Spirit = Color3.fromRGB(156, 39, 176),
}

function TrainingUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TrainingUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	TrainingUI.CreateStatPanel()
	TrainingUI.CreateTrainButtons()
	TrainingUI.CreateZoneDisplay()
	TrainingUI.CreatePowerDisplay()

	remoteEvents:WaitForChild("TrainResult").OnClientEvent:Connect(function(data)
		TrainingUI.ShowTrainResult(data)
		TrainingUI.UpdateStats(data)
	end)

	remoteEvents:WaitForChild("ZoneChanged").OnClientEvent:Connect(function(zoneName)
		TrainingUI.UpdateZone(zoneName)
	end)
end

function TrainingUI.CreatePowerDisplay()
	local frame = Instance.new("Frame")
	frame.Name = "PowerDisplay"
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.Position = UDim2.new(0.5, -100, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "PowerLabel"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = "TOTAL POWER"
	label.TextColor3 = Color3.fromRGB(180, 180, 180)
	label.TextSize = 10
	label.Font = Enum.Font.GothamBold
	label.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "PowerValue"
	value.Size = UDim2.new(1, 0, 0, 30)
	value.Position = UDim2.new(0, 0, 0, 18)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = Color3.fromRGB(255, 215, 0)
	value.TextSize = 22
	value.Font = Enum.Font.GothamBold
	value.Parent = frame
end

function TrainingUI.CreateStatPanel()
	local panel = Instance.new("Frame")
	panel.Name = "StatPanel"
	panel.Size = UDim2.new(0, 180, 0, 200)
	panel.Position = UDim2.new(0, 10, 0.5, -100)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "STATS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "Stats"
	statsContainer.Size = UDim2.new(1, -10, 1, -35)
	statsContainer.Position = UDim2.new(0, 5, 0, 32)
	statsContainer.BackgroundTransparency = 1
	statsContainer.Parent = panel

	layout.Parent = statsContainer

	for i, stat in ipairs(GameConfig.TrainingTypes) do
		local row = Instance.new("Frame")
		row.Name = stat.Name
		row.Size = UDim2.new(1, 0, 0, 35)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i
		row.Parent = statsContainer

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 0, 15)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = stat.Name
		nameLabel.TextColor3 = STAT_COLORS[stat.Name]
		nameLabel.TextSize = 12
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(0.5, 0, 0, 15)
		valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = "0"
		valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		valueLabel.TextSize = 12
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = row

		-- Progress bar
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, 0, 0, 6)
		barBg.Position = UDim2.new(0, 0, 0, 18)
		barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		barBg.BorderSizePixel = 0
		barBg.Parent = row

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0.5, 0)
		barCorner.Parent = barBg

		local barFill = Instance.new("Frame")
		barFill.Name = "Fill"
		barFill.Size = UDim2.new(0, 0, 1, 0)
		barFill.BackgroundColor3 = STAT_COLORS[stat.Name]
		barFill.BorderSizePixel = 0
		barFill.Parent = barBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0.5, 0)
		fillCorner.Parent = barFill
	end
end

function TrainingUI.CreateTrainButtons()
	local frame = Instance.new("Frame")
	frame.Name = "TrainButtons"
	frame.Size = UDim2.new(0, 400, 0, 70)
	frame.Position = UDim2.new(0.5, -200, 1, -80)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame

	for _, stat in ipairs(GameConfig.TrainingTypes) do
		local btn = Instance.new("TextButton")
		btn.Name = "Train" .. stat.Name
		btn.Size = UDim2.new(0, 85, 0, 50)
		btn.BackgroundColor3 = STAT_COLORS[stat.Name]
		btn.Text = "Train\n" .. stat.Name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		btn.Activated:Connect(function()
			remoteEvents.Train:FireServer(stat.Name)
		end)

		-- Hold to train rapidly
		local holding = false
		btn.MouseButton1Down:Connect(function()
			holding = true
			task.spawn(function()
				while holding do
					task.wait(0.3)
					if holding then
						remoteEvents.Train:FireServer(stat.Name)
					end
				end
			end)
		end)

		btn.MouseButton1Up:Connect(function()
			holding = false
		end)

		btn.MouseLeave:Connect(function()
			holding = false
		end)
	end
end

function TrainingUI.CreateZoneDisplay()
	local frame = Instance.new("Frame")
	frame.Name = "ZoneDisplay"
	frame.Size = UDim2.new(0, 180, 0, 35)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "ZoneName"
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "Beginner Dojo (1x)"
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
end

function TrainingUI.ShowTrainResult(data)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 100, 0, 25)
	popup.Position = UDim2.new(0.5, -50 + math.random(-30, 30), 0.6, math.random(-20, 20))
	popup.BackgroundTransparency = 1
	popup.Text = "+" .. tostring(data.Gain) .. " " .. data.Stat
	popup.TextColor3 = STAT_COLORS[data.Stat] or Color3.fromRGB(255, 255, 255)
	popup.TextSize = 16
	popup.Font = Enum.Font.GothamBold
	popup.Parent = screenGui

	TweenService:Create(popup, TweenInfo.new(1), {
		Position = popup.Position + UDim2.new(0, 0, 0, -50),
		TextTransparency = 1,
	}):Play()

	task.delay(1, function() popup:Destroy() end)
end

function TrainingUI.UpdateStats(data)
	-- Update power display
	local powerDisplay = screenGui:FindFirstChild("PowerDisplay")
	if powerDisplay then
		local powerValue = powerDisplay:FindFirstChild("PowerValue")
		if powerValue then
			powerValue.Text = TrainingUI.FormatNumber(data.TotalPower)
		end
	end

	-- Update stat value
	local statPanel = screenGui:FindFirstChild("StatPanel")
	if statPanel then
		local stats = statPanel:FindFirstChild("Stats")
		if stats then
			local row = stats:FindFirstChild(data.Stat)
			if row then
				local value = row:FindFirstChild("Value")
				if value then
					value.Text = TrainingUI.FormatNumber(data.NewValue)
				end
			end
		end
	end
end

function TrainingUI.UpdateZone(zoneName)
	local zoneDisplay = screenGui:FindFirstChild("ZoneDisplay")
	if zoneDisplay then
		local label = zoneDisplay:FindFirstChild("ZoneName")
		if label then
			for _, zone in ipairs(GameConfig.TrainingZones) do
				if zone.Name == zoneName then
					label.Text = zoneName .. " (" .. zone.Multiplier .. "x)"
					break
				end
			end
		end
	end
end

function TrainingUI.FormatNumber(n)
	if n >= 1e12 then return string.format("%.1fT", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

TrainingUI.Init()

return TrainingUI
