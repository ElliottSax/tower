# Adventure Story Obby - Testing Guide

Comprehensive testing checklist and debugging guide.

---

## 🧪 Pre-Launch Testing Checklist

### Phase 1: Basic Systems (30 minutes)

#### Server Initialization
- [ ] Server starts without errors
- [ ] All services initialize in correct order
- [ ] RemoteEvents folder created
- [ ] No warnings in Output window
- [ ] `_G.AdventureStoryObby` table populated

**Expected Output:**
```
=============================================================
   ADVENTURE STORY OBBY - SERVER INITIALIZATION
=============================================================
[PHASE 1] Initializing Security & Networking...
[RemoteEventsInit] Creating RemoteEvents folder...
[RemoteEventsInit] Setting up secure remotes...
[RemoteEventsInit] ✅ All remotes initialized successfully
[SecurityManager] Initializing...
[SecurityManager] Initialized
[PHASE 1] ✅ Security & Networking initialized
...
=============================================================
   ✅ ADVENTURE STORY OBBY - SERVER READY
=============================================================
```

#### Data Service
- [ ] Player joins successfully
- [ ] Profile loads within 5 seconds
- [ ] Default data structure created
- [ ] Leaderstats appear
- [ ] Coins start at 0

**Test Commands (in Command Bar):**
```lua
local player = game.Players:GetChildren()[1]
local DataService = _G.AdventureStoryObby.DataService
local profile = DataService.GetProfile(player)
print(profile.Data.Coins) -- Should be 0
print(profile.Data.Story.CurrentWorld) -- Should be 1
```

---

### Phase 2: NPC Systems (15 minutes)

#### NPC Spawning
- [ ] 3 NPCs spawn in hub after 2-3 seconds
- [ ] NPCs are visible (even if basic models)
- [ ] ProximityPrompts appear when near NPCs
- [ ] Prompt text shows "Talk to [NPC Name]"

**Visual Check:**
- Look for 3 parts/models in Workspace
- Walk near each one to see prompt

#### Dialogue System
- [ ] Press E near Guide NPC
- [ ] Dialogue box appears at bottom of screen
- [ ] NPC name displays correctly
- [ ] Text types with typewriter effect
- [ ] Can skip typewriter with "Skip" button
- [ ] Choice buttons appear after text
- [ ] Clicking choice advances dialogue
- [ ] Dialogue closes properly

**Test Dialogue Flow:**
1. Talk to Guide → Choose "What's happening?"
2. Should show explanation dialogue
3. Choose "How can I help?"
4. Should offer quest
5. Choose "I'll find them!"
6. Quest should start (check quest tracker)

**Verify in Code:**
```lua
local DialogueService = _G.AdventureStoryObby.DialogueService
local player = game.Players:GetChildren()[1]
local hasActive = DialogueService.HasActiveDialogue(player)
print("Has active dialogue:", hasActive)
```

---

### Phase 3: Quest System (20 minutes)

#### Quest Auto-Start
- [ ] Tutorial quest starts automatically on join
- [ ] Quest appears in tracker (top-right)
- [ ] Objective shows "Complete World1_Level1: 0/1"
- [ ] Quest type shows "Story"

#### Quest Tracking
- [ ] Quest tracker is visible
- [ ] Can collapse/expand with toggle button
- [ ] Progress bars display correctly
- [ ] Colors change when objectives complete

#### Quest Completion
- [ ] Complete Level 1
- [ ] Quest objective updates to 1/1
- [ ] Progress bar turns green
- [ ] "CLAIM REWARD" button appears
- [ ] Click button awards coins
- [ ] Quest removed from active list
- [ ] Next quest auto-starts (ForestTrailQuest)

**Manual Quest Test:**
```lua
local QuestService = _G.AdventureStoryObby.QuestService
local player = game.Players:GetChildren()[1]

-- Get active quests
local quests = QuestService.GetActiveQuests(player)
for _, quest in ipairs(quests) do
    print("Quest:", quest.Name, "Complete:", quest.IsComplete)
end

-- Manually complete objective
QuestService.UpdateQuestProgress(player, "Complete", "World1_Level1", 1)

-- Check if complete
local isComplete = QuestService.IsQuestComplete(player, "TutorialComplete")
print("Tutorial complete:", isComplete)
```

---

### Phase 4: World & Level System (30 minutes)

