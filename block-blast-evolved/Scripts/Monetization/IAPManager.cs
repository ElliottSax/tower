using UnityEngine;
using UnityEngine.Purchasing;
using UnityEngine.Purchasing.Extension;
using System;
using System.Collections.Generic;

namespace BlockBlastEvolved.Monetization
{
    /// <summary>
    /// Production-ready IAP Manager for Block Blast Evolved.
    /// Handles all in-app purchases: Remove Ads, Gem Packs, Hero Bundles.
    ///
    /// Revenue Target: 30% of total revenue
    /// Expected Conversion: 2-3% of DAU
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
        public const string REMOVE_ADS = "com.blockblast.removeads";
        public const string GEMS_100 = "com.blockblast.gems100";
        public const string GEMS_500 = "com.blockblast.gems500";
        public const string GEMS_1200 = "com.blockblast.gems1200";
        public const string GEMS_3000 = "com.blockblast.gems3000";
        public const string GEMS_10000 = "com.blockblast.gems10000";
        public const string STARTER_BUNDLE = "com.blockblast.starterbundle";
        public const string HERO_BUNDLE = "com.blockblast.herobundle";

        // Pricing reference (actual prices set in stores)
        private Dictionary<string, float> productPrices = new Dictionary<string, float>
        {
            { REMOVE_ADS, 2.99f },
            { GEMS_100, 0.99f },
            { GEMS_500, 2.99f },
            { GEMS_1200, 4.99f },
            { GEMS_3000, 9.99f },
            { GEMS_10000, 19.99f },
            { STARTER_BUNDLE, 4.99f },
            { HERO_BUNDLE, 7.99f }
        };

        // Gem amounts for each pack
        private Dictionary<string, int> gemRewards = new Dictionary<string, int>
        {
            { GEMS_100, 100 },
            { GEMS_500, 550 },      // 10% bonus
            { GEMS_1200, 1320 },    // 10% bonus
            { GEMS_3000, 3300 },    // 10% bonus
            { GEMS_10000, 11000 },  // 10% bonus
            { STARTER_BUNDLE, 500 },
            { HERO_BUNDLE, 1000 }
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

            // Add consumable products
            builder.AddProduct(GEMS_100, ProductType.Consumable);
            builder.AddProduct(GEMS_500, ProductType.Consumable);
            builder.AddProduct(GEMS_1200, ProductType.Consumable);
            builder.AddProduct(GEMS_3000, ProductType.Consumable);
            builder.AddProduct(GEMS_10000, ProductType.Consumable);
            builder.AddProduct(STARTER_BUNDLE, ProductType.Consumable);
            builder.AddProduct(HERO_BUNDLE, ProductType.Consumable);

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

                case STARTER_BUNDLE:
                    GrantStarterBundle();
                    break;

                case HERO_BUNDLE:
                    GrantHeroBundle();
                    break;

                default:
                    // Gem pack
                    if (gemRewards.ContainsKey(productId))
                    {
                        GrantGems(gemRewards[productId], productId);
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

            DebugLog("Ads disabled permanently");

            ShowPurchaseConfirmation("Ads Removed!", "Enjoy uninterrupted gameplay!");

            // Play celebration effect
            if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("purchase", Vector3.zero);
            }

            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("purchase_success");
            }
        }

        /// <summary>
        /// Grant Starter Bundle rewards
        /// </summary>
        void GrantStarterBundle()
        {
            // Give 500 gems
            GrantGems(500, STARTER_BUNDLE);

            // Unlock rare hero
            var heroSystem = HeroSystem.Instance;
            if (heroSystem != null)
            {
                // Find first locked rare hero
                foreach (var hero in heroSystem.allHeroes)
                {
                    if (hero.rarity == HeroRarity.Rare && !heroSystem.GetUnlockedHeroes().Contains(hero))
                    {
                        heroSystem.UnlockHero(hero.heroId);
                        ShowPurchaseConfirmation("Starter Bundle!", $"500 gems + {hero.heroName} unlocked!");
                        return;
                    }
                }
            }

            ShowPurchaseConfirmation("Starter Bundle!", "500 gems received!");
        }

        /// <summary>
        /// Grant Hero Bundle rewards
        /// </summary>
        void GrantHeroBundle()
        {
            // Give 1000 gems
            GrantGems(1000, HERO_BUNDLE);

            // Unlock epic hero
            var heroSystem = HeroSystem.Instance;
            if (heroSystem != null)
            {
                // Find first locked epic hero
                foreach (var hero in heroSystem.allHeroes)
                {
                    if (hero.rarity == HeroRarity.Epic && !heroSystem.GetUnlockedHeroes().Contains(hero))
                    {
                        heroSystem.UnlockHero(hero.heroId);
                        ShowPurchaseConfirmation("Hero Bundle!", $"1000 gems + {hero.heroName} unlocked!");
                        return;
                    }
                }
            }

            ShowPurchaseConfirmation("Hero Bundle!", "1000 gems received!");
        }

        /// <summary>
        /// Grant gems to player
        /// </summary>
        void GrantGems(int amount, string source)
        {
            var economyManager = EconomyManager.Instance;
            if (economyManager != null)
            {
                economyManager.AddGems(amount);
                DebugLog($"Granted {amount} gems from {source}");
            }

            ShowPurchaseConfirmation($"+{amount} Gems!", "Thank you for your purchase!");

            // Play celebration effect
            if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("gems", Vector3.zero);
            }

            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("gems_collect");
            }
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
            DebugLog($"Purchase State - Ads Removed: {adsRemoved}");
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
                PlayerPrefs.Save();
            }
        }

        /// <summary>
        /// Load purchase state from PlayerPrefs
        /// </summary>
        void LoadPurchaseState()
        {
            adsRemoved = PlayerPrefs.GetInt("ads_removed", 0) == 1;
        }

        #endregion

        #region Public API

        /// <summary>
        /// Check if ads have been removed
        /// </summary>
        public bool HasRemovedAds() => adsRemoved;

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
        }

        #endregion

        #region UI Feedback

        /// <summary>
        /// Show purchase confirmation UI
        /// </summary>
        void ShowPurchaseConfirmation(string title, string message)
        {
            Debug.Log($"[PURCHASE CONFIRMED] {title}: {message}");

            // TODO: Integrate with UI system when available
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
            // TODO: Integrate with analytics system when available
            DebugLog($"Analytics: {eventName}");
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

        [ContextMenu("Test: Buy 500 Gems")]
        public void TestBuy500Gems()
        {
            GrantGems(500, GEMS_500);
        }

        [ContextMenu("Test: Buy Starter Bundle")]
        public void TestBuyStarterBundle()
        {
            GrantStarterBundle();
        }

        [ContextMenu("Test: Reset Purchases")]
        public void TestResetPurchases()
        {
            PlayerPrefs.DeleteKey("ads_removed");
            PlayerPrefs.Save();
            LoadPurchaseState();
            Debug.Log("Purchases reset");
        }
#endif

        #endregion
    }
}
