--[[
	RemoteEventsInit.lua
	Pet Collector Simulator - Remote Event Initialization

	Creates all RemoteEvents and RemoteFunctions for client-server communication.
	MUST RUN FIRST before any other services!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsInit = {}
RemoteEventsInit.Remotes = {}

-- ============================================================================
-- REMOTE EVENT LIST
-- ============================================================================

local REMOTE_EVENTS = {
	-- Data Service
	"UpdateClientData",
	"GetPlayerData",

	-- Pet Service
	"HatchEgg",
	"EquipPet",
	"UnequipPet",
	"DeletePet",
	"GetEquippedPets",

	-- Monetization Service
	"PurchaseProduct",
	"CheckGamePass",
	"GetVIPBenefits",

	-- World Service
	"UnlockWorld",
	"TeleportToWorld",
	"GetUnlockedWorlds",
	"GetCurrentWorld",

	-- Coin Service
	"CollectCoin",
	"AddCoins",
	"CoinUpdate",
	"GetCoins",

	-- Notification System
	"ShowNotification",

	-- Settings
	"GetSetting",
	"SetSetting",
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RemoteEventsInit.Initialize()
	print("[RemoteEventsInit] Creating RemoteEvents...")

	-- Create RemoteEvents folder
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create RemoteEvents
	for _, eventName in ipairs(REMOTE_EVENTS) do
		local existingRemote = remoteFolder:FindFirstChild(eventName)
		if not existingRemote then
			-- Determine if RemoteEvent or RemoteFunction
			local isFunction = eventName:match("^Get") or eventName:match("^Check") or eventName:match("Has")

			local remote
			if isFunction then
				remote = Instance.new("RemoteFunction")
			else
				remote = Instance.new("RemoteEvent")
			end

			remote.Name = eventName
			remote.Parent = remoteFolder

			RemoteEventsInit.Remotes[eventName] = remote

			print(string.format("[RemoteEventsInit] Created %s: %s",
				isFunction and "RemoteFunction" or "RemoteEvent", eventName))
		else
			RemoteEventsInit.Remotes[eventName] = existingRemote
		end
	end

	print(string.format("[RemoteEventsInit] ✅ Initialized %d remotes", #REMOTE_EVENTS))
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function RemoteEventsInit.GetRemote(remoteName: string)
	return RemoteEventsInit.Remotes[remoteName]
end

return RemoteEventsInit
