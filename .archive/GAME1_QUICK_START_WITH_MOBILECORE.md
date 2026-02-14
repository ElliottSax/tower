# 🎮 Game #1: Loot Stack Mayhem - Quick Start Guide

**Using MobileGameCore to build it FAST!**

**Timeline:** Week 1 Prototype (4-8 hours) → Week 2-3 Polish (10-15 hours) → Week 4 Launch!

---

## 🚀 Day 1: Foundation (2-3 hours)

### Step 1: Create New Unity Project (5 min)

```
1. Unity Hub → New Project
2. Template: 2D Core
3. Name: LootStackMayhem
4. Unity Version: 2022.3 LTS
5. Create Project
```

### Step 2: Import MobileGameCore (5 min)

```
1. Copy /mnt/e/projects/MobileGameCore to project folder
2. Window → Package Manager → + → Add package from disk
3. Select MobileGameCore/package.json
4. Wait for import (instant!)
```

### Step 3: Initial Setup (10 min)

**Scene Setup:**
```
1. File → New Scene → Save as "GameScene"
2. Delete default camera (we'll use EnhancedCameraController)
3. Create empty GameObjects:
   - CoreSystems (root for all managers)
   - GameplayObjects (root for game-specific stuff)
```

**Add Core Systems:**
```
Select CoreSystems GameObject, add components:
- SaveSystem
- AnalyticsManager
- EconomyManager
- AudioManager
- AchievementSystem
- DailyChallengeSystem
- GameFeelManager
- PerformanceProfiler (F1 to toggle)
```

**Create Camera:**
```
1. Create → Camera
2. Add EnhancedCameraController component
3. Settings:
   - Offset: (0, 5, -10)
   - Follow Speed: 3
   - Dynamic Zoom: Enabled
   - Min Zoom: 5, Max Zoom: 15
```

### Step 4: Create Game Manager (30 min)

**Create:** `Assets/Scripts/GameManager.cs`

```csharp
using UnityEngine;
using MobileGameCore;
using MobileGameCore.Effects;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [Header("Game State")]
    public bool isPlaying = false;
    public int currentScore = 0;
    public float stackHeight = 0f;
    public float multiplier = 1f;

    [Header("Settings")]
    public float maxMultiplier = 5f;
    public float multiplierIncrement = 0.1f;

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

    void Start()
    {
        // Initialize systems
        SaveSystem.Instance.Initialize();
        AnalyticsManager.Instance.Initialize();

        // Load saved high score
        int highScore = SaveSystem.Instance.GetInt("HighScore", 0);
        Debug.Log($"High Score: {highScore}");

        // Track game start
        AnalyticsManager.Instance.TrackLevelStart(1, "main_game");
    }

    public void StartGame()
    {
        isPlaying = true;
        currentScore = 0;
        stackHeight = 0f;
        multiplier = 1f;

        Debug.Log("Game Started!");
    }

    public void AddScore(int points)
    {
        int finalPoints = Mathf.RoundToInt(points * multiplier);
        currentScore += finalPoints;

        // Increase multiplier
        multiplier = Mathf.Min(multiplier + multiplierIncrement, maxMultiplier);

        Debug.Log($"Score: {currentScore} (x{multiplier:F1})");
    }

    public void GameOver()
    {
        isPlaying = false;

        // Check high score
        int highScore = SaveSystem.Instance.GetInt("HighScore", 0);
        if (currentScore > highScore)
        {
            SaveSystem.Instance.SaveInt("HighScore", currentScore);
            Debug.Log($"NEW HIGH SCORE: {currentScore}!");

            // Game feel!
            GameFeelManager.Instance.SuccessFeedback();
        }

        // Save game
        SaveSystem.Instance.SaveGame();

        // Track game over
        AnalyticsManager.Instance.TrackLevelComplete(1, 3, currentScore);

        Debug.Log($"Game Over! Score: {currentScore}, Height: {stackHeight:F1}m");
    }
}
```

---

## 🎮 Day 2: Treasure System (2-3 hours)

### Step 1: Create Treasure Prefab (30 min)

**Create:** `Assets/Scripts/Treasure.cs`

