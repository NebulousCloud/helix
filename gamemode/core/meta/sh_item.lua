
--[[--
Interactable entities that can be held in inventories.

Items are objects that are contained inside of an `Inventory`, or as standalone entities if they are dropped in the world. They
usually have functionality that provides more gameplay aspects to the schema. For example, the zipties in the HL2 RP schema
allow a player to tie up and search a player.

For an item to have an actual presence, they need to be instanced (usually with `ix.item.Instance`). Items describe the
properties, while instances are a clone of these properties that can have their own unique data (e.g an ID card will have the
same name but different numerical IDs). You can think of items as the class, while instances are objects of the `Item` class.
]]
-- @classmod Item

local ITEM = ix.meta.item or {}
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.description = ITEM.description or "An item that is undefined."
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"

--- Returns a string representation of this item.
-- @realm shared
-- @treturn string String representation
-- @usage print(ix.item.instances[1])
-- > "item[1]"
function ITEM:__tostring()
	return "item["..self.uniqueID.."]["..self.id.."]"
end

--- Returns true if this item is equal to another item. Internally, this checks item IDs.
-- @realm shared
-- @item other Item to compare to
-- @treturn bool Whether or not this item is equal to the given item
-- @usage print(ix.item.instances[1] == ix.item.instances[2])
-- > false
function ITEM:__eq(other)
	return self:GetID() == other:GetID()
end

--- Returns this item's database ID. This is guaranteed to be unique.
-- @realm shared
-- @treturn number Unique ID of item
function ITEM:GetID()
	return self.id
end

--- Returns the name of the item.
-- @realm shared
-- @treturn string The name of the item
function ITEM:GetName()
	return (CLIENT and L(self.name) or self.name)
end

--- Returns the description of the item.
-- @realm shared
-- @treturn string The description of the item
function ITEM:GetDescription()
	if (!self.description) then return "ERROR" end

	return L(self.description or "noDesc")
end

--- Returns the model of the item.
-- @realm shared
-- @treturn string The model of the item
function ITEM:GetModel()
	return self.model
end

--- Returns the skin of the item.
-- @realm shared
-- @treturn number The skin of the item
function ITEM:GetSkin()
	return self.skin or 0
end

function ITEM:GetMaterial()
	return nil
end

--- Returns the ID of the owning character, if one exists.
-- @realm shared
-- @treturn number The owning character's ID
function ITEM:GetCharacterID()
	return self.characterID
end

--- Returns the SteamID64 of the owning player, if one exists.
-- @realm shared
-- @treturn number The owning player's SteamID64
function ITEM:GetPlayerID()
	return self.playerID
end

--- A utility function which prints the item's details.
-- @realm shared
-- @bool[opt=false] detail Whether additional detail should be printed or not(Owner, X position, Y position)
function ITEM:Print(detail)
	if (detail == true) then
		print(Format("%s[%s]: >> [%s](%s,%s)", self.uniqueID, self.id, self.owner, self.gridX, self.gridY))
	else
		print(Format("%s[%s]", self.uniqueID, self.id))
	end
end

--- A utility function printing the item's stored data.
-- @realm shared
function ITEM:PrintData()
	self:Print(true)
	print("ITEM DATA:")
	for k, v in pairs(self.data) do
		print(Format("[%s] = %s", k, v))
	end
end

--- Calls one of the item's methods.
-- @realm shared
-- @string method The method to be called
-- @player client The client to pass when calling the method, if applicable
-- @entity entity The eneity to pass when calling the method, if applicable
-- @param ... Arguments to pass to the method
-- @return The values returned by the method
function ITEM:Call(method, client, entity, ...)
	local oldPlayer, oldEntity = self.player, self.entity

	self.player = client or self.player
	self.entity = entity or self.entity

	if (isfunction(self[method])) then
		local results = {self[method](self, ...)}

		self.player = nil
		self.entity = nil

		return unpack(results)
	end

	self.player = oldPlayer
	self.entity = oldEntity
end

--- Returns the owner of the item.
-- @realm shared
-- @treturn Character The character owning the item
function ITEM:GetOwner()
	local inventory = ix.item.inventories[self.invID]

	if (inventory) then
		return inventory.GetOwner and inventory:GetOwner()
	end

	local id = self:GetID()

	for _, v in ipairs(player.GetAll()) do
		local character = v:GetCharacter()

		if (character and character:GetInventory():GetItemByID(id)) then
			return v
		end
	end
end

