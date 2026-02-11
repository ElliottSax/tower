using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// ScriptableObject for hero data.
    /// Create instances via: Assets → Create → Block Blast → Hero
    /// </summary>
    [CreateAssetMenu(fileName = "Hero_", menuName = "Block Blast/Hero", order = 1)]
    public class HeroData : ScriptableObject
    {
        [Header("Identity")]
        [Tooltip("Unique hero identifier (e.g., warrior_1)")]
        public string heroId = "warrior_1";

        [Tooltip("Display name")]
        public string heroName = "Knight";

        [Tooltip("Hero description")]
        [TextArea(2, 4)]
        public string heroDescription = "A brave warrior with mighty cleaving attacks";

        [Tooltip("Hero portrait icon")]
        public Sprite heroIcon;

        [Tooltip("Hero rarity tier")]
        public HeroRarity rarity = HeroRarity.Common;

        [Header("Stats")]
        [Tooltip("Base power multiplier (affects scoring)")]
        [Range(1f, 2f)]
        public float basePower = 1.0f;

        [Tooltip("Line clear bonus multiplier")]
        [Range(1f, 2f)]
        public float lineBonus = 1.1f;

        [Tooltip("Combo multiplier bonus")]
        [Range(1f, 3f)]
        public float comboMultiplier = 1.2f;

        [Header("Ability")]
        [Tooltip("Unique ability identifier")]
        public string abilityId = "slash";

        [Tooltip("Ability display name")]
        public string abilityName = "Mighty Slash";

        [Tooltip("Ability description")]
        [TextArea(2, 3)]
        public string abilityDescription = "Clears a random row";

        [Tooltip("Ability type")]
        public AbilityType abilityType = AbilityType.ClearRow;

        [Tooltip("Ability power (number of cells/rows/etc affected)")]
        [Range(1f, 30f)]
        public float abilityPower = 1f;

        [Tooltip("Ability cooldown in seconds")]
        [Range(10f, 120f)]
        public float abilityCooldown = 30f;

        [Tooltip("Ability duration for timed effects")]
        [Range(0f, 30f)]
        public float abilityDuration = 5f;

        [Header("Progression")]
        [Tooltip("Maximum hero level")]
        [Range(10, 100)]
        public int maxLevel = 50;

        [Tooltip("Base upgrade cost in coins")]
        [Range(100, 10000)]
        public int baseUpgradeCost = 100;

        [Header("Unlock Requirements")]
        [Tooltip("Gem cost to unlock (0 = starter hero)")]
        [Range(0, 2000)]
        public int unlockCost = 0;

        [Tooltip("Currency type for unlock")]
        public CurrencyType unlockCurrency = CurrencyType.Gems;

        [Tooltip("Is this hero unlocked by default?")]
        public bool starterHero = false;

        /// <summary>
        /// Calculate upgrade cost for given level
        /// </summary>
        public int GetUpgradeCost(int currentLevel)
        {
            return Mathf.RoundToInt(baseUpgradeCost * Mathf.Pow(currentLevel, 1.5f));
        }

        /// <summary>
        /// Get hero stat at given level with scaling
        /// </summary>
        public float GetStatAtLevel(HeroStat stat, int level)
        {
            float baseValue = 0f;

            switch (stat)
            {
                case HeroStat.Power:
                    baseValue = basePower;
                    break;
                case HeroStat.LineBonus:
                    baseValue = lineBonus;
                    break;
                case HeroStat.ComboMultiplier:
                    baseValue = comboMultiplier;
                    break;
                case HeroStat.AbilityPower:
                    baseValue = abilityPower;
                    break;
            }

            // Scale with level: +10% per level
            return baseValue * (1f + (level - 1) * 0.1f);
        }

        /// <summary>
        /// Validate hero data on inspector change
        /// </summary>
        private void OnValidate()
        {
            // Ensure heroId is lowercase with underscores
            if (!string.IsNullOrEmpty(heroId))
            {
                heroId = heroId.ToLower().Replace(" ", "_");
            }

            // Ensure abilityId matches heroId pattern
            if (!string.IsNullOrEmpty(abilityId))
            {
                abilityId = abilityId.ToLower().Replace(" ", "_");
            }

            // Auto-set unlock cost based on rarity if not manually set
            if (unlockCost == 0 && !starterHero)
            {
                switch (rarity)
                {
                    case HeroRarity.Common:
                        unlockCost = 100;
                        break;
                    case HeroRarity.Rare:
                        unlockCost = 250;
                        break;
                    case HeroRarity.Epic:
                        unlockCost = 500;
                        break;
                    case HeroRarity.Legendary:
                        unlockCost = 1000;
                        break;
                }
            }
        }
    }
}
