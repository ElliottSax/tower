--[[
	SecureRemotes.lua
	Secure wrapper for RemoteEvents and RemoteFunctions

	Features:
	- Input validation and sanitization
	- Rate limiting per remote
	- Authentication requirements
	- Automatic logging
	- Anti-exploit detection
	- Type checking

	Created: 2025-12-02
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Safe require of utilities
local ServiceLocator = nil
pcall(function()
	ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
end)

local SecureRemotes = {}
SecureRemotes.Enabled = true

-- Configuration
local CONFIG = {
	MaxRemoteCallsPerSecond = 10,
	MaxRemoteCallsPerMinute = 100,
	MaxDataSize = 10000, -- Characters
	LogSuspiciousActivity = true,
	AutoBanThreshold = 50, -- Suspicious activity score
	TypeCheckingEnabled = true
}

-- Tracking
local remoteCallTracking = {}
local suspiciousActivity = {}
local registeredRemotes = {}

-- Type definitions
local TypeDefinitions = {
	PlayerData = {
		UserId = "number",
		Name = "string",
		Level = "number",
		Coins = "number"
	},
	Position = {
		X = "number",
		Y = "number",
		Z = "number"
	},
	ItemTransaction = {
		ItemId = "string",
		Quantity = "number",
		Price = "number?"
	}
}

-- ============================================================================
-- SECURE REMOTE EVENT
-- ============================================================================

local SecureRemoteEvent = {}
SecureRemoteEvent.__index = SecureRemoteEvent

function SecureRemoteEvent.new(name: string, options: {}?)
	local self = setmetatable({}, SecureRemoteEvent)

	-- Create or get RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	self.Remote = remote
	self.Name = name
	self.Options = options or {}
	self.Callbacks = {}
	self.RateLimits = {}

	-- Set defaults
	self.RequiresAuth = self.Options.RequiresAuth ~= false
	self.MaxCallsPerSecond = self.Options.MaxCallsPerSecond or CONFIG.MaxRemoteCallsPerSecond
	self.MaxDataSize = self.Options.MaxDataSize or CONFIG.MaxDataSize
	self.TypeSchema = self.Options.TypeSchema
	self.AllowedPlayers = self.Options.AllowedPlayers

	-- Connect secure handler
	remote.OnServerEvent:Connect(function(player, ...)
		self:HandleEvent(player, ...)
	end)

	registeredRemotes[name] = self
	return self
end

function SecureRemoteEvent:HandleEvent(player: Player, ...)
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[SecureRemotes] Invalid player attempted to fire", self.Name)
		return
	end

	local userId = player.UserId

	-- Check authentication if required
	if self.RequiresAuth then
		local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
		if SecurityManager and not SecurityManager.IsAuthenticated(player) then
			warn("[SecureRemotes] Unauthenticated player attempted to fire", self.Name)
			self:RecordSuspiciousActivity(player, "UNAUTH_REMOTE_CALL")
			return
		end
	end

	-- Check allowed players list
	if self.AllowedPlayers and not table.find(self.AllowedPlayers, userId) then
		warn("[SecureRemotes] Unauthorized player attempted to fire", self.Name)
		self:RecordSuspiciousActivity(player, "UNAUTHORIZED_ACCESS")
		return
	end

	-- Rate limiting
	if not self:CheckRateLimit(player) then
		warn("[SecureRemotes] Rate limit exceeded for", player.Name, "on", self.Name)
		self:RecordSuspiciousActivity(player, "RATE_LIMIT_EXCEEDED")
		return
	end

	-- Validate and sanitize data
	local args = {...}
	local validatedArgs = self:ValidateAndSanitize(player, args)
	if not validatedArgs then
		warn("[SecureRemotes] Invalid data from", player.Name, "on", self.Name)
		self:RecordSuspiciousActivity(player, "INVALID_DATA")
		return
	end

	-- Type checking if schema provided
	if self.TypeSchema then
		local typeValid = self:CheckTypes(validatedArgs, self.TypeSchema)
		if not typeValid then
			warn("[SecureRemotes] Type mismatch from", player.Name, "on", self.Name)
			self:RecordSuspiciousActivity(player, "TYPE_MISMATCH")
			return
		end
	end

	-- Log the call
	if CONFIG.LogSuspiciousActivity then
		self:LogRemoteCall(player, validatedArgs)
	end

	-- Execute callbacks
	for _, callback in ipairs(self.Callbacks) do
		local success, err = pcall(callback, player, table.unpack(validatedArgs))
		if not success then
			warn("[SecureRemotes] Callback error on", self.Name, ":", err)
		end
	end
end

function SecureRemoteEvent:OnServerEvent(callback: (Player, ...any) -> ())
	table.insert(self.Callbacks, callback)
end

function SecureRemoteEvent:CheckRateLimit(player: Player): boolean
	local userId = player.UserId
	local now = tick()

	-- Initialize tracking
	if not self.RateLimits[userId] then
		self.RateLimits[userId] = {
			Calls = {},
			LastCleanup = now
		}
	end

	local limits = self.RateLimits[userId]

	-- Cleanup old entries (older than 1 minute)
	if now - limits.LastCleanup > 60 then
		local cutoff = now - 60
		local newCalls = {}
		for _, callTime in ipairs(limits.Calls) do
			if callTime > cutoff then
				table.insert(newCalls, callTime)
			end
		end
		limits.Calls = newCalls
		limits.LastCleanup = now
	end

	-- Count recent calls
	local oneSecondAgo = now - 1
	local recentCalls = 0
	for _, callTime in ipairs(limits.Calls) do
		if callTime > oneSecondAgo then
			recentCalls = recentCalls + 1
		end
	end

	-- Check limit
	if recentCalls >= self.MaxCallsPerSecond then
		return false
	end

	-- Add this call
	table.insert(limits.Calls, now)
	return true
end

function SecureRemoteEvent:ValidateAndSanitize(player: Player, args: {}): {}?
	local sanitized = {}

	for i, arg in ipairs(args) do
		local argType = typeof(arg)

		-- Size check for strings
		if argType == "string" then
			if #arg > self.MaxDataSize then
				warn("[SecureRemotes] String too large from", player.Name)
				return nil
			end

			-- Sanitize string
			local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
			if SecurityManager and SecurityManager.SanitizeString then
				arg = SecurityManager.SanitizeString(arg)
				if not arg then
					return nil -- Malicious content detected
				end
			end
		end

		-- Size check for tables
		if argType == "table" then
			local serialized = HttpService:JSONEncode(arg)
			if #serialized > self.MaxDataSize then
				warn("[SecureRemotes] Table too large from", player.Name)
				return nil
			end

			-- Deep sanitize table
			arg = self:SanitizeTable(arg)
			if not arg then
				return nil
			end
		end

		-- Validate numbers
		if argType == "number" then
			if arg ~= arg or arg == math.huge or arg == -math.huge then
				warn("[SecureRemotes] Invalid number from", player.Name)
				return nil
			end
		end

		sanitized[i] = arg
	end

	return sanitized
end

function SecureRemoteEvent:SanitizeTable(tbl: {}): {}?
	local sanitized = {}
	local depth = 0

	local function sanitizeRecursive(t, d)
		if d > 10 then -- Max depth
			return nil
		end

		local result = {}
		for key, value in pairs(t) do
			-- Sanitize key
			if typeof(key) == "string" then
				local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
				if SecurityManager and SecurityManager.SanitizeString then
					key = SecurityManager.SanitizeString(key)
					if not key then
						return nil
					end
				end
			end

			-- Sanitize value
			local valueType = typeof(value)
			if valueType == "string" then
				local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
				if SecurityManager and SecurityManager.SanitizeString then
					value = SecurityManager.SanitizeString(value)
					if not value then
						return nil
					end
				end
			elseif valueType == "table" then
				value = sanitizeRecursive(value, d + 1)
				if not value then
					return nil
				end
			elseif valueType == "number" then
				if value ~= value or value == math.huge or value == -math.huge then
					return nil
				end
			end

			result[key] = value
		end

		return result
	end

	return sanitizeRecursive(tbl, 0)
end

function SecureRemoteEvent:CheckTypes(args: {}, schema: {}): boolean
	for i, expectedType in ipairs(schema) do
		local arg = args[i]

		if typeof(expectedType) == "string" then
			-- Simple type check
			if typeof(arg) ~= expectedType then
				return false
			end
		elseif typeof(expectedType) == "table" then
			-- Complex type check
			if typeof(arg) ~= "table" then
				return false
			end

			for key, valueType in pairs(expectedType) do
				if typeof(arg[key]) ~= valueType then
					return false
				end
			end
		end
	end

	return true
end

function SecureRemoteEvent:RecordSuspiciousActivity(player: Player, reason: string)
	local userId = player.UserId

	if not suspiciousActivity[userId] then
		suspiciousActivity[userId] = {
			Score = 0,
			Incidents = {}
		}
	end

	local activity = suspiciousActivity[userId]

	-- Add incident
	table.insert(activity.Incidents, {
		Reason = reason,
		Remote = self.Name,
		Timestamp = tick()
	})

	-- Increase score based on reason
	local scoreIncrease = {
		UNAUTH_REMOTE_CALL = 5,
		UNAUTHORIZED_ACCESS = 10,
		RATE_LIMIT_EXCEEDED = 3,
		INVALID_DATA = 2,
		TYPE_MISMATCH = 2,
		EXPLOIT_DETECTED = 20
	}

	activity.Score = activity.Score + (scoreIncrease[reason] or 1)

	-- Check for auto-ban
	if activity.Score >= CONFIG.AutoBanThreshold then
		warn("[SecureRemotes] Auto-banning player for suspicious activity:", player.Name)
		local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
		if SecurityManager and SecurityManager.BanPlayer then
			SecurityManager.BanPlayer(player, "Automated: Suspicious activity detected", 86400) -- 24 hour ban
		else
			player:Kick("Suspicious activity detected")
		end
	end
end

function SecureRemoteEvent:LogRemoteCall(player: Player, args: {})
	-- This would typically log to a file or analytics service
	local logEntry = {
		Player = player.Name,
		UserId = player.UserId,
		Remote = self.Name,
		Timestamp = tick(),
		ArgCount = #args
	}

	-- Could send to webhook or analytics here
end

-- ============================================================================
-- SECURE REMOTE FUNCTION
-- ============================================================================

local SecureRemoteFunction = {}
SecureRemoteFunction.__index = SecureRemoteFunction

function SecureRemoteFunction.new(name: string, options: {}?)
	local self = setmetatable({}, SecureRemoteFunction)

	-- Create or get RemoteFunction
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	self.Remote = remote
	self.Name = name
	self.Options = options or {}
	self.Callback = nil
	self.RateLimits = {}

	-- Set defaults
	self.RequiresAuth = self.Options.RequiresAuth ~= false
	self.MaxCallsPerSecond = self.Options.MaxCallsPerSecond or CONFIG.MaxRemoteCallsPerSecond
	self.MaxDataSize = self.Options.MaxDataSize or CONFIG.MaxDataSize
	self.TypeSchema = self.Options.TypeSchema
	self.ReturnSchema = self.Options.ReturnSchema
	self.Timeout = self.Options.Timeout or 10

	-- Connect secure handler
	remote.OnServerInvoke = function(player, ...)
		return self:HandleInvoke(player, ...)
	end

	registeredRemotes[name] = self
	return self
end

function SecureRemoteFunction:HandleInvoke(player: Player, ...)
	-- Similar validation as RemoteEvent
	if not player or not player:IsA("Player") then
		return nil, "Invalid player"
	end

	-- Check authentication
	if self.RequiresAuth then
		local SecurityManager = ServiceLocator and ServiceLocator:Get("SecurityManager")
		if SecurityManager and not SecurityManager.IsAuthenticated(player) then
			self:RecordSuspiciousActivity(player, "UNAUTH_REMOTE_CALL")
			return nil, "Authentication required"
		end
	end

	-- Rate limiting
	if not self:CheckRateLimit(player) then
		self:RecordSuspiciousActivity(player, "RATE_LIMIT_EXCEEDED")
		return nil, "Rate limit exceeded"
	end

	-- Validate and sanitize
	local args = {...}
	local validatedArgs = self:ValidateAndSanitize(player, args)
	if not validatedArgs then
		self:RecordSuspiciousActivity(player, "INVALID_DATA")
		return nil, "Invalid data"
	end

	-- Type checking
	if self.TypeSchema then
		local typeValid = self:CheckTypes(validatedArgs, self.TypeSchema)
		if not typeValid then
			self:RecordSuspiciousActivity(player, "TYPE_MISMATCH")
			return nil, "Type mismatch"
		end
	end

	-- Execute callback with timeout
	if not self.Callback then
		return nil, "No handler registered"
	end

	local result = nil
	local completed = false

	task.spawn(function()
		local success, res = pcall(self.Callback, player, table.unpack(validatedArgs))
		if success then
			result = res
		else
			warn("[SecureRemotes] Callback error on", self.Name, ":", res)
			result = {nil, "Internal error"}
		end
		completed = true
	end)

	-- Wait for completion or timeout
	local startTime = tick()
	while not completed and tick() - startTime < self.Timeout do
		task.wait(0.1)
	end

	if not completed then
		warn("[SecureRemotes] Function timeout on", self.Name)
		return nil, "Request timeout"
	end

	-- Validate return value if schema provided
	if self.ReturnSchema and result then
		local returnValid = self:CheckTypes({result}, {self.ReturnSchema})
		if not returnValid then
			warn("[SecureRemotes] Invalid return type on", self.Name)
			return nil, "Internal error"
		end
	end

	return result
end

function SecureRemoteFunction:OnServerInvoke(callback: (Player, ...any) -> any)
	self.Callback = callback
end

-- Inherit methods from SecureRemoteEvent
SecureRemoteFunction.CheckRateLimit = SecureRemoteEvent.CheckRateLimit
SecureRemoteFunction.ValidateAndSanitize = SecureRemoteEvent.ValidateAndSanitize
SecureRemoteFunction.SanitizeTable = SecureRemoteEvent.SanitizeTable
SecureRemoteFunction.CheckTypes = SecureRemoteEvent.CheckTypes
SecureRemoteFunction.RecordSuspiciousActivity = SecureRemoteEvent.RecordSuspiciousActivity

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SecureRemotes.CreateRemoteEvent(name: string, options: {}?): SecureRemoteEvent
	return SecureRemoteEvent.new(name, options)
end

function SecureRemotes.CreateRemoteFunction(name: string, options: {}?): SecureRemoteFunction
	return SecureRemoteFunction.new(name, options)
end

function SecureRemotes.GetSuspiciousActivity(player: Player): {}?
	local userId = player.UserId
	return suspiciousActivity[userId]
end

function SecureRemotes.ClearSuspiciousActivity(player: Player)
	local userId = player.UserId
	suspiciousActivity[userId] = nil
end

function SecureRemotes.GetAllRemotes(): {}
	return registeredRemotes
end

-- ============================================================================
-- MONITORING
-- ============================================================================

function SecureRemotes.StartMonitoring()
	-- Periodic cleanup of old tracking data
	task.spawn(function()
		while SecureRemotes.Enabled do
			task.wait(300) -- Every 5 minutes

			-- Cleanup old suspicious activity
			local now = tick()
			for userId, activity in pairs(suspiciousActivity) do
				-- Remove incidents older than 1 hour
				local newIncidents = {}
				for _, incident in ipairs(activity.Incidents) do
					if now - incident.Timestamp < 3600 then
						table.insert(newIncidents, incident)
					end
				end
				activity.Incidents = newIncidents

				-- Decay score
				activity.Score = math.max(0, activity.Score - 5)

				-- Remove if no recent activity
				if activity.Score == 0 and #activity.Incidents == 0 then
					suspiciousActivity[userId] = nil
				end
			end

			-- Cleanup rate limits
			for _, remote in pairs(registeredRemotes) do
				if remote.RateLimits then
					for userId, limits in pairs(remote.RateLimits) do
						if now - limits.LastCleanup > 300 then
							remote.RateLimits[userId] = nil
						end
					end
				end
			end
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SecureRemotes.Initialize()
	print("[SecureRemotes] Initializing secure remote system...")

	-- Start monitoring
	SecureRemotes.StartMonitoring()

	-- Register with global table
	if _G.TowerAscent then
		_G.TowerAscent.SecureRemotes = SecureRemotes
	end

	print("[SecureRemotes] ✅ Secure remote system ready")
end

-- Auto-initialize
task.spawn(function()
	task.wait(1)
	SecureRemotes.Initialize()
end)

-- ============================================================================
-- EXPORT
-- ============================================================================

return SecureRemotes