# 💎 DAY 3: COLLECTIBLES & POWER-UPS

**Goal:** Add the FUN factor - coins, treasures, power-ups, and juice!

**Time Required:** 4-5 hours

**What You'll Build:**
- Collectible coins with visual effects
- Power-up system (Magnet, Shield, Speed Boost)
- Jump mechanic
- Particle effects and screen shake
- Score multipliers and combos

---

## 📋 TODAY'S ROADMAP

```
Hour 1: Collectible System (Coins & Treasures)
Hour 2: Power-Up Framework
Hour 3: Jump Mechanic & Physics
Hour 4: Visual Effects & Juice
Hour 5: Testing & Balance
```

---

## ⚙️ PREREQUISITES

**You should have from Day 2:**
- [ ] Complete game loop (play → die → restart)
- [ ] Working HUD with score/distance/coins
- [ ] Collision detection working
- [ ] Game over screen functional

---

## 💰 HOUR 1: COLLECTIBLE SYSTEM

### **STEP 1: Create Coin Prefab**
**Time: 10 minutes**

1. **Create coin object:**
   - Hierarchy → 3D Object → Sphere
   - Name: `Coin`
   - Scale: 0.5, 0.5, 0.5
   - Position: 0, 1, 10 (in a lane for testing)

2. **Add visual flair:**
   - Create new Material: `Mat_Coin`
   - Color: Gold/Yellow (#FFD700)
   - Metallic: 0.8
   - Smoothness: 0.9
   - Assign to Coin's Mesh Renderer

3. **Add spinning behavior:**
   - Create script: `CoinBehavior.cs`

```csharp
using UnityEngine;

public class CoinBehavior : MonoBehaviour
{
    [Header("Rotation")]
    public float rotationSpeed = 180f; // Degrees per second
    public Vector3 rotationAxis = Vector3.up;

    [Header("Bobbing (Optional)")]
    public bool enableBobbing = true;
    public float bobbingSpeed = 2f;
    public float bobbingAmount = 0.3f;

    [Header("Value")]
    public int coinValue = 10;

    private Vector3 startPosition;
    private float timeOffset;

    void Start()
    {
        startPosition = transform.position;
        timeOffset = Random.Range(0f, 100f); // Random offset for variation
    }

    void Update()
    {
        // Rotate coin
        transform.Rotate(rotationAxis * rotationSpeed * Time.deltaTime);

        // Bob up and down
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
            Collect(other.gameObject);
        }
    }

    void Collect(GameObject player)
    {
        // Notify score manager
        if (EndlessScoreManager.Instance != null)
        {
            EndlessScoreManager.Instance.AddCoins(coinValue);
        }
        else if (FindObjectOfType<SimpleHUDController>() != null)
        {
            FindObjectOfType<SimpleHUDController>().AddCoins(coinValue);
        }

        // Visual/audio feedback
        SpawnCollectionEffect();

        // Destroy coin
        Destroy(gameObject);
    }

    void SpawnCollectionEffect()
    {
        // Placeholder - we'll add particles later
        Debug.Log("Coin collected! +" + coinValue);
    }
}
```

   - Add CoinBehavior script to Coin
   - Set Coin Value: 10

4. **Add trigger collider:**
   - Coin already has Sphere Collider
   - Check "Is Trigger" ✓
   - Radius: 0.6 (slightly larger than visual)

5. **Create prefab:**
   - Drag Coin to Prefabs/Collectibles/ folder
   - Delete from scene
   - Prefab is now reusable

---

### **STEP 2: Spawn Coins in Terrain**
**Time: 15 minutes**

1. **Create CoinSpawner script:**

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
        {
            SpawnCoinPattern(chunk.transform, chunkStartZ, chunkLength);
        }
        else
        {
            SpawnRandomCoins(chunk.transform, chunkStartZ, chunkLength);
        }
    }

    void SpawnRandomCoins(Transform parent, float startZ, float length)
    {
        for (int i = 0; i < coinsPerChunk; i++)
        {
            // Random lane
            int randomLane = Random.Range(0, lanePositions.Length);
            float x = lanePositions[randomLane];

            // Random Z within chunk
            float z = startZ + Random.Range(5f, length - 5f);

            // Spawn coin
            Vector3 position = new Vector3(x, coinHeight, z);
            GameObject coin = Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }

    void SpawnCoinPattern(Transform parent, float startZ, float length)
    {
        // Choose random pattern
        int pattern = Random.Range(0, 4);

        switch (pattern)
        {
            case 0: // Single lane line
                SpawnSingleLane(parent, startZ, length);
                break;
            case 1: // Zigzag
                SpawnZigzag(parent, startZ, length);
                break;
            case 2: // All lanes horizontal
                SpawnHorizontalLine(parent, startZ + length * 0.5f);
                break;
            case 3: // Random scatter
                SpawnRandomCoins(parent, startZ, length);
                break;
        }
    }

    void SpawnSingleLane(Transform parent, float startZ, float length)
    {
        int lane = Random.Range(0, lanePositions.Length);
        float x = lanePositions[lane];

        for (int i = 0; i < 5; i++)
        {
            float z = startZ + (length / 6f) * (i + 1);
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }

    void SpawnZigzag(Transform parent, float startZ, float length)
    {
        int currentLane = 1; // Start center

        for (int i = 0; i < 5; i++)
        {
            float x = lanePositions[currentLane];
            float z = startZ + (length / 6f) * (i + 1);
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);

            // Alternate lanes
            currentLane = (currentLane == 0) ? 2 : (currentLane == 2) ? 0 : Random.Range(0, 2) * 2;
        }
    }

    void SpawnHorizontalLine(Transform parent, float z)
    {
        foreach (float x in lanePositions)
        {
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }
}
```

2. **Add to scene:**
   - Create empty GameObject: `CoinSpawner`
   - Add CoinSpawner script
   - Assign Coin prefab to script

3. **Integrate with InfiniteTerrainManager:**
   - Open InfiniteTerrainManager.cs
   - Add at top:

```csharp
[Header("Collectibles")]
public CoinSpawner coinSpawner;
```

   - In the SpawnChunk() method, after creating chunk, add:

```csharp
// Spawn coins for this chunk
if (coinSpawner != null)
{
    coinSpawner.SpawnCoinsForChunk(newChunk, nextChunkZ, chunkLength);
}
```

4. **Assign CoinSpawner:**
   - Select InfiniteTerrainManager in scene
   - Drag CoinSpawner object to "Coin Spawner" field

---

### **STEP 3: Test Coin Collection**
**Time: 5 minutes**

**Press Play and verify:**
- [ ] Coins spawn in lanes
- [ ] Coins spin/bob
- [ ] Running into coin collects it
- [ ] Coin counter in HUD updates
- [ ] Console shows "Coin collected!"
- [ ] Coin disappears after collection

**If coins don't spawn:**
- Check Coin prefab is assigned
- Check CoinSpawner is assigned to InfiniteTerrainManager
- Check SpawnChunk() calls coinSpawner.SpawnCoinsForChunk()

---

## ⚡ HOUR 2: POWER-UP SYSTEM

### **STEP 4: Create Power-Up Base Class**
**Time: 15 minutes**

1. **Create PowerUpBase.cs:**

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
    public Sprite powerUpIcon;

    [Header("Visual")]
    public float rotationSpeed = 90f;
    public Color glowColor = Color.white;

    protected bool isActive = false;
    protected float remainingTime = 0f;
    protected GameObject player;

    void Update()
    {
        // Rotate power-up
        transform.Rotate(Vector3.up * rotationSpeed * Time.deltaTime);

        // If active, countdown
        if (isActive)
        {
            remainingTime -= Time.deltaTime;

            if (remainingTime <= 0f)
            {
                DeactivatePowerUp();
            }
            else
            {
                UpdatePowerUp();
            }
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

        // Hide visual
        GetComponent<MeshRenderer>().enabled = false;
        GetComponent<Collider>().enabled = false;

        // Notify UI
        NotifyUI();

        // Override in subclass
        OnActivate();

        Debug.Log(powerUpType + " activated for " + duration + " seconds!");
    }

    public void DeactivatePowerUp()
    {
        isActive = false;

        // Override in subclass
        OnDeactivate();

        Debug.Log(powerUpType + " deactivated!");

        // Destroy power-up
        Destroy(gameObject);
    }

    void NotifyUI()
    {
        // TODO: Show power-up icon in HUD with timer
    }

    // Override these in subclasses
    protected abstract void OnActivate();
    protected abstract void OnDeactivate();
    protected virtual void UpdatePowerUp() { }
}
```

---

### **STEP 5: Create Magnet Power-Up**
**Time: 15 minutes**

1. **Create MagnetPowerUp.cs:**

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
        // Create magnet collider on player
        if (player != null)
        {
            magnetCollider = player.AddComponent<SphereCollider>();
            magnetCollider.isTrigger = true;
            magnetCollider.radius = magnetRadius;
        }
    }

    protected override void UpdatePowerUp()
    {
        // Attract nearby coins
        Collider[] nearbyColliders = Physics.OverlapSphere(player.transform.position, magnetRadius);

        foreach (Collider col in nearbyColliders)
        {
            if (col.CompareTag("Coin"))
            {
                // Pull coin toward player
                Vector3 direction = (player.transform.position - col.transform.position).normalized;
                col.transform.position += direction * magnetStrength * Time.deltaTime;
            }
        }
    }

    protected override void OnDeactivate()
    {
        // Remove magnet collider
        if (magnetCollider != null)
        {
            Destroy(magnetCollider);
        }
    }
}
```

2. **Create Magnet prefab:**
   - Hierarchy → 3D Object → Cylinder
   - Name: `PowerUp_Magnet`
   - Scale: 0.5, 1, 0.5
   - Create material: Mat_Magnet (Blue, emissive)
   - Add MagnetPowerUp script
   - Set Duration: 10 seconds
   - Set Magnet Radius: 10
   - Add Capsule Collider (Is Trigger: ✓)
   - Tag: Create new tag "PowerUp" and assign
   - Save as Prefabs/PowerUps/PowerUp_Magnet

---

### **STEP 6: Create Shield Power-Up**
**Time: 15 minutes**

1. **Create ShieldPowerUp.cs:**

```csharp
using UnityEngine;

