--[[
	StaffService.lua - Restaurant Empire
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local StaffService = {}

function StaffService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("HireStaff").OnServerEvent:Connect(function(player, staffName)
		if type(staffName) ~= "string" then return end
		local data = DS.GetFullData(player); if not data then return end
		local cfg = nil
		for _, s in ipairs(GC.Staff) do if s.Name == staffName then cfg = s; break end end
		if not cfg then return end
		if not DS.SpendCoins(player, cfg.Cost) then return end
		table.insert(data.Staff, { Name = cfg.Name, Type = cfg.Type, Skill = cfg.Skill })
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then local ss = reEvents:FindFirstChild("StaffSync"); if ss then ss:FireClient(player, data.Staff) end end
	end)

	re:WaitForChild("FireStaff").OnServerEvent:Connect(function(player, index)
		if type(index) ~= "number" then return end
		local data = DS.GetFullData(player); if not data then return end
		if index >= 1 and index <= #data.Staff then table.remove(data.Staff, index) end
	end)

	re:WaitForChild("GetStaff").OnServerEvent:Connect(function(player)
		local data = DS.GetFullData(player); if not data then return end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then local ss = reEvents:FindFirstChild("StaffSync"); if ss then ss:FireClient(player, data.Staff) end end
	end)
end

return StaffService
