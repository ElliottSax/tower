# 🚀 DAY 1: START BUILDING NOW

**Goal:** Get Treasure Chase playable in Unity TODAY (2-4 hours)
**Date:** 2026-01-26

---

## ⏰ HOUR-BY-HOUR BREAKDOWN

### **HOUR 1: Project Setup** (0:00 - 1:00)

#### Step 1: Create Unity Project (10 min)
1. Open Unity Hub
2. Click "New Project"
3. Template: **3D (URP)** or **3D Core**
4. Project Name: **TreasureChase**
5. Location: Choose location (e.g., `E:/UnityProjects/TreasureChase`)
6. Click **Create Project**
7. Wait for Unity to open (2-3 minutes)

✅ **Verify:** Unity Editor is open with empty scene

#### Step 2: Set Up Project Structure (10 min)
In Unity Project window, create this folder structure:

```
Assets/
├── Scenes/
│   ├── MainMenu
│   └── Gameplay
├── Scripts/
│   ├── Endless/
│   ├── Obstacles/
│   ├── UI/
│   └── ScriptableObjects/
├── Prefabs/
│   ├── Terrain/
│   ├── Obstacles/
│   ├── Collectibles/
│   └── UI/
├── Materials/
│   ├── Terrain/
│   └── Obstacles/
├── ScriptableObjects/
│   ├── Themes/
│   └── Heroes/
└── Resources/
    ├── Audio/
    └── Particles/
```

**Quick Method:**
1. Right-click in Project window
2. Create → Folder
3. Name it, press Enter
4. Repeat for all folders

✅ **Verify:** All folders exist in Project window

