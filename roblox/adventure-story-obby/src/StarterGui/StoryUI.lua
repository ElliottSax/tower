--[[
	StoryUI.lua
	Client-side story progression and level selection UI

	Features:
	- World map display
	- Level selection
	- Progress visualization
	- Story information
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StoryUI = {}
StoryUI.IsOpen = false

-- UI Elements
local screenGui = nil
local mainFrame = nil
local worldFrame = nil
local levelListFrame = nil

-- Story data cache
local storyData = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function StoryUI.Init()
	print("[StoryUI] Initializing...")

	-- Create UI
	StoryUI.CreateUI()

	-- Setup keybind to open/close
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.M then -- M for Map
			StoryUI.Toggle()
		end
	end)

	print("[StoryUI] Initialized (Press M to open)")
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

function StoryUI.CreateUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	header.Text = "STORY PROGRESSION"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 28
	header.Font = Enum.Font.SourceSansBold
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		StoryUI.Close()
	end)

	-- World info frame (left side)
	worldFrame = Instance.new("Frame")
	worldFrame.Name = "WorldFrame"
	worldFrame.Size = UDim2.new(0.35, 0, 1, -80)
	worldFrame.Position = UDim2.new(0, 10, 0, 70)
	worldFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	worldFrame.BackgroundTransparency = 0.5
	worldFrame.BorderSizePixel = 0
	worldFrame.Parent = mainFrame

	local worldCorner = Instance.new("UICorner")
	worldCorner.CornerRadius = UDim.new(0, 10)
	worldCorner.Parent = worldFrame

	-- Level list frame (right side, scrolling)
	levelListFrame = Instance.new("ScrollingFrame")
	levelListFrame.Name = "LevelListFrame"
	levelListFrame.Size = UDim2.new(0.63, 0, 1, -80)
	levelListFrame.Position = UDim2.new(0.36, 0, 0, 70)
	levelListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	levelListFrame.BackgroundTransparency = 0.5
	levelListFrame.BorderSizePixel = 0
	levelListFrame.ScrollBarThickness = 8
	levelListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	levelListFrame.Parent = mainFrame

	local levelCorner = Instance.new("UICorner")
	levelCorner.CornerRadius = UDim.new(0, 10)
	levelCorner.Parent = levelListFrame

	local levelLayout = Instance.new("UIListLayout")
	levelLayout.FillDirection = Enum.FillDirection.Vertical
	levelLayout.Padding = UDim.new(0, 10)
	levelLayout.SortOrder = Enum.SortOrder.LayoutOrder
	levelLayout.Padding = UDim.new(0, 10)
	levelLayout.Parent = levelListFrame

	-- Auto-adjust canvas size
	levelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		levelListFrame.CanvasSize = UDim2.new(0, 0, 0, levelLayout.AbsoluteContentSize.Y + 20)
	end)

	print("[StoryUI] UI created successfully")
end

-- ============================================================================
-- UI DISPLAY
-- ============================================================================

function StoryUI.Open()
	StoryUI.IsOpen = true
	screenGui.Enabled = true

	-- Load story data
	StoryUI.LoadStoryData()
end

function StoryUI.Close()
	StoryUI.IsOpen = false
	screenGui.Enabled = false
end

function StoryUI.Toggle()
	if StoryUI.IsOpen then
		StoryUI.Close()
	else
		StoryUI.Open()
	end
end

function StoryUI.LoadStoryData()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local getStoryDataRemote = remoteEvents:FindFirstChild("GetStoryData")
	if not getStoryDataRemote then return end

	local success, data = pcall(function()
		return getStoryDataRemote:InvokeServer()
	end)

	if success and data then
		storyData = data
		StoryUI.DisplayWorldInfo()
		StoryUI.DisplayLevelList()
	end
end

function StoryUI.DisplayWorldInfo()
	-- Clear existing
	for _, child in ipairs(worldFrame:GetChildren()) do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- World 1 info (hardcoded for now)
	local worldName = Instance.new("TextLabel")
	worldName.Size = UDim2.new(1, -20, 0, 40)
	worldName.Position = UDim2.new(0, 10, 0, 10)
	worldName.BackgroundTransparency = 1
	worldName.Text = "WORLD 1: MYSTIC FOREST"
	worldName.TextColor3 = Color3.fromRGB(100, 255, 150)
	worldName.TextSize = 20
	worldName.Font = Enum.Font.SourceSansBold
	worldName.TextWrapped = true
	worldName.Parent = worldFrame

	local worldDesc = Instance.new("TextLabel")
	worldDesc.Size = UDim2.new(1, -20, 0, 100)
	worldDesc.Position = UDim2.new(0, 10, 0, 60)
	worldDesc.BackgroundTransparency = 1
	worldDesc.Text = "A cursed forest shrouded in ancient magic. Complete 5 levels to break the curse and unlock the next realm."
	worldDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	worldDesc.TextSize = 16
	worldDesc.Font = Enum.Font.SourceSans
	worldDesc.TextWrapped = true
	worldDesc.TextYAlignment = Enum.TextYAlignment.Top
	worldDesc.Parent = worldFrame

	-- Progress display
	local completedCount = 0
	if storyData then
		for levelKey, _ in pairs(storyData.CompletedLevels) do
			if levelKey:match("^World1_") then
				completedCount = completedCount + 1
			end
		end
	end

	local progress = Instance.new("TextLabel")
	progress.Size = UDim2.new(1, -20, 0, 40)
	progress.Position = UDim2.new(0, 10, 0, 180)
	progress.BackgroundTransparency = 1
	progress.Text = string.format("Progress: %d/5 Levels", completedCount)
	progress.TextColor3 = Color3.fromRGB(255, 215, 0)
	progress.TextSize = 18
	progress.Font = Enum.Font.SourceSansBold
	progress.Parent = worldFrame
