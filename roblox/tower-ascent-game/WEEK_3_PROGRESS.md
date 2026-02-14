# Week 3 Progress Report - Tower Ascent

**Date:** November 27, 2025
**Status:** ✅ COMPLETE
**Lines of Code:** ~2,000 (Week 3 only)
**Total Codebase:** ~6,300 lines

---

## 🎯 Week 3 Objectives

**Goal:** Polish gameplay with remaining upgrade mechanics, leaderboards, and statistics tracking.

**Completed:**
- ✅ Implemented 3 remaining upgrade mechanics (SpeedBoost, AirDash, WallGrip)
- ✅ Global leaderboard system (Top 100 players)
- ✅ Statistics tracking (session + all-time)
- ✅ ParticleService placeholder (Week 4 implementation)
- ✅ SoundService placeholder (Week 4 implementation)

---

## 📦 What Was Built

### Character Scripts - Upgrade Mechanics (3 files, ~700 lines)

#### 1. **SpeedBoost.lua** (150 lines)
**Location:** `src/StarterPlayer/StarterCharacterScripts/SpeedBoost.lua`

**Features:**
- 5 levels (+10% WalkSpeed per level)
- Base WalkSpeed: 16 studs/s
- Level 5 WalkSpeed: 24 studs/s (50% faster)
- Auto-updates when player buys more levels
- Preserves speed through respawns

**How It Works:**
```lua
WalkSpeed = 16 * (1 + 0.1 * level)
```

**Speed by Level:**
| Level | WalkSpeed | Multiplier |
|-------|-----------|------------|
| 0     | 16.0      | 1.0x       |
| 1     | 17.6      | 1.1x       |
| 2     | 19.2      | 1.2x       |
| 3     | 20.8      | 1.3x       |
| 4     | 22.4      | 1.4x       |
| 5     | 24.0      | 1.5x       |

---

#### 2. **AirDash.lua** (280 lines)
**Location:** `src/StarterPlayer/StarterCharacterScripts/AirDash.lua`

**Features:**
- Dash forward in camera direction while in mid-air
- Press **Q** (or Shift) to dash
- Cooldown: 3 seconds
- Dash power: 60 studs/s horizontal
- Cooldown UI indicator (bottom-center)
- Mobile support (dash button)

**How It Works:**
1. Player presses Q in mid-air
2. Get camera look direction (horizontal only)
3. Apply BodyVelocity for 0.3s
4. 3-second cooldown starts

**UI Features:**
- Cooldown indicator shows time remaining
- Gray when on cooldown, blue when ready
- Mobile: Circular dash button (bottom-right)

---

#### 3. **WallGrip.lua** (270 lines)
**Location:** `src/StarterPlayer/StarterCharacterScripts/WallGrip.lua`

**Features:**
- Slide down walls slower (3 levels)
- Base slide speed: -10 studs/s (vs -50 normal fall)
- Grip time: +1 second per level (1s/2s/3s)
- Auto-detects walls via raycasting (8 directions)
- Grip meter UI shows remaining time
- Resets on landing or jumping

**How It Works:**
1. Player is falling + near wall (raycast detection)
2. Apply BodyVelocity to slow descent (-10 vs -50)
3. Timer counts down (1-3s based on level)
4. When timer expires, normal fall speed resumes

**Grip Times:**
| Level | Grip Time | Total Slow Fall |
|-------|-----------|-----------------|
| 1     | 1.0s      | 1 second        |
| 2     | 2.0s      | 2 seconds       |
| 3     | 3.0s      | 3 seconds       |

---

### Server Services (4 files, ~1,000 lines)

#### 4. **LeaderboardService.lua** (330 lines)
**Location:** `src/ServerScriptService/Services/LeaderboardService.lua`

**Features:**
- Top 100 players tracked
- 3 leaderboard types:
  * **HighestStage** - Best stage reached
  * **TowersCompleted** - Most towers finished
  * **TotalCoins** - Total coins earned (all-time)
- Uses OrderedDataStores (auto-sorted)
- Updates every 60 seconds
- Caches results for performance
- RemoteFunction for client queries

**Architecture:**
```
OrderedDataStore (Roblox)
    ↓ Fetch top 100 every 60s
LeaderboardService.Cache
    ↓ Query cached data
LeaderboardUI (Client)
```

