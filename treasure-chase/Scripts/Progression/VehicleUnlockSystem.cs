using UnityEngine;
using System;
using System.Collections.Generic;
using System.Linq;

namespace TreasureChase.Progression
{
    /// <summary>
    /// Vehicle Unlock System for Treasure Chase.
    /// Manages 8 unlockable vehicles with unique stats and progression.
    ///
    /// Retention Impact: +8-12% D7 retention
    /// Monetization Impact: Drives coin spending → IAP purchases
    /// </summary>
    public class VehicleUnlockSystem : MonoBehaviour
    {
        public static VehicleUnlockSystem Instance { get; private set; }

        [Header("Vehicle Database")]
        [Tooltip("All vehicles in the game (ScriptableObjects)")]
        public List<VehicleData> vehicles = new List<VehicleData>();

        [Header("Unlock Settings")]
        [Tooltip("Starting vehicle (index 0, always unlocked)")]
        public int defaultVehicleIndex = 0;

        [Header("Events")]
        public event Action<int> OnVehicleUnlocked;
        public event Action<int> OnVehicleSelected;
        public event Action OnVehiclesLoaded;

        // State tracking
        private HashSet<int> unlockedVehicles = new HashSet<int>();
        private int selectedVehicleIndex = 0;

        // Current vehicle stats (applied to player)
        private VehicleStats currentStats;

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
        }

        void Start()
        {
            // Load unlock state
            LoadUnlockState();

            // Initialize default vehicle
            if (!unlockedVehicles.Contains(defaultVehicleIndex))
            {
                UnlockVehicle(defaultVehicleIndex, freePurchase: true);
            }

            // Select saved vehicle or default
            int savedIndex = PlayerPrefs.GetInt("SelectedVehicle", defaultVehicleIndex);
            SelectVehicle(savedIndex);

            OnVehiclesLoaded?.Invoke();

            Debug.Log($"VehicleUnlockSystem: Initialized. Unlocked: {unlockedVehicles.Count}, Selected: {selectedVehicleIndex}");
        }

        #endregion

        #region Unlock Management

        /// <summary>
        /// Unlock a vehicle by index
        /// </summary>
        public bool UnlockVehicle(int index, bool freePurchase = false)
        {
            if (index < 0 || index >= vehicles.Count)
            {
                Debug.LogError($"Invalid vehicle index: {index}");
                return false;
            }

            if (unlockedVehicles.Contains(index))
            {
                Debug.Log($"Vehicle {index} already unlocked");
                return false;
            }

            var vehicle = vehicles[index];

            // Check if already unlocked
            if (unlockedVehicles.Contains(index))
            {
                Debug.Log($"Vehicle already unlocked: {vehicle.vehicleName}");
                return true;
            }

            // Check coin cost (unless free purchase)
            if (!freePurchase && vehicle.unlockCost > 0)
            {
                var economyManager = FindObjectOfType<EconomyManager>();
                if (economyManager == null)
                {
                    Debug.LogError("EconomyManager not found");
                    return false;
                }

                int currentCoins = economyManager.GetCoins();
                if (currentCoins < vehicle.unlockCost)
                {
                    Debug.Log($"Not enough coins to unlock {vehicle.vehicleName}. Need {vehicle.unlockCost}, have {currentCoins}");
                    return false;
                }

                // Deduct coins
                economyManager.SpendCoins(vehicle.unlockCost);
            }

            // Unlock vehicle
            unlockedVehicles.Add(index);
            SaveUnlockState();

            // Fire event
            OnVehicleUnlocked?.Invoke(index);

            // Analytics
            LogAnalytics("vehicle_unlocked", new Dictionary<string, object>
            {
                { "vehicle_index", index },
                { "vehicle_name", vehicle.vehicleName },
                { "unlock_cost", vehicle.unlockCost },
                { "free_purchase", freePurchase }
            });

            // Achievement check
            CheckUnlockAchievements();

            Debug.Log($"✅ Vehicle Unlocked: {vehicle.vehicleName} (Index: {index})");

            return true;
        }

        /// <summary>
        /// Select a vehicle to use
        /// </summary>
        public bool SelectVehicle(int index)
        {
            if (index < 0 || index >= vehicles.Count)
            {
                Debug.LogError($"Invalid vehicle index: {index}");
                return false;
            }

            if (!IsVehicleUnlocked(index))
            {
                Debug.Log($"Cannot select locked vehicle: {index}");
                return false;
            }

            selectedVehicleIndex = index;
            currentStats = vehicles[index].stats;

            // Save selection
            PlayerPrefs.SetInt("SelectedVehicle", index);
            PlayerPrefs.Save();

            // Fire event
            OnVehicleSelected?.Invoke(index);

            // Analytics
            LogAnalytics("vehicle_selected", new Dictionary<string, object>
            {
                { "vehicle_index", index },
                { "vehicle_name", vehicles[index].vehicleName }
            });

            Debug.Log($"Vehicle Selected: {vehicles[index].vehicleName}");

            return true;
        }

