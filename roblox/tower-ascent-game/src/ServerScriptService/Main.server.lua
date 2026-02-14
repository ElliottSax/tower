--[[
	init.server.lua
	Main server bootstrap script

	Loads and initializes all services in correct order.
	This is the entry point for the entire game server.

	Load Order (Critical!):
	1. DataService (must load first - other services depend on it)
	2. Generator + MemoryManager + AntiCheat (core obby systems)
	3. Round management services
	4. Monetization services (Week 12+)

	Week 1: Core services only
	Week 2-5: Add round system, checkpoints
	Week 12+: Add monetization services
--]]

print(string.rep("=", 60))
print("TOWER ASCENT - Server Starting...")
print(string.rep("=", 60))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- LOAD CONFIGURATION
-- ============================================================================

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

print("[Bootstrap] GameConfig loaded")
print(string.format("[Bootstrap] Debug Mode: %s", GameConfig.Debug.Enabled))
print(string.format("[Bootstrap] AntiCheat: %s", GameConfig.AntiCheat.Enabled))

-- ============================================================================
-- LOAD SERVICES
-- ============================================================================

local Services = ServerScriptService.Services

-- Phase 1: Data Service (MUST load first!)
print("\n[Bootstrap] Phase 1: Loading DataService...")
local DataService = require(Services.DataService)
DataService.Init()

-- Phase 2: Core Obby Systems
print("\n[Bootstrap] Phase 2: Loading Core Systems...")

-- Week 6: Load section templates BEFORE generator
local SectionLoader = require(Services.SectionLoader)
SectionLoader.Init()

local Generator = require(Services.ObbyService.Generator)
local MemoryManager = require(Services.ObbyService.MemoryManager)
local AntiCheat = require(Services.ObbyService.AntiCheat)

print("[Bootstrap] SectionLoader loaded")
print("[Bootstrap] Generator loaded")
print("[Bootstrap] MemoryManager loaded")
print("[Bootstrap] AntiCheat loaded")

-- ============================================================================
-- GENERATE INITIAL TOWER
-- ============================================================================

print("\n[Bootstrap] Generating initial tower...")

-- Create generator instance
local generator = Generator.new(os.time(), "Normal")

-- Generate tower
local tower = generator:GenerateTower()

-- Start memory management
local memoryManager = MemoryManager.new(tower)
memoryManager:Start()

-- Start anti-cheat
local antiCheat = AntiCheat.new()
antiCheat:Start()

print(string.format(
	"[Bootstrap] Tower generated: %s (Seed: %d)",
	tower.Name,
	tower:GetAttribute("Seed")
))

-- ============================================================================
-- WEEK 2-5: ROUND SYSTEM
-- ============================================================================

print("\n[Bootstrap] Phase 3: Loading Round System...")

local RoundService = require(Services.RoundService)
local CheckpointService = require(Services.CheckpointService)
local CoinService = require(Services.CoinService)
local UpgradeService = require(Services.UpgradeService)

-- Initialize in correct order
CheckpointService.Init()
CoinService.Init()
UpgradeService.Init()
RoundService.Init() -- Last - starts the round loop

print("[Bootstrap] Round system loaded")
print("[Bootstrap] Round time: " .. GameConfig.Round.RoundTime .. " seconds")
print("[Bootstrap] Intermission: " .. GameConfig.Round.IntermissionTime .. " seconds")

-- ============================================================================
-- WEEK 3: POLISH & LEADERBOARDS
-- ============================================================================

print("\n[Bootstrap] Phase 4: Loading Polish Systems...")

local LeaderboardService = require(Services.LeaderboardService)
local StatisticsService = require(Services.StatisticsService)
local ParticleService = require(Services.ParticleService)
local SoundService = require(Services.SoundService)

StatisticsService.Init()
ParticleService.Init()
SoundService.Init()
LeaderboardService.Init() -- Last - syncs player data to leaderboards

print("[Bootstrap] Polish systems loaded")

-- ============================================================================
-- WEEK 7: MOVING PLATFORMS
-- ============================================================================

print("\n[Bootstrap] Phase 5: Loading Moving Platforms...")

local MovingPlatformService = require(Services.MovingPlatformService)
MovingPlatformService.Init(tower) -- Pass tower to detect moving platforms

print("[Bootstrap] Moving platforms loaded")

-- ============================================================================
-- WEEK 8: ENVIRONMENTAL THEMES
-- ============================================================================

print("\n[Bootstrap] Phase 6: Loading Environmental Themes...")

local ThemeService = require(Services.ThemeService)
ThemeService.Init(tower) -- Apply themes to tower

