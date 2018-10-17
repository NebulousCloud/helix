
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

<li><p>
`data`<br />
(default: `{}`)<br />
Table of arbitrary data to send to the client when the inventory has been opened.
</p></li>
</ul>
]]
-- @module ix.storage

ix.storage = ix.storage or {}

if (SERVER) then
	util.AddNetworkString("ixStorageOpen")
	util.AddNetworkString("ixStorageClose")
	util.AddNetworkString("ixStorageExpired")
	util.AddNetworkString("ixStorageMoneyTake")
	util.AddNetworkString("ixStorageMoneyGive")
	util.AddNetworkString("ixStorageMoneyUpdate")

	--- Returns whether or not the given inventory has a storage context and is being looked at by other players.
	-- @server
	-- @inventory inventory Inventory to check
	-- @treturn bool Whether or not `inventory` is in use
	function ix.storage.InUse(inventory)
		if (inventory.storageInfo) then
			for _, v in pairs(inventory:GetReceivers()) do
				if (IsValid(v) and v:IsPlayer() and v != inventory.storageInfo.entity) then
					return true
				end
			end
		end

		return false
	end

	--- Creates a storage context on the given inventory.
	-- @server
	-- @internal
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
		info.data = info.data or {}

		inventory.storageInfo = info

		-- remove context from any bags this inventory might have
		for _, v in pairs(inventory:GetItems()) do
			if (v.isBag and v:GetInventory()) then
				ix.storage.CreateContext(v:GetInventory(), table.Copy(info))
			end
		end
	end

	--- Removes a storage context from an inventory if it exists.
	-- @server
	-- @internal
	-- @inventory inventory Inventory to remove a storage context from
	function ix.storage.RemoveContext(inventory)
		inventory.storageInfo = nil

		-- remove context from any bags this inventory might have
		for _, v in pairs(inventory:GetItems()) do
			if (v.isBag and v:GetInventory()) then
				ix.storage.RemoveContext(v:GetInventory())
			end
		end
	end

	--- Synchronizes an inventory with a storage context to the given client.
	-- @server
	-- @internal
	-- @player client Player to sync storage for
	-- @inventory inventory Inventory to sync storage for
	function ix.storage.Sync(client, inventory)
		local info = inventory.storageInfo

		-- we'll retrieve the money value as we're syncing because it may have changed while
		-- we were waiting for the timer to finish
		if (info.entity.GetMoney) then
			info.data.money = info.entity:GetMoney()
		elseif (info.entity:IsPlayer() and info.entity:GetCharacter()) then
			info.data.money = info.entity:GetCharacter():GetMoney()
		end

		-- bags are automatically sync'd when the owning inventory is sync'd
		inventory:Sync(client)

		net.Start("ixStorageOpen")
			net.WriteUInt(info.id, 32)
			net.WriteEntity(info.entity)
			net.WriteString(info.name)
			net.WriteTable(info.data)
		net.Send(client)
	end

	--- Adds a receiver to a given inventory with a storage context.
	-- @server
	-- @internal
	-- @player client Player to sync storage for
	-- @inventory inventory Inventory to sync storage for
	-- @bool bDontSync Whether or not to skip syncing the storage to the client. If this is `true`, the storage panel will not
	-- show up for the player
	function ix.storage.AddReceiver(client, inventory, bDontSync)
		local info = inventory.storageInfo

		if (info) then
			inventory:AddReceiver(client)
			client.ixOpenStorage = inventory

			-- update receivers for any bags this inventory might have
			for _, v in pairs(inventory:GetItems()) do
				if (v.isBag and v:GetInventory()) then
					v:GetInventory():AddReceiver(client)
				end
			end

			if (!bDontSync) then
				ix.storage.Sync(client, inventory)
			end

			return true
		end

		return false
	end

	--- Removes a storage receiver and removes the context if there are no more receivers.
	-- @server
	-- @internal
	-- @player client Player to remove from receivers
	-- @inventory inventory Inventory with storage context to remove receiver from
	-- @bool bDontRemove Whether or not to skip removing the storage context if there are no more receivers
	function ix.storage.RemoveReceiver(client, inventory, bDontRemove)
		if (inventory.storageInfo) then
			inventory:RemoveReceiver(client)

			-- update receivers for any bags this inventory might have
			for _, v in pairs(inventory:GetItems()) do
				if (v.isBag and v:GetInventory()) then
					v:GetInventory():RemoveReceiver(client)
				end
			end

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
		local receivers = inventory:GetReceivers()

		if (#receivers > 0) then
			net.Start("ixStorageExpired")
				net.WriteUInt(inventory.storageInfo.id, 32)
			net.Send(receivers)
		end

		ix.storage.RemoveContext(inventory)
	end

	net.Receive("ixStorageClose", function(length, client)
		local inventory = client.ixOpenStorage

		if (inventory) then
			ix.storage.RemoveReceiver(client, inventory)
		end
	end)

	net.Receive("ixStorageMoneyTake", function(length, client)
		if (CurTime() < (client.ixStorageMoneyTimer or 0)) then
			return
		end

		local character = client:GetCharacter()

		if (!character) then
			return
		end

		local storageID = net.ReadUInt(32)
		local amount = net.ReadUInt(32)

		local inventory = client.ixOpenStorage

		if (!inventory or !inventory.storageInfo or storageID != inventory:GetID()) then
			return
		end

		local entity = inventory.storageInfo.entity

		if (!IsValid(entity) or
			(!entity:IsPlayer() and (!isfunction(entity.GetMoney) or !isfunction(entity.SetMoney))) or
			(entity:IsPlayer() and !entity:GetCharacter())) then
			return
		end

		entity = entity:IsPlayer() and entity:GetCharacter() or entity
		amount = math.Clamp(math.Round(tonumber(amount) or 0), 0, entity:GetMoney())

		if (amount == 0) then
			return
		end

		character:SetMoney(character:GetMoney() + amount)

		local total = entity:GetMoney() - amount
		entity:SetMoney(total)

		net.Start("ixStorageMoneyUpdate")
			net.WriteUInt(storageID, 32)
			net.WriteUInt(total, 32)
		net.Send(inventory:GetReceivers())

		ix.log.Add(client, "storageMoneyTake", entity, amount, total)

		client.ixStorageMoneyTimer = CurTime() + 0.5
	end)

	net.Receive("ixStorageMoneyGive", function(length, client)
		if (CurTime() < (client.ixStorageMoneyTimer or 0)) then
			return
		end

		local character = client:GetCharacter()

		if (!character) then
			return
		end

		local storageID = net.ReadUInt(32)
		local amount = net.ReadUInt(32)

		local inventory = client.ixOpenStorage

		if (!inventory or !inventory.storageInfo or storageID != inventory:GetID()) then
			return
		end

		local entity = inventory.storageInfo.entity

		if (!IsValid(entity) or
			(!entity:IsPlayer() and (!isfunction(entity.GetMoney) or !isfunction(entity.SetMoney))) or
			(entity:IsPlayer() and !entity:GetCharacter())) then
			return
		end

		entity = entity:IsPlayer() and entity:GetCharacter() or entity
		amount = math.Clamp(math.Round(tonumber(amount) or 0), 0, character:GetMoney())

		if (amount == 0) then
			return
		end

		character:SetMoney(character:GetMoney() - amount)

		local total = entity:GetMoney() + amount
		entity:SetMoney(total)

		net.Start("ixStorageMoneyUpdate")
			net.WriteUInt(storageID, 32)
			net.WriteUInt(total, 32)
		net.Send(inventory:GetReceivers())

		ix.log.Add(client, "storageMoneyGive", entity, amount, total)

		client.ixStorageMoneyTimer = CurTime() + 0.5
	end)
else
	net.Receive("ixStorageOpen", function()
		if (IsValid(ix.gui.menu)) then
			net.Start("ixStorageClose")
			net.SendToServer()
			return
		end

		local id = net.ReadUInt(32)
		local entity = net.ReadEntity()
		local name = net.ReadString()
		local data = net.ReadTable()

		local inventory = ix.item.inventories[id]

		if (IsValid(entity) and inventory and inventory.slots) then
			local localInventory = LocalPlayer():GetCharacter():GetInventory()
			local panel = vgui.Create("ixStorageView")

			if (localInventory) then
				panel:SetLocalInventory(localInventory)
			end

			panel:SetStorageID(id)
			panel:SetStorageTitle(name)
			panel:SetStorageInventory(inventory)

			if (data.money) then
				if (localInventory) then
					panel:SetLocalMoney(LocalPlayer():GetCharacter():GetMoney())
				end

				panel:SetStorageMoney(data.money)
			end
		end
	end)

	net.Receive("ixStorageExpired", function()
		if (IsValid(ix.gui.openedStorage)) then
			ix.gui.openedStorage:Remove()
		end

		local id = net.ReadUInt(32)

		if (id != 0) then
			ix.item.inventories[id] = nil
		end
	end)

	net.Receive("ixStorageMoneyUpdate", function()
		local storageID = net.ReadUInt(32)
		local amount = net.ReadUInt(32)

		local panel = ix.gui.openedStorage

		if (!IsValid(panel) or panel:GetStorageID() != storageID) then
			return
		end

		panel:SetStorageMoney(amount)
		panel:SetLocalMoney(LocalPlayer():GetCharacter():GetMoney())
	end)
end
