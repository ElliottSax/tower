--[[
	DebugUtilities.lua
	Comprehensive testing and debugging tools for Tower Ascent

	Features:
	- Test all 50 section templates
	- Validate section integrity
	- Test moving platform system
	- Test theme system
	- Performance profiling
	- Error reporting
	- Admin commands

	Usage:
	_G.TowerAscent.DebugUtilities.TestAllSections()
	_G.TowerAscent.DebugUtilities.ValidateTower(tower)
	_G.TowerAscent.DebugUtilities.TestMovingPlatforms(tower)

	Week 8: Code review and testing utilities
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SectionLoader = require(script.Parent.Parent.Services.SectionLoader)
local SectionBuilder = require(script.Parent.SectionBuilder)
local ThemeService = require(script.Parent.Parent.Services.ThemeService)
local MovingPlatformService = require(script.Parent.Parent.Services.MovingPlatformService)

-- Week 11: Added hazard and weather testing
local HazardService, WeatherService

local DebugUtilities = {}

-- ============================================================================
-- TEST RESULTS TRACKING
-- ============================================================================

local TestResults = {
	TotalTests = 0,
	PassedTests = 0,
	FailedTests = 0,
	Errors = {},
}

local function resetTestResults()
	TestResults = {
		TotalTests = 0,
		PassedTests = 0,
		FailedTests = 0,
		Errors = {},
	}
end

local function recordTest(testName: string, passed: boolean, errorMsg: string?)
	TestResults.TotalTests = TestResults.TotalTests + 1

	if passed then
		TestResults.PassedTests = TestResults.PassedTests + 1
		print(string.format("✓ PASS: %s", testName))
	else
		TestResults.FailedTests = TestResults.FailedTests + 1
		table.insert(TestResults.Errors, {
			Test = testName,
			Error = errorMsg or "Unknown error",
		})
		warn(string.format("✗ FAIL: %s - %s", testName, errorMsg or "Unknown error"))
	end
end

local function printTestSummary()
	print("\n" .. string.rep("=", 60))
	print("TEST SUMMARY")
	print(string.rep("=", 60))
	print(string.format("Total Tests: %d", TestResults.TotalTests))
	print(string.format("Passed: %d (%.1f%%)",
		TestResults.PassedTests,
		TestResults.TotalTests > 0 and (TestResults.PassedTests / TestResults.TotalTests * 100) or 0
	))
	print(string.format("Failed: %d (%.1f%%)",
		TestResults.FailedTests,
		TestResults.TotalTests > 0 and (TestResults.FailedTests / TestResults.TotalTests * 100) or 0
	))

	if #TestResults.Errors > 0 then
		print("\nERRORS:")
		for i, error in ipairs(TestResults.Errors) do
			print(string.format("  %d. %s: %s", i, error.Test, error.Error))
		end
	end

	print(string.rep("=", 60) .. "\n")

	return TestResults.FailedTests == 0
end

-- ============================================================================
-- SECTION TEMPLATE TESTING
-- ============================================================================

function DebugUtilities.TestAllSections()
	--[[
		Tests all 50 section templates for build errors.
		Returns true if all tests pass.
	--]]

	print("\n[DebugUtilities] Testing all section templates...")
	resetTestResults()

	local tiers = {"Easy", "Medium", "Hard", "Expert"}

	for _, tier in ipairs(tiers) do
		local templateNames = SectionLoader.ListTemplates(tier)

		print(string.format("\nTesting %s sections (%d templates)...", tier, #templateNames))

		for _, templateName in ipairs(templateNames) do
			DebugUtilities.TestSectionTemplate(tier, templateName)
		end
	end

	return printTestSummary()
end

function DebugUtilities.TestSectionTemplate(tier: string, templateName: string): boolean
	--[[
		Tests a single section template.
	--]]

	local sectionsFolder = ServerStorage:FindFirstChild("Sections")
	if not sectionsFolder then
		recordTest(templateName, false, "Sections folder not found")
		return false
	end

	local tierFolder = sectionsFolder:FindFirstChild(tier)
	if not tierFolder then
		recordTest(templateName, false, string.format("%s folder not found", tier))
		return false
	end

	local template = tierFolder:FindFirstChild(templateName)
	if not template then
		recordTest(templateName, false, "Template not found in ServerStorage")
		return false
	end

	-- Validate template
	local validationResult, validationError = DebugUtilities.ValidateSection(template)
	if not validationResult then
		recordTest(templateName, false, validationError)
		return false
	end

	recordTest(templateName, true)
	return true
end

-- ============================================================================
-- SECTION VALIDATION
-- ============================================================================

function DebugUtilities.ValidateSection(section: Model): (boolean, string?)
	--[[
		Validates a section has all required components.
		Returns (success, errorMessage)
	--]]

	-- Check if it's a Model
	if not section:IsA("Model") then
		return false, "Not a Model"
	end

	-- Check PrimaryPart
	if not section.PrimaryPart then
		return false, "Missing PrimaryPart"
	end

	-- Check for Start attachment
	local hasStart = false
	local hasNext = false
	local hasCheckpoint = false
	local platformCount = 0

	for _, descendant in ipairs(section:GetDescendants()) do
		if descendant:IsA("Attachment") then
			if descendant.Name == "Start" then
				hasStart = true
			elseif descendant.Name == "Next" then
				hasNext = true
			end
		elseif descendant.Name == "Checkpoint" then
			hasCheckpoint = true
		elseif descendant.Name:match("Platform") and descendant:IsA("BasePart") then
			platformCount = platformCount + 1
		end
	end

	if not hasStart then
		return false, "Missing Start attachment"
	end

	if not hasNext then
		return false, "Missing Next attachment"
	end

	if not hasCheckpoint then
		-- Warning, not error
		warn(string.format("[Validation] %s missing Checkpoint (recommended)", section.Name))
	end

	if platformCount == 0 then
		return false, "No platforms found"
	end

	-- Check attributes
	local tier = section:GetAttribute("Tier")
	if not tier then
		return false, "Missing Tier attribute"
	end

	local validTiers = {Easy = true, Medium = true, Hard = true, Expert = true}
	if not validTiers[tier] then
		return false, string.format("Invalid tier: %s", tier)
	end

	return true
end

-- ============================================================================
-- TOWER VALIDATION
-- ============================================================================

function DebugUtilities.ValidateTower(tower: Model): boolean
	--[[
		Validates an entire generated tower.
	--]]

	print("\n[DebugUtilities] Validating tower...")
	resetTestResults()

	-- Check tower exists
	if not tower then
		recordTest("Tower exists", false, "Tower is nil")
		return printTestSummary()
	end

	recordTest("Tower exists", true)

	-- Check tower is in workspace
	if tower.Parent ~= workspace then
		recordTest("Tower in workspace", false, "Tower not in workspace")
	else
		recordTest("Tower in workspace", true)
	end

	-- Check sections
	local sections = {}
	for _, child in ipairs(tower:GetChildren()) do
		if child:IsA("Model") and child.Name:match("Section_") then
			table.insert(sections, child)
		end
	end

	recordTest(string.format("Has sections (%d found)", #sections), #sections > 0, "No sections found")

	-- Validate each section
	for _, section in ipairs(sections) do
		local sectionNumber = tonumber(section.Name:match("Section_(%d+)"))
		if sectionNumber then
			local valid, error = DebugUtilities.ValidateSection(section)
			recordTest(string.format("Section %d valid", sectionNumber), valid, error)
		end
	end

	-- Check finish line
	local hasFinishLine = false
	for _, child in ipairs(tower:GetDescendants()) do
		if child.Name == "FinishLine" then
			hasFinishLine = true
			break
		end
	end

	recordTest("Has finish line", hasFinishLine, "No finish line found")

	return printTestSummary()
end

-- ============================================================================
-- MOVING PLATFORM TESTING
-- ============================================================================

function DebugUtilities.TestMovingPlatforms(tower: Model): boolean
	--[[
		Tests moving platform system.
	--]]

	print("\n[DebugUtilities] Testing moving platforms...")
	resetTestResults()

	if not tower then
		recordTest("Tower exists", false, "Tower is nil")
		return printTestSummary()
	end

	-- Find all moving platforms
	local movingPlatforms = {}
	for _, descendant in ipairs(tower:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsMovingPlatform") then
			table.insert(movingPlatforms, descendant)
		end
	end

	recordTest(string.format("Found moving platforms (%d)", #movingPlatforms), #movingPlatforms > 0)

	-- Validate each moving platform
	for i, platform in ipairs(movingPlatforms) do
		local startPos = platform:GetAttribute("StartPosition")
		local endPos = platform:GetAttribute("EndPosition")
		local speed = platform:GetAttribute("Speed")

		local testName = string.format("Platform %d attributes", i)

		if not startPos then
			recordTest(testName, false, "Missing StartPosition")
		elseif not endPos then
			recordTest(testName, false, "Missing EndPosition")
		elseif not speed or speed <= 0 then
			recordTest(testName, false, string.format("Invalid speed: %s", tostring(speed)))
		else
			recordTest(testName, true)
		end

		-- Check if platform is anchored
		if not platform.Anchored then
			recordTest(string.format("Platform %d anchored", i), false, "Platform not anchored")
		else
			recordTest(string.format("Platform %d anchored", i), true)
		end
	end

	-- Check MovingPlatformService tracking
	local activeCount = MovingPlatformService.GetActivePlatformCount()
	recordTest(
		string.format("MovingPlatformService tracking (%d active)", activeCount),
		activeCount == #movingPlatforms,
		string.format("Expected %d, got %d", #movingPlatforms, activeCount)
	)

	return printTestSummary()
end

-- ============================================================================
-- THEME TESTING
-- ============================================================================

function DebugUtilities.TestThemes(tower: Model): boolean
	--[[
		Tests theme system.
	--]]

	print("\n[DebugUtilities] Testing themes...")
	resetTestResults()

	if not tower then
		recordTest("Tower exists", false, "Tower is nil")
		return printTestSummary()
	end

	-- Check sections have themes
	local themedSections = 0
	local sectionsByTheme = {
		Grasslands = 0,
		Desert = 0,
		Snow = 0,
		Volcano = 0,
	}

	for _, child in ipairs(tower:GetChildren()) do
		if child:IsA("Model") and child.Name:match("Section_") then
			local theme = child:GetAttribute("Theme")
			if theme then
				themedSections = themedSections + 1
				if sectionsByTheme[theme] then
					sectionsByTheme[theme] = sectionsByTheme[theme] + 1
				end
			end
		end
	end

	recordTest(
		string.format("Sections have themes (%d themed)", themedSections),
		themedSections > 0,
		"No sections have Theme attribute"
	)

	-- Validate theme distribution
	for themeName, count in pairs(sectionsByTheme) do
		recordTest(
			string.format("%s theme sections (%d)", themeName, count),
			count > 0
		)
	end

	-- Test theme detection
	for sectionNum = 1, 50 do
		local expectedTheme = ThemeService.GetThemeForSection(sectionNum)
		local validThemes = {Grasslands = true, Desert = true, Snow = true, Volcano = true}

		recordTest(
			string.format("Section %d theme detection", sectionNum),
			validThemes[expectedTheme],
			string.format("Invalid theme: %s", expectedTheme)
		)
	end

	return printTestSummary()
end

-- ============================================================================
-- PERFORMANCE PROFILING
-- ============================================================================

function DebugUtilities.ProfileTowerGeneration(): number
	--[[
		Profiles tower generation performance.
		Returns generation time in seconds.
	--]]

	print("\n[DebugUtilities] Profiling tower generation...")

	local Generator = require(script.Parent.Parent.Services.ObbyService.Generator)

	local startTime = tick()
	local generator = Generator.new(os.time(), "Normal")
	local tower = generator:GenerateTower()
	local endTime = tick()

	local generationTime = endTime - startTime

	print(string.format("Tower generation time: %.3f seconds", generationTime))
	print(string.format("Sections: %d", generator:GetSectionCount()))
	print(string.format("Average time per section: %.4f seconds", generationTime / generator:GetSectionCount()))

	-- Cleanup
	tower:Destroy()

	return generationTime
end

-- ============================================================================
-- STRESS TESTING
-- ============================================================================

function DebugUtilities.StressTest(iterations: number): boolean
	--[[
		Generates multiple towers to test for memory leaks and consistency.
	--]]

	iterations = iterations or 10

	print(string.format("\n[DebugUtilities] Running stress test (%d iterations)...", iterations))
	resetTestResults()

	local Generator = require(script.Parent.Parent.Services.ObbyService.Generator)
	local totalTime = 0

	for i = 1, iterations do
		local startTime = tick()

		local success, error = pcall(function()
			local generator = Generator.new(os.time() + i, "Normal")
			local tower = generator:GenerateTower()

			-- Validate
			local valid = DebugUtilities.ValidateSection(tower:GetChildren()[1])
			if not valid then
				error("Validation failed")
			end

			-- Cleanup
			tower:Destroy()
		end)

		local endTime = tick()
		totalTime = totalTime + (endTime - startTime)

		recordTest(string.format("Iteration %d", i), success, error)

		if i % 5 == 0 then
			print(string.format("Progress: %d/%d (%.1f%%)", i, iterations, i / iterations * 100))
		end
	end

	print(string.format("\nTotal time: %.2f seconds", totalTime))
	print(string.format("Average time: %.3f seconds", totalTime / iterations))

	return printTestSummary()
end

-- ============================================================================
-- DIAGNOSTIC REPORTS
-- ============================================================================

function DebugUtilities.GenerateFullReport(tower: Model?): string
	--[[
		Generates a comprehensive diagnostic report.
	--]]

	local report = {}

	table.insert(report, "=== TOWER ASCENT DIAGNOSTIC REPORT ===")
	table.insert(report, string.format("Generated: %s", os.date()))
	table.insert(report, "")

	-- System status
	table.insert(report, "=== SYSTEM STATUS ===")
	table.insert(report, string.format("SectionLoader templates: %d", SectionLoader.GetTemplateCount()))
	table.insert(report, string.format("  - Easy: %d", SectionLoader.GetTemplateCount("Easy")))
	table.insert(report, string.format("  - Medium: %d", SectionLoader.GetTemplateCount("Medium")))
	table.insert(report, string.format("  - Hard: %d", SectionLoader.GetTemplateCount("Hard")))
	table.insert(report, string.format("  - Expert: %d", SectionLoader.GetTemplateCount("Expert")))
	table.insert(report, "")

	if tower then
		table.insert(report, "=== TOWER STATUS ===")
		table.insert(report, string.format("Name: %s", tower.Name))
		table.insert(report, string.format("Seed: %s", tostring(tower:GetAttribute("Seed"))))
		table.insert(report, string.format("Parent: %s", tostring(tower.Parent)))

		-- Count sections
		local sectionCount = 0
		for _, child in ipairs(tower:GetChildren()) do
			if child:IsA("Model") and child.Name:match("Section_") then
				sectionCount = sectionCount + 1
			end
		end
		table.insert(report, string.format("Sections: %d", sectionCount))

		-- Count moving platforms
		local movingPlatformCount = 0
		for _, descendant in ipairs(tower:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("IsMovingPlatform") then
				movingPlatformCount = movingPlatformCount + 1
			end
		end
		table.insert(report, string.format("Moving platforms: %d", movingPlatformCount))

		table.insert(report, "")
	end

	-- Moving platform service status
	table.insert(report, "=== MOVING PLATFORM SERVICE ===")
	table.insert(report, string.format("Active platforms: %d", MovingPlatformService.GetActivePlatformCount()))
	table.insert(report, "")

	-- Theme service status
	table.insert(report, "=== THEME SERVICE ===")
	table.insert(report, string.format("Current theme: %s", tostring(ThemeService.GetCurrentTheme())))
	table.insert(report, "")

	table.insert(report, "=== END REPORT ===")

	local fullReport = table.concat(report, "\n")
	print(fullReport)

	return fullReport
end

-- ============================================================================
-- QUICK FIX UTILITIES
-- ============================================================================

function DebugUtilities.RebuildAllTemplates(): boolean
	--[[
		Rebuilds all section templates.
		Useful if templates are corrupted.
	--]]

	print("\n[DebugUtilities] Rebuilding all templates...")

	local tiers = {"Easy", "Medium", "Hard", "Expert"}
	local success = true

	for _, tier in ipairs(tiers) do
		local tierSuccess = SectionLoader.RebuildTier(tier)
		if not tierSuccess then
			success = false
			warn(string.format("Failed to rebuild %s tier", tier))
		end
	end

	if success then
		print("All templates rebuilt successfully!")
	else
		warn("Some templates failed to rebuild")
	end

	return success
end

-- ============================================================================
-- WEEK 11: HAZARD TESTING
-- ============================================================================

function DebugUtilities.TestHazards(tower: Model): boolean
	--[[
		Tests hazard system (Week 9).
		WEEK 11: Comprehensive hazard validation
	--]]

	print("\n[DebugUtilities] Testing hazards...")
	resetTestResults()

	-- Lazy load HazardService
	if not HazardService then
		HazardService = _G.TowerAscent and _G.TowerAscent.HazardService
		if not HazardService then
			recordTest("HazardService loaded", false, "HazardService not found in _G.TowerAscent")
			return printTestSummary()
		end
	end

	recordTest("HazardService loaded", true)

	if not tower then
		recordTest("Tower exists", false, "Tower is nil")
		return printTestSummary()
	end

	-- Find all hazards
	local hazardsByType = {
		Lava = {},
		Spikes = {},
		Ice = {},
		WindZone = {},
		Quicksand = {},
		RotatingObstacle = {},
		PoisonGas = {},
		FallingPlatform = {},
	}

	local totalHazards = 0

	for _, descendant in ipairs(tower:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local hazardType = descendant:GetAttribute("HazardType")
			if hazardType and hazardsByType[hazardType] then
				table.insert(hazardsByType[hazardType], descendant)
				totalHazards = totalHazards + 1
			end
		end
	end

	recordTest(
		string.format("Total hazards found (%d)", totalHazards),
		totalHazards > 0,
		"No hazards found in tower"
	)

	-- Test each hazard type
	for hazardType, hazards in pairs(hazardsByType) do
		local count = #hazards
		recordTest(
			string.format("%s hazards (%d found)", hazardType, count),
			true -- Just record count, not pass/fail
		)

		-- Validate each hazard instance
		for i, hazard in ipairs(hazards) do
			local testName = string.format("%s #%d attributes", hazardType, i)

			-- Check required attributes based on type
			if hazardType == "Lava" then
				recordTest(testName, hazard:GetAttribute("Damage") ~= nil)
			elseif hazardType == "Spikes" then
				local damage = hazard:GetAttribute("Damage")
				recordTest(testName, damage == 40, string.format("Expected 40 damage, got %s", tostring(damage)))
			elseif hazardType == "Ice" then
				local friction = hazard:GetAttribute("FrictionMultiplier")
				recordTest(testName, friction ~= nil, "Missing FrictionMultiplier")
			elseif hazardType == "WindZone" then
				local direction = hazard:GetAttribute("WindDirection")
				local force = hazard:GetAttribute("WindForce")
				recordTest(testName, direction ~= nil and force ~= nil, "Missing wind attributes")
			elseif hazardType == "Quicksand" then
				local slowdown = hazard:GetAttribute("SpeedMultiplier")
				recordTest(testName, slowdown ~= nil, "Missing SpeedMultiplier")
			elseif hazardType == "RotatingObstacle" then
				local speed = hazard:GetAttribute("RotationSpeed")
				recordTest(testName, speed ~= nil, "Missing RotationSpeed")
			elseif hazardType == "PoisonGas" then
				local dps = hazard:GetAttribute("DamagePerSecond")
				recordTest(testName, dps == 10, string.format("Expected 10 DPS, got %s", tostring(dps)))
			elseif hazardType == "FallingPlatform" then
				local collapseTime = hazard:GetAttribute("CollapseTime")
				recordTest(testName, collapseTime ~= nil, "Missing CollapseTime")
			end
		end
	end

	-- Expected hazard counts (from Week 9 implementation)
	local expectedCounts = {
		Lava = 6,
		Spikes = 8,
		Ice = 6,
		WindZone = 5,
		Quicksand = 3,
		RotatingObstacle = 4,
		PoisonGas = 3,
		FallingPlatform = 5,
	}

	-- Validate counts match expectations
	for hazardType, expected in pairs(expectedCounts) do
		local actual = #hazardsByType[hazardType]
		recordTest(
			string.format("%s count validation (expected %d)", hazardType, expected),
			actual == expected,
			string.format("Expected %d, found %d", expected, actual)
		)
	end

	return printTestSummary()
end

-- ============================================================================
-- WEEK 11: WEATHER TESTING
-- ============================================================================

function DebugUtilities.TestWeather(): boolean
	--[[
		Tests weather system (Week 10).
		WEEK 11: Comprehensive weather validation
	--]]

	print("\n[DebugUtilities] Testing weather system...")
	resetTestResults()

	-- Lazy load WeatherService
	if not WeatherService then
		WeatherService = _G.TowerAscent and _G.TowerAscent.WeatherService
		if not WeatherService then
			recordTest("WeatherService loaded", false, "WeatherService not found in _G.TowerAscent")
			return printTestSummary()
		end
	end

	recordTest("WeatherService loaded", true)

	-- Test weather type definitions
	local weatherTypes = {"Clear", "Sandstorm", "Blizzard", "VolcanicAsh"}

	for _, weatherType in ipairs(weatherTypes) do
		-- Test SetWeather function
		local success, error = pcall(function()
			WeatherService.SetWeather(weatherType)
		end)

		recordTest(
			string.format("Set weather: %s", weatherType),
			success,
			error
		)

		-- Verify active weather
		if success then
			local activeWeather = WeatherService.ActiveWeather
			recordTest(
				string.format("Active weather is %s", weatherType),
				activeWeather == weatherType,
				string.format("Expected %s, got %s", weatherType, activeWeather)
			)
		end

		task.wait(0.5) -- Brief delay between tests
	end

	-- Test theme-to-weather mapping
	local themeToWeather = {
		Grasslands = "Clear",
		Desert = "Sandstorm",
		Snow = "Blizzard",
		Volcano = "VolcanicAsh",
	}

	for theme, expectedWeather in pairs(themeToWeather) do
		local success, error = pcall(function()
			WeatherService.SetWeatherByTheme(theme)
		end)

		recordTest(
			string.format("Theme %s → Weather", theme),
			success,
			error
		)

		if success then
			local activeWeather = WeatherService.ActiveWeather
			recordTest(
				string.format("Theme %s maps to %s", theme, expectedWeather),
				activeWeather == expectedWeather,
				string.format("Expected %s, got %s", expectedWeather, activeWeather)
			)
		end

		task.wait(0.5)
	end

	-- Test weather event trigger
	WeatherService.SetWeather("Sandstorm") -- Set to event-enabled weather
	task.wait(0.5)

	local success, error = pcall(function()
		WeatherService.TriggerWeatherEvent()
	end)

	recordTest("Trigger weather event", success, error)

	-- Test GetStatus function
	local success2, status = pcall(function()
		return WeatherService.GetStatus()
	end)

	recordTest("GetStatus function", success2)

	if success2 and status then
		recordTest("Status has ActiveWeather", status.ActiveWeather ~= nil)
		recordTest("Status has IntensityLevel", status.IntensityLevel ~= nil)
		recordTest("Status has EventCooldown", status.EventCooldown ~= nil)
		recordTest("Status has HasEvents", status.HasEvents ~= nil)
	end

	return printTestSummary()
end

-- ============================================================================
-- WEEK 11: COMPREHENSIVE SYSTEM TEST
-- ============================================================================

function DebugUtilities.RunComprehensiveTests(tower: Model?): boolean
	--[[
		Runs ALL tests in sequence.
		WEEK 11: Complete system validation
	--]]

	print("\n" .. string.rep("=", 80))
	print("COMPREHENSIVE SYSTEM TEST - WEEK 11")
	print(string.rep("=", 80))

	local allPassed = true

	-- 1. Section template tests
	print("\n[1/6] Testing section templates...")
	if not DebugUtilities.TestAllSections() then
		allPassed = false
	end

	-- 2. Tower validation (if tower provided)
	if tower then
		print("\n[2/6] Validating tower...")
		if not DebugUtilities.ValidateTower(tower) then
			allPassed = false
		end
	else
		print("\n[2/6] Skipping tower validation (no tower provided)")
	end

	-- 3. Moving platform tests
	if tower then
		print("\n[3/6] Testing moving platforms...")
		if not DebugUtilities.TestMovingPlatforms(tower) then
			allPassed = false
		end
	else
		print("\n[3/6] Skipping moving platform tests (no tower provided)")
	end

	-- 4. Theme tests
	if tower then
		print("\n[4/6] Testing themes...")
		if not DebugUtilities.TestThemes(tower) then
			allPassed = false
		end
	else
		print("\n[4/6] Skipping theme tests (no tower provided)")
	end

	-- 5. Hazard tests (WEEK 11)
	if tower then
		print("\n[5/6] Testing hazards...")
		if not DebugUtilities.TestHazards(tower) then
			allPassed = false
		end
	else
		print("\n[5/6] Skipping hazard tests (no tower provided)")
	end

	-- 6. Weather tests (WEEK 11)
	print("\n[6/6] Testing weather system...")
	if not DebugUtilities.TestWeather() then
		allPassed = false
	end

	-- Final summary
	print("\n" .. string.rep("=", 80))
	if allPassed then
		print("✅ ALL TESTS PASSED - PRODUCTION READY")
	else
		print("❌ SOME TESTS FAILED - REVIEW ERRORS ABOVE")
	end
	print(string.rep("=", 80) .. "\n")

	return allPassed
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return DebugUtilities
