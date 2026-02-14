--[[
	AuthSystem.lua
	Authentication and authorization system

	Features:
	- Session management with tokens
	- Role-based access control (RBAC)
	- Permission levels
	- Two-factor authentication support
	- Login attempt tracking
	- Session timeout and renewal
	- OAuth-like token system

	Created: 2025-12-02
--]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuthSystem = {}
AuthSystem.Enabled = true

-- Configuration
local CONFIG = {
	SessionTimeout = 3600, -- 1 hour
	MaxLoginAttempts = 5,
	LoginAttemptWindow = 300, -- 5 minutes
	TokenLength = 32,
	RequireTwoFactor = false,
	MinPasswordLength = 8,
	MaxSessionsPerUser = 3,
	RefreshTokenLifetime = 86400 * 7, -- 7 days
	AccessTokenLifetime = 900 -- 15 minutes
}

-- Roles and permissions
local ROLES = {
	OWNER = {
		Level = 100,
		Permissions = {"*"} -- All permissions
	},
	ADMIN = {
		Level = 90,
		Permissions = {
			"admin.*",
			"moderation.*",
			"data.read",
			"data.write",
			"player.kick",
			"player.ban",
			"server.shutdown"
		}
	},
	MODERATOR = {
		Level = 50,
		Permissions = {
			"moderation.*",
			"player.kick",
			"player.mute",
			"chat.delete",
			"report.view"
		}
	},
	VIP = {
		Level = 20,
		Permissions = {
			"vip.access",
			"vip.commands",
			"chat.vip"
		}
	},
	PLAYER = {
		Level = 10,
		Permissions = {
			"game.play",
			"chat.send",
			"report.create"
		}
	},
	GUEST = {
		Level = 1,
		Permissions = {
			"game.view"
		}
	}
}

-- DataStores
local authDataStore = DataStoreService:GetDataStore("AuthSystem")
local sessionDataStore = DataStoreService:GetDataStore("Sessions")

-- Active sessions
local activeSessions = {}
local loginAttempts = {}
local userRoles = {}
local twoFactorCodes = {}

-- ============================================================================
-- TOKEN GENERATION
-- ============================================================================

local function generateToken(length: number?): string
	length = length or CONFIG.TokenLength
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local token = {}

	for i = 1, length do
		local randomIndex = math.random(1, #chars)
		table.insert(token, string.sub(chars, randomIndex, randomIndex))
	end

	return table.concat(token)
end

local function generateSecureHash(data: string, salt: string?): string
	salt = salt or generateToken(16)
	local combined = data .. salt

	-- Simple hash function (use proper crypto in production)
	local hash = 0
	for i = 1, #combined do
		hash = bit32.bxor(hash * 31, string.byte(combined, i))
		hash = hash % 2147483647
	end

	return tostring(hash) .. ":" .. salt
end

local function verifyHash(data: string, hashedValue: string): boolean
	local parts = string.split(hashedValue, ":")
	if #parts ~= 2 then
		return false
	end

	local salt = parts[2]
	local expectedHash = generateSecureHash(data, salt)

	return expectedHash == hashedValue
end

-- ============================================================================
-- SESSION MANAGEMENT
-- ============================================================================

local Session = {}
Session.__index = Session

function Session.new(userId: number, role: string?)
	local self = setmetatable({}, Session)

	self.SessionId = generateToken()
	self.UserId = userId
	self.Role = role or "PLAYER"
	self.AccessToken = generateToken()
	self.RefreshToken = generateToken(48)
	self.CreatedAt = tick()
	self.LastActivity = tick()
	self.ExpiresAt = tick() + CONFIG.SessionTimeout
	self.Metadata = {
		IP = "", -- Would need to be set externally
		Device = "",
		Location = ""
	}
	self.IsValid = true

	return self
end

function Session:Refresh()
	self.LastActivity = tick()
	self.ExpiresAt = tick() + CONFIG.SessionTimeout
	self.AccessToken = generateToken()
end

function Session:IsExpired(): boolean
	return tick() > self.ExpiresAt
end

function Session:Invalidate()
	self.IsValid = false
	self.ExpiresAt = 0
end

function Session:HasPermission(permission: string): boolean
	local role = ROLES[self.Role]
	if not role then
		return false
	end

	-- Check for wildcard permission
	for _, perm in ipairs(role.Permissions) do
		if perm == "*" or perm == permission then
			return true
		end

		-- Check wildcard patterns
		local pattern = string.gsub(perm, "%.", "%%.")
		pattern = string.gsub(pattern, "%*", ".*")
		if string.match(permission, "^" .. pattern .. "$") then
			return true
		end
	end

	return false
end

-- ============================================================================
-- AUTHENTICATION
-- ============================================================================

function AuthSystem.Authenticate(player: Player, credentials: {}?): (boolean, string?, Session?)
	local userId = player.UserId

	-- Check login attempts
	if not AuthSystem.CheckLoginAttempts(userId) then
		return false, "Too many login attempts. Please try again later.", nil
	end

	-- Record login attempt
	AuthSystem.RecordLoginAttempt(userId)

	-- Get user auth data
	local authData = AuthSystem.GetAuthData(userId)

	-- Verify credentials if provided
	if credentials then
		if credentials.Password and authData.PasswordHash then
			if not verifyHash(credentials.Password, authData.PasswordHash) then
				return false, "Invalid credentials", nil
			end
		end

		-- Check 2FA if enabled
		if authData.TwoFactorEnabled and CONFIG.RequireTwoFactor then
			if not credentials.TwoFactorCode then
				-- Generate and send 2FA code
				local code = AuthSystem.Generate2FACode(userId)
				return false, "2FA_REQUIRED", nil
			else
				if not AuthSystem.Verify2FACode(userId, credentials.TwoFactorCode) then
					return false, "Invalid 2FA code", nil
				end
			end
		end
	end

	-- Determine role
	local role = AuthSystem.GetUserRole(userId)

	-- Check if user is banned
	local SecurityManager = _G.TowerAscent and _G.TowerAscent.SecurityManager
	if SecurityManager and SecurityManager.IsPlayerBanned then
		if SecurityManager.IsPlayerBanned(player) then
			return false, "Account banned", nil
		end
	end

	-- Create session
	local session = Session.new(userId, role)

	-- Store session
	activeSessions[userId] = activeSessions[userId] or {}
	table.insert(activeSessions[userId], session)

	-- Limit sessions per user
	while #activeSessions[userId] > CONFIG.MaxSessionsPerUser do
		local oldSession = table.remove(activeSessions[userId], 1)
		oldSession:Invalidate()
	end

	-- Clear login attempts
	loginAttempts[userId] = nil

	-- Save session to DataStore
	task.spawn(function()
		AuthSystem.SaveSession(session)
	end)

	print(string.format("[AuthSystem] User %d authenticated with role %s", userId, role))

	return true, nil, session
end

function AuthSystem.ValidateToken(token: string): (boolean, Session?)
	for userId, sessions in pairs(activeSessions) do
		for _, session in ipairs(sessions) do
			if session.AccessToken == token or session.RefreshToken == token then
				if session.IsValid and not session:IsExpired() then
					session:Refresh()
					return true, session
				else
					return false, nil
				end
			end
		end
	end

	return false, nil
end

function AuthSystem.RefreshToken(refreshToken: string): (boolean, string?)
	local valid, session = AuthSystem.ValidateToken(refreshToken)
	if valid and session then
		session:Refresh()
		return true, session.AccessToken
	end

	return false, nil
end

function AuthSystem.Logout(player: Player)
	local userId = player.UserId

	if activeSessions[userId] then
		for _, session in ipairs(activeSessions[userId]) do
			session:Invalidate()
		end
		activeSessions[userId] = nil
	end

	print(string.format("[AuthSystem] User %d logged out", userId))
end

-- ============================================================================
-- AUTHORIZATION
-- ============================================================================

function AuthSystem.Authorize(player: Player, permission: string): boolean
	local userId = player.UserId

	-- Get active session
	local sessions = activeSessions[userId]
	if not sessions or #sessions == 0 then
		return false
	end

	-- Check most recent valid session
	for i = #sessions, 1, -1 do
		local session = sessions[i]
		if session.IsValid and not session:IsExpired() then
			return session:HasPermission(permission)
		end
	end

	return false
end

function AuthSystem.GetUserRole(userId: number): string
	-- Check cached roles
	if userRoles[userId] then
		return userRoles[userId]
	end

	-- Check if owner
	if userId == game.CreatorId then
		userRoles[userId] = "OWNER"
		return "OWNER"
	end

	-- Check group ranks (example)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- Example: Check group rank
		local groupId = 0 -- Your group ID
		if groupId > 0 then
			local rank = player:GetRankInGroup(groupId)
			if rank >= 255 then
				userRoles[userId] = "ADMIN"
				return "ADMIN"
			elseif rank >= 200 then
				userRoles[userId] = "MODERATOR"
				return "MODERATOR"
			end
		end

		-- Check if VIP
		-- This would check gamepass ownership or other VIP indicators
		local hasVIP = false -- Check your VIP system
		if hasVIP then
			userRoles[userId] = "VIP"
			return "VIP"
		end
	end

	-- Default role
	userRoles[userId] = "PLAYER"
	return "PLAYER"
end

function AuthSystem.SetUserRole(userId: number, role: string)
	if not ROLES[role] then
		warn("[AuthSystem] Invalid role:", role)
		return
	end

	userRoles[userId] = role

	-- Update sessions
	if activeSessions[userId] then
		for _, session in ipairs(activeSessions[userId]) do
			session.Role = role
		end
	end

	-- Save to DataStore
	task.spawn(function()
		local authData = AuthSystem.GetAuthData(userId)
		authData.Role = role
		AuthSystem.SaveAuthData(userId, authData)
	end)
end

-- ============================================================================
-- LOGIN ATTEMPTS
-- ============================================================================

function AuthSystem.CheckLoginAttempts(userId: number): boolean
	local attempts = loginAttempts[userId]
	if not attempts then
		return true
	end

	-- Clean old attempts
	local now = tick()
	local recentAttempts = {}
	for _, timestamp in ipairs(attempts) do
		if now - timestamp < CONFIG.LoginAttemptWindow then
			table.insert(recentAttempts, timestamp)
		end
	end

	loginAttempts[userId] = recentAttempts
	return #recentAttempts < CONFIG.MaxLoginAttempts
end

function AuthSystem.RecordLoginAttempt(userId: number)
	loginAttempts[userId] = loginAttempts[userId] or {}
	table.insert(loginAttempts[userId], tick())
end

-- ============================================================================
-- TWO-FACTOR AUTHENTICATION
-- ============================================================================

function AuthSystem.Generate2FACode(userId: number): string
	local code = tostring(math.random(100000, 999999))

	twoFactorCodes[userId] = {
		Code = code,
		ExpiresAt = tick() + 300 -- 5 minutes
	}

	-- In a real implementation, send this code via email/SMS
	print(string.format("[AuthSystem] 2FA code for user %d: %s", userId, code))

	return code
end

function AuthSystem.Verify2FACode(userId: number, code: string): boolean
	local storedCode = twoFactorCodes[userId]
	if not storedCode then
		return false
	end

	if tick() > storedCode.ExpiresAt then
		twoFactorCodes[userId] = nil
		return false
	end

	if storedCode.Code == code then
		twoFactorCodes[userId] = nil
		return true
	end

	return false
end

function AuthSystem.Enable2FA(player: Player): boolean
	local userId = player.UserId
	local authData = AuthSystem.GetAuthData(userId)

	authData.TwoFactorEnabled = true
	AuthSystem.SaveAuthData(userId, authData)

	return true
end

function AuthSystem.Disable2FA(player: Player, password: string): boolean
	local userId = player.UserId
	local authData = AuthSystem.GetAuthData(userId)

	-- Verify password
	if authData.PasswordHash and not verifyHash(password, authData.PasswordHash) then
		return false
	end

	authData.TwoFactorEnabled = false
	AuthSystem.SaveAuthData(userId, authData)

	return true
end

-- ============================================================================
-- DATA PERSISTENCE
-- ============================================================================

function AuthSystem.GetAuthData(userId: number): {}
	local success, data = pcall(function()
		return authDataStore:GetAsync("User_" .. userId)
	end)

	if success and data then
		-- Decrypt if encryption is enabled
		local DataEncryption = _G.TowerAscent and _G.TowerAscent.DataEncryption
		if DataEncryption and DataEncryption.DecryptFields then
			return DataEncryption.DecryptFields(data)
		end
		return data
	end

	return {
		UserId = userId,
		Role = "PLAYER",
		CreatedAt = tick()
	}
end

function AuthSystem.SaveAuthData(userId: number, data: {})
	-- Encrypt if encryption is enabled
	local DataEncryption = _G.TowerAscent and _G.TowerAscent.DataEncryption
	if DataEncryption and DataEncryption.EncryptFields then
		data = DataEncryption.EncryptFields(data)
	end

	local success, err = pcall(function()
		authDataStore:SetAsync("User_" .. userId, data)
	end)

	if not success then
		warn("[AuthSystem] Failed to save auth data:", err)
	end
end

function AuthSystem.SaveSession(session: Session)
	local sessionData = {
		SessionId = session.SessionId,
		UserId = session.UserId,
		Role = session.Role,
		CreatedAt = session.CreatedAt,
		ExpiresAt = session.ExpiresAt
	}

	local success, err = pcall(function()
		sessionDataStore:SetAsync(session.SessionId, sessionData)
	end)

	if not success then
		warn("[AuthSystem] Failed to save session:", err)
	end
end

-- ============================================================================
-- PASSWORD MANAGEMENT
-- ============================================================================

function AuthSystem.SetPassword(player: Player, password: string): boolean
	if #password < CONFIG.MinPasswordLength then
		return false
	end

	local userId = player.UserId
	local authData = AuthSystem.GetAuthData(userId)

	authData.PasswordHash = generateSecureHash(password)
	authData.PasswordChangedAt = tick()

	AuthSystem.SaveAuthData(userId, authData)
	return true
end

function AuthSystem.ChangePassword(player: Player, oldPassword: string, newPassword: string): boolean
	if #newPassword < CONFIG.MinPasswordLength then
		return false
	end

	local userId = player.UserId
	local authData = AuthSystem.GetAuthData(userId)

	-- Verify old password
	if authData.PasswordHash and not verifyHash(oldPassword, authData.PasswordHash) then
		return false
	end

	authData.PasswordHash = generateSecureHash(newPassword)
	authData.PasswordChangedAt = tick()

	AuthSystem.SaveAuthData(userId, authData)

	-- Invalidate all sessions
	AuthSystem.Logout(player)

	return true
end

-- ============================================================================
-- SESSION MONITORING
-- ============================================================================

function AuthSystem.CleanupExpiredSessions()
	for userId, sessions in pairs(activeSessions) do
		local validSessions = {}
		for _, session in ipairs(sessions) do
			if session.IsValid and not session:IsExpired() then
				table.insert(validSessions, session)
			end
		end
		if #validSessions > 0 then
			activeSessions[userId] = validSessions
		else
			activeSessions[userId] = nil
		end
	end
end

function AuthSystem.GetActiveSessions(player: Player): {}
	local userId = player.UserId
	return activeSessions[userId] or {}
end

function AuthSystem.GetAllActiveSessions(): {}
	local allSessions = {}
	for userId, sessions in pairs(activeSessions) do
		for _, session in ipairs(sessions) do
			if session.IsValid and not session:IsExpired() then
				table.insert(allSessions, {
					UserId = userId,
					SessionId = session.SessionId,
					Role = session.Role,
					CreatedAt = session.CreatedAt,
					ExpiresAt = session.ExpiresAt
				})
			end
		end
	end
	return allSessions
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function AuthSystem.IsAuthenticated(player: Player): boolean
	local userId = player.UserId
	local sessions = activeSessions[userId]

	if not sessions then
		return false
	end

	for _, session in ipairs(sessions) do
		if session.IsValid and not session:IsExpired() then
			return true
		end
	end

	return false
end

function AuthSystem.RequireAuth(player: Player, permission: string?): boolean
	if not AuthSystem.IsAuthenticated(player) then
		return false
	end

	if permission then
		return AuthSystem.Authorize(player, permission)
	end

	return true
end

function AuthSystem.GetPlayerPermissions(player: Player): {}
	local userId = player.UserId
	local sessions = activeSessions[userId]

	if not sessions or #sessions == 0 then
		return {}
	end

	for i = #sessions, 1, -1 do
		local session = sessions[i]
		if session.IsValid and not session:IsExpired() then
			local role = ROLES[session.Role]
			return role and role.Permissions or {}
		end
	end

	return {}
end

-- ============================================================================
-- EVENTS
-- ============================================================================

local function onPlayerAdded(player: Player)
	-- Auto-authenticate player
	local success, error, session = AuthSystem.Authenticate(player)

	if success and session then
		-- Send session info to client (if needed)
		-- You would use a RemoteEvent here
	end
end

local function onPlayerRemoving(player: Player)
	AuthSystem.Logout(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function AuthSystem.Initialize()
	print("[AuthSystem] Initializing authentication system...")

	-- Start session cleanup
	task.spawn(function()
		while AuthSystem.Enabled do
			task.wait(60) -- Every minute
			AuthSystem.CleanupExpiredSessions()
		end
	end)

	-- Register with global table
	if _G.TowerAscent then
		_G.TowerAscent.AuthSystem = AuthSystem
	end

	-- Register with SecurityManager
	local SecurityManager = _G.TowerAscent and _G.TowerAscent.SecurityManager
	if SecurityManager then
		SecurityManager.AuthSystem = AuthSystem
	end

	print("[AuthSystem] ✅ Authentication system ready")
end

-- Auto-initialize
task.spawn(function()
	task.wait(1)
	AuthSystem.Initialize()
end)

-- ============================================================================
-- EXPORT
-- ============================================================================

return AuthSystem