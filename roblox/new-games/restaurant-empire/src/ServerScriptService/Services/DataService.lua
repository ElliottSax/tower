--[[
	DataService.lua - Restaurant Empire
]]
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local GC = require(RS.Shared.Config.GameConfig)
local DataService = {}
local PD = {}
local ds = DSS:GetDataStore("RestaurantEmpire_v1")

function DataService.Init() end
function DataService.LoadPlayer(p)
	local ok, d = pcall(function() return ds:GetAsync("P_" .. p.UserId) end)
	if ok and d then for k,v in pairs(GC.DefaultData) do if d[k]==nil then d[k]=v end end; PD[p.UserId]=d
	else local n={}; for k,v in pairs(GC.DefaultData) do if type(v)=="table" then n[k]={}; for a,b in pairs(v) do n[k][a]=b end else n[k]=v end end; PD[p.UserId]=n end
end
function DataService.SavePlayer(p) local d=PD[p.UserId]; if d then pcall(function() ds:SetAsync("P_"..p.UserId,d) end) end end
function DataService.GetFullData(p) return PD[p.UserId] end
function DataService.AddCoins(p, amt)
	local d=PD[p.UserId]; if not d then return 0 end
	local m = 1 + d.PrestigeLevel * 0.3
	if d.GamePasses and d.GamePasses.DoubleTips then m = m * 2 end
	local f = math.floor(amt * m); d.Coins = d.Coins + f; d.TotalCoinsEarned = d.TotalCoinsEarned + f
	local ls=p:FindFirstChild("leaderstats"); if ls then local c=ls:FindFirstChild("Coins"); if c then c.Value=d.Coins end end
	return f
end
function DataService.SpendCoins(p, amt)
	local d=PD[p.UserId]; if not d or d.Coins<amt then return false end
	d.Coins=d.Coins-amt
	local ls=p:FindFirstChild("leaderstats"); if ls then local c=ls:FindFirstChild("Coins"); if c then c.Value=d.Coins end end
	return true
end
function DataService.AddXP(p, amt)
	local d=PD[p.UserId]; if not d then return end
	d.XP = d.XP + amt
	local needed = d.Level * 100
	while d.XP >= needed do d.XP = d.XP - needed; d.Level = d.Level + 1; needed = d.Level * 100
		-- Unlock recipes at level thresholds
		for _, r in ipairs(GC.Recipes) do
			if r.UnlockLevel == d.Level then
				local found = false
				for _, u in ipairs(d.UnlockedRecipes) do if u == r.Name then found = true; break end end
				if not found then table.insert(d.UnlockedRecipes, r.Name) end
			end
		end
	end
end

return DataService
