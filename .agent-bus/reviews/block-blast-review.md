# Block Blast Evolved -- Comprehensive Code Review

**Reviewer**: Senior Unity/C# Code Reviewer (Claude Opus 4.6)
**Date**: 2026-02-11
**Project**: `/mnt/e/projects/block-blast-evolved/`
**Files Reviewed**: 17 C# files (~4,800 LOC)
**Overall Quality Rating**: 5/10

---

## Executive Summary

Block Blast Evolved is an early-stage mobile puzzle game with RPG hero mechanics and a monetization layer. The codebase has a reasonable architectural skeleton -- singleton managers, event-driven communication, and ScriptableObject-based data -- but suffers from **significant bugs that would prevent compilation**, **several incomplete/stub implementations marked as production-ready**, **client-side-only purchase security**, and **numerous Unity best practice violations**. The code reads like a first-draft scaffold rather than production-ready software.

---

## CRITICAL ISSUES (Must Fix Before Any Build)

### C-1: Duplicate `BlockType` Enum -- COMPILATION ERROR

**Files**:
- `/mnt/e/projects/block-blast-evolved/Scripts/GridSystem.cs` (lines 548-560): Defines `BlockBlastEvolved.BlockType` with values `None, Single, Line2, Line3, Line4, Line5, LShape, TShape, Square, ZShape`
- `/mnt/e/projects/block-blast-evolved/Scripts/UI/GameOverController.cs` (lines 379-384): Defines `BlockBlastEvolved.UI.BlockType` with values `None, Standard, Special`

**Impact**: While technically in different namespaces (`BlockBlastEvolved` vs `BlockBlastEvolved.UI`), `GameOverController.cs` also references `GridSystem.Instance.GetCell()` and sets `cell.blockType = BlockType.None` (line 307), which uses the local `UI.BlockType` enum rather than the `BlockBlastEvolved.BlockType` the GridCell expects. This will either fail to compile or silently assign the wrong enum type. The `ClearSomeBlocks()` method in GameOverController directly manipulates GridCell data using the wrong enum.

**Severity**: CRITICAL -- Build will fail or produce incorrect behavior.

---

### C-2: `ScoreManager.GetHighScore()` Method Does Not Exist

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/GameOverController.cs` (line 142)

```csharp
int highScore = scoreManager.GetHighScore();
```

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/ScoreManager.cs`

The `ScoreManager` class has no `GetHighScore()` method. It only has `GetScore()`, `AddScore()`, `AddLineBonus()`, `ActivateMultiplier()`, and `ResetScore()`. This is a compilation error.

**Severity**: CRITICAL -- Build will fail.

---

### C-3: Duplicate Hero Data Architecture -- Redundant Classes

Three separate hero definition systems exist simultaneously:

1. **`Hero` class** in `HeroSystem.cs` (lines 568-610) -- a `[Serializable]` POCO used by HeroSystem at runtime.
2. **`HeroTemplate` ScriptableObject** in `ScriptableObjects/HeroTemplate.cs` -- a full ScriptableObject with `[CreateAssetMenu]`.
3. **`HeroData` ScriptableObject** in `ScriptableObjects/HeroData.cs` -- another full ScriptableObject with a different `[CreateAssetMenu]` path.

All three define the same fields (heroId, heroName, basePower, lineBonus, comboMultiplier, abilityType, etc.) with slightly different defaults and ranges. `HeroSystem` only uses the `Hero` class. `HeroTemplate` and `HeroData` are never referenced by any runtime code.

**Impact**: Confusing for developers, wasted code, risk of using the wrong data source.

**Severity**: CRITICAL (architectural) -- Must be resolved to avoid developer confusion and data inconsistency.

---

