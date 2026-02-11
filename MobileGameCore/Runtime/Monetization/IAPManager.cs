using UnityEngine;
#if UNITY_PURCHASING
using UnityEngine.Purchasing;
using UnityEngine.Purchasing.Extension;
#endif

namespace MobileGameCore
{
    /// <summary>
    /// Manages In-App Purchases using Unity IAP.
    /// Supports consumables, non-consumables, and subscriptions.
    ///
    /// REVENUE IMPACT: Primary monetization for premium features
    ///
    /// SETUP:
    /// 1. Install Unity IAP package (com.unity.purchasing)
    /// 2. Enable IAP in Services window
    /// 3. Configure products in this script or inspector
    /// 4. Set up products in App Store Connect / Google Play Console
    ///
    /// USAGE:
    /// IAPManager.Instance.PurchaseProduct("com.yourgame.gems_100", (success, productId) => {
    ///     if (success) {
    ///         // Grant gems, save to SaveSystem
    ///         EconomyManager.Instance.AddCurrency("gems", 100);
    ///         SaveSystem.Instance.Save();
    ///     }
    /// });
    ///
    /// PRODUCT TYPES:
    /// - Consumable: Can purchase multiple times (currency packs, power-ups)
    /// - Non-Consumable: Purchase once (ad removal, permanent upgrades)
    /// - Subscription: Recurring (VIP membership, season pass)
    /// </summary>
#if UNITY_PURCHASING
    public class IAPManager : MonoBehaviour, IStoreListener
#else
    public class IAPManager : MonoBehaviour
#endif
    {
        public static IAPManager Instance { get; private set; }

        [System.Serializable]
        public class ProductDefinition
        {
            public string productId;
            public ProductType productType;
            public string localizedTitle;
            public string localizedDescription;
            public int rewardAmount; // For currency packs
            public string rewardType; // "gems", "coins", etc.
        }

        [Header("Product Catalog")]
        [SerializeField] private ProductDefinition[] products = new ProductDefinition[]
        {
            // Currency Packs (Consumable)
            new ProductDefinition
            {
                productId = "com.yourgame.gems_100",
                productType = ProductType.Consumable,
                localizedTitle = "Small Gem Pack",
                localizedDescription = "100 Gems",
                rewardAmount = 100,
                rewardType = "gems"
            },
            new ProductDefinition
            {
                productId = "com.yourgame.gems_500",
                productType = ProductType.Consumable,
                localizedTitle = "Medium Gem Pack",
                localizedDescription = "500 Gems + 50 Bonus",
                rewardAmount = 550,
                rewardType = "gems"
            },
            new ProductDefinition
            {
                productId = "com.yourgame.gems_1000",
                productType = ProductType.Consumable,
                localizedTitle = "Large Gem Pack",
                localizedDescription = "1000 Gems + 200 Bonus",
                rewardAmount = 1200,
                rewardType = "gems"
            },

            // Non-Consumables
            new ProductDefinition
            {
                productId = "com.yourgame.remove_ads",
                productType = ProductType.NonConsumable,
                localizedTitle = "Remove Ads",
                localizedDescription = "Remove all ads forever",
                rewardAmount = 0,
                rewardType = "remove_ads"
            },

            // Subscriptions
            new ProductDefinition
            {
                productId = "com.yourgame.vip_monthly",
                productType = ProductType.Subscription,
                localizedTitle = "VIP Membership",
                localizedDescription = "2x rewards, exclusive items, no ads",
                rewardAmount = 0,
                rewardType = "vip"
            }
        };

        [Header("Settings")]
        [SerializeField] private bool enableDebugLogs = true;

#if UNITY_PURCHASING
        private IStoreController storeController;
        private IExtensionProvider extensionProvider;
#endif
        private bool isInitialized = false;
        private System.Action<bool, string> currentPurchaseCallback;

        void Awake()
        {
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
        }

        void Start()
        {
            InitializeIAP();
        }

        public void InitializeIAP()
        {
#if UNITY_PURCHASING
            if (isInitialized)
            {
                LogDebug("IAP already initialized");
                return;
            }

            LogDebug("Initializing Unity IAP...");

            var builder = ConfigurationBuilder.Instance(StandardPurchasingModule.Instance());

            // Add all products from catalog
            foreach (var product in products)
            {
                builder.AddProduct(product.productId, product.productType);
                LogDebug($"Added product: {product.productId} ({product.productType})");
            }

            UnityPurchasing.Initialize(this, builder);
#else
            Debug.LogWarning("[IAPManager] Unity IAP package not installed. Install via Package Manager.");
#endif
        }

        /// <summary>
        /// Purchase a product by ID. Callback returns (success, productId).
        /// </summary>
        public void PurchaseProduct(string productId, System.Action<bool, string> callback)
        {
#if UNITY_PURCHASING
            if (!isInitialized)
            {
                LogDebug("IAP not initialized yet");
                callback?.Invoke(false, productId);
                return;
            }

            currentPurchaseCallback = callback;

            var product = storeController.products.WithID(productId);
            if (product != null && product.availableToPurchase)
            {
                LogDebug($"Purchasing: {productId}");
                storeController.InitiatePurchase(product);

                // Track purchase attempt
                if (AnalyticsManager.Instance != null)
                {
                    AnalyticsManager.Instance.LogEvent("iap_purchase_initiated", new System.Collections.Generic.Dictionary<string, object>
                    {
                        { "product_id", productId },
                        { "product_type", product.definition.type.ToString() },
                        { "price", product.metadata.localizedPrice }
                    });
                }
            }
            else
            {
                LogDebug($"Product not available: {productId}");
                callback?.Invoke(false, productId);
            }
#else
            Debug.LogWarning("[IAPManager] Unity IAP not available");
            callback?.Invoke(false, productId);
#endif
        }

        /// <summary>
        /// Restore purchases (iOS requirement for non-consumables and subscriptions).
        /// </summary>
        public void RestorePurchases(System.Action<bool> callback)
        {
#if UNITY_PURCHASING && UNITY_IOS
            if (!isInitialized)
            {
                callback?.Invoke(false);
                return;
            }

            LogDebug("Restoring purchases...");

            var apple = extensionProvider.GetExtension<IAppleExtensions>();
            apple.RestoreTransactions((result) =>
            {
                LogDebug($"Restore purchases result: {result}");
                callback?.Invoke(result);

                if (AnalyticsManager.Instance != null)
                {
                    AnalyticsManager.Instance.LogEvent("iap_restore_purchases", new System.Collections.Generic.Dictionary<string, object>
                    {
                        { "success", result }
                    });
                }
            });
#else
            LogDebug("Restore purchases only available on iOS");
            callback?.Invoke(false);
#endif
        }

        /// <summary>
        /// Check if a product has been purchased (for non-consumables).
        /// </summary>
        public bool HasPurchased(string productId)
        {
#if UNITY_PURCHASING
            if (!isInitialized) return false;

            var product = storeController.products.WithID(productId);
            if (product != null)
            {
                return product.hasReceipt;
            }
#endif
            return false;
        }

        /// <summary>
        /// Get localized price string for a product.
        /// </summary>
        public string GetLocalizedPrice(string productId)
        {
#if UNITY_PURCHASING
            if (!isInitialized) return "$?.??";

            var product = storeController.products.WithID(productId);
            if (product != null && product.metadata != null)
            {
                return product.metadata.localizedPriceString;
            }
#endif
            return "$?.??";
        }

        /// <summary>
        /// Get product metadata (title, description, price).
        /// </summary>
        public ProductDefinition GetProductDefinition(string productId)
        {
            foreach (var product in products)
            {
                if (product.productId == productId)
                    return product;
            }
            return null;
        }

#if UNITY_PURCHASING
        #region IStoreListener Implementation

        public void OnInitialized(IStoreController controller, IExtensionProvider extensions)
        {
            LogDebug("IAP initialization successful!");
            storeController = controller;
            extensionProvider = extensions;
            isInitialized = true;

            // Track successful initialization
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.LogEvent("iap_initialized");
            }
        }

