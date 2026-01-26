using UnityEngine;
using TMPro;
using UnityEngine.UI;

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

    private int finalScore = 0;
    private float finalDistance = 0f;
    private int finalCoins = 0;

    void Start()
    {
        // Hide panel at start
        if (gameOverPanel != null)
            gameOverPanel.SetActive(false);

        // Hook up restart button
        if (restartButton != null)
        {
            restartButton.onClick.AddListener(OnRestartClicked);
        }

        // Subscribe to game over event
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnGameOver.AddListener(ShowGameOver);
        }
    }

    void ShowGameOver()
    {
        // Gather final stats
        GatherStats();

        // Save best score
        CheckAndSaveBestScore();

        // Update UI
        UpdateGameOverUI();

        // Show panel
        if (gameOverPanel != null)
            gameOverPanel.SetActive(true);
    }

    void GatherStats()
    {
        // Get distance
        if (DistanceTracker.Instance != null)
        {
            finalDistance = DistanceTracker.Instance.currentDistance;
        }

        // Get score and coins
        if (EndlessScoreManager.Instance != null)
        {
            finalScore = EndlessScoreManager.Instance.currentScore;
            finalCoins = EndlessScoreManager.Instance.currentCoins;
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

    void OnDestroy()
    {
        // Unsubscribe from events
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnGameOver.RemoveListener(ShowGameOver);
        }

        if (restartButton != null)
        {
            restartButton.onClick.RemoveListener(OnRestartClicked);
        }
    }
}