### C-4: IAP Purchase Security -- Client-Side Only Reward Granting

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/Monetization/IAPManager.cs`

All purchase rewards are granted entirely client-side:

```csharp
public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
{
    string productId = args.purchasedProduct.definition.id;
    GrantPurchaseReward(productId);  // No server validation
    SavePurchaseState(productId);    // Only PlayerPrefs
    return PurchaseProcessingResult.Complete;
}
```

- No receipt validation against Apple/Google servers.
- No server-side verification of purchase integrity.
- "Remove Ads" state stored in `PlayerPrefs.SetInt("ads_removed", 1)` -- trivially editable on rooted/jailbroken devices.
- Gem balances stored only in local memory with no integrity checks.

**Impact**: Any user with a modded APK or rooted device can grant themselves unlimited gems, remove ads for free, or unlock all heroes. This is a real revenue loss vector for mobile games.

**Severity**: CRITICAL (security) -- Revenue-impacting vulnerability.

---

### C-5: `IAPManager.OnPurchaseFailed` Event Name Collision

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/Monetization/IAPManager.cs`

```csharp
// Line 69: event declaration
public event Action<string> OnPurchaseFailed;

// Line 248: IDetailedStoreListener implementation method
public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)
```

The `OnPurchaseFailed` event and the `OnPurchaseFailed` interface method share the same name. Inside the method body (line 252), `OnPurchaseFailed?.Invoke(product.definition.id)` will call the event, but this name collision is confusing and fragile. The same collision occurs with the overloaded variant on line 261. This may cause unexpected compiler warnings or ambiguity depending on the C# version.

**Severity**: CRITICAL -- Potential compilation ambiguity, confusing code.

---

## WARNINGS (Significant Issues)

### W-1: Memory Leak -- Material Instantiation in Update Loop

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/BlockPlacer.cs`

```csharp
// Line 265 (CreatePreviewObjects):
Material previewMat = new Material(Shader.Find("Standard"));
previewMat.SetFloat("_Mode", 3);
previewMat.color = new Color(1, 1, 1, 0.3f);
renderer.material = previewMat;

// Line 308 (UpdatePreviewVisuals, called every frame during drag):
renderer.material.color = color;  // Creates implicit material copy
```

- `new Material(...)` creates an unmanaged material that must be explicitly destroyed.
- `renderer.material` (not `.sharedMaterial`) creates an implicit copy every time it is accessed.
- Preview objects are created and destroyed during drag operations, but the materials are never explicitly destroyed.
- Over many drag operations, orphaned materials will accumulate in memory.

**Impact**: Memory leak that worsens with gameplay duration. Particularly bad on mobile devices with limited memory.

---

### W-2: `Shader.Find("Standard")` Will Fail in Builds

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/BlockPlacer.cs` (line 265)

```csharp
Material previewMat = new Material(Shader.Find("Standard"));
```

`Shader.Find()` only works at runtime if the shader is included in the build. The "Standard" shader is only included if at least one material in the project references it. In a build stripped of unused shaders, this will return `null`, causing a `NullReferenceException`.

**Impact**: Potential crash in production builds.

---

### W-3: `renderer.material = emptyMaterial` Creates Material Copies

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/GridSystem.cs` (lines 140, 286, 293, 297)

Every call to `renderer.material = someSharedMaterial` creates a new material instance. For an 8x8 grid (64 cells), this means 64 material instances created at initialization, plus additional copies every time cells are updated. These copies are never cleaned up.

**Impact**: Significant material memory overhead, especially on mobile.

---

### W-4: `FindObjectOfType<>()` Called in Gameplay Code

**Files**:
- `BlockPlacer.cs` line 192: `FindObjectOfType<ScoreManager>()`
- `HeroSystem.cs` lines 199, 402, 518, 539: `FindObjectOfType<EconomyManager>()`, `FindObjectOfType<ScoreManager>()`, `FindObjectOfType<SaveSystem>()`

`FindObjectOfType<T>()` is an O(n) search through all GameObjects. It should never be called during gameplay (per-frame or per-action). All of these managers have `Instance` singletons that should be used instead.

**Impact**: Performance degradation, inconsistency (some code uses `Instance`, some uses `FindObjectOfType` for the same manager).

---

### W-5: Incomplete Ability Implementations

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/HeroSystem.cs`

Several hero abilities are stubs that only log but do not actually perform their action:

- `ClearRandomRow()` (line 377-384): Picks a random row but never actually clears it. Only logs.
- `ClearRandomColumn()` (line 389-395): Same -- picks a column, logs, does nothing.
- `ActivateDoublePoints()` (line 400-408): Finds ScoreManager but the activation line is commented out.
- `SpawnExtraBlock()` (line 413-417): Only logs.
- `ShuffleGrid()` (line 422-426): Only logs.
- `ClearRandomCells()` (line 350-369): Clears cell data but does NOT update visuals (comment says "Update visual would go here").

