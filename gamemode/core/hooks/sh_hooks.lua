
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

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR
local animationFixOffset = Vector(16.5438, -0.1642, -20.5493)

function GM:TranslateActivity(client, act)
	local clientInfo = client:GetTable()
	local modelClass = clientInfo.ixAnimModelClass or "player"
	local bRaised = client:IsWepRaised()

	if (modelClass == "player") then
		local weapon = client:GetActiveWeapon()
		local bAlwaysRaised = ix.config.Get("weaponAlwaysRaised")
		weapon = IsValid(weapon) and weapon or nil

		if (!bAlwaysRaised and weapon and !bRaised and client:OnGround()) then
			local model = string.lower(client:GetModel())

			if (string.find(model, "zombie")) then
				local tree = ix.anim.zombie

				if (string.find(model, "fast")) then
					tree = ix.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = weapon and (weapon.HoldType or weapon:GetHoldType()) or "normal"

			if (!bAlwaysRaised and weapon and !bRaised and client:OnGround()) then
				holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
			end

			local tree = ix.anim.player[holdType]

			if (tree and tree[act]) then
				if (isstring(tree[act])) then
					clientInfo.CalcSeqOverride = client:LookupSequence(tree[act])

					return
				else
					return tree[act]
				end
			end
		end

		return self.BaseClass:TranslateActivity(client, act)
	end

	if (clientInfo.ixAnimTable) then
		local glide = clientInfo.ixAnimGlide

		if (client:InVehicle()) then
			act = clientInfo.ixAnimTable[1]

			local fixVector = clientInfo.ixAnimTable[2]

			if (isvector(fixVector)) then
				client:SetLocalPos(animationFixOffset)
			end

			if (isstring(act)) then
				clientInfo.CalcSeqOverride = client:LookupSequence(act)
			else
				return act
			end
		elseif (client:OnGround()) then
			if (clientInfo.ixAnimTable[act]) then
				local act2 = clientInfo.ixAnimTable[act][bRaised and 2 or 1]

				if (isstring(act2)) then
					clientInfo.CalcSeqOverride = client:LookupSequence(act2)
				else
					return act2
				end
			end
		elseif (glide) then
			if (isstring(glide)) then
				clientInfo.CalcSeqOverride = client:LookupSequence(glide)
			else
				return clientInfo.ixAnimGlide
			end
		end
	end
end

function GM:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	if (!client:GetCharacter()) then
		return false
	end

	if (itemTable.noBusiness) then
		return false
	end

	if (itemTable.factions) then
		local allowed = false

		if (istable(itemTable.factions)) then
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

		if (istable(itemTable.classes)) then
			for _, v in pairs(itemTable.classes) do
				if (client:GetCharacter():GetClass() == v) then
					allowed = true

					break
				end
			end
		elseif (client:GetCharacter():GetClass() == itemTable.classes) then
			allowed = true
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.flag) then
		if (!client:GetCharacter():HasFlags(itemTable.flag)) then
			return false
		end
	end

	return true
end

function GM:DoAnimationEvent(client, event, data)
	local class = client.ixAnimModelClass

	if (class == "player") then
		return self.BaseClass:DoAnimationEvent(client, event, data)
	else
		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local animation = client.ixAnimTable

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

function GM:EntityRemoved(entity)
	if (SERVER) then
		entity:ClearNetVars()
	elseif (entity:IsWeapon()) then
		local owner = entity:GetOwner()

		-- GetActiveWeapon is the player's new weapon at this point so we'll assume
		-- that the player switched away from this weapon
		if (IsValid(owner) and owner:IsPlayer()) then
			hook.Run("PlayerWeaponChanged", owner, owner:GetActiveWeapon())
		end
	end
end

local function UpdatePlayerHoldType(client, weapon)
	weapon = weapon or client:GetActiveWeapon()
	local holdType = "normal"

	if (IsValid(weapon)) then
		holdType = weapon.HoldType or weapon:GetHoldType()
		holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType
	end

	client.ixAnimHoldType = holdType
end

local function UpdateAnimationTable(client, vehicle)
	local baseTable = ix.anim[client.ixAnimModelClass] or {}

	if (IsValid(client) and IsValid(vehicle)) then
		local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

		if (baseTable.vehicle and baseTable.vehicle[vehicleClass]) then
			client.ixAnimTable = baseTable.vehicle[vehicleClass]
		else
			client.ixAnimTable = baseTable.normal[ACT_MP_CROUCH_IDLE]
		end
	else
		client.ixAnimTable = baseTable[client.ixAnimHoldType]
	end

	client.ixAnimGlide = baseTable["glide"]
