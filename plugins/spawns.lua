local PLUGIN = PLUGIN

PLUGIN.name = "Spawns"
PLUGIN.description = "Spawn points for factions and classes."
PLUGIN.author = "Chessnut"
PLUGIN.spawns = PLUGIN.spawns or {}

function PLUGIN:PostPlayerLoadout(client)
	if (self.spawns and table.Count(self.spawns) > 0 and client:GetChar()) then
		local class = client:GetChar():GetClass()
		local points
		local className = ""

		for k, v in ipairs(ix.faction.indices) do
			if (k == client:Team()) then
				points = self.spawns[v.uniqueID] or {}

				break
			end
		end

		if (points) then
			for k, v in ipairs(ix.class.list) do
				if (class == v.index) then
					className = v.uniqueID

					break
				end
			end

			points = points[className] or points[""]

			if (points and table.Count(points) > 0) then
				local position = table.Random(points)

				client:SetPos(position)
			end
		end
	end
end

function PLUGIN:LoadData()
	self.spawns = self:GetData() or {}
end

function PLUGIN:SaveSpawns()
	self:SetData(self.spawns)
end

ix.command.Add("SpawnAdd", {
	description = "@cmdSpawnAdd",
	adminOnly = true,
	syntax = "<string faction> [string class]",
	OnRun = function(self, client, arguments)
		local faction
		local name = arguments[1]
		local class = table.concat(arguments, " ", 2)
		local info
		local info2

		if (name) then
			info = ix.faction.indices[name:lower()]

			if (!info) then
				for k, v in ipairs(ix.faction.indices) do
					if (ix.util.StringMatches(v.uniqueID, name) or ix.util.StringMatches(L(v.name, client), name)) then
						faction = v.uniqueID
						info = v

						break
					end
				end
			end

			if (info) then
				if (class and class != "") then
					local found = false

					for k, v in ipairs(ix.class.list) do
						if (v.faction == info.index and (v.uniqueID:lower() == class:lower() or ix.util.StringMatches(L(v.name, client), class))) then
							class = v.uniqueID
							info2 = v
							found = true

							break
						end
					end

					if (!found) then
						return L("invalidClass", client)
					end
				else
					class = ""
				end

				PLUGIN.spawns[faction] = PLUGIN.spawns[faction] or {}
				PLUGIN.spawns[faction][class] = PLUGIN.spawns[faction][class] or {}

				table.insert(PLUGIN.spawns[faction][class], client:GetPos())

				PLUGIN:SaveSpawns()

				local name = L(info.name, client)

				if (info2) then
					name = name.." ("..L(info2.name, client)..")"
				end

				return L("spawnAdded", client, name)
			else
				return L("invalidFaction", client)
			end
		else
			return L("invalidArg", client, 1)
		end
	end
})

ix.command.Add("SpawnRemove", {
	description = "@cmdSpawnRemove",
	adminOnly = true,
	syntax = "[number radius]",
	OnRun = function(self, client, arguments)
		local position = client:GetPos()
		local radius = tonumber(arguments[1]) or 120
		local i = 0

		for k, v in pairs(PLUGIN.spawns) do
			for k2, v in pairs(v) do
				for k3, v3 in pairs(v) do
					if (v3:Distance(position) <= radius) then
						v[k3] = nil
						i = i + 1
					end
				end
			end
		end

		if (i > 0) then
			PLUGIN:SaveSpawns()
		end

		return L("spawnDeleted", client, i)
	end
})
