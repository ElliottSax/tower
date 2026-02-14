# Tower Ascent - 2-Hour Quick Start

> **Get a working Tower of Hell clone prototype running in 2 hours**

## 🎯 What You'll Build

In 2 hours, you'll have:
- 20-50 players on same server
- Procedurally generated tower (same for everyone)
- 8-minute round timer
- Basic coin collection
- Round resets with new tower

**This is a PROTOTYPE** - full production takes 16-20 weeks. Use this to validate the concept.

---

## ⚡ 30-Minute Setup

### Step 1: Install Tooling (10 minutes)

**Install Roblox Studio** (if not already):
https://www.roblox.com/create

**Install Rojo** (sync filesystem to Studio):

```bash
# Install Aftman (tool manager)
curl -L https://github.com/LPGhatguy/aftman/releases/latest/download/aftman-linux-x86_64.zip -o aftman.zip
unzip aftman.zip
chmod +x aftman
sudo mv aftman /usr/local/bin/

# Install Rojo via Aftman
aftman add rojo-rbx/rojo@7.4.3
aftman install
```

Or install directly:
https://github.com/rojo-rbx/rojo/releases

**Install Rojo plugin in Studio:**
1. Open Studio
2. Plugins → Manage Plugins
3. Search "Rojo"
4. Install "Rojo 7"

### Step 2: Create Project (10 minutes)

```bash
# Create directory
mkdir tower-ascent
cd tower-ascent

# Create structure
mkdir -p src/ServerScriptService
mkdir -p src/ServerStorage/Sections/Easy
mkdir -p src/Workspace
```

**Create Rojo project file:**

```bash
cat > default.project.json << 'EOF'
{
  "name": "TowerAscent",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/ServerScriptService"
    },
    "ServerStorage": {
      "$className": "ServerStorage",
      "$path": "src/ServerStorage"
    },
    "Workspace": {
      "$className": "Workspace",
      "$path": "src/Workspace",
      "$properties": {
        "StreamingEnabled": true
      }
    }
  }
}
EOF
```

### Step 3: Start Rojo (5 minutes)

```bash
# Start Rojo server
rojo serve
```

**In Roblox Studio:**
1. Create new Baseplate
2. Plugins → Rojo → Connect
3. Should say "Connected to localhost:34872"

### Step 4: Verify Sync (5 minutes)

**Test sync works:**

```bash
# Create test file
echo 'print("Hello from Rojo!")' > src/ServerScriptService/test.server.lua
```

In Studio:
1. Check ServerScriptService → test script should appear
2. Run game (F5) → Output should show "Hello from Rojo!"
3. Stop game, delete test.server.lua

---

## 🏗️ 1-Hour Build

### Step 1: Create Spawn (10 minutes)

**In Roblox Studio:**

1. Insert Part in Workspace
2. Properties:
   - Size: 50, 1, 50
   - Position: 0, 0, 0
   - Anchored: true
   - Color: Green
3. Name it "SpawnPlatform"

4. Insert SpawnLocation in SpawnPlatform
5. Properties:
   - Transparency: 1
   - Position: 0, 5, 0

**Save place file:**
File → Publish to Roblox → "Tower Ascent Prototype"

### Step 2: Create Section Template (15 minutes)

**In ServerStorage:**

1. Right-click ServerStorage → Insert Object → Folder → Name it "Sections"
2. Right-click Sections → Insert Object → Folder → Name it "Easy"
3. Right-click Easy → Insert Object → Model → Name it "JumpGap"

**Build the JumpGap section:**

1. Insert Part in JumpGap model
   - Size: 8, 1, 8
   - Position: 0, 0, 0
   - Anchored: true
   - Color: Random
   - Name: "Start"

2. Insert Part in JumpGap model
   - Size: 8, 1, 8
   - Position: 0, 0, 15 (gap of 7 studs)
   - Anchored: true
   - Color: Same as Start
   - Name: "Next"

3. Select JumpGap model
4. Properties → PrimaryPart → select "Start"

**Copy template 4 more times:**
- Duplicate JumpGap (Ctrl+D)
- Name them: JumpGap2, JumpGap3, JumpGap4, JumpGap5
- Vary Next position slightly (12-18 studs gap)

**You should now have 5 sections in ServerStorage.Sections.Easy**

### Step 3: Generator Script (20 minutes)

**Create generator:**

