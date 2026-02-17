--[[
	MergeUI.lua - Merge Mania
	Main client UI: merge grid, item dragging, earnings counter, navigation

	Features:
	- 6x6 (or 8x8) merge grid with drag-and-drop
	- Real-time earnings counter (coins/sec)
	- Item display with tier colors, path icons, golden glow
	- Bottom navigation bar (Grid, Generators, Collections, Prestige, Shop)
	- Notification system
	- Offline earnings popup
	- Merge result animations
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local MergeUI = {}
local screenGui
local gridFrame, gridCells
local earningsLabel, coinsLabel
local notificationContainer
local activePanel = "Grid"
local navButtons = {}

-- Grid state (mirrors server)
local localGrid = {}
local gridRows = 6
local gridCols = 6

-- Drag state
local isDragging = false
local dragItem = nil
local dragFromRow = nil
local dragFromCol = nil
local dragGhost = nil

-- Earnings display
local currentCoins = 0
local coinsPerSec = 0
local displayedCoins = 0

-- ============================================================================
-- THEME CONSTANTS
-- ============================================================================
local THEME = GameConfig.Theme
local CELL_SIZE = 70
local CELL_PADDING = 4
local NAV_HEIGHT = 60
local HEADER_HEIGHT = 60
local GRID_PADDING = 10

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MergeUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MergeManiaUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = player.PlayerGui

	-- Build UI layers
	MergeUI.CreateHeader()
	MergeUI.CreateGrid()
	MergeUI.CreateNavBar()
	MergeUI.CreateNotificationContainer()

	-- Connect remote events
	MergeUI.ConnectEvents()

	-- Start display update loop
	MergeUI.StartDisplayLoop()

	-- Request initial data
	task.spawn(function()
		local gridState = remoteFunctions:WaitForChild("GetGridState"):InvokeServer()
		if gridState then
			MergeUI.UpdateFullGrid(gridState)
		end
	end)
end

-- ============================================================================
-- HEADER (Coins display + earnings per second)
-- ============================================================================

function MergeUI.CreateHeader()
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = THEME.PanelColor
	header.BackgroundTransparency = 0.1
	header.BorderSizePixel = 0
	header.Parent = screenGui

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 0)
	headerCorner.Parent = header

	-- Coins display
	coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0.5, -10, 1, 0)
	coinsLabel.Position = UDim2.new(0, 20, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "0 Coins"
	coinsLabel.TextColor3 = GameConfig.Theme.GoldenColor
	coinsLabel.TextSize = 24
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = header

	-- Earnings per second
	earningsLabel = Instance.new("TextLabel")
	earningsLabel.Name = "EarningsLabel"
	earningsLabel.Size = UDim2.new(0.5, -10, 1, 0)
	earningsLabel.Position = UDim2.new(0.5, 0, 0, 0)
	earningsLabel.BackgroundTransparency = 1
	earningsLabel.Text = "+0/sec"
	earningsLabel.TextColor3 = THEME.SuccessColor
	earningsLabel.TextSize = 18
	earningsLabel.Font = Enum.Font.GothamMedium
	earningsLabel.TextXAlignment = Enum.TextXAlignment.Right
	earningsLabel.Parent = header
end

-- ============================================================================
-- MERGE GRID
-- ============================================================================

function MergeUI.CreateGrid()
	local totalGridWidth = gridCols * (CELL_SIZE + CELL_PADDING) + GRID_PADDING * 2
	local totalGridHeight = gridRows * (CELL_SIZE + CELL_PADDING) + GRID_PADDING * 2

	gridFrame = Instance.new("Frame")
	gridFrame.Name = "GridFrame"
	gridFrame.Size = UDim2.new(0, totalGridWidth, 0, totalGridHeight)
	gridFrame.Position = UDim2.new(0.5, -totalGridWidth / 2, 0, HEADER_HEIGHT + 10)
	gridFrame.BackgroundColor3 = THEME.PanelColor
	gridFrame.BackgroundTransparency = 0.3
	gridFrame.BorderSizePixel = 0
	gridFrame.Parent = screenGui

	local gridCorner = Instance.new("UICorner")
	gridCorner.CornerRadius = UDim.new(0, 12)
	gridCorner.Parent = gridFrame

	-- Create grid cells
	gridCells = {}
	for row = 1, gridRows do
		gridCells[row] = {}
		for col = 1, gridCols do
			local cell = MergeUI.CreateCell(row, col)
			gridCells[row][col] = cell
		end
	end
end

function MergeUI.CreateCell(row, col)
	local x = GRID_PADDING + (col - 1) * (CELL_SIZE + CELL_PADDING)
	local y = GRID_PADDING + (row - 1) * (CELL_SIZE + CELL_PADDING)

	local cell = Instance.new("Frame")
	cell.Name = "Cell_" .. row .. "_" .. col
	cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
	cell.Position = UDim2.new(0, x, 0, y)
	cell.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	cell.BackgroundTransparency = 0.3
	cell.BorderSizePixel = 0
	cell.Parent = gridFrame

	local cellCorner = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 8)
	cellCorner.Parent = cell

	-- Item display (hidden by default)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "ItemFrame"
	itemFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
	itemFrame.Position = UDim2.new(0.075, 0, 0.075, 0)
	itemFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	itemFrame.BackgroundTransparency = 1
	itemFrame.BorderSizePixel = 0
	itemFrame.Visible = false
	itemFrame.Parent = cell

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 6)
	itemCorner.Parent = itemFrame

	-- Tier number
	local tierLabel = Instance.new("TextLabel")
	tierLabel.Name = "TierLabel"
	tierLabel.Size = UDim2.new(1, 0, 0.4, 0)
	tierLabel.Position = UDim2.new(0, 0, 0, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = ""
	tierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	tierLabel.TextSize = 20
	tierLabel.Font = Enum.Font.GothamBold
	tierLabel.Parent = itemFrame

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ""
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.TextSize = 9
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextWrapped = true
	nameLabel.Parent = itemFrame

	-- Path indicator
	local pathLabel = Instance.new("TextLabel")
	pathLabel.Name = "PathLabel"
	pathLabel.Size = UDim2.new(1, 0, 0.25, 0)
	pathLabel.Position = UDim2.new(0, 0, 0.75, 0)
	pathLabel.BackgroundTransparency = 1
	pathLabel.Text = ""
	pathLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	pathLabel.TextSize = 8
	pathLabel.Font = Enum.Font.Gotham
	pathLabel.Parent = itemFrame

	-- Golden indicator
	local goldenIndicator = Instance.new("Frame")
	goldenIndicator.Name = "GoldenIndicator"
	goldenIndicator.Size = UDim2.new(0.3, 0, 0.15, 0)
	goldenIndicator.Position = UDim2.new(0.7, 0, 0, 0)
	goldenIndicator.BackgroundColor3 = GameConfig.Theme.GoldenColor
	goldenIndicator.Visible = false
	goldenIndicator.Parent = itemFrame

	local goldenCorner = Instance.new("UICorner")
	goldenCorner.CornerRadius = UDim.new(0, 4)
	goldenCorner.Parent = goldenIndicator

	local goldenText = Instance.new("TextLabel")
	goldenText.Size = UDim2.new(1, 0, 1, 0)
	goldenText.BackgroundTransparency = 1
	goldenText.Text = "5x"
	goldenText.TextColor3 = Color3.fromRGB(0, 0, 0)
	goldenText.TextSize = 8
	goldenText.Font = Enum.Font.GothamBold
	goldenText.Parent = goldenIndicator

	-- Click/drag detection
	local inputButton = Instance.new("TextButton")
	inputButton.Name = "InputButton"
	inputButton.Size = UDim2.new(1, 0, 1, 0)
	inputButton.BackgroundTransparency = 1
	inputButton.Text = ""
	inputButton.Parent = cell
	inputButton.ZIndex = 5

	-- Drag handling
	inputButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			MergeUI.StartDrag(row, col)
		end
	end)

	inputButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDragging and dragFromRow == row and dragFromCol == col then
				-- Ended on same cell - could be a tap to sell
			end
		end
	end)

	-- Drop target
	inputButton.MouseEnter:Connect(function()
		if isDragging and (row ~= dragFromRow or col ~= dragFromCol) then
			-- Highlight potential drop target
			MergeUI.HighlightCell(row, col, true)
		end
	end)

	inputButton.MouseLeave:Connect(function()
		MergeUI.HighlightCell(row, col, false)
	end)

	return {
		Frame = cell,
		ItemFrame = itemFrame,
		TierLabel = tierLabel,
		NameLabel = nameLabel,
		PathLabel = pathLabel,
		GoldenIndicator = goldenIndicator,
		InputButton = inputButton,
	}
