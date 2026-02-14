--[[
	EmoteUI.client.lua
	Emote wheel and management interface

	Features:
	- Radial emote wheel (hold B)
	- Emote favorites
	- Emote browser
	- Unlock progress display
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[EmoteUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local WHEEL_RADIUS = 120
local WHEEL_SLOT_SIZE = 50
local WHEEL_SLOTS = 8

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EmoteUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Emote wheel (radial menu)
local emoteWheel = Instance.new("Frame")
emoteWheel.Name = "EmoteWheel"
emoteWheel.AnchorPoint = Vector2.new(0.5, 0.5)
emoteWheel.Position = UDim2.new(0.5, 0, 0.5, 0)
emoteWheel.Size = UDim2.new(0, WHEEL_RADIUS * 2 + WHEEL_SLOT_SIZE, 0, WHEEL_RADIUS * 2 + WHEEL_SLOT_SIZE)
emoteWheel.BackgroundTransparency = 1
emoteWheel.Visible = false
emoteWheel.Parent = screenGui

-- Center indicator
local wheelCenter = Instance.new("Frame")
wheelCenter.Name = "Center"
wheelCenter.AnchorPoint = Vector2.new(0.5, 0.5)
wheelCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
wheelCenter.Size = UDim2.new(0, 60, 0, 60)
wheelCenter.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
wheelCenter.Parent = emoteWheel

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(1, 0)
centerCorner.Parent = wheelCenter

local centerStroke = Instance.new("UIStroke")
centerStroke.Color = Color3.fromRGB(100, 80, 200)
centerStroke.Thickness = 2
centerStroke.Parent = wheelCenter

local centerLabel = Instance.new("TextLabel")
centerLabel.Size = UDim2.new(1, 0, 1, 0)
centerLabel.BackgroundTransparency = 1
centerLabel.Font = Enum.Font.GothamBold
centerLabel.TextSize = 12
centerLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
centerLabel.Text = "Select"
centerLabel.Parent = wheelCenter

-- Create wheel slots
local wheelSlots = {}
for i = 1, WHEEL_SLOTS do
	local angle = (i - 1) * (360 / WHEEL_SLOTS) - 90 -- Start from top
	local radians = math.rad(angle)
	local x = math.cos(radians) * WHEEL_RADIUS
	local y = math.sin(radians) * WHEEL_RADIUS

	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.AnchorPoint = Vector2.new(0.5, 0.5)
	slot.Position = UDim2.new(0.5, x, 0.5, y)
	slot.Size = UDim2.new(0, WHEEL_SLOT_SIZE, 0, WHEEL_SLOT_SIZE)
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	slot.Parent = emoteWheel

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Name = "Stroke"
	slotStroke.Color = Color3.fromRGB(60, 60, 80)
	slotStroke.Thickness = 2
	slotStroke.Parent = slot

	local slotIcon = Instance.new("TextLabel")
	slotIcon.Name = "Icon"
	slotIcon.Size = UDim2.new(1, 0, 0.7, 0)
	slotIcon.BackgroundTransparency = 1
	slotIcon.Font = Enum.Font.GothamBold
	slotIcon.TextSize = 24
	slotIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	slotIcon.Text = ""
	slotIcon.Parent = slot

	local slotName = Instance.new("TextLabel")
	slotName.Name = "Name"
	slotName.Position = UDim2.new(0, 0, 0.65, 0)
	slotName.Size = UDim2.new(1, 0, 0.35, 0)
	slotName.BackgroundTransparency = 1
	slotName.Font = Enum.Font.Gotham
	slotName.TextSize = 8
	slotName.TextColor3 = Color3.fromRGB(180, 180, 200)
	slotName.Text = ""
	slotName.TextTruncate = Enum.TextTruncate.AtEnd
	slotName.Parent = slot

	wheelSlots[i] = {
		frame = slot,
		angle = angle,
		emoteId = nil,
	}
end

-- Emote browser panel
local browserPanel = Instance.new("Frame")
browserPanel.Name = "BrowserPanel"
browserPanel.AnchorPoint = Vector2.new(0.5, 0.5)
browserPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
browserPanel.Size = UDim2.new(0, 450, 0, 400)
browserPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
browserPanel.Visible = false
browserPanel.Parent = screenGui

local browserCorner = Instance.new("UICorner")
browserCorner.CornerRadius = UDim.new(0, 12)
browserCorner.Parent = browserPanel

local browserStroke = Instance.new("UIStroke")
browserStroke.Color = Color3.fromRGB(100, 80, 200)
browserStroke.Thickness = 2
browserStroke.Parent = browserPanel

-- Browser header
local browserHeader = Instance.new("Frame")
browserHeader.Size = UDim2.new(1, 0, 0, 50)
browserHeader.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
browserHeader.Parent = browserPanel

local browserHeaderCorner = Instance.new("UICorner")
browserHeaderCorner.CornerRadius = UDim.new(0, 12)
browserHeaderCorner.Parent = browserHeader

local browserHeaderFix = Instance.new("Frame")
browserHeaderFix.Size = UDim2.new(1, 0, 0, 15)
browserHeaderFix.Position = UDim2.new(0, 0, 1, -15)
browserHeaderFix.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
browserHeaderFix.BorderSizePixel = 0
browserHeaderFix.Parent = browserHeader

local browserTitle = Instance.new("TextLabel")
browserTitle.Position = UDim2.new(0, 15, 0, 0)
browserTitle.Size = UDim2.new(1, -60, 1, 0)
browserTitle.BackgroundTransparency = 1
browserTitle.Font = Enum.Font.GothamBold
browserTitle.TextSize = 20
browserTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
browserTitle.Text = "Emotes"
browserTitle.TextXAlignment = Enum.TextXAlignment.Left
browserTitle.Parent = browserHeader

local browserClose = Instance.new("TextButton")
browserClose.AnchorPoint = Vector2.new(1, 0.5)
browserClose.Position = UDim2.new(1, -10, 0.5, 0)
browserClose.Size = UDim2.new(0, 35, 0, 35)
browserClose.BackgroundTransparency = 1
browserClose.Font = Enum.Font.GothamBold
browserClose.TextSize = 24
browserClose.TextColor3 = Color3.fromRGB(255, 255, 255)
browserClose.Text = "X"
browserClose.Parent = browserHeader

-- Category tabs
local categoryTabs = Instance.new("Frame")
categoryTabs.Position = UDim2.new(0, 10, 0, 55)
categoryTabs.Size = UDim2.new(1, -20, 0, 35)
categoryTabs.BackgroundTransparency = 1
categoryTabs.Parent = browserPanel

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 5)
tabsLayout.Parent = categoryTabs

local categories = { "All", "Greetings", "Reactions", "Dances", "Victory", "Dimension" }
local categoryButtons = {}

for _, category in ipairs(categories) do
	local btn = Instance.new("TextButton")
	btn.Name = category
	btn.Size = UDim2.new(0, 65, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.fromRGB(180, 180, 200)
	btn.Text = category
	btn.Parent = categoryTabs

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	categoryButtons[category] = btn
end

-- Emotes grid
local emotesScroll = Instance.new("ScrollingFrame")
emotesScroll.Position = UDim2.new(0, 10, 0, 100)
emotesScroll.Size = UDim2.new(1, -20, 1, -160)
emotesScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
emotesScroll.ScrollBarThickness = 6
emotesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
emotesScroll.Parent = browserPanel

local emotesCorner = Instance.new("UICorner")
emotesCorner.CornerRadius = UDim.new(0, 8)
emotesCorner.Parent = emotesScroll

local emotesGrid = Instance.new("UIGridLayout")
emotesGrid.CellSize = UDim2.new(0, 80, 0, 90)
emotesGrid.CellPadding = UDim2.new(0, 10, 0, 10)
emotesGrid.Parent = emotesScroll

local emotesPadding = Instance.new("UIPadding")
emotesPadding.PaddingAll = UDim.new(0, 10)
emotesPadding.Parent = emotesScroll

-- Favorites section
local favoritesLabel = Instance.new("TextLabel")
favoritesLabel.Position = UDim2.new(0, 15, 1, -50)
favoritesLabel.Size = UDim2.new(0, 80, 0, 20)
favoritesLabel.BackgroundTransparency = 1
favoritesLabel.Font = Enum.Font.GothamBold
favoritesLabel.TextSize = 12
favoritesLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
favoritesLabel.Text = "Favorites:"
favoritesLabel.TextXAlignment = Enum.TextXAlignment.Left
favoritesLabel.Parent = browserPanel

local favoritesContainer = Instance.new("Frame")
favoritesContainer.Position = UDim2.new(0, 95, 1, -50)
favoritesContainer.Size = UDim2.new(1, -110, 0, 40)
favoritesContainer.BackgroundTransparency = 1
favoritesContainer.Parent = browserPanel

local favoritesLayout = Instance.new("UIListLayout")
favoritesLayout.FillDirection = Enum.FillDirection.Horizontal
favoritesLayout.Padding = UDim.new(0, 5)
favoritesLayout.Parent = favoritesContainer

-- Hint label
local hintLabel = Instance.new("TextLabel")
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -20)
hintLabel.Size = UDim2.new(0, 200, 0, 20)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 12
hintLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
hintLabel.Text = "Hold B for emote wheel"
hintLabel.Visible = false
hintLabel.Parent = screenGui

-- ============================================================================
-- STATE
-- ============================================================================

local emoteData = { unlocked = {}, locked = {}, favorites = {} }
local selectedCategory = "All"
local wheelActive = false
local selectedSlot = nil
local favorites = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetEmoteRemotes()
	return {
		PlayEmote = RemoteEvents:FindFirstChild("PlayEmote"),
		StopEmote = RemoteEvents:FindFirstChild("StopEmote"),
		GetEmotes = RemoteEvents:FindFirstChild("GetEmotes"),
		SetEmoteFavorites = RemoteEvents:FindFirstChild("SetEmoteFavorites"),
	}
end

local function RefreshEmoteData()
	local remotes = GetEmoteRemotes()
	if remotes.GetEmotes then
		local data = remotes.GetEmotes:InvokeServer()
		if data then
			emoteData = data
			favorites = data.favorites or {}
		end
	end
end

local function PlayEmote(emoteId: string)
	local remotes = GetEmoteRemotes()
	if remotes.PlayEmote then
		remotes.PlayEmote:FireServer(emoteId)
	end
end

local function StopEmote()
	local remotes = GetEmoteRemotes()
	if remotes.StopEmote then
		remotes.StopEmote:FireServer()
	end
end

local function SaveFavorites()
	local remotes = GetEmoteRemotes()
	if remotes.SetEmoteFavorites then
		remotes.SetEmoteFavorites:FireServer(favorites)
	end
end

local function ToggleFavorite(emoteId: string)
	-- Check if already favorite
	for i, fav in ipairs(favorites) do
		if fav == emoteId then
			table.remove(favorites, i)
			SaveFavorites()
			return
		end
	end

	-- Add if under limit
	if #favorites < 8 then
		table.insert(favorites, emoteId)
		SaveFavorites()
	end
end

local function IsFavorite(emoteId: string): boolean
	for _, fav in ipairs(favorites) do
		if fav == emoteId then
			return true
		end
	end
	return false
end

local function UpdateWheelSlots()
	-- Fill wheel slots with favorites
	for i, slot in ipairs(wheelSlots) do
		local emoteId = favorites[i]
		local emote = nil

		-- Find emote data
		if emoteId then
			for _, e in ipairs(emoteData.unlocked) do
				if e.id == emoteId then
					emote = e
					break
				end
			end
		end

		slot.emoteId = emoteId

		if emote then
			slot.frame.Icon.Text = emote.icon or "?"
			slot.frame.Name.Text = emote.name or ""
			slot.frame.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
		else
			slot.frame.Icon.Text = "+"
			slot.frame.Name.Text = "Empty"
			slot.frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		end
	end
end

local function CreateEmoteCard(emote, isUnlocked: boolean): Frame
	local card = Instance.new("Frame")
	card.Name = emote.id
	card.BackgroundColor3 = isUnlocked and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(30, 30, 45)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isUnlocked and Color3.fromRGB(100, 80, 200) or Color3.fromRGB(60, 60, 80)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Position = UDim2.new(0, 0, 0, 5)
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 28
	icon.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
	icon.Text = emote.icon or "?"
	icon.Parent = card

	-- Name
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 0, 0, 45)
	name.Size = UDim2.new(1, 0, 0, 20)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 10
	name.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
	name.Text = emote.name
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	-- Favorite star (for unlocked)
	if isUnlocked then
		local favStar = Instance.new("TextButton")
		favStar.AnchorPoint = Vector2.new(1, 0)
		favStar.Position = UDim2.new(1, -2, 0, 2)
		favStar.Size = UDim2.new(0, 20, 0, 20)
		favStar.BackgroundTransparency = 1
		favStar.Font = Enum.Font.GothamBold
		favStar.TextSize = 14
		favStar.TextColor3 = IsFavorite(emote.id) and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(80, 80, 100)
		favStar.Text = "star"
		favStar.Parent = card

		favStar.MouseButton1Click:Connect(function()
			ToggleFavorite(emote.id)
			favStar.TextColor3 = IsFavorite(emote.id) and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(80, 80, 100)
			UpdateWheelSlots()
			UpdateFavoritesDisplay()
		end)

		-- Click to play
		local playButton = Instance.new("TextButton")
		playButton.Size = UDim2.new(1, 0, 0, 20)
		playButton.Position = UDim2.new(0, 0, 1, -22)
		playButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
		playButton.Font = Enum.Font.GothamBold
		playButton.TextSize = 10
		playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		playButton.Text = "Play"
		playButton.Parent = card

		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 4)
		playCorner.Parent = playButton

		playButton.MouseButton1Click:Connect(function()
			PlayEmote(emote.id)
		end)
	else
		-- Unlock requirement
		local reqLabel = Instance.new("TextLabel")
		reqLabel.Position = UDim2.new(0, 2, 1, -22)
		reqLabel.Size = UDim2.new(1, -4, 0, 20)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Font = Enum.Font.Gotham
		reqLabel.TextSize = 8
		reqLabel.TextColor3 = Color3.fromRGB(150, 100, 100)
		reqLabel.TextWrapped = true
		reqLabel.Parent = card

		if emote.unlockMethod == "level" then
			reqLabel.Text = "Lvl " .. emote.unlockRequirement
		elseif emote.unlockMethod == "achievement" then
			reqLabel.Text = "Achievement"
		elseif emote.unlockMethod == "shop" then
			reqLabel.Text = emote.unlockRequirement .. " Coins"
		elseif emote.unlockMethod == "dimension" then
			reqLabel.Text = emote.unlockRequirement .. " Dim"
		end
	end

	return card
