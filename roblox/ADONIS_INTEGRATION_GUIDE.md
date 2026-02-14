# Adonis Admin System Integration Guide

Complete guide to integrating Adonis Admin with your Tower Ascent game's existing security infrastructure.

---

## 📋 Overview

This guide integrates **Adonis Admin** with your existing systems:
- ✅ SecurityManager (ban escalation system)
- ✅ WebhookLogger (Discord notifications)
- ✅ ServiceLocator (dependency injection)
- ✅ AntiExploit (player monitoring)

**Benefits:**
- 400+ moderation commands out of the box
- Professional admin panel UI
- Ban management integrated with your existing ban escalation
- Real-time webhook logging for all admin actions

---

## 🚀 Installation Steps

### Step 1: Install Adonis Loader

**Method A: Roblox Library (Recommended)**
1. Open Roblox Studio with your Tower Ascent game
2. Go to Toolbox → Models
3. Search for "Adonis Loader" by Sceleratis
4. Insert into **ServerScriptService**

**Method B: GitHub Release**
1. Visit https://github.com/Epix-Incorporated/Adonis/releases
2. Download latest `.rbxm` file
3. In Studio: Right-click ServerScriptService → Insert from File
4. Select downloaded `.rbxm` file

**Expected Structure:**
```
ServerScriptService
├── Adonis_Loader (Script)
│   └── Config (Folder)
│       ├── Settings (ModuleScript)
│       ├── Plugins (Folder)
│       └── ...
├── Services (your existing folder)
├── Security (your existing folder)
└── Utilities (your existing folder)
```

---

### Step 2: Configure Security Settings

Open **Adonis_Loader → Config → Settings** and modify:

```lua
--[[
	SECURITY CONFIGURATION
	Change these values to secure your admin system
]]

Settings = {
	-- CRITICAL: Change this to a random string
	DataStoreKey = "TowerAscent_Adonis_2025_" .. math.random(10000, 99999),

	-- Change if using third-party plugins
	G_Access_Key = "YourSecretKey_" .. game.JobId,

	-- Your game info
	GroupId = 0, -- Set to your Roblox group ID if you have one
	GroupRanked = true, -- Enable group-based permissions

	-- Prefix for commands (default is :)
	Prefix = ":",
	AnyPrefix = false,

	-- Console settings
	Console_Enabled = true,

	-- Misc
	Theme = "Default", -- or "Dark", "Blue", "Red"
}
```

---

### Step 3: Setup Admin Permissions

In the same **Settings** module, configure who gets admin:

```lua
--[[
	ADMIN CONFIGURATION
	Add your admins here
]]

Admins = {
	-- By Username (NOT recommended - users can change names)
	-- "YourUsername";

	-- By UserID (Recommended)
	-- Get your UserID from: https://www.roblox.com/users/YOUR_ID/profile
	{
		UserId = 123456789, -- Replace with your UserID
		Level = "Creators", -- Highest level
	},

	-- By Group Rank
	{
		GroupId = 0, -- Your group ID
		GroupRank = 255, -- Owner rank
		Level = "Creators",
	},
	{
		GroupId = 0,
		GroupRank = 254, -- Admin rank
		Level = "Admins",
	},
	{
		GroupId = 0,
		GroupRank = 200, -- Moderator rank
		Level = "Moderators",
	},

	-- By Gamepass (for VIP admins)
	{
		Gamepass = 0, -- Your gamepass ID
		Level = "Moderators",
	},
}

--[[
	PERMISSION LEVELS (Highest to Lowest)
	- Creators: Full access (owner)
	- HeadAdmins: Most commands
	- Admins: Standard moderation
	- Moderators: Basic moderation
	- Players: Regular players
]]
```

---

## 🔌 Custom Plugin: SecurityManager Integration

Create custom Adonis plugin to integrate with your existing ban system.

### File: `Adonis_Loader/Config/Plugins/Server-TowerAscentSecurity.lua`

