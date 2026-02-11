# MobileGameCore Integration Guide

**Complete guide to integrating MobileGameCore into your Unity mobile game.**

---

## Table of Contents
1. [Installation](#installation)
2. [Quick Start (5 Minutes)](#quick-start)
3. [Core Systems Setup](#core-systems-setup)
4. [Monetization Setup (IAP + Ads)](#monetization-setup)
5. [Remote Config Setup](#remote-config-setup)
6. [Common Patterns](#common-patterns)
7. [Platform-Specific Setup](#platform-specific-setup)
8. [Troubleshooting](#troubleshooting)

---

## Installation

### Method 1: Unity Package Manager (Recommended)
1. Copy `MobileGameCore` folder to your project
2. Open Unity
3. Window → Package Manager → + → Add package from disk
4. Select `MobileGameCore/package.json`
5. Done! All scripts available under `MobileGameCore` namespace

### Method 2: Direct Import
1. Copy `MobileGameCore/Runtime` to `Assets/MobileGameCore`
2. Scripts immediately available
3. No package manager needed

---

## Quick Start (5 Minutes)

### Step 1: Create Bootstrap Scene

Create a new scene called `Bootstrap` with this script:

```csharp
using UnityEngine;
using MobileGameCore;

public class GameBootstrap : MonoBehaviour
{
    void Start()
    {
        // Initialize core systems in order
        SaveSystem.Instance.Initialize();
        AnalyticsManager.Instance.Initialize();
        EconomyManager.Instance.Initialize();
        AdManager.Instance.Initialize();

        // Load your main menu
        UnityEngine.SceneManagement.SceneManager.LoadScene("MainMenu");
    }
}
```

### Step 2: Test It
1. Add `GameBootstrap` to empty GameObject in Bootstrap scene
2. Add Bootstrap scene to Build Settings (index 0)
3. Press Play
4. Check Console - should see initialization logs

**You're done!** All core systems are now available throughout your game.

---

## Core Systems Setup

### SaveSystem - Player Progression

**Basic Usage:**
```csharp
// Save currency
SaveSystem.Instance.AddCurrency("coins", 100);
SaveSystem.Instance.AddCurrency("gems", 50);

// Save level progress
SaveSystem.Instance.SaveLevelProgress(1, 3, 1200); // level, stars, score

// Save custom data
SaveSystem.Instance.SetCustomData("player_name", "Alice");
SaveSystem.Instance.SetCustomData("tutorial_complete", true);

// Save to disk
SaveSystem.Instance.Save();
```

**Load Data:**
```csharp
void Start()
{
    SaveSystem.Instance.Initialize(); // Auto-loads

    int coins = SaveSystem.Instance.GetCurrency("coins");
    bool tutorialDone = SaveSystem.Instance.GetCustomData<bool>("tutorial_complete", false);
}
```

**Reset Progress (for testing):**
```csharp
SaveSystem.Instance.ResetAllData(); // Clears everything
```

### AnalyticsManager - Track Everything

**Track Events:**
```csharp
// Level events
AnalyticsManager.Instance.TrackLevelStart(1);
AnalyticsManager.Instance.TrackLevelComplete(1, 1200, 45.5f, 3);
AnalyticsManager.Instance.TrackLevelFail(1, "fell_off_platform");

// Item collection
AnalyticsManager.Instance.TrackItemCollected("coin", 10);
AnalyticsManager.Instance.TrackItemUnlock("legendary_sword", "gameplay");

// Custom events
AnalyticsManager.Instance.TrackEvent("boss_defeated", new Dictionary<string, object>
{
    { "boss_name", "Dragon" },
    { "attempts", 3 },
    { "time_seconds", 120.5f }
});
```

**User Properties:**
```csharp
AnalyticsManager.Instance.SetUserProperty("player_level", "15");
AnalyticsManager.Instance.SetHasMadePurchase(true);
```

### EconomyManager - Currencies & Purchases

**Setup Currencies:**
```csharp
void Start()
{
    EconomyManager.Instance.Initialize();

    // Currencies are automatically tracked via SaveSystem
    // Default: "coins" and "gems"
}
```

**Spend Currency:**
```csharp
// Check if player can afford
if (EconomyManager.Instance.CanAfford("coins", 500))
{
    EconomyManager.Instance.SpendCurrency("coins", 500);
    UnlockPowerUp();
}
else
{
    ShowInsufficientFundsUI();
}
```

**Reward Currency:**
```csharp
// From level complete
EconomyManager.Instance.AddCurrency("coins", 100);

// From ad watch
EconomyManager.Instance.AddCurrency("gems", 50);

// Always save after currency changes
SaveSystem.Instance.Save();
```

---

## Monetization Setup (IAP + Ads)

### In-App Purchases (IAP)

**1. Install Unity IAP Package:**
```
Window → Package Manager → Unity Registry → In App Purchasing → Install
```

**2. Configure Products in IAPManager.cs:**

Edit the `products` array in IAPManager.cs (or extend it):

```csharp
[Header("Product Catalog")]
[SerializeField] private ProductDefinition[] products = new ProductDefinition[]
{
    // Your actual product IDs from App Store / Google Play
    new ProductDefinition
    {
        productId = "com.mygame.gems_100",
        productType = ProductType.Consumable,
        rewardAmount = 100,
        rewardType = "gems"
    },
    new ProductDefinition
    {
        productId = "com.mygame.remove_ads",
        productType = ProductType.NonConsumable,
        rewardType = "remove_ads"
    }
};
```

**3. Purchase Flow:**

```csharp
public class ShopUI : MonoBehaviour
{
    public void OnBuyGems100Clicked()
    {
        IAPManager.Instance.PurchaseProduct("com.mygame.gems_100", OnPurchaseComplete);
    }

    void OnPurchaseComplete(bool success, string productId)
    {
        if (success)
        {
            // IAPManager auto-grants gems via EconomyManager
            ShowSuccessMessage("Purchase successful!");
        }
        else
        {
            ShowErrorMessage("Purchase failed. Please try again.");
        }
    }
}
```

**4. Check Ownership (Non-Consumables):**

```csharp
void Start()
{
    bool adsRemoved = IAPManager.Instance.HasPurchased("com.mygame.remove_ads");

    if (adsRemoved)
    {
        // Hide all ads
        AdManager.Instance.enabled = false;
    }
}
```

**5. Restore Purchases (iOS Requirement):**

```csharp
public void OnRestorePurchasesClicked()
{
    IAPManager.Instance.RestorePurchases((success) =>
    {
        if (success)
            ShowSuccessMessage("Purchases restored!");
    });
}
```

### Unity Ads

**1. Enable Ads:**
- Services → Ads → Enable
- Get your Game ID from Unity Dashboard

**2. Configure AdManager:**
```csharp
// In Unity Inspector on AdManager prefab:
// - Android Game ID: your_android_id
// - iOS Game ID: your_ios_id
// - Test Mode: true (for testing)
```

**3. Show Rewarded Ad:**

```csharp
public class RewardedAdButton : MonoBehaviour
{
    public void OnWatchAdClicked()
    {
        AdManager.Instance.ShowRewardedAd(OnAdComplete);
    }

    void OnAdComplete(bool success)
    {
        if (success)
        {
            // Grant reward
            EconomyManager.Instance.AddCurrency("gems", 50);
            SaveSystem.Instance.Save();

            ShowRewardMessage("You earned 50 gems!");
        }
    }
}
```

**4. Show Interstitial (Game Over):**

```csharp
public class GameOverScreen : MonoBehaviour
{
    void Start()
    {
        // Show ad every 3rd game over
        int gamesPlayed = SaveSystem.Instance.GetCustomData<int>("games_played", 0);

        if (gamesPlayed % 3 == 0)
        {
            AdManager.Instance.ShowInterstitialAd(null);
        }
    }
}
```

---

## Remote Config Setup

**Enable live tuning of game parameters without app updates!**

### 1. Install Packages

```
Window → Package Manager → Unity Registry
→ Install: Remote Config, Services Core
```

### 2. Enable Service

```
Services → Remote Config → Enable
```

### 3. Create Config in Dashboard

Unity Dashboard → Remote Config → Create Settings:

```json
{
  "ad_reward_multiplier": 1.5,
  "daily_reward_multiplier": 2.0,
  "event_active": true,
  "event_name": "halloween_2026",
  "iap_discount_percentage": 20
}
```

### 4. Fetch and Use Config

```csharp
void Start()
{
    RemoteConfigManager.Instance.InitializeAndFetch(() =>
    {
        // Config is ready
        float adMultiplier = RemoteConfigManager.Instance.GetAdRewardMultiplier();
        bool eventActive = RemoteConfigManager.Instance.IsEventActive();

        if (eventActive)
        {
            string eventName = RemoteConfigManager.Instance.GetEventName();
            StartEvent(eventName);
        }

        InitializeGame();
    });
}
```

### 5. Apply to Rewards

```csharp
void GrantAdReward()
{
    int baseReward = 50;
    float multiplier = RemoteConfigManager.Instance.GetAdRewardMultiplier();
    int finalReward = Mathf.RoundToInt(baseReward * multiplier);

    EconomyManager.Instance.AddCurrency("gems", finalReward);
}
```

**Now you can adjust rewards remotely for A/B testing!**

---

## Common Patterns

### Pattern 1: Complete Game Bootstrap

```csharp
using UnityEngine;
using MobileGameCore;

public class GameBootstrap : MonoBehaviour
{
    void Start()
    {
        // 1. Core systems
        SaveSystem.Instance.Initialize();
        AnalyticsManager.Instance.Initialize();

        // 2. Remote Config (fetch latest)
        RemoteConfigManager.Instance.InitializeAndFetch(() =>
        {
            // 3. Economy
            EconomyManager.Instance.Initialize();

            // 4. Monetization
            IAPManager.Instance.InitializeIAP();
            AdManager.Instance.Initialize();

            // 5. Game systems
            AchievementSystem.Instance.Initialize();
            DailyChallengeSystem.Instance.Initialize();

            // 6. Ready!
            OnSystemsReady();
        });
    }

    void OnSystemsReady()
    {
        // Check for daily rewards
        DailyChallengeSystem.Instance.CheckDailyReset();

        // Load main menu
        TransitionManager.Instance.LoadScene("MainMenu", TransitionManager.TransitionType.Fade);
    }
}
```

### Pattern 2: Level Complete Flow

```csharp
public class LevelController : MonoBehaviour
{
    void OnLevelComplete()
    {
        int score = CalculateScore();
        int stars = CalculateStars();
        int coinsEarned = score / 10;

        // 1. Save progress
        SaveSystem.Instance.SaveLevelProgress(currentLevel, stars, score);
        SaveSystem.Instance.AddCurrency("coins", coinsEarned);
        SaveSystem.Instance.Save();

        // 2. Track analytics
        AnalyticsManager.Instance.TrackLevelComplete(currentLevel, score, timePlayed, stars);

        // 3. Check achievements
        AchievementSystem.Instance.UpdateProgress("levels_completed", 1);

        // 4. Show UI
        ShowLevelCompleteUI(score, stars, coinsEarned);
    }
}
```

### Pattern 3: Daily Reward System

```csharp
public class DailyRewardUI : MonoBehaviour
{
    void Start()
    {
        if (DailyChallengeSystem.Instance.HasNewDailyReward())
        {
            int streak = DailyChallengeSystem.Instance.GetCurrentStreak();
            int baseReward = 100;
            int reward = baseReward * streak;

            // Apply remote config multiplier
            float multiplier = RemoteConfigManager.Instance.GetDailyRewardMultiplier();
            reward = Mathf.RoundToInt(reward * multiplier);

            // Grant reward
            EconomyManager.Instance.AddCurrency("coins", reward);
            DailyChallengeSystem.Instance.ClaimDailyReward();
            SaveSystem.Instance.Save();

            ShowRewardUI(reward, streak);
        }
    }
}
```

---

## Platform-Specific Setup

### iOS Setup

**1. App Tracking Transparency (ATT):**

Add to `Info.plist`:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your data to show personalized ads and improve your experience.</string>
```

**2. Request Tracking:**
```csharp
void Start()
{
    #if UNITY_IOS
    ATTManager.Instance.RequestTracking((authorized) =>
    {
        if (authorized)
        {
            Debug.Log("Tracking authorized");
        }
        AdManager.Instance.Initialize();
    });
    #else
    AdManager.Instance.Initialize();
    #endif
}
```

### Android Setup

**1. Permissions:**

Automatically handled by Unity Ads and IAP packages.

**2. Google Play Services:**

Install via Package Manager if using Google Play billing.

---

## Troubleshooting

### "IAPManager not initializing"
**Solution:** Install Unity IAP package via Package Manager.

### "Ads not showing"
**Solution:**
1. Check Game IDs are set in AdManager inspector
2. Verify ads are enabled in Unity Services
3. Set Test Mode = true during development

### "Remote Config always returns defaults"
**Solution:**
1. Check internet connection
2. Verify Remote Config is enabled in Services
3. Check Unity Dashboard has published settings

### "Save file corrupted"
**Solution:**
```csharp
SaveSystem.Instance.ResetAllData(); // Nuclear option
// Or check corruption type:
AnalyticsManager.Instance.TrackSaveFileCorruption("hash_mismatch");
```

### "Firebase Analytics not working"
**Solution:**
1. Download Firebase Unity SDK
2. Add google-services.json (Android) or GoogleService-Info.plist (iOS)
3. System works without Firebase (graceful fallback)

---

## Next Steps

1. **Read TESTING_GUIDE.md** - Validate integration
2. **Check CHANGELOG.md** - See what's new
3. **Review example games** - LootStackMayhem, TreasureChase
4. **Join community** - GitHub Discussions

---

## Revenue Optimization Tips

### 1. A/B Test IAP Prices
```csharp
// Use Remote Config to test prices
int price = RemoteConfigManager.Instance.GetInt("gem_pack_100_price", 99);
ShowPrice(price);
```

### 2. Smart Ad Placement
```csharp
// Show ads at natural breaks, not spam
bool shouldShowAd =
    gamesPlayed % 3 == 0 &&  // Every 3rd game
    TimeSinceLastAd() > 120;  // At least 2 minutes apart
```

### 3. Track Everything
```csharp
// Know your funnel
AnalyticsManager.Instance.TrackEvent("shop_opened");
AnalyticsManager.Instance.TrackEvent("iap_viewed", { "product_id", productId });
AnalyticsManager.Instance.TrackEvent("iap_purchase_initiated", ...);
```

---

**You're ready to ship!** 🚀

Questions? Check the code comments - every public method has XML documentation.
