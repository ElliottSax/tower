# Treasure Chase - Comprehensive Code Review

**Reviewer**: Senior Unity/C# Code Reviewer (Claude Opus 4.6)
**Date**: 2026-02-11
**Project**: `/mnt/e/projects/treasure-chase/`
**Files Reviewed**: 32 C# files (~6,500+ lines of code)
**Overall Quality Rating**: 5/10

---

## Executive Summary

Treasure Chase is a mobile endless runner with monetization (IAP + ads), daily rewards, a vehicle unlock system, tournaments, and ghost replays. The codebase is functional for a prototype but has **critical security vulnerabilities** in its monetization layer, **multiple production blockers**, widespread use of the deprecated `FindObjectOfType` pattern, and a significant reliance on `PlayerPrefs` for data that should be server-validated. The code demonstrates reasonable Unity patterns (singleton managers, event-driven architecture, object pooling) but lacks the hardening required for a production mobile game -- especially one processing real-money transactions.

---

## CRITICAL Issues (Must Fix Before Any Release)

### C1. SECURITY: BinaryFormatter Deserialization Vulnerability
**File**: `/mnt/e/projects/treasure-chase/Scripts/Endless/GhostRecorder.cs` (lines 336-373)
**Severity**: CRITICAL
**Description**: `BinaryFormatter.Serialize()` and `BinaryFormatter.Deserialize()` are used for ghost run persistence. BinaryFormatter is **officially deprecated by Microsoft** due to remote code execution (RCE) vulnerabilities. A crafted `.dat` file on disk could execute arbitrary code when deserialized.
```csharp
BinaryFormatter formatter = new BinaryFormatter();
FileStream stream = new FileStream(path, FileMode.Open);
PersonalBestGhost = formatter.Deserialize(stream) as GhostRun;  // RCE vector
stream.Close();
```
**Impact**: Remote code execution if an attacker can place a file at `Application.persistentDataPath/personal_best_ghost.dat`.
**Fix**: Replace with `JsonUtility.ToJson`/`JsonUtility.FromJson` (already implemented in the same class but unused for save/load), or use a safe binary serializer.

### C2. SECURITY: IAP Purchase Validation Missing Server-Side Receipt Verification
**File**: `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (lines 225-244)
**Severity**: CRITICAL
**Description**: `ProcessPurchase()` immediately grants rewards with **no server-side receipt validation**. The comment framework for receipt validation exists but is not implemented. This means:
- Jailbroken/rooted devices can inject fake purchase receipts
- Freedom/LuckyPatcher-style tools can bypass payment
- Google Play/Apple will reject apps with unvalidated IAPs in some markets
```csharp
public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
{
    string productId = args.purchasedProduct.definition.id;
    GrantPurchaseReward(productId);  // No receipt validation!
    return PurchaseProcessingResult.Complete;
}
```
**Impact**: Revenue loss through purchase fraud. Every IAP product (Remove Ads, coin packs, starter bundle, battle pass) is exploitable.
**Fix**: Implement server-side receipt validation before calling `GrantPurchaseReward()`. Return `PurchaseProcessingResult.Pending` until server confirms.

### C3. SECURITY: All Monetization State Stored in PlayerPrefs (Trivially Hackable)
**Files**:
- `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (lines 452-463)
- `/mnt/e/projects/treasure-chase/Scripts/Progression/VehicleUnlockSystem.cs` (lines 294-299)
- `/mnt/e/projects/treasure-chase/Scripts/Progression/DailyRewardSystem.cs` (lines 412-419)
**Severity**: CRITICAL
**Description**: All purchase state, vehicle unlocks, streak data, and coin balances are stored in `PlayerPrefs`, which on Android is an **unencrypted XML file** at `/data/data/<package>/shared_prefs/`. Any user with root access or a file editor can:
- Set `ads_removed = 1` to get free ad removal (worth $2.99)
- Set `has_battle_pass = 1` for free battle pass (worth $4.99)
- Edit `UnlockedVehicles` to unlock all vehicles
- Inflate coin balance
- Modify streak data
```csharp
PlayerPrefs.SetInt("ads_removed", 1);  // Trivially editable
PlayerPrefs.SetString("UnlockedVehicles", "0,1,2,3,4,5,6,7");  // Free unlocks
```
**Impact**: Complete bypass of all monetization and progression systems.
**Fix**: Implement server-side state management or at minimum encrypt/sign PlayerPrefs values with a device-unique key. Use obfuscated key names.

