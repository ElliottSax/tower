--[[
	AdminCommands.lua
	Developer commands for testing and debugging

	Usage:
	1. Add your UserId to ADMIN_LIST
	2. In-game, use chat commands: /give coins 1000

	Available Commands:
	- /give coins [amount]
	- /complete level [world] [level]
	- /start quest [questId]
	- /give fragment [fragmentId]
	- /unlock all
	- /reset data
	- /tp [levelId]
	- /skip level
--]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminCommands = {}

-- ============================================================================
-- ADMIN LIST
-- ============================================================================

-- Add your UserIds here to grant admin access
local ADMIN_LIST = {
	-- Example: 123456789, -- Your UserId
	-- Add more UserIds as needed
}

-- Alternatively, set this to true to allow all players (DEVELOPMENT ONLY!)
local ALLOW_ALL_ADMINS = true -- Set to false in production!

-- ============================================================================
-- SERVICES
-- ============================================================================

local DataService = nil
local StoryService = nil
local QuestService = nil
local WorldService = nil
local CoinService = nil

function AdminCommands.Init()
	print("[AdminCommands] Initializing...")

	-- Load services
	DataService = require(ServerScriptService.Services.DataService)
	StoryService = require(ServerScriptService.Services.StoryService)
	QuestService = require(ServerScriptService.Services.QuestService)
	WorldService = require(ServerScriptService.Services.WorldService)
	CoinService = require(ServerScriptService.Services.CoinService)

	-- Connect chat commands
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			AdminCommands.OnPlayerChatted(player, message)
		end)
	end)

	print("[AdminCommands] Initialized")
end

-- ============================================================================
-- PERMISSION CHECK
-- ============================================================================

function AdminCommands.IsAdmin(player: Player): boolean
	if ALLOW_ALL_ADMINS then
		return true
	end

	return table.find(ADMIN_LIST, player.UserId) ~= nil
end

-- ============================================================================
-- COMMAND HANDLER
-- ============================================================================

function AdminCommands.OnPlayerChatted(player: Player, message: string)
	-- Check if message starts with /
	if not message:sub(1, 1) == "/" then
		return
	end

	-- Check if player is admin
	if not AdminCommands.IsAdmin(player) then
		return
	end

	-- Parse command
	local args = message:split(" ")
	local command = args[1]:lower()

	-- Remove / prefix
	command = command:sub(2)

	-- Execute command
	local success, result = pcall(function()
		return AdminCommands.ExecuteCommand(player, command, args)
	end)

	if not success then
		AdminCommands.SendMessage(player, "Error: " .. tostring(result), Color3.fromRGB(255, 100, 100))
	end
end

-- ============================================================================
-- COMMAND EXECUTION
-- ============================================================================

function AdminCommands.ExecuteCommand(player: Player, command: string, args: {string})
	if command == "give" then
		return AdminCommands.GiveCommand(player, args)
	elseif command == "complete" then
		return AdminCommands.CompleteCommand(player, args)
	elseif command == "start" then
		return AdminCommands.StartCommand(player, args)
	elseif command == "unlock" then
		return AdminCommands.UnlockCommand(player, args)
	elseif command == "reset" then
		return AdminCommands.ResetCommand(player, args)
	elseif command == "tp" then
		return AdminCommands.TeleportCommand(player, args)
	elseif command == "skip" then
		return AdminCommands.SkipCommand(player, args)
	elseif command == "help" then
		return AdminCommands.HelpCommand(player)
	else
		AdminCommands.SendMessage(player, "Unknown command: " .. command, Color3.fromRGB(255, 100, 100))
	end
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

function AdminCommands.GiveCommand(player: Player, args: {string})
	-- /give coins 1000
	-- /give fragment Fragment_W1_L2

	local type = args[2]
	local value = args[3]

	if not type or not value then
		AdminCommands.SendMessage(player, "Usage: /give [coins|fragment] [amount|id]")
		return
	end

	if type == "coins" then
		local amount = tonumber(value)
		if not amount then
			AdminCommands.SendMessage(player, "Invalid amount")
			return
		end

		DataService.AddCoins(player, amount)
		AdminCommands.SendMessage(player, string.format("Gave %d coins", amount), Color3.fromRGB(100, 255, 100))

	elseif type == "fragment" then
		local fragmentId = value
		StoryService.CollectFragment(player, fragmentId)
		AdminCommands.SendMessage(player, string.format("Gave fragment: %s", fragmentId), Color3.fromRGB(100, 255, 100))

	else
		AdminCommands.SendMessage(player, "Invalid type. Use: coins or fragment")
	end
end

function AdminCommands.CompleteCommand(player: Player, args: {string})
	-- /complete level 1 1
	-- /complete world 1

	local type = args[2]

	if type == "level" then
		local worldId = tonumber(args[3])
		local levelId = tonumber(args[4])

		if not worldId or not levelId then
			AdminCommands.SendMessage(player, "Usage: /complete level [world] [level]")
			return
		end

		StoryService.CompleteLevel(player, worldId, levelId)
		AdminCommands.SendMessage(player, string.format("Completed World %d, Level %d", worldId, levelId), Color3.fromRGB(100, 255, 100))

	elseif type == "world" then
		local worldId = tonumber(args[3])

		if not worldId then
			AdminCommands.SendMessage(player, "Usage: /complete world [worldId]")
			return
		end

		-- Complete all levels in world
		for levelId = 1, 5 do
			StoryService.CompleteLevel(player, worldId, levelId)
		end

		AdminCommands.SendMessage(player, string.format("Completed all levels in World %d", worldId), Color3.fromRGB(100, 255, 100))

	else
		AdminCommands.SendMessage(player, "Usage: /complete [level|world]")
	end
