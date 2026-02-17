local RS = game:GetService("ReplicatedStorage")
local R = {}
local E = {
	"PlaceFurniture","RemoveFurniture","UnlockLocation","GetRestaurant","RestaurantSync",
	"CookDish","CookResult","CustomerOrder",
	"HireStaff","FireStaff","GetStaff","StaffSync",
	"GetShopData","ShopData","PurchaseGamePass","PurchaseDevProduct",
	"Prestige","GetPrestigeInfo","PrestigeUpdate",
	"ClaimDaily","GetDailyStatus","DailyUpdate",
	"GetLeaderboard","LeaderboardData",
	"DailyReward","Notification",
}
function R.Init()
	local f = Instance.new("Folder"); f.Name = "RemoteEvents"; f.Parent = RS
	for _, n in ipairs(E) do local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = f end
end
return R