### C4. SECURITY: Hardcoded Placeholder Ad Game IDs
**File**: `/mnt/e/projects/treasure-chase/Scripts/Monetization/UnityAdsManager.cs` (lines 23-26)
**Severity**: CRITICAL (Production Blocker)
**Description**: Ad game IDs are still set to placeholder values:
```csharp
public string androidGameId = "YOUR_ANDROID_GAME_ID";
public string iOSGameId = "YOUR_IOS_GAME_ID";
```
**Impact**: Ads will fail to initialize on all platforms. The game will generate zero ad revenue, which is supposedly 70% of total revenue.
**Fix**: Replace with actual Unity Dashboard game IDs before any production build.

### C5. BUG: ContinueRun After Game Over Uses ResumeGame Instead of Resetting State
**File**: `/mnt/e/projects/treasure-chase/Scripts/GameOverController.cs` (lines 214-244)
**Severity**: CRITICAL
**Description**: `ContinueRun()` calls `GameStateManager.Instance.ResumeGame()`, but `ResumeGame()` checks `if (!isPaused || isGameOver) return;` (line 69). Since `isGameOver` is `true`, `ResumeGame()` will silently return without doing anything. The game remains frozen at `Time.timeScale = 0`.
```csharp
void ContinueRun()
{
    // ...
    if (GameStateManager.Instance != null)
    {
        GameStateManager.Instance.ResumeGame();  // BUG: Returns immediately because isGameOver == true
    }
}
```
**Impact**: Players who watch a rewarded ad to continue will be stuck on a frozen screen. This is a direct revenue and UX problem -- users will complain and stop watching ads.
**Fix**: Add a `ContinueAfterGameOver()` method in `GameStateManager` that resets `isGameOver = false`, sets `isGameActive = true`, and restores `Time.timeScale = 1f`.

### C6. BUG: PlayerController Death Disables Component But Game Over Freezes Time
**File**: `/mnt/e/projects/treasure-chase/Scripts/PlayerController.cs` (lines 152-180)
**Severity**: HIGH
**Description**: When the player dies, `Die()` plays a death sound via `PlayOneShot()`, but then `GameStateManager.GameOver()` sets `Time.timeScale = 0f`. Since `PlayOneShot()` is not affected by timeScale by default, this works for audio, but the death particles instantiated at line 169 will freeze mid-animation because particle systems respect timeScale. Also, the player component is disabled at line 179, meaning the `ContinueRun()` flow has no way to re-enable it (no reference is stored).
**Impact**: Death particles freeze. Continue-after-ad flow is broken because the PlayerController remains disabled.

---

## HIGH Severity Issues (Warnings)

