# Changelog

All notable changes to MobileGameCore will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-10

### Added - PRODUCTION READY RELEASE
- **IAPManager.cs**: Complete Unity IAP integration for revenue
  - Consumables, non-consumables, subscriptions
  - Product catalog with 5 example products
  - Receipt handling and restore purchases (iOS)
  - Analytics integration for purchase tracking
  - Graceful fallback when IAP not available

- **RemoteConfigManager.cs**: Live content updates without app updates
  - Unity Remote Config integration
  - A/B testing support
  - Live economy tuning (prices, rewards, multipliers)
  - Feature flags for remote kill switches
  - Event configuration (seasonal events)
  - 15+ pre-configured default values

- **Assembly Definitions**: Fast compilation and proper dependencies
  - MobileGameCore.Runtime.asmdef
  - MobileGameCore.Editor.asmdef
  - Conditional compilation for optional packages

- **Enhanced Analytics**:
  - LogPurchase() for Firebase ecommerce tracking
  - Real-money IAP revenue tracking
  - Proper currency code support

### Changed
- Updated package.json to v1.1.0
- Added optional dependencies for Unity packages
- Enhanced documentation with revenue impact notes

### Revenue Impact
- **Direct**: IAPManager enables premium currency, ad removal, VIP subscriptions
- **Optimization**: RemoteConfigManager enables live A/B testing of prices/rewards
- **Tracking**: Enhanced analytics for data-driven monetization decisions

## [1.0.0] - 2026-01-26

### Added - INITIAL EXTRACTION
- **Core Systems** (4):
  - SaveSystem.cs: SHA256 integrity, multi-currency, level progress
  - AnalyticsManager.cs: Firebase integration with graceful fallback
  - AchievementSystem.cs: Progress tracking, unlocks, rewards
  - DailyChallengeSystem.cs: Daily missions, streaks, auto-reset

- **Monetization** (2):
  - AdManager.cs: Unity Ads (rewarded + interstitial)
  - ATTManager.cs: iOS 14+ App Tracking Transparency

- **Economy & Audio** (2):
  - EconomyManager.cs: Multi-currency, purchases, upgrades
  - AudioManager.cs: Music + SFX with mobile-optimized pooling

- **Procedural Generation** (4):
  - ProceduralMeshGenerator.cs: Base class for runtime meshes
  - ProceduralCollectable.cs: Generate coins, gems, chests
  - ProceduralParticles.cs: 9 effect types
  - AudioSynthesizer.cs: Synthesize sound effects

- **Game Feel & Polish** (3):
  - GameFeelManager.cs: Hit freeze, slow motion, camera shake
  - EnhancedCameraController.cs: Smooth follow, shake, dynamic zoom
  - TransitionManager.cs: Scene transitions with loading screens

- **Input & Debug** (2):
  - InputManager.cs: Touch, tilt, swipe (3 modes)
  - PerformanceProfiler.cs: FPS, memory, draw calls

### Key Features
- **Zero Asset Dependencies**: Everything generated at runtime
- **Mobile-First Design**: Touch input, performance optimization
- **Production Quality**: Battle-tested from Treasure Chase project
- **Complete Documentation**: XML comments on all public APIs

### Statistics
- 17 core systems
- ~6,500 lines of code
- Package size: ~150 KB (code only)
- Compilation: Zero errors

---

## Upgrade Guide

### 1.0.0 → 1.1.0

#### New Features Available
1. **In-App Purchases**: Add IAPManager to your bootstrap scene
2. **Remote Config**: Add RemoteConfigManager for live tuning
3. **Enhanced Revenue Tracking**: Use LogPurchase() for IAP analytics

#### Breaking Changes
- None! Fully backwards compatible.

#### Recommended Updates
```csharp
// OLD (v1.0.0) - still works
void Start() {
    SaveSystem.Instance.Initialize();
    AnalyticsManager.Instance.Initialize();
}

// NEW (v1.1.0) - recommended pattern
void Start() {
    // 1. Core
    SaveSystem.Instance.Initialize();
    AnalyticsManager.Instance.Initialize();

    // 2. Remote Config (fetch latest values)
    RemoteConfigManager.Instance.InitializeAndFetch(() => {
        // 3. Economy (use remote values)
        EconomyManager.Instance.Initialize();

        // 4. IAP (revenue!)
        IAPManager.Instance.InitializeIAP();

        // 5. Ads (backup revenue)
        AdManager.Instance.Initialize();

        StartGame();
    });
}
```

#### New Dependencies (Optional)
- `com.unity.purchasing` (4.0.0+) - for IAPManager
- `com.unity.remote-config` (3.0.0+) - for RemoteConfigManager
- `com.unity.services.core` (1.7.0+) - required by remote config

Install via Package Manager if you want to use these features.

---

## Roadmap

### v1.2.0 (Planned)
- [ ] Cloud Save integration (Google Play Games, iCloud)
- [ ] Push Notifications manager
- [ ] Social features (friends, invites, sharing)
- [ ] Advanced analytics (funnels, cohorts, retention)

### v1.3.0 (Planned)
- [ ] Multiplayer foundation (Netcode/Mirror integration)
- [ ] Leaderboards manager
- [ ] Cross-promotion system
- [ ] Advanced IAP (sale timers, limited offers)

### v2.0.0 (Future)
- [ ] Full LiveOps suite (events, seasons, battle pass)
- [ ] Advanced A/B testing framework
- [ ] Server-side validation for IAP
- [ ] Anti-cheat integration

---

## Support

**Found a bug?** Open an issue on GitHub.

**Need help?** Check INTEGRATION_GUIDE.md for examples.

**Want to contribute?** Pull requests welcome!