end

local function UpdateEmotesDisplay()
	-- Clear existing
	for _, child in ipairs(emotesScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add unlocked emotes
	for _, emote in ipairs(emoteData.unlocked) do
		if selectedCategory == "All" or emote.category == selectedCategory then
			local card = CreateEmoteCard(emote, true)
			card.Parent = emotesScroll
		end
	end

	-- Add locked emotes
	for _, emote in ipairs(emoteData.locked) do
		if selectedCategory == "All" or emote.category == selectedCategory then
			local card = CreateEmoteCard(emote, false)
			card.Parent = emotesScroll
		end
	end
end

local function UpdateFavoritesDisplay()
	-- Clear existing
	for _, child in ipairs(favoritesContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add favorite slots
	for i = 1, 8 do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.new(0, 35, 0, 35)
		slot.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		slot.Parent = favoritesContainer

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slot

		local emoteId = favorites[i]
		if emoteId then
			-- Find emote
			for _, emote in ipairs(emoteData.unlocked) do
				if emote.id == emoteId then
					local icon = Instance.new("TextLabel")
					icon.Size = UDim2.new(1, 0, 1, 0)
					icon.BackgroundTransparency = 1
					icon.Font = Enum.Font.GothamBold
					icon.TextSize = 18
					icon.TextColor3 = Color3.fromRGB(255, 255, 255)
					icon.Text = emote.icon or "?"
					icon.Parent = slot
					break
				end
			end
		else
			local plus = Instance.new("TextLabel")
			plus.Size = UDim2.new(1, 0, 1, 0)
			plus.BackgroundTransparency = 1
			plus.Font = Enum.Font.GothamBold
			plus.TextSize = 18
			plus.TextColor3 = Color3.fromRGB(80, 80, 100)
			plus.Text = "+"
			plus.Parent = slot
		end
	end
end

local function SelectCategory(category: string)
	selectedCategory = category

	-- Update button appearances
	for cat, btn in pairs(categoryButtons) do
		if cat == category then
			btn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			btn.TextColor3 = Color3.fromRGB(180, 180, 200)
		end
	end

	UpdateEmotesDisplay()
end

local function ShowWheel()
	wheelActive = true
	emoteWheel.Visible = true
	UpdateWheelSlots()
end

local function HideWheel()
	wheelActive = false
	emoteWheel.Visible = false

	-- Play selected emote
	if selectedSlot and selectedSlot.emoteId then
		PlayEmote(selectedSlot.emoteId)
	end

	selectedSlot = nil
end

local function UpdateWheelSelection()
	if not wheelActive then return end

	local mousePos = UserInputService:GetMouseLocation()
	local wheelCenter = emoteWheel.AbsolutePosition + emoteWheel.AbsoluteSize / 2
	local delta = mousePos - wheelCenter
	local distance = delta.Magnitude

	-- Only select if far enough from center
	if distance < 40 then
		selectedSlot = nil
		centerLabel.Text = "Select"

		for _, slot in ipairs(wheelSlots) do
			slot.frame.Stroke.Color = Color3.fromRGB(60, 60, 80)
			slot.frame.Size = UDim2.new(0, WHEEL_SLOT_SIZE, 0, WHEEL_SLOT_SIZE)
		end
		return
	end

	-- Calculate angle
	local angle = math.deg(math.atan2(delta.Y, delta.X))

	-- Find closest slot
	local closestSlot = nil
	local closestDiff = 999

	for _, slot in ipairs(wheelSlots) do
		local diff = math.abs(angle - slot.angle)
		if diff > 180 then
			diff = 360 - diff
		end

		if diff < closestDiff then
			closestDiff = diff
			closestSlot = slot
		end
	end

	-- Update visuals
	for _, slot in ipairs(wheelSlots) do
		if slot == closestSlot then
			slot.frame.Stroke.Color = Color3.fromRGB(100, 80, 200)
			TweenService:Create(slot.frame, TweenInfo.new(0.1), {
				Size = UDim2.new(0, WHEEL_SLOT_SIZE + 10, 0, WHEEL_SLOT_SIZE + 10)
			}):Play()
		else
			slot.frame.Stroke.Color = Color3.fromRGB(60, 60, 80)
			TweenService:Create(slot.frame, TweenInfo.new(0.1), {
				Size = UDim2.new(0, WHEEL_SLOT_SIZE, 0, WHEEL_SLOT_SIZE)
			}):Play()
		end
	end

	selectedSlot = closestSlot

	-- Update center label
	if closestSlot and closestSlot.emoteId then
		for _, emote in ipairs(emoteData.unlocked) do
			if emote.id == closestSlot.emoteId then
				centerLabel.Text = emote.name
				break
			end
		end
	else
		centerLabel.Text = "Empty"
	end
end

local function ShowBrowser()
	RefreshEmoteData()
	SelectCategory("All")
	UpdateFavoritesDisplay()
	browserPanel.Visible = true
end

local function HideBrowser()
	browserPanel.Visible = false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Category buttons
for category, btn in pairs(categoryButtons) do
	btn.MouseButton1Click:Connect(function()
		SelectCategory(category)
	end)
end

browserClose.MouseButton1Click:Connect(HideBrowser)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			-- Shift+B opens browser
			if browserPanel.Visible then
				HideBrowser()
			else
				ShowBrowser()
			end
		else
			-- B alone shows wheel
			RefreshEmoteData()
			ShowWheel()
		end
	elseif input.KeyCode == Enum.KeyCode.X then
		StopEmote()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.B then
		HideWheel()
	end
end)

-- Update wheel selection each frame
RunService.RenderStepped:Connect(UpdateWheelSelection)

-- Emote played broadcast
local emotePlayed = RemoteEvents:FindFirstChild("EmotePlayed")
if emotePlayed then
	emotePlayed.OnClientEvent:Connect(function(userId, emoteId, icon)
		-- Show indicator above player
		local emotingPlayer = Players:GetPlayerByUserId(userId)
		if emotingPlayer and emotingPlayer.Character then
			local head = emotingPlayer.Character:FindFirstChild("Head")
			if head then
				-- Create floating icon
				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.new(0, 50, 0, 50)
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				billboard.Adornee = head
				billboard.Parent = head

				local iconLabel = Instance.new("TextLabel")
				iconLabel.Size = UDim2.new(1, 0, 1, 0)
				iconLabel.BackgroundTransparency = 1
				iconLabel.Font = Enum.Font.GothamBold
				iconLabel.TextSize = 30
				iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				iconLabel.Text = icon or "?"
				iconLabel.Parent = billboard

				-- Fade out
				task.delay(2, function()
					TweenService:Create(iconLabel, TweenInfo.new(0.5), {
						TextTransparency = 1
					}):Play()
					task.wait(0.5)
					billboard:Destroy()
				end)
			end
		end
	end)
end

-- Initial load
task.spawn(function()
	task.wait(1)
	RefreshEmoteData()
	UpdateWheelSlots()
	hintLabel.Visible = true
end)

print("[EmoteUI] Initialized - Hold B for wheel, Shift+B for browser, X to stop")
