# Tower Ascent - Monetization Testing Plan

**Date:** January 2026
**Status:** Ready for execution
**Scope:** VIP Pass, Battle Pass, Game Passes, Developer Products

---

## 🎯 Testing Overview

### Systems to Test

1. **VIPService** (Week 12)
2. **BattlePassService** (Week 13)
3. **GamePassService** (Week 14)
4. **DevProductService** (Week 14)

### Testing Phases

1. **Configuration** - Set up all product IDs
2. **Unit Testing** - Test individual functions
3. **Integration Testing** - Test service interactions
4. **Manual Testing** - Real purchase flows
5. **Regression Testing** - Ensure no breaking changes

---

## 📋 Phase 1: Configuration Setup

### Required Before Testing

**Create Products on Roblox:**

**VIP Pass (1 Game Pass):**
- Name: "Tower Ascent VIP"
- Price: 500 Robux
- Description: "2x Coins Forever + VIP Tag + Exclusive Benefits"

**Battle Pass (1 Game Pass):**
- Name: "Premium Battle Pass - Season 1"
- Price: 99 Robux
- Description: "Unlock 50 premium rewards!"

**Game Passes (5 passes):**
1. Particle Effects Pack (149 Robux)
2. Emote Pack (99 Robux)
3. Double XP (199 Robux)
4. Checkpoint Skip (79 Robux)
5. Speed Demon (149 Robux)

**Developer Products (8 products):**
1. 500 Coins (49 Robux)
2. 1,500 Coins (99 Robux)
3. 4,000 Coins (199 Robux)
4. 10,000 Coins (399 Robux)
5. 30 Min XP Boost (29 Robux)
6. 1 Hour XP Boost (49 Robux)
7. 3 Hour XP Boost (99 Robux)
8. Respawn Skip (19 Robux)

---

**Update Configuration Files:**

**VIPService.lua (Line 34):**
```lua
VIPGamePassId = YOUR_VIP_ID_HERE
```

**BattlePassService.lua (Line 34):**
```lua
PremiumPassId = YOUR_BATTLE_PASS_ID_HERE
```

**GamePassService.lua (Lines 29-78):**
```lua
ParticleEffects.Id = YOUR_ID_HERE
EmotePack.Id = YOUR_ID_HERE
DoubleXP.Id = YOUR_ID_HERE
CheckpointSkip.Id = YOUR_ID_HERE
SpeedDemon.Id = YOUR_ID_HERE
```

**DevProductService.lua (Lines 28-104):**
```lua
CoinPack_Small.Id = YOUR_ID_HERE
CoinPack_Medium.Id = YOUR_ID_HERE
CoinPack_Large.Id = YOUR_ID_HERE
CoinPack_Mega.Id = YOUR_ID_HERE
XPBoost_30min.Id = YOUR_ID_HERE
XPBoost_1hour.Id = YOUR_ID_HERE
XPBoost_3hour.Id = YOUR_ID_HERE
RespawnSkip.Id = YOUR_ID_HERE
```

---

## 🧪 Phase 2: Unit Testing

### VIPService Tests

**Test 1: VIP Status Detection**
```lua
-- Admin command test
local player = game.Players:FindFirstChild("TestPlayer")
_G.TowerAscent.VIPService.AdminGrantVIP(player)

-- Expected: player:GetAttribute("IsVIP") == true
-- Expected: VIP tag appears above player
```

**Test 2: 2x Coin Multiplier**
```lua
-- Grant VIP, collect coin
_G.TowerAscent.VIPService.AdminGrantVIP(player)
_G.TowerAscent.CoinService.AddCoins(player, 10, "Test")

-- Expected: Player receives 20 coins (10 × 2)
-- Expected: Console shows "VIP bonus" message
```

**Test 3: VIP Tag Creation**
```lua
-- Grant VIP
_G.TowerAscent.VIPService.AdminGrantVIP(player)

-- Expected: BillboardGui created in player character
-- Expected: Text shows "⭐ VIP"
-- Expected: Color is gold (Color3.fromRGB(255, 215, 0))
```

**Test 4: VIP Removal**
```lua
-- Grant then revoke
_G.TowerAscent.VIPService.AdminGrantVIP(player)
_G.TowerAscent.VIPService.AdminRevokeVIP(player)

-- Expected: IsVIP == false
-- Expected: VIP tag destroyed
-- Expected: Coin multiplier back to 1x
```

---

### BattlePassService Tests

**Test 5: XP Earning (Section Reached)**
```lua
local player = game.Players:FindFirstChild("TestPlayer")
_G.TowerAscent.BattlePassService.OnSectionReached(player, 10)

-- Expected: +5 XP
-- Expected: Progress updated
```

