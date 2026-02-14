# Section Creation Guide

> Step-by-step guide for creating obby sections from scratch

## 📐 Section Requirements

Every section MUST have:
- ✅ PrimaryPart (base platform for positioning)
- ✅ Next (connection point for next section)
- ✅ Checkpoint (spawn point for players)
- ✅ Colored/One and Colored/Two folders (for theming)
- ✅ Bounding box <60×60 studs (prevents overlap)
- ✅ Completable by 80%+ of target difficulty players

**Recommended length:** 30-40 studs per section

---

## 🎨 Section Template Setup (One-Time)

### Step 1: Create Base Template

1. Open Roblox Studio
2. Insert Model: `Ctrl+Shift+M` → Name: "SectionTemplate"
3. Insert Part → Name: "PrimaryPart"
   - Size: 8, 1, 8
   - Position: 0, 0, 0
   - Anchored: true
   - Color: Gray
4. Select Model → Properties → PrimaryPart dropdown → Select "PrimaryPart"

### Step 2: Add Connection Points

**Next Point:**
1. Duplicate PrimaryPart → Rename: "Next"
2. Position: 0, 0, 40 (end of section)
3. Size: 0.5, 0.5, 0.5
4. Transparency: 1
5. Color: Green (for visibility in Studio)

**Checkpoint:**
1. Insert Part → Name: "Checkpoint"
2. Position: 0, 3, 2 (above start)
3. Size: 8, 6, 1
4. Transparency: 0.8
5. CanCollide: false
6. Color: Light green
7. Material: Neon

### Step 3: Add Color Folders

1. Insert Folder into Model → Name: "Colored"
2. Insert Folder into Colored → Name: "One"
3. Insert Folder into Colored → Name: "Two"

### Step 4: Save Template

1. Right-click SectionTemplate → "Save to Roblox"
2. Name: "ObbySection_Template"
3. Save to inventory

**You now have a reusable template!**

---

## 🏗️ Creating a New Section (30min - 8hrs)

### Example: "JumpGap" (Easy Difficulty)

#### Part 1: Planning (5-10 minutes)

**Sketch on paper:**
```
[Start] --8 studs--> [Platform] --8 studs--> [Platform] --8 studs--> [End]
   ↑                    ↑                       ↑                      ↑
Checkpoint         (empty space)          (empty space)            Next point
```

**Specifications:**
- Difficulty: Easy (1/10)
- Length: 40 studs
- Obstacle: Simple gaps
- Estimated completion time: 10-15 seconds
- Fail rate target: <10%

#### Part 2: Building (1-2 hours)

**Step 1: Insert Template**
1. Toolbox → My Models → ObbySection_Template
2. Insert into Workspace
3. Rename: "JumpGap"

**Step 2: Add Obstacle Geometry**

Platform 1:
1. Insert Part → Parent: JumpGap
2. Size: 8, 1, 8
3. Position: 0, 0, 12
4. Anchored: true
5. Move to Colored/One folder

Platform 2:
1. Duplicate Platform 1
2. Position: 0, 0, 24
3. Move to Colored/Two folder

Platform 3:
1. Duplicate Platform 1
2. Position: 0, 0, 36
3. Move to Colored/One folder

**Step 3: Position Next Point**
- Move Next part to: 0, 0, 40 (after last platform)

**Step 4: Add Details (Optional)**
- Insert decorative parts (pillars, railings)
- Add to Colored folders for theming
- Keep total parts <50 for this section

#### Part 3: Validation (15 minutes)

