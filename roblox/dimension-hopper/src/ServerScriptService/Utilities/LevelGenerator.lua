--[[
	LevelGenerator.lua
	High-level level generation using SectionBuilder and SectionTemplates

	Features:
	- Generate complete dimensions with proper section flow
	- Mix templates for variety
	- Ensure smooth difficulty progression
	- Add collectibles and secrets
	- Create spawn/finish areas

	Usage:
	local dimension = LevelGenerator.GenerateDimension("Gravity", {
		Seed = 12345,
		SectionCount = 20,
	})
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SectionBuilder = require(ServerScriptService.Utilities.SectionBuilder)
local SectionTemplates = require(ServerScriptService.Utilities.SectionTemplates)

local LevelGenerator = {}

-- CRITICAL FIX: Store fragment animation connections for proper cleanup
-- Prevents memory leak from orphaned animation threads
local FragmentConnections = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SECTION_SPACING = {
	Gravity = Vector3.new(0, 50, 150),
	Tiny = Vector3.new(0, 0, 120),
	Void = Vector3.new(0, 0, 100),
	Sky = Vector3.new(0, 30, 200),
}

local FRAGMENT_CHANCE = 0.3 -- 30% chance per section
local SECRET_CHANCE = 0.1 -- 10% chance for secret area

-- ============================================================================
-- SPAWN AREA CREATION
-- ============================================================================

function LevelGenerator.CreateSpawnArea(dimension: string, position: Vector3): Model
	local spawn = Instance.new("Model")
	spawn.Name = "SpawnArea"

	local dimConfig = GameConfig.Dimensions[dimension]
	local theme = dimConfig.Theme

	-- Main platform
	local platform = SectionBuilder.CreatePart({
		Name = "SpawnPlatform",
		Size = Vector3.new(40, 3, 40),
		Position = position,
		Material = Enum.Material.SmoothPlastic,
		Color = theme.PrimaryColor,
	})
	platform.Parent = spawn

	-- Decorative border
	local borderColors = {theme.AccentColor, theme.SecondaryColor}
	for i = 1, 4 do
		local rotation = CFrame.Angles(0, math.rad(90 * i), 0)
		local offset = rotation * Vector3.new(18, 2, 0)

		local border = SectionBuilder.CreatePart({
			Name = "Border_" .. i,
			Size = Vector3.new(4, 4, 40),
			Position = position + offset + Vector3.new(0, 2, 0),
			Material = Enum.Material.Neon,
			Color = borderColors[((i - 1) % 2) + 1],
		})
		border.Parent = spawn
	end

	-- Spawn point marker
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Position = position + Vector3.new(0, 5, 0)
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Neutral = true
	spawnPoint.Parent = spawn

	-- Starting checkpoint
	local checkpoint = SectionBuilder.CreateCheckpoint(dimension, position + Vector3.new(0, 2, 15), 0)
	checkpoint.Parent = spawn

	-- Dimension name display
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DimensionSign"
	billboardGui.Size = UDim2.new(0, 300, 0, 100)
	billboardGui.StudsOffset = Vector3.new(0, 15, 0)
	billboardGui.Adornee = platform
	billboardGui.Parent = spawn

	local dimensionLabel = Instance.new("TextLabel")
	dimensionLabel.Size = UDim2.new(1, 0, 0.6, 0)
	dimensionLabel.BackgroundTransparency = 1
	dimensionLabel.Font = Enum.Font.GothamBold
	dimensionLabel.TextSize = 36
	dimensionLabel.TextColor3 = theme.AccentColor
	dimensionLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	dimensionLabel.TextStrokeTransparency = 0.5
	dimensionLabel.Text = dimConfig.Icon .. " " .. dimConfig.DisplayName .. " " .. dimConfig.Icon
	dimensionLabel.Parent = billboardGui

	local descLabel = Instance.new("TextLabel")
	descLabel.Position = UDim2.new(0, 0, 0.6, 0)
	descLabel.Size = UDim2.new(1, 0, 0.4, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 18
	descLabel.TextColor3 = Color3.new(1, 1, 1)
	descLabel.Text = dimConfig.Description
	descLabel.Parent = billboardGui

	return spawn
end

-- ============================================================================
-- FINISH AREA CREATION
-- ============================================================================

function LevelGenerator.CreateFinishArea(dimension: string, position: Vector3): Model
	local finish = Instance.new("Model")
	finish.Name = "FinishArea"

	local dimConfig = GameConfig.Dimensions[dimension]
	local theme = dimConfig.Theme

	-- Victory platform
	local platform = SectionBuilder.CreatePart({
		Name = "FinishPlatform",
		Size = Vector3.new(30, 3, 30),
		Position = position,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0), -- Gold
	})
	platform.Parent = finish

	-- Finish line
	local finishLine = SectionBuilder.CreateFinishLine(dimension, position + Vector3.new(0, 2, -10))
	finishLine.Parent = finish

	-- Victory arch
	local archLeft = SectionBuilder.CreatePart({
		Name = "ArchLeft",
		Size = Vector3.new(3, 20, 3),
		Position = position + Vector3.new(-12, 10, -10),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0),
	})
	archLeft.Parent = finish

	local archRight = SectionBuilder.CreatePart({
		Name = "ArchRight",
		Size = Vector3.new(3, 20, 3),
		Position = position + Vector3.new(12, 10, -10),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0),
	})
	archRight.Parent = finish

	local archTop = SectionBuilder.CreatePart({
		Name = "ArchTop",
		Size = Vector3.new(27, 3, 3),
		Position = position + Vector3.new(0, 20, -10),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 0),
	})
	archTop.Parent = finish

	-- "FINISH" sign
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FinishSign"
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = archTop
	billboard.Parent = finish

	local finishLabel = Instance.new("TextLabel")
	finishLabel.Size = UDim2.new(1, 0, 1, 0)
	finishLabel.BackgroundTransparency = 1
	finishLabel.Font = Enum.Font.GothamBold
	finishLabel.TextSize = 48
	finishLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	finishLabel.TextStrokeColor3 = Color3.fromRGB(255, 215, 0)
	finishLabel.TextStrokeTransparency = 0
	finishLabel.Text = "🏁 FINISH 🏁"
	finishLabel.Parent = billboard

	-- Confetti particles
	for _, part in ipairs({archLeft, archRight}) do
		local confetti = Instance.new("ParticleEmitter")
		confetti.Name = "Confetti"
		confetti.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 255, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 100, 255)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255)),
		})
		confetti.Size = NumberSequence.new(0.5, 0.2)
		confetti.Transparency = NumberSequence.new(0, 1)
		confetti.Lifetime = NumberRange.new(2, 4)
		confetti.Rate = 10
		confetti.Speed = NumberRange.new(5, 15)
		confetti.SpreadAngle = Vector2.new(30, 30)
		confetti.Parent = part
	end

	return finish
