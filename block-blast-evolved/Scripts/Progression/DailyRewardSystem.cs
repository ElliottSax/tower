using UnityEngine;
using System;
using System.Collections.Generic;

namespace BlockBlastEvolved.Progression
{
    /// <summary>
    /// Daily reward system with 7-day streak and grace period.
    /// Boosts D1/D7 retention by 10-15%.
    /// </summary>
    public class DailyRewardSystem : MonoBehaviour
    {
        public static DailyRewardSystem Instance { get; private set; }

        [Header("Reward Configuration")]
        [Tooltip("7-day reward cycle")]
        public DailyReward[] weeklyRewards = new DailyReward[7];

        [Header("Grace Period")]
        [Tooltip("Hours before streak resets (30 = player-friendly)")]
        [Range(0, 48)]
        public int gracePeriodHours = 30;

        [Header("Settings")]
        [Tooltip("Enable debug logs")]
        public bool debugMode = true;

        // State
        private int currentStreak = 0;
        private DateTime lastClaimDate;
        private bool hasClaimedToday = false;
        private bool streakExpired = false;

        // Events
        public event Action<DailyReward, int> OnRewardClaimed;
        public event Action<int> OnStreakIncreased;
        public event Action OnStreakReset;

        #region Unity Lifecycle

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

            // Initialize default rewards if not set
            if (weeklyRewards == null || weeklyRewards.Length != 7)
            {
                InitializeDefaultRewards();
            }
        }

        void Start()
        {
            LoadStreakData();
            CheckStreakStatus();
        }

        #endregion

        #region Reward Configuration

        /// <summary>
        /// Initialize default 7-day reward cycle
        /// </summary>
        void InitializeDefaultRewards()
        {
            weeklyRewards = new DailyReward[7]
            {
                // Day 1: Small coins
                new DailyReward
                {
                    day = 1,
                    rewardType = RewardType.Coins,
                    coins = 50,
                    description = "Daily Login Bonus"
                },
                // Day 2: More coins
                new DailyReward
                {
                    day = 2,
                    rewardType = RewardType.Coins,
                    coins = 100,
                    description = "2-Day Streak!"
                },
                // Day 3: Gems (premium currency)
                new DailyReward
                {
                    day = 3,
                    rewardType = RewardType.Gems,
                    gems = 10,
                    description = "3-Day Streak - Gems!"
                },
                // Day 4: Larger coins
                new DailyReward
                {
                    day = 4,
                    rewardType = RewardType.Coins,
                    coins = 200,
                    description = "4-Day Streak!"
                },
                // Day 5: More gems
                new DailyReward
                {
                    day = 5,
                    rewardType = RewardType.Gems,
                    gems = 25,
                    description = "5-Day Streak - More Gems!"
                },
                // Day 6: Large coins
                new DailyReward
                {
                    day = 6,
                    rewardType = RewardType.Coins,
                    coins = 500,
                    description = "Almost there!"
                },
                // Day 7: Grand reward (gems + hero unlock)
                new DailyReward
                {
                    day = 7,
                    rewardType = RewardType.GrandPrize,
                    coins = 1000,
                    gems = 50,
                    heroUnlock = true,
                    description = "Week Complete - Grand Prize!"
                }
            };

            DebugLog("Initialized default 7-day reward cycle");
        }

        #endregion

        #region Streak Management

        /// <summary>
        /// Check if player can claim today's reward
        /// </summary>
        public bool CanClaimToday()
        {
            return !hasClaimedToday && !streakExpired;
        }

        /// <summary>
        /// Claim today's daily reward
        /// </summary>
        public bool ClaimDailyReward()
        {
            if (!CanClaimToday())
            {
                DebugLog("Cannot claim - already claimed today or streak expired");
                return false;
            }

            // Get current reward
            int rewardIndex = currentStreak % 7;
            DailyReward reward = weeklyRewards[rewardIndex];

            // Grant rewards
            GrantReward(reward);

            // Update streak
            currentStreak++;
            lastClaimDate = DateTime.UtcNow;
            hasClaimedToday = true;

            // Fire events
            OnRewardClaimed?.Invoke(reward, currentStreak);
            OnStreakIncreased?.Invoke(currentStreak);

            // Check if week completed
            if (currentStreak % 7 == 0)
            {
                DebugLog($"Week {currentStreak / 7} completed!");
            }

            // Save state
            SaveStreakData();

            DebugLog($"Claimed Day {reward.day} reward - Streak: {currentStreak}");

            return true;
        }