```csharp
using UnityEngine;
using MobileGameCore.ProceduralGeneration;
using MobileGameCore.Effects;

public class Treasure : MonoBehaviour
{
    public enum TreasureType
    {
        Coin,
        GoldBar,
        Gem,
        Diamond,
        Chest
    }

    [Header("Settings")]
    public TreasureType type;
    public int pointValue = 10;

    private Rigidbody2D rb;
    private ProceduralCollectable visual;
    private bool hasLanded = false;

    void Awake()
    {
        rb = gameObject.AddComponent<Rigidbody2D>();

        // Add procedural visual
        GameObject visualObj = new GameObject("Visual");
        visualObj.transform.SetParent(transform);
        visualObj.transform.localPosition = Vector3.zero;
        visual = visualObj.AddComponent<ProceduralCollectable>();

        SetupTreasure();
    }

    void SetupTreasure()
    {
        switch (type)
        {
            case TreasureType.Coin:
                rb.mass = 0.5f;
                visual.SetCollectableType(ProceduralCollectable.Shape.Coin, Color.yellow);
                pointValue = 10;
                break;

            case TreasureType.GoldBar:
                rb.mass = 1.5f;
                visual.SetCollectableType(ProceduralCollectable.Shape.Bar,
                    ProceduralCollectable.GetPresetColor(ProceduralCollectable.ColorPreset.Gold));
                pointValue = 20;
                break;

            case TreasureType.Gem:
                rb.mass = 0.8f;
                rb.sharedMaterial = new PhysicsMaterial2D { bounciness = 0.6f };
                visual.SetCollectableType(ProceduralCollectable.Shape.Gem,
                    ProceduralCollectable.GetPresetColor(ProceduralCollectable.ColorPreset.Ruby));
                pointValue = 30;
                break;

            case TreasureType.Diamond:
                rb.mass = 0.4f;
                visual.SetCollectableType(ProceduralCollectable.Shape.Diamond,
                    ProceduralCollectable.GetPresetColor(ProceduralCollectable.ColorPreset.Diamond));
                pointValue = 50;
                break;

            case TreasureType.Chest:
                rb.mass = 2f;
                visual.SetCollectableType(ProceduralCollectable.Shape.Chest, new Color(0.6f, 0.3f, 0.1f));
                pointValue = 40;
                break;
        }

        // Add collider
        CircleCollider2D collider = gameObject.AddComponent<CircleCollider2D>();
        collider.radius = 0.5f;
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (!hasLanded)
        {
            hasLanded = true;

            // Game feel!
            float intensity = rb.mass * 0.3f;
            GameFeelManager.Instance.Impact(intensity);

            // Particles!
            ProceduralParticles.CreateEffect(
                ProceduralParticles.EffectType.Sparkle,
                transform.position,
                visual.GetComponent<MeshRenderer>().material.color,
                0.5f
            );

            // Add score
            GameManager.Instance.AddScore(pointValue);

            // Update stack height
            if (transform.position.y > GameManager.Instance.stackHeight)
            {
                GameManager.Instance.stackHeight = transform.position.y;
            }
        }
    }
}
```

### Step 2: Create Treasure Spawner (30 min)

**Create:** `Assets/Scripts/TreasureSpawner.cs`

```csharp
using UnityEngine;

public class TreasureSpawner : MonoBehaviour
{
    [Header("Spawn Settings")]
    public float spawnHeight = 10f;
    public float spawnDelay = 1f;

    private float nextSpawnTime = 0f;
    private GameObject currentTreasure;

    void Update()
    {
        if (!GameManager.Instance.isPlaying)
            return;

        // Wait for current treasure to land
        if (currentTreasure != null)
            return;

        // Spawn treasure on timer
        if (Time.time >= nextSpawnTime)
        {
            SpawnRandomTreasure();
            nextSpawnTime = Time.time + spawnDelay;
        }

        // Drop treasure on tap
        if (Input.GetMouseButtonDown(0) && currentTreasure != null)
        {
            DropTreasure();
        }
    }

    void SpawnRandomTreasure()
    {
        // Create treasure at top of screen
        currentTreasure = new GameObject("Treasure");
        currentTreasure.transform.position = new Vector3(
            Random.Range(-3f, 3f), // Random X
            spawnHeight,
            0f
        );

        // Add treasure component
        Treasure treasure = currentTreasure.AddComponent<Treasure>();
        treasure.type = (Treasure.TreasureType)Random.Range(0, 5);

        // Disable physics until dropped
        Rigidbody2D rb = currentTreasure.GetComponent<Rigidbody2D>();
        rb.simulated = false;
    }

    void DropTreasure()
    {
        if (currentTreasure == null)
            return;

        // Enable physics
        Rigidbody2D rb = currentTreasure.GetComponent<Rigidbody2D>();
        rb.simulated = true;

        // Clear reference
        currentTreasure = null;
    }
}
```

