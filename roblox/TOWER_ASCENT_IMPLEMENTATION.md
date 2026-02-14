# Tower Ascent - Tower of Hell Clone with Meta-Progression

> **Production-ready implementation plan for cooperative social obby with roguelike progression**

## 🎯 Final Design Decision

**Model:** Tower of Hell mechanics + Meta-progression differentiation
**Rationale:** Delivers on "max revenue, proven model" while avoiding competitive toxicity/latency issues
**Timeline:** 16-20 weeks
**Expected Value:** $2,800/year (40% success probability)

---

## 📋 Core Mechanics Summary

### What We're Building

**Tower of Hell Proven Elements:**
- 20-50 players per server (not 2-6!)
- Same procedurally generated tower for everyone
- 8-minute round timer
- Goal: Reach top before timer expires
- Tower resets every 8 minutes
- Indirect competition (leaderboard, not head-to-head)

**Our Differentiation (Meta-Progression):**
- Collect coins during climb
- Permanent upgrades (double jump, faster climb, etc.)
- Daily challenge towers (specific seeds, global leaderboard)
- Difficulty modes (Easy/Normal/Hard/Nightmare)
- Battle pass (seasonal rewards)
- Cooperative team mode (2-4 players tied together)

**Why This Works:**
- ✅ Proven model (26.6B visits)
- ✅ Low toxicity (timer is opponent, not other players)
- ✅ No latency issues (asynchronous gameplay)
- ✅ Procedural generation is FAIR (everyone gets same tower)
- ✅ Social retention (20-50 players together)
- ✅ Differentiation (Tower of Hell lacks meta-progression)

---

## 🏗️ Architecture Changes from Original Plan

### What Stays the Same

1. **DevForum Generator** - Still the base (everyone gets same tower)
2. **Rojo + Wally + Selene** - Toolchain unchanged
3. **ProfileService** - Data persistence
4. **CollectionService** - Hazards and checkpoints
5. **AnalyticsService** - Batched logging
6. **StreamingEnabled** - Memory optimization

### What Changes

| Original | Tower Ascent | Reason |
|----------|--------------|--------|
| Checkpoints save progress | NO checkpoints (Tower of Hell style) | Core mechanic |
| Small instances (6 players) | Large servers (20-50 players) | Proven model |
| Head-to-head racing | Shared tower + timer | Avoid toxicity/latency |
| Direct competition | Indirect competition | Lower toxicity |
| Static difficulty | Multiple difficulty modes | Differentiation |
| No meta-progression | Coin → upgrade loop | Retention hook |

### What's New

**CurrencyService:**
- Track coins collected during run
- Award coins based on performance (distance climbed, time)
- Persistent coin storage

**UpgradeService:**
- Purchase permanent abilities (double jump, faster climb, etc.)
- Apply upgrades to player character
- Balance upgrades to not trivialize content

**DailyChallengeService:**
- Specific seed each day
- Global leaderboard for that tower
- Exclusive rewards

**DifficultyService:**
- Easy: Checkpoints enabled, slower timer
- Normal: Tower of Hell style (default)
- Hard: Extra obstacles, 2x coins
- Nightmare: 1 life, 3x coins

**TeamModeService (Post-Launch):**
- 2-4 players tied together
- If one falls, all reset
- Higher rewards for team completion

---

## 🎮 Complete Player Experience

### First-Time Player (Session 1)

1. **Join Server** (20-50 players already playing)
2. **Spawn at base** of procedurally generated tower
3. **See timer:** 5:32 remaining (mid-round)
4. **Start climbing** - no tutorial needed (obby is self-explanatory)
5. **Fall at stage 12** - respawn at bottom
6. **Try again** - make it to stage 18
7. **Timer expires** - round ends
8. **See leaderboard:** Top 10 players who finished
9. **Earn 47 coins** (based on highest stage reached)
10. **Tower regenerates** - completely new layout
11. **New round starts** - 8:00 timer
12. **Try new tower** - different obstacles this time

### Returning Player (Session 10)

