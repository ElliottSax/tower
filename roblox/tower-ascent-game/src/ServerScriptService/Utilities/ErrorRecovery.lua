--[[
	ErrorRecovery.lua
	Graceful error handling and recovery mechanisms

	Features:
	- Automatic retry logic with exponential backoff
	- Fallback mechanisms for critical failures
	- Error logging and tracking
	- Circuit breaker pattern
	- Graceful degradation

	Usage:
	   local result = ErrorRecovery.RetryOperation(function() ... end, 3)
	   ErrorRecovery.RegisterFallback("ServiceName", fallbackFunction)

	Created: 2025-12-01 (Post-Testing-Infrastructure)
--]]

local ErrorRecovery = {}
ErrorRecovery.ErrorLog = {}
ErrorRecovery.Fallbacks = {}
ErrorRecovery.CircuitBreakers = {}
ErrorRecovery.AutoRecoveryEnabled = false
ErrorRecovery.RecoveryInProgress = {} -- Track ongoing recoveries to prevent race conditions

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Retry settings
	MaxRetries = 3,
	InitialBackoff = 0.5, -- seconds
	MaxBackoff = 10,
	BackoffMultiplier = 2,

	-- Circuit breaker
	FailureThreshold = 5, -- failures before opening circuit
	ResetTimeout = 30, -- seconds before attempting reset

	-- Logging
	MaxLogEntries = 500,
}

-- ============================================================================
-- ERROR LOGGING
-- ============================================================================

local function LogError(context: string, error: string, metadata: {}?)
	local entry = {
		Context = context,
		Error = tostring(error),
		Metadata = metadata or {},
		Timestamp = tick(),
		Count = 1
	}

	-- Check for duplicate recent errors
	for i = #ErrorRecovery.ErrorLog, math.max(1, #ErrorRecovery.ErrorLog - 10), -1 do
		local existing = ErrorRecovery.ErrorLog[i]
		if existing.Context == context and existing.Error == entry.Error then
			existing.Count = existing.Count + 1
			existing.Timestamp = tick()
			return
		end
	end

	table.insert(ErrorRecovery.ErrorLog, entry)

	-- Limit log size
	if #ErrorRecovery.ErrorLog > CONFIG.MaxLogEntries then
		table.remove(ErrorRecovery.ErrorLog, 1)
	end

	warn(string.format("[ErrorRecovery] %s: %s", context, error))
end

-- ============================================================================
-- RETRY LOGIC WITH EXPONENTIAL BACKOFF
-- ============================================================================

function ErrorRecovery.RetryOperation(
	operation: () -> any,
	maxRetries: number?,
	context: string?
): (boolean, any)
	maxRetries = maxRetries or CONFIG.MaxRetries
	context = context or "Unknown Operation"

	local backoff = CONFIG.InitialBackoff
	local lastError = nil

	for attempt = 1, maxRetries do
		local success, result = pcall(operation)

		if success then
			if attempt > 1 then
				print(string.format("[ErrorRecovery] %s succeeded on attempt %d/%d",
					context, attempt, maxRetries))
			end
			return true, result
		end

		lastError = result

		if attempt < maxRetries then
			LogError(context, result, {
				Attempt = attempt,
				MaxRetries = maxRetries,
				NextRetry = backoff
			})

			task.wait(backoff)
			backoff = math.min(backoff * CONFIG.BackoffMultiplier, CONFIG.MaxBackoff)
		end
	end

	-- All retries failed
	LogError(context .. " (FINAL FAILURE)", lastError, {
		TotalAttempts = maxRetries
	})

	return false, lastError
end

-- ============================================================================
-- FALLBACK MECHANISMS
-- ============================================================================

function ErrorRecovery.RegisterFallback(serviceName: string, fallbackFunction: () -> any)
	ErrorRecovery.Fallbacks[serviceName] = fallbackFunction
	print(string.format("[ErrorRecovery] Registered fallback for %s", serviceName))
end

