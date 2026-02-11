# Mobile Game Monetization Pattern

**Source**: block-blast-agent (2026-02-10)
**Reusable For**: All mobile games (puzzle, casual, hyper-casual)

## Overview

Production-ready monetization stack for Unity mobile games. Implements 70/30 ads-to-IAP revenue split with player-friendly frequency controls.

## Components

### 1. IAPManager (Unity IAP)

**Purpose**: Handle all in-app purchases with receipt validation

**Key Features**:
- 8-product template (Remove Ads + 5 gem packs + 2 bundles)
- iOS purchase restoration (App Store requirement)
- Receipt validation framework
- Analytics revenue tracking
- Sandbox testing support

**Product Template**:
```csharp
// Non-consumable
REMOVE_ADS: $2.99

// Consumable (gem packs with 10% bonus on larger packs)
GEMS_100: $0.99 (100 gems)
GEMS_500: $2.99 (550 gems, 10% bonus)
GEMS_1200: $4.99 (1320 gems, 10% bonus)
GEMS_3000: $9.99 (3300 gems, 10% bonus)
GEMS_10000: $19.99 (11000 gems, 10% bonus)

// Bundles (currency + premium content)
STARTER_BUNDLE: $4.99 (500 gems + rare item)
PREMIUM_BUNDLE: $7.99 (1000 gems + epic item)
```

**Integration**:
```csharp
// Purchase product
IAPManager.Instance.BuyProduct(IAPManager.GEMS_500);

// Check if ads removed
bool adsDisabled = IAPManager.Instance.HasRemovedAds();

// Get localized price
string price = IAPManager.Instance.GetProductPrice(IAPManager.REMOVE_ADS);
```

### 2. UnityAdsManager (Unity Ads SDK)

**Purpose**: Monetize with rewarded video and interstitial ads

**Key Features**:
- Rewarded video (continue game, bonus rewards)
- Interstitial with frequency control (no spam)
- Auto-retry on load failure
- Remove Ads IAP integration (skip ads for paying users)
- Platform-specific ad unit IDs

**Ad Frequency**:
```csharp
// Interstitial frequency (player-friendly)
interstitialCooldown: 180f (3 minutes)
gamesBeforeInterstitial: 3 (every 3 games)

// Rewarded video (on-demand, no limits)
ShowRewardedAd((success) => {
    if (success) GrantReward();
});
```

**Integration**:
```csharp
// Show rewarded ad
UnityAdsManager.Instance.ShowRewardedAd((success) => {
    if (success) {
        // Grant reward (continue game, bonus coins, etc.)
    }
});

// Show interstitial (respects frequency)
UnityAdsManager.Instance.ShowInterstitialAd(() => {
    // Ad complete or skipped
});

// Check if ad ready
bool ready = UnityAdsManager.Instance.IsRewardedAdReady();
```

### 3. ShopUI

**Purpose**: Display hero collection and gem packs for purchase

**Key Features**:
- Tab-based navigation (Heroes + Gems)
- Hero purchase cards with unlock status
- Gem pack cards with dynamic IAP pricing
- Currency display (coins + gems)
- Special offers (Remove Ads, bundles)

**Design Pattern**:
```csharp
// Shop tabs
enum ShopTab { Heroes, Gems }

// Hero purchase flow
public void PurchaseHero(string heroId, int gemCost) {
    if (economyManager.SpendGems(gemCost)) {
        heroSystem.UnlockHero(heroId);
        ShowPurchaseSuccess("Hero Unlocked!");
    }
}

// IAP purchase flow
public void PurchaseGemPack(string productId) {
    IAPManager.Instance.BuyProduct(productId);
}
```

### 4. GameOverController

**Purpose**: Monetization flow on game over (continue + interstitial)

**Key Features**:
- Continue with rewarded ad OR gems (player choice)
- Interstitial ad display (respects frequency)
- Score and high score tracking
- Game resume mechanics

**Continue Flow**:
```csharp
// Continue button logic
void OnContinueClicked() {
    if (UnityAdsManager.Instance.IsRewardedAdReady()) {
        // Show rewarded ad
        UnityAdsManager.Instance.ShowRewardedAd(OnContinueAdComplete);
    } else {
        // Fallback: Continue with gems
        ContinueWithGems(50);
    }
}

// Resume game after continue
void ContinueGame() {
    ClearSomeBlocks(); // Clear 20-30% of board
    HideGameOver();
    Time.timeScale = 1f;
}
```

## Revenue Model

### Target Metrics

- **ARPDAU**: $0.03-$0.05
- **IAP Conversion**: 2-3%
- **Ad Revenue**: 70% of total
- **IAP Revenue**: 30% of total
- **D1 Retention**: 40-45%
- **D7 Retention**: 18-22%
- **Avg Session**: 8-12 minutes
- **Ad Impressions/Session**: 3-5
- **eCPM**: $8-$12

### Revenue Split

**Ads (70%)**:
- Rewarded video: 2-3 views/session
- Interstitial: 1-2 views/session
- eCPM: $8-$12 (Unity Ads, AdMob)

