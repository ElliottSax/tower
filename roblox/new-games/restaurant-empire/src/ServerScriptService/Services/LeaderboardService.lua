--[[
	LeaderboardService.lua - Restaurant Empire
	Global leaderboards for stars rating and total coins
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DSS = game:GetService("DataStoreService")
local LeaderboardService = {}

local starsBoard = DSS:GetOrderedDataStore("REStarsLeaderV1")
local coinsBoard = DSS:GetOrderedDataStore("RECoinsLeaderV1")

function LeaderboardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardType)
		if type(boardType) ~= "string" then return end
		local board = boardType == "Coins" and coinsBoard or starsBoard
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
					pcall(function() starsBoard:SetAsync(tostring(p.UserId), math.floor((data.Stars or 0) * 100)) end)
					pcall(function() coinsBoard:SetAsync(tostring(p.UserId), data.Coins or 0) end)
				end
			end
		end
	end)
end

return LeaderboardService
