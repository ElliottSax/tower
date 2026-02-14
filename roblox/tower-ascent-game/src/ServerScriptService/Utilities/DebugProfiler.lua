--[[
	DebugProfiler.lua
	Real-time performance monitoring and profiling

	Features:
	- CPU profiling per service
	- Memory usage tracking
	- FPS monitoring
	- Network statistics
	- Performance bottleneck detection
	- Historical data tracking
	- Real-time dashboard

	Usage:
	   DebugProfiler.Start()
	   DebugProfiler.ProfileFunction("ServiceName", function() ... end)
	   DebugProfiler.PrintDashboard()

	Created: 2025-12-01 (Post-Testing-Infrastructure)
--]]

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")

local DebugProfiler = {}
DebugProfiler.Enabled = false
DebugProfiler.Profiles = {} -- [ServiceName] = {TotalTime, CallCount, ...}
DebugProfiler.PerformanceHistory = {}
DebugProfiler.MemorySnapshots = {}
DebugProfiler.HeartbeatConnection = nil
DebugProfiler.LoggedMissingCategories = false

-- Circular buffer for performance history (prevents O(n) removal)
DebugProfiler.HistoryIndex = 1
DebugProfiler.HistorySize = 0
DebugProfiler.MaxHistorySize = 300 -- Will be recalculated based on config

-- Circular buffer for memory snapshots (prevents O(n) table.remove)
DebugProfiler.MemorySnapshotIndex = 1
DebugProfiler.MemorySnapshotSize = 0
DebugProfiler.MaxMemorySnapshots = 30

-- Performance tracking
local LastSampleTime = tick()
local LastFrameTime = 0

-- Part count caching (consistent with MemoryManager)
local CachedPartCount = 0
local LastPartCountUpdate = 0
local PART_COUNT_CACHE_DURATION = 5 -- seconds

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Sampling intervals
	SampleInterval = 1, -- seconds
	HistoryDuration = 300, -- 5 minutes
	MemorySnapshotInterval = 10, -- seconds

	-- Thresholds for warnings
	MaxFrameTime = 16.67, -- 60 FPS = 16.67ms per frame
	MaxMemoryMB = 300,
	MaxCPUPercent = 10,

	-- Display
	DashboardUpdateInterval = 5,
}

-- ============================================================================
-- PROFILING DATA STRUCTURES
-- ============================================================================

local function InitializeProfile(serviceName: string)
	if not DebugProfiler.Profiles[serviceName] then
		DebugProfiler.Profiles[serviceName] = {
			TotalTime = 0,
			CallCount = 0,
			AverageTime = 0,
			MinTime = math.huge,
			MaxTime = 0,
			LastCallTime = 0,
			Errors = 0
		}
	end
end

-- ============================================================================
-- FUNCTION PROFILING
-- ============================================================================

function DebugProfiler.ProfileFunction(serviceName: string, func: () -> any): any
	InitializeProfile(serviceName)

	local profile = DebugProfiler.Profiles[serviceName]
	local startTime = os.clock()
	local success, result = pcall(func)
	local elapsed = (os.clock() - startTime) * 1000 -- Convert to milliseconds

	-- Update profile stats
	profile.CallCount = profile.CallCount + 1
	profile.TotalTime = profile.TotalTime + elapsed
	profile.AverageTime = profile.TotalTime / profile.CallCount
	profile.MinTime = math.min(profile.MinTime, elapsed)
	profile.MaxTime = math.max(profile.MaxTime, elapsed)
	profile.LastCallTime = elapsed

	if not success then
		profile.Errors = profile.Errors + 1
		error(result)
	end

	-- Warn on slow operations
	if elapsed > CONFIG.MaxFrameTime then
		warn(string.format("[DebugProfiler] SLOW: %s took %.2fms (threshold: %.2fms)",
			serviceName, elapsed, CONFIG.MaxFrameTime))
	end

	return result
end

-- ============================================================================
-- PERFORMANCE SAMPLING
-- ============================================================================

