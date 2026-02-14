--[[
	GamePassService.lua
	Manages individual Game Pass products for Tower Ascent

	Game Passes (one-time purchases):
	- Particle Effects Pack - Exclusive trail effects
	- Emote Pack - Special emotes/animations
	- Double XP - Permanent 2x XP for Battle Pass
	- Checkpoint Skip - Skip to last checkpoint on death
	- Speed Demon - +5% permanent speed boost

	Week 14: Additional monetization
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePassService = {}
GamePassService.PlayerPasses = {} -- [UserId] = {PassId = true, ...}
GamePassService.IsInitialized = false
GamePassService.PurchaseRateLimits = {}

-- ============================================================================
-- GAME PASS DEFINITIONS
-- ============================================================================

local GAME_PASSES = {
	ParticleEffects = {
		Id = 0, -- PLACEHOLDER: Set after creating on Roblox
		Name = "Particle Effects Pack",
		Description = "Unlock 5 exclusive trail effects: Fire, Ice, Rainbow, Galaxy, Neon",
		Price = 149, -- Robux
		Benefits = {
			Trails = { "Fire_Premium", "Ice_Premium", "Rainbow_Premium", "Galaxy_Premium", "Neon_Premium" }
		},
	},

	EmotePack = {
		Id = 0, -- PLACEHOLDER
		Name = "Emote Pack",
		Description = "Unlock 5 special emotes: Celebrate, Flex, Dizzy, Surrender, Breakdance",
		Price = 99, -- Robux
		Benefits = {
			Emotes = { "Celebrate", "Flex", "Dizzy", "Surrender", "Breakdance" }
		},
	},

	DoubleXP = {
		Id = 0, -- PLACEHOLDER
		Name = "Double XP",
		Description = "Earn 2x Battle Pass XP permanently",
		Price = 199, -- Robux
		Benefits = {
			XPMultiplier = 2
		},
	},

	CheckpointSkip = {
		Id = 0, -- PLACEHOLDER
		Name = "Checkpoint Skip",
		Description = "Option to skip to your last checkpoint when you die",
		Price = 79, -- Robux
		Benefits = {
			CanSkipCheckpoint = true
		},
	},

	SpeedDemon = {
		Id = 0, -- PLACEHOLDER
		Name = "Speed Demon",
		Description = "Permanent +5% walk speed boost",
		Price = 149, -- Robux
		Benefits = {
			SpeedBoost = 0.05 -- 5%
		},
	},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GamePassService.Init()
	print("[GamePassService] Initializing...")

	-- Create RemoteEvents
	GamePassService.CreateRemoteEvents()

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		GamePassService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GamePassService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(GamePassService.OnPlayerJoin, player)
	end

	-- Listen for purchases
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased then
			GamePassService.OnGamePassPurchased(player, gamePassId)
		end
	end)

	GamePassService.IsInitialized = true
	print("[GamePassService] Initialized with " .. GamePassService.GetConfiguredPassCount() .. " configured passes")
end

function GamePassService.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Game Pass Status Update
	if not remoteFolder:FindFirstChild("GamePassUpdate") then
		local updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "GamePassUpdate"
		updateEvent.Parent = remoteFolder
	end

	-- Prompt Game Pass Purchase
	if not remoteFolder:FindFirstChild("PromptGamePassPurchase") then
		local purchaseEvent = Instance.new("RemoteEvent")
		purchaseEvent.Name = "PromptGamePassPurchase"
		purchaseEvent.Parent = remoteFolder

		purchaseEvent.OnServerEvent:Connect(function(player, passName)
			GamePassService.PromptPurchase(player, passName)
		end)
	end

	-- Get Game Pass Data (RemoteFunction)
	if not remoteFolder:FindFirstChild("GetGamePassData") then
		local dataFunction = Instance.new("RemoteFunction")
		dataFunction.Name = "GetGamePassData"
		dataFunction.Parent = remoteFolder

		dataFunction.OnServerInvoke = function(player)
			return GamePassService.GetPlayerPassData(player)
		end
	end
end

function GamePassService.GetConfiguredPassCount(): number
	local count = 0
	for _, pass in pairs(GAME_PASSES) do
		if pass.Id > 0 then
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function GamePassService.OnPlayerJoin(player: Player)
	GamePassService.PlayerPasses[player.UserId] = {}

	-- Check ownership of all passes
	task.spawn(function()
		for passName, passData in pairs(GAME_PASSES) do
			if passData.Id > 0 then
				GamePassService.CheckPassOwnership(player, passName)
			end
		end

		-- Apply benefits after all checks complete
		GamePassService.ApplyAllBenefits(player)

		-- Notify client
		GamePassService.NotifyPassStatus(player)
	end)

	print(string.format("[GamePassService] Initialized passes for %s", player.Name))
end

function GamePassService.OnPlayerLeave(player: Player)
	GamePassService.PlayerPasses[player.UserId] = nil
	GamePassService.PurchaseRateLimits[player.UserId] = nil
end

function GamePassService.CheckPassOwnership(player: Player, passName: string)
	local passData = GAME_PASSES[passName]
	if not passData or passData.Id == 0 then return end

	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.Id)
	end)

	if success and ownsPass then
		GamePassService.PlayerPasses[player.UserId][passName] = true
		print(string.format("[GamePassService] %s owns %s", player.Name, passData.Name))
	end
