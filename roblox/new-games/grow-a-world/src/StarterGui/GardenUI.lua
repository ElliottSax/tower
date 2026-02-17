--[[
	GardenUI.lua - Grow a World
	Main garden interface - shows plots, growth progress, plant/harvest buttons
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local GardenUI = {}
local screenGui, mainFrame

-- ============================================================================
-- UI CREATION
-- ============================================================================

function GardenUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GardenUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	-- Bottom bar with garden info
	GardenUI.CreateBottomBar()

	-- Listen for garden updates
	remoteEvents:WaitForChild("GardenUpdate").OnClientEvent:Connect(function(action, biome, plotIndex, data)
		GardenUI.HandleGardenUpdate(action, biome, plotIndex, data)
	end)

	remoteEvents:WaitForChild("GardenState").OnClientEvent:Connect(function(gardens)
		GardenUI.UpdateFullState(gardens)
	end)

	-- Request initial state
	remoteEvents:WaitForChild("GetGardenState"):FireServer()
end

function GardenUI.CreateBottomBar()
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "BottomBar"
	mainFrame.Size = UDim2.new(1, 0, 0, 80)
	mainFrame.Position = UDim2.new(0, 0, 1, -80)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Quick action buttons
	local actions = {
		{ Name = "Plant", Icon = "rbxassetid://0", Color = Color3.fromRGB(76, 175, 80) },
		{ Name = "Water", Icon = "rbxassetid://0", Color = Color3.fromRGB(33, 150, 243) },
		{ Name = "Harvest All", Icon = "rbxassetid://0", Color = Color3.fromRGB(255, 193, 7) },
		{ Name = "Seeds", Icon = "rbxassetid://0", Color = Color3.fromRGB(156, 39, 176) },
		{ Name = "Biomes", Icon = "rbxassetid://0", Color = Color3.fromRGB(255, 87, 34) },
		{ Name = "Shop", Icon = "rbxassetid://0", Color = Color3.fromRGB(233, 30, 99) },
	}

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = mainFrame

	for _, action in ipairs(actions) do
		local btn = Instance.new("TextButton")
		btn.Name = action.Name
		btn.Size = UDim2.new(0, 100, 0, 60)
		btn.BackgroundColor3 = action.Color
		btn.Text = action.Name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.Parent = mainFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		-- Hover effects
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 110, 0, 65),
				BackgroundColor3 = action.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.2),
			}):Play()
		end)

		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 100, 0, 60),
				BackgroundColor3 = action.Color,
			}):Play()
		end)

		btn.Activated:Connect(function()
			GardenUI.HandleAction(action.Name)
		end)
	end
end

-- ============================================================================
-- ACTION HANDLERS
-- ============================================================================

function GardenUI.HandleAction(actionName)
	if actionName == "Harvest All" then
		remoteEvents.HarvestAll:FireServer("Meadow") -- Current biome
	elseif actionName == "Seeds" then
		remoteEvents.GetSeedShop:FireServer()
	elseif actionName == "Biomes" then
		remoteEvents.GetBiomeInfo:FireServer()
	elseif actionName == "Shop" then
		remoteEvents.GetShopData:FireServer()
	end
end

-- ============================================================================
-- UPDATE HANDLERS
-- ============================================================================

function GardenUI.HandleGardenUpdate(action, biome, plotIndex, data)
	if action == "planted" then
		GardenUI.ShowNotification("Planted " .. data.SeedName .. "!", Color3.fromRGB(76, 175, 80))
	elseif action == "watered" then
		GardenUI.ShowNotification("Watered! Growth boosted!", Color3.fromRGB(33, 150, 243))
	elseif action == "harvested" then
		GardenUI.ShowNotification(
			"Harvested " .. data.SeedName .. " for " .. data.Value .. " coins!",
			Color3.fromRGB(255, 193, 7)
		)
	end
end

function GardenUI.UpdateFullState(gardens)
	-- Update plot displays when full state received
	print("[GardenUI] Received full garden state")
end

-- ============================================================================
-- NOTIFICATION SYSTEM
-- ============================================================================

function GardenUI.ShowNotification(text, color)
	local notif = Instance.new("TextLabel")
	notif.Name = "Notification"
	notif.Size = UDim2.new(0.4, 0, 0, 40)
	notif.Position = UDim2.new(0.3, 0, 0.15, 0)
	notif.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
	notif.BackgroundTransparency = 0.2
	notif.Text = text
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.TextSize = 16
	notif.Font = Enum.Font.GothamBold
	notif.TextWrapped = true
	notif.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif

	-- Animate in
	notif.Position = UDim2.new(0.3, 0, 0.1, 0)
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.3, 0, 0.15, 0),
	}):Play()

	-- Fade out after 3 seconds
	task.delay(3, function()
		TweenService:Create(notif, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}):Play()
		task.wait(0.5)
		notif:Destroy()
	end)
end

-- Start UI
GardenUI.Init()

return GardenUI
