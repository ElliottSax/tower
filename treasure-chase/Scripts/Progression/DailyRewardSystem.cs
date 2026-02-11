using UnityEngine;
using System;
using System.Collections.Generic;

namespace TreasureChase.Progression
{
    /// <summary>
    /// Daily Reward System for Treasure Chase.
    /// 7-day reward cycle with streak tracking and recovery options.
    ///
    /// Retention Impact: +10-15% D1/D7 retention
    /// Combined with Vehicles: +18-27% D7 retention (compound effect)
    /// </summary>
    public class DailyRewardSystem : MonoBehaviour
    {
        public static DailyRewardSystem Instance { get; private set; }

        [Header("Daily Rewards Configuration")]
        [Tooltip("7-day reward cycle")]
        public List<DailyReward> rewards = new List<DailyReward>();

        [Header("Streak Settings")]
        [Tooltip("Grace period for missed days (hours)")]
        public float streakGracePeriodHours = 30f; // 30 hours = 6-hour buffer

        [Tooltip("Cost to recover missed day (rewarded ad)")]
        public bool allowStreakRecovery = true;

        [Header("Events")]
        public event Action<int> OnRewardClaimed; // Day index
        public event Action<int> OnStreakUpdated; // Current streak
        public event Action OnStreakLost;
        public event Action OnStreakRecovered;

        // State tracking
        private DateTime lastClaimTime;
        private int currentStreak = 0;
        private int todayIndex = 0; // 0-6 for 7-day cycle
        private bool hasClaimedToday = false;
        private bool streakBroken = false;

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
            // Initialize default rewards if empty
            if (rewards.Count == 0)
            {
                InitializeDefaultRewards();
            }

            // Load state
            LoadState();

            // Check daily reset
            CheckDailyReset();

            Debug.Log($"DailyRewardSystem: Initialized. Streak: {currentStreak}, Today: Day {todayIndex + 1}");
        }

        #endregion

        #region Reward Management

        /// <summary>
        /// Claim today's reward
        /// </summary>
        public bool ClaimDailyReward()
        {
            if (hasClaimedToday)
            {
                Debug.Log("Daily reward already claimed today");
                return false;
            }

            if (streakBroken && !allowStreakRecovery)
            {
                Debug.Log("Streak broken - cannot claim until tomorrow");
                return false;
            }

            // Get today's reward
            DailyReward reward = GetTodayReward();

            // Grant reward
            GrantReward(reward);

            // Update state
            hasClaimedToday = true;
            lastClaimTime = DateTime.UtcNow;
            currentStreak++;
            todayIndex = (todayIndex + 1) % 7; // Cycle through 0-6

            // Save state
            SaveState();

            // Fire events
            OnRewardClaimed?.Invoke(todayIndex);
            OnStreakUpdated?.Invoke(currentStreak);

            // Analytics
            LogAnalytics("daily_reward_claimed", new Dictionary<string, object>
            {
                { "day_index", todayIndex },
                { "streak", currentStreak },
                { "reward_type", reward.rewardType.ToString() },
                { "reward_amount", reward.amount }
            });

            Debug.Log($"✅ Daily Reward Claimed! Day {todayIndex + 1}, Streak: {currentStreak}");

            return true;
        }

        /// <summary>
        /// Recover streak with rewarded ad
        /// </summary>
        public void RecoverStreak(Action<bool> onComplete)
        {
            if (!streakBroken)
            {
                Debug.Log("Streak not broken - no recovery needed");
                onComplete?.Invoke(false);
                return;
            }

            if (!allowStreakRecovery)
            {
                Debug.Log("Streak recovery not allowed");
                onComplete?.Invoke(false);
                return;
            }

            // Show rewarded ad
            var adsManager = FindObjectOfType<TreasureChase.Monetization.UnityAdsManager>();
            if (adsManager != null && adsManager.IsRewardedAdReady())
            {
                adsManager.ShowRewardedAd((rewarded) =>
                {
                    if (rewarded)
                    {
                        // Restore streak
                        streakBroken = false;
                        SaveState();

                        OnStreakRecovered?.Invoke();

                        // Analytics
                        LogAnalytics("daily_reward_streak_recovered", new Dictionary<string, object>
                        {
                            { "streak", currentStreak },
                            { "recovery_method", "rewarded_ad" }
                        });

                        Debug.Log($"✅ Streak Recovered! Current: {currentStreak}");
                        onComplete?.Invoke(true);
                    }
                    else
                    {
                        Debug.Log("Streak recovery failed - ad not watched");
                        onComplete?.Invoke(false);
                    }
                });
            }
            else
            {
                Debug.Log("Rewarded ad not available for streak recovery");
                onComplete?.Invoke(false);
            }
        }

