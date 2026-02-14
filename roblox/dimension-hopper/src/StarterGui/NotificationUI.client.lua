--[[
	NotificationUI.client.lua
	Displays in-game notifications

	Features:
	- Toast notifications from the right
	- Queue system for multiple notifications
	- Different styles for different types
	- Server announcements (center banner)
	- Sound effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[NotificationUI] RemoteEvents not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MAX_VISIBLE_NOTIFICATIONS = 5
local NOTIFICATION_WIDTH = 300
local NOTIFICATION_HEIGHT = 70
local NOTIFICATION_PADDING = 10
local NOTIFICATION_START_X = 320 -- Off screen

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 200 -- Above most UI
screenGui.Parent = playerGui

-- Notification container (right side)
local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "NotificationContainer"
notificationContainer.AnchorPoint = Vector2.new(1, 0)
notificationContainer.Position = UDim2.new(1, -10, 0, 10)
notificationContainer.Size = UDim2.new(0, NOTIFICATION_WIDTH, 1, -20)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

-- Server announcement banner (top center)
local announcementBanner = Instance.new("Frame")
announcementBanner.Name = "AnnouncementBanner"
announcementBanner.AnchorPoint = Vector2.new(0.5, 0)
announcementBanner.Position = UDim2.new(0.5, 0, 0, -100) -- Hidden above
announcementBanner.Size = UDim2.new(0, 500, 0, 80)
announcementBanner.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
announcementBanner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 10)
bannerCorner.Parent = announcementBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(255, 100, 150)
bannerStroke.Thickness = 2
bannerStroke.Parent = announcementBanner

local bannerIcon = Instance.new("TextLabel")
bannerIcon.Name = "Icon"
bannerIcon.Position = UDim2.new(0, 15, 0.5, -15)
bannerIcon.Size = UDim2.new(0, 30, 0, 30)
bannerIcon.BackgroundTransparency = 1
bannerIcon.Font = Enum.Font.GothamBold
bannerIcon.TextSize = 24
bannerIcon.TextColor3 = Color3.fromRGB(255, 100, 150)
bannerIcon.Text = "📢"
bannerIcon.Parent = announcementBanner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Name = "Title"
bannerTitle.Position = UDim2.new(0, 55, 0, 12)
bannerTitle.Size = UDim2.new(1, -70, 0, 25)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBold
bannerTitle.TextSize = 18
bannerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerTitle.Text = "Announcement"
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
bannerTitle.Parent = announcementBanner

local bannerMessage = Instance.new("TextLabel")
bannerMessage.Name = "Message"
bannerMessage.Position = UDim2.new(0, 55, 0, 38)
bannerMessage.Size = UDim2.new(1, -70, 0, 30)
bannerMessage.BackgroundTransparency = 1
bannerMessage.Font = Enum.Font.Gotham
bannerMessage.TextSize = 14
bannerMessage.TextColor3 = Color3.fromRGB(180, 180, 200)
bannerMessage.Text = ""
bannerMessage.TextXAlignment = Enum.TextXAlignment.Left
bannerMessage.TextWrapped = true
bannerMessage.Parent = announcementBanner

-- ============================================================================
-- STATE
-- ============================================================================

local notificationQueue = {}
local activeNotifications = {}
local isProcessingQueue = false

-- ============================================================================
-- NOTIFICATION CREATION
-- ============================================================================

local function CreateNotification(data): Frame
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(1, 0, 0, NOTIFICATION_HEIGHT)
	notification.Position = UDim2.new(0, NOTIFICATION_START_X, 0, 0) -- Start off screen
	notification.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	notification.Parent = notificationContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = data.color or Color3.fromRGB(80, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = notification

	-- Icon background
	local iconBg = Instance.new("Frame")
	iconBg.Position = UDim2.new(0, 10, 0.5, -20)
	iconBg.Size = UDim2.new(0, 40, 0, 40)
	iconBg.BackgroundColor3 = data.color or Color3.fromRGB(80, 150, 255)
	iconBg.Parent = notification

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBg

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 20
	iconLabel.TextColor3 = Color3.fromRGB(30, 30, 45)
	iconLabel.Text = data.icon or "i"
	iconLabel.Parent = iconBg

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.new(0, 60, 0, 10)
	titleLabel.Size = UDim2.new(1, -70, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = data.title or "Notification"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = notification

	-- Message
	if data.message then
		local messageLabel = Instance.new("TextLabel")
		messageLabel.Position = UDim2.new(0, 60, 0, 32)
		messageLabel.Size = UDim2.new(1, -70, 0, 28)
		messageLabel.BackgroundTransparency = 1
		messageLabel.Font = Enum.Font.Gotham
		messageLabel.TextSize = 12
		messageLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
		messageLabel.Text = data.message
		messageLabel.TextXAlignment = Enum.TextXAlignment.Left
		messageLabel.TextWrapped = true
		messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
		messageLabel.Parent = notification
	end

	-- Store data
	notification:SetAttribute("Duration", data.duration or 4)
	notification:SetAttribute("Priority", data.priority or 2)

	return notification
end

-- ============================================================================
-- NOTIFICATION MANAGEMENT
-- ============================================================================

local function RepositionNotifications()
	local yOffset = 0

	for i, notif in ipairs(activeNotifications) do
		if notif and notif.Parent then
			TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = UDim2.new(0, 0, 0, yOffset)
			}):Play()

			yOffset = yOffset + NOTIFICATION_HEIGHT + NOTIFICATION_PADDING
		end
	end
end

local function ShowNotification(data)
	-- Check if we have room
	while #activeNotifications >= MAX_VISIBLE_NOTIFICATIONS do
		local oldest = table.remove(activeNotifications, 1)
		if oldest and oldest.Parent then
			-- Slide out quickly
			TweenService:Create(oldest, TweenInfo.new(0.2), {
				Position = UDim2.new(0, NOTIFICATION_START_X, 0, oldest.Position.Y.Offset)
			}):Play()
			task.delay(0.2, function()
				if oldest.Parent then
					oldest:Destroy()
				end
			end)
		end
	end

	local notification = CreateNotification(data)
	table.insert(activeNotifications, notification)

	-- Calculate Y position
	local yOffset = 0
	for i, notif in ipairs(activeNotifications) do
		if notif == notification then
			break
		end
		yOffset = yOffset + NOTIFICATION_HEIGHT + NOTIFICATION_PADDING
	end

	notification.Position = UDim2.new(0, NOTIFICATION_START_X, 0, yOffset)

	-- Slide in
	TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0, 0, 0, yOffset)
	}):Play()

	-- Play sound
	if data.sound then
		-- Play sound effect
	end

	-- Auto-dismiss
	local duration = data.duration or 4
	task.delay(duration, function()
		if notification and notification.Parent then
			-- Remove from active
			for i, notif in ipairs(activeNotifications) do
				if notif == notification then
					table.remove(activeNotifications, i)
					break
				end
			end

			-- Slide out
			TweenService:Create(notification, TweenInfo.new(0.2), {
				Position = UDim2.new(0, NOTIFICATION_START_X, 0, notification.Position.Y.Offset)
			}):Play()

			task.delay(0.2, function()
				if notification.Parent then
					notification:Destroy()
				end
			end)

			-- Reposition remaining
			task.delay(0.1, RepositionNotifications)
		end
	end)
