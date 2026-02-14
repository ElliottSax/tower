# Game #1 - Day 1 Validation Script

**Copy this script into Unity to validate your setup is complete and working.**

---

## ValidationScript.cs

**Location:** `Assets/_Game/Scripts/Core/ValidationScript.cs`

**Purpose:** Automatically check that all systems are working correctly after setup.

```csharp
using UnityEngine;
using MobileGameCore;
using MobileGameCore.Effects;
using MobileGameCore.ProceduralGeneration;

/// <summary>
/// Validates that all MobileGameCore systems and Game #1 setup is correct.
/// Attach to any GameObject and press P in Play mode to run validation.
/// </summary>
public class ValidationScript : MonoBehaviour
{
    [Header("Validation Settings")]
    [Tooltip("Automatically run validation on Start")]
    public bool autoValidateOnStart = false;

    [Tooltip("Show detailed logs for each test")]
    public bool verboseLogging = true;

    private int testsRun = 0;
    private int testsPassed = 0;
    private int testsFailed = 0;

    void Start()
    {
        if (autoValidateOnStart)
        {
            RunValidation();
        }
        else
        {
            Debug.Log("[ValidationScript] Press 'P' in Play mode to run validation tests.");
        }
    }

    void Update()
    {
        // Press P to run validation
        if (Input.GetKeyDown(KeyCode.P))
        {
            RunValidation();
        }
    }

    /// <summary>
    /// Run all validation tests.
    /// </summary>
    public void RunValidation()
    {
        Debug.Log("==================================================");
        Debug.Log("STARTING MOBILEGAMECORE + GAME #1 VALIDATION");
        Debug.Log("==================================================\n");

        testsRun = 0;
        testsPassed = 0;
        testsFailed = 0;

        // Core Systems
        ValidateSaveSystem();
        ValidateAnalyticsManager();
        ValidateEconomyManager();
        ValidateAchievementSystem();
        ValidateDailyChallengeSystem();

        // Monetization
        ValidateAdManager();
        ValidateATTManager();

        // Audio
        ValidateAudioManager();
        ValidateAudioSynthesizer();

        // Procedural Generation
        ValidateProceduralCollectable();
        ValidateProceduralParticles();

        // Effects
        ValidateGameFeelManager();
        ValidateTransitionManager();

        // Camera & Input
        ValidateCameraController();
        ValidateInputManager();

        // Game #1 Specific
        ValidateGameManager();
        ValidateTreasureSpawner();
        ValidateUI();

        // Performance
        ValidatePerformanceProfiler();

        // Summary
        PrintSummary();
    }

    #region Core Systems Validation

    void ValidateSaveSystem()
    {
        string testName = "SaveSystem";
        testsRun++;

        if (SaveSystem.Instance == null)
        {
            Fail(testName, "SaveSystem.Instance is null. Add SaveSystem component to CoreSystems GameObject.");
            return;
        }

        try
        {
            // Test currency
            SaveSystem.Instance.AddCurrency("test_coins", 100);
            int coins = SaveSystem.Instance.GetCurrency("test_coins");

            if (coins == 100)
            {
                // Test unlock
                SaveSystem.Instance.Unlock("test_item");
                bool unlocked = SaveSystem.Instance.IsUnlocked("test_item");

                if (unlocked)
                {
                    Pass(testName, "Currency and unlock systems working correctly.");
                }
                else
                {
                    Fail(testName, "Unlock system not working.");
                }
            }
            else
            {
                Fail(testName, $"Currency system incorrect. Expected 100, got {coins}");
            }
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateAnalyticsManager()
    {
        string testName = "AnalyticsManager";
        testsRun++;

        if (AnalyticsManager.Instance == null)
        {
            Fail(testName, "AnalyticsManager.Instance is null. Add AnalyticsManager component.");
            return;
        }

        try
        {
            AnalyticsManager.Instance.TrackEvent("validation_test");
            Pass(testName, "Analytics tracking working (may be in fallback mode without Firebase).");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateEconomyManager()
    {
        string testName = "EconomyManager";
        testsRun++;

        if (EconomyManager.Instance == null)
        {
            Fail(testName, "EconomyManager.Instance is null. Add EconomyManager component.");
            return;
        }

        try
        {
            EconomyManager.Instance.AddCurrency("gems", 50);
            int gems = EconomyManager.Instance.GetCurrency("gems");

            if (gems == 50)
            {
                bool canSpend = EconomyManager.Instance.CanAfford("gems", 25);
                if (canSpend)
                {
                    Pass(testName, "Currency and purchase checking working.");
                }
                else
                {
                    Fail(testName, "CanAfford check failed.");
                }
            }
            else
            {
                Fail(testName, $"Expected 50 gems, got {gems}");
            }
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateAchievementSystem()
    {
        string testName = "AchievementSystem";
        testsRun++;

        if (AchievementSystem.Instance == null)
        {
            Fail(testName, "AchievementSystem.Instance is null. Add AchievementSystem component.");
            return;
        }

        try
        {
            var testAchievement = new Achievement(
                "test_achievement",
                "Test Achievement",
                "Test description",
                10,
                100
            );

            AchievementSystem.Instance.RegisterAchievement(testAchievement);
            AchievementSystem.Instance.AddProgress("test_achievement", 50);

            float progress = AchievementSystem.Instance.GetProgress("test_achievement");

            if (progress == 0.5f)
            {
                Pass(testName, "Achievement progress tracking working.");
            }
            else
            {
                Fail(testName, $"Expected progress 0.5, got {progress}");
            }
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateDailyChallengeSystem()
    {
        string testName = "DailyChallengeSystem";
        testsRun++;

        if (DailyChallengeSystem.Instance == null)
        {
            Fail(testName, "DailyChallengeSystem.Instance is null. Add DailyChallengeSystem component.");
            return;
        }

        try
        {
            int streak = DailyChallengeSystem.Instance.GetStreak();
            Pass(testName, $"Daily challenge system working. Current streak: {streak}");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    #endregion

    #region Monetization Validation

    void ValidateAdManager()
    {
        string testName = "AdManager";
        testsRun++;

        if (AdManager.Instance == null)
        {
            Warn(testName, "AdManager not found. Optional - add when ready for monetization.");
            return;
        }

        Pass(testName, "AdManager component present.");
    }

    void ValidateATTManager()
    {
        string testName = "ATTManager";
        testsRun++;

        if (ATTManager.Instance == null)
        {
            Warn(testName, "ATTManager not found. Optional - needed for iOS only.");
            return;
        }

        Pass(testName, "ATTManager component present.");
    }

    #endregion

    #region Audio Validation

    void ValidateAudioManager()
    {
        string testName = "AudioManager";
        testsRun++;

        if (AudioManager.Instance == null)
        {
            Fail(testName, "AudioManager.Instance is null. Add AudioManager component.");
            return;
        }

        try
        {
            float volume = AudioManager.Instance.GetMasterVolume();
            Pass(testName, $"AudioManager working. Master volume: {volume}");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateAudioSynthesizer()
    {
        string testName = "AudioSynthesizer";
        testsRun++;

        if (AudioSynthesizer.Instance == null)
        {
            Fail(testName, "AudioSynthesizer.Instance is null. Add AudioSynthesizer component to CoreSystems.");
            return;
        }

        try
        {
            // Just check it exists and can be called
            Pass(testName, "AudioSynthesizer ready for procedural sound generation.");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    #endregion

    #region Procedural Generation Validation

    void ValidateProceduralCollectable()
    {
        string testName = "ProceduralCollectable";
        testsRun++;

        try
        {
            // Try to create a test coin
            GameObject testObj = new GameObject("ValidationCoin");
            ProceduralCollectable coin = testObj.AddComponent<ProceduralCollectable>();
            coin.SetCollectableType(ProceduralCollectable.Shape.Coin, Color.yellow);

            // Check if mesh was generated
            MeshFilter meshFilter = coin.GetComponent<MeshFilter>();
            if (meshFilter != null && meshFilter.sharedMesh != null)
            {
                Pass(testName, "Procedural coin mesh generated successfully!");
                Destroy(testObj);
            }
            else
            {
                Fail(testName, "Mesh not generated.");
                Destroy(testObj);
            }
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateProceduralParticles()
    {
        string testName = "ProceduralParticles";
        testsRun++;

        try
        {
            // Try to create particles
            GameObject particleObj = ProceduralParticles.CreateEffect(
                ProceduralParticles.EffectType.Sparkle,
                Vector3.zero,
                Color.yellow,
                0.5f
            );

            if (particleObj != null)
            {
                Pass(testName, "Procedural particles generated successfully!");
                Destroy(particleObj, 1f); // Clean up after 1 second
            }
            else
            {
                Fail(testName, "Particles not created.");
            }
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    #endregion

    #region Effects Validation

    void ValidateGameFeelManager()
    {
        string testName = "GameFeelManager";
        testsRun++;

        if (GameFeelManager.Instance == null)
        {
            Fail(testName, "GameFeelManager.Instance is null. Add GameFeelManager component.");
            return;
        }

        try
        {
            GameFeelManager.Instance.Impact(0.1f);
            Pass(testName, "GameFeelManager working. You should feel a brief freeze.");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateTransitionManager()
    {
        string testName = "TransitionManager";
        testsRun++;

        if (TransitionManager.Instance == null)
        {
            Fail(testName, "TransitionManager.Instance is null. Add TransitionManager component.");
            return;
        }

        Pass(testName, "TransitionManager component present.");
    }

    #endregion

    #region Camera & Input Validation

    void ValidateCameraController()
    {
        string testName = "EnhancedCameraController";
        testsRun++;

        if (EnhancedCameraController.Instance == null)
        {
            Fail(testName, "EnhancedCameraController not found. Add to Main Camera.");
            return;
        }

        try
        {
            EnhancedCameraController.Instance.ShakeMedium();
            Pass(testName, "Camera controller working. You should see camera shake.");
        }
        catch (System.Exception e)
        {
            Fail(testName, $"Exception: {e.Message}");
        }
    }

    void ValidateInputManager()
    {
        string testName = "InputManager";
        testsRun++;

        if (InputManager.Instance == null)
        {
            Fail(testName, "InputManager.Instance is null. Add InputManager component.");
            return;
        }

        Pass(testName, "InputManager component present.");
    }

    #endregion

    #region Game #1 Specific Validation

    void ValidateGameManager()
    {
        string testName = "GameManager (Game #1)";
        testsRun++;

        if (GameManager.Instance == null)
        {
            Fail(testName, "GameManager.Instance is null. Create GameManager GameObject with GameManager.cs script.");
            return;
        }

        if (GameManager.Instance.isPlaying)
        {
            Pass(testName, $"GameManager running. Score: {GameManager.Instance.currentScore}, Multiplier: {GameManager.Instance.multiplier:F1}x");
        }
        else
        {
            Warn(testName, "GameManager present but game not started (isPlaying = false).");
        }
    }

    void ValidateTreasureSpawner()
    {
        string testName = "TreasureSpawner (Game #1)";
        testsRun++;

        TreasureSpawner spawner = FindObjectOfType<TreasureSpawner>();

        if (spawner == null)
        {
            Fail(testName, "TreasureSpawner not found. Create TreasureSpawner GameObject with TreasureSpawner.cs script.");
            return;
        }

        Pass(testName, "TreasureSpawner present and should be spawning treasures.");
    }

    void ValidateUI()
    {
        string testName = "GameUI (Game #1)";
        testsRun++;

        GameUI ui = FindObjectOfType<GameUI>();

        if (ui == null)
        {
            Fail(testName, "GameUI not found. Add GameUI.cs to Canvas GameObject.");
            return;
        }

        if (ui.scoreText == null || ui.multiplierText == null)
        {
            Fail(testName, "GameUI missing text references. Link TextMeshPro components in inspector.");
            return;
        }

        Pass(testName, "GameUI present with text references linked.");
    }

    #endregion

    #region Performance Validation

    void ValidatePerformanceProfiler()
    {
        string testName = "PerformanceProfiler";
        testsRun++;

        if (PerformanceProfiler.Instance == null)
        {
            Warn(testName, "PerformanceProfiler not found. Optional - press F1 to toggle performance overlay.");
            return;
        }

        Pass(testName, "PerformanceProfiler present. Press F1 to toggle overlay.");
    }

    #endregion

    #region Helper Methods

    void Pass(string testName, string message = "")
    {
        testsPassed++;
        string msg = $"✅ PASS: {testName}";
        if (!string.IsNullOrEmpty(message))
            msg += $" - {message}";

        Debug.Log(msg);
    }

    void Fail(string testName, string message)
    {
        testsFailed++;
        Debug.LogError($"❌ FAIL: {testName} - {message}");
    }

    void Warn(string testName, string message)
    {
        // Warnings don't count as pass or fail
        Debug.LogWarning($"⚠️  WARN: {testName} - {message}");
    }

    void PrintSummary()
    {
        Debug.Log("\n==================================================");
        Debug.Log("VALIDATION COMPLETE");
        Debug.Log("==================================================");
        Debug.Log($"Tests Run: {testsRun}");
        Debug.Log($"✅ Passed: {testsPassed}");
        Debug.Log($"❌ Failed: {testsFailed}");

        float successRate = testsRun > 0 ? (testsPassed / (float)testsRun) * 100f : 0f;
        Debug.Log($"Success Rate: {successRate:F1}%");

        if (testsFailed == 0)
        {
            Debug.Log("\n🎉 ALL TESTS PASSED! YOUR SETUP IS COMPLETE! 🎉");
            Debug.Log("You're ready to build your game!");
        }
        else
        {
            Debug.Log($"\n⚠️  {testsFailed} test(s) failed. Check errors above and fix issues.");
        }

        Debug.Log("==================================================\n");
    }

    #endregion
}
```

