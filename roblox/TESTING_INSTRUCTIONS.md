# Testing Instructions - Code Review Fixes

Step-by-step guide to test all implemented fixes in Roblox Studio.

---

## 🚀 Quick Test (2 minutes)

### 1. Open in Roblox Studio

```
File > Open from File > tower-ascent-game/
```

### 2. Run Quick Validation

Open the **Command Bar** (View > Command Bar) and run:

```lua
local SecurityValidation = require(game.ServerScriptService.Utilities.SecurityValidation)
SecurityValidation.QuickCheck()
```

**Expected Output:**
```
[SecurityValidation] ✅ Quick check passed - All critical systems loaded
```

### 3. Run Full Test Suite

In the Command Bar:

```lua
local SecurityValidation = require(game.ServerScriptService.Utilities.SecurityValidation)
local results = SecurityValidation.RunAllTests()
print("Passed:", results.Passed, "Failed:", results.Failed)
```

**Expected Output:**
```
✅ Passed: 12
❌ Failed: 0
🎉 ALL TESTS PASSED!
```

---

## 🔬 Detailed Testing (10 minutes)

### Test 1: ServiceLocator

**Command:**
```lua
local ServiceLocator = require(game.ServerScriptService.Utilities.ServiceLocator)
print("Registered services:", table.concat(ServiceLocator.GetServiceNames(), ", "))
```

**Expected:**
- Should see: DataService, CoinService, CheckpointService, SecurityManager, AntiExploit, etc.

**What to Check:**
- ✅ At least 5 services registered
- ✅ Critical services present (DataService, SecurityManager)

---

### Test 2: RemoteEventsInit

**Command:**
```lua
local RemoteEventsInit = require(game.ServerScriptService.Utilities.RemoteEventsInit)
local remotes = RemoteEventsInit.GetAllRemotes()
for name, remote in pairs(remotes) do
    print("Remote:", name, "Type:", typeof(remote))
end
```

**Expected:**
- Should see: GetCoins, CoinUpdate, HasUpgrade, PurchaseUpgrade, etc.

**What to Check:**
- ✅ RemoteEvents folder exists in ReplicatedStorage
- ✅ All remotes are SecureRemote objects, not raw Instances
- ✅ Each remote has security configuration

---

### Test 3: Secure RemoteFunctions (Rate Limiting)

**Test rate limiting by spamming a remote:**

```lua
-- In Command Bar (Server)
local player = game.Players:GetChildren()[1] -- Get first player
if player then
    local RemoteEventsInit = require(game.ServerScriptService.Utilities.RemoteEventsInit)
    local getCoins = RemoteEventsInit.GetRemote("GetCoins")

    -- Spam 20 requests (should hit rate limit at 5/second)
    for i = 1, 20 do
        local result = getCoins.Remote:InvokeServer()
        print("Request", i, "Result:", result)
        task.wait(0.05) -- 20 requests/second
    end
end
```

**Expected:**
- First 5-10 requests succeed
- Later requests blocked with "Rate limit exceeded" warnings

**What to Check:**
- ✅ Rate limiting works
- ✅ Console shows "[SecureRemotes] Rate limit exceeded" warnings
- ✅ Player not kicked (just request denied)

---

### Test 4: Input Validation

**Test invalid inputs:**

```lua
local CoinService = require(game.ServerScriptService.Services.CoinService)

-- Test 1: Nil player
local success1 = CoinService.AddCoins(nil, 100, "Test")
print("Nil player:", success1) -- Should be false

-- Test 2: Invalid amount
local player = game.Players:GetChildren()[1]
local success2 = CoinService.AddCoins(player, -100, "Test")
print("Negative amount:", success2) -- Should be false

-- Test 3: NaN amount
local success3 = CoinService.AddCoins(player, 0/0, "Test")
print("NaN amount:", success3) -- Should be false

-- Test 4: Valid input
local success4 = CoinService.AddCoins(player, 100, "Test")
print("Valid input:", success4) -- Should be true
```

**Expected:**
- All invalid inputs rejected (false)
- Valid input succeeds (true)
- Console shows warning messages for invalid inputs

**What to Check:**
- ✅ Nil checks work
- ✅ NaN checks work
- ✅ Range checks work
- ✅ Valid inputs still work

---

### Test 5: Safe Requires (Optional Dependencies)

**Test service works without optional dependencies:**

