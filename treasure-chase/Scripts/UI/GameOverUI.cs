using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.SceneManagement;
using System.Collections;

namespace TreasureChase.UI
{
    /// <summary>
    /// Game over screen showing run results, stats, and options.
    /// </summary>
    public class GameOverUI : MonoBehaviour
    {
        [Header("Panels")]
        [Tooltip("Main game over panel")]
        public GameObject gameOverPanel;

        [Tooltip("Results panel (score, distance, etc.)")]
        public GameObject resultsPanel;

        [Tooltip("New record panel (shown if high score)")]
        public GameObject newRecordPanel;

        [Header("Score Display")]
        [Tooltip("Final score text")]
        public TextMeshProUGUI finalScoreText;

        [Tooltip("High score text")]
        public TextMeshProUGUI highScoreText;

        [Tooltip("Score difference (e.g., +1,234 from previous)")]
        public TextMeshProUGUI scoreDifferenceText;

        [Header("Stats Display")]
        [Tooltip("Distance traveled")]
        public TextMeshProUGUI distanceText;

        [Tooltip("Coins collected")]
        public TextMeshProUGUI coinsCollectedText;

        [Tooltip("Treasures collected")]
        public TextMeshProUGUI treasuresCollectedText;

        [Tooltip("Max multiplier reached")]
        public TextMeshProUGUI maxMultiplierText;

        [Header("Rewards Display")]
        [Tooltip("Total coins earned text")]
        public TextMeshProUGUI totalCoinsEarnedText;

        [Tooltip("Bonus coins text (from achievements, etc.)")]
        public TextMeshProUGUI bonusCoinsText;

        [Header("Tournament Display")]
        [Tooltip("Tournament rank text")]
        public TextMeshProUGUI tournamentRankText;

        [Tooltip("Tournament container (hidden if not in tournament)")]
        public GameObject tournamentContainer;

        [Header("Buttons")]
        [Tooltip("Retry button")]
        public Button retryButton;

        [Tooltip("Main menu button")]
        public Button mainMenuButton;

        [Tooltip("Watch ad for 2x coins button")]
        public Button watchAdButton;

        [Tooltip("Share button")]
        public Button shareButton;

        [Header("Animation")]
        [Tooltip("Delay before showing panel")]
        public float showDelay = 1f;

        [Tooltip("Count-up animation speed")]
        public float countUpSpeed = 1000f;

        // Private fields
        private int displayedScore = 0;
        private int targetScore = 0;
        private bool hasWatchedAd = false;

        #region Unity Lifecycle

        void Start()
        {
            // Hide initially
            if (gameOverPanel != null)
            {
                gameOverPanel.SetActive(false);
            }

            // Setup buttons
            SetupButtons();
        }

        #endregion

        #region Setup

        /// <summary>
        /// Sets up button listeners
        /// </summary>
        void SetupButtons()
        {
            if (retryButton != null)
            {
                retryButton.onClick.AddListener(OnRetryPressed);
            }

            if (mainMenuButton != null)
            {
                mainMenuButton.onClick.AddListener(OnMainMenuPressed);
            }

            if (watchAdButton != null)
            {
                watchAdButton.onClick.AddListener(OnWatchAdPressed);
            }

            if (shareButton != null)
            {
                shareButton.onClick.AddListener(OnSharePressed);
            }
        }

        #endregion

        #region Show Game Over

        /// <summary>
        /// Shows game over screen with results
        /// </summary>
        public void Show()
        {
            StartCoroutine(ShowSequence());
        }

        /// <summary>
        /// Animated game over sequence
        /// </summary>
        IEnumerator ShowSequence()
        {
            // Delay before showing
            yield return new WaitForSeconds(showDelay);

            // Show panel
            if (gameOverPanel != null)
            {
                gameOverPanel.SetActive(true);
            }

            // Collect data from managers
            CollectRunData();

            // Animate score count-up
            yield return StartCoroutine(AnimateScoreCountUp());

            // Show stats
            ShowStats();

            // Check for new record
            CheckNewRecord();

            // Show tournament results
            ShowTournamentResults();

            // Calculate and show rewards
            ShowRewards();
        }

        /// <summary>
        /// Collects run data from game managers
        /// </summary>
        void CollectRunData()
        {
            if (Endless.EndlessScoreManager.Instance != null)
            {
                targetScore = Endless.EndlessScoreManager.Instance.CurrentScore;
            }
        }

