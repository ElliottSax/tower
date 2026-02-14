# Adventure Story Obby - System Architecture

This document provides a visual overview of the game's architecture and how all systems interact.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        PLAYER CLIENT                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ DialogueUI   │  │ QuestUI      │  │  StoryUI     │     │
│  │              │  │              │  │              │     │
│  │ - Typewriter │  │ - Progress   │  │ - Level Map  │     │
│  │ - Choices    │  │ - Tracker    │  │ - Selection  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                   │                  │             │
│         └───────────────────┴──────────────────┘             │
│                             │                                │
│                    RemoteEvents                              │
└─────────────────────────────┼───────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────┐
│                        GAME SERVER                           │
│                             │                                │
│  ┌──────────────────────────▼────────────────────────┐      │
│  │          RemoteEventsInit (Security)              │      │
│  │  - Rate limiting  - Type validation               │      │
│  └──────────────────────────┬────────────────────────┘      │
│                             │                                │
│  ┌──────────────────────────▼────────────────────────┐      │
│  │              DataService (Core)                   │      │
│  │  - ProfileService  - Player data                  │      │
│  │  - Autosave       - Session locking              │      │
│  └──────────────────────────┬────────────────────────┘      │
│                             │                                │
│         ┌───────────────────┼───────────────────┐           │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │StoryService │    │WorldService │    │NPCService   │    │
│  │             │    │             │    │             │    │
│  │-Progression │    │-Teleports   │    │-Spawning    │    │
│  │-Fragments   │    │-Checkpoints │    │-Interaction │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│         │                   │                   │           │
│         └───────────────────┼───────────────────┘           │
│                             │                                │
│         ┌───────────────────┼───────────────────┐           │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │QuestService │    │DialogueServ │    │Collectible  │    │
│  │             │    │             │    │Service      │    │
│  │-Tracking    │    │-Trees       │    │             │    │
│  │-Daily Reset │    │-Choices     │    │-Anti-cheat  │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow Diagram

### Player Joins Game

```
Player Joins
    │
    ▼
DataService.OnPlayerAdded
    │
    ├──► Load Profile from ProfileService
    │    └──► Create default data if new player
    │
    ├──► Initialize Leaderstats
    │
    ├──► QuestService.OnPlayerJoin
    │    ├──► Load active quests
    │    ├──► Refresh daily quests if needed
    │    └──► Auto-start tutorial quest
    │
    └──► Spawn at HubSpawn
         │
         ▼
    NPCService spawns 3 NPCs
         │
         └──► Player can interact
```

### NPC Interaction Flow

```
Player presses E near NPC
    │
    ▼
ProximityPrompt triggered
    │
    ▼
NPCService.OnNPCInteract
    │
    ├──► DialogueService.StartDialogue
    │    ├──► Check dialogue history
    │    ├──► Load dialogue tree
    │    └──► Update relationship
    │
    └──► Fire NPCInteract remote to client
         │
         ▼
    DialogueUI receives event
         │
         ├──► Call StartDialogue remote
         │    └──► Receive dialogue data
         │
         ├──► Display dialogue box
         ├──► Show typewriter effect
         └──► Display choices
              │
              └──► Player clicks choice
                   │
                   ▼
              MakeChoice remote
                   │
                   ├──► Execute OnComplete callback
                   │    └──► May start quest
                   │
                   └──► Return next dialogue
                        │
                        ├──► If Ended: Close UI
                        └──► Else: Show next dialogue
```

### Level Completion Flow

```
Player touches finish line
    │
    ▼
CompleteLevelEvent fired
    │
    ▼
WorldService.CompleteCurrentLevel
    │
    ├──► Calculate completion time
    │
    ├──► StoryService.CompleteLevel
    │    ├──► Mark level complete
    │    ├──► Update current level
    │    ├──► Award coins
    │    ├──► Check if world complete
    │    └──► Unlock next level/world
    │
    ├──► QuestService.UpdateQuestProgress
    │    ├──► Check all active quests
    │    ├──► Update progress
    │    └──► Fire QuestUpdate to client
    │
    └──► Teleport back to hub
         │
         └──► QuestTrackerUI updates
```

### Quest Progress Flow