**Test 6: XP Earning (Tower Completed)**
```lua
_G.TowerAscent.BattlePassService.OnTowerCompleted(player)

-- Expected: +100 XP
-- Expected: Tier up if XP >= 100
```

**Test 7: Tier-Up Logic**
```lua
-- Add 100 XP (should tier up)
_G.TowerAscent.BattlePassService.AddXP(player, 100, "Test")

-- Expected: Tier == 2
-- Expected: XP reset to 0 (or overflow)
-- Expected: Tier 2 rewards unlocked
```

**Test 8: Reward Claiming (Free Track)**
```lua
-- Reach tier 1, claim free reward
_G.TowerAscent.BattlePassService.ClaimReward(player, 1, false)

-- Expected: 50 coins added
-- Expected: ClaimedFree[1] = true
-- Expected: Cannot claim again
```

**Test 9: Reward Claiming (Premium Track)**
```lua
-- Grant premium, reach tier 1, claim premium reward
_G.TowerAscent.BattlePassService.ClaimReward(player, 1, true)

-- Expected: Premium reward granted
-- Expected: ClaimedPremium[1] = true
-- Expected: Free players cannot claim
```

**Test 10: Challenge Completion**
```lua
-- Complete "Reach section 10" challenge
-- (Tracked automatically via OnSectionReached)

-- Expected: Challenge marked complete
-- Expected: XP reward granted (50 XP)
```

---

### GamePassService Tests

**Test 11: Game Pass Ownership Detection**
```lua
-- Test all 5 passes
local passes = {
    "ParticleEffects",
    "EmotePack",
    "DoubleXP",
    "CheckpointSkip",
    "SpeedDemon"
}

for _, passName in ipairs(passes) do
    local hasPass = _G.TowerAscent.GamePassService.HasGamePass(player, passName)
    print(passName .. ": " .. tostring(hasPass))
end

-- Expected: Correct ownership status for each pass
```

**Test 12: Double XP Integration**
```lua
-- Purchase Double XP pass, earn XP
-- (Manual purchase or admin grant)

_G.TowerAscent.BattlePassService.OnSectionReached(player, 10)

-- Expected: 10 XP earned (5 base × 2)
-- Expected: HasDoubleXP attribute == true
```

**Test 13: Speed Boost Application**
```lua
-- Purchase Speed Demon pass
-- (Manual purchase or admin grant)

local character = player.Character
local walkSpeed = character.Humanoid.WalkSpeed

-- Expected: WalkSpeed == 16.8 (16 × 1.05)
-- Expected: HasSpeedBoost attribute == true
```

**Test 14: Particle Effects Unlock**
```lua
-- Purchase Particle Effects pack

local trails = player:GetAttribute("UnlockedTrails")

-- Expected: 5 premium trails unlocked
-- Expected: Trails stored in player data
```

---

### DevProductService Tests

**Test 15: Coin Pack Purchase (Small)**
```lua
-- Purchase 500 Coin Pack (49 Robux)
-- (Manual purchase via Roblox)

-- Expected: +500 coins added immediately
-- Expected: Receipt processed
-- Expected: PurchaseGranted returned
```

**Test 16: Coin Pack Purchase (Mega)**
```lua
-- Purchase 10,000 Coin Pack (399 Robux)

-- Expected: +10,000 coins added
-- Expected: Correct value (+150% bonus)
```

**Test 17: XP Boost Activation**
```lua
-- Purchase 30 Min XP Boost

-- Expected: Boost active (2x multiplier)
-- Expected: Timer starts (30 minutes)
-- Expected: Boost expires after 30 minutes
```

**Test 18: XP Boost Expiration**
```lua
-- Purchase boost, wait 30 minutes

task.wait(1800) -- 30 minutes

-- Expected: Boost expired
-- Expected: Multiplier back to 1x
-- Expected: Player notified of expiration
```

**Test 19: Respawn Skip Usage**
```lua
-- Purchase Respawn Skip, die in tower

-- Expected: RespawnSkips attribute == 1
-- Expected: Option to skip death penalty
-- Expected: After use, RespawnSkips == 0
```

**Test 20: Receipt Idempotency**
```lua
-- Simulate duplicate receipt

local receiptInfo = {
    PlayerId = player.UserId,
    ProductId = CoinPack_Small.Id,
    PurchaseId = "test_123"
}

_G.TowerAscent.DevProductService.ProcessReceipt(receiptInfo)
_G.TowerAscent.DevProductService.ProcessReceipt(receiptInfo) -- Duplicate

-- Expected: Only 1 grant (500 coins total, not 1000)
-- Expected: Second call returns PurchaseGranted immediately
```