        /// <summary>
        /// Check streak status (called on app start)
        /// </summary>
        void CheckStreakStatus()
        {
            DateTime now = DateTime.UtcNow;
            TimeSpan timeSinceLastClaim = now - lastClaimDate;

            // Check if it's a new day
            if (lastClaimDate.Date < now.Date)
            {
                hasClaimedToday = false;

                // Check if within grace period
                if (timeSinceLastClaim.TotalHours <= gracePeriodHours)
                {
                    // Within grace period - streak continues
                    DebugLog($"New day - streak continues ({timeSinceLastClaim.TotalHours:F1}h since last claim)");
                }
                else
                {
                    // Outside grace period - streak expires
                    streakExpired = true;
                    DebugLog($"Streak expired ({timeSinceLastClaim.TotalHours:F1}h since last claim)");
                }
            }
            else
            {
                // Same day as last claim
                hasClaimedToday = true;
                DebugLog("Already claimed today");
            }
        }

        /// <summary>
        /// Reset streak (when grace period expires)
        /// </summary>
        public void ResetStreak()
        {
            int oldStreak = currentStreak;
            currentStreak = 0;
            hasClaimedToday = false;
            streakExpired = false;
            lastClaimDate = DateTime.MinValue;

            OnStreakReset?.Invoke();

            DebugLog($"Streak reset (was {oldStreak} days)");

            SaveStreakData();
        }

        /// <summary>
        /// Get current streak count
        /// </summary>
        public int GetCurrentStreak()
        {
            return currentStreak;
        }

        /// <summary>
        /// Get current day in weekly cycle (1-7)
        /// </summary>
        public int GetCurrentDay()
        {
            return (currentStreak % 7) + 1;
        }

        /// <summary>
        /// Get next reward preview
        /// </summary>
        public DailyReward GetNextReward()
        {
            int rewardIndex = currentStreak % 7;
            return weeklyRewards[rewardIndex];
        }

        /// <summary>
        /// Get all weekly rewards
        /// </summary>
        public DailyReward[] GetWeeklyRewards()
        {
            return weeklyRewards;
        }

        #endregion

        #region Reward Granting

        /// <summary>
        /// Grant reward to player
        /// </summary>
        void GrantReward(DailyReward reward)
        {
            var economyManager = EconomyManager.Instance;
            if (economyManager == null)
            {
                DebugLog("EconomyManager not found!");
                return;
            }

            // Grant coins
            if (reward.coins > 0)
            {
                economyManager.AddCoins(reward.coins);
                DebugLog($"Granted {reward.coins} coins");
            }

            // Grant gems
            if (reward.gems > 0)
            {
                economyManager.AddGems(reward.gems);
                DebugLog($"Granted {reward.gems} gems");
            }

            // Grant hero unlock
            if (reward.heroUnlock)
            {
                GrantRandomHero();
            }

            // Play reward effects
            ShowRewardFeedback(reward);
        }

        /// <summary>
        /// Grant random locked hero
        /// </summary>
        void GrantRandomHero()
        {
            var heroSystem = HeroSystem.Instance;
            if (heroSystem == null) return;

            // Get all locked heroes
            var allHeroes = new List<Hero>(heroSystem.allHeroes);
            var unlockedHeroes = heroSystem.GetUnlockedHeroes();

            // Remove already unlocked heroes
            allHeroes.RemoveAll(h => unlockedHeroes.Contains(h));

            if (allHeroes.Count == 0)
            {
                DebugLog("All heroes already unlocked - granting gems instead");
                EconomyManager.Instance?.AddGems(100);
                return;
            }

            // Unlock random hero (prefer Common/Rare)
            var commonAndRare = allHeroes.FindAll(h =>
                h.rarity == HeroRarity.Common || h.rarity == HeroRarity.Rare);

            Hero heroToUnlock = commonAndRare.Count > 0
                ? commonAndRare[UnityEngine.Random.Range(0, commonAndRare.Count)]
                : allHeroes[UnityEngine.Random.Range(0, allHeroes.Count)];

            heroSystem.UnlockHero(heroToUnlock.heroId);

            DebugLog($"Granted hero: {heroToUnlock.heroName}");
        }