```lua
-- Temporarily rename ParticleService to break it
local ParticleService = game.ServerScriptService.Services:FindFirstChild("ParticleService")
if ParticleService then
    ParticleService.Name = "ParticleService_DISABLED"
end

-- Try to add coins (uses ParticleService)
local CoinService = require(game.ServerScriptService.Services.CoinService)
local player = game.Players:GetChildren()[1]
local success = CoinService.AddCoins(player, 100, "Test")

print("AddCoins success (no ParticleService):", success)

-- Restore ParticleService
if ParticleService then
    ParticleService.Name = "ParticleService"
end
```

**Expected:**
- CoinService still works (success = true)
- No errors about missing ParticleService
- Just skips particle effect

**What to Check:**
- ✅ Service doesn't crash
- ✅ Core functionality still works
- ✅ Optional features gracefully skipped

---

### Test 6: Ban Escalation

**Test progressive ban system:**

```lua
local SecurityManager = require(game.ServerScriptService.Security.SecurityManager)
local player = game.Players:GetChildren()[1]

-- Check ban history
print("Ban History:", game:GetService("HttpService"):JSONEncode(SecurityManager.BanHistory))

-- Simulate multiple bans (DON'T DO THIS IN PRODUCTION!)
-- This is just to test the escalation logic
local testUserId = 999999 -- Fake user ID for testing

-- First offense
SecurityManager.BanHistory[testUserId] = {OffenseCount = 0, LastBan = 0}
SecurityManager.Bans[testUserId] = nil
-- (Can't actually ban without real player, just check the logic)

print("Test user ban history initialized")
```

**Expected:**
- Ban history table exists
- Structure: {OffenseCount = number, LastBan = number}

**What to Check:**
- ✅ BanHistory table exists
- ✅ Ban durations increase: 3600s → 10800s → 32400s
- ✅ Permanent ban at offense 5

---

### Test 7: WebhookLogger (Without Webhook)

**Test logging works even without webhook configured:**

```lua
local WebhookLogger = require(game.ServerScriptService.Utilities.WebhookLogger)

-- Log events (won't send, but should queue)
WebhookLogger.LogEvent("Test Event", "Testing webhook logger", "INFO", {
    {name = "Test Field", value = "Test Value", inline = true}
})

print("Event queued successfully (no errors)")
```

**Expected:**
- No errors
- Console warning: "Webhook URL not configured"
- Event queued but not sent

**What to Check:**
- ✅ Doesn't crash without webhook URL
- ✅ Events can be logged
- ✅ Queue management works

---

### Test 8: ServiceLocator Async Loading

**Test waiting for services:**

```lua
local ServiceLocator = require(game.ServerScriptService.Utilities.ServiceLocator)

-- Test immediate get
local DataService = ServiceLocator.Get("DataService")
print("DataService (immediate):", DataService ~= nil)

-- Test wait for service
local SecurityManager = ServiceLocator.WaitFor("SecurityManager", 5)
print("SecurityManager (wait):", SecurityManager ~= nil)

-- Test wait for missing service (should timeout)
local MissingService = ServiceLocator.WaitFor("NonExistentService", 2)
print("Missing service (should be nil):", MissingService == nil)
```

**Expected:**
- Immediate get: succeeds
- Wait for existing: succeeds
- Wait for missing: times out (nil) after 2 seconds

**What to Check:**
- ✅ WaitFor works for existing services
- ✅ WaitFor times out for missing services
- ✅ No infinite loops

---

### Test 9: CONFIG Tables

**Verify magic numbers extracted:**

```lua
-- Check CheckpointService CONFIG
local CheckpointService = require(game.ServerScriptService.Services.CheckpointService)

-- CONFIG should exist (can't access directly, but service should load)
print("CheckpointService loaded:", CheckpointService ~= nil)
print("Has Init function:", CheckpointService.Init ~= nil)
```

**Expected:**
- Service loads successfully
- No magic numbers in visible code

**What to Check:**
- ✅ Service loads
- ✅ Functions work
- ✅ No hardcoded delays visible

---

### Test 10: LinearVelocity (DoubleJump)

**Test in-game:**

1. Start a local server (Test tab > Play)
2. Get the DoubleJump upgrade (or modify code to always have it)
3. Jump, then press Space again in mid-air
4. Should perform double jump

**Expected:**
- Double jump works smoothly
- Uses LinearVelocity (not BodyVelocity)

**What to Check:**
- ✅ Double jump activates
- ✅ No errors in console
- ✅ Attachment and LinearVelocity created
- ✅ Cleaned up after 0.2 seconds

---

## 🎮 In-Game Testing

### Full Gameplay Test

1. **Start Local Server**
   - Test tab > Players: 2
   - Click "Start"

