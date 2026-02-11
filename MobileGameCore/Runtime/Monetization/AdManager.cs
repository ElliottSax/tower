using UnityEngine;
using UnityEngine.Advertisements;

namespace MobileGameCore
{
    /// <summary>
    /// Manages Unity Ads integration for rewarded and interstitial ads.
    /// Handles initialization, showing ads, and callbacks.
    /// FIXED: Ensures Time.timeScale is always restored after ads to prevent soft-lock
    ///
    /// SETUP REQUIRED:
    /// 1. Install Unity Ads package (Package Manager → Ads)
    /// 2. Enable Unity Ads in Services window
    /// 3. Set your Game IDs in the inspector
    /// 4. Configure ad placements in Unity Dashboard
    ///
    /// USAGE:
    /// AdManager.Instance.ShowRewardedAd((success) => {
    ///     if (success) {
    ///         // Grant reward
    ///     }
    /// });
    /// </summary>
    public class AdManager : MonoBehaviour, IUnityAdsInitializationListener, IUnityAdsLoadListener, IUnityAdsShowListener
    {
        public static AdManager Instance { get; private set; }

        [Header("Ad IDs")]
        [SerializeField] private string androidGameID = "YOUR_ANDROID_GAME_ID";
        [SerializeField] private string iOSGameID = "YOUR_IOS_GAME_ID";

        [Header("Ad Units")]
        [SerializeField] private string rewardedAdUnitID = "Rewarded_iOS"; // Or "Rewarded_Android"
        [SerializeField] private string interstitialAdUnitID = "Interstitial_iOS"; // Or "Interstitial_Android"

        [Header("Settings")]
        [SerializeField] private bool testMode = true;

