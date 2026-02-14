# Week 1: Project Setup & Foundation

## Day 1-2: Toolchain Setup

### Initialize Rojo Project
```bash
# Install toolchain (run once)
curl -L https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-linux-x86_64 -o rokit
chmod +x rokit
sudo mv rokit /usr/local/bin/

# Initialize project
mkdir procedural-obby && cd procedural-obby
rokit init
rokit add rojo-rbx/rojo@7.4.3
rokit add Kampfkarren/selene@0.27.1
rokit add JohnnyMorganz/stylua@0.20.0
rokit install

# Initialize Rojo
rojo init
```

### Create Project Structure
```
procedural-obby/
├── .github/
│   └── workflows/
│       └── ci.yml
├── src/
│   ├── ServerScriptService/
│   │   ├── init.server.lua
│   │   └── Services/
│   │       ├── ObbyService/
│   │       │   ├── init.lua
│   │       │   ├── Generator.lua
│   │       │   ├── SectionPool.lua
│   │       │   ├── MemoryManager.lua      # NEW: Memory cleanup
│   │       │   └── AntiCheat.lua          # NEW: Validation
│   │       ├── RoundService.lua
│   │       ├── DataService.lua
│   │       └── AnalyticsService.lua
│   ├── ServerStorage/
│   │   └── Sections/
│   │       ├── Easy/
│   │       ├── Medium/
│   │       ├── Hard/
│   │       └── Special/
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Config/
│   │   │   │   ├── GameConfig.lua
│   │   │   │   ├── SectionConfig.lua
│   │   │   │   └── MobileConfig.lua      # NEW: Mobile optimization
│   │   │   └── Packages/
│   │   │       └── _Index/               # Wally packages
│   │   └── Assets/
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── Controllers/
│               ├── UIController.client.lua
│               └── MobileOptimizer.client.lua  # NEW
├── default.project.json
├── wally.toml
├── selene.toml
├── .stylua.toml
└── README.md
```

### Configure default.project.json
```json
{
  "name": "ProceduralObby",
  "sourcemap": {
    "enabled": true
  },
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$path": "src/ServerScriptService"
    },
    "ServerStorage": {
      "$path": "src/ServerStorage"
    },
    "ReplicatedStorage": {
      "$path": "src/ReplicatedStorage"
    },
    "StarterPlayer": {
      "$path": "src/StarterPlayer"
    }
  }
}
```

### Configure Wally (Package Manager)
**wally.toml**
```toml
[package]
name = "yourname/procedural-obby"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
ProfileService = "madstudioroblox/profileservice@1.0.0"
TestEZ = "roblox/testez@0.4.1"
Promise = "evaera/promise@4.0.0"

[dev-dependencies]
```

### Configure Selene
**selene.toml**
```toml
std = "roblox"

[lints]
unused_variable = "warn"
deprecated = "warn"
incorrect_standard_library_use = "warn"
shadowing = "warn"
```

### Configure StyLua
**.stylua.toml**
```toml
column_width = 120
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "Double"
call_parentheses = "Always"

[sort_requires]
enabled = true
```

## Day 3-4: DevForum Script Integration

### Port DevForum Self-Generating Obby Script