public class ShieldPowerUp : PowerUpBase
{
    [Header("Shield Settings")]
    public GameObject shieldVisualPrefab;

    private GameObject shieldVisual;
    private PlayerController playerController;

    protected override void OnActivate()
    {
        if (player != null)
        {
            // Disable collision with obstacles
            playerController = player.GetComponent<PlayerController>();
            if (playerController != null)
            {
                playerController.isShielded = true;
            }

            // Spawn shield visual
            if (shieldVisualPrefab != null)
            {
                shieldVisual = Instantiate(shieldVisualPrefab, player.transform);
                shieldVisual.transform.localPosition = Vector3.zero;
            }
            else
            {
                // Create simple sphere shield
                CreateDefaultShield();
            }
        }
    }

    void CreateDefaultShield()
    {
        GameObject shield = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        shield.transform.SetParent(player.transform);
        shield.transform.localPosition = Vector3.zero;
        shield.transform.localScale = Vector3.one * 2.5f;

        // Remove collider (visual only)
        Destroy(shield.GetComponent<Collider>());

        // Make transparent blue
        Renderer renderer = shield.GetComponent<Renderer>();
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0, 0.5f, 1f, 0.3f); // Blue transparent
        mat.SetFloat("_Mode", 3); // Transparent mode
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
        // Remove shield
        if (playerController != null)
        {
            playerController.isShielded = false;
        }

