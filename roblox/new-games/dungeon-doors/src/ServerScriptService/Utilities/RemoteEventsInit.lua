--[[
	RemoteEventsInit.lua - Dungeon Doors
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEventsInit = {}
local REMOTE_EVENTS = {
	"StartRun", "VoteDoor", "GetRunState", "AbandonRun", "RunState", "RunEnd",
	"CombatResult", "BossDefeated", "LootDrop", "Healed", "ShopRoom",
	"BuyUpgrade", "GetSoulsShop", "SoulsShopData", "UpgradeResult",
	"GetShopData", "ShopData", "PurchaseGamePass", "PurchaseDevProduct",
	"ChooseDoor", "DungeonUpdate",
	"ClaimDaily", "GetDailyStatus", "DailyUpdate",
	"GetLeaderboard", "LeaderboardData",
	"DailyReward", "Notification",
}

function RemoteEventsInit.Init()
	local folder = Instance.new("Folder"); folder.Name = "RemoteEvents"; folder.Parent = ReplicatedStorage
	for _, name in ipairs(REMOTE_EVENTS) do local e = Instance.new("RemoteEvent"); e.Name = name; e.Parent = folder end
	print("[RemoteEventsInit] Created", #REMOTE_EVENTS, "remote events")
end

return RemoteEventsInit
