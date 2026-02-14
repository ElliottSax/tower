--[[
	PartyUI.client.lua
	Party management interface

	Features:
	- Party member display
	- Invite friends
	- Party controls (kick, promote, leave)
	- Invite notifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[PartyUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PartyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Party panel (shown when in party or managing)
local partyPanel = Instance.new("Frame")
partyPanel.Name = "PartyPanel"
partyPanel.AnchorPoint = Vector2.new(0, 0.5)
partyPanel.Position = UDim2.new(0, 10, 0.5, 0)
partyPanel.Size = UDim2.new(0, 200, 0, 250)
partyPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
partyPanel.Visible = false
partyPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = partyPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(100, 80, 200)
panelStroke.Thickness = 2
panelStroke.Parent = partyPanel

-- Party header
local partyHeader = Instance.new("Frame")
partyHeader.Name = "Header"
partyHeader.Size = UDim2.new(1, 0, 0, 40)
partyHeader.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
partyHeader.Parent = partyPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = partyHeader

-- Fix bottom corners of header
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 15)
headerFix.Position = UDim2.new(0, 0, 1, -15)
headerFix.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
headerFix.BorderSizePixel = 0
headerFix.Parent = partyHeader

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -40, 1, 0)
headerTitle.Position = UDim2.new(0, 10, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 16
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.Text = "Party (1/4)"
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = partyHeader

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -5, 0.5, 0)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.BackgroundTransparency = 1
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Parent = partyHeader

-- Members container
local membersContainer = Instance.new("ScrollingFrame")
membersContainer.Name = "MembersContainer"
membersContainer.Position = UDim2.new(0, 10, 0, 50)
membersContainer.Size = UDim2.new(1, -20, 0, 120)
membersContainer.BackgroundTransparency = 1
membersContainer.ScrollBarThickness = 4
membersContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
membersContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
membersContainer.Parent = partyPanel

local membersLayout = Instance.new("UIListLayout")
membersLayout.Padding = UDim.new(0, 5)
membersLayout.Parent = membersContainer

-- Buttons container
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Name = "ButtonsContainer"
buttonsContainer.Position = UDim2.new(0, 10, 1, -80)
buttonsContainer.Size = UDim2.new(1, -20, 0, 70)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.Parent = partyPanel

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.Padding = UDim.new(0, 5)
buttonsLayout.Parent = buttonsContainer

-- Invite button
local inviteButton = Instance.new("TextButton")
inviteButton.Name = "InviteButton"
inviteButton.Size = UDim2.new(1, 0, 0, 30)
inviteButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
inviteButton.Font = Enum.Font.GothamBold
inviteButton.TextSize = 14
inviteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
inviteButton.Text = "Invite Player"
inviteButton.Parent = buttonsContainer

local inviteCorner = Instance.new("UICorner")
inviteCorner.CornerRadius = UDim.new(0, 6)
inviteCorner.Parent = inviteButton

-- Leave button
local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveButton"
leaveButton.Size = UDim2.new(1, 0, 0, 30)
leaveButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
leaveButton.Font = Enum.Font.GothamBold
leaveButton.TextSize = 14
leaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveButton.Text = "Leave Party"
leaveButton.Parent = buttonsContainer

local leaveCorner = Instance.new("UICorner")
leaveCorner.CornerRadius = UDim.new(0, 6)
leaveCorner.Parent = leaveButton

-- Mini party indicator (always visible when in party)
local partyIndicator = Instance.new("TextButton")
partyIndicator.Name = "PartyIndicator"
partyIndicator.AnchorPoint = Vector2.new(0, 0.5)
partyIndicator.Position = UDim2.new(0, 10, 0.5, -150)
partyIndicator.Size = UDim2.new(0, 40, 0, 40)
partyIndicator.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
partyIndicator.Visible = false
partyIndicator.Parent = screenGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(0, 10)
indicatorCorner.Parent = partyIndicator

local indicatorIcon = Instance.new("TextLabel")
indicatorIcon.Size = UDim2.new(1, 0, 1, 0)
indicatorIcon.BackgroundTransparency = 1
indicatorIcon.Font = Enum.Font.GothamBold
indicatorIcon.TextSize = 20
indicatorIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
indicatorIcon.Text = "2"
indicatorIcon.Parent = partyIndicator

-- Invite popup
local invitePopup = Instance.new("Frame")
invitePopup.Name = "InvitePopup"
invitePopup.AnchorPoint = Vector2.new(0.5, 0.5)
invitePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
invitePopup.Size = UDim2.new(0, 300, 0, 350)
invitePopup.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
invitePopup.Visible = false
invitePopup.Parent = screenGui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent = invitePopup

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(80, 200, 80)
popupStroke.Thickness = 2
popupStroke.Parent = invitePopup

local popupTitle = Instance.new("TextLabel")
popupTitle.Position = UDim2.new(0, 15, 0, 10)
popupTitle.Size = UDim2.new(1, -30, 0, 30)
popupTitle.BackgroundTransparency = 1
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextSize = 18
popupTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
popupTitle.Text = "Invite Player"
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.Parent = invitePopup

local popupClose = Instance.new("TextButton")
popupClose.AnchorPoint = Vector2.new(1, 0)
popupClose.Position = UDim2.new(1, -10, 0, 10)
popupClose.Size = UDim2.new(0, 30, 0, 30)
popupClose.BackgroundTransparency = 1
popupClose.Font = Enum.Font.GothamBold
popupClose.TextSize = 20
popupClose.TextColor3 = Color3.fromRGB(180, 180, 180)
popupClose.Text = "X"
popupClose.Parent = invitePopup

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Position = UDim2.new(0, 15, 0, 50)
playerList.Size = UDim2.new(1, -30, 1, -70)
playerList.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
playerList.ScrollBarThickness = 4
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.Parent = invitePopup

local playerListCorner = Instance.new("UICorner")
playerListCorner.CornerRadius = UDim.new(0, 8)
playerListCorner.Parent = playerList

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 2)
playerListLayout.Parent = playerList

