# Testing Tools - Comprehensive Suite

**Purpose:** Additional tools to support Week 1 testing phase
**Tools Available:** 4 (Performance Monitor, Test Data Initializer, Bug Report Generator, Test Result Logger)
**Total LOC:** ~1,500 lines

---

## Tools Overview

| Tool | Purpose | Type | Usage |
|------|---------|------|-------|
| **PerformanceMonitor** | Real-time performance tracking | Monitoring | Continuous |
| **TestDataInitializer** | Test account data setup | Setup | One-time |
| **BugReportGenerator** | Automated bug report creation | Documentation | As-needed |
| **TestResultLogger** | Test result tracking & reporting | Logging | Per-session |

---

## Tool 1: PerformanceMonitor.lua

### Purpose
Monitor game performance in real-time during testing to detect memory leaks, FPS drops, and DataStore issues.

### Features
- **Memory Tracking:** Total memory, memory growth rate, leak detection
- **Performance Metrics:** Server FPS, Heartbeat time, Physics step time
- **DataStore Monitoring:** Request count, error tracking
- **Network Stats:** Data send/receive rates
- **Alert System:** Automatic warnings when thresholds exceeded
- **Trend Analysis:** Memory growth trends over time

### Usage

**Start Monitoring:**
```lua
local Monitor = require(game.ServerScriptService.test_scripts.tools.PerformanceMonitor)
Monitor.StartMonitoring()

-- Runs continuously, reports every 30 seconds
```

**Get Current Snapshot:**
```lua
local snapshot = Monitor.GetSnapshot()
print("Memory:", snapshot.MemoryMB, "MB")
print("FPS:", snapshot.ServerFPS)
```

**Check Memory Trend:**
```lua
local trend = Monitor.GetMemoryTrend()
print("Status:", trend.Status)  -- HEALTHY, ELEVATED, POTENTIAL_LEAK, CRITICAL_LEAK
print("Growth Rate:", trend.GrowthRateMBPerHour, "MB/hour")
```

**Generate Report:**
```lua
Monitor.GenerateReport()
-- Prints comprehensive summary with memory analysis
```

### Configuration

Edit CONFIG table in PerformanceMonitor.lua:

```lua
local CONFIG = {
    UpdateInterval = 30,      -- Seconds between readings
    LogToConsole = true,     -- Print to output window
    SaveToDataStore = false, -- Persist metrics
    AlertThresholds = {
        MemoryMB = 2000,     -- Alert if memory > 2GB
        ServerFPS = 40,      -- Alert if FPS < 40
        DataStoreErrors = 5  -- Alert if errors > 5
    }
}
```

### When to Use

**Long-Running Tests:**
- ASO-F3-3: 30-minute collectible memory leak test
- DH-F1-3: 2-hour fragment memory leak test
- SRU-F2-3: 100 join/leave cycles memory test

**Load Testing:**
- 20-50 concurrent players stress test
- Extended gameplay sessions
- Memory baseline establishment

**Example Output:**
```
════════════════════════════════════════════════════════════
Performance Report - Uptime: 45 minutes
════════════════════════════════════════════════════════════

MEMORY:
  Total: 1,234.56 MB
  Places: 456.78 MB

PERFORMANCE:
  Server FPS: 58
  Heartbeat: 16.7 ms
  Physics Step: 2.3 ms

PLAYERS:
  Count: 5

DATASTORE:
  Requests: 142
  Errors: 0
════════════════════════════════════════════════════════════
```

---

## Tool 2: TestDataInitializer.lua

### Purpose
Automatically set up test accounts with specific data states for comprehensive scenario testing.

### Features
- **5 Pre-Configured Accounts:** New player, mid-game, near-max coins, VIP mid, VIP late
- **Auto-Initialization:** Automatically configure data when test accounts join
- **Manual Setup:** On-demand initialization for specific accounts
- **Reset Capability:** Reset accounts to baseline configuration
- **Stress Testing:** Generate stress test data (100+ pets, high values)

### Usage

**Print Configuration Guide:**
```lua
local TestDataInit = require(game.ServerScriptService.test_scripts.tools.TestDataInitializer)
-- Automatically prints guide when module loads
```

**Enable Auto-Initialization:**
```lua
TestDataInit.SetupAutoInitialization()
-- Test accounts will be configured when they join
```

**Manual Initialization:**
```lua
-- After test accounts join:
TestDataInit.InitializeAllTestPlayers()
-- Or for specific player:
TestDataInit.InitializePlayer(player, testConfig)
```

