--[[
	RestaurantService.lua - Restaurant Empire
	Building, furniture placement, location management
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local RestaurantService = {}

function RestaurantService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("PlaceFurniture").OnServerEvent:Connect(function(player, furnitureName, pos)
		if type(furnitureName) ~= "string" then return end
		local data = DS.GetFullData(player); if not data then return end
		local cfg = nil
		for _, f in ipairs(GC.Furniture) do if f.Name == furnitureName then cfg = f; break end end
		if not cfg then return end
		if not DS.SpendCoins(player, cfg.Cost) then return end
		table.insert(data.Furniture, { Name = cfg.Name, Type = cfg.Type, Position = pos })
		RestaurantService.SyncRestaurant(player)
	end)

	re:WaitForChild("RemoveFurniture").OnServerEvent:Connect(function(player, index)
		if type(index) ~= "number" then return end
		local data = DS.GetFullData(player); if not data then return end
		if index < 1 or index > #data.Furniture then return end
		table.remove(data.Furniture, index)
		RestaurantService.SyncRestaurant(player)
	end)

	re:WaitForChild("UnlockLocation").OnServerEvent:Connect(function(player, locationName)
		if type(locationName) ~= "string" then return end
		local data = DS.GetFullData(player); if not data then return end
		for _, loc in ipairs(GC.Locations) do
			if loc.Name == locationName then
				for _, u in ipairs(data.UnlockedLocations) do if u == locationName then return end end
				if DS.SpendCoins(player, loc.UnlockCost) then
					table.insert(data.UnlockedLocations, locationName)
				end
				return
			end
		end
	end)

	re:WaitForChild("GetRestaurant").OnServerEvent:Connect(function(player) RestaurantService.SyncRestaurant(player) end)
end

function RestaurantService.SyncRestaurant(player)
	local DS = require(SSS.Services.DataService)
	local data = DS.GetFullData(player); if not data then return end
	local re = RS:FindFirstChild("RemoteEvents")
	if re then local rs = re:FindFirstChild("RestaurantSync")
		if rs then rs:FireClient(player, { Furniture = data.Furniture, Location = data.CurrentLocation, Locations = GC.Locations, UnlockedLocations = data.UnlockedLocations }) end
	end
end

function RestaurantService.GetTableCount(player)
	local DS = require(SSS.Services.DataService)
	local data = DS.GetFullData(player); if not data then return 0 end
	local count = 0
	for _, f in ipairs(data.Furniture) do if f.Type == "table" then count = count + 1 end end
	return count
end

return RestaurantService
