# Treasure Chase - Monetization Setup Guide

**Status**: Code complete - ready for Unity package installation
**Files**: `Scripts/Monetization/IAPManager.cs`, `Scripts/Monetization/UnityAdsManager.cs`

---

## Step 1: Install Unity Packages

### 1.1 Unity IAP Package
1. Open Unity Editor
2. Window → Package Manager
3. Search for "In-App Purchasing"
4. Click "Install"
5. Wait for import to complete

### 1.2 Unity Ads Package
1. Window → Package Manager
2. Search for "Advertisement"
3. Click "Install"
4. Wait for import to complete

**Expected Dependencies**:
```
com.unity.purchasing (4.9.0+)
com.unity.ads (4.5.0+)
```

---

## Step 2: Configure Unity Services

### 2.1 Enable Unity Services
1. Window → Services
2. Create new Unity Project ID (if not already created)
3. Enable "In-App Purchasing"
4. Enable "Ads"

### 2.2 Get Game IDs
1. Unity Dashboard → Monetization → Ads
2. Copy **Android Game ID**
3. Copy **iOS Game ID**
4. Paste into `UnityAdsManager.cs`:

```csharp
[Header("Unity Ads Configuration")]
public string androidGameId = "YOUR_ANDROID_GAME_ID"; // Replace this
public string iOSGameId = "YOUR_IOS_GAME_ID";         // Replace this
```

### 2.3 Create Ad Units
1. Unity Dashboard → Monetization → Ad Units
2. Create ad units:
   - **Rewarded_Android** (Rewarded Video)
   - **Interstitial_Android** (Interstitial)
   - **Rewarded_iOS** (Rewarded Video)
   - **Interstitial_iOS** (Interstitial)

**Note**: Ad unit IDs are already set in `UnityAdsManager.cs`, just ensure they match your dashboard.

---

## Step 3: Configure Store Products

### 3.1 Google Play Console (Android)
1. Go to Google Play Console
2. Your App → In-app products
3. Create products with these IDs:

**Non-Consumable**:
- `com.treasurechase.removeads` - $2.99 - "Remove Ads"

**Consumable**:
- `com.treasurechase.coins100` - $0.99 - "100 Coins"
- `com.treasurechase.coins500` - $2.99 - "500 Coins"
- `com.treasurechase.coins1200` - $4.99 - "1,200 Coins"
- `com.treasurechase.coins3000` - $9.99 - "3,000 Coins"
- `com.treasurechase.coins10000` - $19.99 - "10,000 Coins"
- `com.treasurechase.starterbundle` - $4.99 - "Starter Bundle"
- `com.treasurechase.battlepass` - $4.99 - "Battle Pass"

**Important**: Product IDs are already set in `IAPManager.cs` - just create them in the store.

### 3.2 App Store Connect (iOS)
1. Go to App Store Connect
2. Your App → In-App Purchases
3. Create products with same IDs as above
4. Set prices in USD (same as Google Play)

**Note**: Apple requires screenshots + descriptions for each product.

---

## Step 4: Create Unity Scene Setup

### 4.1 Create Managers GameObject
1. Create empty GameObject: "Managers"
2. Add components:
   - `IAPManager.cs`
   - `UnityAdsManager.cs`
   - `EconomyManager` (already exists in StubScripts)
   - `AnalyticsManager` (already exists in StubScripts)

### 4.2 Configure IAPManager
**Inspector Settings**:
- Test Mode: ✅ (for sandbox testing)
- Debug Mode: ✅ (show logs)

### 4.3 Configure UnityAdsManager
**Inspector Settings**:
- Android Game ID: [YOUR_ANDROID_GAME_ID]
- iOS Game ID: [YOUR_IOS_GAME_ID]
- Rewarded Ad Unit ID: "Rewarded_Android" (or "Rewarded_iOS")
- Interstitial Ad Unit ID: "Interstitial_Android" (or "Interstitial_iOS")
- Interstitial Cooldown: 120 (2 minutes)
- Runs Before Interstitial: 3
- Test Mode: ✅
- Debug Mode: ✅

### 4.4 Configure GameOverController
**Inspector Settings**:
- Continue Button: [Assign UI Button]
- Double Coins Button: [Assign UI Button]
- Interstitial Frequency: 3

---

## Step 5: Test in Editor

### 5.1 Test IAP (Editor Only)
1. Play scene
2. Right-click `IAPManager` in Hierarchy
3. Select "Test: Buy Remove Ads"
4. Check console for: `[IAPManager] Ads disabled permanently`

### 5.2 Test Ads (Editor Simulation)
1. Play scene
2. Right-click `UnityAdsManager` in Hierarchy
3. Select "Test: Show Rewarded Ad"
4. Check console for: `[UnityAdsManager] Showing Rewarded Ad...`

**Note**: Real ads won't show in editor - only on device builds.

---

## Step 6: Test on Device (Sandbox Mode)

### 6.1 Android Test
1. Build and install APK on device
2. **Test Mode must be ON** (shows test ads)
3. Trigger game over → click "Continue" button
4. Watch test ad → verify player resurrects with shield