**Reset Account:**
```lua
-- Reset to baseline configuration:
TestDataInit.ResetPlayer(player)
```

**Create Stress Test Data:**
```lua
-- Generate 100 pets, high coins:
TestDataInit.CreateStressTestData(player)
```

### Test Account Configurations

See `/roblox/TEST_ACCOUNTS_SETUP.md` for detailed setup guide.

**Quick Reference:**
```
TestUser1: New Player (0 coins, Level 1)
TestUser2: Mid-Game (1K coins, Level 10)
TestUser3: Near Max (999.9M coins, Level 50)
TestUser4: VIP Mid (500 coins, Level 15, VIP)
TestUser5: VIP Late (10K coins, Level 99, VIP)
```

### When to Use

**Pre-Testing Setup:**
- Before beginning Week 1 testing
- After creating new test accounts
- When test data becomes corrupted

**During Testing:**
- Reset accounts between test sessions
- Switch between test scenarios
- Create edge-case data for specific tests

---

## Tool 3: BugReportGenerator.lua

### Purpose
Generate structured, detailed bug reports from test failures for efficient tracking and resolution.

### Features
- **Automated Report Generation:** Create bug reports from test failures
- **Severity Classification:** P0/P1/P2/P3 priority levels
- **Markdown Format:** GitHub-compatible formatted reports
- **Batch Processing:** Generate multiple reports from test session
- **Bug Summary:** Statistical overview of bugs by game and severity

### Usage

**Generate Bug Report from Test Failure:**
```lua
local BugGen = require(game.ServerScriptService.test_scripts.tools.BugReportGenerator)

local failureData = {
    Title = "VIP multiplier not working",
    Severity = "P1",
    Description = "VIP players not receiving 2x coin multiplier",
    Steps = {
        "Join as VIP player",
        "Collect 100 coins",
        "Check balance"
    },
    Expected = "200 coins added (2x multiplier)",
    Actual = "100 coins added (1x multiplier)",
    Impact = "VIP players not getting purchased benefits",
    RelatedFix = "Fix #3: VIP Race Condition",
    Logs = "[VIPService] IsVIP=true, Multiplier=1.0"
}

local report = BugGen.FromTestFailure("TA-F3-1", "Tower Ascent", failureData)
print(report)
```

**Batch Create Reports:**
```lua
local failures = {
    {TestCase = "TA-F3-1", Game = "Tower Ascent", Title = "VIP bug", Severity = "P1", ...},
    {TestCase = "SRU-F1-2", Game = "Speed Run Universe", Title = "Time validation", Severity = "P0", ...}
}

local reports = BugGen.BatchCreate(failures)
```

**Print Bug Summary:**
```lua
BugGen.PrintSummary(bugs)
```

### Bug Report Template

Generated reports follow this structure:

```markdown
# Bug Report

**Bug ID:** BUG-TowerAscent-1708876543
**Title:** [Tower Ascent] - P1 - VIP multiplier not working
**Severity:** P1
**Status:** New
**Created:** 2026-02-22 15:30:45

## Description
VIP players not receiving 2x coin multiplier

## Steps to Reproduce
1. Join as VIP player
2. Collect 100 coins
3. Check balance

## Expected Behavior
200 coins added (2x multiplier)

## Actual Behavior
100 coins added (1x multiplier)

## Impact
VIP players not getting purchased benefits

## Environment
- **Game:** Tower Ascent
- **Test Case:** TA-F3-1
- **Platform:** Roblox Studio
- **Roblox Version:** Latest

## Related Fix
Related to: Fix #3: VIP Race Condition

---
**Reported By:** Claude Code (Automated Test)
**Session:** Week 1 Testing Phase
```

### When to Use

**After Test Failures:**
- Immediately after discovering bugs
- At end of testing session
- When QA reports issues

**During Bug Triage:**
- Organize bugs by priority
- Generate summary statistics
- Export for external tracking systems

---

## Tool 4: TestResultLogger.lua

### Purpose
Track all test executions, results, and generate comprehensive reports for analysis and documentation.

### Features
- **Automatic Logging:** Log every test result (PASS/FAIL/SKIPPED/MANUAL)
- **Session Tracking:** Track entire test session from start to finish
- **Summary Statistics:** Pass rate, duration, failure counts
- **Export Formats:** Markdown and JSON export
- **Pass Rate by Game:** Analyze results per game
- **Failed Test Extraction:** Quickly identify all failures

### Usage