end

-- ============================================================================
-- DRAG AND DROP
-- ============================================================================

function MergeUI.StartDrag(row, col)
	local key = row .. "_" .. col
	local item = localGrid[key]
	if not item then return end

	isDragging = true
	dragFromRow = row
	dragFromCol = col
	dragItem = item

	-- Create ghost element
	dragGhost = Instance.new("Frame")
	dragGhost.Name = "DragGhost"
	dragGhost.Size = UDim2.new(0, CELL_SIZE * 0.8, 0, CELL_SIZE * 0.8)
	dragGhost.BackgroundColor3 = GameConfig.GetTierColor(item.Tier)
	dragGhost.BackgroundTransparency = 0.3
	dragGhost.BorderSizePixel = 0
	dragGhost.ZIndex = 100
	dragGhost.Parent = screenGui

	local ghostCorner = Instance.new("UICorner")
	ghostCorner.CornerRadius = UDim.new(0, 8)
	ghostCorner.Parent = dragGhost

	local ghostLabel = Instance.new("TextLabel")
	ghostLabel.Size = UDim2.new(1, 0, 1, 0)
	ghostLabel.BackgroundTransparency = 1
	ghostLabel.Text = "T" .. item.Tier
	ghostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ghostLabel.TextSize = 18
	ghostLabel.Font = Enum.Font.GothamBold
	ghostLabel.ZIndex = 101
	ghostLabel.Parent = dragGhost

	-- Dim source cell
	local cellData = gridCells[row] and gridCells[row][col]
	if cellData then
		cellData.ItemFrame.BackgroundTransparency = 0.5
	end
