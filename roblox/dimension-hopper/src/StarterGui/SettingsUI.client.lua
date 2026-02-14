--[[
	SettingsUI.client.lua
	Client UI for game settings

	Features:
	- Audio volume controls (Music, SFX)
	- Graphics quality toggle
	- Sensitivity settings
	- Control hints toggle
	- Reset to defaults
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- DEFAULT SETTINGS
-- ============================================================================

local DEFAULT_SETTINGS = {
	musicVolume = 0.5,
	sfxVolume = 0.7,
	graphicsQuality = "Auto", -- "Low", "Medium", "High", "Auto"
	sensitivity = 0.5,
	showControlHints = true,
	screenShake = true,
	showFPS = false,
}

local currentSettings = {}

-- Load from player or use defaults
for key, value in pairs(DEFAULT_SETTINGS) do
	currentSettings[key] = value
end

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Settings button (gear icon)
local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.AnchorPoint = Vector2.new(1, 0)
settingsButton.Position = UDim2.new(1, -20, 0, 270)
settingsButton.Size = UDim2.new(0, 50, 0, 50)
settingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
settingsButton.Font = Enum.Font.GothamBold
settingsButton.TextSize = 22
settingsButton.TextColor3 = Color3.fromRGB(180, 180, 200)
settingsButton.Text = "⚙"
settingsButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = settingsButton

-- Settings panel
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 450, 0, 500)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(80, 80, 120)
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.new(0, 20, 0, 15)
titleLabel.Size = UDim2.new(0.5, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Settings"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = panel

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -15, 0, 12)
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Settings container
local container = Instance.new("ScrollingFrame")
container.Name = "Container"
container.Position = UDim2.new(0, 15, 0, 60)
container.Size = UDim2.new(1, -30, 1, -120)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 0)
container.ScrollBarThickness = 6
container.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
container.Parent = panel

local containerLayout = Instance.new("UIListLayout")
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
containerLayout.Padding = UDim.new(0, 10)
containerLayout.Parent = container

-- Reset button
local resetButton = Instance.new("TextButton")
resetButton.Name = "Reset"
resetButton.AnchorPoint = Vector2.new(0.5, 1)
resetButton.Position = UDim2.new(0.5, 0, 1, -15)
resetButton.Size = UDim2.new(0, 150, 0, 40)
resetButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 14
resetButton.TextColor3 = Color3.fromRGB(200, 200, 220)
resetButton.Text = "Reset to Defaults"
resetButton.Parent = panel

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetButton

-- ============================================================================
-- SETTING COMPONENTS
-- ============================================================================

local function CreateSectionHeader(name: string, layoutOrder: number): Frame
	local header = Instance.new("Frame")
	header.Name = name .. "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.LayoutOrder = layoutOrder
	header.BackgroundTransparency = 1
	header.Parent = container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(150, 150, 200)
	label.Text = string.upper(name)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	return header
end

local function CreateSlider(name: string, displayName: string, layoutOrder: number, min: number, max: number, default: number, onChange: (number) -> ()): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.LayoutOrder = layoutOrder
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0, 15, 0, 5)
	label.Size = UDim2.new(0.5, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = displayName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, -15, 0, 5)
	valueLabel.Size = UDim2.new(0, 50, 0, 20)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
	valueLabel.Text = tostring(math.floor(default * 100)) .. "%"
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame

	local sliderBg = Instance.new("Frame")
	sliderBg.Name = "SliderBg"
	sliderBg.Position = UDim2.new(0, 15, 0, 30)
	sliderBg.Size = UDim2.new(1, -30, 0, 10)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sliderBg.Parent = frame

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 5)
	sliderCorner.Parent = sliderBg

	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "Fill"
	sliderFill.Size = UDim2.new(default, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
	sliderFill.Parent = sliderBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = sliderFill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(default, 0, 0.5, 0)
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Parent = sliderBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	-- Slider interaction
	local dragging = false

	local function UpdateSlider(value: number)
		value = math.clamp(value, min, max)
		local normalized = (value - min) / (max - min)

		sliderFill.Size = UDim2.new(normalized, 0, 1, 0)
		knob.Position = UDim2.new(normalized, 0, 0.5, 0)
		valueLabel.Text = tostring(math.floor(value * 100)) .. "%"

		onChange(value)
	end

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local pos = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
			UpdateSlider(min + pos * (max - min))
		end
	end)

	sliderBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local pos = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
			UpdateSlider(min + pos * (max - min))
		end
	end)

	frame.UpdateValue = function(value)
		UpdateSlider(value)
	end

	return frame
end

local function CreateToggle(name: string, displayName: string, layoutOrder: number, default: boolean, onChange: (boolean) -> ()): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 0, 45)
	frame.LayoutOrder = layoutOrder
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0, 15, 0, 0)
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = displayName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.AnchorPoint = Vector2.new(1, 0.5)
	toggleBg.Position = UDim2.new(1, -15, 0.5, 0)
	toggleBg.Size = UDim2.new(0, 50, 0, 26)
	toggleBg.BackgroundColor3 = default and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(80, 80, 90)
	toggleBg.Parent = frame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 13)
	toggleCorner.Parent = toggleBg

	local toggleKnob = Instance.new("Frame")
	toggleKnob.Name = "Knob"
	toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
	toggleKnob.Position = default and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	toggleKnob.Size = UDim2.new(0, 22, 0, 22)
	toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleKnob.Parent = toggleBg

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = toggleKnob

	local enabled = default

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(1, 0, 1, 0)
	toggleButton.BackgroundTransparency = 1
	toggleButton.Text = ""
	toggleButton.Parent = toggleBg

	toggleButton.MouseButton1Click:Connect(function()
		enabled = not enabled

		TweenService:Create(toggleBg, TweenInfo.new(0.2), {
			BackgroundColor3 = enabled and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(80, 80, 90)
		}):Play()

		TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Position = enabled and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		}):Play()

		onChange(enabled)
	end)

	frame.UpdateValue = function(value)
		enabled = value
		toggleBg.BackgroundColor3 = enabled and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(80, 80, 90)
		toggleKnob.Position = enabled and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	end

	return frame
