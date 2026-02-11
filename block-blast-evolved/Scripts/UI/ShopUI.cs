using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using TMPro;
using BlockBlastEvolved.Monetization;

namespace BlockBlastEvolved.UI
{
    /// <summary>
    /// Shop UI for purchasing heroes and gem packs.
    /// Displays hero collection, gem shop, and IAP products.
    /// </summary>
    public class ShopUI : MonoBehaviour
    {
        [Header("Shop Panels")]
        [Tooltip("Hero shop panel")]
        public GameObject heroShopPanel;

        [Tooltip("Gem shop panel")]
        public GameObject gemShopPanel;

        [Header("Hero Shop")]
        [Tooltip("Container for hero purchase cards")]
        public Transform heroGridContainer;

        [Tooltip("Hero card prefab")]
        public GameObject heroCardPrefab;

        [Header("Gem Shop")]
        [Tooltip("Container for gem pack cards")]
        public Transform gemPackContainer;

        [Tooltip("Gem pack card prefab")]
        public GameObject gemPackCardPrefab;

        [Header("Currency Display")]
        [Tooltip("Coins text display")]
        public TextMeshProUGUI coinsText;

        [Tooltip("Gems text display")]
        public TextMeshProUGUI gemsText;

        [Header("Special Offers")]
        [Tooltip("Remove Ads button")]
        public Button removeAdsButton;

        [Tooltip("Remove Ads price text")]
        public TextMeshProUGUI removeAdsPriceText;

        [Tooltip("Starter Bundle button")]
        public Button starterBundleButton;

        [Tooltip("Starter Bundle price text")]
        public TextMeshProUGUI starterBundlePriceText;

        [Header("Tab Buttons")]
        public Button heroesTabButton;
        public Button gemsTabButton;

        // Current shop tab
        private ShopTab currentTab = ShopTab.Heroes;

        // Hero card cache
        private List<HeroCard> heroCards = new List<HeroCard>();

        #region Unity Lifecycle

        void Start()
        {
            // Setup tab buttons
            if (heroesTabButton != null)
                heroesTabButton.onClick.AddListener(() => SwitchTab(ShopTab.Heroes));

            if (gemsTabButton != null)
                gemsTabButton.onClick.AddListener(() => SwitchTab(ShopTab.Gems));

            // Setup special offer buttons
            if (removeAdsButton != null)
                removeAdsButton.onClick.AddListener(BuyRemoveAds);

            if (starterBundleButton != null)
                starterBundleButton.onClick.AddListener(BuyStarterBundle);

            // Subscribe to IAP events
            if (IAPManager.Instance != null)
            {
                IAPManager.Instance.OnPurchaseSuccess += OnPurchaseSuccess;
                IAPManager.Instance.OnStoreInitialized += UpdatePrices;
            }

            // Populate shop
            PopulateHeroShop();
            PopulateGemShop();

            // Update currency display
            UpdateCurrencyDisplay();

            // Update prices
            UpdatePrices();

            // Show default tab
            SwitchTab(ShopTab.Heroes);
        }

        void OnDestroy()
        {
            // Unsubscribe from events
            if (IAPManager.Instance != null)
            {
                IAPManager.Instance.OnPurchaseSuccess -= OnPurchaseSuccess;
                IAPManager.Instance.OnStoreInitialized -= UpdatePrices;
            }
        }

        void Update()
        {
            // Update currency display each frame
            UpdateCurrencyDisplay();
        }

        #endregion

        #region Shop Tabs

        /// <summary>
        /// Switch between shop tabs
        /// </summary>
        void SwitchTab(ShopTab tab)
        {
            currentTab = tab;

            // Show/hide panels
            if (heroShopPanel != null)
                heroShopPanel.SetActive(tab == ShopTab.Heroes);

            if (gemShopPanel != null)
                gemShopPanel.SetActive(tab == ShopTab.Gems);

            // Update tab button visuals
            UpdateTabButtons();
        }

        /// <summary>
        /// Update tab button visuals
        /// </summary>
        void UpdateTabButtons()
        {
            if (heroesTabButton != null)
            {
                var colors = heroesTabButton.colors;
                colors.normalColor = currentTab == ShopTab.Heroes ? new Color(1f, 0.8f, 0f) : Color.white;
                heroesTabButton.colors = colors;
            }

            if (gemsTabButton != null)
            {
                var colors = gemsTabButton.colors;
                colors.normalColor = currentTab == ShopTab.Gems ? new Color(1f, 0.8f, 0f) : Color.white;
                gemsTabButton.colors = colors;
            }
        }

        #endregion

        #region Hero Shop

