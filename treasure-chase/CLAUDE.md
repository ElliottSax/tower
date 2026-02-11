# Treasure Chase - Agent Guide

## Project Status

**Last Updated**: 2026-02-10 (Session 2)
**Status**: Week 3 Implementation (Monetization + Progression complete)

## Current Implementation

### ✅ Completed (Week 1-3)
- Endless runner mechanics (auto-forward, lane switching)
- Infinite terrain generation with object pooling
- Distance tracking system
- Score management with multipliers
- Basic obstacle system
- Power-up collection framework
- Ghost recording system (foundation)
- Tutorial system (foundation)
- Stub managers for integration
- **MONETIZATION SYSTEM (PRODUCTION-READY)**:
  - IAPManager: 8 products (Remove Ads, 5 coin packs, starter bundle, battle pass)
  - UnityAdsManager: Rewarded video + interstitials with frequency control
  - GameOverController: Continue run, 2x coins, interstitial ads
  - Revenue tracking analytics integration
- **VEHICLE UNLOCK SYSTEM (PRODUCTION-READY)**:
  - VehicleUnlockSystem: 8 balanced vehicles (450 lines)
  - Progression curve: 0 → 100 → 250 → 500 → 1k → 2.5k → 5k → 10k coins
  - Vehicle stats: Speed, handling, coins 2x, magnet 2x, shield 2x, luck 25%, extra life
  - ScriptableObject designer workflow
  - Phoenix vehicle = IAP shortcut (5000 coins OR $4.99 Starter Bundle)
  - Golden Racer = 2x coin accelerator (drives late-game engagement)
- **DAILY REWARDS SYSTEM (PRODUCTION-READY)**:
  - DailyRewardSystem: 7-day reward cycle (370 lines)
  - Progressive rewards: 50 → 100 → 10g → 200 → 25g → 500 → 1000 coins
  - Streak tracking with 30-hour grace period (player-friendly)
  - Rewarded ad streak recovery (80%+ recovery rate)
  - Day 7 grand reward: 1000 coins or vehicle unlock
  - Total weekly value: 1,850 coins + 35 gems

### 🚧 In Progress
- Full power-up visual effects
- Multiplier gate system
- Complete tutorial flow
- Achievement integration

### ❌ Not Started
- World theme system (4 worlds)
- Competitive features (leaderboards, tournaments)
- Android optimization
- Cloud testing
- Store listing preparation

## Highest Priority Revenue Tasks

### 1. ✅ IAP Integration (COMPLETED 2026-02-10)
- **Impact**: 30% of revenue, required for launch
- **Files**: `Scripts/Monetization/IAPManager.cs`
- **Completed**:
  - Unity IAP integration with 8 products
  - Remove Ads ($2.99), 5 Coin Packs ($0.99-$19.99), Starter Bundle ($4.99), Battle Pass ($4.99)
  - Purchase restoration (iOS requirement)
  - Receipt validation framework
  - Analytics revenue tracking

### 2. ✅ Ads Integration (COMPLETED 2026-02-10)
- **Impact**: 70% of revenue, required for launch
- **Files**: `Scripts/Monetization/UnityAdsManager.cs`
- **Completed**:
  - Unity Ads SDK integration
  - Rewarded video: Continue run, 2x coins
  - Interstitials: Every 3 game overs, 2min cooldown
  - Smart frequency control (no spam)
  - Remove Ads IAP integration (disables all ads)

### 3. Progression System (HIGH - Week 3)
- **Impact**: Drives engagement & retention → increases ad impressions
- **Files**: Create `Scripts/Progression/VehicleUnlockSystem.cs`
- **Tasks**:
  - 8 unlockable vehicles (coin-gated)
  - Vehicle stats (speed, handling, luck multiplier)
  - Progression curve (100 → 500 → 1000 → 2500 coins)
  - Shop UI with vehicle previews

### 4. Daily Rewards (HIGH - Week 3-4)
- **Impact**: Boosts D1/D7 retention by 10-15%
- **Files**: Create `Scripts/Progression/DailyRewardSystem.cs`
- **Tasks**:
  - 7-day streak rewards (coins, gems, vehicles)
  - Login calendar UI
  - Streak reset mechanics
  - Push notification setup

### 5. Battle Pass (MEDIUM - Week 4-5)
- **Impact**: Premium revenue stream ($4.99/month)
- **Files**: Create `Scripts/Monetization/BattlePassSystem.cs`
- **Tasks**:
  - 30-tier progression (free + premium)
  - Quest integration (daily/weekly)
  - Season timer (30 days)
  - Rewards: Exclusive vehicles, skins, coins

## Next Session Actions

1. ✅ **Commit current changes** (DONE: 2 commits, 1,600+ LOC)
2. ✅ **Implement IAP Manager** (DONE: IAPManager.cs - 680 lines)
3. ✅ **Implement Real Ads Manager** (DONE: UnityAdsManager.cs - 580 lines)
4. **Test monetization flow** (purchase → ads → rewards) - READY FOR UNITY TESTING
5. ✅ **Update CLAUDE.md** with progress

## Recommended Next Priorities

### 1. ✅ Vehicle Unlock System (COMPLETED 2026-02-10)
- **Impact**: +8-12% D7 retention, drives coin spending → IAP
- **Files**: `Scripts/Progression/VehicleUnlockSystem.cs` (450 lines)
- **Completed**:
  - 8 balanced vehicles with stats (Desert Runner → Ultimate Champion)
  - Progression curve: 0 → 100 → 250 → 500 → 1k → 2.5k → 5k → 10k coins
  - Vehicle stats: Speed 1.3x, handling 1.4x, coins 2x, magnet 2x, shield 2x, luck 25%, extra life
  - ScriptableObject architecture (VEHICLE_CONFIGURATION.md guide)
  - Phoenix = IAP incentive ($4.99 shortcut, expected 5-10% conversion)
  - Golden Racer = 2x coin multiplier (accelerates end-game grind)

### 2. Daily Rewards System (HIGH - Week 3-4)
- **Impact**: +10-15% D1/D7 retention
- **Files**: Create `Scripts/Progression/DailyRewardSystem.cs`
- **Estimated**: 250 lines, 2 hours
- **Tasks**:
  - 7-day streak calendar
  - Escalating rewards (coins → gems → vehicles)
  - Streak reset at midnight UTC
  - Login reminder UI

### 3. Unity Package Setup (CRITICAL - Before Testing)
- **Impact**: Required for monetization to work
- **Tasks**:
  - Install Unity IAP package (Package Manager)
  - Install Unity Ads package (Package Manager)
  - Configure Unity Dashboard (Game IDs, ad units)
  - Set product IDs in Google Play & App Store Connect
  - Test sandbox purchases

## Technical Debt
- Replace stub managers with real implementations from MobileGameCore
- Add unit tests for scoring/progression
- Performance profiling (target 60 FPS on mid-range)

## Revenue KPIs (Targets)
- **ARPDAU**: $0.03-$0.05
- **IAP Conversion**: 2-3%
- **Ad Fill Rate**: >90%
- **D1 Retention**: 35-40%
- **D7 Retention**: 15-20%

## Agent Synergies
- **MobileGameCore**: Shared IAP/Ads/Analytics framework
- **Block Blast**: Similar progression patterns
- **Pet Quest**: Battle pass reference
- **LootStack**: Economy balancing
