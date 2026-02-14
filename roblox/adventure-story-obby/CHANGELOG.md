# Changelog

All notable changes to Adventure Story Obby will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned Features
- World 2: Crystal Caves (5 levels)
- Story Pass / Battle Pass system
- Cosmetic shop
- Party system for co-op play
- Speed run leaderboards
- Cutscene system
- Branching story paths
- Character abilities / skill tree

---

## [1.0.0] - 2025-02-05

### Added

#### Core Systems
- **Data Service** with ProfileService integration
  - Session locking to prevent data loss
  - Staggered autosave (every 60 seconds)
  - Safe shutdown handling
  - Extended data model for story progression

#### Story Systems
- **StoryService** for level progression tracking
  - 5 levels in World 1 (Mystic Forest)
  - Level completion validation
  - World unlocking system
  - Fragment collection tracking
  - NPC relationship management

- **DialogueService** for NPC conversations
  - Branching dialogue trees
  - Choice-driven narratives
  - Dialogue history tracking
  - Relationship gain system
  - Quest triggers from conversations

- **NPCService** for NPC management
  - 3 NPCs in hub (Guide, Merchant, Elder)
  - ProximityPrompt interaction system
  - Automatic NPC spawning
  - Basic NPC model fallback

- **WorldService** for level management
  - Teleportation system (hub ↔ levels)
  - Checkpoint system with respawn
  - Death tracking
  - Level completion timing
  - Auto-return to hub after completion

- **QuestService** for quest tracking
  - 6 story quests with progression chains
  - 6 daily quest types (3 random per day)
  - Per-objective progress tracking
  - Reward claiming system
  - Daily reset at midnight UTC

- **CollectibleService** for collectibles
  - Fragment collection (3 in World 1)
  - Coin collection
  - Bonus items
  - Anti-cheat rate limiting (5/second max)
  - Visual effects (particles, spinning)

#### Security Systems
- **SecurityManager** for anti-exploit protection
- **SecureRemotes** wrapper for all remote events
  - Type validation
  - Rate limiting
  - Max data size checks
  - Per-player tracking

#### UI Systems
- **DialogueUI** with typewriter effect
  - Choice buttons (up to 4)
  - Skip functionality
  - NPC name display
  - Smooth animations

- **QuestTrackerUI** for progress tracking
  - Active quest display (top-right)
  - Progress bars per objective
  - Collapsible interface
  - Claim reward buttons
  - Real-time updates

- **StoryUI** for level selection
  - World map interface
  - Level unlock status
  - Progress visualization (X/5 levels)
  - Keyboard shortcut (M key)
  - Start/Replay buttons

- **CoinDisplayUI** (from Tower Ascent)
  - Real-time coin count
  - Update animations

- **SettingsUI** (from Tower Ascent)
  - Volume controls
  - Settings persistence

#### Content
- **World 1: Mystic Forest** (5 levels)
  - Level 1: Tutorial Path (Easy, 3 checkpoints)
  - Level 2: Forest Trail (Easy, 4 checkpoints, 1 fragment)
  - Level 3: River Crossing (Normal, 5 checkpoints, 1 fragment)
  - Level 4: Ancient Ruins (Normal, 6 checkpoints, 1 fragment)
  - Level 5: Guardian's Gate (Hard, 7 checkpoints, boss finale)

- **3 NPCs with 15+ dialogue nodes**
  - Guide (Elder Moss): Main quest giver, 10 nodes
  - Merchant (Trader Tom): Shop keeper, 5 nodes
  - Elder (Ancient One): Lore keeper, 6 nodes

- **12 Quests**
  - 6 story quests: Tutorial → Forest Trail → River Crossing → Ruins → Guardian's Gate
  - 6 daily quest types: Coins, Levels, NPCs, Speed, Perfect, Collector

- **Collectibles**
  - 3 Ancient Fragments across levels 2-4
  - Coin pickups in all levels
  - Bonus crystals (optional)

