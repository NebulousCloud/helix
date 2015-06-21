nut.faction = nut.faction or {}
nut.faction.teams = nut.faction.teams or {}
nut.faction.indices = nut.faction.indices or {}

local CITIZEN_MODELS = {
	"models/humans/group01/male_01.mdl",
	"models/humans/group01/male_02.mdl",
	"models/humans/group01/male_04.mdl",
	"models/humans/group01/male_05.mdl",
	"models/humans/group01/male_06.mdl",
	"models/humans/group01/male_07.mdl",
	"models/humans/group01/male_08.mdl",
	"models/humans/group01/male_09.mdl",
	"models/humans/group02/male_01.mdl",
	"models/humans/group02/male_03.mdl",
	"models/humans/group02/male_05.mdl",
	"models/humans/group02/male_07.mdl",
	"models/humans/group02/male_09.mdl",
	"models/humans/group01/female_01.mdl",
	"models/humans/group01/female_02.mdl",
	"models/humans/group01/female_03.mdl",
	"models/humans/group01/female_06.mdl",
	"models/humans/group01/female_07.mdl",
	"models/humans/group02/female_01.mdl",
	"models/humans/group02/female_03.mdl",
	"models/humans/group02/female_06.mdl",
	"models/humans/group01/female_04.mdl"
}

function nut.faction.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		FACTION = nut.faction.teams[niceName] or {index = table.Count(nut.faction.teams) + 1, isDefault = true}
			if (PLUGIN) then
				FACTION.plugin = PLUGIN.uniqueID
			end

			nut.util.include(directory.."/"..v, "shared")

			if (!FACTION.name) then
				FACTION.name = "Unknown"
				ErrorNoHalt("Faction '"..niceName.."' is missing a name. You need to add a FACTION.name = \"Name\"\n")
			end

			if (!FACTION.desc) then
				FACTION.desc = "noDesc"
				ErrorNoHalt("Faction '"..niceName.."' is missing a description. You need to add a FACTION.desc = \"Description\"\n")
			end

			if (!FACTION.color) then
				FACTION.color = Color(150, 150, 150)
				ErrorNoHalt("Faction '"..niceName.."' is missing a color. You need to add FACTION.color = Color(1, 2, 3)\n")
			end

			team.SetUp(FACTION.index, FACTION.name or "Unknown", FACTION.color or Color(125, 125, 125))
			
			FACTION.models = FACTION.models or CITIZEN_MODELS
			FACTION.uniqueID = FACTION.uniqueID or niceName

			for k, v in pairs(FACTION.models) do
				if (type(v) == "string") then
					util.PrecacheModel(v)
				elseif (type(v) == "table") then
					util.PrecacheModel(v[1])
				end
			end

			nut.faction.indices[FACTION.index] = FACTION
			nut.faction.teams[niceName] = FACTION
		FACTION = nil
	end
end

function nut.faction.getIndex(uniqueID)
	for k, v in ipairs(nut.faction.indices) do
		if (v.uniqueID == uniqueID) then
			return k
		end
	end
end

if (CLIENT) then
	function nut.faction.hasWhitelist(faction)
		local data = nut.faction.indices[faction]

		if (data) then
			if (data.isDefault) then
				return true
			end

			local nutData = nut.localData and nut.localData.whitelists or {}

			return nutData[SCHEMA.folder] and nutData[SCHEMA.folder][data.uniqueID] == true or false
		end

		return false
	end
end
