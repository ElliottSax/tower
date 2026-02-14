--[[
	LobbyUI.client.lua
	Main menu and lobby UI for Dimension Hopper

	Features:
	- Dimension selection
	- Game mode selection
	- Lobby player list
	- Ready up button
	- Queue status
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[LobbyUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DIMENSIONS = {
	{
		Name = "Gravity",
		DisplayName = "GRAVITY",
		Icon = "🌀",
		Description = "Where up becomes down and walls become floors",
		Color = Color3.fromRGB(138, 43, 226),
	},
	{
		Name = "Tiny",
		DisplayName = "TINY",
		Icon = "🐜",
		Description = "Shrink down and explore a giant world",
		Color = Color3.fromRGB(34, 139, 34),
	},
	{
		Name = "Void",
		DisplayName = "VOID",
		Icon = "👁️",
		Description = "Run or be consumed by the darkness",
		Color = Color3.fromRGB(139, 0, 0),
	},
	{
		Name = "Sky",
		DisplayName = "SKY",
		Icon = "🦅",
		Description = "Soar through floating islands in the clouds",
		Color = Color3.fromRGB(135, 206, 235),
	},
}

local GAME_MODES = {
	{
		Name = "DimensionRace",
		DisplayName = "Dimension Race",
		Description = "Race through a single dimension",
		Icon = "🏃",
	},
	{
		Name = "Marathon",
		DisplayName = "Dimension Marathon",
		Description = "Race through ALL four dimensions",
		Icon = "🏆",
	},
	{
		Name = "Practice",
		DisplayName = "Practice Mode",
		Description = "No timer, just practice",
		Icon = "🎯",
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

local selectedDimension = "Gravity"
local selectedGameMode = "DimensionRace"
local isInLobby = false
local isReady = false

-- ============================================================================
-- CREATE UI
-- ============================================================================

local function CreateLobbyUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LobbyUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(80, 80, 100)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame

	-- ========================================
	-- TITLE
	-- ========================================

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "DIMENSION HOPPER"
	titleLabel.TextSize = 42
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.Parent = mainFrame

	-- ========================================
	-- LEFT SIDE - DIMENSION SELECTION
	-- ========================================

	local dimensionFrame = Instance.new("Frame")
	dimensionFrame.Name = "DimensionFrame"
	dimensionFrame.Size = UDim2.new(0.45, -20, 0.6, 0)
	dimensionFrame.Position = UDim2.new(0, 20, 0, 80)
	dimensionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	dimensionFrame.BackgroundTransparency = 0.5
	dimensionFrame.Parent = mainFrame

	local dimCorner = Instance.new("UICorner")
	dimCorner.CornerRadius = UDim.new(0, 12)
	dimCorner.Parent = dimensionFrame

	local dimTitle = Instance.new("TextLabel")
	dimTitle.Name = "Title"
	dimTitle.Size = UDim2.new(1, 0, 0, 40)
	dimTitle.BackgroundTransparency = 1
	dimTitle.Text = "SELECT DIMENSION"
	dimTitle.TextSize = 18
	dimTitle.Font = Enum.Font.GothamBold
	dimTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	dimTitle.Parent = dimensionFrame

	local dimList = Instance.new("Frame")
	dimList.Name = "List"
	dimList.Size = UDim2.new(1, -20, 1, -50)
	dimList.Position = UDim2.new(0, 10, 0, 45)
	dimList.BackgroundTransparency = 1
	dimList.Parent = dimensionFrame

	local dimLayout = Instance.new("UIListLayout")
	dimLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dimLayout.Padding = UDim.new(0, 8)
	dimLayout.Parent = dimList

	-- Create dimension buttons
	for i, dim in ipairs(DIMENSIONS) do
		local button = Instance.new("TextButton")
		button.Name = dim.Name
		button.Size = UDim2.new(1, 0, 0, 60)
		button.BackgroundColor3 = dim.Color
		button.BackgroundTransparency = 0.7
		button.Text = ""
		button.LayoutOrder = i
		button.Parent = dimList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = button

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Name = "Stroke"
		btnStroke.Color = dim.Color
		btnStroke.Thickness = 0
		btnStroke.Parent = button

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 40, 1, 0)
		icon.Position = UDim2.new(0, 10, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = dim.Icon
		icon.TextSize = 28
		icon.Font = Enum.Font.GothamBold
		icon.TextColor3 = Color3.new(1, 1, 1)
		icon.Parent = button

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0.4, 0, 0, 25)
		name.Position = UDim2.new(0, 55, 0, 5)
		name.BackgroundTransparency = 1
		name.Text = dim.DisplayName
		name.TextSize = 18
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = button

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -65, 0, 25)
		desc.Position = UDim2.new(0, 55, 0, 28)
		desc.BackgroundTransparency = 1
		desc.Text = dim.Description
		desc.TextSize = 12
		desc.Font = Enum.Font.Gotham
		desc.TextColor3 = Color3.fromRGB(180, 180, 180)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextTruncate = Enum.TextTruncate.AtEnd
		desc.Parent = button

		-- Click handler
		button.MouseButton1Click:Connect(function()
			selectedDimension = dim.Name

			-- Update selection visuals
			for _, child in ipairs(dimList:GetChildren()) do
				if child:IsA("TextButton") then
					local stroke = child:FindFirstChild("Stroke")
					if stroke then
						stroke.Thickness = (child.Name == dim.Name) and 3 or 0
					end
					child.BackgroundTransparency = (child.Name == dim.Name) and 0.4 or 0.7
				end
			end
		end)
	end

	-- ========================================
	-- RIGHT SIDE - GAME MODE & LOBBY
	-- ========================================

	local rightFrame = Instance.new("Frame")
	rightFrame.Name = "RightFrame"
	rightFrame.Size = UDim2.new(0.45, -20, 0.6, 0)
	rightFrame.Position = UDim2.new(0.5, 10, 0, 80)
	rightFrame.BackgroundTransparency = 1
	rightFrame.Parent = mainFrame

	-- Game Mode Selection
	local modeFrame = Instance.new("Frame")
	modeFrame.Name = "ModeFrame"
	modeFrame.Size = UDim2.new(1, 0, 0.5, -5)
	modeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	modeFrame.BackgroundTransparency = 0.5
	modeFrame.Parent = rightFrame

	local modeCorner = Instance.new("UICorner")
	modeCorner.CornerRadius = UDim.new(0, 12)
	modeCorner.Parent = modeFrame

	local modeTitle = Instance.new("TextLabel")
	modeTitle.Size = UDim2.new(1, 0, 0, 35)
	modeTitle.BackgroundTransparency = 1
	modeTitle.Text = "GAME MODE"
	modeTitle.TextSize = 16
	modeTitle.Font = Enum.Font.GothamBold
	modeTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	modeTitle.Parent = modeFrame

	local modeList = Instance.new("Frame")
	modeList.Name = "List"
	modeList.Size = UDim2.new(1, -20, 1, -45)
	modeList.Position = UDim2.new(0, 10, 0, 40)
	modeList.BackgroundTransparency = 1
	modeList.Parent = modeFrame

	local modeLayout = Instance.new("UIListLayout")
	modeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	modeLayout.Padding = UDim.new(0, 5)
	modeLayout.Parent = modeList

	for i, mode in ipairs(GAME_MODES) do
		local button = Instance.new("TextButton")
		button.Name = mode.Name
		button.Size = UDim2.new(1, 0, 0, 35)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		button.BackgroundTransparency = 0.5
		button.Text = ""
		button.LayoutOrder = i
		button.Parent = modeList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = button

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Name = "Stroke"
		btnStroke.Color = Color3.fromRGB(100, 200, 255)
		btnStroke.Thickness = (i == 1) and 2 or 0
		btnStroke.Parent = button

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 30, 1, 0)
		icon.Position = UDim2.new(0, 5, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = mode.Icon
		icon.TextSize = 18
		icon.Font = Enum.Font.GothamBold
		icon.TextColor3 = Color3.new(1, 1, 1)
		icon.Parent = button

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -40, 1, 0)
		name.Position = UDim2.new(0, 40, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = mode.DisplayName
		name.TextSize = 14
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = button

		button.MouseButton1Click:Connect(function()
			selectedGameMode = mode.Name

			for _, child in ipairs(modeList:GetChildren()) do
				if child:IsA("TextButton") then
					local stroke = child:FindFirstChild("Stroke")
					if stroke then
						stroke.Thickness = (child.Name == mode.Name) and 2 or 0
					end
				end
			end
		end)
	end

	-- Lobby Info
	local lobbyFrame = Instance.new("Frame")
	lobbyFrame.Name = "LobbyFrame"
	lobbyFrame.Size = UDim2.new(1, 0, 0.5, -5)
	lobbyFrame.Position = UDim2.new(0, 0, 0.5, 5)
	lobbyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	lobbyFrame.BackgroundTransparency = 0.5
	lobbyFrame.Parent = rightFrame

	local lobbyCorner = Instance.new("UICorner")
	lobbyCorner.CornerRadius = UDim.new(0, 12)
	lobbyCorner.Parent = lobbyFrame

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.Name = "Title"
	lobbyTitle.Size = UDim2.new(1, 0, 0, 35)
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Text = "LOBBY (0/16)"
	lobbyTitle.TextSize = 16
	lobbyTitle.Font = Enum.Font.GothamBold
	lobbyTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	lobbyTitle.Parent = lobbyFrame

	local lobbyList = Instance.new("ScrollingFrame")
	lobbyList.Name = "PlayerList"
	lobbyList.Size = UDim2.new(1, -20, 1, -45)
	lobbyList.Position = UDim2.new(0, 10, 0, 40)
	lobbyList.BackgroundTransparency = 1
	lobbyList.ScrollBarThickness = 4
	lobbyList.CanvasSize = UDim2.new(0, 0, 0, 0)
	lobbyList.Parent = lobbyFrame

	local lobbyLayout = Instance.new("UIListLayout")
	lobbyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lobbyLayout.Padding = UDim.new(0, 3)
	lobbyLayout.Parent = lobbyList

	-- ========================================
	-- BOTTOM - ACTION BUTTONS
	-- ========================================

	local buttonFrame = Instance.new("Frame")
	buttonFrame.Name = "ButtonFrame"
	buttonFrame.Size = UDim2.new(1, -40, 0, 60)
	buttonFrame.Position = UDim2.new(0, 20, 1, -80)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = mainFrame

	-- Play Button
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0.3, 0, 1, 0)
	playButton.Position = UDim2.new(0.35, 0, 0, 0)
	playButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
	playButton.Text = "PLAY"
	playButton.TextSize = 24
	playButton.Font = Enum.Font.GothamBold
	playButton.TextColor3 = Color3.new(1, 1, 1)
	playButton.Parent = buttonFrame

	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 10)
	playCorner.Parent = playButton

	-- Ready Button (shown when in lobby)
	local readyButton = Instance.new("TextButton")
	readyButton.Name = "ReadyButton"
	readyButton.Size = UDim2.new(0.2, 0, 1, 0)
	readyButton.Position = UDim2.new(0.68, 0, 0, 0)
	readyButton.BackgroundColor3 = Color3.fromRGB(200, 180, 50)
	readyButton.Text = "READY"
	readyButton.TextSize = 18
	readyButton.Font = Enum.Font.GothamBold
	readyButton.TextColor3 = Color3.new(1, 1, 1)
	readyButton.Visible = false
	readyButton.Parent = buttonFrame

	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, 10)
	readyCorner.Parent = readyButton

	-- Leave Button
	local leaveButton = Instance.new("TextButton")
	leaveButton.Name = "LeaveButton"
	leaveButton.Size = UDim2.new(0.15, 0, 1, 0)
	leaveButton.Position = UDim2.new(0.9, 0, 0, 0)
	leaveButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	leaveButton.Text = "LEAVE"
	leaveButton.TextSize = 16
	leaveButton.Font = Enum.Font.GothamBold
	leaveButton.TextColor3 = Color3.new(1, 1, 1)
	leaveButton.Visible = false
	leaveButton.Parent = buttonFrame

	local leaveCorner = Instance.new("UICorner")
	leaveCorner.CornerRadius = UDim.new(0, 10)
	leaveCorner.Parent = leaveButton

	return screenGui