local playerListPadding = Instance.new("UIPadding")
playerListPadding.PaddingAll = UDim.new(0, 5)
playerListPadding.Parent = playerList

-- Invite received popup
local inviteReceivedPopup = Instance.new("Frame")
inviteReceivedPopup.Name = "InviteReceivedPopup"
inviteReceivedPopup.AnchorPoint = Vector2.new(0.5, 0)
inviteReceivedPopup.Position = UDim2.new(0.5, 0, 0, -150)
inviteReceivedPopup.Size = UDim2.new(0, 350, 0, 120)
inviteReceivedPopup.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
inviteReceivedPopup.Parent = screenGui

local receivedCorner = Instance.new("UICorner")
receivedCorner.CornerRadius = UDim.new(0, 12)
receivedCorner.Parent = inviteReceivedPopup

local receivedStroke = Instance.new("UIStroke")
receivedStroke.Color = Color3.fromRGB(100, 80, 200)
receivedStroke.Thickness = 2
receivedStroke.Parent = inviteReceivedPopup

local receivedTitle = Instance.new("TextLabel")
receivedTitle.Position = UDim2.new(0, 15, 0, 10)
receivedTitle.Size = UDim2.new(1, -30, 0, 25)
receivedTitle.BackgroundTransparency = 1
receivedTitle.Font = Enum.Font.GothamBold
receivedTitle.TextSize = 16
receivedTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
receivedTitle.Text = "Party Invite"
receivedTitle.TextXAlignment = Enum.TextXAlignment.Left
receivedTitle.Parent = inviteReceivedPopup

local receivedMessage = Instance.new("TextLabel")
receivedMessage.Name = "Message"
receivedMessage.Position = UDim2.new(0, 15, 0, 35)
receivedMessage.Size = UDim2.new(1, -30, 0, 30)
receivedMessage.BackgroundTransparency = 1
receivedMessage.Font = Enum.Font.Gotham
receivedMessage.TextSize = 14
receivedMessage.TextColor3 = Color3.fromRGB(180, 180, 200)
receivedMessage.Text = "PlayerName invited you to their party"
receivedMessage.TextXAlignment = Enum.TextXAlignment.Left
receivedMessage.Parent = inviteReceivedPopup

local acceptButton = Instance.new("TextButton")
acceptButton.Name = "AcceptButton"
acceptButton.Position = UDim2.new(0, 15, 1, -45)
acceptButton.Size = UDim2.new(0.5, -20, 0, 35)
acceptButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
acceptButton.Font = Enum.Font.GothamBold
acceptButton.TextSize = 14
acceptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptButton.Text = "Accept"
acceptButton.Parent = inviteReceivedPopup

local acceptCorner = Instance.new("UICorner")
acceptCorner.CornerRadius = UDim.new(0, 6)
acceptCorner.Parent = acceptButton

