# File Index

Quick reference for finding and understanding every file in the project.

---

## 📚 Documentation Files (Root)

| File | Purpose | When to Read |
|------|---------|--------------|
| **README.md** | Complete game overview | Start here |
| **QUICKSTART.md** | 5-step setup guide | First time setup |
| **IMPLEMENTATION_SUMMARY.md** | What's implemented | Check project status |
| **ARCHITECTURE.md** | System design diagrams | Understand how it works |
| **TESTING_GUIDE.md** | Testing & debugging | Before release / troubleshooting |
| **STUDIO_BUILDING_GUIDE.md** | Build levels in Studio | Building phase |
| **CHANGELOG.md** | Version history | Track changes |
| **FAQ.md** | Common questions | Have a question? |
| **FILE_INDEX.md** | This file | Finding files |

---

## ⚙️ Configuration Files

### `/src/ReplicatedStorage/Shared/Config/`

| File | Lines | Purpose | Edit When |
|------|-------|---------|-----------|
| **StoryConfig.lua** | ~200 | Game-wide settings | Balancing, tuning rewards |

**Key Sections:**
- `Worlds` - World definitions
- `NPCs` - NPC configurations
- `Quest` - Quest parameters
- `Collectibles` - Collectible settings
- `Dialogue` - Dialogue parameters
- `Progression` - Level rewards
- `Monetization` - VIP, game passes

---

## 📖 Data Files

### `/src/ReplicatedStorage/Shared/Data/`

| File | Lines | Purpose | Edit When |
|------|-------|---------|-----------|
| **NPCDialogues.lua** | ~200 | NPC conversation trees | Adding dialogue |
| **StoryChapters.lua** | ~150 | Level metadata | Adding levels/worlds |
| **QuestDefinitions.lua** | ~200 | Quest definitions | Adding quests |

**NPCDialogues.lua** - Contains:
- Guide (Elder Moss) - 10+ dialogue nodes
- Merchant (Trader Tom) - 5+ dialogue nodes
- Elder (Ancient One) - 6+ dialogue nodes

**StoryChapters.lua** - Contains:
- World 1 (Mystic Forest) - 5 level definitions
- Helper functions for level lookup

**QuestDefinitions.lua** - Contains:
- 6 story quests
- 6 daily quest types
- Helper functions for quest lookup

---

## 🛠️ Server Services

### `/src/ServerScriptService/Services/`

| File | Lines | Primary Purpose | Key Functions |
|------|-------|-----------------|---------------|
| **DataService.lua** | ~650 | Player data persistence | `GetProfile`, `AddCoins`, `GetData` |
| **StoryService.lua** | ~200 | Story progression | `CompleteLevel`, `CollectFragment` |
| **DialogueService.lua** | ~150 | NPC conversations | `StartDialogue`, `MakeChoice` |
| **NPCService.lua** | ~150 | NPC management | `SpawnNPC`, `OnNPCInteract` |
| **WorldService.lua** | ~250 | Level transitions | `TeleportToLevel`, `SetCheckpoint` |
| **QuestService.lua** | ~400 | Quest tracking | `StartQuest`, `UpdateQuestProgress` |
| **CollectibleService.lua** | ~250 | Collectible management | `CollectItem`, `ValidateCollection` |
| **CoinService.lua** | ~100 | Currency system | (From Tower Ascent) |
| **AchievementService.lua** | ~200 | Achievements | (From Tower Ascent) |
| **LeaderboardService.lua** | ~150 | Stats & rankings | (From Tower Ascent) |

### Service Relationships

```
DataService (Core)
    ↓
StoryService ← QuestService
    ↓           ↓
WorldService   CollectibleService
    ↓
DialogueService
    ↓
NPCService
```

---

## 🔐 Security Files

### `/src/ServerScriptService/Security/`

| File | Lines | Purpose | Touch? |
|------|-------|---------|--------|
| **SecurityManager.lua** | ~200 | Anti-exploit protection | ❌ No |
| **SecureRemotes.lua** | ~300 | Remote validation | ❌ No |

**SecurityManager.lua** - Handles:
- Player validation
- Exploit detection
- Ban management

**SecureRemotes.lua** - Provides:
- Type checking
- Rate limiting
- Max data size validation

---

## 🔧 Utility Files

### `/src/ServerScriptService/Utilities/`

| File | Lines | Purpose | Edit When |
|------|-------|---------|-----------|
| **ServiceLocator.lua** | ~100 | Service management | ❌ Never |
| **RemoteEventsInit.lua** | ~300 | Network setup | Adding remotes |
| **AdminCommands.lua** | ~400 | Developer commands | Adding commands |
| **PerformanceMonitor.lua** | ~250 | Performance tracking | Tuning thresholds |

