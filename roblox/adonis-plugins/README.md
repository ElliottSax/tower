# Adonis Plugins for Tower Ascent

This folder contains custom Adonis plugins that integrate the admin system with Tower Ascent's security infrastructure.

---

## 📦 Included Plugins

### 1. Server-TowerAscentSecurity.lua

**Purpose**: Integrates Adonis with SecurityManager, WebhookLogger, and ServiceLocator

**Features:**
- ✅ Overrides `:ban` command to use SecurityManager ban escalation
- ✅ Adds `:banhistory <player>` command
- ✅ Adds `:exploitstats` command
- ✅ Adds `:clearbanhistory <player>` command (Creators only)
- ✅ Adds `:checkservice <name>` command
- ✅ Logs all admin commands to WebhookLogger

**Custom Commands:**

| Command | Description | Admin Level |
|---------|-------------|-------------|
| `:banhistory <player>` | View player's ban escalation history | Moderators |
| `:exploitstats` | View security system status | Admins |
| `:clearbanhistory <player>` | Reset player's ban history | Creators |
| `:checkservice <name>` | Check if a service is registered | Admins |

**Ban Escalation Integration:**

When you use `:ban <player>`, it automatically uses the SecurityManager ban escalation system:
- 1st offense: 1 hour
- 2nd offense: 3 hours
- 3rd offense: 9 hours
- 4th offense: 27 hours
- 5th+ offense: PERMANENT

---

### 2. Server-WebhookLogger.lua

**Purpose**: Logs all significant admin actions to Discord via WebhookLogger

**Features:**
- ✅ Logs all admin commands to Discord
- ✅ Logs player kicks with reason and admin info
- ✅ Logs server shutdowns with 2-second delay
- ✅ Logs place teleports
- ✅ Logs admin joins/leaves
- ✅ Configurable command filtering

**Logged Events:**

| Event | Severity | Details |
|-------|----------|---------|
| Admin Command | INFO | Command, admin name, timestamp |
| Player Kicked | WARNING | Target, admin, reason |
| Server Shutdown | CRITICAL | Admin, timestamp, JobId |
| Admin Joined | INFO | Admin name, level |
| Admin Left | INFO | Admin name, timestamp |

**Configuration:**

You can edit settings at the top of the file:

```lua
local CONFIG = {
	LogAllCommands = true,          -- Log every command
	LogAdminJoins = true,           -- Log when admins join/leave

	ImportantCommands = {           -- Always log these
		"ban", "kick", "shutdown"
	},

	IgnoredCommands = {             -- Never log these
		"cmds", "h", "m"            -- Too spammy
	},
}
```

---

## 🚀 Installation

### Quick Install:

1. **Copy plugin files**:
   - Copy both `.lua` files from this folder

2. **In Roblox Studio**:
   - Navigate to: `ServerScriptService → Adonis_Loader → Config → Plugins`
   - Right-click `Plugins` folder
   - Select "Insert from File..."
   - Insert both plugin files

3. **Verify installation**:
   - You should see both files in the Plugins folder:
     - `Server-TowerAscentSecurity`
     - `Server-WebhookLogger`

4. **Restart or rejoin**:
   - Stop the game and play again
   - Plugins will auto-load

5. **Test**:
   - Type `:exploitstats` in chat
   - Should see security system status

---

## ✅ Verification

After installation, check the **Output** console for:

