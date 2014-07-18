function GM:ShowHelp(client)
	-- Keep this here since the spawn menu will open by default.
end

function GM:PlayerInitialSpawn(client)
	client:SetNoDraw(true)

	if (client:IsBot()) then
		hook.Run("OnLocalPlayerValid", client)
	else
		netstream.Start(client, "nut_LoadingData", "Waiting for local player.")
	end
end

function GM:OnLocalPlayerValid(client, steamID, uniqueID)
	netstream.Start(client, "nut_LoadingData", "Sending current time.")
	netstream.Start(client, "nut_CurTime", nut.util.GetTime())

	client:KillSilent()
	client:StripWeapons()

	netstream.Start(client, "nut_LoadingData", "Initializing player data.")
	client:InitializeData()

	player_manager.SetPlayerClass(client, "player_nut")
	player_manager.RunClass(client, "Spawn")

	netstream.Start(client, "nut_LoadingData", "Loading characters.")
	nut.char.Load(client, function()
		netstream.Start(client, "nut_LoadingData", "Loading other characters.")

		local total = 0
		local time = 0.1

		for k, v in pairs(player.GetAll()) do
			if (v.character and v != client) then
				total = total + 1
			end
		end

		local i = 0

		for k, v in pairs(player.GetAll()) do
			if (v.character and v != client) then
				local fraction = math.max(client:Ping() / 100, 0.0001) + 0.00025
				time = time + fraction

				timer.Simple(k * fraction, function()
					if (IsValid(client) and IsValid(v)) then
						i = i + 1

						netstream.Start(client, "nut_LoadingData", "Networking characters... "..math.Round((i / total) * 100).."%")
						v.character:Send(nil, client, true)
					end
				end)
			end
		end

		netstream.Start(client, "nut_CharMenu")

		local uniqueID = "nut_SaveChar"..client:SteamID()

		timer.Create(uniqueID, nut.config.saveInterval, 0, function()
			if (!IsValid(client)) then
				timer.Remove(uniqueID)

				return
			end

			nut.char.Save(client)
		end)

		if (client:IsBot()) then
			local character = nut.char.New(client)
				character:SetVar("charname", client:Name())

				for index, _ in RandomPairs(nut.faction.buffer) do
					character.faction = index
					client:SetTeam(index)

					break
				end

				local factionTable = nut.faction.GetByID(character.faction)

				character.model = table.Random(factionTable.maleModels)
				character.index = 1
				character.skin = 0
			client.character = character
			character:Send()
		end
	end)
end

-- Purpose: Called after a character is loaded, but the player has not spawned yet.
function GM:PlayerLoadedChar(client)
	local faction = client.character:GetVar("faction", 9001)
	client:SetTeam(faction)
	client:SetSkin(client.character:GetData("skin", 0))

	client.character:SetVar("id", math.floor(client.character:GetData("id", os.clock() + client:UniqueID())))

	local customClass = client.character:GetData("customClass")

	if (customClass and customClass != "") then
		client:SetNetVar("customClass", customClass)
	else
		client:SetNetVar("customClass", nil)
	end

	if (!client:GetNutVar("sawCredits")) then
		hook.Run("PlayerFirstLoaded", client)
		client:SetNutVar("sawCredits", true)

		nut.util.SendIntroFade(client)

		timer.Simple(15, function()
			if (!IsValid(client)) then
				return
			end
			
			nut.scroll.Send("NutScript: "..nut.lang.Get("schema_author", "Chessnut and rebel1324"), client, function()
				if (IsValid(client)) then
					nut.scroll.Send(SCHEMA.name..": "..nut.lang.Get("schema_author", SCHEMA.author), client)
				end
			end)
		end)
	end
end

function GM:PlayerShouldTaunt(client, act)
	return nut.config.allowTaunts
end

