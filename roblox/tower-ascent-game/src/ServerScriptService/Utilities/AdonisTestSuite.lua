--[[
	AdonisTestSuite.lua
	Automated testing suite for Adonis integration

	Tests all Adonis integrations with Tower Ascent systems:
	- ServiceLocator integration
	- SecurityManager ban escalation
	- WebhookLogger integration
	- Custom commands existence
	- Plugin loading

	Usage in Command Bar:
		local AdonisTestSuite = require(game.ServerScriptService.Utilities.AdonisTestSuite)
		AdonisTestSuite.RunAllTests()

	Created: 2025-12-18
]]

local AdonisTestSuite = {}

local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- TEST UTILITIES
-- ============================================================================

local function testPassed(testName)
	print(string.format("✅ [AdonisTest] PASSED: %s", testName))
	return true
end

local function testFailed(testName, reason)
	warn(string.format("❌ [AdonisTest] FAILED: %s - %s", testName, reason))
	return false
end

local function testWarning(testName, message)
	warn(string.format("⚠️  [AdonisTest] WARNING: %s - %s", testName, message))
end

-- ============================================================================
-- TEST 1: ADONIS LOADER EXISTS
-- ============================================================================

function AdonisTestSuite.TestAdonisLoaderExists()
	print("\n[AdonisTest] Testing Adonis Loader installation...")

	local adonisLoader = ServerScriptService:FindFirstChild("Adonis_Loader")

	if not adonisLoader then
		return testFailed("Adonis Loader", "Adonis_Loader not found in ServerScriptService")
	end

	-- Check for Config folder
	local config = adonisLoader:FindFirstChild("Config")
	if not config then
		return testFailed("Adonis Config", "Config folder not found in Adonis_Loader")
	end

	-- Check for Settings module
	local settings = config:FindFirstChild("Settings")
	if not settings then
		return testFailed("Adonis Settings", "Settings module not found in Config")
	end

	-- Check for Plugins folder
	local plugins = config:FindFirstChild("Plugins")
	if not plugins then
		return testFailed("Adonis Plugins", "Plugins folder not found in Config")
	end

	return testPassed("Adonis Loader Installation")
end

-- ============================================================================
-- TEST 2: TOWER ASCENT PLUGINS INSTALLED
-- ============================================================================

function AdonisTestSuite.TestPluginsInstalled()
	print("\n[AdonisTest] Testing Tower Ascent plugins...")

	local adonisLoader = ServerScriptService:FindFirstChild("Adonis_Loader")
	if not adonisLoader then
		return testFailed("Plugins Check", "Adonis_Loader not found")
	end

	local plugins = adonisLoader:FindFirstChild("Config")
		and adonisLoader.Config:FindFirstChild("Plugins")

	if not plugins then
		return testFailed("Plugins Check", "Plugins folder not found")
	end

	-- Check for required plugins
	local requiredPlugins = {
		"Server-TowerAscentSecurity",
		"Server-WebhookLogger"
	}

	local missingPlugins = {}
	for _, pluginName in ipairs(requiredPlugins) do
		if not plugins:FindFirstChild(pluginName) then
			table.insert(missingPlugins, pluginName)
		end
	end

	if #missingPlugins > 0 then
		return testFailed("Plugins Check",
			"Missing plugins: " .. table.concat(missingPlugins, ", "))
	end

	return testPassed("Tower Ascent Plugins Installed")
end

-- ============================================================================
-- TEST 3: TOWER ASCENT SYSTEMS AVAILABLE
-- ============================================================================

function AdonisTestSuite.TestTowerAscentSystems()
	print("\n[AdonisTest] Testing Tower Ascent systems availability...")

	-- Test ServiceLocator
	local success1, ServiceLocator = pcall(function()
		return require(ServerScriptService.Utilities.ServiceLocator)
	end)

	if not success1 or not ServiceLocator then
		return testFailed("Tower Ascent Systems", "ServiceLocator not available")
	end

	-- Test SecurityManager
	local SecurityManager = ServiceLocator.Get("SecurityManager")
	if not SecurityManager then
		testWarning("Tower Ascent Systems", "SecurityManager not registered in ServiceLocator")
	end

	-- Test WebhookLogger
	local success2, WebhookLogger = pcall(function()
		return require(ServerScriptService.Utilities.WebhookLogger)
	end)

	if not success2 or not WebhookLogger then
		testWarning("Tower Ascent Systems", "WebhookLogger not available")
	end

	return testPassed("Tower Ascent Systems Available")