```
Player collects fragment
    │
    ▼
CollectibleService.CollectItem
    │
    ├──► Validate collection (anti-cheat)
    │
    ├──► StoryService.CollectFragment
    │    ├──► Check if already collected
    │    ├──► Mark as collected
    │    └──► Award coins
    │
    └──► QuestService.UpdateQuestProgress
         │
         ├──► Check all active quests
         │    └──► Match objective type & target
         │
         ├──► Update progress
         │    └──► Profile.Data.Quests.Progress[questId]
         │
         ├──► Check if quest complete
         │    └──► All objectives at max progress?
         │
         ├──► Fire QuestUpdate to client
         │    └──► QuestTrackerUI refreshes
         │
         └──► If complete: Show claim button
```

---

## 🔄 Service Dependencies

```
┌──────────────────────────────────────────────────────────┐
│                    Initialization Order                   │
└──────────────────────────────────────────────────────────┘

1. RemoteEventsInit
   └─► Creates all RemoteEvents/Functions

2. SecurityManager
   └─► Wraps all remotes with validation

3. DataService
   └─► ProfileService integration

4. CoinService ───────┐
5. StoryService ──────┤─► All depend on DataService
6. WorldService ──────┘

7. DialogueService ───┐
8. NPCService ────────┤─► NPCService uses DialogueService
                      │
9. QuestService ──────┤─► QuestService uses StoryService
10. CollectibleService┘   CollectibleService uses both

11. AchievementService
12. LeaderboardService
```

### Cross-Service Communication

```
StoryService
    │
    ├──► Uses: DataService
    └──► Used by: QuestService, CollectibleService, WorldService

DialogueService
    │
    ├──► Uses: DataService, StoryService, QuestService
    └──► Used by: NPCService

QuestService
    │
    ├──► Uses: DataService, StoryService
    └──► Used by: CollectibleService, WorldService

WorldService
    │
    ├──► Uses: DataService, StoryService
    └──► Used by: (Client via remotes)

CollectibleService
    │
    ├──► Uses: DataService, StoryService, QuestService
    └──► Used by: (Touch events)

NPCService
    │
    ├──► Uses: DialogueService
    └──► Used by: (ProximityPrompts)
```

---

## 🎮 Game Loop

```
┌─────────────────────────────────────────────────────────────┐
│                      CORE GAME LOOP                          │
└─────────────────────────────────────────────────────────────┘

1. PLAYER SPAWNS IN HUB
   ├─► NPCs are visible
   ├─► Quest tracker shows active quests
   └─► Can press M for story UI

2. INTERACT WITH NPCs
   ├─► Talk to Guide
   ├─► Receive quest
   └─► Learn about fragments

3. OPEN STORY UI (M key)
   ├─► View available levels
   ├─► Check progress (X/5 levels)
   └─► Click START on Level 1

4. TELEPORT TO LEVEL
   ├─► WorldService teleports player
   ├─► Checkpoint saved
   └─► Level timer starts

5. PLAY LEVEL
   ├─► Navigate parkour
   ├─► Collect coins (optional)
   ├─► Touch checkpoints (respawn points)
   └─► Avoid hazards

6. COLLECT FRAGMENTS (if present)
   ├─► Touch collectible
   ├─► CollectibleService validates
   ├─► Fragment added to story data
   └─► Quest progress updates

7. COMPLETE LEVEL
   ├─► Touch finish line
   ├─► Level marked complete
   ├─► Coins awarded
   └─► Quest objectives updated

8. RETURN TO HUB
   ├─► Auto-teleport after 2 seconds
   └─► Quest tracker shows progress

9. CLAIM QUEST REWARDS
   ├─► Click "Claim Reward" button
   ├─► Receive coins
   └─► Next quest auto-starts

10. REPEAT
    └─► Progress through all 5 levels
        └─► Complete World 1
            └─► Unlock World 2 (future)

┌─────────────────────────────────────────────────────────────┐
│                     PARALLEL SYSTEMS                         │
└─────────────────────────────────────────────────────────────┘

DAILY QUESTS
├─► Reset at midnight UTC
├─► 3 random quests assigned
└─► Complete for bonus rewards

RELATIONSHIPS
├─► Increase when talking to NPCs
├─► Unlock special dialogues
└─► Bonus rewards at milestones

DATA PERSISTENCE
├─► Autosave every 60 seconds
├─► Save on player leave
└─► ProfileService session locking
```

