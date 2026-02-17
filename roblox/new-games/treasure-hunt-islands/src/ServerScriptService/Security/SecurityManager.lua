local Players = game:GetService("Players")
local SecurityManager = {}
local PA = {}
local RL = { Dig = { M = 60, C = 0.5 }, BuyTool = { M = 10, C = 2 }, FightPirate = { M = 20, C = 3 } }

function SecurityManager.Init()
	Players.PlayerAdded:Connect(function(p) PA[p.UserId] = {} end)
	Players.PlayerRemoving:Connect(function(p) PA[p.UserId] = nil end)
end

function SecurityManager.CheckRateLimit(player, action)
	local limit = RL[action]; if not limit then return true end
	local a = PA[player.UserId]; if not a then return false end
	local d = a[action]
	if not d then a[action] = { C = 1, R = os.time(), L = os.time() }; return true end
	local n = os.time()
	if n - d.R >= 60 then d.C = 0; d.R = n end
	if n - d.L < limit.C then return false end
	if d.C >= limit.M then return false end
	d.C = d.C + 1; d.L = n; return true
end

return SecurityManager
