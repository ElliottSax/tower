# MobileGameCore Quick Reference

**Fast lookup for common operations. Copy-paste ready.**

---

## Installation (1 Minute)

```bash
# Method 1: Unity Package Manager
Window → Package Manager → + → Add package from disk → Select package.json

# Method 2: Direct Import
Copy MobileGameCore/Runtime to Assets/MobileGameCore
```

---

## Bootstrap (Copy-Paste)

```csharp
using UnityEngine;
using MobileGameCore;

public class GameBootstrap : MonoBehaviour
{
    void Start()
    {
        // Core
        SaveSystem.Instance.Initialize();
        AnalyticsManager.Instance.Initialize();

        // Remote Config → Economy → Monetization
        RemoteConfigManager.Instance.InitializeAndFetch(() => {
            EconomyManager.Instance.Initialize();
            IAPManager.Instance.InitializeIAP();
            AdManager.Instance.Initialize();

            LoadMainMenu();
        });
    }

    void LoadMainMenu()
    {
        TransitionManager.Instance.LoadScene("MainMenu", TransitionManager.TransitionType.Fade);
    }
}
```

---

## Save System

```csharp
// SAVE
SaveSystem.Instance.AddCurrency("coins", 100);
SaveSystem.Instance.SaveLevelProgress(level, stars, score);
SaveSystem.Instance.SetCustomData("player_name", "Alice");
SaveSystem.Instance.Save(); // Write to disk

// LOAD
int coins = SaveSystem.Instance.GetCurrency("coins");
bool tutorialDone = SaveSystem.Instance.GetCustomData<bool>("tutorial_done", false);
```

---

## Economy

```csharp
// CHECK & SPEND
if (EconomyManager.Instance.CanAfford("coins", 500))
{
    EconomyManager.Instance.SpendCurrency("coins", 500);
    UnlockItem();
}

// ADD
EconomyManager.Instance.AddCurrency("gems", 50);
SaveSystem.Instance.Save();
```

---

## In-App Purchases (IAP)

```csharp
// PURCHASE
IAPManager.Instance.PurchaseProduct("com.game.gems_100", (success, id) => {
    if (success) {
        // Gems auto-granted by IAPManager
        ShowSuccessUI();
    }
});

// CHECK OWNERSHIP (non-consumables)
bool adsRemoved = IAPManager.Instance.HasPurchased("com.game.remove_ads");

// RESTORE (iOS)
IAPManager.Instance.RestorePurchases((success) => {
    if (success) ShowRestoreSuccessUI();
});

// GET PRICE
string price = IAPManager.Instance.GetLocalizedPrice("com.game.gems_100");
priceLabel.text = price; // "$0.99"
```

**Setup**: Edit product catalog in `IAPManager.cs`

---

## Ads

```csharp
// REWARDED AD
AdManager.Instance.ShowRewardedAd((success) => {
    if (success) {
        EconomyManager.Instance.AddCurrency("gems", 50);
        SaveSystem.Instance.Save();
    }
});

// INTERSTITIAL AD
AdManager.Instance.ShowInterstitialAd(null);

// CHECK IF READY
bool canShow = AdManager.Instance.IsRewardedAdReady();
```

**Setup**: Set Game IDs in AdManager inspector

---

## Remote Config

```csharp
// FETCH (usually in bootstrap)
RemoteConfigManager.Instance.InitializeAndFetch(() => {
    // Config ready
    ApplyRemoteValues();
});

// GET VALUES
float adMultiplier = RemoteConfigManager.Instance.GetAdRewardMultiplier();
int startingCoins = RemoteConfigManager.Instance.GetInt("starting_coins", 100);
bool eventActive = RemoteConfigManager.Instance.IsEventActive();

// USE IN REWARDS
int reward = Mathf.RoundToInt(baseReward * adMultiplier);
```

**Setup**: Create config in Unity Dashboard → Remote Config

---

## Analytics

```csharp
// LEVEL EVENTS
AnalyticsManager.Instance.TrackLevelStart(levelNumber);
AnalyticsManager.Instance.TrackLevelComplete(level, score, time, stars);
AnalyticsManager.Instance.TrackLevelFail(level, "fell_off_platform");

// ITEM EVENTS
AnalyticsManager.Instance.TrackItemCollected("coin", 10);
AnalyticsManager.Instance.TrackItemUnlock("legendary_sword", "gameplay");

// MONETIZATION EVENTS
AnalyticsManager.Instance.TrackAdView("rewarded", "level_fail");
AnalyticsManager.Instance.LogPurchase(productId, price, currencyCode);

// CUSTOM EVENTS
AnalyticsManager.Instance.TrackEvent("boss_defeated", new Dictionary<string, object>
{
    { "boss_name", "Dragon" },
    { "attempts", 3 }
});
```

