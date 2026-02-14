--[[
	BugAnalytics.lua
	Advanced bug analytics and pattern recognition

	Features:
	- Bug pattern analysis
	- Trend detection
	- Correlation analysis
	- Predictive alerts
	- Impact assessment
	- Root cause analysis
	- Performance correlation

	Usage:
	   BugAnalytics.Analyze()
	   BugAnalytics.GetTrends()
	   BugAnalytics.PredictIssues()

	Created: 2025-12-02 (Bug Analytics System)
--]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")

local BugAnalytics = {}
BugAnalytics.Enabled = false
BugAnalytics.Patterns = {}
BugAnalytics.Trends = {}
BugAnalytics.Correlations = {}
BugAnalytics.Predictions = {}
BugAnalytics.Dashboard = {}

-- Configuration
local CONFIG = {
	AnalysisInterval = 60, -- seconds
	TrendWindow = 3600, -- 1 hour
	PatternThreshold = 3, -- Minimum occurrences to be a pattern
	CorrelationThreshold = 0.7, -- Minimum correlation coefficient
	PredictionConfidence = 0.8
}

-- ============================================================================
-- PATTERN RECOGNITION
-- ============================================================================

function BugAnalytics.AnalyzePatterns()
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if not BugReporter or not BugReporter.Reports then
		return {}
	end

	local patterns = {}
	local reports = BugReporter.Reports

	-- Time-based patterns
	local hourlyDistribution = {}
	for i = 0, 23 do
		hourlyDistribution[i] = 0
	end

	for _, report in ipairs(reports) do
		local hour = os.date("*t", report.Timestamp).hour
		hourlyDistribution[hour] = hourlyDistribution[hour] + 1
	end

	-- Find peak hours
	local maxHour = 0
	local maxCount = 0
	for hour, count in pairs(hourlyDistribution) do
		if count > maxCount then
			maxHour = hour
			maxCount = count
		end
	end

	if maxCount > CONFIG.PatternThreshold then
		table.insert(patterns, {
			Type = "TIME_BASED",
			Description = string.format("Most bugs occur at %d:00 (%d reports)", maxHour, maxCount),
			Confidence = maxCount / #reports
		})
	end

	-- Category patterns
	local categoryPatterns = {}
	for _, report in ipairs(reports) do
		categoryPatterns[report.Category] = (categoryPatterns[report.Category] or 0) + 1
	end

	for category, count in pairs(categoryPatterns) do
		if count >= CONFIG.PatternThreshold then
			table.insert(patterns, {
				Type = "CATEGORY",
				Description = string.format("%s bugs are frequent (%d occurrences)", category, count),
				Category = category,
				Count = count,
				Percentage = (count / #reports) * 100
			})
		end
	end

	-- Error message patterns
	local errorPatterns = {}
	for _, report in ipairs(reports) do
		if report.Data and report.Data.Error then
			local error = report.Data.Error

			-- Extract common error patterns
			local patterns = {
				"attempt to index nil",
				"attempt to call",
				"timeout",
				"memory",
				"infinite loop",
				"stack overflow"
			}

			for _, pattern in ipairs(patterns) do
				if error:find(pattern) then
					errorPatterns[pattern] = (errorPatterns[pattern] or 0) + 1
				end
			end
		end
	end

	for pattern, count in pairs(errorPatterns) do
		if count >= CONFIG.PatternThreshold then
			table.insert(patterns, {
				Type = "ERROR_PATTERN",
				Description = string.format("'%s' errors recurring (%d times)", pattern, count),
				Pattern = pattern,
				Count = count
			})
		end
	end

	-- Player-specific patterns
	local playerBugs = {}
	for _, report in ipairs(reports) do
		if report.ReportedBy then
			local userId = report.ReportedBy.UserId
			playerBugs[userId] = (playerBugs[userId] or 0) + 1
		end
	end

	-- Check for players with excessive bug reports
	for userId, count in pairs(playerBugs) do
		if count > CONFIG.PatternThreshold * 2 then
			table.insert(patterns, {
				Type = "PLAYER_SPECIFIC",
				Description = string.format("Player %d reports many bugs (%d reports)", userId, count),
				UserId = userId,
				Count = count
			})
		end
	end

	BugAnalytics.Patterns = patterns
	return patterns
end

-- ============================================================================
-- TREND ANALYSIS
-- ============================================================================

function BugAnalytics.AnalyzeTrends()
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if not BugReporter or not BugReporter.Reports then
		return {}
	end

	local trends = {}
	local now = tick()
	local windowStart = now - CONFIG.TrendWindow

	-- Get reports within window
	local recentReports = {}
	for _, report in ipairs(BugReporter.Reports) do
		if report.Timestamp >= windowStart then
			table.insert(recentReports, report)
		end
	end

	-- Calculate bug rate over time
	local timeBuckets = {}
	local bucketSize = 300 -- 5 minutes
	local bucketCount = math.ceil(CONFIG.TrendWindow / bucketSize)

	for i = 1, bucketCount do
		timeBuckets[i] = 0
	end

	for _, report in ipairs(recentReports) do
		local bucketIndex = math.floor((report.Timestamp - windowStart) / bucketSize) + 1
		if bucketIndex >= 1 and bucketIndex <= bucketCount then
			timeBuckets[bucketIndex] = timeBuckets[bucketIndex] + 1
		end
	end

	-- Detect trends
	local increasing = true
	local decreasing = true

	for i = 2, bucketCount do
		if timeBuckets[i] < timeBuckets[i-1] then
			increasing = false
		end
		if timeBuckets[i] > timeBuckets[i-1] then
			decreasing = false
		end
	end

	if increasing and timeBuckets[bucketCount] > timeBuckets[1] then
		table.insert(trends, {
			Type = "INCREASING",
			Description = "Bug reports are increasing",
			Severity = "WARNING",
			Rate = (timeBuckets[bucketCount] - timeBuckets[1]) / bucketCount
		})
	elseif decreasing and timeBuckets[bucketCount] < timeBuckets[1] then
		table.insert(trends, {
			Type = "DECREASING",
			Description = "Bug reports are decreasing",
			Severity = "GOOD",
			Rate = (timeBuckets[1] - timeBuckets[bucketCount]) / bucketCount
		})
	end

	-- Category trends
	local categoryTrends = {}
	for _, report in ipairs(recentReports) do
		categoryTrends[report.Category] = (categoryTrends[report.Category] or 0) + 1
	end

	-- Compare with historical averages
	local historicalCategories = {}
	for _, report in ipairs(BugReporter.Reports) do
		historicalCategories[report.Category] = (historicalCategories[report.Category] or 0) + 1
	end

	for category, recentCount in pairs(categoryTrends) do
		local historicalAvg = (historicalCategories[category] or 0) / math.max(1, #BugReporter.Reports)
		local recentAvg = recentCount / math.max(1, #recentReports)

		if recentAvg > historicalAvg * 1.5 then
			table.insert(trends, {
				Type = "CATEGORY_SPIKE",
				Description = string.format("%s bugs spiking (%.1fx normal)", category, recentAvg / historicalAvg),
				Category = category,
				Multiplier = recentAvg / historicalAvg
			})
		end
	end

	BugAnalytics.Trends = trends
	return trends
end

-- ============================================================================
-- CORRELATION ANALYSIS
-- ============================================================================

function BugAnalytics.FindCorrelations()
	local correlations = {}

	-- Correlate bugs with performance metrics
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	local RuntimeMonitor = _G.TowerAscent and _G.TowerAscent.RuntimeMonitor

	if not BugReporter or not RuntimeMonitor then
		return correlations
	end

	-- Memory correlation
	local highMemoryBugs = 0
	local totalBugs = #BugReporter.Reports

	for _, report in ipairs(BugReporter.Reports) do
		if report.Environment and report.Environment.Memory > 400 then
			highMemoryBugs = highMemoryBugs + 1
		end
	end

	local memoryCorrelation = highMemoryBugs / math.max(1, totalBugs)
	if memoryCorrelation > CONFIG.CorrelationThreshold then
		table.insert(correlations, {
			Type = "MEMORY",
			Description = string.format("%.0f%% of bugs occur during high memory usage", memoryCorrelation * 100),
			Correlation = memoryCorrelation,
			Recommendation = "Investigate memory-related issues"
		})
	end

	-- FPS correlation
	local lowFPSBugs = 0
	for _, report in ipairs(BugReporter.Reports) do
		if report.Environment and report.Environment.FPS < 30 then
			lowFPSBugs = lowFPSBugs + 1
		end
	end

	local fpsCorrelation = lowFPSBugs / math.max(1, totalBugs)
	if fpsCorrelation > CONFIG.CorrelationThreshold then
		table.insert(correlations, {
			Type = "PERFORMANCE",
			Description = string.format("%.0f%% of bugs occur during low FPS", fpsCorrelation * 100),
			Correlation = fpsCorrelation,
			Recommendation = "Performance optimization may reduce bugs"
		})
	end

	-- Player count correlation
	local highPlayerBugs = 0
	local averagePlayerCount = 0

	for _, report in ipairs(BugReporter.Reports) do
		if report.Environment then
			averagePlayerCount = averagePlayerCount + report.Environment.PlayerCount
			if report.Environment.PlayerCount > 50 then
				highPlayerBugs = highPlayerBugs + 1
			end
		end
	end

	averagePlayerCount = averagePlayerCount / math.max(1, totalBugs)
	local playerCorrelation = highPlayerBugs / math.max(1, totalBugs)

	if playerCorrelation > 0.3 then -- Lower threshold for player count
		table.insert(correlations, {
			Type = "PLAYER_COUNT",
			Description = string.format("%.0f%% of bugs occur with 50+ players", playerCorrelation * 100),
			Correlation = playerCorrelation,
			AveragePlayerCount = averagePlayerCount,
			Recommendation = "Scale testing needed"
		})
	end

	BugAnalytics.Correlations = correlations
	return correlations
end

-- ============================================================================
-- PREDICTIVE ANALYTICS
-- ============================================================================

function BugAnalytics.PredictIssues()
	local predictions = {}

	-- Get current metrics
	local currentMemory = Stats:GetTotalMemoryUsageMb()
	local currentFPS = workspace:GetRealPhysicsFPS()
	local currentPlayers = #Players:GetPlayers()

	-- Memory prediction
	if currentMemory > 400 then
		local probability = math.min(1, (currentMemory - 400) / 100)
		if probability > CONFIG.PredictionConfidence then
			table.insert(predictions, {
				Type = "MEMORY_ISSUE",
				Description = "Memory-related bugs likely soon",
				Probability = probability,
				CurrentValue = currentMemory,
				Threshold = 400,
				TimeToIssue = (500 - currentMemory) / 10 -- Rough estimate in minutes
			})
		end
	end

	-- FPS prediction
	if currentFPS < 40 then
		local probability = math.min(1, (40 - currentFPS) / 20)
		if probability > CONFIG.PredictionConfidence then
			table.insert(predictions, {
				Type = "PERFORMANCE_ISSUE",
				Description = "Performance bugs likely",
				Probability = probability,
				CurrentValue = currentFPS,
				Threshold = 30
			})
		end
	end

	-- Pattern-based prediction
	local patterns = BugAnalytics.Patterns
	for _, pattern in ipairs(patterns) do
		if pattern.Type == "TIME_BASED" then
			-- Check if we're approaching a high-bug hour
			local currentHour = os.date("*t").hour
			-- This is simplified - you'd want more sophisticated prediction
			if math.abs(currentHour - (pattern.PeakHour or 0)) <= 1 then
				table.insert(predictions, {
					Type = "TIME_BASED_SPIKE",
					Description = "Bug spike expected based on historical patterns",
					Probability = pattern.Confidence or 0.5,
					ExpectedIn = "Within 1 hour"
				})
			end
		end
	end

	-- Trend-based prediction
	local trends = BugAnalytics.Trends
	for _, trend in ipairs(trends) do
		if trend.Type == "INCREASING" and trend.Rate > 1 then
			table.insert(predictions, {
				Type = "TREND_ACCELERATION",
				Description = "Bug rate accelerating",
				Probability = math.min(1, trend.Rate / 5),
				CurrentRate = trend.Rate,
				ExpectedImpact = "HIGH"
			})
		end
	end

	BugAnalytics.Predictions = predictions
	return predictions
end

-- ============================================================================
-- IMPACT ASSESSMENT
-- ============================================================================

function BugAnalytics.AssessImpact()
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if not BugReporter then
		return {}
	end

	local impact = {
		TotalBugs = #BugReporter.Reports,
		CriticalBugs = 0,
		AffectedPlayers = {},
		EstimatedDowntime = 0,
		DataIntegrity = "GOOD",
		PlayerExperience = "NORMAL"
	}

	-- Count critical bugs
	for _, report in ipairs(BugReporter.Reports) do
		if report.Priority == "CRITICAL" then
			impact.CriticalBugs = impact.CriticalBugs + 1
		end

		-- Track affected players
		if report.AffectedPlayers then
			for _, player in ipairs(report.AffectedPlayers) do
				impact.AffectedPlayers[player.UserId] = true
			end
		end
	end

	impact.UniqueAffectedPlayers = 0
	for _ in pairs(impact.AffectedPlayers) do
		impact.UniqueAffectedPlayers = impact.UniqueAffectedPlayers + 1
	end

	-- Assess data integrity
	local dataBugs = 0
	for _, report in ipairs(BugReporter.Reports) do
		if report.Category == "DATA" then
			dataBugs = dataBugs + 1
		end
	end

	if dataBugs > 5 then
		impact.DataIntegrity = "AT_RISK"
	elseif dataBugs > 10 then
		impact.DataIntegrity = "COMPROMISED"
	end

	-- Assess player experience
	local gameplayBugs = 0
	for _, report in ipairs(BugReporter.Reports) do
		if report.Category == "GAMEPLAY" or report.Category == "VISUAL" then
			gameplayBugs = gameplayBugs + 1
		end
	end

	if gameplayBugs > 10 then
		impact.PlayerExperience = "DEGRADED"
	elseif gameplayBugs > 20 then
		impact.PlayerExperience = "POOR"
	end

	-- Estimate downtime (simplified)
	impact.EstimatedDowntime = impact.CriticalBugs * 5 -- 5 minutes per critical bug

	return impact
end

-- ============================================================================
-- ROOT CAUSE ANALYSIS
-- ============================================================================

function BugAnalytics.FindRootCauses()
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if not BugReporter then
		return {}
	end

	local rootCauses = {}

	-- Analyze stack traces
	local stackPatterns = {}
	for _, report in ipairs(BugReporter.Reports) do
		if report.StackTrace then
			-- Extract function names from stack trace
			for funcName in report.StackTrace:gmatch("([%w_]+)%s*%(") do
				stackPatterns[funcName] = (stackPatterns[funcName] or 0) + 1
			end
		end
	end

	-- Find most common functions in stack traces
	local sortedFunctions = {}
	for funcName, count in pairs(stackPatterns) do
		table.insert(sortedFunctions, {Name = funcName, Count = count})
	end

	table.sort(sortedFunctions, function(a, b)
		return a.Count > b.Count
	end)

	for i = 1, math.min(5, #sortedFunctions) do
		local func = sortedFunctions[i]
		if func.Count >= CONFIG.PatternThreshold then
			table.insert(rootCauses, {
				Type = "FUNCTION",
				Description = string.format("Function '%s' appears in %d bug reports", func.Name, func.Count),
				Function = func.Name,
				Frequency = func.Count,
				Recommendation = "Review and refactor this function"
			})
		end
	end

	-- Service-based root causes
	local serviceBugs = {}
	for _, report in ipairs(BugReporter.Reports) do
		if report.Context and report.Context.Services then
			for serviceName, _ in pairs(report.Context.Services) do
				serviceBugs[serviceName] = (serviceBugs[serviceName] or 0) + 1
			end
		end
	end

	for serviceName, count in pairs(serviceBugs) do
		if count >= CONFIG.PatternThreshold * 2 then
			table.insert(rootCauses, {
				Type = "SERVICE",
				Description = string.format("Service '%s' involved in %d bugs", serviceName, count),
				Service = serviceName,
				Count = count,
				Recommendation = "Audit service for issues"
			})
		end
	end

	return rootCauses
end

-- ============================================================================
-- DASHBOARD GENERATION
-- ============================================================================

function BugAnalytics.GenerateDashboard()
	local dashboard = {
		Timestamp = tick(),
		Summary = {},
		Patterns = BugAnalytics.AnalyzePatterns(),
		Trends = BugAnalytics.AnalyzeTrends(),
		Correlations = BugAnalytics.FindCorrelations(),
		Predictions = BugAnalytics.PredictIssues(),
		Impact = BugAnalytics.AssessImpact(),
		RootCauses = BugAnalytics.FindRootCauses()
	}

	-- Generate summary
	local BugReporter = _G.TowerAscent and _G.TowerAscent.BugReporter
	if BugReporter then
		local analytics = BugReporter.GetAnalytics()
		dashboard.Summary = {
			TotalBugs = analytics.TotalReports,
			CriticalBugs = dashboard.Impact.CriticalBugs,
			UniqueAffectedPlayers = dashboard.Impact.UniqueAffectedPlayers,
			TopCategory = nil,
			HealthScore = 100
		}

		-- Find top category
		local maxCategory = nil
		local maxCount = 0
		for category, count in pairs(analytics.ByCategory) do
			if count > maxCount then
				maxCategory = category
				maxCount = count
			end
		end
		dashboard.Summary.TopCategory = maxCategory

		-- Calculate health score
		local score = 100
		score = score - (dashboard.Impact.CriticalBugs * 10)
		score = score - (analytics.TotalReports * 0.5)

		if dashboard.Impact.DataIntegrity == "AT_RISK" then
			score = score - 20
		elseif dashboard.Impact.DataIntegrity == "COMPROMISED" then
			score = score - 40
		end

		dashboard.Summary.HealthScore = math.max(0, score)
	end

	BugAnalytics.Dashboard = dashboard
	return dashboard
end

-- ============================================================================
-- REPORTING
-- ============================================================================

function BugAnalytics.ExportReport(format: string?): string
	format = format or "markdown"
	local dashboard = BugAnalytics.GenerateDashboard()

	if format == "markdown" then
		local output = {
			"# Bug Analytics Report",
			string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
			"",
			"## Executive Summary",
			string.format("- **Health Score**: %.0f/100", dashboard.Summary.HealthScore),
			string.format("- **Total Bugs**: %d", dashboard.Summary.TotalBugs),
			string.format("- **Critical Bugs**: %d", dashboard.Summary.CriticalBugs),
			string.format("- **Affected Players**: %d", dashboard.Summary.UniqueAffectedPlayers),
			string.format("- **Top Issue**: %s", dashboard.Summary.TopCategory or "None"),
			"",
			"## Key Patterns"
		}

		for i, pattern in ipairs(dashboard.Patterns) do
			if i <= 5 then
				table.insert(output, string.format("%d. %s", i, pattern.Description))
			end
		end

		table.insert(output, "")
		table.insert(output, "## Current Trends")

		for _, trend in ipairs(dashboard.Trends) do
			local icon = trend.Severity == "WARNING" and "⚠️" or "✅"
			table.insert(output, string.format("- %s %s", icon, trend.Description))
		end

		table.insert(output, "")
		table.insert(output, "## Predictions")

		for _, prediction in ipairs(dashboard.Predictions) do
			table.insert(output, string.format("- **%s** (%.0f%% probability)",
				prediction.Description, prediction.Probability * 100))
		end

		table.insert(output, "")
		table.insert(output, "## Root Causes")

		for i, cause in ipairs(dashboard.RootCauses) do
			if i <= 3 then
				table.insert(output, string.format("%d. %s", i, cause.Description))
				table.insert(output, string.format("   - Recommendation: %s", cause.Recommendation))
			end
		end

		table.insert(output, "")
		table.insert(output, "## Impact Assessment")
		table.insert(output, string.format("- Data Integrity: %s", dashboard.Impact.DataIntegrity))
		table.insert(output, string.format("- Player Experience: %s", dashboard.Impact.PlayerExperience))
		table.insert(output, string.format("- Estimated Downtime: %d minutes", dashboard.Impact.EstimatedDowntime))

		return table.concat(output, "\n")

	elseif format == "json" then
		return HttpService:JSONEncode(dashboard)
	end

	return ""
end

-- ============================================================================
-- AUTOMATION
-- ============================================================================

function BugAnalytics.Start()
	if BugAnalytics.Enabled then
		return
	end

	BugAnalytics.Enabled = true
	print("[BugAnalytics] Starting analytics engine...")

	-- Regular analysis
	task.spawn(function()
		while BugAnalytics.Enabled do
			task.wait(CONFIG.AnalysisInterval)

			if BugAnalytics.Enabled then
				BugAnalytics.GenerateDashboard()

				-- Check for critical predictions
				for _, prediction in ipairs(BugAnalytics.Predictions) do
					if prediction.Probability > 0.9 then
						warn(string.format("⚠️ [BugAnalytics] HIGH PROBABILITY: %s",
							prediction.Description))
					end
				end
			end
		end
	end)
end

function BugAnalytics.Stop()
	BugAnalytics.Enabled = false
	print("[BugAnalytics] Analytics engine stopped")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return BugAnalytics