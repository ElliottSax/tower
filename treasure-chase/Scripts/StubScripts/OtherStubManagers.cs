using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Collection of stub managers for Day 1 setup.
/// Replace with real implementations from Treasure Multiplier later.
/// </summary>

// ============================================================
// PARTICLE EFFECT MANAGER
// ============================================================
public class ParticleEffectManager : MonoBehaviour
{
    public static ParticleEffectManager Instance { get; private set; }

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

    public void PlayEffect(string effectName, Vector3 position)
    {
        Debug.Log($"[STUB] ParticleEffectManager.PlayEffect: {effectName} at {position}");
    }

    public void SetAmbientParticles(GameObject particleSystem)
    {
        Debug.Log($"[STUB] ParticleEffectManager.SetAmbientParticles: {particleSystem?.name}");
    }
}

// ============================================================
// ECONOMY MANAGER
// ============================================================
public class EconomyManager : MonoBehaviour
{
    private int coins = 0;
    private int gems = 0;

    public void AddCoins(int amount)
    {
        coins += amount;
        Debug.Log($"[STUB] EconomyManager.AddCoins: +{amount} (Total: {coins})");
    }

    public void SpendCoins(int amount)
    {
        coins -= amount;
        Debug.Log($"[STUB] EconomyManager.SpendCoins: -{amount} (Total: {coins})");
    }

    public int GetCoins()
    {
        return coins;
    }

    public void AddGems(int amount)
    {
        gems += amount;
        Debug.Log($"[STUB] EconomyManager.AddGems: +{amount} (Total: {gems})");
    }

    public int GetGems()
    {
        return gems;
    }
}

// ============================================================
// GAME FEEL MANAGER
// ============================================================
public class GameFeelManager : MonoBehaviour
{
    public static GameFeelManager Instance { get; private set; }

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void HitFreeze(float duration)
    {
        Debug.Log($"[STUB] GameFeelManager.HitFreeze: {duration}s");
        // TODO: Implement time slowdown
    }
}

// ============================================================
// ACHIEVEMENT SYSTEM
// ============================================================
public class AchievementSystem : MonoBehaviour
{
    private HashSet<string> unlockedAchievements = new HashSet<string>();

    public void UnlockAchievement(string achievementId)
    {
        if (unlockedAchievements.Add(achievementId))
        {
            Debug.Log($"[STUB] AchievementSystem.UnlockAchievement: {achievementId} 🏆");
        }
    }

    public bool IsAchievementUnlocked(string achievementId)
    {
        return unlockedAchievements.Contains(achievementId);
    }
}

// ============================================================
// SAVE SYSTEM
// ============================================================
public class SaveSystem : MonoBehaviour
{
    private Dictionary<string, int> intData = new Dictionary<string, int>();
    private Dictionary<string, float> floatData = new Dictionary<string, float>();
    private Dictionary<string, string> stringData = new Dictionary<string, string>();

    public void SetInt(string key, int value)
    {
        intData[key] = value;
        PlayerPrefs.SetInt(key, value);
    }

    public int GetInt(string key, int defaultValue = 0)
    {
        if (intData.ContainsKey(key))
            return intData[key];
        return PlayerPrefs.GetInt(key, defaultValue);
    }

    public void SetFloat(string key, float value)
    {
        floatData[key] = value;
        PlayerPrefs.SetFloat(key, value);
    }

    public float GetFloat(string key, float defaultValue = 0f)
    {
        if (floatData.ContainsKey(key))
            return floatData[key];
        return PlayerPrefs.GetFloat(key, defaultValue);
    }

    public void SetString(string key, string value)
    {
        stringData[key] = value;
        PlayerPrefs.SetString(key, value);
    }

    public string GetString(string key, string defaultValue = "")
    {
        if (stringData.ContainsKey(key))
            return stringData[key];
        return PlayerPrefs.GetString(key, defaultValue);
    }

    public void Save()
    {
        PlayerPrefs.Save();
        Debug.Log("[STUB] SaveSystem.Save: Data saved to PlayerPrefs");
    }
}

// ============================================================
// ANALYTICS MANAGER
// ============================================================
public class AnalyticsManager : MonoBehaviour
{
    public void LogEvent(string eventName, Dictionary<string, object> parameters)
    {
        Debug.Log($"[STUB] AnalyticsManager.LogEvent: {eventName}");
        if (parameters != null)
        {
            foreach (var kvp in parameters)
            {
                Debug.Log($"  - {kvp.Key}: {kvp.Value}");
            }
        }
    }
}

// ============================================================
// HUD MANAGER
// ============================================================
public class HUDManager : MonoBehaviour
{
    public static HUDManager Instance { get; private set; }

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void FlashCoinCounter()
    {
        Debug.Log("[STUB] HUDManager.FlashCoinCounter");
    }

    public void ShowMultiplierBonus(int multiplier)
    {
        Debug.Log($"[STUB] HUDManager.ShowMultiplierBonus: x{multiplier}");
    }
}

// ============================================================
// ADS MANAGER
// ============================================================
public class AdsManager : MonoBehaviour
{
    public void ShowRewardedAd(System.Action<bool> onComplete)
    {
        Debug.Log("[STUB] AdsManager.ShowRewardedAd");
        // Simulate ad watch success
        if (onComplete != null)
        {
            onComplete(true);
        }
    }

    public void ShowInterstitial()
    {
        Debug.Log("[STUB] AdsManager.ShowInterstitial");
    }
}

// ============================================================
// PLAYER PROFILE
// ============================================================
public class PlayerProfile : MonoBehaviour
{
    public string PlayerName { get; set; } = "Player";
}

// ============================================================
// COLLECTIBLE (for treasures)
// ============================================================
public class Collectible : MonoBehaviour
{
    public UnityEngine.Events.UnityEvent OnCollected;

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            OnCollected?.Invoke();
            Debug.Log("[STUB] Collectible collected!");
            Destroy(gameObject);
        }
    }
}
