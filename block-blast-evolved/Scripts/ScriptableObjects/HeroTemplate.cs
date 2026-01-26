using UnityEngine;

namespace BlockBlastEvolved.ScriptableObjects
{
    /// <summary>
    /// ScriptableObject template for creating heroes.
    /// Defines hero stats, abilities, and progression.
    ///
    /// USAGE:
    /// 1. Right-click in Project window
    /// 2. Create > BlockBlastEvolved > Hero
    /// 3. Configure all settings
    /// 4. Add to HeroSystem's allHeroes array
    /// </summary>
    [CreateAssetMenu(fileName = "Hero_Knight", menuName = "BlockBlastEvolved/Hero", order = 1)]
    public class HeroTemplate : ScriptableObject
    {
        [Header("Identity")]
        [Tooltip("Unique hero identifier (e.g., warrior_1, mage_1)")]
        public string heroId = "knight_1";

        [Tooltip("Hero display name")]
        public string heroName = "Knight";

        [TextArea(2, 4)]
        [Tooltip("Hero description/lore")]
        public string heroDescription = "A brave knight who protects the realm with his mighty sword.";

        [Tooltip("Hero portrait/icon")]
        public Sprite heroIcon;

        [Tooltip("Hero rarity")]
        public HeroRarity rarity = HeroRarity.Common;

        [Header("Base Stats")]
        [Tooltip("Base power (affects scoring multiplier)")]
        [Range(50f, 200f)]
        public float basePower = 100f;

        [Tooltip("Line clear bonus multiplier (1.2 = 20% bonus)")]
        [Range(1f, 2f)]
        public float lineBonus = 1.2f;

        [Tooltip("Combo multiplier (1.5 = 50% more combo points)")]
        [Range(1f, 3f)]
        public float comboMultiplier = 1.5f;

        [Header("Ability")]
        [Tooltip("Ability identifier")]
        public string abilityId = "knight_slash";

        [Tooltip("Ability display name")]
        public string abilityName = "Mighty Slash";

        [TextArea(2, 3)]
        [Tooltip("Ability description")]
        public string abilityDescription = "Clears a random row on the grid.";

        [Tooltip("Ability type")]
        public AbilityType abilityType = AbilityType.ClearRow;

        [Tooltip("Ability power (cells cleared, multiplier strength, etc.)")]
        [Range(1f, 20f)]
        public float abilityPower = 1f;

        [Tooltip("Ability cooldown (seconds)")]
        [Range(10f, 120f)]
        public float abilityCooldown = 30f;

        [Tooltip("Ability duration (for timed effects like double points)")]
        [Range(0f, 30f)]
        public float abilityDuration = 5f;

        [Tooltip("Ability visual effect prefab")]
        public GameObject abilityEffectPrefab;

        [Header("Progression")]
        [Tooltip("Maximum level")]
        [Range(10, 100)]
        public int maxLevel = 50;

        [Tooltip("Base upgrade cost (scales with level)")]
        [Range(50, 1000)]
        public int baseUpgradeCost = 100;

        [Tooltip("Stat scaling per level (0.1 = +10% per level)")]
        [Range(0.05f, 0.2f)]
        public float statScalingPerLevel = 0.1f;

        [Header("Unlock Requirements")]
        [Tooltip("Cost to unlock hero (0 = starter hero)")]
        [Range(0, 10000)]
        public int unlockCost = 0;

        [Tooltip("Currency type for unlocking")]
        public CurrencyType unlockCurrency = CurrencyType.Coins;

        [Tooltip("Required player level to unlock (0 = always available)")]
        [Range(0, 100)]
        public int requiredPlayerLevel = 0;

        [Tooltip("Required achievement to unlock (empty = none)")]
        public string requiredAchievement = "";

        [Header("Visual Customization")]
        [Tooltip("Hero model/character prefab (3D)")]
        public GameObject heroModelPrefab;

        [Tooltip("UI theme colors for this hero")]
        public HeroThemeColors themeColors;

        [Header("Audio")]
        [Tooltip("Ability activation sound")]
        public string abilitySoundName = "ability_slash";

        [Tooltip("Level up sound")]
        public string levelUpSoundName = "hero_levelup";

        [Tooltip("Unlock sound")]
        public string unlockSoundName = "hero_unlock";

        #region Helper Methods

        /// <summary>
        /// Calculates stat value at specific level
        /// </summary>
        public float GetStatAtLevel(float baseStat, int level)
        {
            return baseStat * (1f + (level - 1) * statScalingPerLevel);
        }

        /// <summary>
        /// Calculates upgrade cost for level
        /// </summary>
        public int GetUpgradeCost(int currentLevel)
        {
            // Cost = base * level^1.5
            return Mathf.RoundToInt(baseUpgradeCost * Mathf.Pow(currentLevel, 1.5f));
        }

        /// <summary>
        /// Checks if hero can be unlocked
        /// </summary>
        public bool CanUnlock(int playerLevel, int playerCoins, int playerGems)
        {
            // Check player level
            if (playerLevel < requiredPlayerLevel)
                return false;

            // Check currency
            if (unlockCurrency == CurrencyType.Coins && playerCoins < unlockCost)
                return false;

            if (unlockCurrency == CurrencyType.Gems && playerGems < unlockCost)
                return false;

            // Check achievement (would need achievement system check)
            if (!string.IsNullOrEmpty(requiredAchievement))
            {
                // TODO: Check achievement system
            }

            return true;
        }