local function GetCachedPartCount(): number
	local now = tick()

	if now - LastPartCountUpdate >= PART_COUNT_CACHE_DURATION then
		CachedPartCount = #workspace:GetDescendants()
		LastPartCountUpdate = now
	end

	return CachedPartCount
end

local function SamplePerformance()
	local now = tick()
	local deltaTime = now - LastSampleTime
	LastSampleTime = now

	-- Non-blocking FPS calculation using deltaTime
	local fps = 60 -- Default fallback
	if deltaTime > 0.001 then
		fps = math.floor(1 / deltaTime)
	end

	local sample = {
		Timestamp = now,
		FPS = math.min(fps, 60), -- Cap at 60 for reasonable values
		Memory = Stats:GetTotalMemoryUsageMb(),
		PlayerCount = #Players:GetPlayers(),
		PartCount = GetCachedPartCount(), -- Use cached value
	}

	-- Get detailed stats
	if Stats:FindFirstChild("PerformanceStats") then
		sample.CPU = Stats.PerformanceStats.CPU:GetValue()
		sample.Physics = Stats.PerformanceStats.Physics:GetValue()
		sample.Render = Stats.PerformanceStats.Render:GetValue()
	end

	-- Use circular buffer to avoid O(n) operations
	DebugProfiler.MaxHistorySize = math.floor(CONFIG.HistoryDuration / CONFIG.SampleInterval)

	-- Add sample to circular buffer
	DebugProfiler.PerformanceHistory[DebugProfiler.HistoryIndex] = sample
	DebugProfiler.HistoryIndex = (DebugProfiler.HistoryIndex % DebugProfiler.MaxHistorySize) + 1
	DebugProfiler.HistorySize = math.min(DebugProfiler.HistorySize + 1, DebugProfiler.MaxHistorySize)

	-- Check thresholds
	if sample.Memory > CONFIG.MaxMemoryMB then
		warn(string.format("[DebugProfiler] HIGH MEMORY: %.1f MB (threshold: %d MB)",
			sample.Memory, CONFIG.MaxMemoryMB))
	end

	return sample
end

-- ============================================================================
-- MEMORY PROFILING
-- ============================================================================

local function TakeMemorySnapshot()
	local snapshot = {
		Timestamp = tick(),
		TotalMemory = Stats:GetTotalMemoryUsageMb(),
		Breakdown = {}
	}

	-- Get memory breakdown by category
	local memoryCategories = {
		"InstanceCount",
		"PhysicsSteppingMemory",
		"GraphicsMemory",
		"ScriptMemory",
		"AnimationMemory"
	}

	local missingCategories = {}

	for _, category in ipairs(memoryCategories) do
		local stat = Stats:FindFirstChild(category)
		if stat then
			snapshot.Breakdown[category] = stat:GetValue()
		else
			table.insert(missingCategories, category)
			snapshot.Breakdown[category] = 0 -- Default value
		end
	end

	-- Log missing categories once
	if #missingCategories > 0 and not DebugProfiler.LoggedMissingCategories then
		warn(string.format("[DebugProfiler] Missing memory categories: %s",
			table.concat(missingCategories, ", ")))
		DebugProfiler.LoggedMissingCategories = true
	end

	-- Use circular buffer to avoid O(n) table.remove
	DebugProfiler.MemorySnapshots[DebugProfiler.MemorySnapshotIndex] = snapshot
	DebugProfiler.MemorySnapshotIndex = (DebugProfiler.MemorySnapshotIndex % DebugProfiler.MaxMemorySnapshots) + 1
	DebugProfiler.MemorySnapshotSize = math.min(DebugProfiler.MemorySnapshotSize + 1, DebugProfiler.MaxMemorySnapshots)

	return snapshot
end

-- ============================================================================
-- BOTTLENECK DETECTION
-- ============================================================================

