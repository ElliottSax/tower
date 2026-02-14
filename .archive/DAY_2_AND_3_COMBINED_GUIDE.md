# 🚀 DAYS 2 & 3 COMBINED: COMPLETE GAME IN 2 DAYS

**Goal:** Transform your basic runner into a polished, fun, addictive game!

**Time Required:** 7-9 hours total (can split across 2 days)

**What You'll Build:**
- Complete UI system
- Game over and restart
- Collectible coins with effects
- Power-ups (Magnet, Shield)
- Jump mechanic
- Visual polish and juice

---

## 📋 COMBINED ROADMAP (7-9 HOURS)

```
Part 1: Core Systems (2 hours)
  ├─ Game state management
  ├─ Collision detection
  └─ Basic HUD

Part 2: Complete UI (1.5 hours)
  ├─ Full HUD (score, coins, multiplier)
  └─ Game over screen

Part 3: Collectibles (1.5 hours)
  ├─ Coin system
  └─ Coin spawning patterns

Part 4: Power-Ups (2 hours)
  ├─ Magnet power-up
  └─ Shield power-up

Part 5: Jump & Polish (2 hours)
  ├─ Jump mechanic
  └─ Visual effects (particles, shake, trails)
```

---

## ✅ PREREQUISITES CHECK

Before starting, verify:
- [ ] Day 1 complete (endless runner works)
- [ ] Player moves in lanes
- [ ] Terrain spawns infinitely
- [ ] Obstacles appear
- [ ] Unity project open and saved

**Ready? Let's build! 🎮**

---

# PART 1: CORE SYSTEMS (2 hours)

## STEP 1: Create GameStateManager (10 min)

**Create the script:**

1. Assets/Scripts/ → Right-click → Create → C# Script
2. Name: `GameStateManager`
3. Paste this code:

```csharp
using UnityEngine;
using UnityEngine.Events;

public class GameStateManager : MonoBehaviour
{
    public static GameStateManager Instance { get; private set; }

    [Header("Game State")]
    public bool isGameActive = true;
    public bool isGameOver = false;
    public bool isPaused = false;

    [Header("Events")]
    public UnityEvent OnGameStart;
    public UnityEvent OnGameOver;
    public UnityEvent OnGamePause;
    public UnityEvent OnGameResume;

    void Awake()
    {
        if (Instance == null)
            Instance = this;
        else
            Destroy(gameObject);
    }

    void Start()
    {
        StartGame();
    }

    public void StartGame()
    {
        isGameActive = true;
        isGameOver = false;
        isPaused = false;
        Time.timeScale = 1f;
        OnGameStart?.Invoke();
        Debug.Log("Game Started!");
    }

    public void GameOver()
    {
        if (isGameOver) return;
        isGameActive = false;
        isGameOver = true;
        Time.timeScale = 0f;
        OnGameOver?.Invoke();
        Debug.Log("Game Over!");
    }

    public void PauseGame()
    {
        if (!isGameActive || isGameOver) return;
        isPaused = true;
        Time.timeScale = 0f;
        OnGamePause?.Invoke();
    }

    public void ResumeGame()
    {
        if (!isPaused || isGameOver) return;
        isPaused = false;
        Time.timeScale = 1f;
        OnGameResume?.Invoke();
    }

    public void RestartGame()
    {
        Time.timeScale = 1f;
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex
        );
    }
}
```

**Add to scene:**
- Hierarchy → Create Empty → Name: `GameStateManager`
- Add Component → GameStateManager script

**Test:** Press Play, check Console for "Game Started!"

---

## STEP 2: Add Collision to PlayerController (15 min)

**Open PlayerController.cs and add:**

At the top with other variables:
```csharp
[Header("Collision")]
public LayerMask obstacleLayer;
public GameObject deathParticles;

[Header("Shield")]
public bool isShielded = false;
```

At the start of Update():
```csharp
void Update()
{
    // Stop input if game is over
    if (GameStateManager.Instance != null && !GameStateManager.Instance.isGameActive)
        return;

    // ... rest of your existing Update code ...
}
```

