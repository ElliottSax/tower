using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

namespace TreasureChase.UI
{
    /// <summary>
    /// HUD for endless runner mode showing score, distance, multiplier, and coins.
    /// </summary>
    public class EndlessHUD : MonoBehaviour
    {
        public static EndlessHUD Instance { get; private set; }

        [Header("Score Display")]
        [Tooltip("Score text (e.g., 12,345)")]
        public TextMeshProUGUI scoreText;

        [Tooltip("High score text")]
        public TextMeshProUGUI highScoreText;

        [Header("Distance Display")]
        [Tooltip("Distance text (e.g., 1,234m)")]
        public TextMeshProUGUI distanceText;

        [Tooltip("Milestone indicator (every 100m)")]
        public GameObject milestoneEffect;

        [Header("Multiplier Display")]
        [Tooltip("Multiplier text (e.g., x10.5)")]
        public TextMeshProUGUI multiplierText;

        [Tooltip("Multiplier glow effect")]
        public Image multiplierGlow;

        [Header("Coins Display")]
        [Tooltip("Coins collected this run")]
        public TextMeshProUGUI coinsText;

        [Tooltip("Coin icon for flash effect")]
        public Image coinIcon;

        [Header("Power-Up Display")]
        [Tooltip("Power-up icon container")]
        public GameObject powerUpContainer;

        [Tooltip("Power-up icon image")]
        public Image powerUpIcon;

        [Tooltip("Power-up duration bar")]
        public Image powerUpDurationBar;

        [Tooltip("Power-up duration text")]
        public TextMeshProUGUI powerUpDurationText;

        [Header("Speed Display")]
        [Tooltip("Speed text (e.g., 45 km/h)")]
        public TextMeshProUGUI speedText;

        [Header("Combo Display")]
        [Tooltip("Combo counter (e.g., Combo x5!)")]
        public TextMeshProUGUI comboText;

        [Tooltip("Combo container (hidden when no combo)")]
        public GameObject comboContainer;

        [Header("Animation Settings")]
        [Tooltip("Score count-up speed")]
        public float scoreCountSpeed = 100f;

        [Tooltip("Flash duration for effects")]
        public float flashDuration = 0.3f;

        // Private fields
        private int displayedScore = 0;
        private int targetScore = 0;
        private Coroutine scoreCountCoroutine;

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
                Debug.LogWarning("Multiple EndlessHUD instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Subscribe to events
            SubscribeToEvents();

            // Initialize display
            InitializeDisplay();

            Debug.Log("EndlessHUD: Initialized");
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            UnsubscribeFromEvents();
        }

        void Update()
        {
            // Smooth score counting
            if (displayedScore < targetScore)
            {
                displayedScore = Mathf.Min(displayedScore + Mathf.CeilToInt(scoreCountSpeed * Time.deltaTime), targetScore);
                UpdateScoreDisplay();
            }
        }

        #endregion

        #region Initialization

        /// <summary>
        /// Subscribes to game events
        /// </summary>
        void SubscribeToEvents()
        {
            if (Endless.EndlessScoreManager.Instance != null)
            {
                Endless.EndlessScoreManager.Instance.OnScoreChanged.AddListener(UpdateScore);
                Endless.EndlessScoreManager.Instance.OnCoinsChanged.AddListener(UpdateCoins);
                Endless.EndlessScoreManager.Instance.OnMultiplierChanged.AddListener(UpdateMultiplier);
            }

            if (Endless.DistanceTracker.Instance != null)
            {
                Endless.DistanceTracker.Instance.OnDistanceChanged.AddListener(UpdateDistance);
                Endless.DistanceTracker.Instance.OnMilestoneReached.AddListener(ShowMilestone);
            }
        }

        /// <summary>
        /// Unsubscribes from game events
        /// </summary>
        void UnsubscribeFromEvents()
        {
            if (Endless.EndlessScoreManager.Instance != null)
            {
                Endless.EndlessScoreManager.Instance.OnScoreChanged.RemoveListener(UpdateScore);
                Endless.EndlessScoreManager.Instance.OnCoinsChanged.RemoveListener(UpdateCoins);
                Endless.EndlessScoreManager.Instance.OnMultiplierChanged.RemoveListener(UpdateMultiplier);
            }

            if (Endless.DistanceTracker.Instance != null)
            {
                Endless.DistanceTracker.Instance.OnDistanceChanged.RemoveListener(UpdateDistance);
                Endless.DistanceTracker.Instance.OnMilestoneReached.RemoveListener(ShowMilestone);
            }
        }

