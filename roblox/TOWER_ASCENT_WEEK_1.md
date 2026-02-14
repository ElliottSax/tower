# Tower Ascent - Week 1 Implementation

> **Foundation week for Tower of Hell clone with meta-progression**

## 🎯 Week 1 Goals

By end of Week 1, you will have:
- ✅ Working 8-minute round system
- ✅ Procedurally generated tower (same for all 20-50 players)
- ✅ Basic coin collection and persistence
- ✅ Memory management (prevent server OOM)
- ✅ Anti-cheat (teleport/fly detection)
- ✅ StreamingEnabled optimization
- ✅ Mobile-optimized settings

**Deliverable:** Working MVP where 20-50 players can climb same tower, earn coins, and see them persist

---

## 📋 Day-by-Day Breakdown

### Day 1: Environment Setup (8 hours)

**Morning (4 hours): Toolchain**

Follow IMPLEMENTATION_WEEK_1.md sections:
1. Install Rokit
2. Install Rojo 7.4.3+
3. Install Wally
4. Create Rojo project

**Afternoon (4 hours): Project Structure**

```bash
# Create directory structure
mkdir -p src/ServerScriptService/Services/ObbyService
mkdir -p src/ServerScriptService/Services
mkdir -p src/ServerStorage/Sections/{Easy,Medium,Hard,Special}
mkdir -p src/ReplicatedStorage/Shared/{Config,Packages}
mkdir -p src/StarterPlayer/StarterPlayerScripts/Controllers
mkdir -p src/StarterGui
```

**Project file (default.project.json):**

```json
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
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "$path": "src/ReplicatedStorage"
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "$path": "src/StarterPlayer"
    },
    "StarterGui": {
      "$className": "StarterGui",
      "$path": "src/StarterGui"
    }
  }
}
```

**Wally packages (wally.toml):**

```toml
[package]
name = "yourname/tower-ascent"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
ProfileService = "madstudioroblox/profileservice@2.0.4"
Promise = "evaera/promise@4.0.0"

[dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```

Run `wally install`

**Test Rojo sync:**
```bash
rojo serve
```
Open Roblox Studio → Plugins → Rojo → Connect

---

### Day 2: Core Generator (8 hours)

**Tower Ascent Generator Modifications:**

The key difference: **Everyone gets the same tower each round**

