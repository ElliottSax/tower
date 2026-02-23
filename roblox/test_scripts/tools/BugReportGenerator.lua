--[[
    Bug Report Generator - Automated bug report creation
    Generates structured bug reports from test failures
    Usage: Call after test failures to document bugs
]]

local BugReportGenerator = {}

-- Bug severity levels
local SEVERITY = {
    P0 = {Name = "P0 - Critical", Color = "RED", Description = "Blocks launch, data loss, exploits"},
    P1 = {Name = "P1 - High", Color = "ORANGE", Description = "Major feature broken, bad UX"},
    P2 = {Name = "P2 - Medium", Color = "YELLOW", Description = "Minor bug, edge case"},
    P3 = {Name = "P3 - Low", Color = "GREEN", Description = "Cosmetic, nice-to-have"}
}

-- Bug report template
local function createBugReport(data)
    local report = {
        "# Bug Report",
        "",
        string.format("**Bug ID:** BUG-%s-%d", data.Game, os.time()),
        string.format("**Title:** [%s] - %s - %s", data.Game, data.Severity, data.Title),
        string.format("**Severity:** %s", data.Severity),
        string.format("**Status:** New"),
        string.format("**Created:** %s", os.date("%Y-%m-%d %H:%M:%S")),
        "",
        "## Description",
        data.Description or "No description provided",
        "",
        "## Steps to Reproduce",
    }

    for i, step in ipairs(data.Steps or {}) do
        table.insert(report, string.format("%d. %s", i, step))
    end

    table.insert(report, "")
    table.insert(report, "## Expected Behavior")
    table.insert(report, data.Expected or "No expected behavior specified")
    table.insert(report, "")
    table.insert(report, "## Actual Behavior")
    table.insert(report, data.Actual or "No actual behavior specified")
    table.insert(report, "")
    table.insert(report, "## Impact")
    table.insert(report, data.Impact or "Impact not assessed")
    table.insert(report, "")

    if data.Screenshots then
        table.insert(report, "## Screenshots")
        for _, screenshot in ipairs(data.Screenshots) do
            table.insert(report, string.format("- %s", screenshot))
        end
        table.insert(report, "")
    end

    table.insert(report, "## Environment")
    table.insert(report, string.format("- **Game:** %s", data.Game))
    table.insert(report, string.format("- **Test Case:** %s", data.TestCase or "N/A"))
    table.insert(report, string.format("- **Platform:** %s", data.Platform or "Unknown"))
    table.insert(report, string.format("- **Roblox Version:** %s", data.RobloxVersion or "Unknown"))
    table.insert(report, string.format("- **Test Server:** %s", data.TestServer and "Yes" or "Studio"))
    table.insert(report, "")

    if data.RelatedFix then
        table.insert(report, "## Related Fix")
        table.insert(report, string.format("Related to: %s", data.RelatedFix))
        table.insert(report, "")
    end

    if data.Logs then
        table.insert(report, "## Server Logs")
        table.insert(report, "```")
        table.insert(report, data.Logs)
        table.insert(report, "```")
        table.insert(report, "")
    end

    table.insert(report, "## Priority Assessment")
    local severityInfo = SEVERITY[data.Severity]
    if severityInfo then
        table.insert(report, string.format("**%s:** %s", severityInfo.Name, severityInfo.Description))
    end
    table.insert(report, "")

    table.insert(report, "---")
    table.insert(report, "**Reported By:** Claude Code (Automated Test)")
    table.insert(report, string.format("**Session:** Week 1 Testing Phase"))

    return table.concat(report, "\n")
end

--[[
    Generate bug report from test failure
]]
function BugReportGenerator.FromTestFailure(testCase, game, failure)
    local bugData = {
        Game = game,
        Title = failure.Title or string.format("%s Test Failed", testCase),
        Severity = failure.Severity or "P1",
        Description = failure.Description or string.format("Test case %s failed during automated testing", testCase),
        Steps = failure.Steps or {
            string.format("Run test: %s", testCase),
            "Observe failure"
        },
        Expected = failure.Expected or "Test should pass",
        Actual = failure.Actual or "Test failed",
        Impact = failure.Impact or "Feature may not work as intended",
        TestCase = testCase,
        Platform = "Roblox Studio",
        RobloxVersion = "Latest",
        TestServer = false,
        RelatedFix = failure.RelatedFix,
        Logs = failure.Logs
    }

    local report = createBugReport(bugData)
    return report
