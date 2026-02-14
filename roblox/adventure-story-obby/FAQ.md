# Frequently Asked Questions (FAQ)

Common questions and answers about Adventure Story Obby.

---

## 📦 Setup & Installation

### Q: How do I get started with this project?

**A:** Follow these steps:
1. Read **QUICKSTART.md** for a 5-step setup guide
2. Start Rojo server: `rojo serve`
3. Connect from Roblox Studio
4. Build the hub and levels following **STUDIO_BUILDING_GUIDE.md**
5. Test the game!

### Q: Do I need to know Lua to use this?

**A:** Not really! All the code is complete. You just need to:
- Build levels in Studio (drag-and-drop parts)
- Set some attributes on collectibles (right-click → Add Attribute)
- Copy-paste the provided scripts

### Q: What's Rojo and why do I need it?

**A:** Rojo syncs code from your computer to Roblox Studio. Benefits:
- Use your favorite code editor
- Version control with Git
- Better code organization
- Faster development

Alternative: You can manually copy all scripts into Studio, but it's tedious.

### Q: Can I use this without Rojo?

**A:** Yes, but it's not recommended. You'd need to:
1. Manually create all folders in Studio
2. Copy-paste each .lua file as a Script/ModuleScript
3. Maintain the exact folder structure

---

## 🎮 Gameplay

### Q: How does the story progression work?

**A:**
1. Player spawns in hub
2. Talks to NPCs to get quests
3. Opens Story UI (M key) to select levels
4. Completes levels to unlock next ones
5. Collects fragments to progress story
6. Claims quest rewards for coins
7. Repeats until World 1 is complete

### Q: What happens if a player dies?

**A:**
- They respawn at their last checkpoint
- No coins or progress lost
- Death counter increases (for stats)

### Q: How do checkpoints work?

**A:**
- Touch a checkpoint part to save your position
- If you die, you respawn there
- Checkpoints persist until you complete the level or leave

### Q: Can players replay completed levels?

**A:** Yes! The Story UI shows a "REPLAY" button for completed levels.

### Q: How often does data save?

**A:**
- Automatically every 60 seconds (staggered)
- When player leaves
- When level completes
- When quest is claimed

---

## 🏗️ Building in Studio

### Q: Do I have to build all 5 levels?

**A:** No! Start with just Level 1. The game will work fine. Add more levels when you're ready.

### Q: What's the minimum I need to build?

**A:**
- Hub with spawn point and 3 NPC markers
- Level 1 with spawn, platforms, checkpoints, and finish
- That's it! Everything else will work even if you don't build it yet.

### Q: How do I make moving platforms?

**A:** Insert a Script inside the platform part and use the template from **STUDIO_BUILDING_GUIDE.md**. It's a simple loop that moves the platform back and forth.

### Q: How do I create collectibles?

**A:**
1. Insert a Part (any shape)
2. Right-click → Add Attribute
3. Add `CollectibleType` (String) = `"Fragment"`
4. Add `CollectibleId` (String) = `"Fragment_W1_L2"`
5. Done! The CollectibleService handles the rest.

### Q: Can I use models from the Toolbox?

**A:** Yes! You can use:
- Terrain
- Models for decorations
- Pre-made obstacles
- NPCs (place them where the spawn markers are)

Just make sure to keep the required parts (spawns, checkpoints, finish).

---

## 💻 Code & Scripting

### Q: Do I need to modify any code?

**A:** Usually no! But you might want to:
- Add your UserId to AdminCommands.lua for admin access
- Adjust coin rewards in StoryConfig.lua
- Customize NPC dialogues in NPCDialogues.lua

### Q: How do I add more dialogue to NPCs?

**A:** Edit `src/ReplicatedStorage/Shared/Data/NPCDialogues.lua`:
```lua
NPCDialogues.Guide.NewDialogue = {
    Text = "Your dialogue text here",
    Choices = {
        {Text = "Choice 1", NextId = "AnotherDialogue"},
        {Text = "Choice 2", NextId = nil}, -- nil = close
    }
}
```

### Q: How do I create new quests?

**A:** Edit `src/ReplicatedStorage/Shared/Data/QuestDefinitions.lua`:
```lua
QuestDefinitions.Story.MyNewQuest = {
    Id = "MyNewQuest",
    Type = "Story",
    Name = "Quest Name",
    Description = "Quest description",
    Objectives = {
        {Type = "Complete", Target = "World1_Level1", Count = 1},
    },
    Rewards = {
        Coins = 100,
    },
}
```