```lua
-- src/ServerScriptService/Services/ObbyService/Generator.lua

local ServerStorage = game:GetService("ServerStorage")
local Random = Random.new()

local Generator = {}
Generator.CurrentTower = nil
Generator.CurrentSeed = nil
Generator.ActiveStages = {} -- Track for memory management

-- Tower Ascent: Fixed section count per round
local SECTIONS_PER_TOWER = 50

function Generator:GenerateTower(seed: number): Model
    -- Use provided seed (same for all players on server)
    Random = Random.new(seed)
    self.CurrentSeed = seed

    -- Create tower container
    local tower = Instance.new("Model")
    tower.Name = "Tower_" .. seed
    tower.Parent = workspace

    -- Get section pools
    local sections = {
        Easy = ServerStorage.Sections.Easy:GetChildren(),
        Medium = ServerStorage.Sections.Medium:GetChildren(),
        Hard = ServerStorage.Sections.Hard:GetChildren(),
    }

    -- Validate we have sections
    assert(#sections.Easy > 0, "No Easy sections found!")
    assert(#sections.Medium > 0, "No Medium sections found!")
    assert(#sections.Hard > 0, "No Hard sections found!")

    -- Generate sections with difficulty curve
    local previousNext = nil

    for i = 1, SECTIONS_PER_TOWER do
        local difficulty = self:GetDifficultyForStage(i)
        local pool = sections[difficulty]

        -- Pick random section from pool
        local sectionTemplate = pool[Random:NextInteger(1, #pool)]
        local section = sectionTemplate:Clone()

        -- Apply stage number
        section:SetAttribute("StageNumber", i)
        section.Name = "Stage_" .. i

        -- Position section
        if previousNext then
            -- Connect to previous section's Next part
            local nextPart = section:FindFirstChild("Next")
            assert(nextPart, "Section missing Next part: " .. section.Name)

            -- Random rotation (Tower of Hell style)
            local shouldTurn = Random:NextInteger(1, 100) <= 30 -- 30% chance to turn
            local angle = shouldTurn and (Random:NextInteger(1, 3) * 90) or 0

            section:SetPrimaryPartCFrame(
                CFrame.new(previousNext.Position) * CFrame.Angles(0, math.rad(angle), 0)
            )
        else
            -- First section at origin
            section:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
        end

        -- Set up for next section
        previousNext = section:FindFirstChild("Next")

        -- Parent to tower
        section.Parent = tower

        -- Track for memory management
        table.insert(self.ActiveStages, section)
    end

    -- Add finish platform
    local finish = ServerStorage.Sections.Special.Finish:Clone()
    finish:SetPrimaryPartCFrame(CFrame.new(previousNext.Position + Vector3.new(0, 10, 0)))
    finish.Parent = tower

    -- Tag finish for detection
    local finishPart = finish.PrimaryPart
    finishPart:SetAttribute("IsFinish", true)

    self.CurrentTower = tower
    return tower
end

function Generator:GetDifficultyForStage(stageNumber: number): string
    -- Difficulty curve (Tower of Hell style)
    if stageNumber <= 15 then
        return "Easy" -- 30% of tower
    elseif stageNumber <= 35 then
        return "Medium" -- 40% of tower
    else
        return "Hard" -- 30% of tower
    end
end

function Generator:DestroyTower()
    if self.CurrentTower then
        self.CurrentTower:Destroy()
        self.CurrentTower = nil
    end

    self.ActiveStages = {}
    self.CurrentSeed = nil
end

return Generator
```

**Test in Studio:**

1. Create one Easy section in ServerStorage.Sections.Easy (simple platform)
2. Create one Medium section
3. Create one Hard section
4. Create Finish platform in ServerStorage.Sections.Special
5. Run server, call `Generator:GenerateTower(12345)`
6. Verify 50 sections generate

---

### Day 3: Round System (8 hours)

**8-Minute Round Timer:**

