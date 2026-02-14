--[[
	BugReportService.lua
	Server-side bug report handler and crash recovery

	Features:
	- Receives player bug reports
	- Automatic crash recovery
	- Bug deduplication
	- Webhook integration
	- Admin notifications
	- Automatic responses

	Created: 2025-12-02 (Server Bug Handling)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local BugReportService = {}
BugReportService.Enabled = true

-- Create RemoteEvent for client reports
local bugReportRemote = Instance.new("RemoteEvent")
bugReportRemote.Name = "BugReport"
bugReportRemote.Parent = ReplicatedStorage

-- DataStore for persistent bug tracking
local bugDataStore = DataStoreService:GetDataStore("BugReports")

-- Configuration
local CONFIG = {
	WebhookUrl = "", -- Set your Discord/Slack webhook URL here
	MaxReportsPerPlayer = 10, -- Per hour
	AutoRecoveryEnabled = true,
	NotifyAdmins = true,
	SaveToDataStore = true,
	CriticalThreshold = 5 -- Number of same critical bugs before emergency action
}

-- Tracking
local playerReportCounts = {}
local criticalBugCounts = {}

-- ============================================================================
-- PLAYER BUG REPORT HANDLING
-- ============================================================================

bugReportRemote.OnServerEvent:Connect(function(player, reportData)
	-- Validate player
	if not player or not player:IsA("Player") then
		return
	end

	-- Rate limiting
	local userId = player.UserId
	playerReportCounts[userId] = playerReportCounts[userId] or {Count = 0, Reset = tick() + 3600}

	if tick() > playerReportCounts[userId].Reset then
		playerReportCounts[userId] = {Count = 0, Reset = tick() + 3600}
	end

	if playerReportCounts[userId].Count >= CONFIG.MaxReportsPerPlayer then
		-- Notify player they're rate limited
		return
	end

	playerReportCounts[userId].Count = playerReportCounts[userId].Count + 1

	-- Process report
	BugReportService.ProcessPlayerReport(player, reportData)
end)

function BugReportService.ProcessPlayerReport(player: Player, data: {})
	-- Get BugReporter if available
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter

	-- Validate data
	local category = data.Category or "OTHER"
	local description = data.Description or "No description provided"

	-- Add player context
	local enhancedData = {
		PlayerReport = true,
		ReportedBy = {
			UserId = player.UserId,
			Name = player.Name,
			AccountAge = player.AccountAge
		},
		ClientContext = data.Context,
		ReproductionSteps = data.ReproductionSteps or data.Steps,
		Screenshot = data.Screenshot,
		ServerContext = {
			JobId = game.JobId,
			PlaceVersion = game.PlaceVersion,
			PlayerCount = #Players:GetPlayers(),
			Memory = game:GetService("Stats"):GetTotalMemoryUsageMb()
		}
	}

	-- Create bug report
	local report = nil
	if BugReporter then
		report = BugReporter.ReportBug(category, description, enhancedData, player)
	else
		-- Fallback if BugReporter not available
		report = {
			Id = HttpService:GenerateGUID(false),
			Category = category,
			Description = description,
			Data = enhancedData,
			Timestamp = tick()
		}
	end

	-- Handle based on category
	if category == "CRASH" or category == "DATA" then
		BugReportService.HandleCriticalReport(report, player)
	end

	-- Save to DataStore if enabled
	if CONFIG.SaveToDataStore then
		task.spawn(function()
			BugReportService.SaveReport(report)
		end)
	end

	-- Send to webhook if configured
	if CONFIG.WebhookUrl and CONFIG.WebhookUrl ~= "" then
		task.spawn(function()
			BugReportService.SendToWebhook(report)
		end)
	end

	-- Notify admins if enabled
	if CONFIG.NotifyAdmins then
		BugReportService.NotifyAdmins(report, player)
	end

	-- Thank the player
	BugReportService.SendResponse(player, "Thank you for your bug report! We'll investigate it.")

	return report
end

-- ============================================================================
-- CRITICAL BUG HANDLING
-- ============================================================================

function BugReportService.HandleCriticalReport(report: {}, player: Player?)
	local bugKey = report.Category .. ":" .. report.Description:sub(1, 50)

	-- Track critical bug frequency
	criticalBugCounts[bugKey] = (criticalBugCounts[bugKey] or 0) + 1

	warn(string.format("🚨 [CRITICAL BUG] %s - Count: %d",
		bugKey, criticalBugCounts[bugKey]))

	-- Take action if threshold reached
	if criticalBugCounts[bugKey] >= CONFIG.CriticalThreshold then
		BugReportService.EmergencyResponse(report)
	end

	-- Attempt recovery if enabled
	if CONFIG.AutoRecoveryEnabled then
		if report.Category == "DATA" and player then
			BugReportService.AttemptDataRecovery(player)
		elseif report.Category == "CRASH" then
			BugReportService.AttemptCrashRecovery()
		end
	end
end

function BugReportService.EmergencyResponse(report: {})
	warn("⚠️ [EMERGENCY] Critical bug threshold reached!")

	-- Notify all players
	for _, player in ipairs(Players:GetPlayers()) do
		BugReportService.SendResponse(player,
			"⚠️ We're experiencing technical issues. Your data is being protected.")
	end

	-- Enable all safety systems
	local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
	if ErrorRecovery and ErrorRecovery.EnableAutoRecovery then
		ErrorRecovery.EnableAutoRecovery()
	end

	-- Force save all data
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService and DataService.SaveAllProfiles then
		task.spawn(function()
			DataService.SaveAllProfiles()
			print("📁 Emergency save completed")
		end)
	end

	-- Consider shutdown if too severe
	-- game:Shutdown() -- Uncomment only if you want automatic shutdown
end

-- ============================================================================
-- RECOVERY SYSTEMS
-- ============================================================================

function BugReportService.AttemptDataRecovery(player: Player)
	print(string.format("🔧 Attempting data recovery for %s", player.Name))

	local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
	if ErrorRecovery and ErrorRecovery.RecoverPlayerData then
		local success = ErrorRecovery.RecoverPlayerData(player)
		if success then
			BugReportService.SendResponse(player, "✅ Your data has been recovered.")
		else
			BugReportService.SendResponse(player, "⚠️ Data recovery in progress...")
		end
	end
end

function BugReportService.AttemptCrashRecovery()
	print("🔧 Attempting crash recovery...")

	local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
	if not ErrorRecovery then
		return
	end

	-- Try to recover tower
	if ErrorRecovery.RecoverTower then
		task.spawn(function()
			ErrorRecovery.RecoverTower()
		end)
	end

	-- Reset circuit breakers
	if ErrorRecovery.CircuitBreakers then
		for serviceName, breaker in pairs(ErrorRecovery.CircuitBreakers) do
			if breaker.State == "OPEN" then
				ErrorRecovery.ResetCircuitBreaker(serviceName)
			end
		end
	end

	print("✅ Crash recovery attempted")
end

-- ============================================================================
-- CRASH DETECTION
-- ============================================================================

function BugReportService.MonitorForCrashes()
	-- Monitor player disconnections
	Players.PlayerRemoving:Connect(function(player)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health <= 0 then
				-- Player died before leaving - potential crash
				local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
				if BugReporter and BugReporter.ReportCrash then
					BugReporter.ReportCrash(player, "Player death disconnect", {
						Position = character.PrimaryPart and character.PrimaryPart.Position,
						Health = 0
					})
				end
			end
		end

		-- Check if player had unsaved data
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService and DataService.HasUnsavedData and DataService.HasUnsavedData(player) then
			-- Force save
			if DataService.SaveProfile then
				task.spawn(function()
					DataService.SaveProfile(player)
				end)
			end
		end
	end)

	-- Monitor script errors
	game:GetService("ScriptContext").Error:Connect(function(message, stack, script)
		-- Check for critical patterns
		if message:find("DataService") or
		   message:find("ProfileService") or
		   message:find("data") then
			-- Critical data error
			local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
			if BugReporter then
				BugReporter.ReportBug("DATA",
					"Critical data error detected",
					{Error = message, Stack = stack, Script = script and script:GetFullName()})
			end

			-- Attempt recovery
			BugReportService.AttemptCrashRecovery()
		end
	end)
end

-- ============================================================================
-- DATA PERSISTENCE
-- ============================================================================

function BugReportService.SaveReport(report: {})
	if not CONFIG.SaveToDataStore then
		return
	end

	local key = "BugReport_" .. report.Id
	local success, err = pcall(function()
		-- Simplify report for storage
		local storedData = {
			Id = report.Id,
			Category = report.Category,
			Description = report.Description:sub(1, 200),
			Priority = report.Priority,
			Timestamp = report.Timestamp,
			JobId = game.JobId
		}

		bugDataStore:SetAsync(key, HttpService:JSONEncode(storedData))
	end)

	if not success then
		warn("[BugReportService] Failed to save report:", err)
	end
end

function BugReportService.LoadRecentReports()
	-- This would load recent reports from DataStore
	-- Implementation depends on your needs
end

-- ============================================================================
-- WEBHOOK INTEGRATION
-- ============================================================================

function BugReportService.SendToWebhook(report: {})
	if not CONFIG.WebhookUrl or CONFIG.WebhookUrl == "" then
		return
	end

	local webhookData = {
		embeds = {{
			title = string.format("🐛 Bug Report: %s", report.Category),
			description = report.Description:sub(1, 1000),
			color = report.Priority == "CRITICAL" and 16711680 or
					report.Priority == "HIGH" and 16744192 or
					report.Priority == "MEDIUM" and 16776960 or
					8421504,
			fields = {
				{
					name = "Report ID",
					value = report.Id:sub(1, 8),
					inline = true
				},
				{
					name = "Priority",
					value = report.Priority or "UNKNOWN",
					inline = true
				},
				{
					name = "Server",
					value = string.format("JobId: %s", game.JobId:sub(1, 8)),
					inline = true
				}
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		}}
	}

	-- Add player info if available
	if report.ReportedBy then
		table.insert(webhookData.embeds[1].fields, {
			name = "Reported By",
			value = string.format("%s (ID: %d)", report.ReportedBy.Name, report.ReportedBy.UserId),
			inline = false
		})
	end

	local success, response = pcall(function()
		return HttpService:PostAsync(CONFIG.WebhookUrl,
			HttpService:JSONEncode(webhookData),
			Enum.HttpContentType.ApplicationJson)
	end)

	if not success then
		warn("[BugReportService] Webhook failed:", response)
	end
end

-- ============================================================================
-- ADMIN NOTIFICATIONS
-- ============================================================================

function BugReportService.NotifyAdmins(report: {}, reportingPlayer: Player?)
	local admins = {}

	-- Find admins (customize this based on your admin system)
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetRankInGroup(0) >= 250 or -- Example: group rank
		   player.UserId == game.CreatorId then -- Game owner
			table.insert(admins, player)
		end
	end

	local message = string.format("🐛 New %s bug report: %s",
		report.Priority or "UNKNOWN",
		report.Description:sub(1, 50))

	for _, admin in ipairs(admins) do
		BugReportService.SendResponse(admin, message)
	end
end

-- ============================================================================
-- PLAYER COMMUNICATION
-- ============================================================================

function BugReportService.SendResponse(player: Player, message: string)
	-- This would typically use a RemoteEvent to show UI
	-- For now, we'll use a simple approach
	local success, err = pcall(function()
		-- You would send this to a UI system
		print(string.format("[To %s] %s", player.Name, message))
	end)
end

-- ============================================================================
-- STATISTICS
-- ============================================================================

function BugReportService.GetStatistics()
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if not BugReporter or not BugReporter.GetAnalytics then
		return {
			TotalReports = 0,
			CriticalBugs = 0
		}
	end

	local analytics = BugReporter.GetAnalytics()
	return {
		TotalReports = analytics.TotalReports,
		CriticalBugs = #criticalBugCounts,
		ReportsByCategory = analytics.ByCategory,
		TopBugs = analytics.TopBugs,
		CrashRate = analytics.CrashRate
	}
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function BugReportService.RegisterAdminCommands()
	local AdminCommands = _G.TowerAscent and _G.TowerAscent.AdminCommands
	if not AdminCommands then
		return
	end

	-- /bugs stats
	AdminCommands.RegisterCommand("bugs", "stats", function(player)
		local stats = BugReportService.GetStatistics()
		return string.format("Bug Statistics:\nTotal: %d\nCritical: %d\nCrash Rate: %d/hr",
			stats.TotalReports, stats.CriticalBugs, stats.CrashRate or 0)
	end)

	-- /bugs recent
	AdminCommands.RegisterCommand("bugs", "recent", function(player)
		local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
		if not BugReporter then
			return "BugReporter not available"
		end

		local recent = BugReporter.GetRecentReports(5)
		local output = {"Recent Bugs:"}

		for i, report in ipairs(recent) do
			table.insert(output, string.format("%d. [%s] %s",
				i, report.Category, report.Description:sub(1, 30)))
		end

		return table.concat(output, "\n")
	end)

	-- /bugs recover
	AdminCommands.RegisterCommand("bugs", "recover", function(player)
		BugReportService.AttemptCrashRecovery()
		return "Recovery attempted"
	end)

	print("[BugReportService] Admin commands registered")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BugReportService.Initialize()
	print("[BugReportService] Initializing bug report service...")

	-- Start crash monitoring
	BugReportService.MonitorForCrashes()

	-- Register admin commands
	BugReportService.RegisterAdminCommands()

	-- Integration with existing systems
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if BugReporter then
		BugReporter.Initialize()
		BugReporter.Start()
		BugReporter.EnableAutoDetection()
		print("[BugReportService] BugReporter integrated and started")
	end

	-- Integration with RuntimeMonitor
	local RuntimeMonitor = _G.TowerAscent and _G.TowerAscent.RuntimeMonitor
	if RuntimeMonitor then
		-- Hook into alerts
		local originalAlert = RuntimeMonitor.Alert
		RuntimeMonitor.Alert = function(severity, message, data)
			originalAlert(severity, message, data)

			-- Also create bug report for critical alerts
			if severity == "CRITICAL" and BugReporter then
				BugReporter.ReportBug("CRASH",
					"Critical alert: " .. message,
					{AlertData = data})
			end
		end
	end

	print("[BugReportService] ✅ Bug reporting service ready")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

-- Auto-initialize on require
task.spawn(function()
	task.wait(1) -- Wait for other services
	BugReportService.Initialize()
end)

return BugReportService