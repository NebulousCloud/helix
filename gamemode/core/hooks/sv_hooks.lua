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

function GM:PlayerInitialSpawn(client)
	client.nutJoinTime = RealTime()
	
	if (client:IsBot()) then
		local index = math.random(1, table.Count(nut.faction.indices))
		local faction = nut.faction.indices[index]

		local character = nut.char.new({
			name = client:Name(),
			faction = faction and faction.uniqueID or "unknown",
			model = faction and table.Random(faction.models) or "models/gman.mdl"
		}, os.time(), client, client:SteamID64())
		character.isBot = true
		nut.char.loaded[os.time()] = character

		client:Spawn()
		character:setup()

		return
	end

	nut.config.send(client)

	client:loadNutData(function(data)
		if (!IsValid(client)) then return end

		netstream.Start(client, "nutDataSync", data)
		
		nut.char.restore(client, function(charList)
			if (!IsValid(client)) then return end
			
			MsgN("Loaded ("..table.concat(charList, ", ")..") for "..client:Name())

			for k, v in ipairs(charList) do
				nut.char.loaded[v]:sync(client)
			end

			for k, v in ipairs(player.GetAll()) do
				if (v:getChar()) then
					v:getChar():sync(client)
				end
			end

			client.nutCharList = charList
				netstream.Start(client, "charMenu", charList)
			client.nutLoaded = true

			client:setNutData("intro", true)
		end)
	end)

	client:SetNoDraw(true)

	timer.Simple(1, function()
		if (!IsValid(client)) then return end
		
		client:KillSilent()
	end)
end

function GM:PlayerUse(client, entity)
	if (entity:isDoor()) then
		local result = hook.Run("CanPlayerUseDoor", client, entity)

		if (result == false) then
			return false
		else
			hook.Run("PlayerUseDoor", client, entity)
		end
	end

	return true
end

function GM:KeyPress(client, key)
	if (key == IN_RELOAD) then
		timer.Create("nutToggleRaise"..client:SteamID(), 1, 1, function()
			if (IsValid(client)) then
				client:toggleWepRaised()
			end
		end)
	elseif (key == IN_USE) then
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local entity = util.TraceLine(data).Entity

		if (IsValid(entity) and entity:isDoor()) then
			hook.Run("PlayerUse", client, entity)
		end
	end
end

function GM:KeyRelease(client, key)
	if (key == IN_RELOAD) then
		timer.Remove("nutToggleRaise"..client:SteamID())
	end
end

function GM:CanPlayerInteractItem(client, action, item)
	if (action == "drop" and hook.Run("CanPlayerDropItem", client, item) == false) then
		return false
	end

	if (action == "take" and hook.Run("CanPlayerTakeItem", client, item) == false) then
		return false
	end

	return client:Alive()
end

function GM:CanPlayerTakeItem(client, item)
	if (type(item) == "Entity") then
		local char = client:getChar()
		
		if (item.prevOwner and item.prevPlayer and item.prevPlayer == client and item.prevOwner != char.id) then
			client:notify(L("playerCharBelonging", client))

			return false
		end
	end
end

function GM:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
	client:setWepRaised(false)
end

function GM:PlayerShouldTakeDamage(client, attacker)
	return client:getChar() != nil
end

function GM:GetFallDamage(client, speed)
	return (speed - 580) * (100 / 444)
end

function GM:EntityTakeDamage(entity, dmgInfo)
	if (IsValid(entity.nutPlayer)) then
		if (dmgInfo:IsDamageType(DMG_CRUSH)) then
			if ((entity.nutFallGrace or 0) < CurTime()) then
				if (dmgInfo:GetDamage() <= 10) then
					dmgInfo:SetDamage(0)
				end

				entity.nutFallGrace = CurTime() + 0.5
			else
				return
			end
		end

		entity.nutPlayer:TakeDamageInfo(dmgInfo)
	end
end

function GM:PlayerLoadedChar(client, character, lastChar)
	if (lastChar) then
		local charEnts = lastChar:getVar("charEnts") or {}

		for k, v in ipairs(charEnts) do
			if (v and IsValid(v)) then
				v:Remove()
			end
		end

		lastChar:setVar("charEnts", nil) 
	end

	if (character) then
		for k, v in pairs(nut.class.list) do
			if (v.faction == client:Team()) then
				if (v.isDefault) then
					character:setClass(v.index)

					break
				end
			end
		end
	end

	if (IsValid(client.nutRagdoll)) then
		client.nutRagdoll.nutNoReset = true
		client.nutRagdoll.nutIgnoreDelete = true
		client.nutRagdoll:Remove()
	end

	hook.Run("PlayerLoadout", client)
end

function GM:CharacterLoaded(id)
	local character = nut.char.loaded[id]

	if (character) then
		local client = character:getPlayer()

		if (IsValid(client)) then
			local uniqueID = "nutSaveChar"..client:SteamID()

			timer.Create(uniqueID, nut.config.get("saveInterval"), 0, function()
				if (IsValid(client) and client:getChar()) then
					client:getChar():save()
				else
					timer.Remove(uniqueID)
				end
			end)
		end
	end