print("[Bootstrap] Environmental themes loaded")

-- ============================================================================
-- WEEK 9: ENVIRONMENTAL HAZARDS
-- ============================================================================

print("\n[Bootstrap] Phase 7: Loading Environmental Hazards...")

local HazardService = require(Services.HazardService)
HazardService.Init(tower) -- Initialize hazards in tower

print("[Bootstrap] Environmental hazards loaded")

-- ============================================================================
-- WEEK 10: DYNAMIC WEATHER
-- ============================================================================

print("\n[Bootstrap] Phase 8: Loading Dynamic Weather...")

local WeatherService = require(Services.WeatherService)
WeatherService.Init() -- Initialize weather system

print("[Bootstrap] Dynamic weather loaded")

-- ============================================================================
-- WEEK 12: MONETIZATION
-- ============================================================================

print("\n[Bootstrap] Phase 9: Loading Monetization Systems...")

local VIPService = require(Services.Monetization.VIPService)
VIPService.Init() -- Initialize VIP membership system

print("[Bootstrap] VIPService loaded")

-- ============================================================================
-- WEEK 13: BATTLE PASS
-- ============================================================================

print("\n[Bootstrap] Phase 10: Loading Battle Pass...")

local BattlePassService = require(Services.Monetization.BattlePassService)
BattlePassService.Init() -- Initialize seasonal battle pass

print("[Bootstrap] BattlePassService loaded")

-- ============================================================================
-- WEEK 14: ADDITIONAL MONETIZATION
-- ============================================================================

print("\n[Bootstrap] Phase 11: Loading Additional Monetization...")

local GamePassService = require(Services.Monetization.GamePassService)
GamePassService.Init() -- Initialize game passes (cosmetic packs)

local DevProductService = require(Services.Monetization.DevProductService)
DevProductService.Init() -- Initialize developer products (coin packs)

print("[Bootstrap] GamePassService loaded")
print("[Bootstrap] DevProductService loaded")
print("[Bootstrap] All monetization systems loaded")

-- ============================================================================
-- STARTUP COMPLETE
-- ============================================================================

print("\n" .. string.rep("=", 60))
print("TOWER ASCENT - Server Ready!")
print(string.rep("=", 60))
print(string.format("Tower: %s", tower.Name))
print(string.format("Sections: %d", GameConfig.Tower.SectionsPerTower))
print(string.format("Round Time: %d seconds", GameConfig.Round.RoundTime))
print(string.format("Difficulty: %s", generator.DifficultyMode))
print(string.rep("=", 60))

-- ============================================================================
-- DEBUG UTILITIES (Development/Testing Only)
-- ============================================================================

-- Only load debug utilities in debug mode to save memory in production
local DebugUtilities, ValidationTests, AdminCommands, EdgeCaseTests
local StressTests, ChaosMonkey, ErrorRecovery, DebugProfiler
local ProductionReadiness, PreDeploymentChecklist, PreLaunchValidation, SecurityAudit