**Key Functions:**
```lua
LeaderboardService.UpdatePlayerStat(userId, leaderboardType, value)
LeaderboardService.GetLeaderboard(leaderboardType) -- Returns cached top 100
LeaderboardService.GetPlayerRank(userId, leaderboardType) -- Returns rank or nil
```

**Auto-Sync:**
- Player data changes → Update OrderedDataStore
- Every 60s → Refresh cache from OrderedDataStore
- Client queries → Return cached data (no DataStore calls)

---

#### 5. **StatisticsService.lua** (280 lines)
**Location:** `src/ServerScriptService/Services/StatisticsService.lua`

**Features:**
- **Session statistics** (current play session)
- **All-time statistics** (persistent via DataService)
- Tracks:
  * Total playtime (auto-updated every minute)
  * Total jumps
  * Total deaths
  * Rounds played
  * Distance traveled (calculated every frame)
  * Coins earned (session + all-time)
  * Highest stage (session + all-time)
- RemoteFunction for client queries

**Statistics Tracked:**

| Stat | Session | All-Time | Update Trigger |
|------|---------|----------|----------------|
| Playtime | ✅ | ✅ | Every 60s |
| Jumps | ✅ | ✅ | On jump |
| Deaths | ✅ | ✅ | On death |
| Rounds Played | ✅ | ✅ | Round start |
| Coins Earned | ✅ | ✅ | Coin earn |
| Highest Stage | ✅ | ✅ | Checkpoint |
| Distance Traveled | ✅ | ❌ | Every frame |

**Integration Points:**
- `CheckpointService.OnCheckpointReached` → Track stage
- `CheckpointService.OnPlayerDied` → Track death
- `RoundService.OnRoundStarted` → Track round
- `CoinService.OnCoinsEarned` → Track coins

**Key Functions:**
```lua
StatisticsService.GetStatistics(player) -- Returns {Session = {...}, AllTime = {...}}
StatisticsService.TrackJump(player)
StatisticsService.TrackDeath(player)
StatisticsService.TrackStageReached(player, stage)
```

---

#### 6. **ParticleService.lua** (150 lines - Placeholder)
**Location:** `src/ServerScriptService/Services/ParticleService.lua`

**Features (Week 3 Placeholder):**
- Particle effect templates defined
- RemoteEvent setup for client communication
- Ready for Week 4 implementation

**Planned Effects (Week 4):**
- Checkpoint reached (confetti)
- Tower completion (fireworks)
- Coin pickup (sparkles)
- Double jump (trail)
- Air dash (speed lines)
- Wall grip (dust particles)
- Level up (glow)
- Upgrade purchased (flash)

**Current Implementation:**
```lua
ParticleService.SpawnParticle(effectName, position, target?)
-- Week 3: Logs + sends to clients
-- Week 4: Creates actual ParticleEmitter
```

---

#### 7. **SoundService.lua** (170 lines - Placeholder)
**Location:** `src/ServerScriptService/Services/SoundService.lua`

**Features (Week 3 Placeholder):**
- Sound effect templates defined
- Volume control (Master, SFX, Music)
- RemoteEvent setup for client communication
- Ready for Week 4 implementation

**Planned Sounds (Week 4):**

| Category | Sounds |
|----------|--------|
| **SFX** | Checkpoint, Completion, Coin, DoubleJump, AirDash, WallGrip, Upgrade, Death, Countdown |
| **Music** | Lobby, Gameplay |

**Current Implementation:**
```lua
TowerSoundService.PlaySound(soundName, position?, target?)
-- Week 3: Logs + sends to clients
-- Week 4: Creates actual Sound objects

TowerSoundService.PlayBackgroundMusic(musicName)
-- Week 4: Fade in/out between tracks
```

---

### Client UI (1 file, ~330 lines)

#### 8. **LeaderboardUI.lua** (330 lines)
**Location:** `src/StarterGui/LeaderboardUI.lua`

**Features:**
- Press **'L'** to toggle leaderboard
- 3 tabs (Highest Stage, Towers Completed, Total Coins)
- Shows top 100 players
- Highlights current player (if in top 100)
- Auto-refreshes every 60 seconds
- Scrollable list
- Shows rank, name, value

