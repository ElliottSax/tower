--[[
	Main.server.lua - Escape the Factory
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

local FactoryService = require(SSS.Services.FactoryService)
FactoryService.Init()

local TrapService = require(SSS.Services.TrapService)
TrapService.Init()

local PuzzleService = require(SSS.Services.PuzzleService)
PuzzleService.Init()

local UpgradeService = require(SSS.Services.UpgradeService)
UpgradeService.Init()

local CompanionService = require(SSS.Services.CompanionService)
CompanionService.Init()

local DailyRewardService = require(SSS.Services.DailyRewardService)
DailyRewardService.Init()

local MonetizationService = require(SSS.Services.Monetization.MonetizationService)
MonetizationService.Init()

print("[Escape the Factory] All services initialized!")