end

-- Track mouse/touch for drag ghost position
UserInputService.InputChanged:Connect(function(input)
	if not isDragging or not dragGhost then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		dragGhost.Position = UDim2.new(0, pos.X - CELL_SIZE * 0.4, 0, pos.Y - CELL_SIZE * 0.4)
	end
end)

-- Handle drop on mouse/touch release
UserInputService.InputEnded:Connect(function(input)
	if not isDragging then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- Find which cell we dropped on
		local dropRow, dropCol = MergeUI.GetCellAtPosition(input.Position)

		if dropRow and dropCol and (dropRow ~= dragFromRow or dropCol ~= dragFromCol) then
			-- Check if this would be a merge or a move
			local targetKey = dropRow .. "_" .. dropCol
			local targetItem = localGrid[targetKey]

			if targetItem and targetItem.Path == dragItem.Path and targetItem.Tier == dragItem.Tier then
				-- Merge!
				remoteEvents.MergeItems:FireServer(dragFromRow, dragFromCol, dropRow, dropCol)
			else
				-- Move
				remoteEvents.MoveItem:FireServer(dragFromRow, dragFromCol, dropRow, dropCol)
			end
		end

		-- Cleanup drag state
		MergeUI.EndDrag()
	end
end)

function MergeUI.EndDrag()
	isDragging = false

	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end

	-- Restore source cell
	if dragFromRow and dragFromCol then
		local cellData = gridCells[dragFromRow] and gridCells[dragFromRow][dragFromCol]
		if cellData then
			cellData.ItemFrame.BackgroundTransparency = 0
		end
	end

	-- Clear all highlights
	for r = 1, gridRows do
		for c = 1, gridCols do
			MergeUI.HighlightCell(r, c, false)
		end
	end

	dragFromRow = nil
	dragFromCol = nil
	dragItem = nil
end

function MergeUI.GetCellAtPosition(screenPos)
	local gridAbsPos = gridFrame.AbsolutePosition
	local relX = screenPos.X - gridAbsPos.X - GRID_PADDING
	local relY = screenPos.Y - gridAbsPos.Y - GRID_PADDING

	local col = math.floor(relX / (CELL_SIZE + CELL_PADDING)) + 1
	local row = math.floor(relY / (CELL_SIZE + CELL_PADDING)) + 1

	if row >= 1 and row <= gridRows and col >= 1 and col <= gridCols then
		return row, col
	end
	return nil, nil
