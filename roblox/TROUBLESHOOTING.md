# Troubleshooting Guide

> Common issues and their solutions for the Procedural Obby implementation

## 🔧 Setup Issues

### Rokit Installation Fails

**Symptom:** `curl: command not found` or download errors

**Solution:**
```bash
# Linux/Mac alternative:
wget https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64
chmod +x rokit-linux-x86_64
sudo mv rokit-linux-x86_64 /usr/local/bin/rokit

# Windows: Download manually from GitHub releases
# Extract .exe to C:\Windows\ or add to PATH
```

### Rojo Won't Connect to Studio

**Symptom:** Plugin shows "Not connected" or "Connection refused"

**Solution:**
1. Check Rojo is running: `rojo serve` should show `Rojo server listening on port 34872`
2. In Studio plugin, verify address is `localhost:34872`
3. Windows: Allow Rojo through firewall
4. Mac: Grant network permissions in Security & Privacy
5. Try changing port: `rojo serve --port 35000`

### Wally Packages Not Installing

**Symptom:** `wally install` fails or packages folder empty

**Solution:**
```bash
# 1. Check wally.toml syntax (must be valid TOML)
# 2. Verify internet connection
# 3. Clear cache and retry:
rm -rf ~/.wally
wally install

# 4. If specific package fails, check it exists:
# https://wally.run/package/madstudioroblox/profileservice
```

---

## 🎮 Runtime Errors

### "ServerStorage.Sections not found"

**Symptom:** Generator errors on first run

**Root Cause:** Folder structure not created in Studio

**Solution:**
1. Open Roblox Studio
2. Manually create: `ServerStorage > Sections > Easy`, `Medium`, `Hard`, `Special`
3. Add at least one section model to `Easy/`
4. Verify in Rojo sync

### "PrimaryPart is not a valid member of Model"

**Symptom:** Stage creation fails with CFrame error

**Root Cause:** Section model missing PrimaryPart assignment

**Solution:**
1. In Studio, select section model
2. In Properties, find `PrimaryPart` dropdown
3. Select the base part (usually the platform)
4. Save and publish
5. Re-sync with Rojo

### "Attempt to index nil with 'Next'"

**Symptom:** Generator crashes on second stage

**Root Cause:** First stage missing Next connection point

**Solution:**
```lua
-- Validate all sections with this script:
for _, section in pairs(ServerStorage.Sections.Easy:GetChildren()) do
    if not section:FindFirstChild("Next") then
        warn(section.Name, "missing Next point")
    end
    if not section:FindFirstChild("Checkpoint") then
        warn(section.Name, "missing Checkpoint")
    end
end
```

### ProfileService: "Session locked"

**Symptom:** Players kicked with "Data failed to load"

**Root Cause:** Profile still locked from previous session (server crashed without releasing)

**Solution:**
1. **Immediate:** Wait 5 minutes for auto-release
2. **Long-term:** Add timeout in DataService:
```lua
local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
-- "ForceLoad" steals lock after timeout (use cautiously)
```

3. **During development:** Clear test data:
```lua
-- WARNING: Deletes all player data (dev only)
local ProfileStore = ProfileService.GetProfileStore("PlayerData_v2") -- New version = fresh start
```

---

## ⚡ Performance Issues

### Server Memory Climbing >2GB

**Symptom:** Memory usage increases over time, server eventually crashes

**Root Cause:** Stages not being cleaned up

**Diagnosis:**
```lua
-- Add to ServerScriptService to monitor:
while true do
    wait(60)
    local stageCount = #workspace.Tower:GetChildren()
    local memory = game:GetService("Stats"):GetTotalMemoryUsageMb()
    print("Stages:", stageCount, "Memory:", memory, "MB")

    if stageCount > 100 then
        warn("TOO MANY STAGES - MemoryManager not working")
    end
end
```

**Solution:**
1. Verify MemoryManager:Start() is called in init.server.lua
2. Check DespawnDistance isn't too high (should be ~300 studs)
3. Ensure old stages are actually destroyed:
```lua
-- In MemoryManager:CleanupDistantStages()
print("Destroying stage", stage.Name, "at", stage:GetAttribute("StageNumber"))
stage:Destroy() -- Verify this line executes
```

### Mobile FPS <30

**Symptom:** Game lags on iPhone/Android, desktop fine

**Root Cause:** Too many parts, shadows enabled, high-res textures

