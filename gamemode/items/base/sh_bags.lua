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
			local inventory = LocalPlayer():getChar():getInv(index)	

			if (inventory and inventory.slots) then
				local panel = nut.gui.menu.panel:Add("nutInventory")
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