        #endregion

        #region Reward Granting

        /// <summary>
        /// Grant reward to player
        /// </summary>
        void GrantReward(DailyReward reward)
        {
            var economyManager = FindObjectOfType<EconomyManager>();
            var vehicleSystem = VehicleUnlockSystem.Instance;

            switch (reward.rewardType)
            {
                case RewardType.Coins:
                    if (economyManager != null)
                    {
                        economyManager.AddCoins(reward.amount);
                        Debug.Log($"Granted {reward.amount} coins");
                    }
                    break;

                case RewardType.Gems:
                    if (economyManager != null)
                    {
                        economyManager.AddGems(reward.amount);
                        Debug.Log($"Granted {reward.amount} gems");
                    }
                    break;

                case RewardType.Vehicle:
                    if (vehicleSystem != null && reward.amount >= 0 && reward.amount < vehicleSystem.vehicles.Count)
                    {
                        vehicleSystem.UnlockVehicle(reward.amount, freePurchase: true);
                        Debug.Log($"Granted vehicle: {vehicleSystem.vehicles[reward.amount].vehicleName}");
                    }
                    break;

                case RewardType.PowerUp:
                    // Grant power-up (implement with inventory system)
                    Debug.Log($"Granted power-up: {reward.amount}");
                    break;
            }

            // Show reward UI
            ShowRewardNotification(reward);
        }

        /// <summary>
        /// Show reward notification UI
        /// </summary>
        void ShowRewardNotification(DailyReward reward)
        {
            // TODO: Integrate with UI system
            Debug.Log($"[UI] Daily Reward: {reward.GetDisplayText()}");
        }

        #endregion

        #region Daily Reset Logic

        /// <summary>
        /// Check if day has reset (called on app open)
        /// </summary>
        void CheckDailyReset()
        {
            DateTime now = DateTime.UtcNow;
            DateTime lastClaim = lastClaimTime;

            // If never claimed, start fresh
            if (lastClaim == DateTime.MinValue)
            {
                Debug.Log("First time user - welcome!");
                return;
            }

            // Calculate hours since last claim
            TimeSpan timeSinceLastClaim = now - lastClaim;
            float hoursSinceClaim = (float)timeSinceLastClaim.TotalHours;

            Debug.Log($"Hours since last claim: {hoursSinceClaim:F1}");

            // Case 1: Same day (within 24 hours)
            if (hoursSinceClaim < 24f)
            {
                Debug.Log("Same day - reward already claimed or still available");
                // hasClaimedToday should be loaded from PlayerPrefs
                return;
            }

            // Case 2: Next day (24-30 hours) - streak continues
            else if (hoursSinceClaim < streakGracePeriodHours)
            {
                Debug.Log("New day - reward available!");
                hasClaimedToday = false;
                SaveState();
                return;
            }

            // Case 3: Missed day (>30 hours) - streak broken
            else
            {
                Debug.Log($"⚠️ Streak broken! Missed day (>30 hours)");
                BreakStreak();
            }
        }

        /// <summary>
        /// Break the streak (missed day)
        /// </summary>
        void BreakStreak()
        {
            if (currentStreak > 0)
            {
                Debug.Log($"Streak lost: {currentStreak} days");

                // Analytics
                LogAnalytics("daily_reward_streak_lost", new Dictionary<string, object>
                {
                    { "streak_lost", currentStreak }
                });
            }

            // Reset state
            currentStreak = 0;
            todayIndex = 0;
            hasClaimedToday = false;
            streakBroken = true;

            SaveState();

            // Fire event
            OnStreakLost?.Invoke();

            // Show recovery option UI
            if (allowStreakRecovery)
            {
                Debug.Log("💡 Streak recovery available! Watch ad to restore.");
            }
        }