end

function AdminCommands.StartCommand(player: Player, args: {string})
	-- /start quest CollectFragments

	local type = args[2]
	local id = args[3]

	if type == "quest" then
		if not id then
			AdminCommands.SendMessage(player, "Usage: /start quest [questId]")
			return
		end

		QuestService.StartQuest(player, id)
		AdminCommands.SendMessage(player, string.format("Started quest: %s", id), Color3.fromRGB(100, 255, 100))

	else
		AdminCommands.SendMessage(player, "Usage: /start quest [questId]")
	end
end

function AdminCommands.UnlockCommand(player: Player, args: {string})
	-- /unlock all

	local type = args[2]

	if type == "all" then
		local profile = DataService.GetProfile(player)
		if not profile then return end

		-- Unlock all levels in World 1
		for levelId = 1, 5 do
			local levelKey = string.format("World1_Level%d", levelId)
			profile.Data.Story.CompletedLevels[levelKey] = true
		end

		-- Unlock all worlds
		profile.Data.Story.UnlockedWorlds = {1, 2, 3, 4, 5}

		AdminCommands.SendMessage(player, "Unlocked all levels and worlds", Color3.fromRGB(100, 255, 100))

	else
		AdminCommands.SendMessage(player, "Usage: /unlock all")
	end
end

function AdminCommands.ResetCommand(player: Player, args: {string})
	-- /reset data

	local type = args[2]

	if type == "data" then
		local profile = DataService.GetProfile(player)
		if not profile then return end

		-- Reset story progress
		profile.Data.Story.CompletedLevels = {}
		profile.Data.Story.CollectedFragments = {}
		profile.Data.Story.CurrentWorld = 1
		profile.Data.Story.CurrentLevel = 1
		profile.Data.Story.UnlockedWorlds = {1}

		-- Reset quests
		profile.Data.Quests.Active = {}
		profile.Data.Quests.Completed = {}
		profile.Data.Quests.Progress = {}

		-- Reset coins (optional)
		profile.Data.Coins = 0

		-- Update leaderstats
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = 0
			end
		end

		AdminCommands.SendMessage(player, "Reset all player data", Color3.fromRGB(255, 200, 100))

	else
		AdminCommands.SendMessage(player, "Usage: /reset data")
	end
end

function AdminCommands.TeleportCommand(player: Player, args: {string})
	-- /tp 1 (teleports to Level 1)
	-- /tp hub

	local destination = args[2]

	if destination == "hub" then
		WorldService.TeleportToHub(player)
		AdminCommands.SendMessage(player, "Teleported to hub", Color3.fromRGB(100, 255, 100))

	else
		local levelId = tonumber(destination)
		if not levelId then
			AdminCommands.SendMessage(player, "Usage: /tp [levelId|hub]")
			return
		end

		-- Assume World 1 for simplicity
		WorldService.TeleportToLevel(player, 1, levelId)
		AdminCommands.SendMessage(player, string.format("Teleported to Level %d", levelId), Color3.fromRGB(100, 255, 100))
	end
end

function AdminCommands.SkipCommand(player: Player, args: {string})
	-- /skip level (completes current level)

	local type = args[2]

	if type == "level" then
		-- Complete current level
		WorldService.CompleteCurrentLevel(player)
		AdminCommands.SendMessage(player, "Completed current level", Color3.fromRGB(100, 255, 100))

	else
		AdminCommands.SendMessage(player, "Usage: /skip level")
	end
end

function AdminCommands.HelpCommand(player: Player)
	AdminCommands.SendMessage(player, "=== ADMIN COMMANDS ===", Color3.fromRGB(255, 215, 0))
	AdminCommands.SendMessage(player, "/give coins [amount] - Give coins")
	AdminCommands.SendMessage(player, "/give fragment [id] - Give fragment")
	AdminCommands.SendMessage(player, "/complete level [w] [l] - Complete level")
	AdminCommands.SendMessage(player, "/complete world [w] - Complete world")
	AdminCommands.SendMessage(player, "/start quest [id] - Start quest")
	AdminCommands.SendMessage(player, "/unlock all - Unlock everything")
	AdminCommands.SendMessage(player, "/reset data - Reset player data")
	AdminCommands.SendMessage(player, "/tp [level|hub] - Teleport")
	AdminCommands.SendMessage(player, "/skip level - Complete current level")
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function AdminCommands.SendMessage(player: Player, message: string, color: Color3?)
	color = color or Color3.fromRGB(255, 255, 255)

	-- Send via TextChatService (new chat)
	local TextChatService = game:GetService("TextChatService")
	local success, _ = pcall(function()
		TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(
			"[ADMIN] " .. message,
			player.Name
		)
	end)

	-- Fallback to legacy chat
	if not success then
		game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
			Text = "[ADMIN] " .. message,
			Color = color,
			Font = Enum.Font.SourceSansBold,
		})
	end

	-- Also print to output
	print(string.format("[AdminCommands] %s: %s", player.Name, message))
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return AdminCommands