2. **Test Core Gameplay**
   - [ ] Player spawns correctly
   - [ ] Can move and jump
   - [ ] Checkpoints save progress
   - [ ] Death respawns at checkpoint
   - [ ] Coins awarded for progress

3. **Test Security**
   - [ ] Can't spam RemoteFunctions
   - [ ] Invalid inputs rejected
   - [ ] Services don't crash from missing dependencies

4. **Test Services**
   - [ ] DataService saves/loads
   - [ ] CoinService updates UI
   - [ ] CheckpointService tracks progress

5. **Check Console**
   - [ ] No red errors
   - [ ] Services initialize in order
   - [ ] All systems report "✅ Ready"

---

## 📊 Expected Console Output (On Startup)

```
====================================
Tower Ascent - Initializing...
====================================
[Server] Step 1: Loading ServiceLocator...
[Server] ✅ ServiceLocator loaded
[Server] Step 2: Initializing RemoteEvents...
[RemoteEventsInit] Creating RemoteEvents folder...
[RemoteEventsInit] Setting up secure remotes...
[RemoteEventsInit] ✅ All remotes initialized successfully
[Server] ✅ RemoteEvents initialized
[Server] Step 3: Loading WebhookLogger...
[WebhookLogger] Initializing webhook logger...
[WebhookLogger] ✅ Webhook logger initialized
[Server] ✅ WebhookLogger loaded
[Server] Step 4: Loading Security systems...
[SecurityManager] ✅ Security system initialized
[AntiExploit] Initializing anti-exploit system...
[AntiExploit] ✅ Anti-exploit system ready
[SecureRemotes] Initializing secure remote system...
[SecureRemotes] ✅ Secure remote system ready
[Server] ✅ Security systems loaded
[Server] Step 5: Loading Core services...
[DataService] Initializing...
[DataService] Initialized
[CoinService] Initializing...
[CoinService] RemoteEvents setup complete (using SecureRemotes)
[CoinService] Initialized
[CheckpointService] Initializing...
[CheckpointService] Checkpoint detection setup complete
[CheckpointService] Finish line detection setup complete
[CheckpointService] Initialized
[Server] ✅ Core services loaded
====================================
✅ ALL SYSTEMS INITIALIZED
====================================
Registered services:
  [1] ServiceLocator
  [2] RemoteEventsInit
  [3] WebhookLogger
  [4] SecurityManager
  [5] AntiExploit
  [6] SecureRemotes
  [7] DataService
  [8] CoinService
  [9] CheckpointService
====================================
🚀 Tower Ascent is ready!
====================================
```

---

## ❌ Common Test Failures

### Failure: "RemoteEvents folder not found"
**Cause:** RemoteEventsInit not initialized before services
**Fix:** Ensure init.server.lua calls RemoteEventsInit.Initialize() first

### Failure: "Service not found in ServiceLocator"
**Cause:** Service not registered or wrong initialization order
**Fix:** Check service calls ServiceLocator.Register() in Initialize()

### Failure: "Module not found"
**Cause:** File path incorrect
**Fix:** Verify file exists in correct folder

### Failure: Tests timeout
**Cause:** ServiceLocator.WaitFor() waiting for missing service
**Fix:** Reduce timeout or fix service initialization

---

## ✅ Success Criteria

All tests pass if:

- ✅ SecurityValidation.RunAllTests() = 12 passed, 0 failed
- ✅ No errors in console on startup
- ✅ All services registered in ServiceLocator
- ✅ RemoteEvents created in ReplicatedStorage
- ✅ Game plays normally (movement, checkpoints, coins)
- ✅ Rate limiting blocks spam requests
- ✅ Invalid inputs rejected gracefully
- ✅ Services work without optional dependencies

---

## 🐛 Troubleshooting

### If Tests Fail

1. **Check file locations**
   - ServiceLocator.lua in ServerScriptService/Utilities/
   - RemoteEventsInit.lua in ServerScriptService/Utilities/
   - WebhookLogger.lua in ServerScriptService/Utilities/

2. **Check initialization order**
   - ServiceLocator first
   - RemoteEventsInit second
   - Security systems third
   - Core services fourth

3. **Check for typos**
   - Service names must match exactly
   - Function names case-sensitive

4. **Check Studio version**
   - LinearVelocity requires recent Studio version
   - Update if using old version

---

## 📞 Report Issues

If tests fail:

1. Copy full console output
2. Note which specific test failed
3. Include error message
4. Check if game still works despite test failure

**Next Steps After Testing:**
- If all tests pass → Deploy to production
- If tests fail → Review error messages and fix issues
- If game works but tests fail → Tests may need adjustment

**Last Updated:** 2025-12-17
