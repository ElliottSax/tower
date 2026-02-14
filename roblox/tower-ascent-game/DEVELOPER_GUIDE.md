# Tower Ascent - Developer Guide

**Last Updated:** 2025-12-01
**Code Review Status:** ✅ Production-Ready (Grade A-)

This guide covers the recent code review fixes and best practices for developers working on Tower Ascent.

---

## 📋 **TABLE OF CONTENTS**

1. [Quick Start](#quick-start)
2. [Testing Your Changes](#testing-your-changes)
3. [Security Best Practices](#security-best-practices)
4. [Common Pitfalls](#common-pitfalls)
5. [Code Review Fixes Explained](#code-review-fixes-explained)
6. [Performance Guidelines](#performance-guidelines)
7. [Debugging Tools](#debugging-tools)

---

## 🚀 **QUICK START**

### Running the Game

1. Open `tower-ascent-game/default.project.json` in Roblox Studio
2. Press F5 to run
3. Check Output for startup logs
4. Look for: `TOWER ASCENT - Server Ready!`

### Running Validation Tests

After making changes, run validation tests:

```lua
-- In Studio command bar:
_G.TowerAscent.ValidationTests.RunAll()
```

This will verify all critical fixes are working correctly.

---

## 🧪 **TESTING YOUR CHANGES**

### Manual Testing Checklist

Before committing code:

- [ ] Server boots without errors
- [ ] No warnings in Output (except expected ones)
- [ ] Tower generates successfully
- [ ] Players can spawn and move
- [ ] Checkpoints work correctly
- [ ] Coins are awarded properly
- [ ] Round system cycles correctly

### Automated Testing

Enable automated tests on startup:

```lua
-- In GameConfig.lua
GameConfig.Debug.RunTests = true
```

Tests will run automatically when server starts.

### Test Specific Components

```lua
-- Test checkpoint debounce
_G.TowerAscent.ValidationTests.TestCheckpointDebounce()

-- Test anti-cheat
_G.TowerAscent.ValidationTests.TestRespawnTracking()

-- Test memory manager
_G.TowerAscent.ValidationTests.TestMemoryManagerCaching()

-- View results
_G.TowerAscent.ValidationTests.PrintResults()
```

---

## 🔒 **SECURITY BEST PRACTICES**

### 1. Server-Side Validation

**❌ NEVER trust client data:**

```lua
-- BAD: Client can manipulate attributes
if character:GetAttribute("IsVIP") then
    -- Give VIP benefits
end
```

**✅ ALWAYS validate on server:**

```lua
-- GOOD: Server-authoritative
local VIPService = require(...)
if VIPService.IsVIP(player) then
    -- Give VIP benefits
end
```

### 2. Debounce All Touch Events

**❌ Without debounce:**

```lua
checkpoint.Touched:Connect(function(hit)
    AwardCoins(player, 10) -- Can be spammed!
end)
```

**✅ With debounce:**

```lua
local debounce = {}

checkpoint.Touched:Connect(function(hit)
    local key = player.UserId .. "_" .. checkpointId
    if debounce[key] then return end

    debounce[key] = true
    task.delay(1, function()
        debounce[key] = nil
    end)

    AwardCoins(player, 10)
end)
```

### 3. Rate Limit RemoteEvents

**❌ No rate limiting:**

```lua
remoteEvent.OnServerEvent:Connect(function(player)
    ProcessRequest(player) -- Can be spammed!
end)
```

**✅ With rate limiting:**

```lua
local rateLimits = {}

remoteEvent.OnServerEvent:Connect(function(player)
    local now = tick()
    local lastCall = rateLimits[player.UserId] or 0

    if now - lastCall < 5 then
        warn("Rate limited:", player.Name)
        return
    end

    rateLimits[player.UserId] = now
    ProcessRequest(player)
end)
```

### 4. Never Use Client-Controllable Attributes for Security

**❌ Exploitable:**

```lua
-- Anti-cheat bypass: exploiters can set this attribute
if character:GetAttribute("JustRespawned") then
    return -- Skip teleport detection
end
```

**✅ Secure:**

```lua
-- Server-side tracking that clients can't manipulate
local recentRespawns = {} -- [UserId] = tick()

function DidRecentlyRespawn(player)
    local time = recentRespawns[player.UserId]
    return time and (tick() - time) < 2
end
```

---

## ⚠️ **COMMON PITFALLS**

### Pitfall #1: Using `.rep()` on Strings

**❌ Wrong:**

```lua
print("=".rep(60)) -- Python syntax, errors in Lua!
```

**✅ Correct:**

```lua
print(string.rep("=", 60))
```

### Pitfall #2: Expensive Operations in Loops

**❌ Inefficient:**

```lua
function Update()
    for i = 1, 100 do
        local count = #workspace:GetDescendants() -- Called 100 times!
    end
end
```

**✅ Optimized:**

```lua
function Update()
    local count = #workspace:GetDescendants() -- Called once
    for i = 1, 100 do
        -- Use cached count
    end
end
```

### Pitfall #3: Forgetting to Disconnect Connections

**❌ Memory leak:**

```lua
function OnTowerGenerate()
    for _, checkpoint in ipairs(tower:GetDescendants()) do
        checkpoint.Touched:Connect(function()
            -- This connection never gets disconnected!
        end)
    end
end
```

**✅ Proper cleanup:**

```lua
local connections = {}

function OnTowerGenerate()
    -- Cleanup old connections
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}

    -- Create new connections
    for _, checkpoint in ipairs(tower:GetDescendants()) do
        local conn = checkpoint.Touched:Connect(function()
            -- ...
        end)
        table.insert(connections, conn)
    end
end
```

### Pitfall #4: Race Conditions with Async Operations

**❌ Race condition:**

```lua
-- Player might complete checkpoint before VIP status loads!
task.spawn(function()
    local isVIP = CheckVIPStatus(player)
    player:SetAttribute("IsVIP", isVIP)
end)
```

**✅ Synchronous:**

```lua
-- Block until VIP status known
local isVIP = CheckVIPStatus(player)
player:SetAttribute("IsVIP", isVIP)
```

---

## 📖 **CODE REVIEW FIXES EXPLAINED**

### Fix #1: Checkpoint Debounce

**Why?** Players could spam-touch checkpoints to farm coins

**How?**
```lua
-- Track recent touches per player per section
local debounceKey = player.UserId .. "_" .. sectionNumber
if CheckpointService.CheckpointDebounce[debounceKey] then
    return -- Already touched recently
end

-- Set debounce with 1-second timeout
CheckpointService.CheckpointDebounce[debounceKey] = true
task.delay(1, function()
    CheckpointService.CheckpointDebounce[debounceKey] = nil
end)
```

**Where?** `CheckpointService.lua:221-239`

### Fix #2: Anti-Cheat Bypass

**Why?** Exploiters could set `JustRespawned` attribute to bypass teleport detection

**How?**
```lua
-- Server-side tracking instead of attributes
CheckpointService.RecentRespawns[player.UserId] = tick()

-- Validation function
function CheckpointService.DidRecentlyRespawn(player)
    local time = CheckpointService.RecentRespawns[player.UserId]
    return time and (tick() - time) < 2
end
```

**Where?**
- `CheckpointService.lua:44-46, 136-140, 481-490`
- `AntiCheat.lua:303-306`

### Fix #3: VIP Rate Limiting

**Why?** Prevent DoS attacks from spam-firing purchase prompts

**How?**
```lua
local rateLimits = {}

if now - (rateLimits[player.UserId] or 0) < 5 then
    return -- Rate limited
end

rateLimits[player.UserId] = now
```

**Where?** `VIPService.lua:106-121`

### Fix #4: Memory Manager Caching

**Why?** `GetDescendants()` is expensive, was called every 5 seconds

**How?**
```lua
-- Cache for 5 seconds
if tick() - self.LastPartCountUpdate < 5 then
    return self.CachedPartCount
end

-- Update cache
self.CachedPartCount = #workspace:GetDescendants()
self.LastPartCountUpdate = tick()
```

**Where?** `MemoryManager.lua:254-272`

---

## ⚡ **PERFORMANCE GUIDELINES**

### 1. Cache Expensive Operations

```lua
-- ❌ BAD: Called repeatedly
for i = 1, 100 do
    local descendants = workspace:GetDescendants()
end

-- ✅ GOOD: Cached
local descendants = workspace:GetDescendants()
for i = 1, 100 do
    -- Use cached value
end
```

### 2. Use Specific Services

```lua
-- ❌ LESS SPECIFIC: Searches all descendants
workspace:FindFirstChild("Part", true)

-- ✅ MORE SPECIFIC: Direct path
workspace.Folder.Part
```

### 3. Batch Remote Events

```lua
-- ❌ BAD: 100 separate events
for i = 1, 100 do
    remoteEvent:FireClient(player, i)
end

-- ✅ GOOD: Single batched event
remoteEvent:FireClient(player, {1, 2, 3, ..., 100})
```

### 4. Limit Heartbeat Connections

```lua
-- ❌ BAD: 100 heartbeat connections
for i = 1, 100 do
    RunService.Heartbeat:Connect(function()
        -- ...
    end)
end

-- ✅ GOOD: Single connection handles all
RunService.Heartbeat:Connect(function()
    for i = 1, 100 do
        -- ...
    end
end)
```

---

## 🐛 **DEBUGGING TOOLS**

### Access Global State

All services are accessible via `_G.TowerAscent`:

```lua
_G.TowerAscent.CheckpointService
_G.TowerAscent.CoinService
_G.TowerAscent.AntiCheat
_G.TowerAscent.MemoryManager
-- etc.
```

### Admin Commands

```lua
-- Add coins
_G.TowerAscent.CoinService.AdminAddCoins(player, 1000)

-- Grant VIP temporarily
_G.TowerAscent.VIPService.AdminGrantVIP(player)

-- Force memory cleanup
_G.TowerAscent.MemoryManager:ForceCleanup()

-- Get stats
print(_G.TowerAscent.MemoryManager:GetStats())
print(_G.TowerAscent.AntiCheat:GetStats())
```

### Debug Logging

Enable verbose logging:

```lua
-- In GameConfig.lua
GameConfig.Debug.VerboseLogs = true
```

### Memory Stats

```lua
-- Get current memory usage
_G.TowerAscent.MemoryManager:LogMemoryStats()

-- Get active stage count
print(_G.TowerAscent.MemoryManager:GetActiveStageCount())

-- Get part count
print(_G.TowerAscent.MemoryManager:GetPartCount())
```

### Anti-Cheat Stats

```lua
-- Get violation stats
local stats = _G.TowerAscent.AntiCheat:GetStats()
print("Total Violations:", stats.TotalViolations)
print("Total Kicks:", stats.TotalKicks)

-- Get player-specific violations
local violations = _G.TowerAscent.AntiCheat:GetPlayerViolations(player)
for _, v in ipairs(violations) do
    print(v.Type, v.Timestamp, v.Details)
end
```

---

## 📝 **NOTES FOR CONTRIBUTORS**

### Before Submitting Code

1. Run validation tests: `_G.TowerAscent.ValidationTests.RunAll()`
2. Check for warnings in Output
3. Test with multiple players (if applicable)
4. Verify memory usage stays under 200 MB
5. Check for connection leaks

### Code Style

- Use `--` for single-line comments
- Use `--[[]]` for multi-line comments
- Indent with tabs (consistent with existing code)
- Use PascalCase for functions: `MyFunction()`
- Use camelCase for variables: `myVariable`
- Use SCREAMING_SNAKE_CASE for constants: `MAX_PLAYERS`

### Documentation

- Every file should have a header comment explaining purpose
- Every function should have a comment explaining what it does
- Complex logic should have inline comments
- Update this guide when adding new systems

---

## 🔗 **USEFUL LINKS**

- [Roblox DevHub](https://create.roblox.com/docs)
- [ProfileService Documentation](https://madstudioroblox.github.io/ProfileService/)
- [Luau Type Checking](https://luau-lang.org/typecheck)
- [Roblox Performance Optimization](https://create.roblox.com/docs/projects/optimization)

---

## 📞 **SUPPORT**

Questions about the code review fixes?
- Check `CHANGES.md` for detailed explanations
- Run validation tests to verify fixes work
- Review this guide for best practices

---

**Last Updated:** 2025-12-01
**Maintainer:** Code Review Team
