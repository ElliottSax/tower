--[[
    Test Result Logger - Automated test result tracking and reporting
    Logs all test executions, results, and generates summary reports
    Usage: Integrate with test runners to automatically log results
]]

local TestResultLogger = {}

-- Test session storage
local Session = {
    StartTime = os.time(),
    Tests = {},
    Summary = {
        Total = 0,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }
}

--[[
    Log a test result
]]
function TestResultLogger.LogResult(testData)
    local result = {
        Timestamp = os.time(),
        TestID = testData.TestID,
        Game = testData.Game,
        Fix = testData.Fix,
        Description = testData.Description,
        Status = testData.Status,  -- PASS, FAIL, SKIPPED, MANUAL
        Expected = testData.Expected,
        Actual = testData.Actual,
        Duration = testData.Duration or 0,
        Notes = testData.Notes,
        Error = testData.Error
    }

    table.insert(Session.Tests, result)

    -- Update summary
    Session.Summary.Total = Session.Summary.Total + 1
    if result.Status == "PASS" then
        Session.Summary.Passed = Session.Summary.Passed + 1
    elseif result.Status == "FAIL" then
        Session.Summary.Failed = Session.Summary.Failed + 1
    elseif result.Status == "SKIPPED" then
        Session.Summary.Skipped = Session.Summary.Skipped + 1
    elseif result.Status == "MANUAL" then
        Session.Summary.Manual = Session.Summary.Manual + 1
    end

    -- Print result
    local statusSymbol = {
        PASS = "✅",
        FAIL = "❌",
        SKIPPED = "⏭️",
        MANUAL = "✋"
    }

    print(string.format("[TestLog] %s %s - %s",
        statusSymbol[result.Status] or "?",
        result.TestID,
        result.Description))

    if result.Status == "FAIL" and result.Error then
        warn(string.format("  Error: %s", result.Error))
    end

    return result
end

--[[
    Log test suite execution
]]
function TestResultLogger.LogSuite(suiteName, results)
    print(string.format("\n[TestLog] Suite: %s", suiteName))

    for _, result in ipairs(results) do
        TestResultLogger.LogResult(result)
    end

    local suiteTotal = #results
    local suitePassed = 0
    for _, result in ipairs(results) do
        if result.Status == "PASS" then
            suitePassed = suitePassed + 1
        end
    end

    print(string.format("[TestLog] Suite complete: %d/%d passed (%.1f%%)\n",
        suitePassed, suiteTotal, (suitePassed / suiteTotal) * 100))
end

--[[
    Get current session summary
]]
function TestResultLogger.GetSummary()
    local duration = os.time() - Session.StartTime

    return {
        Duration = duration,
        Tests = Session.Summary.Total,
        Passed = Session.Summary.Passed,
        Failed = Session.Summary.Failed,
        Skipped = Session.Summary.Skipped,
        Manual = Session.Summary.Manual,
        PassRate = Session.Summary.Total > 0
            and (Session.Summary.Passed / Session.Summary.Total) * 100
            or 0
    }
end

