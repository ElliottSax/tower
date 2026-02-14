# ⚡ DAYS 2 & 3 QUICK START - START HERE!

**All scripts are created!** Just follow these steps to implement.

**Time:** 7-9 hours total

---

## ✅ HOUR 1: GAME STATE & COLLISION (Start here!)

### STEP 1: Add GameStateManager (5 min)

1. **Open Unity project**
2. **Hierarchy → Create Empty GameObject**
3. **Name:** `GameStateManager`
4. **Add Component:** GameStateManager (the script is already in Scripts folder!)
5. **Press Play** → Check Console for "Game Started!"

✅ **Working? Continue!**

---

### STEP 2: Update PlayerController for Collision (10 min)

**Open Scripts/PlayerController.cs and add these sections:**

**A) Add variables at top (after other [Header] sections):**

```csharp
[Header("Collision")]
public LayerMask obstacleLayer;
public GameObject deathParticles;

[Header("Shield")]
public bool isShielded = false;

private Rigidbody rb;
```

**B) At START of Update() method, add:**

```csharp
void Update()
{
    // Add this line at the very beginning
    if (GameStateManager.Instance != null && !GameStateManager.Instance.isGameActive)
        return;

    // ... your existing code continues ...
}
```

**C) Add these NEW methods at the bottom of the file:**

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

**Save the file!**

---

### STEP 3: Tag Your Obstacles (3 min)

1. **Inspector → Tags & Layers → Tags → Add Tag**
2. **Create tag:** `Obstacle`
3. **Open:** Prefabs/Obstacles/Obstacle_Box prefab
4. **Set Tag:** Obstacle
5. **Verify:** Box Collider has "Is Trigger" checked ✓

---

### STEP 4: Test Collision (2 min)

**Press Play:**
- Run into obstacle
- Console shows "Game Over!"
- Game freezes

✅ **Working? Continue!**

---

## ✅ HOUR 2: BUILD THE HUD

### STEP 5: Create HUD Structure (20 min)

**Delete old UI first:**
- Find any old "DistanceText" on Canvas → Delete it

**Now create new HUD:**

**1) HUD Panel (5 min):**
- Canvas → Right-click → UI → Panel
- Name: `HUD_Panel`
- Inspector → Image component → Color → Set Alpha to 0 (transparent)

**2) Distance Display (5 min):**
- HUD_Panel → Right-click → UI → Image
- Name: `DistanceBackground`
- **Rect Transform:**
  - Anchor Preset: Top-left
  - Pos X: 150, Pos Y: -50
  - Width: 200, Height: 60
- **Image component:** Color = Black, Alpha = 180

- DistanceBackground → Right-click → UI → Text - TextMeshPro
- Name: `DistanceText`
- Font Size: 36
- Alignment: Center + Middle
- Color: White
- Text: "0 m"

**3) Coin Display (3 min):**
- Select DistanceBackground → Duplicate (Ctrl+D)
- Name: `CoinBackground`
- Pos X: 400, Pos Y: -50 (move it right)
- Update child text:
  - Name: `CoinText`
  - Text: "💎 0"

**4) Score Display (3 min):**
- HUD_Panel → Right-click → UI → Text - TextMeshPro
- Name: `ScoreText`
- Anchor Preset: Top-center
- Pos Y: -100
- Font Size: 48
- Alignment: Center
- Color: Yellow (#FFD700)
- Text: "0"
- **Add Outline:** Component → Outline → Color: Black, Size: 3

**5) Multiplier Display (4 min):**
- HUD_Panel → Right-click → UI → Text - TextMeshPro
- Name: `MultiplierText`
- Anchor Preset: Top-center
- Pos Y: -180
- Font Size: 32
- Color: Orange
- Text: "x1.0"
- **Set Alpha to 0** (Color → A = 0)

---

### STEP 6: Connect HUD Controller (10 min)

1. **Select Canvas in Hierarchy**
2. **Add Component → SimpleHUDController**
3. **Assign all 4 text fields (drag from Hierarchy):**
   - Distance Text → DistanceText
   - Score Text → ScoreText
   - Coin Text → CoinText
   - Multiplier Text → MultiplierText

4. **Press Play** → Verify all counters show and update!

✅ **Working? Continue!**

---

## ✅ HOUR 3: GAME OVER SCREEN

### STEP 7: Create Game Over Panel (25 min)

**1) Main Panel (2 min):**
- Canvas → Right-click → UI → Panel
- Name: `GameOverPanel`
- Color: Black, Alpha: 220
- **CRITICAL:** Uncheck "Active" in Inspector (top-left checkbox)

