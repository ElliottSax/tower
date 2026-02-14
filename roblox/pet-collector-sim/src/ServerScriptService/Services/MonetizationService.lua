--[[
	MonetizationService.lua
	Pet Collector Simulator - Monetization & Revenue Service

	Handles:
	- Game Pass purchases and benefits
	- Developer Product purchases (coins, eggs, boosts)
	- Receipt processing
	- VIP benefits
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}
MonetizationService.DataService = nil
MonetizationService.PetService = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MonetizationService.Init()
	print("[MonetizationService] Initializing...")

	-- Setup marketplace callbacks
	MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(MonetizationService.OnGamePassPurchase)

	-- Setup remote events
	MonetizationService.SetupRemotes()

	print("[MonetizationService] Initialized - Revenue tracking active")
end

function MonetizationService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Purchase dev product
	local purchaseProductRemote = remoteEvents:WaitForChild("PurchaseProduct")
	purchaseProductRemote.OnServerEvent:Connect(function(player, productName)
		MonetizationService.PromptProductPurchase(player, productName)
	end)

	-- Check game pass
	local checkGamePassRemote = remoteEvents:WaitForChild("CheckGamePass")
	checkGamePassRemote.OnServerInvoke = function(player, gamePassName)
		return MonetizationService.HasGamePass(player, gamePassName)
	end

	-- Get VIP benefits
	local getVIPBenefitsRemote = remoteEvents:WaitForChild("GetVIPBenefits")
	getVIPBenefitsRemote.OnServerInvoke = function(player)
		return MonetizationService.GetPlayerBenefits(player)
	end
end

-- ============================================================================
-- GAME PASSES
-- ============================================================================

function MonetizationService.HasGamePass(player: Player, gamePassName: string)
	local gamePass = GameConfig.GamePasses[gamePassName]
	if not gamePass or gamePass.Id == 0 then
		return false -- Not configured
	end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePass.Id)
	end)

	return success and hasPass
end

function MonetizationService.OnGamePassPurchase(player, gamePassId, wasPurchased)
	if not wasPurchased then return end

	-- Find game pass name
	local gamePassName = nil
	for name, data in pairs(GameConfig.GamePasses) do
		if data.Id == gamePassId then
			gamePassName = name
			break
		end
	end

	if gamePassName then
		print(string.format("[MonetizationService] %s purchased %s game pass!",
			player.Name, gamePassName))

		-- Apply immediate benefits
		MonetizationService.ApplyGamePassBenefits(player, gamePassName)

		-- Notify player
		local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
		if notifyRemote then
			notifyRemote:FireClient(player,
				string.format("Thanks for purchasing %s!", gamePassName),
				"Success")
		end
	end
end

function MonetizationService.ApplyGamePassBenefits(player: Player, gamePassName: string)
	if not MonetizationService.DataService then
		MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = MonetizationService.DataService.GetData(player)
	if not playerData then return end

	-- Apply specific benefits
	if gamePassName == "VIP" then
		-- VIP gets immediate coin bonus
		MonetizationService.DataService.AddCoins(player, 10000)

		-- Speed boost
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = GameConfig.Settings.VIPWalkSpeed
			end
		end

	elseif gamePassName == "SpeedBoost" then
		-- Speed boost
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = GameConfig.Settings.VIPWalkSpeed
			end
		end

	elseif gamePassName == "ExtraSlots" then
		-- Inventory expanded automatically in PetService

	elseif gamePassName == "LuckyBoost" then
		-- Luck boost applied in PetService.RollPet

	elseif gamePassName == "AutoHatch" then
		-- Auto-hatch handled by client with server validation
	end
end

function MonetizationService.GetPlayerBenefits(player: Player)
	local benefits = {
		VIP = MonetizationService.HasGamePass(player, "VIP"),
		LuckyBoost = MonetizationService.HasGamePass(player, "LuckyBoost"),
		AutoHatch = MonetizationService.HasGamePass(player, "AutoHatch"),
		SpeedBoost = MonetizationService.HasGamePass(player, "SpeedBoost"),
		ExtraSlots = MonetizationService.HasGamePass(player, "ExtraSlots"),
		CoinMultiplier = 1,
	}

	if benefits.VIP then
		benefits.CoinMultiplier = benefits.CoinMultiplier * 2
	end

	return benefits
end

-- ============================================================================
-- DEVELOPER PRODUCTS
-- ============================================================================

