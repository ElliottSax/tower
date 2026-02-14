--[[
	Main.server.lua
	Pet Collector Simulator - Server Initialization

	Initializes all services in correct order for monetization-focused game.

	Services:
	1. Security & Networking
	2. Data Management
	3. Core Gameplay (Pets, Coins)
	4. Monetization (Game Passes, Dev Products)
	5. Progression (Worlds, Quests)
--]]

local ServerScriptService = game:GetService("ServerScriptService")

print("============================================================")
print("   PET COLLECTOR SIMULATOR - SERVER INITIALIZATION")
print("============================================================")

-- ============================================================================
-- PHASE 1: SECURITY & NETWORKING
-- ============================================================================

print("\n[PHASE 1] Initializing Security & Networking...")

-- Initialize RemoteEvents FIRST
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Initialize()

-- Initialize Security Manager
local SecurityManager = require(ServerScriptService.Security.SecurityManager)
SecurityManager.Init()

print("[PHASE 1] ✅ Security & Networking initialized")

-- ============================================================================
-- PHASE 2: DATA MANAGEMENT
-- ============================================================================

print("\n[PHASE 2] Initializing Data Management...")

-- Initialize DataService (all other services depend on this)
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

print("[PHASE 2] ✅ Data Management initialized")

-- ============================================================================
-- PHASE 3: CORE GAMEPLAY
-- ============================================================================

print("\n[PHASE 3] Initializing Core Gameplay Systems...")

-- Initialize CoinService
local CoinService = require(ServerScriptService.Services.CoinService)
CoinService.Init()

-- Initialize PetService (core gameplay loop)
local PetService = require(ServerScriptService.Services.PetService)
PetService.Init()

print("[PHASE 3] ✅ Core Gameplay Systems initialized")

-- ============================================================================
-- PHASE 4: MONETIZATION (KEY REVENUE SYSTEMS)
-- ============================================================================

print("\n[PHASE 4] Initializing Monetization Systems...")

-- Initialize MonetizationService (game passes & dev products)
local MonetizationService = require(ServerScriptService.Services.MonetizationService)
MonetizationService.Init()

print("[PHASE 4] ✅ Monetization Systems initialized")

-- ============================================================================
-- PHASE 5: PROGRESSION
-- ============================================================================

print("\n[PHASE 5] Initializing Progression Systems...")

-- Initialize WorldService (world unlocking)
local WorldService = require(ServerScriptService.Services.WorldService)
WorldService.Init()

print("[PHASE 5] ✅ Progression Systems initialized")

-- ============================================================================
-- INITIALIZATION COMPLETE
-- ============================================================================

print("\n============================================================")
print("   ✅ PET COLLECTOR SIMULATOR - SERVER READY")
print("   💰 MONETIZATION SYSTEMS ACTIVE")
print("============================================================\n")

-- ============================================================================
-- GLOBAL ACCESS (DEBUGGING)
-- ============================================================================

_G.PetCollectorSim = {
	DataService = DataService,
	SecurityManager = SecurityManager,
	RemoteEventsInit = RemoteEventsInit,
	CoinService = CoinService,
	PetService = PetService,
	MonetizationService = MonetizationService,
	WorldService = WorldService,
}

print("[Main] All services accessible via _G.PetCollectorSim")

-- ============================================================================
-- REVENUE TRACKING
-- ============================================================================

-- Log when players join (track DAU for revenue analysis)
game.Players.PlayerAdded:Connect(function(player)
	print(string.format("[Main] Player joined: %s (UserId: %d) - DAU++", player.Name, player.UserId))
end)