```
[Adonis-TowerAscent] ✅ Security integration loaded
[Adonis-TowerAscent]   - ServiceLocator: OK
[Adonis-TowerAscent]   - SecurityManager: OK
[Adonis-TowerAscent]   - WebhookLogger: OK
[Adonis-TowerAscent]   - AntiExploit: OK
[Adonis-TowerAscent] ✅ Integration complete
[Adonis-TowerAscent] Custom commands added:
[Adonis-TowerAscent]   - :banhistory <player>
[Adonis-TowerAscent]   - :exploitstats
[Adonis-TowerAscent]   - :clearbanhistory <player> (Creators only)
[Adonis-TowerAscent]   - :checkservice <name>
[Adonis-TowerAscent]
[Adonis-TowerAscent] 🎉 Tower Ascent Security integration ready!

[Adonis-Webhook] ✅ Webhook logging initialized
[Adonis-Webhook]   - Command logging enabled
[Adonis-Webhook]   - Kick logging enabled
[Adonis-Webhook]   - Shutdown logging enabled
[Adonis-Webhook]   - Place teleport logging enabled
[Adonis-Webhook]   - Admin join/leave logging enabled
[Adonis-Webhook] ✅ Webhook logging ready
[Adonis-Webhook] Configuration:
[Adonis-Webhook]   - Log all commands: true
[Adonis-Webhook]   - Log admin joins: true
[Adonis-Webhook]
[Adonis-Webhook] 🎉 Discord notifications enabled!
```

---

## 🔧 Requirements

These plugins require the following Tower Ascent systems to be present:

### Required:
- ✅ `ServiceLocator.lua` in `ServerScriptService/Utilities/`
- ✅ `SecurityManager.lua` in `ServerScriptService/Security/`
- ✅ `WebhookLogger.lua` in `ServerScriptService/Utilities/`

### Optional:
- ⚠️ `AntiExploit.lua` in `ServerScriptService/Security/` (for `:exploitstats`)
- ⚠️ Other services (CoinService, DataService, etc.)

**Note**: Plugins will gracefully degrade if optional components are missing.

---

## 🧪 Testing

### Test SecurityManager Integration:

```lua
-- In Studio Command Bar:
local ServiceLocator = require(game.ServerScriptService.Utilities.ServiceLocator)
local SecurityManager = ServiceLocator.Get("SecurityManager")

-- Check ban history exists
print("Ban history table exists:", SecurityManager.BanHistory ~= nil)
```

### Test Custom Commands:

Join the game as an admin and test:

```
:exploitstats              - Should show security status
:banhistory YourUsername   - Should show clean record
:checkservice DataService  - Should show service info
```

### Test Webhook Logging:

1. Configure webhook URL in WebhookLogger
2. Run any admin command
3. Check Discord - should see notification within 30 seconds

---

## 🐛 Troubleshooting

### Plugins Not Loading

**Symptoms**: No output messages, custom commands don't work

**Solutions**:
1. Check file names start with `Server-`
2. Verify files are in correct folder: `Adonis_Loader/Config/Plugins/`
3. Check for syntax errors in Output console
4. Restart Studio completely

### SecurityManager Not Found

**Symptoms**: Ban command uses default Adonis ban, not escalation

**Solutions**:
1. Verify SecurityManager.lua exists
2. Check ServiceLocator is loaded before Adonis
3. Ensure SecurityManager calls `ServiceLocator.Register("SecurityManager", SecurityManager)`
4. Look for error: `[Adonis-TowerAscent] SecurityManager not available`

### WebhookLogger Not Logging

**Symptoms**: No Discord notifications

**Solutions**:
1. Verify webhook URL is configured: `WebhookLogger.SetWebhookUrl("...")`
2. Enable HttpService: Game Settings → Security → Allow HTTP Requests ✅
3. Check Output for: `[WebhookLogger] Webhook URL not configured`
4. Verify Discord webhook is active (not deleted)

### Commands Exist But Don't Work

**Symptoms**: `:banhistory` shows in `:cmds` but doesn't execute

**Solutions**:
1. Check your admin level (need Moderators+ for most commands)
2. Verify ServiceLocator has required services
3. Run `:checkservice SecurityManager` to verify systems
4. Look for errors in Output when running command

---

## 🔄 Updates

### Version 1.0 (2025-12-18)

**Initial Release**
- SecurityManager ban integration
- WebhookLogger integration
- Custom commands: banhistory, exploitstats, clearbanhistory, checkservice
- Admin action logging to Discord