---

## 🎨 Day 3: Polish & UI (2-3 hours)

### Step 1: Create Simple UI (1 hour)

**Create UI Canvas:**
```
1. Right-click Hierarchy → UI → Canvas
2. Canvas Scaler: Scale With Screen Size (1920x1080)
3. Create child UI elements:
```

**Create:** `Assets/Scripts/GameUI.cs`

```csharp
using UnityEngine;
using UnityEngine.UI;
using MobileGameCore;

public class GameUI : MonoBehaviour
{
    [Header("UI Elements")]
    public Text scoreText;
    public Text heightText;
    public Text multiplierText;
    public GameObject gameOverPanel;
    public Text finalScoreText;
    public Text highScoreText;

    void Update()
    {
        if (GameManager.Instance != null)
        {
            scoreText.text = $"Score: {GameManager.Instance.currentScore}";
            heightText.text = $"Height: {GameManager.Instance.stackHeight:F1}m";
            multiplierText.text = $"x{GameManager.Instance.multiplier:F1}";
        }
    }

    public void ShowGameOver()
    {
        gameOverPanel.SetActive(true);
        finalScoreText.text = $"Score: {GameManager.Instance.currentScore}";
        highScoreText.text = $"Best: {SaveSystem.Instance.GetInt("HighScore", 0)}";
    }

    public void OnPlayAgain()
    {
        gameOverPanel.SetActive(false);
        GameManager.Instance.StartGame();
    }
}
```

### Step 2: Add Achievements (30 min)

**In GameManager.Start():**
```csharp
void Start()
{
    // ... existing code ...

    // Register achievements
    AchievementSystem.Instance.RegisterAchievement(
        new Achievement("first_stack", "First Stack", "Stack 5 treasures", 50, 5, "stacking")
    );

    AchievementSystem.Instance.RegisterAchievement(
        new Achievement("tower_master", "Tower Master", "Reach 10m height", 100, 1, "height")
    );

    AchievementSystem.Instance.RegisterAchievement(
        new Achievement("multiplier_x5", "Multiplier Master", "Reach x5 multiplier", 150, 1, "multiplier")
    );

    // Subscribe to achievement unlocks
    AchievementSystem.Instance.OnAchievementUnlocked += (achievement) =>
    {
        Debug.Log($"🏆 Achievement Unlocked: {achievement.title}");
        GameFeelManager.Instance.SuccessFeedback();
    };
}
```

**Track progress in Treasure.OnCollisionEnter2D():**
```csharp
void OnCollisionEnter2D(Collision2D collision)
{
    // ... existing code ...

    // Track achievements
    AchievementSystem.Instance.AddProgress("first_stack", 1);

    if (GameManager.Instance.stackHeight >= 10f)
    {
        AchievementSystem.Instance.AddProgress("tower_master", 1);
    }

    if (GameManager.Instance.multiplier >= 5f)
    {
        AchievementSystem.Instance.AddProgress("multiplier_x5", 1);
    }
}
```

### Step 3: Add Daily Challenges (30 min)

**In GameManager.Start():**
```csharp
void Start()
{
    // ... existing code ...

    // Register daily challenges
    DailyChallengeSystem.Instance.RegisterChallenge(
        new DailyChallenge("stack_20", "Stack Master", "Stack 20 treasures", 20, 100)
    );

    DailyChallengeSystem.Instance.RegisterChallenge(
        new DailyChallenge("score_1000", "Score Hunter", "Score 1000 points", 1000, 150)
    );

    DailyChallengeSystem.Instance.RegisterChallenge(
        new DailyChallenge("reach_5m", "Height Challenge", "Reach 5m height", 1, 200)
    );
}
```

---

## 🚀 Day 4: Build & Test (1-2 hours)

### Step 1: Build for Mobile (30 min)

