using UnityEngine;
using System.Collections.Generic;
#if UNITY_REMOTE_CONFIG
using Unity.RemoteConfig;
using Unity.Services.Core;
using Unity.Services.Authentication;
#endif

namespace MobileGameCore
{
    /// <summary>
    /// Manages Unity Remote Config for live content updates and A/B testing.
    /// Enables changing game parameters without app updates.
    ///
    /// REVENUE IMPACT: Optimize monetization through live tuning
    ///
    /// USE CASES:
    /// - Adjust IAP prices based on A/B testing
    /// - Tune reward amounts (daily rewards, ad rewards)
    /// - Enable/disable features remotely
    /// - Seasonal events configuration
    /// - Difficulty balancing
    ///
    /// SETUP:
    /// 1. Install Unity Remote Config package (com.unity.remote-config)
    /// 2. Enable Remote Config in Services window
    /// 3. Create config in Unity Dashboard
    /// 4. Set environment ID in inspector
    ///
    /// USAGE:
    /// RemoteConfigManager.Instance.FetchConfig(() => {
    ///     int gemPrice = RemoteConfigManager.Instance.GetInt("gem_pack_100_price", 99);
    ///     float adReward = RemoteConfigManager.Instance.GetFloat("ad_reward_multiplier", 1.0f);
    ///     bool eventActive = RemoteConfigManager.Instance.GetBool("halloween_event_active", false);
    /// });
    /// </summary>
    public class RemoteConfigManager : MonoBehaviour
    {
        public static RemoteConfigManager Instance { get; private set; }

        [System.Serializable]
        public struct UserAttributes { }

        [System.Serializable]
        public struct AppAttributes { }

        [Header("Settings")]
        [SerializeField] private bool enableDebugLogs = true;
        [SerializeField] private bool autoFetchOnStart = true;

        private bool isInitialized = false;
        private bool isFetching = false;
        private Dictionary<string, object> configCache = new Dictionary<string, object>();

        // Default values for common configs
        private readonly Dictionary<string, object> defaultValues = new Dictionary<string, object>
        {
            // Monetization
            { "ad_reward_multiplier", 1.0f },
            { "daily_reward_multiplier", 1.0f },
            { "iap_discount_percentage", 0 },

            // Economy
            { "starting_coins", 100 },
            { "starting_gems", 10 },
            { "level_coin_reward", 50 },

            // Difficulty
            { "enemy_health_multiplier", 1.0f },
            { "player_damage_multiplier", 1.0f },

            // Features
            { "daily_challenges_enabled", true },
            { "leaderboard_enabled", true },
            { "social_features_enabled", true },

            // Events
            { "event_active", false },
            { "event_name", "none" },
            { "event_reward_multiplier", 1.0f }
        };

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
            if (autoFetchOnStart)
            {
                InitializeAndFetch();
            }
        }

        /// <summary>
        /// Initialize Unity Services and fetch remote config.
        /// </summary>
        public async void InitializeAndFetch(System.Action onComplete = null)
        {
#if UNITY_REMOTE_CONFIG
            try
            {
                LogDebug("Initializing Unity Services...");
                await UnityServices.InitializeAsync();

                // Anonymous authentication
                if (!AuthenticationService.Instance.IsSignedIn)
                {
                    await AuthenticationService.Instance.SignInAnonymouslyAsync();
                    LogDebug($"Signed in anonymously: {AuthenticationService.Instance.PlayerId}");
                }

                isInitialized = true;
                LogDebug("Unity Services initialized");

                // Fetch config
                FetchConfig(onComplete);
            }
            catch (System.Exception e)
            {
                Debug.LogError($"[RemoteConfigManager] Initialization failed: {e.Message}");
                onComplete?.Invoke();
            }
#else
            Debug.LogWarning("[RemoteConfigManager] Unity Remote Config package not installed");
            onComplete?.Invoke();
#endif
        }

        /// <summary>
        /// Fetch remote config from server.
        /// </summary>
        public void FetchConfig(System.Action onComplete = null)
        {
#if UNITY_REMOTE_CONFIG
            if (!isInitialized)
            {
                LogDebug("Remote Config not initialized. Call InitializeAndFetch() first.");
                onComplete?.Invoke();
                return;
            }

            if (isFetching)
            {
                LogDebug("Already fetching config...");
                return;
            }

            isFetching = true;
            LogDebug("Fetching remote config...");

            RemoteConfigService.Instance.FetchCompleted += (response) =>
            {
                isFetching = false;

                switch (response.status)
                {
                    case ConfigRequestStatus.Success:
                        LogDebug("Remote config fetched successfully");
                        CacheConfigValues();
                        TrackConfigFetch(true);
                        break;

                    case ConfigRequestStatus.Failed:
                        LogDebug($"Config fetch failed: {response.errorMessage}");
                        TrackConfigFetch(false);
                        break;
                }

                onComplete?.Invoke();
            };

            RemoteConfigService.Instance.FetchConfigsAsync(new UserAttributes(), new AppAttributes());
#else
            LogDebug("Remote Config not available, using defaults");
            onComplete?.Invoke();
#endif
        }

