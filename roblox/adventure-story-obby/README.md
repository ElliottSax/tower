# Adventure Story Obby

A narrative-driven parkour game built on proven architecture from Tower Ascent, featuring NPCs, quests, collectibles, and story progression.

## 🎮 Game Overview

**Adventure Story Obby** combines classic obby gameplay with an engaging storyline. Players navigate through challenging parkour levels while interacting with NPCs, completing quests, and uncovering the mysteries of the Mystic Forest.

### Core Features

- **Story-Driven Gameplay**: Full narrative experience with branching dialogues
- **World 1 - Mystic Forest**: 5 complete levels with progressive difficulty
- **NPC System**: 3 unique NPCs with personality and relationships
- **Quest System**: Story quests + daily challenges for engagement
- **Collectibles**: Ancient Fragments scattered across levels
- **Data Persistence**: ProfileService integration for reliable saves
- **Security**: Built-in anti-cheat and exploit protection
- **Monetization Ready**: VIP benefits and coin economy

## 📁 Project Structure

```
adventure-story-obby/
├── default.project.json          # Rojo project configuration
├── README.md                      # This file
│
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Config/
│   │   │   │   └── StoryConfig.lua          # Game configuration
│   │   │   └── Data/
│   │   │       ├── NPCDialogues.lua         # NPC conversation trees
│   │   │       ├── StoryChapters.lua        # Level definitions
│   │   │       └── QuestDefinitions.lua     # Quest data
│   │   └── Packages/                        # Third-party libraries
│   │       ├── ProfileService.lua
│   │       └── Promise.lua
│   │
│   ├── ServerScriptService/
│   │   ├── Main.server.lua                  # Server initialization
│   │   ├── Services/
│   │   │   ├── DataService.lua              # Player data persistence
│   │   │   ├── StoryService.lua             # Story progression
│   │   │   ├── DialogueService.lua          # NPC conversations
│   │   │   ├── NPCService.lua               # NPC management
│   │   │   ├── WorldService.lua             # Level loading/teleports
│   │   │   ├── QuestService.lua             # Quest tracking
│   │   │   ├── CollectibleService.lua       # Collectible management
│   │   │   ├── CoinService.lua              # Currency system
│   │   │   ├── AchievementService.lua       # Achievement tracking
│   │   │   └── LeaderboardService.lua       # Stats & rankings
│   │   ├── Security/
│   │   │   ├── SecurityManager.lua          # Anti-exploit protection
│   │   │   └── SecureRemotes.lua            # Remote validation
│   │   └── Utilities/
│   │       ├── ServiceLocator.lua           # Service management
│   │       └── RemoteEventsInit.lua         # Network initialization
│   │
│   ├── StarterGui/
│   │   ├── DialogueUI.lua                   # NPC dialogue interface
│   │   ├── QuestTrackerUI.lua               # Quest progress display
│   │   ├── StoryUI.lua                      # World/level selection
│   │   ├── CoinDisplayUI.lua                # Currency display
│   │   └── SettingsUI.lua                   # Game settings
│   │
│   ├── ServerStorage/
│   │   ├── Worlds/                          # Level models (built in Studio)
│   │   │   ├── Hub/
│   │   │   └── World1_MysticForest/
│   │   ├── NPCs/                            # NPC models
│   │   └── Collectibles/                    # Collectible models
│   │
│   └── StarterPlayer/
│       └── StarterCharacterScripts/
│           └── MovementController.lua       # Player movement
```

## 🏗️ Architecture

### Service Initialization Order

1. **Security & Networking** - RemoteEventsInit, SecurityManager
2. **Data Management** - DataService (ProfileService)
3. **Core Systems** - CoinService, StoryService, WorldService
4. **NPC & Dialogue** - DialogueService, NPCService
5. **Quest & Collectibles** - QuestService, CollectibleService
6. **Stats & Social** - AchievementService, LeaderboardService

### Data Model