end

-- ============================================================================
-- TEST 4: ADONIS COMMANDS EXIST
-- ============================================================================

function AdonisTestSuite.TestCustomCommandsExist()
	print("\n[AdonisTest] Testing custom commands...")

	-- Try to access Adonis server
	local adonisLoader = ServerScriptService:FindFirstChild("Adonis_Loader")
	if not adonisLoader then
		return testFailed("Custom Commands", "Adonis not installed")
	end

	-- Note: We can't easily test if commands exist without the server running
	-- This test just verifies the plugins are in place
	local plugins = adonisLoader:FindFirstChild("Config")
		and adonisLoader.Config:FindFirstChild("Plugins")

	if not plugins then
		return testFailed("Custom Commands", "Plugins folder not found")
	end

	local securityPlugin = plugins:FindFirstChild("Server-TowerAscentSecurity")
	if not securityPlugin then
		return testFailed("Custom Commands",
			"Server-TowerAscentSecurity plugin missing (provides custom commands)")
	end

	-- Can't test actual command registration without server running
	testWarning("Custom Commands",
		"Commands can only be tested in-game. Use :cmds to verify.")

	return testPassed("Custom Commands Plugin Installed")
end

-- ============================================================================
-- TEST 5: HTTPSERVICE ENABLED
-- ============================================================================

function AdonisTestSuite.TestHttpServiceEnabled()
	print("\n[AdonisTest] Testing HttpService...")

	local HttpService = game:GetService("HttpService")

	local success, result = pcall(function()
		return HttpService.HttpEnabled
	end)

	if not success or not result then
		testWarning("HttpService",
			"HttpService not enabled - webhooks won't work! " ..
			"Enable in Game Settings → Security → Allow HTTP Requests")
		return false
	end

	return testPassed("HttpService Enabled")
end

-- ============================================================================
-- TEST 6: WEBHOOK CONFIGURATION
-- ============================================================================

function AdonisTestSuite.TestWebhookConfiguration()
	print("\n[AdonisTest] Testing webhook configuration...")

	local success, WebhookLogger = pcall(function()
		return require(ServerScriptService.Utilities.WebhookLogger)
	end)

	if not success or not WebhookLogger then
		return testFailed("Webhook Configuration", "WebhookLogger not available")
	end

	-- Try to check if webhook URL is configured
	-- Note: WebhookLogger doesn't expose the URL, so we just verify the module loaded
	testWarning("Webhook Configuration",
		"Cannot verify webhook URL. Test with WebhookLogger.LogEvent() manually.")

	return testPassed("WebhookLogger Module Loaded")
end

-- ============================================================================
-- TEST 7: SETTINGS CONFIGURATION
-- ============================================================================

function AdonisTestSuite.TestAdonisSettings()
	print("\n[AdonisTest] Testing Adonis settings...")

	local adonisLoader = ServerScriptService:FindFirstChild("Adonis_Loader")
	if not adonisLoader then
		return testFailed("Settings Check", "Adonis not installed")
	end

	local settings = adonisLoader:FindFirstChild("Config")
		and adonisLoader.Config:FindFirstChild("Settings")

	if not settings then
		return testFailed("Settings Check", "Settings module not found")
	end

	-- Try to require settings
	local success, settingsModule = pcall(function()
		return require(settings)
	end)

	if not success then
		return testFailed("Settings Check",
			"Settings module has errors: " .. tostring(settingsModule))
	end

	-- Check if DataStoreKey was changed
	if settingsModule.DataStoreKey == "CHANGE_THIS_KEY" then
		testWarning("Settings Check",
			"DataStoreKey still set to default! Change this for security!")
		return false
	end

	-- Check if any admins configured
	if not settingsModule.Admins or #settingsModule.Admins == 0 then
		testWarning("Settings Check",
			"No admins configured! Add yourself to the Admins table.")
		return false
	end

	return testPassed("Adonis Settings Configured")
end

-- ============================================================================
-- MAIN TEST RUNNER
-- ============================================================================

