using UnityEngine;
using System;
using System.Collections.Generic;

namespace MobileGameCore
{
    /// <summary>
    /// Achievement system for tracking player accomplishments and milestones.
    /// Handles unlocking, progress tracking, notifications, and rewards.
    ///
    /// USAGE:
    /// AchievementSystem.Instance.RegisterAchievement(new Achievement("first_win", "First Win", "Win your first game", 100, 1));
    /// AchievementSystem.Instance.AddProgress("first_win", 1);
    /// bool unlocked = AchievementSystem.Instance.IsUnlocked("first_win");
    /// </summary>
    public class AchievementSystem : MonoBehaviour
    {
        public static AchievementSystem Instance { get; private set; }

        [Header("Settings")]
        [SerializeField] private bool showNotifications = true;
        [SerializeField] private float notificationDuration = 3f;

        // Events
        public event Action<Achievement> OnAchievementUnlocked;
        public event Action<Achievement, float> OnAchievementProgress;

        private Dictionary<string, Achievement> achievements = new Dictionary<string, Achievement>();
        private Dictionary<string, float> progress = new Dictionary<string, float>();
        private HashSet<string> unlockedAchievements = new HashSet<string>();

        private const string SAVE_KEY_PREFIX = "Achievement_";

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
        }

        /// <summary>
        /// Register a new achievement
        /// </summary>
        public void RegisterAchievement(Achievement achievement)
        {
            if (achievements.ContainsKey(achievement.id))
            {
                Debug.LogWarning($"[AchievementSystem] Achievement {achievement.id} already registered");
                return;
            }

            achievements[achievement.id] = achievement;

            // Initialize progress
            if (!progress.ContainsKey(achievement.id))
            {
                progress[achievement.id] = 0f;
            }
        }

        /// <summary>
        /// Add progress to an achievement
        /// </summary>
        public void AddProgress(string achievementId, float amount)
        {
            if (!achievements.ContainsKey(achievementId))
            {
                Debug.LogWarning($"[AchievementSystem] Achievement {achievementId} not found");
                return;
            }

            if (unlockedAchievements.Contains(achievementId))
            {
                return; // Already unlocked
            }

            Achievement achievement = achievements[achievementId];
            float oldProgress = progress[achievementId];
            float newProgress = Mathf.Min(oldProgress + amount, achievement.maxProgress);

            progress[achievementId] = newProgress;
            SaveProgress(achievementId);

            // Fire progress event
            OnAchievementProgress?.Invoke(achievement, newProgress / achievement.maxProgress);

            // Check if unlocked
            if (newProgress >= achievement.maxProgress)
            {
                UnlockAchievement(achievementId);
            }
        }

        /// <summary>
        /// Set progress to specific value
        /// </summary>
        public void SetProgress(string achievementId, float amount)
        {
            if (!achievements.ContainsKey(achievementId))
            {
                Debug.LogWarning($"[AchievementSystem] Achievement {achievementId} not found");
                return;
            }

            if (unlockedAchievements.Contains(achievementId))
            {
                return;
            }

            Achievement achievement = achievements[achievementId];
            float newProgress = Mathf.Min(amount, achievement.maxProgress);

            progress[achievementId] = newProgress;
            SaveProgress(achievementId);

            OnAchievementProgress?.Invoke(achievement, newProgress / achievement.maxProgress);

            if (newProgress >= achievement.maxProgress)
            {
                UnlockAchievement(achievementId);
            }
        }

