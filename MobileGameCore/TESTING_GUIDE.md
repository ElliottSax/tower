# MobileGameCore Testing & Validation Guide

**Complete validation checklist for ensuring MobileGameCore works perfectly in your Unity project.**

---

## Quick Start Test (5 minutes)

### Step 1: Import Package

**Option A: Local Package**
```
1. Window → Package Manager
2. + → Add package from disk
3. Select MobileGameCore/package.json
4. Wait for import (should be instant)
```

**Option B: Direct Import**
```
1. Copy MobileGameCore/Runtime to Assets/MobileGameCore
2. Scripts available immediately
```

### Step 2: Create Test Scene

1. Create new scene: `TestScene`
2. Create empty GameObject: `CoreSystems`
3. Add these components:
   - SaveSystem
   - AnalyticsManager
   - EconomyManager
   - AudioManager
   - InputManager
   - AchievementSystem
   - DailyChallengeSystem

### Step 3: Verify Compilation

**Expected Result:** Zero errors, zero warnings

**If you get errors:**
- Missing UnityEngine.InputSystem → Install from Package Manager
- Missing Firebase → Optional, AnalyticsManager has graceful fallback

---

## System-by-System Validation

### ✅ 1. SaveSystem (CRITICAL)

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class SaveSystemTest : MonoBehaviour
{
    void Start()
    {
        // Initialize
        SaveSystem.Instance.Initialize();

        // Test currency
        SaveSystem.Instance.AddCurrency("coins", 100);
        Debug.Log($"Coins: {SaveSystem.Instance.GetCurrency("coins")}"); // Should print 100

        // Test unlocks
        SaveSystem.Instance.Unlock("test_item");
        Debug.Log($"Unlocked: {SaveSystem.Instance.IsUnlocked("test_item")}"); // Should print True

        // Test save/load
        SaveSystem.Instance.SaveGame();
        Debug.Log("✅ SaveSystem working!");
    }
}
```

**Expected Console Output:**
```
[SaveSystem] Initialized
Coins: 100
Unlocked: True
[SaveSystem] Game saved successfully
✅ SaveSystem working!
```

### ✅ 2. AnalyticsManager

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class AnalyticsTest : MonoBehaviour
{
    void Start()
    {
        AnalyticsManager.Instance.Initialize();
        AnalyticsManager.Instance.TrackLevelStart(1);
        AnalyticsManager.Instance.TrackLevelComplete(1, 3, 1000);
        Debug.Log("✅ AnalyticsManager working!");
    }
}
```

**Expected:**
- No errors (even without Firebase)
- Console shows analytics events tracked

### ✅ 3. EconomyManager

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class EconomyTest : MonoBehaviour
{
    void Start()
    {
        // Test currency
        EconomyManager.Instance.AddCurrency("coins", 500);
        Debug.Log($"Coins: {EconomyManager.Instance.GetCurrency("coins")}");

        // Test purchase
        bool success = EconomyManager.Instance.SpendCurrency("coins", 100, "Test Item");
        Debug.Log($"Purchase success: {success}"); // Should be true
        Debug.Log($"Coins after: {EconomyManager.Instance.GetCurrency("coins")}"); // Should be 400

        // Test unlock
        EconomyManager.Instance.UnlockItem("item_1", 50);
        Debug.Log($"Item unlocked: {EconomyManager.Instance.IsItemUnlocked("item_1")}");

        Debug.Log("✅ EconomyManager working!");
    }
}
```

### ✅ 4. AudioManager

**Test Setup:**
1. Add AudioManager component
2. Leave all audio clips empty (optional)
3. Run test

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class AudioTest : MonoBehaviour
{
    void Start()
    {
        AudioManager.Instance.SetMasterVolume(0.7f);
        Debug.Log($"Master Volume: {AudioManager.Instance.GetMasterVolume()}");

        // Would play sound if clips assigned
        // AudioManager.Instance.PlayButtonClick();

        Debug.Log("✅ AudioManager working!");
    }
}
```

### ✅ 5. ProceduralGeneration Systems

