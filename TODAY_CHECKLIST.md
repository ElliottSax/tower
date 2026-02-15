# TODAY'S CHECKLIST - Friday Feb 14, 2026

**Mission**: Get Pet Quest Legends monetization configured and tested
**Goal**: First revenue within 7 days
**Time Required**: 4 hours

---

## ✅ Priority 1: Pet Quest Legends Monetization Setup

### Task 1: Create Developer Products on Roblox (1.5 hours)

**Step-by-Step**:

1. **Go to Roblox Creator Dashboard**
   - Navigate to: https://create.roblox.com/dashboard/creations
   - Sign in if needed

2. **Select Pet Quest Legends**
   - Find your game in the list
   - Click to open game dashboard

3. **Navigate to Monetization**
   - Left sidebar → "Monetization"
   - Click "Developer Products"

4. **Create Gem Pack 100**
   - Click "Create Developer Product"
   - Name: `Gem Pack 100`
   - Description: `100 Gems - Best for beginners!`
   - Price: `100 Robux`
   - Icon: Upload icon (optional, can add later)
   - Click "Create"
   - **COPY THE PRODUCT ID** (long number like 1234567890)
   - Paste into notepad: `GemPack100 ID: [paste here]`

5. **Create Gem Pack 500**
   - Click "Create Developer Product"
   - Name: `Gem Pack 500`
   - Description: `500 Gems + 50% Bonus! Popular choice!`
   - Price: `400 Robux`
   - Click "Create"
   - **COPY THE PRODUCT ID**
   - Paste into notepad: `GemPack500 ID: [paste here]`

6. **Create Gem Pack 1200**
   - Click "Create Developer Product"
   - Name: `Gem Pack 1200`
   - Description: `1,200 Gems + 100% Bonus! Great value!`
   - Price: `800 Robux`
   - Click "Create"
   - **COPY THE PRODUCT ID**
   - Paste into notepad: `GemPack1200 ID: [paste here]`

7. **Create Gem Pack 3000**
   - Click "Create Developer Product"
   - Name: `Gem Pack 3000`
   - Description: `3,000 Gems - Best Value! Most popular!`
   - Price: `1,999 Robux`
   - Click "Create"
   - **COPY THE PRODUCT ID**
   - Paste into notepad: `GemPack3000 ID: [paste here]`

8. **Verify Game Passes Exist** (15 minutes)
   - Navigate to "Passes" in monetization section
   - Check if these 6 passes exist:
     - 2x Coins (200 Robux)
     - 2x Luck (250 Robux)
     - Auto Clicker (300 Robux)
     - Extra Pet Slots (200 Robux)
     - Fast Hatch (150 Robux)
     - VIP (500 Robux)
   - If missing, create them
   - **COPY ALL GAME PASS IDs**

**Checkpoint**: You should have 4 Developer Product IDs and 6 Game Pass IDs

---

### Task 2: Update GameConfig.lua with IDs (30 minutes)

**Step-by-Step**:

1. **Open Pet Quest Legends in VS Code**
   - Path: `/mnt/e/projects/pet-quest-legends/`

2. **Open GameConfig.lua**
   - File: `src/ReplicatedStorage/Shared/Config/GameConfig.lua`

3. **Find DeveloperProducts Table** (around line 200-250)
   - Search for `DeveloperProducts = {`

4. **Update Gem Pack IDs**
   - Find this section:
   ```lua
   DeveloperProducts = {
       {
           Name = "GemPack100",
           Id = 0,  -- REPLACE WITH YOUR PRODUCT ID
           Gems = 100,
           Robux = 100,
           BonusPercent = 0
       },
       {
           Name = "GemPack500",
           Id = 0,  -- REPLACE WITH YOUR PRODUCT ID
           Gems = 500,
           Robux = 400,
           BonusPercent = 50
       },
       {
           Name = "GemPack1200",
           Id = 0,  -- REPLACE WITH YOUR PRODUCT ID
           Gems = 1200,
           Robux = 800,
           BonusPercent = 100
       },
       {
           Name = "GemPack3000",
           Id = 0,  -- REPLACE WITH YOUR PRODUCT ID
           Gems = 3000,
           Robux = 1999,
           BonusPercent = 100
       }
   }
   ```

5. **Replace Each `Id = 0` with Your Product IDs**
   - Copy from notepad where you saved them
   - Example: `Id = 1234567890,`
   - Make sure to keep the comma

6. **Find GamePasses Table**
   - Search for `GamePasses = {`