**Future Enhancements:**
- [ ] `:givecoins <player> <amount>` command
- [ ] `:setlevel <player> <level>` command
- [ ] `:resetdata <player>` command (with confirmation)
- [ ] `:serverstats` showing player count, uptime, etc.
- [ ] Admin activity dashboard

---

## 📚 Documentation

### Full Documentation:
- **ADONIS_INTEGRATION_GUIDE.md** - Complete integration guide
- **ADONIS_QUICK_START.md** - 15-minute setup guide
- **IMPLEMENTATION_COMPLETE.md** - Overall system architecture

### Adonis Resources:
- **GitHub**: https://github.com/Epix-Incorporated/Adonis
- **Discord**: https://discord.gg/H5RvTP3
- **Wiki**: Check GitHub repository

---

## 💡 Customization

### Adding More Commands

Edit `Server-TowerAscentSecurity.lua` and add:

```lua
-- Example: Give coins command
server.Commands.GiveCoins = {
	Prefix = ":";
	Commands = {"givecoins", "addcoins"};
	Args = {"player", "number"};
	Description = "Give coins to a player";
	AdminLevel = "Admins";
	Function = function(args)
		local admin = args.Player
		local target = args.Targets[1]
		local amount = tonumber(args.Args[2]) or 100

		local CoinService = ServiceLocator.Get("CoinService")
		if CoinService and CoinService.AddCoins then
			CoinService.AddCoins(target, amount, "Admin gift")
			sendOutput(admin, "Success",
				string.format("Gave %d coins to %s", amount, target.Name),
				true)
		end
	end
}
```

### Changing Logged Events

Edit `Server-WebhookLogger.lua`:

```lua
-- To stop logging admin joins:
LogAdminJoins = false,

-- To log more commands:
ImportantCommands = {
	"ban", "kick", "shutdown", "teleport", "god"
},

-- To ignore more commands:
IgnoredCommands = {
	"cmds", "h", "m", "pm", "to"
},
```

---

## 🎯 Best Practices

### Security:
- ✅ Only give "Creators" level to trusted developers
- ✅ Use UserID-based admin assignment (not username)
- ✅ Monitor webhook logs daily for suspicious activity
- ✅ Review ban history weekly with `:banhistory`

### Moderation:
- ✅ Always provide ban reasons: `:ban player 1h Exploiting`
- ✅ Check ban history before banning: `:banhistory player`
- ✅ Use appropriate escalation - don't override duration unless necessary
- ✅ Log significant actions in Discord for team awareness

### Maintenance:
- ✅ Test commands after Adonis updates
- ✅ Review webhook logs for errors
- ✅ Keep plugin code backed up
- ✅ Document any custom modifications

---

## 🏆 Features at a Glance

| Feature | Server-TowerAscentSecurity | Server-WebhookLogger |
|---------|---------------------------|---------------------|
| Ban Escalation | ✅ | - |
| Custom Commands | ✅ (4 commands) | - |
| Webhook Logging | ✅ (commands only) | ✅ (all events) |
| ServiceLocator Integration | ✅ | - |
| Discord Notifications | - | ✅ |
| Admin Join/Leave Tracking | - | ✅ |
| Kick Logging | - | ✅ |
| Shutdown Logging | - | ✅ |

---

## 📞 Support

### Plugin Issues:
1. Check Output console for error messages
2. Verify all required files are present
3. Test with `:checkservice` command
4. Review ADONIS_INTEGRATION_GUIDE.md

### Feature Requests:
- Document desired features in your game's issue tracker
- Check Adonis documentation for existing solutions
- Consider customizing plugins (see Customization section)

---

**Plugin Version**: 1.0
**Created**: 2025-12-18
**Compatible With**: Adonis Latest, Tower Ascent Security v1.0
**Status**: ✅ **PRODUCTION READY**

---

**Installation is complete! Your Adonis admin system is now fully integrated with Tower Ascent's security infrastructure. 🎉**
