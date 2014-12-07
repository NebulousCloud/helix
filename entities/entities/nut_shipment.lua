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

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Shipment"
ENT.Category = "NutScript"
ENT.Spawnable = false

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/Items/item_item_crate.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:Use(activator)
		print(activator)
		if (activator:getChar() and activator:getChar():getID() == self:getNetVar("owner", 0) and hook.Run("PlayerCanOpenShipment", activator, self) != false) then
			netstream.Start(activator, "openShp", self, self.items)
		end
	end

	function ENT:setItems(items)
		self.items = items
	end
else
	function ENT:onShouldDrawEntityInfo()
		return true
	end

	function ENT:onDrawEntityInfo(alpha)
		local position = self:LocalToWorld(self:OBBCenter()):ToScreen()
		local x, y = position.x, position.y
		local owner = nut.char.loaded[self:getNetVar("owner", 0)]

		nut.util.drawText(L"shipment", x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (owner) then
			nut.util.drawText(L("shipmentDesc", owner:getName()), x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end
	end
end