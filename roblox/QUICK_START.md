# Quick Start Guide - Procedural Obby in 30 Minutes

> Get from zero to working prototype in 30 minutes

## ⚡ Speed Run Setup

### Prerequisites (5 minutes)
```bash
# Check you have:
git --version        # Git installed?
code --version       # VSCode installed? (optional)
```

Download Roblox Studio: https://create.roblox.com/

### Install Toolchain (10 minutes)

**Linux/Mac:**
```bash
# 1. Install Rokit
curl -L https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64 -o rokit
chmod +x rokit && sudo mv rokit /usr/local/bin/

# 2. Create project
mkdir my-obby && cd my-obby

# 3. Install tools
rokit init
rokit add rojo-rbx/rojo@7.4.3
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/stylua
rokit install

# 4. Initialize Rojo
rojo init
```

**Windows:**
```powershell
# 1. Download Rokit from GitHub releases
# https://github.com/rojo-rbx/rokit/releases/latest
# Extract to C:\Windows\System32\ (or add to PATH)

# 2. Create project
mkdir my-obby
cd my-obby

# 3. Install tools
rokit init
rokit add rojo-rbx/rojo@7.4.3
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/stylua
rokit install

# 4. Initialize Rojo
rojo init
```

### Create Minimal Project (15 minutes)

**1. Configure Rojo** (`default.project.json`):
```json
{
  "name": "MyObby",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$path": "src/server"
    },
    "ReplicatedStorage": {
      "$path": "src/shared"
    }
  }
}
```

**2. Create folders:**
```bash
mkdir -p src/server
mkdir -p src/shared
```

**3. Create minimal generator** (`src/server/Generator.server.lua`):
```lua
local ServerStorage = game:GetService("ServerStorage")

-- Create Tower folder
local tower = workspace:FindFirstChild("Tower") or Instance.new("Folder")
tower.Name = "Tower"
tower.Parent = workspace

-- Simple stage generator
local function createStage(stageNumber)
	local stage = Instance.new("Model")
	stage.Name = "Stage_" .. stageNumber

	-- Platform
	local platform = Instance.new("Part")
	platform.Size = Vector3.new(10, 1, 10)
	platform.Position = Vector3.new(0, stageNumber * 5, stageNumber * 15)
	platform.Anchored = true
	platform.Color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
	platform.Parent = stage

	stage.PrimaryPart = platform
	stage.Parent = tower

	print("Created stage", stageNumber)
end

-- Generate 10 stages
for i = 1, 10 do
	createStage(i)
end

print("✅ Obby generated!")
```

**4. Start Rojo:**
```bash
rojo serve
```

**5. In Roblox Studio:**
- Install "Rojo" plugin from Creator Marketplace
- Click "Connect" in plugin
- Should show "Connected to localhost:34872"
- See 10 colored platforms appear in Workspace.Tower

**🎉 You have a working procedural obby in 30 minutes!**

---

## 🎯 Next Steps (Choose Your Path)

### Path A: Production-Ready (16-20 weeks)
Follow the complete implementation:
1. [README.md](./README.md) - Overview
2. [IMPLEMENTATION_WEEK_1.md](./IMPLEMENTATION_WEEK_1.md) - Full setup
3. [IMPLEMENTATION_WEEK_2-5.md](./IMPLEMENTATION_WEEK_2-5.md) - Core systems
4. [IMPLEMENTATION_WEEK_6-20.md](./IMPLEMENTATION_WEEK_6-20.md) - Content & launch

### Path B: Rapid Prototype (1-2 weeks)
Build minimal viable game:
1. ✅ Basic generator (done above)
2. Add checkpoints (2 hours)
3. Add respawn system (2 hours)
4. Create 5 sections manually (10 hours)
5. Add basic UI (2 hours)
6. Deploy to Roblox (1 hour)

**Total: ~17 hours for playable prototype**

### Path C: Learning Exercise (1 week)
Study and experiment:
1. Read DevForum Self-Generating Obby thread
2. Experiment with CFrame math
3. Build 3 sections by hand
4. Add CollectionService behaviors
5. Test with friends

---

## 📚 Essential Reading Order

**Day 1:**
- README.md (30 min)
- IMPLEMENTATION_WEEK_1.md (1 hour)
- Start setup (2 hours)

