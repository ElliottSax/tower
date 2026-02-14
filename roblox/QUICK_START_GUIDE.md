# Quick Start Guide - New Security Systems

## 🚀 Getting Started

All Priority 1, 2, and 3 fixes from the code review have been implemented. Here's how to use the new systems:

---

## 1. ServiceLocator Pattern

### Basic Usage

```lua
-- Get ServiceLocator
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)

-- Register a service
ServiceLocator.Register("MyService", MyService)

-- Get a service
local DataService = ServiceLocator.Get("DataService")
if DataService then
    DataService.GetCoins(player)
end

-- Wait for a service (useful during initialization)
local SecurityManager = ServiceLocator.WaitFor("SecurityManager", 10) -- 10 second timeout

-- Check if service exists
if ServiceLocator.Has("ParticleService") then
    print("ParticleService is available!")
end
```

### Migration from _G Pattern

**Before:**
```lua
local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
if BugReporter then
    BugReporter.ReportBug(...)
end
```

**After:**
```lua
local BugReporter = ServiceLocator.Get("BugReporter")
if BugReporter and BugReporter.ReportBug then
    BugReporter.ReportBug(...)
end
```

---

## 2. Secure RemoteEvents/Functions

### Adding a New Remote

**Step 1:** Add to `RemoteEventsInit.lua`

```lua
-- In RemoteEventsInit.Initialize()
local myRemoteFunction = SecureRemotes.CreateRemoteFunction("MyRemote", {
    MaxCallsPerSecond = 5, -- Rate limit
    TypeSchema = {"string", "number"}, -- Validate arguments
    ReturnSchema = "boolean" -- Validate return value
})

RemoteEventsInit.Remotes.MyRemote = myRemoteFunction
```

**Step 2:** Setup callback in your service

```lua
-- In your service Init() function
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
local myRemote = RemoteEventsInit.GetRemote("MyRemote")

myRemote:OnServerInvoke(function(player, stringArg, numberArg)
    -- Your logic here
    -- Arguments are already validated by SecureRemotes
    return true
end)
```

### Client Usage

```lua
-- Client-side (same as before)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local MyRemote = RemoteEvents:WaitForChild("MyRemote")
local result = MyRemote:InvokeServer("test", 123)
```

---

## 3. Webhook Logging

### Setup

```lua
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

-- Configure your Discord webhook URL
WebhookLogger.SetWebhookUrl("https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN")
```

### Usage

```lua
-- Log a security event
WebhookLogger.LogSecurityEvent("RATE_LIMIT_EXCEEDED", {
    Player = player.Name,
    UserId = player.UserId,
    Remote = "PurchaseUpgrade"
})

-- Log an exploit detection
WebhookLogger.LogExploitDetection(player, "SPEED_HACK", {
    Speed = 500,
    MaxSpeed = 100
})

-- Log a ban
WebhookLogger.LogBan(player, "Multiple security violations", 3600)

-- Log a critical error
WebhookLogger.LogCriticalError("DataStore failed", stackTrace)

-- Custom event
WebhookLogger.LogEvent(
    "Custom Event",
    "Something happened",
    "WARNING", -- Severity: INFO, WARNING, ERROR, CRITICAL, SECURITY
    {
        {name = "Field 1", value = "Value 1", inline = true},
        {name = "Field 2", value = "Value 2", inline = true}
    }
)
```

---

## 4. Ban Escalation System

### How It Works

The ban system now automatically escalates:

- **Offense 1:** 1 hour ban
- **Offense 2:** 3 hours ban (1h × 3^1)
- **Offense 3:** 9 hours ban (1h × 3^2)
- **Offense 4:** 27 hours ban (1h × 3^3)
- **Offense 5+:** PERMANENT BAN

### Configuration

```lua
-- In SecurityManager.lua CONFIG table
BanDurationBase = 3600, -- 1 hour for first offense
BanDurationMultiplier = 3, -- 3x increase per repeat offense
MaxBanDuration = 2592000, -- 30 days maximum
PermanentBanAfterOffenses = 5, -- Permanent ban after 5 offenses
```

### Manual Ban

```lua
local SecurityManager = ServiceLocator.Get("SecurityManager")

-- Ban with escalation
SecurityManager.BanPlayer(player, "Cheating detected")

-- Ban with custom duration (bypasses escalation)
SecurityManager.BanPlayer(player, "Severe violation", 86400) -- 24 hours
```

---

## 5. Safe Requires for Optional Services

### Pattern

```lua
-- Safe require pattern
local success, ParticleService = pcall(function()
    return require(script.Parent.ParticleService)
end)

if success and ParticleService and ParticleService.SpawnParticle then
    ParticleService.SpawnParticle("CoinPickup", position, player)
end
```

### When to Use

Use safe requires for:
- ✅ Optional visual/audio services (ParticleService, SoundService)
- ✅ Optional game features (ThemeService, WeatherService)
- ✅ Week-gated features (VIPService, ShopService)

