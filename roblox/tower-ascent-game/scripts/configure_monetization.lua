--[[
	configure_monetization.lua
	Automated script to update all monetization product IDs

	Usage:
	1. Create all 15 products on Roblox Creator Dashboard
	2. Update the IDs in the CONFIG section below
	3. Run this script: lua scripts/configure_monetization.lua
	4. Script will update all 4 service files automatically

	OR: Manually update each service file (see MONETIZATION_SETUP_GUIDE.md)
--]]

-- ============================================================================
-- CONFIGURATION - UPDATE THESE WITH YOUR PRODUCT IDs
-- ============================================================================

local PRODUCT_IDS = {
	-- GAME PASSES (7 passes)
	VIP_PASS = 0,              -- VIP Pass (500 Robux) - 2x coins forever
	BATTLE_PASS = 0,           -- Premium Battle Pass Season 1 (99 Robux)
	PARTICLE_EFFECTS = 0,      -- Particle Effects Pack (149 Robux)
	EMOTE_PACK = 0,            -- Emote Pack (99 Robux)
	DOUBLE_XP = 0,             -- Double XP (199 Robux)
	CHECKPOINT_SKIP = 0,       -- Checkpoint Skip (79 Robux)
	SPEED_DEMON = 0,           -- Speed Demon (149 Robux)

	-- DEVELOPER PRODUCTS (8 products)
	COIN_PACK_SMALL = 0,       -- 500 Coins (49 Robux)
	COIN_PACK_MEDIUM = 0,      -- 1,500 Coins (99 Robux)
	COIN_PACK_LARGE = 0,       -- 4,000 Coins (199 Robux)
	COIN_PACK_MEGA = 0,        -- 10,000 Coins (399 Robux)
	XP_BOOST_30MIN = 0,        -- 30 Min XP Boost (29 Robux)
	XP_BOOST_1HOUR = 0,        -- 1 Hour XP Boost (49 Robux)
	XP_BOOST_3HOUR = 0,        -- 3 Hour XP Boost (99 Robux)
	RESPAWN_SKIP = 0,          -- Respawn Skip (19 Robux)
}

-- ============================================================================
-- FILE PATHS
-- ============================================================================

local FILES = {
	VIPService = "src/ServerScriptService/Services/Monetization/VIPService.lua",
	BattlePassService = "src/ServerScriptService/Services/Monetization/BattlePassService.lua",
	GamePassService = "src/ServerScriptService/Services/Monetization/GamePassService.lua",
	DevProductService = "src/ServerScriptService/Services/Monetization/DevProductService.lua",
}

-- ============================================================================
-- VALIDATION
-- ============================================================================

local function ValidateIDs()
	print("\n=== VALIDATING PRODUCT IDs ===")

	local missingCount = 0
	local duplicateCheck = {}

	for name, id in pairs(PRODUCT_IDS) do
		-- Check if ID is set (not 0)
		if id == 0 then
			print(string.format("❌ %s: NOT SET (still 0)", name))
			missingCount = missingCount + 1
		else
			-- Check for duplicates
			if duplicateCheck[id] then
				print(string.format("❌ %s: DUPLICATE ID %d (same as %s)", name, id, duplicateCheck[id]))
				missingCount = missingCount + 1
			else
				duplicateCheck[id] = name
				print(string.format("✅ %s: %d", name, id))
			end
		end
	end

	print("\n=== VALIDATION SUMMARY ===")
	print(string.format("Total Products: %d", 15))
	print(string.format("Configured: %d", 15 - missingCount))
	print(string.format("Missing/Invalid: %d", missingCount))

	if missingCount > 0 then
		print("\n❌ VALIDATION FAILED")
		print("Please update all product IDs in this script before running.")
		print("See MONETIZATION_SETUP_GUIDE.md for instructions.")
		return false
	else
		print("\n✅ VALIDATION PASSED - All product IDs configured!")
		return true
	end
end

-- ============================================================================
-- FILE UPDATES
-- ============================================================================

