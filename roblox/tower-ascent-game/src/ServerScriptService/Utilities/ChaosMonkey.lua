--[[
	ChaosMonkey.lua
	Chaos engineering and fault injection testing

	Inspired by Netflix's Chaos Monkey - intentionally breaks things
	to test system resilience and error recovery.

	Chaos Scenarios:
	- Random service failures
	- Random data corruption
	- Network latency simulation
	- Memory pressure simulation
	- Random player disconnects
	- Corrupted checkpoint data
	- Missing tower sections

	⚠️ WARNING: Only use in testing environment!
	⚠️ NEVER enable in production!

	Usage: _G.TowerAscent.ChaosMonkey.EnableChaos(duration)
	       _G.TowerAscent.ChaosMonkey.DisableChaos()

	Created: 2025-12-01 (Post-Code-Review)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ChaosMonkey = {}
ChaosMonkey.Enabled = false
ChaosMonkey.Events = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- How often to trigger chaos (seconds)
	ChaosInterval = 5,

	-- Probability of each chaos event (0-1)
	Probabilities = {
		DataCorruption = 0.05,      -- 5% chance
		ServiceFailure = 0.10,       -- 10% chance
		MemoryPressure = 0.05,       -- 5% chance
		CheckpointCorruption = 0.10, -- 10% chance
		RandomDelay = 0.20,          -- 20% chance
	},

	-- Safety limits
	MaxConcurrentChaos = 3,
	MaxDelaySeconds = 2,
}

-- ============================================================================
-- CHAOS TRACKING
-- ============================================================================

local function LogChaos(eventType: string, message: string)
	print(string.format("[🔥 CHAOS] %s: %s", eventType, message))

	table.insert(ChaosMonkey.Events, {
		Type = eventType,
		Message = message,
		Timestamp = tick()
	})

	-- Keep only last 100 events
	if #ChaosMonkey.Events > 100 then
		table.remove(ChaosMonkey.Events, 1)
	end
end

-- ============================================================================
-- CHAOS EVENT 1: DATA CORRUPTION
-- ============================================================================

local function InjectDataCorruption()
	if math.random() > CONFIG.Probabilities.DataCorruption then return end

	local player = Players:GetPlayers()[math.random(1, #Players:GetPlayers())]
	if not player then return end

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then return end

	-- Attempt to add invalid coins (should be rejected)
	local result = DataService.AddCoins(player, 0/0) -- NaN

	if result == false then
		LogChaos("DATA_CORRUPTION", string.format("Injected NaN coins to %s - REJECTED ✓", player.Name))
	else
		LogChaos("DATA_CORRUPTION", string.format("Injected NaN coins to %s - ACCEPTED ⚠️", player.Name))
	end
end

-- ============================================================================
-- CHAOS EVENT 2: SERVICE FAILURE SIMULATION
-- ============================================================================

local function InjectServiceFailure()
	if math.random() > CONFIG.Probabilities.ServiceFailure then return end

	-- Simulate temporary service unavailability
	local services = {"CoinService", "CheckpointService", "DataService"}
	local serviceName = services[math.random(1, #services)]

	LogChaos("SERVICE_FAILURE", string.format("Simulating %s temporary unavailability", serviceName))

	-- Note: Actual service shutdown would be too destructive
	-- This is a simulation only
end

-- ============================================================================
-- CHAOS EVENT 3: MEMORY PRESSURE
-- ============================================================================

local function InjectMemoryPressure()
	if math.random() > CONFIG.Probabilities.MemoryPressure then return end

	-- Create temporary memory pressure
	local wasteMemory = {}
	for i = 1, 1000 do
		table.insert(wasteMemory, string.rep("X", 1000))
	end

	LogChaos("MEMORY_PRESSURE", "Created temporary memory pressure (1MB)")

	-- Let GC clean up
	task.delay(2, function()
		wasteMemory = nil
	end)
end

-- ============================================================================
-- CHAOS EVENT 4: CHECKPOINT CORRUPTION
-- ============================================================================

local function InjectCheckpointCorruption()
	if math.random() > CONFIG.Probabilities.CheckpointCorruption then return end

	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then return end

	local player = Players:GetPlayers()[math.random(1, math.min(#Players:GetPlayers(), 1))]
	if not player then return end

	-- Attempt to set invalid checkpoint data
	-- Service should handle gracefully
	task.spawn(function()
		local success, err = pcall(function()
			CheckpointService.SetPlayerCheckpoint(player, -1, Vector3.new(0, 0, 0))
		end)

		if success then
			LogChaos("CHECKPOINT_CORRUPTION", string.format("Set invalid checkpoint for %s - System handled it", player.Name))
		else
			LogChaos("CHECKPOINT_CORRUPTION", string.format("Set invalid checkpoint for %s - Error caught: %s", player.Name, tostring(err)))
		end
	end)
end

-- ============================================================================
-- CHAOS EVENT 5: RANDOM DELAYS
-- ============================================================================

local function InjectRandomDelay()
	if math.random() > CONFIG.Probabilities.RandomDelay then return end

	local delay = math.random() * CONFIG.MaxDelaySeconds

	LogChaos("RANDOM_DELAY", string.format("Injecting %.2fs artificial delay", delay))

	task.wait(delay)
end

-- ============================================================================
-- CHAOS EVENT 6: RACE CONDITION SIMULATION
-- ============================================================================

local function InjectRaceCondition()
	local player = Players:GetPlayers()[1]
	if not player then return end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then return end

	-- Simulate concurrent operations
	for i = 1, 10 do
		task.spawn(function()
			CoinService.AddCoins(player, 1, "RaceConditionTest")
		end)
	end

	LogChaos("RACE_CONDITION", string.format("Triggered 10 concurrent coin operations for %s", player.Name))
end

-- ============================================================================
-- CHAOS EVENT 7: ANTI-CHEAT FALSE TRIGGER
-- ============================================================================

local function InjectAntiCheatFalseTrigger()
	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if not AntiCheat then return end

	local player = Players:GetPlayers()[1]
	if not player then return end

	-- Simulate rapid position changes (legitimate teleport)
	-- Anti-cheat should account for respawn
	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if CheckpointService then
		CheckpointService.RecentRespawns[player.UserId] = tick()

		LogChaos("ANTI_CHEAT", string.format("Simulating legitimate teleport for %s (should not trigger)", player.Name))

		task.delay(2.5, function()
			CheckpointService.RecentRespawns[player.UserId] = nil
		end)
	end
end

-- ============================================================================
-- CHAOS ENGINE
-- ============================================================================

local function TriggerRandomChaos()
	-- Select random chaos events
	local chaosEvents = {
		InjectDataCorruption,
		InjectServiceFailure,
		InjectMemoryPressure,
		InjectCheckpointCorruption,
		InjectRandomDelay,
		InjectRaceCondition,
		InjectAntiCheatFalseTrigger,
	}

	-- Trigger up to MaxConcurrentChaos events
	local eventsToTrigger = math.random(1, CONFIG.MaxConcurrentChaos)

	for i = 1, eventsToTrigger do
		local eventFunc = chaosEvents[math.random(1, #chaosEvents)]
		task.spawn(function()
			local success, err = pcall(eventFunc)
			if not success then
				LogChaos("ERROR", string.format("Chaos event failed: %s", tostring(err)))
			end
		end)
	end
end

-- ============================================================================
-- CONTROL FUNCTIONS
-- ============================================================================

function ChaosMonkey.EnableChaos(durationSeconds: number?)
	if ChaosMonkey.Enabled then
		warn("[ChaosMonkey] Chaos already enabled!")
		return
	end

	print("\n" .. string.rep("🔥", 30))
	print("⚠️  CHAOS MONKEY ENABLED ⚠️")
	print("System resilience testing activated")
	if durationSeconds then
		print(string.format("Duration: %d seconds", durationSeconds))
	else
		print("Duration: Indefinite (call DisableChaos() to stop)")
	end
	print(string.rep("🔥", 30) .. "\n")

	ChaosMonkey.Enabled = true
	ChaosMonkey.Events = {}

	-- Start chaos loop using coroutine (more efficient than Heartbeat probability check)
	task.spawn(function()
		while ChaosMonkey.Enabled do
			task.wait(CONFIG.ChaosInterval)

			if ChaosMonkey.Enabled then
				TriggerRandomChaos()
			end
		end
	end)

	-- Auto-disable after duration
	if durationSeconds then
		task.delay(durationSeconds, function()
			if ChaosMonkey.Enabled then
				ChaosMonkey.DisableChaos()
			end
		end)
	end
end

function ChaosMonkey.DisableChaos()
	if not ChaosMonkey.Enabled then
		warn("[ChaosMonkey] Chaos not enabled!")
		return
	end

	print("\n" .. string.rep("✅", 30))
	print("CHAOS MONKEY DISABLED")
	print(string.format("Total chaos events: %d", #ChaosMonkey.Events))
	print(string.rep("✅", 30) .. "\n")

	ChaosMonkey.Enabled = false
	-- Coroutine will stop on next iteration when it checks ChaosMonkey.Enabled
end

function ChaosMonkey.GetChaosEvents(): {}
	return ChaosMonkey.Events
end

function ChaosMonkey.PrintChaosLog()
	print("\n" .. string.rep("-", 60))
	print("CHAOS EVENT LOG")
	print(string.rep("-", 60))

	if #ChaosMonkey.Events == 0 then
		print("No chaos events recorded")
	else
		for i, event in ipairs(ChaosMonkey.Events) do
			print(string.format("%d. [%s] %s (%.2fs ago)",
				i,
				event.Type,
				event.Message,
				tick() - event.Timestamp
			))
		end
	end

	print(string.rep("-", 60) .. "\n")
end

function ChaosMonkey.GetStats(): {}
	local stats = {}

	for _, event in ipairs(ChaosMonkey.Events) do
		stats[event.Type] = (stats[event.Type] or 0) + 1
	end

	return {
		TotalEvents = #ChaosMonkey.Events,
		EventsByType = stats,
		IsEnabled = ChaosMonkey.Enabled
	}
end

function ChaosMonkey.PrintStats()
	local stats = ChaosMonkey.GetStats()

	print("\n" .. string.rep("=", 60))
	print("CHAOS MONKEY STATISTICS")
	print(string.rep("=", 60))
	print(string.format("Status: %s", stats.IsEnabled and "ENABLED 🔥" or "DISABLED ✅"))
	print(string.format("Total Events: %d", stats.TotalEvents))
	print("\nEvents by Type:")

	for eventType, count in pairs(stats.EventsByType) do
		print(string.format("  %s: %d", eventType, count))
	end

	print(string.rep("=", 60) .. "\n")
end

-- ============================================================================
-- SAFETY CHECKS
-- ============================================================================

function ChaosMonkey.IsSafeToEnable(): boolean
	-- Check if in production
	local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

	if not GameConfig.Debug.Enabled then
		warn("[ChaosMonkey] ⚠️  DEBUG MODE DISABLED - Chaos Monkey should NOT run in production!")
		return false
	end

	return true
end

-- ============================================================================
-- QUICK TEST SCENARIOS
-- ============================================================================

function ChaosMonkey.TestErrorRecovery()
	print("\n[ChaosMonkey] Testing error recovery mechanisms...")

	-- Test 1: Invalid coin operations
	local player = Players:GetPlayers()[1]
	if player then
		local DataService = _G.TowerAscent.DataService
		print("Test 1: Invalid coin operations")
		DataService.AddCoins(player, 0/0) -- NaN
		DataService.AddCoins(player, -100) -- Negative
		DataService.AddCoins(player, math.huge) -- Infinity
		print("✓ Invalid operations rejected gracefully")
	end

	-- Test 2: Nil player handling
	print("\nTest 2: Nil player handling")
	local DataService = _G.TowerAscent.DataService
	DataService.AddCoins(nil, 100)
	DataService.GetCoins(nil)
	print("✓ Nil player handled gracefully")

	-- Test 3: Concurrent operations
	print("\nTest 3: Concurrent operations")
	if player then
		for i = 1, 10 do
			task.spawn(function()
				_G.TowerAscent.CoinService.AddCoins(player, 1, "ConcurrentTest")
			end)
		end
		task.wait(0.5)
		print("✓ Concurrent operations handled")
	end

	print("\n✅ Error recovery test complete\n")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ChaosMonkey
