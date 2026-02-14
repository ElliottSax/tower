# Weeks 2-5: Core Loop & Data Persistence

## Week 2: Player Data & Checkpoint System

### Day 1-2: ProfileService Integration

**src/ServerScriptService/Services/DataService.lua**
```lua
--[[
	DataService.lua
	Handles all player data persistence using ProfileService
	Prevents data loss with session locking
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ReplicatedStorage.Shared.Packages.ProfileService)

local DataService = {}
DataService.Profiles = {}

-- Data template
local PLAYER_DATA_TEMPLATE = {
	Stage = 1,
	CompletedRounds = 0,
	TotalWins = 0,
	BestTime = math.huge,
	CompletedSeeds = {}, -- Track which seeds player has beaten
	Stats = {
		TotalJumps = 0,
		TotalDeaths = 0,
		TotalPlayTime = 0,
	},
	Settings = {
		MusicEnabled = true,
		SFXEnabled = true,
	},
	Purchases = {
		VIPPass = false,
		DoubleCoins = false,
	},
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData_v1", -- Version number for easy data wipes during development
	PLAYER_DATA_TEMPLATE
)

function DataService:Start()
	-- Handle players joining
	Players.PlayerAdded:Connect(function(player)
		self:LoadProfile(player)
	end)

	-- Handle players leaving
	Players.PlayerRemoving:Connect(function(player)
		self:UnloadProfile(player)
	end)

	-- Load existing players (if hot-reloading)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:LoadProfile(player)
		end)
	end
end

function DataService:LoadProfile(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if not profile then
		-- Profile failed to load (rare - usually session lock issue)
		player:Kick("Data failed to load. Please rejoin.")
		return
	end

	-- Handle session lock
	profile:AddUserId(player.UserId)
	profile:Reconcile() -- Fill in missing keys from template

	profile:ListenToRelease(function()
		self.Profiles[player] = nil
		player:Kick("Data session ended. Please rejoin.")
	end)

	-- Check if player left during load
	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	-- Store profile
	self.Profiles[player] = profile

	-- Setup leaderstats
	self:SetupLeaderstats(player, profile.Data)

	-- Spawn at checkpoint
	self:SpawnAtCheckpoint(player, profile.Data.Stage)

	print("[DataService] Loaded profile for", player.Name, "- Stage", profile.Data.Stage)
end

function DataService:UnloadProfile(player: Player)
	local profile = self.Profiles[player]
	if profile then
		profile:Release()
		self.Profiles[player] = nil
		print("[DataService] Unloaded profile for", player.Name)
	end
end

function DataService:SetupLeaderstats(player: Player, data: table)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = data.Stage
	stageValue.Parent = leaderstats

	local winsValue = Instance.new("IntValue")
	winsValue.Name = "Wins"
	winsValue.Value = data.TotalWins
	winsValue.Parent = leaderstats

	-- Listen for stage changes to save
	stageValue.Changed:Connect(function(newStage)
		self:UpdateStage(player, newStage)
	end)
end

function DataService:UpdateStage(player: Player, newStage: number)
	local profile = self.Profiles[player]
	if not profile then return end

	-- Only save if moving forward
	if newStage > profile.Data.Stage then
		profile.Data.Stage = newStage
		print("[DataService]", player.Name, "reached stage", newStage)
	end
end

function DataService:SpawnAtCheckpoint(player: Player, stageNumber: number)
	player.CharacterAdded:Connect(function(character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoidRootPart then return end

		-- Find checkpoint for player's stage
		local checkpoint = workspace.Tower:FindFirstChild("Checkpoint_" .. stageNumber, true)
		if checkpoint then
			humanoidRootPart.CFrame = checkpoint.CFrame + Vector3.new(0, 5, 0)
		else
			-- Fallback to spawn
			humanoidRootPart.CFrame = CFrame.new(0, 20, 0)
		end
	end)

	-- Spawn character if not already spawned
	if not player.Character then
		player:LoadCharacter()
	end
end

function DataService:GetData(player: Player): table?
	local profile = self.Profiles[player]
	return profile and profile.Data
end

function DataService:IncrementStat(player: Player, statName: string, amount: number?)
	local profile = self.Profiles[player]
	if not profile then return end

	local increment = amount or 1
	if profile.Data.Stats[statName] then
		profile.Data.Stats[statName] += increment
	end
end

function DataService:CompleteRound(player: Player, seed: number, time: number)
	local profile = self.Profiles[player]
	if not profile then return end

	profile.Data.CompletedRounds += 1
	profile.Data.TotalWins += 1

	-- Track seed completion
	if not table.find(profile.Data.CompletedSeeds, seed) then
		table.insert(profile.Data.CompletedSeeds, seed)
	end

	-- Update best time
	if time < profile.Data.BestTime then
		profile.Data.BestTime = time
	end

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Wins") then
		leaderstats.Wins.Value = profile.Data.TotalWins
	end
end

return DataService
```

