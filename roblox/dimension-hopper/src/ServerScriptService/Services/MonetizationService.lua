--[[
	MonetizationService.lua
	Handles Game Passes, VIP, and Developer Products

	Features:
	- Game Pass ownership tracking
	- VIP membership benefits
	- Developer Products (consumables)
	- Ad reward system
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- Game Pass definitions with benefits
local GAME_PASSES = {
	WingCollection = {
		Id = 0, -- Set in GameConfig
		Name = "Wing Collection",
		Description = "10 exclusive wing styles",
		Wings = {
			"Angel Wings", "Demon Wings", "Butterfly Wings", "Dragon Wings",
			"Fairy Wings", "Phoenix Wings", "Cyber Wings", "Galaxy Wings",
			"Rainbow Wings", "Shadow Wings"
		},
	},
	TrailCollection = {
		Id = 0,
		Name = "Trail Collection",
		Description = "15 trail effects",
		Trails = {
			"Fire", "Ice", "Lightning", "Rainbow", "Stars",
			"Hearts", "Music Notes", "Bubbles", "Smoke", "Sparkle",
			"Neon", "Pixel", "Confetti", "Flower", "Crystal"
		},
	},
	EmotePack = {
		Id = 0,
		Name = "Emote Pack",
		Description = "8 exclusive emotes",
		Emotes = {
			"Dab", "Floss", "Robot", "Backflip",
			"Salute", "Cheer", "Sit", "Sleep"
		},
	},
	DoubleXP = {
		Id = 0,
		Name = "Double XP",
		Description = "Permanent 2x XP multiplier",
		XPMultiplier = 2,
	},
}

-- Developer Products (consumables)
local DEV_PRODUCTS = {
	-- XP Boosts
	XPBoost_Small = { Id = 0, Name = "Small XP Boost", XP = 500 },
	XPBoost_Medium = { Id = 0, Name = "Medium XP Boost", XP = 1500 },
	XPBoost_Large = { Id = 0, Name = "Large XP Boost", XP = 5000 },

	-- Pass XP
	PassXP_Small = { Id = 0, Name = "Pass XP Boost", PassXP = 250 },
	PassXP_Medium = { Id = 0, Name = "Pass XP Boost+", PassXP = 750 },
	PassXP_Large = { Id = 0, Name = "Pass XP Mega", PassXP = 2500 },

	-- Skip
	SkipSection = { Id = 0, Name = "Skip Section", SkipSections = 1 },
}

-- ============================================================================
-- STATE
-- ============================================================================

MonetizationService.PlayerPasses = {} -- [UserId] = { passName = true/false }

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MonetizationService.Init()
	print("[MonetizationService] Initializing...")

	-- Load product IDs from GameConfig
	MonetizationService.LoadProductIds()

	-- Create remotes
	MonetizationService.CreateRemotes()

	-- Setup marketplace callbacks
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if wasPurchased then
			MonetizationService.OnGamePassPurchased(player, passId)
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return MonetizationService.ProcessReceipt(receiptInfo)
	end

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		MonetizationService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		MonetizationService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(MonetizationService.OnPlayerJoin, player)
	end

	print("[MonetizationService] Initialized")
end

function MonetizationService.LoadProductIds()
	local config = GameConfig.Monetization.GamePasses

	for passName, passData in pairs(GAME_PASSES) do
		if config[passName] and config[passName].Id > 0 then
			passData.Id = config[passName].Id
		end
	end

	-- VIP
	if GameConfig.Monetization.VIP and GameConfig.Monetization.VIP.ProductId > 0 then
		GAME_PASSES.VIP = {
			Id = GameConfig.Monetization.VIP.ProductId,
			Name = "VIP Membership",
			Description = "2x XP, Queue Priority, Exclusive Shop",
			XPMultiplier = GameConfig.Monetization.VIP.XPMultiplier or 2,
		}
	end
end

function MonetizationService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not remoteFunctions then
		remoteFunctions = Instance.new("Folder")
		remoteFunctions.Name = "RemoteFunctions"
		remoteFunctions.Parent = ReplicatedStorage
	end

	-- Game pass sync
	if not remoteFolder:FindFirstChild("GamePassSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GamePassSync"
		event.Parent = remoteFolder
	end

	-- Prompt purchase
	if not remoteFolder:FindFirstChild("PromptPurchase") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PromptPurchase"
		event.Parent = remoteFolder
	end

	-- Watch ad
	if not remoteFolder:FindFirstChild("WatchAd") then
		local event = Instance.new("RemoteEvent")
		event.Name = "WatchAd"
		event.Parent = remoteFolder
	end

	-- Get available products
	if not remoteFunctions:FindFirstChild("GetProducts") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetProducts"
		func.Parent = remoteFunctions

		func.OnServerInvoke = function(player)
			return MonetizationService.GetProductList(player)
		end
	end

	MonetizationService.Remotes = {
		GamePassSync = remoteFolder.GamePassSync,
		PromptPurchase = remoteFolder.PromptPurchase,
		WatchAd = remoteFolder.WatchAd,
	}

	-- Connect purchase prompt
	MonetizationService.Remotes.PromptPurchase.OnServerEvent:Connect(function(player, productType, productId)
		MonetizationService.PromptPurchase(player, productType, productId)
	end)

	-- Connect ad watching
	MonetizationService.Remotes.WatchAd.OnServerEvent:Connect(function(player)
		MonetizationService.ProcessAdWatch(player)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function MonetizationService.OnPlayerJoin(player: Player)
	MonetizationService.PlayerPasses[player.UserId] = {}

	-- Check ownership of all game passes
	for passName, passData in pairs(GAME_PASSES) do
		if passData.Id and passData.Id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.Id)
			end)

			if success and owns then
				MonetizationService.PlayerPasses[player.UserId][passName] = true
				MonetizationService.ApplyPassBenefits(player, passName)
			end
		end
	end

	-- Sync to client
	MonetizationService.SyncToClient(player)

	print(string.format("[MonetizationService] Loaded passes for %s", player.Name))
end

function MonetizationService.OnPlayerLeave(player: Player)
	MonetizationService.PlayerPasses[player.UserId] = nil
end

-- ============================================================================
-- GAME PASSES
-- ============================================================================

function MonetizationService.HasGamePass(player: Player, passName: string): boolean
	local passes = MonetizationService.PlayerPasses[player.UserId]
	return passes and passes[passName] or false
end

function MonetizationService.OnGamePassPurchased(player: Player, passId: number)
	-- Find which pass was purchased
	for passName, passData in pairs(GAME_PASSES) do
		if passData.Id == passId then
			MonetizationService.PlayerPasses[player.UserId][passName] = true
			MonetizationService.ApplyPassBenefits(player, passName)
			MonetizationService.SyncToClient(player)

			print(string.format("[MonetizationService] %s purchased %s", player.Name, passName))
			break
		end
	end
end

function MonetizationService.ApplyPassBenefits(player: Player, passName: string)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local passData = GAME_PASSES[passName]
	if not passData then return end

	local data = DataService.GetData(player)
	if not data then return end

	-- Unlock cosmetics
	if passData.Wings then
		for _, wing in ipairs(passData.Wings) do
			DataService.UnlockItem(player, "Wing", wing)
		end
	end

	if passData.Trails then
		for _, trail in ipairs(passData.Trails) do
			DataService.UnlockItem(player, "Trail", trail)
		end
	end

	if passData.Emotes then
		for _, emote in ipairs(passData.Emotes) do
			DataService.UnlockItem(player, "Emote", emote)
		end
	end

	-- Store in player data for persistence
	if not data.Purchases.GamePasses then
		data.Purchases.GamePasses = {}
	end
	data.Purchases.GamePasses[passName] = true

	-- VIP special handling
	if passName == "VIP" then
		data.Purchases.VIP = true
	end
end

-- ============================================================================
-- DEVELOPER PRODUCTS
-- ============================================================================

function MonetizationService.ProcessReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	-- Find which product was purchased
	for productName, productData in pairs(DEV_PRODUCTS) do
		if productData.Id == productId then
			local success = MonetizationService.GrantProduct(player, productName, productData)

			if success then
				print(string.format("[MonetizationService] %s purchased %s", player.Name, productName))
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end

	-- Check if it's the Dimension Pass
	local passProductId = GameConfig.Monetization.DimensionPass.ProductId
	if productId == passProductId then
		local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
		if DataService then
			local data = DataService.GetData(player)
			if data then
				data.Purchases.DimensionPass = true
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.GrantProduct(player: Player, productName: string, productData: table): boolean
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	local DimensionPassService = _G.DimensionHopper and _G.DimensionHopper.GetService("DimensionPassService")

	-- XP Boost
	if productData.XP and DataService then
		DataService.AddXP(player, productData.XP, "XP Boost Purchase")
		return true
	end

	-- Pass XP
	if productData.PassXP and DimensionPassService then
		DimensionPassService.AddPassXP(player, productData.PassXP)
		return true
	end

	-- Skip Section
	if productData.SkipSections then
		local CheckpointService = _G.DimensionHopper and _G.DimensionHopper.GetService("CheckpointService")
		local RaceService = _G.DimensionHopper and _G.DimensionHopper.GetService("RaceService")

		if CheckpointService and RaceService then
			-- Only allow during active race
			if not RaceService.IsRacing() then
				warn("[MonetizationService] Cannot skip section - no active race")
				return false
			end

			-- Get current section
			local currentSection = CheckpointService.GetPlayerSection(player)
			local targetSection = currentSection + productData.SkipSections

			-- Get maximum section (prevent skipping past finish)
			local maxSection = CheckpointService.GetTotalSections and CheckpointService.GetTotalSections() or 20
			if targetSection >= maxSection then
				warn("[MonetizationService] Cannot skip - already at or near finish")
				return false
			end

			-- Teleport player to next checkpoint
			local success = CheckpointService.SkipToSection(player, targetSection)
			if success then
				print(string.format("[MonetizationService] %s skipped to section %d", player.Name, targetSection))
				return true
			end
		end

		return false
	end

	return false
end

-- ============================================================================
-- AD REWARDS
-- ============================================================================

function MonetizationService.ProcessAdWatch(player: Player)
	if not GameConfig.Monetization.Ads.Enabled then
		return false
	end

	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return false end

	local data = DataService.GetData(player)
	if not data then return false end

	local today = os.date("%Y-%m-%d")

	-- Reset counter if new day
	if data.Purchases.LastAdDate ~= today then
		data.Purchases.AdsWatchedToday = 0
		data.Purchases.LastAdDate = today
	end

	-- Check daily limit
	local maxAds = GameConfig.Monetization.Ads.MaxAdsPerDay or 5
	if data.Purchases.AdsWatchedToday >= maxAds then
		return false
	end

	-- Grant reward
	local xpReward = GameConfig.Monetization.Ads.XPPerAd or 50
	DataService.AddXP(player, xpReward, "Ad Watch")

	data.Purchases.AdsWatchedToday = data.Purchases.AdsWatchedToday + 1

	print(string.format("[MonetizationService] %s watched ad (%d/%d today)",
		player.Name, data.Purchases.AdsWatchedToday, maxAds))

	return true
end

function MonetizationService.CanWatchAd(player: Player): boolean
	if not GameConfig.Monetization.Ads.Enabled then
		return false
	end

	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return false end

	local data = DataService.GetData(player)
	if not data then return false end

	local today = os.date("%Y-%m-%d")
	if data.Purchases.LastAdDate ~= today then
		return true
	end

	local maxAds = GameConfig.Monetization.Ads.MaxAdsPerDay or 5
	return data.Purchases.AdsWatchedToday < maxAds
end

-- ============================================================================
-- PURCHASE PROMPTS
-- ============================================================================

function MonetizationService.PromptPurchase(player: Player, productType: string, productName: string)
	if productType == "GamePass" then
		local passData = GAME_PASSES[productName]
		if passData and passData.Id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, passData.Id)
		end

	elseif productType == "DevProduct" then
		local productData = DEV_PRODUCTS[productName]
		if productData and productData.Id > 0 then
			MarketplaceService:PromptProductPurchase(player, productData.Id)
		end
	end
end

-- ============================================================================
-- SYNC & DATA
-- ============================================================================

function MonetizationService.SyncToClient(player: Player)
	local passes = MonetizationService.PlayerPasses[player.UserId] or {}

	MonetizationService.Remotes.GamePassSync:FireClient(player, {
		OwnedPasses = passes,
		CanWatchAd = MonetizationService.CanWatchAd(player),
	})
end

function MonetizationService.GetProductList(player: Player): table
	local products = {
		GamePasses = {},
		DevProducts = {},
	}

	for passName, passData in pairs(GAME_PASSES) do
		table.insert(products.GamePasses, {
			Name = passName,
			DisplayName = passData.Name,
			Description = passData.Description,
			Id = passData.Id,
			Owned = MonetizationService.HasGamePass(player, passName),
		})
	end

	for productName, productData in pairs(DEV_PRODUCTS) do
		table.insert(products.DevProducts, {
			Name = productName,
			DisplayName = productData.Name,
			Id = productData.Id,
		})
	end

	return products
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function MonetizationService.GetXPMultiplier(player: Player): number
	local multiplier = 1

	-- Check DoubleXP pass
	if MonetizationService.HasGamePass(player, "DoubleXP") then
		multiplier = multiplier * 2
	end

	-- Check VIP
	if MonetizationService.HasGamePass(player, "VIP") then
		multiplier = multiplier * (GameConfig.Monetization.VIP.XPMultiplier or 2)
	end

	return multiplier
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function MonetizationService.DebugGrantPass(player: Player, passName: string)
	MonetizationService.PlayerPasses[player.UserId][passName] = true
	MonetizationService.ApplyPassBenefits(player, passName)
	MonetizationService.SyncToClient(player)
end

return MonetizationService