end

function MergeUI.HighlightCell(row, col, highlight)
	local cellData = gridCells[row] and gridCells[row][col]
	if not cellData then return end

	if highlight then
		local key = row .. "_" .. col
		local targetItem = localGrid[key]
		local canMerge = targetItem and dragItem
			and targetItem.Path == dragItem.Path
			and targetItem.Tier == dragItem.Tier

		cellData.Frame.BackgroundColor3 = canMerge
			and THEME.SuccessColor
			or Color3.fromRGB(80, 80, 100)
	else
		cellData.Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	end
end

-- ============================================================================
-- CELL RENDERING
-- ============================================================================

function MergeUI.UpdateCell(row, col, itemData)
	local cellData = gridCells[row] and gridCells[row][col]
	if not cellData then return end

	if not itemData then
		-- Empty cell
		cellData.ItemFrame.Visible = false
		cellData.TierLabel.Text = ""
		cellData.NameLabel.Text = ""
		cellData.PathLabel.Text = ""
		cellData.GoldenIndicator.Visible = false
		return
	end

	-- Get tier display data
	local tierData = GameConfig.GetTierData(itemData.Path, itemData.Tier)
	local tierColor = tierData and tierData.Color or GameConfig.GetTierColor(itemData.Tier)

	cellData.ItemFrame.Visible = true
	cellData.ItemFrame.BackgroundColor3 = tierColor
	cellData.ItemFrame.BackgroundTransparency = 0

	cellData.TierLabel.Text = "T" .. itemData.Tier
	cellData.NameLabel.Text = tierData and tierData.Name or ("Tier " .. itemData.Tier)
	cellData.PathLabel.Text = itemData.Path

	-- Golden indicator
	cellData.GoldenIndicator.Visible = itemData.IsGolden == true

	-- Glow effect for high-tier items
	if itemData.Tier >= 15 then
		-- Pulsing glow for high-tier items
		local glow = cellData.Frame:FindFirstChild("HighTierGlow")
		if not glow then
			glow = Instance.new("UIStroke")
			glow.Name = "HighTierGlow"
			glow.Color = tierColor
			glow.Thickness = 2
			glow.Parent = cellData.Frame
		end
		glow.Color = tierColor
	else
		local glow = cellData.Frame:FindFirstChild("HighTierGlow")
		if glow then glow:Destroy() end
	end
end

-- ============================================================================
-- NAVIGATION BAR
-- ============================================================================

function MergeUI.CreateNavBar()
	local navFrame = Instance.new("Frame")
	navFrame.Name = "NavBar"
	navFrame.Size = UDim2.new(1, 0, 0, NAV_HEIGHT)
	navFrame.Position = UDim2.new(0, 0, 1, -NAV_HEIGHT)
	navFrame.BackgroundColor3 = THEME.PanelColor
	navFrame.BackgroundTransparency = 0.1
	navFrame.BorderSizePixel = 0
	navFrame.ZIndex = 10
	navFrame.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = navFrame

	local tabs = {
		{ Name = "Grid", Color = THEME.AccentColor },
		{ Name = "Generators", Color = Color3.fromRGB(76, 175, 80) },
		{ Name = "Collections", Color = Color3.fromRGB(255, 193, 7) },
		{ Name = "Prestige", Color = Color3.fromRGB(156, 39, 176) },
		{ Name = "Shop", Color = Color3.fromRGB(233, 30, 99) },
		{ Name = "Paths", Color = Color3.fromRGB(255, 140, 0) },
	}

	for _, tab in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Name = tab.Name
		btn.Size = UDim2.new(0, 80, 0, 44)
		btn.BackgroundColor3 = tab.Color
		btn.BackgroundTransparency = tab.Name == "Grid" and 0 or 0.5
		btn.Text = tab.Name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 11
		btn.Parent = navFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		navButtons[tab.Name] = { Button = btn, Color = tab.Color }

		-- Hover effect
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundTransparency = 0,
			}):Play()
		end)

		btn.MouseLeave:Connect(function()
			if activePanel ~= tab.Name then
				TweenService:Create(btn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.5,
				}):Play()
			end
		end)

		btn.Activated:Connect(function()
			MergeUI.SwitchPanel(tab.Name)
		end)
	end