### Day 3: Checkpoint & Respawn System

**src/ServerScriptService/Services/CheckpointService.lua**
```lua
--[[
	CheckpointService.lua
	Handles checkpoint detection and player respawning
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local DataService = require(script.Parent.DataService)

local CheckpointService = {}
CheckpointService.activeConnections = {} -- Track connections per player for cleanup

function CheckpointService:Start()
	-- Setup existing checkpoints
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		self:SetupCheckpoint(checkpoint)
	end

	-- Setup new checkpoints as they're added
	CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(function(checkpoint)
		self:SetupCheckpoint(checkpoint)
	end)

	-- Handle player death/respawn
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:SetupPlayer(player)
	end
end

function CheckpointService:SetupCheckpoint(checkpoint: BasePart)
	if not checkpoint:IsA("BasePart") then return end

	checkpoint.CanCollide = false
	checkpoint.Transparency = 1

	local connection = checkpoint.Touched:Connect(function(hit)
		self:OnCheckpointTouched(checkpoint, hit)
	end)

	-- Store connection for cleanup
	if not self.activeConnections[checkpoint] then
		self.activeConnections[checkpoint] = {}
	end
	table.insert(self.activeConnections[checkpoint], connection)
end

function CheckpointService:OnCheckpointTouched(checkpoint: BasePart, hit: BasePart)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local stageNumber = checkpoint:GetAttribute("StageNumber")
	if not stageNumber then return end

	-- Update player stage
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Stage") then
		local currentStage = leaderstats.Stage.Value

		-- Only update if this is the next stage
		if stageNumber == currentStage + 1 then
			leaderstats.Stage.Value = stageNumber

			-- Analytics
			local AnalyticsService = require(script.Parent.AnalyticsService)
			AnalyticsService:LogStageComplete(player, stageNumber)

			-- Visual feedback
			self:PlayCheckpointEffect(checkpoint, player)
		end
	end
end

function CheckpointService:PlayCheckpointEffect(checkpoint: BasePart, player: Player)
	-- Create temporary visual effect
	local effect = Instance.new("Part")
	effect.Anchored = true
	effect.CanCollide = false
	effect.Size = Vector3.new(8, 1, 8)
	effect.Transparency = 0.5
	effect.Color = Color3.fromRGB(85, 255, 127)
	effect.Material = Enum.Material.Neon
	effect.CFrame = checkpoint.CFrame
	effect.Parent = workspace.Effects

	-- Animate
	local tween = game:GetService("TweenService"):Create(
		effect,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(12, 0.1, 12), Transparency = 1 }
	)
	tween:Play()

	task.delay(0.5, function()
		effect:Destroy()
	end)

	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://5678995321" -- Checkpoint sound
	sound.Volume = 0.5
	sound.Parent = checkpoint
	sound:Play()

	game:GetService("Debris"):AddItem(sound, 2)
end

function CheckpointService:SetupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end

		-- Track deaths
		humanoid.Died:Connect(function()
			DataService:IncrementStat(player, "TotalDeaths", 1)

			-- Respawn at checkpoint after delay
			task.wait(2)
			if player:IsDescendantOf(Players) then
				local leaderstats = player:FindFirstChild("leaderstats")
				local stage = leaderstats and leaderstats:FindFirstChild("Stage")

				if stage then
					DataService:SpawnAtCheckpoint(player, stage.Value)
				end
			end
		end)
	end)
end

function CheckpointService:CleanupCheckpoint(checkpoint: BasePart)
	local connections = self.activeConnections[checkpoint]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		self.activeConnections[checkpoint] = nil
	end
end

return CheckpointService
```