Add these new methods at the bottom:
```csharp
void OnTriggerEnter(Collider other)
{
    if (other.CompareTag("Obstacle"))
    {
        if (isShielded)
        {
            Destroy(other.gameObject);
            Debug.Log("Shield protected you!");
        }
        else
        {
            Die();
        }
    }
}

void Die()
{
    Debug.Log("Player Hit Obstacle!");

    if (deathParticles != null)
        Instantiate(deathParticles, transform.position, Quaternion.identity);

    if (GameStateManager.Instance != null)
        GameStateManager.Instance.GameOver();

    enabled = false;
}
```

**Tag your obstacles:**
1. Create tag: Inspector → Tags → Add Tag → "Obstacle"
2. Open Prefabs/Obstacles/Obstacle_Box
3. Set Tag: Obstacle
4. Verify "Is Trigger" is checked on collider

**Test:**
- Press Play
- Hit obstacle
- Console shows "Game Over!"
- Game freezes

---

## STEP 3: Create Complete HUD (25 min)

**Delete old UI:**
- Delete any old DistanceText from Canvas

**Create HUD structure:**

1. **HUD Panel:**
   - Canvas → UI → Panel (name: HUD_Panel)
   - Color: Transparent (Alpha = 0)

2. **Distance Display (Top-Left):**
   - HUD_Panel → UI → Image (name: DistanceBackground)
   - Anchor: Top-left
   - Position: X=150, Y=-50
   - Width: 200, Height: 60
   - Color: Black, Alpha: 180

   - DistanceBackground → UI → Text-TextMeshPro (name: DistanceText)
   - Font Size: 36
   - Alignment: Center + Middle
   - Color: White
   - Text: "0 m"

3. **Coin Display (Top-Left, next to distance):**
   - Duplicate DistanceBackground (Ctrl+D)
   - Name: CoinBackground
   - Position: X=400, Y=-50

   - Rename child text to: CoinText
   - Text: "💎 0"

