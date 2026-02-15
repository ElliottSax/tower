# Immediate Action Plan - Game Portfolio Expansion

**Date**: 2026-02-14
**Goal**: Launch Pet Quest Legends in 30 days + Start Tower Ascent development
**Focus**: Execute on highest-value activities immediately

---

## 🔥 THIS WEEK (Feb 14-21, 2026)

### Day 1 (TODAY - Friday Feb 14)

#### Pet Quest Legends - Monetization Setup (4 hours)
**WHY**: Game is 85% complete, just needs Roblox configuration to generate revenue

**Tasks**:
1. ✅ **Create 4 Developer Products on Roblox Creator Dashboard** (1 hour)
   - Go to: https://create.roblox.com/dashboard/creations
   - Select Pet Quest Legends game
   - Navigate to "Monetization" → "Developer Products"
   - Create products:
     - Name: "Gem Pack 100", Price: 100 Robux, Description: "100 Gems"
     - Name: "Gem Pack 500", Price: 400 Robux, Description: "500 Gems + 50% Bonus"
     - Name: "Gem Pack 1200", Price: 800 Robux, Description: "1,200 Gems + 100% Bonus"
     - Name: "Gem Pack 3000", Price: 1,999 Robux, Description: "3,000 Gems + Best Value"
   - Copy each Product ID (long number)

2. ✅ **Update GameConfig.lua with Product IDs** (30 minutes)
   - File: `/mnt/e/projects/pet-quest-legends/src/ReplicatedStorage/Shared/Config/GameConfig.lua`
   - Find `DeveloperProducts` table
   - Replace placeholder IDs with actual IDs from step 1
   - Example:
     ```lua
     { Name = "GemPack100", Id = YOUR_PRODUCT_ID_HERE, Gems = 100, Robux = 100 }
     ```

3. ✅ **Verify Game Passes exist** (30 minutes)
   - Check if 6 game passes already created (2x Coins, 2x Luck, Auto Clicker, Extra Slots, Fast Hatch, VIP)
   - If not, create them via Roblox Creator Dashboard
   - Update GameConfig.lua with Game Pass IDs

4. ✅ **Create test place for monetization testing** (30 minutes)
   - Publish Pet Quest Legends to Roblox (if not already)
   - Enable Studio API Services in Game Settings
   - Test purchases in Studio (uses sandbox mode)

5. ✅ **Document Product IDs** (15 minutes)
   - Create file: `/mnt/e/projects/pet-quest-legends/MONETIZATION_IDS.md`
   - Record all Product IDs and Game Pass IDs
   - Include testing instructions

6. ✅ **Initial test in Roblox Studio** (45 minutes)
   - Open game in Studio
   - Test gem purchase flow (sandbox mode)
   - Test gacha egg hatching with gems
   - Test fusion system
   - Verify event countdown displays correctly
   - Check for any errors in Output window

**DELIVERABLE**: Pet Quest Legends configured for monetization, ready for live testing

---

#### Project Assessment (4 hours)
**WHY**: Need to know which other games are viable to launch quickly

**Tasks**:
1. ✅ **Investigate Dimension Hopper** (1 hour)
   - Read: `/mnt/e/projects/roblox/dimension-hopper/CLAUDE.md` (if exists)
   - Check: `default.project.json`, `src/` folder structure
   - Test: Open in Roblox Studio and playtest 5 minutes
   - Grade: A-F based on completion, bugs, revenue potential
   - Decision: Launch / Continue / Freeze / Archive

2. ✅ **Investigate Multiplication Game** (1 hour)
   - Read: `/mnt/e/projects/roblox/multiplication-game/CLAUDE.md` (if exists)
   - Check: Service files, UI scripts
   - Test: Playtest core gameplay loop
   - Grade: A-F
   - Decision: Launch / Continue / Freeze / Archive

3. ✅ **Investigate Pet Collector Sim** (1 hour)
   - Read documentation
   - Check code structure
   - Test gameplay
   - Grade: A-F
   - Decision: Launch / Continue / Freeze / Archive

4. ✅ **Investigate Adventure Story Obby** (1 hour)
   - Read documentation
   - Check code structure
   - Test gameplay
   - Grade: A-F
   - Decision: Launch / Continue / Freeze / Archive

