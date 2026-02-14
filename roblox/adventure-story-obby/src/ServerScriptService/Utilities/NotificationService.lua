--[[
	NotificationService.lua
	Server-side notification utility

	Sends notifications to clients via RemoteEvent.
	Works with NotificationUI.lua on client.

	Usage:
	NotificationService.Success(player, "Level complete!")
	NotificationService.Coin(player, "+50 coins")
	NotificationService.Quest(player, "New quest available!")
--]]

local ServerScriptService = game:GetService("ServerScriptService")

local NotificationService = {}
local RemoteEventsInit = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function NotificationService.Init()
	-- Lazy load RemoteEventsInit
	RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
end

-- ============================================================================
-- NOTIFICATION FUNCTIONS
-- ============================================================================

function NotificationService.Send(player: Player, message: string, notificationType: string?)
	if not RemoteEventsInit then
		NotificationService.Init()
	end

	local remote = RemoteEventsInit.GetRemote("ShowNotification")
	if remote and remote.Remote then
		remote.Remote:FireClient(player, message, notificationType or "Info")
	end
end

function NotificationService.Success(player: Player, message: string)
	NotificationService.Send(player, message, "Success")
end

function NotificationService.Error(player: Player, message: string)
	NotificationService.Send(player, message, "Error")
end

function NotificationService.Info(player: Player, message: string)
	NotificationService.Send(player, message, "Info")
end

function NotificationService.Warning(player: Player, message: string)
	NotificationService.Send(player, message, "Warning")
end

function NotificationService.Coin(player: Player, message: string)
	NotificationService.Send(player, message, "Coin")
end

function NotificationService.Quest(player: Player, message: string)
	NotificationService.Send(player, message, "Quest")
end

-- ============================================================================
-- BROADCAST (All Players)
-- ============================================================================

function NotificationService.Broadcast(message: string, notificationType: string?)
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		NotificationService.Send(player, message, notificationType)
	end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return NotificationService