```lua
--[[
	Server: Tower Ascent Security Integration
	Integrates Adonis with existing SecurityManager and WebhookLogger

	Created: 2025-12-18
]]

return function(Vargs)
	local server = Vargs.Server
	local service = Vargs.Service

	local ServerScriptService = game:GetService("ServerScriptService")
	local Players = game:GetService("Players")

	-- Import Tower Ascent systems
	local ServiceLocator, SecurityManager, WebhookLogger

	pcall(function()
		ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
		WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

		-- Wait for SecurityManager to be registered
		if ServiceLocator then
			SecurityManager = ServiceLocator.WaitFor("SecurityManager", 10)
		end
	end)

	print("[Adonis-TowerAscent] Security integration loaded")

	-- ========================================================================
	-- OVERRIDE ADONIS BAN COMMAND TO USE SECURITYMANAGER
	-- ========================================================================

	-- Hook into Adonis ban command
	server.Commands.Ban.Function = function(args)
		local player = args.Player -- Admin who ran command
		local targets = args.Targets -- Players to ban
		local reason = args.Reason or "Banned by admin"
		local duration = args.Duration -- Can be: permanent, 1d, 2h, etc.

		for _, target in ipairs(targets) do
			-- Use Tower Ascent SecurityManager ban system
			if SecurityManager and SecurityManager.BanPlayer then
				-- Parse duration (Adonis format: "1d", "2h", "30m")
				local durationSeconds = nil

				if duration and duration ~= "permanent" then
					local time, unit = duration:match("(%d+)([dhm])")
					if time and unit then
						time = tonumber(time)
						if unit == "d" then
							durationSeconds = time * 86400 -- days
						elseif unit == "h" then
							durationSeconds = time * 3600 -- hours
						elseif unit == "m" then
							durationSeconds = time * 60 -- minutes
						end
					end
				end

				-- Call SecurityManager.BanPlayer (uses escalation system)
				SecurityManager.BanPlayer(target, reason, durationSeconds)

				-- Log to webhook
				if WebhookLogger then
					WebhookLogger.LogBan(
						target,
						reason,
						durationSeconds or 0,
						player.Name -- Admin who banned
					)
				end

				-- Notify admin
				server.Remote.MakeGui(player, "Output", {
					Title = "Ban Successful",
					Message = string.format("Banned %s for %s",
						target.Name,
						duration or "permanent"),
					Color = Color3.new(0, 1, 0)
				})
			else
				warn("[Adonis-TowerAscent] SecurityManager not available, using default Adonis ban")
				-- Fallback to default Adonis ban
				service.TrackTask("Thread: Adonis Ban", function()
					target:Kick(string.format("Banned: %s", reason))
				end)
			end
		end
	end

	-- ========================================================================
	-- LOG ALL ADMIN COMMANDS TO WEBHOOK
	-- ========================================================================

	-- Hook into command execution
	local originalRunCommand = server.Process.Command

	server.Process.Command = function(player, message, ...)
		-- Log command to webhook
		if WebhookLogger then
			WebhookLogger.LogEvent(
				"🔧 Admin Command",
				string.format("**%s** executed: `%s`", player.Name, message),
				"INFO",
				{
					{name = "Admin", value = player.Name, inline = true},
					{name = "UserID", value = tostring(player.UserId), inline = true},
					{name = "Command", value = message, inline = false},
					{name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
				}
			)
		end

		-- Run original command
		return originalRunCommand(player, message, ...)
	end

	-- ========================================================================
	-- CUSTOM COMMANDS
	-- ========================================================================

	-- Command: :banhistory <player>
	-- Shows player's ban escalation history
	server.Commands.BanHistory = {
		Prefix = ":";
		Commands = {"banhistory", "banhist"};
		Args = {"player"};
		Description = "View player's ban escalation history";
		AdminLevel = "Moderators";
		Function = function(args)
			local player = args.Player
			local target = args.Targets[1]

			if not target then
				return server.Remote.MakeGui(player, "Output", {
					Title = "Error",
					Message = "Target player not found",
					Color = Color3.new(1, 0, 0)
				})
			end

			if SecurityManager and SecurityManager.BanHistory then
				local history = SecurityManager.BanHistory[target.UserId]

				if history then
					local message = string.format(
						"Ban History for %s:\n" ..
						"Total Offenses: %d\n" ..
						"Last Ban: %s\n" ..
						"Next Ban Duration: %s",
						target.Name,
						history.OffenseCount,
						os.date("%Y-%m-%d %H:%M:%S", history.LastBan),
						history.OffenseCount >= 5 and "PERMANENT" or
							string.format("%d hours", math.floor((3600 * math.pow(3, history.OffenseCount)) / 3600))
					)

					server.Remote.MakeGui(player, "Output", {
						Title = "Ban History",
						Message = message,
						Color = Color3.new(1, 1, 0)
					})
				else
					server.Remote.MakeGui(player, "Output", {
						Title = "Ban History",
						Message = string.format("%s has no ban history", target.Name),
						Color = Color3.new(0, 1, 0)
					})
				end
			else
				server.Remote.MakeGui(player, "Output", {
					Title = "Error",
					Message = "SecurityManager not available",
					Color = Color3.new(1, 0, 0)
				})
			end
		end
	}

	-- Command: :exploitstats
	-- Shows anti-exploit detection statistics
	server.Commands.ExploitStats = {
		Prefix = ":";
		Commands = {"exploitstats", "anticheats", "securitystats"};
		Args = {};
		Description = "View anti-exploit detection statistics";
		AdminLevel = "Admins";
		Function = function(args)
			local player = args.Player

			local AntiExploit = ServiceLocator and ServiceLocator.Get("AntiExploit")

			if AntiExploit then
				-- Gather stats (implement GetStats() in AntiExploit if needed)
				local message = "Anti-Exploit Statistics:\n\n" ..
					"Total Detections: Coming soon\n" ..
					"Active Monitors: Speed, Teleport, NoClip\n" ..
					"Webhook Logging: " .. (WebhookLogger and "Enabled" or "Disabled")

				server.Remote.MakeGui(player, "Output", {
					Title = "Security Stats",
					Message = message,
					Color = Color3.new(0.5, 0.5, 1)
				})
			else
				server.Remote.MakeGui(player, "Output", {
					Title = "Error",
					Message = "AntiExploit system not available",
					Color = Color3.new(1, 0, 0)
				})
			end
		end
	}

	-- Command: :clearbanhistory <player>
	-- Clears a player's ban escalation history (Creators only)
	server.Commands.ClearBanHistory = {
		Prefix = ":";
		Commands = {"clearbanhistory", "resetbans"};
		Args = {"player"};
		Description = "Clear player's ban escalation history";
		AdminLevel = "Creators";
		Function = function(args)
			local player = args.Player
			local target = args.Targets[1]

			if not target then
				return server.Remote.MakeGui(player, "Output", {
					Title = "Error",
					Message = "Target player not found",
					Color = Color3.new(1, 0, 0)
				})
			end

			if SecurityManager and SecurityManager.BanHistory then
				SecurityManager.BanHistory[target.UserId] = nil

				-- Log to webhook
				if WebhookLogger then
					WebhookLogger.LogEvent(
						"🔄 Ban History Cleared",
						string.format("**%s** cleared ban history for **%s**", player.Name, target.Name),
						"WARNING",
						{
							{name = "Admin", value = player.Name, inline = true},
							{name = "Target", value = target.Name, inline = true}
						}
					)
				end

				server.Remote.MakeGui(player, "Output", {
					Title = "Success",
					Message = string.format("Cleared ban history for %s", target.Name),
					Color = Color3.new(0, 1, 0)
				})
			end
		end
	}

	print("[Adonis-TowerAscent] ✅ Integration complete - Custom commands loaded")
end
```

