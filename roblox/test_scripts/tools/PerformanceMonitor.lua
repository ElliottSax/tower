--[[
    Performance Monitor - Real-time game performance tracking
    Monitors: Memory, FPS, DataStore calls, Player count
    Usage: Run in ServerScriptService for continuous monitoring
]]

local PerformanceMonitor = {}

-- Configuration
local CONFIG = {
    UpdateInterval = 30,  -- seconds between readings
    LogToConsole = true,
    SaveToDataStore = false,  -- Set true to persist metrics
    AlertThresholds = {
        MemoryMB = 2000,      -- Alert if memory > 2GB
        ServerFPS = 40,       -- Alert if FPS < 40
        DataStoreErrors = 5   -- Alert if errors > 5 per minute
    }
}

-- Metrics storage
local Metrics = {
    StartTime = os.time(),
    Readings = {},
    Alerts = {}
}

-- Services
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[
    Get current performance snapshot
]]
function PerformanceMonitor.GetSnapshot()
    local snapshot = {
        Timestamp = os.time(),
        Uptime = os.time() - Metrics.StartTime,

        -- Memory
        MemoryMB = Stats:GetTotalMemoryUsageMb(),
        MemoryPlaces = Stats.PlacesMemory:GetValue() / 1024 / 1024,
        MemoryScript = Stats.InstanceCount:GetValue() * 0.001,  -- Rough estimate

        -- Performance
        ServerFPS = math.floor(1 / RunService.Heartbeat:Wait()),
        Heartbeat = Stats.HeartbeatTimeMs:GetValue(),

        -- Players
        PlayerCount = #Players:GetPlayers(),

        -- DataStore (if available)
        DataStoreRequests = Stats:GetValueOrDefault("DataStore Requests", 0),
        DataStoreErrors = Stats:GetValueOrDefault("DataStore Errors", 0),

        -- Network
        DataReceiveKbps = Stats.DataReceiveKbps:GetValue(),
        DataSendKbps = Stats.DataSendKbps:GetValue(),

        -- Physics
        PhysicsStepTimeMs = Stats.PhysicsStepTimeMs:GetValue(),
    }

    return snapshot
end

--[[
    Format snapshot for display
]]
function PerformanceMonitor.FormatSnapshot(snapshot)
    local lines = {
        string.rep("=", 60),
        string.format("Performance Report - Uptime: %d minutes", math.floor(snapshot.Uptime / 60)),
        string.rep("=", 60),
        "",
        "MEMORY:",
        string.format("  Total: %.2f MB", snapshot.MemoryMB),
        string.format("  Places: %.2f MB", snapshot.MemoryPlaces),
        "",
        "PERFORMANCE:",
        string.format("  Server FPS: %d", snapshot.ServerFPS),
        string.format("  Heartbeat: %.2f ms", snapshot.Heartbeat),
        string.format("  Physics Step: %.2f ms", snapshot.PhysicsStepTimeMs),
        "",
        "PLAYERS:",
        string.format("  Count: %d", snapshot.PlayerCount),
        "",
        "DATASTORE:",
        string.format("  Requests: %d", snapshot.DataStoreRequests),
        string.format("  Errors: %d", snapshot.DataStoreErrors),
        "",
        "NETWORK:",
        string.format("  Receive: %.2f Kbps", snapshot.DataReceiveKbps),
        string.format("  Send: %.2f Kbps", snapshot.DataSendKbps),
        string.rep("=", 60),
    }

    return table.concat(lines, "\n")
end

--[[
    Check for alert conditions
]]
function PerformanceMonitor.CheckAlerts(snapshot)
    local alerts = {}

    -- Memory alert
    if snapshot.MemoryMB > CONFIG.AlertThresholds.MemoryMB then
        table.insert(alerts, {
            Type = "MEMORY",
            Severity = "HIGH",
            Message = string.format("Memory usage high: %.2f MB (threshold: %d MB)",
                snapshot.MemoryMB, CONFIG.AlertThresholds.MemoryMB)
        })
    end

    -- FPS alert
    if snapshot.ServerFPS < CONFIG.AlertThresholds.ServerFPS then
        table.insert(alerts, {
            Type = "PERFORMANCE",
            Severity = "HIGH",
            Message = string.format("Server FPS low: %d (threshold: %d)",
                snapshot.ServerFPS, CONFIG.AlertThresholds.ServerFPS)
        })
    end

    -- DataStore errors alert
    if snapshot.DataStoreErrors > CONFIG.AlertThresholds.DataStoreErrors then
        table.insert(alerts, {
            Type = "DATASTORE",
            Severity = "CRITICAL",
            Message = string.format("DataStore errors: %d (threshold: %d)",
                snapshot.DataStoreErrors, CONFIG.AlertThresholds.DataStoreErrors)
        })
    end

    return alerts
end

--[[
    Log alert to console and storage
]]
function PerformanceMonitor.LogAlert(alert)
    warn(string.format("[PERFORMANCE ALERT] %s - %s: %s",
        alert.Severity, alert.Type, alert.Message))

    table.insert(Metrics.Alerts, {
        Timestamp = os.time(),
        Alert = alert
    })
end

