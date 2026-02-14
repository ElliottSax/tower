--[[
	QuestTrackerUI.lua
	Client-side quest tracker UI

	Features:
	- Active quest display (top-right corner)
	- Progress bars for objectives
	- Completion notifications
	- Collapsible quest list
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local QuestTrackerUI = {}

-- UI Elements
local screenGui = nil
local trackerFrame = nil
local questListFrame = nil
local toggleButton = nil

-- Quest cache
local activeQuests = {}
local isExpanded = true

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function QuestTrackerUI.Init()
	print("[QuestTrackerUI] Initializing...")

	-- Create UI
	QuestTrackerUI.CreateUI()

	-- Connect to remote events
	QuestTrackerUI.ConnectRemotes()

	-- Load active quests
	task.defer(function()
		QuestTrackerUI.RefreshQuests()
	end)

	print("[QuestTrackerUI] Initialized")
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

function QuestTrackerUI.CreateUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestTrackerUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main tracker frame (top-right)
	trackerFrame = Instance.new("Frame")
	trackerFrame.Name = "TrackerFrame"
	trackerFrame.Size = UDim2.new(0, 300, 0, 400)
	trackerFrame.Position = UDim2.new(1, -320, 0, 20)
	trackerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	trackerFrame.BackgroundTransparency = 0.3
	trackerFrame.BorderSizePixel = 0
	trackerFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = trackerFrame

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	header.Text = "ACTIVE QUESTS"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 20
	header.Font = Enum.Font.SourceSansBold
	header.Parent = trackerFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	-- Toggle button
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 30, 0, 30)
	toggleButton.Position = UDim2.new(1, -35, 0, 5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggleButton.Text = "-"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 20
	toggleButton.Font = Enum.Font.SourceSansBold
	toggleButton.Parent = header

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		QuestTrackerUI.ToggleExpanded()
	end)

	-- Quest list frame (scrolling)
	questListFrame = Instance.new("ScrollingFrame")
	questListFrame.Name = "QuestListFrame"
	questListFrame.Size = UDim2.new(1, -10, 1, -50)
	questListFrame.Position = UDim2.new(0, 5, 0, 45)
	questListFrame.BackgroundTransparency = 1
	questListFrame.BorderSizePixel = 0
	questListFrame.ScrollBarThickness = 6
	questListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	questListFrame.Parent = trackerFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = questListFrame

	-- Auto-adjust canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		questListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	print("[QuestTrackerUI] UI created successfully")
end

-- ============================================================================
-- QUEST DISPLAY
-- ============================================================================

function QuestTrackerUI.RefreshQuests()
	-- Get active quests from server
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local getActiveQuestsRemote = remoteEvents:FindFirstChild("GetActiveQuests")
	if not getActiveQuestsRemote then return end

	local success, quests = pcall(function()
		return getActiveQuestsRemote:InvokeServer()
	end)

	if success and quests then
		activeQuests = quests
		QuestTrackerUI.UpdateQuestDisplay()
	end
end

function QuestTrackerUI.UpdateQuestDisplay()
	-- Clear existing quest displays
	for _, child in ipairs(questListFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Quest") then
			child:Destroy()
		end
	end

	-- Create quest displays
	for index, quest in ipairs(activeQuests) do
		QuestTrackerUI.CreateQuestDisplay(quest, index)
	end
end

function QuestTrackerUI.CreateQuestDisplay(quest, index: number)
	-- Quest container
	local questContainer = Instance.new("Frame")
	questContainer.Name = "Quest_" .. quest.Id
	questContainer.Size = UDim2.new(1, -10, 0, 100) -- Will auto-resize
	questContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	questContainer.BackgroundTransparency = 0.5
	questContainer.BorderSizePixel = 0
	questContainer.LayoutOrder = index
	questContainer.Parent = questListFrame

	local questCorner = Instance.new("UICorner")
	questCorner.CornerRadius = UDim.new(0, 8)
	questCorner.Parent = questContainer

	-- Quest name
	local questName = Instance.new("TextLabel")
	questName.Name = "QuestName"
	questName.Size = UDim2.new(1, -10, 0, 25)
	questName.Position = UDim2.new(0, 5, 0, 5)
	questName.BackgroundTransparency = 1
	questName.Text = quest.Name
	questName.TextColor3 = quest.IsComplete and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
	questName.TextSize = 16
	questName.Font = Enum.Font.SourceSansBold
	questName.TextXAlignment = Enum.TextXAlignment.Left
	questName.Parent = questContainer

	-- Quest type tag
	local typeTag = Instance.new("TextLabel")
	typeTag.Name = "TypeTag"
	typeTag.Size = UDim2.new(0, 60, 0, 20)
	typeTag.Position = UDim2.new(1, -65, 0, 7)
	typeTag.BackgroundColor3 = quest.Type == "Story" and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 150, 200)
	typeTag.Text = quest.Type
	typeTag.TextColor3 = Color3.fromRGB(255, 255, 255)
	typeTag.TextSize = 12
	typeTag.Font = Enum.Font.SourceSansBold
	typeTag.Parent = questContainer

	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0, 4)
	tagCorner.Parent = typeTag

	-- Objectives
	local yOffset = 35
	for i, objective in ipairs(quest.Objectives) do
		local objectiveKey = string.format("Objective%d", i)
		local progress = quest.Progress[objectiveKey] or 0
		local target = objective.Count

		-- Objective text
		local objText = Instance.new("TextLabel")
		objText.Name = "Objective" .. i
		objText.Size = UDim2.new(1, -10, 0, 20)
		objText.Position = UDim2.new(0, 5, 0, yOffset)
		objText.BackgroundTransparency = 1
		objText.Text = string.format("• %s: %d/%d", objective.Name or objective.Type, progress, target)
		objText.TextColor3 = progress >= target and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
		objText.TextSize = 14
		objText.Font = Enum.Font.SourceSans
		objText.TextXAlignment = Enum.TextXAlignment.Left
		objText.Parent = questContainer

		-- Progress bar
		local progressBarBg = Instance.new("Frame")
		progressBarBg.Name = "ProgressBarBg" .. i
		progressBarBg.Size = UDim2.new(0.9, 0, 0, 4)
		progressBarBg.Position = UDim2.new(0.05, 0, 0, yOffset + 22)
		progressBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		progressBarBg.BorderSizePixel = 0
		progressBarBg.Parent = questContainer

		local progressBar = Instance.new("Frame")
		progressBar.Name = "ProgressBar" .. i
		progressBar.Size = UDim2.new(math.clamp(progress / target, 0, 1), 0, 1, 0)
		progressBar.BackgroundColor3 = progress >= target and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 200, 255)
		progressBar.BorderSizePixel = 0
		progressBar.Parent = progressBarBg

		yOffset = yOffset + 30
	end

	-- Claim button if complete
	if quest.IsComplete then
		local claimButton = Instance.new("TextButton")
		claimButton.Name = "ClaimButton"
		claimButton.Size = UDim2.new(0.9, 0, 0, 30)
		claimButton.Position = UDim2.new(0.05, 0, 0, yOffset + 5)
		claimButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		claimButton.Text = "CLAIM REWARD"
		claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimButton.TextSize = 14
		claimButton.Font = Enum.Font.SourceSansBold
		claimButton.Parent = questContainer

		local claimCorner = Instance.new("UICorner")
		claimCorner.CornerRadius = UDim.new(0, 6)
		claimCorner.Parent = claimButton

		claimButton.MouseButton1Click:Connect(function()
			QuestTrackerUI.ClaimReward(quest.Id)
		end)

		yOffset = yOffset + 40
	end

	-- Resize container
	questContainer.Size = UDim2.new(1, -10, 0, yOffset + 10)