1. **Join server**
2. **Tower already in progress** (4:21 remaining)
3. **Opens upgrade shop** - has 892 coins saved
4. **Purchases "Double Jump"** upgrade (500 coins)
5. **Climbs tower** - double jump helps clear difficult gaps
6. **Reaches stage 34** - falls
7. **Tries again** - makes it to stage 41
8. **Timer expires** - earns 83 coins (distance bonus + upgrade multiplier)
9. **Checks daily challenge** - tries specific seed
10. **Sees global leaderboard** - ranks #1,247 for today's tower
11. **Next round starts** - continues playing

### Experienced Player (Session 50+)

1. **Join server**
2. **Selects "Hard Mode"** - more difficult tower, 2x coins
3. **Has multiple upgrades:** Double jump, faster climb, air dash
4. **Climbs efficiently** - reaches top in 3:42
5. **Earns 200 coins** (completion + hard mode bonus + time bonus)
6. **Waits for next round** (5:18 remaining on timer)
7. **Spectates friend** who's still climbing
8. **Round ends** - new tower generates
9. **Tries Nightmare mode** - 1 life, 3x coins
10. **Falls at stage 53** - earns 159 coins (distance × 3)
11. **Switches to Team Mode** with 3 friends
12. **Coordinates climb** - all must reach checkpoint together

---

## 💰 Monetization Strategy

### Free-to-Play Core Loop

**100% playable without spending:**
- ✅ Climb towers
- ✅ Earn coins
- ✅ Buy upgrades with earned coins
- ✅ Try all difficulty modes
- ✅ Daily challenges
- ✅ Team mode

**Monetization does NOT:**
- ❌ Skip progression (no "pay to win")
- ❌ Lock game modes behind paywall
- ❌ Require purchases to enjoy game

### Revenue Streams

**1. Battle Pass ($4.99/month or 400 Robux)**

Tier rewards (30 tiers):
- Exclusive character skins
- Unique particle trails
- Special victory animations
- Coin multipliers (1.1x, 1.2x, etc.)
- Exclusive emotes

**2. VIP Subscription ($9.99/month or 800 Robux)**

Benefits:
- 2x coin earnings (stacks with other bonuses)
- Access to VIP-only servers (less crowded)
- Exclusive chat badge
- Monthly exclusive cosmetic

**3. Cosmetic Marketplace (100-500 Robux each)**

One-time purchases:
- Character skins
- Particle trails
- Victory animations
- Emotes
- Profile badges

**4. Game Passes (100-200 Robux each)**

One-time unlocks:
- Extra loadout slots (save upgrade presets)
- Custom tower seeds (play specific layouts)
- Extended spectator features

**Expected Revenue (Year 1):**

```
Conservative (200 CCU):
- Battle pass: 40 active × $4.99 = $199.60/month
- VIP: 10 subs × $9.99 = $99.90/month
- Cosmetics: $100/month (impulse buys)
- Total: ~$400/month = $4,800/year

Realistic (600 CCU):
- Battle pass: 120 active × $4.99 = $598.80/month
- VIP: 30 subs × $9.99 = $299.70/month
- Cosmetics: $250/month
- Total: ~$1,150/month = $13,800/year

Optimistic (1500 CCU):
- Battle pass: 300 active × $4.99 = $1,497/month
- VIP: 75 subs × $9.99 = $749.25/month
- Cosmetics: $500/month
- Total: ~$2,750/month = $33,000/year
```

**Revenue increased from original estimates** due to:
- Larger player count (20-50 vs 6)
- Subscription model vs one-time passes
- Battle pass retention

---

## 🔧 Technical Implementation Changes

### RoundService (Modified)

**Original Plan:** Manage 2-6 player race instances
**Tower Ascent:** Manage 8-minute rounds for entire server

