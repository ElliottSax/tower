--[[
	SecurityManager.lua - Dungeon Doors
]]
local Players = game:GetService("Players")
local SecurityManager = {}
local RATE_LIMITS = { VoteDoor = { MaxPerMinute = 30, Cooldown = 1 }, BuyUpgrade = { MaxPerMinute = 10, Cooldown = 2 }, StartRun = { MaxPerMinute = 5, Cooldown = 5 } }
local PlayerActions = {}

function SecurityManager.Init()
	Players.PlayerAdded:Connect(function(p) PlayerActions[p.UserId] = {} end)
	Players.PlayerRemoving:Connect(function(p) PlayerActions[p.UserId] = nil end)
end

function SecurityManager.CheckRateLimit(player, actionName)
	local limit = RATE_LIMITS[actionName]; if not limit then return true end
	local actions = PlayerActions[player.UserId]; if not actions then return false end
	local ad = actions[actionName]
	if not ad then actions[actionName] = { Count = 1, LastReset = os.time(), LastAction = os.time() }; return true end
	local now = os.time()
	if now - ad.LastReset >= 60 then ad.Count = 0; ad.LastReset = now end
	if now - ad.LastAction < limit.Cooldown then return false end
	if ad.Count >= limit.MaxPerMinute then return false end
	ad.Count = ad.Count + 1; ad.LastAction = now; return true
end

return SecurityManager