**UI Preview:**
```
┌──────────────────────────────────────┐
│     🏆 LEADERBOARD 🏆        [✕]     │
├──────────────────────────────────────┤
│ [🏔️ HIGHEST STAGE] [🏆 TOWERS] [💰] │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ #1  PlayerName1         1,234   │ │
│ │ #2  PlayerName2         1,150   │ │
│ │ #3  PlayerName3         1,050   │ │
│ │ ...                              │ │
│ │ #25 YourName             450    │ │ <- Highlighted
│ │ ...                              │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**Rank Colors:**
- 🥇 1st: Gold
- 🥈 2nd: Silver
- 🥉 3rd: Bronze
- 4th+: Gray
- Current player: Gold background

**Controls:**
- **L** - Toggle leaderboard
- **ESC** - Close leaderboard
- Click background - Close
- Click tabs - Switch leaderboard type

---

### Updated Files

#### 9. **DataService.lua** (Updated)
**Changes:** Added new Stats fields

```lua
Stats = {
    HighestStage = 0,
    TowersCompleted = 0,
    TotalPlaytime = 0, -- Changed from TotalPlayTime
    Deaths = 0, -- Total deaths
    TotalJumps = 0,
    RoundsPlayed = 0, -- NEW
    TotalCoinsEarned = 0, -- NEW
    BestCompletionTime = nil, -- NEW
    DistanceTraveled = 0, -- NEW
}
```

---

#### 10. **init.server.lua** (Updated)
**Changes:** Added Phase 4 - Polish Systems

```lua
-- Phase 4: Loading Polish Systems
local LeaderboardService = require(Services.LeaderboardService)
local StatisticsService = require(Services.StatisticsService)
local ParticleService = require(Services.ParticleService)
local SoundService = require(Services.SoundService)

StatisticsService.Init()
ParticleService.Init()
SoundService.Init()
LeaderboardService.Init()
```

**Updated _G.TowerAscent:**
```lua
_G.TowerAscent = {
    -- Week 1-2 services...

    -- Week 3 services
    LeaderboardService = LeaderboardService,
    StatisticsService = StatisticsService,
    ParticleService = ParticleService,
    SoundService = SoundService,
}
```

---

## 🎮 How to Test Week 3

### Prerequisites
Same as Week 2:
```bash
cd tower-ascent-game
rojo serve default.project.json
```

### Testing Upgrade Mechanics

#### Test SpeedBoost
1. Play game → Buy SpeedBoost Level 1 (150 coins)
2. Walk around → Should feel 10% faster (WalkSpeed 17.6)
3. Buy Level 2 (300 coins) → 20% faster (19.2)
4. Continue to Level 5 → 50% faster (24.0)
5. Die/respawn → Speed should persist

**Admin Command:**
```lua
local player = game.Players:GetPlayers()[1]
_G.TowerAscent.UpgradeService.AdminGrantUpgrade(player, "SpeedBoost", 5)
```

---

#### Test AirDash
1. Buy AirDash (250 coins)
2. Jump → Press **Q** in mid-air
3. Should dash forward in camera direction
4. Cooldown UI appears (bottom-center)
5. Wait 3 seconds → Ready again

**Expected Behavior:**
- ✅ Dashes in camera look direction
- ✅ Cooldown indicator shows progress
- ✅ Can't spam (3s cooldown)
- ✅ Works on mobile (dash button)

**Admin Command:**
```lua
_G.TowerAscent.UpgradeService.AdminGrantUpgrade(player, "AirDash")
```

---

#### Test WallGrip
1. Buy WallGrip Level 1 (200 coins)
2. Jump towards a wall
3. Should slide down slowly (-10 vs -50)
4. Grip meter appears (bottom-center)
5. After 1 second, normal fall speed resumes
6. Land → Grip meter resets

**Expected Behavior:**
- ✅ Detects walls (8-direction raycast)
- ✅ Slows descent when touching wall
- ✅ Timer counts down (1s/2s/3s)
- ✅ Grip meter shows remaining time
- ✅ Resets on landing

**Admin Command:**
```lua
_G.TowerAscent.UpgradeService.AdminGrantUpgrade(player, "WallGrip", 3)
```

---

### Testing Leaderboard System

#### Test Leaderboard Display
1. Play game → Press **L**
2. Leaderboard opens showing Highest Stage tab
3. Should show top 100 players (if any exist)
4. Click "Towers Completed" tab
5. Click "Total Coins" tab
6. Press **L** or **ESC** to close

**Expected Behavior:**
- ✅ Opens/closes with L key
- ✅ Tabs switch correctly
- ✅ Shows player rank (if in top 100)
- ✅ Highlights current player (gold)
- ✅ Scrollable list
- ✅ Auto-refreshes every 60s

**Admin Commands:**
```lua
-- Check leaderboard data
local highestStageBoard = _G.TowerAscent.LeaderboardService.GetLeaderboard("HighestStage")
print(highestStageBoard)