        /// <summary>
        /// Unlock achievement immediately
        /// </summary>
        void UnlockAchievement(string achievementId)
        {
            if (unlockedAchievements.Contains(achievementId))
            {
                return;
            }

            Achievement achievement = achievements[achievementId];
            unlockedAchievements.Add(achievementId);

            // Mark as unlocked in save
            PlayerPrefs.SetInt($"{SAVE_KEY_PREFIX}{achievementId}_Unlocked", 1);
            PlayerPrefs.Save();

            // Award rewards
            if (achievement.rewardCoins > 0 && SaveSystem.Instance != null)
            {
                SaveSystem.Instance.AddCurrency("coins", achievement.rewardCoins);
            }

            // Fire event
            OnAchievementUnlocked?.Invoke(achievement);

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
                        var trackMethod = analyticsType.GetMethod("TrackAchievement");
                        trackMethod?.Invoke(instance, new object[] { achievement.id });
                    }
                }
            }
            catch { }

            Debug.Log($"[AchievementSystem] Achievement unlocked: {achievement.title}");

            if (showNotifications)
            {
                ShowNotification(achievement);
            }
        }

        /// <summary>
        /// Check if achievement is unlocked
        /// </summary>
        public bool IsUnlocked(string achievementId)
        {
            return unlockedAchievements.Contains(achievementId);
        }

        /// <summary>
        /// Get achievement progress (0-1)
        /// </summary>
        public float GetProgress(string achievementId)
        {
            if (!achievements.ContainsKey(achievementId))
            {
                return 0f;
            }

            if (unlockedAchievements.Contains(achievementId))
            {
                return 1f;
            }

            Achievement achievement = achievements[achievementId];
            return progress[achievementId] / achievement.maxProgress;
        }

        /// <summary>
        /// Get all achievements
        /// </summary>
        public List<Achievement> GetAllAchievements()
        {
            return new List<Achievement>(achievements.Values);
        }

        /// <summary>
        /// Get unlocked achievements count
        /// </summary>
        public int GetUnlockedCount()
        {
            return unlockedAchievements.Count;
        }

        void ShowNotification(Achievement achievement)
        {
            // Placeholder - implement UI notification
            Debug.Log($"🏆 Achievement Unlocked: {achievement.title}\n{achievement.description}\n+{achievement.rewardCoins} coins");
        }

        void SaveProgress(string achievementId)
        {
            PlayerPrefs.SetFloat($"{SAVE_KEY_PREFIX}{achievementId}_Progress", progress[achievementId]);
        }

        void LoadProgress()
        {
            foreach (var kvp in achievements)
            {
                string id = kvp.Key;

                // Load progress
                if (PlayerPrefs.HasKey($"{SAVE_KEY_PREFIX}{id}_Progress"))
                {
                    progress[id] = PlayerPrefs.GetFloat($"{SAVE_KEY_PREFIX}{id}_Progress");
                }

                // Load unlocked status
                if (PlayerPrefs.GetInt($"{SAVE_KEY_PREFIX}{id}_Unlocked", 0) == 1)
                {
                    unlockedAchievements.Add(id);
                }
            }

            Debug.Log($"[AchievementSystem] Loaded progress for {achievements.Count} achievements ({unlockedAchievements.Count} unlocked)");
        }

        #if UNITY_EDITOR
        [ContextMenu("Reset All Achievements")]
        void ResetAllAchievements()
        {
            foreach (var id in achievements.Keys)
            {
                PlayerPrefs.DeleteKey($"{SAVE_KEY_PREFIX}{id}_Progress");
                PlayerPrefs.DeleteKey($"{SAVE_KEY_PREFIX}{id}_Unlocked");
            }

            progress.Clear();
            unlockedAchievements.Clear();

            foreach (var id in achievements.Keys)
            {
                progress[id] = 0f;
            }

            PlayerPrefs.Save();
            Debug.Log("[AchievementSystem] All achievements reset");
        }
        #endif
    }

    [System.Serializable]
    public class Achievement
    {
        public string id;
        public string title;
        public string description;
        public string category;
        public int rewardCoins;
        public float maxProgress;
        public Sprite icon;

        public Achievement(string id, string title, string description, int rewardCoins, float maxProgress, string category = "general")
        {
            this.id = id;
            this.title = title;
            this.description = description;
            this.rewardCoins = rewardCoins;
            this.maxProgress = maxProgress;
            this.category = category;
        }
    }
}
