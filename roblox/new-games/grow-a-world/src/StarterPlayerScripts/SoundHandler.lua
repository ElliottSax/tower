--[[
	SoundHandler.lua - Grow a World
	Client-side sound effects and ambient music
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundHandler = {}

local sounds = {}
local currentMusic = nil

local SOUND_IDS = {
	-- UI sounds
	ButtonClick = "rbxassetid://0",
	ButtonHover = "rbxassetid://0",
	Purchase = "rbxassetid://0",
	Error = "rbxassetid://0",

	-- Garden sounds
	Plant = "rbxassetid://0",
	Water = "rbxassetid://0",
	Harvest = "rbxassetid://0",
	GrowComplete = "rbxassetid://0",

	-- Reward sounds
	CoinCollect = "rbxassetid://0",
	LevelUp = "rbxassetid://0",
	Prestige = "rbxassetid://0",
	RareSeed = "rbxassetid://0",
	DailyReward = "rbxassetid://0",

	-- Pack opening
	PackOpen = "rbxassetid://0",
	PackReveal = "rbxassetid://0",

	-- Trade
	TradeRequest = "rbxassetid://0",
	TradeComplete = "rbxassetid://0",
}

local MUSIC_IDS = {
	Meadow = "rbxassetid://0",
	Desert = "rbxassetid://0",
	Swamp = "rbxassetid://0",
	Mountain = "rbxassetid://0",
	Crystal = "rbxassetid://0",
	Volcanic = "rbxassetid://0",
	Cloud = "rbxassetid://0",
	Void = "rbxassetid://0",
}

function SoundHandler.Init()
	-- Pre-create sound instances
	local sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "SFX"
	sfxGroup.Volume = 0.8
	sfxGroup.Parent = SoundService

	local musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "Music"
	musicGroup.Volume = 0.4
	musicGroup.Parent = SoundService

	for name, id in pairs(SOUND_IDS) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.SoundGroup = sfxGroup
		sound.Parent = SoundService
		sounds[name] = sound
	end

	-- Listen for remote events to trigger sounds
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GardenUpdate").OnClientEvent:Connect(function(action)
		if action == "planted" then
			SoundHandler.Play("Plant")
		elseif action == "watered" then
			SoundHandler.Play("Water")
		elseif action == "harvested" then
			SoundHandler.Play("Harvest")
		end
	end)

	remoteEvents:WaitForChild("SeedPackResult").OnClientEvent:Connect(function()
		SoundHandler.Play("PackOpen")
	end)

	remoteEvents:WaitForChild("DailyReward").OnClientEvent:Connect(function()
		SoundHandler.Play("DailyReward")
	end)

	remoteEvents:WaitForChild("PrestigeComplete").OnClientEvent:Connect(function()
		SoundHandler.Play("Prestige")
	end)

	remoteEvents:WaitForChild("TradeRequest").OnClientEvent:Connect(function()
		SoundHandler.Play("TradeRequest")
	end)

	remoteEvents:WaitForChild("TradeComplete").OnClientEvent:Connect(function()
		SoundHandler.Play("TradeComplete")
	end)

	print("[SoundHandler] Initialized")
end

function SoundHandler.Play(soundName)
	local sound = sounds[soundName]
	if sound then
		sound:Play()
	end
end

function SoundHandler.PlayMusic(biomeName)
	local musicId = MUSIC_IDS[biomeName]
	if not musicId then return end

	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
	end

	local music = Instance.new("Sound")
	music.Name = "BiomeMusic"
	music.SoundId = musicId
	music.Looped = true
	music.Volume = 0
	music.SoundGroup = SoundService:FindFirstChild("Music")
	music.Parent = SoundService

	music:Play()

	-- Fade in
	local TweenService = game:GetService("TweenService")
	TweenService:Create(music, TweenInfo.new(2), { Volume = 0.4 }):Play()

	currentMusic = music
end

function SoundHandler.StopMusic()
	if currentMusic then
		local TweenService = game:GetService("TweenService")
		TweenService:Create(currentMusic, TweenInfo.new(1), { Volume = 0 }):Play()
		task.delay(1, function()
			if currentMusic then
				currentMusic:Stop()
				currentMusic:Destroy()
				currentMusic = nil
			end
		end)
	end
end

SoundHandler.Init()

return SoundHandler