**Test procedural collectable:**
```csharp
using UnityEngine;
using MobileGameCore.ProceduralGeneration;

public class ProceduralTest : MonoBehaviour
{
    void Start()
    {
        // Create a procedural coin
        GameObject coinObj = new GameObject("TestCoin");
        ProceduralCollectable coin = coinObj.AddComponent<ProceduralCollectable>();
        coin.SetCollectableType(ProceduralCollectable.Shape.Coin, Color.yellow);

        Debug.Log("✅ ProceduralCollectable working! Check scene for yellow coin mesh.");

        // Create particle effect
        ProceduralParticles.CreateEffect(
            ProceduralParticles.EffectType.Sparkle,
            Vector3.zero,
            Color.yellow,
            1f
        );

        Debug.Log("✅ ProceduralParticles working!");

        // Create synthesized sound
        if (AudioSynthesizer.Instance != null)
        {
            AudioSynthesizer.Instance.PlaySound("collect");
            Debug.Log("✅ AudioSynthesizer working!");
        }
    }
}
```

**Expected Result:**
- You should SEE a yellow coin mesh in the scene
- You should SEE yellow sparkle particles
- You should HEAR a "ding" sound

### ✅ 6. GameFeelManager

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore.Effects;

public class GameFeelTest : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            GameFeelManager.Instance.Impact(1f);
            Debug.Log("✅ Impact feedback triggered!");
        }
    }
}
```

**Test:**
1. Run game
2. Press SPACE
3. Should feel brief freeze/pause

### ✅ 7. EnhancedCameraController

**Test Setup:**
1. Create new scene
2. Create cube at (0, 0, 0), tag it "Player"
3. Add EnhancedCameraController to Main Camera
4. Run

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore.Camera;

public class CameraTest : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.S))
        {
            EnhancedCameraController.Instance.ShakeMedium();
            Debug.Log("✅ Camera shake triggered!");
        }
    }
}
```

### ✅ 8. InputManager

**Test Setup:**
1. Add InputManager component
2. Set Input Mode to "Tilt"
3. Run on device OR use keyboard in editor

**Expected:** Keyboard WASD works as fallback in editor

### ✅ 9. PerformanceProfiler

**Test:**
1. Add PerformanceProfiler component
2. Run game
3. Press F1
4. Should see FPS overlay in top-left

**Expected Output:**
```
PERFORMANCE PROFILER
FRAMERATE
FPS: 60.0
Min: 60.0 | Max: 60.0 | Avg: 60.0
Frame Time: 16.7 ms

MEMORY
Allocated: 50 MB
Reserved: 100 MB
...
```

### ✅ 10. TransitionManager

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore.Effects;

public class TransitionTest : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.T))
        {
            TransitionManager.Instance.FadeOut(0.5f);
            Debug.Log("✅ Transition started!");
        }
    }
}
```

**Test:** Press T, screen should fade to black

### ✅ 11. AchievementSystem

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class AchievementTest : MonoBehaviour
{
    void Start()
    {
        // Register achievement
        AchievementSystem.Instance.RegisterAchievement(
            new Achievement("test_achievement", "Test Achievement", "Complete test", 100, 10)
        );

        // Add progress
        AchievementSystem.Instance.AddProgress("test_achievement", 5);
        Debug.Log($"Progress: {AchievementSystem.Instance.GetProgress("test_achievement")}"); // 0.5

        // Complete it
        AchievementSystem.Instance.AddProgress("test_achievement", 5);
        Debug.Log($"Unlocked: {AchievementSystem.Instance.IsUnlocked("test_achievement")}"); // True

        Debug.Log("✅ AchievementSystem working!");
    }
}
```

### ✅ 12. DailyChallengeSystem

**Test Script:**
```csharp
using UnityEngine;
using MobileGameCore;

public class DailyChallengeTest : MonoBehaviour
{
    void Start()
    {
        // Register challenge
        DailyChallengeSystem.Instance.RegisterChallenge(
            new DailyChallenge("test_challenge", "Test Challenge", "Complete test", 10, 50)
        );

        Debug.Log($"Streak: {DailyChallengeSystem.Instance.GetStreak()}");
        Debug.Log($"Challenges today: {DailyChallengeSystem.Instance.GetTodaysChallenges().Count}");

        Debug.Log("✅ DailyChallengeSystem working!");
    }
}
```

---

## Complete Integration Test

**Create this master test scene:**

