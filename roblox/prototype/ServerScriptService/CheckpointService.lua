--[[
	CheckpointService.lua
	Handles checkpoint progression and respawning

	Features:
	- Saves player's highest section reached (in-memory)
	- Respawns player at last checkpoint on death
	- Detects finish line completion
	- Awards coins on finish
--]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local CheckpointService = {}

-- Store player checkpoint data (resets on server restart)
-- Format: { [UserId] = { section = number, position = Vector3 } }
local playerCheckpoints = {}

-- Get CoinService (will be required after CoinService is created)
local CoinService

-- Initialize checkpoint for new player
local function initializePlayer(player)
	playerCheckpoints[player.UserId] = {
		section = 0,
		position = Vector3.new(0, 10, 0) -- Default spawn
	}
	print(string.format("[CheckpointService] Initialized player: %s", player.Name))
end

-- Handle checkpoint touch
local function onCheckpointTouched(checkpoint, hit)
	-- Verify it's a player character
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Get section number
	local sectionNumber = checkpoint:GetAttribute("SectionNumber")
	if not sectionNumber then
		warn("[CheckpointService] Checkpoint missing SectionNumber attribute!")
		return
	end

	-- Only update if this is a new checkpoint (prevent backwards progress)
	local currentData = playerCheckpoints[player.UserId]
	if not currentData or sectionNumber > currentData.section then
		playerCheckpoints[player.UserId] = {
			section = sectionNumber,
			position = checkpoint.Position + Vector3.new(0, 3, 0) -- Spawn slightly above
		}

		print(string.format(
			"[CheckpointService] %s reached section %d",
			player.Name,
			sectionNumber
		))

		-- Visual feedback
		checkpoint.Color = Color3.fromRGB(255, 255, 0) -- Turn yellow when activated
		task.wait(0.3)
		checkpoint.Color = Color3.fromRGB(0, 255, 0) -- Back to green
	end
end

-- Handle finish line touch
local function onFinishLineTouched(finishLine, hit)
	-- Verify it's a player character
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	print(string.format("[CheckpointService] %s completed the tower!", player.Name))

	-- Award coins (100 coins for completion)
	if CoinService then
		CoinService.AddCoins(player, 100)
		print(string.format("[CheckpointService] Awarded 100 coins to %s", player.Name))
	end

	-- Visual celebration
	finishLine.Color = Color3.fromRGB(255, 215, 0) -- Gold flash
	task.wait(0.5)

	-- Teleport back to start
	local checkpointData = playerCheckpoints[player.UserId]
	if checkpointData then
		checkpointData.section = 0
		checkpointData.position = Vector3.new(0, 10, 0)
	end

	if character.PrimaryPart then
		character.PrimaryPart.CFrame = CFrame.new(0, 10, 0)
		print(string.format("[CheckpointService] Teleported %s to start", player.Name))
	end
end

-- Respawn player at last checkpoint
local function onCharacterAdded(player, character)
	-- Wait for character to fully load
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Get last checkpoint
	local checkpointData = playerCheckpoints[player.UserId]
	if checkpointData and checkpointData.section > 0 then
		-- Respawn at checkpoint
		task.wait(0.1) -- Small delay to prevent spawn conflicts
		rootPart.CFrame = CFrame.new(checkpointData.position)
		print(string.format(
			"[CheckpointService] Respawned %s at section %d",
			player.Name,
			checkpointData.section
		))
	else
		-- First spawn or no checkpoint yet
		rootPart.CFrame = CFrame.new(0, 10, 0)
	end
end

-- Setup checkpoint listeners
local function setupCheckpoints()
	-- Listen for all existing checkpoints
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		checkpoint.Touched:Connect(function(hit)
			onCheckpointTouched(checkpoint, hit)
		end)
	end

	-- Listen for new checkpoints (in case tower regenerates)
	CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(function(checkpoint)
		checkpoint.Touched:Connect(function(hit)
			onCheckpointTouched(checkpoint, hit)
		end)
	end)

	print("[CheckpointService] Checkpoint listeners setup complete")
end

-- Setup finish line listeners
local function setupFinishLine()
	-- Listen for all finish lines
	for _, finishLine in ipairs(CollectionService:GetTagged("FinishLine")) do
		finishLine.Touched:Connect(function(hit)
			onFinishLineTouched(finishLine, hit)
		end)
	end

	-- Listen for new finish lines
	CollectionService:GetInstanceAddedSignal("FinishLine"):Connect(function(finishLine)
		finishLine.Touched:Connect(function(hit)
			onFinishLineTouched(finishLine, hit)
		end)
	end)

	print("[CheckpointService] Finish line listeners setup complete")
end

-- Player management
local function onPlayerAdded(player)
	initializePlayer(player)

	-- Setup character respawn
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Handle current character if already spawned
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	playerCheckpoints[player.UserId] = nil
	print(string.format("[CheckpointService] Cleaned up data for: %s", player.Name))
end

-- Initialize service
function CheckpointService.Init()
	print("[CheckpointService] Initializing...")

	-- Try to get CoinService
	local success, result = pcall(function()
		return require(script.Parent.CoinService)
	end)
	if success then
		CoinService = result
		print("[CheckpointService] CoinService connected")
	else
		warn("[CheckpointService] CoinService not found, coins won't be awarded")
	end

	-- Setup checkpoint and finish line detection
	task.wait(1) -- Wait for tower to generate
	setupCheckpoints()
	setupFinishLine()

	-- Setup player management
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("[CheckpointService] Initialization complete!")
end

-- Get player's current section (for UI display)
function CheckpointService.GetPlayerSection(player)
	local data = playerCheckpoints[player.UserId]
	return data and data.section or 0
end

-- Auto-initialize
CheckpointService.Init()

return CheckpointService