---

## 🔐 Security Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Security Layers                        │
└──────────────────────────────────────────────────────────┘

LAYER 1: RemoteEvent Validation
├─► SecureRemotes wraps all remotes
├─► Type checking on all parameters
├─► Rate limiting (max calls per second)
└─► Max data size validation

LAYER 2: Service-Level Validation
├─► Player existence checks
├─► Profile existence checks
├─► Ownership verification
└─► State validation

LAYER 3: Anti-Cheat Measures
├─► Collection rate limiting (5/second max)
├─► Minimum time between collections (0.1s)
├─► Already-collected checks
└─► Level unlock validation

LAYER 4: Data Protection
├─► ProfileService session locking
├─► No direct leaderstats manipulation
├─► All coin changes through DataService
└─► Secure remote handlers only
```

---

## 📦 Data Structure

```
Profile.Data
│
├─► Coins: number
│
├─► Story
│   ├─► CurrentWorld: number
│   ├─► CurrentLevel: number
│   ├─► CompletedLevels: {[levelKey] = true}
│   ├─► UnlockedWorlds: {1, 2, 3}
│   ├─► CollectedFragments: {[fragmentId] = true}
│   ├─► NPCRelationships: {[npcName] = number}
│   └─► DialogueHistory: {[npcName] = count}
│
├─► Quests
│   ├─► Active: [{Id, Type, StartedAt}]
│   ├─► Completed: {[questId] = timestamp}
│   ├─► Progress: {[questId] = {Objective1 = 2, ...}}
│   └─► LastDailyReset: number
│
├─► Stats
│   ├─► HighestStage: number
│   ├─► TowersCompleted: number
│   ├─► TotalPlaytime: number
│   ├─► Deaths: number
│   └─► ...
│
├─► Achievements: {[achievementId] = {Unlocked, UnlockedAt}}
│
├─► Settings
│   ├─► MusicVolume: number
│   ├─► SFXVolume: number
│   └─► ShowTutorial: boolean
│
└─► Timestamps
    ├─► Created: number
    ├─► LastLogin: number
    └─► LastSave: number
```

---

## 🎯 Critical Paths

### Path 1: First-Time Player Experience

```
1. Join game
2. Data loaded (new player)
3. Spawn at hub
4. Tutorial quest auto-starts
5. Talk to Guide NPC
6. Receive fragment quest
7. Open story UI (M)
8. Start Level 1
9. Complete tutorial
10. Return to hub
11. Claim quest reward
12. Next quest unlocks
```

### Path 2: Returning Player

```
1. Join game
2. Data loaded (existing profile)
3. Daily quests refresh if needed
4. Spawn at hub
5. Quest tracker shows progress
6. Continue from last level
7. Complete remaining levels
8. Collect fragments
9. Finish World 1
10. Unlock World 2
```

### Path 3: Daily Quest Completion

```
1. Check quest tracker
2. See 3 daily quests
3. Complete objectives
4. Claim rewards
5. Wait for next reset
6. New quests assigned
```

---

## 🚀 Performance Optimizations

### Autosave Staggering
```
Instead of:
All players save at once every 60s
└─► Potential lag spike

We use:
Staggered saves across 60s interval
├─► 2-3 saves per second
├─► Distributed evenly
└─► No lag spikes
```

### Lazy Loading
```
Services load dependencies as needed:
├─► Prevents circular dependencies
├─► Faster initialization
└─► Cleaner code
```

### Efficient Data Queries
```
Cache player profiles in memory:
├─► No repeated ProfileService calls
├─► Instant data access
└─► Only write on changes
```

---

## 📈 Scalability

### Adding New Worlds
1. Add world definition to `StoryChapters.lua`
2. Create levels in Studio
3. No code changes needed!

### Adding New NPCs
1. Add NPC config to `StoryConfig.lua`
2. Add dialogues to `NPCDialogues.lua`
3. Create model in Studio
4. NPC spawns automatically!

### Adding New Quests
1. Define quest in `QuestDefinitions.lua`
2. Quest system handles it automatically
3. Can be story or daily quest

### Adding New Collectibles
1. Place part in Studio
2. Set attributes (Type, Id)
3. CollectibleService handles the rest

---

This architecture provides a **solid foundation** for a scalable, maintainable, and secure game! 🎉
