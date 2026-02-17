--[[
	LeaderboardService.lua - Treasure Hunt Islands
	Global leaderboards for treasures found and gold earned
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DSS = game:GetService("DataStoreService")
local LeaderboardService = {}

local treasureBoard = DSS:GetOrderedDataStore("THITreasureLeaderV1")
local goldBoard = DSS:GetOrderedDataStore("THIGoldLeaderV1")

function LeaderboardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardType)
		if type(boardType) ~= "string" then return end
		local board = boardType == "Gold" and goldBoard or treasureBoard
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

	task.spawn(function()
		while true do
			task.wait(60)
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				local data = DS.GetData(p)
				if data then
					pcall(function() treasureBoard:SetAsync(tostring(p.UserId), data.TreasuresFound or 0) end)
					pcall(function() goldBoard:SetAsync(tostring(p.UserId), data.Coins or 0) end)
				end
			end
		end
	end)
end

return LeaderboardService