if GameConfig.Debug.Enabled then
	DebugUtilities = require(ServerScriptService.Utilities.DebugUtilities)
	ValidationTests = require(ServerScriptService.Utilities.ValidationTests)
	AdminCommands = require(ServerScriptService.Utilities.AdminCommands)
	EdgeCaseTests = require(ServerScriptService.Utilities.EdgeCaseTests)
	StressTests = require(ServerScriptService.Utilities.StressTests)
	ChaosMonkey = require(ServerScriptService.Utilities.ChaosMonkey)
	ErrorRecovery = require(ServerScriptService.Utilities.ErrorRecovery)
	DebugProfiler = require(ServerScriptService.Utilities.DebugProfiler)
	ProductionReadiness = require(ServerScriptService.Utilities.ProductionReadiness)
	PreDeploymentChecklist = require(ServerScriptService.Utilities.PreDeploymentChecklist)
	PreLaunchValidation = require(ServerScriptService.Utilities.PreLaunchValidation)
	SecurityAudit = require(ServerScriptService.Utilities.SecurityAudit)

	-- Run automated tests if enabled
	if GameConfig.Debug.RunTests then
		print("\n[Bootstrap] Running automated tests...")

		task.spawn(function()
			-- Test all section templates
			DebugUtilities.TestAllSections()

			-- Validate tower
			DebugUtilities.ValidateTower(tower)

			-- Test moving platforms
			DebugUtilities.TestMovingPlatforms(tower)

			-- Test themes
			DebugUtilities.TestThemes(tower)

			-- Generate full report
			DebugUtilities.GenerateFullReport(tower)

			-- Run validation tests for code review fixes
			print("\n[Bootstrap] Running validation tests for code review fixes...")
			ValidationTests.RunAll()
		end)
	end

	-- Store references globally ONLY in debug mode for admin commands
	-- SECURITY: Never expose in production - exploiters can access _G
	_G.TowerAscent = {
		-- Week 1 services
		Generator = generator,
		MemoryManager = memoryManager,
		AntiCheat = antiCheat,
		DataService = DataService,
		Tower = tower,
		Config = GameConfig,

		-- Week 2 services
		RoundService = RoundService,
		CheckpointService = CheckpointService,
		CoinService = CoinService,
		UpgradeService = UpgradeService,

		-- Week 3 services
		LeaderboardService = LeaderboardService,
		StatisticsService = StatisticsService,
		ParticleService = ParticleService,
		SoundService = SoundService,

		-- Week 6 services
		SectionLoader = SectionLoader,

		-- Week 7 services
		MovingPlatformService = MovingPlatformService,

		-- Week 8 services
		ThemeService = ThemeService,

		-- Week 9 services
		HazardService = HazardService,

		-- Week 10 services
		WeatherService = WeatherService,

		-- Week 12 services
		VIPService = VIPService,

		-- Week 13 services
		BattlePassService = BattlePassService,

		-- Week 14 services
		GamePassService = GamePassService,
		DevProductService = DevProductService,

		-- Debug utilities
		DebugUtilities = DebugUtilities,
		ValidationTests = ValidationTests,
		AdminCommands = AdminCommands,
		EdgeCaseTests = EdgeCaseTests,
		StressTests = StressTests,
		ChaosMonkey = ChaosMonkey,
		ErrorRecovery = ErrorRecovery,
		DebugProfiler = DebugProfiler,
		ProductionReadiness = ProductionReadiness,
		PreDeploymentChecklist = PreDeploymentChecklist,
		PreLaunchValidation = PreLaunchValidation,
		SecurityAudit = SecurityAudit,
	}
else
	-- Production mode - load only essential utilities for safety checks
	PreDeploymentChecklist = require(ServerScriptService.Utilities.PreDeploymentChecklist)
end

-- ============================================================================
-- PRODUCTION SAFETY CHECK
-- ============================================================================

if not GameConfig.Debug.Enabled then
	-- Production mode - run safety checks
	print("\n[Bootstrap] Production mode detected - running safety checks...")

	local quickCheck = PreDeploymentChecklist.QuickCheck()

	if not quickCheck then
		warn("[Bootstrap] ⚠️  PRODUCTION SAFETY CHECK FAILED")
		warn("[Bootstrap] Run _G.TowerAscent.PreDeploymentChecklist.Validate() for details")
	else
		print("[Bootstrap] ✅ Production safety checks passed")
	end
else
	-- Debug mode - show available utilities
	print("\n[Bootstrap] Debug mode enabled - Testing utilities available")
	print("[Bootstrap] Access via _G.TowerAscent")
	print("[Bootstrap]")
	print("[Bootstrap] Admin Commands:")
	print("[Bootstrap]   _G.TowerAscent.AdminCommands.Help()")
	print("[Bootstrap]")
	print("[Bootstrap] Testing Suites:")
	print("[Bootstrap]   _G.TowerAscent.ValidationTests.RunAll()")
	print("[Bootstrap]   _G.TowerAscent.EdgeCaseTests.RunAll()")
	print("[Bootstrap]   _G.TowerAscent.StressTests.RunAll()")
	print("[Bootstrap]")
	print("[Bootstrap] Advanced Utilities:")
	print("[Bootstrap]   _G.TowerAscent.ChaosMonkey.EnableChaos(60)")
	print("[Bootstrap]   _G.TowerAscent.ErrorRecovery.PrintErrorReport()")
	print("[Bootstrap]   _G.TowerAscent.DebugProfiler.Start()")
	print("[Bootstrap]")
	print("[Bootstrap] Production Readiness:")
	print("[Bootstrap]   _G.TowerAscent.ProductionReadiness.RunFullValidation()")
	print("[Bootstrap]   _G.TowerAscent.PreDeploymentChecklist.Validate()")
	print("[Bootstrap]")
	print("[Bootstrap] Pre-Launch Validation:")
	print("[Bootstrap]   _G.TowerAscent.PreLaunchValidation.RunAll()")
	print("[Bootstrap]   _G.TowerAscent.PreLaunchValidation.QuickCheck()")
	print("[Bootstrap]   _G.TowerAscent.SecurityAudit.RunAll()")
end