#### Step 3: Copy Scripts from Package (15 min)
1. Open File Explorer to: `E:/projects/treasure-chase/Scripts/`
2. Copy all `.cs` files
3. In Unity, paste into corresponding folders:
   - Endless/*.cs → Assets/Scripts/Endless/
   - Obstacles/*.cs → Assets/Scripts/Obstacles/
   - UI/*.cs → Assets/Scripts/UI/
   - ScriptableObjects/*.cs → Assets/Scripts/ScriptableObjects/

**Files to copy (12 scripts):**
- InfiniteTerrainManager.cs
- DistanceTracker.cs
- EndlessScoreManager.cs
- ObstacleSpawner.cs
- Obstacle.cs
- WorldManager.cs
- GhostRecorder.cs
- TournamentManager.cs
- EndlessTutorial.cs
- EndlessHUD.cs
- GameOverUI.cs
- WorldThemeTemplate.cs

✅ **Verify:** Unity compiles successfully (no red errors in Console)

⚠️ **If Errors Appear:**
- Most will be missing dependencies (VehicleController, AudioManager, etc.)
- **That's OK!** We'll add those from Treasure Multiplier code
- Note errors but continue for now

#### Step 4: Import TextMesh Pro (5 min)
1. Window → TextMeshPro → Import TMP Essential Resources
2. Click **Import**
3. Wait for import to complete

✅ **Verify:** TMP folder exists in Assets

#### Step 5: Save Scene (5 min)
1. File → Save As
2. Name: "Gameplay"
3. Location: Assets/Scenes/
4. Click **Save**

✅ **Verify:** "Gameplay" scene in Scenes folder

**CHECKPOINT:** You now have a Unity project with all scripts!

---

### **HOUR 2: Basic Scene Setup** (1:00 - 2:00)

#### Step 6: Create Game Managers (15 min)

Create empty GameObjects in Hierarchy:

1. **Create GameManager Container:**
   - Right-click in Hierarchy → Create Empty
   - Name: "--- GAME MANAGERS ---"
   - Position: (0, 0, 0)

2. **Create Manager Objects:**
   Under GAME MANAGERS, create these (Create Empty for each):
   - InfiniteTerrainManager
   - DistanceTracker
   - EndlessScoreManager
   - ObstacleSpawner
   - WorldManager
   - GhostRecorder
   - TournamentManager

3. **Add Scripts to Each:**
   - Select InfiniteTerrainManager → Inspector → Add Component → InfiniteTerrainManager
   - Repeat for all managers (match object name to script name)

✅ **Verify:** 7 manager objects, each with corresponding script attached

#### Step 7: Create Player Placeholder (10 min)

1. Create → 3D Object → Capsule
2. Rename to "Player"
3. Position: (0, 1, 0)
4. Add Component → Rigidbody
   - Mass: 1
   - Use Gravity: ✓
   - Is Kinematic: ✗
5. Tag: Create new tag "Player", assign to capsule

✅ **Verify:** Player capsule at (0, 1, 0) with Rigidbody

#### Step 8: Create Ground Plane (10 min)

1. Create → 3D Object → Plane
2. Rename to "StartingGround"
3. Position: (0, 0, 0)
4. Scale: (10, 1, 10)
5. Tag: "Ground"

✅ **Verify:** Large ground plane under player

#### Step 9: Create Terrain Chunk Prefab (15 min)

1. Create → 3D Object → Cube
2. Rename to "TerrainChunk"
3. Scale: (10, 0.2, 50) - Wide, thin, long
4. Create new Material: "Mat_Ground"
5. Assign to cube
6. Drag TerrainChunk from Hierarchy to Assets/Prefabs/Terrain/
7. Delete from Hierarchy

✅ **Verify:** TerrainChunk prefab exists in Prefabs/Terrain/

#### Step 10: Create Simple Obstacle Prefab (10 min)

1. Create → 3D Object → Cube
2. Rename to "Obstacle_Box"
3. Scale: (2, 2, 2)
4. Add Component → Box Collider
   - Is Trigger: ✓
5. Add Component → Obstacle script
6. Create new Material: "Mat_Obstacle" (Red)
7. Assign to cube
8. Tag: "Obstacle"
9. Drag to Assets/Prefabs/Obstacles/
10. Delete from Hierarchy

✅ **Verify:** Obstacle_Box prefab with red material

**CHECKPOINT:** Basic scene set up with managers and prefabs!

---

### **HOUR 3: Wire Everything Together** (2:00 - 3:00)

#### Step 11: Configure InfiniteTerrainManager (10 min)

1. Select InfiniteTerrainManager in Hierarchy
2. Inspector settings:
   - Terrain Chunk Prefab: Drag TerrainChunk prefab
   - Chunks Ahead: 5
   - Chunks Behind: 2
   - Chunk Length: 50
   - Recycle Distance: 100

✅ **Verify:** All fields assigned (no "None" fields)

#### Step 12: Configure ObstacleSpawner (10 min)

1. Select ObstacleSpawner in Hierarchy
2. Inspector:
   - Standard Obstacles → Size: 1
   - Element 0: Drag Obstacle_Box prefab
   - Base Spawn Chance: 0.5
   - Min Obstacle Spacing: 10
   - Max Obstacles Per Chunk: 3
   - Lane Positions → Size: 3
     - Element 0: -3
     - Element 1: 0
     - Element 2: 3

✅ **Verify:** Obstacle prefab assigned, lanes configured

#### Step 13: Configure WorldManager (10 min)

1. Select WorldManager
2. Inspector:
   - World Themes → Size: 1
   - Element 0: (We'll create this next)
   - Theme Change Distance: 1000
   - Starting Theme Index: 0

**Leave World Themes empty for now** - we'll create ScriptableObject next

✅ **Verify:** WorldManager configured (empty themes OK)

#### Step 14: Create First WorldTheme (15 min)

1. Right-click: Assets/ScriptableObjects/Themes/
2. Create → TreasureChase → World Theme
3. Rename: "Theme_Basic"
4. Inspector settings:
   ```
   Theme Name: "Basic"
   Description: "Starting theme"
   Unlock Distance: 0

   Visual Settings:
   - Terrain Material: Mat_Ground (drag from Materials folder)
   - Ambient Color: White (255, 255, 255)
   - Fog Color: Gray (128, 128, 128)
   - Fog Density: 0.01

   Audio:
   - Music Track: "music_main" (can be empty for now)
   - Ambient Sound Loop: "" (leave empty)

   Game Objects:
   - Theme Obstacles → Size: 1
     - Element 0: Obstacle_Box prefab
   - Theme Treasures: (leave empty)
   - Theme Decorations: (leave empty)

   Difficulty Modifiers:
   - Speed Multiplier: 1.0
   - Visibility Modifier: 1.0
   - Obstacle Spawn Multiplier: 1.0
   ```

5. Assign to WorldManager:
   - Select WorldManager
   - Drag Theme_Basic into World Themes array

✅ **Verify:** Theme_Basic created and assigned to WorldManager

#### Step 15: Link Player to Trackers (10 min)

**Problem:** Scripts need to find VehicleController, but we don't have it yet.

**Quick Fix - Create Placeholder:**

1. Select Player
2. Add Component → New Script
3. Name: "PlayerController"
4. Click Create and Add

5. Open PlayerController.cs (double-click)
6. Replace with:
```csharp
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float speed = 10f;
    public float moveSpeed = 5f;

    void Update()
    {
        // Auto-forward movement
        transform.Translate(Vector3.forward * speed * Time.deltaTime);

        // Left/Right movement
        float horizontal = Input.GetAxis("Horizontal");
        transform.Translate(Vector3.right * horizontal * moveSpeed * Time.deltaTime);
    }

    public float GetVelocity() { return speed; }
    public int GetCurrentLane() { return 0; }
    public bool IsJumping { get { return false; } }
    public bool HasAnyPowerUp() { return false; }
    public bool HasInvincibility { get { return false; } }
    public bool HasShield { get { return false; } }
    public void TakeDamage(int amount) { Debug.Log("Hit! Damage: " + amount); }
    public void ConsumeShield() { }
}
```

7. Save script
8. Wait for Unity to compile

✅ **Verify:** No compile errors, Player has PlayerController

#### Step 16: Configure DistanceTracker (5 min)

1. Select DistanceTracker
2. Inspector:
   - Starting Distance: 0
   - Distance Multiplier: 1
   - Milestone Interval: 100

✅ **Verify:** DistanceTracker configured

**CHECKPOINT:** All systems wired together!

---

### **HOUR 4: Test & Play!** (3:00 - 4:00)

#### Step 17: Create Camera Follow (10 min)

1. Select Main Camera
2. Transform:
   - Position: (0, 5, -10)
   - Rotation: (20, 0, 0)
3. Add Component → New Script: "CameraFollow"
4. Open CameraFollow.cs:

```csharp
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;
    public Vector3 offset = new Vector3(0, 5, -10);
    public float smoothSpeed = 5f;

    void Start()
    {
        if (target == null)
            target = GameObject.FindGameObjectWithTag("Player").transform;
    }

    void LateUpdate()
    {
        if (target == null) return;

        Vector3 desiredPosition = target.position + offset;
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, smoothSpeed * Time.deltaTime);
        transform.position = smoothedPosition;

        transform.LookAt(target);
    }
}
```

5. Save
6. Wait for compile

✅ **Verify:** Camera follows player

#### Step 18: Add Directional Light (5 min)

1. GameObject → Light → Directional Light
2. Transform:
   - Position: (0, 10, 0)
   - Rotation: (50, -30, 0)
3. Light:
   - Color: White
   - Intensity: 1

✅ **Verify:** Scene is well-lit

#### Step 19: FIRST PLAYTEST! (5 min)

1. Click **Play** button (top center)
2. Watch what happens:
   - Player should move forward automatically
   - Terrain chunks should spawn ahead
   - Camera should follow player
   - Obstacles should spawn on terrain

**Expected Behavior:**
- ✅ Player moves forward
- ✅ Terrain generates continuously
- ✅ Camera follows smoothly
- ✅ Console shows "Spawned obstacle" messages

**Common Issues:**
- ❌ Player falls through ground → Check Rigidbody is not kinematic
- ❌ No terrain spawns → Check InfiniteTerrainManager has prefab assigned
- ❌ Obstacles not spawning → Check ObstacleSpawner has obstacles assigned

3. Click **Play** again to stop

✅ **Verify:** Basic endless runner works!

#### Step 20: Add Arrow Key Controls (10 min)

Player should respond to arrow keys already (from PlayerController).

**Test:**
1. Click Play
2. Press **Left/Right Arrow Keys**
3. Player should move between lanes

✅ **Verify:** Player responds to input

#### Step 21: Test Obstacle Collision (10 min)

1. Play game
2. Run into an obstacle
3. Check Console for: "Hit! Damage: 1"

✅ **Verify:** Collision detection works

#### Step 22: Save Everything! (5 min)

1. File → Save
2. File → Save Project
3. Commit to Git (if using version control):
   ```bash
   git add .
   git commit -m "Initial Treasure Chase setup - basic endless runner working"
   ```

✅ **Verify:** Project saved

#### Step 23: Celebrate! (5 min)

**YOU DID IT!** 🎉

You now have:
- ✅ Working endless runner
- ✅ Infinite terrain generation
- ✅ Obstacle spawning
- ✅ Player movement
- ✅ Camera follow
- ✅ All manager systems in place

**Take a screenshot/video of your working game!**

---

## 🎯 WHAT YOU ACCOMPLISHED TODAY

### **Technical:**
- ✅ Set up Unity project
- ✅ Imported all 12 scripts
- ✅ Created 7 manager systems
- ✅ Built terrain generation
- ✅ Built obstacle spawning
- ✅ Implemented player movement
- ✅ Configured camera follow

### **Systems Working:**
- ✅ InfiniteTerrainManager (chunks spawn/recycle)
- ✅ ObstacleSpawner (obstacles appear on terrain)
- ✅ Basic player controller
- ✅ Collision detection
- ✅ WorldManager (basic theme)

### **Not Yet Working (OK for Day 1):**
- ⏳ Score display (no UI yet)
- ⏳ Distance tracking display
- ⏳ Power-ups
- ⏳ Treasures
- ⏳ Game over screen
- ⏳ Theme switching
- ⏳ Tournaments

**These are ALL scheduled for Week 2-3!**

---

## 📅 TOMORROW (Day 2)

### **Goal:** Add UI and scoring

**Tasks (2 hours):**
1. Create HUD Canvas
2. Wire up EndlessHUD script
3. Display score/distance/multiplier
4. Test score counting
5. Add floating score texts

**Guide:** Follow UI_AND_SCRIPTABLEOBJECTS_SETUP_GUIDE.md

---

## 🚨 TROUBLESHOOTING

### **Issue: Scripts have compile errors**
**Cause:** Missing dependencies (AudioManager, etc.)

**Solution A - Quick Fix:**
Create stub scripts:

```csharp
// AudioManager.cs
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance;
    void Awake() { Instance = this; }
    public void PlaySFX(string name, float volume = 1f, float pitch = 1f) { }
    public void PlayMusic(string name, float fadeTime = 1f) { }
}

// CameraController.cs
public class CameraController : MonoBehaviour
{
    public static CameraController Instance;
    void Awake() { Instance = this; }
    public void ShakeLight() { }
    public void ShakeMedium() { }
    public void ShakeHeavy() { }
    public void Shake(float intensity, float duration) { }
    public void FlashColor(UnityEngine.Color color, float duration) { }
    public void FadeToBlack(float duration) { }
    public void FadeFromBlack(float duration) { }
}

// ParticleEffectManager.cs
public class ParticleEffectManager : MonoBehaviour
{
    public static ParticleEffectManager Instance;
    void Awake() { Instance = this; }
    public void PlayEffect(string name, UnityEngine.Vector3 position) { }
    public void SetAmbientParticles(GameObject particles) { }
}

// EconomyManager.cs
public class EconomyManager : MonoBehaviour
{
    public void AddCoins(int amount) { }
    public void SpendCoins(int amount) { }
    public int GetCoins() { return 0; }
    public void AddGems(int amount) { }
}

// GameFeelManager.cs
public class GameFeelManager : MonoBehaviour
{
    public static GameFeelManager Instance;
    void Awake() { Instance = this; }
    public void HitFreeze(float duration) { }
}
```

Add these to Assets/Scripts/ and attach to GameManager objects.

**Solution B - Import from Treasure Multiplier:**
Copy the real scripts from your Treasure Multiplier project.

### **Issue: Player falls through ground**
- Check Rigidbody → Is Kinematic is **unchecked**
- Check ground has Collider
- Check Physics → Edit → Project Settings → Physics → Auto Sync Transforms is checked

### **Issue: Terrain doesn't spawn**
- Check InfiniteTerrainManager has TerrainChunk prefab assigned
- Check TerrainChunk prefab has MeshRenderer
- Check Play mode - terrain spawns at runtime, not in edit mode

### **Issue: Obstacles don't spawn**
- Check ObstacleSpawner has obstacle prefabs assigned
- Check Base Spawn Chance > 0
- Check obstacles have colliders with Is Trigger = true
- Check Console for "Spawned obstacle" messages

### **Issue: Camera doesn't follow**
- Check CameraFollow script is attached to Main Camera
- Check Player has "Player" tag
- Check Camera has clear view (not blocked)

---

## ✅ DAY 1 COMPLETION CHECKLIST

- [ ] Unity project created
- [ ] All scripts imported (12 files)
- [ ] No compile errors
- [ ] 7 manager GameObjects created
- [ ] Manager scripts attached
- [ ] Player capsule with PlayerController
- [ ] Ground plane
- [ ] TerrainChunk prefab created
- [ ] Obstacle_Box prefab created
- [ ] Theme_Basic ScriptableObject created
- [ ] InfiniteTerrainManager configured
- [ ] ObstacleSpawner configured
- [ ] WorldManager configured
- [ ] Camera follow working
- [ ] Game plays in editor
- [ ] Player moves forward automatically
- [ ] Player responds to arrow keys
- [ ] Terrain spawns continuously
- [ ] Obstacles spawn on terrain
- [ ] Collision detection works
- [ ] Project saved

**Completion Time:** 2-4 hours

---

## 📸 PROOF OF PROGRESS

**Take these screenshots:**
1. Unity Project window showing all folders/scripts
2. Hierarchy showing all manager GameObjects
3. Play mode with player moving forward
4. Obstacles spawned on terrain
5. Console showing no errors

**Share in your dev log or social media!**

---

## 🎮 CONGRATULATIONS!

**You just built a working endless runner in ONE DAY!**

Most people spend WEEKS getting to this point. You did it in HOURS.

**Tomorrow you'll add UI and make it feel like a real game.**

**Keep going! You're 10% of the way to launch! 🚀**

---

*Created: 2026-01-26*
*Status: Day 1 Guide*
*Time Required: 2-4 hours*
*Difficulty: Beginner-Friendly*

**NOW GO BUILD! 🎮💪**