5. ✅ **Create Project Assessment Report** (30 minutes)
   - File: `/mnt/e/projects/PROJECT_ASSESSMENT_REPORT.md`
   - Table format:
     | Project | Grade | Completion | Revenue Potential | Decision | Effort to Launch |
   - Recommendations for each project
   - Priority order for development

**DELIVERABLE**: Clear understanding of portfolio status, prioritized action plan

---

### Day 2-3 (Weekend: Feb 15-16)

#### Pet Quest Legends - Live Testing & Polish (8 hours)

**Saturday Tasks**:
1. ✅ **Publish to Roblox as unlisted** (1 hour)
   - Publish game to Roblox
   - Set to "Friends Only" for initial testing
   - Enable HttpService, DataStoreService, MarketplaceService
   - Configure all API permissions

2. ✅ **Live test monetization** (3 hours)
   - Test gem purchases with real Robux (small amount)
   - Verify DevProductService processes purchases correctly
   - Test gacha system with purchased gems
   - Test fusion system
   - Verify data persistence (logout, login, check gems remain)
   - Test on mobile device (borrow phone or use emulator)

3. ✅ **Bug fixes from testing** (3 hours)
   - Fix any issues discovered during live testing
   - Test fixes
   - Document known issues that won't block launch

4. ✅ **Create bug tracking doc** (1 hour)
   - File: `/mnt/e/projects/pet-quest-legends/KNOWN_ISSUES.md`
   - List all bugs by severity (Critical/High/Medium/Low)
   - Plan fixes (Pre-launch / Post-launch)

**Sunday Tasks**:
1. ✅ **Create game icon** (2 hours)
   - Use MidJourney/DALL-E for icon generation
   - Prompt: "Cute cartoon pets, vibrant colors, Roblox game icon style, legendary egg glowing"
   - Size: 512x512px
   - Upload to Roblox Creator Dashboard

2. ✅ **Create game thumbnail** (2 hours)
   - Generate 3-5 thumbnail options
   - Show: Cute pets, egg hatching, gem shop, excitement
   - Size: 1920x1080px
   - Upload to Roblox

3. ✅ **Write game description** (1 hour)
   - SEO-optimized for Roblox search
   - Keywords: pet, collection, simulator, eggs, rare, legendary
   - Highlight: Free daily rewards, 100+ pets, events, trading
   - Max 1,000 characters

4. ✅ **Plan launch marketing** (2 hours)
   - Write launch announcement
   - Create Discord server (if not exists)
   - Plan social media posts (TikTok, Twitter, YouTube)
   - Outline YouTuber outreach strategy

5. ✅ **Soft launch preparation** (1 hour)
   - Set game to "Public" on Roblox
   - Prepare analytics tracking (revenue, CCU, retention)
   - Set up monitoring alerts (errors, crashes)

**DELIVERABLE**: Pet Quest Legends ready for soft launch Monday

---

### Day 4-5 (Monday-Tuesday: Feb 17-18)

#### Pet Quest Legends - Soft Launch (2 hours/day)

**Tasks**:
1. ✅ **Set game to Public** (15 minutes)
   - Change visibility from "Friends Only" to "Public"
   - Monitor immediately for crashes/errors

2. ✅ **Initial marketing push** (1 hour)
   - Post to Roblox game discovery forums
   - Share on Twitter/X with hashtags #Roblox #PetSimulator #NewGame
   - Post in relevant Discord servers (Roblox dev communities)
   - Create TikTok announcement video (30 seconds)

3. ✅ **Monitor analytics** (30 minutes, 3x/day)
   - CCU (Concurrent Users)
   - Revenue (gem purchases)
   - Error logs (Roblox Developer Console)
   - Player feedback (comments, Discord)

4. ✅ **Rapid bug fixes** (ongoing)
   - Address Critical bugs within 2 hours
   - Address High bugs within 24 hours
   - Document Medium/Low bugs for later

**DELIVERABLE**: Pet Quest Legends generating first revenue, player feedback collected

---

#### Tower Ascent - Prototype Testing (3 hours)

**Tasks**:
1. ✅ **Read decision guide** (15 minutes)
   - File: `/mnt/e/projects/roblox/DECISION_TREE.md`
   - Understand 3 versions (Standard/Premium/World-Class)
   - Confirm phased approach decision