**src/ServerScriptService/Services/ObbyService/Generator.lua**
```lua
--[[
	Generator.lua
	Procedural obby generation using CFrame-based connection points
	Based on DevForum Self-Generating Obby (hardened for production)
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SectionConfig = require(ReplicatedStorage.Shared.Config.SectionConfig)

local Generator = {}
Generator.__index = Generator

function Generator.new(seed: number?)
	local self = setmetatable({}, Generator)

	self.seed = seed or os.time()
	self.rng = Random.new(self.seed)
	self.previousStage = nil
	self.stageCount = 0
	self.turnpointCounter = 0
	self.activeStages = {}  -- Track for memory management

	return self
end

function Generator:CreateStage(stageType: string, stageNumber: number, isFinish: boolean): Model?
	local success, result = pcall(function()
		-- Select section
		local stage
		if isFinish then
			stage = ServerStorage.Sections.Special.Finish:Clone()
		else
			stage = self:SelectSection(stageType)
		end

		if not stage then
			warn("Failed to find section of type:", stageType)
			return nil
		end

		-- Validate section structure
		assert(stage.PrimaryPart, "Section missing PrimaryPart: " .. stage.Name)
		assert(stage:FindFirstChild("Next"), "Section missing Next part: " .. stage.Name)
		assert(stage:FindFirstChild("Checkpoint"), "Section missing Checkpoint: " .. stage.Name)

		-- Apply theming
		self:ApplyTheming(stage)

		-- Position stage
		self:PositionStage(stage, stageNumber)

		-- Setup checkpoint
		self:SetupCheckpoint(stage, stageNumber)

		-- Store reference
		stage.Name = "Stage_" .. stageNumber
		stage:SetAttribute("StageNumber", stageNumber)
		stage:SetAttribute("Seed", self.seed)
		stage:SetAttribute("GeneratedAt", os.time())

		-- Parent to workspace
		stage.Parent = workspace.Tower

		-- Track for cleanup
		table.insert(self.activeStages, stage)

		self.previousStage = stage
		self.stageCount += 1

		return stage
	end)

	if not success then
		warn("Error creating stage:", result)
		return nil
	end

	return result
end

function Generator:SelectSection(difficulty: string): Model?
	local sectionsFolder = ServerStorage.Sections:FindFirstChild(difficulty)
	if not sectionsFolder then
		return nil
	end

	local sections = sectionsFolder:GetChildren()
	if #sections == 0 then
		return nil
	end

	-- Weighted selection based on SectionConfig
	local totalWeight = 0
	local weights = {}

	for _, section in ipairs(sections) do
		local config = SectionConfig.Sections[section.Name]
		local weight = config and config.SpawnWeight or 1.0
		totalWeight += weight
		table.insert(weights, { section = section, weight = weight })
	end

	local roll = self.rng:NextNumber(0, totalWeight)
	local cumulative = 0

	for _, data in ipairs(weights) do
		cumulative += data.weight
		if roll <= cumulative then
			return data.section:Clone()
		end
	end

	-- Fallback
	return sections[self.rng:NextInteger(1, #sections)]:Clone()
end

function Generator:ApplyTheming(stage: Model)
	local colorScheme = GameConfig.ColorSchemes[self.rng:NextInteger(1, #GameConfig.ColorSchemes)]

	local coloredFolder = stage:FindFirstChild("Colored")
	if not coloredFolder then return end

	-- Color group 1
	local group1 = coloredFolder:FindFirstChild("One")
	if group1 then
		for _, part in ipairs(group1:GetChildren()) do
			if part:IsA("BasePart") then
				part.Color = colorScheme.Primary
			end
		end
	end

	-- Color group 2
	local group2 = coloredFolder:FindFirstChild("Two")
	if group2 then
		for _, part in ipairs(group2:GetChildren()) do
			if part:IsA("BasePart") then
				part.Color = colorScheme.Secondary
			end
		end
	end
end

function Generator:PositionStage(stage: Model, stageNumber: number)
	if not self.previousStage then
		-- First stage - position at origin
		stage:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
		return
	end

	-- Calculate turnpoint (every N stages, rotate 90 degrees)
	local shouldTurn = self.turnpointCounter >= GameConfig.TurnpointInterval
	if shouldTurn then
		self.turnpointCounter = 0
	else
		self.turnpointCounter += 1
	end

	-- Get previous Next point
	local previousNext = self.previousStage:FindFirstChild("Next")
	if not previousNext then
		warn("Previous stage missing Next point")
		stage:SetPrimaryPartCFrame(self.previousStage:GetPivot() + Vector3.new(0, 10, 0))
		return
	end

	-- Position at connection point
	if shouldTurn then
		-- Alternate between 90 and -90 degrees
		local angle = (stageNumber % 2 == 0) and 90 or -90
		stage:SetPrimaryPartCFrame(
			CFrame.new(previousNext.Position) * CFrame.Angles(0, math.rad(angle), 0)
		)
	else
		stage:SetPrimaryPartCFrame(CFrame.new(previousNext.Position))
	end

	-- Cleanup previous Next marker
	previousNext:Destroy()
end

function Generator:SetupCheckpoint(stage: Model, stageNumber: number)
	local checkpoint = stage:FindFirstChild("Checkpoint")
	if not checkpoint then return end

	checkpoint:SetAttribute("StageNumber", stageNumber)

	-- Add touch detection (will be handled by separate checkpoint service)
	checkpoint.CanCollide = false
	checkpoint.Transparency = 1
	checkpoint.Name = "Checkpoint_" .. stageNumber
end

function Generator:GetActiveStages(): {Model}
	return self.activeStages
end

function Generator:Reset()
	-- Cleanup all stages
	for _, stage in ipairs(self.activeStages) do
		if stage and stage.Parent then
			stage:Destroy()
		end
	end

	self.activeStages = {}
	self.previousStage = nil
	self.stageCount = 0
	self.turnpointCounter = 0
end

return Generator
```

