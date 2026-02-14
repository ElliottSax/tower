--[[
	PerformanceMonitor.lua
	Monitors server performance and logs statistics

	Features:
	- Memory usage tracking
	- Player count monitoring
	- Service health checks
	- Automatic alerts for issues
	- Performance logs

	Usage:
	Set ENABLED = true to activate monitoring
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Stats = game:GetService("Stats")

local PerformanceMonitor = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local ENABLED = false -- Set to true to enable monitoring
local LOG_INTERVAL = 30 -- Log stats every 30 seconds
local ALERT_MEMORY_THRESHOLD = 3000 -- MB - Alert if memory exceeds this
local ALERT_HEARTBEAT_THRESHOLD = 50 -- ms - Alert if heartbeat exceeds this

-- ============================================================================
-- TRACKING
-- ============================================================================

local startTime = os.time()
local lastLogTime = 0
local performanceLogs = {}

-- Stats tracking
local peakMemory = 0
local peakPlayers = 0
local peakHeartbeat = 0
local totalDatastoreErrors = 0

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PerformanceMonitor.Init()
	if not ENABLED then
		print("[PerformanceMonitor] Disabled (set ENABLED = true to activate)")
		return
	end

	print("[PerformanceMonitor] Initializing...")

	-- Start monitoring loop
	PerformanceMonitor.StartMonitoring()

	-- Log on shutdown
	game:BindToClose(function()
		PerformanceMonitor.LogShutdown()
	end)

	print("[PerformanceMonitor] Initialized")
end

-- ============================================================================
-- MONITORING
-- ============================================================================

function PerformanceMonitor.StartMonitoring()
	task.spawn(function()
		while true do
			local currentTime = os.time()

			if currentTime - lastLogTime >= LOG_INTERVAL then
				PerformanceMonitor.LogStats()
				lastLogTime = currentTime
			end

			task.wait(5) -- Check every 5 seconds
		end
	end)
end

function PerformanceMonitor.LogStats()
	local uptime = os.time() - startTime
	local playerCount = #Players:GetPlayers()
	local memoryUsage = Stats:GetTotalMemoryUsageMb()
	local heartbeat = RunService.Heartbeat:Wait() * 1000 -- ms

	-- Update peaks
	if memoryUsage > peakMemory then
		peakMemory = memoryUsage
	end

	if playerCount > peakPlayers then
		peakPlayers = playerCount
	end

	if heartbeat > peakHeartbeat then
		peakHeartbeat = heartbeat
	end

	-- Create log entry
	local logEntry = {
		Timestamp = os.time(),
		Uptime = uptime,
		Players = playerCount,
		Memory = memoryUsage,
		Heartbeat = heartbeat,
	}

	table.insert(performanceLogs, logEntry)

	-- Keep only last 100 logs
	if #performanceLogs > 100 then
		table.remove(performanceLogs, 1)
	end

	-- Print summary
	print(string.format(
		"[Performance] Uptime: %ds | Players: %d | Memory: %.2f MB | Heartbeat: %.2f ms",
		uptime,
		playerCount,
		memoryUsage,
		heartbeat
	))

	-- Check for alerts
	PerformanceMonitor.CheckAlerts(memoryUsage, heartbeat)

	-- Check service health
	PerformanceMonitor.CheckServiceHealth()
end

-- ============================================================================
-- ALERTS
-- ============================================================================

function PerformanceMonitor.CheckAlerts(memoryUsage: number, heartbeat: number)
	-- Memory alert
	if memoryUsage > ALERT_MEMORY_THRESHOLD then
		warn(string.format(
			"[PerformanceMonitor] ⚠️ HIGH MEMORY USAGE: %.2f MB (threshold: %d MB)",
			memoryUsage,
			ALERT_MEMORY_THRESHOLD
		))
	end

	-- Heartbeat alert (lag)
	if heartbeat > ALERT_HEARTBEAT_THRESHOLD then
		warn(string.format(
			"[PerformanceMonitor] ⚠️ HIGH HEARTBEAT: %.2f ms (threshold: %d ms)",
			heartbeat,
			ALERT_HEARTBEAT_THRESHOLD
		))
	end
end

function PerformanceMonitor.CheckServiceHealth()
	-- Check if all services are still accessible
	local services = _G.AdventureStoryObby

	if not services then
		warn("[PerformanceMonitor] ⚠️ _G.AdventureStoryObby not accessible!")
		return
	end

	local criticalServices = {
		"DataService",
		"StoryService",
		"QuestService",
		"WorldService"
	}

	for _, serviceName in ipairs(criticalServices) do
		if not services[serviceName] then
			warn(string.format("[PerformanceMonitor] ⚠️ Service missing: %s", serviceName))
		end
	end
end

-- ============================================================================
-- REPORTING
-- ============================================================================

function PerformanceMonitor.GetReport(): string
	local uptime = os.time() - startTime
	local playerCount = #Players:GetPlayers()
	local memoryUsage = Stats:GetTotalMemoryUsageMb()

	local report = string.format([[
=== PERFORMANCE REPORT ===
Uptime: %d seconds (%.1f hours)
Current Players: %d
Peak Players: %d

Memory:
- Current: %.2f MB
- Peak: %.2f MB
- Threshold: %d MB

Heartbeat:
- Peak: %.2f ms
- Threshold: %d ms

Datastore Errors: %d

Total Logs: %d
]],
		uptime,
		uptime / 3600,
		playerCount,
		peakPlayers,
		memoryUsage,
		peakMemory,
		ALERT_MEMORY_THRESHOLD,
		peakHeartbeat,
		ALERT_HEARTBEAT_THRESHOLD,
		totalDatastoreErrors,
		#performanceLogs
	)

	return report
end

function PerformanceMonitor.PrintReport()
	print(PerformanceMonitor.GetReport())
end

function PerformanceMonitor.LogShutdown()
	print("[PerformanceMonitor] Server shutting down...")
	PerformanceMonitor.PrintReport()
end

-- ============================================================================
-- MANUAL TRACKING
-- ============================================================================

function PerformanceMonitor.IncrementDatastoreError()
	totalDatastoreErrors = totalDatastoreErrors + 1
end

function PerformanceMonitor.GetLogs()
	return performanceLogs
end

function PerformanceMonitor.GetPeakStats()
	return {
		Memory = peakMemory,
		Players = peakPlayers,
		Heartbeat = peakHeartbeat,
	}
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return PerformanceMonitor
