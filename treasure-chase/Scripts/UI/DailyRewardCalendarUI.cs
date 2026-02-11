using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;
using System.Collections.Generic;
using TreasureChase.Progression;

namespace TreasureChase.UI
{
    /// <summary>
    /// Daily Reward Calendar UI for Treasure Chase.
    /// Visual 7-day calendar with claim flow and streak recovery.
    ///
    /// Completes progression loop UI for app store launch.
    /// </summary>
    public class DailyRewardCalendarUI : MonoBehaviour
    {
        [Header("Calendar Panel")]
        [Tooltip("Main calendar panel")]
        public GameObject calendarPanel;

        [Header("Calendar Day Cards")]
        [Tooltip("7 day card UI elements (Day 1-7)")]
        public List<DailyRewardDayCard> dayCards = new List<DailyRewardDayCard>();

        [Header("Header")]
        [Tooltip("Streak counter text")]
        public TextMeshProUGUI streakText;

        [Tooltip("Fire emoji for streak")]
        public GameObject streakFireIcon;

        [Header("Claim Section")]
        [Tooltip("Claim reward button")]
        public Button claimButton;

        [Tooltip("Claim button text")]
        public TextMeshProUGUI claimButtonText;

        [Tooltip("Next reward timer text")]
        public TextMeshProUGUI nextRewardTimerText;

        [Tooltip("Come back message")]
        public TextMeshProUGUI comeBackMessageText;

        [Header("Reward Animation")]
        [Tooltip("Reward icon for animation")]
        public GameObject rewardIconPrefab;

        [Tooltip("Target for coin animation (HUD coin counter)")]
        public Transform coinAnimationTarget;

        [Tooltip("Confetti particle system (Day 7)")]
        public ParticleSystem confettiParticles;

        [Header("Streak Recovery Popup")]
        [Tooltip("Streak broken popup panel")]
        public GameObject streakRecoveryPopup;

        [Tooltip("Streak lost text")]
        public TextMeshProUGUI streakLostText;

        [Tooltip("Watch ad button")]
        public Button watchAdButton;

        [Tooltip("Skip button")]
        public Button skipRecoveryButton;

        [Header("Audio")]
        [Tooltip("Claim reward sound")]
        public AudioClip claimRewardSound;

        [Tooltip("Day 7 fanfare sound")]
        public AudioClip day7FanfareSound;

        // State
        private DailyRewardSystem rewardSystem;
        private bool isAnimating = false;

        #region Unity Lifecycle

        void Start()
        {
            // Get reward system
            rewardSystem = DailyRewardSystem.Instance;

            if (rewardSystem == null)
            {
                Debug.LogError("DailyRewardSystem not found!");
                return;
            }

            // Hook up buttons
            if (claimButton != null)
                claimButton.onClick.AddListener(OnClaimButtonClicked);

            if (watchAdButton != null)
                watchAdButton.onClick.AddListener(OnWatchAdClicked);

            if (skipRecoveryButton != null)
                skipRecoveryButton.onClick.AddListener(OnSkipRecoveryClicked);

            // Subscribe to events
            rewardSystem.OnRewardClaimed += OnRewardClaimed;
            rewardSystem.OnStreakUpdated += OnStreakUpdated;
            rewardSystem.OnStreakLost += OnStreakLost;
            rewardSystem.OnStreakRecovered += OnStreakRecovered;

            // Initialize UI
            RefreshCalendarUI();

            // Hide panel initially
            if (calendarPanel != null)
                calendarPanel.SetActive(false);

            // Check if should show on launch
            if (!rewardSystem.HasClaimedToday())
            {
                ShowCalendar();
            }

            // Check if streak broken
            if (rewardSystem.IsStreakBroken())
            {
                ShowStreakRecoveryPopup();
            }
        }

        void Update()
        {
            // Update timer every frame
            if (calendarPanel != null && calendarPanel.activeSelf)
            {
                UpdateNextRewardTimer();
            }
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (rewardSystem != null)
            {
                rewardSystem.OnRewardClaimed -= OnRewardClaimed;
                rewardSystem.OnStreakUpdated -= OnStreakUpdated;
                rewardSystem.OnStreakLost -= OnStreakLost;
                rewardSystem.OnStreakRecovered -= OnStreakRecovered;
            }

            // Unsubscribe from buttons
            if (claimButton != null)
                claimButton.onClick.RemoveListener(OnClaimButtonClicked);

            if (watchAdButton != null)
                watchAdButton.onClick.RemoveListener(OnWatchAdClicked);

            if (skipRecoveryButton != null)
                skipRecoveryButton.onClick.RemoveListener(OnSkipRecoveryClicked);
        }

        #endregion