end

function MergeUI.SwitchPanel(panelName)
	activePanel = panelName

	-- Update nav button states
	for name, data in pairs(navButtons) do
		data.Button.BackgroundTransparency = name == panelName and 0 or 0.5
	end

	-- Show/hide grid
	gridFrame.Visible = panelName == "Grid"

	-- Request data for panels
	if panelName == "Generators" then
		remoteEvents.GetGenerators:FireServer()
	elseif panelName == "Collections" then
		remoteEvents.GetCollections:FireServer()
	elseif panelName == "Prestige" then
		remoteEvents.GetPrestigeInfo:FireServer()
	elseif panelName == "Shop" then
		remoteEvents.GetShopData:FireServer()
	elseif panelName == "Paths" then
		remoteEvents.GetPathInfo:FireServer()
	end
end

-- ============================================================================
-- NOTIFICATION SYSTEM
-- ============================================================================

function MergeUI.CreateNotificationContainer()
	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0.5, 0, 0, 200)
	notificationContainer.Position = UDim2.new(0.25, 0, 0.08, 0)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = notificationContainer
end

function MergeUI.ShowNotification(text, color, duration)
	duration = duration or 3

	local notif = Instance.new("TextLabel")
	notif.Name = "Notification"
	notif.Size = UDim2.new(1, 0, 0, 36)
	notif.BackgroundColor3 = color or THEME.PanelColor
	notif.BackgroundTransparency = 0.15
	notif.Text = "  " .. text
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.TextSize = 14
	notif.Font = Enum.Font.GothamBold
	notif.TextWrapped = true
	notif.TextXAlignment = Enum.TextXAlignment.Left
	notif.Parent = notificationContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif

	-- Animate in
	notif.BackgroundTransparency = 1
	notif.TextTransparency = 1
	TweenService:Create(notif, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		BackgroundTransparency = 0.15,
		TextTransparency = 0,
	}):Play()

	-- Fade out
	task.delay(duration, function()
		if notif and notif.Parent then
			TweenService:Create(notif, TweenInfo.new(0.4), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}):Play()
			task.wait(0.4)
			if notif and notif.Parent then
				notif:Destroy()
			end
		end
	end)
end

-- ============================================================================
-- MERGE RESULT ANIMATION
-- ============================================================================

function MergeUI.PlayMergeEffect(row, col, isGolden, tierName)
	local cellData = gridCells[row] and gridCells[row][col]
	if not cellData then return end

	-- Flash effect
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 10, 1, 10)
	flash.Position = UDim2.new(0, -5, 0, -5)
	flash.BackgroundColor3 = isGolden and THEME.GoldenColor or THEME.AccentColor
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = cellData.Frame

	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 10)
	flashCorner.Parent = flash

	TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
		Size = UDim2.new(1.5, 0, 1.5, 0),
		Position = UDim2.new(-0.25, 0, -0.25, 0),
	}):Play()

	task.delay(0.5, function()
		if flash and flash.Parent then
			flash:Destroy()
		end
	end)

	-- Scale bounce on the item
	if cellData.ItemFrame.Visible then
		cellData.ItemFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
		cellData.ItemFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
		TweenService:Create(cellData.ItemFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.85, 0, 0.85, 0),
			Position = UDim2.new(0.075, 0, 0.075, 0),
		}):Play()
	end

	-- Floating text for golden merges
	if isGolden then
		MergeUI.ShowNotification("GOLDEN " .. (tierName or "Merge") .. "! (5x value)", THEME.GoldenColor, 4)
	end
end

-- ============================================================================
-- OFFLINE EARNINGS POPUP
-- ============================================================================