2. ✅ **Install prototype** (25 minutes)
   - Follow: `/mnt/e/projects/roblox/prototype/PROTOTYPE_SETUP.md`
   - Copy 6 scripts to Roblox Studio
   - Test prototype gameplay

3. ✅ **Playtest for fun** (30 minutes)
   - Climb tower
   - Collect coins
   - Buy double jump upgrade
   - Complete multiple rounds
   - **CRITICAL DECISION**: Is core loop fun? Yes/No

4. ✅ **Read World-Class spec** (1 hour)
   - File: `/mnt/e/projects/roblox/TOWER_ASCENT_WORLD_CLASS.md`
   - Understand all 27 systems
   - Review phased launch strategy
   - Confirm: Can launch Standard at Week 24 for $2K-3K/month

5. ✅ **Make GO/NO-GO decision** (15 minutes)
   - If prototype fun: COMMIT to World-Class phased approach
   - If prototype not fun: ABANDON (no sunk cost)
   - Document decision

6. ✅ **Read Week 1 guide** (45 minutes)
   - File: `/mnt/e/projects/roblox/TOWER_ASCENT_WEEK_1.md`
   - Understand Rojo setup, toolchain
   - Understand Week 1 deliverables (generator, memory manager, anti-cheat)
   - Plan Week 1 schedule

**DELIVERABLE**: Decision on Tower Ascent, ready to start Week 1 development if GO

---

### Day 6-7 (Wednesday-Thursday: Feb 19-20)

#### Project Assessment - Deep Dive (8 hours)

**Tasks per project** (2 hours each):

1. ✅ **Open in Roblox Studio**
   - Test gameplay for 15-20 minutes
   - Record video of gameplay session
   - Note bugs, missing features, polish level

2. ✅ **Read all code**
   - Check Services folder completeness
   - Review UI scripts functionality
   - Identify technical debt

3. ✅ **Assess monetization**
   - What revenue systems exist?
   - What's missing?
   - Estimate revenue potential if launched

4. ✅ **Estimate completion**
   - Current: X% complete
   - Remaining work: Y hours
   - Blocker issues (Critical bugs, missing features)

5. ✅ **Grade project**
   - A: 80%+ complete, ready to launch (1-2 weeks work)
   - B: 60-80% complete, viable (4-6 weeks work)
   - C: 40-60% complete, needs work (8-12 weeks work)
   - D: 20-40% complete, questionable (16+ weeks work)
   - F: <20% complete or critical flaws (abandon/freeze)

6. ✅ **Make decision**
   - **Launch**: A grade, finish in 1-2 weeks, launch immediately
   - **Continue**: B-C grade, add to development queue
   - **Freeze**: D-F grade with fixable issues, document for later
   - **Archive**: F grade with unfixable issues, learn lessons

**DELIVERABLE**: Complete project assessment report with recommendations

---

#### Tower Ascent - Week 1 Start (if GO decision) (8 hours)

**Tasks**:
1. ✅ **Setup Rojo toolchain** (2 hours)
   - Install Rojo 7.4.3+
   - Install Wally
   - Install Selene linter
   - Install StyLua formatter
   - Configure VS Code extensions
   - Test Rojo sync with empty project

2. ✅ **Create project structure** (1 hour)
   - Initialize Rojo project
   - Create folder structure per Week 1 guide
   - Set up default.project.json
   - Create wally.toml for dependencies
   - Initialize Git repository

3. ✅ **Implement Generator (Day 1-2)** (4 hours)
   - Create TowerGenerator.lua
   - Implement seed-based procedural generation
   - 50 sections per tower
   - Mix difficulty levels
   - Test in Studio (generate 10 towers, verify randomness)

4. ✅ **Implement MemoryManager** (1 hour)
   - Create MemoryManager.lua
   - Despawn sections 2 stages behind player
   - Prevent server OOM
   - Test with 20 players

**DELIVERABLE**: Tower Ascent Week 1 foundation in progress

---

### Day 8 (Friday: Feb 21)

#### Weekly Review & Planning (2 hours)

**Tasks**:
1. ✅ **Pet Quest Legends - Week 1 metrics** (30 minutes)
   - Total revenue
   - CCU peak/average
   - Player feedback summary
   - Critical bugs encountered
   - Plan Week 2 improvements

