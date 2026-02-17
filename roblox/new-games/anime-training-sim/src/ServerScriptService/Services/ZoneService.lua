--[[
	ZoneService.lua - Anime Training Simulator
	Training zone unlocking and teleportation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ZoneService = {}
ZoneService.DataService = nil

function ZoneService.Init()
	print("[ZoneService] Initializing...")
	ZoneService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("UnlockZone").OnServerEvent:Connect(function(player, zoneName)
		ZoneService.UnlockZone(player, zoneName)
	end)

	remoteEvents:WaitForChild("TeleportToZone").OnServerEvent:Connect(function(player, zoneName)
		ZoneService.TeleportToZone(player, zoneName)
	end)

	remoteEvents:WaitForChild("GetZones").OnServerEvent:Connect(function(player)
		ZoneService.SendZoneList(player)
	end)

	print("[ZoneService] Initialized")
end

function ZoneService.UnlockZone(player, zoneName)
	if type(zoneName) ~= "string" then return end
	local data = ZoneService.DataService.GetFullData(player)
	if not data then return end

	local zoneConfig = nil
	local zoneIndex = 0
	for i, zone in ipairs(GameConfig.TrainingZones) do
		if zone.Name == zoneName then
			zoneConfig = zone
			zoneIndex = i
			break
		end
	end
	if not zoneConfig then return end

	-- Check already unlocked
	for _, z in ipairs(data.UnlockedZones) do
		if z == zoneName then return end
	end

	-- Check previous zone is unlocked (sequential unlock)
	if zoneIndex > 1 then
		local prevZone = GameConfig.TrainingZones[zoneIndex - 1]
		local prevUnlocked = false
		for _, z in ipairs(data.UnlockedZones) do
			if z == prevZone.Name then prevUnlocked = true; break end
		end
		if not prevUnlocked then return end
	end

	-- Check power requirement
	local totalPower = ZoneService.DataService.GetTotalPower(player)
	if totalPower < zoneConfig.RequiredPower then return end

	-- Check cost
	if not ZoneService.DataService.SpendCoins(player, zoneConfig.UnlockCost) then return end

	table.insert(data.UnlockedZones, zoneName)

	-- Quest progress
	local QuestService = require(ServerScriptService.Services.QuestService)
	QuestService.UpdateProgress(player, "Zones", nil, 1)

	ZoneService.SendZoneList(player)
	print("[ZoneService]", player.Name, "unlocked zone:", zoneName)
end

function ZoneService.TeleportToZone(player, zoneName)
	if type(zoneName) ~= "string" then return end
	local data = ZoneService.DataService.GetFullData(player)
	if not data then return end

	local unlocked = false
	for _, z in ipairs(data.UnlockedZones) do
		if z == zoneName then unlocked = true; break end
	end
	if not unlocked then return end

	data.CurrentZone = zoneName

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local zoneChanged = remoteEvents:FindFirstChild("ZoneChanged")
		if zoneChanged then
			zoneChanged:FireClient(player, zoneName)
		end
	end
end

function ZoneService.SendZoneList(player)
	local data = ZoneService.DataService.GetFullData(player)
	if not data then return end

	local totalPower = ZoneService.DataService.GetTotalPower(player)
	local zones = {}

	for _, zone in ipairs(GameConfig.TrainingZones) do
		local unlocked = false
		for _, z in ipairs(data.UnlockedZones) do
			if z == zone.Name then unlocked = true; break end
		end

		table.insert(zones, {
			Name = zone.Name,
			Multiplier = zone.Multiplier,
			UnlockCost = zone.UnlockCost,
			RequiredPower = zone.RequiredPower,
			Unlocked = unlocked,
			Current = data.CurrentZone == zone.Name,
			CanUnlock = totalPower >= zone.RequiredPower and not unlocked,
		})
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local zoneList = remoteEvents:FindFirstChild("ZoneList")
		if zoneList then
			zoneList:FireClient(player, zones)
		end
	end
end

return ZoneService