### Day 4-5: Lava/Hazard System with CollectionService

**src/ServerScriptService/Services/HazardService.lua**
```lua
--[[
	HazardService.lua
	Handles all hazards (lava, spikes, etc.) using CollectionService
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local HazardService = {}
HazardService.activeConnections = {}

function HazardService:Start()
	-- Setup existing hazards
	for _, hazard in ipairs(CollectionService:GetTagged("Lava")) do
		self:SetupLava(hazard)
	end

	for _, hazard in ipairs(CollectionService:GetTagged("InstantKill")) do
		self:SetupInstantKill(hazard)
	end

	-- Setup new hazards as they're added
	CollectionService:GetInstanceAddedSignal("Lava"):Connect(function(hazard)
		self:SetupLava(hazard)
	end)

	CollectionService:GetInstanceAddedSignal("InstantKill"):Connect(function(hazard)
		self:SetupInstantKill(hazard)
	end)

	-- Cleanup removed hazards
	CollectionService:GetInstanceRemovedSignal("Lava"):Connect(function(hazard)
		self:CleanupHazard(hazard)
	end)

	CollectionService:GetInstanceRemovedSignal("InstantKill"):Connect(function(hazard)
		self:CleanupHazard(hazard)
	end)
end

function HazardService:SetupLava(lava: BasePart)
	if not lava:IsA("BasePart") then return end

	lava.CanCollide = false

	local connection = lava.Touched:Connect(function(hit)
		self:OnLavaTouched(lava, hit)
	end)

	-- Store connection
	if not self.activeConnections[lava] then
		self.activeConnections[lava] = {}
	end
	table.insert(self.activeConnections[lava], connection)
end

function HazardService:SetupInstantKill(hazard: BasePart)
	if not hazard:IsA("BasePart") then return end

	hazard.CanCollide = false

	local connection = hazard.Touched:Connect(function(hit)
		self:OnInstantKillTouched(hazard, hit)
	end)

	if not self.activeConnections[hazard] then
		self.activeConnections[hazard] = {}
	end
	table.insert(self.activeConnections[hazard], connection)
end

function HazardService:OnLavaTouched(lava: BasePart, hit: BasePart)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Apply damage over time (allows player to escape)
	humanoid:TakeDamage(25)

	-- Play effect
	self:PlayLavaEffect(hit)
end

function HazardService:OnInstantKillTouched(hazard: BasePart, hit: BasePart)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Instant death
	humanoid.Health = 0
end

function HazardService:PlayLavaEffect(part: BasePart)
	-- Create fire effect
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 10
	fire.Parent = part

	Debris:AddItem(fire, 2)

	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://5788415801" -- Lava sizzle
	sound.Volume = 0.3
	sound.Parent = part
	sound:Play()

	Debris:AddItem(sound, 2)
end

function HazardService:CleanupHazard(hazard: Instance)
	local connections = self.activeConnections[hazard]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		self.activeConnections[hazard] = nil
	end
end

return HazardService
```

---

## Week 3: Round System & Analytics

### Day 1-2: Round Management