### W1. Duplicate Singleton Collision: Two VehicleUnlockSystem Classes
**Files**:
- `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (lines 653-659): Contains a stub `VehicleUnlockSystem` in `TreasureChase.Monetization` namespace
- `/mnt/e/projects/treasure-chase/Scripts/Progression/VehicleUnlockSystem.cs` (lines 15-415): Contains the real `VehicleUnlockSystem` in `TreasureChase.Progression` namespace
**Severity**: HIGH
**Description**: Two classes named `VehicleUnlockSystem` exist in different namespaces. The `IAPManager.GrantStarterBundle()` calls `FindObjectOfType<VehicleUnlockSystem>()` which will find the stub in the Monetization namespace (since it's in the same file), not the real progression system. The stub's `UnlockVehicle()` only prints a debug log and does nothing.
**Impact**: Starter Bundle IAP ($4.99) will never actually unlock the vehicle. Users pay real money and get nothing.
**Fix**: Remove the stub `VehicleUnlockSystem` from `IAPManager.cs` and add `using TreasureChase.Progression;` import.

### W2. Same Issue with BattlePassSystem Stub
**File**: `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (lines 645-651)
**Severity**: HIGH
**Description**: `BattlePassSystem` is a stub class inside the IAPManager file that does nothing when `ActivatePremiumPass()` is called. The Battle Pass costs $4.99 and grants no actual functionality.
**Impact**: Players pay $4.99 for a battle pass that does nothing.

### W3. FileStream Not Disposed on Exception (Resource Leak)
**File**: `/mnt/e/projects/treasure-chase/Scripts/Endless/GhostRecorder.cs` (lines 334-346, 352-374)
**Severity**: HIGH
**Description**: FileStream objects are opened but `stream.Close()` is called outside any `finally` block. If serialization/deserialization throws, the stream leaks.
```csharp
FileStream stream = new FileStream(path, FileMode.Create);
formatter.Serialize(stream, run);  // If this throws, stream leaks
stream.Close();
```
**Fix**: Use `using` statements: `using (var stream = new FileStream(...)) { ... }`

