# Tower Ascent Prototype - Setup Guide

> **Complete setup in 15 minutes. No pre-made models needed - everything generates procedurally!**

**What You'll Build:**
- 10-section procedurally generated tower
- Checkpoint system (saves progress)
- Coin collection on completion
- Double jump upgrade (100 coins)
- Full climbing gameplay loop

**Time Required:** 15 minutes

---

## Prerequisites

### 1. Install Roblox Studio (if you haven't already)
1. Go to https://www.roblox.com/create
2. Click "Start Creating"
3. Download and install Roblox Studio
4. Sign in with your Roblox account

### 2. Files You Need
All prototype files are in `/mnt/e/projects/roblox/prototype/`
- `ServerScriptService/TowerGenerator.lua`
- `ServerScriptService/CheckpointService.lua`
- `ServerScriptService/CoinService.lua`
- `ServerScriptService/UpgradeService.lua`
- `StarterGui/CoinDisplay.lua`
- `StarterPlayer/StarterCharacterScripts/DoubleJump.lua`

---

## Step-by-Step Installation

### Step 1: Create New Place

1. Open Roblox Studio
2. Click **"New"** → Select **"Baseplate"** template
3. Click **"Create"**

This gives you a clean workspace with just a baseplate.

---

### Step 2: Setup Server Scripts

#### 2.1: Open Explorer Window
- If you don't see the **Explorer** window on the right side:
  - Click **View** tab → Check **"Explorer"**

#### 2.2: Insert TowerGenerator Script
1. In Explorer, find **ServerScriptService**
2. Right-click **ServerScriptService** → **Insert Object** → **Script**
3. Rename the script to `TowerGenerator`
4. Double-click `TowerGenerator` to open it
5. **Delete all default code**
6. Copy the entire contents of `prototype/ServerScriptService/TowerGenerator.lua`
7. Paste into the script
8. Press **Ctrl+S** to save

#### 2.3: Insert CheckpointService Script
1. Right-click **ServerScriptService** → **Insert Object** → **Script**
2. Rename to `CheckpointService`
3. Delete default code
4. Copy contents from `prototype/ServerScriptService/CheckpointService.lua`
5. Paste and save (Ctrl+S)

#### 2.4: Insert CoinService Script
1. Right-click **ServerScriptService** → **Insert Object** → **Script**
2. Rename to `CoinService`
3. Delete default code
4. Copy contents from `prototype/ServerScriptService/CoinService.lua`
5. Paste and save (Ctrl+S)

#### 2.5: Insert UpgradeService Script
1. Right-click **ServerScriptService** → **Insert Object** → **Script**
2. Rename to `UpgradeService`
3. Delete default code
4. Copy contents from `prototype/ServerScriptService/UpgradeService.lua`
5. Paste and save (Ctrl+S)

**Your ServerScriptService should now contain:**
- TowerGenerator
- CheckpointService
- CoinService
- UpgradeService

---

### Step 3: Setup Client UI

#### 3.1: Insert CoinDisplay UI Script
1. In Explorer, find **StarterGui**
2. Right-click **StarterGui** → **Insert Object** → **LocalScript**
3. Rename to `CoinDisplay`
4. Delete default code
5. Copy contents from `prototype/StarterGui/CoinDisplay.lua`
6. Paste and save (Ctrl+S)

---

### Step 4: Setup Character Scripts

#### 4.1: Create StarterCharacterScripts Folder
1. In Explorer, find **StarterPlayer**
2. Right-click **StarterPlayer** → **Insert Object** → **Folder**
3. Rename the folder to `StarterCharacterScripts` (EXACT NAME - case sensitive!)

#### 4.2: Insert DoubleJump Script
1. Right-click **StarterCharacterScripts** → **Insert Object** → **LocalScript**
2. Rename to `DoubleJump`
3. Delete default code
4. Copy contents from `prototype/StarterPlayer/StarterCharacterScripts/DoubleJump.lua`
5. Paste and save (Ctrl+S)

**Your hierarchy should look like:**
```
StarterPlayer
└── StarterCharacterScripts
    └── DoubleJump (LocalScript)
```

---

### Step 5: Configure Spawn Location

#### 5.1: Delete Default SpawnLocation
1. In **Workspace**, find `SpawnLocation`
2. Right-click → **Delete**

#### 5.2: Create New Spawn
1. Right-click **Workspace** → **Insert Object** → **Part**
2. Rename to `SpawnLocation`
3. In **Properties** window:
   - **Position:** `0, 5, 0`
   - **Size:** `10, 1, 10`
   - **Anchored:** ✓ (checked)
   - **BrickColor:** Bright blue
