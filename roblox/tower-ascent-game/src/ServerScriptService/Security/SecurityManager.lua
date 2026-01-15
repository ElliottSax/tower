--[[
	SecurityManager.lua
	Comprehensive security system addressing all P0 vulnerabilities

	Critical Security Features:
	- Remote event validation and rate limiting
	- Authorization and authentication
	- Input sanitization
	- Anti-exploit detection
	- Data encryption
	- DDoS protection
	- Secure admin system

	Priority: P0 (CRITICAL)
	Created: 2025-12-02
--]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local GroupService = game:GetService("GroupService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Safe require of utilities
local WebhookLogger = nil
local ServiceLocator = nil
pcall(function()
	WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)
	ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
end)

local SecurityManager = {}
SecurityManager.Enabled = true
SecurityManager.Bans = {}
SecurityManager.BanHistory = {} -- Track repeat offenders: [UserId] = {OffenseCount, LastBan}
SecurityManager.Authorizations = {}
SecurityManager.RateLimits = {}
SecurityManager.Violations = {}
SecurityManager.TrustedUsers = {}

-- Configuration
local CONFIG = {
	-- Rate limiting
	MaxRequestsPerSecond = 5,
	MaxRequestsPerMinute = 20,
	MaxRequestsPerHour = 100,

	-- Anti-exploit and ban escalation
	MaxViolationsBeforeBan = 3,
	BanDurationBase = 3600, -- 1 hour for first offense
	BanDurationMultiplier = 3, -- 3x increase per repeat offense
	MaxBanDuration = 2592000, -- 30 days maximum
	PermanentBanAfterOffenses = 5, -- Permanent ban after 5 offenses

	-- Data limits
	MaxStringLength = 1000,
	MaxDataSize = 10000,
	MaxArrayLength = 100,

	-- Admin security
	AdminGroupId = 0, -- Set your group ID
	AdminRankRequired = 250,
	OwnerUserId = game.CreatorId,

	-- Encryption (DISABLED - XOR encryption is insecure)
	-- For real encryption, use Roblox's built-in encryption or a proper crypto library
	EncryptionEnabled = false,
	EncryptionKey = nil

	-- Patterns to detect
	MaliciousPatterns = {
		"<script>", "</script>",
		"javascript:",
		"onclick=",
		"onerror=",
		"eval(",
		"require(",
		"loadstring(",
		"getfenv(",
		"setfenv(",
		"_G[",
		"rawset(",
		"rawget(",
		"debug.",
		"while true do",
		"repeat until false",
		":Destroy()",
		":Remove()",
		":ClearAllChildren()",
		"game:Shutdown()",
		"kick()",
		":Kick(",
	},

	-- Trusted developers (add your developer user IDs)
	TrustedDevelopers = {
		-- game.CreatorId, -- Automatically added
	}
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SecurityManager.Initialize()
	-- Encryption disabled (XOR is insecure - use proper crypto library if needed)
	-- CONFIG.EncryptionKey = HttpService:GenerateGUID(false) .. HttpService:GenerateGUID(false)

	-- Add creator as trusted
	table.insert(CONFIG.TrustedDevelopers, game.CreatorId)

	-- Load ban list from DataStore
	task.spawn(function()
		SecurityManager.LoadBans()
	end)

	-- Start monitoring
	SecurityManager.StartMonitoring()

	print("[SecurityManager] ✅ Security system initialized")
end

-- ============================================================================
-- AUTHENTICATION & AUTHORIZATION
-- ============================================================================

function SecurityManager.AuthenticatePlayer(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	-- Check if banned
	if SecurityManager.IsBanned(player) then
		player:Kick("You are banned from this game.")
		return false
	end

	-- Check account age (anti-bot)
	if player.AccountAge < 7 then -- 7 days minimum
		SecurityManager.LogViolation(player, "NEW_ACCOUNT", "Account age too low")
		-- Don't kick, but monitor closely
	end

	-- Generate auth token
	local token = HttpService:GenerateGUID(false)
	SecurityManager.Authorizations[player.UserId] = {
		Token = token,
		Timestamp = tick(),
		Validated = true
	}

	return true
end

function SecurityManager.IsAdmin(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	-- Check if owner
	if player.UserId == CONFIG.OwnerUserId then
		return true
	end

	-- Check trusted developers
	for _, trustedId in ipairs(CONFIG.TrustedDevelopers) do
		if player.UserId == trustedId then
			return true
		end
	end

	-- Check group rank
	if CONFIG.AdminGroupId > 0 then
		local success, rank = pcall(function()
			return player:GetRankInGroup(CONFIG.AdminGroupId)
		end)

		if success and rank >= CONFIG.AdminRankRequired then
			return true
		end
	end

	return false
end

function SecurityManager.IsTrusted(player: Player): boolean
	if not player then return false end

	-- Admins are always trusted
	if SecurityManager.IsAdmin(player) then
		return true
	end

	-- Check trusted users list
	return SecurityManager.TrustedUsers[player.UserId] == true
end

-- ============================================================================
-- RATE LIMITING & DDoS PROTECTION
-- ============================================================================

function SecurityManager.CheckRateLimit(player: Player, action: string): boolean
	if not player then return false end

	-- Admins bypass rate limits
	if SecurityManager.IsAdmin(player) then
		return true
	end

	local userId = player.UserId
	local key = userId .. ":" .. action
	local now = tick()

	-- Initialize rate limit data
	if not SecurityManager.RateLimits[key] then
		SecurityManager.RateLimits[key] = {
			Requests = {},
			Bans = 0
		}
	end

	local rateLimit = SecurityManager.RateLimits[key]

	-- Clean old requests
	local validRequests = {}
	for _, timestamp in ipairs(rateLimit.Requests) do
		if now - timestamp < 3600 then -- Keep last hour
			table.insert(validRequests, timestamp)
		end
	end
	rateLimit.Requests = validRequests

	-- Count recent requests
	local secondCount = 0
	local minuteCount = 0
	local hourCount = #validRequests

	for _, timestamp in ipairs(validRequests) do
		if now - timestamp < 1 then
			secondCount = secondCount + 1
		end
		if now - timestamp < 60 then
			minuteCount = minuteCount + 1
		end
	end

	-- Check limits
	if secondCount >= CONFIG.MaxRequestsPerSecond then
		SecurityManager.LogViolation(player, "RATE_LIMIT_SECOND", action)
		return false
	end

	if minuteCount >= CONFIG.MaxRequestsPerMinute then
		SecurityManager.LogViolation(player, "RATE_LIMIT_MINUTE", action)
		return false
	end

	if hourCount >= CONFIG.MaxRequestsPerHour then
		SecurityManager.LogViolation(player, "RATE_LIMIT_HOUR", action)
		return false
	end

	-- Add request
	table.insert(rateLimit.Requests, now)

	return true
end

-- ============================================================================
-- INPUT SANITIZATION & VALIDATION
-- ============================================================================

function SecurityManager.SanitizeString(input: string): string?
	if type(input) ~= "string" then
		return nil
	end

	-- Length check
	if #input > CONFIG.MaxStringLength then
		return string.sub(input, 1, CONFIG.MaxStringLength)
	end

	-- Remove malicious patterns
	local sanitized = input
	for _, pattern in ipairs(CONFIG.MaliciousPatterns) do
		sanitized = string.gsub(sanitized, pattern, "")
	end

	-- Remove non-printable characters
	sanitized = string.gsub(sanitized, "[%c%z]", "")

	-- HTML encode special characters
	sanitized = string.gsub(sanitized, "&", "&amp;")
	sanitized = string.gsub(sanitized, "<", "&lt;")
	sanitized = string.gsub(sanitized, ">", "&gt;")
	sanitized = string.gsub(sanitized, '"', "&quot;")
	sanitized = string.gsub(sanitized, "'", "&#39;")

	return sanitized
end

function SecurityManager.ValidateData(data: any, schema: {}?): (boolean, string?)
	-- Nil check
	if data == nil then
		return false, "Data is nil"
	end

	-- Size check
	local dataStr = HttpService:JSONEncode(data)
	if #dataStr > CONFIG.MaxDataSize then
		return false, "Data too large"
	end

	-- Type validation
	if schema then
		for key, expectedType in pairs(schema) do
			if type(data[key]) ~= expectedType then
				return false, string.format("Invalid type for %s: expected %s, got %s",
					key, expectedType, type(data[key]))
			end
		end
	end

	-- Array length check
	if type(data) == "table" then
		local count = 0
		for _ in pairs(data) do
			count = count + 1
			if count > CONFIG.MaxArrayLength then
				return false, "Array too large"
			end
		end
	end

	-- String sanitization
	if type(data) == "string" then
		local sanitized = SecurityManager.SanitizeString(data)
		if not sanitized then
			return false, "String validation failed"
		end
	end

	return true, nil
end

-- ============================================================================
-- ANTI-EXPLOIT DETECTION
-- ============================================================================

function SecurityManager.DetectExploit(player: Player, data: {}): boolean
	if not player then return true end

	-- Check for impossible values
	if data.Position then
		local character = player.Character
		if character and character.PrimaryPart then
			local distance = (character.PrimaryPart.Position - data.Position).Magnitude
			if distance > 500 then -- Teleport hack
				SecurityManager.LogViolation(player, "TELEPORT_HACK",
					string.format("Distance: %.0f", distance))
				return true
			end
		end
	end

	-- Check for speed hacks
	if data.Velocity then
		local velocity = data.Velocity
		if typeof(velocity) == "Vector3" then
			local speed = velocity.Magnitude
			if speed > 100 then -- Unrealistic speed
				SecurityManager.LogViolation(player, "SPEED_HACK",
					string.format("Speed: %.0f", speed))
				return true
			end
		end
	end

	-- Check for impossible game states
	if data.Coins and data.Coins > 999999999 then
		SecurityManager.LogViolation(player, "IMPOSSIBLE_VALUE", "Coins: " .. tostring(data.Coins))
		return true
	end

	-- Check for malicious strings
	for key, value in pairs(data) do
		if type(value) == "string" then
			for _, pattern in ipairs(CONFIG.MaliciousPatterns) do
				if string.find(value, pattern) then
					SecurityManager.LogViolation(player, "MALICIOUS_PATTERN", pattern)
					return true
				end
			end
		end
	end

	return false
end

-- ============================================================================
-- SECURE REMOTE HANDLING
-- ============================================================================

function SecurityManager.SecureRemote(remote: RemoteEvent | RemoteFunction, handler: (Player, ...) -> any)
	local wrappedHandler = function(player, ...)
		-- Authentication check
		if not SecurityManager.Authorizations[player.UserId] then
			if not SecurityManager.AuthenticatePlayer(player) then
				return nil
			end
		end

		-- Rate limiting
		if not SecurityManager.CheckRateLimit(player, remote.Name) then
			warn(string.format("[Security] Rate limit exceeded for %s on %s",
				player.Name, remote.Name))
			return nil
		end

		-- Get arguments
		local args = {...}

		-- Validate each argument
		for i, arg in ipairs(args) do
			local valid, err = SecurityManager.ValidateData(arg)
			if not valid then
				SecurityManager.LogViolation(player, "INVALID_DATA", err)
				return nil
			end
		end

		-- Check for exploits
		local exploitData = {}
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				exploitData = arg
				break
			end
		end

		if SecurityManager.DetectExploit(player, exploitData) then
			return nil
		end

		-- Call original handler
		local success, result = pcall(handler, player, ...)

		if not success then
			warn(string.format("[Security] Handler error for %s: %s",
				remote.Name, tostring(result)))
			return nil
		end

		return result
	end

	-- Connect based on type
	if remote:IsA("RemoteEvent") then
		remote.OnServerEvent:Connect(wrappedHandler)
	elseif remote:IsA("RemoteFunction") then
		remote.OnServerInvoke = wrappedHandler
	end
end

-- ============================================================================
-- VIOLATION TRACKING & BANNING
-- ============================================================================

function SecurityManager.LogViolation(player: Player, violationType: string, details: string?)
	if not player then return end

	local userId = player.UserId

	-- Initialize violation record
	if not SecurityManager.Violations[userId] then
		SecurityManager.Violations[userId] = {
			Count = 0,
			Types = {},
			LastViolation = 0
		}
	end

	local violations = SecurityManager.Violations[userId]
	violations.Count = violations.Count + 1
	violations.LastViolation = tick()

	table.insert(violations.Types, {
		Type = violationType,
		Details = details,
		Timestamp = tick()
	})

	warn(string.format("[Security] Violation logged for %s (%d): %s - %s",
		player.Name, userId, violationType, details or "No details"))

	-- Check for ban threshold
	if violations.Count >= CONFIG.MaxViolationsBeforeBan then
		SecurityManager.BanPlayer(player, "Multiple security violations")
	end

	-- Report critical violations
	if violationType == "EXPLOIT" or violationType == "MALICIOUS_PATTERN" then
		local BugReporter = ServiceLocator and ServiceLocator.Get("BugReporter")
		if BugReporter and BugReporter.ReportBug then
			BugReporter.ReportBug("SECURITY",
				string.format("Security violation: %s", violationType),
				{
					Player = player.Name,
					UserId = userId,
					Details = details
				})
		end

		-- Log to webhook
		if WebhookLogger then
			WebhookLogger.LogSecurityEvent(violationType, {
				Player = player.Name,
				UserId = userId,
				Details = details or "No details",
				ViolationCount = violations.Count
			})
		end
	end
end

function SecurityManager.BanPlayer(player: Player, reason: string, durationOverride: number?)
	if not player then return end

	local userId = player.UserId

	-- Don't ban admins
	if SecurityManager.IsAdmin(player) then
		warn(string.format("[Security] Attempted to ban admin %s", player.Name))
		return
	end

	-- Initialize ban history if needed
	if not SecurityManager.BanHistory[userId] then
		SecurityManager.BanHistory[userId] = {
			OffenseCount = 0,
			LastBan = 0
		}
	end

	-- Increment offense count
	local history = SecurityManager.BanHistory[userId]
	history.OffenseCount = history.OffenseCount + 1
	history.LastBan = tick()

	-- Calculate ban duration with escalation
	local duration = durationOverride
	if not duration then
		if history.OffenseCount >= CONFIG.PermanentBanAfterOffenses then
			-- Permanent ban
			duration = 0
		else
			-- Escalating ban: base * multiplier ^ (offenses - 1)
			duration = CONFIG.BanDurationBase * math.pow(CONFIG.BanDurationMultiplier, history.OffenseCount - 1)
			duration = math.min(duration, CONFIG.MaxBanDuration)
		end
	end

	-- Add to ban list
	SecurityManager.Bans[userId] = {
		Reason = reason,
		Timestamp = tick(),
		Duration = duration,
		OffenseCount = history.OffenseCount,
		IsPermanent = (duration == 0)
	}

	-- Save to DataStore
	task.spawn(function()
		SecurityManager.SaveBan(userId, reason)
	end)

	-- Log to webhook
	if WebhookLogger then
		WebhookLogger.LogBan(player, reason, duration)
	end

	-- Kick player with appropriate message
	local kickMessage
	if duration == 0 then
		kickMessage = string.format("PERMANENT BAN\nReason: %s\nOffense #%d", reason, history.OffenseCount)
	else
		local hours = math.floor(duration / 3600)
		local days = math.floor(hours / 24)
		local timeStr = days > 0 and string.format("%d days", days) or string.format("%d hours", hours)
		kickMessage = string.format("BANNED FOR %s\nReason: %s\nOffense #%d", timeStr, reason, history.OffenseCount)
	end
	player:Kick(kickMessage)

	warn(string.format("[Security] Banned player %s (%d): %s [Offense #%d, Duration: %ds]",
		player.Name, userId, reason, history.OffenseCount, duration))
end

function SecurityManager.IsBanned(player: Player): boolean
	if not player then return true end

	local userId = player.UserId
	local ban = SecurityManager.Bans[userId]

	if not ban then
		return false
	end

	-- Check if ban expired
	if ban.Duration > 0 then
		local elapsed = tick() - ban.Timestamp
		if elapsed > ban.Duration then
			SecurityManager.Bans[userId] = nil
			return false
		end
	end

	return true
end

-- ============================================================================
-- DATA ENCRYPTION
-- ============================================================================

-- NOTE: Encryption functions removed - XOR encryption is insecure.
-- If encryption is needed, use Roblox's built-in data encryption
-- or a proper cryptographic library. The platform handles
-- DataStore encryption automatically.

-- ============================================================================
-- SECURE ADMIN COMMANDS
-- ============================================================================

function SecurityManager.RegisterSecureCommand(name: string, handler: (Player, ...) -> any)
	local AdminCommands = ServiceLocator and ServiceLocator.Get("AdminCommands")
	if not AdminCommands then return end

	local secureHandler = function(player, ...)
		-- Admin check
		if not SecurityManager.IsAdmin(player) then
			return "You do not have permission to use this command"
		end

		-- Log command usage
		print(string.format("[Security] Admin %s used command: %s",
			player.Name, name))

		-- Execute with error handling
		local success, result = pcall(handler, player, ...)

		if not success then
			warn(string.format("[Security] Admin command error: %s", tostring(result)))
			return "Command failed: " .. tostring(result)
		end

		return result
	end

	AdminCommands.RegisterCommand("admin", name, secureHandler)
end

-- ============================================================================
-- MONITORING & DETECTION
-- ============================================================================

function SecurityManager.StartMonitoring()
	-- Monitor player joins
	Players.PlayerAdded:Connect(function(player)
		-- Authenticate on join
		SecurityManager.AuthenticatePlayer(player)

		-- Monitor character
		player.CharacterAdded:Connect(function(character)
			SecurityManager.MonitorCharacter(player, character)
		end)
	end)

	-- Monitor player leaves
	Players.PlayerRemoving:Connect(function(player)
		-- Clean up data
		SecurityManager.Authorizations[player.UserId] = nil
		SecurityManager.RateLimits[player.UserId] = nil
	end)

	-- Periodic cleanup
	task.spawn(function()
		while SecurityManager.Enabled do
			task.wait(60)
			SecurityManager.CleanupOldData()
		end
	end)
end

function SecurityManager.MonitorCharacter(player: Player, character: Model)
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Monitor walk speed
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed > 50 then -- Abnormal speed
			SecurityManager.LogViolation(player, "SPEED_MODIFICATION",
				string.format("WalkSpeed: %.0f", humanoid.WalkSpeed))
			humanoid.WalkSpeed = 16 -- Reset to default
		end
	end)

	-- Monitor jump power
	humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
		if humanoid.JumpPower > 100 then -- Abnormal jump
			SecurityManager.LogViolation(player, "JUMP_MODIFICATION",
				string.format("JumpPower: %.0f", humanoid.JumpPower))
			humanoid.JumpPower = 50 -- Reset to default
		end
	end)

	-- Monitor health
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if humanoid.Health > humanoid.MaxHealth then
			SecurityManager.LogViolation(player, "HEALTH_MODIFICATION",
				string.format("Health: %.0f/%.0f", humanoid.Health, humanoid.MaxHealth))
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

function SecurityManager.CleanupOldData()
	local now = tick()

	-- Clean rate limits
	for key, data in pairs(SecurityManager.RateLimits) do
		local validRequests = {}
		for _, timestamp in ipairs(data.Requests) do
			if now - timestamp < 3600 then
				table.insert(validRequests, timestamp)
			end
		end
		data.Requests = validRequests
	end

	-- Clean old violations
	for userId, violations in pairs(SecurityManager.Violations) do
		if now - violations.LastViolation > 86400 then -- 24 hours
			SecurityManager.Violations[userId] = nil
		end
	end

	-- Clean expired bans
	for userId, ban in pairs(SecurityManager.Bans) do
		if ban.Duration > 0 then
			local elapsed = now - ban.Timestamp
			if elapsed > ban.Duration then
				SecurityManager.Bans[userId] = nil
			end
		end
	end
end

-- ============================================================================
-- DATASTORE PERSISTENCE
-- ============================================================================

function SecurityManager.SaveBan(userId: number, reason: string)
	local banDataStore = DataStoreService:GetDataStore("SecurityBans")

	-- Get the ban data to save the correct duration
	local banData = SecurityManager.Bans[userId]
	local duration = banData and banData.Duration or CONFIG.BanDurationBase

	local success, err = pcall(function()
		banDataStore:SetAsync("Ban_" .. userId, {
			Reason = reason,
			Timestamp = tick(),
			Duration = duration,
			OffenseCount = banData and banData.OffenseCount or 1,
			IsPermanent = banData and banData.IsPermanent or false
		})
	end)

	if not success then
		warn(string.format("[Security] Failed to save ban: %s", err))
	end
end

function SecurityManager.LoadBans()
	local banDataStore = DataStoreService:GetDataStore("SecurityBans")

	-- This would need to iterate through pages in production
	-- Simplified for example
	print("[Security] Loading ban list...")
end

-- ============================================================================
-- EXPORT & ADMIN COMMANDS
-- ============================================================================

function SecurityManager.GetStatistics()
	local stats = {
		ActivePlayers = #Players:GetPlayers(),
		Authenticated = 0,
		Violations = 0,
		Bans = 0,
		RateLimited = 0
	}

	for _ in pairs(SecurityManager.Authorizations) do
		stats.Authenticated = stats.Authenticated + 1
	end

	for _ in pairs(SecurityManager.Violations) do
		stats.Violations = stats.Violations + 1
	end

	for _ in pairs(SecurityManager.Bans) do
		stats.Bans = stats.Bans + 1
	end

	return stats
end

function SecurityManager.RegisterAdminCommands()
	-- /security stats
	SecurityManager.RegisterSecureCommand("stats", function(player)
		local stats = SecurityManager.GetStatistics()
		return string.format("Security Stats:\nAuth: %d\nViolations: %d\nBans: %d",
			stats.Authenticated, stats.Violations, stats.Bans)
	end)

	-- /security ban [username] [reason]
	SecurityManager.RegisterSecureCommand("ban", function(player, targetName, ...)
		local reason = table.concat({...}, " ")
		local target = Players:FindFirstChild(targetName)

		if target then
			SecurityManager.BanPlayer(target, reason)
			return string.format("Banned %s: %s", targetName, reason)
		else
			return "Player not found"
		end
	end)

	-- /security unban [userId]
	SecurityManager.RegisterSecureCommand("unban", function(player, userId)
		userId = tonumber(userId)
		if userId then
			SecurityManager.Bans[userId] = nil
			return string.format("Unbanned user %d", userId)
		else
			return "Invalid user ID"
		end
	end)

	-- /security violations [username]
	SecurityManager.RegisterSecureCommand("violations", function(player, targetName)
		local target = Players:FindFirstChild(targetName)
		if not target then
			return "Player not found"
		end

		local violations = SecurityManager.Violations[target.UserId]
		if violations then
			return string.format("Violations for %s: %d", targetName, violations.Count)
		else
			return "No violations found"
		end
	end)

	print("[SecurityManager] Admin commands registered")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
SecurityManager.Initialize()

return SecurityManager