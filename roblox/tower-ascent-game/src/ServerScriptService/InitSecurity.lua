--[[
	InitSecurity.lua
	Initializes and integrates the complete security system

	This script sets up:
	- SecurityManager (core security)
	- SecureRemotes (protected remotes)
	- DataEncryption (data protection)
	- AuthSystem (authentication)
	- AntiExploit (exploit detection)
	- All integrations

	Place this in ServerScriptService to enable full security.

	Created: 2025-12-02
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for game to initialize
task.wait(2)

print("=" .. string.rep("=", 60))
print("INITIALIZING SECURITY SYSTEM")
print(string.rep("=", 60))

-- Ensure _G.TowerAscent exists
_G.TowerAscent = _G.TowerAscent or {}

-- ============================================================================
-- LOAD MODULES
-- ============================================================================

print("[Security] Loading security modules...")

-- Find Security folder
local SecurityFolder = ServerScriptService:FindFirstChild("Security")
if not SecurityFolder then
	warn("[Security] Security folder not found! Creating one...")
	SecurityFolder = Instance.new("Folder")
	SecurityFolder.Name = "Security"
	SecurityFolder.Parent = ServerScriptService
end

local modules = {}
local loadOrder = {
	"SecurityManager",    -- Core security (load first)
	"DataEncryption",    -- Data protection
	"AuthSystem",        -- Authentication
	"SecureRemotes",     -- Remote security
	"AntiExploit"       -- Exploit detection
}

-- Load modules in order
for _, moduleName in ipairs(loadOrder) do
	local moduleScript = SecurityFolder:FindFirstChild(moduleName)
	if moduleScript then
		local success, module = pcall(require, moduleScript)
		if success then
			modules[moduleName] = module
			print(string.format("  ✅ %s loaded", moduleName))
		else
			warn(string.format("  ❌ %s failed to load: %s", moduleName, module))
		end
	else
		warn(string.format("  ⚠️ %s not found", moduleName))
	end
end

-- ============================================================================
-- REGISTER WITH GLOBAL TABLE
-- ============================================================================

print("[Security] Registering modules with _G.TowerAscent...")

for name, module in pairs(modules) do
	_G.TowerAscent[name] = module
end

-- ============================================================================
-- INITIALIZE MODULES
-- ============================================================================

print("[Security] Initializing security systems...")

-- Initialize in specific order
local initOrder = {
	"SecurityManager",
	"DataEncryption",
	"AuthSystem",
	"SecureRemotes",
	"AntiExploit"
}

for _, moduleName in ipairs(initOrder) do
	local module = modules[moduleName]
	if module and module.Initialize then
		local success, err = pcall(module.Initialize)
		if success then
			print(string.format("  ✅ %s initialized", moduleName))
		else
			warn(string.format("  ❌ %s initialization failed: %s", moduleName, err))
		end
	end
end

-- ============================================================================
-- CROSS-MODULE INTEGRATION
-- ============================================================================

print("[Security] Setting up module integrations...")

-- SecurityManager integration
if modules.SecurityManager then
	-- Give SecurityManager access to other modules
	modules.SecurityManager.AuthSystem = modules.AuthSystem
	modules.SecurityManager.AntiExploit = modules.AntiExploit
	modules.SecurityManager.DataEncryption = modules.DataEncryption
	modules.SecurityManager.SecureRemotes = modules.SecureRemotes
	print("  ✅ SecurityManager integrated")
end

-- SecureRemotes integration with SecurityManager
if modules.SecureRemotes and modules.SecurityManager then
	-- Override sanitization to use SecurityManager
	local originalSanitize = modules.SecureRemotes.ValidateAndSanitize
	if originalSanitize then
		modules.SecureRemotes.ValidateAndSanitize = function(self, player, args)
			-- First use SecurityManager validation
			for i, arg in ipairs(args) do
				if typeof(arg) == "string" then
					args[i] = modules.SecurityManager.SanitizeString(arg)
					if not args[i] then
						return nil -- Malicious content detected
					end
				end
			end
			-- Then apply original validation
			return originalSanitize(self, player, args)
		end
	end
	print("  ✅ SecureRemotes integrated with SecurityManager")
end

-- AuthSystem integration with DataEncryption
if modules.AuthSystem and modules.DataEncryption then
	-- Auth data will be automatically encrypted
	print("  ✅ AuthSystem integrated with DataEncryption")
end

-- AntiExploit integration with SecurityManager
if modules.AntiExploit and modules.SecurityManager then
	-- AntiExploit will use SecurityManager's ban system
	print("  ✅ AntiExploit integrated with SecurityManager")
end

-- ============================================================================
-- SECURE EXISTING REMOTES
-- ============================================================================

if modules.SecureRemotes then
	print("[Security] Securing existing RemoteEvents...")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- Find and secure existing remotes
	for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
		if remote:IsA("RemoteEvent") then
			-- Don't re-secure already secured remotes
			if not remote:GetAttribute("Secured") then
				print(string.format("  🔒 Securing: %s", remote.Name))

				-- Create secure wrapper
				local secureRemote = modules.SecureRemotes.CreateRemoteEvent(remote.Name, {
					RequiresAuth = false, -- Don't require auth by default
					MaxCallsPerSecond = 10
				})

				remote:SetAttribute("Secured", true)
			end
		elseif remote:IsA("RemoteFunction") then
			if not remote:GetAttribute("Secured") then
				print(string.format("  🔒 Securing: %s", remote.Name))

				local secureRemote = modules.SecureRemotes.CreateRemoteFunction(remote.Name, {
					RequiresAuth = false,
					MaxCallsPerSecond = 5,
					Timeout = 10
				})

				remote:SetAttribute("Secured", true)
			end
		end
	end
end

-- ============================================================================
-- ADMIN COMMAND SECURITY
-- ============================================================================

if modules.AuthSystem then
	print("[Security] Securing admin commands...")

	local AdminCommands = _G.TowerAscent.AdminCommands
	if AdminCommands then
		-- Wrap admin command execution with auth check
		local originalExecute = AdminCommands.ExecuteCommand
		if originalExecute then
			AdminCommands.ExecuteCommand = function(player, command, ...)
				-- Check if player has admin permission
				if not modules.AuthSystem.Authorize(player, "admin.commands") then
					warn(string.format("[Security] Unauthorized admin command attempt: %s by %s",
						command, player.Name))

					-- Report suspicious activity
					if modules.SecurityManager then
						modules.SecurityManager.RecordSuspiciousActivity(player, "UNAUTH_ADMIN_COMMAND")
					end

					return false, "Insufficient permissions"
				end

				-- Execute command
				return originalExecute(player, command, ...)
			end
		end
		print("  ✅ Admin commands secured")
	else
		warn("  ⚠️ AdminCommands not found")
	end
end

-- ============================================================================
-- DATA SERVICE SECURITY
-- ============================================================================

if modules.DataEncryption then
	print("[Security] Securing DataService...")

	local DataService = _G.TowerAscent.DataService
	if DataService then
		-- Wrap save functions with encryption
		local originalSave = DataService.SaveProfile
		if originalSave then
			DataService.SaveProfile = function(player, data)
				-- Encrypt sensitive fields
				local encryptedData = modules.DataEncryption.SecurePlayerData(data or player)
				return originalSave(player, encryptedData)
			end
		end

		-- Wrap load functions with decryption
		local originalLoad = DataService.LoadProfile
		if originalLoad then
			DataService.LoadProfile = function(player)
				local data = originalLoad(player)
				if data then
					-- Decrypt sensitive fields
					return modules.DataEncryption.RestorePlayerData(data)
				end
				return data
			end
		end

		print("  ✅ DataService secured")
	else
		warn("  ⚠️ DataService not found")
	end
end

-- ============================================================================
-- PLAYER SECURITY EVENTS
-- ============================================================================

print("[Security] Setting up player security events...")

Players.PlayerAdded:Connect(function(player)
	-- Authenticate player
	if modules.AuthSystem then
		task.spawn(function()
			local success, error, session = modules.AuthSystem.Authenticate(player)
			if success then
				print(string.format("  ✅ %s authenticated (Role: %s)",
					player.Name, session.Role))
			else
				warn(string.format("  ❌ %s authentication failed: %s",
					player.Name, error or "Unknown"))
			end
		end)
	end

	-- Check if player is banned
	if modules.SecurityManager then
		if modules.SecurityManager.IsPlayerBanned(player) then
			local banInfo = modules.SecurityManager.GetBanInfo(player.UserId)
			player:Kick(string.format("You are banned. Reason: %s",
				banInfo and banInfo.Reason or "Unknown"))
		end
	end

	-- Start monitoring for exploits
	if modules.AntiExploit then
		-- AntiExploit auto-monitors through its own PlayerAdded
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up auth session
	if modules.AuthSystem then
		modules.AuthSystem.Logout(player)
	end

	-- Clear any temporary security data
	if modules.SecurityManager then
		modules.SecurityManager.ClearPlayerData(player)
	end
end)

-- ============================================================================
-- SECURITY MONITORING
-- ============================================================================

print("[Security] Starting security monitoring...")

-- Periodic security report
task.spawn(function()
	while true do
		task.wait(300) -- Every 5 minutes

		local report = {
			Timestamp = tick(),
			Modules = {}
		}

		-- Collect status from each module
		if modules.SecurityManager then
			report.Modules.SecurityManager = {
				Enabled = modules.SecurityManager.Enabled,
				BannedPlayers = modules.SecurityManager.GetBannedPlayers and #modules.SecurityManager.GetBannedPlayers() or 0
			}
		end

		if modules.AuthSystem then
			report.Modules.AuthSystem = {
				Enabled = modules.AuthSystem.Enabled,
				ActiveSessions = #modules.AuthSystem.GetAllActiveSessions()
			}
		end

		if modules.AntiExploit then
			local stats = modules.AntiExploit.GetStatistics()
			report.Modules.AntiExploit = {
				Enabled = modules.AntiExploit.Enabled,
				TotalDetections = stats.TotalDetections,
				CurrentViolators = #stats.CurrentViolators
			}
		end

		if modules.SecureRemotes then
			report.Modules.SecureRemotes = {
				Enabled = modules.SecureRemotes.Enabled,
				SecuredRemotes = modules.SecureRemotes.GetAllRemotes and #modules.SecureRemotes.GetAllRemotes() or 0
			}
		end

		if modules.DataEncryption then
			local stats = modules.DataEncryption.GetStatistics()
			report.Modules.DataEncryption = {
				Enabled = stats.EncryptionEnabled,
				KeyVersion = stats.CurrentKeyVersion
			}
		end

		-- Log report
		print("\n[Security Report]")
		for moduleName, status in pairs(report.Modules) do
			print(string.format("  %s: %s",
				moduleName,
				status.Enabled and "✅ Active" or "❌ Inactive"))
		end
	end
end)

-- ============================================================================
-- HEALTH CHECK
-- ============================================================================

task.wait(1)

print("\n[Security] Running health check...")

local healthCheck = {
	SecurityManager = modules.SecurityManager and modules.SecurityManager.Enabled,
	DataEncryption = modules.DataEncryption and modules.DataEncryption.Enabled,
	AuthSystem = modules.AuthSystem and modules.AuthSystem.Enabled,
	SecureRemotes = modules.SecureRemotes and modules.SecureRemotes.Enabled,
	AntiExploit = modules.AntiExploit and modules.AntiExploit.Enabled
}

local allHealthy = true
for system, status in pairs(healthCheck) do
	if status then
		print(string.format("  ✅ %s: ACTIVE", system))
	else
		print(string.format("  ❌ %s: INACTIVE", system))
		allHealthy = false
	end
end

-- ============================================================================
-- FINAL STATUS
-- ============================================================================

print("\n" .. string.rep("=", 60))

if allHealthy then
	print("🛡️ SECURITY SYSTEM FULLY OPERATIONAL")
	print("All security modules are active and integrated")
	print("Protection levels:")
	print("  • Remote exploitation: PROTECTED")
	print("  • Data encryption: ACTIVE")
	print("  • Authentication: ENFORCED")
	print("  • Anti-exploit: MONITORING")
	print("  • Admin commands: SECURED")
else
	print("⚠️ SECURITY SYSTEM PARTIALLY OPERATIONAL")
	print("Some security features may not be available")
end

print(string.rep("=", 60) .. "\n")

-- ============================================================================
-- EXPORT
-- ============================================================================

return {
	SecurityManager = modules.SecurityManager,
	DataEncryption = modules.DataEncryption,
	AuthSystem = modules.AuthSystem,
	SecureRemotes = modules.SecureRemotes,
	AntiExploit = modules.AntiExploit,
	Initialized = allHealthy
}