using UnityEngine;
using System.Collections.Generic;

namespace MobileGameCore
{
    /// <summary>
    /// Manages game economy: currencies, purchases, unlocks, and upgrade system.
    /// Interfaces with SaveSystem for persistence.
    ///
    /// USAGE:
    /// - Currency: EconomyManager.Instance.AddCurrency("coins", 100);
    /// - Purchase: EconomyManager.Instance.SpendCurrency("coins", 50, "item_name");
    /// - Unlocks: EconomyManager.Instance.UnlockItem("item_id", cost, "coins");
    /// - Upgrades: EconomyManager.Instance.PurchaseUpgrade("speed_upgrade", currentLevel, cost, "coins");
    /// </summary>
    public class EconomyManager : MonoBehaviour
    {
        public static EconomyManager Instance { get; private set; }

        [Header("Currency Configuration")]
        [SerializeField] private CurrencyConfig[] currencies;

        [Header("Unlockable Items")]
        [SerializeField] private UnlockableItem[] availableItems;

        [Header("Upgrade Configuration")]
        [SerializeField] private UpgradeData[] availableUpgrades;

        [Header("Reward Settings")]
        [SerializeField] private int rewardPerAd = 50; // Default reward for watching ads

        // Events
        public System.Action<string, int> OnCurrencyChanged; // (currencyType, newAmount)
        public System.Action<string> OnItemUnlocked; // (itemId)
        public System.Action<string, int> OnUpgradePurchased; // (upgradeId, newLevel)

        private Dictionary<string, int> purchasedUpgrades = new Dictionary<string, int>();

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
            LoadPurchasedUpgrades();
        }

        #region Currency Management

        /// <summary>
        /// Get current amount of currency
        /// </summary>
        public int GetCurrency(string currencyType = "coins")
        {
            if (SaveSystem.Instance != null)
            {
                return SaveSystem.Instance.GetCurrency(currencyType);
            }
            return 0;
        }

        /// <summary>
        /// Add currency to player account
        /// </summary>
        public void AddCurrency(string currencyType, int amount)
        {
            if (amount <= 0)
            {
                Debug.LogWarning($"[EconomyManager] Invalid currency amount: {amount}");
                return;
            }

            if (SaveSystem.Instance != null)
            {
                SaveSystem.Instance.AddCurrency(currencyType, amount);
                int newAmount = GetCurrency(currencyType);
                OnCurrencyChanged?.Invoke(currencyType, newAmount);
                Debug.Log($"[EconomyManager] {currencyType} added: +{amount} (Total: {newAmount})");
            }
        }

        /// <summary>
        /// Spend currency if player has enough
        /// </summary>
        public bool SpendCurrency(string currencyType, int amount, string itemName = "")
        {
            if (amount <= 0)
            {
                Debug.LogWarning($"[EconomyManager] Invalid currency amount: {amount}");
                return false;
            }

            if (SaveSystem.Instance != null)
            {
                bool success = SaveSystem.Instance.SpendCurrency(currencyType, amount);

                if (success)
                {
                    int newAmount = GetCurrency(currencyType);
                    OnCurrencyChanged?.Invoke(currencyType, newAmount);
                    Debug.Log($"[EconomyManager] {currencyType} spent: -{amount} (Remaining: {newAmount}) - {itemName}");

                    // Track purchase
                    if (AnalyticsManager.Instance != null && !string.IsNullOrEmpty(itemName))
                    {
                        AnalyticsManager.Instance.TrackPurchase(itemName, amount, currencyType);
                    }
                }
                else
                {
                    Debug.LogWarning($"[EconomyManager] Not enough {currencyType}! Required: {amount}, Available: {GetCurrency(currencyType)}");
                }

                return success;
            }

            return false;
        }

        /// <summary>
        /// Check if player can afford purchase
        /// </summary>
        public bool CanAfford(string currencyType, int cost)
        {
            return GetCurrency(currencyType) >= cost;
        }

        /// <summary>
        /// Reward currency for watching rewarded ad
        /// </summary>
        public void RewardCurrencyFromAd(string currencyType = "coins", int amount = 0)
        {
            int rewardAmount = amount > 0 ? amount : rewardPerAd;
            AddCurrency(currencyType, rewardAmount);

            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.TrackAdReward(currencyType, rewardAmount);
            }

