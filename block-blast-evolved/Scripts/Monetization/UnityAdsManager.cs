using UnityEngine;
using UnityEngine.Advertisements;
using System;
using System.Collections;
using System.Collections.Generic;

namespace BlockBlastEvolved.Monetization
{
    /// <summary>
    /// Production-ready Unity Ads Manager for Block Blast Evolved.
    /// Handles rewarded videos and interstitial ads.
    ///
    /// Revenue Target: 70% of total revenue
    /// Expected Impressions: 4-6 per session
    /// eCPM Target: $8-$12
    /// </summary>
    public class UnityAdsManager : MonoBehaviour, IUnityAdsInitializationListener, IUnityAdsLoadListener, IUnityAdsShowListener
    {
        public static UnityAdsManager Instance { get; private set; }

        [Header("Unity Ads Configuration")]
        [Tooltip("Android Game ID from Unity Dashboard")]
        public string androidGameId = "YOUR_ANDROID_GAME_ID";

        [Tooltip("iOS Game ID from Unity Dashboard")]
        public string iOSGameId = "YOUR_IOS_GAME_ID";

        [Tooltip("Enable test mode (shows test ads)")]
        public bool testMode = true;

        [Header("Ad Unit IDs")]
        [Tooltip("Rewarded video ad unit ID")]
        public string rewardedAdUnitId = "Rewarded_Android";

        [Tooltip("Interstitial ad unit ID")]
        public string interstitialAdUnitId = "Interstitial_Android";

        [Header("Ad Frequency Settings")]
        [Tooltip("Minimum seconds between interstitial ads")]
        public float interstitialCooldown = 180f; // 3 minutes

        [Tooltip("Minimum games before showing interstitial")]
        public int gamesBeforeInterstitial = 3;

        [Tooltip("Enable debug logs")]
        public bool debugMode = true;

        // State tracking
        private bool isInitialized = false;
        private bool rewardedAdLoaded = false;
        private bool interstitialAdLoaded = false;
        private float lastInterstitialTime = 0f;
        private int gamesSinceLastInterstitial = 0;

        // Callbacks
        private Action<bool> currentRewardedCallback;
        private Action currentInterstitialCallback;

        // Events
        public event Action OnAdsInitialized;
        public event Action<bool> OnRewardedAdComplete;
        public event Action OnInterstitialComplete;

        #region Unity Lifecycle

        void Awake()
        {
            // Singleton pattern
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

            // Set platform-specific ad unit IDs
            if (Application.platform == RuntimePlatform.IPhonePlayer)
            {
                rewardedAdUnitId = "Rewarded_iOS";
                interstitialAdUnitId = "Interstitial_iOS";
            }
        }

        void Start()
        {
            // Check if IAP removed ads
            if (IAPManager.Instance != null && IAPManager.Instance.HasRemovedAds())
            {
                DebugLog("Ads disabled - user purchased Remove Ads");
                return;
            }

            // Initialize Unity Ads
            InitializeAds();
        }

        #endregion

        #region Initialization

        /// <summary>
        /// Initialize Unity Ads SDK
        /// </summary>
        void InitializeAds()
        {
            if (isInitialized)
            {
                DebugLog("Ads already initialized");
                return;
            }

            string gameId = Application.platform == RuntimePlatform.IPhonePlayer
                ? iOSGameId
                : androidGameId;

            DebugLog($"Initializing Unity Ads (Game ID: {gameId}, Test Mode: {testMode})");

            Advertisement.Initialize(gameId, testMode, this);
        }

        /// <summary>
        /// Called when Unity Ads initialization succeeds
        /// </summary>
        public void OnInitializationComplete()
        {
            isInitialized = true;
            DebugLog("✅ Unity Ads Initialized Successfully!");

            // Preload both ad types
            LoadRewardedAd();
            LoadInterstitialAd();

            // Fire event
            OnAdsInitialized?.Invoke();

            // Log analytics
            LogAnalytics("ads_initialized", new Dictionary<string, object>
            {
                { "test_mode", testMode }
            });
        }

        /// <summary>
        /// Called when Unity Ads initialization fails
        /// </summary>
        public void OnInitializationFailed(UnityAdsInitializationError error, string message)
        {
            DebugLog($"❌ Unity Ads Initialization Failed: {error} - {message}");

            LogAnalytics("ads_init_failed", new Dictionary<string, object>
            {
                { "error", error.ToString() },
                { "message", message }
            });
        }

        #endregion

        #region Rewarded Video Ads

        /// <summary>
        /// Load rewarded video ad
        /// </summary>
        void LoadRewardedAd()
        {
            if (!isInitialized) return;

            DebugLog("Loading Rewarded Ad...");
            Advertisement.Load(rewardedAdUnitId, this);
        }