**Run Validation Script:**
```lua
-- Copy to Command Bar (F9 → Command Bar)
local section = game.Selection:Get()[1] -- Select your section first

-- Check PrimaryPart
if not section.PrimaryPart then
    warn("❌ Missing PrimaryPart")
else
    print("✅ PrimaryPart set")
end

-- Check Next
if not section:FindFirstChild("Next") then
    warn("❌ Missing Next part")
else
    print("✅ Next part exists")
    print("   Position:", section.Next.Position)
end

-- Check Checkpoint
if not section:FindFirstChild("Checkpoint") then
    warn("❌ Missing Checkpoint")
else
    print("✅ Checkpoint exists")
end

-- Check Colored folders
local colored = section:FindFirstChild("Colored")
if not colored then
    warn("❌ Missing Colored folder")
elseif not colored:FindFirstChild("One") or not colored:FindFirstChild("Two") then
    warn("❌ Missing One or Two folders")
else
    print("✅ Color folders exist")
    print("   One parts:", #colored.One:GetChildren())
    print("   Two parts:", #colored.Two:GetChildren())
end

-- Check size
local _, size = section:GetBoundingBox()
print("Bounding box:", math.floor(size.X), "×", math.floor(size.Z))
if size.X > 60 or size.Z > 60 then
    warn("⚠️  Section too large (max 60×60)")
else
    print("✅ Size OK")
end

-- Check part count
local partCount = 0
for _, obj in pairs(section:GetDescendants()) do
    if obj:IsA("BasePart") then partCount += 1 end
end
print("Total parts:", partCount)
if partCount > 200 then
    warn("⚠️  High part count (>200), may impact mobile performance")
end

print("\n=== Validation Complete ===")
```

#### Part 4: Playtesting (30 minutes)

**Solo Test:**
1. Start playtest (F5)
2. Spawn character at Checkpoint position
3. Attempt section 10 times
4. Track: Completion time, deaths, frustration

**Metrics:**
- Easy sections: 90%+ completion rate
- Medium sections: 70-85% completion rate
- Hard sections: 50-70% completion rate

**Adjust if needed:**
- Too easy? Widen gaps, narrow platforms
- Too hard? Close gaps, widen platforms

#### Part 5: Polish (1-2 hours)

**Materials:**
- Platforms: SmoothPlastic (good for mobile)
- Decorations: Plastic, Concrete (avoid Neon/Glass on mobile)

**Colors (will be overridden by theming):**
- Colored/One: Leave as default (will be themed)
- Colored/Two: Leave as default (will be themed)

**Add CollectionService Tags:**
```lua
-- If section has lava:
local lava = section.LavaPart
game:GetService("CollectionService"):AddTag(lava, "Lava")

-- If section has spinning platform:
local spinner = section.SpinningPlatform
game:GetService("CollectionService"):AddTag(spinner, "SpinningPlatform")
spinner:SetAttribute("SpinSpeed", 5) -- degrees per second
spinner:SetAttribute("SpinAxis", "Y")
```

#### Part 6: Export (5 minutes)

**To ServerStorage:**
1. Move section to ServerStorage.Sections.Easy (or Medium/Hard)
2. Verify path: ServerStorage > Sections > Easy > JumpGap
3. Test in-game generation

**Update SectionConfig.lua:**
```lua
SectionConfig.Sections["JumpGap"] = {
    Difficulty = "Easy",
    Length = "Medium", -- Short/Medium/Long
    SpawnWeight = 1.0,
    Creator = "YourName",
    Tags = {"Jump", "Linear"},
}
```

---

## 📝 Section Design Patterns

### Easy Difficulty (Target: 1-2/10)

**JumpGap** (Completed above)
- 3 platforms, 8-stud gaps
- Straightforward path

**StairClimb**
```
[Start] → [Step+2Y] → [Step+4Y] → [Step+6Y] → [End]
```
- Simple ascending platforms
- No gaps, just vertical climbing

**WideJumps**
```
[Start: 10×10] --6 studs--> [Platform: 12×12] --> [End]
```
- Forgiving landing zones
- Wide platforms reduce frustration

**Curves**
```
[Start] → [Turn 45°] → [Turn 45°] → [End at 90°]
```
- Gentle curving path
- Introduces turning without difficulty

---

### Medium Difficulty (Target: 4-6/10)

**ZigZag**
```
[Start: X=0] → [Platform: X=4] → [Platform: X=-4] → [End: X=0]
```
- Alternating left/right platforms
- Requires directional changes mid-jump

**Balance**
```
[Start] → [2-stud wide path, 30 studs long] → [End]
```
- Narrow walkway
- Tests precision movement

**SpinningPlatforms** (Animated)
```lua
-- Add after building static platforms:
for _, platform in pairs(section.Platforms:GetChildren()) do
    CollectionService:AddTag(platform, "SpinningPlatform")
    platform:SetAttribute("SpinSpeed", 10)
    platform:SetAttribute("SpinAxis", "Y")
end
```
- Rotating obstacles
- Timing-based challenge

