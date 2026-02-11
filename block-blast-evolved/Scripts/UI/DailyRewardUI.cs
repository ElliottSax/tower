using UnityEngine;
using UnityEngine.UI;
using TMPro;
using BlockBlastEvolved.Progression;

namespace BlockBlastEvolved.UI
{
    /// <summary>
    /// Daily reward UI with 7-day calendar.
    /// Shows current streak, available rewards, and claim button.
    /// </summary>
    public class DailyRewardUI : MonoBehaviour
    {
        [Header("UI Panels")]
        [Tooltip("Daily reward popup panel")]
        public GameObject dailyRewardPanel;

        [Header("Reward Display")]
        [Tooltip("Today's reward display")]
        public GameObject todayRewardDisplay;

        [Tooltip("Reward icon")]
        public Image rewardIcon;

        [Tooltip("Reward description text")]
        public TextMeshProUGUI rewardDescriptionText;

        [Tooltip("Reward amount text (coins/gems)")]
        public TextMeshProUGUI rewardAmountText;

        [Header("Streak Display")]
        [Tooltip("Current streak text")]
        public TextMeshProUGUI streakText;

        [Tooltip("Day counter text")]
        public TextMeshProUGUI dayText;

        [Header("Weekly Calendar")]
        [Tooltip("Container for 7 day cards")]
        public Transform calendarContainer;

        [Tooltip("Day card prefab")]
        public GameObject dayCardPrefab;

        [Header("Claim Button")]
        [Tooltip("Claim reward button")]
        public Button claimButton;

        [Tooltip("Claim button text")]
        public TextMeshProUGUI claimButtonText;

        [Header("Settings")]
        [Tooltip("Show popup on app start if reward available")]
        public bool showOnStart = true;

        [Tooltip("Auto-show delay in seconds")]
        public float showDelay = 1f;

        // Day cards cache
        private DayCard[] dayCards = new DayCard[7];

        #region Unity Lifecycle

        void Start()
        {
            // Setup claim button
            if (claimButton != null)
            {
                claimButton.onClick.AddListener(OnClaimClicked);
            }

            // Subscribe to events
            if (DailyRewardSystem.Instance != null)
            {
                DailyRewardSystem.Instance.OnRewardClaimed += OnRewardClaimed;
                DailyRewardSystem.Instance.OnStreakIncreased += OnStreakIncreased;
                DailyRewardSystem.Instance.OnStreakReset += OnStreakReset;
            }

            // Build calendar
            BuildWeeklyCalendar();

            // Hide panel initially
            if (dailyRewardPanel != null)
            {
                dailyRewardPanel.SetActive(false);
            }

            // Auto-show if reward available
            if (showOnStart)
            {
                Invoke(nameof(CheckAndShowReward), showDelay);
            }
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (DailyRewardSystem.Instance != null)
            {
                DailyRewardSystem.Instance.OnRewardClaimed -= OnRewardClaimed;
                DailyRewardSystem.Instance.OnStreakIncreased -= OnStreakIncreased;
                DailyRewardSystem.Instance.OnStreakReset -= OnStreakReset;
            }
        }

        #endregion

        #region UI Display

        /// <summary>
        /// Check if reward available and show panel
        /// </summary>
        void CheckAndShowReward()
        {
            if (DailyRewardSystem.Instance != null &&
                DailyRewardSystem.Instance.CanClaimToday())
            {
                ShowDailyRewardPanel();
            }
        }

        /// <summary>
        /// Show daily reward panel
        /// </summary>
        public void ShowDailyRewardPanel()
        {
            if (dailyRewardPanel != null)
            {
                dailyRewardPanel.SetActive(true);
            }

            UpdateDisplay();
        }

        /// <summary>
        /// Hide daily reward panel
        /// </summary>
        public void HideDailyRewardPanel()
        {
            if (dailyRewardPanel != null)
            {
                dailyRewardPanel.SetActive(false);
            }
        }

