--[[
	Main.server.lua - Battle Royale Legends
	Server entry point - initializes all services
]]
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Initialize utilities first
local RemoteEventsInit = require(SSS.Utilities.RemoteEventsInit)
RemoteEventsInit.Init()

-- Initialize core services
local SecurityManager = require(SSS.Security.SecurityManager)
SecurityManager.Init()

local DataService = require(SSS.Services.DataService)
DataService.Init()

local LootService = require(SSS.Services.LootService)
LootService.Init()

local MatchService = require(SSS.Services.MatchService)
MatchService.Init()

local CombatService = require(SSS.Services.CombatService)
CombatService.Init()

local BuildService = require(SSS.Services.BuildService)
BuildService.Init()

local StormService = require(SSS.Services.StormService)
StormService.Init()

local RankService = require(SSS.Services.RankService)
RankService.Init()

local ShopService = require(SSS.Services.ShopService)
ShopService.Init()

local MonetizationService = require(SSS.Services.Monetization.MonetizationService)
MonetizationService.Init()

print("[Battle Royale Legends] All services initialized!")