end

--[[
    Interactive bug report creation
]]
function BugReportGenerator.CreateInteractive()
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║   Interactive Bug Report Generator                            ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("")
    print("This function requires user input.")
    print("Use BugReportGenerator.FromTestFailure() for automated reports.")
    print("")

    -- Example usage
    local exampleBug = {
        Game = "Tower Ascent",
        Title = "VIP multiplier not working",
        Severity = "P1",
        Description = "VIP players are not receiving 2x coin multiplier",
        Steps = {
            "Join as VIP player",
            "Collect 100 coins",
            "Check coin balance"
        },
        Expected = "200 coins added (2x multiplier)",
        Actual = "100 coins added (1x multiplier)",
        Impact = "VIP players not getting purchased benefits",
        TestCase = "TA-F3-1",
        Platform = "Roblox Studio",
        RobloxVersion = "2.621.123",
        TestServer = true,
        RelatedFix = "Fix #3: VIP Race Condition",
        Logs = "[VIPService] IsVIP=true, Multiplier=1.0 (should be 2.0)"
    }

    local report = createBugReport(exampleBug)

    print("=== EXAMPLE BUG REPORT ===")
    print(report)
    print("=== END EXAMPLE ===")
    print("")
    print("To create your own report, call:")
    print("  BugReportGenerator.FromTestFailure(testCase, game, failureData)")
end

--[[
    Export bug report to file (markdown format)
]]
function BugReportGenerator.ExportReport(report, filename)
    filename = filename or string.format("BUG-%d.md", os.time())

    print(string.format("[BugReportGen] Generated report: %s", filename))
    print(string.format("[BugReportGen] Copy the report below to: roblox/bugs/%s", filename))
    print("")
    print(report)
    print("")

    return filename
end

--[[
    Batch create bug reports from multiple test failures
]]
function BugReportGenerator.BatchCreate(failures)
    print(string.format("[BugReportGen] Creating %d bug reports...", #failures))

    local reports = {}

    for i, failure in ipairs(failures) do
        local report = BugReportGenerator.FromTestFailure(
            failure.TestCase,
            failure.Game,
            failure
        )

        table.insert(reports, {
            Filename = string.format("BUG-%s-%d-%d.md", failure.Game, os.time(), i),
            Content = report
        })
    end

    print(string.format("[BugReportGen] ✅ Created %d bug reports", #reports))

    return reports
end

--[[
    Print bug summary for tracking
]]
function BugReportGenerator.PrintSummary(bugs)
    print("\n╔═══════════════════════════════════════════════════════════════╗")
    print("║   Bug Summary Report                                          ║")
    print("╚═══════════════════════════════════════════════════════════════╝\n")

    local byGame = {}
    local bySeverity = {P0 = 0, P1 = 0, P2 = 0, P3 = 0}

    for _, bug in ipairs(bugs) do
        -- Count by game
        byGame[bug.Game] = (byGame[bug.Game] or 0) + 1

        -- Count by severity
        bySeverity[bug.Severity] = (bySeverity[bug.Severity] or 0) + 1
    end

    print(string.format("Total Bugs: %d\n", #bugs))

    print("By Severity:")
    for severity, count in pairs(bySeverity) do
        if count > 0 then
            local info = SEVERITY[severity]
            print(string.format("  %s: %d", info.Name, count))
        end
    end

    print("\nBy Game:")
    for game, count in pairs(byGame) do
        print(string.format("  %s: %d", game, count))
    end

    print("\n")
end

-- Example usage print
print("[BugReportGen] Bug Report Generator loaded")
print("Usage: BugReportGenerator.FromTestFailure(testCase, game, failureData)")
print("Example: BugReportGenerator.CreateInteractive()")

return BugReportGenerator