        /// <summary>
        /// Validates hero data (editor only)
        /// </summary>
        public bool IsValid()
        {
            if (string.IsNullOrEmpty(heroId)) return false;
            if (string.IsNullOrEmpty(heroName)) return false;
            if (heroIcon == null) return false;
            if (basePower <= 0) return false;
            if (abilityCooldown <= 0) return false;
            return true;
        }

        /// <summary>
        /// Returns debug string for hero
        /// </summary>
        public override string ToString()
        {
            return $"Hero: {heroName} ({rarity}) - Power: {basePower}, Ability: {abilityName}";
        }

        #endregion
    }

    /// <summary>
    /// Hero theme colors for UI
    /// </summary>
    [System.Serializable]
    public class HeroThemeColors
    {
        public Color primaryColor = Color.blue;
        public Color secondaryColor = Color.cyan;
        public Color accentColor = Color.yellow;
    }

    /// <summary>
    /// Currency types
    /// </summary>
    public enum CurrencyType
    {
        Coins,
        Gems,
        Both
    }
}

/*
 * EXAMPLE HERO CONFIGURATIONS:
 *
 * KNIGHT (Common - Starter):
 * - heroId: "knight_1"
 * - heroName: "Knight"
 * - rarity: Common
 * - basePower: 100
 * - lineBonus: 1.2 (20% bonus)
 * - comboMultiplier: 1.5
 * - abilityType: ClearRow
 * - abilityPower: 1 (clears 1 row)
 * - abilityCooldown: 30s
 * - unlockCost: 0 (starter)
 *
 * MAGE (Rare):
 * - heroId: "mage_1"
 * - heroName: "Wizard"
 * - rarity: Rare
 * - basePower: 110
 * - lineBonus: 1.3 (30% bonus)
 * - comboMultiplier: 1.8
 * - abilityType: ClearRandomCells
 * - abilityPower: 8 (clears 8 random cells)
 * - abilityCooldown: 35s
 * - unlockCost: 1000 (coins)
 * - requiredPlayerLevel: 5
 *
 * ARCHER (Rare):
 * - heroId: "archer_1"
 * - heroName: "Ranger"
 * - rarity: Rare
 * - basePower: 105
 * - lineBonus: 1.25 (25% bonus)
 * - comboMultiplier: 2.0 (double combo!)
 * - abilityType: ClearColumn
 * - abilityPower: 1 (clears 1 column)
 * - abilityCooldown: 32s
 * - unlockCost: 800 (coins)
 * - requiredPlayerLevel: 3
 *
 * MERCHANT (Epic):
 * - heroId: "merchant_1"
 * - heroName: "Coin Master"
 * - rarity: Epic
 * - basePower: 120
 * - lineBonus: 1.4 (40% bonus)
 * - comboMultiplier: 1.6
 * - abilityType: DoublePoints
 * - abilityPower: 2.0 (2x multiplier)
 * - abilityCooldown: 45s
 * - abilityDuration: 10s
 * - unlockCost: 500 (gems)
 * - requiredPlayerLevel: 10
 *
 * ENGINEER (Epic):
 * - heroId: "engineer_1"
 * - heroName: "Builder"
 * - rarity: Epic
 * - basePower: 115
 * - lineBonus: 1.35 (35% bonus)
 * - comboMultiplier: 1.7
 * - abilityType: ExtraBlock
 * - abilityPower: 1 (spawns 1 extra block)
 * - abilityCooldown: 40s
 * - unlockCost: 2500 (coins)
 * - requiredPlayerLevel: 15
 *
 * SORCERER (Legendary):
 * - heroId: "sorcerer_1"
 * - heroName: "Grand Mage"
 * - rarity: Legendary
 * - basePower: 150
 * - lineBonus: 1.6 (60% bonus!)
 * - comboMultiplier: 2.5 (huge combo bonus)
 * - abilityType: Shuffle
 * - abilityPower: 1 (reorganizes entire grid)
 * - abilityCooldown: 60s
 * - unlockCost: 1000 (gems)
 * - requiredPlayerLevel: 25
 * - requiredAchievement: "clear_1000_lines"
 *
 * PALADIN (Legendary):
 * - heroId: "paladin_1"
 * - heroName: "Holy Warrior"
 * - rarity: Legendary
 * - basePower: 160
 * - lineBonus: 1.7 (70% bonus!)
 * - comboMultiplier: 2.0
 * - abilityType: ClearRandomCells
 * - abilityPower: 15 (clears 15 cells!)
 * - abilityCooldown: 50s
 * - unlockCost: 1500 (gems)
 * - requiredPlayerLevel: 30
 *
 * NINJA (Epic - Special):
 * - heroId: "ninja_1"
 * - heroName: "Shadow"
 * - rarity: Epic
 * - basePower: 125
 * - lineBonus: 1.45 (45% bonus)
 * - comboMultiplier: 3.0 (triple combo!)
 * - abilityType: ClearRandomCells
 * - abilityPower: 10 (clears 10 cells)
 * - abilityCooldown: 38s
 * - unlockCost: 750 (gems)
 * - requiredPlayerLevel: 20
 */
