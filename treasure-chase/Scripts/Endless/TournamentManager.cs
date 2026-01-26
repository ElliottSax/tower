using UnityEngine;
using UnityEngine.Events;
using System.Collections.Generic;
using System.Linq;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Manages tournament events and competitive leaderboards.
    /// Handles daily/weekly tournaments, rewards, and player rankings.
    /// </summary>
    public class TournamentManager : MonoBehaviour
    {
        public static TournamentManager Instance { get; private set; }

        [Header("Tournament Settings")]
        [Tooltip("Duration of daily tournaments (hours)")]
        public int dailyTournamentDuration = 24;

        [Tooltip("Duration of weekly tournaments (days)")]
        public int weeklyTournamentDuration = 7;

        [Tooltip("Number of attempts per tournament")]
        public int maxAttemptsPerTournament = 3;

        [Header("Rewards")]
        [Tooltip("Reward tiers based on rank percentile")]
        public TournamentRewardTier[] rewardTiers;

        [Header("Entry Costs")]
        [Tooltip("Cost to enter daily tournament (coins)")]
        public int dailyTournamentCost = 0; // Free

        [Tooltip("Cost to enter weekly tournament (coins)")]
        public int weeklyTournamentCost = 100;

        [Tooltip("Cost to enter premium tournament (coins)")]
        public int premiumTournamentCost = 500;

        [Header("Events")]
        public UnityEvent<Tournament> OnTournamentStarted;
        public UnityEvent<Tournament> OnTournamentEnded;
        public UnityEvent<TournamentScore> OnNewPersonalBest;

        // Private fields
        private Tournament activeDailyTournament;
        private Tournament activeWeeklyTournament;
        private Tournament activePremiumTournament;
        private Dictionary<string, List<TournamentScore>> leaderboards;

        // Public properties
        public Tournament ActiveDailyTournament => activeDailyTournament;
        public Tournament ActiveWeeklyTournament => activeWeeklyTournament;
        public bool HasActiveTournament => activeDailyTournament != null || activeWeeklyTournament != null;

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
                Debug.LogWarning("Multiple TournamentManager instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Initialize leaderboards
            leaderboards = new Dictionary<string, List<TournamentScore>>();

            // Check for active tournaments
            CheckActiveTournaments();

            // Schedule tournament updates
            InvokeRepeating(nameof(UpdateTournaments), 60f, 60f); // Every minute

            Debug.Log("TournamentManager: Initialized");
        }

        #endregion

        #region Tournament Lifecycle

        /// <summary>
        /// Checks and updates active tournaments
        /// </summary>
        void UpdateTournaments()
        {
            // Check daily tournament
            if (activeDailyTournament != null && System.DateTime.Now > activeDailyTournament.endTime)
            {
                EndTournament(activeDailyTournament);
                activeDailyTournament = null;
            }

            // Check weekly tournament
            if (activeWeeklyTournament != null && System.DateTime.Now > activeWeeklyTournament.endTime)
            {
                EndTournament(activeWeeklyTournament);
                activeWeeklyTournament = null;
            }

            // Create new tournaments if needed
            CheckActiveTournaments();
        }

        /// <summary>
        /// Checks if tournaments need to be created
        /// </summary>
        void CheckActiveTournaments()
        {
            // Create daily tournament if none active
            if (activeDailyTournament == null)
            {
                CreateDailyTournament();
            }

            // Create weekly tournament if none active
            if (activeWeeklyTournament == null)
            {
                CreateWeeklyTournament();
            }
        }

        /// <summary>
        /// Creates a new daily tournament
        /// </summary>
        void CreateDailyTournament()
        {
            activeDailyTournament = new Tournament
            {
                id = $"daily_{System.DateTime.Now:yyyyMMdd}",
                name = "Daily Challenge",
                description = "Compete for the highest score today!",
                type = TournamentType.Daily,
                startTime = System.DateTime.Now,
                endTime = System.DateTime.Now.AddHours(dailyTournamentDuration),
                entryCost = dailyTournamentCost,
                maxAttempts = maxAttemptsPerTournament,
                isActive = true
            };

            // Initialize leaderboard
            leaderboards[activeDailyTournament.id] = new List<TournamentScore>();

            OnTournamentStarted?.Invoke(activeDailyTournament);

            Debug.Log($"🏆 Daily Tournament Started: {activeDailyTournament.name}");
        }

        /// <summary>
        /// Creates a new weekly tournament
        /// </summary>
        void CreateWeeklyTournament()
        {
            activeWeeklyTournament = new Tournament
            {
                id = $"weekly_{GetWeekNumber()}",
                name = "Weekly Championship",
                description = "Prove you're the best this week!",
                type = TournamentType.Weekly,
                startTime = System.DateTime.Now,
                endTime = System.DateTime.Now.AddDays(weeklyTournamentDuration),
                entryCost = weeklyTournamentCost,
                maxAttempts = maxAttemptsPerTournament,
                isActive = true
            };

            // Initialize leaderboard
            leaderboards[activeWeeklyTournament.id] = new List<TournamentScore>();

            OnTournamentStarted?.Invoke(activeWeeklyTournament);

            Debug.Log($"🏆 Weekly Tournament Started: {activeWeeklyTournament.name}");
        }

        /// <summary>
        /// Ends a tournament and distributes rewards
        /// </summary>
        void EndTournament(Tournament tournament)
        {
            if (tournament == null) return;

            tournament.isActive = false;

            // Get final leaderboard
            var finalLeaderboard = GetLeaderboard(tournament.id);

            // Distribute rewards
            DistributeRewards(tournament, finalLeaderboard);

            OnTournamentEnded?.Invoke(tournament);

            Debug.Log($"🏆 Tournament Ended: {tournament.name} - {finalLeaderboard.Count} participants");

            // Log analytics
            LogTournamentAnalytics(tournament, finalLeaderboard);
        }

        #endregion

        #region Score Submission

        /// <summary>
        /// Submits a score to active tournament
        /// </summary>
        public void SubmitScore(int score, float distance, int coins)
        {
            var playerId = GetPlayerId();

            // Submit to daily tournament
            if (activeDailyTournament != null && activeDailyTournament.isActive)
            {
                SubmitScoreToTournament(activeDailyTournament, playerId, score, distance, coins);
            }

            // Submit to weekly tournament
            if (activeWeeklyTournament != null && activeWeeklyTournament.isActive)
            {
                SubmitScoreToTournament(activeWeeklyTournament, playerId, score, distance, coins);
            }
        }

        /// <summary>
        /// Submits score to specific tournament
        /// </summary>
        void SubmitScoreToTournament(Tournament tournament, string playerId, int score, float distance, int coins)
        {
            if (!leaderboards.ContainsKey(tournament.id))
            {
                Debug.LogError($"TournamentManager: Leaderboard not found for tournament {tournament.id}");
                return;
            }

            var leaderboard = leaderboards[tournament.id];

            // Find existing player score
            var existingScore = leaderboard.FirstOrDefault(s => s.playerId == playerId);

            if (existingScore != null)
            {
                // Update if new score is better
                if (score > existingScore.score)
                {
                    existingScore.score = score;
                    existingScore.distance = distance;
                    existingScore.coins = coins;
                    existingScore.timestamp = System.DateTime.Now;
                    existingScore.attempts++;

                    OnNewPersonalBest?.Invoke(existingScore);

                    Debug.Log($"🎯 New Tournament PB! Score: {score}");
                }
                else
                {
                    existingScore.attempts++;
                }
            }
            else
            {
                // New entry
                var newScore = new TournamentScore
                {
                    playerId = playerId,
                    playerName = GetPlayerName(),
                    score = score,
                    distance = distance,
                    coins = coins,
                    timestamp = System.DateTime.Now,
                    attempts = 1
                };

                leaderboard.Add(newScore);

                OnNewPersonalBest?.Invoke(newScore);

                Debug.Log($"🎯 Tournament Entry! Score: {score}");
            }

            // Sort leaderboard
            leaderboard.Sort((a, b) => b.score.CompareTo(a.score));
        }

        #endregion

        #region Leaderboards

        /// <summary>
        /// Gets leaderboard for tournament
        /// </summary>
        public List<TournamentScore> GetLeaderboard(string tournamentId, int topN = 100)
        {
            if (!leaderboards.ContainsKey(tournamentId))
            {
                return new List<TournamentScore>();
            }

            var leaderboard = leaderboards[tournamentId];
            return leaderboard.Take(topN).ToList();
        }

        /// <summary>
        /// Gets player's rank in tournament
        /// </summary>
        public int GetPlayerRank(string tournamentId, string playerId)
        {
            if (!leaderboards.ContainsKey(tournamentId))
            {
                return -1;
            }

            var leaderboard = leaderboards[tournamentId];
            var playerScore = leaderboard.FirstOrDefault(s => s.playerId == playerId);

            if (playerScore == null)
            {
                return -1; // Not participating
            }

            return leaderboard.IndexOf(playerScore) + 1;
        }

        /// <summary>
        /// Gets player's percentile in tournament
        /// </summary>
        public float GetPlayerPercentile(string tournamentId, string playerId)
        {
            if (!leaderboards.ContainsKey(tournamentId))
            {
                return 100f;
            }

            var leaderboard = leaderboards[tournamentId];
            if (leaderboard.Count == 0) return 100f;

            int rank = GetPlayerRank(tournamentId, playerId);
            if (rank == -1) return 100f;

            return (float)rank / leaderboard.Count * 100f;
        }

        #endregion

        #region Rewards

        /// <summary>
        /// Distributes rewards to tournament participants
        /// </summary>
        void DistributeRewards(Tournament tournament, List<TournamentScore> leaderboard)
        {
            if (leaderboard.Count == 0) return;

            foreach (var score in leaderboard)
            {
                float percentile = GetPlayerPercentile(tournament.id, score.playerId);
                var reward = GetRewardForPercentile(percentile);

                if (reward != null)
                {
                    AwardReward(score.playerId, reward);
                }
            }
        }

        /// <summary>
        /// Gets reward tier for percentile
        /// </summary>
        TournamentRewardTier GetRewardForPercentile(float percentile)
        {
            if (rewardTiers == null || rewardTiers.Length == 0)
            {
                return null;
            }

            foreach (var tier in rewardTiers)
            {
                if (percentile <= tier.percentileThreshold)
                {
                    return tier;
                }
            }

            return null; // No reward
        }

        /// <summary>
        /// Awards reward to player
        /// </summary>
        void AwardReward(string playerId, TournamentRewardTier reward)
        {
            // Only award to current player
            if (playerId != GetPlayerId()) return;

            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(reward.coinReward);
                economyManager.AddGems(reward.gemReward);
            }

            Debug.Log($"🎁 Tournament Reward: {reward.coinReward} coins, {reward.gemReward} gems ({reward.tierName})");
        }

        #endregion

        #region Utility

        /// <summary>
        /// Gets player ID
        /// </summary>
        string GetPlayerId()
        {
            // Use device ID or account ID
            return SystemInfo.deviceUniqueIdentifier;
        }

        /// <summary>
        /// Gets player name
        /// </summary>
        string GetPlayerName()
        {
            var playerProfile = FindObjectOfType<PlayerProfile>();
            if (playerProfile != null)
            {
                return playerProfile.PlayerName;
            }
            return "Player";
        }

        /// <summary>
        /// Gets current week number
        /// </summary>
        int GetWeekNumber()
        {
            var culture = System.Globalization.CultureInfo.CurrentCulture;
            var calendar = culture.Calendar;
            var dateTimeInfo = culture.DateTimeFormat;
            return calendar.GetWeekOfYear(System.DateTime.Now, dateTimeInfo.CalendarWeekRule, dateTimeInfo.FirstDayOfWeek);
        }

        /// <summary>
        /// Logs tournament analytics
        /// </summary>
        void LogTournamentAnalytics(Tournament tournament, List<TournamentScore> leaderboard)
        {
            var analyticsManager = FindObjectOfType<AnalyticsManager>();
            if (analyticsManager == null) return;

            analyticsManager.LogEvent("tournament_ended", new Dictionary<string, object>
            {
                { "tournament_id", tournament.id },
                { "tournament_type", tournament.type.ToString() },
                { "participants", leaderboard.Count },
                { "top_score", leaderboard.Count > 0 ? leaderboard[0].score : 0 },
                { "avg_score", leaderboard.Count > 0 ? leaderboard.Average(s => s.score) : 0 }
            });
        }

        #endregion
    }

    /// <summary>
    /// Tournament data structure
    /// </summary>
    [System.Serializable]
    public class Tournament
    {
        public string id;
        public string name;
        public string description;
        public TournamentType type;
        public System.DateTime startTime;
        public System.DateTime endTime;
        public int entryCost;
        public int maxAttempts;
        public bool isActive;
    }

    /// <summary>
    /// Tournament score entry
    /// </summary>
    [System.Serializable]
    public class TournamentScore
    {
        public string playerId;
        public string playerName;
        public int score;
        public float distance;
        public int coins;
        public System.DateTime timestamp;
        public int attempts;
    }

    /// <summary>
    /// Tournament types
    /// </summary>
    public enum TournamentType
    {
        Daily,
        Weekly,
        Premium,
        Special
    }

    /// <summary>
    /// Reward tier configuration
    /// </summary>
    [System.Serializable]
    public class TournamentRewardTier
    {
        public string tierName = "Gold";
        [Tooltip("Top X% of players receive this reward")]
        public float percentileThreshold = 10f; // Top 10%
        public int coinReward = 1000;
        public int gemReward = 50;
    }
}
