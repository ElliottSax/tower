--[[
	WebhookLogger.lua
	Centralized webhook logging for security events and analytics

	Features:
	- Discord webhook integration
	- Rate limiting to prevent spam
	- Event queuing and batching
	- Automatic retry on failure
	- Color-coded severity levels

	Configuration:
	- Set webhook URL in ServerScriptService/Config.lua or via SetWebhookUrl()

	Usage:
		WebhookLogger.LogSecurityEvent("EXPLOIT_DETECTED", {
			Player = player.Name,
			ViolationType = "SPEED_HACK",
			Details = "Player moving at 500 studs/s"
		})

	Created: 2025-12-17
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local WebhookLogger = {}
WebhookLogger.Enabled = true

-- Configuration
local CONFIG = {
	WebhookURL = "", -- Set via SetWebhookUrl() or Config.lua
	MaxRequestsPerMinute = 30,
	BatchSize = 5, -- Send up to 5 events per webhook call
	BatchDelay = 5, -- Wait 5 seconds before sending batch
	RetryAttempts = 3,
	RetryDelay = 2,
}

-- Event queue
local eventQueue = {}
local lastWebhookTime = 0
local requestCount = 0
local requestResetTime = tick()

-- Severity colors for Discord embeds
local SEVERITY_COLORS = {
	INFO = 3447003, -- Blue
	WARNING = 16776960, -- Yellow
	ERROR = 16711680, -- Red
	CRITICAL = 10038562, -- Dark red
	SECURITY = 15158332, -- Orange
}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

function WebhookLogger.SetWebhookUrl(url: string)
	CONFIG.WebhookURL = url
	print("[WebhookLogger] Webhook URL configured")
end

function WebhookLogger.GetWebhookUrl(): string
	return CONFIG.WebhookURL
end

-- ============================================================================
-- RATE LIMITING
-- ============================================================================

local function checkRateLimit(): boolean
	local now = tick()

	-- Reset counter every minute
	if now - requestResetTime > 60 then
		requestCount = 0
		requestResetTime = now
	end

	-- Check limit
	if requestCount >= CONFIG.MaxRequestsPerMinute then
		warn("[WebhookLogger] Rate limit exceeded, dropping event")
		return false
	end

	requestCount = requestCount + 1
	return true
end

-- ============================================================================
-- WEBHOOK SENDING
-- ============================================================================

local function sendWebhook(embed: {}): boolean
	if not CONFIG.WebhookURL or CONFIG.WebhookURL == "" then
		warn("[WebhookLogger] Webhook URL not configured")
		return false
	end

	if not checkRateLimit() then
		return false
	end

	local payload = {
		embeds = {embed}
	}

	local success = false
	local attempts = 0

	while not success and attempts < CONFIG.RetryAttempts do
		attempts = attempts + 1

		local ok, response = pcall(function()
			return HttpService:PostAsync(
				CONFIG.WebhookURL,
				HttpService:JSONEncode(payload),
				Enum.HttpContentType.ApplicationJson,
				false
			)
		end)

		if ok then
			success = true
		else
			warn(string.format("[WebhookLogger] Failed to send webhook (attempt %d/%d): %s",
				attempts, CONFIG.RetryAttempts, tostring(response)))

			if attempts < CONFIG.RetryAttempts then
				task.wait(CONFIG.RetryDelay)
			end
		end
	end

	return success
end

-- ============================================================================
-- EVENT LOGGING
-- ============================================================================

function WebhookLogger.LogEvent(title: string, description: string, severity: string?, fields: {}?)
	if not WebhookLogger.Enabled then return end

	-- Create embed
	local embed = {
		title = title,
		description = description,
		color = SEVERITY_COLORS[severity] or SEVERITY_COLORS.INFO,
		timestamp = DateTime.now():ToIsoDate(),
		fields = fields or {},
	}

	-- Add game info
	table.insert(embed.fields, {
		name = "Game",
		value = string.format("%s (PlaceId: %d)", game.Name, game.PlaceId),
		inline = true
	})

	table.insert(embed.fields, {
		name = "JobId",
		value = game.JobId,
		inline = true
	})

	-- Queue or send immediately
	table.insert(eventQueue, embed)

	-- Send if batch size reached
	if #eventQueue >= CONFIG.BatchSize then
		WebhookLogger.FlushQueue()
	end
end

function WebhookLogger.LogSecurityEvent(violationType: string, data: {})
	local fields = {}

	-- Add all data as fields
	for key, value in pairs(data) do
		table.insert(fields, {
			name = key,
			value = tostring(value),
			inline = true
		})
	end

	WebhookLogger.LogEvent(
		string.format("🚨 Security Alert: %s", violationType),
		string.format("A security violation was detected in the game."),
		"SECURITY",
		fields
	)
end

function WebhookLogger.LogExploitDetection(player: Player, exploitType: string, details: {})
	local fields = {
		{name = "Player", value = player.Name, inline = true},
		{name = "UserId", value = tostring(player.UserId), inline = true},
		{name = "Exploit Type", value = exploitType, inline = false},
	}

	-- Add details
	for key, value in pairs(details) do
		table.insert(fields, {
			name = key,
			value = tostring(value),
			inline = true
		})
	end

	WebhookLogger.LogEvent(
		"⚠️ Exploit Detected",
		string.format("Player **%s** was detected using exploits", player.Name),
		"CRITICAL",
		fields
	)
end

function WebhookLogger.LogBan(player: Player, reason: string, duration: number)
	WebhookLogger.LogEvent(
		"🔨 Player Banned",
		string.format("Player **%s** has been banned", player.Name),
		"WARNING",
		{
			{name = "Player", value = player.Name, inline = true},
			{name = "UserId", value = tostring(player.UserId), inline = true},
			{name = "Reason", value = reason, inline = false},
			{name = "Duration", value = string.format("%d hours", math.floor(duration / 3600)), inline = true},
		}
	)
end

function WebhookLogger.LogCriticalError(errorMessage: string, stackTrace: string?)
	WebhookLogger.LogEvent(
		"💥 Critical Error",
		errorMessage,
		"ERROR",
		{
			{name = "Stack Trace", value = stackTrace or "N/A", inline = false},
		}
	)
end

function WebhookLogger.LogPlayerCount()
	local playerCount = #Players:GetPlayers()

	WebhookLogger.LogEvent(
		"📊 Server Statistics",
		string.format("Server has %d players", playerCount),
		"INFO",
		{
			{name = "Players", value = tostring(playerCount), inline = true},
			{name = "Max Players", value = tostring(Players.MaxPlayers), inline = true},
		}
	)
end

-- ============================================================================
-- QUEUE MANAGEMENT
-- ============================================================================

function WebhookLogger.FlushQueue()
	if #eventQueue == 0 then return end

	-- Send first embed immediately
	local firstEmbed = table.remove(eventQueue, 1)
	if firstEmbed then
		sendWebhook(firstEmbed)
	end

	-- Send remaining embeds (if any) after delay
	if #eventQueue > 0 then
		task.spawn(function()
			for _, embed in ipairs(eventQueue) do
				task.wait(1) -- Space out requests
				sendWebhook(embed)
			end
			eventQueue = {}
		end)
	end
end

function WebhookLogger.ClearQueue()
	eventQueue = {}
	print("[WebhookLogger] Event queue cleared")
end

-- ============================================================================
-- AUTOMATIC FLUSHING
-- ============================================================================

function WebhookLogger.StartAutoFlush()
	task.spawn(function()
		while WebhookLogger.Enabled do
			task.wait(CONFIG.BatchDelay)

			if #eventQueue > 0 then
				WebhookLogger.FlushQueue()
			end
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function WebhookLogger.Initialize()
	print("[WebhookLogger] Initializing webhook logger...")

	-- Try to load webhook URL from config
	local success, Config = pcall(function()
		return require(script.Parent.Parent.Config)
	end)

	if success and Config and Config.WebhookURL then
		CONFIG.WebhookURL = Config.WebhookURL
		print("[WebhookLogger] Loaded webhook URL from Config")
	end

	-- Start auto-flush
	WebhookLogger.StartAutoFlush()

	print("[WebhookLogger] ✅ Webhook logger initialized")
end

-- Auto-initialize
task.spawn(function()
	task.wait(1)
	WebhookLogger.Initialize()
end)

-- ============================================================================
-- EXPORT
-- ============================================================================

return WebhookLogger