**Impact**: Hero abilities are non-functional. Players using abilities will see feedback (camera shake, sounds) but no actual gameplay effect.

---

### W-6: Currency Manipulation Not Validated on Hero Unlock

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/HeroSystem.cs`

The `UnlockHero()` method (line 84) does not check or deduct any currency. It simply adds the heroId to the unlocked list. While `HeroCollectionUI.OnUnlockButtonPressed()` calls `HeroSystem.Instance.UnlockHero()`, it does not deduct currency either. The `ShopUI.PurchaseHero()` method does properly deduct gems, but `HeroCollectionUI` provides a separate unlock path that bypasses payment.

Similarly, `LevelUpHero()` uses `FindObjectOfType<EconomyManager>()` which could return null, causing the level-up to proceed for free (lines 199-211: cost check is skipped if economyManager is null, but the level-up still happens on line 214).

**Impact**: Free hero unlocks through HeroCollectionUI. Free level-ups if EconomyManager is not in scene.

---

### W-7: Grid `IsGridFull()` Uses Arbitrary 10% Threshold

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/GridSystem.cs` (lines 436-454)

```csharp
float emptyPercentage = (float)emptyCount / (gridWidth * gridHeight);
return emptyPercentage < 0.1f;
```

The game considers the grid "full" when fewer than 10% of cells are empty, even though there might be 6 empty cells on an 8x8 grid. This is not how Block Blast games work -- game over should trigger when NO available block shapes can be placed, not based on an arbitrary fill percentage.

**Impact**: Game over triggers incorrectly -- too early (when blocks could still fit) or too late (when blocks cannot fit but >10% cells are empty).

---

### W-8: `Time.timeScale = 1f` Reset on Game Over Flow

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/GameOverController.cs` (lines 271, 322, 337)

The code sets `Time.timeScale = 1f` in `ContinueGame()`, `OnRestartClicked()`, and `OnMainMenuClicked()`. However, nothing in the codebase ever sets `Time.timeScale` to anything other than 1. This suggests a possible design flaw -- if the game is meant to pause during the game over screen, `Time.timeScale = 0` should be set in `ShowGameOver()`, but it is not.

**Impact**: Minor -- code resets a value that was never changed. But if pause behavior is intended, it is broken.

---

### W-9: Placeholder Ad Game IDs in Source Code

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/Monetization/UnityAdsManager.cs` (lines 23-24)

```csharp
public string androidGameId = "YOUR_ANDROID_GAME_ID";
public string iOSGameId = "YOUR_IOS_GAME_ID";
```

These are placeholder strings. If this gets into a build, ads will fail to initialize. While they are serialized fields (can be set in Inspector), having invalid defaults is risky.

**Impact**: Ads will not work in any build unless Inspector values are manually overridden.

---

### W-10: Excessive Singleton Pattern Usage

All 10 manager classes use the singleton pattern:
- GridSystem, BlockPlacer, BlockBlastHUD, HeroSystem, AudioManager, ScoreManager, EconomyManager, SaveSystem, CameraController, ParticleEffectManager, IAPManager, UnityAdsManager

This is a common pattern in Unity mobile games, but it creates tight coupling, makes testing difficult, and creates hidden initialization order dependencies. Some singletons use `DontDestroyOnLoad` (HeroSystem, AudioManager, EconomyManager, SaveSystem, IAPManager, UnityAdsManager) while others do not (GridSystem, BlockPlacer, BlockBlastHUD, ScoreManager, CameraController, ParticleEffectManager), creating inconsistency about what persists across scenes.

**Impact**: Potential null reference exceptions when scene-scoped singletons are accessed from DontDestroyOnLoad objects after a scene transition.

---

