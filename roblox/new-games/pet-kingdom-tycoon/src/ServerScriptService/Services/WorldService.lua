--[[
	WorldService.lua - Pet Kingdom Tycoon
	World unlocking and exploration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WorldService = {}
WorldService.DataService = nil

function WorldService.Init()
	print("[WorldService] Initializing...")
	WorldService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("UnlockWorld").OnServerEvent:Connect(function(player, worldName)
		WorldService.UnlockWorld(player, worldName)
	end)

	re:WaitForChild("GetWorlds").OnServerEvent:Connect(function(player)
		WorldService.SendWorldList(player)
	end)

	print("[WorldService] Initialized")
end

function WorldService.UnlockWorld(player, worldName)
	if type(worldName) ~= "string" then return end
	local data = WorldService.DataService.GetFullData(player)
	if not data then return end

	local worldConfig = nil
	local worldIndex = 0
	for i, w in ipairs(GameConfig.Worlds) do
		if w.Name == worldName then worldConfig = w; worldIndex = i; break end
	end
	if not worldConfig then return end

	for _, w in ipairs(data.UnlockedWorlds) do
		if w == worldName then return end
	end

	-- Must unlock in order
	if worldIndex > 1 then
		local prevWorld = GameConfig.Worlds[worldIndex - 1]
		local prevUnlocked = false
		for _, w in ipairs(data.UnlockedWorlds) do
			if w == prevWorld.Name then prevUnlocked = true; break end
		end
		if not prevUnlocked then return end
	end

	if not WorldService.DataService.SpendCoins(player, worldConfig.UnlockCost) then return end

	table.insert(data.UnlockedWorlds, worldName)
	WorldService.SendWorldList(player)
end

function WorldService.SendWorldList(player)
	local data = WorldService.DataService.GetFullData(player)
	if not data then return end

	local worlds = {}
	for _, world in ipairs(GameConfig.Worlds) do
		local unlocked = false
		for _, w in ipairs(data.UnlockedWorlds) do
			if w == world.Name then unlocked = true; break end
		end
		table.insert(worlds, {
			Name = world.Name,
			UnlockCost = world.UnlockCost,
			Unlocked = unlocked,
			Pets = world.Pets,
			EggTypes = world.EggTypes,
		})
	end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local wl = re:FindFirstChild("WorldList")
		if wl then wl:FireClient(player, worlds) end
	end
end

return WorldService
