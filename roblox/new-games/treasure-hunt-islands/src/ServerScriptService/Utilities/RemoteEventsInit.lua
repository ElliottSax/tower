local RS = game:GetService("ReplicatedStorage")
local R = {}
local EVENTS = {
	"UnlockIsland","TravelToIsland","GetIslands","IslandList",
	"Dig","DigResult","BuyTool","SellTreasure",
	"BuyShip","HireCrew","GetShipInfo","ShipInfo","ShipChanged",
	"FightPirate","CombatResult",
	"GetTradingPost","TradingPostData",
	"GetShopData","ShopData","PurchaseGamePass","PurchaseDevProduct",
	"IslandSync","ShipSync",
	"Prestige","GetPrestigeInfo","PrestigeUpdate",
	"ClaimDaily","GetDailyStatus","DailyUpdate",
	"GetLeaderboard","LeaderboardData",
	"DailyReward","Notification",
}
function R.Init()
	local f = Instance.new("Folder"); f.Name = "RemoteEvents"; f.Parent = RS
	for _, n in ipairs(EVENTS) do local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = f end
end
return R