function MergeUI.ShowOfflineEarningsPopup(data)
	local overlay = Instance.new("Frame")
	overlay.Name = "OfflineOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex = 200
	overlay.Parent = screenGui

	local popup = Instance.new("Frame")
	popup.Name = "OfflinePopup"
	popup.Size = UDim2.new(0, 320, 0, 240)
	popup.Position = UDim2.new(0.5, -160, 0.5, -120)
	popup.BackgroundColor3 = THEME.PanelColor
	popup.BorderSizePixel = 0
	popup.ZIndex = 201
	popup.Parent = overlay

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = popup

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Welcome Back!"
	title.TextColor3 = THEME.GoldenColor
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 202
	title.Parent = popup

	-- Time away
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, 0, 0, 30)
	timeLabel.Position = UDim2.new(0, 0, 0, 45)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "You were away for " .. (data.TimeString or "a while")
	timeLabel.TextColor3 = THEME.TextSecondary
	timeLabel.TextSize = 14
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.ZIndex = 202
	timeLabel.Parent = popup

	-- Coins earned
	local coinsEarned = Instance.new("TextLabel")
	coinsEarned.Size = UDim2.new(1, 0, 0, 50)
	coinsEarned.Position = UDim2.new(0, 0, 0, 80)
	coinsEarned.BackgroundTransparency = 1
	coinsEarned.Text = GameConfig.FormatNumber(data.Coins) .. " Coins"
	coinsEarned.TextColor3 = THEME.GoldenColor
	coinsEarned.TextSize = 30
	coinsEarned.Font = Enum.Font.GothamBold
	coinsEarned.ZIndex = 202
	coinsEarned.Parent = popup

	-- Efficiency note
	local effNote = Instance.new("TextLabel")
	effNote.Size = UDim2.new(1, 0, 0, 20)
	effNote.Position = UDim2.new(0, 0, 0, 130)
	effNote.BackgroundTransparency = 1
	effNote.Text = "(" .. math.floor(data.Efficiency * 100) .. "% offline rate)"
	effNote.TextColor3 = THEME.TextSecondary
	effNote.TextSize = 12
	effNote.Font = Enum.Font.Gotham
	effNote.ZIndex = 202
	effNote.Parent = popup

	-- Collect button
	local collectBtn = Instance.new("TextButton")
	collectBtn.Size = UDim2.new(0.7, 0, 0, 44)
	collectBtn.Position = UDim2.new(0.15, 0, 0, 170)
	collectBtn.BackgroundColor3 = THEME.SuccessColor
	collectBtn.Text = "Collect!"
	collectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectBtn.TextSize = 18
	collectBtn.Font = Enum.Font.GothamBold
	collectBtn.ZIndex = 202
	collectBtn.Parent = popup

	local collectCorner = Instance.new("UICorner")
	collectCorner.CornerRadius = UDim.new(0, 8)
	collectCorner.Parent = collectBtn

	collectBtn.Activated:Connect(function()
		remoteEvents.CollectOffline:FireServer()

		-- Animate out
		TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
		task.wait(0.3)
		overlay:Destroy()
	end)

	-- Animate in
	popup.Size = UDim2.new(0, 0, 0, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 240),
		Position = UDim2.new(0.5, -160, 0.5, -120),
	}):Play()
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

