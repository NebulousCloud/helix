--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

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