7. **Update Game Pass IDs**
   - Find this section:
   ```lua
   GamePasses = {
       {
           Name = "2xCoins",
           Id = 0,  -- REPLACE
           Price = 200,
           Benefits = { CoinMultiplier = 2 }
       },
       {
           Name = "2xLuck",
           Id = 0,  -- REPLACE
           Price = 250,
           Benefits = { LuckMultiplier = 2 }
       },
       -- ... etc for all 6 passes
   }
   ```

8. **Replace All Game Pass IDs**

9. **Save File** (Ctrl+S)

10. **Commit Changes** (if using Git)
    ```bash
    cd /mnt/e/projects/pet-quest-legends
    git add src/ReplicatedStorage/Shared/Config/GameConfig.lua
    git commit -m "feat(monetization): Add Developer Product IDs and Game Pass IDs"
    ```

**Checkpoint**: GameConfig.lua now has real IDs, file saved

---

### Task 3: Test in Roblox Studio (1.5 hours)

**Step-by-Step**:

1. **Open Pet Quest Legends in Roblox Studio**
   - If using Rojo: Start Rojo server first
     ```bash
     cd /mnt/e/projects/pet-quest-legends
     rojo serve
     ```
   - Open Roblox Studio
   - Connect Rojo plugin if using Rojo
   - OR just open the .rbxl file directly

2. **Enable API Services** (CRITICAL)
   - Home tab → Game Settings
   - Security tab
   - Enable "Allow HTTP Requests"
   - Enable "Enable Studio Access to API Services" ✓ (IMPORTANT)
   - Click "Save"

3. **Start Test Server**
   - Click "Play" (F5)
   - Studio will run in sandbox mode (fake purchases)

4. **Test Gem Shop UI**
   - Press 'G' key to open Gem Shop
   - Check if UI appears
   - Check if 3 tabs work (GEMS, EGGS, EVENTS)
   - Check if gem packs display correctly

5. **Test Gem Purchase (Sandbox)**
   - Click on "Gem Pack 100" button
   - Studio should show purchase prompt (sandbox mode)
   - Click "Buy" (fake purchase, no real Robux)
   - Check Output window for errors
   - Check if gems were added to player data

6. **Test Gem Spending**
   - Go to EGGS tab
   - Try to buy a premium egg (200 gems)
   - Check if gems deducted correctly
   - Check if egg hatches

7. **Test Gacha System**
   - Hatch multiple eggs
   - Verify rarity distribution (should get mostly Common/Uncommon)
   - Check pity counter (in F9 console, check player data)

8. **Test Fusion System**
   - Equip 2 pets of same rarity
   - Try to fuse them
   - Check if gem cost is correct
   - Check if fusion works