            Debug.Log($"[EconomyManager] Rewarded {rewardAmount} {currencyType} from ad");
        }

        #endregion

        #region Item Unlocks (Generic System)

        /// <summary>
        /// Check if item is unlocked
        /// </summary>
        public bool IsItemUnlocked(string itemId)
        {
            if (SaveSystem.Instance != null)
            {
                return SaveSystem.Instance.IsUnlocked(itemId);
            }
            return false;
        }

        /// <summary>
        /// Purchase/unlock item
        /// </summary>
        public bool UnlockItem(string itemId, int cost, string currencyType = "coins")
        {
            if (IsItemUnlocked(itemId))
            {
                Debug.LogWarning($"[EconomyManager] Item {itemId} already unlocked");
                return false;
            }

            if (SpendCurrency(currencyType, cost, $"Unlock_{itemId}"))
            {
                if (SaveSystem.Instance != null)
                {
                    SaveSystem.Instance.Unlock(itemId);
                }

                OnItemUnlocked?.Invoke(itemId);

                if (AnalyticsManager.Instance != null)
                {
                    AnalyticsManager.Instance.TrackItemUnlock(itemId, "purchase");
                }

                Debug.Log($"[EconomyManager] Item unlocked: {itemId}");
                return true;
            }

            return false;
        }

        /// <summary>
        /// Get unlockable item data by ID
        /// </summary>
        public UnlockableItem GetItemData(string itemId)
        {
            if (availableItems == null) return null;

            foreach (var item in availableItems)
            {
                if (item.itemId == itemId)
                {
                    return item;
                }
            }

            return null;
        }

        /// <summary>
        /// Get all available items
        /// </summary>
        public UnlockableItem[] GetAllItems()
        {
            return availableItems;
        }

        #endregion

        #region Upgrade System

        /// <summary>
        /// Get current upgrade level
        /// </summary>
        public int GetUpgradeLevel(string upgradeId)
        {
            if (purchasedUpgrades.ContainsKey(upgradeId))
            {
                return purchasedUpgrades[upgradeId];
            }
            return 0;
        }

        /// <summary>
        /// Purchase upgrade
        /// </summary>
        public bool PurchaseUpgrade(string upgradeId, int currentLevel, int cost, string currencyType = "coins")
        {
            UpgradeData upgrade = GetUpgradeData(upgradeId);
            if (upgrade == null)
            {
                Debug.LogError($"[EconomyManager] Upgrade not found: {upgradeId}");
                return false;
            }

            if (currentLevel >= upgrade.maxLevel)
            {
                Debug.LogWarning($"[EconomyManager] Upgrade {upgradeId} already at max level");
                return false;
            }

            if (SpendCurrency(currencyType, cost, $"Upgrade_{upgradeId}_Lv{currentLevel + 1}"))
            {
                int newLevel = currentLevel + 1;
                purchasedUpgrades[upgradeId] = newLevel;

                // Save to persistent storage using custom data
                if (SaveSystem.Instance != null)
                {
                    SaveSystem.Instance.SaveData($"upgrade_{upgradeId}", newLevel.ToString());
                }

                OnUpgradePurchased?.Invoke(upgradeId, newLevel);

                Debug.Log($"[EconomyManager] Upgrade purchased: {upgradeId} Level {newLevel}");
                return true;
            }

            return false;
        }

        /// <summary>
        /// Get upgrade data by ID
        /// </summary>
        public UpgradeData GetUpgradeData(string upgradeId)
        {
            if (availableUpgrades == null) return null;

            foreach (var upgrade in availableUpgrades)
            {
                if (upgrade.upgradeId == upgradeId)
                {
                    return upgrade;
                }
            }

            return null;
        }

        void LoadPurchasedUpgrades()
        {
            if (SaveSystem.Instance == null || availableUpgrades == null) return;

            purchasedUpgrades.Clear();

            foreach (var upgrade in availableUpgrades)
            {
                // Load from custom data
                string levelStr = SaveSystem.Instance.LoadData<string>($"upgrade_{upgrade.upgradeId}");
                if (int.TryParse(levelStr, out int level) && level > 0)
                {
                    purchasedUpgrades[upgrade.upgradeId] = level;
                }
            }

            Debug.Log($"[EconomyManager] Loaded {purchasedUpgrades.Count} purchased upgrades");
        }

        #endregion

        #region Data Classes

        [System.Serializable]
        public class CurrencyConfig
        {
            public string currencyType = "coins";
            public string displayName = "Coins";
            public Sprite icon;
            public int startingAmount = 0;
        }

        [System.Serializable]
        public class UnlockableItem
        {
            public string itemId;
            public string itemName;
            public string description;
            public int unlockCost;
            public string currencyType = "coins";
            public int unlockLevel = 1; // Level required to unlock
            public Sprite icon;

            // Optional: Item-specific stats (extend in your game)
            public float statValue1 = 0f;
            public float statValue2 = 0f;
            public int statValue3 = 0;
        }

        [System.Serializable]
        public class UpgradeData
        {
            public string upgradeId;
            public string upgradeName;
            public string description;
            public int maxLevel = 10;
            public int baseCost = 100;
            public string currencyType = "coins";
            public float costMultiplier = 1.5f;

            // Upgrade effects
            public string upgradeCategory = "general"; // e.g., "speed", "power", "capacity"
            public float valuePerLevel = 1f;

            /// <summary>
            /// Calculate cost for specific level
            /// </summary>
            public int GetCostForLevel(int level)
            {
                if (level <= 0 || level > maxLevel)
                    return 0;

                return Mathf.RoundToInt(baseCost * Mathf.Pow(costMultiplier, level - 1));
            }

            /// <summary>
            /// Get total bonus at level
            /// </summary>
            public float GetBonusAtLevel(int level)
            {
                return valuePerLevel * level;
            }
        }

        #endregion

        #if UNITY_EDITOR
        [ContextMenu("Add 1000 Coins")]
        void DebugAddCoins()
        {
            AddCurrency("coins", 1000);
        }

        [ContextMenu("Add 100 Gems")]
        void DebugAddGems()
        {
            AddCurrency("gems", 100);
        }

        [ContextMenu("Test Purchase")]
        void DebugTestPurchase()
        {
            SpendCurrency("coins", 100, "Test Item");
        }
        #endif
    }
}