        private void CacheConfigValues()
        {
#if UNITY_REMOTE_CONFIG
            configCache.Clear();

            // Cache all keys from Remote Config
            var appConfig = RemoteConfigService.Instance.appConfig;
            foreach (var key in appConfig.GetKeys())
            {
                configCache[key] = appConfig.GetJson(key);
            }

            LogDebug($"Cached {configCache.Count} config values");
#endif
        }

        // GET VALUE METHODS

        /// <summary>
        /// Get int value from remote config.
        /// </summary>
        public int GetInt(string key, int defaultValue = 0)
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetInt(key, defaultValue);
            }
#endif
            return defaultValues.ContainsKey(key) ? (int)defaultValues[key] : defaultValue;
        }

        /// <summary>
        /// Get float value from remote config.
        /// </summary>
        public float GetFloat(string key, float defaultValue = 0f)
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetFloat(key, defaultValue);
            }
#endif
            return defaultValues.ContainsKey(key) ? (float)defaultValues[key] : defaultValue;
        }

        /// <summary>
        /// Get bool value from remote config.
        /// </summary>
        public bool GetBool(string key, bool defaultValue = false)
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetBool(key, defaultValue);
            }
#endif
            return defaultValues.ContainsKey(key) ? (bool)defaultValues[key] : defaultValue;
        }

        /// <summary>
        /// Get string value from remote config.
        /// </summary>
        public string GetString(string key, string defaultValue = "")
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetString(key, defaultValue);
            }
#endif
            return defaultValues.ContainsKey(key) ? (string)defaultValues[key] : defaultValue;
        }

        /// <summary>
        /// Get JSON value from remote config.
        /// </summary>
        public string GetJson(string key, string defaultValue = "{}")
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetJson(key);
            }
#endif
            return defaultValue;
        }

        /// <summary>
        /// Check if a key exists in remote config.
        /// </summary>
        public bool HasKey(string key)
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.HasKey(key);
            }
#endif
            return defaultValues.ContainsKey(key);
        }

        /// <summary>
        /// Get all config keys.
        /// </summary>
        public string[] GetKeys()
        {
#if UNITY_REMOTE_CONFIG
            if (isInitialized)
            {
                return RemoteConfigService.Instance.appConfig.GetKeys();
            }
#endif
            var keys = new string[defaultValues.Count];
            defaultValues.Keys.CopyTo(keys, 0);
            return keys;
        }

        // CONVENIENCE METHODS FOR COMMON CONFIGS

        /// <summary>
        /// Get ad reward multiplier (for tuning ad rewards).
        /// </summary>
        public float GetAdRewardMultiplier()
        {
            return GetFloat("ad_reward_multiplier", 1.0f);
        }

        /// <summary>
        /// Get daily reward multiplier (for events/promotions).
        /// </summary>
        public float GetDailyRewardMultiplier()
        {
            return GetFloat("daily_reward_multiplier", 1.0f);
        }

        /// <summary>
        /// Check if an event is active.
        /// </summary>
        public bool IsEventActive()
        {
            return GetBool("event_active", false);
        }

        /// <summary>
        /// Get current event name.
        /// </summary>
        public string GetEventName()
        {
            return GetString("event_name", "none");
        }

        /// <summary>
        /// Get event reward multiplier.
        /// </summary>
        public float GetEventRewardMultiplier()
        {
            return GetFloat("event_reward_multiplier", 1.0f);
        }

        /// <summary>
        /// Check if a feature is enabled remotely.
        /// </summary>
        public bool IsFeatureEnabled(string featureName)
        {
            return GetBool($"{featureName}_enabled", true);
        }

        private void TrackConfigFetch(bool success)
        {
            if (AnalyticsManager.Instance != null)
            {
                AnalyticsManager.Instance.LogEvent("remote_config_fetched", new Dictionary<string, object>
                {
                    { "success", success },
                    { "config_count", configCache.Count }
                });
            }
        }

        private void LogDebug(string message)
        {
            if (enableDebugLogs)
            {
                Debug.Log($"[RemoteConfigManager] {message}");
            }
        }

        // EDITOR TESTING
        void OnGUI()
        {
            if (!enableDebugLogs) return;

#if UNITY_EDITOR
            GUILayout.BeginArea(new Rect(10, 200, 300, 400));
            GUILayout.Label("Remote Config Debug");
            GUILayout.Label($"Initialized: {isInitialized}");
            GUILayout.Label($"Cached configs: {configCache.Count}");

            if (GUILayout.Button("Fetch Config Now"))
            {
                if (isInitialized)
                    FetchConfig();
                else
                    InitializeAndFetch();
            }

            GUILayout.Label("\nSample Values:");
            GUILayout.Label($"Ad Multiplier: {GetAdRewardMultiplier()}");
            GUILayout.Label($"Event Active: {IsEventActive()}");
            GUILayout.Label($"Event Name: {GetEventName()}");

            GUILayout.EndArea();
#endif
        }
    }
}
