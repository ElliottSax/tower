--[[
	BugReporter.lua
	Comprehensive bug reporting and tracking system

	Features:
	- Automated bug detection
	- Player-initiated bug reports
	- Crash detection and reporting
	- Stack trace capture
	- Environment snapshots
	- Bug categorization and prioritization
	- Duplicate detection
	- Reproduction tracking

	Usage:
	   BugReporter.ReportBug(category, description, data)
	   BugReporter.ReportCrash(player, error, context)
	   BugReporter.EnableAutoDetection()

	Created: 2025-12-02 (Advanced Bug Reporting)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local ContentProvider = game:GetService("ContentProvider")
local LogService = game:GetService("LogService")

local BugReporter = {}
BugReporter.Enabled = false
BugReporter.Reports = {}
BugReporter.AutoDetection = false
BugReporter.PlayerReports = {}
BugReporter.CrashReports = {}
BugReporter.Patterns = {}
BugReporter.ReproductionSteps = {}

-- Configuration
local CONFIG = {
	MaxReports = 1000,
	MaxReportSize = 50000, -- characters
	AutoDetectionInterval = 10, -- seconds
	DuplicateThreshold = 0.8, -- similarity score
	CriticalPatterns = {
		"DataService",
		"ProfileService",
		"data loss",
		"corrupted",
		"infinite loop"
	},
	Categories = {
		CRASH = {Priority = "CRITICAL", Color = Color3.fromRGB(255, 0, 0)},
		DATA = {Priority = "CRITICAL", Color = Color3.fromRGB(255, 100, 0)},
		GAMEPLAY = {Priority = "HIGH", Color = Color3.fromRGB(255, 200, 0)},
		VISUAL = {Priority = "MEDIUM", Color = Color3.fromRGB(255, 255, 0)},
		PERFORMANCE = {Priority = "HIGH", Color = Color3.fromRGB(200, 150, 0)},
		OTHER = {Priority = "LOW", Color = Color3.fromRGB(150, 150, 150)}
	}
}

-- ============================================================================
-- BUG REPORT STRUCTURE
-- ============================================================================

local function CreateBugReport(category: string, description: string, data: {}?): {}
	local report = {
		-- Metadata
		Id = HttpService:GenerateGUID(false),
		Timestamp = tick(),
		Date = os.date("%Y-%m-%d %H:%M:%S"),
		Category = category,
		Priority = CONFIG.Categories[category] and CONFIG.Categories[category].Priority or "UNKNOWN",

		-- Bug Information
		Description = description,
		Data = data or {},

		-- Environment
		Environment = {
			PlaceId = game.PlaceId,
			PlaceVersion = game.PlaceVersion,
			JobId = game.JobId,
			ServerTime = workspace.DistributedGameTime,
			PlayerCount = #Players:GetPlayers(),
			Memory = Stats:GetTotalMemoryUsageMb(),
			FPS = workspace:GetRealPhysicsFPS()
		},

		-- Technical Details
		StackTrace = debug.traceback(),
		LogMessages = {},

		-- Tracking
		Status = "NEW",
		DuplicateCount = 0,
		FirstSeen = tick(),
		LastSeen = tick(),
		AffectedPlayers = {},

		-- Reproduction
		ReproductionRate = 0,
		ReproductionSteps = {},
		CanReproduce = false
	}

	-- Capture recent log messages
	local logs = LogService:GetLogHistory()
	local recentLogs = {}
	for i = math.max(1, #logs - 10), #logs do
		if logs[i] then
			table.insert(recentLogs, {
				Message = logs[i].message,
				Type = tostring(logs[i].messageType),
				Timestamp = logs[i].timestamp
			})
		end
	end
	report.LogMessages = recentLogs

	return report
end

-- ============================================================================
-- AUTOMATED BUG DETECTION
-- ============================================================================

function BugReporter.DetectBugs()
	local detectedBugs = {}

	-- Check for memory leaks
	local memoryUsage = Stats:GetTotalMemoryUsageMb()
	if memoryUsage > 500 then
		table.insert(detectedBugs, {
			Category = "PERFORMANCE",
			Description = "High memory usage detected",
			Data = {
				Memory = memoryUsage,
				Threshold = 500
			}
		})
	end

	-- Check for low FPS
	local fps = workspace:GetRealPhysicsFPS()
	if fps < 20 then
		table.insert(detectedBugs, {
			Category = "PERFORMANCE",
			Description = "Low FPS detected",
			Data = {
				FPS = fps,
				Threshold = 20
			}
		})
	end

	-- Check for script errors in log
	local logs = LogService:GetLogHistory()
	for _, log in ipairs(logs) do
		if log.messageType == Enum.MessageType.MessageError then
			local errorMsg = log.message

			-- Check for critical patterns
			for _, pattern in ipairs(CONFIG.CriticalPatterns) do
				if errorMsg:find(pattern) then
					table.insert(detectedBugs, {
						Category = "CRASH",
						Description = "Critical error pattern detected",
						Data = {
							Error = errorMsg,
							Pattern = pattern,
							Timestamp = log.timestamp
						}
					})
					break
				end
			end
		end
	end

	-- Check for nil reference errors
	local nilErrors = 0
	for _, log in ipairs(logs) do
		if log.message:find("attempt to index nil") or log.message:find("nil value") then
			nilErrors = nilErrors + 1
		end
	end

	if nilErrors > 5 then
		table.insert(detectedBugs, {
			Category = "GAMEPLAY",
			Description = "Multiple nil reference errors",
			Data = {
				Count = nilErrors,
				Threshold = 5
			}
		})
	end

	-- Check service availability
	if _G.TowerAscent then
		local criticalServices = {"DataService", "RoundService", "CheckpointService"}
		for _, serviceName in ipairs(criticalServices) do
			if not _G.TowerAscent[serviceName] then
				table.insert(detectedBugs, {
					Category = "CRASH",
					Description = string.format("Critical service not available: %s", serviceName),
					Data = {
						Service = serviceName,
						Available = false
					}
				})
			end
		end
	end

	-- Report detected bugs
	for _, bug in ipairs(detectedBugs) do
		BugReporter.ReportBug(bug.Category, bug.Description, bug.Data)
	end

	return detectedBugs
end

-- ============================================================================
-- BUG REPORTING
-- ============================================================================

function BugReporter.ReportBug(category: string, description: string, data: {}?, player: Player?)
	-- Validate category
	if not CONFIG.Categories[category] then
		category = "OTHER"
	end

	-- Check for duplicates
	local isDuplicate, existingReport = BugReporter.CheckDuplicate(category, description)

	if isDuplicate and existingReport then
		-- Update existing report
		existingReport.DuplicateCount = existingReport.DuplicateCount + 1
		existingReport.LastSeen = tick()

		if player then
			table.insert(existingReport.AffectedPlayers, {
				UserId = player.UserId,
				Name = player.Name,
				Time = tick()
			})
		end

		print(string.format("[BugReporter] Duplicate bug report updated: %s (Count: %d)",
			existingReport.Id, existingReport.DuplicateCount))

		return existingReport
	end

	-- Create new report
	local report = CreateBugReport(category, description, data)

	-- Add player information if provided
	if player then
		report.ReportedBy = {
			UserId = player.UserId,
			Name = player.Name,
			AccountAge = player.AccountAge
		}

		table.insert(report.AffectedPlayers, report.ReportedBy)

		-- Get player's game state
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService and DataService.GetData then
			local success, playerData = pcall(function()
				return DataService.GetData(player)
			end)

			if success and playerData then
				report.PlayerGameState = {
					Section = playerData.CurrentSection,
					Coins = playerData.Coins,
					PlayTime = playerData.PlayTime
				}
			end
		end
	end

	-- Capture additional context
	report.Context = BugReporter.CaptureContext()

	-- Store report
	table.insert(BugReporter.Reports, report)

	-- Limit report storage
	if #BugReporter.Reports > CONFIG.MaxReports then
		table.remove(BugReporter.Reports, 1)
	end

	-- Log based on priority
	local priority = CONFIG.Categories[category].Priority
	if priority == "CRITICAL" then
		warn(string.format("🔴 [CRITICAL BUG] %s: %s", category, description))
	elseif priority == "HIGH" then
		warn(string.format("🟠 [HIGH PRIORITY BUG] %s: %s", category, description))
	elseif priority == "MEDIUM" then
		print(string.format("🟡 [MEDIUM BUG] %s: %s", category, description))
	else
		print(string.format("⚪ [BUG] %s: %s", category, description))
	end

	-- Trigger automated response for critical bugs
	if priority == "CRITICAL" then
		BugReporter.HandleCriticalBug(report)
	end

	return report
end

-- ============================================================================
-- CRASH REPORTING
-- ============================================================================

function BugReporter.ReportCrash(player: Player?, error: string, context: {}?)
	local crashReport = {
		Type = "CRASH",
		Error = error,
		Player = player and {
			UserId = player.UserId,
			Name = player.Name
		} or nil,
		Context = context or {},
		Timestamp = tick(),
		ServerInfo = {
			JobId = game.JobId,
			PlaceVersion = game.PlaceVersion,
			Uptime = workspace.DistributedGameTime
		}
	}

	-- Try to capture pre-crash state
	local RuntimeMonitor = _G.TowerAscent and _G.TowerAscent.RuntimeMonitor
	if RuntimeMonitor and RuntimeMonitor.DumpState then
		crashReport.PreCrashState = RuntimeMonitor.DumpState()
	end

	table.insert(BugReporter.CrashReports, crashReport)

	-- Create bug report
	local report = BugReporter.ReportBug("CRASH",
		string.format("Crash: %s", error:sub(1, 100)),
		crashReport,
		player)

	-- Attempt recovery
	local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
	if ErrorRecovery then
		if player and ErrorRecovery.RecoverPlayerData then
			task.spawn(function()
				ErrorRecovery.RecoverPlayerData(player)
			end)
		end

		if ErrorRecovery.EnableAutoRecovery then
			ErrorRecovery.EnableAutoRecovery()
		end
	end

	return report
end

-- ============================================================================
-- DUPLICATE DETECTION
-- ============================================================================

function BugReporter.CheckDuplicate(category: string, description: string): (boolean, {}?)
	-- Simple similarity check based on category and description
	for _, report in ipairs(BugReporter.Reports) do
		if report.Category == category then
			-- Calculate similarity score
			local similarity = 0

			-- Exact match
			if report.Description == description then
				return true, report
			end

			-- Partial match
			local words1 = string.split(description:lower(), " ")
			local words2 = string.split(report.Description:lower(), " ")

			local matches = 0
			for _, word1 in ipairs(words1) do
				for _, word2 in ipairs(words2) do
					if word1 == word2 and #word1 > 3 then
						matches = matches + 1
						break
					end
				end
			end

			similarity = matches / math.max(#words1, #words2)

			if similarity >= CONFIG.DuplicateThreshold then
				return true, report
			end
		end
	end

	return false, nil
end

-- ============================================================================
-- CONTEXT CAPTURE
-- ============================================================================

function BugReporter.CaptureContext(): {}
	local context = {
		Timestamp = tick(),
		Services = {},
		ActivePlayers = {}
	}

	-- Capture service states
	if _G.TowerAscent then
		for serviceName, service in pairs(_G.TowerAscent) do
			if type(service) == "table" then
				local serviceInfo = {
					Available = true,
					Enabled = service.Enabled
				}

				-- Service-specific data
				if serviceName == "RoundService" then
					serviceInfo.HasTower = service.CurrentTower ~= nil
				elseif serviceName == "MemoryManager" then
					serviceInfo.LastCleanup = service.LastCleanup
				elseif serviceName == "ErrorRecovery" then
					serviceInfo.ErrorCount = service.ErrorLog and #service.ErrorLog or 0
				end

				context.Services[serviceName] = serviceInfo
			end
		end
	end

	-- Capture active players
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(context.ActivePlayers, {
			UserId = player.UserId,
			Name = player.Name,
			Ping = player:GetNetworkPing()
		})
	end

	-- Capture performance metrics
	context.Performance = {
		FPS = workspace:GetRealPhysicsFPS(),
		Memory = Stats:GetTotalMemoryUsageMb(),
		HeartbeatDelta = RunService.Heartbeat:Wait()
	}

	return context
end

-- ============================================================================
-- CRITICAL BUG HANDLING
-- ============================================================================

function BugReporter.HandleCriticalBug(report: {})
	warn(string.format("[BugReporter] Handling critical bug: %s", report.Id))

	-- Trigger emergency measures based on category
	if report.Category == "DATA" then
		-- Pause data operations
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService and DataService.PauseOperations then
			DataService.PauseOperations()
		end

		-- Alert all players
		for _, player in ipairs(Players:GetPlayers()) do
			BugReporter.NotifyPlayer(player,
				"⚠️ Data issue detected. Your progress is being protected.")
		end

	elseif report.Category == "CRASH" then
		-- Enable all recovery mechanisms
		local ErrorRecovery = _G.TowerAscent and _G.TowerAscent.ErrorRecovery
		if ErrorRecovery and ErrorRecovery.EnableAutoRecovery then
			ErrorRecovery.EnableAutoRecovery()
		end

		-- Force save all player data
		local DataService = _G.TowerAscent and _G.TowerAscent.DataService
		if DataService and DataService.SaveAllProfiles then
			task.spawn(function()
				DataService.SaveAllProfiles()
			end)
		end
	end

	-- Log to external service (webhook, analytics, etc.)
	-- This would be implementation-specific
end

-- ============================================================================
-- PLAYER BUG REPORTING
-- ============================================================================

function BugReporter.PlayerReport(player: Player, category: string, description: string, includeScreenshot: boolean?)
	-- Rate limiting
	local lastReport = BugReporter.PlayerReports[player.UserId]
	if lastReport and tick() - lastReport < 60 then
		BugReporter.NotifyPlayer(player, "Please wait before submitting another report.")
		return false
	end

	BugReporter.PlayerReports[player.UserId] = tick()

	-- Create report with player context
	local data = {
		PlayerReport = true,
		IncludesScreenshot = includeScreenshot or false
	}

	local report = BugReporter.ReportBug(category, description, data, player)

	-- Thank the player
	BugReporter.NotifyPlayer(player,
		string.format("Thank you for your report! (ID: %s)", report.Id:sub(1, 8)))

	return report
end

-- ============================================================================
-- REPRODUCTION TRACKING
-- ============================================================================

function BugReporter.StartReproduction(bugId: string)
	BugReporter.ReproductionSteps[bugId] = {
		Steps = {},
		StartTime = tick(),
		Recording = true
	}

	print(string.format("[BugReporter] Started recording reproduction for bug %s", bugId:sub(1, 8)))
end

function BugReporter.AddReproductionStep(bugId: string, step: string, data: {}?)
	local reproduction = BugReporter.ReproductionSteps[bugId]
	if not reproduction or not reproduction.Recording then
		return
	end

	table.insert(reproduction.Steps, {
		Step = step,
		Data = data,
		Timestamp = tick() - reproduction.StartTime
	})
end

function BugReporter.EndReproduction(bugId: string, reproduced: boolean)
	local reproduction = BugReporter.ReproductionSteps[bugId]
	if not reproduction then
		return
	end

	reproduction.Recording = false
	reproduction.EndTime = tick()
	reproduction.Reproduced = reproduced

	-- Find the bug report and update it
	for _, report in ipairs(BugReporter.Reports) do
		if report.Id == bugId then
			report.ReproductionSteps = reproduction.Steps
			report.CanReproduce = reproduced

			if reproduced then
				report.ReproductionRate = report.ReproductionRate + 1
			end

			break
		end
	end

	print(string.format("[BugReporter] Reproduction %s for bug %s",
		reproduced and "successful" or "failed", bugId:sub(1, 8)))
end

-- ============================================================================
-- BUG ANALYTICS
-- ============================================================================

function BugReporter.GetAnalytics(): {}
	local analytics = {
		TotalReports = #BugReporter.Reports,
		ByCategory = {},
		ByPriority = {},
		RecentTrends = {},
		TopBugs = {},
		CrashRate = 0
	}

	-- Count by category and priority
	for _, report in ipairs(BugReporter.Reports) do
		-- By category
		analytics.ByCategory[report.Category] = (analytics.ByCategory[report.Category] or 0) + 1

		-- By priority
		analytics.ByPriority[report.Priority] = (analytics.ByPriority[report.Priority] or 0) + 1
	end

	-- Find top bugs (most duplicates)
	local sortedReports = {}
	for _, report in ipairs(BugReporter.Reports) do
		table.insert(sortedReports, report)
	end

	table.sort(sortedReports, function(a, b)
		return a.DuplicateCount > b.DuplicateCount
	end)

	for i = 1, math.min(5, #sortedReports) do
		table.insert(analytics.TopBugs, {
			Id = sortedReports[i].Id,
			Description = sortedReports[i].Description,
			Count = sortedReports[i].DuplicateCount
		})
	end

	-- Calculate crash rate
	local crashes = 0
	local oneHourAgo = tick() - 3600

	for _, report in ipairs(BugReporter.Reports) do
		if report.Category == "CRASH" and report.Timestamp > oneHourAgo then
			crashes = crashes + 1
		end
	end

	analytics.CrashRate = crashes -- per hour

	return analytics
end

-- ============================================================================
-- PLAYER NOTIFICATION
-- ============================================================================

function BugReporter.NotifyPlayer(player: Player, message: string)
	-- This would typically use a RemoteEvent to show UI
	-- For now, just print
	print(string.format("[To %s] %s", player.Name, message))
end

-- ============================================================================
-- LIFECYCLE MANAGEMENT
-- ============================================================================

function BugReporter.Start()
	if BugReporter.Enabled then
		return
	end

	BugReporter.Enabled = true
	print("[BugReporter] Bug reporting system started")

	-- Start auto-detection
	if BugReporter.AutoDetection then
		task.spawn(function()
			while BugReporter.Enabled do
				task.wait(CONFIG.AutoDetectionInterval)
				if BugReporter.Enabled then
					BugReporter.DetectBugs()
				end
			end
		end)
	end

	-- Monitor script errors
	LogService.MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			-- Check for critical patterns
			for _, pattern in ipairs(CONFIG.CriticalPatterns) do
				if message:find(pattern) then
					BugReporter.ReportBug("CRASH",
						"Critical error detected",
						{Error = message, Pattern = pattern})
					break
				end
			end
		end
	end)

	-- Monitor player disconnects
	Players.PlayerRemoving:Connect(function(player)
		-- Check if player crashed
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			local humanoid = character.Humanoid
			if humanoid.Health <= 0 then
				BugReporter.ReportCrash(player, "Player died and disconnected", {
					Health = 0,
					Position = character.PrimaryPart and character.PrimaryPart.Position
				})
			end
		end
	end)
end

function BugReporter.Stop()
	BugReporter.Enabled = false
	BugReporter.AutoDetection = false
	print("[BugReporter] Bug reporting system stopped")
end

function BugReporter.EnableAutoDetection()
	BugReporter.AutoDetection = true
	print("[BugReporter] Auto-detection enabled")
end

function BugReporter.DisableAutoDetection()
	BugReporter.AutoDetection = false
	print("[BugReporter] Auto-detection disabled")
end

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================

function BugReporter.ExportReport(format: string?): string
	format = format or "markdown"

	local analytics = BugReporter.GetAnalytics()
	local output = {}

	if format == "markdown" then
		table.insert(output, "# Bug Report Summary")
		table.insert(output, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
		table.insert(output, "")
		table.insert(output, "## Statistics")
		table.insert(output, string.format("- Total Reports: %d", analytics.TotalReports))
		table.insert(output, string.format("- Crash Rate: %d/hour", analytics.CrashRate))
		table.insert(output, "")
		table.insert(output, "## By Category")

		for category, count in pairs(analytics.ByCategory) do
			table.insert(output, string.format("- %s: %d", category, count))
		end

		table.insert(output, "")
		table.insert(output, "## Top Bugs")

		for i, bug in ipairs(analytics.TopBugs) do
			table.insert(output, string.format("%d. %s (x%d)",
				i, bug.Description:sub(1, 50), bug.Count))
		end

	elseif format == "json" then
		return HttpService:JSONEncode({
			Reports = BugReporter.Reports,
			Analytics = analytics,
			Timestamp = tick()
		})
	end

	return table.concat(output, "\n")
end

function BugReporter.GetReport(bugId: string): {}?
	for _, report in ipairs(BugReporter.Reports) do
		if report.Id == bugId then
			return report
		end
	end
	return nil
end

function BugReporter.GetRecentReports(count: number?): {}
	count = count or 10
	local recent = {}

	local startIdx = math.max(1, #BugReporter.Reports - count + 1)
	for i = startIdx, #BugReporter.Reports do
		table.insert(recent, BugReporter.Reports[i])
	end

	return recent
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function BugReporter.RegisterAdminCommands()
	local AdminCommands = _G.TowerAscent and _G.TowerAscent.AdminCommands
	if not AdminCommands then
		return
	end

	-- /bug report
	AdminCommands.RegisterCommand("bug", "report", function(player, ...)
		local args = {...}
		local category = args[1] or "OTHER"
		local description = table.concat(args, " ", 2)

		local report = BugReporter.PlayerReport(player, category, description)
		return string.format("Bug reported: %s", report and report.Id:sub(1, 8) or "Failed")
	end)

	-- /bug list
	AdminCommands.RegisterCommand("bug", "list", function(player)
		local recent = BugReporter.GetRecentReports(5)
		local output = {"Recent Bug Reports:"}

		for i, report in ipairs(recent) do
			table.insert(output, string.format("%d. [%s] %s",
				i, report.Category, report.Description:sub(1, 30)))
		end

		return table.concat(output, "\n")
	end)

	-- /bug stats
	AdminCommands.RegisterCommand("bug", "stats", function(player)
		local analytics = BugReporter.GetAnalytics()
		return string.format("Bug Stats: %d total, %d crashes/hour",
			analytics.TotalReports, analytics.CrashRate)
	end)

	print("[BugReporter] Admin commands registered")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BugReporter.Initialize()
	-- Integration with RuntimeMonitor
	local RuntimeMonitor = _G.TowerAscent and _G.TowerAscent.RuntimeMonitor
	if RuntimeMonitor then
		-- Hook into error tracking
		local originalTrackError = RuntimeMonitor.TrackError
		RuntimeMonitor.TrackError = function(context, error, metadata)
			originalTrackError(context, error, metadata)

			-- Also report to BugReporter
			BugReporter.ReportBug("CRASH",
				string.format("Runtime error: %s", tostring(error):sub(1, 100)),
				{Context = context, Metadata = metadata})
		end
	end

	print("[BugReporter] Initialized and integrated with existing systems")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return BugReporter