```lua
PlayerData = {
    Coins = 0,

    Story = {
        CurrentWorld = 1,
        CurrentLevel = 1,
        CompletedLevels = {},
        UnlockedWorlds = {1},
        CollectedFragments = {},
        NPCRelationships = {},
        DialogueHistory = {},
    },

    Quests = {
        Active = {},
        Completed = {},
        Progress = {},
        LastDailyReset = 0,
    },

    Stats = {...},
    Achievements = {},
    Settings = {...},
}
```

## 🎭 NPCs & Dialogues

### NPCs in Hub

1. **Elder Moss (Guide)** - Main quest giver, story progression
2. **Trader Tom (Merchant)** - Shop, power-ups, cosmetics
3. **Ancient One (Elder)** - Lore keeper, story background

### Dialogue System

- Branching conversation trees
- Relationship system (builds over time)
- Choice-driven narratives
- Quest triggers from dialogues

## 🗺️ World 1: Mystic Forest

### Levels

| Level | Name | Difficulty | Checkpoints | Features |
|-------|------|------------|-------------|----------|
| 1 | Tutorial Path | Easy | 3 | Basic jumping intro |
| 2 | Forest Trail | Easy | 4 | Moving platforms, 1st fragment |
| 3 | River Crossing | Normal | 5 | Timing challenges, 2nd fragment |
| 4 | Ancient Ruins | Normal | 6 | Hazards, 3rd fragment |
| 5 | Guardian's Gate | Hard | 7 | Boss-style finale |

### Story Arc

1. Guide explains the forest curse
2. Player must collect 3 Ancient Fragments
3. Each level reveals more lore via collectibles
4. Final level confronts the curse's source
5. Completing World 1 unlocks World 2

## 🎯 Quest System

### Story Quests

- **TutorialComplete** - Complete Level 1
- **ForestTrailQuest** - Complete Level 2, collect 1st fragment
- **RiverCrossingQuest** - Complete Level 3, collect 2nd fragment
- **RuinsQuest** - Complete Level 4, collect 3rd fragment
- **GuardiansGateQuest** - Complete Level 5, break the curse

### Daily Quests (3 random per day)

- **Coin Collector** - Collect 50 coins
- **Daily Challenge** - Complete 3 levels
- **Social Butterfly** - Talk to all NPCs
- **Speed Runner** - Complete level under 2 minutes
- **Flawless Victory** - Complete level without dying
- **Treasure Hunter** - Collect all coins in a level

## 🪙 Economy & Monetization

### Coin Rewards

- Level completion: 50-200 coins (scales with difficulty)
- Quest rewards: 50-300 coins
- Collectibles: 50-100 coins
- World completion bonus: 500 coins

### VIP Benefits

- 2x coin multiplier
- 1.2x speed boost
- Access to exclusive areas

### Game Passes (Future)

- Early Access - New worlds 1 week early
- Cosmetic Pack - Exclusive trails and effects

## 🛠️ Building in Roblox Studio

### Required Setup

1. **Hub World**
   - Create spawn point: `HubSpawn`
   - Place NPC spawn markers: `Hub_Guide`, `Hub_Merchant`, `Hub_Elder`
   - Add portal to World 1

2. **World 1 Levels**
   - Create 5 level folders in Workspace or ServerStorage
   - Each level needs a `Spawn` part for player teleportation
   - Add checkpoint parts (named `Checkpoint1`, `Checkpoint2`, etc.)
   - Place finish line trigger

3. **Collectibles**
   - Create collectible parts in `Workspace/Collectibles`
   - Set attributes:
     - `CollectibleType` (String): "Fragment", "Coin", or "Bonus"
     - `CollectibleId` (String): e.g., "Fragment_W1_L2"

4. **NPCs**
   - Create NPC models in `ServerStorage/NPCs/`
   - Name them: `Guide`, `Merchant`, `Elder`
   - Each needs a HumanoidRootPart

### Level Building Guidelines

