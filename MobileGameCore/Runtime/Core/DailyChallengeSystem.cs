using UnityEngine;
using System;
using System.Collections.Generic;

namespace MobileGameCore
{
    /// <summary>
    /// Daily challenge system for engagement and retention.
    /// Provides daily missions with rewards and streak tracking.
    ///
    /// USAGE:
    /// DailyChallengeSystem.Instance.RegisterChallenge(new DailyChallenge("collect_10", "Collect 10 items", 10, 50));
    /// DailyChallengeSystem.Instance.AddProgress("collect_10", 1);
    /// int streak = DailyChallengeSystem.Instance.GetStreak();
    /// </summary>
    public class DailyChallengeSystem : MonoBehaviour
    {
        public static DailyChallengeSystem Instance { get; private set; }

        [Header("Settings")]
        [SerializeField] private int challengesPerDay = 3;
        [SerializeField] private bool autoGenerateChallenges = true;

        [Header("Rewards")]
        [SerializeField] private int baseReward = 50;
        [SerializeField] private int streakBonusPerDay = 10;
        [SerializeField] private int maxStreakBonus = 100;

        // Events
        public event Action<DailyChallenge> OnChallengeCompleted;
        public event Action<int> OnStreakIncreased;
        public event Action OnAllChallengesCompleted;

        private List<DailyChallenge> availableChallenges = new List<DailyChallenge>();
        private List<DailyChallenge> todaysChallenges = new List<DailyChallenge>();
        private Dictionary<string, float> progress = new Dictionary<string, float>();
        private HashSet<string> completedChallenges = new HashSet<string>();

        private int currentStreak = 0;
        private DateTime lastPlayDate;

        private const string SAVE_KEY_PREFIX = "DailyChallenge_";
        private const string STREAK_KEY = "DailyChallenge_Streak";
        private const string LAST_PLAY_KEY = "DailyChallenge_LastPlay";

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
            LoadProgress();
            CheckDailyReset();
        }

        /// <summary>
        /// Register a challenge template
        /// </summary>
        public void RegisterChallenge(DailyChallenge challenge)
        {
            availableChallenges.Add(challenge);
        }

        /// <summary>
        /// Get today's active challenges
        /// </summary>
        public List<DailyChallenge> GetTodaysChallenges()
        {
            return todaysChallenges;
        }

        /// <summary>
        /// Add progress to a challenge
        /// </summary>
        public void AddProgress(string challengeId, float amount)
        {
            DailyChallenge challenge = todaysChallenges.Find(c => c.id == challengeId);
            if (challenge == null)
            {
                return; // Not an active challenge today
            }

            if (completedChallenges.Contains(challengeId))
            {
                return; // Already completed
            }

            float oldProgress = progress.ContainsKey(challengeId) ? progress[challengeId] : 0f;
            float newProgress = Mathf.Min(oldProgress + amount, challenge.targetValue);

            progress[challengeId] = newProgress;
            SaveProgress();

            // Check if completed
            if (newProgress >= challenge.targetValue)
            {
                CompleteChallenge(challenge);
            }
        }

        /// <summary>
        /// Complete a challenge
        /// </summary>
        void CompleteChallenge(DailyChallenge challenge)
        {
            if (completedChallenges.Contains(challenge.id))
            {
                return;
            }

            completedChallenges.Add(challenge.id);

            // Award rewards
            int totalReward = challenge.rewardCoins + GetStreakBonus();
            if (SaveSystem.Instance != null)
            {
                SaveSystem.Instance.AddCurrency("coins", totalReward);
            }

            // Fire event
            OnChallengeCompleted?.Invoke(challenge);

            Debug.Log($"[DailyChallengeSystem] Challenge completed: {challenge.title} (+{totalReward} coins)");

            // Check if all challenges completed
            if (completedChallenges.Count >= todaysChallenges.Count)
            {
                OnAllChallengesCompleted?.Invoke();
                Debug.Log($"[DailyChallengeSystem] All daily challenges completed! Streak: {currentStreak}");
            }

            SaveProgress();

            // Track analytics
            try
            {
                var analyticsType = System.Type.GetType("MobileGameCore.AnalyticsManager");
                if (analyticsType != null)
                {
                    var instanceProp = analyticsType.GetProperty("Instance");
                    var instance = instanceProp?.GetValue(null);
                    if (instance != null)
                    {
                        var trackMethod = analyticsType.GetMethod("TrackEvent");
                        var dict = new Dictionary<string, object>
                        {
                            { "challenge_id", challenge.id },
                            { "streak", currentStreak }
                        };
                        trackMethod?.Invoke(instance, new object[] { "daily_challenge_complete", dict });
                    }
                }
            }
            catch { }
        }