**Day 2:**
- SECTION_CREATION_GUIDE.md (30 min)
- Build first section (2 hours)

**Day 3:**
- IMPLEMENTATION_WEEK_2-5.md (1 hour)
- Implement DataService (3 hours)

**Week 2+:**
- Follow week-by-week guides
- Reference TROUBLESHOOTING.md as needed

---

## 🔑 Key Concepts (Learn These First)

### 1. CFrame (Positioning)
```lua
-- Position a part
part.CFrame = CFrame.new(0, 10, 0) -- X, Y, Z

-- Rotation
part.CFrame = CFrame.new(0, 10, 0) * CFrame.Angles(0, math.rad(90), 0)

-- Relative positioning (connection points)
newPart.CFrame = oldPart.CFrame + Vector3.new(0, 0, 10) -- 10 studs in Z direction
```

### 2. Random with Seed
```lua
local rng = Random.new(12345) -- Seed
local value = rng:NextInteger(1, 100) -- Always same with same seed

-- Use for reproducibility
local seed = os.time()
print("Today's seed:", seed) -- Save this for debugging
```

### 3. CollectionService (Tags)
```lua
local CollectionService = game:GetService("CollectionService")

-- Tag an object
CollectionService:AddTag(lavaPart, "Lava")

-- React to tagged objects
for _, lava in pairs(CollectionService:GetTagged("Lava")) do
	lava.Touched:Connect(function(hit)
		-- Kill player
	end)
end
```

### 4. ProfileService (Data)
```lua
local ProfileService = require(...)
local ProfileStore = ProfileService.GetProfileStore("PlayerData", {
	Stage = 1,
	Wins = 0
})

-- Load profile
local profile = ProfileStore:LoadProfileAsync("Player_" .. userId)
if profile then
	profile.Data.Stage += 1 -- Auto-saves!
end
```

---

## ⚠️ Critical Warnings

### ❌ DON'T DO THIS:
```lua
-- BAD: Will crash with memory leak
while true do
	local stage = createStage()
	-- Never cleanup old stages
end

-- BAD: Not deterministic
math.random() -- Different every time, can't reproduce bugs

-- BAD: Data loss risk
DataStore:SetAsync(key, value) -- No error handling, no session lock

-- BAD: Rate limit
for i = 1, 1000 do
	AnalyticsService:LogEvent(...) -- THROTTLED!
end
```

### ✅ DO THIS INSTEAD:
```lua
-- GOOD: Cleanup old stages
if #activeStages > 20 then
	local oldStage = table.remove(activeStages, 1)
	oldStage:Destroy()
end

-- GOOD: Deterministic
local rng = Random.new(seed)
rng:NextInteger(1, 100)

-- GOOD: ProfileService handles session locks
local profile = ProfileStore:LoadProfileAsync(key)

-- GOOD: Batch events
task.wait(30)
AnalyticsService:LogEvent(...) -- Once per 30 seconds
```

---

## 🧪 Test Your Understanding

### Challenge 1: Create a Stage with Connection Points
```lua
-- Create a stage at position (0, 20, 0)
-- Add a "Next" point at the end
-- Player should spawn at a "Checkpoint" part

-- Solution in SECTION_CREATION_GUIDE.md
```

### Challenge 2: Implement Simple Checkpoint
```lua
-- When player touches checkpoint part:
-- 1. Update their leaderstats.Stage value
-- 2. Print confirmation message
-- 3. Play a sound

-- Hint: Use .Touched event
-- Solution in IMPLEMENTATION_WEEK_2-5.md
```

### Challenge 3: Add Memory Cleanup
```lua
-- Every 10 seconds:
-- 1. Count stages in workspace.Tower
-- 2. If >20 stages, destroy oldest
-- 3. Print how many were cleaned

-- Hint: Use task.spawn() + while loop
-- Solution in IMPLEMENTATION_WEEK_1.md
```

---

## 📖 Glossary

**Obby** - Obstacle course game (Roblox genre)
**CCU** - Concurrent Users (players online simultaneously)
**CFrame** - Coordinate Frame (position + rotation)
**Seed** - Number that initializes random generator
**ProfileService** - Library for safe data persistence
**CollectionService** - Tag-based object management
**Rojo** - Filesystem sync tool for Roblox
**Wally** - Package manager for Roblox
**TestEZ** - Testing framework
**Selene** - Lua linter
**StyLua** - Lua formatter

