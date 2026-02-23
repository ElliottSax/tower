--[[
	VIPService.lua
	Manages VIP membership benefits for Tower Ascent

	Features:
	- VIP Game Pass detection (permanent purchase)
	- 2x coin multiplier for VIP players
	- VIP cosmetic tag/badge
	- VIP lounge access
	- Priority server access (if server full)
	- Exclusive VIP trail effect

	Benefits:
	- 2x Coins: Reduces grind (2-3 climbs vs 4-6 to max upgrades)
	- Cosmetic Status: VIP tag displayed in chat/leaderboard
	- Social Hub: VIP lounge area (future)
	- QoL: Priority access if server full

	Week 12: Core monetization system
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VIPService = {}
VIPService.VIPPlayers = {} -- Track VIP status: [UserId] = true/false/nil(pending)
VIPService.VIPCache = {} -- Cache VIP status: [UserId] = {IsVIP = bool, Timestamp = number}
VIPService.PurchaseRateLimits = {} -- Track last purchase prompt: [UserId] = tick()
VIPService.CharacterConnections = {} -- Track CharacterAdded connections to prevent leaks: [UserId] = connection
VIPService.IsInitialized = false

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- VIP Game Pass ID (set this after creating Game Pass on Roblox)
	VIPGamePassId = 0, -- PLACEHOLDER: Replace with actual Game Pass ID

	-- VIP Benefits
	CoinMultiplier = 2, -- 2x coins for VIP players

	-- VIP Cosmetics
	VIPTag = "⭐ VIP",
	VIPChatColor = Color3.fromRGB(255, 215, 0), -- Gold
	VIPNameColor = Color3.fromRGB(255, 215, 0), -- Gold

	-- VIP Lounge
	VIPLoungeEnabled = false, -- Enable in future when lounge built
	VIPLoungeSpawn = Vector3.new(0, 100, 0), -- Lounge spawn location
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function VIPService.Init()
	print("[VIPService] Initializing...")

	-- Validate Game Pass ID
	if CONFIG.VIPGamePassId == 0 then
		warn("[VIPService] VIP Game Pass ID not set! VIP features disabled.")
		warn("[VIPService] Set CONFIG.VIPGamePassId in VIPService.lua")
		VIPService.IsInitialized = true
		return
	end

	-- Create RemoteEvents for client communication
	VIPService.CreateRemoteEvents()

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		VIPService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		VIPService.OnPlayerLeave(player)
	end)

	VIPService.IsInitialized = true
	print("[VIPService] Initialized")
end

function VIPService.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- VIP Status Update (notify client of VIP status)
	if not remoteFolder:FindFirstChild("VIPStatusUpdate") then
		local statusUpdate = Instance.new("RemoteEvent")
		statusUpdate.Name = "VIPStatusUpdate"
		statusUpdate.Parent = remoteFolder
	end

	-- Prompt VIP Purchase (client requests purchase prompt)
	if not remoteFolder:FindFirstChild("PromptVIPPurchase") then
		local promptPurchase = Instance.new("RemoteEvent")
		promptPurchase.Name = "PromptVIPPurchase"
		promptPurchase.Parent = remoteFolder

		-- Handle purchase prompts from client (with rate limiting)
		promptPurchase.OnServerEvent:Connect(function(player)
			-- RATE LIMITING: Prevent DoS via spam-firing purchase prompts
			local now = tick()
			local lastPrompt = VIPService.PurchaseRateLimits[player.UserId] or 0

			if now - lastPrompt < 5 then
				-- Rate limited (5 second cooldown between prompts)
				warn(string.format(
					"[VIPService] %s is rate limited on purchase prompts (%.1fs remaining)",
					player.Name,
					5 - (now - lastPrompt)
				))
				return
			end

			-- Update rate limit timestamp
			VIPService.PurchaseRateLimits[player.UserId] = now

			-- Process purchase prompt
			VIPService.PromptPurchase(player)
		end)
	end
end

-- ============================================================================
-- VIP STATUS MANAGEMENT
-- ============================================================================

function VIPService.OnPlayerJoin(player: Player)
	--[[
		Called when player joins server.
		Checks VIP status and applies benefits.

		FIXED: Non-blocking marketplace call to prevent server hangs.
		Default to non-VIP immediately, then upgrade if marketplace confirms VIP status.
	--]]

	if CONFIG.VIPGamePassId == 0 then
		-- VIP not configured, treat as non-VIP
		VIPService.VIPPlayers[player.UserId] = false
		player:SetAttribute("IsVIP", false)
		return
	end

	-- SECURITY FIX: Use pending state and cache to prevent race condition
	local userId = player.UserId

	-- Set pending state (nil = checking)
	VIPService.VIPPlayers[userId] = nil
	player:SetAttribute("IsVIP", nil)
	player:SetAttribute("VIPCheckPending", true)

	-- Try to load from cache first
	local cachedStatus = nil
	local cacheAge = math.huge

	if VIPService.VIPCache[userId] then
		cachedStatus = VIPService.VIPCache[userId].IsVIP
		cacheAge = tick() - VIPService.VIPCache[userId].Timestamp
	end

	-- Use cache if fresh (< 5 minutes)
	if cachedStatus ~= nil and cacheAge < 300 then
		VIPService.VIPPlayers[userId] = cachedStatus
		player:SetAttribute("IsVIP", cachedStatus)
		player:SetAttribute("VIPCheckPending", false)

		print(string.format("[VIPService] Loaded from cache for %s: %s",
			player.Name, tostring(cachedStatus)))

		if cachedStatus then
			VIPService.ApplyVIPBenefits(player)
		end

		return
	end

	-- Check VIP status asynchronously
	task.spawn(function()
		local success, isVIP = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(userId, CONFIG.VIPGamePassId)
		end)

		if not success then
			-- Failed to check - default to non-VIP (safe fallback)
			warn(string.format("[VIPService] Failed to check VIP status for %s", player.Name))
			isVIP = false
		end

		-- Verify player is still in the game (they may have left during async call)
		if not player or not player.Parent then return end

		-- Update VIP status
		VIPService.VIPPlayers[userId] = isVIP
		player:SetAttribute("IsVIP", isVIP)
		player:SetAttribute("VIPCheckPending", false)

		-- Cache the result
		VIPService.VIPCache[userId] = {
			IsVIP = isVIP,
			Timestamp = tick()
		}

		if isVIP then
			print(string.format("[VIPService] %s confirmed as VIP", player.Name))
			VIPService.ApplyVIPBenefits(player)
		else
			print(string.format("[VIPService] %s confirmed as non-VIP", player.Name))
		end

		-- Notify client of VIP status
		VIPService.NotifyVIPStatus(player, isVIP)
	end)