```lua
-- src/ServerScriptService/Services/RoundService.lua

local RoundService = {}
RoundService.CurrentRound = nil
RoundService.RoundTimer = 480 -- 8 minutes
RoundService.IntermissionTimer = 15

function RoundService:StartRound()
    -- Generate new tower (same seed for all players)
    local seed = os.time()
    local tower = ObbyService:GenerateTower(seed, 50) -- 50 stages

    self.CurrentRound = {
        Seed = seed,
        Tower = tower,
        StartTime = os.time(),
        Completions = {},
    }

    -- Start countdown
    self:CountdownTimer()
end

function RoundService:CountdownTimer()
    local timeLeft = self.RoundTimer

    while timeLeft > 0 do
        task.wait(1)
        timeLeft -= 1

        -- Update UI for all players
        for _, player in ipairs(Players:GetPlayers()) do
            player:SetAttribute("RoundTimeLeft", timeLeft)
        end

        -- Speed up timer if someone finishes (Tower of Hell mechanic)
        if #self.CurrentRound.Completions > 0 then
            timeLeft -= 2 -- Double speed
        end
    end

    self:EndRound()
end

function RoundService:PlayerReachedTop(player)
    -- Record completion
    table.insert(self.CurrentRound.Completions, {
        Player = player,
        Time = os.time() - self.CurrentRound.StartTime,
    })

    -- Award coins
    local coins = 100 -- Base completion reward
    CurrencyService:AwardCoins(player, coins)

    -- Announce
    self:AnnounceCompletion(player)
end

function RoundService:EndRound()
    -- Show final leaderboard
    self:DisplayLeaderboard()

    -- Award participation coins
    for _, player in ipairs(Players:GetPlayers()) do
        local highestStage = player:GetAttribute("HighestStageThisRound") or 0
        local coins = math.floor(highestStage * 2) -- 2 coins per stage
        CurrencyService:AwardCoins(player, coins)
    end

    -- Cleanup tower
    if self.CurrentRound.Tower then
        self.CurrentRound.Tower:Destroy()
    end

    -- Intermission
    task.wait(self.IntermissionTimer)

    -- Start new round
    self:StartRound()
end
```

### CurrencyService (New)

```lua
-- src/ServerScriptService/Services/CurrencyService.lua

local CurrencyService = {}
local ProfileService = require(Packages.ProfileService)

function CurrencyService:AwardCoins(player: Player, amount: number)
    local profile = DataService:GetProfile(player)
    if not profile then return end

    profile.Data.Coins = (profile.Data.Coins or 0) + amount

    -- Update client
    player:SetAttribute("Coins", profile.Data.Coins)

    -- Analytics
    AnalyticsService:LogEvent(player, "coins_earned", {
        amount = amount,
        total = profile.Data.Coins,
    })
end

function CurrencyService:SpendCoins(player: Player, amount: number): boolean
    local profile = DataService:GetProfile(player)
    if not profile then return false end

    if (profile.Data.Coins or 0) < amount then
        return false -- Not enough coins
    end

    profile.Data.Coins -= amount
    player:SetAttribute("Coins", profile.Data.Coins)

    -- Analytics
    AnalyticsService:LogEvent(player, "coins_spent", {
        amount = amount,
        remaining = profile.Data.Coins,
    })

    return true
end

function CurrencyService:GetBalance(player: Player): number
    local profile = DataService:GetProfile(player)
    if not profile then return 0 end

    return profile.Data.Coins or 0
end
```

### UpgradeService (New)