**WallRun**
```
[Start] → [Wall with ledge] → [Turn 90°] → [End]
```
- Platforms against vertical wall
- Tests spatial awareness

---

### Hard Difficulty (Target: 7-9/10)

**NarrowPath**
```
[Start] → [1-stud wide path, 40 studs] → [End]
```
- Extreme precision required
- High fall risk

**TripleJump**
```
[Start] --10 studs--> [1×1 platform] --10 studs--> [1×1] --10 studs--> [End]
```
- Chained difficult jumps
- No safe spots to rest

**Laser Grid** (Requires scripting)
```lua
-- Add moving lasers:
for _, laser in pairs(section.Lasers:GetChildren()) do
    CollectionService:AddTag(laser, "InstantKill")

    -- Tween movement
    local tween = TweenService:Create(laser, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
        Position = laser.Position + Vector3.new(0, 10, 0)
    })
    tween:Play()
end
```

**DisappearingPath**
```lua
-- Platforms disappear after stepping on:
for _, platform in pairs(section.DisappearingPlatforms:GetChildren()) do
    platform.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            wait(0.5)
            platform.Transparency = 1
            platform.CanCollide = false
            wait(3)
            platform.Transparency = 0
            platform.CanCollide = true
        end
    end)
end
```

---

## ⚡ Advanced Techniques

### Moving Platforms (TweenService)

```lua
-- Place in ServerScriptService/Services/ObbyService/Animators/MovingPlatform.lua
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

for _, platform in pairs(CollectionService:GetTagged("MovingPlatform")) do
    local startPos = platform.Position
    local endPos = platform:GetAttribute("EndPosition") -- Vector3

    local tween = TweenService:Create(
        platform,
        TweenInfo.new(
            platform:GetAttribute("MoveTime") or 3,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            -1, -- Infinite
            true -- Reverse
        ),
        { Position = endPos }
    )

    tween:Play()
end
```

**In Studio:**
1. Tag platform: "MovingPlatform"
2. Set Attribute "EndPosition": `Vector3.new(0, 10, 0)` (relative to start)
3. Set Attribute "MoveTime": `3` (seconds)

### Conveyor Belts (BodyVelocity)

```lua
-- In part's script:
local velocity = Instance.new("BodyVelocity")
velocity.Velocity = Vector3.new(0, 0, 20) -- Move in Z direction
velocity.MaxForce = Vector3.new(0, 0, 40000)

part.Touched:Connect(function(hit)
    local character = hit.Parent
    if character:FindFirstChild("Humanoid") then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local clone = velocity:Clone()
            clone.Parent = rootPart
            task.delay(0.5, function()
                clone:Destroy()
            end)
        end
    end
end)
```

### Dynamic Lava (Rising/Falling)

```lua
-- In HazardService or dedicated script:
local lava = workspace.Tower.CurrentStage.Lava

local tween = TweenService:Create(lava, TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Position = lava.Position + Vector3.new(0, 20, 0)
})
tween:Play()
```

---

## 🎯 Section Variety Checklist

To keep game engaging, include variety across 20+ sections:

**Obstacle Types:**
- [ ] 5+ Jump-based (gaps, triple jumps)
- [ ] 3+ Balance (narrow paths, tightropes)
- [ ] 2+ Timing (moving platforms, lasers)
- [ ] 2+ Spatial (wall runs, spirals)
- [ ] 2+ Hazards (lava, spikes, disappearing)
- [ ] 2+ Speed (conveyors, timed sections)

**Visual Themes:**
- [ ] Open air platforms
- [ ] Enclosed corridors
- [ ] Vertical climbing
- [ ] Downward drops
- [ ] Spiral towers
- [ ] Flat linear

**Length:**
- [ ] 7 Short (20-30 studs)
- [ ] 10 Medium (30-40 studs)
- [ ] 3 Long (40-60 studs)

---

## 🔍 Quality Checklist (Per Section)

Before marking section complete:

**Structure:**
- [ ] PrimaryPart assigned
- [ ] Next point at end (Z=40 typically)
- [ ] Checkpoint at start (Y=3 typically)
- [ ] Colored/One and Two folders populated
- [ ] Bounding box <60×60 studs
- [ ] All parts anchored
- [ ] All collision parts have CanCollide=true
- [ ] All visual-only parts have CanCollide=false

