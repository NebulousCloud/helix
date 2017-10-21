
nut.storage = nut.storage or {}

--[[
	This library is used for abstracting away the mess of overriding functions and
	making your own panels when you want to want a player to be able to view/modify an inventory.

	You should always pass in the same data in the info table for the same inventory if called
	multiple times for different users. The entity field is used to "attach" an inventory to
	a physical object and is required to function.

	example:
	nut.storage.Open(client, inventory, {
		name = "Filing Cabinet", 		-- defaults to "Storage"
		entity = ents.GetByIndex(3), 	-- this is required
		bMultipleUsers = true 			-- defaults to false
	})
]]--

if (SERVER) then
	-- Returns an array of people that currently have this inventory open.
	function nut.storage.GetReceivers(inventory)
		local result = {}

		if (inventory.storageInfo) then
			for k, v in pairs(inventory.storageInfo.receivers) do
				if (IsValid(k) and k:IsPlayer()) then
					result[#result + 1] = k
				end
			end
		end

		return result
	end

	-- Returns true if this inventory has a storage context and is in use by at least one person.
	function nut.storage.InUse(inventory)
		if (inventory.storageInfo) then
			for k, v in pairs(inventory.storageInfo.receivers) do
				if (IsValid(k) and k:IsPlayer()) then
					return true
				end
			end
		end

		return false
	end

	-- Creates a storage context on the given inventory.
	function nut.storage.CreateContext(inventory, info)
		info = info or {}

		info.id = inventory:GetID()
		info.name = info.name or "Storage"
		info.entity = assert(IsValid(info.entity), "expected valid entity in info table") and info.entity
		info.bMultipleUsers = info.bMultipleUsers == nil and false or info.bMultipleUsers
		info.receivers = info.receivers or {}

		-- store old copies of inventory methods so we can restore them after we're done
		inventory.oldOnAuthorizeTransfer = inventory.OnAuthorizeTransfer
		inventory.oldGetReceiver = inventory.GetReceiver
		inventory.storageInfo = info
		
		function inventory:OnAuthorizeTransfer(inventoryClient, oldInventory, item)
			return IsValid(inventoryClient) and IsValid(self.storageInfo.entity) and self.storageInfo.receivers[inventoryClient] != nil
		end

		function inventory:GetReceiver()
			local result = nut.storage.GetReceivers(self)

			return #result > 0 and result or nil
		end
	end

	-- Removes a storage context from an inventory if it exists.
	function nut.storage.RemoveContext(inventory)
		-- restore old callbacks
		inventory.OnAuthorizeTransfer = inventory.oldOnAuthorizeTransfer
		inventory.GetReceiver = inventory.oldGetReceiver

		inventory.storageInfo = nil
	end

	-- Makes a player open an inventory that they can interact with.
	-- This takes care of making a storage context if one doesn't exist, and adds the player
	-- to the list of people that can view this inventory.
	function nut.storage.Open(client, inventory, info)
		assert(IsValid(client) and client:IsPlayer(), "expected valid player")
		assert(getmetatable(inventory) == nut.meta.inventory, "expected valid inventory")

		-- create storage context if one isn't already created
		if (!inventory.storageInfo) then
			info = info or {}
			nut.storage.CreateContext(inventory, info)
		end

		-- add the client to the list of receivers if we're allowed to have multiple users
		-- or if nobody else is occupying this inventory, otherwise nag the player
		if (inventory.storageInfo.bMultipleUsers or !nut.storage.InUse(inventory)) then
			inventory.storageInfo.receivers[client] = true
		else
			client:NotifyLocalized("storageInUse")
			return
		end

		client.nutOpenStorage = inventory

		inventory:Sync(client)
		netstream.Start(client, "StorageOpen", info)
	end

	-- Forcefully makes clients close this inventory if they have it open and
	-- clears the storage context on the inventory if it exists.
	function nut.storage.Close(inventory)
		local receivers = nut.storage.GetReceivers(inventory)

		if (#receivers > 0) then
			netstream.Start(receivers, "StorageExpired", inventory.storageInfo)
		end

		nut.storage.RemoveContext(inventory)
	end

	netstream.Hook("StorageClose", function(client)
		local inventory = client.nutOpenStorage

		if (inventory) then
			local info = inventory.storageInfo
			
			if (info.receivers[client]) then
				info.receivers[client] = nil

				if (info.bMultipleUsers) then
					if (!nut.storage.InUse(inventory)) then
						nut.storage.RemoveContext(inventory)
					end
				else
					nut.storage.RemoveContext(inventory)
				end
			end

			client.nutOpenStorage = nil
		end
	end)
else
	netstream.Hook("StorageOpen", function(info)
		local inventory = nut.item.inventories[info.id]

		if (IsValid(info.entity) and inventory and inventory.slots) then
			local localInventory = LocalPlayer():GetCharacter():GetInventory()
			local panel = vgui.Create("nutStorageView")

			if (localInventory) then
				panel:SetLocalInventory(localInventory)
			end

			panel:SetStorageTitle(info.name)
			panel:SetStorageInventory(inventory)
		end
	end)

	netstream.Hook("StorageExpired", function(info)
		if (IsValid(nut.gui.openedStorage)) then
			nut.gui.openedStorage:Remove()
		end

		if (info.id != 0) then
			nut.item.inventories[info.id] = nil
		end
	end)
end
