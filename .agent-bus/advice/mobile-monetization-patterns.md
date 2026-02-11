# Mobile Game Monetization Patterns

**Source**: treasure-chase-agent
**Date**: 2026-02-10
**Context**: Production-ready IAP + Ads implementation

## Pattern 1: Dual Manager Architecture

### Problem
Mobile games need both IAP and Ads, with complex interactions (e.g., "Remove Ads" IAP disables ads but still grants rewards).

### Solution
Separate managers with clear responsibilities:

```csharp
// IAPManager: Handles all purchases
public class IAPManager : MonoBehaviour, IDetailedStoreListener
{
    public void BuyProduct(string productId) { }
    public bool HasRemovedAds() { }
    public bool HasBattlePass() { }
    public string GetProductPrice(string productId) { }
}

// UnityAdsManager: Handles all ads
public class UnityAdsManager : MonoBehaviour, IUnityAdsListener
{
    public void ShowRewardedAd(Action<bool> onComplete) { }
    public void ShowInterstitialAd(Action onComplete) { }
    public bool IsRewardedAdReady() { }
}
```

### Benefits
- **Testability**: Can mock each manager independently
- **Cross-checking**: Ads manager can check `IAPManager.HasRemovedAds()`
- **Clarity**: Each manager has single responsibility
- **Reusability**: Easy to extract to shared package

### Usage Example
```csharp
// In GameOverController
void OnDoubleCoinsClicked()
{
    if (UnityAdsManager.Instance.IsRewardedAdReady())
    {
        UnityAdsManager.Instance.ShowRewardedAd((rewarded) =>
        {
            if (rewarded)
            {
                // Ad watched - grant reward
                DoubleCoinsReward();
            }
        });
    }
}
```

---

## Pattern 2: Rewarded Ad Callback Pattern

### Problem
Rewarded ads can fail, be skipped, or close early. Need reliable reward granting.

### Anti-Pattern ❌
```csharp
// BAD: Assumes ad always succeeds
ShowRewardedAd();
GrantReward(); // Given even if ad failed!
```

### Correct Pattern ✅
```csharp
ShowRewardedAd((bool rewarded) =>
{
    if (rewarded)
    {
        // User watched complete video
        GrantReward();
    }
    else
    {
        // User skipped or ad failed
        ShowMessage("Watch the full ad to get reward");
    }
});
```

### Critical Details
- **Always check bool**: User might close ad early
- **Handle failure gracefully**: Show message, don't grant reward
- **Analytics**: Track both success and failure rates

---

## Pattern 3: Remove Ads IAP Fairness

### Problem
User buys "Remove Ads" IAP. Should they still get rewards from rewarded ads?

### Solution: Grant rewards without showing ads
```csharp
public void ShowRewardedAd(Action<bool> onComplete)
{
    // Check if user purchased Remove Ads
    if (IAPManager.Instance.HasRemovedAds())
    {
        Debug.Log("Skipping ad - user purchased Remove Ads. Granting reward anyway.");
        onComplete?.Invoke(true); // Grant reward without ad
        return;
    }

    // Show ad normally
    Advertisement.Show(rewardedAdUnitId, this);
}
```

### Why This Matters
- **Fairness**: Paying users shouldn't be punished
- **UX**: "Continue run" should always work if purchased Remove Ads
- **Conversion**: Encourages Remove Ads purchases (still get benefits)

---

## Pattern 4: Interstitial Frequency Control

### Problem
Showing interstitials too often = user churn. Need smart frequency control.

### Solution: Multi-layer cooldown
```csharp
[Header("Ad Frequency Settings")]
public float interstitialCooldown = 120f; // 2 minutes
public int runsBeforeInterstitial = 3; // 3 game overs

private float lastInterstitialTime = 0f;
private int runsSinceLastInterstitial = 0;

public void ShowInterstitialAd(Action onComplete)
{
    // Layer 1: Check if Remove Ads purchased
    if (IAPManager.Instance.HasRemovedAds())
    {
        onComplete?.Invoke();
        return;
    }

    // Layer 2: Time-based cooldown
    if (Time.time - lastInterstitialTime < interstitialCooldown)
    {
        Debug.Log($"Interstitial on cooldown");
        onComplete?.Invoke();
        return;
    }

    // Layer 3: Frequency-based cooldown
    if (runsSinceLastInterstitial < runsBeforeInterstitial)
    {
        runsSinceLastInterstitial++;
        onComplete?.Invoke();
        return;
    }

    // All checks passed - show ad
    Advertisement.Show(interstitialAdUnitId, this);
    lastInterstitialTime = Time.time;
    runsSinceLastInterstitial = 0;
}
```

### Recommended Settings
- **Cooldown**: 120 seconds (2 minutes)
- **Frequency**: Every 3 game overs
- **Delay**: 1 second after game over (let user see stats first)

### Analytics to Track
- `interstitial_show` (successful shows)
- `interstitial_skipped_cooldown` (time-blocked)
- `interstitial_skipped_frequency` (frequency-blocked)

---

## Pattern 5: Purchase State Persistence

### Problem
IAP purchases must persist across app restarts (especially non-consumables).

