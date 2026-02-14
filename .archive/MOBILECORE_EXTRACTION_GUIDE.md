# MobileGameCore Extraction Guide
## Creating Your Reusable Game Systems Library

**Date:** 2026-01-26
**Source:** Treasure Multiplier Project
**Target:** Shared Unity Package for All 5 Games
**Timeline:** Week 1-2 of Master Plan

---

## 🎯 Objective

Extract proven, production-ready systems from the Treasure Multiplier project into a reusable Unity package that will serve as the foundation for all 5 mobile games.

**Why This Matters:**
- ✅ **Save 2-4 weeks per game** (don't rebuild common systems)
- ✅ **Consistent quality** across all games
- ✅ **Bug fixes propagate** to all games instantly
- ✅ **Professional architecture** (portfolio showcase)
- ✅ **Faster iteration** (focus on gameplay, not infrastructure)

---

## 📦 Package Structure

### Option A: Unity Package (Recommended)

Create a local Unity Package at:
```
/mnt/e/projects/MobileGameCore/
```

### Option B: Git Submodule (Advanced)

Create separate repo and use as submodule in each game project.

**For simplicity, we'll use Option A.**

---

## 🗂️ Systems to Extract

### From Treasure Project

Located in: `/mnt/e/projects/treasure/Assets/Scripts/`

| System | File | Lines | Priority | Dependencies |
|--------|------|-------|----------|--------------|
| SaveSystem | Core/SaveSystem.cs | 530 | CRITICAL | None |
| AnalyticsManager | Analytics/AnalyticsManager.cs | 520 | HIGH | Firebase |
| AdManager | Monetization/AdManager.cs | 380 | HIGH | Unity Ads |
| ATTManager | Monetization/ATTManager.cs | 180 | HIGH | iOS only |
| EconomyManager | Economy/EconomyManager.cs | 420 | HIGH | SaveSystem |
| AudioManager | Audio/AudioManager.cs | 320 | MEDIUM | None |
| AchievementSystem | Core/AchievementSystem.cs | 600 | MEDIUM | SaveSystem |
| DailyChallengeSystem | Core/DailyChallengeSystem.cs | 500 | MEDIUM | SaveSystem |
| InputManager | Input/InputManager.cs | 290 | MEDIUM | None |
| EnhancedCameraController | Camera/EnhancedCameraController.cs | 480 | MEDIUM | None |
| GameFeelManager | Effects/GameFeelManager.cs | 350 | MEDIUM | Camera |
| TransitionManager | Effects/TransitionManager.cs | 280 | LOW | None |
| PerformanceProfiler | Debug/PerformanceProfiler.cs | 320 | LOW | None |
| ProceduralMeshGenerator | ProceduralAssets/ProceduralMeshGenerator.cs | 400 | HIGH | None |
| ProceduralTreasure | ProceduralAssets/ProceduralTreasure.cs | 380 | HIGH | ProceduralMeshGenerator |
| ProceduralParticles | ProceduralAssets/ProceduralParticles.cs | 450 | MEDIUM | None |
| AudioSynthesizer | ProceduralAssets/AudioSynthesizer.cs | 320 | MEDIUM | None |

**Total: ~6,720 lines of reusable code**

---

## 🏗️ Step-by-Step Extraction

### Phase 1: Create Package Structure (30 minutes)

**Step 1: Create Directory**

```bash
cd /mnt/e/projects
mkdir -p MobileGameCore/Runtime
mkdir -p MobileGameCore/Runtime/Core
mkdir -p MobileGameCore/Runtime/Analytics
mkdir -p MobileGameCore/Runtime/Monetization
mkdir -p MobileGameCore/Runtime/Economy
mkdir -p MobileGameCore/Runtime/Audio
mkdir -p MobileGameCore/Runtime/Input
mkdir -p MobileGameCore/Runtime/Camera
mkdir -p MobileGameCore/Runtime/Effects
mkdir -p MobileGameCore/Runtime/Performance
mkdir -p MobileGameCore/Runtime/ProceduralGeneration
mkdir -p MobileGameCore/Runtime/Utils
mkdir -p MobileGameCore/Editor
mkdir -p MobileGameCore/Documentation
```

**Step 2: Create package.json**

File: `/mnt/e/projects/MobileGameCore/package.json`

```json
{
  "name": "com.yourstudio.mobilegamecore",
  "version": "1.0.0",
  "displayName": "Mobile Game Core",
  "description": "Reusable systems for mobile game development. Includes analytics, monetization, save system, procedural generation, and more.",
  "unity": "2022.3",
  "keywords": [
    "mobile",
    "game",
    "framework",
    "analytics",
    "monetization",
    "procedural"
  ],
  "author": {
    "name": "Your Studio",
    "email": "your@email.com"
  }
}
```

**Step 3: Create Assembly Definition**

File: `/mnt/e/projects/MobileGameCore/Runtime/MobileGameCore.asmdef`

```json
{
  "name": "MobileGameCore",
  "rootNamespace": "MobileGameCore",
  "references": [
    "Unity.Advertisements",
    "Unity.Services.Core",
    "Unity.Services.Analytics"
  ],
  "includePlatforms": [],
  "excludePlatforms": [],
  "allowUnsafeCode": false,
  "overrideReferences": false,
  "precompiledReferences": [],
  "autoReferenced": true,
  "defineConstraints": [],
  "versionDefines": [],
  "noEngineReferences": false
}
```

---

### Phase 2: Extract Core Systems (2-3 hours)

**Priority 1: Save System (CRITICAL)**

```bash
# Copy from Treasure project
cp /mnt/e/projects/treasure/Assets/Scripts/Core/SaveSystem.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs
```

**Modifications Needed:**
- Change namespace from `TreasureMultiplier.Core` to `MobileGameCore`
- Make sure it's game-agnostic (no Treasure-specific save data)
- Add generic save/load methods

**Priority 2: Analytics Manager**

```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Analytics/AnalyticsManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Analytics/AnalyticsManager.cs
```

**Modifications:**
- Change namespace
- Make events generic (don't hardcode Treasure-specific events)
- Add common event presets (game_start, game_over, etc.)

**Priority 3: Ad Manager**

```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Monetization/AdManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Monetization/AdManager.cs

cp /mnt/e/projects/treasure/Assets/Scripts/Monetization/ATTManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Monetization/ATTManager.cs
```

**Modifications:**
- Change namespace
- Already game-agnostic (should work as-is)

**Priority 4: Economy Manager**

```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Economy/EconomyManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Economy/EconomyManager.cs
```

**Modifications:**
- Change namespace
- Make currency types configurable (not hardcoded)

---

### Phase 3: Extract Support Systems (2 hours)

**Audio Manager:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Audio/AudioManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Audio/AudioManager.cs
```

**Achievement System:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Core/AchievementSystem.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Core/AchievementSystem.cs
```

**Daily Challenge System:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Core/DailyChallengeSystem.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Core/DailyChallengeSystem.cs
```

**Input Manager:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Input/InputManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Input/InputManager.cs
```

**Camera Controller:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Camera/EnhancedCameraController.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Camera/EnhancedCameraController.cs
```

**Game Feel Manager:**
```bash
cp /mnt/e/projects/treasure/Assets/Scripts/Effects/GameFeelManager.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Effects/GameFeelManager.cs
```

**All need namespace change to `MobileGameCore`**

---

### Phase 4: Extract Procedural Generation (2 hours)

**These are your SECRET WEAPON - most valuable reusable systems!**

```bash
# Base class
cp /mnt/e/projects/treasure/Assets/Scripts/ProceduralAssets/ProceduralMeshGenerator.cs \
   /mnt/e/projects/MobileGameCore/Runtime/ProceduralGeneration/ProceduralMeshGenerator.cs

# Treasure generator (HIGH VALUE)
cp /mnt/e/projects/treasure/Assets/Scripts/ProceduralAssets/ProceduralTreasure.cs \
   /mnt/e/projects/MobileGameCore/Runtime/ProceduralGeneration/ProceduralTreasure.cs

# Particles
cp /mnt/e/projects/treasure/Assets/Scripts/ProceduralAssets/ProceduralParticles.cs \
   /mnt/e/projects/MobileGameCore/Runtime/ProceduralGeneration/ProceduralParticles.cs

# Audio synthesizer
cp /mnt/e/projects/treasure/Assets/Scripts/ProceduralAssets/AudioSynthesizer.cs \
   /mnt/e/projects/MobileGameCore/Runtime/Audio/AudioSynthesizer.cs

# Terrain (optional, useful for Game #3)
cp /mnt/e/projects/treasure/Assets/Scripts/ProceduralAssets/ProceduralTerrain.cs \
   /mnt/e/projects/MobileGameCore/Runtime/ProceduralGeneration/ProceduralTerrain.cs
```

**Modifications:**
- Change all namespaces to `MobileGameCore.ProceduralGeneration`
- Make sure generators are configurable (seed, parameters)

---

### Phase 5: Add Utility Classes (1 hour)

**Create New Files** (these don't exist in Treasure, but are universally useful):

**File: `/mnt/e/projects/MobileGameCore/Runtime/Utils/Singleton.cs`**

```csharp
using UnityEngine;

namespace MobileGameCore.Utils
{
    /// <summary>
    /// Singleton pattern for MonoBehaviours.
    /// </summary>
    public class Singleton<T> : MonoBehaviour where T : MonoBehaviour
    {
        private static T _instance;
        private static readonly object _lock = new object();

        public static T Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = FindObjectOfType<T>();

                        if (_instance == null)
                        {
                            GameObject singleton = new GameObject(typeof(T).Name);
                            _instance = singleton.AddComponent<T>();
                            DontDestroyOnLoad(singleton);
                        }
                    }
                    return _instance;
                }
            }
        }

        protected virtual void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Destroy(gameObject);
                return;
            }
            _instance = this as T;
            DontDestroyOnLoad(gameObject);
        }
    }
}
```

**File: `/mnt/e/projects/MobileGameCore/Runtime/Utils/ObjectPooler.cs`**

```csharp
using System.Collections.Generic;
using UnityEngine;

