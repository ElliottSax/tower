# 🚀 Run Week 1 Tests - Quick Start Guide

**Time Required:** 5 minutes to start, 16-20 hours total
**Difficulty:** Easy (mostly automated)
**Status:** Ready to Execute

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Open Roblox Studio (1 min)
1. Launch Roblox Studio
2. Open any of your 5 games:
   - Tower Ascent
   - Speed Run Universe
   - Adventure Story Obby
   - Pet Collector Sim
   - Dimension Hopper

### Step 2: Copy Test Scripts (2 min)
1. In Roblox Studio Explorer, find **ServerScriptService**
2. Right-click → Insert Object → Folder
3. Name it: `test_scripts`
4. Copy all files from `/mnt/e/projects/roblox/test_scripts/` to this folder

**Directory structure should look like:**
```
ServerScriptService
└── test_scripts
    ├── MasterTestRunner (ModuleScript)
    ├── README (ModuleScript)
    ├── tower_ascent (Folder)
    │   ├── test_debug_mode
    │   ├── test_authentication
    │   ├── test_vip_race
    │   ├── test_coin_underflow
    │   └── test_monetization
    ├── speed_run_universe (Folder)
    ├── adventure_story_obby (Folder)
    ├── pet_collector_sim (Folder)
    ├── dimension_hopper (Folder)
    └── tools (Folder)
```

### Step 3: Run Tests (2 min)
1. Click **View** → **Output** (to see results)
2. Click **View** → **Command Bar** (to run commands)
3. In Command Bar, paste:

```lua
local Runner = require(game.ServerScriptService.test_scripts.MasterTestRunner)
Runner.RunAllTests()
```

4. Press **Enter**
5. Watch Output window for results

---

## 📊 What You'll See

### Sample Output

```
╔═══════════════════════════════════════════════════════════════╗
║        Master Test Suite - Roblox Games Portfolio            ║
║  Testing 17 Critical Fixes Across 5 Games                    ║
║  Total Test Cases: 60                                        ║
╚═══════════════════════════════════════════════════════════════╝

═════════════════════════════════════════════════════════════
GAME 1/5: TOWER ASCENT
═════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════╗
║  Tower Ascent - Debug Mode Protection Tests      ║
╚═══════════════════════════════════════════════════╝

=== TA-F1-1: Debug Mode Disabled in Production ===
⏭️  SKIP: Test requires production environment (test server)

=== TA-F1-2: Debug Mode Enabled in Studio ===
✅ PASS: Debug mode enabled in Studio
✅ PASS: _G.TowerAscent table exists

=== TA-F1-3: Webhook Alert Fires ===
✋ MANUAL TEST: Temporarily enable debug in production
  Expected: Security alert about debug mode

╔═══════════════════════════════════════════════════╗
║  Test Results Summary                             ║
╚═══════════════════════════════════════════════════╝
Total:   3
✅ Passed: 1
❌ Failed: 0
⏭️  Skipped: 1
✋ Manual: 1

... (continues for all 60 tests)

╔═══════════════════════════════════════════════════════════════╗
║                  FINAL TEST RESULTS SUMMARY                   ║
╚═══════════════════════════════════════════════════════════════╝

  Games Tested:       5/5
  Test Modules Run:   17
  Total Test Cases:   60

  ✅ Passed:          18 (30%)
  ❌ Failed:          0 (0%)
  ⏭️  Skipped:         0 (0%)
  ✋ Manual Required: 42 (70%)

  Duration:           45 seconds

╔═══════════════════════════════════════════════════════════════╗
║  Overall Status: ✅ PASS
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📋 Interpreting Results

### Status Codes

| Symbol | Status | Meaning |
|--------|--------|---------|
| ✅ | **PASS** | Test passed successfully |
| ❌ | **FAIL** | Test failed, bug found |
| ⏭️ | **SKIPPED** | Test skipped (needs different environment) |
| ✋ | **MANUAL** | Manual testing required |

### Expected Results

**In Roblox Studio:**
- **~18 automated tests should PASS** (30%)
- **~42 tests require MANUAL testing** (70%)
- **0-2 tests may SKIP** (need test server)
- **0 tests should FAIL** (all fixes implemented)

**If You See Failures (❌):**
1. Copy the error message
2. Check which test failed
3. Review the fix in FIXES_COMPLETED.md
4. Create bug report using BugReportGenerator
5. Fix the issue
6. Re-run tests

---

## 🔧 Using Testing Tools

### Performance Monitoring

Monitor memory and FPS during tests:

```lua
local Monitor = require(game.ServerScriptService.test_scripts.tools.PerformanceMonitor)
Monitor.StartMonitoring()

