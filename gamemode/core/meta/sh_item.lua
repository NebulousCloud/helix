
--[[--
Interactable entities that can be held in inventories.

Items are objects that are contained inside of an `Inventory`, or as standalone entities if they are dropped in the world. They
usually have functionality that provides more gameplay aspects to the schema. For example, the zipties in the HL2 RP schema
allow a player to tie up and search a player.

For an item to have an actual presence, they need to be instanced (usually with `ix.item.Instance`). Items describe the
properties, while instances are a clone of these properties that can have their own unique data (e.g an ID card will have the
same name but different numerical IDs). You can think of items as the class, while instances are objects of the `Item` class.

## Creating item classes (`ItemStructure`)
Item classes are defined in their own file inside of your schema or plugin's `items/` folder. In these item class files you
specify how instances of the item behave. This includes default values for basic things like the item's name and description,
to more advanced things by overriding extra methods from an item base. See `ItemStructure` for information on how to define
a basic item class.

Item classes in this folder are automatically loaded by Helix when the server starts up.

## Item bases
If many items share the same functionality (i.e a can of soda and a bottle of water can both be consumed), then you might want
to consider using an item base to reduce the amount of duplication for these items. Item bases are defined the same way as
regular item classes, but they are placed in the `items/base/` folder in your schema or plugin. For example, a `consumables`
base would be in `items/base/sh_consumables.lua`.

Any items that you want to use this base must be placed in a subfolder that has the name of the base you want that item to use.
For example, for a bottled water item to use the consumable base, it must be placed in `items/consumables/sh_bottled_water.lua`.
This also means that you cannot place items into subfolders as you wish, since the framework will try to use an item base that
doesn't exist.

The default item bases that come with Helix are:

  - `ammo` - provides ammo to any items with the `weapons` base
  - `bags` - holds an inventory that other items can be stored inside of
  - `outfit` - changes the appearance of the player that wears it
  - `pacoutfit` - changes the appearance of the player that wears it using PAC3
  - `weapons` - makes any SWEP into an item that can be equipped

These item bases usually come with extra values and methods that you can define/override in order to change their functionality.
You should take a look at the source code for these bases to see their capabilities.

## Item functions (`ItemFunctionStructure`)
Requiring players to interact with items in order for them to do something is quite common. As such, there is already a built-in
mechanism to allow players to right-click items and show a list of available options. Item functions are defined in your item
class file in the `ITEM.functions` table. See `ItemFunctionStructure` on how to define them.

Helix comes with `drop`, `take`, and `combine` item functions by default that allows items to be dropped from a player's
inventory, picked up from the world, and combining items together. These can be overridden by defining an item function
in your item class file with the same name. See the `bags` base for example usage of the `combine` item function.

## Item icons (`ItemIconStructure`)
Icons for items sometimes don't line up quite right, in which case you can modify an item's `iconCam` value and line up the
rendered model as needed. See `ItemIconStructure` for more details.
]]
-- @classmod Item

