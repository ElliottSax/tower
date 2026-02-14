# Loot Stack Mayhem - Unity Project Setup Guide

**Complete step-by-step instructions to set up your Unity project and start building.**

---

## Step 1: Create New Unity Project (5 minutes)

### 1.1 Unity Hub Setup
1. Open Unity Hub
2. Click **"New Project"**
3. Select **"2D Core"** template
4. Project name: `LootStackMayhem`
5. Location: Choose your workspace
6. Unity version: **2022.3 LTS** (recommended)
7. Click **"Create Project"**

### 1.2 Wait for Initial Setup
- Unity will open and create default folders
- Wait for compilation to complete

---

## Step 2: Import MobileGameCore (5 minutes)

### 2.1 Copy Package
```bash
# Copy MobileGameCore folder into your project
cp -r /mnt/e/projects/MobileGameCore /path/to/LootStackMayhem/Packages/
```

**OR** (Alternative: Direct Import)
```bash
# Copy Runtime folder directly to Assets
cp -r /mnt/e/projects/MobileGameCore/Runtime /path/to/LootStackMayhem/Assets/MobileGameCore
```

### 2.2 Verify Import
1. In Unity, check Console window
2. Should see: **"All scripts compiled successfully"**
3. If errors, see Troubleshooting section

### 2.3 Install Dependencies
**Unity Input System (Required):**
1. Window → Package Manager
2. Packages: Unity Registry
3. Find **"Input System"**
4. Click **"Install"**
5. Click **"Yes"** when asked to restart

**Firebase Analytics (Optional):**
- Only needed if you want real analytics
- MobileGameCore has graceful fallback
- Can add later

---

## Step 3: Project Structure Setup (5 minutes)

### 3.1 Create Folder Structure
In Unity Project window, create these folders:

```
Assets/
├── _Game/
│   ├── Scenes/
│   ├── Scripts/
│   │   ├── Core/
│   │   ├── Gameplay/
│   │   └── UI/
│   ├── Prefabs/
│   └── Materials/
└── MobileGameCore/ (already imported)
```

