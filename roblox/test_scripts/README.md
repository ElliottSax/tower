# Roblox Games Portfolio - Test Scripts

**Purpose:** Automated and manual validation scripts for Week 1 testing phase
**Coverage:** 60 test cases across 17 critical fixes in 5 games
**Created:** 2026-02-22

---

## Quick Start

### Run All Tests (Recommended)

```lua
-- In Roblox Studio Command Bar:
local MasterRunner = require(game.ServerScriptService.test_scripts.MasterTestRunner)
MasterRunner.RunAllTests()
```

---

## Directory Structure

```
test_scripts/
├── README.md                    (This file)
├── MasterTestRunner.lua         (Orchestrates all tests)
│
├── tower_ascent/               (Tower Ascent - 5 fixes, 15 tests)
│   ├── test_debug_mode.lua     (3 tests - Debug mode protection)
│   ├── test_authentication.lua (3 tests - IsAuthenticated function)
│   ├── test_vip_race.lua       (4 tests - VIP race condition)
│   ├── test_coin_underflow.lua (3 tests - Coin underflow protection)
│   └── test_monetization.lua   (4 tests - Product IDs)
│
├── speed_run_universe/         (Speed Run - 5 fixes, 20 tests)
│   ├── test_speedrun_validation.lua  (5 tests - Anti-cheat)
│   ├── test_player_cleanup.lua       (3 tests - Memory cleanup) [TODO]
│   ├── test_ghost_compression.lua    (4 tests - Ghost compression) [TODO]
│   └── test_leaderboard.lua          (4 tests - Error handling) [TODO]
│
├── adventure_story_obby/       (Adventure - 3 fixes, 9 tests)
│   ├── test_checkpoint_validation.lua  (4 tests) [TODO]
│   ├── test_coin_cap.lua              (3 tests) [TODO]
│   └── test_collectible_memory.lua    (3 tests) [TODO]
│
├── pet_collector_sim/          (Pet Collector - 3 fixes, 12 tests)
│   ├── test_negative_coins.lua        (4 tests) [TODO]
│   ├── test_trading_disabled.lua      (3 tests) [TODO]
│   └── test_secure_remotes.lua        (4 tests) [TODO]
│
└── dimension_hopper/           (Dimension - 1 fix, 4 tests)
    └── test_fragment_memory.lua       (4 tests) [TODO]
```

---

## Test Modules Status

| Game | Module | Status | LOC |
|------|--------|--------|-----|
| Tower Ascent | test_debug_mode.lua | ✅ Complete | ~120 |
| Tower Ascent | test_authentication.lua | ✅ Complete | ~110 |
| Tower Ascent | test_vip_race.lua | ✅ Complete | ~120 |
| Tower Ascent | test_coin_underflow.lua | ✅ Complete | ~130 |
| Tower Ascent | test_monetization.lua | ✅ Complete | ~120 |
| Speed Run | test_speedrun_validation.lua | ✅ Complete | ~150 |
| Speed Run | test_player_cleanup.lua | 🔴 TODO | 0 |
| Speed Run | test_ghost_compression.lua | 🔴 TODO | 0 |
| Speed Run | test_leaderboard.lua | 🔴 TODO | 0 |
| Adventure | test_checkpoint_validation.lua | 🔴 TODO | 0 |
| Adventure | test_coin_cap.lua | 🔴 TODO | 0 |
| Adventure | test_collectible_memory.lua | 🔴 TODO | 0 |
| Pet Collector | test_negative_coins.lua | 🔴 TODO | 0 |
| Pet Collector | test_trading_disabled.lua | 🔴 TODO | 0 |
| Pet Collector | test_secure_remotes.lua | 🔴 TODO | 0 |
| Dimension | test_fragment_memory.lua | 🔴 TODO | 0 |
| **Master** | **MasterTestRunner.lua** | **✅ Complete** | **~200** |

**Current Progress:** 7/17 modules complete (~950 LOC)

---

## How to Use

### Individual Test Module

```lua
-- Run a specific test module:
local TestDebug = require(game.ServerScriptService.test_scripts.tower_ascent.test_debug_mode)
local results = TestDebug.RunAllTests()

-- Results will print to Output window
print("Tests passed:", results.Passed)
print("Tests failed:", results.Failed)
```

### Per-Game Testing

```lua
-- Run all tests for Tower Ascent:
local tests = {
    require(script.tower_ascent.test_debug_mode),
    require(script.tower_ascent.test_authentication),
    require(script.tower_ascent.test_vip_race),
    require(script.tower_ascent.test_coin_underflow),
    require(script.tower_ascent.test_monetization)
}

for _, test in ipairs(tests) do
    test.RunAllTests()
end
```

### Master Test Runner

```lua
-- Run ALL tests across ALL games:
local MasterRunner = require(game.ServerScriptService.test_scripts.MasterTestRunner)
local allResults = MasterRunner.RunAllTests()

-- Comprehensive summary printed
-- Returns overall statistics
```

---

## Test Result Codes

Each test returns one of these status codes:

| Code | Meaning | Action |
|------|---------|--------|
| **PASS** ✅ | Test passed successfully | Continue |
| **FAIL** ❌ | Test failed, bug found | Document and fix |
| **SKIPPED** ⏭️ | Test skipped (wrong environment) | Run in correct environment |
| **MANUAL** ✋ | Manual testing required | Follow manual test procedure |
| **WARN** ⚠️ | Warning, not critical | Investigate if needed |

---

## Test Types

### Automated Tests
- Run entirely via Lua code
- No player interaction needed
- Can run in Studio or test server
- Instant results

**Examples:**
- Product ID validation
- nil player handling
- Code configuration checks

