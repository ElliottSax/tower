# LootStack Mayhem - Comprehensive Code Review

**Reviewer:** Senior Unity/C# Code Review Agent
**Date:** 2026-02-11
**Project:** `/mnt/e/projects/LootStackMayhem/`
**Files Reviewed:** 37/37 C# files (100%)
**Overall Quality Rating:** 5.5 / 10

---

## Executive Summary

LootStack Mayhem is a mobile arcade game with an extensive monetization framework (MobileGameCore). The project demonstrates solid architectural ambition with well-organized namespaces, event-driven communication, and comprehensive feature coverage (ads, IAP, battle pass, daily rewards, power-ups). However, there are several **critical gameplay-breaking bugs**, significant **memory/performance concerns** for mobile, and multiple **API mismatches** between systems that would prevent the game from functioning correctly in production.

The code shows signs of rapid development with multiple systems built in isolation that have not been integration-tested together. The MobileGameCore framework has good foundations but uses fragile patterns (heavy reflection usage, inconsistent persistence strategies).

---

## Critical Issues (Must Fix Before Ship)

### 1. MagnetPowerUp uses 3D Physics in a 2D Game (GAME-BREAKING)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Gameplay/MagnetPowerUp.cs`
**Lines:** 31-50

The game uses `Rigidbody2D` and `CircleCollider2D` (confirmed by `Treasure.cs` using `[RequireComponent(typeof(Rigidbody2D))]` and `OnCollisionEnter2D`), but MagnetPowerUp uses `Physics.OverlapSphere()` (3D) and casts to `Rigidbody` (3D). This power-up will **never find any treasures** and is completely non-functional.

**Fix:** Replace `Physics.OverlapSphere` with `Physics2D.OverlapCircleAll`, and `Rigidbody` with `Rigidbody2D`.

---

### 2. ShieldPowerUp Resets Player Score on "Save" (GAME-BREAKING)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Gameplay/ShieldPowerUp.cs`
**Lines:** 87-113

When the shield intercepts a game over, `CancelGameOver()` calls `GameManager.Instance.StartGame()`, which resets `currentScore = 0`, `multiplier = 1.0f`, and `comboCount = 0`. The shield is supposed to save the player, but it **destroys their entire run progress instead**.

**Fix:** Add a `ContinueGame()` method to GameManager that resumes play without resetting state, or refactor the shield to prevent the game over from triggering in the first place.

---

### 3. IAPManager Method/Event Name Collision (COMPILE ERROR)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Monetization/IAPManager.cs`

The class defines both an event `public event System.Action<string> OnPurchaseFailed` and a method `public void OnPurchaseFailed(Product product, PurchaseFailureDescription failDescription)`. When the method body calls `OnPurchaseFailed?.Invoke(product.definition.id)`, this creates ambiguity between the recursive method call and the event invocation. Depending on the C# compiler version, this either causes a compile error or infinite recursion.

**Fix:** Rename the event to something like `OnPurchaseFailedEvent` or rename the interface method implementation.

---

### 4. RewardedAdController "Continue" Resets Score (GAME-BREAKING)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Monetization/RewardedAdController.cs`

`ShowContinueAd` success callback calls `GameManager.Instance.StartGame()`, which resets all player progress. A player watches an ad to continue playing but loses their score.

**Fix:** Same as Shield issue - need a `ContinueGame()` method on GameManager.

---

### 5. GameManager-to-AnalyticsManager API Mismatch (COMPILE ERROR)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Core/GameManager.cs`

GameManager calls:
- `AnalyticsManager.Instance.TrackEvent("milestone_10_treasures", "count", treasuresCollected)` -- but TrackEvent's signature is `(string eventName, Dictionary<string, object> parameters)`, not `(string, string, int)`
- `AnalyticsManager.Instance.TrackLevelComplete(levelIndex: 1, stars: ..., score: ...)` -- but the actual method signature is `TrackLevelComplete(int levelNumber, int score, float timeSeconds, int stars = 0)`, which uses positional parameters differently and requires `timeSeconds`

**Fix:** Update GameManager calls to match AnalyticsManager's actual method signatures.

---

### 6. GameManager Calls Non-Existent SaveSystem.Initialize() (COMPILE ERROR)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Core/GameManager.cs`

`InitializeSystems()` calls `SaveSystem.Instance.Initialize()`, but SaveSystem has no public `Initialize()` method. SaveSystem initializes itself in `Awake()`.

