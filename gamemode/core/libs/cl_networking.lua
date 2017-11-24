local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

ix.net = ix.net or {}
ix.net.globals = ix.net.globals or {}

netstream.Hook("nVar", function(index, key, value)
	ix.net[index] = ix.net[index] or {}
	ix.net[index][key] = value
end)

netstream.Hook("nDel", function(index)
	ix.net[index] = nil
end)

netstream.Hook("nLcl", function(key, value)
	ix.net[LocalPlayer():EntIndex()] = ix.net[LocalPlayer():EntIndex()] or {}
	ix.net[LocalPlayer():EntIndex()][key] = value
end)

netstream.Hook("gVar", function(key, value)
	ix.net.globals[key] = value
end)

function GetNetVar(key, default)
	local value = ix.net.globals[key]

	return value != nil and value or default
end

function entityMeta:GetNetVar(key, default)
	local index = self:EntIndex()

	if (ix.net[index] and ix.net[index][key] != nil) then
		return ix.net[index][key]
	end

	return default
end

playerMeta.GetLocalVar = entityMeta.GetNetVar
