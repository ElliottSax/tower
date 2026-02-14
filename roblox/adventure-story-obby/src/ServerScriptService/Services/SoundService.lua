--[[
	SoundService.lua
	Manages game audio (music and sound effects)

	Features:
	- Background music system
	- Sound effect playback
	- Volume control
	- Crossfading between tracks
	- Per-world music themes
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SoundService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MUSIC_TRACKS = {
	Hub = {
		Name = "Hub Theme",
		SoundId = "rbxassetid://1837879082", -- Placeholder
		Volume = 0.3,
		Looped = true,
	},

	World1 = {
		Name = "Mystic Forest",
		SoundId = "rbxassetid://1838673350", -- Placeholder
		Volume = 0.4,
		Looped = true,
	},

	World2 = {
		Name = "Crystal Caves",
		SoundId = "rbxassetid://1838673350", -- Placeholder (future)
		Volume = 0.4,
		Looped = true,
	},

	Boss = {
		Name = "Boss Battle",
		SoundId = "rbxassetid://1838818279", -- Placeholder
		Volume = 0.5,
		Looped = true,
	},

	Victory = {
		Name = "Victory",
		SoundId = "rbxassetid://1838849823", -- Placeholder
		Volume = 0.4,
		Looped = false,
	},
}

local SOUND_EFFECTS = {
	LevelComplete = "rbxassetid://6895079853",
	QuestComplete = "rbxassetid://6895079853",
	CoinCollect = "rbxasset://sounds/electronicpingshort.wav",
	FragmentCollect = "rbxassetid://6895079853",
	Checkpoint = "rbxasset://sounds/Notification.mp3",
	ButtonClick = "rbxasset://sounds/button.wav",
	Error = "rbxasset://sounds/SWITCH2.wav",
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SoundService.Init()
	print("[SoundService] Initializing...")

	-- Setup remote handlers
	SoundService.SetupRemoteHandlers()

	print("[SoundService] Initialized")
end

-- ============================================================================
-- MUSIC CONTROL
-- ============================================================================

function SoundService.PlayMusic(player: Player, trackName: string)
	local track = MUSIC_TRACKS[trackName]
	if not track then
		warn("[SoundService] Unknown music track:", trackName)
		return
	end

	-- Send to client to play
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local playMusicRemote = RemoteEventsInit.GetRemote("PlayMusic")

	if playMusicRemote and playMusicRemote.Remote then
		playMusicRemote.Remote:FireClient(player, trackName, track)
	end

	print(string.format("[SoundService] Playing '%s' for %s", track.Name, player.Name))
end

function SoundService.StopMusic(player: Player)
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local stopMusicRemote = RemoteEventsInit.GetRemote("StopMusic")

	if stopMusicRemote and stopMusicRemote.Remote then
		stopMusicRemote.Remote:FireClient(player)
	end
end

function SoundService.SetMusicVolume(player: Player, volume: number)
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local setMusicVolumeRemote = RemoteEventsInit.GetRemote("SetMusicVolume")

	if setMusicVolumeRemote and setMusicVolumeRemote.Remote then
		setMusicVolumeRemote.Remote:FireClient(player, volume)
	end
end

-- ============================================================================
-- SOUND EFFECTS
-- ============================================================================

function SoundService.PlaySound(player: Player, soundName: string, volume: number?)
	local soundId = SOUND_EFFECTS[soundName]
	if not soundId then
		warn("[SoundService] Unknown sound effect:", soundName)
		return
	end

	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local playSoundRemote = RemoteEventsInit.GetRemote("PlaySound")

	if playSoundRemote and playSoundRemote.Remote then
		playSoundRemote.Remote:FireClient(player, soundId, volume or 0.5)
	end
end

-- ============================================================================
-- CONTEXT-AWARE MUSIC
-- ============================================================================

function SoundService.PlayMusicForContext(player: Player, context: string)
	-- Play appropriate music based on game context
	if context == "Hub" then
		SoundService.PlayMusic(player, "Hub")
	elseif context:match("^World1") then
		-- Check if boss level
		if context:match("Level5$") then
			SoundService.PlayMusic(player, "Boss")
		else
			SoundService.PlayMusic(player, "World1")
		end
	elseif context:match("^World2") then
		SoundService.PlayMusic(player, "World2")
	end
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function SoundService.SetupRemoteHandlers()
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

	-- PlayMusic (Server → Client)
	local playMusicRemote = Instance.new("RemoteEvent")
	playMusicRemote.Name = "PlayMusic"
	playMusicRemote.Parent = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- StopMusic (Server → Client)
	local stopMusicRemote = Instance.new("RemoteEvent")
	stopMusicRemote.Name = "StopMusic"
	stopMusicRemote.Parent = ReplicatedStorage:FindFirstChild("RemoteEvents")

	-- SetMusicVolume (Server → Client)
	local setMusicVolumeRemote = Instance.new("RemoteEvent")
	setMusicVolumeRemote.Name = "SetMusicVolume"
	setMusicVolumeRemote.Parent = ReplicatedStorage:FindFirstChild("RemoteEvents")

	-- PlaySound (Server → Client)
	local playSoundRemote = Instance.new("RemoteEvent")
	playSoundRemote.Name = "PlaySound"
	playSoundRemote.Parent = ReplicatedStorage:FindFirstChild("RemoteEvents")

	print("[SoundService] Remote handlers setup complete")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return SoundService
