local RS = game:GetService("ReplicatedStorage")
local R = {}
local E = {
	"JoinQueue", "LeaveQueue", "GetMatchState", "MatchUpdate",
	"Attack", "EquipWeapon", "UseHeal", "UseShield", "CombatUpdate",
	"OpenChest", "PickupLoot", "LootDrop",
	"Build", "DestroyPiece", "BuildUpdate",
	"StormUpdate", "StormDamage",
	"GetRank", "GetLeaderboard", "RankUpdate",
	"BuySkin", "EquipSkin", "GetShopData", "ShopUpdate",
	"PurchaseGamePass", "PurchaseDevProduct",
	"Notification",
}
function R.Init()
	local f = Instance.new("Folder"); f.Name = "RemoteEvents"; f.Parent = RS
	for _, n in ipairs(E) do local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = f end
end
return R