--[[--
All item functions live inside of an item's `functions` table. An item function entry includes a few methods and fields you can
use to customize the functionality and appearance of the item function. An example item function is below:

	-- this item function's unique ID is "MyFunction"
	ITEM.functions.MyFunction = {
		name = "myFunctionPhrase", -- uses the "myFunctionPhrase" language phrase when displaying in the UI
		tip = "myFunctionDescription", -- uses the "myFunctionDescription" language phrase when displaying in the UI
		icon = "icon16/add.png", -- path to the icon material
		OnRun = function(item)
			local client = item.player
			local entity = item.entity -- only set if this is function is being ran while the item is in the world

			if (IsValid(client)) then
				client:ChatPrint("This is a test.")

				if (IsValid(entity)) then
					client:ChatPrint(entity:GetName())
				end
			end

			-- do not remove this item from the owning player's inventory
			return false
		end,
		OnCanRun = function(item)
			-- only allow admins to run this item function
			local client = item.player
			return IsValid(client) and client:IsAdmin()
		end
	}
]]
-- @table ItemFunctionStructure
-- @realm shared
-- @field[type=string,opt] name Language phrase to use when displaying this item function's name in the UI. If not specified,
-- then it will use the unique ID of the item function
-- @field[type=string,opt] tip Language phrase to use when displaying this item function's detailed description in the UI
-- @field[type=string,opt] icon Path to the material to use when displaying this item function's icon
-- @field[type=function] OnRun Function to call when the item function is ran. This function is **ONLY** ran on the server.
--
-- The only argument passed into this function is the instance of the item being called. The instance will have its `player`
-- field set if the item function is being ran by a player (which it should be most of the time). It will also have its `entity`
-- field set if the item function is being ran while the item is in the world, and not in a player's inventory.
--
-- The item will be removed after the item function is ran. If you want to prevent this behaviour, then you can return `false`
-- in this function. See the example above.
-- @field[type=function] OnCanRun Function to call when checking whether or not this item function can be ran. This function is
-- ran **BOTH** on the client and server.
--
-- The arguments are the same as `OnCanRun`, and the `player` and `entity` fields will be set on the item instance accordingly.
-- Returning `true` will allow the item function to be ran. Returning `false` will prevent it from running and additionally
-- hide it from the UI. See the example above.
-- @field[type=function,opt] OnClick This function is called when the player clicks on this item function's entry in the UI.
-- This function is ran **ONLY** on the client, and is only ran if `OnCanRun` succeeds.
--
-- The same arguments from `OnCanRun` and `OnRun` apply to this function.

--[[--
Changing the way an item's icon is rendered is done by modifying the location and angle of the model, as well as the FOV of the
camera. You can tweak the values in code, or use the `ix_dev_icon` console command to visually position the model and camera. An
example entry for an item's icon is below:

	ITEM.iconCam = {
		pos = Vector(0, 0, 60),
		ang = Angle(90, 0, 0),
		fov = 45
	}

Note that this will probably not work for your item's specific model, since every model has a different size, origin, etc. All
item icons need to be tweaked individually.
]]
-- @table ItemIconStructure
-- @realm client
-- @field[type=vector] pos Location of the model relative to the camera. +X is forward, +Z is up
-- @field[type=angle] ang Angle of the model
-- @field[type=number] fov FOV of the camera

--[[--
When creating an item class, the file will have a global table `ITEM` set that you use to define the item's values/methods. An
example item class is below:

`items/sh_brick.lua`
	ITEM.name = "Brick"
	ITEM.description = "A brick. Pretty self-explanatory. You can eat it but you'll probably lose some teeth."
	ITEM.model = Model("models/props_debris/concrete_cynderblock001.mdl")
	ITEM.width = 1
	ITEM.height = 1
	ITEM.price = 25

Note that the below list only includes the default fields available for *all* items, and not special ones defined in custom
item bases.
]]
-- @table ItemStructure
-- @realm shared
-- @field[type=string] name Display name of the item
-- @field[type=string] description Detailed description of the item
-- @field[type=string] model Model to use for the item's icon and when it's dropped in the world
-- @field[type=number,opt=1] width Width of the item in grid cells
-- @field[type=number,opt=1] height Height of the item in grid cells
-- @field[type=number,opt=0] price How much money it costs to purchase this item in the business menu
-- @field[type=string,opt] category Name of the category this item belongs to - mainly used for the business menu
-- @field[type=boolean,opt=false] noBusiness Whether or not to disallow purchasing this item in the business menu
-- @field[type=table,opt] factions List of factions allowed to purchase this item in the business menu
-- @field[type=table,opt] classes List of character classes allowed to purchase this item in the business menu. Classes are
-- checked after factions, so the character must also be in an allowed faction
-- @field[type=string,opt] flag List of flags (as a string - e.g `"a"` or `"abc"`) allowed to purchase this item in the
-- business menu. Flags are checked last, so the character must also be in an allowed faction and class
-- @field[type=ItemIconStructure,opt] iconCam How to render this item's icon
-- @field[type=table,opt] functions List of all item functions that this item has. See `ItemFunctionStructure` on how to define
-- new item functions

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

--- Returns the player that owns this item.
-- @realm shared
-- @treturn player Player owning this item
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

			hook.Run("OnItemSpawned", entity)
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
	-- @treturn[1] string The error, if applicable
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