        /// <summary>
        /// Get current progress for a challenge (0-1)
        /// </summary>
        public float GetProgress(string challengeId)
        {
            DailyChallenge challenge = todaysChallenges.Find(c => c.id == challengeId);
            if (challenge == null)
            {
                return 0f;
            }

            if (completedChallenges.Contains(challengeId))
            {
                return 1f;
            }

            float currentProgress = progress.ContainsKey(challengeId) ? progress[challengeId] : 0f;
            return currentProgress / challenge.targetValue;
        }

        /// <summary>
        /// Check if challenge is completed
        /// </summary>
        public bool IsCompleted(string challengeId)
        {
            return completedChallenges.Contains(challengeId);
        }

        /// <summary>
        /// Get current streak
        /// </summary>
        public int GetStreak()
        {
            return currentStreak;
        }

        /// <summary>
        /// Get streak bonus coins
        /// </summary>
        int GetStreakBonus()
        {
            return Mathf.Min(currentStreak * streakBonusPerDay, maxStreakBonus);
        }

        /// <summary>
        /// Check if it's a new day and reset challenges
        /// </summary>
        void CheckDailyReset()
        {
            DateTime today = DateTime.Today;

            if (lastPlayDate.Date < today)
            {
                // Check streak
                if ((today - lastPlayDate.Date).Days == 1)
                {
                    // Consecutive day - increase streak
                    if (completedChallenges.Count >= todaysChallenges.Count && todaysChallenges.Count > 0)
                    {
                        currentStreak++;
                        OnStreakIncreased?.Invoke(currentStreak);
                        Debug.Log($"[DailyChallengeSystem] Streak increased: {currentStreak}");
                    }
                }
                else if ((today - lastPlayDate.Date).Days > 1)
                {
                    // Streak broken
                    if (currentStreak > 0)
                    {
                        Debug.Log($"[DailyChallengeSystem] Streak broken! Was: {currentStreak}");
                    }
                    currentStreak = 0;
                }

                // Reset for new day
                ResetDailyChallenges();
                lastPlayDate = today;
                SaveProgress();
            }
        }

        /// <summary>
        /// Reset challenges for a new day
        /// </summary>
        void ResetDailyChallenges()
        {
            progress.Clear();
            completedChallenges.Clear();
            todaysChallenges.Clear();

            if (autoGenerateChallenges && availableChallenges.Count > 0)
            {
                GenerateDailyChallenges();
            }

            Debug.Log($"[DailyChallengeSystem] Daily challenges reset. {todaysChallenges.Count} challenges active.");
        }

        /// <summary>
        /// Generate random challenges for today
        /// </summary>
        void GenerateDailyChallenges()
        {
            // Shuffle and pick random challenges
            List<DailyChallenge> shuffled = new List<DailyChallenge>(availableChallenges);

            for (int i = shuffled.Count - 1; i > 0; i--)
            {
                int randomIndex = UnityEngine.Random.Range(0, i + 1);
                var temp = shuffled[i];
                shuffled[i] = shuffled[randomIndex];
                shuffled[randomIndex] = temp;
            }

            int count = Mathf.Min(challengesPerDay, shuffled.Count);
            for (int i = 0; i < count; i++)
            {
                todaysChallenges.Add(shuffled[i]);
                progress[shuffled[i].id] = 0f;
            }
        }