### W4. Event Naming Collision: OnPurchaseFailed
**File**: `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (lines 68, 249-261)
**Severity**: HIGH
**Description**: The class has both an event `public event Action<string> OnPurchaseFailed` (line 68) and a method `public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)` (line 249) with the same name. The method body calls `OnPurchaseFailed?.Invoke(product.definition.id)` which is actually invoking the event, but this naming collision is extremely confusing and could lead to accidental recursion in derived classes.
**Fix**: Rename the event to `PurchaseFailed` or `OnPurchaseFailedEvent`.

### W5. Time.timeScale = 0 Breaks Invoke and Coroutines
**File**: `/mnt/e/projects/treasure-chase/Scripts/GameOverController.cs` (line 280)
**Severity**: HIGH
**Description**: `ShowInterstitialIfNeeded()` uses `Invoke(nameof(ShowInterstitial), 1f)` to delay the interstitial ad by 1 second. However, `GameStateManager.GameOver()` has already set `Time.timeScale = 0f`, so `Invoke` will never fire because `Invoke` uses scaled time.
```csharp
void ShowInterstitialIfNeeded()
{
    // ... Time.timeScale is already 0 here
    Invoke(nameof(ShowInterstitial), 1f);  // Never fires!
}
```
**Impact**: Interstitial ads will never show after game over (70% of expected revenue is at risk).
**Fix**: Use a coroutine with `WaitForSecondsRealtime(1f)` instead of `Invoke`.

### W6. GameOverUI ShowSequence Uses WaitForSeconds Under Frozen TimeScale
**File**: `/mnt/e/projects/treasure-chase/Scripts/UI/GameOverUI.cs` (line 149)
**Severity**: HIGH
**Description**: `ShowSequence()` starts with `yield return new WaitForSeconds(showDelay)`, but during game over `Time.timeScale = 0f`, so this coroutine will hang forever.
**Fix**: Use `WaitForSecondsRealtime(showDelay)`.

### W7. MagnetPowerUp Null Reference Risk on Player
**File**: `/mnt/e/projects/treasure-chase/Scripts/MagnetPowerUp.cs` (line 25)
**Severity**: HIGH
**Description**: `UpdatePowerUp()` accesses `player.transform.position` without null-checking `player`. If the player is destroyed (e.g., during game over cleanup), this will throw a `NullReferenceException` every frame.
**Fix**: Add `if (player == null) return;` at the start of `UpdatePowerUp()`.

### W8. PowerUpBase Visual Hiding is Incomplete
**File**: `/mnt/e/projects/treasure-chase/Scripts/PowerUpBase.cs` (lines 54-68)
**Severity**: MEDIUM-HIGH
**Description**: `ActivatePowerUp()` is public and can be called externally (e.g., `ShieldPowerUp.ActivatePowerUp(5f)` in `GameOverController`). However, when called via `ActivatePowerUp()` (the public overload), it always passes through `OnTriggerEnter` first which sets `player`, but the external call from `GameOverController` line 233 calls `ActivatePowerUp(5f)` without `player` ever being set (no trigger event fires). The `ShieldPowerUp.OnActivate()` will then have `player == null` and the shield effect will silently fail.
**Impact**: The "continue with shield" after watching an ad does not actually apply a shield.

### W9. Obstacle.Start() Uses FindObjectOfType Every Spawn
**File**: `/mnt/e/projects/treasure-chase/Scripts/Obstacles/Obstacle.cs` (line 55)
**Severity**: MEDIUM-HIGH
**Description**: Every obstacle spawned calls `FindObjectOfType<PlayerController>()` in its `Start()` method. In an endless runner with dozens of obstacles, this is called many times per second, causing unnecessary CPU overhead.
**Fix**: Use a static reference or cache the player reference centrally.

---

## MEDIUM Severity Issues

### M1. Excessive FindObjectOfType Usage (Performance)
**Files**: Nearly every file
**Severity**: MEDIUM
**Description**: `FindObjectOfType<T>()` is used pervasively throughout the codebase, sometimes called every frame (e.g., `CoinBehavior.Collect()` calls it twice at lines 58-61). This is an O(n) scene traversal that should be replaced with cached references or singleton access.
**Locations** (partial list):
- `CoinBehavior.Collect()` - called on every coin pickup (lines 58-61)
- `EndlessScoreManager.OnRunEnd()` - line 246
- `EndlessScoreManager.LogRunAnalytics()` - line 342
- `EndlessScoreManager.SaveHighScore()` - line 310
- `DistanceTracker.AwardMilestoneBonus()` - line 133
- `EndlessTutorial.SpawnTutorialTreasure()` and related - lines 380+
- `GameOverController.ContinueRun()` - line 223
- `IAPManager` - multiple occurrences
**Fix**: Create singletons for frequently accessed managers, or cache references in Start().

### M2. CoinBehavior Double FindObjectOfType on Collection
**File**: `/mnt/e/projects/treasure-chase/Scripts/CoinBehavior.cs` (lines 58-61)
**Severity**: MEDIUM
**Description**:
```csharp
else if (FindObjectOfType<SimpleHUDController>() != null)
{
    FindObjectOfType<SimpleHUDController>().AddCoins(coinValue);
}
```
This calls `FindObjectOfType` twice for the same type in the fallback path. The second call could theoretically return null if the object was destroyed between calls, causing a crash.

### M3. MagnetPowerUp Adds SphereCollider But Uses OverlapSphere Redundantly
**File**: `/mnt/e/projects/treasure-chase/Scripts/MagnetPowerUp.cs`
**Severity**: MEDIUM
**Description**: `OnActivate()` adds a `SphereCollider` to the player (line 16-18), and `UpdatePowerUp()` also does `Physics.OverlapSphere()` every frame (line 25). The added collider and the overlap sphere serve the same purpose but are both active simultaneously, causing double-processing.
**Fix**: Choose one approach. Either use the trigger collider for OnTriggerStay/OnTriggerEnter detection, or use OverlapSphere. Not both.

### M4. ShieldPowerUp Creates Material at Runtime with Shader.Find
**File**: `/mnt/e/projects/treasure-chase/Scripts/ShieldPowerUp.cs` (line 36)
**Severity**: MEDIUM
**Description**: `Shader.Find("Standard")` at runtime can fail in built players if the Standard shader is not included in the build (e.g., if no other object uses it). This is a common Unity gotcha.
```csharp
Material mat = new Material(Shader.Find("Standard"));
```
**Impact**: Shield visual may not appear in production builds, leaving the player confused about whether they have protection.
**Fix**: Use a pre-created shader reference assigned in the Inspector, or ensure Standard shader is in "Always Included Shaders" in Graphics Settings.

### M5. Material Leak in ShieldPowerUp and GhostRecorder
**Files**:
- `/mnt/e/projects/treasure-chase/Scripts/ShieldPowerUp.cs` (line 36)
- `/mnt/e/projects/treasure-chase/Scripts/Endless/GhostRecorder.cs` (line 279)
**Severity**: MEDIUM
**Description**: New `Material` objects are created at runtime with `new Material(...)` and `renderer.material` (which creates an instance). These are never explicitly destroyed, causing material instances to leak memory. In an endless runner where shields may be activated many times per session, this accumulates.
**Fix**: Track material instances and destroy them in `OnDeactivate()`.

### M6. Obstacle.Update() Material Swapping Every Frame
**File**: `/mnt/e/projects/treasure-chase/Scripts/Obstacles/Obstacle.cs` (lines 66-81)
**Severity**: MEDIUM
**Description**: The warning material system swaps `objectRenderer.material` every frame when the player is in range. Accessing `.material` (not `.sharedMaterial`) creates a new material instance each time, causing massive material instance leaks.
```csharp
objectRenderer.material = warningMaterial;   // Creates new instance
objectRenderer.material = originalMaterial;  // Creates another
```
**Fix**: Use `MaterialPropertyBlock` for per-instance changes, or use `sharedMaterial` if the original is not shared with other objects.

### M7. GameStateManager Does Not Use DontDestroyOnLoad
**File**: `/mnt/e/projects/treasure-chase/Scripts/GameStateManager.cs`
**Severity**: MEDIUM
**Description**: GameStateManager is a singleton but does NOT use `DontDestroyOnLoad`. On scene reload (RestartGame at line 78-83), the singleton instance is destroyed and recreated. Any references other objects hold to the old instance become stale. This is inconsistent with other singletons (IAPManager, UnityAdsManager, TournamentManager) that DO use DontDestroyOnLoad.
**Impact**: Event listeners registered to the old GameStateManager will stop working after restart.

### M8. Tournament System Is Local-Only (No Server Backend)
**File**: `/mnt/e/projects/treasure-chase/Scripts/Endless/TournamentManager.cs`
**Severity**: MEDIUM
**Description**: The entire tournament/leaderboard system operates only in local memory. Leaderboards are Dictionary instances that reset when the app closes. There is no server communication, no cloud save, no anti-cheat. The tournaments create a false impression of multiplayer competition.
**Impact**: Players will see only their own scores. Tournaments are meaningless. This should either be removed or clearly documented as a placeholder.

### M9. DateTime.Parse Without TryParse for IAP and Daily Rewards
**Files**:
- `/mnt/e/projects/treasure-chase/Scripts/Monetization/IAPManager.cs` (line 479)
- `/mnt/e/projects/treasure-chase/Scripts/Progression/DailyRewardSystem.cs` (line 442)
**Severity**: MEDIUM
**Description**: `DateTime.Parse(purchaseDateStr)` will throw `FormatException` if the stored string is corrupted or in an unexpected locale format. This could crash on app startup.
**Fix**: Use `DateTime.TryParseExact()` with `DateTimeStyles.RoundtripKind` for ISO 8601 strings.

### M10. No Input Handling for Mobile Touch
**File**: `/mnt/e/projects/treasure-chase/Scripts/PlayerController.cs` (lines 74-87)
**Severity**: MEDIUM
**Description**: Player movement only responds to keyboard input (`KeyCode.Space`, `KeyCode.LeftArrow`, `KeyCode.RightArrow`). For a mobile game, there is no touch input, swipe detection, or on-screen controls. The tutorial (`EndlessTutorial`) has basic swipe detection but the actual player controller does not.
**Impact**: The game is unplayable on mobile devices in its current form.

---

## LOW Severity Issues (Minor Improvements)

### L1. Excessive Debug.Log Statements in Production Code
**Files**: All files
**Description**: Nearly every method logs to console. In production builds, `Debug.Log` causes string allocations and is a known performance issue on mobile. Should be wrapped in `#if UNITY_EDITOR` or use conditional compilation.