function MergeUI.ConnectEvents()
	-- Full grid update
	remoteEvents:WaitForChild("GridUpdate").OnClientEvent:Connect(function(state)
		MergeUI.UpdateFullGrid(state)
	end)

	-- Single cell update
	remoteEvents:WaitForChild("GridCellUpdate").OnClientEvent:Connect(function(row, col, itemData)
		local key = row .. "_" .. col
		localGrid[key] = itemData
		MergeUI.UpdateCell(row, col, itemData)
	end)

	-- Merge result
	remoteEvents:WaitForChild("MergeResult").OnClientEvent:Connect(function(result)
		if result.Success and result.Data then
			-- Play merge effect (find the cell from grid update)
			-- The cell update will have already happened
			MergeUI.ShowNotification(
				"Merged: " .. (result.Data.Name or "Unknown") .. (result.Data.IsGolden and " (GOLDEN!)" or ""),
				result.Data.IsGolden and THEME.GoldenColor or THEME.SuccessColor
			)
		end
	end)

	-- Earnings update
	remoteEvents:WaitForChild("EarningsUpdate").OnClientEvent:Connect(function(data)
		currentCoins = data.CurrentCoins or 0
		coinsPerSec = data.CoinsPerSec or 0
	end)

	-- Offline earnings
	remoteEvents:WaitForChild("OfflineEarnings").OnClientEvent:Connect(function(data)
		MergeUI.ShowOfflineEarningsPopup(data)
	end)

	-- Notifications
	remoteEvents:WaitForChild("Notification").OnClientEvent:Connect(function(data)
		MergeUI.ShowNotification(data.Text, data.Color)
	end)

	-- Player stats
	remoteEvents:WaitForChild("PlayerStats").OnClientEvent:Connect(function(stats)
		currentCoins = stats.Coins or currentCoins
	end)

	-- Collection complete
	remoteEvents:WaitForChild("CollectionComplete").OnClientEvent:Connect(function(data)
		MergeUI.ShowNotification(
			"COLLECTION COMPLETE: " .. data.CollectionName .. " - " .. data.Reward,
			THEME.GoldenColor, 5
		)
	end)

	-- Prestige complete
	remoteEvents:WaitForChild("PrestigeComplete").OnClientEvent:Connect(function(data)
		MergeUI.ShowNotification(
			"PRESTIGE " .. data.NewLevel .. "! Multiplier: " .. string.format("%.1fx", data.Multiplier),
			Color3.fromRGB(156, 39, 176), 5
		)
		-- Refresh grid
		task.spawn(function()
			local gridState = remoteFunctions.GetGridState:InvokeServer()
			if gridState then
				MergeUI.UpdateFullGrid(gridState)
			end
		end)
	end)

	-- Path unlocked
	remoteEvents:WaitForChild("PathUnlocked").OnClientEvent:Connect(function(data)
		MergeUI.ShowNotification(
			data.Path .. " path unlocked!",
			data.Color or THEME.SuccessColor, 4
		)
	end)

	-- Generator spawn
	remoteEvents:WaitForChild("GeneratorSpawn").OnClientEvent:Connect(function(data)
		-- Subtle notification for generator spawns (don't spam)
	end)
end

-- ============================================================================
-- GRID STATE MANAGEMENT
-- ============================================================================

function MergeUI.UpdateFullGrid(state)
	if not state then return end

	-- Update grid dimensions
	if state.Rows and state.Cols then
		if state.Rows ~= gridRows or state.Cols ~= gridCols then
			gridRows = state.Rows
			gridCols = state.Cols
			MergeUI.RebuildGrid()
		end
	end

	-- Update local grid cache
	localGrid = state.Grid or {}

	-- Render all cells
	for row = 1, gridRows do
		for col = 1, gridCols do
			local key = row .. "_" .. col
			MergeUI.UpdateCell(row, col, localGrid[key])
		end
	end
end

function MergeUI.RebuildGrid()
	-- Destroy old grid
	if gridFrame then
		gridFrame:Destroy()
	end
	gridCells = nil

	-- Recreate with new dimensions
	MergeUI.CreateGrid()
end

-- ============================================================================
-- DISPLAY UPDATE LOOP (smooth coin counter)
-- ============================================================================

function MergeUI.StartDisplayLoop()
	RunService.RenderStepped:Connect(function(dt)
		-- Smooth coin counter
		displayedCoins = displayedCoins + (currentCoins - displayedCoins) * math.min(1, dt * 5)

		if coinsLabel then
			coinsLabel.Text = GameConfig.FormatNumber(math.floor(displayedCoins)) .. " Coins"
		end

		if earningsLabel then
			if coinsPerSec > 0 then
				earningsLabel.Text = "+" .. GameConfig.FormatNumber(coinsPerSec) .. "/sec"
				earningsLabel.TextColor3 = THEME.SuccessColor
			else
				earningsLabel.Text = "+0/sec"
				earningsLabel.TextColor3 = THEME.TextSecondary
			end
		end
	end)
end

-- ============================================================================
-- SELL ITEM (double-tap or long press)
-- ============================================================================

local lastTapTime = 0
local lastTapRow = 0
local lastTapCol = 0

function MergeUI.HandleCellTap(row, col)
	local now = tick()
	if row == lastTapRow and col == lastTapCol and now - lastTapTime < 0.4 then
		-- Double tap - sell item
		local key = row .. "_" .. col
		if localGrid[key] then
			remoteEvents.SellItem:FireServer(row, col)
		end
		lastTapTime = 0
	else
		lastTapTime = now
		lastTapRow = row
		lastTapCol = col
	end
end

-- ============================================================================
-- START
-- ============================================================================

MergeUI.Init()

return MergeUI