### 3.2 Create Main Scene
1. Right-click `Assets/_Game/Scenes`
2. Create → Scene
3. Name it **"MainGame"**
4. Double-click to open
5. Delete default "Main Camera" (we'll add a better one)

---

## Step 4: Set Up Core Systems (10 minutes)

### 4.1 Create CoreSystems GameObject
1. In Hierarchy, right-click → Create Empty
2. Name it **"CoreSystems"**
3. Position: (0, 0, 0)

### 4.2 Add MobileGameCore Components
Select CoreSystems GameObject, then click **"Add Component"** for each:

**Core Systems:**
- SaveSystem
- AnalyticsManager
- EconomyManager
- AudioManager
- AchievementSystem
- DailyChallengeSystem

**Effects & Polish:**
- GameFeelManager
- TransitionManager

**Procedural Generation:**
- AudioSynthesizer

**Debug:**
- PerformanceProfiler (optional, toggle with F1)

**Input:**
- InputManager (set to "Tilt" mode in inspector)

### 4.3 Create Camera
1. Hierarchy → Right-click → Camera
2. Name it **"MainCamera"**
3. Tag: "MainCamera" (should be default)
4. Add Component → **EnhancedCameraController**
5. Set these values in inspector:
   - Follow Target: (leave empty for now)
   - Follow Speed: 5
   - Offset: (0, 2, -10)
   - Enable Shake: ✓

---

## Step 5: Import Starter Scripts (10 minutes)

### 5.1 Create GameManager.cs
**Location:** `Assets/_Game/Scripts/Core/GameManager.cs`

Use the starter script from **GAME1_STARTER_SCRIPTS.md** (see GameManager.cs section below)

### 5.2 Create TreasureSpawner.cs
**Location:** `Assets/_Game/Scripts/Gameplay/TreasureSpawner.cs`

Use the starter script from **GAME1_STARTER_SCRIPTS.md**

### 5.3 Create Treasure.cs
**Location:** `Assets/_Game/Scripts/Gameplay/Treasure.cs`

Use the starter script from **GAME1_STARTER_SCRIPTS.md**

### 5.4 Create GameUI.cs
**Location:** `Assets/_Game/Scripts/UI/GameUI.cs`

Use the starter script from **GAME1_STARTER_SCRIPTS.md**

---

## Step 6: Set Up Game Objects (10 minutes)

### 6.1 Add GameManager
1. Create Empty GameObject: **"GameManager"**
2. Add Component → **GameManager** (your script)
3. Position: (0, 0, 0)

### 6.2 Add TreasureSpawner
1. Create Empty GameObject: **"TreasureSpawner"**
2. Add Component → **TreasureSpawner**
3. Position: (0, 10, 0) - spawns from above
4. In inspector, set:
   - Spawn Interval: 0.5
   - Min X: -3
   - Max X: 3

### 6.3 Create Ground
1. Hierarchy → 2D Object → Sprite → Square
2. Name it **"Ground"**
3. Position: (0, -4, 0)
4. Scale: (10, 1, 1)
5. Add Component → **Box Collider 2D**
6. Change Sprite Color: (gray or brown)

### 6.4 Create UI Canvas
1. Hierarchy → UI → Canvas
2. Canvas Scaler settings:
   - UI Scale Mode: "Scale With Screen Size"
   - Reference Resolution: 1080 x 1920
   - Match: 0.5 (width/height balanced)
3. Add Component → **GameUI** (your script)

### 6.5 Create UI Text Elements
**Inside Canvas, create:**

**Score Text:**
1. Right-click Canvas → UI → Text - TextMeshPro
2. Name: "ScoreText"
3. Position: Top-center (Anchor: Top, Pos Y: -100)
4. Font Size: 72
5. Alignment: Center
6. Text: "0"

**Multiplier Text:**
1. UI → Text - TextMeshPro
2. Name: "MultiplierText"
3. Position: Below score (Pos Y: -200)
4. Font Size: 48
5. Text: "x1.0"

**High Score Text:**
1. UI → Text - TextMeshPro
2. Name: "HighScoreText"
3. Position: Top-right corner
4. Font Size: 36
5. Text: "Best: 0"

### 6.6 Link UI References
1. Select Canvas (with GameUI component)
2. Drag UI elements to inspector slots:
   - Score Text → ScoreText
   - Multiplier Text → MultiplierText
   - High Score Text → HighScoreText

---

## Step 7: Configure Camera (5 minutes)

### 7.1 Set Camera Follow Target
1. Select MainCamera
2. Find **EnhancedCameraController** component
3. Drag **Ground** GameObject to "Follow Target"
4. This will center the camera on gameplay area

---

## Step 8: Test the Game (5 minutes)

### 8.1 First Playtest
1. Press **Play** button
2. **Expected behavior:**
   - Treasures spawn from top
   - They fall and land on ground
   - Score increases on landing
   - Multiplier increases
   - Screen shakes on impact
   - Particles appear
   - Sound effects play

### 8.2 Verify Systems
**Check Console for:**
```
[SaveSystem] Initialized
[AnalyticsManager] Initialized (or fallback mode)
[GameManager] Game started
```

**Visual checks:**
- ✅ Treasures are procedurally generated (coins, gems, etc.)
- ✅ Particles spawn on landing
- ✅ Camera shakes slightly
- ✅ UI updates with score

### 8.3 Press F1
- Performance overlay should appear
- Shows FPS, memory usage

---

## Step 9: Build Settings (Optional, 5 minutes)

### 9.1 Add Scene to Build
1. File → Build Settings
2. Click **"Add Open Scenes"**
3. MainGame should appear in list

### 9.2 Set Platform
**For Android:**
1. Select Android in Platform list
2. Click **"Switch Platform"** (takes a few minutes)

**For iOS:**
1. Select iOS
2. Click **"Switch Platform"**
3. Requires Mac for building

---

## Step 10: Customize & Polish (Ongoing)

### 10.1 Tune Gameplay Values
**In TreasureSpawner:**
- Adjust spawn interval (faster = harder)
- Change spawn position range
- Add more treasure types

**In Treasure.cs:**
- Adjust point values
- Change mass (heavier = harder impacts)
- Tune multiplier increase rate

**In GameFeelManager (CoreSystems):**
- Hit freeze duration
- Shake intensity
- Particle spawn rates

### 10.2 Add More Features
**Week 1 additions:**
- Game over screen
- Restart button
- Pause menu
- Settings screen
- Tutorial overlay

**Week 2 additions:**
- Unity Ads integration (use AdManager)
- Upgrade shop (use EconomyManager)
- Achievements (already set up!)
- Daily challenges (already set up!)

---

## Troubleshooting

### "Type MobileGameCore.SaveSystem not found"
**Solution:** Make sure you imported MobileGameCore correctly. Check that files are in `Assets/MobileGameCore/` or `Packages/MobileGameCore/`

### "Input System not found"
**Solution:** Window → Package Manager → Install "Input System", restart Unity

### "No sound playing"
**Solution:** AudioSynthesizer generates sounds procedurally. Make sure AudioSynthesizer component is on CoreSystems GameObject.

### "Particles not visible"
**Solution:** Make sure you have a Main Camera tagged as "MainCamera"

### "Treasures not falling"
**Solution:** Make sure Treasure.cs adds Rigidbody2D component in Awake(). Check Gravity Scale is > 0 (default: 1)

### "Compilation errors on import"
**Solution:**
1. Close Unity
2. Delete `Library` folder in project
3. Reopen Unity (will reimport everything)

---

## Next Steps

**You now have:**
- ✅ Complete Unity project setup
- ✅ MobileGameCore integrated
- ✅ Basic gameplay working
- ✅ UI functional
- ✅ All core systems active

**Day 1 Complete!** (should take 1-2 hours total)

**Tomorrow (Day 2):**
- Add more treasure types
- Create combo system
- Add visual polish
- Create main menu
- Add sound effects

**See GAME1_QUICK_START_WITH_MOBILECORE.md for Day 2-4 plan**

---

## Quick Reference

**Key GameObjects:**
- CoreSystems - All MobileGameCore managers
- GameManager - Game logic controller
- TreasureSpawner - Spawns collectables
- MainCamera - With EnhancedCameraController
- Ground - Landing platform
- Canvas - UI system

**Key Scripts:**
- GameManager.cs - Main game controller
- TreasureSpawner.cs - Treasure generation
- Treasure.cs - Collectable behavior
- GameUI.cs - UI updates

**Testing:**
- Play button - Test gameplay
- F1 - Performance overlay
- Check Console - System status

---

**YOU'RE READY TO BUILD!** 🎮🚀

Start with Step 1 and work through each section. By Step 8, you'll have a playable prototype!
