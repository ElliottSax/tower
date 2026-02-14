using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

namespace BlockBlastEvolved.UI
{
    /// <summary>
    /// HUD for Block Blast Evolved showing score, moves, level, and hero info.
    /// </summary>
    public class BlockBlastHUD : MonoBehaviour
    {
        public static BlockBlastHUD Instance { get; private set; }

        [Header("Score Display")]
        [Tooltip("Current score text")]
        public TextMeshProUGUI scoreText;

        [Tooltip("Target score for level")]
        public TextMeshProUGUI targetScoreText;

        [Tooltip("Score progress bar")]
        public Image scoreProgressBar;

        [Header("Level Display")]
        [Tooltip("Current level text")]
        public TextMeshProUGUI levelText;

        [Tooltip("Level name text (e.g., 'Desert Valley')")]
        public TextMeshProUGUI levelNameText;

        [Header("Moves Display")]
        [Tooltip("Remaining moves text")]
        public TextMeshProUGUI movesText;

        [Tooltip("Moves counter background (changes color when low)")]
        public Image movesBackground;

        [Tooltip("Low moves threshold (color change trigger)")]
        public int lowMovesThreshold = 3;

        [Header("Hero Display")]
        [Tooltip("Hero portrait image")]
        public Image heroPortrait;

        [Tooltip("Hero name text")]
        public TextMeshProUGUI heroNameText;

        [Tooltip("Hero level text")]
        public TextMeshProUGUI heroLevelText;

        [Tooltip("Ability button")]
        public Button abilityButton;

        [Tooltip("Ability icon")]
        public Image abilityIcon;

        [Tooltip("Ability cooldown overlay")]
        public Image abilityCooldownOverlay;

        [Tooltip("Ability cooldown text")]
        public TextMeshProUGUI abilityCooldownText;

        [Header("Combo Display")]
        [Tooltip("Combo counter text")]
        public TextMeshProUGUI comboText;

        [Tooltip("Combo container (hidden when no combo)")]
        public GameObject comboContainer;

        [Header("Block Queue Display")]
        [Tooltip("Block queue container")]
        public GameObject blockQueueContainer;

        [Tooltip("Block preview slots (should have 3)")]
        public BlockPreviewSlot[] blockPreviewSlots;

        [Header("Colors")]
        [Tooltip("Normal moves color")]
        public Color normalMovesColor = Color.white;

        [Tooltip("Low moves color")]
        public Color lowMovesColor = Color.red;

        // Private fields
        private int currentScore = 0;
        private int targetScore = 0;
        private int currentMoves = 0;
        private int currentCombo = 0;

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
                Debug.LogWarning("Multiple BlockBlastHUD instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Initialize display
            InitializeDisplay();

            // Setup ability button
            if (abilityButton != null)
            {
                abilityButton.onClick.AddListener(OnAbilityButtonPressed);
            }

            Debug.Log("BlockBlastHUD: Initialized");
        }

        void Update()
        {
            // Update ability cooldown
            UpdateAbilityCooldown();
        }

        #endregion

        #region Initialization

        /// <summary>
        /// Initializes HUD display
        /// </summary>
        void InitializeDisplay()
        {
            UpdateScore(0);
            UpdateMoves(30); // Default moves
            UpdateLevel(1, "Tutorial");
            UpdateTargetScore(1000);
            HideCombo();

            // Load active hero
            if (HeroSystem.Instance != null && HeroSystem.Instance.activeHero != null)
            {
                UpdateHeroDisplay(HeroSystem.Instance.activeHero);
            }
        }

        #endregion

        #region Score Display

        /// <summary>
        /// Updates score display
        /// </summary>
        public void UpdateScore(int score)
        {
            currentScore = score;

            if (scoreText != null)
            {
                scoreText.text = score.ToString("N0");
            }

            UpdateScoreProgress();
        }

        /// <summary>
        /// Sets target score for level
        /// </summary>
        public void UpdateTargetScore(int target)
        {
            targetScore = target;

            if (targetScoreText != null)
            {
                targetScoreText.text = $"Goal: {target:N0}";
            }

            UpdateScoreProgress();
        }

        /// <summary>
        /// Updates score progress bar
        /// </summary>
        void UpdateScoreProgress()
        {
            if (scoreProgressBar != null && targetScore > 0)
            {
                float progress = (float)currentScore / targetScore;
                scoreProgressBar.fillAmount = Mathf.Clamp01(progress);

                // Color based on progress
                if (progress >= 1f)
                {
                    scoreProgressBar.color = Color.green;
                }
                else if (progress >= 0.7f)
                {
                    scoreProgressBar.color = Color.yellow;
                }
                else
                {
                    scoreProgressBar.color = Color.white;
                }
            }
        }