---

## Achievements

```csharp
// INITIALIZE
AchievementSystem.Instance.Initialize();

// DEFINE (in your code)
AchievementSystem.Instance.DefineAchievement(
    "first_win",
    "First Victory",
    "Win your first level",
    1, // max progress
    100 // reward coins
);

// UPDATE PROGRESS
AchievementSystem.Instance.UpdateProgress("first_win", 1);

// CHECK
bool unlocked = AchievementSystem.Instance.IsUnlocked("first_win");
```

---

## Daily Challenges

```csharp
// INITIALIZE & CHECK
DailyChallengeSystem.Instance.Initialize();
DailyChallengeSystem.Instance.CheckDailyReset(); // Call on app start

// CLAIM DAILY REWARD
if (DailyChallengeSystem.Instance.HasNewDailyReward())
{
    int streak = DailyChallengeSystem.Instance.GetCurrentStreak();
    int reward = 100 * streak;

    EconomyManager.Instance.AddCurrency("coins", reward);
    DailyChallengeSystem.Instance.ClaimDailyReward();
    SaveSystem.Instance.Save();
}
```

---

## Audio

```csharp
// PLAY MUSIC
AudioManager.Instance.PlayMusic(musicClip, loop: true);

// PLAY SFX
AudioManager.Instance.PlaySFX(jumpSound);

// VOLUME
AudioManager.Instance.SetMasterVolume(0.8f);
AudioManager.Instance.SetMusicVolume(0.6f);
AudioManager.Instance.SetSFXVolume(1.0f);
```

---

## Camera

```csharp
// SETUP
EnhancedCameraController camera = Camera.main.GetComponent<EnhancedCameraController>();
camera.target = player.transform;
camera.followSpeed = 5f;

// SHAKE
camera.Shake(EnhancedCameraController.ShakePreset.Medium);

// ZOOM
camera.SetTargetZoom(8f, 1f); // size, duration
```

---

## Game Feel

```csharp
// HIT FREEZE
GameFeelManager.Instance.HitFreeze(0.1f);

// SLOW MOTION
GameFeelManager.Instance.SlowMotion(0.5f, 2f); // scale, duration

// COLLECTION FEEDBACK
GameFeelManager.Instance.OnCollectible(collectiblePosition, "coin");
```

---

## Scene Transitions

```csharp
// LOAD WITH TRANSITION
TransitionManager.Instance.LoadScene("Level1", TransitionManager.TransitionType.Fade);

// WITH LOADING SCREEN
TransitionManager.Instance.LoadSceneWithLoadingScreen("Level1", minimumLoadTime: 1f);
```

---

## Input

```csharp
// GET INPUT
Vector2 input = InputManager.Instance.GetMovementInput();

// CHECK MODE
InputMode mode = InputManager.Instance.CurrentMode; // VirtualJoystick, Tilt, Swipe

// CHANGE MODE
InputManager.Instance.SetInputMode(InputMode.Tilt);
```

---

## Performance Profiler

```csharp
// ENABLE (F1 in-game)
PerformanceProfiler.Instance.enabled = true;

// GET STATS
float fps = PerformanceProfiler.Instance.CurrentFPS;
float memory = PerformanceProfiler.Instance.CurrentMemoryMB;
```

**Shows overlay with FPS, memory, draw calls**

---

## Procedural Generation

```csharp
// CREATE COLLECTABLE
GameObject coin = ProceduralCollectable.CreateCollectable(
    ProceduralCollectable.CollectableShape.Coin,
    ProceduralCollectable.ColorPreset.Gold
);

// CREATE PARTICLE EFFECT
ProceduralParticles.CreateEffect(
    ProceduralParticles.EffectType.Sparkle,
    position,
    particleCount: 20
);

// SYNTHESIZE SOUND
AudioClip beep = AudioSynthesizer.GenerateTone(
    AudioSynthesizer.Waveform.Sine,
    440f, // frequency (Hz)
    0.5f  // duration (seconds)
);
```