```lua
-- src/ServerScriptService/Services/RoundService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyService = require(script.Parent.ObbyService)
local Generator = require(script.Parent.ObbyService.Generator)

local RoundService = {}
RoundService.ROUND_DURATION = 480 -- 8 minutes (Tower of Hell default)
RoundService.INTERMISSION_DURATION = 15 -- 15 seconds between rounds

RoundService.CurrentRound = nil
RoundService.IsIntermission = false

-- Round state
RoundService.RoundNumber = 0
RoundService.TimeRemaining = 0
RoundService.Completions = {}

function RoundService:Init()
    -- Start first round after brief delay
    task.wait(5)
    self:StartRound()
end

function RoundService:StartRound()
    self.IsIntermission = false
    self.RoundNumber += 1
    self.TimeRemaining = self.ROUND_DURATION
    self.Completions = {}

    -- Generate new tower with time-based seed
    local seed = os.time()
    print("[RoundService] Starting Round", self.RoundNumber, "with seed", seed)

    local tower = Generator:GenerateTower(seed)

    self.CurrentRound = {
        Number = self.RoundNumber,
        Seed = seed,
        Tower = tower,
        StartTime = os.time(),
        Completions = {},
    }

    -- Announce round start
    self:AnnounceToAll("Round " .. self.RoundNumber .. " started! Reach the top in 8 minutes!")

    -- Reset all players to spawn
    for _, player in ipairs(Players:GetPlayers()) do
        self:ResetPlayer(player)
        player:SetAttribute("CurrentStage", 0)
        player:SetAttribute("HighestStageThisRound", 0)
    end

    -- Start countdown
    task.spawn(function()
        self:RunCountdown()
    end)
end

function RoundService:RunCountdown()
    local lastUpdate = os.clock()

    while self.TimeRemaining > 0 do
        task.wait(0.1) -- Update 10 times per second for smooth UI

        local now = os.clock()
        local delta = now - lastUpdate
        lastUpdate = now

        self.TimeRemaining -= delta

        -- Update all players every second
        if math.floor(self.TimeRemaining) % 1 < 0.1 then
            self:BroadcastTimeRemaining()
        end

        -- Tower of Hell mechanic: Speed up if someone finishes
        if #self.Completions > 0 then
            self.TimeRemaining -= delta -- Double speed (subtract delta twice)
        end

        -- Warnings
        if math.floor(self.TimeRemaining) == 60 then
            self:AnnounceToAll("⚠️ 1 MINUTE REMAINING!")
        elseif math.floor(self.TimeRemaining) == 10 then
            self:AnnounceToAll("⚠️ 10 SECONDS!")
        end
    end

    self:EndRound()
end

function RoundService:BroadcastTimeRemaining()
    -- Update all players
    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("RoundTimeRemaining", math.max(0, math.floor(self.TimeRemaining)))
    end
end

function RoundService:PlayerReachedFinish(player: Player)
    -- Check if already completed
    for _, completion in ipairs(self.Completions) do
        if completion.Player == player then
            return -- Already finished
        end
    end

    local completionTime = os.time() - self.CurrentRound.StartTime

    table.insert(self.Completions, {
        Player = player,
        Time = completionTime,
    })

    -- Announce
    self:AnnounceToAll(player.Name .. " reached the top in " .. self:FormatTime(completionTime) .. "!")

    -- Award coins (will implement in Day 4)
    local coins = 100 -- Base completion reward
    -- CurrencyService:AwardCoins(player, coins) -- TODO: Day 4

    print("[RoundService]", player.Name, "completed round in", completionTime, "seconds")
end

function RoundService:EndRound()
    print("[RoundService] Round", self.RoundNumber, "ended")

    -- Show leaderboard
    self:DisplayLeaderboard()

    -- Award participation coins based on highest stage
    for _, player in ipairs(Players:GetPlayers()) do
        local highestStage = player:GetAttribute("HighestStageThisRound") or 0
        local coins = math.floor(highestStage * 2) -- 2 coins per stage reached

        -- TODO: Day 4 - CurrencyService:AwardCoins(player, coins)

        print("[RoundService]", player.Name, "earned", coins, "coins (stage", highestStage, ")")
    end

    -- Cleanup tower
    Generator:DestroyTower()

    -- Intermission
    self:StartIntermission()
end

function RoundService:StartIntermission()
    self.IsIntermission = true

    self:AnnounceToAll("Intermission - Next round in " .. self.INTERMISSION_DURATION .. " seconds")

    task.wait(self.INTERMISSION_DURATION)

    self:StartRound()
end

function RoundService:DisplayLeaderboard()
    -- Sort completions by time
    table.sort(self.Completions, function(a, b)
        return a.Time < b.Time
    end)

    -- Announce top 3
    if #self.Completions > 0 then
        self:AnnounceToAll("🏆 TOP FINISHERS:")
        for i = 1, math.min(3, #self.Completions) do
            local completion = self.Completions[i]
            self:AnnounceToAll("#" .. i .. ": " .. completion.Player.Name .. " - " .. self:FormatTime(completion.Time))
        end
    else
        self:AnnounceToAll("Nobody finished this round!")
    end
end

function RoundService:ResetPlayer(player: Player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Health = 0 -- Force respawn
    end
end

function RoundService:AnnounceToAll(message: string)
    for _, player in ipairs(Players:GetPlayers()) do
        -- Send to chat
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[TOWER ASCENT] " .. message,
            Color = Color3.fromRGB(255, 255, 100),
        })
    end

    print("[ANNOUNCEMENT]", message)
end

function RoundService:FormatTime(seconds: number): string
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", mins, secs)
end

-- Detect finish touches
workspace.DescendantAdded:Connect(function(descendant)
    if not descendant:IsA("BasePart") then return end
    if not descendant:GetAttribute("IsFinish") then return end

    descendant.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character then return end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        RoundService:PlayerReachedFinish(player)
    end)
end)

return RoundService
```

