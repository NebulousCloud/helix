function GM:PlayerInitialSpawn(client)
	nut.config.send(client)

	client.nutJoinTime = RealTime()
	client:loadNutData(function(data)
		if (!IsValid(client)) then return end

		nut.char.restore(client, function(charList)
			if (!IsValid(client)) then return end
			
			print("Loaded ("..table.concat(charList, ", ")..") for "..client:Name())

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

function GM:PlayerShouldTakeDamage(client, attacker)
	return client:getChar() != nil
end

function GM:GetFallDamage(client, speed)
	return (speed - 580) * (100 / 444)
end

function GM:PlayerLoadedChar(client, character, currentChar)
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
end

-- Called when weapons should be given to a player.
function GM:PlayerLoadout(client)
	local character = client:getChar()

	-- Check if they have loaded a character.
	if (character) then
		client:SetupHands()
		-- Set their player model to the character's model.
		client:SetModel(character:getModel())

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

function GM:ShutDown()
	nut.shuttingDown = true
	nut.config.save()

	for k, v in ipairs(player.GetAll()) do
		if (v:getChar()) then
			v:getChar():save()
		end
	end
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end