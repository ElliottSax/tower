--[[
	Generator.lua
	Production-grade procedural tower generation

	Features:
	- Seed-based determinism (same seed = same tower)
	- Loads pre-built sections from ServerStorage
	- Memory-efficient (integrates with MemoryManager)
	- Difficulty progression
	- CFrame-based connection points
	- Supports 4 difficulty modes
	- Fully testable

	Architecture:
	- Sections are pre-built in Roblox Studio, saved in ServerStorage
	- Generator selects sections based on difficulty curve
	- Each section has "Start" and "Next" attachment points
	- Sections connect via CFrame math (no manual positioning)

	Week 1: Basic implementation
	Week 6-11: Add 30+ unique sections
--]]

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Generator = {}
Generator.__index = Generator

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local SECTIONS_PER_TOWER = GameConfig.Tower.SectionsPerTower
local SECTION_LENGTH = GameConfig.Tower.SectionLength
local START_HEIGHT = GameConfig.Tower.StartHeight

-- Difficulty curve
-- Maps section number → difficulty tier
local DIFFICULTY_CURVE = {
	{ range = {1, 5},   tier = "Easy" },    -- First 5: Easy
	{ range = {6, 15},  tier = "Medium" },  -- Next 10: Medium
	{ range = {16, 35}, tier = "Hard" },    -- Next 20: Hard
	{ range = {36, 50}, tier = "Expert" },  -- Final 15: Expert
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Generator.new(seed: number?, difficultyMode: string?)
	local self = setmetatable({}, Generator)

	-- Seed for deterministic generation
	self.Seed = seed or os.time()
	self.RNG = Random.new(self.Seed)

	-- Difficulty mode (affects time limits, coin rewards)
	self.DifficultyMode = difficultyMode or "Normal"

	-- Track active stages
	self.ActiveStages = {}

	-- Performance tracking
	self.GenerationStartTime = nil
	self.GenerationEndTime = nil

	-- Section templates (loaded from ServerStorage)
	self.SectionTemplates = {
		Easy = {},
		Medium = {},
		Hard = {},
		Expert = {},
	}

	-- Load section templates
	self:LoadSectionTemplates()

	return self
end

-- ============================================================================
-- SECTION TEMPLATE LOADING
-- ============================================================================

function Generator:LoadSectionTemplates()
	local sectionsFolder = ServerStorage:FindFirstChild("Sections")

	if not sectionsFolder then
		warn("[Generator] Sections folder not found in ServerStorage!")
		warn("[Generator] Creating placeholder sections...")
		self:CreatePlaceholderSections()
		return
	end

	-- Load sections by difficulty
	for tier, _ in pairs(self.SectionTemplates) do
		local tierFolder = sectionsFolder:FindFirstChild(tier)

		if tierFolder then
			for _, section in ipairs(tierFolder:GetChildren()) do
				if section:IsA("Model") then
					-- VALIDATE SECTION: Ensure it has required attachments
					local hasStart = self:FindAttachment(section, "Start") ~= nil
					local hasNext = self:FindAttachment(section, "Next") ~= nil

					if not hasStart then
						warn(string.format(
							"[Generator] Section %s missing 'Start' attachment - SKIPPING",
							section.Name
						))
						continue
					end

					if not hasNext then
						warn(string.format(
							"[Generator] Section %s missing 'Next' attachment - SKIPPING",
							section.Name
						))
						continue
					end

					-- Section is valid
					table.insert(self.SectionTemplates[tier], section)
				end
			end

			print(string.format(
				"[Generator] Loaded %d valid %s sections",
				#self.SectionTemplates[tier],
				tier
			))
		else
			warn(string.format("[Generator] %s folder not found, using placeholders", tier))
		end
	end

	-- Validate we have sections for each tier
	local needsPlaceholders = false
	for tier, sections in pairs(self.SectionTemplates) do
		if #sections == 0 then
			warn(string.format("[Generator] No sections found for %s tier!", tier))
			needsPlaceholders = true
		end
	end

	-- Create placeholders for ALL empty tiers at once (not just the first one found)
	if needsPlaceholders then
		self:CreatePlaceholderSections()
	end
end

-- ============================================================================
-- PLACEHOLDER SECTIONS (Week 1 only)
-- ============================================================================

function Generator:CreatePlaceholderSections()
	--[[
		Week 1: Generate simple placeholder sections procedurally
		Week 6-11: Replace with hand-crafted sections from Studio

		These are intentionally simple - production sections will be
		much more detailed and varied
	--]]

	print("[Generator] Creating procedural placeholder sections...")

	-- Create 5 simple section types for each difficulty
	local function createSimpleSection(tier: string, index: number)
		local section = Instance.new("Model")
		section.Name = string.format("%s_Placeholder_%d", tier, index)

		-- Main platform
		local platform = Instance.new("Part")
		platform.Name = "Platform"
		platform.Size = Vector3.new(SECTION_LENGTH, 2, 12)
		platform.Position = Vector3.new(0, 0, 0)
		platform.Anchored = true
		platform.Material = Enum.Material.Neon

		-- Color by difficulty
		if tier == "Easy" then
			platform.Color = Color3.fromRGB(100, 255, 100)
		elseif tier == "Medium" then
			platform.Color = Color3.fromRGB(100, 200, 255)
		elseif tier == "Hard" then
			platform.Color = Color3.fromRGB(255, 200, 100)
		else
			platform.Color = Color3.fromRGB(255, 100, 100)
		end

		platform.Parent = section

		-- Start attachment point
		local startAttachment = Instance.new("Attachment")
		startAttachment.Name = "Start"
		startAttachment.Position = Vector3.new(-SECTION_LENGTH/2, 1, 0)
		startAttachment.Parent = platform

		-- Next attachment point
		local nextAttachment = Instance.new("Attachment")
		nextAttachment.Name = "Next"
		nextAttachment.Position = Vector3.new(SECTION_LENGTH/2, 1, 0)
		nextAttachment.Parent = platform

		-- Checkpoint part
		local checkpoint = Instance.new("Part")
		checkpoint.Name = "Checkpoint"
		checkpoint.Size = Vector3.new(8, 6, 1)
		checkpoint.Position = Vector3.new(-SECTION_LENGTH/2, 4, 0)
		checkpoint.Anchored = true
		checkpoint.CanCollide = false
		checkpoint.Transparency = 0.5
		checkpoint.Material = Enum.Material.ForceField
		checkpoint.Color = Color3.fromRGB(0, 255, 0)
		checkpoint.Parent = section

		-- Tag checkpoint
		CollectionService:AddTag(checkpoint, "Checkpoint")

		section.PrimaryPart = platform
		return section
	end

	-- Create 3 sections per tier (minimum viable)
	for tier, _ in pairs(self.SectionTemplates) do
		for i = 1, 3 do
			local section = createSimpleSection(tier, i)
			table.insert(self.SectionTemplates[tier], section)
		end
	end

	print("[Generator] Created placeholder sections (replace in Week 6-11)")
end

-- ============================================================================
-- TOWER GENERATION
-- ============================================================================

function Generator:GenerateTower(): Model
	self.GenerationStartTime = tick()

	print(string.format(
		"[Generator] Generating tower (Seed: %d, Difficulty: %s)",
		self.Seed,
		self.DifficultyMode
	))

	-- Create tower container
	local tower = Instance.new("Model")
	tower.Name = string.format("Tower_%d", self.Seed)
	tower:SetAttribute("Seed", self.Seed)
	tower:SetAttribute("DifficultyMode", self.DifficultyMode)
	tower:SetAttribute("GenerationTime", 0) -- Will update at end

	-- Starting CFrame
	local currentCF = CFrame.new(0, START_HEIGHT, 0)

	-- Generate sections
	for i = 1, SECTIONS_PER_TOWER do
		-- Get difficulty tier for this section
		local tier = self:GetDifficultyTier(i)

		-- Select section from template pool
		local sectionTemplate = self:SelectSection(tier)

		if not sectionTemplate then
			-- Graceful fallback: try other tiers instead of crashing
			warn(string.format("[Generator] No section found for tier %s, trying fallback tiers...", tier))

			local fallbackOrder = {"Medium", "Easy", "Hard", "Expert"}
			for _, fallbackTier in ipairs(fallbackOrder) do
				if fallbackTier ~= tier then
					sectionTemplate = self:SelectSection(fallbackTier)
					if sectionTemplate then
						warn(string.format("[Generator] Using %s section as fallback for section %d", fallbackTier, i))
						break
					end
				end
			end

			-- If still no template, skip this section with a warning
			if not sectionTemplate then
				warn(string.format("[Generator] CRITICAL: No sections available for section %d, skipping!", i))
				currentCF = currentCF * CFrame.new(SECTION_LENGTH, 0, 0)
				continue
			end
		end

		-- Clone and position section with error handling
		local success, section = pcall(function()
			return self:CloneAndPositionSection(sectionTemplate, currentCF, i)
		end)

		if not success or not section then
			warn(string.format("[Generator] Failed to create section %d: %s", i, tostring(section)))
			currentCF = currentCF * CFrame.new(SECTION_LENGTH, 0, 0)
			continue
		end

		-- Add to tower
		section.Parent = tower

		-- Track in active stages
		table.insert(self.ActiveStages, section)

		-- Get next connection point
		local nextPoint = self:GetNextConnectionPoint(section)
		if nextPoint then
			currentCF = nextPoint
		else
			warn(string.format("[Generator] Section %d missing Next attachment!", i))
			-- Fallback: offset by section length
			currentCF = currentCF * CFrame.new(SECTION_LENGTH, 0, 0)
		end

		-- Log every 10 sections
		if i % 10 == 0 then
			print(string.format("[Generator] Generated %d/%d sections", i, SECTIONS_PER_TOWER))
		end
	end

	-- Add finish line
	local finishLine = self:CreateFinishLine(currentCF)
	finishLine.Parent = tower

	-- Parent to workspace
	tower.Parent = workspace

	-- Log completion
	self.GenerationEndTime = tick()
	local generationTime = self.GenerationEndTime - self.GenerationStartTime
	tower:SetAttribute("GenerationTime", generationTime)

	print(string.format(
		"[Generator] Tower generation complete! (%.2f seconds, %d sections)",
		generationTime,
		SECTIONS_PER_TOWER
	))

	return tower
end

-- ============================================================================
-- DIFFICULTY TIER SELECTION
-- ============================================================================

function Generator:GetDifficultyTier(sectionNumber: number): string
	-- Find which tier this section belongs to
	for _, curve in ipairs(DIFFICULTY_CURVE) do
		if sectionNumber >= curve.range[1] and sectionNumber <= curve.range[2] then
			return curve.tier
		end
	end

	-- Fallback
	return "Medium"
end

-- ============================================================================
-- SECTION SELECTION
-- ============================================================================

function Generator:SelectSection(tier: string): Model
	local pool = self.SectionTemplates[tier]

	if not pool or #pool == 0 then
		warn(string.format("[Generator] No sections available for tier: %s", tier))
		return nil
	end

	-- Use RNG for deterministic selection
	local index = self.RNG:NextInteger(1, #pool)
	return pool[index]
end

-- ============================================================================
-- SECTION POSITIONING
-- ============================================================================

function Generator:CloneAndPositionSection(template: Model, cf: CFrame, sectionNumber: number): Model
	-- Clone section
	local section = template:Clone()
	section.Name = string.format("Section_%d_%s", sectionNumber, template.Name)

	-- Set attributes
	section:SetAttribute("SectionNumber", sectionNumber)
	section:SetAttribute("OriginalTemplate", template.Name)

	-- Choose random rotation FIRST (0, 90, 180, 270 degrees)
	local rotations = {0, 90, 180, 270}
	local rotation = rotations[self.RNG:NextInteger(1, #rotations)]
	local rotationCFrame = CFrame.Angles(0, math.rad(rotation), 0)

	-- Store rotation for debugging
	section:SetAttribute("Rotation", rotation)

	-- Find Start attachment
	local startAttachment = self:FindAttachment(section, "Start")

	if startAttachment then
		-- Get Start attachment's offset from model pivot in LOCAL/object space
		-- This offset doesn't change with world rotation
		local pivotCF = section:GetPivot()
		local offset = pivotCF:ToObjectSpace(startAttachment.WorldCFrame)

		-- Position section with rotation applied using PivotTo (replaces deprecated SetPrimaryPartCFrame):
		-- 1. cf = target world position/orientation
		-- 2. * rotationCFrame = apply Y-axis rotation
		-- 3. * offset:Inverse() = shift so Start attachment ends up at target
		section:PivotTo(cf * rotationCFrame * offset:Inverse())

		-- Verify alignment (debug mode only)
		if GameConfig.Debug.VerboseLogs then
			local finalStart = self:FindAttachment(section, "Start")
			if finalStart then
				local distance = (finalStart.WorldCFrame.Position - cf.Position).Magnitude
				if distance > 0.1 then
					warn(string.format(
						"[Generator] Section %d alignment error: %.2f studs (rotation: %d°)",
						sectionNumber,
						distance,
						rotation
					))
				end
			end
		end
	else
		-- Fallback: position by pivot with rotation
		warn(string.format("[Generator] Section %d missing Start attachment!", sectionNumber))
		section:PivotTo(cf * rotationCFrame)
	end

	return section
end

-- ============================================================================
-- CONNECTION POINTS
-- ============================================================================

function Generator:GetNextConnectionPoint(section: Model): CFrame?
	local nextAttachment = self:FindAttachment(section, "Next")

	if nextAttachment then
		return nextAttachment.WorldCFrame
	end

	return nil
end

function Generator:FindAttachment(section: Model, name: string): Attachment?
	-- Search all descendants for attachment
	for _, descendant in ipairs(section:GetDescendants()) do
		if descendant:IsA("Attachment") and descendant.Name == name then
			return descendant
		end
	end

	return nil
end

-- ============================================================================
-- FINISH LINE
-- ============================================================================

function Generator:CreateFinishLine(cf: CFrame): Part
	local finishLine = Instance.new("Part")
	finishLine.Name = "FinishLine"
	finishLine.Size = Vector3.new(20, 15, 2)
	finishLine.CFrame = cf * CFrame.new(0, 7.5, 0) -- Center vertically
	finishLine.Anchored = true
	finishLine.CanCollide = false
	finishLine.Transparency = 0.3
	finishLine.Material = Enum.Material.ForceField
	finishLine.Color = Color3.fromRGB(255, 215, 0) -- Gold
	finishLine:SetAttribute("IsFinish", true)

	-- Tag for detection
	CollectionService:AddTag(finishLine, "FinishLine")

	return finishLine
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function Generator:Cleanup()
	-- Remove all active stages
	for _, stage in ipairs(self.ActiveStages) do
		if stage and stage.Parent then
			stage:Destroy()
		end
	end

	self.ActiveStages = {}

	print("[Generator] Cleanup complete")
end

-- ============================================================================
-- TESTING UTILITIES
-- ============================================================================

function Generator:GetSectionCount(): number
	return #self.ActiveStages
end

function Generator:GetGenerationTime(): number?
	if self.GenerationStartTime and self.GenerationEndTime then
		return self.GenerationEndTime - self.GenerationStartTime
	end
	return nil
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return Generator
