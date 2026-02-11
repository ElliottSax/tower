using UnityEngine;
using TMPro;
using UnityEngine.UI;
using TreasureChase.Endless;
using TreasureChase.Monetization;

public class GameOverController : MonoBehaviour
{
    [Header("Game Over Panel")]
    public GameObject gameOverPanel;

    [Header("Stats Display")]
    public TextMeshProUGUI finalScoreText;
    public TextMeshProUGUI finalDistanceText;
    public TextMeshProUGUI finalCoinsText;
    public TextMeshProUGUI bestScoreText;

    [Header("Buttons")]
    public Button restartButton;
    public Button continueButton; // Watch ad to continue
    public Button doubleCoinsButton; // Watch ad to 2x coins

    [Header("Monetization")]
    [Tooltip("Show interstitial ad every N game overs")]
    public int interstitialFrequency = 3;

    private int finalScore = 0;
    private float finalDistance = 0f;
    private int finalCoins = 0;
    private int gameOverCount = 0;

    void Start()
    {
        // Hide panel at start
        if (gameOverPanel != null)
            gameOverPanel.SetActive(false);

        // Hook up buttons
        if (restartButton != null)
            restartButton.onClick.AddListener(OnRestartClicked);

        if (continueButton != null)
            continueButton.onClick.AddListener(OnContinueClicked);

        if (doubleCoinsButton != null)
            doubleCoinsButton.onClick.AddListener(OnDoubleCoinsClicked);

        // Subscribe to game over event
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnGameOver.AddListener(ShowGameOver);
        }

