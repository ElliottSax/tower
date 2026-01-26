using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

namespace BlockBlastEvolved.UI
{
    /// <summary>
    /// Hero collection and management UI.
    /// Shows owned heroes, stats, upgrade options, and equip functionality.
    /// </summary>
    public class HeroCollectionUI : MonoBehaviour
    {
        [Header("Panels")]
        [Tooltip("Main collection panel")]
        public GameObject collectionPanel;

        [Tooltip("Hero detail panel (shown when hero selected)")]
        public GameObject detailPanel;

        [Header("Hero Grid")]
        [Tooltip("Container for hero cards")]
        public Transform heroGridContainer;

        [Tooltip("Hero card prefab")]
        public GameObject heroCardPrefab;

        [Header("Detail View")]
        [Tooltip("Selected hero portrait")]
        public Image heroPortrait;

        [Tooltip("Hero name text")]
        public TextMeshProUGUI heroNameText;

        [Tooltip("Hero description text")]
        public TextMeshProUGUI heroDescriptionText;

        [Tooltip("Hero level text")]
        public TextMeshProUGUI heroLevelText;

        [Tooltip("Hero rarity text")]
        public TextMeshProUGUI heroRarityText;

        [Header("Stats Display")]
        [Tooltip("Power stat text")]
        public TextMeshProUGUI powerText;

        [Tooltip("Line bonus text")]
        public TextMeshProUGUI lineBonusText;

        [Tooltip("Combo multiplier text")]
        public TextMeshProUGUI comboMultiplierText;

        [Header("Ability Display")]
        [Tooltip("Ability name text")]
        public TextMeshProUGUI abilityNameText;

        [Tooltip("Ability description text")]
        public TextMeshProUGUI abilityDescriptionText;

        [Tooltip("Ability cooldown text")]
        public TextMeshProUGUI abilityCooldownText;

        [Tooltip("Ability icon")]
        public Image abilityIcon;

        [Header("Upgrade Section")]
        [Tooltip("Upgrade button")]
        public Button upgradeButton;

        [Tooltip("Upgrade cost text")]
        public TextMeshProUGUI upgradeCostText;

        [Tooltip("Next level stats text")]
        public TextMeshProUGUI nextLevelStatsText;

        [Tooltip("Max level indicator")]
        public GameObject maxLevelIndicator;

        [Header("Actions")]
        [Tooltip("Equip button")]
        public Button equipButton;

        [Tooltip("Close button")]
        public Button closeButton;

        [Header("Unlock Section")]
        [Tooltip("Unlock button (for locked heroes)")]
        public Button unlockButton;

        [Tooltip("Unlock cost text")]
        public TextMeshProUGUI unlockCostText;

        [Tooltip("Locked overlay")]
        public GameObject lockedOverlay;

        [Header("Rarity Colors")]
        public Color commonColor = Color.gray;
        public Color rareColor = Color.blue;
        public Color epicColor = Color.magenta;
        public Color legendaryColor = Color.yellow;

        // Private fields
        private Hero selectedHero;
        private List<GameObject> heroCards = new List<GameObject>();

        #region Unity Lifecycle

        void Start()
        {
            // Hide initially
            if (collectionPanel != null)
            {
                collectionPanel.SetActive(false);
            }

            if (detailPanel != null)
            {
                detailPanel.SetActive(false);
            }

            // Setup buttons
            SetupButtons();
        }

        #endregion

        #region Setup

        /// <summary>
        /// Sets up button listeners
        /// </summary>
        void SetupButtons()
        {
            if (equipButton != null)
            {
                equipButton.onClick.AddListener(OnEquipButtonPressed);
            }

            if (upgradeButton != null)
            {
                upgradeButton.onClick.AddListener(OnUpgradeButtonPressed);
            }

            if (unlockButton != null)
            {
                unlockButton.onClick.AddListener(OnUnlockButtonPressed);
            }

            if (closeButton != null)
            {
                closeButton.onClick.AddListener(OnCloseButtonPressed);
            }
        }

        #endregion

        #region Show/Hide

        /// <summary>
        /// Shows collection UI
        /// </summary>
        public void Show()
        {
            if (collectionPanel != null)
            {
                collectionPanel.SetActive(true);
            }

            // Populate hero grid
            PopulateHeroGrid();
        }

        /// <summary>
        /// Hides collection UI
        /// </summary>
        public void Hide()
        {
            if (collectionPanel != null)
            {
                collectionPanel.SetActive(false);
            }

            if (detailPanel != null)
            {
                detailPanel.SetActive(false);
            }
        }

        #endregion

        #region Hero Grid

        /// <summary>
        /// Populates hero grid with all heroes
        /// </summary>
        void PopulateHeroGrid()
        {
            // Clear existing cards
            foreach (GameObject card in heroCards)
            {
                Destroy(card);
            }
            heroCards.Clear();

            if (HeroSystem.Instance == null || heroGridContainer == null || heroCardPrefab == null)
                return;

            // Get all heroes (both unlocked and locked)
            var allHeroes = HeroSystem.Instance.allHeroes;

            foreach (Hero hero in allHeroes)
            {
                GameObject card = Instantiate(heroCardPrefab, heroGridContainer);
                heroCards.Add(card);

                // Setup card
                SetupHeroCard(card, hero);
            }
        }