**RemoteEventsInit.lua** - Creates 20+ remotes:
- Story remotes (4)
- Dialogue remotes (3)
- NPC remotes (1)
- World remotes (4)
- Quest remotes (4)
- Plus Tower Ascent remotes

**AdminCommands.lua** - Chat commands:
- `/give` - Give items/coins
- `/complete` - Complete levels
- `/start` - Start quests
- `/unlock` - Unlock content
- `/reset` - Reset data
- `/tp` - Teleport
- `/skip` - Skip level
- `/help` - List commands

---

## 🎨 UI Files

### `/src/StarterGui/`

| File | Lines | Purpose | Edit When |
|------|-------|---------|-----------|
| **DialogueUI.lua** | ~350 | NPC dialogue interface | Customizing dialogue UI |
| **QuestTrackerUI.lua** | ~300 | Quest progress display | Customizing quest UI |
| **StoryUI.lua** | ~350 | Level selection | Customizing map UI |
| **CoinDisplayUI.lua** | ~100 | Currency display | (From Tower Ascent) |
| **SettingsUI.lua** | ~200 | Game settings | (From Tower Ascent) |

**DialogueUI.lua** - Features:
- Typewriter effect
- Choice buttons
- Skip functionality
- NPC name display

**QuestTrackerUI.lua** - Features:
- Active quest list
- Progress bars
- Collapsible interface
- Claim reward buttons

**StoryUI.lua** - Features:
- World map
- Level unlock status
- Progress tracking
- Keyboard shortcut (M key)

---

## 🎮 Main Entry Point

### `/src/ServerScriptService/`

| File | Lines | Purpose | Edit? |
|------|-------|---------|-------|
| **Main.server.lua** | ~150 | Server initialization | ⚠️ Rarely |

**Initialization Order:**
1. RemoteEventsInit (Security & Networking)
2. SecurityManager
3. DataService (Data Management)
4. CoinService, StoryService, WorldService
5. DialogueService, NPCService
6. QuestService, CollectibleService
7. AchievementService, LeaderboardService
8. AdminCommands, PerformanceMonitor (Optional)

---

## 📦 Dependencies

### `/src/ReplicatedStorage/Packages/`

| File | Source | Purpose |
|------|--------|---------|
| **ProfileService.lua** | loleris | Data persistence |
| **Promise.lua** | evaera | Async operations |
| **TestEZ.lua** | Roblox | Unit testing |

---

## 🗂️ Folder Structure Reference

```
adventure-story-obby/
│
├── 📄 Documentation (10 files)
│   ├── README.md
│   ├── QUICKSTART.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── ARCHITECTURE.md
│   ├── TESTING_GUIDE.md
│   ├── STUDIO_BUILDING_GUIDE.md
│   ├── CHANGELOG.md
│   ├── FAQ.md
│   ├── FILE_INDEX.md
│   └── default.project.json
│
└── src/
    ├── ReplicatedStorage/
    │   ├── Shared/
    │   │   ├── Config/
    │   │   │   └── 📄 StoryConfig.lua (1 file)
    │   │   └── Data/
    │   │       ├── 📄 NPCDialogues.lua
    │   │       ├── 📄 StoryChapters.lua
    │   │       └── 📄 QuestDefinitions.lua (3 files)
    │   └── Packages/
    │       └── 📦 ProfileService, Promise, TestEZ (3 files)
    │
    ├── ServerScriptService/
    │   ├── 📄 Main.server.lua (1 file)
    │   ├── Services/
    │   │   ├── 📄 DataService.lua
    │   │   ├── 📄 StoryService.lua
    │   │   ├── 📄 DialogueService.lua
    │   │   ├── 📄 NPCService.lua
    │   │   ├── 📄 WorldService.lua
    │   │   ├── 📄 QuestService.lua
    │   │   ├── 📄 CollectibleService.lua
    │   │   ├── 📄 CoinService.lua
    │   │   ├── 📄 AchievementService.lua
    │   │   └── 📄 LeaderboardService.lua (10 files)
    │   ├── Security/
    │   │   ├── 📄 SecurityManager.lua
    │   │   └── 📄 SecureRemotes.lua (2 files)
    │   └── Utilities/
    │       ├── 📄 ServiceLocator.lua
    │       ├── 📄 RemoteEventsInit.lua
    │       ├── 📄 AdminCommands.lua
    │       └── 📄 PerformanceMonitor.lua (4 files)
    │
    ├── StarterGui/
    │   ├── 📄 DialogueUI.lua
    │   ├── 📄 QuestTrackerUI.lua
    │   ├── 📄 StoryUI.lua
    │   ├── 📄 CoinDisplayUI.lua
    │   └── 📄 SettingsUI.lua (5 files)
    │
    ├── ServerStorage/
    │   ├── Worlds/
    │   │   ├── Hub/ (build in Studio)
    │   │   └── World1_MysticForest/ (build in Studio)
    │   ├── NPCs/ (build in Studio)
    │   └── Collectibles/ (build in Studio)
    │
    └── StarterPlayer/
        └── StarterCharacterScripts/
            └── (movement scripts if needed)
```