        /// <summary>
        /// Update all UI elements
        /// </summary>
        void UpdateDisplay()
        {
            if (DailyRewardSystem.Instance == null) return;

            // Update streak display
            UpdateStreakDisplay();

            // Update today's reward display
            UpdateTodayReward();

            // Update claim button
            UpdateClaimButton();

            // Update calendar
            UpdateCalendar();
        }

        /// <summary>
        /// Update streak counter
        /// </summary>
        void UpdateStreakDisplay()
        {
            int streak = DailyRewardSystem.Instance.GetCurrentStreak();
            int currentDay = DailyRewardSystem.Instance.GetCurrentDay();

            if (streakText != null)
            {
                streakText.text = $"{streak} Day Streak!";
            }

            if (dayText != null)
            {
                dayText.text = $"Day {currentDay} / 7";
            }
        }

        /// <summary>
        /// Update today's reward display
        /// </summary>
        void UpdateTodayReward()
        {
            var reward = DailyRewardSystem.Instance.GetNextReward();

            if (rewardDescriptionText != null)
            {
                rewardDescriptionText.text = reward.description;
            }

            if (rewardAmountText != null)
            {
                string amountText = "";

                if (reward.coins > 0)
                {
                    amountText += $"{reward.coins} Coins";
                }

                if (reward.gems > 0)
                {
                    if (amountText.Length > 0) amountText += " + ";
                    amountText += $"{reward.gems} Gems";
                }

                if (reward.heroUnlock)
                {
                    if (amountText.Length > 0) amountText += " + ";
                    amountText += "Random Hero";
                }

                rewardAmountText.text = amountText;
            }

            if (rewardIcon != null && reward.rewardIcon != null)
            {
                rewardIcon.sprite = reward.rewardIcon;
            }
        }

        /// <summary>
        /// Update claim button state
        /// </summary>
        void UpdateClaimButton()
        {
            bool canClaim = DailyRewardSystem.Instance.CanClaimToday();

            if (claimButton != null)
            {
                claimButton.interactable = canClaim;
            }

            if (claimButtonText != null)
            {
                claimButtonText.text = canClaim ? "Claim Reward" : "Come Back Tomorrow";
            }
        }

        #endregion

        #region Weekly Calendar

        /// <summary>
        /// Build 7-day calendar UI
        /// </summary>
        void BuildWeeklyCalendar()
        {
            if (calendarContainer == null || dayCardPrefab == null) return;
            if (DailyRewardSystem.Instance == null) return;

            // Clear existing cards
            foreach (Transform child in calendarContainer)
            {
                Destroy(child.gameObject);
            }

            // Get all weekly rewards
            var weeklyRewards = DailyRewardSystem.Instance.GetWeeklyRewards();

            // Create card for each day
            for (int i = 0; i < weeklyRewards.Length; i++)
            {
                GameObject cardObj = Instantiate(dayCardPrefab, calendarContainer);
                DayCard card = cardObj.GetComponent<DayCard>();

                if (card != null)
                {
                    card.Initialize(weeklyRewards[i], i);
                    dayCards[i] = card;
                }
            }

            // Update calendar state
            UpdateCalendar();
        }

        /// <summary>
        /// Update calendar day states
        /// </summary>
        void UpdateCalendar()
        {
            if (DailyRewardSystem.Instance == null) return;

            int currentStreak = DailyRewardSystem.Instance.GetCurrentStreak();
            int currentDay = DailyRewardSystem.Instance.GetCurrentDay();

            for (int i = 0; i < dayCards.Length; i++)
            {
                if (dayCards[i] == null) continue;

                // Determine day state
                DayState state;

                if (i < currentDay - 1)
                {
                    // Already claimed
                    state = DayState.Claimed;
                }
                else if (i == currentDay - 1)
                {
                    // Current day
                    state = DailyRewardSystem.Instance.CanClaimToday()
                        ? DayState.Available
                        : DayState.Claimed;
                }
                else
                {
                    // Future day
                    state = DayState.Locked;
                }

                dayCards[i].UpdateState(state);
            }
        }

        #endregion

        #region Claim Flow