end

-- ============================================================================
-- COLLECTIBLE CREATION
-- ============================================================================

function LevelGenerator.CreateFragment(dimension: string, position: Vector3, fragmentNumber: number): BasePart
	local dimConfig = GameConfig.Dimensions[dimension]

	local fragment = SectionBuilder.CreatePart({
		Name = "Fragment_" .. fragmentNumber,
		Size = Vector3.new(2, 2, 2),
		Position = position,
		Material = Enum.Material.Neon,
		Color = dimConfig.Theme.AccentColor,
		CanCollide = false,
	})

	fragment:SetAttribute("FragmentNumber", fragmentNumber)
	fragment:SetAttribute("Dimension", dimension)
	CollectionService:AddTag(fragment, "DimensionalFragment")

	-- Spinning animation
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 2, 0)
	spin.MaxTorque = Vector3.new(0, math.huge, 0)
	spin.Parent = fragment

	-- Glow effect
	local light = Instance.new("PointLight")
	light.Color = dimConfig.Theme.AccentColor
	light.Brightness = 2
	light.Range = 8
	light.Parent = fragment

	-- Float up and down
	local float = Instance.new("BodyPosition")
	float.MaxForce = Vector3.new(0, math.huge, 0)
	float.Position = position
	float.Parent = fragment

	-- CRITICAL FIX: Use Heartbeat connection instead of task.spawn loop
	-- Allows proper cleanup and prevents memory leaks
	local startY = position.Y
	local startTime = tick()

	local floatConnection = RunService.Heartbeat:Connect(function()
		-- Check if fragment still exists
		if not fragment.Parent or not fragment:IsDescendantOf(game) then
			floatConnection:Disconnect()
			FragmentConnections[fragment] = nil
			return
		end

		-- Animate floating
		local elapsed = tick() - startTime
		float.Position = Vector3.new(
			position.X,
			startY + math.sin(elapsed * 2) * 0.5,
			position.Z
		)
	end)

	-- Store connection for cleanup
	FragmentConnections[fragment] = floatConnection

	-- Cleanup on ancestry changed (fragment destroyed or removed from game)
	fragment.AncestryChanged:Connect(function()
		if not fragment:IsDescendantOf(game) then
			if FragmentConnections[fragment] then
				FragmentConnections[fragment]:Disconnect()
				FragmentConnections[fragment] = nil
			end
		end
	end)

	return fragment
