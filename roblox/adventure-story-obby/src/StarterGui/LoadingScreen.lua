--[[
	LoadingScreen.lua
	Loading screen for level transitions and initial game load

	Features:
	- Smooth fade in/out
	- Loading text animation
	- Progress bar (optional)
	- Custom messages
	- Prevents player input during load
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LoadingScreen = {}
LoadingScreen.IsLoading = false

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local FADE_SPEED = 0.5 -- seconds
local DOT_ANIMATION_SPEED = 0.5 -- seconds per dot

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function LoadingScreen.Init()
	print("[LoadingScreen] Initializing...")

	-- Create loading UI
	LoadingScreen.CreateUI()

	-- Connect to remote events
	LoadingScreen.ConnectRemotes()

	-- Remove default loading screen
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	print("[LoadingScreen] Initialized")
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

function LoadingScreen.CreateUI()
	-- Create ScreenGui
	LoadingScreen.ScreenGui = Instance.new("ScreenGui")
	LoadingScreen.ScreenGui.Name = "LoadingScreen"
	LoadingScreen.ScreenGui.ResetOnSpawn = false
	LoadingScreen.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	LoadingScreen.ScreenGui.DisplayOrder = 100 -- On top of everything
	LoadingScreen.ScreenGui.Enabled = false
	LoadingScreen.ScreenGui.Parent = playerGui

	-- Background frame
	LoadingScreen.Background = Instance.new("Frame")
	LoadingScreen.Background.Name = "Background"
	LoadingScreen.Background.Size = UDim2.new(1, 0, 1, 0)
	LoadingScreen.Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	LoadingScreen.Background.BackgroundTransparency = 1
	LoadingScreen.Background.BorderSizePixel = 0
	LoadingScreen.Background.Parent = LoadingScreen.ScreenGui

	-- Loading text
	LoadingScreen.LoadingText = Instance.new("TextLabel")
	LoadingScreen.LoadingText.Name = "LoadingText"
	LoadingScreen.LoadingText.Size = UDim2.new(0, 400, 0, 50)
	LoadingScreen.LoadingText.Position = UDim2.new(0.5, -200, 0.5, -25)
	LoadingScreen.LoadingText.BackgroundTransparency = 1
	LoadingScreen.LoadingText.Text = "Loading"
	LoadingScreen.LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
	LoadingScreen.LoadingText.TextSize = 36
	LoadingScreen.LoadingText.Font = Enum.Font.SourceSansBold
	LoadingScreen.LoadingText.TextTransparency = 1
	LoadingScreen.LoadingText.Parent = LoadingScreen.Background

	-- Subtitle text
	LoadingScreen.SubtitleText = Instance.new("TextLabel")
	LoadingScreen.SubtitleText.Name = "SubtitleText"
	LoadingScreen.SubtitleText.Size = UDim2.new(0, 600, 0, 30)
	LoadingScreen.SubtitleText.Position = UDim2.new(0.5, -300, 0.5, 40)
	LoadingScreen.SubtitleText.BackgroundTransparency = 1
	LoadingScreen.SubtitleText.Text = ""
	LoadingScreen.SubtitleText.TextColor3 = Color3.fromRGB(200, 200, 200)
	LoadingScreen.SubtitleText.TextSize = 20
	LoadingScreen.SubtitleText.Font = Enum.Font.SourceSans
	LoadingScreen.SubtitleText.TextTransparency = 1
	LoadingScreen.SubtitleText.Parent = LoadingScreen.Background

	-- Spinning loader icon
	LoadingScreen.Spinner = Instance.new("ImageLabel")
	LoadingScreen.Spinner.Name = "Spinner"
	LoadingScreen.Spinner.Size = UDim2.new(0, 50, 0, 50)
	LoadingScreen.Spinner.Position = UDim2.new(0.5, -25, 0.5, -100)
	LoadingScreen.Spinner.BackgroundTransparency = 1
	LoadingScreen.Spinner.Image = "rbxasset://textures/loading/robloxTilt.png"
	LoadingScreen.Spinner.ImageTransparency = 1
	LoadingScreen.Spinner.Parent = LoadingScreen.Background

	-- Progress bar (optional)
	LoadingScreen.ProgressBarBg = Instance.new("Frame")
	LoadingScreen.ProgressBarBg.Name = "ProgressBarBg"
	LoadingScreen.ProgressBarBg.Size = UDim2.new(0, 400, 0, 6)
	LoadingScreen.ProgressBarBg.Position = UDim2.new(0.5, -200, 0.5, 80)
	LoadingScreen.ProgressBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	LoadingScreen.ProgressBarBg.BackgroundTransparency = 1
	LoadingScreen.ProgressBarBg.BorderSizePixel = 0
	LoadingScreen.ProgressBarBg.Parent = LoadingScreen.Background

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = LoadingScreen.ProgressBarBg

	LoadingScreen.ProgressBar = Instance.new("Frame")
	LoadingScreen.ProgressBar.Name = "ProgressBar"
	LoadingScreen.ProgressBar.Size = UDim2.new(0, 0, 1, 0)
	LoadingScreen.ProgressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	LoadingScreen.ProgressBar.BorderSizePixel = 0
	LoadingScreen.ProgressBar.Parent = LoadingScreen.ProgressBarBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 3)
	barCorner.Parent = LoadingScreen.ProgressBar
end

-- ============================================================================
-- LOADING CONTROL
-- ============================================================================

function LoadingScreen.Show(message: string?, subtitle: string?)
	if LoadingScreen.IsLoading then return end
	LoadingScreen.IsLoading = true

	-- Set messages
	LoadingScreen.LoadingText.Text = message or "Loading"
	LoadingScreen.SubtitleText.Text = subtitle or ""

	-- Enable GUI
	LoadingScreen.ScreenGui.Enabled = true

	-- Fade in
	TweenService:Create(
		LoadingScreen.Background,
		TweenInfo.new(FADE_SPEED),
		{BackgroundTransparency = 0.3}
	):Play()

	TweenService:Create(
		LoadingScreen.LoadingText,
		TweenInfo.new(FADE_SPEED),
		{TextTransparency = 0}
	):Play()

	TweenService:Create(
		LoadingScreen.SubtitleText,
		TweenInfo.new(FADE_SPEED),
		{TextTransparency = 0}
	):Play()

	TweenService:Create(
		LoadingScreen.Spinner,
		TweenInfo.new(FADE_SPEED),
		{ImageTransparency = 0}
	):Play()

	TweenService:Create(
		LoadingScreen.ProgressBarBg,
		TweenInfo.new(FADE_SPEED),
		{BackgroundTransparency = 0}
	):Play()

	-- Start animations
	LoadingScreen.StartDotAnimation()
	LoadingScreen.StartSpinAnimation()
end

function LoadingScreen.Hide()
	if not LoadingScreen.IsLoading then return end

	-- Stop animations
	LoadingScreen.StopDotAnimation()
	LoadingScreen.StopSpinAnimation()

	-- Fade out
	TweenService:Create(
		LoadingScreen.Background,
		TweenInfo.new(FADE_SPEED),
		{BackgroundTransparency = 1}
	):Play()

	TweenService:Create(
		LoadingScreen.LoadingText,
		TweenInfo.new(FADE_SPEED),
		{TextTransparency = 1}
	):Play()

	TweenService:Create(
		LoadingScreen.SubtitleText,
		TweenInfo.new(FADE_SPEED),
		{TextTransparency = 1}
	):Play()

	TweenService:Create(
		LoadingScreen.Spinner,
		TweenInfo.new(FADE_SPEED),
		{ImageTransparency = 1}
	):Play()

	local hideTween = TweenService:Create(
		LoadingScreen.ProgressBarBg,
		TweenInfo.new(FADE_SPEED),
		{BackgroundTransparency = 1}
	)
	hideTween:Play()

	hideTween.Completed:Connect(function()
		LoadingScreen.ScreenGui.Enabled = false
		LoadingScreen.IsLoading = false
	end)
end

function LoadingScreen.UpdateProgress(progress: number)
	-- Progress should be 0-1
	progress = math.clamp(progress, 0, 1)

	TweenService:Create(
		LoadingScreen.ProgressBar,
		TweenInfo.new(0.3),
		{Size = UDim2.new(progress, 0, 1, 0)}
	):Play()
end

-- ============================================================================
-- ANIMATIONS
-- ============================================================================

LoadingScreen.DotAnimationThread = nil

function LoadingScreen.StartDotAnimation()
	LoadingScreen.DotAnimationThread = task.spawn(function()
		local baseText = LoadingScreen.LoadingText.Text:gsub("%.+$", "")
		local dots = 0

		while LoadingScreen.IsLoading do
			dots = (dots % 3) + 1
			LoadingScreen.LoadingText.Text = baseText .. string.rep(".", dots)
			task.wait(DOT_ANIMATION_SPEED)
		end
	end)
end

function LoadingScreen.StopDotAnimation()
	if LoadingScreen.DotAnimationThread then
		task.cancel(LoadingScreen.DotAnimationThread)
		LoadingScreen.DotAnimationThread = nil
	end
end

LoadingScreen.SpinAnimationThread = nil

function LoadingScreen.StartSpinAnimation()
	LoadingScreen.SpinAnimationThread = task.spawn(function()
		while LoadingScreen.IsLoading do
			for rotation = 0, 360, 5 do
				if not LoadingScreen.IsLoading then break end
				LoadingScreen.Spinner.Rotation = rotation
				task.wait(0.01)
			end
		end
	end)
end

function LoadingScreen.StopSpinAnimation()
	if LoadingScreen.SpinAnimationThread then
		task.cancel(LoadingScreen.SpinAnimationThread)
		LoadingScreen.SpinAnimationThread = nil
	end
end

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

function LoadingScreen.ConnectRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then return end

	-- Show loading screen
	local showLoadingRemote = remoteEvents:FindFirstChild("ShowLoadingScreen")
	if showLoadingRemote then
		showLoadingRemote.OnClientEvent:Connect(function(message, subtitle)
			LoadingScreen.Show(message, subtitle)
		end)
	end

	-- Hide loading screen
	local hideLoadingRemote = remoteEvents:FindFirstChild("HideLoadingScreen")
	if hideLoadingRemote then
		hideLoadingRemote.OnClientEvent:Connect(function()
			LoadingScreen.Hide()
		end)
	end

	-- Update progress
	local updateProgressRemote = remoteEvents:FindFirstChild("UpdateLoadingProgress")
	if updateProgressRemote then
		updateProgressRemote.OnClientEvent:Connect(function(progress)
			LoadingScreen.UpdateProgress(progress)
		end)
	end
end

-- ============================================================================
-- INITIAL LOAD
-- ============================================================================

function LoadingScreen.InitialLoad()
	-- Show loading on game start
	LoadingScreen.Show("Loading Adventure Story Obby", "Preparing your adventure...")

	-- Wait for game to load
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- Wait a moment for assets
	task.wait(1)

	-- Hide loading screen
	LoadingScreen.Hide()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
LoadingScreen.Init()

-- Show initial loading
task.defer(function()
	LoadingScreen.InitialLoad()
end)

-- Expose globally
_G.LoadingScreen = LoadingScreen

return LoadingScreen
