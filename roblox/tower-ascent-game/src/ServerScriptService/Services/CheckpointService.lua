--[[
	CheckpointService.lua
	Manages player progression through tower sections

	Features:
	- Detects checkpoint touches
	- Saves current section per player
	- Respawns at last checkpoint on death
	- Detects finish line completion
	- Awards coins for progression
	- Integrates with RoundService, DataService, CoinService
	- Uses CollectionService tags

	How it works:
	1. Each section has a checkpoint (tagged "Checkpoint")
	2. Player touches checkpoint → save section number
	3. Player dies → respawn at last checkpoint position
	4. Finish line (tagged "FinishLine") → award coins, notify RoundService

	Week 2: Full implementation
	Week 3: Add checkpoint VFX, sound effects
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Safe require ServiceLocator
local ServiceLocator = nil
pcall(function()
	ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
end)

-- Cached optional services (loaded once at init, not on every checkpoint touch)
local ParticleService = nil
local SoundService = nil
local ThemeService = nil
local OptionalServicesLoaded = false

local function loadOptionalServices()
	if OptionalServicesLoaded then return end
	OptionalServicesLoaded = true

	-- Load optional services with pcall (they may not exist)
	pcall(function()
		ParticleService = require(ServerScriptService.Services.ParticleService)
	end)
	pcall(function()
		SoundService = require(ServerScriptService.Services.SoundService)
	end)
	pcall(function()
		ThemeService = require(ServerScriptService.Services.ThemeService)
	end)
end

local CheckpointService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	CheckpointDebounceTime = 1, -- Seconds before checkpoint can be triggered again
	RespawnDelay = 0.1, -- Delay before respawning at checkpoint
	CheckpointSpawnHeight = 3, -- Studs above checkpoint to spawn player
	RecentRespawnWindow = 2, -- Seconds to track recent respawns (anti-cheat)
}

-- ============================================================================
-- STATE
-- ============================================================================

-- Player checkpoint data
-- Format: [UserId] = { section = number, position = Vector3, timestamp = number }
CheckpointService.PlayerCheckpoints = {}

-- Debounce tracking (prevents spam-touching same checkpoint)
-- Format: [UserId_SectionNumber] = { timestamp = tick() }
-- Uses expiring cache pattern to prevent unbounded growth
CheckpointService.CheckpointDebounce = {}

-- Recent respawns (for anti-cheat teleport detection)
-- Format: [UserId] = tick()
CheckpointService.RecentRespawns = {}

-- Connections
CheckpointService.CheckpointConnections = {}
CheckpointService.FinishLineConnections = {}
CheckpointService.CharacterConnections = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CheckpointService.Init()
	print("[CheckpointService] Initializing...")

	-- Load optional services once at init (not on every checkpoint touch)
	loadOptionalServices()

	-- Setup player management
	Players.PlayerAdded:Connect(function(player)
		CheckpointService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CheckpointService.OnPlayerRemoving(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		CheckpointService.OnPlayerAdded(player)
	end

	-- Setup checkpoint detection
	CheckpointService.SetupCheckpointDetection()
	CheckpointService.SetupFinishLineDetection()

	-- Start debounce cleanup loop to prevent memory leaks
	CheckpointService.StartDebounceCleanupLoop()

	print("[CheckpointService] Initialized")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function CheckpointService.OnPlayerAdded(player: Player)
	-- Initialize checkpoint data
	CheckpointService.PlayerCheckpoints[player.UserId] = {
		section = 0,
		position = Vector3.new(0, GameConfig.Tower.StartHeight + 5, 0),
		timestamp = tick(),
	}

	-- Setup character respawn handling
	player.CharacterAdded:Connect(function(character)
		CheckpointService.OnCharacterAdded(player, character)
	end)

	if player.Character then
		CheckpointService.OnCharacterAdded(player, player.Character)
	end

	print(string.format("[CheckpointService] Initialized player: %s", player.Name))
end

function CheckpointService.OnPlayerRemoving(player: Player)
	-- Cleanup
	CheckpointService.PlayerCheckpoints[player.UserId] = nil

	-- Clean up debounce entries for this player
	local userIdPrefix = tostring(player.UserId) .. "_"
	local prefixLen = #userIdPrefix
	for key, _ in pairs(CheckpointService.CheckpointDebounce) do
		if string.sub(key, 1, prefixLen) == userIdPrefix then
			CheckpointService.CheckpointDebounce[key] = nil
		end
	end

	-- Disconnect character connections
	if CheckpointService.CharacterConnections[player] then
		for _, connection in ipairs(CheckpointService.CharacterConnections[player]) do
			connection:Disconnect()
		end
		CheckpointService.CharacterConnections[player] = nil
	end

	print(string.format("[CheckpointService] Cleaned up player: %s", player.Name))
end

function CheckpointService.OnCharacterAdded(player: Player, character: Model)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)

	if not humanoid or not rootPart then
		return
	end

	-- Track respawn time (for anti-cheat teleport detection)
	CheckpointService.RecentRespawns[player.UserId] = tick()
	task.delay(CONFIG.RecentRespawnWindow, function()
		CheckpointService.RecentRespawns[player.UserId] = nil
	end)

	-- Get checkpoint data
	local checkpointData = CheckpointService.PlayerCheckpoints[player.UserId]

	if checkpointData and checkpointData.section > 0 then
		-- Respawn at last checkpoint
		task.wait(CONFIG.RespawnDelay) -- Small delay to prevent conflicts
		rootPart.CFrame = CFrame.new(checkpointData.position)

		print(string.format(
			"[CheckpointService] Respawned %s at section %d",
			player.Name,
			checkpointData.section
		))
	else
		-- First spawn or no checkpoint yet
		rootPart.CFrame = CFrame.new(Vector3.new(0, GameConfig.Tower.StartHeight + 5, 0))
	end

	-- Listen for death
	if not CheckpointService.CharacterConnections[player] then
		CheckpointService.CharacterConnections[player] = {}
	end

	local diedConnection = humanoid.Died:Connect(function()
		CheckpointService.OnPlayerDied(player)
	end)

	table.insert(CheckpointService.CharacterConnections[player], diedConnection)
end

function CheckpointService.OnPlayerDied(player: Player)
	print(string.format("[CheckpointService] %s died", player.Name))

	-- Update stats
	local DataService = require(script.Parent.DataService)
	DataService.IncrementDeaths(player)

	-- Character will respawn automatically, OnCharacterAdded handles checkpoint respawn
end

-- ============================================================================
-- CHECKPOINT DETECTION
-- ============================================================================

function CheckpointService.SetupCheckpointDetection()
	-- Listen for existing checkpoints
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		CheckpointService.ConnectCheckpoint(checkpoint)
	end

	-- Listen for new checkpoints (when tower regenerates)
	CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(function(checkpoint)
		CheckpointService.ConnectCheckpoint(checkpoint)
	end)

	-- Cleanup removed checkpoints
	CollectionService:GetInstanceRemovedSignal("Checkpoint"):Connect(function(checkpoint)
		if CheckpointService.CheckpointConnections[checkpoint] then
			CheckpointService.CheckpointConnections[checkpoint]:Disconnect()
			CheckpointService.CheckpointConnections[checkpoint] = nil
		end
	end)

	print("[CheckpointService] Checkpoint detection setup complete")
end

function CheckpointService.ConnectCheckpoint(checkpoint: BasePart)
	if CheckpointService.CheckpointConnections[checkpoint] then
		return -- Already connected
	end

	local connection = checkpoint.Touched:Connect(function(hit)
		CheckpointService.OnCheckpointTouched(checkpoint, hit)
	end)

	CheckpointService.CheckpointConnections[checkpoint] = connection
end

function CheckpointService.OnCheckpointTouched(checkpoint: BasePart, hit: BasePart)
	-- Verify it's a player character
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Get section number from checkpoint
	local section = checkpoint.Parent:GetAttribute("SectionNumber")
	if not section then
		warn("[CheckpointService] Checkpoint missing SectionNumber attribute!")
		return
	end

	-- DEBOUNCE CHECK: Prevent rapid re-triggering of same checkpoint
	-- Uses expiring cache pattern - checks timestamp instead of just existence
	local debounceKey = player.UserId .. "_" .. section
	local debounceEntry = CheckpointService.CheckpointDebounce[debounceKey]
	if debounceEntry then
		if (tick() - debounceEntry.timestamp) < CONFIG.CheckpointDebounceTime then
			return -- Still in debounce period
		else
			-- Entry expired, clean it up
			CheckpointService.CheckpointDebounce[debounceKey] = nil
		end
	end

	-- Check if this is a new checkpoint (prevent backwards progress)
	local checkpointData = CheckpointService.PlayerCheckpoints[player.UserId]
	if not checkpointData then return end

	if section <= checkpointData.section then
		return -- Not a new checkpoint
	end

	-- Set debounce IMMEDIATELY with timestamp
	-- Uses expiring cache pattern - no task.delay needed (checked on access)
	CheckpointService.CheckpointDebounce[debounceKey] = { timestamp = tick() }

	-- ANTI-CHEAT VALIDATION (BEFORE mutation!)
	-- Validate stage progression to prevent teleport exploits
	local AntiCheat = ServiceLocator and ServiceLocator.Get("AntiCheat")
	if AntiCheat and AntiCheat.CheckStageProgression then
		local isValid = AntiCheat:CheckStageProgression(player, checkpointData.section, section)

		if not isValid then
			-- Stage skip detected - block progression
			warn(string.format(
				"[CheckpointService] BLOCKED stage skip: %s attempted %d → %d (Max skip: %d)",
				player.Name,
				checkpointData.section,
				section,
				GameConfig.AntiCheat.MaxStageSkip
			))

			-- Visual feedback (flash red)
			task.spawn(function()
				if not checkpoint or not checkpoint.Parent then return end

				local originalColor = checkpoint.Color
				for i = 1, 3 do
					if not checkpoint or not checkpoint.Parent then break end
					checkpoint.Color = Color3.fromRGB(255, 0, 0)
					task.wait(0.1)

					if not checkpoint or not checkpoint.Parent then break end
					checkpoint.Color = originalColor
					task.wait(0.1)
				end
			end)

			return -- Stop here - don't save checkpoint or award coins
		end
	end

	-- Update checkpoint data (only if validation passed)
	checkpointData.section = section
	checkpointData.position = checkpoint.Position + Vector3.new(0, CONFIG.CheckpointSpawnHeight, 0) -- Spawn slightly above
	checkpointData.timestamp = tick()

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stage = leaderstats:FindFirstChild("Stage")
		if stage then
			stage.Value = section
		end
	end

	-- Update DataService (highest stage all-time)
	local DataService = require(script.Parent.DataService)
	DataService.UpdateHighestStage(player, section)

	-- Award coins for progression
	local CoinService = require(script.Parent.CoinService)
	local coinsAwarded = GameConfig.Progression.CoinsPerSection
	CoinService.AddCoins(player, coinsAwarded, "Checkpoint")

	-- WEEK 13: Battle Pass XP for section reached
	local success, BattlePassService = pcall(function()
		return require(script.Parent.Monetization.BattlePassService)
	end)
	if success and BattlePassService and BattlePassService.OnSectionReached then
		BattlePassService.OnSectionReached(player, section)
		BattlePassService.OnCoinsCollected(player, coinsAwarded)
	end

	-- Visual & audio feedback (Week 4) - Uses cached optional services
	if ParticleService and ParticleService.SpawnParticle then
		ParticleService.SpawnParticle("CheckpointReached", checkpoint.Position, player)
	end

	if SoundService and SoundService.PlaySound then
		SoundService.PlaySound("CheckpointReached", checkpoint.Position)
	end

	print(string.format(
		"[CheckpointService] %s reached section %d (+%d coins)",
		player.Name,
		section,
		coinsAwarded
	))

	-- Visual feedback (turn checkpoint yellow briefly)
	task.spawn(function()
		if not checkpoint or not checkpoint.Parent then return end

		local originalColor = checkpoint.Color
		checkpoint.Color = Color3.fromRGB(255, 255, 0)
		task.wait(0.3)

		if not checkpoint or not checkpoint.Parent then return end
		checkpoint.Color = originalColor
	end)

	-- Notify ThemeService of section progression (for theme transitions)
	if ThemeService and ThemeService.OnSectionEntered then
		ThemeService.OnSectionEntered(player, section)
	end
end

-- ============================================================================
-- FINISH LINE DETECTION
-- ============================================================================

function CheckpointService.SetupFinishLineDetection()
	-- Listen for existing finish lines
	for _, finishLine in ipairs(CollectionService:GetTagged("FinishLine")) do
		CheckpointService.ConnectFinishLine(finishLine)
	end

	-- Listen for new finish lines
	CollectionService:GetInstanceAddedSignal("FinishLine"):Connect(function(finishLine)
		CheckpointService.ConnectFinishLine(finishLine)
	end)

	-- Cleanup removed finish lines
	CollectionService:GetInstanceRemovedSignal("FinishLine"):Connect(function(finishLine)
		if CheckpointService.FinishLineConnections[finishLine] then
			CheckpointService.FinishLineConnections[finishLine]:Disconnect()
			CheckpointService.FinishLineConnections[finishLine] = nil
		end
	end)

	print("[CheckpointService] Finish line detection setup complete")
end

function CheckpointService.ConnectFinishLine(finishLine: BasePart)
	if CheckpointService.FinishLineConnections[finishLine] then
		return -- Already connected
	end

	local connection = finishLine.Touched:Connect(function(hit)
		CheckpointService.OnFinishLineTouched(finishLine, hit)
	end)

	CheckpointService.FinishLineConnections[finishLine] = connection
end

function CheckpointService.OnFinishLineTouched(finishLine: BasePart, hit: BasePart)
	-- Verify it's a player character
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check if round is in progress
	local RoundService = require(script.Parent.RoundService)
	if not RoundService.IsRoundInProgress() then
		return -- Can't finish outside of round
	end

	print(string.format("[CheckpointService] %s completed the tower!", player.Name))

	-- Award completion bonus
	local CoinService = require(script.Parent.CoinService)
	local DataService = require(script.Parent.DataService)

	local completionBonus = GameConfig.Progression.CompletionBonus
	CoinService.AddCoins(player, completionBonus)

	-- Update stats
	DataService.IncrementTowersCompleted(player)
	DataService.UpdateHighestStage(player, GameConfig.Tower.SectionsPerTower)

	-- WEEK 13: Battle Pass XP for tower completion
	local success, BattlePassService = pcall(function()
		return require(script.Parent.Monetization.BattlePassService)
	end)
	if success and BattlePassService and BattlePassService.OnTowerCompleted then
		BattlePassService.OnTowerCompleted(player)
		BattlePassService.OnCoinsCollected(player, completionBonus)
	end

	-- Visual & audio feedback (Week 4) - Uses cached optional services
	if ParticleService and ParticleService.SpawnParticle then
		ParticleService.SpawnParticle("TowerCompleted", finishLine.Position)
	end

	if SoundService and SoundService.PlaySound then
		SoundService.PlaySound("TowerCompleted", finishLine.Position)
	end

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stage = leaderstats:FindFirstChild("Stage")
		if stage then
			stage.Value = GameConfig.Tower.SectionsPerTower
		end
	end

	-- Notify RoundService
	RoundService.OnPlayerFinished(player)

	-- Visual celebration
	task.spawn(function()
		finishLine.Color = Color3.fromRGB(255, 215, 0) -- Gold flash
		task.wait(0.5)
		finishLine.Color = Color3.fromRGB(255, 215, 0) -- Stay gold
	end)

	print(string.format(
		"[CheckpointService] Awarded %d completion bonus to %s",
		completionBonus,
		player.Name
	))
end

-- ============================================================================
-- RESET CHECKPOINTS (CALLED BY ROUNDSERVICE)
-- ============================================================================

function CheckpointService.ResetAllCheckpoints()
	-- Reset all players to section 0
	for userId, data in pairs(CheckpointService.PlayerCheckpoints) do
		data.section = 0
		data.position = Vector3.new(0, GameConfig.Tower.StartHeight + 5, 0)
		data.timestamp = tick()
	end

	-- Clear all debounce entries (new round = fresh start)
	CheckpointService.CheckpointDebounce = {}

	print("[CheckpointService] Reset all player checkpoints and cleared debounces")
end

-- ============================================================================
-- DEBOUNCE CLEANUP
-- ============================================================================

function CheckpointService.CleanupExpiredDebounces()
	-- Remove expired debounce entries to prevent unbounded table growth
	local now = tick()
	local cleanedCount = 0

	for key, entry in pairs(CheckpointService.CheckpointDebounce) do
		if (now - entry.timestamp) >= CONFIG.CheckpointDebounceTime then
			CheckpointService.CheckpointDebounce[key] = nil
			cleanedCount = cleanedCount + 1
		end
	end

	if cleanedCount > 0 then
		print(string.format("[CheckpointService] Cleaned up %d expired debounce entries", cleanedCount))
	end
end

function CheckpointService.StartDebounceCleanupLoop()
	task.spawn(function()
		while true do
			task.wait(60) -- Every minute
			CheckpointService.CleanupExpiredDebounces()
		end
	end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function CheckpointService.GetPlayerSection(player: Player): number
	local data = CheckpointService.PlayerCheckpoints[player.UserId]
	return data and data.section or 0
end

function CheckpointService.GetPlayerCheckpointPosition(player: Player): Vector3?
	local data = CheckpointService.PlayerCheckpoints[player.UserId]
	return data and data.position or nil
end

function CheckpointService.SetPlayerCheckpoint(player: Player, section: number, position: Vector3)
	local data = CheckpointService.PlayerCheckpoints[player.UserId]
	if data then
		data.section = section
		data.position = position
		data.timestamp = tick()
	end
end

function CheckpointService.DidRecentlyRespawn(player: Player): boolean
	--[[
		Returns true if player respawned recently.
		Used by AntiCheat to prevent false positives on teleport detection.
	--]]
	local respawnTime = CheckpointService.RecentRespawns[player.UserId]
	if not respawnTime then return false end

	return (tick() - respawnTime) < CONFIG.RecentRespawnWindow
end

function CheckpointService.CleanupTower()
	--[[
		Disconnects all checkpoint and finish line connections.
		Called by RoundService before destroying old tower.
		Prevents memory leaks from dangling connections.
	--]]

	-- Disconnect all checkpoint connections
	for checkpoint, connection in pairs(CheckpointService.CheckpointConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	CheckpointService.CheckpointConnections = {}

	-- Disconnect all finish line connections
	for finishLine, connection in pairs(CheckpointService.FinishLineConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	CheckpointService.FinishLineConnections = {}

	print("[CheckpointService] Cleaned up all checkpoint/finish line connections")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return CheckpointService