namespace MobileGameCore.Utils
{
    /// <summary>
    /// Simple object pooler for performance optimization.
    /// </summary>
    public class ObjectPooler : MonoBehaviour
    {
        private Dictionary<string, Queue<GameObject>> _pools = new Dictionary<string, Queue<GameObject>>();

        public GameObject Spawn(GameObject prefab, Vector3 position, Quaternion rotation)
        {
            string key = prefab.name;

            if (!_pools.ContainsKey(key))
            {
                _pools[key] = new Queue<GameObject>();
            }

            GameObject obj;
            if (_pools[key].Count > 0)
            {
                obj = _pools[key].Dequeue();
                obj.transform.position = position;
                obj.transform.rotation = rotation;
                obj.SetActive(true);
            }
            else
            {
                obj = Instantiate(prefab, position, rotation);
                obj.name = key;
            }

            return obj;
        }

        public void Despawn(GameObject obj)
        {
            obj.SetActive(false);

            string key = obj.name;
            if (!_pools.ContainsKey(key))
            {
                _pools[key] = new Queue<GameObject>();
            }

            _pools[key].Enqueue(obj);
        }

        public void PreWarm(GameObject prefab, int count)
        {
            string key = prefab.name;
            if (!_pools.ContainsKey(key))
            {
                _pools[key] = new Queue<GameObject>();
            }

            for (int i = 0; i < count; i++)
            {
                GameObject obj = Instantiate(prefab);
                obj.name = key;
                obj.SetActive(false);
                _pools[key].Enqueue(obj);
            }
        }
    }
}
```

**File: `/mnt/e/projects/MobileGameCore/Runtime/Utils/Timer.cs`**

```csharp
using System;
using UnityEngine;