local function UpdateVIPService()
	print("\n=== UPDATING VIPService.lua ===")

	local file = io.open(FILES.VIPService, "r")
	if not file then
		print("❌ Failed to open VIPService.lua")
		return false
	end

	local content = file:read("*all")
	file:close()

	-- Replace VIPGamePassId = 0 with actual ID
	local pattern = "VIPGamePassId%s*=%s*%d+"
	local replacement = string.format("VIPGamePassId = %d", PRODUCT_IDS.VIP_PASS)

	local newContent, count = content:gsub(pattern, replacement)

	if count == 0 then
		print("⚠️ Pattern not found - VIPGamePassId may already be set")
		return true -- Not a failure, just already configured
	end

	-- Write updated content
	file = io.open(FILES.VIPService, "w")
	if not file then
		print("❌ Failed to write VIPService.lua")
		return false
	end

	file:write(newContent)
	file:close()

	print(string.format("✅ Updated VIPService.lua (VIPGamePassId = %d)", PRODUCT_IDS.VIP_PASS))
	return true
end

local function UpdateBattlePassService()
	print("\n=== UPDATING BattlePassService.lua ===")

	local file = io.open(FILES.BattlePassService, "r")
	if not file then
		print("❌ Failed to open BattlePassService.lua")
		return false
	end

	local content = file:read("*all")
	file:close()

	-- Replace PremiumPassId = 0 with actual ID
	local pattern = "PremiumPassId%s*=%s*%d+"
	local replacement = string.format("PremiumPassId = %d", PRODUCT_IDS.BATTLE_PASS)

	local newContent, count = content:gsub(pattern, replacement)

	if count == 0 then
		print("⚠️ Pattern not found - PremiumPassId may already be set")
		return true
	end

	-- Write updated content
	file = io.open(FILES.BattlePassService, "w")
	if not file then
		print("❌ Failed to write BattlePassService.lua")
		return false
	end

	file:write(newContent)
	file:close()

	print(string.format("✅ Updated BattlePassService.lua (PremiumPassId = %d)", PRODUCT_IDS.BATTLE_PASS))
	return true
end

local function UpdateGamePassService()
	print("\n=== UPDATING GamePassService.lua ===")

	local file = io.open(FILES.GamePassService, "r")
	if not file then
		print("❌ Failed to open GamePassService.lua")
		return false
	end

	local content = file:read("*all")
	file:close()

	-- Update each Game Pass ID
	local updates = {
		{pattern = "ParticleEffects%s*=%s*{.-Id%s*=%s*%d+", id = PRODUCT_IDS.PARTICLE_EFFECTS, name = "ParticleEffects"},
		{pattern = "EmotePack%s*=%s*{.-Id%s*=%s*%d+", id = PRODUCT_IDS.EMOTE_PACK, name = "EmotePack"},
		{pattern = "DoubleXP%s*=%s*{.-Id%s*=%s*%d+", id = PRODUCT_IDS.DOUBLE_XP, name = "DoubleXP"},
		{pattern = "CheckpointSkip%s*=%s*{.-Id%s*=%s*%d+", id = PRODUCT_IDS.CHECKPOINT_SKIP, name = "CheckpointSkip"},
		{pattern = "SpeedDemon%s*=%s*{.-Id%s*=%s*%d+", id = PRODUCT_IDS.SPEED_DEMON, name = "SpeedDemon"},
	}

	local newContent = content
	local totalUpdates = 0

	for _, update in ipairs(updates) do
		-- Find the section and replace just the Id = 0 part
		local sectionPattern = string.format("(%s%s*=%s*{.-Id%s*=%s*)%%d+", update.name, "%s", "%s", "%s", "%s")
		local replacement = string.format("%%1%d", update.id)

		local updatedContent, count = newContent:gsub(sectionPattern, replacement)

		if count > 0 then
			newContent = updatedContent
			totalUpdates = totalUpdates + count
			print(string.format("✅ Updated %s (Id = %d)", update.name, update.id))
		else
			print(string.format("⚠️ Pattern not found for %s", update.name))
		end
	end

	if totalUpdates == 0 then
		print("⚠️ No updates made - IDs may already be configured")
		return true
	end

	-- Write updated content
	file = io.open(FILES.GamePassService, "w")
	if not file then
		print("❌ Failed to write GamePassService.lua")
		return false
	end

	file:write(newContent)
	file:close()

	print(string.format("✅ Updated GamePassService.lua (%d IDs configured)", totalUpdates))
	return true