---

## 📊 File Statistics

**Total Custom Files:** 24 Lua files + 10 documentation files
**Total Lines of Code:** ~5,000 lines (excluding packages)

**Breakdown by Category:**
- Configuration/Data: 4 files (~550 lines)
- Services: 10 files (~2,400 lines)
- Security: 2 files (~500 lines)
- Utilities: 4 files (~1,050 lines)
- UI: 5 files (~1,500 lines)
- Main: 1 file (~150 lines)

---

## 🔍 Quick File Finder

### "I want to..."

**...change coin rewards**
→ `StoryConfig.lua` (Progression.LevelRewards)

**...add new dialogue**
→ `NPCDialogues.lua` (Add new node to NPC section)

**...create new quest**
→ `QuestDefinitions.lua` (Add to Story or Daily section)

**...add new level**
→ `StoryChapters.lua` (Add level definition)

**...modify UI colors**
→ `DialogueUI.lua`, `QuestTrackerUI.lua`, or `StoryUI.lua`

**...add admin command**
→ `AdminCommands.lua` (ExecuteCommand function)

**...change data structure**
→ `DataService.lua` (DEFAULT_DATA table)

**...customize NPC behavior**
→ `NPCService.lua` (SpawnNPC, SetupNPCInteraction)

**...add remote event**
→ `RemoteEventsInit.lua` (Initialize function)

**...modify quest logic**
→ `QuestService.lua` (UpdateQuestProgress)

**...change level completion**
→ `StoryService.lua` (CompleteLevel)

**...customize checkpoints**
→ `WorldService.lua` (SetCheckpoint, RespawnAtCheckpoint)

**...modify collectible behavior**
→ `CollectibleService.lua` (CollectItem)

---

## 🎯 Files You'll Edit Most

**For Content Creation:**
1. `StoryConfig.lua` - Balancing and tuning
2. `NPCDialogues.lua` - Adding dialogue
3. `QuestDefinitions.lua` - Creating quests
4. `StoryChapters.lua` - Defining levels

**For Customization:**
1. `DialogueUI.lua` - Dialogue appearance
2. `QuestTrackerUI.lua` - Quest tracker appearance
3. `StoryUI.lua` - Map appearance
4. `AdminCommands.lua` - Adding debug commands

**Files You'll Rarely Touch:**
1. `DataService.lua` - Core persistence (stable)
2. `SecurityManager.lua` - Anti-cheat (works as-is)
3. `SecureRemotes.lua` - Remote validation (works as-is)
4. `ServiceLocator.lua` - Service management (stable)

---

## 📖 Reading Order for New Developers

**Day 1: Understanding**
1. README.md
2. ARCHITECTURE.md
3. DataService.lua (understand data structure)
4. Main.server.lua (see initialization)

**Day 2: Content**
5. StoryConfig.lua
6. StoryChapters.lua
7. NPCDialogues.lua
8. QuestDefinitions.lua

**Day 3: Systems**
9. StoryService.lua
10. QuestService.lua
11. DialogueService.lua
12. WorldService.lua

**Day 4: UI**
13. DialogueUI.lua
14. QuestTrackerUI.lua
15. StoryUI.lua

**Day 5: Advanced**
16. CollectibleService.lua
17. NPCService.lua
18. SecurityManager.lua
19. AdminCommands.lua

---

## 🚀 Quick Actions

**Want to test something?**
→ Use AdminCommands (`/help` in chat)

**Game not working?**
→ Check TESTING_GUIDE.md

**Need to build levels?**
→ Follow STUDIO_BUILDING_GUIDE.md

**Have a question?**
→ Check FAQ.md

**Want to understand the code?**
→ Read ARCHITECTURE.md

**Ready to play?**
→ Follow QUICKSTART.md

---

This index helps you navigate the 24 custom files + documentation. Every file is purpose-built and well-commented! 📚✨