**Fix:** Remove the explicit Initialize() call or add the method to SaveSystem.

---

### 7. Default Hash Salt Not Changed (SECURITY)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Core/SaveSystem.cs`
**Line:** ~22

```csharp
private const string HASH_SALT = "MobileGameCore_v1.0_ChangeThisInYourGame";
```

The default placeholder salt is still in use. Any player familiar with the framework can compute valid hashes for modified save data.

**Fix:** Change to a unique, project-specific salt value.

---

### 8. BattlePassManager Starts at Season 2 (BUG)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Progression/BattlePassManager.cs`

`StartNewSeason()` increments `currentSeasonNumber++` before setting up the first season. On first launch, this means the game starts at "Season 2" instead of "Season 1".

**Fix:** Only increment after the first season is complete, or initialize `currentSeasonNumber` to 0 so the first increment brings it to 1.

---

### 9. Ad Placeholder Game IDs in Production Code
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Monetization/AdManager.cs`

```csharp
[SerializeField] private string androidGameId = "YOUR_ANDROID_GAME_ID";
[SerializeField] private string iosGameId = "YOUR_IOS_GAME_ID";
```

These placeholder values will cause ad initialization to fail silently. All ad revenue = $0.

**Fix:** Replace with actual game IDs from the Unity Dashboard before shipping.

---

### 10. Battle Pass / Tier Skip Purchases Are Free (BUG)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Progression/BattlePassManager.cs`

`PurchasePremiumPass()` and `PurchaseTierSkip()` both have `// TODO: Verify IAP receipt` comments and immediately grant rewards without any payment verification. Players can get premium content for free.

**Fix:** Integrate with IAPManager before enabling these UI buttons.

---

## High-Priority Warnings

### 11. No Object Pooling for Treasures (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Gameplay/TreasureSpawner.cs`

Every treasure spawn creates a new GameObject (`new GameObject("Treasure")`). On mobile, this causes GC spikes and frame drops during heavy spawning. Treasures are the core mechanic and spawn continuously.

**Recommendation:** Implement an object pool. Recycle treasures instead of creating/destroying them.

---

### 12. ProceduralParticles Renders Per-Particle DrawMesh Calls (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/ProceduralGeneration/ProceduralParticles.cs`

Each individual particle is rendered with its own `Graphics.DrawMesh()` call. With 50+ particles, that means 50+ draw calls per emitter per frame. On mobile GPUs, this is extremely expensive.

**Recommendation:** Use Unity's built-in ParticleSystem, or batch particles into a single mesh.

---

### 13. Shader.Find at Runtime (BUILD FAILURE RISK)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/ProceduralGeneration/ProceduralParticles.cs`

```csharp
Shader shader = Shader.Find("Particles/Standard Unlit");
```

`Shader.Find()` only works at runtime if the shader is included in the build (referenced somewhere or added to "Always Included Shaders"). Procedural usage means no scene reference exists, so the shader may be stripped from the build, causing pink/missing materials.

**Recommendation:** Add the shader to Project Settings > Graphics > Always Included Shaders, or use a `[SerializeField] Shader` reference.

---

### 14. ProceduralCollectable Adds Light Component (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/ProceduralGeneration/ProceduralCollectable.cs`

Each procedurally generated collectable adds a real-time `Light` component for glow. Real-time lights are extremely expensive on mobile (forward rendering per-pixel lights). With many collectables, this will tank performance.

**Recommendation:** Use emissive materials or baked lighting instead.

---

### 15. PerformanceProfiler Creates Texture2D Every Line Draw (MEMORY LEAK)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Debug/PerformanceProfiler.cs`
**Lines:** 311-326

`DrawLine()` creates `new Texture2D(1, 1)` for every line segment, every frame. With 60 FPS history entries, that is ~60 texture allocations per frame. While `Destroy(tex)` is called, this still causes massive GC pressure and frame-rate drops -- ironic for a performance profiler.

**Recommendation:** Create a single static 1x1 texture at initialization and reuse it.

---

### 16. PerformanceProfiler FindObjectsOfType Called Twice Per Update (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Debug/PerformanceProfiler.cs`
**Lines:** 145-155

`FindObjectsOfType<GameObject>()` is called twice in `UpdateMetrics()` -- once for total count and again for iteration. This is one of the most expensive Unity API calls. On mobile with hundreds of objects, this will cause visible hitches every 0.5 seconds.

**Recommendation:** Call it once and cache the result.

---

