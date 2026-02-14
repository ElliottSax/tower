# Week 9: Hazard Placement Strategy

**Date:** November 29, 2025
**Purpose:** Design document for adding hazards to all 50 section templates

---

## 🎯 Hazard Placement Philosophy

### Theme-Difficulty Matrix

| Theme | Sections | Difficulty | Hazard Frequency | Primary Hazards |
|-------|----------|------------|------------------|-----------------|
| **Grasslands** | 1-15 | Easy/Medium | 10-20% | Spikes (static) |
| **Desert** | 16-30 | Medium | 30-40% | Quicksand, Spikes |
| **Snow** | 31-40 | Hard | 50-60% | Ice, WindZone, Spikes |
| **Volcano** | 41-50 | Expert | 70-80% | Lava, Spikes, FallingPlatform |

### Hazard Distribution Rules

**Easy Sections (1-10):**
- Hazards: 10% (1 in 10 sections)
- Types: Static spikes only
- Placement: Obvious, avoidable
- Purpose: Teaching hazard mechanics

**Medium Sections (11-30):**
- Hazards: 30-40% (6-10 of 20 sections)
- Types: Quicksand, static spikes, occasional rotating obstacle
- Placement: Moderate challenge, clear visual cues
- Purpose: Testing learned mechanics

**Hard Sections (31-40):**
- Hazards: 50-60% (8-9 of 15 sections)
- Types: Ice (slippery), wind zones, spikes, rare falling platforms
- Placement: Integrated into core challenge
- Purpose: Environmental mastery

**Expert Sections (41-50):**
- Hazards: 70-80% (7-8 of 10 sections)
- Types: Lava (instant death), falling platforms, rotating obstacles, poison gas
- Placement: Extreme precision required
- Purpose: Ultimate test

---

## 📋 Section-by-Section Hazard Plan

### Easy Sections (Grasslands Theme)

| Section | Name | Hazard | Placement | Difficulty Impact |
|---------|------|--------|-----------|-------------------|
| 01 | StraightPath | None | - | Tutorial section |
| 02 | SmallGap | None | - | Learning jumps |
| 03 | TripleJump | **Spikes** | Between 2nd and 3rd platform | Teaches avoidance |
| 04 | NarrowPath | None | - | Width challenge |
| 05 | ZigZag | None | - | Turning challenge |
| 06 | SteppingStones | None | - | Precision jumps |
| 07 | WideGap | None | - | Long jump |
| 08 | PlatformClimb | None | - | Vertical climbing |
| 09 | ObstacleCourse | None | - | Combination |
| 10 | EasyFinale | None | - | Confidence builder |

**Total Hazards:** 1/10 (10%)

---

### Medium Sections (Desert Theme)

| Section | Name | Hazard | Placement | Difficulty Impact |
|---------|------|--------|-----------|-------------------|
| 11 | TripleGap | None | - | Gap jumping |
| 12 | NarrowBridge | **Quicksand** | On bridge surface (center 50%) | Slow movement test |
| 13 | UpwardSpiral | None | - | Climbing |
| 14 | ZigZagGaps | **Spikes** | On landing platforms (edges) | Precision landing |
| 15 | MovingPlatformIntro | None | - | Timing introduction |
| 16 | DiagonalJumps | None | - | Angled movement |
| 17 | StaggeredPlatforms | **Quicksand** | On lower platforms | Route choice |
| 18 | TightCorners | None | - | Sharp turns |
| 19 | DoubleJumpRequired | None | - | Upgrade test |
| 20 | LongClimb | **Spikes** | On rest platforms | Risk/reward |
| 21 | FourWayChoice | None | - | Decision making |
| 22 | HorizontalMaze | **Rotating Obstacle** | Center of maze | Dynamic obstacle |
| 23 | FastPlatforms | None | - | Moving platform speed |
| 24 | PrecisionLanding | None | - | Accuracy |
| 25 | MediumFinale | **Spikes + Quicksand** | Combined challenge | Finale test |

**Total Hazards:** 6/15 (40%)

---

### Hard Sections (Snow Theme)

