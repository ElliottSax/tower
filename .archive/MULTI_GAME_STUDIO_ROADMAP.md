# Multi-Game Studio Roadmap
## Building All 5 Mobile Games Strategically

**Date:** 2026-01-26
**Strategy:** Build games in optimal order to maximize code reuse
**Timeline:** 12-18 months (all 5 games live)
**Approach:** Indie game studio portfolio

---

## 🎯 The Master Plan

Instead of building 5 separate games from scratch, we'll build a **shared systems library** and develop games in an order that maximizes code reuse. Each game builds on learnings from the previous one.

### Core Strategy:
1. **Extract common systems** into a reusable "Core Library"
2. **Build games in difficulty order** (simple → complex)
3. **Reuse 60-80% of code** across games
4. **Launch iteratively** (1 game every 2-3 months)
5. **Cross-promote** between games (user acquisition synergy)

---

## 📚 Phase 0: Create Shared Core Library (Week 1-2)

### Extract from Treasure Multiplier Project

Create a new Unity package: **"MobileGameCore"**

**Systems to Extract:**

```
MobileGameCore/
├── Analytics/
│   └── AnalyticsManager.cs ✅ (from Treasure)
├── Monetization/
│   ├── AdManager.cs ✅ (from Treasure)
│   └── ATTManager.cs ✅ (iOS compliance)
├── Data/
│   ├── SaveSystem.cs ✅ (SHA256 integrity)
│   └── CloudSaveManager.cs (NEW - implement once, use everywhere)
├── Economy/
│   └── EconomyManager.cs ✅ (currency, purchases)
├── Engagement/
│   ├── AchievementSystem.cs ✅ (from Treasure)
│   └── DailyChallengeSystem.cs ✅ (from Treasure)
├── Audio/
│   ├── AudioManager.cs ✅ (from Treasure)
│   └── AudioSynthesizer.cs ✅ (procedural audio)
├── Input/
│   └── InputManager.cs ✅ (touch, tilt, swipe)
├── UI/
│   ├── UIManager.cs (NEW - standardized UI flow)
│   ├── TransitionManager.cs ✅ (scene transitions)
│   └── HUDManager.cs (base class, game-specific inheritance)
├── Effects/
│   ├── GameFeelManager.cs ✅ (screen shake, hit stop)
│   ├── ParticleManager.cs (pooling)
│   └── ProceduralParticles.cs ✅ (from Treasure)
├── ProceduralGeneration/
│   ├── ProceduralMeshGenerator.cs ✅ (base class)
│   ├── ProceduralTreasure.cs ✅ (reusable!)
│   └── ProceduralTerrain.cs ✅ (optional per game)
├── Camera/
│   └── EnhancedCameraController.cs ✅ (from Treasure)
├── Performance/
│   ├── PerformanceProfiler.cs ✅ (from Treasure)
│   └── ObjectPooler.cs (NEW - critical for mobile)
└── Utils/
    ├── Singleton.cs
    ├── Timer.cs
    └── MathUtils.cs
```

**Why This Matters:**
- ✅ Build once, use in all 5 games
- ✅ Bug fixes propagate to all games
- ✅ Consistent player experience across games
- ✅ Faster development (2-4 weeks saved per game)
- ✅ Professional portfolio piece

**Deliverable:** Unity Package that can be imported into any project

---

## 🎮 Game Development Order

Build in this specific order to maximize efficiency:

---

## Game #1: Loot Stack Mayhem
**Timeline:** Week 3-10 (8 weeks)
**Reason:** Simplest, perfect showcase for procedural system

### Why First:
- ✅ **Smallest scope** (single screen gameplay)
- ✅ **Perfect test** of Core Library
- ✅ **Procedural treasures already done** (biggest asset!)
- ✅ **Quick win** (motivation for remaining games)
- ✅ **Physics foundation** (useful for other games)