end

function GM:PlayerSay(client, message)
	local chatType, message, anonymous = nut.chat.parse(client, message, true)

	if (chatType == "ic") then
		if (nut.command.parse(client, message)) then
			return ""
		end
	end

	nut.chat.send(client, chatType, hook.Run("PlayerMessageSend", client, chatType, message, anonymous) or message, anonymous)
	hook.Run("PostPlayerSay", client, message, chatType, anonymous)

	return ""
end

function GM:PlayerSpawn(client)
	client:SetNoDraw(false)
	client:setAction()
	hook.Run("PlayerLoadout", client)
end

-- Shortcuts for (super)admin only things.
local IsAdmin = function(_, client) return client:IsAdmin() end

-- Set the gamemode hooks to the appropriate shortcuts.
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnNPC = IsAdmin
GM.PlayerSpawnSENT = IsAdmin
GM.PlayerSpawnVehicle = IsAdmin

function GM:PlayerSpawnProp(client)
	if (client:getChar() and client:getChar():hasFlags("e")) then
		return true
	end

	return false
end

function GM:PlayerSpawnRagdoll(client)
	if (client:getChar() and client:getChar():hasFlags("r")) then
		return true
	end

	return false
end

-- Called when weapons should be given to a player.
function GM:PlayerLoadout(client)
	if (client.nutSkipLoadout) then
		client.nutSkipLoadout = nil

		return
	end
	
	client:SetWeaponColor(Vector(client:GetInfo("cl_weaponcolor")))
	client:StripAmmo()
	client:StripWeapons()
	client:setLocalVar("blur", nil)

	local character = client:getChar()

	-- Check if they have loaded a character.
	if (character) then
		client:SetupHands()
		-- Set their player model to the character's model.
		client:SetModel(character:getModel())
		client:Give("nut_hands")
		client:SelectWeapon("nut_hands")
		client:SetWalkSpeed(nut.config.get("walkSpeed"))
		client:SetRunSpeed(nut.config.get("runSpeed"))
		
		local faction = nut.faction.indices[client:Team()]

		if (faction) then
			-- If their faction wants to do something when the player spawns, let it.
			if (faction.onSpawn) then
				faction:onSpawn(client)
			end

			-- If the faction has default weapons, give them to the player.
			if (faction.weapons) then
				for k, v in ipairs(faction.weapons) do
					client:Give(v)
				end
			end
		end

		-- Apply any flags as needed.
		nut.flag.onSpawn(client)
		nut.attribs.setup(client)

		hook.Run("PostPlayerLoadout", client)
	end
end

function GM:PostPlayerLoadout(client)
	-- Reload All Attrib Boosts
	local char = client:getChar()

	if (char:getInv()) then
		for k, v in pairs(char:getInv():getItems()) do
			if (v:getData("equip")) then
				if (v.attribBoosts) then
					for k, v in pairs(v.attribBoosts) do
						char:addBoost(v.uniqueID, k, v)
					end
				end

				if (v.isWeapon) then
					client.carryWeapons = {}

					local weapon = client:Give(v.class)

					if (IsValid(weapon)) then
						local ammo = v:getData("ammo")

						client.carryWeapons[v.weaponCategory] = weapon

						local count = weapon:Clip1()
						local ammoType = weapon:GetPrimaryAmmoType()

						if (client:GetAmmoCount(ammoType) >= count) then
							client:RemoveAmmo(count, ammoType)
						end

						if (ammo) then
							weapon:SetClip1(ammo)
						end
					else
						print(Format("[Nutscript] Weapon %s does not exist!", v.class))
					end
				end
			end
		end
	end
end

local deathSounds = {
	Sound("vo/npc/male01/pain07.wav"),
	Sound("vo/npc/male01/pain08.wav"),
	Sound("vo/npc/male01/pain09.wav")
}

function GM:PlayerDeath(client, inflictor, attacker)
	if (IsValid(client.nutRagdoll)) then
		client.nutRagdoll.nutIgnoreDelete = true
		client.nutRagdoll:Remove()
		client:setLocalVar("blur", nil)
	end

	client:setNetVar("deathStartTime", CurTime())
	client:setNetVar("deathTime", CurTime() + nut.config.get("spawnTime", 5))

	local deathSound = hook.Run("GetPlayerDeathSound", client) or table.Random(deathSounds)

	if (client:isFemale() and !deathSound:find("female")) then
		deathSound = deathSound:gsub("male", "female")
	end

	client:EmitSound(deathSound)
end

local painSounds = {
	Sound("vo/npc/male01/pain01.wav"),
	Sound("vo/npc/male01/pain02.wav"),
	Sound("vo/npc/male01/pain03.wav"),
	Sound("vo/npc/male01/pain04.wav"),
	Sound("vo/npc/male01/pain05.wav"),
	Sound("vo/npc/male01/pain06.wav")
}