local declineButton = Instance.new("TextButton")
declineButton.Name = "DeclineButton"
declineButton.Position = UDim2.new(0.5, 5, 1, -45)
declineButton.Size = UDim2.new(0.5, -20, 0, 35)
declineButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
declineButton.Font = Enum.Font.GothamBold
declineButton.TextSize = 14
declineButton.TextColor3 = Color3.fromRGB(255, 255, 255)
declineButton.Text = "Decline"
declineButton.Parent = inviteReceivedPopup

local declineCorner = Instance.new("UICorner")
declineCorner.CornerRadius = UDim.new(0, 6)
declineCorner.Parent = declineButton

-- ============================================================================
-- STATE
-- ============================================================================

local currentParty = nil
local isLeader = false
local pendingInvite = nil

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function CreateMemberCard(memberData): Frame
	local card = Instance.new("Frame")
	card.Name = "MemberCard"
	card.Size = UDim2.new(1, 0, 0, 35)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	-- Leader icon
	if memberData.isLeader then
		local leaderIcon = Instance.new("TextLabel")
		leaderIcon.Position = UDim2.new(0, 5, 0.5, -10)
		leaderIcon.Size = UDim2.new(0, 20, 0, 20)
		leaderIcon.BackgroundTransparency = 1
		leaderIcon.Font = Enum.Font.GothamBold
		leaderIcon.TextSize = 14
		leaderIcon.TextColor3 = Color3.fromRGB(255, 200, 50)
		leaderIcon.Text = "crown"
		leaderIcon.Parent = card
	end

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, memberData.isLeader and 28 or 8, 0, 0)
	nameLabel.Size = UDim2.new(1, memberData.isLeader and -80 or -60, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = memberData.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Action buttons (only for leader, not for self)
	if isLeader and memberData.userId ~= player.UserId then
		-- Kick button
		local kickButton = Instance.new("TextButton")
		kickButton.AnchorPoint = Vector2.new(1, 0.5)
		kickButton.Position = UDim2.new(1, -5, 0.5, 0)
		kickButton.Size = UDim2.new(0, 25, 0, 25)
		kickButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		kickButton.Font = Enum.Font.GothamBold
		kickButton.TextSize = 12
		kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		kickButton.Text = "X"
		kickButton.Parent = card

		local kickCorner = Instance.new("UICorner")
		kickCorner.CornerRadius = UDim.new(0, 4)
		kickCorner.Parent = kickButton

		kickButton.MouseButton1Click:Connect(function()
			local kickRemote = RemoteEvents:FindFirstChild("KickFromParty")
			if kickRemote then
				kickRemote:FireServer(memberData.userId)
			end
		end)

		-- Promote button
		local promoteButton = Instance.new("TextButton")
		promoteButton.AnchorPoint = Vector2.new(1, 0.5)
		promoteButton.Position = UDim2.new(1, -35, 0.5, 0)
		promoteButton.Size = UDim2.new(0, 25, 0, 25)
		promoteButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		promoteButton.Font = Enum.Font.GothamBold
		promoteButton.TextSize = 10
		promoteButton.TextColor3 = Color3.fromRGB(30, 30, 30)
		promoteButton.Text = "P"
		promoteButton.Parent = card

		local promoteCorner = Instance.new("UICorner")
		promoteCorner.CornerRadius = UDim.new(0, 4)
		promoteCorner.Parent = promoteButton

		promoteButton.MouseButton1Click:Connect(function()
			local transferRemote = RemoteEvents:FindFirstChild("TransferLeadership")
			if transferRemote then
				transferRemote:FireServer(memberData.userId)
			end
		end)
	end

	return card
end

local function CreatePlayerInviteCard(targetPlayer): Frame
	local card = Instance.new("Frame")
	card.Name = "PlayerCard"
	card.Size = UDim2.new(1, 0, 0, 40)
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.Size = UDim2.new(1, -80, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = targetPlayer.Name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.AnchorPoint = Vector2.new(1, 0.5)
	inviteBtn.Position = UDim2.new(1, -5, 0.5, 0)
	inviteBtn.Size = UDim2.new(0, 60, 0, 28)
	inviteBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	inviteBtn.Font = Enum.Font.GothamBold
	inviteBtn.TextSize = 12
	inviteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	inviteBtn.Text = "Invite"
	inviteBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = inviteBtn

	inviteBtn.MouseButton1Click:Connect(function()
		local inviteRemote = RemoteEvents:FindFirstChild("InviteToParty")
		if inviteRemote then
			inviteRemote:FireServer(targetPlayer.UserId)
			inviteBtn.Text = "Sent!"
			inviteBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			task.delay(2, function()
				if inviteBtn.Parent then
					inviteBtn.Text = "Invite"
					inviteBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
				end
			end)
		end
	end)

	return card
end

local function UpdatePartyDisplay()
	-- Clear existing members
	for _, child in ipairs(membersContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if currentParty then
		-- Update header
		headerTitle.Text = string.format("Party (%d/4)", #currentParty.members)

		-- Add member cards
		for _, member in ipairs(currentParty.members) do
			local card = CreateMemberCard(member)
			card.Parent = membersContainer
		end

		-- Update indicator
		indicatorIcon.Text = tostring(#currentParty.members)
		partyIndicator.Visible = not partyPanel.Visible

		-- Update buttons
		inviteButton.Visible = isLeader and #currentParty.members < 4
		leaveButton.Text = isLeader and "Disband Party" or "Leave Party"
	else
		partyIndicator.Visible = false
	end
end

local function UpdatePlayerList()
	-- Clear existing
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get party member IDs
	local partyMemberIds = {}
	if currentParty then
		for _, member in ipairs(currentParty.members) do
			partyMemberIds[member.userId] = true
		end
	end

	-- Add all players except self and party members
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and not partyMemberIds[p.UserId] then
			local card = CreatePlayerInviteCard(p)
			card.Parent = playerList
		end
	end
end

local function ShowInvitePopup()
	UpdatePlayerList()
	invitePopup.Visible = true
end

local function HideInvitePopup()
	invitePopup.Visible = false
end

local function ShowInviteReceived(inviteData)
	pendingInvite = inviteData
	receivedMessage.Text = inviteData.fromName .. " invited you to their party"

	-- Slide in
	TweenService:Create(inviteReceivedPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Auto-hide after timeout
	task.delay(60, function()
		if pendingInvite == inviteData then
			TweenService:Create(inviteReceivedPopup, TweenInfo.new(0.2), {
				Position = UDim2.new(0.5, 0, 0, -150)
			}):Play()
			pendingInvite = nil
		end
	end)
end

local function HideInviteReceived()
	TweenService:Create(inviteReceivedPopup, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, 0, 0, -150)
	}):Play()
end

local function TogglePartyPanel()
	partyPanel.Visible = not partyPanel.Visible
	if partyPanel.Visible then
		partyIndicator.Visible = false
	else
		partyIndicator.Visible = currentParty ~= nil
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

closeButton.MouseButton1Click:Connect(function()
	partyPanel.Visible = false
	partyIndicator.Visible = currentParty ~= nil
end)

partyIndicator.MouseButton1Click:Connect(TogglePartyPanel)

inviteButton.MouseButton1Click:Connect(ShowInvitePopup)

popupClose.MouseButton1Click:Connect(HideInvitePopup)

leaveButton.MouseButton1Click:Connect(function()
	local leaveRemote = RemoteEvents:FindFirstChild("LeaveParty")
	if leaveRemote then
		leaveRemote:FireServer()
	end
end)

acceptButton.MouseButton1Click:Connect(function()
	if pendingInvite then
		local respondRemote = RemoteEvents:FindFirstChild("RespondToInvite")
		if respondRemote then
			respondRemote:FireServer(pendingInvite.fromUserId, true)
		end
		HideInviteReceived()
		pendingInvite = nil
	end
end)

declineButton.MouseButton1Click:Connect(function()
	if pendingInvite then
		local respondRemote = RemoteEvents:FindFirstChild("RespondToInvite")
		if respondRemote then
			respondRemote:FireServer(pendingInvite.fromUserId, false)
		end
		HideInviteReceived()
		pendingInvite = nil
	end
end)

-- Server events
local partySync = RemoteEvents:FindFirstChild("PartySync")
if partySync then
	partySync.OnClientEvent:Connect(function(partyData)
		currentParty = partyData

		if partyData then
			isLeader = partyData.leader == player.UserId
			partyPanel.Visible = true
			partyIndicator.Visible = false
		else
			isLeader = false
			partyPanel.Visible = false
			partyIndicator.Visible = false
		end

		UpdatePartyDisplay()
	end)
end

local partyInviteReceived = RemoteEvents:FindFirstChild("PartyInviteReceived")
if partyInviteReceived then
	partyInviteReceived.OnClientEvent:Connect(function(inviteData)
		ShowInviteReceived(inviteData)
	end)
end

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.P then
		if currentParty then
			TogglePartyPanel()
		else
			-- Create party or show invite popup
			local createRemote = RemoteEvents:FindFirstChild("CreateParty")
			if createRemote then
				createRemote:FireServer()
			end
		end
	end
end)

-- Player list updates
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)

print("[PartyUI] Initialized - Press P to manage party")
