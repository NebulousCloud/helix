local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

nut.net = nut.net or {}
nut.net.globals = nut.net.globals or {}

netstream.Hook("nVar", function(index, key, value)
	nut.net[index] = nut.net[index] or {}
	nut.net[index][key] = value
end)

netstream.Hook("nDel", function(index)
	nut.net[index] = nil
end)

netstream.Hook("nLcl", function(key, value)
	nut.net[LocalPlayer():EntIndex()] = nut.net[LocalPlayer():EntIndex()] or {}
	nut.net[LocalPlayer():EntIndex()][key] = value
end)

netstream.Hook("gVar", function(key, value)
	nut.net.globals[key] = value
end)

function getNetVar(key, default)
	local value = nut.net.globals[key]

	return value != nil and value or default
end

function entityMeta:getNetVar(key, default)
	local index = self:EntIndex()

	if (nut.net[index] and nut.net[index][key] != nil) then
		return nut.net[index][key]
	end

	return default
end

playerMeta.getLocalVar = entityMeta.getNetVar