--[[
	PreLaunchValidation.lua
	Comprehensive pre-launch validation script for Tower Ascent

	Validates all critical systems before launch:
	- Service initialization
	- Configuration validity
	- Performance benchmarks
	- Security systems
	- Data integrity

	Run this before deploying to production!
--]]

local PreLaunchValidation = {}

PreLaunchValidation.Results = {
	Passed = {},
	Failed = {},
	Warnings = {},
	Score = 0,
	TotalTests = 0
}

-- ============================================================================
-- VALIDATION HELPERS
-- ============================================================================

local function Pass(testName, message)
	table.insert(PreLaunchValidation.Results.Passed, {
		Test = testName,
		Message = message or "OK"
	})
	PreLaunchValidation.Results.TotalTests += 1
	print(string.format("✅ PASS: %s - %s", testName, message or "OK"))
end

local function Fail(testName, reason)
	table.insert(PreLaunchValidation.Results.Failed, {
		Test = testName,
		Reason = reason
	})
	PreLaunchValidation.Results.TotalTests += 1
	warn(string.format("❌ FAIL: %s - %s", testName, reason))
end

local function Warn(testName, message)
	table.insert(PreLaunchValidation.Results.Warnings, {
		Test = testName,
		Message = message
	})
	warn(string.format("⚠️  WARN: %s - %s", testName, message))
end

-- ============================================================================
-- SERVICE VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateServices()
	print("\n[PreLaunchValidation] === SERVICE VALIDATION ===")

	local requiredServices = {
		"DataService",
		"RoundService",
		"CheckpointService",
		"CoinService",
		"UpgradeService",
		"LeaderboardService",
		"SectionLoader",
		"ThemeService",
		"HazardService",
		"WeatherService",
		"VIPService",
		"BattlePassService",
		"GamePassService",
		"DevProductService"
	}

	for _, serviceName in ipairs(requiredServices) do
		local service = _G.TowerAscent and _G.TowerAscent[serviceName]

		if service then
			if service.IsInitialized == true then
				Pass(serviceName, "Initialized")
			elseif service.IsInitialized == false then
				Fail(serviceName, "Not initialized")
			else
				Warn(serviceName, "No initialization flag")
			end
		else
			Fail(serviceName, "Service not found in _G.TowerAscent")
		end
	end
end