### Create Configuration Files

**src/ReplicatedStorage/Shared/Config/GameConfig.lua**
```lua
local GameConfig = {
	-- Round Settings
	RoundDuration = 480, -- 8 minutes in seconds
	IntermissionDuration = 15, -- seconds

	-- Generation Settings
	TotalStages = 50,
	TurnpointInterval = 8, -- Rotate every 8 stages

	-- Difficulty Progression
	DifficultyBreakpoints = {
		{ maxStage = 15, difficulty = "Easy" },
		{ maxStage = 35, difficulty = "Medium" },
		{ maxStage = 50, difficulty = "Hard" },
	},

	-- Theming
	ColorSchemes = {
		{ Primary = Color3.fromRGB(255, 85, 127), Secondary = Color3.fromRGB(85, 170, 255) },
		{ Primary = Color3.fromRGB(170, 85, 255), Secondary = Color3.fromRGB(255, 255, 85) },
		{ Primary = Color3.fromRGB(85, 255, 127), Secondary = Color3.fromRGB(255, 127, 85) },
	},

	-- Memory Management (NEW)
	MaxActiveStages = 20, -- Keep this many stages loaded
	DespawnDistance = 300, -- Studs behind player
	CleanupInterval = 10, -- Seconds between cleanup sweeps

	-- Mobile Optimization (NEW)
	MobileMaxStages = 15,
	MobileShadowsEnabled = false,
	MobileTextureQuality = 512,
}

return GameConfig
```

**src/ReplicatedStorage/Shared/Config/SectionConfig.lua**
```lua
--[[
	Section metadata and spawn weights
	Will be populated as sections are created
]]

local SectionConfig = {
	Sections = {
		-- Example structure (add as sections are built):
		-- ["JumpGap"] = {
		-- 	Difficulty = "Easy",
		-- 	Length = "Short",
		-- 	SpawnWeight = 1.0,
		-- 	Creator = "YourName",
		-- 	Tags = {"Jump", "Linear"},
		-- },
	},
}

return SectionConfig
```

## Day 5: Critical Systems Foundation

### Memory Management System

**src/ServerScriptService/Services/ObbyService/MemoryManager.lua**
```lua
--[[
	MemoryManager.lua
	Handles stage cleanup to prevent memory leaks
	Critical for long-running servers
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)

local MemoryManager = {}
MemoryManager.__index = MemoryManager

function MemoryManager.new(generator)
	local self = setmetatable({}, MemoryManager)

	self.generator = generator
	self.cleanupConnection = nil

	return self
end

function MemoryManager:Start()
	if self.cleanupConnection then
		self.cleanupConnection:Disconnect()
	end

	-- Run cleanup every N seconds
	self.cleanupConnection = task.spawn(function()
		while true do
			task.wait(GameConfig.CleanupInterval)
			self:CleanupDistantStages()
		end
	end)
end

function MemoryManager:CleanupDistantStages()
	local activeStages = self.generator:GetActiveStages()

	-- Find furthest player position
	local maxPlayerStage = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local stage = leaderstats:FindFirstChild("Stage")
			if stage and stage.Value > maxPlayerStage then
				maxPlayerStage = stage.Value
			end
		end
	end

	-- Cleanup stages far behind
	local stagesToRemove = {}
	for i, stage in ipairs(activeStages) do
		local stageNumber = stage:GetAttribute("StageNumber")
		if stageNumber and stageNumber < (maxPlayerStage - GameConfig.MaxActiveStages) then
			table.insert(stagesToRemove, i)

			-- Disconnect any connections
			local connections = stage:GetAttribute("Connections")
			if connections then
				for _, conn in ipairs(connections) do
					if typeof(conn) == "RBXScriptConnection" then
						conn:Disconnect()
					end
				end
			end

			-- Destroy stage
			stage:Destroy()
		end
	end

	-- Remove from active list (reverse order to preserve indices)
	for i = #stagesToRemove, 1, -1 do
		table.remove(activeStages, stagesToRemove[i])
	end

	if #stagesToRemove > 0 then
		print("[MemoryManager] Cleaned up", #stagesToRemove, "stages")
	end
end

function MemoryManager:Stop()
	if self.cleanupConnection then
		task.cancel(self.cleanupConnection)
		self.cleanupConnection = nil
	end
end

return MemoryManager
```

