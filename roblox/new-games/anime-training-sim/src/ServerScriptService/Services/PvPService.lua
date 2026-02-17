--[[
	PvPService.lua - Anime Training Simulator
	Arena-based PvP with ELO rating, matchmaking, ranked tiers
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PvPService = {}
PvPService.DataService = nil

local MatchQueue = {} -- { { Player = player, Power = power, Rating = rating } }
local ActiveMatches = {} -- [matchId] = { Player1, Player2, StartTime }
local PlayerCooldowns = {} -- [UserId] = os.time() of last match

function PvPService.Init()
	print("[PvPService] Initializing...")

	PvPService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("JoinPvPQueue").OnServerEvent:Connect(function(player)
		PvPService.JoinQueue(player)
	end)

	remoteEvents:WaitForChild("LeavePvPQueue").OnServerEvent:Connect(function(player)
		PvPService.LeaveQueue(player)
	end)

	remoteEvents:WaitForChild("PvPAttack").OnServerEvent:Connect(function(player, abilityName)
		PvPService.ProcessAttack(player, abilityName)
	end)

	-- Matchmaking loop
	task.spawn(function()
		while true do
			task.wait(3)
			PvPService.ProcessMatchmaking()
		end
	end)

	-- Match timer loop
	task.spawn(function()
		while true do
			task.wait(1)
			PvPService.CheckMatchTimers()
		end
	end)

	print("[PvPService] Initialized")
end

function PvPService.JoinQueue(player)
	local data = PvPService.DataService.GetFullData(player)
	if not data then return end

	local totalPower = PvPService.DataService.GetTotalPower(player)
	if totalPower < GameConfig.PvP.MinPowerToEnter then return end

	-- Check cooldown
	local cooldown = PlayerCooldowns[player.UserId]
	if cooldown and os.time() - cooldown < GameConfig.PvP.ArenaCooldown then return end

	-- Check not already in queue or match
	for _, entry in ipairs(MatchQueue) do
		if entry.Player == player then return end
	end

	for _, match in pairs(ActiveMatches) do
		if match.Player1 == player or match.Player2 == player then return end
	end

	table.insert(MatchQueue, {
		Player = player,
		Power = totalPower,
		Rating = data.PvPRating or 1000,
		JoinedAt = os.time(),
	})

	-- Notify player
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local pvpStatus = remoteEvents:FindFirstChild("PvPStatus")
		if pvpStatus then
			pvpStatus:FireClient(player, { Status = "InQueue", QueueSize = #MatchQueue })
		end
	end
end

function PvPService.LeaveQueue(player)
	for i, entry in ipairs(MatchQueue) do
		if entry.Player == player then
			table.remove(MatchQueue, i)
			break
		end
	end
end

function PvPService.ProcessMatchmaking()
	if #MatchQueue < 2 then return end

	-- Sort by rating for closer matches
	table.sort(MatchQueue, function(a, b) return a.Rating < b.Rating end)

	-- Match adjacent players in queue
	local matched = {}
	for i = 1, #MatchQueue - 1, 2 do
		local p1 = MatchQueue[i]
		local p2 = MatchQueue[i + 1]

		-- Check both players still valid
		if p1.Player.Parent and p2.Player.Parent then
			local matchId = tostring(os.time()) .. "_" .. p1.Player.UserId .. "_" .. p2.Player.UserId
			ActiveMatches[matchId] = {
				Player1 = p1.Player,
				Player2 = p2.Player,
				StartTime = os.time(),
				HP1 = 100,
				HP2 = 100,
			}

			table.insert(matched, i + 1)
			table.insert(matched, i)

			-- Notify both players
			local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remoteEvents then
				local pvpStart = remoteEvents:FindFirstChild("PvPMatchStart")
				if pvpStart then
					pvpStart:FireClient(p1.Player, {
						MatchId = matchId,
						Opponent = p2.Player.Name,
						OpponentPower = p2.Power,
					})
					pvpStart:FireClient(p2.Player, {
						MatchId = matchId,
						Opponent = p1.Player.Name,
						OpponentPower = p1.Power,
					})
				end
			end
		end
	end

	-- Remove matched from queue (reverse order to preserve indices)
	table.sort(matched, function(a, b) return a > b end)
	for _, idx in ipairs(matched) do
		table.remove(MatchQueue, idx)
	end
end

function PvPService.ProcessAttack(player, abilityName)
	if type(abilityName) ~= "string" then return end

	-- Find active match
	local matchId, match = nil, nil
	for id, m in pairs(ActiveMatches) do
		if m.Player1 == player or m.Player2 == player then
			matchId = id
			match = m
			break
		end
	end

	if not match then return end

	local data = PvPService.DataService.GetFullData(player)
	if not data then return end

	-- Calculate damage based on stats
	local totalPower = PvPService.DataService.GetTotalPower(player)
	local baseDamage = math.floor(math.sqrt(totalPower) * 0.1)
	if baseDamage < 1 then baseDamage = 1 end

	-- Apply ability bonus if valid
	for _, ability in ipairs(GameConfig.Abilities) do
		if ability.Name == abilityName then
			baseDamage = baseDamage + ability.Damage
			break
		end
	end

	-- Apply damage
	local isPlayer1 = match.Player1 == player
	if isPlayer1 then
		match.HP2 = math.max(0, match.HP2 - baseDamage)
	else
		match.HP1 = math.max(0, match.HP1 - baseDamage)
	end

	-- Sync HP to both players
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local pvpSync = remoteEvents:FindFirstChild("PvPSync")
		if pvpSync then
			local syncData = { HP1 = match.HP1, HP2 = match.HP2, LastAttacker = player.Name, Damage = baseDamage }
			pvpSync:FireClient(match.Player1, syncData)
			pvpSync:FireClient(match.Player2, syncData)
		end
	end

	-- Check for KO
	if match.HP1 <= 0 then
		PvPService.EndMatch(matchId, match.Player2, match.Player1)
	elseif match.HP2 <= 0 then
		PvPService.EndMatch(matchId, match.Player1, match.Player2)
	end
end

function PvPService.CheckMatchTimers()
	local now = os.time()
	for matchId, match in pairs(ActiveMatches) do
		if now - match.StartTime >= GameConfig.PvP.MatchDuration then
			-- Time's up - player with more HP wins
			if match.HP1 > match.HP2 then
				PvPService.EndMatch(matchId, match.Player1, match.Player2)
			elseif match.HP2 > match.HP1 then
				PvPService.EndMatch(matchId, match.Player2, match.Player1)
			else
				-- Draw - both get small reward
				PvPService.EndMatch(matchId, nil, nil, true)
			end
		end
	end
end

function PvPService.EndMatch(matchId, winner, loser, isDraw)
	local match = ActiveMatches[matchId]
	if not match then return end

	ActiveMatches[matchId] = nil

	if isDraw then
		-- Both get lose reward
		if match.Player1.Parent then
			PvPService.DataService.AddCoins(match.Player1, GameConfig.PvP.LoseRewardCoins)
			PlayerCooldowns[match.Player1.UserId] = os.time()
		end
		if match.Player2.Parent then
			PvPService.DataService.AddCoins(match.Player2, GameConfig.PvP.LoseRewardCoins)
			PlayerCooldowns[match.Player2.UserId] = os.time()
		end
		return
	end

	if winner and winner.Parent then
		local winnerData = PvPService.DataService.GetFullData(winner)
		if winnerData then
			winnerData.PvPWins = winnerData.PvPWins + 1
			winnerData.PvPRating = winnerData.PvPRating + 25
			PvPService.DataService.AddCoins(winner, GameConfig.PvP.WinRewardCoins)
		end
		PlayerCooldowns[winner.UserId] = os.time()

		-- Quest progress
		local QuestService = require(ServerScriptService.Services.QuestService)
		QuestService.UpdateProgress(winner, "PvPWins", nil, 1)
	end

	if loser and loser.Parent then
		local loserData = PvPService.DataService.GetFullData(loser)
		if loserData then
			loserData.PvPLosses = loserData.PvPLosses + 1
			loserData.PvPRating = math.max(0, loserData.PvPRating - 15)
			PvPService.DataService.AddCoins(loser, GameConfig.PvP.LoseRewardCoins)
		end
		PlayerCooldowns[loser.UserId] = os.time()
	end

	-- Notify both
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local pvpEnd = remoteEvents:FindFirstChild("PvPMatchEnd")
		if pvpEnd then
			if winner and winner.Parent then
				pvpEnd:FireClient(winner, { Result = "Win", Coins = GameConfig.PvP.WinRewardCoins })
			end
			if loser and loser.Parent then
				pvpEnd:FireClient(loser, { Result = "Lose", Coins = GameConfig.PvP.LoseRewardCoins })
			end
		end
	end
end

function PvPService.GetTier(rating)
	local tier = GameConfig.PvP.RankedTiers[1]
	for _, t in ipairs(GameConfig.PvP.RankedTiers) do
		if rating >= t.MinRating then
			tier = t
		end
	end
	return tier
end

return PvPService
