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
		}, -1, client, client:SteamID64())
		character.isBot = true
		nut.char.loaded[-1] = character

		client:Spawn()
		character:setup()

		return
	end

	nut.config.send(client)

	client:loadNutData(function(data)
		if (!IsValid(client)) then return end

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
		end)
	end)

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

function GM:PlayerLoadedChar(client, character, lastChar)
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

	nut.chat.send(client, chatType, message, anonymous)

	return ""
end

function GM:PlayerSpawn(client)
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
	client:StripAmmo()
	client:StripWeapons()

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

function GM:PlayerDeath(client, inflictor, attacker)
	client:setNetVar("deathStartTime", CurTime())
	client:setNetVar("deathTime", CurTime() + nut.config.get("spawnTime", 5))
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
		character:save()
	end
end

function GM:InitPostEntity()
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

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end

function GM:CanPlayerUseBusiness(char, id)
	local item = nut.item.list[id]
	local price = item.price or 0

	if (!item) then
		client:notify(L("itemNoExit", client))

		return false
	end

	-- Does player has enough money?
	if (!char:hasMoney(price)) then
		char.player:notify(L("canNotAfford", client))
		
		return false
	end

	-- Does player has proper flag to buy this item?
	if (item.flag and !char:hasFlag(item.flag)) then
		char.player:notify(L("flagNoMatch", client, item.flag))
		
		return false
	end

	return price
end

function GM:OnPlayerUseBusiness(char, item)
	-- You can manipulate purchased items with this hook.
	-- does not requires any kind of return.
	-- ex) item:setData("businessItem", true)
	-- then every purchased item will be marked as Business Item.
end
