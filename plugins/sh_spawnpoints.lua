local PLUGIN = PLUGIN
PLUGIN.name = "Spawn Points"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides the ability for administrators to set spawn points."
PLUGIN.points = PLUGIN.points or {}

function PLUGIN:LoadData()
	self.points = self:ReadTable()
end

function PLUGIN:SaveData()
	self:WriteTable(self.points)
end

function PLUGIN:ChooseSpawn(client, spawns)
	if (#spawns > 0) then
		local data = table.Random(spawns)

		client:SetPos(data.pos)
		client:SetEyeAngles(data.ang)
	end
end

function PLUGIN:PlayerSpawn(client)
	timer.Simple(0.1, function()
		if (!IsValid(client)) then
			return
		end

		local faction = client:Team()
		local class = client:CharClass()
		local spawns = {}

		if (class) then
			for k, v in pairs(self.points) do
				if (v.faction == faction and v.class == class) then
					spawns[#spawns + 1] = v
				end
			end

			if (#spawns > 0) then
				return self:ChooseSpawn(client, spawns)
			end
		end

		for k, v in pairs(self.points) do
			if (v.faction == faction) then
				spawns[#spawns + 1] = v
			end
		end

		if (#spawns < 1) then
			for k, v in pairs(self.points) do
				if (!v.faction) then
					spawns[#spawns + 1] = v
				end
			end
		end

		self:ChooseSpawn(client, spawns)
	end)
end

nut.command.Register({
	adminOnly = true,
	syntax = "[string faction] [string class]",
	onRun = function(client, arguments)
		local faction = arguments[1] or ""
		local class = arguments[2] or ""
		local factionIndex
		local factionTable
		local classID
		local classTable

		if (faction != "") then
			for k, v in pairs(nut.faction.GetAll()) do
				if (nut.util.StringMatches(faction, v.name)) then
					factionIndex = k
					factionTable = v

					break
				end
			end
		end

		if (class != "" and factionIndex) then
			for k, v in pairs(nut.class.GetByFaction(factionIndex)) do
				if (nut.util.StringMatches(class, v.name)) then
					classID = k
					classTable = v

					break
				end
			end
		end

		local position = client:GetPos() + Vector(0, 0, 8)
		local angles = client:EyeAngles()

		PLUGIN.points[#PLUGIN.points + 1] = {pos = position, ang = angles, faction = factionIndex, class = classID}

		if (classTable) then
			nut.util.Notify("You have added a(n) "..(factionTable and factionTable.name or "default").." spawn for the "..classTable.name.." class.", client)
		else
			nut.util.Notify("You have added a(n) "..(factionTable and factionTable.name or "default").." spawn.", client)
		end

		PLUGIN:SaveData()
	end
}, "spawnadd")

nut.command.Register({
	adminOnly = true,
	syntax = "[number radius]",
	onRun = function(client, arguments)
		local radius = math.max(tonumber(arguments[1] or "") or 128, 8)
		local i = 0
		local position = client:GetPos()

		for k, v in pairs(PLUGIN.points) do
			if (v.pos:Distance(position) <= radius) then
				i = i + 1
				PLUGIN.points[k] = nil
			end
		end

		nut.util.Notify("You have removed "..i.." spawn point(s).", client)
		PLUGIN:SaveData()
	end
}, "spawnremove")