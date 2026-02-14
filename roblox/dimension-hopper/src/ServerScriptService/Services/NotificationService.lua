--[[
	NotificationService.lua
	Manages in-game notifications for various events

	Features:
	- Queue-based notification system
	- Multiple notification types (info, success, warning, error)
	- Priority system
	- Sound integration
	- Server-wide announcements
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationService = {}

-- ============================================================================
-- NOTIFICATION TYPES
-- ============================================================================

NotificationService.Types = {
	INFO = {
		name = "info",
		color = Color3.fromRGB(80, 150, 255),
		icon = "i",
		duration = 4,
	},
	SUCCESS = {
		name = "success",
		color = Color3.fromRGB(80, 200, 80),
		icon = "✓",
		duration = 4,
	},
	WARNING = {
		name = "warning",
		color = Color3.fromRGB(255, 180, 50),
		icon = "!",
		duration = 5,
	},
	ERROR = {
		name = "error",
		color = Color3.fromRGB(220, 80, 80),
		icon = "✕",
		duration = 5,
	},
	ACHIEVEMENT = {
		name = "achievement",
		color = Color3.fromRGB(255, 215, 0),
		icon = "★",
		duration = 5,
	},
	PERSONAL_BEST = {
		name = "personal_best",
		color = Color3.fromRGB(150, 100, 255),
		icon = "⏱",
		duration = 5,
	},
	LEVEL_UP = {
		name = "level_up",
		color = Color3.fromRGB(100, 255, 200),
		icon = "↑",
		duration = 5,
	},
	FRIEND = {
		name = "friend",
		color = Color3.fromRGB(100, 200, 255),
		icon = "👤",
		duration = 4,
	},
	REWARD = {
		name = "reward",
		color = Color3.fromRGB(255, 200, 100),
		icon = "🎁",
		duration = 4,
	},
	ANNOUNCEMENT = {
		name = "announcement",
		color = Color3.fromRGB(255, 100, 150),
		icon = "📢",
		duration = 8,
	},
}

-- Priority levels (higher = more important, shown first)
NotificationService.Priority = {
	LOW = 1,
	NORMAL = 2,
	HIGH = 3,
	CRITICAL = 4,
}

-- ============================================================================
-- STATE
-- ============================================================================

-- Nothing server-side, all notifications sent to clients

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function NotificationService.Init()
	print("[NotificationService] Initializing...")

	NotificationService.CreateRemotes()

	-- Setup friend notifications
	NotificationService.SetupFriendNotifications()

	print("[NotificationService] Initialized")
end

function NotificationService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Send notification to client
	if not remoteFolder:FindFirstChild("ShowNotification") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ShowNotification"
		event.Parent = remoteFolder
	end

	-- Server announcement
	if not remoteFolder:FindFirstChild("ServerAnnouncement") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ServerAnnouncement"
		event.Parent = remoteFolder
	end

	NotificationService.Remotes = {
		ShowNotification = remoteFolder.ShowNotification,
		ServerAnnouncement = remoteFolder.ServerAnnouncement,
	}
end

-- ============================================================================
-- NOTIFICATION API
-- ============================================================================

function NotificationService.Send(player: Player, notificationType: string, title: string, message: string?, options: table?)
	options = options or {}

	local typeConfig = NotificationService.Types[string.upper(notificationType)]
	if not typeConfig then
		typeConfig = NotificationService.Types.INFO
	end

	local notification = {
		type = typeConfig.name,
		title = title,
		message = message,
		icon = options.icon or typeConfig.icon,
		color = options.color or typeConfig.color,
		duration = options.duration or typeConfig.duration,
		priority = options.priority or NotificationService.Priority.NORMAL,
		sound = options.sound,
		data = options.data,
	}

	NotificationService.Remotes.ShowNotification:FireClient(player, notification)
end

function NotificationService.SendToAll(notificationType: string, title: string, message: string?, options: table?)
	for _, player in ipairs(Players:GetPlayers()) do
		NotificationService.Send(player, notificationType, title, message, options)
	end
end

function NotificationService.Announce(title: string, message: string?, duration: number?)
	local announcement = {
		title = title,
		message = message,
		duration = duration or 8,
	}

	NotificationService.Remotes.ServerAnnouncement:FireAllClients(announcement)
end

-- ============================================================================
-- CONVENIENCE METHODS
-- ============================================================================

function NotificationService.Info(player: Player, title: string, message: string?)
	NotificationService.Send(player, "INFO", title, message)
end

function NotificationService.Success(player: Player, title: string, message: string?)
	NotificationService.Send(player, "SUCCESS", title, message)
end

function NotificationService.Warning(player: Player, title: string, message: string?)
	NotificationService.Send(player, "WARNING", title, message)
end

function NotificationService.Error(player: Player, title: string, message: string?)
	NotificationService.Send(player, "ERROR", title, message)
end

function NotificationService.Achievement(player: Player, achievementName: string, xpReward: number?)
	NotificationService.Send(player, "ACHIEVEMENT", "Achievement Unlocked!", achievementName, {
		priority = NotificationService.Priority.HIGH,
		data = { xp = xpReward },
	})
end

function NotificationService.PersonalBest(player: Player, dimension: string, time: number, improvement: number?)
	local message = string.format("%.2fs", time)
	if improvement then
		message = message .. string.format(" (%.2fs faster!)", improvement)
	end

	NotificationService.Send(player, "PERSONAL_BEST", "New Personal Best!", message, {
		priority = NotificationService.Priority.HIGH,
		data = { dimension = dimension, time = time },
	})
end

function NotificationService.LevelUp(player: Player, newLevel: number, rewards: table?)
	local message = "Level " .. tostring(newLevel)

	NotificationService.Send(player, "LEVEL_UP", "Level Up!", message, {
		priority = NotificationService.Priority.HIGH,
		data = { level = newLevel, rewards = rewards },
	})
end

function NotificationService.Reward(player: Player, rewardType: string, amount: number)
	NotificationService.Send(player, "REWARD", rewardType, "+" .. tostring(amount), {
		data = { type = rewardType, amount = amount },
	})
end

function NotificationService.FriendJoined(player: Player, friendName: string)
	NotificationService.Send(player, "FRIEND", "Friend Joined", friendName .. " is now playing!")
end

function NotificationService.FriendFinished(player: Player, friendName: string, placement: number, time: number)
	local ordinal = placement == 1 and "1st" or placement == 2 and "2nd" or placement == 3 and "3rd" or tostring(placement) .. "th"
	NotificationService.Send(player, "FRIEND", friendName .. " Finished",
		ordinal .. " place - " .. string.format("%.2fs", time))
end

-- ============================================================================
-- FRIEND NOTIFICATIONS
-- ============================================================================

function NotificationService.SetupFriendNotifications()
	Players.PlayerAdded:Connect(function(newPlayer)
		-- Notify friends that this player joined
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= newPlayer then
				-- Check if they're friends (simplified - in production use FriendsService)
				local success, areFriends = pcall(function()
					return player:IsFriendsWith(newPlayer.UserId)
				end)

				if success and areFriends then
					NotificationService.FriendJoined(player, newPlayer.Name)
				end
			end
		end
	end)
end

-- ============================================================================
-- RACE NOTIFICATIONS
-- ============================================================================

function NotificationService.OnRaceStart(players: {Player}, dimension: string)
	for _, player in ipairs(players) do
		NotificationService.Info(player, "Race Started!", dimension .. " Dimension")
	end
end

function NotificationService.OnRaceFinish(player: Player, placement: number, time: number, isPersonalBest: boolean)
	local ordinal = placement == 1 and "1st" or placement == 2 and "2nd" or placement == 3 and "3rd" or tostring(placement) .. "th"

	if placement == 1 then
		NotificationService.Success(player, "Victory!", "You finished " .. ordinal .. "!")
	else
		NotificationService.Info(player, "Race Complete", "You finished " .. ordinal)
	end

	if isPersonalBest then
		-- PB notification handled separately
	end
end

function NotificationService.OnRaceCountdown(players: {Player}, count: number)
	for _, player in ipairs(players) do
		if count > 0 then
			NotificationService.Info(player, tostring(count), nil, { duration = 1 })
		else
			NotificationService.Success(player, "GO!", nil, { duration = 1 })
		end
	end
end

-- ============================================================================
-- DAILY CHALLENGE NOTIFICATIONS
-- ============================================================================

function NotificationService.OnDailyReset()
	NotificationService.Announce("Daily Challenge Reset!", "A new daily challenge is available!")
end

function NotificationService.OnDailyComplete(player: Player, placement: number, xpEarned: number)
	NotificationService.Success(player, "Daily Complete!",
		string.format("Rank #%d - +%d XP", placement, xpEarned), {
			priority = NotificationService.Priority.HIGH,
		})
end

return NotificationService