**IAP (30%)**:
- Remove Ads: 15-20% of IAP revenue
- Gem packs: 50-60% of IAP revenue
- Bundles: 20-30% of IAP revenue
- Average purchase: $3.50-$5.00

## Setup Checklist

### Unity Packages

1. Install Unity IAP (Window → Package Manager → Unity IAP)
2. Install Unity Ads (Window → Package Manager → Advertisements)

### Unity Dashboard

1. Create project at dashboard.unity.com
2. Get Game IDs (Android + iOS)
3. Configure ad units:
   - Rewarded_Android / Rewarded_iOS
   - Interstitial_Android / Interstitial_iOS
4. Enable test mode for development

### Store Setup

**Google Play Console**:
1. Create app listing
2. Add IAP products matching IAPManager constants
3. Set prices for each product
4. Enable sandbox testing

**App Store Connect**:
1. Create app listing
2. Add IAP products matching IAPManager constants
3. Set prices for each product
4. Enable sandbox testing

### Code Integration

1. Copy IAPManager.cs to project
2. Copy UnityAdsManager.cs to project
3. Copy ShopUI.cs to project
4. Copy GameOverController.cs to project
5. Update Game IDs in UnityAdsManager
6. Update Product IDs in IAPManager (match store listings)
7. Create EconomyManager singleton (if not exists)
8. Test sandbox purchases

## Customization

### Adjust Ad Frequency

```csharp
// In UnityAdsManager
public float interstitialCooldown = 180f; // Change to 120-300 seconds
public int gamesBeforeInterstitial = 3;   // Change to 2-5 games
```

### Adjust IAP Prices

```csharp
// In IAPManager (reference only, real prices set in stores)
private Dictionary<string, float> productPrices = new Dictionary<string, float>
{
    { REMOVE_ADS, 2.99f },     // Change to 1.99-4.99
    { GEMS_100, 0.99f },       // Entry-level
    { GEMS_500, 2.99f },       // Best value
    { GEMS_10000, 19.99f }     // Whale tier
};
```

### Adjust Gem Economy

```csharp
// In GameOverController
public int continueCostGems = 50; // Change to 25-100 gems

// In ShopUI
// Adjust hero unlock costs by rarity:
Common: 100 gems
Rare: 250 gems
Epic: 500 gems
Legendary: 1000 gems
```

## Best Practices

### Player-Friendly Monetization

1. **No Forced Ads**: All ads are optional (rewarded) or respectful (interstitial with cooldown)
2. **Clear IAP Value**: Bundles offer 10% bonus, clear gem amounts
3. **Multiple Paths**: Continue with ad OR gems (player choice)
4. **Fair Pricing**: Remove Ads at $2.99 is industry standard

### Technical Best Practices

1. **Error Handling**: All IAP/Ad calls have failure callbacks
2. **Retry Logic**: Auto-retry ad loading on failure
3. **State Management**: Track purchase state in PlayerPrefs
4. **Analytics**: Log all purchase/ad events for tracking
5. **Testing**: Editor test methods for development

### Revenue Optimization

1. **10% Bonus**: Incentivize larger gem pack purchases
2. **Limited Bundles**: Starter/Hero bundles create urgency
3. **Continue Flow**: Maximize rewarded ad views
4. **Remove Ads**: High perceived value at reasonable price

## Testing

### IAP Testing

```csharp
// Editor test methods (IAPManager)
[ContextMenu("Test: Buy Remove Ads")]
public void TestBuyRemoveAds() { ... }

[ContextMenu("Test: Buy 500 Gems")]
public void TestBuy500Gems() { ... }

[ContextMenu("Test: Reset Purchases")]
public void TestResetPurchases() { ... }
```

### Ads Testing

```csharp
// Editor test methods (UnityAdsManager)
[ContextMenu("Test: Show Rewarded Ad")]
public void TestShowRewardedAd() { ... }

[ContextMenu("Test: Show Interstitial Ad")]
public void TestShowInterstitialAd() { ... }

[ContextMenu("Test: Reset Cooldowns")]
public void TestResetCooldowns() { ... }
```

## Cross-Project Usage

**Compatible With**:
- Puzzle games (Block Blast, Tetris clones)
- Casual games (Match-3, merge games)
- Hyper-casual games (runners, arcade)
- Collection games (hero collectors, pet games)

**Adaptation Required**:
- Change product IDs to match game
- Adjust gem economy (earning rates, spending costs)
- Customize shop UI for game theme
- Replace hero system with game-specific collection

## File Locations

```
Scripts/
├── Monetization/
│   ├── IAPManager.cs (580 lines)
│   └── UnityAdsManager.cs (560 lines)
└── UI/
    ├── ShopUI.cs (550 lines)
    └── GameOverController.cs (450 lines)
```

## Dependencies

- Unity 2022.3 or later
- Unity IAP package (com.unity.purchasing)
- Unity Ads package (com.unity.ads)
- TextMeshPro (for UI text)

## License

MIT License - Free to use in any project

## Support

For questions or issues, contact the agent-bus team or refer to:
- Unity IAP Docs: https://docs.unity.com/iap/
- Unity Ads Docs: https://docs.unity.com/ads/