### 17. SlowMotionPowerUp Time.timeScale Conflict (BUG)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Gameplay/SlowMotionPowerUp.cs`

Modifying `Time.timeScale` globally affects:
- Pause system (`Time.timeScale = 0`)
- Ad system (AdManager saves/restores timeScale around ads)
- Invoke-based timers throughout the codebase
- Other power-up durations (BasePowerUp uses `Invoke(nameof(Deactivate), duration)` which is timeScale-dependent)

Additionally, `OnDeactivate()` starts a coroutine to gradually restore timeScale, but `BasePowerUp.Deactivate()` calls `Destroy(gameObject)` immediately after `OnDeactivate()`, killing the coroutine before it completes.

**Fix:** Use `Time.unscaledDeltaTime` for power-up timing. Add a deactivation delay to BasePowerUp. Consider `DOTween` or manual timers instead of Invoke.

---

### 18. GameOverUI Listener Accumulation (BUG)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/UI/GameOverUI.cs`

Ad result event subscriptions happen inside button click handlers. If the button is clicked multiple times before an ad completes, listeners accumulate, causing the reward to be granted multiple times.

**Fix:** Unsubscribe before subscribing, or use a flag to prevent double-clicks.

---

### 19. ShopUI Listener Accumulation (BUG)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/UI/ShopUI.cs`

Same pattern as GameOverUI. IAP purchase result callbacks are subscribed inside purchase button clicks, potentially accumulating.

**Fix:** Same approach -- unsubscribe before subscribing or guard with flags.

---

### 20. Material Instance Leaks (MEMORY)
**Files:** `Treasure.cs`, `ShieldPowerUp.cs`

Accessing `.material` (not `.sharedMaterial`) on a renderer creates a new material instance. Treasure.cs does this on every landing in `OnLanded()`, and ShieldPowerUp does this in `Update()` every frame. These material instances are never explicitly destroyed.

**Recommendation:** Use MaterialPropertyBlock instead, or destroy material instances when done.

---

### 21. Inconsistent Singleton Patterns (ARCHITECTURE)
Multiple classes implement singletons differently:
- **With DontDestroyOnLoad:** SaveSystem, AudioManager, PerformanceProfiler, DailyRewardSystem, BattlePassManager, PowerUpManager
- **Without DontDestroyOnLoad:** GameManager, TreasureSpawner, RewardedAdController, IAPManager
- **No destroy check:** Some singletons don't destroy the duplicate gameObject

This means scene transitions will break some systems but not others.

**Recommendation:** Standardize on a single base singleton class with consistent behavior.

---

### 22. DateTime.Today for Daily Rewards is Exploitable (SECURITY)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Progression/DailyRewardSystem.cs`

Uses `DateTime.Today` (local device time) for daily reward eligibility. Players can change their device clock to claim unlimited daily rewards.

**Recommendation:** Use server time or `DateTime.UtcNow` with server-side validation.

---

## Medium-Priority Warnings

### 23. Reflection-Based Service Discovery (FRAGILE)
**Files:** DailyChallengeSystem.cs, AchievementSystem.cs, InputManager.cs, GameFeelManager.cs

These files use `System.Reflection` to find and invoke methods on AnalyticsManager, CameraController, and AudioManager to avoid hard dependencies. While the intent is good, reflection is slow, produces no compile-time errors, and will silently fail if method names change.

**Recommendation:** Use interfaces or a lightweight service locator pattern.

---

### 24. Inconsistent Persistence (DailyChallengeSystem, AchievementSystem)
**Files:** DailyChallengeSystem.cs, AchievementSystem.cs

These MobileGameCore systems use `PlayerPrefs` directly for persistence, while SaveSystem exists specifically for this purpose. Data could become inconsistent if SaveSystem resets/migrates data but PlayerPrefs retains old values.

**Recommendation:** Route all persistence through SaveSystem.

---

### 25. SaveSystem Saves on Every Change (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Core/SaveSystem.cs`

Every call to `SetData()`, `SetInt()`, `SetString()`, etc. triggers a full `SaveGame()`, which serializes the entire dictionary, computes a SHA256 hash, Base64 encodes it, and writes to PlayerPrefs. During gameplay with frequent score/currency updates, this is excessive I/O.

**Recommendation:** Implement dirty-flag batching. Mark data as dirty and save periodically (every 5-10 seconds) or on specific events (game over, app pause).

---

### 26. Camera.main Usage in BasePowerUp (PERFORMANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/Gameplay/BasePowerUp.cs`