end

local LobbyUI = CreateLobbyUI()

-- ============================================================================
-- UI FUNCTIONS
-- ============================================================================

local function UpdateLobbyList(players)
	local lobbyList = LobbyUI.MainFrame.RightFrame.LobbyFrame.PlayerList

	-- Clear existing
	for _, child in ipairs(lobbyList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add players
	for i, p in ipairs(players) do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, 0, 0, 25)
		entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		entry.BackgroundTransparency = 0.5
		entry.LayoutOrder = i
		entry.Parent = lobbyList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 4)
		entryCorner.Parent = entry

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = p.Name
		nameLabel.TextSize = 14
		nameLabel.Font = p.UserId == player.UserId and Enum.Font.GothamBold or Enum.Font.Gotham
		nameLabel.TextColor3 = p.UserId == player.UserId
			and Color3.fromRGB(255, 215, 0)
			or Color3.new(1, 1, 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entry

		local readyLabel = Instance.new("TextLabel")
		readyLabel.Size = UDim2.new(0.3, -10, 1, 0)
		readyLabel.Position = UDim2.new(0.7, 0, 0, 0)
		readyLabel.BackgroundTransparency = 1
		readyLabel.Text = p.Ready and "✓ READY" or "..."
		readyLabel.TextSize = 12
		readyLabel.Font = Enum.Font.GothamBold
		readyLabel.TextColor3 = p.Ready
			and Color3.fromRGB(100, 255, 100)
			or Color3.fromRGB(150, 150, 150)
		readyLabel.TextXAlignment = Enum.TextXAlignment.Right
		readyLabel.Parent = entry
	end

	-- Update canvas size
	local layout = lobbyList:FindFirstChildOfClass("UIListLayout")
	if layout then
		lobbyList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end

	-- Update title
	local title = LobbyUI.MainFrame.RightFrame.LobbyFrame.Title
	title.Text = string.format("LOBBY (%d/16)", #players)
end

local function SetLobbyState(inLobby)
	isInLobby = inLobby

	local buttonFrame = LobbyUI.MainFrame.ButtonFrame

	buttonFrame.PlayButton.Text = inLobby and "SEARCHING..." or "PLAY"
	buttonFrame.PlayButton.BackgroundColor3 = inLobby
		and Color3.fromRGB(100, 100, 100)
		or Color3.fromRGB(50, 200, 80)

	buttonFrame.ReadyButton.Visible = inLobby
	buttonFrame.LeaveButton.Visible = inLobby
end

local function SetReadyState(ready)
	isReady = ready

	local readyButton = LobbyUI.MainFrame.ButtonFrame.ReadyButton
	readyButton.Text = ready and "READY ✓" or "READY"
	readyButton.BackgroundColor3 = ready
		and Color3.fromRGB(100, 255, 100)
		or Color3.fromRGB(200, 180, 50)
end

local function ShowLobbyUI()
	LobbyUI.MainFrame.Visible = true
end

local function HideLobbyUI()
	LobbyUI.MainFrame.Visible = false
end

-- ============================================================================
-- BUTTON HANDLERS
-- ============================================================================

local buttonFrame = LobbyUI.MainFrame.ButtonFrame

buttonFrame.PlayButton.MouseButton1Click:Connect(function()
	if isInLobby then return end

	-- Join lobby
	if RemoteEvents:FindFirstChild("JoinLobby") then
		RemoteEvents.JoinLobby:FireServer(selectedDimension, selectedGameMode)
		SetLobbyState(true)
	end
end)

buttonFrame.ReadyButton.MouseButton1Click:Connect(function()
	if not isInLobby then return end

	-- Toggle ready
	if RemoteEvents:FindFirstChild("ReadyUp") then
		RemoteEvents.ReadyUp:FireServer()
		SetReadyState(not isReady)
	end
end)

buttonFrame.LeaveButton.MouseButton1Click:Connect(function()
	if not isInLobby then return end

	-- Leave lobby
	if RemoteEvents:FindFirstChild("LeaveLobby") then
		RemoteEvents.LeaveLobby:FireServer()
		SetLobbyState(false)
		SetReadyState(false)
		UpdateLobbyList({})
	end
end)

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

if RemoteEvents:FindFirstChild("RaceState") then
	RemoteEvents.RaceState.OnClientEvent:Connect(function(state, data)
		if state == "LobbyUpdate" and data then
			UpdateLobbyList(data.Players or {})
		elseif state == "Countdown" or state == "Racing" then
			HideLobbyUI()
		elseif state == "Results" then
			-- Show results, then return to lobby
		elseif state == "Idle" then
			ShowLobbyUI()
			SetLobbyState(false)
			SetReadyState(false)
		end
	end)
end

-- ============================================================================
-- INITIAL STATE
-- ============================================================================

-- Select first dimension by default
local dimList = LobbyUI.MainFrame.DimensionFrame.List
local firstDim = dimList:FindFirstChild("Gravity")
if firstDim then
	local stroke = firstDim:FindFirstChild("Stroke")
	if stroke then stroke.Thickness = 3 end
	firstDim.BackgroundTransparency = 0.4
end

print("[LobbyUI] Lobby UI initialized")