function ErrorRecovery.ExecuteWithFallback(
	serviceName: string,
	primaryOperation: () -> any,
	customFallback: (() -> any)?
): (boolean, any)
	local success, result = pcall(primaryOperation)

	if success then
		return true, result
	end

	-- Try custom fallback first
	if customFallback then
		LogError(serviceName, result, {FallbackType = "Custom"})
		local fallbackSuccess, fallbackResult = pcall(customFallback)
		if fallbackSuccess then
			print(string.format("[ErrorRecovery] %s: Custom fallback succeeded", serviceName))
			return true, fallbackResult
		end
	end

	-- Try registered fallback
	local registeredFallback = ErrorRecovery.Fallbacks[serviceName]
	if registeredFallback then
		LogError(serviceName, result, {FallbackType = "Registered"})
		local fallbackSuccess, fallbackResult = pcall(registeredFallback)
		if fallbackSuccess then
			print(string.format("[ErrorRecovery] %s: Registered fallback succeeded", serviceName))
			return true, fallbackResult
		end
	end

	-- All fallbacks failed
	LogError(serviceName .. " (ALL FALLBACKS FAILED)", result)
	return false, result
end

-- ============================================================================
-- CIRCUIT BREAKER PATTERN
-- ============================================================================

local CircuitState = {
	CLOSED = "CLOSED", -- Normal operation
	OPEN = "OPEN", -- Failures detected, blocking requests
	HALF_OPEN = "HALF_OPEN" -- Testing if service recovered
}

function ErrorRecovery.InitCircuitBreaker(serviceName: string)
	ErrorRecovery.CircuitBreakers[serviceName] = {
		State = CircuitState.CLOSED,
		FailureCount = 0,
		LastFailureTime = 0,
		SuccessCount = 0
	}
end

function ErrorRecovery.ExecuteWithCircuitBreaker(
	serviceName: string,
	operation: () -> any
): (boolean, any)
	local breaker = ErrorRecovery.CircuitBreakers[serviceName]

	if not breaker then
		ErrorRecovery.InitCircuitBreaker(serviceName)
		breaker = ErrorRecovery.CircuitBreakers[serviceName]
	end

	-- Check circuit state
	if breaker.State == CircuitState.OPEN then
		local timeSinceFailure = tick() - breaker.LastFailureTime

		if timeSinceFailure >= CONFIG.ResetTimeout then
			-- Attempt to half-open circuit
			breaker.State = CircuitState.HALF_OPEN
			print(string.format("[ErrorRecovery] Circuit for %s is HALF-OPEN (testing recovery)",
				serviceName))
		else
			-- Circuit still open
			return false, string.format("Circuit breaker OPEN for %s (retry in %.1fs)",
				serviceName, CONFIG.ResetTimeout - timeSinceFailure)
		end
	end

	-- Execute operation
	local success, result = pcall(operation)

	if success then
		-- Success
		breaker.SuccessCount = breaker.SuccessCount + 1

		if breaker.State == CircuitState.HALF_OPEN and breaker.SuccessCount >= 3 then
			-- Recovered
			breaker.State = CircuitState.CLOSED
			breaker.FailureCount = 0
			breaker.SuccessCount = 0
			print(string.format("[ErrorRecovery] Circuit for %s is CLOSED (recovered)", serviceName))
		elseif breaker.State == CircuitState.CLOSED and breaker.FailureCount > 0 then
			-- Decay failure count on success in CLOSED state
			breaker.FailureCount = math.max(0, breaker.FailureCount - 1)
		end

		return true, result
	else
		-- Failure
		breaker.FailureCount = breaker.FailureCount + 1
		breaker.LastFailureTime = tick()
		breaker.SuccessCount = 0

		LogError(serviceName, result, {
			CircuitState = breaker.State,
			FailureCount = breaker.FailureCount
		})

		if breaker.FailureCount >= CONFIG.FailureThreshold then
			breaker.State = CircuitState.OPEN
			warn(string.format("[ErrorRecovery] Circuit for %s is OPEN (threshold reached: %d failures)",
				serviceName, breaker.FailureCount))
		end

		return false, result
	end
end

-- ============================================================================
-- GRACEFUL DEGRADATION
-- ============================================================================

function ErrorRecovery.SafeServiceCall(
	serviceName: string,
	methodName: string,
	args: {any},
	defaultValue: any?
): any
	local service = _G.TowerAscent and _G.TowerAscent[serviceName]

	if not service then
		LogError("SafeServiceCall", string.format("%s not found", serviceName))
		return defaultValue
	end

	local method = service[methodName]
	if not method or type(method) ~= "function" then
		LogError("SafeServiceCall", string.format("%s.%s not found or not a function",
			serviceName, methodName))
		return defaultValue
	end

	local success, result = pcall(function()
		return method(table.unpack(args))
	end)

	if success then
		return result
	else
		LogError("SafeServiceCall", string.format("%s.%s failed: %s",
			serviceName, methodName, tostring(result)))
		return defaultValue
	end