4. Right-click the part → **Insert Object** → **SpawnLocation** (yes, insert the SpawnLocation OBJECT into the part)

This creates a spawn point at the base of the tower.

---

### Step 6: Test The Prototype!

#### 6.1: Run Test
1. Click the **Play** button (▶️) at the top of Studio
2. Wait 2-3 seconds for the tower to generate

**What Should Happen:**
- You spawn on a blue platform
- Tower generates in front of you (10 colorful sections)
- You see "Coins: 0" in top-left corner
- You see "Upgrade Shop" with "Buy Double Jump" button
- Output window shows initialization messages

#### 6.2: Test Gameplay Loop

**Test 1: Climbing & Checkpoints**
1. Walk into the tower (first section)
2. You should see a green checkpoint activate (turns yellow briefly)
3. Press **R** to reset your character
4. You should respawn at the checkpoint (not the start!)

**Test 2: Finish Line & Coins**
1. Climb all 10 sections (use Reset if you fall to save time)
2. Touch the gold finish line at the end
3. You should see "Coins: 100" appear
4. You teleport back to the start

**Test 3: Buy Double Jump**
1. After earning 100 coins, click "Buy Double Jump (100 coins)" button
2. Button should change to "Double Jump (OWNED)"
3. Your coins should decrease to 0

**Test 4: Use Double Jump**
1. Jump once (press Space)
2. While in the air, press Space again
3. You should jump a second time!
4. Use this to climb sections more easily

#### 6.3: Check Output for Errors
- Click **View** → **Output** to see the output window
- You should see messages like:
  ```
  [TowerGenerator] Generating 10-section tower...
  [TowerGenerator] Generated section 1: Section_1_Flat
  [CheckpointService] Initialized player: YourUsername
  [CoinService] Initialized YourUsername with 0 coins
  ```

- **No red errors should appear!**

---

## Troubleshooting

### Problem: Tower Doesn't Generate

**Solution:**
1. Check Output window for errors (View → Output)
2. Verify TowerGenerator script is in ServerScriptService (NOT Workspace!)
3. Make sure the script is named exactly `TowerGenerator`
4. Check that it's a **Script**, not a **LocalScript** (should have red icon)

---

### Problem: UI Doesn't Appear

**Solution:**
1. Verify CoinDisplay is in **StarterGui** (NOT StarterPlayer!)
2. Make sure it's a **LocalScript** (should have blue icon)
3. Check Output for errors starting with `[CoinUI]`
4. Try stopping and restarting the test (click Stop, then Play again)

---

### Problem: Double Jump Doesn't Work

**Solution:**
1. Verify DoubleJump is in **StarterPlayer > StarterCharacterScripts**
2. Folder MUST be named `StarterCharacterScripts` exactly
3. Make sure it's a **LocalScript**
4. Check that you actually bought the upgrade (coins should be 0 after purchase)
5. Jump, then press Space WHILE IN THE AIR (not on ground)

---

### Problem: Checkpoints Don't Save

**Solution:**
1. Wait 1 second after touching checkpoint
2. Make sure you touched the GREEN transparent part (not just the platform)
3. Check Output for messages like `[CheckpointService] PlayerName reached section X`
4. Verify CheckpointService script is running (check Output on game start)

---

### Problem: No Coins After Finishing

**Solution:**
1. Make sure you touched the GOLD finish line (section 10)
2. Check Output for: `[CheckpointService] PlayerName completed the tower!`
3. Verify CoinService and CheckpointService scripts are both in ServerScriptService
4. Make sure CoinService loads BEFORE CheckpointService (alphabetical order is fine)

---

## Understanding the Prototype

### File Responsibilities

**Server Scripts (ServerScriptService):**
- `TowerGenerator.lua` - Generates 10 sections procedurally (runs once on start)
- `CheckpointService.lua` - Handles checkpoint touches, respawning, finish line
- `CoinService.lua` - Manages coin storage and transactions
- `UpgradeService.lua` - Handles upgrade purchases (validates with CoinService)

**Client Scripts:**
- `CoinDisplay.lua` (StarterGui) - Shows UI, sends purchase requests
- `DoubleJump.lua` (StarterCharacterScripts) - Detects jump input, performs double jump

### How It Works

