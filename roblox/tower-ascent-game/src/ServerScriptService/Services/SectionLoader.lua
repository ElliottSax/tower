--[[
	SectionLoader.lua
	Loads and builds section templates on server start

	Features:
	- Builds section templates from definitions
	- Stores templates in ServerStorage
	- Creates folder structure automatically
	- Validates template integrity
	- Performance tracking

	Workflow:
	1. SectionLoader.Init() called on server start
	2. Loads template definitions (EasySections, MediumSections, etc.)
	3. Builds each template using SectionBuilder
	4. Stores in ServerStorage/Sections/[Tier]/
	5. Generator loads from ServerStorage

	Week 6: Initial implementation
--]]

local ServerStorage = game:GetService("ServerStorage")

local EasySections = require(script.Parent.Parent.SectionTemplates.EasySections)
local MediumSections = require(script.Parent.Parent.SectionTemplates.MediumSections)
local HardSections = require(script.Parent.Parent.SectionTemplates.HardSections)
local ExpertSections = require(script.Parent.Parent.SectionTemplates.ExpertSections)

local SectionLoader = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local SECTION_DEFINITIONS = {
	Easy = EasySections,
	Medium = MediumSections,
	Hard = HardSections,
	Expert = ExpertSections,
}

-- ============================================================================
-- FOLDER SETUP
-- ============================================================================

function SectionLoader.SetupFolders()
	--[[
		Creates folder structure in ServerStorage:
		ServerStorage/
		  Sections/
		    Easy/
		    Medium/
		    Hard/
		    Expert/
	--]]

	local sectionsFolder = ServerStorage:FindFirstChild("Sections")

	if not sectionsFolder then
		sectionsFolder = Instance.new("Folder")
		sectionsFolder.Name = "Sections"
		sectionsFolder.Parent = ServerStorage
		print("[SectionLoader] Created Sections folder in ServerStorage")
	end

	-- Create tier folders
	local tiers = {"Easy", "Medium", "Hard", "Expert"}
	for _, tier in ipairs(tiers) do
		local tierFolder = sectionsFolder:FindFirstChild(tier)
		if not tierFolder then
			tierFolder = Instance.new("Folder")
			tierFolder.Name = tier
			tierFolder.Parent = sectionsFolder
		end
	end

	return sectionsFolder
end

-- ============================================================================
-- TEMPLATE BUILDING
-- ============================================================================

function SectionLoader.BuildTemplates(tier: string, definitions: {})
	--[[
		Builds all templates for a given tier.
		Returns array of Model instances.
	--]]

	local templates = {}
	local buildCount = 0
	local failCount = 0

	print(string.format("[SectionLoader] Building %s sections...", tier))

	for templateName, builderFunc in pairs(definitions) do
		local success, result = pcall(builderFunc)

		if success and result then
			-- Validate it's a Model
			if typeof(result) == "Instance" and result:IsA("Model") then
				table.insert(templates, result)
				buildCount = buildCount + 1
				print(string.format("  ✓ Built: %s", templateName))
			else
				warn(string.format("  ✗ Invalid return type for %s (expected Model)", templateName))
				failCount = failCount + 1
			end
		else
			warn(string.format("  ✗ Failed to build %s: %s", templateName, tostring(result)))
			failCount = failCount + 1
		end
	end

	print(string.format(
		"[SectionLoader] %s sections: %d built, %d failed",
		tier,
		buildCount,
		failCount
	))

	return templates
end

-- ============================================================================
-- STORAGE
-- ============================================================================

function SectionLoader.StoreTemplates(tier: string, templates: {Model})
	--[[
		Stores built templates in ServerStorage.
	--]]

	local sectionsFolder = ServerStorage:FindFirstChild("Sections")
	if not sectionsFolder then
		error("[SectionLoader] Sections folder not found!")
	end

	local tierFolder = sectionsFolder:FindFirstChild(tier)
	if not tierFolder then
		error(string.format("[SectionLoader] %s folder not found!", tier))
	end

	-- Clear existing templates
	for _, child in ipairs(tierFolder:GetChildren()) do
		child:Destroy()
	end

	-- Store new templates
	for _, template in ipairs(templates) do
		template.Parent = tierFolder
	end

	print(string.format(
		"[SectionLoader] Stored %d %s templates in ServerStorage",
		#templates,
		tier
	))
end

-- ============================================================================
-- VALIDATION
-- ============================================================================

