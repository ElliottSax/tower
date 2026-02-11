using UnityEngine;
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace MobileGameCore
{
    /// <summary>
    /// Save/load system using JSON with integrity checking.
    /// Persists player progress, currency, unlocks, and settings.
    /// SECURITY: Uses SHA256 hash to detect save file tampering.
    ///
    /// Usage: Extend SaveData class in your game for game-specific data.
    /// </summary>
    public class SaveSystem : MonoBehaviour
    {
        public static SaveSystem Instance { get; private set; }

        private const string SAVE_FILE_NAME = "savegame.dat";
        private const string HASH_SALT = "MobileGameCore_v1.0_ChangeThisInYourGame"; // IMPORTANT: Change this per game!
        private string savePath;

        private SaveData currentSaveData;

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);

                savePath = Path.Combine(Application.persistentDataPath, SAVE_FILE_NAME);
                LoadGame();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        #region Save/Load

        public void SaveGame()
        {
            try
            {
                // Serialize to JSON
                string json = JsonUtility.ToJson(currentSaveData, true);

                // Compute hash for integrity checking
                string hash = ComputeHash(json);

                // Create container with data and hash
                SaveFileContainer container = new SaveFileContainer
                {
                    data = json,
                    hash = hash,
                    version = 1
                };

                string containerJson = JsonUtility.ToJson(container);

                // Encode (NOT encryption - just obfuscation)
                // Note: This is NOT secure encryption, just makes it non-obvious
                string encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(containerJson));

                // Write to file
                File.WriteAllText(savePath, encoded);

                Debug.Log($"[SaveSystem] Game saved to: {savePath}");
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveSystem] Failed to save game: {ex.Message}");
            }
        }

        public void LoadGame()
        {
            if (!File.Exists(savePath))
            {
                Debug.Log("[SaveSystem] No save file found, creating new save data");
                currentSaveData = new SaveData();
                return;
            }

            try
            {
                // Read file
                string encoded = File.ReadAllText(savePath);

                // Decode
                string containerJson = Encoding.UTF8.GetString(Convert.FromBase64String(encoded));

                // Deserialize container
                SaveFileContainer container = JsonUtility.FromJson<SaveFileContainer>(containerJson);

                // Verify integrity
                string computedHash = ComputeHash(container.data);
                if (computedHash != container.hash)
                {
                    Debug.LogWarning("[SaveSystem] Save file integrity check FAILED - file may be corrupted or tampered");

                    // Decision point: Reject save or accept with warning
                    // For single-player game, we'll accept but log
                    if (AnalyticsManager.Instance != null)
                    {
                        AnalyticsManager.Instance.TrackEvent("save_tampering_detected");
                    }
                }

                // Deserialize actual save data
                currentSaveData = JsonUtility.FromJson<SaveData>(container.data);

                Debug.Log($"[SaveSystem] Game loaded from: {savePath}");
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveSystem] Failed to load game: {ex.Message}");
                Debug.Log("[SaveSystem] Creating fresh save data");
                currentSaveData = new SaveData();
            }
        }

        public void DeleteSave()
        {
            if (File.Exists(savePath))
            {
                File.Delete(savePath);
                Debug.Log("[SaveSystem] Save file deleted");
            }

            currentSaveData = new SaveData();
        }

        #endregion

        #region Integrity Checking

        /// <summary>
        /// Compute SHA256 hash of data for integrity checking
        /// </summary>
        private string ComputeHash(string data)
        {
            // Add salt to prevent rainbow table attacks
            string saltedData = HASH_SALT + data;

            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = Encoding.UTF8.GetBytes(saltedData);
                byte[] hash = sha256.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }

        #endregion

        #region Data Access

        public SaveData GetSaveData()
        {
            return currentSaveData;
        }

        // Generic methods - games can extend SaveData and add specific methods
        public void SaveData(string key, string value)
        {
            currentSaveData.customData[key] = value;
            SaveGame();
        }

        public T LoadData<T>(string key, T defaultValue = default)
        {
            if (currentSaveData.customData.TryGetValue(key, out string value))
            {
                try
                {
                    return JsonUtility.FromJson<T>(value);
                }
                catch
                {
                    return defaultValue;
                }
            }
            return defaultValue;
        }

        // Currency (generic implementation)
        public int GetCurrency(string currencyType = "gold")
        {
            if (currentSaveData.currencies.TryGetValue(currencyType, out int amount))
            {
                return amount;
            }
            return 0;
        }

        public void AddCurrency(string currencyType, int amount)
        {
            if (amount < 0)
            {
                Debug.LogError($"[SaveSystem] Attempted to add negative currency: {amount}");
                return;
            }

            int current = GetCurrency(currencyType);
            int newAmount = current + amount;

            // Sanity check - prevent integer overflow exploits
            if (newAmount < current)
            {
                Debug.LogError("[SaveSystem] Currency overflow detected! Capping at max value.");
                newAmount = int.MaxValue;
            }

            currentSaveData.currencies[currencyType] = newAmount;
            SaveGame();
        }

        public bool SpendCurrency(string currencyType, int amount)
        {
            if (amount < 0)
            {
                Debug.LogError($"[SaveSystem] Attempted to spend negative currency: {amount}");
                return false;
            }

            int current = GetCurrency(currencyType);
            if (current >= amount)
            {
                currentSaveData.currencies[currencyType] = current - amount;
                SaveGame();
                return true;
            }
            return false;
        }

        // Progress (generic level system)
        public int GetHighestLevelUnlocked() => currentSaveData.highestLevelUnlocked;

        public void UnlockLevel(int levelNumber)
        {
            if (levelNumber <= 0)
            {
                Debug.LogError($"[SaveSystem] Invalid level number: {levelNumber}");
                return;
            }

            if (levelNumber > currentSaveData.highestLevelUnlocked)
            {
                currentSaveData.highestLevelUnlocked = levelNumber;
                SaveGame();
            }
        }

        public int GetLevelStars(int levelNumber)
        {
            if (currentSaveData.levelStars.TryGetValue(levelNumber, out int stars))
            {
                return stars;
            }
            return 0;
        }

        public void SetLevelStars(int levelNumber, int stars)
        {
            // Validate inputs
            if (levelNumber <= 0 || stars < 0 || stars > 3)
            {
                Debug.LogError($"[SaveSystem] Invalid level stars: level={levelNumber}, stars={stars}");
                return;
            }

            if (stars > GetLevelStars(levelNumber))
            {
                currentSaveData.levelStars[levelNumber] = stars;
                SaveGame();
            }
        }

        // Generic unlockables
        public bool IsUnlocked(string unlockID)
        {
            if (string.IsNullOrEmpty(unlockID))
            {
                Debug.LogError("[SaveSystem] Unlock ID is null or empty");
                return false;
            }
            return currentSaveData.unlockedItems.Contains(unlockID);
        }

        public void Unlock(string unlockID)
        {
            if (string.IsNullOrEmpty(unlockID))
            {
                Debug.LogError("[SaveSystem] Unlock ID is null or empty");
                return;
            }

            if (!IsUnlocked(unlockID))
            {
                currentSaveData.unlockedItems.Add(unlockID);
                SaveGame();
            }
        }

        // Daily Reward
        public DateTime GetLastDailyRewardClaim() => currentSaveData.lastDailyRewardClaim;

        public void ClaimDailyReward()
        {
            currentSaveData.lastDailyRewardClaim = DateTime.UtcNow;
            currentSaveData.dailyRewardStreak++;

            // Cap streak at reasonable value
            if (currentSaveData.dailyRewardStreak > 365)
            {
                currentSaveData.dailyRewardStreak = 365;
            }

            SaveGame();
        }

        public int GetDailyRewardStreak() => currentSaveData.dailyRewardStreak;

        public void ResetDailyStreak()
        {
            currentSaveData.dailyRewardStreak = 0;
            SaveGame();
        }

        // First time
        public bool IsFirstLaunch() => currentSaveData.isFirstLaunch;

        public void SetFirstLaunchComplete()
        {
            currentSaveData.isFirstLaunch = false;
            SaveGame();
        }

        #endregion

        #region Cloud Save Integration

        /// <summary>
        /// Serialize current save data to JSON for cloud storage.
        /// Used by CloudSaveManager.
        /// </summary>
        public string SerializeToJson()
        {
            try
            {
                currentSaveData.lastSaveTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                return JsonUtility.ToJson(currentSaveData, true);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveSystem] Failed to serialize: {ex.Message}");
                return "{}";
            }
        }

        /// <summary>
        /// Load save data from JSON string (from cloud).
        /// Used by CloudSaveManager.
        /// </summary>
        public void LoadFromJson(string json)
        {
            try
            {
                currentSaveData = JsonUtility.FromJson<SaveData>(json);
                Debug.Log("[SaveSystem] Loaded from cloud JSON");

                // Save locally after loading from cloud
                SaveGame();
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SaveSystem] Failed to load from JSON: {ex.Message}");
            }
        }

        /// <summary>
        /// Get timestamp of last save (for conflict resolution).
        /// </summary>
        public long GetLastSaveTimestamp()
        {
            return currentSaveData.lastSaveTimestamp;
        }

        #endregion
    }

    /// <summary>
    /// Container for save file with integrity checking
    /// </summary>
    [System.Serializable]
    public class SaveFileContainer
    {
        public string data;
        public string hash;
        public int version;
    }

    /// <summary>
    /// Serializable save data structure
    /// EXTEND THIS CLASS in your game for game-specific data
    /// </summary>
    [System.Serializable]
    public class SaveData
    {
        // Generic currency system (supports multiple currency types)
        public SerializableDictionary<string, int> currencies = new SerializableDictionary<string, int>();

        // Generic progress system
        public int highestLevelUnlocked = 1;
        public SerializableDictionary<int, int> levelStars = new SerializableDictionary<int, int>();

        // Generic unlocks
        public System.Collections.Generic.List<string> unlockedItems = new System.Collections.Generic.List<string>();

        // Daily Rewards
        public DateTime lastDailyRewardClaim = DateTime.MinValue;
        public int dailyRewardStreak = 0;

        // Meta
        public bool isFirstLaunch = true;
        public int totalPlayTimeSeconds = 0;
        public DateTime firstLaunchDate = DateTime.UtcNow;
        public long lastSaveTimestamp = 0; // Unix timestamp for cloud sync

        // Custom data (for game-specific data without extending)
        public SerializableDictionary<string, string> customData = new SerializableDictionary<string, string>();
    }

    /// <summary>
    /// Serializable dictionary for Unity's JsonUtility
    /// Enhanced with integrity checking
    /// </summary>
    [System.Serializable]
    public class SerializableDictionary<TKey, TValue>
    {
        [SerializeField] private System.Collections.Generic.List<TKey> keys = new System.Collections.Generic.List<TKey>();
        [SerializeField] private System.Collections.Generic.List<TValue> values = new System.Collections.Generic.List<TValue>();

        /// <summary>
        /// Validate that keys and values are in sync
        /// </summary>
        private bool ValidateIntegrity()
        {
            if (keys.Count != values.Count)
            {
                Debug.LogError($"[SerializableDictionary] Corruption: keys={keys.Count}, values={values.Count}");
                return false;
            }
            return true;
        }

        /// <summary>
        /// Repair dictionary by truncating to shorter list
        /// </summary>
        private void RepairDictionary()
        {
            int minCount = Mathf.Min(keys.Count, values.Count);
            if (keys.Count > minCount)
            {
                keys.RemoveRange(minCount, keys.Count - minCount);
            }
            if (values.Count > minCount)
            {
                values.RemoveRange(minCount, values.Count - minCount);
            }
            Debug.Log($"[SerializableDictionary] Repaired to {minCount} entries");
        }

        public bool TryGetValue(TKey key, out TValue value)
        {
            if (!ValidateIntegrity())
            {
                RepairDictionary();
            }

            int index = keys.IndexOf(key);
            if (index >= 0 && index < values.Count)
            {
                value = values[index];
                return true;
            }
            value = default;
            return false;
        }

        public void Add(TKey key, TValue value)
        {
            if (!ValidateIntegrity())
            {
                RepairDictionary();
            }

            int index = keys.IndexOf(key);
            if (index >= 0 && index < values.Count)
            {
                values[index] = value;
            }
            else
            {
                keys.Add(key);
                values.Add(value);
            }
        }

        public bool ContainsKey(TKey key) => keys.Contains(key);

        public TValue this[TKey key]
        {
            get
            {
                TryGetValue(key, out TValue value);
                return value;
            }
            set
            {
                Add(key, value);
            }
        }
    }
}