        /// <summary>
        /// Adds score with animation
        /// </summary>
        public void AddScore(int points, Vector3 worldPosition)
        {
            UpdateScore(currentScore + points);

            // Show floating text
            ShowFloatingScore(points, worldPosition);

            // Pulse score text
            StartCoroutine(PulseText(scoreText));
        }

        /// <summary>
        /// Shows floating score text at position
        /// </summary>
        void ShowFloatingScore(int points, Vector3 worldPosition)
        {
            // Create floating text
            GameObject floatingText = new GameObject("FloatingScore");
            floatingText.transform.SetParent(transform);

            var text = floatingText.AddComponent<TextMeshProUGUI>();
            text.text = $"+{points}";
            text.fontSize = 48;
            text.color = Color.yellow;
            text.alignment = TextAlignmentOptions.Center;

            RectTransform rect = floatingText.GetComponent<RectTransform>();
            rect.position = worldPosition;

            // Animate
            StartCoroutine(AnimateFloatingText(floatingText, rect));
        }

        /// <summary>
        /// Animates floating score text
        /// </summary>
        IEnumerator AnimateFloatingText(GameObject textObj, RectTransform rect)
        {
            TextMeshProUGUI text = textObj.GetComponent<TextMeshProUGUI>();
            Vector3 startPos = rect.position;
            Vector3 endPos = startPos + Vector3.up * 100f;

            float elapsed = 0f;
            float duration = 1f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;

                rect.position = Vector3.Lerp(startPos, endPos, t);
                Color color = text.color;
                color.a = 1f - t;
                text.color = color;

                yield return null;
            }

            Destroy(textObj);
        }

        #endregion

        #region Level Display

        /// <summary>
        /// Updates level display
        /// </summary>
        public void UpdateLevel(int level, string levelName)
        {
            if (levelText != null)
            {
                levelText.text = $"Level {level}";
            }

            if (levelNameText != null)
            {
                levelNameText.text = levelName;
            }
        }

        #endregion

        #region Moves Display

        /// <summary>
        /// Updates moves display
        /// </summary>
        public void UpdateMoves(int moves)
        {
            currentMoves = moves;

            if (movesText != null)
            {
                movesText.text = moves.ToString();

                // Change color if low
                if (moves <= lowMovesThreshold)
                {
                    movesText.color = lowMovesColor;

                    if (movesBackground != null)
                    {
                        movesBackground.color = lowMovesColor;
                    }

                    // Pulse warning
                    StartCoroutine(PulseText(movesText));
                }
                else
                {
                    movesText.color = normalMovesColor;

                    if (movesBackground != null)
                    {
                        movesBackground.color = normalMovesColor;
                    }
                }
            }
        }

        /// <summary>
        /// Decrements moves by 1
        /// </summary>
        public void UseMove()
        {
            UpdateMoves(currentMoves - 1);
        }

        #endregion

        #region Hero Display

        /// <summary>
        /// Updates hero display
        /// </summary>
        public void UpdateHeroDisplay(Hero hero)
        {
            if (hero == null) return;

            if (heroPortrait != null && hero.heroIcon != null)
            {
                heroPortrait.sprite = hero.heroIcon;
            }

            if (heroNameText != null)
            {
                heroNameText.text = hero.heroName;
            }

            if (heroLevelText != null)
            {
                int level = HeroSystem.Instance.GetHeroLevel(hero.heroId);
                heroLevelText.text = $"Lv.{level}";
            }

            if (abilityIcon != null && hero.heroIcon != null)
            {
                abilityIcon.sprite = hero.heroIcon; // Or separate ability icon
            }
        }

        #endregion

        #region Ability Display

        /// <summary>
        /// Updates ability cooldown display
        /// </summary>
        void UpdateAbilityCooldown()
        {
            if (HeroSystem.Instance == null || HeroSystem.Instance.activeHero == null)
                return;

            string abilityId = HeroSystem.Instance.activeHero.abilityId;
            bool onCooldown = HeroSystem.Instance.IsAbilityOnCooldown(abilityId);

            if (abilityButton != null)
            {
                abilityButton.interactable = !onCooldown;
            }

            if (onCooldown)
            {
                float cooldown = HeroSystem.Instance.GetAbilityCooldown(abilityId);

                if (abilityCooldownOverlay != null)
                {
                    abilityCooldownOverlay.gameObject.SetActive(true);
                    float maxCooldown = HeroSystem.Instance.activeHero.abilityCooldown;
                    abilityCooldownOverlay.fillAmount = cooldown / maxCooldown;
                }

                if (abilityCooldownText != null)
                {
                    abilityCooldownText.text = $"{Mathf.Ceil(cooldown)}s";
                    abilityCooldownText.gameObject.SetActive(true);
                }
            }
            else
            {
                if (abilityCooldownOverlay != null)
                {
                    abilityCooldownOverlay.gameObject.SetActive(false);
                }

                if (abilityCooldownText != null)
                {
                    abilityCooldownText.gameObject.SetActive(false);
                }
            }
        }