        /// <summary>
        /// Show rewarded video ad with callback
        /// </summary>
        /// <param name="onComplete">Callback with reward status (true = watched, false = skipped/error)</param>
        public void ShowRewardedAd(Action<bool> onComplete)
        {
            if (!isInitialized)
            {
                DebugLog("Cannot show ad - not initialized");
                onComplete?.Invoke(false);
                return;
            }

            if (IAPManager.Instance != null && IAPManager.Instance.HasRemovedAds())
            {
                DebugLog("Skipping ad - user purchased Remove Ads. Granting reward anyway.");
                onComplete?.Invoke(true); // Grant reward without ad
                return;
            }

            if (!rewardedAdLoaded)
            {
                DebugLog("Rewarded ad not loaded yet - loading now");
                LoadRewardedAd();
                onComplete?.Invoke(false);
                return;
            }

            currentRewardedCallback = onComplete;

            DebugLog("Showing Rewarded Ad...");
            Advertisement.Show(rewardedAdUnitId, this);

            // Log analytics
            LogAnalytics("rewarded_ad_show", new Dictionary<string, object>
            {
                { "ad_unit", rewardedAdUnitId }
            });
        }

        #endregion

        #region Interstitial Ads

        /// <summary>
        /// Load interstitial ad
        /// </summary>
        void LoadInterstitialAd()
        {
            if (!isInitialized) return;

            DebugLog("Loading Interstitial Ad...");
            Advertisement.Load(interstitialAdUnitId, this);
        }

        /// <summary>
        /// Show interstitial ad (respects cooldown)
        /// </summary>
        public void ShowInterstitialAd(Action onComplete = null)
        {
            if (!isInitialized)
            {
                DebugLog("Cannot show ad - not initialized");
                onComplete?.Invoke();
                return;
            }

            if (IAPManager.Instance != null && IAPManager.Instance.HasRemovedAds())
            {
                DebugLog("Skipping interstitial - user purchased Remove Ads");
                onComplete?.Invoke();
                return;
            }

            // Check cooldown
            if (Time.time - lastInterstitialTime < interstitialCooldown)
            {
                DebugLog($"Interstitial on cooldown ({(int)(interstitialCooldown - (Time.time - lastInterstitialTime))}s remaining)");
                onComplete?.Invoke();
                return;
            }

            // Check game frequency
            if (gamesSinceLastInterstitial < gamesBeforeInterstitial)
            {
                gamesSinceLastInterstitial++;
                DebugLog($"Not enough games ({gamesSinceLastInterstitial}/{gamesBeforeInterstitial})");
                onComplete?.Invoke();
                return;
            }

            if (!interstitialAdLoaded)
            {
                DebugLog("Interstitial ad not loaded yet");
                LoadInterstitialAd();
                onComplete?.Invoke();
                return;
            }

            currentInterstitialCallback = onComplete;

            DebugLog("Showing Interstitial Ad...");
            Advertisement.Show(interstitialAdUnitId, this);

            // Reset counters
            lastInterstitialTime = Time.time;
            gamesSinceLastInterstitial = 0;

            // Log analytics
            LogAnalytics("interstitial_ad_show", new Dictionary<string, object>
            {
                { "ad_unit", interstitialAdUnitId }
            });
        }

        #endregion

        #region IUnityAdsLoadListener Implementation

        /// <summary>
        /// Called when ad load succeeds
        /// </summary>
        public void OnUnityAdsAdLoaded(string placementId)
        {
            DebugLog($"✅ Ad Loaded: {placementId}");

            if (placementId == rewardedAdUnitId)
            {
                rewardedAdLoaded = true;
            }
            else if (placementId == interstitialAdUnitId)
            {
                interstitialAdLoaded = true;
            }

            LogAnalytics("ad_loaded", new Dictionary<string, object>
            {
                { "placement_id", placementId }
            });
        }

        /// <summary>
        /// Called when ad load fails
        /// </summary>
        public void OnUnityAdsFailedToLoad(string placementId, UnityAdsLoadError error, string message)
        {
            DebugLog($"❌ Ad Failed to Load: {placementId} - {error} - {message}");

            if (placementId == rewardedAdUnitId)
            {
                rewardedAdLoaded = false;
                // Retry after delay
                StartCoroutine(RetryLoadAd(placementId, 5f));
            }
            else if (placementId == interstitialAdUnitId)
            {
                interstitialAdLoaded = false;
                StartCoroutine(RetryLoadAd(placementId, 10f));
            }

            LogAnalytics("ad_load_failed", new Dictionary<string, object>
            {
                { "placement_id", placementId },
                { "error", error.ToString() },
                { "message", message }
            });
        }

        /// <summary>
        /// Retry loading ad after delay
        /// </summary>
        IEnumerator RetryLoadAd(string placementId, float delay)
        {
            yield return new WaitForSeconds(delay);
            DebugLog($"Retrying ad load: {placementId}");
            Advertisement.Load(placementId, this);
        }

        #endregion

        #region IUnityAdsShowListener Implementation

        /// <summary>
        /// Called when ad show starts
        /// </summary>
        public void OnUnityAdsShowStart(string placementId)
        {
            DebugLog($"Ad Show Started: {placementId}");
        }