end

local function ProcessQueue()
	if isProcessingQueue then return end
	if #notificationQueue == 0 then return end

	isProcessingQueue = true

	while #notificationQueue > 0 do
		-- Sort by priority
		table.sort(notificationQueue, function(a, b)
			return (a.priority or 2) > (b.priority or 2)
		end)

		local data = table.remove(notificationQueue, 1)
		ShowNotification(data)

		-- Small delay between notifications
		task.wait(0.15)
	end

	isProcessingQueue = false
end

local function QueueNotification(data)
	table.insert(notificationQueue, data)
	task.spawn(ProcessQueue)
end

-- ============================================================================
-- SERVER ANNOUNCEMENT
-- ============================================================================

local function ShowAnnouncement(data)
	bannerTitle.Text = data.title or "Announcement"
	bannerMessage.Text = data.message or ""

	-- Slide down
	TweenService:Create(announcementBanner, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Auto-hide
	local duration = data.duration or 8
	task.delay(duration, function()
		TweenService:Create(announcementBanner, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, -100)
		}):Play()
	end)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local showNotification = RemoteEvents:FindFirstChild("ShowNotification")
if showNotification then
	showNotification.OnClientEvent:Connect(function(data)
		QueueNotification(data)
	end)
end

local serverAnnouncement = RemoteEvents:FindFirstChild("ServerAnnouncement")
if serverAnnouncement then
	serverAnnouncement.OnClientEvent:Connect(function(data)
		ShowAnnouncement(data)
	end)
end

-- ============================================================================
-- LOCAL NOTIFICATION API (for client-side notifications)
-- ============================================================================

local NotificationUI = {}

function NotificationUI.Show(notificationType: string, title: string, message: string?, options: table?)
	options = options or {}

	local typeConfigs = {
		info = { color = Color3.fromRGB(80, 150, 255), icon = "i" },
		success = { color = Color3.fromRGB(80, 200, 80), icon = "✓" },
		warning = { color = Color3.fromRGB(255, 180, 50), icon = "!" },
		error = { color = Color3.fromRGB(220, 80, 80), icon = "✕" },
	}

	local config = typeConfigs[notificationType] or typeConfigs.info

	QueueNotification({
		title = title,
		message = message,
		icon = options.icon or config.icon,
		color = options.color or config.color,
		duration = options.duration or 4,
		priority = options.priority or 2,
	})
end

function NotificationUI.Info(title: string, message: string?)
	NotificationUI.Show("info", title, message)
end

function NotificationUI.Success(title: string, message: string?)
	NotificationUI.Show("success", title, message)
end

function NotificationUI.Warning(title: string, message: string?)
	NotificationUI.Show("warning", title, message)
end

function NotificationUI.Error(title: string, message: string?)
	NotificationUI.Show("error", title, message)
end

-- Make available globally for other client scripts
_G.NotificationUI = NotificationUI

print("[NotificationUI] Initialized")