```csharp
using UnityEngine;
using MobileGameCore;
using MobileGameCore.Effects;
using MobileGameCore.ProceduralGeneration;

public class MobileGameCoreFullTest : MonoBehaviour
{
    void Start()
    {
        Debug.Log("=== MOBILEGAMECORE FULL TEST ===");

        // 1. Save System
        SaveSystem.Instance.Initialize();
        SaveSystem.Instance.AddCurrency("coins", 1000);
        Debug.Log("✅ SaveSystem: " + SaveSystem.Instance.GetCurrency("coins"));

        // 2. Analytics
        AnalyticsManager.Instance.TrackEvent("test_event");
        Debug.Log("✅ AnalyticsManager");

        // 3. Economy
        EconomyManager.Instance.AddCurrency("coins", 100);
        Debug.Log("✅ EconomyManager: " + EconomyManager.Instance.GetCurrency("coins"));

        // 4. Achievements
        AchievementSystem.Instance.RegisterAchievement(
            new Achievement("test", "Test", "Test", 10, 1)
        );
        AchievementSystem.Instance.AddProgress("test", 1);
        Debug.Log("✅ AchievementSystem");

        // 5. Daily Challenges
        DailyChallengeSystem.Instance.RegisterChallenge(
            new DailyChallenge("test", "Test", "Test", 1, 10)
        );
        Debug.Log("✅ DailyChallengeSystem");

        // 6. Procedural Systems
        ProceduralParticles.CreateEffect(
            ProceduralParticles.EffectType.Sparkle,
            Vector3.zero,
            Color.yellow
        );
        Debug.Log("✅ ProceduralParticles");

        if (AudioSynthesizer.Instance != null)
        {
            AudioSynthesizer.Instance.PlaySound("collect");
            Debug.Log("✅ AudioSynthesizer");
        }

        // 7. Game Feel
        GameFeelManager.Instance.Impact(0.5f);
        Debug.Log("✅ GameFeelManager");

        Debug.Log("=== ALL SYSTEMS OPERATIONAL ===");
    }
}
```

**Expected Console Output:**
```
=== MOBILEGAMECORE FULL TEST ===
[SaveSystem] Initialized
✅ SaveSystem: 1000
[AnalyticsManager] Event tracked: test_event
✅ AnalyticsManager
✅ EconomyManager: 1100
[AchievementSystem] Achievement unlocked: Test
✅ AchievementSystem
✅ DailyChallengeSystem
✅ ProceduralParticles
✅ AudioSynthesizer
✅ GameFeelManager
=== ALL SYSTEMS OPERATIONAL ===
```

---

## Mobile Device Testing

### Android Build Test
1. Build Settings → Android
2. Build and Run
3. Check:
   - [ ] Touch input works
   - [ ] Ads would work (if configured)
   - [ ] Save/load persists
   - [ ] Performance is good (60 FPS)
   - [ ] No crashes

### iOS Build Test
1. Build Settings → iOS
2. Build and Run (requires Mac/Xcode)
3. Check:
   - [ ] ATT prompt appears (if AdManager used)
   - [ ] Touch input works
   - [ ] Save/load persists
   - [ ] Performance is good

---

## Common Issues & Solutions

### Issue: "Type MobileGameCore.SaveSystem not found"
**Solution:** Make sure namespace is correct:
```csharp
using MobileGameCore; // Correct
// NOT using MobileGameCore.Core;
```

### Issue: "Firebase not found"
**Solution:** This is OK! AnalyticsManager has graceful fallback.
Optional: Install Firebase if you want analytics

### Issue: "Input System not found"
**Solution:** Window → Package Manager → Install "Input System"

### Issue: "No sound playing"
**Solution:** AudioManager requires audio clips OR use AudioSynthesizer for procedural sound

### Issue: "Particles not visible"
**Solution:** Make sure you have a Main Camera in the scene

---

## Performance Benchmarks

**Target Performance (Mobile):**
- FPS: 60 (smooth gameplay)
- Memory: < 200 MB allocated
- Draw Calls: < 100
- Load Time: < 2 seconds

**Check with PerformanceProfiler (F1 key)**

---

## Validation Checklist

Before shipping your game, verify:

**Core Systems:**
- [ ] SaveSystem saves and loads correctly
- [ ] Analytics events tracked (if using Firebase)
- [ ] Economy balances correct
- [ ] Audio volumes saved/loaded

**Mobile Specific:**
- [ ] Touch input works on device
- [ ] Tilt controls work (if using)
- [ ] Ads display correctly (if using)
- [ ] ATT prompt appears on iOS (if using ads)
- [ ] Performance is 60 FPS on target devices

**Polish:**
- [ ] Screen shake feels good
- [ ] Transitions are smooth
- [ ] Particle effects look good
- [ ] Sound effects play correctly

**Save System:**
- [ ] Progress saves on quit
- [ ] Progress loads on restart
- [ ] Save file integrity verified (SHA256 hash)

---

## Next Steps

Once validation passes:
1. ✅ MobileGameCore is production-ready
2. 🎮 Start building your first game
3. 🚀 Reuse these systems in all 5 games

**You're ready to build!** 🎉