-- Let it run in background
-- Check memory every 30 seconds
-- Generates alerts if issues detected
```

**When to use:**
- Long-running tests (30+ minutes)
- Memory leak tests
- Performance validation

### Test Data Setup

Initialize test accounts with data:

```lua
local TestDataInit = require(game.ServerScriptService.test_scripts.tools.TestDataInitializer)

-- See what accounts are configured
TestDataInit.PrintGuide()

-- Initialize all test players
TestDataInit.InitializeAllTestPlayers()
```

**When to use:**
- Before manual testing
- After creating test accounts
- When test data gets corrupted

### Result Logging

Track all test executions:

```lua
local Logger = require(game.ServerScriptService.test_scripts.tools.TestResultLogger)

-- Run tests with logging
local results = Runner.RunAllTests()

-- Print summary
Logger.PrintSummary()

-- Export results
local markdown = Logger.ExportMarkdown()
print(markdown)
```

**When to use:**
- Document test sessions
- Track progress over time
- Generate test reports

### Bug Reporting

Create bug reports for failures:

```lua
local BugGen = require(game.ServerScriptService.test_scripts.tools.BugReportGenerator)

-- Example bug report
local failure = {
    Title = "Test failure description",
    Severity = "P1",
    Description = "What went wrong",
    Steps = {"Step 1", "Step 2"},
    Expected = "What should happen",
    Actual = "What actually happened"
}