end

function GamePassService.OnGamePassPurchased(player: Player, gamePassId: number)
	-- Find which pass was purchased
	for passName, passData in pairs(GAME_PASSES) do
		if passData.Id == gamePassId then
			GamePassService.PlayerPasses[player.UserId][passName] = true
			print(string.format("[GamePassService] %s purchased %s!", player.Name, passData.Name))

			-- Apply benefits immediately
			GamePassService.ApplyPassBenefits(player, passName)

			-- Notify client
			GamePassService.NotifyPassStatus(player)
			return
		end
	end
end

-- ============================================================================
-- BENEFITS
-- ============================================================================

function GamePassService.ApplyAllBenefits(player: Player)
	local passes = GamePassService.PlayerPasses[player.UserId]
	if not passes then return end

	for passName, owned in pairs(passes) do
		if owned then
			GamePassService.ApplyPassBenefits(player, passName)
		end
	end
end

function GamePassService.ApplyPassBenefits(player: Player, passName: string)
	local passData = GAME_PASSES[passName]
	if not passData then return end

	local benefits = passData.Benefits
	if not benefits then return end

	-- Set attributes for benefits
	if benefits.XPMultiplier then
		player:SetAttribute("XPMultiplier", benefits.XPMultiplier)
	end

	if benefits.CanSkipCheckpoint then
		player:SetAttribute("CanSkipCheckpoint", true)
	end

	if benefits.SpeedBoost then
		player:SetAttribute("SpeedBoostMultiplier", 1 + benefits.SpeedBoost)

		-- Apply speed boost to character
		if player.Character then
			GamePassService.ApplySpeedBoost(player.Character, benefits.SpeedBoost)
		end

		-- Apply to future characters
		player.CharacterAdded:Connect(function(character)
			GamePassService.ApplySpeedBoost(character, benefits.SpeedBoost)
		end)
	end

	if benefits.Trails then
		-- Grant trails cosmetics
		GamePassService.GrantCosmetics(player, "Trails", benefits.Trails)
	end

	if benefits.Emotes then
		-- Grant emote cosmetics
		GamePassService.GrantCosmetics(player, "Emotes", benefits.Emotes)
	end

	print(string.format("[GamePassService] Applied %s benefits to %s", passName, player.Name))
end

