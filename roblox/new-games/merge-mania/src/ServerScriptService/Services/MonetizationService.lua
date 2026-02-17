--[[
	MonetizationService.lua - Merge Mania
	Handles Game Passes and Developer Products (Robux purchases)

	Game Passes: Auto-Merge, 2x Earnings, Grid Expansion, Premium Generators,
	             Lucky Merger, VIP
	Dev Products: Coin packs, Instant Merge, Clear Grid, Lucky Boost,
	              Speed Boost, Skip Tier Merge
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}
MonetizationService.DataService = nil
MonetizationService.MergeService = nil
MonetizationService.EarningsService = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MonetizationService.Init()
	print("[MonetizationService] Initializing...")

	MonetizationService.DataService = require(ServerScriptService.Services.DataService)

	MonetizationService.SetupGamePassHandlers()
	MonetizationService.SetupDevProductHandlers()
	MonetizationService.SetupRemotes()

	print("[MonetizationService] Initialized")
end

function MonetizationService.LateInit()
	MonetizationService.MergeService = require(ServerScriptService.Services.MergeService)
	MonetizationService.EarningsService = require(ServerScriptService.Services.EarningsService)
end

function MonetizationService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetShopData").OnServerEvent:Connect(function(player)
		MonetizationService.SendShopData(player)
	end)

	remoteEvents:WaitForChild("PurchaseGamePass").OnServerEvent:Connect(function(player, passName)
		if type(passName) ~= "string" or #passName > 64 then return end
		MonetizationService.PromptGamePass(player, passName)
	end)

	remoteEvents:WaitForChild("PurchaseDevProduct").OnServerEvent:Connect(function(player, productName)
		if type(productName) ~= "string" or #productName > 64 then return end
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

	-- Handle game pass purchase completion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then return end

		local data = MonetizationService.DataService.GetFullData(player)
		if not data then return end

		data.GamePasses = data.GamePasses or {}

		for passName, passConfig in pairs(GameConfig.GamePasses) do
			if passConfig.Id == gamePassId then
				data.GamePasses[passName] = true

				-- Apply immediate effects
				MonetizationService.ApplyGamePassEffects(player, passName)

				-- Notify
				MonetizationService.Notify(player,
					"Purchased " .. passConfig.Name .. "! " .. passConfig.Description,
					GameConfig.Theme.SuccessColor
				)

				print("[MonetizationService]", player.Name, "purchased game pass:", passName)
				break
			end
		end
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

	-- Apply effects for owned passes
	for passName, owned in pairs(data.GamePasses) do
		if owned then
			MonetizationService.ApplyGamePassEffects(player, passName)
		end
	end
end

function MonetizationService.ApplyGamePassEffects(player, passName)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end

	if passName == "GridExpansion" then
		-- Expand grid to 8x8
		data.GridRows = GameConfig.Grid.ExpandedRows
		data.GridCols = GameConfig.Grid.ExpandedCols

		-- Sync new grid size to client
		if MonetizationService.MergeService then
			MonetizationService.MergeService.SyncGrid(player)
		end
	end

	-- Recalculate earnings for any pass that affects income
	if passName == "DoubleEarnings" or passName == "VIP" or passName == "LuckyMerger" then
		if MonetizationService.EarningsService then
			MonetizationService.EarningsService.RecalculateEarnings(player)
		end
	end
end

function MonetizationService.PromptGamePass(player, passName)
	local passConfig = GameConfig.GamePasses[passName]
	if not passConfig or passConfig.Id <= 0 then return end

	pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, passConfig.Id)
	end)
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
					print("[MonetizationService]", player.Name, "purchased dev product:", productName)
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

	-- === Coin Packs ===
	if productConfig.Amount then
		MonetizationService.DataService.AddCoins(player, productConfig.Amount)
		MonetizationService.Notify(player,
			"Received " .. GameConfig.FormatNumber(productConfig.Amount) .. " coins!",
			GameConfig.Theme.SuccessColor
		)
		return true
	end

	-- === Instant Merge All ===
	if productName == "InstantMerge" then
		if MonetizationService.MergeService then
			-- Keep merging until no more merges possible
			local mergeCount = 0
			for _ = 1, 100 do -- Safety limit
				local merged = MonetizationService.MergeService.AutoMergeOnce(player)
				if not merged then break end
				mergeCount = mergeCount + 1
			end
			MonetizationService.Notify(player,
				"Instant Merged " .. mergeCount .. " pairs!",
				GameConfig.Theme.SuccessColor
			)
		end
		return true
	end

	-- === Clear Grid ===
	if productName == "ClearGrid" then
		if MonetizationService.MergeService then
			MonetizationService.MergeService.ClearGrid(player, true) -- collect coins
			MonetizationService.Notify(player,
				"Grid cleared! Coins collected!",
				GameConfig.Theme.SuccessColor
			)
		end
		return true
	end

	-- === Lucky Boost (30 min) ===
	if productName == "LuckyBoost30" then
		MonetizationService.DataService.AddBoost(player, "LuckyBoost", 1800) -- 30 minutes
		MonetizationService.Notify(player,
			"Lucky Boost activated for 30 minutes! 3x golden merge chance!",
			GameConfig.Theme.GoldenColor
		)
		return true
	end

	-- === Speed Boost (30 min) ===
	if productName == "SpeedBoost30" then
		MonetizationService.DataService.AddBoost(player, "SpeedBoost", 1800) -- 30 minutes
		MonetizationService.Notify(player,
			"Speed Boost activated for 30 minutes! 2x generator speed!",
			GameConfig.Theme.AccentColor
		)
		return true
	end

	-- === Skip Tier Merge ===
	if productName == "SkipTierMerge" then
		MonetizationService.DataService.AddBoost(player, "SkipTierMerge", 86400) -- 24h (one-time use)
		MonetizationService.Notify(player,
			"Skip Tier Merge ready! Your next merge jumps 2 tiers!",
			GameConfig.Theme.GoldenColor
		)
		return true
	end

	return false
end

function MonetizationService.PromptDevProduct(player, productName)
	local productConfig = GameConfig.DevProducts[productName]
	if not productConfig or productConfig.Id <= 0 then return end

	pcall(function()
		MarketplaceService:PromptProductPurchase(player, productConfig.Id)
	end)
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
			Amount = config.Amount,
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

-- ============================================================================
-- AUTO MERGE LOOP (for game pass holders)
-- ============================================================================

function MonetizationService.StartAutoMergeLoop()
	task.spawn(function()
		while true do
			task.wait(5) -- Auto merge every 5 seconds
			for _, player in ipairs(Players:GetPlayers()) do
				local data = MonetizationService.DataService.GetFullData(player)
				if data and data.GamePasses and data.GamePasses["AutoMerge"] then
					if MonetizationService.MergeService then
						MonetizationService.MergeService.AutoMergeOnce(player)
					end
				end
			end
		end
	end)
end

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

function MonetizationService.Notify(player, text, color)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Text = text, Color = color })
		end
	end
end

return MonetizationService