### 6.2 iOS Test
1. Build and install via TestFlight or Xcode
2. **Test Mode must be ON**
3. Same test as Android

### 6.3 IAP Sandbox Test
**Android**:
1. Add test account in Google Play Console
2. Sign in with test account on device
3. Attempt purchase → should show "Test Purchase"

**iOS**:
1. Settings → App Store → Sandbox Account
2. Sign in with sandbox account
3. Attempt purchase → should show sandbox popup

---

## Step 7: Production Build Checklist

### 7.1 Pre-Launch Settings
**IAPManager**:
- [ ] Test Mode: ❌ OFF
- [ ] Debug Mode: ❌ OFF (or leave ON for analytics)

**UnityAdsManager**:
- [ ] Test Mode: ❌ OFF
- [ ] Debug Mode: ❌ OFF (or leave ON for analytics)
- [ ] Game IDs: ✅ Correct production IDs
- [ ] Ad Unit IDs: ✅ Match Unity Dashboard

### 7.2 Build Settings
- [ ] Bundle ID matches store listings
- [ ] Version code incremented
- [ ] Target API 33+ (Android 13)
- [ ] 64-bit ARM support enabled
- [ ] IL2CPP scripting backend (not Mono)

### 7.3 Store Submission
- [ ] All IAP products created and approved
- [ ] Privacy policy updated (mentions IAP + Ads)
- [ ] Data Safety form filled (Google Play)
- [ ] Screenshots include monetization features

---

## Step 8: Analytics Verification

### 8.1 Events to Monitor
**IAP Events**:
- `iap_initialized` (fires on app start)
- `iap_purchase_attempt` (user clicks buy)
- `iap_purchase_success` (purchase complete)
- `iap_purchase_failed` (purchase failed)

**Ad Events**:
- `ads_initialized` (fires on app start)
- `rewarded_ad_show` (ad shown)
- `rewarded_ad_complete` (ad watched)
- `interstitial_ad_show` (interstitial shown)
- `ad_load_failed` (ad failed to load)

### 8.2 Revenue Events
Firebase Analytics will automatically track:
- `purchase` (IAP revenue)
- `ad_impression` (ad views)

**Check in Firebase Console**:
1. Analytics → Events → Look for events above
2. Monetization → Revenue → Should show IAP revenue
3. Monetization → AdMob → Should show ad revenue (if AdMob linked)

---

## Troubleshooting

### "IAP not initialized"
**Solution**:
- Verify Unity IAP package installed
- Check Unity Services are enabled
- Verify project is linked to Unity Project ID

### "Ads not showing"
**Solution**:
- Verify Unity Ads package installed
- Check game IDs are correct
- Ensure test mode is ON for testing
- Check internet connection (ads require network)

### "Purchase failed - Product not found"
**Solution**:
- Verify product IDs match store exactly
- Check products are published (not draft)
- Wait 24 hours after creating products (store propagation)

### "Rewarded ad not granting reward"
**Solution**:
- Check `OnUnityAdsShowComplete` callback
- Verify `showCompletionState == COMPLETED`
- Ensure `currentRewardedCallback?.Invoke(true)` is called

---

## Testing Checklist

### Functionality Tests
- [ ] IAP: Buy Remove Ads → Ads disabled
- [ ] IAP: Buy coin pack → Coins added
- [ ] IAP: Restore purchases (iOS) → Previous purchases restored
- [ ] Ads: Continue run → Rewarded ad → Player resurrects
- [ ] Ads: Double coins → Rewarded ad → Coins doubled
- [ ] Ads: Interstitial shows every 3rd game over
- [ ] Ads: Interstitial respects 2min cooldown
- [ ] Ads: Remove Ads IAP disables all ads

### Edge Cases
- [ ] Close ad early → No reward granted
- [ ] No internet → Graceful fallback
- [ ] Ad load failed → Retry automatically
- [ ] Battle Pass expires after 30 days

### Analytics
- [ ] Revenue events fire correctly
- [ ] Purchase events include transaction ID
- [ ] Ad events include placement ID

---

## Revenue Projections

**Target ARPDAU**: $0.03-$0.05

**Breakdown**:
- Ads (70%): $0.021-$0.035 per DAU
  - 3-5 ad impressions per session
  - eCPM: $8-$12 (rewarded), $4-$6 (interstitial)
- IAP (30%): $0.009-$0.015 per DAU
  - 2-3% conversion rate
  - ARPPU: $3-$5

**Optimization Tips**:
1. **Increase ad impressions**: Add power-up rewarded ads
2. **Increase IAP conversion**: Promote starter bundle on first game over
3. **Increase ARPPU**: Create limited-time coin pack sales
4. **Reduce churn**: Ensure Remove Ads IAP is visible and affordable

---

## Next Steps

After monetization is working:
1. **Vehicle Unlock System** → Drives coin spending
2. **Daily Rewards** → Boosts retention
3. **Battle Pass System** → Recurring revenue

---

**Setup complete! Ready to ship revenue-generating features. 🚀**
