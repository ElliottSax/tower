using UnityEngine;
using UnityEngine.Events;
using System.Collections.Generic;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Manages scoring for endless runner mode.
    /// Combines distance-based score with treasure collection and multipliers.
    /// </summary>
    public class EndlessScoreManager : MonoBehaviour
    {
        public static EndlessScoreManager Instance { get; private set; }

        [Header("Score Settings")]
        [Tooltip("Base points earned per meter traveled")]
        public int baseScorePerMeter = 1;

        [Tooltip("Points per treasure collected")]
        public int treasureValue = 10;

        [Tooltip("Bonus points for passing through gates")]
        public int gatePassBonus = 50;

        [Tooltip("Bonus for destroying obstacles (if power-up active)")]
        public int obstacleDestroyBonus = 25;

        [Header("Multiplier Settings")]
        [Tooltip("Maximum multiplier cap to prevent overflow")]
        public float maxMultiplier = 100f;

        [Header("Events")]
        public UnityEvent<int> OnScoreChanged;
        public UnityEvent<int> OnCoinsChanged;
        public UnityEvent<float> OnMultiplierChanged;

        // Private fields
        private int currentScore = 0;
        private int currentCoins = 0;
        private int currentTreasures = 0;
        private float currentMultiplier = 1f;
        private int highScore = 0;

        // Public properties
        public int CurrentScore => currentScore;
        public int CurrentCoins => currentCoins;
        public int CurrentTreasures => currentTreasures;
        public float CurrentMultiplier => currentMultiplier;
        public int HighScore => highScore;

        #region Unity Lifecycle

        void Awake()
        {
            // Singleton pattern
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Debug.LogWarning("Multiple EndlessScoreManager instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Load high score
            LoadHighScore();

            // Subscribe to distance changes
            if (DistanceTracker.Instance != null)
            {
                DistanceTracker.Instance.OnDistanceChanged.AddListener(UpdateDistanceScore);
            }

            Debug.Log($"EndlessScoreManager: Initialized. High Score: {highScore}");
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (DistanceTracker.Instance != null)
            {
                DistanceTracker.Instance.OnDistanceChanged.RemoveListener(UpdateDistanceScore);
            }
        }

        #endregion

        #region Scoring

        /// <summary>
        /// Updates score based on distance traveled
        /// </summary>
        void UpdateDistanceScore(float distance)
        {
            // Calculate distance-based score with multiplier
            int distanceScore = Mathf.FloorToInt(distance * baseScorePerMeter * currentMultiplier);

            // Update total score (distance + treasures + bonuses)
            currentScore = distanceScore + (currentTreasures * treasureValue);

            // Fire score changed event
            OnScoreChanged?.Invoke(currentScore);
        }

        /// <summary>
        /// Called when player collects a treasure
        /// </summary>
        public void CollectTreasure(int value = 1)
        {
            currentTreasures++;
            currentCoins += Mathf.RoundToInt(value * currentMultiplier);

            // Update score
            currentScore += Mathf.RoundToInt(treasureValue * currentMultiplier);

            // Fire events
            OnCoinsChanged?.Invoke(currentCoins);
            OnScoreChanged?.Invoke(currentScore);

            // Visual/audio feedback
            ShowCollectionFeedback(value);

            Debug.Log($"💎 Treasure Collected! Total: {currentTreasures}, Coins: +{value * currentMultiplier}");
        }

        /// <summary>
        /// Called when player passes through a multiplier gate
        /// </summary>
        public void PassThroughGate(int multiplier)
        {
            // Multiply current multiplier
            currentMultiplier *= multiplier;

            // Cap multiplier
            currentMultiplier = Mathf.Min(currentMultiplier, maxMultiplier);

            // Add gate pass bonus
            currentScore += gatePassBonus;

            // Fire event
            OnMultiplierChanged?.Invoke(currentMultiplier);
            OnScoreChanged?.Invoke(currentScore);

            // Visual/audio feedback
            ShowGateFeedback(multiplier);

            Debug.Log($"⚡ Gate x{multiplier}! New Multiplier: x{currentMultiplier}");
        }

        /// <summary>
        /// Called when player destroys an obstacle (with power-up)
        /// </summary>
        public void DestroyObstacle()
        {
            int bonus = Mathf.RoundToInt(obstacleDestroyBonus * currentMultiplier);
            currentScore += bonus;
            currentCoins += bonus / 2;

            OnScoreChanged?.Invoke(currentScore);
            OnCoinsChanged?.Invoke(currentCoins);

            Debug.Log($"💥 Obstacle Destroyed! +{bonus} points");
        }

        #endregion

        #region Visual Feedback

        /// <summary>
        /// Shows visual/audio feedback for treasure collection
        /// </summary>
        void ShowCollectionFeedback(int value)
        {
            // Camera shake (light)
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ShakeLight();
            }

            // Audio
            if (AudioManager.Instance != null)
            {
                float pitch = Random.Range(0.9f, 1.1f);
                AudioManager.Instance.PlaySFX("collect", pitch: pitch);
            }

            // Particles
            if (ParticleEffectManager.Instance != null)
            {
                // Will be implemented with treasure position
            }

            // HUD flash
            if (HUDManager.Instance != null)
            {
                HUDManager.Instance.FlashCoinCounter();
            }
        }

        /// <summary>
        /// Shows visual/audio feedback for gate multiplier
        /// </summary>
        void ShowGateFeedback(int multiplier)
        {
            // Camera shake (scaled by multiplier)
            if (CameraController.Instance != null)
            {
                float intensity = Mathf.Log(multiplier, 2) * 0.15f;
                CameraController.Instance.Shake(0.3f + intensity, 0.4f);
            }

            // Game feel hit freeze
            if (GameFeelManager.Instance != null)
            {
                float freezeDuration = 0.05f + (Mathf.Log(multiplier, 2) * 0.02f);
                GameFeelManager.Instance.HitFreeze(freezeDuration);
            }

            // Audio (chord sound, higher for bigger multipliers)
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlayChord(440 * multiplier, 0.5f);
            }

            // HUD multiplier display
            if (HUDManager.Instance != null)
            {
                HUDManager.Instance.ShowMultiplierBonus(multiplier);
            }
        }

        #endregion

        #region Run Management

        /// <summary>
        /// Called when the run ends (game over)
        /// </summary>
        public void OnRunEnd()
        {
            // Award coins to economy
            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(currentCoins);
            }

            // Save high score
            SaveHighScore();

            // Analytics
            LogRunAnalytics();

            // Achievement check
            CheckScoreAchievements();

            Debug.Log($"🏁 Run Ended - Score: {currentScore}, Coins: {currentCoins}, Multiplier: x{currentMultiplier}");
        }

        /// <summary>
        /// Resets score for a new run
        /// </summary>
        public void ResetRun()
        {
            currentScore = 0;
            currentCoins = 0;
            currentTreasures = 0;
            currentMultiplier = 1f;

            OnScoreChanged?.Invoke(currentScore);
            OnCoinsChanged?.Invoke(currentCoins);
            OnMultiplierChanged?.Invoke(currentMultiplier);

            Debug.Log("EndlessScoreManager: Reset for new run");
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Loads high score from save system
        /// </summary>
        void LoadHighScore()
        {
            var saveSystem = FindObjectOfType<SaveSystem>();
            if (saveSystem != null)
            {
                highScore = saveSystem.GetInt("high_score_endless", 0);
            }
            else
            {
                highScore = PlayerPrefs.GetInt("HighScore", 0);
            }
        }

        /// <summary>
        /// Saves high score if current score is higher
        /// </summary>
        void SaveHighScore()
        {
            if (currentScore > highScore)
            {
                highScore = currentScore;

                var saveSystem = FindObjectOfType<SaveSystem>();
                if (saveSystem != null)
                {
                    saveSystem.SetInt("high_score_endless", highScore);
                    saveSystem.Save();
                }
                else
                {
                    PlayerPrefs.SetInt("HighScore", highScore);
                    PlayerPrefs.Save();
                }

                // Achievement: New record
                var achievementSystem = FindObjectOfType<AchievementSystem>();
                if (achievementSystem != null)
                {
                    achievementSystem.UnlockAchievement("new_record");
                }

                Debug.Log($"🏆 NEW HIGH SCORE: {highScore}!");
            }
        }

        #endregion

        #region Analytics

        /// <summary>
        /// Logs run analytics to Firebase/Analytics
        /// </summary>
        void LogRunAnalytics()
        {
            var analyticsManager = FindObjectOfType<AnalyticsManager>();
            if (analyticsManager == null) return;

            analyticsManager.LogEvent("run_complete", new Dictionary<string, object>
            {
                { "score", currentScore },
                { "distance", DistanceTracker.Instance.CurrentDistance },
                { "coins", currentCoins },
                { "treasures", currentTreasures },
                { "multiplier", currentMultiplier },
                { "is_new_record", currentScore > highScore }
            });
        }

        /// <summary>
        /// Checks and unlocks score-based achievements
        /// </summary>
        void CheckScoreAchievements()
        {
            var achievementSystem = FindObjectOfType<AchievementSystem>();
            if (achievementSystem == null) return;

            if (currentScore >= 1000)
                achievementSystem.UnlockAchievement("score_1k");

            if (currentScore >= 10000)
                achievementSystem.UnlockAchievement("score_10k");

            if (currentScore >= 100000)
                achievementSystem.UnlockAchievement("score_100k");

            if (currentScore >= 1000000)
                achievementSystem.UnlockAchievement("score_1m");

            // Multiplier achievements
            if (currentMultiplier >= 10)
                achievementSystem.UnlockAchievement("multiplier_10");

            if (currentMultiplier >= 50)
                achievementSystem.UnlockAchievement("multiplier_50");

            if (currentMultiplier >= 100)
                achievementSystem.UnlockAchievement("multiplier_100");
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Returns formatted score string (e.g., "12,345")
        /// </summary>
        public string GetFormattedScore() => currentScore.ToString("N0");

        /// <summary>
        /// Returns formatted coins string
        /// </summary>
        public string GetFormattedCoins() => currentCoins.ToString("N0");

        /// <summary>
        /// Returns formatted multiplier string (e.g., "x10.5")
        /// </summary>
        public string GetFormattedMultiplier() => $"x{currentMultiplier:F1}";

        /// <summary>
        /// Adds coins directly (called by CoinBehavior when coins are collected)
        /// </summary>
        public void AddCoins(int amount)
        {
            if (amount <= 0) return;

            int adjustedAmount = Mathf.RoundToInt(amount * currentMultiplier);
            currentCoins += adjustedAmount;
            currentScore += adjustedAmount;

            OnCoinsChanged?.Invoke(currentCoins);
            OnScoreChanged?.Invoke(currentScore);

            Debug.Log($"Coins Added: +{adjustedAmount} (Total: {currentCoins})");
        }

        #endregion
    }
}
