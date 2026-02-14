# Setup Guide - Pet Collector Simulator

Quick step-by-step guide to get your game running and making money.

---

## ⚡ **Quick Start (15 minutes)**

### **1. Start Rojo (Sync Code to Studio)**

```bash
cd /mnt/e/projects/roblox/pet-collector-sim
rojo serve
```

Keep this running in the terminal.

---

### **2. Open Roblox Studio**

1. Create a new place
2. Save it as "PetCollectorSimulator"
3. In Studio, go to **Plugins → Rojo**
4. Click **Connect** (should connect to localhost:34872)
5. Click **Sync In** (imports all code)

**You should see:**
- ReplicatedStorage/Shared
- ReplicatedStorage/Packages
- ServerScriptService/Main
- ServerScriptService/Services (5 files)
- ServerScriptService/Security
- ServerScriptService/Utilities

---

### **3. Create Game Passes**

1. Go to [Roblox Creator Dashboard](https://create.roblox.com/)
2. Select your game
3. Go to **Monetization → Passes**
4. Create 5 game passes:

| Pass Name | Price | Description |
|-----------|-------|-------------|
| VIP | 350 R$ | 2x coins, exclusive pets, no cooldown |
| Lucky Boost | 250 R$ | 3x chance for legendary pets |
| Auto Hatch | 400 R$ | Auto-hatch eggs every 5 seconds |
| Speed Boost | 150 R$ | 2x walk speed, jump boost |
| Extra Slots | 300 R$ | +10 pet slots, equip 3 pets |

5. **Copy each Pass ID** (you'll need these)

---

### **4. Create Developer Products**

Go to **Monetization → Developer Products** and create:

**Coin Packs:**
- `Coins_1000` - 50 R$ - 1,000 coins
- `Coins_5000` - 200 R$ - 5,000 coins
- `Coins_25000` - 800 R$ - 25,000 coins
- `Coins_100000` - 2,500 R$ - 100,000 coins

**Egg Packs:**
- `BasicEgg_10Pack` - 100 R$ - 10 Basic Eggs
- `RareEgg_5Pack` - 250 R$ - 5 Rare Eggs
- `LegendaryEgg_Single` - 400 R$ - 1 Legendary Egg

**Boosts:**
- `LuckBoost_1Hour` - 100 R$ - 2x luck for 1 hour
- `CoinBoost_1Hour` - 150 R$ - 3x coins for 1 hour

**Copy each Product ID** (you'll need these)

---

### **5. Configure IDs in Code**

Edit `/src/ReplicatedStorage/Shared/Config/GameConfig.lua`:

Replace all `Id = 0` with your actual IDs:

```lua
GameConfig.GamePasses = {
    VIP = {
        Id = 123456789, -- YOUR VIP PASS ID HERE
        Price = 350,
        -- ...
    },
    LuckyBoost = {
        Id = 987654321, -- YOUR LUCKY BOOST PASS ID HERE
        Price = 250,
        -- ...
    },
    -- ... repeat for all game passes
}

GameConfig.DeveloperProducts = {
    Coins_1000 = {
        Id = 111222333, -- YOUR COINS DEV PRODUCT ID HERE
        Price = 50,
        Amount = 1000,
    },
    -- ... repeat for all dev products
}
```

**Save and let Rojo sync** (automatic if rojo serve is running)

---

### **6. Build Worlds in Studio**

In Workspace, create 5 folders:

#### **World1 (Starter Island)**

1. Insert Part, name it `SpawnPoint`
2. Position: `(0, 10, 0)`
3. Anchored: Yes
4. Color: Green

Create a simple platform around spawn point (starter area).

#### **World2-5 (Copy World1 structure)**

- World2: Position spawn at `(200, 10, 0)`
- World3: Position spawn at `(400, 10, 0)`
- World4: Position spawn at `(600, 10, 0)`
- World5: Position spawn at `(800, 10, 0)`

Each world should have:
- Different terrain/theme
- Larger area than previous world
- Decorative elements

**Minimum viable: Just spawn points + basic platforms**

---

### **7. Test the Game**

Click **Play** in Studio (F5).

**Test these:**

1. **Data saves:**
   - Play for 1 minute
   - Stop (Shift+F5)
   - Play again
   - Check you still have data

2. **Egg hatching:**
   - Open console (F9)
   - Type: `_G.PetCollectorSim.DataService.AddCoins(game.Players.LocalPlayer, 1000)`
   - Try hatching an egg (you'll need UI for this, or use console)

3. **Game Pass check:**
   - Type: `_G.PetCollectorSim.MonetizationService.HasGamePass(game.Players.LocalPlayer, "VIP")`
   - Should return `false` (you don't own it yet)

4. **World teleportation:**
   - Type: `_G.PetCollectorSim.WorldService.TeleportToWorld(game.Players.LocalPlayer, 2)`
   - You should teleport to World2

**If all tests pass, core systems work!** ✅

---

## 🎨 **Next Steps: UI (Required for Launch)**

The game currently has no UI. You need to create:

### **1. Egg Hatch UI**

Location: `StarterGui/EggHatchUI.lua`

**What it needs:**
- Button: "Hatch Basic Egg (100 coins)"
- Shows current coins
- On click → `HatchEgg:FireServer("Basic")`
- Shows result (pet name, rarity, multiplier)

### **2. Pet Inventory UI**

Location: `StarterGui/PetInventoryUI.lua`

**What it needs:**
- Scrolling frame with all owned pets
- Equip/Unequip buttons
- Delete button (with confirmation)
- Shows rarity colors
- Shows coin multiplier

### **3. World Selection UI**

Location: `StarterGui/WorldSelectionUI.lua`

**What it needs:**
- Show 5 worlds
- Lock icon on locked worlds
- Shows unlock cost
- "Unlock" button (if requirements met)
- "Teleport" button (if unlocked)

### **4. Shop UI**

Location: `StarterGui/ShopUI.lua`

**What it needs:**
- **Game Passes tab:**
  - Shows all 5 game passes
  - Benefits list
  - "Purchase" button → `MarketplaceService:PromptGamePassPurchase()`
  - "Owned" badge if already purchased

- **Coins tab:**
  - Shows all coin packs
  - "Best Value" tag on bigger packs
  - "Purchase" button → `PurchaseProduct:FireServer("Coins_1000")`

- **Eggs tab:**
  - Shows all egg packs
  - Preview possible pets
  - "Purchase" button

### **5. Coin Display UI**

Location: `StarterGui/CoinDisplayUI.lua`

**What it needs:**
- Top-left corner
- Shows current coins (updates in real-time)
- Icon + number
- Animates when coins change

---

## 🔧 **Optional Enhancements**

### **Pet Models**

Replace `"rbxassetid://0"` in PetDefinitions.lua with:
- Actual pet models (toolbox or make your own)
- Pet icons for UI
- Or use simple parts with colors/shapes

### **Sounds & Music**

Add sound effects for:
- Egg hatch
- Coin collect
- World unlock
- Level up

Add background music for each world.

### **Visual Polish**

- Particle effects on rare pets (Sparkles for Legendary+)
- Coin pickup animation (tween to player)
- Egg hatch animation (egg cracks, pet appears)
- World transition animation (fade to black)

---

## 🚀 **Publishing**

### **Before you publish:**

✅ All game pass IDs configured
✅ All dev product IDs configured
✅ Basic UI working (hatch, inventory, shop)
✅ Worlds built with spawn points
✅ Data persistence tested
✅ No console errors

### **Publish steps:**

1. **File → Publish to Roblox**
2. Set game as Public
3. Create good thumbnail:
   - Show cute pets
   - "NEW!" or "FREE!" text
   - Bright colors
4. Write description:
   - "Collect 60+ pets!"
   - "Unlock 5 unique worlds!"
   - "Trade with friends!" (if you add trading)
   - "FREE to play!"
5. Add tags: Simulator, Pets, Collection, RPG

---

## 💰 **Launch Marketing**

### **Day 1-3: Soft Launch**
- Invite friends
- Post in Roblox groups
- Test monetization
- Fix any bugs

### **Day 4-7: Sponsored Ads**
- Budget: $10-50/day (1,000-5,000 Robux)
- Target: Pet Simulator players
- Monitor ROI (if ARPDAU > ad cost, keep running ads)

### **Week 2+: Content Updates**
- Add new pets weekly
- Run events (2x coins weekend)
- Engage with community

---

## 📊 **Monitor Revenue**

Check Creator Dashboard daily:

1. **Revenue** - How much earned today?
2. **DAU** - How many players today?
3. **ARPDAU** - Revenue ÷ DAU
4. **Top Products** - Which game passes sell most?

**Optimize based on data:**
- If VIP sells well → create VIP+ tier
- If Lucky Boost doesn't sell → lower price or improve benefits
- If DAU drops → add new content

---

## 🆘 **Troubleshooting**

### **"RemoteEvents not found"**
- Make sure Rojo synced properly
- Check ReplicatedStorage has RemoteEvents folder
- Try re-syncing (Rojo → Sync In)

### **"DataService.GetData is nil"**
- Services not initialized yet
- Wait for server startup (check output log)

### **"Game pass not working"**
- Double-check Pass ID in GameConfig.lua
- Pass must be created in Creator Dashboard
- Test with "Test Game Pass" feature in Studio

### **"Dev product not granting"**
- Check Product ID matches GameConfig.lua
- Check ProcessReceipt function in MonetizationService
- Test with "Test Purchase" in Studio

### **"Data not saving"**
- ProfileService might not be configured
- Check DataStore enabled in Studio settings
- Test in published game (Studio has different behavior)

---

## ✅ **Final Checklist**

Before launch:

- [ ] Rojo connected and synced
- [ ] All 5 game passes created and IDs configured
- [ ] All 9 dev products created and IDs configured
- [ ] 5 worlds built with spawn points
- [ ] UI created (hatch, inventory, world, shop, coins)
- [ ] Tested egg hatching
- [ ] Tested world unlocking
- [ ] Tested game pass purchase (use test mode)
- [ ] Tested dev product purchase (use test mode)
- [ ] Data persists between sessions
- [ ] No console errors
- [ ] Good thumbnail/icon created
- [ ] Game published as Public

**Time estimate: 4-6 hours total** (if you rush the UI and worlds)

---

**Ready to launch? You got this!** 💰🚀

For detailed monetization strategy, see `MONETIZATION_GUIDE.md`.