**2) Title (3 min):**
- GameOverPanel → Right-click → UI → Text - TextMeshPro
- Name: `GameOverTitle`
- Text: "GAME OVER"
- Font Size: 72
- Pos Y: 200
- Color: Red
- Alignment: Center
- Add Outline: Black, Size: 5

**3) Stats - 4 text objects (12 min):**

**Final Score:**
- GameOverPanel → UI → Text-TMP
- Name: `FinalScoreText`
- Text: "Score: 0"
- Font Size: 48, Pos Y: 80
- Color: Yellow, Alignment: Center

**Distance (duplicate FinalScoreText):**
- Duplicate → Name: `FinalDistanceText`
- Text: "Distance: 0 m"
- Pos Y: 20, Color: White

**Coins (duplicate again):**
- Duplicate → Name: `FinalCoinsText`
- Text: "Coins: 0"
- Pos Y: -40, Color: Cyan

**Best Score (duplicate again):**
- Duplicate → Name: `BestScoreText`
- Text: "Best: 0"
- Pos Y: -120, Font Size: 36, Color: Gold

**4) Restart Button (5 min):**
- GameOverPanel → Right-click → UI → Button - TextMeshPro
- Name: `RestartButton`
- Pos Y: -220
- Width: 300, Height: 80
- Button color: Green
- Update text child: "RESTART", Size: 40, White

---

### STEP 8: Connect Game Over Controller (10 min)

1. **Select Canvas**
2. **Add Component → GameOverController**
3. **Assign everything:**
   - Game Over Panel → Drag GameOverPanel
   - Final Score Text → Drag FinalScoreText
   - Final Distance Text → Drag FinalDistanceText
   - Final Coins Text → Drag FinalCoinsText
   - Best Score Text → Drag BestScoreText
   - Restart Button → Drag RestartButton

4. **Press Play:**
   - Hit obstacle
   - Game Over panel appears?
   - Stats show?
   - Restart works?

✅ **Complete game loop working!**

---

## 🎉 CHECKPOINT: 3 HOURS DONE

**Take a 10-15 minute break!** You now have:
- ✅ Complete HUD
- ✅ Game over system
- ✅ Restart functionality

**Continue when ready! 🎮**

---

## ✅ HOUR 4: COLLECTIBLE COINS

### STEP 9: Create Coin Prefab (15 min)

**1) Create coin object (3 min):**
- Hierarchy → 3D Object → Sphere
- Name: `Coin`
- Scale: 0.5, 0.5, 0.5
- Position: 0, 1, 10

**2) Make it gold (3 min):**
- Create material: Assets/Materials/Mat_Coin
- Color: Gold (#FFD700)
- Metallic: 0.8, Smoothness: 0.9
- Drag to Coin

**3) Add script (2 min):**
- Select Coin
- Add Component → CoinBehavior
- Coin Value: 10

**4) Configure collider (2 min):**
- Coin has Sphere Collider component
- Check "Is Trigger" ✓
- Radius: 0.6

**5) Create tag (2 min):**
- Inspector → Tag → Add Tag → "Coin"
- Set Coin's tag to: Coin

**6) Save as prefab (3 min):**
- Create folder: Assets/Prefabs/Collectibles/
- Drag Coin from Hierarchy → Prefabs/Collectibles/
- Delete Coin from scene

---

### STEP 10: Setup Coin Spawning (15 min)

**1) Create CoinSpawner object (2 min):**
- Hierarchy → Create Empty
- Name: `CoinSpawner`
- Add Component → CoinSpawner script

**2) Assign coin prefab (1 min):**
- Drag Coin prefab to "Coin Prefab" field

**3) Update InfiniteTerrainManager.cs (8 min):**

Open the file and add:

**At top with other [Header] sections:**
```csharp
[Header("Collectibles")]
public CoinSpawner coinSpawner;
```

**In your SpawnChunk() method, AFTER creating the chunk:**
```csharp
// Spawn coins for this chunk
if (coinSpawner != null)
{
    coinSpawner.SpawnCoinsForChunk(newChunk, nextChunkZ, chunkLength);
}
```

**4) Assign CoinSpawner (2 min):**
- Select InfiniteTerrainManager in Hierarchy
- Drag CoinSpawner object to "Coin Spawner" field

**5) Test (2 min):**
- Press Play
- Coins spawn?
- Collect coins?
- Counter updates?

✅ **Working!**

---

## ✅ HOURS 5-6: POWER-UPS

### STEP 11: Create Magnet Power-Up (20 min)

**1) Create object (3 min):**
- 3D Object → Cylinder
- Name: `PowerUp_Magnet`
- Scale: 0.5, 1, 0.5
- Position: 0, 1.5, 20

