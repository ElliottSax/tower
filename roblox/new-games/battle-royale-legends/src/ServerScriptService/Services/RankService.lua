--[[
	RankService.lua - Battle Royale Legends
	XP-based ranking system with global leaderboards
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local DSS = game:GetService("DataStoreService")
local GC = require(RS.Shared.Config.GameConfig)
local RankService = {}

local leaderboard = DSS:GetOrderedDataStore("BRLeaderboardV1")

function RankService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("GetRank").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local rank = RankService.GetRankForXP(data.XP)
		local nextRank = RankService.GetNextRank(data.XP)
		re:FindFirstChild("RankUpdate"):FireClient(player, {
			Rank = rank.Name,
			XP = data.XP,
			NextRank = nextRank and nextRank.Name or "MAX",
			NextRankXP = nextRank and nextRank.MinXP or data.XP,
			Wins = data.Wins,
			Kills = data.Kills,
			GamesPlayed = data.GamesPlayed,
		})
	end)

	re:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player)
		local ok, pages = pcall(function() return leaderboard:GetSortedAsync(false, 20) end)
		if not ok then return end
		local top = pages:GetCurrentPage()
		local entries = {}
		for i, entry in ipairs(top) do
			table.insert(entries, { Rank = i, UserId = entry.key, XP = entry.value })
		end
		re:FindFirstChild("RankUpdate"):FireClient(player, { Type = "Leaderboard", Entries = entries })
	end)

	-- Update leaderboard periodically
	task.spawn(function()
		while true do
			task.wait(60)
			for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
				local data = DS.GetData(p)
				if data then
					pcall(function() leaderboard:SetAsync(tostring(p.UserId), data.XP) end)
				end
			end
		end
	end)
end

function RankService.GetRankForXP(xp)
	local best = GC.Ranks[1]
	for _, rank in ipairs(GC.Ranks) do
		if xp >= rank.MinXP then best = rank end
	end
	return best
end

function RankService.GetNextRank(xp)
	for i, rank in ipairs(GC.Ranks) do
		if xp < rank.MinXP then return rank end
	end
	return nil
end

return RankService
