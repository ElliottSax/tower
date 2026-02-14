# Tower Ascent - Comprehensive Testing Guide

**Last Updated:** 2025-12-01
**Status:** Production Testing Infrastructure Complete
**Test Coverage:** Validation, Edge Cases, Stress, Chaos, Profiling

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Test Suites](#test-suites)
4. [Validation Tests](#validation-tests)
5. [Edge Case Tests](#edge-case-tests)
6. [Stress Tests](#stress-tests)
7. [Chaos Engineering](#chaos-engineering)
8. [Error Recovery](#error-recovery)
9. [Performance Profiling](#performance-profiling)
10. [Testing Workflows](#testing-workflows)

---

## Overview

Tower Ascent includes a comprehensive 5-layer testing infrastructure:

- **Validation Tests** (7 tests) - Verify code review fixes remain in place
- **Edge Case Tests** (15 tests) - Boundary conditions and invalid inputs
- **Stress Tests** (8 tests) - Performance under load
- **Chaos Engineering** (7 scenarios) - Fault injection and resilience
- **Performance Profiling** - Real-time bottleneck detection

**Total Coverage:** 37+ automated tests + continuous profiling

---

## Quick Start

### Run All Tests

```lua
-- Validation (code review fixes)
_G.TowerAscent.ValidationTests.RunAll()

-- Edge cases
_G.TowerAscent.EdgeCaseTests.RunAll()

-- Stress tests
_G.TowerAscent.StressTests.RunAll()

-- Check profiler
_G.TowerAscent.DebugProfiler.PrintDashboard()
```

### Pre-Deployment Testing

```lua
-- 1. Validation
_G.TowerAscent.ValidationTests.RunAll()

-- 2. Edge cases
_G.TowerAscent.EdgeCaseTests.RunAll()

-- 3. Stress
_G.TowerAscent.StressTests.RunAll()

-- 4. Chaos (60 seconds)
_G.TowerAscent.ChaosMonkey.EnableChaos(60)
task.wait(65)

-- 5. Review
_G.TowerAscent.DebugProfiler.PrintDashboard()
_G.TowerAscent.ErrorRecovery.PrintErrorReport()
```

---

## Test Suites

### Available Utilities

```lua
_G.TowerAscent.ValidationTests   -- Code review fix validation
_G.TowerAscent.EdgeCaseTests     -- Boundary and edge cases
_G.TowerAscent.StressTests       -- Load and performance
_G.TowerAscent.ChaosMonkey       -- Chaos engineering
_G.TowerAscent.ErrorRecovery     -- Error handling
_G.TowerAscent.DebugProfiler     -- Performance profiling
```

---

## Validation Tests

**Purpose:** Ensure code review fixes remain in place

```lua
_G.TowerAscent.ValidationTests.RunAll()
```

### Tests (7)

1. **Syntax Check** - No Python syntax in Lua
2. **Checkpoint Debounce** - 1-second cooldown prevents spam
3. **Respawn Tracking** - Server-side tracking (not client attributes)
4. **VIP Rate Limiting** - 5-second cooldown on purchase prompts
5. **Section Validation** - Generator rejects invalid sections
6. **Memory Caching** - 80% reduction in GetDescendants() calls
7. **Connection Cleanup** - Prevents memory leaks

### Expected Output

```
================================================================================
VALIDATION TESTS - CODE REVIEW FIXES
================================================================================
✅ Syntax Check: PASS
✅ Checkpoint Debounce: PASS - blocked 9/10 spam attempts
✅ Respawn Tracking: PASS - server-side active
⚠️  VIP Rate Limiting: WARN - VIPService not configured (OK)
✅ Section Validation: PASS - invalid sections rejected
✅ Memory Manager Caching: PASS - 80% reduction
✅ Connection Cleanup: PASS - cleanup function exists

Total: 7 | Passed: 6 | Warnings: 1 (expected)
✅ ALL VALIDATION TESTS PASSED
```

---

## Edge Case Tests

**Purpose:** Test boundary conditions and invalid inputs

```lua
_G.TowerAscent.EdgeCaseTests.RunAll()
```

### Tests (15)

1. **Zero and Negative Values** - Rejects invalid coin amounts
2. **Extremely Large Values** - Handles 10 billion coins safely
3. **NaN and Infinity** - Rejects 0/0 and math.huge
4. **Nil Player Handling** - Graceful nil handling
5. **Rapid Checkpoint Touches** - Debounce prevents spam
6. **Concurrent Coin Operations** - No race conditions
7. **Invalid Checkpoint Sections** - Rejects section -1, 999
8. **Corrupted Player Data** - Handles corrupted profiles
9. **Missing Service Dependencies** - Graceful degradation
10. **Memory Manager Under Load** - Remains responsive
11. **Anti-Cheat False Positives** - Doesn't flag respawns
12. **VIP Status Race Conditions** - Synchronous loading
13. **Disconnected Player Cleanup** - Cleanup on disconnect
14. **Invalid Upgrade Purchases** - Validates before purchase
15. **Tower Generation Failures** - Recovery mechanisms

### Example: Test NaN Handling

```lua
_G.TowerAscent.EdgeCaseTests.TestNaNAndInfinity()
```

**Expected:**
```
✅ Edge Case Test: NaN and Infinity Handling
  - NaN coins rejected: ✓
  - Infinity coins rejected: ✓
  - Negative infinity rejected: ✓
  - Data integrity maintained: ✓
```

---

## Stress Tests

**Purpose:** Performance under realistic and extreme load

```lua
_G.TowerAscent.StressTests.RunAll()
```

### Tests (8)

1. **Rapid Coin Operations** - 1000 operations, ~milliseconds
2. **Concurrent Player Operations** - All players, 100 ops each
3. **Memory Leak Detection** - Memory delta < 10 MB
4. **Server FPS Under Load** - FPS ≥ 40 under artificial load
5. **Anti-Cheat Spam** - 1000 concurrent checks, remains responsive
6. **Checkpoint Spam Protection** - Blocks 999/1000 attempts
7. **Memory Manager Continuous** - 50 rapid cleanups
8. **Data Persistence Stress** - 500 read/write operations

### Sustained Load Test

```lua
-- 60-second high load simulation
_G.TowerAscent.StressTests.SimulateHighLoad(60)
```

**Output:**
```
============================================================
SIMULATING HIGH LOAD - 60 SECONDS
============================================================
[LoadTest] Time: 5s/60s | FPS: 58 | Memory: 185 MB | Ops: 1234
[LoadTest] Time: 10s/60s | FPS: 59 | Memory: 187 MB | Ops: 2456
...
============================================================
LOAD TEST COMPLETE
============================================================
Duration: 60.23s
Operations: 15234 (253 ops/sec)
Errors: 0 (0.00%)
Final FPS: 59
Final Memory: 192.4 MB
============================================================
```

---

## Chaos Engineering

**Purpose:** Test system resilience through fault injection

### Enable Chaos

```lua
-- 60-second chaos
_G.TowerAscent.ChaosMonkey.EnableChaos(60)

-- Indefinite (call DisableChaos to stop)
_G.TowerAscent.ChaosMonkey.EnableChaos()

-- Disable
_G.TowerAscent.ChaosMonkey.DisableChaos()
```

### Scenarios (7)

1. **Data Corruption** (5%) - Inject NaN/Infinity, should be rejected
2. **Service Failures** (10%) - Simulate temporary unavailability
3. **Memory Pressure** (5%) - 1 MB temporary spike
4. **Checkpoint Corruption** (10%) - Invalid checkpoint data
5. **Random Delays** (20%) - 0-2 second artificial latency
6. **Race Conditions** - 10 concurrent coin operations
7. **Anti-Cheat False Triggers** - Legitimate teleports

### Monitor Chaos

```lua
-- View chaos log
_G.TowerAscent.ChaosMonkey.PrintChaosLog()

-- Get statistics
_G.TowerAscent.ChaosMonkey.PrintStats()
```

**Output:**
```
============================================================
CHAOS MONKEY STATISTICS
============================================================
Status: ENABLED 🔥
Total Events: 47

Events by Type:
  DATA_CORRUPTION: 3
  SERVICE_FAILURE: 6
  MEMORY_PRESSURE: 2
  RANDOM_DELAY: 12
  RACE_CONDITION: 8
  ...
============================================================
```

### Safety

```lua
-- Only enable if Debug mode active
if _G.TowerAscent.ChaosMonkey.IsSafeToEnable() then
    _G.TowerAscent.ChaosMonkey.EnableChaos(30)
end
```

⚠️ **NEVER** run ChaosMonkey in production!

---

## Error Recovery

**Purpose:** Automatic retry and graceful degradation

### Retry with Exponential Backoff

```lua
local ErrorRecovery = _G.TowerAscent.ErrorRecovery

-- Retry up to 3 times
local success, result = ErrorRecovery.RetryOperation(function()
    return riskyOperation()
end, 3, "OperationName")
```

### Fallback Mechanisms

```lua
-- Register fallback
ErrorRecovery.RegisterFallback("DataService", function()
    return DefaultData
end)

-- Execute with fallback
local success, result = ErrorRecovery.ExecuteWithFallback(
    "DataService",
    function() return DataService.LoadData(player) end
)
```

### Circuit Breaker

```lua
-- Protects against cascading failures
local success, result = ErrorRecovery.ExecuteWithCircuitBreaker(
    "ExternalAPI",
    function() return API.Call() end
)
```

### Data Recovery

```lua
-- Recover player data
ErrorRecovery.RecoverPlayerData(player)

-- Recover tower
ErrorRecovery.RecoverTower()
```

### Error Reporting

```lua
-- Print error report
ErrorRecovery.PrintErrorReport()

-- Get stats
local stats = ErrorRecovery.GetErrorStats()
```

---

## Performance Profiling

**Purpose:** Real-time performance monitoring

### Start Profiling

```lua
local Profiler = _G.TowerAscent.DebugProfiler

-- Start
Profiler.Start()

-- Stop (prints report)
Profiler.Stop()

-- Reset
Profiler.Reset()
```

### Profile Functions

```lua
-- Profile specific function
local result = Profiler.ProfileFunction("ServiceName.Method", function()
    return YourFunction()
end)
```

### Dashboard

```lua
Profiler.PrintDashboard()
```

**Output:**
```
======================================================================
DEBUG PROFILER DASHBOARD
======================================================================
FPS: 59 | Memory: 187.3 MB | Players: 5 | Parts: 2341

----------------------------------------------------------------------
TOP 10 SLOWEST SERVICES (by average time)
----------------------------------------------------------------------
🟡 1. DataService.LoadProfile: 8.23ms | Calls: 15 | Max: 12.45ms
🟢 2. Generator.GenerateTower: 4.12ms | Calls: 3 | Max: 5.67ms
🟢 3. MemoryManager.Cleanup: 2.34ms | Calls: 120 | Max: 3.21ms

⚠️  BOTTLENECKS DETECTED
1. [MEDIUM] DataService.LoadProfile: 8.23ms average

MEMORY BREAKDOWN
Total: 187.3 MB
  InstanceCount: 45.2 MB
  PhysicsSteppingMemory: 23.1 MB
  GraphicsMemory: 89.4 MB
======================================================================
```

### Benchmarking

```lua
-- Benchmark 1000 iterations
Profiler.Benchmark("MyFunction", 1000, function()
    MyFunction()
end)
```

**Output:**
```
[DebugProfiler] Benchmarking MyFunction (1000 iterations)...
  Average: 2.345ms
  Median: 2.312ms
  Min: 1.987ms
  Max: 4.123ms
  Total: 2345ms
```

### Detect Bottlenecks

```lua
local bottlenecks = Profiler.DetectBottlenecks()
for i, bottleneck in ipairs(bottlenecks) do
    print(bottleneck.Type, bottleneck.Service, bottleneck.Severity)
end
```

---

## Testing Workflows

### Pre-Deployment Checklist

```lua
-- 1. Validation
_G.TowerAscent.ValidationTests.RunAll()

-- 2. Edge cases
_G.TowerAscent.EdgeCaseTests.RunAll()

-- 3. Stress tests
_G.TowerAscent.StressTests.RunAll()

-- 4. Start profiler
_G.TowerAscent.DebugProfiler.Start()

-- 5. Chaos (60 seconds)
_G.TowerAscent.ChaosMonkey.EnableChaos(60)
task.wait(65)

-- 6. Check results
_G.TowerAscent.DebugProfiler.PrintDashboard()
_G.TowerAscent.ErrorRecovery.PrintErrorReport()
_G.TowerAscent.ChaosMonkey.PrintStats()
```

### Continuous Monitoring

```lua
-- Start profiler
_G.TowerAscent.DebugProfiler.Start()

-- Enable auto-recovery
_G.TowerAscent.ErrorRecovery.EnableAutoRecovery()

-- Monitor every 60 seconds
while true do
    task.wait(60)
    _G.TowerAscent.DebugProfiler.PrintDashboard()
end
```

### Performance Investigation

```lua
-- 1. Start profiling
_G.TowerAscent.DebugProfiler.Start()

-- 2. Trigger suspected slow operation
-- (play the game, use systems)

-- 3. Check bottlenecks
local bottlenecks = _G.TowerAscent.DebugProfiler.DetectBottlenecks()

-- 4. Print dashboard
_G.TowerAscent.DebugProfiler.PrintDashboard()
```

---

## Best Practices

### Testing Frequency

| Environment | Tests | Frequency |
|------------|-------|-----------|
| Development | Validation | Every commit |
| Development | Edge Cases | Daily |
| Staging | All Tests | Before deploy |
| Production | Profiler only | Continuous |
| Production | Chaos | **NEVER** |

### When to Use Each Suite

- **ValidationTests** - After code review, before commits
- **EdgeCaseTests** - New features, refactors
- **StressTests** - Performance regressions, before deploy
- **ChaosMonkey** - Staging only, resilience testing
- **DebugProfiler** - Continuous, bottleneck detection
- **ErrorRecovery** - Production, automatic recovery

### Safety Guidelines

- ⚠️ **NEVER** run ChaosMonkey in production
- ⚠️ **NEVER** enable auto-recovery without monitoring
- ✅ **ALWAYS** run validation tests before deployment
- ✅ **ALWAYS** monitor profiler for bottlenecks
- ✅ **ALWAYS** review error recovery logs

---

## Troubleshooting

### Tests Not Found

**Issue:** `_G.TowerAscent.ValidationTests` is nil

**Solution:**
```lua
-- Check debug mode
print(_G.TowerAscent.Config.Debug.Enabled) -- Must be true

-- Restart server
```

### Tests Failing

**Issue:** Validation tests fail unexpectedly

**Solution:**
1. Check `CODE_REVIEW_SUMMARY.md` for expected behavior
2. Run individual test for detailed error
3. Verify no recent code changes broke fixes

### Profiler Not Starting

**Issue:** Profiler doesn't collect data

**Solution:**
```lua
-- Stop existing
_G.TowerAscent.DebugProfiler.Stop()

-- Reset
_G.TowerAscent.DebugProfiler.Reset()

-- Start fresh
_G.TowerAscent.DebugProfiler.Start()
```

---

## Additional Resources

- **Code Review Summary:** `CODE_REVIEW_SUMMARY.md`
- **Developer Guide:** `DEVELOPER_GUIDE.md`
- **Deployment Checklist:** `DEPLOYMENT_CHECKLIST.md`
- **Quick Reference:** `QUICK_REFERENCE.md`
- **Section Template Testing:** See below

---

## Legacy Testing (Sections/Themes/Platforms)

### Test Section Templates

```lua
_G.TowerAscent.DebugUtilities.TestAllSections()
```

### Test Moving Platforms

```lua
_G.TowerAscent.DebugUtilities.TestMovingPlatforms(tower)
```

### Test Themes

```lua
_G.TowerAscent.DebugUtilities.TestThemes(tower)
```

### Full Diagnostic

```lua
_G.TowerAscent.DebugUtilities.GenerateFullReport(tower)
```

---

**END OF TESTING GUIDE**

*For questions, see `DEVELOPER_GUIDE.md` or file an issue.*
