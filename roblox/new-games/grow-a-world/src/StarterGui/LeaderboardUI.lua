--[[
	LeaderboardUI.lua - Grow a World
	Global leaderboard display - coins, plants harvested, prestige level
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local LeaderboardUI = {}
local screenGui, lbFrame, isOpen = nil, nil, false

local TAB_COLORS = {
	TotalCoinsEarned = Color3.fromRGB(255, 193, 7),
	PlantsHarvested = Color3.fromRGB(76, 175, 80),
	PrestigeLevel = Color3.fromRGB(156, 39, 176),
}

function LeaderboardUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeaderboardUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	LeaderboardUI.CreateFrame()

	remoteEvents:WaitForChild("LeaderboardData").OnClientEvent:Connect(function(data)
		LeaderboardUI.PopulateLeaderboard(data)
		LeaderboardUI.Open()
	end)

	-- Leaderboard button on HUD
	LeaderboardUI.CreateHUDButton()
end

function LeaderboardUI.CreateHUDButton()
	local btn = Instance.new("TextButton")
	btn.Name = "LeaderboardBtn"
	btn.Size = UDim2.new(0, 40, 0, 40)
	btn.Position = UDim2.new(1, -50, 0, 10)
	btn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
	btn.Text = "LB"
	btn.TextColor3 = Color3.fromRGB(0, 0, 0)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	btn.Activated:Connect(function()
		remoteEvents.GetLeaderboard:FireServer("TotalCoinsEarned")
	end)
end

function LeaderboardUI.CreateFrame()
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			LeaderboardUI.Close()
		end
	end)

	lbFrame = Instance.new("Frame")
	lbFrame.Name = "LeaderboardFrame"
	lbFrame.Size = UDim2.new(0, 400, 0, 500)
	lbFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	lbFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	lbFrame.BorderSizePixel = 0
	lbFrame.Visible = false
	lbFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = lbFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 45)
	title.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
	title.Text = "Leaderboard"
	title.TextColor3 = Color3.fromRGB(20, 20, 30)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.Parent = lbFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = title

	-- Close
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 35, 0, 35)
	closeBtn.Position = UDim2.new(1, -40, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = lbFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		LeaderboardUI.Close()
	end)

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 35)
	tabBar.Position = UDim2.new(0, 0, 0, 45)
	tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	tabBar.BorderSizePixel = 0
	tabBar.Parent = lbFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Parent = tabBar

	local tabs = {
		{ Key = "TotalCoinsEarned", Label = "Coins" },
		{ Key = "PlantsHarvested", Label = "Plants" },
		{ Key = "PrestigeLevel", Label = "Prestige" },
	}

	for _, tabInfo in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = tabInfo.Key
		tab.Size = UDim2.new(1 / #tabs, 0, 1, 0)
		tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		tab.Text = tabInfo.Label
		tab.TextColor3 = Color3.fromRGB(200, 200, 200)
		tab.TextSize = 13
		tab.Font = Enum.Font.GothamBold
		tab.BorderSizePixel = 0
		tab.Parent = tabBar

		tab.Activated:Connect(function()
			remoteEvents.GetLeaderboard:FireServer(tabInfo.Key)
		end)
	end

	-- Entries list
	local entries = Instance.new("ScrollingFrame")
	entries.Name = "Entries"
	entries.Size = UDim2.new(1, -20, 1, -90)
	entries.Position = UDim2.new(0, 10, 0, 85)
	entries.BackgroundTransparency = 1
	entries.ScrollBarThickness = 4
	entries.Parent = lbFrame

	local entryLayout = Instance.new("UIListLayout")
	entryLayout.Padding = UDim.new(0, 4)
	entryLayout.Parent = entries
end

function LeaderboardUI.PopulateLeaderboard(data)
	if not data then return end

	local entries = lbFrame:FindFirstChild("Entries")
	if not entries then return end

	for _, child in ipairs(entries:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local color = TAB_COLORS[data.Board] or Color3.fromRGB(255, 193, 7)

	-- Update tab highlights
	local tabBar = lbFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == data.Board then
					tab.BackgroundColor3 = color
					tab.TextColor3 = Color3.fromRGB(20, 20, 30)
				else
					tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
					tab.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end

	for rank, entry in ipairs(data.Entries or {}) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 35)
		row.BackgroundColor3 = rank <= 3 and color or Color3.fromRGB(35, 35, 50)
		row.BackgroundTransparency = rank <= 3 and 0.7 or 0
		row.BorderSizePixel = 0
		row.LayoutOrder = rank
		row.Parent = entries

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0, 40, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. rank
		rankLabel.TextColor3 = rank <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 180)
		rankLabel.TextSize = 14
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 45, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.Name or "Player"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 13
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
		valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(entry.Value or 0)
		valueLabel.TextColor3 = color
		valueLabel.TextSize = 14
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.Parent = row
	end

	local layout = entries:FindFirstChild("UIListLayout")
	if layout then
		entries.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
end

function LeaderboardUI.Open()
	if isOpen then return end
	isOpen = true
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = true end
	lbFrame.Visible = true
end

function LeaderboardUI.Close()
	if not isOpen then return end
	isOpen = false
	lbFrame.Visible = false
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = false end
end

LeaderboardUI.Init()

return LeaderboardUI