        /// <summary>
        /// Populate hero shop with all available heroes
        /// </summary>
        void PopulateHeroShop()
        {
            if (heroGridContainer == null || heroCardPrefab == null) return;
            if (HeroSystem.Instance == null) return;

            // Clear existing cards
            foreach (Transform child in heroGridContainer)
            {
                Destroy(child.gameObject);
            }
            heroCards.Clear();

            // Create card for each hero
            foreach (var hero in HeroSystem.Instance.allHeroes)
            {
                GameObject cardObj = Instantiate(heroCardPrefab, heroGridContainer);
                HeroCard card = cardObj.GetComponent<HeroCard>();

                if (card != null)
                {
                    card.Initialize(hero);
                    heroCards.Add(card);
                }
            }
        }

        /// <summary>
        /// Purchase hero with gems
        /// </summary>
        public void PurchaseHero(string heroId, int gemCost)
        {
            var economyManager = EconomyManager.Instance;
            var heroSystem = HeroSystem.Instance;

            if (economyManager == null || heroSystem == null) return;

            // Check if already unlocked
            if (heroSystem.GetUnlockedHeroes().Exists(h => h.heroId == heroId))
            {
                Debug.LogWarning($"Hero {heroId} already unlocked!");
                return;
            }

            // Check gem balance
            if (economyManager.GetGems() < gemCost)
            {
                Debug.LogWarning($"Not enough gems! Need {gemCost}, have {economyManager.GetGems()}");
                ShowNotEnoughGemsPopup(gemCost);
                return;
            }

            // Spend gems
            if (economyManager.SpendGems(gemCost))
            {
                // Unlock hero
                heroSystem.UnlockHero(heroId);

                // Show success feedback
                ShowPurchaseSuccess($"Hero Unlocked!");

                // Play effects
                if (ParticleEffectManager.Instance != null)
                {
                    ParticleEffectManager.Instance.PlayEffect("hero_unlock", Vector3.zero);
                }

                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX("hero_unlock");
                }

                // Refresh shop display
                RefreshHeroCards();
            }
        }

        /// <summary>
        /// Refresh hero card display states
        /// </summary>
        void RefreshHeroCards()
        {
            foreach (var card in heroCards)
            {
                card.RefreshState();
            }
        }

        #endregion

        #region Gem Shop

        /// <summary>
        /// Populate gem shop with IAP products
        /// </summary>
        void PopulateGemShop()
        {
            if (gemPackContainer == null || gemPackCardPrefab == null) return;

            // Clear existing cards
            foreach (Transform child in gemPackContainer)
            {
                Destroy(child.gameObject);
            }

            // Create cards for each gem pack
            CreateGemPackCard(IAPManager.GEMS_100, 100, "Small Pack");
            CreateGemPackCard(IAPManager.GEMS_500, 550, "Medium Pack");
            CreateGemPackCard(IAPManager.GEMS_1200, 1320, "Large Pack");
            CreateGemPackCard(IAPManager.GEMS_3000, 3300, "Mega Pack");
            CreateGemPackCard(IAPManager.GEMS_10000, 11000, "Ultimate Pack");
        }

        /// <summary>
        /// Create gem pack card
        /// </summary>
        void CreateGemPackCard(string productId, int gemAmount, string packName)
        {
            GameObject cardObj = Instantiate(gemPackCardPrefab, gemPackContainer);
            GemPackCard card = cardObj.GetComponent<GemPackCard>();

            if (card != null)
            {
                card.Initialize(productId, gemAmount, packName);
            }
        }

        /// <summary>
        /// Purchase gem pack
        /// </summary>
        public void PurchaseGemPack(string productId)
        {
            if (IAPManager.Instance != null)
            {
                IAPManager.Instance.BuyProduct(productId);
            }
        }

        #endregion

        #region Special Offers

        /// <summary>
        /// Purchase Remove Ads
        /// </summary>
        void BuyRemoveAds()
        {
            if (IAPManager.Instance != null)
            {
                IAPManager.Instance.BuyProduct(IAPManager.REMOVE_ADS);
            }
        }

        /// <summary>
        /// Purchase Starter Bundle
        /// </summary>
        void BuyStarterBundle()
        {
            if (IAPManager.Instance != null)
            {
                IAPManager.Instance.BuyProduct(IAPManager.STARTER_BUNDLE);
            }
        }

        #endregion

        #region Currency Display

        /// <summary>
        /// Update currency text display
        /// </summary>
        void UpdateCurrencyDisplay()
        {
            var economyManager = EconomyManager.Instance;
            if (economyManager == null) return;

            if (coinsText != null)
                coinsText.text = economyManager.GetCoins().ToString();

            if (gemsText != null)
                gemsText.text = economyManager.GetGems().ToString();
        }

        #endregion

        #region Price Updates

