--[[
	MonetizationValidator.lua

	Validates that all monetization products are configured correctly
	Run before launch to ensure no placeholder IDs remain

	Usage in Studio Command Bar:
	require(game.ServerScriptService.Utilities.MonetizationValidator).ValidateAll()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationValidator = {}

function MonetizationValidator.ValidateAll()
	print(string.rep("=", 60))
	print("MONETIZATION CONFIGURATION VALIDATION")
	print(string.rep("=", 60))

	local allValid = true
	local warnings = {}
	local errors = {}

	-- Check GameConfig exists
	if not GameConfig.Monetization then
		table.insert(errors, "❌ GameConfig.Monetization not found")
		print("\n" .. table.concat(errors, "\n"))
		return false
	end

	-- Validate Game Passes
	print("\n📦 Validating Game Passes...")

	local gamePasses = GameConfig.Monetization.GamePasses or {}
	local gamePassNames = {"VIP", "SpeedBoost", "DoubleJump", "AirDash"}

	for _, name in ipairs(gamePassNames) do
		local id = gamePasses[name]

		if not id then
			table.insert(errors, string.format("❌ Game Pass '%s' not defined", name))
			allValid = false
		elseif id == 0 then
			table.insert(errors, string.format("❌ Game Pass '%s' has placeholder ID (0)", name))
			allValid = false
		elseif type(id) ~= "number" then
			table.insert(errors, string.format("❌ Game Pass '%s' has invalid ID type: %s", name, type(id)))
			allValid = false
		else
			print(string.format("  ✅ %s: %d", name, id))
		end
	end

	-- Validate Developer Products
	print("\n💰 Validating Developer Products...")

	local devProducts = GameConfig.Monetization.DeveloperProducts or {}
	local productNames = {"Coins1000", "Coins5000", "Coins10000"}

	for _, name in ipairs(productNames) do
		local id = devProducts[name]

		if not id then
			table.insert(errors, string.format("❌ Dev Product '%s' not defined", name))
			allValid = false
		elseif id == 0 then
			table.insert(errors, string.format("❌ Dev Product '%s' has placeholder ID (0)", name))
			allValid = false
		elseif type(id) ~= "number" then
			table.insert(errors, string.format("❌ Dev Product '%s' has invalid ID type: %s", name, type(id)))
			allValid = false
		else
			print(string.format("  ✅ %s: %d", name, id))
		end
	end

	-- Check VIPService configuration
	print("\n👑 Validating VIPService...")

	local VIPService = require(game.ServerScriptService.Services.Monetization.VIPService)
	-- VIPService stores config internally, we'll check if it's accessible

	print("  ℹ️  VIPService loaded successfully")

	-- Summary
	print(string.rep("=", 60))

	if #errors > 0 then
		print("\n🔴 ERRORS FOUND:")
		for _, err in ipairs(errors) do
			print(err)
		end
	end

	if #warnings > 0 then
		print("\n⚠️  WARNINGS:")
		for _, warn in ipairs(warnings) do
			print(warn)
		end
	end

	print("\n" .. string.rep("=", 60))

	if allValid then
		print("✅ ALL MONETIZATION PRODUCTS CONFIGURED")
		print("✅ Ready for production launch")
	else
		print("❌ MONETIZATION NOT CONFIGURED")
		print("⚠️  DO NOT LAUNCH - Fix errors above")
		print("\nSee MONETIZATION_SETUP_CHECKLIST.md for instructions")
	end

	print(string.rep("=", 60))

	return allValid
end

-- Auto-validate on require (for easier testing)
if game:GetService("RunService"):IsStudio() then
	task.spawn(function()
		task.wait(2) -- Wait for services to load
		MonetizationValidator.ValidateAll()
	end)
end

return MonetizationValidator