- **Tutorial Path (Level 1)**: Simple straight path, 3 easy checkpoints
- **Forest Trail (Level 2)**: Add 3-4 moving platforms, hide 1 fragment
- **River Crossing (Level 3)**: Water hazards, disappearing platforms, 1 fragment
- **Ancient Ruins (Level 4)**: Spikes, traps, complex paths, 1 fragment
- **Guardian's Gate (Level 5)**: Combine all mechanics, boss-style finale

## 🚀 Deployment

### Using Rojo (Recommended)

1. Install Rojo: https://rojo.space/
2. Open Roblox Studio
3. Install Rojo plugin in Studio
4. Navigate to project folder:
   ```bash
   cd /mnt/e/projects/roblox/adventure-story-obby
   ```
5. Start Rojo server:
   ```bash
   rojo serve
   ```
6. In Studio, click "Connect" in Rojo plugin
7. Build your world in Studio
8. Publish to Roblox

### Manual Setup (Alternative)

1. Copy all scripts manually into Roblox Studio
2. Ensure folder structure matches
3. Place scripts in correct services
4. Build world manually

## 🧪 Testing

### Test Checklist

1. **Data Persistence**
   - [ ] Join game, complete Level 1
   - [ ] Leave and rejoin
   - [ ] Verify Level 1 is marked complete
   - [ ] Verify coins saved

2. **Story Progression**
   - [ ] Talk to Guide NPC in hub
   - [ ] Receive quest to collect fragments
   - [ ] Complete Level 1
   - [ ] Verify quest progress updates

3. **Dialogue System**
   - [ ] Interact with all 3 NPCs
   - [ ] See dialogue boxes appear
   - [ ] Make choice selections
   - [ ] Complete dialogue flows

4. **Quest System**
   - [ ] Check quest tracker UI
   - [ ] Complete quest objective
   - [ ] Claim reward
   - [ ] Verify coins awarded

5. **World Transitions**
   - [ ] Teleport from hub to Level 1
   - [ ] Complete level
   - [ ] Teleport back to hub
   - [ ] Enter Level 2

## 📊 Performance

- **ProfileService**: Prevents data loss via session locking
- **Staggered Autosave**: Saves distributed to prevent lag spikes
- **World Streaming**: Levels load/unload dynamically
- **Anti-Cheat**: Rate limiting on collectibles and actions
- **Secure Remotes**: Validation on all client-server communication

## 🔮 Future Expansion

### Session 2: Additional Worlds
- World 2: Crystal Caves (5 levels)
- New NPCs and quest lines
- Theme variation

### Session 3: Advanced Monetization
- Story Pass (Battle Pass system)
- Developer products (boosts, skips)
- Cosmetic shop

### Session 4: Social Features
- Party system for co-op
- Leaderboards (fastest times)
- Social achievements

### Session 5: Advanced Features
- Cutscene system
- Branching story paths
- Multiple endings
- Character abilities/skill tree

## 📝 Code Examples

### Starting a Quest (Server)
```lua
QuestService.StartQuest(player, "CollectFragments")
```

### Completing a Level (Server)
```lua
StoryService.CompleteLevel(player, 1, 1) -- World 1, Level 1
```

### Collecting a Fragment (Server)
```lua
StoryService.CollectFragment(player, "Fragment_W1_L2")
```

### Opening Dialogue UI (Client)
```lua
DialogueUI.RequestDialogue("Guide")
```

## 🐛 Known Issues

- None currently - this is a fresh implementation

## 🤝 Credits

- **Architecture**: Based on Tower Ascent proven systems
- **ProfileService**: loleris - https://github.com/MadStudioRoblox/ProfileService
- **Promise**: evaera - https://github.com/evaera/roblox-lua-promise

## 📄 License

This is a learning/portfolio project. Feel free to use as reference.

---

**Ready to play?** Build the levels in Roblox Studio, start the server, and begin your adventure! 🎮✨
