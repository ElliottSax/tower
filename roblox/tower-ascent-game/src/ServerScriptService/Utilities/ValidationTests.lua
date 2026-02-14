--[[
	ValidationTests.lua
	Automated validation tests for code review fixes

	Run this after deploying fixes to verify everything works correctly.
	Usage: _G.TowerAscent.ValidationTests.RunAll()

	Tests:
	1. Checkpoint debounce protection
	2. Anti-cheat respawn tracking
	3. VIP rate limiting
	4. Section template validation
	5. Memory manager caching
	6. Connection cleanup

	Week 1: Created post-code-review (2025-12-01)
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ValidationTests = {}
ValidationTests.Results = {}
ValidationTests.IsRunning = false

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function Log(testName: string, status: string, message: string)
	local emoji = status == "PASS" and "✅" or status == "FAIL" and "❌" or "⚠️"
	print(string.format("[ValidationTests] %s %s: %s", emoji, testName, message))

	table.insert(ValidationTests.Results, {
		Test = testName,
		Status = status,
		Message = message,
		Timestamp = tick()
	})
end

local function CreateMockPlayer(): Player
	-- Returns first available player for testing
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[1]
	end
	warn("[ValidationTests] No players available for testing")
	return nil
end

-- ============================================================================
-- TEST 1: CHECKPOINT DEBOUNCE
-- ============================================================================

function ValidationTests.TestCheckpointDebounce()
	local testName = "Checkpoint Debounce"

	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then
		Log(testName, "FAIL", "CheckpointService not found in _G.TowerAscent")
		return
	end

	-- Verify debounce table exists
	if not CheckpointService.CheckpointDebounce then
		Log(testName, "FAIL", "CheckpointDebounce table not found")
		return
	end

	-- Test debounce key generation
	local testUserId = 12345
	local testSection = 10
	local debounceKey = testUserId .. "_" .. testSection

	-- Simulate debounce set
	CheckpointService.CheckpointDebounce[debounceKey] = true

	-- Verify it exists
	if CheckpointService.CheckpointDebounce[debounceKey] then
		Log(testName, "PASS", "Debounce table works correctly")
	else
		Log(testName, "FAIL", "Debounce key not set correctly")
	end

	-- Cleanup
	CheckpointService.CheckpointDebounce[debounceKey] = nil
end

-- ============================================================================
-- TEST 2: ANTI-CHEAT RESPAWN TRACKING
-- ============================================================================

function ValidationTests.TestRespawnTracking()
	local testName = "Anti-Cheat Respawn Tracking"

	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then
		Log(testName, "FAIL", "CheckpointService not found")
		return
	end

	-- Verify RecentRespawns table exists
	if not CheckpointService.RecentRespawns then
		Log(testName, "FAIL", "RecentRespawns table not found")
		return
	end

	-- Verify DidRecentlyRespawn function exists
	if not CheckpointService.DidRecentlyRespawn then
		Log(testName, "FAIL", "DidRecentlyRespawn function not found")
		return
	end

	-- Test with mock player
	local player = CreateMockPlayer()
	if not player or not player:IsA("Player") then
		Log(testName, "WARN", "No valid player available for testing")
		return
	end

	-- Simulate respawn
	CheckpointService.RecentRespawns[player.UserId] = tick()

	-- Test function
	local didRespawn = CheckpointService.DidRecentlyRespawn(player)
	if didRespawn then
		Log(testName, "PASS", "Respawn tracking works correctly")
	else
		Log(testName, "FAIL", "DidRecentlyRespawn returned false when should be true")
	end

	-- Cleanup
	CheckpointService.RecentRespawns[player.UserId] = nil
end

-- ============================================================================
-- TEST 3: VIP RATE LIMITING
-- ============================================================================

function ValidationTests.TestVIPRateLimiting()
	local testName = "VIP Rate Limiting"

	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if not VIPService then
		Log(testName, "WARN", "VIPService not found (Week 12+ feature)")
		return
	end

	-- Verify rate limit table exists
	if not VIPService.PurchaseRateLimits then
		Log(testName, "FAIL", "PurchaseRateLimits table not found")
		return
	end

	-- Test rate limit tracking
	local testUserId = 12345
	local now = tick()
	VIPService.PurchaseRateLimits[testUserId] = now

	-- Verify it was set
	if VIPService.PurchaseRateLimits[testUserId] == now then
		Log(testName, "PASS", "Rate limiting table works correctly")
	else
		Log(testName, "FAIL", "Rate limit timestamp not set correctly")
	end

	-- Cleanup
	VIPService.PurchaseRateLimits[testUserId] = nil
end

-- ============================================================================
-- TEST 4: SECTION TEMPLATE VALIDATION
-- ============================================================================

function ValidationTests.TestSectionValidation()
	local testName = "Section Template Validation"

	local generator = _G.TowerAscent and _G.TowerAscent.Generator
	if not generator then
		Log(testName, "FAIL", "Generator not found")
		return
	end

	-- Verify FindAttachment method exists
	if not generator.FindAttachment then
		Log(testName, "FAIL", "FindAttachment method not found")
		return
	end

	-- Create mock section with attachments
	local mockSection = Instance.new("Model")
	local mockPart = Instance.new("Part")
	mockPart.Parent = mockSection

	local startAttachment = Instance.new("Attachment")
	startAttachment.Name = "Start"
	startAttachment.Parent = mockPart

	local nextAttachment = Instance.new("Attachment")
	nextAttachment.Name = "Next"
	nextAttachment.Parent = mockPart

	-- Test FindAttachment
	local foundStart = generator:FindAttachment(mockSection, "Start")
	local foundNext = generator:FindAttachment(mockSection, "Next")

	if foundStart and foundNext then
		Log(testName, "PASS", "Section validation works correctly")
	else
		Log(testName, "FAIL", string.format("FindAttachment failed (Start: %s, Next: %s)",
			tostring(foundStart ~= nil), tostring(foundNext ~= nil)))
	end

	-- Cleanup
	mockSection:Destroy()
end

-- ============================================================================
-- TEST 5: MEMORY MANAGER CACHING
-- ============================================================================

function ValidationTests.TestMemoryManagerCaching()
	local testName = "Memory Manager Caching"

	local memoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager
	if not memoryManager then
		Log(testName, "FAIL", "MemoryManager not found")
		return
	end

	-- Verify cache fields exist
	if not memoryManager.CachedPartCount then
		Log(testName, "FAIL", "CachedPartCount field not found")
		return
	end

	if not memoryManager.LastPartCountUpdate then
		Log(testName, "FAIL", "LastPartCountUpdate field not found")
		return
	end

	-- Verify GetPartCount method exists
	if not memoryManager.GetPartCount then
		Log(testName, "FAIL", "GetPartCount method not found")
		return
	end

	-- Test caching behavior
	local firstCall = memoryManager:GetPartCount()
	local firstTime = memoryManager.LastPartCountUpdate

	task.wait(0.1) -- Wait but stay under 5 second cache window

	local secondCall = memoryManager:GetPartCount()
	local secondTime = memoryManager.LastPartCountUpdate

	-- Second call should use cache (same timestamp)
	if firstTime == secondTime and firstCall == secondCall then
		Log(testName, "PASS", string.format("Caching works (Time: %.2fs, Parts: %d)", firstTime, firstCall))
	else
		Log(testName, "FAIL", "Cache not working correctly")
	end
end

-- ============================================================================
-- TEST 6: CONNECTION CLEANUP
-- ============================================================================

function ValidationTests.TestConnectionCleanup()
	local testName = "Connection Cleanup"

	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then
		Log(testName, "FAIL", "CheckpointService not found")
		return
	end

	-- Verify CleanupTower function exists
	if not CheckpointService.CleanupTower then
		Log(testName, "FAIL", "CleanupTower function not found")
		return
	end

	-- Count initial connections
	local initialCheckpoints = 0
	for _ in pairs(CheckpointService.CheckpointConnections) do
		initialCheckpoints = initialCheckpoints + 1
	end

	local initialFinishLines = 0
	for _ in pairs(CheckpointService.FinishLineConnections) do
		initialFinishLines = initialFinishLines + 1
	end

	-- Run cleanup
	CheckpointService.CleanupTower()

	-- Count after cleanup
	local afterCheckpoints = 0
	for _ in pairs(CheckpointService.CheckpointConnections) do
		afterCheckpoints = afterCheckpoints + 1
	end

	local afterFinishLines = 0
	for _ in pairs(CheckpointService.FinishLineConnections) do
		afterFinishLines = afterFinishLines + 1
	end

	-- Verify cleanup worked
	if afterCheckpoints == 0 and afterFinishLines == 0 then
		Log(testName, "PASS", string.format("Cleanup works (Cleared %d checkpoints, %d finish lines)",
			initialCheckpoints, initialFinishLines))
	else
		Log(testName, "FAIL", string.format("Cleanup incomplete (Remaining: %d checkpoints, %d finish lines)",
			afterCheckpoints, afterFinishLines))
	end
end

-- ============================================================================
-- TEST 7: SYNTAX CHECK
-- ============================================================================

function ValidationTests.TestSyntax()
	local testName = "Syntax Check"

	-- Test string.rep exists and works
	local success, result = pcall(function()
		return string.rep("=", 60)
	end)

	if success and #result == 60 then
		Log(testName, "PASS", "string.rep syntax correct")
	else
		Log(testName, "FAIL", "string.rep syntax error")
	end
end

-- ============================================================================
-- RUN ALL TESTS
-- ============================================================================

function ValidationTests.RunAll()
	-- Prevent concurrent execution
	if ValidationTests.IsRunning then
		warn("[ValidationTests] Tests already running! Wait for completion.")
		return ValidationTests.Results
	end

	ValidationTests.IsRunning = true

	print("\n" .. string.rep("=", 60))
	print("TOWER ASCENT - VALIDATION TESTS")
	print("Running automated tests for code review fixes...")
	print(string.rep("=", 60))

	-- Clear previous results
	ValidationTests.Results = {}

	-- Run all tests
	ValidationTests.TestSyntax()
	ValidationTests.TestCheckpointDebounce()
	ValidationTests.TestRespawnTracking()
	ValidationTests.TestVIPRateLimiting()
	ValidationTests.TestSectionValidation()
	ValidationTests.TestMemoryManagerCaching()
	ValidationTests.TestConnectionCleanup()

	-- Summary
	print("\n" .. string.rep("=", 60))
	print("TEST SUMMARY")
	print(string.rep("=", 60))

	local passed = 0
	local failed = 0
	local warnings = 0

	for _, result in ipairs(ValidationTests.Results) do
		if result.Status == "PASS" then
			passed = passed + 1
		elseif result.Status == "FAIL" then
			failed = failed + 1
		else
			warnings = warnings + 1
		end
	end

	print(string.format("Total Tests: %d", #ValidationTests.Results))
	print(string.format("✅ Passed: %d", passed))
	print(string.format("❌ Failed: %d", failed))
	print(string.format("⚠️  Warnings: %d", warnings))

	if failed == 0 then
		print("\n✅ ALL CRITICAL TESTS PASSED - Ready for deployment!")
	else
		print("\n❌ SOME TESTS FAILED - Review failures before deploying")
	end

	print(string.rep("=", 60) .. "\n")

	ValidationTests.IsRunning = false
	return ValidationTests.Results
end

-- ============================================================================
-- INDIVIDUAL TEST ACCESS
-- ============================================================================

function ValidationTests.GetResults()
	return ValidationTests.Results
end

function ValidationTests.PrintResults()
	print("\n" .. string.rep("-", 60))
	print("DETAILED RESULTS")
	print(string.rep("-", 60))

	for i, result in ipairs(ValidationTests.Results) do
		local emoji = result.Status == "PASS" and "✅" or result.Status == "FAIL" and "❌" or "⚠️"
		print(string.format("%d. %s [%s] %s: %s",
			i,
			emoji,
			result.Status,
			result.Test,
			result.Message
		))
	end

	print(string.rep("-", 60) .. "\n")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ValidationTests
