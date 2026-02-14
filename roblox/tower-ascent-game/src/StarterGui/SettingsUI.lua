--[[
	SettingsUI.lua
	Game settings menu

	Features:
	- Press 'ESC' or 'P' to toggle settings
	- Volume controls (Master, SFX, Music)
	- Slider UI elements
	- Saves settings to DataService
	- Real-time audio feedback
	- Settings:
	  * Master Volume (0-100%)
	  * SFX Volume (0-100%)
	  * Music Volume (0-100%)
	  * Show Tutorial (On/Off)
	  * [Future: Graphics quality, keybinds]

	Week 4: Full implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- STATE
-- ============================================================================

local isSettingsOpen = false

local settings = {
	MasterVolume = 0.5,
	SFXVolume = 0.7,
	MusicVolume = 0.3,
	ShowTutorial = true,
}

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.5
background.BorderSizePixel = 0
background.Visible = false
background.Parent = screenGui

-- Settings Frame (center)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
settingsFrame.Size = UDim2.new(0, 500, 0, 500)
settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = settingsFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(150, 150, 150)
stroke.Thickness = 3
stroke.Parent = settingsFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 28
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "⚙️ SETTINGS ⚙️"
titleLabel.Parent = settingsFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "✕"
closeButton.Parent = settingsFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Settings Container
local settingsContainer = Instance.new("ScrollingFrame")
settingsContainer.Name = "SettingsContainer"
settingsContainer.Position = UDim2.new(0, 20, 0, 80)
settingsContainer.Size = UDim2.new(1, -40, 1, -100)
settingsContainer.BackgroundTransparency = 1
settingsContainer.BorderSizePixel = 0
settingsContainer.ScrollBarThickness = 8
settingsContainer.Parent = settingsFrame

local containerLayout = Instance.new("UIListLayout")
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
containerLayout.Padding = UDim.new(0, 20)
containerLayout.Parent = settingsContainer

-- ============================================================================
-- CREATE SLIDER
-- ============================================================================

local function createSlider(name: string, label: string, initialValue: number, layoutOrder: number, callback: (number) -> ())
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = name .. "Slider"
	sliderFrame.Size = UDim2.new(1, 0, 0, 80)
	sliderFrame.BackgroundTransparency = 1
	sliderFrame.LayoutOrder = layoutOrder
	sliderFrame.Parent = settingsContainer

	-- Label
	local sliderLabel = Instance.new("TextLabel")
	sliderLabel.Size = UDim2.new(1, 0, 0, 25)
	sliderLabel.BackgroundTransparency = 1
	sliderLabel.Font = Enum.Font.GothamBold
	sliderLabel.TextSize = 18
	sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
	sliderLabel.Text = label
	sliderLabel.Parent = sliderFrame

	-- Value Label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Position = UDim2.new(1, -60, 0, 0)
	valueLabel.Size = UDim2.new(0, 60, 0, 25)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 18
	valueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = string.format("%d%%", math.floor(initialValue * 100))
	valueLabel.Parent = sliderFrame

	-- Slider Track
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "Track"
	sliderTrack.Position = UDim2.new(0, 0, 0, 35)
	sliderTrack.Size = UDim2.new(1, 0, 0, 8)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Parent = sliderFrame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 4)
	trackCorner.Parent = sliderTrack

	-- Slider Fill
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "Fill"
	sliderFill.Size = UDim2.new(initialValue, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = sliderFill

	-- Slider Thumb
	local sliderThumb = Instance.new("Frame")
	sliderThumb.Name = "Thumb"
	sliderThumb.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderThumb.Position = UDim2.new(initialValue, 0, 0.5, 0)
	sliderThumb.Size = UDim2.new(0, 20, 0, 20)
	sliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderThumb.BorderSizePixel = 0
	sliderThumb.Parent = sliderTrack

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = sliderThumb

	-- Slider logic
	local dragging = false

	local function updateSlider(input)
		local trackSize = sliderTrack.AbsoluteSize.X
		local trackPos = sliderTrack.AbsolutePosition.X
		local mouseX = input.Position.X

		local relativeX = math.clamp(mouseX - trackPos, 0, trackSize)
		local value = relativeX / trackSize

		-- Update UI
		sliderFill.Size = UDim2.new(value, 0, 1, 0)
		sliderThumb.Position = UDim2.new(value, 0, 0.5, 0)
		valueLabel.Text = string.format("%d%%", math.floor(value * 100))

		-- Callback
		callback(value)

		return value
	end

	sliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateSlider(input)
		end
	end)

	sliderTrack.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		                 input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)

	sliderTrack.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return sliderFrame
end

-- ============================================================================
-- CREATE TOGGLE
-- ============================================================================