        /// <summary>
        /// Animates score count-up
        /// </summary>
        IEnumerator AnimateScoreCountUp()
        {
            displayedScore = 0;

            while (displayedScore < targetScore)
            {
                displayedScore = Mathf.Min(displayedScore + Mathf.CeilToInt(countUpSpeed * Time.deltaTime), targetScore);

                if (finalScoreText != null)
                {
                    finalScoreText.text = displayedScore.ToString("N0");
                }

                yield return null;
            }

            // Final value
            if (finalScoreText != null)
            {
                finalScoreText.text = targetScore.ToString("N0");
            }
        }

        #endregion

        #region Stats Display

        /// <summary>
        /// Shows run statistics
        /// </summary>
        void ShowStats()
        {
            if (Endless.DistanceTracker.Instance != null && distanceText != null)
            {
                distanceText.text = $"{Endless.DistanceTracker.Instance.CurrentDistance:F0}m";
            }

            if (Endless.EndlessScoreManager.Instance != null)
            {
                if (coinsCollectedText != null)
                {
                    coinsCollectedText.text = Endless.EndlessScoreManager.Instance.CurrentCoins.ToString("N0");
                }

                if (treasuresCollectedText != null)
                {
                    treasuresCollectedText.text = Endless.EndlessScoreManager.Instance.CurrentTreasures.ToString();
                }

                if (maxMultiplierText != null)
                {
                    maxMultiplierText.text = $"x{Endless.EndlessScoreManager.Instance.CurrentMultiplier:F1}";
                }

                if (highScoreText != null)
                {
                    highScoreText.text = $"Best: {Endless.EndlessScoreManager.Instance.HighScore:N0}";
                }
            }
        }

        /// <summary>
        /// Checks if new record and shows indicator
        /// </summary>
        void CheckNewRecord()
        {
            if (Endless.EndlessScoreManager.Instance == null) return;

            bool isNewRecord = targetScore > Endless.EndlessScoreManager.Instance.HighScore;

            if (newRecordPanel != null)
            {
                newRecordPanel.SetActive(isNewRecord);
            }

            if (isNewRecord)
            {
                // Play celebration effect
                PlayNewRecordEffect();
            }

            // Show score difference
            if (scoreDifferenceText != null && Endless.EndlessScoreManager.Instance.HighScore > 0)
            {
                int difference = targetScore - Endless.EndlessScoreManager.Instance.HighScore;
                if (difference > 0)
                {
                    scoreDifferenceText.text = $"+{difference:N0}";
                    scoreDifferenceText.color = Color.green;
                }
                else
                {
                    scoreDifferenceText.text = $"{difference:N0}";
                    scoreDifferenceText.color = Color.red;
                }
            }
        }

        /// <summary>
        /// Plays new record celebration effect
        /// </summary>
        void PlayNewRecordEffect()
        {
            // Confetti particles
            if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("confetti", Vector3.zero);
            }

            // Sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("new_record", volume: 1f);
            }

            // Haptic feedback
            if (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer)
            {
                Handheld.Vibrate();
            }

