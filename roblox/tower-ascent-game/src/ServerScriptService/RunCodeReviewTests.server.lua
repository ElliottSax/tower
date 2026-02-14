--[[
	RunCodeReviewTests.server.lua
	Automatically runs code review validation tests on server start

	Purpose:
	- Validates all code review fixes are working correctly
	- Runs automatically when server starts (or when script is enabled)
	- Can be disabled by setting ENABLED to false

	Usage:
	- Enable this script in ServerScriptService to run tests
	- Check server console for test results
	- Disable after validation is complete
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local ENABLED = false -- Set to true to run tests
local AUTO_RUN = false -- Set to true to run automatically on server start
local RUN_ON_COMMAND = true -- Allow running via Admin command

if not ENABLED then
	print("[CodeReviewTests] Validation tests disabled. Set ENABLED = true to run.")
	return
end

-- Load validator
local success, Validator = pcall(function()
	return require(ServerScriptService.Utilities.CodeReviewValidation)
end)

if not success then
	warn("[CodeReviewTests] Failed to load CodeReviewValidation:", Validator)
	return
end

print("[CodeReviewTests] Code Review Validation loaded successfully")

-- Run tests automatically if configured
if AUTO_RUN then
	task.wait(3) -- Wait for all services to initialize

	print("\n[CodeReviewTests] Running automatic validation...")
	local results = Validator.RunAllTests()

	if results.Failed == 0 then
		print("[CodeReviewTests] ✅ All validation tests passed!")
	else
		warn(string.format("[CodeReviewTests] ⚠️  %d tests failed", results.Failed))
	end
end

-- Make available for admin commands
if RUN_ON_COMMAND then
	-- Store in ServerScriptService for admin access
	local ValidatorAPI = Instance.new("ModuleScript")
	ValidatorAPI.Name = "__CodeReviewValidator"
	ValidatorAPI.Parent = ServerScriptService

	-- Store reference for admin commands
	_G.RunCodeReviewTests = function()
		return Validator.RunAllTests()
	end

	_G.RunCriticalTests = function()
		return Validator.RunCriticalTests()
	end

	_G.RunHighPriorityTests = function()
		return Validator.RunHighPriorityTests()
	end

	_G.RunPerformanceTests = function()
		return Validator.RunPerformanceTests()
	end

	print("[CodeReviewTests] Validation functions registered:")
	print("  - _G.RunCodeReviewTests() - Run all tests")
	print("  - _G.RunCriticalTests() - Run critical fix tests only")
	print("  - _G.RunHighPriorityTests() - Run high-priority fix tests only")
	print("  - _G.RunPerformanceTests() - Run performance optimization tests only")
end