local report = BugGen.FromTestFailure("TA-F1-1", "Tower Ascent", failure)
print(report)
```

**When to use:**
- Any test fails
- Found bugs during manual testing
- Need to document issues

---

## 📝 Manual Testing Required

After automated tests complete, you need to manually test:

### High Priority Manual Tests (Day 1)

**VIP Multiplier Testing (TA-F3-1, TA-F3-2):**
1. Create test account with VIP Game Pass
2. Join game
3. Collect coins
4. Verify 2x multiplier
5. Test with non-VIP account (1x multiplier)

**Speedrun Validation (SRU-F1-1):**
1. Complete a speedrun
2. Submit valid time
3. Check leaderboard
4. Verify time saved correctly

**Checkpoint Validation (ASO-F1-1, ASO-F1-2):**
1. Stand at checkpoint
2. Trigger checkpoint save
3. Die and respawn
4. Attempt distant checkpoint (should fail)

### See WEEK1_QUICK_CHECKLIST.md for complete schedule

---

## 🐛 If Tests Fail

### Debugging Steps

1. **Read the error message**
   ```
   ❌ FAIL: Expected 200 coins, got 100
   ```

2. **Check which fix is affected**
   - Error is in TA-F3-1
   - Related to Fix #3: VIP Race Condition
   - Check: `tower-ascent-game/FIXES_COMPLETED.md`

3. **Verify the fix was implemented**
   - Open the source file
   - Check if fix code is present
   - Verify logic is correct

4. **Create bug report**
   ```lua
   BugGen.FromTestFailure("TA-F3-1", "Tower Ascent", {
       Title = "VIP multiplier not working",
       Severity = "P1",
       Description = "VIP players get 1x instead of 2x",
       Expected = "200 coins",
       Actual = "100 coins"
   })
   ```

5. **Fix the bug**
   - Update the source code
   - Save the file
   - Re-run the test

6. **Re-test**
   ```lua
   local TestVIP = require(...test_vip_race)
   TestVIP.RunAllTests()
   ```

---

## 📊 Tracking Progress

### Update WEEK1_TESTING_PROGRESS.md

After each test session:

1. Open `WEEK1_TESTING_PROGRESS.md`
2. Update test status checkboxes
3. Fill in actual results
4. Note any bugs found
5. Update summary statistics

**Example:**
```markdown
| Test ID | Status | Expected | Actual | Notes |
|---------|--------|----------|--------|-------|
| TA-F1-1 | ⏭️ SKIP | Debug disabled | N/A | Needs test server |
| TA-F1-2 | ✅ PASS | Debug enabled | Debug enabled | Works in Studio |
| TA-F1-3 | ✋ MANUAL | Alert fires | Not tested | Need to test |
```

---

## ⏱️ Time Estimates

### Automated Tests Only
- **Setup:** 5 minutes
- **Execution:** 2-3 minutes
- **Review Results:** 10 minutes
- **Total:** ~15-20 minutes

### Full Week 1 Testing
- **Day 1:** Tower Ascent + Speed Run (8-10h)
- **Day 2:** Speed Run Universe (6-8h)
- **Day 3:** Adventure + Pet Collector (6-8h)
- **Day 4:** Dimension Hopper + Final (4-6h)
- **Total:** 16-20 hours

---

## 🎯 Success Criteria

### Automated Tests (Today)
- ✅ All 18 automated tests PASS
- ✅ 0 tests FAIL
- ✅ Results documented

### Week 1 Complete (4 Days)
- ✅ All 60 test cases executed
- ✅ 90%+ pass rate (54+ tests)
- ✅ All bugs documented
- ✅ P0/P1 bugs fixed
- ✅ Performance validated

---

## 🚨 Common Issues

### "Module not found"
**Problem:** Test scripts not in correct location
**Solution:** Verify test_scripts folder is in ServerScriptService

### "No players in server"
**Problem:** Some tests need active players
**Solution:** Start local server (Play mode) before running tests

### "DataService not found"
**Problem:** Game services not matching test expectations
**Solution:** Check game structure matches expected paths

### Tests run but no output
**Problem:** Output window not visible
**Solution:** View → Output to show output window

---

## 📞 Getting Help

**Documentation:**
- TESTING_GUIDE.md - Complete instructions
- MASTER_TESTING_SUITE.md - Test specifications
- TEST_ACCOUNTS_SETUP.md - Account setup
- test_scripts/README.md - Framework docs

**Quick Commands:**
```lua
-- Run all tests
MasterTestRunner.RunAllTests()

-- Run single game
test_module.RunAllTests()

-- Initialize test data
TestDataInitializer.InitializeAllTestPlayers()

-- Start monitoring
PerformanceMonitor.StartMonitoring()

-- Export results
TestResultLogger.ExportMarkdown()
```

---

## ✅ Checklist

**Before You Begin:**
- [ ] Roblox Studio installed
- [ ] Game opened in Studio
- [ ] test_scripts folder copied
- [ ] Output window visible
- [ ] Command bar visible

**After Automated Tests:**
- [ ] Results reviewed
- [ ] Pass rate calculated
- [ ] Failures documented
- [ ] Progress updated

**Next Steps:**
- [ ] Create test accounts (TestUser1-5)
- [ ] Begin manual testing
- [ ] Follow WEEK1_QUICK_CHECKLIST.md
- [ ] Complete Day 1 testing

---

**Ready to begin? Run this command in Studio:**

```lua
require(game.ServerScriptService.test_scripts.MasterTestRunner).RunAllTests()
```

**Good luck! 🚀**

---

**Created:** 2026-02-22
**Last Updated:** 2026-02-22
**Status:** Ready for Execution