#### Story UI
- [ ] Press M key to open Story UI
- [ ] UI appears centered on screen
- [ ] World 1 info displays on left
- [ ] 5 levels shown on right
- [ ] Level 1 shows "AVAILABLE"
- [ ] Levels 2-5 show "🔒 LOCKED"
- [ ] Close button works (X)
- [ ] M key toggles UI

#### Teleportation
- [ ] Click "START" on Level 1
- [ ] Player teleports to level spawn
- [ ] UI closes
- [ ] Checkpoint saved message in output

**Verify Teleport:**
```lua
local WorldService = _G.AdventureStoryObby.WorldService
local player = game.Players:GetChildren()[1]

-- Check if in level
local isInLevel = WorldService.IsInLevel(player)
print("Player in level:", isInLevel)

-- Get current level
local levelInfo = WorldService.GetPlayerLevel(player)
if levelInfo then
    print("World:", levelInfo.WorldId, "Level:", levelInfo.LevelId)
end
```

#### Checkpoint System
- [ ] Touch checkpoint part
- [ ] Checkpoint number displays in output
- [ ] Die/reset character
- [ ] Respawn at last checkpoint (not spawn)

**Checkpoint Script (add to checkpoint part):**
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local setCheckpointRemote = remoteEvents:WaitForChild("SetCheckpoint")

local CHECKPOINT_ID = 2 -- Change per checkpoint

script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            setCheckpointRemote:FireServer(CHECKPOINT_ID, script.Parent.CFrame)
            print("Checkpoint", CHECKPOINT_ID, "saved for", player.Name)
        end
    end
end)
```

#### Level Completion
- [ ] Touch finish line
- [ ] "Level complete" message
- [ ] Coins awarded (check coin display)
- [ ] Quest progress updates
- [ ] Wait 2 seconds
- [ ] Auto-teleport to hub
- [ ] Level marked complete in Story UI
- [ ] Next level unlocks

---

### Phase 5: Collectible System (20 minutes)

#### Collectible Setup
- [ ] Collectible part placed in world
- [ ] Attributes set correctly:
  - `CollectibleType` = "Fragment"
  - `CollectibleId` = "Fragment_W1_L2"
- [ ] Particle effects visible
- [ ] Part rotates/spins

#### Collection
- [ ] Walk into collectible
- [ ] Collectible disappears
- [ ] Sound plays
- [ ] Coins awarded (+50 for fragment)
- [ ] Quest progress updates
- [ ] Fragment marked in story data

**Verify Collection:**
```lua
local StoryService = _G.AdventureStoryObby.StoryService
local player = game.Players:GetChildren()[1]

-- Check fragments
local storyData = StoryService.GetStoryData(player)
for fragmentId, collected in pairs(storyData.CollectedFragments) do
    print("Fragment:", fragmentId, "Collected:", collected)
end

-- Manually give fragment
StoryService.CollectFragment(player, "Fragment_W1_L2")
```

#### Anti-Cheat
- [ ] Spam-collect multiple items rapidly
- [ ] Rate limiting should kick in
- [ ] Warning message in output
- [ ] Collection denied

---

### Phase 6: Data Persistence (15 minutes)

#### Save on Leave
- [ ] Play for 2 minutes
- [ ] Complete Level 1
- [ ] Earn some coins
- [ ] Leave game
- [ ] Check output for "Released profile for [Name]"

#### Load on Join
- [ ] Rejoin game
- [ ] Profile loads within 5 seconds
- [ ] Coins restored
- [ ] Level 1 still marked complete
- [ ] Unlocked levels preserved
- [ ] Quest progress restored

**Force Save Test:**
```lua
local DataService = _G.AdventureStoryObby.DataService
local player = game.Players:GetChildren()[1]
local profile = DataService.GetProfile(player)

-- Modify data
DataService.AddCoins(player, 100)

-- Check timestamp
print("Last save:", profile.Data.Timestamps.LastSave)