---

## 🔗 Phase 3: Integration Testing

### Cross-Service Integration

**Test 21: VIP + Battle Pass (Coin Multiplier)**
```lua
-- Grant VIP, complete tower

_G.TowerAscent.VIPService.AdminGrantVIP(player)
_G.TowerAscent.CheckpointService.OnFinishLineTouched(finishLine, player.Character.HumanoidRootPart)

-- Expected: Completion bonus × 2 (VIP)
-- Expected: Battle Pass XP earned
-- Expected: All integrations work
```

**Test 22: Double XP Game Pass + XP Boost**
```lua
-- Purchase Double XP pass + 30 Min XP Boost

_G.TowerAscent.BattlePassService.OnSectionReached(player, 10)

-- Expected: 20 XP earned (5 base × 2 × 2)
-- Expected: Boosts stack correctly
```

**Test 23: Checkpoint Skip + Respawn Skip**
```lua
-- Purchase both, die in tower

-- Expected: Two skip options available
-- Expected: Checkpoint Skip → respawn at checkpoint
-- Expected: Respawn Skip → respawn at current position
```

**Test 24: All Monetization Active**
```lua
-- Player has:
-- - VIP Pass (2x coins)
-- - Premium Battle Pass (premium rewards)
-- - All 5 Game Passes
-- - Active XP Boost

-- Test gameplay:
_G.TowerAscent.CheckpointService.OnCheckpointTouched(checkpoint, player.Character.HumanoidRootPart)

-- Expected: Coins × 2 (VIP)
-- Expected: XP × 4 (Double XP + Boost)
-- Expected: All systems work together
-- Expected: No conflicts or errors
```

---

## 🖐️ Phase 4: Manual Testing

### Purchase Flow Testing

**Manual Test 1: VIP Purchase (End-to-End)**
1. Join game as test account (no VIP)
2. Open shop UI (or use admin command to prompt)
3. Click "Buy VIP Pass"
4. Complete purchase (500 Robux)
5. Verify VIP tag appears above player
6. Collect coins, verify 2x multiplier
7. Rejoin game, verify VIP status persists
8. **Expected: Full purchase flow works**

**Manual Test 2: Battle Pass Purchase**
1. Join game, check Battle Pass tier (should be 1)
2. Click "Buy Premium Battle Pass"
3. Complete purchase (99 Robux)
4. Verify premium status = true
5. Reach tier 1, claim premium reward
6. Verify premium reward granted
7. **Expected: Premium access immediate**

**Manual Test 3: Game Pass Purchase (Particle Effects)**
1. Join game, check unlocked trails
2. Purchase Particle Effects Pack (149 Robux)
3. Verify 5 new trails unlocked
4. Equip trail, verify visual effect
5. Rejoin game, verify trails still unlocked
6. **Expected: Trails persist**

**Manual Test 4: Developer Product (Coin Pack)**
1. Check current coin balance
2. Purchase 500 Coin Pack (49 Robux)
3. Verify +500 coins immediately
4. Check transaction history
5. **Expected: Instant coin delivery**

**Manual Test 5: XP Boost Purchase**
1. Purchase 30 Min XP Boost (29 Robux)
2. Verify boost active (UI indicator)
3. Earn XP from gameplay
4. Verify 2x multiplier active
5. Wait 30 minutes
6. Verify boost expired
7. **Expected: Temporary boost works**

---

### Edge Case Testing

**Edge Test 1: Player Leaves During Purchase**
1. Initiate purchase prompt
2. Leave game before completing
3. Rejoin
4. Complete purchase (if prompted by Roblox)
5. **Expected: Receipt processed on rejoin, product granted**

**Edge Test 2: Multiple Purchases Rapidly**
1. Purchase 500 Coin Pack
2. Immediately purchase 1,500 Coin Pack
3. Immediately purchase 4,000 Coin Pack
4. **Expected: All 3 purchases processed, total +5,900 coins**

**Edge Test 3: Purchase While Dead**
1. Die in tower
2. Purchase Respawn Skip while respawning
3. **Expected: Purchase works, skip available after respawn**

**Edge Test 4: Server Crash During Purchase**
1. Initiate purchase
2. Simulate server crash (shutdown server)
3. Restart server
4. Player rejoins
5. **Expected: Receipt processed on rejoin (Roblox retries)**

---

## 📊 Phase 5: Regression Testing

### Ensure No Breaking Changes

**Regression Test 1: Core Gameplay Unaffected**
- Complete tower without any purchases
- Verify checkpoint system works
- Verify coin collection works
- Verify leaderboards work
- **Expected: Free experience unchanged**

