--[[
	Main.server.lua
	Adventure Story Obby - Server initialization

	Initializes all services in the correct dependency order.

	Services are loaded in this order:
	1. Security & Networking (RemoteEventsInit, SecurityManager)
	2. Data Management (DataService)
	3. Core Game Systems (CoinService, StoryService, WorldService)
	4. NPC & Dialogue (NPCService, DialogueService)
	5. Quest & Progression (QuestService, CollectibleService)
	6. Stats & Social (AchievementService, LeaderboardService)
--]]

local ServerScriptService = game:GetService("ServerScriptService")

print("=============================================================")
print("   ADVENTURE STORY OBBY - SERVER INITIALIZATION")
print("=============================================================")

-- ============================================================================
-- PHASE 1: SECURITY & NETWORKING
-- ============================================================================

print("\n[PHASE 1] Initializing Security & Networking...")

-- Initialize RemoteEvents FIRST (all services depend on this)
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

-- Initialize DataService (all other services depend on player data)
local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

print("[PHASE 2] ✅ Data Management initialized")

-- ============================================================================
-- PHASE 3: CORE GAME SYSTEMS
-- ============================================================================

print("\n[PHASE 3] Initializing Core Game Systems...")

-- Initialize CoinService
local CoinService = require(ServerScriptService.Services.CoinService)
CoinService.Init()

-- Initialize StoryService
local StoryService = require(ServerScriptService.Services.StoryService)
StoryService.Init()

-- Initialize WorldService
local WorldService = require(ServerScriptService.Services.WorldService)
WorldService.Init()

print("[PHASE 3] ✅ Core Game Systems initialized")

-- ============================================================================
-- PHASE 4: NPC & DIALOGUE
-- ============================================================================

print("\n[PHASE 4] Initializing NPC & Dialogue Systems...")

-- Initialize DialogueService
local DialogueService = require(ServerScriptService.Services.DialogueService)
DialogueService.Init()

-- Initialize NPCService (must be after DialogueService)
local NPCService = require(ServerScriptService.Services.NPCService)
NPCService.Init()

print("[PHASE 4] ✅ NPC & Dialogue Systems initialized")

-- ============================================================================
-- PHASE 5: QUEST & COLLECTIBLES
-- ============================================================================

print("\n[PHASE 5] Initializing Quest & Collectible Systems...")

-- Initialize QuestService
local QuestService = require(ServerScriptService.Services.QuestService)
QuestService.Init()

-- Initialize CollectibleService
local CollectibleService = require(ServerScriptService.Services.CollectibleService)
CollectibleService.Init()

print("[PHASE 5] ✅ Quest & Collectible Systems initialized")

-- ============================================================================
-- PHASE 6: STATS & SOCIAL
-- ============================================================================

print("\n[PHASE 6] Initializing Stats & Social Systems...")

-- Initialize AchievementService
local AchievementService = require(ServerScriptService.Services.AchievementService)
AchievementService.Init()

-- Initialize LeaderboardService
local LeaderboardService = require(ServerScriptService.Services.LeaderboardService)
LeaderboardService.Init()

-- Initialize SoundService
local SoundService = require(ServerScriptService.Services.SoundService)
SoundService.Init()

print("[PHASE 6] ✅ Stats & Social Systems initialized")

-- ============================================================================
-- INITIALIZATION COMPLETE
-- ============================================================================

print("\n=============================================================")
print("   ✅ ADVENTURE STORY OBBY - SERVER READY")
print("=============================================================\n")

-- ============================================================================
-- PHASE 7: ADMIN UTILITIES (OPTIONAL)
-- ============================================================================

print("\n[PHASE 7] Initializing Admin Utilities...")

-- Initialize AdminCommands (optional, for development)
local AdminCommands = require(ServerScriptService.Utilities.AdminCommands)
AdminCommands.Init()

-- Initialize PerformanceMonitor (optional, for production monitoring)
local PerformanceMonitor = require(ServerScriptService.Utilities.PerformanceMonitor)
PerformanceMonitor.Init()

print("[PHASE 7] ✅ Admin Utilities initialized")

-- ============================================================================
-- GLOBAL ACCESS (DEBUGGING)
-- ============================================================================

-- Store services in global for debugging (optional)
_G.AdventureStoryObby = {
	DataService = DataService,
	SecurityManager = SecurityManager,
	RemoteEventsInit = RemoteEventsInit,
	CoinService = CoinService,
	StoryService = StoryService,
	WorldService = WorldService,
	DialogueService = DialogueService,
	NPCService = NPCService,
	QuestService = QuestService,
	CollectibleService = CollectibleService,
	AchievementService = AchievementService,
	LeaderboardService = LeaderboardService,
	SoundService = SoundService,
	AdminCommands = AdminCommands,
	PerformanceMonitor = PerformanceMonitor,
	NotificationService = require(ServerScriptService.Utilities.NotificationService),
}

print("[Main] All services accessible via _G.AdventureStoryObby")