4. **Score Display (Top-Center):**
   - HUD_Panel → UI → Text-TextMeshPro (name: ScoreText)
   - Anchor: Top-center
   - Position: Y=-100
   - Font Size: 48
   - Alignment: Center
   - Color: Yellow (#FFD700)
   - Text: "0"
   - Component: Add Outline (black, size 3)

5. **Multiplier Display (Below Score):**
   - HUD_Panel → UI → Text-TextMeshPro (name: MultiplierText)
   - Anchor: Top-center
   - Position: Y=-180
   - Font Size: 32
   - Color: Orange
   - Text: "x1.0"
   - Set Alpha: 0 (will fade in when active)

---

## STEP 4: Create HUD Controller (15 min)

**Create SimpleHUDController.cs:**

```csharp
using UnityEngine;
using TMPro;

public class SimpleHUDController : MonoBehaviour
{
    [Header("HUD References")]
    public TextMeshProUGUI distanceText;
    public TextMeshProUGUI scoreText;
    public TextMeshProUGUI coinText;
    public TextMeshProUGUI multiplierText;

    [Header("Score Settings")]
    public float pointsPerMeter = 10f;
    public float pointsPerCoin = 50f;

    private float currentDistance = 0f;
    private int currentScore = 0;
    private int currentCoins = 0;
    private float currentMultiplier = 1f;

    void Update()
    {
        UpdateFromManagers();
        UpdateUI();
    }

    void UpdateFromManagers()
    {
        if (DistanceTracker.Instance != null)
            currentDistance = DistanceTracker.Instance.currentDistance;

        if (EndlessScoreManager.Instance != null)
        {
            currentCoins = EndlessScoreManager.Instance.currentCoins;
            currentScore = EndlessScoreManager.Instance.currentScore;
            currentMultiplier = EndlessScoreManager.Instance.currentMultiplier;
        }
        else
        {
            currentScore = Mathf.FloorToInt(currentDistance * pointsPerMeter);
        }
    }

    void UpdateUI()
    {
        if (distanceText != null)
            distanceText.text = Mathf.Floor(currentDistance) + " m";

        if (scoreText != null)
            scoreText.text = currentScore.ToString();

        if (coinText != null)
            coinText.text = "💎 " + currentCoins.ToString();

        if (multiplierText != null)
        {
            if (currentMultiplier > 1f)
            {
                multiplierText.text = "x" + currentMultiplier.ToString("F1");
                Color c = multiplierText.color;
                c.a = Mathf.Lerp(c.a, 1f, Time.deltaTime * 5f);
                multiplierText.color = c;
            }
            else
            {
                Color c = multiplierText.color;
                c.a = Mathf.Lerp(c.a, 0f, Time.deltaTime * 5f);
                multiplierText.color = c;
            }
        }
    }

    public void AddCoins(int amount)
    {
        currentCoins += amount;
    }
}
```

**Assign to Canvas:**
- Select Canvas
- Add Component → SimpleHUDController
- Drag all 4 text objects to their fields:
  - DistanceText
  - ScoreText
  - CoinText
  - MultiplierText

**Test:**
- Press Play
- All counters visible
- Distance/score update as you run

---

## STEP 5: Create Game Over Screen (35 min)

**Create Game Over Panel:**

1. **Main Panel:**
   - Canvas → UI → Panel (name: GameOverPanel)
   - Color: Black, Alpha: 220
   - **IMPORTANT:** Set Active: FALSE (uncheck in Inspector)

2. **Title:**
   - GameOverPanel → UI → Text-TextMeshPro (name: GameOverTitle)
   - Text: "GAME OVER"
   - Font Size: 72
   - Position: Y=200
   - Color: Red
   - Alignment: Center
   - Add Outline: Black, size 5

3. **Stats:**

   **Final Score:**
   - GameOverPanel → UI → Text-TextMeshPro (name: FinalScoreText)
   - Text: "Score: 0"
   - Font Size: 48
   - Position: Y=80
   - Color: Yellow
   - Alignment: Center

   **Distance (duplicate FinalScoreText):**
   - Name: FinalDistanceText
   - Text: "Distance: 0 m"
   - Position: Y=20
   - Color: White

   **Coins (duplicate again):**
   - Name: FinalCoinsText
   - Text: "Coins: 0"
   - Position: Y=-40
   - Color: Cyan

   **Best Score (duplicate again):**
   - Name: BestScoreText
   - Text: "Best: 0"
   - Position: Y=-120
   - Font Size: 36
   - Color: Gold

4. **Restart Button:**
   - GameOverPanel → UI → Button-TextMeshPro (name: RestartButton)
   - Position: Y=-220
   - Width: 300, Height: 80
   - Button Color: Green

   - Update button's text child:
     - Text: "RESTART"
     - Font Size: 40
     - Color: White

---

## STEP 6: Game Over Controller (20 min)

**Create GameOverController.cs:**

```csharp
using UnityEngine;
using TMPro;
using UnityEngine.UI;

public class GameOverController : MonoBehaviour
{
    [Header("Game Over Panel")]
    public GameObject gameOverPanel;

    [Header("Stats Display")]
    public TextMeshProUGUI finalScoreText;
    public TextMeshProUGUI finalDistanceText;
    public TextMeshProUGUI finalCoinsText;
    public TextMeshProUGUI bestScoreText;

    [Header("Buttons")]
    public Button restartButton;

    private int finalScore = 0;
    private float finalDistance = 0f;
    private int finalCoins = 0;

    void Start()
    {
        if (gameOverPanel != null)
            gameOverPanel.SetActive(false);

        if (restartButton != null)
            restartButton.onClick.AddListener(OnRestartClicked);

        if (GameStateManager.Instance != null)
            GameStateManager.Instance.OnGameOver.AddListener(ShowGameOver);
    }

    void ShowGameOver()
    {
        GatherStats();
        CheckAndSaveBestScore();
        UpdateGameOverUI();

        if (gameOverPanel != null)
            gameOverPanel.SetActive(true);
    }

    void GatherStats()
    {
        if (DistanceTracker.Instance != null)
            finalDistance = DistanceTracker.Instance.currentDistance;

        if (EndlessScoreManager.Instance != null)
        {
            finalScore = EndlessScoreManager.Instance.currentScore;
            finalCoins = EndlessScoreManager.Instance.currentCoins;
        }
        else if (FindObjectOfType<SimpleHUDController>() != null)
        {
            finalScore = Mathf.FloorToInt(finalDistance * 10f);
        }
    }

    void CheckAndSaveBestScore()
    {
        int previousBest = PlayerPrefs.GetInt("BestScore", 0);
        if (finalScore > previousBest)
        {
            PlayerPrefs.SetInt("BestScore", finalScore);
            PlayerPrefs.Save();
            Debug.Log("New Best Score: " + finalScore);
        }
    }

    void UpdateGameOverUI()
    {
        if (finalScoreText != null)
            finalScoreText.text = "Score: " + finalScore.ToString();

        if (finalDistanceText != null)
            finalDistanceText.text = "Distance: " + Mathf.Floor(finalDistance) + " m";

        if (finalCoinsText != null)
            finalCoinsText.text = "Coins: " + finalCoins.ToString();

        if (bestScoreText != null)
        {
            int bestScore = PlayerPrefs.GetInt("BestScore", 0);
            bestScoreText.text = "Best: " + bestScore.ToString();
        }
    }

    void OnRestartClicked()
    {
        if (GameStateManager.Instance != null)
            GameStateManager.Instance.RestartGame();
    }

    void OnDestroy()
    {
        if (GameStateManager.Instance != null)
            GameStateManager.Instance.OnGameOver.RemoveListener(ShowGameOver);

        if (restartButton != null)
            restartButton.onClick.RemoveListener(OnRestartClicked);
    }
}
```

**Assign to Canvas:**
- Select Canvas
- Add Component → GameOverController
- Assign all fields:
  - GameOverPanel → drag from Canvas
  - All 4 text fields → drag from GameOverPanel
  - RestartButton → drag from GameOverPanel

**Test complete flow:**
- Press Play
- Run into obstacle
- Game Over panel appears
- Click Restart
- Game reloads

---

# 🎉 CHECKPOINT 1: COMPLETE GAME LOOP (2 hours done)

**You now have:**
- ✅ Complete HUD
- ✅ Game over system
- ✅ Restart functionality
- ✅ Best score saving

**Take a 5-10 minute break! 🎮**

---

# PART 3: COLLECTIBLES (1.5 hours)

## STEP 7: Create Coin Prefab (15 min)

**Create coin object:**
1. Hierarchy → 3D Object → Sphere (name: Coin)
2. Scale: 0.5, 0.5, 0.5
3. Position: 0, 1, 10 (temporarily)

**Make it gold:**
1. Create material: Assets/Materials/Mat_Coin
2. Color: Gold (#FFD700)
3. Metallic: 0.8, Smoothness: 0.9
4. Assign to Coin

**Add spinning script - CoinBehavior.cs:**

```csharp
using UnityEngine;

public class CoinBehavior : MonoBehaviour
{
    [Header("Rotation")]
    public float rotationSpeed = 180f;
    public Vector3 rotationAxis = Vector3.up;

    [Header("Bobbing")]
    public bool enableBobbing = true;
    public float bobbingSpeed = 2f;
    public float bobbingAmount = 0.3f;

    [Header("Value")]
    public int coinValue = 10;

    [Header("Effects")]
    public GameObject collectionEffectPrefab;

    private Vector3 startPosition;
    private float timeOffset;

    void Start()
    {
        startPosition = transform.position;
        timeOffset = Random.Range(0f, 100f);
    }

    void Update()
    {
        transform.Rotate(rotationAxis * rotationSpeed * Time.deltaTime);

        if (enableBobbing)
        {
            float newY = startPosition.y + Mathf.Sin((Time.time + timeOffset) * bobbingSpeed) * bobbingAmount;
            transform.position = new Vector3(transform.position.x, newY, transform.position.z);
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            Collect();
        }
    }

    void Collect()
    {
        // Add coins
        if (EndlessScoreManager.Instance != null)
            EndlessScoreManager.Instance.AddCoins(coinValue);
        else if (FindObjectOfType<SimpleHUDController>() != null)
            FindObjectOfType<SimpleHUDController>().AddCoins(coinValue);

        // Spawn effect
        if (collectionEffectPrefab != null)
            Instantiate(collectionEffectPrefab, transform.position, Quaternion.identity);

        Debug.Log("Coin collected! +" + coinValue);
        Destroy(gameObject);
    }
}
```

**Configure coin:**
- Add CoinBehavior script to Coin
- Coin Value: 10
- Already has Sphere Collider:
  - Check "Is Trigger" ✓
  - Radius: 0.6

**Create tag:**
- Inspector → Tag → Add Tag → "Coin"
- Set Coin's tag: Coin

**Save as prefab:**
- Create folder: Assets/Prefabs/Collectibles/
- Drag Coin → Prefabs/Collectibles/
- Delete Coin from scene

---

## STEP 8: Coin Spawner System (25 min)

**Create CoinSpawner.cs:**

```csharp
using UnityEngine;

public class CoinSpawner : MonoBehaviour
{
    [Header("Coin Settings")]
    public GameObject coinPrefab;
    public int coinsPerChunk = 5;
    public float coinHeight = 1f;

    [Header("Lane Positions")]
    public float[] lanePositions = { -3f, 0f, 3f };

    [Header("Patterns")]
    public bool usePatterns = true;

    public void SpawnCoinsForChunk(GameObject chunk, float chunkStartZ, float chunkLength)
    {
        if (coinPrefab == null) return;

        if (usePatterns)
            SpawnCoinPattern(chunk.transform, chunkStartZ, chunkLength);
        else
            SpawnRandomCoins(chunk.transform, chunkStartZ, chunkLength);
    }

    void SpawnRandomCoins(Transform parent, float startZ, float length)
    {
        for (int i = 0; i < coinsPerChunk; i++)
        {
            int randomLane = Random.Range(0, lanePositions.Length);
            float x = lanePositions[randomLane];
            float z = startZ + Random.Range(5f, length - 5f);
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }

    void SpawnCoinPattern(Transform parent, float startZ, float length)
    {
        int pattern = Random.Range(0, 4);

        switch (pattern)
        {
            case 0: SpawnSingleLane(parent, startZ, length); break;
            case 1: SpawnZigzag(parent, startZ, length); break;
            case 2: SpawnHorizontalLine(parent, startZ + length * 0.5f); break;
            case 3: SpawnRandomCoins(parent, startZ, length); break;
        }
    }

    void SpawnSingleLane(Transform parent, float startZ, float length)
    {
        int lane = Random.Range(0, lanePositions.Length);
        float x = lanePositions[lane];

        for (int i = 0; i < 5; i++)
        {
            float z = startZ + (length / 6f) * (i + 1);
            Instantiate(coinPrefab, new Vector3(x, coinHeight, z), Quaternion.identity, parent);
        }
    }

    void SpawnZigzag(Transform parent, float startZ, float length)
    {
        int currentLane = 1;

        for (int i = 0; i < 5; i++)
        {
            float x = lanePositions[currentLane];
            float z = startZ + (length / 6f) * (i + 1);
            Instantiate(coinPrefab, new Vector3(x, coinHeight, z), Quaternion.identity, parent);
            currentLane = (currentLane == 0) ? 2 : (currentLane == 2) ? 0 : Random.Range(0, 2) * 2;
        }
    }

    void SpawnHorizontalLine(Transform parent, float z)
    {
        foreach (float x in lanePositions)
        {
            Instantiate(coinPrefab, new Vector3(x, coinHeight, z), Quaternion.identity, parent);
        }
    }
}
```

**Add to scene:**
- Hierarchy → Create Empty (name: CoinSpawner)
- Add Component → CoinSpawner
- Assign Coin prefab

**Integrate with terrain:**
- Open InfiniteTerrainManager.cs
- Add at top with other variables:

```csharp
[Header("Collectibles")]
public CoinSpawner coinSpawner;
```

- Find your SpawnChunk() method
- After creating the chunk, add:

```csharp
// Spawn coins for this chunk
if (coinSpawner != null)
{
    coinSpawner.SpawnCoinsForChunk(newChunk, nextChunkZ, chunkLength);
}
```

**Assign CoinSpawner:**
- Select InfiniteTerrainManager in scene
- Drag CoinSpawner object to "Coin Spawner" field

**Test:**
- Press Play
- Coins spawn in patterns
- Collect coins
- Counter updates

---

# PART 4: POWER-UPS (2 hours)

## STEP 9: Power-Up Base Class (20 min)

**Create PowerUpBase.cs:**

```csharp
using UnityEngine;

public enum PowerUpType
{
    Magnet,
    Shield,
    SpeedBoost,
    DoubleCoins
}

public abstract class PowerUpBase : MonoBehaviour
{
    [Header("Power-Up Settings")]
    public PowerUpType powerUpType;
    public float duration = 10f;

    [Header("Visual")]
    public float rotationSpeed = 90f;

    protected bool isActive = false;
    protected float remainingTime = 0f;
    protected GameObject player;

    void Update()
    {
        transform.Rotate(Vector3.up * rotationSpeed * Time.deltaTime);

        if (isActive)
        {
            remainingTime -= Time.deltaTime;
            if (remainingTime <= 0f)
                DeactivatePowerUp();
            else
                UpdatePowerUp();
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player") && !isActive)
        {
            player = other.gameObject;
            ActivatePowerUp();
        }
    }

    public void ActivatePowerUp()
    {
        isActive = true;
        remainingTime = duration;
        GetComponent<MeshRenderer>().enabled = false;
        GetComponent<Collider>().enabled = false;
        OnActivate();
        Debug.Log(powerUpType + " activated for " + duration + " seconds!");
    }

    public void DeactivatePowerUp()
    {
        isActive = false;
        OnDeactivate();
        Debug.Log(powerUpType + " deactivated!");
        Destroy(gameObject);
    }

    protected abstract void OnActivate();
    protected abstract void OnDeactivate();
    protected virtual void UpdatePowerUp() { }
}
```

---

## STEP 10: Magnet Power-Up (20 min)

**Create MagnetPowerUp.cs:**

```csharp
using UnityEngine;

public class MagnetPowerUp : PowerUpBase
{
    [Header("Magnet Settings")]
    public float magnetRadius = 10f;
    public float magnetStrength = 15f;

    private SphereCollider magnetCollider;

    protected override void OnActivate()
    {
        if (player != null)
        {
            magnetCollider = player.AddComponent<SphereCollider>();
            magnetCollider.isTrigger = true;
            magnetCollider.radius = magnetRadius;
        }
    }

    protected override void UpdatePowerUp()
    {
        Collider[] nearbyColliders = Physics.OverlapSphere(player.transform.position, magnetRadius);

        foreach (Collider col in nearbyColliders)
        {
            if (col.CompareTag("Coin"))
            {
                Vector3 direction = (player.transform.position - col.transform.position).normalized;
                col.transform.position += direction * magnetStrength * Time.deltaTime;
            }
        }
    }

    protected override void OnDeactivate()
    {
        if (magnetCollider != null)
            Destroy(magnetCollider);
    }
}
```

**Create Magnet prefab:**
1. 3D Object → Cylinder (name: PowerUp_Magnet)
2. Scale: 0.5, 1, 0.5
3. Material: Mat_Magnet (Blue, Metallic: 0.5, Emission: Blue)
4. Add MagnetPowerUp script
5. Duration: 10
6. Magnet Radius: 10
7. Magnet Strength: 15
8. Add Capsule Collider (Is Trigger ✓)
9. Save to Prefabs/PowerUps/PowerUp_Magnet
10. Delete from scene

---

## STEP 11: Shield Power-Up (25 min)

**Create ShieldPowerUp.cs:**

```csharp
using UnityEngine;

public class ShieldPowerUp : PowerUpBase
{
    private GameObject shieldVisual;
    private PlayerController playerController;

    protected override void OnActivate()
    {
        if (player != null)
        {
            playerController = player.GetComponent<PlayerController>();
            if (playerController != null)
                playerController.isShielded = true;

            CreateDefaultShield();
        }
    }

    void CreateDefaultShield()
    {
        GameObject shield = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        shield.transform.SetParent(player.transform);
        shield.transform.localPosition = Vector3.zero;
        shield.transform.localScale = Vector3.one * 2.5f;

        Destroy(shield.GetComponent<Collider>());

        Renderer renderer = shield.GetComponent<Renderer>();
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0, 0.5f, 1f, 0.3f);
        mat.SetFloat("_Mode", 3);
        mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        mat.SetInt("_ZWrite", 0);
        mat.DisableKeyword("_ALPHATEST_ON");
        mat.EnableKeyword("_ALPHABLEND_ON");
        mat.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        mat.renderQueue = 3000;
        renderer.material = mat;

        shieldVisual = shield;
    }

    protected override void OnDeactivate()
    {
        if (playerController != null)
            playerController.isShielded = false;

        if (shieldVisual != null)
            Destroy(shieldVisual);
    }
}
```

**Create Shield prefab:**
1. 3D Object → Capsule (name: PowerUp_Shield)
2. Scale: 0.5, 1, 0.5
3. Material: Mat_Shield (Cyan, Emission: Cyan)
4. Add ShieldPowerUp script
5. Duration: 15
6. Add Capsule Collider (Is Trigger ✓)
7. Save to Prefabs/PowerUps/PowerUp_Shield
8. Delete from scene

---

## STEP 12: Spawn Power-Ups (15 min)

**Update InfiniteTerrainManager.cs:**

Add with other variables:
```csharp
[Header("Power-Ups")]
public GameObject[] powerUpPrefabs;
public float powerUpSpawnChance = 0.15f;
```

Add this method:
```csharp
void SpawnPowerUp(GameObject chunk, float startZ, float length)
{
    if (powerUpPrefabs.Length == 0) return;

    GameObject powerUpPrefab = powerUpPrefabs[Random.Range(0, powerUpPrefabs.Length)];
    float x = lanePositions[Random.Range(0, lanePositions.Length)];
    float z = startZ + (length * 0.5f);
    float y = 1.5f;

    Instantiate(powerUpPrefab, new Vector3(x, y, z), Quaternion.identity, chunk.transform);
}
```

In SpawnChunk(), after coin spawning:
```csharp
// Spawn power-up
if (powerUpPrefabs.Length > 0 && Random.value < powerUpSpawnChance)
{
    SpawnPowerUp(newChunk, nextChunkZ, chunkLength);
}
```

**Assign power-ups:**
- Select InfiniteTerrainManager
- Power Up Prefabs: Size 2
- Element 0: PowerUp_Magnet
- Element 1: PowerUp_Shield
- Power Up Spawn Chance: 0.15

**Test power-ups:**
- Magnet pulls coins
- Shield protects from obstacles

---

# PART 5: JUMP & POLISH (2 hours)

## STEP 13: Add Jump Mechanic (30 min)

**Update PlayerController.cs:**

Add variables:
```csharp
[Header("Jump Settings")]
public float jumpForce = 8f;
public LayerMask groundLayer;
public Transform groundCheck;
public float groundCheckRadius = 0.2f;

private Rigidbody rb;
private bool isGrounded = false;
```

Add to Start():
```csharp
void Start()
{
    rb = GetComponent<Rigidbody>();

    if (groundCheck == null)
    {
        GameObject groundCheckObj = new GameObject("GroundCheck");
        groundCheckObj.transform.SetParent(transform);
        groundCheckObj.transform.localPosition = new Vector3(0, -0.5f, 0);
        groundCheck = groundCheckObj.transform;
    }
}
```

In Update(), before lane switching:
```csharp
// Check if grounded
isGrounded = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);

// Jump
if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
{
    Jump();
}
```

Add Jump method:
```csharp
void Jump()
{
    if (rb != null)
    {
        rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
        rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
        Debug.Log("Jump!");
    }
}
```

**Setup ground layer:**
1. Create Layer: "Ground"
2. Select all terrain/ground objects → Layer: Ground
3. Player → PlayerController → Ground Layer: Ground

**Configure Rigidbody:**
- Player → Rigidbody:
  - Use Gravity: ✓
  - Is Kinematic: ✗
  - Constraints: Freeze Rotation X, Y, Z

**Test:** Space bar jumps!

---

## STEP 14: Visual Effects (45 min)

**A) Coin Collection Particles (15 min):**

1. Effects → Particle System (name: CoinCollectEffect)
2. Configure:
   - Duration: 0.5, Looping: OFF
   - Start Lifetime: 0.3
   - Start Speed: 3
   - Start Size: 0.15
   - Start Color: Yellow → Transparent (gradient)
   - Emission: 20 burst
   - Shape: Sphere, Radius: 0.5
3. Set inactive
4. Save: Prefabs/Effects/CoinCollectEffect
5. Assign to Coin prefab's "Collection Effect Prefab" field

**B) Screen Shake (15 min):**