function GM:PlayerSpawn(client)
	client:UnRagdoll(true)
	client:SetNoDraw(false)
	client:SetRenderMode(4)
	client:SetColor(Color(255, 255, 255))
	client:SetNetVar("drunk", 0)
	client:SetNetVar("tied", false)
	client:SetNetVar("noDepress", 0)
	client:SetNetVar("blur", 0)
	client:ScreenFadeOut()
	client:SetMainBar()
	
	if (!client.character) then
		return
	end

	client:StripWeapons()
	client:SetModel(client.character.model or "models/player.mdl")

	if (nut.config.nutFists) then
		client:Give("nut_fists")
	end

	player_manager.SetPlayerClass(client, "player_nut")
	player_manager.RunClass(client, "Spawn")

	client:SetWalkSpeed(nut.config.walkSpeed)
	client:SetRunSpeed(nut.config.runSpeed)
	client:SetWepRaised(false)

	local groups = client.character:GetData("groups", {})

	for k, v in pairs(groups) do
		client:SetBodygroup(k, v)
	end

	hook.Run("PlayerLoadout", client)
	
	nut.flag.OnSpawn(client)
	nut.attribs.OnSpawn(client)

	local index = client:CharClass()

	if (index) then
		local classTable = nut.class.Get(index)

		if (classTable and classTable.OnSpawn) then
			classTable:OnSpawn(client)
		end
	end
end

function GM:PlayerDisconnected(client)
	nut.char.Save(client)

	timer.Remove("nut_SaveChar"..client:SteamID())
end

function GM:PlayerSpray(client)
	return false
end

function GM:PlayerShouldTakeDamage()
	return true
end

function GM:CanArmDupe()
	return false
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end

function GM:GetFallDamage(client, speed)
	speed = speed - 580

	return speed * nut.config.fallDamageScale
end

function GM:ShutDown()
	MsgN("NutScript is shutting down...")

	nut.shuttingDown = true

	for k, v in pairs(player.GetAll()) do
		nut.char.Save(v)
	end

	self:SaveTime()
	hook.Run("SaveData")
end

function GM:PlayerSay(client, text, public)
	local result = nut.chat.Process(client, text)

	if (result) then
		return result
	end
	
	return text
end

function GM:CanPlayerSuicide(client)
	return nut.config.canSuicide
end

function GM:PlayerGiveSWEP(client, class, weapon)
	return client:IsAdmin()
end

function GM:PlayerSpawnSWEP(client, class, weapon)
	return client:IsAdmin()
end

function GM:PlayerSpawnEffect(client, model)
	return client:HasFlag("e")
end

function GM:PlayerSpawnNPC(client, npc, weapon)
	return client:HasFlag("n")
end

function GM:PlayerSpawnObject(client)
	return client:HasFlag("e") or client:HasFlag("r")
end

function GM:PlayerSpawnProp(client, model)
	return client:HasFlag("e")
end

function GM:PlayerSpawnRagdoll(client, model, entity)
	return client:HasFlag("r")
end

function GM:PlayerSpawnSENT(client)
	return client:IsAdmin()
end

function GM:PlayerSpawnVehicle(client, model, name, vehicle)
	return client:HasFlag("c")
end

function GM:PlayerSpawnedProp(client, model, entity)
	entity:SetCreator(client)
end

function GM:PlayerSpawnedRagdoll(client, model, entity)
	entity:SetCreator(client)
end

function GM:PlayerSpawnedSENT(client, entity)
	entity:SetCreator(client)
end

function GM:PlayerSpawnedVehicle(client, entity)
	entity:SetCreator(client)
end

function GM:PlayerSwitchFlashlight(client, state)
	if (!client:CanUseFlashlight()) then
		return false
	end
	
	if (nut.config.flashlight) then
		return true
	end

	return false
end

function GM:RemoveEntitiesByClass(class)
	for k, v in pairs(ents.FindByClass(class)) do
		SafeRemoveEntity(v)
	end
end

function GM:InitPostEntity()
	hook.Run("LoadData")

	if (nut.config.clearMaps) then
		self:RemoveEntitiesByClass("item_healthcharger")
		self:RemoveEntitiesByClass("prop_vehicle*")
		self:RemoveEntitiesByClass("weapon_*")
		self:RemoveEntitiesByClass("item_suitcharger")
	end
end

local limbs = {}
limbs[HITGROUP_GEAR] = true
limbs[HITGROUP_RIGHTARM] = true
limbs[HITGROUP_LEFTLEG] = true
limbs[HITGROUP_RIGHTLEG] = true

function GM:ScalePlayerDamage(client, hitGroup, damageInfo)
	if (hitGroup < 2 and damageInfo:IsBulletDamage()) then
		damageInfo:ScaleDamage(10)
	elseif (limbs[hitGroup]) then
		damageInfo:ScaleDamage(0.75)
	end
end

