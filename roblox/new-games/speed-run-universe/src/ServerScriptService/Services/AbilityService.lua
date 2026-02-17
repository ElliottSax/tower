--[[
	AbilityService.lua - Speed Run Universe
	Manages movement ability unlocks, equipping, usage validation, and cooldowns.
	Abilities: Double Jump, Dash, Wall Run, Grapple, Glide, Teleport
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AbilityService = {}
AbilityService.DataService = nil
AbilityService.SecurityManager = nil

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================
-- Active cooldowns: userId -> { abilityId -> lastUsedTick }
local AbilityCooldowns = {}

-- Maximum equipped abilities at once
local MAX_EQUIPPED = 3

-- ============================================================================
-- INIT
-- ============================================================================
function AbilityService.Init()
	AbilityService.DataService = require(ServerScriptService.Services.DataService)
	AbilityService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Equip/unequip ability
	re:WaitForChild("EquipAbility").OnServerEvent:Connect(function(player, data)
		AbilityService.HandleEquipAbility(player, data)
	end)

	-- Ability usage (server-side validation)
	re:WaitForChild("UseAbility").OnServerEvent:Connect(function(player, data)
		AbilityService.HandleUseAbility(player, data)
	end)

	-- Initialize cooldown tracking
	Players.PlayerAdded:Connect(function(player)
		AbilityCooldowns[player.UserId] = {}
	end)
	Players.PlayerRemoving:Connect(function(player)
		AbilityCooldowns[player.UserId] = nil
	end)

	print("[AbilityService] Initialized")
end

-- ============================================================================
-- EQUIP / UNEQUIP
-- ============================================================================
function AbilityService.HandleEquipAbility(player, data)
	if not AbilityService.SecurityManager.CheckRateLimit(player, "EquipAbility") then return end
	if not data or not data.AbilityId then return end

	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return end

	local abilityId = data.AbilityId
	local action = data.Action or "equip" -- "equip" or "unequip"

	-- Validate ability exists
	local abilityCfg = GameConfig.AbilityById[abilityId]
	if not abilityCfg then return end

	-- Check if player has unlocked this ability
	local isUnlocked = false
	for _, id in ipairs(playerData.UnlockedAbilities) do
		if id == abilityId then isUnlocked = true; break end
	end
	if not isUnlocked then
		AbilityService._Notify(player, "Ability not unlocked yet!")
		return
	end

	if action == "equip" then
		-- Check if already equipped
		for _, id in ipairs(playerData.EquippedAbilities) do
			if id == abilityId then
				AbilityService._Notify(player, "Ability already equipped!")
				return
			end
		end

		-- Check max equipped
		if #playerData.EquippedAbilities >= MAX_EQUIPPED then
			AbilityService._Notify(player, "Max " .. MAX_EQUIPPED .. " abilities equipped! Unequip one first.")
			return
		end

		table.insert(playerData.EquippedAbilities, abilityId)
		AbilityService._Notify(player, abilityCfg.Name .. " equipped!")

	elseif action == "unequip" then
		local found = false
		for i, id in ipairs(playerData.EquippedAbilities) do
			if id == abilityId then
				table.remove(playerData.EquippedAbilities, i)
				found = true
				break
			end
		end
		if not found then return end
		AbilityService._Notify(player, abilityCfg.Name .. " unequipped.")
	end

	-- Sync to client
	AbilityService._SyncAbilities(player)
end

-- ============================================================================
-- USE ABILITY (Server validation)
-- ============================================================================
function AbilityService.HandleUseAbility(player, data)
	if not AbilityService.SecurityManager.CheckRateLimit(player, "UseAbility") then return end
	if not data or not data.AbilityId then return end

	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return end

	local abilityId = data.AbilityId
	local abilityCfg = GameConfig.AbilityById[abilityId]
	if not abilityCfg then return end

	-- Must be equipped
	local isEquipped = false
	for _, id in ipairs(playerData.EquippedAbilities) do
		if id == abilityId then isEquipped = true; break end
	end
	if not isEquipped then return end

	-- Check cooldown
	local cooldowns = AbilityCooldowns[player.UserId]
	if cooldowns then
		local lastUsed = cooldowns[abilityId]
		if lastUsed then
			local elapsed = tick() - lastUsed
			if elapsed < abilityCfg.Cooldown then
				-- Still on cooldown - client should handle this visually,
				-- but server rejects to prevent exploits
				return
			end
		end
		cooldowns[abilityId] = tick()
	end

	-- Apply ability effect based on type
	AbilityService._ApplyAbility(player, abilityCfg, data)
end

-- ============================================================================
-- ABILITY APPLICATION (Server-authoritative effects)
-- ============================================================================
function AbilityService._ApplyAbility(player, abilityCfg, clientData)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	local abilityId = abilityCfg.Id

	if abilityId == "DoubleJump" then
		-- Double jump: apply upward velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		bodyVelocity.Velocity = Vector3.new(0, abilityCfg.JumpPower, 0)
		bodyVelocity.Parent = hrp
		task.delay(0.2, function()
			if bodyVelocity.Parent then bodyVelocity:Destroy() end
		end)

	elseif abilityId == "Dash" then
		-- Dash: burst forward in look direction
		local lookVector = hrp.CFrame.LookVector
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
		bodyVelocity.Velocity = lookVector * abilityCfg.DashForce
		bodyVelocity.Parent = hrp
		task.delay(abilityCfg.Duration, function()
			if bodyVelocity.Parent then bodyVelocity:Destroy() end
		end)

	elseif abilityId == "WallRun" then
		-- Wall run: check if near a wall, apply upward + forward velocity
		-- The client handles the visual/animation; server validates and applies physics
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { character }
		params.FilterType = Enum.RaycastFilterType.Exclude

		-- Cast ray to the right and left to find walls
		local rightResult = workspace:Raycast(hrp.Position, hrp.CFrame.RightVector * 3, params)
		local leftResult = workspace:Raycast(hrp.Position, -hrp.CFrame.RightVector * 3, params)
		local wallResult = rightResult or leftResult

		if wallResult then
			local wallNormal = wallResult.Normal
			local upVelocity = Vector3.new(0, abilityCfg.WallRunSpeed * 0.5, 0)
			local forwardVelocity = hrp.CFrame.LookVector * abilityCfg.WallRunSpeed

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Velocity = upVelocity + forwardVelocity
			bodyVelocity.Parent = hrp

			-- Anti-gravity during wall run
			local bodyForce = Instance.new("BodyForce")
			bodyForce.Force = Vector3.new(0, workspace.Gravity * hrp.AssemblyMass, 0)
			bodyForce.Parent = hrp

			task.delay(abilityCfg.Duration, function()
				if bodyVelocity.Parent then bodyVelocity:Destroy() end
				if bodyForce.Parent then bodyForce:Destroy() end
			end)
		end

	elseif abilityId == "Grapple" then
		-- Grapple: raycast forward to find anchor point, pull toward it
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { character }
		params.FilterType = Enum.RaycastFilterType.Exclude

		local direction = hrp.CFrame.LookVector + Vector3.new(0, 0.3, 0) -- Slightly upward
		local result = workspace:Raycast(hrp.Position, direction.Unit * abilityCfg.GrappleRange, params)

		if result then
			local targetPos = result.Position
			local direction = (targetPos - hrp.Position).Unit

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Velocity = direction * abilityCfg.GrappleSpeed
			bodyVelocity.Parent = hrp

			-- Create visual rope (beam)
			local attachment0 = Instance.new("Attachment")
			attachment0.Parent = hrp

			local attachment1 = Instance.new("Attachment")
			attachment1.WorldPosition = targetPos
			attachment1.Parent = workspace.Terrain

			local beam = Instance.new("Beam")
			beam.Attachment0 = attachment0
			beam.Attachment1 = attachment1
			beam.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
			beam.Width0 = 0.2
			beam.Width1 = 0.1
			beam.Parent = hrp

			task.delay(abilityCfg.Duration, function()
				if bodyVelocity.Parent then bodyVelocity:Destroy() end
				if beam.Parent then beam:Destroy() end
				if attachment0.Parent then attachment0:Destroy() end
				if attachment1.Parent then attachment1:Destroy() end
			end)
		end

	elseif abilityId == "Glide" then
		-- Glide: reduce gravity, maintain horizontal velocity
		local bodyForce = Instance.new("BodyForce")
		-- Counter most of gravity, leaving only GlideGravity
		local counterForce = (workspace.Gravity - abilityCfg.GlideGravity) * hrp.AssemblyMass
		bodyForce.Force = Vector3.new(0, counterForce, 0)
		bodyForce.Parent = hrp

		-- Add forward glide
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
		bodyVelocity.Velocity = hrp.CFrame.LookVector * abilityCfg.GlideSpeed
		bodyVelocity.Parent = hrp

		-- End glide after duration or when player lands
		local glideActive = true
		task.delay(abilityCfg.Duration, function()
			glideActive = false
			if bodyForce.Parent then bodyForce:Destroy() end
			if bodyVelocity.Parent then bodyVelocity:Destroy() end
		end)

		-- Also end glide if player touches ground
		task.spawn(function()
			while glideActive do
				task.wait(0.1)
				if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Landed then
					glideActive = false
					if bodyForce.Parent then bodyForce:Destroy() end
					if bodyVelocity.Parent then bodyVelocity:Destroy() end
					break
				end
			end
		end)

	elseif abilityId == "Teleport" then
		-- Teleport: blink forward
		local lookVector = hrp.CFrame.LookVector
		local targetPos = hrp.Position + lookVector * abilityCfg.TeleportDistance

		-- Raycast to make sure we don't teleport through walls
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { character }
		params.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(hrp.Position, lookVector * abilityCfg.TeleportDistance, params)

		if result then
			-- Hit something - teleport to just before the wall
			targetPos = result.Position - lookVector * 2
		end

		hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
	end
end

-- ============================================================================
-- SYNC ABILITIES TO CLIENT
-- ============================================================================
function AbilityService._SyncAbilities(player)
	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local sync = re:FindFirstChild("AbilitySync")
		if sync then
			-- Build ability state
			local abilityState = {
				UnlockedAbilities = playerData.UnlockedAbilities,
				EquippedAbilities = playerData.EquippedAbilities,
				Cooldowns = {},
			}

			-- Include current cooldown states
			local cooldowns = AbilityCooldowns[player.UserId]
			if cooldowns then
				for abilityId, lastUsed in pairs(cooldowns) do
					local cfg = GameConfig.AbilityById[abilityId]
					if cfg then
						local remaining = cfg.Cooldown - (tick() - lastUsed)
						if remaining > 0 then
							abilityState.Cooldowns[abilityId] = remaining
						end
					end
				end
			end

			sync:FireClient(player, abilityState)
		end
	end
end

-- ============================================================================
-- QUERIES
-- ============================================================================
function AbilityService.HasAbility(player, abilityId)
	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return false end

	for _, id in ipairs(playerData.UnlockedAbilities) do
		if id == abilityId then return true end
	end
	return false
end

function AbilityService.IsAbilityEquipped(player, abilityId)
	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return false end

	for _, id in ipairs(playerData.EquippedAbilities) do
		if id == abilityId then return true end
	end
	return false
end

function AbilityService.GetEquippedAbilities(player)
	local playerData = AbilityService.DataService.GetFullData(player)
	if not playerData then return {} end
	return playerData.EquippedAbilities
end

-- ============================================================================
-- UTILITY
-- ============================================================================
function AbilityService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return AbilityService