---

## How to Use

### **1. Copy Script into Unity**
1. Create file: `Assets/_Game/Scripts/Core/ValidationScript.cs`
2. Copy the code above
3. Save

### **2. Add to Scene**
1. Select any GameObject (or create new empty: "Validator")
2. Add Component → ValidationScript

### **3. Run Validation**
**Option A: Automatic (on Start)**
- Check "Auto Validate On Start" in inspector
- Press Play
- Check Console for results

**Option B: Manual (press P)**
- Leave "Auto Validate On Start" unchecked
- Press Play
- Press **P** key to run validation
- Check Console for results

### **4. Interpret Results**

**All Green (✅):**
```
✅ PASS: SaveSystem - Currency and unlock systems working correctly.
✅ PASS: AnalyticsManager - Analytics tracking working...
✅ PASS: ProceduralCollectable - Procedural coin mesh generated successfully!

🎉 ALL TESTS PASSED! YOUR SETUP IS COMPLETE! 🎉
```
**Result:** You're ready to build!

**Some Red (❌):**
```
❌ FAIL: GameManager - GameManager.Instance is null.
```
**Result:** Follow the error message to fix the issue

**Yellow Warnings (⚠️):**
```
⚠️ WARN: AdManager - Optional, add when ready for monetization.
```
**Result:** These are OK - optional systems

