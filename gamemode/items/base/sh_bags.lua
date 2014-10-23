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

ITEM.name = "Bag"
ITEM.desc = "A bag to hold items."
ITEM.model = "models/props_c17/suitcase001a.mdl"
ITEM.width = 2
ITEM.height = 2
ITEM.invWidth = 4
ITEM.invHeight = 2
ITEM.functions.View = {
	onClick = function(item)
		local index = item:getData("id")

		if (index) then
			local panel = nut.gui["inv"..index]
			local inventory = LocalPlayer():getChar():getInv(index)	
			
			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory and inventory.slots) then
				panel = nut.gui.menu.panel:Add("nutInventory")
				panel:setInventory(inventory)
				panel:ShowCloseButton(true)
				panel:SetTitle(item.name)

				nut.gui["inv"..index] = panel
			end
		end

		return false
	end,
	onCanRun = function(item)
		return !IsValid(item.entity) and item:getData("id")
	end
}

function ITEM:onInstanced(invID, x, y)
	local inventory = nut.item.inventories[invID]

	if (inventory) then
		nut.item.newInv(inventory.owner, self.uniqueID, function(inventory)
			self:setData("id", inventory:getID())
		end)
	end
end

function ITEM:onRemoved()
	local index = self:getData("id")

	if (index) then
		nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
		nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)
	end
end

function ITEM:onRegistered()
	nut.item.registerInv(self.uniqueID, self.invWidth, self.invHeight)
end