### Basic Anti-Cheat System

**src/ServerScriptService/Services/ObbyService/AntiCheat.lua**
```lua
--[[
	AntiCheat.lua
	Server-side validation for obby progression
	Prevents teleportation and stage skipping
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)

local AntiCheat = {}
AntiCheat.__index = AntiCheat

-- Configuration
local TELEPORT_THRESHOLD = 50 -- Studs per frame
local STAGE_SKIP_TOLERANCE = 2 -- Allow skipping N stages (for speedrun tech)
local FLY_CHECK_DURATION = 3 -- Seconds airborne before flagging
local HIGH_PING_THRESHOLD = 300 -- ms - be lenient with laggy players

function AntiCheat.new()
	local self = setmetatable({}, AntiCheat)

	self.playerData = {} -- { [player] = { lastPosition, lastStage, airborneTime } }
	self.heartbeatConnection = nil

	return self
end

function AntiCheat:Start()
	-- Track player join/leave
	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.playerData[player] = nil
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self:InitializePlayer(player)
	end

	-- Validation loop
	self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:ValidatePlayers(deltaTime)
	end)
end

function AntiCheat:InitializePlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		if humanoidRootPart then
			self.playerData[player] = {
				lastPosition = humanoidRootPart.Position,
				lastStage = 1,
				airborneTime = 0,
				lastValidationTime = tick(),
			}
		end
	end)
end

function AntiCheat:ValidatePlayers(deltaTime: number)
	for player, data in pairs(self.playerData) do
		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChild("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart then continue end

		-- Get player ping
		local ping = player:GetNetworkPing() * 1000 -- Convert to ms
		local isPingHigh = ping > HIGH_PING_THRESHOLD

		-- Teleport detection
		local distance = (rootPart.Position - data.lastPosition).Magnitude
		local threshold = isPingHigh and (TELEPORT_THRESHOLD * 2) or TELEPORT_THRESHOLD

		if distance > threshold and humanoid.Health > 0 then
			self:HandleTeleport(player, distance)
		end

		-- Fly detection
		if humanoid.FloorMaterial == Enum.Material.Air and humanoid.Health > 0 then
			data.airborneTime += deltaTime

			if data.airborneTime > FLY_CHECK_DURATION and not isPingHigh then
				-- Check if velocity is too low (hovering)
				if rootPart.AssemblyLinearVelocity.Y > -10 and rootPart.AssemblyLinearVelocity.Y < 10 then
					self:HandleFly(player)
				end
			end
		else
			data.airborneTime = 0
		end

		-- Stage progression validation
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local currentStage = leaderstats:FindFirstChild("Stage")
			if currentStage then
				local stageJump = currentStage.Value - data.lastStage

				if stageJump > STAGE_SKIP_TOLERANCE then
					self:HandleStageSkip(player, data.lastStage, currentStage.Value)
				elseif stageJump > 0 then
					-- Valid progression
					data.lastStage = currentStage.Value
				end
			end
		end

		-- Update tracking
		data.lastPosition = rootPart.Position
		data.lastValidationTime = tick()
	end
end

function AntiCheat:HandleTeleport(player: Player, distance: number)
	warn("[AntiCheat] Potential teleport detected:", player.Name, "moved", math.floor(distance), "studs")

	-- Increment violation counter
	local violations = player:GetAttribute("AntiCheatViolations") or 0
	player:SetAttribute("AntiCheatViolations", violations + 1)

	if violations >= 3 then
		player:Kick("Unusual movement detected. If you believe this is an error, rejoin the game.")
	else
		-- Reset to last checkpoint
		self:ResetToCheckpoint(player)
	end
end

function AntiCheat:HandleFly(player: Player)
	warn("[AntiCheat] Potential fly detected:", player.Name)

	local violations = player:GetAttribute("AntiCheatViolations") or 0
	player:SetAttribute("AntiCheatViolations", violations + 1)

	if violations >= 3 then
		player:Kick("Unusual movement detected. If you believe this is an error, rejoin the game.")
	else
		self:ResetToCheckpoint(player)
	end
end

function AntiCheat:HandleStageSkip(player: Player, fromStage: number, toStage: number)
	warn("[AntiCheat] Stage skip detected:", player.Name, "from", fromStage, "to", toStage)

	-- Reset to last valid stage
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Stage") then
		leaderstats.Stage.Value = fromStage
	end

	self:ResetToCheckpoint(player)
end

function AntiCheat:ResetToCheckpoint(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local currentStage = leaderstats:FindFirstChild("Stage")
	if not currentStage then return end

	-- Find checkpoint
	local checkpoint = workspace.Tower:FindFirstChild("Checkpoint_" .. currentStage.Value, true)
	if checkpoint then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = checkpoint.CFrame + Vector3.new(0, 5, 0)
		end
	end
end

function AntiCheat:Stop()
	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
	end
	self.playerData = {}
end

return AntiCheat
```

