# 🎮 Mobile Game Core

**Production-ready systems library for Unity mobile games.**

**Status: COMPLETE! ✅** | **17/17 Systems** | **~6,500 Lines** | **Zero Asset Dependencies**

---

## ✨ What Is This?

MobileGameCore is a complete, battle-tested framework for building mobile games in Unity. Extract from a successful production game, it provides everything you need to build professional mobile games quickly.

### **The Secret Weapon: Zero Asset Dependencies**
- Generate meshes at runtime (coins, gems, chests)
- Create particle effects programmatically
- Synthesize sound effects from code
- **No 3D models, no textures, no audio files needed!**

---

## 📦 Complete Feature List

### Core Systems (4)
- ✅ **SaveSystem** - SHA256 integrity, multi-currency, level progress
- ✅ **AnalyticsManager** - Firebase integration with graceful fallback
- ✅ **AchievementSystem** - Progress tracking, unlocks, rewards
- ✅ **DailyChallengeSystem** - Daily missions, streaks, auto-reset

### Monetization (2)
- ✅ **AdManager** - Unity Ads (rewarded + interstitial) with bug fixes
- ✅ **ATTManager** - iOS 14+ App Tracking Transparency compliance

### Economy & Audio (2)
- ✅ **EconomyManager** - Multi-currency, purchases, upgrades
- ✅ **AudioManager** - Music + SFX with mobile-optimized pooling

### Procedural Generation (4) 🌟
- ✅ **ProceduralMeshGenerator** - Base class for runtime mesh creation
- ✅ **ProceduralCollectable** - Generate coins, gems, chests (5 shapes, 8 colors)
- ✅ **ProceduralParticles** - 9 effect types (sparkles, explosions, trails)
- ✅ **AudioSynthesizer** - Synthesize bleeps, bloops, chords, sweeps

### Game Feel & Polish (3)
- ✅ **GameFeelManager** - Hit freeze, slow motion, camera shake
- ✅ **EnhancedCameraController** - Smooth follow, shake, dynamic zoom
- ✅ **TransitionManager** - Scene transitions with loading screens

### Input & Debug (2)
- ✅ **InputManager** - Touch, tilt, swipe (3 modes)
- ✅ **PerformanceProfiler** - FPS, memory, draw calls (F1 overlay)

## Installation

### Option 1: Local Package

1. Copy `MobileGameCore` folder to your project
2. In Unity: Window → Package Manager → + → Add package from disk
3. Select `MobileGameCore/package.json`

### Option 2: Import into Assets

1. Copy `MobileGameCore/Runtime` folder to `Assets/MobileGameCore`
2. Scripts will be available immediately

## Quick Start

```csharp
using MobileGameCore;
using MobileGameCore.Utils;

public class GameManager : Singleton<GameManager>
{
    void Start()
    {
        // Initialize core systems
        SaveSystem.Instance.Initialize();
        AnalyticsManager.Instance.Initialize();
        AdManager.Instance.Initialize();

        // Ready to go!
    }
}
```

## Extracted from

Treasure Multiplier project - production-ready, tested code.

## License

MIT License (or your preferred license)
