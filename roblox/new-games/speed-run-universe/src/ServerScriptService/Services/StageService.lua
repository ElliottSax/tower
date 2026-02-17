--[[
	StageService.lua - Speed Run Universe
	Manages checkpoints, stage completion, world progression, and coin collection.
	Handles the physical game world interactions - checkpoints, kill zones, coins.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StageService = {}
StageService.DataService = nil
StageService.SpeedrunService = nil
StageService.SecurityManager = nil
StageService.ChallengeService = nil

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================
-- Player checkpoint tracking: userId -> { WorldId, StageNum, CheckpointCFrame }
local PlayerCheckpoints = {}

-- Collected coins per session: userId -> { ["WorldId_Stage_CoinIndex"] = true }
local CollectedCoins = {}

-- ============================================================================
-- INIT
-- ============================================================================
function StageService.Init()
	StageService.DataService = require(ServerScriptService.Services.DataService)
	StageService.SpeedrunService = require(ServerScriptService.Services.SpeedrunService)
	StageService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Checkpoint touched
	re:WaitForChild("CheckpointReached").OnServerEvent:Connect(function(player, data)
		StageService.OnCheckpointReached(player, data)
	end)

	-- Coin collected
	re:WaitForChild("CoinCollected").OnServerEvent:Connect(function(player, data)
		StageService.OnCoinCollected(player, data)
	end)

	-- Teleport to stage request
	re:WaitForChild("TeleportToStage").OnServerEvent:Connect(function(player, data)
		StageService.TeleportToStage(player, data)
	end)

	-- World unlock request
	re:WaitForChild("UnlockWorld").OnServerEvent:Connect(function(player, data)
		StageService.UnlockWorld(player, data)
	end)

	-- Setup death handler for all players
	Players.PlayerAdded:Connect(function(player)
		CollectedCoins[player.UserId] = {}
		player.CharacterAdded:Connect(function(character)
			StageService._SetupCharacterDeath(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerCheckpoints[player.UserId] = nil
		CollectedCoins[player.UserId] = nil
	end)

	-- Setup physical checkpoint/coin/killzone detection
	task.spawn(function()
		task.wait(2) -- Wait for workspace to load
		StageService._SetupWorldTriggers()
	end)

	print("[StageService] Initialized")
end

-- Deferred init for ChallengeService (may not exist at Init time)
function StageService._EnsureChallengeService()
	if not StageService.ChallengeService then
		local ok, svc = pcall(function()
			return require(ServerScriptService.Services.ChallengeService)
		end)
		if ok then StageService.ChallengeService = svc end
	end
end

-- ============================================================================
-- CHECKPOINT HANDLING
-- ============================================================================
function StageService.OnCheckpointReached(player, data)
	if not StageService.SecurityManager.CheckRateLimit(player, "CheckpointReached") then return end
	if not data or not data.WorldId or not data.StageNum then return end

	local worldId = data.WorldId
	local stageNum = tonumber(data.StageNum)
	if not stageNum then return end

	-- Validate the world exists
	local worldConfig = GameConfig.WorldById[worldId]
	if not worldConfig then return end

	-- Validate stage number
	if stageNum < 1 or stageNum > worldConfig.StageCount then return end

	-- Validate world is unlocked
	if not StageService.DataService.HasUnlockedWorld(player, worldId) then return end

	-- Update checkpoint
	PlayerCheckpoints[player.UserId] = {
		WorldId = worldId,
		StageNum = stageNum,
		CheckpointCFrame = data.CheckpointCFrame, -- CFrame position of checkpoint
	}

	-- If this is a stage-end checkpoint (transition to next stage), trigger completion
	if data.IsStageEnd then
		StageService._CompleteStage(player, worldId, stageNum)
	end

	-- Sync to client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local sync = re:FindFirstChild("StageSync")
		if sync then
			sync:FireClient(player, {
				Action = "CheckpointSet",
				WorldId = worldId,
				StageNum = stageNum,
			})
		end
	end
end

-- ============================================================================
-- STAGE COMPLETION
-- ============================================================================
function StageService._CompleteStage(player, worldId, stageNum)
	local playerData = StageService.DataService.GetFullData(player)
	if not playerData then return end

	local stageKey = worldId .. "_" .. tostring(stageNum)

	-- Mark stage as completed (idempotent)
	local isFirstCompletion = not playerData.CompletedStages[stageKey]
	playerData.CompletedStages[stageKey] = true

	if isFirstCompletion then
		playerData.TotalStagesCompleted = playerData.TotalStagesCompleted + 1

		-- Award stage coins
		local worldConfig = GameConfig.WorldById[worldId]
		if worldConfig then
			StageService.DataService.AddCoins(player, worldConfig.CoinReward)
		end

		-- Update furthest progress
		local worldIndex = worldConfig and worldConfig.Index or 1
		local currentFurthestWorld = GameConfig.WorldById[playerData.FurthestWorld]
		local currentFurthestIndex = currentFurthestWorld and currentFurthestWorld.Index or 1

		if worldIndex > currentFurthestIndex or
			(worldIndex == currentFurthestIndex and stageNum > playerData.FurthestStage) then
			playerData.FurthestWorld = worldId
			playerData.FurthestStage = stageNum
		end

		-- Check ability unlocks
		StageService._CheckAbilityUnlocks(player, worldId, stageNum)
	end

	-- Notify speedrun service
	StageService.SpeedrunService.OnStageComplete(player, worldId, stageNum)

	-- Notify challenge service
	StageService._EnsureChallengeService()
	if StageService.ChallengeService then
		StageService.ChallengeService.OnStageComplete(player, worldId, stageNum)
	end

	-- Fire stage complete event to client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local stageComplete = re:FindFirstChild("StageComplete")
		if stageComplete then
			stageComplete:FireClient(player, {
				WorldId = worldId,
				StageNum = stageNum,
				FirstCompletion = isFirstCompletion,
				TotalCompleted = playerData.TotalStagesCompleted,
			})
		end

		-- Check if world is fully complete
		local worldConfig = GameConfig.WorldById[worldId]
		if worldConfig and stageNum >= worldConfig.StageCount then
			local allComplete = true
			for s = 1, worldConfig.StageCount do
				if not playerData.CompletedStages[worldId .. "_" .. tostring(s)] then
					allComplete = false
					break
				end
			end
			if allComplete then
				local worldComplete = re:FindFirstChild("WorldComplete")
				if worldComplete then
					worldComplete:FireClient(player, {
						WorldId = worldId,
						CompletionReward = worldConfig.CompletionReward,
					})
				end
			end
		end
	end

	-- Update leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local stagesVal = ls:FindFirstChild("Stages")
		if stagesVal then stagesVal.Value = playerData.TotalStagesCompleted end
	end
end

-- ============================================================================
-- ABILITY UNLOCK CHECK
-- ============================================================================
function StageService._CheckAbilityUnlocks(player, worldId, stageNum)
	local playerData = StageService.DataService.GetFullData(player)
	if not playerData then return end

	for _, ability in ipairs(GameConfig.Abilities) do
		-- Check if already unlocked
		local alreadyUnlocked = false
		for _, id in ipairs(playerData.UnlockedAbilities) do
			if id == ability.Id then alreadyUnlocked = true; break end
		end
		if alreadyUnlocked then continue end

		-- Check unlock condition
		if ability.UnlockWorld == worldId and ability.UnlockStage <= stageNum then
			table.insert(playerData.UnlockedAbilities, ability.Id)

			-- Notify client
			local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if re then
				local unlockEvent = re:FindFirstChild("UnlockAbility")
				if unlockEvent then
					unlockEvent:FireClient(player, {
						AbilityId = ability.Id,
						AbilityName = ability.Name,
						Description = ability.Description,
					})
				end
			end

			print("[StageService]", player.Name, "unlocked ability:", ability.Name)
		end
	end
end

-- ============================================================================
-- COIN COLLECTION
-- ============================================================================
function StageService.OnCoinCollected(player, data)
	if not data or not data.WorldId or not data.StageNum or not data.CoinIndex then return end

	-- Security check
	if not StageService.SecurityManager.ValidateCoinCollection(
		player, data.WorldId, data.StageNum, data.CoinIndex
	) then return end

	-- Prevent duplicate collection
	local coinKey = data.WorldId .. "_" .. data.StageNum .. "_" .. data.CoinIndex
	local collected = CollectedCoins[player.UserId]
	if not collected then return end
	if collected[coinKey] then return end
	collected[coinKey] = true

	-- Award coins (1 coin = 1 coin currency by default)
	local coinValue = 1
	local worldConfig = GameConfig.WorldById[data.WorldId]
	if worldConfig then
		coinValue = worldConfig.Difficulty -- Higher worlds = more valuable coins
	end

	StageService.DataService.AddCoins(player, coinValue)

	-- Update speedrun session
	local run = StageService.SpeedrunService.GetActiveRun(player)
	if run then
		run.CoinsCollected = run.CoinsCollected + 1
	end

	-- Track total coins collected stat
	local playerData = StageService.DataService.GetFullData(player)
	if playerData then
		playerData.TotalCoinsCollected = playerData.TotalCoinsCollected + 1
	end

	-- Notify challenge service
	StageService._EnsureChallengeService()
	if StageService.ChallengeService then
		StageService.ChallengeService.OnCoinCollected(player, data.WorldId, coinValue)
	end
end

-- ============================================================================
-- WORLD UNLOCK
-- ============================================================================
function StageService.UnlockWorld(player, data)
	if not StageService.SecurityManager.CheckRateLimit(player, "UnlockWorld") then return end
	if not data or not data.WorldId then return end

	local worldConfig = GameConfig.WorldById[data.WorldId]
	if not worldConfig then return end

	-- Check if already unlocked
	if StageService.DataService.HasUnlockedWorld(player, data.WorldId) then
		StageService._Notify(player, "World already unlocked!")
		return
	end

	-- Check if player can afford it
	if not StageService.DataService.SpendCoins(player, worldConfig.UnlockCost) then
		StageService._Notify(player, "Not enough coins! Need " .. worldConfig.UnlockCost)
		return
	end

	-- Unlock the world
	local playerData = StageService.DataService.GetFullData(player)
	if playerData then
		table.insert(playerData.UnlockedWorlds, data.WorldId)
	end

	-- Notify client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local worldUnlocked = re:FindFirstChild("WorldUnlocked")
		if worldUnlocked then
			worldUnlocked:FireClient(player, {
				WorldId = data.WorldId,
				WorldName = worldConfig.Name,
			})
		end
	end

	StageService._Notify(player, "Unlocked " .. worldConfig.Name .. "!")
	print("[StageService]", player.Name, "unlocked world:", worldConfig.Name)
end

-- ============================================================================
-- TELEPORT TO STAGE
-- ============================================================================
function StageService.TeleportToStage(player, data)
	if not StageService.SecurityManager.CheckRateLimit(player, "TeleportToStage") then return end
	if not data or not data.WorldId or not data.StageNum then return end

	local worldId = data.WorldId
	local stageNum = tonumber(data.StageNum)
	if not stageNum then return end

	-- Must have the world unlocked
	if not StageService.DataService.HasUnlockedWorld(player, worldId) then
		StageService._Notify(player, "World is locked!")
		return
	end

	-- Must have completed the stage before (or it's stage 1)
	if stageNum > 1 and not StageService.DataService.HasCompletedStage(player, worldId, stageNum - 1) then
		StageService._Notify(player, "Complete the previous stage first!")
		return
	end

	-- Find the spawn point in workspace
	local worldFolder = workspace:FindFirstChild("Worlds")
	if worldFolder then
		local world = worldFolder:FindFirstChild(worldId)
		if world then
			local stage = world:FindFirstChild("Stage_" .. stageNum)
			if stage then
				local spawn = stage:FindFirstChild("Spawn") or stage:FindFirstChild("Checkpoint")
				if spawn and player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
					end
				end
			end
		end
	end

	-- Update checkpoint
	PlayerCheckpoints[player.UserId] = {
		WorldId = worldId,
		StageNum = stageNum,
	}

	-- Update data
	local playerData = StageService.DataService.GetFullData(player)
	if playerData then
		playerData.CurrentWorld = worldId
		playerData.CurrentStage = stageNum
	end
end

-- ============================================================================
-- DEATH / RESPAWN
-- ============================================================================
function StageService._SetupCharacterDeath(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		-- Notify speedrun service of death
		StageService.SpeedrunService.OnPlayerDeath(player)

		-- Fire death event for UI
		local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if re then
			local deathEvent = re:FindFirstChild("PlayerDied")
			if deathEvent then
				deathEvent:FireClient(player, {
					DeathCount = StageService.SpeedrunService.GetActiveRun(player)
						and StageService.SpeedrunService.GetActiveRun(player).DeathCount or 0,
				})
			end
		end

		-- Respawn at checkpoint after brief delay
		task.wait(1)
		StageService._RespawnAtCheckpoint(player)
	end)
end

function StageService._RespawnAtCheckpoint(player)
	local checkpoint = PlayerCheckpoints[player.UserId]
	if not checkpoint then return end

	-- Wait for character to respawn
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	-- If we have a CFrame, use it; otherwise find the checkpoint part
	if checkpoint.CheckpointCFrame then
		hrp.CFrame = checkpoint.CheckpointCFrame + Vector3.new(0, 3, 0)
	else
		local worldFolder = workspace:FindFirstChild("Worlds")
		if worldFolder then
			local world = worldFolder:FindFirstChild(checkpoint.WorldId)
			if world then
				local stage = world:FindFirstChild("Stage_" .. checkpoint.StageNum)
				if stage then
					local spawn = stage:FindFirstChild("Checkpoint") or stage:FindFirstChild("Spawn")
					if spawn then
						hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
					end
				end
			end
		end
	end
end

-- ============================================================================
-- WORLD TRIGGER SETUP
-- ============================================================================
-- Sets up .Touched events on workspace checkpoint/coin/killzone parts
function StageService._SetupWorldTriggers()
	local worldFolder = workspace:FindFirstChild("Worlds")
	if not worldFolder then
		warn("[StageService] No 'Worlds' folder found in workspace - skipping trigger setup")
		return
	end

	for _, worldModel in ipairs(worldFolder:GetChildren()) do
		local worldId = worldModel.Name

		for stageNum = 1, 10 do
			local stage = worldModel:FindFirstChild("Stage_" .. stageNum)
			if not stage then continue end

			-- Setup checkpoint triggers
			local checkpoint = stage:FindFirstChild("Checkpoint")
			if checkpoint and checkpoint:IsA("BasePart") then
				checkpoint.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player then
						StageService.OnCheckpointReached(player, {
							WorldId = worldId,
							StageNum = stageNum,
							IsStageEnd = false,
							CheckpointCFrame = checkpoint.CFrame,
						})
					end
				end)
			end

			-- Setup finish line triggers
			local finish = stage:FindFirstChild("FinishLine") or stage:FindFirstChild("StageEnd")
			if finish and finish:IsA("BasePart") then
				finish.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player then
						StageService.OnCheckpointReached(player, {
							WorldId = worldId,
							StageNum = stageNum,
							IsStageEnd = true,
							CheckpointCFrame = finish.CFrame,
						})
					end
				end)
			end

			-- Setup coin triggers
			local coinsFolder = stage:FindFirstChild("Coins")
			if coinsFolder then
				for coinIndex, coinPart in ipairs(coinsFolder:GetChildren()) do
					if coinPart:IsA("BasePart") then
						local ci = coinIndex -- capture for closure
						coinPart.Touched:Connect(function(hit)
							local player = Players:GetPlayerFromCharacter(hit.Parent)
							if player then
								StageService.OnCoinCollected(player, {
									WorldId = worldId,
									StageNum = stageNum,
									CoinIndex = ci,
								})
								-- Hide coin for this player (visual feedback)
								coinPart.Transparency = 1
								coinPart.CanCollide = false
								task.wait(30) -- Respawn coin after 30 seconds
								coinPart.Transparency = 0
								coinPart.CanCollide = false -- Coins should not block movement
							end
						end)
					end
				end
			end

			-- Setup kill zones
			local killZones = stage:FindFirstChild("KillZones")
			if killZones then
				for _, killPart in ipairs(killZones:GetChildren()) do
					if killPart:IsA("BasePart") then
						killPart.Touched:Connect(function(hit)
							local character = hit.Parent
							local humanoid = character and character:FindFirstChild("Humanoid")
							if humanoid and humanoid.Health > 0 then
								humanoid.Health = 0
							end
						end)
					end
				end
			end
		end
	end

	print("[StageService] World triggers setup complete")
end

-- ============================================================================
-- QUERIES
-- ============================================================================
function StageService.GetPlayerCheckpoint(player)
	return PlayerCheckpoints[player.UserId]
end

function StageService.ResetCoinsForStage(player, worldId, stageNum)
	local collected = CollectedCoins[player.UserId]
	if not collected then return end

	-- Remove entries for this specific stage
	local prefix = worldId .. "_" .. stageNum .. "_"
	for key, _ in pairs(collected) do
		if string.sub(key, 1, #prefix) == prefix then
			collected[key] = nil
		end
	end
end

-- ============================================================================
-- UTILITY
-- ============================================================================
function StageService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return StageService
