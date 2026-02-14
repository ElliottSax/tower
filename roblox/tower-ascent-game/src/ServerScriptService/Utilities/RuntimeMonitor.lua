--[[
	RuntimeMonitor.lua
	Production runtime monitoring and debugging utilities

	Features:
	- Real-time error tracking
	- Performance monitoring
	- State dumping
	- Health checks
	- Alert system

	Usage:
	   RuntimeMonitor.Start()
	   RuntimeMonitor.TrackError(context, error)
	   RuntimeMonitor.DumpState()

	Created: 2025-12-02 (Production Debugging)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local RuntimeMonitor = {}
RuntimeMonitor.Enabled = false
RuntimeMonitor.Errors = {}
RuntimeMonitor.Alerts = {}
RuntimeMonitor.HealthChecks = {}
RuntimeMonitor.Connection = nil

-- Configuration
local CONFIG = {
	MaxErrorLog = 500,
	HealthCheckInterval = 60, -- seconds
	AlertThresholds = {
		ErrorsPerMinute = 10,
		MemoryMB = 450,
		FPS = 20,
		PlayerCrashes = 5
	}
}

-- ============================================================================
-- ERROR TRACKING
-- ============================================================================

function RuntimeMonitor.TrackError(context: string, error: any, metadata: {}?)
	local entry = {
		Context = context,
		Error = tostring(error),
		Metadata = metadata or {},
		Timestamp = tick(),
		Traceback = debug.traceback()
	}

	table.insert(RuntimeMonitor.Errors, entry)

	-- Limit error log size
	if #RuntimeMonitor.Errors > CONFIG.MaxErrorLog then
		table.remove(RuntimeMonitor.Errors, 1)
	end

	-- Check for critical patterns
	local errorStr = tostring(error)
	if errorStr:find("DataService") or errorStr:find("ProfileService") then
		RuntimeMonitor.Alert("CRITICAL", "Data service error detected", entry)
	elseif errorStr:find("memory") or errorStr:find("exhausted") then
		RuntimeMonitor.Alert("HIGH", "Memory issue detected", entry)
	end

	warn(string.format("[RuntimeMonitor] %s: %s", context, error))
end

-- ============================================================================
-- ALERT SYSTEM
-- ============================================================================

function RuntimeMonitor.Alert(severity: string, message: string, data: any?)
	local alert = {
		Severity = severity,
		Message = message,
		Data = data,
		Timestamp = tick()
	}

	table.insert(RuntimeMonitor.Alerts, alert)

	-- Log based on severity
	if severity == "CRITICAL" then
		warn(string.format("🚨 [CRITICAL ALERT] %s", message))

		-- Trigger emergency recovery if needed
		if message:find("Data service") then
			local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
			if ErrorRecovery and ErrorRecovery.EnableAutoRecovery then
				ErrorRecovery.EnableAutoRecovery()
			end
		end
	elseif severity == "HIGH" then
		warn(string.format("⚠️ [HIGH ALERT] %s", message))
	else
		print(string.format("ℹ️ [ALERT] %s", message))
	end
end

-- ============================================================================
-- HEALTH CHECKS
-- ============================================================================

function RuntimeMonitor.RunHealthChecks()
	local health = {
		Timestamp = tick(),
		Checks = {}
	}

	-- Memory check
	local memoryUsage = Stats:GetTotalMemoryUsageMb()
	health.Checks.Memory = {
		Value = memoryUsage,
		Status = memoryUsage < CONFIG.AlertThresholds.MemoryMB and "HEALTHY" or "WARNING",
		Message = string.format("Memory: %.1f MB", memoryUsage)
	}

	-- FPS check
	local fps = workspace:GetRealPhysicsFPS()
	health.Checks.FPS = {
		Value = fps,
		Status = fps >= CONFIG.AlertThresholds.FPS and "HEALTHY" or "WARNING",
		Message = string.format("FPS: %d", fps)
	}

	-- Player count
	local playerCount = #Players:GetPlayers()
	health.Checks.Players = {
		Value = playerCount,
		Status = "HEALTHY",
		Message = string.format("Players: %d", playerCount)
	}

	-- Error rate check
	local recentErrors = 0
	local oneMinuteAgo = tick() - 60
	for _, error in ipairs(RuntimeMonitor.Errors) do
		if error.Timestamp > oneMinuteAgo then
			recentErrors = recentErrors + 1
		end
	end

	health.Checks.ErrorRate = {
		Value = recentErrors,
		Status = recentErrors < CONFIG.AlertThresholds.ErrorsPerMinute and "HEALTHY" or "WARNING",
		Message = string.format("Errors/min: %d", recentErrors)
	}

	-- Service availability
	local services = {"DataService", "RoundService", "CheckpointService", "AntiCheat"}
	local servicesAvailable = 0
	for _, serviceName in ipairs(services) do
		if _G.TowerAscent and _G.TowerAscent[serviceName] then
			servicesAvailable = servicesAvailable + 1
		end
	end

	health.Checks.Services = {
		Value = servicesAvailable,
		Status = servicesAvailable == #services and "HEALTHY" or "WARNING",
		Message = string.format("Services: %d/%d", servicesAvailable, #services)
	}

	table.insert(RuntimeMonitor.HealthChecks, health)

	-- Trigger alerts for warnings
	for checkName, check in pairs(health.Checks) do
		if check.Status == "WARNING" then
			RuntimeMonitor.Alert("MEDIUM", string.format("Health check warning: %s", check.Message))
		end
	end

	return health
end

-- ============================================================================
-- STATE DUMPING
-- ============================================================================

function RuntimeMonitor.DumpState(): {}
	local state = {
		Timestamp = tick(),
		Server = {
			PlaceId = game.PlaceId,
			JobId = game.JobId,
			PlayerCount = #Players:GetPlayers(),
			Memory = Stats:GetTotalMemoryUsageMb(),
			FPS = workspace:GetRealPhysicsFPS()
		},
		Players = {},
		Services = {},
		RecentErrors = {},
		RecentAlerts = {}
	}

	-- Dump player states
	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = {
			UserId = player.UserId,
			Name = player.Name,
			JoinTime = player.AccountAge
		}

		-- Get player data if available
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService and DataService.GetData then
			local success, data = pcall(function()
				return DataService.GetData(player)
			end)
			if success and data then
				playerData.GameData = {
					Section = data.CurrentSection,
					Coins = data.Coins,
					PlayTime = data.PlayTime
				}
			end
		end

		table.insert(state.Players, playerData)
	end

	-- Dump service states
	if _G.TowerAscent then
		for serviceName, service in pairs(_G.TowerAscent) do
			if type(service) == "table" then
				local serviceState = {}

				-- Get basic info
				if service.Enabled ~= nil then
					serviceState.Enabled = service.Enabled
				end

				-- Service-specific data
				if serviceName == "RoundService" and service.CurrentTower then
					serviceState.TowerExists = service.CurrentTower ~= nil
					serviceState.TowerParent = service.CurrentTower.Parent and service.CurrentTower.Parent.Name
				elseif serviceName == "ErrorRecovery" then
					serviceState.ErrorCount = #service.ErrorLog
					serviceState.AutoRecoveryEnabled = service.AutoRecoveryEnabled
				elseif serviceName == "MemoryManager" then
					serviceState.CleanupCount = service.CleanupCount or 0
					serviceState.LastCleanup = service.LastCleanup
				end

				state.Services[serviceName] = serviceState
			end
		end
	end

	-- Recent errors (last 10)
	local errorStart = math.max(1, #RuntimeMonitor.Errors - 9)
	for i = errorStart, #RuntimeMonitor.Errors do
		table.insert(state.RecentErrors, RuntimeMonitor.Errors[i])
	end

	-- Recent alerts (last 5)
	local alertStart = math.max(1, #RuntimeMonitor.Alerts - 4)
	for i = alertStart, #RuntimeMonitor.Alerts do
		table.insert(state.RecentAlerts, RuntimeMonitor.Alerts[i])
	end

	return state
end

-- ============================================================================
-- PERFORMANCE TRACKING
-- ============================================================================

function RuntimeMonitor.GetPerformanceReport(): {}
	local report = {
		Current = {
			FPS = workspace:GetRealPhysicsFPS(),
			Memory = Stats:GetTotalMemoryUsageMb(),
			Players = #Players:GetPlayers(),
			Parts = #workspace:GetDescendants()
		},
		Errors = {
			Total = #RuntimeMonitor.Errors,
			LastMinute = 0,
			LastHour = 0
		},
		Uptime = tick()
	}

	-- Count recent errors
	local now = tick()
	for _, error in ipairs(RuntimeMonitor.Errors) do
		if error.Timestamp > now - 60 then
			report.Errors.LastMinute = report.Errors.LastMinute + 1
		end
		if error.Timestamp > now - 3600 then
			report.Errors.LastHour = report.Errors.LastHour + 1
		end
	end

	return report
end

-- ============================================================================
-- ERROR ANALYSIS
-- ============================================================================

function RuntimeMonitor.AnalyzeErrors(): {}
	local analysis = {
		TotalErrors = #RuntimeMonitor.Errors,
		ErrorsByContext = {},
		CommonPatterns = {},
		CriticalErrors = 0
	}

	-- Count by context
	for _, error in ipairs(RuntimeMonitor.Errors) do
		local context = error.Context
		analysis.ErrorsByContext[context] = (analysis.ErrorsByContext[context] or 0) + 1

		-- Check for critical patterns
		if error.Error:find("DataService") or error.Error:find("data loss") then
			analysis.CriticalErrors = analysis.CriticalErrors + 1
		end
	end

	-- Find common error patterns
	local patterns = {
		"nil value",
		"attempt to index",
		"timeout",
		"memory",
		"connection lost"
	}

	for _, pattern in ipairs(patterns) do
		local count = 0
		for _, error in ipairs(RuntimeMonitor.Errors) do
			if error.Error:find(pattern) then
				count = count + 1
			end
		end
		if count > 0 then
			analysis.CommonPatterns[pattern] = count
		end
	end

	return analysis
end

-- ============================================================================
-- MONITORING LIFECYCLE
-- ============================================================================

function RuntimeMonitor.Start()
	if RuntimeMonitor.Enabled then
		warn("[RuntimeMonitor] Already running")
		return
	end

	RuntimeMonitor.Enabled = true
	print("[RuntimeMonitor] Starting runtime monitoring...")

	-- Start health check loop
	task.spawn(function()
		while RuntimeMonitor.Enabled do
			task.wait(CONFIG.HealthCheckInterval)
			if RuntimeMonitor.Enabled then
				RuntimeMonitor.RunHealthChecks()
			end
		end
	end)

	-- Monitor for player crashes
	Players.PlayerRemoving:Connect(function(player)
		-- Track if player left unexpectedly
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			local humanoid = character.Humanoid
			if humanoid.Health <= 0 then
				RuntimeMonitor.TrackError("PlayerCrash", "Player died and left: " .. player.Name)
			end
		end
	end)

	print("[RuntimeMonitor] Runtime monitoring active")
end

function RuntimeMonitor.Stop()
	RuntimeMonitor.Enabled = false
	if RuntimeMonitor.Connection then
		RuntimeMonitor.Connection:Disconnect()
		RuntimeMonitor.Connection = nil
	end
	print("[RuntimeMonitor] Runtime monitoring stopped")
end

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================

function RuntimeMonitor.ExportReport(): string
	local state = RuntimeMonitor.DumpState()
	local analysis = RuntimeMonitor.AnalyzeErrors()

	local report = {
		"# Runtime Monitor Report",
		string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
		"",
		"## Server Status",
		string.format("- JobId: %s", state.Server.JobId),
		string.format("- Players: %d", state.Server.PlayerCount),
		string.format("- Memory: %.1f MB", state.Server.Memory),
		string.format("- FPS: %d", state.Server.FPS),
		"",
		"## Error Analysis",
		string.format("- Total Errors: %d", analysis.TotalErrors),
		string.format("- Critical Errors: %d", analysis.CriticalErrors),
		"",
		"### Errors by Context:",
	}

	for context, count in pairs(analysis.ErrorsByContext) do
		table.insert(report, string.format("- %s: %d", context, count))
	end

	table.insert(report, "")
	table.insert(report, "### Common Patterns:")

	for pattern, count in pairs(analysis.CommonPatterns) do
		table.insert(report, string.format("- %s: %d occurrences", pattern, count))
	end

	return table.concat(report, "\n")
end

function RuntimeMonitor.GetStats()
	return {
		ErrorCount = #RuntimeMonitor.Errors,
		AlertCount = #RuntimeMonitor.Alerts,
		LastHealthCheck = RuntimeMonitor.HealthChecks[#RuntimeMonitor.HealthChecks],
		Enabled = RuntimeMonitor.Enabled
	}
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function RuntimeMonitor.RegisterAdminCommands()
	local AdminCommands = _G.TowerAscent and _G.TowerAscent.AdminCommands
	if not AdminCommands then
		return
	end

	-- /monitor start
	AdminCommands.RegisterCommand("monitor", "start", function(player)
		RuntimeMonitor.Start()
		return "Runtime monitoring started"
	end)

	-- /monitor stop
	AdminCommands.RegisterCommand("monitor", "stop", function(player)
		RuntimeMonitor.Stop()
		return "Runtime monitoring stopped"
	end)

	-- /monitor report
	AdminCommands.RegisterCommand("monitor", "report", function(player)
		return RuntimeMonitor.ExportReport()
	end)

	-- /monitor health
	AdminCommands.RegisterCommand("monitor", "health", function(player)
		local health = RuntimeMonitor.RunHealthChecks()
		local message = "Health Check Results:\n"
		for name, check in pairs(health.Checks) do
			message = message .. string.format("%s: %s\n", name, check.Message)
		end
		return message
	end)

	-- /monitor errors
	AdminCommands.RegisterCommand("monitor", "errors", function(player)
		local analysis = RuntimeMonitor.AnalyzeErrors()
		return string.format("Errors: %d total, %d critical",
			analysis.TotalErrors, analysis.CriticalErrors)
	end)

	print("[RuntimeMonitor] Admin commands registered")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return RuntimeMonitor