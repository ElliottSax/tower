using UnityEngine;
using UnityEngine.Purchasing;
using UnityEngine.Purchasing.Extension;
using System;
using System.Collections.Generic;

namespace TreasureChase.Monetization
{
    /// <summary>
    /// Production-ready IAP Manager for Treasure Chase.
    /// Handles all in-app purchases: Remove Ads, Coin Packs, Starter Bundle.
    ///
    /// Revenue Target: 30% of total ($0.009-$0.015 per DAU)
    /// Expected Conversion: 2-3%
    /// </summary>
    public class IAPManager : MonoBehaviour, IDetailedStoreListener
    {
        public static IAPManager Instance { get; private set; }

        [Header("IAP Settings")]
        [Tooltip("Enable test mode for sandbox purchases")]
        public bool testMode = true;

        [Tooltip("Show purchase logs in console")]
        public bool debugMode = true;

        // Product IDs (match Google Play Console & App Store Connect)
        public const string REMOVE_ADS = "com.treasurechase.removeads";
        public const string COINS_100 = "com.treasurechase.coins100";
        public const string COINS_500 = "com.treasurechase.coins500";
        public const string COINS_1200 = "com.treasurechase.coins1200";
        public const string COINS_3000 = "com.treasurechase.coins3000";
        public const string COINS_10000 = "com.treasurechase.coins10000";
        public const string STARTER_BUNDLE = "com.treasurechase.starterbundle";
        public const string BATTLE_PASS = "com.treasurechase.battlepass";

        // Pricing reference (actual prices set in stores)
        private Dictionary<string, float> productPrices = new Dictionary<string, float>
        {
            { REMOVE_ADS, 2.99f },
            { COINS_100, 0.99f },
            { COINS_500, 2.99f },
            { COINS_1200, 4.99f },
            { COINS_3000, 9.99f },
            { COINS_10000, 19.99f },
            { STARTER_BUNDLE, 4.99f },
            { BATTLE_PASS, 4.99f }
        };

        // Coin amounts for each pack
        private Dictionary<string, int> coinRewards = new Dictionary<string, int>
        {
            { COINS_100, 100 },
            { COINS_500, 500 },
            { COINS_1200, 1200 },
            { COINS_3000, 3000 },
            { COINS_10000, 10000 },
            { STARTER_BUNDLE, 500 } // Starter bundle also includes vehicle unlock
        };

        // Unity IAP
        private IStoreController storeController;
        private IExtensionProvider extensionProvider;
        private bool isInitialized = false;

        // Events
        public event Action<string> OnPurchaseSuccess;
        public event Action<string> OnPurchaseFailed;
        public event Action OnStoreInitialized;

        // State tracking
        private bool adsRemoved = false;
        private bool hasBattlePass = false;

        #region Unity Lifecycle

        void Awake()
        {
            // Singleton pattern
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            // Load purchase state
            LoadPurchaseState();
        }

        void Start()
        {
            // Initialize Unity IAP
            InitializeStore();
        }

        #endregion

        #region Store Initialization

        /// <summary>
        /// Initialize Unity IAP with all products
        /// </summary>
        void InitializeStore()
        {
            if (isInitialized)
            {
                DebugLog("Store already initialized");
                return;
            }

            var builder = ConfigurationBuilder.Instance(StandardPurchasingModule.Instance());

            // Add non-consumable products
            builder.AddProduct(REMOVE_ADS, ProductType.NonConsumable);
            builder.AddProduct(BATTLE_PASS, ProductType.NonConsumable); // Reset monthly via server

            // Add consumable products
            builder.AddProduct(COINS_100, ProductType.Consumable);
            builder.AddProduct(COINS_500, ProductType.Consumable);
            builder.AddProduct(COINS_1200, ProductType.Consumable);
            builder.AddProduct(COINS_3000, ProductType.Consumable);
            builder.AddProduct(COINS_10000, ProductType.Consumable);
            builder.AddProduct(STARTER_BUNDLE, ProductType.Consumable);

            // Initialize
            UnityPurchasing.Initialize(this, builder);

            DebugLog("Initializing Unity IAP...");
        }

