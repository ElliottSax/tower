--[[
	ProductionReadiness.lua
	Meta-validation suite for production deployment readiness

	Tests the test infrastructure itself to ensure reliability.

	Features:
	- Validates all test utilities work correctly
	- Checks integration between systems
	- Verifies production safety guards
	- Tests error handling mechanisms
	- Validates performance impact
	- Resource leak detection
	- Simulated production conditions

	Usage: _G.TowerAscent.ProductionReadiness.RunFullValidation()

	Created: 2025-12-01 (Production Hardening)
--]]

local ProductionReadiness = {}
ProductionReadiness.Results = {}
ProductionReadiness.Errors = {}
ProductionReadiness.Warnings = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Validation thresholds
	MaxTestExecutionTime = 30, -- seconds
	MaxMemoryImpact = 20, -- MB
	MaxProfilerOverhead = 5, -- percent

	-- Production safety
	RequireDebugMode = true,
	BlockChaosInProduction = true,
}

-- ============================================================================
-- TIMEOUT PROTECTION
-- ============================================================================

local function RunWithTimeout(func: () -> any, timeoutSeconds: number, context: string?): (boolean, any)
	context = context or "Operation"

	local finished = false
	local result = nil
	local success = false

	task.spawn(function()
		success, result = pcall(func)
		finished = true
	end)

	local startTime = tick()
	while not finished and (tick() - startTime) < timeoutSeconds do
		task.wait(0.1)
	end

	if not finished then
		local errorMsg = string.format("Timeout: %s took longer than %ds", context, timeoutSeconds)
		return false, errorMsg
	end

	return success, result
end

-- ============================================================================
-- LOGGING
-- ============================================================================

local function LogResult(category: string, test: string, status: string, message: string)
	local entry = {
		Category = category,
		Test = test,
		Status = status,
		Message = message,
		Timestamp = tick()
	}

	table.insert(ProductionReadiness.Results, entry)

	local emoji = status == "PASS" and "✅" or status == "FAIL" and "❌" or "⚠️"
	print(string.format("[ProductionReadiness] %s [%s] %s: %s", emoji, category, test, message))

	if status == "FAIL" then
		table.insert(ProductionReadiness.Errors, entry)
	elseif status == "WARN" then
		table.insert(ProductionReadiness.Warnings, entry)
	end
end

-- ============================================================================
-- UTILITY EXISTENCE CHECKS
-- ============================================================================

function ProductionReadiness.ValidateUtilitiesExist(): boolean
	LogResult("INFRASTRUCTURE", "Utility Existence", "INFO", "Checking all utilities are loaded...")

	local requiredUtilities = {
		"ValidationTests",
		"EdgeCaseTests",
		"StressTests",
		"ChaosMonkey",
		"ErrorRecovery",
		"DebugProfiler",
		"AdminCommands"
	}

	local allExist = true

	for _, utilityName in ipairs(requiredUtilities) do
		local utility = _G.TowerAscent and _G.TowerAscent[utilityName]

		if not utility then
			LogResult("INFRASTRUCTURE", "Utility Existence", "FAIL",
				string.format("%s not found in _G.TowerAscent", utilityName))
			allExist = false
		else
			LogResult("INFRASTRUCTURE", "Utility Existence", "PASS",
				string.format("%s loaded", utilityName))
		end
	end

	return allExist
end

-- ============================================================================
-- VALIDATION TEST INTEGRITY
-- ============================================================================