## Day 5: StreamingEnabled Setup

### Enable Streaming in Workspace
```lua
-- Add to src/ServerScriptService/init.server.lua
workspace.StreamingEnabled = true
workspace.StreamingMinRadius = 128
workspace.StreamingTargetRadius = 256
workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.Default
```

### Mobile Optimization Client Script

**src/StarterPlayer/StarterPlayerScripts/MobileOptimizer.client.lua**
```lua
--[[
	MobileOptimizer.client.lua
	Detects mobile and applies performance optimizations
]]

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)

-- Detect mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
	print("[MobileOptimizer] Mobile device detected - applying optimizations")

	-- Reduce shadow quality
	if not GameConfig.MobileShadowsEnabled then
		Lighting.GlobalShadows = false
	end

	-- Reduce streaming radius
	if workspace.StreamingEnabled then
		workspace.StreamingTargetRadius = 192 -- Reduced from 256
	end

	-- Watch for new stages and optimize
	workspace.Tower.ChildAdded:Connect(function(stage)
		if not stage:IsA("Model") then return end

		task.wait(0.1) -- Let stage finish loading

		for _, descendant in ipairs(stage:GetDescendants()) do
			if descendant:IsA("BasePart") then
				-- Disable shadows
				descendant.CastShadow = false

				-- Simplify materials
				if descendant.Material == Enum.Material.Neon or descendant.Material == Enum.Material.Glass then
					descendant.Material = Enum.Material.SmoothPlastic
				end
			end
		end
	end)
end
```

## Deliverables Checklist

- [ ] Rojo project initialized with correct structure
- [ ] Wally dependencies installed (ProfileService, TestEZ)
- [ ] Selene and StyLua configured
- [ ] DevForum Generator script ported and hardened
- [ ] GameConfig and SectionConfig created
- [ ] MemoryManager implemented and tested
- [ ] AntiCheat system implemented with validation loop
- [ ] StreamingEnabled configured
- [ ] Mobile optimization script created
- [ ] GitHub repository created with .gitignore
- [ ] Initial commit with complete project structure

## Testing Checklist

- [ ] Rojo sync works in Studio
- [ ] Generator creates single stage at origin
- [ ] Memory manager runs without errors
- [ ] Anti-cheat detects teleportation (test with command)
- [ ] Mobile script detects device correctly
- [ ] Streaming loads/unloads stages properly

## Next Week Preview

Week 2 will focus on:
- ProfileService integration for player data
- Checkpoint system with persistence
- Basic UI for stage counter
- First 3 section models (Easy difficulty)
- CollectionService setup for lava/hazards