end

function StoryUI.DisplayLevelList()
	-- Clear existing
	for _, child in ipairs(levelListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	-- Display 5 levels
	for levelId = 1, 5 do
		StoryUI.CreateLevelButton(1, levelId)
	end
end

function StoryUI.CreateLevelButton(worldId: number, levelId: number)
	local levelKey = string.format("World%d_Level%d", worldId, levelId)

	-- Check if completed
	local isCompleted = storyData and storyData.CompletedLevels[levelKey] or false

	-- Check if unlocked
	local isUnlocked = levelId == 1 or (storyData and storyData.CompletedLevels[string.format("World%d_Level%d", worldId, levelId - 1)])

	-- Level button
	local levelButton = Instance.new("TextButton")
	levelButton.Name = levelKey
	levelButton.Size = UDim2.new(1, -20, 0, 80)
	levelButton.BackgroundColor3 = isCompleted and Color3.fromRGB(50, 150, 50) or (isUnlocked and Color3.fromRGB(60, 60, 100) or Color3.fromRGB(60, 60, 60))
	levelButton.AutoButtonColor = isUnlocked
	levelButton.Parent = levelListFrame

	local levelCorner = Instance.new("UICorner")
	levelCorner.CornerRadius = UDim.new(0, 10)
	levelCorner.Parent = levelButton

	-- Level name
	local levelName = Instance.new("TextLabel")
	levelName.Size = UDim2.new(1, -20, 0, 30)
	levelName.Position = UDim2.new(0, 10, 0, 10)
	levelName.BackgroundTransparency = 1
	levelName.Text = string.format("Level %d", levelId)
	levelName.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
	levelName.TextSize = 20
	levelName.Font = Enum.Font.SourceSansBold
	levelName.TextXAlignment = Enum.TextXAlignment.Left
	levelName.Parent = levelButton

	-- Status indicator
	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(0, 100, 0, 25)
	status.Position = UDim2.new(1, -110, 0, 12)
	status.BackgroundColor3 = isCompleted and Color3.fromRGB(50, 200, 50) or (isUnlocked and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(100, 100, 100))
	status.Text = isCompleted and "✓ COMPLETE" or (isUnlocked and "AVAILABLE" or "🔒 LOCKED")
	status.TextColor3 = Color3.fromRGB(255, 255, 255)
	status.TextSize = 14
	status.Font = Enum.Font.SourceSansBold
	status.Parent = levelButton

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = status

	-- Action button
	if isUnlocked then
		local actionText = isCompleted and "REPLAY" or "START"

		local actionButton = Instance.new("TextButton")
		actionButton.Size = UDim2.new(0.9, 0, 0, 30)
		actionButton.Position = UDim2.new(0.05, 0, 1, -38)
		actionButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
		actionButton.Text = actionText
		actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		actionButton.TextSize = 16
		actionButton.Font = Enum.Font.SourceSansBold
		actionButton.Parent = levelButton

		local actionCorner = Instance.new("UICorner")
		actionCorner.CornerRadius = UDim.new(0, 6)
		actionCorner.Parent = actionButton

		actionButton.MouseButton1Click:Connect(function()
			StoryUI.TeleportToLevel(worldId, levelId)
		end)
	end
end

-- ============================================================================
-- ACTIONS
-- ============================================================================

function StoryUI.TeleportToLevel(worldId: number, levelId: number)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local teleportRemote = remoteEvents:FindFirstChild("TeleportToLevel")
	if not teleportRemote then return end

	local success, result = pcall(function()
		return teleportRemote:InvokeServer(worldId, levelId)
	end)

	if success and result then
		StoryUI.Close()
		print(string.format("[StoryUI] Teleported to World%d_Level%d", worldId, levelId))
	else
		warn("[StoryUI] Failed to teleport:", result)
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
StoryUI.Init()

return StoryUI