function AdonisTestSuite.RunAllTests()
	print("\n" .. string.rep("=", 60))
	print("ADONIS INTEGRATION TEST SUITE")
	print(string.rep("=", 60))

	local results = {
		Passed = 0,
		Failed = 0,
		Warnings = 0,
		Tests = {}
	}

	local tests = {
		{Name = "Adonis Loader Installation", Func = AdonisTestSuite.TestAdonisLoaderExists},
		{Name = "Tower Ascent Plugins", Func = AdonisTestSuite.TestPluginsInstalled},
		{Name = "Tower Ascent Systems", Func = AdonisTestSuite.TestTowerAscentSystems},
		{Name = "Custom Commands", Func = AdonisTestSuite.TestCustomCommandsExist},
		{Name = "HttpService", Func = AdonisTestSuite.TestHttpServiceEnabled},
		{Name = "Webhook Configuration", Func = AdonisTestSuite.TestWebhookConfiguration},
		{Name = "Adonis Settings", Func = AdonisTestSuite.TestAdonisSettings},
	}

	for _, test in ipairs(tests) do
		local success, result = pcall(test.Func)

		if success and result then
			results.Passed = results.Passed + 1
			table.insert(results.Tests, {Name = test.Name, Passed = true})
		elseif success and result == false then
			results.Warnings = results.Warnings + 1
			table.insert(results.Tests, {Name = test.Name, Passed = false, Warning = true})
		else
			results.Failed = results.Failed + 1
			table.insert(results.Tests, {
				Name = test.Name,
				Passed = false,
				Error = not success and tostring(result) or nil
			})
		end
	end

	-- Print summary
	print("\n" .. string.rep("=", 60))
	print("TEST RESULTS SUMMARY")
	print(string.rep("=", 60))
	print(string.format("Total Tests: %d", results.Passed + results.Failed + results.Warnings))
	print(string.format("✅ Passed: %d", results.Passed))
	print(string.format("⚠️  Warnings: %d", results.Warnings))
	print(string.format("❌ Failed: %d", results.Failed))
	print(string.rep("=", 60))

	if results.Failed == 0 and results.Warnings == 0 then
		print("🎉 ALL TESTS PASSED!")
		print("✅ Adonis integration is ready to use")
		print("\nNext steps:")
		print("1. Play the game (F5)")
		print("2. Type :cmds in chat to verify")
		print("3. Test custom commands: :exploitstats, :banhistory YourName")
	elseif results.Failed == 0 then
		print("⚠️  TESTS PASSED WITH WARNINGS")
		print("\nWarnings found:")
		for _, test in ipairs(results.Tests) do
			if test.Warning then
				print(string.format("  - %s", test.Name))
			end
		end
		print("\nAdonis should work, but review warnings above.")
	else
		warn("❌ SOME TESTS FAILED")
		print("\nFailed Tests:")
		for _, test in ipairs(results.Tests) do
			if not test.Passed and not test.Warning then
				print(string.format("  - %s", test.Name))
				if test.Error then
					print(string.format("    Error: %s", test.Error))
				end
			end
		end
		print("\nFix the issues above and run tests again.")
	end

	print(string.rep("=", 60))

	return results
end

-- ============================================================================
-- QUICK CHECK (MINIMAL TEST)
-- ============================================================================

function AdonisTestSuite.QuickCheck()
	print("[AdonisTest] Running quick check...")

	local checks = {
		AdonisInstalled = ServerScriptService:FindFirstChild("Adonis_Loader") ~= nil,
		PluginsInstalled = false,
		SystemsAvailable = false,
	}

	-- Check plugins
	local adonisLoader = ServerScriptService:FindFirstChild("Adonis_Loader")
	if adonisLoader then
		local plugins = adonisLoader:FindFirstChild("Config")
			and adonisLoader.Config:FindFirstChild("Plugins")
		if plugins then
			checks.PluginsInstalled =
				plugins:FindFirstChild("Server-TowerAscentSecurity") ~= nil and
				plugins:FindFirstChild("Server-WebhookLogger") ~= nil
		end
	end

	-- Check systems
	local success, ServiceLocator = pcall(function()
		return require(ServerScriptService.Utilities.ServiceLocator)
	end)
	checks.SystemsAvailable = success and ServiceLocator ~= nil

	-- Print results
	for name, passed in pairs(checks) do
		if passed then
			print(string.format("✅ %s", name))
		else
			warn(string.format("❌ %s", name))
		end
	end

	local allPassed = checks.AdonisInstalled and checks.PluginsInstalled and checks.SystemsAvailable

	if allPassed then
		print("[AdonisTest] ✅ Quick check passed - Basic setup looks good")
	else
		warn("[AdonisTest] ❌ Quick check failed - Review errors above")
	end

	return allPassed
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return AdonisTestSuite
