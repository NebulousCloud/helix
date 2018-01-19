
local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

ix.net = ix.net or {}
ix.net.globals = ix.net.globals or {}

-- Check if there is an attempt to send a function. Can't send those.
local function CheckBadType(name, object)
	local objectType = type(object)

	if (objectType == "function") then
		ErrorNoHalt("Net var '"..name.."' contains a bad object type!")

		return true
	elseif (objectType == "table") then
		for k, v in pairs(object) do
			-- Check both the key and the value for tables, and has recursion.
			if (CheckBadType(name, k) or CheckBadType(name, v)) then
				return true
			end
		end
	end
end

function SetNetVar(key, value, receiver) -- luacheck: globals SetNetVar
	if (CheckBadType(key, value)) then return end
	if (GetNetVar(key) == value) then return end

	ix.net.globals[key] = value
	netstream.Start(receiver, "gVar", key, value)
end

function playerMeta:SyncVars()
	for entity, data in pairs(ix.net) do
		if (entity == "globals") then
			for k, v in pairs(data) do
				netstream.Start(self, "gVar", k, v)
			end
		elseif (IsValid(entity)) then
			for k, v in pairs(data) do
				netstream.Start(self, "nVar", entity:EntIndex(), k, v)
			end
		end
	end
end

function entityMeta:SendNetVar(key, receiver)
	netstream.Start(receiver, "nVar", self:EntIndex(), key, ix.net[self] and ix.net[self][key])
end

function entityMeta:ClearNetVars(receiver)
	ix.net[self] = nil
	netstream.Start(receiver, "nDel", self:EntIndex())
end

function entityMeta:SetNetVar(key, value, receiver)
	if (CheckBadType(key, value)) then return end

	ix.net[self] = ix.net[self] or {}

	if (ix.net[self][key] != value) then
		ix.net[self][key] = value
	end

	self:SendNetVar(key, receiver)
end

function entityMeta:GetNetVar(key, default)
	if (ix.net[self] and ix.net[self][key] != nil) then
		return ix.net[self][key]
	end

	return default
end

function playerMeta:SetLocalVar(key, value)
	if (CheckBadType(key, value)) then return end

	ix.net[self] = ix.net[self] or {}
	ix.net[self][key] = value

	netstream.Start(self, "nLcl", key, value)
end

playerMeta.GetLocalVar = entityMeta.GetNetVar

function GetNetVar(key, default) -- luacheck: globals GetNetVar
	local value = ix.net.globals[key]

	return value != nil and value or default
end

hook.Add("EntityRemoved", "nCleanUp", function(entity)
	entity:ClearNetVars()
end)

hook.Add("PlayerInitialSpawn", "nSync", function(client)
	client:SyncVars()
end)
