--[[
	PrestigeUI.lua - Grow a World
	Prestige/rebirth interface - shows cost, multiplier, milestones
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local PrestigeUI = {}
local screenGui, prestigeFrame, isOpen = nil, nil, false

function PrestigeUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PrestigeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	PrestigeUI.CreatePrestigeFrame()

	remoteEvents:WaitForChild("PrestigeInfo").OnClientEvent:Connect(function(info)
		PrestigeUI.UpdateInfo(info)
		PrestigeUI.Open()
	end)

	remoteEvents:WaitForChild("PrestigeComplete").OnClientEvent:Connect(function(newLevel)
		PrestigeUI.ShowPrestigeAnimation(newLevel)
		PrestigeUI.Close()
	end)
end

function PrestigeUI.CreatePrestigeFrame()
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			PrestigeUI.Close()
		end
	end)

	prestigeFrame = Instance.new("Frame")
	prestigeFrame.Name = "PrestigeFrame"
	prestigeFrame.Size = UDim2.new(0, 450, 0, 400)
	prestigeFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
	prestigeFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
	prestigeFrame.BorderSizePixel = 0
	prestigeFrame.Visible = false
	prestigeFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = prestigeFrame

	-- Gradient border effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Parent = prestigeFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "PRESTIGE"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = prestigeFrame

	-- Current level
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0, 30)
	levelLabel.Position = UDim2.new(0, 0, 0, 50)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Current Level: 0"
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextSize = 18
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.Parent = prestigeFrame

	-- Multiplier
	local multLabel = Instance.new("TextLabel")
	multLabel.Name = "MultLabel"
	multLabel.Size = UDim2.new(1, 0, 0, 30)
	multLabel.Position = UDim2.new(0, 0, 0, 80)
	multLabel.BackgroundTransparency = 1
	multLabel.Text = "Coin Multiplier: 1.00x"
	multLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
	multLabel.TextSize = 16
	multLabel.Font = Enum.Font.GothamBold
	multLabel.Parent = prestigeFrame

	-- Cost info
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(1, 0, 0, 30)
	costLabel.Position = UDim2.new(0, 0, 0, 120)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Cost: 10,000 coins"
	costLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
	costLabel.TextSize = 16
	costLabel.Font = Enum.Font.Gotham
	costLabel.Parent = prestigeFrame

	-- Warning
	local warning = Instance.new("TextLabel")
	warning.Size = UDim2.new(0.9, 0, 0, 60)
	warning.Position = UDim2.new(0.05, 0, 0, 160)
	warning.BackgroundTransparency = 1
	warning.Text = "Warning: Prestiging resets your coins, seeds, and garden progress. You keep your prestige multiplier permanently!"
	warning.TextColor3 = Color3.fromRGB(255, 100, 100)
	warning.TextSize = 12
	warning.Font = Enum.Font.Gotham
	warning.TextWrapped = true
	warning.Parent = prestigeFrame

	-- Next milestone
	local milestoneLabel = Instance.new("TextLabel")
	milestoneLabel.Name = "MilestoneLabel"
	milestoneLabel.Size = UDim2.new(0.9, 0, 0, 40)
	milestoneLabel.Position = UDim2.new(0.05, 0, 0, 230)
	milestoneLabel.BackgroundTransparency = 1
	milestoneLabel.Text = ""
	milestoneLabel.TextColor3 = Color3.fromRGB(156, 39, 176)
	milestoneLabel.TextSize = 13
	milestoneLabel.Font = Enum.Font.GothamBold
	milestoneLabel.TextWrapped = true
	milestoneLabel.Parent = prestigeFrame

	-- Prestige button
	local prestigeBtn = Instance.new("TextButton")
	prestigeBtn.Name = "PrestigeBtn"
	prestigeBtn.Size = UDim2.new(0.6, 0, 0, 50)
	prestigeBtn.Position = UDim2.new(0.2, 0, 1, -70)
	prestigeBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	prestigeBtn.Text = "PRESTIGE NOW"
	prestigeBtn.TextColor3 = Color3.fromRGB(20, 15, 30)
	prestigeBtn.TextSize = 20
	prestigeBtn.Font = Enum.Font.GothamBold
	prestigeBtn.Parent = prestigeFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = prestigeBtn

	prestigeBtn.Activated:Connect(function()
		remoteEvents.Prestige:FireServer()
	end)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 35, 0, 35)
	closeBtn.Position = UDim2.new(1, -40, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = prestigeFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		PrestigeUI.Close()
	end)
end

function PrestigeUI.UpdateInfo(info)
	if not info then return end

	local levelLabel = prestigeFrame:FindFirstChild("LevelLabel")
	if levelLabel then
		levelLabel.Text = "Current Level: " .. (info.Level or 0)
	end

	local multLabel = prestigeFrame:FindFirstChild("MultLabel")
	if multLabel then
		local mult = 1 + (info.Level or 0) * 0.25
		multLabel.Text = string.format("Coin Multiplier: %.2fx", mult)
	end

	local costLabel = prestigeFrame:FindFirstChild("CostLabel")
	if costLabel then
		costLabel.Text = "Cost: " .. tostring(info.Cost or 0) .. " coins"
	end

	local milestoneLabel = prestigeFrame:FindFirstChild("MilestoneLabel")
	if milestoneLabel and info.NextMilestone then
		milestoneLabel.Text = "Next milestone at level " .. info.NextMilestone.Level .. ": " .. info.NextMilestone.Reward
	end

	-- Disable button if can't afford
	local btn = prestigeFrame:FindFirstChild("PrestigeBtn")
	if btn then
		if info.CanPrestige then
			btn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			btn.Text = "PRESTIGE NOW"
		else
			btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			btn.Text = "Need more coins"
		end
	end
end

function PrestigeUI.ShowPrestigeAnimation(newLevel)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	flash.ZIndex = 100
	flash.Parent = screenGui

	local levelText = Instance.new("TextLabel")
	levelText.Size = UDim2.new(1, 0, 0, 60)
	levelText.Position = UDim2.new(0, 0, 0.4, 0)
	levelText.BackgroundTransparency = 1
	levelText.Text = "PRESTIGE LEVEL " .. newLevel .. "!"
	levelText.TextColor3 = Color3.fromRGB(20, 15, 30)
	levelText.TextSize = 40
	levelText.Font = Enum.Font.GothamBold
	levelText.ZIndex = 101
	levelText.Parent = flash

	TweenService:Create(flash, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()

	TweenService:Create(levelText, TweenInfo.new(2), {
		TextTransparency = 1,
	}):Play()

	task.delay(2.5, function()
		flash:Destroy()
	end)
end

function PrestigeUI.Open()
	if isOpen then return end
	isOpen = true
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = true end
	prestigeFrame.Visible = true
end

function PrestigeUI.Close()
	if not isOpen then return end
	isOpen = false
	prestigeFrame.Visible = false
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = false end
end

PrestigeUI.Init()

return PrestigeUI
