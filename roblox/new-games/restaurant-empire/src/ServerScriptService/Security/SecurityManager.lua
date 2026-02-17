local Players = game:GetService("Players")
local S = {}; local PA = {}
function S.Init() Players.PlayerAdded:Connect(function(p) PA[p.UserId]={} end); Players.PlayerRemoving:Connect(function(p) PA[p.UserId]=nil end) end
function S.CheckRateLimit(p,a) return true end
return S