**Initialize in server script:**

```lua
-- src/ServerScriptService/init.server.lua

local RoundService = require(script.Services.RoundService)

RoundService:Init()
```

**Test:**
1. Start server
2. Verify tower generates every 8 minutes
3. Touch finish platform, verify completion announced
4. Verify round ends after 8 minutes
5. Verify intermission and new round starts

---

### Day 4: Currency System (8 hours)

**Basic CurrencyService (no ProfileService yet):**

```lua
-- src/ServerScriptService/Services/CurrencyService.lua

local Players = game:GetService("Players")

local CurrencyService = {}
CurrencyService.PlayerCoins = {} -- Temporary in-memory storage

function CurrencyService:Init()
    -- Initialize player coin tracking
    Players.PlayerAdded:Connect(function(player)
        self:InitPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:SavePlayer(player)
    end)
end

function CurrencyService:InitPlayer(player: Player)
    -- TODO: Load from ProfileService (Week 2)
    self.PlayerCoins[player.UserId] = 0

    -- Set attribute for client
    player:SetAttribute("Coins", 0)

    print("[CurrencyService] Initialized", player.Name, "with 0 coins")
end

function CurrencyService:SavePlayer(player: Player)
    -- TODO: Save to ProfileService (Week 2)
    local coins = self.PlayerCoins[player.UserId]
    print("[CurrencyService] Saving", player.Name, "with", coins, "coins (not persisted yet)")

    self.PlayerCoins[player.UserId] = nil
end

function CurrencyService:AwardCoins(player: Player, amount: number)
    if not self.PlayerCoins[player.UserId] then
        warn("[CurrencyService] Player not initialized:", player.Name)
        return
    end

    self.PlayerCoins[player.UserId] += amount
    player:SetAttribute("Coins", self.PlayerCoins[player.UserId])

    print("[CurrencyService]", player.Name, "earned", amount, "coins (total:", self.PlayerCoins[player.UserId], ")")

    -- TODO: Analytics (Week 2)
end

function CurrencyService:SpendCoins(player: Player, amount: number): boolean
    if not self.PlayerCoins[player.UserId] then
        return false
    end

    if self.PlayerCoins[player.UserId] < amount then
        warn("[CurrencyService]", player.Name, "tried to spend", amount, "but only has", self.PlayerCoins[player.UserId])
        return false
    end

    self.PlayerCoins[player.UserId] -= amount
    player:SetAttribute("Coins", self.PlayerCoins[player.UserId])

    print("[CurrencyService]", player.Name, "spent", amount, "coins (remaining:", self.PlayerCoins[player.UserId], ")")

    return true
end

function CurrencyService:GetBalance(player: Player): number
    return self.PlayerCoins[player.UserId] or 0
end

return CurrencyService
```

**Update RoundService to award coins:**

```lua
-- In RoundService:PlayerReachedFinish()
local CurrencyService = require(script.Parent.CurrencyService)

function RoundService:PlayerReachedFinish(player: Player)
    -- ... existing completion logic ...

    -- Award coins
    local coins = 100 -- Base completion reward
    CurrencyService:AwardCoins(player, coins)
end

-- In RoundService:EndRound()
function RoundService:EndRound()
    -- ... existing logic ...

    -- Award participation coins
    for _, player in ipairs(Players:GetPlayers()) do
        local highestStage = player:GetAttribute("HighestStageThisRound") or 0
        local coins = math.floor(highestStage * 2) -- 2 coins per stage reached

        CurrencyService:AwardCoins(player, coins)
    end

    -- ... rest of function ...
end
```

**Initialize in server:**

```lua
-- src/ServerScriptService/init.server.lua

local CurrencyService = require(script.Services.CurrencyService)
local RoundService = require(script.Services.RoundService)

CurrencyService:Init()
RoundService:Init()
```

**Test:**
1. Join server
2. Verify Coins attribute set to 0
3. Reach stage 10, let round end
4. Verify 20 coins awarded (10 stages × 2)
5. Complete tower, verify 100 bonus coins
6. Check player.Coins attribute updated