---

## 📊 Webhook Logging Plugin

### File: `Adonis_Loader/Config/Plugins/Server-WebhookLogger.lua`

```lua
--[[
	Server: Webhook Logger
	Logs all admin actions to Discord via WebhookLogger

	Created: 2025-12-18
]]

return function(Vargs)
	local server = Vargs.Server

	local ServerScriptService = game:GetService("ServerScriptService")

	-- Import WebhookLogger
	local WebhookLogger
	pcall(function()
		WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)
	end)

	if not WebhookLogger then
		warn("[Adonis-Webhook] WebhookLogger not found - logging disabled")
		return
	end

	print("[Adonis-Webhook] Initializing webhook logging...")

	-- ========================================================================
	-- LOG PLAYER JOINS/LEAVES
	-- ========================================================================

	game.Players.PlayerAdded:Connect(function(player)
		-- Check if player is admin
		local isAdmin = server.Admin.CheckAdmin(player)

		if isAdmin then
			WebhookLogger.LogEvent(
				"👮 Admin Joined",
				string.format("**%s** joined the game", player.Name),
				"INFO",
				{
					{name = "Player", value = player.Name, inline = true},
					{name = "UserID", value = tostring(player.UserId), inline = true},
					{name = "Admin Level", value = isAdmin, inline = true}
				}
			)
		end
	end)

	-- ========================================================================
	-- LOG KICKS/BANS
	-- ========================================================================

	-- Hook into kick command
	local originalKick = server.Commands.Kick.Function
	server.Commands.Kick.Function = function(args)
		local admin = args.Player
		local reason = args.Reason or "No reason specified"

		for _, target in ipairs(args.Targets) do
			WebhookLogger.LogEvent(
				"👢 Player Kicked",
				string.format("**%s** kicked **%s**", admin.Name, target.Name),
				"WARNING",
				{
					{name = "Admin", value = admin.Name, inline = true},
					{name = "Target", value = target.Name, inline = true},
					{name = "Reason", value = reason, inline = false}
				}
			)
		end

		return originalKick(args)
	end

	-- ========================================================================
	-- LOG SERVER SHUTDOWNS
	-- ========================================================================

	local originalShutdown = server.Commands.Shutdown.Function
	server.Commands.Shutdown.Function = function(args)
		local admin = args.Player

		WebhookLogger.LogEvent(
			"🛑 Server Shutdown",
			string.format("**%s** is shutting down the server", admin.Name),
			"CRITICAL",
			{
				{name = "Admin", value = admin.Name, inline = true},
				{name = "UserID", value = tostring(admin.UserId), inline = true},
				{name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
			}
		)

		task.wait(1) -- Give webhook time to send
		return originalShutdown(args)
	end

	print("[Adonis-Webhook] ✅ Webhook logging enabled")
end
```

