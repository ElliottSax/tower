--[[
	ServiceLocator.lua
	Central service registry to replace _G pattern

	Benefits:
	- Type-safe service access
	- Clear initialization order
	- Easy testing and mocking
	- No global pollution

	Usage:
		-- Register service
		ServiceLocator.Register("DataService", DataService)

		-- Get service
		local DataService = ServiceLocator.Get("DataService")

		-- Wait for service (useful during initialization)
		local DataService = ServiceLocator.WaitFor("DataService", 10)

	Created: 2025-12-17
--]]

local ServiceLocator = {}
ServiceLocator._services = {}
ServiceLocator._pendingRequests = {}

-- ============================================================================
-- SERVICE REGISTRATION
-- ============================================================================

function ServiceLocator.Register(serviceName: string, serviceInstance: any)
	if ServiceLocator._services[serviceName] then
		warn(string.format("[ServiceLocator] Service '%s' already registered, overwriting", serviceName))
	end

	ServiceLocator._services[serviceName] = serviceInstance
	print(string.format("[ServiceLocator] Registered service: %s", serviceName))

	-- Resolve pending requests
	if ServiceLocator._pendingRequests[serviceName] then
		for _, resolveCallback in ipairs(ServiceLocator._pendingRequests[serviceName]) do
			task.spawn(resolveCallback, serviceInstance)
		end
		ServiceLocator._pendingRequests[serviceName] = nil
	end

	return true
end

function ServiceLocator.Unregister(serviceName: string)
	ServiceLocator._services[serviceName] = nil
	print(string.format("[ServiceLocator] Unregistered service: %s", serviceName))
end

-- ============================================================================
-- SERVICE ACCESS
-- ============================================================================

function ServiceLocator.Get(serviceName: string): any?
	return ServiceLocator._services[serviceName]
end

function ServiceLocator.GetOrError(serviceName: string): any
	local service = ServiceLocator._services[serviceName]
	if not service then
		error(string.format("[ServiceLocator] Service '%s' not found", serviceName))
	end
	return service
end

function ServiceLocator.WaitFor(serviceName: string, timeout: number?): any?
	-- Check if already registered
	if ServiceLocator._services[serviceName] then
		return ServiceLocator._services[serviceName]
	end

	-- Wait for registration
	local maxWait = timeout or 10
	local startTime = tick()
	local result = nil
	local completed = false

	-- Setup pending request
	if not ServiceLocator._pendingRequests[serviceName] then
		ServiceLocator._pendingRequests[serviceName] = {}
	end

	table.insert(ServiceLocator._pendingRequests[serviceName], function(service)
		result = service
		completed = true
	end)

	-- Wait with timeout
	while not completed and (tick() - startTime) < maxWait do
		task.wait(0.1)
	end

	if completed then
		return result
	else
		warn(string.format("[ServiceLocator] Timeout waiting for service: %s", serviceName))
		return nil
	end
end

function ServiceLocator.Has(serviceName: string): boolean
	return ServiceLocator._services[serviceName] ~= nil
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function ServiceLocator.GetAll(): {[string]: any}
	local services = {}
	for name, service in pairs(ServiceLocator._services) do
		services[name] = service
	end
	return services
end

function ServiceLocator.GetServiceNames(): {string}
	local names = {}
	for name, _ in pairs(ServiceLocator._services) do
		table.insert(names, name)
	end
	return names
end

function ServiceLocator.Clear()
	ServiceLocator._services = {}
	ServiceLocator._pendingRequests = {}
	print("[ServiceLocator] Cleared all services")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return ServiceLocator
