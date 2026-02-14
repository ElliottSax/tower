# Tower Ascent - Quick Reference

**For:** Developers & Testers
**Version:** Post-Code-Review (2025-12-01)

Quick command reference for common tasks.

---

## 🎮 **ADMIN COMMANDS**

Access via command bar: `_G.TowerAscent.AdminCommands.<command>`

### Get Help
```lua
_G.TowerAscent.AdminCommands.Help()
```

### Give Coins
```lua
local player = game.Players.YourName
_G.TowerAscent.AdminCommands.GiveCoins(player, 1000)
```

### Set Coins
```lua
_G.TowerAscent.AdminCommands.SetCoins(player, 5000)
```

### Grant VIP
```lua
_G.TowerAscent.AdminCommands.GrantVIP(player)
```

### Teleport to Section
```lua
_G.TowerAscent.AdminCommands.TeleportToSection(player, 25)
```

### View Player Stats
```lua
_G.TowerAscent.AdminCommands.ViewPlayerStats(player)
```

### View Server Stats
```lua
_G.TowerAscent.AdminCommands.ViewServerStats()
```

### Force Memory Cleanup
```lua
_G.TowerAscent.AdminCommands.ForceMemoryCleanup()
```

### Clear Violations
```lua
_G.TowerAscent.AdminCommands.ClearViolations(player)
```

### Regenerate Tower
```lua
_G.TowerAscent.AdminCommands.RegenerateTower()
```

---

## 🧪 **VALIDATION TESTS**

### Run All Tests
```lua
_G.TowerAscent.ValidationTests.RunAll()
```

### View Results
```lua
_G.TowerAscent.ValidationTests.PrintResults()
```

### Run Specific Test
```lua
_G.TowerAscent.ValidationTests.TestCheckpointDebounce()
_G.TowerAscent.ValidationTests.TestRespawnTracking()
_G.TowerAscent.ValidationTests.TestMemoryManagerCaching()
```

---

## 📊 **VIEW STATS**

### Memory Stats
```lua
_G.TowerAscent.MemoryManager:LogMemoryStats()
_G.TowerAscent.MemoryManager:GetStats()
```

### Anti-Cheat Stats
```lua
local stats = _G.TowerAscent.AntiCheat:GetStats()
print("Violations:", stats.TotalViolations)
print("Kicks:", stats.TotalKicks)
```

### Player Data
```lua
local data = _G.TowerAscent.DataService.GetData(player)
print("Coins:", data.Coins)
print("Highest Stage:", data.Stats.HighestStage)
```

### VIP Status
```lua
local isVIP = _G.TowerAscent.VIPService.IsVIP(player)
print("VIP:", isVIP)
```

---

## 🔧 **COMMON TASKS**

### Get First Player
```lua
local player = game.Players:GetPlayers()[1]
```

### Give Max Upgrades
```lua
local player = game.Players.YourName
_G.TowerAscent.AdminCommands.SetCoins(player, 999999)
```

### Test Checkpoint Spam
```lua
-- Verify debounce works by rapid-touching checkpoint
-- Should only award coins once per second
```

### Test Teleport Detection
```lua
-- Clear violations first
_G.TowerAscent.AdminCommands.ClearViolations(player)

-- Teleport far away (should trigger violation)
_G.TowerAscent.AdminCommands.TeleportToSection(player, 40)

-- Check violations
_G.TowerAscent.AdminCommands.ViewViolations(player)
```

### Check Memory Usage
```lua
_G.TowerAscent.AdminCommands.ViewMemoryStats()
```

### Verify All Fixes
```lua
_G.TowerAscent.ValidationTests.RunAll()
```

---

## 🚨 **TROUBLESHOOTING**

### Server Won't Start
1. Check Output for errors
2. Verify `string.rep` syntax (not `.rep()`)
3. Check all services loaded

### Checkpoints Not Working
1. Verify CollectionService tags
2. Check checkpoint debounce isn't stuck
3. View player checkpoint data:
```lua
local section = _G.TowerAscent.CheckpointService.GetPlayerSection(player)
print("Current section:", section)
```

### Players Getting Kicked (False Positives)
1. Check anti-cheat stats:
```lua
_G.TowerAscent.AdminCommands.ViewViolations(player)
```
2. Adjust thresholds in GameConfig.lua
3. Clear violations for testing:
```lua
_G.TowerAscent.AdminCommands.ClearViolations(player)
```

### Memory Usage High
1. Check active stages:
```lua
local stats = _G.TowerAscent.MemoryManager:GetStats()
print("Active:", stats.ActiveStages)
print("Parts:", stats.CurrentPartCount)
```
2. Force cleanup:
```lua
_G.TowerAscent.AdminCommands.ForceMemoryCleanup()
```

### VIP Not Working
1. Check if Game Pass ID configured:
```lua
-- VIPService.lua line 36
CONFIG.VIPGamePassId = 0  -- Must set to actual ID
```
2. Check VIP status:
```lua
local isVIP = _G.TowerAscent.VIPService.IsVIP(player)
print("VIP:", isVIP)
```

---

## ⚙️ **CONFIGURATION**

### Enable Debug Mode
```lua
-- In GameConfig.lua
GameConfig.Debug.Enabled = true
GameConfig.Debug.RunTests = true
GameConfig.Debug.VerboseLogs = true
```

### Disable Anti-Cheat (Testing)
```lua
-- In GameConfig.lua
GameConfig.AntiCheat.Enabled = false
```

### Adjust Anti-Cheat Thresholds
```lua
-- In GameConfig.lua
GameConfig.AntiCheat.MaxSpeed = 150  -- Default: 100
GameConfig.AntiCheat.MaxStageSkip = 5  -- Default: 2
GameConfig.AntiCheat.TeleportThreshold = 200  -- Default: 100
```

### Change Round Time
```lua
-- In GameConfig.lua
GameConfig.Round.RoundTime = 600  -- 10 minutes (default: 480)
GameConfig.Round.IntermissionTime = 30  -- 30 seconds (default: 20)
```

---

## 📋 **PRE-DEPLOYMENT CHECKLIST**

Quick checklist before deploying:

```lua
-- 1. Run validation tests
_G.TowerAscent.ValidationTests.RunAll()

-- 2. Check server stats
_G.TowerAscent.AdminCommands.ViewServerStats()

-- 3. Verify config
-- GameConfig.Debug.Enabled = false
-- GameConfig.Debug.RunTests = false
-- GameConfig.AntiCheat.Enabled = true

-- 4. Test core gameplay
-- - Tower generates
-- - Checkpoints work
-- - Coins awarded
-- - Round cycles

-- 5. Ready to deploy!
```

---

## 🔗 **MORE INFO**

- **Full Documentation:** See `DEVELOPER_GUIDE.md`
- **Deployment:** See `DEPLOYMENT_CHECKLIST.md`
- **Changelog:** See `CHANGES.md`
- **Admin Commands:** `_G.TowerAscent.AdminCommands.Help()`

---

**Last Updated:** 2025-12-01