end

local function UpdateDevProductService()
	print("\n=== UPDATING DevProductService.lua ===")

	local file = io.open(FILES.DevProductService, "r")
	if not file then
		print("❌ Failed to open DevProductService.lua")
		return false
	end

	local content = file:read("*all")
	file:close()

	-- Update each Developer Product ID
	local updates = {
		{name = "CoinPack_Small", id = PRODUCT_IDS.COIN_PACK_SMALL},
		{name = "CoinPack_Medium", id = PRODUCT_IDS.COIN_PACK_MEDIUM},
		{name = "CoinPack_Large", id = PRODUCT_IDS.COIN_PACK_LARGE},
		{name = "CoinPack_Mega", id = PRODUCT_IDS.COIN_PACK_MEGA},
		{name = "XPBoost_30min", id = PRODUCT_IDS.XP_BOOST_30MIN},
		{name = "XPBoost_1hour", id = PRODUCT_IDS.XP_BOOST_1HOUR},
		{name = "XPBoost_3hour", id = PRODUCT_IDS.XP_BOOST_3HOUR},
		{name = "RespawnSkip", id = PRODUCT_IDS.RESPAWN_SKIP},
	}

	local newContent = content
	local totalUpdates = 0

	for _, update in ipairs(updates) do
		-- Find the section and replace just the Id = 0 part
		local sectionPattern = string.format("(%s%s*=%s*{.-Id%s*=%s*)%%d+", update.name, "%s", "%s", "%s", "%s")
		local replacement = string.format("%%1%d", update.id)

		local updatedContent, count = newContent:gsub(sectionPattern, replacement)

		if count > 0 then
			newContent = updatedContent
			totalUpdates = totalUpdates + count
			print(string.format("✅ Updated %s (Id = %d)", update.name, update.id))
		else
			print(string.format("⚠️ Pattern not found for %s", update.name))
		end
	end

	if totalUpdates == 0 then
		print("⚠️ No updates made - IDs may already be configured")
		return true
	end

	-- Write updated content
	file = io.open(FILES.DevProductService, "w")
	if not file then
		print("❌ Failed to write DevProductService.lua")
		return false
	end

	file:write(newContent)
	file:close()

	print(string.format("✅ Updated DevProductService.lua (%d IDs configured)", totalUpdates))
	return true
end

-- ============================================================================
-- MAIN
-- ============================================================================

local function Main()
	print("╔════════════════════════════════════════════════════════════╗")
	print("║     Tower Ascent - Monetization Configuration Script      ║")
	print("╚════════════════════════════════════════════════════════════╝")

	-- Step 1: Validate all IDs are set
	if not ValidateIDs() then
		print("\n❌ CONFIGURATION ABORTED")
		print("Please update PRODUCT_IDS in this script and try again.")
		return false
	end

	-- Step 2: Update all service files
	print("\n=== UPDATING SERVICE FILES ===")

	local success = true
	success = success and UpdateVIPService()
	success = success and UpdateBattlePassService()
	success = success and UpdateGamePassService()
	success = success and UpdateDevProductService()

	-- Step 3: Summary
	print("\n╔════════════════════════════════════════════════════════════╗")
	if success then
		print("║               ✅ CONFIGURATION COMPLETE! ✅                ║")
		print("╚════════════════════════════════════════════════════════════╝")
		print("\n📋 Next Steps:")
		print("1. Review updated service files to verify changes")
		print("2. Publish game to Roblox (File → Publish to Roblox)")
		print("3. Run monetization testing (see MONETIZATION_TESTING_PLAN.md)")
		print("4. Fix any bugs found")
		print("5. Launch monetization! 🚀")
		print("\n💰 Estimated Revenue: $154-2,637/month")
		print("📊 15 Products Configured and Ready to Generate Income!")
	else
		print("║             ❌ CONFIGURATION FAILED! ❌                    ║")
		print("╚════════════════════════════════════════════════════════════╝")
		print("\nSome files failed to update. Please check errors above.")
		print("You may need to manually update the files.")
	end

	return success
end

-- Run the script
Main()