`PlayActivationSound()` and `PlayExpirationSound()` use `Camera.main` which involves a `FindObjectWithTag` call internally. This is slow and can return null if the main camera is destroyed/disabled.

**Recommendation:** Cache the camera reference or use AudioManager directly.

---

### 27. PowerUpDisplayUI Hardcoded Durations (MAINTENANCE)
**File:** `/mnt/e/projects/LootStackMayhem/Assets/_Game/Scripts/UI/PowerUpDisplayUI.cs`

`GetDurationForType()` hardcodes power-up durations (Magnet: 10s, Shield: 999s, Multiplier: 15s, SlowMotion: 8s). If actual power-up durations change in their respective scripts, the UI will show incorrect timers.

**Recommendation:** Store durations in ScriptableObjects or have power-ups report their own duration.

---

### 28. TransitionManager Uses Legacy UI Text
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Effects/TransitionManager.cs`

Uses `UnityEngine.UI.Text` instead of TextMeshPro. The rest of the project uses TextMeshPro. Legacy Text has inferior rendering quality especially on mobile.

**Recommendation:** Switch to TextMeshProUGUI for consistency.

---

### 29. SerializableDictionary O(n) Lookup
**File:** `/mnt/e/projects/LootStackMayhem/Assets/MobileGameCore/Runtime/Core/SaveSystem.cs`

The custom `SerializableDictionary` uses parallel `List<TKey>` and `List<TValue>` with `List.IndexOf()` for lookups, making every get/set O(n). With many save entries, this degrades.

**Recommendation:** Use a proper Dictionary internally and serialize to lists only during save/load.

---

## Minor Improvements

### 30. Emojis in Code Strings
**Files:** DailyRewardUI.cs (line 186: "fire emoji"), DailyRewardUI.cs (line 358: "party emoji")

While harmless, emoji in string literals can cause encoding issues on some platforms and build pipelines.

### 31. FindObjectOfType Deprecation Warning
**File:** LootStackSceneBuilder.cs (line 115)

`FindObjectOfType` is deprecated in newer Unity versions. Use `FindFirstObjectByType` or `FindAnyObjectByType`.

### 32. Empty Lambda Callbacks in Scene Builder
**File:** LootStackSceneBuilder.cs

Buttons are created with `() => {}` empty callbacks. These should be wired to actual methods or left null.

### 33. AudioSynthesizer Generates 10 Sounds at Startup
**File:** AudioSynthesizer.cs

Generates 10 procedural audio clips on `Awake()`, which could cause a startup stall on low-end devices.

### 34. GameManager Public Fields for Game State
**File:** GameManager.cs

`isPlaying`, `isPaused`, `currentScore`, `multiplier`, `comboCount` are all public fields. Other scripts directly read and modify these, creating tight coupling and making it hard to track state changes.

**Recommendation:** Use properties with events for state changes.

### 35. Multiple Nullable Instance Accesses Without Checks
Throughout the codebase, `SomeManager.Instance.Method()` is called without null-checking Instance first. If a manager hasn't initialized yet or is destroyed, this throws NullReferenceException.

---

## File-by-File Summary

| File | Lines | Rating | Key Issues |
|------|-------|--------|------------|
| GameManager.cs | 274 | 4/10 | Missing Initialize method, API mismatch, no ContinueGame |
| TreasureSpawner.cs | 144 | 5/10 | No object pooling |
| Treasure.cs | 212 | 5/10 | Potential null ref, material leak |
| GameUI.cs | 206 | 7/10 | Clean, good event cleanup |
| MagnetPowerUp.cs | 70 | 1/10 | Uses wrong physics system entirely |
| ShieldPowerUp.cs | 170 | 2/10 | Resets score on save, material leak in Update |
| MultiplierBoostPowerUp.cs | 127 | 5/10 | Direct state mutation, division restore bug |
| SlowMotionPowerUp.cs | 194 | 3/10 | timeScale conflicts, coroutine killed on Destroy |
| BasePowerUp.cs | 156 | 5/10 | Camera.main, Invoke affected by timeScale |
| PowerUpManager.cs | 446 | 6/10 | Active power-ups not deactivated on game start |
| RewardedAdController.cs | 420 | 4/10 | Continue resets score |
| IAPManager.cs | 436 | 3/10 | Method/event name collision, starter pack type |
| GameOverUI.cs | 398 | 5/10 | Listener accumulation |
| ShopUI.cs | 510 | 5/10 | Listener accumulation, polling in Update |
| PowerUpDisplayUI.cs | 407 | 6/10 | Hardcoded durations |
| DailyRewardSystem.cs | 414 | 6/10 | Local time exploitable |
| DailyRewardUI.cs | 508 | 7/10 | Clean UI code |
| BattlePassManager.cs | 668 | 5/10 | Season 2 bug, free purchases |
| BattlePassUI.cs | 596 | 7/10 | Minor null checks missing |
| LootStackSceneBuilder.cs | 406 | 6/10 | Editor utility, mostly fine |
| SaveSystem.cs | 477 | 5/10 | Default salt, O(n) dictionary, saves too often |
| DailyChallengeSystem.cs | 415 | 6/10 | Reflection, PlayerPrefs inconsistency |
| AchievementSystem.cs | 308 | 6/10 | Reflection, PlayerPrefs inconsistency |
| AnalyticsManager.cs | 452 | 7/10 | Good Firebase integration, API mismatch from callers |
| AdManager.cs | 368 | 6/10 | Placeholder IDs, good timeScale restoration |
| ATTManager.cs | 217 | 8/10 | Well-implemented |
| EconomyManager.cs | 406 | 7/10 | Good input validation |
| AudioManager.cs | 413 | 7/10 | Good SFX pooling |
| InputManager.cs | 342 | 6/10 | Reflection for analytics |
| EnhancedCameraController.cs | 475 | 7/10 | Feature-rich, proper cleanup |
| GameFeelManager.cs | 491 | 6/10 | Reflection, good timeScale handling |
| TransitionManager.cs | 496 | 6/10 | Legacy UI Text |
| ProceduralCollectable.cs | 308 | 5/10 | Light components expensive on mobile |
| ProceduralMeshGenerator.cs | 316 | 7/10 | Clean abstract base |
| ProceduralParticles.cs | 536 | 3/10 | Per-particle DrawMesh, Shader.Find |
| AudioSynthesizer.cs | 386 | 6/10 | Startup generation overhead |
| PerformanceProfiler.cs | 426 | 4/10 | Texture2D leak, double FindObjectsOfType |

---

## Priority Action Plan

### Immediate (Block Ship)
1. Fix MagnetPowerUp to use 2D physics
2. Fix shield/continue to not reset score (add ContinueGame method)
3. Fix IAPManager method/event name collision
4. Fix GameManager-to-AnalyticsManager API mismatches
5. Remove or fix SaveSystem.Initialize() call
6. Change SaveSystem hash salt
7. Replace placeholder ad game IDs
8. Wire BattlePass/TierSkip purchases to IAPManager

### Before Beta
9. Implement object pooling for treasures
10. Fix SlowMotionPowerUp timeScale conflicts
11. Fix listener accumulation in GameOverUI and ShopUI
12. Fix material instance leaks in Treasure and ShieldPowerUp
13. Fix PerformanceProfiler texture leak and double FindObjectsOfType
14. Fix BattlePassManager Season 2 initialization bug
15. Add Shader to Always Included Shaders list

### Before Launch
16. Implement save batching (dirty flag)
17. Standardize singleton pattern
18. Replace reflection with interfaces/service locator
19. Route all persistence through SaveSystem
20. Cache Camera.main references
21. Replace ProceduralParticles with Unity ParticleSystem
22. Remove real-time Light from ProceduralCollectable

---

## Architecture Strengths

- Well-organized namespace hierarchy (`LootStackMayhem.Gameplay`, `.Monetization`, `.UI`, `.Progression`)
- Event-driven communication between systems (OnGameStarted, OnGameOver, etc.)
- Comprehensive monetization feature set (ads, IAP, shop, battle pass, daily rewards, power-ups)
- Good conditional compilation usage for platform-specific code (iOS ATT, Unity Purchasing)
- MobileGameCore framework is a good reusable foundation concept
- Proper event cleanup in OnDestroy methods (mostly)
- Test mode controller for editor debugging
- ATTManager implementation is production-quality

## Architecture Weaknesses

- Systems built in isolation without integration testing
- Tight coupling through public fields on GameManager
- Inconsistent persistence strategy (SaveSystem vs PlayerPrefs)
- Heavy reliance on reflection for loose coupling (fragile at runtime)
- No dependency injection or service locator (everything via singletons)
- Multiple Time.timeScale consumers with no coordination layer
- No unit tests or automated integration tests

---

*Review completed: 37/37 files analyzed. All findings verified against source code.*