            Debug.Log("🏆 NEW RECORD!");
        }

        #endregion

        #region Tournament Results

        /// <summary>
        /// Shows tournament results if applicable
        /// </summary>
        void ShowTournamentResults()
        {
            if (Endless.TournamentManager.Instance == null)
            {
                if (tournamentContainer != null)
                {
                    tournamentContainer.SetActive(false);
                }
                return;
            }

            var activeTournament = Endless.TournamentManager.Instance.ActiveDailyTournament;
            if (activeTournament == null)
            {
                if (tournamentContainer != null)
                {
                    tournamentContainer.SetActive(false);
                }
                return;
            }

            // Show tournament info
            if (tournamentContainer != null)
            {
                tournamentContainer.SetActive(true);
            }

            // Get player's rank
            string playerId = SystemInfo.deviceUniqueIdentifier;
            int rank = Endless.TournamentManager.Instance.GetPlayerRank(activeTournament.id, playerId);

            if (tournamentRankText != null && rank > 0)
            {
                float percentile = Endless.TournamentManager.Instance.GetPlayerPercentile(activeTournament.id, playerId);
                tournamentRankText.text = $"Rank: #{rank} (Top {percentile:F0}%)";
            }
        }

        #endregion

        #region Rewards

        /// <summary>
        /// Shows rewards earned
        /// </summary>
        void ShowRewards()
        {
            int coinsEarned = 0;
            int bonusCoins = 0;

            if (Endless.EndlessScoreManager.Instance != null)
            {
                coinsEarned = Endless.EndlessScoreManager.Instance.CurrentCoins;
            }

            // Calculate bonus coins (achievements, etc.)
            bonusCoins = CalculateBonusCoins();

            if (totalCoinsEarnedText != null)
            {
                totalCoinsEarnedText.text = $"{coinsEarned:N0}";
            }

            if (bonusCoinsText != null && bonusCoins > 0)
            {
                bonusCoinsText.text = $"+{bonusCoins:N0} Bonus";
                bonusCoinsText.gameObject.SetActive(true);
            }
            else if (bonusCoinsText != null)
            {
                bonusCoinsText.gameObject.SetActive(false);
            }
        }

        /// <summary>
        /// Calculates bonus coins from achievements, etc.
        /// </summary>
        int CalculateBonusCoins()
        {
            int bonus = 0;

            // New record bonus
            if (Endless.EndlessScoreManager.Instance != null)
            {
                if (targetScore > Endless.EndlessScoreManager.Instance.HighScore)
                {
                    bonus += 100; // New record bonus
                }
            }

            // Distance milestones
            if (Endless.DistanceTracker.Instance != null)
            {
                int milestones = Mathf.FloorToInt(Endless.DistanceTracker.Instance.CurrentDistance / 100f);
                bonus += milestones * 10; // 10 coins per milestone
            }

            return bonus;
        }

        #endregion

        #region Button Handlers

        /// <summary>
        /// Retry button pressed
        /// </summary>
        void OnRetryPressed()
        {
            // Play click sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("ui_click");
            }

            // Restart level
            SceneManager.LoadScene(SceneManager.GetActiveScene().name);
        }

        /// <summary>
        /// Main menu button pressed
        /// </summary>
        void OnMainMenuPressed()
        {
            // Play click sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("ui_click");
            }

            // Load main menu
            SceneManager.LoadScene("MainMenu");
        }

        /// <summary>
        /// Watch ad button pressed
        /// </summary>
        void OnWatchAdPressed()
        {
            if (hasWatchedAd)
            {
                Debug.LogWarning("Already watched ad for this run!");
                return;
            }

            // Show rewarded ad
            var adsManager = FindObjectOfType<AdsManager>();
            if (adsManager != null)
            {
                adsManager.ShowRewardedAd(OnAdWatchComplete);
            }
            else
            {
                Debug.LogWarning("AdsManager not found!");
            }
        }

        /// <summary>
        /// Called when ad watch is complete
        /// </summary>
        void OnAdWatchComplete(bool success)
        {
            if (!success) return;

            hasWatchedAd = true;

            // Double coins
            if (Endless.EndlessScoreManager.Instance != null)
            {
                int coinsEarned = Endless.EndlessScoreManager.Instance.CurrentCoins;
                int bonusCoins = coinsEarned; // 2x = original + bonus

                var economyManager = FindObjectOfType<EconomyManager>();
                if (economyManager != null)
                {
                    economyManager.AddCoins(bonusCoins);
                }

                // Update display
                if (totalCoinsEarnedText != null)
                {
                    totalCoinsEarnedText.text = $"{coinsEarned * 2:N0}";
                }

                // Show feedback
                if (bonusCoinsText != null)
                {
                    bonusCoinsText.text = $"+{bonusCoins:N0} from Ad!";
                    bonusCoinsText.color = Color.yellow;
                    bonusCoinsText.gameObject.SetActive(true);
                }
            }

            // Disable button
            if (watchAdButton != null)
            {
                watchAdButton.interactable = false;
                var buttonText = watchAdButton.GetComponentInChildren<TextMeshProUGUI>();
                if (buttonText != null)
                {
                    buttonText.text = "Thanks!";
                }
            }

            Debug.Log("💰 Coins doubled from ad!");
        }

        /// <summary>
        /// Share button pressed
        /// </summary>
        void OnSharePressed()
        {
            string shareText = $"I just scored {targetScore:N0} points in Treasure Chase! Can you beat that?";
            string shareUrl = "https://play.google.com/store/apps/details?id=com.yourcompany.treasurechase";

            // Share via native plugin or social media
            Debug.Log($"Share: {shareText}");

            // TODO: Implement native sharing
            // NativeShare.Share(shareText, shareUrl);
        }

        #endregion
    }
}
