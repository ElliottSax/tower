# Dimension Hopper

A multiplayer competitive obby game where players race through four unique dimensions, each with its own physics-defying mechanics.

## Game Concept

**Dimension Hopper** combines the thrill of competitive racing with unique dimensional mechanics. Players race through procedurally-assembled tower sections, mastering gravity flips, shrinking through tiny passages, escaping a chasing void, and gliding through the sky.

## Four Dimensions

### 1. Gravity Dimension 🌀
- **Mechanic**: Gravity flip zones that change your orientation
- **Challenge**: Navigate platforms while gravity shifts (up, down, sideways)
- **Theme**: Purple/indigo space aesthetic with cyan glow

### 2. Tiny Dimension 🐜
- **Mechanic**: Scale zones that shrink players to different sizes
- **Challenge**: Access tiny passages only small players can fit through
- **Theme**: Forest green nature aesthetic (you're ant-sized)

### 3. Void Dimension 👁️
- **Mechanic**: A chasing void that consumes everything behind you
- **Challenge**: Stay ahead of the void while platforms crumble after you touch them
- **Theme**: Dark red/black horror aesthetic with tension building

### 4. Sky Dimension 🦅
- **Mechanic**: Glider with boost meter, wind currents, and updrafts
- **Challenge**: Navigate floating islands using flight physics
- **Theme**: Bright sky blue with white clouds

## Game Modes

| Mode | Description | Players |
|------|-------------|---------|
| **Dimension Race** | Race through a single dimension | 1-16 |
| **Marathon** | All four dimensions back-to-back (2.5x XP) | 1-8 |
| **Practice** | No timer, unlimited respawns | 1 |
| **Daily Challenge** | Special modifiers, bonus rewards | 1-16 |

## Project Structure

```
dimension-hopper/
├── default.project.json          # Rojo configuration
├── README.md                     # This file
├── GAME_DESIGN.md               # Full design document
│
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/
    │       └── Config/
    │           └── GameConfig.lua    # All game settings
    │
    ├── ServerScriptService/
    │   ├── Main.server.lua           # Server bootstrap
    │   └── Services/
    │       ├── DataService.lua       # Player data persistence
    │       ├── DimensionService.lua  # Dimension loading/switching
    │       ├── GravityService.lua    # Gravity flip mechanics
    │       ├── ScaleService.lua      # Player scaling mechanics
    │       ├── VoidService.lua       # Chasing void mechanics
    │       ├── GliderService.lua     # Flight mechanics
    │       ├── RaceService.lua       # Multiplayer racing
    │       ├── CheckpointService.lua # Progress tracking
    │       ├── SoundService.lua      # Audio management
    │       ├── DimensionPassService.lua  # Season Pass
    │       └── MonetizationService.lua   # Game Passes & Products
    │
    ├── StarterPlayer/
    │   └── StarterPlayerScripts/
    │       ├── ClientMain.client.lua    # Main client controller
    │       └── SoundHandler.client.lua  # Client audio
    │
    └── StarterGui/
        ├── GameHUD.client.lua    # Race HUD
        └── LobbyUI.client.lua    # Menu & lobby
```

## Setup Instructions

### Prerequisites
- [Rojo](https://rojo.space/) installed
- Roblox Studio

### Installation

1. Clone or download this project
2. Open a terminal in the project directory
3. Start Rojo server:
   ```bash
   rojo serve
   ```
4. Open Roblox Studio
5. Install the Rojo plugin if not already installed
6. Click "Connect" in the Rojo plugin panel

### Building for Publication

```bash
rojo build -o DimensionHopper.rbxlx
```

## Configuration

All game settings are centralized in `GameConfig.lua`:

- **Dimensions**: Themes, settings, difficulty scaling
- **Race Settings**: Lobby times, player counts, timeouts
- **Progression**: XP requirements, level rewards
- **Monetization**: Product IDs, prices, benefits

### Setting Up Monetization

1. Create Game Passes in Roblox Creator Dashboard
2. Create Developer Products for consumables
3. Update IDs in `GameConfig.lua`:
   ```lua
   GameConfig.Monetization.DimensionPass.ProductId = YOUR_ID
   GameConfig.Monetization.GamePasses.WingCollection.Id = YOUR_ID
   -- etc.
   ```

## Tags Reference

The game uses CollectionService tags for gameplay elements:

| Tag | Description |
|-----|-------------|
| `Checkpoint` | Section checkpoints (requires `Section` attribute) |
| `FinishLine` | Race finish line (optional `Dimension` attribute) |
| `GravityFlip` | Gravity flip zone (requires `FlipDirection` attribute) |
| `ScaleZone` | Scale change zone (requires `TargetScale` or `ScaleMode` attribute) |
| `CrumblingPlatform` | Platform that crumbles after touch |
| `WindCurrent` | Wind zone (requires `WindDirection`, `WindStrength` attributes) |
| `Updraft` | Vertical lift zone (requires `LiftStrength` attribute) |
| `TinyPassage` | Passage only small players can enter |

## Building Levels

### Section Setup

Each section should:
1. Have a `Checkpoint` tagged part at the start
2. Set the `Section` attribute (number) on the checkpoint
3. Include dimension-appropriate hazards and mechanics

### Dimension-Specific Elements

**Gravity**:
- Add `GravityFlip` tagged parts with `FlipDirection` = "Up"/"Down"/"Left"/"Right"/"Reverse"

**Tiny**:
- Add `ScaleZone` tagged parts with `TargetScale` = 0.5, 0.25, 0.1, or 0.05

**Void**:
- Add `CrumblingPlatform` tagged parts (optional `CrumbleDelay` attribute)

**Sky**:
- Add `WindCurrent` and `Updraft` tagged parts

## Progression System

### Player Level
- Earned from races, challenges, collectibles
- Unlocks cosmetic rewards at milestone levels

### Dimension Mastery
- Separate XP track per dimension
- Tiers: Bronze → Silver → Gold → Diamond → Master
- Mastery unlocks dimension-specific rewards

### Dimension Pass (Season Pass)
- 50 tiers per season
- Free and Premium tracks
- Daily/Weekly challenges
- Seasonal cosmetic rewards

## Monetization

### Ethical Design
- No pay-to-win advantages
- Cosmetic-only purchases
- Clear value propositions
- Optional ad watching for small rewards

### Products
- **Dimension Pass**: Seasonal premium track
- **VIP Membership**: 2x XP, queue priority
- **Game Passes**: Cosmetic packs (Wings, Trails, Emotes)
- **Developer Products**: XP boosts (consumable)

## Services API

### DataService
```lua
DataService.AddXP(player, amount, source)
DataService.GetData(player)
DataService.UnlockItem(player, category, itemId)
```

### RaceService
```lua
RaceService.AddToLobby(player, dimension, gameMode)
RaceService.RemoveFromLobby(player)
RaceService.SetPlayerReady(player)
```

### DimensionPassService
```lua
DimensionPassService.AddPassXP(player, amount)
DimensionPassService.OnRaceComplete(player)
DimensionPassService.OnGravityFlip(player)
```

## Debug Commands

Access via server console or admin commands:

```lua
-- Add XP to player
_G.DimensionHopper.GetService("DataService").AddXP(player, 1000, "Debug")

-- Set pass tier
_G.DimensionHopper.GetService("DimensionPassService").DebugSetTier(player, 25)

-- Grant game pass (testing)
_G.DimensionHopper.GetService("MonetizationService").DebugGrantPass(player, "VIP")
```

## Contributing

When adding new features:
1. Follow the existing service pattern
2. Add configuration to `GameConfig.lua`
3. Use CollectionService tags for world elements
4. Update this README

## License

This project is for educational purposes. Roblox assets and branding are property of Roblox Corporation.