--[[
    Start continuous monitoring
]]
function PerformanceMonitor.StartMonitoring()
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║   Performance Monitor Started                                 ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print(string.format("Update interval: %d seconds", CONFIG.UpdateInterval))
    print(string.format("Memory threshold: %d MB", CONFIG.AlertThresholds.MemoryMB))
    print(string.format("FPS threshold: %d", CONFIG.AlertThresholds.ServerFPS))
    print("")

    spawn(function()
        while true do
            wait(CONFIG.UpdateInterval)

            -- Get snapshot
            local snapshot = PerformanceMonitor.GetSnapshot()

            -- Store reading
            table.insert(Metrics.Readings, snapshot)

            -- Trim old readings (keep last 100)
            if #Metrics.Readings > 100 then
                table.remove(Metrics.Readings, 1)
            end

            -- Check for alerts
            local alerts = PerformanceMonitor.CheckAlerts(snapshot)
            for _, alert in ipairs(alerts) do
                PerformanceMonitor.LogAlert(alert)
            end

            -- Log to console
            if CONFIG.LogToConsole then
                print(PerformanceMonitor.FormatSnapshot(snapshot))
            end
        end
    end)
end

--[[
    Get memory trend analysis
]]
function PerformanceMonitor.GetMemoryTrend()
    if #Metrics.Readings < 2 then
        return {
            Status = "INSUFFICIENT_DATA",
            Message = "Need at least 2 readings"
        }
    end

    local firstReading = Metrics.Readings[1]
    local lastReading = Metrics.Readings[#Metrics.Readings]

    local memoryGrowth = lastReading.MemoryMB - firstReading.MemoryMB
    local duration = lastReading.Timestamp - firstReading.Timestamp
    local growthRate = memoryGrowth / (duration / 3600)  -- MB per hour

    local status = "HEALTHY"
    if growthRate > 100 then
        status = "CRITICAL_LEAK"
    elseif growthRate > 50 then
        status = "POTENTIAL_LEAK"
    elseif growthRate > 20 then
        status = "ELEVATED"
    end

    return {
        Status = status,
        GrowthMB = memoryGrowth,
        GrowthRateMBPerHour = growthRate,
        Duration = duration,
        Message = string.format("Memory %s by %.2f MB over %d minutes (%.2f MB/hour)",
            memoryGrowth >= 0 and "increased" or "decreased",
            math.abs(memoryGrowth),
            duration / 60,
            growthRate)
    }
end

--[[
    Generate summary report
]]
function PerformanceMonitor.GenerateReport()
    print("\n")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║   Performance Monitoring Summary                              ║")
    print("╚═══════════════════════════════════════════════════════════════╝")

    if #Metrics.Readings == 0 then
        print("No data collected yet")
        return
    end

    local firstReading = Metrics.Readings[1]
    local lastReading = Metrics.Readings[#Metrics.Readings]
    local duration = lastReading.Timestamp - firstReading.Timestamp

    print(string.format("Monitoring duration: %d minutes", duration / 60))
    print(string.format("Total readings: %d", #Metrics.Readings))
    print(string.format("Alerts triggered: %d", #Metrics.Alerts))
    print("")

    -- Memory analysis
    print("MEMORY ANALYSIS:")
    local memoryTrend = PerformanceMonitor.GetMemoryTrend()
    print(string.format("  Status: %s", memoryTrend.Status))
    print(string.format("  %s", memoryTrend.Message))
    print(string.format("  Current: %.2f MB", lastReading.MemoryMB))
    print("")

    -- Performance summary
    print("PERFORMANCE SUMMARY:")
    local avgFPS = 0
    for _, reading in ipairs(Metrics.Readings) do
        avgFPS = avgFPS + reading.ServerFPS
    end
    avgFPS = avgFPS / #Metrics.Readings

    print(string.format("  Average FPS: %.1f", avgFPS))
    print(string.format("  Current FPS: %d", lastReading.ServerFPS))
    print(string.format("  Average Players: %.1f",
        (lastReading.PlayerCount + firstReading.PlayerCount) / 2))
    print("")

    -- Alerts summary
    if #Metrics.Alerts > 0 then
        print("ALERTS:")
        for i, alertEntry in ipairs(Metrics.Alerts) do
            if i <= 5 then  -- Show last 5 alerts
                local alert = alertEntry.Alert
                print(string.format("  [%s] %s: %s",
                    alert.Severity, alert.Type, alert.Message))
            end
        end
        if #Metrics.Alerts > 5 then
            print(string.format("  ... and %d more alerts", #Metrics.Alerts - 5))
        end
    else
        print("ALERTS: None (healthy)")
    end

    print("")
    print("╚═══════════════════════════════════════════════════════════════╝")
end

--[[
    Export data for external analysis
]]
function PerformanceMonitor.ExportData()
    local HttpService = game:GetService("HttpService")

    local export = {
        StartTime = Metrics.StartTime,
        Duration = os.time() - Metrics.StartTime,
        Readings = Metrics.Readings,
        Alerts = Metrics.Alerts,
        MemoryTrend = PerformanceMonitor.GetMemoryTrend()
    }

    local json = HttpService:JSONEncode(export)
    print("=== PERFORMANCE DATA EXPORT ===")
    print(json)
    print("=== END EXPORT ===")

    return export
end

-- Auto-start monitoring if run directly
if not _G.PerformanceMonitor then
    _G.PerformanceMonitor = PerformanceMonitor
    PerformanceMonitor.StartMonitoring()
end

return PerformanceMonitor