end

-- ============================================================================
-- SECTION GENERATION
-- ============================================================================

function LevelGenerator.GenerateSection(dimension: string, sectionNumber: number, position: Vector3, seed: number): Model
	local dimConfig = GameConfig.Dimensions[dimension]

	-- Determine difficulty
	local difficulty = "Easy"
	for diff, config in pairs(dimConfig.Difficulty) do
		if type(config.Sections) == "table" then
			if sectionNumber >= config.Sections[1] and sectionNumber <= config.Sections[2] then
				difficulty = diff
				break
			end
		end
	end

	-- Get random template for this difficulty
	math.randomseed(seed + sectionNumber)
	local templateName, template = SectionTemplates.GetRandomTemplate(dimension, difficulty)

	-- Build section
	local section = SectionBuilder.Build({
		Dimension = dimension,
		SectionNumber = sectionNumber,
		Difficulty = difficulty,
		Position = position,
		Template = templateName,
	})

	-- Maybe add a fragment
	if math.random() < FRAGMENT_CHANCE then
		-- Find a good position within the section (above a platform)
		local fragmentPos = position + Vector3.new(
			(math.random() - 0.5) * 20,
			10 + math.random() * 10,
			math.random() * 50
		)
		local fragment = LevelGenerator.CreateFragment(dimension, fragmentPos, sectionNumber)
		fragment.Parent = section
	end

	return section
end

-- ============================================================================
-- DIMENSION GENERATION
-- ============================================================================

function LevelGenerator.GenerateDimension(dimension: string, config: table?): Model
	config = config or {}
	local seed = config.Seed or math.random(1, 1000000)
	math.randomseed(seed)

	local dimConfig = GameConfig.Dimensions[dimension]
	if not dimConfig then
		warn("[LevelGenerator] Unknown dimension: " .. dimension)
		return Instance.new("Model")
	end

	local sectionCount = config.SectionCount or dimConfig.Settings.SectionCount or 20
	local spacing = SECTION_SPACING[dimension] or Vector3.new(0, 30, 150)

	local dimensionModel = Instance.new("Model")
	dimensionModel.Name = dimension .. "_Dimension"
	dimensionModel:SetAttribute("Dimension", dimension)
	dimensionModel:SetAttribute("Seed", seed)
	dimensionModel:SetAttribute("SectionCount", sectionCount)

	-- Current position tracker
	local currentPos = Vector3.new(0, 0, 0)

	-- Create spawn area
	local spawnArea = LevelGenerator.CreateSpawnArea(dimension, currentPos)
	spawnArea.Parent = dimensionModel

	-- Move to first section position
	currentPos = currentPos + spacing

	-- Generate all sections
	for i = 1, sectionCount do
		local section = LevelGenerator.GenerateSection(dimension, i, currentPos, seed)
		section.Parent = dimensionModel

		-- Move to next section position
		currentPos = currentPos + spacing

		-- Add some variation
		currentPos = currentPos + Vector3.new(
			(math.random() - 0.5) * 20,
			(math.random() - 0.5) * 10,
			0
		)
	end

	-- Create finish area
	local finishArea = LevelGenerator.CreateFinishArea(dimension, currentPos)
	finishArea.Parent = dimensionModel

	print(string.format("[LevelGenerator] Generated %s dimension with %d sections (seed: %d)",
		dimension, sectionCount, seed))

	return dimensionModel