        /// <summary>
        /// Initializes HUD display
        /// </summary>
        void InitializeDisplay()
        {
            // Set initial values
            UpdateScore(0);
            UpdateCoins(0);
            UpdateDistance(0f);
            UpdateMultiplier(1f);

            // Hide power-up display
            if (powerUpContainer != null)
            {
                powerUpContainer.SetActive(false);
            }

            // Hide combo display
            if (comboContainer != null)
            {
                comboContainer.SetActive(false);
            }

            // Load high score
            if (Endless.EndlessScoreManager.Instance != null && highScoreText != null)
            {
                highScoreText.text = $"Best: {Endless.EndlessScoreManager.Instance.HighScore:N0}";
            }
        }

        #endregion

        #region Score Display

        /// <summary>
        /// Updates score display
        /// </summary>
        public void UpdateScore(int score)
        {
            targetScore = score;

            // Instant update for small changes, smooth for large
            if (Mathf.Abs(targetScore - displayedScore) < 100)
            {
                displayedScore = targetScore;
                UpdateScoreDisplay();
            }
        }

        /// <summary>
        /// Updates score text
        /// </summary>
        void UpdateScoreDisplay()
        {
            if (scoreText != null)
            {
                scoreText.text = displayedScore.ToString("N0");
            }
        }

        /// <summary>
        /// Flashes score text
        /// </summary>
        public void FlashScore()
        {
            StartCoroutine(FlashElement(scoreText));
        }

        #endregion

        #region Distance Display

        /// <summary>
        /// Updates distance display
        /// </summary>
        public void UpdateDistance(float distance)
        {
            if (distanceText != null)
            {
                distanceText.text = $"{distance:F0}m";
            }
        }

        /// <summary>
        /// Shows milestone reached effect
        /// </summary>
        public void ShowMilestone(int milestone)
        {
            if (milestoneEffect != null)
            {
                GameObject effect = Instantiate(milestoneEffect, transform);
                Destroy(effect, 2f);
            }

            // Flash distance text
            StartCoroutine(FlashElement(distanceText));

            Debug.Log($"🎯 Milestone {milestone}00m!");
        }

        #endregion

        #region Multiplier Display

        /// <summary>
        /// Updates multiplier display
        /// </summary>
        public void UpdateMultiplier(float multiplier)
        {
            if (multiplierText != null)
            {
                multiplierText.text = $"x{multiplier:F1}";

                // Color based on multiplier value
                if (multiplier >= 10f)
                {
                    multiplierText.color = Color.red;
                }
                else if (multiplier >= 5f)
                {
                    multiplierText.color = Color.yellow;
                }
                else
                {
                    multiplierText.color = Color.white;
                }
            }

            // Pulse multiplier display
            StartCoroutine(PulseMultiplier());
        }

        /// <summary>
        /// Shows multiplier bonus popup
        /// </summary>
        public void ShowMultiplierBonus(int multiplier)
        {
            // Create popup text
            if (multiplierText != null)
            {
                GameObject popup = new GameObject("MultiplierPopup");
                popup.transform.SetParent(transform);
                popup.transform.localScale = Vector3.one;

                var text = popup.AddComponent<TextMeshProUGUI>();
                text.text = $"+x{multiplier}!";
                text.fontSize = 72;
                text.alignment = TextAlignmentOptions.Center;
                text.color = Color.yellow;

                RectTransform rect = popup.GetComponent<RectTransform>();
                rect.anchoredPosition = Vector2.zero;

                // Animate and destroy
                StartCoroutine(AnimatePopup(popup));
            }
        }

        /// <summary>
        /// Pulses multiplier display
        /// </summary>
        IEnumerator PulseMultiplier()
        {
            if (multiplierText == null) yield break;

            Vector3 originalScale = multiplierText.transform.localScale;
            float elapsed = 0f;
            float duration = 0.3f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float scale = 1f + Mathf.Sin(elapsed / duration * Mathf.PI) * 0.3f;
                multiplierText.transform.localScale = originalScale * scale;
                yield return null;
            }

            multiplierText.transform.localScale = originalScale;
        }

        #endregion

        #region Coins Display

        /// <summary>
        /// Updates coins display
        /// </summary>
        public void UpdateCoins(int coins)
        {
            if (coinsText != null)
            {
                coinsText.text = coins.ToString("N0");
            }
        }

        /// <summary>
        /// Flashes coin counter
        /// </summary>
        public void FlashCoinCounter()
        {
            if (coinIcon != null)
            {
                StartCoroutine(FlashImage(coinIcon));
            }
            if (coinsText != null)
            {
                StartCoroutine(FlashElement(coinsText));
            }
        }

        #endregion

        #region Power-Up Display

