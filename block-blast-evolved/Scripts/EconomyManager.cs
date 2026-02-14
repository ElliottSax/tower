using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Manages in-game currencies (coins, gems).
    /// Stub implementation - extend with full economy system as needed.
    /// </summary>
    public class EconomyManager : MonoBehaviour
    {
        public static EconomyManager Instance { get; private set; }

        private int coins = 0;
        private int gems = 0;

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
            }
        }

        /// <summary>
        /// Gets current coin count.
        /// </summary>
        public int GetCoins()
        {
            return coins;
        }

        /// <summary>
        /// Gets current gem count.
        /// </summary>
        public int GetGems()
        {
            return gems;
        }

        /// <summary>
        /// Adds coins.
        /// </summary>
        public void AddCoins(int amount)
        {
            coins += amount;
            Debug.Log($"EconomyManager: +{amount} coins (total: {coins})");
        }

        /// <summary>
        /// Spends coins if sufficient balance.
        /// </summary>
        public bool SpendCoins(int amount)
        {
            if (coins >= amount)
            {
                coins -= amount;
                Debug.Log($"EconomyManager: -{amount} coins (total: {coins})");
                return true;
            }
            Debug.LogWarning($"EconomyManager: Not enough coins ({coins} < {amount})");
            return false;
        }

        /// <summary>
        /// Adds gems.
        /// </summary>
        public void AddGems(int amount)
        {
            gems += amount;
            Debug.Log($"EconomyManager: +{amount} gems (total: {gems})");
        }

        /// <summary>
        /// Spends gems if sufficient balance.
        /// </summary>
        public bool SpendGems(int amount)
        {
            if (gems >= amount)
            {
                gems -= amount;
                Debug.Log($"EconomyManager: -{amount} gems (total: {gems})");
                return true;
            }
            Debug.LogWarning($"EconomyManager: Not enough gems ({gems} < {amount})");
            return false;
        }
    }
}
