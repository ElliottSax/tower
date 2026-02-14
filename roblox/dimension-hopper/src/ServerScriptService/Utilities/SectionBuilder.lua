--[[
	SectionBuilder.lua
	Utility for procedurally building dimension sections

	Features:
	- Creates section parts with proper tags
	- Supports all dimension-specific mechanics
	- Configurable difficulty scaling
	- Deterministic generation with seeds

	Usage:
	local section = SectionBuilder.Build({
		Dimension = "Gravity",
		SectionNumber = 5,
		Difficulty = "Medium",
		Position = Vector3.new(0, 100, 0),
	})
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SectionBuilder = {}

-- ============================================================================
-- MATERIALS & COLORS
-- ============================================================================

local DIMENSION_MATERIALS = {
	Gravity = {
		Primary = Enum.Material.Neon,
		Secondary = Enum.Material.SmoothPlastic,
		Accent = Enum.Material.ForceField,
	},
	Tiny = {
		Primary = Enum.Material.Grass,
		Secondary = Enum.Material.Wood,
		Accent = Enum.Material.Fabric,
	},
	Void = {
		Primary = Enum.Material.Slate,
		Secondary = Enum.Material.Basalt,
		Accent = Enum.Material.Neon,
	},
	Sky = {
		Primary = Enum.Material.SmoothPlastic,
		Secondary = Enum.Material.Ice,
		Accent = Enum.Material.Glass,
	},
}

-- ============================================================================
-- PART CREATION
-- ============================================================================

function SectionBuilder.CreatePart(config: table): BasePart
	local part = Instance.new("Part")
	part.Name = config.Name or "SectionPart"
	part.Size = config.Size or Vector3.new(10, 1, 10)
	part.Position = config.Position or Vector3.zero
	part.Anchored = true
	part.CanCollide = config.CanCollide ~= false
	part.Material = config.Material or Enum.Material.SmoothPlastic
	part.Color = config.Color or Color3.fromRGB(100, 100, 100)
	part.Transparency = config.Transparency or 0

	if config.CFrame then
		part.CFrame = config.CFrame
	end

	return part
end

function SectionBuilder.CreatePlatform(dimension: string, position: Vector3, size: Vector3?): BasePart
	local dimConfig = GameConfig.Dimensions[dimension]
	local materials = DIMENSION_MATERIALS[dimension]

	local platform = SectionBuilder.CreatePart({
		Name = "Platform",
		Size = size or Vector3.new(12, 2, 12),
		Position = position,
		Material = materials.Primary,
		Color = dimConfig.Theme.PrimaryColor,
	})

	return platform
end

function SectionBuilder.CreateCheckpoint(dimension: string, position: Vector3, sectionNumber: number): BasePart
	local dimConfig = GameConfig.Dimensions[dimension]

	local checkpoint = SectionBuilder.CreatePart({
		Name = "Checkpoint",
		Size = Vector3.new(10, 0.5, 10),
		Position = position,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(100, 255, 100),
		Transparency = 0.3,
	})

	-- Set attributes for CheckpointService
	checkpoint:SetAttribute("Section", sectionNumber)
	checkpoint:SetAttribute("Dimension", dimension)

	-- Add tag for CollectionService
	CollectionService:AddTag(checkpoint, "Checkpoint")

	return checkpoint
end

function SectionBuilder.CreateFinishLine(dimension: string, position: Vector3): BasePart
	local finishLine = SectionBuilder.CreatePart({
		Name = "FinishLine",
		Size = Vector3.new(20, 0.5, 2),
		Position = position,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0),
		Transparency = 0.2,
	})

	CollectionService:AddTag(finishLine, "FinishLine")

	return finishLine
end

-- ============================================================================
-- GRAVITY DIMENSION ELEMENTS
-- ============================================================================

function SectionBuilder.CreateGravityFlipZone(position: Vector3, size: Vector3, flipDirection: Vector3): BasePart
	local zone = SectionBuilder.CreatePart({
		Name = "GravityFlipZone",
		Size = size or Vector3.new(10, 10, 10),
		Position = position,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(138, 43, 226),
		Transparency = 0.7,
		CanCollide = false,
	})

	zone:SetAttribute("FlipDirection", flipDirection)
	CollectionService:AddTag(zone, "GravityFlip")

	-- Visual indicator (arrow)
	local arrow = Instance.new("Part")
	arrow.Name = "DirectionIndicator"
	arrow.Size = Vector3.new(1, 3, 1)
	arrow.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(flipDirection.Y > 0 and 0 or 180))
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Material = Enum.Material.Neon
	arrow.Color = Color3.fromRGB(0, 255, 255)
	arrow.Parent = zone

	return zone