#### Configuration
- **StoryConfig.lua** with game-wide settings
  - World definitions
  - NPC configurations
  - Quest parameters
  - Collectible settings
  - Dialogue parameters
  - Progression rules
  - Monetization hooks

- **NPCDialogues.lua** with all conversation trees
- **StoryChapters.lua** with level metadata
- **QuestDefinitions.lua** with all quests

#### Documentation
- **README.md**: Complete game overview
- **QUICKSTART.md**: 5-step setup guide
- **IMPLEMENTATION_SUMMARY.md**: Detailed status report
- **ARCHITECTURE.md**: System design diagrams
- **TESTING_GUIDE.md**: Comprehensive testing checklist
- **CHANGELOG.md**: This file

#### Infrastructure
- **Main.server.lua** with proper initialization order
- **RemoteEventsInit** with 20+ secure remotes
- **ServiceLocator** pattern for service management
- Rojo project configuration

### Technical Details

**Services:** 12 server-side services
**UI Scripts:** 5 client-side interfaces
**Data Files:** 4 configuration modules
**Remote Events:** 20+ secure endpoints
**Total Code:** 24 custom Lua files + dependencies

**Architecture Highlights:**
- Service-based design for clean separation
- Lazy loading to avoid circular dependencies
- Event-driven client-server communication
- Data-driven content (easy to expand)
- Built-in anti-cheat and validation
- Staggered autosave for performance

### Security Features
- Rate limiting on all remotes (2-20 calls/second)
- Collection spam protection (5/second max)
- Type validation on all inputs
- Profile session locking
- Server-authoritative data changes
- No client-side money manipulation

### Performance Optimizations
- Staggered autosave (2-3 players/second)
- Lazy service loading
- Efficient data queries
- Minimal client-server traffic
- Proper memory cleanup

---

## Version History

### [1.0.0] - 2025-02-05
Initial release - Complete MVP with World 1

### Future Versions

#### [1.1.0] - Planned
- World 2: Crystal Caves
- New NPCs and dialogues
- 5 new levels
- New collectibles

#### [1.2.0] - Planned
- Story Pass system
- Cosmetic shop
- Developer products
- VIP perks

#### [1.3.0] - Planned
- Party system
- Speed run leaderboards
- Social achievements
- Friend invites

#### [2.0.0] - Planned
- Worlds 3-5
- Cutscene system
- Branching narratives
- Multiple endings
- Character abilities
- Skill tree

---

## Migration Guide

### Upgrading from Tower Ascent

If you're familiar with Tower Ascent, here are the key differences:

**New Systems:**
- StoryService (replaces TowerService)
- DialogueService (new)
- NPCService (new)
- WorldService (new)
- CollectibleService (new)

**Modified Systems:**
- DataService: Extended with Story and expanded Quests data
- QuestService: Adapted for story quests + daily quests
- RemoteEventsInit: 20+ new story-related remotes

**Preserved Systems:**
- CoinService (unchanged)
- AchievementService (unchanged)
- LeaderboardService (unchanged)
- SecurityManager (unchanged)
- SecureRemotes (unchanged)

**Data Migration:**
If migrating from Tower Ascent, increment `PROFILE_STORE_NAME` in DataService.lua to avoid data conflicts.

---

## Known Issues

None currently. This is a fresh implementation.

---

## Credits

**Architecture:** Based on Tower Ascent proven systems
**ProfileService:** loleris - https://github.com/MadStudioRoblox/ProfileService
**Promise:** evaera - https://github.com/evaera/roblox-lua-promise

---

## License

This is a learning/portfolio project. Feel free to use as reference.

---

## Support

For issues, questions, or contributions:
- Check README.md for documentation
- Check TESTING_GUIDE.md for debugging
- Check QUICKSTART.md for setup help
- Check ARCHITECTURE.md for system design

---

**Current Version: 1.0.0** - Ready for Studio building phase! 🎮✨
