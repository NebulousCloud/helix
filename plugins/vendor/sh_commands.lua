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

local PLUGIN = PLUGIN

nut.command.add("vendoradd", {
	adminOnly = true,
	onRun = function(client, arguments)
		local position = client:GetEyeTrace().HitPos
		local angles = (client:GetPos() - position):Angle()
		angles.p = 0
		angles.r = 0

		local entity = ents.Create("nut_vendor")
		entity:SetPos(position)
		entity:SetAngles(angles)
		entity:Spawn()

		PLUGIN:saveVendors()

		return "@vendorMade"
	end
})

nut.command.add("vendorremove", {
	adminOnly = true,
	onRun = function(client, arguments)
		local entity = client:GetEyeTrace().Entity

		if (IsValid(entity) and entity:GetClass() == "nut_vendor") then
			entity:Remove()

			return "@vendorDeleted"
		else
			return "@vendorNotValid"
		end
	end
})