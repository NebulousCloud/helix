
function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

-- luacheck: globals HOLDTYPE_TRANSLATOR
HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

-- luacheck: globals  PLAYER_HOLDTYPE_TRANSLATOR
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

local getModelClass = ix.anim.GetModelClass
local IsValid = IsValid
local string = string
local type = type

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR

function GM:TranslateActivity(client, act)
	local model = string.lower(client.GetModel(client))
	local modelClass = getModelClass(model) or "player"
	local weapon = client.GetActiveWeapon(client)

	if (modelClass == "player") then
		if (!ix.config.Get("wepAlwaysRaised") and IsValid(weapon) and !client.IsWepRaised(client) and client.OnGround(client)) then
			if (string.find(model, "zombie")) then
				local tree = ix.anim.zombie

				if (string.find(model, "fast")) then
					tree = ix.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = IsValid(weapon) and (weapon.HoldType or weapon.GetHoldType(weapon)) or "normal"

			if (!ix.config.Get("wepAlwaysRaised") and IsValid(weapon) and !client.IsWepRaised(client) and client:OnGround()) then
				holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
			end

			local tree = ix.anim.player[holdType]

			if (tree and tree[act]) then
				if (type(tree[act]) == "string") then
					client.CalcSeqOverride = client.LookupSequence(client, tree[act])

					return
				else
					return tree[act]
				end
			end
		end

		return self.BaseClass.TranslateActivity(self.BaseClass, client, act)
	end

	local tree = ix.anim[modelClass]

	if (tree) then
		local subClass = "normal"

		if (client.InVehicle(client)) then
			local vehicle = client.GetVehicle(client)
			local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

			if (tree.vehicle and tree.vehicle[vehicleClass]) then
				act = tree.vehicle[vehicleClass][1]
				local fixvec = tree.vehicle[vehicleClass][2]

				if (fixvec) then
					client:SetLocalPos(Vector(16.5438, -0.1642, -20.5493))
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
				local act2 = tree[subClass][act][client.IsWepRaised(client) and 2 or 1]

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
	local itemTable = ix.item.list[uniqueID]

	if (!client:GetChar()) then
		return false
	end

	if (itemTable.noBusiness) then
		return false
	end

	if (itemTable.factions) then
		local allowed = false

		if (type(itemTable.factions) == "table") then
			for _, v in pairs(itemTable.factions) do
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
			for _, v in pairs(itemTable.classes) do
				if (client:GetChar():GetClass() == v) then
					allowed = true

					break
				end
			end
		elseif (client:GetChar():GetClass() == itemTable.classes) then
			allowed = true
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.flag) then
		if (!client:GetChar():HasFlags(itemTable.flag)) then
			return false
		end
	end

	return true
end

function GM:DoAnimationEvent(client, event, data)
	local model = client:GetModel():lower()
	local class = ix.anim.GetModelClass(model)

	if (class == "player") then
		return self.BaseClass:DoAnimationEvent(client, event, data)
	else
		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local holdType = weapon.HoldType or weapon:GetHoldType()
			holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

			local animation = ix.anim[class][holdType]

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
	if (data.Entity.ixIsMuted) then
		return false
	end
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(client, velocity)
	client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity)[2] - client:EyeAngles()[2]))

	local oldSeqOverride = client.CalcSeqOverride
	local seqIdeal = self.BaseClass:CalcMainActivity(client, velocity)
	--client.CalcSeqOverride is being -1 after this line.

	if (client.ixForceSeq and client:GetSequence() != client.ixForceSeq) then
		client:SetCycle(0)
	end

	return seqIdeal, client.ixForceSeq or oldSeqOverride or client.CalcSeqOverride
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function GM:StartCommand(client, command)
	local isRaised, weapon = client:IsWepRaised()

	if (!isRaised and (!weapon or !weapon.FireWhenLowered)) then
		command:RemoveKey(KEY_BLACKLIST)
	end
end

function GM:OnCharVarChanged(char, varName, oldVar, newVar)
	if (ix.char.varHooks[varName]) then
		for _, v in pairs(ix.char.varHooks[varName]) do
			v(char, oldVar, newVar)
		end
	end
end

function GM:CanPlayerThrowPunch(client)
	if (!client:IsWepRaised()) then
		return false
	end

	return true
end

function GM:OnCharCreated(client, character)
	local faction = ix.faction.Get(character:GetFaction())

	if (faction and faction.OnCharCreated) then
		faction:OnCharCreated(client, character)
	end
end

function GM:GetDefaultCharName(client, faction)
	local info = ix.faction.indices[faction]

	if (info and info.GetDefaultName) then
		return info:GetDefaultName(client)
	end
end

function GM:CanPlayerUseChar(client, char)
	local banned = char:GetData("banned")

	if (banned) then
		if (type(banned) == "number" and banned < os.time()) then
			return false, L("charBanned", os.date("%H:%M:%S - %d/%m/%Y", banned))
		end

		return false, L("charBanned", "Never")
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
	local bPickup = false

	if (client:IsSuperAdmin()) then
		bPickup = true
	elseif (client:IsAdmin() and !(entity:IsPlayer() and entity:IsSuperAdmin())) then
		bPickup = true
	elseif (self.BaseClass:PhysgunPickup(client, entity) == false) then
		return false
	end

	if (bPickup and entity:IsPlayer()) then
		entity:SetMoveType(MOVETYPE_NONE)
	end

	return bPickup
end

function GM:PhysgunDrop(client, entity)
	if (entity:IsPlayer()) then
		entity:SetMoveType(MOVETYPE_WALK)
	end
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
	local char = client:GetChar()

	if (char) then
		if (client:GetNetVar("actAng")) then
			moveData:SetForwardSpeed(0)
			moveData:SetSideSpeed(0)
			moveData:SetVelocity(Vector(0, 0, 0))
		end

		if (client:GetMoveType() == MOVETYPE_WALK and moveData:KeyDown(IN_WALK)) then
			local mf, ms = 0, 0
			local speed = client:GetWalkSpeed()
			local ratio = ix.config.Get("walkRatio")

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

function GM:CanItemBeTransfered(itemObject, curInv, inventory)
	if (itemObject and itemObject.isBag) then
		if (inventory.id != 0 and curInv.id != inventory.id) then
			if (inventory.vars and inventory.vars.isBag) then
				local owner = itemObject:GetOwner()

				if (IsValid(owner)) then
					owner:NotifyLocalized("nestedBags")
				end

				return false
			end
		elseif (inventory.id != 0 and curInv.id == inventory.id) then
			return
		end

		inventory = ix.item.inventories[itemObject:GetData("id")]

		if (inventory) then
			for _, v in pairs(inventory:GetItems()) do
				if (v:GetData("equip") == true) then
					local owner = itemObject:GetOwner()

					if (owner and IsValid(owner)) then
						owner:NotifyLocalized("equippedBag")
					end

					return false
				end
			end
		end
	end
end

function GM:ShowHelp() end

function GM:PreGamemodeLoaded()
	hook.Remove("PostDrawEffects", "RenderWidgets")
	hook.Remove("PlayerTick", "TickWidgets")
end

function GM:PostGamemodeLoaded()
	baseclass.Set("ix_character", ix.meta.character)
	baseclass.Set("ix_inventory", ix.meta.inventory)
	baseclass.Set("ix_item", ix.meta.item)
end
