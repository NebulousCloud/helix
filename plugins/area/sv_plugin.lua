
util.AddNetworkString("ixAreaSync")
util.AddNetworkString("ixAreaAdd")
util.AddNetworkString("ixAreaRemove")
util.AddNetworkString("ixAreaChanged")

util.AddNetworkString("ixAreaEditStart")
util.AddNetworkString("ixAreaEditEnd")

ix.log.AddType("areaAdd", function(client, name)
	return string.format("%s has added area \"%s\".", client:Name(), tostring(name))
end)

ix.log.AddType("areaRemove", function(client, name)
	return string.format("%s has removed area \"%s\".", client:Name(), tostring(name))
end)

local function SortVector(first, second)
	return Vector(math.min(first.x, second.x), math.min(first.y, second.y), math.min(first.z, second.z)),
		Vector(math.max(first.x, second.x), math.max(first.y, second.y), math.max(first.z, second.z))
end

function ix.area.Create(name, type, startPosition, endPosition, bNoReplicate, properties)
	local min, max = SortVector(startPosition, endPosition)

	ix.area.stored[name] = {
		type = type or "area",
		startPosition = min,
		endPosition = max,
		bNoReplicate = bNoReplicate,
		properties = properties
	}

	-- network to clients if needed
	if (!bNoReplicate) then
		net.Start("ixAreaAdd")
			net.WriteString(name)
			net.WriteString(type)
			net.WriteVector(startPosition)
			net.WriteVector(endPosition)
			net.WriteTable(properties)
		net.Broadcast()
	end
end

function ix.area.Remove(name, bNoReplicate)
	ix.area.stored[name] = nil

	-- network to clients if needed
	if (!bNoReplicate) then
		net.Start("ixAreaRemove")
			net.WriteString(name)
		net.Broadcast()
	end
end
