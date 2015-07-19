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

local getModelClass = nut.anim.getModelClass
local IsValid = IsValid
local string = string
local type = type

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR

function GM:TranslateActivity(client, act)
	local model = string.lower(client.GetModel(client))
	local class = getModelClass(model)
	local weapon = client.GetActiveWeapon(client)

	if (class == "player") then
		if (!nut.config.get("wepAlwaysRaised") and IsValid(weapon) and !client.isWepRaised(client) and client.OnGround(client)) then
			if (string.find(model, "zombie")) then
				local tree = nut.anim.zombie

				if (string.find(model, "fast")) then
					tree = nut.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = weapon.HoldType or weapon.GetHoldType(weapon)
			holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"

			local tree = nut.anim.player[holdType]

			if (tree and tree[act]) then
				return tree[act]
			end
		end

		return self.BaseClass.TranslateActivity(self.BaseClass, client, act)
	end

	local tree = nut.anim[class]

	if (tree) then
		local subClass = "normal"

		if (client.InVehicle(client)) then
			local vehicle = client.GetVehicle(client)
			local class = vehicle:isChair() and "chair" or vehicle:GetClass()

			if (tree.vehicle and tree.vehicle[class]) then
				local act = tree.vehicle[class][1]
				local fixvec = tree.vehicle[class][2]
				--local fixang = tree.vehicle[class][3]

				if (fixvec) then
					client.ManipulateBonePosition(client, 0, fixvec)
				end

				if (type(act) == "string") then
					client.CalcSeqOverride = client.LookupSequence(client, act)

					return
				else
					return act
				end
			else
				act = tree.normal[ACT_MP_CROUCH_IDLE][1]

				if (type(act) == "string") then
					client.CalcSeqOverride = client:LookupSequence(act)
				end

				return
			end
		elseif (client.OnGround(client)) then
			client.ManipulateBonePosition(client, 0, vector_origin)

			if (IsValid(weapon)) then
				subClass = weapon.HoldType or weapon.GetHoldType(weapon)
				subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
			end

			if (tree[subClass] and tree[subClass][act]) then
				local act2 = tree[subClass][act][client.isWepRaised(client) and 2 or 1]

				if (type(act2) == "string") then
					client.CalcSeqOverride = client.LookupSequence(client, act2)

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

	if (itemTable.noBusiness) then
		return false
	end
	
	if (itemTable.factions) then
		local allowed = false

		if (type(itemTable.factions) == "table") then
			for k, v in pairs(itemTable.factions) do
				if (client:Team() == v) then
					allowed = true

					break
				end
			end
		elseif (client:Team() != itemTable.factions) then
			allowed = false
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.classes) then
		local allowed = false

		if (type(itemTable.classes) == "table") then
			for k, v in pairs(itemTable.classes) do
				if (client:getChar():getClass() == v) then
					allowed = true

					break
				end
			end
		elseif (client:getChar():getClass() == itemTable.classes) then
			allowed = true
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.flag) then
		if (!client:getChar():hasFlags(itemTable.flag)) then
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
			local holdType = weapon.HoldType or weapon:GetHoldType()
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

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(client, velocity)
	local eyeAngles = client.EyeAngles(client)
	local yaw = vectorAngle(velocity)[2]
	local normalized = normalizeAngle(yaw - eyeAngles[2])

	client.SetPoseParameter(client, "move_yaw", normalized)

	if (CLIENT) then
		client.SetIK(client, false)
	end

	local oldSeqOverride = client.CalcSeqOverride
	local seqIdeal, seqOverride = self.BaseClass.CalcMainActivity(self.BaseClass, client, velocity)
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
	local banned = char:getData("banned")

	if (banned) then
		if (type(banned) == "number" and banned < os.time()) then
			return
		end

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
			local speed = client:GetWalkSpeed()
			local ratio = nut.config.get("walkRatio")

			if (moveData:KeyDown(IN_FORWARD)) then
				mf = ratio
			elseif (moveData:KeyDown(IN_BACK)) then
				mf = -ratio
			end

			if (moveData:KeyDown(IN_MOVELEFT)) then
				ms = -ratio
			elseif (moveData:KeyDown(IN_MOVERIGHT)) then
				ms = ratio
			end

			moveData:SetForwardSpeed(mf * speed) 
			moveData:SetSideSpeed(ms * speed) 
		end
	end
end