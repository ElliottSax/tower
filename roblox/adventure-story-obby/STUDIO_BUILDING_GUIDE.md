# Studio Building Guide

Complete guide for building the visual elements of Adventure Story Obby in Roblox Studio.

---

## 🎨 Overview

All the **code is complete** - you just need to build the **visual elements**:
1. Hub world (spawn + NPC markers)
2. 5 levels for World 1
3. Collectibles placement
4. Optional: Custom NPC models

Estimated time: **2-4 hours** for basic version

---

## 🏗️ Part 1: Hub World (30 minutes)

### Step 1: Create Spawn Point

1. Insert a **Part** in Workspace
2. Name it: `HubSpawn`
3. Set properties:
   - Position: `0, 10, 0`
   - Size: `10, 1, 10`
   - Anchored: ✅ True
   - Transparency: `1` (invisible)
   - CanCollide: ❌ False

### Step 2: Create Floor

1. Insert a **Part** in Workspace
2. Name it: `HubFloor`
3. Set properties:
   - Position: `0, 0, 0`
   - Size: `200, 1, 200`
   - Anchored: ✅ True
   - Material: `Grass` or `Concrete`
   - Color: `0.3, 0.6, 0.3` (green)

### Step 3: Create NPC Spawn Markers

Create 3 parts for NPC spawn locations:

**NPC 1: Guide (Elder Moss)**
1. Insert Part
2. Name: `Hub_Guide`
3. Position: `-40, 5, 0`
4. Size: `4, 6, 4`
5. Anchored: ✅ True
6. Transparency: `1`
7. CanCollide: ❌ False

**NPC 2: Merchant (Trader Tom)**
1. Insert Part
2. Name: `Hub_Merchant`
3. Position: `40, 5, 0`
4. Size: `4, 6, 4`
5. Anchored: ✅ True
6. Transparency: `1`
7. CanCollide: ❌ False

**NPC 3: Elder (Ancient One)**
1. Insert Part
2. Name: `Hub_Elder`
3. Position: `0, 5, -40`
4. Size: `4, 6, 4`
5. Anchored: ✅ True
6. Transparency: `1`
7. CanCollide: ❌ False

### Step 4: Add Decorations (Optional)

Add trees, rocks, buildings, etc. to make the hub look nice.

**Quick Tree:**
1. Insert Part (trunk): `2x10x2`, Brown
2. Insert Part (leaves): `8x8x8`, Green, on top
3. Group as Model
4. Duplicate around hub

---

## 🗺️ Part 2: Level 1 - Tutorial Path (30 minutes)

### Overview
- **Difficulty:** Easy
- **Checkpoints:** 3
- **Platforms:** 6-8
- **Theme:** Simple straight path

### Step 1: Create Level Folder

1. In Workspace, insert a **Folder**
2. Name it: `World1_Level1`

### Step 2: Create Spawn Point

1. Inside `World1_Level1` folder, insert a **Part**
2. Name it: `Spawn`
3. Set properties:
   - Position: `200, 10, 0` (away from hub)
   - Size: `10, 1, 10`
   - Anchored: ✅ True
   - Material: `Neon`
   - Color: `0, 1, 0` (green)

### Step 3: Build Platform Path

Create 6-8 platforms in a straight line:

**Platform Template:**
- Size: `10, 1, 10`
- Anchored: ✅ True
- Material: `Plastic`
- Color: `0.5, 0.3, 0.2` (wood brown)
- Spacing: `15 studs` apart

**Platform Positions:**
1. Start: `210, 10, 0`
2. Platform 2: `225, 10, 0`
3. Checkpoint 1: `240, 10, 0`
4. Platform 3: `255, 10, 0`
5. Platform 4: `270, 10, 0`
6. Checkpoint 2: `285, 10, 0`
7. Platform 5: `300, 10, 0`
8. Checkpoint 3: `315, 10, 0`
9. Finish: `330, 10, 0`