function SectionLoader.ValidateTemplate(template: Model): boolean
	--[[
		Validates a section template has required components:
		- PrimaryPart
		- Start attachment
		- Next attachment
		- At least one Checkpoint
	--]]

	-- Check PrimaryPart
	if not template.PrimaryPart then
		warn(string.format("[SectionLoader] Template '%s' missing PrimaryPart", template.Name))
		return false
	end

	-- Find attachments
	local hasStart = false
	local hasNext = false
	local hasCheckpoint = false

	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("Attachment") then
			if descendant.Name == "Start" then
				hasStart = true
			elseif descendant.Name == "Next" then
				hasNext = true
			end
		elseif descendant.Name == "Checkpoint" then
			hasCheckpoint = true
		end
	end

	-- Validate
	local valid = true

	if not hasStart then
		warn(string.format("[SectionLoader] Template '%s' missing Start attachment", template.Name))
		valid = false
	end

	if not hasNext then
		warn(string.format("[SectionLoader] Template '%s' missing Next attachment", template.Name))
		valid = false
	end

	if not hasCheckpoint then
		warn(string.format("[SectionLoader] Template '%s' missing Checkpoint (recommended)", template.Name))
		-- Not critical, just a warning
	end

	return valid
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SectionLoader.Init()
	print("[SectionLoader] Initializing section templates...")

	local startTime = tick()

	-- Setup folders
	SectionLoader.SetupFolders()

	-- Track totals
	local totalBuilt = 0
	local totalFailed = 0

	-- Build and store each tier
	for tier, definitions in pairs(SECTION_DEFINITIONS) do
		-- Build templates
		local templates = SectionLoader.BuildTemplates(tier, definitions)

		-- Validate templates
		local validTemplates = {}
		for _, template in ipairs(templates) do
			if SectionLoader.ValidateTemplate(template) then
				table.insert(validTemplates, template)
			else
				totalFailed = totalFailed + 1
			end
		end

		-- Store valid templates
		SectionLoader.StoreTemplates(tier, validTemplates)
		totalBuilt = totalBuilt + #validTemplates
	end

	-- Log completion
	local endTime = tick()
	local buildTime = endTime - startTime

	print(string.format(
		"[SectionLoader] Initialization complete! Built %d templates in %.2fs",
		totalBuilt,
		buildTime
	))

	if totalFailed > 0 then
		warn(string.format("[SectionLoader] %d templates failed validation", totalFailed))
	end

	return true
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function SectionLoader.GetTemplateCount(tier: string?): number
	--[[
		Returns number of templates for a tier (or all tiers).
	--]]

	local sectionsFolder = ServerStorage:FindFirstChild("Sections")
	if not sectionsFolder then
		return 0
	end

	if tier then
		local tierFolder = sectionsFolder:FindFirstChild(tier)
		return tierFolder and #tierFolder:GetChildren() or 0
	else
		-- Count all tiers
		local total = 0
		for _, tierFolder in ipairs(sectionsFolder:GetChildren()) do
			total = total + #tierFolder:GetChildren()
		end
		return total
	end
end

function SectionLoader.ListTemplates(tier: string): {string}
	--[[
		Returns list of template names for a tier.
	--]]

	local sectionsFolder = ServerStorage:FindFirstChild("Sections")
	if not sectionsFolder then
		return {}
	end

	local tierFolder = sectionsFolder:FindFirstChild(tier)
	if not tierFolder then
		return {}
	end

	local names = {}
	for _, template in ipairs(tierFolder:GetChildren()) do
		table.insert(names, template.Name)
	end

	return names
end

function SectionLoader.RebuildTier(tier: string): boolean
	--[[
		Rebuilds all templates for a specific tier.
		Useful for development/testing.
	--]]

	local definitions = SECTION_DEFINITIONS[tier]
	if not definitions then
		warn(string.format("[SectionLoader] No definitions found for tier: %s", tier))
		return false
	end

	print(string.format("[SectionLoader] Rebuilding %s tier...", tier))

	local templates = SectionLoader.BuildTemplates(tier, definitions)

	-- Validate
	local validTemplates = {}
	for _, template in ipairs(templates) do
		if SectionLoader.ValidateTemplate(template) then
			table.insert(validTemplates, template)
		end
	end

	-- Store
	SectionLoader.StoreTemplates(tier, validTemplates)

	return true
end

-- ============================================================================
-- ADMIN COMMANDS (Development Only)
-- ============================================================================

function SectionLoader.DebugPrintStats()
	--[[
		Prints statistics about loaded templates.
		Call via: _G.TowerAscent.SectionLoader.DebugPrintStats()
	--]]

	print("=== SECTION TEMPLATE STATS ===")

	local tiers = {"Easy", "Medium", "Hard", "Expert"}
	for _, tier in ipairs(tiers) do
		local count = SectionLoader.GetTemplateCount(tier)
		local templates = SectionLoader.ListTemplates(tier)

		print(string.format("%s: %d templates", tier, count))
		for i, name in ipairs(templates) do
			print(string.format("  %d. %s", i, name))
		end
	end

	local total = SectionLoader.GetTemplateCount()
	print(string.format("\nTotal: %d templates", total))
	print("==============================")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return SectionLoader
