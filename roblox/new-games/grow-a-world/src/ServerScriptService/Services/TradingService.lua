--[[
	TradingService.lua - Grow a World
	Player-to-player seed trading (key viral mechanic)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TradingService = {}
TradingService.DataService = nil
TradingService.ActiveTrades = {} -- [TradeId] = { Player1, Player2, Offers1, Offers2, Status }
TradingService.TradeCounter = 0

function TradingService.Init()
	print("[TradingService] Initializing...")
	TradingService.DataService = require(ServerScriptService.Services.DataService)
	TradingService.SetupRemotes()
	print("[TradingService] Initialized")
end

function TradingService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("RequestTrade").OnServerEvent:Connect(function(player, targetPlayerName)
		TradingService.RequestTrade(player, targetPlayerName)
	end)

	remoteEvents:WaitForChild("AcceptTrade").OnServerEvent:Connect(function(player, tradeId)
		TradingService.AcceptTrade(player, tradeId)
	end)

	remoteEvents:WaitForChild("DeclineTrade").OnServerEvent:Connect(function(player, tradeId)
		TradingService.DeclineTrade(player, tradeId)
	end)

	remoteEvents:WaitForChild("AddTradeItem").OnServerEvent:Connect(function(player, tradeId, seedName, quantity)
		TradingService.AddTradeItem(player, tradeId, seedName, quantity)
	end)

	remoteEvents:WaitForChild("ConfirmTrade").OnServerEvent:Connect(function(player, tradeId)
		TradingService.ConfirmTrade(player, tradeId)
	end)
end

function TradingService.RequestTrade(player, targetPlayerName)
	if not GameConfig.Trading.Enabled then return false, "Trading disabled" end

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then return false, "Player not found" end
	if targetPlayer == player then return false, "Cannot trade with yourself" end

	-- Create trade session
	TradingService.TradeCounter = TradingService.TradeCounter + 1
	local tradeId = "trade_" .. TradingService.TradeCounter

	TradingService.ActiveTrades[tradeId] = {
		Player1 = player,
		Player2 = targetPlayer,
		Offers1 = {},
		Offers2 = {},
		Confirmed1 = false,
		Confirmed2 = false,
		Status = "pending",
		CreatedAt = os.time(),
	}

	-- Notify target player
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tradeRequestRemote = remoteEvents:FindFirstChild("TradeRequest")
		if tradeRequestRemote then
			tradeRequestRemote:FireClient(targetPlayer, tradeId, player.Name)
		end
	end

	-- Auto-expire after 60 seconds
	task.delay(60, function()
		local trade = TradingService.ActiveTrades[tradeId]
		if trade and trade.Status == "pending" then
			TradingService.CancelTrade(tradeId, "expired")
		end
	end)

	return true, tradeId
end

function TradingService.AcceptTrade(player, tradeId)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade or trade.Status ~= "pending" then return false end
	if trade.Player2 ~= player then return false end

	trade.Status = "active"

	-- Notify both players
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tradeActiveRemote = remoteEvents:FindFirstChild("TradeActive")
		if tradeActiveRemote then
			tradeActiveRemote:FireClient(trade.Player1, tradeId)
			tradeActiveRemote:FireClient(trade.Player2, tradeId)
		end
	end

	return true
end

function TradingService.DeclineTrade(player, tradeId)
	TradingService.CancelTrade(tradeId, "declined")
end

function TradingService.AddTradeItem(player, tradeId, seedName, quantity)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade or trade.Status ~= "active" then return false end

	quantity = math.clamp(quantity or 1, 1, GameConfig.Trading.MaxItemsPerTrade)

	-- Determine which side
	local offers
	if trade.Player1 == player then
		offers = trade.Offers1
	elseif trade.Player2 == player then
		offers = trade.Offers2
	else
		return false
	end

	-- Check player has seeds
	local data = TradingService.DataService.GetFullData(player)
	if not data or not data.SeedInventory then return false end

	local hasSeed = false
	for _, seed in ipairs(data.SeedInventory) do
		if seed.Name == seedName and seed.Count >= quantity then
			hasSeed = true
			break
		end
	end
	if not hasSeed then return false, "Not enough seeds" end

	-- Add to offers (replace if already offered same seed)
	for i, offer in ipairs(offers) do
		if offer.Name == seedName then
			offers[i].Quantity = quantity
			return true
		end
	end
	table.insert(offers, { Name = seedName, Quantity = quantity })

	-- Reset confirmations
	trade.Confirmed1 = false
	trade.Confirmed2 = false

	-- Notify both players of updated offers
	TradingService.SyncTradeState(tradeId)
	return true
end

function TradingService.ConfirmTrade(player, tradeId)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade or trade.Status ~= "active" then return false end

	if trade.Player1 == player then
		trade.Confirmed1 = true
	elseif trade.Player2 == player then
		trade.Confirmed2 = true
	else
		return false
	end

	-- If both confirmed, execute trade
	if trade.Confirmed1 and trade.Confirmed2 then
		TradingService.ExecuteTrade(tradeId)
	end

	return true
end

function TradingService.ExecuteTrade(tradeId)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade then return end

	local GardenService = require(ServerScriptService.Services.GardenService)

	-- Remove items from Player1, give to Player2
	for _, offer in ipairs(trade.Offers1) do
		GardenService.RemoveSeedFromInventory(trade.Player1, offer.Name, offer.Quantity)
		local seedConfig = GardenService.FindSeedConfig(offer.Name)
		if seedConfig then
			GardenService.AddSeedToInventory(trade.Player2, offer.Name, seedConfig.Rarity, seedConfig.Biome, offer.Quantity)
		end
	end

	-- Remove items from Player2, give to Player1
	for _, offer in ipairs(trade.Offers2) do
		GardenService.RemoveSeedFromInventory(trade.Player2, offer.Name, offer.Quantity)
		local seedConfig = GardenService.FindSeedConfig(offer.Name)
		if seedConfig then
			GardenService.AddSeedToInventory(trade.Player1, offer.Name, seedConfig.Rarity, seedConfig.Biome, offer.Quantity)
		end
	end

	-- Track stats
	local data1 = TradingService.DataService.GetFullData(trade.Player1)
	local data2 = TradingService.DataService.GetFullData(trade.Player2)
	if data1 then data1.TradesCompleted = (data1.TradesCompleted or 0) + 1 end
	if data2 then data2.TradesCompleted = (data2.TradesCompleted or 0) + 1 end

	-- Notify both players
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tradeCompleteRemote = remoteEvents:FindFirstChild("TradeComplete")
		if tradeCompleteRemote then
			tradeCompleteRemote:FireClient(trade.Player1, tradeId, "success")
			tradeCompleteRemote:FireClient(trade.Player2, tradeId, "success")
		end
	end

	-- Cleanup
	TradingService.ActiveTrades[tradeId] = nil
	print("[TradingService] Trade completed:", trade.Player1.Name, "<->", trade.Player2.Name)
end

function TradingService.CancelTrade(tradeId, reason)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tradeCancelRemote = remoteEvents:FindFirstChild("TradeCancelled")
		if tradeCancelRemote then
			if trade.Player1 and trade.Player1:IsDescendantOf(Players) then
				tradeCancelRemote:FireClient(trade.Player1, tradeId, reason)
			end
			if trade.Player2 and trade.Player2:IsDescendantOf(Players) then
				tradeCancelRemote:FireClient(trade.Player2, tradeId, reason)
			end
		end
	end

	TradingService.ActiveTrades[tradeId] = nil
end

function TradingService.SyncTradeState(tradeId)
	local trade = TradingService.ActiveTrades[tradeId]
	if not trade then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tradeSyncRemote = remoteEvents:FindFirstChild("TradeSync")
		if tradeSyncRemote then
			local state = {
				Offers1 = trade.Offers1,
				Offers2 = trade.Offers2,
				Confirmed1 = trade.Confirmed1,
				Confirmed2 = trade.Confirmed2,
			}
			tradeSyncRemote:FireClient(trade.Player1, tradeId, state)
			tradeSyncRemote:FireClient(trade.Player2, tradeId, state)
		end
	end
end

return TradingService