**Diagnosis:**
```lua
-- Client-side performance check:
local stats = game:GetService("Stats")
local fps = stats.FrameRate
local partCount = #workspace:GetDescendants()

print("FPS:", fps, "Parts:", partCount)

if fps < 50 then
    warn("PERFORMANCE ISSUE")
    print("Rendering:", stats.RenderAverage)
    print("Physics:", stats.PhysicsAverage)
end
```

**Solution:**
1. Reduce part count per section (<200 parts each)
2. Disable shadows globally:
```lua
workspace.GlobalShadows = false
```
3. Lower streaming radius on mobile:
```lua
-- In MobileOptimizer.client.lua
if isMobile then
    workspace.StreamingTargetRadius = 128 -- Down from 256
end
```
4. Check Material usage - avoid Glass, Neon, ForceField

### Long Join Times (>30 seconds)

**Symptom:** Players wait forever to spawn

**Root Cause:** Too much content loading before StreamingEnabled kicks in

**Solution:**
1. Verify StreamingEnabled is actually on:
```lua
print("Streaming:", workspace.StreamingEnabled) -- Should be true
```

2. Reduce initial spawn area complexity
3. Move UI assets to ReplicatedStorage, lazy-load
4. Check internet connection (test on different network)

---

## 🛡️ Anti-Cheat Issues

### False Positives (Legit Players Kicked)

**Symptom:** High-ping players or speed runners getting kicked

**Root Cause:** Thresholds too strict

**Solution:**
```lua
-- In AntiCheat.lua, make ping-aware:
local ping = player:GetNetworkPing() * 1000 -- ms
local threshold = TELEPORT_THRESHOLD

if ping > HIGH_PING_THRESHOLD then
    threshold = threshold * 2 -- Double tolerance for laggy players
end

if distance > threshold then
    -- Kick logic
end
```

### Exploiters Still Bypassing

**Symptom:** Players obviously cheating but not detected

**Root Cause:** Client-side exploits can manipulate anything

**Solution:**
1. **Never trust client** - all validation server-side
2. Add additional checks:
```lua
-- Velocity check (flying)
if rootPart.AssemblyLinearVelocity.Y > 200 then
    warn("Suspicious vertical velocity")
end

-- Humanoid state check
if humanoid:GetState() == Enum.HumanoidStateType.Physics then
    -- Ragdolled = possible noclip
end
```

3. Log suspicious players for review:
```lua
local suspicionScore = 0
if distance > threshold then suspicionScore += 1 end
if airborneTime > 10 then suspicionScore += 1 end

player:SetAttribute("SuspicionScore", suspicionScore)
```

4. Use server-authoritative position:
```lua
-- Instead of trusting client position, validate against checkpoints
-- Only allow player to be near their current stage
local allowedStage = leaderstats.Stage.Value
local allowedPosition = workspace.Tower:FindFirstChild("Stage_" .. allowedStage)

if allowedPosition then
    local distance = (rootPart.Position - allowedPosition.Position).Magnitude
    if distance > 500 then
        -- Player too far from their stage
        rootPart.CFrame = allowedPosition.Checkpoint.CFrame
    end
end
```

---

## 📊 Analytics Problems

### Events Not Showing in Creator Hub

**Symptom:** Custom events logged but no data in dashboard

**Possible Causes:**
1. **24-hour delay** - Data takes time to process
2. **Rate limiting** - Too many events sent
3. **Cardinality exceeded** - Too many unique field combinations

**Solution:**
```lua
-- Check rate limit:
local playersCount = #game:GetService("Players"):GetPlayers()
local limit = 120 + (playersCount * 20) -- Per minute
print("Analytics rate limit:", limit, "/min")

-- Batch events to stay under limit (see AnalyticsService.lua)
```

### "Too many custom events" Error

**Symptom:** AnalyticsService:LogCustomEvent fails

**Root Cause:** 100 event limit reached

**Solution:**
- Consolidate events (use CustomField01 for variants)
- Example:
```lua
-- BAD (100 events):
LogCustomEvent(player, "Stage1Complete", ...)
LogCustomEvent(player, "Stage2Complete", ...)
-- ... 98 more

-- GOOD (1 event):
LogCustomEvent(player, "StageComplete", stageNumber, {
    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Stage-" .. stageNumber
})
```

---

## 💰 Monetization Issues

### Game Pass Purchase Not Detecting

**Symptom:** Players buy pass but feature doesn't unlock

**Root Cause:** UserOwnsGamePassAsync timing or pass ID wrong

