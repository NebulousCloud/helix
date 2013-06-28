util.AddNetworkString("nut_ShowMenu")

function GM:ShowHelp(client)
	net.Start("nut_ShowMenu")
	net.Send(client)
end

function GM:GetDefaultInventory(client)
	return {}
end

function GM:GetDefaultMoney(client)
	return nut.config.startingAmount
end

function GM:PlayerInitialSpawn(client)
	if (IsValid(client)) then
		client:KillSilent()
	end
	
	timer.Simple(5, function()
		if (!IsValid(client)) then
			return
		end

		client:KillSilent()
		client:StripWeapons()
		client:InitializeData()

		player_manager.SetPlayerClass(client, "player_nut")
		player_manager.RunClass(client, "Spawn")

		for k, v in pairs(nut.char.GetAll()) do
			v:Send(nil, client)
		end

		nut.char.Load(client, function()
			net.Start("nut_CharMenu")
			net.Send(client)

			local uniqueID = "nut_SaveChar"..client:SteamID()

			timer.Create(uniqueID, nut.config.saveInterval, 0, function()
				if (!IsValid(client)) then
					timer.Remove(uniqueID)

					return
				end

				nut.char.Save(client)
			end)
		end)
	end)
end

function GM:PlayerLoadedChar(client)
	local faction = client.character:GetVar("faction", 9001)
	client:SetTeam(faction)

	if (!client.nut_SawCredits) then
		client.nut_SawCredits = true
		nut.scroll.Send("NutScript: "..nut.lang.Get("schema_author", "Chessnut"), client)

		timer.Simple(20, function()
			if (IsValid(client)) then
				nut.scroll.Send(SCHEMA.name..": "..nut.lang.Get("schema_author", SCHEMA.author), client)
			end
		end)
	end
end

function GM:PlayerSpawn(client)
	if (!client.character) then
		return
	end

	client:StripWeapons()
	client:SetModel(client.character.model)

	client:Give("nut_fists")

	player_manager.SetPlayerClass(client, "player_nut")
	player_manager.RunClass(client, "Spawn")

	client:SetWalkSpeed(nut.config.walkSpeed)
	client:SetRunSpeed(nut.config.runSpeed)
	client:SetWepRaised(false)

	nut.flag.OnSpawn(client)
	nut.attribs.OnSpawn(client)
end

function GM:PlayerDisconnected(client)
	nut.char.Save(client)

	timer.Remove("nut_SaveChar"..client:SteamID())
end

function GM:PlayerShouldTakeDamage()
	return true
end

function GM:CanArmDupe()
	print("Duping?")

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
	for k, v in pairs(player.GetAll()) do
		nut.char.Save(v)
	end

	nut.schema.Call("SaveData")
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
	return client:HasFlag("p")
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

function GM:PlayerSwitchFlashlight(client, state)
	return nut.config.flashlight
end

function GM:InitPostEntity()
	nut.schema.Call("LoadData")
end

function GM:PlayerDeathThink(client)
	return client.character != nil
end