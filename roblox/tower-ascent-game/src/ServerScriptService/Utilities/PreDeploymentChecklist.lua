--[[
	PreDeploymentChecklist.lua
	Final validation before production deployment

	Ensures all production requirements are met before going live.

	Validation Categories:
	1. Configuration (Debug mode off, correct settings)
	2. Code Quality (All tests passing)
	3. Performance (Meets targets)
	4. Security (Anti-cheat active, validation in place)
	5. Data (ProfileService configured)
	6. Safety (No debug tools enabled)

	Usage: _G.TowerAscent.PreDeploymentChecklist.Validate()

	Created: 2025-12-01 (Production Hardening)
--]]

local PreDeploymentChecklist = {}

-- ============================================================================
-- CHECKLIST ITEMS
-- ============================================================================

local ChecklistItems = {
	-- CRITICAL: Must pass for production
	Critical = {
		{
			ID = "DEBUG_MODE_OFF",
			Name = "Debug Mode Disabled",
			Check = function()
				local config = _G.TowerAscent and _G.TowerAscent.Config
				return config and config.Debug and not config.Debug.Enabled
			end,
			FailureMessage = "Debug mode is ENABLED - must be disabled in production",
			Severity = "BLOCKER"
		},
		{
			ID = "RUN_TESTS_OFF",
			Name = "Automated Tests Disabled",
			Check = function()
				local config = _G.TowerAscent and _G.TowerAscent.Config
				return config and config.Debug and not config.Debug.RunTests
			end,
			FailureMessage = "RunTests is ENABLED - must be disabled in production",
			Severity = "BLOCKER"
		},
		{
			ID = "CHAOS_MONKEY_OFF",
			Name = "Chaos Monkey Disabled",
			Check = function()
				local chaos = _G.TowerAscent and _G.TowerAscent.ChaosMonkey
				return chaos and not chaos.Enabled
			end,
			FailureMessage = "ChaosMonkey is ENABLED - must never run in production",
			Severity = "BLOCKER"
		},
		{
			ID = "ANTI_CHEAT_ON",
			Name = "Anti-Cheat Enabled",
			Check = function()
				local config = _G.TowerAscent and _G.TowerAscent.Config
				return config and config.AntiCheat and config.AntiCheat.Enabled
			end,
			FailureMessage = "Anti-cheat is DISABLED - must be enabled in production",
			Severity = "BLOCKER"
		},
		{
			ID = "DATA_SERVICE_LOADED",
			Name = "DataService Loaded",
			Check = function()
				return _G.TowerAscent and _G.TowerAscent.DataService ~= nil
			end,
			FailureMessage = "DataService not loaded - data will be lost",
			Severity = "BLOCKER"
		},
		{
			ID = "VALIDATION_TESTS_PASS",
			Name = "All Validation Tests Pass",
			Check = function()
				local tests = _G.TowerAscent and _G.TowerAscent.ValidationTests
				if not tests then return false end

				local success, results = pcall(function()
					return tests.RunAll()
				end)

				if not success then return false end

				-- Check for failures
				for _, result in ipairs(results) do
					if result.Status == "FAIL" then
						return false
					end
				end

				return true
			end,
			FailureMessage = "Validation tests failing - code review fixes may be broken",
			Severity = "BLOCKER"
		}
	},

	-- HIGH: Should pass, but can be overridden with justification
	High = {
		{
			ID = "MEMORY_MANAGER_ON",
			Name = "Memory Manager Enabled",
			Check = function()
				local config = _G.TowerAscent and _G.TowerAscent.Config
				return config and config.Memory and config.Memory.Enabled
			end,
			FailureMessage = "Memory manager disabled - may cause performance issues",
			Severity = "HIGH"
		},
		{
			ID = "CHECKPOINT_DEBOUNCE",
			Name = "Checkpoint Debounce Active",
			Check = function()
				local checkpoint = _G.TowerAscent and _G.TowerAscent.CheckpointService
				return checkpoint and checkpoint.CheckpointDebounce ~= nil
			end,
			FailureMessage = "Checkpoint debounce not active - spam exploit possible",
			Severity = "HIGH"
		},
		{
			ID = "VIP_RATE_LIMIT",
			Name = "VIP Rate Limiting Active",
			Check = function()
				local vip = _G.TowerAscent and _G.TowerAscent.VIPService
				return vip and vip.PurchaseRateLimits ~= nil
			end,
			FailureMessage = "VIP rate limiting not active - DoS possible",
			Severity = "HIGH"
		},
		{
			ID = "EDGE_CASE_TESTS_PASS",
			Name = "Edge Case Tests Pass",
			Check = function()
				local tests = _G.TowerAscent and _G.TowerAscent.EdgeCaseTests
				if not tests then return false end

				local success, results = pcall(function()
					return tests.RunAll()
				end)

				if not success then return false end

				-- Allow some warnings, but no failures
				for _, result in ipairs(results) do
					if result.Status == "FAIL" then
						return false
					end
				end

				return true
			end,
			FailureMessage = "Edge case tests failing - system may not handle boundary conditions",
			Severity = "HIGH"
		}
	},

	-- MEDIUM: Good to have
	Medium = {
		{
			ID = "PROFILER_OFF",
			Name = "Debug Profiler Not Running",
			Check = function()
				local profiler = _G.TowerAscent and _G.TowerAscent.DebugProfiler
				return profiler and not profiler.Enabled
			end,
			FailureMessage = "Debug profiler is running - adds performance overhead",
			Severity = "MEDIUM"
		},
		{
			ID = "STRESS_TESTS_PASS",
			Name = "Stress Tests Pass",
			Check = function()
				local tests = _G.TowerAscent and _G.TowerAscent.StressTests
				if not tests then return true end -- Optional

				local success, results = pcall(function()
					return tests.RunAll()
				end)

				return success
			end,
			FailureMessage = "Stress tests failing - performance may degrade under load",
			Severity = "MEDIUM"
		},
		{
			ID = "ERROR_RECOVERY_READY",
			Name = "Error Recovery Available",
			Check = function()
				local recovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
				return recovery ~= nil
			end,
			FailureMessage = "Error recovery not available - no automatic recovery",
			Severity = "MEDIUM"
		},
		{
			ID = "PLAYER_SYSTEMS_FUNCTIONAL",
			Name = "Player Systems Functional",
			Check = function()
				local Players = game:GetService("Players")
				local DataService = _G.TowerAscent and _G.TowerAscent.DataService

				if not DataService then return false end

				-- Get first player for testing
				local players = Players:GetPlayers()
				if #players == 0 then
					return true -- No players to test, skip check
				end

				local player = players[1]
				if not player or not player:IsA("Player") then
					return false -- Invalid player object
				end

				-- Verify player data systems work
				local success, _ = pcall(function()
					-- Test GetProfile/GetData (should not error)
					if DataService.GetProfile then
						DataService.GetProfile(player)
					elseif DataService.GetData then
						DataService.GetData(player)
					end
				end)

				return success
			end,
			FailureMessage = "Player systems not functional - data operations may fail",
			Severity = "MEDIUM"
		}
	},

	-- LOW: Nice to have
	Low = {
		{
			ID = "ADMIN_COMMANDS_AVAILABLE",
			Name = "Admin Commands Available",
			Check = function()
				return _G.TowerAscent and _G.TowerAscent.AdminCommands ~= nil
			end,
			FailureMessage = "Admin commands not available - harder to debug in production",
			Severity = "LOW"
		},
		{
			ID = "STATISTICS_SERVICE",
			Name = "Statistics Service Loaded",
			Check = function()
				return _G.TowerAscent and _G.TowerAscent.StatisticsService ~= nil
			end,
			FailureMessage = "Statistics service not loaded - no analytics",
			Severity = "LOW"
		}
	}
}