---

## 🎬 Video Tutorials (Recommended)

Search YouTube for:
- "Roblox obby tutorial" - Basic building
- "Roblox CFrame tutorial" - Positioning math
- "Rojo setup 2024" - Workflow setup
- "ProfileService tutorial" - Data persistence
- "Tower of Hell sections" - Inspiration

---

## 💬 Community

**DevForum** (Best for technical questions):
https://devforum.roblox.com/c/help-and-feedback/scripting-support/

**Discord** (Real-time help):
- Roblox OSS Community: https://discord.gg/roblox-oss
- Hidden Developers: https://discord.gg/hdv

**Reddit** (Showcase/feedback):
r/robloxgamedev

---

## 🎯 Your First Week Goals

**Day 1:** Setup toolchain, create 10-stage generator ✅
**Day 2:** Build first section model manually
**Day 3:** Implement checkpoint system
**Day 4:** Add ProfileService data saving
**Day 5:** Create 2 more sections
**Day 6:** Add lava hazards with CollectionService
**Day 7:** Playtest with friends, fix bugs

**End of Week 1:**
- 3 working sections
- Checkpoints saving progress
- Basic hazards (lava)
- Tested by 5+ people

**If you achieve this, you're on track for 16-20 week timeline!**

---

## 🆘 Stuck? Quick Checklist

1. ☑️ Read error message carefully (Output window in Studio)
2. ☑️ Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for your error
3. ☑️ Search DevForum for error message
4. ☑️ Verify file paths match default.project.json
5. ☑️ Restart Rojo and Studio
6. ☑️ Check official Roblox API docs
7. ☑️ Ask on DevForum with detailed info

---

## 📊 Progress Tracker

Copy to your notes:

```markdown
## Week 1
- [ ] Toolchain installed (Rokit, Rojo, Selene, StyLua)
- [ ] 10-stage basic generator working
- [ ] First section built manually
- [ ] Checkpoint system implemented
- [ ] ProfileService integrated
- [ ] 3 sections total

## Week 2
- [ ] MemoryManager implemented
- [ ] AntiCheat basic validation
- [ ] StreamingEnabled configured
- [ ] Mobile optimization script
- [ ] 5 sections total

## Week 3
- [ ] RoundService with 8-min timer
- [ ] Analytics batching
- [ ] CollectionService hazards
- [ ] 8 sections total

## Week 4
- [ ] TestEZ suite (10+ tests)
- [ ] CI/CD pipeline
- [ ] Mobile testing on real devices
- [ ] 10 sections total

## Week 5-16
(Continue with guides...)
```

---

## 🏆 Success Stories

**Realistic Expectations:**

**Month 1:** 50-100 CCU, $50-100 revenue
**Month 3:** 100-300 CCU, $300-600 revenue
**Month 6:** 300-1000 CCU if content pipeline strong
**Year 1:** Sustainable side income if you keep updating

**Tower of Hell:** 5+ years, large team, 26.6B visits
**Your game:** Solo/small team, 1-2 years to mature

**Remember:** 95% of Roblox games never hit 100 CCU. If you reach that, you're already successful!

---

## 🚀 Launch Checklist (Weeks 19-20)

When you're ready to go public:

**Pre-Launch:**
- [ ] 20+ sections complete
- [ ] No critical bugs
- [ ] Mobile tested (60fps on iPhone 11)
- [ ] Anti-cheat catches exploits
- [ ] Monetization functional
- [ ] Analytics tracking everything
- [ ] Thumbnails uploaded (4-5 high-quality)
- [ ] Game description with keywords

**Launch Day:**
- [ ] Publish to public
- [ ] Post on DevForum "Creations"
- [ ] Twitter/X announcement
- [ ] Discord server ready
- [ ] Sponsor ad campaign ($50-100)
- [ ] Monitor server logs hourly

**Week After Launch:**
- [ ] Daily analytics review
- [ ] Fix reported bugs immediately
- [ ] Respond to all feedback
- [ ] Adjust difficulty if needed
- [ ] Plan first content update

---

**Ready? Start with the 30-minute setup above, then dive into [IMPLEMENTATION_WEEK_1.md](./IMPLEMENTATION_WEEK_1.md)!**

**Questions? Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) or ask on DevForum.**

**Last Updated:** 2025-01-27
