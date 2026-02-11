using UnityEngine;
using System.Collections.Generic;

// Firebase imports - requires Firebase Unity SDK
// Download from: https://firebase.google.com/download/unity
#if UNITY_ANDROID || UNITY_IOS
using Firebase;
using Firebase.Analytics;
using Firebase.Extensions;
#endif

namespace MobileGameCore
{
    /// <summary>
    /// Firebase Analytics integration for tracking game events and user behavior.
    /// Features graceful degradation when Firebase unavailable, comprehensive error handling,
    /// and flexible event tracking.
    ///
    /// SETUP REQUIRED:
    /// 1. Download Firebase Unity SDK from firebase.google.com/download/unity
    /// 2. Import FirebaseAnalytics.unitypackage
    /// 3. Add google-services.json (Android) or GoogleService-Info.plist (iOS) to Assets/
    /// 4. Configure Firebase project in Firebase Console
    ///
    /// USAGE:
    /// - Generic: AnalyticsManager.Instance.TrackEvent("my_event", parameters);
    /// - Built-in: AnalyticsManager.Instance.TrackLevelStart(1);
    /// - Custom: Extend this class for game-specific events
    /// </summary>
    public class AnalyticsManager : MonoBehaviour
    {
        public static AnalyticsManager Instance { get; private set; }

        private bool isInitialized = false;
        private bool firebaseAvailable = false;

        [Header("Debug Settings")]
        [SerializeField] private bool enableDebugLogs = true;
        [SerializeField] private bool enableOfflineMode = false; // For testing without Firebase

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeFirebase();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        async void InitializeFirebase()
        {
            #if UNITY_ANDROID || UNITY_IOS
            try
            {
                var dependencyStatus = await FirebaseApp.CheckAndFixDependenciesAsync();

                if (dependencyStatus == DependencyStatus.Available)
                {
                    FirebaseApp app = FirebaseApp.DefaultInstance;
                    isInitialized = true;
                    firebaseAvailable = true;

                    // Enable analytics collection (respects user consent from ATT)
                    FirebaseAnalytics.SetAnalyticsCollectionEnabled(true);

                    LogDebug("Firebase Analytics initialized successfully");

                    // Track app open
                    TrackEvent("app_open");
                }
                else
                {
                    LogError($"Firebase initialization failed: {dependencyStatus}");
                    firebaseAvailable = false;
                    isInitialized = true; // Still mark as initialized to prevent spam
                }
            }
            catch (System.Exception ex)
            {
                LogError($"Firebase initialization exception: {ex.Message}");
                firebaseAvailable = false;
                isInitialized = true;
            }
            #else
            LogWarning("Firebase Analytics not available on this platform (Editor/Desktop). Using offline mode.");
            isInitialized = true;
            firebaseAvailable = false;
            #endif
        }

        #region Event Tracking

        /// <summary>
        /// Track custom event with parameters
        /// </summary>
        public void TrackEvent(string eventName, Dictionary<string, object> parameters = null)
        {
            if (!isInitialized)
            {
                LogWarning($"Analytics not initialized yet, queuing event: {eventName}");
                return;
            }

            // Validate event name
            if (string.IsNullOrEmpty(eventName))
            {
                LogError("Cannot track event with null or empty name");
                return;
            }

            // Sanitize event name (Firebase requirements: lowercase, underscores, max 40 chars)
            string sanitizedName = SanitizeEventName(eventName);

            try
            {
                #if UNITY_ANDROID || UNITY_IOS
                if (firebaseAvailable)
                {
                    if (parameters == null || parameters.Count == 0)
                    {
                        FirebaseAnalytics.LogEvent(sanitizedName);
                    }
                    else
                    {
                        // Convert dictionary to Firebase parameters
                        List<Parameter> firebaseParams = new List<Parameter>();

                        foreach (var kvp in parameters)
                        {
                            if (kvp.Value is string stringValue)
                                firebaseParams.Add(new Parameter(kvp.Key, stringValue));
                            else if (kvp.Value is int intValue)
                                firebaseParams.Add(new Parameter(kvp.Key, intValue));
                            else if (kvp.Value is long longValue)
                                firebaseParams.Add(new Parameter(kvp.Key, longValue));
                            else if (kvp.Value is double doubleValue)
                                firebaseParams.Add(new Parameter(kvp.Key, doubleValue));
                            else if (kvp.Value is float floatValue)
                                firebaseParams.Add(new Parameter(kvp.Key, (double)floatValue));
                            else if (kvp.Value is bool boolValue)
                                firebaseParams.Add(new Parameter(kvp.Key, boolValue ? 1 : 0));
                            else
                                firebaseParams.Add(new Parameter(kvp.Key, kvp.Value.ToString()));
                        }

                        FirebaseAnalytics.LogEvent(sanitizedName, firebaseParams.ToArray());
                    }
                }
                #endif

                LogDebug($"Analytics Event: {sanitizedName}" + (parameters != null ? $" ({parameters.Count} params)" : ""));
            }
            catch (System.Exception ex)
            {
                LogError($"Failed to log analytics event '{sanitizedName}': {ex.Message}");
            }
        }