        #region Calendar Display

        /// <summary>
        /// Show calendar panel
        /// </summary>
        public void ShowCalendar()
        {
            if (calendarPanel != null)
            {
                calendarPanel.SetActive(true);
                RefreshCalendarUI();
            }
        }

        /// <summary>
        /// Hide calendar panel
        /// </summary>
        public void HideCalendar()
        {
            if (calendarPanel != null)
            {
                calendarPanel.SetActive(false);
            }
        }

        /// <summary>
        /// Refresh entire calendar UI
        /// </summary>
        void RefreshCalendarUI()
        {
            UpdateStreakDisplay();
            UpdateDayCards();
            UpdateClaimButton();
            UpdateNextRewardTimer();
        }

        /// <summary>
        /// Update streak counter display
        /// </summary>
        void UpdateStreakDisplay()
        {
            int streak = rewardSystem.GetCurrentStreak();

            if (streakText != null)
            {
                if (streak > 0)
                {
                    streakText.text = $"🔥 {streak} Day Streak!";
                }
                else
                {
                    streakText.text = "Start Your Streak!";
                }
            }

            // Show/hide fire icon
            if (streakFireIcon != null)
            {
                streakFireIcon.SetActive(streak > 0);
            }
        }

        /// <summary>
        /// Update all day cards
        /// </summary>
        void UpdateDayCards()
        {
            int todayIndex = rewardSystem.GetTodayIndex();
            int streak = rewardSystem.GetCurrentStreak();

            for (int i = 0; i < dayCards.Count; i++)
            {
                if (dayCards[i] != null)
                {
                    DailyReward reward = rewardSystem.GetRewardForDay(i);

                    // Determine state
                    DayCardState state;
                    if (i < todayIndex || (i == todayIndex && rewardSystem.HasClaimedToday()))
                    {
                        state = DayCardState.Completed;
                    }
                    else if (i == todayIndex && !rewardSystem.HasClaimedToday())
                    {
                        state = DayCardState.Current;
                    }
                    else
                    {
                        state = DayCardState.Locked;
                    }

                    // Update card
                    dayCards[i].SetupCard(i + 1, reward, state);
                }
            }
        }

        /// <summary>
        /// Update claim button state
        /// </summary>
        void UpdateClaimButton()
        {
            bool canClaim = !rewardSystem.HasClaimedToday() && !rewardSystem.IsStreakBroken();

            if (claimButton != null)
            {
                claimButton.interactable = canClaim && !isAnimating;

                if (claimButtonText != null)
                {
                    if (rewardSystem.HasClaimedToday())
                    {
                        claimButtonText.text = "Claimed! Come back tomorrow";
                    }
                    else if (rewardSystem.IsStreakBroken())
                    {
                        claimButtonText.text = "Streak Broken - Recover to Continue";
                    }
                    else
                    {
                        DailyReward todayReward = rewardSystem.GetTodayReward();
                        claimButtonText.text = $"Claim {todayReward.GetDisplayText()}";
                    }
                }
            }

            // Show/hide come back message
            if (comeBackMessageText != null)
            {
                comeBackMessageText.gameObject.SetActive(rewardSystem.HasClaimedToday());

                if (rewardSystem.HasClaimedToday())
                {
                    float hoursUntilNext = rewardSystem.GetTimeUntilNextReward() / 3600f;
                    comeBackMessageText.text = $"Come back in {hoursUntilNext:F1} hours for your next reward!";
                }
            }
        }

        /// <summary>
        /// Update next reward countdown timer
        /// </summary>
        void UpdateNextRewardTimer()
        {
            if (nextRewardTimerText == null) return;

            if (!rewardSystem.HasClaimedToday() && !rewardSystem.IsStreakBroken())
            {
                nextRewardTimerText.text = "Available Now!";
                nextRewardTimerText.color = Color.green;
            }
            else
            {
                float seconds = rewardSystem.GetTimeUntilNextReward();

                int hours = Mathf.FloorToInt(seconds / 3600f);
                int minutes = Mathf.FloorToInt((seconds % 3600f) / 60f);
                int secs = Mathf.FloorToInt(seconds % 60f);

                nextRewardTimerText.text = $"Next reward in: {hours:D2}:{minutes:D2}:{secs:D2}";
                nextRewardTimerText.color = Color.white;
            }
        }

        #endregion

        #region Claim Flow

        /// <summary>
        /// Called when claim button clicked
        /// </summary>
        void OnClaimButtonClicked()
        {
            if (isAnimating) return;

            bool success = rewardSystem.ClaimDailyReward();

            if (success)
            {
                // Play claim animation
                DailyReward reward = rewardSystem.GetRewardForDay(rewardSystem.GetTodayIndex() - 1); // -1 because it advanced
                StartCoroutine(PlayClaimAnimation(reward));
            }
            else
            {
                Debug.Log("Failed to claim reward");
            }
        }

