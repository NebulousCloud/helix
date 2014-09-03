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

function GM:PlayerSay(client, message)
	nut.chat.parse(client, message)

	return ""
end

function GM:PlayerSpawn(client)
	hook.Run("PlayerLoadout", client)
end

function GM:PlayerLoadout(client)
	local character = client:getChar()

	if (character) then
		client:SetModel(character:getModel())

		local faction = nut.faction.indices[client:Team()]

		if (faction) then
			if (faction.onSpawn) then
				faction:onSpawn(client)
			end

			if (faction.weapons) then
				for k, v in ipairs(faction.weapons) do
					client:Give(v)
				end
			end
		end
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
end

function GM:ShutDown()
	nut.config.save()
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end