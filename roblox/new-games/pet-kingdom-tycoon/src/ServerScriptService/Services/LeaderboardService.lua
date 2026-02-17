--[[
	LeaderboardService.lua - Pet Kingdom Tycoon
	Global leaderboards for total pets and coins
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DSS = game:GetService("DataStoreService")
local LeaderboardService = {}

local petsBoard = DSS:GetOrderedDataStore("PKTPetsLeaderV1")
local coinsBoard = DSS:GetOrderedDataStore("PKTCoinsLeaderV1")

function LeaderboardService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardType)
		if type(boardType) ~= "string" then return end
		local board = boardType == "Coins" and coinsBoard or petsBoard
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
					pcall(function() petsBoard:SetAsync(tostring(p.UserId), data.TotalPets or #(data.Pets or {})) end)
					pcall(function() coinsBoard:SetAsync(tostring(p.UserId), data.Coins or 0) end)
				end
			end
		end
	end)
end

return LeaderboardService