```lua
-- src/ServerScriptService/Services/UpgradeService.lua

local UpgradeService = {}

UpgradeService.UPGRADES = {
    DoubleJump = {
        Name = "Double Jump",
        Description = "Jump again while in mid-air",
        Cost = 500,
        MaxLevel = 1,
    },
    FasterClimb = {
        Name = "Faster Climbing",
        Description = "Climb ladders 25% faster",
        Cost = 300,
        MaxLevel = 3, -- 25% per level
    },
    AirDash = {
        Name = "Air Dash",
        Description = "Quick burst of movement in air",
        Cost = 1000,
        MaxLevel = 1,
    },
    CoinMultiplier = {
        Name = "Coin Multiplier",
        Description = "+10% coins per level",
        Cost = 400,
        MaxLevel = 5,
    },
}

function UpgradeService:PurchaseUpgrade(player: Player, upgradeId: string): boolean
    local upgrade = self.UPGRADES[upgradeId]
    if not upgrade then return false end

    local profile = DataService:GetProfile(player)
    if not profile then return false end

    -- Check current level
    local currentLevel = profile.Data.Upgrades[upgradeId] or 0
    if currentLevel >= upgrade.MaxLevel then
        return false -- Max level reached
    end

    -- Check cost
    local cost = upgrade.Cost * (currentLevel + 1) -- Scales with level
    if not CurrencyService:SpendCoins(player, cost) then
        return false -- Not enough coins
    end

    -- Apply upgrade
    profile.Data.Upgrades[upgradeId] = currentLevel + 1

    -- Apply to character
    self:ApplyUpgrade(player, upgradeId, currentLevel + 1)

    -- Analytics
    AnalyticsService:LogEvent(player, "upgrade_purchased", {
        upgrade = upgradeId,
        level = currentLevel + 1,
        cost = cost,
    })

    return true
end

function UpgradeService:ApplyUpgrade(player: Player, upgradeId: string, level: number)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if upgradeId == "DoubleJump" then
        -- Enable double jump script (client-side)
        player:SetAttribute("HasDoubleJump", true)
    elseif upgradeId == "FasterClimb" then
        -- Increase climb speed
        local multiplier = 1 + (0.25 * level)
        character:SetAttribute("ClimbSpeedMultiplier", multiplier)
    elseif upgradeId == "AirDash" then
        player:SetAttribute("HasAirDash", true)
    elseif upgradeId == "CoinMultiplier" then
        player:SetAttribute("CoinMultiplier", 1 + (0.1 * level))
    end
end

function UpgradeService:LoadUpgrades(player: Player)
    local profile = DataService:GetProfile(player)
    if not profile then return end

    -- Apply all owned upgrades
    for upgradeId, level in pairs(profile.Data.Upgrades or {}) do
        self:ApplyUpgrade(player, upgradeId, level)
    end
end
```

### DailyChallengeService (New)

```lua
-- src/ServerScriptService/Services/DailyChallengeService.lua

local DailyChallengeService = {}

function DailyChallengeService:GetDailySeed(): number
    -- Same seed for entire day (UTC)
    local date = os.date("!*t")
    local daysSinceEpoch = math.floor(os.time() / 86400)
    return daysSinceEpoch * 12345 -- Consistent seed for the day
end

function DailyChallengeService:GenerateDailyTower(): Model
    local seed = self:GetDailySeed()
    return ObbyService:GenerateTower(seed, 60) -- 60 stages
end

function DailyChallengeService:SubmitScore(player: Player, time: number)
    local profile = DataService:GetProfile(player)
    if not profile then return end

    local date = os.date("!%Y-%m-%d")

    -- Check if already submitted today
    if profile.Data.DailyScores[date] then
        -- Only update if better
        if time < profile.Data.DailyScores[date] then
            profile.Data.DailyScores[date] = time
        else
            return -- Worse score
        end
    else
        profile.Data.DailyScores[date] = time
    end

    -- Update OrderedDataStore for leaderboard
    local leaderboardStore = DataStoreService:GetOrderedDataStore("DailyLeaderboard_" .. date)
    leaderboardStore:SetAsync(tostring(player.UserId), time)

    -- Award coins
    CurrencyService:AwardCoins(player, 150) -- Daily completion bonus
end

function DailyChallengeService:GetLeaderboard(topN: number): {any}
    local date = os.date("!%Y-%m-%d")
    local leaderboardStore = DataStoreService:GetOrderedDataStore("DailyLeaderboard_" .. date)

    local pages = leaderboardStore:GetSortedAsync(true, topN)
    local leaderboard = {}

    for rank, entry in ipairs(pages:GetCurrentPage()) do
        table.insert(leaderboard, {
            Rank = rank,
            UserId = tonumber(entry.key),
            Time = entry.value,
        })
    end

    return leaderboard
end
```

---

## 📊 Updated Data Schema

### ProfileService Template

```lua
-- src/ServerScriptService/Services/DataService.lua

PLAYER_DATA_TEMPLATE = {
    -- Currency
    Coins = 0,

    -- Progression
    TotalRoundsPlayed = 0,
    TotalCompletions = 0,
    BestCompletionTime = math.huge,
    HighestStageEver = 0,

    -- Upgrades (key = upgrade ID, value = level)
    Upgrades = {},

    -- Daily challenges (key = date "YYYY-MM-DD", value = time in seconds)
    DailyScores = {},

    -- Monetization
    OwnedCosmetics = {}, -- Array of cosmetic IDs
    ActiveCosmetics = {
        Skin = nil,
        Trail = nil,
        Victory = nil,
    },
    HasBattlePass = false,
    BattlePassTier = 0,
    IsVIP = false,

    -- Stats
    Stats = {
        TotalJumps = 0,
        TotalFalls = 0,
        TotalPlayTime = 0,
        TotalCoinsEarned = 0,
        TotalCoinsSpent = 0,
    },

    -- Settings
    Settings = {
        Difficulty = "Normal", -- Easy, Normal, Hard, Nightmare
        ShowTimer = true,
        ShowLeaderboard = true,
    },
}
```