### What's New (Game-Specific):
- Physics stacking system (Unity Physics2D)
- Balance detection algorithm
- Drop timing mechanic
- Camera follow (zoom out as stack grows)

### Systems from Core Library:
- ✅ SaveSystem
- ✅ AnalyticsManager
- ✅ AdManager
- ✅ AchievementSystem
- ✅ EconomyManager
- ✅ ProceduralTreasure
- ✅ AudioSynthesizer
- ✅ GameFeelManager

### Launch Target: End of Month 2
**Expected Revenue:** $500-2000/month (ads + IAP)

---

## Game #2: Block Breaker Ascent
**Timeline:** Week 11-17 (7 weeks)
**Reason:** Hyper-casual speed, reuses many systems

### Why Second:
- ✅ **Fast development** (hyper-casual = minimal features)
- ✅ **Reuses physics** from Game #1
- ✅ **Tests endless generation** (needed for Game #3)
- ✅ **High viral potential** (good for user acquisition)
- ✅ **Different monetization** (ads-focused)

### What's New:
- Ball physics system
- Block destruction system
- Endless vertical generation
- One-tap control scheme
- Obstacle variety (5+ types)

### Systems from Core Library:
- ✅ All from Game #1
- ✅ ProceduralTerrain (adapted for vertical blocks)
- ✅ ProceduralParticles (destruction effects)
- ✅ DailyChallengeSystem (height goals)

### Code Reuse: ~70% from Core Library + Game #1 physics

### Launch Target: End of Month 4
**Expected Revenue:** $300-1500/month (ads-heavy)

---

## Game #3: Dimension Dash (Endless Runner)
**Timeline:** Week 18-27 (10 weeks)
**Reason:** More complex, but most systems exist

### Why Third:
- ✅ **Builds on endless generation** from Game #2
- ✅ **Reuses terrain generation** from Treasure
- ✅ **Character controller** foundational for Game #4
- ✅ **Portal effects** unique selling point
- ✅ **Most mass-market appeal** (endless runners proven)

### What's New:
- Character controller (swipe-based)
- Endless chunk generation (streaming)
- Dimension switching system
- Portal transition effects
- Obstacle procedural generation (5 dimensions × 5 obstacles = 25 types)
- Powerup system (speed, magnet, invincibility)

### Systems from Core Library:
- ✅ All previous systems
- ✅ ProceduralTerrain (5 dimension variants)
- ✅ ProceduralParticles (portal effects)
- ✅ EnhancedCameraController (follow runner)
- ✅ InputManager (swipe gestures)

### Code Reuse: ~65% from Core Library

### Launch Target: End of Month 7
**Expected Revenue:** $800-3000/month (ads + cosmetics)

---

## Game #4: Merge Defense Kingdom
**Timeline:** Week 28-43 (16 weeks)
**Reason:** Most complex, but highest revenue potential

### Why Fourth:
- ✅ **Leverage all previous learnings**
- ✅ **Reuse tower defense knowledge** from Tower project
- ✅ **Highest monetization potential** ($0.50-2.00 ARPU)
- ✅ **Portfolio centerpiece** (shows technical depth)
- ✅ **Long-term revenue** (high retention genre)

### What's New:
- Merge mechanic system (drag & drop)
- Tower upgrade trees (merge chains)
- Enemy pathfinding (A* algorithm)
- Wave system (enemy spawning)
- Grid-based placement
- Tower variety (8+ tower types)
- Enemy variety (12+ enemy types)
- Boss battles (every 10 waves)

### Systems from Core Library:
- ✅ All previous systems
- ✅ ProceduralMeshGenerator (towers if no 3D models)
- ✅ SaveSystem (critical - save tower levels)
- ✅ EconomyManager (gold/gems economy)
- ✅ AchievementSystem (100+ potential achievements)
- ✅ DailyChallengeSystem (survive X waves with Y tower)

### Additional Assets Needed:
- Tower 3D models (or procedural)
- Enemy 3D models (or procedural)
- Environment assets

### Code Reuse: ~55% from Core Library

### Launch Target: End of Month 11
**Expected Revenue:** $2000-8000/month (IAP-heavy)

---

## Game #5: Resource Rush Tycoon
**Timeline:** Week 44-55 (12 weeks)
**Reason:** Different genre, but systems mostly exist

### Why Fifth (Last):
- ✅ **Different pace** (idle vs action - good variety)
- ✅ **Reuses economy systems** heavily
- ✅ **Procedural treasures shine** (visual variety)
- ✅ **Passive revenue model** (different from others)
- ✅ **Portfolio completion** (5 genres covered)

### What's New:
- Incremental math system (BigNumber library)
- Offline earnings calculator
- Prestige system (reset with bonuses)
- Worker automation system
- Upgrade tree system (branching paths)
- Idle tick system (calculates earnings while closed)

### Systems from Core Library:
- ✅ All previous systems
- ✅ EconomyManager (perfect fit for incremental)
- ✅ SaveSystem (absolutely critical)
- ✅ ProceduralTreasure (show treasure variety)
- ✅ AchievementSystem (milestone-based)
- ✅ DailyChallengeSystem (mine X resources)

### Code Reuse: ~60% from Core Library

### Launch Target: End of Month 15
**Expected Revenue:** $1500-6000/month (IAP + ads)

---

## 📊 Development Timeline Overview

```
Month 1:  [Core Library]
Month 2:  [Loot Stack Mayhem] → Launch
Month 3:  [Block Breaker Ascent]
Month 4:  [Block Breaker Ascent] → Launch
Month 5:  [Dimension Dash]
Month 6:  [Dimension Dash]
Month 7:  [Dimension Dash] → Launch
Month 8:  [Merge Defense Kingdom]
Month 9:  [Merge Defense Kingdom]
Month 10: [Merge Defense Kingdom]
Month 11: [Merge Defense Kingdom] → Launch
Month 12: [Resource Rush Tycoon]
Month 13: [Resource Rush Tycoon]
Month 14: [Resource Rush Tycoon]
Month 15: [Resource Rush Tycoon] → Launch
Month 16-18: [Live Ops & Polish All Games]
```

### Concurrent Activities:
- **Marketing:** Start marketing each game 2 weeks before launch
- **Testing:** Beta test with previous game's users
- **Updates:** Push monthly updates to live games
- **Cross-Promotion:** Add "More Games" button in each game

---

## 💰 Revenue Projections

### Conservative Estimates (First Year)

| Month | Games Live | Monthly Revenue | Notes |
|-------|-----------|-----------------|-------|
| 1-2 | 0 | $0 | Development |
| 3 | 1 (Loot Stack) | $500 | Slow start |
| 4 | 1 | $800 | Growing |
| 5 | 2 | $1,500 | Second game launched |
| 6-7 | 2 | $2,000 | Stabilizing |
| 8 | 3 (+ Dimension Dash) | $3,500 | Third game boost |
| 9-11 | 3 | $4,000 | Stable portfolio |
| 12 | 4 (+ Merge Defense) | $7,000 | Big revenue jump (IAP) |
| 13-15 | 4 | $8,500 | Merge Defense scaling |
| 16 | 5 (+ Resource Rush) | $11,000 | Full portfolio |
| 17-18 | 5 | $13,000 | Cross-promotion synergy |

**Year 1 Total Revenue:** ~$80,000 - $120,000
**Year 2 Potential:** $150,000 - $250,000 (with live ops)

### Revenue Breakdown (Month 18):

| Game | Monthly Revenue | ARPU | Downloads/Month |
|------|----------------|------|-----------------|
| Loot Stack Mayhem | $2,000 | $0.12 | 16,000 |
| Block Breaker Ascent | $1,800 | $0.08 | 22,000 |
| Dimension Dash | $3,500 | $0.18 | 19,000 |
| Merge Defense Kingdom | $4,200 | $1.20 | 3,500 |
| Resource Rush Tycoon | $3,500 | $0.90 | 3,900 |
| **TOTAL** | **$15,000** | **$0.23 avg** | **64,400** |

*Assumes organic growth + cross-promotion, no paid UA*

---

## 🎨 Art Asset Strategy

### Option A: Procedural (Your Strength!)
**Budget:** $0 - $2,000 (minor outsourcing)
**Timeline:** Built into development

**Pros:**
- ✅ Zero file dependencies
- ✅ Tiny build sizes (<50MB per game)
- ✅ Infinite variety
- ✅ Your competitive advantage
- ✅ Faster iteration

**Cons:**
- ❌ Limited visual fidelity
- ❌ Harder to achieve AAA look
- ❌ Character animation challenging

**Best For:** Games 1, 2, 5

### Option B: Hybrid (Procedural + Outsource)
**Budget:** $3,000 - $8,000 per game
**Timeline:** 2-3 weeks per game

**What to Outsource:**
- Character models (player, enemies)
- Hero/Premium assets (featured items)
- UI elements (buttons, icons)

**What to Keep Procedural:**
- Environment blocks
- Common collectibles
- Particle effects
- Terrain

**Best For:** Games 3, 4

### Option C: Full Outsource
**Budget:** $10,000 - $25,000 per game
**Timeline:** 6-8 weeks per game

**Not Recommended:** Slows development, increases costs

---

## 🔧 Technical Architecture

### Shared Tech Stack

**Engine:** Unity 2022.3 LTS (stick with what works)
**Language:** C#
**Backend:** Firebase (free tier covers all games)
**Analytics:** Firebase Analytics
**Ads:** Unity Ads (single integration)
**IAP:** Unity IAP (single integration)
**Cloud Save:** Firebase Storage or Unity Cloud Save

### Project Structure

```
projects/
├── MobileGameCore/          ← Shared package
│   └── (all shared systems)
├── game1-loot-stack/
│   ├── Assets/
│   │   ├── MobileGameCore/  ← Import package
│   │   └── Game/           ← Game-specific code
│   └── Builds/
├── game2-block-breaker/
├── game3-dimension-dash/
├── game4-merge-defense/
└── game5-resource-rush/
```

### Git Repository Strategy

**Option A: Monorepo**
- Single repo with all 5 games + core library
- Easier to share code changes
- Larger repo size

**Option B: Multi-repo**
- Separate repo per game
- Core library as git submodule
- Better separation, cleaner history

**Recommendation:** Monorepo (easier for solo dev)

---

## 📱 Cross-Promotion Strategy

### User Acquisition Synergy

Each game promotes the others:

**In-Game Cross-Promo:**
- "More Games" button in main menu
- Post-game interstitial (every 5th game)
- Reward for trying other games (50 coins)
- "Studio" section showing all games

**Shared Account System:**
- Optional account creation
- Sync achievements across games
- Bonus for playing multiple games
- "Loyal Player" badge (3+ games played)

**Cross-Game Rewards:**
- Play Game A → get bonus in Game B
- Unlock exclusive items for multi-game players
- Daily challenge multiplier (more games = better rewards)

**Expected Effect:**
- 20-30% of users try second game
- 10-15% become multi-game players
- 40% increase in LTV (lifetime value)

---

## 🎯 Marketing Strategy (Low Budget)

### Pre-Launch (Each Game)

**Weeks -4 to -2:**
- Post devlog videos (YouTube, TikTok)
- Share GIFs on Twitter/Reddit (r/Unity3D, r/gamedev, r/IndieDev)
- Create game subreddit
- Build email list (itch.io landing page)

**Weeks -2 to 0:**
- Beta test (TestFlight, Google Play Internal Testing)
- Post in "Show & Tell" communities
- Reach out to mobile game YouTubers (small channels)
- Create press kit

### Post-Launch

**Week 1-2:**
- Post on Product Hunt
- Submit to app review sites (AppAdvice, TouchArcade)
- Cross-post to gaming subreddits
- Influencer outreach (micro-influencers)

**Ongoing:**
- Weekly devlog updates
- Monthly content updates
- Seasonal events (Halloween, Christmas)
- Community challenges

### Budget Allocation

| Activity | Cost per Game | Total (5 games) |
|----------|--------------|-----------------|
| App Store Graphics | $200 | $1,000 |
| Trailer Video | $300 | $1,500 |
| Press Kit | $100 | $500 |
| Influencer Budget | $500 | $2,500 |
| Paid UA Test | $500 | $2,500 |
| **TOTAL** | **$1,600** | **$8,000** |

**ROI Target:** 3-5x (breakeven in 2-3 months per game)

---

## 📊 Success Metrics & KPIs

### Per-Game Success Criteria

| Metric | Target | Definition |
|--------|--------|------------|
| D1 Retention | >40% | % returning after day 1 |
| D7 Retention | >20% | % returning after day 7 |
| D30 Retention | >10% | % returning after day 30 |
| Session Length | >5 min | Avg time per session |
| Sessions/Day | >3 | Daily engagement |
| ARPU (D30) | >$0.15 | Revenue per user (30 days) |
| CPI | <$0.50 | Cost per install (if using ads) |
| Crash Rate | <1% | App stability |
| Rating | >4.2★ | App Store rating |
| Downloads (M1) | >10,000 | First month installs |

### Portfolio Success Criteria

**By Month 18:**
- ✅ 5 games live on iOS + Android
- ✅ 250,000+ total downloads
- ✅ $10,000+ monthly recurring revenue
- ✅ 4.0+ average rating across all games
- ✅ Proven indie game studio

---

## 🛠️ Tools & Services Budget

### Essential (Paid)

| Service | Cost/Month | Cost/Year | Purpose |
|---------|-----------|-----------|---------|
| Unity Pro | $185 | $2,220 | Remove splash screen |
| Firebase Blaze | ~$25 | ~$300 | Analytics, cloud save |
| App Store Dev | $8 | $99 | iOS publishing |
| Google Play Dev | - | $25 one-time | Android publishing |
| Domain + Hosting | $15 | $180 | Studio website |
| **TOTAL** | **~$233** | **~$2,824/year** |

### Optional (Nice to Have)

| Service | Cost | Purpose |
|---------|------|---------|
| AppLovin Max | Free | Ad mediation |
| Game Analytics | Free | Additional analytics |
| TestFlight | Free | iOS beta testing |
| Discord Bot | Free | Community |

---

## 🎓 Learning & Iteration

### Key Learnings from Each Game

**Game #1 (Loot Stack):**
- Core library validation
- Physics performance on mobile
- Ad integration best practices
- Player onboarding flow

**Game #2 (Block Breaker):**
- Hyper-casual metrics (what's "good enough")
- Viral loop mechanics
- Endless generation performance
- Quick iteration cycles

**Game #3 (Dimension Dash):**
- Chunk streaming optimization
- Character controller feel
- Swipe gesture UX
- Cosmetic monetization

**Game #4 (Merge Defense):**
- Complex systems architecture
- IAP pricing strategy
- Long-term retention mechanics
- Economy balancing

**Game #5 (Resource Rush):**
- Idle game math (big numbers)
- Offline progression
- Prestige systems
- Notification strategy

### Apply Learnings Backward

After each game, update:
- ✅ Core library with improvements
- ✅ Previous games with new features
- ✅ Documentation and best practices

---

## 🚀 Execution Checklist

### Month 1: Foundation
- [ ] Create MobileGameCore package
- [ ] Extract all systems from Treasure project
- [ ] Set up git repository structure
- [ ] Create project templates
- [ ] Set up Firebase project (shared across games)
- [ ] Design studio logo/branding

### Month 2: Game #1 Dev
- [ ] Create Loot Stack Mayhem project
- [ ] Implement physics stacking
- [ ] Import MobileGameCore
- [ ] Create procedural treasures
- [ ] Build tutorial
- [ ] Test on 5+ devices

### Month 2 (End): First Launch
- [ ] Submit to App Store & Google Play
- [ ] Create landing page
- [ ] Post on social media
- [ ] Reach out to reviewers
- [ ] Monitor analytics daily

### Months 3-15: Rinse & Repeat
- [ ] Follow game development order
- [ ] Launch every 2-4 months
- [ ] Update previous games monthly
- [ ] Iterate based on data

### Month 16-18: Portfolio Complete
- [ ] All 5 games live
- [ ] Cross-promotion active
- [ ] Studio website polished
- [ ] Plan live ops calendar
- [ ] Consider Game #6 or platform expansion

---

## 🎯 The Big Picture

### What You're Building

Not just 5 games, but:
- ✅ **A game studio** (5-game portfolio)
- ✅ **A reusable framework** (MobileGameCore)
- ✅ **A technical showcase** (procedural generation expertise)
- ✅ **A revenue stream** ($10-15K/month potential)
- ✅ **A player community** (250K+ players)
- ✅ **A proven track record** (5 shipped games)

### Career Options After

With 5 published games:
1. **Continue indie dev** (scale to 10+ games)
2. **Sell studio/games** ($200K-500K potential)
3. **Get hired** (senior mobile dev, $120K+ salary)
4. **Contract work** ($100-200/hour rates)
5. **Teach/course** (sell your framework)
6. **Start larger studio** (raise funding with traction)

---

## 💡 Pro Tips

### Development

1. **Test on real devices early** (emulators lie)
2. **Profile every 2 weeks** (catch performance issues)
3. **Version control everything** (commit daily)
4. **Document as you build** (future you will thank you)
5. **Playtest with strangers** (family is too nice)

### Business

1. **Track metrics obsessively** (data > opinions)
2. **Launch imperfect games** (iterate after launch)
3. **Talk to players daily** (Discord, reviews)
4. **Cross-promote aggressively** (free UA)
5. **Build in public** (marketing during dev)

### Sustainability

1. **Don't burn out** (work 6-8 hours, not 12)
2. **Take weekends off** (long game, not sprint)
3. **Celebrate milestones** (first download, first $100)
4. **Join communities** (gamedev Discord, subreddits)
5. **Have fun!** (why we do this)

---

## ✅ Decision Point

### You Have Two Paths:

**Path A: Sequential (Recommended)**
- Build all 5 games as outlined
- 15-18 months to full portfolio
- Maximize learning and code reuse
- Safer, proven approach

**Path B: Parallel (Advanced)**
- Build 2-3 games simultaneously
- Faster time to market
- Higher risk, more complexity
- Requires team or outsourcing

**My Recommendation:** Path A (Sequential)

### Next Immediate Steps:

1. **Read this entire document** ✅
2. **Create MobileGameCore package** (Week 1-2)
3. **Start Game #1: Loot Stack Mayhem** (Week 3)
4. **Set up Firebase and Unity Ads** (Week 3)
5. **Build first prototype** (Week 4)

---

## 🎮 Let's Build This!

You have:
- ✅ 5 solid game concepts
- ✅ Existing code to reuse (Treasure project)
- ✅ Development experience (Tower + Treasure)
- ✅ Procedural generation superpower
- ✅ Complete roadmap (this document)

**Everything you need to build a successful indie game studio.**

**Ready to start? Let's create the MobileGameCore package!** 🚀

---

**Next Document:** `GAME1_LOOT_STACK_DETAILED_PLAN.md` (when ready to begin)
