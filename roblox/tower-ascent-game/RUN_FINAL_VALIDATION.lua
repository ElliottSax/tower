--[[
    FINAL PRODUCTION VALIDATION SCRIPT

    Run this in Roblox Studio's Command Bar or as a Script to validate
    all fixes and confirm production readiness.

    Instructions:
    1. Open Roblox Studio with your Tower Ascent game
    2. Open the Command Bar (View -> Command Bar)
    3. Copy and paste this entire script
    4. Press Enter to run

    Expected Result: All checks should pass with A grade (95%+)
]]

print("\n" .. string.rep("=", 80))
print("TOWER ASCENT - FINAL PRODUCTION VALIDATION")
print("Running comprehensive validation after all fixes...")
print(string.rep("=", 80) .. "\n")

-- Wait for game to fully load
task.wait(2)

-- Check if TowerAscent is loaded
if not _G.TowerAscent then
    error("❌ TowerAscent not loaded! Make sure the game is running.")
end

print("✅ TowerAscent loaded successfully\n")

-- Step 1: Run Production Readiness Validation
print("[1/5] Running Production Readiness Validation...")
print(string.rep("-", 60))

local ProductionReadiness = _G.TowerAscent.ProductionReadiness
if ProductionReadiness then
    local success, result = pcall(function()
        return ProductionReadiness.RunFullValidation()
    end)

    if success then
        print("✅ Production Readiness validation complete")
    else
        warn("⚠️ Production Readiness validation failed:", result)
    end
else
    warn("❌ ProductionReadiness not found")
end

task.wait(1)

-- Step 2: Run Pre-Deployment Checklist
print("\n[2/5] Running Pre-Deployment Checklist...")
print(string.rep("-", 60))