**src/ServerScriptService/Services/RoundService.lua**
```lua
--[[
	RoundService.lua
	Manages 8-minute rounds with intermission
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Generator = require(script.Parent.ObbyService.Generator)
local MemoryManager = require(script.Parent.ObbyService.MemoryManager)
local DataService = require(script.Parent.DataService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local RoundService = {}
RoundService.currentRound = nil
RoundService.roundActive = false
RoundService.roundStartTime = 0

function RoundService:Start()
	-- Wait for other services to initialize
	task.wait(2)

	-- Start round loop
	while true do
		self:RunIntermission()
		self:RunRound()
	end
end

function RoundService:RunIntermission()
	print("[RoundService] Intermission started")
	self.roundActive = false

	-- Cleanup previous round
	if self.currentRound then
		self.currentRound.generator:Reset()
		self.currentRound.memoryManager:Stop()
		self.currentRound = nil
	end

	-- Reset all players
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Stage") then
			leaderstats.Stage.Value = 1
		end
	end

	-- Countdown
	for i = GameConfig.IntermissionDuration, 1, -1 do
		-- Update UI (send to all clients via ReplicatedStorage value)
		local statusValue = ReplicatedStorage:FindFirstChild("GameStatus") or Instance.new("StringValue")
		statusValue.Name = "GameStatus"
		statusValue.Value = "Intermission: " .. i .. "s"
		statusValue.Parent = ReplicatedStorage

		task.wait(1)
	end
end

function RoundService:RunRound()
	print("[RoundService] Round started")
	self.roundActive = true
	self.roundStartTime = tick()

	-- Generate new seed for this round
	local seed = os.time()
	print("[RoundService] Seed:", seed)

	-- Create generator
	local generator = Generator.new(seed)
	local memoryManager = MemoryManager.new(generator)

	self.currentRound = {
		generator = generator,
		memoryManager = memoryManager,
		seed = seed,
		startTime = self.roundStartTime,
	}

	-- Generate all stages
	local towerFolder = workspace:FindFirstChild("Tower") or Instance.new("Folder")
	towerFolder.Name = "Tower"
	towerFolder.Parent = workspace

	for i = 1, GameConfig.TotalStages do
		local difficulty = self:GetDifficultyForStage(i)
		local isFinish = i == GameConfig.TotalStages

		generator:CreateStage(difficulty, i, isFinish)
	end

	-- Start memory management
	memoryManager:Start()

	-- Round timer
	for i = GameConfig.RoundDuration, 0, -1 do
		if not self.roundActive then break end

		local statusValue = ReplicatedStorage:FindFirstChild("GameStatus")
		if statusValue then
			local minutes = math.floor(i / 60)
			local seconds = i % 60
			statusValue.Value = string.format("Time: %02d:%02d", minutes, seconds)
		end

		task.wait(1)
	end

	-- Round ended
	self:EndRound()
end

function RoundService:GetDifficultyForStage(stageNumber: number): string
	for _, breakpoint in ipairs(GameConfig.DifficultyBreakpoints) do
		if stageNumber <= breakpoint.maxStage then
			return breakpoint.difficulty
		end
	end
	return "Hard"
end

function RoundService:EndRound()
	print("[RoundService] Round ended")
	self.roundActive = false

	-- Find winners (players who reached final stage)
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Stage") then
			if leaderstats.Stage.Value >= GameConfig.TotalStages then
				local completionTime = tick() - self.roundStartTime
				DataService:CompleteRound(player, self.currentRound.seed, completionTime)
				AnalyticsService:LogRoundWin(player, completionTime, self.currentRound.seed)

				-- Victory message
				print("[RoundService]", player.Name, "won in", math.floor(completionTime), "seconds!")
			end
		end
	end
end

return RoundService
```

### Day 3-5: Analytics Implementation

