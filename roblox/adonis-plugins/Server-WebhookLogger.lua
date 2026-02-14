--[[
	Server: Webhook Logger for Adonis Commands
	Logs all significant admin actions to Discord via WebhookLogger

	INSTALLATION:
	1. Copy this file to: ServerScriptService/Adonis_Loader/Config/Plugins/
	2. Ensure WebhookLogger.lua is in ServerScriptService/Utilities/
	3. Configure webhook URL in WebhookLogger
	4. Restart server or rejoin game

	FEATURES:
	- Logs all admin commands to Discord
	- Logs player kicks with admin info
	- Logs server shutdowns
	- Logs admin joins/leaves
	- Rate-limited to prevent spam

	Created: 2025-12-18
	Version: 1.0
]]

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service

	local ServerScriptService = game:GetService("ServerScriptService")
	local Players = game:GetService("Players")

	-- ========================================================================
	-- IMPORT WEBHOOK LOGGER
	-- ========================================================================

	local WebhookLogger
	local success = pcall(function()
		WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)
	end)

	if not success or not WebhookLogger then
		warn("[Adonis-Webhook] WebhookLogger not found - logging disabled")
		warn("[Adonis-Webhook] Make sure WebhookLogger.lua exists in ServerScriptService/Utilities/")
		return
	end

	print("[Adonis-Webhook] ✅ Webhook logging initialized")

	-- ========================================================================
	-- CONFIGURATION
	-- ========================================================================

	local CONFIG = {
		-- Log all commands (true) or only important ones (false)
		LogAllCommands = true,

		-- Commands to always log (even if LogAllCommands = false)
		ImportantCommands = {
			"ban", "kick", "shutdown", "place", "unban",
			"clearbanhistory", "exploitstats", "teleport"
		},

		-- Commands to never log (even if LogAllCommands = true)
		IgnoredCommands = {
			"cmds", "h", "m" -- Too spammy
		},

		-- Log player joins/leaves
		LogAdminJoins = true,
	}

	-- ========================================================================
	-- HELPER FUNCTIONS
	-- ========================================================================

	local function shouldLogCommand(commandName)
		-- Check if in ignored list
		for _, ignored in ipairs(CONFIG.IgnoredCommands) do
			if commandName:lower() == ignored:lower() then
				return false
			end
		end

		-- If logging all, return true
		if CONFIG.LogAllCommands then
			return true
		end

		-- Otherwise, only log if in important list
		for _, important in ipairs(CONFIG.ImportantCommands) do
			if commandName:lower() == important:lower() then
				return true
			end
		end

		return false
	end

	local function getCommandName(message)
		-- Extract command name from message (e.g., ":ban player" -> "ban")
		local prefix = message:sub(1, 1)
		if prefix == ":" or prefix == ";" or prefix == "!" then
			local command = message:sub(2):match("%S+")
			return command
		end
		return message:match("%S+")
	end

	-- ========================================================================
	-- LOG ALL ADMIN COMMANDS
	-- ========================================================================

	-- Hook into command processing
	local originalProcessCommand = server.Process.Command

	server.Process.Command = function(player, message, ...)
		-- Get command name
		local commandName = getCommandName(message)

		-- Check if we should log this command
		if commandName and shouldLogCommand(commandName) then
			task.spawn(function()
				pcall(function()
					WebhookLogger.LogEvent(
						"🔧 Admin Command",
						string.format("**%s** executed command", player.Name),
						"INFO",
						{
							{name = "Admin", value = player.Name, inline = true},
							{name = "UserID", value = tostring(player.UserId), inline = true},
							{name = "Command", value = message, inline = false},
							{name = "Time", value = os.date("%H:%M:%S"), inline = true}
						}
					)
				end)
			end)
		end

		-- Run original command
		return originalProcessCommand(player, message, ...)
	end

	print("[Adonis-Webhook]   - Command logging enabled")

	-- ========================================================================
	-- LOG KICKS
	-- ========================================================================

	if server.Commands.Kick then
		local originalKick = server.Commands.Kick.Function

		server.Commands.Kick.Function = function(args)
			local admin = args.Player
			local reason = args.Reason or "No reason specified"

			-- Log each kick
			for _, target in ipairs(args.Targets or {}) do
				task.spawn(function()
					pcall(function()
						WebhookLogger.LogEvent(
							"👢 Player Kicked",
							string.format("**%s** was kicked from the server", target.Name),
							"WARNING",
							{
								{name = "Player", value = target.Name, inline = true},
								{name = "UserID", value = tostring(target.UserId), inline = true},
								{name = "Admin", value = admin.Name, inline = true},
								{name = "Reason", value = reason, inline = false}
							}
						)
					end)
				end)
			end

			return originalKick(args)
		end

		print("[Adonis-Webhook]   - Kick logging enabled")
	end

	-- ========================================================================
	-- LOG SERVER SHUTDOWNS
	-- ========================================================================

	if server.Commands.Shutdown then
		local originalShutdown = server.Commands.Shutdown.Function

		server.Commands.Shutdown.Function = function(args)
			local admin = args.Player

			-- Log shutdown BEFORE it happens
			pcall(function()
				WebhookLogger.LogEvent(
					"🛑 Server Shutdown",
					string.format("**%s** is shutting down the server", admin.Name),
					"CRITICAL",
					{
						{name = "Admin", value = admin.Name, inline = true},
						{name = "UserID", value = tostring(admin.UserId), inline = true},
						{name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true},
						{name = "Server", value = game.JobId, inline = false}
					}
				)
			end)

			-- Wait for webhook to send
			task.wait(2)

			return originalShutdown(args)
		end

		print("[Adonis-Webhook]   - Shutdown logging enabled")
	end

	-- ========================================================================
	-- LOG PLACE TELEPORTS
	-- ========================================================================

	if server.Commands.Place then
		local originalPlace = server.Commands.Place.Function

		server.Commands.Place.Function = function(args)
			local admin = args.Player
			local placeId = args.Args and args.Args[1]

			task.spawn(function()
				pcall(function()
					WebhookLogger.LogEvent(
						"🌐 Place Teleport",
						string.format("**%s** teleported players to another place", admin.Name),
						"INFO",
						{
							{name = "Admin", value = admin.Name, inline = true},
							{name = "Place ID", value = tostring(placeId or "Unknown"), inline = true},
							{name = "Players", value = tostring(#(args.Targets or {})), inline = true}
						}
					)
				end)
			end)

			return originalPlace(args)
		end

		print("[Adonis-Webhook]   - Place teleport logging enabled")
	end

	-- ========================================================================
	-- LOG ADMIN PLAYER JOINS/LEAVES
	-- ========================================================================

	if CONFIG.LogAdminJoins then
		-- Track admin joins
		Players.PlayerAdded:Connect(function(player)
			-- Wait a moment for admin check to be ready
			task.wait(1)

			local isAdmin = server.Admin.CheckAdmin(player)

			if isAdmin then
				task.spawn(function()
					pcall(function()
						WebhookLogger.LogEvent(
							"👮 Admin Joined",
							string.format("**%s** joined the server", player.Name),
							"INFO",
							{
								{name = "Admin", value = player.Name, inline = true},
								{name = "UserID", value = tostring(player.UserId), inline = true},
								{name = "Admin Level", value = tostring(isAdmin), inline = true},
								{name = "Time", value = os.date("%H:%M:%S"), inline = true}
							}
						)
					end)
				end)

				print(string.format("[Adonis-Webhook] Admin %s joined", player.Name))
			end
		end)

		-- Track admin leaves
		Players.PlayerRemoving:Connect(function(player)
			local isAdmin = server.Admin.CheckAdmin(player)

			if isAdmin then
				task.spawn(function()
					pcall(function()
						WebhookLogger.LogEvent(
							"👋 Admin Left",
							string.format("**%s** left the server", player.Name),
							"INFO",
							{
								{name = "Admin", value = player.Name, inline = true},
								{name = "UserID", value = tostring(player.UserId), inline = true},
								{name = "Time", value = os.date("%H:%M:%S"), inline = true}
							}
						)
					end)
				end)

				print(string.format("[Adonis-Webhook] Admin %s left", player.Name))
			end
		end)

		print("[Adonis-Webhook]   - Admin join/leave logging enabled")
	end

	-- ========================================================================
	-- STARTUP LOG
	-- ========================================================================

	task.spawn(function()
		-- Wait a moment for server to fully initialize
		task.wait(3)

		pcall(function()
			WebhookLogger.LogEvent(
				"🚀 Server Started",
				"Adonis admin system initialized with webhook logging",
				"INFO",
				{
					{name = "Server", value = game.JobId, inline = false},
					{name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true},
					{name = "Place", value = tostring(game.PlaceId), inline = true}
				}
			)
		end)
	end)

	-- ========================================================================
	-- INITIALIZATION COMPLETE
	-- ========================================================================

	print("[Adonis-Webhook] ✅ Webhook logging ready")
	print("[Adonis-Webhook] Configuration:")
	print(string.format("[Adonis-Webhook]   - Log all commands: %s", tostring(CONFIG.LogAllCommands)))
	print(string.format("[Adonis-Webhook]   - Log admin joins: %s", tostring(CONFIG.LogAdminJoins)))
	print("[Adonis-Webhook]")
	print("[Adonis-Webhook] 🎉 Discord notifications enabled!")
end