**Log Individual Test Result:**
```lua
local Logger = require(game.ServerScriptService.test_scripts.tools.TestResultLogger)

Logger.LogResult({
    TestID = "TA-F1-1",
    Game = "Tower Ascent",
    Fix = "Fix #1: Debug Mode",
    Description = "Debug mode disabled in production",
    Status = "PASS",  -- or FAIL, SKIPPED, MANUAL
    Expected = "_G.TowerAscent = nil",
    Actual = "_G.TowerAscent = nil",
    Duration = 5,
    Notes = "Verified in test server"
})
```

**Log Test Suite:**
```lua
local results = {
    {TestID = "TA-F1-1", Status = "PASS", ...},
    {TestID = "TA-F1-2", Status = "PASS", ...},
    {TestID = "TA-F1-3", Status = "MANUAL", ...}
}

Logger.LogSuite("Tower Ascent - Debug Mode", results)
```

**Print Session Summary:**
```lua
Logger.PrintSummary()
```

**Get Failed Tests:**
```lua
local failed = Logger.GetFailedTests()
for _, test in ipairs(failed) do
    print("Failed:", test.TestID, test.Description)
end
```

**Export Results:**
```lua
-- Markdown format (for documentation)
local markdown = Logger.ExportMarkdown()
print(markdown)

-- JSON format (for external tools)
local json = Logger.ExportJSON()
print(json)
```

**Reset Session:**
```lua
-- Start new test run
Logger.ResetSession()
```

### Example Output

**Summary:**
```
╔═══════════════════════════════════════════════════════════════╗
║   Test Session Summary                                        ║
╚═══════════════════════════════════════════════════════════════╝
Duration: 45 minutes
Total Tests: 25
✅ Passed: 22 (88.0%)
❌ Failed: 1
⏭️  Skipped: 1
✋ Manual: 1

⚠️  FAILURES DETECTED:
  - TA-F3-1: VIP player gets 2x coins
    Error: Multiplier = 1.0, expected 2.0
╚═══════════════════════════════════════════════════════════════╝
```

**Pass Rate by Game:**
```
Tower Ascent: 14/15 (93.3%)
Speed Run Universe: 18/20 (90.0%)
Adventure Story Obby: 9/9 (100.0%)
Pet Collector Sim: 11/12 (91.7%)
Dimension Hopper: 4/4 (100.0%)
```

### Integration with Test Scripts

**Integrate with test runners:**
```lua
-- In test modules:
local Logger = require(game.ServerScriptService.test_scripts.tools.TestResultLogger)

function TestRunner.RunAllTests()
    -- Run tests...

    -- Log each result
    for _, test in ipairs(tests) do
        Logger.LogResult({
            TestID = test.id,
            Game = "Tower Ascent",
            Status = test.result,
            ...
        })
    end

    return results
end
```

### When to Use

**Every Test Session:**
- Start of test run: Logger.ResetSession()
- During tests: Logger.LogResult() for each test
- End of session: Logger.PrintSummary()
- Export results: Logger.ExportMarkdown()

**Analysis:**
- Identify failure patterns
- Track pass rate trends
- Generate documentation
- Share results with team

---

## Combined Workflow Example

### Complete Test Session with All Tools

```lua
-- 1. Initialize test data
local TestDataInit = require(...TestDataInitializer)
TestDataInit.InitializeAllTestPlayers()

-- 2. Start performance monitoring
local Monitor = require(...PerformanceMonitor)
Monitor.StartMonitoring()

-- 3. Start test logging
local Logger = require(...TestResultLogger)
Logger.ResetSession()

-- 4. Run tests (example)
for _, testModule in ipairs(testModules) do
    local results = testModule.RunAllTests()

    -- Log results
    for _, result in ipairs(results) do
        Logger.LogResult(result)
    end
end

-- 5. Check for failures
local failed = Logger.GetFailedTests()

-- 6. Generate bug reports for failures
if #failed > 0 then
    local BugGen = require(...BugReportGenerator)
    local bugs = BugGen.BatchCreate(failed)
    BugGen.PrintSummary(bugs)
end

-- 7. Print final reports
Logger.PrintDetailedReport()
Monitor.GenerateReport()

-- 8. Export results
local markdown = Logger.ExportMarkdown()
local perfData = Monitor.ExportData()

print("═══ Test Session Complete ═══")
print("Results exported to markdown")
print("Performance data exported")
```

---

## Installation

### Copy to Game

1. Create `test_scripts/tools/` folder in ServerScriptService
2. Copy all 4 tool files to the folder
3. Tools are now available to test scripts

### Folder Structure