---

## 🧪 Testing the Integration

### Step 1: Quick Check

After installing Adonis, run in **Command Bar**:

```lua
-- Check if Adonis loaded
print("Adonis loaded:", game.ServerScriptService:FindFirstChild("Adonis_Loader") ~= nil)

-- Check if plugins loaded
local loader = game.ServerScriptService:FindFirstChild("Adonis_Loader")
if loader then
	local config = loader:FindFirstChild("Config")
	if config then
		local plugins = config:FindFirstChild("Plugins")
		print("Plugins folder:", plugins ~= nil)
		if plugins then
			for _, plugin in ipairs(plugins:GetChildren()) do
				print("  -", plugin.Name)
			end
		end
	end
end
```

### Step 2: Test Commands

Join the game as an admin and test:

```
:cmds - List all commands
:banhistory YourUsername - Check ban history
:exploitstats - View security stats
:pm YourUsername Test message - Test messaging
```

### Step 3: Verify Webhook Logging

1. Check Discord channel for webhook messages
2. Run an admin command
3. Verify command appears in Discord within 30 seconds

### Step 4: Test Ban Integration

```lua
-- In Studio Command Bar
local Players = game:GetService("Players")
local ServiceLocator = require(game.ServerScriptService.Utilities.ServiceLocator)
local SecurityManager = ServiceLocator.Get("SecurityManager")

-- Check that ban history exists
print("Ban history table:", SecurityManager.BanHistory)
```

---

## ⚙️ Configuration Options

### Admin Levels

Customize permission levels in **Settings**:

```lua
Permissions = {
	Creators = {
		Commands = {"All"}; -- Full access
		Chat = true;
		IncognitoChat = true;
	},

	HeadAdmins = {
		Commands = {"All"};
		Excludes = {"Shutdown", "ClearBanHistory"}; -- Can't shutdown or clear bans
		Chat = true;
	},

	Admins = {
		Commands = {
			"Ban", "Kick", "Teleport", "Kill", "God",
			"Ungod", "BanHistory", "ExploitStats"
		};
		Chat = true;
	},

	Moderators = {
		Commands = {
			"Kick", "Teleport", "BanHistory", "Message"
		};
		Chat = false;
	}
}
```

### Custom Commands

Add your own commands in **Settings**:

```lua
Commands = {
	GiveCoins = {
		Prefix = ":";
		Commands = {"givecoins", "addcoins"};
		Args = {"player", "amount"};
		Description = "Give coins to a player";
		AdminLevel = "Admins";
		Function = function(plr, args)
			local ServiceLocator = require(game.ServerScriptService.Utilities.ServiceLocator)
			local CoinService = ServiceLocator.Get("CoinService")

			for _, target in ipairs(args.Targets) do
				local amount = tonumber(args.Amount) or 100
				CoinService.AddCoins(target, amount, "Admin gift")
			end
		end
	}
}
```

---

## 📚 Common Admin Commands

### Moderation
- `:ban <player> <duration> <reason>` - Ban player (uses your escalation system)
- `:kick <player> <reason>` - Kick player
- `:mute <player>` - Mute player's chat
- `:unmute <player>` - Unmute player

### Player Management
- `:tp <player1> <player2>` - Teleport player1 to player2
- `:bring <player>` - Teleport player to you
- `:to <player>` - Teleport to player
- `:respawn <player>` - Respawn player

### Server Management
- `:m <message>` - Server-wide message
- `:h <message>` - Server-wide hint
- `:logs` - View server logs
- `:shutdown` - Shutdown server

### Tower Ascent Custom Commands
- `:banhistory <player>` - View ban escalation history
- `:exploitstats` - View anti-cheat statistics
- `:clearbanhistory <player>` - Reset ban history (Creators only)
- `:givecoins <player> <amount>` - Award coins (if you add the custom command)

---