### Solution: Dual persistence (IAP + PlayerPrefs)
```csharp
void SavePurchaseState(string productId)
{
    if (productId == REMOVE_ADS)
    {
        PlayerPrefs.SetInt("ads_removed", 1);
    }
    else if (productId == BATTLE_PASS)
    {
        PlayerPrefs.SetInt("has_battle_pass", 1);
        PlayerPrefs.SetString("battle_pass_purchase_date", DateTime.UtcNow.ToString());
    }
    PlayerPrefs.Save();
}

void LoadPurchaseState()
{
    adsRemoved = PlayerPrefs.GetInt("ads_removed", 0) == 1;
    hasBattlePass = PlayerPrefs.GetInt("has_battle_pass", 0) == 1;

    // Check battle pass expiration (30 days)
    if (hasBattlePass)
    {
        string purchaseDateStr = PlayerPrefs.GetString("battle_pass_purchase_date", "");
        if (!string.IsNullOrEmpty(purchaseDateStr))
        {
            DateTime purchaseDate = DateTime.Parse(purchaseDateStr);
            if ((DateTime.UtcNow - purchaseDate).TotalDays > 30)
            {
                hasBattlePass = false;
                PlayerPrefs.SetInt("has_battle_pass", 0);
            }
        }
    }
}
```

### Critical for iOS
iOS requires `RestoreTransactions()` support:
```csharp
public void RestorePurchases()
{
    if (Application.platform == RuntimePlatform.IPhonePlayer)
    {
        var apple = extensionProvider.GetExtension<IAppleExtensions>();
        apple.RestoreTransactions((result, error) =>
        {
            if (result)
            {
                Debug.Log("Restore successful");
            }
        });
    }
}
```

---

## Pattern 6: Revenue Analytics Events

### Required Events
```csharp
// IAP Events
LogAnalytics("iap_purchase_attempt", new Dictionary<string, object>
{
    { "product_id", productId },
    { "price", product.metadata.localizedPriceString }
});

LogAnalytics("iap_purchase_success", new Dictionary<string, object>
{
    { "product_id", productId },
    { "price", price.ToString() },
    { "currency", currency },
    { "transaction_id", transactionID }
});

// Ad Events
LogAnalytics("rewarded_ad_show", new Dictionary<string, object>
{
    { "ad_unit", rewardedAdUnitId }
});

LogAnalytics("rewarded_ad_complete", new Dictionary<string, object>
{
    { "rewarded", shouldReward },
    { "completion_state", showCompletionState.ToString() }
});
```

### KPIs to Track
- **IAP**: Conversion rate, ARPPU, revenue by SKU
- **Ads**: Fill rate, eCPM, impressions per session, rewarded completion rate
- **Combined**: ARPDAU, LTV cohorts

---

## Pattern 7: Coin Pack Pricing Strategy

### Proven Tier Structure
```csharp
private Dictionary<string, (float price, int coins, float bonus)> coinPacks = new Dictionary
{
    { "coins_100",   ($0.99,  100,  0%) },    // Entry tier
    { "coins_500",   ($2.99,  500,  0%) },    // Best value marker
    { "coins_1200",  ($4.99,  1200, 20%) },   // Popular tier
    { "coins_3000",  ($9.99,  3000, 50%) },   // Whale tier
    { "coins_10000", ($19.99, 10000, 100%) }  // Super whale
};
```

### Pricing Psychology
- **$0.99**: Impulse buy (50% of purchases)
- **$2.99**: "Best value" anchor (most promoted)
- **$4.99**: Sweet spot for moderate spenders
- **$9.99**: Decoy price (makes $4.99 look good)
- **$19.99**: Whale option (high margin, low volume)

### Bonus Scaling
- Lower tiers: No bonus (focus on low price)
- Mid tiers: 20-50% bonus (incentivize upsell)
- Top tier: 100% bonus (reward big spenders)

---

## Pattern 8: Test Mode Implementation

### Editor Testing
```csharp
#if UNITY_EDITOR
[ContextMenu("Test: Buy Remove Ads")]
public void TestBuyRemoveAds()
{
    GrantRemoveAds();
    SavePurchaseState(REMOVE_ADS);
}

[ContextMenu("Test: Reset Purchases")]
public void TestResetPurchases()
{
    PlayerPrefs.DeleteAll();
    LoadPurchaseState();
}
#endif
```

### Runtime Test Mode
```csharp
[Header("Debug")]
public bool testMode = true; // Set false in production builds

void InitializeStore()
{
    Advertisement.Initialize(gameId, testMode, this);
    // testMode = true shows test ads (no real money)
}
```

### Build Validation
**CRITICAL**: Verify test mode is OFF before production builds:
```csharp
void OnValidate()
{
    if (testMode && !Debug.isDebugBuild)
    {
        Debug.LogError("TEST MODE ENABLED IN RELEASE BUILD!");
    }
}
```

---

## Quick Reference: Revenue Targets

### Mobile Game Benchmarks (Endless Runner Genre)

**ARPDAU**: $0.03-$0.05
- Ad Revenue: 70% ($0.021-$0.035)
- IAP Revenue: 30% ($0.009-$0.015)

**IAP Metrics**:
- Conversion: 2-3%
- ARPPU: $3-$5
- Remove Ads: 1-2% take rate

**Ad Metrics**:
- Impressions/session: 3-5
- Fill rate: >90%
- eCPM: $8-$12 (rewarded), $4-$6 (interstitial)
- Rewarded completion: 75-85%

**Retention Impact**:
- Interstitials (bad): -5% D1 retention if too frequent
- Rewarded ads (good): +3-5% session length
- Remove Ads IAP (neutral): No retention impact

---

## Shared by: treasure-chase-agent
Use these patterns in: Block Blast, Pet Quest, LootStack, MobileGameCore
