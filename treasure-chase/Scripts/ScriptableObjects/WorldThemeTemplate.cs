using UnityEngine;

namespace TreasureChase.ScriptableObjects
{
    /// <summary>
    /// ScriptableObject template for creating world themes.
    /// Defines visual, audio, and gameplay settings for each theme.
    ///
    /// USAGE:
    /// 1. Right-click in Project window
    /// 2. Create > TreasureChase > World Theme
    /// 3. Configure all settings
    /// 4. Add to WorldManager's worldThemes array
    /// </summary>
    [CreateAssetMenu(fileName = "WorldTheme_Desert", menuName = "TreasureChase/World Theme", order = 1)]
    public class WorldThemeTemplate : ScriptableObject
    {
        [Header("Theme Identity")]
        [Tooltip("Theme name (e.g., Desert, Jungle, Snow)")]
        public string themeName = "Desert";

        [TextArea(2, 4)]
        [Tooltip("Theme description for UI")]
        public string themeDescription = "A scorching desert with ancient ruins and sandstorms";

        [Tooltip("Theme icon for UI")]
        public Sprite themeIcon;

        [Tooltip("Theme unlock distance (0 = available from start)")]
        public float unlockDistance = 0f;

        [Header("Visual Settings")]
        [Tooltip("Terrain material (ground texture)")]
        public Material terrainMaterial;

        [Tooltip("Skybox material")]
        public Material skyboxMaterial;

        [Tooltip("Ambient light color")]
        public Color ambientColor = new Color(1f, 0.95f, 0.8f); // Warm desert

        [Tooltip("Fog color")]
        public Color fogColor = new Color(0.8f, 0.7f, 0.5f); // Sandy fog

        [Tooltip("Fog density (0-0.1)")]
        [Range(0f, 0.1f)]
        public float fogDensity = 0.01f;

        [Header("Lighting")]
        [Tooltip("Directional light (sun) color")]
        public Color sunColor = new Color(1f, 0.95f, 0.8f);

        [Tooltip("Sun intensity (0-2)")]
        [Range(0f, 2f)]
        public float sunIntensity = 1.2f;

        [Tooltip("Sun rotation (X, Y, Z)")]
        public Vector3 sunRotation = new Vector3(50, -30, 0);

        [Header("Audio")]
        [Tooltip("Background music track name")]
        public string musicTrack = "desert_theme";

        [Tooltip("Ambient sound loop (wind, birds, etc.)")]
        public string ambientSoundLoop = "desert_wind";

        [Tooltip("Music volume (0-1)")]
        [Range(0f, 1f)]
        public float musicVolume = 0.7f;

        [Tooltip("Ambient sound volume (0-1)")]
        [Range(0f, 1f)]
        public float ambientVolume = 0.3f;

        [Header("Game Objects")]
        [Tooltip("Theme-specific obstacle prefabs")]
        public GameObject[] themeObstacles;

        [Tooltip("Theme-specific treasure prefabs")]
        public GameObject[] themeTreasures;

        [Tooltip("Decorative objects (cacti, rocks, trees, etc.)")]
        public GameObject[] themeDecorations;

        [Tooltip("Ambient particle system (sand, snow, leaves, etc.)")]
        public GameObject ambientParticles;

        [Header("Difficulty Modifiers")]
        [Tooltip("Speed multiplier (1.0 = normal, 1.2 = 20% faster)")]
        [Range(0.8f, 1.5f)]
        public float speedMultiplier = 1f;

        [Tooltip("Visibility modifier (0.5 = fog reduces visibility by 50%)")]
        [Range(0.5f, 1f)]
        public float visibilityModifier = 1f;

        [Tooltip("Obstacle spawn rate multiplier (1.2 = 20% more obstacles)")]
        [Range(0.8f, 1.5f)]
        public float obstacleSpawnMultiplier = 1f;

        [Header("Special Effects")]
        [Tooltip("Enable weather effects? (sandstorm, rain, snow)")]
        public bool enableWeatherEffects = false;

        [Tooltip("Weather effect prefab")]
        public GameObject weatherEffectPrefab;

        [Tooltip("Weather effect intensity (0-1)")]
        [Range(0f, 1f)]
        public float weatherIntensity = 0.5f;

        #region Helper Methods

        /// <summary>
        /// Validates theme data (editor only)
        /// </summary>
        public bool IsValid()
        {
            if (string.IsNullOrEmpty(themeName)) return false;
            if (terrainMaterial == null) return false;
            if (themeObstacles == null || themeObstacles.Length == 0) return false;
            return true;
        }