Create CameraShake.cs:
```csharp
using UnityEngine;

public class CameraShake : MonoBehaviour
{
    public static CameraShake Instance { get; private set; }

    public float shakeDuration = 0.3f;
    public float shakeMagnitude = 0.2f;

    private Vector3 initialPosition;
    private float currentShakeDuration = 0f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    void Start()
    {
        initialPosition = transform.localPosition;
    }

    void Update()
    {
        if (currentShakeDuration > 0)
        {
            transform.localPosition = initialPosition + Random.insideUnitSphere * shakeMagnitude;
            currentShakeDuration -= Time.deltaTime;
        }
        else
        {
            currentShakeDuration = 0f;
            transform.localPosition = initialPosition;
        }
    }

    public void TriggerShake(float duration, float magnitude)
    {
        shakeDuration = duration;
        shakeMagnitude = magnitude;
        currentShakeDuration = duration;
    }
}
```

- Add to Main Camera
- In PlayerController Die() method:

```csharp
if (CameraShake.Instance != null)
    CameraShake.Instance.TriggerShake(0.5f, 0.3f);
```

**C) Player Trail (5 min):**

- Select Player
- Add Component → Trail Renderer
- Time: 0.3
- Width: 0.3 → 0 (curve)
- Color: White → Transparent
- Material: Default-Particle