function GM:PlayerDeath(victim, weapon, attacker)
	local time = CurTime() + nut.config.deathTime
	time = hook.Run("PlayerGetDeathTime", client, time) or time

	
	victim:SetNutVar("deathTime", time)

	timer.Simple(0, function()
		victim:SetMainBar("You are now respawning.", nut.config.deathTime)
		victim:ScreenFadeIn(nut.config.deathTime * 0.25)
	end)
	if (attacker:IsPlayer()) then
		nut.util.AddLog(Format("%s(%s) killed by %s(%s) with %s.", victim:Name(), victim:SteamID(), attacker:Name(), attacker:SteamID(), weapon:GetClass()), LOG_FILTER_MAJOR)
	else
		nut.util.AddLog(Format("%s(%s) killed by %s.", victim:Name(), victim:SteamID(), attacker:GetClass()), LOG_FILTER_MAJOR)
	end
end

function GM:PlayerDeathSound(client)
	client:EmitSound("vo/npc/"..client:GetGender().."01/pain0"..math.random(7, 9)..".wav")

	return true
end

function GM:PlayerHurt(client, attacker, health, damage)
	if (health <= 0) then
		return true
	end

	client:EmitSound(hook.Run("PlayerPainSound", client) or "vo/npc/"..client:GetGender().."01/pain0"..math.random(1, 6)..".wav")

	return true
end

function GM:PlayerDeathThink(client)
	if (client.character and client:GetNutVar("deathTime", 0) < CurTime()) then
		client:Spawn()

		return true
	end
	
	return false
end

function GM:PlayerCanHearPlayersVoice(speaker, listener)
	return nut.config.allowVoice, nut.config.voice3D
end

function GM:PlayerGetFistDamage(client, damage)
	return damage + (client:GetAttrib(ATTRIB_STR, 0) * 0.2)
end

function GM:PlayerThrowPunch(client, attempted)
	local value = 0.001

	if (attempted) then
		value = 0.005
	end

	client:UpdateAttrib(ATTRIB_STR, value)
end

function GM:OnPlayerHitGround(client, inWater, onFloater, fallSpeed)
	if (!inWater and !onFloater) then
		client:UpdateAttrib(ATTRIB_ACR, 0.005)
	end
end

function GM:SaveTime()
	nut.util.WriteTable("date", tostring(nut.util.GetTime()), true)
end

function GM:PlayerUse(client, entity)
	if (entity.NoUse or client:GetNetVar("tied")) then
		if (client:GetNetVar("tied") and SERVER and client:GetNutVar("nextTieMsg", 0) < CurTime()) then
			nut.util.Notify("You can not do this when tied.", client)
			client:SetNutVar("nextTieMsg", CurTime() + 1)
		end

		return false
	end

	return true
end

function GM:KeyPress(client, key)
	local config = nut.config

	if (key == IN_USE) then
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 56
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and client:GetNetVar("tied")) then
			if (client:GetNutVar("nextTieMsg", 0) < CurTime() and SERVER) then
				nut.util.Notify("You can not do this when tied.", client)
				client:SetNutVar("nextTieMsg", CurTime() + 1)
			end

			return false
		end

		if (IsValid(entity) and entity:IsDoor()) then
			if (hook.Run("PlayerCanUseDoor", client, entity) == false) then
				return
			end

			return hook.Run("PlayerUseDoor", client, entity)
		elseif (entity:IsPlayer()) then
			return hook.Run("PlayerInteract", client, entity)
		end
	elseif (config.holdReloadToToggle and key == IN_RELOAD) then
		timer.Create("nut_ToggleTime"..client:UniqueID(), config.holdReloadTime, 1, function()
			nut.command.SetShowCommandRan(true)
				nut.command.RunCommand(client, "toggleraise", {})
			nut.command.SetShowCommandRan(false)
		end)
	end
end

function GM:KeyRelease(client, key)
	if (key == IN_RELOAD) then
		timer.Remove("nut_ToggleTime"..client:UniqueID())
	end
end

-- Purpose: Called after a new money entity has been created by nut.currency.Spawn()
function GM:MoneyEntityCreated(entity) end

-- Purpose: Called after a money entity has been used, return false to disallow pickup.
function GM:PlayerCanPickupMoney(client, entity) return true end

-- Purpose: Called before knocking, return false to disallow knocking.
function GM:PlayerCanKnock(client, door) return true end

-- Purpose: Called to adjust the roll amount. Useful for perks that give extra roll points.
function GM:GetRollAmount(client, amount) return amount end

-- Purpose: Called in the fallover command to determine if a player is allowed to fall over.
function GM:CanFallOver(client) return true end

