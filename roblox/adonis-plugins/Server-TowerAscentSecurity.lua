--[[
	Server: Tower Ascent Security Integration
	Integrates Adonis Admin with existing SecurityManager and WebhookLogger

	INSTALLATION:
	1. Copy this file to: ServerScriptService/Adonis_Loader/Config/Plugins/
	2. Restart server or rejoin game
	3. Test with :banhistory command

	FEATURES:
	- Overrides :ban command to use SecurityManager ban escalation
	- Adds :banhistory command to view player ban history
	- Adds :exploitstats command for security monitoring
	- Adds :clearbanhistory command (Creators only)
	- Integrates webhook logging for all admin actions

	Created: 2025-12-18
	Version: 1.0
]]

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service

	local ServerScriptService = game:GetService("ServerScriptService")
	local Players = game:GetService("Players")

	-- ========================================================================
	-- IMPORT TOWER ASCENT SYSTEMS
	-- ========================================================================

	local ServiceLocator, SecurityManager, WebhookLogger, AntiExploit

	local success = pcall(function()
		ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
		WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

		-- Wait for SecurityManager to be registered
		if ServiceLocator then
			SecurityManager = ServiceLocator.WaitFor("SecurityManager", 10)
			AntiExploit = ServiceLocator.Get("AntiExploit")
		end
	end)

	if not success then
		warn("[Adonis-TowerAscent] Failed to load Tower Ascent systems - integration disabled")
		return
	end

	print("[Adonis-TowerAscent] ✅ Security integration loaded")
	if ServiceLocator then print("[Adonis-TowerAscent]   - ServiceLocator: OK") end
	if SecurityManager then print("[Adonis-TowerAscent]   - SecurityManager: OK") end
	if WebhookLogger then print("[Adonis-TowerAscent]   - WebhookLogger: OK") end
	if AntiExploit then print("[Adonis-TowerAscent]   - AntiExploit: OK") end

	-- ========================================================================
	-- HELPER FUNCTIONS
	-- ========================================================================

	local function parseDuration(duration)
		--[[
			Parse Adonis duration format (e.g., "1d", "2h", "30m")
			Returns duration in seconds, or nil for permanent
		]]
		if not duration or duration == "permanent" or duration == "perm" then
			return nil -- Permanent ban (0 in SecurityManager)
		end

		local time, unit = duration:match("(%d+)([dhm])")
		if time and unit then
			time = tonumber(time)
			if unit == "d" then
				return time * 86400 -- days
			elseif unit == "h" then
				return time * 3600 -- hours
			elseif unit == "m" then
				return time * 60 -- minutes
			end
		end

		return nil -- Default to permanent if can't parse
	end

	local function sendOutput(player, title, message, success)
		local color = success and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		server.Remote.MakeGui(player, "Output", {
			Title = title,
			Message = message,
			Color = color
		})
	end

	-- ========================================================================
	-- OVERRIDE ADONIS BAN COMMAND
	-- ========================================================================

	if SecurityManager then
		-- Store original ban function
		local originalBanFunction = server.Commands.Ban.Function

		-- Override with SecurityManager integration
		server.Commands.Ban.Function = function(args)
			local admin = args.Player
			local targets = args.Targets or {}
			local reason = args.Reason or "Banned by administrator"
			local duration = args.Duration

			-- Parse duration
			local durationSeconds = parseDuration(duration)

			for _, target in ipairs(targets) do
				-- Use Tower Ascent SecurityManager ban system
				-- This automatically uses ban escalation!
				SecurityManager.BanPlayer(target, reason, durationSeconds)

				-- Log to webhook
				if WebhookLogger then
					WebhookLogger.LogBan(
						target,
						reason,
						durationSeconds or 0, -- 0 = permanent
						admin.Name -- Admin who issued ban
					)
				end

				-- Notify admin
				local banMessage
				if durationSeconds then
					local hours = math.floor(durationSeconds / 3600)
					banMessage = string.format(
						"Banned %s for %d hours\nReason: %s",
						target.Name, hours, reason
					)
				else
					banMessage = string.format(
						"Permanently banned %s\nReason: %s",
						target.Name, reason
					)
				end

				sendOutput(admin, "Ban Successful", banMessage, true)

				print(string.format(
					"[Adonis-TowerAscent] %s banned %s (Duration: %s, Reason: %s)",
					admin.Name, target.Name, duration or "permanent", reason
				))
			end
		end

		print("[Adonis-TowerAscent]   - Ban command overridden (using SecurityManager)")
	else
		warn("[Adonis-TowerAscent] SecurityManager not available - using default Adonis ban")
	end

	-- ========================================================================
	-- LOG ALL ADMIN COMMANDS TO WEBHOOK
	-- ========================================================================

	if WebhookLogger then
		-- Hook into command execution
		local originalRunCommand = server.Process.Command

		server.Process.Command = function(player, message, ...)
			-- Log command to webhook (non-blocking)
			task.spawn(function()
				pcall(function()
					WebhookLogger.LogEvent(
						"🔧 Admin Command",
						string.format("**%s** executed admin command", player.Name),
						"INFO",
						{
							{name = "Admin", value = player.Name, inline = true},
							{name = "UserID", value = tostring(player.UserId), inline = true},
							{name = "Command", value = message, inline = false},
							{name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
						}
					)
				end)
			end)

			-- Run original command
			return originalRunCommand(player, message, ...)
		end

		print("[Adonis-TowerAscent]   - Admin command logging enabled")
	end

	-- ========================================================================
	-- CUSTOM COMMAND: :banhistory
	-- ========================================================================

	server.Commands.BanHistory = {
		Prefix = ":";
		Commands = {"banhistory", "banhist", "baninfo"};
		Args = {"player"};
		Description = "View player's ban escalation history from SecurityManager";
		AdminLevel = "Moderators";
		Function = function(args)
			local admin = args.Player
			local targets = args.Targets or {}

			if #targets == 0 then
				return sendOutput(admin, "Error", "No target player found", false)
			end

			local target = targets[1]

			if not SecurityManager or not SecurityManager.BanHistory then
				return sendOutput(admin, "Error", "SecurityManager not available", false)
			end

			local history = SecurityManager.BanHistory[target.UserId]

			if history and history.OffenseCount > 0 then
				-- Calculate next ban duration
				local nextBanDuration
				if history.OffenseCount >= 5 then
					nextBanDuration = "PERMANENT"
				else
					local seconds = 3600 * math.pow(3, history.OffenseCount)
					local hours = math.floor(seconds / 3600)
					nextBanDuration = string.format("%d hours", hours)
				end

				local lastBanDate = history.LastBan > 0
					and os.date("%Y-%m-%d %H:%M:%S", history.LastBan)
					or "Never"

				local message = string.format(
					"Ban History for %s:\n\n" ..
					"Total Offenses: %d\n" ..
					"Last Ban: %s\n" ..
					"Next Ban Duration: %s\n\n" ..
					"Escalation: 1h → 3h → 9h → 27h → PERMANENT",
					target.Name,
					history.OffenseCount,
					lastBanDate,
					nextBanDuration
				)

				sendOutput(admin, "Ban History", message, true)
			else
				local message = string.format(
					"%s has a clean record!\n\n" ..
					"No ban history found.",
					target.Name
				)

				sendOutput(admin, "Ban History", message, true)
			end
		end
	}

	-- ========================================================================
	-- CUSTOM COMMAND: :exploitstats
	-- ========================================================================

	server.Commands.ExploitStats = {
		Prefix = ":";
		Commands = {"exploitstats", "anticheats", "securitystats"};
		Args = {};
		Description = "View anti-exploit detection statistics and security system status";
		AdminLevel = "Admins";
		Function = function(args)
			local admin = args.Player

			local statsLines = {
				"🛡️ Tower Ascent Security Status",
				"",
				"ACTIVE SYSTEMS:",
			}

			-- Check each system
			if SecurityManager then
				table.insert(statsLines, "✅ SecurityManager - Online")
				local banCount = 0
				for _ in pairs(SecurityManager.BanHistory or {}) do
					banCount = banCount + 1
				end
				table.insert(statsLines, string.format("   - Players with ban history: %d", banCount))
			else
				table.insert(statsLines, "❌ SecurityManager - Offline")
			end

			if AntiExploit then
				table.insert(statsLines, "✅ AntiExploit - Online")
				table.insert(statsLines, "   - Monitors: Speed, Teleport, NoClip")
			else
				table.insert(statsLines, "❌ AntiExploit - Offline")
			end

			if WebhookLogger then
				table.insert(statsLines, "✅ WebhookLogger - Online")
				table.insert(statsLines, "   - Discord notifications enabled")
			else
				table.insert(statsLines, "❌ WebhookLogger - Offline")
			end

			if ServiceLocator then
				table.insert(statsLines, "✅ ServiceLocator - Online")
				local services = ServiceLocator.GetServiceNames()
				table.insert(statsLines, string.format("   - Registered services: %d", #services))
			else
				table.insert(statsLines, "❌ ServiceLocator - Offline")
			end

			table.insert(statsLines, "")
			table.insert(statsLines, "Integration: Tower Ascent v1.0")

			sendOutput(admin, "Security Statistics", table.concat(statsLines, "\n"), true)
		end
	}

	-- ========================================================================
	-- CUSTOM COMMAND: :clearbanhistory
	-- ========================================================================

	server.Commands.ClearBanHistory = {
		Prefix = ":";
		Commands = {"clearbanhistory", "resetbans", "clearbans"};
		Args = {"player"};
		Description = "Clear a player's ban escalation history (WARNING: Resets to 0 offenses)";
		AdminLevel = "Creators"; -- Only highest level admins
		Function = function(args)
			local admin = args.Player
			local targets = args.Targets or {}

			if #targets == 0 then
				return sendOutput(admin, "Error", "No target player found", false)
			end

			local target = targets[1]

			if not SecurityManager or not SecurityManager.BanHistory then
				return sendOutput(admin, "Error", "SecurityManager not available", false)
			end

			-- Clear ban history
			local hadHistory = SecurityManager.BanHistory[target.UserId] ~= nil
			SecurityManager.BanHistory[target.UserId] = nil

			-- Log to webhook
			if WebhookLogger then
				WebhookLogger.LogEvent(
					"🔄 Ban History Cleared",
					string.format(
						"**%s** cleared ban history for **%s** (UserID: %d)",
						admin.Name, target.Name, target.UserId
					),
					"WARNING",
					{
						{name = "Admin", value = admin.Name, inline = true},
						{name = "Admin ID", value = tostring(admin.UserId), inline = true},
						{name = "Target", value = target.Name, inline = true},
						{name = "Target ID", value = tostring(target.UserId), inline = true},
					}
				)
			end

			local message
			if hadHistory then
				message = string.format(
					"Successfully cleared ban history for %s\n\n" ..
					"Their next ban will start at 1 hour duration.",
					target.Name
				)
			else
				message = string.format(
					"%s had no ban history to clear.",
					target.Name
				)
			end

			sendOutput(admin, "Ban History Cleared", message, true)

			print(string.format(
				"[Adonis-TowerAscent] %s cleared ban history for %s",
				admin.Name, target.Name
			))
		end
	}

	-- ========================================================================
	-- CUSTOM COMMAND: :checkservice
	-- ========================================================================

	server.Commands.CheckService = {
		Prefix = ":";
		Commands = {"checkservice", "serviceinfo", "svcinfo"};
		Args = {"string"};
		Description = "Check if a Tower Ascent service is registered and available";
		AdminLevel = "Admins";
		Function = function(args)
			local admin = args.Player
			local serviceName = args.Args[1]

			if not serviceName then
				return sendOutput(admin, "Error", "Please specify a service name", false)
			end

			if not ServiceLocator then
				return sendOutput(admin, "Error", "ServiceLocator not available", false)
			end

			local hasService = ServiceLocator.Has(serviceName)
			local service = ServiceLocator.Get(serviceName)

			if hasService and service then
				-- Try to get some info about the service
				local funcCount = 0
				for key, value in pairs(service) do
					if type(value) == "function" then
						funcCount = funcCount + 1
					end
				end

				local message = string.format(
					"Service '%s' is registered!\n\n" ..
					"Functions: %d\n" ..
					"Status: Available",
					serviceName, funcCount
				)

				sendOutput(admin, "Service Check", message, true)
			else
				local allServices = ServiceLocator.GetServiceNames()

				local message = string.format(
					"Service '%s' is NOT registered.\n\n" ..
					"Available services (%d):\n%s",
					serviceName,
					#allServices,
					table.concat(allServices, ", ")
				)

				sendOutput(admin, "Service Check", message, false)
			end
		end
	}

	-- ========================================================================
	-- INITIALIZATION COMPLETE
	-- ========================================================================

	print("[Adonis-TowerAscent] ✅ Integration complete")
	print("[Adonis-TowerAscent] Custom commands added:")
	print("[Adonis-TowerAscent]   - :banhistory <player>")
	print("[Adonis-TowerAscent]   - :exploitstats")
	print("[Adonis-TowerAscent]   - :clearbanhistory <player> (Creators only)")
	print("[Adonis-TowerAscent]   - :checkservice <name>")
	print("[Adonis-TowerAscent]")
	print("[Adonis-TowerAscent] 🎉 Tower Ascent Security integration ready!")
end
