using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

namespace BlockBlastEvolved
{
    /// <summary>
    /// RPG hero system for Block Blast Evolved.
    /// Manages hero collection, abilities, stats, and progression.
    /// </summary>
    public class HeroSystem : MonoBehaviour
    {
        public static HeroSystem Instance { get; private set; }

        [Header("Hero Database")]
        [Tooltip("All available heroes")]
        public Hero[] allHeroes;

        [Header("Active Hero")]
        [Tooltip("Currently equipped hero")]
        public Hero activeHero;

        [Header("Events")]
        public UnityEvent<Hero> OnHeroEquipped;
        public UnityEvent<Hero> OnHeroLevelUp;
        public UnityEvent<Hero> OnHeroUnlocked;
        public UnityEvent<string> OnAbilityUsed;

        // Private fields
        private List<string> unlockedHeroIds;
        private Dictionary<string, int> heroLevels;
        private Dictionary<string, float> abilityC cooldowns;

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
                Debug.LogWarning("Multiple HeroSystem instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Initialize data
            unlockedHeroIds = new List<string>();
            heroLevels = new Dictionary<string, int>();
            abilityCooldowns = new Dictionary<string, float>();

            // Load player data
            LoadHeroData();

            // Unlock starter hero if first time
            if (unlockedHeroIds.Count == 0 && allHeroes.Length > 0)
            {
                UnlockHero(allHeroes[0].heroId);
                EquipHero(allHeroes[0].heroId);
            }

            Debug.Log($"HeroSystem: Initialized with {unlockedHeroIds.Count} unlocked heroes");
        }

        void Update()
        {
            // Update ability cooldowns
            UpdateCooldowns();
        }

        #endregion

        #region Hero Management

        /// <summary>
        /// Unlocks a hero for use
        /// </summary>
        public bool UnlockHero(string heroId)
        {
            if (unlockedHeroIds.Contains(heroId))
            {
                Debug.LogWarning($"Hero {heroId} already unlocked!");
                return false;
            }

            Hero hero = GetHeroById(heroId);
            if (hero == null)
            {
                Debug.LogError($"Hero {heroId} not found!");
                return false;
            }

            unlockedHeroIds.Add(heroId);
            heroLevels[heroId] = 1;

            OnHeroUnlocked?.Invoke(hero);

            Debug.Log($"🦸 Hero Unlocked: {hero.heroName}");

            SaveHeroData();
            return true;
        }

        /// <summary>
        /// Equips a hero as active
        /// </summary>
        public bool EquipHero(string heroId)
        {
            if (!unlockedHeroIds.Contains(heroId))
            {
                Debug.LogWarning($"Cannot equip locked hero {heroId}!");
                return false;
            }

            Hero hero = GetHeroById(heroId);
            if (hero == null)
            {
                Debug.LogError($"Hero {heroId} not found!");
                return false;
            }

            activeHero = hero;
            OnHeroEquipped?.Invoke(hero);

            Debug.Log($"⚔️ Hero Equipped: {hero.heroName}");

            SaveHeroData();
            return true;
        }

        /// <summary>
        /// Gets hero by ID
        /// </summary>
        Hero GetHeroById(string heroId)
        {
            foreach (Hero hero in allHeroes)
            {
                if (hero.heroId == heroId)
                {
                    return hero;
                }
            }
            return null;
        }

        /// <summary>
        /// Gets all unlocked heroes
        /// </summary>
        public List<Hero> GetUnlockedHeroes()
        {
            List<Hero> unlocked = new List<Hero>();

            foreach (string heroId in unlockedHeroIds)
            {
                Hero hero = GetHeroById(heroId);
                if (hero != null)
                {
                    unlocked.Add(hero);
                }
            }

            return unlocked;
        }

        #endregion

        #region Hero Progression

        /// <summary>
        /// Levels up a hero
        /// </summary>
        public bool LevelUpHero(string heroId)
        {
            if (!unlockedHeroIds.Contains(heroId))
            {
                Debug.LogWarning($"Cannot level up locked hero {heroId}!");
                return false;
            }

            Hero hero = GetHeroById(heroId);
            if (hero == null) return false;

            int currentLevel = GetHeroLevel(heroId);

            if (currentLevel >= hero.maxLevel)
            {
                Debug.LogWarning($"Hero {hero.heroName} is already max level!");
                return false;
            }

            // Check cost
            int upgradeCost = CalculateUpgradeCost(hero, currentLevel);
            var economyManager = FindObjectOfType<EconomyManager>();

            if (economyManager != null && economyManager.GetCoins() < upgradeCost)
            {
                Debug.LogWarning($"Not enough coins to upgrade {hero.heroName}!");
                return false;
            }

            // Deduct cost
            if (economyManager != null)
            {
                economyManager.SpendCoins(upgradeCost);
            }

            // Level up
            heroLevels[heroId] = currentLevel + 1;

            OnHeroLevelUp?.Invoke(hero);

            Debug.Log($"📈 {hero.heroName} leveled up to {heroLevels[heroId]}!");

            SaveHeroData();
            return true;
        }