end

function SectionBuilder.CreateWallPlatform(position: Vector3, size: Vector3, rotation: CFrame): BasePart
	local platform = SectionBuilder.CreatePart({
		Name = "WallPlatform",
		Size = size or Vector3.new(12, 2, 12),
		CFrame = CFrame.new(position) * rotation,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(75, 0, 130),
	})

	return platform
end

-- ============================================================================
-- TINY DIMENSION ELEMENTS
-- ============================================================================

function SectionBuilder.CreateScaleZone(position: Vector3, size: Vector3, targetScale: number): BasePart
	local zone = SectionBuilder.CreatePart({
		Name = "ScaleZone",
		Size = size or Vector3.new(8, 8, 8),
		Position = position,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(100, 255, 100),
		Transparency = 0.8,
		CanCollide = false,
	})

	zone:SetAttribute("TargetScale", targetScale)
	CollectionService:AddTag(zone, "ScaleZone")

	return zone
end

function SectionBuilder.CreateGiantObstacle(position: Vector3, obstacleType: string): Model
	local model = Instance.new("Model")
	model.Name = "GiantObstacle_" .. obstacleType

	local obstacles = {
		Pencil = function()
			local body = SectionBuilder.CreatePart({
				Name = "Body",
				Size = Vector3.new(4, 40, 4),
				Position = position,
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(255, 200, 100),
			})
			body.Parent = model

			local tip = SectionBuilder.CreatePart({
				Name = "Tip",
				Size = Vector3.new(3, 6, 3),
				Position = position + Vector3.new(0, 23, 0),
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(255, 200, 150),
			})
			tip.Parent = model
		end,

		Button = function()
			local base = SectionBuilder.CreatePart({
				Name = "Base",
				Size = Vector3.new(20, 5, 20),
				Position = position,
				Material = Enum.Material.Plastic,
				Color = Color3.fromRGB(255, 50, 50),
			})
			base.Shape = Enum.PartType.Cylinder
			base.Parent = model
		end,

		Book = function()
			local cover = SectionBuilder.CreatePart({
				Name = "Cover",
				Size = Vector3.new(30, 4, 40),
				Position = position,
				Material = Enum.Material.Fabric,
				Color = Color3.fromRGB(139, 69, 19),
			})
			cover.Parent = model
		end,
	}

	if obstacles[obstacleType] then
		obstacles[obstacleType]()
	end

	return model
end

-- ============================================================================
-- VOID DIMENSION ELEMENTS
-- ============================================================================

function SectionBuilder.CreateCrumblingPlatform(position: Vector3, size: Vector3?, crumbleDelay: number?): BasePart
	local platform = SectionBuilder.CreatePart({
		Name = "CrumblingPlatform",
		Size = size or Vector3.new(10, 2, 10),
		Position = position,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(50, 20, 20),
	})

	platform:SetAttribute("CrumbleDelay", crumbleDelay or 2.5)
	platform:SetAttribute("Crumbled", false)
	CollectionService:AddTag(platform, "CrumblingPlatform")

	-- Add cracks visual
	local crack = Instance.new("Decal")
	crack.Name = "Crack"
	crack.Face = Enum.NormalId.Top
	crack.Transparency = 0.5
	crack.Parent = platform

	return platform
