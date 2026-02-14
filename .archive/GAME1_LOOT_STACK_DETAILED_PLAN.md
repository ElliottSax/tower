# Game #1: Loot Stack Mayhem
## Complete Game Design Document (GDD)

**Version:** 1.0
**Date:** 2026-01-26
**Platform:** iOS + Android
**Engine:** Unity 2022.3 LTS
**Timeline:** 8 weeks (Week 3-10 of master plan)
**Target Launch:** End of Month 2

---

## 📋 Executive Summary

**High Concept:**
"Tetris meets Jenga with treasure physics"

**Elevator Pitch:**
Stack falling treasures as high as possible without toppling. Each treasure type has unique physics (heavy gold bars, bouncy gems, sticky slime chests). Precision placement + physics chaos = addictive one-more-try gameplay.

**Target Audience:**
- Primary: Ages 13-35
- Secondary: Casual mobile gamers
- Tertiary: Physics puzzle fans

**Monetization:**
- Rewarded ads (undo last drop, start with bonus)
- Interstitial ads (every 3-4 games)
- IAP: cosmetic treasure skins, ad removal ($2.99)

**Success Metrics:**
- D1 Retention: >40%
- D7 Retention: >20%
- Session Length: >5 minutes
- ARPU (30 days): $0.12-0.20

---

## 🎮 Core Gameplay

### Game Loop (60-Second Session)

1. **Treasure appears at top** (random type, shown in preview)
2. **Player taps screen** to drop treasure
3. **Treasure falls** and lands on stack
4. **Physics settle** (1-2 seconds)
5. **Check stability:** Stack balanced? Continue. Stack toppled? Game Over.
6. **Score increases** based on height
7. **Multiplier grows** (combo meter)
8. **Repeat** until stack falls

### Core Mechanics

**1. Treasure Types (6 Total)**

| Type | Physics | Weight | Size | Special Property |
|------|---------|--------|------|-----------------|
| Coin | Flat | Light | Small | Slides easily |
| Gold Bar | Rectangular | Heavy | Medium | Stable base |
| Gem | Octahedron | Medium | Small | Bouncy |
| Diamond | Multi-faceted | Light | Tiny | Unpredictable roll |
| Chest | Box | Heavy | Large | Stackable lid |
| Slime Blob | Soft body | Light | Medium | Sticky (high friction) |

**2. Stacking Physics**

- **Unity Physics2D** for simulation
- **Center of Mass calculation** every frame
- **Stability threshold:** 30 degrees tilt = warning, 45 degrees = game over
- **Friction values:** Varied per treasure (0.3 to 0.8)
- **Bounciness:** Gems = 0.6, others = 0.1
- **Sleep after 2 seconds** (physics optimization)

**3. Scoring System**

```
Base Score = Stack Height (cm)
Points per Drop = Base Score × Multiplier × Treasure Value

Treasure Values:
- Coin: 1x
- Gold Bar: 2x
- Gem: 3x
- Diamond: 5x
- Chest: 4x
- Slime Blob: 2x

Multiplier:
- Starts at 1.0x
- +0.1x per successful drop
- Caps at 5.0x
- Resets on game over
- Bonus: Perfect center placement = +0.5x instant
```

**4. Drop Mechanic**

- **Tap anywhere** to drop (not drag)
- **Treasure appears** at random X position at screen top
- **Preview next treasure** (shown in corner)
- **Hold to see trajectory?** NO (too easy, remove challenge)
- **No lateral movement** (pure vertical drop)

**5. Camera System**

- **Starts**: Bottom of screen
- **Zooms out** as stack grows taller
- **Max zoom**: 3x starting view
- **Smooth follow**: SmoothDamp, 0.3 second lag
- **Screenshake**: On treasure land (0.1 intensity)

---

## 🎨 Visual Design

### Art Style

