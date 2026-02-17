--[[
	SecurityManager.lua - Escape the Factory
	Rate limiting and anti-exploit checks
]]
local Players = game:GetService("Players")
local S = {}
local PA = {}
local LIMITS = { TrapHit = { Max = 5, Window = 1 }, BuyUpgrade = { Max = 3, Window = 2 }, CompleteRoom = { Max = 2, Window = 3 } }

function S.Init()
	Players.PlayerAdded:Connect(function(p) PA[p.UserId] = {} end)
	Players.PlayerRemoving:Connect(function(p) PA[p.UserId] = nil end)
end

function S.CheckRateLimit(player, action)
	local data = PA[player.UserId]; if not data then return false end
	local limit = LIMITS[action]; if not limit then return true end
	local now = tick()
	if not data[action] then data[action] = {} end
	local times = data[action]
	while #times > 0 and (now - times[1]) > limit.Window do table.remove(times, 1) end
	if #times >= limit.Max then return false end
	table.insert(times, now)
	return true
end

return S
