--[[
	IslandService.lua - Treasure Hunt Islands
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local IslandService = {}

function IslandService.Init()
	local DataService = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("UnlockIsland").OnServerEvent:Connect(function(player, islandName)
		if type(islandName) ~= "string" then return end
		local data = DataService.GetFullData(player); if not data then return end
		local cfg, idx = nil, 0
		for i, island in ipairs(GameConfig.Islands) do if island.Name == islandName then cfg = island; idx = i; break end end
		if not cfg then return end
		for _, u in ipairs(data.UnlockedIslands) do if u == islandName then return end end
		if idx > 1 then
			local prev = GameConfig.Islands[idx - 1]; local prevOk = false
			for _, u in ipairs(data.UnlockedIslands) do if u == prev.Name then prevOk = true; break end end
			if not prevOk then return end
		end
		if not DataService.SpendCoins(player, cfg.UnlockCost) then return end
		table.insert(data.UnlockedIslands, islandName)
		IslandService.SendIslands(player)
	end)

	re:WaitForChild("TravelToIsland").OnServerEvent:Connect(function(player, islandName)
		if type(islandName) ~= "string" then return end
		local data = DataService.GetFullData(player); if not data then return end
		for _, u in ipairs(data.UnlockedIslands) do
			if u == islandName then data.CurrentIsland = islandName; return end
		end
	end)

	re:WaitForChild("GetIslands").OnServerEvent:Connect(function(player) IslandService.SendIslands(player) end)
end

function IslandService.SendIslands(player)
	local DataService = require(SSS.Services.DataService)
	local data = DataService.GetFullData(player); if not data then return end
	local islands = {}
	for _, island in ipairs(GameConfig.Islands) do
		local unlocked = false
		for _, u in ipairs(data.UnlockedIslands) do if u == island.Name then unlocked = true; break end end
		table.insert(islands, { Name = island.Name, UnlockCost = island.UnlockCost, Unlocked = unlocked, Current = data.CurrentIsland == island.Name })
	end
	local re = RS:FindFirstChild("RemoteEvents")
	if re then local il = re:FindFirstChild("IslandList"); if il then il:FireClient(player, islands) end end
end

return IslandService
