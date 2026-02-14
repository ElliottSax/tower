--[[
	SecurityAudit.lua
	Comprehensive security audit for Tower Ascent

	Validates security measures:
	- Remote event security
	- Anti-cheat systems
	- Data protection
	- Rate limiting
	- Input validation

	Run before production deployment!
--]]

local SecurityAudit = {}

SecurityAudit.Findings = {
	Critical = {},
	High = {},
	Medium = {},
	Low = {},
	Info = {}
}

-- ============================================================================
-- AUDIT HELPERS
-- ============================================================================

local function AddFinding(severity, category, issue, recommendation)
	local finding = {
		Category = category,
		Issue = issue,
		Recommendation = recommendation,
		Timestamp = os.time()
	}

	table.insert(SecurityAudit.Findings[severity], finding)

	local icon = {
		Critical = "🔴",
		High = "🟠",
		Medium = "🟡",
		Low = "🔵",
		Info = "ℹ️"
	}

	print(string.format("%s [%s] %s: %s",
		icon[severity], severity, category, issue))
end

-- ============================================================================
-- REMOTE EVENT SECURITY AUDIT
-- ============================================================================

function SecurityAudit.AuditRemoteEvents()
	print("\n[SecurityAudit] === REMOTE EVENT SECURITY ===")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")

	if not remoteFolder then
		AddFinding("Critical", "RemoteEvents", "RemoteEvents folder not found",
			"Create RemoteEvents folder in ReplicatedStorage")
		return
	end

	local totalRemotes = 0
	local securedRemotes = 0
	local unsecuredRemotes = {}

	for _, remote in ipairs(remoteFolder:GetChildren()) do
		if remote:IsA("RemoteEvent") then
			totalRemotes += 1

			-- Check if it has a server-side handler
			-- Note: This is a basic check; actual security depends on handler implementation
			if remote.OnServerEvent:GetConnections() and #remote.OnServerEvent:GetConnections() > 0 then
				securedRemotes += 1
			else
				table.insert(unsecuredRemotes, remote.Name)
			end
		elseif remote:IsA("RemoteFunction") then
			totalRemotes += 1

			-- Check RemoteFunction
			if remote.OnServerInvoke then
				securedRemotes += 1
			else
				table.insert(unsecuredRemotes, remote.Name)
			end
		end
	end

	print(string.format("  Total remotes: %d", totalRemotes))
	print(string.format("  Secured: %d", securedRemotes))
	print(string.format("  Unsecured: %d", #unsecuredRemotes))

	if #unsecuredRemotes > 0 then
		AddFinding("High", "RemoteEvents",
			string.format("%d remote(s) without server handlers: %s",
				#unsecuredRemotes, table.concat(unsecuredRemotes, ", ")),
			"Add server-side validation and handlers for all remotes")
	else
		AddFinding("Info", "RemoteEvents", "All remotes have server handlers", "None")
	end

	-- Check for exploitable remote names
	local suspiciousNames = {"Admin", "Give", "Money", "Teleport", "SetHealth"}
	for _, remote in ipairs(remoteFolder:GetChildren()) do
		for _, suspicious in ipairs(suspiciousNames) do
			if string.find(remote.Name:lower(), suspicious:lower()) then
				AddFinding("Medium", "RemoteEvents",
					string.format("Potentially exploitable remote name: %s", remote.Name),
					"Ensure this remote has proper permission checks")
				break
			end
		end
	end
end

-- ============================================================================
-- ANTI-CHEAT AUDIT
-- ============================================================================

function SecurityAudit.AuditAntiCheat()
	print("\n[SecurityAudit] === ANTI-CHEAT SYSTEMS ===")

	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat

	if not AntiCheat then
		AddFinding("Critical", "AntiCheat", "AntiCheat system not found",
			"Implement AntiCheat system before launch")
		return
	end

	-- Check if AntiCheat is running
	if AntiCheat.IsRunning then
		AddFinding("Info", "AntiCheat", "AntiCheat system is running", "None")
	else
		AddFinding("Critical", "AntiCheat", "AntiCheat system is not running",
			"Start AntiCheat system in bootstrap")
	end

	-- Check configuration
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local success, GameConfig = pcall(function()
		return require(ReplicatedStorage.Shared.Config.GameConfig)
	end)

	if success and GameConfig and GameConfig.AntiCheat then
		if GameConfig.AntiCheat.Enabled then
			AddFinding("Info", "AntiCheat", "AntiCheat enabled in config", "None")
		else
			AddFinding("High", "AntiCheat", "AntiCheat disabled in config",
				"Enable AntiCheat for production")
		end

		-- Check detection thresholds
		if GameConfig.AntiCheat.TeleportThreshold and
		   GameConfig.AntiCheat.TeleportThreshold < 100 then
			AddFinding("Info", "AntiCheat", "Teleport detection configured", "None")
		else
			AddFinding("Medium", "AntiCheat", "Teleport threshold may be too lenient",
				"Review teleport detection threshold")
		end
	else
		AddFinding("High", "AntiCheat", "AntiCheat configuration not found",
			"Add AntiCheat configuration to GameConfig")
	end
end

-- ============================================================================
-- DATA SECURITY AUDIT
-- ============================================================================

function SecurityAudit.AuditDataSecurity()
	print("\n[SecurityAudit] === DATA SECURITY ===")

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService

	if not DataService then
		AddFinding("Critical", "DataService", "DataService not found",
			"Initialize DataService before launch")
		return
	end

	-- Check if using ProfileService (recommended)
	if DataService.ProfileStore or DataService.Profiles then
		AddFinding("Info", "DataService", "Using ProfileService (session locking)",
			"None - this is best practice")
	else
		AddFinding("High", "DataService", "Not using ProfileService",
			"Consider using ProfileService to prevent data loss")
	end

	-- Check if data is validated
	if DataService.ValidatePlayerData or DataService.Validate then
		AddFinding("Info", "DataService", "Data validation implemented", "None")
	else
		AddFinding("Medium", "DataService", "No data validation detected",
			"Add data validation to prevent corrupted data")
	end

	-- Check auto-save
	if DataService.AutoSave or DataService.SaveInterval then
		AddFinding("Info", "DataService", "Auto-save configured", "None")
	else
		AddFinding("Medium", "DataService", "No auto-save detected",
			"Implement periodic auto-save to prevent data loss")
	end
end

-- ============================================================================
-- RATE LIMITING AUDIT
-- ============================================================================

function SecurityAudit.AuditRateLimiting()
	print("\n[SecurityAudit] === RATE LIMITING ===")

	-- Check monetization services for rate limiting
	local services = {
		"VIPService",
		"BattlePassService",
		"GamePassService",
		"DevProductService"
	}

	local withRateLimiting = 0
	local withoutRateLimiting = {}

	for _, serviceName in ipairs(services) do
		local service = _G.TowerAscent and _G.TowerAscent[serviceName]

		if service then
			-- Check for rate limiting properties
			if service.PurchaseRateLimits or service.RateLimits or service.PurchasePromptCooldown then
				withRateLimiting += 1
				AddFinding("Info", "RateLimiting",
					string.format("%s has rate limiting", serviceName), "None")
			else
				table.insert(withoutRateLimiting, serviceName)
			end
		end
	end

	if #withoutRateLimiting > 0 then
		AddFinding("Medium", "RateLimiting",
			string.format("Services without rate limiting: %s",
				table.concat(withoutRateLimiting, ", ")),
			"Add rate limiting to prevent spam/exploitation")
	end
end

-- ============================================================================
-- INPUT VALIDATION AUDIT
-- ============================================================================

function SecurityAudit.AuditInputValidation()
	print("\n[SecurityAudit] === INPUT VALIDATION ===")

	-- Check coin service
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService

	if CoinService and CoinService.AddCoins then
		-- This is a basic check - actual validation needs code review
		AddFinding("Info", "InputValidation", "CoinService exists with AddCoins method",
			"Ensure AddCoins validates amount (positive, reasonable limit)")
	else
		AddFinding("Medium", "InputValidation", "CoinService or AddCoins not found",
			"Ensure coin transactions are properly validated")
	end

	-- Check upgrade service
	local UpgradeService = _G.TowerAscent and _G.TowerAscent.UpgradeService

	if UpgradeService then
		AddFinding("Info", "InputValidation", "UpgradeService exists",
			"Ensure upgrades validate player level, costs, and limits")
	else
		AddFinding("Medium", "InputValidation", "UpgradeService not found",
			"Validate upgrade purchases server-side")
	end
end

-- ============================================================================
-- PERMISSION AUDIT
-- ============================================================================

function SecurityAudit.AuditPermissions()
	print("\n[SecurityAudit] === PERMISSION SYSTEMS ===")

	-- Check for admin command protection
	local AdminCommands = _G.TowerAscent and _G.TowerAscent.AdminCommands

	if AdminCommands then
		AddFinding("High", "Permissions", "AdminCommands utility exists",
			"Ensure admin commands check for actual admin permissions (not just accessible)")

		-- Check if admin list exists
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local success, GameConfig = pcall(function()
			return require(ReplicatedStorage.Shared.Config.GameConfig)
		end)

		if success and GameConfig and GameConfig.Admins then
			AddFinding("Info", "Permissions", "Admin list configured", "None")
		else
			AddFinding("Medium", "Permissions", "No admin list found in config",
				"Add admin user ID list to GameConfig")
		end
	else
		AddFinding("Info", "Permissions", "No admin commands found",
			"None - this is acceptable for production")
	end

	-- Check debug mode
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local success, GameConfig = pcall(function()
		return require(ReplicatedStorage.Shared.Config.GameConfig)
	end)

	if success and GameConfig then
		if GameConfig.Debug and GameConfig.Debug.Enabled then
			AddFinding("Critical", "Permissions", "Debug mode is ENABLED",
				"DISABLE debug mode before production deployment!")
		else
			AddFinding("Info", "Permissions", "Debug mode is disabled", "None")
		end
	end
end

-- ============================================================================
-- GLOBAL EXPOSURE AUDIT
-- ============================================================================

function SecurityAudit.AuditGlobalExposure()
	print("\n[SecurityAudit] === GLOBAL EXPOSURE ===")

	-- Check _G exposure
	if _G.TowerAscent then
		AddFinding("High", "GlobalExposure", "_G.TowerAscent is exposed globally",
			"In production, only expose _G in debug mode or secure with checks")

		-- Count exposed services
		local count = 0
		for _ in pairs(_G.TowerAscent) do
			count += 1
		end

		print(string.format("  Exposed objects: %d", count))

		-- Critical services that shouldn't be directly exposed
		local sensitive = {"DataService", "AdminCommands", "AntiCheat"}
		for _, service in ipairs(sensitive) do
			if _G.TowerAscent[service] then
				AddFinding("High", "GlobalExposure",
					string.format("Sensitive service exposed: %s", service),
					"Protect sensitive services from client access")
			end
		end
	else
		AddFinding("Info", "GlobalExposure", "_G.TowerAscent not exposed", "None")
	end
end

-- ============================================================================
-- MARKETPLACE SECURITY AUDIT
-- ============================================================================

function SecurityAudit.AuditMarketplaceSecurity()
	print("\n[SecurityAudit] === MARKETPLACE SECURITY ===")

	local MarketplaceService = game:GetService("MarketplaceService")

	-- Check ProcessReceipt
	if MarketplaceService.ProcessReceipt then
		AddFinding("Info", "Marketplace", "ProcessReceipt handler configured", "None")

		-- Check DevProductService
		local DevProductService = _G.TowerAscent and _G.TowerAscent.DevProductService

		if DevProductService and DevProductService.ProcessReceipt then
			AddFinding("Info", "Marketplace",
				"DevProductService handles receipt processing", "None")

			-- Check for idempotency
			if DevProductService.PendingPurchases or DevProductService.ProcessedReceipts then
				AddFinding("Info", "Marketplace", "Receipt idempotency implemented",
					"None - prevents double-granting")
			else
				AddFinding("High", "Marketplace", "No receipt idempotency detected",
					"Implement receipt tracking to prevent double-granting")
			end
		else
			AddFinding("Medium", "Marketplace", "DevProductService not handling receipts",
				"Ensure receipt processing is properly implemented")
		end
	else
		AddFinding("Critical", "Marketplace", "No ProcessReceipt handler configured",
			"Configure ProcessReceipt to handle developer product purchases")
	end
end

-- ============================================================================
-- RUN ALL AUDITS
-- ============================================================================

function SecurityAudit.RunAll()
	print("\n" .. string.rep("=", 70))
	print("TOWER ASCENT - SECURITY AUDIT")
	print(string.rep("=", 70))

	-- Reset findings
	SecurityAudit.Findings = {
		Critical = {},
		High = {},
		Medium = {},
		Low = {},
		Info = {}
	}

	-- Run all audits
	SecurityAudit.AuditRemoteEvents()
	SecurityAudit.AuditAntiCheat()
	SecurityAudit.AuditDataSecurity()
	SecurityAudit.AuditRateLimiting()
	SecurityAudit.AuditInputValidation()
	SecurityAudit.AuditPermissions()
	SecurityAudit.AuditGlobalExposure()
	SecurityAudit.AuditMarketplaceSecurity()

	-- Print summary
	print("\n" .. string.rep("=", 70))
	print("SECURITY AUDIT SUMMARY")
	print(string.rep("=", 70))

	local criticalCount = #SecurityAudit.Findings.Critical
	local highCount = #SecurityAudit.Findings.High
	local mediumCount = #SecurityAudit.Findings.Medium
	local lowCount = #SecurityAudit.Findings.Low
	local infoCount = #SecurityAudit.Findings.Info

	print(string.format("🔴 Critical: %d", criticalCount))
	print(string.format("🟠 High:     %d", highCount))
	print(string.format("🟡 Medium:   %d", mediumCount))
	print(string.format("🔵 Low:      %d", lowCount))
	print(string.format("ℹ️  Info:     %d", infoCount))

	-- Security score
	local totalIssues = criticalCount + highCount + mediumCount + lowCount
	local securityScore = 100

	if criticalCount > 0 then
		securityScore -= (criticalCount * 20)
	end
	if highCount > 0 then
		securityScore -= (highCount * 10)
	end
	if mediumCount > 0 then
		securityScore -= (mediumCount * 5)
	end
	if lowCount > 0 then
		securityScore -= (lowCount * 2)
	end

	securityScore = math.max(0, securityScore)

	print(string.format("\n🛡️  Security Score: %d/100", securityScore))

	-- Determine security status
	if criticalCount > 0 then
		warn("❌ CRITICAL ISSUES FOUND - DO NOT DEPLOY")
	elseif highCount > 0 then
		warn("⚠️  HIGH PRIORITY ISSUES - Address before launch")
	elseif mediumCount > 3 then
		warn("⚠️  Multiple medium issues - Review recommended")
	else
		print("✅ Security posture acceptable for launch")
	end

	print(string.rep("=", 70) .. "\n")

	return SecurityAudit.Findings
end

-- ============================================================================
-- GENERATE REPORT
-- ============================================================================

function SecurityAudit.GenerateReport()
	local report = "TOWER ASCENT - SECURITY AUDIT REPORT\n"
	report = report .. string.rep("=", 70) .. "\n\n"

	local function addSection(severity, findings)
		if #findings > 0 then
			report = report .. string.format("\n%s FINDINGS (%d):\n", severity:upper(), #findings)
			report = report .. string.rep("-", 70) .. "\n"

			for i, finding in ipairs(findings) do
				report = report .. string.format("\n%d. [%s] %s\n",
					i, finding.Category, finding.Issue)
				report = report .. string.format("   Recommendation: %s\n",
					finding.Recommendation)
			end
		end
	end

	addSection("Critical", SecurityAudit.Findings.Critical)
	addSection("High", SecurityAudit.Findings.High)
	addSection("Medium", SecurityAudit.Findings.Medium)
	addSection("Low", SecurityAudit.Findings.Low)

	report = report .. "\n" .. string.rep("=", 70) .. "\n"

	return report
end

return SecurityAudit