        /// <summary>
        /// Shows power-up active indicator
        /// </summary>
        public void ShowPowerUp(Sprite icon, float duration)
        {
            if (powerUpContainer != null)
            {
                powerUpContainer.SetActive(true);
            }

            if (powerUpIcon != null && icon != null)
            {
                powerUpIcon.sprite = icon;
            }

            // Start duration countdown
            StartCoroutine(UpdatePowerUpDuration(duration));
        }

        /// <summary>
        /// Hides power-up indicator
        /// </summary>
        public void HidePowerUp()
        {
            if (powerUpContainer != null)
            {
                powerUpContainer.SetActive(false);
            }
        }

        /// <summary>
        /// Updates power-up duration bar
        /// </summary>
        IEnumerator UpdatePowerUpDuration(float duration)
        {
            float elapsed = 0f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float progress = 1f - (elapsed / duration);

                if (powerUpDurationBar != null)
                {
                    powerUpDurationBar.fillAmount = progress;
                }

                if (powerUpDurationText != null)
                {
                    powerUpDurationText.text = $"{Mathf.Ceil(duration - elapsed)}s";
                }

                yield return null;
            }

            HidePowerUp();
        }

        #endregion

        #region Speed Display

        /// <summary>
        /// Updates speed display
        /// </summary>
        public void UpdateSpeed(float speedMPS)
        {
            if (speedText != null)
            {
                // Convert m/s to km/h
                float speedKMH = speedMPS * 3.6f;
                speedText.text = $"{speedKMH:F0} km/h";
            }
        }

        #endregion

        #region Combo Display

        /// <summary>
        /// Shows combo counter
        /// </summary>
        public void ShowCombo(int combo)
        {
            if (comboContainer != null)
            {
                comboContainer.SetActive(true);
            }

            if (comboText != null)
            {
                comboText.text = $"Combo x{combo}!";

                // Scale based on combo
                float scale = 1f + Mathf.Min(combo * 0.1f, 1f);
                comboText.transform.localScale = Vector3.one * scale;
            }

            // Pulse effect
            StartCoroutine(PulseElement(comboText));
        }

        /// <summary>
        /// Hides combo counter
        /// </summary>
        public void HideCombo()
        {
            if (comboContainer != null)
            {
                comboContainer.SetActive(false);
            }
        }

        #endregion

        #region Animation Helpers

        /// <summary>
        /// Flashes a text element
        /// </summary>
        IEnumerator FlashElement(TextMeshProUGUI text)
        {
            if (text == null) yield break;

            Color originalColor = text.color;
            float elapsed = 0f;

            while (elapsed < flashDuration)
            {
                elapsed += Time.deltaTime;
                float alpha = 1f + Mathf.Sin(elapsed / flashDuration * Mathf.PI * 4f) * 0.5f;
                text.color = new Color(originalColor.r, originalColor.g, originalColor.b, alpha);
                yield return null;
            }

            text.color = originalColor;
        }

        /// <summary>
        /// Flashes an image element
        /// </summary>
        IEnumerator FlashImage(Image image)
        {
            if (image == null) yield break;

            Color originalColor = image.color;
            float elapsed = 0f;

            while (elapsed < flashDuration)
            {
                elapsed += Time.deltaTime;
                float brightness = 1f + Mathf.Sin(elapsed / flashDuration * Mathf.PI * 2f) * 0.5f;
                image.color = originalColor * brightness;
                yield return null;
            }

            image.color = originalColor;
        }

        /// <summary>
        /// Pulses an element
        /// </summary>
        IEnumerator PulseElement(TextMeshProUGUI text)
        {
            if (text == null) yield break;

            Vector3 originalScale = text.transform.localScale;
            float elapsed = 0f;
            float duration = 0.5f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float scale = 1f + Mathf.Sin(elapsed / duration * Mathf.PI) * 0.2f;
                text.transform.localScale = originalScale * scale;
                yield return null;
            }

            text.transform.localScale = originalScale;
        }

        /// <summary>
        /// Animates popup text
        /// </summary>
        IEnumerator AnimatePopup(GameObject popup)
        {
            RectTransform rect = popup.GetComponent<RectTransform>();
            TextMeshProUGUI text = popup.GetComponent<TextMeshProUGUI>();

            float elapsed = 0f;
            float duration = 1.5f;
            Vector2 startPos = Vector2.zero;
            Vector2 endPos = Vector2.up * 200f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;

                // Move up
                rect.anchoredPosition = Vector2.Lerp(startPos, endPos, t);

                // Scale
                float scale = 1f + Mathf.Sin(t * Mathf.PI) * 0.5f;
                rect.localScale = Vector3.one * scale;

                // Fade out
                Color color = text.color;
                color.a = 1f - t;
                text.color = color;

                yield return null;
            }

            Destroy(popup);
        }

        #endregion
    }
}
