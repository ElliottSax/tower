# Treasure Chase - FROZEN PROJECT

**Date Frozen**: 2026-02-11
**Frozen By**: Portfolio Architect
**Grade**: 5/10
**Reason**: Will not compile correctly, critical security vulnerabilities, keyboard-only controls on mobile game

---

## Why This Project Is Frozen

Treasure Chase has **6 critical security vulnerabilities** that directly impact revenue, **broken game-over flow** that prevents monetization, and **keyboard-only controls** despite being a mobile game. The effort to fix (60+ hours) is better invested in a new endless runner using **MobileGameCore SDK**.

### Critical Security Issues (Revenue-Impacting)

1. **BinaryFormatter RCE vulnerability** - `GhostRecorder.cs` uses deprecated `BinaryFormatter.Deserialize()` which allows remote code execution via crafted `.dat` files
2. **Zero IAP receipt validation** - `ProcessPurchase()` grants rewards immediately with no server-side verification (jailbreak exploit)
3. **All monetization in PlayerPrefs** - Purchase state, vehicle unlocks, streak data, coin balances in plaintext XML (trivially hackable)
4. **Placeholder ad game IDs** - `"YOUR_ANDROID_GAME_ID"` = $0 ad revenue (supposed to be 70% of total revenue)
5. **Duplicate VehicleUnlockSystem stub** - Starter Bundle IAP ($4.99) calls stub that does nothing instead of real unlock system
6. **Duplicate BattlePassSystem stub** - Battle Pass IAP ($4.99) calls stub that does nothing

### Critical Gameplay Bugs (Broken Monetization)

7. **Continue-after-ad is broken** - `ContinueRun()` calls `ResumeGame()` which silently returns because `isGameOver == true`, player stuck at frozen screen
8. **Interstitial ads never show** - `Invoke(nameof(ShowInterstitial), 1f)` uses scaled time, but `Time.timeScale = 0` during game over
9. **Shield power-up from ad doesn't work** - External call path bypasses `player` reference setup, shield fails silently
10. **PlayerController disabled on death** - No way to re-enable it during continue flow

### Critical Mobile Issues

11. **No touch input** - `PlayerController` only responds to keyboard (`KeyCode.Space`, arrow keys), unplayable on mobile
12. **Material leaks** - `ShieldPowerUp` and `Obstacle` create new material instances every frame, never cleaned up
13. **`Time.timeScale = 0` breaks coroutines** - `GameOverUI.ShowSequence()` uses `WaitForSeconds` which hangs forever at timeScale=0

---

## What Was Salvaged

**Nothing unique to extract.** Treasure Chase uses the same MobileGameCore SDK already extracted from LootStack.

The game-specific systems have critical bugs:
- VehicleUnlockSystem - Good progression curve design, but no server validation
- DailyRewardSystem - Solid 7-day calendar, but exploitable with device clock changes
- TournamentManager - Local-only, no actual multiplayer
- GhostRecorder - Uses insecure BinaryFormatter

**Lesson learned**: These systems demonstrate good **game design** (progression curves, retention mechanics) but poor **production engineering** (no security, no server validation, no mobile input).

---

## Revenue Model (Theoretical, Unrealized)

### IAP Products (30% of revenue)
- Remove Ads: $2.99
- Coin packs: $0.99-$19.99 (5 tiers)
- Starter Bundle: $4.99 (5000 coins + Phoenix vehicle)
- Battle Pass: $4.99/month

### Ads (70% of revenue)
- Rewarded video: Continue run, 2x coins
- Interstitial: Every 3 game overs, 2-minute cooldown

### Expected Metrics
- ARPDAU: $0.03-$0.05
- IAP Conversion: 2-3%
- Ad Fill Rate: >90%
- Revenue: $3.6K-$30K/year (if working)

**Actual Revenue**: $0 (ads don't initialize, IAP bypasses don't work, no mobile input)

---

## Technical Debt Summary