        /// <summary>
        /// Gets hero level
        /// </summary>
        public int GetHeroLevel(string heroId)
        {
            if (heroLevels.ContainsKey(heroId))
            {
                return heroLevels[heroId];
            }
            return 1;
        }

        /// <summary>
        /// Calculates upgrade cost for hero
        /// </summary>
        int CalculateUpgradeCost(Hero hero, int currentLevel)
        {
            // Cost scales: base * level^1.5
            return Mathf.RoundToInt(hero.baseUpgradeCost * Mathf.Pow(currentLevel, 1.5f));
        }

        /// <summary>
        /// Gets hero stat with level scaling
        /// </summary>
        public float GetHeroStat(Hero hero, HeroStat stat)
        {
            if (hero == null) return 0f;

            int level = GetHeroLevel(hero.heroId);
            float baseValue = 0f;

            switch (stat)
            {
                case HeroStat.Power:
                    baseValue = hero.basePower;
                    break;
                case HeroStat.LineBonus:
                    baseValue = hero.lineBonus;
                    break;
                case HeroStat.ComboMultiplier:
                    baseValue = hero.comboMultiplier;
                    break;
                case HeroStat.AbilityPower:
                    baseValue = hero.abilityPower;
                    break;
            }

            // Scale with level: +10% per level
            return baseValue * (1f + (level - 1) * 0.1f);
        }

        #endregion

        #region Abilities

        /// <summary>
        /// Uses active hero's ability
        /// </summary>
        public bool UseAbility()
        {
            if (activeHero == null)
            {
                Debug.LogWarning("No active hero!");
                return false;
            }

            // Check cooldown
            if (IsAbilityOnCooldown(activeHero.abilityId))
            {
                float remainingCooldown = GetAbilityCooldown(activeHero.abilityId);
                Debug.LogWarning($"Ability on cooldown! {remainingCooldown:F1}s remaining");
                return false;
            }

            // Execute ability
            ExecuteAbility(activeHero);

            // Start cooldown
            StartAbilityCooldown(activeHero.abilityId, activeHero.abilityCooldown);

            OnAbilityUsed?.Invoke(activeHero.abilityId);

            Debug.Log($"⚡ Ability Used: {activeHero.abilityName}");

            return true;
        }

        /// <summary>
        /// Executes hero ability
        /// </summary>
        void ExecuteAbility(Hero hero)
        {
            switch (hero.abilityType)
            {
                case AbilityType.ClearRandomCells:
                    ClearRandomCells(hero);
                    break;

                case AbilityType.ClearRow:
                    ClearRandomRow();
                    break;

                case AbilityType.ClearColumn:
                    ClearRandomColumn();
                    break;

                case AbilityType.DoublePoints:
                    ActivateDoublePoints(hero.abilityDuration);
                    break;

                case AbilityType.ExtraBlock:
                    SpawnExtraBlock();
                    break;

                case AbilityType.Shuffle:
                    ShuffleGrid();
                    break;
            }

            // Visual/audio feedback
            ShowAbilityFeedback(hero);
        }

        /// <summary>
        /// Clears random cells (Mage ability)
        /// </summary>
        void ClearRandomCells(Hero hero)
        {
            if (GridSystem.Instance == null) return;

            int cellsToClear = Mathf.RoundToInt(hero.abilityPower);

            for (int i = 0; i < cellsToClear; i++)
            {
                int x = Random.Range(0, GridSystem.Instance.GridWidth);
                int y = Random.Range(0, GridSystem.Instance.GridHeight);

                var cell = GridSystem.Instance.GetCell(x, y);
                if (cell != null && !cell.isEmpty)
                {
                    // Clear cell
                    cell.isEmpty = true;
                    cell.blockType = BlockType.None;
                    // Update visual would go here
                }
            }

            Debug.Log($"💥 Cleared {cellsToClear} random cells!");
        }

        /// <summary>
        /// Clears random row (Warrior ability)
        /// </summary>
        void ClearRandomRow()
        {
            if (GridSystem.Instance == null) return;

            int row = Random.Range(0, GridSystem.Instance.GridHeight);
            // GridSystem would handle this
            Debug.Log($"⚔️ Cleared row {row}!");
        }

        /// <summary>
        /// Clears random column
        /// </summary>
        void ClearRandomColumn()
        {
            if (GridSystem.Instance == null) return;

            int column = Random.Range(0, GridSystem.Instance.GridWidth);
            Debug.Log($"🏹 Cleared column {column}!");
        }

        /// <summary>
        /// Activates double points multiplier
        /// </summary>
        void ActivateDoublePoints(float duration)
        {
            var scoreManager = FindObjectOfType<ScoreManager>();
            if (scoreManager != null)
            {
                // scoreManager.ActivateMultiplier(2f, duration);
            }
            Debug.Log($"💰 Double points for {duration}s!");
        }

        /// <summary>
        /// Spawns extra block
        /// </summary>
        void SpawnExtraBlock()
        {
            // BlockSpawner would handle this
            Debug.Log("🎁 Extra block spawned!");
        }

