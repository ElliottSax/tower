--[[
	BuildService.lua - Battle Royale Legends
	Player building system - walls, ramps, floors
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local BuildService = {}

local playerMaterials = {}
local builtPieces = {}

function BuildService.Init()
	local Players = game:GetService("Players")
	local re = RS:WaitForChild("RemoteEvents")

	Players.PlayerAdded:Connect(function(p)
		playerMaterials[p.UserId] = { Wood = 0, Stone = 0, Metal = 0 }
	end)
	Players.PlayerRemoving:Connect(function(p) playerMaterials[p.UserId] = nil end)

	re:WaitForChild("Build").OnServerEvent:Connect(function(player, pieceName, material, position, rotation)
		if type(pieceName) ~= "string" or type(material) ~= "string" then return end

		local pieceCfg = nil
		for _, bp in ipairs(GC.BuildPieces) do if bp.Name == pieceName then pieceCfg = bp; break end end
		if not pieceCfg then return end

		local mats = playerMaterials[player.UserId]; if not mats then return end
		if not mats[material] or mats[material] < pieceCfg.Cost then
			local reEvents = RS:FindFirstChild("RemoteEvents")
			if reEvents then
				local bu = reEvents:FindFirstChild("BuildUpdate")
				if bu then bu:FireClient(player, { Type = "Error", Message = "Not enough " .. material }) end
			end
			return
		end

		mats[material] = mats[material] - pieceCfg.Cost

		local pieceId = player.UserId .. "_" .. tick()
		builtPieces[pieceId] = {
			Owner = player.UserId,
			Piece = pieceName,
			Material = material,
			HP = pieceCfg.HP,
			MaxHP = pieceCfg.HP,
		}

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local bu = reEvents:FindFirstChild("BuildUpdate")
			if bu then bu:FireAllClients({ Type = "Built", PieceId = pieceId, Piece = pieceName, Material = material, Position = position, Rotation = rotation }) end
		end
	end)

	re:WaitForChild("DestroyPiece").OnServerEvent:Connect(function(player, pieceId)
		if type(pieceId) ~= "string" then return end
		local piece = builtPieces[pieceId]; if not piece then return end
		piece.HP = piece.HP - 50
		if piece.HP <= 0 then
			builtPieces[pieceId] = nil
			local reEvents = RS:FindFirstChild("RemoteEvents")
			if reEvents then
				local bu = reEvents:FindFirstChild("BuildUpdate")
				if bu then bu:FireAllClients({ Type = "Destroyed", PieceId = pieceId }) end
			end
		end
	end)
end

function BuildService.AddMaterials(player, materialName, amount)
	local mats = playerMaterials[player.UserId]; if not mats then return end
	if mats[materialName] then
		mats[materialName] = math.min(999, mats[materialName] + amount)
	end
end

function BuildService.GetMaterials(player) return playerMaterials[player.UserId] end

function BuildService.ClearAllPieces()
	builtPieces = {}
end

return BuildService
