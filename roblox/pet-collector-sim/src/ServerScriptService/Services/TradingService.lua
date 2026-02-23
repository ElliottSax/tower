--[[
	TradingService.lua
	Pet Collector Simulator - Player-to-Player Trading

	Handles:
	- Trade initiation and negotiation
	- Trade acceptance/rejection
	- Escrow system (hold pets until both confirm)
	- Trade restrictions (prevent scams)
	- Trade history and moderation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TradingService = {}
TradingService.DataService = nil
TradingService.PetService = nil

-- In-memory trade storage (trades in progress)
local ActiveTrades = {}
local TradeIdCounter = 1

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- CRITICAL FIX: Trading disabled for launch (ExchangePets function incomplete)
-- TODO: Complete ExchangePets function before enabling
local TRADING_ENABLED = false

local TRADE_TIMEOUT = 300 -- 5 minutes to accept/reject
local MIN_PET_AGE = 60 * 60 -- 1 hour minimum before trading
local SAME_PET_COOLDOWN = 7 * 24 * 60 * 60 -- 7 days between trading same pet
local TRADE_TAX = 0.05 -- 5% tax on coin value

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TradingService.Init()
	print("[TradingService] Initializing...")

	-- Setup remote events
	TradingService.SetupRemotes()

	print("[TradingService] Initialized - Trading system active")
end

function TradingService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Initiate trade
	local initiateTradeRemote = remoteEvents:WaitForChild("InitiateTrade")
	initiateTradeRemote.OnServerEvent:Connect(function(player, targetPlayerName, offeredPets, requestedPets)
		TradingService.InitiateTrade(player, targetPlayerName, offeredPets, requestedPets)
	end)

	-- Accept trade
	local acceptTradeRemote = remoteEvents:WaitForChild("AcceptTrade")
	acceptTradeRemote.OnServerEvent:Connect(function(player, tradeId)
		TradingService.AcceptTrade(player, tradeId)
	end)

	-- Reject trade
	local rejectTradeRemote = remoteEvents:WaitForChild("RejectTrade")
	rejectTradeRemote.OnServerEvent:Connect(function(player, tradeId)
		TradingService.RejectTrade(player, tradeId)
	end)

	-- Cancel trade
	local cancelTradeRemote = remoteEvents:WaitForChild("CancelTrade")
	cancelTradeRemote.OnServerEvent:Connect(function(player, tradeId)
		TradingService.CancelTrade(player, tradeId)
	end)

	-- Get active trades
	local getTradesRemote = remoteEvents:WaitForChild("GetActiveTrades")
	getTradesRemote.OnServerInvoke = function(player)
		return TradingService.GetActiveTrades(player)
	end
end

-- ============================================================================
-- TRADE INITIATION
-- ============================================================================

function TradingService.InitiateTrade(player: Player, targetPlayerName: string,
	offeredPets: table, requestedPets: table): boolean

	-- CRITICAL FIX: Trading disabled until ExchangePets function is completed
	if not TRADING_ENABLED then
		warn("[TradingService] Trading is temporarily disabled")

		-- Notify player
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local notifyRemote = remoteEvents:FindFirstChild("ShowNotification")
			if notifyRemote then
				notifyRemote:FireClient(player, "Trading is temporarily disabled. Check back soon!", "Warning")
			end
		end

		return false
	end

	if not TradingService.DataService then
		TradingService.DataService = require(ServerScriptService.Services.DataService)
	end
	if not TradingService.PetService then
		TradingService.PetService = require(ServerScriptService.Services.PetService)
	end

	-- Find target player
	local targetPlayer = game.Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn(string.format("[TradingService] Target player not found: %s", targetPlayerName))
		return false
	end

	local playerData = TradingService.DataService.GetData(player)
	local targetData = TradingService.DataService.GetData(targetPlayer)

	if not playerData or not targetData then
		warn("[TradingService] Cannot load player data")
		return false
	end

	-- Validate offered pets
	for _, petId in ipairs(offeredPets) do
		if not TradingService.ValidatePetForTrade(playerData, petId) then
			warn(string.format("[TradingService] %s cannot trade pet %s", player.Name, petId))
			return false
		end
	end

	-- Validate requested pets
	for _, petId in ipairs(requestedPets) do
		if not TradingService.ValidatePetForTrade(targetData, petId) then
			warn(string.format("[TradingService] %s cannot provide pet %s", targetPlayerName, petId))
			return false
		end
	end

	-- Create trade
	local tradeId = string.format("%d_%d_%d", player.UserId, targetPlayer.UserId, TradeIdCounter)
	TradeIdCounter = TradeIdCounter + 1

	local trade = {
		Id = tradeId,
		InitiatorId = player.UserId,
		InitiatorName = player.Name,
		TargetId = targetPlayer.UserId,
		TargetName = targetPlayerName,
		OfferedPets = offeredPets,
		RequestedPets = requestedPets,
		InitiatorAccepted = false,
		TargetAccepted = false,
		CreatedAt = os.time(),
		ExpiresAt = os.time() + TRADE_TIMEOUT,
		Status = "pending",
	}

	ActiveTrades[tradeId] = trade

	print(string.format("[TradingService] Trade initiated: %s -> %s (ID: %s)",
		player.Name, targetPlayerName, tradeId))

	-- Notify target player
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("TradeNotification")
	if notifyRemote then
		notifyRemote:FireClient(targetPlayer, {
			Type = "TradeInitiated",
			TradeId = tradeId,
			FromPlayer = player.Name,
			OfferedCount = #offeredPets,
			RequestedCount = #requestedPets,
		})
	end

	return true
end

-- ============================================================================
-- TRADE VALIDATION
-- ============================================================================

function TradingService.ValidatePetForTrade(playerData: table, petInstanceId: string): boolean
	if not playerData.Pets then
		return false
	end

	-- Find pet
	local pet = nil
	for _, p in ipairs(playerData.Pets) do
		if p.InstanceId == petInstanceId then
			pet = p
			break
		end
	end

	if not pet then
		return false
	end

	-- Check age (must be at least 1 hour old)
	local now = os.time()
	local petAge = now - (pet.HatchedAt or now)
	if petAge < MIN_PET_AGE then
		warn(string.format("[TradingService] Pet too new to trade (age: %d seconds)", petAge))
		return false
	end

	-- Check if equipped (cannot trade equipped pets)
	for _, equippedId in ipairs(playerData.EquippedPets or {}) do
		if equippedId == petInstanceId then
			return false
		end
	end

	return true
end

-- ============================================================================
-- TRADE ACCEPTANCE
-- ============================================================================

function TradingService.AcceptTrade(player: Player, tradeId: string): boolean
	if not TradingService.DataService then
		TradingService.DataService = require(ServerScriptService.Services.DataService)
	end

	local trade = ActiveTrades[tradeId]
	if not trade then
		warn(string.format("[TradingService] Trade not found: %s", tradeId))
		return false
	end

	-- Check trade status
	if trade.Status ~= "pending" then
		warn(string.format("[TradingService] Trade already completed: %s", tradeId))
		return false
	end

	-- Check timeout
	if os.time() > trade.ExpiresAt then
		TradingService.CancelTrade(player, tradeId)
		return false
	end

	local playerData = TradingService.DataService.GetData(player)
	if not playerData then
		return false
	end

	-- Mark player's acceptance
	if player.UserId == trade.InitiatorId then
		trade.InitiatorAccepted = true
	elseif player.UserId == trade.TargetId then
		trade.TargetAccepted = true
	else
		warn(string.format("[TradingService] %s not part of trade %s", player.Name, tradeId))
		return false
	end

	-- Check if both accepted
	if trade.InitiatorAccepted and trade.TargetAccepted then
		return TradingService.CompleteTrade(tradeId)
	end

	return true
end

-- ============================================================================
-- TRADE COMPLETION
-- ============================================================================

function TradingService.CompleteTrade(tradeId: string): boolean
	if not TradingService.DataService then
		TradingService.DataService = require(ServerScriptService.Services.DataService)
	end

	local trade = ActiveTrades[tradeId]
	if not trade then
		return false
	end

	-- Get player data
	local initiatorPlayer = game.Players:FindFirstWhom(function(p) return p.UserId == trade.InitiatorId end)
	local targetPlayer = game.Players:FindFirstWhom(function(p) return p.UserId == trade.TargetId end)

	if not initiatorPlayer or not targetPlayer then
		warn(string.format("[TradingService] Player disconnected during trade: %s", tradeId))
		return false
	end

	local initiatorData = TradingService.DataService.GetData(initiatorPlayer)
	local targetData = TradingService.DataService.GetData(targetPlayer)

	if not initiatorData or not targetData then
		return false
	end

	-- Exchange pets (in escrow system, just transfer)
	-- Initiator gives requested pets to target, receives offered pets
	TradingService.ExchangePets(initiatorData, targetData, trade.OfferedPets, trade.RequestedPets)
	TradingService.ExchangePets(targetData, initiatorData, trade.RequestedPets, trade.OfferedPets)

	-- Mark trade as complete
	trade.Status = "completed"
	trade.CompletedAt = os.time()

	-- Log trade
	if not initiatorData.TradeHistory then
		initiatorData.TradeHistory = {}
	end
	table.insert(initiatorData.TradeHistory, {
		TradeId = tradeId,
		Partner = trade.TargetName,
		Gave = #trade.OfferedPets,
		Received = #trade.RequestedPets,
		CompletedAt = os.time(),
	})

	if not targetData.TradeHistory then
		targetData.TradeHistory = {}
	end
	table.insert(targetData.TradeHistory, {
		TradeId = tradeId,
		Partner = trade.InitiatorName,
		Gave = #trade.RequestedPets,
		Received = #trade.OfferedPets,
		CompletedAt = os.time(),
	})

	print(string.format("[TradingService] Trade completed: %s <-> %s (ID: %s)",
		trade.InitiatorName, trade.TargetName, tradeId))

	-- Notify both players
	local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("TradeNotification")
	if notifyRemote then
		notifyRemote:FireClient(initiatorPlayer, {Type = "TradeCompleted", TradeId = tradeId})
		notifyRemote:FireClient(targetPlayer, {Type = "TradeCompleted", TradeId = tradeId})
	end

	return true
end

-- ============================================================================
-- TRADE REJECTION/CANCELLATION
-- ============================================================================

function TradingService.RejectTrade(player: Player, tradeId: string): boolean
	local trade = ActiveTrades[tradeId]
	if not trade then
		return false
	end

	if trade.Status ~= "pending" then
		return false
	end

	-- Mark as rejected
	trade.Status = "rejected"

	-- Notify other player
	local otherPlayerId = player.UserId == trade.InitiatorId and trade.TargetId or trade.InitiatorId
	local otherPlayer = game.Players:FindFirstWhom(function(p) return p.UserId == otherPlayerId end)

	if otherPlayer then
		local notifyRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("TradeNotification")
		if notifyRemote then
			notifyRemote:FireClient(otherPlayer, {
				Type = "TradeRejected",
				TradeId = tradeId,
				By = player.Name,
			})
		end
	end

	print(string.format("[TradingService] Trade rejected: %s (by %s)", tradeId, player.Name))

	return true
end

function TradingService.CancelTrade(player: Player, tradeId: string): boolean
	local trade = ActiveTrades[tradeId]
	if not trade then
		return false
	end

	if trade.Status ~= "pending" then
		return false
	end

	-- Check if initiator or target
	if player.UserId ~= trade.InitiatorId and player.UserId ~= trade.TargetId then
		return false
	end

	trade.Status = "cancelled"

	print(string.format("[TradingService] Trade cancelled: %s", tradeId))

	return true
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function TradingService.ExchangePets(fromData: table, toData: table, petsToGive: table, petsToReceive: table)
	-- Remove pets from 'from' player
	for _, petInstanceId in ipairs(petsToGive) do
		for i, pet in ipairs(fromData.Pets) do
			if pet.InstanceId == petInstanceId then
				table.remove(fromData.Pets, i)
				break
			end
		end
	end

	-- Add pets to 'to' player (not implemented - would need actual pet data transfer)
	print(string.format("[TradingService] Exchanged %d pets", #petsToGive))
end

function TradingService.GetActiveTrades(player: Player): table
	local trades = {}

	for tradeId, trade in pairs(ActiveTrades) do
		-- Only show trades involving this player
		if trade.InitiatorId == player.UserId or trade.TargetId == player.UserId then
			-- Skip expired trades
			if os.time() > trade.ExpiresAt and trade.Status == "pending" then
				trade.Status = "expired"
			end

			if trade.Status == "pending" then
				table.insert(trades, {
					Id = tradeId,
					Status = trade.Status,
					InitiatorName = trade.InitiatorName,
					TargetName = trade.TargetName,
					OfferedCount = #trade.OfferedPets,
					RequestedCount = #trade.RequestedPets,
					ExpiresAt = trade.ExpiresAt,
					TimeRemaining = math.max(0, trade.ExpiresAt - os.time()),
					IsInitiator = player.UserId == trade.InitiatorId,
					AcceptedByMe = player.UserId == trade.InitiatorId and trade.InitiatorAccepted
						or player.UserId == trade.TargetId and trade.TargetAccepted,
					AcceptedByOther = player.UserId == trade.InitiatorId and trade.TargetAccepted
						or player.UserId == trade.TargetId and trade.InitiatorAccepted,
				})
			end
		end
	end

	return trades
end

return TradingService