**Diagnosis:**
```lua
-- Test game pass detection:
local passId = 123456789 -- YOUR PASS ID
local success, owns = pcall(function()
    return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(
        player.UserId,
        passId
    )
end)

print("Check success:", success, "Owns:", owns)

if not success then
    warn("MarketplaceService error:", owns) -- 'owns' contains error message
end
```

**Solution:**
1. Verify pass ID matches Creator Hub
2. Test in published game (NOT Studio)
3. Add retry logic:
```lua
local function checkOwnership(player, passId, retries)
    retries = retries or 3
    for i = 1, retries do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)

        if success then
            return owns
        end

        wait(1) -- Retry after delay
    end
    return false
end
```

### ProcessReceipt Not Firing

**Symptom:** Developer Products purchased but not delivered

**Root Cause:** Receipt not saved properly, or yielding

**Solution:**
```lua
-- CORRECT receipt handling:
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

    if not player then
        -- Player left, retry later
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Grant product (NO YIELDING HERE!)
    local success = grantProduct(player, receiptInfo.ProductId)

    if success then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        -- Failed, retry
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Move slow operations (DataStore) outside ProcessReceipt:
function grantProduct(player, productId)
    -- Fast, non-yielding check
    local data = cachedData[player] -- Use cached data, not DataStore

    if productId == SKIP_PASS_ID then
        -- Grant immediately
        player.leaderstats.Stage.Value += 1
        -- Save to DataStore asynchronously (separate function)
        task.spawn(function()
            saveData(player)
        end)
        return true
    end

    return false
end
```

---

## 🔌 Rojo Sync Issues

### "Tree conflict" Error

**Symptom:** Rojo refuses to sync, shows tree mismatch

**Root Cause:** Studio changes conflict with filesystem

**Solution:**
1. **Quick fix:** Restart Studio and Rojo
2. **Nuclear option:** Delete place, rebuild from Rojo:
```bash
rojo build --output fresh.rbxl
# Open fresh.rbxl in Studio
```

3. **Prevention:** Use partially-managed Rojo (scripts only, not entire place)

### Changes Not Appearing in Studio

**Symptom:** Edit .lua file, save, but Studio doesn't update

**Root Cause:** Rojo not watching, or file outside source tree

**Diagnosis:**
```bash
# Check Rojo output for:
# "Synced X instances"

# If no sync message:
1. File not in default.project.json tree
2. Rojo crashed (check terminal)
3. File syntax error (check Selene output)
```

**Solution:**
1. Verify file path matches default.project.json
2. Restart Rojo: `Ctrl+C`, then `rojo serve`
3. Check file for syntax errors: `selene path/to/file.lua`

### Team Collaboration Overwriting

**Symptom:** Two developers' changes conflict

**Root Cause:** Rojo bypasses Team Create, last write wins

**Solution:**
1. **Use Git branches** (required for teams)
```bash
# Developer A:
git checkout -b feature/new-section
# Make changes, commit, push

# Developer B:
git checkout -b feature/anti-cheat
# Make changes, commit, push

# Merge via PR after review
```

2. **Separate dev places** - Each dev has their own place ID
3. **Communicate** - Announce before syncing shared files

---

## 🧪 Testing Issues

### TestEZ Tests Failing

**Symptom:** `roblox-cli run tests` errors or hangs

**Root Cause:** TestEZ setup incorrect, or tests have issues

**Solution:**
```lua
-- Check test file structure:
-- MyModule.spec.lua must be SIBLING to MyModule.lua

src/
├── Generator.lua
└── Generator.spec.lua  ✅ Correct

-- Test must return function:
return function()
    local MyModule = require(script.Parent.MyModule)

    describe("Feature", function()
        it("should work", function()
            expect(true).to.be.ok()
        end)
    end)
end
```

### Determinism Tests Failing

**Symptom:** Same seed produces different results

**Root Cause:** Cross-platform Random.new() bug (2023 issue, possibly fixed)

**Solution:**
1. Test on same platform:
```lua
it("should generate identically", function()
    -- Run both on server OR both on client, not mixed
    local gen1 = Generator.new(12345)
    local gen2 = Generator.new(12345)

    -- Compare results
end)
```

2. Add tolerance for floating-point:
```lua
-- Don't use exact equality for CFrames
expect(cframe1.Position).to.be.near(cframe2.Position, 0.01)
```

3. Report if bug persists (post on DevForum with repro)

---

## 📱 Mobile-Specific Issues

### Touch Controls Not Working

**Symptom:** Players can't move on mobile

**Root Cause:** Custom UI blocking input

