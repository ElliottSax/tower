--[[
	DailyRewardUI.lua - Grow a World
	Shows daily login reward popup with streak info
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local DailyRewardUI = {}
local screenGui

function DailyRewardUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	remoteEvents:WaitForChild("DailyReward").OnClientEvent:Connect(function(data)
		DailyRewardUI.ShowReward(data)
	end)
end

function DailyRewardUI.ShowReward(data)
	if not data then return end

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.6
	overlay.ZIndex = 50
	overlay.Parent = screenGui

	local popup = Instance.new("Frame")
	popup.Size = UDim2.new(0, 380, 0, 350)
	popup.Position = UDim2.new(0.5, -190, 0.5, -175)
	popup.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	popup.BorderSizePixel = 0
	popup.ZIndex = 51
	popup.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Parent = popup

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Daily Reward!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 52
	title.Parent = popup

	-- Streak
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(1, 0, 0, 25)
	streakLabel.Position = UDim2.new(0, 0, 0, 50)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "Login Streak: " .. (data.Streak or 1) .. " days!"
	streakLabel.TextColor3 = Color3.fromRGB(255, 152, 0)
	streakLabel.TextSize = 16
	streakLabel.Font = Enum.Font.GothamBold
	streakLabel.ZIndex = 52
	streakLabel.Parent = popup

	-- Day indicators
	local dayBar = Instance.new("Frame")
	dayBar.Size = UDim2.new(0.9, 0, 0, 50)
	dayBar.Position = UDim2.new(0.05, 0, 0, 85)
	dayBar.BackgroundTransparency = 1
	dayBar.ZIndex = 52
	dayBar.Parent = popup

	local dayLayout = Instance.new("UIListLayout")
	dayLayout.FillDirection = Enum.FillDirection.Horizontal
	dayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dayLayout.Padding = UDim.new(0, 6)
	dayLayout.Parent = dayBar

	for i = 1, 7 do
		local dayDot = Instance.new("Frame")
		dayDot.Size = UDim2.new(0, 40, 0, 40)
		dayDot.ZIndex = 53
		dayDot.Parent = dayBar

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent = dayDot

		local dayNum = Instance.new("TextLabel")
		dayNum.Size = UDim2.new(1, 0, 1, 0)
		dayNum.BackgroundTransparency = 1
		dayNum.Text = tostring(i)
		dayNum.TextSize = 14
		dayNum.Font = Enum.Font.GothamBold
		dayNum.ZIndex = 54
		dayNum.Parent = dayDot

		if i == data.Day then
			dayDot.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			dayNum.TextColor3 = Color3.fromRGB(20, 20, 30)
		elseif i < data.Day then
			dayDot.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
			dayNum.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			dayDot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			dayNum.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end

	-- Reward display
	local reward = data.Reward
	local rewardText = ""
	if reward then
		if reward.Reward == "Coins" then
			rewardText = tostring(reward.Amount) .. " Coins!"
		elseif reward.Reward == "Seeds" then
			rewardText = tostring(reward.Amount) .. " " .. (reward.Rarity or "Random") .. " Seeds!"
		end
	end

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(0.9, 0, 0, 50)
	rewardLabel.Position = UDim2.new(0.05, 0, 0, 150)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = rewardText
	rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rewardLabel.TextSize = 24
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextWrapped = true
	rewardLabel.ZIndex = 52
	rewardLabel.Parent = popup

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(0.6, 0, 0, 45)
	claimBtn.Position = UDim2.new(0.2, 0, 1, -65)
	claimBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	claimBtn.Text = "Claim!"
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.TextSize = 20
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.ZIndex = 52
	claimBtn.Parent = popup

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = claimBtn

	claimBtn.Activated:Connect(function()
		TweenService:Create(popup, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -190, -0.5, 0),
		}):Play()
		TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
		}):Play()
		task.wait(0.3)
		popup:Destroy()
		overlay:Destroy()
	end)

	-- Entrance animation
	popup.Position = UDim2.new(0.5, -190, 1.5, 0)
	TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -190, 0.5, -175),
	}):Play()
end

DailyRewardUI.Init()

return DailyRewardUI