### Manual Tests
- Require actual gameplay
- Need player actions (collect coins, hatch eggs, etc.)
- May need Robux purchases
- Time-consuming but critical

**Examples:**
- VIP multiplier testing
- Speedrun validation
- Memory leak monitoring
- Exploit attempts

---

## Environment Requirements

### Studio Environment
**Best for:**
- Code validation
- Unit tests
- Debug mode testing

**Run with:**
- Debug mode enabled
- Local server
- Command bar access

### Test Server Environment
**Best for:**
- Security testing
- Production config validation
- Integration tests

**Run with:**
- Debug mode disabled
- Published test server
- Real player accounts

---

## Common Test Scenarios

### Testing Code Logic
```lua
-- Example: Test coin underflow protection
local DataService = require(game.ServerScriptService.Services.DataService)
local player = game.Players:GetPlayers()[1]

DataService.SetPlayerData(player, "Coins", 50)
DataService.RemoveCoins(player, 100)  -- Try to remove more than available

local finalCoins = DataService.GetPlayerData(player, "Coins")
assert(finalCoins == 0, "Coins should be capped at 0")
```

### Testing Security
```lua
-- Example: Test server-authoritative checkpoint
local remoteEvents = game.ReplicatedStorage.RemoteEvents

-- Attempt to set distant checkpoint (should fail)
remoteEvents.SetCheckpoint:FireServer(99, CFrame.new(1000, 1000, 1000))

-- Server should reject and log warning
```

### Testing Performance
```lua
-- Example: Test memory leak
local startMemory = game:GetService("Stats"):GetTotalMemoryUsageMb()

-- Spawn and collect 100 collectibles
for i = 1, 100 do
    -- Spawn collectible
    -- Collect it
    -- Wait briefly
end

local endMemory = game:GetService("Stats"):GetTotalMemoryUsageMb()
local memoryGrowth = endMemory - startMemory

assert(memoryGrowth < 10, "Memory growth should be < 10MB")
```

---

## Troubleshooting

### "Module not found"
- Ensure test_scripts folder is in ServerScriptService
- Check folder names match exactly (case-sensitive)
- Verify module names are correct

### "No players in server"
- Join server with a player before running tests
- Some tests require an active player
- Use test accounts (TestUser1-5)

### "Could not load Service"
- Check game structure matches expected paths
- Ensure services exist in ServerScriptService
- Verify module naming is correct

### "Test always skipped"
- Check if you're in correct environment (Studio vs Production)
- Some tests only run in Studio, others only in test server
- Read test description for environment requirements

---

## Best Practices

**Before Testing:**
1. Read TESTING_GUIDE.md for detailed instructions
2. Check WEEK1_QUICK_CHECKLIST.md for daily tasks
3. Set up test accounts with varying data
4. Have WEEK1_TESTING_PROGRESS.md open for logging

**During Testing:**
1. Run automated tests first (faster)
2. Document results immediately
3. Create bug reports for failures
4. Take screenshots of issues
5. Monitor server logs for warnings

**After Testing:**
1. Update WEEK1_TESTING_PROGRESS.md
2. Calculate pass/fail rates
3. Prioritize bugs (P0/P1/P2/P3)
4. Re-test after fixes
5. Generate summary report

---

## Integration with Documentation

**Reference Documents:**
- `../MASTER_TESTING_SUITE.md` - Detailed test specifications
- `../WEEK1_TESTING_PROGRESS.md` - Live progress tracker
- `../TESTING_GUIDE.md` - Step-by-step guide
- `../WEEK1_QUICK_CHECKLIST.md` - Daily checklists
- `../WEEK1_TEST_SUMMARY.md` - Executive summary
- `../DEPLOYMENT_ROADMAP.md` - Launch timeline

**Fix Documentation:**
- `../tower-ascent-game/FIXES_COMPLETED.md`
- `../new-games/speed-run-universe/FIXES_COMPLETED.md`
- `../adventure-story-obby/FIXES_COMPLETED.md`
- `../pet-collector-sim/FIXES_COMPLETED.md`
- `../dimension-hopper/FIXES_COMPLETED.md`

---

## Contributing

**Adding New Tests:**
1. Create test module in appropriate folder
2. Follow existing test format (see test_debug_mode.lua)
3. Implement RunAllTests() function
4. Return results table with Pass/Fail counts
5. Update MasterTestRunner.lua to include new module
6. Update this README with status

**Test Module Template:**
```lua
local TestRunner = {}

function TestRunner.TestSomething()
    print("=== TEST: Something ===")
    -- Test logic here
    return "PASS" -- or "FAIL", "SKIPPED", "MANUAL"
end

function TestRunner.RunAllTests()
    local results = { Total = 1, Passed = 0, Failed = 0, Skipped = 0, Manual = 0 }

    local result = TestRunner.TestSomething()
    if result == "PASS" then results.Passed = results.Passed + 1
    elseif result == "FAIL" then results.Failed = results.Failed + 1
    -- ... etc

    return results
end

return TestRunner
```

---

## FAQ

**Q: Can I run tests in a live production server?**
A: No! Use Studio or dedicated test servers. Never test on production.

**Q: How long does the full test suite take?**
A: 16-20 hours total (4-5 hours per day across 4 days)

**Q: What if a test fails?**
A: Document as bug, fix immediately if P0/P1, then re-test

**Q: Can I skip manual tests?**
A: No, they cover critical scenarios that can't be automated

**Q: Do I need Robux to test monetization?**
A: Ideally yes, but you can use test environment or skip purchase tests

---

**Version:** 1.0
**Last Updated:** 2026-02-22
**Status:** In Progress (7/17 modules complete)
**Next:** Complete remaining test modules
