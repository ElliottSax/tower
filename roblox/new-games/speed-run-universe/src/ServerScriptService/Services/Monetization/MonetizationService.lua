--[[
	MonetizationService.lua - Speed Run Universe
	Handles GamePass purchases, DevProduct purchases, receipt processing,
	and grants appropriate rewards.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}
MonetizationService.DataService = nil
MonetizationService.SecurityManager = nil
MonetizationService.CosmeticsService = nil

-- ============================================================================
-- INIT
-- ============================================================================
function MonetizationService.Init()
	MonetizationService.DataService = require(ServerScriptService.Services.DataService)
	MonetizationService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Shop data request
	re:WaitForChild("GetShopData").OnServerEvent:Connect(function(player)
		MonetizationService.SendShopData(player)
	end)

	-- GamePass purchase prompt
	re:WaitForChild("PurchaseGamePass").OnServerEvent:Connect(function(player, passName)
		if not MonetizationService.SecurityManager.CheckRateLimit(player, "PurchaseGamePass") then return end
		local cfg = GameConfig.GamePasses[passName]
		if cfg and cfg.Id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, cfg.Id)
		end
	end)

	-- DevProduct purchase prompt
	re:WaitForChild("PurchaseDevProduct").OnServerEvent:Connect(function(player, productName)
		if not MonetizationService.SecurityManager.CheckRateLimit(player, "PurchaseDevProduct") then return end
		local cfg = GameConfig.DevProducts[productName]
		if cfg and cfg.Id > 0 then
			MarketplaceService:PromptProductPurchase(player, cfg.Id)
		end
	end)

	-- Check existing game pass ownership on join
	Players.PlayerAdded:Connect(function(player)
		task.wait(3) -- Wait for data to load
		MonetizationService._CheckExistingPasses(player)
	end)

	-- Handle GamePass purchased mid-session
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if purchased then
			MonetizationService._GrantGamePass(player, gamePassId)
		end
	end)

	-- Handle DevProduct receipt processing
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return MonetizationService._ProcessReceipt(receiptInfo)
	end

	print("[MonetizationService] Initialized")
end

-- Deferred CosmeticsService access
function MonetizationService._EnsureCosmeticsService()
	if not MonetizationService.CosmeticsService then
		local ok, svc = pcall(function()
			return require(ServerScriptService.Services.CosmeticsService)
		end)
		if ok then MonetizationService.CosmeticsService = svc end
	end
end

-- ============================================================================
-- CHECK EXISTING PASSES
-- ============================================================================
function MonetizationService._CheckExistingPasses(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end

	data.GamePasses = data.GamePasses or {}

	for passName, cfg in pairs(GameConfig.GamePasses) do
		if cfg.Id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, cfg.Id)
			end)
			if success and owns then
				data.GamePasses[passName] = true
				MonetizationService._ApplyPassEffects(player, passName)
			end
		end
	end
end

-- ============================================================================
-- GRANT GAME PASS
-- ============================================================================
function MonetizationService._GrantGamePass(player, gamePassId)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end

	data.GamePasses = data.GamePasses or {}

	for passName, cfg in pairs(GameConfig.GamePasses) do
		if cfg.Id == gamePassId then
			data.GamePasses[passName] = true
			MonetizationService._ApplyPassEffects(player, passName)

			-- Notify player
			MonetizationService._Notify(player, "Thank you! " .. cfg.Name .. " activated!")
			print("[MonetizationService]", player.Name, "purchased:", cfg.Name)
			return
		end
	end
end

-- ============================================================================
-- APPLY PASS EFFECTS
-- ============================================================================
function MonetizationService._ApplyPassEffects(player, passName)
	local character = player.Character

	if passName == "SpeedBoost" then
		-- Apply speed multiplier
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				local baseMult = MonetizationService.DataService.GetSpeedMultiplier(player)
				humanoid.WalkSpeed = GameConfig.SpeedModifiers.Default * baseMult
			end
		end

	elseif passName == "VIP" then
		-- VIP: speed + name color + chat tag
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				local baseMult = MonetizationService.DataService.GetSpeedMultiplier(player)
				humanoid.WalkSpeed = GameConfig.SpeedModifiers.Default * baseMult
			end
		end

		-- Gold name color in leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			-- Add VIP indicator
			local vipVal = ls:FindFirstChild("VIP")
			if not vipVal then
				vipVal = Instance.new("StringValue")
				vipVal.Name = "VIP"
				vipVal.Value = "VIP"
				vipVal.Parent = ls
			end
		end

	elseif passName == "ExclusiveTrails" then
		-- Grant exclusive trails
		MonetizationService._EnsureCosmeticsService()
		if MonetizationService.CosmeticsService then
			for _, trailId in ipairs(GameConfig.GamePasses.ExclusiveTrails.UnlockedTrails) do
				MonetizationService.CosmeticsService.GrantTrail(player, trailId)
			end
		end

	elseif passName == "SkipWorld" then
		-- The SkipWorld pass unlocks one world; handled on client prompt
		-- Player selects which world to unlock
		MonetizationService._Notify(player, "World Skip Pass activated! Open the world select to use it.")
	end
