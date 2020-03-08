
PLUGIN.name = "Basic Prop Protection"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds a simple prop protection system."

CAMI.RegisterPrivilege({
	Name = "Helix - Bypass Prop Protection",
	MinAccess = "admin"
})

local PROP_BLACKLIST = {
	["models/props_combine/combinetrain02b.mdl"] = true,
	["models/props_combine/combinetrain02a.mdl"] = true,
	["models/props_combine/combinetrain01.mdl"] = true,
	["models/cranes/crane_frame.mdl"] = true,
	["models/props_junk/trashdumpster02.mdl"] = true,
	["models/props_c17/oildrum001_explosive.mdl"] = true,
	["models/props_canal/canal_bridge02.mdl"] = true,
	["models/props_canal/canal_bridge01.mdl"] = true,
	["models/props_canal/canal_bridge03a.mdl"] = true,
	["models/props_canal/canal_bridge03b.mdl"] = true,
	["models/props_wasteland/cargo_container01.mdl"] = true,
	["models/props_wasteland/cargo_container01c.mdl"] = true,
	["models/props_wasteland/cargo_container01b.mdl"] = true,
	["models/props_combine/combine_mine01.mdl"] = true,
	["models/props_junk/glassjug01.mdl"] = true,
	["models/props_c17/paper01.mdl"] = true,
	["models/props_junk/garbage_takeoutcarton001a.mdl"] = true,
	["models/props_c17/trappropeller_engine.mdl"] = true,
	["models/props/cs_office/microwave.mdl"] = true,
	["models/items/item_item_crate.mdl"] = true,
	["models/props_junk/gascan001a.mdl"] = true,
	["models/props_c17/consolebox01a.mdl"] = true,
	["models/props_buildings/building_002a.mdl"] = true,
	["models/props_phx/mk-82.mdl"] = true,
	["models/props_phx/cannonball.mdl"] = true,
	["models/props_phx/ball.mdl"] = true,
	["models/props_phx/amraam.mdl"] = true,
	["models/props_phx/misc/flakshell_big.mdl"] = true,
	["models/props_phx/ww2bomb.mdl"] = true,
	["models/props_phx/torpedo.mdl"] = true,
	["models/props/de_train/biohazardtank.mdl"] = true,
	["models/props_buildings/project_building01.mdl"] = true,
	["models/props_combine/prison01c.mdl"] = true,
	["models/props/cs_militia/silo_01.mdl"] = true,
	["models/props_phx/huge/evildisc_corp.mdl"] = true,
	["models/props_phx/misc/potato_launcher_explosive.mdl"] = true,
	["models/props_combine/combine_citadel001.mdl"] = true,
	["models/props_phx/oildrum001_explosive.mdl"] = true,
	["models/props_junk/wood_crate01_explosive.mdl"] = true,
	["models/props_junk/propane_tank001a.mdl"] = true,
	["models/props_explosive/explosive_butane_can.mdl"] = true,
	["models/props_explosive/explosive_butane_can02.mdl"] = true
}

if (SERVER) then
	ix.log.AddType("spawnProp", function(client, ...)
		local arg = {...}
		return string.format("%s has spawned '%s'.", client:Name(), arg[1])
	end)

	ix.log.AddType("spawnEntity", function(client, ...)
		local arg = {...}
		return string.format("%s has spawned a '%s'.", client:Name(), arg[1])
	end)

	function PLUGIN:PlayerSpawnObject(client, model, entity)
		if ((client.ixNextSpawn or 0) < CurTime()) then
			client.ixNextSpawn = CurTime() + 0.75
		else
			return false
		end

		if (!client:IsAdmin() and PROP_BLACKLIST[model:lower()]) then
			return false
		end
	end

	function PLUGIN:PhysgunPickup(client, entity)
		local characterID = client:GetCharacter():GetID()

		if (entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:OnPhysgunReload(weapon, client)
		local characterID = client:GetCharacter():GetID()
		local trace = client:GetEyeTrace()

		if (IsValid(trace.Entity) and trace.Entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:CanProperty(client, property, entity)
		local characterID = client:GetCharacter():GetID()

		if (entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:CanTool(client, trace, tool)
		local entity = trace.Entity
		local characterID = client:GetCharacter():GetID()

		if (IsValid(entity) and entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:PlayerSpawnedProp(client, model, entity)
		ix.log.Add(client, "spawnProp", model)
	end

	PLUGIN.PlayerSpawnedEffect = PLUGIN.PlayerSpawnedProp
	PLUGIN.PlayerSpawnedRagdoll = PLUGIN.PlayerSpawnedProp

	function PLUGIN:PlayerSpawnedNPC(client, entity)
		ix.log.Add(client, "spawnEntity", entity)
	end

	PLUGIN.PlayerSpawnedSWEP = PLUGIN.PlayerSpawnedNPC
	PLUGIN.PlayerSpawnedSENT = PLUGIN.PlayerSpawnedNPC
	PLUGIN.PlayerSpawnedVehicle = PLUGIN.PlayerSpawnedNPC
else
	function PLUGIN:PhysgunPickup(client, entity)
		if (entity:GetNetVar("owner", 0) != client:GetCharacter():GetID()
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:CanProperty(client, property, entity)
		local characterID = client:GetCharacter():GetID()

		if (entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end

	function PLUGIN:CanTool(client, trace, tool)
		local entity = trace.Entity
		local characterID = client:GetCharacter():GetID()

		if (IsValid(entity) and entity:GetNetVar("owner", 0) != characterID
		and !CAMI.PlayerHasAccess(client, "Helix - Bypass Prop Protection", nil)) then
			return false
		end
	end
end