end

function SectionBuilder.CreateSafeZone(position: Vector3, size: Vector3?): BasePart
	local zone = SectionBuilder.CreatePart({
		Name = "SafeZone",
		Size = size or Vector3.new(15, 1, 15),
		Position = position,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(100, 100, 255),
		Transparency = 0.5,
	})

	CollectionService:AddTag(zone, "VoidSafeZone")

	return zone
end

-- ============================================================================
-- SKY DIMENSION ELEMENTS
-- ============================================================================

function SectionBuilder.CreateCloudPlatform(position: Vector3, size: Vector3?): BasePart
	local cloud = SectionBuilder.CreatePart({
		Name = "CloudPlatform",
		Size = size or Vector3.new(20, 8, 20),
		Position = position,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.3,
	})

	-- Make it bouncy
	cloud.CustomPhysicalProperties = PhysicalProperties.new(
		0.1, -- Density
		0.3, -- Friction
		0.8 -- Elasticity (bouncy!)
	)

	return cloud
end

function SectionBuilder.CreateWindCurrent(position: Vector3, size: Vector3, direction: Vector3, strength: number): BasePart
	local wind = SectionBuilder.CreatePart({
		Name = "WindCurrent",
		Size = size or Vector3.new(10, 30, 10),
		Position = position,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(200, 220, 255),
		Transparency = 0.9,
		CanCollide = false,
	})

	wind:SetAttribute("WindDirection", direction)
	wind:SetAttribute("WindStrength", strength)
	CollectionService:AddTag(wind, "WindCurrent")

	return wind
end

function SectionBuilder.CreateUpdraft(position: Vector3, size: Vector3?, liftStrength: number?): BasePart
	local updraft = SectionBuilder.CreatePart({
		Name = "Updraft",
		Size = size or Vector3.new(15, 50, 15),
		Position = position,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(255, 255, 200),
		Transparency = 0.85,
		CanCollide = false,
	})

	updraft:SetAttribute("LiftStrength", liftStrength or 60)
	CollectionService:AddTag(updraft, "Updraft")

	-- Particle effect
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Transparency = NumberSequence.new(0.5, 1)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(20, 30)
	particles.SpreadAngle = Vector2.new(10, 10)
	particles.Parent = updraft

	return updraft
end

function SectionBuilder.CreateFloatingIsland(position: Vector3, radius: number): Model
	local island = Instance.new("Model")
	island.Name = "FloatingIsland"

	-- Main body
	local body = SectionBuilder.CreatePart({
		Name = "Body",
		Size = Vector3.new(radius * 2, radius, radius * 2),
		Position = position,
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(100, 150, 50),
	})
	body.Parent = island

	-- Bottom rock
	local bottom = SectionBuilder.CreatePart({
		Name = "Bottom",
		Size = Vector3.new(radius * 1.5, radius * 0.8, radius * 1.5),
		Position = position - Vector3.new(0, radius * 0.7, 0),
		Material = Enum.Material.Rock,
		Color = Color3.fromRGB(100, 80, 60),
	})
	bottom.Parent = island

	return island
end

-- ============================================================================
-- SECTION BUILDING
-- ============================================================================

function SectionBuilder.Build(config: table): Model
	local section = Instance.new("Model")
	section.Name = string.format("Section_%s_%d", config.Dimension, config.SectionNumber)

	-- Set section attributes
	section:SetAttribute("SectionNumber", config.SectionNumber)
	section:SetAttribute("Dimension", config.Dimension)
	section:SetAttribute("Difficulty", config.Difficulty)

	local basePos = config.Position or Vector3.new(0, 0, 0)

	-- Build dimension-specific section
	if config.Dimension == "Gravity" then
		SectionBuilder.BuildGravitySection(section, config, basePos)
	elseif config.Dimension == "Tiny" then
		SectionBuilder.BuildTinySection(section, config, basePos)
	elseif config.Dimension == "Void" then
		SectionBuilder.BuildVoidSection(section, config, basePos)
	elseif config.Dimension == "Sky" then
		SectionBuilder.BuildSkySection(section, config, basePos)
	end

	return section
