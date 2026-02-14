# Adonis Installation Checklist

**Use this checklist to track your installation progress.**

---

## 📋 Pre-Installation

- [ ] Backup your game files
- [ ] Read `ADONIS_QUICK_START.md` (you are here!)
- [ ] Have Roblox Studio open with Tower Ascent game loaded
- [ ] Know your Roblox UserID (get from profile URL)

**Your UserID**: __________________ (write it down!)

---

## 🔧 Step-by-Step Installation

### Part 1: Install Adonis Loader (5 minutes)

- [ ] Open Roblox Studio
- [ ] Open your Tower Ascent game
- [ ] Open Toolbox (View → Toolbox)
- [ ] Click **Models** tab
- [ ] Search: "Adonis Loader" by Sceleratis
- [ ] Click the model to insert it
- [ ] **Verify**: Drag into **ServerScriptService** if not already there
- [ ] **Verify**: You see `Adonis_Loader` folder in ServerScriptService

**If stuck**: The Adonis Loader should be a blue script icon with a folder inside it.

---

### Part 2: Configure Security (5 minutes)

- [ ] In Explorer, navigate to: `ServerScriptService → Adonis_Loader → Config → Settings`
- [ ] Double-click `Settings` to open the module
- [ ] Find line with: `DataStoreKey = "CHANGE_THIS_KEY"`
- [ ] Change it to something random:

**Example**:
```lua
DataStoreKey = "TowerAscent_2025_54823"
```

**Your DataStoreKey**: __________________ (write it down for reference!)

- [ ] Press **Ctrl+S** to save
- [ ] **Verify**: File name in tab should NOT have asterisk (*) - means it's saved

**Security Note**: Never use the default key! This prevents unauthorized access.

---

### Part 3: Add Yourself as Admin (5 minutes)

**First, get your UserID:**
- [ ] Go to your Roblox profile: https://www.roblox.com/users/YOUR_NAME/profile
- [ ] Look at the URL, it should be: `https://www.roblox.com/users/123456789/profile`
- [ ] The number (123456789) is your UserID
- [ ] **Write it down**: My UserID is: __________________

**Now add yourself to the admin list:**
- [ ] Still in the `Settings` module, scroll down to find the `Admins = {` table
- [ ] You'll see examples or placeholders
- [ ] Add this code (replace 123456789 with YOUR UserID):

```lua
Admins = {
	{
		UserId = 123456789,  -- ← YOUR USERID HERE
		Level = "Creators",
	},
}
```

- [ ] Press **Ctrl+S** to save
- [ ] **Verify**: Your UserID is correct (no typos)
- [ ] **Verify**: Comma after `Level = "Creators",` exists
- [ ] **Verify**: File saved (no asterisk in tab name)

**Common Mistake**: Make sure you use **UserId** (capital I in Id), not UserID or userid.

---

### Part 4: Install Tower Ascent Plugins (5-10 minutes)