        private string gameID;
        private bool isInitialized = false;
        private System.Action<bool> currentAdCallback;
        private float previousTimeScale = 1f; // Store previous timeScale to restore

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
                return;
            }
        }

        void Start()
        {
            // Wait for ATT before initializing ads (iOS only)
            #if UNITY_IOS
            if (ATTManager.Instance != null && !ATTManager.Instance.RequestComplete)
            {
                ATTManager.Instance.RequestTracking((authorized) =>
                {
                    InitializeAds();
                });
            }
            else
            {
                InitializeAds();
            }
            #else
            InitializeAds();
            #endif
        }

        void InitializeAds()
        {
            #if UNITY_IOS
            gameID = iOSGameID;
            #elif UNITY_ANDROID
            gameID = androidGameID;
            #else
            gameID = iOSGameID; // Default
            #endif

            if (string.IsNullOrEmpty(gameID) || gameID.StartsWith("YOUR_"))
            {
                Debug.LogWarning("[AdManager] Ad Game ID not set! Ads will not work.");
                return;
            }

            Debug.Log($"[AdManager] Initializing Unity Ads (Test Mode: {testMode})...");
            Advertisement.Initialize(gameID, testMode, this);
        }

        #region IUnityAdsInitializationListener

        public void OnInitializationComplete()
        {
            isInitialized = true;
            Debug.Log("[AdManager] Unity Ads initialized successfully");

            // Pre-load first ad
            LoadRewardedAd();
        }

        public void OnInitializationFailed(UnityAdsInitializationError error, string message)
        {
            Debug.LogError($"[AdManager] Unity Ads initialization failed: {error} - {message}");
        }

        #endregion

        #region Load Ads

        void LoadRewardedAd()
        {
            if (!isInitialized) return;

            Advertisement.Load(rewardedAdUnitID, this);
        }

        void LoadInterstitialAd()
        {
            if (!isInitialized) return;

            Advertisement.Load(interstitialAdUnitID, this);
        }

        public void OnUnityAdsAdLoaded(string placementId)
        {
            Debug.Log($"[AdManager] Ad loaded: {placementId}");
        }

        public void OnUnityAdsFailedToLoad(string placementId, UnityAdsLoadError error, string message)
        {
            Debug.LogWarning($"[AdManager] Ad failed to load: {placementId} - {error} - {message}");

            // Retry after delay
            if (placementId == rewardedAdUnitID)
                Invoke(nameof(LoadRewardedAd), 5f);
            else if (placementId == interstitialAdUnitID)
                Invoke(nameof(LoadInterstitialAd), 5f);
        }

        #endregion

        #region Show Ads

        /// <summary>
        /// Show rewarded video ad. Call this from UI buttons or game logic.
        /// </summary>
        /// <param name="onComplete">Callback: true if user watched full ad, false if skipped/failed</param>
        public void ShowRewardedAd(System.Action<bool> onComplete)
        {
            if (!isInitialized)
            {
                Debug.LogWarning("[AdManager] Ads not initialized");
                onComplete?.Invoke(false);
                return;
            }

            currentAdCallback = onComplete;

            // Check if ad is already showing
            if (Advertisement.isShowing)
            {
                Debug.LogWarning("[AdManager] Ad already showing");
                onComplete?.Invoke(false);
                return;
            }

            // Show ad
            Advertisement.Show(rewardedAdUnitID, this);

            // Analytics
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.TrackAdView("rewarded", "manual_trigger");
            }
        }

        /// <summary>
        /// Show interstitial ad (non-rewarded, between levels/games)
        /// </summary>
        /// <param name="onComplete">Callback: true if ad was shown, false if failed</param>
        public void ShowInterstitialAd(System.Action<bool> onComplete = null)
        {
            if (!isInitialized)
            {
                Debug.LogWarning("[AdManager] Ads not initialized");
                onComplete?.Invoke(false);
                return;
            }

            currentAdCallback = onComplete;

            if (Advertisement.isShowing)
            {
                Debug.LogWarning("[AdManager] Ad already showing");
                onComplete?.Invoke(false);
                return;
            }

            Advertisement.Show(interstitialAdUnitID, this);

            // Analytics
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.TrackAdView("interstitial", "manual_trigger");
            }
        }

        public void OnUnityAdsShowComplete(string placementId, UnityAdsShowCompletionState showCompletionState)
        {
            bool success = showCompletionState == UnityAdsShowCompletionState.COMPLETED;

            Debug.Log($"[AdManager] Ad show complete: {placementId} - Success: {success}");

            // CRITICAL FIX: Always restore timeScale
            RestoreGameState();

            // Callback
            currentAdCallback?.Invoke(success);
            currentAdCallback = null;

            // Preload next ad
            if (placementId == rewardedAdUnitID)
                LoadRewardedAd();
            else if (placementId == interstitialAdUnitID)
                LoadInterstitialAd();

            // Analytics
            if (success && AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.TrackEvent("ad_completed", new System.Collections.Generic.Dictionary<string, object>
                {
                    { "placement", placementId }
                });
            }
        }

        public void OnUnityAdsShowFailure(string placementId, UnityAdsShowError error, string message)
        {
            Debug.LogError($"[AdManager] Ad show failed: {placementId} - {error} - {message}");

            // CRITICAL FIX: Always restore timeScale even on failure
            RestoreGameState();

            // Callback with failure
            currentAdCallback?.Invoke(false);
            currentAdCallback = null;

            // Try to reload
            if (placementId == rewardedAdUnitID)
                LoadRewardedAd();
            else if (placementId == interstitialAdUnitID)
                LoadInterstitialAd();
        }

        public void OnUnityAdsShowStart(string placementId)
        {
            Debug.Log($"[AdManager] Ad started: {placementId}");

            // Store current timeScale before pausing
            previousTimeScale = Time.timeScale;

            // Pause game
            Time.timeScale = 0f;

            // Mute audio (if AudioManager available)
            // NOTE: This assumes you have AudioManager in your project
            // Comment out if not using AudioManager
            /*
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PauseMusic();
            }
            */
        }

        public void OnUnityAdsShowClick(string placementId)
        {
            Debug.Log($"[AdManager] Ad clicked: {placementId}");

            // Analytics
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.TrackAdClick(placementId.Contains("Rewarded") ? "rewarded" : "interstitial");
            }
        }

        #endregion

        #region Game State Management

        /// <summary>
        /// Restore game state after ad completes or fails
        /// CRITICAL: This must ALWAYS be called to prevent game soft-lock
        /// </summary>
        private void RestoreGameState()
        {
            // Restore timeScale
            Time.timeScale = previousTimeScale;

            // Resume audio (if AudioManager available)
            /*
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.ResumeMusic();
            }
            */

            Debug.Log($"[AdManager] Game state restored (timeScale: {Time.timeScale})");
        }

        #endregion

        #region Utility

        /// <summary>
        /// Check if rewarded ad is available to show
        /// </summary>
        public bool IsRewardedAdReady()
        {
            return isInitialized && Advertisement.isInitialized;
        }

        /// <summary>
        /// Check if interstitial ad is available to show
        /// </summary>
        public bool IsInterstitialAdReady()
        {
            return isInitialized && Advertisement.isInitialized;
        }

        /// <summary>
        /// Emergency recovery if game gets stuck in paused state
        /// Call this from a debug menu or automatic detection
        /// </summary>
        public void EmergencyUnpause()
        {
            Debug.LogWarning("[AdManager] Emergency unpause triggered!");
            Time.timeScale = 1f;

            /*
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.ResumeMusic();
            }
            */
        }

        void OnApplicationPause(bool pauseStatus)
        {
            // Safety: If app is resumed but still frozen, unpause
            if (!pauseStatus && Time.timeScale == 0f && !Advertisement.isShowing)
            {
                Debug.LogWarning("[AdManager] Detected frozen game state on app resume, fixing...");
                EmergencyUnpause();
            }
        }

        #endregion
    }
}