```bash
cat > src/ServerScriptService/TowerGenerator.server.lua << 'EOF'
local ServerStorage = game:GetService("ServerStorage")

-- Config
local SECTIONS_PER_TOWER = 20
local ROUND_DURATION = 480 -- 8 minutes

-- Get section templates
local sections = ServerStorage.Sections.Easy:GetChildren()

print("Found", #sections, "section templates")

-- Generate tower function
local function GenerateTower(seed)
    local rng = Random.new(seed)

    local tower = Instance.new("Model")
    tower.Name = "Tower_" .. seed

    local previousNext = nil

    for i = 1, SECTIONS_PER_TOWER do
        -- Pick random section
        local template = sections[rng:NextInteger(1, #sections)]
        local section = template:Clone()

        section.Name = "Stage_" .. i
        section:SetAttribute("StageNumber", i)

        -- Position section
        if previousNext then
            -- Random turn (30% chance)
            local shouldTurn = rng:NextInteger(1, 100) <= 30
            local angle = shouldTurn and (rng:NextInteger(1, 3) * 90) or 0

            section:SetPrimaryPartCFrame(
                CFrame.new(previousNext.Position) *
                CFrame.Angles(0, math.rad(angle), 0)
            )
        else
            -- First section
            section:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
        end

        -- Get Next part for next section
        previousNext = section:FindFirstChild("Next")

        section.Parent = tower
    end

    -- Add finish platform
    local finish = Instance.new("Part")
    finish.Name = "Finish"
    finish.Size = Vector3.new(20, 1, 20)
    finish.Position = previousNext.Position + Vector3.new(0, 10, 0)
    finish.Anchored = true
    finish.Color = Color3.fromRGB(255, 215, 0) -- Gold
    finish:SetAttribute("IsFinish", true)
    finish.Parent = tower

    tower.Parent = workspace

    print("Generated tower with", SECTIONS_PER_TOWER, "sections")

    return tower
end

-- Round system
local currentTower = nil
local roundNumber = 0

local function StartRound()
    roundNumber = roundNumber + 1
    local seed = os.time()

    print("=== ROUND", roundNumber, "STARTED (Seed:", seed, ") ===")

    -- Destroy old tower
    if currentTower then
        currentTower:Destroy()
    end

    -- Generate new tower
    currentTower = GenerateTower(seed)

    -- Wait for round duration
    task.wait(ROUND_DURATION)

    -- Round ended
    print("=== ROUND", roundNumber, "ENDED ===")

    -- Brief intermission
    task.wait(15)

    -- Start next round
    StartRound()
end

-- Start first round after 5 seconds
task.wait(5)
StartRound()
EOF
```

**Sync to Studio:**
1. File should appear in ServerScriptService
2. Run game (F5)
3. Output should show "Generated tower with 20 sections"
4. You should see tower in workspace

### Step 4: Basic Coin System (15 minutes)

**Create coin tracker:**

```bash
cat > src/ServerScriptService/CoinSystem.server.lua << 'EOF'
local Players = game:GetService("Players")

-- Track player coins (in-memory only)
local playerCoins = {}

-- Initialize player
Players.PlayerAdded:Connect(function(player)
    playerCoins[player.UserId] = 0

    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    print(player.Name, "joined with 0 coins")
end)

-- Award coins function
local function AwardCoins(player, amount)
    if not playerCoins[player.UserId] then return end

    playerCoins[player.UserId] = playerCoins[player.UserId] + amount

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value = playerCoins[player.UserId]
        end
    end

    print(player.Name, "earned", amount, "coins (total:", playerCoins[player.UserId], ")")
end

-- Detect finish touches
workspace.DescendantAdded:Connect(function(descendant)
    if not descendant:IsA("BasePart") then return end
    if not descendant:GetAttribute("IsFinish") then return end

    print("Finish platform detected, setting up touch event")

    descendant.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character then return end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        print(player.Name, "reached the finish!")

        -- Award completion bonus
        AwardCoins(player, 100)
    end)
end)

print("Coin system initialized")
EOF
```

**Test:**
1. Run game
2. Join as player
3. Climb to finish (or teleport with Roblox Studio tools)
4. Touch finish platform
5. Leaderstats should update with 100 coins

---

## ✅ 2-Hour Milestone Checklist

**You should now have:**

- [ ] Rojo syncing files to Studio
- [ ] 5 section templates in ServerStorage.Sections.Easy
- [ ] TowerGenerator creating 20-section tower
- [ ] Tower regenerates every 8 minutes
- [ ] Coin system tracking completions
- [ ] Leaderstats showing coin balance

**Test with friends:**
1. Publish place to Roblox
2. Set max players to 50
3. Invite 2-3 friends
4. Verify everyone sees same tower layout
5. Race to the top!

---

## 🎨 Quick Improvements (30 minutes each)

### Add Timer Display

Create ScreenGui showing round timer:

```bash
mkdir -p src/StarterGui/TimerGui

cat > src/StarterGui/TimerGui/TimerDisplay.client.lua << 'EOF'
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TimerGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 200, 0, 50)
timerLabel.Position = UDim2.new(0.5, -100, 0, 10)
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.BackgroundTransparency = 0.5
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextSize = 24
timerLabel.Font = Enum.Font.SourceSansBold
timerLabel.Text = "8:00"
timerLabel.Parent = screenGui

-- Update every second (mock countdown for now)
-- TODO: Sync with actual server timer in Week 2
local timeLeft = 480

while true do
    task.wait(1)
    timeLeft = math.max(0, timeLeft - 1)

    local mins = math.floor(timeLeft / 60)
    local secs = timeLeft % 60

    timerLabel.Text = string.format("%d:%02d", mins, secs)

    if timeLeft == 0 then
        timeLeft = 480 -- Reset
    end
end
EOF
```

### Add Participation Coins

Modify TowerGenerator.server.lua to track stage progress:

