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
	OnClick = function(item)
		local index = item:GetData("id")

		if (index) then
			local panel = nut.gui["inv"..index]
			local parent = item.invID and nut.gui["inv"..item.invID] or nil
			local inventory = nut.item.inventories[index]
			
			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory and inventory.slots) then
				panel = vgui.Create("nutInventory", parent)
				panel:SetInventory(inventory)
				panel:ShowCloseButton(true)
				panel:SetTitle(item.GetName and item:GetName() or L(item.name))

				nut.gui["inv"..index] = panel
			else
				ErrorNoHalt("[NutScript] Attempt to view an uninitialized inventory '"..index.."'\n")
			end
		end

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity) and item:GetData("id")
	end
}

-- Called when a new instance of this item has been made.
function ITEM:OnInstanced(invID, x, y)
	local inventory = nut.item.inventories[invID]

	nut.item.NewInv(inventory and inventory.owner or 0, self.uniqueID, function(inventory)
		inventory.vars.isBag = self.uniqueID
		self:SetData("id", inventory:GetID())
	end)
end

function ITEM:GetInv()
	local index = self:GetData("id")

	if (index) then
		return nut.item.inventories[index]
	end
end

-- Called when the item first appears for a client.
function ITEM:OnSendData()
	local index = self:GetData("id")

	if (index) then
		local inventory = nut.item.inventories[index]

		if (inventory) then
			inventory.vars.isBag = self.uniqueID
			inventory:Sync(self.player)
		else
			local owner = self.player:GetChar():GetID()

			nut.item.RestoreInv(self:GetData("id"), self.invWidth, self.invHeight, function(inventory)
				inventory.vars.isBag = self.uniqueID
				inventory:SetOwner(owner, true)
			end)
		end
	else
		local inventory = nut.item.inventories[self.invID]
		local client = self.player

		nut.item.NewInv(self.player:GetChar():GetID(), self.uniqueID, function(inventory)
			self:SetData("id", inventory:GetID())
		end)
	end
end

ITEM.postHooks.drop = function(item, result)
	local index = item:GetData("id")

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
function ITEM:OnRemoved()
	local index = self:GetData("id")

	if (index) then
		nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
		nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)
	end
end

-- Called when the item should tell whether or not it can be transfered between inventories.
function ITEM:OnCanBeTransfered(oldInventory, newInventory)
	local index = self:GetData("id")

	if (newInventory) then
		if (newInventory.vars and newInventory.vars.isBag) then
			return false
		end

		local index2 = newInventory:GetID()

		if (index == index2) then
			return false
		end

		for k, v in pairs(self:GetInv():GetItems()) do
			if (v:GetData("id") == index2) then
				return false
			end
		end
	end
	
	return !newInventory or newInventory:GetID() != oldInventory:GetID() or newInventory.vars.isBag
end

-- Called after the item is registered into the item tables.
function ITEM:OnRegistered()
	nut.item.RegisterInv(self.uniqueID, self.invWidth, self.invHeight, true)
end