        /// <summary>
        /// Shuffles grid (reorganizes blocks)
        /// </summary>
        void ShuffleGrid()
        {
            // Would reorganize existing blocks on grid
            Debug.Log("🔀 Grid shuffled!");
        }

        /// <summary>
        /// Shows ability visual/audio feedback
        /// </summary>
        void ShowAbilityFeedback(Hero hero)
        {
            // Camera shake
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ShakeMedium();
            }

            // Play sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX($"ability_{hero.abilityType.ToString().ToLower()}");
            }

            // Particle effect
            if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("ability", Vector3.zero);
            }
        }

        #endregion

        #region Cooldown Management

        /// <summary>
        /// Starts ability cooldown
        /// </summary>
        void StartAbilityCooldown(string abilityId, float cooldownTime)
        {
            abilityCooldowns[abilityId] = cooldownTime;
        }

        /// <summary>
        /// Updates ability cooldowns
        /// </summary>
        void UpdateCooldowns()
        {
            List<string> keys = new List<string>(abilityCooldowns.Keys);

            foreach (string abilityId in keys)
            {
                if (abilityCooldowns[abilityId] > 0)
                {
                    abilityCooldowns[abilityId] -= Time.deltaTime;

                    if (abilityCooldowns[abilityId] <= 0)
                    {
                        abilityCooldowns[abilityId] = 0;
                    }
                }
            }
        }

        /// <summary>
        /// Checks if ability is on cooldown
        /// </summary>
        public bool IsAbilityOnCooldown(string abilityId)
        {
            if (abilityCooldowns.ContainsKey(abilityId))
            {
                return abilityCooldowns[abilityId] > 0;
            }
            return false;
        }

        /// <summary>
        /// Gets remaining cooldown time
        /// </summary>
        public float GetAbilityCooldown(string abilityId)
        {
            if (abilityCooldowns.ContainsKey(abilityId))
            {
                return abilityCooldowns[abilityId];
            }
            return 0f;
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Saves hero data
        /// </summary>
        void SaveHeroData()
        {
            var saveSystem = FindObjectOfType<SaveSystem>();
            if (saveSystem != null)
            {
                saveSystem.SetString("unlocked_heroes", string.Join(",", unlockedHeroIds));
                saveSystem.SetString("active_hero", activeHero?.heroId ?? "");

                // Save levels
                foreach (var kvp in heroLevels)
                {
                    saveSystem.SetInt($"hero_level_{kvp.Key}", kvp.Value);
                }

                saveSystem.Save();
            }
        }

        /// <summary>
        /// Loads hero data
        /// </summary>
        void LoadHeroData()
        {
            var saveSystem = FindObjectOfType<SaveSystem>();
            if (saveSystem != null)
            {
                string unlockedStr = saveSystem.GetString("unlocked_heroes", "");
                if (!string.IsNullOrEmpty(unlockedStr))
                {
                    unlockedHeroIds.AddRange(unlockedStr.Split(','));
                }

                string activeHeroId = saveSystem.GetString("active_hero", "");
                if (!string.IsNullOrEmpty(activeHeroId))
                {
                    activeHero = GetHeroById(activeHeroId);
                }

                // Load levels
                foreach (string heroId in unlockedHeroIds)
                {
                    heroLevels[heroId] = saveSystem.GetInt($"hero_level_{heroId}", 1);
                }
            }
        }

        #endregion
    }

    /// <summary>
    /// Hero definition
    /// </summary>
    [System.Serializable]
    public class Hero
    {
        [Header("Identity")]
        public string heroId = "warrior_1";
        public string heroName = "Knight";
        public string heroDescription = "A brave warrior";
        public Sprite heroIcon;
        public HeroRarity rarity = HeroRarity.Common;

        [Header("Stats")]
        public float basePower = 100f;
        public float lineBonus = 1.2f; // 20% bonus on line clears
        public float comboMultiplier = 1.5f;

        [Header("Ability")]
        public string abilityId = "slash";
        public string abilityName = "Mighty Slash";
        public string abilityDescription = "Clears a random row";
        public AbilityType abilityType = AbilityType.ClearRow;
        public float abilityPower = 1f;
        public float abilityCooldown = 30f;
        public float abilityDuration = 5f; // For timed abilities

        [Header("Progression")]
        public int maxLevel = 50;
        public int baseUpgradeCost = 100;

        [Header("Unlock Requirements")]
        public int unlockCost = 0; // 0 = starter hero
        public string unlockCurrency = "coins"; // "coins" or "gems"
    }

    /// <summary>
    /// Hero rarities
    /// </summary>
    public enum HeroRarity
    {
        Common,
        Rare,
        Epic,
        Legendary
    }

    /// <summary>
    /// Hero stats
    /// </summary>
    public enum HeroStat
    {
        Power,
        LineBonus,
        ComboMultiplier,
        AbilityPower
    }

    /// <summary>
    /// Ability types
    /// </summary>
    public enum AbilityType
    {
        ClearRandomCells,
        ClearRow,
        ClearColumn,
        DoublePoints,
        ExtraBlock,
        Shuffle
    }
}