        /// <summary>
        /// Called when IAP initialization succeeds
        /// </summary>
        public void OnInitialized(IStoreController controller, IExtensionProvider extensions)
        {
            storeController = controller;
            extensionProvider = extensions;
            isInitialized = true;

            DebugLog("✅ IAP Initialized Successfully!");

            // Restore purchases (iOS requirement)
            RestorePurchases();

            // Fire event
            OnStoreInitialized?.Invoke();

            // Log to analytics
            LogAnalytics("iap_initialized", new Dictionary<string, object>
            {
                { "product_count", storeController.products.all.Length }
            });
        }

        /// <summary>
        /// Called when IAP initialization fails
        /// </summary>
        public void OnInitializeFailed(InitializationFailureReason error)
        {
            DebugLog($"❌ IAP Initialization Failed: {error}");

            // Log to analytics
            LogAnalytics("iap_init_failed", new Dictionary<string, object>
            {
                { "error", error.ToString() }
            });
        }

        public void OnInitializeFailed(InitializationFailureReason error, string message)
        {
            DebugLog($"❌ IAP Initialization Failed: {error} - {message}");

            LogAnalytics("iap_init_failed", new Dictionary<string, object>
            {
                { "error", error.ToString() },
                { "message", message }
            });
        }

        #endregion

        #region Purchase Flow

        /// <summary>
        /// Purchase a product by ID
        /// </summary>
        public void BuyProduct(string productId)
        {
            if (!isInitialized)
            {
                DebugLog("Cannot purchase - store not initialized");
                OnPurchaseFailed?.Invoke(productId);
                return;
            }

            var product = storeController.products.WithID(productId);

            if (product != null && product.availableToPurchase)
            {
                DebugLog($"Purchasing {productId}...");
                storeController.InitiatePurchase(product);

                // Log purchase attempt
                LogAnalytics("iap_purchase_attempt", new Dictionary<string, object>
                {
                    { "product_id", productId },
                    { "price", product.metadata.localizedPriceString }
                });
            }
            else
            {
                DebugLog($"Product {productId} not available for purchase");
                OnPurchaseFailed?.Invoke(productId);
            }
        }

        /// <summary>
        /// Called when purchase succeeds
        /// </summary>
        public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
        {
            string productId = args.purchasedProduct.definition.id;

            DebugLog($"✅ Purchase Successful: {productId}");

            // Grant rewards based on product
            GrantPurchaseReward(productId);

            // Save purchase state
            SavePurchaseState(productId);

            // Fire success event
            OnPurchaseSuccess?.Invoke(productId);

            // Log to analytics
            LogPurchaseAnalytics(args.purchasedProduct);

            return PurchaseProcessingResult.Complete;
        }

        /// <summary>
        /// Called when purchase fails
        /// </summary>
        public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)
        {
            DebugLog($"❌ Purchase Failed: {product.definition.id} - {failureReason}");

            OnPurchaseFailed?.Invoke(product.definition.id);

            // Log to analytics
            LogAnalytics("iap_purchase_failed", new Dictionary<string, object>
            {
                { "product_id", product.definition.id },
                { "reason", failureReason.ToString() }
            });
        }

        public void OnPurchaseFailed(Product product, PurchaseFailureDescription failureDescription)
        {
            DebugLog($"❌ Purchase Failed: {product.definition.id} - {failureDescription.reason}");
            DebugLog($"   Message: {failureDescription.message}");

            OnPurchaseFailed?.Invoke(product.definition.id);

            LogAnalytics("iap_purchase_failed", new Dictionary<string, object>
            {
                { "product_id", product.definition.id },
                { "reason", failureDescription.reason.ToString() },
                { "message", failureDescription.message }
            });
        }

        #endregion

        #region Reward Granting

        /// <summary>
        /// Grant rewards for purchased product
        /// </summary>
        void GrantPurchaseReward(string productId)
        {
            switch (productId)
            {
                case REMOVE_ADS:
                    GrantRemoveAds();
                    break;

                case BATTLE_PASS:
                    GrantBattlePass();
                    break;

                case STARTER_BUNDLE:
                    GrantStarterBundle();
                    break;

                default:
                    // Coin pack
                    if (coinRewards.ContainsKey(productId))
                    {
                        GrantCoins(coinRewards[productId], productId);
                    }
                    break;
            }
        }