        /// <summary>
        /// Ability button pressed
        /// </summary>
        void OnAbilityButtonPressed()
        {
            if (HeroSystem.Instance != null)
            {
                bool success = HeroSystem.Instance.UseAbility();

                if (success)
                {
                    // Show ability effect
                    ShowAbilityEffect();
                }
            }
        }

        /// <summary>
        /// Shows ability activation effect
        /// </summary>
        void ShowAbilityEffect()
        {
            // Pulse ability button
            if (abilityButton != null)
            {
                StartCoroutine(PulseElement(abilityButton.transform, 1.3f));
            }

            // Flash screen
            if (CameraController.Instance != null)
            {
                CameraController.Instance.FlashColor(Color.yellow, 0.3f);
            }
        }

        #endregion

        #region Combo Display

        /// <summary>
        /// Updates combo display
        /// </summary>
        public void UpdateCombo(int combo)
        {
            currentCombo = combo;

            if (combo > 1)
            {
                ShowCombo(combo);
            }
            else
            {
                HideCombo();
            }
        }

        /// <summary>
        /// Shows combo counter
        /// </summary>
        void ShowCombo(int combo)
        {
            if (comboContainer != null)
            {
                comboContainer.SetActive(true);
            }

            if (comboText != null)
            {
                comboText.text = $"Combo x{combo}!";

                // Scale based on combo
                float scale = 1f + Mathf.Min(combo * 0.05f, 0.5f);
                comboText.transform.localScale = Vector3.one * scale;
            }

            // Pulse effect
            StartCoroutine(PulseText(comboText));
        }

        /// <summary>
        /// Hides combo counter
        /// </summary>
        void HideCombo()
        {
            if (comboContainer != null)
            {
                comboContainer.SetActive(false);
            }
        }

        #endregion

        #region Block Queue Display

        /// <summary>
        /// Updates block queue display
        /// </summary>
        public void UpdateBlockQueue(BlockShape[] blocks)
        {
            if (blockPreviewSlots == null || blocks == null) return;

            for (int i = 0; i < blockPreviewSlots.Length && i < blocks.Length; i++)
            {
                if (blockPreviewSlots[i] != null)
                {
                    blockPreviewSlots[i].SetBlock(blocks[i]);
                }
            }
        }

        /// <summary>
        /// Removes block from queue display
        /// </summary>
        public void RemoveBlockFromQueue(int index)
        {
            if (blockPreviewSlots != null && index < blockPreviewSlots.Length)
            {
                if (blockPreviewSlots[index] != null)
                {
                    blockPreviewSlots[index].Clear();
                }
            }
        }

        #endregion

        #region Animation Helpers

        /// <summary>
        /// Pulses text element
        /// </summary>
        IEnumerator PulseText(TextMeshProUGUI text)
        {
            if (text == null) yield break;

            Vector3 originalScale = text.transform.localScale;
            float elapsed = 0f;
            float duration = 0.3f;

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
        /// Pulses transform element
        /// </summary>
        IEnumerator PulseElement(Transform element, float maxScale)
        {
            if (element == null) yield break;

            Vector3 originalScale = element.localScale;
            float elapsed = 0f;
            float duration = 0.4f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float scale = 1f + Mathf.Sin(elapsed / duration * Mathf.PI) * (maxScale - 1f);
                element.localScale = originalScale * scale;
                yield return null;
            }

            element.localScale = originalScale;
        }

        #endregion
    }

    /// <summary>
    /// Block preview slot in queue
    /// </summary>
    [System.Serializable]
    public class BlockPreviewSlot
    {
        public GameObject container;
        public Image[] cellImages; // Visual representation of block shape

        public void SetBlock(BlockShape block)
        {
            if (container != null)
            {
                container.SetActive(true);
            }

            // Update visual representation
            // TODO: Create block shape visual from block.occupiedCells
        }

        public void Clear()
        {
            if (container != null)
            {
                container.SetActive(false);
            }
        }
    }
}
