# Weeks 6-20: Scaling, Monetization & Launch

## Phase 2: Content & Testing (Weeks 6-11)

### Week 6: Mobile Testing & Optimization

**Goals:**
- Test on actual mobile devices (iPhone 11, Android mid-range)
- Achieve 60fps on target devices
- Fix mobile-specific bugs

**Device Test Matrix:**

| Device | Target FPS | Max Stages Visible | Settings |
|--------|-----------|-------------------|----------|
| iPhone 11 (2019) | 60 | 15 | Shadows off, LOD medium |
| Samsung Galaxy S21 | 60 | 18 | Shadows off, LOD medium |
| iPad Pro | 60 | 20 | Shadows on, LOD high |
| Android Budget (<$200) | 30 | 12 | All effects off |

**Mobile Optimization Checklist:**
- [ ] StreamingTargetRadius reduced to 192 on mobile
- [ ] Shadow casting disabled on all parts
- [ ] No glass/neon materials on mobile
- [ ] Texture resolution max 512x512
- [ ] Part count per stage <200
- [ ] No ParticleEmitters on mobile
- [ ] Sound effects use SoundGroups for easy disable
- [ ] UI scales properly on small screens (5.5" iPhone)

**Performance Profiling Script:**
```lua
-- src/StarterPlayer/StarterPlayerScripts/PerformanceMonitor.client.lua
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local frameTimes = {}
local sampleCount = 0
local maxSamples = 300 -- 5 seconds at 60fps

RunService.RenderStepped:Connect(function(deltaTime)
	sampleCount += 1
	table.insert(frameTimes, deltaTime * 1000) -- Convert to ms

	if sampleCount >= maxSamples then
		-- Calculate stats
		local total = 0
		local max = 0
		local min = math.huge

		for _, time in ipairs(frameTimes) do
			total += time
			max = math.max(max, time)
			min = math.min(min, time)
		end

		local avg = total / #frameTimes
		local targetFrameTime = 16.67 -- 60fps

		-- Log results
		print("=== Performance Report ===")
		print("Avg frame time:", string.format("%.2f", avg), "ms")
		print("Max frame time:", string.format("%.2f", max), "ms")
		print("Min frame time:", string.format("%.2f", min), "ms")
		print("Estimated FPS:", string.format("%.1f", 1000 / avg))
		print("Memory:", string.format("%.1f", Stats:GetTotalMemoryUsageMb()), "MB")

		if avg > targetFrameTime then
			warn("PERFORMANCE WARNING: Average frame time exceeds 60fps target")
		end

		-- Reset
		frameTimes = {}
		sampleCount = 0
	end
end)
```

---

### Weeks 7-9: Section Content Creation (10 More Sections)

**Time Budget: 80 hours (8 hours per section × 10)**

**Section Distribution:**
- 4 Easy (Stages 1-15)
- 4 Medium (Stages 16-35)
- 2 Hard (Stages 36-50)

**Easy Sections (1-2 hour completion time each):**
1. **StairClimb** - Simple ascending platforms
2. **WideJumps** - Forgiving landing zones
3. **Curves** - Gentle turning path
4. **Pyramid** - Climb around pyramid structure

**Medium Sections (2-4 hour completion time each):**
5. **SpinningPlatforms** - Rotating obstacles (TweenService)
6. **WallRun** - Tight wall-hugging path
7. **MovingPlatforms** - Back-and-forth platforms
8. **DropDown** - Precision falling segments

**Hard Sections (4-8 hour completion time each):**
9. **NarrowPath** - 1-stud wide walkway
10. **TripleJump** - Chained difficult jumps

### Section Creation Workflow

**Day 1-2: Modeling (per section)**
1. Sketch on paper (10min)
2. Block out with basic parts in Studio (1-2hr)
3. Add PrimaryPart, Next, Checkpoint (15min)
4. Create Colored/One and Colored/Two folders (15min)
5. Add detail geometry (1-2hr)
6. Validate with validation script (5min)

**Day 3: Playtesting**
1. Test personally (30min)
2. Adjust difficulty based on completion time
3. Add hazards if too easy
4. Simplify if completion <50%

**Day 4: Polish**
1. Apply materials
2. Add decorative parts
3. Verify bounding box <60×60 studs
4. Export to ServerStorage

### Animated Section Example (SpinningPlatforms)

```lua
-- Place in ServerScriptService/Services/ObbyService/Animators/SpinningPlatform.lua
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local SpinningPlatform = {}

function SpinningPlatform:Start()
	for _, platform in ipairs(CollectionService:GetTagged("SpinningPlatform")) do
		self:AnimatePlatform(platform)
	end

	CollectionService:GetInstanceAddedSignal("SpinningPlatform"):Connect(function(platform)
		self:AnimatePlatform(platform)
	end)
end

function SpinningPlatform:AnimatePlatform(platform: BasePart)
	if not platform:IsA("BasePart") then return end

	local speed = platform:GetAttribute("SpinSpeed") or 10 -- degrees per second
	local axis = platform:GetAttribute("SpinAxis") or "Y"

	-- Continuous rotation
	task.spawn(function()
		while platform and platform.Parent do
			local rotation = CFrame.Angles(
				axis == "X" and math.rad(speed) or 0,
				axis == "Y" and math.rad(speed) or 0,
				axis == "Z" and math.rad(speed) or 0
			)

			platform.CFrame = platform.CFrame * rotation
			task.wait(0.03) -- ~30fps for smooth rotation
		end
	end)
end

return SpinningPlatform
```

**Tag platforms in Studio:**
```lua
-- Select spinning platform part
-- Tag Editor plugin → Add tag "SpinningPlatform"
-- Set Attribute: SpinSpeed = 5
-- Set Attribute: SpinAxis = "Y"
```

---

### Week 10-11: Playtesting & Balancing

**Recruit 50-100 Playtesters:**
- Post on DevForum "Community Resources"
- Roblox Discord servers
- Friends & guild members

**Playtest Survey (Google Forms):**
```
1. Which stages felt too hard? (Multi-select: Stage 1-50)
2. Which stages felt too easy?
3. Did you experience lag? (Yes/No/Sometimes)
4. What device did you play on? (PC/Mobile/Console)
5. How long did you play? (0-5min / 5-15min / 15-30min / 30min+)
6. Would you play again? (Yes/No/Maybe)
7. Would you pay Robux to skip difficult stages? (Yes/No/Maybe/How much?)
8. Additional feedback (open text)
```

**Difficulty Balancing Targets:**

| Stage Range | Target Drop-off | Acceptable Range |
|-------------|-----------------|------------------|
| 1-10 | 5% | 0-10% |
| 11-20 | 10% | 5-15% |
| 21-30 | 12% | 8-18% |
| 31-40 | 15% | 10-20% |
| 41-50 | 20% | 15-30% |

**Analytics Queries (Creator Hub):**
```sql
-- Drop-off by stage (pseudo-SQL, use Creator Hub Analytics)
SELECT
  stageNumber,
  COUNT(*) as completions,
  LAG(COUNT(*)) OVER (ORDER BY stageNumber) as previousCompletions,
  (previousCompletions - completions) / previousCompletions as dropOffRate
FROM StageCompletions
GROUP BY stageNumber
ORDER BY stageNumber
```

**Balancing Actions:**
- If drop-off >25%: Simplify section (wider platforms, shorter gaps)
- If drop-off <3%: Add difficulty (narrower, longer, add hazards)
- If complaints >10 players: Redesign section entirely

---

## Phase 3: Monetization & Polish (Weeks 12-16)

### Week 12-13: Monetization Implementation

**Game Pass: Skip Stage (200 Robux)**

Create in Roblox Creator Hub → Game Passes

**src/ServerScriptService/Services/MonetizationService.lua**
```lua
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)

local MonetizationService = {}
MonetizationService.SKIP_STAGE_PASS_ID = 123456789 -- Replace with your ID

function MonetizationService:Start()
	-- Handle purchase prompts
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased and gamePassId == self.SKIP_STAGE_PASS_ID then
			self:OnSkipPurchased(player)
		end
	end)

	-- Process receipt (for developer products if you add them later)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end
end

function MonetizationService:SkipStage(player: Player)
	-- Check if owns pass
	local ownsPass = false
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, self.SKIP_STAGE_PASS_ID)
	end)

	if success then
		ownsPass = result
	end

	if not ownsPass then
		-- Prompt purchase
		MarketplaceService:PromptGamePassPurchase(player, self.SKIP_STAGE_PASS_ID)
		return
	end

	-- Skip current stage
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Stage") then
		leaderstats.Stage.Value += 1

		-- Spawn at new checkpoint
		DataService:SpawnAtCheckpoint(player, leaderstats.Stage.Value)

		-- Log usage
		warn("[Monetization]", player.Name, "skipped to stage", leaderstats.Stage.Value)
	end
end

function MonetizationService:OnSkipPurchased(player: Player)
	print("[Monetization]", player.Name, "purchased Skip Stage pass")

	-- Update data
	local data = DataService:GetData(player)
	if data then
		data.Purchases.SkipPass = true
	end

	-- Thank you message
	local message = Instance.new("Message")
	message.Text = "Thank you for supporting the game!"
	message.Parent = workspace
	game:GetService("Debris"):AddItem(message, 3)
end

return MonetizationService
```

**UI Skip Button:**
```lua
-- src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create skip button
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ObbyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local skipButton = Instance.new("TextButton")
skipButton.Size = UDim2.new(0, 120, 0, 40)
skipButton.Position = UDim2.new(1, -130, 0, 10)
skipButton.Text = "Skip Stage"
skipButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
skipButton.TextColor3 = Color3.white()
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 14
skipButton.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = skipButton

-- Remote event
local skipRemote = ReplicatedStorage:WaitForChild("SkipStageRemote")

skipButton.Activated:Connect(function()
	skipRemote:FireServer()
end)
```

**Server-side handler:**
```lua
-- src/ServerScriptService/init.server.lua (add this)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationService = require(script.Services.MonetizationService)

local skipRemote = Instance.new("RemoteEvent")
skipRemote.Name = "SkipStageRemote"
skipRemote.Parent = ReplicatedStorage

skipRemote.OnServerEvent:Connect(function(player)
	MonetizationService:SkipStage(player)
end)
```

**A/B Testing (Manual):**
- Week 1: 200 Robux price
- Week 2: 150 Robux price
- Week 3: 300 Robux price
- Compare: Purchases per 1000 players, total revenue

**VIP Pass (500 Robux) - Future Addition:**
- 2x coins (if you add coins later)
- Exclusive checkpoint effects
- VIP tag in leaderboard
- Early access to new sections

---

### Week 14: CI/CD Pipeline Hardening

**Complete GitHub Actions Workflow:**

**.github/workflows/ci.yml**
```yaml
name: CI/CD

on:
  push:
    branches: [main, staging, production]
  pull_request:
    branches: [main, staging, production]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Rokit
        run: |
          curl -L https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64 -o rokit
          chmod +x rokit
          sudo mv rokit /usr/local/bin/
          rokit install

      - name: Run Selene
        run: selene src/

      - name: Run StyLua (check mode)
        run: stylua --check src/

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Rokit
        run: |
          curl -L https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64 -o rokit
          chmod +x rokit
          sudo mv rokit /usr/local/bin/
          rokit install

      - name: Install Wally packages
        run: wally install

      - name: Run TestEZ
        run: |
          # Would need roblox-cli or similar
          echo "TestEZ tests would run here"
          # roblox-cli run --script tests/RunTests.lua

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Rokit
        run: |
          curl -L https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64 -o rokit
          chmod +x rokit
          sudo mv rokit /usr/local/bin/
          rokit install

      - name: Build place file
        run: rojo build --output ProceduralObby.rbxl

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: place-file
          path: ProceduralObby.rbxl

  deploy-staging:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/staging'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: place-file

      - name: Deploy to staging
        env:
          ROBLOX_API_KEY: ${{ secrets.ROBLOX_STAGING_API_KEY }}
        run: |
          # Use Open Cloud API to upload
          echo "Would deploy to staging place"
          # mantle deploy --environment staging

  deploy-production:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/production'
    environment:
      name: production
      url: https://www.roblox.com/games/YOUR_GAME_ID
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: place-file

      - name: Deploy to production
        env:
          ROBLOX_API_KEY: ${{ secrets.ROBLOX_PRODUCTION_API_KEY }}
        run: |
          echo "Would deploy to production place"
          # Requires manual approval in GitHub
```

**GitHub Repository Secrets:**
- `ROBLOX_STAGING_API_KEY` - OpenCloud API key for staging place
- `ROBLOX_PRODUCTION_API_KEY` - OpenCloud API key for production place

**Branch Strategy:**
- `main` - Development, auto-deploy to dev place
- `staging` - Pre-release testing, auto-deploy to staging place
- `production` - Live game, manual approval required

---

### Week 15-16: Polish & Performance

**Visual Polish:**
- [ ] Consistent color schemes across all sections
- [ ] Add skybox
- [ ] Lighting improvements (ColorCorrection, Bloom)
- [ ] Spawn area with instructions
- [ ] Victory area for winners
- [ ] Leaderboard UI showing top players

**Audio:**
- [ ] Background music (3-4 tracks, shuffle)
- [ ] Jump sound
- [ ] Checkpoint reached sound
- [ ] Death/respawn sound
- [ ] Victory fanfare
- [ ] UI click sounds

**Performance Final Pass:**
```lua
-- Run this in Studio to profile
local function profileMemory()
	local stats = game:GetService("Stats")
	print("=== Memory Profile ===")
	print("Total Memory:", stats:GetTotalMemoryUsageMb(), "MB")
	print("Instance Count:", #workspace:GetDescendants())
	print("Parts Count:", #workspace.Tower:GetDescendants())

	-- Break down by service
	for _, service in ipairs(game:GetChildren()) do
		if service:IsA("ServiceProvider") then
			local count = #service:GetDescendants()
			if count > 100 then
				print(service.Name .. ":", count, "instances")
			end
		end
	end
end

profileMemory()
```

**Optimization Targets:**
- Server memory: <500MB with 50 players
- Client memory: <800MB on mobile
- Average FPS: >55 on iPhone 11
- Join time: <15 seconds

---

## Phase 4: Content Expansion & Launch (Weeks 17-20)

### Week 17-18: Section Expansion (7 more → 20 total)

**Additional Sections:**
11. **FloatingIslands** (Medium)
12. **Spiral** (Medium)
13. **Conveyor** (Medium)
14. **Laser Grid** (Hard)
15. **DisappearingPath** (Hard)
16. **TimedJumps** (Hard)
17. **MegaCombo** (Hard) - Combines multiple mechanics

**Total Content:**
- 7 Easy sections
- 7 Medium sections
- 6 Hard sections
- 1 Finish section
- **21 sections total** (exceeds minimum 20)

---

### Week 19: Soft Launch

**Limited Release Strategy:**
- Private server testing only (week 1)
- Invite-only public testing (week 2)
- Paid ads at $10-20/day (week 3)
- Organic growth monitoring

**Soft Launch Checklist:**
- [ ] All 20+ sections complete
- [ ] Analytics dashboard configured
- [ ] Anti-cheat tested by playtesters
- [ ] Mobile tested on 5+ devices
- [ ] No critical bugs in tracker
- [ ] Monetization functional
- [ ] CI/CD pipeline tested
- [ ] Backup data recovery tested

**Monitoring (Daily):**
- CCU peak/average
- Session time average
- D1/D7 retention
- Drop-off by stage
- Revenue per 1000 visits
- Exploit reports
- Crash reports

---

### Week 20: Full Launch & Post-Launch

**Launch Day Checklist:**
- [ ] Update game description with keywords: "obby", "tower", "parkour", "procedural"
- [ ] Upload 4-5 high-quality thumbnails
- [ ] Create icon
- [ ] Set up social media (Twitter/X, Discord)
- [ ] Sponsor ad campaign ($50-100 budget)
- [ ] Post on DevForum "Creations"
- [ ] Monitor server logs for errors

**Post-Launch Support (Weeks 21-24):**
- Daily check: Analytics, exploit reports
- Weekly updates: New sections, bug fixes
- Monthly content: Seasonal themes, events
- Community engagement: Discord, respond to feedback

**Success Metrics (Month 1):**
- 100-500 CCU sustained
- 5% D1 retention (realistic)
- 8+ minute average session
- <15% drop-off per stage
- $50-500 revenue (depending on CCU)

**Iteration Cycle:**
```
Week 21-22: Gather feedback
Week 23-24: Implement top 3 requests
Week 25-26: New content drop (5 sections)
Week 27-28: Seasonal event
...continue monthly cadence
```

---

## Resource Summary

### Total Time Investment

| Phase | Weeks | Hours | Description |
|-------|-------|-------|-------------|
| Foundation | 1-5 | 120 | Setup, core systems, 3 sections |
| Content & Testing | 6-11 | 160 | 10 sections, playtesting, balancing |
| Monetization & Polish | 12-16 | 100 | Shop, CI/CD, audio, visual polish |
| Expansion & Launch | 17-20 | 100 | 7 sections, soft launch, full launch |
| **Total** | **20** | **480** | **~12 weeks full-time equivalent** |

### Cost Breakdown

| Item | Cost | Notes |
|------|------|-------|
| Domain (optional) | $12/year | Custom domain for game hub |
| Ads (soft launch) | $50-100 | Initial player acquisition |
| Ads (full launch) | $100-500 | Scale based on early ROI |
| Audio (if commissioned) | $50-200 | Or use free music library |
| Thumbnails (if commissioned) | $20-100 | Or make yourself |
| **Minimum Total** | $50 | Just ads |
| **Recommended Total** | $300-500 | Professional presentation |

### Expected Revenue (Year 1)

| Scenario | CCU | Monthly Revenue | Annual Revenue |
|----------|-----|-----------------|----------------|
| Conservative | 50-100 | $50-100 | $600-1200 |
| Realistic | 100-300 | $150-400 | $1800-4800 |
| Optimistic | 300-1000 | $500-2000 | $6000-24000 |
| Tower of Hell | 10k-30k | $50k-200k+ | $600k-2M+ |

**Reality Check:** 95% of Roblox games never reach 100 CCU sustained.

---

## Critical Success Factors

**Must-Haves:**
1. ✅ 20+ quality sections with variety
2. ✅ Stable performance on mobile (60fps)
3. ✅ Functional anti-cheat (prevents 90%+ exploits)
4. ✅ Data persistence (no data loss)
5. ✅ Clear monetization (skip button works)

**Nice-to-Haves:**
- Advanced anti-cheat (ML-based detection)
- Daily login rewards
- Leaderboards (all-time, weekly)
- Social features (invite friends)
- Cosmetics (trails, checkpoint effects)

**Deal-Breakers:**
- ❌ Frequent crashes
- ❌ Data loss
- ❌ <30fps on iPhone 11
- ❌ Rampant exploiting
- ❌ Monetization feels predatory

---

## Next Steps After Launch

**Month 2-3: Community Building**
- Discord server setup
- Community section builders (submit designs)
- Competitions (best time, first to complete)
- VIP program for loyal players

**Month 4-6: Feature Expansion**
- Difficulty modes (easy/normal/hard tower variants)
- Daily challenges
- Seasonal sections (Halloween, Christmas)
- Trading system (if you add collectibles)

**Month 7-12: Long-term Sustainability**
- Mobile app (if successful)
- Merchandise (if brand strong)
- Spin-off games (different mechanics)
- Partner program (revenue share for section creators)

**Remember:** Most successful Roblox games took 1-2 years to reach peak CCU. This is a marathon, not a sprint.