        /// <summary>
        /// Grant Remove Ads permanent upgrade
        /// </summary>
        void GrantRemoveAds()
        {
            adsRemoved = true;

            // Disable ads
            var adsManager = FindObjectOfType<AdsManager>();
            if (adsManager != null)
            {
                // AdsManager will check IAPManager.HasRemovedAds()
                DebugLog("Ads disabled permanently");
            }

            // Show confirmation
            ShowPurchaseConfirmation("Ads Removed!", "Enjoy uninterrupted gameplay!");

            // Unlock achievement
            var achievementSystem = FindObjectOfType<AchievementSystem>();
            if (achievementSystem != null)
            {
                achievementSystem.UnlockAchievement("remove_ads_purchased");
            }
        }

        /// <summary>
        /// Grant Battle Pass access
        /// </summary>
        void GrantBattlePass()
        {
            hasBattlePass = true;

            // Enable battle pass (check expiration via server timestamp later)
            var battlePassSystem = FindObjectOfType<BattlePassSystem>();
            if (battlePassSystem != null)
            {
                battlePassSystem.ActivatePremiumPass();
            }

            ShowPurchaseConfirmation("Battle Pass Activated!", "Unlock exclusive rewards!");

            var achievementSystem = FindObjectOfType<AchievementSystem>();
            if (achievementSystem != null)
            {
                achievementSystem.UnlockAchievement("battle_pass_purchased");
            }
        }

        /// <summary>
        /// Grant Starter Bundle rewards
        /// </summary>
        void GrantStarterBundle()
        {
            // Give 500 coins
            GrantCoins(500, STARTER_BUNDLE);

            // Unlock second vehicle
            var vehicleSystem = FindObjectOfType<VehicleUnlockSystem>();
            if (vehicleSystem != null)
            {
                vehicleSystem.UnlockVehicle(1); // Index 1 = second vehicle
            }

            ShowPurchaseConfirmation("Starter Bundle Received!", "500 coins + Bonus Vehicle!");
        }

        /// <summary>
        /// Grant coins to player
        /// </summary>
        void GrantCoins(int amount, string source)
        {
            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(amount);
                DebugLog($"Granted {amount} coins from {source}");
            }