```
ServerScriptService/
└── test_scripts/
    ├── tools/
    │   ├── README.md (this file)
    │   ├── PerformanceMonitor.lua
    │   ├── TestDataInitializer.lua
    │   ├── BugReportGenerator.lua
    │   └── TestResultLogger.lua
    ├── tower_ascent/
    ├── speed_run_universe/
    └── ... other test folders
```

---

## Best Practices

### Performance Monitoring
- ✅ Start monitoring at beginning of long tests
- ✅ Check memory trend every 15-30 minutes
- ✅ Export data for later analysis
- ❌ Don't rely on single snapshot

### Test Data
- ✅ Reset accounts between test sessions
- ✅ Verify data after initialization
- ✅ Use appropriate account for each test
- ❌ Don't modify test configurations during active testing

### Bug Reporting
- ✅ Generate reports immediately after finding bugs
- ✅ Include detailed steps to reproduce
- ✅ Attach server logs and screenshots
- ❌ Don't delay bug documentation

### Result Logging
- ✅ Log every test execution
- ✅ Export results at end of session
- ✅ Archive results for trend analysis
- ❌ Don't forget to reset between sessions

---

## Troubleshooting

### Performance Monitor

**Issue:** No data collected
- **Fix:** Check UpdateInterval setting
- **Fix:** Ensure Monitor.StartMonitoring() was called

**Issue:** False memory leak alerts
- **Fix:** Increase AlertThresholds.MemoryMB
- **Fix:** Check for natural memory growth (players joining)

### Test Data Initializer

**Issue:** Data not persisting
- **Fix:** Verify DataService is working
- **Fix:** Check ProfileService session locking

**Issue:** Wrong data loaded
- **Fix:** Run TestDataInit.ResetPlayer(player)
- **Fix:** Verify player name matches exactly

### Bug Report Generator

**Issue:** Missing required fields
- **Fix:** Provide all required fields in failureData
- **Fix:** Check template for required parameters

### Test Result Logger

**Issue:** Results not saving
- **Fix:** Logger only stores in memory (not persistent)
- **Fix:** Export to markdown/JSON for persistence

---

## Advanced Usage

### Custom Performance Metrics

Extend PerformanceMonitor with game-specific metrics:

```lua
-- Add custom metric
function Monitor.GetCustomSnapshot()
    local snapshot = Monitor.GetSnapshot()

    -- Add game-specific data
    snapshot.ActiveGhosts = #SpeedrunService.GhostRecordings
    snapshot.ActiveCollectibles = #CollectibleService.ActiveCollectibles

    return snapshot
end
```

### Custom Test Data Profiles

Add new test account configurations:

```lua
-- In TestDataInitializer.lua, add to TEST_ACCOUNTS:
{
    Name = "TestUser6",
    Description = "Exploiter test account",
    Data = {
        Coins = 1000000000,  -- Max coins
        Flagged = true,
        BanStatus = "warned"
    }
}
```

### Custom Bug Report Templates

Modify bug report format in BugReportGenerator.lua:

```lua
-- Add custom sections
table.insert(report, "## Team Assignment")
table.insert(report, string.format("Assigned to: %s", data.Assignee or "Unassigned"))
```

---

## API Reference

### PerformanceMonitor API

```lua
Monitor.StartMonitoring()                    -- Start continuous monitoring
Monitor.GetSnapshot() -> table              -- Get current metrics
Monitor.GetMemoryTrend() -> table           -- Get memory analysis
Monitor.GenerateReport()                    -- Print summary report
Monitor.ExportData() -> table               -- Export all data
```

### TestDataInitializer API

```lua
TestDataInit.InitializePlayer(player, config) -> boolean
TestDataInit.SetupAutoInitialization()
TestDataInit.InitializeAllTestPlayers()
TestDataInit.ResetPlayer(player) -> boolean
TestDataInit.CreateStressTestData(player) -> boolean
TestDataInit.PrintGuide()
```

### BugReportGenerator API

```lua
BugGen.FromTestFailure(testCase, game, failureData) -> string
BugGen.CreateInteractive()
BugGen.ExportReport(report, filename) -> string
BugGen.BatchCreate(failures) -> table
BugGen.PrintSummary(bugs)
```

### TestResultLogger API

```lua
Logger.LogResult(testData) -> table
Logger.LogSuite(suiteName, results)
Logger.GetSummary() -> table
Logger.PrintSummary()
Logger.ExportMarkdown() -> string
Logger.ExportJSON() -> string
Logger.ResetSession()
Logger.GetFailedTests() -> table
Logger.GetPassRateByGame() -> table
Logger.PrintDetailedReport()
```

---

**Last Updated:** 2026-02-22
**Version:** 1.0
**Status:** Production Ready
