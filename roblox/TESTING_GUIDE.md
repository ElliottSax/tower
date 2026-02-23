# Week 1 Testing Guide - Roblox Games Portfolio

**Purpose:** Execute all 60 test cases to validate 17 critical fixes across 5 games
**Duration:** 16-20 hours estimated
**Phase:** Unit Testing & Critical Fix Validation

---

## Quick Start

### Option 1: Automated Testing (Recommended)

**Run all tests via Master Test Runner:**

1. Open Roblox Studio
2. Open any game from the portfolio
3. Open Server Script Service
4. Run this in the Command Bar:

```lua
-- Load and run master test suite
local TestRunner = require(game.ServerScriptService.test_scripts.MasterTestRunner)
local results = TestRunner.RunAllTests()

-- Results will print to Output window
```

**Expected Output:**
- Summary of all 60 test cases
- Pass/Fail status for each test
- Overall portfolio health score

---

### Option 2: Per-Game Testing

**Test individual games:**

```lua
-- Tower Ascent - Debug Mode Test
local TestDebug = require(game.ServerScriptService.test_scripts.tower_ascent.test_debug_mode)
TestDebug.RunAllTests()

-- Tower Ascent - Authentication Test
local TestAuth = require(game.ServerScriptService.test_scripts.tower_ascent.test_authentication)
TestAuth.RunAllTests()

-- Continue with other test modules...
```

---

## Test Environment Setup

### Prerequisites

**Required:**
- ✅ Roblox Studio installed (latest version)
- ✅ All 5 games published to Studio
- ✅ Test scripts copied to each game's ServerScriptService
- ✅ Test accounts created (TestUser1-5)

**Optional:**
- ✅ Discord/Slack webhook for alerts
- ✅ Test server published for production tests
- ✅ VIP Game Pass for monetization tests

---

### Test Accounts Setup

Create these test accounts in Roblox:

| Account | Purpose | Setup |
|---------|---------|-------|
| TestUser1 | New player testing | No data, no VIP |
| TestUser2 | Mid-game progression | 1000 coins, no VIP |
| TestUser3 | Max coins testing | 999,999,999 coins, no VIP |
| TestUser4 | VIP testing | 500 coins, **VIP Game Pass** |
| TestUser5 | Late-game VIP | 10,000 coins, **VIP Game Pass** |

---

## Testing Workflow

### Step 1: Studio Environment Tests

**What to test:**
- Debug mode enabled in Studio
- Code functionality
- Basic game mechanics

**Run these tests in Studio:**
- TA-F1-2 (Debug mode enabled)
- TA-F2-3 (Nil player handling)
- TA-F4 (Coin underflow)
- TA-F5-3 (Product ID validation)

**How to run:**
1. Open game in Roblox Studio
2. Click "Play" to start local server
3. Open Command Bar (View → Output → Command Bar)
4. Run test scripts as shown above
5. Check Output window for results

---

### Step 2: Test Server Environment Tests

**What to test:**
- Debug mode disabled in production
- Server-authoritative validation
- Security fixes

**Run these tests on test server:**
- TA-F1-1 (Debug mode disabled)
- All checkpoint validation tests
- All security tests
- Rate limiting tests

**How to run:**
1. Publish game to "Test Server" version
2. Join test server with test account
3. Execute remote actions (hatch eggs, set checkpoints)
4. Monitor server logs in Developer Console
5. Verify exploits are blocked

---

### Step 3: Manual Testing

**Required for:**
- Monetization (Robux purchases)
- VIP multiplier validation
- Real player scenarios
- Exploit attempts

**Manual Test Checklist:**

#### Tower Ascent
- [ ] VIP player gets 2x coins (TA-F3-1)
- [ ] Non-VIP player gets 1x coins (TA-F3-2)
- [ ] Purchase VIP Game Pass (TA-F5-1)
- [ ] Purchase 1000 Coin Pack (TA-F5-2)

#### Speed Run Universe
- [ ] Complete valid speedrun (SRU-F1-1)
- [ ] Attempt impossible time 0.1s (SRU-F1-2)
- [ ] Submit backwards checkpoints (SRU-F1-3)
- [ ] Verify ghost compression <100KB (SRU-F3-1)
- [ ] Watch ghost playback smooth (SRU-F3-4)

#### Adventure Story Obby
- [ ] Set valid checkpoint (ASO-F1-1)
- [ ] Attempt distant checkpoint (ASO-F1-2)
- [ ] Collect coins near cap (ASO-F2-2)
- [ ] Rapid collectible collection (ASO-F3-2)

#### Pet Collector Sim
- [ ] Hatch egg with sufficient coins (PCS-F1-1)
- [ ] Hatch egg with insufficient coins (PCS-F1-2)
- [ ] Attempt trade (should be disabled) (PCS-F2-1)
- [ ] Spam hatch egg 25x rapidly (PCS-F3-1)
- [ ] Send invalid egg type (PCS-F3-2)

#### Dimension Hopper
- [ ] Collect 10 fragments (DH-F1-1)
- [ ] Stress test 100 fragments (DH-F1-2)
- [ ] Monitor memory for 2 hours (DH-F1-3)

---

## Test Result Documentation

### Recording Results

**For each test, document:**

1. **Test ID** (e.g., TA-F1-1)
2. **Status** (✅ PASS / ❌ FAIL / ⏭️ SKIP / ✋ MANUAL)
3. **Expected Result** (from test suite)
4. **Actual Result** (what actually happened)
5. **Notes** (any observations, warnings, errors)
6. **Screenshots** (if applicable)