end

function VIPService.OnPlayerLeave(player: Player)
	--[[
		Cleanup when player leaves.
	--]]

	VIPService.VIPPlayers[player.UserId] = nil
	VIPService.PurchaseRateLimits[player.UserId] = nil

	-- Disconnect CharacterAdded connection to prevent memory leak
	if VIPService.CharacterConnections[player.UserId] then
		VIPService.CharacterConnections[player.UserId]:Disconnect()
		VIPService.CharacterConnections[player.UserId] = nil
	end
end

-- ============================================================================
-- VIP BENEFITS
-- ============================================================================

function VIPService.ApplyVIPBenefits(player: Player)
	--[[
		Applies VIP benefits to player.
		Called when VIP player joins or purchases VIP.
	--]]

	-- Set VIP attribute (used by other services)
	player:SetAttribute("IsVIP", true)

	-- Apply VIP name tag (if player has character)
	if player.Character then
		VIPService.ApplyVIPTag(player)
	end

	-- Listen for character spawn to reapply tag (disconnect old connection first to prevent leaks)
	if VIPService.CharacterConnections[player.UserId] then
		VIPService.CharacterConnections[player.UserId]:Disconnect()
	end
	VIPService.CharacterConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
		VIPService.ApplyVIPTag(player)
	end)

	-- VIP Lounge access (future)
	if CONFIG.VIPLoungeEnabled then
		-- Teleport to VIP lounge on join (optional)
		-- player.Character:MoveTo(CONFIG.VIPLoungeSpawn)
	end
end

function VIPService.ApplyVIPTag(player: Player)
	--[[
		Applies VIP tag above player's name.
	--]]

	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Remove existing VIP tag (if any)
	local existingTag = head:FindFirstChild("VIPTag")
	if existingTag then
		existingTag:Destroy()
	end

	-- Create VIP BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "VIPTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	-- Create VIP label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = CONFIG.VIPTag
	label.TextColor3 = CONFIG.VIPNameColor
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
end

-- ============================================================================
-- COIN MULTIPLIER
-- ============================================================================

function VIPService.GetCoinMultiplier(player: Player): number
	--[[
		Returns coin multiplier for player.
		VIP players get 2x coins.
		Called by CoinService when awarding coins.
	--]]

	if VIPService.IsVIP(player) then
		return CONFIG.CoinMultiplier
	else
		return 1
	end
end

-- ============================================================================
-- VIP STATUS CHECKING
-- ============================================================================

