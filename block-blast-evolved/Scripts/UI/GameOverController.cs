using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using TMPro;
using BlockBlastEvolved.Monetization;

namespace BlockBlastEvolved.UI
{
    /// <summary>
    /// Game Over UI Controller with monetization integration.
    /// Handles continue with ads, score display, and menu navigation.
    /// </summary>
    public class GameOverController : MonoBehaviour
    {
        [Header("UI Panels")]
        [Tooltip("Game over panel")]
        public GameObject gameOverPanel;

        [Header("Score Display")]
        [Tooltip("Final score text")]
        public TextMeshProUGUI finalScoreText;

        [Tooltip("High score text")]
        public TextMeshProUGUI highScoreText;

        [Tooltip("Lines cleared text")]
        public TextMeshProUGUI linesClearedText;

        [Header("Buttons")]
        [Tooltip("Continue button (watch ad)")]
        public Button continueButton;

        [Tooltip("Restart button")]
        public Button restartButton;

        [Tooltip("Main menu button")]
        public Button mainMenuButton;

        [Tooltip("Continue button text")]
        public TextMeshProUGUI continueButtonText;

        [Header("Settings")]
        [Tooltip("Allow continue once per game")]
        public bool allowContinue = true;

        [Tooltip("Continue cost (gems, if no ad available)")]
        public int continueCostGems = 50;

        // State
        private bool hasContinued = false;
        private int currentScore = 0;
        private int linesCleared = 0;

        #region Unity Lifecycle

        void Awake()
        {
            // Setup button listeners
            if (continueButton != null)
                continueButton.onClick.AddListener(OnContinueClicked);

            if (restartButton != null)
                restartButton.onClick.AddListener(OnRestartClicked);

            if (mainMenuButton != null)
                mainMenuButton.onClick.AddListener(OnMainMenuClicked);

            // Hide panel initially
            if (gameOverPanel != null)
                gameOverPanel.SetActive(false);
        }

        #endregion

        #region Game Over Flow

        /// <summary>
        /// Show game over screen
        /// </summary>
        public void ShowGameOver(int score, int lines)
        {
            currentScore = score;
            linesCleared = lines;

            // Show panel
            if (gameOverPanel != null)
                gameOverPanel.SetActive(true);

            // Update score display
            UpdateScoreDisplay();

            // Update continue button
            UpdateContinueButton();

            // Show interstitial ad (if conditions met)
            ShowInterstitialAd();

            // Notify ads manager
            if (UnityAdsManager.Instance != null)
            {
                UnityAdsManager.Instance.IncrementGameCounter();
            }

            // Play game over sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("game_over");
            }
        }

        /// <summary>
        /// Hide game over screen
        /// </summary>
        public void HideGameOver()
        {
            if (gameOverPanel != null)
                gameOverPanel.SetActive(false);

            // Reset continue state
            hasContinued = false;
        }

        #endregion

        #region Score Display

        /// <summary>
        /// Update score text display
        /// </summary>
        void UpdateScoreDisplay()
        {
            // Final score
            if (finalScoreText != null)
                finalScoreText.text = $"Score: {currentScore:N0}";

            // High score
            if (highScoreText != null)
            {
                var scoreManager = ScoreManager.Instance;
                if (scoreManager != null)
                {
                    int highScore = scoreManager.GetHighScore();
                    highScoreText.text = $"Best: {highScore:N0}";

                    // Highlight if new high score
                    if (currentScore > highScore)
                    {
                        highScoreText.color = Color.yellow;
                        highScoreText.text = $"NEW BEST: {currentScore:N0}";
                    }
                }
            }

            // Lines cleared
            if (linesClearedText != null)
                linesClearedText.text = $"Lines: {linesCleared}";
        }

        #endregion

        #region Continue Functionality

        /// <summary>
        /// Update continue button state
        /// </summary>
        void UpdateContinueButton()
        {
            if (continueButton == null) return;

            // Check if continue is allowed
            bool canContinue = allowContinue && !hasContinued;

            continueButton.gameObject.SetActive(canContinue);

            if (canContinue)
            {
                // Check if rewarded ad is available
                bool adAvailable = UnityAdsManager.Instance != null &&
                                  UnityAdsManager.Instance.IsRewardedAdReady();

                if (continueButtonText != null)
                {
                    if (adAvailable)
                    {
                        continueButtonText.text = "Continue (Watch Ad)";
                    }
                    else
                    {
                        continueButtonText.text = $"Continue ({continueCostGems} Gems)";
                    }
                }
            }
        }