end

function SectionBuilder.BuildGravitySection(section: Model, config: table, basePos: Vector3)
	local difficulty = config.Difficulty or "Easy"
	local dimConfig = GameConfig.Dimensions.Gravity.Difficulty[difficulty]

	-- Create checkpoint at start
	local checkpoint = SectionBuilder.CreateCheckpoint("Gravity", basePos, config.SectionNumber)
	checkpoint.Parent = section

	-- Create platforms based on difficulty
	local flipsNeeded = dimConfig.FlipsPerSection or 1
	local platformCount = 4 + flipsNeeded

	for i = 1, platformCount do
		local offset = Vector3.new(
			math.sin(i * 0.5) * 20,
			i * 15,
			i * 25
		)

		local platform = SectionBuilder.CreatePlatform("Gravity", basePos + offset)
		platform.Parent = section

		-- Add gravity flip zones between platforms
		if i < platformCount and i % math.ceil(platformCount / flipsNeeded) == 0 then
			local flipDir = (i % 2 == 0) and Vector3.new(0, -1, 0) or Vector3.new(0, 1, 0)
			local flipZone = SectionBuilder.CreateGravityFlipZone(
				basePos + offset + Vector3.new(0, 8, 12),
				Vector3.new(15, 15, 5),
				flipDir
			)
			flipZone.Parent = section
		end
	end
end