        if (shieldVisual != null)
        {
            Destroy(shieldVisual);
        }
    }
}
```

2. **Update PlayerController.cs:**
   - Add at top with other variables:

```csharp
[Header("Shield")]
public bool isShielded = false;
```

   - Update OnTriggerEnter():

```csharp
void OnTriggerEnter(Collider other)
{
    if (other.CompareTag("Obstacle"))
    {
        if (isShielded)
        {
            // Destroy obstacle instead of dying
            Destroy(other.gameObject);
            Debug.Log("Shield protected you!");
        }
        else
        {
            Die();
        }
    }
}
```

3. **Create Shield prefab:**
   - 3D Object → Capsule (name: PowerUp_Shield)
   - Scale: 0.5, 1, 0.5
   - Material: Mat_Shield (Cyan/Light Blue, emissive)
   - Add ShieldPowerUp script
   - Duration: 15 seconds
   - Add Capsule Collider (Is Trigger ✓)
   - Tag: PowerUp
   - Save as Prefabs/PowerUps/PowerUp_Shield

---

### **STEP 7: Tag Coins for Magnet**
**Time: 2 minutes**

1. **Create "Coin" tag:**
   - Inspector → Tag → Add Tag
   - Create: `Coin`

2. **Update Coin prefab:**
   - Open Coin prefab
   - Set Tag: Coin
   - Save

---

### **STEP 8: Spawn Power-Ups**
**Time: 10 minutes**

1. **Update InfiniteTerrainManager.cs or create PowerUpSpawner:**

Add to InfiniteTerrainManager:

```csharp
[Header("Power-Ups")]
public GameObject[] powerUpPrefabs;
public float powerUpSpawnChance = 0.15f; // 15% chance per chunk

