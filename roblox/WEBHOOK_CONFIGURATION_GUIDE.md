# Discord Webhook Configuration Guide

**Step-by-step guide to enable Discord notifications for admin actions.**

---

## 📋 What You'll Get

After configuring webhooks, you'll receive Discord notifications for:
- ✅ Every admin command executed
- ✅ Player kicks with reason and admin name
- ✅ Server shutdowns
- ✅ Bans with escalation info
- ✅ Admin joins/leaves
- ✅ Critical security events

**Example Notification:**
```
🔧 Admin Command
PlayerName executed admin command

Admin: PlayerName
UserID: 123456789
Command: :ban ExploiterName 1h Cheating
Time: 14:23:45
```

---

## 🚀 Step 1: Create Discord Webhook (5 minutes)

### Option A: Using Discord Desktop/Web

1. **Open Discord** and go to your server
2. **Open Server Settings**:
   - Click server name → Server Settings
   - Or right-click server icon → Server Settings

3. **Navigate to Integrations**:
   - Left sidebar → Click "Integrations"

4. **Create Webhook**:
   - Click "Webhooks" section
   - Click "New Webhook" button
   - A new webhook appears

5. **Configure Webhook**:
   - **Name**: "Tower Ascent Logs" (or whatever you want)
   - **Channel**: Select the channel for logs (e.g., #admin-logs)
   - **Avatar**: Optional - upload an icon

6. **Copy Webhook URL**:
   - Click "Copy Webhook URL" button
   - **IMPORTANT**: Save this URL somewhere safe!
   - It looks like: `https://discord.com/api/webhooks/1234567890/ABCdef123...`

7. **Save**:
   - Click "Save Changes"

### Option B: Create a Dedicated Channel First (Recommended)

1. **Create new channel**:
   - Right-click your server → Create Channel
   - Name: "admin-logs" or "tower-ascent-logs"
   - Make it private (only admins can see)
   - Click Create

2. **Set Permissions**:
   - Click channel settings (gear icon)
   - Permissions tab
   - Make sure only admins can view
   - Save

3. **Create Webhook** (follow Option A steps above)

---

## 🔧 Step 2: Configure Webhook in Game (5 minutes)

### Method 1: Add to Initialization Script (Recommended)

1. **Find your game's main initialization script**:
   - Usually in `ServerScriptService`
   - Might be named: `init.server.lua`, `Main.server.lua`, or similar
   - If you don't have one, create a new Script in ServerScriptService

2. **Add this code** at the top (after services):

```lua
-- ========================================================================
-- WEBHOOK CONFIGURATION
-- ========================================================================

local ServerScriptService = game:GetService("ServerScriptService")

-- Load WebhookLogger
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

-- Configure webhook URL
-- REPLACE WITH YOUR ACTUAL WEBHOOK URL:
local WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

-- Set the webhook URL
WebhookLogger.SetWebhookUrl(WEBHOOK_URL)

print("[Game] ✅ Webhook configured and ready")
```

3. **Replace the URL**:
   - Change `YOUR_WEBHOOK_URL_HERE` to your actual webhook URL
   - Keep the quotes around it!

4. **Save** (Ctrl+S)

### Method 2: Modify WebhookLogger Directly (Not Recommended)

**Only use if you don't have an init script**

1. Open: `ServerScriptService → Utilities → WebhookLogger`
2. Find the `WEBHOOK_URL` variable at the top
3. Replace the default URL with yours
4. Save (Ctrl+S)

**Note**: This method is not recommended because updates might overwrite your URL.

---

## 🧪 Step 3: Enable HttpService (CRITICAL!)

**Webhooks won't work without this!**

1. **In Roblox Studio**:
   - Top menu → Home tab
   - Click "Game Settings" button (or press Ctrl+Shift+P)

2. **Navigate to Security**:
   - Left sidebar → "Security" section

3. **Enable HTTP**:
   - Find: "Allow HTTP Requests"
   - **Check the box** ✅
   - This allows your game to send data to Discord

4. **Save**:
   - Click "Save" at bottom
   - Close Game Settings

**Security Note**: This is safe - it allows your game to make web requests to Discord. Your webhook URL is private.

---

## ✅ Step 4: Test the Webhook (5 minutes)

### Test 1: Direct Test in Studio

1. **Open Command Bar** (View → Command Bar)
2. **Paste this code**:

```lua
local WebhookLogger = require(game.ServerScriptService.Utilities.WebhookLogger)
WebhookLogger.LogEvent(
    "🧪 Test Event",
    "This is a test notification from Tower Ascent!",
    "INFO",
    {
        {name = "Status", value = "Testing webhooks", inline = true},
        {name = "Time", value = os.date("%H:%M:%S"), inline = true}
    }
)
print("Test webhook sent!")
```

3. **Press Enter** to execute
4. **Check Discord** - you should see a message within 30 seconds!

**Expected Result in Discord:**
```
🧪 Test Event
This is a test notification from Tower Ascent!

Status: Testing webhooks
Time: 14:23:45
```

### Test 2: Test via Admin Command

1. **Play the game** (F5)
2. **In chat, type**: `:m Testing webhook`
3. **Check Discord** - should see notification of admin command

**Expected Result:**
```
🔧 Admin Command
YourName executed admin command

Admin: YourName
UserID: 123456789
Command: :m Testing webhook
Time: 14:23:45
```

### Test 3: Test Ban Notification

1. **In chat, type**: `:banhistory YourUsername`
2. **Check Discord** - should see the command logged

---

## 🐛 Troubleshooting

### "No messages appearing in Discord"

**Checklist:**
- [ ] HttpService enabled? (Game Settings → Security)
- [ ] Webhook URL correct? (no typos, copied fully)
- [ ] Discord webhook not deleted?
- [ ] Check Output console for errors

**Common Errors in Output:**

**Error**: `HTTP 404 (Not Found)`
- **Cause**: Webhook URL is wrong or webhook was deleted
- **Fix**: Re-create webhook, copy new URL

**Error**: `HttpService is not allowed`
- **Cause**: HttpService not enabled
- **Fix**: Game Settings → Security → Enable HTTP Requests

**Error**: `HTTP 429 (Too Many Requests)`
- **Cause**: Rate limited by Discord (30 requests/minute)
- **Fix**: This is normal if many commands run quickly. WebhookLogger batches them.

### "Messages delayed by 30+ seconds"

**This is normal!** WebhookLogger batches messages to avoid rate limits.

- Batches sent every 2 seconds
- Up to 10 messages per batch
- Max 30 requests per minute (Discord limit)

**To flush immediately** (for testing):
```lua
-- In Command Bar:
local WebhookLogger = require(game.ServerScriptService.Utilities.WebhookLogger)
WebhookLogger.FlushQueue()
```

### "Some commands logged, some aren't"

**Check configuration** in `Server-WebhookLogger.lua`:

```lua
local CONFIG = {
    LogAllCommands = true,  -- Set to true to log everything

    IgnoredCommands = {
        "cmds", "h", "m"  -- These won't be logged (too spammy)
    },
}
```

**To log everything**:
- Set `LogAllCommands = true`
- Set `IgnoredCommands = {}` (empty)

---

## 🎨 Customization

### Change Webhook Name/Avatar

1. **In Discord**:
   - Server Settings → Integrations → Webhooks
   - Click your webhook
   - Change name/avatar
   - Save

### Change Message Colors

Colors are based on severity:

- **INFO** (Blue): General information
- **WARNING** (Yellow): Kicks, suspicious activity
- **CRITICAL** (Red): Bans, shutdowns, exploits

**To customize**, edit `WebhookLogger.lua`:

```lua
local SEVERITY_COLORS = {
    INFO = 3447003,      -- Blue
    WARNING = 16776960,  -- Yellow
    CRITICAL = 16711680, -- Red
}
```

### Filter Specific Commands

**In `Server-WebhookLogger.lua`**, modify:

```lua
local CONFIG = {
    LogAllCommands = false,  -- Don't log everything

    -- Only log these important commands:
    ImportantCommands = {
        "ban", "kick", "shutdown", "clearbanhistory"
    },

    -- Never log these (too spammy):
    IgnoredCommands = {
        "cmds", "h", "m", "pm", "to", "bring"
    },
}
```

---

## 📊 What Gets Logged

### Always Logged (Can't Disable)
- ✅ Server startup
- ✅ Server shutdown (by admin)
- ✅ Critical errors

### Configurable (Based on Settings)
- ⚙️ Admin commands (all or filtered)
- ⚙️ Player kicks
- ⚙️ Bans (with escalation info)
- ⚙️ Admin joins/leaves
- ⚙️ Place teleports

### From SecurityManager Integration
- ✅ Ban escalations
- ✅ Exploit detections (from AntiExploit)
- ✅ Security violations

---

## 🔒 Security Best Practices

### Protect Your Webhook URL

**DO:**
- ✅ Keep webhook URL private
- ✅ Only share with trusted developers
- ✅ Store in secure script (not accessible to players)
- ✅ Use private Discord channel for logs

**DON'T:**
- ❌ Share webhook URL publicly
- ❌ Commit webhook URL to public GitHub
- ❌ Store in client-side scripts
- ❌ Post screenshots showing full URL

### If Webhook URL Compromised

1. **Delete old webhook immediately**:
   - Discord → Server Settings → Integrations → Webhooks
   - Click webhook → Delete

2. **Create new webhook** (follow Step 1 again)

3. **Update game** with new URL

4. **Publish game** so old servers update

### Limit Channel Access

- Only admins should see the logs channel
- Set permissions to restrict access
- Consider separate channels for different severity levels

---

## 📈 Advanced Configuration

### Multiple Webhooks for Different Events

```lua
-- In initialization script
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

-- Main webhook for general logs
WebhookLogger.SetWebhookUrl("https://discord.com/api/webhooks/MAIN_WEBHOOK")

-- Could extend WebhookLogger to support multiple URLs for different events
-- (Requires custom modification to WebhookLogger.lua)
```

### Create Custom Log Events

```lua
-- Example: Log when player reaches level 100
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

Players.PlayerAdded:Connect(function(player)
    -- When player levels up to 100
    if playerLevel == 100 then
        WebhookLogger.LogEvent(
            "🎉 Level 100 Achieved",
            string.format("**%s** reached level 100!", player.Name),
            "INFO",
            {
                {name = "Player", value = player.Name, inline = true},
                {name = "UserID", value = tostring(player.UserId), inline = true},
                {name = "Time", value = os.date("%H:%M:%S"), inline = true}
            }
        )
    end
end)
```

---

## ✅ Verification Checklist

Your webhook is properly configured when:

- [ ] HttpService enabled in Game Settings
- [ ] Webhook URL configured in game code
- [ ] Test message appears in Discord
- [ ] Admin commands logged to Discord
- [ ] No errors in Output console
- [ ] Messages arrive within 30 seconds
- [ ] Discord channel only visible to admins

---

## 📞 Support

### Discord Webhook Issues
- **Discord Guide**: https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
- **Rate Limits**: https://discord.com/developers/docs/topics/rate-limits

### WebhookLogger Issues
- Check: `WebhookLogger.lua` source code
- Review: `ADONIS_INTEGRATION_GUIDE.md`
- Test: `WebhookLogger.FlushQueue()` in Command Bar

### Common Questions

**Q: Can players see webhook messages?**
A: No, only Discord users in your server can see them.

**Q: Do webhooks work in published games?**
A: Yes! Just make sure HttpService is enabled.

**Q: How many webhooks can I create?**
A: Discord allows up to 10 webhooks per channel.

**Q: Can I use one webhook for multiple games?**
A: Yes, but it's better to use separate webhooks to identify which game sent the message.

---

## 🎉 Success!

If you've completed all steps and see messages in Discord, **congratulations!**

You now have:
- ✅ Real-time Discord notifications
- ✅ Complete audit trail of admin actions
- ✅ Security event monitoring
- ✅ Automatic logging for all critical events

**Your moderation team can now monitor the game from Discord! 🚀**

---

**Last Updated**: 2025-12-18
**Estimated Time**: 15 minutes
**Difficulty**: Easy
**Status**: Ready to configure!