### Step 4: Create Checkpoints

**Checkpoint Part Template:**
1. Insert Part at checkpoint positions
2. Name: `Checkpoint1`, `Checkpoint2`, `Checkpoint3`
3. Size: `10, 1, 10`
4. Anchored: ✅ True
5. Material: `Neon`
6. Color: `1, 1, 0` (yellow)
7. Transparency: `0.5`

**Add Checkpoint Script:**
Insert a **Script** inside each checkpoint part:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local setCheckpointRemote = remoteEvents:WaitForChild("SetCheckpoint")

local CHECKPOINT_ID = 1 -- Change to 2, 3 for other checkpoints

script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            setCheckpointRemote:FireServer(CHECKPOINT_ID, script.Parent.CFrame)
            print("Checkpoint", CHECKPOINT_ID, "saved!")
        end
    end
end)
```

### Step 5: Create Finish Line

1. Insert Part at end position (`330, 10, 0`)
2. Name: `Finish`
3. Size: `12, 8, 1`
4. Anchored: ✅ True
5. Material: `Neon`
6. Color: `0, 1, 0` (green)

**Add Finish Script:**
Insert a **Script** inside Finish part:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local completeLevelEvent = remoteEvents:WaitForChild("CompleteLevelEvent")

local debounce = {}

script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player and not debounce[player] then
            debounce[player] = true

            print(player.Name, "completed the level!")
            completeLevelEvent:FireServer()

            -- Show completion message
            local gui = Instance.new("ScreenGui")
            gui.ResetOnSpawn = false

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0.2, 0)
            label.Position = UDim2.new(0, 0, 0.4, 0)
            label.BackgroundTransparency = 1
            label.Text = "LEVEL COMPLETE!"
            label.TextColor3 = Color3.new(0, 1, 0)
            label.TextScaled = true
            label.Font = Enum.Font.SourceSansBold
            label.Parent = gui

            gui.Parent = player.PlayerGui

            wait(2)
            gui:Destroy()

            task.wait(1)
            debounce[player] = nil
        end
    end
end)
```

### Step 6: Add Decorations (Optional)

- Add walls on sides
- Add trees/rocks nearby
- Add ambient lighting

---

## 🌲 Part 3: Level 2 - Forest Trail (45 minutes)

### Overview
- **Difficulty:** Easy
- **Checkpoints:** 4
- **Platforms:** 10-12 (some moving)
- **Fragment:** 1
- **Theme:** Forest with moving platforms

### Key Features
- 3-4 **moving platforms** (side-to-side)
- Hidden **fragment collectible**
- Winding path (not straight)

### Moving Platform Template

1. Create a Part (platform)
2. Add a **Script** inside it:

```lua
-- Simple moving platform (side-to-side)
local platform = script.Parent
local startPos = platform.Position
local moveDistance = 20 -- studs to move
local speed = 2 -- seconds per cycle

while true do
    -- Move right
    for i = 0, 1, 0.02 do
        platform.Position = startPos + Vector3.new(moveDistance * i, 0, 0)
        wait(speed / 50)
    end

    -- Move left
    for i = 1, 0, -0.02 do
        platform.Position = startPos + Vector3.new(moveDistance * i, 0, 0)
        wait(speed / 50)
    end
end
```

### Fragment Collectible

1. Insert a **Part** (hidden in the level)
2. Name: `Fragment1`
3. Size: `2, 2, 2`
4. Anchored: ✅ True
5. Shape: `Ball`
6. Material: `Neon`
7. Color: `0.4, 0.8, 1` (light blue)

**Set Attributes:**
- Right-click part → **Add Attribute**
- Name: `CollectibleType` | Type: `String` | Value: `"Fragment"`
- Add Attribute
- Name: `CollectibleId` | Type: `String` | Value: `"Fragment_W1_L2"`

The CollectibleService will handle the rest automatically!

---

## 🌊 Part 4: Level 3 - River Crossing (45 minutes)