        /// <summary>
        /// Called when ad show completes
        /// </summary>
        public void OnUnityAdsShowComplete(string placementId, UnityAdsShowCompletionState showCompletionState)
        {
            DebugLog($"✅ Ad Show Complete: {placementId} - {showCompletionState}");

            if (placementId == rewardedAdUnitId)
            {
                // Grant reward if user watched complete video
                bool shouldReward = showCompletionState == UnityAdsShowCompletionState.COMPLETED;

                currentRewardedCallback?.Invoke(shouldReward);
                currentRewardedCallback = null;

                OnRewardedAdComplete?.Invoke(shouldReward);

                // Reload ad
                rewardedAdLoaded = false;
                LoadRewardedAd();

                // Analytics
                LogAnalytics("rewarded_ad_complete", new Dictionary<string, object>
                {
                    { "rewarded", shouldReward },
                    { "completion_state", showCompletionState.ToString() }
                });
            }
            else if (placementId == interstitialAdUnitId)
            {
                currentInterstitialCallback?.Invoke();
                currentInterstitialCallback = null;

                OnInterstitialComplete?.Invoke();

                // Reload ad
                interstitialAdLoaded = false;
                LoadInterstitialAd();

                // Analytics
                LogAnalytics("interstitial_ad_complete", new Dictionary<string, object>
                {
                    { "completion_state", showCompletionState.ToString() }
                });
            }
        }

        /// <summary>
        /// Called when ad show fails
        /// </summary>
        public void OnUnityAdsShowFailure(string placementId, UnityAdsShowError error, string message)
        {
            DebugLog($"❌ Ad Show Failed: {placementId} - {error} - {message}");

            if (placementId == rewardedAdUnitId)
            {
                currentRewardedCallback?.Invoke(false);
                currentRewardedCallback = null;

                rewardedAdLoaded = false;
                LoadRewardedAd();
            }
            else if (placementId == interstitialAdUnitId)
            {
                currentInterstitialCallback?.Invoke();
                currentInterstitialCallback = null;

                interstitialAdLoaded = false;
                LoadInterstitialAd();
            }

            LogAnalytics("ad_show_failed", new Dictionary<string, object>
            {
                { "placement_id", placementId },
                { "error", error.ToString() },
                { "message", message }
            });
        }

        /// <summary>
        /// Called when user clicks ad
        /// </summary>
        public void OnUnityAdsShowClick(string placementId)
        {
            DebugLog($"Ad Clicked: {placementId}");

            LogAnalytics("ad_clicked", new Dictionary<string, object>
            {
                { "placement_id", placementId }
            });
        }

        #endregion

        #region Public API

        /// <summary>
        /// Check if ads are available (initialized and not removed via IAP)
        /// </summary>
        public bool AreAdsAvailable()
        {
            if (IAPManager.Instance != null && IAPManager.Instance.HasRemovedAds())
                return false;

            return isInitialized;
        }

        /// <summary>
        /// Check if rewarded ad is ready to show
        /// </summary>
        public bool IsRewardedAdReady()
        {
            return isInitialized && rewardedAdLoaded;
        }

        /// <summary>
        /// Check if interstitial ad is ready to show
        /// </summary>
        public bool IsInterstitialAdReady()
        {
            return isInitialized && interstitialAdLoaded &&
                   (Time.time - lastInterstitialTime >= interstitialCooldown) &&
                   (gamesSinceLastInterstitial >= gamesBeforeInterstitial);
        }

        /// <summary>
        /// Preload both ad types (call when transitioning to game scene)
        /// </summary>
        public void PreloadAds()
        {
            if (!isInitialized) return;

            if (!rewardedAdLoaded)
                LoadRewardedAd();

            if (!interstitialAdLoaded)
                LoadInterstitialAd();

            DebugLog("Preloading ads...");
        }

        /// <summary>
        /// Increment game counter (call on game over)
        /// </summary>
        public void IncrementGameCounter()
        {
            gamesSinceLastInterstitial++;
            DebugLog($"Games since last interstitial: {gamesSinceLastInterstitial}");
        }

        #endregion

        #region Utilities

        void DebugLog(string message)
        {
            if (debugMode)
            {
                Debug.Log($"[UnityAdsManager] {message}");
            }
        }

        void LogAnalytics(string eventName, Dictionary<string, object> parameters)
        {
            // TODO: Integrate with analytics system when available
            DebugLog($"Analytics: {eventName}");
        }

        #endregion

        #region Test Methods (Editor Only)

#if UNITY_EDITOR
        [ContextMenu("Test: Show Rewarded Ad")]
        public void TestShowRewardedAd()
        {
            ShowRewardedAd((rewarded) =>
            {
                Debug.Log($"Test Rewarded Ad Complete - Rewarded: {rewarded}");
            });
        }

        [ContextMenu("Test: Show Interstitial Ad")]
        public void TestShowInterstitialAd()
        {
            ShowInterstitialAd(() =>
            {
                Debug.Log("Test Interstitial Ad Complete");
            });
        }

        [ContextMenu("Test: Reset Cooldowns")]
        public void TestResetCooldowns()
        {
            lastInterstitialTime = 0f;
            gamesSinceLastInterstitial = 0;
            Debug.Log("Ad cooldowns reset");
        }
#endif

        #endregion
    }
}