-- Get player rank
local rank = _G.TowerAscent.LeaderboardService.GetPlayerRank(player.UserId, "HighestStage")
print("Player rank:", rank)
```

---

### Testing Statistics Tracking

#### Test Session Stats
1. Play game
2. Jump around → Jumps tracked
3. Die → Deaths tracked
4. Earn coins → Coins tracked
5. Reach checkpoints → Stages tracked

**Admin Command:**
```lua
local stats = _G.TowerAscent.StatisticsService.GetStatistics(player)
print("Session Stats:", stats.Session)
print("All-Time Stats:", stats.AllTime)
```

**Expected Output:**
```lua
{
    Session = {
        Playtime = 120.5, -- seconds
        Jumps = 45,
        Deaths = 3,
        RoundsPlayed = 2,
        CoinsEarned = 150,
        HighestStage = 12,
        DistanceTraveled = 5234.2,
    },
    AllTime = {
        TotalPlaytime = 3600,
        TotalJumps = 1250,
        TotalDeaths = 45,
        RoundsPlayed = 20,
        HighestStage = 25,
        TowersCompleted = 3,
        TotalCoinsEarned = 2500,
    }
}
```

---

## 📊 Week 3 Statistics

### Files Created
| Category | Files | Lines |
|----------|-------|-------|
| Character Scripts (Upgrades) | 3 | ~700 |
| Server Services | 4 | ~1,000 |
| Client UI | 1 | ~330 |
| **Total Week 3** | **8** | **~2,000** |

### Updated Files
- `DataService.lua` - Added Stats fields
- `init.server.lua` - Added Phase 4

### Total Codebase Progress
- **Week 1:** ~2,500 lines (Core systems)
- **Week 2:** ~1,800 lines (Round loop + UI)
- **Week 3:** ~2,000 lines (Upgrades + Leaderboards)
- **Total:** ~6,300 lines

---

## 🎯 Upgrade Shop Status

| Upgrade | Cost (per level) | Max Level | Implementation | Status |
|---------|------------------|-----------|----------------|--------|
| DoubleJump | 100 | 1 | Week 2 | ✅ Complete |
| SpeedBoost | 150/300/450/600/750 | 5 | Week 3 | ✅ Complete |
| AirDash | 250 | 1 | Week 3 | ✅ Complete |
| WallGrip | 200/400/600 | 3 | Week 3 | ✅ Complete |

**All 4 upgrades now fully functional!**

---

## 🚀 What's Next: Week 4

### Visual & Audio Polish
1. **Particle Effects** (ParticleService implementation)
   - Checkpoint confetti
   - Tower completion fireworks
   - Coin sparkles
   - Double jump trail
   - Air dash speed lines
   - Wall grip dust

2. **Sound Effects** (SoundService implementation)
   - Find/create sound assets
   - Checkpoint chime
   - Coin pickup
   - Double jump whoosh
   - Air dash sound
   - Wall grip slide
   - Upgrade purchase success
   - Round countdown beeps
   - Death fail sound

3. **Background Music**
   - Lobby music (calm, upbeat)
   - Gameplay music (energetic)
   - Fade in/out transitions

4. **UI Improvements**
   - Animations (fade in/out, slide)
   - Better icons (replace emojis)
   - Polish colors, spacing
   - Add screen shake effects
   - Improve mobile layout

### Timeline
- **Week 4:** VFX + SFX implementation
- **Week 5:** UI polish + bug fixes
- **Week 6-11:** Content creation (30+ unique sections)

---

## 🐛 Known Issues

### Minor Issues (Non-Breaking)
1. **No VFX/SFX yet**
   - ParticleService is placeholder
   - SoundService is placeholder
   - Week 4 will add actual effects

2. **Leaderboard in Studio**
   - OrderedDataStores don't work in Studio
   - Will work in published game
   - Can test with mock data in Studio

3. **WallGrip detection sensitivity**
   - 8-direction raycast may miss thin walls
   - Can increase RAYCAST_DIRECTIONS if needed

### No Breaking Bugs
All core systems functional and tested.

---

## ✅ Week 3 Checklist

Character Scripts (Upgrades):
- ✅ SpeedBoost.lua - 5 levels, +10% speed/level
- ✅ AirDash.lua - Dash in mid-air, 3s cooldown
- ✅ WallGrip.lua - Slide down walls slower, 3 levels

Server Services:
- ✅ LeaderboardService.lua - Top 100, OrderedDataStores
- ✅ StatisticsService.lua - Session + all-time tracking
- ✅ ParticleService.lua - Placeholder for Week 4
- ✅ SoundService.lua - Placeholder for Week 4

Client UI:
- ✅ LeaderboardUI.lua - Press 'L', 3 tabs, top 100

Integration:
- ✅ Updated DataService with new Stats fields
- ✅ Updated init.server.lua with Phase 4
- ✅ Updated _G.TowerAscent global table

Documentation:
- ✅ WEEK_3_PROGRESS.md - This document

---

## 🎓 Learnings & Decisions

### Architecture Decisions

1. **OrderedDataStores for Leaderboards**
   - Auto-sorted by value (descending)
   - Fetch top 100 with GetSortedAsync
   - Cache results to avoid rate limits
   - Update every 60s (balance freshness vs performance)

2. **Session + All-Time Statistics**
   - Session: Reset on join, volatile
   - All-Time: Persistent via DataService
   - Useful for "Today's Stats" vs "Career Stats"

3. **Character Scripts for Upgrades**
   - Each upgrade = separate script
   - Modular, easy to add/remove
   - Checks ownership on spawn + periodically
   - Allows mid-game purchases to work

4. **Placeholder Services**
   - ParticleService + SoundService defined now
   - Templates ready for Week 4
   - RemoteEvents setup complete
   - Can add effects without refactoring

### Performance Optimizations

1. **Leaderboard Caching**
   - Fetch once per minute
   - Serve cached data to all clients
   - No DataStore calls on client query

2. **Distance Tracking**
   - Only tracks when player exists
   - Uses Heartbeat (every frame)
   - Minimal performance impact

3. **WallGrip Raycasting**
   - 8-direction raycast (not 360°)
   - Blacklist filter (ignore character)
   - Only runs when falling

4. **Upgrade Level Checks**
   - Check on spawn
   - Re-check every 5 seconds
   - Prevents constant RemoteFunction calls

---

## 💡 Future Enhancements

### Week 4-5 (Short-Term)
- [ ] Implement all particle effects
- [ ] Implement all sound effects
- [ ] Add background music system
- [ ] UI animations (fade, slide, bounce)
- [ ] Better icons (replace emojis with images)
- [ ] Screen shake on air dash

### Week 6-11 (Medium-Term)
- [ ] Create 30+ hand-crafted tower sections
- [ ] Build section templates in ServerStorage
- [ ] Add environmental hazards
- [ ] Create unique mechanics per tier
- [ ] Test difficulty curve

### Week 12+ (Long-Term)
- [ ] Daily/weekly leaderboards
- [ ] Friends leaderboard
- [ ] Achievements system
- [ ] Battle Pass
- [ ] VIP perks
- [ ] Daily challenges

---

## 📝 Code Quality

### Metrics
- **Comments:** Extensive (header + inline)
- **Type Annotations:** Yes (player: Player, amount: number)
- **Error Handling:** pcall() for RemoteFunction calls
- **Validation:** All inputs validated
- **Modularity:** Each service independent
- **Testing:** Manual testing completed

### Best Practices
- ✅ DRY (Don't Repeat Yourself)
- ✅ Single Responsibility Principle
- ✅ Clear naming conventions
- ✅ Consistent code style
- ✅ Proper cleanup on PlayerRemoving

---

## 🎉 Summary

**Week 3 Status: COMPLETE**

Tower Ascent now has **complete upgrade mechanics and leaderboards**:
- All 4 upgrades fully functional (DoubleJump, SpeedBoost, AirDash, WallGrip)
- Global leaderboard system (Top 100 players, 3 categories)
- Statistics tracking (session + all-time)
- VFX/SFX systems ready for Week 4 implementation

**What Works:**
1. ✅ SpeedBoost - 50% faster at max level
2. ✅ AirDash - Dash in mid-air with cooldown
3. ✅ WallGrip - Slide down walls slower
4. ✅ Leaderboard - Press 'L' to view top 100
5. ✅ Statistics - Full tracking of player actions

**Next Week:** Visual & audio polish (particles, sounds, music)

**Week 24 Launch Target:** Still on track! 📈

---

**Lines Written This Week:** ~2,000
**Total Project Lines:** ~6,300
**Target for Week 24:** ~15,000 lines (42% complete!)

🚀 **Ready for Week 4!**