| Issue | Severity | Fix Effort |
|-------|----------|------------|
| BinaryFormatter RCE | CRITICAL | 2 hours |
| IAP receipt validation | CRITICAL | 8 hours |
| PlayerPrefs security | CRITICAL | 8 hours |
| Placeholder ad IDs | CRITICAL | 1 hour |
| Duplicate VehicleUnlockSystem | CRITICAL | 1 hour |
| Duplicate BattlePassSystem | CRITICAL | 1 hour |
| Continue flow broken | CRITICAL | 4 hours |
| Interstitial Invoke broken | HIGH | 2 hours |
| Shield power-up external call | HIGH | 2 hours |
| PlayerController re-enable | HIGH | 2 hours |
| Mobile touch input | CRITICAL | 8 hours |
| Material leaks | MEDIUM | 4 hours |
| WaitForSeconds at timeScale=0 | HIGH | 2 hours |
| FileStream resource leaks | HIGH | 1 hour |
| FindObjectOfType (40+ calls) | MEDIUM | 8 hours |
| DateTime.Parse without TryParse | MEDIUM | 2 hours |
| **TOTAL** | | **56 hours** |

Add **4-8 hours** for testing on actual mobile devices, which would reveal additional touch input issues.

**Total effort to ship**: 60-64 hours

---

## If Unfreezing This Project

**DO NOT** resume work on Treasure Chase. Instead:

### Option A: Build New Endless Runner with MobileGameCore (Recommended)
1. Use `/mnt/e/projects/MobileGameCore/` as foundation
2. Implement **mobile touch input first** (swipe detection, screen zones)
3. Use **JSON serialization** instead of BinaryFormatter
4. Integrate **server-side IAP validation** from day one
5. Test **Continue flow** before implementing other features
6. Use real Unity Ad/IAP IDs from the start
7. **Time to ship**: 40-60 hours for complete, working game

### Option B: Fix Treasure Chase (Not Recommended)
1. Replace BinaryFormatter with JsonUtility (2 hours)
2. Fix continue flow game state bug (4 hours)
3. Fix interstitial Invoke timing (2 hours)
4. Remove duplicate stub systems (2 hours)
5. Add mobile touch input (8 hours)
6. Add server-side IAP validation (8 hours)
7. Encrypt/migrate PlayerPrefs (8 hours)
8. Fix material leaks (4 hours)
9. Replace FindObjectOfType calls (8 hours)
10. Test on device (8 hours)
11. **Total**: 54-60 hours

**Verdict**: Option A produces a more robust game in the same time. Treasure Chase's bugs indicate insufficient production discipline.

---

## Security Analysis

### BinaryFormatter Vulnerability Details
```csharp
// VULNERABLE CODE (GhostRecorder.cs:336-373)
BinaryFormatter formatter = new BinaryFormatter();
FileStream stream = new FileStream(path, FileMode.Open);
PersonalBestGhost = formatter.Deserialize(stream) as GhostRun;  // RCE vector
```

**Exploit**: Attacker places malicious `.dat` file at `Application.persistentDataPath/personal_best_ghost.dat`. When game loads, arbitrary code executes.

**Fix**:
```csharp
// SECURE ALTERNATIVE
string json = File.ReadAllText(path);
PersonalBestGhost = JsonUtility.FromJson<GhostRun>(json);
```

### IAP Receipt Validation Missing
```csharp
// VULNERABLE CODE (IAPManager.cs:225-244)
public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
{
    string productId = args.purchasedProduct.definition.id;
    GrantPurchaseReward(productId);  // No validation!
    return PurchaseProcessingResult.Complete;
}
```

**Exploit**: Jailbroken device with Freedom/LuckyPatcher injects fake receipts. Player gets premium content without paying.

**Fix**: Implement server-side receipt validation via Google Play Billing API or Apple App Store Server API before granting rewards.

### PlayerPrefs Hack
```xml
<!-- Android: /data/data/com.yourcompany.treasurechase/shared_prefs/com.yourcompany.treasurechase.xml -->
<int name="ads_removed" value="1" />  <!-- Free $2.99 IAP -->
<int name="has_battle_pass" value="1" />  <!-- Free $4.99 IAP -->
<string name="UnlockedVehicles">0,1,2,3,4,5,6,7</string>  <!-- All vehicles unlocked -->
```