namespace MobileGameCore.Utils
{
    /// <summary>
    /// Simple timer utility.
    /// </summary>
    public class Timer
    {
        private float _duration;
        private float _elapsed;
        private bool _isRunning;
        private Action _onComplete;

        public float Elapsed => _elapsed;
        public float Remaining => Mathf.Max(0, _duration - _elapsed);
        public float Progress => Mathf.Clamp01(_elapsed / _duration);
        public bool IsRunning => _isRunning;

        public Timer(float duration, Action onComplete = null)
        {
            _duration = duration;
            _onComplete = onComplete;
        }

        public void Start()
        {
            _isRunning = true;
            _elapsed = 0f;
        }

        public void Stop()
        {
            _isRunning = false;
        }

        public void Reset()
        {
            _elapsed = 0f;
        }

        public void Update(float deltaTime)
        {
            if (!_isRunning) return;

            _elapsed += deltaTime;

            if (_elapsed >= _duration)
            {
                _isRunning = false;
                _onComplete?.Invoke();
            }
        }
    }
}
```

---

### Phase 6: Create Documentation (1 hour)

**File: `/mnt/e/projects/MobileGameCore/README.md`**

```markdown
# Mobile Game Core

Reusable systems library for Unity mobile games.

## Features

- ✅ Save System (SHA256 integrity checking)
- ✅ Analytics (Firebase integration)
- ✅ Monetization (Unity Ads + IAP)
- ✅ Economy (currency management)
- ✅ Audio (manager + procedural synthesis)
- ✅ Achievements (unlock system)
- ✅ Daily Challenges (engagement)
- ✅ Input (touch, tilt, swipe)
- ✅ Camera (enhanced follow + shake)
- ✅ Game Feel (hit stop, slow motion)
- ✅ Procedural Generation (meshes, particles, audio)
- ✅ Performance (profiler, object pooling)

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