// In SpawnChunk() method:
void SpawnChunk()
{
    // ... existing chunk spawn code ...

    // Spawn power-up randomly
    if (powerUpPrefabs.Length > 0 && Random.value < powerUpSpawnChance)
    {
        SpawnPowerUp(newChunk, nextChunkZ, chunkLength);
    }
}

void SpawnPowerUp(GameObject chunk, float startZ, float length)
{
    // Random power-up
    GameObject powerUpPrefab = powerUpPrefabs[Random.Range(0, powerUpPrefabs.Length)];

    // Random lane
    float x = lanePositions[Random.Range(0, lanePositions.Length)];

    // Middle of chunk
    float z = startZ + (length * 0.5f);
    float y = 1.5f; // Slightly higher than coins

    Vector3 position = new Vector3(x, y, z);
    Instantiate(powerUpPrefab, position, Quaternion.identity, chunk.transform);
}
```

2. **Assign power-ups:**
   - Select InfiniteTerrainManager
   - Set Power Up Prefabs size: 2
   - Drag PowerUp_Magnet to Element 0
   - Drag PowerUp_Shield to Element 1
   - Power Up Spawn Chance: 0.15

---

### **STEP 9: Test Power-Ups**
**Time: 10 minutes**

**Press Play and test:**

**Magnet:**
- [ ] Blue cylinder spawns occasionally
- [ ] Collecting it shows "Magnet activated"
- [ ] Nearby coins are pulled toward player
- [ ] Lasts 10 seconds
- [ ] Auto-deactivates

**Shield:**
- [ ] Cyan capsule spawns occasionally
- [ ] Collecting shows shield bubble around player
- [ ] Running into obstacles destroys them (no death)
- [ ] Shield lasts 15 seconds
- [ ] Visual disappears when done

---

## 🦘 HOUR 3: JUMP MECHANIC

### **STEP 10: Add Jump to PlayerController**
**Time: 20 minutes**

1. **Open PlayerController.cs**

2. **Add jump variables:**

```csharp
[Header("Jump Settings")]
public float jumpForce = 8f;
public LayerMask groundLayer;
public Transform groundCheck; // Empty child object at player's feet
public float groundCheckRadius = 0.2f;

