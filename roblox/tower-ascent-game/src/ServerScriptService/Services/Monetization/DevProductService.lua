--[[
	DevProductService.lua
	Manages Developer Products (consumable purchases) for Tower Ascent

	Developer Products (can be purchased multiple times):
	- Coin Packs - Buy coins with Robux
	- XP Boost - Temporary XP boost
	- Respawn Skip - Skip death penalty once

	Week 14: Developer Products monetization
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DevProductService = {}
DevProductService.IsInitialized = false
DevProductService.PurchaseRateLimits = {}
DevProductService.PendingPurchases = {} -- Track purchases being processed

-- ============================================================================
-- DEVELOPER PRODUCT DEFINITIONS
-- ============================================================================

local DEV_PRODUCTS = {
	-- Coin Packs
	CoinPack_Small = {
		Id = 0, -- PLACEHOLDER: Set after creating on Roblox
		Name = "500 Coins",
		Description = "Get 500 coins instantly",
		Price = 49, -- Robux
		Type = "Coins",
		Amount = 500,
	},

	CoinPack_Medium = {
		Id = 0, -- PLACEHOLDER
		Name = "1,500 Coins (+50% Bonus)",
		Description = "Get 1,500 coins - 50% bonus value!",
		Price = 99, -- Robux
		Type = "Coins",
		Amount = 1500,
	},

	CoinPack_Large = {
		Id = 0, -- PLACEHOLDER
		Name = "4,000 Coins (+100% Bonus)",
		Description = "Get 4,000 coins - Best value!",
		Price = 199, -- Robux
		Type = "Coins",
		Amount = 4000,
	},

	CoinPack_Mega = {
		Id = 0, -- PLACEHOLDER
		Name = "10,000 Coins (+150% Bonus)",
		Description = "Get 10,000 coins - Mega pack!",
		Price = 399, -- Robux
		Type = "Coins",
		Amount = 10000,
	},

	-- Boosts
	XPBoost_30min = {
		Id = 0, -- PLACEHOLDER
		Name = "30 Min XP Boost",
		Description = "2x Battle Pass XP for 30 minutes",
		Price = 29, -- Robux
		Type = "XPBoost",
		Duration = 1800, -- 30 minutes in seconds
		Multiplier = 2,
	},

	XPBoost_1hour = {
		Id = 0, -- PLACEHOLDER
		Name = "1 Hour XP Boost",
		Description = "2x Battle Pass XP for 1 hour",
		Price = 49, -- Robux
		Type = "XPBoost",
		Duration = 3600, -- 1 hour in seconds
		Multiplier = 2,
	},

	XPBoost_3hour = {
		Id = 0, -- PLACEHOLDER
		Name = "3 Hour XP Boost",
		Description = "2x Battle Pass XP for 3 hours - Best value!",
		Price = 99, -- Robux
		Type = "XPBoost",
		Duration = 10800, -- 3 hours in seconds
		Multiplier = 2,
	},

	-- Utility
	RespawnSkip = {
		Id = 0, -- PLACEHOLDER
		Name = "Respawn Skip",
		Description = "Skip one death - respawn at current position",
		Price = 19, -- Robux
		Type = "RespawnSkip",
		Uses = 1,
	},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DevProductService.Init()
	print("[DevProductService] Initializing...")

	-- Create RemoteEvents
	DevProductService.CreateRemoteEvents()

	-- Setup purchase processor
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return DevProductService.ProcessReceipt(receiptInfo)
	end

	-- Connect player events
	Players.PlayerRemoving:Connect(function(player)
		DevProductService.PurchaseRateLimits[player.UserId] = nil
	end)

	-- Cleanup stale pending purchases (prevents memory leak)
	task.spawn(function()
		while true do
			task.wait(300) -- Every 5 minutes
			local now = tick()
			local cleanedCount = 0

			for key, timestamp in pairs(DevProductService.PendingPurchases) do
				if type(timestamp) == "number" and (now - timestamp) > 300 then
					DevProductService.PendingPurchases[key] = nil
					cleanedCount = cleanedCount + 1
				end
			end

			if cleanedCount > 0 then
				print(string.format("[DevProductService] Cleaned up %d stale pending purchases", cleanedCount))
			end
		end
	end)

	DevProductService.IsInitialized = true
	print("[DevProductService] Initialized with " .. DevProductService.GetConfiguredProductCount() .. " configured products")
end

function DevProductService.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Prompt Developer Product Purchase
	if not remoteFolder:FindFirstChild("PromptDevProductPurchase") then
		local purchaseEvent = Instance.new("RemoteEvent")
		purchaseEvent.Name = "PromptDevProductPurchase"
		purchaseEvent.Parent = remoteFolder

		purchaseEvent.OnServerEvent:Connect(function(player, productName)
			DevProductService.PromptPurchase(player, productName)
		end)
	end

	-- Get Developer Product Data (RemoteFunction)
	if not remoteFolder:FindFirstChild("GetDevProductData") then
		local dataFunction = Instance.new("RemoteFunction")
		dataFunction.Name = "GetDevProductData"
		dataFunction.Parent = remoteFolder

		dataFunction.OnServerInvoke = function(player)
			return DevProductService.GetProductList()
		end
	end
end

function DevProductService.GetConfiguredProductCount(): number
	local count = 0
	for _, product in pairs(DEV_PRODUCTS) do
		if product.Id > 0 then
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- PURCHASE PROCESSING
-- ============================================================================

function DevProductService.ProcessReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, but we should still try to grant
		-- Return NotProcessedYet so Roblox retries when they rejoin
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find which product was purchased
	local productName = nil
	local productData = nil

	for name, data in pairs(DEV_PRODUCTS) do
		if data.Id == receiptInfo.ProductId then
			productName = name
			productData = data
			break
		end
	end

	if not productData then
		warn(string.format("[DevProductService] Unknown product ID: %d", receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Prevent duplicate processing (store timestamp for cleanup)
	local receiptKey = receiptInfo.PurchaseId
	local now = tick()

	if DevProductService.PendingPurchases[receiptKey] then
		local timestamp = DevProductService.PendingPurchases[receiptKey]
		-- If stuck for more than 60 seconds, allow retry
		if type(timestamp) == "number" and (now - timestamp) < 60 then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	DevProductService.PendingPurchases[receiptKey] = now

	-- Process the purchase
	local success = DevProductService.GrantProduct(player, productName, productData)

	-- Cleanup pending
	DevProductService.PendingPurchases[receiptKey] = nil

	if success then
		print(string.format("[DevProductService] %s purchased %s", player.Name, productData.Name))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn(string.format("[DevProductService] Failed to grant %s to %s", productData.Name, player.Name))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function DevProductService.GrantProduct(player: Player, productName: string, productData: {}): boolean
	local productType = productData.Type

	if productType == "Coins" then
		-- Grant coins
		local success, CoinService = pcall(function()
			return require(script.Parent.Parent.CoinService)
		end)

		if success and CoinService then
			local granted = CoinService.AddCoins(player, productData.Amount, "DevProduct:" .. productName)
			return granted
		end

	elseif productType == "XPBoost" then
		-- Grant temporary XP boost
		local currentBoostEnd = player:GetAttribute("XPBoostEnd") or 0
		local now = os.time()
		local newEnd = math.max(now, currentBoostEnd) + productData.Duration

		player:SetAttribute("XPBoostEnd", newEnd)
		player:SetAttribute("XPBoostMultiplier", productData.Multiplier)

		print(string.format("[DevProductService] %s has XP boost until %s",
			player.Name, os.date("%X", newEnd)))
		return true

	elseif productType == "RespawnSkip" then
		-- Grant respawn skip uses
		local currentSkips = player:GetAttribute("RespawnSkips") or 0
		player:SetAttribute("RespawnSkips", currentSkips + productData.Uses)

		print(string.format("[DevProductService] %s now has %d respawn skips",
			player.Name, currentSkips + productData.Uses))
		return true
	end

	return false
end

-- ============================================================================
-- PURCHASE PROMPTING
-- ============================================================================

function DevProductService.PromptPurchase(player: Player, productName: string)
	local productData = DEV_PRODUCTS[productName]
	if not productData then
		warn(string.format("[DevProductService] Unknown product: %s", productName))
		return
	end

	if productData.Id == 0 then
		warn(string.format("[DevProductService] Product not configured: %s", productName))
		return
	end

	-- Rate limiting (3 second cooldown)
	local now = tick()
	local lastPrompt = DevProductService.PurchaseRateLimits[player.UserId] or 0
	if now - lastPrompt < 3 then
		return
	end
	DevProductService.PurchaseRateLimits[player.UserId] = now

	-- Prompt purchase
	task.spawn(function()
		local success, err = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productData.Id)
		end)
		if not success then
			warn(string.format("[DevProductService] Purchase prompt failed: %s", tostring(err)))
		end
	end)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function DevProductService.GetProductList(): {}
	local productList = {}

	for productName, productData in pairs(DEV_PRODUCTS) do
		productList[productName] = {
			Name = productData.Name,
			Description = productData.Description,
			Price = productData.Price,
			Type = productData.Type,
			Amount = productData.Amount,
			Duration = productData.Duration,
			Configured = productData.Id > 0,
		}
	end

	return productList
end

function DevProductService.HasActiveXPBoost(player: Player): boolean
	local boostEnd = player:GetAttribute("XPBoostEnd") or 0
	return os.time() < boostEnd
end

function DevProductService.GetXPBoostMultiplier(player: Player): number
	if DevProductService.HasActiveXPBoost(player) then
		return player:GetAttribute("XPBoostMultiplier") or 1
	end
	return 1
end

function DevProductService.UseRespawnSkip(player: Player): boolean
	local skips = player:GetAttribute("RespawnSkips") or 0
	if skips > 0 then
		player:SetAttribute("RespawnSkips", skips - 1)
		print(string.format("[DevProductService] %s used respawn skip (%d remaining)",
			player.Name, skips - 1))
		return true
	end
	return false
end

function DevProductService.GetRespawnSkips(player: Player): number
	return player:GetAttribute("RespawnSkips") or 0
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function DevProductService.AdminGrantProduct(player: Player, productName: string)
	local productData = DEV_PRODUCTS[productName]
	if not productData then
		warn("[DevProductService] Unknown product: " .. productName)
		return false
	end

	local success = DevProductService.GrantProduct(player, productName, productData)
	if success then
		print(string.format("[DevProductService] ADMIN: Granted %s to %s", productData.Name, player.Name))
	end
	return success
end

function DevProductService.DebugPrint()
	print("=== DEVELOPER PRODUCT SERVICE STATUS ===")

	print("\nCoin Packs:")
	for productName, productData in pairs(DEV_PRODUCTS) do
		if productData.Type == "Coins" then
			print(string.format("  %s: %d coins for %d R$ (ID: %d)",
				productData.Name, productData.Amount, productData.Price, productData.Id))
		end
	end

	print("\nXP Boosts:")
	for productName, productData in pairs(DEV_PRODUCTS) do
		if productData.Type == "XPBoost" then
			print(string.format("  %s: %dx for %d seconds, %d R$ (ID: %d)",
				productData.Name, productData.Multiplier, productData.Duration, productData.Price, productData.Id))
		end
	end

	print("\nUtility:")
	for productName, productData in pairs(DEV_PRODUCTS) do
		if productData.Type == "RespawnSkip" then
			print(string.format("  %s: %d uses for %d R$ (ID: %d)",
				productData.Name, productData.Uses, productData.Price, productData.Id))
		end
	end

	print("\nActive Player Boosts:")
	for _, player in ipairs(Players:GetPlayers()) do
		local hasBoost = DevProductService.HasActiveXPBoost(player)
		local skips = DevProductService.GetRespawnSkips(player)
		if hasBoost or skips > 0 then
			print(string.format("  %s: XP Boost: %s, Skips: %d",
				player.Name, hasBoost and "Active" or "None", skips))
		end
	end
	print("=========================================")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return DevProductService
