
--[[--
Player manipulation of inventories.

This library provides an easy way for players to manipulate other inventories. The only functions that you should need are
`ix.storage.Open` and `ix.storage.Close`. When opening an inventory as a storage item, it will display both the given inventory
and the player's inventory in the player's UI, which allows them to drag items to and from the given inventory.

Example usage:
	ix.storage.Open(client, inventory, {
		name = "Filing Cabinet",
		entity = ents.GetByIndex(3),
		bMultipleUsers = true,
		searchText = "Rummaging...",
		searchTime = 4
	})

## Storage info structure
There are some parameters you can customize when opening an inventory as a storage object with `ix.storage.Open`.
<ul>
<li><p>
`id`<br />
(default: id of inventory passed into `ix.storage.Open`)<br />
The ID of the inventory.
</p></li>

<li><p>
`name`<br />
(default: `"Storage"`)<br />
Title to display in the UI when the inventory is open.
</p></li>

<li><p>
`entity`<br />
(required)<br />
Entity to "attach" the inventory to. This is used to provide a location for the inventory for things like making sure the player
doesn't move too far away from the inventory, etc. This can also be a player.
</p></li>

<li><p>
`bMultipleUsers`<br />
(default: `false`)<br />
Whether or not multiple players are allowed to view this inventory at the same time.
</p></li>

<li><p>
`searchTime`<br />
(default: `0`)<br />
How long the player has to wait before the inventory is opened.
</p></li>

<li><p>
`searchText`<br />
(default: `"@storageSearching"`)<br />
Text to display to the user while opening the inventory. This can be a language phrase.
</p></li>

<li><p>
`OnPlayerClose`<br />
(default: `nil`)<br />
Called when a player who was accessing the inventory has closed it. The argument passed is the player who closed it.
</p></li>
</ul>
]]
-- @module ix.storage

ix.storage = ix.storage or {}