        private string SanitizeEventName(string eventName)
        {
            // Firebase requirements: lowercase, underscores, no special characters, max 40 chars
            string sanitized = eventName.ToLower().Replace(" ", "_").Replace("-", "_");
            sanitized = System.Text.RegularExpressions.Regex.Replace(sanitized, @"[^a-z0-9_]", "");

            if (sanitized.Length > 40)
                sanitized = sanitized.Substring(0, 40);

            return sanitized;
        }

        #endregion

        #region Common Game Events
        // These are common events for most mobile games. Extend or modify for your game.

        public void TrackLevelStart(int levelNumber, string context = "")
        {
            var parameters = new Dictionary<string, object>
            {
                { "level_number", levelNumber }
            };

            if (!string.IsNullOrEmpty(context))
                parameters.Add("context", context);

            TrackEvent("level_start", parameters);
        }

        public void TrackLevelComplete(int levelNumber, int score, float timeSeconds, int stars = 0)
        {
            var parameters = new Dictionary<string, object>
            {
                { "level_number", levelNumber },
                { "score", score },
                { "time_seconds", (int)timeSeconds }
            };

            if (stars > 0)
                parameters.Add("stars", stars);

            TrackEvent("level_complete", parameters);
        }

        public void TrackLevelFail(int levelNumber, string failReason = "")
        {
            var parameters = new Dictionary<string, object>
            {
                { "level_number", levelNumber }
            };

            if (!string.IsNullOrEmpty(failReason))
                parameters.Add("fail_reason", failReason);

            TrackEvent("level_fail", parameters);
        }

        public void TrackItemCollected(string itemType, int value = 0, string context = "")
        {
            var parameters = new Dictionary<string, object>
            {
                { "item_type", itemType }
            };

            if (value > 0)
                parameters.Add("value", value);
            if (!string.IsNullOrEmpty(context))
                parameters.Add("context", context);

            TrackEvent("item_collected", parameters);
        }

        public void TrackItemUnlock(string itemName, string unlockMethod = "gameplay")
        {
            TrackEvent("item_unlock", new Dictionary<string, object>
            {
                { "item_name", itemName },
                { "unlock_method", unlockMethod } // "gameplay", "purchase", "reward"
            });
        }

        public void TrackPurchase(string itemName, int cost, string currency = "coins")
        {
            TrackEvent("purchase", new Dictionary<string, object>
            {
                { "item_name", itemName },
                { "cost", cost },
                { "currency", currency }
            });
        }

        /// <summary>
        /// Track real-money IAP purchase (use Firebase's ecommerce event for revenue tracking)
        /// </summary>
        public void LogPurchase(string productId, double price, string currencyCode)
        {
            #if UNITY_ANDROID || UNITY_IOS
            if (firebaseAvailable)
            {
                FirebaseAnalytics.LogEvent(FirebaseAnalytics.EventPurchase, new[]
                {
                    new Parameter(FirebaseAnalytics.ParameterItemId, productId),
                    new Parameter(FirebaseAnalytics.ParameterValue, price),
                    new Parameter(FirebaseAnalytics.ParameterCurrency, currencyCode)
                });
            }
            #endif

            LogDebug($"IAP Purchase tracked: {productId}, {price} {currencyCode}");
        }

        public void TrackAdView(string adType, string placement)
        {
            TrackEvent("ad_view", new Dictionary<string, object>
            {
                { "ad_type", adType }, // "rewarded", "interstitial", "banner"
                { "placement", placement } // "level_fail", "double_reward", etc.
            });
        }