### Overview
- **Difficulty:** Normal
- **Checkpoints:** 5
- **Platforms:** Disappearing + moving
- **Fragment:** 1
- **Theme:** Water hazards, timing challenges

### Key Features
- **Water** (kill parts below platforms)
- **Disappearing platforms** (fade in/out)
- **Timed jumps** required

### Water Kill Part

1. Create large Part below level
2. Name: `Water`
3. Size: `100, 50, 100`
4. Position: `Y = -20` (below platforms)
5. Anchored: ✅ True
6. Material: `Water`
7. Color: `0.2, 0.4, 0.8` (blue)
8. Transparency: `0.3`
9. CanCollide: ❌ False

**Add Kill Script:**
```lua
script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Health = 0
        print(hit.Parent.Name, "fell in water!")
    end
end)
```

### Disappearing Platform

1. Create Part
2. Add **Script**:

```lua
local platform = script.Parent
local fadeTime = 3 -- seconds visible
local respawnTime = 2 -- seconds invisible

while true do
    -- Visible
    platform.Transparency = 0
    platform.CanCollide = true
    wait(fadeTime)

    -- Warning (flash)
    for i = 1, 3 do
        platform.Transparency = 0.5
        wait(0.2)
        platform.Transparency = 0
        wait(0.2)
    end

    -- Invisible
    platform.Transparency = 1
    platform.CanCollide = false
    wait(respawnTime)
end
```

---

## 🏛️ Part 5: Level 4 - Ancient Ruins (60 minutes)

### Overview
- **Difficulty:** Normal
- **Checkpoints:** 6
- **Platforms:** Complex paths with hazards
- **Fragment:** 1
- **Theme:** Ruins with spikes and traps

### Key Features
- **Spike traps** (kill on touch)
- **Multiple paths** (optional routes)
- **Hidden fragment** in secret area

### Spike Trap

1. Create Part (spike shape)
2. Size: `4, 2, 4`
3. Material: `Metal`
4. Color: `0.5, 0.5, 0.5` (gray)
5. Anchored: ✅ True

**Add Kill Script:**
```lua
script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Health = humanoid.Health - 50 -- Damage (not instant kill)
        print(hit.Parent.Name, "hit spikes!")
    end
end)
```

### Secret Area for Fragment

Create a hidden path that leads to the fragment:
- Use transparent walls to hide entrance
- Add parkour challenge to reach it
- Place fragment at end

---

## 🚪 Part 6: Level 5 - Guardian's Gate (90 minutes)

### Overview
- **Difficulty:** Hard
- **Checkpoints:** 7
- **Platforms:** All mechanics combined
- **Theme:** Epic finale, boss-style level

### Key Features
- **All previous mechanics** combined
- Moving platforms + disappearing platforms
- Water hazards + spike traps
- Long jumps required
- **Finale room** with climactic moment

### Boss-Style Finale

Create a large platform at the end with:
1. Central platform (safe zone)
2. Surrounding hazards
3. Epic lighting effects
4. Finish portal/gate

**Add Dramatic Finish:**
```lua
-- Add this to the finish part
local TweenService = game:GetService("TweenService")

script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            -- Create dramatic effect
            local gui = Instance.new("ScreenGui")
            gui.ResetOnSpawn = false

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 1
            bg.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0.3, 0)
            label.Position = UDim2.new(0, 0, 0.35, 0)
            label.BackgroundTransparency = 1
            label.Text = "THE CURSE IS BROKEN!"
            label.TextColor3 = Color3.new(1, 0.8, 0)
            label.TextScaled = true
            label.Font = Enum.Font.SourceSansBold
            label.TextTransparency = 1
            label.Parent = gui

            gui.Parent = player.PlayerGui

            -- Fade in
            TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 0}):Play()

            wait(3)

            -- Fade out
            TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
            TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1}):Play()

            wait(1)
            gui:Destroy()
        end
    end
end)
```