**src/ServerScriptService/Services/AnalyticsService.lua**
```lua
--[[
	AnalyticsService.lua
	Batched analytics to avoid rate limits
]]

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Analytics = {}
Analytics.eventQueue = {}
Analytics.batchInterval = 30 -- seconds

function Analytics:Start()
	-- Batch flush loop
	task.spawn(function()
		while true do
			task.wait(self.batchInterval)
			self:FlushQueue()
		end
	end)
end

function Analytics:LogStageComplete(player: Player, stageNumber: number)
	-- Queue event instead of logging immediately
	table.insert(self.eventQueue, {
		type = "StageComplete",
		player = player,
		stageNumber = stageNumber,
		timestamp = tick(),
	})
end

function Analytics:LogStageFail(player: Player, stageNumber: number, reason: string)
	table.insert(self.eventQueue, {
		type = "StageFail",
		player = player,
		stageNumber = stageNumber,
		reason = reason,
		timestamp = tick(),
	})
end

function Analytics:LogRoundWin(player: Player, completionTime: number, seed: number)
	-- Log immediately (important event)
	local success, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, "RoundWin", math.floor(completionTime), {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Seed-" .. seed,
		})
	end)

	if not success then
		warn("[Analytics] Failed to log round win:", err)
	end
end

function Analytics:FlushQueue()
	if #self.eventQueue == 0 then return end

	-- Aggregate by stage
	local stageCounts = {} -- { [stageNum] = { completions = N, fails = N } }

	for _, event in ipairs(self.eventQueue) do
		if not stageCounts[event.stageNumber] then
			stageCounts[event.stageNumber] = { completions = 0, fails = 0 }
		end

		if event.type == "StageComplete" then
			stageCounts[event.stageNumber].completions += 1
		elseif event.type == "StageFail" then
			stageCounts[event.stageNumber].fails += 1
		end
	end

	-- Log aggregated events
	for stageNum, counts in pairs(stageCounts) do
		if counts.completions > 0 then
			pcall(function()
				AnalyticsService:LogCustomEvent(Players:GetPlayers()[1], "StageCompleteBatch", counts.completions, {
					[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Stage-" .. stageNum,
				})
			end)
		end

		if counts.fails > 0 then
			pcall(function()
				AnalyticsService:LogCustomEvent(Players:GetPlayers()[1], "StageFailBatch", counts.fails, {
					[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "Stage-" .. stageNum,
				})
			end)
		end
	end

	-- Clear queue
	self.eventQueue = {}
	print("[Analytics] Flushed", #stageCounts, "stage metrics")
end

return Analytics
```

---

## Week 4: Testing Infrastructure

### TestEZ Setup

**src/ServerScriptService/Services/ObbyService/Generator.spec.lua**
```lua
return function()
	local Generator = require(script.Parent.Generator)

	describe("Generator.new", function()
		it("should create with default seed", function()
			local gen = Generator.new()
			expect(gen).to.be.ok()
			expect(gen.seed).to.be.ok()
		end)

		it("should create with custom seed", function()
			local gen = Generator.new(12345)
			expect(gen.seed).to.equal(12345)
		end)
	end)

	describe("Deterministic generation", function()
		it("should generate identical stages with same seed", function()
			local gen1 = Generator.new(99999)
			local gen2 = Generator.new(99999)

			local stage1 = gen1:CreateStage("Easy", 1, false)
			local stage2 = gen2:CreateStage("Easy", 1, false)

			expect(stage1.Name).to.equal(stage2.Name)
			expect(stage1.PrimaryPart.CFrame).to.equal(stage2.PrimaryPart.CFrame)

			-- Cleanup
			stage1:Destroy()
			stage2:Destroy()
			gen1:Reset()
			gen2:Reset()
		end)
	end)

	describe("Stage validation", function()
		it("should have required components", function()
			local gen = Generator.new(12345)
			local stage = gen:CreateStage("Easy", 1, false)

			expect(stage).to.be.ok()
			expect(stage:FindFirstChild("Next")).to.be.ok()
			expect(stage:FindFirstChild("Checkpoint")).to.be.ok()
			expect(stage.PrimaryPart).to.be.ok()

			stage:Destroy()
			gen:Reset()
		end)
	end)
end
```

