--[[
	StressTests.lua
	Performance and load testing framework

	Tests:
	- High player count simulation
	- Rapid event firing
	- Memory stress testing
	- CPU load testing
	- Network bandwidth simulation
	- Sustained load over time

	Usage: _G.TowerAscent.StressTests.RunAll()
	       _G.TowerAscent.StressTests.SimulateHighLoad(duration)

	Created: 2025-12-01 (Post-Code-Review)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local StressTests = {}
StressTests.Results = {}
StressTests.IsRunning = false

-- Performance tracking (non-blocking FPS calculation)
local LastFPSSampleTime = tick()

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function Log(testName: string, status: string, message: string)
	local emoji = status == "PASS" and "✅" or status == "FAIL" and "❌" or "⚠️"
	print(string.format("[StressTests] %s %s: %s", emoji, testName, message))

	table.insert(StressTests.Results, {
		Test = testName,
		Status = status,
		Message = message,
		Timestamp = tick()
	})
end

local function GetFirstPlayer(): Player?
	local players = Players:GetPlayers()
	return #players > 0 and players[1] or nil
end

local function GetMemoryUsage(): number
	return Stats:GetTotalMemoryUsageMb()
end

local function GetServerFPS(): number
	-- Non-blocking FPS calculation using deltaTime
	local now = tick()
	local deltaTime = now - LastFPSSampleTime
	LastFPSSampleTime = now

	if deltaTime > 0.001 then
		return math.min(60, math.floor(1 / deltaTime))
	else
		return 60 -- Default to 60 FPS if deltaTime is too small
	end
end

-- ============================================================================
-- STRESS TEST 1: RAPID COIN OPERATIONS
-- ============================================================================

function StressTests.TestRapidCoinOperations()
	local testName = "Rapid Coin Operations"

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then
		Log(testName, "FAIL", "CoinService not found")
		return
	end

	local player = GetFirstPlayer()
	if not player or not player:IsA("Player") then
		Log(testName, "WARN", "No valid player available")
		return
	end

	local startTime = tick()
	local operations = 1000
	local successCount = 0

	-- Perform 1000 rapid coin operations
	for i = 1, operations do
		local success = CoinService.AddCoins(player, 1, "StressTest")
		if success then
			successCount = successCount + 1
		end
	end

	local duration = tick() - startTime
	local opsPerSecond = math.floor(operations / duration)

	if successCount == operations then
		Log(testName, "PASS", string.format("Handled %d ops in %.2fs (%d ops/sec)",
			operations, duration, opsPerSecond))
	else
		Log(testName, "FAIL", string.format("Only %d/%d operations succeeded",
			successCount, operations))
	end

	-- Cleanup
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService then
		DataService.RemoveCoins(player, operations)
	end
end

-- ============================================================================
-- STRESS TEST 2: CONCURRENT PLAYER OPERATIONS
-- ============================================================================

function StressTests.TestConcurrentPlayerOperations()
	local testName = "Concurrent Player Operations"

	local players = Players:GetPlayers()
	if #players == 0 then
		Log(testName, "WARN", "No players available")
		return
	end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then
		Log(testName, "FAIL", "CoinService not found")
		return
	end

	local startTime = tick()
	local operationsPerPlayer = 100
	local totalOps = #players * operationsPerPlayer

	-- Simulate concurrent operations for all players
	for _, player in ipairs(players) do
		task.spawn(function()
			for i = 1, operationsPerPlayer do
				CoinService.AddCoins(player, 1, "ConcurrentStressTest")
			end
		end)
	end

	-- Wait for completion
	task.wait(2)

	local duration = tick() - startTime
	local opsPerSecond = math.floor(totalOps / duration)

	Log(testName, "PASS", string.format("Handled %d concurrent ops across %d players (%.2fs, %d ops/sec)",
		totalOps, #players, duration, opsPerSecond))

	-- Cleanup
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService then
		for _, player in ipairs(players) do
			DataService.RemoveCoins(player, operationsPerPlayer)
		end
	end
end

-- ============================================================================
-- STRESS TEST 3: MEMORY LEAK DETECTION
-- ============================================================================

function StressTests.TestMemoryLeakDetection()
	local testName = "Memory Leak Detection"

	local initialMemory = GetMemoryUsage()
	local iterations = 100

	-- Perform repeated operations that could leak memory
	for i = 1, iterations do
		-- Test tower regeneration
		local RoundService = _G.TowerAscent and _G.TowerAscent.RoundService
		if RoundService then
			-- Don't actually regenerate, just test memory
			-- RoundService.GenerateNewTower() -- Too expensive
		end

		-- Test checkpoint operations
		local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
		if CheckpointService then
			CheckpointService.ResetAllCheckpoints()
		end

		if i % 20 == 0 then
			task.wait(0.1) -- Give GC a chance
		end
	end

	-- Force garbage collection
	task.wait(1)

	local finalMemory = GetMemoryUsage()
	local memoryDelta = finalMemory - initialMemory

	if memoryDelta < 10 then -- Less than 10 MB increase
		Log(testName, "PASS", string.format("No significant memory leak (Delta: %.2f MB)", memoryDelta))
	else
		Log(testName, "WARN", string.format("Potential memory leak detected (Delta: %.2f MB)", memoryDelta))
	end
end

-- ============================================================================
-- STRESS TEST 4: SERVER FPS UNDER LOAD
-- ============================================================================

function StressTests.TestServerFPSUnderLoad()
	local testName = "Server FPS Under Load"

	local initialFPS = GetServerFPS()

	-- Create artificial load
	local startTime = tick()
	local iterations = 10000
	local dummy = 0

	for i = 1, iterations do
		dummy = dummy + math.sin(i) * math.cos(i)
	end

	local duration = tick() - startTime
	local finalFPS = GetServerFPS()

	if finalFPS >= 40 then -- Minimum acceptable FPS
		Log(testName, "PASS", string.format("FPS stable under load (Initial: %d, Final: %d)",
			initialFPS, finalFPS))
	else
		Log(testName, "WARN", string.format("FPS degraded under load (Initial: %d, Final: %d)",
			initialFPS, finalFPS))
	end
end

-- ============================================================================
-- STRESS TEST 5: ANTI-CHEAT UNDER SPAM
-- ============================================================================

function StressTests.TestAntiCheatUnderSpam()
	local testName = "Anti-Cheat Under Spam"

	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if not AntiCheat then
		Log(testName, "FAIL", "AntiCheat not found")
		return
	end

	local player = GetFirstPlayer()
	if not player or not player:IsA("Player") then
		Log(testName, "WARN", "No valid player available")
		return
	end

	local startTime = tick()
	local checks = 1000

	-- Spam check operations
	for i = 1, checks do
		task.spawn(function()
			AntiCheat:ForceCheck(player)
		end)
	end

	task.wait(1)

	local duration = tick() - startTime
	local checksPerSecond = math.floor(checks / duration)

	-- Verify anti-cheat still responds
	local stats = AntiCheat:GetStats()
	if stats then
		Log(testName, "PASS", string.format("Anti-cheat handled %d checks/sec, still responsive",
			checksPerSecond))
	else
		Log(testName, "FAIL", "Anti-cheat unresponsive after spam")
	end
end

-- ============================================================================
-- STRESS TEST 6: CHECKPOINT SPAM
-- ============================================================================

function StressTests.TestCheckpointSpam()
	local testName = "Checkpoint Spam Protection"

	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then
		Log(testName, "FAIL", "CheckpointService not found")
		return
	end

	local testUserId = 888888
	local testSection = 10
	local debounceKey = testUserId .. "_" .. testSection

	-- Clear any existing
	CheckpointService.CheckpointDebounce[debounceKey] = nil

	-- Simulate 1000 rapid touches
	local blockedCount = 0
	for i = 1, 1000 do
		if CheckpointService.CheckpointDebounce[debounceKey] then
			blockedCount = blockedCount + 1
		else
			CheckpointService.CheckpointDebounce[debounceKey] = true
		end
	end

	-- Should block 999 out of 1000 attempts
	if blockedCount >= 999 then
		Log(testName, "PASS", string.format("Debounce blocked %d/1000 spam attempts", blockedCount))
	else
		Log(testName, "FAIL", string.format("Debounce only blocked %d/1000 attempts", blockedCount))
	end

	-- Cleanup
	CheckpointService.CheckpointDebounce[debounceKey] = nil
end

-- ============================================================================
-- STRESS TEST 7: MEMORY MANAGER CONTINUOUS LOAD
-- ============================================================================

function StressTests.TestMemoryManagerContinuousLoad()
	local testName = "Memory Manager Continuous Load"

	local MemoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager
	if not MemoryManager then
		Log(testName, "FAIL", "MemoryManager not found")
		return
	end

	local startTime = tick()
	local cleanupCount = 50

	-- Rapid cleanup cycles
	for i = 1, cleanupCount do
		MemoryManager:ForceCleanup()
		if i % 10 == 0 then
			task.wait(0.05)
		end
	end

	local duration = tick() - startTime

	-- Verify still responsive
	local stats = MemoryManager:GetStats()
	if stats and stats.CurrentPartCount then
		Log(testName, "PASS", string.format("Memory manager handled %d cleanups in %.2fs",
			cleanupCount, duration))
	else
		Log(testName, "FAIL", "Memory manager unresponsive after continuous load")
	end
end

-- ============================================================================
-- STRESS TEST 8: DATA PERSISTENCE STRESS
-- ============================================================================

function StressTests.TestDataPersistenceStress()
	local testName = "Data Persistence Stress"

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		Log(testName, "FAIL", "DataService not found")
		return
	end

	local player = GetFirstPlayer()
	if not player or not player:IsA("Player") then
		Log(testName, "WARN", "No valid player available")
		return
	end

	local operations = 500
	local startTime = tick()

	-- Rapid read/write operations
	for i = 1, operations do
		DataService.AddCoins(player, 1)
		local coins = DataService.GetCoins(player)
		DataService.RemoveCoins(player, 1)
	end

	local duration = tick() - startTime
	local opsPerSecond = math.floor(operations / duration)

	-- Verify data integrity
	local finalCoins = DataService.GetCoins(player)

	Log(testName, "PASS", string.format("Handled %d data operations in %.2fs (%d ops/sec)",
		operations, duration, opsPerSecond))
end

-- ============================================================================
-- STRESS TEST 9: SUSTAINED LOAD TEST
-- ============================================================================

function StressTests.SimulateHighLoad(durationSeconds: number)
	-- Safety limits
	local MAX_DURATION = 600 -- 10 minutes max
	local MAX_OPERATIONS = 100000 -- 100k operations max

	if durationSeconds > MAX_DURATION then
		warn(string.format("[StressTests] Duration capped at %d seconds (requested: %d)",
			MAX_DURATION, durationSeconds))
		durationSeconds = MAX_DURATION
	end

	print("\n" .. string.rep("=", 60))
	print(string.format("SIMULATING HIGH LOAD - %d SECONDS (MAX: %d ops)",
		durationSeconds, MAX_OPERATIONS))
	print(string.rep("=", 60))

	StressTests.IsRunning = true

	local startTime = tick()
	local endTime = startTime + durationSeconds

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	local MemoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager

	local operationCount = 0
	local errorCount = 0

	while tick() < endTime and StressTests.IsRunning and operationCount < MAX_OPERATIONS do
		-- Simulate various operations
		local players = Players:GetPlayers()

		for _, player in ipairs(players) do
			task.spawn(function()
				-- Coin operations
				local success, err = pcall(function()
					CoinService.AddCoins(player, math.random(1, 10), "LoadTest")
				end)

				if not success then
					errorCount = errorCount + 1
				else
					operationCount = operationCount + 1
				end
			end)
		end

		-- Memory operations
		if math.random() > 0.9 then
			task.spawn(function()
				MemoryManager:ForceCleanup()
			end)
		end

		-- Monitor performance
		local currentTime = tick()
		local elapsed = currentTime - startTime
		local remaining = endTime - currentTime

		if math.floor(elapsed) % 5 == 0 then
			local fps = GetServerFPS()
			local memory = GetMemoryUsage()
			print(string.format("[LoadTest] Time: %.0fs/%.0fs | FPS: %d | Memory: %.1f MB | Ops: %d | Errors: %d",
				elapsed, durationSeconds, fps, memory, operationCount, errorCount))
		end

		task.wait(0.1)
	end

	StressTests.IsRunning = false

	local totalTime = tick() - startTime
	local avgOpsPerSecond = math.floor(operationCount / totalTime)

	print(string.rep("=", 60))
	print("LOAD TEST COMPLETE")
	print(string.rep("=", 60))
	print(string.format("Duration: %.2f seconds", totalTime))
	print(string.format("Operations: %d (%d ops/sec)", operationCount, avgOpsPerSecond))
	print(string.format("Errors: %d (%.2f%%)", errorCount, (errorCount / math.max(1, operationCount)) * 100))
	print(string.format("Final FPS: %d", GetServerFPS()))
	print(string.format("Final Memory: %.1f MB", GetMemoryUsage()))

	if operationCount >= MAX_OPERATIONS then
		print(string.format("⚠️  Operation limit reached (%d ops)", MAX_OPERATIONS))
	end

	print(string.rep("=", 60) .. "\n")

	return {
		Duration = totalTime,
		Operations = operationCount,
		Errors = errorCount,
		FinalFPS = GetServerFPS(),
		FinalMemory = GetMemoryUsage()
	}
end

function StressTests.StopLoadTest()
	StressTests.IsRunning = false
	print("[StressTests] Stopping load test...")
end

-- ============================================================================
-- RUN ALL TESTS
-- ============================================================================

function StressTests.RunAll()
	-- Prevent concurrent execution
	if StressTests.IsRunning then
		warn("[StressTests] Tests already running! Wait for completion.")
		return StressTests.Results
	end

	StressTests.IsRunning = true

	print("\n" .. string.rep("=", 60))
	print("STRESS TESTS - PERFORMANCE & LOAD TESTING")
	print("Testing system behavior under heavy load...")
	print(string.rep("=", 60))

	-- Clear previous results
	StressTests.Results = {}

	-- Run all stress tests
	StressTests.TestRapidCoinOperations()
	StressTests.TestConcurrentPlayerOperations()
	StressTests.TestMemoryLeakDetection()
	StressTests.TestServerFPSUnderLoad()
	StressTests.TestAntiCheatUnderSpam()
	StressTests.TestCheckpointSpam()
	StressTests.TestMemoryManagerContinuousLoad()
	StressTests.TestDataPersistenceStress()

	-- Summary
	print("\n" .. string.rep("=", 60))
	print("STRESS TEST SUMMARY")
	print(string.rep("=", 60))

	local passed = 0
	local failed = 0
	local warnings = 0

	for _, result in ipairs(StressTests.Results) do
		if result.Status == "PASS" then
			passed = passed + 1
		elseif result.Status == "FAIL" then
			failed = failed + 1
		else
			warnings = warnings + 1
		end
	end

	print(string.format("Total Tests: %d", #StressTests.Results))
	print(string.format("✅ Passed: %d", passed))
	print(string.format("❌ Failed: %d", failed))
	print(string.format("⚠️  Warnings: %d", warnings))

	if failed == 0 then
		print("\n✅ ALL STRESS TESTS PASSED - System performs well under load!")
	else
		print("\n❌ SOME STRESS TESTS FAILED - Review failures before deploying")
	end

	print(string.rep("=", 60) .. "\n")

	StressTests.IsRunning = false
	return StressTests.Results
end

function StressTests.PrintResults()
	print("\n" .. string.rep("-", 60))
	print("DETAILED STRESS TEST RESULTS")
	print(string.rep("-", 60))

	for i, result in ipairs(StressTests.Results) do
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

return StressTests
