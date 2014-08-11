nut.util.Include("sv_hooks.lua")
nut.util.Include("cl_hooks.lua")

function GM:Initialize()
	if (SERVER) then
		local date = nut.util.ReadTable("date", true)
		local time = os.time({
			month = nut.config.dateStartMonth,
			day = nut.config.dateStartDay,
			year = nut.config.dateStartYear
		})

		if (#date < 1) then
			time = time * (nut.config.dateMinuteLength / 60)

			nut.util.WriteTable("date", time, true)
			nut.curTime = time
		else
			nut.curTime = date[1] or time
		end

		if (!nut.config.noPersist) then
			game.ConsoleCommand("sbox_persist 1\n")
		end
	end

	hook.Run("SetupAttributes")
end

--[[
	Purpose: Called when an auto-refresh has occurred, a timer is used to give the game time
	to load the schemas config files.
--]]
function GM:OnReloaded()
	if (SERVER) then
		nut.util.AddLog("NutScript has been auto-refreshed.", LOG_FILTER_MAJOR)
	end
	
	timer.Simple(0.5, function()
		hook.Run("SetupAttributes")
		hook.Run("Refresh")
	end)
end

--[[
	Purpose: Allows schemas and plugins to register their attributes through a hook
	so that schemas can easily override this behavior without editing nutscript itself.
--]]
function GM:SetupAttributes()
	if (nut.config.baseAttributes) then
		ATTRIB_ACR = nut.attribs.SetUp("Acrobatics", "Affects how high you can jump.", "acr", function(client, points)
			client:SetJumpPower(nut.config.jumpPower + points*3)
		end)

		ATTRIB_STR = nut.attribs.SetUp("Strength", "Affects how powerful your actions are.", "str")
	end

	hook.Run("RegisterAttributes")
end

--[[
	Purpose: Similar to an entity's SetupDataTables, this prepares any variables that
	are to be networked. This can be called on the schema to make custom variables, but
	is used on the framework for default variables. You should not edit this.
--]]
function GM:CreateCharVars(character)
	character:NewVar("charname", "John Doe", CHAR_PUBLIC)
	character:NewVar("description", "An unknown person.", CHAR_PUBLIC)
	character:NewVar("money", 0, CHAR_PRIVATE)
	character:NewVar("inv", {}, CHAR_PRIVATE)
	character:NewVar("chardata", {}, CHAR_PRIVATE)
	character:NewVar("gender", "male", CHAR_PUBLIC)
	character:NewVar("id", 0, CHAR_PUBLIC, true)
end

function GM:GetPlayerName(client, mode)
	return client:Name()
end

WEAPON_LOWERED = 1
WEAPON_RAISED = 2

local math_NormalizeAngle = math.NormalizeAngle
local string_find = string.find
local string_lower = string.lower
local getAnimClass = nut.anim.GetClass
local getHoldType = nut.util.GetHoldType
local config = nut.config

local Length2D = FindMetaTable("Vector").Length2D

local NORMAL_HOLDTYPES = {
	normal = true,
	fist = true,
	melee = true,
	revolver = true,
	pistol = true,
	slam = true,
	knife = true,
	grenade = true
}

function GM:GrabEarAnimation(client)
	if (nut.config.allowEarGrab) then
		return self.BaseClass:GrabEarAnimation(client)
	end
end

function GM:CalcMainActivity(client, velocity)
	local model = string_lower(client:GetModel())
	local class = getAnimClass(model)
	local weapon = client:GetActiveWeapon()
	local holdType = "normal"
	local state = WEAPON_LOWERED
	local action = "idle"
	local length2D = Length2D(velocity)

	if (length2D >= config.runSpeed - 10) then
		action = "run"
	elseif (length2D >= 5) then
		action = "walk"
	end

	if (IsValid(weapon)) then
		holdType = getHoldType(weapon)

		if (weapon.AlwaysRaised or config.alwaysRaised[weapon:GetClass()]) then
			state = WEAPON_RAISED
		end
	end

	if (client:WepRaised()) then
		state = WEAPON_RAISED
	end

	if (string_find(model, "/player/") or string_find(model, "/playermodel") or class == "player") then
		local calcIdeal, calcOverride = self.BaseClass:CalcMainActivity(client, velocity)

		if (state == WEAPON_LOWERED) then
			if (client:Crouching()) then
				action = action.."_crouch"
			end

			if (!client:OnGround()) then
				action = "jump"
			end

			if (!NORMAL_HOLDTYPES[holdType]) then
				calcIdeal = _G["ACT_HL2MP_"..string.upper(action).."_PASSIVE"]
			else
				if (action == "jump") then
					calcIdeal = ACT_HL2MP_JUMP_PASSIVE
				else
					calcIdeal = _G["ACT_HL2MP_"..string.upper(action)]
				end
			end
		end

		client.CalcIdeal = calcIdeal
		client.CalcSeqOverride = calcOverride

		return client.CalcIdeal, client.CalcSeqOverride
	end

	if (client.character and client:Alive()) then
		client.CalcSeqOverride = -1

		if (client:Crouching()) then
			action = action.."_crouch"
		end
		
		local animClass = nut.anim[class]

		if (!animClass) then
			class = "citizen_male"
		end

		if (!animClass[holdType]) then
			holdType = "normal"
		end

		if (!animClass[holdType][action]) then
			action = "idle"
		end

		local animation = animClass[holdType][action]
		local value = ACT_IDLE

		if (!client:OnGround()) then
			client.CalcIdeal = animClass.glide or ACT_GLIDE
		elseif (client:InVehicle()) then
			client.CalcIdeal = animClass.normal.idle_crouch[1]
		elseif (animation) then
			value = animation[state]

			if (type(value) == "string") then
				client.CalcSeqOverride = client:LookupSequence(value)
			else
				client.CalcIdeal = value
			end
		end

		local override = client:GetNetVar("seq")

		if (override) then
			client.CalcSeqOverride = client:LookupSequence(override)
		end

		if (CLIENT) then
			client:SetIK(false)
		end

		local eyeAngles = client:EyeAngles()
		local yaw = velocity:Angle().yaw
		local normalized = math_NormalizeAngle(yaw - eyeAngles.y)

		client:SetPoseParameter("move_yaw", normalized)

		return client.CalcIdeal or ACT_IDLE, client.CalcSeqOverride or -1
	end
end

function GM:PhysgunPickup(client, entity)
	if (client:IsAdmin()) then
		if (entity:IsPlayer()) then
			entity:SetMoveType(MOVETYPE_NOCLIP)

			return true
		end
	end

	if (entity:GetPersistent()) then return false end

	if (entity.PhysgunDisable or entity.PhysgunDisabled) then
		if (entity.PhysgunAllowAdmin and client:IsAdmin()) then
			return  true
		end
		
		return false
	end

	if (client:IsAdmin()) then
		return true
	end

	local creator = entity.GetCreator and entity:GetCreator()

	if (client != creator) then
		return false
	end

	return !entity:IsNPC() and !entity:IsPlayer() and (SERVER and !entity:CreatedByMap() or true)
end

function GM:CanTool(client, trace, mode)
	local entity = trace.Entity
	local result = self.BaseClass:CanTool(client, trace, mode)

	if (result == false) then
		return false
	end

	if (client:IsAdmin()) then
		if (IsValid(entity) and entity:IsPlayer() and !nut.config.adminRemovePly and SERVER and (mode == "remover")) then
			entity:Kick("You have been removed by "..client:Name())
		end

		return true
	elseif (IsValid(entity) and entity:IsDoor()) then
		return false
	end
	
	if entity:IsWorld() then
		return true
	end
	
	local creator = entity.GetCreator and entity:GetCreator()

	if (SERVER and client != creator) then
		return false
	end

	return !entity:IsNPC() and !entity:IsPlayer() and (SERVER and !entity:CreatedByMap() or true)
end

function GM:PhysgunDrop(client, entity)
	if (entity:IsPlayer()) then
		entity:SetMoveType(MOVETYPE_WALK)
	end
end

function GM:DoAnimationEvent(client, event, data)
	local model = string_lower(client:GetModel())
	local class = getAnimClass(model)

	if (string_find(model, "/player/") or string_find(model, "/playermodel") or class == "player") then
		return self.BaseClass:DoAnimationEvent(client, event, data)
	end

	local weapon = client:GetActiveWeapon()
	local holdType = "normal"
	local class = nut.anim.GetClass(model)

	if (!nut.anim[class]) then
		class = "citizen_male"
	end

	if (IsValid(weapon)) then
		holdType = nut.util.GetHoldType(weapon)
	end

	if (!nut.anim[class][holdType]) then
		holdType = "normal"
	end

	local animation = nut.anim[class][holdType]

	if (event == PLAYERANIMEVENT_ATTACK_PRIMARY) then
		client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

		return ACT_VM_PRIMARYATTACK
	elseif (event == PLAYERANIMEVENT_ATTACK_SECONDARY) then
		client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

		return ACT_VM_SECONDARYATTACK
	elseif (event == PLAYERANIMEVENT_RELOAD) then
		client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.reload or ACT_GESTURE_RELOAD_SMG1, true)

		return ACT_INVALID
	elseif (event == PLAYERANIMEVENT_JUMP) then
		client.m_bJumping = true
		client.m_bFistJumpFrame = true
		client.m_flJumpStartTime = CurTime()

		client:AnimRestartMainSequence()

		return ACT_INVALID
	elseif (event == PLAYERANIMEVENT_CANCEL_RELOAD) then
		client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

		return ACT_INVALID
	end

	return nil
end

function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

function GM:CanProperty(client, property, entity)
	return client:IsAdmin()
end

function GM:PlayerCanUseItem(client, item)
	if (client:GetNetVar("tied") and !item.allowUseOnTied) then
		return false
	end
end
