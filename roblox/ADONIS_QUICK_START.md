# Adonis Admin - Quick Start Guide

**Get Adonis admin system running in 15 minutes!**

---

## ⚡ Quick Installation (5 Steps)

### Step 1: Install Adonis Loader (2 minutes)

1. Open your Tower Ascent game in Roblox Studio
2. Open **Toolbox** (View → Toolbox)
3. Click **Models** tab
4. Search: **"Adonis Loader"** by Sceleratis
5. Click to insert into **ServerScriptService**

✅ **Done!** You should see `Adonis_Loader` in ServerScriptService

---

### Step 2: Configure Security (3 minutes)

1. Open: `ServerScriptService → Adonis_Loader → Config → Settings`
2. Find the `Settings` table
3. Change `DataStoreKey`:

```lua
-- CHANGE THIS LINE:
DataStoreKey = "CHANGE_THIS_KEY";

-- TO SOMETHING RANDOM LIKE:
DataStoreKey = "TowerAscent_2025_" .. math.random(10000, 99999);
```

4. **Save the file** (Ctrl+S)

✅ **Done!** Your admin system is now secure

---

### Step 3: Add Yourself as Admin (3 minutes)

1. Still in the `Settings` module
2. Find your **UserID**:
   - Go to: https://www.roblox.com/users/YOUR_PROFILE/profile
   - Look at URL: `https://www.roblox.com/users/123456789/profile`
   - Your UserID is the number: `123456789`

3. Add yourself to the `Admins` table:

```lua
Admins = {
	-- Add this line with YOUR UserID:
	{
		UserId = 123456789, -- ← Replace with your actual UserID
		Level = "Creators", -- Highest level
	},
}
```

4. **Save the file** (Ctrl+S)

✅ **Done!** You're now an admin

---

### Step 4: Install Tower Ascent Plugins (5 minutes)

1. Go to the folder: `/mnt/e/projects/roblox/adonis-plugins/`
2. You'll find two files:
   - `Server-TowerAscentSecurity.lua`
   - `Server-WebhookLogger.lua`

3. In Roblox Studio:
   - Right-click: `Adonis_Loader → Config → Plugins`
   - Select **"Insert from File..."**
   - Choose `Server-TowerAscentSecurity.lua`
   - Repeat for `Server-WebhookLogger.lua`

4. **Verify**: You should now see both files in the Plugins folder

✅ **Done!** Tower Ascent integration complete

---

### Step 5: Test It! (2 minutes)

1. Click **Play** (F5) in Studio
2. Wait for game to load
3. In the chat, type: **`:cmds`**

**Expected Result:**
- A GUI opens showing all available commands
- You should see custom commands: `:banhistory`, `:exploitstats`

4. Test custom command: **`:exploitstats`**

**Expected Result:**
- Shows security system status
- Lists active services (SecurityManager, AntiExploit, etc.)

✅ **Done!** Adonis is working!

---

## 🎮 Essential Commands

### Your First Commands to Try

```
:cmds                    - List all commands
:exploitstats           - View security status
:banhistory YourName    - Check ban history
:to YourFriend          - Teleport to player
:bring YourFriend       - Bring player to you
```

### Important Commands

**Moderation:**
```
:ban PlayerName 1h Reason    - Ban for 1 hour (uses escalation!)
:kick PlayerName Reason      - Kick player
:mute PlayerName             - Mute player chat
:unmute PlayerName           - Unmute player
```

**Teleportation:**
```
:tp Player1 Player2     - Teleport Player1 to Player2
:to PlayerName          - Teleport yourself to player
:bring PlayerName       - Bring player to you
```

**Communication:**
```
:m Message here         - Server-wide message
:h Hint text           - Server-wide hint
:pm PlayerName Message  - Private message
```

**Server Management:**
```
:shutdown              - Shutdown server (Creators only)
:place PlaceID         - Teleport to another place
:logs                  - View server logs
```

### Tower Ascent Custom Commands

**Security Commands:**
```
:banhistory PlayerName         - View ban escalation history
:exploitstats                  - View anti-cheat statistics
:clearbanhistory PlayerName    - Reset ban history (Creators only)
:checkservice ServiceName      - Check if a service is loaded
```

---

## 🔧 Configuration

### Change Command Prefix

Default prefix is `:` but you can change it:

In `Settings` module:
```lua
Prefix = ":";     -- Change to "!", ";", etc.
```

### Add More Admins

```lua
Admins = {
	-- By UserID (Recommended)
	{UserId = 123456789, Level = "Creators"},
	{UserId = 987654321, Level = "Admins"},
	{UserId = 555555555, Level = "Moderators"},

	-- By Group Rank
	{
		GroupId = 12345678,      -- Your group ID
		GroupRank = 255,         -- Rank 255
		Level = "Creators",
	},

	-- By Gamepass
	{
		Gamepass = 12345678,     -- Your gamepass ID
		Level = "Moderators",
	},
}
```

### Enable Webhook Notifications

1. Get Discord webhook URL:
   - Discord → Server Settings → Integrations → Webhooks
   - Click "New Webhook"
   - Copy webhook URL