        /// <summary>
        /// Handle continue button click
        /// </summary>
        void OnContinueClicked()
        {
            if (hasContinued)
            {
                Debug.LogWarning("Already continued this game!");
                return;
            }

            // Try rewarded ad first
            if (UnityAdsManager.Instance != null && UnityAdsManager.Instance.IsRewardedAdReady())
            {
                UnityAdsManager.Instance.ShowRewardedAd(OnContinueAdComplete);
            }
            else
            {
                // Fallback: Continue with gems
                ContinueWithGems();
            }
        }

        /// <summary>
        /// Continue ad callback
        /// </summary>
        void OnContinueAdComplete(bool success)
        {
            if (success)
            {
                // Grant continue
                ContinueGame();
            }
            else
            {
                Debug.Log("User did not complete ad");
            }
        }

        /// <summary>
        /// Continue with gem payment
        /// </summary>
        void ContinueWithGems()
        {
            var economyManager = EconomyManager.Instance;
            if (economyManager == null) return;

            // Check gem balance
            if (economyManager.GetGems() < continueCostGems)
            {
                Debug.LogWarning($"Not enough gems! Need {continueCostGems}");
                ShowNotEnoughGemsPopup();
                return;
            }

            // Spend gems
            if (economyManager.SpendGems(continueCostGems))
            {
                ContinueGame();
            }
        }

        /// <summary>
        /// Continue game (remove some blocks, continue playing)
        /// </summary>
        void ContinueGame()
        {
            hasContinued = true;

            // Clear some blocks to give player a chance
            ClearSomeBlocks();

            // Hide game over screen
            HideGameOver();

            // Resume game
            Time.timeScale = 1f;

            // Play continue effect
            if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("continue", Vector3.zero);
            }

            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("continue");
            }

            Debug.Log("Game continued!");
        }

        /// <summary>
        /// Clear some blocks to help player continue
        /// </summary>
        void ClearSomeBlocks()
        {
            if (GridSystem.Instance == null) return;

            // Clear 20-30% of filled cells randomly
            int totalCells = GridSystem.Instance.GridWidth * GridSystem.Instance.GridHeight;
            int cellsToClear = Random.Range(totalCells / 5, totalCells / 3);

            for (int i = 0; i < cellsToClear; i++)
            {
                int x = Random.Range(0, GridSystem.Instance.GridWidth);
                int y = Random.Range(0, GridSystem.Instance.GridHeight);

                var cell = GridSystem.Instance.GetCell(x, y);
                if (cell != null && !cell.isEmpty)
                {
                    cell.isEmpty = true;
                    cell.blockType = BlockType.None;
                    // Visual update would go here
                }
            }
        }

        #endregion

        #region Navigation

        /// <summary>
        /// Restart game
        /// </summary>
        void OnRestartClicked()
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(SceneManager.GetActiveScene().name);

            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("button_click");
            }
        }

        /// <summary>
        /// Return to main menu
        /// </summary>
        void OnMainMenuClicked()
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene("MainMenu"); // Adjust scene name as needed

            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("button_click");
            }
        }

        #endregion

        #region Interstitial Ads

        /// <summary>
        /// Show interstitial ad on game over (respects frequency)
        /// </summary>
        void ShowInterstitialAd()
        {
            if (UnityAdsManager.Instance != null)
            {
                UnityAdsManager.Instance.ShowInterstitialAd();
            }
        }

        #endregion

        #region UI Feedback

        /// <summary>
        /// Show not enough gems popup
        /// </summary>
        void ShowNotEnoughGemsPopup()
        {
            Debug.Log("[NOT ENOUGH GEMS] Shop would open here");
            // TODO: Open shop UI to purchase gems
        }

        #endregion
    }

    /// <summary>
    /// Stub BlockType enum (if not defined elsewhere)
    /// </summary>
    public enum BlockType
    {
        None,
        Standard,
        Special
    }
}