end

-- ============================================================================
-- MARATHON GENERATION
-- ============================================================================

function LevelGenerator.GenerateMarathon(seed: number?): Model
	seed = seed or math.random(1, 1000000)

	local marathonModel = Instance.new("Model")
	marathonModel.Name = "Marathon"
	marathonModel:SetAttribute("Seed", seed)

	local currentPos = Vector3.new(0, 0, 0)
	local sectionsPerDimension = 10 -- Shorter for marathon

	for i, dimensionName in ipairs(GameConfig.DimensionOrder) do
		local dimSeed = seed + (i * 1000)

		-- Generate dimension with fewer sections
		local dimension = LevelGenerator.GenerateDimension(dimensionName, {
			Seed = dimSeed,
			SectionCount = sectionsPerDimension,
		})

		-- Position the dimension
		dimension:PivotTo(CFrame.new(currentPos))
		dimension.Parent = marathonModel

		-- Calculate next dimension position
		local bounds = dimension:GetBoundingBox()
		local size = bounds.Size
		currentPos = currentPos + Vector3.new(0, 0, size.Z + 50)

		-- Add transition zone between dimensions
		if i < #GameConfig.DimensionOrder then
			local transitionZone = LevelGenerator.CreateTransitionZone(
				dimensionName,
				GameConfig.DimensionOrder[i + 1],
				currentPos - Vector3.new(0, 0, 25)
			)
			transitionZone.Parent = marathonModel
		end
	end

	print(string.format("[LevelGenerator] Generated marathon with %d dimensions (seed: %d)",
		#GameConfig.DimensionOrder, seed))

	return marathonModel
end

function LevelGenerator.CreateTransitionZone(fromDimension: string, toDimension: string, position: Vector3): Model
	local transition = Instance.new("Model")
	transition.Name = "Transition_" .. fromDimension .. "_to_" .. toDimension

	local fromConfig = GameConfig.Dimensions[fromDimension]
	local toConfig = GameConfig.Dimensions[toDimension]

	-- Gradient platform
	local platform = SectionBuilder.CreatePart({
		Name = "TransitionPlatform",
		Size = Vector3.new(20, 3, 50),
		Position = position,
		Material = Enum.Material.SmoothPlastic,
		Color = fromConfig.Theme.PrimaryColor,
	})
	platform.Parent = transition

	-- Portal effect
	local portal = SectionBuilder.CreatePart({
		Name = "Portal",
		Size = Vector3.new(15, 15, 1),
		Position = position + Vector3.new(0, 10, 20),
		Material = Enum.Material.ForceField,
		Color = toConfig.Theme.AccentColor,
		Transparency = 0.5,
		CanCollide = false,
	})
	portal.Parent = transition

	-- Portal particles
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(toConfig.Theme.AccentColor)
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 30
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = portal

	-- Sign showing next dimension
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = portal
	billboard.Parent = transition

	local nextLabel = Instance.new("TextLabel")
	nextLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Font = Enum.Font.Gotham
	nextLabel.TextSize = 16
	nextLabel.TextColor3 = Color3.new(1, 1, 1)
	nextLabel.Text = "NEXT DIMENSION"
	nextLabel.Parent = billboard

	local dimLabel = Instance.new("TextLabel")
	dimLabel.Position = UDim2.new(0, 0, 0.5, 0)
	dimLabel.Size = UDim2.new(1, 0, 0.5, 0)
	dimLabel.BackgroundTransparency = 1
	dimLabel.Font = Enum.Font.GothamBold
	dimLabel.TextSize = 24
	dimLabel.TextColor3 = toConfig.Theme.AccentColor
	dimLabel.Text = toConfig.Icon .. " " .. toConfig.DisplayName
	dimLabel.Parent = billboard

	return transition
end

-- ============================================================================
-- PRACTICE MODE
-- ============================================================================

function LevelGenerator.GeneratePracticeLevel(dimension: string, difficulty: string?): Model
	local practiceModel = Instance.new("Model")
	practiceModel.Name = "Practice_" .. dimension

	local dimConfig = GameConfig.Dimensions[dimension]

	-- Find section range for difficulty
	local sectionRange = {1, 5}
	if difficulty and dimConfig.Difficulty[difficulty] then
		sectionRange = dimConfig.Difficulty[difficulty].Sections or sectionRange
	end

	local sectionCount = sectionRange[2] - sectionRange[1] + 1

	-- Generate with fixed easy seed for consistency
	local practice = LevelGenerator.GenerateDimension(dimension, {
		Seed = 42, -- Fixed seed for practice
		SectionCount = math.min(sectionCount, 10),
	})

	practice.Name = "Practice_" .. dimension
	practice:SetAttribute("Mode", "Practice")
	practice:SetAttribute("Difficulty", difficulty or "All")

	return practice
end

-- Generate a single practice section (for per-section practice)
function LevelGenerator.GeneratePracticeSection(dimension: string, sectionNumber: number, config: table?): Model
	config = config or {}
	local seed = config.seed or os.time()
	math.randomseed(seed)

	local dimConfig = GameConfig.Dimensions[dimension]
	if not dimConfig then
		warn("[LevelGenerator] Unknown dimension: " .. dimension)
		return nil
	end

	local practiceModel = Instance.new("Model")
	practiceModel.Name = string.format("Practice_%s_Section%d", dimension, sectionNumber)
	practiceModel:SetAttribute("Dimension", dimension)
	practiceModel:SetAttribute("SectionNumber", sectionNumber)
	practiceModel:SetAttribute("Mode", "Practice")

	-- Create spawn area at origin
	local spawnArea = LevelGenerator.CreateSpawnArea(dimension, Vector3.new(0, 0, 0))
	spawnArea.Parent = practiceModel

	-- Generate the target section
	local spacing = SECTION_SPACING[dimension] or Vector3.new(0, 30, 150)
	local sectionPos = spacing

	local section = LevelGenerator.GenerateSection(dimension, sectionNumber, sectionPos, seed)
	section.Parent = practiceModel

	-- Add a simple finish area after the section
	local finishPos = sectionPos + spacing
	local finishArea = LevelGenerator.CreateFinishArea(dimension, finishPos)
	finishArea.Parent = practiceModel

	-- Add spawn marker for respawn
	local respawnPoint = Instance.new("SpawnLocation")
	respawnPoint.Name = "PracticeSpawn"
	respawnPoint.Position = Vector3.new(0, 5, 0)
	respawnPoint.Size = Vector3.new(6, 1, 6)
	respawnPoint.Anchored = true
	respawnPoint.CanCollide = false
	respawnPoint.Transparency = 1
	respawnPoint.Neutral = true
	respawnPoint.Parent = practiceModel

	print(string.format("[LevelGenerator] Generated practice section: %s Section %d",
		dimension, sectionNumber))

	return practiceModel
end

-- ============================================================================
-- DIMENSION LEVEL GENERATION (for DimensionService integration)
-- ============================================================================

function LevelGenerator.GenerateDimensionLevel(dimension: string, options: table?): Model
	options = options or {}

	local seed = options.seed or math.random(1, 1000000)
	local sectionCount = options.sectionCount
	local difficulty = options.difficulty or "normal"

	local dimConfig = GameConfig.Dimensions[dimension]
	if not dimConfig then
		warn("[LevelGenerator] Unknown dimension: " .. dimension)
		return nil
	end

	-- Use config section count if not specified
	if not sectionCount then
		sectionCount = dimConfig.Settings.SectionCount or 20
	end

	-- Adjust section count based on difficulty
	if difficulty == "easy" then
		sectionCount = math.floor(sectionCount * 0.7)
	elseif difficulty == "hard" then
		sectionCount = math.floor(sectionCount * 1.3)
	end

	-- Generate the dimension
	local dimensionModel = LevelGenerator.GenerateDimension(dimension, {
		Seed = seed,
		SectionCount = sectionCount,
	})

	if dimensionModel then
		dimensionModel:SetAttribute("Difficulty", difficulty)
	end

	return dimensionModel
end

return LevelGenerator