-- Purpose: Called to see if the nut_FadeIntro net message should be sent to a player.
function GM:PlayerShouldSeeIntro(client) return true end

-- Purpose: Called after a clothing item has been put on or taken off.
function GM:OnClothEquipped(client, itemTable, equipped) end

-- Purpose: Called after a part item has been put on or taken off.
function GM:OnPartEquipped(client, itemTable, equipped) end

-- Purpose: Called after a weapon has been equipped or holstered.
function GM:OnWeaponEquipped(client, itemTable, equipped) end

-- Purpose: Called after the attribute data for a character has been changed.
function GM:PlayerAttribUpdated(client, attribute, change, value) end

-- Purpose: Called before a character has been saved to the database.
function GM:CharacterSave(client) end

--[[
	Purpose: Called once a new character is being created and the inventory is being set up.
	The inventory table provided has a function: inventory:Add(uniqueID, amount, data)
	The :Add() method functions just like client:UpdateInv(uniqueID, amount, data)
--]]
function GM:GetDefaultInv(inventory) end

-- Purpose: Called after the inventory has been set up to adjust the default money.
function GM:GetDefaultMoney(amount) return nut.config.startingAmount end

-- Purpose: Called after a new database has been inserted into the database and
-- networked to the creator of the character.
function GM:PlayerCreatedChar(client, data) end

-- Purpose: Called after a player has spawned with a character.
function GM:PostPlayerSpawn(client) end

-- Purpose: Called to see if a chat mode is allowed to be used. Results are returned
-- to the player say hook.
function GM:ChatClassCanSay(class, structure, speaker) end

-- Purpose: Called when the chat box text has been updated.
function GM:PlayerTyping(client, text) end

-- Purpose: Called to modify what a player is typing.
function GM:PrePlayerSay(client, text, mode, listeners) return text end

-- Purpose: Called after a player has chosen to be in a class. Return false to disallow.
function GM:PlayerCanJoinClass(client, class) return true end

-- Purpose: Called before a player's class has been set.
function GM:PlayerPreJoinClass(client, class) end

-- Purpose: Calledafter a player's class has been set.
function GM:PlayerPostJoinClass(client, class) end

-- Purpose: Called once the non-character data for a player has been retrieved from
-- the database. This includes whitelists and misc. data.
function GM:PlayerLoadedData(client) end

-- Purpose: Whether or not a player can receive their faction pay. Return false to
-- disallow their pay.
function GM:ShouldReceivePay(client) return true end

-- Purpose: Called after the schema files have been included.
function GM:SchemaInitialized() end

-- Purpose: Called after a physical item is made.
function GM:OnItemDropped(client, itemTable, entity) end

-- Purpose: Called once a physical item has been picked up.
function GM:OnItemTaken(item) end

-- Purpose: Called to see if an item is allowed to be used. Return false to prevent use.
function GM:PlayerCanUseItem(client, itemTable) return true end

-- Purpose: Used to get the default item data to match business menu display. Return nothing
-- to have no default data.
function GM:GetBusinessItemData(client, itemTable, data) end

-- Purpose: Called after an item has been purchased from the business menu.
function GM:PlayerBoughtItem(client, itemTable) end

-- Purpose: Called in the act plugin to see if an act is allowed to be started.
-- Return false to prevent the act.
function GM:CanStartSeq(client) return true end

-- Purpose: Called in the area display plugin when a player has entered a new area.
function GM:PlayerEnterArea(client, area, entities) end

-- Purpose: Called by the item saving plugin when an item has been restored from data.
function GM:ItemRestored(itemTable, entity) end

-- Purpose: Called by the item saving plugin to see if a physical item should save.
function GM:ItemShouldSave(entity) end

-- Purpose: Called by the item saving plugin after a physical item has been saved.
function GM:ItemSaved(entity) end

-- Purpose: Called by the stamina plugin after a player has lost all of their stamina.
function GM:PlayerLostStamina(client) end

-- Purpose: Called to see if breathing noises should be played after all stamina has
-- been lost.
function GM:PlayerShouldBreathe(client) return true end

-- Purpose: Called by the storage plugin after an item has been moved.
function GM:OnItemTransfered(client, storage, itemTable) end

netstream.Hook("nut_LocalPlayerValid", function(client)
	if (!client:GetNutVar("validated")) then
		hook.Run("OnLocalPlayerValid", client)
		client:SetNutVar("validated", true)
	end
end)