        /// <summary>
        /// Unlock vehicle by name (for IAP/rewards)
        /// </summary>
        public bool UnlockVehicleByName(string vehicleName, bool freePurchase = false)
        {
            for (int i = 0; i < vehicles.Count; i++)
            {
                if (vehicles[i].vehicleName == vehicleName)
                {
                    return UnlockVehicle(i, freePurchase);
                }
            }

            Debug.LogError($"Vehicle not found: {vehicleName}");
            return false;
        }

        #endregion

        #region Query Methods

        /// <summary>
        /// Check if vehicle is unlocked
        /// </summary>
        public bool IsVehicleUnlocked(int index)
        {
            return unlockedVehicles.Contains(index);
        }

        /// <summary>
        /// Get currently selected vehicle index
        /// </summary>
        public int GetSelectedVehicleIndex()
        {
            return selectedVehicleIndex;
        }

        /// <summary>
        /// Get currently selected vehicle data
        /// </summary>
        public VehicleData GetSelectedVehicle()
        {
            if (selectedVehicleIndex >= 0 && selectedVehicleIndex < vehicles.Count)
            {
                return vehicles[selectedVehicleIndex];
            }
            return null;
        }

        /// <summary>
        /// Get current vehicle stats (for gameplay)
        /// </summary>
        public VehicleStats GetCurrentStats()
        {
            return currentStats;
        }

        /// <summary>
        /// Get list of all unlocked vehicle indices
        /// </summary>
        public List<int> GetUnlockedVehicles()
        {
            return unlockedVehicles.ToList();
        }

        /// <summary>
        /// Get next locked vehicle (for UI "Unlock Next" button)
        /// </summary>
        public VehicleData GetNextLockedVehicle()
        {
            for (int i = 0; i < vehicles.Count; i++)
            {
                if (!unlockedVehicles.Contains(i))
                {
                    return vehicles[i];
                }
            }
            return null; // All unlocked
        }

        /// <summary>
        /// Get unlock progress (for UI)
        /// </summary>
        public string GetUnlockProgress()
        {
            return $"{unlockedVehicles.Count}/{vehicles.Count}";
        }

        /// <summary>
        /// Get unlock percentage (for analytics)
        /// </summary>
        public float GetUnlockPercentage()
        {
            if (vehicles.Count == 0) return 0f;
            return (float)unlockedVehicles.Count / vehicles.Count;
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Save unlock state to PlayerPrefs
        /// </summary>
        void SaveUnlockState()
        {
            // Convert HashSet to comma-separated string
            string unlockedString = string.Join(",", unlockedVehicles.OrderBy(x => x));
            PlayerPrefs.SetString("UnlockedVehicles", unlockedString);
            PlayerPrefs.Save();

            Debug.Log($"Saved unlock state: {unlockedString}");
        }

        /// <summary>
        /// Load unlock state from PlayerPrefs
        /// </summary>
        void LoadUnlockState()
        {
            string unlockedString = PlayerPrefs.GetString("UnlockedVehicles", "");

            if (string.IsNullOrEmpty(unlockedString))
            {
                Debug.Log("No saved unlock state - starting fresh");
                return;
            }

            // Parse comma-separated string to HashSet
            unlockedVehicles.Clear();
            string[] indices = unlockedString.Split(',');
            foreach (string indexStr in indices)
            {
                if (int.TryParse(indexStr, out int index))
                {
                    unlockedVehicles.Add(index);
                }
            }

            Debug.Log($"Loaded unlock state: {unlockedVehicles.Count} vehicles unlocked");
        }

        #endregion

        #region Achievements

        /// <summary>
        /// Check and unlock vehicle-related achievements
        /// </summary>
        void CheckUnlockAchievements()
        {
            var achievementSystem = FindObjectOfType<AchievementSystem>();
            if (achievementSystem == null) return;

            int unlockedCount = unlockedVehicles.Count;

            if (unlockedCount >= 2)
                achievementSystem.UnlockAchievement("vehicles_unlocked_2");

            if (unlockedCount >= 4)
                achievementSystem.UnlockAchievement("vehicles_unlocked_4");

            if (unlockedCount >= 8)
                achievementSystem.UnlockAchievement("vehicles_unlocked_all");
        }

        #endregion

        #region Analytics

        void LogAnalytics(string eventName, Dictionary<string, object> parameters)
        {
            var analyticsManager = FindObjectOfType<AnalyticsManager>();
            if (analyticsManager != null)
            {
                analyticsManager.LogEvent(eventName, parameters);
            }
        }

        #endregion

        #region Editor Testing

#if UNITY_EDITOR
        [ContextMenu("Test: Unlock All Vehicles")]
        public void TestUnlockAll()
        {
            for (int i = 0; i < vehicles.Count; i++)
            {
                UnlockVehicle(i, freePurchase: true);
            }
            Debug.Log("All vehicles unlocked");
        }

        [ContextMenu("Test: Reset Unlocks")]
        public void TestResetUnlocks()
        {
            unlockedVehicles.Clear();
            PlayerPrefs.DeleteKey("UnlockedVehicles");
            PlayerPrefs.DeleteKey("SelectedVehicle");
            PlayerPrefs.Save();
            Debug.Log("Vehicle unlocks reset");
        }

        [ContextMenu("Test: Add 1000 Coins")]
        public void TestAddCoins()
        {
            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(1000);
                Debug.Log("Added 1000 coins");
            }
        }