**2) Material (2 min):**
- Create: Mat_Magnet
- Color: Blue (#0099FF)
- Metallic: 0.5
- Emission: Blue
- Assign to cylinder

**3) Add script (2 min):**
- Add Component → MagnetPowerUp
- Duration: 10
- Magnet Radius: 10
- Magnet Strength: 15

**4) Collider (2 min):**
- Add Component → Capsule Collider
- Is Trigger: ✓
- Radius: 0.6, Height: 2

**5) Save prefab (2 min):**
- Create folder: Prefabs/PowerUps/
- Drag to Prefabs/PowerUps/PowerUp_Magnet
- Delete from scene

---

### STEP 12: Create Shield Power-Up (20 min)

**Same process as Magnet:**

1. 3D Object → Capsule (name: PowerUp_Shield)
2. Scale: 0.5, 1, 0.5
3. Material: Mat_Shield (Cyan #00FFFF, Emission: Cyan)
4. Add Component → ShieldPowerUp, Duration: 15
5. Add Capsule Collider (Is Trigger ✓)
6. Save: Prefabs/PowerUps/PowerUp_Shield
7. Delete from scene

---

### STEP 13: Spawn Power-Ups (15 min)

**Update InfiniteTerrainManager.cs:**

**Add variables:**
```csharp
[Header("Power-Ups")]
public GameObject[] powerUpPrefabs;
public float powerUpSpawnChance = 0.15f;
```

**Add this new method:**
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

**In SpawnChunk(), after coin spawning:**
```csharp
// Spawn power-up
if (powerUpPrefabs.Length > 0 && Random.value < powerUpSpawnChance)
{
    SpawnPowerUp(newChunk, nextChunkZ, chunkLength);
}
```

**Assign in Inspector:**
- Select InfiniteTerrainManager
- Power Up Prefabs: Size = 2
- Element 0: PowerUp_Magnet
- Element 1: PowerUp_Shield
- Power Up Spawn Chance: 0.15

**Test:**
- Magnet pulls coins
- Shield protects from obstacles

---

## ✅ HOUR 7: JUMP & POLISH

### STEP 14: Add Jump (25 min)

**Update PlayerController.cs:**

**Add variables:**
```csharp
[Header("Jump Settings")]
public float jumpForce = 8f;
public LayerMask groundLayer;
public Transform groundCheck;
public float groundCheckRadius = 0.2f;

private bool isGrounded = false;
```

**In Start() method, add:**
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

**In Update(), add BEFORE lane switching:**
```csharp
// Check if grounded
isGrounded = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);

// Jump
if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
{
    Jump();
}
```

**Add new Jump() method:**
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

**Setup layers:**
1. Create Layer: "Ground"
2. Select all ground/terrain → Layer: Ground
3. Player → Ground Layer: Ground (in Inspector)

**Configure Rigidbody:**
- Player → Rigidbody:
  - Use Gravity: ✓
  - Is Kinematic: ✗
  - Constraints: Freeze Rotation X, Y, Z ✓

---

### STEP 15: Add Camera Shake (10 min)

1. **Select Main Camera**
2. **Add Component → CameraShake**

**That's it!** The Die() function already calls it.

---

### STEP 16: Add Player Trail (5 min)

1. **Select Player**
2. **Add Component → Trail Renderer**
3. **Configure:**
   - Time: 0.3
   - Width: 0.3 → 0 (curve from wide to narrow)
   - Color: White → Transparent
   - Material: Default-Particle

---

## 🎉 DAYS 2 & 3 COMPLETE!

### Final Testing Checklist:

- [ ] Start game → HUD shows
- [ ] Collect coins → particles + counter
- [ ] Collect Magnet → pulls coins
- [ ] Collect Shield → protects from obstacles
- [ ] Jump (Space) → player jumps
- [ ] Hit obstacle → shake + particles + game over
- [ ] Stats show correctly
- [ ] Restart works
- [ ] Best score saves

---

## 💾 SAVE YOUR WORK!

File → Save Scene
File → Save Project

```bash
cd /mnt/e/projects/treasure-chase
git add .
git commit -m "Days 2-3: Complete UI, collectibles, power-ups, jump, polish"
```

---

## 🚀 YOU DID IT!

**Progress: 60% complete!**

Your game now has:
- ✅ Complete game loop
- ✅ Professional UI
- ✅ Collectibles with effects
- ✅ Power-ups (Magnet, Shield)
- ✅ Jump mechanic
- ✅ Visual polish

**Next:** Day 4-5 - Full integration with Treasure Multiplier code!

---

**Questions? Stuck? Tell me which step and I'll help! 🎮**
