--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "normal"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

PLAYER_HOLDTYPE_TRANSLATOR = {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["passive"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "normal"

function GM:TranslateActivity(client, act)
	local model = client:GetModel():lower()
	local class = nut.anim.getModelClass(model)
	local weapon = client:GetActiveWeapon()

	if (class == "player") then
		if (IsValid(weapon) and !client:isWepRaised() and client:OnGround()) then
			if (model:find("zombie")) then
				local tree = nut.anim.zombie

				if (model:find("fast")) then
					tree = nut.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = weapon:GetHoldType()
			local value = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
			local tree = nut.anim.player[value]

			if (tree and tree[act]) then
				return tree[act]
			end
		end

		return self.BaseClass:TranslateActivity(client, act)
	end

	local tree = nut.anim[class]

	if (tree) then
		local subClass = "normal"

		if (client:InVehicle() and tree.vehicle) then
			local vehicle = client:GetVehicle()
			if (vehicle and IsValid(vehicle)) then
				local class = vehicle:GetClass()
				local act = tree.vehicle[class][1]
				local fixvec = tree.vehicle[class][2]
				local fixang = tree.vehicle[class][3]

				client:ManipulateBonePosition(0, fixvec)

				if (type(act) == "string") then
					client.CalcSeqOverride = client:LookupSequence(act)

					return
				else
					return act
				end
			end
		end
		
		if (client:OnGround()) then
			client:ManipulateBonePosition(0, Vector())

			if (IsValid(weapon)) then
				subClass = weapon:GetHoldType()
				subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
			end

			if (tree[subClass] and tree[subClass][act]) then
				local act2 = tree[subClass][act][client:isWepRaised() and 2 or 1]

				if (type(act2) == "string") then
					client.CalcSeqOverride = client:LookupSequence(act2)

					return
				end

				return act2
			end
		elseif (tree.glide) then
			return tree.glide
		end
	end
end

function GM:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = nut.item.list[uniqueID]

	if (!client:getChar()) then
		return false
	end

	if (itemTable.faction) then
		local allowed = false

		if (type(itemTable.faction) == "table") then
			for k, v in pairs(itemTable.faction) do
				if (client:Team() == v) then
					allowed = true

					break
				end
			end
		elseif (client:Team() != itemTable.faction) then
			allowed = false
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.class) then
		local allowed = false

		if (type(itemTable.class) == "table") then
			for k, v in pairs(itemTable.class) do
				if (client:getChar():getClass() == v) then
					allowed = true

					break
				end
			end
		elseif (client:getChar():getClass() != itemTable.class) then
			allowed = false
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.flags) then
		if (!client:getChar():hasFlags(itemTable.flags)) then
			return false
		end
	end

	return true
end

function GM:DoAnimationEvent(client, event, data)
	local model = client:GetModel():lower()
	local class = nut.anim.getModelClass(model)

	if (class == "player") then
		return self.BaseClass:DoAnimationEvent(client, event, data)
	else
		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local holdType = weapon:GetHoldType()
			holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

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
		end
	end

	return ACT_INVALID
end

function GM:EntityEmitSound(data)
	if (data.Entity.nutIsMuted) then
		return false
	end
end

function GM:CalcMainActivity(client, velocity)
	local eyeAngles = client:EyeAngles()
	local yaw = velocity:Angle().yaw
	local normalized = math.NormalizeAngle(yaw - eyeAngles.y)

	client:SetPoseParameter("move_yaw", normalized)

	if (CLIENT) then
		client:SetIK(false)
	end

	local oldSeqOverride = client.CalcSeqOverride
	local seqIdeal, seqOverride = self.BaseClass:CalcMainActivity(client, velocity)
	--client.CalcSeqOverride is being -1 after this line.

	return seqIdeal, client.nutForceSeq or oldSeqOverride or client.CalcSeqOverride
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function GM:StartCommand(client, command)
	local weapon = client:GetActiveWeapon()

	if (!client:isWepRaised()) then
		if (IsValid(weapon) and weapon.FireWhenLowered) then
			return
		end

		command:RemoveKey(KEY_BLACKLIST)
	end
end

function GM:OnCharVarChanged(char, varName, oldVar, newVar)
	if (nut.char.varHooks[varName]) then
		for k, v in pairs(nut.char.varHooks[varName]) do
			v(char, oldVar, newVar)
		end
	end
end

function GM:CanPlayerThrowPunch(client)
	if (!client:isWepRaised()) then
		return false
	end

	return true
end

function GM:GetDefaultCharName(client, faction)
	local info = nut.faction.indices[faction]

	if (info and info.onGetDefaultName) then
		return info:onGetDefaultName(client)
	end
end

function GM:CanPlayerUseChar(client, char)
	if (char:getData("banned")) then
		return false, "@charBanned"
	end
end

function GM:CanProperty(client, property, entity)
	if (client:IsAdmin()) then
		return true
	end

	if (CLIENT and (property == "remover" or property == "collision")) then
		return true
	end

	return false
end

function GM:PhysgunPickup(client, entity)
	if (client:IsAdmin()) then
		return true
	end

	if (self.BaseClass:PhysgunPickup(client, entity) == false) then
		return false
	end

	return false
end

local TOOL_SAFE = {}
TOOL_SAFE["lamp"] = true
TOOL_SAFE["camera"] = true

local TOOL_DANGEROUS = {}
TOOL_DANGEROUS["dynamite"] = true

function GM:CanTool(client, trace, tool)
	if (client:IsAdmin()) then
		return true
	end

	if (TOOL_DANGEROUS[tool]) then
		return false
	end
	
	local entity = trace.Entity

	if (IsValid(entity)) then
		if (TOOL_SAFE[tool]) then
			return true
		end
	else
		return true
	end

	return false
end

function GM:Move(client, moveData)
	local char = client:getChar()
	if (char) then
		if (client:getNetVar("actAng")) then
			moveData:SetForwardSpeed(0)
			moveData:SetSideSpeed(0)
		end

		if (client:GetMoveType() == MOVETYPE_WALK and moveData:KeyDown(IN_WALK)) then
			local mf, ms = 0, 0

			if (moveData:KeyDown(IN_FORWARD)) then
				mf = .4
			elseif (moveData:KeyDown(IN_BACK)) then
				mf = -.4
			end

			if (moveData:KeyDown(IN_MOVELEFT)) then
				ms = -.4
			elseif (moveData:KeyDown(IN_MOVERIGHT)) then
				ms = .4
			end

			moveData:SetForwardSpeed(mf * client:GetWalkSpeed()) 
			moveData:SetSideSpeed(ms * client:GetWalkSpeed()) 
		end
	end
end