end

function GM:PlayerWeaponChanged(client, weapon)
	UpdatePlayerHoldType(client, weapon)
	UpdateAnimationTable(client)

	if (CLIENT) then
		return
	end

	-- update weapon raise state
	if (weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon:GetClass()]) then
		client:SetWepRaised(true, weapon)
		return
	elseif (weapon.IsAlwaysLowered or weapon.NeverRaised) then
		client:SetWepRaised(false, weapon)
		return
	end

	-- If the player has been forced to have their weapon lowered.
	if (client:IsRestricted()) then
		client:SetWepRaised(false, weapon)
		return
	end

	-- Let the config decide before actual results.
	if (ix.config.Get("weaponAlwaysRaised")) then
		client:SetWepRaised(true, weapon)
		return
	end

	client:SetWepRaised(false, weapon)
end

function GM:PlayerSwitchWeapon(client, oldWeapon, weapon)
	if (!IsFirstTimePredicted()) then
		return
	end

	-- the player switched weapon themself (i.e not through SelectWeapon), so we have to network it here
	if (SERVER) then
		net.Start("PlayerSelectWeapon")
			net.WriteEntity(client)
			net.WriteString(weapon:GetClass())
		net.Broadcast()
	end

	hook.Run("PlayerWeaponChanged", client, weapon)
end

function GM:PlayerModelChanged(client, model)
	client.ixAnimModelClass = ix.anim.GetModelClass(model)

	UpdateAnimationTable(client)
end

do
	local vectorAngle = FindMetaTable("Vector").Angle
	local normalizeAngle = math.NormalizeAngle

	function GM:CalcMainActivity(client, velocity)
		local clientInfo = client:GetTable()
		local forcedSequence = client:GetNetVar("forcedSequence")

		if (forcedSequence) then
			if (client:GetSequence() != forcedSequence) then
				client:SetCycle(0)
			end

			return -1, forcedSequence
		end

		client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity)[2] - client:EyeAngles()[2]))

		local sequenceOverride = clientInfo.CalcSeqOverride
		clientInfo.CalcSeqOverride = -1
		clientInfo.CalcIdeal = ACT_MP_STAND_IDLE

		-- we could call the baseclass function, but it's faster to do it this way
		local BaseClass = self.BaseClass

		if (BaseClass:HandlePlayerNoClipping(client, velocity) or
			BaseClass:HandlePlayerDriving(client) or
			BaseClass:HandlePlayerVaulting(client, velocity) or
			BaseClass:HandlePlayerJumping(client, velocity) or
			BaseClass:HandlePlayerSwimming(client, velocity) or
			BaseClass:HandlePlayerDucking(client, velocity)) then -- luacheck: ignore 542
		else
			local length = velocity:Length2DSqr()

			if (length > 22500) then
				clientInfo.CalcIdeal = ACT_MP_RUN
			elseif (length > 0.25) then
				clientInfo.CalcIdeal = ACT_MP_WALK
			end
		end

		clientInfo.m_bWasOnGround = client:OnGround()
		clientInfo.m_bWasNoclipping = (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle())

		return clientInfo.CalcIdeal, sequenceOverride or clientInfo.CalcSeqOverride or -1
	end
end

do
	local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

	function GM:StartCommand(client, command)
		if (!client:CanShootWeapon()) then
			command:RemoveKey(KEY_BLACKLIST)
		end
	end
end

function GM:CharacterVarChanged(char, varName, oldVar, newVar)
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

function GM:OnCharacterCreated(client, character)
	local faction = ix.faction.Get(character:GetFaction())

	if (faction and faction.OnCharacterCreated) then
		faction:OnCharacterCreated(client, character)
	end
end

function GM:GetDefaultCharacterName(client, faction)
	local info = ix.faction.indices[faction]

	if (info and info.GetDefaultName) then
		return info:GetDefaultName(client)
	end
end

function GM:CanPlayerUseCharacter(client, character)
	local banned = character:GetData("banned")

	if (banned) then
		if (isnumber(banned)) then
			if (banned < os.time()) then
				return
			end

			return false, "@charBannedTemp"
		end

		return false, "@charBanned"
	end

	local bHasWhitelist = client:HasWhitelist(character:GetFaction())

	if (!bHasWhitelist) then
		return false, "@noWhitelist"
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
	local bPickup = self.BaseClass:PhysgunPickup(client, entity)

	if (!bPickup and entity:IsPlayer() and (client:IsSuperAdmin() or client:IsAdmin() and !entity:IsSuperAdmin())) then
		bPickup = true
	end

	if (bPickup) then
		if (entity:IsPlayer()) then
			entity:SetMoveType(MOVETYPE_NONE)
		elseif (!entity.ixCollisionGroup) then
			entity.ixCollisionGroup = entity:GetCollisionGroup()
			entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		end
	end

	return bPickup