### W-11: `ShopUI.Update()` Calls `UpdateCurrencyDisplay()` Every Frame

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/ShopUI.cs` (lines 115-119)

```csharp
void Update()
{
    UpdateCurrencyDisplay();
}
```

This updates two TextMeshPro elements every single frame. Currency only changes when the player makes a purchase or earns coins/gems -- event-driven updates would be far more efficient.

**Impact**: Unnecessary per-frame string allocation and UI updates.

---

### W-12: `BlockBlastHUD.Update()` Checks Cooldowns Every Frame

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/BlockBlastHUD.cs` (lines 121-126)

```csharp
void Update()
{
    UpdateAbilityCooldown();
}
```

The `UpdateAbilityCooldown()` method accesses `HeroSystem.Instance`, checks the active hero, queries cooldown state, and updates multiple UI elements every frame. This is wasteful when the ability is not on cooldown (which is most of the time).

**Impact**: Unnecessary CPU work every frame.

---

## MINOR IMPROVEMENTS

### M-1: Missing Null Check in `BlockPlacer.GetMouseWorldPosition()`

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/BlockPlacer.cs` (line 71)

```csharp
mainCamera = Camera.main;
```

`Camera.main` can return null. The null check on line 341 is good, but there is no warning logged when the camera is null. Also, `Camera.main` uses `FindObjectWithTag` internally -- caching is correct here but should verify it stays valid.

---

### M-2: `BlockPreviewSlot.SetBlock()` is Incomplete

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/BlockBlastHUD.cs` (lines 609-618)

```csharp
public void SetBlock(BlockShape block)
{
    if (container != null)
    {
        container.SetActive(true);
    }
    // TODO: Create block shape visual from block.occupiedCells
}
```

The block preview in the HUD will show empty containers with no visual representation of upcoming blocks.

---

### M-3: Unicode Emoji in Debug.Log Statements

Throughout the codebase, debug log messages use emoji characters (e.g., lines in GridSystem, BlockPlacer, HeroSystem). While harmless, these can cause encoding issues in some log viewers and build pipelines. Examples: `Debug.Log($"...(checkmark) Block placed...")`, `Debug.Log($"...(target) Cleared...")`.

---

### M-4: `HeroSystem.UpdateCooldowns()` Allocates a List Every Frame

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/HeroSystem.cs` (lines 467-483)

```csharp
void UpdateCooldowns()
{
    List<string> keys = new List<string>(abilityCooldowns.Keys); // Allocation every frame
    foreach (string abilityId in keys) { ... }
}
```

This creates a new `List<string>` every frame to iterate the dictionary. A cached list or using `Dictionary.Enumerator` would avoid this GC allocation.

---

### M-5: `HeroSystem.GetHeroById()` Uses Linear Search

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/HeroSystem.cs` (lines 140-149)

Iterates the entire `allHeroes` array to find a hero by ID. Should use a `Dictionary<string, Hero>` for O(1) lookup. Called frequently during save/load, equip, level up, and UI population.

---

### M-6: `HeroCollectionUI.GetUnlockedHeroes()` Called Repeatedly

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/HeroCollectionUI.cs`

`HeroSystem.Instance.GetUnlockedHeroes()` creates a new `List<Hero>` every time it is called (see HeroSystem.cs lines 155-169). It is called for every hero card in `SetupHeroCard()` (line 247), and again in `ShowHeroDetail()` (line 354). For N heroes, this creates N+1 list allocations just to populate the UI.

---

### M-7: `GridCell` is a Class, Should Be a Struct

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/GridSystem.cs` (lines 534-543)

`GridCell` is a reference type (class) containing only value-type fields (int, bool, int) plus one reference (GameObject). For a grid of 64-100 cells, using a class means 64-100 heap allocations. A struct with the GameObject tracked separately would be more cache-friendly and reduce GC pressure.

Note: `GetCell()` returns null for invalid positions (line 208), which would need to change if GridCell were a struct.

---

### M-8: No Input Abstraction for Mobile

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/BlockPlacer.cs`

The block placement uses `Input.GetMouseButtonUp(0)` and `Input.mousePosition`. This is the legacy Input Manager and only works with mouse input. For a mobile game, touch input via `Input.GetTouch()` or Unity's new Input System should be used.

---

### M-9: `OnDrawGizmos` Accesses `GetCellWorldPosition` at Grid Boundaries

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/GridSystem.cs` (lines 505-525)

