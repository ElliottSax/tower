--[[
	MemoryManager.lua
	Prevents server OOM by despawning distant sections

	Critical System - Without this, server crashes after ~30 minutes

	How it works:
	1. Every 5 seconds, check all active stages
	2. Find the furthest player progress
	3. Despawn stages that are >15 stages behind
	4. StreamingEnabled handles client-side optimization

	Memory Budget:
	- 50 sections × 50 parts each = 2,500 parts total
	- With cleanup: ~750 parts active (15 sections × 50 parts)
	- Memory usage: <200 MB (vs 500+ MB without cleanup)

	Week 1: Basic implementation
	Week 3: Add performance monitoring
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MemoryManager = {}
MemoryManager.__index = MemoryManager

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local CLEANUP_INTERVAL = GameConfig.Memory.CleanupInterval or 5
local MAX_ACTIVE_STAGES = GameConfig.Tower.MaxActiveStages or 15
local DESPAWN_DISTANCE = GameConfig.Tower.DespawnDistance or 500
local MAX_PARTS = GameConfig.Memory.MaxParts or 5000
local LOG_STATS = GameConfig.Memory.LogStats

-- Emergency cleanup configuration
local EMERGENCY_DESPAWN_PERCENTAGE = 0.2 -- Despawn 20% of stages during emergency
local PART_COUNT_CACHE_TTL = 5 -- Seconds before refreshing cached part count

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MemoryManager.new(towerModel: Model)
	local self = setmetatable({}, MemoryManager)

	self.Tower = towerModel
	self.ActiveStages = {}
	self.DespawnedStages = {}

	-- Performance tracking
	self.TotalPartsCreated = 0
	self.TotalPartsDespawned = 0
	self.CleanupCount = 0

	-- Cached part count (prevents expensive GetDescendants calls every frame)
	self.CachedPartCount = 0
	self.LastPartCountUpdate = 0

	-- Heartbeat connection
	self.CleanupConnection = nil

	return self
end

-- ============================================================================
-- START/STOP
-- ============================================================================

function MemoryManager:Start()
	print("[MemoryManager] Starting...")

	-- Index all stages
	self:IndexStages()

	-- Start cleanup loop
	self:StartCleanupLoop()

	print(string.format(
		"[MemoryManager] Started (Tracking %d stages, Cleanup every %ds)",
		#self.ActiveStages,
		CLEANUP_INTERVAL
	))
end

function MemoryManager:Stop()
	if self.CleanupConnection then
		self.CleanupConnection:Disconnect()
		self.CleanupConnection = nil
	end

	print("[MemoryManager] Stopped")
end

-- ============================================================================
-- STAGE INDEXING
-- ============================================================================

function MemoryManager:IndexStages()
	--[[
		Build index of all stages with metadata
		Format: {
			Model = section,
			SectionNumber = number,
			Position = Vector3,
			IsActive = boolean,
		}
	--]]

	self.ActiveStages = {}

	for _, child in ipairs(self.Tower:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("SectionNumber") then
			local stageData = {
				Model = child,
				SectionNumber = child:GetAttribute("SectionNumber"),
				Position = child.PrimaryPart and child.PrimaryPart.Position or Vector3.new(0, 0, 0),
				IsActive = true,
			}

			table.insert(self.ActiveStages, stageData)
			self.TotalPartsCreated = self.TotalPartsCreated + #child:GetDescendants()
		end
	end

	-- Sort by section number
	table.sort(self.ActiveStages, function(a, b)
		return a.SectionNumber < b.SectionNumber
	end)

	print(string.format(
		"[MemoryManager] Indexed %d stages (%d total parts)",
		#self.ActiveStages,
		self.TotalPartsCreated
	))
end

-- ============================================================================
-- CLEANUP LOOP
-- ============================================================================

function MemoryManager:StartCleanupLoop()
	local lastCleanup = tick()

	self.CleanupConnection = RunService.Heartbeat:Connect(function()
		local now = tick()

		if now - lastCleanup >= CLEANUP_INTERVAL then
			self:PerformCleanup()
			lastCleanup = now
		end
	end)
end

function MemoryManager:PerformCleanup()
	-- Get max player progress
	local maxPlayerStage = self:GetMaxPlayerProgress()

	if maxPlayerStage == 0 then
		-- No players have progressed yet
		return
	end

	-- Calculate despawn threshold
	local despawnThreshold = maxPlayerStage - MAX_ACTIVE_STAGES

	if despawnThreshold <= 0 then
		-- Not enough progress to despawn anything
		return
	end

	-- Despawn old stages
	local despawnedCount = 0

	for _, stageData in ipairs(self.ActiveStages) do
		if stageData.IsActive and stageData.SectionNumber < despawnThreshold then
			self:DespawnStage(stageData)
			despawnedCount = despawnedCount + 1
		end
	end

	if despawnedCount > 0 then
		self.CleanupCount = self.CleanupCount + 1

		if LOG_STATS then
			print(string.format(
				"[MemoryManager] Cleanup #%d: Despawned %d stages (Threshold: < Section %d)",
				self.CleanupCount,
				despawnedCount,
				despawnThreshold
			))

			self:LogMemoryStats()
		end
	end

	-- Emergency cleanup if too many parts
	self:EmergencyCleanup()
end

-- ============================================================================
-- PLAYER PROGRESS TRACKING
-- ============================================================================

function MemoryManager:GetMaxPlayerProgress(): number
	local maxStage = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local stage = leaderstats:FindFirstChild("Stage")
			if stage and stage.Value > maxStage then
				maxStage = stage.Value
			end
		end
	end

	return maxStage
end

-- ============================================================================
-- STAGE DESPAWNING
-- ============================================================================

function MemoryManager:DespawnStage(stageData: {})
	if not stageData.IsActive then
		return -- Already despawned
	end

	-- Count parts before destroying
	local partCount = stageData.Model and #stageData.Model:GetDescendants() or 0

	-- Destroy the model
	if stageData.Model and stageData.Model.Parent then
		stageData.Model:Destroy()
	end

	-- Update tracking
	stageData.IsActive = false
	self.TotalPartsDespawned = self.TotalPartsDespawned + partCount

	table.insert(self.DespawnedStages, {
		SectionNumber = stageData.SectionNumber,
		DespawnedAt = tick(),
	})
end

-- ============================================================================
-- PART COUNT CACHING
-- ============================================================================

function MemoryManager:GetPartCount(): number
	--[[
		Returns current part count in workspace with caching.
		Prevents expensive GetDescendants() calls every cleanup cycle.
	--]]

	local now = tick()

	-- Use cached value if within TTL
	if now - self.LastPartCountUpdate < PART_COUNT_CACHE_TTL then
		return self.CachedPartCount
	end

	-- Update cache
	self.CachedPartCount = #workspace:GetDescendants()
	self.LastPartCountUpdate = now

	return self.CachedPartCount
end

-- ============================================================================
-- EMERGENCY CLEANUP
-- ============================================================================

function MemoryManager:EmergencyCleanup()
	--[[
		If total parts exceed threshold, aggressively despawn
		This prevents server crashes from unexpected part count
	--]]

	local currentPartCount = self:GetPartCount()

	if currentPartCount <= MAX_PARTS then
		return -- Under budget
	end

	warn(string.format(
		"[MemoryManager] EMERGENCY CLEANUP! Part count: %d (Max: %d)",
		currentPartCount,
		MAX_PARTS
	))

	-- Despawn configured percentage of active stages
	local targetDespawn = math.ceil(#self.ActiveStages * EMERGENCY_DESPAWN_PERCENTAGE)
	local despawned = 0

	for _, stageData in ipairs(self.ActiveStages) do
		if stageData.IsActive and despawned < targetDespawn then
			self:DespawnStage(stageData)
			despawned = despawned + 1
		end
	end

	warn(string.format(
		"[MemoryManager] Emergency despawned %d stages",
		despawned
	))
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function MemoryManager:LogMemoryStats()
	local activeCount = 0
	for _, stage in ipairs(self.ActiveStages) do
		if stage.IsActive then
			activeCount = activeCount + 1
		end
	end

	local memoryUsage = Stats:GetTotalMemoryUsageMb()
	local partCount = self:GetPartCount()

	print(string.format(
		"[MemoryManager] Stats - Active Stages: %d, Parts: %d, Memory: %.1f MB",
		activeCount,
		partCount,
		memoryUsage
	))
end

function MemoryManager:GetStats(): {}
	local activeCount = 0
	for _, stage in ipairs(self.ActiveStages) do
		if stage.IsActive then
			activeCount = activeCount + 1
		end
	end

	return {
		TotalStages = #self.ActiveStages,
		ActiveStages = activeCount,
		DespawnedStages = #self.DespawnedStages,
		TotalPartsCreated = self.TotalPartsCreated,
		TotalPartsDespawned = self.TotalPartsDespawned,
		CurrentPartCount = self:GetPartCount(),
		MemoryUsageMB = Stats:GetTotalMemoryUsageMb(),
		CleanupCount = self.CleanupCount,
	}
end

-- ============================================================================
-- TESTING UTILITIES
-- ============================================================================

function MemoryManager:ForceCleanup()
	-- Manual cleanup for testing
	self:PerformCleanup()
end

function MemoryManager:GetActiveStageCount(): number
	local count = 0
	for _, stage in ipairs(self.ActiveStages) do
		if stage.IsActive then
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return MemoryManager
