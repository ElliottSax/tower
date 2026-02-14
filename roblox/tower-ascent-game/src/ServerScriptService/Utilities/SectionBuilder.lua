--[[
	SectionBuilder.lua
	Utility for programmatically creating tower section templates

	Features:
	- Builds section models with Start/Next attachment points
	- Creates platforms, obstacles, and checkpoints
	- Handles proper CFrame positioning
	- Validates section integrity
	- Adds environmental hazards (lava, spikes, wind, etc.)

	Usage:
	local SectionBuilder = require(ServerScriptService.Utilities.SectionBuilder)
	local section = SectionBuilder.new("Easy_Straight")
		:AddPlatform(Vector3.new(0, 0, 0), Vector3.new(30, 2, 12))
		:AddCheckpoint(Vector3.new(-15, 4, 0))
		:AddSpikes(Vector3.new(10, 0, 0))
		:Build()

	Week 6: Initial implementation
	Week 9: Added hazard methods
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SectionBuilder = {}
SectionBuilder.__index = SectionBuilder

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local SECTION_LENGTH = GameConfig.Tower.SectionLength or 30
local DEFAULT_PLATFORM_SIZE = Vector3.new(SECTION_LENGTH, 2, 12)
local DEFAULT_CHECKPOINT_SIZE = Vector3.new(8, 6, 1)

-- Material presets
local MATERIALS = {
	Easy = {
		Platform = Enum.Material.Grass,
		Color = Color3.fromRGB(120, 200, 120),
	},
	Medium = {
		Platform = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(150, 150, 150),
	},
	Hard = {
		Platform = Enum.Material.Concrete,
		Color = Color3.fromRGB(100, 100, 120),
	},
	Expert = {
		Platform = Enum.Material.Metal,
		Color = Color3.fromRGB(80, 80, 90),
	},
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function SectionBuilder.new(name: string, tier: string)
	local self = setmetatable({}, SectionBuilder)

	self.Name = name or "Untitled_Section"
	self.Tier = tier or "Easy"
	self.Parts = {} -- All parts to add to the model
	self.PrimaryPartIndex = nil
	self.StartPosition = Vector3.new(-SECTION_LENGTH/2, 1, 0)
	self.NextPosition = Vector3.new(SECTION_LENGTH/2, 1, 0)

	return self
end

-- ============================================================================
-- PLATFORM CREATION
-- ============================================================================

function SectionBuilder:AddPlatform(position: Vector3, size: Vector3?, material: Enum.Material?, color: Color3?): SectionBuilder
	size = size or DEFAULT_PLATFORM_SIZE

	-- Get default material/color for tier
	local preset = MATERIALS[self.Tier] or MATERIALS.Easy
	material = material or preset.Platform
	color = color or preset.Color

	local platform = Instance.new("Part")
	platform.Name = "Platform_" .. tostring(#self.Parts + 1)
	platform.Size = size
	platform.Position = position
	platform.Anchored = true
	platform.Material = material
	platform.Color = color
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth

	-- First platform becomes PrimaryPart
	if #self.Parts == 0 then
		self.PrimaryPartIndex = #self.Parts + 1
	end

	table.insert(self.Parts, platform)

	return self
end

function SectionBuilder:AddJumpPad(position: Vector3, size: Vector3?, color: Color3?): SectionBuilder
	size = size or Vector3.new(6, 1, 6)
	color = color or Color3.fromRGB(100, 200, 255)

	local jumpPad = Instance.new("Part")
	jumpPad.Name = "JumpPad"
	jumpPad.Size = size
	jumpPad.Position = position
	jumpPad.Anchored = true
	jumpPad.Material = Enum.Material.Neon
	jumpPad.Color = color
	jumpPad:SetAttribute("IsJumpPad", true)
	jumpPad:SetAttribute("JumpPower", 100)

	table.insert(self.Parts, jumpPad)

	return self
end

function SectionBuilder:AddKillBrick(position: Vector3, size: Vector3?): SectionBuilder
	size = size or Vector3.new(10, 2, 10)

	local killBrick = Instance.new("Part")
	killBrick.Name = "KillBrick"
	killBrick.Size = size
	killBrick.Position = position
	killBrick.Anchored = true
	killBrick.Material = Enum.Material.Neon
	killBrick.Color = Color3.fromRGB(255, 50, 50)
	killBrick.CanCollide = false
	killBrick.Transparency = 0.3
	killBrick:SetAttribute("IsKillBrick", true)

	table.insert(self.Parts, killBrick)

	return self
end

-- ============================================================================
-- OBSTACLE CREATION
-- ============================================================================

function SectionBuilder:AddWall(position: Vector3, size: Vector3?, rotation: number?): SectionBuilder
	size = size or Vector3.new(2, 6, 12)
	rotation = rotation or 0

	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = size
	wall.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	wall.Anchored = true
	wall.Material = Enum.Material.Brick
	wall.Color = Color3.fromRGB(120, 100, 80)

	table.insert(self.Parts, wall)

	return self
end

function SectionBuilder:AddGap(startPos: Vector3, endPos: Vector3): SectionBuilder
	-- Gap is represented by absence of platforms
	-- This is more of a design helper - doesn't add parts
	-- We'll add small markers for visualization

	local marker1 = Instance.new("Part")
	marker1.Name = "GapMarker"
	marker1.Size = Vector3.new(0.5, 0.5, 12)
	marker1.Position = startPos
	marker1.Anchored = true
	marker1.Transparency = 0.8
	marker1.CanCollide = false
	marker1.Color = Color3.fromRGB(255, 255, 0)

	local marker2 = marker1:Clone()
	marker2.Position = endPos

	table.insert(self.Parts, marker1)
	table.insert(self.Parts, marker2)

	return self
end

function SectionBuilder:AddMovingPlatform(startPos: Vector3, endPos: Vector3, size: Vector3?, speed: number?): SectionBuilder
	size = size or Vector3.new(10, 2, 10)
	speed = speed or 5

	local platform = Instance.new("Part")
	platform.Name = "MovingPlatform"
	platform.Size = size
	platform.Position = startPos
	platform.Anchored = false
	platform.Material = Enum.Material.Metal
	platform.Color = Color3.fromRGB(180, 180, 200)
	platform:SetAttribute("IsMovingPlatform", true)
	platform:SetAttribute("StartPosition", startPos)
	platform:SetAttribute("EndPosition", endPos)
	platform:SetAttribute("Speed", speed)

	-- Add BodyPosition for movement (handled by MovingPlatformService later)
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyPosition.Position = startPos
	bodyPosition.Parent = platform

	table.insert(self.Parts, platform)

	return self
end

-- ============================================================================
-- HAZARDS (Week 9)
-- ============================================================================

--[[
	Add lava hazard (instant death)
	@param position Vector3 - Position of lava
	@param size Vector3 - Size of lava pool
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddLava(position: Vector3, size: Vector3?): SectionBuilder
	size = size or Vector3.new(10, 1, 10)

	local lava = Instance.new("Part")
	lava.Name = "Lava"
	lava.Size = size
	lava.Position = position
	lava.Anchored = true
	lava.Material = Enum.Material.Neon
	lava.Color = Color3.fromRGB(255, 100, 0)
	lava.Transparency = 0.3
	lava:SetAttribute("HazardType", "Lava")

	table.insert(self.Parts, lava)

	return self
end

--[[
	Add spikes hazard (damage)
	@param position Vector3 - Position of spikes
	@param size Vector3 - Size of spike cluster
	@param retractable boolean - Whether spikes retract/extend
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddSpikes(position: Vector3, size: Vector3?, retractable: boolean?): SectionBuilder
	size = size or Vector3.new(6, 2, 6)

	local spikes = Instance.new("Part")
	spikes.Name = retractable and "RetractableSpikes" or "Spikes"
	spikes.Size = size
	spikes.Position = position
	spikes.Anchored = true
	spikes.Material = Enum.Material.Metal
	spikes.Color = Color3.fromRGB(100, 100, 100)
	spikes:SetAttribute("HazardType", "Spikes")

	if retractable then
		spikes:SetAttribute("Retractable", true)
	end

	table.insert(self.Parts, spikes)

	return self
end

--[[
	Add rotating obstacle hazard (knockback)
	@param position Vector3 - Center position of obstacle
	@param size Vector3 - Size of rotating bar
	@param speed number - Rotation speed (degrees/second)
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddRotatingObstacle(position: Vector3, size: Vector3?, speed: number?): SectionBuilder
	size = size or Vector3.new(20, 2, 2)
	speed = speed or 30

	local obstacle = Instance.new("Part")
	obstacle.Name = "RotatingObstacle"
	obstacle.Size = size
	obstacle.Position = position
	obstacle.Anchored = false
	obstacle.Material = Enum.Material.Metal
	obstacle.Color = Color3.fromRGB(150, 150, 150)
	obstacle:SetAttribute("HazardType", "RotatingObstacle")
	obstacle:SetAttribute("RotationSpeed", speed)

	-- Make it spin (anchored but can rotate)
	obstacle.Anchored = true

	table.insert(self.Parts, obstacle)

	return self
end

--[[
	Add wind zone hazard (force)
	@param position Vector3 - Center of wind zone
	@param size Vector3 - Size of wind zone
	@param direction Vector3 - Wind direction (normalized)
	@param force number - Wind strength
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddWindZone(position: Vector3, size: Vector3?, direction: Vector3?, force: number?): SectionBuilder
	size = size or Vector3.new(10, 20, 10)
	direction = direction or Vector3.new(1, 0, 0)
	force = force or 30

	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = size
	windZone.Position = position
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.Material = Enum.Material.ForceField
	windZone.Color = Color3.fromRGB(150, 200, 255)
	windZone.Transparency = 0.8
	windZone:SetAttribute("HazardType", "WindZone")
	windZone:SetAttribute("WindDirection", direction)
	windZone:SetAttribute("WindForce", force)

	table.insert(self.Parts, windZone)

	return self
end

--[[
	Add ice hazard (slippery surface)
	@param position Vector3 - Position of ice
	@param size Vector3 - Size of ice platform
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddIce(position: Vector3, size: Vector3?): SectionBuilder
	size = size or Vector3.new(12, 2, 12)

	local ice = Instance.new("Part")
	ice.Name = "Ice"
	ice.Size = size
	ice.Position = position
	ice.Anchored = true
	ice.Material = Enum.Material.Ice
	ice.Color = Color3.fromRGB(150, 200, 255)
	ice.Transparency = 0.3
	ice.Reflectance = 0.5
	ice:SetAttribute("HazardType", "Ice")

	table.insert(self.Parts, ice)

	return self
end

--[[
	Add quicksand hazard (slow)
	@param position Vector3 - Position of quicksand
	@param size Vector3 - Size of quicksand pit
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddQuicksand(position: Vector3, size: Vector3?): SectionBuilder
	size = size or Vector3.new(10, 2, 10)

	local quicksand = Instance.new("Part")
	quicksand.Name = "Quicksand"
	quicksand.Size = size
	quicksand.Position = position
	quicksand.Anchored = true
	quicksand.Material = Enum.Material.Sand
	quicksand.Color = Color3.fromRGB(200, 180, 140)
	quicksand:SetAttribute("HazardType", "Quicksand")

	table.insert(self.Parts, quicksand)

	return self
end

--[[
	Add poison gas hazard (damage over time)
	@param position Vector3 - Center of gas cloud
	@param size Vector3 - Size of gas zone
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddPoisonGas(position: Vector3, size: Vector3?): SectionBuilder
	size = size or Vector3.new(10, 15, 10)

	local poisonGas = Instance.new("Part")
	poisonGas.Name = "PoisonGas"
	poisonGas.Size = size
	poisonGas.Position = position
	poisonGas.Anchored = true
	poisonGas.CanCollide = false
	poisonGas.Material = Enum.Material.ForceField
	poisonGas.Color = Color3.fromRGB(100, 255, 100)
	poisonGas.Transparency = 0.7
	poisonGas:SetAttribute("HazardType", "PoisonGas")

	table.insert(self.Parts, poisonGas)

	return self
end

--[[
	Add falling platform hazard (timed collapse)
	@param position Vector3 - Position of platform
	@param size Vector3 - Size of platform
	@param fallDelay number - Time before falling (seconds)
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddFallingPlatform(position: Vector3, size: Vector3?, fallDelay: number?): SectionBuilder
	size = size or Vector3.new(10, 2, 10)
	fallDelay = fallDelay or 0.5

	local platform = Instance.new("Part")
	platform.Name = "FallingPlatform"
	platform.Size = size
	platform.Position = position
	platform.Anchored = true
	platform.Material = Enum.Material.Concrete
	platform.Color = Color3.fromRGB(150, 150, 150)
	platform:SetAttribute("HazardType", "FallingPlatform")
	platform:SetAttribute("FallDelay", fallDelay)

	table.insert(self.Parts, platform)

	return self
end

--[[
	Generic hazard adder (advanced use)
	@param hazardType string - Type of hazard (Lava, Spikes, etc.)
	@param position Vector3 - Position of hazard
	@param size Vector3 - Size of hazard
	@param customAttributes table? - Optional custom attributes
	@return SectionBuilder - Self for chaining
--]]
function SectionBuilder:AddHazard(hazardType: string, position: Vector3, size: Vector3, customAttributes: table?): SectionBuilder
	local hazard = Instance.new("Part")
	hazard.Name = hazardType
	hazard.Size = size
	hazard.Position = position
	hazard.Anchored = true
	hazard:SetAttribute("HazardType", hazardType)

	-- Apply custom attributes
	if customAttributes then
		for key, value in pairs(customAttributes) do
			hazard:SetAttribute(key, value)
		end
	end

	table.insert(self.Parts, hazard)

	return self
end

-- ============================================================================
-- CHECKPOINT
-- ============================================================================

function SectionBuilder:AddCheckpoint(position: Vector3?, size: Vector3?): SectionBuilder
	position = position or Vector3.new(-SECTION_LENGTH/2, 4, 0)
	size = size or DEFAULT_CHECKPOINT_SIZE

	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Size = size
	checkpoint.Position = position
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.Transparency = 0.5
	checkpoint.Material = Enum.Material.ForceField
	checkpoint.Color = Color3.fromRGB(0, 255, 100)

	-- Tag for CheckpointService detection
	CollectionService:AddTag(checkpoint, "Checkpoint")

	table.insert(self.Parts, checkpoint)

	return self
end

-- ============================================================================
-- DECORATION
-- ============================================================================

function SectionBuilder:AddDecoration(position: Vector3, size: Vector3, shape: string, color: Color3?): SectionBuilder
	color = color or Color3.fromRGB(200, 200, 200)

	local decoration = Instance.new("Part")
	decoration.Name = "Decoration"
	decoration.Size = size
	decoration.Position = position
	decoration.Anchored = true
	decoration.CanCollide = false
	decoration.Material = Enum.Material.SmoothPlastic
	decoration.Color = color
	decoration.Transparency = 0.2

	if shape == "Sphere" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = decoration
	elseif shape == "Cylinder" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Parent = decoration
	end

	table.insert(self.Parts, decoration)

	return self
end

-- ============================================================================
-- CONNECTION POINTS
-- ============================================================================

function SectionBuilder:SetConnectionPoints(startPos: Vector3?, nextPos: Vector3?): SectionBuilder
	if startPos then
		self.StartPosition = startPos
	end
	if nextPos then
		self.NextPosition = nextPos
	end
	return self
end

-- ============================================================================
-- BUILD
-- ============================================================================

function SectionBuilder:Build(): Model
	if #self.Parts == 0 then
		error("[SectionBuilder] Cannot build section with no parts!")
	end

	if not self.PrimaryPartIndex then
		error("[SectionBuilder] No PrimaryPart set!")
	end

	-- Create model
	local model = Instance.new("Model")
	model.Name = self.Name
	model:SetAttribute("Tier", self.Tier)
	model:SetAttribute("SectionLength", SECTION_LENGTH)

	-- Add all parts
	for _, part in ipairs(self.Parts) do
		part.Parent = model
	end

	-- Set PrimaryPart
	local primaryPart = self.Parts[self.PrimaryPartIndex]
	model.PrimaryPart = primaryPart

	-- Add Start attachment
	local startAttachment = Instance.new("Attachment")
	startAttachment.Name = "Start"
	startAttachment.Position = self.StartPosition
	startAttachment.Parent = primaryPart

	-- Add Next attachment
	local nextAttachment = Instance.new("Attachment")
	nextAttachment.Name = "Next"
	nextAttachment.Position = self.NextPosition
	nextAttachment.Parent = primaryPart

	print(string.format(
		"[SectionBuilder] Built section '%s' (%s tier) with %d parts",
		self.Name,
		self.Tier,
		#self.Parts
	))

	return model
end

-- ============================================================================
-- VALIDATION
-- ============================================================================

function SectionBuilder:Validate(): boolean
	if #self.Parts == 0 then
		warn("[SectionBuilder] Validation failed: No parts added")
		return false
	end

	if not self.PrimaryPartIndex then
		warn("[SectionBuilder] Validation failed: No PrimaryPart set")
		return false
	end

	-- Check for checkpoint
	local hasCheckpoint = false
	for _, part in ipairs(self.Parts) do
		if part.Name == "Checkpoint" then
			hasCheckpoint = true
			break
		end
	end

	if not hasCheckpoint then
		warn("[SectionBuilder] Warning: No checkpoint added (recommended)")
	end

	return true
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return SectionBuilder
