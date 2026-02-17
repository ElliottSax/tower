--[[
	PuzzleService.lua - Escape the Factory
	Manages room puzzles (button sequences, color matching, etc.)
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local PuzzleService = {}

local activePuzzles = {}

function PuzzleService.Init()
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("RequestPuzzle").OnServerEvent:Connect(function(player, roomNumber)
		if type(roomNumber) ~= "number" then return end
		local FactoryService = require(SSS.Services.FactoryService)
		local run = FactoryService.GetRun(player); if not run then return end

		-- Generate a puzzle based on factory difficulty
		local factoryCfg = nil
		for _, f in ipairs(GC.Factories) do if f.Name == run.Factory then factoryCfg = f; break end end
		local difficulty = factoryCfg and factoryCfg.Difficulty or 1

		local puzzleType = GC.PuzzleTypes[math.random(#GC.PuzzleTypes)]
		local puzzle = PuzzleService.GeneratePuzzle(puzzleType, difficulty)

		activePuzzles[player.UserId] = {
			Type = puzzleType,
			Solution = puzzle.Solution,
			StartTime = tick(),
		}

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local pu = reEvents:FindFirstChild("PuzzleUpdate")
			if pu then pu:FireClient(player, {
				Type = "PuzzleStart",
				PuzzleType = puzzleType,
				Data = puzzle.ClientData,
				TimeLimit = 30 + (10 - difficulty) * 5,
			}) end
		end
	end)

	re:WaitForChild("SolvePuzzle").OnServerEvent:Connect(function(player, answer)
		local puzzle = activePuzzles[player.UserId]; if not puzzle then return end
		local elapsed = tick() - puzzle.StartTime
		local reEvents = RS:FindFirstChild("RemoteEvents")

		local correct = PuzzleService.CheckAnswer(puzzle, answer)
		activePuzzles[player.UserId] = nil

		if correct then
			local DS = require(SSS.Services.DataService)
			local bonus = math.floor(50 / math.max(1, elapsed / 10))
			local FactoryService = require(SSS.Services.FactoryService)
			FactoryService.CollectCoin(player, bonus)

			if reEvents then
				local pu = reEvents:FindFirstChild("PuzzleUpdate")
				if pu then pu:FireClient(player, { Type = "PuzzleSolved", Bonus = bonus, Time = elapsed }) end
			end
		else
			if reEvents then
				local pu = reEvents:FindFirstChild("PuzzleUpdate")
				if pu then pu:FireClient(player, { Type = "PuzzleFailed" }) end
			end
		end
	end)
end

function PuzzleService.GeneratePuzzle(puzzleType, difficulty)
	local length = math.min(3 + difficulty, 8)

	if puzzleType == "ButtonSequence" then
		local seq = {}
		for i = 1, length do table.insert(seq, math.random(1, 4)) end
		return { Solution = seq, ClientData = { Length = length, Buttons = 4 } }

	elseif puzzleType == "ColorMatch" then
		local colors = { "Red", "Blue", "Green", "Yellow", "Purple", "Orange" }
		local target = {}
		for i = 1, length do table.insert(target, colors[math.random(#colors)]) end
		return { Solution = target, ClientData = { Target = target, Colors = colors } }

	elseif puzzleType == "SimonSays" then
		local seq = {}
		for i = 1, length do table.insert(seq, math.random(1, 4)) end
		return { Solution = seq, ClientData = { Sequence = seq, Speed = 1.0 - (difficulty * 0.08) } }

	elseif puzzleType == "CodeCrack" then
		local code = {}
		for i = 1, math.min(4, 2 + math.floor(difficulty / 2)) do table.insert(code, math.random(0, 9)) end
		return { Solution = code, ClientData = { Length = #code, MaxDigit = 9 } }

	else
		-- Default simple puzzle
		local answer = math.random(1, 4)
		return { Solution = { answer }, ClientData = { Options = 4 } }
	end
end

function PuzzleService.CheckAnswer(puzzle, answer)
	if type(answer) ~= "table" and type(answer) ~= "number" then return false end
	local sol = puzzle.Solution
	if type(answer) == "number" then return answer == sol[1] end
	if #answer ~= #sol then return false end
	for i, v in ipairs(sol) do
		if answer[i] ~= v then return false end
	end
	return true
end

return PuzzleService