**Exploit**: Root access or APK editor modifies XML file directly.

**Fix**: Server-side state management or encrypted PlayerPrefs with device-unique keys.

---

## Broken Continue Flow Analysis

```csharp
// GameOverController.cs:214-244
void ContinueRun()
{
    // ... user watched ad, granted shield ...
    GameStateManager.Instance.ResumeGame();  // BUG!
}

// GameStateManager.cs:66-75
public void ResumeGame()
{
    if (!isPaused || isGameOver)  // isGameOver is TRUE
    {
        return;  // Silently does nothing!
    }
    // Never reaches here...
}
```

**Result**: Player watches ad, shield is granted, but game stays frozen at `Time.timeScale = 0` because `ResumeGame()` returns immediately.

**Impact**: Zero rewarded ad revenue (players won't watch ads that don't work).

---

## Lessons Learned

### What Went Wrong
1. **Security as afterthought** - IAP, saves, ads all implemented without security considerations
2. **Keyboard-first on mobile** - Game designed for desktop testing, never adapted for mobile
3. **Time.timeScale misuse** - Breaks Invoke, WaitForSeconds, and particle systems
4. **FindObjectOfType everywhere** - 40+ occurrences in critical gameplay paths
5. **No device testing** - Would have immediately revealed touch input is missing
6. **Duplicate stub classes** - Created placeholder classes that shadow real implementations
7. **BinaryFormatter despite warnings** - Used deprecated serializer with known RCE vulnerability

### What Went Right
1. **VehicleUnlockSystem progression curve** - Well-balanced (0 → 100 → 250 → 500 → 1K → 2.5K → 5K → 10K coins)
2. **DailyRewardSystem design** - 7-day streak with grace period, rewarded ad recovery
3. **Object pooling** - InfiniteTerrainManager properly recycles chunks
4. **Event-driven architecture** - Good use of UnityEvents for loose coupling
5. **Ghost replay concept** - Innovative feature (despite insecure serialization)

---

## Superseded By

**MobileGameCore SDK** (`/mnt/e/projects/MobileGameCore/`)
- Grade: B
- Production-ready foundation with proper IAP/Ads integration
- No security vulnerabilities in the framework itself

**Recommendation**: If building another endless runner, use MobileGameCore + design Treasure Chase's progression systems (vehicle unlocks, daily rewards) with proper security from day one.

---

## Archive Location

**Status**: Left in place at `/mnt/e/projects/treasure-chase/` with FROZEN markers.
**Reason**: Serves as case study of "good game design + poor production engineering". The progression systems are well-designed but the implementation is insecure.

---

## Estimated Hours Saved

**By freezing**: 60-64 hours of fixes + 20+ hours of security hardening
**By using MobileGameCore for new games**: 20-30 hours of pre-built systems
**Net savings**: 50-60 hours of debugging + security patching avoided

---

## Final Notes

Treasure Chase demonstrates **excellent game design** (vehicle progression, daily rewards, ghost replays, tournaments) but **catastrophic production engineering** (RCE vulnerability, IAP fraud risk, no mobile input, broken continue flow).

The code review found **35 total issues**:
- **6 critical** (security + compilation)
- **9 high severity** (gameplay + performance)
- **10 medium severity** (architecture + optimization)
- **10 low severity** (polish + maintenance)

The progression systems (VehicleUnlockSystem, DailyRewardSystem) have well-thought-out **retention mechanics** and **monetization funnels**. These designs are worth preserving for future mobile games.

However, the **security posture is unshippable**. Every revenue stream (ads, IAP, rewarded videos) is either broken or exploitable. Fixing all issues would take as long as building a new game with proper architecture.

**The right path forward** is to extract the progression design patterns, apply them to a new endless runner built on MobileGameCore with security baked in from the start.

**Status**: FROZEN - Do not resume work. Use design patterns in future mobile games built on MobileGameCore.
