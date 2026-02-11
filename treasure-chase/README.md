# Treasure Chase - Endless Runner

**Genre:** Endless Runner + Collection Hybrid
**Platform:** iOS & Android
**Engine:** Unity 2022.3 LTS
**Status:** In Development

## Project Overview

Treasure Chase is an endless runner mobile game where players collect treasures, multiply their score through gates, and compete on global leaderboards. Built by adapting the Treasure Multiplier codebase (~95% code reuse).

## Key Features

- 🏃 Endless running with lane-switching mechanics
- 💎 Treasure collection system
- ⚡ Multiplier gates (x2, x3, x5, x10)
- 🚧 7+ obstacle types
- 🌍 4 unique world themes
- 🏆 Tournaments and leaderboards
- 👻 Ghost racing
- 🎯 Daily challenges
- 🎮 8 unlockable vehicles

## Documentation

- [Implementation Guide](../TREASURE_CHASE_IMPLEMENTATION.md) - Week-by-week development plan
- [Master Plan](../MOBILE_GAME_MASTER_PLAN.md) - Overall strategy
- [Game Design Document](../GAME_DESIGN_DOCUMENTS.md) - Complete GDD

## Development Timeline

- **Week 1-2:** Core endless runner conversion
- **Week 3-4:** Obstacle variety & polish
- **Week 5:** Progression integration
- **Week 6:** World system
- **Week 7:** Competitive features
- **Week 8:** Testing & launch prep

**Target Launch:** 8 weeks from start

## Technical Stack

- Unity 2022.3 LTS
- C# .NET Standard 2.1
- Universal Render Pipeline (URP)
- IL2CPP scripting backend
- Firebase Analytics
- Unity Ads
- Google Play Games Services (Android)
- Game Center (iOS)

## Project Structure

```
treasure-chase/
├── Assets/
│   ├── Scripts/
│   │   ├── Core/              (From Treasure Multiplier)
│   │   ├── Endless/           (NEW - Endless runner specific)
│   │   ├── UI/                (From Treasure Multiplier)
│   │   ├── Procedural/        (From Treasure Multiplier)
│   │   └── Monetization/      (From Treasure Multiplier)
│   ├── Scenes/
│   │   ├── MainMenu.unity
│   │   ├── EndlessGame.unity
│   │   └── TestScene.unity
│   └── Data/
│       ├── Worlds/            (WorldTheme ScriptableObjects)
│       └── Config/            (Balance configurations)
├── Documentation/
│   ├── IMPLEMENTATION.md      (Technical implementation)
│   ├── BALANCE.md             (Game balance notes)
│   └── CHANGELOG.md           (Version history)
└── README.md                  (This file)
```

## Getting Started

### Prerequisites
- Unity 2022.3 LTS or later
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)
- Git

### Setup Instructions

1. **Clone Treasure Multiplier Base:**
   ```bash
   # This project extends Treasure Multiplier
   # Copy the Treasure Multiplier project files here
   cp -r ../treasure/Assets/* Assets/
   ```

2. **Install Dependencies:**
   - Firebase Unity SDK
   - Unity Ads SDK
   - Google Play Games SDK (Android)
   - Game Center SDK (iOS)

3. **Configure Project:**
   - Open in Unity 2022.3 LTS
   - Set build target to Android or iOS
   - Configure Player Settings (see Implementation Guide)

4. **Run Test Scene:**
   - Open `TestScene.unity`
   - Press Play
   - Verify basic movement works

### Week 1 Development Tasks

See [Implementation Guide](../TREASURE_CHASE_IMPLEMENTATION.md) for detailed tasks.

**Quick Start (Day 1):**
1. Modify `VehicleController.cs` for auto-forward movement
2. Create `InfiniteTerrainManager.cs` for chunk-based terrain
3. Add `DistanceTracker.cs` for distance tracking
4. Test basic endless loop

## Code Reuse from Treasure Multiplier

**100% Reusable (~14,000 lines):**
- ✅ GameManager.cs
- ✅ SaveSystem.cs
- ✅ EconomyManager.cs
- ✅ AnalyticsManager.cs
- ✅ AchievementSystem.cs
- ✅ DailyChallengeSystem.cs
- ✅ All UI systems (Menu, HUD, Settings, Shop)
- ✅ AudioManager.cs
- ✅ AdManager.cs
- ✅ ATTManager.cs (iOS)
- ✅ All procedural generation systems
- ✅ EnhancedCameraController.cs
- ✅ GameFeelManager.cs
- ✅ TransitionManager.cs
- ✅ PerformanceProfiler.cs

**Needs Modification (~2,000 lines):**
- ⚙️ VehicleController.cs (add auto-forward)
- ⚙️ LevelManager.cs (adapt for endless)
- ⚙️ TreasureSpawner.cs (make infinite)
- ⚙️ InputManager.cs (add swipe for jump/duck)

**New Development (~2,500 lines):**
- 🆕 InfiniteTerrainManager.cs (~350 lines)
- 🆕 ObstacleSpawner.cs (~400 lines)
- 🆕 DistanceTracker.cs (~200 lines)
- 🆕 EndlessScoreManager.cs (~300 lines)
- 🆕 WorldManager.cs (~250 lines)
- 🆕 GhostRecorder/Player.cs (~300 lines)
- 🆕 TournamentManager.cs (~400 lines)
- 🆕 EndlessTutorial.cs (~250 lines)

## Success Metrics

### Target KPIs
- **D1 Retention:** 35-40%
- **D7 Retention:** 15-20%
- **D30 Retention:** 5-8%
- **ARPDAU:** $0.03-$0.05
- **Session Length:** 8-12 minutes
- **Sessions/Day:** 3-4
- **Crash-Free Rate:** >99.5%

### Performance Targets
- **Low-End (2-4GB):** 30 FPS minimum
- **Mid-Range (4-8GB):** 60 FPS stable
- **High-End (8GB+):** 60 FPS locked
- **Build Size:** <100 MB

## Monetization

### Ad Revenue (Primary - 70%)
- Rewarded video ads (continue, double coins, power-ups)
- Interstitial ads (between runs, respectful frequency)
- Expected: $0.025-$0.04 per DAU

### IAP Revenue (Secondary - 30%)
- Remove ads: $2.99
- Coin packs: $0.99 - $19.99
- Vehicle bundles: $0.99 - $14.99
- Battle Pass: $4.99/month
- Expected: 2-3% conversion rate

## Contributing

This is currently a solo/small team project. Contributions welcome after initial launch.

## License

Proprietary - All rights reserved
Contact for licensing inquiries

## Contact

- Developer: [Your Name]
- Email: [Your Email]
- Website: [Your Website]

## Changelog

### v0.1.0 (Current - In Development)
- Initial project setup
- Documentation complete
- Ready to start Week 1 development

---

**Let's build an amazing endless runner! 🚀**

Last Updated: 2026-01-26