end

-- ============================================================================
-- DATA RECOVERY
-- ============================================================================

function ErrorRecovery.RecoverPlayerData(player: Player): boolean
	if not player or not player:IsA("Player") then
		warn("[ErrorRecovery] Invalid player object")
		return false
	end

	local userId = player.UserId

	-- Check if recovery already in progress for this player
	if ErrorRecovery.RecoveryInProgress[userId] then
		warn(string.format("[ErrorRecovery] Recovery already in progress for %s", player.Name))
		return false
	end

	-- Mark recovery as in progress
	ErrorRecovery.RecoveryInProgress[userId] = true

	print(string.format("[ErrorRecovery] Attempting to recover data for %s", player.Name))

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		warn("[ErrorRecovery] DataService not available")
		ErrorRecovery.RecoveryInProgress[userId] = nil
		return false
	end

	-- Check if DataService has a ReloadProfile API method (recommended approach)
	if DataService.ReloadProfile and type(DataService.ReloadProfile) == "function" then
		local success, result = ErrorRecovery.RetryOperation(function()
			return DataService.ReloadProfile(player)
		end, 3, "RecoverPlayerData")

		if success then
			print(string.format("[ErrorRecovery] Successfully recovered data for %s using ReloadProfile API", player.Name))
		else
			warn(string.format("[ErrorRecovery] Failed to recover data for %s: %s", player.Name, tostring(result)))
		end

		-- Clear recovery tracking (was missing, causing permanent lock for this player)
		ErrorRecovery.RecoveryInProgress[userId] = nil

		return success
	end

	-- Fallback: Use GetProfile to check if profile exists, don't manipulate internal state
	local success, result = ErrorRecovery.RetryOperation(function()
		-- Trigger standard load if no profile exists
		local hasProfile = false

		if DataService.GetProfile and type(DataService.GetProfile) == "function" then
			hasProfile = DataService.GetProfile(player) ~= nil
		elseif DataService.Profiles then
			-- Read-only check (safe)
			hasProfile = DataService.Profiles[player] ~= nil
		end

		if not hasProfile then
			-- Let DataService handle its own initialization
			if DataService.OnPlayerAdded then
				DataService.OnPlayerAdded(player)
			else
				error("DataService.OnPlayerAdded not available")
			end

			-- Verify profile loaded
			if DataService.GetProfile then
				if not DataService.GetProfile(player) then
					error("Profile failed to load after recovery attempt")
				end
			end
		end

		return true
	end, 3, "RecoverPlayerData")

	if success then
		print(string.format("[ErrorRecovery] Successfully recovered data for %s", player.Name))
	else
		warn(string.format("[ErrorRecovery] Failed to recover data for %s: %s", player.Name, tostring(result)))
	end

	-- Clear recovery tracking
	ErrorRecovery.RecoveryInProgress[userId] = nil

	return success
end

-- ============================================================================
-- TOWER RECOVERY
-- ============================================================================

function ErrorRecovery.RecoverTower(): boolean
	print("[ErrorRecovery] Attempting to recover tower generation")

	local RoundService = _G.TowerAscent and _G.TowerAscent.RoundService
	if not RoundService then
		warn("[ErrorRecovery] RoundService not available")
		return false
	end

	-- Attempt to regenerate tower with retry logic
	local success = ErrorRecovery.RetryOperation(function()
		-- Clean up existing tower
		if RoundService.CurrentTower then
			RoundService.CurrentTower:Destroy()
			RoundService.CurrentTower = nil
		end

		-- Generate new tower
		RoundService.GenerateNewTower()

		-- Verify tower exists
		if not RoundService.CurrentTower then
			error("Tower failed to generate")
		end

		return true
	end, 3, "RecoverTower")

	if success then
		print("[ErrorRecovery] Successfully recovered tower")
	else
		warn("[ErrorRecovery] Failed to recover tower")
	end

	return success
end

-- ============================================================================
-- STATS AND REPORTING
-- ============================================================================