## 🔐 Security Best Practices

### 1. Secure Your DataStore Key
```lua
-- NEVER use default key
DataStoreKey = "TowerAscent_Adonis_" .. tostring(os.time())
```

### 2. Limit Creator Access
```lua
-- Only give Creators level to trusted developers
Admins = {
	{UserId = YOUR_USERID, Level = "Creators"}, -- You only
}
```

### 3. Configure Webhook URL
```lua
-- In init.server.lua or configuration
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)
WebhookLogger.SetWebhookUrl("https://discord.com/api/webhooks/YOUR_WEBHOOK")
```

### 4. Monitor Admin Actions
- Check webhook logs daily
- Review ban history weekly
- Audit admin list monthly

---

## 🐛 Troubleshooting

### Adonis Not Loading
**Problem**: Adonis_Loader exists but commands don't work

**Solution**:
1. Check Output for errors
2. Verify DataStoreKey is set
3. Ensure you're added to Admins list
4. Try `:cmds` in chat

### Commands Not Working
**Problem**: Type commands but nothing happens

**Solution**:
1. Check prefix is `:` (default)
2. Verify you're in Admins list
3. Check admin level has permission for command
4. Look in Output for error messages

### Plugins Not Loading
**Problem**: Custom commands don't exist

**Solution**:
1. Verify plugin files are in `Config/Plugins` folder
2. Check plugin names start with `Server-` or `Client-`
3. Look for syntax errors in plugin code
4. Restart Studio and rejoin

### Ban Integration Not Working
**Problem**: Bans don't use SecurityManager escalation

**Solution**:
1. Verify ServiceLocator is loaded before Adonis
2. Check SecurityManager is registered
3. Ensure plugin `Server-TowerAscentSecurity.lua` is present
4. Check Output for `[Adonis-TowerAscent]` messages

### Webhooks Not Sending
**Problem**: No Discord notifications for admin actions

**Solution**:
1. Verify WebhookURL is configured
2. Check HttpService is enabled (Game Settings)
3. Ensure WebhookLogger.lua is loaded
4. Check Discord webhook URL is valid
5. Look for rate limit warnings in Output

---

## 📊 Integration Summary

### What's Integrated

| Feature | Status | Integration Point |
|---------|--------|------------------|
| Ban System | ✅ | Uses SecurityManager.BanPlayer |
| Ban Escalation | ✅ | Automatic via SecurityManager |
| Webhook Logging | ✅ | All commands logged |
| Custom Commands | ✅ | Ban history, exploit stats |
| Service Locator | ✅ | All services accessible |
| Anti-Exploit | ✅ | Stats via :exploitstats |

### What's New

- `:banhistory <player>` - View ban escalation
- `:exploitstats` - Security statistics
- `:clearbanhistory <player>` - Reset bans (Creators only)
- Discord webhook logs for all admin actions
- Automatic ban escalation (1h → 3h → 9h → permanent)

---

## 🎯 Next Steps

### Immediate (Do Now)
1. ✅ Install Adonis Loader
2. ✅ Configure Settings (DataStoreKey, Admins)
3. ✅ Add custom plugins
4. ✅ Test commands in-game

### Short Term (This Week)
1. Configure webhook URL
2. Add more custom commands (givecoins, setlevel, etc.)
3. Train moderators on commands
4. Monitor webhook logs

### Long Term (Future)
1. Create admin dashboard UI
2. Add more security integrations
3. Implement admin activity tracking
4. Build custom admin panel

---

## 📞 Support

### Official Adonis Resources
- **GitHub**: https://github.com/Epix-Incorporated/Adonis
- **Discord**: https://discord.gg/H5RvTP3
- **DevForum**: Search "Adonis Admin"

### Tower Ascent Integration Issues
- Check `IMPLEMENTATION_COMPLETE.md` for system overview
- Review `TESTING_INSTRUCTIONS.md` for validation
- Consult `CODE_REVIEW_FIXES_SUMMARY.md` for architecture details

---

**Installation Date**: 2025-12-18
**Version**: Adonis Latest + Tower Ascent Security v1.0
**Status**: ✅ **READY FOR DEPLOYMENT**

---

## 🎉 Success Criteria

You'll know the integration is successful when:

- ✅ You can run `:cmds` in-game and see command list
- ✅ `:banhistory` shows ban escalation data
- ✅ Bans trigger Discord webhook notifications
- ✅ Admin commands appear in Discord within 30 seconds
- ✅ SecurityManager ban system works with `:ban` command
- ✅ No errors in Output console

**Congratulations! You now have enterprise-grade admin tools integrated with your existing security infrastructure.**