-- ============================================================================
-- CONFIGURATION VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateConfiguration()
	print("\n[PreLaunchValidation] === CONFIGURATION VALIDATION ===")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

	-- Check tower configuration
	if GameConfig.Tower.SectionsPerTower == 50 then
		Pass("Tower.SectionsPerTower", "50 sections configured")
	else
		Fail("Tower.SectionsPerTower", "Expected 50, got " .. GameConfig.Tower.SectionsPerTower)
	end

	-- Check difficulty modes
	local difficultyModes = GameConfig.Tower.DifficultyModes
	if difficultyModes and #difficultyModes >= 4 then
		Pass("Tower.DifficultyModes", #difficultyModes .. " modes available")
	else
		Fail("Tower.DifficultyModes", "Expected 4+ modes")
	end

	-- Check round configuration
	if GameConfig.Round.RoundTime > 0 then
		Pass("Round.RoundTime", GameConfig.Round.RoundTime .. " seconds")
	else
		Fail("Round.RoundTime", "Invalid round time")
	end

	-- Check monetization placeholders
	if GameConfig.Monetization.VIP.ProductId == 0 then
		Warn("VIP.ProductId", "Placeholder ID - needs configuration before monetization testing")
	else
		Pass("VIP.ProductId", "Configured")
	end

	if GameConfig.Monetization.BattlePass.ProductId == 0 then
		Warn("BattlePass.ProductId", "Placeholder ID - needs configuration")
	else
		Pass("BattlePass.ProductId", "Configured")
	end

	-- Check AntiCheat
	if GameConfig.AntiCheat.Enabled then
		Pass("AntiCheat.Enabled", "Protection active")
	else
		Warn("AntiCheat.Enabled", "AntiCheat disabled - enable for production")
	end

	-- Check Debug mode
	if GameConfig.Debug.Enabled == false then
		Pass("Debug.Enabled", "Debug mode OFF (production ready)")
	else
		Warn("Debug.Enabled", "Debug mode ON - disable for production")
	end
end

-- ============================================================================
-- CONTENT VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateContent()
	print("\n[PreLaunchValidation] === CONTENT VALIDATION ===")

	local SectionLoader = _G.TowerAscent and _G.TowerAscent.SectionLoader

	if not SectionLoader then
		Fail("SectionLoader", "Service not available")
		return
	end

	-- Check section count
	local sectionCount = 0
	for _ in pairs(SectionLoader.Sections or {}) do
		sectionCount += 1
	end

	if sectionCount >= 50 then
		Pass("Section Templates", sectionCount .. " sections loaded")
	else
		Fail("Section Templates", "Only " .. sectionCount .. " sections (expected 50+)")
	end

	-- Check section distribution
	local difficulties = {Easy = 0, Medium = 0, Hard = 0, Expert = 0}
	for _, section in pairs(SectionLoader.Sections or {}) do
		local diff = section.Difficulty
		if difficulties[diff] then
			difficulties[diff] += 1
		end
	end

	print(string.format("  Distribution: Easy=%d, Medium=%d, Hard=%d, Expert=%d",
		difficulties.Easy, difficulties.Medium, difficulties.Hard, difficulties.Expert))

	if difficulties.Easy >= 5 and difficulties.Medium >= 10 and
	   difficulties.Hard >= 10 and difficulties.Expert >= 5 then
		Pass("Section Distribution", "Good balance across difficulties")
	else
		Warn("Section Distribution", "Uneven difficulty distribution")
	end
end

-- ============================================================================
-- TOWER VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateTower()
	print("\n[PreLaunchValidation] === TOWER VALIDATION ===")

	local tower = _G.TowerAscent and _G.TowerAscent.Tower

	if not tower or not tower:IsA("Model") then
		Fail("Tower", "Tower not found or invalid")
		return
	end

	Pass("Tower", "Tower model exists")

	-- Check sections
	local sections = tower:FindFirstChild("Sections")
	if sections then
		local sectionCount = #sections:GetChildren()
		if sectionCount == 50 then
			Pass("Tower.Sections", "50 sections in tower")
		else
			Fail("Tower.Sections", "Expected 50, found " .. sectionCount)
		end
	else
		Fail("Tower.Sections", "Sections folder not found")
	end

	-- Check spawn point
	local spawn = tower:FindFirstChild("Spawn")
	if spawn then
		Pass("Tower.Spawn", "Spawn point exists")
	else
		Fail("Tower.Spawn", "No spawn point found")
	end

	-- Check finish line
	local finish = tower:FindFirstChild("Finish")
	if finish then
		Pass("Tower.Finish", "Finish line exists")
	else
		Fail("Tower.Finish", "No finish line found")
	end
end

-- ============================================================================
-- PERFORMANCE VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidatePerformance()
	print("\n[PreLaunchValidation] === PERFORMANCE VALIDATION ===")

	local ServerScriptService = game:GetService("ServerScriptService")

	-- Check script count
	local function countScripts(parent)
		local count = 0
		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
				count += 1
			end
		end
		return count
	end

	local scriptCount = countScripts(ServerScriptService)
	print(string.format("  Total scripts: %d", scriptCount))

	if scriptCount < 100 then
		Pass("Script Count", scriptCount .. " scripts (reasonable)")
	else
		Warn("Script Count", scriptCount .. " scripts (consider optimization)")
	end

	-- Check memory usage
	local memoryUsed = math.floor(gcinfo())
	print(string.format("  Memory usage: %.2f MB", memoryUsed / 1024))

	if memoryUsed < 1024 * 1024 then -- Less than 1GB
		Pass("Memory Usage", string.format("%.2f MB", memoryUsed / 1024))
	else
		Warn("Memory Usage", string.format("%.2f MB (high)", memoryUsed / 1024))
	end

	-- Check player capacity
	local Players = game:GetService("Players")
	if Players.MaxPlayers >= 20 then
		Pass("Player Capacity", Players.MaxPlayers .. " players")
	else
		Warn("Player Capacity", "Only " .. Players.MaxPlayers .. " players (consider increasing)")
	end
end

-- ============================================================================
-- SECURITY VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateSecurity()
	print("\n[PreLaunchValidation] === SECURITY VALIDATION ===")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Check RemoteEvents
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteFolder then
		local remoteCount = #remoteFolder:GetChildren()
		Pass("RemoteEvents", remoteCount .. " remote events configured")

		-- Check for unsecured remotes
		local unsecured = 0
		for _, remote in ipairs(remoteFolder:GetChildren()) do
			if remote:IsA("RemoteEvent") and not remote.OnServerEvent then
				unsecured += 1
			end
		end

		if unsecured > 0 then
			Warn("RemoteEvents", unsecured .. " remotes without server handlers")
		end
	else
		Fail("RemoteEvents", "RemoteEvents folder not found")
	end

	-- Check AntiCheat
	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if AntiCheat then
		Pass("AntiCheat", "AntiCheat system loaded")
	else
		Fail("AntiCheat", "AntiCheat system not found")
	end

	-- Check DataService
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService and DataService.IsInitialized then
		Pass("DataService", "Data persistence ready")
	else
		Fail("DataService", "Data persistence not initialized")
	end
end

-- ============================================================================
-- MONETIZATION VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateMonetization()
	print("\n[PreLaunchValidation] === MONETIZATION VALIDATION ===")

	-- VIP Service
	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if VIPService and VIPService.IsInitialized then
		Pass("VIPService", "Initialized")

		if VIPService.GetCoinMultiplier then
			Pass("VIPService.GetCoinMultiplier", "2x coin multiplier available")
		else
			Warn("VIPService.GetCoinMultiplier", "Method not found")
		end
	else
		Fail("VIPService", "Not initialized")
	end

	-- Battle Pass Service
	local BattlePassService = _G.TowerAscent and _G.TowerAscent.BattlePassService
	if BattlePassService and BattlePassService.IsInitialized then
		Pass("BattlePassService", "Initialized")

		if BattlePassService.AddXP then
			Pass("BattlePassService.AddXP", "XP system available")
		else
			Warn("BattlePassService.AddXP", "Method not found")
		end
	else
		Fail("BattlePassService", "Not initialized")
	end

	-- Game Pass Service
	local GamePassService = _G.TowerAscent and _G.TowerAscent.GamePassService
	if GamePassService and GamePassService.IsInitialized then
		Pass("GamePassService", "Initialized")
	else
		Fail("GamePassService", "Not initialized")
	end

	-- Dev Product Service
	local DevProductService = _G.TowerAscent and _G.TowerAscent.DevProductService
	if DevProductService and DevProductService.IsInitialized then
		Pass("DevProductService", "Initialized")

		-- Check ProcessReceipt
		local MarketplaceService = game:GetService("MarketplaceService")
		if MarketplaceService.ProcessReceipt then
			Pass("DevProductService.ProcessReceipt", "Receipt processor configured")
		else
			Fail("DevProductService.ProcessReceipt", "Not configured")
		end
	else
		Fail("DevProductService", "Not initialized")
	end
end

-- ============================================================================
-- ENVIRONMENTAL SYSTEMS VALIDATION
-- ============================================================================

function PreLaunchValidation.ValidateEnvironmentalSystems()
	print("\n[PreLaunchValidation] === ENVIRONMENTAL SYSTEMS ===")

	-- Theme Service
	local ThemeService = _G.TowerAscent and _G.TowerAscent.ThemeService
	if ThemeService and ThemeService.IsInitialized then
		Pass("ThemeService", "Initialized")
	else
		Fail("ThemeService", "Not initialized")
	end

	-- Hazard Service
	local HazardService = _G.TowerAscent and _G.TowerAscent.HazardService
	if HazardService and HazardService.IsInitialized then
		Pass("HazardService", "Initialized")
	else
		Fail("HazardService", "Not initialized")
	end

	-- Weather Service
	local WeatherService = _G.TowerAscent and _G.TowerAscent.WeatherService
	if WeatherService and WeatherService.IsInitialized then
		Pass("WeatherService", "Initialized")
	else
		Fail("WeatherService", "Not initialized")
	end

	-- Moving Platform Service
	local MovingPlatformService = _G.TowerAscent and _G.TowerAscent.MovingPlatformService
	if MovingPlatformService and MovingPlatformService.IsInitialized then
		Pass("MovingPlatformService", "Initialized")
	else
		Fail("MovingPlatformService", "Not initialized")
	end
end

-- ============================================================================
-- RUN ALL VALIDATIONS
-- ============================================================================

function PreLaunchValidation.RunAll()
	print("\n" .. string.rep("=", 70))
	print("TOWER ASCENT - PRE-LAUNCH VALIDATION")
	print(string.rep("=", 70))

	-- Reset results
	PreLaunchValidation.Results = {
		Passed = {},
		Failed = {},
		Warnings = {},
		Score = 0,
		TotalTests = 0
	}

	-- Run all validation suites
	PreLaunchValidation.ValidateServices()
	PreLaunchValidation.ValidateConfiguration()
	PreLaunchValidation.ValidateContent()
	PreLaunchValidation.ValidateTower()
	PreLaunchValidation.ValidatePerformance()
	PreLaunchValidation.ValidateSecurity()
	PreLaunchValidation.ValidateMonetization()
	PreLaunchValidation.ValidateEnvironmentalSystems()

	-- Calculate score
	local passCount = #PreLaunchValidation.Results.Passed
	local failCount = #PreLaunchValidation.Results.Failed
	local warnCount = #PreLaunchValidation.Results.Warnings
	local totalTests = PreLaunchValidation.Results.TotalTests

	if totalTests > 0 then
		PreLaunchValidation.Results.Score = math.floor((passCount / totalTests) * 100)
	end

	-- Print summary
	print("\n" .. string.rep("=", 70))
	print("VALIDATION SUMMARY")
	print(string.rep("=", 70))
	print(string.format("✅ Passed:   %d", passCount))
	print(string.format("❌ Failed:   %d", failCount))
	print(string.format("⚠️  Warnings: %d", warnCount))
	print(string.format("📊 Score:    %d%% (%d/%d tests passed)",
		PreLaunchValidation.Results.Score, passCount, totalTests))
	print(string.rep("=", 70))

	-- Determine launch readiness
	if failCount == 0 and warnCount == 0 then
		print("🚀 LAUNCH READY: All systems validated successfully!")
	elseif failCount == 0 and warnCount <= 5 then
		print("✅ LAUNCH READY: Minor warnings present, but no critical issues")
	elseif failCount <= 2 then
		warn("⚠️  CAUTION: Some tests failed - review before launch")
	else
		warn("❌ NOT READY: Multiple failures detected - fix before launch")
	end

	print(string.rep("=", 70) .. "\n")

	return PreLaunchValidation.Results
end

-- ============================================================================
-- QUICK CHECK (Faster validation for repeated runs)
-- ============================================================================

function PreLaunchValidation.QuickCheck()
	print("\n[PreLaunchValidation] Running Quick Check...")

	local critical = 0

	-- Check critical services
	local criticalServices = {
		"DataService", "RoundService", "CheckpointService",
		"CoinService", "SectionLoader"
	}

	for _, serviceName in ipairs(criticalServices) do
		local service = _G.TowerAscent and _G.TowerAscent[serviceName]
		if not service or service.IsInitialized ~= true then
			critical += 1
			warn(string.format("❌ Critical service not ready: %s", serviceName))
		end
	end

	-- Check tower
	local tower = _G.TowerAscent and _G.TowerAscent.Tower
	if not tower then
		critical += 1
		warn("❌ Tower not generated")
	end

	-- Check config
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local success, GameConfig = pcall(function()
		return require(ReplicatedStorage.Shared.Config.GameConfig)
	end)

	if not success or not GameConfig then
		critical += 1
		warn("❌ GameConfig not loaded")
	end

	if critical == 0 then
		print("✅ Quick Check: All critical systems operational")
		return true
	else
		warn(string.format("❌ Quick Check: %d critical issues found", critical))
		return false
	end
end

return PreLaunchValidation
