ITEM.name = "Bag"
ITEM.desc = "A bag to hold items."
ITEM.model = "models/props_c17/suitcase001a.mdl"
ITEM.category = "Storage"
ITEM.width = 2
ITEM.height = 2
ITEM.invWidth = 4
ITEM.invHeight = 2
ITEM.isBag = true
ITEM.functions.View = {
	icon = "icon16/briefcase.png",
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
				panel:SetTitle(item.getName and item:getName() or L(item.name))

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

	nut.item.newInv(inventory and inventory.owner or 0, self.uniqueID, function(inventory)
		inventory.vars.isBag = self.uniqueID
		self:setData("id", inventory:getID())
	end)
end

function ITEM:getInv()
	local index = self:getData("id")

	if (index) then
		return nut.item.inventories[index]
	end
end

-- Called when the item first appears for a client.
function ITEM:onSendData()
	local index = self:getData("id")

	if (index) then
		local inventory = nut.item.inventories[index]

		if (inventory) then
			inventory.vars.isBag = self.uniqueID
			inventory:sync(self.player)
		else
			local owner = self.player:getChar():getID()

			nut.item.restoreInv(self:getData("id"), self.invWidth, self.invHeight, function(inventory)
				inventory.vars.isBag = self.uniqueID
				inventory:setOwner(owner, true)
			end)
		end
	else
		local inventory = nut.item.inventories[self.invID]
		local client = self.player

		nut.item.newInv(self.player:getChar():getID(), self.uniqueID, function(inventory)
			self:setData("id", inventory:getID())
		end)
	end
end

ITEM.postHooks.drop = function(item, result)
	local index = item:getData("id")

	nut.db.query("UPDATE nut_inventories SET _charID = 0 WHERE _invID = "..index)
	netstream.Start(item.player, "nutBagDrop", index)
end

if (CLIENT) then
	netstream.Hook("nutBagDrop", function(index)
		local panel = nut.gui["inv"..index]

		if (panel and panel:IsVisible()) then
			panel:Close()
		end
	end)
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
	local index = self:getData("id")

	if (newInventory) then
		if (newInventory.vars and newInventory.vars.isBag) then
			return false
		end

		local index2 = newInventory:getID()

		if (index == index2) then
			return false
		end

		for k, v in pairs(self:getInv():getItems()) do
			if (v:getData("id") == index2) then
				return false
			end
		end
	end
	
	return !newInventory or newInventory:getID() != oldInventory:getID() or newInventory.vars.isBag
end

-- Called after the item is registered into the item tables.
function ITEM:onRegistered()
	nut.item.registerInv(self.uniqueID, self.invWidth, self.invHeight, true)
end