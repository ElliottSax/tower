--[[
	MatchService.lua - Battle Royale Legends
	Manages match lifecycle: lobby, drop, gameplay, victory
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local GC = require(RS.Shared.Config.GameConfig)
local MatchService = {}

local currentMatch = nil
local queue = {}

function MatchService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("JoinQueue").OnServerEvent:Connect(function(player)
		if currentMatch and currentMatch.State == "InProgress" then
			re:FindFirstChild("MatchUpdate"):FireClient(player, { Type = "Error", Message = "Match in progress, wait for next round" })
			return
		end
		if not table.find(queue, player) then
			table.insert(queue, player)
			for _, p in ipairs(queue) do
				re:FindFirstChild("MatchUpdate"):FireClient(p, { Type = "Queue", Count = #queue, Needed = GC.MinPlayersToStart })
			end
		end
		if #queue >= GC.MinPlayersToStart and (not currentMatch or currentMatch.State == "Ended") then
			MatchService.StartCountdown()
		end
	end)

	re:WaitForChild("LeaveQueue").OnServerEvent:Connect(function(player)
		local idx = table.find(queue, player)
		if idx then table.remove(queue, idx) end
	end)

	re:WaitForChild("GetMatchState").OnServerEvent:Connect(function(player)
		if currentMatch then
			re:FindFirstChild("MatchUpdate"):FireClient(player, { Type = "State", State = currentMatch.State, Alive = currentMatch.AliveCount or 0 })
		end
	end)
end

function MatchService.StartCountdown()
	local DS = require(SSS.Services.DataService)
	local re = RS:FindFirstChild("RemoteEvents")
	currentMatch = {
		State = "Countdown",
		Players = {},
		Alive = {},
		Kills = {},
		AliveCount = 0,
	}

	for _, p in ipairs(queue) do
		currentMatch.Players[p.UserId] = p
		currentMatch.Alive[p.UserId] = true
		currentMatch.Kills[p.UserId] = 0
		currentMatch.AliveCount = currentMatch.AliveCount + 1
	end
	queue = {}

	-- Countdown
	for i = 10, 1, -1 do
		for uid, p in pairs(currentMatch.Players) do
			if p.Parent then
				re:FindFirstChild("MatchUpdate"):FireClient(p, { Type = "Countdown", Time = i })
			end
		end
		task.wait(1)
	end

	MatchService.StartMatch()
end

function MatchService.StartMatch()
	local re = RS:FindFirstChild("RemoteEvents")
	currentMatch.State = "InProgress"
	currentMatch.StartTime = tick()

	-- Assign random drop locations
	for uid, p in pairs(currentMatch.Players) do
		if p.Parent then
			local loc = GC.DropLocations[math.random(#GC.DropLocations)]
			re:FindFirstChild("MatchUpdate"):FireClient(p, { Type = "Start", DropLocation = loc, AliveCount = currentMatch.AliveCount })
		end
	end

	-- Start storm timer
	task.spawn(function()
		local StormService = require(SSS.Services.StormService)
		StormService.StartStorm(currentMatch)
	end)

	-- Match timeout
	task.spawn(function()
		task.wait(GC.MatchDuration)
		if currentMatch and currentMatch.State == "InProgress" then
			MatchService.EndMatch(nil)
		end
	end)
end

function MatchService.EliminatePlayer(player, killerPlayer)
	if not currentMatch or currentMatch.State ~= "InProgress" then return end
	if not currentMatch.Alive[player.UserId] then return end

	currentMatch.Alive[player.UserId] = false
	currentMatch.AliveCount = currentMatch.AliveCount - 1

	if killerPlayer and currentMatch.Kills[killerPlayer.UserId] then
		currentMatch.Kills[killerPlayer.UserId] = currentMatch.Kills[killerPlayer.UserId] + 1
	end

	local re = RS:FindFirstChild("RemoteEvents")
	local placement = currentMatch.AliveCount + 1

	re:FindFirstChild("MatchUpdate"):FireClient(player, { Type = "Eliminated", Placement = placement })

	-- Broadcast alive count
	for uid, p in pairs(currentMatch.Players) do
		if p.Parent and currentMatch.Alive[uid] then
			re:FindFirstChild("MatchUpdate"):FireClient(p, { Type = "AliveUpdate", Count = currentMatch.AliveCount })
		end
	end

	-- Check for winner
	if currentMatch.AliveCount <= 1 then
		local winner = nil
		for uid, alive in pairs(currentMatch.Alive) do
			if alive then winner = currentMatch.Players[uid]; break end
		end
		MatchService.EndMatch(winner)
	end
end

function MatchService.EndMatch(winner)
	if not currentMatch or currentMatch.State == "Ended" then return end
	currentMatch.State = "Ended"

	local DS = require(SSS.Services.DataService)
	local re = RS:FindFirstChild("RemoteEvents")

	-- Award XP and record stats
	for uid, p in pairs(currentMatch.Players) do
		if p.Parent then
			local kills = currentMatch.Kills[uid] or 0
			local isWinner = winner and winner.UserId == uid
			local placement = isWinner and 1 or (currentMatch.AliveCount + 1)

			local xp = kills * GC.XPRewards.Kill
			if placement <= 10 then xp = xp + GC.XPRewards.Top10 end
			if placement <= 5 then xp = xp + GC.XPRewards.Top5 end
			if isWinner then xp = xp + GC.XPRewards.Win end

			DS.AddXP(p, xp)
			DS.AddCoins(p, xp)
			DS.RecordMatch(p, placement, kills)

			re:FindFirstChild("MatchUpdate"):FireClient(p, {
				Type = "MatchEnd",
				Winner = winner and winner.Name or "Nobody",
				Placement = placement,
				Kills = kills,
				XPEarned = xp,
			})
		end
	end

	currentMatch = nil
end

function MatchService.GetMatch() return currentMatch end

return MatchService
