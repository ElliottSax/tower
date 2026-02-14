using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Manages player score, combos, and multipliers.
    /// Stub implementation - extend with full scoring system as needed.
    /// </summary>
    public class ScoreManager : MonoBehaviour
    {
        public static ScoreManager Instance { get; private set; }

        private int currentScore = 0;
        private float scoreMultiplier = 1f;

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Gets current score.
        /// </summary>
        public int GetScore()
        {
            return currentScore;
        }

        /// <summary>
        /// Adds points to current score.
        /// </summary>
        public void AddScore(int points)
        {
            currentScore += Mathf.RoundToInt(points * scoreMultiplier);
            Debug.Log($"ScoreManager: Score is now {currentScore}");
        }

        /// <summary>
        /// Awards bonus points for clearing lines.
        /// </summary>
        public void AddLineBonus(int linesCleared)
        {
            // Bonus scales with number of lines cleared simultaneously
            int bonus = linesCleared * linesCleared * 100;
            AddScore(bonus);
            Debug.Log($"ScoreManager: Line bonus +{bonus} for {linesCleared} lines");
        }

        /// <summary>
        /// Activates a score multiplier for a duration.
        /// </summary>
        public void ActivateMultiplier(float multiplier, float duration)
        {
            scoreMultiplier = multiplier;
            Debug.Log($"ScoreManager: Multiplier x{multiplier} for {duration}s - not yet implemented");
        }

        /// <summary>
        /// Resets score to zero.
        /// </summary>
        public void ResetScore()
        {
            currentScore = 0;
            scoreMultiplier = 1f;
        }
    }
}