function SectionBuilder.BuildTinySection(section: Model, config: table, basePos: Vector3)
	local difficulty = config.Difficulty or "Easy"
	local dimConfig = GameConfig.Dimensions.Tiny.Difficulty[difficulty]
	local targetScale = dimConfig.Scale or 1

	-- Create checkpoint at start
	local checkpoint = SectionBuilder.CreateCheckpoint("Tiny", basePos, config.SectionNumber)
	checkpoint.Parent = section

	-- Create scale zone at entrance
	local scaleZone = SectionBuilder.CreateScaleZone(basePos + Vector3.new(0, 5, 10), Vector3.new(10, 10, 5), targetScale)
	scaleZone.Parent = section

	-- Create giant obstacles and platforms
	local obstacleTypes = {"Pencil", "Button", "Book"}

	for i = 1, 5 do
		local offset = Vector3.new(
			(math.random() - 0.5) * 40,
			0,
			i * 30
		)

		-- Giant obstacles
		if math.random() > 0.5 then
			local obstacleType = obstacleTypes[math.random(1, #obstacleTypes)]
			local obstacle = SectionBuilder.CreateGiantObstacle(basePos + offset, obstacleType)
			obstacle.Parent = section
		end

		-- Platforms (scaled for tiny players)
		local platSize = Vector3.new(8, 2, 8) / targetScale
		local platform = SectionBuilder.CreatePlatform("Tiny", basePos + offset + Vector3.new(0, 5, 0), platSize)
		platform.Parent = section
	end
end

function SectionBuilder.BuildVoidSection(section: Model, config: table, basePos: Vector3)
	local difficulty = config.Difficulty or "Easy"
	local dimConfig = GameConfig.Dimensions.Void.Difficulty[difficulty]
	local crumbleDelay = dimConfig.CrumbleDelay or 2.5

	-- Create checkpoint with safe zone
	local checkpoint = SectionBuilder.CreateCheckpoint("Void", basePos, config.SectionNumber)
	checkpoint.Parent = section

	local safeZone = SectionBuilder.CreateSafeZone(basePos + Vector3.new(0, 0.5, 0))
	safeZone.Parent = section

	-- Create crumbling platforms path
	local platformCount = 8

	for i = 1, platformCount do
		local offset = Vector3.new(
			math.sin(i * 0.8) * 15,
			math.sin(i * 0.3) * 5,
			i * 20
		)

		local platform = SectionBuilder.CreateCrumblingPlatform(
			basePos + offset,
			Vector3.new(10, 2, 10),
			crumbleDelay - (i * 0.1) -- Gets faster as you progress
		)
		platform.Parent = section
	end
end

function SectionBuilder.BuildSkySection(section: Model, config: table, basePos: Vector3)
	local difficulty = config.Difficulty or "Easy"
	local dimConfig = GameConfig.Dimensions.Sky.Difficulty[difficulty]
	local gapDistance = dimConfig.GapDistance or 50
	local windStrength = dimConfig.WindStrength or 20

	-- Create checkpoint on floating island
	local startIsland = SectionBuilder.CreateFloatingIsland(basePos, 15)
	startIsland.Parent = section

	local checkpoint = SectionBuilder.CreateCheckpoint("Sky", basePos + Vector3.new(0, 10, 0), config.SectionNumber)
	checkpoint.Parent = section

	-- Create cloud platforms and islands
	for i = 1, 4 do
		local offset = Vector3.new(
			math.sin(i * 1.2) * 30,
			math.sin(i * 0.5) * 20,
			i * gapDistance
		)

		-- Alternating cloud and island
		if i % 2 == 0 then
			local island = SectionBuilder.CreateFloatingIsland(basePos + offset, 10)
			island.Parent = section
		else
			local cloud = SectionBuilder.CreateCloudPlatform(basePos + offset, Vector3.new(15, 5, 15))
			cloud.Parent = section
		end

		-- Add wind current between platforms
		if i < 4 then
			local windOffset = offset + Vector3.new(0, 10, gapDistance * 0.5)
			local windDir = Vector3.new(math.sin(i), 0.5, math.cos(i)).Unit
			local windCurrent = SectionBuilder.CreateWindCurrent(
				basePos + windOffset,
				Vector3.new(20, 40, 20),
				windDir,
				windStrength
			)
			windCurrent.Parent = section
		end
	end

	-- Add updraft at the end
	local updraft = SectionBuilder.CreateUpdraft(
		basePos + Vector3.new(0, 20, gapDistance * 3),
		Vector3.new(20, 60, 20),
		80
	)
	updraft.Parent = section
end

-- ============================================================================
-- DIMENSION GENERATION
-- ============================================================================

function SectionBuilder.GenerateDimension(dimension: string, seed: number?): Model
	local dimModel = Instance.new("Model")
	dimModel.Name = dimension .. "Dimension"

	local dimConfig = GameConfig.Dimensions[dimension]
	if not dimConfig then
		warn("[SectionBuilder] Unknown dimension: " .. dimension)
		return dimModel
	end

	-- Use seed for deterministic generation
	if seed then
		math.randomseed(seed)
	end

	local sectionCount = dimConfig.Settings.SectionCount or 20
	local currentPos = Vector3.new(0, 0, 0)

	for i = 1, sectionCount do
		-- Determine difficulty based on section number
		local difficulty = "Easy"
		for diff, config in pairs(dimConfig.Difficulty) do
			if i >= config.Sections[1] and i <= config.Sections[2] then
				difficulty = diff
				break
			end
		end

		-- Build section
		local section = SectionBuilder.Build({
			Dimension = dimension,
			SectionNumber = i,
			Difficulty = difficulty,
			Position = currentPos,
		})
		section.Parent = dimModel

		-- Move position forward for next section
		currentPos = currentPos + Vector3.new(0, 50, 150)
	end

	-- Add finish line at end
	local finishLine = SectionBuilder.CreateFinishLine(dimension, currentPos + Vector3.new(0, 2, 20))
	finishLine.Parent = dimModel

	print(string.format("[SectionBuilder] Generated %s with %d sections", dimension, sectionCount))

	return dimModel
end

return SectionBuilder