--- Sets a key within the item's data.
-- @realm shared
-- @string key The key to store the value within
-- @param[opt=nil] value The value to store within the key
-- @tab[opt=nil] receivers The players to replicate the data on
-- @bool[opt=false] noSave Whether to disable saving the data on the database or not
-- @bool[opt=false] noCheckEntity Whether to disable setting the data on the entity, if applicable
function ITEM:SetData(key, value, receivers, noSave, noCheckEntity)
	self.data = self.data or {}
	self.data[key] = value

	if (SERVER) then
		if (!noCheckEntity) then
			local ent = self:GetEntity()

			if (IsValid(ent)) then
				local data = ent:GetNetVar("data", {})
				data[key] = value

				ent:SetNetVar("data", data)
			end
		end
	end

	if (receivers != false and (receivers or self:GetOwner())) then
		net.Start("ixInventoryData")
			net.WriteUInt(self:GetID(), 32)
			net.WriteString(key)
			net.WriteType(value)
		net.Send(receivers or self:GetOwner())
	end

	if (!noSave and ix.db) then
		local query = mysql:Update("ix_items")
			query:Update("data", util.TableToJSON(self.data))
			query:Where("item_id", self:GetID())
		query:Execute()
	end
end

--- Returns the value stored on a key within the item's data.
-- @realm shared
-- @string key The key in which the value is stored
-- @param[opt=nil] default The value to return in case there is no value stored in the key
-- @return The value stored within the key
function ITEM:GetData(key, default)
	self.data = self.data or {}

	if (self.data) then
		if (key == true) then
			return self.data
		end

		local value = self.data[key]

		if (value != nil) then
			return value
		elseif (IsValid(self.entity)) then
			local data = self.entity:GetNetVar("data", {})
			value = data[key]

			if (value != nil) then
				return value
			end
		end
	else
		self.data = {}
	end

	if (default != nil) then
		return default
	end

	return
end

--- Changes the function called on specific events for the item.
-- @realm shared
-- @string name The name of the hook
-- @func func The function to call once the event occurs
function ITEM:Hook(name, func)
	if (name) then
		self.hooks[name] = func
	end
end

--- Changes the function called after hooks for specific events for the item.
-- @realm shared
-- @string name The name of the hook
-- @func func The function to call after the original hook was called
function ITEM:PostHook(name, func)
	if (name) then
		self.postHooks[name] = func
	end
end

--- Removes the item.
-- @realm shared
-- @bool bNoReplication Whether or not the item's removal should not be replicated.
-- @bool bNoDelete Whether or not the item should not be fully deleted
-- @treturn bool Whether the item was successfully deleted or not
function ITEM:Remove(bNoReplication, bNoDelete)
	local inv = ix.item.inventories[self.invID]

	if (self.invID > 0 and inv) then
		local failed = false

		for x = self.gridX, self.gridX + (self.width - 1) do
			if (inv.slots[x]) then
				for y = self.gridY, self.gridY + (self.height - 1) do
					local item = inv.slots[x][y]

					if (item and item.id == self.id) then
						inv.slots[x][y] = nil
					else
						failed = true
					end
				end
			end
		end

		if (failed) then
			local items = inv:GetItems()

			inv.slots = {}
			for _, v in pairs(items) do
				if (v.invID == inv:GetID()) then
					for x = self.gridX, self.gridX + (self.width - 1) do
						for y = self.gridY, self.gridY + (self.height - 1) do
							inv.slots[x][y] = v.id
						end
					end
				end
			end

			if (IsValid(inv.owner) and inv.owner:IsPlayer()) then
				inv:Sync(inv.owner, true)
			end

			return false
		end
	else
		-- @todo definition probably isn't needed
		inv = ix.item.inventories[self.invID]

		if (inv) then
			ix.item.inventories[self.invID][self.id] = nil
		end
	end

	if (SERVER and !bNoReplication) then
		local entity = self:GetEntity()

		if (IsValid(entity)) then
			entity:Remove()
		end

		local receivers = inv.GetReceivers and inv:GetReceivers()

		if (self.invID != 0 and istable(receivers)) then
			net.Start("ixInventoryRemove")
				net.WriteUInt(self.id, 32)
				net.WriteUInt(self.invID, 32)
			net.Send(receivers)
		end

		if (!bNoDelete) then
			local item = ix.item.instances[self.id]

			if (item and item.OnRemoved) then
				item:OnRemoved()
			end

			local query = mysql:Delete("ix_items")
				query:Where("item_id", self.id)
			query:Execute()

			ix.item.instances[self.id] = nil
		end
	end

	return true
end