        /// <summary>
        /// Play reward claim animation
        /// </summary>
        IEnumerator PlayClaimAnimation(DailyReward reward)
        {
            isAnimating = true;

            // Play sound
            if (claimRewardSound != null)
            {
                AudioSource.PlayClipAtPoint(claimRewardSound, Camera.main.transform.position);
            }

            // Check if Day 7
            bool isDay7 = (rewardSystem.GetTodayIndex() == 0); // Wrapped around to 0 after claiming day 7

            if (isDay7)
            {
                // Day 7 celebration
                yield return StartCoroutine(PlayDay7Celebration());
            }
            else
            {
                // Normal reward animation
                yield return StartCoroutine(PlayRewardAnimation(reward));
            }

            // Refresh UI
            RefreshCalendarUI();

            isAnimating = false;
        }

        /// <summary>
        /// Play normal reward animation
        /// </summary>
        IEnumerator PlayRewardAnimation(DailyReward reward)
        {
            if (rewardIconPrefab != null && coinAnimationTarget != null)
            {
                // Spawn reward icon
                GameObject icon = Instantiate(rewardIconPrefab, transform);
                icon.transform.position = claimButton.transform.position;

                // Animate to HUD
                float duration = 0.8f;
                float elapsed = 0f;

                Vector3 startPos = icon.transform.position;
                Vector3 endPos = coinAnimationTarget.position;

                while (elapsed < duration)
                {
                    elapsed += Time.deltaTime;
                    float t = elapsed / duration;

                    // Ease out curve
                    t = 1f - Mathf.Pow(1f - t, 3f);

                    icon.transform.position = Vector3.Lerp(startPos, endPos, t);

                    yield return null;
                }

                Destroy(icon);
            }

            yield return new WaitForSeconds(0.2f);
        }

        /// <summary>
        /// Play Day 7 grand celebration
        /// </summary>
        IEnumerator PlayDay7Celebration()
        {
            // Play fanfare sound
            if (day7FanfareSound != null)
            {
                AudioSource.PlayClipAtPoint(day7FanfareSound, Camera.main.transform.position);
            }

            // Play confetti
            if (confettiParticles != null)
            {
                confettiParticles.Play();
            }

            // Scale pulse animation
            if (claimButton != null)
            {
                StartCoroutine(PulseAnimation(claimButton.transform));
            }

            // Show "7-Day Streak Complete!" message
            if (streakText != null)
            {
                string originalText = streakText.text;
                streakText.text = "🎉 7-DAY STREAK COMPLETE! 🎉";
                streakText.color = Color.yellow;

                yield return new WaitForSeconds(2f);

                streakText.text = originalText;
                streakText.color = Color.white;
            }

            yield return new WaitForSeconds(1f);
        }

        /// <summary>
        /// Pulse scale animation
        /// </summary>
        IEnumerator PulseAnimation(Transform target)
        {
            Vector3 originalScale = target.localScale;

            float duration = 0.5f;
            float elapsed = 0f;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;

                float scale = 1f + Mathf.Sin(t * Mathf.PI) * 0.2f;
                target.localScale = originalScale * scale;

                yield return null;
            }

            target.localScale = originalScale;
        }

        #endregion

        #region Streak Recovery

        /// <summary>
        /// Show streak recovery popup
        /// </summary>
        void ShowStreakRecoveryPopup()
        {
            if (streakRecoveryPopup != null)
            {
                streakRecoveryPopup.SetActive(true);

                int lostStreak = rewardSystem.GetCurrentStreak();

                if (streakLostText != null)
                {
                    if (lostStreak > 0)
                    {
                        streakLostText.text = $"⚠️ You lost your {lostStreak}-day streak!\n\nWatch an ad to restore it?";
                    }
                    else
                    {
                        streakLostText.text = "⚠️ You missed a day!\n\nWatch an ad to continue your streak?";
                    }
                }
            }
        }

        /// <summary>
        /// Hide streak recovery popup
        /// </summary>
        void HideStreakRecoveryPopup()
        {
            if (streakRecoveryPopup != null)
            {
                streakRecoveryPopup.SetActive(false);
            }
        }

        /// <summary>
        /// Called when watch ad button clicked
        /// </summary>
        void OnWatchAdClicked()
        {
            rewardSystem.RecoverStreak((success) =>
            {
                if (success)
                {
                    // Streak recovered!
                    HideStreakRecoveryPopup();
                    RefreshCalendarUI();

                    // Show success message
                    if (streakText != null)
                    {
                        StartCoroutine(ShowRecoverySuccessMessage());
                    }
                }
                else
                {
                    Debug.Log("Streak recovery failed");
                }
            });
        }