end

function QuestTrackerUI.ToggleExpanded()
	isExpanded = not isExpanded

	if isExpanded then
		trackerFrame.Size = UDim2.new(0, 300, 0, 400)
		questListFrame.Visible = true
		toggleButton.Text = "-"
	else
		trackerFrame.Size = UDim2.new(0, 300, 0, 45)
		questListFrame.Visible = false
		toggleButton.Text = "+"
	end
end

-- ============================================================================
-- ACTIONS
-- ============================================================================

function QuestTrackerUI.ClaimReward(questId: string)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local claimRewardRemote = remoteEvents:FindFirstChild("ClaimQuestReward")
	if not claimRewardRemote then return end

	local success, result = pcall(function()
		return claimRewardRemote:InvokeServer(questId)
	end)

	if success and result then
		-- Show notification
		QuestTrackerUI.ShowNotification("Quest completed! Reward claimed.")
		-- Refresh quests
		QuestTrackerUI.RefreshQuests()
	end
end

function QuestTrackerUI.ShowNotification(message: string)
	-- Simple notification (could be enhanced)
	print("[QuestTrackerUI]", message)
	-- TODO: Create fancy notification UI
end

-- ============================================================================
-- REMOTE COMMUNICATION
-- ============================================================================

function QuestTrackerUI.ConnectRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then return end

	-- QuestUpdate event
	local questUpdateRemote = remoteEvents:FindFirstChild("QuestUpdate")
	if questUpdateRemote then
		questUpdateRemote.OnClientEvent:Connect(function(questId)
			-- Refresh quest display
			QuestTrackerUI.RefreshQuests()
		end)
	end

	print("[QuestTrackerUI] Remotes connected")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
QuestTrackerUI.Init()

return QuestTrackerUI
