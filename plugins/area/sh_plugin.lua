local PLUGIN = PLUGIN
PLUGIN.name = "Area"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Allows you to set area."
PLUGIN.areaTable = {}
nut.area = nut.area or {}
ALWAYS_RAISED["nut_areahelper"] = true

local playerMeta = FindMetaTable("Player")

function nut.area.getArea(areaID)
	return PLUGIN.areaTable[areaID]
end

function nut.area.getAllArea()
	return PLUGIN.areaTable
end

-- This is for single check (ex: area items, checking area in commands)
function playerMeta:isInArea(areaID)
	local areaData = nut.area.getArea(areaID)

	if (!areaData) then
		return false, "Area you specified is not valid."
	end

	local char = v:getChar()

	if (!char) then
		return false, "Your character is not valid."
	end

	local clientPos = self:GetPos() + self:OBBCenter()
	return clientPos:WithinAABox(areaData.minVector, areaData.maxVector), areaData
end

-- This is for continous check (ex: checking gas area whatever.)
function playerMeta:getArea()
	return self.curArea
end

if (SERVER) then
	local function sortVector(vector1, vector2)
		local minVector = Vector(0, 0, 0)
		local maxVector = Vector(0, 0, 0)

		for i = 1, 3 do
			if (vector1[i] >= vector2[i]) then
				maxVector[i] = vector1[i]
				minVector[i] = vector2[i]
			else
				maxVector[i] = vector2[i]
				minVector[i] = vector1[i]
			end
		end

		return minVector, maxVector
	end

	function nut.area.addArea(name, vector1, vector2, desc)
		if (!name or !vector1 or !vector2) then
			return false, "Required arguments are not provided."
		end

		local minVector, maxVector = sortVector(vector1, vector2)

		table.insert(PLUGIN.areaTable, {
			name = name,
			minVector = minVector,
			maxVector = maxVector, 
			desc = desc or "",
		})
	end

	function PLUGIN:PlayerInitialSpawn(client)
		netstream.Start("areaReceive", nut.area.getAllArea())
	end
else
	netstream.Hook("areaReceive", function(areaData)
		if (areaData) then
			PLUGIN.areaTable = areaData
		else
			print("Bad Data Received?")
		end
	end)

	-- area Manager.
	function nut.area.openAreaManager()

	end

	netstream.Hook("areaManager", function()
		nut.area.openAreaManager()
	end)
end

function PLUGIN:Think()
	for k, v in ipairs(player.GetAll()) do
		local char = v:getChar()

		if (char) then
			local area = v:getArea()
			for id, areaData in pairs(nut.area.getAllArea()) do
				local clientPos = v:GetPos() + v:OBBCenter()

				if (clientPos:WithinAABox(areaData.minVector, areaData.maxVector)) then
					v.curArea = id
				end
			end
		end
	end
end