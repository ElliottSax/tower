# ⚡ DAY 1 QUICK CHECKLIST

**Print this or keep it on your second monitor!**

---

## 📋 HOUR 1: PROJECT SETUP

### Unity Project
- [ ] Create new 3D (URP) project: "TreasureChase"
- [ ] Wait for Unity to open

### Folder Structure
- [ ] Assets/Scenes/
- [ ] Assets/Scripts/Endless/
- [ ] Assets/Scripts/Obstacles/
- [ ] Assets/Scripts/UI/
- [ ] Assets/Scripts/ScriptableObjects/
- [ ] Assets/Prefabs/Terrain/
- [ ] Assets/Prefabs/Obstacles/
- [ ] Assets/Materials/
- [ ] Assets/ScriptableObjects/Themes/

### Copy Scripts (12 files)
- [ ] InfiniteTerrainManager.cs → Scripts/Endless/
- [ ] DistanceTracker.cs → Scripts/Endless/
- [ ] EndlessScoreManager.cs → Scripts/Endless/
- [ ] ObstacleSpawner.cs → Scripts/Obstacles/
- [ ] Obstacle.cs → Scripts/Obstacles/
- [ ] WorldManager.cs → Scripts/Endless/
- [ ] GhostRecorder.cs → Scripts/Endless/
- [ ] TournamentManager.cs → Scripts/Endless/
- [ ] EndlessTutorial.cs → Scripts/Endless/
- [ ] EndlessHUD.cs → Scripts/UI/
- [ ] GameOverUI.cs → Scripts/UI/
- [ ] WorldThemeTemplate.cs → Scripts/ScriptableObjects/

### Import TextMesh Pro
- [ ] Window → TextMeshPro → Import TMP Essential Resources

### Save Scene
- [ ] File → Save As → "Gameplay" → Assets/Scenes/

---

## 📋 HOUR 2: SCENE SETUP

### Create Managers (Hierarchy)
- [ ] Create Empty: "--- GAME MANAGERS ---"
- [ ] Under GAME MANAGERS:
  - [ ] InfiniteTerrainManager + script
  - [ ] DistanceTracker + script
  - [ ] EndlessScoreManager + script
  - [ ] ObstacleSpawner + script
  - [ ] WorldManager + script
  - [ ] GhostRecorder + script
  - [ ] TournamentManager + script

### Create Player
- [ ] Create → 3D Object → Capsule
- [ ] Rename: "Player"
- [ ] Position: (0, 1, 0)
- [ ] Add Rigidbody (not kinematic)
- [ ] Tag: "Player"

### Create Ground
- [ ] Create → 3D Object → Plane
- [ ] Rename: "StartingGround"
- [ ] Scale: (10, 1, 10)

### TerrainChunk Prefab
- [ ] Create Cube → "TerrainChunk"
- [ ] Scale: (10, 0.2, 50)
- [ ] Create Material: "Mat_Ground"
- [ ] Drag to Prefabs/Terrain/
- [ ] Delete from Hierarchy

### Obstacle Prefab
- [ ] Create Cube → "Obstacle_Box"
- [ ] Scale: (2, 2, 2)
- [ ] Add Box Collider (Is Trigger ✓)
- [ ] Add Obstacle script
- [ ] Create Material: "Mat_Obstacle" (Red)
- [ ] Tag: "Obstacle"
- [ ] Drag to Prefabs/Obstacles/
- [ ] Delete from Hierarchy

---

## 📋 HOUR 3: CONFIGURE

### InfiniteTerrainManager
- [ ] Terrain Chunk Prefab: TerrainChunk
- [ ] Chunks Ahead: 5
- [ ] Chunks Behind: 2
- [ ] Chunk Length: 50

### ObstacleSpawner
- [ ] Standard Obstacles → Size: 1 → Obstacle_Box
- [ ] Base Spawn Chance: 0.5
- [ ] Min Obstacle Spacing: 10
- [ ] Lane Positions: [-3, 0, 3]

### Create Theme_Basic
- [ ] Right-click ScriptableObjects/Themes/
- [ ] Create → TreasureChase → World Theme
- [ ] Name: "Theme_Basic"
- [ ] Theme Name: "Basic"
- [ ] Terrain Material: Mat_Ground
- [ ] Theme Obstacles: Obstacle_Box

### WorldManager
- [ ] World Themes → Size: 1 → Theme_Basic
- [ ] Theme Change Distance: 1000

### Create PlayerController Script
- [ ] Select Player → Add Component → New Script: "PlayerController"
- [ ] Copy code from guide
- [ ] Save & wait for compile

---

## 📋 HOUR 4: TEST!

### Camera Follow
- [ ] Main Camera Position: (0, 5, -10)
- [ ] Main Camera Rotation: (20, 0, 0)
- [ ] Add Component → New Script: "CameraFollow"
- [ ] Copy code from guide

### Lighting
- [ ] GameObject → Light → Directional Light
- [ ] Position: (0, 10, 0)
- [ ] Rotation: (50, -30, 0)

### PLAYTEST
- [ ] Click Play button
- [ ] Player moves forward? ✓
- [ ] Terrain spawns? ✓
- [ ] Camera follows? ✓
- [ ] Obstacles spawn? ✓
- [ ] Arrow keys work? ✓
- [ ] Collision detection? ✓

### Save Everything
- [ ] File → Save
- [ ] File → Save Project
- [ ] Git commit (optional)

---

## ✅ SUCCESS CRITERIA

**You're done when:**
1. ✅ Game plays without errors
2. ✅ Player moves forward automatically
3. ✅ Player moves left/right with arrow keys
4. ✅ Terrain chunks spawn continuously
5. ✅ Obstacles appear on terrain
6. ✅ Console shows "Hit! Damage: 1" on collision
7. ✅ Camera follows player smoothly

---

## 🚨 QUICK TROUBLESHOOTING

**Player falls through ground:**
→ Rigidbody: Is Kinematic = OFF

**No terrain spawns:**
→ Check InfiniteTerrainManager has prefab assigned

**Obstacles don't spawn:**
→ Check ObstacleSpawner has Obstacle_Box in array

**Camera doesn't move:**
→ Check Player has "Player" tag

**Compile errors:**
→ Create stub AudioManager/CameraController scripts (see full guide)

---

## 📞 IF STUCK

1. Check Console for specific errors
2. Read full guide: DAY_1_START_BUILDING_NOW.md
3. Verify all checkboxes above are complete
4. Take a 5-minute break and try again

---

**TIME BUDGET:**
- Hour 1: Setup (60 min)
- Hour 2: Scene (60 min)
- Hour 3: Configure (60 min)
- Hour 4: Test (60 min)
- **Total: 4 hours max**

**GO! 🚀**