-- Wait 60 seconds for autosave
wait(60)
print("After autosave:", profile.Data.Timestamps.LastSave)
```

---

### Phase 7: UI Systems (15 minutes)

#### Coin Display
- [ ] Coin display visible (top-right or UI)
- [ ] Shows current coin count
- [ ] Updates when coins change
- [ ] Animates on change

#### Quest Tracker
- [ ] Always visible (unless collapsed)
- [ ] Shows up to 5 active quests
- [ ] Scrolls if more than fit
- [ ] Progress bars accurate
- [ ] Colors correct (yellow for active, green for complete)

#### Dialogue UI
- [ ] Appears when talking to NPC
- [ ] Blocks input while active
- [ ] Typewriter effect smooth
- [ ] Choices clickable
- [ ] Can close mid-conversation
- [ ] Doesn't break if NPC far away

#### Story UI
- [ ] Opens/closes with M key
- [ ] Level info accurate
- [ ] Lock icons correct
- [ ] Progress count accurate (X/5)
- [ ] Can click levels to start
- [ ] Locked levels unclickable

---

## 🐛 Debugging Guide

### Common Issues & Solutions

#### "RemoteEvents folder not found"
**Cause:** RemoteEventsInit didn't run
**Solution:**
```lua
-- In Command Bar
local RemoteEventsInit = require(game.ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Initialize()
```

#### "Profile failed to load"
**Cause:** ProfileService timeout or mock data store issue
**Solution:**
- In Studio: Publish game to Roblox first
- Or: Wait 30 seconds and retry
- Check Output for specific error

#### "NPCs not spawning"
**Cause:** Spawn markers missing
**Solution:**
- Create parts named: `Hub_Guide`, `Hub_Merchant`, `Hub_Elder`
- Make sure they're in Workspace (not ServerStorage)

#### "Can't teleport to levels"
**Cause:** Level spawn points missing
**Solution:**
- Create folder: `World1_Level1` in Workspace
- Add Part named `Spawn` inside folder
- Make sure Part is anchored

#### "Dialogue not opening"
**Cause:** RemoteEvents not connected
**Solution:**
```lua
-- Check if remotes exist
local remoteEvents = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
print("RemoteEvents exists:", remoteEvents ~= nil)

if remoteEvents then
    for _, remote in ipairs(remoteEvents:GetChildren()) do
        print("Remote:", remote.Name)
    end
end
```

#### "Quests not updating"
**Cause:** Objective type/target mismatch
**Solution:**
- Check QuestDefinitions.lua objective type
- Ensure UpdateQuestProgress uses same type
- Example: `Type = "Complete"` must match `"Complete"` in code

#### "Collectibles not working"
**Cause:** Attributes not set
**Solution:**
```lua
-- Set attributes on collectible part
local collectible = workspace.Collectible -- Replace with your part
collectible:SetAttribute("CollectibleType", "Fragment")
collectible:SetAttribute("CollectibleId", "Fragment_W1_L2")
```

---

## 🔍 Debug Commands

### Useful Command Bar Scripts

#### Give Coins
```lua
local player = game.Players:GetChildren()[1]
local DataService = _G.AdventureStoryObby.DataService
DataService.AddCoins(player, 1000)
print("Gave 1000 coins to", player.Name)
```

#### Complete Level
```lua
local player = game.Players:GetChildren()[1]
local StoryService = _G.AdventureStoryObby.StoryService
StoryService.CompleteLevel(player, 1, 1) -- World 1, Level 1
print("Level completed")
```

#### Start Quest
```lua
local player = game.Players:GetChildren()[1]
local QuestService = _G.AdventureStoryObby.QuestService
QuestService.StartQuest(player, "CollectFragments")
print("Quest started")
```

#### Give Fragment
```lua
local player = game.Players:GetChildren()[1]
local StoryService = _G.AdventureStoryObby.StoryService
StoryService.CollectFragment(player, "Fragment_W1_L2")
print("Fragment collected")
```

#### Unlock All Levels
```lua
local player = game.Players:GetChildren()[1]
local DataService = _G.AdventureStoryObby.DataService
local profile = DataService.GetProfile(player)

for level = 1, 5 do
    local levelKey = "World1_Level" .. level
    profile.Data.Story.CompletedLevels[levelKey] = true
end
print("All levels unlocked")
```

#### Reset Player Data
```lua
local player = game.Players:GetChildren()[1]
local DataService = _G.AdventureStoryObby.DataService
local profile = DataService.GetProfile(player)

-- Reset story progress
profile.Data.Story.CompletedLevels = {}
profile.Data.Story.CollectedFragments = {}
profile.Data.Story.CurrentLevel = 1
profile.Data.Quests.Active = {}
profile.Data.Quests.Completed = {}
print("Player data reset")
```

#### View All Player Data
```lua
local player = game.Players:GetChildren()[1]
local DataService = _G.AdventureStoryObby.DataService
local profile = DataService.GetProfile(player)

print("=== PLAYER DATA ===")
print("Coins:", profile.Data.Coins)
print("Current World:", profile.Data.Story.CurrentWorld)
print("Current Level:", profile.Data.Story.CurrentLevel)
print("Completed Levels:", #profile.Data.Story.CompletedLevels)
print("Active Quests:", #profile.Data.Quests.Active)
```

---

## 📊 Performance Testing

### Monitor Server Performance

```lua
-- Add to ServerScriptService
local RunService = game:GetService("RunService")
local lastPrint = tick()

RunService.Heartbeat:Connect(function()
    if tick() - lastPrint > 5 then -- Every 5 seconds
        local players = game.Players:GetPlayers()
        print(string.format(
            "[Performance] Players: %d | Memory: %.2f MB | FPS: %d",
            #players,
            game:GetService("Stats"):GetTotalMemoryUsageMb(),
            math.floor(1 / RunService.Heartbeat:Wait())
        ))
        lastPrint = tick()
    end
end)
```

### Check for Memory Leaks

```lua
-- Track active objects
local function countObjects()
    local counts = {}
    for _, obj in ipairs(game:GetDescendants()) do
        local className = obj.ClassName
        counts[className] = (counts[className] or 0) + 1
    end

    -- Print top 10
    local sorted = {}
    for class, count in pairs(counts) do
        table.insert(sorted, {class, count})
    end
    table.sort(sorted, function(a, b) return a[2] > b[2] end)

    print("=== TOP 10 OBJECTS ===")
    for i = 1, 10 do
        if sorted[i] then
            print(i, sorted[i][1], sorted[i][2])
        end
    end
end

countObjects()
```

---

## ✅ Pre-Release Checklist

Before publishing to Roblox:

### Code Quality
- [ ] No errors in Output window
- [ ] All services initialize successfully
- [ ] No warnings about missing dependencies
- [ ] All remote events exist
- [ ] All UI elements display correctly

### Gameplay
- [ ] Can complete all 5 levels
- [ ] All 3 NPCs functional
- [ ] All quests completable
- [ ] All collectibles work
- [ ] Coins awarded correctly
- [ ] Data saves and loads properly

### User Experience
- [ ] Tutorial is clear
- [ ] UI is readable
- [ ] No confusing error messages
- [ ] Teleports are smooth
- [ ] No sudden crashes
- [ ] Performance is good (30+ FPS)

### Security
- [ ] Rate limiting works
- [ ] Can't spam collect items
- [ ] Can't access locked levels
- [ ] Can't duplicate coins
- [ ] RemoteEvents are secure

### Polish
- [ ] Hub looks presentable
- [ ] Levels are fun to play
- [ ] NPCs have proper models
- [ ] Collectibles are visible
- [ ] Sound effects work (if added)
- [ ] Loading screens (if added)

---

## 🚀 Load Testing

Test with multiple players:

```lua
-- Simulate load test
for i = 1, 10 do
    local DataService = _G.AdventureStoryObby.DataService
    -- Simulate 10 players joining rapidly
end
```

Monitor:
- [ ] All players load successfully
- [ ] No data corruption
- [ ] Server doesn't lag
- [ ] Autosave handles load
- [ ] No memory leaks

---

## 📝 Testing Log Template

```
Date: _______________
Tester: _______________
Version: _______________

BASIC SYSTEMS:
- Server Init: PASS / FAIL
- Data Service: PASS / FAIL
- NPC System: PASS / FAIL

GAMEPLAY:
- Level 1: PASS / FAIL
- Level 2: PASS / FAIL
- Level 3: PASS / FAIL
- Level 4: PASS / FAIL
- Level 5: PASS / FAIL

FEATURES:
- Quests: PASS / FAIL
- Dialogues: PASS / FAIL
- Collectibles: PASS / FAIL
- Data Persistence: PASS / FAIL

ISSUES FOUND:
1. ________________________________
2. ________________________________
3. ________________________________

OVERALL: READY / NOT READY
```

---

This testing guide ensures your game is **production-ready**! 🎮✨
