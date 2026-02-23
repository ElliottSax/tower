--[[
    Tower Ascent - Debug Mode Protection Test
    Fix #1: Validates debug mode is disabled in production
    Test Cases: TA-F1-1, TA-F1-2, TA-F1-3
]]

local TestRunner = {}

function TestRunner.TestDebugModeDisabledInProduction()
    print("=== TA-F1-1: Debug Mode Disabled in Production ===")

    -- Check if running in Studio or Production
    local RunService = game:GetService("RunService")
    local isStudio = RunService:IsStudio()

    if isStudio then
        warn("[SKIP] Test requires production environment (test server)")
        return "SKIPPED"
    end

    -- Check _G.TowerAscent should be nil in production
    if _G.TowerAscent == nil then
        print("✅ PASS: _G.TowerAscent is nil (debug mode disabled)")
        return "PASS"
    else
        print("❌ FAIL: _G.TowerAscent exists in production (SECURITY RISK)")
        return "FAIL"
    end
end

function TestRunner.TestDebugModeEnabledInStudio()
    print("=== TA-F1-2: Debug Mode Enabled in Studio ===")

    local RunService = game:GetService("RunService")
    local isStudio = RunService:IsStudio()

    if not isStudio then
        warn("[SKIP] Test requires Studio environment")
        return "SKIPPED"
    end

    -- Check GameConfig.Debug.Enabled
    local success, GameConfig = pcall(function()
        return require(game.ReplicatedStorage.Shared.Config.GameConfig)
    end)

    if not success then
        print("❌ FAIL: Could not load GameConfig:", GameConfig)
        return "FAIL"
    end

    if GameConfig.Debug and GameConfig.Debug.Enabled == true then
        print("✅ PASS: Debug mode enabled in Studio")

        -- Check if _G.TowerAscent exists
        if _G.TowerAscent and type(_G.TowerAscent) == "table" then
            print("✅ PASS: _G.TowerAscent table exists")
            print("  Services exposed:", table.concat(vim.tbl_keys(_G.TowerAscent or {}), ", "))
            return "PASS"
        else
            print("❌ FAIL: _G.TowerAscent should exist in debug mode")
            return "FAIL"
        end
    else
        print("⚠️  WARN: Debug mode disabled in Studio (may be intentional)")
        return "WARN"
    end
end

function TestRunner.TestWebhookAlertFires()
    print("=== TA-F1-3: Webhook Alert Fires ===")
    print("⚠️  MANUAL TEST: Temporarily enable debug in production")
    print("  1. Set GameConfig.Debug.Enabled = true")
    print("  2. Publish to test server")
    print("  3. Start server")
    print("  4. Check Discord/Slack webhook")
    print("  Expected: Security alert about debug mode in production")
    return "MANUAL"
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Tower Ascent - Debug Mode Protection Tests      ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 3,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestDebugModeDisabledInProduction()
    if result1 == "PASS" then results.Passed = results.Passed + 1
    elseif result1 == "FAIL" then results.Failed = results.Failed + 1
    elseif result1 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 2
    local result2 = TestRunner.TestDebugModeEnabledInStudio()
    if result2 == "PASS" then results.Passed = results.Passed + 1
    elseif result2 == "FAIL" then results.Failed = results.Failed + 1
    elseif result2 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 3
    local result3 = TestRunner.TestWebhookAlertFires()
    if result3 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Test Results Summary                             ║")
    print("╚═══════════════════════════════════════════════════╝")
    print(string.format("Total:   %d", results.Total))
    print(string.format("✅ Passed: %d", results.Passed))
    print(string.format("❌ Failed: %d", results.Failed))
    print(string.format("⏭️  Skipped: %d", results.Skipped))
    print(string.format("✋ Manual: %d", results.Manual))

    return results
end

-- Auto-run if executed directly
if not _G.TestFramework then
    TestRunner.RunAllTests()
end

return TestRunner