        void SaveProgress()
        {
            // Save streak and last play date
            PlayerPrefs.SetInt(STREAK_KEY, currentStreak);
            PlayerPrefs.SetString(LAST_PLAY_KEY, lastPlayDate.ToString("yyyy-MM-dd"));

            // Save progress for each challenge
            foreach (var kvp in progress)
            {
                PlayerPrefs.SetFloat($"{SAVE_KEY_PREFIX}{kvp.Key}_Progress", kvp.Value);
            }

            // Save completed challenges
            string completedIds = string.Join(",", completedChallenges);
            PlayerPrefs.SetString($"{SAVE_KEY_PREFIX}Completed", completedIds);

            // Save today's challenge IDs
            List<string> challengeIds = new List<string>();
            foreach (var challenge in todaysChallenges)
            {
                challengeIds.Add(challenge.id);
            }
            PlayerPrefs.SetString($"{SAVE_KEY_PREFIX}TodaysChallenges", string.Join(",", challengeIds));

            PlayerPrefs.Save();
        }

        void LoadProgress()
        {
            // Load streak and last play date
            currentStreak = PlayerPrefs.GetInt(STREAK_KEY, 0);
            string lastPlayStr = PlayerPrefs.GetString(LAST_PLAY_KEY, DateTime.Today.ToString("yyyy-MM-dd"));

            if (DateTime.TryParse(lastPlayStr, out DateTime parsed))
            {
                lastPlayDate = parsed;
            }
            else
            {
                lastPlayDate = DateTime.Today;
            }

            // Load today's challenges
            string challengeIdsStr = PlayerPrefs.GetString($"{SAVE_KEY_PREFIX}TodaysChallenges", "");
            if (!string.IsNullOrEmpty(challengeIdsStr))
            {
                string[] ids = challengeIdsStr.Split(',');
                foreach (string id in ids)
                {
                    DailyChallenge challenge = availableChallenges.Find(c => c.id == id);
                    if (challenge != null)
                    {
                        todaysChallenges.Add(challenge);
                    }
                }
            }

            // Load progress
            foreach (var challenge in todaysChallenges)
            {
                if (PlayerPrefs.HasKey($"{SAVE_KEY_PREFIX}{challenge.id}_Progress"))
                {
                    progress[challenge.id] = PlayerPrefs.GetFloat($"{SAVE_KEY_PREFIX}{challenge.id}_Progress");
                }
                else
                {
                    progress[challenge.id] = 0f;
                }
            }

            // Load completed challenges
            string completedStr = PlayerPrefs.GetString($"{SAVE_KEY_PREFIX}Completed", "");
            if (!string.IsNullOrEmpty(completedStr))
            {
                string[] completed = completedStr.Split(',');
                foreach (string id in completed)
                {
                    if (!string.IsNullOrEmpty(id))
                    {
                        completedChallenges.Add(id);
                    }
                }
            }

            Debug.Log($"[DailyChallengeSystem] Loaded: Streak {currentStreak}, {todaysChallenges.Count} challenges, {completedChallenges.Count} completed");
        }

        #if UNITY_EDITOR
        [ContextMenu("Force Daily Reset")]
        void ForceReset()
        {
            lastPlayDate = DateTime.Today.AddDays(-2);
            CheckDailyReset();
        }

        [ContextMenu("Complete All Today's Challenges")]
        void CompleteAllChallenges()
        {
            foreach (var challenge in todaysChallenges)
            {
                progress[challenge.id] = challenge.targetValue;
                CompleteChallenge(challenge);
            }
        }
        #endif
    }

    [System.Serializable]
    public class DailyChallenge
    {
        public string id;
        public string title;
        public string description;
        public float targetValue;
        public int rewardCoins;
        public Sprite icon;

        public DailyChallenge(string id, string title, string description, float targetValue, int rewardCoins)
        {
            this.id = id;
            this.title = title;
            this.description = description;
            this.targetValue = targetValue;
            this.rewardCoins = rewardCoins;
        }
    }
}
