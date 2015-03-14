local PLUGIN = PLUGIN

PLUGIN.name = "Spawns"
PLUGIN.desc = "Spawn points for factions and classes."
PLUGIN.author = "Chessnut"
PLUGIN.spawns = PLUGIN.spawns or {}

function PLUGIN:PostPlayerLoadout(client)
	if (self.spawns and table.Count(self.spawns) > 0 and client:getChar()) then
		local class = client:getChar():getClass()
		local points
		local className = ""

		for k, v in ipairs(nut.faction.indices) do
			if (k == client:Team()) then
				points = self.spawns[v.uniqueID] or {}

				break
			end
		end

		if (points) then
			for k, v in ipairs(nut.class.list) do
				if (class == v.index) then
					className = v.uniqueID

					break
				end
			end

			points = points[className] or points[""]

			if (points and table.Count(points) > 0) then
				client:SetPos(table.Random(points))
			end
		end
	end
end

function PLUGIN:LoadData()
	self.spawns = self:getData() or {}
end

function PLUGIN:SaveSpawns()
	self:setData(self.spawns)
end

nut.command.add("spawnadd", {
	adminOnly = true,
	syntax = "<string faction> [string class]",
	onRun = function(client, arguments)
		local faction
		local name = arguments[1]
		local class = table.concat(arguments, " ", 2)
		local info

		if (name) then
			for k, v in ipairs(nut.faction.indices) do
				if (nut.util.stringMatches(v.uniqueID, name) or nut.util.stringMatches(L(v.name, client), name)) then
					faction = v.uniqueID
					info = v

					if (class and class != "") then
						local found = false

						for k2, v2 in ipairs(nut.class.list) do
							if (v2.faction == v.index) then
								class = v2.uniqueID
								found = true

								break
							end
						end

						if (!found) then
							return L("invalidClass", client)
						end
					end

					break
				end
			end

			if (faction) then
				PLUGIN.spawns[faction] = PLUGIN.spawns[faction] or {}
				PLUGIN.spawns[faction][class] = PLUGIN.spawns[faction][class] or {}

				table.insert(PLUGIN.spawns[faction][class], client:GetPos())

				PLUGIN:SaveSpawns()

				return L("spawnAdded", client, L(info.name, client))
			else
				return L("invalidFaction", client)
			end
		else
			return L("invalidArg", client, 1)
		end
	end
})

nut.command.add("spawnremove", {
	adminOnly = true,
	syntax = "[number radius]",
	onRun = function(client, arguments)
		local position = client:GetPos()
		local radius = tonumber(arguments[1]) or 120
		local i = 0

		for k, v in pairs(PLUGIN.spawns) do
			for k2, v2 in pairs(v) do
				for k3, v3 in pairs(v2) do
					if (v3:Distance(position) <= radius) then
						v2[k3] = nil
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