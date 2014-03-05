PLUGIN.name = "Persistent Props"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Allows administrators to set props to be persistent through restarts."

if (SERVER) then
	file.CreateDir("persist")
	file.CreateDir("persist/nutscript")

	function PLUGIN:LoadData()
		local contents = file.Read("persist/nutscript/"..SCHEMA.uniqueID.."/"..game.GetMap()..".txt", "DATA")

		if (!contents) then
			return
		end

		local data = util.JSONToTable(contents)

		if (data) then
			local entities, constraints = duplicator.Paste(nil, data.Entities or {}, data.Contraints or {})

			for k, v in pairs(entities) do
				v:SetNutVar("persist", true)
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.GetAll()) do
			if (v:GetNutVar("persist")) then
				data[#data + 1] = v
			end
		end

		if (#data > 0) then
			local persistData = duplicator.CopyEnts(data)

			if (!persistData) then
				return
			end

			file.CreateDir("persist/nutscript/"..SCHEMA.uniqueID)
			file.Write("persist/nutscript/"..SCHEMA.uniqueID.."/"..game.GetMap()..".txt", util.TableToJSON(persistData))
		end
	end
end

local PLUGIN = PLUGIN

nut.command.Register({
	syntax = "[bool disabled]",
	adminOnly = true,
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity)) then
			local class = entity:GetClass()

			if (string.find(class, "prop_") and !string.find(class, "door")) then
				entity:SetNutVar("persist", !util.tobool(arguments[1]))

				if (entity:GetNutVar("persist")) then
					nut.util.Notify("This entity is now persisted.", client)
				else
					nut.util.Notify("This entity is no longer persisted.", client)
				end

				PLUGIN:SaveData()
			else
				nut.util.Notify("That entity can not be persisted.", client)
			end
		else
			nut.util.Notify("You provided an invalid entity.", client)
		end
	end
}, "setpersist")