### Q: How do I add more worlds?

**A:**
1. Add world definition to `StoryChapters.lua`
2. Build the levels in Studio (name them `World2_Level1`, etc.)
3. No code changes needed!

### Q: Can I add more collectible types?

**A:** Yes! Edit `StoryConfig.lua`:
```lua
StoryConfig.Collectibles.Types.MyNewType = {
    Name = "My Collectible",
    Description = "Description",
    CoinReward = 25,
    ParticleColor = Color3.fromRGB(255, 0, 0),
}
```

---

## 🔧 Troubleshooting

### Q: "RemoteEvents folder not found" error

**A:** Make sure Main.server.lua ran. Check Output window for:
```
[RemoteEventsInit] Creating RemoteEvents folder...
```

If you don't see it, the server didn't start properly.

### Q: NPCs aren't spawning

**A:** Check:
1. Are the spawn markers named exactly `Hub_Guide`, `Hub_Merchant`, `Hub_Elder`?
2. Are they in Workspace (not ServerStorage)?
3. Look at Output window for NPC spawn messages

### Q: Players can't teleport to levels

**A:** Check:
1. Is the level folder named `World1_Level1` (exactly)?
2. Is there a part named `Spawn` inside the folder?
3. Is the Spawn part Anchored?

### Q: Data isn't saving

**A:** ProfileService requires:
1. Game published to Roblox
2. API services enabled in Game Settings
3. Not working? Check Output for ProfileService errors

In Studio, data is mock and won't persist between sessions.

### Q: Quest progress not updating

**A:** Make sure:
1. Objective type matches: `Type = "Complete"` in quest definition
2. `UpdateQuestProgress` uses same type: `UpdateQuestProgress(player, "Complete", ...)`
3. Quest is active (check quest tracker UI)

### Q: Collectibles not working

**A:** Verify:
1. Part has both attributes: `CollectibleType` and `CollectibleId`
2. Part is in Workspace (or a descendant of Workspace)
3. CollectibleService initialized (check Output)

---

## 🎯 Features & Customization

### Q: How do I change coin rewards?

**A:** Edit `StoryConfig.lua`:
```lua
StoryConfig.Progression.LevelRewards = {
    Coins = {
        [1] = 100,  -- Changed from 50
        [2] = 150,  -- Changed from 75
        -- ...
    }
}
```

### Q: How do I add VIP benefits?

**A:** VIP hooks are already built in! Edit `StoryConfig.lua`:
```lua
StoryConfig.Monetization.VIP = {
    CoinMultiplier = 2.0,  -- 2x coins
    SpeedBoost = 1.2,      -- 20% faster
    ExclusiveAreas = true,
}
```

Then check for VIP in your code:
```lua
-- Example: Check if player has VIP game pass
local hasVIP = player:GetRankInGroup(yourGroupId) >= 5
if hasVIP then
    -- Apply VIP multiplier
end
```

### Q: Can I add daily rewards?

**A:** The DailyReward data structure exists in DataService! You'd need to create a DailyRewardService (similar to QuestService) to handle the logic.

### Q: How do I add achievements?

**A:** AchievementService is already included from Tower Ascent! Define achievements and call:
```lua
AchievementService.UnlockAchievement(player, "AchievementId")
```

### Q: Can I add a shop?

**A:** Yes! Create a ShopService and ShopUI. Use the Merchant NPC's dialogue to trigger it:
```lua
OnComplete = function(player)
    return "OpenShop" -- ShopUI listens for this
end
```

---

## 🚀 Performance & Optimization

### Q: How many players can the game handle?

**A:** With the current architecture:
- **Tested:** Up to 50 players (in similar systems)
- **Optimized:** Staggered autosave, efficient data structures
- **Scalable:** Add more servers as needed

### Q: Will the game lag with many players?

**A:** Unlikely, because:
- Autosave is staggered (2-3 saves/second max)
- No heavy loops or computations
- World streaming reduces client load
- Anti-cheat rate limiting prevents spam

Enable PerformanceMonitor to track server health!

### Q: How do I monitor performance?

**A:** Set `ENABLED = true` in `PerformanceMonitor.lua`. It will log:
- Memory usage
- Player count
- Heartbeat (lag indicator)
- Service health

### Q: What if I get memory warnings?