function VIPService.IsVIP(player: Player): boolean
	--[[
		Returns true if player is VIP.
		Primary VIP status check used by all services.
	--]]

	-- Check attribute first (set on join)
	local isVIPAttribute = player:GetAttribute("IsVIP")
	if isVIPAttribute ~= nil then
		return isVIPAttribute
	end

	-- Fallback: check cached status
	return VIPService.VIPPlayers[player.UserId] == true
end

function VIPService.RefreshVIPStatus(player: Player)
	--[[
		Force refresh VIP status (after purchase).
		Called when player purchases VIP Game Pass.
	--]]

	if CONFIG.VIPGamePassId == 0 then
		return
	end

	task.spawn(function()
		local success, isVIP = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, CONFIG.VIPGamePassId)
		end)

		if success and isVIP then
			-- Player is now VIP
			VIPService.VIPPlayers[player.UserId] = true
			VIPService.ApplyVIPBenefits(player)
			VIPService.NotifyVIPStatus(player, true)

			print(string.format("[VIPService] %s purchased VIP!", player.Name))
		end
	end)
end

-- ============================================================================
-- PURCHASE HANDLING
-- ============================================================================

function VIPService.PromptPurchase(player: Player)
	--[[
		Prompts player to purchase VIP Game Pass.
		Called when player clicks "Buy VIP" button.
	--]]

	if CONFIG.VIPGamePassId == 0 then
		warn("[VIPService] Cannot prompt purchase - Game Pass ID not set")
		return
	end

	-- Check if already VIP
	if VIPService.IsVIP(player) then
		print(string.format("[VIPService] %s already owns VIP", player.Name))
		-- Could notify player they already own it (via RemoteEvent to client)
		return
	end

	-- Prompt purchase
	task.spawn(function()
		local success, error = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, CONFIG.VIPGamePassId)
		end)

		if not success then
			warn(string.format("[VIPService] Failed to prompt purchase for %s: %s", player.Name, tostring(error)))
		end
	end)
end

-- Listen for Game Pass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == CONFIG.VIPGamePassId and wasPurchased then
		-- Player purchased VIP
		VIPService.RefreshVIPStatus(player)
	end
end)

-- ============================================================================
-- CLIENT COMMUNICATION
-- ============================================================================

function VIPService.NotifyVIPStatus(player: Player, isVIP: boolean)
	--[[
		Notifies client of VIP status.
		Client can use this to show/hide VIP UI elements.
	--]]

	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then return end

	local statusUpdate = remoteFolder:FindFirstChild("VIPStatusUpdate")
	if statusUpdate then
		statusUpdate:FireClient(player, isVIP)
	end
end

-- ============================================================================
-- ADMIN COMMANDS (for testing)
-- ============================================================================

function VIPService.AdminGrantVIP(player: Player)
	--[[
		Admin command to grant VIP temporarily (for testing).
		Does NOT actually give Game Pass ownership.
	--]]

	print(string.format("[VIPService] ADMIN: Granting VIP to %s (temporary)", player.Name))
	VIPService.VIPPlayers[player.UserId] = true
	VIPService.ApplyVIPBenefits(player)
	VIPService.NotifyVIPStatus(player, true)
end

function VIPService.AdminRevokeVIP(player: Player)
	--[[
		Admin command to revoke VIP (for testing).
	--]]

	print(string.format("[VIPService] ADMIN: Revoking VIP from %s", player.Name))
	VIPService.VIPPlayers[player.UserId] = false
	player:SetAttribute("IsVIP", false)
	VIPService.NotifyVIPStatus(player, false)

	-- Remove VIP tag
	if player.Character and player.Character:FindFirstChild("Head") then
		local vipTag = player.Character.Head:FindFirstChild("VIPTag")
		if vipTag then
			vipTag:Destroy()
		end
	end
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function VIPService.GetVIPCount(): number
	--[[
		Returns number of VIP players currently in server.
	--]]

	local count = 0
	for _, isVIP in pairs(VIPService.VIPPlayers) do
		if isVIP then
			count = count + 1
		end
	end
	return count
end

function VIPService.DebugPrint()
	--[[
		Prints VIP service status.
	--]]

	print("=== VIP SERVICE STATUS ===")
	print(string.format("VIP Game Pass ID: %d", CONFIG.VIPGamePassId))
	print(string.format("Coin Multiplier: %dx", CONFIG.CoinMultiplier))
	print(string.format("VIP Players: %d", VIPService.GetVIPCount()))
	print(string.format("Total Players: %d", #Players:GetPlayers()))
	print("==========================")

	-- List VIP players
	if VIPService.GetVIPCount() > 0 then
		print("\nVIP Players:")
		for userId, isVIP in pairs(VIPService.VIPPlayers) do
			if isVIP then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					print(string.format("  - %s (%d)", player.Name, userId))
				end
			end
		end
	end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return VIPService