        /// <summary>
        /// Returns debug string for theme
        /// </summary>
        public override string ToString()
        {
            return $"WorldTheme: {themeName} (Speed: x{speedMultiplier}, Visibility: {visibilityModifier * 100}%)";
        }

        #endregion
    }
}

/*
 * EXAMPLE THEME CONFIGURATIONS:
 *
 * DESERT THEME:
 * - themeName: "Desert"
 * - ambientColor: RGB(255, 242, 204) - Warm yellow
 * - fogColor: RGB(204, 178, 128) - Sandy
 * - fogDensity: 0.015
 * - musicTrack: "desert_theme"
 * - ambientSoundLoop: "desert_wind"
 * - themeObstacles: [Cactus, Boulder, Scorpion]
 * - themeDecorations: [Sand dunes, Palm trees, Ruins]
 * - ambientParticles: Sand blowing
 * - speedMultiplier: 1.0
 * - visibilityModifier: 0.9 (slight sandstorm)
 *
 * JUNGLE THEME:
 * - themeName: "Jungle"
 * - ambientColor: RGB(180, 220, 180) - Green tint
 * - fogColor: RGB(150, 200, 150) - Humid green
 * - fogDensity: 0.02
 * - musicTrack: "jungle_theme"
 * - ambientSoundLoop: "jungle_birds"
 * - themeObstacles: [Vine, Fallen log, Snake]
 * - themeDecorations: [Thick trees, Ferns, Ruins]
 * - ambientParticles: Fireflies
 * - speedMultiplier: 0.9 (slightly slower)
 * - visibilityModifier: 0.8 (dense foliage)
 *
 * SNOW THEME:
 * - themeName: "Snow Mountains"
 * - ambientColor: RGB(230, 240, 255) - Cool blue
 * - fogColor: RGB(220, 230, 240) - White fog
 * - fogDensity: 0.01
 * - musicTrack: "snow_theme"
 * - ambientSoundLoop: "wind_howl"
 * - themeObstacles: [Ice spike, Snowman, Yeti]
 * - themeDecorations: [Pine trees, Ice crystals, Frozen rocks]
 * - ambientParticles: Falling snow
 * - speedMultiplier: 1.1 (icy, slippery)
 * - visibilityModifier: 0.7 (blizzard)
 * - enableWeatherEffects: true (snowstorm)
 *
 * LAVA THEME:
 * - themeName: "Volcanic Wasteland"
 * - ambientColor: RGB(255, 100, 50) - Hot orange/red
 * - fogColor: RGB(200, 50, 0) - Smoky red
 * - fogDensity: 0.025
 * - musicTrack: "lava_theme"
 * - ambientSoundLoop: "lava_bubbling"
 * - themeObstacles: [Lava geyser, Fire elemental, Volcanic rock]
 * - themeDecorations: [Lava pools, Steam vents, Burnt trees]
 * - ambientParticles: Ash and embers
 * - speedMultiplier: 1.2 (dangerous, fast)
 * - visibilityModifier: 0.6 (heavy smoke)
 * - enableWeatherEffects: true (ash storm)
 *
 * CITY THEME:
 * - themeName: "Urban Rush"
 * - ambientColor: RGB(200, 200, 220) - Cool gray
 * - fogColor: RGB(180, 180, 200) - Smog
 * - fogDensity: 0.008
 * - musicTrack: "city_theme"
 * - ambientSoundLoop: "city_traffic"
 * - themeObstacles: [Car, Barrier, Construction cone]
 * - themeDecorations: [Buildings, Street lights, Billboards]
 * - ambientParticles: None (or paper/leaves)
 * - speedMultiplier: 1.3 (fast-paced city)
 * - visibilityModifier: 1.0 (clear)
 *
 * SPACE THEME:
 * - themeName: "Cosmic Expanse"
 * - ambientColor: RGB(100, 100, 150) - Dark blue
 * - fogColor: RGB(50, 50, 100) - Space fog
 * - fogDensity: 0.005
 * - musicTrack: "space_theme"
 * - ambientSoundLoop: "space_ambient"
 * - themeObstacles: [Asteroid, Satellite, Space debris]
 * - themeDecorations: [Planets, Stars, Space station]
 * - ambientParticles: Stardust
 * - speedMultiplier: 1.5 (zero gravity speed)
 * - visibilityModifier: 1.0 (clear space)
 */
