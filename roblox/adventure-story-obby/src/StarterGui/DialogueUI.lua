--[[
	DialogueUI.lua
	Client-side dialogue UI for NPC conversations

	Features:
	- Dialogue box with typewriter effect
	- Choice buttons
	- NPC portrait display
	- Skip/close functionality
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DialogueUI = {}
DialogueUI.IsActive = false

-- UI Elements (will be created)
local screenGui = nil
local dialogueFrame = nil
local npcNameLabel = nil
local dialogueTextLabel = nil
local choicesFrame = nil
local skipButton = nil

-- Current dialogue state
local currentNPC = nil
local isTyping = false
local typewriterCoroutine = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DialogueUI.Init()
	print("[DialogueUI] Initializing...")

	-- Create UI
	DialogueUI.CreateUI()

	-- Connect to remote events
	DialogueUI.ConnectRemotes()

	print("[DialogueUI] Initialized")
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

function DialogueUI.CreateUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DialogueUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Main dialogue frame (bottom of screen)
	dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialogueFrame"
	dialogueFrame.Size = UDim2.new(0.8, 0, 0.25, 0)
	dialogueFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	dialogueFrame.BackgroundTransparency = 0.2
	dialogueFrame.BorderSizePixel = 0
	dialogueFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = dialogueFrame

	-- NPC Name Label
	npcNameLabel = Instance.new("TextLabel")
	npcNameLabel.Name = "NPCName"
	npcNameLabel.Size = UDim2.new(1, -40, 0, 40)
	npcNameLabel.Position = UDim2.new(0, 20, 0, 10)
	npcNameLabel.BackgroundTransparency = 1
	npcNameLabel.Text = "NPC Name"
	npcNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	npcNameLabel.TextSize = 24
	npcNameLabel.Font = Enum.Font.SourceSansBold
	npcNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	npcNameLabel.Parent = dialogueFrame

	-- Dialogue Text Label
	dialogueTextLabel = Instance.new("TextLabel")
	dialogueTextLabel.Name = "DialogueText"
	dialogueTextLabel.Size = UDim2.new(1, -40, 0.4, 0)
	dialogueTextLabel.Position = UDim2.new(0, 20, 0, 50)
	dialogueTextLabel.BackgroundTransparency = 1
	dialogueTextLabel.Text = ""
	dialogueTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	dialogueTextLabel.TextSize = 20
	dialogueTextLabel.Font = Enum.Font.SourceSans
	dialogueTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	dialogueTextLabel.TextYAlignment = Enum.TextYAlignment.Top
	dialogueTextLabel.TextWrapped = true
	dialogueTextLabel.Parent = dialogueFrame

	-- Choices Frame
	choicesFrame = Instance.new("Frame")
	choicesFrame.Name = "ChoicesFrame"
	choicesFrame.Size = UDim2.new(1, -40, 0.35, 0)
	choicesFrame.Position = UDim2.new(0, 20, 0.6, 0)
	choicesFrame.BackgroundTransparency = 1
	choicesFrame.Parent = dialogueFrame

	local choicesLayout = Instance.new("UIListLayout")
	choicesLayout.FillDirection = Enum.FillDirection.Vertical
	choicesLayout.Padding = UDim.new(0, 8)
	choicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	choicesLayout.Parent = choicesFrame

	-- Skip Button
	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0, 100, 0, 40)
	skipButton.Position = UDim2.new(1, -120, 0, 10)
	skipButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	skipButton.Text = "Skip"
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.TextSize = 18
	skipButton.Font = Enum.Font.SourceSansBold
	skipButton.Parent = dialogueFrame

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 8)
	skipCorner.Parent = skipButton

	skipButton.MouseButton1Click:Connect(function()
		DialogueUI.SkipTypewriter()
	end)

	print("[DialogueUI] UI created successfully")
end

-- ============================================================================
-- DIALOGUE DISPLAY
-- ============================================================================

function DialogueUI.ShowDialogue(dialogueData)
	if not dialogueData then return end

	currentNPC = dialogueData.NPC
	DialogueUI.IsActive = true
	screenGui.Enabled = true

	-- Set NPC name
	npcNameLabel.Text = dialogueData.NPC or "Unknown"

	-- Display dialogue text with typewriter effect
	DialogueUI.TypewriterEffect(dialogueData.Text or "")

	-- Wait for typewriter to complete before showing choices
	task.spawn(function()
		while isTyping do
			task.wait(0.1)
		end
		-- Display choices
		DialogueUI.DisplayChoices(dialogueData.Choices or {})
	end)