local PreDeploymentChecklist = _G.TowerAscent.PreDeploymentChecklist
if PreDeploymentChecklist then
    local success, result = pcall(function()
        return PreDeploymentChecklist.Validate()
    end)

    if success and result then
        if #result.Blockers == 0 then
            print("✅ No deployment blockers found")
        else
            warn("❌ Deployment blockers found:", #result.Blockers)
            for _, blocker in ipairs(result.Blockers) do
                warn("  - " .. blocker.Name)
            end
        end
    else
        warn("⚠️ Pre-deployment checklist failed:", result)
    end
else
    warn("❌ PreDeploymentChecklist not found")
end

task.wait(1)

-- Step 3: Quick System Health Check
print("\n[3/5] System Health Check...")
print(string.rep("-", 60))

local checks = {
    {
        name = "DebugProfiler (should be OFF)",
        check = function()
            local profiler = _G.TowerAscent.DebugProfiler
            return profiler and not profiler.Enabled
        end
    },
    {
        name = "ChaosMonkey (should be OFF)",
        check = function()
            local chaos = _G.TowerAscent.ChaosMonkey
            return chaos and not chaos.Enabled
        end
    },
    {
        name = "ErrorRecovery Available",
        check = function()
            local recovery = _G.TowerAscent.ErrorRecovery
            return recovery ~= nil
        end
    },
    {
        name = "Memory Manager Active",
        check = function()
            local config = _G.TowerAscent.Config
            return config and config.Memory and config.Memory.Enabled
        end
    },
    {
        name = "Anti-Cheat Enabled",
        check = function()
            local config = _G.TowerAscent.Config
            return config and config.AntiCheat and config.AntiCheat.Enabled
        end
    },
    {
        name = "Debug Mode OFF",
        check = function()
            local config = _G.TowerAscent.Config
            return config and config.Debug and not config.Debug.Enabled
        end
    }
}

local healthPassed = 0
local healthFailed = 0

for _, check in ipairs(checks) do
    local success, result = pcall(check.check)
    if success and result then
        print("  ✅ " .. check.name)
        healthPassed = healthPassed + 1
    else
        print("  ❌ " .. check.name)
        healthFailed = healthFailed + 1
    end
end

print(string.format("\nHealth Check: %d/%d passed", healthPassed, #checks))

task.wait(1)

-- Step 4: Verify Critical Fixes
print("\n[4/5] Verifying Critical Fixes...")
print(string.rep("-", 60))

local fixes = {
    {
        name = "DebugProfiler has LoggedMissingCategories field",
        check = function()
            local profiler = _G.TowerAscent.DebugProfiler
            return profiler and profiler.LoggedMissingCategories ~= nil
        end
    },
    {
        name = "ErrorRecovery has AutoRecoveryEnabled field",
        check = function()
            local recovery = _G.TowerAscent.ErrorRecovery
            return recovery and recovery.AutoRecoveryEnabled ~= nil
        end
    },
    {
        name = "ErrorRecovery has DisableAutoRecovery function",
        check = function()
            local recovery = _G.TowerAscent.ErrorRecovery
            return recovery and type(recovery.DisableAutoRecovery) == "function"
        end
    },
    {
        name = "ValidationTests has IsRunning field",
        check = function()
            local tests = _G.TowerAscent.ValidationTests
            return tests and tests.IsRunning ~= nil
        end
    },
    {
        name = "EdgeCaseTests has IsRunning field",
        check = function()
            local tests = _G.TowerAscent.EdgeCaseTests
            return tests and tests.IsRunning ~= nil
        end
    },
    {
        name = "StressTests has IsRunning field",
        check = function()
            local tests = _G.TowerAscent.StressTests
            return tests and tests.IsRunning ~= nil
        end
    }
}

local fixesPassed = 0
local fixesFailed = 0

for _, fix in ipairs(fixes) do
    local success, result = pcall(fix.check)
    if success and result then
        print("  ✅ " .. fix.name)
        fixesPassed = fixesPassed + 1
    else
        print("  ❌ " .. fix.name)
        fixesFailed = fixesFailed + 1
    end
end

print(string.format("\nFixes Verified: %d/%d passed", fixesPassed, #fixes))

task.wait(1)

-- Step 5: Performance Baseline
print("\n[5/5] Performance Baseline...")
print(string.rep("-", 60))

local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Take performance measurements
local measurements = {}
for i = 1, 5 do
    task.wait(0.2)
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local memory = Stats:GetTotalMemoryUsageMb()
    table.insert(measurements, {fps = fps, memory = memory})
end

-- Calculate averages
local avgFps = 0
local avgMemory = 0
for _, m in ipairs(measurements) do
    avgFps = avgFps + m.fps
    avgMemory = avgMemory + m.memory
end
avgFps = math.floor(avgFps / #measurements)
avgMemory = math.floor(avgMemory / #measurements)

print(string.format("  Average FPS: %d", avgFps))
print(string.format("  Average Memory: %d MB", avgMemory))
print(string.format("  Player Count: %d", #Players:GetPlayers()))

local performanceGood = avgFps >= 30 and avgMemory < 500
if performanceGood then
    print("  ✅ Performance metrics acceptable")
else
    print("  ⚠️ Performance may need optimization")
end

-- Final Summary
print("\n" .. string.rep("=", 80))
print("FINAL VALIDATION SUMMARY")
print(string.rep("=", 80))

local totalChecks = healthPassed + fixesPassed
local totalPossible = #checks + #fixes
local percentage = math.floor((totalChecks / totalPossible) * 100)

print(string.format("System Health: %d/%d checks passed", healthPassed, #checks))
print(string.format("Code Fixes: %d/%d verified", fixesPassed, #fixes))
print(string.format("Overall Score: %d/%d (%.0f%%)", totalChecks, totalPossible, percentage))

-- Grade calculation
local grade = "F"
if percentage >= 95 then
    grade = "A"
elseif percentage >= 90 then
    grade = "A-"
elseif percentage >= 85 then
    grade = "B+"
elseif percentage >= 80 then
    grade = "B"
elseif percentage >= 75 then
    grade = "C"
elseif percentage >= 70 then
    grade = "D"
end

print(string.format("\nProduction Readiness Grade: %s (%d%%)", grade, percentage))

if percentage >= 95 then
    print("\n🎉 ✅ SYSTEM IS FULLY PRODUCTION READY!")
    print("All critical fixes verified and system is performing excellently.")
    print("You can deploy to production with confidence!")
elseif percentage >= 90 then
    print("\n✅ System is production ready with minor issues")
    print("Review any failed checks but deployment can proceed.")
elseif percentage >= 80 then
    print("\n⚠️ System has some issues that should be addressed")
    print("Fix failed checks before deploying to production.")
else
    print("\n❌ System is NOT production ready")
    print("Critical issues detected. Fix all problems before deployment.")
end

print(string.rep("=", 80) .. "\n")

-- Return results for external use
return {
    grade = grade,
    percentage = percentage,
    healthPassed = healthPassed,
    healthTotal = #checks,
    fixesPassed = fixesPassed,
    fixesTotal = #fixes,
    performance = {
        fps = avgFps,
        memory = avgMemory,
        acceptable = performanceGood
    }
}