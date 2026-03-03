# Tower Ascent - Monetization Setup Checklist

## ⚠️ CRITICAL: Update Product IDs Before Launch

All monetization product IDs are currently set to placeholder `0`. You MUST update these with actual Roblox product IDs before launching.

## Step 1: Create Products on Roblox

### Game Passes (One-time purchases)

1. **VIP Pass**
   - Go to: https://create.roblox.com/dashboard/creations
   - Select "Tower Ascent" game
   - Click "Monetization" → "Passes"
   - Create New Pass:
     - Name: "VIP"
     - Description: "2x coins, VIP tag, exclusive perks!"
     - Price: 299 Robux (recommended)
   - Copy the Game Pass ID

2. **Speed Boost Pass**
   - Create New Pass:
     - Name: "Permanent Speed Boost"
     - Description: "Run faster permanently!"
     - Price: 199 Robux

3. **Double Jump Pass**
   - Create New Pass:
     - Name: "Double Jump"
     - Description: "Jump again in mid-air!"
     - Price: 149 Robux

4. **Air Dash Pass**
   - Create New Pass:
     - Name: "Air Dash"
     - Description: "Dash forward while airborne!"
     - Price: 249 Robux

### Developer Products (Repeatable purchases)

1. **1000 Coins Pack**
   - Go to "Monetization" → "Developer Products"
   - Create New Product:
     - Name: "1000 Coins"
     - Description: "Instant 1000 coins!"
     - Price: 29 Robux
   - Copy the Product ID

2. **5000 Coins Pack**
   - Create New Product:
     - Name: "5000 Coins"
     - Description: "Instant 5000 coins!"
     - Price: 129 Robux

3. **10000 Coins Pack**
   - Create New Product:
     - Name: "10000 Coins"
     - Description: "Instant 10000 coins - BEST VALUE!"
     - Price: 229 Robux

## Step 2: Update Game Configuration

Open `/src/ReplicatedStorage/Shared/Config/GameConfig.lua` and update these sections:

### Update VIP Configuration
```lua
-- Line 38 in VIPService.lua
VIPGamePassId = YOUR_VIP_GAMEPASS_ID_HERE,
```

### Update Monetization Section
```lua
GameConfig.Monetization = {
	-- Game Passes (one-time purchases)
	GamePasses = {
		VIP = YOUR_VIP_PASS_ID,           -- Replace 0
		SpeedBoost = YOUR_SPEED_PASS_ID,  -- Replace 0
		DoubleJump = YOUR_JUMP_PASS_ID,   -- Replace 0
		AirDash = YOUR_DASH_PASS_ID,      -- Replace 0
	},

	-- Developer Products (repeatable purchases)
	DeveloperProducts = {
		Coins1000 = YOUR_1000_COINS_ID,   -- Replace 0
		Coins5000 = YOUR_5000_COINS_ID,   -- Replace 0
		Coins10000 = YOUR_10000_COINS_ID, -- Replace 0
	},
}
```

## Step 3: Verify Configuration

Run the validation script:
```lua
-- In Roblox Studio Command Bar:
require(game.ServerScriptService.Utilities.MonetizationValidator).ValidateAll()
```

This will check:
- ✅ All product IDs are set (not 0)
- ✅ Product IDs are valid numbers
- ✅ Products exist on Roblox (if possible)

## Step 4: Test Purchases

1. **Enable Studio Testing**
   - Test → Game Settings → Security → Enable Studio Access to API Services
   - Test → Start Server
   - Test purchases in Studio (they won't charge Robux)

2. **Test Each Product**
   - [ ] VIP Pass - Verify 2x coins
   - [ ] Speed Boost - Verify speed increase
   - [ ] Double Jump - Verify can jump in air
   - [ ] Air Dash - Verify dash works
   - [ ] 1000 Coins - Verify coins added
   - [ ] 5000 Coins - Verify coins added
   - [ ] 10000 Coins - Verify coins added

3. **Test Error Cases**
   - [ ] Purchase with 0 Robux (should fail gracefully)
   - [ ] Cancel purchase (should not grant item)
   - [ ] Network failure during purchase (should not lose Robux)

## Step 5: Launch Checklist

Before publishing to production:

- [ ] All 7 product IDs updated from placeholder `0`
- [ ] Validation script passes all checks
- [ ] All products tested in Studio
- [ ] Product descriptions are clear
- [ ] Prices are set correctly
- [ ] Icons uploaded (if applicable)
- [ ] Receipt processing tested
- [ ] Webhook notifications working (optional)

## Pricing Recommendations

**Game Passes (Total: 896 Robux for all)**
- VIP: 299 Robux (~30% discount vs buying coins)
- Speed Boost: 199 Robux
- Double Jump: 149 Robux
- Air Dash: 249 Robux

**Developer Products**
- 1000 Coins: 29 Robux (29 coins per Robux)
- 5000 Coins: 129 Robux (38.7 coins per Robux - 33% bonus)
- 10000 Coins: 229 Robux (43.6 coins per Robux - 50% bonus)

## Revenue Projections

**Conservative (100 CCU average)**
- 10% conversion rate = 10 buyers/day
- Average purchase = 150 Robux
- Daily revenue = 1500 Robux (~$5.25 USD)
- Monthly revenue = ~$157 USD

**Optimistic (500 CCU average)**
- 15% conversion rate = 75 buyers/day
- Average purchase = 200 Robux
- Daily revenue = 15,000 Robux (~$52.50 USD)
- Monthly revenue = ~$1,575 USD

## Support

If purchases fail:
1. Check game is published (not private)
2. Verify API services enabled
3. Check product IDs are correct
4. Test in actual published game (not Studio)
5. Check Roblox Developer Console for errors

## Security Notes

- ✅ All purchases processed server-side
- ✅ Receipt validation implemented
- ✅ Rate limiting on purchase prompts
- ✅ Product ownership verification
- ✅ No client trust in purchase flow

---

**Last Updated:** 2026-02-22
**Status:** ⚠️ Requires configuration before launch