**Theme:** Cartoon treasure / pirate fantasy
**Color Palette:**
- Gold: #FFD700
- Silver: #C0C0C0
- Gem colors: Ruby red, sapphire blue, emerald green, amethyst purple
- Background: Deep ocean blue gradient (#001F3F → #0074D9)

### Procedural Generation

**Treasure Models** (from Treasure Multiplier project):
- Coin: Cylinder (0.5m diameter, 0.1m thick)
- Gold Bar: Beveled prism (0.4m × 0.2m × 0.15m)
- Gem: Octahedron (0.25m)
- Diamond: Multi-faceted (0.15m)
- Chest: Box with lid (0.5m × 0.4m × 0.35m)
- Slime Blob: Soft sphere (0.35m) with vertex wobble

**Materials:**
- Metallic shader for gold/silver
- Emissive glow for gems
- Procedural noise texture for slime
- Vertex colors for variety

**Effects:**
- Sparkle particles on landing
- Dust puff when treasure settles
- Screen shake on heavy drops
- Glow pulse on perfect placement
- Treasure wobble animation (juice)

### UI Design

**Main Screen:**
```
┌─────────────────────────────┐
│  ⭐ Best: 24.5m  💰 1,234   │ ← Top Bar
├─────────────────────────────┤
│                             │
│      [Next: 💎]             │ ← Preview (top right)
│                             │
│                             │
│         🪙                  │
│        ╱│╲                 │
│       📦📦                  │
│      ╱────╲                │ ← Game Area
│     │ 💰💰 │               │
│     └──────┘               │
│   ════════════              │ ← Ground
│                             │
│  Height: 2.4m  x3.2        │ ← Stats Bar
└─────────────────────────────┘
│   [⏸ Pause]  [🔊]           │ ← Bottom buttons
```

**Font:** Bold, rounded sans-serif (Fredoka One style)

---

## 🎵 Audio Design

### Sound Effects (Procedural from AudioSynthesizer)

| Event | Sound | Parameters |
|-------|-------|------------|
| Treasure Drop | Whoosh | Frequency sweep 1000→200Hz, 0.2s |
| Treasure Land (Light) | Tap | 800Hz sine, 0.1s, low volume |
| Treasure Land (Heavy) | Thud | 200Hz triangle, 0.3s, high volume |
| Stack Wobble | Creak | 400Hz sawtooth, 0.5s, modulated |
| Game Over (Fall) | Crash | White noise burst, 1.0s |
| Perfect Placement | Ding | 1200Hz sine, 0.2s |
| Multiplier Up | Chime | Chord (C-E-G), 0.3s |
| New High Score | Fanfare | Melody (C-E-G-C), 1.0s |
| UI Button | Click | 1000Hz square, 0.05s |
| Coin Collect | Coin | 880Hz ding, 0.15s |

### Music

**Background Music:**
- **Menu:** Upbeat pirate shanty (120 BPM, major key)
- **Gameplay:** Tension-building loop (gradually adds instruments as stack grows)
- **Game Over:** Sad trombone (comedic defeat)

**Implementation:**
- Use AudioSynthesizer for simple loops
- OR free royalty-free tracks (YouTube Audio Library)
- Volume: Music 60%, SFX 80% (adjustable in settings)

---

## 📱 User Interface Flow

### Screen Flow

```
[Splash Screen]
     ↓
[Main Menu] ──→ [Settings]
     ↓          ↓
[Tutorial?]    [About]
     ↓
[Game] ──→ [Pause Menu] ──→ [Resume / Quit]
     ↓
[Game Over] ──→ [Retry / Menu]
     ↓
[Leaderboard]
```

### Main Menu

**Elements:**
- Studio logo (fade in)
- Game title (bounce in)
- "Tap to Play" button (pulse animation)
- High score display
- Coin balance (top right)
- Settings gear (top left)
- "More Games" button (bottom)

**First Launch Only:**
- Tutorial button (auto-shown)
- "Skip Tutorial" option

### Gameplay HUD

**Top Bar:**
- Current height (meters)
- High score indicator
- Coin balance
- Pause button

**Center:**
- Stack visualization
- Next treasure preview (corner)

**Bottom:**
- Current multiplier (x2.5)
- Score this session
- Perfect placement streak indicator

**Warning Indicator:**
- Yellow border flash when tilt >30°
- Red pulsing border when tilt >40°
- Vibration on mobile (if enabled)

### Game Over Screen

**Elements:**
- "Game Over" title (shake in)
- Final stats:
  - Height achieved
  - Score
  - Best height (if new record: confetti!)
  - Coins earned
  - Treasures stacked
- Buttons:
  - "Play Again" (large, centered)
  - "Watch Ad" to continue (50% off, one-time)
  - "Main Menu" (small)
- Ad placement (interstitial, every 3rd game)

### Pause Menu

**Elements:**
- "Paused" title
- Current game stats (height, score)
- Buttons:
  - Resume
  - Restart
  - Settings
  - Main Menu
- Background: Blurred game view

---

## 🏆 Progression System

### Player Levels (XP System)

**XP Gain:**
- 1 XP per meter of height
- Bonus XP for multiplier (10 XP per 1.0x)
- Daily login bonus (50 XP)
- Complete daily challenge (100 XP)

**Levels:**
- Level 1-10: 100 XP each
- Level 11-25: 200 XP each
- Level 26-50: 500 XP each
- Level 51+: 1000 XP each

**Level Rewards:**
- Every level: 50 coins
- Every 5 levels: Treasure skin unlock
- Every 10 levels: 500 coins + special skin
- Level 50: Golden treasure set + 5,000 coins

### Unlockables

**Treasure Skins (30 Total):**
- Default set (6 treasures)
- Wooden set (rustic)
- Crystal set (glowing)
- Rainbow set (colorful)
- Halloween set (spooky)
- Christmas set (festive)
- Unlock with coins or level rewards

**Background Themes (8 Total):**
- Ocean (default)
- Cave
- Sky
- Volcano
- Ice
- Space
- Rainbow
- Midnight
- Unlock: 1,000 coins each

**Ground Themes (6 Total):**
- Stone platform (default)
- Wooden deck
- Gold pile
- Ice block
- Lava rock
- Cloud
- Unlock: 500 coins each

### Achievements (25 Total)

| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| First Stack | Stack 5 treasures | 50 coins |
| Steady Hand | Stack 10 treasures | 100 coins |
| Tower Builder | Stack 20 treasures | 200 coins |
| Skyscraper | Reach 10m height | 150 coins |
| Space Race | Reach 25m height | 300 coins |
| To Infinity | Reach 50m height | 1,000 coins |
| Gold Hoarder | Collect 100 gold bars | 200 coins |
| Gem Master | Collect 100 gems | 200 coins |
| Diamond Eyes | Collect 50 diamonds | 300 coins |
| Perfect 10 | Get 10 perfect placements in a row | 500 coins |
| Multiplier King | Reach 5.0x multiplier | 250 coins |
| Survivor | Play 100 games | 200 coins |
| Marathon | Play for 30 minutes straight | 300 coins |
| Daily Grind | Complete 7 daily challenges | 500 coins |
| All Skins | Unlock all treasure skins | 2,000 coins |
| ... (10 more) | ... | ... |

### Daily Challenges (Rotates Daily)

**Challenge Types:**
1. Reach X meters height
2. Stack X treasures
3. Score X points
4. Get X perfect placements
5. Use only [treasure type]
6. Reach multiplier of X
7. Play X games
8. Stack X of [treasure type]

**Rewards:**
- Easy: 100 coins
- Medium: 250 coins
- Hard: 500 coins

**Streak Bonus:**
- Consecutive days: +50 coins per day
- Max 7-day streak: +350 coins bonus

---

## 💰 Economy & Monetization

### Currency System

**Coins (Soft Currency):**
- Earned: Gameplay (height × 10), achievements, daily challenges
- Spent: Treasure skins, themes, power-ups
- Balance target: 2,000-5,000 coins per hour of play

**Gems (Hard Currency):**
- Earned: Level rewards (rare), watching ads (5 gems)
- Spent: Exclusive skins, ad removal, continue game
- NOT required for progression

### Monetization Strategy

**1. Rewarded Ads (70% of revenue)**

**Placements:**
- Continue game after death (50 gems value, one-time per game)
- Double coin reward (post-game offer)
- Daily bonus coin (200 coins)
- Free gems (5 gems per ad, 5 max per day)

**Frequency Cap:**
- Max 1 per 3 minutes
- Max 10 per day
- No forced ads (player-initiated only)

**2. Interstitial Ads (20% of revenue)**

**Placements:**
- Every 3rd game over (skippable after 5 seconds)
- Returning to main menu from game (50% chance)

**Frequency Cap:**
- Max 1 per 5 minutes
- Never during first 3 games (onboarding)
- Never if player has IAP

**3. In-App Purchases (10% of revenue)**

| Product | Price | Contents |
|---------|-------|----------|
| Starter Pack | $0.99 | 1,000 coins + 50 gems |
| Coin Pack (Small) | $1.99 | 2,500 coins |
| Coin Pack (Medium) | $4.99 | 7,500 coins + 25 gems |
| Coin Pack (Large) | $9.99 | 20,000 coins + 100 gems |
| Remove Ads | $2.99 | Permanent ad removal |
| VIP Pass | $4.99/month | Ad-free, 2x coins, daily gems (20) |

**Expected ARPU:**
- Day 1: $0.02
- Day 7: $0.08
- Day 30: $0.15
- Non-payers: 80% (still profitable via ads)
- Payers: 20% (average spend $4.50)

### Power-Ups (Optional)

**Temporary Boosts:**
- Slow Motion (10s): Easier to time drops - 100 coins or 1 ad
- Stabilizer (3 drops): Less wobble - 150 coins or 1 ad
- Magnet (3 drops): Auto-center - 200 coins or 1 ad
- Safety Net (1 use): One free undo - 250 coins or 1 ad

**Strategy:**
- Unlocked after Tutorial
- Not required to enjoy game
- Accessible via gems or ads

---

## 🎓 Tutorial System

### First-Time User Experience (FTUE)

**Goals:**
- Teach core mechanic in <60 seconds
- Get player to first "aha!" moment
- Show progression hook

**Flow:**

**Step 1: Guided Drop (5 seconds)**
- Hand icon: "Tap to drop the treasure!"
- Single coin appears
- Player taps
- Coin lands on ground
- "Great!" feedback

**Step 2: Stack Building (15 seconds)**
- "Now stack 3 more!"
- Show next treasure preview
- Player drops 3 treasures
- Celebrate on 3rd stack

**Step 3: Physics Demo (10 seconds)**
- "Be careful! Unbalanced stacks fall!"
- Intentionally spawn heavy gold bar off-center
- Player drops it
- Stack wobbles (doesn't fall)
- "Nice save!"

**Step 4: Scoring Intro (10 seconds)**
- "Your score = stack height!"
- Show height meter
- "Higher stack = higher score!"

**Step 5: Multiplier Intro (10 seconds)**
- "Chain drops for bonus multiplier!"
- Show multiplier meter
- Player drops 2 more treasures
- "x2.0 Multiplier!"

**Step 6: Goal Setting (5 seconds)**
- "Try to reach 5 meters!"
- Continue until game over or 5m reached

**Step 7: End Tutorial (5 seconds)**
- "Tutorial Complete! +100 coins"
- "Now beat your record!"
- Unlock daily challenges

**Total Time:** ~60 seconds

**Skip Option:**
- "Skip Tutorial" button (top right)
- Confirm dialog: "Are you sure? (You'll miss rewards)"
- Still grants 100 coins if skipped

---

## 🎯 Analytics & Metrics

### Key Events to Track (Firebase)

**Session Events:**
- `app_open`
- `session_start`
- `session_end` (duration)
- `tutorial_begin`
- `tutorial_complete`

**Gameplay Events:**
- `game_start`
- `game_over` (height, score, treasures_stacked)
- `treasure_drop` (type, success/fail)
- `perfect_placement`
- `multiplier_reached` (value)
- `new_high_score` (height)

**Monetization Events:**
- `ad_impression` (type, placement)
- `ad_click`
- `ad_reward` (type, value)
- `iap_shown` (product_id)
- `iap_purchased` (product_id, price)

**Engagement Events:**
- `achievement_unlocked` (id)
- `daily_challenge_complete` (challenge_id)
- `skin_unlocked` (skin_id)
- `level_up` (new_level)

**User Properties:**
- `player_level` (1-100)
- `days_since_install` (1-365)
- `total_games_played` (0-999999)
- `highest_height` (meters)
- `has_made_purchase` (true/false)
- `ads_removed` (true/false)

### A/B Testing

**Test Variables:**
- Tutorial flow (short vs detailed)
- Ad frequency (every 2nd vs 3rd vs 4th game)
- Treasure spawn rate (6 types equal vs weighted)
- Multiplier cap (5.0x vs 10.0x)
- Coin earn rate (10 vs 15 vs 20 per meter)

**Success Metric:** D7 retention (primary), ARPU (secondary)

---

## 🛠️ Technical Implementation

### Week-by-Week Development Plan

**Week 1: Core Mechanic**
- [ ] Create Unity project
- [ ] Import MobileGameCore
- [ ] Implement treasure drop system
- [ ] Add Physics2D simulation
- [ ] Create 2D treasure prefabs (placeholder cubes)
- [ ] Add ground platform
- [ ] Camera follow system
- [ ] Basic scoring

**Week 2: Physics & Balance**
- [ ] Center of mass calculation
- [ ] Tilt detection (game over trigger)
- [ ] Friction/bounciness per treasure type
- [ ] Stack stability algorithm
- [ ] Physics optimization (sleep, fixed update)
- [ ] Screenshake on landing

**Week 3: Procedural Treasures**
- [ ] Import ProceduralMeshGenerator from Treasure
- [ ] Create 6 treasure types with procedural meshes
- [ ] Materials (metallic, emissive, vertex colors)
- [ ] Glow effects
- [ ] Particle effects (sparkle, dust)

**Week 4: UI & Flow**
- [ ] Main menu scene
- [ ] HUD (height, score, multiplier)
- [ ] Game over screen
- [ ] Pause menu
- [ ] Settings screen
- [ ] Transition animations

**Week 5: Progression**
- [ ] Achievement system (import from MobileGameCore)
- [ ] Daily challenge system (import)
- [ ] Level/XP system
- [ ] Unlockable skins
- [ ] Coin economy

**Week 6: Monetization**
- [ ] Unity Ads integration (import AdManager)
- [ ] Rewarded ad placements
- [ ] Interstitial ad placements
- [ ] IAP setup (Unity IAP)
- [ ] ATT prompt (iOS)

**Week 7: Polish & Juice**
- [ ] Audio (procedural SFX)
- [ ] Background music
- [ ] Particle effects polish
- [ ] UI animations (tweens)
- [ ] Tutorial system
- [ ] Game feel pass (shake, timing, feedback)

**Week 8: Testing & Launch Prep**
- [ ] Device testing (5+ Android, 3+ iOS)
- [ ] Performance profiling (60 FPS locked)
- [ ] Bug fixing
- [ ] App Store assets (screenshots, video)
- [ ] Submit to stores

### Code Architecture

**Scene Structure:**
```
GameScene
├── Core
│   ├── GameManager (MobileGameCore)
│   ├── SaveSystem (MobileGameCore)
│   ├── AnalyticsManager (MobileGameCore)
│   ├── AdManager (MobileGameCore)
│   └── AudioManager (MobileGameCore)
├── Gameplay
│   ├── StackManager (NEW - core game logic)
│   ├── TreasureSpawner (NEW - drop system)
│   ├── BalanceDetector (NEW - physics stability)
│   └── ScoreManager (NEW - scoring logic)
├── Camera
│   └── CameraController (MobileGameCore, adapted)
├── UI
│   ├── Canvas
│   ├── HUD (NEW)
│   └── GameOverScreen (NEW)
└── Environment
    ├── Ground
    └── Background
```

**Key Scripts (New):**

1. **StackManager.cs** (~300 lines)
   - Manages treasure stack
   - Tracks all treasures in play
   - Calculates center of mass
   - Detects game over condition

2. **TreasureSpawner.cs** (~200 lines)
   - Spawns treasures at top
   - Shows next treasure preview
   - Handles tap-to-drop input
   - Object pooling

3. **BalanceDetector.cs** (~150 lines)
   - Monitors stack tilt angle
   - Checks if stack is stable
   - Triggers warning effects
   - Game over detection

4. **ScoreManager.cs** (~200 lines)
   - Calculates score from height
   - Manages multiplier
   - Perfect placement detection
   - Coin rewards

5. **Treasure.cs** (~100 lines)
   - Individual treasure behavior
   - Physics properties
   - Procedural mesh generation trigger
   - Particle effects on land

**Total New Code:** ~1,500 lines (6 weeks × 250 lines/week)
**Reused Code:** ~5,000 lines (from MobileGameCore)

### Performance Targets

| Metric | Target | Test Device |
|--------|--------|-------------|
| FPS | 60 (locked) | Pixel 5 (mid-range) |
| Memory | <300MB | iPhone 12 |
| Load Time | <2s | Cold start |
| Build Size | <40MB | Android APK |
| Battery Drain | <15%/hour | Gameplay |

### Platform-Specific

**iOS:**
- ATT prompt on first launch
- iCloud save sync (optional)
- Game Center leaderboards
- Haptic feedback (iPhone)

**Android:**
- Google Play Games leaderboards
- Vibration feedback
- Back button = pause

---

## 🧪 Testing Plan

### Alpha Testing (Week 7)
- Internal testing (5 devices)
- Focus: Crashes, major bugs, physics glitches
- Deliverable: Bug list (priority ranked)

### Beta Testing (Week 8)
- TestFlight (iOS) + Google Play Internal Testing (Android)
- 20-30 external testers
- Focus: Gameplay balance, difficulty curve, monetization
- Metrics: Retention, session length, ARPU
- Feedback form (Google Form)

### Test Cases (Critical)

**Functional:**
- [ ] Treasure drops correctly
- [ ] Physics simulation accurate
- [ ] Game over triggers on topple
- [ ] Scoring calculates correctly
- [ ] Saves persist after close
- [ ] Ads load and reward correctly
- [ ] IAP completes successfully

**Edge Cases:**
- [ ] Stack 100+ treasures (stress test)
- [ ] Play for 60+ minutes (memory leak)
- [ ] Force close mid-game (save corruption)
- [ ] No internet (offline mode)
- [ ] Ad fails to load (fallback)
- [ ] IAP interrupted (restore)

**Devices:**
- [ ] Low-end Android (2GB RAM)
- [ ] Mid-range Android (4GB RAM)
- [ ] High-end Android (8GB RAM)
- [ ] iPhone 12
- [ ] iPhone 15 Pro
- [ ] iPad (tablet layout)

---

## 📈 Post-Launch Plan

### Week 1 Post-Launch
- **Monitor:** Crash rate, rating, reviews
- **Daily update:** Fix critical bugs
- **Community:** Respond to all reviews
- **Metrics:** Track D1/D7 retention

### Week 2-4 Post-Launch
- **Update 1.1:** Bug fixes, balance tweaks
- **Add:** Seasonal event (e.g., Valentine's theme)
- **Marketing:** Post to Reddit, Twitter, TikTok
- **Iterate:** Based on analytics data

### Month 2-3
- **Update 1.2:** New treasure types (3 more), new skins (10 more)
- **Feature:** Endless mode (no game over, leaderboard)
- **Feature:** Challenge mode (limited drops, achieve goal)
- **Cross-promo:** Add "More Games" button (for future games)

### Long-Term (Month 3+)
- **Seasonal events** (Halloween, Christmas)
- **Live ops:** Weekly challenges
- **Leaderboards:** Global rankings
- **Multiplayer?** (async: beat friend's score)
- **Prepare:** Update MobileGameCore with learnings for Game #2

---

## ✅ Success Criteria

**Launch Success:**
- ✅ Zero critical bugs
- ✅ <1% crash rate
- ✅ 4.0+ star rating
- ✅ 10,000+ downloads (first month)
- ✅ D1 retention >40%
- ✅ $500+ revenue (first month)

**Long-Term Success:**
- ✅ 100,000+ downloads (6 months)
- ✅ D7 retention >20%
- ✅ $1,500-2,000/month revenue (stable)
- ✅ Featured on App Store (goal)
- ✅ Used as foundation for Game #2

---

## 🎉 Ready to Build!

**This game will:**
- ✅ Validate your MobileGameCore library
- ✅ Prove your procedural generation system
- ✅ Test your monetization strategy
- ✅ Build your first player community
- ✅ Generate revenue while you build Game #2

**Next Steps:**
1. Review this GDD
2. Create Unity project
3. Set up MobileGameCore package
4. Start Week 1: Core Mechanic
5. Build the foundation for your indie game studio!

**Let's do this! 🚀**

---

**Companion Documents:**
- `MULTI_GAME_STUDIO_ROADMAP.md` - Master plan for all 5 games
- `MOBILE_GAME_CONCEPTS_PLAN.md` - High-level overview of all concepts
- `MOBILECORE_EXTRACTION_GUIDE.md` - Next: Extract shared systems

**Version History:**
- v1.0 (2026-01-26): Initial GDD