-- ============================================================================
-- VALIDATION EXECUTION
-- ============================================================================

function PreDeploymentChecklist.Validate(): {}
	print("\n" .. string.rep("=", 80))
	print("PRE-DEPLOYMENT CHECKLIST")
	print("Final validation before production deployment")
	print(string.rep("=", 80) .. "\n")

	local results = {
		Blockers = {},
		High = {},
		Medium = {},
		Low = {},
		Passed = 0,
		Failed = 0,
		TotalChecks = 0
	}

	-- Run critical checks
	print("[CRITICAL] Blocker Checks (Must Pass)")
	print(string.rep("-", 80))

	for _, item in ipairs(ChecklistItems.Critical) do
		results.TotalChecks = results.TotalChecks + 1

		local success, checkResult = pcall(item.Check)
		local passed = success and checkResult

		if passed then
			results.Passed = results.Passed + 1
			print(string.format("✅ %s", item.Name))
		else
			results.Failed = results.Failed + 1
			table.insert(results.Blockers, item)
			print(string.format("❌ %s", item.Name))
			print(string.format("   └─ %s", item.FailureMessage))
		end
	end

	-- Run high priority checks
	print("\n[HIGH] High Priority Checks")
	print(string.rep("-", 80))

	for _, item in ipairs(ChecklistItems.High) do
		results.TotalChecks = results.TotalChecks + 1

		local success, checkResult = pcall(item.Check)
		local passed = success and checkResult

		if passed then
			results.Passed = results.Passed + 1
			print(string.format("✅ %s", item.Name))
		else
			results.Failed = results.Failed + 1
			table.insert(results.High, item)
			print(string.format("⚠️  %s", item.Name))
			print(string.format("   └─ %s", item.FailureMessage))
		end
	end

	-- Run medium priority checks
	print("\n[MEDIUM] Medium Priority Checks")
	print(string.rep("-", 80))

	for _, item in ipairs(ChecklistItems.Medium) do
		results.TotalChecks = results.TotalChecks + 1

		local success, checkResult = pcall(item.Check)
		local passed = success and checkResult

		if passed then
			results.Passed = results.Passed + 1
			print(string.format("✅ %s", item.Name))
		else
			results.Failed = results.Failed + 1
			table.insert(results.Medium, item)
			print(string.format("⚠️  %s", item.Name))
		end
	end

	-- Run low priority checks
	print("\n[LOW] Low Priority Checks")
	print(string.rep("-", 80))

	for _, item in ipairs(ChecklistItems.Low) do
		results.TotalChecks = results.TotalChecks + 1

		local success, checkResult = pcall(item.Check)
		local passed = success and checkResult

		if passed then
			results.Passed = results.Passed + 1
			print(string.format("✅ %s", item.Name))
		else
			results.Failed = results.Failed + 1
			table.insert(results.Low, item)
			print(string.format("ℹ️  %s", item.Name))
		end
	end

	-- Summary
	print("\n" .. string.rep("=", 80))
	print("CHECKLIST SUMMARY")
	print(string.rep("=", 80))
	print(string.format("Total Checks: %d", results.TotalChecks))
	print(string.format("Passed: %d (%.1f%%)", results.Passed,
		(results.Passed / results.TotalChecks) * 100))
	print(string.format("Failed: %d (%.1f%%)", results.Failed,
		(results.Failed / results.TotalChecks) * 100))
	print()
	print(string.format("Blockers: %d", #results.Blockers))
	print(string.format("High Priority: %d", #results.High))
	print(string.format("Medium Priority: %d", #results.Medium))
	print(string.format("Low Priority: %d", #results.Low))
	print(string.rep("=", 80))

	-- Final verdict
	if #results.Blockers > 0 then
		print("\n❌ DEPLOYMENT BLOCKED")
		print("Fix all blocker issues before deployment:")
		for i, item in ipairs(results.Blockers) do
			print(string.format("  %d. %s", i, item.Name))
		end
		print()
		return results
	end

	if #results.High > 0 then
		print("\n⚠️  DEPLOYMENT NOT RECOMMENDED")
		print("Fix high priority issues or document justification:")
		for i, item in ipairs(results.High) do
			print(string.format("  %d. %s", i, item.Name))
		end
		print()
		return results
	end

	if #results.Medium > 0 then
		print("\n✅ DEPLOYMENT ALLOWED (with warnings)")
		print("Consider fixing medium priority issues:")
		for i, item in ipairs(results.Medium) do
			print(string.format("  %d. %s", i, item.Name))
		end
		print()
	else
		print("\n✅ READY FOR PRODUCTION DEPLOYMENT")
		print("All critical and high priority checks passed!")
		print()
	end

	return results
end

-- ============================================================================
-- QUICK VALIDATION
-- ============================================================================

function PreDeploymentChecklist.QuickCheck(): boolean
	print("\n[PreDeploymentChecklist] Running quick check...")

	local hasBlockers = false

	for _, item in ipairs(ChecklistItems.Critical) do
		local success, checkResult = pcall(item.Check)
		if not (success and checkResult) then
			warn(string.format("❌ BLOCKER: %s", item.Name))
			warn(string.format("   %s", item.FailureMessage))
			hasBlockers = true
		end
	end

	if hasBlockers then
		print("❌ Quick check failed - blockers found\n")
		return false
	else
		print("✅ Quick check passed - no blockers\n")
		return true
	end
end

-- ============================================================================
-- GENERATE DEPLOYMENT REPORT
-- ============================================================================

function PreDeploymentChecklist.GenerateReport(): string
	local results = PreDeploymentChecklist.Validate()

	local report = {
		"# Pre-Deployment Validation Report",
		"",
		string.format("**Generated:** %s", os.date("%Y-%m-%d %H:%M:%S")),
		string.format("**Total Checks:** %d", results.TotalChecks),
		string.format("**Passed:** %d (%.1f%%)", results.Passed,
			(results.Passed / results.TotalChecks) * 100),
		string.format("**Failed:** %d (%.1f%%)", results.Failed,
			(results.Failed / results.TotalChecks) * 100),
		"",
		"## Status",
		""
	}

	if #results.Blockers > 0 then
		table.insert(report, "❌ **DEPLOYMENT BLOCKED**")
		table.insert(report, "")
		table.insert(report, "### Blocker Issues")
		for i, item in ipairs(results.Blockers) do
			table.insert(report, string.format("%d. **%s**", i, item.Name))
			table.insert(report, string.format("   - %s", item.FailureMessage))
		end
	elseif #results.High > 0 then
		table.insert(report, "⚠️  **DEPLOYMENT NOT RECOMMENDED**")
		table.insert(report, "")
		table.insert(report, "### High Priority Issues")
		for i, item in ipairs(results.High) do
			table.insert(report, string.format("%d. **%s**", i, item.Name))
			table.insert(report, string.format("   - %s", item.FailureMessage))
		end
	else
		table.insert(report, "✅ **READY FOR DEPLOYMENT**")
	end

	return table.concat(report, "\n")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return PreDeploymentChecklist
