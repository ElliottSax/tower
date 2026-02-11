using UnityEngine;

#if UNITY_IOS
using Unity.Advertisement.IosSupport;
#endif

namespace MobileGameCore
{
    /// <summary>
    /// Handles iOS 14+ App Tracking Transparency (ATT) framework.
    /// REQUIRED for ad monetization on iOS 14+.
    /// Must be called before initializing ads.
    ///
    /// IMPORTANT: You MUST add this to Info.plist:
    /// <key>NSUserTrackingUsageDescription</key>
    /// <string>This app uses your device's advertising identifier to show you personalized ads and measure ad performance. This helps keep the game free!</string>
    ///
    /// Note: The privacy message should be specific about what data is collected.
    /// Generic messages like "to improve your experience" may be rejected by Apple.
    ///
    /// USAGE:
    /// ATTManager.Instance.RequestTracking((authorized) => {
    ///     // Now safe to initialize ads
    ///     AdManager.Instance.Initialize();
    /// });
    /// </summary>
    public class ATTManager : MonoBehaviour
    {
        public static ATTManager Instance { get; private set; }

        [Header("Privacy Configuration")]
        [Tooltip("Recommended privacy message for Info.plist (copy to your Info.plist file)")]
        [TextArea(3, 5)]
        [SerializeField] private string recommendedPrivacyMessage =
            "This app uses your device's advertising identifier to show you personalized ads " +
            "and measure ad performance. This helps keep the game free!";

        private bool attRequestComplete = false;
        private bool userAuthorizedTracking = false;

        public bool IsAuthorized => userAuthorizedTracking;
        public bool RequestComplete => attRequestComplete;

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Request tracking authorization. Call this before showing ads.
        /// </summary>
        public void RequestTracking(System.Action<bool> onComplete = null)
        {
            #if UNITY_IOS
            // Check current status
            var status = ATTrackingStatusBinding.GetAuthorizationTrackingStatus();

            Debug.Log($"[ATTManager] Current Status: {status}");

            if (status == ATTrackingStatusBinding.AuthorizationTrackingStatus.NOT_DETERMINED)
            {
                // Show ATT prompt
                Debug.Log("[ATTManager] Showing ATT authorization prompt...");
                ATTrackingStatusBinding.RequestAuthorizationTracking((newStatus) =>
                {
                    HandleATTResponse(newStatus);
                    onComplete?.Invoke(userAuthorizedTracking);
                });
            }
            else
            {
                // Already determined
                HandleATTResponse(status);
                onComplete?.Invoke(userAuthorizedTracking);
            }
            #else
            // Non-iOS platforms - always authorized
            attRequestComplete = true;
            userAuthorizedTracking = true;
            Debug.Log("[ATTManager] ATT not required on non-iOS platform");
            onComplete?.Invoke(true);
            #endif
        }

        #if UNITY_IOS
        void HandleATTResponse(ATTrackingStatusBinding.AuthorizationTrackingStatus status)
        {
            attRequestComplete = true;

            switch (status)
            {
                case ATTrackingStatusBinding.AuthorizationTrackingStatus.AUTHORIZED:
                    Debug.Log("[ATTManager] User authorized tracking ✓");
                    userAuthorizedTracking = true;
                    PlayerPrefs.SetInt("ATT_Authorized", 1);

                    // Track acceptance in analytics
                    if (AnalyticsManager.Instance != null)
                    {
                        AnalyticsManager.Instance.TrackEvent("att_accepted");
                    }
                    break;

                case ATTrackingStatusBinding.AuthorizationTrackingStatus.DENIED:
                case ATTrackingStatusBinding.AuthorizationTrackingStatus.RESTRICTED:
                    Debug.Log($"[ATTManager] User denied tracking (status: {status})");
                    userAuthorizedTracking = false;
                    PlayerPrefs.SetInt("ATT_Authorized", 0);

                    // Track denial in analytics (without personal data)
                    if (AnalyticsManager.Instance != null)
                    {
                        AnalyticsManager.Instance.TrackEvent("att_denied", new System.Collections.Generic.Dictionary<string, object>
                        {
                            { "status", status.ToString() }
                        });
                    }

                    // Log expected revenue impact
                    Debug.LogWarning("[ATTManager] Ad revenue expected to be ~50% lower due to ATT denial");
                    break;

                case ATTrackingStatusBinding.AuthorizationTrackingStatus.NOT_DETERMINED:
                    // Shouldn't happen after request, but handle it
                    Debug.LogWarning("[ATTManager] Status still not determined after request");
                    userAuthorizedTracking = false;
                    break;
            }

            PlayerPrefs.Save();
        }
        #endif

        /// <summary>
        /// Get expected CPM (Cost Per Mille) modifier based on ATT status.
        /// Authorized users typically generate 2x higher ad revenue.
        /// </summary>
        public float GetCPMModifier()
        {
            return userAuthorizedTracking ? 1.0f : 0.5f;
        }

        /// <summary>
        /// Get expected eCPM (effective Cost Per Mille) for planning.
        /// These are rough estimates for iOS in 2024.
        /// </summary>
        public float GetExpectedECPM()
        {
            // Base eCPM for rewarded video ads on iOS (2024 estimates)
            float baseECPM = userAuthorizedTracking ? 12.0f : 6.0f; // USD

            return baseECPM;
        }

        /// <summary>
        /// Check if user can be prompted again (useful for settings menu)
        /// </summary>
        public bool CanRequestAgain()
        {
            #if UNITY_IOS
            var status = ATTrackingStatusBinding.GetAuthorizationTrackingStatus();
            return status == ATTrackingStatusBinding.AuthorizationTrackingStatus.NOT_DETERMINED;
            #else
            return false;
            #endif
        }

        /// <summary>
        /// Get user-friendly status message for display in settings
        /// </summary>
        public string GetStatusMessage()
        {
            if (!attRequestComplete)
            {
                return "Tracking permission not yet requested";
            }

            if (userAuthorizedTracking)
            {
                return "Tracking authorized - Personalized ads enabled";
            }
            else
            {
                return "Tracking denied - Showing non-personalized ads";
            }
        }

        /// <summary>
        /// Show educational message about why tracking helps
        /// Call this before RequestTracking() to improve acceptance rate
        /// </summary>
        public void ShowEducationalMessage(System.Action onDismiss = null)
        {
            // TODO: Implement pre-ATT educational popup
            // Research shows this can improve acceptance rates by 20-30%

            Debug.Log("[ATTManager] Educational message: " + recommendedPrivacyMessage);
            onDismiss?.Invoke();
        }

        #if UNITY_EDITOR
        void OnValidate()
        {
            // Reminder in Unity Editor
            Debug.Log($"[ATTManager] Remember to add NSUserTrackingUsageDescription to Info.plist:\n{recommendedPrivacyMessage}");
        }
        #endif
    }
}