### L2. Magic Numbers Throughout Codebase
**Files**: Multiple
**Description**: Hardcoded values like `5f` (shield duration in GameOverController:233), `20f` (player offset in Obstacle:84), `100` (tutorial coins in EndlessTutorial:340), `50f` (swipe threshold in EndlessTutorial:513) should be configurable fields.

### L3. DistanceTracker.OnGUI() Creates GUIStyle Every Frame
**File**: `/mnt/e/projects/treasure-chase/Scripts/Endless/DistanceTracker.cs` (lines 275-283)
**Description**: Inside `#if UNITY_EDITOR`, `OnGUI()` creates a `new GUIStyle()` every frame. Should be cached as a field.

### L4. Inconsistent Namespace Usage
**Description**: Some files use namespaces (`TreasureChase.Endless`, `TreasureChase.Obstacles`, `TreasureChase.Monetization`, `TreasureChase.Progression`, `TreasureChase.UI`, `TreasureChase.Data`, `TreasureChase.ScriptableObjects`), while core gameplay files (`PlayerController`, `GameStateManager`, `CameraShake`, `CameraFollow`, `CoinSpawner`, `SimpleHUDController`, `PowerUpBase`, `MagnetPowerUp`, `ShieldPowerUp`, `GameOverController`) are in the default global namespace. This inconsistency causes import confusion and potential naming conflicts.