end

function DialogueUI.TypewriterEffect(text: string)
	isTyping = true
	dialogueTextLabel.Text = ""

	-- Stop any existing typewriter
	if typewriterCoroutine then
		task.cancel(typewriterCoroutine)
	end

	typewriterCoroutine = task.spawn(function()
		for i = 1, #text do
			dialogueTextLabel.Text = string.sub(text, 1, i)
			task.wait(0.03) -- Typewriter speed
		end
		isTyping = false
	end)
end

function DialogueUI.SkipTypewriter()
	if isTyping and typewriterCoroutine then
		task.cancel(typewriterCoroutine)
		-- Show full text immediately
		isTyping = false
	end
end

function DialogueUI.DisplayChoices(choices)
	-- Clear existing choices
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Create choice buttons
	for index, choice in ipairs(choices) do
		local choiceButton = Instance.new("TextButton")
		choiceButton.Name = "Choice" .. index
		choiceButton.Size = UDim2.new(1, 0, 0, 40)
		choiceButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		choiceButton.Text = choice.Text or "Continue"
		choiceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		choiceButton.TextSize = 18
		choiceButton.Font = Enum.Font.SourceSans
		choiceButton.AutoButtonColor = true
		choiceButton.Parent = choicesFrame

		local choiceCorner = Instance.new("UICorner")
		choiceCorner.CornerRadius = UDim.new(0, 8)
		choiceCorner.Parent = choiceButton

		-- Hover effect
		choiceButton.MouseEnter:Connect(function()
			choiceButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end)

		choiceButton.MouseLeave:Connect(function()
			choiceButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end)

		-- Click handler
		choiceButton.MouseButton1Click:Connect(function()
			DialogueUI.MakeChoice(index)
		end)
	end
end

function DialogueUI.HideDialogue()
	DialogueUI.IsActive = false
	screenGui.Enabled = false
	currentNPC = nil

	-- Stop typewriter
	if typewriterCoroutine then
		task.cancel(typewriterCoroutine)
		typewriterCoroutine = nil
	end
end

-- ============================================================================
-- REMOTE COMMUNICATION
-- ============================================================================

function DialogueUI.ConnectRemotes()
	-- Wait for RemoteEvents folder
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		warn("[DialogueUI] RemoteEvents folder not found")
		return
	end

	-- NPCInteract (Server → Client)
	local npcInteractRemote = remoteEvents:FindFirstChild("NPCInteract")
	if npcInteractRemote then
		npcInteractRemote.OnClientEvent:Connect(function(npcName)
			-- Request dialogue from server
			DialogueUI.RequestDialogue(npcName)
		end)
	end

	print("[DialogueUI] Remotes connected")
end

function DialogueUI.RequestDialogue(npcName: string)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local startDialogueRemote = remoteEvents:FindFirstChild("StartDialogue")
	if not startDialogueRemote then return end

	-- Call server to start dialogue
	local success, dialogueData = pcall(function()
		return startDialogueRemote:InvokeServer(npcName)
	end)

	if success and dialogueData then
		DialogueUI.ShowDialogue(dialogueData)
	else
		warn("[DialogueUI] Failed to start dialogue:", dialogueData)
	end
end

function DialogueUI.MakeChoice(choiceIndex: number)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local makeChoiceRemote = remoteEvents:FindFirstChild("MakeChoice")
	if not makeChoiceRemote then return end

	-- Call server with choice
	local success, nextDialogue = pcall(function()
		return makeChoiceRemote:InvokeServer(choiceIndex)
	end)

	if success and nextDialogue then
		if nextDialogue.Ended then
			-- Dialogue ended
			DialogueUI.HideDialogue()
		else
			-- Show next dialogue
			DialogueUI.ShowDialogue(nextDialogue)
		end
	else
		warn("[DialogueUI] Failed to make choice:", nextDialogue)
		DialogueUI.HideDialogue()
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
DialogueUI.Init()

return DialogueUI
