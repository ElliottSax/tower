--[[
	ShipService.lua - Treasure Hunt Islands
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local ShipService = {}

function ShipService.Init()
	local DataService = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("BuyShip").OnServerEvent:Connect(function(player, shipName)
		if type(shipName) ~= "string" then return end
		local data = DataService.GetFullData(player); if not data then return end
		for _, ship in ipairs(GameConfig.Ships) do
			if ship.Name == shipName then
				if DataService.SpendCoins(player, ship.Cost) then
					data.CurrentShip = shipName
					local reEvents = RS:FindFirstChild("RemoteEvents")
					if reEvents then local sr = reEvents:FindFirstChild("ShipChanged"); if sr then sr:FireClient(player, shipName) end end
				end
				return
			end
		end
	end)

	re:WaitForChild("HireCrew").OnServerEvent:Connect(function(player, crewName)
		if type(crewName) ~= "string" then return end
		local data = DataService.GetFullData(player); if not data then return end
		for _, crew in ipairs(GameConfig.Crew) do
			if crew.Name == crewName then
				for _, c in ipairs(data.Crew) do if c == crewName then return end end -- Already hired
				if DataService.SpendCoins(player, crew.Cost) then
					table.insert(data.Crew, crewName)
				end
				return
			end
		end
	end)

	re:WaitForChild("GetShipInfo").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player); if not data then return end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local si = reEvents:FindFirstChild("ShipInfo")
			if si then si:FireClient(player, { Ship = data.CurrentShip, Crew = data.Crew, Ships = GameConfig.Ships, CrewOptions = GameConfig.Crew }) end
		end
	end)
end

return ShipService