Do NOT use safe requires for:
- ❌ Core services (DataService, SecurityManager)
- ❌ Required dependencies (ProfileService, GameConfig)

---

## 6. Magic Numbers → CONFIG

### Before
```lua
task.delay(1, function()
    -- What is this "1" for?
    CheckpointDebounce[key] = nil
end)
```

### After
```lua
local CONFIG = {
    CheckpointDebounceTime = 1, -- Seconds before checkpoint can be triggered again
}

task.delay(CONFIG.CheckpointDebounceTime, function()
    CheckpointDebounce[key] = nil
end)
```

### Benefits
- ✅ Easy to tune without hunting through code
- ✅ Self-documenting
- ✅ Can be overridden for testing

---

## 7. Input Validation

### Always Validate External Data

```lua
function MyService.ProcessPurchase(player: Player, itemId: string, quantity: number)
    -- 1. Validate player
    if not player or not player:IsA("Player") then
        warn("[MyService] Invalid player")
        return false
    end

    -- 2. Validate types
    if type(itemId) ~= "string" or type(quantity) ~= "number" then
        warn("[MyService] Invalid types")
        return false
    end

    -- 3. Validate ranges
    if quantity <= 0 or quantity > 100 then
        warn("[MyService] Invalid quantity:", quantity)
        return false
    end

    -- 4. Validate against NaN/Infinity
    if quantity ~= quantity or quantity == math.huge then
        warn("[MyService] Invalid number:", quantity)
        return false
    end

    -- 5. Clamp to safe range
    quantity = math.clamp(quantity, 1, 100)

    -- Now safe to use
    return true
end
```

---

## 🎯 Best Practices

### 1. Initialization Order

```lua
-- In init.server.lua
-- 1. ServiceLocator (FIRST!)
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)

-- 2. RemoteEventsInit (SECOND!)
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Initialize()

-- 3. Security systems
local SecurityManager = require(ServerScriptService.Security.SecurityManager)
local AntiExploit = require(ServerScriptService.Security.AntiExploit)

-- 4. Core services
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

-- 5. Everything else...
```

### 2. Service Registration

```lua
function MyService.Initialize()
    print("[MyService] Initializing...")

    -- Do initialization work
    MyService.SetupConnections()

    -- Register with ServiceLocator (LAST!)
    local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
    if ServiceLocator then
        ServiceLocator.Register("MyService", MyService)
    end

    print("[MyService] ✅ Ready")
end
```

### 3. Accessing Services

```lua
-- ✅ GOOD: Safe access
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
local DataService = ServiceLocator.Get("DataService")
if DataService and DataService.GetCoins then
    local coins = DataService.GetCoins(player)
end

-- ❌ BAD: Assumes service exists
local DataService = ServiceLocator.Get("DataService")
local coins = DataService.GetCoins(player) -- Crashes if DataService is nil
```

---

## 📋 Checklist for New Features

When adding a new feature:

- [ ] Create secure RemoteEvents in `RemoteEventsInit.lua`
- [ ] Add input validation for all arguments
- [ ] Use safe requires for optional dependencies
- [ ] Extract magic numbers to CONFIG table
- [ ] Register service with ServiceLocator
- [ ] Add webhook logging for critical events
- [ ] Handle errors gracefully with pcall
- [ ] Test with missing dependencies

---

## 🐛 Common Issues

### Issue: "RemoteEvents folder not found"
**Solution:** Make sure `RemoteEventsInit.Initialize()` runs before any service that needs remotes.

### Issue: "Service not found in ServiceLocator"
**Solution:** Check initialization order. Service must be registered before you try to get it.

### Issue: "Webhook not sending"
**Solution:**
1. Check webhook URL is configured: `WebhookLogger.SetWebhookUrl(...)`
2. Check rate limits (max 30 requests/minute)
3. Check output for error messages

### Issue: "LinearVelocity not working"
**Solution:** Make sure you're creating an Attachment and setting `Attachment0`:
```lua
local attachment = Instance.new("Attachment")
attachment.Parent = rootPart

local linearVelocity = Instance.new("LinearVelocity")
linearVelocity.Attachment0 = attachment -- REQUIRED!
linearVelocity.Parent = rootPart
```

---

## 📚 Further Reading

- **ServiceLocator API:** `tower-ascent-game/src/ServerScriptService/Utilities/ServiceLocator.lua`
- **WebhookLogger API:** `tower-ascent-game/src/ServerScriptService/Utilities/WebhookLogger.lua`
- **RemoteEventsInit:** `tower-ascent-game/src/ServerScriptService/Utilities/RemoteEventsInit.lua`
- **Full Changes:** `CODE_REVIEW_FIXES_SUMMARY.md`

---

**Need Help?**
- Check the code comments in each file
- Review the example implementations
- Consult the full implementation summary

**Last Updated:** 2025-12-17