---

## 🎨 Part 7: Visual Polish (Optional)

### Lighting

```lua
-- Insert in Lighting service
local Lighting = game:GetService("Lighting")

-- Mystic Forest theme
Lighting.Ambient = Color3.fromRGB(100, 150, 100)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 170, 120)
Lighting.Brightness = 2
Lighting.ClockTime = 14 -- 2 PM

-- Add atmosphere
local Atmosphere = Instance.new("Atmosphere")
Atmosphere.Density = 0.3
Atmosphere.Offset = 0.5
Atmosphere.Color = Color3.fromRGB(200, 230, 200)
Atmosphere.Decay = Color3.fromRGB(100, 150, 100)
Atmosphere.Glare = 0.2
Atmosphere.Haze = 2
Atmosphere.Parent = Lighting

-- Add bloom
local Bloom = Instance.new("BloomEffect")
Bloom.Intensity = 0.5
Bloom.Size = 24
Bloom.Threshold = 0.8
Bloom.Parent = Lighting
```

### Sound Effects

Add ambient sounds:
1. Insert **Sound** in Workspace
2. SoundId: Forest ambiance
3. Looped: ✅ True
4. Volume: `0.3`
5. Playing: ✅ True

---

## 📦 Part 8: Organizing Your Workspace

### Recommended Structure

```
Workspace
├── Hub
│   ├── HubSpawn
│   ├── HubFloor
│   ├── Hub_Guide
│   ├── Hub_Merchant
│   ├── Hub_Elder
│   └── Decorations (Folder)
│
├── Levels (Folder)
│   ├── World1_Level1
│   ├── World1_Level2
│   ├── World1_Level3
│   ├── World1_Level4
│   └── World1_Level5
│
└── Collectibles (Folder)
    ├── Fragment1 (with attributes)
    ├── Fragment2
    └── Fragment3
```

---

## ✅ Final Checklist

### Hub World
- [ ] HubSpawn part created and positioned
- [ ] Hub floor created
- [ ] 3 NPC spawn markers created and named correctly
- [ ] Basic decorations added

### Level 1
- [ ] World1_Level1 folder created
- [ ] Spawn point inside folder
- [ ] 6-8 platforms built
- [ ] 3 checkpoints with scripts
- [ ] Finish line with script
- [ ] Tested: Can complete level

### Level 2
- [ ] World1_Level2 folder created
- [ ] Moving platforms (3-4)
- [ ] 4 checkpoints
- [ ] Fragment with attributes
- [ ] Finish line
- [ ] Tested: Can collect fragment

### Level 3
- [ ] World1_Level3 folder created
- [ ] Water kill parts
- [ ] Disappearing platforms
- [ ] 5 checkpoints
- [ ] Fragment
- [ ] Tested: Water kills player

### Level 4
- [ ] World1_Level4 folder created
- [ ] Spike traps
- [ ] Multiple paths
- [ ] 6 checkpoints
- [ ] Hidden fragment
- [ ] Tested: Spikes damage player

### Level 5
- [ ] World1_Level5 folder created
- [ ] All mechanics combined
- [ ] 7 checkpoints
- [ ] Epic finale
- [ ] Tested: Dramatic finish works

### Collectibles
- [ ] 3 fragments placed
- [ ] All have CollectibleType attribute
- [ ] All have CollectibleId attribute
- [ ] Tested: Fragments collect properly

---

## 🎓 Tips for Building

1. **Start Simple:** Build basic versions first, then polish later
2. **Test Frequently:** Play-test after each level
3. **Use Templates:** Copy and modify existing parts
4. **Group Objects:** Use folders and models to stay organized
5. **Save Often:** Use Ctrl+S frequently
6. **Backup:** Publish to Roblox regularly

---

## 🚀 You're Ready!

Once you've built these visual elements, your game is **100% complete and playable**!

All the complex logic is already done - you just made it look good! 🎨✨