```
1. File → Build Settings
2. Platform: Android or iOS
3. Switch Platform
4. Player Settings:
   - Company Name: Your Studio
   - Product Name: Loot Stack Mayhem
   - Bundle ID: com.yourstudio.lootstackmayhem
   - Version: 0.1.0
5. Build and Run
```

### Step 2: Test on Device (30 min)

**Checklist:**
- [ ] Touch input works
- [ ] Treasures spawn and drop
- [ ] Physics feels good
- [ ] Score increases correctly
- [ ] High score saves
- [ ] Achievements unlock
- [ ] Performance is 60 FPS (press F1)
- [ ] No crashes

### Step 3: Iterate (1 hour)

**Common tweaks:**
- Adjust treasure mass values
- Fine-tune spawn delay
- Adjust camera zoom speed
- Balance score values
- Test different treasure distributions

---

## 📊 Week 2: Add Monetization

### Step 1: Unity Ads Setup

**Follow AdManager integration:**
```csharp
using MobileGameCore;

void Start()
{
    // Initialize ads
    AdManager.Instance.Initialize("your_game_id_here", testMode: true);
}

public void OnGameOver()
{
    // Show interstitial ad every 3rd game
    int gamesPlayed = SaveSystem.Instance.GetInt("GamesPlayed", 0);
    SaveSystem.Instance.SaveInt("GamesPlayed", gamesPlayed + 1);

    if (gamesPlayed % 3 == 0)
    {
        AdManager.Instance.ShowInterstitialAd();
    }
}

public void WatchAdToRevive()
{
    AdManager.Instance.ShowRewardedAd((success) =>
    {
        if (success)
        {
            // Give player one more chance!
            GameManager.Instance.StartGame();
            GameManager.Instance.multiplier = 2f; // Bonus multiplier
        }
    });
}
```

### Step 2: ATT Setup (iOS)

```csharp
#if UNITY_IOS
void Start()
{
    // Request tracking before showing ads
    ATTManager.Instance.RequestTracking((authorized) =>
    {
        Debug.Log($"ATT: {(authorized ? "Authorized" : "Denied")}");
        AdManager.Instance.Initialize("your_game_id_here", testMode: false);
    });
}
#endif
```

---

## 🎯 Week 3-4: Polish & Launch

### Polish Checklist
- [ ] Add juice to all actions (screen shake, particles)
- [ ] Create simple menu screen
- [ ] Add settings (volume, input mode)
- [ ] Implement tutorial (first 3 drops)
- [ ] Add sound effects (use AudioSynthesizer!)
- [ ] Create app icon
- [ ] Write App Store description
- [ ] Take screenshots
- [ ] Test on multiple devices

### Launch Checklist
- [ ] Remove test mode from AdManager
- [ ] Increment version number
- [ ] Build release APK/IPA
- [ ] Upload to stores
- [ ] Submit for review
- [ ] Monitor analytics
- [ ] Respond to early feedback

---

## 💡 Pro Tips

**Use MobileGameCore Features:**
1. **ProceduralParticles** for all VFX (sparkles, explosions)
2. **AudioSynthesizer** for quick sound effects
3. **GameFeelManager** for screen shake on every treasure drop
4. **PerformanceProfiler** (F1) to maintain 60 FPS
5. **SaveSystem** for high scores and progress
6. **AnalyticsManager** to track player behavior

**Quick Wins:**
- Start with 3 treasure types, add more later
- Use simple physics first, tune later
- Prototype in 2D, easier and faster
- Test on device early and often
- Use F1 profiler to catch performance issues

**Common Pitfalls:**
- Don't over-complicate physics
- Keep UI simple initially
- Test ads integration early (approval takes time)
- Make game fun BEFORE adding monetization

---

## 🎉 You're Ready!

**With MobileGameCore, you have:**
- ✅ Complete save/load system
- ✅ Analytics integration
- ✅ Ad monetization ready
- ✅ Procedural art system
- ✅ Achievement system
- ✅ Daily challenges
- ✅ Game feel systems
- ✅ Performance profiling

**Estimated Timeline:**
- Week 1: Prototype (follow Days 1-4 above)
- Week 2: Polish + Monetization
- Week 3: Testing + App Store prep
- Week 4: Launch!

**You can build this game in 4 weeks!** 🚀

Start with Day 1 and follow the guide. You'll have a playable prototype in 2-3 hours!

**Good luck!** 🎮