        // Load game over count
        gameOverCount = PlayerPrefs.GetInt("GameOverCount", 0);
    }

    void ShowGameOver()
    {
        // Gather final stats
        GatherStats();

        // Save best score
        CheckAndSaveBestScore();

        // Call EndlessScoreManager run end
        if (EndlessScoreManager.Instance != null)
        {
            EndlessScoreManager.Instance.OnRunEnd();
        }

        // Update UI
        UpdateGameOverUI();

        // Show monetization buttons
        UpdateMonetizationButtons();

        // Show panel
        if (gameOverPanel != null)
            gameOverPanel.SetActive(true);

        // Increment game over count
        gameOverCount++;
        PlayerPrefs.SetInt("GameOverCount", gameOverCount);
        PlayerPrefs.Save();

        // Show interstitial ad (if enough game overs and not removed via IAP)
        ShowInterstitialIfNeeded();
    }

    void GatherStats()
    {
        // Get distance
        if (DistanceTracker.Instance != null)
        {
            finalDistance = DistanceTracker.Instance.CurrentDistance;
        }

        // Get score and coins
        if (EndlessScoreManager.Instance != null)
        {
            finalScore = EndlessScoreManager.Instance.CurrentScore;
            finalCoins = EndlessScoreManager.Instance.CurrentCoins;
        }
        else if (FindObjectOfType<SimpleHUDController>() != null)
        {
            // Fallback to simple calculation
            finalScore = Mathf.FloorToInt(finalDistance * 10f);
        }
    }

    void CheckAndSaveBestScore()
    {
        int previousBest = PlayerPrefs.GetInt("BestScore", 0);

        if (finalScore > previousBest)
        {
            PlayerPrefs.SetInt("BestScore", finalScore);
            PlayerPrefs.Save();
            Debug.Log("New Best Score: " + finalScore);
        }
    }

    void UpdateGameOverUI()
    {
        // Update score
        if (finalScoreText != null)
            finalScoreText.text = "Score: " + finalScore.ToString();

        // Update distance
        if (finalDistanceText != null)
            finalDistanceText.text = "Distance: " + Mathf.Floor(finalDistance) + " m";

        // Update coins
        if (finalCoinsText != null)
            finalCoinsText.text = "Coins: " + finalCoins.ToString();

        // Update best score
        if (bestScoreText != null)
        {
            int bestScore = PlayerPrefs.GetInt("BestScore", 0);
            bestScoreText.text = "Best: " + bestScore.ToString();
        }
    }

    void OnRestartClicked()
    {
        Debug.Log("Restart clicked!");

        // Hide game over panel
        if (gameOverPanel != null)
            gameOverPanel.SetActive(false);

        // Restart game
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.RestartGame();
        }
        else
        {
            // Fallback restart
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex
            );
        }
    }

    void OnContinueClicked()
    {
        // Show rewarded ad to continue run
        if (UnityAdsManager.Instance != null && UnityAdsManager.Instance.IsRewardedAdReady())
        {
            UnityAdsManager.Instance.ShowRewardedAd((rewarded) =>
            {
                if (rewarded)
                {
                    ContinueRun();
                }
                else
                {
                    Debug.Log("User did not complete ad - cannot continue");
                }
            });
        }
        else
        {
            Debug.Log("Rewarded ad not available");
        }
    }

    void OnDoubleCoinsClicked()
    {
        // Show rewarded ad to double coins
        if (UnityAdsManager.Instance != null && UnityAdsManager.Instance.IsRewardedAdReady())
        {
            UnityAdsManager.Instance.ShowRewardedAd((rewarded) =>
            {
                if (rewarded)
                {
                    DoubleCoinsReward();
                }
                else
                {
                    Debug.Log("User did not complete ad - no bonus coins");
                }
            });
        }
        else
        {
            Debug.Log("Rewarded ad not available");
        }
    }

    void ContinueRun()
    {
        Debug.Log("Continue run - restoring player");

        // Hide game over panel
        if (gameOverPanel != null)
            gameOverPanel.SetActive(false);

        // Restore player (resurrect at last checkpoint)
        var playerController = FindObjectOfType<PlayerController>();
        if (playerController != null)
        {
            // Move player back slightly
            playerController.transform.position -= playerController.transform.forward * 5f;

            // Grant temporary shield
            var shieldPowerUp = playerController.GetComponent<ShieldPowerUp>();
            if (shieldPowerUp != null)
            {
                shieldPowerUp.ActivatePowerUp(5f); // 5 seconds of invincibility
            }
        }

        // Resume game
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.ResumeGame();
        }

        Debug.Log("Run continued - player restored with shield!");
    }

    void DoubleCoinsReward()
    {
        // Double the coins earned this run
        int bonusCoins = finalCoins;

        var economyManager = FindObjectOfType<EconomyManager>();
        if (economyManager != null)
        {
            economyManager.AddCoins(bonusCoins);
        }

        // Update UI
        if (finalCoinsText != null)
        {
            finalCoinsText.text = "Coins: " + (finalCoins * 2).ToString() + " (2x Bonus!)";
        }

        // Hide double coins button (can only use once per run)
        if (doubleCoinsButton != null)
        {
            doubleCoinsButton.gameObject.SetActive(false);
        }

        Debug.Log($"Coins doubled! Bonus: +{bonusCoins}");
    }

    void ShowInterstitialIfNeeded()
    {
        // Show interstitial every N game overs
        if (gameOverCount % interstitialFrequency == 0)
        {
            if (UnityAdsManager.Instance != null && UnityAdsManager.Instance.IsInterstitialAdReady())
            {
                // Delay interstitial by 1 second (let user see game over screen first)
                Invoke(nameof(ShowInterstitial), 1f);
            }
        }
    }

    void ShowInterstitial()
    {
        if (UnityAdsManager.Instance != null)
        {
            UnityAdsManager.Instance.ShowInterstitialAd(() =>
            {
                Debug.Log("Interstitial ad complete");
            });
        }
    }

    void UpdateMonetizationButtons()
    {
        // Show/hide continue button based on ad availability
        if (continueButton != null)
        {
            bool canContinue = UnityAdsManager.Instance != null &&
                               UnityAdsManager.Instance.IsRewardedAdReady();
            continueButton.gameObject.SetActive(canContinue);
        }

        // Show/hide double coins button based on ad availability
        if (doubleCoinsButton != null)
        {
            bool canDouble = UnityAdsManager.Instance != null &&
                             UnityAdsManager.Instance.IsRewardedAdReady() &&
                             finalCoins > 0;
            doubleCoinsButton.gameObject.SetActive(canDouble);
        }
    }

    void OnDestroy()
    {
        // Unsubscribe from events
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnGameOver.RemoveListener(ShowGameOver);
        }

        // Unsubscribe from buttons
        if (restartButton != null)
            restartButton.onClick.RemoveListener(OnRestartClicked);

        if (continueButton != null)
            continueButton.onClick.RemoveListener(OnContinueClicked);

        if (doubleCoinsButton != null)
            doubleCoinsButton.onClick.RemoveListener(OnDoubleCoinsClicked);
    }
}
