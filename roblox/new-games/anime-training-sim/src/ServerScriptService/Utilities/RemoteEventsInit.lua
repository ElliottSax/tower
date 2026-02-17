--[[
	RemoteEventsInit.lua - Anime Training Simulator
	Creates all RemoteEvents for client-server communication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsInit = {}

local REMOTE_EVENTS = {
	-- Training
	"Train", "TrainResult",

	-- Zones
	"UnlockZone", "TeleportToZone", "GetZones", "ZoneList", "ZoneChanged",

	-- Transformations
	"Transform", "GetTransformations", "TransformResult", "TransformationList",

	-- Pets
	"HatchEgg", "HatchResult", "EquipPet", "UnequipPet",
	"FusePets", "FuseResult", "DeletePet", "PetSync",

	-- Abilities
	"BuyAbility", "EquipAbility", "GetAbilities",
	"AbilityUnlocked", "AbilityList", "AbilitySync",

	-- PvP
	"JoinPvPQueue", "LeavePvPQueue", "PvPAttack",
	"PvPStatus", "PvPMatchStart", "PvPSync", "PvPMatchEnd",

	-- Quests
	"GetQuests", "ClaimQuest", "QuestList", "QuestSync", "QuestComplete",

	-- Rebirth
	"Rebirth", "GetRebirthInfo", "RebirthInfo", "RebirthComplete",

	-- Leaderboards
	"GetLeaderboard", "LeaderboardData",

	-- Daily Rewards
	"DailyReward",

	-- Shop / Monetization
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
