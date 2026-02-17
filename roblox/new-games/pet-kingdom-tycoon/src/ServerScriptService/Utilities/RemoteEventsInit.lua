--[[
	RemoteEventsInit.lua - Pet Kingdom Tycoon
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEventsInit = {}

local REMOTE_EVENTS = {
	"HatchEgg", "HatchResult", "FeedPet", "EvolvePet", "EvolveResult",
	"ReleasePet", "GetPets", "PetSync",
	"StartBreeding", "CollectBreeding", "GetBreedingStatus",
	"BreedingStatus", "BreedingResult",
	"BuildStructure", "RemoveStructure", "GetKingdom", "KingdomSync",
	"UnlockWorld", "GetWorlds", "WorldList",
	"RequestTrade", "AcceptTrade", "DeclineTrade",
	"AddTradeItem", "ConfirmTrade",
	"TradeRequest", "TradeActive", "TradeSync", "TradeComplete", "TradeCancelled",
	"GetShopData", "ShopData", "PurchaseGamePass", "PurchaseDevProduct",
	"GetEggs", "EggResult", "BreedingUpdate",
	"ClaimDaily", "GetDailyStatus", "DailyUpdate",
	"GetLeaderboard", "LeaderboardData",
	"WorldSync",
	"DailyReward", "Notification",
}

function RemoteEventsInit.Init()
	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	for _, name in ipairs(REMOTE_EVENTS) do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
	end
	print("[RemoteEventsInit] Created", #REMOTE_EVENTS, "remote events")
end

return RemoteEventsInit