The gizmo drawing iterates `x <= gridWidth` and `y <= gridHeight` (inclusive), calling `GetCellWorldPosition(gridWidth, ...)` which is one beyond the valid grid range. While not a crash (it just computes a position), it is semantically incorrect.

---

### M-10: `HeroData.OnValidate()` Auto-Modifies `unlockCost`

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/ScriptableObjects/HeroData.cs` (lines 141-158)

The `OnValidate` method automatically sets `unlockCost` based on rarity whenever it is 0 and `starterHero` is false. This means a designer cannot intentionally set a non-starter hero to cost 0 gems without the value being overwritten on every Inspector change.

---

### M-11: No `OnDisable` Cleanup for Event Subscriptions

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/UI/BlockBlastHUD.cs` (line 115)

```csharp
abilityButton.onClick.AddListener(OnAbilityButtonPressed);
```

Button listeners are added in `Start()` but never removed. While Unity handles this for destroyed GameObjects, if the HUD is disabled and re-enabled, listeners could be duplicated.

Similarly in `HeroCollectionUI.cs`, listeners are added in `SetupButtons()` but never removed.

---

### M-12: PlayerPrefs for Save Data is Insecure and Limited

**File**: `/mnt/e/projects/block-blast-evolved/Scripts/SaveSystem.cs`

PlayerPrefs stores data in plain text (Windows registry on Windows, plist on macOS/iOS, XML on Android). It is not suitable for:
- Currency balances (easily editable)
- Purchase state (trivially spoofable)
- Hero progression (no integrity checking)

For a game with real-money transactions, save data should use encrypted local storage or server-side persistence.

---

## SUMMARY TABLE

| Category | Count | Details |
|----------|-------|---------|
| Critical Issues | 5 | Compilation errors (C-1, C-2), duplicate architecture (C-3), IAP security (C-4), name collision (C-5) |
| Warnings | 12 | Memory leaks (W-1, W-3), shader crash (W-2), FindObjectOfType (W-4), stub abilities (W-5), free unlocks (W-6), wrong game-over logic (W-7), frame waste (W-11, W-12), placeholder IDs (W-9), singleton inconsistency (W-10), timeScale (W-8) |
| Minor Issues | 12 | Allocations (M-4, M-6), linear search (M-5), struct vs class (M-7), input system (M-8), gizmo bounds (M-9), auto-modify (M-10), listener cleanup (M-11), PlayerPrefs security (M-12), null check (M-1), stub UI (M-2), emoji logs (M-3) |
| **Total** | **29** | |

---

## RATING BREAKDOWN

| Dimension | Score (1-10) | Notes |
|-----------|-------------|-------|
| Correctness | 3/10 | Compilation errors, duplicate enums, missing methods, stub abilities |
| Security | 2/10 | Client-side purchase validation, PlayerPrefs for currency, no integrity checks |
| Performance | 5/10 | Material leaks, FindObjectOfType in gameplay, per-frame allocations |
| Architecture | 5/10 | Good separation of concerns, but triple-redundant hero data, singleton overuse |
| Code Style | 7/10 | Consistent naming, XML docs, proper regions, good use of attributes |
| Completeness | 4/10 | Many stub implementations, multiple TODO comments, missing core gameplay |
| Maintainability | 5/10 | Good documentation but confusing redundant classes, inconsistent patterns |

**Overall: 5/10** -- The codebase has a solid structural foundation and good documentation habits, but critical bugs prevent compilation, security is absent for monetization, and many systems are stubs logged as "production-ready" in CLAUDE.md. Significant work is needed before this can be considered shippable.

---

## TOP 5 PRIORITY FIXES

1. **Fix compilation errors**: Remove duplicate `BlockType` enum in GameOverController.cs, add `GetHighScore()` to ScoreManager.
2. **Consolidate hero data**: Pick ONE of Hero/HeroTemplate/HeroData and remove the other two.
3. **Add server-side receipt validation** for IAP purchases, or at minimum encrypt PlayerPrefs data.
4. **Fix material memory leaks**: Use `sharedMaterial` for reads, explicitly destroy created materials, replace `Shader.Find()`.
5. **Implement hero abilities**: The 5 stub abilities need actual gameplay logic, not just Debug.Log.