end

-- ============================================================================
-- PROCESS DEV PRODUCT RECEIPT
-- ============================================================================
function MonetizationService._ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = MonetizationService.DataService.GetFullData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for productName, cfg in pairs(GameConfig.DevProducts) do
		if cfg.Id == receiptInfo.ProductId then
			-- Process based on product type
			if cfg.Amount then
				-- Coin purchase
				MonetizationService.DataService.AddCoins(player, cfg.Amount)
				MonetizationService._Notify(player, "+" .. cfg.Amount .. " coins!")

			elseif productName == "SkipWorldUnlock" then
				-- Find next locked world and unlock it
				local nextWorld = MonetizationService._FindNextLockedWorld(player)
				if nextWorld then
					table.insert(data.UnlockedWorlds, nextWorld.Id)
					MonetizationService._Notify(player, "Unlocked " .. nextWorld.Name .. "!")

					-- Notify client of unlock
					local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
					if re then
						local unlock = re:FindFirstChild("WorldUnlocked")
						if unlock then
							unlock:FireClient(player, {
								WorldId = nextWorld.Id,
								WorldName = nextWorld.Name,
							})
						end
					end
				else
					-- All worlds already unlocked - refund as coins
					MonetizationService.DataService.AddCoins(player, 5000)
					MonetizationService._Notify(player, "All worlds unlocked! +5000 coins instead.")
				end

			elseif productName == "ReviveBoost" then
				-- Instant revive with speed boost
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.Health = humanoid.MaxHealth

						-- Temp speed boost
						local baseMult = MonetizationService.DataService.GetSpeedMultiplier(player)
						local boostedSpeed = GameConfig.SpeedModifiers.Default * baseMult * cfg.SpeedMultiplier
						humanoid.WalkSpeed = boostedSpeed

						task.delay(cfg.BoostDuration, function()
							if humanoid and humanoid.Parent then
								humanoid.WalkSpeed = GameConfig.SpeedModifiers.Default * baseMult
							end
						end)
					end
				end
				MonetizationService._Notify(player, "Revived with speed boost!")
			end

			print("[MonetizationService]", player.Name, "purchased product:", cfg.Name)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ============================================================================
-- SHOP DATA
-- ============================================================================
function MonetizationService.SendShopData(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end

	local shop = {
		GamePasses = {},
		DevProducts = {},
		OwnedPasses = data.GamePasses or {},
		PlayerCoins = data.Coins,
	}

	for name, cfg in pairs(GameConfig.GamePasses) do
		shop.GamePasses[name] = {
			Name = cfg.Name,
			Description = cfg.Description,
			Price = cfg.Price,
			Owned = data.GamePasses and data.GamePasses[name] or false,
		}
	end

	for name, cfg in pairs(GameConfig.DevProducts) do
		shop.DevProducts[name] = {
			Name = cfg.Name,
			Description = cfg.Description or "",
			Price = cfg.Price,
		}
	end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local shopData = re:FindFirstChild("ShopData")
		if shopData then
			shopData:FireClient(player, shop)
		end
	end
end

-- ============================================================================
-- HELPERS
-- ============================================================================
function MonetizationService._FindNextLockedWorld(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return nil end

	for _, world in ipairs(GameConfig.Worlds) do
		local unlocked = false
		for _, w in ipairs(data.UnlockedWorlds) do
			if w == world.Id then unlocked = true; break end
		end
		if not unlocked then
			return world
		end
	end

	return nil -- All worlds unlocked
end

function MonetizationService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return MonetizationService
