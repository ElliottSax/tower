--[[
	RemoteEventsInit.lua - Grow a World
	Creates all RemoteEvents and RemoteFunctions for client-server communication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsInit = {}

local REMOTE_EVENTS = {
	-- Garden
	"PlantSeed", "WaterPlant", "HarvestPlant", "HarvestAll",
	"GetGardenState", "GardenUpdate", "GardenState",

	-- Seeds
	"BuySeed", "BuySeedPack", "GetSeedShop",
	"SeedShopData", "SeedPackResult",

	-- Biomes
	"UnlockBiome", "TeleportToBiome", "GetBiomeInfo", "BiomeInfo",

	-- Trading
	"RequestTrade", "AcceptTrade", "DeclineTrade",
	"AddTradeItem", "ConfirmTrade",
	"TradeRequest", "TradeActive", "TradeSync",
	"TradeComplete", "TradeCancelled",

	-- Prestige
	"Prestige", "GetPrestigeInfo", "PrestigeInfo", "PrestigeComplete",

	-- Leaderboards
	"GetLeaderboard", "LeaderboardData",

	-- Daily Rewards
	"DailyReward",

	-- Monetization
	"GetShopData", "ShopData",
	"PurchaseGamePass", "PurchaseDevProduct",

	-- General
	"Notification",
}

function RemoteEventsInit.Init()
	print("[RemoteEventsInit] Creating", #REMOTE_EVENTS, "remote events...")

	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage

	for _, eventName in ipairs(REMOTE_EVENTS) do
		local event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = folder
	end

	print("[RemoteEventsInit] Created all remote events")
end

return RemoteEventsInit
