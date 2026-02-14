# ✅ DAY 2 QUICK CHECKLIST

**Print and check off as you go!**

---

## ⚙️ SETUP (5 min)

- [ ] Day 1 working (endless runner plays)
- [ ] Unity project open
- [ ] Scene saved from yesterday

---

## 🎯 HOUR 1: COLLISION & GAME OVER (35 min)

### GameStateManager
- [ ] Create GameStateManager.cs script
- [ ] Copy code from guide
- [ ] Create empty GameObject named "GameStateManager"
- [ ] Add GameStateManager component
- [ ] Test: Console shows "Game Started!" when playing

### PlayerController Collision
- [ ] Open PlayerController.cs
- [ ] Add collision variables (obstacleLayer, deathParticles)
- [ ] Add OnTriggerEnter() method
- [ ] Add Die() method
- [ ] Update Update() to check game state
- [ ] Save script

### Tag Obstacles
- [ ] Open Obstacle_Box prefab
- [ ] Create "Obstacle" tag if needed
- [ ] Set prefab tag to "Obstacle"
- [ ] Verify Box Collider "Is Trigger" is checked
- [ ] Save prefab

### Test
- [ ] Press Play
- [ ] Hit obstacle
- [ ] Console shows "Game Over!"
- [ ] Game freezes

---

## 🎨 HOUR 2: HUD CREATION (40 min)

### Delete Old UI
- [ ] Delete old DistanceText from Canvas

### Create HUD Panel
- [ ] Canvas → UI → Panel
- [ ] Name: HUD_Panel
- [ ] Color: Transparent (Alpha = 0)

### Distance Display
- [ ] HUD_Panel → UI → Image (name: DistanceBackground)
- [ ] Anchor top-left, Position X=150 Y=-50
- [ ] Size 200x60, Color black (Alpha=180)
- [ ] Add child Text-TMP: "DistanceText"
- [ ] Font size 36, Center align, White
- [ ] Text: "0 m"

### Coin Display
- [ ] Duplicate DistanceBackground
- [ ] Name: CoinBackground
- [ ] Position X=400 Y=-50
- [ ] Update text to: "💎 0"

### Score Display
- [ ] HUD_Panel → UI → Text-TMP (name: ScoreText)
- [ ] Anchor top-center, Y=-100
- [ ] Font size 48, Yellow, outline enabled
- [ ] Text: "0"

### Multiplier Display
- [ ] HUD_Panel → UI → Text-TMP (name: MultiplierText)
- [ ] Anchor top-center, Y=-180
- [ ] Font size 32, Orange
- [ ] Text: "x1.0"
- [ ] Alpha: 0

### HUD Controller
- [ ] Create SimpleHUDController.cs
- [ ] Copy code from guide
- [ ] Select Canvas
- [ ] Add Component → SimpleHUDController
- [ ] Assign all 4 text fields (drag from hierarchy)

### Test HUD
- [ ] Press Play
- [ ] Distance updates
- [ ] Score increases
- [ ] All text visible

---

## 💀 HOUR 3: GAME OVER SCREEN (50 min)

### Create Panel
- [ ] Canvas → UI → Panel (name: GameOverPanel)
- [ ] Color: Black (Alpha=220)
- [ ] Set Active: FALSE

### Add Title
- [ ] GameOverPanel → UI → Text-TMP
- [ ] Name: GameOverTitle
- [ ] Text: "GAME OVER"
- [ ] Font size 72, Red, outline enabled
- [ ] Position Y=200

### Add Stats
- [ ] Create FinalScoreText (Y=80, size 48, yellow)
- [ ] Create FinalDistanceText (Y=20, size 48, white)
- [ ] Create FinalCoinsText (Y=-40, size 48, cyan)
- [ ] Create BestScoreText (Y=-120, size 36, gold)

### Add Restart Button
- [ ] GameOverPanel → UI → Button-TMP
- [ ] Name: RestartButton
- [ ] Position Y=-220, Size 300x80
- [ ] Color: Green
- [ ] Update text: "RESTART" (size 40, white)

### Game Over Controller
- [ ] Create GameOverController.cs
- [ ] Copy code from guide
- [ ] Select Canvas
- [ ] Add Component → GameOverController
- [ ] Assign GameOverPanel
- [ ] Assign all 4 text fields
- [ ] Assign RestartButton

### Test Game Over
- [ ] Press Play
- [ ] Hit obstacle
- [ ] Game Over panel appears
- [ ] Stats show correctly
- [ ] Click Restart
- [ ] Scene reloads

---

## ✨ HOUR 4: POLISH (60 min)

### Pause Button (Optional)
- [ ] HUD_Panel → UI → Button-TMP
- [ ] Name: PauseButton
- [ ] Top-right anchor, X=-80 Y=-50
- [ ] Text: "||"
- [ ] Hook up OnClick to pause function

### Death Particles
- [ ] Create Particle System (name: DeathExplosion)
- [ ] Configure: Red, 50 particles, Speed 5
- [ ] Set inactive
- [ ] Save as Prefabs/Effects/DeathExplosion
- [ ] Assign to Player's "Death Particles" field

### Improve Movement
- [ ] Open PlayerController.cs
- [ ] Update lane switching code (from guide)
- [ ] Add AnimationCurve for smooth movement
- [ ] Test: Movement feels snappier

### Sound Hooks (Optional)
- [ ] Add AudioClip variables to PlayerController
- [ ] Add AudioSource component code
- [ ] Add PlayOneShot() calls in movement/death
- [ ] (Can assign sounds later)

### Final Testing
- [ ] Complete gameplay: start → play → die → restart
- [ ] Left/Right arrows work smoothly
- [ ] Distance/score update correctly
- [ ] Collision works
- [ ] Game over shows stats
- [ ] Restart works
- [ ] Best score saves

---

## 💾 SAVE & COMMIT

- [ ] File → Save Scene
- [ ] File → Save Project
- [ ] Git commit: "Day 2 complete"

---

## 🎉 DAY 2 COMPLETE!

**YOU NOW HAVE:**
- ✅ Complete game loop
- ✅ Professional UI
- ✅ Game over system
- ✅ Restart functionality
- ✅ Polish and particles

**PROGRESS: 40% COMPLETE! 🚀**

---

## 🚀 TOMORROW: DAY 3

**You'll add:**
- Collectible coins/treasures
- Power-ups (magnet, shield)
- Jump mechanic
- Particle effects
- Score multipliers

**Get excited! 🎮**

---

**Total Time: 3-4 hours**
**Files Created: 3 scripts + complete UI**
**Game Status: Fully playable with loop!**
