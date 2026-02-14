--[[
	InitBugReporting.lua
	Initializes and integrates the complete bug reporting system

	This script sets up:
	- BugReporter (core system)
	- BugReportService (server handler)
	- BugAnalytics (analysis engine)
	- RuntimeMonitor (monitoring)
	- All integrations

	Place this in ServerScriptService to enable bug reporting.

	Created: 2025-12-02
--]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for game to initialize
task.wait(2)

print("=" .. string.rep("=", 60))
print("INITIALIZING BUG REPORTING SYSTEM")
print(string.rep("=", 60))

-- Ensure _G.TowerAscent exists
_G.TowerAscent = _G.TowerAscent or {}

-- ============================================================================
-- LOAD MODULES
-- ============================================================================

print("[BugReporting] Loading modules...")

-- Load utilities
local Utilities = ServerScriptService:FindFirstChild("Utilities")
if not Utilities then
	warn("[BugReporting] Utilities folder not found!")
	return
end

local success, modules = pcall(function()
	return {
		BugReporter = require(Utilities:WaitForChild("BugReporter", 5)),
		RuntimeMonitor = require(Utilities:WaitForChild("RuntimeMonitor", 5)),
		BugAnalytics = require(Utilities:WaitForChild("BugAnalytics", 5)),
		ErrorRecovery = _G.TowerAscent.ErrorRecovery or require(Utilities:WaitForChild("ErrorRecovery", 5))
	}
end)

if not success then
	warn("[BugReporting] Failed to load modules:", modules)
	return
end

-- Load services
local Services = ServerScriptService:FindFirstChild("Services")
if Services then
	local serviceSuccess, BugReportService = pcall(function()
		return require(Services:WaitForChild("BugReportService", 5))
	end)

	if serviceSuccess then
		modules.BugReportService = BugReportService
	else
		warn("[BugReporting] Failed to load BugReportService:", BugReportService)
	end
end

print("[BugReporting] Modules loaded successfully")

-- ============================================================================
-- REGISTER WITH GLOBAL TABLE
-- ============================================================================

print("[BugReporting] Registering with _G.TowerAscent...")

_G.TowerAscent.BugReporter = modules.BugReporter
_G.TowerAscent.RuntimeMonitor = modules.RuntimeMonitor
_G.TowerAscent.BugAnalytics = modules.BugAnalytics
_G.TowerAscent.ErrorRecovery = modules.ErrorRecovery

-- ============================================================================
-- INITIALIZE SYSTEMS
-- ============================================================================

print("[BugReporting] Initializing systems...")

-- Initialize BugReporter
if modules.BugReporter then
	modules.BugReporter.Initialize()
	modules.BugReporter.Start()
	modules.BugReporter.EnableAutoDetection()
	print("  ✅ BugReporter initialized")
else
	warn("  ❌ BugReporter not available")
end

-- Initialize RuntimeMonitor
if modules.RuntimeMonitor then
	modules.RuntimeMonitor.Initialize()
	modules.RuntimeMonitor.Start()
	print("  ✅ RuntimeMonitor initialized")
else
	warn("  ❌ RuntimeMonitor not available")
end

-- Initialize BugAnalytics
if modules.BugAnalytics then
	modules.BugAnalytics.Start()
	print("  ✅ BugAnalytics initialized")
else
	warn("  ❌ BugAnalytics not available")
end

-- BugReportService initializes itself
if modules.BugReportService then
	print("  ✅ BugReportService initialized")
else
	warn("  ⚠️ BugReportService not available (player reporting disabled)")
end

-- ============================================================================
-- INTEGRATIONS
-- ============================================================================

print("[BugReporting] Setting up integrations...")

-- Integration with ErrorRecovery
if modules.ErrorRecovery and modules.BugReporter then
	-- Hook into error recovery
	local originalRecoverData = modules.ErrorRecovery.RecoverPlayerData
	modules.ErrorRecovery.RecoverPlayerData = function(player)
		-- Report the recovery attempt
		modules.BugReporter.ReportBug("DATA",
			"Player data recovery attempted",
			{Player = player.Name, UserId = player.UserId},
			player)

		-- Call original
		return originalRecoverData(player)
	end
	print("  ✅ ErrorRecovery integration complete")
end

-- Integration with DataService
local DataService = _G.TowerAscent.DataService
if DataService and modules.BugReporter then
	-- Hook into data errors
	if DataService.OnError then
		local originalOnError = DataService.OnError
		DataService.OnError = function(player, error)
			modules.BugReporter.ReportBug("DATA",
				"DataService error",
				{Error = error, Player = player and player.Name},
				player)
			originalOnError(player, error)
		end
	end
	print("  ✅ DataService integration complete")
end

-- Integration with RoundService
local RoundService = _G.TowerAscent.RoundService
if RoundService and modules.BugReporter then
	-- Monitor tower generation failures
	if RoundService.GenerateNewTower then
		local originalGenerate = RoundService.GenerateNewTower
		RoundService.GenerateNewTower = function(...)
			local success, result = pcall(originalGenerate, ...)
			if not success then
				modules.BugReporter.ReportBug("GAMEPLAY",
					"Tower generation failed",
					{Error = result})
			end
			return success and result
		end
	end
	print("  ✅ RoundService integration complete")
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

print("[BugReporting] Registering admin commands...")

local AdminCommands = _G.TowerAscent.AdminCommands
if AdminCommands then
	-- Register all bug-related commands
	if modules.BugReporter then
		modules.BugReporter.RegisterAdminCommands()
	end

	if modules.RuntimeMonitor then
		modules.RuntimeMonitor.RegisterAdminCommands()
	end

	if modules.BugReportService and modules.BugReportService.RegisterAdminCommands then
		modules.BugReportService.RegisterAdminCommands()
	end

	print("  ✅ Admin commands registered")
else
	warn("  ⚠️ AdminCommands not available")
end

-- ============================================================================
-- HEALTH CHECK
-- ============================================================================

task.wait(1)

print("\n[BugReporting] Running health check...")

local healthCheck = {
	BugReporter = modules.BugReporter and modules.BugReporter.Enabled,
	RuntimeMonitor = modules.RuntimeMonitor and modules.RuntimeMonitor.Enabled,
	BugAnalytics = modules.BugAnalytics and modules.BugAnalytics.Enabled,
	AutoDetection = modules.BugReporter and modules.BugReporter.AutoDetection
}

local allHealthy = true
for system, status in pairs(healthCheck) do
	if status then
		print(string.format("  ✅ %s: ACTIVE", system))
	else
		print(string.format("  ❌ %s: INACTIVE", system))
		allHealthy = false
	end
end

-- ============================================================================
-- FINAL STATUS
-- ============================================================================

print("\n" .. string.rep("=", 60))

if allHealthy then
	print("🎉 BUG REPORTING SYSTEM FULLY OPERATIONAL")
	print("Players can press F9 to report bugs")
	print("Automated detection is active")
	print("Analytics engine is running")
else
	print("⚠️ BUG REPORTING SYSTEM PARTIALLY OPERATIONAL")
	print("Some features may not be available")
end

print(string.rep("=", 60) .. "\n")

-- ============================================================================
-- STARTUP REPORT
-- ============================================================================

-- Generate initial report after 5 seconds
task.wait(5)

if modules.BugAnalytics then
	local dashboard = modules.BugAnalytics.GenerateDashboard()
	print("\n[BugReporting] Initial Analytics:")
	print(string.format("  Health Score: %.0f/100", dashboard.Summary.HealthScore))
	print(string.format("  Total Bugs: %d", dashboard.Summary.TotalBugs))
	print(string.format("  Critical Bugs: %d", dashboard.Summary.CriticalBugs))
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return {
	BugReporter = modules.BugReporter,
	RuntimeMonitor = modules.RuntimeMonitor,
	BugAnalytics = modules.BugAnalytics,
	BugReportService = modules.BugReportService,
	Initialized = allHealthy
}