**Locate the plugin files:**
- [ ] Open File Explorer (Windows Explorer)
- [ ] Navigate to: `E:\projects\roblox\adonis-plugins\`
- [ ] **Verify**: You see these two files:
  - `Server-TowerAscentSecurity.lua`
  - `Server-WebhookLogger.lua`

**Install Plugin 1: Security Integration**
- [ ] In Roblox Studio Explorer, navigate to: `ServerScriptService → Adonis_Loader → Config → Plugins`
- [ ] Right-click on the `Plugins` folder
- [ ] Select **"Insert from File..."**
- [ ] Navigate to `E:\projects\roblox\adonis-plugins\`
- [ ] Select `Server-TowerAscentSecurity.lua`
- [ ] Click **Open**
- [ ] **Verify**: You see `Server-TowerAscentSecurity` in the Plugins folder

**Install Plugin 2: Webhook Logger**
- [ ] Right-click on the `Plugins` folder again
- [ ] Select **"Insert from File..."**
- [ ] Select `Server-WebhookLogger.lua`
- [ ] Click **Open**
- [ ] **Verify**: You see `Server-WebhookLogger` in the Plugins folder

**Final Verification:**
- [ ] Plugins folder contains exactly 2 new scripts:
  - `Server-TowerAscentSecurity`
  - `Server-WebhookLogger`
- [ ] Both are **ModuleScript** type (gray icon with "Lua" text)

---

### Part 5: First Test (5 minutes)

**Start the game:**
- [ ] Press **F5** or click **Play** button
- [ ] Wait for game to fully load
- [ ] Watch the **Output** window (View → Output if not visible)

**Check Output for success messages:**
- [ ] Look for: `[Adonis-TowerAscent] ✅ Security integration loaded`
- [ ] Look for: `[Adonis-TowerAscent] ✅ Integration complete`
- [ ] Look for: `[Adonis-Webhook] ✅ Webhook logging initialized`
- [ ] **No red errors** related to Adonis or plugins

**Test in-game:**
- [ ] In the game chat, type: `:cmds`
- [ ] **Expected**: GUI opens showing command list
- [ ] **Expected**: GUI has "Search" bar at top
- [ ] **Expected**: You see many commands listed

**Test custom commands:**
- [ ] Type in chat: `:exploitstats`
- [ ] **Expected**: GUI shows security status
- [ ] **Expected**: Shows "SecurityManager: Online" (or similar)

**Test ban history:**
- [ ] Type in chat: `:banhistory YourUsername`
- [ ] **Expected**: Shows "clean record" or "no ban history"

**If ANY test fails, see Troubleshooting section below!**

---

## 🎯 Verification Checklist

After installation, verify all these work:

### Basic Adonis Commands
- [ ] `:cmds` - Shows command list
- [ ] `:m Test message` - Sends server message
- [ ] `:to YourUsername` - Tries to teleport to yourself (should work)

### Tower Ascent Custom Commands
- [ ] `:exploitstats` - Shows security system status
- [ ] `:banhistory YourUsername` - Shows your ban history (clean)
- [ ] `:checkservice SecurityManager` - Shows service is registered

### Integration Verification
- [ ] No errors in Output console
- [ ] ServiceLocator messages appear in Output
- [ ] SecurityManager loaded
- [ ] WebhookLogger loaded
- [ ] RemoteEventsInit loaded

---

## 🐛 Troubleshooting

### Issue: `:cmds` doesn't work

**Possible Causes:**
1. You're not in the Admins list
2. Wrong prefix (try `;cmds` or `!cmds`)
3. Settings not saved

**Fix:**
- [ ] Stop the game (press Stop button)
- [ ] Check Settings module - is your UserID there?
- [ ] Verify you saved (Ctrl+S)
- [ ] Check for syntax errors (red underlines in code)
- [ ] Restart Studio completely
- [ ] Try again

### Issue: Custom commands don't exist

**Check:**
- [ ] Are plugin files in the Plugins folder?
- [ ] Do file names start with `Server-`?
- [ ] Are they ModuleScript type (not Script)?
- [ ] Any errors in Output about plugins?

**Fix:**
- [ ] Re-insert plugin files
- [ ] Make sure files are in: `Adonis_Loader/Config/Plugins/`
- [ ] Restart Studio
- [ ] Check Output for error messages

### Issue: Red errors in Output

**Common errors and fixes:**

**Error**: `"Adonis_Loader.Config.Settings:XX: Expected identifier, got 'X'"`
- **Fix**: Syntax error in Settings module. Check commas, quotes, brackets.

**Error**: `"Unable to load module"`
- **Fix**: File path wrong or file missing. Re-insert plugins.

**Error**: `"[Adonis-TowerAscent] Failed to load Tower Ascent systems"`
- **Fix**: ServiceLocator or SecurityManager not found. Run `SecurityValidation.RunAllTests()` first.

### Issue: Game works but no integration messages

**This means:**
- Adonis works ✅
- Plugins didn't load ❌

**Fix:**
- [ ] Check Output for `[Adonis-TowerAscent]` messages
- [ ] Verify plugins are in Plugins folder
- [ ] Check file names start with `Server-`
- [ ] Look for script errors in plugins
- [ ] Re-insert plugins from file

---

## 🎓 Post-Installation

### Immediate Next Steps
- [ ] Test all custom commands
- [ ] Configure webhook URL (see below)
- [ ] Add other admins/moderators
- [ ] Train team on basic commands

### Configure Webhook (Optional but Recommended)
See `WEBHOOK_CONFIGURATION_GUIDE.md` for step-by-step

- [ ] Create Discord webhook
- [ ] Copy webhook URL
- [ ] Add to game initialization script
- [ ] Test webhook notifications

### Add More Admins
- [ ] Get UserIDs for team members
- [ ] Add to Admins table in Settings
- [ ] Assign appropriate levels (Creators, Admins, Moderators)
- [ ] Save and test

---

## 📊 Installation Complete Criteria

You're done when ALL of these are true:

- ✅ Adonis_Loader exists in ServerScriptService
- ✅ Settings module has custom DataStoreKey
- ✅ You're in the Admins table with Creators level
- ✅ Both plugins exist in Plugins folder
- ✅ `:cmds` works and shows command list
- ✅ `:exploitstats` shows security status
- ✅ `:banhistory YourUsername` shows clean record
- ✅ No red errors in Output console
- ✅ Integration messages appear in Output

---

## ✅ Success!

If all checkboxes above are marked, **congratulations!** 🎉

You now have:
- ✅ Professional admin system (400+ commands)
- ✅ Ban escalation integration
- ✅ Security monitoring
- ✅ Custom Tower Ascent commands
- ✅ Webhook logging (when configured)

**Next**: Read `ADONIS_INTEGRATION_GUIDE.md` for advanced features!

---

## 📞 Need Help?

**If you're stuck:**
1. Check the Troubleshooting section above
2. Review Output console for specific error messages
3. Re-read the Quick Start guide
4. Check Adonis Discord: https://discord.gg/H5RvTP3

**Common Resources:**
- Quick Start: `ADONIS_QUICK_START.md`
- Full Guide: `ADONIS_INTEGRATION_GUIDE.md`
- Plugin Docs: `adonis-plugins/README.md`

---

**Last Updated**: 2025-12-18
**Estimated Time**: 15-20 minutes
**Difficulty**: Easy
**Status**: Ready to start!

**Good luck with your installation! 🚀**
