--[[
	TowerGenerator.lua
	Procedurally generates a 10-section tower with varying difficulty
	Each section is created using basic parts (no pre-made models needed!)

	Usage: Run this on server start, tower auto-generates
--]]

local TowerGenerator = {}

-- Configuration
local SECTIONS_COUNT = 10
local SECTION_LENGTH = 50 -- studs
local START_HEIGHT = 10
local PLATFORM_SIZE = Vector3.new(12, 1, 12) -- studs
local CHECKPOINT_SIZE = Vector3.new(10, 8, 1) -- studs

-- Section Templates (procedurally generated)
local SectionTypes = {
	"FlatPlatform",
	"GapJump",
	"Staircase",
	"ZigZag",
	"WallClimb"
}

-- Create a single platform
local function createPlatform(position, size, color)
	local platform = Instance.new("Part")
	platform.Size = size or PLATFORM_SIZE
	platform.Position = position
	platform.Anchored = true
	platform.Material = Enum.Material.Neon
	platform.Color = color or Color3.fromRGB(100, 200, 255)
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	return platform
end

-- Create checkpoint marker
local function createCheckpoint(position, sectionNumber)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Size = CHECKPOINT_SIZE
	checkpoint.Position = position
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.Transparency = 0.5
	checkpoint.Material = Enum.Material.ForceField
	checkpoint.Color = Color3.fromRGB(0, 255, 0)
	checkpoint:SetAttribute("SectionNumber", sectionNumber)

	-- Add CollectionService tag
	local CollectionService = game:GetService("CollectionService")
	CollectionService:AddTag(checkpoint, "Checkpoint")

	return checkpoint
end

-- Create connection point marker (invisible, for reference)
local function createConnectionPoint(name, position)
	local point = Instance.new("Part")
	point.Name = name
	point.Size = Vector3.new(1, 1, 1)
	point.Position = position
	point.Anchored = true
	point.CanCollide = false
	point.Transparency = 1
	return point
end

-- SECTION TYPE 1: Flat Platform (Easy)
local function generateFlatPlatform(startCF, sectionNum)
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNum .. "_Flat"

	-- Main platform
	local platform = createPlatform(
		startCF.Position + Vector3.new(0, 0, 0),
		Vector3.new(SECTION_LENGTH, 1, 12),
		Color3.fromRGB(100, 200, 255)
	)
	platform.Parent = section

	-- Checkpoint at start
	local checkpoint = createCheckpoint(
		startCF.Position + Vector3.new(0, 4, 0),
		sectionNum
	)
	checkpoint.Parent = section

	-- Connection points
	local startPoint = createConnectionPoint("Start", startCF.Position)
	local nextPoint = createConnectionPoint("Next", startCF.Position + Vector3.new(SECTION_LENGTH, 0, 0))
	startPoint.Parent = section
	nextPoint.Parent = section

	section.PrimaryPart = platform
	return section, CFrame.new(nextPoint.Position)
end

-- SECTION TYPE 2: Gap Jump (Medium)
local function generateGapJump(startCF, sectionNum)
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNum .. "_Gap"

	-- First platform
	local platform1 = createPlatform(
		startCF.Position,
		Vector3.new(15, 1, 12),
		Color3.fromRGB(255, 200, 100)
	)
	platform1.Parent = section

	-- Gap (10 studs)
	local gapSize = 10

	-- Second platform
	local platform2 = createPlatform(
		startCF.Position + Vector3.new(15 + gapSize + 15, 2, 0), -- Slightly higher
		Vector3.new(15, 1, 12),
		Color3.fromRGB(255, 200, 100)
	)
	platform2.Parent = section

	-- Checkpoint
	local checkpoint = createCheckpoint(
		startCF.Position + Vector3.new(0, 4, 0),
		sectionNum
	)
	checkpoint.Parent = section

	-- Connection points
	local startPoint = createConnectionPoint("Start", startCF.Position)
	local nextPoint = createConnectionPoint("Next", platform2.Position + Vector3.new(15, 0, 0))
	startPoint.Parent = section
	nextPoint.Parent = section

	section.PrimaryPart = platform1
	return section, CFrame.new(nextPoint.Position)
end

-- SECTION TYPE 3: Staircase (Easy-Medium)
local function generateStaircase(startCF, sectionNum)
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNum .. "_Stairs"

	local stairCount = 5
	local stairWidth = SECTION_LENGTH / stairCount
	local risePerStair = 3 -- studs height gain per stair

	local firstStair
	for i = 1, stairCount do
		local stair = createPlatform(
			startCF.Position + Vector3.new(stairWidth * (i - 1) + stairWidth/2, risePerStair * i, 0),
			Vector3.new(stairWidth, 1, 12),
			Color3.fromRGB(150, 100, 255)
		)
		stair.Parent = section

		if i == 1 then
			firstStair = stair
		end
	end

	-- Checkpoint
	local checkpoint = createCheckpoint(
		startCF.Position + Vector3.new(0, 4, 0),
		sectionNum
	)
	checkpoint.Parent = section

	-- Connection points
	local startPoint = createConnectionPoint("Start", startCF.Position)
	local nextPoint = createConnectionPoint(
		"Next",
		startCF.Position + Vector3.new(SECTION_LENGTH, risePerStair * stairCount, 0)
	)
	startPoint.Parent = section
	nextPoint.Parent = section

	section.PrimaryPart = firstStair
	return section, CFrame.new(nextPoint.Position)