        /// <summary>
        /// Sets up a hero card
        /// </summary>
        void SetupHeroCard(GameObject card, Hero hero)
        {
            // Get card components
            Image portrait = card.transform.Find("Portrait")?.GetComponent<Image>();
            TextMeshProUGUI nameText = card.transform.Find("NameText")?.GetComponent<TextMeshProUGUI>();
            TextMeshProUGUI levelText = card.transform.Find("LevelText")?.GetComponent<TextMeshProUGUI>();
            Image rarityBorder = card.GetComponent<Image>();
            GameObject lockedIcon = card.transform.Find("LockedIcon")?.gameObject;

            // Set portrait
            if (portrait != null && hero.heroIcon != null)
            {
                portrait.sprite = hero.heroIcon;
            }

            // Set name
            if (nameText != null)
            {
                nameText.text = hero.heroName;
            }

            // Check if unlocked
            bool isUnlocked = HeroSystem.Instance.GetUnlockedHeroes().Contains(hero);

            if (isUnlocked)
            {
                // Show level
                if (levelText != null)
                {
                    int level = HeroSystem.Instance.GetHeroLevel(hero.heroId);
                    levelText.text = $"Lv.{level}";
                }

                // Hide locked icon
                if (lockedIcon != null)
                {
                    lockedIcon.SetActive(false);
                }

                // Normal colors
                if (portrait != null)
                {
                    Color color = portrait.color;
                    color.a = 1f;
                    portrait.color = color;
                }
            }
            else
            {
                // Hide level
                if (levelText != null)
                {
                    levelText.gameObject.SetActive(false);
                }

                // Show locked icon
                if (lockedIcon != null)
                {
                    lockedIcon.SetActive(true);
                }

                // Darken portrait
                if (portrait != null)
                {
                    Color color = portrait.color;
                    color.a = 0.5f;
                    portrait.color = color;
                }
            }

            // Set rarity border color
            if (rarityBorder != null)
            {
                rarityBorder.color = GetRarityColor(hero.rarity);
            }

            // Add click listener
            Button button = card.GetComponent<Button>();
            if (button == null)
            {
                button = card.AddComponent<Button>();
            }
            button.onClick.AddListener(() => OnHeroCardClicked(hero));
        }

        /// <summary>
        /// Gets color for rarity
        /// </summary>
        Color GetRarityColor(HeroRarity rarity)
        {
            switch (rarity)
            {
                case HeroRarity.Common: return commonColor;
                case HeroRarity.Rare: return rareColor;
                case HeroRarity.Epic: return epicColor;
                case HeroRarity.Legendary: return legendaryColor;
                default: return Color.white;
            }
        }

        #endregion

        #region Hero Detail

        /// <summary>
        /// Hero card clicked
        /// </summary>
        void OnHeroCardClicked(Hero hero)
        {
            selectedHero = hero;
            ShowHeroDetail(hero);

            // Play sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("ui_click");
            }
        }

        /// <summary>
        /// Shows hero detail panel
        /// </summary>
        void ShowHeroDetail(Hero hero)
        {
            if (detailPanel != null)
            {
                detailPanel.SetActive(true);
            }

            bool isUnlocked = HeroSystem.Instance.GetUnlockedHeroes().Contains(hero);

            // Show locked/unlocked content
            if (lockedOverlay != null)
            {
                lockedOverlay.SetActive(!isUnlocked);
            }

            // Basic info
            if (heroPortrait != null && hero.heroIcon != null)
            {
                heroPortrait.sprite = hero.heroIcon;
            }

            if (heroNameText != null)
            {
                heroNameText.text = hero.heroName;
            }

            if (heroDescriptionText != null)
            {
                heroDescriptionText.text = hero.heroDescription;
            }

            if (heroRarityText != null)
            {
                heroRarityText.text = hero.rarity.ToString();
                heroRarityText.color = GetRarityColor(hero.rarity);
            }

            if (isUnlocked)
            {
                ShowUnlockedHeroInfo(hero);
            }
            else
            {
                ShowLockedHeroInfo(hero);
            }
        }