| Section | Name | Hazard | Placement | Difficulty Impact |
|---------|------|--------|-----------|-------------------|
| 26 | AdvancedGaps | None | - | Distance test |
| 27 | SlipperySlope | **Ice** | Entire platform surface | Movement control |
| 28 | VerticalWall | **Wind Zone** | Between platforms (horizontal push) | Counter-force jumping |
| 29 | MovingObstacles | None | - | Timing |
| 30 | NarrowMaze | **Ice** | All maze floors | Precision control |
| 31 | SpeedboostRequired | None | - | Upgrade check |
| 32 | RotatingPlatforms | None | - | Rotation timing |
| 33 | MultiGap | **Spikes** | On landing zones | High-risk jumps |
| 34 | WallGripIntro | None | - | Wall climb mechanic |
| 35 | CombinationJumps | **Wind Zone + Ice** | Wind pushes onto ice | Multi-hazard |
| 36 | TimingGauntlet | None | - | Rhythm |
| 37 | TightRope | **Ice** | 1-stud platforms are ice | Extreme precision |
| 38 | AirDashRequired | None | - | Air dash test |
| 39 | AdvancedMoving | **Falling Platform** | Every 3rd platform falls | Timing pressure |
| 40 | HardFinale | **Ice + Wind + Spikes** | All hazards combined | Ultimate hard test |

**Total Hazards:** 9/15 (60%)

---

### Expert Sections (Volcano Theme)

| Section | Name | Hazard | Placement | Difficulty Impact |
|---------|------|--------|-----------|-------------------|
| 41 | TheImpossibleGap | **Lava** | Below gap (instant death) | High consequence |
| 42 | UltraNarrowGauntlet | **Lava** | On both sides of 1-stud path | Pixel-perfect required |
| 43 | TripleSpiralAscent | **Falling Platforms** | Every other platform falls | Speed required |
| 44 | MovingPlatformHell | **Lava** | Below all platforms | No safety net |
| 45 | TheGauntlet | **Rotating Obstacles** | 3 rotating bars | Timing + precision |
| 46 | MicroPlatforms | None | - | Pure precision |
| 47 | TripleAirDash | **Poison Gas** | Between dash zones | Damage pressure |
| 48 | UltimatePrecision | **Lava + Spikes** | Everywhere except path | 1-try challenge |
| 49 | AllUpgradesRequired | **Lava + Falling + Rotating** | Full hazard suite | Everything test |
| 50 | TheFinale | **Lava + Spikes + Gas + Falling** | Maximum challenge | Victory gauntlet |

**Total Hazards:** 8/10 (80%)

---

## 🌪️ Environmental Weather Effects

### WeatherService Design

**Purpose:** Add dynamic environmental effects that enhance immersion without affecting gameplay.

#### Weather Types

**1. Clear (Grasslands)**
- No active weather
- Ambient birds, wind sounds
- Occasional butterflies (particles)

**2. Sandstorm (Desert)**
- Periodic gusts of sand (every 20-30 seconds)
- Reduced visibility during gusts (fog color changes to sandy)
- Sandy particles blow across screen
- Wind audio increases during gusts

**3. Blizzard (Snow)**
- Constant heavy snowfall
- Periodic strong wind gusts
- Screen frost effect (subtle vignette)
- Howling wind audio

**4. Volcanic Ash (Volcano)**
- Falling ash particles
- Dark, ominous atmosphere
- Rumbling sounds
- Occasional lava bubble particles

#### Implementation Approach

**Client-Side Weather Handler:**
- Listens to theme changes
- Creates weather effects locally
- Respects graphics settings

**Server-Side Weather Coordinator:**
- Triggers periodic weather events (sandstorm gusts)
- Synchronizes events across all clients
- Integrates with ThemeService

---

## 🔧 Implementation Steps

### Step 1: Update Section Templates (Manual)
- Edit EasySections.lua - Add 1 hazard
- Edit MediumSections.lua - Add 6 hazards
- Edit HardSections.lua - Add 9 hazards
- Edit ExpertSections.lua - Add 8 hazards

### Step 2: Create WeatherService (New File)
- Server-side weather coordinator
- Periodic event triggers
- Theme-based weather selection

### Step 3: Create WeatherHandler (Client)
- Client-side weather effects
- Particle systems for each weather type
- Audio management
- Graphics quality scaling

### Step 4: Integration
- Hook WeatherService into init.server.lua
- Connect to ThemeService for theme changes
- Test all weather transitions

---

## ✅ Success Criteria

**Hazards:**
- [ ] All 50 sections reviewed
- [ ] 24 sections have hazards (48% total)
- [ ] Hazard difficulty matches theme/tier
- [ ] No sections feel unfair

**Weather:**
- [ ] 4 weather types implemented
- [ ] Smooth transitions between themes
- [ ] Performance impact < 5 FPS
- [ ] Audio enhances immersion

**Integration:**
- [ ] HazardService initializes all hazards
- [ ] ThemeService triggers weather changes
- [ ] No errors in console

---

**Next:** Begin updating section templates with hazards.