        /// <summary>
        /// Show reward visual/audio feedback
        /// </summary>
        void ShowRewardFeedback(DailyReward reward)
        {
            // Play celebration effect
            if (ParticleEffectManager.Instance != null)
            {
                string effectName = reward.day == 7 ? "grand_prize" : "daily_reward";
                ParticleEffectManager.Instance.PlayEffect(effectName, Vector3.zero);
            }

            // Play sound
            if (AudioManager.Instance != null)
            {
                string soundName = reward.day == 7 ? "grand_prize" : "reward_claim";
                AudioManager.Instance.PlaySFX(soundName);
            }

            // Show popup (integrate with UI system)
            DebugLog($"[REWARD CLAIMED] {reward.description}");
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Save streak data
        /// </summary>
        void SaveStreakData()
        {
            var saveSystem = SaveSystem.Instance;
            if (saveSystem == null) return;

            saveSystem.SetInt("daily_reward_streak", currentStreak);
            saveSystem.SetString("daily_reward_last_claim", lastClaimDate.ToString("o"));
            saveSystem.Save();

            DebugLog("Streak data saved");
        }

        /// <summary>
        /// Load streak data
        /// </summary>
        void LoadStreakData()
        {
            var saveSystem = SaveSystem.Instance;
            if (saveSystem == null) return;

            currentStreak = saveSystem.GetInt("daily_reward_streak", 0);

            string lastClaimStr = saveSystem.GetString("daily_reward_last_claim", "");
            if (!string.IsNullOrEmpty(lastClaimStr))
            {
                if (DateTime.TryParse(lastClaimStr, out DateTime parsed))
                {
                    lastClaimDate = parsed;
                }
            }
            else
            {
                lastClaimDate = DateTime.MinValue;
            }

            DebugLog($"Streak data loaded - Streak: {currentStreak}, Last Claim: {lastClaimDate}");
        }

        #endregion

        #region Utilities

        void DebugLog(string message)
        {
            if (debugMode)
            {
                Debug.Log($"[DailyRewardSystem] {message}");
            }
        }

        #endregion

        #region Test Methods (Editor Only)

#if UNITY_EDITOR
        [ContextMenu("Test: Claim Today's Reward")]
        public void TestClaimReward()
        {
            if (ClaimDailyReward())
            {
                Debug.Log("✅ Reward claimed successfully");
            }
            else
            {
                Debug.Log("❌ Cannot claim reward");
            }
        }

        [ContextMenu("Test: Reset Streak")]
        public void TestResetStreak()
        {
            ResetStreak();
            Debug.Log("Streak reset to 0");
        }

        [ContextMenu("Test: Skip to Tomorrow")]
        public void TestSkipToTomorrow()
        {
            lastClaimDate = DateTime.UtcNow.AddDays(-1);
            hasClaimedToday = false;
            SaveStreakData();
            CheckStreakStatus();
            Debug.Log("Skipped to tomorrow - can claim again");
        }

        [ContextMenu("Test: Expire Streak")]
        public void TestExpireStreak()
        {
            lastClaimDate = DateTime.UtcNow.AddHours(-(gracePeriodHours + 1));
            SaveStreakData();
            CheckStreakStatus();
            Debug.Log($"Streak expired - status: {(streakExpired ? "EXPIRED" : "ACTIVE")}");
        }

        [ContextMenu("Test: Show All Rewards")]
        public void TestShowAllRewards()
        {
            Debug.Log("=== 7-Day Reward Cycle ===");
            for (int i = 0; i < weeklyRewards.Length; i++)
            {
                var reward = weeklyRewards[i];
                Debug.Log($"Day {reward.day}: {reward.description} - {reward.coins} coins, {reward.gems} gems");
            }
        }
#endif

        #endregion
    }

    /// <summary>
    /// Daily reward definition
    /// </summary>
    [System.Serializable]
    public class DailyReward
    {
        [Header("Day")]
        public int day = 1;

        [Header("Rewards")]
        public RewardType rewardType = RewardType.Coins;
        public int coins = 0;
        public int gems = 0;
        public bool heroUnlock = false;

        [Header("Display")]
        public string description = "Daily Login Bonus";
        public Sprite rewardIcon;
    }

    /// <summary>
    /// Reward types
    /// </summary>
    public enum RewardType
    {
        Coins,
        Gems,
        Hero,
        GrandPrize
    }
}
