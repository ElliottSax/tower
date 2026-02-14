--[[
	Validation.lua
	Shared validation utilities for consistent input validation across client and server

	Features:
	- Player validation
	- Type checking
	- Number range validation
	- String sanitization
	- Table structure validation

	Usage:
	local Validation = require(ReplicatedStorage.Shared.Utilities.Validation)

	if not Validation.ValidatePlayer(player) then return end
	if not Validation.ValidateNumber(amount, 0, 1000000) then return end
--]]

local Players = game:GetService("Players")

local Validation = {}

-- ============================================================================
-- PLAYER VALIDATION
-- ============================================================================

function Validation.ValidatePlayer(player: any): boolean
	if not player then
		return false
	end

	if not typeof(player) == "Instance" then
		return false
	end

	if not player:IsA("Player") then
		return false
	end

	-- Check if player is still in game
	if not player.Parent then
		return false
	end

	return true
end

function Validation.ValidatePlayerWithCharacter(player: any): boolean
	if not Validation.ValidatePlayer(player) then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true
end

-- ============================================================================
-- TYPE VALIDATION
-- ============================================================================

function Validation.ValidateType(value: any, expectedType: string): boolean
	return type(value) == expectedType
end

function Validation.ValidateInstance(value: any, className: string): boolean
	if not value then
		return false
	end

	if typeof(value) ~= "Instance" then
		return false
	end

	return value:IsA(className)
end

-- ============================================================================
-- NUMBER VALIDATION
-- ============================================================================

function Validation.ValidateNumber(value: any, min: number?, max: number?): boolean
	if type(value) ~= "number" then
		return false
	end

	-- Check for NaN
	if value ~= value then
		return false
	end

	-- Check for infinity
	if value == math.huge or value == -math.huge then
		return false
	end

	-- Check range
	if min and value < min then
		return false
	end

	if max and value > max then
		return false
	end

	return true
end

function Validation.ValidateInteger(value: any, min: number?, max: number?): boolean
	if not Validation.ValidateNumber(value, min, max) then
		return false
	end

	return value == math.floor(value)
end

function Validation.ValidatePositiveNumber(value: any, max: number?): boolean
	return Validation.ValidateNumber(value, 0, max)
end

function Validation.ValidatePositiveInteger(value: any, max: number?): boolean
	return Validation.ValidateInteger(value, 0, max)
end

-- ============================================================================
-- STRING VALIDATION
-- ============================================================================

function Validation.ValidateString(value: any, minLength: number?, maxLength: number?): boolean
	if type(value) ~= "string" then
		return false
	end

	local length = #value

	if minLength and length < minLength then
		return false
	end

	if maxLength and length > maxLength then
		return false
	end

	return true
end

function Validation.ValidateNonEmptyString(value: any, maxLength: number?): boolean
	return Validation.ValidateString(value, 1, maxLength)
end

-- Sanitize string by removing potentially dangerous characters
function Validation.SanitizeString(value: string, maxLength: number?): string
	if type(value) ~= "string" then
		return ""
	end

	-- Remove null bytes and control characters
	local sanitized = value:gsub("[\0-\31]", "")

	-- Truncate if needed
	if maxLength and #sanitized > maxLength then
		sanitized = sanitized:sub(1, maxLength)
	end

	return sanitized
end

-- ============================================================================
-- TABLE VALIDATION
-- ============================================================================

function Validation.ValidateTable(value: any): boolean
	return type(value) == "table"
end

function Validation.ValidateTableWithKeys(value: any, requiredKeys: {string}): boolean
	if not Validation.ValidateTable(value) then
		return false
	end

	for _, key in ipairs(requiredKeys) do
		if value[key] == nil then
			return false
		end
	end

	return true
end

-- ============================================================================
-- ENUM VALIDATION
-- ============================================================================

function Validation.ValidateEnum(value: any, allowedValues: {any}): boolean
	for _, allowed in ipairs(allowedValues) do
		if value == allowed then
			return true
		end
	end
	return false
end

-- ============================================================================
-- COMBINED VALIDATORS
-- ============================================================================

-- Validate common coin operation parameters
function Validation.ValidateCoinOperation(player: any, amount: any): boolean
	if not Validation.ValidatePlayer(player) then
		return false
	end

	if not Validation.ValidatePositiveInteger(amount, 999999999) then
		return false
	end

	return true
end

-- Validate upgrade purchase parameters
function Validation.ValidateUpgradePurchase(player: any, upgradeName: any): boolean
	if not Validation.ValidatePlayer(player) then
		return false
	end

	if not Validation.ValidateNonEmptyString(upgradeName, 50) then
		return false
	end

	return true
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return Validation
