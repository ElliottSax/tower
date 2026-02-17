local RS = game:GetService("ReplicatedStorage")
local R = {}
local E = {
	"StartRun", "CompleteRoom", "SkipRoom", "PlayerDied", "UnlockFactory", "RunUpdate",
	"TrapHit", "CollectGear", "UsePowerup", "TrapUpdate",
	"RequestPuzzle", "SolvePuzzle", "PuzzleUpdate",
	"BuyUpgrade", "GetUpgrades", "UpgradeUpdate",
	"BuyCompanion", "EquipCompanion", "GetCompanions", "CompanionUpdate",
	"ClaimDaily", "GetDailyStatus", "DailyUpdate",
	"PurchaseGamePass", "PurchaseDevProduct",
	"GetShopData", "ShopData",
	"Notification",
}
function R.Init()
	local f = Instance.new("Folder"); f.Name = "RemoteEvents"; f.Parent = RS
	for _, n in ipairs(E) do local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = f end
end
return R