end

function GM:PhysgunDrop(client, entity)
	if (entity:IsPlayer()) then
		entity:SetMoveType(MOVETYPE_WALK)
	elseif (entity.ixCollisionGroup) then
		entity:SetCollisionGroup(entity.ixCollisionGroup)
		entity.ixCollisionGroup = nil
	end
end

do
	local TOOL_DANGEROUS = {}
	TOOL_DANGEROUS["dynamite"] = true
	TOOL_DANGEROUS["duplicator"] = true

	function GM:CanTool(client, trace, tool)
		if (client:IsAdmin()) then
			return true
		end

		if (TOOL_DANGEROUS[tool]) then
			return false
		end

		return self.BaseClass:CanTool(client, trace, tool)
	end
end

function GM:Move(client, moveData)
	local char = client:GetCharacter()

	if (char) then
		if (client:GetNetVar("actEnterAngle")) then
			moveData:SetForwardSpeed(0)
			moveData:SetSideSpeed(0)
			moveData:SetVelocity(vector_origin)
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

function GM:CanTransferItem(itemObject, curInv, inventory)
	if (SERVER) then
		local client = itemObject.GetOwner and itemObject:GetOwner() or nil

		if (IsValid(client) and curInv.GetReceivers) then
			local bAuthorized = false

			for _, v in ipairs(curInv:GetReceivers()) do
				if (client == v) then
					bAuthorized = true
					break
				end
			end

			if (!bAuthorized) then
				return false
			end
		end
	end

	-- we can transfer anything that isn't a bag
	if (!itemObject or !itemObject.isBag) then
		return
	end

	-- don't allow bags to be put inside bags
	if (inventory.id != 0 and curInv.id != inventory.id) then
		if (inventory.vars and inventory.vars.isBag) then
			local owner = itemObject:GetOwner()

			if (IsValid(owner)) then
				owner:NotifyLocalized("nestedBags")
			end

			return false
		end
	elseif (inventory.id != 0 and curInv.id == inventory.id) then
		-- we are simply moving items around if we're transferring to the same inventory
		return
	end

	inventory = ix.item.inventories[itemObject:GetData("id")]

	-- don't allow transferring items that are in use
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

function GM:CanPlayerEquipItem(client, item)
	return item.invID == client:GetCharacter():GetInventory():GetID()
end

function GM:CanPlayerUnequipItem(client, item)
	return item.invID == client:GetCharacter():GetInventory():GetID()
end

function GM:OnItemTransferred(item, curInv, inventory)
	local bagInventory = item.GetInventory and item:GetInventory()

	if (!bagInventory) then
		return
	end

	-- we need to retain the receiver if the owner changed while viewing as storage
	if (inventory.storageInfo and isfunction(curInv.GetOwner)) then
		bagInventory:AddReceiver(curInv:GetOwner())
	end
end

function GM:ShowHelp() end

function GM:PreGamemodeLoaded()
	hook.Remove("PostDrawEffects", "RenderWidgets")
	hook.Remove("PlayerTick", "TickWidgets")
	hook.Remove("RenderScene", "RenderStereoscopy")
end

function GM:PostGamemodeLoaded()
	baseclass.Set("ix_character", ix.meta.character)
	baseclass.Set("ix_inventory", ix.meta.inventory)
	baseclass.Set("ix_item", ix.meta.item)
end

if (SERVER) then
	util.AddNetworkString("PlayerVehicle")

	function GM:PlayerEnteredVehicle(client, vehicle, role)
		UpdateAnimationTable(client)

		net.Start("PlayerVehicle")
			net.WriteEntity(client)
			net.WriteEntity(vehicle)
			net.WriteBool(true)
		net.Broadcast()
	end

	function GM:PlayerLeaveVehicle(client, vehicle)
		UpdateAnimationTable(client)

		net.Start("PlayerVehicle")
			net.WriteEntity(client)
			net.WriteEntity(vehicle)
			net.WriteBool(false)
		net.Broadcast()
	end
else
	net.Receive("PlayerVehicle", function(length)
		local client = net.ReadEntity()
		local vehicle = net.ReadEntity()
		local bEntered = net.ReadBool()

		UpdateAnimationTable(client, bEntered and vehicle or false)
	end)
end