            ShowPurchaseConfirmation($"+{amount} Coins!", "Thank you for your purchase!");
        }

        #endregion

        #region Restore Purchases

        /// <summary>
        /// Restore previous purchases (iOS requirement)
        /// </summary>
        public void RestorePurchases()
        {
            if (!isInitialized)
            {
                DebugLog("Cannot restore - store not initialized");
                return;
            }

            // iOS only (Android restores automatically)
            if (Application.platform == RuntimePlatform.IPhonePlayer)
            {
                DebugLog("Restoring purchases...");

                var apple = extensionProvider.GetExtension<IAppleExtensions>();
                apple.RestoreTransactions((result, error) =>
                {
                    if (result)
                    {
                        DebugLog("✅ Restore successful");
                        ShowPurchaseConfirmation("Purchases Restored", "Previous purchases have been restored");
                    }
                    else
                    {
                        DebugLog($"❌ Restore failed: {error}");
                    }
                });
            }

            // Also check local state
            CheckPurchaseState();
        }

        /// <summary>
        /// Check purchase state from PlayerPrefs
        /// </summary>
        void CheckPurchaseState()
        {
            adsRemoved = PlayerPrefs.GetInt("ads_removed", 0) == 1;
            hasBattlePass = PlayerPrefs.GetInt("has_battle_pass", 0) == 1;

            DebugLog($"Purchase State - Ads Removed: {adsRemoved}, Battle Pass: {hasBattlePass}");
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Save purchase state to PlayerPrefs
        /// </summary>
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

        /// <summary>
        /// Load purchase state from PlayerPrefs
        /// </summary>
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
                    TimeSpan elapsed = DateTime.UtcNow - purchaseDate;

                    if (elapsed.TotalDays > 30)
                    {
                        hasBattlePass = false;
                        PlayerPrefs.SetInt("has_battle_pass", 0);
                        DebugLog("Battle Pass expired (30 days)");
                    }
                }
            }
        }

        #endregion

        #region Public API

        /// <summary>
        /// Check if ads have been removed
        /// </summary>
        public bool HasRemovedAds() => adsRemoved;

        /// <summary>
        /// Check if player has active battle pass
        /// </summary>
        public bool HasBattlePass() => hasBattlePass;

        /// <summary>
        /// Get localized price string for product
        /// </summary>
        public string GetProductPrice(string productId)
        {
            if (!isInitialized)
                return productPrices.ContainsKey(productId) ? $"${productPrices[productId]:F2}" : "$??.??";

            var product = storeController.products.WithID(productId);
            return product?.metadata.localizedPriceString ?? "$??.??";
        }

        /// <summary>
        /// Check if product is available for purchase
        /// </summary>
        public bool IsProductAvailable(string productId)
        {
            if (!isInitialized)
                return false;

            var product = storeController.products.WithID(productId);
            return product != null && product.availableToPurchase;
        }

        /// <summary>
        /// Get product metadata
        /// </summary>
        public ProductMetadata GetProductMetadata(string productId)
        {
            if (!isInitialized)
                return null;

            var product = storeController.products.WithID(productId);
            return product?.metadata;
        }

        #endregion

        #region Analytics

        /// <summary>
        /// Log purchase analytics (revenue tracking)
        /// </summary>
        void LogPurchaseAnalytics(Product product)
        {
            // Extract revenue value
            decimal price = product.metadata.localizedPrice;
            string currency = product.metadata.isoCurrencyCode;

            LogAnalytics("iap_purchase_success", new Dictionary<string, object>
            {
                { "product_id", product.definition.id },
                { "price", price.ToString() },
                { "currency", currency },
                { "transaction_id", product.transactionID }
            });

            // Firebase Analytics revenue event
            var analyticsManager = FindObjectOfType<AnalyticsManager>();
            if (analyticsManager != null)
            {
                // Firebase.Analytics.FirebaseAnalytics.LogEvent("purchase", ...) in production
            }
        }

        #endregion

        #region UI Feedback

        /// <summary>
        /// Show purchase confirmation UI
        /// </summary>
        void ShowPurchaseConfirmation(string title, string message)
        {
            // Show popup (integrate with UI system)
            Debug.Log($"[PURCHASE CONFIRMED] {title}: {message}");

            // TODO: Show actual UI popup
            // var uiManager = FindObjectOfType<UIManager>();
            // uiManager?.ShowPopup(title, message, "OK");
        }

        #endregion

        #region Utilities

        void DebugLog(string message)
        {
            if (debugMode)
            {
                Debug.Log($"[IAPManager] {message}");
            }
        }

        void LogAnalytics(string eventName, Dictionary<string, object> parameters)
        {
            var analyticsManager = FindObjectOfType<AnalyticsManager>();
            if (analyticsManager != null)
            {
                analyticsManager.LogEvent(eventName, parameters);
            }
        }

        #endregion

        #region Test Methods (Editor Only)

#if UNITY_EDITOR
        /// <summary>
        /// Simulate purchase success (for testing in editor)
        /// </summary>
        [ContextMenu("Test: Buy Remove Ads")]
        public void TestBuyRemoveAds()
        {
            GrantRemoveAds();
            SavePurchaseState(REMOVE_ADS);
        }

        [ContextMenu("Test: Buy 500 Coins")]
        public void TestBuy500Coins()
        {
            GrantCoins(500, COINS_500);
        }

        [ContextMenu("Test: Reset Purchases")]
        public void TestResetPurchases()
        {
            PlayerPrefs.DeleteKey("ads_removed");
            PlayerPrefs.DeleteKey("has_battle_pass");
            PlayerPrefs.Save();
            LoadPurchaseState();
            Debug.Log("Purchases reset");
        }
#endif

        #endregion
    }

    // Stub systems (replace with real implementations)
    public class BattlePassSystem : MonoBehaviour
    {
        public void ActivatePremiumPass()
        {
            Debug.Log("[STUB] BattlePassSystem.ActivatePremiumPass");
        }
    }

    public class VehicleUnlockSystem : MonoBehaviour
    {
        public void UnlockVehicle(int index)
        {
            Debug.Log($"[STUB] VehicleUnlockSystem.UnlockVehicle: {index}");
        }
    }
}