**Gameplay:**
- [ ] Completable by 80%+ of target difficulty
- [ ] Tested 10+ times personally
- [ ] Completion time: Easy <20s, Medium <40s, Hard <60s
- [ ] No invisible walls or stuck spots
- [ ] Checkpoint spawns player safely
- [ ] Next point doesn't overlap obstacle

**Performance:**
- [ ] <200 parts total
- [ ] No unions (use parts or MeshParts)
- [ ] No glass/neon on mobile (use SmoothPlastic)
- [ ] Textures <1024×1024 resolution
- [ ] No ParticleEmitters (or tagged for desktop-only)

**Metadata:**
- [ ] Added to SectionConfig.lua
- [ ] Difficulty rating accurate
- [ ] Spawn weight set (0.5-1.5)
- [ ] Tags added if needed (Lava, SpinningPlatform, etc.)

---

## 💡 Pro Tips

1. **Build in sets of 3-5 sections** to maintain consistent style/difficulty
2. **Playtest immediately** - don't build 10 sections then test all at once
3. **Reference Tower of Hell sections** for inspiration (don't copy!)
4. **Use plugins:**
   - Building Tools by F3X (advanced building)
   - Tag Editor (for CollectionService)
   - Reclass (bulk property changes)
5. **Save variants** - If you make a "JumpGap", save "JumpGapHard" variant
6. **Document tricks** - If a section requires specific tech (wall climb, edge grab), note it
7. **Color blindness** - Test color schemes with Color Blind Sim plugin

---

## 📦 Exporting & Versioning

### When to Save New Version

- ✅ After major redesign (save as "SectionName_v2")
- ✅ Before deleting large portions
- ✅ When creating difficulty variants

### Export Workflow

**For Rojo workflow:**
1. Right-click section → "Save to File"
2. Save to: `models/sections/easy/JumpGap.rbxm`
3. Add to git: `git add models/sections/easy/JumpGap.rbxm`
4. Update SectionConfig.lua

**For Studio-only workflow:**
1. Drag section to ServerStorage.Sections.Easy
2. Publish place
3. Update SectionConfig.lua

---

## 🎓 Learning from Tower of Hell

### Study These Sections (Don't Copy!)

**Easy:**
- "Balance" - Narrow walkway basics
- "QWERTY" - Letter-shaped platforms (visual interest)
- "Cogs" - Rotating platforms (timing introduction)

**Medium:**
- "Doorways" - Precision jumping through holes
- "Towers" - Vertical climbing
- "Maelstrom" - Curved path with momentum

**Hard:**
- "Acceleration" - Speed-based challenge
- "Takeshi's Castle" - Multi-mechanic combination
- "Limbo" - Extreme precision

**Analyze:**
- How are connection points placed?
- What makes it fun vs frustrating?
- Part count vs visual complexity balance
- How is difficulty communicated visually?

---

## 🚀 Production Timeline

**Week 1 (3 sections):** ~24 hours
- Day 1-2: Easy section #1 (JumpGap)
- Day 3-4: Easy section #2 (StairClimb)
- Day 5: Easy section #3 (WideJumps)

**Week 2-3 (10 sections):** ~80 hours
- 4 Easy sections (2 days each)
- 4 Medium sections (3 days each)
- 2 Hard sections (4 days each)

**Week 4 (7 sections):** ~56 hours
- 3 Easy sections
- 3 Medium sections
- 1 Hard section

**Total: 20 sections in ~160 hours**

---

## 📚 Additional Resources

- [Tower of Hell Wiki - Sections](https://tower-of-hell.fandom.com/wiki/Sections)
- [Roblox Building Tutorial](https://create.roblox.com/docs/building-and-visuals)
- [TweenService Guide](https://create.roblox.com/docs/reference/engine/classes/TweenService)
- [CollectionService Docs](https://create.roblox.com/docs/reference/engine/classes/CollectionService)

---

**Ready to build?**

1. Set up template (30 min)
2. Build first Easy section (2 hours)
3. Test and iterate (30 min)
4. Add to ServerStorage (5 min)
5. Repeat for 19 more sections!

**Last Updated:** 2025-01-27