local drownSounds = {
	Sound("player/pl_drown1.wav"),
	Sound("player/pl_drown2.wav"),
	Sound("player/pl_drown3.wav"),
}

function GM:GetPlayerPainSound(client)
	if (client:WaterLevel() >= 3) then
		return table.Random(drownSounds)
	end
end

function GM:PlayerHurt(client, attacker, health, damage)
	if ((client.nutNextPain or 0) < CurTime()) then
		local painSound = hook.Run("GetPlayerPainSound", client) or table.Random(painSounds)

		if (client:isFemale() and !painSound:find("female")) then
			painSound = painSound:gsub("male", "female")
		end

		client:EmitSound(painSound)
		client.nutNextPain = CurTime() + 0.33
	end
end

function GM:PlayerDeathThink(client)
	local deathTime = client:getNetVar("deathTime")

	if (deathTime and deathTime <= CurTime()) then
		client:Spawn()
	end

	return false
end

function GM:PlayerDisconnected(client)
	client:saveNutData()

	local character = client:getChar()

	if (character) then
		local charEnts = character:getVar("charEnts") or {}

		for k, v in ipairs(charEnts) do
			if (v and IsValid(v)) then
				v:Remove()
			end
		end

		character:save()
	end
end

function GM:InitPostEntity()
	local doors = ents.FindByClass("prop_door_rotating")

	for k, v in ipairs(doors) do
		local parent = v:GetOwner()

		if (IsValid(parent)) then
			v.nutPartner = parent
			parent.nutPartner = v
		else
			for k2, v2 in ipairs(doors) do
				if (v2:GetOwner() == v) then
					v2.nutPartner = v
					v.nutPartner = v2

					break
				end
			end
		end
	end

	timer.Simple(0.1, function()
		hook.Run("LoadData")
	end)
end

function GM:ShutDown()
	nut.shuttingDown = true
	nut.config.save()

	hook.Run("SaveData")

	for k, v in ipairs(player.GetAll()) do
		if (v:getChar()) then
			v:getChar():save()
		end
	end
end

LIMB_GROUPS = {}
LIMB_GROUPS[HITGROUP_LEFTARM] = true
LIMB_GROUPS[HITGROUP_RIGHTARM] = true
LIMB_GROUPS[HITGROUP_LEFTLEG] = true
LIMB_GROUPS[HITGROUP_RIGHTLEG] = true
LIMB_GROUPS[HITGROUP_GEAR] = true

function GM:ScalePlayerDamage(client, hitGroup, dmgInfo)
	dmgInfo:ScaleDamage(1.5)

	if (hitGroup == HITGROUP_HEAD) then
		dmgInfo:ScaleDamage(7)
	elseif (LIMB_GROUPS[hitGroup]) then
		dmgInfo:ScaleDamage(0.5)
	end
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end

function GM:OnPlayerUseBusiness(client, item)
	-- You can manipulate purchased items with this hook.
	-- does not requires any kind of return.
	-- ex) item:setData("businessItem", true)
	-- then every purchased item will be marked as Business Item.
end

function GM:PlayerDeathSound()
	return true
end

function GM:Think()
	for k, v in ipairs(player.GetAll()) do
		if (v:getChar() and v:Alive() and hook.Run("ShouldPlayerDrowned", v) != false) then
			if (v:WaterLevel() >= 3) then
				if (!v.drowningTime) then
					v.drowningTime = CurTime() + 30
					v.nextDrowning = CurTime()
					v.drownDamage = v.drownDamage or 0
				end

				if (v.drowningTime < CurTime()) then
					if (v.nextDrowning < CurTime()) then
						v:ScreenFade(1, Color(0, 0, 255, 100), 1, 0)
						v:TakeDamage(10)
						v.drownDamage = v.drownDamage + 10
						v.nextDrowning = CurTime() + 1
					end
				end
			else
				if (v.drowningTime) then
					v.drowningTime = nil
					v.nextDrowning = nil
					v.nextRecover = CurTime() + 2
				end

				if (v.nextRecover and v.nextRecover < CurTime() and v.drownDamage > 0) then
					v.drownDamage = v.drownDamage - 10
					v:SetHealth(math.Clamp(v:Health() + 10, 0, v:GetMaxHealth()))
					v.nextRecover = CurTime() + 1
				end
			end
		end
	end
end

function GM:CanItemBeTransfered(itemObject, curInv, inventory)
	if (itemObject.isBag) then
		local inventory = nut.item.inventories[itemObject:getData("id")]

		if (inventory) then
			for k, v in pairs(inventory:getItems()) do
				if (v:getData("equip") == true) then
					local owner = itemObject:getOwner()
					if (owner and IsValid(owner)) then
						owner:notify(L("equippedBag", owner))
					end

					return false
				end
			end
		end
	end
end

netstream.Hook("strReq", function(client, time, text)
	if (client.nutStrReqs and client.nutStrReqs[time]) then
		client.nutStrReqs[time](text)
		client.nutStrReqs[time] = nil
	end
end)