**Regression Test 2: Existing Services Still Work**
- Test Generator (tower generation)
- Test RoundService (timed rounds)
- Test ThemeService (environmental themes)
- Test HazardService (hazards active)
- Test WeatherService (weather effects)
- **Expected: All systems functional**

**Regression Test 3: Data Persistence**
- Complete tower, earn coins/XP
- Leave game
- Rejoin
- **Expected: Progress saved, restored on rejoin**

**Regression Test 4: Performance**
- Join server with 10+ players
- Some with VIP, some with Battle Pass
- Monitor server performance (CPU, memory)
- **Expected: No performance degradation**

---

## ✅ Testing Checklist

### VIP System (Week 12)

- [ ] VIP status detection (MarketplaceService)
- [ ] 2x coin multiplier application
- [ ] VIP tag creation and display
- [ ] Admin commands (grant/revoke)
- [ ] Purchase prompt
- [ ] VIP persistence (rejoin test)

### Battle Pass System (Week 13)

- [ ] XP earning (sections, towers, rounds)
- [ ] Tier-up logic (progressive XP)
- [ ] Free reward claiming
- [ ] Premium reward claiming
- [ ] Challenge generation (daily/weekly)
- [ ] Challenge completion tracking
- [ ] Challenge reset (24 hours / 7 days)
- [ ] Season management
- [ ] Premium pass purchase

### Game Pass System (Week 14)

- [ ] Particle Effects Pack (5 trails)
- [ ] Emote Pack (5 emotes)
- [ ] Double XP (2x Battle Pass XP)
- [ ] Checkpoint Skip (skip to checkpoint)
- [ ] Speed Demon (+5% speed)
- [ ] Ownership detection (all 5 passes)
- [ ] Benefit application (automatic on join)

### Developer Product System (Week 14)

- [ ] Coin Pack Small (500 coins)
- [ ] Coin Pack Medium (1,500 coins)
- [ ] Coin Pack Large (4,000 coins)
- [ ] Coin Pack Mega (10,000 coins)
- [ ] XP Boost 30 Min (2x for 30 min)
- [ ] XP Boost 1 Hour (2x for 1 hour)
- [ ] XP Boost 3 Hour (2x for 3 hours)
- [ ] Respawn Skip (skip 1 death)
- [ ] Receipt processing (ProcessReceipt)
- [ ] Idempotency (no duplicate granting)

### Integration Testing

- [ ] VIP + Battle Pass (coins × 2, XP earned)
- [ ] Double XP + XP Boost (stacking multipliers)
- [ ] All systems active (no conflicts)
- [ ] Cross-service communication

### Regression Testing

- [ ] Core gameplay unaffected
- [ ] Existing services still work
- [ ] Data persistence working
- [ ] Performance acceptable

---

## 🐛 Bug Reporting Template

**If bugs found during testing, report using this template:**

### Bug Report

**Title:** [Brief description]

**Severity:** Critical / High / Medium / Low

**System:** VIP / Battle Pass / Game Pass / Dev Product

**Steps to Reproduce:**
1.
2.
3.

**Expected Behavior:**

**Actual Behavior:**

**Console Errors:**
```
[Paste console output]
```

**Additional Context:**
- Player ID:
- Product ID:
- Timestamp:

---

## 📈 Success Criteria

### All Tests Must Pass

**VIP System:**
- ✅ 2x coins work
- ✅ VIP tag displays
- ✅ Purchase flow works
- ✅ Persistence works

**Battle Pass:**
- ✅ XP earning from all sources
- ✅ Tier-up correct
- ✅ Rewards claimable
- ✅ Challenges work

**Game Passes:**
- ✅ All 5 passes grant benefits
- ✅ Ownership detected correctly
- ✅ Benefits persist

**Developer Products:**
- ✅ All 8 products grant correctly
- ✅ Receipts processed
- ✅ No duplicate granting

**Integration:**
- ✅ All systems work together
- ✅ No conflicts
- ✅ Performance good

---

## 🚀 Post-Testing

### After All Tests Pass

1. **Update PROJECT_STATUS.md** - Mark monetization testing complete
2. **Create test results document** - MONETIZATION_TEST_RESULTS.md
3. **Fix any bugs found** - Address all critical/high bugs
4. **Regression test fixes** - Ensure fixes don't break other things
5. **Mark monetization as "Production Ready"**
6. **Move to Week 20: Launch Preparation**

---

**Testing Plan Created:** January 2026
**Estimated Testing Time:** 8-12 hours (comprehensive)
**Next:** Execute testing plan, document results

---

🧪 **Tower Ascent - Monetization Testing Plan Ready!**