**Solution:**
```lua
-- In ScreenGui:
screenGui.IgnoreGuiInset = true -- Prevents SafeArea issues

-- For buttons:
button.Modal = false -- Doesn't block game input
```

### UI Cut Off on Notch Screens

**Symptom:** iPhone X+ shows UI under notch

**Root Cause:** SafeArea not respected

**Solution:**
```lua
-- Use ScreenInsets:
local GuiService = game:GetService("GuiService")
local insets = GuiService:GetGuiInset()

-- Position UI accounting for insets:
frame.Position = UDim2.new(0, insets.X, 0, insets.Y + 10)
```

Or enable:
```lua
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
```

---

## 🌐 Network Issues

### "HttpService is not enabled"

**Symptom:** Wally or external APIs fail

**Root Cause:** HttpService disabled in game settings

**Solution:**
1. Game Settings → Security → Enable "Allow HTTP Requests"
2. Publish place
3. Retry

### DataStore Request Throttled

**Symptom:** "DataStore request was throttled" warnings

**Root Cause:** Too many SetAsync calls

**Solution:**
```lua
-- BAD (saves on every change):
value.Changed:Connect(function()
    dataStore:SetAsync(key, value.Value) -- THROTTLED!
end)

-- GOOD (batch saves):
local saveQueue = {}
value.Changed:Connect(function()
    saveQueue[key] = value.Value
end)

task.spawn(function()
    while true do
        wait(30) -- Save every 30 seconds
        for key, val in pairs(saveQueue) do
            dataStore:SetAsync(key, val)
        end
        saveQueue = {}
    end
end)
```

---

## 🔍 Debugging Tips

### Enable Verbose Logging

```lua
-- Add to top of problematic service:
local DEBUG = true

local function log(...)
    if DEBUG then
        print("[ServiceName]", ...)
    end
end

function MyService:SomeFunction()
    log("Function called with", arg1, arg2)
    -- ...
    log("Result:", result)
end
```

### Use Developer Console

In-game, press `F9` to open console:
- **Server** tab: Server-side errors
- **Client** tab: Client-side errors
- **Log** tab: All print statements

### Studio Output Filters

Click funnel icon in Output:
- ☑️ Script Performance - Shows slow scripts
- ☑️ Memory - Shows memory usage
- ☑️ Physics - Shows physics issues

### MicroProfiler

Press `Ctrl+P` (PC) / `Cmd+P` (Mac) in Studio or client
- Shows frame-by-frame performance
- Identify bottlenecks (rendering, physics, scripts)
- Look for red (slow) bars

---

## 🆘 Getting Help

### Before Asking

1. ✅ Read this troubleshooting guide
2. ✅ Check Roblox DevForum for similar issues
3. ✅ Review official documentation
4. ✅ Search existing GitHub issues

### When Asking

**Bad Question:**
> "It doesn't work, help!"

**Good Question:**
> **Title:** ProfileService session lock won't release
>
> **Description:**
> - Roblox Studio version: 0.615.0.6150536
> - ProfileService version: 1.0.0
> - Behavior: Players kicked with "Session locked" after server crash
>
> **Steps to reproduce:**
> 1. Start server
> 2. Player joins
> 3. Stop server (kill process)
> 4. Player tries to rejoin within 5 minutes
> 5. Gets kicked
>
> **Expected:** Profile loads with ForceLoad
> **Actual:** Profile returns nil
>
> **Code:**
> ```lua
> local profile = ProfileStore:LoadProfileAsync("Player_" .. userId)
> if not profile then
>     player:Kick("Session locked")
> end
> ```
>
> **Logs:**
> ```
> [ProfileService] Session locked for Player_123456
> ```

### Where to Ask

- **Roblox DevForum:** https://devforum.roblox.com/c/help-and-feedback/scripting-support/
- **Rojo Discord:** https://discord.gg/rojo (for Rojo-specific issues)
- **GitHub Issues:** (if bug in this implementation guide)

---

## 📚 Additional Resources

- [Roblox Creator Hub](https://create.roblox.com/docs)
- [Roblox API Reference](https://create.roblox.com/docs/reference/engine)
- [DevForum](https://devforum.roblox.com/)
- [Rojo Documentation](https://rojo.space/docs/)
- [ProfileService Guide](https://madstudioroblox.github.io/ProfileService/)

---

**Still stuck?** Create a GitHub issue with:
1. Clear title
2. Steps to reproduce
3. Expected vs actual behavior
4. Code snippet
5. Error messages/logs
6. Screenshots if relevant

**Last Updated:** 2025-01-27