private Rigidbody rb;
private bool isGrounded = false;
```

3. **Add in Start():**

```csharp
void Start()
{
    rb = GetComponent<Rigidbody>();

    // Create ground check if doesn't exist
    if (groundCheck == null)
    {
        GameObject groundCheckObj = new GameObject("GroundCheck");
        groundCheckObj.transform.SetParent(transform);
        groundCheckObj.transform.localPosition = new Vector3(0, -0.5f, 0);
        groundCheck = groundCheckObj.transform;
    }
}
```

4. **Update Update() method:**

```csharp
void Update()
{
    if (GameStateManager.Instance != null && !GameStateManager.Instance.isGameActive)
        return;

    // Check if grounded
    isGrounded = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);

    // Move forward
    transform.Translate(Vector3.forward * forwardSpeed * Time.deltaTime);

    // Lane switching
    if (Input.GetKeyDown(KeyCode.LeftArrow) && currentLane > 0 && !isSwitchingLane)
        StartLaneSwitch(currentLane - 1);

    if (Input.GetKeyDown(KeyCode.RightArrow) && currentLane < 2 && !isSwitchingLane)
        StartLaneSwitch(currentLane + 1);

    // JUMP (new!)
    if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
    {
        Jump();
    }

    // Execute lane switch
    if (isSwitchingLane)
    {
        // ... existing lane switch code ...
    }
}

void Jump()
{
    if (rb != null)
    {
        rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z); // Reset Y velocity
        rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
        Debug.Log("Jump!");
    }
}
```

5. **Setup ground layer:**
   - Create new Layer: "Ground"
   - Select all ground/terrain objects
   - Set Layer: Ground
   - Select Player
   - In PlayerController, set Ground Layer: Ground

6. **Configure Player Rigidbody:**
   - Select Player
   - Rigidbody component:
     - Mass: 1
     - Drag: 0
     - Angular Drag: 0.05
     - Use Gravity: ✓
     - Is Kinematic: ✗ (unchecked)
     - Constraints: Freeze Rotation X, Y, Z ✓

---

### **STEP 11: Create Jump-Over Obstacles**
**Time: 15 minutes**

1. **Create low obstacle:**
   - Duplicate Obstacle_Box prefab
   - Name: Obstacle_LowBar
   - Scale: X=1.5, Y=0.5, Z=0.3 (horizontal bar)
   - Position Y: 0.5
   - Color: Yellow
   - Keep trigger collider

2. **Update ObstacleSpawner:**

```csharp
[Header("Obstacle Types")]
public GameObject[] jumpableObstacles; // Low obstacles to jump over
public GameObject[] dodgeObstacles;    // Standard obstacles to dodge

public float jumpableObstacleChance = 0.3f; // 30% are jumpable

// In obstacle spawning code:
void SpawnObstacle(Transform parent, Vector3 position)
{
    GameObject prefabToSpawn;

    if (Random.value < jumpableObstacleChance && jumpableObstacles.Length > 0)
    {
        // Spawn jumpable obstacle
        prefabToSpawn = jumpableObstacles[Random.Range(0, jumpableObstacles.Length)];
    }
    else
    {
        // Spawn dodge obstacle
        prefabToSpawn = dodgeObstacles.Length > 0
            ? dodgeObstacles[Random.Range(0, dodgeObstacles.Length)]
            : standardObstacles[0];
    }

    Instantiate(prefabToSpawn, position, Quaternion.identity, parent);
}
```

3. **Assign obstacle types:**
   - Select ObstacleSpawner
   - Jumpable Obstacles: Add Obstacle_LowBar
   - Dodge Obstacles: Add Obstacle_Box
   - Jumpable Obstacle Chance: 0.3

---

### **STEP 12: Test Jump**
**Time: 5 minutes**

**Press Play and test:**
- [ ] Space bar makes player jump
- [ ] Player lands back on ground
- [ ] Can jump over low yellow bars
- [ ] Still dies to red boxes (if hit)
- [ ] Can't double-jump (only jump when grounded)

---

## ✨ HOUR 4: VISUAL EFFECTS & JUICE

### **STEP 13: Coin Collection Particle**
**Time: 15 minutes**

1. **Create coin particle effect:**
   - Hierarchy → Effects → Particle System
   - Name: CoinCollectEffect
   - Configure:
     - Duration: 0.5
     - Looping: OFF
     - Start Lifetime: 0.3-0.5
     - Start Speed: 2-4
     - Start Size: 0.1-0.2
     - Start Color: Yellow to transparent (gradient)
     - Emission: 20 particles burst
     - Shape: Sphere, radius 0.5
   - Set inactive
   - Save as Prefabs/Effects/CoinCollectEffect

2. **Update CoinBehavior.cs:**

```csharp
[Header("Effects")]
public GameObject collectionEffectPrefab;