if (SERVER) then
	--- Returns the item's entity.
	-- @realm server
	-- @treturn entity The entity of the item
	function ITEM:GetEntity()
		local id = self:GetID()

		for _, v in ipairs(ents.FindByClass("ix_item")) do
			if (v.ixItemID == id) then
				return v
			end
		end
	end

	--- Spawn an item entity based off the item table.
	-- @realm server
	-- @param[type=vector] position The position in which the item's entity will be spawned
	-- @param[type=angle] angles The angles at which the item's entity will spawn
	-- @treturn entity The spawned entity
	function ITEM:Spawn(position, angles)
		-- Check if the item has been created before.
		if (ix.item.instances[self.id]) then
			local client

			-- Spawn the actual item entity.
			local entity = ents.Create("ix_item")
			entity:Spawn()
			entity:SetAngles(angles or Angle(0, 0, 0))
			-- Make the item represent this item.
			entity:SetItem(self.id)

			-- If the first argument is a player, then we will find a position to drop
			-- the item based off their aim.
			if (type(position) == "Player") then
				client = position
				position = position:GetItemDropPos(entity)
			end

			entity:SetPos(position)

			if (IsValid(client)) then
				entity.ixSteamID = client:SteamID()
				entity.ixCharID = client:GetCharacter():GetID()
				entity:SetNetVar("owner", entity.ixCharID)
			end

			-- Return the newly created entity.
			return entity
		end
	end

	--- Transfers an item to a specific inventory.
	-- @realm server
	-- @number invID The inventory to transfer the item to
	-- @number x The X position to which the item should be transferred on the new inventory
	-- @number y The Y position to which the item should be transferred on the new inventory
	-- @player client The player to which the item is being transferred
	-- @bool noReplication Whether there should be no replication of the transferral
	-- @bool isLogical Whether or not an entity should spawn if the item is transferred to the world
	-- @treturn[1] bool Whether the transfer was successful or not
	-- @treturn[2] string The error, if applicable
	function ITEM:Transfer(invID, x, y, client, noReplication, isLogical)
		invID = invID or 0

		if (self.invID == invID) then
			return false, "same inv"
		end

		local inventory = ix.item.inventories[invID]
		local curInv = ix.item.inventories[self.invID or 0]

		if (curInv and !IsValid(client)) then
			client = curInv.GetOwner and curInv:GetOwner() or nil
		end

		-- check if this item doesn't belong to another one of this player's characters
		local itemPlayerID = self:GetPlayerID()
		local itemCharacterID = self:GetCharacterID()

		if (!self.bAllowMultiCharacterInteraction and IsValid(client) and client:GetCharacter()) then
			local playerID = client:SteamID64()
			local characterID = client:GetCharacter():GetID()

			if (itemPlayerID and itemCharacterID) then
				if (itemPlayerID == playerID and itemCharacterID != characterID) then
					return false, "itemOwned"
				end
			else
				self.characterID = characterID
				self.playerID = playerID

				local query = mysql:Update("ix_items")
					query:Update("character_id", characterID)
					query:Update("player_id", playerID)
					query:Where("item_id", self:GetID())
				query:Execute()
			end
		end

		if (hook.Run("CanTransferItem", self, curInv, inventory) == false) then
			return false, "notAllowed"
		end

		local authorized = false

		if (inventory and inventory.OnAuthorizeTransfer and inventory:OnAuthorizeTransfer(client, curInv, self)) then
			authorized = true
		end

		if (!authorized and self.CanTransfer and self:CanTransfer(curInv, inventory) == false) then
			return false, "notAllowed"
		end

		if (curInv) then
			if (invID and invID > 0 and inventory) then
				local targetInv = inventory
				local bagInv

				if (!x and !y) then
					x, y, bagInv = inventory:FindEmptySlot(self.width, self.height)
				end

				if (bagInv) then
					targetInv = bagInv
				end

				if (!x or !y) then
					return false, "noFit"
				end

				local prevID = self.invID
				local status, result = targetInv:Add(self.id, nil, nil, x, y, noReplication)

				if (status) then
					if (self.invID > 0 and prevID != 0) then
						-- we are transferring this item from one inventory to another
						curInv:Remove(self.id, false, true, true)
						self.invID = invID

						if (self.OnTransferred) then
							self:OnTransferred(curInv, inventory)
						end

						hook.Run("OnItemTransferred", self, curInv, inventory)
						return true
					elseif (self.invID > 0 and prevID == 0) then
						-- we are transferring this item from the world to an inventory
						ix.item.inventories[0][self.id] = nil

						if (self.OnTransferred) then
							self:OnTransferred(curInv, inventory)
						end

						hook.Run("OnItemTransferred", self, curInv, inventory)
						return true
					end
				else
					return false, result
				end
			elseif (IsValid(client)) then
				-- we are transferring this item from an inventory to the world
				self.invID = 0
				curInv:Remove(self.id, false, true)

				local query = mysql:Update("ix_items")
					query:Update("inventory_id", 0)
					query:Where("item_id", self.id)
				query:Execute()

				inventory = ix.item.inventories[0]
				inventory[self:GetID()] = self

				if (self.OnTransferred) then
					self:OnTransferred(curInv, inventory)
				end

				hook.Run("OnItemTransferred", self, curInv, inventory)

				if (!isLogical) then
					return self:Spawn(client)
				end

				return true
			else
				return false, "noOwner"
			end
		else
			return false, "invalidInventory"
		end
	end
end

ix.meta.item = ITEM
