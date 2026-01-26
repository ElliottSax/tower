# Treasure Chase - Quick Start Guide

Get running in 15 minutes! 🚀

## Prerequisites Check

- [ ] Unity 2022.3 LTS installed
- [ ] Treasure Multiplier codebase available
- [ ] Android SDK configured (for Android)
- [ ] 2+ hours free time to start development

## Step 1: Project Setup (5 minutes)

### Create New Unity Project
```bash
# Option A: Use Unity Hub
# 1. Open Unity Hub
# 2. Click "New Project"
# 3. Select "Universal Render Pipeline"
# 4. Name: "TreasureChase"
# 5. Location: /mnt/e/projects/treasure-chase

# Option B: Clone and Rename Treasure Multiplier
cd /mnt/e/projects
cp -r treasure treasure-chase
cd treasure-chase
# Rename in Unity: Assets → Rename "Treasure Multiplier" to "Treasure Chase"
```

### Configure Build Settings
1. Open Unity: File → Build Settings
2. Switch Platform to **Android** (or iOS)
3. Player Settings:
   - Product Name: "Treasure Chase"
   - Company Name: [Your Company]
   - Package Name: com.[yourcompany].treasurechase
   - Version: 0.1.0

4. Android Settings:
   - Min API Level: Android 7.0 (API 24)
   - Target API Level: Android 13 (API 33)
   - Scripting Backend: IL2CPP
   - Architecture: ARM64
   - Install Location: Automatic

5. iOS Settings (if targeting iOS):
   - Min iOS Version: 13.0
   - Architecture: ARM64
   - Requires ARKit: NO

## Step 2: Code Modifications (5 minutes)

### Modify VehicleController for Endless Running

Open `Assets/Scripts/Vehicle/VehicleController.cs`:

```csharp
// ADD at top of class:
[Header("Endless Runner Settings")]
public float constantForwardSpeed = 10f;
public float laneDistance = 3f;
public float laneSwitchSpeed = 5f;
public int currentLane = 1; // 0=left, 1=center, 2=right

// MODIFY FixedUpdate():
void FixedUpdate()
{
    // NEW: Constant forward movement
    rb.velocity = new Vector3(
        rb.velocity.x,
        rb.velocity.y,
        constantForwardSpeed
    );

    // NEW: Lane positioning
    float targetX = (currentLane - 1) * laneDistance;
    Vector3 targetPosition = new Vector3(
        targetX,
        transform.position.y,
        transform.position.z
    );

    transform.position = Vector3.Lerp(
        transform.position,
        targetPosition,
        Time.fixedDeltaTime * laneSwitchSpeed
    );
}

// ADD new method:
public void SwitchLane(int direction)
{
    int targetLane = Mathf.Clamp(currentLane + direction, 0, 2);
    if (targetLane != currentLane)
    {
        currentLane = targetLane;
        AudioManager.Instance.PlaySFX("lane_switch");
    }
}
```

### Create InfiniteTerrainManager (Basic Version)

Create new file: `Assets/Scripts/Endless/InfiniteTerrainManager.cs`:

```csharp
using UnityEngine;
using System.Collections.Generic;

public class InfiniteTerrainManager : MonoBehaviour
{
    public static InfiniteTerrainManager Instance { get; private set; }

    [Header("Terrain Settings")]
    public GameObject terrainChunkPrefab;
    public int chunksAhead = 5;
    public float chunkLength = 50f;

    private Transform player;
    private float nextChunkZ = 0f;
    private List<GameObject> activeChunks = new List<GameObject>();

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        player = FindObjectOfType<VehicleController>().transform;

        // Generate initial chunks
        for (int i = 0; i < chunksAhead; i++)
        {
            SpawnChunk();
        }
    }

    void Update()
    {
        // Spawn new chunk if player is getting close
        if (player.position.z > nextChunkZ - (chunksAhead * chunkLength))
        {
            SpawnChunk();
        }

        // Remove old chunks (optional - for now just let them exist)
    }

    void SpawnChunk()
    {
        GameObject chunk = Instantiate(terrainChunkPrefab, new Vector3(0, 0, nextChunkZ), Quaternion.identity);
        activeChunks.Add(chunk);
        nextChunkZ += chunkLength;
    }
}
```

### Create DistanceTracker

Create new file: `Assets/Scripts/Endless/DistanceTracker.cs`:

```csharp
using UnityEngine;

public class DistanceTracker : MonoBehaviour
{
    public static DistanceTracker Instance { get; private set; }

    private Transform player;
    private float startZ;
    private float currentDistance;

    public float CurrentDistance => currentDistance;

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        player = FindObjectOfType<VehicleController>().transform;
        startZ = player.position.z;
    }

    void Update()
    {
        if (player != null)
        {
            currentDistance = player.position.z - startZ;
        }
    }
}
```