## System Overview

### SaveSystem
Secure save/load with SHA256 hash verification.

```csharp
SaveSystem.Instance.SaveData("player_name", "Alice");
string name = SaveSystem.Instance.LoadData<string>("player_name");
```

### AnalyticsManager
Firebase Analytics integration with graceful degradation.

```csharp
AnalyticsManager.Instance.LogEvent("level_complete", new Dictionary<string, object>
{
    { "level", 5 },
    { "score", 1000 }
});
```

### AdManager
Unity Ads with rewarded + interstitial support.

```csharp
AdManager.Instance.ShowRewardedAd((success) =>
{
    if (success)
    {
        // Grant reward
    }
});
```

### EconomyManager
Multi-currency economy system.

```csharp
EconomyManager.Instance.AddCurrency("coins", 100);
bool canAfford = EconomyManager.Instance.CanAfford("coins", 50);
EconomyManager.Instance.SpendCurrency("coins", 50);
```

### ProceduralTreasure
Generate treasure meshes at runtime (zero asset files!).

```csharp
ProceduralTreasure treasure = gameObject.AddComponent<ProceduralTreasure>();
treasure.treasureType = TreasureType.GoldBar;
treasure.GenerateMesh();
```

## Dependencies

- Unity 2022.3 LTS or later
- Firebase SDK (optional, graceful degradation)
- Unity Ads (optional)
- Unity IAP (optional)

## Used In Games