        /// <summary>
        /// Handle claim button click
        /// </summary>
        void OnClaimClicked()
        {
            if (DailyRewardSystem.Instance == null) return;

            if (DailyRewardSystem.Instance.ClaimDailyReward())
            {
                // Play claim animation
                PlayClaimAnimation();

                // Update display after short delay
                Invoke(nameof(UpdateDisplay), 0.5f);

                // Auto-hide after 3 seconds
                Invoke(nameof(HideDailyRewardPanel), 3f);
            }
            else
            {
                Debug.LogWarning("Failed to claim reward");
            }
        }

        /// <summary>
        /// Play claim reward animation
        /// </summary>
        void PlayClaimAnimation()
        {
            // TODO: Implement claim animation
            // - Scale up reward icon
            // - Play particle effects
            // - Show floating text
            Debug.Log("[ANIMATION] Playing claim animation");
        }

        #endregion

        #region Event Handlers

        /// <summary>
        /// Called when reward is claimed
        /// </summary>
        void OnRewardClaimed(DailyReward reward, int newStreak)
        {
            Debug.Log($"Reward claimed: {reward.description} - Streak: {newStreak}");
            UpdateDisplay();
        }

        /// <summary>
        /// Called when streak increases
        /// </summary>
        void OnStreakIncreased(int newStreak)
        {
            Debug.Log($"Streak increased to {newStreak}");

            // Show celebration for week completion
            if (newStreak % 7 == 0)
            {
                ShowWeekCompletePopup(newStreak / 7);
            }
        }

        /// <summary>
        /// Called when streak resets
        /// </summary>
        void OnStreakReset()
        {
            Debug.Log("Streak reset to 0");
            UpdateDisplay();
        }

        /// <summary>
        /// Show week complete celebration
        /// </summary>
        void ShowWeekCompletePopup(int weekNumber)
        {
            Debug.Log($"🎉 Week {weekNumber} Complete!");
            // TODO: Show popup with celebration animation
        }

        #endregion

        #region Helper Classes

        /// <summary>
        /// Individual day card component
        /// </summary>
        public class DayCard : MonoBehaviour
        {
            [Header("UI Elements")]
            public TextMeshProUGUI dayNumberText;
            public Image rewardIcon;
            public TextMeshProUGUI rewardAmountText;
            public GameObject claimedIndicator;
            public GameObject availableIndicator;
            public GameObject lockedOverlay;

            private DailyReward reward;
            private int dayIndex;

            public void Initialize(DailyReward reward, int dayIndex)
            {
                this.reward = reward;
                this.dayIndex = dayIndex;

                // Set day number
                if (dayNumberText != null)
                {
                    dayNumberText.text = $"Day {reward.day}";
                }

                // Set reward icon
                if (rewardIcon != null && reward.rewardIcon != null)
                {
                    rewardIcon.sprite = reward.rewardIcon;
                }

                // Set reward amount
                if (rewardAmountText != null)
                {
                    string amount = "";
                    if (reward.coins > 0) amount = $"{reward.coins}";
                    if (reward.gems > 0) amount = $"{reward.gems}g";
                    if (reward.heroUnlock) amount = "Hero";
                    rewardAmountText.text = amount;
                }
            }

            public void UpdateState(DayState state)
            {
                // Update indicators
                if (claimedIndicator != null)
                    claimedIndicator.SetActive(state == DayState.Claimed);

                if (availableIndicator != null)
                    availableIndicator.SetActive(state == DayState.Available);

                if (lockedOverlay != null)
                    lockedOverlay.SetActive(state == DayState.Locked);

                // Update visual style
                var canvasGroup = GetComponent<CanvasGroup>();
                if (canvasGroup != null)
                {
                    canvasGroup.alpha = state == DayState.Locked ? 0.5f : 1f;
                }
            }
        }

        #endregion
    }

    /// <summary>
    /// Day card states
    /// </summary>
    public enum DayState
    {
        Locked,    // Future day
        Available, // Can claim today
        Claimed    // Already claimed
    }
}