---

### Day 5: Memory Management & Anti-Cheat (8 hours)

**MemoryManager (same as original plan):**

```lua
-- src/ServerScriptService/Services/ObbyService/MemoryManager.lua

local Players = game:GetService("Players")

local MemoryManager = {}
MemoryManager.MAX_STAGES_LOADED = 20 -- Keep 20 stages around active players

function MemoryManager:Init(generator)
    self.Generator = generator

    -- Clean up every 10 seconds
    task.spawn(function()
        while true do
            task.wait(10)
            self:CleanupDistantStages()
        end
    end)
end

function MemoryManager:CleanupDistantStages()
    -- Find highest player stage
    local maxPlayerStage = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local stage = player:GetAttribute("CurrentStage") or 0
        if stage > maxPlayerStage then
            maxPlayerStage = stage
        end
    end

    -- Cleanup stages far behind
    local cleaned = 0
    for i = #self.Generator.ActiveStages, 1, -1 do
        local stage = self.Generator.ActiveStages[i]
        local stageNumber = stage:GetAttribute("StageNumber") or 0

        -- Keep stages within range
        if stageNumber < (maxPlayerStage - self.MAX_STAGES_LOADED) then
            stage:Destroy()
            table.remove(self.Generator.ActiveStages, i)
            cleaned += 1
        end
    end

    if cleaned > 0 then
        print("[MemoryManager] Cleaned up", cleaned, "distant stages")
    end
end

return MemoryManager
```

**AntiCheat (basic teleport/fly detection):**

```lua
-- src/ServerScriptService/Services/AntiCheat.lua

local Players = game:GetService("Players")

local AntiCheat = {}
AntiCheat.TELEPORT_THRESHOLD = 50 -- studs per 0.1s = suspicious
AntiCheat.VERTICAL_THRESHOLD = 30 -- flying detection
AntiCheat.LastPositions = {}

function AntiCheat:Init()
    Players.PlayerAdded:Connect(function(player)
        self:TrackPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastPositions[player.UserId] = nil
    end)
end

function AntiCheat:TrackPlayer(player: Player)
    player.CharacterAdded:Connect(function(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        task.spawn(function()
            self:MonitorPosition(player, humanoidRootPart)
        end)
    end)
end

function AntiCheat:MonitorPosition(player: Player, hrp: BasePart)
    local lastPos = hrp.Position
    local lastTime = os.clock()

    while hrp.Parent do
        task.wait(0.1)

        local currentPos = hrp.Position
        local currentTime = os.clock()
        local delta = currentTime - lastTime

        -- Check horizontal speed
        local horizontalDist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)).Magnitude
        if horizontalDist / delta > self.TELEPORT_THRESHOLD then
            warn("[AntiCheat] Suspicious teleport:", player.Name, horizontalDist, "studs in", delta, "seconds")
            -- TODO: Kick or flag player
        end

        -- Check vertical speed (flying)
        local verticalDist = currentPos.Y - lastPos.Y
        if verticalDist > self.VERTICAL_THRESHOLD and delta < 0.5 then
            warn("[AntiCheat] Suspicious vertical movement:", player.Name, verticalDist, "studs up")
        end

        lastPos = currentPos
        lastTime = currentTime
    end
end

return AntiCheat
```

**StreamingEnabled (Workspace property):**

Set in Studio manually:
1. Workspace → Properties → StreamingEnabled = true
2. Workspace → StreamingTargetRadius = 256
3. Workspace → StreamingMinRadius = 64

Or via script:

```lua
-- src/ServerScriptService/init.server.lua

workspace.StreamingEnabled = true
workspace.StreamingTargetRadius = 256
workspace.StreamingMinRadius = 64
```

**MobileOptimizer (client-side):**

```lua
-- src/StarterPlayer/StarterPlayerScripts/MobileOptimizer.client.lua

local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    -- Reduce graphics quality
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level05 -- Mid quality

    -- Disable expensive effects
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    print("[MobileOptimizer] Applied mobile optimizations")
end
```

