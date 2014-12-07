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
ITEM.category = "Storage"
ITEM.width = 2
ITEM.height = 2
ITEM.invWidth = 4
ITEM.invHeight = 2
ITEM.functions.View = {
	onClick = function(item)
		local index = item:getData("id")

		if (index) then
			local panel = nut.gui["inv"..index]
			local parent = item.invID and nut.gui["inv"..item.invID] or nil
			local inventory = nut.item.inventories[index]
			
			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory and inventory.slots) then
				panel = vgui.Create("nutInventory", parent)
				panel:setInventory(inventory)
				panel:ShowCloseButton(true)
				panel:SetTitle(item.name)

				nut.gui["inv"..index] = panel
			else
				ErrorNoHalt("[NutScript] Attempt to view an uninitialized inventory '"..index.."'\n")
			end
		end

		return false
	end,
	onCanRun = function(item)
		return !IsValid(item.entity) and item:getData("id")
	end
}

-- Called when a new instance of this item has been made.
function ITEM:onInstanced(invID, x, y)
	local inventory = nut.item.inventories[invID]

	if (inventory) then
		nut.item.newInv(inventory.owner, self.uniqueID, function(inventory)
			self:setData("id", inventory:getID())
		end)
	end
end

-- Called when the item first appears for a client.
function ITEM:onSendData(client)
	local inventory = nut.item.inventories[self:getData("id")]

	if (inventory) then
		inventory:sync(client)
	end
end

-- Called before the item is permanently deleted.
function ITEM:onRemoved()
	local index = self:getData("id")

	if (index) then
		nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
		nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)
	end
end

-- Called when the item should tell whether or not it can be transfered between inventories.
function ITEM:onCanBeTransfered(oldInventory, newInventory)
	if (newInventory and newInventory:getID() == self:getData("id")) then
		return false
	end

	return !newInventory or newInventory:getID() != oldInventory:getID()
end

-- Called after the item is registered into the item tables.
function ITEM:onRegistered()
	nut.item.registerInv(self.uniqueID, self.invWidth, self.invHeight)
end