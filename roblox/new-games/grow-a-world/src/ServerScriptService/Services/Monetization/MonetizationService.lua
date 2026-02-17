--[[
	MonetizationService.lua - Grow a World
	Handles Game Passes and Developer Products (Robux purchases)
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}
MonetizationService.DataService = nil

function MonetizationService.Init()
	print("[MonetizationService] Initializing...")
	MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	MonetizationService.SetupGamePassHandlers()
	MonetizationService.SetupDevProductHandlers()
	MonetizationService.SetupRemotes()
	print("[MonetizationService] Initialized")
end

function MonetizationService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetShopData").OnServerEvent:Connect(function(player)
		MonetizationService.SendShopData(player)
	end)

	remoteEvents:WaitForChild("PurchaseGamePass").OnServerEvent:Connect(function(player, passName)
		MonetizationService.PromptGamePass(player, passName)
	end)

	remoteEvents:WaitForChild("PurchaseDevProduct").OnServerEvent:Connect(function(player, productName)
		MonetizationService.PromptDevProduct(player, productName)
	end)
end

-- ============================================================================
-- GAME PASS HANDLING
-- ============================================================================

function MonetizationService.SetupGamePassHandlers()
	-- Check existing game passes on join
	Players.PlayerAdded:Connect(function(player)
		task.wait(2) -- Wait for data to load
		MonetizationService.CheckExistingPasses(player)
	end)
end

function MonetizationService.CheckExistingPasses(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end
	data.GamePasses = data.GamePasses or {}

	for passName, passConfig in pairs(GameConfig.GamePasses) do
		if passConfig.Id > 0 then
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passConfig.Id)
			end)
			if success and ownsPass then
				data.GamePasses[passName] = true
			end
		end
	end
end

function MonetizationService.PromptGamePass(player, passName)
	local passConfig = GameConfig.GamePasses[passName]
	if not passConfig or passConfig.Id <= 0 then return end

	MarketplaceService:PromptGamePassPurchase(player, passConfig.Id)
end

-- ============================================================================
-- DEVELOPER PRODUCT HANDLING
-- ============================================================================

function MonetizationService.SetupDevProductHandlers()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local productId = receiptInfo.ProductId
		local data = MonetizationService.DataService.GetFullData(player)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

		-- Find matching product
		for productName, productConfig in pairs(GameConfig.DevProducts) do
			if productConfig.Id == productId then
				local success = MonetizationService.GrantDevProduct(player, productName, productConfig)
				if success then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService.GrantDevProduct(player, productName, productConfig)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return false end

	-- Coin packs
	if productConfig.Amount then
		MonetizationService.DataService.AddCoins(player, productConfig.Amount)
		print("[MonetizationService]", player.Name, "purchased", productName, "- granted", productConfig.Amount, "coins")
		return true
	end

	-- Rare seed pack
	if productName == "RareSeedPack" then
		local SeedService = require(ServerScriptService.Services.SeedService)
		SeedService.BuySeedPack(player, "Legendary")
		print("[MonetizationService]", player.Name, "purchased Rare Seed Pack")
		return true
	end

	-- Instant grow
	if productName == "InstantGrow" then
		local GardenService = require(ServerScriptService.Services.GardenService)
		local gardens = GardenService.PlayerGardens[player.UserId]
		if gardens then
			for biomeName, garden in pairs(gardens) do
				for plotIndex, plot in pairs(garden.Plots) do
					plot.PlantedAt = os.time() - plot.GrowTime -- Make all plants mature
				end
			end
		end
		print("[MonetizationService]", player.Name, "used Instant Grow")
		return true
	end

	-- Luck Potion
	if productName == "LuckPotion" then
		-- Temporary luck boost stored in data
		data._LuckPotionExpiry = os.time() + 1800 -- 30 minutes
		print("[MonetizationService]", player.Name, "activated Luck Potion (30 min)")
		return true
	end

	return false
end

function MonetizationService.PromptDevProduct(player, productName)
	local productConfig = GameConfig.DevProducts[productName]
	if not productConfig or productConfig.Id <= 0 then return end

	MarketplaceService:PromptProductPurchase(player, productConfig.Id)
end

-- ============================================================================
-- SHOP DATA
-- ============================================================================

function MonetizationService.SendShopData(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end

	local shopData = {
		GamePasses = {},
		DevProducts = {},
		OwnedPasses = data.GamePasses or {},
	}

	for name, config in pairs(GameConfig.GamePasses) do
		shopData.GamePasses[name] = {
			Name = config.Name,
			Description = config.Description,
			Price = config.Price,
			Owned = data.GamePasses and data.GamePasses[name] or false,
		}
	end

	for name, config in pairs(GameConfig.DevProducts) do
		shopData.DevProducts[name] = {
			Name = config.Name,
			Description = config.Description or "",
			Price = config.Price,
		}
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local shopRemote = remoteEvents:FindFirstChild("ShopData")
		if shopRemote then
			shopRemote:FireClient(player, shopData)
		end
	end
end

return MonetizationService
