--[[
	RemoteEventsInit.lua - Speed Run Universe
	Creates all RemoteEvent and RemoteFunction instances used for client-server communication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEventsInit = {}

local REMOTE_EVENTS = {
	-- Speedrun / Timer
	"StartSpeedrun",       -- Client -> Server: player begins a stage or world run
	"StopSpeedrun",        -- Client -> Server: player finishes a run
	"SpeedrunUpdate",      -- Server -> Client: timer ticks, split times
	"SpeedrunComplete",    -- Server -> Client: run finished, results
	"NewPersonalBest",     -- Server -> Client: celebrate a new PB

	-- Stages / Checkpoints
	"CheckpointReached",   -- Client -> Server: player touched a checkpoint
	"StageComplete",       -- Server -> Client: stage finished
	"WorldComplete",       -- Server -> Client: all stages in world finished
	"TeleportToStage",     -- Client -> Server: request teleport to a stage
	"StageSync",           -- Server -> Client: sync stage/world progress

	-- Coins
	"CoinCollected",       -- Client -> Server: player collected a coin
	"CoinSync",            -- Server -> Client: update coin count

	-- Abilities
	"UnlockAbility",       -- Server -> Client: ability unlocked notification
	"EquipAbility",        -- Client -> Server: equip/unequip ability
	"UseAbility",          -- Client -> Server: ability activation (for validation)
	"AbilitySync",         -- Server -> Client: sync ability state

	-- Cosmetics
	"BuyTrail",            -- Client -> Server: purchase trail
	"EquipTrail",          -- Client -> Server: equip trail
	"BuyWinEffect",        -- Client -> Server: purchase win effect
	"EquipWinEffect",      -- Client -> Server: equip win effect
	"CosmeticSync",        -- Server -> Client: sync cosmetics state
	"PlayWinEffect",       -- Server -> All Clients: show a player's win effect

	-- Ghosts
	"StartGhostRecord",    -- Server internal: begin recording ghost
	"StopGhostRecord",     -- Server internal: stop recording ghost
	"RequestGhost",        -- Client -> Server: request ghost data for a stage
	"GhostData",           -- Server -> Client: send ghost replay data
	"ToggleGhosts",        -- Client -> Server: toggle ghost visibility

	-- Leaderboards
	"RequestLeaderboard",  -- Client -> Server: request leaderboard data
	"LeaderboardData",     -- Server -> Client: send leaderboard entries

	-- Challenges
	"RequestChallenges",   -- Client -> Server: request current challenges
	"ChallengeSync",       -- Server -> Client: sync challenge progress
	"ChallengeComplete",   -- Server -> Client: challenge completed
	"ClaimChallengeReward", -- Client -> Server: claim reward

	-- Tournament
	"RequestTournament",   -- Client -> Server: get tournament info
	"TournamentSync",      -- Server -> Client: tournament status/leaderboard
	"TournamentComplete",  -- Server -> Client: tournament ended, prizes

	-- Monetization
	"GetShopData",         -- Client -> Server: request shop data
	"ShopData",            -- Server -> Client: shop data response
	"PurchaseGamePass",    -- Client -> Server: initiate gamepass purchase
	"PurchaseDevProduct",  -- Client -> Server: initiate dev product purchase

	-- Daily Reward
	"DailyReward",         -- Server -> Client: daily reward notification

	-- World unlock
	"UnlockWorld",         -- Client -> Server: attempt to unlock a world
	"WorldUnlocked",       -- Server -> Client: world unlock confirmed

	-- General UI
	"Notification",        -- Server -> Client: push notification to player
	"PlayerDied",          -- Server -> Client: death event for stats

	-- Settings
	"UpdateSettings",      -- Client -> Server: update player settings (volume, toggles)
}

local REMOTE_FUNCTIONS = {
	"GetPlayerData",       -- Client -> Server: request full player data
	"GetWorldTimes",       -- Client -> Server: request personal bests for a world
	"GetGhostList",        -- Client -> Server: get available ghost keys
}

function RemoteEventsInit.Init()
	-- Create RemoteEvents folder
	local eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "RemoteEvents"
	eventsFolder.Parent = ReplicatedStorage

	for _, name in ipairs(REMOTE_EVENTS) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = eventsFolder
	end

	-- Create RemoteFunctions folder
	local functionsFolder = Instance.new("Folder")
	functionsFolder.Name = "RemoteFunctions"
	functionsFolder.Parent = ReplicatedStorage

	for _, name in ipairs(REMOTE_FUNCTIONS) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = functionsFolder
	end

	print("[RemoteEventsInit] Created", #REMOTE_EVENTS, "events and", #REMOTE_FUNCTIONS, "functions")
end

return RemoteEventsInit