--[[
    Print session summary
]]
function TestResultLogger.PrintSummary()
    local summary = TestResultLogger.GetSummary()

    print("\n╔═══════════════════════════════════════════════════════════════╗")
    print("║   Test Session Summary                                        ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(string.format("Duration: %d minutes", math.floor(summary.Duration / 60)))
    print(string.format("Total Tests: %d", summary.Tests))
    print(string.format("✅ Passed: %d (%.1f%%)", summary.Passed, summary.PassRate))
    print(string.format("❌ Failed: %d", summary.Failed))
    print(string.format("⏭️  Skipped: %d", summary.Skipped))
    print(string.format("✋ Manual: %d", summary.Manual))

    if summary.Failed > 0 then
        print("\n⚠️  FAILURES DETECTED:")
        for _, result in ipairs(Session.Tests) do
            if result.Status == "FAIL" then
                print(string.format("  - %s: %s", result.TestID, result.Description))
                if result.Error then
                    print(string.format("    Error: %s", result.Error))
                end
            end
        end
    end

    print("╚═══════════════════════════════════════════════════════════════╝\n")
end

--[[
    Export results to markdown format
]]
function TestResultLogger.ExportMarkdown()
    local lines = {
        "# Test Results Report",
        "",
        string.format("**Date:** %s", os.date("%Y-%m-%d %H:%M:%S")),
        string.format("**Duration:** %d minutes", math.floor((os.time() - Session.StartTime) / 60)),
        ""
    }

    local summary = TestResultLogger.GetSummary()

    table.insert(lines, "## Summary")
    table.insert(lines, "")
    table.insert(lines, string.format("- **Total Tests:** %d", summary.Tests))
    table.insert(lines, string.format("- **Passed:** %d (%.1f%%)", summary.Passed, summary.PassRate))
    table.insert(lines, string.format("- **Failed:** %d", summary.Failed))
    table.insert(lines, string.format("- **Skipped:** %d", summary.Skipped))
    table.insert(lines, string.format("- **Manual:** %d", summary.Manual))
    table.insert(lines, "")

    table.insert(lines, "## Test Results")
    table.insert(lines, "")
    table.insert(lines, "| Test ID | Game | Description | Status |")
    table.insert(lines, "|---------|------|-------------|--------|")

    for _, result in ipairs(Session.Tests) do
        local statusEmoji = {
            PASS = "✅",
            FAIL = "❌",
            SKIPPED = "⏭️",
            MANUAL = "✋"
        }

        table.insert(lines, string.format("| %s | %s | %s | %s %s |",
            result.TestID,
            result.Game or "N/A",
            result.Description,
            statusEmoji[result.Status] or "?",
            result.Status))
    end

    table.insert(lines, "")
    table.insert(lines, "## Failures")
    table.insert(lines, "")

    local hasFailures = false
    for _, result in ipairs(Session.Tests) do
        if result.Status == "FAIL" then
            hasFailures = true
            table.insert(lines, string.format("### %s - %s", result.TestID, result.Description))
            table.insert(lines, "")
            table.insert(lines, string.format("**Expected:** %s", result.Expected or "N/A"))
            table.insert(lines, string.format("**Actual:** %s", result.Actual or "N/A"))
            if result.Error then
                table.insert(lines, string.format("**Error:** %s", result.Error))
            end
            table.insert(lines, "")
        end
    end

    if not hasFailures then
        table.insert(lines, "*No failures*")
        table.insert(lines, "")
    end

    table.insert(lines, "---")
    table.insert(lines, "Generated by Claude Code Test Result Logger")

    return table.concat(lines, "\n")
end

--[[
    Export results to JSON format
]]
function TestResultLogger.ExportJSON()
    local HttpService = game:GetService("HttpService")

    local export = {
        StartTime = Session.StartTime,
        EndTime = os.time(),
        Duration = os.time() - Session.StartTime,
        Summary = Session.Summary,
        Tests = Session.Tests
    }

    return HttpService:JSONEncode(export)
end

--[[
    Reset session (start new test run)
]]
function TestResultLogger.ResetSession()
    Session = {
        StartTime = os.time(),
        Tests = {},
        Summary = {
            Total = 0,
            Passed = 0,
            Failed = 0,
            Skipped = 0,
            Manual = 0
        }
    }

    print("[TestLog] Session reset - starting new test run")
end

--[[
    Get failed tests
]]
function TestResultLogger.GetFailedTests()
    local failed = {}

    for _, result in ipairs(Session.Tests) do
        if result.Status == "FAIL" then
            table.insert(failed, result)
        end
    end

    return failed
end

--[[
    Get pass rate by game
]]
function TestResultLogger.GetPassRateByGame()
    local byGame = {}

    for _, result in ipairs(Session.Tests) do
        local game = result.Game or "Unknown"

        if not byGame[game] then
            byGame[game] = {Total = 0, Passed = 0}
        end

        byGame[game].Total = byGame[game].Total + 1
        if result.Status == "PASS" then
            byGame[game].Passed = byGame[game].Passed + 1
        end
    end

    -- Calculate pass rates
    for game, stats in pairs(byGame) do
        stats.PassRate = (stats.Passed / stats.Total) * 100
    end

    return byGame
end

--[[
    Print detailed report
]]
function TestResultLogger.PrintDetailedReport()
    print("\n╔═══════════════════════════════════════════════════════════════╗")
    print("║   Detailed Test Results Report                                ║")
    print("╚═══════════════════════════════════════════════════════════════╝\n")

    -- Overall summary
    TestResultLogger.PrintSummary()

    -- Pass rate by game
    print("\nPass Rate by Game:")
    local byGame = TestResultLogger.GetPassRateByGame()
    for game, stats in pairs(byGame) do
        print(string.format("  %s: %d/%d (%.1f%%)",
            game, stats.Passed, stats.Total, stats.PassRate))
    end

    -- Export options
    print("\n╔═══════════════════════════════════════════════════════════════╗")
    print("║   Export Options                                              ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("To export results:")
    print("  Markdown: TestResultLogger.ExportMarkdown()")
    print("  JSON: TestResultLogger.ExportJSON()")
    print("")
end

-- Initialize
print("[TestLog] Test Result Logger initialized")
print("[TestLog] Session started at:", os.date("%Y-%m-%d %H:%M:%S", Session.StartTime))

return TestResultLogger