function DebugProfiler.DetectBottlenecks(): {}
	local bottlenecks = {}

	-- Check function profiles
	for serviceName, profile in pairs(DebugProfiler.Profiles) do
		-- Slow average time
		if profile.AverageTime > CONFIG.MaxFrameTime then
			table.insert(bottlenecks, {
				Type = "SLOW_FUNCTION",
				Service = serviceName,
				AverageTime = profile.AverageTime,
				CallCount = profile.CallCount,
				Severity = "HIGH"
			})
		end

		-- Frequent slow calls
		if profile.CallCount > 100 and profile.MaxTime > 50 then
			table.insert(bottlenecks, {
				Type = "FREQUENT_SLOW_CALLS",
				Service = serviceName,
				MaxTime = profile.MaxTime,
				CallCount = profile.CallCount,
				Severity = "MEDIUM"
			})
		end

		-- High error rate
		if profile.Errors > 0 and profile.Errors / profile.CallCount > 0.05 then
			table.insert(bottlenecks, {
				Type = "HIGH_ERROR_RATE",
				Service = serviceName,
				ErrorRate = (profile.Errors / profile.CallCount) * 100,
				Severity = "HIGH"
			})
		end
	end

	-- Check performance history
	if DebugProfiler.HistorySize > 10 then
		local recentSamples = {}
		local startIdx = math.max(1, DebugProfiler.HistorySize - 9)
		for i = startIdx, DebugProfiler.HistorySize do
			local sample = DebugProfiler.PerformanceHistory[i]
			if sample then
				table.insert(recentSamples, sample)
			end
		end

		-- Calculate average FPS
		local totalFPS = 0
		for _, sample in ipairs(recentSamples) do
			totalFPS = totalFPS + sample.FPS
		end
		local avgFPS = totalFPS / #recentSamples

		if avgFPS < 50 then
			table.insert(bottlenecks, {
				Type = "LOW_FPS",
				AverageFPS = avgFPS,
				Severity = "HIGH"
			})
		end

		-- Check memory growth
		local firstMemory = recentSamples[1].Memory
		local lastMemory = recentSamples[#recentSamples].Memory
		local memoryGrowth = lastMemory - firstMemory

		if memoryGrowth > 50 then
			table.insert(bottlenecks, {
				Type = "MEMORY_LEAK",
				GrowthMB = memoryGrowth,
				Duration = recentSamples[#recentSamples].Timestamp - recentSamples[1].Timestamp,
				Severity = "HIGH"
			})
		end
	end

	return bottlenecks
end

-- ============================================================================
-- DASHBOARD AND REPORTING
-- ============================================================================

function DebugProfiler.PrintDashboard()
	print("\n" .. string.rep("=", 70))
	print("DEBUG PROFILER DASHBOARD")
	print(string.rep("=", 70))

	-- Current performance
	-- Get most recent sample from circular buffer
	local currentSample = nil
	if DebugProfiler.HistorySize > 0 then
		local lastIndex = ((DebugProfiler.HistoryIndex - 2) % DebugProfiler.MaxHistorySize) + 1
		currentSample = DebugProfiler.PerformanceHistory[lastIndex]
	end
	if currentSample then
		print(string.format("FPS: %d | Memory: %.1f MB | Players: %d | Parts: %d",
			currentSample.FPS,
			currentSample.Memory,
			currentSample.PlayerCount,
			currentSample.PartCount))
	end

	-- Top 10 slowest services
	print("\n" .. string.rep("-", 70))
	print("TOP 10 SLOWEST SERVICES (by average time)")
	print(string.rep("-", 70))

	local sortedProfiles = {}
	for serviceName, profile in pairs(DebugProfiler.Profiles) do
		table.insert(sortedProfiles, {Name = serviceName, Profile = profile})
	end

	table.sort(sortedProfiles, function(a, b)
		return a.Profile.AverageTime > b.Profile.AverageTime
	end)

	for i = 1, math.min(10, #sortedProfiles) do
		local entry = sortedProfiles[i]
		local profile = entry.Profile

		local emoji = profile.AverageTime > CONFIG.MaxFrameTime and "🔴" or
					  profile.AverageTime > CONFIG.MaxFrameTime * 0.5 and "🟡" or "🟢"

		print(string.format("%s %d. %s: Avg %.2fms | Calls: %d | Max: %.2fms | Errors: %d",
			emoji,
			i,
			entry.Name,
			profile.AverageTime,
			profile.CallCount,
			profile.MaxTime,
			profile.Errors))
	end

	-- Bottlenecks
	local bottlenecks = DebugProfiler.DetectBottlenecks()
	if #bottlenecks > 0 then
		print("\n" .. string.rep("-", 70))
		print("⚠️  BOTTLENECKS DETECTED")
		print(string.rep("-", 70))

		for i, bottleneck in ipairs(bottlenecks) do
			if bottleneck.Type == "SLOW_FUNCTION" then
				print(string.format("%d. [%s] %s: %.2fms average (%d calls)",
					i, bottleneck.Severity, bottleneck.Service, bottleneck.AverageTime, bottleneck.CallCount))
			elseif bottleneck.Type == "LOW_FPS" then
				print(string.format("%d. [%s] Low server FPS: %.1f average",
					i, bottleneck.Severity, bottleneck.AverageFPS))
			elseif bottleneck.Type == "MEMORY_LEAK" then
				print(string.format("%d. [%s] Potential memory leak: +%.1f MB in %.1fs",
					i, bottleneck.Severity, bottleneck.GrowthMB, bottleneck.Duration))
			elseif bottleneck.Type == "HIGH_ERROR_RATE" then
				print(string.format("%d. [%s] %s: %.1f%% error rate",
					i, bottleneck.Severity, bottleneck.Service, bottleneck.ErrorRate))
			end
		end
	else
		print("\n✅ No bottlenecks detected")
	end

	-- Memory breakdown
	if DebugProfiler.MemorySnapshotSize > 0 then
		-- Get most recent snapshot from circular buffer
		local latestIdx = ((DebugProfiler.MemorySnapshotIndex - 2) % DebugProfiler.MaxMemorySnapshots) + 1
		local latest = DebugProfiler.MemorySnapshots[latestIdx]
		print("\n" .. string.rep("-", 70))
		print("MEMORY BREAKDOWN")
		print(string.rep("-", 70))
		print(string.format("Total: %.1f MB", latest.TotalMemory))

		for category, value in pairs(latest.Breakdown) do
			print(string.format("  %s: %.1f MB", category, value))
		end
	end

	print(string.rep("=", 70) .. "\n")
end

function DebugProfiler.GetStats(): {}
	local stats = {
		Profiles = {},
		CurrentPerformance = {},
		Bottlenecks = DebugProfiler.DetectBottlenecks(),
		IsEnabled = DebugProfiler.Enabled
	}

	-- Copy profiles
	for serviceName, profile in pairs(DebugProfiler.Profiles) do
		stats.Profiles[serviceName] = {
			AverageTime = profile.AverageTime,
			CallCount = profile.CallCount,
			MaxTime = profile.MaxTime,
			Errors = profile.Errors
		}
	end

	-- Current performance
	if DebugProfiler.HistorySize > 0 then
		local lastIndex = ((DebugProfiler.HistoryIndex - 2) % DebugProfiler.MaxHistorySize) + 1
		stats.CurrentPerformance = DebugProfiler.PerformanceHistory[lastIndex]
	end

	return stats
end

function DebugProfiler.ExportCSV(): string
	local csv = "Timestamp,FPS,Memory,Players,Parts\n"

	-- Export from circular buffer
	for i = 1, DebugProfiler.HistorySize do
		local sample = DebugProfiler.PerformanceHistory[i]
		if sample then
			csv = csv .. string.format("%d,%.1f,%.1f,%d,%d\n",
				sample.Timestamp,
				sample.FPS,
				sample.Memory,
				sample.PlayerCount,
				sample.PartCount)
		end
	end

	return csv
end

-- ============================================================================
-- SERVICE-SPECIFIC PROFILING
-- ============================================================================

function DebugProfiler.ProfileService(serviceName: string, service: {})
	-- Wrap all functions in the service with profiling
	local wrappedService = {}

	for key, value in pairs(service) do
		if type(value) == "function" then
			wrappedService[key] = function(...)
				return DebugProfiler.ProfileFunction(serviceName .. "." .. key, function()
					return value(...)
				end)
			end
		else
			wrappedService[key] = value
		end
	end

	return wrappedService
end

-- ============================================================================
-- CONTROL FUNCTIONS
-- ============================================================================

function DebugProfiler.Start()
	if DebugProfiler.Enabled then
		warn("[DebugProfiler] Already running")
		return
	end

	print("\n" .. string.rep("🔍", 30))
	print("DEBUG PROFILER STARTED")
	print("Performance monitoring active")
	print(string.rep("🔍", 30) .. "\n")

	DebugProfiler.Enabled = true
	DebugProfiler.Profiles = {}
	DebugProfiler.PerformanceHistory = {}
	DebugProfiler.MemorySnapshots = {}
	DebugProfiler.HistoryIndex = 1
	DebugProfiler.HistorySize = 0
	DebugProfiler.MemorySnapshotIndex = 1
	DebugProfiler.MemorySnapshotSize = 0

	-- Start sampling
	local lastSample = tick()
	local lastMemorySnapshot = tick()
	local lastDashboard = tick()

	DebugProfiler.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		local now = tick()

		-- Performance sampling
		if now - lastSample >= CONFIG.SampleInterval then
			SamplePerformance()
			lastSample = now
		end

		-- Memory snapshots
		if now - lastMemorySnapshot >= CONFIG.MemorySnapshotInterval then
			TakeMemorySnapshot()
			lastMemorySnapshot = now
		end

		-- Auto dashboard
		if now - lastDashboard >= CONFIG.DashboardUpdateInterval then
			-- Optional: Auto-print dashboard
			-- DebugProfiler.PrintDashboard()
			lastDashboard = now
		end
	end)
end

function DebugProfiler.Stop()
	if not DebugProfiler.Enabled then
		warn("[DebugProfiler] Not running")
		return
	end

	print("\n" .. string.rep("✅", 30))
	print("DEBUG PROFILER STOPPED")
	print(string.rep("✅", 30) .. "\n")

	DebugProfiler.Enabled = false

	if DebugProfiler.HeartbeatConnection then
		DebugProfiler.HeartbeatConnection:Disconnect()
		DebugProfiler.HeartbeatConnection = nil
	end

	-- Print final report
	DebugProfiler.PrintDashboard()
end

function DebugProfiler.Reset()
	DebugProfiler.Profiles = {}
	DebugProfiler.PerformanceHistory = {}
	DebugProfiler.MemorySnapshots = {}
	DebugProfiler.HistoryIndex = 1
	DebugProfiler.HistorySize = 0
	DebugProfiler.MemorySnapshotIndex = 1
	DebugProfiler.MemorySnapshotSize = 0
	print("[DebugProfiler] Reset all profiling data")
end

-- ============================================================================
-- QUICK PROFILING UTILITIES
-- ============================================================================

function DebugProfiler.Benchmark(name: string, iterations: number, func: () -> any)
	print(string.format("\n[DebugProfiler] Benchmarking %s (%d iterations)...", name, iterations))

	local times = {}
	local totalTime = 0

	for i = 1, iterations do
		local start = os.clock()
		func()
		local elapsed = (os.clock() - start) * 1000
		table.insert(times, elapsed)
		totalTime = totalTime + elapsed
	end

	table.sort(times)

	local avg = totalTime / iterations
	local min = times[1]
	local max = times[#times]
	local median = times[math.floor(#times / 2)]

	print(string.format("  Average: %.3fms", avg))
	print(string.format("  Median: %.3fms", median))
	print(string.format("  Min: %.3fms", min))
	print(string.format("  Max: %.3fms", max))
	print(string.format("  Total: %.3fms\n", totalTime))
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return DebugProfiler