end

local function CreateDropdown(name: string, displayName: string, layoutOrder: number, options: {string}, default: string, onChange: (string) -> ()): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 0, 45)
	frame.LayoutOrder = layoutOrder
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0, 15, 0, 0)
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = displayName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local dropdownButton = Instance.new("TextButton")
	dropdownButton.Name = "Dropdown"
	dropdownButton.AnchorPoint = Vector2.new(1, 0.5)
	dropdownButton.Position = UDim2.new(1, -15, 0.5, 0)
	dropdownButton.Size = UDim2.new(0, 120, 0, 30)
	dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	dropdownButton.Font = Enum.Font.Gotham
	dropdownButton.TextSize = 13
	dropdownButton.TextColor3 = Color3.fromRGB(200, 200, 220)
	dropdownButton.Text = default .. " ▼"
	dropdownButton.Parent = frame

	local dropCorner = Instance.new("UICorner")
	dropCorner.CornerRadius = UDim.new(0, 6)
	dropCorner.Parent = dropdownButton

	local currentIndex = table.find(options, default) or 1

	dropdownButton.MouseButton1Click:Connect(function()
		currentIndex = (currentIndex % #options) + 1
		local selected = options[currentIndex]
		dropdownButton.Text = selected .. " ▼"
		onChange(selected)
	end)

	frame.UpdateValue = function(value)
		currentIndex = table.find(options, value) or 1
		dropdownButton.Text = value .. " ▼"
	end

	return frame
end

-- ============================================================================
-- CREATE SETTINGS
-- ============================================================================

local settingElements = {}

-- Audio section
CreateSectionHeader("Audio", 1)

settingElements.musicVolume = CreateSlider("musicVolume", "Music Volume", 2, 0, 1, currentSettings.musicVolume, function(value)
	currentSettings.musicVolume = value
	-- Apply to SoundService
	local musicGroup = SoundService:FindFirstChild("Music")
	if musicGroup then
		musicGroup.Volume = value
	end
end)

settingElements.sfxVolume = CreateSlider("sfxVolume", "SFX Volume", 3, 0, 1, currentSettings.sfxVolume, function(value)
	currentSettings.sfxVolume = value
	local sfxGroup = SoundService:FindFirstChild("SFX")
	if sfxGroup then
		sfxGroup.Volume = value
	end
end)

-- Graphics section
CreateSectionHeader("Graphics", 10)

settingElements.graphicsQuality = CreateDropdown("graphicsQuality", "Graphics Quality", 11, {"Low", "Medium", "High", "Auto"}, currentSettings.graphicsQuality, function(value)
	currentSettings.graphicsQuality = value
	-- Apply graphics settings
	if value == "Low" then
		settings().Rendering.QualityLevel = 1
	elseif value == "Medium" then
		settings().Rendering.QualityLevel = 5
	elseif value == "High" then
		settings().Rendering.QualityLevel = 10
	else
		settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
	end
end)

settingElements.screenShake = CreateToggle("screenShake", "Screen Shake", 12, currentSettings.screenShake, function(value)
	currentSettings.screenShake = value
end)

-- Controls section
CreateSectionHeader("Controls", 20)

settingElements.sensitivity = CreateSlider("sensitivity", "Camera Sensitivity", 21, 0.1, 1, currentSettings.sensitivity, function(value)
	currentSettings.sensitivity = value
	UserInputService.MouseDeltaSensitivity = value * 2
end)

-- Interface section
CreateSectionHeader("Interface", 30)

settingElements.showControlHints = CreateToggle("showControlHints", "Show Control Hints", 31, currentSettings.showControlHints, function(value)
	currentSettings.showControlHints = value
end)

settingElements.showFPS = CreateToggle("showFPS", "Show FPS Counter", 32, currentSettings.showFPS, function(value)
	currentSettings.showFPS = value
	-- Toggle FPS display
end)

-- Update canvas size
container.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 10)

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function OpenSettings()
	panel.Visible = true
end

local function CloseSettings()
	panel.Visible = false
	-- Save settings
	-- Could save to DataStore via RemoteEvent
end

local function ResetToDefaults()
	for key, value in pairs(DEFAULT_SETTINGS) do
		currentSettings[key] = value
		if settingElements[key] and settingElements[key].UpdateValue then
			settingElements[key].UpdateValue(value)
		end
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

settingsButton.MouseButton1Click:Connect(OpenSettings)
closeButton.MouseButton1Click:Connect(CloseSettings)
resetButton.MouseButton1Click:Connect(ResetToDefaults)

-- ESC to close
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		CloseSettings()
	end
end)

-- Button hover effects
local buttons = {settingsButton, closeButton, resetButton}
for _, button in ipairs(buttons) do
	local originalColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.2)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

print("[SettingsUI] Initialized")