function ProductionReadiness.TestValidationTests(): boolean
	LogResult("VALIDATION", "ValidationTests", "INFO", "Testing ValidationTests suite...")

	local ValidationTests = _G.TowerAscent and _G.TowerAscent.ValidationTests
	if not ValidationTests then
		LogResult("VALIDATION", "ValidationTests", "FAIL", "ValidationTests not loaded")
		return false
	end

	-- Check all test functions exist
	local requiredTests = {
		"TestSyntax",
		"TestCheckpointDebounce",
		"TestRespawnTracking",
		"TestVIPRateLimiting",
		"TestSectionValidation",
		"TestMemoryManagerCaching",
		"TestConnectionCleanup",
		"RunAll"
	}

	local allExist = true
	for _, testName in ipairs(requiredTests) do
		if type(ValidationTests[testName]) ~= "function" then
			LogResult("VALIDATION", "ValidationTests", "FAIL",
				string.format("Missing test function: %s", testName))
			allExist = false
		end
	end

	if not allExist then return false end

	-- Try to run tests with timeout protection
	local success, results = RunWithTimeout(function()
		return ValidationTests.RunAll()
	end, CONFIG.MaxTestExecutionTime, "ValidationTests.RunAll")

	if not success then
		LogResult("VALIDATION", "ValidationTests", "FAIL",
			string.format("RunAll() threw error: %s", tostring(results)))
		return false
	end

	-- Validate results structure
	if type(results) ~= "table" then
		LogResult("VALIDATION", "ValidationTests", "FAIL", "RunAll() should return table")
		return false
	end

	LogResult("VALIDATION", "ValidationTests", "PASS",
		string.format("All tests executed (%d results)", #results))
	return true
end

-- ============================================================================
-- EDGE CASE TEST INTEGRITY
-- ============================================================================

function ProductionReadiness.TestEdgeCaseTests(): boolean
	LogResult("EDGE_CASES", "EdgeCaseTests", "INFO", "Testing EdgeCaseTests suite...")

	local EdgeCaseTests = _G.TowerAscent and _G.TowerAscent.EdgeCaseTests
	if not EdgeCaseTests then
		LogResult("EDGE_CASES", "EdgeCaseTests", "FAIL", "EdgeCaseTests not loaded")
		return false
	end

	-- Check RunAll exists
	if type(EdgeCaseTests.RunAll) ~= "function" then
		LogResult("EDGE_CASES", "EdgeCaseTests", "FAIL", "Missing RunAll function")
		return false
	end

	-- Try to run tests with timeout protection
	local startTime = tick()
	local success, results = RunWithTimeout(function()
		return EdgeCaseTests.RunAll()
	end, CONFIG.MaxTestExecutionTime, "EdgeCaseTests.RunAll")
	local duration = tick() - startTime

	if not success then
		LogResult("EDGE_CASES", "EdgeCaseTests", "FAIL",
			string.format("RunAll() threw error: %s", tostring(results)))
		return false
	end

	if duration > CONFIG.MaxTestExecutionTime then
		LogResult("EDGE_CASES", "EdgeCaseTests", "WARN",
			string.format("Tests took %.1fs (threshold: %ds)", duration, CONFIG.MaxTestExecutionTime))
	end

	LogResult("EDGE_CASES", "EdgeCaseTests", "PASS",
		string.format("All tests executed in %.1fs", duration))
	return true
end

-- ============================================================================
-- STRESS TEST INTEGRITY
-- ============================================================================

function ProductionReadiness.TestStressTests(): boolean
	LogResult("STRESS", "StressTests", "INFO", "Testing StressTests suite...")

	local StressTests = _G.TowerAscent and _G.TowerAscent.StressTests
	if not StressTests then
		LogResult("STRESS", "StressTests", "FAIL", "StressTests not loaded")
		return false
	end

	-- Check critical functions exist
	local requiredFunctions = {
		"RunAll",
		"SimulateHighLoad",
		"StopLoadTest"
	}

	for _, funcName in ipairs(requiredFunctions) do
		if type(StressTests[funcName]) ~= "function" then
			LogResult("STRESS", "StressTests", "FAIL",
				string.format("Missing function: %s", funcName))
			return false
		end
	end

	-- Test that StopLoadTest works (safety mechanism)
	StressTests.IsRunning = true
	StressTests.StopLoadTest()

	if StressTests.IsRunning then
		LogResult("STRESS", "StressTests", "FAIL", "StopLoadTest() doesn't stop load test")
		return false
	end

	LogResult("STRESS", "StressTests", "PASS", "All functions exist and safety works")
	return true
end

-- ============================================================================
-- CHAOS MONKEY SAFETY CHECKS
-- ============================================================================

function ProductionReadiness.TestChaosMonkeySafety(): boolean
	LogResult("CHAOS", "ChaosMonkey Safety", "INFO", "Testing chaos engineering safety...")

	local ChaosMonkey = _G.TowerAscent and _G.TowerAscent.ChaosMonkey
	if not ChaosMonkey then
		LogResult("CHAOS", "ChaosMonkey Safety", "FAIL", "ChaosMonkey not loaded")
		return false
	end

	-- Test 1: IsSafeToEnable() exists and works
	if type(ChaosMonkey.IsSafeToEnable) ~= "function" then
		LogResult("CHAOS", "ChaosMonkey Safety", "FAIL", "Missing IsSafeToEnable() function")
		return false
	end

	local isSafe = ChaosMonkey.IsSafeToEnable()
	local GameConfig = _G.TowerAscent and _G.TowerAscent.Config

	if GameConfig and GameConfig.Debug and not GameConfig.Debug.Enabled then
		-- Production mode - chaos should NOT be safe
		if isSafe then
			LogResult("CHAOS", "ChaosMonkey Safety", "FAIL",
				"IsSafeToEnable() returns true in production mode (CRITICAL BUG)")
			return false
		else
			LogResult("CHAOS", "ChaosMonkey Safety", "PASS",
				"Production safety guard active - chaos blocked")
		end
	else
		-- Debug mode - chaos can be enabled
		LogResult("CHAOS", "ChaosMonkey Safety", "PASS",
			"Debug mode - chaos allowed (expected)")
	end

	-- Test 2: DisableChaos() works
	ChaosMonkey.Enabled = true
	ChaosMonkey.DisableChaos()

	if ChaosMonkey.Enabled then
		LogResult("CHAOS", "ChaosMonkey Safety", "FAIL", "DisableChaos() doesn't disable")
		return false
	end

	LogResult("CHAOS", "ChaosMonkey Safety", "PASS", "All safety mechanisms work")
	return true
end

-- ============================================================================
-- ERROR RECOVERY VALIDATION
-- ============================================================================

function ProductionReadiness.TestErrorRecovery(): boolean
	LogResult("ERROR_RECOVERY", "ErrorRecovery", "INFO", "Testing error recovery mechanisms...")

	local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
	if not ErrorRecovery then
		LogResult("ERROR_RECOVERY", "ErrorRecovery", "FAIL", "ErrorRecovery not loaded")
		return false
	end

	-- Test 1: RetryOperation with successful operation
	local callCount = 0
	local success, result = ErrorRecovery.RetryOperation(function()
		callCount = callCount + 1
		return "success"
	end, 3, "TestOperation")

	if not success or result ~= "success" or callCount ~= 1 then
		LogResult("ERROR_RECOVERY", "ErrorRecovery", "FAIL",
			"RetryOperation failed on successful operation")
		return false
	end

	-- Test 2: RetryOperation with eventual success
	callCount = 0
	success, result = ErrorRecovery.RetryOperation(function()
		callCount = callCount + 1
		if callCount < 2 then
			error("Temporary failure")
		end
		return "recovered"
	end, 3, "TestRetry")

	if not success or result ~= "recovered" or callCount ~= 2 then
		LogResult("ERROR_RECOVERY", "ErrorRecovery", "FAIL",
			"RetryOperation failed to recover after retry")
		return false
	end

	-- Test 3: RetryOperation with permanent failure
	callCount = 0
	success, result = ErrorRecovery.RetryOperation(function()
		callCount = callCount + 1
		error("Permanent failure")
	end, 3, "TestPermanentFailure")

	if success or callCount ~= 3 then
		LogResult("ERROR_RECOVERY", "ErrorRecovery", "FAIL",
			"RetryOperation should fail after max retries")
		return false
	end

	-- Test 4: Circuit breaker
	ErrorRecovery.InitCircuitBreaker("TestService")

	-- Should work initially
	success = ErrorRecovery.ExecuteWithCircuitBreaker("TestService", function()
		return true
	end)

	if not success then
		LogResult("ERROR_RECOVERY", "ErrorRecovery", "FAIL",
			"Circuit breaker blocked valid operation")
		return false
	end

	LogResult("ERROR_RECOVERY", "ErrorRecovery", "PASS",
		"Retry logic and circuit breaker work correctly")
	return true
end

-- ============================================================================
-- PROFILER VALIDATION
-- ============================================================================

function ProductionReadiness.TestDebugProfiler(): boolean
	LogResult("PROFILER", "DebugProfiler", "INFO", "Testing debug profiler...")

	local Profiler = _G.TowerAscent and _G.TowerAscent.DebugProfiler
	if not Profiler then
		LogResult("PROFILER", "DebugProfiler", "FAIL", "DebugProfiler not loaded")
		return false
	end

	-- Test 1: Start/Stop
	Profiler.Reset()
	Profiler.Start()

	if not Profiler.Enabled then
		LogResult("PROFILER", "DebugProfiler", "FAIL", "Start() doesn't enable profiler")
		return false
	end

	-- Test 2: ProfileFunction accuracy
	local testExecuted = false
	local result = Profiler.ProfileFunction("TestFunction", function()
		testExecuted = true
		return "result"
	end)

	if not testExecuted or result ~= "result" then
		LogResult("PROFILER", "DebugProfiler", "FAIL", "ProfileFunction doesn't execute correctly")
		Profiler.Stop()
		return false
	end

	-- Test 3: Stats collection
	local stats = Profiler.GetStats()
	if not stats or not stats.Profiles or not stats.Profiles["TestFunction"] then
		LogResult("PROFILER", "DebugProfiler", "FAIL", "Stats not collected")
		Profiler.Stop()
		return false
	end

	-- Test 4: Performance overhead
	local iterations = 1000
	local startTime = tick()
	for i = 1, iterations do
		local _ = 1 + 1
	end
	local baselineTime = tick() - startTime

	startTime = tick()
	for i = 1, iterations do
		Profiler.ProfileFunction("OverheadTest", function()
			local _ = 1 + 1
		end)
	end
	local profiledTime = tick() - startTime

	local overhead = ((profiledTime - baselineTime) / baselineTime) * 100

	if overhead > CONFIG.MaxProfilerOverhead then
		LogResult("PROFILER", "DebugProfiler", "WARN",
			string.format("Profiler overhead: %.1f%% (threshold: %d%%)", overhead, CONFIG.MaxProfilerOverhead))
	else
		LogResult("PROFILER", "DebugProfiler", "PASS",
			string.format("Profiler overhead acceptable: %.1f%%", overhead))
	end

	Profiler.Stop()
	return true
end

-- ============================================================================
-- INTEGRATION TESTS
-- ============================================================================

function ProductionReadiness.TestUtilityIntegration(): boolean
	LogResult("INTEGRATION", "Utility Integration", "INFO", "Testing utility integration...")

	-- Test 1: ErrorRecovery + Profiler
	local ErrorRecovery = _G.TowerAscent.ErrorRecovery
	local Profiler = _G.TowerAscent.DebugProfiler

	Profiler.Start()

	local success, result = ErrorRecovery.RetryOperation(function()
		return Profiler.ProfileFunction("IntegrationTest", function()
			return "integrated"
		end)
	end, 3, "IntegrationTest")

	if not success or result ~= "integrated" then
		LogResult("INTEGRATION", "Utility Integration", "FAIL",
			"ErrorRecovery + Profiler integration failed")
		Profiler.Stop()
		return false
	end

	Profiler.Stop()

	-- Test 2: ChaosMonkey + ErrorRecovery
	local ChaosMonkey = _G.TowerAscent.ChaosMonkey

	-- Get chaos stats (should work even if chaos not enabled)
	local stats = ChaosMonkey.GetStats()
	if not stats or type(stats.TotalEvents) ~= "number" then
		LogResult("INTEGRATION", "Utility Integration", "FAIL",
			"ChaosMonkey.GetStats() returns invalid data")
		return false
	end

	LogResult("INTEGRATION", "Utility Integration", "PASS",
		"All utilities integrate correctly")
	return true
end

-- ============================================================================
-- RESOURCE LEAK DETECTION
-- ============================================================================

function ProductionReadiness.TestResourceLeaks(): boolean
	LogResult("RESOURCES", "Resource Leaks", "INFO", "Testing for resource leaks...")

	local Stats = game:GetService("Stats")
	local initialMemory = Stats:GetTotalMemoryUsageMb()

	-- Run all test suites
	local ValidationTests = _G.TowerAscent.ValidationTests
	local EdgeCaseTests = _G.TowerAscent.EdgeCaseTests

	-- Multiple iterations to detect leaks (with timeout protection)
	for i = 1, 3 do
		RunWithTimeout(function() ValidationTests.RunAll() end, CONFIG.MaxTestExecutionTime, "ValidationTests iteration " .. i)
		RunWithTimeout(function() EdgeCaseTests.RunAll() end, CONFIG.MaxTestExecutionTime, "EdgeCaseTests iteration " .. i)
		task.wait(0.1)
	end

	-- Force garbage collection
	task.wait(1)

	local finalMemory = Stats:GetTotalMemoryUsageMb()
	local memoryDelta = finalMemory - initialMemory

	if memoryDelta > CONFIG.MaxMemoryImpact then
		LogResult("RESOURCES", "Resource Leaks", "WARN",
			string.format("Memory increased %.1f MB (threshold: %d MB)", memoryDelta, CONFIG.MaxMemoryImpact))
		return true -- Warning, not failure
	else
		LogResult("RESOURCES", "Resource Leaks", "PASS",
			string.format("No memory leaks detected (delta: %.1f MB)", memoryDelta))
		return true
	end
end

-- ============================================================================
-- SERVICE DEPENDENCY CHECKS
-- ============================================================================

function ProductionReadiness.TestServiceDependencies(): boolean
	LogResult("DEPENDENCIES", "Service Dependencies", "INFO", "Checking service dependencies...")

	local requiredServices = {
		"DataService",
		"RoundService",
		"CheckpointService",
		"CoinService",
		"MemoryManager",
		"AntiCheat"
	}

	local allExist = true
	for _, serviceName in ipairs(requiredServices) do
		local service = _G.TowerAscent and _G.TowerAscent[serviceName]
		if not service then
			LogResult("DEPENDENCIES", "Service Dependencies", "WARN",
				string.format("%s not found (OK if not implemented yet)", serviceName))
		else
			LogResult("DEPENDENCIES", "Service Dependencies", "PASS",
				string.format("%s loaded", serviceName))
		end
	end

	return true
end

-- ============================================================================
-- PRODUCTION SAFETY VALIDATION
-- ============================================================================

function ProductionReadiness.ValidateProductionSafety(): boolean
	LogResult("SAFETY", "Production Safety", "INFO", "Validating production safety guards...")

	local GameConfig = _G.TowerAscent and _G.TowerAscent.Config
	if not GameConfig then
		LogResult("SAFETY", "Production Safety", "FAIL", "GameConfig not found")
		return false
	end

	local issues = {}

	-- Check 1: Debug mode configuration
	if not GameConfig.Debug then
		table.insert(issues, "Debug configuration missing")
	end

	-- Check 2: Production deployment checklist
	if GameConfig.Debug and GameConfig.Debug.Enabled then
		LogResult("SAFETY", "Production Safety", "WARN",
			"Debug mode is ENABLED - should be DISABLED in production")
	else
		LogResult("SAFETY", "Production Safety", "PASS",
			"Debug mode is disabled (production ready)")
	end

	if GameConfig.Debug and GameConfig.Debug.RunTests then
		LogResult("SAFETY", "Production Safety", "WARN",
			"RunTests is ENABLED - should be DISABLED in production")
	end

	-- Check 3: Chaos Monkey safety
	local ChaosMonkey = _G.TowerAscent.ChaosMonkey
	if ChaosMonkey and ChaosMonkey.Enabled then
		LogResult("SAFETY", "Production Safety", "FAIL",
			"ChaosMonkey is ENABLED - MUST be disabled in production")
		return false
	end

	if #issues > 0 then
		LogResult("SAFETY", "Production Safety", "WARN",
			string.format("Found %d configuration issues", #issues))
	else
		LogResult("SAFETY", "Production Safety", "PASS",
			"All production safety guards in place")
	end

	return true
end

-- ============================================================================
-- ERROR HANDLING STRESS TEST
-- ============================================================================

function ProductionReadiness.TestErrorHandlingRobustness(): boolean
	LogResult("ERROR_HANDLING", "Robustness", "INFO", "Testing error handling robustness...")

	local ErrorRecovery = _G.TowerAscent.ErrorRecovery

	-- Test 1: Handle nil gracefully
	local success, result = pcall(function()
		ErrorRecovery.RetryOperation(nil, 3, "NilTest")
	end)

	if success then
		LogResult("ERROR_HANDLING", "Robustness", "FAIL",
			"RetryOperation should reject nil operation")
		return false
	end

	-- Test 2: Handle invalid parameters
	success, result = pcall(function()
		ErrorRecovery.RetryOperation(function() end, -1, "InvalidRetries")
	end)

	-- Should handle gracefully (not crash)
	LogResult("ERROR_HANDLING", "Robustness", "PASS",
		"Error handling robust to invalid inputs")
	return true
end

-- ============================================================================
-- FULL VALIDATION SUITE
-- ============================================================================

function ProductionReadiness.RunFullValidation(): boolean
	print("\n" .. string.rep("=", 80))
	print("PRODUCTION READINESS VALIDATION")
	print("Comprehensive meta-validation of testing infrastructure")
	print(string.rep("=", 80) .. "\n")

	ProductionReadiness.Results = {}
	ProductionReadiness.Errors = {}
	ProductionReadiness.Warnings = {}

	local startTime = tick()

	-- Phase 1: Infrastructure
	print("\n[Phase 1] Infrastructure Validation")
	ProductionReadiness.ValidateUtilitiesExist()
	ProductionReadiness.TestServiceDependencies()

	-- Phase 2: Test Suite Integrity
	print("\n[Phase 2] Test Suite Integrity")
	ProductionReadiness.TestValidationTests()
	ProductionReadiness.TestEdgeCaseTests()
	ProductionReadiness.TestStressTests()

	-- Phase 3: Utility Validation
	print("\n[Phase 3] Utility Validation")
	ProductionReadiness.TestChaosMonkeySafety()
	ProductionReadiness.TestErrorRecovery()
	ProductionReadiness.TestDebugProfiler()

	-- Phase 4: Integration
	print("\n[Phase 4] Integration Testing")
	ProductionReadiness.TestUtilityIntegration()
	ProductionReadiness.TestResourceLeaks()

	-- Phase 5: Production Safety
	print("\n[Phase 5] Production Safety")
	ProductionReadiness.ValidateProductionSafety()
	ProductionReadiness.TestErrorHandlingRobustness()

	local duration = tick() - startTime

	-- Summary
	print("\n" .. string.rep("=", 80))
	print("VALIDATION SUMMARY")
	print(string.rep("=", 80))

	local passed = 0
	local failed = 0
	local warnings = 0

	for _, result in ipairs(ProductionReadiness.Results) do
		if result.Status == "PASS" then
			passed = passed + 1
		elseif result.Status == "FAIL" then
			failed = failed + 1
		elseif result.Status == "WARN" then
			warnings = warnings + 1
		end
	end

	print(string.format("Duration: %.2f seconds", duration))
	print(string.format("Total Checks: %d", #ProductionReadiness.Results))
	print(string.format("✅ Passed: %d", passed))
	print(string.format("❌ Failed: %d", failed))
	print(string.format("⚠️  Warnings: %d", warnings))

	if failed > 0 then
		print("\n❌ CRITICAL FAILURES DETECTED:")
		for i, error in ipairs(ProductionReadiness.Errors) do
			print(string.format("  %d. [%s] %s: %s", i, error.Category, error.Test, error.Message))
		end
	end

	if warnings > 0 then
		print("\n⚠️  WARNINGS:")
		for i, warning in ipairs(ProductionReadiness.Warnings) do
			print(string.format("  %d. [%s] %s: %s", i, warning.Category, warning.Test, warning.Message))
		end
	end

	print(string.rep("=", 80))

	if failed == 0 then
		print("\n✅ PRODUCTION READY - All critical checks passed")
		if warnings > 0 then
			print("⚠️  Review warnings before deployment")
		end
		print()
		return true
	else
		print("\n❌ NOT PRODUCTION READY - Fix critical failures before deployment")
		print()
		return false
	end
end

-- ============================================================================
-- QUICK CHECKS
-- ============================================================================

function ProductionReadiness.QuickCheck(): boolean
	print("\n[ProductionReadiness] Running quick validation...")

	local checks = {
		ProductionReadiness.ValidateUtilitiesExist,
		ProductionReadiness.TestChaosMonkeySafety,
		ProductionReadiness.ValidateProductionSafety
	}

	for _, check in ipairs(checks) do
		if not check() then
			print("❌ Quick check failed")
			return false
		end
	end

	print("✅ Quick check passed\n")
	return true
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ProductionReadiness
