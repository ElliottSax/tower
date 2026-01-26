using UnityEngine;
using System.Collections.Generic;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Manages world themes and visual progression in endless runner.
    /// Handles theme transitions based on distance milestones.
    /// </summary>
    public class WorldManager : MonoBehaviour
    {
        public static WorldManager Instance { get; private set; }

        [Header("Theme System")]
        [Tooltip("Array of world themes (Desert, Jungle, Snow, Lava, etc.)")]
        public WorldTheme[] worldThemes;

        [Tooltip("Distance between theme changes (meters)")]
        public float themeChangeDistance = 1000f;

        [Tooltip("Duration of theme transition (seconds)")]
        public float transitionDuration = 2f;

        [Header("Current Theme")]
        [Tooltip("Starting theme index")]
        public int startingThemeIndex = 0;

        // Private fields
        private int currentThemeIndex;
        private WorldTheme currentTheme;
        private bool isTransitioning = false;
        private float transitionProgress = 0f;

        // Public properties
        public WorldTheme CurrentTheme => currentTheme;
        public int CurrentThemeIndex => currentThemeIndex;

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
                Debug.LogWarning("Multiple WorldManager instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Validate themes
            if (worldThemes == null || worldThemes.Length == 0)
            {
                Debug.LogError("WorldManager: No themes assigned!");
                return;
            }

            // Set initial theme
            SetTheme(startingThemeIndex, immediate: true);

            // Subscribe to distance milestones
            if (DistanceTracker.Instance != null)
            {
                DistanceTracker.Instance.OnDistanceChanged.AddListener(CheckThemeTransition);
            }

            Debug.Log($"WorldManager: Initialized with {worldThemes.Length} themes");
        }

        void Update()
        {
            // Handle theme transition
            if (isTransitioning)
            {
                UpdateTransition();
            }
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (DistanceTracker.Instance != null)
            {
                DistanceTracker.Instance.OnDistanceChanged.RemoveListener(CheckThemeTransition);
            }
        }

        #endregion

        #region Theme Management

        /// <summary>
        /// Checks if theme should change based on distance
        /// </summary>
        void CheckThemeTransition(float distance)
        {
            if (isTransitioning) return;

            // Calculate which theme should be active
            int targetThemeIndex = Mathf.FloorToInt(distance / themeChangeDistance) % worldThemes.Length;

            if (targetThemeIndex != currentThemeIndex)
            {
                TransitionToTheme(targetThemeIndex);
            }
        }

        /// <summary>
        /// Sets the active theme
        /// </summary>
        public void SetTheme(int themeIndex, bool immediate = false)
        {
            if (themeIndex < 0 || themeIndex >= worldThemes.Length)
            {
                Debug.LogError($"WorldManager: Invalid theme index {themeIndex}");
                return;
            }

            currentThemeIndex = themeIndex;
            currentTheme = worldThemes[themeIndex];

            if (immediate)
            {
                ApplyTheme(currentTheme);
            }
            else
            {
                StartTransition(currentTheme);
            }

            Debug.Log($"🌍 Theme changed to: {currentTheme.themeName}");
        }

        /// <summary>
        /// Starts transition to new theme
        /// </summary>
        void TransitionToTheme(int themeIndex)
        {
            SetTheme(themeIndex, immediate: false);

            // Play transition effect
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ShakeMedium();
            }

            // Audio feedback
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("theme_transition");
            }
        }

        /// <summary>
        /// Starts theme transition animation
        /// </summary>
        void StartTransition(WorldTheme newTheme)
        {
            isTransitioning = true;
            transitionProgress = 0f;

            // Fade effect
            if (CameraController.Instance != null)
            {
                CameraController.Instance.FadeToBlack(transitionDuration * 0.5f);
            }

            // Notify terrain manager to switch obstacles
            if (InfiniteTerrainManager.Instance != null)
            {
                InfiniteTerrainManager.Instance.SetCurrentTheme(newTheme);
            }
        }

        /// <summary>
        /// Updates theme transition progress
        /// </summary>
        void UpdateTransition()
        {
            transitionProgress += Time.deltaTime / transitionDuration;

            if (transitionProgress >= 0.5f && transitionProgress < 0.55f)
            {
                // Apply theme at midpoint of transition
                ApplyTheme(currentTheme);
            }

            if (transitionProgress >= 1f)
            {
                // Transition complete
                isTransitioning = false;
                transitionProgress = 0f;

                // Fade back in
                if (CameraController.Instance != null)
                {
                    CameraController.Instance.FadeFromBlack(transitionDuration * 0.5f);
                }
            }
        }

        /// <summary>
        /// Applies theme settings to game
        /// </summary>
        void ApplyTheme(WorldTheme theme)
        {
            // Apply lighting
            if (theme.lightingPreset != null)
            {
                RenderSettings.skybox = theme.skyboxMaterial;
                RenderSettings.ambientLight = theme.ambientColor;
                RenderSettings.fogColor = theme.fogColor;
                RenderSettings.fogDensity = theme.fogDensity;
            }

            // Apply music
            if (AudioManager.Instance != null && !string.IsNullOrEmpty(theme.musicTrack))
            {
                AudioManager.Instance.PlayMusic(theme.musicTrack, fadeTime: 1f);
            }

            // Apply particle effects
            if (ParticleEffectManager.Instance != null && theme.ambientParticles != null)
            {
                ParticleEffectManager.Instance.SetAmbientParticles(theme.ambientParticles);
            }

            // Notify terrain manager
            if (InfiniteTerrainManager.Instance != null)
            {
                InfiniteTerrainManager.Instance.OnThemeChanged(theme);
            }
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Returns obstacle prefabs for current theme
        /// </summary>
        public GameObject[] GetCurrentThemeObstacles()
        {
            if (currentTheme != null && currentTheme.themeObstacles != null)
            {
                return currentTheme.themeObstacles;
            }
            return new GameObject[0];
        }

        /// <summary>
        /// Returns treasure prefabs for current theme
        /// </summary>
        public GameObject[] GetCurrentThemeTreasures()
        {
            if (currentTheme != null && currentTheme.themeTreasures != null)
            {
                return currentTheme.themeTreasures;
            }
            return new GameObject[0];
        }

        /// <summary>
        /// Returns terrain material for current theme
        /// </summary>
        public Material GetCurrentTerrainMaterial()
        {
            return currentTheme?.terrainMaterial;
        }

        /// <summary>
        /// Gets next theme in sequence
        /// </summary>
        public WorldTheme GetNextTheme()
        {
            int nextIndex = (currentThemeIndex + 1) % worldThemes.Length;
            return worldThemes[nextIndex];
        }

        #endregion

        #region Debug

        #if UNITY_EDITOR
        [ContextMenu("Next Theme")]
        void DebugNextTheme()
        {
            int nextIndex = (currentThemeIndex + 1) % worldThemes.Length;
            SetTheme(nextIndex, immediate: false);
        }

        [ContextMenu("Previous Theme")]
        void DebugPreviousTheme()
        {
            int prevIndex = (currentThemeIndex - 1 + worldThemes.Length) % worldThemes.Length;
            SetTheme(prevIndex, immediate: false);
        }
        #endif

        #endregion
    }

    /// <summary>
    /// ScriptableObject defining a world theme
    /// </summary>
    [CreateAssetMenu(fileName = "WorldTheme", menuName = "TreasureChase/World Theme")]
    public class WorldTheme : ScriptableObject
    {
        [Header("Theme Info")]
        public string themeName = "Desert";
        public string themeDescription = "Hot sandy desert with cacti";
        public Sprite themeIcon;

        [Header("Visual Settings")]
        public Material terrainMaterial;
        public Material skyboxMaterial;
        public Color ambientColor = Color.white;
        public Color fogColor = Color.gray;
        [Range(0f, 0.1f)]
        public float fogDensity = 0.01f;

        [Header("Lighting")]
        public LightingPreset lightingPreset;

        [Header("Audio")]
        public string musicTrack = "desert_theme";
        public string ambientSoundLoop = "desert_wind";

        [Header("Game Objects")]
        public GameObject[] themeObstacles;
        public GameObject[] themeTreasures;
        public GameObject[] themeDecorations;
        public GameObject ambientParticles; // Sand, snow, leaves, etc.

        [Header("Difficulty Modifiers")]
        [Tooltip("Speed multiplier for this theme (1.0 = normal)")]
        [Range(0.8f, 1.5f)]
        public float speedMultiplier = 1f;

        [Tooltip("Visibility modifier (0.5 = fog/sandstorm reduces visibility)")]
        [Range(0.5f, 1f)]
        public float visibilityModifier = 1f;
    }

    /// <summary>
    /// Lighting preset for themes
    /// </summary>
    [System.Serializable]
    public class LightingPreset
    {
        public Color sunColor = Color.white;
        public float sunIntensity = 1f;
        public Vector3 sunRotation = new Vector3(50, -30, 0);
    }
}
