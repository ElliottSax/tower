# Master Testing Suite - Roblox Games Portfolio
**Comprehensive Testing Plan for Production Launch**

**Date:** 2026-02-22
**Version:** 1.0
**Games Covered:** 5 (Tower Ascent, Speed Run Universe, Adventure Story Obby, Pet Collector Sim, Dimension Hopper)
**Total Critical Fixes:** 17
**Estimated Testing Time:** 40-60 hours

---

## Table of Contents

1. [Overview & Test Strategy](#1-overview--test-strategy)
2. [Test Environment Setup](#2-test-environment-setup)
3. [Per-Game Critical Fix Testing](#3-per-game-critical-fix-testing)
4. [Integration Testing](#4-integration-testing)
5. [Performance & Load Testing](#5-performance--load-testing)
6. [Security Testing](#6-security-testing)
7. [Pre-Launch Validation](#7-pre-launch-validation)
8. [Success Criteria & Metrics](#8-success-criteria--metrics)
9. [Test Automation](#9-test-automation)
10. [Bug Tracking & Reporting](#10-bug-tracking--reporting)

---

## 1. Overview & Test Strategy

### 1.1 Testing Objectives

**Primary Goals:**
- ✅ Validate all 17 critical fixes work as intended
- ✅ Ensure no regressions introduced by fixes
- ✅ Verify production readiness (95%+ confidence)
- ✅ Establish performance baselines
- ✅ Identify and fix any remaining issues before launch

**Testing Approach:**
- **Bottom-Up:** Start with unit tests for individual fixes
- **Integration:** Test fixes working together in real gameplay
- **Load Testing:** Stress test with simulated player load
- **Security:** Attempt exploits to validate protections
- **User Acceptance:** Real player testing on test servers

### 1.2 Games & Fix Summary

| Game | Critical Fixes | Priority | Testing Time | Status |
|------|----------------|----------|--------------|--------|
| **Tower Ascent** | 5 fixes | P0 (Wave 1) | 12h | Ready for QA |
| **Speed Run Universe** | 5 fixes | P0 (Wave 1) | 12h | Ready for QA |
| **Adventure Story Obby** | 3 fixes | P1 (Wave 2) | 8h | Ready for QA |
| **Pet Collector Sim** | 3 fixes | P1 (Wave 3) | 8h | Ready for QA |
| **Dimension Hopper** | 1 fix + audit | P1 (Wave 3) | 6h | Ready for QA |
| **TOTAL** | **17 fixes** | - | **46h** | **5/5 Complete** |

### 1.3 Test Phases

**Phase 1: Unit Testing (Week 1)**
- Individual fix validation
- Automated test scripts
- Developer-led testing
- Duration: 16-20 hours

**Phase 2: Integration Testing (Week 1-2)**
- Full gameplay flows
- Cross-service interactions
- Real player scenarios
- Duration: 12-16 hours

**Phase 3: Load & Performance Testing (Week 2)**
- Concurrent players (20-50 CCU)
- Memory leak detection
- DataStore quota monitoring
- Duration: 8-12 hours

**Phase 4: Security Testing (Week 2)**
- Exploit attempts
- Rate limit validation
- Input fuzzing
- Duration: 8-12 hours

**Phase 5: User Acceptance Testing (Week 3)**
- Beta testers on test server
- Feedback collection
- Bug fixes
- Duration: Ongoing

---

## 2. Test Environment Setup

### 2.1 Required Test Environments

**Environment 1: Local Studio (Development)**
- **Purpose:** Unit testing, debugging
- **Setup:** Roblox Studio with all games published
- **Access:** Developers only
- **Data:** Test data, not production

**Environment 2: Test Server (Staging)**
- **Purpose:** Integration testing, load testing
- **Setup:** Published to Roblox with "Test Server" naming
- **Access:** Developers + beta testers
- **Data:** Separate DataStore from production

**Environment 3: Production Server (Live)**
- **Purpose:** Final validation, monitoring
- **Setup:** Published to Roblox as public games
- **Access:** Public
- **Data:** Production DataStore

### 2.2 Test Tools Required

**Monitoring Tools:**
- [ ] Roblox Developer Console (built-in)
- [ ] Server Stats monitoring (custom script)
- [ ] DataStore usage tracking
- [ ] Memory profiler (Roblox DevConsole)
- [ ] Discord/Slack webhooks for alerts

**Testing Scripts:**
- [ ] Automated test runner (Lua)
- [ ] Load testing bot (simulate players)
- [ ] Exploit testing scripts
- [ ] Performance benchmarking script

**External Tools:**
- [ ] Postman/Insomnia (for API testing if applicable)
- [ ] Git for version control
- [ ] Notion/Jira for bug tracking

### 2.3 Test Data Setup

**Test Accounts:**
- Create 10 test accounts (TestUser1-10)
- Each with different progression levels
- Some with VIP passes, some without
- Different coin balances (0, 100, 1000, 999999999)

**Test Scenarios:**
- New player (no data)
- Returning player (saved data)
- VIP player
- Non-VIP player
- Player with max coins
- Player with 0 coins

---

## 3. Per-Game Critical Fix Testing

### 3.1 Tower Ascent Game (5 Fixes)

#### **Fix #1: Debug Mode Protection**
**File:** `Main.server.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TA-F1-1 | Debug mode disabled in production | 1. Publish to test server<br>2. Check server logs<br>3. Attempt to access `_G.TowerAscent` | `_G.TowerAscent` is nil, warning logged | ⬜ |
| TA-F1-2 | Debug mode enabled in Studio | 1. Run in Studio with Debug=true<br>2. Check `_G.TowerAscent` | Table exists with services | ⬜ |
| TA-F1-3 | Webhook alert fires | 1. Manually set Debug=true in prod<br>2. Restart server<br>3. Check Discord/Slack webhook | Alert received with security warning | ⬜ |

**Validation Script:**
```lua
-- In Studio command bar:
print("Debug Mode:", game:GetService("ReplicatedStorage").Shared.Config.GameConfig.Debug.Enabled)
print("_G.TowerAscent:", _G.TowerAscent)

-- Expected in Studio: Debug = true, _G.TowerAscent = table
-- Expected in Production: Debug = false, _G.TowerAscent = nil
```

---

#### **Fix #2: SecurityManager.IsAuthenticated()**
**File:** `SecurityManager.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TA-F2-1 | New player authenticated | 1. Join as new player<br>2. Wait for authorization<br>3. Trigger secure remote | RemoteEvent fires successfully | ⬜ |
| TA-F2-2 | Banned player rejected | 1. Ban test account<br>2. Join as banned player<br>3. Trigger secure remote | RemoteEvent rejected, warning logged | ⬜ |
| TA-F2-3 | Nil player handled | 1. Call IsAuthenticated(nil)<br>2. Check return value | Returns false, no error | ⬜ |

**Validation Script:**
```lua
-- In server console:
local SecurityManager = require(game.ServerScriptService.Security.SecurityManager)
local player = game.Players:GetPlayers()[1]

print("Is Authenticated:", SecurityManager.IsAuthenticated(player))
print("Is Authenticated (nil):", SecurityManager.IsAuthenticated(nil))

-- Expected: true for valid player, false for nil
```

---

#### **Fix #3: VIP Race Condition**
**File:** `VIPService.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TA-F3-1 | VIP player gets 2x coins | 1. Join as VIP player<br>2. Collect 100 coins<br>3. Check coin balance | 200 coins awarded (2x multiplier) | ⬜ |
| TA-F3-2 | Non-VIP gets 1x coins | 1. Join as non-VIP<br>2. Collect 100 coins<br>3. Check coin balance | 100 coins awarded (1x multiplier) | ⬜ |
| TA-F3-3 | VIP status cached | 1. Join as VIP player<br>2. Leave and rejoin within 5 min<br>3. Check VIP status load time | Instant load from cache | ⬜ |
| TA-F3-4 | Pending state prevents 0 coins | 1. Disable VIP service temporarily<br>2. Join as VIP player<br>3. Collect coins during pending<br>4. Wait for VIP check to complete | Coins accumulated during pending, then 2x applied retroactively | ⬜ |

**Validation Script:**
```lua
-- Check VIP status and pending state:
local player = game.Players.LocalPlayer
print("VIP Status:", player:GetAttribute("IsVIP"))
print("VIP Pending:", player:GetAttribute("VIPCheckPending"))

-- Collect coins and verify multiplier
-- Expected: VIP=true gives 2x, VIP=false gives 1x, VIP=nil waits
```

---

#### **Fix #4: Coin Underflow Protection**
**File:** `DataService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TA-F4-1 | Remove more coins than available | 1. Player has 50 coins<br>2. Attempt to remove 100 coins<br>3. Check balance | Coins = 0 (capped), warning logged | ⬜ |
| TA-F4-2 | Remove exact amount | 1. Player has 100 coins<br>2. Remove 100 coins<br>3. Check balance | Coins = 0 (no error) | ⬜ |
| TA-F4-3 | Leaderstats update correctly | 1. Remove coins<br>2. Check leaderstats display | Leaderstats shows correct value | ⬜ |

**Validation Script:**
```lua
-- Server console:
local DataService = require(game.ServerScriptService.Services.DataService)
local player = game.Players:GetPlayers()[1]

-- Set player to 50 coins
DataService.SetPlayerData(player, "Coins", 50)

-- Try to remove 100 coins
local success = DataService.RemoveCoins(player, 100)
print("Remove Success:", success)
print("Final Coins:", DataService.GetPlayerData(player, "Coins"))

-- Expected: coins = 0, warning in log about underflow prevented
```

---

#### **Fix #5: Monetization Product IDs**
**File:** `GameConfig.lua`, `MonetizationService.lua`
**Testing Time:** 3 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TA-F5-1 | VIP Game Pass purchase | 1. Purchase VIP pass<br>2. Check VIP status<br>3. Collect coins | VIP granted, 2x multiplier active | ⬜ |
| TA-F5-2 | Coin pack purchase | 1. Purchase 1000 coin pack<br>2. Check coin balance | 1000 coins added | ⬜ |
| TA-F5-3 | Product ID validation | 1. Check all product IDs != 0<br>2. Verify in Roblox Create | All IDs valid and match Roblox | ⬜ |
| TA-F5-4 | Purchase failure handling | 1. Mock purchase failure<br>2. Attempt purchase | Error handled gracefully, no crash | ⬜ |

**Validation Script:**
```lua
-- Check product IDs configured:
local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)

for name, id in pairs(GameConfig.Monetization.GamePasses) do
    if id == 0 then
        warn("Game Pass not configured:", name)
    else
        print("Game Pass configured:", name, "=", id)
    end
end

-- Expected: All IDs != 0, no warnings
```

---

### 3.2 Speed Run Universe (5 Fixes)

#### **Fix #1: ValidateSpeedrunTime()**
**File:** `SecurityManager.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SRU-F1-1 | Valid speedrun time accepted | 1. Complete Grass world in 20s<br>2. Submit time with checkpoints<br>3. Check leaderboard | Time accepted and recorded | ⬜ |
| SRU-F1-2 | Impossible time rejected | 1. Submit time of 0.1s for Grass<br>2. Check response | Rejected: "Time too fast" | ⬜ |
| SRU-F1-3 | Non-monotonic checkpoints rejected | 1. Submit checkpoints [5, 3, 10]<br>2. Check response | Rejected: "Checkpoint times not increasing" | ⬜ |
| SRU-F1-4 | Completion < last checkpoint rejected | 1. Submit checkpoints [5, 10, 15], time=12<br>2. Check response | Rejected: "Completion time less than last checkpoint" | ⬜ |
| SRU-F1-5 | Sudden improvement flagged | 1. Set PB of 60s<br>2. Submit new time of 20s (67% faster)<br>3. Check logs | Warning logged, time accepted (flagged) | ⬜ |

**Validation Script:**
```lua
-- Server console:
local SecurityManager = require(game.ServerScriptService.Security.SecurityManager)
local player = game.Players:GetPlayers()[1]

-- Test valid time
local valid, reason = SecurityManager.ValidateSpeedrunTime(player, "Grass", nil, 20, {5, 10, 15})
print("Valid time:", valid, reason)

-- Test impossible time
local valid2, reason2 = SecurityManager.ValidateSpeedrunTime(player, "Grass", nil, 0.1, {})
print("Impossible time:", valid2, reason2)

-- Expected: First = true, Second = false with reason
```

---

#### **Fix #2: PlayerRemoving Cleanup**
**File:** `SpeedrunService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SRU-F2-1 | Active run cleaned on leave | 1. Start speedrun<br>2. Leave immediately<br>3. Check ActiveRuns table | Player removed from ActiveRuns | ⬜ |
| SRU-F2-2 | Ghost recording saved | 1. Start run, record 100 frames<br>2. Leave mid-run<br>3. Check DataStore | Partial ghost saved with >50 frames | ⬜ |
| SRU-F2-3 | Memory doesn't leak | 1. Join/leave 100 times<br>2. Monitor memory usage | Memory stable, no growth | ⬜ |

**Validation Script:**
```lua
-- Server console (check after player leaves):
local SpeedrunService = require(game.ServerScriptService.Services.SpeedrunService)

print("Active Runs:", #SpeedrunService.ActiveRuns)
print("Ghost Recordings:", #SpeedrunService.GhostRecordings)

-- Expected: Both should be 0 after all players leave
```

---

#### **Fix #3: Ghost Data Compression**
**File:** `GhostCompression.lua`, `SpeedrunService.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SRU-F3-1 | Ghost compressed to <100KB | 1. Complete 5-min speedrun<br>2. Check saved ghost size<br>3. Verify compression | Size < 100KB, ~80% reduction | ⬜ |
| SRU-F3-2 | Decompression works correctly | 1. Load compressed ghost<br>2. Play back ghost<br>3. Compare to original | Positions within 0.1 studs | ⬜ |
| SRU-F3-3 | Aggressive compression triggers | 1. Record 15-min ghost (>100KB)<br>2. Check compression method | Aggressive mode used, size reduced | ⬜ |
| SRU-F3-4 | Ghost playback smooth | 1. Load compressed ghost<br>2. Watch ghost run<br>3. Check visual quality | Smooth motion, no stuttering | ⬜ |

**Validation Script:**
```lua
-- Test compression:
local GhostCompression = require(game.ServerScriptService.Utilities.GhostCompression)

local frames = {} -- Create test frames
for i = 1, 1000 do
    table.insert(frames, {
        Time = i * 0.1,
        Position = Vector3.new(i, 0, 0),
        Rotation = CFrame.new()
    })
end

local compressed = GhostCompression.CompressGhost(frames)
print("Original size:", #frames * 50, "bytes (estimated)")
print("Compressed size:", #compressed, "bytes")
print("Reduction:", math.floor((1 - #compressed / (#frames * 50)) * 100), "%")

-- Expected: 60-80% reduction
```

---

#### **Fix #4: Ghost Size and Duration Limits**
**File:** `SpeedrunService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SRU-F4-1 | Recording stops at 10 minutes | 1. Start speedrun, don't finish<br>2. Wait 15 minutes<br>3. Check recording | Recording stopped at 10 min, warning logged | ⬜ |
| SRU-F4-2 | Frame limit enforced | 1. Record at max FPS<br>2. Reach 6000 frames<br>3. Check recording | Recording stopped, warning logged | ⬜ |
| SRU-F4-3 | DataStore save succeeds | 1. Record 10-min ghost<br>2. Save to DataStore<br>3. Check size | Save succeeds, size < 4MB | ⬜ |

---

#### **Fix #5: Leaderboard Error Handling**
**File:** `LeaderboardService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SRU-F5-1 | Normal leaderboard fetch | 1. Request leaderboard<br>2. Check response | Fresh data returned, cache hit = true | ⬜ |
| SRU-F5-2 | DataStore failure retry | 1. Mock DataStore failure<br>2. Request leaderboard<br>3. Check logs | 2 retry attempts logged, stale cache returned | ⬜ |
| SRU-F5-3 | Stale cache fallback | 1. Cached data exists<br>2. Fail all requests<br>3. Check response | Stale cache returned, cache hit = false | ⬜ |
| SRU-F5-4 | Client shows data properly | 1. Receive stale cache<br>2. Check client UI | UI shows data with "may be outdated" message | ⬜ |

---

### 3.3 Adventure Story Obby (3 Fixes)

#### **Fix #1: Checkpoint CFrame Validation**
**File:** `WorldService.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ASO-F1-1 | Valid checkpoint set | 1. Stand at Checkpoint_5<br>2. Trigger checkpoint<br>3. Check spawn position | Checkpoint saved with server CFrame | ⬜ |
| ASO-F1-2 | Too far from checkpoint rejected | 1. Stand 100 studs from checkpoint<br>2. Try to set checkpoint remotely<br>3. Check response | Rejected: "too far from checkpoint" | ⬜ |
| ASO-F1-3 | Invalid checkpoint ID rejected | 1. Send checkpointId = "hack"<br>2. Check response | Rejected: "Invalid checkpointId" | ⬜ |
| ASO-F1-4 | Exploiter flagged | 1. Attempt distant checkpoint<br>2. Check SecurityManager | Player flagged for "CheckpointTooFar" | ⬜ |

**Validation Script:**
```lua
-- Client attempts to set distant checkpoint (should fail):
local remoteEvents = game.ReplicatedStorage.RemoteEvents
remoteEvents.SetCheckpoint:FireServer(99, CFrame.new(1000, 1000, 1000))

-- Expected: Server rejects, logs warning, flags player
```

---

#### **Fix #2: Coin Cap Validation**
**File:** `DataService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ASO-F2-1 | Normal coin collection | 1. Collect 100 coins<br>2. Check balance | 100 coins added | ⬜ |
| ASO-F2-2 | Near cap collection | 1. Set coins to 999,999,900<br>2. Collect 200 coins<br>3. Check balance | Capped at 1,000,000,000, warning logged | ⬜ |
| ASO-F2-3 | At cap stays at cap | 1. Set coins to 1,000,000,000<br>2. Collect 100 coins<br>3. Check balance | Stays at 1,000,000,000 | ⬜ |

---

#### **Fix #3: Collectible Animation Memory Leak**
**File:** `CollectibleService.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ASO-F3-1 | Animation thread cleaned | 1. Spawn 10 collectibles<br>2. Collect all 10<br>3. Check thread count | All 10 threads cleaned up | ⬜ |
| ASO-F3-2 | Rapid collection stress test | 1. Spawn 100 collectibles<br>2. Collect in 10 seconds<br>3. Monitor memory | Memory returns to baseline | ⬜ |
| ASO-F3-3 | Long-running server test | 1. Run server for 30 minutes<br>2. Continuously spawn/collect<br>3. Monitor memory | Memory stable, no growth | ⬜ |

---

### 3.4 Pet Collector Sim (3 Fixes)

#### **Fix #1: Negative Coin Exploit**
**File:** `PetService.lua`, `WorldService.lua`
**Testing Time:** 1 hour

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| PCS-F1-1 | Hatch egg with sufficient coins | 1. Player has 500 coins<br>2. Hatch Basic egg (100 cost)<br>3. Check balance | 400 coins remaining | ⬜ |
| PCS-F1-2 | Hatch egg insufficient coins | 1. Player has 50 coins<br>2. Try to hatch Basic egg<br>3. Check response | Rejected: "cannot afford" | ⬜ |
| PCS-F1-3 | Unlock world with coins | 1. Player has 1000 coins<br>2. Unlock world (500 cost)<br>3. Check balance | 500 coins remaining | ⬜ |
| PCS-F1-4 | RemoveCoins used, not AddCoins | 1. Check code uses RemoveCoins<br>2. Verify error handling | RemoveCoins called, handles failure | ⬜ |

---

#### **Fix #2: Trading System Disabled**
**File:** `TradingService.lua`
**Testing Time:** 30 minutes

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| PCS-F2-1 | Initiate trade attempt | 1. Try to send trade request<br>2. Check response | Rejected: "Trading temporarily disabled" | ⬜ |
| PCS-F2-2 | Client notification | 1. Attempt trade<br>2. Check client UI | Notification shows "Check back soon!" | ⬜ |
| PCS-F2-3 | TRADING_ENABLED flag | 1. Check TradingService code<br>2. Verify flag value | TRADING_ENABLED = false | ⬜ |

---

#### **Fix #3: SecureRemotes Integration**
**File:** `PetService.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| PCS-F3-1 | Rate limit enforcement | 1. Rapid-fire 25 hatch requests<br>2. Check responses | First 20 succeed, rest rejected | ⬜ |
| PCS-F3-2 | Invalid egg type rejected | 1. Send eggType = "FakeEgg"<br>2. Check response | Rejected: "Invalid value" | ⬜ |
| PCS-F3-3 | Type validation | 1. Send petId as number instead of string<br>2. Check response | Rejected: "Schema validation failed" | ⬜ |
| PCS-F3-4 | Delete rate limit | 1. Try to delete 15 pets rapidly<br>2. Check responses | First 10 succeed, rest rejected | ⬜ |

---

### 3.5 Dimension Hopper (1 Fix)

#### **Fix #1: Fragment Animation Memory Leak**
**File:** `LevelGenerator.lua`
**Testing Time:** 2 hours

**Test Cases:**

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| DH-F1-1 | Fragment animation cleanup | 1. Spawn 10 fragments<br>2. Collect all<br>3. Check FragmentConnections | Table empty (#FragmentConnections = 0) | ⬜ |
| DH-F1-2 | Stress test 100 fragments | 1. Spawn 100 fragments<br>2. Destroy immediately<br>3. Monitor memory | Memory stable, connections cleaned | ⬜ |
| DH-F1-3 | Long-running server | 1. Run server 2 hours<br>2. Continuously spawn fragments<br>3. Monitor memory | Memory stable, no growth | ⬜ |
| DH-F1-4 | Dimension unload cleanup | 1. Load dimension with 50 fragments<br>2. Unload dimension<br>3. Check FragmentConnections | All connections cleaned | ⬜ |

---

## 4. Integration Testing

### 4.1 Cross-Game Tests

#### **ProfileService Data Persistence**
**Testing Time:** 2 hours

**Test Scenarios:**
- [ ] Player joins, earns coins, leaves, rejoins → coins persisted
- [ ] Player progress saved across sessions
- [ ] Multiple games don't conflict (separate DataStores)
- [ ] Session locking prevents data loss

---

#### **Monetization Flow**
**Testing Time:** 2 hours

**Test Scenarios:**
- [ ] VIP purchase grants benefits in all applicable games
- [ ] Coin packs award correct amounts
- [ ] Receipt processing works correctly
- [ ] Failed purchases don't deduct Robux

---

#### **Security Consistency**
**Testing Time:** 1 hour

**Test Scenarios:**
- [ ] All games use server-authoritative validation
- [ ] No games trust client-provided positions/amounts
- [ ] Rate limiting active across all services
- [ ] Exploiters flagged in SecurityManager

---

### 4.2 Full Gameplay Flows

#### **Tower Ascent - New Player Journey**
**Testing Time:** 30 minutes

**Flow:**
1. Join as new player
2. Complete tutorial (if exists)
3. Climb to floor 10
4. Collect 100 coins
5. Purchase speed boost upgrade
6. Continue to floor 20
7. Leave and rejoin
8. Verify progress saved

**Expected:** Smooth experience, no errors, data persists

---

#### **Speed Run Universe - Speedrun Session**
**Testing Time:** 30 minutes

**Flow:**
1. Join as new player
2. Complete Grass world in 25s
3. Set personal best
4. Ghost saved and compressed
5. Rejoin and load ghost
6. Race against own ghost
7. Beat PB with 20s time
8. Check leaderboard updated

**Expected:** Ghost playback smooth, times validated, leaderboard accurate

---

#### **Adventure Story Obby - World Completion**
**Testing Time:** 30 minutes

**Flow:**
1. Join as new player
2. Complete World 1, Level 1-5
3. Collect 50 collectibles
4. Reach checkpoints
5. Die and respawn at checkpoint
6. Complete world
7. Unlock World 2
8. Leave and rejoin
9. Verify progress saved

**Expected:** Checkpoints work, collectibles collected, progress persists

---

#### **Pet Collector Sim - Pet Collection**
**Testing Time:** 30 minutes

**Flow:**
1. Join as new player
2. Collect 500 coins
3. Hatch 5 Basic eggs
4. Get 5 random pets
5. Equip 3 pets
6. Unlock World 2 (500 coins)
7. Delete 1 pet
8. Leave and rejoin
9. Verify pets and progress saved

**Expected:** Pets persist, coins accurate, world unlocked

---

#### **Dimension Hopper - Dimension Completion**
**Testing Time:** 30 minutes

**Flow:**
1. Join as new player
2. Complete Gravity dimension
3. Collect all 10 fragments
4. Reach section 20
5. Trigger finish area
6. Unlock Tiny dimension
7. Practice mode in Tiny
8. Leave and rejoin
9. Verify progress saved

**Expected:** Fragments collected, dimensions unlocked, practice works

---

## 5. Performance & Load Testing

### 5.1 Memory Leak Detection

**Tools:** Roblox DevConsole Memory Profiler

**Test Procedure:**
1. Start server with 0 players
2. Record baseline memory usage
3. Run for 2 hours with simulated activity
4. Record memory every 10 minutes
5. Plot memory over time
6. Check for upward trend (leak indicator)

**Success Criteria:**
- Memory fluctuates but doesn't trend upward
- Memory returns to baseline after activity stops
- No warnings about memory usage

**Games to Test:**
- ✅ Speed Run Universe (ghost recording leak)
- ✅ Adventure Story Obby (collectible animation leak)
- ✅ Dimension Hopper (fragment animation leak)

---

### 5.2 Concurrent Player Load Testing

**Tools:** Bot scripts simulating players

**Test Scenarios:**

| Game | CCU | Duration | Actions | Success Criteria |
|------|-----|----------|---------|------------------|
| Tower Ascent | 20 | 1 hour | Climb, collect coins, purchase | No lag, all actions work |
| Speed Run Universe | 20 | 1 hour | Complete runs, save ghosts | All ghosts saved, leaderboard updates |
| Adventure Story Obby | 20 | 1 hour | Complete levels, collect items | Checkpoints work, items collected |
| Pet Collector Sim | 20 | 1 hour | Hatch eggs, equip pets | All pets saved, no duplication |
| Dimension Hopper | 20 | 1 hour | Complete dimensions, fragments | Fragments collected, memory stable |

**Metrics to Track:**
- Server FPS (should stay >40 FPS)
- Memory usage (should stay <2GB)
- DataStore success rate (should stay >95%)
- Player lag reports (should be minimal)

---

### 5.3 DataStore Quota Testing

**Test Procedure:**
1. Monitor DataStore requests per minute
2. Check against Roblox limits (60+numPlayers*10 requests/min)
3. Verify request batching working
4. Test save queue during high load

**Games with High DataStore Usage:**
- Speed Run Universe (ghost saves)
- Pet Collector Sim (pet inventory saves)

**Success Criteria:**
- No "DataStore request quota exceeded" errors
- All saves eventually succeed
- Queue doesn't grow unbounded

---

### 5.4 Performance Benchmarks

**Baseline Metrics to Establish:**

| Metric | Tower Ascent | Speed Run | Adventure | Pet Collector | Dimension |
|--------|--------------|-----------|-----------|---------------|-----------|
| Server FPS (empty) | >60 | >60 | >60 | >60 | >60 |
| Server FPS (20 players) | >50 | >50 | >50 | >50 | >50 |
| Memory (empty) | <500MB | <500MB | <500MB | <500MB | <500MB |
| Memory (20 players) | <1.5GB | <1.5GB | <1.5GB | <1.5GB | <1.5GB |
| DataStore calls/min | <100 | <150 | <100 | <120 | <100 |

---

## 6. Security Testing

### 6.1 Exploit Attempts

**Test Scenarios:**

#### **Position Exploits**
- [ ] Attempt to teleport to finish (Tower Ascent)
- [ ] Set distant checkpoint (Adventure Story Obby)
- [ ] Skip sections (Dimension Hopper)

**Expected:** All rejected with server-authoritative validation

---

#### **Economy Exploits**
- [ ] Attempt negative coin addition
- [ ] Exceed max coin cap
- [ ] Duplicate coins via timing
- [ ] Purchase without payment

**Expected:** All rejected, exploiter flagged

---

#### **Rate Limit Bypasses**
- [ ] Spam hatch egg 100x in 10s
- [ ] Spam equip pet rapidly
- [ ] Flood checkpoint requests
- [ ] DDoS attempt with remotes

**Expected:** Rate limits enforce, excess requests rejected

---

#### **Input Validation**
- [ ] Send invalid egg types ("Exploit123")
- [ ] Send NaN/Infinity values
- [ ] Send wrong data types (number instead of string)
- [ ] Send malformed tables

**Expected:** All rejected with schema validation

---

### 6.2 Anti-Cheat Validation

**Speed Run Universe:**
- [ ] Submit impossible time (0.1s)
- [ ] Submit backwards checkpoints
- [ ] Submit completion < last checkpoint
- [ ] Sudden 90% improvement

**Expected:** All flagged or rejected

---

### 6.3 Data Security

**Test Scenarios:**
- [ ] Player A cannot access Player B's data
- [ ] VIP status cannot be spoofed
- [ ] Inventory cannot be modified by client
- [ ] Leaderboards show accurate data

**Expected:** All data server-authoritative, no client manipulation

---

## 7. Pre-Launch Validation

### 7.1 Production Checklist

**Configuration:**
- [ ] Debug mode disabled in all games
- [ ] All product IDs configured (not 0)
- [ ] DataStore names set to production
- [ ] Webhook URLs configured
- [ ] Error logging enabled (Sentry/Analytics)

**Monetization:**
- [ ] All Game Passes created and IDs updated
- [ ] All Developer Products created and IDs updated
- [ ] Purchase handlers tested
- [ ] Receipt processing verified

**Security:**
- [ ] All critical fixes deployed
- [ ] SecurityManager working
- [ ] Rate limits configured
- [ ] Anti-cheat active

**Performance:**
- [ ] Memory leaks fixed
- [ ] DataStore optimized
- [ ] Server FPS acceptable
- [ ] Load tested with target CCU

**Data:**
- [ ] ProfileService configured
- [ ] Session locking enabled
- [ ] Auto-save working
- [ ] Backup system ready

---

### 7.2 Test Server Sign-Off

**Before promoting to production:**

| Game | All Fixes Tested | Integration OK | Performance OK | Security OK | Sign-Off |
|------|------------------|----------------|----------------|-------------|----------|
| Tower Ascent | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Speed Run Universe | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Adventure Story Obby | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Pet Collector Sim | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Dimension Hopper | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

**Sign-off requires:**
- All critical tests passed
- No P0/P1 bugs remaining
- Performance within acceptable range
- Security validated
- Team approval

---

## 8. Success Criteria & Metrics

### 8.1 Test Pass Criteria

**Per-Game:**
- ✅ All critical fix tests passed (100%)
- ✅ Integration tests passed (90%+)
- ✅ No P0 bugs remaining
- ✅ No more than 3 P1 bugs
- ✅ Performance benchmarks met

**Overall Portfolio:**
- ✅ All 5 games pass individual criteria
- ✅ No cross-game conflicts
- ✅ Monetization working across portfolio
- ✅ DataStore quotas not exceeded
- ✅ Security validated on all games

---

### 8.2 Key Metrics to Track

**During Testing:**
- Test cases executed / total
- Tests passed / failed / blocked
- Bugs found by severity (P0/P1/P2)
- Bugs fixed / remaining
- Code coverage (if automated)

**Post-Launch:**
- Crash rate (should be <0.1%)
- Average session time
- Retention (D1, D7, D30)
- Monetization (ARPPU, conversion)
- CCU growth
- DataStore errors (should be <1%)

---

## 9. Test Automation

### 9.1 Automated Test Scripts

**Unit Test Framework:**
```lua
-- tests/TestRunner.lua
local TestRunner = {}

function TestRunner.RunAllTests()
    local results = {
        Passed = 0,
        Failed = 0,
        Tests = {}
    }

    -- Tower Ascent Tests
    results = TestRunner.RunGameTests("TowerAscent", results)

    -- Speed Run Universe Tests
    results = TestRunner.RunGameTests("SpeedRunUniverse", results)

    -- ... other games ...

    print("===== TEST RESULTS =====")
    print("Passed:", results.Passed)
    print("Failed:", results.Failed)
    print("Success Rate:", math.floor(results.Passed / (results.Passed + results.Failed) * 100), "%")

    return results
end

function TestRunner.RunGameTests(gameName, results)
    local tests = require(script.Parent.Games[gameName])

    for testName, testFunc in pairs(tests) do
        local success, error = pcall(testFunc)

        if success then
            results.Passed = results.Passed + 1
            print("✅", gameName, testName, "PASSED")
        else
            results.Failed = results.Failed + 1
            print("❌", gameName, testName, "FAILED:", error)
        end

        table.insert(results.Tests, {
            Game = gameName,
            Test = testName,
            Passed = success,
            Error = error
        })
    end

    return results
end

return TestRunner
```

---

### 9.2 Continuous Integration

**Recommended Setup:**
1. Git pre-commit hook runs unit tests
2. Test server auto-deploys on main branch push
3. Automated smoke tests run every deploy
4. Discord/Slack notification on test failures

**GitHub Actions Example:**
```yaml
name: Roblox Game Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Install Rojo
      run: |
        wget https://github.com/rojo-rbx/rojo/releases/download/v7.3.0/rojo-7.3.0-linux.zip
        unzip rojo-7.3.0-linux.zip

    - name: Build Project
      run: ./rojo build -o game.rbxlx

    - name: Run Tests (if test framework exists)
      run: echo "Tests passed"

    - name: Notify Discord
      if: failure()
      run: |
        curl -X POST ${{ secrets.DISCORD_WEBHOOK }} \
          -H "Content-Type: application/json" \
          -d '{"content":"❌ Tests failed on ${{ github.ref }}"}'
```

---

## 10. Bug Tracking & Reporting

### 10.1 Bug Report Template

**Title:** [GAME] - [SEVERITY] - Brief description

**Severity:**
- P0: Critical (blocks launch, data loss, exploits)
- P1: High (major feature broken, bad UX)
- P2: Medium (minor bug, edge case)
- P3: Low (cosmetic, nice-to-have)

**Template:**
```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Impact
Who is affected and how severe

## Screenshots/Logs
Attach relevant media

## Environment
- Game: Tower Ascent
- Platform: Windows
- Roblox Version: 2.621.123
- Test Server: Yes/No

## Related Fix
Related to Fix #2: VIP Race Condition
```

---

### 10.2 Bug Tracking Workflow

**States:**
1. **New** - Bug reported, not triaged
2. **Triaged** - Severity assigned, assigned to developer
3. **In Progress** - Developer working on fix
4. **Fixed** - Fix implemented, needs testing
5. **Verified** - QA confirmed fix works
6. **Closed** - Bug resolved

**Priority Guidelines:**
- P0: Fix immediately, blocks launch
- P1: Fix before launch
- P2: Fix in Week 1 patch
- P3: Fix in future update

---

## 11. Testing Timeline

### Week 1: Unit Testing (16-20 hours)
**Monday-Tuesday:** Tower Ascent + Speed Run Universe
**Wednesday-Thursday:** Adventure Story Obby + Pet Collector Sim
**Friday:** Dimension Hopper + Integration Tests

### Week 2: Load & Security Testing (16-20 hours)
**Monday-Tuesday:** Performance testing, memory leak detection
**Wednesday-Thursday:** Load testing, DataStore stress
**Friday:** Security testing, exploit attempts

### Week 3: UAT & Bug Fixes (Ongoing)
**Monday:** Deploy to test servers
**Tuesday-Friday:** Beta tester feedback, bug fixes
**Weekend:** Final validation

### Week 4: Launch Prep (8 hours)
**Monday-Wednesday:** Production deployment preparation
**Thursday:** Soft launch (limited audience)
**Friday:** Full launch (all games live)

---

## 12. Contact & Support

**Testing Lead:** TBD
**QA Team:** TBD
**Developers:** Claude Code (fixes), [Human developers]
**Discord:** #qa-testing channel
**Bug Reports:** Notion/Jira board

---

## Appendix A: Quick Reference

### Critical Fixes Summary

| Game | Fix | File | Test Priority |
|------|-----|------|---------------|
| Tower Ascent | Debug Mode | Main.server.lua | HIGH |
| Tower Ascent | IsAuthenticated | SecurityManager.lua | HIGH |
| Tower Ascent | VIP Race | VIPService.lua | CRITICAL |
| Tower Ascent | Coin Underflow | DataService.lua | HIGH |
| Tower Ascent | Product IDs | GameConfig.lua | CRITICAL |
| Speed Run | ValidateTime | SecurityManager.lua | CRITICAL |
| Speed Run | Cleanup | SpeedrunService.lua | HIGH |
| Speed Run | Compression | GhostCompression.lua | HIGH |
| Speed Run | Size Limits | SpeedrunService.lua | MEDIUM |
| Speed Run | Error Handling | LeaderboardService.lua | HIGH |
| Adventure | Checkpoint | WorldService.lua | CRITICAL |
| Adventure | Coin Cap | DataService.lua | HIGH |
| Adventure | Memory Leak | CollectibleService.lua | HIGH |
| Pet Collector | Negative Coins | PetService.lua | CRITICAL |
| Pet Collector | Trading | TradingService.lua | HIGH |
| Pet Collector | SecureRemotes | PetService.lua | HIGH |
| Dimension | Memory Leak | LevelGenerator.lua | HIGH |

---

## Appendix B: Test Data Sets

### Sample Test Accounts

| Account | UserId | Coins | VIP | Progress | Purpose |
|---------|--------|-------|-----|----------|---------|
| TestUser1 | 1001 | 0 | No | New player | Fresh start testing |
| TestUser2 | 1002 | 1000 | No | Mid-game | Normal progression |
| TestUser3 | 1003 | 999999999 | No | Max coins | Cap testing |
| TestUser4 | 1004 | 500 | Yes | Mid-game | VIP testing |
| TestUser5 | 1005 | 10000 | Yes | Late-game | VIP + progression |

---

**Document Version:** 1.0
**Last Updated:** 2026-02-22
**Status:** Ready for QA Team Review
**Next Review:** After Week 1 testing completion
