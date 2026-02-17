--[[
	BiomeUI.lua - Grow a World
	Biome browser - view unlocked/locked biomes, teleport, unlock new ones
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local BiomeUI = {}
local screenGui, biomeFrame, isOpen = nil, nil, false

local BIOME_COLORS = {
	Meadow = Color3.fromRGB(76, 175, 80),
	Desert = Color3.fromRGB(255, 193, 7),
	Swamp = Color3.fromRGB(104, 159, 56),
	Mountain = Color3.fromRGB(121, 85, 72),
	Crystal = Color3.fromRGB(33, 150, 243),
	Volcanic = Color3.fromRGB(244, 67, 54),
	Cloud = Color3.fromRGB(176, 190, 197),
	Void = Color3.fromRGB(103, 58, 183),
}

function BiomeUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BiomeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	BiomeUI.CreateBiomeFrame()

	remoteEvents:WaitForChild("BiomeInfo").OnClientEvent:Connect(function(biomeData)
		BiomeUI.PopulateBiomes(biomeData)
		BiomeUI.Open()
	end)
end

function BiomeUI.CreateBiomeFrame()
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			BiomeUI.Close()
		end
	end)

	biomeFrame = Instance.new("Frame")
	biomeFrame.Name = "BiomeFrame"
	biomeFrame.Size = UDim2.new(0.65, 0, 0.7, 0)
	biomeFrame.Position = UDim2.new(0.175, 0, 0.15, 0)
	biomeFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 25)
	biomeFrame.BorderSizePixel = 0
	biomeFrame.Visible = false
	biomeFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = biomeFrame

	-- Title
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = biomeFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Biomes"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		BiomeUI.Close()
	end)

	-- Biome grid
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -60)
	content.Position = UDim2.new(0, 10, 0, 55)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.Parent = biomeFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 240, 0, 180)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = content
end

function BiomeUI.PopulateBiomes(biomeData)
	local content = biomeFrame:FindFirstChild("Content")
	if not content then return end

	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, biome in ipairs(GameConfig.Biomes) do
		local unlocked = biomeData and biomeData.Unlocked and biomeData.Unlocked[biome.Name]
		local card = BiomeUI.CreateBiomeCard(biome, i, unlocked)
		card.Parent = content
	end

	local grid = content:FindFirstChild("UIGridLayout")
	if grid then
		content.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
	end
end

function BiomeUI.CreateBiomeCard(biome, index, unlocked)
	local card = Instance.new("Frame")
	card.Name = biome.Name
	card.BackgroundColor3 = unlocked and Color3.fromRGB(40, 45, 40) or Color3.fromRGB(30, 30, 30)
	card.BorderSizePixel = 0
	card.LayoutOrder = index

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	-- Color bar
	local colorBar = Instance.new("Frame")
	colorBar.Size = UDim2.new(1, 0, 0, 6)
	colorBar.BackgroundColor3 = BIOME_COLORS[biome.Name] or Color3.fromRGB(100, 100, 100)
	colorBar.BackgroundTransparency = unlocked and 0 or 0.5
	colorBar.BorderSizePixel = 0
	colorBar.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = biome.Name
	nameLabel.TextColor3 = unlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = card

	-- Info
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -10, 0, 40)
	info.Position = UDim2.new(0, 5, 0, 44)
	info.BackgroundTransparency = 1
	info.Text = string.format("Plots: %d\nGrowth: %dx", biome.Plots, biome.GrowthMultiplier)
	info.TextColor3 = Color3.fromRGB(160, 160, 160)
	info.TextSize = 12
	info.Font = Enum.Font.Gotham
	info.TextWrapped = true
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Parent = card

	-- Action button
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 35)
	btn.Position = UDim2.new(0, 10, 1, -45)
	btn.BorderSizePixel = 0
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	if unlocked then
		btn.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
		btn.Text = "Teleport"
		btn.Activated:Connect(function()
			remoteEvents.TeleportToBiome:FireServer(biome.Name)
			BiomeUI.Close()
		end)
	else
		btn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
		btn.Text = "Unlock (" .. tostring(biome.UnlockCost) .. " coins)"
		btn.Activated:Connect(function()
			remoteEvents.UnlockBiome:FireServer(biome.Name)
		end)
	end

	return card
end

function BiomeUI.Open()
	if isOpen then return end
	isOpen = true
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = true end
	biomeFrame.Visible = true
	biomeFrame.Position = UDim2.new(0.175, 0, 1, 0)
	TweenService:Create(biomeFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.175, 0, 0.15, 0),
	}):Play()
end

function BiomeUI.Close()
	if not isOpen then return end
	TweenService:Create(biomeFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0.175, 0, 1, 0),
	}):Play()
	task.wait(0.2)
	biomeFrame.Visible = false
	local overlay = screenGui:FindFirstChild("Overlay")
	if overlay then overlay.Visible = false end
	isOpen = false
end

BiomeUI.Init()

return BiomeUI
