--[[
	CollectibleService.lua
	Manages collectibles (fragments, coins, bonuses)

	Handles:
	- Collectible spawning
	- Touch detection
	- Collection validation (anti-cheat)
	- Rewards
	- Quest progress updates
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StoryConfig = require(ReplicatedStorage.Shared.Config.StoryConfig)

local CollectibleService = {}
local DataService = nil -- Lazy loaded
local StoryService = nil
local QuestService = nil

-- Anti-cheat tracking
-- Format: [Player] = {LastCollection = tick(), CollectionsThisSecond = 0}
local CollectionTracking = {}

-- Active collectibles
-- Format: [CollectibleInstance] = {Type = "Fragment", Id = "Fragment_W1_L2", Reward = 50, AnimationThread = thread}
local ActiveCollectibles = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CollectibleService.Init()
	print("[CollectibleService] Initializing...")

	-- Lazy load services
	DataService = require(ServerScriptService.Services.DataService)
	StoryService = require(ServerScriptService.Services.StoryService)

	-- Setup collectibles in world
	CollectibleService.SetupCollectibles()

	print("[CollectibleService] Initialized")
end

-- ============================================================================
-- COLLECTIBLE SETUP
-- ============================================================================

function CollectibleService.SetupCollectibles()
	-- Find all collectibles in workspace
	local collectiblesFolder = Workspace:FindFirstChild("Collectibles")
	if not collectiblesFolder then
		warn("[CollectibleService] Collectibles folder not found in Workspace")
		return
	end

	-- Setup each collectible
	for _, collectible in ipairs(collectiblesFolder:GetDescendants()) do
		if collectible:IsA("BasePart") and collectible:GetAttribute("CollectibleType") then
			CollectibleService.SetupCollectible(collectible)
		end
	end

	print(string.format("[CollectibleService] Setup %d collectibles", #ActiveCollectibles))
end

function CollectibleService.SetupCollectible(collectible: BasePart)
	-- Get collectible data from attributes
	local collectibleType = collectible:GetAttribute("CollectibleType") -- "Fragment", "Coin", "Bonus"
	local collectibleId = collectible:GetAttribute("CollectibleId") -- "Fragment_W1_L2"

	if not collectibleType or not collectibleId then
		warn("[CollectibleService] Invalid collectible attributes:", collectible:GetFullName())
		return
	end

	-- Get reward data
	local typeConfig = StoryConfig.Collectibles.Types[collectibleType]
	if not typeConfig then
		warn("[CollectibleService] Unknown collectible type:", collectibleType)
		return
	end

	-- Store collectible data
	local collectibleData = {
		Type = collectibleType,
		Id = collectibleId,
		Reward = typeConfig.CoinReward,
		AnimationThread = nil, -- Will be set by AddCollectibleEffects
	}
	ActiveCollectibles[collectible] = collectibleData

	-- Add visual effects (particle emitter)
	CollectibleService.AddCollectibleEffects(collectible, typeConfig, collectibleData)

	-- Connect touch detection
	collectible.Touched:Connect(function(hit)
		CollectibleService.OnCollectibleTouched(collectible, hit)
	end)

	print(string.format("[CollectibleService] Setup collectible: %s (%s)", collectibleId, collectibleType))
end

function CollectibleService.AddCollectibleEffects(collectible: BasePart, typeConfig: {}, collectibleData: {})
	-- Add particle emitter for visual effect
	local particle = Instance.new("ParticleEmitter")
	particle.Name = "CollectibleParticle"
	particle.Color = ColorSequence.new(typeConfig.ParticleColor)
	particle.LightEmission = 1
	particle.Size = NumberSequence.new(0.2, 0.5)
	particle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particle.Transparency = NumberSequence.new(0, 1)
	particle.Lifetime = NumberRange.new(1, 2)
	particle.Rate = 20
	particle.Speed = NumberRange.new(1, 3)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.Parent = collectible

	-- Add spinning animation
	local rotationValue = Instance.new("NumberValue")
	rotationValue.Name = "Rotation"
	rotationValue.Value = 0
	rotationValue.Parent = collectible

	-- CRITICAL FIX: Store animation thread for explicit cleanup (prevents memory leak)
	local animationThread = task.spawn(function()
		local running = true

		-- Add cleanup on collectible destruction
		collectible.AncestryChanged:Connect(function()
			if not collectible:IsDescendantOf(game) then
				running = false
			end
		end)

		while running and collectible.Parent and collectible:IsDescendantOf(Workspace) do
			rotationValue.Value = rotationValue.Value + 2
			collectible.CFrame = collectible.CFrame * CFrame.Angles(0, math.rad(2), 0)
			task.wait(0.03)
		end

		-- Thread cleanup
		running = false
	end)

	-- Store thread reference for explicit cleanup
	collectibleData.AnimationThread = animationThread
end

-- ============================================================================
-- COLLECTION
-- ============================================================================

function CollectibleService.OnCollectibleTouched(collectible: BasePart, hit: BasePart)
	-- Check if hit is a player character
	local character = hit.Parent
	if not character or not character:FindFirstChild("Humanoid") then
		return
	end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Attempt collection
	CollectibleService.CollectItem(player, collectible)
end

function CollectibleService.CollectItem(player: Player, collectible: BasePart): boolean
	-- Get collectible data
	local collectibleData = ActiveCollectibles[collectible]
	if not collectibleData then
		return false
	end

	-- Anti-cheat: Rate limiting
	if not CollectibleService.ValidateCollection(player) then
		warn(string.format("[CollectibleService] %s exceeded collection rate limit", player.Name))
		return false
	end

	-- Check if already collected
	if collectibleData.Type == "Fragment" then
		if StoryService.HasFragment(player, collectibleData.Id) then
			-- Already collected, don't allow again
			return false
		end

		-- Collect fragment
		local success = StoryService.CollectFragment(player, collectibleData.Id)
		if not success then
			return false
		end

		-- Update quest progress
		QuestService = QuestService or require(ServerScriptService.Services.QuestService)
		QuestService.UpdateQuestProgress(player, "Collect", collectibleData.Id, 1)

	elseif collectibleData.Type == "Coin" then
		-- Award coins
		DataService.AddCoins(player, collectibleData.Reward)

		-- Update quest progress
		QuestService = QuestService or require(ServerScriptService.Services.QuestService)
		QuestService.UpdateQuestProgress(player, "CollectCoins", "Any", collectibleData.Reward)

	elseif collectibleData.Type == "Bonus" then
		-- Award bonus coins
		DataService.AddCoins(player, collectibleData.Reward)
	end

	-- Remove collectible
	CollectibleService.RemoveCollectible(collectible)

	print(string.format("[CollectibleService] %s collected %s (+%d coins)",
		player.Name, collectibleData.Id, collectibleData.Reward))

	return true
end

function CollectibleService.RemoveCollectible(collectible: BasePart)
	-- CRITICAL FIX: Clean up animation thread before destroying (prevents memory leak)
	local collectibleData = ActiveCollectibles[collectible]
	if collectibleData and collectibleData.AnimationThread then
		task.cancel(collectibleData.AnimationThread)
		collectibleData.AnimationThread = nil
	end

	-- Remove from active collectibles BEFORE destroying
	ActiveCollectibles[collectible] = nil

	-- Play collection effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.Parent = collectible
	sound:Play()

	-- Fade out
	local particle = collectible:FindFirstChild("CollectibleParticle")
	if particle then
		particle.Enabled = false
	end

	-- Remove after delay
	task.wait(0.5)
	collectible:Destroy()
end

-- ============================================================================
-- ANTI-CHEAT
-- ============================================================================

function CollectibleService.ValidateCollection(player: Player): boolean
	local now = tick()
	local tracking = CollectionTracking[player]

	if not tracking then
		-- First collection
		CollectionTracking[player] = {
			LastCollection = now,
			CollectionsThisSecond = 1,
		}
		return true
	end

	-- Check time since last collection
	local timeSinceLastCollection = now - tracking.LastCollection

	if timeSinceLastCollection < StoryConfig.Collectibles.MinTimeBetweenCollections then
		-- Too fast
		return false
	end

	-- Reset counter if more than 1 second has passed
	if timeSinceLastCollection > 1 then
		tracking.CollectionsThisSecond = 1
		tracking.LastCollection = now
		return true
	end

	-- Check rate limit
	if tracking.CollectionsThisSecond >= StoryConfig.Collectibles.MaxCollectionsPerSecond then
		-- Too many collections per second
		return false
	end

	-- Valid collection
	tracking.CollectionsThisSecond = tracking.CollectionsThisSecond + 1
	tracking.LastCollection = now

	return true
end

-- ============================================================================
-- MANUAL COLLECTION (for scripted events)
-- ============================================================================

function CollectibleService.GiveCollectible(player: Player, collectibleType: string, collectibleId: string): boolean
	local typeConfig = StoryConfig.Collectibles.Types[collectibleType]
	if not typeConfig then
		warn("[CollectibleService] Unknown collectible type:", collectibleType)
		return false
	end

	if collectibleType == "Fragment" then
		return StoryService.CollectFragment(player, collectibleId)
	elseif collectibleType == "Coin" then
		return DataService.AddCoins(player, typeConfig.CoinReward)
	elseif collectibleType == "Bonus" then
		return DataService.AddCoins(player, typeConfig.CoinReward)
	end

	return false
end

return CollectibleService
