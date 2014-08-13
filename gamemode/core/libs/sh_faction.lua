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

		FACTION = nut.faction.teams[niceName] or {index = table.Count(nut.faction.teams) + 1}
			nut.util.include(directory.."/"..v, "shared")
			team.SetUp(FACTION.index, FACTION.name or "Unknown", FACTION.color or Color(125, 125, 125))

			if (!FACTION.models) then
				FACTION.models = CITIZEN_MODELS
			end

			FACTION.uniqueID = niceName

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

if (CLIENT) then
	function nut.faction.hasWhitelist(faction)
		local data = nut.faction.indices[faction]

		if (data and data.isDefault) then
			return true
		end

		return ((nut.localData and nut.localData.whitelists or {})["whitelists"] or {})[faction] == true
	end
end