---

## Week 5: First 3 Section Models

### Section Model Template Structure

Create in Roblox Studio:

```
StarterSection (Model)
├── PrimaryPart (Part) [Set as PrimaryPart]
│   ├── Position: 0, 0, 0
│   ├── Size: 8, 1, 8
│   └── Anchored: true
├── Next (Part)
│   ├── Position: 0, 0, 40 (end of section)
│   ├── Size: 0.5, 0.5, 0.5
│   ├── Transparency: 1
│   └── Anchored: true
├── Checkpoint (Part)
│   ├── Position: 0, 3, 2
│   ├── Size: 8, 6, 1
│   ├── Transparency: 0.8
│   ├── Color: Green
│   ├── CanCollide: false
│   └── Anchored: true
├── Colored/
│   ├── One/ (Folder)
│   │   └── [Parts to be colored with primary theme]
│   └── Two/ (Folder)
│       └── [Parts to be colored with secondary theme]
└── [Obstacle geometry]
```

### Three Starter Sections

**1. JumpGap (Easy)**
- 3 platforms with 8-stud gaps
- Total length: 40 studs
- Difficulty: 1/10

**2. ZigZag (Easy)**
- Alternating platform positions
- 6 platforms, 6-stud gaps
- Total length: 40 studs
- Difficulty: 2/10

**3. Balance (Medium)**
- Narrow 2-stud wide path
- 30 studs long
- Total length: 40 studs
- Difficulty: 4/10

### Section Validation Script

```lua
-- Place in ServerScriptService, run once to validate sections
local ServerStorage = game:GetService("ServerStorage")

local function validateSection(section: Model)
	local errors = {}

	-- Check PrimaryPart
	if not section.PrimaryPart then
		table.insert(errors, "Missing PrimaryPart")
	end

	-- Check Next point
	if not section:FindFirstChild("Next") then
		table.insert(errors, "Missing Next connection point")
	end

	-- Check Checkpoint
	if not section:FindFirstChild("Checkpoint") then
		table.insert(errors, "Missing Checkpoint")
	end

	-- Check structure
	if not section:FindFirstChild("Colored") then
		table.insert(errors, "Missing Colored folder")
	end

	-- Check size
	local _, size = section:GetBoundingBox()
	if size.X > 60 or size.Z > 60 then
		table.insert(errors, "Section too large (max 60x60 studs)")
	end

	return errors
end

-- Validate all sections
for _, difficulty in ipairs(ServerStorage.Sections:GetChildren()) do
	for _, section in ipairs(difficulty:GetChildren()) do
		local errors = validateSection(section)
		if #errors > 0 then
			warn("Section", section.Name, "has errors:")
			for _, err in ipairs(errors) do
				warn("  -", err)
			end
		else
			print("✓ Section", section.Name, "is valid")
		end
	end
end
```

## Deliverables: Weeks 2-5

**Week 2:**
- [ ] ProfileService integrated
- [ ] DataService with session locking
- [ ] Checkpoint system functional
- [ ] Lava/hazards using CollectionService
- [ ] Player spawn at last checkpoint

**Week 3:**
- [ ] RoundService with 8-minute timer
- [ ] Seed-based generation per round
- [ ] Intermission system
- [ ] Batched analytics to avoid rate limits
- [ ] Winner detection and logging

**Week 4:**
- [ ] TestEZ suite with 10+ tests
- [ ] Generator determinism tests
- [ ] Section validation tests
- [ ] CI pipeline runs tests automatically

**Week 5:**
- [ ] 3 section models completed
- [ ] Sections added to ServerStorage
- [ ] SectionConfig populated
- [ ] Manual playtesting of all 3 sections
- [ ] Difficulty balanced (completion rate >80% for Easy)

## Next Phase Preview

Weeks 6-10 will cover:
- Mobile optimization testing
- 10 additional sections (total 13)
- Monetization (skip stage button)
- 50+ playtest responses
- Performance profiling