**Update tracking document:**
- Open `/roblox/WEEK1_TESTING_PROGRESS.md`
- Update test status checkboxes
- Add notes to each test row
- Update pass/fail counts
- Log any bugs found

---

### Bug Reporting

**If a test fails:**

1. Create bug report using this template:

```markdown
## Bug: [GAME] - [SEVERITY] - Brief description

**Test Case:** TA-F1-1 (Debug Mode Disabled in Production)

**Severity:** P0 (Critical - blocks launch)

**Description:**
Debug mode is enabled in production, exposing _G.TowerAscent global table

**Steps to Reproduce:**
1. Publish Tower Ascent to test server
2. Join test server
3. Check `_G.TowerAscent` in developer console
4. Table exists (should be nil)

**Expected:** _G.TowerAscent = nil
**Actual:** _G.TowerAscent = { DataService, VIPService, ... }

**Impact:**
CRITICAL - Exploiters can access internal services and manipulate game state

**Screenshots:**
[Attach screenshot of developer console]

**Environment:**
- Game: Tower Ascent
- Server: Test Server (not Studio)
- Roblox Version: 2.621.123
- Date: 2026-02-22
```

2. Add to bugs section in WEEK1_TESTING_PROGRESS.md
3. Assign priority (P0/P1/P2/P3)
4. Fix immediately if P0 or P1

---

## Expected Results Summary

### Tower Ascent (15 tests)

| Fix | Automated | Manual | Expected Pass Rate |
|-----|-----------|--------|-------------------|
| Debug Mode | 2/3 | 1/3 | 100% |
| Authentication | 2/3 | 1/3 | 100% |
| VIP Race | 1/4 | 3/4 | 100% |
| Coin Underflow | 3/3 | 0/3 | 100% |
| Monetization | 1/4 | 3/4 | 100% |

**Total:** 9 automated, 6 manual

---

### Speed Run Universe (20 tests)

| Fix | Automated | Manual | Expected Pass Rate |
|-----|-----------|--------|-------------------|
| Speedrun Validation | 1/5 | 4/5 | 100% |
| Player Cleanup | 1/3 | 2/3 | 100% |
| Ghost Compression | 1/4 | 3/4 | 100% |
| Size Limits | 0/3 | 3/3 | 100% |
| Leaderboard | 2/4 | 2/4 | 100% |

**Total:** 5 automated, 15 manual

---

### Adventure Story Obby (9 tests)

| Fix | Automated | Manual | Expected Pass Rate |
|-----|-----------|--------|-------------------|
| Checkpoint Validation | 0/4 | 4/4 | 100% |
| Coin Cap | 1/3 | 2/3 | 100% |
| Collectible Memory | 0/3 | 3/3 | 100% |

**Total:** 1 automated, 8 manual

---

### Pet Collector Sim (12 tests)

| Fix | Automated | Manual | Expected Pass Rate |
|-----|-----------|--------|-------------------|
| Negative Coins | 2/4 | 2/4 | 100% |
| Trading Disabled | 1/3 | 2/3 | 100% |
| SecureRemotes | 0/4 | 4/4 | 100% |

**Total:** 3 automated, 9 manual

---

### Dimension Hopper (4 tests)

| Fix | Automated | Manual | Expected Pass Rate |
|-----|-----------|--------|-------------------|
| Fragment Memory | 0/4 | 4/4 | 100% |

**Total:** 0 automated, 4 manual

---

## Overall Testing Summary

**Total Test Cases:** 60
**Automated Tests:** 18 (30%)
**Manual Tests:** 42 (70%)
**Expected Duration:** 16-20 hours

**Success Criteria:**
- ✅ All automated tests pass (18/18)
- ✅ All manual tests pass (42/42)
- ✅ No P0 bugs found
- ✅ No more than 3 P1 bugs
- ✅ Performance benchmarks met
- ✅ Security validated

---

## Troubleshooting

### Common Issues

**Issue:** Test script not found
- **Fix:** Ensure test scripts are in ServerScriptService/test_scripts/

**Issue:** "Could not load DataService"
- **Fix:** Check game structure matches expected paths

**Issue:** No players in server (tests skipped)
- **Fix:** Join server with test account before running tests

**Issue:** Manual tests can't be automated
- **Fix:** That's expected - follow manual test procedures

---

## Next Steps After Week 1

**After completing all tests:**

1. ✅ Update WEEK1_TESTING_PROGRESS.md with final results
2. ✅ Create bug reports for all failures
3. ✅ Fix all P0 and P1 bugs
4. ✅ Re-test fixed bugs
5. ✅ Generate summary report
6. ✅ Move to Week 2: Load & Performance Testing

**Sign-off required from:**
- QA Lead (review all test results)
- Development Lead (confirm all P0/P1 bugs fixed)
- Project Manager (approve move to Week 2)

---

## Contact & Support

**Questions?**
- Check MASTER_TESTING_SUITE.md for detailed test specifications
- Review FIXES_COMPLETED.md for implementation details
- Check DEPLOYMENT_ROADMAP.md for timeline

**Report Issues:**
- Discord: #qa-testing channel
- Document: WEEK1_TESTING_PROGRESS.md → Bugs Found section

---

**Last Updated:** 2026-02-22
**Version:** 1.0
**Status:** Ready for execution