### L5. CameraShake.TriggerShake() Overwrites Instance Fields
**File**: `/mnt/e/projects/treasure-chase/Scripts/CameraShake.cs` (lines 46-51)
**Description**: The parameterized `TriggerShake(float, float)` permanently overwrites the `shakeDuration` and `shakeMagnitude` inspector values. Subsequent calls to the parameterless `TriggerShake()` will use the last overridden values instead of the original inspector settings.

### L6. Duplicate WorldTheme Definitions
**Files**:
- `/mnt/e/projects/treasure-chase/Scripts/Endless/WorldManager.cs` (lines 312-348): `WorldTheme` ScriptableObject
- `/mnt/e/projects/treasure-chase/Scripts/ScriptableObjects/WorldThemeTemplate.cs`: A separate `WorldThemeTemplate` ScriptableObject
**Description**: Two different ScriptableObjects define world themes with overlapping but different fields. Only `WorldTheme` (from WorldManager) is used in code. `WorldThemeTemplate` appears unused.

### L7. EconomyManager Allows Negative Coin Balance
**File**: `/mnt/e/projects/treasure-chase/Scripts/StubScripts/OtherStubManagers.cs` (lines 55-57)
**Description**: `SpendCoins(int amount)` simply subtracts without checking if balance is sufficient:
```csharp
public void SpendCoins(int amount)
{
    coins -= amount;  // Can go negative
}
```

### L8. VehicleUnlockSystem.UnlockVehicle() Has Redundant Check
**File**: `/mnt/e/projects/treasure-chase/Scripts/Progression/VehicleUnlockSystem.cs` (lines 91-104)
**Description**: The method checks `unlockedVehicles.Contains(index)` twice - at line 91 (returns false) and line 100 (returns true). The second check is unreachable.

### L9. DailyRewardCalendarUI Uses Camera.main (Performance)
**File**: `/mnt/e/projects/treasure-chase/Scripts/UI/DailyRewardCalendarUI.cs` (lines 361, 429)
**Description**: `Camera.main` performs a `FindGameObjectWithTag("MainCamera")` call. Should be cached.