function MonetizationService.PromptProductPurchase(player: Player, productName: string)
	local product = GameConfig.DeveloperProducts[productName]
	if not product or product.Id == 0 then
		warn(string.format("[MonetizationService] Invalid product: %s", productName))
		return
	end

	-- Prompt purchase
	MarketplaceService:PromptProductPurchase(player, product.Id)
end

function MonetizationService.ProcessReceipt(receiptInfo)
	print(string.format("[MonetizationService] Processing receipt for player %d, product %d",
		receiptInfo.PlayerId, receiptInfo.ProductId))

	-- Find player
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		warn("[MonetizationService] Player not found for receipt")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find product
	local productData = nil
	local productName = nil
	for name, data in pairs(GameConfig.DeveloperProducts) do
		if data.Id == receiptInfo.ProductId then
			productData = data
			productName = name
			break
		end
	end

	if not productData then
		warn(string.format("[MonetizationService] Unknown product ID: %d", receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant product
	local success = MonetizationService.GrantProduct(player, productName, productData)
	if success then
		print(string.format("[MonetizationService] Granted %s to %s", productName, player.Name))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn(string.format("[MonetizationService] Failed to grant %s to %s", productName, player.Name))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService.GrantProduct(player: Player, productName: string, productData: {})
	if not MonetizationService.DataService then
		MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	end
	if not MonetizationService.PetService then
		MonetizationService.PetService = require(ServerScriptService.Services.PetService)
	end

	local playerData = MonetizationService.DataService.GetData(player)
	if not playerData then return false end

	-- Handle different product types
	if productName:match("^Coins_") then
		-- Coin purchase
		MonetizationService.DataService.AddCoins(player, productData.Amount)

		local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
		if notifyRemote then
			notifyRemote:FireClient(player,
				string.format("+%d coins!", productData.Amount),
				"Coin")
		end

		return true

	elseif productName:match("Egg_") then
		-- Egg pack purchase
		for i = 1, productData.Amount do
			MonetizationService.PetService.HatchEgg(player, productData.EggType)
		end

		local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
		if notifyRemote then
			notifyRemote:FireClient(player,
				string.format("Received %d %s eggs!", productData.Amount, productData.EggType),
				"Success")
		end

		return true

	elseif productName:match("Boost_") then
		-- Temporary boost purchase
		if not playerData.ActiveBoosts then
			playerData.ActiveBoosts = {}
		end

		local boostType = productName:match("^(%w+)Boost_")
		playerData.ActiveBoosts[boostType] = {
			ExpiresAt = os.time() + productData.Duration,
			Multiplier = productData.Multiplier,
		}

		local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowNotification")
		if notifyRemote then
			notifyRemote:FireClient(player,
				string.format("%dx %s boost active for 1 hour!", productData.Multiplier, boostType),
				"Success")
		end

		return true
	end

	return false
end

-- ============================================================================
-- BOOST MANAGEMENT
-- ============================================================================

function MonetizationService.GetActiveBoosts(player: Player)
	if not MonetizationService.DataService then
		MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = MonetizationService.DataService.GetData(player)
	if not playerData or not playerData.ActiveBoosts then
		return {}
	end

	-- Clean up expired boosts
	local now = os.time()
	for boostType, boostData in pairs(playerData.ActiveBoosts) do
		if boostData.ExpiresAt <= now then
			playerData.ActiveBoosts[boostType] = nil
			print(string.format("[MonetizationService] %s's %s boost expired", player.Name, boostType))
		end
	end

	return playerData.ActiveBoosts
end

function MonetizationService.GetCoinMultiplier(player: Player)
	local multiplier = 1

	-- Game pass multiplier
	if MonetizationService.HasGamePass(player, "VIP") then
		multiplier = multiplier * 2
	end

	-- Active boost multiplier
	local boosts = MonetizationService.GetActiveBoosts(player)
	if boosts.Coin then
		multiplier = multiplier * boosts.Coin.Multiplier
	end

	return multiplier
end

-- ============================================================================
-- ANALYTICS
-- ============================================================================

function MonetizationService.TrackRevenue(player: Player, productName: string, robux: number)
	-- In production, send to analytics service (Google Analytics, etc.)
	print(string.format("[MonetizationService] REVENUE: %s purchased %s for %d Robux",
		player.Name, productName, robux))

	-- Track in player data
	if not MonetizationService.DataService then
		MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = MonetizationService.DataService.GetData(player)
	if playerData then
		playerData.Stats.TotalSpent = (playerData.Stats.TotalSpent or 0) + robux
		playerData.Stats.TotalPurchases = (playerData.Stats.TotalPurchases or 0) + 1
	end
end

return MonetizationService
