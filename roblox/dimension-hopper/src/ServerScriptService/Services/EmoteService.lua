--[[
	EmoteService.lua
	Manages player emotes and celebrations

	Features:
	- Play emotes/animations
	- Emote wheel
	- Victory celebrations
	- Unlockable emotes
	- Emote cooldowns
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoteService = {}

-- ============================================================================
-- EMOTE DEFINITIONS
-- ============================================================================

EmoteService.Emotes = {
	-- Free emotes
	wave = {
		id = "wave",
		name = "Wave",
		description = "A friendly wave",
		animationId = "rbxassetid://0", -- TODO: Add animation ID
		duration = 2,
		category = "Greetings",
		unlocked = true, -- Free for everyone
		icon = "👋",
	},
	clap = {
		id = "clap",
		name = "Clap",
		description = "Applause!",
		animationId = "rbxassetid://0",
		duration = 2.5,
		category = "Reactions",
		unlocked = true,
		icon = "👏",
	},
	thumbsup = {
		id = "thumbsup",
		name = "Thumbs Up",
		description = "Show your approval",
		animationId = "rbxassetid://0",
		duration = 1.5,
		category = "Reactions",
		unlocked = true,
		icon = "👍",
	},
	shrug = {
		id = "shrug",
		name = "Shrug",
		description = "Who knows?",
		animationId = "rbxassetid://0",
		duration = 2,
		category = "Reactions",
		unlocked = true,
		icon = "🤷",
	},

	-- Unlockable emotes
	dance1 = {
		id = "dance1",
		name = "Dance",
		description = "Show off your moves",
		animationId = "rbxassetid://0",
		duration = 4,
		category = "Dances",
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 5,
		icon = "💃",
	},
	dance2 = {
		id = "dance2",
		name = "Fancy Dance",
		description = "A fancier dance",
		animationId = "rbxassetid://0",
		duration = 5,
		category = "Dances",
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 15,
		icon = "🕺",
	},
	flip = {
		id = "flip",
		name = "Backflip",
		description = "Do a backflip!",
		animationId = "rbxassetid://0",
		duration = 1.5,
		category = "Tricks",
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "gravity_master",
		icon = "🔄",
	},
	bow = {
		id = "bow",
		name = "Bow",
		description = "Take a bow",
		animationId = "rbxassetid://0",
		duration = 2,
		category = "Greetings",
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 10,
		icon = "🙇",
	},
	laugh = {
		id = "laugh",
		name = "Laugh",
		description = "LOL!",
		animationId = "rbxassetid://0",
		duration = 3,
		category = "Reactions",
		unlocked = false,
		unlockMethod = "shop",
		unlockRequirement = 100, -- coins
		icon = "😂",
	},
	cry = {
		id = "cry",
		name = "Cry",
		description = "Tears of joy... or sadness",
		animationId = "rbxassetid://0",
		duration = 3,
		category = "Reactions",
		unlocked = false,
		unlockMethod = "shop",
		unlockRequirement = 100,
		icon = "😢",
	},

	-- Victory emotes
	victory1 = {
		id = "victory1",
		name = "Victory Pose",
		description = "Strike a winning pose",
		animationId = "rbxassetid://0",
		duration = 3,
		category = "Victory",
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "first_place",
		icon = "🏆",
	},
	victory2 = {
		id = "victory2",
		name = "Champion Dance",
		description = "The dance of champions",
		animationId = "rbxassetid://0",
		duration = 4,
		category = "Victory",
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "win_streak_10",
		icon = "👑",
	},

	-- Dimension-themed emotes
	gravityFlip = {
		id = "gravityFlip",
		name = "Gravity Flip",
		description = "Defy gravity!",
		animationId = "rbxassetid://0",
		duration = 2,
		category = "Dimension",
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "gravity_master",
		icon = "⬆️",
	},
	shrink = {
		id = "shrink",
		name = "Shrink",
		description = "Pretend to shrink",
		animationId = "rbxassetid://0",
		duration = 2.5,
		category = "Dimension",
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Tiny",
		icon = "🔍",
	},
	glide = {
		id = "glide",
		name = "Glide Pose",
		description = "Arms out like you're gliding",
		animationId = "rbxassetid://0",
		duration = 3,
		category = "Dimension",
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Sky",
		icon = "🪂",
	},
}

-- Emote cooldown (seconds)
local EMOTE_COOLDOWN = 1

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { unlockedEmotes = {}, favorites = {}, lastEmoteTime }
EmoteService.PlayerData = {}

-- [UserId] = { track, animation }
EmoteService.ActiveEmotes = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function EmoteService.Init()
	print("[EmoteService] Initializing...")

	EmoteService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		EmoteService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		EmoteService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		EmoteService.OnPlayerJoin(player)
	end

	print("[EmoteService] Initialized with", EmoteService.GetEmoteCount(), "emotes")
end

function EmoteService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Play emote
	if not remoteFolder:FindFirstChild("PlayEmote") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlayEmote"
		event.Parent = remoteFolder
	end

	-- Stop emote
	if not remoteFolder:FindFirstChild("StopEmote") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StopEmote"
		event.Parent = remoteFolder
	end

	-- Get emotes
	if not remoteFolder:FindFirstChild("GetEmotes") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetEmotes"
		func.Parent = remoteFolder
	end

	-- Set favorites
	if not remoteFolder:FindFirstChild("SetEmoteFavorites") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SetEmoteFavorites"
		event.Parent = remoteFolder
	end

	-- Emote played (broadcast to others)
	if not remoteFolder:FindFirstChild("EmotePlayed") then
		local event = Instance.new("RemoteEvent")
		event.Name = "EmotePlayed"
		event.Parent = remoteFolder
	end

	EmoteService.Remotes = {
		PlayEmote = remoteFolder.PlayEmote,
		StopEmote = remoteFolder.StopEmote,
		GetEmotes = remoteFolder.GetEmotes,
		SetEmoteFavorites = remoteFolder.SetEmoteFavorites,
		EmotePlayed = remoteFolder.EmotePlayed,
	}

	EmoteService.Remotes.PlayEmote.OnServerEvent:Connect(function(player, emoteId)
		EmoteService.PlayEmote(player, emoteId)
	end)

	EmoteService.Remotes.StopEmote.OnServerEvent:Connect(function(player)
		EmoteService.StopEmote(player)
	end)

	EmoteService.Remotes.GetEmotes.OnServerInvoke = function(player)
		return EmoteService.GetPlayerEmotes(player)
	end

	EmoteService.Remotes.SetEmoteFavorites.OnServerEvent:Connect(function(player, favorites)
		EmoteService.SetFavorites(player, favorites)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function EmoteService.OnPlayerJoin(player: Player)
	EmoteService.PlayerData[player.UserId] = {
		unlockedEmotes = {},
		favorites = {},
		lastEmoteTime = 0,
	}

	-- Unlock default emotes
	for emoteId, emote in pairs(EmoteService.Emotes) do
		if emote.unlocked then
			EmoteService.PlayerData[player.UserId].unlockedEmotes[emoteId] = true
		end
	end

	EmoteService.LoadPlayerData(player)
end

function EmoteService.OnPlayerLeave(player: Player)
	EmoteService.StopEmote(player)
	EmoteService.SavePlayerData(player)
	EmoteService.PlayerData[player.UserId] = nil
	EmoteService.ActiveEmotes[player.UserId] = nil
end

function EmoteService.LoadPlayerData(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data then
		local playerData = EmoteService.PlayerData[player.UserId]
		if playerData then
			if data.UnlockedEmotes then
				for emoteId, _ in pairs(data.UnlockedEmotes) do
					playerData.unlockedEmotes[emoteId] = true
				end
			end
			if data.EmoteFavorites then
				playerData.favorites = data.EmoteFavorites
			end
		end
	end
end

function EmoteService.SavePlayerData(player: Player)
	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			UnlockedEmotes = playerData.unlockedEmotes,
			EmoteFavorites = playerData.favorites,
		})
	end
end

-- ============================================================================
-- EMOTE PLAYBACK
-- ============================================================================

function EmoteService.PlayEmote(player: Player, emoteId: string): boolean
	local emote = EmoteService.Emotes[emoteId]
	if not emote then
		return false
	end

	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return false end

	-- Check if unlocked
	if not playerData.unlockedEmotes[emoteId] then
		return false
	end

	-- Check cooldown
	if tick() - playerData.lastEmoteTime < EMOTE_COOLDOWN then
		return false
	end

	-- Check if character exists
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	-- Stop any current emote
	EmoteService.StopEmote(player)

	playerData.lastEmoteTime = tick()

	-- Load and play animation
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Create animation (in production, use actual animation IDs)
	local animation = Instance.new("Animation")
	animation.AnimationId = emote.animationId

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if success and track then
		track:Play()

		EmoteService.ActiveEmotes[player.UserId] = {
			track = track,
			animation = animation,
			emoteId = emoteId,
		}

		-- Auto-stop after duration
		task.delay(emote.duration, function()
			local activeEmote = EmoteService.ActiveEmotes[player.UserId]
			if activeEmote and activeEmote.emoteId == emoteId then
				EmoteService.StopEmote(player)
			end
		end)

		-- Broadcast to other players
		EmoteService.Remotes.EmotePlayed:FireAllClients(player.UserId, emoteId, emote.icon)

		print(string.format("[EmoteService] %s played emote: %s", player.Name, emote.name))
		return true
	end

	return false
end

function EmoteService.StopEmote(player: Player)
	local activeEmote = EmoteService.ActiveEmotes[player.UserId]
	if not activeEmote then return end

	if activeEmote.track then
		activeEmote.track:Stop()
	end

	if activeEmote.animation then
		activeEmote.animation:Destroy()
	end

	EmoteService.ActiveEmotes[player.UserId] = nil
end

-- ============================================================================
-- UNLOCK SYSTEM
-- ============================================================================

function EmoteService.UnlockEmote(player: Player, emoteId: string): boolean
	local emote = EmoteService.Emotes[emoteId]
	if not emote then return false end

	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return false end

	if playerData.unlockedEmotes[emoteId] then
		return false -- Already unlocked
	end

	playerData.unlockedEmotes[emoteId] = true

	-- Notify player
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		local NotificationService = DimensionHopper.GetService("NotificationService")
		if NotificationService then
			NotificationService.Send(player, "REWARD", "Emote Unlocked!", emote.name .. " " .. emote.icon)
		end
	end

	print(string.format("[EmoteService] %s unlocked emote: %s", player.Name, emote.name))
	return true
end

function EmoteService.CheckEmoteUnlocks(player: Player, event: string, value: any)
	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return end

	for emoteId, emote in pairs(EmoteService.Emotes) do
		if not playerData.unlockedEmotes[emoteId] then
			if emote.unlockMethod == event then
				local shouldUnlock = false

				if event == "level" and type(value) == "number" then
					shouldUnlock = value >= emote.unlockRequirement
				elseif event == "achievement" and type(value) == "string" then
					shouldUnlock = value == emote.unlockRequirement
				elseif event == "dimension" and type(value) == "string" then
					shouldUnlock = value == emote.unlockRequirement
				end

				if shouldUnlock then
					EmoteService.UnlockEmote(player, emoteId)
				end
			end
		end
	end
end

-- ============================================================================
-- API
-- ============================================================================

function EmoteService.GetPlayerEmotes(player: Player): table
	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return {} end

	local result = {
		unlocked = {},
		locked = {},
		favorites = playerData.favorites,
	}

	for emoteId, emote in pairs(EmoteService.Emotes) do
		local emoteData = {
			id = emoteId,
			name = emote.name,
			description = emote.description,
			icon = emote.icon,
			category = emote.category,
			duration = emote.duration,
			unlocked = playerData.unlockedEmotes[emoteId] == true,
		}

		if emoteData.unlocked then
			table.insert(result.unlocked, emoteData)
		else
			emoteData.unlockMethod = emote.unlockMethod
			emoteData.unlockRequirement = emote.unlockRequirement
			table.insert(result.locked, emoteData)
		end
	end

	return result
end

function EmoteService.SetFavorites(player: Player, favorites: {string})
	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return end

	-- Validate favorites (max 8, must be unlocked)
	local validFavorites = {}
	for i, emoteId in ipairs(favorites) do
		if i > 8 then break end
		if playerData.unlockedEmotes[emoteId] then
			table.insert(validFavorites, emoteId)
		end
	end

	playerData.favorites = validFavorites
end

function EmoteService.HasEmote(player: Player, emoteId: string): boolean
	local playerData = EmoteService.PlayerData[player.UserId]
	if not playerData then return false end
	return playerData.unlockedEmotes[emoteId] == true
end

function EmoteService.GetEmoteCount(): number
	local count = 0
	for _ in pairs(EmoteService.Emotes) do
		count = count + 1
	end
	return count
end

-- ============================================================================
-- EVENT HANDLERS (called by other services)
-- ============================================================================

function EmoteService.OnLevelUp(player: Player, newLevel: number)
	EmoteService.CheckEmoteUnlocks(player, "level", newLevel)
end

function EmoteService.OnAchievementUnlocked(player: Player, achievementId: string)
	EmoteService.CheckEmoteUnlocks(player, "achievement", achievementId)
end

function EmoteService.OnDimensionComplete(player: Player, dimension: string)
	EmoteService.CheckEmoteUnlocks(player, "dimension", dimension)
end

return EmoteService