**Initialize in server:**

```lua
-- src/ServerScriptService/init.server.lua

local MemoryManager = require(script.Services.ObbyService.MemoryManager)
local Generator = require(script.Services.ObbyService.Generator)
local AntiCheat = require(script.Services.AntiCheat)
local CurrencyService = require(script.Services.CurrencyService)
local RoundService = require(script.Services.RoundService)

-- StreamingEnabled
workspace.StreamingEnabled = true
workspace.StreamingTargetRadius = 256
workspace.StreamingMinRadius = 64

-- Initialize services
MemoryManager:Init(Generator)
AntiCheat:Init()
CurrencyService:Init()
RoundService:Init()

print("[Server] Tower Ascent initialized")
```

---

## ✅ Week 1 Deliverables Checklist

### Core Systems
- [ ] Rojo project syncing successfully
- [ ] Wally packages installed (ProfileService, Promise)
- [ ] Selene + StyLua configured
- [ ] Generator creates 50-stage tower from seed
- [ ] RoundService runs 8-minute rounds
- [ ] Intermission between rounds works
- [ ] CurrencyService tracks coins (in-memory)
- [ ] Coins awarded for completion (100) and participation (2/stage)
- [ ] MemoryManager cleans up distant stages
- [ ] AntiCheat monitors teleport/fly
- [ ] StreamingEnabled configured
- [ ] MobileOptimizer reduces quality on mobile

### Testing
- [ ] Generate tower with seed 12345, verify deterministic
- [ ] Generate with same seed twice, verify identical layout
- [ ] Touch finish, verify completion announced
- [ ] Wait 8 minutes, verify round ends and new tower generates
- [ ] Verify coins awarded at round end
- [ ] Verify player.Coins attribute updates
- [ ] Test with 2-3 players simultaneously

### Content
- [ ] At least 1 Easy section in ServerStorage.Sections.Easy
- [ ] At least 1 Medium section in ServerStorage.Sections.Medium
- [ ] At least 1 Hard section in ServerStorage.Sections.Hard
- [ ] Finish platform in ServerStorage.Sections.Special.Finish

**If all checkboxes complete: READY FOR WEEK 2** ✅

---

## 🔧 Troubleshooting Week 1

### "Tower not generating"

Check:
1. Sections exist in ServerStorage.Sections.*
2. Each section has PrimaryPart set
3. Each section has Next part
4. Console for errors

### "Coins not saving"

Expected - persistence added in Week 2 with ProfileService. Coins only persist during session in Week 1.

### "Round not ending after 8 minutes"

Check:
1. RoundService:Init() called in init.server.lua
2. Console for errors in RunCountdown()

### "Players falling through floor"

Check:
1. Section parts are Anchored = true
2. Section PrimaryPart set correctly
3. StreamingEnabled might be unloading parts - increase StreamingTargetRadius

---

## 📊 Expected Week 1 Metrics

**Development Time:** 40 hours (5 days × 8 hours)

**Lines of Code:**
- Generator.lua: ~150 lines
- RoundService.lua: ~200 lines
- CurrencyService.lua: ~80 lines
- MemoryManager.lua: ~50 lines
- AntiCheat.lua: ~60 lines
- MobileOptimizer.client.lua: ~20 lines
- init.server.lua: ~30 lines
**Total: ~590 lines**

**Performance Targets:**
- Server memory: <300MB (20-50 players)
- Client FPS: 60+ on PC, 40+ on mobile
- Round transition: <3 seconds

---

## 🎯 Next Steps (Week 2)

After completing Week 1, move to **Week 2-5 implementation:**

1. **ProfileService integration** - Persist coins permanently
2. **UpgradeService** - Purchase and apply upgrades (double jump, etc.)
3. **CheckpointService** - Track stage progression (for participation coins)
4. **AnalyticsService** - Log events (batched)
5. **TestEZ suite** - Automated testing

---

**Last Updated:** 2025-01-27
**Status:** Ready to begin
**Next:** Day 1 - Environment Setup

