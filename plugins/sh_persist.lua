local PLUGIN = PLUGIN
PLUGIN.name = "Persistent Props"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Allows administrators to set props to be persistent through restarts."

if (SERVER) then
	function PLUGIN:LoadData()
		for k, data in pairs(self:ReadTable("props")) do
			if (data) then
				local entities, constraints = duplicator.Paste(nil, data.Entities or {}, data.Contraints or {})

				for k, v in pairs(entities) do
					v:SetPersistent(true)
				end
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.GetAll()) do
			if (v:GetPersistent()) then
				data[k] = v
			end
		end

		if (#data > 0) then
			self:WriteTable("props", duplicator.CopyEnts(data))
		end
	end
end

nut.command.Register({
	syntax = "[bool disabled]",
	adminOnly = true,
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (IsValid(entity)) then
			local class = entity:GetClass()

			if (string.find(class, "prop_") and !string.find(class, "door")) then
				entity:SetPersistent(!util.tobool(arguments[1]))

				if (entity:GetPersistent()) then
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