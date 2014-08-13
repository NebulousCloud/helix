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

function GM:PlayerDeathThink(client)
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