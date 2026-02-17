--[[
	RemoteEventsInit.lua - Merge Mania
	Creates all RemoteEvents and RemoteFunctions for client-server communication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsInit = {}

local REMOTE_EVENTS = {
	-- Grid & Merge
	"MergeItems",       -- Client -> Server: request merge at two positions
	"MoveItem",         -- Client -> Server: move item to new grid position
	"SellItem",         -- Client -> Server: sell item for coins
	"GridUpdate",       -- Server -> Client: full grid state sync
	"GridCellUpdate",   -- Server -> Client: single cell update
	"MergeResult",      -- Server -> Client: result of merge attempt (success/fail/golden)

	-- Generators
	"BuyGenerator",     -- Client -> Server: purchase a generator
	"UpgradeGenerator", -- Client -> Server: upgrade generator speed
	"GeneratorSpawn",   -- Server -> Client: generator spawned an item
	"GeneratorList",    -- Server -> Client: list of owned generators
	"GetGenerators",    -- Client -> Server: request generator list

	-- Earnings
	"EarningsUpdate",   -- Server -> Client: periodic earnings update (coins/sec, total)
	"CollectOffline",   -- Client -> Server: collect offline earnings
	"OfflineEarnings",  -- Server -> Client: offline earnings info on join
	"GetEarnings",      -- Client -> Server: request current earnings info

	-- Collections
	"CollectionUpdate",   -- Server -> Client: collection progress update
	"CollectionComplete", -- Server -> Client: collection completed notification
	"GetCollections",     -- Client -> Server: request collection data

	-- Prestige
	"Prestige",         -- Client -> Server: perform prestige
	"GetPrestigeInfo",  -- Client -> Server: request prestige info
	"PrestigeInfo",     -- Server -> Client: prestige data
	"PrestigeComplete", -- Server -> Client: prestige completed

	-- Monetization
	"GetShopData",         -- Client -> Server: request shop info
	"ShopData",            -- Server -> Client: shop data
	"PurchaseGamePass",    -- Client -> Server: prompt game pass purchase
	"PurchaseDevProduct",  -- Client -> Server: prompt dev product purchase

	-- Merge Paths
	"UnlockPath",       -- Client -> Server: unlock a merge path
	"PathUnlocked",     -- Server -> Client: path unlock confirmation
	"GetPathInfo",      -- Client -> Server: request path info

	-- Events
	"GetEventInfo",     -- Client -> Server: request active event info
	"EventInfo",        -- Server -> Client: event data
	"EventReward",      -- Server -> Client: event reward granted

	-- General
	"Notification",     -- Server -> Client: show notification
	"PlayerStats",      -- Server -> Client: player stats update (coins, prestige, etc.)
}

local REMOTE_FUNCTIONS = {
	"GetGridState",     -- Client -> Server: get full grid state (returns data)
	"GetPlayerData",    -- Client -> Server: get player stats
}

function RemoteEventsInit.Init()
	print("[RemoteEventsInit] Creating", #REMOTE_EVENTS, "remote events and", #REMOTE_FUNCTIONS, "remote functions...")

	-- Create RemoteEvents folder
	local eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "RemoteEvents"
	eventsFolder.Parent = ReplicatedStorage

	for _, eventName in ipairs(REMOTE_EVENTS) do
		local event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = eventsFolder
	end

	-- Create RemoteFunctions folder
	local funcsFolder = Instance.new("Folder")
	funcsFolder.Name = "RemoteFunctions"
	funcsFolder.Parent = ReplicatedStorage

	for _, funcName in ipairs(REMOTE_FUNCTIONS) do
		local func = Instance.new("RemoteFunction")
		func.Name = funcName
		func.Parent = funcsFolder
	end

	print("[RemoteEventsInit] Created all remote events and functions")
end

return RemoteEventsInit