---

## Common Patterns

### Level Complete Flow
```csharp
void OnLevelComplete()
{
    // 1. Calculate
    int score = CalculateScore();
    int stars = CalculateStars();
    int coins = score / 10;

    // 2. Save
    SaveSystem.Instance.SaveLevelProgress(currentLevel, stars, score);
    SaveSystem.Instance.AddCurrency("coins", coins);
    SaveSystem.Instance.Save();

    // 3. Track
    AnalyticsManager.Instance.TrackLevelComplete(currentLevel, score, timePlayed, stars);

    // 4. Achievements
    AchievementSystem.Instance.UpdateProgress("levels_completed", 1);

    // 5. UI
    ShowLevelCompleteUI(score, stars, coins);
}
```

### Shop Purchase Flow
```csharp
void OnBuyItemClicked(string itemId, int price)
{
    // 1. Check
    if (!EconomyManager.Instance.CanAfford("coins", price))
    {
        ShowInsufficientFundsUI();
        return;
    }

    // 2. Spend
    EconomyManager.Instance.SpendCurrency("coins", price);

    // 3. Grant
    GrantItem(itemId);

    // 4. Save
    SaveSystem.Instance.SetCustomData($"owned_{itemId}", true);
    SaveSystem.Instance.Save();

    // 5. Track
    AnalyticsManager.Instance.TrackPurchase(itemId, price, "coins");
}
```

### Ad Reward Flow
```csharp
void OnWatchAdClicked()
{
    AdManager.Instance.ShowRewardedAd((success) =>
    {
        if (success)
        {
            // 1. Get multiplier from remote config
            float multiplier = RemoteConfigManager.Instance.GetAdRewardMultiplier();

            // 2. Calculate reward
            int reward = Mathf.RoundToInt(50 * multiplier);

            // 3. Grant
            EconomyManager.Instance.AddCurrency("gems", reward);

            // 4. Save
            SaveSystem.Instance.Save();

            // 5. Track
            AnalyticsManager.Instance.TrackAdReward("gems", reward);

            // 6. UI
            ShowRewardUI(reward);
        }
    });
}
```

### Daily Reward Check
```csharp
void Start()
{
    DailyChallengeSystem.Instance.CheckDailyReset();

    if (DailyChallengeSystem.Instance.HasNewDailyReward())
    {
        int streak = DailyChallengeSystem.Instance.GetCurrentStreak();
        int reward = 100 * streak;

        // Apply remote config bonus
        float multiplier = RemoteConfigManager.Instance.GetDailyRewardMultiplier();
        reward = Mathf.RoundToInt(reward * multiplier);

        // Grant and save
        EconomyManager.Instance.AddCurrency("coins", reward);
        DailyChallengeSystem.Instance.ClaimDailyReward();
        SaveSystem.Instance.Save();

        ShowDailyRewardUI(reward, streak);
    }
}
```

---

## Platform-Specific

### iOS App Tracking Transparency
```csharp
#if UNITY_IOS
ATTManager.Instance.RequestTracking((authorized) => {
    Debug.Log($"Tracking: {authorized}");
    AdManager.Instance.Initialize();
});
#else
AdManager.Instance.Initialize();
#endif
```

### Check Platform
```csharp
#if UNITY_IOS
    // iOS-specific code
#elif UNITY_ANDROID
    // Android-specific code
#else
    // Editor/other platforms
#endif
```

---

## Dependencies (Optional)

Install via Package Manager if you want to use:
- **Unity Ads**: `com.unity.ads` (for AdManager)
- **Unity IAP**: `com.unity.purchasing` (for IAPManager)
- **Remote Config**: `com.unity.remote-config` (for RemoteConfigManager)
- **Services Core**: `com.unity.services.core` (required by Remote Config)

**All features gracefully degrade if packages not installed.**

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| IAP not working | Install Unity IAP package |
| Ads not showing | Set Game IDs in AdManager inspector |
| Remote Config returns defaults | Check internet, Unity Dashboard config |
| Compile errors | Install missing packages or use `#if` defines |

---

## Next Steps

1. **Read INTEGRATION_GUIDE.md** - Full setup instructions
2. **Check example games** - LootStackMayhem, TreasureChase
3. **Review CHANGELOG.md** - See what's new in each version

---

**Quick Start**: Copy bootstrap code, press play, you're done. 🚀
