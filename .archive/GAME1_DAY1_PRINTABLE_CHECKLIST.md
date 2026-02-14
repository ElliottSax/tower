# 📋 Game #1 - Day 1 Printable Checklist

**Print this page and check off items as you complete them!**

**Goal:** Playable prototype in 2-3 hours ⏱️

---

## ☐ Phase 1: Create Unity Project (15 min)

- [ ] Open Unity Hub
- [ ] Click "New Project"
- [ ] Select "2D Core" template
- [ ] Project name: `LootStackMayhem`
- [ ] Unity version: 2022.3 LTS or later
- [ ] Click "Create Project"
- [ ] Wait for Unity to open

**Expected:** Empty Unity project open

---

## ☐ Phase 2: Import MobileGameCore (15 min)

### Option A: Package Import
- [ ] In Unity: Window → Package Manager
- [ ] Click + → Add package from disk
- [ ] Navigate to `/mnt/e/projects/MobileGameCore/package.json`
- [ ] Click "Select"
- [ ] Wait for import

### Option B: Direct Import (if Package fails)
- [ ] Copy `/mnt/e/projects/MobileGameCore/Runtime` folder
- [ ] Paste into Unity `Assets/MobileGameCore`

### Verify Import
- [ ] Check Console window: Should say "All scripts compiled successfully"
- [ ] No red errors in Console

**Expected:** Zero compilation errors ✅

---

## ☐ Phase 3: Install Dependencies (10 min)

### Input System (REQUIRED)
- [ ] Window → Package Manager
- [ ] Packages dropdown: "Unity Registry"
- [ ] Find "Input System"
- [ ] Click "Install"
- [ ] Click "Yes" to restart Unity when prompted
- [ ] Unity restarts

**Expected:** Input System installed

### Firebase Analytics (OPTIONAL)
- [ ] Skip for now (can add later)
- [ ] AnalyticsManager works without it

---

## ☐ Phase 4: Create Folder Structure (5 min)

In Unity Project window, create:
- [ ] Assets/_Game/
- [ ] Assets/_Game/Scenes/
- [ ] Assets/_Game/Scripts/
- [ ] Assets/_Game/Scripts/Core/
- [ ] Assets/_Game/Scripts/Gameplay/
- [ ] Assets/_Game/Scripts/UI/
- [ ] Assets/_Game/Prefabs/
- [ ] Assets/_Game/Materials/

**Expected:** Organized folder structure

---

## ☐ Phase 5: Create Main Scene (5 min)

