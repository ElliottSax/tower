--[[
	TrailsUI.client.lua
	Trail selection and customization interface

	Features:
	- Browse available trails
	- Equip trails
	- Show unlock requirements
	- Preview trails
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[TrailsUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TrailsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main panel
local trailsPanel = Instance.new("Frame")
trailsPanel.Name = "TrailsPanel"
trailsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
trailsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
trailsPanel.Size = UDim2.new(0, 450, 0, 380)
trailsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
trailsPanel.Visible = false
trailsPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = trailsPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(100, 80, 200)
panelStroke.Thickness = 2
panelStroke.Parent = trailsPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
header.Parent = trailsPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 15)
headerFix.Position = UDim2.new(0, 0, 1, -15)
headerFix.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 15, 0, 0)
title.Size = UDim2.new(1, -60, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Trails"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.BackgroundTransparency = 1
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Parent = header

-- Currently equipped
local equippedSection = Instance.new("Frame")
equippedSection.Position = UDim2.new(0, 15, 0, 60)
equippedSection.Size = UDim2.new(1, -30, 0, 60)
equippedSection.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
equippedSection.Parent = trailsPanel

local equippedCorner = Instance.new("UICorner")
equippedCorner.CornerRadius = UDim.new(0, 8)
equippedCorner.Parent = equippedSection

local equippedLabel = Instance.new("TextLabel")
equippedLabel.Position = UDim2.new(0, 10, 0, 5)
equippedLabel.Size = UDim2.new(1, -20, 0, 18)
equippedLabel.BackgroundTransparency = 1
equippedLabel.Font = Enum.Font.Gotham
equippedLabel.TextSize = 11
equippedLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
equippedLabel.Text = "CURRENTLY EQUIPPED"
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.Parent = equippedSection

local equippedPreview = Instance.new("Frame")
equippedPreview.Position = UDim2.new(0, 10, 0, 25)
equippedPreview.Size = UDim2.new(0, 40, 0, 25)
equippedPreview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
equippedPreview.Parent = equippedSection

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 4)
previewCorner.Parent = equippedPreview

-- Gradient for preview
local previewGradient = Instance.new("UIGradient")
previewGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
previewGradient.Parent = equippedPreview

local equippedName = Instance.new("TextLabel")
equippedName.Name = "EquippedName"
equippedName.Position = UDim2.new(0, 60, 0, 25)
equippedName.Size = UDim2.new(1, -70, 0, 25)
equippedName.BackgroundTransparency = 1
equippedName.Font = Enum.Font.GothamBold
equippedName.TextSize = 14
equippedName.TextColor3 = Color3.fromRGB(255, 255, 255)
equippedName.Text = "Basic Trail"
equippedName.TextXAlignment = Enum.TextXAlignment.Left
equippedName.Parent = equippedSection

-- Trails grid
local trailsScroll = Instance.new("ScrollingFrame")
trailsScroll.Position = UDim2.new(0, 15, 0, 130)
trailsScroll.Size = UDim2.new(1, -30, 1, -145)
trailsScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
trailsScroll.ScrollBarThickness = 6
trailsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
trailsScroll.Parent = trailsPanel

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = trailsScroll

local trailsGrid = Instance.new("UIGridLayout")
trailsGrid.CellSize = UDim2.new(0, 95, 0, 100)
trailsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
trailsGrid.Parent = trailsScroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingAll = UDim.new(0, 10)
scrollPadding.Parent = trailsScroll

-- ============================================================================
-- STATE
-- ============================================================================

local trailData = { unlocked = {}, locked = {}, equipped = "default" }

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetTrailsRemote()
	return RemoteEvents:FindFirstChild("GetTrails")
end

local function GetEquipRemote()
	return RemoteEvents:FindFirstChild("EquipTrail")
end

local function RefreshTrailData()
	local remote = GetTrailsRemote()
	if remote then
		local data = remote:InvokeServer()
		if data then
			trailData = data
		end
	end
end

local function CreateTrailCard(trail, isUnlocked: boolean): Frame
	local card = Instance.new("Frame")
	card.Name = trail.id
	card.BackgroundColor3 = isUnlocked and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(30, 30, 45)

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local isEquipped = trail.id == trailData.equipped

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = isEquipped and Color3.fromRGB(80, 200, 80) or (isUnlocked and Color3.fromRGB(100, 80, 200) or Color3.fromRGB(60, 60, 80))
	cardStroke.Thickness = isEquipped and 3 or 2
	cardStroke.Parent = card

	-- Trail preview
	local preview = Instance.new("Frame")
	preview.Position = UDim2.new(0.5, -30, 0, 10)
	preview.Size = UDim2.new(0, 60, 0, 25)
	preview.BackgroundColor3 = trail.color or Color3.fromRGB(255, 255, 255)
	preview.Parent = card

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = preview

	if not isUnlocked then
		preview.BackgroundTransparency = 0.5
	end

	-- Name
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 5, 0, 40)
	name.Size = UDim2.new(1, -10, 0, 18)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 11
	name.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 140)
	name.Text = trail.name
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	if isUnlocked then
		-- Equip button
		local equipBtn = Instance.new("TextButton")
		equipBtn.Position = UDim2.new(0.5, -35, 1, -30)
		equipBtn.Size = UDim2.new(0, 70, 0, 22)
		equipBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(80, 200, 80)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 10
		equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Text = isEquipped and "Equipped" or "Equip"
		equipBtn.Parent = card

		local equipCorner = Instance.new("UICorner")
		equipCorner.CornerRadius = UDim.new(0, 4)
		equipCorner.Parent = equipBtn

		if not isEquipped then
			equipBtn.MouseButton1Click:Connect(function()
				local remote = GetEquipRemote()
				if remote then
					remote:FireServer(trail.id)
					trailData.equipped = trail.id
					UpdateTrailsDisplay()
					UpdateEquippedDisplay()
				end
			end)
		end
	else
		-- Unlock requirement
		local reqLabel = Instance.new("TextLabel")
		reqLabel.Position = UDim2.new(0, 5, 1, -30)
		reqLabel.Size = UDim2.new(1, -10, 0, 25)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Font = Enum.Font.Gotham
		reqLabel.TextSize = 9
		reqLabel.TextColor3 = Color3.fromRGB(150, 100, 100)
		reqLabel.TextWrapped = true
		reqLabel.Parent = card

		if trail.unlockMethod == "level" then
			reqLabel.Text = "Level " .. trail.unlockRequirement
		elseif trail.unlockMethod == "achievement" then
			reqLabel.Text = "Achievement"
		elseif trail.unlockMethod == "dimension" then
			reqLabel.Text = trail.unlockRequirement .. " Dimension"
		elseif trail.unlockMethod == "shop" then
			reqLabel.Text = trail.unlockRequirement .. " Coins"
		else
			reqLabel.Text = "Locked"
		end
	end

	return card