void SpawnCollectionEffect()
{
    if (collectionEffectPrefab != null)
    {
        Instantiate(collectionEffectPrefab, transform.position, Quaternion.identity);
    }

    Debug.Log("Coin collected! +" + coinValue);
}
```

3. **Assign to Coin prefab:**
   - Open Coin prefab
   - Drag CoinCollectEffect to Collection Effect Prefab field

---

### **STEP 14: Screen Shake on Collision**
**Time: 15 minutes**

1. **Create CameraShake.cs:**

```csharp
using UnityEngine;

public class CameraShake : MonoBehaviour
{
    public static CameraShake Instance { get; private set; }

    public float shakeDuration = 0.3f;
    public float shakeMagnitude = 0.2f;
    public float dampingSpeed = 1.0f;

    private Vector3 initialPosition;
    private float currentShakeDuration = 0f;

    void Awake()
    {
        if (Instance == null)
            Instance = this;
        else
            Destroy(gameObject);
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
            currentShakeDuration -= Time.deltaTime * dampingSpeed;
        }
        else
        {
            currentShakeDuration = 0f;
            transform.localPosition = initialPosition;
        }
    }

    public void TriggerShake()
    {
        currentShakeDuration = shakeDuration;
    }

    public void TriggerShake(float duration, float magnitude)
    {
        shakeDuration = duration;
        shakeMagnitude = magnitude;
        currentShakeDuration = duration;
    }
}
```

2. **Add to Camera:**
   - Select Main Camera
   - Add Component → CameraShake

3. **Call from PlayerController:**

In Die() method:

```csharp
void Die()
{
    Debug.Log("Player Hit Obstacle!");

    // Screen shake
    if (CameraShake.Instance != null)
    {
        CameraShake.Instance.TriggerShake(0.5f, 0.3f);
    }

    // ... rest of die code ...
}
```

---

### **STEP 15: Floating Score Text**
**Time: 20 minutes**

1. **Create FloatingText.cs:**

```csharp
using UnityEngine;
using TMPro;

public class FloatingText : MonoBehaviour
{
    public float lifetime = 1f;
    public float floatSpeed = 2f;
    public float fadeSpeed = 1f;

    private TextMeshPro textMesh;
    private float timer = 0f;

    void Start()
    {
        textMesh = GetComponent<TextMeshPro>();
        Destroy(gameObject, lifetime);
    }

    void Update()
    {
        // Float upward
        transform.position += Vector3.up * floatSpeed * Time.deltaTime;

        // Fade out
        if (textMesh != null)
        {
            Color color = textMesh.color;
            color.a = Mathf.Lerp(1f, 0f, timer / lifetime);
            textMesh.color = color;
        }

        timer += Time.deltaTime;
    }

    public void SetText(string text, Color color)
    {
        if (textMesh != null)
        {
            textMesh.text = text;
            textMesh.color = color;
        }
    }
}
```

2. **Create FloatingText prefab:**
   - Hierarchy → 3D Object → 3D Text - TextMeshPro
   - Name: FloatingText
   - Font size: 2
   - Alignment: Center + Middle
   - Color: Yellow
   - Add FloatingText script
   - Set inactive
   - Save as Prefabs/UI/FloatingText

3. **Update CoinBehavior to spawn floating text:**

```csharp
[Header("Effects")]
public GameObject floatingTextPrefab;