- [ ] Right-click Assets/_Game/Scenes
- [ ] Create → Scene
- [ ] Name: "MainGame"
- [ ] Double-click to open MainGame scene
- [ ] Delete default "Main Camera" (we'll add better one)

**Expected:** Empty MainGame scene open

---

## ☐ Phase 6: Copy Starter Scripts (15 min)

Open: `/mnt/e/projects/GAME1_STARTER_SCRIPTS.md`

Copy these 4 scripts:

### GameManager.cs
- [ ] Create: `Assets/_Game/Scripts/Core/GameManager.cs`
- [ ] Copy code from GAME1_STARTER_SCRIPTS.md
- [ ] Save
- [ ] Check Console: No errors

### TreasureSpawner.cs
- [ ] Create: `Assets/_Game/Scripts/Gameplay/TreasureSpawner.cs`
- [ ] Copy code from GAME1_STARTER_SCRIPTS.md
- [ ] Save
- [ ] Check Console: No errors

### Treasure.cs
- [ ] Create: `Assets/_Game/Scripts/Gameplay/Treasure.cs`
- [ ] Copy code from GAME1_STARTER_SCRIPTS.md
- [ ] Save
- [ ] Check Console: No errors

### GameUI.cs
- [ ] Create: `Assets/_Game/Scripts/UI/GameUI.cs`
- [ ] Copy code from GAME1_STARTER_SCRIPTS.md
- [ ] Save
- [ ] Check Console: No errors

**Expected:** All 4 scripts compiled successfully

---

## ☐ Phase 7: Create CoreSystems GameObject (10 min)

- [ ] Hierarchy → Right-click → Create Empty
- [ ] Name: "CoreSystems"
- [ ] Position: (0, 0, 0)

Add these components (Add Component → search by name):
- [ ] SaveSystem
- [ ] AnalyticsManager
- [ ] EconomyManager
- [ ] AudioManager
- [ ] AchievementSystem
- [ ] DailyChallengeSystem
- [ ] GameFeelManager
- [ ] TransitionManager
- [ ] AudioSynthesizer
- [ ] InputManager (set Input Mode: "Tilt")
- [ ] PerformanceProfiler (optional)

**Expected:** CoreSystems with 11 components

---

## ☐ Phase 8: Create Camera (5 min)

- [ ] Hierarchy → Right-click → Camera
- [ ] Name: "MainCamera"
- [ ] Tag: "MainCamera" (should be default)
- [ ] Add Component → EnhancedCameraController
- [ ] Set these values in Inspector:
  - [ ] Follow Speed: 5
  - [ ] Offset: (0, 2, -10)
  - [ ] Enable Shake: ✓ (checked)

**Expected:** Camera with EnhancedCameraController

---

## ☐ Phase 9: Create GameManager GameObject (5 min)

- [ ] Hierarchy → Create Empty
- [ ] Name: "GameManager"
- [ ] Position: (0, 0, 0)
- [ ] Add Component → GameManager (your script)

**Expected:** GameManager GameObject in scene

---

## ☐ Phase 10: Create TreasureSpawner GameObject (5 min)

- [ ] Hierarchy → Create Empty
- [ ] Name: "TreasureSpawner"
- [ ] Position: (0, 10, 0) ← spawns from above
- [ ] Add Component → TreasureSpawner (your script)
- [ ] Set in Inspector:
  - [ ] Spawn Interval: 0.5
  - [ ] Min X: -3
  - [ ] Max X: 3

**Expected:** TreasureSpawner at top of screen

---

## ☐ Phase 11: Create Ground Platform (5 min)

- [ ] Hierarchy → 2D Object → Sprites → Square
- [ ] Name: "Ground"
- [ ] Position: (0, -4, 0)
- [ ] Scale: (10, 1, 1)
- [ ] Add Component → Box Collider 2D
- [ ] Change Sprite Color: gray or brown

**Expected:** Visible ground platform

---

## ☐ Phase 12: Create UI Canvas (15 min)

### Create Canvas
- [ ] Hierarchy → UI → Canvas
- [ ] Canvas Scaler settings:
  - [ ] UI Scale Mode: "Scale With Screen Size"
  - [ ] Reference Resolution: 1080 x 1920
  - [ ] Match: 0.5
- [ ] Add Component → GameUI (your script)

### Create Score Text
- [ ] Right-click Canvas → UI → Text - TextMeshPro
  - [ ] (If prompted) Import TMP Essentials → click "Import"
- [ ] Name: "ScoreText"
- [ ] Anchor: Top-Center
- [ ] Position Y: -100
- [ ] Font Size: 72
- [ ] Alignment: Center
- [ ] Text: "0"

### Create Multiplier Text
- [ ] Right-click Canvas → UI → Text - TextMeshPro
- [ ] Name: "MultiplierText"
- [ ] Position Y: -200
- [ ] Font Size: 48
- [ ] Alignment: Center
- [ ] Text: "x1.0"

### Create High Score Text
- [ ] Right-click Canvas → UI → Text - TextMeshPro
- [ ] Name: "HighScoreText"
- [ ] Anchor: Top-Right
- [ ] Font Size: 36
- [ ] Text: "Best: 0"

### Link UI References
- [ ] Select Canvas
- [ ] Find GameUI component in Inspector
- [ ] Drag ScoreText → Score Text slot
- [ ] Drag MultiplierText → Multiplier Text slot
- [ ] Drag HighScoreText → High Score Text slot
- [ ] Combo Text: leave empty (optional)

**Expected:** Canvas with 3 text elements, all linked

---

## ☐ Phase 13: Configure Camera Follow (2 min)

- [ ] Select MainCamera
- [ ] Find EnhancedCameraController component
- [ ] Drag Ground GameObject → Follow Target slot

**Expected:** Camera will track gameplay area

---

## ☐ Phase 14: First Playtest! (5 min)

### Press Play ▶️

**You should see:**
- [ ] Treasures spawning from top
- [ ] Treasures falling down
- [ ] Treasures landing on ground
- [ ] Score increasing in UI
- [ ] Multiplier increasing in UI
- [ ] Screen shaking slightly on impact
- [ ] Particles appearing on landing
- [ ] Sound effects playing

**Check Console:**
- [ ] "[SaveSystem] Initialized"
- [ ] "[AnalyticsManager] Initialized..."
- [ ] "[GameManager] Game started!"
- [ ] No red errors

### Press F1
- [ ] Performance overlay appears
- [ ] Shows FPS, memory usage

**Expected:** WORKING GAME! 🎉

---

## ☐ Phase 15: Run Validation (Optional, 5 min)

- [ ] Copy ValidationScript.cs from `GAME1_DAY1_VALIDATION_SCRIPT.md`
- [ ] Create: `Assets/_Game/Scripts/Core/ValidationScript.cs`
- [ ] Add to any GameObject
- [ ] Press Play
- [ ] Press **P** key
- [ ] Check Console for validation results

**Expected:** All tests pass ✅

---

## ☐ Phase 16: Save Everything (2 min)

- [ ] File → Save (Ctrl+S / Cmd+S)
- [ ] File → Save Project

**Expected:** All changes saved

---

## 🎉 Day 1 Complete!

If you checked all boxes, congratulations! You have:

✅ Unity project set up
✅ MobileGameCore imported
✅ Scene configured
✅ All scripts working
✅ Playable prototype

---

## 📊 Quick Stats

**Time spent:** ___ hours
**Treasures spawned:** Press Play to see!
**Your high score:** ______

---

## 🐛 Troubleshooting Checklist

**If things aren't working, check:**

- [ ] Console window has no red errors
- [ ] All 4 starter scripts copied correctly
- [ ] CoreSystems has all MobileGameCore components
- [ ] GameManager GameObject exists in scene
- [ ] TreasureSpawner GameObject exists in scene
- [ ] Ground has Box Collider 2D
- [ ] Canvas has GameUI component
- [ ] UI text elements are linked in GameUI component
- [ ] Input System installed and Unity restarted

**Still stuck?**
→ Open: `/mnt/e/projects/GAME1_UNITY_SETUP_GUIDE.md` Troubleshooting section

---

## 📸 Screenshot Checklist (Optional)

Take screenshots of these milestones:

- [ ] First successful Play test
- [ ] First treasure spawning
- [ ] High score > 100
- [ ] High score > 1000
- [ ] Multiplier at max (5x)

---

## 🎯 Tomorrow (Day 2) Preview

**What you'll add:**
- [ ] More treasure variety
- [ ] Combo visual feedback
- [ ] Game over screen
- [ ] Restart button
- [ ] Main menu (optional)

**Reference:** `GAME1_QUICK_START_WITH_MOBILECORE.md` Day 2 section

---

## 💡 Pro Tips for Day 1

✅ **Test frequently** - Press Play after each major step
✅ **Check Console** - Helps catch errors early
✅ **Use F1** - See performance overlay anytime
✅ **Save often** - Ctrl+S / Cmd+S
✅ **Don't rush** - Better to do it right than fast
✅ **Have fun** - You're building a real game!

---

## 📞 Quick Reference

**Key GameObjects:**
- CoreSystems - MobileGameCore managers
- GameManager - Game logic
- TreasureSpawner - Spawns treasures
- MainCamera - With EnhancedCameraController
- Ground - Landing platform
- Canvas - UI system

**Key Scripts:**
- GameManager.cs - Game controller
- TreasureSpawner.cs - Treasure spawning
- Treasure.cs - Collectable behavior
- GameUI.cs - UI updates

**Keyboard Shortcuts:**
- **Play:** Ctrl+P / Cmd+P
- **Pause:** Ctrl+Shift+P / Cmd+Shift+P
- **Performance Overlay:** F1
- **Save:** Ctrl+S / Cmd+S

---

**PRINT THIS PAGE AND CHECK OFF AS YOU GO!** ✅

**Good luck! You've got this!** 🎮🚀

---

*Checklist for: Loot Stack Mayhem - Day 1*
*Estimated Time: 2-3 hours*
*Goal: Playable Prototype*
