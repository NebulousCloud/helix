PLUGIN.name = "Basic Prop Protection"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a simple prop protection system."

local PROP_BLACKLIST = {
	["models/props_combine/combinetrain02b.mdl"] = true,
	["models/props_combine/combinetrain02a.mdl"] = true,
	["models/props_combine/combinetrain01.mdl"] = true,
	["models/cranes/crane_frame.mdl"] = true,
	["models/props_wasteland/cargo_container01.mdl"] = true,
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
	["models/props_phx/oildrum001_explosive.mdl"] = true
}

if (SERVER) then
	local function getLogName(entity)
		local class = entity:GetClass():lower()

		if (class:find("prop")) then
			local propType = class:sub(6)

			if (propType == "physics") then
				propType = "prop"
			end

			class = propType.." ("..entity:GetModel()..")"
		end

		return class
	end

	function PLUGIN:PlayerSpawnObject(client, model, skin)
		if ((client.nutNextSpawn or 0) < CurTime()) then
			client.nutNextSpawn = CurTime() + 0.75
		else
			return false
		end

		if (!client:IsAdmin() and PROP_BLACKLIST[model:lower()]) then
			return false
		end
	end

	function PLUGIN:PhysgunPickup(client, entity)
		if (entity:GetCreator() == client) then
			return true
		end
	end

	function PLUGIN:CanProperty(client, property, entity)
		if (entity:GetCreator() == client and (property == "remover" or property == "collision")) then
			nut.log.add(client, " used "..property.." on "..getLogName(entity))

			return true
		end
	end

	function PLUGIN:CanTool(client, trace, tool)
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetCreator() == client) then
			return true
		end
	end

	function PLUGIN:PlayerSpawnedEntity(client, entity)
		entity:SetCreator(client)
		nut.log.add(client, "spawned "..getLogName(entity))
	end

	function PLUGIN:PlayerSpawnedProp(client, model, entity)
		hook.Run("PlayerSpawnedEntity", client, entity)
	end

	PLUGIN.PlayerSpawnedEffect = PLUGIN.PlayerSpawnedProp
	PLUGIN.PlayerSpawnedRagdoll = PLUGIN.PlayerSpawnedProp

	function PLUGIN:PlayerSpawnedNPC(client, entity)
		hook.Run("PlayerSpawnedEntity", client, entity)
	end

	PLUGIN.PlayerSpawnedSENT = PLUGIN.PlayerSpawnedNPC
	PLUGIN.PlayerSpawnedVehicle = PLUGIN.PlayerSpawnedNPC
end