end

local function UpdateEquippedDisplay()
	-- Find equipped trail
	local equippedTrail = nil
	for _, trail in ipairs(trailData.unlocked) do
		if trail.id == trailData.equipped then
			equippedTrail = trail
			break
		end
	end

	if equippedTrail then
		equippedName.Text = equippedTrail.name
		equippedPreview.BackgroundColor3 = equippedTrail.color or Color3.fromRGB(255, 255, 255)
	else
		equippedName.Text = "Basic Trail"
		equippedPreview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function UpdateTrailsDisplay()
	-- Clear existing
	for _, child in ipairs(trailsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add unlocked trails first
	for _, trail in ipairs(trailData.unlocked) do
		local card = CreateTrailCard(trail, true)
		card.Parent = trailsScroll
	end

	-- Add locked trails
	for _, trail in ipairs(trailData.locked) do
		local card = CreateTrailCard(trail, false)
		card.Parent = trailsScroll
	end
end

local function ShowPanel()
	RefreshTrailData()
	UpdateEquippedDisplay()
	UpdateTrailsDisplay()
	trailsPanel.Visible = true
end

local function HidePanel()
	trailsPanel.Visible = false
end

local function TogglePanel()
	if trailsPanel.Visible then
		HidePanel()
	else
		ShowPanel()
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

closeButton.MouseButton1Click:Connect(HidePanel)

-- Make accessible globally (can be opened from shop/cosmetics)
_G.TrailsUI = {
	Show = ShowPanel,
	Hide = HidePanel,
	Toggle = TogglePanel,
}

print("[TrailsUI] Initialized")