if (SERVER) then
	--- Returns all players that currently looking at the given inventory as a storage.
	-- @server
	-- @inventory inventory Inventory to get receivers from
	-- @treturn table An array of players that currently have `inventory` open
	function ix.storage.GetReceivers(inventory)
		local result = {}

		if (inventory.storageInfo) then
			for k, _ in pairs(inventory.storageInfo.receivers) do
				if (IsValid(k) and k:IsPlayer()) then
					result[#result + 1] = k
				end
			end
		end

		return result
	end

	--- Returns whether or not the given inventory has a storage context and is being looked at by other players.
	-- @server
	-- @inventory inventory Inventory to check
	-- @treturn bool Whether or not `inventory` is in use
	function ix.storage.InUse(inventory)
		if (inventory.storageInfo) then
			for k, _ in pairs(inventory.storageInfo.receivers) do
				if (IsValid(k) and k:IsPlayer()) then
					return true
				end
			end
		end

		return false
	end

	--- Creates a storage context on the given inventory. This is an internal function and shouldn't be used!
	-- @server
	-- @inventory inventory Inventory to create a storage context for
	-- @table info Information to store on the context
	function ix.storage.CreateContext(inventory, info)
		info = info or {}

		info.id = inventory:GetID()
		info.name = info.name or "Storage"
		info.entity = assert(IsValid(info.entity), "expected valid entity in info table") and info.entity
		info.bMultipleUsers = info.bMultipleUsers == nil and false or info.bMultipleUsers
		info.searchTime = tonumber(info.searchTime) or 0
		info.searchText = info.searchText or "@storageSearching"
		info.receivers = info.receivers or {}

		-- store old copies of inventory methods so we can restore them after we're done
		inventory.oldOnAuthorizeTransfer = inventory.OnAuthorizeTransfer
		inventory.oldGetReceiver = inventory.GetReceiver
		inventory.storageInfo = info

		if (info.entity:IsPlayer()) then
			inventory.oldCheckAccess = inventory.CheckAccess

			function inventory:OnCheckAccess(client)
				return self.storageInfo.receivers[client] == true
			end
		end

		function inventory:OnAuthorizeTransfer(inventoryClient, oldInventory, item)
			return IsValid(inventoryClient) and IsValid(self.storageInfo.entity) and self.storageInfo.receivers[inventoryClient] != nil
		end

		function inventory:GetReceiver()
			local result = ix.storage.GetReceivers(self)

			return #result > 0 and (#result == 1 and result[1] or result) or nil
		end
	end

	--- Removes a storage context from an inventory if it exists. This is an internal function and shouldn't be used!
	-- @server
	-- @inventory inventory Inventory to remove a storage context from
	function ix.storage.RemoveContext(inventory)
		-- restore old callbacks
		inventory.OnAuthorizeTransfer = inventory.oldOnAuthorizeTransfer
		inventory.GetReceiver = inventory.oldGetReceiver

		if (inventory.oldCheckAccess) then
			inventory.CheckAccess = inventory.oldCheckAccess
			inventory.oldCheckAccess = nil
		end

		inventory.oldOnAuthorizeTransfer = nil
		inventory.oldGetReceiver = nil
		inventory.storageInfo = nil
	end

	--- Synchronizes an inventory with a storage context to the given client.
	-- This is an internal function and shouldn't be used!
	-- @server
	-- @player client Player to sync storage for
	-- @inventory inventory Inventory to sync storage for
	function ix.storage.Sync(client, inventory)
		local info = inventory.storageInfo

		inventory:Sync(client)
		netstream.Start(client, "StorageOpen", info.id, info.entity, info.name)
	end

	--- Adds a receiver to a given inventory with a storage context. This is an internal function and shouldn't be used!
	-- @server
	-- @player client Player to sync storage for
	-- @inventory inventory Inventory to sync storage for
	-- @bool bDontSync Whether or not to skip syncing the storage to the client. If this is `true`, the storage panel will not
	-- show up for the player
	function ix.storage.AddReceiver(client, inventory, bDontSync)
		local info = inventory.storageInfo

		if (info and !info.receivers[client]) then
			if (info.entity:IsPlayer()) then
				if (client:GetCharacter() and client:GetCharacter():GetInventory()) then
					local receiverInventory = client:GetCharacter():GetInventory()

					-- do not override OnAuthorizeTransfer if the client's inventory
					-- is currently interacting with something
					if (receiverInventory.oldOnAuthorizeTransfer) then
						return false
					end

					function receiverInventory:OnAuthorizeTransfer(inventoryClient, oldInventory, item)
						if (oldInventory == inventory) then
							return true
						end

						receiverInventory:oldOnAuthorizeTransfer(inventoryClient, oldInventory, item)
					end
				end
			end

			info.receivers[client] = true
			client.ixOpenStorage = inventory

			if (!bDontSync) then
				ix.storage.Sync(client, inventory)
			end

			return true
		end

		return false
	end

	--- Removes a storage receiver and removes the context if there are no more receivers.
	-- This is an internal function and shouldn't be used!
	-- @server
	-- @player client Player to remove from receivers
	-- @inventory inventory Inventory with storage context to remove receiver from
	-- @bool bDontRemove Whether or not to skip removing the storage context if there are no more receivers
	function ix.storage.RemoveReceiver(client, inventory, bDontRemove)
		if (inventory.storageInfo) then
			-- restore old OnAuthorizeTransfer callback if it exists
			if (client:GetCharacter() and client:GetCharacter():GetInventory()) then
				local clientInventory = client:GetCharacter():GetInventory()

				if (clientInventory.oldOnAuthorizeTransfer) then
					clientInventory.OnAuthorizeTransfer = clientInventory.oldOnAuthorizeTransfer
					clientInventory.oldOnAuthorizeTransfer = nil
				end
			end

			inventory.storageInfo.receivers[client] = nil

			if (isfunction(inventory.storageInfo.OnPlayerClose)) then
				inventory.storageInfo.OnPlayerClose(client)
			end

			if (!bDontRemove and !ix.storage.InUse(inventory)) then
				ix.storage.RemoveContext(inventory)
			end

			client.ixOpenStorage = nil
			return true
		end

		return false
	end

	--- Makes a player open an inventory that they can interact with. This can be called multiple times on the same inventory,
	-- if the info passed allows for multiple users.
	-- @server
	-- @player client Player to open the inventory for
	-- @inventory inventory Inventory to open
	-- @table info Storage info (see <strong>Storage info structure</strong> for usage)
	function ix.storage.Open(client, inventory, info)
		assert(IsValid(client) and client:IsPlayer(), "expected valid player")
		assert(getmetatable(inventory) == ix.meta.inventory, "expected valid inventory")

		-- create storage context if one isn't already created
		if (!inventory.storageInfo) then
			info = info or {}
			ix.storage.CreateContext(inventory, info)
		end

		local storageInfo = inventory.storageInfo

		-- add the client to the list of receivers if we're allowed to have multiple users
		-- or if nobody else is occupying this inventory, otherwise nag the player
		if (storageInfo.bMultipleUsers or !ix.storage.InUse(inventory)) then
			ix.storage.AddReceiver(client, inventory, true)
		else
			client:NotifyLocalized("storageInUse")
			return
		end

		if (storageInfo.searchTime > 0) then
			client:SetAction(storageInfo.searchText, storageInfo.searchTime)
			client:DoStaredAction(storageInfo.entity, function()
				if (IsValid(client) and IsValid(storageInfo.entity) and inventory.storageInfo) then
					ix.storage.Sync(client, inventory)
				end
			end, storageInfo.searchTime, function()
				if (IsValid(client)) then
					ix.storage.RemoveReceiver(client, inventory)
					client:SetAction()
				end
			end)
		else
			ix.storage.Sync(client, inventory)
		end
	end

	--- Forcefully makes clients close this inventory if they have it open.
	-- @server
	-- @inventory inventory Inventory to close
	function ix.storage.Close(inventory)
		local receivers = ix.storage.GetReceivers(inventory)

		if (#receivers > 0) then
			netstream.Start(receivers, "StorageExpired", inventory.storageInfo.id)
		end

		ix.storage.RemoveContext(inventory)
	end

	netstream.Hook("StorageClose", function(client)
		local inventory = client.ixOpenStorage

		if (inventory) then
			ix.storage.RemoveReceiver(client, inventory)
		end
	end)
else
	netstream.Hook("StorageOpen", function(id, entity, name)
		local inventory = ix.item.inventories[id]

		if (IsValid(entity) and inventory and inventory.slots) then
			local localInventory = LocalPlayer():GetCharacter():GetInventory()
			local panel = vgui.Create("ixStorageView")

			if (localInventory) then
				panel:SetLocalInventory(localInventory)
			end

			panel:SetStorageTitle(name)
			panel:SetStorageInventory(inventory)
		end
	end)

	netstream.Hook("StorageExpired", function(id)
		if (IsValid(ix.gui.openedStorage)) then
			ix.gui.openedStorage:Remove()
		end

		if (id != 0) then
			ix.item.inventories[id] = nil
		end
	end)
end