2. ✅ **Project Assessment - Final report** (30 minutes)
   - Complete PROJECT_ASSESSMENT_REPORT.md
   - Prioritize projects for next month
   - Create Gantt chart for development pipeline

3. ✅ **Tower Ascent - Week 1 progress** (30 minutes)
   - What's complete?
   - What's blocked?
   - Plan Week 2 tasks

4. ✅ **Update roadmap** (30 minutes)
   - Update GAME_PORTFOLIO_EXPANSION_PLAN.md
   - Adjust timelines based on actual progress
   - Identify bottlenecks

**DELIVERABLE**: Week 1 complete, clear plan for Week 2

---

## 🎯 WEEK 2 (Feb 22-28, 2026)

### Pet Quest Legends - First Update (20 hours)

**Goals**:
- Address player feedback
- Fix all Critical/High bugs
- Add small new feature (new pet, new area, or new event)
- Boost retention with update announcement

**Tasks**:
1. Bug fixes (10 hours)
2. New content (8 hours)
3. Update marketing (2 hours)

---

### Tower Ascent - Week 1 Complete (30 hours)

**Goals**:
- Complete all Week 1 deliverables
- Playable tower generation
- Basic round system
- Anti-cheat foundation

**Tasks**:
1. Finish Generator (if not done)
2. Implement RoundService (8-min rounds, intermission)
3. Implement CheckpointService
4. Implement HazardService (lava, killbricks)
5. Implement MemoryManager
6. Implement basic AntiCheat (teleport detection)
7. Implement CoinService (basic)
8. Test with 10 players

---

### Project Development - Continue 1 Assessed Project (10 hours)

**IF** any project graded A (ready to launch):
- Spend 10 hours finishing it
- Launch by end of Week 2
- Add to revenue-generating portfolio

**IF** no projects graded A:
- Focus on Tower Ascent Week 1
- Defer other projects

---

## 🚀 MONTH 2 (March 2026)

### Pet Quest Legends - Growth Phase
- **Week 1-2**: First major update (new area, 20+ pets, spring event)
- **Week 3-4**: Marketing push (YouTuber outreach, ads)
- **Goal**: 2,000+ CCU, $5K-10K monthly revenue

### Tower Ascent - Development Sprint
- **Week 1-4**: Complete Weeks 2-5 of development guide
- **Week 5-8**: Complete Weeks 6-12 of development guide
- **Goal**: 50% complete by end of Month 2

### New Game Start - Idle Pet Empire
- **Week 1-2**: Concept design, prototype
- **Week 3-4**: Core loop implementation
- **Goal**: Playable prototype by end of Month 2

---

## 💰 Revenue Targets

### Month 1 (February 2026)
- Pet Quest Legends: $2K-8K (soft launch + ramp)
- Other games: $0 (assessment phase)
- **Total**: $2K-8K

### Month 2 (March 2026)
- Pet Quest Legends: $8K-20K (first update + marketing)
- Tower Ascent: $0 (in development)
- Idle Pet Empire: $0 (in development)
- Other games: $0-3K (if any grade A projects launched)
- **Total**: $8K-23K

### Month 3 (April 2026)
- Pet Quest Legends: $10K-30K (stable)
- Tower Ascent: $0 (in development)
- Idle Pet Empire: $3K-8K (launch)
- Other games: $2K-5K
- **Total**: $15K-43K

---

## ✅ Success Criteria (End of Week 1)

### Must Achieve
- ✅ Pet Quest Legends monetization configured
- ✅ Pet Quest Legends soft launched
- ✅ All projects assessed and graded
- ✅ Tower Ascent GO/NO-GO decision made
- ✅ Clear roadmap for next 30 days

### Stretch Goals
- ✅ Pet Quest Legends generating $500+ revenue (Week 1)
- ✅ Tower Ascent Week 1 complete
- ✅ 1 additional project ready to launch
- ✅ Social media presence established

---

## 🔧 Tools & Resources Needed

### Immediate (This Week)
- ✅ Roblox Creator Dashboard access
- ✅ Roblox Studio installed
- ✅ VS Code with Rojo extension
- ✅ MidJourney or DALL-E access (for icons/thumbnails)
- ✅ Discord account (for community)