### L10. No Assembly Definition Files
**Description**: The project has no `.asmdef` files. For a 32-file project, this is acceptable, but adding assembly definitions would improve compile times and enforce dependency boundaries between modules.

---

## Architecture Assessment

### Positive Patterns
1. **Event-driven architecture**: Uses UnityEvents for loose coupling between systems (GameStateManager, EndlessScoreManager, DistanceTracker).
2. **Object pooling**: InfiniteTerrainManager properly recycles terrain chunks.
3. **Singleton pattern**: Consistently used across managers (though implementation varies).
4. **ScriptableObject data**: VehicleDataSO and WorldThemeTemplate enable designer-driven workflows.
5. **Good null-checking discipline**: Almost every external reference is null-checked before use.
6. **Proper event cleanup**: OnDestroy methods properly unsubscribe from events in most files.

### Negative Patterns
1. **FindObjectOfType everywhere**: Extremely heavy usage for what should be cached references. At least 40+ occurrences.
2. **PlayerPrefs for sensitive data**: All monetization, progression, and save data uses unencrypted PlayerPrefs.
3. **No dependency injection**: Everything relies on FindObjectOfType or static singletons.
4. **Multiple classes per file**: `OtherStubManagers.cs` contains 9 classes in one file. `WorldManager.cs` contains 3 classes. This hinders maintainability.
5. **No unit tests**: Zero test coverage for scoring, progression, daily rewards, or IAP logic.
6. **Test mode flags left enabled**: Both IAPManager.testMode and UnityAdsManager.testMode default to `true`.

---

## Production Readiness Checklist

| Category | Status | Notes |
|----------|--------|-------|
| IAP Receipt Validation | FAIL | No server-side validation |
| Ad Integration | FAIL | Placeholder game IDs |
| Data Security | FAIL | All data in plaintext PlayerPrefs |
| Mobile Input | FAIL | Keyboard-only controls |
| Memory Management | WARN | Material leaks, FindObjectOfType |
| Error Handling | WARN | DateTime.Parse without TryParse |
| Game Loop | FAIL | Continue-after-ad broken |
| Interstitial Timing | FAIL | Invoke broken at timeScale=0 |
| Test Coverage | FAIL | No tests |
| Debug Code | WARN | Debug.Log everywhere |

---

## Summary of All Issues by Severity

| Severity | Count | Examples |
|----------|-------|---------|
| CRITICAL | 6 | BinaryFormatter RCE, missing IAP validation, hackable PlayerPrefs, placeholder ad IDs, broken continue flow, broken player state |
| HIGH | 9 | Duplicate class names, FileStream leak, event naming collision, timeScale vs Invoke/Coroutine, null reference risks |
| MEDIUM | 10 | FindObjectOfType performance, material leaks, no mobile input, local-only tournaments, DateTime.Parse |
| LOW | 10 | Debug.Log spam, magic numbers, namespace inconsistency, redundant checks |

**Total Issues Found: 35**

---

## Recommended Priority Fix Order

1. **Remove BinaryFormatter** -- Replace with JsonUtility (30 minutes, eliminates RCE)
2. **Fix ContinueRun game over state** -- Add proper resume method (1 hour)
3. **Fix Invoke at timeScale=0** -- Use WaitForSecondsRealtime (15 minutes)
4. **Remove duplicate VehicleUnlockSystem/BattlePassSystem stubs** from IAPManager.cs (15 minutes)
5. **Fix PowerUpBase.ActivatePowerUp() external call path** -- ensure player reference is set (30 minutes)
6. **Add mobile touch input to PlayerController** (2-4 hours)
7. **Replace placeholder ad game IDs** (5 minutes once you have the IDs)
8. **Add server-side IAP receipt validation** (1-2 days)
9. **Encrypt or migrate from PlayerPrefs** for monetization state (1 day)
10. **Replace FindObjectOfType with cached references** (half day)