local function createToggle(name: string, label: string, initialValue: boolean, layoutOrder: number, callback: (boolean) -> ())
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = name .. "Toggle"
	toggleFrame.Size = UDim2.new(1, 0, 0, 50)
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.LayoutOrder = layoutOrder
	toggleFrame.Parent = settingsContainer

	-- Label
	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Font = Enum.Font.GothamBold
	toggleLabel.TextSize = 18
	toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Text = label
	toggleLabel.Parent = toggleFrame

	-- Toggle Button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.AnchorPoint = Vector2.new(1, 0.5)
	toggleButton.Position = UDim2.new(1, 0, 0.5, 0)
	toggleButton.Size = UDim2.new(0, 80, 0, 35)
	toggleButton.BackgroundColor3 = initialValue and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
	toggleButton.BorderSizePixel = 0
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 16
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.Text = initialValue and "ON" or "OFF"
	toggleButton.Parent = toggleFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = toggleButton

	-- Toggle logic
	local currentValue = initialValue

	toggleButton.MouseButton1Click:Connect(function()
		currentValue = not currentValue

		-- Update UI
		toggleButton.Text = currentValue and "ON" or "OFF"
		toggleButton.BackgroundColor3 = currentValue and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)

		-- Callback
		callback(currentValue)
	end)

	return toggleFrame
end

-- ============================================================================
-- SETTINGS CALLBACKS
-- ============================================================================

local function saveSetting(settingName: string, value: any)
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 2)
	if remoteFolder then
		local setSettingRemote = remoteFolder:FindFirstChild("SetSetting")
		if setSettingRemote then
			pcall(function()
				setSettingRemote:InvokeServer(settingName, value)
			end)
		end
	end
end

local function onMasterVolumeChanged(value: number)
	settings.MasterVolume = value

	-- Update SoundHandler
	if _G.SoundHandler then
		_G.SoundHandler.SetMasterVolume(value)
	end
end

local function onSFXVolumeChanged(value: number)
	settings.SFXVolume = value
	saveSetting("SFXVolume", value)

	-- Update SoundHandler
	if _G.SoundHandler then
		_G.SoundHandler.SetSFXVolume(value)
	end
end

local function onMusicVolumeChanged(value: number)
	settings.MusicVolume = value
	saveSetting("MusicVolume", value)

	-- Update SoundHandler
	if _G.SoundHandler then
		_G.SoundHandler.SetMusicVolume(value)
	end
end

local function onShowTutorialChanged(value: boolean)
	settings.ShowTutorial = value
	saveSetting("ShowTutorial", value)
end

-- ============================================================================
-- SETTINGS TOGGLE
-- ============================================================================

local function openSettings()
	isSettingsOpen = true
	background.Visible = true
	settingsFrame.Visible = true

	print("[SettingsUI] Settings opened")
end

local function closeSettings()
	isSettingsOpen = false
	background.Visible = false
	settingsFrame.Visible = false

	print("[SettingsUI] Settings closed")
end

local function toggleSettings()
	if isSettingsOpen then
		closeSettings()
	else
		openSettings()
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Don't open settings if other UIs are open
	if gameProcessed and input.KeyCode ~= Enum.KeyCode.Escape then
		return
	end

	if input.KeyCode == Enum.KeyCode.P or
	   (input.KeyCode == Enum.KeyCode.Escape and not isSettingsOpen) then
		toggleSettings()
	elseif input.KeyCode == Enum.KeyCode.Escape and isSettingsOpen then
		closeSettings()
	end
end)

-- Close button
closeButton.MouseButton1Click:Connect(closeSettings)

-- Background click to close
background.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closeSettings()
	end
end)

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Create settings
createSlider("MasterVolume", "🔊 Master Volume", settings.MasterVolume, 1, onMasterVolumeChanged)
createSlider("SFXVolume", "🎵 Sound Effects", settings.SFXVolume, 2, onSFXVolumeChanged)
createSlider("MusicVolume", "🎶 Music", settings.MusicVolume, 3, onMusicVolumeChanged)
createToggle("ShowTutorial", "📖 Show Tutorial", settings.ShowTutorial, 4, onShowTutorialChanged)

-- Update canvas size
settingsContainer.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 20)
containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	settingsContainer.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 20)
end)

-- Load saved settings from DataService
task.spawn(function()
	task.wait(2) -- Wait for remotes to initialize

	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
	if not remoteFolder then return end

	local getSettingRemote = remoteFolder:FindFirstChild("GetSetting")
	if not getSettingRemote then return end

	-- Load each setting
	local settingsToLoad = {"MusicVolume", "SFXVolume", "ShowTutorial"}
	for _, settingName in ipairs(settingsToLoad) do
		local success, value = pcall(function()
			return getSettingRemote:InvokeServer(settingName)
		end)
		if success and value ~= nil then
			settings[settingName] = value
		end
	end

	print("[SettingsUI] Settings loaded from DataService")
end)

print("[SettingsUI] Initialized (Press 'P' or 'ESC' to open)")