**1. Tower Generation (Server):**
- TowerGenerator creates 10 sections on server start
- Each section has a checkpoint (green part) and connection points
- Section types: Flat, Gap Jump, Staircase, ZigZag, Wall Climb
- Difficulty increases (sections 1-2 easy, 8-10 hard)

**2. Checkpoint System (Server):**
- Green checkpoints tagged with CollectionService
- When touched, saves section number and position
- On death/respawn, teleports to last checkpoint
- Finish line (gold) awards 100 coins

**3. Coin System (Server + Client):**
- Server stores coin amounts (in-memory, resets on server restart)
- Server validates all transactions
- Client UI displays coins
- RemoteEvents synchronize server ↔ client

**4. Upgrade System (Server + Client):**
- Client requests purchase via RemoteEvent
- Server validates (checks coins, ownership)
- Server deducts coins and grants upgrade
- Client receives confirmation and enables double jump

**5. Double Jump (Client):**
- Detects Space bar while in air
- Checks upgrade ownership
- Applies upward velocity
- Resets when player lands

---

## Next Steps

### Customize Your Prototype

**Change Tower Height:**
- Open `TowerGenerator.lua`
- Line 9: Change `SECTIONS_COUNT = 10` to any number (try 20!)

**Adjust Double Jump Cost:**
- Open `UpgradeService.lua`
- Line 20: Change `cost = 100` to any number

**Modify Coin Reward:**
- Open `CheckpointService.lua`
- Line 68: Change `CoinService.AddCoins(player, 100)` to any number

**Add More Section Variety:**
- Open `TowerGenerator.lua`
- Add new generator functions (see `generateFlatPlatform` as example)
- Add to section type rotation (line 253)

---

## What This Validates

✅ **Core Gameplay Loop:**
- Climbing is fun and challenging
- Checkpoints feel rewarding
- Finishing gives sense of accomplishment

✅ **Progression System:**
- Coins motivate completion
- Upgrades enhance gameplay
- Players want to climb again with new abilities

✅ **Technical Foundation:**
- Procedural generation works
- Client-server communication reliable
- No major performance issues

**If this prototype is FUN, proceed to Week 1 full implementation!**

**If NOT fun, identify what needs to change before investing 40-52 weeks.**

---

## Performance Notes

**Expected Performance:**
- 60 FPS on most devices
- ~200-300 parts total (very light)
- Memory usage: <100 MB
- Works on mobile (touch controls for jump)

**This prototype intentionally has:**
- No DataStore (persistence)
- No round timer
- Basic graphics (neon materials)
- Simple sections (no complex geometry)

**Week 1+ will add:**
- ProfileService (data persistence)
- 8-minute round timer
- Better graphics and polish
- 30+ unique sections
- Advanced systems (ranked, UGC, pets, etc.)

---

## Success Criteria

### ✅ Prototype is SUCCESSFUL if:
- [ ] You can climb all 10 sections
- [ ] Checkpoints save your progress
- [ ] Finishing awards 100 coins
- [ ] You can buy double jump
- [ ] Double jump works reliably
- [ ] **Most importantly: It's FUN and you want to play more!**

### ❌ Reconsider if:
- [ ] Climbing feels frustrating (not challenging)
- [ ] Checkpoints are too far apart (progress loss hurts)
- [ ] Sections are too repetitive/boring
- [ ] Double jump doesn't feel impactful
- [ ] You don't want to climb the tower again

---

## Ready for Production?

**If prototype is successful:**

1. Read **[TOWER_ASCENT_WEEK_1.md](/mnt/e/projects/roblox/TOWER_ASCENT_WEEK_1.md)** for full implementation
2. Decide: Standard / Premium / World-Class (see [DECISION_TREE.md](/mnt/e/projects/roblox/DECISION_TREE.md))
3. Set up proper development environment (Rojo, Wally, Git)
4. Begin Week 1 implementation

**If prototype needs work:**
- Adjust section difficulty
- Add more variety
- Tweak checkpoint placement
- Modify jump mechanics
- Test with friends for feedback

---

## Questions?

**Technical Issues:**
- Check Output window for error messages
- Verify all scripts are in correct locations
- Make sure Scripts vs LocalScripts are correct

**Gameplay Feedback:**
- Play for 10 minutes minimum
- Test all 10 sections
- Try with and without double jump
- Ask: "Would I play this for hours?"

---

**Estimated Setup Time:** 15 minutes
**Estimated Test Time:** 10 minutes
**Total:** 25 minutes to validate your next 40-52 weeks!

**Good luck! 🚀🎮**