        public void OnInitializeFailed(InitializationFailureReason error)
        {
            LogDebug($"IAP initialization failed: {error}");
            isInitialized = false;

            // Track failure
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.LogEvent("iap_init_failed", new System.Collections.Generic.Dictionary<string, object>
                {
                    { "reason", error.ToString() }
                });
            }
        }

        public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
        {
            var productId = args.purchasedProduct.definition.id;
            LogDebug($"Purchase successful: {productId}");

            // Find product definition
            var productDef = GetProductDefinition(productId);
            if (productDef != null)
            {
                // Grant rewards based on product type
                if (productDef.rewardType == "gems" || productDef.rewardType == "coins")
                {
                    if (EconomyManager.Instance != null)
                    {
                        EconomyManager.Instance.AddCurrency(productDef.rewardType, productDef.rewardAmount);
                        LogDebug($"Granted {productDef.rewardAmount} {productDef.rewardType}");
                    }
                }
                else if (productDef.rewardType == "remove_ads")
                {
                    if (SaveSystem.Instance != null)
                    {
                        SaveSystem.Instance.SetCustomData("ads_removed", true);
                        SaveSystem.Instance.Save();
                        LogDebug("Ads removed permanently");
                    }
                }
                else if (productDef.rewardType == "vip")
                {
                    if (SaveSystem.Instance != null)
                    {
                        SaveSystem.Instance.SetCustomData("vip_active", true);
                        SaveSystem.Instance.Save();
                        LogDebug("VIP membership activated");
                    }
                }
            }

            // Track successful purchase
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.LogPurchase(
                    productId,
                    (double)args.purchasedProduct.metadata.localizedPrice,
                    args.purchasedProduct.metadata.isoCurrencyCode
                );
            }

            // Save after purchase
            if (SaveSystem.Instance != null)
            {
                SaveSystem.Instance.Save();
            }

            currentPurchaseCallback?.Invoke(true, productId);
            currentPurchaseCallback = null;

            return PurchaseProcessingResult.Complete;
        }

        public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)
        {
            LogDebug($"Purchase failed: {product.definition.id}, Reason: {failureReason}");

            // Track failure
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.LogEvent("iap_purchase_failed", new System.Collections.Generic.Dictionary<string, object>
                {
                    { "product_id", product.definition.id },
                    { "reason", failureReason.ToString() }
                });
            }

            currentPurchaseCallback?.Invoke(false, product.definition.id);
            currentPurchaseCallback = null;
        }

        #endregion
#endif

        private void LogDebug(string message)
        {
            if (enableDebugLogs)
            {
                Debug.Log($"[IAPManager] {message}");
            }
        }
    }
}