```lua
-- In StartRound() function, before task.wait(ROUND_DURATION):

-- Track player progress
local playerStages = {}

for _, player in ipairs(game.Players:GetPlayers()) do
    playerStages[player.UserId] = 0
end

-- Monitor stage touches
currentTower.DescendantAdded:Connect(function(part)
    if not part:IsA("BasePart") then return end

    part.Touched:Connect(function(hit)
        local char = hit.Parent
        if not char then return end

        local player = game.Players:GetPlayerFromCharacter(char)
        if not player then return end

        local stageNum = part.Parent:GetAttribute("StageNumber")
        if stageNum and stageNum > (playerStages[player.UserId] or 0) then
            playerStages[player.UserId] = stageNum
            print(player.Name, "reached stage", stageNum)
        end
    end)
end)

-- After task.wait(ROUND_DURATION), award participation coins:
for userId, highestStage in pairs(playerStages) do
    local player = game.Players:GetPlayerByUserId(userId)
    if player then
        local coins = highestStage * 2 -- 2 coins per stage
        -- Call AwardCoins() from CoinSystem
        print("Award", coins, "participation coins to", player.Name)
    end
end
```

### Add Sound Effects

In Studio:
1. Insert Sound in Workspace
2. SoundId = "rbx://assetid/14226126822" (jump sound)
3. Name = "JumpSound"

In character script:

```lua
-- src/StarterPlayer/StarterCharacterScripts/JumpSound.client.lua
local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local jumpSound = workspace:WaitForChild("JumpSound")

humanoid.StateChanged:Connect(function(old, new)
    if new == Enum.HumanoidStateType.Jumping then
        jumpSound:Play()
    end
end)
```

---

## 🚀 Next Steps

### This Prototype Validates:
- ✅ Tower generation works
- ✅ Everyone sees same tower (deterministic seeds)
- ✅ 8-minute rounds functional
- ✅ Basic coin economy

### What's Missing (Week 2-20):
- ⚠️ Coins don't persist (need ProfileService)
- ⚠️ No upgrades (need UpgradeService)
- ⚠️ No daily challenges
- ⚠️ No battle pass
- ⚠️ Only 5 section templates (need 30+)
- ⚠️ No mobile optimization
- ⚠️ No anti-cheat
- ⚠️ No analytics

### To Continue to Production:

**Follow full implementation:**
1. [TOWER_ASCENT_IMPLEMENTATION.md](./TOWER_ASCENT_IMPLEMENTATION.md) - Complete overview
2. [TOWER_ASCENT_WEEK_1.md](./TOWER_ASCENT_WEEK_1.md) - Week 1 detailed guide
3. [IMPLEMENTATION_WEEK_2-5.md](./IMPLEMENTATION_WEEK_2-5.md) - Core systems
4. [SECTION_CREATION_GUIDE.md](./SECTION_CREATION_GUIDE.md) - Build 30 sections
5. [IMPLEMENTATION_WEEK_6-20.md](./IMPLEMENTATION_WEEK_6-20.md) - Polish & launch

**Timeline:** 16-20 weeks to production-ready game

---

## 🎯 Success Metrics for Prototype

**You'll know the prototype is working if:**

✅ **Technical:**
- Rojo syncs files without errors
- Tower generates in <2 seconds
- No red errors in Output
- Multiple players can join

✅ **Gameplay:**
- Tower is climbable (not too easy/hard)
- Finish platform touchable
- Coins award correctly
- Round resets after 8 minutes

✅ **Performance:**
- 60 FPS on decent PC
- <300MB server memory
- No lag spikes during tower generation

**If all green checkmarks: READY FOR FULL PRODUCTION** ✅

---

## 🆘 Quick Troubleshooting

### "Rojo won't connect"

1. Check Rojo is running (`rojo serve`)
2. Check port 34872 not blocked
3. Restart Studio
4. Reinstall Rojo plugin

### "Tower not generating"

1. Check ServerStorage.Sections.Easy has sections
2. Check each section has PrimaryPart set
3. Check each section has "Next" part
4. Check Output for errors

### "Sections floating/overlapping"

Normal for prototype - proper positioning comes in Week 1 full implementation.

### "Coins not showing"

1. Check leaderstats folder created
2. Check CoinSystem.server.lua running
3. Check Output for errors
4. Verify touch event firing (add print statements)

---

## 💡 Tips for Success

**DO:**
- ✅ Start simple (5 sections is enough for prototype)
- ✅ Test frequently (run game after every change)
- ✅ Read Output console (critical for debugging)
- ✅ Invite friends to test multiplayer

**DON'T:**
- ❌ Overcomplicate sections yet (save for Week 6+)
- ❌ Worry about persistence (Week 2)
- ❌ Optimize prematurely (Week 5+)
- ❌ Skip testing (builds bad habits)

---

**You now have a working Tower Ascent prototype! 🎉**

**Ready for production?** → [TOWER_ASCENT_WEEK_1.md](./TOWER_ASCENT_WEEK_1.md)

**Questions?** → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

**Last Updated:** 2025-01-27
**Time to Complete:** 2 hours
**Prerequisites:** Roblox Studio installed, basic Lua knowledge