end

-- SECTION TYPE 4: ZigZag (Medium)
local function generateZigZag(startCF, sectionNum)
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNum .. "_ZigZag"

	local platformCount = 4
	local platformSpacing = SECTION_LENGTH / platformCount
	local zigzagOffset = 8 -- studs left/right

	local firstPlatform
	for i = 1, platformCount do
		local offsetZ = (i % 2 == 0) and zigzagOffset or -zigzagOffset

		local platform = createPlatform(
			startCF.Position + Vector3.new(platformSpacing * i, i * 2, offsetZ),
			Vector3.new(10, 1, 10),
			Color3.fromRGB(255, 150, 200)
		)
		platform.Parent = section

		if i == 1 then
			firstPlatform = platform
		end
	end

	-- Checkpoint
	local checkpoint = createCheckpoint(
		startCF.Position + Vector3.new(0, 4, 0),
		sectionNum
	)
	checkpoint.Parent = section

	-- Connection points
	local startPoint = createConnectionPoint("Start", startCF.Position)
	local nextPoint = createConnectionPoint(
		"Next",
		startCF.Position + Vector3.new(SECTION_LENGTH, platformCount * 2, 0)
	)
	startPoint.Parent = section
	nextPoint.Parent = section

	section.PrimaryPart = firstPlatform
	return section, CFrame.new(nextPoint.Position)
end

-- SECTION TYPE 5: Wall Climb (Hard)
local function generateWallClimb(startCF, sectionNum)
	local section = Instance.new("Model")
	section.Name = "Section_" .. sectionNum .. "_Wall"

	-- Create vertical wall
	local wall = createPlatform(
		startCF.Position + Vector3.new(SECTION_LENGTH/2, 15, -8),
		Vector3.new(SECTION_LENGTH, 30, 1),
		Color3.fromRGB(150, 150, 150)
	)
	wall.Parent = section

	-- Create climbing platforms attached to wall
	local climbCount = 6
	local firstClimb
	for i = 1, climbCount do
		local climb = createPlatform(
			startCF.Position + Vector3.new(
				(SECTION_LENGTH / climbCount) * i,
				i * 4,
				-3
			),
			Vector3.new(8, 1, 6),
			Color3.fromRGB(200, 100, 100)
		)
		climb.Parent = section

		if i == 1 then
			firstClimb = climb
		end
	end

	-- Checkpoint
	local checkpoint = createCheckpoint(
		startCF.Position + Vector3.new(0, 4, 0),
		sectionNum
	)
	checkpoint.Parent = section

	-- Connection points
	local startPoint = createConnectionPoint("Start", startCF.Position)
	local nextPoint = createConnectionPoint(
		"Next",
		startCF.Position + Vector3.new(SECTION_LENGTH, climbCount * 4, 0)
	)
	startPoint.Parent = section
	nextPoint.Parent = section

	section.PrimaryPart = firstClimb or wall
	return section, CFrame.new(nextPoint.Position)
end

-- Main tower generation
function TowerGenerator.Generate()
	print("[TowerGenerator] Generating 10-section tower...")

	-- Create tower container
	local tower = Instance.new("Model")
	tower.Name = "Tower_Prototype"

	-- Starting position
	local currentCF = CFrame.new(0, START_HEIGHT, 0)

	-- Section generators
	local generators = {
		generateFlatPlatform,
		generateGapJump,
		generateStaircase,
		generateZigZag,
		generateWallClimb
	}

	-- Generate 10 sections with increasing difficulty
	for i = 1, SECTIONS_COUNT do
		-- Choose section type based on difficulty progression
		local generatorIndex
		if i <= 2 then
			generatorIndex = 1 -- Flat platforms for first 2
		elseif i <= 4 then
			generatorIndex = math.random(1, 2) -- Flat or Gap
		elseif i <= 7 then
			generatorIndex = math.random(2, 4) -- Gap, Stairs, or ZigZag
		else
			generatorIndex = math.random(3, 5) -- Stairs, ZigZag, or Wall
		end

		local section, nextCF = generators[generatorIndex](currentCF, i)
		section.Parent = tower

		-- Add finish marker on section 10
		if i == SECTIONS_COUNT then
			local finish = Instance.new("Part")
			finish.Name = "FinishLine"
			finish.Size = Vector3.new(12, 10, 1)
			finish.Position = nextCF.Position + Vector3.new(0, 5, 0)
			finish.Anchored = true
			finish.CanCollide = false
			finish.Transparency = 0.3
			finish.Material = Enum.Material.ForceField
			finish.Color = Color3.fromRGB(255, 215, 0) -- Gold
			finish:SetAttribute("IsFinish", true)

			local CollectionService = game:GetService("CollectionService")
			CollectionService:AddTag(finish, "FinishLine")

			finish.Parent = section
		end

		currentCF = nextCF
		print(string.format("[TowerGenerator] Generated section %d: %s", i, section.Name))
	end

	tower.Parent = workspace
	print("[TowerGenerator] Tower generation complete!")

	return tower
end

-- Auto-generate on server start
TowerGenerator.Generate()

return TowerGenerator