---

## 🎨 Content Creation Changes

### Section Requirements (Same as Tower of Hell)

**NO CHECKPOINTS in Normal/Hard/Nightmare modes**

Each section needs:
- ✅ PrimaryPart (connection point)
- ✅ Next part (where next section connects)
- ❌ NO Checkpoint parts (Tower of Hell doesn't have them)

**Exception:** Easy mode CAN have checkpoints for casual players

### Section Design Guidelines

**Tower of Hell sections are shorter and more frequent:**
- Original plan: 20 sections for full tower
- Tower Ascent: **50 sections** per tower (matches Tower of Hell's ~6 sections per floor × 8 floors)

**Timeline Impact:**
- 50 sections × 8 hours each = 400 hours of content creation
- HOWEVER: Can launch with 30 sections, add 20 post-launch
- Launch timeline: 30 sections × 8 hours = 240 hours (fits in 16-20 week timeline)

**Quality over quantity at launch:**
- Week 1-5: Core systems (no section creation yet)
- Week 6-11: Create 15 sections (2.5 per week)
- Week 12-16: Create 15 more sections (3 per week)
- **Launch with 30 sections**
- Post-launch: Add 2-3 sections per week

---

## 📅 Revised Timeline (16-20 Weeks)

### Phase 1: Foundation (Weeks 1-5)

**Week 1:**
- Toolchain setup (Rojo, Wally, Selene)
- DevForum generator port
- MemoryManager, AntiCheat, StreamingEnabled
- GameConfig with 8-minute rounds

**Week 2-3:**
- ProfileService integration
- CurrencyService (earn/spend coins)
- UpgradeService (purchase/apply upgrades)
- RoundService (8-minute timer, shared tower)

**Week 4-5:**
- DailyChallengeService
- DifficultyService (4 modes)
- AnalyticsService (batched)
- TestEZ suite
- Create 3 prototype sections

### Phase 2: Content Creation (Weeks 6-11)

**Week 6-8:**
- Create 10 sections (Easy difficulty)
- Create 5 sections (Medium difficulty)
- **Total: 15 sections**

**Week 9-11:**
- Create 7 sections (Medium difficulty)
- Create 8 sections (Hard difficulty)
- **Total: 30 sections (15 + 15)**

**Mobile testing throughout:**
- Test each section on iPhone 11, iPad, Android
- Optimize for 60fps
- Validate touch controls

### Phase 3: Monetization & Polish (Weeks 12-16)

**Week 12-13:**
- Battle Pass system
- VIP subscription
- Cosmetics marketplace
- Game pass integration

**Week 14-15:**
- UI/UX polish (leaderboards, shop, daily challenges)
- Audio (music, SFX for falls, completions, timer warnings)
- Visual polish (lighting, particle effects, skybox)

**Week 16:**
- Playtesting (50-100 players)
- Balance adjustments
- Bug fixes
- Performance optimization

### Phase 4: Launch (Weeks 17-20)

**Week 17:**
- Soft launch (friends & family, 20-30 players)
- Monitor analytics
- Fix critical bugs

**Week 18:**
- Public soft launch (100-200 players)
- Community feedback
- Iterate on balance

**Week 19:**
- Marketing materials (thumbnails, description, video trailer)
- Social media presence (Discord, Twitter)
- Sponsored ad campaign ($50-100)

**Week 20:**
- Full public launch
- Monitor CCU, retention, revenue
- Daily updates and hotfixes

### Post-Launch Roadmap

**Month 2-3:**
- Add 2-3 sections per week (reach 50 total)
- Seasonal event (Halloween, Christmas, etc.)
- Battle Pass Season 2

**Month 4-6:**
- Team Mode (cooperative 2-4 players)
- Party API integration (Q1 2025)
- Community-submitted sections
- Ranked competitive mode

---

## 🎯 Success Metrics

### Week 5 (Foundation Complete)

- ✅ 8-minute rounds functional
- ✅ Coins awarded and persistent
- ✅ At least 2 upgrades purchasable
- ✅ Daily challenge generates unique tower
- ✅ 30 sections created (prototype quality)

### Week 16 (Pre-Launch)

- ✅ 30 playable sections
- ✅ 60fps on iPhone 11
- ✅ Battle pass functional
- ✅ No critical bugs
- ✅ 50+ playtest hours logged

### Month 1 (Post-Launch)

- 🎯 100+ CCU peak
- 🎯 5%+ D1 retention
- 🎯 $500+ revenue (battle pass + VIP)
- 🎯 10+ battle pass subscribers

### Month 3 (Established)

- 🎯 300+ CCU sustained
- 🎯 8%+ D1 retention
- 🎯 $2,000+ monthly revenue
- 🎯 50+ active VIP subscribers
- 🎯 50 total sections available

---

## 🔄 Differences from Original Plan Summary

| Aspect | Original Plan | Tower Ascent | Impact |
|--------|--------------|--------------|--------|
| **Model** | Head-to-head racing | Shared tower + timer | Avoids toxicity/latency |
| **Player Count** | 2-6 per race | 20-50 per server | Higher social retention |
| **Competition** | Direct (racing) | Indirect (leaderboard) | Lower toxicity |
| **Checkpoints** | Save progress | No checkpoints (Normal+) | True Tower of Hell feel |
| **Progression** | Stage completion | Meta-progression (coins → upgrades) | Long-term retention |
| **Monetization** | One-time passes | Battle pass + VIP subs | 3-5x better LTV |
| **Content** | 20 sections at launch | 30 sections (→ 50 post-launch) | Matches Tower of Hell scope |
| **Fairness** | RNG spawn positions | Everyone gets same tower | Competitive balance |
| **Technical Risk** | High (lag comp, sync) | Low (async, proven) | Faster development |

---

## 📞 Next Steps

### This Week (Week 0)

**Day 1-2: Prototype Validation**
- Build basic 8-minute round system
- Test shared tower generation (all players see same tower)
- Validate coin collection and persistence

**Day 3: Tower of Hell Analysis**
- Play Tower of Hell for 2-3 hours
- Document exact mechanics, feel, pacing
- Note what works and what could improve

**Day 4-5: Finalize Design**
- Lock in upgrade list (4-6 upgrades for launch)
- Design battle pass tier rewards (30 tiers)
- Plan section themes

**Day 6-7: Environment Setup**
- Follow IMPLEMENTATION_WEEK_1.md
- Set up Rojo project structure
- Install dependencies

### Week 1 (Begin Implementation)

Start IMPLEMENTATION_WEEK_1.md with Tower Ascent modifications:
- DevForum generator (everyone gets same seed)
- RoundService (8-minute timer)
- CurrencyService (basic earn/spend)
- MemoryManager, AntiCheat, StreamingEnabled

---

## ✅ Confidence Assessment

**Why This Will Succeed:**

1. **Proven Model:** Tower of Hell has 26.6B visits over 5 years
2. **Clear Differentiation:** Meta-progression Tower of Hell lacks
3. **Avoids Fatal Flaws:** No toxicity, no latency issues, fair competition
4. **Technical Simplicity:** Asynchronous gameplay, no complex sync needed
5. **Social Retention:** 20-50 players together, 1.9x session time
6. **Modern Monetization:** Battle pass + subscriptions (higher LTV)
7. **Scalable Content:** Can launch with 30 sections, add more post-launch

**Confidence:** 9/10 (vs 4/10 for head-to-head racing)

**Expected Outcome:**
- 400-800 CCU realistic
- $5,000-15,000/year revenue
- 40% success probability
- **$2,800 expected value** (best of all options)

---

**Last Updated:** 2025-01-27
**Status:** Ready to begin Week 0 prototyping
**Next Document:** Start IMPLEMENTATION_WEEK_1.md with Tower Ascent modifications