void SpawnCollectionEffect()
{
    // Particle effect
    if (collectionEffectPrefab != null)
    {
        Instantiate(collectionEffectPrefab, transform.position, Quaternion.identity);
    }

    // Floating text
    if (floatingTextPrefab != null)
    {
        GameObject textObj = Instantiate(floatingTextPrefab, transform.position, Quaternion.identity);
        FloatingText floatingText = textObj.GetComponent<FloatingText>();
        if (floatingText != null)
        {
            floatingText.SetText("+" + coinValue, Color.yellow);
        }
    }

    Debug.Log("Coin collected! +" + coinValue);
}
```

---

### **STEP 16: Add Trail to Player**
**Time: 5 minutes**

1. **Add Trail Renderer:**
   - Select Player
   - Add Component → Trail Renderer
   - Configure:
     - Time: 0.3
     - Width: 0.3 to 0
     - Color: White to transparent (gradient)
     - Material: Default-Particle

---

## 🎯 HOUR 5: TESTING & BALANCE

### **STEP 17: Balance Testing**
**Time: 30 minutes**

**Test each system:**

**Coins:**
- [ ] Spawn in good patterns
- [ ] Easy to collect
- [ ] Visual feedback works
- [ ] Counter updates

**Power-Ups:**
- [ ] Spawn rate feels right (~15%)
- [ ] Magnet pulls coins effectively
- [ ] Shield protects from 1-2 hits
- [ ] Durations feel balanced

**Jump:**
- [ ] Responsive controls
- [ ] Can clear low obstacles
- [ ] Lands smoothly
- [ ] Can't double-jump

**Visual Effects:**
- [ ] Particles look good
- [ ] Screen shake not too intense
- [ ] Floating text readable
- [ ] Trail looks smooth

**Adjust values as needed!**

---

### **STEP 18: Add Combo System (Optional)**
**Time: 15 minutes**

**Track consecutive coin collections:**

Add to SimpleHUDController or EndlessScoreManager:

```csharp
[Header("Combo System")]
public int currentCombo = 0;
public float comboTimeout = 2f;
private float lastCoinTime = 0f;

public void AddCoins(int amount)
{
    currentCoins += amount;

    // Update combo
    if (Time.time - lastCoinTime < comboTimeout)
    {
        currentCombo++;

        if (currentCombo >= 5)
        {
            // Bonus for 5+ combo
            currentScore += 100;
            Debug.Log("COMBO x" + currentCombo + "! +100 bonus!");
        }
    }
    else
    {
        currentCombo = 1;
    }

    lastCoinTime = Time.time;
}
```

---

## 🎉 DAY 3 COMPLETE!

### **What You Built Today:**

✅ **Collectible System:**
- Spinning, bobbing coins
- Pattern-based spawning
- Collection effects (particles + text)

✅ **Power-Up System:**
- Magnet (pulls coins)
- Shield (protects from obstacles)
- Reusable base class for future power-ups

✅ **Jump Mechanic:**
- Space bar to jump
- Ground detection
- Jumpable obstacles
- Physics-based movement

✅ **Visual Polish:**
- Particle effects
- Screen shake
- Floating score text
- Player trail effect
- Combo system

---

## 📊 YOUR PROGRESS

```
Week 1 Progress: [████████████░░░░░░░░] 60%

✅ Day 1: Basic endless runner
✅ Day 2: UI + Game Over
✅ Day 3: Collectibles + Power-Ups + Jump
⏳ Day 4-5: Full integration with Treasure Multiplier
⏳ Day 6-7: Theme system + final polish
```

---

## 🚀 WHAT'S NEXT?

### **Tomorrow (Day 4-5):**
1. Integrate remaining Treasure Multiplier code
2. Add theme progression system
3. Implement full scoring with multipliers
4. Add more power-ups (Speed Boost, Double Coins)
5. Polish visual themes

---

## 💾 SAVE & COMMIT

```bash
cd /mnt/e/projects/treasure-chase
git add .
git commit -m "Day 3: Collectibles, power-ups, jump mechanic, and visual polish"
```

---

## 🎯 YOUR GAME IS NOW FUN!

**Before Day 3:** Functional but basic
**After Day 3:** Engaging and addictive!

You've added:
- ✅ Rewards (coins)
- ✅ Variety (power-ups)
- ✅ Player agency (jump)
- ✅ Feedback (particles, shake, text)

**Your game now has the core engagement loop! 🎮**

---

**REST UP! TOMORROW WE INTEGRATE EVERYTHING! 🚀**

*The game is getting REALLY good now!*