## Step 3: Test Scene Setup (5 minutes)

### Create EndlessTestScene

1. **Create New Scene:**
   - File → New Scene
   - Save As: `Assets/Scenes/EndlessTest.unity`

2. **Add GameObjects:**
   ```
   Hierarchy:
   ├── GameManager (from Treasure Multiplier prefab)
   ├── InfiniteTerrainManager (empty GameObject)
   ├── DistanceTracker (empty GameObject)
   ├── Player (VehicleController from Treasure Multiplier)
   ├── Main Camera
   └── Directional Light
   ```

3. **Configure InfiniteTerrainManager:**
   - Attach `InfiniteTerrainManager` script
   - Create a simple terrain chunk prefab:
     - Create Plane (scaled 10x1x5 to make 50 unit long chunk)
     - Add simple texture/material
     - Save as Prefab: `Assets/Prefabs/TerrainChunk.prefab`
   - Drag TerrainChunk prefab to "Terrain Chunk Prefab" field

4. **Configure DistanceTracker:**
   - Attach `DistanceTracker` script (no configuration needed)

5. **Configure Player:**
   - Ensure VehicleController is attached
   - Set "Constant Forward Speed" to 10
   - Set "Lane Distance" to 3
   - Set "Current Lane" to 1

6. **Position Camera:**
   - Position: (0, 5, -10)
   - Rotation: (20, 0, 0)
   - Or attach EnhancedCameraController from Treasure Multiplier

## Step 4: Test! (2 minutes)

1. **Press Play in Unity**

2. **Expected Behavior:**
   - Player vehicle moves forward automatically
   - Terrain generates ahead
   - Distance counts up

3. **Test Controls:**
   - Press Left Arrow: Vehicle switches to left lane
   - Press Right Arrow: Vehicle switches to right lane
   - (Jump/Duck not implemented yet)

4. **If it works:** 🎉 You have a basic endless runner!

5. **If not:**
   - Check Console for errors
   - Verify all scripts attached
   - Ensure VehicleController has Rigidbody
   - Check that TerrainChunk prefab exists

## What's Next?

Now that you have the basic endless runner working, follow the **Week 1 Development Plan** in the Implementation Guide:

### Day 1-2: Enhanced Movement
- [ ] Add jump mechanic (swipe up)
- [ ] Add duck mechanic (swipe down)
- [ ] Improve lane switching feel

### Day 3-4: Infinite Terrain
- [ ] Add chunk recycling (object pooling)
- [ ] Populate chunks with treasures
- [ ] Add basic obstacles

### Day 5: HUD Integration
- [ ] Display distance in HUD
- [ ] Display score
- [ ] Add pause menu

### Day 6-7: First Obstacles
- [ ] Create 3 basic obstacle types
- [ ] Add collision detection
- [ ] Implement game over

## Useful Resources

- **Implementation Guide:** `TREASURE_CHASE_IMPLEMENTATION.md` (week-by-week plan)
- **Master Plan:** `MOBILE_GAME_MASTER_PLAN.md` (overall strategy)
- **Game Design Doc:** `GAME_DESIGN_DOCUMENTS.md` (complete GDD)
- **Treasure Multiplier Code:** Reference existing systems

## Troubleshooting

### Vehicle Not Moving Forward
- Check: VehicleController has `constantForwardSpeed` set >0
- Check: VehicleController has Rigidbody component
- Check: Rigidbody is not kinematic

### Terrain Not Spawning
- Check: InfiniteTerrainManager has terrain chunk prefab assigned
- Check: chunksAhead >0
- Check: Player reference found (VehicleController exists in scene)

### Lane Switching Not Working
- Check: Input detected in console (add Debug.Log)
- Check: laneDistance and laneSwitchSpeed values
- Check: currentLane value (should be 0, 1, or 2)

## Quick Tips

1. **Iterate Fast:** Get something playable ASAP, then polish
2. **Test Often:** Press Play every 30 minutes to catch bugs early
3. **Use Treasure Multiplier Code:** Don't reinvent the wheel
4. **Commit to Git:** Version control is your friend
5. **Track Progress:** Use TODO list or project tracker

## Success Criteria for Day 1

By end of Day 1, you should have:
- ✅ Vehicle moving forward automatically
- ✅ Lane switching working (left/right)
- ✅ Terrain generating ahead of player
- ✅ Distance tracking and displaying
- ✅ No crashes, smooth 60 FPS

**If you hit these, you're on track for 8-week launch! 🚀**

---

Need help? Check the full Implementation Guide or reference Treasure Multiplier code.

Good luck! 🎮