        /// <summary>
        /// Shows info for unlocked hero
        /// </summary>
        void ShowUnlockedHeroInfo(Hero hero)
        {
            int level = HeroSystem.Instance.GetHeroLevel(hero.heroId);

            // Level
            if (heroLevelText != null)
            {
                heroLevelText.text = $"Level {level}";
            }

            // Stats (with level scaling)
            if (powerText != null)
            {
                float power = HeroSystem.Instance.GetHeroStat(hero, HeroStat.Power);
                powerText.text = $"Power: {power:F0}";
            }

            if (lineBonusText != null)
            {
                float bonus = HeroSystem.Instance.GetHeroStat(hero, HeroStat.LineBonus);
                lineBonusText.text = $"Line Bonus: x{bonus:F2}";
            }

            if (comboMultiplierText != null)
            {
                float combo = HeroSystem.Instance.GetHeroStat(hero, HeroStat.ComboMultiplier);
                comboMultiplierText.text = $"Combo: x{combo:F2}";
            }

            // Ability
            if (abilityNameText != null)
            {
                abilityNameText.text = hero.abilityName;
            }

            if (abilityDescriptionText != null)
            {
                abilityDescriptionText.text = hero.abilityDescription;
            }

            if (abilityCooldownText != null)
            {
                abilityCooldownText.text = $"Cooldown: {hero.abilityCooldown}s";
            }

            if (abilityIcon != null && hero.heroIcon != null)
            {
                abilityIcon.sprite = hero.heroIcon;
            }

            // Upgrade section
            bool isMaxLevel = level >= hero.maxLevel;

            if (upgradeButton != null)
            {
                upgradeButton.gameObject.SetActive(!isMaxLevel);
            }

            if (maxLevelIndicator != null)
            {
                maxLevelIndicator.SetActive(isMaxLevel);
            }

            if (!isMaxLevel && upgradeCostText != null)
            {
                int cost = hero.GetUpgradeCost(level);
                upgradeCostText.text = $"{cost} Coins";
            }

            // Equip button
            if (equipButton != null)
            {
                bool isEquipped = HeroSystem.Instance.activeHero == hero;
                equipButton.gameObject.SetActive(!isEquipped);

                var buttonText = equipButton.GetComponentInChildren<TextMeshProUGUI>();
                if (buttonText != null)
                {
                    buttonText.text = isEquipped ? "Equipped" : "Equip";
                }
            }

            // Hide unlock button
            if (unlockButton != null)
            {
                unlockButton.gameObject.SetActive(false);
            }
        }

        /// <summary>
        /// Shows info for locked hero
        /// </summary>
        void ShowLockedHeroInfo(Hero hero)
        {
            // Show unlock button
            if (unlockButton != null)
            {
                unlockButton.gameObject.SetActive(true);
            }

            if (unlockCostText != null)
            {
                string currency = hero.unlockCurrency == CurrencyType.Coins ? "Coins" : "Gems";
                unlockCostText.text = $"{hero.unlockCost} {currency}";
            }

            // Hide other buttons
            if (equipButton != null)
            {
                equipButton.gameObject.SetActive(false);
            }

            if (upgradeButton != null)
            {
                upgradeButton.gameObject.SetActive(false);
            }

            // Show base stats (level 1)
            if (powerText != null)
            {
                powerText.text = $"Power: {hero.basePower:F0}";
            }

            if (lineBonusText != null)
            {
                lineBonusText.text = $"Line Bonus: x{hero.lineBonus:F2}";
            }

            if (comboMultiplierText != null)
            {
                comboMultiplierText.text = $"Combo: x{hero.comboMultiplier:F2}";
            }
        }

        #endregion

        #region Button Handlers

        /// <summary>
        /// Equip button pressed
        /// </summary>
        void OnEquipButtonPressed()
        {
            if (selectedHero == null) return;

            bool success = HeroSystem.Instance.EquipHero(selectedHero.heroId);

            if (success)
            {
                // Update UI
                ShowHeroDetail(selectedHero);

                // Play sound
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX("ui_confirm");
                }

                Debug.Log($"Equipped hero: {selectedHero.heroName}");
            }
        }

        /// <summary>
        /// Upgrade button pressed
        /// </summary>
        void OnUpgradeButtonPressed()
        {
            if (selectedHero == null) return;

            bool success = HeroSystem.Instance.LevelUpHero(selectedHero.heroId);

            if (success)
            {
                // Update UI
                ShowHeroDetail(selectedHero);
                PopulateHeroGrid(); // Refresh grid to show new level

                // Play sound
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX(selectedHero.levelUpSoundName);
                }

                Debug.Log($"Upgraded hero: {selectedHero.heroName}");
            }
            else
            {
                // Show error (not enough coins, max level, etc.)
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX("error");
                }

                Debug.LogWarning("Cannot upgrade hero");
            }
        }

        /// <summary>
        /// Unlock button pressed
        /// </summary>
        void OnUnlockButtonPressed()
        {
            if (selectedHero == null) return;

            bool success = HeroSystem.Instance.UnlockHero(selectedHero.heroId);

            if (success)
            {
                // Update UI
                ShowHeroDetail(selectedHero);
                PopulateHeroGrid(); // Refresh grid

                // Play sound
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX(selectedHero.unlockSoundName);
                }

                // Play effect
                if (ParticleEffectManager.Instance != null)
                {
                    ParticleEffectManager.Instance.PlayEffect("hero_unlock", Vector3.zero);
                }

                Debug.Log($"Unlocked hero: {selectedHero.heroName}");
            }
            else
            {
                // Show error
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX("error");
                }

                Debug.LogWarning("Cannot unlock hero");
            }
        }

        /// <summary>
        /// Close button pressed
        /// </summary>
        void OnCloseButtonPressed()
        {
            Hide();
        }

        #endregion
    }
}
