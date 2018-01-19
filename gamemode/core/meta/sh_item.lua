local ITEM = ix.meta.item or {}
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.description = ITEM.description or "An item that is undefined."
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"

function ITEM:__eq(other)
	return self:GetID() == other:GetID()
end

function ITEM:__tostring()
	return "item["..self.uniqueID.."]["..self.id.."]"
end

function ITEM:GetID()
	return self.id
end

function ITEM:GetName()
	return (CLIENT and L(self.name) or self.name)
end

function ITEM:GetDescription()
	if (!self.description) then return "ERROR" end

	return L(self.description or "noDesc")
end

-- Dev Buddy. You don't have to print the item data with PrintData();
function ITEM:Print(detail)
	if (detail == true) then
		print(Format("%s[%s]: >> [%s](%s,%s)", self.uniqueID, self.id, self.owner, self.gridX, self.gridY))
	else
		print(Format("%s[%s]", self.uniqueID, self.id))
	end
end

-- Dev Buddy, You don't have to make another function to print the item Data.
function ITEM:PrintData()
	self:Print(true)
	print("ITEM DATA:")
	for k, v in pairs(self.data) do
		print(Format("[%s] = %s", k, v))
	end
end

function ITEM:Call(method, client, entity, ...)
	local oldPlayer, oldEntity = self.player, self.entity

	self.player = client or self.player
	self.entity = entity or self.entity

	if (type(self[method]) == "function") then
		local results = {self[method](self, ...)}

		self.player = nil
		self.entity = nil

		return unpack(results)
	end

	self.player = oldPlayer
	self.entity = oldEntity
end

function ITEM:GetOwner()
	local inventory = ix.item.inventories[self.invID]

	if (inventory) then
		return (inventory.GetReceiver and inventory:GetReceiver())
	end

	local id = self:GetID()

	for _, v in ipairs(player.GetAll()) do
		local character = v:GetCharacter()

		if (character and character:GetInventory():GetItemByID(id)) then
			return v
		end
	end
end

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

	if (receivers != false) then
		if (receivers or self:GetOwner()) then
			netstream.Start(receivers or self:GetOwner(), "invData", self:GetID(), key, value)
		end
	end

	if (!noSave and ix.db) then
		local query = mysql:Update("ix_items")
			query:Update("data", util.TableToJSON(self.data))
			query:Where("item_id", self:GetID())
		query:Execute()
	end
end

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


function ITEM:Hook(name, func)
	if (name) then
		self.hooks[name] = func
	end
end

function ITEM:PostHook(name, func)
	if (name) then
		self.postHooks[name] = func
	end
end

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

		local receiver = inv.GetReceiver and inv:GetReceiver()

		if (self.invID != 0) then
			if (IsValid(receiver) and receiver:GetChar() and inv.owner == receiver:GetChar():GetID()) then
				netstream.Start(receiver, "invRm", self.id, inv:GetID())
			else
				netstream.Start(receiver, "invRm", self.id, inv:GetID(), inv.owner)
			end
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
	function ITEM:GetEntity()
		local id = self:GetID()

		for _, v in ipairs(ents.FindByClass("ix_item")) do
			if (v.ixItemID == id) then
				return v
			end
		end
	end
	-- Spawn an item entity based off the item table.
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
				entity.ixCharID = client:GetChar():GetID()
			end

			-- Return the newly created entity.
			return entity
		end
	end

	-- Transfers an item to a specific inventory.
	function ITEM:Transfer(invID, x, y, client, noReplication, isLogical)
		invID = invID or 0

		if (self.invID == invID) then
			return false, "same inv"
		end

		local inventory = ix.item.inventories[invID]
		local curInv = ix.item.inventories[self.invID or 0]

		if (hook.Run("CanItemBeTransfered", self, curInv, inventory) == false) then
			return false, "notAllowed"
		end

		local authorized = false

		if (curInv and !IsValid(client)) then
			client = (curInv.GetReceiver and curInv:GetReceiver() or nil)
		end

		if (inventory and inventory.OnAuthorizeTransfer and inventory:OnAuthorizeTransfer(client, curInv, self)) then
			authorized = true
		end

		if (!authorized and self.OnCanBeTransfered and self:OnCanBeTransfered(curInv, inventory) == false) then
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
					return false, "noSpace"
				end

				local prevID = self.invID
				local status, result = targetInv:Add(self.id, nil, nil, x, y, noReplication)

				if (status) then
					if (self.invID > 0 and prevID != 0) then
						curInv:Remove(self.id, false, true)
						self.invID = invID

						if (self.OnTransfered) then
							self:OnTransfered(curInv, inventory)
						end
						hook.Run("OnItemTransfered", self, curInv, inventory)

						return true
					elseif (self.invID > 0 and prevID == 0) then
						inventory = ix.item.inventories[0]
						inventory[self.id] = nil

						if (self.OnTransfered) then
							self:OnTransfered(curInv, inventory)
						end

						hook.Run("OnItemTransfered", self, curInv, inventory)

						return true
					end
				else
					return false, result
				end
			elseif (IsValid(client)) then
				self.invID = 0
				curInv:Remove(self.id, false, true)

				local query = mysql:Update("ix_items")
					query:Update("inventory_id", 0)
					query:Where("item_id", self.id)
				query:Execute()

				if (isLogical != true) then
					return self:Spawn(client)
				else
					inventory = ix.item.inventories[0]
					inventory[self:GetID()] = self

					if (self.OnTransfered) then
						self:OnTransfered(curInv, inventory)
					end
					hook.Run("OnItemTransfered", self, curInv, inventory)

					return true
				end
			else
				return false, "noOwner"
			end
		else
			return false, "invalidInventory"
		end
	end
end

ix.meta.item = ITEM