- Treasure Multiplier
- Loot Stack Mayhem (Game #1)
- Block Breaker Ascent (Game #2)
- Dimension Dash (Game #3)
- Merge Defense Kingdom (Game #4)
- Resource Rush Tycoon (Game #5)

## License

MIT License (or your preferred license)
```

**File: `/mnt/e/projects/MobileGameCore/CHANGELOG.md`**

```markdown
# Changelog

## [1.0.0] - 2026-01-26

### Added
- Initial release
- Extracted from Treasure Multiplier project
- 17 core systems (~6,720 lines)
- Complete documentation
- Utility classes (Singleton, ObjectPooler, Timer)

### Systems Included
- SaveSystem (SHA256 integrity)
- AnalyticsManager (Firebase)
- AdManager + ATTManager (Unity Ads)
- EconomyManager
- AudioManager + AudioSynthesizer
- AchievementSystem
- DailyChallengeSystem
- InputManager
- EnhancedCameraController
- GameFeelManager
- TransitionManager
- PerformanceProfiler
- ProceduralMeshGenerator
- ProceduralTreasure
- ProceduralParticles

### Utilities
- Singleton<T> pattern
- ObjectPooler (performance)
- Timer (utility)
```

---

## 🧪 Testing the Package

### Create Test Project

```bash
# Create new Unity project (Unity Hub or command line)
# Name: MobileGameCoreTest
```

**In Unity:**
1. Window → Package Manager
2. + → Add package from disk
3. Select `/mnt/e/projects/MobileGameCore/package.json`
4. Verify all scripts compile

**Create Test Scene:**

```csharp
using UnityEngine;
using MobileGameCore;
using MobileGameCore.Utils;

public class CoreTest : MonoBehaviour
{
    void Start()
    {
        // Test each system
        TestSaveSystem();
        TestEconomy();
        TestTimer();
    }

    void TestSaveSystem()
    {
        SaveSystem.Instance.SaveData("test_key", "test_value");
        string loaded = SaveSystem.Instance.LoadData<string>("test_key");
        Debug.Log($"SaveSystem Test: {(loaded == "test_value" ? "PASS" : "FAIL")}");
    }

    void TestEconomy()
    {
        EconomyManager.Instance.AddCurrency("coins", 100);
        int coins = EconomyManager.Instance.GetCurrency("coins");
        Debug.Log($"Economy Test: {(coins == 100 ? "PASS" : "FAIL")}");
    }

    void TestTimer()
    {
        Timer timer = new Timer(1.0f, () => Debug.Log("Timer Complete!"));
        timer.Start();
        Debug.Log($"Timer Test: {(timer.IsRunning ? "PASS" : "FAIL")}");
    }
}
```

**Expected:** All tests pass, no compile errors.

---

## 📊 Checklist

### Package Creation
- [ ] Directory structure created
- [ ] package.json created
- [ ] Assembly definition created
- [ ] README.md written
- [ ] CHANGELOG.md created

### Core Systems Extracted
- [ ] SaveSystem.cs
- [ ] AnalyticsManager.cs
- [ ] AdManager.cs
- [ ] ATTManager.cs
- [ ] EconomyManager.cs
- [ ] AudioManager.cs
- [ ] AchievementSystem.cs
- [ ] DailyChallengeSystem.cs
- [ ] InputManager.cs
- [ ] EnhancedCameraController.cs
- [ ] GameFeelManager.cs
- [ ] TransitionManager.cs
- [ ] PerformanceProfiler.cs

### Procedural Generation Extracted
- [ ] ProceduralMeshGenerator.cs
- [ ] ProceduralTreasure.cs
- [ ] ProceduralParticles.cs
- [ ] AudioSynthesizer.cs
- [ ] ProceduralTerrain.cs (optional)

### Utilities Created
- [ ] Singleton.cs
- [ ] ObjectPooler.cs
- [ ] Timer.cs

### Namespace Changes
- [ ] All files use `MobileGameCore` namespace
- [ ] No references to `TreasureMultiplier` namespace

### Testing
- [ ] Test project created
- [ ] Package imports successfully
- [ ] All scripts compile
- [ ] Basic functionality tested
- [ ] No errors in console

### Documentation
- [ ] README.md complete
- [ ] Quick Start guide included
- [ ] System overview documented
- [ ] Example code provided

---

## 🚀 Next Steps

Once MobileGameCore is complete:

1. **Git Repository** (optional but recommended)
   ```bash
   cd /mnt/e/projects/MobileGameCore
   git init
   git add .
   git commit -m "Initial commit: MobileGameCore v1.0.0"
   ```

2. **Start Game #1**
   - Create new Unity project: LootStackMayhem
   - Import MobileGameCore package
   - Follow `GAME1_LOOT_STACK_DETAILED_PLAN.md`

3. **Iterate**
   - As you build games, update MobileGameCore
   - Add new utilities as needed
   - Bug fixes propagate to all games

---

## 💡 Pro Tips

### Best Practices

1. **Keep It Generic**
   - Don't add game-specific code to MobileGameCore
   - Use inheritance/composition in individual games

2. **Version Control**
   - Tag releases (v1.0.0, v1.1.0, etc.)
   - Use semantic versioning
   - Document breaking changes

3. **Testing**
   - Test in each new game project
   - Fix bugs in MobileGameCore, not in games
   - Update all games when you update core

4. **Documentation**
   - Update README when adding systems
   - Include code examples
   - Document breaking changes

### Common Pitfalls

❌ **Don't:**
- Add game-specific logic to core systems
- Hardcode values that should be configurable
- Skip namespace changes (causes conflicts)
- Forget to update CHANGELOG

✅ **Do:**
- Keep systems decoupled
- Use events for communication
- Provide sensible defaults
- Test thoroughly before using in games

---

## 🎯 Success Criteria

MobileGameCore is ready when:

- ✅ All files extracted and namespaced correctly
- ✅ Package imports into new Unity project
- ✅ No compile errors
- ✅ Basic functionality tested
- ✅ Documentation complete
- ✅ Ready to use in Game #1

**Timeline:** 1-2 weeks (can be done in parallel with planning)

**Effort:** ~10-15 hours total

**Value:** Saves 2-4 weeks per game (5 games = 10-20 weeks saved!)

---

## 📞 Support

If you encounter issues:

1. Check namespace changes (most common issue)
2. Verify Unity version (2022.3 LTS required)
3. Check dependencies (Firebase, Unity Ads optional)
4. Review CHANGELOG for breaking changes

---

**Ready to extract! This is the foundation of your indie game studio.** 🏗️

**Next:** Once complete, proceed to `GAME1_LOOT_STACK_DETAILED_PLAN.md`