**D) Death Particles (10 min):**

1. Effects → Particle System (name: DeathExplosion)
2. Configure:
   - Duration: 1, Looping: OFF
   - Start Speed: 5
   - Start Size: 0.2
   - Start Color: Red
   - Emission: 50 burst
   - Shape: Sphere
3. Set inactive
4. Save: Prefabs/Effects/DeathExplosion
5. Assign to Player → Death Particles field

**Test all effects!**

---

## STEP 15: Final Testing (30 min)

**Complete Gameplay Test:**

- [ ] Start game
- [ ] HUD shows all counters
- [ ] Collect coins → particles + counter update
- [ ] Collect Magnet → pulls coins
- [ ] Collect Shield → protects from obstacles
- [ ] Jump over low obstacles (if created)
- [ ] Hit obstacle → screen shake + death particles
- [ ] Game Over panel shows stats
- [ ] Best score saves
- [ ] Restart works
- [ ] All systems reset properly

**Adjust values for balance:**
- Coin spawn rate
- Power-up spawn rate
- Power-up durations
- Jump force
- Player speed

---

# 🎉 DAYS 2 & 3 COMPLETE!

## What You Built:

✅ **Game Systems:**
- State management
- Collision detection
- Restart functionality

✅ **UI:**
- Complete HUD (4 displays)
- Game over screen
- Button interactions

✅ **Collectibles:**
- Spinning coins
- Pattern spawning
- Collection effects

✅ **Power-Ups:**
- Magnet system
- Shield protection
- Reusable framework

✅ **Mechanics:**
- Jump with ground detection
- Physics-based movement

✅ **Polish:**
- Particle effects (3 types)
- Screen shake
- Trail renderer
- Visual feedback

---

## 📊 YOUR PROGRESS

```
[████████████░░░░░░░░] 60% Complete

✅ Day 1: Basic runner
✅ Day 2: UI + Game over
✅ Day 3: Collectibles + Power-ups
⏳ Day 4-5: Full integration
⏳ Day 6-7: Themes + polish
⏳ Week 8: Launch! 🚀
```

---

## 💾 SAVE YOUR WORK

```bash
cd /mnt/e/projects/treasure-chase
git add .
git commit -m "Days 2-3 complete: Full UI, collectibles, power-ups, jump, and polish"
```

---

## 🎮 YOUR GAME IS NOW FUN AND POLISHED!

**Next steps (Day 4-5):**
- Integrate full Treasure Multiplier code
- Theme progression system
- More power-ups
- Advanced scoring

**You're 60% done with a publishable game! 🚀**
