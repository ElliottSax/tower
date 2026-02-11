# Block Blast Monetization Setup Guide

**Quick start guide for integrating the monetization system.**

## Prerequisites

- Unity 2022.3 or later
- Block Blast project open in Unity
- Google Play Console account (Android)
- App Store Connect account (iOS)

## Step 1: Install Unity Packages

1. Open Unity Package Manager (Window → Package Manager)

2. Install **Unity IAP**:
   - Click "+" → "Add package by name"
   - Enter: `com.unity.purchasing`
   - Click "Add"

3. Install **Unity Ads**:
   - Click "+" → "Add package by name"
   - Enter: `com.unity.ads`
   - Click "Add"

4. Wait for packages to install (may take 2-3 minutes)

## Step 2: Configure Unity Dashboard

1. Go to https://dashboard.unity.com

2. Create new project or select existing project

3. Get your **Game IDs**:
   - Go to Monetization → Configure
   - Note down Android Game ID
   - Note down iOS Game ID

4. Configure **Ad Units**:
   - Go to Monetization → Ad Units
   - Create "Rewarded_Android" (Rewarded Video)
   - Create "Interstitial_Android" (Interstitial)
   - Create "Rewarded_iOS" (Rewarded Video)
   - Create "Interstitial_iOS" (Interstitial)

5. Enable **Test Mode**:
   - Go to Settings → Test Mode
   - Enable test mode for development

## Step 3: Update Game IDs in Code

1. Open `Scripts/Monetization/UnityAdsManager.cs`

2. Replace placeholder Game IDs (lines 22-23):
```csharp
public string androidGameId = "YOUR_ANDROID_GAME_ID"; // Replace with real ID
public string iOSGameId = "YOUR_IOS_GAME_ID";         // Replace with real ID
```

3. Save the file

## Step 4: Configure Google Play Console

1. Go to https://play.google.com/console

2. Create app listing (if not exists)

3. Go to Monetize → Products → In-app products

4. Create the following products:

| Product ID | Type | Price |
|------------|------|-------|
| `com.blockblast.removeads` | Non-consumable | $2.99 |
| `com.blockblast.gems100` | Consumable | $0.99 |
| `com.blockblast.gems500` | Consumable | $2.99 |
| `com.blockblast.gems1200` | Consumable | $4.99 |
| `com.blockblast.gems3000` | Consumable | $9.99 |
| `com.blockblast.gems10000` | Consumable | $19.99 |
| `com.blockblast.starterbundle` | Consumable | $4.99 |
| `com.blockblast.herobundle` | Consumable | $7.99 |

5. Activate each product

6. Enable License Testing:
   - Go to Settings → License Testing
   - Add your test account email
   - Set license testing mode to "Respond as Licensed"

## Step 5: Configure App Store Connect

1. Go to https://appstoreconnect.apple.com

2. Create app listing (if not exists)

3. Go to Features → In-App Purchases

4. Create the following products (same as Google Play):

| Product ID | Type | Price |
|------------|------|-------|
| `com.blockblast.removeads` | Non-consumable | $2.99 |
| `com.blockblast.gems100` | Consumable | $0.99 |
| `com.blockblast.gems500` | Consumable | $2.99 |
| `com.blockblast.gems1200` | Consumable | $4.99 |
| `com.blockblast.gems3000` | Consumable | $9.99 |
| `com.blockblast.gems10000` | Consumable | $19.99 |
| `com.blockblast.starterbundle` | Consumable | $4.99 |
| `com.blockblast.herobundle` | Consumable | $7.99 |

5. Submit each product for review (required for sandbox testing)

6. Add Sandbox Test Account:
   - Go to Users and Access → Sandbox Testers
   - Add test account email

## Step 6: Create Manager GameObjects

1. In Unity Hierarchy, create empty GameObjects:
   - Right-click → Create Empty → Name: "IAPManager"
   - Right-click → Create Empty → Name: "UnityAdsManager"
   - Right-click → Create Empty → Name: "EconomyManager"
   - Right-click → Create Empty → Name: "SaveSystem"

2. Attach scripts to GameObjects:
   - IAPManager → Add Component → IAPManager.cs
   - UnityAdsManager → Add Component → UnityAdsManager.cs
   - EconomyManager → Add Component → EconomyManager.cs
   - SaveSystem → Add Component → SaveSystem.cs

3. Configure UnityAdsManager:
   - Check "Test Mode" (for development)
   - Check "Debug Mode" (for logs)

4. Configure IAPManager:
   - Check "Test Mode" (for sandbox purchases)
   - Check "Debug Mode" (for logs)

## Step 7: Test Monetization (Editor)

