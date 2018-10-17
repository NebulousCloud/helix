
local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

ix.net = ix.net or {}
ix.net.globals = ix.net.globals or {}

util.AddNetworkString("ixGlobalVarSet")
util.AddNetworkString("ixLocalVarSet")
util.AddNetworkString("ixNetVarSet")
util.AddNetworkString("ixNetVarDelete")

-- Check if there is an attempt to send a function. Can't send those.
local function CheckBadType(name, object)
	local objectType = type(object)

	if (objectType == "function") then
		ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")

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

	net.Start("ixGlobalVarSet")
	net.WriteString(key)
	net.WriteType(value)

	if (receiver == nil) then
		net.Broadcast()
	else
		net.Send(receiver)
	end
end

function playerMeta:SyncVars()
	for entity, data in pairs(ix.net) do
		if (entity == "globals") then
			for k, v in pairs(data) do
				net.Start("ixGlobalVarSet")
					net.WriteString(k)
					net.WriteType(v)
				net.Send(self)
			end
		elseif (IsValid(entity)) then
			for k, v in pairs(data) do
				net.Start("ixNetVarSet")
					net.WriteUInt(entity:EntIndex(), 16)
					net.WriteString(k)
					net.WriteType(v)
				net.Send(self)
			end
		end
	end
end

function entityMeta:SendNetVar(key, receiver)
	net.Start("ixNetVarSet")
	net.WriteUInt(self:EntIndex(), 16)
	net.WriteString(key)
	net.WriteType(ix.net[self] and ix.net[self][key])

	if (receiver == nil) then
		net.Broadcast()
	else
		net.Send(receiver)
	end
end

function entityMeta:ClearNetVars(receiver)
	ix.net[self] = nil

	net.Start("ixNetVarDelete")
	net.WriteUInt(self:EntIndex(), 16)

	if (receiver == nil) then
		net.Broadcast()
	else
		net.Send(receiver)
	end
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

	net.Start("ixLocalVarSet")
		net.WriteString(key)
		net.WriteType(value)
	net.Send(self)
end

playerMeta.GetLocalVar = entityMeta.GetNetVar

function GetNetVar(key, default) -- luacheck: globals GetNetVar
	local value = ix.net.globals[key]

	return value != nil and value or default
end
