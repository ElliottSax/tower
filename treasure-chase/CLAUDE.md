# Treasure Chase - Agent Guide

## Project Status

**Last Updated**: 2026-02-10
**Status**: Week 2-3 Implementation (Core loop partially complete)

## Current Implementation

### ✅ Completed (Week 1-2)
- Endless runner mechanics (auto-forward, lane switching)
- Infinite terrain generation with object pooling
- Distance tracking system
- Score management with multipliers
- Basic obstacle system
- Power-up collection framework
- Ghost recording system (foundation)
- Tutorial system (foundation)
- Stub managers for integration

### 🚧 In Progress
- Monetization integration (IAP + Ads)
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

### 1. IAP Integration (CRITICAL - Week 3)
- **Impact**: 30% of revenue, required for launch
- **Files**: Create `Scripts/Monetization/IAPManager.cs`
- **Tasks**:
  - Unity IAP package integration
  - 5 products: Remove Ads ($2.99), Coin Packs ($0.99-$19.99), Starter Bundle ($4.99)
  - Purchase restoration
  - Receipt validation

### 2. Ads Integration (CRITICAL - Week 3)
- **Impact**: 70% of revenue, required for launch
- **Files**: Enhance `StubScripts/OtherStubManagers.cs` AdsManager
- **Tasks**:
  - Unity Ads SDK integration
  - Rewarded video: Continue run, 2x coins, power-up boost
  - Interstitials: Between runs (respectful frequency)
  - Ad placement optimization (no ads during run)

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

1. **Commit current changes** (11 modified files)
2. **Implement IAP Manager** (Unity IAP integration)
3. **Implement Real Ads Manager** (Unity Ads)
4. **Test monetization flow** (purchase → ads → rewards)
5. **Update CLAUDE.md** with progress

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
