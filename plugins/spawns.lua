
local PLUGIN = PLUGIN

PLUGIN.name = "Spawns"
PLUGIN.description = "Spawn points for factions and classes."
PLUGIN.author = "Chessnut"
PLUGIN.spawns = PLUGIN.spawns or {}

function PLUGIN:PlayerLoadout(client)
	local character = client:GetCharacter()

	if (self.spawns and !table.IsEmpty(self.spawns) and character) then
		local class = character:GetClass()
		local points
		local className = "default"

		for k, v in ipairs(ix.faction.indices) do
			if (k == client:Team()) then
				points = self.spawns[v.uniqueID] or {}

				break
			end
		end

		if (points) then
			for _, v in ipairs(ix.class.list) do
				if (class == v.index) then
					className = v.uniqueID

					break
				end
			end

			points = points[className] or points["default"]

			if (points and !table.IsEmpty(points)) then
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
	privilege = "Manage Spawn Points",
	adminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.text, ix.type.optional)
	},
	OnRun = function(self, client, name, class)
		local info = ix.faction.indices[name:lower()]
		local info2
		local faction

		if (!info) then
			for _, v in ipairs(ix.faction.indices) do
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

				for _, v in ipairs(ix.class.list) do
					if (v.faction == info.index and
						(v.uniqueID:lower() == class:lower() or ix.util.StringMatches(L(v.name, client), class))) then
						class = v.uniqueID
						info2 = v
						found = true

						break
					end
				end

				if (!found) then
					return "@invalidClass"
				end
			else
				class = "default"
			end

			PLUGIN.spawns[faction] = PLUGIN.spawns[faction] or {}
			PLUGIN.spawns[faction][class] = PLUGIN.spawns[faction][class] or {}

			table.insert(PLUGIN.spawns[faction][class], client:GetPos())

			PLUGIN:SaveSpawns()

			name = L(info.name, client)

			if (info2) then
				name = name .. " (" .. L(info2.name, client) .. ")"
			end

			return "@spawnAdded", name
		else
			return "@invalidFaction"
		end
	end
})

ix.command.Add("SpawnRemove", {
	description = "@cmdSpawnRemove",
	privilege = "Manage Spawn Points",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, radius)
		radius = radius or 120

		local position = client:GetPos()
		local i = 0

		for _, v in pairs(PLUGIN.spawns) do
			for _, v2 in pairs(v) do
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

		return "@spawnDeleted", i
	end
})
