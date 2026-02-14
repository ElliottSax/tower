--[[
	NotificationUI.lua
	Universal notification system for player feedback

	Features:
	- Success notifications (green)
	- Error notifications (red)
	- Info notifications (blue)
	- Warning notifications (yellow)
	- Slide-in animation
	- Auto-dismiss after delay
	- Queue system for multiple notifications
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationUI = {}
NotificationUI.NotificationQueue = {}
NotificationUI.ActiveNotification = nil

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local NOTIFICATION_DURATION = 3 -- seconds
local ANIMATION_SPEED = 0.3 -- seconds

local NotificationTypes = {
	Success = {
		Color = Color3.fromRGB(100, 255, 100),
		Icon = "✓",
	},
	Error = {
		Color = Color3.fromRGB(255, 100, 100),
		Icon = "✗",
	},
	Info = {
		Color = Color3.fromRGB(100, 150, 255),
		Icon = "ℹ",
	},
	Warning = {
		Color = Color3.fromRGB(255, 200, 100),
		Icon = "⚠",
	},
	Coin = {
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "💰",
	},
	Quest = {
		Color = Color3.fromRGB(150, 100, 255),
		Icon = "📜",
	},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function NotificationUI.Init()
	print("[NotificationUI] Initializing...")

	-- Create container
	NotificationUI.CreateContainer()

	-- Start processing queue
	NotificationUI.ProcessQueue()

	print("[NotificationUI] Initialized")
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

function NotificationUI.CreateContainer()
	-- Container for notifications (top-center)
	NotificationUI.Container = Instance.new("ScreenGui")
	NotificationUI.Container.Name = "NotificationUI"
	NotificationUI.Container.ResetOnSpawn = false
	NotificationUI.Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	NotificationUI.Container.DisplayOrder = 10 -- Above most UI
	NotificationUI.Container.Parent = playerGui
end

-- ============================================================================
-- NOTIFICATION DISPLAY
-- ============================================================================

function NotificationUI.Show(message: string, notificationType: string?)
	notificationType = notificationType or "Info"

	-- Add to queue
	table.insert(NotificationUI.NotificationQueue, {
		Message = message,
		Type = notificationType,
	})
end

function NotificationUI.ProcessQueue()
	task.spawn(function()
		while true do
			-- Wait if there's an active notification
			if NotificationUI.ActiveNotification then
				task.wait(0.1)
				continue
			end

			-- Check if queue has notifications
			if #NotificationUI.NotificationQueue == 0 then
				task.wait(0.1)
				continue
			end

			-- Get next notification
			local notification = table.remove(NotificationUI.NotificationQueue, 1)

			-- Show it
			NotificationUI.DisplayNotification(notification)

			-- Wait for it to finish
			task.wait(NOTIFICATION_DURATION + ANIMATION_SPEED * 2)
		end
	end)
end

function NotificationUI.DisplayNotification(notification)
	local typeConfig = NotificationTypes[notification.Type] or NotificationTypes.Info

	-- Create notification frame
	local frame = Instance.new("Frame")
	frame.Name = "Notification"
	frame.Size = UDim2.new(0, 400, 0, 60)
	frame.Position = UDim2.new(0.5, -200, 0, -70) -- Start above screen
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = NotificationUI.Container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	-- Colored bar on left
	local colorBar = Instance.new("Frame")
	colorBar.Size = UDim2.new(0, 5, 1, 0)
	colorBar.BackgroundColor3 = typeConfig.Color
	colorBar.BorderSizePixel = 0
	colorBar.Parent = frame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = colorBar

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 1, 0)
	icon.Position = UDim2.new(0, 10, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = typeConfig.Icon
	icon.TextColor3 = typeConfig.Color
	icon.TextSize = 30
	icon.Font = Enum.Font.SourceSansBold
	icon.Parent = frame

	-- Message text
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -70, 1, 0)
	text.Position = UDim2.new(0, 60, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = notification.Message
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 18
	text.Font = Enum.Font.SourceSans
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextWrapped = true
	text.Parent = frame

	NotificationUI.ActiveNotification = frame

	-- Animate in
	local slideIn = TweenService:Create(
		frame,
		TweenInfo.new(ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0, 20)}
	)
	slideIn:Play()

	-- Wait
	task.wait(NOTIFICATION_DURATION)

	-- Animate out
	local slideOut = TweenService:Create(
		frame,
		TweenInfo.new(ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -200, 0, -70)}
	)
	slideOut:Play()
	slideOut.Completed:Connect(function()
		frame:Destroy()
		NotificationUI.ActiveNotification = nil
	end)
end

-- ============================================================================
-- CONVENIENCE FUNCTIONS
-- ============================================================================

function NotificationUI.Success(message: string)
	NotificationUI.Show(message, "Success")
end

function NotificationUI.Error(message: string)
	NotificationUI.Show(message, "Error")
end

function NotificationUI.Info(message: string)
	NotificationUI.Show(message, "Info")
end

function NotificationUI.Warning(message: string)
	NotificationUI.Show(message, "Warning")
end

function NotificationUI.Coin(message: string)
	NotificationUI.Show(message, "Coin")
end

function NotificationUI.Quest(message: string)
	NotificationUI.Show(message, "Quest")
end

-- ============================================================================
-- REMOTE LISTENING
-- ============================================================================

function NotificationUI.ConnectRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then return end

	-- Listen for server notifications
	local notificationRemote = remoteEvents:FindFirstChild("ShowNotification")
	if notificationRemote then
		notificationRemote.OnClientEvent:Connect(function(message, notificationType)
			NotificationUI.Show(message, notificationType)
		end)
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
NotificationUI.Init()
NotificationUI.ConnectRemotes()

-- Expose globally for other scripts
_G.Notify = NotificationUI

-- Test notification (remove in production)
task.wait(2)
NotificationUI.Info("Notification system ready!")

return NotificationUI