        /// <summary>
        /// Update IAP product prices
        /// </summary>
        void UpdatePrices()
        {
            if (IAPManager.Instance == null) return;

            // Update Remove Ads price
            if (removeAdsPriceText != null)
            {
                string price = IAPManager.Instance.GetProductPrice(IAPManager.REMOVE_ADS);
                removeAdsPriceText.text = price;
            }

            // Update Starter Bundle price
            if (starterBundlePriceText != null)
            {
                string price = IAPManager.Instance.GetProductPrice(IAPManager.STARTER_BUNDLE);
                starterBundlePriceText.text = price;
            }

            // Hide Remove Ads button if already purchased
            if (removeAdsButton != null && IAPManager.Instance.HasRemovedAds())
            {
                removeAdsButton.gameObject.SetActive(false);
            }
        }

        #endregion

        #region Purchase Callbacks

        /// <summary>
        /// Called when purchase succeeds
        /// </summary>
        void OnPurchaseSuccess(string productId)
        {
            Debug.Log($"Purchase success: {productId}");

            // Refresh shop
            RefreshHeroCards();
            UpdatePrices();

            // Show success message
            ShowPurchaseSuccess("Purchase Complete!");
        }

        #endregion

        #region UI Feedback

        /// <summary>
        /// Show purchase success feedback
        /// </summary>
        void ShowPurchaseSuccess(string message)
        {
            Debug.Log($"[PURCHASE SUCCESS] {message}");
            // TODO: Show popup UI
        }

        /// <summary>
        /// Show not enough gems popup
        /// </summary>
        void ShowNotEnoughGemsPopup(int gemsNeeded)
        {
            Debug.Log($"[NOT ENOUGH GEMS] Need {gemsNeeded} gems");
            // TODO: Show popup with option to buy gems
        }

        #endregion

        #region Helper Classes

        /// <summary>
        /// Hero purchase card component
        /// </summary>
        public class HeroCard : MonoBehaviour
        {
            [Header("UI Elements")]
            public Image heroIcon;
            public TextMeshProUGUI heroNameText;
            public TextMeshProUGUI heroPriceText;
            public Button purchaseButton;
            public GameObject lockedOverlay;
            public GameObject unlockedIndicator;

            private Hero hero;

            public void Initialize(Hero hero)
            {
                this.hero = hero;

                // Set hero info
                if (heroNameText != null)
                    heroNameText.text = hero.heroName;

                if (heroIcon != null && hero.heroIcon != null)
                    heroIcon.sprite = hero.heroIcon;

                if (heroPriceText != null)
                    heroPriceText.text = $"{hero.unlockCost} Gems";

                // Setup button
                if (purchaseButton != null)
                {
                    purchaseButton.onClick.AddListener(OnPurchaseClicked);
                }

                // Refresh state
                RefreshState();
            }

            public void RefreshState()
            {
                if (hero == null) return;

                bool isUnlocked = HeroSystem.Instance != null &&
                                 HeroSystem.Instance.GetUnlockedHeroes().Exists(h => h.heroId == hero.heroId);

                // Update UI
                if (lockedOverlay != null)
                    lockedOverlay.SetActive(!isUnlocked);

                if (unlockedIndicator != null)
                    unlockedIndicator.SetActive(isUnlocked);

                if (purchaseButton != null)
                    purchaseButton.interactable = !isUnlocked;
            }

            void OnPurchaseClicked()
            {
                var shopUI = GetComponentInParent<ShopUI>();
                if (shopUI != null)
                {
                    shopUI.PurchaseHero(hero.heroId, hero.unlockCost);
                }
            }
        }

        /// <summary>
        /// Gem pack card component
        /// </summary>
        public class GemPackCard : MonoBehaviour
        {
            [Header("UI Elements")]
            public TextMeshProUGUI packNameText;
            public TextMeshProUGUI gemAmountText;
            public TextMeshProUGUI priceText;
            public Button purchaseButton;

            private string productId;

            public void Initialize(string productId, int gemAmount, string packName)
            {
                this.productId = productId;

                if (packNameText != null)
                    packNameText.text = packName;

                if (gemAmountText != null)
                    gemAmountText.text = $"{gemAmount} Gems";

                // Get price from IAP Manager
                if (priceText != null && IAPManager.Instance != null)
                {
                    priceText.text = IAPManager.Instance.GetProductPrice(productId);
                }

                if (purchaseButton != null)
                {
                    purchaseButton.onClick.AddListener(OnPurchaseClicked);
                }
            }

            void OnPurchaseClicked()
            {
                var shopUI = GetComponentInParent<ShopUI>();
                if (shopUI != null)
                {
                    shopUI.PurchaseGemPack(productId);
                }
            }
        }

        #endregion
    }

    public enum ShopTab
    {
        Heroes,
        Gems
    }
}