        /// <summary>
        /// Called when skip button clicked
        /// </summary>
        void OnSkipRecoveryClicked()
        {
            HideStreakRecoveryPopup();
        }

        /// <summary>
        /// Show recovery success message
        /// </summary>
        IEnumerator ShowRecoverySuccessMessage()
        {
            if (streakText != null)
            {
                string originalText = streakText.text;
                Color originalColor = streakText.color;

                streakText.text = "✅ Streak Restored!";
                streakText.color = Color.green;

                yield return new WaitForSeconds(2f);

                streakText.text = originalText;
                streakText.color = originalColor;
            }
        }

        #endregion

        #region Event Handlers

        void OnRewardClaimed(int dayIndex)
        {
            Debug.Log($"UI: Reward claimed for day {dayIndex + 1}");
            // Animation is handled in claim flow
        }

        void OnStreakUpdated(int streak)
        {
            Debug.Log($"UI: Streak updated to {streak}");
            UpdateStreakDisplay();
        }

        void OnStreakLost()
        {
            Debug.Log("UI: Streak lost");
            ShowStreakRecoveryPopup();
        }

        void OnStreakRecovered()
        {
            Debug.Log("UI: Streak recovered");
            HideStreakRecoveryPopup();
            RefreshCalendarUI();
        }

        #endregion

        #region Public API

        /// <summary>
        /// Toggle calendar visibility
        /// </summary>
        public void ToggleCalendar()
        {
            if (calendarPanel != null)
            {
                bool isActive = calendarPanel.activeSelf;
                if (isActive)
                {
                    HideCalendar();
                }
                else
                {
                    ShowCalendar();
                }
            }
        }

        #endregion
    }

    /// <summary>
    /// Individual day card component
    /// </summary>
    [System.Serializable]
    public class DailyRewardDayCard
    {
        [Tooltip("Card root GameObject")]
        public GameObject cardRoot;

        [Tooltip("Day number text (1-7)")]
        public TextMeshProUGUI dayNumberText;

        [Tooltip("Reward text")]
        public TextMeshProUGUI rewardText;

        [Tooltip("Reward icon")]
        public Image rewardIcon;

        [Tooltip("Completed checkmark")]
        public GameObject completedCheckmark;

        [Tooltip("Current day highlight")]
        public GameObject currentDayHighlight;

        [Tooltip("Locked overlay")]
        public GameObject lockedOverlay;

        [Tooltip("Day 7 special indicator")]
        public GameObject day7SpecialIndicator;

        /// <summary>
        /// Setup card display
        /// </summary>
        public void SetupCard(int dayNumber, DailyReward reward, DayCardState state)
        {
            // Day number
            if (dayNumberText != null)
            {
                dayNumberText.text = $"Day {dayNumber}";
            }

            // Reward text
            if (rewardText != null)
            {
                rewardText.text = reward.GetDisplayText();
            }

            // Reward icon (set sprite based on reward type)
            if (rewardIcon != null)
            {
                // TODO: Set sprite based on reward.rewardType
                rewardIcon.enabled = true;
            }

            // State visuals
            if (completedCheckmark != null)
            {
                completedCheckmark.SetActive(state == DayCardState.Completed);
            }

            if (currentDayHighlight != null)
            {
                currentDayHighlight.SetActive(state == DayCardState.Current);
            }

            if (lockedOverlay != null)
            {
                lockedOverlay.SetActive(state == DayCardState.Locked);
            }

            // Day 7 special
            if (day7SpecialIndicator != null)
            {
                day7SpecialIndicator.SetActive(dayNumber == 7);
            }

            // Card alpha based on state
            if (cardRoot != null)
            {
                CanvasGroup canvasGroup = cardRoot.GetComponent<CanvasGroup>();
                if (canvasGroup == null)
                {
                    canvasGroup = cardRoot.AddComponent<CanvasGroup>();
                }

                switch (state)
                {
                    case DayCardState.Completed:
                        canvasGroup.alpha = 0.6f; // Faded
                        break;
                    case DayCardState.Current:
                        canvasGroup.alpha = 1.0f; // Full brightness
                        break;
                    case DayCardState.Locked:
                        canvasGroup.alpha = 0.4f; // Very faded
                        break;
                }
            }
        }
    }

    /// <summary>
    /// Day card visual states
    /// </summary>
    public enum DayCardState
    {
        Completed,  // Already claimed (checkmark)
        Current,    // Available to claim (highlighted)
        Locked      // Future day (grayed out)
    }
}