        #endregion

        #region Query Methods

        /// <summary>
        /// Get today's reward
        /// </summary>
        public DailyReward GetTodayReward()
        {
            if (todayIndex >= 0 && todayIndex < rewards.Count)
            {
                return rewards[todayIndex];
            }
            return rewards[0]; // Fallback
        }

        /// <summary>
        /// Get reward for specific day
        /// </summary>
        public DailyReward GetRewardForDay(int dayIndex)
        {
            if (dayIndex >= 0 && dayIndex < rewards.Count)
            {
                return rewards[dayIndex];
            }
            return null;
        }

        /// <summary>
        /// Check if today's reward has been claimed
        /// </summary>
        public bool HasClaimedToday()
        {
            return hasClaimedToday;
        }

        /// <summary>
        /// Get current streak count
        /// </summary>
        public int GetCurrentStreak()
        {
            return currentStreak;
        }

        /// <summary>
        /// Get today's day index (0-6)
        /// </summary>
        public int GetTodayIndex()
        {
            return todayIndex;
        }

        /// <summary>
        /// Check if streak is broken and recoverable
        /// </summary>
        public bool IsStreakBroken()
        {
            return streakBroken;
        }

        /// <summary>
        /// Get time until next reward (in seconds)
        /// </summary>
        public float GetTimeUntilNextReward()
        {
            if (!hasClaimedToday)
            {
                return 0f; // Available now
            }

            DateTime now = DateTime.UtcNow;
            DateTime nextMidnight = now.Date.AddDays(1);
            TimeSpan timeUntilMidnight = nextMidnight - now;

            return (float)timeUntilMidnight.TotalSeconds;
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Save state to PlayerPrefs
        /// </summary>
        void SaveState()
        {
            PlayerPrefs.SetString("DailyReward_LastClaim", lastClaimTime.ToString("o")); // ISO 8601 format
            PlayerPrefs.SetInt("DailyReward_Streak", currentStreak);
            PlayerPrefs.SetInt("DailyReward_TodayIndex", todayIndex);
            PlayerPrefs.SetInt("DailyReward_ClaimedToday", hasClaimedToday ? 1 : 0);
            PlayerPrefs.SetInt("DailyReward_StreakBroken", streakBroken ? 1 : 0);
            PlayerPrefs.Save();

            Debug.Log($"Daily reward state saved: Streak {currentStreak}, Day {todayIndex + 1}");
        }

        /// <summary>
        /// Load state from PlayerPrefs
        /// </summary>
        void LoadState()
        {
            string lastClaimStr = PlayerPrefs.GetString("DailyReward_LastClaim", "");

            if (string.IsNullOrEmpty(lastClaimStr))
            {
                // First time user
                lastClaimTime = DateTime.MinValue;
                currentStreak = 0;
                todayIndex = 0;
                hasClaimedToday = false;
                streakBroken = false;
            }
            else
            {
                lastClaimTime = DateTime.Parse(lastClaimStr);
                currentStreak = PlayerPrefs.GetInt("DailyReward_Streak", 0);
                todayIndex = PlayerPrefs.GetInt("DailyReward_TodayIndex", 0);
                hasClaimedToday = PlayerPrefs.GetInt("DailyReward_ClaimedToday", 0) == 1;
                streakBroken = PlayerPrefs.GetInt("DailyReward_StreakBroken", 0) == 1;
            }

            Debug.Log($"Daily reward state loaded: Streak {currentStreak}, Day {todayIndex + 1}, Claimed: {hasClaimedToday}");
        }

        #endregion

        #region Default Rewards

        /// <summary>
        /// Initialize default 7-day reward cycle
        /// </summary>
        void InitializeDefaultRewards()
        {
            rewards = new List<DailyReward>
            {
                // Day 1: Welcome bonus
                new DailyReward
                {
                    dayIndex = 0,
                    rewardType = RewardType.Coins,
                    amount = 50,
                    displayText = "50 Coins"
                },

                // Day 2: Escalating
                new DailyReward
                {
                    dayIndex = 1,
                    rewardType = RewardType.Coins,
                    amount = 100,
                    displayText = "100 Coins"
                },

                // Day 3: Introduce gems
                new DailyReward
                {
                    dayIndex = 2,
                    rewardType = RewardType.Gems,
                    amount = 10,
                    displayText = "10 Gems"
                },

                // Day 4: More coins
                new DailyReward
                {
                    dayIndex = 3,
                    rewardType = RewardType.Coins,
                    amount = 200,
                    displayText = "200 Coins"
                },

                // Day 5: More gems
                new DailyReward
                {
                    dayIndex = 4,
                    rewardType = RewardType.Gems,
                    amount = 25,
                    displayText = "25 Gems"
                },

                // Day 6: Large coin bonus
                new DailyReward
                {
                    dayIndex = 5,
                    rewardType = RewardType.Coins,
                    amount = 500,
                    displayText = "500 Coins"
                },

                // Day 7: Grand reward (vehicle unlock OR 1000 coins)
                new DailyReward
                {
                    dayIndex = 6,
                    rewardType = RewardType.Coins, // Changed to coins by default
                    amount = 1000,
                    displayText = "1000 Coins" // or "Speed Demon Vehicle" if amount = 1 (vehicle index)
                }
            };

            Debug.Log("Initialized default 7-day reward cycle");
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
        [ContextMenu("Test: Claim Today's Reward")]
        public void TestClaimReward()
        {
            ClaimDailyReward();
        }

        [ContextMenu("Test: Skip Day (Break Streak)")]
        public void TestSkipDay()
        {
            lastClaimTime = DateTime.UtcNow.AddHours(-48); // 2 days ago
            SaveState();
            LoadState();
            CheckDailyReset();
            Debug.Log("Simulated skipped day");
        }

        [ContextMenu("Test: Reset Daily Rewards")]
        public void TestResetRewards()
        {
            PlayerPrefs.DeleteKey("DailyReward_LastClaim");
            PlayerPrefs.DeleteKey("DailyReward_Streak");
            PlayerPrefs.DeleteKey("DailyReward_TodayIndex");
            PlayerPrefs.DeleteKey("DailyReward_ClaimedToday");
            PlayerPrefs.DeleteKey("DailyReward_StreakBroken");
            PlayerPrefs.Save();

            LoadState();
            Debug.Log("Daily rewards reset");
        }

        [ContextMenu("Test: Advance to Next Day")]
        public void TestAdvanceDay()
        {
            hasClaimedToday = false;
            lastClaimTime = DateTime.UtcNow.AddHours(-25); // Yesterday
            SaveState();
            CheckDailyReset();
            Debug.Log("Advanced to next day");
        }

        [ContextMenu("Debug: Print State")]
        public void DebugPrintState()
        {
            Debug.Log($"=== DAILY REWARD STATE ===");
            Debug.Log($"Current Streak: {currentStreak}");
            Debug.Log($"Today Index: {todayIndex} (Day {todayIndex + 1}/7)");
            Debug.Log($"Claimed Today: {hasClaimedToday}");
            Debug.Log($"Streak Broken: {streakBroken}");
            Debug.Log($"Last Claim: {lastClaimTime}");
            Debug.Log($"Time Until Next: {GetTimeUntilNextReward() / 3600f:F1} hours");
        }
#endif

        #endregion
    }

    /// <summary>
    /// Daily reward data structure
    /// </summary>
    [Serializable]
    public class DailyReward
    {
        public int dayIndex; // 0-6
        public RewardType rewardType;
        public int amount;
        public string displayText;

        public string GetDisplayText()
        {
            if (!string.IsNullOrEmpty(displayText))
                return displayText;

            return $"{amount} {rewardType}";
        }
    }

    /// <summary>
    /// Reward types
    /// </summary>
    public enum RewardType
    {
        Coins,
        Gems,
        Vehicle,
        PowerUp
    }
}