        public void TrackAdClick(string adType, string placement = "")
        {
            var parameters = new Dictionary<string, object>
            {
                { "ad_type", adType }
            };

            if (!string.IsNullOrEmpty(placement))
                parameters.Add("placement", placement);

            TrackEvent("ad_click", parameters);
        }

        public void TrackAdReward(string rewardType, int rewardAmount)
        {
            TrackEvent("ad_reward", new Dictionary<string, object>
            {
                { "reward_type", rewardType },
                { "reward_amount", rewardAmount }
            });
        }

        public void TrackTutorialStep(int stepNumber, string stepName)
        {
            TrackEvent("tutorial_step", new Dictionary<string, object>
            {
                { "step_number", stepNumber },
                { "step_name", stepName }
            });
        }

        public void TrackTutorialComplete()
        {
            TrackEvent("tutorial_complete");
        }

        public void TrackAchievementUnlock(string achievementId, string achievementName = "")
        {
            var parameters = new Dictionary<string, object>
            {
                { "achievement_id", achievementId }
            };

            if (!string.IsNullOrEmpty(achievementName))
                parameters.Add("achievement_name", achievementName);

            TrackEvent("achievement_unlock", parameters);
        }

        public void TrackSaveFileCorruption(string corruptionType)
        {
            TrackEvent("save_file_corruption", new Dictionary<string, object>
            {
                { "corruption_type", corruptionType }
            });
        }

        public void TrackError(string errorType, string errorMessage)
        {
            TrackEvent("error", new Dictionary<string, object>
            {
                { "error_type", errorType },
                { "error_message", errorMessage }
            });
        }

        public void TrackSessionEnd(float sessionDuration, int levelsPlayed)
        {
            TrackEvent("session_end", new Dictionary<string, object>
            {
                { "session_duration", (int)sessionDuration },
                { "levels_played", levelsPlayed }
            });
        }

        #endregion

        #region User Properties

        public void SetUserProperty(string propertyName, string value)
        {
            if (!isInitialized || string.IsNullOrEmpty(propertyName))
                return;

            #if UNITY_ANDROID || UNITY_IOS
            if (firebaseAvailable)
            {
                FirebaseAnalytics.SetUserProperty(propertyName, value);
                LogDebug($"User Property Set: {propertyName} = {value}");
            }
            #endif
        }

        public void SetTotalPlayTime(int seconds)
        {
            SetUserProperty("total_play_time", seconds.ToString());
        }

        public void SetPlayerLevel(int level)
        {
            SetUserProperty("player_level", level.ToString());
        }

        public void SetInputMode(string inputMode)
        {
            SetUserProperty("input_mode", inputMode);
        }

        public void SetHasMadePurchase(bool hasPurchased)
        {
            SetUserProperty("has_made_purchase", hasPurchased.ToString().ToLower());
        }

        #endregion

        #region Utility

        public bool IsInitialized()
        {
            return isInitialized;
        }

        public bool IsFirebaseAvailable()
        {
            return firebaseAvailable;
        }

        private void LogDebug(string message)
        {
            if (enableDebugLogs)
            {
                Debug.Log($"[AnalyticsManager] {message}");
            }
        }

        private void LogWarning(string message)
        {
            Debug.LogWarning($"[AnalyticsManager] {message}");
        }

        private void LogError(string message)
        {
            Debug.LogError($"[AnalyticsManager] {message}");
        }

        #endregion

        #region Session Tracking

        private float sessionStartTime;
        private int levelsPlayedThisSession = 0;

        void Start()
        {
            sessionStartTime = Time.realtimeSinceStartup;
        }

        public void IncrementLevelsPlayed()
        {
            levelsPlayedThisSession++;
        }

        void OnApplicationPause(bool pauseStatus)
        {
            if (pauseStatus)
            {
                // App going to background - track session end
                float sessionDuration = Time.realtimeSinceStartup - sessionStartTime;
                TrackSessionEnd(sessionDuration, levelsPlayedThisSession);
            }
            else
            {
                // App resuming - start new session
                sessionStartTime = Time.realtimeSinceStartup;
                levelsPlayedThisSession = 0;
            }
        }

        void OnApplicationQuit()
        {
            // Track session end on quit
            float sessionDuration = Time.realtimeSinceStartup - sessionStartTime;
            TrackSessionEnd(sessionDuration, levelsPlayedThisSession);
        }

        #endregion
    }
}