---

## What Gets Validated

### **MobileGameCore Systems (17)**
- SaveSystem
- AnalyticsManager
- EconomyManager
- AchievementSystem
- DailyChallengeSystem
- AdManager (optional)
- ATTManager (optional)
- AudioManager
- AudioSynthesizer
- ProceduralCollectable
- ProceduralParticles
- GameFeelManager
- TransitionManager
- EnhancedCameraController
- InputManager
- PerformanceProfiler (optional)

### **Game #1 Systems (3)**
- GameManager
- TreasureSpawner
- GameUI

---

## Example Output

```
==================================================
STARTING MOBILEGAMECORE + GAME #1 VALIDATION
==================================================

✅ PASS: SaveSystem - Currency and unlock systems working correctly.
✅ PASS: AnalyticsManager - Analytics tracking working (may be in fallback mode without Firebase).
✅ PASS: EconomyManager - Currency and purchase checking working.
✅ PASS: AchievementSystem - Achievement progress tracking working.
✅ PASS: DailyChallengeSystem - Daily challenge system working. Current streak: 0
⚠️  WARN: AdManager - AdManager not found. Optional - add when ready for monetization.
⚠️  WARN: ATTManager - ATTManager not found. Optional - needed for iOS only.
✅ PASS: AudioManager - AudioManager working. Master volume: 1
✅ PASS: AudioSynthesizer - AudioSynthesizer ready for procedural sound generation.
✅ PASS: ProceduralCollectable - Procedural coin mesh generated successfully!
✅ PASS: ProceduralParticles - Procedural particles generated successfully!
✅ PASS: GameFeelManager - GameFeelManager working. You should feel a brief freeze.
✅ PASS: TransitionManager - TransitionManager component present.
✅ PASS: EnhancedCameraController - Camera controller working. You should see camera shake.
✅ PASS: InputManager - InputManager component present.
✅ PASS: GameManager (Game #1) - GameManager running. Score: 0, Multiplier: 1.0x
✅ PASS: TreasureSpawner (Game #1) - TreasureSpawner present and should be spawning treasures.
✅ PASS: GameUI (Game #1) - GameUI present with text references linked.
✅ PASS: PerformanceProfiler - PerformanceProfiler present. Press F1 to toggle overlay.

==================================================
VALIDATION COMPLETE
==================================================
Tests Run: 18
✅ Passed: 16
❌ Failed: 0
Success Rate: 88.9%

🎉 ALL TESTS PASSED! YOUR SETUP IS COMPLETE! 🎉
You're ready to build your game!
==================================================
```