**A:**
1. Check for memory leaks (uncleaned connections)
2. Reduce number of collectibles/decorations
3. Use Streaming to unload distant areas
4. Check PerformanceMonitor logs

---

## 🎨 Content Creation

### Q: How hard is it to add World 2?

**A:** Very easy!
1. Copy `World1` section in `StoryChapters.lua`
2. Rename to `World2` with new level definitions
3. Build 5 new levels in Studio
4. Done! No code changes needed.

### Q: Can I have more than 5 levels per world?

**A:** Yes! The system supports unlimited levels. Just:
1. Add more level definitions to `StoryChapters.lua`
2. Build them in Studio
3. Quests and progression will work automatically

### Q: How do I create branching stories?

**A:** Use dialogue choices to set flags:
```lua
OnComplete = function(player)
    local profile = DataService.GetProfile(player)
    profile.Data.Story.CustomFlags = profile.Data.Story.CustomFlags or {}
    profile.Data.Story.CustomFlags.ChoiceA = true
    return nil
end
```

Then check flags in other dialogues to show different options.

### Q: Can I add voice acting?

**A:** Yes! Add Sound instances to dialogue nodes:
```lua
-- In DialogueService or DialogueUI
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://YOUR_AUDIO_ID"
sound.Parent = workspace
sound:Play()
```

---

## 💰 Monetization

### Q: How do I monetize this game?

**A:** Several options:
1. **VIP Game Pass** - 2x coins, speed boost (hooks already built)
2. **Dev Products** - Coin packs, level skips
3. **Story Pass** - Battle Pass style system (planned feature)
4. **Cosmetics** - Trails, effects, titles

### Q: Is the coin economy balanced?

**A:** Current balance:
- Levels: 50-200 coins
- Quests: 50-300 coins
- Collectibles: 50 coins each

Adjust in `StoryConfig.lua` based on your monetization strategy.

### Q: How do I add a shop?

**A:** Create:
1. ShopService (handle purchases)
2. ShopUI (display items)
3. Product definitions (what's for sale)

Use CoinService to deduct coins and DataService to grant items.

---

## 📚 Learning & Support

### Q: Where can I learn more about Roblox development?

**A:**
- Official Roblox Creator Hub: https://create.roblox.com/docs
- Roblox DevForum: https://devforum.roblox.com/
- YouTube tutorials
- This project's code (well-commented!)

### Q: Can I contribute to this project?

**A:** This is a learning/portfolio project, but feel free to:
- Fork and modify for your own games
- Share improvements or fixes
- Use as reference for your projects

### Q: Is there a Discord/community?

**A:** This is an individual project, but you can:
- Post on Roblox DevForum for help
- Share your version on Roblox
- Credit the original architecture (Tower Ascent)

### Q: Can I use this for commercial games?

**A:** Yes! This is a learning project. Use it however you like. Just note:
- ProfileService is by loleris (MIT License)
- Promise is by evaera (MIT License)
- Consider giving credit to original architecture

---

## 🔮 Future Features

### Q: Will you add World 2-5?

**A:** Not planned by default, but the architecture supports it! You can easily add them yourself.

### Q: What about a Story Pass system?

**A:** Planned as a future feature. Would work like:
- Season-based progression
- Exclusive rewards
- Premium tier
- Similar to Tower Ascent's system

### Q: Can this support multiplayer co-op?

**A:** Yes! The architecture already handles multiple players. For co-op:
- Add party system (from Dimension Hopper concept)
- Shared checkpoints
- Co-op specific quests

### Q: Will you add mobile support?

**A:** The game already works on mobile! UI might need tweaking:
- Larger buttons
- Touch-friendly interface
- Simplified controls

---

## 🆘 Still Need Help?

1. **Check the docs:**
   - README.md - Overview
   - QUICKSTART.md - Setup
   - TESTING_GUIDE.md - Debugging
   - STUDIO_BUILDING_GUIDE.md - Building levels

2. **Check Output window** in Studio for error messages

3. **Use Admin Commands** (in-game chat):
   - `/help` - List all commands
   - `/give coins 1000` - Test economy
   - `/complete level 1 1` - Skip levels

4. **Check _G.AdventureStoryObby** in Command Bar for service access

5. **Read the code comments** - All files are well-documented

---

**Still stuck?** Remember: The entire codebase is open and commented. Read through the services to understand how they work! 📚✨