function GamePassService.ApplySpeedBoost(character: Model, boostAmount: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Only set BaseWalkSpeed if not already set (prevents desync with other speed systems)
		if not humanoid:GetAttribute("BaseWalkSpeed") then
			humanoid:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
		end

		-- Get the current base speed
		local baseSpeed = humanoid:GetAttribute("BaseWalkSpeed")

		-- Apply boost multiplicatively
		humanoid.WalkSpeed = baseSpeed * (1 + boostAmount)

		print(string.format(
			"[GamePassService] Applied %d%% speed boost (Base: %.1f, New: %.1f)",
			boostAmount * 100,
			baseSpeed,
			humanoid.WalkSpeed
		))
	end
end

function GamePassService.GrantCosmetics(player: Player, category: string, items: {string})
	local success, DataService = pcall(function()
		return require(script.Parent.Parent.DataService)
	end)

	if success and DataService then
		local profile = DataService.GetProfile(player)
		if profile then
			if not profile.Data.Cosmetics then
				profile.Data.Cosmetics = {}
			end
			if not profile.Data.Cosmetics[category] then
				profile.Data.Cosmetics[category] = {}
			end

			for _, item in ipairs(items) do
				profile.Data.Cosmetics[category][item] = true
			end
		end
	end
end

-- ============================================================================
-- STATUS CHECKING
-- ============================================================================

function GamePassService.HasPass(player: Player, passName: string): boolean
	local passes = GamePassService.PlayerPasses[player.UserId]
	return passes and passes[passName] == true
end

function GamePassService.GetXPMultiplier(player: Player): number
	if GamePassService.HasPass(player, "DoubleXP") then
		return 2
	end
	return 1
end

function GamePassService.CanSkipCheckpoint(player: Player): boolean
	return GamePassService.HasPass(player, "CheckpointSkip")
end

function GamePassService.GetSpeedMultiplier(player: Player): number
	if GamePassService.HasPass(player, "SpeedDemon") then
		return 1.05 -- 5% boost
	end
	return 1
end

-- ============================================================================
-- PURCHASE HANDLING
-- ============================================================================

function GamePassService.PromptPurchase(player: Player, passName: string)
	local passData = GAME_PASSES[passName]
	if not passData then
		warn(string.format("[GamePassService] Unknown pass: %s", passName))
		return
	end

	if passData.Id == 0 then
		warn(string.format("[GamePassService] Pass not configured: %s", passName))
		return
	end

	-- Rate limiting
	local now = tick()
	local lastPrompt = GamePassService.PurchaseRateLimits[player.UserId] or 0
	if now - lastPrompt < 5 then
		return
	end
	GamePassService.PurchaseRateLimits[player.UserId] = now

	-- Check if already owned
	if GamePassService.HasPass(player, passName) then
		print(string.format("[GamePassService] %s already owns %s", player.Name, passData.Name))
		return
	end

	-- Prompt purchase
	task.spawn(function()
		local success, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, passData.Id)
		end)
		if not success then
			warn(string.format("[GamePassService] Purchase prompt failed: %s", tostring(err)))
		end
	end)
end

-- ============================================================================
-- CLIENT COMMUNICATION
-- ============================================================================

function GamePassService.NotifyPassStatus(player: Player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then return end

	local updateEvent = remoteFolder:FindFirstChild("GamePassUpdate")
	if updateEvent then
		local data = GamePassService.GetPlayerPassData(player)
		updateEvent:FireClient(player, data)
	end
end

function GamePassService.GetPlayerPassData(player: Player): {}
	local ownedPasses = GamePassService.PlayerPasses[player.UserId] or {}
	local passData = {}

	for passName, data in pairs(GAME_PASSES) do
		passData[passName] = {
			Name = data.Name,
			Description = data.Description,
			Price = data.Price,
			Owned = ownedPasses[passName] == true,
			Benefits = data.Benefits,
			Configured = data.Id > 0,
		}
	end

	return passData
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function GamePassService.AdminGrantPass(player: Player, passName: string)
	local passData = GAME_PASSES[passName]
	if not passData then
		warn("[GamePassService] Unknown pass: " .. passName)
		return
	end

	GamePassService.PlayerPasses[player.UserId][passName] = true
	GamePassService.ApplyPassBenefits(player, passName)
	GamePassService.NotifyPassStatus(player)
	print(string.format("[GamePassService] ADMIN: Granted %s to %s", passData.Name, player.Name))
end

function GamePassService.AdminRevokePass(player: Player, passName: string)
	GamePassService.PlayerPasses[player.UserId][passName] = nil
	GamePassService.NotifyPassStatus(player)
	print(string.format("[GamePassService] ADMIN: Revoked %s from %s", passName, player.Name))
end

function GamePassService.DebugPrint()
	print("=== GAME PASS SERVICE STATUS ===")

	for passName, passData in pairs(GAME_PASSES) do
		print(string.format("  %s (ID: %d, Price: %d R$)",
			passData.Name, passData.Id, passData.Price))
	end

	print("\nPlayer Ownership:")
	for userId, passes in pairs(GamePassService.PlayerPasses) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local ownedList = {}
			for passName, owned in pairs(passes) do
				if owned then
					table.insert(ownedList, passName)
				end
			end
			print(string.format("  %s: %s",
				player.Name,
				#ownedList > 0 and table.concat(ownedList, ", ") or "None"
			))
		end
	end
	print("=================================")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return GamePassService