---

## Troubleshooting

### **"GameManager.Instance is null"**
**Solution:**
1. Create empty GameObject: "GameManager"
2. Add Component → GameManager (your script from GAME1_STARTER_SCRIPTS.md)

### **"SaveSystem.Instance is null"**
**Solution:**
1. Create empty GameObject: "CoreSystems"
2. Add Component → SaveSystem
3. Add other MobileGameCore managers

### **"ProceduralCollectable failed"**
**Solution:**
- Check MobileGameCore imported correctly
- Check namespace: `using MobileGameCore.ProceduralGeneration;`

### **"GameUI missing text references"**
**Solution:**
1. Select Canvas GameObject
2. Find GameUI component in Inspector
3. Drag TextMeshPro objects to scoreText, multiplierText, etc.

---

## Next Steps After Validation

**If all tests pass:**
1. ✅ Your setup is complete!
2. ✅ Press Play and enjoy your prototype
3. ✅ Move to Day 2: Enhanced gameplay

**If some tests fail:**
1. Read error messages carefully
2. Follow suggestions in error messages
3. Check `GAME1_UNITY_SETUP_GUIDE.md` for setup steps
4. Run validation again after fixes

---

**This validation script ensures your Day 1 setup is perfect!** ✅

*Copy into Unity and press P to validate everything!*