### Short-term (Next 2 Weeks)
- ✅ Rojo 7.4.3+ installed
- ✅ Wally package manager
- ✅ Selene + StyLua
- ✅ TikTok account (for marketing)
- ✅ Twitter/X account (for marketing)

### Medium-term (Month 2-3)
- ✅ Small ad budget ($200-500/month)
- ✅ YouTuber outreach list
- ✅ Analytics dashboard (Google Sheets or similar)
- ✅ Community moderators (hire from players when revenue supports)

---

## 📞 Daily Standup Questions

**Every morning, ask yourself**:
1. What did I accomplish yesterday?
2. What will I accomplish today?
3. What's blocking me?
4. Are we on track for revenue targets?
5. Are we on track for launch deadlines?

**Every evening, review**:
1. Did I hit today's goals?
2. What surprised me today (good or bad)?
3. What do I need to adjust tomorrow?
4. Pet Quest metrics: CCU, revenue, errors
5. Player feedback: What are they saying?

---

## 🎯 North Star Metrics

**Focus on these above all else**:
1. **Monthly Revenue**: Goal = $50K-100K by Month 12
2. **Total CCU**: Goal = 20,000+ by Month 12
3. **Games Launched**: Goal = 7-10 by Month 12
4. **Player Retention**: D1 > 10%, D7 > 5%
5. **Development Velocity**: 1-2 games launched per month (after Month 3)

---

## ⚠️ Red Flags (Stop and Reassess)

**IF any of these occur, STOP and reassess strategy**:
1. Pet Quest Legends generates <$500 in first month
2. Tower Ascent prototype is not fun
3. No assessed projects are grade A or B
4. Development velocity <50% of planned
5. Burnout (working >60 hrs/week unsustainably)

**Reassessment Actions**:
1. Analyze why targets missed
2. Identify bottlenecks or wrong assumptions
3. Pivot strategy (focus, kill projects, change scope)
4. Update roadmap with realistic targets
5. Consider hiring help (if revenue supports)

---

## 🏆 Week 1 Checklist

### Friday (TODAY)
- [ ] Create 4 Developer Products on Roblox
- [ ] Update Pet Quest GameConfig.lua with Product IDs
- [ ] Verify Game Passes exist
- [ ] Test monetization in Studio sandbox
- [ ] Document Product IDs
- [ ] Assess Dimension Hopper (1 hour)
- [ ] Assess Multiplication Game (1 hour)
- [ ] Assess Pet Collector Sim (1 hour)
- [ ] Assess Adventure Story Obby (1 hour)

### Saturday
- [ ] Publish Pet Quest as unlisted
- [ ] Live test monetization with real Robux
- [ ] Fix Critical bugs
- [ ] Document known issues

### Sunday
- [ ] Create game icon (MidJourney/DALL-E)
- [ ] Create game thumbnail
- [ ] Write game description
- [ ] Plan launch marketing
- [ ] Prepare soft launch

### Monday
- [ ] Set Pet Quest to Public (soft launch)
- [ ] Initial marketing push
- [ ] Monitor analytics
- [ ] Read Tower Ascent DECISION_TREE.md
- [ ] Test Tower Ascent prototype

### Tuesday
- [ ] Continue Pet Quest monitoring
- [ ] Rapid bug fixes
- [ ] Read Tower Ascent World-Class spec
- [ ] Make Tower Ascent GO/NO-GO decision
- [ ] Read Tower Ascent Week 1 guide

### Wednesday
- [ ] Deep dive project assessments (2 projects)
- [ ] Tower Ascent: Setup Rojo toolchain
- [ ] Tower Ascent: Create project structure

### Thursday
- [ ] Deep dive project assessments (2 projects)
- [ ] Tower Ascent: Implement Generator
- [ ] Tower Ascent: Implement MemoryManager

### Friday
- [ ] Complete PROJECT_ASSESSMENT_REPORT.md
- [ ] Pet Quest Week 1 metrics review
- [ ] Tower Ascent Week 1 progress review
- [ ] Update roadmap
- [ ] Plan Week 2

---

**READY? LET'S EXECUTE.** 🚀

**Start with Priority 1: Pet Quest Legends monetization setup (4 hours TODAY)**

This is the fastest path to first revenue. Everything else can wait until this is done.

**GO GO GO!** 💰🎮