function ErrorRecovery.GetErrorStats(): {}
	local stats = {
		TotalErrors = #ErrorRecovery.ErrorLog,
		ErrorsByContext = {},
		CircuitBreakerStatus = {},
		RecentErrors = {}
	}

	-- Count errors by context
	for _, entry in ipairs(ErrorRecovery.ErrorLog) do
		stats.ErrorsByContext[entry.Context] = (stats.ErrorsByContext[entry.Context] or 0) + entry.Count
	end

	-- Circuit breaker status
	for serviceName, breaker in pairs(ErrorRecovery.CircuitBreakers) do
		stats.CircuitBreakerStatus[serviceName] = {
			State = breaker.State,
			FailureCount = breaker.FailureCount,
			TimeSinceLastFailure = tick() - breaker.LastFailureTime
		}
	end

	-- Recent errors (last 10)
	local startIdx = math.max(1, #ErrorRecovery.ErrorLog - 9)
	for i = startIdx, #ErrorRecovery.ErrorLog do
		table.insert(stats.RecentErrors, ErrorRecovery.ErrorLog[i])
	end

	return stats
end

function ErrorRecovery.PrintErrorReport()
	local stats = ErrorRecovery.GetErrorStats()

	print("\n" .. string.rep("=", 60))
	print("ERROR RECOVERY REPORT")
	print(string.rep("=", 60))
	print(string.format("Total Errors: %d", stats.TotalErrors))

	print("\nErrors by Context:")
	for context, count in pairs(stats.ErrorsByContext) do
		print(string.format("  %s: %d", context, count))
	end

	print("\nCircuit Breaker Status:")
	for serviceName, status in pairs(stats.CircuitBreakerStatus) do
		print(string.format("  %s: %s (Failures: %d, Last: %.1fs ago)",
			serviceName, status.State, status.FailureCount, status.TimeSinceLastFailure))
	end

	print("\nRecent Errors:")
	for i, entry in ipairs(stats.RecentErrors) do
		print(string.format("  %d. [%s] %s (Count: %d, %.1fs ago)",
			i, entry.Context, entry.Error, entry.Count, tick() - entry.Timestamp))
	end

	print(string.rep("=", 60) .. "\n")
end

function ErrorRecovery.ClearErrorLog()
	ErrorRecovery.ErrorLog = {}
	print("[ErrorRecovery] Error log cleared")
end

function ErrorRecovery.ResetCircuitBreaker(serviceName: string)
	local breaker = ErrorRecovery.CircuitBreakers[serviceName]
	if breaker then
		breaker.State = CircuitState.CLOSED
		breaker.FailureCount = 0
		breaker.SuccessCount = 0
		print(string.format("[ErrorRecovery] Reset circuit breaker for %s", serviceName))
	else
		warn(string.format("[ErrorRecovery] No circuit breaker found for %s", serviceName))
	end
end

-- ============================================================================
-- AUTO-RECOVERY MECHANISMS
-- ============================================================================

function ErrorRecovery.EnableAutoRecovery()
	if ErrorRecovery.AutoRecoveryEnabled then
		warn("[ErrorRecovery] Auto-recovery already enabled")
		return
	end

	ErrorRecovery.AutoRecoveryEnabled = true
	print("[ErrorRecovery] Enabling auto-recovery mechanisms")

	-- Monitor for common failures
	task.spawn(function()
		while ErrorRecovery.AutoRecoveryEnabled do
			task.wait(30)

			if not ErrorRecovery.AutoRecoveryEnabled then
				break
			end

			local stats = ErrorRecovery.GetErrorStats()

			-- Check for repeated DataService failures
			if stats.ErrorsByContext["DataService"] and stats.ErrorsByContext["DataService"] > 5 then
				warn("[ErrorRecovery] Detected repeated DataService failures - investigating")
				-- Could trigger automatic recovery here
			end

			-- Check for tower generation failures
			if stats.ErrorsByContext["Generator"] and stats.ErrorsByContext["Generator"] > 3 then
				warn("[ErrorRecovery] Detected tower generation failures")
				ErrorRecovery.RecoverTower()
			end
		end

		print("[ErrorRecovery] Auto-recovery monitoring stopped")
	end)
end

function ErrorRecovery.DisableAutoRecovery()
	if not ErrorRecovery.AutoRecoveryEnabled then
		warn("[ErrorRecovery] Auto-recovery not enabled")
		return
	end

	ErrorRecovery.AutoRecoveryEnabled = false
	print("[ErrorRecovery] Disabling auto-recovery...")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ErrorRecovery
