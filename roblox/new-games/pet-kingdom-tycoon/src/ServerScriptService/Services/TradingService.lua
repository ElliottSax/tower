--[[
	TradingService.lua - Pet Kingdom Tycoon
	Player-to-player pet trading
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TradingService = {}
TradingService.DataService = nil

local ActiveTrades = {} -- [tradeId] = { Player1, Player2, Offer1 = {petIds}, Offer2 = {petIds}, Confirmed = {} }
local PendingRequests = {} -- [targetUserId] = { From = player, Time = os.time() }

function TradingService.Init()
	print("[TradingService] Initializing...")
	TradingService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("RequestTrade").OnServerEvent:Connect(function(player, targetName)
		TradingService.RequestTrade(player, targetName)
	end)

	re:WaitForChild("AcceptTrade").OnServerEvent:Connect(function(player)
		TradingService.AcceptTrade(player)
	end)

	re:WaitForChild("DeclineTrade").OnServerEvent:Connect(function(player)
		TradingService.DeclineTrade(player)
	end)

	re:WaitForChild("AddTradeItem").OnServerEvent:Connect(function(player, petId)
		TradingService.AddItem(player, petId)
	end)

	re:WaitForChild("ConfirmTrade").OnServerEvent:Connect(function(player)
		TradingService.ConfirmTrade(player)
	end)

	print("[TradingService] Initialized")
end

function TradingService.RequestTrade(player, targetName)
	if type(targetName) ~= "string" then return end
	local target = Players:FindFirstChild(targetName)
	if not target or target == player then return end

	PendingRequests[target.UserId] = { From = player, Time = os.time() }

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local tr = re:FindFirstChild("TradeRequest")
		if tr then tr:FireClient(target, player.Name) end
	end
end

function TradingService.AcceptTrade(player)
	local request = PendingRequests[player.UserId]
	if not request then return end
	if os.time() - request.Time > 30 then PendingRequests[player.UserId] = nil; return end

	local tradeId = player.UserId .. "_" .. request.From.UserId
	ActiveTrades[tradeId] = {
		Player1 = request.From,
		Player2 = player,
		Offer1 = {},
		Offer2 = {},
		Confirmed = {},
	}
	PendingRequests[player.UserId] = nil

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local ta = re:FindFirstChild("TradeActive")
		if ta then
			ta:FireClient(request.From, { TradeId = tradeId, Partner = player.Name })
			ta:FireClient(player, { TradeId = tradeId, Partner = request.From.Name })
		end
	end
end

function TradingService.DeclineTrade(player)
	PendingRequests[player.UserId] = nil
	-- Also cancel any active trade
	for tradeId, trade in pairs(ActiveTrades) do
		if trade.Player1 == player or trade.Player2 == player then
			local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if re then
				local tc = re:FindFirstChild("TradeCancelled")
				if tc then
					if trade.Player1.Parent then tc:FireClient(trade.Player1) end
					if trade.Player2.Parent then tc:FireClient(trade.Player2) end
				end
			end
			ActiveTrades[tradeId] = nil
			break
		end
	end
end

function TradingService.AddItem(player, petId)
	if type(petId) ~= "string" then return end
	for tradeId, trade in pairs(ActiveTrades) do
		if trade.Player1 == player then
			table.insert(trade.Offer1, petId)
			TradingService.SyncTrade(tradeId)
			return
		elseif trade.Player2 == player then
			table.insert(trade.Offer2, petId)
			TradingService.SyncTrade(tradeId)
			return
		end
	end
end

function TradingService.ConfirmTrade(player)
	for tradeId, trade in pairs(ActiveTrades) do
		if trade.Player1 == player or trade.Player2 == player then
			trade.Confirmed[player.UserId] = true

			if trade.Confirmed[trade.Player1.UserId] and trade.Confirmed[trade.Player2.UserId] then
				TradingService.ExecuteTrade(tradeId)
			end
			return
		end
	end
end

function TradingService.ExecuteTrade(tradeId)
	local trade = ActiveTrades[tradeId]
	if not trade then return end

	local data1 = TradingService.DataService.GetFullData(trade.Player1)
	local data2 = TradingService.DataService.GetFullData(trade.Player2)
	if not data1 or not data2 then return end

	-- Transfer pets
	for _, petId in ipairs(trade.Offer1) do
		if data1.Pets[petId] then
			data2.Pets[petId] = data1.Pets[petId]
			data1.Pets[petId] = nil
		end
	end

	for _, petId in ipairs(trade.Offer2) do
		if data2.Pets[petId] then
			data1.Pets[petId] = data2.Pets[petId]
			data2.Pets[petId] = nil
		end
	end

	data1.TradesCompleted = (data1.TradesCompleted or 0) + 1
	data2.TradesCompleted = (data2.TradesCompleted or 0) + 1

	ActiveTrades[tradeId] = nil

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local tc = re:FindFirstChild("TradeComplete")
		if tc then
			if trade.Player1.Parent then tc:FireClient(trade.Player1) end
			if trade.Player2.Parent then tc:FireClient(trade.Player2) end
		end
	end
end

function TradingService.SyncTrade(tradeId)
	local trade = ActiveTrades[tradeId]
	if not trade then return end
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local ts = re:FindFirstChild("TradeSync")
		if ts then
			local syncData = { Offer1 = trade.Offer1, Offer2 = trade.Offer2 }
			if trade.Player1.Parent then ts:FireClient(trade.Player1, syncData) end
			if trade.Player2.Parent then ts:FireClient(trade.Player2, syncData) end
		end
	end
end

return TradingService