        [ContextMenu("Debug: Print Unlock State")]
        public void DebugPrintState()
        {
            Debug.Log($"=== VEHICLE UNLOCK STATE ===");
            Debug.Log($"Unlocked: {unlockedVehicles.Count}/{vehicles.Count}");
            Debug.Log($"Selected: {selectedVehicleIndex} ({GetSelectedVehicle()?.vehicleName})");
            Debug.Log($"Unlocked Indices: {string.Join(", ", unlockedVehicles.OrderBy(x => x))}");
        }
#endif

        #endregion
    }

    /// <summary>
    /// Vehicle data ScriptableObject structure
    /// </summary>
    [Serializable]
    public class VehicleData
    {
        [Header("Basic Info")]
        public string vehicleName = "Vehicle";
        public string vehicleDescription = "A basic vehicle";
        public Sprite vehicleIcon;
        public GameObject vehiclePrefab;

        [Header("Unlock Requirements")]
        public int unlockCost = 0; // 0 = starter vehicle (always unlocked)
        public VehicleRarity rarity = VehicleRarity.Common;

        [Header("Stats")]
        public VehicleStats stats = new VehicleStats();

        [Header("Visual")]
        public Color primaryColor = Color.white;
        public Color secondaryColor = Color.gray;
    }

    /// <summary>
    /// Vehicle stats that affect gameplay
    /// </summary>
    [Serializable]
    public class VehicleStats
    {
        [Header("Movement")]
        [Tooltip("Speed multiplier (1.0 = normal, 1.2 = 20% faster)")]
        [Range(0.8f, 1.5f)]
        public float speedMultiplier = 1.0f;

        [Tooltip("How quickly vehicle switches lanes (1.0 = normal)")]
        [Range(0.8f, 1.5f)]
        public float handlingMultiplier = 1.0f;

        [Header("Collection")]
        [Tooltip("Coin collection multiplier (1.0 = normal, 1.5 = 50% more coins)")]
        [Range(1.0f, 2.0f)]
        public float coinMultiplier = 1.0f;

        [Tooltip("Treasure collection range multiplier (1.0 = normal)")]
        [Range(1.0f, 2.0f)]
        public float magnetRangeMultiplier = 1.0f;

        [Header("Defense")]
        [Tooltip("Shield power-up duration multiplier (1.0 = normal)")]
        [Range(1.0f, 2.0f)]
        public float shieldDurationMultiplier = 1.0f;

        [Tooltip("Starting run with shield (seconds, 0 = none)")]
        [Range(0f, 5f)]
        public float startingShieldDuration = 0f;

        [Header("Special Abilities")]
        [Tooltip("Chance to avoid obstacles (0-100%)")]
        [Range(0f, 100f)]
        public float luckyDodgeChance = 0f;

        [Tooltip("Extra life per run (0 or 1)")]
        [Range(0, 1)]
        public int extraLife = 0;

        /// <summary>
        /// Calculate overall rating (for UI display)
        /// </summary>
        public int GetOverallRating()
        {
            float rating = 0f;

            // Movement
            rating += (speedMultiplier - 1f) * 20f;
            rating += (handlingMultiplier - 1f) * 15f;

            // Collection
            rating += (coinMultiplier - 1f) * 25f;
            rating += (magnetRangeMultiplier - 1f) * 10f;

            // Defense
            rating += (shieldDurationMultiplier - 1f) * 15f;
            rating += startingShieldDuration * 5f;

            // Special
            rating += luckyDodgeChance * 0.5f;
            rating += extraLife * 30f;

            // Normalize to 1-5 stars
            return Mathf.Clamp(Mathf.RoundToInt(rating / 20f) + 1, 1, 5);
        }
    }

    /// <summary>
    /// Vehicle rarity tiers
    /// </summary>
    public enum VehicleRarity
    {
        Common,     // Starting vehicles (free or cheap)
        Uncommon,   // Mid-tier unlocks
        Rare,       // Late-game unlocks
        Epic,       // Premium unlocks
        Legendary   // Ultimate unlock
    }
}
