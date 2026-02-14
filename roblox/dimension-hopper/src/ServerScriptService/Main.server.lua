--[[
	Main.server.lua
	Bootstrap script for Dimension Hopper

	Initializes all server services in the correct order
	Handles global error recovery and monitoring
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("========================================")
print("  DIMENSION HOPPER - Server Starting")
print("========================================")

-- ============================================================================
-- SERVICE LOADING
-- ============================================================================

local Services = ServerScriptService:WaitForChild("Services")

-- Load services in dependency order
local serviceModules = {
	-- Core Services (load first)
	{ name = "DataService", path = Services:FindFirstChild("DataService") },
	{ name = "SoundService", path = Services:FindFirstChild("SoundService") },
	{ name = "RewardsService", path = Services:FindFirstChild("RewardsService") },

	-- Dimension Services
	{ name = "DimensionService", path = Services:FindFirstChild("DimensionService") },

	-- Dimension-Specific Mechanics
	{ name = "GravityService", path = Services:FindFirstChild("GravityService") },
	{ name = "ScaleService", path = Services:FindFirstChild("ScaleService") },
	{ name = "VoidService", path = Services:FindFirstChild("VoidService") },
	{ name = "GliderService", path = Services:FindFirstChild("GliderService") },

	-- Game Flow
	{ name = "RaceService", path = Services:FindFirstChild("RaceService") },
	{ name = "CheckpointService", path = Services:FindFirstChild("CheckpointService") },
	{ name = "SpectatorService", path = Services:FindFirstChild("SpectatorService") },

	-- Progression & Social
	{ name = "LeaderboardService", path = Services:FindFirstChild("LeaderboardService") },
	{ name = "DimensionPassService", path = Services:FindFirstChild("DimensionPassService") },
	{ name = "CosmeticsService", path = Services:FindFirstChild("CosmeticsService") },
	{ name = "DailyChallengeService", path = Services:FindFirstChild("DailyChallengeService") },
	{ name = "AchievementService", path = Services:FindFirstChild("AchievementService") },
	{ name = "TutorialService", path = Services:FindFirstChild("TutorialService") },
	{ name = "StatsService", path = Services:FindFirstChild("StatsService") },
	{ name = "GhostService", path = Services:FindFirstChild("GhostService") },
	{ name = "NotificationService", path = Services:FindFirstChild("NotificationService") },
	{ name = "PartyService", path = Services:FindFirstChild("PartyService") },
	{ name = "EmoteService", path = Services:FindFirstChild("EmoteService") },
	{ name = "MatchmakingService", path = Services:FindFirstChild("MatchmakingService") },
	{ name = "TrailsService", path = Services:FindFirstChild("TrailsService") },

	-- Monetization (optional)
	{ name = "MonetizationService", path = Services:FindFirstChild("MonetizationService") },
}

-- Store loaded services
local LoadedServices = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function SafeRequire(moduleScript: ModuleScript): any?
	local success, result = pcall(require, moduleScript)
	if success then
		return result
	else
		warn(string.format("[Main] Failed to require %s: %s", moduleScript.Name, tostring(result)))
		return nil
	end
end

local function SafeInit(service: any, serviceName: string): boolean
	if not service then return false end
	if not service.Init then
		-- Service doesn't need initialization
		return true
	end

	local success, err = pcall(function()
		service.Init()
	end)

	if success then
		print(string.format("[Main] %s initialized", serviceName))
		return true
	else
		warn(string.format("[Main] %s failed to initialize: %s", serviceName, tostring(err)))
		return false
	end
end

local function LoadServices()
	print("[Main] Loading services...")

	local loadedCount = 0
	local failedCount = 0

	for _, serviceInfo in ipairs(serviceModules) do
		if serviceInfo.path then
			local service = SafeRequire(serviceInfo.path)
			if service then
				LoadedServices[serviceInfo.name] = service
				loadedCount = loadedCount + 1
			else
				failedCount = failedCount + 1
			end
		else
			-- Service module doesn't exist yet (optional)
			print(string.format("[Main] %s not found (optional)", serviceInfo.name))
		end
	end

	print(string.format("[Main] Loaded %d services (%d failed)", loadedCount, failedCount))
end

local function InitializeServices()
	print("[Main] Initializing services...")

	local initCount = 0

	for _, serviceInfo in ipairs(serviceModules) do
		local service = LoadedServices[serviceInfo.name]
		if service then
			if SafeInit(service, serviceInfo.name) then
				initCount = initCount + 1
			end
		end
	end

	print(string.format("[Main] Initialized %d services", initCount))
end

-- ============================================================================
-- REMOTE EVENTS SETUP
-- ============================================================================

local function SetupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not remoteFunctions then
		remoteFunctions = Instance.new("Folder")
		remoteFunctions.Name = "RemoteFunctions"
		remoteFunctions.Parent = ReplicatedStorage
	end

	print("[Main] Remote folders created")
end

-- ============================================================================
-- PLAYER HANDLING
-- ============================================================================

local function OnPlayerAdded(player: Player)
	print(string.format("[Main] Player joined: %s", player.Name))

	-- Services handle their own PlayerAdded connections
	-- This is just for logging/global handling
end

local function OnPlayerRemoving(player: Player)
	print(string.format("[Main] Player leaving: %s", player.Name))

	-- Services handle their own cleanup
end

-- ============================================================================
-- ERROR HANDLING
-- ============================================================================

local function SetupErrorHandling()
	-- Global error logging
	game:GetService("ScriptContext").Error:Connect(function(message, stackTrace, script)
		warn(string.format("[ERROR] %s\n%s\nScript: %s",
			message,
			stackTrace or "No stack trace",
			script and script:GetFullName() or "Unknown"
		))

		-- Could send to analytics here
	end)
end

-- ============================================================================
-- SERVICE ACCESS
-- ============================================================================

-- Global service locator for cross-service communication
_G.DimensionHopper = {
	GetService = function(serviceName: string): any?
		return LoadedServices[serviceName]
	end,

	Services = LoadedServices,
}

-- ============================================================================
-- STARTUP
-- ============================================================================

local function Startup()
	local startTime = tick()

	-- Setup error handling first
	SetupErrorHandling()

	-- Create remote folders
	SetupRemoteEvents()

	-- Load and initialize services
	LoadServices()
	InitializeServices()

	-- Setup player connections
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	-- Handle existing players (if any joined during load)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(OnPlayerAdded, player)
	end

	local loadTime = tick() - startTime

	print("========================================")
	print(string.format("  Server ready in %.2fs", loadTime))
	print(string.format("  Services: %d loaded", #LoadedServices))
	print("========================================")
end

-- Run startup
Startup()