9. **Test Event System**
   - Check EVENTS tab
   - Verify event countdown displays
   - (Events may not be active, that's OK)

10. **Check for Errors**
    - Press F9 to open Developer Console
    - Check "Output" tab for red errors
    - Check "Server" tab for server errors
    - Copy any errors to notepad for later fixing

11. **Stop Test** (Shift+F5)

12. **Review Test Results**
    - Did gem purchases work? ✓ / ✗
    - Did gem spending work? ✓ / ✗
    - Did gacha work? ✓ / ✗
    - Did fusion work? ✓ / ✗
    - Any errors? (list them)

**Checkpoint**: Basic monetization flow tested in sandbox mode

---

### Task 4: Document Everything (30 minutes)

**Step-by-Step**:

1. **Create MONETIZATION_IDS.md**
   - File: `/mnt/e/projects/pet-quest-legends/MONETIZATION_IDS.md`
   - Content:
   ```markdown
   # Pet Quest Legends - Monetization IDs

   **Date Configured**: 2026-02-14

   ## Developer Products

   | Product | ID | Price | Gems | Bonus |
   |---------|-----|-------|------|-------|
   | Gem Pack 100 | [PASTE ID] | 100 R$ | 100 | 0% |
   | Gem Pack 500 | [PASTE ID] | 400 R$ | 500 | 50% |
   | Gem Pack 1200 | [PASTE ID] | 800 R$ | 1200 | 100% |
   | Gem Pack 3000 | [PASTE ID] | 1999 R$ | 3000 | 100% |

   ## Game Passes

   | Pass | ID | Price | Benefit |
   |------|-----|-------|---------|
   | 2x Coins | [PASTE ID] | 200 R$ | 2x coin earning |
   | 2x Luck | [PASTE ID] | 250 R$ | 2x rare pets |
   | Auto Clicker | [PASTE ID] | 300 R$ | Auto earn coins |
   | Extra Slots | [PASTE ID] | 200 R$ | 6 pet slots |
   | Fast Hatch | [PASTE ID] | 150 R$ | Instant hatching |
   | VIP | [PASTE ID] | 500 R$ | All benefits |

   ## Testing Notes

   **Studio Sandbox Testing** (2026-02-14):
   - Gem purchases: ✓ / ✗
   - Gem spending: ✓ / ✗
   - Gacha system: ✓ / ✗
   - Fusion system: ✓ / ✗
   - Errors found: [LIST]

   **Live Testing** (TBD):
   - Real Robux purchase: TBD
   - Receipt validation: TBD
   - Data persistence: TBD

   ## Next Steps

   1. [ ] Publish game to Roblox (unlisted)
   2. [ ] Test real Robux purchase (small amount)
   3. [ ] Verify data saves correctly
   4. [ ] Fix any bugs discovered
   5. [ ] Soft launch
   ```

2. **Update KNOWN_ISSUES.md** (if bugs found)
   - File: `/mnt/e/projects/pet-quest-legends/KNOWN_ISSUES.md`
   - List all bugs by severity
   - Plan which to fix pre-launch vs post-launch

3. **Commit All Changes**
   ```bash
   cd /mnt/e/projects/pet-quest-legends
   git add .
   git commit -m "feat(monetization): Configure IDs and complete testing

   - Added Developer Product IDs (4 gem packs)
   - Added Game Pass IDs (6 passes)
   - Tested monetization flow in Studio sandbox
   - Documented setup in MONETIZATION_IDS.md
   - [List any bugs found]"
   ```

**Checkpoint**: Everything documented and committed

---

## 📋 End of Day Checklist

**By end of today, you should have**:

- ✅ 4 Developer Products created on Roblox
- ✅ 6 Game Passes verified (or created if missing)
- ✅ All 10 IDs copied to notepad
- ✅ GameConfig.lua updated with real IDs
- ✅ Monetization tested in Studio sandbox
- ✅ All bugs documented
- ✅ Changes committed to Git
- ✅ MONETIZATION_IDS.md created

**Time spent**: ~4 hours

**Status**: Pet Quest Legends ready for live testing tomorrow

**Next Steps** (Tomorrow - Saturday):
1. Publish game to Roblox (unlisted)
2. Test real Robux purchase (buy smallest gem pack)
3. Verify gems are granted correctly
4. Verify data persists after logout/login
5. Fix any bugs discovered

---

## 🚨 If You Get Stuck

### Problem: Can't find Developer Products section
**Solution**: Make sure you're in the correct game dashboard. Check game name in top-left.

### Problem: Product IDs not working
**Solution**: Make sure you copied the entire number (no spaces, no commas). Product IDs are long numbers like 1234567890.

### Problem: Errors in Studio when testing purchases
**Solution**: Check if "Enable Studio Access to API Services" is enabled in Game Settings → Security.

### Problem: Gem Shop doesn't open with 'G' key
**Solution**: Check if GemShopUI.client.lua is in StarterGui folder. Check Output (F9) for errors.

### Problem: Rojo not syncing
**Solution**: Make sure `rojo serve` is running. Check Rojo plugin is connected (green circle).

---

## 💡 Success Indicators

**You'll know you succeeded today if**:

1. You can see all 4 gem packs in Roblox Creator Dashboard
2. You can see all 6 game passes in Creator Dashboard
3. GameConfig.lua has real IDs (no zeros)
4. In Studio, pressing 'G' opens the Gem Shop
5. In Studio sandbox, you can "buy" gems and the number increases
6. No red errors in Output window during testing
7. Everything is documented and committed to Git

**If all ✓ above, you're ready for Saturday's live testing!**

---

## 🎯 The Big Picture

**Why This Matters**:
- This is the ONLY thing blocking Pet Quest Legends from generating revenue
- Once these IDs are configured and tested, the game can make money
- Expected revenue: $10K-50K Month 1 if you hit 10K+ CCU
- This is your fastest path to financial independence

**Today's Work = Future Income**:
- 4 hours today
- 2-3 days until soft launch
- 7 days until full launch
- Revenue starts flowing

**You're 4 hours away from a revenue-generating game. Let's do this!** 💰🚀

---

**START NOW. TIME IS MONEY.** ⏰💵

**First action**: Open browser, go to https://create.roblox.com/dashboard/creations

**GO GO GO!** 🎮
