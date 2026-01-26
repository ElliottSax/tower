using UnityEngine;
using TMPro;

public class SimpleHUDController : MonoBehaviour
{
    [Header("HUD References")]
    public TextMeshProUGUI distanceText;
    public TextMeshProUGUI scoreText;
    public TextMeshProUGUI coinText;
    public TextMeshProUGUI multiplierText;

    [Header("Score Settings")]
    public float pointsPerMeter = 10f;
    public float pointsPerCoin = 50f;

    private float currentDistance = 0f;
    private int currentScore = 0;
    private int currentCoins = 0;
    private float currentMultiplier = 1f;

    void Update()
    {
        UpdateFromManagers();
        UpdateUI();
    }

    void UpdateFromManagers()
    {
        // Get distance from DistanceTracker
        if (DistanceTracker.Instance != null)
        {
            currentDistance = DistanceTracker.Instance.currentDistance;
        }

        // Get coins from EndlessScoreManager (if exists)
        if (EndlessScoreManager.Instance != null)
        {
            currentCoins = EndlessScoreManager.Instance.currentCoins;
            currentScore = EndlessScoreManager.Instance.currentScore;
            currentMultiplier = EndlessScoreManager.Instance.currentMultiplier;
        }
        else
        {
            // Simple score calculation if manager doesn't exist yet
            currentScore = Mathf.FloorToInt(currentDistance * pointsPerMeter);
        }
    }

    void UpdateUI()
    {
        // Update distance
        if (distanceText != null)
        {
            distanceText.text = Mathf.Floor(currentDistance) + " m";
        }

        // Update score
        if (scoreText != null)
        {
            scoreText.text = currentScore.ToString();
        }

        // Update coins
        if (coinText != null)
        {
            coinText.text = "💎 " + currentCoins.ToString();
        }

        // Update multiplier (only show if > 1.0)
        if (multiplierText != null)
        {
            if (currentMultiplier > 1f)
            {
                multiplierText.text = "x" + currentMultiplier.ToString("F1");
                // Fade in
                Color c = multiplierText.color;
                c.a = Mathf.Lerp(c.a, 1f, Time.deltaTime * 5f);
                multiplierText.color = c;
            }
            else
            {
                // Fade out
                Color c = multiplierText.color;
                c.a = Mathf.Lerp(c.a, 0f, Time.deltaTime * 5f);
                multiplierText.color = c;
            }
        }
    }

    // Public method to add coins
    public void AddCoins(int amount)
    {
        currentCoins += amount;
    }
}