1. Open Unity Editor

2. Select IAPManager GameObject in Hierarchy

3. In Inspector, right-click on IAPManager script

4. Test methods available:
   - "Test: Buy Remove Ads" → Simulates purchase
   - "Test: Buy 500 Gems" → Grants 500 gems
   - "Test: Reset Purchases" → Clears purchase state

5. Select UnityAdsManager GameObject

6. Test methods available:
   - "Test: Show Rewarded Ad" → Simulates rewarded ad
   - "Test: Show Interstitial Ad" → Simulates interstitial
   - "Test: Reset Cooldowns" → Resets ad frequency

## Step 8: Test on Device (Sandbox)

### Android Testing

1. Build APK (File → Build Settings → Android → Build)

2. Install on test device

3. Login with test account (Google Play Console → License Testing)

4. Test IAP purchases (will use sandbox, no real money)

5. Test ads (will show test ads with "Unity Ads Test" watermark)

### iOS Testing

1. Build to Xcode (File → Build Settings → iOS → Build)

2. Open Xcode project

3. Connect test device

4. Run on device

5. Login with sandbox test account (App Store Connect → Sandbox Testers)

6. Test IAP purchases (will use sandbox, no real money)

7. Test ads (will show test ads)

## Step 9: Integration with Game Flow

### Game Over Screen

1. Create GameOverController UI panel

2. Add GameOverController.cs script to panel

3. Hook up UI elements in Inspector:
   - finalScoreText
   - highScoreText
   - continueButton
   - restartButton
   - mainMenuButton

4. On game over, call:
```csharp
GameOverController.Instance.ShowGameOver(score, linesCleared);
```

### Shop Screen

1. Create ShopUI panel

2. Add ShopUI.cs script to panel

3. Hook up UI elements in Inspector:
   - heroShopPanel
   - gemShopPanel
   - heroGridContainer
   - gemPackContainer
   - coinsText
   - gemsText
   - removeAdsButton
   - starterBundleButton

4. Create hero card prefab (ShopUI.HeroCard)

5. Create gem pack card prefab (ShopUI.GemPackCard)

## Step 10: Verify Analytics

1. All IAP purchases log analytics events:
   - `iap_purchase_attempt`
   - `iap_purchase_success`
   - `iap_purchase_failed`

2. All ad impressions log analytics events:
   - `rewarded_ad_show`
   - `rewarded_ad_complete`
   - `interstitial_ad_show`
   - `interstitial_ad_complete`

3. Integrate with your analytics provider:
   - Firebase Analytics
   - GameAnalytics
   - Unity Analytics

## Troubleshooting

### "Store not initialized" Error

- Wait 5-10 seconds after app launch
- Check Unity IAP package is installed
- Verify product IDs match exactly (case-sensitive)
- Check internet connection

### "Ad not loaded" Error

- Wait 10-15 seconds after app launch
- Check Unity Ads package is installed
- Verify Game IDs are correct
- Check internet connection
- Enable test mode in Unity Dashboard

### Purchases Not Working (Sandbox)

- Verify test account is added in store console
- Check product IDs match exactly
- Clear app data and reinstall
- Wait 24 hours after creating products (App Store)

### Ads Not Showing

- Enable test mode in UnityAdsManager
- Check Game IDs are correct
- Verify ad units are configured in dashboard
- Wait 10-15 seconds after initialization

## Production Checklist

Before launching:

- [ ] Disable test mode in IAPManager
- [ ] Disable test mode in UnityAdsManager
- [ ] Disable debug mode in both managers
- [ ] Verify all product IDs match store listings
- [ ] Test sandbox purchases on both platforms
- [ ] Test ad impressions (rewarded + interstitial)
- [ ] Verify analytics events are logging
- [ ] Test Remove Ads purchase flow
- [ ] Test continue with ad flow
- [ ] Test shop UI gem purchases
- [ ] Submit app for review (stores)
- [ ] Wait for IAP products approval

## Revenue Tracking

Monitor these KPIs:

- **ARPDAU**: Revenue per daily active user
- **IAP Conversion**: % of users making purchases
- **Ad Impressions**: Rewarded + interstitial per session
- **eCPM**: Earnings per 1000 ad impressions
- **D1/D7 Retention**: Day 1 and Day 7 retention rates

Target Metrics:
- ARPDAU: $0.03-$0.05
- IAP Conversion: 2-3%
- Ad Impressions/Session: 3-5
- eCPM: $8-$12

## Support

For issues or questions:
- Unity IAP Docs: https://docs.unity.com/iap/
- Unity Ads Docs: https://docs.unity.com/ads/
- Google Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/support/app-store-connect/
