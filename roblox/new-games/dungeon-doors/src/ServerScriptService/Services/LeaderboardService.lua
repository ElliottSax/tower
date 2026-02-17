--[[
	LeaderboardService.lua - Dungeon Doors
	Global leaderboards for highest floor reached and total souls
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DSS = game:GetService("DataStoreService")
local LeaderboardService = {}

local floorBoard = DSS:GetOrderedDataStore("DDFloorLeaderV1")
local soulsBoard = DSS:GetOrderedDataStore("DDSoulsLeaderV1")

function LeaderboardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardType)
		if type(boardType) ~= "string" then return end
		local board = boardType == "Souls" and soulsBoard or floorBoard
		local ok, pages = pcall(function() return board:GetSortedAsync(false, 20) end)
		if not ok then return end
		local top = pages:GetCurrentPage()
		local entries = {}
		for i, entry in ipairs(top) do
			table.insert(entries, { Rank = i, UserId = entry.key, Value = entry.value })
		end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local lu = reEvents:FindFirstChild("LeaderboardData")
			if lu then lu:FireClient(player, { Board = boardType, Entries = entries }) end
		end
	end)

	-- Update leaderboards periodically
	task.spawn(function()
		while true do
			task.wait(60)
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				local data = DS.GetData(p)
				if data then
					pcall(function() floorBoard:SetAsync(tostring(p.UserId), data.HighestFloor or 0) end)
					pcall(function() soulsBoard:SetAsync(tostring(p.UserId), data.Souls or 0) end)
				end
			end
		end
	end)
end

return LeaderboardService