2. In your game's initialization script:
```lua
local WebhookLogger = require(game.ServerScriptService.Utilities.WebhookLogger)
WebhookLogger.SetWebhookUrl("https://discord.com/api/webhooks/YOUR_URL_HERE")
```

3. Test it by running an admin command - you should see it in Discord!

---

## 📋 Admin Permission Levels

From highest to lowest:

| Level | Access |
|-------|--------|
| **Creators** | Everything (owner level) |
| **HeadAdmins** | Most commands (can't shutdown) |
| **Admins** | Standard moderation commands |
| **Moderators** | Basic kick/mute/teleport |
| **Players** | No admin commands |

---

## 🐛 Troubleshooting

### "Commands don't work when I type them"

**Fix:**
1. Make sure you're in the `Admins` list (check Settings module)
2. Verify you used the correct prefix (default is `:`)
3. Check Output console for errors
4. Try typing: `:cmds` to see if you're an admin

### "I'm not in the admin list"

**Fix:**
1. Double-check your UserID
2. Make sure you saved the Settings module (Ctrl+S)
3. Restart the game (stop and play again)
4. Verify syntax: `{UserId = 123456789, Level = "Creators"},`

### "Custom commands (:banhistory, :exploitstats) don't exist"

**Fix:**
1. Check that plugin files are in: `Adonis_Loader/Config/Plugins/`
2. Verify file names start with `Server-`
3. Check for script errors in Output console
4. Restart Studio and try again

### "Webhooks aren't sending to Discord"

**Fix:**
1. Enable HttpService: Game Settings → Security → Allow HTTP Requests ✅
2. Verify webhook URL is correct (no typos)
3. Check Discord webhook settings (not deleted)
4. Look for errors in Output console
5. Test with: `WebhookLogger.FlushQueue()` in Command Bar

---

## ✅ Verification Checklist

After installation, verify everything works:

- [ ] `:cmds` shows command list
- [ ] `:exploitstats` shows security status
- [ ] `:banhistory YourName` shows your ban history (should be clean)
- [ ] `:to PlayerName` teleports you
- [ ] `:m Test` sends server message
- [ ] Custom commands appear in `:cmds` list
- [ ] Discord webhook receives admin command notifications (if configured)

---

## 🎯 What's Integrated

Your Adonis installation includes:

✅ **SecurityManager Integration**
- `:ban` command uses your existing ban escalation system
- Automatic progression: 1h → 3h → 9h → 27h → PERMANENT

✅ **WebhookLogger Integration**
- All admin commands logged to Discord
- Ban events, kicks, shutdowns tracked
- Real-time notifications

✅ **Custom Commands**
- `:banhistory` - View player ban escalation
- `:exploitstats` - Check security systems
- `:clearbanhistory` - Reset ban records (Creators only)
- `:checkservice` - Verify service availability

✅ **ServiceLocator Integration**
- All Tower Ascent services accessible
- Clean dependency management

---

## 📚 Next Steps

### Immediate:
1. ✅ Test all commands
2. ✅ Add other admins/moderators
3. ✅ Configure webhook URL (optional)

### Soon:
1. Read full guide: `ADONIS_INTEGRATION_GUIDE.md`
2. Learn advanced commands: https://github.com/Epix-Incorporated/Adonis
3. Customize permissions for your team

### Future:
1. Create custom commands for coin management
2. Build admin dashboard UI
3. Setup automated reports

---

## 💡 Pro Tips

**Command Shortcuts:**
- Most commands have aliases: `:banhistory` = `:banhist` = `:baninfo`
- Use Tab to autocomplete player names
- Use `:!` to run last command again

**Batch Operations:**
- Target multiple players: `:bring player1,player2,player3`
- Target by group: `:bring @admins`, `:bring @all`
- Target by team: `:bring %TeamName`

**Admin Chat:**
- Prefix messages with `/` for admin-only chat
- Example: `/This message is only visible to admins`

**View History:**
- `:logs` shows recent commands
- `:adminlogs` shows admin actions
- `:chatlogs` shows chat history

---

## 🆘 Support

**Adonis Support:**
- GitHub: https://github.com/Epix-Incorporated/Adonis
- Discord: https://discord.gg/H5RvTP3
- DevForum: Search "Adonis Admin"

**Tower Ascent Integration Issues:**
- Check: `ADONIS_INTEGRATION_GUIDE.md` for detailed info
- Review: `IMPLEMENTATION_COMPLETE.md` for system overview
- Run: `SecurityValidation.RunAllTests()` to verify systems

---

## 🎉 Success!

You now have a professional admin system integrated with your Tower Ascent security infrastructure!

**Key Features You Have:**
- 400+ moderation commands
- Discord webhook notifications
- Ban escalation system integration
- Real-time security monitoring
- Custom Tower Ascent commands

**Ready to moderate your game like a pro! 🚀**

---

**Installation Date**: 2025-12-18
**Version**: Adonis + Tower Ascent Security v1.0
**Status**: ✅ **PRODUCTION READY**
