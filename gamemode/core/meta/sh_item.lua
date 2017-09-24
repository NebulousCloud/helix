local ITEM = nut.meta.item or {}
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.desc = ITEM.desc or "An item that is undefined."
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
	if (!self.desc) then return "ERROR" end
	
	return L(self.desc or "noDesc")
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
	local inventory = nut.item.inventories[self.invID]

	if (inventory) then
		return (inventory.GetReceiver and inventory:GetReceiver())
	end

	local id = self:GetID()

	for k, v in ipairs(player.GetAll()) do
		local character = v:GetChar()

		if (character and character:GetInv():GetItemByID(id)) then
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

	if (!noSave) then
		if (nut.db) then
			nut.db.UpdateTable({_data = self.data}, nil, "items", "_itemID = "..self:GetID())
		end
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
			local value = data[key]

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

function ITEM:Remove()
	local inv = nut.item.inventories[self.invID]
	local x2, y2

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
			for k, v in pairs(items) do
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
		local inv = nut.item.inventories[self.invID]

		if (inv) then
			nut.item.inventories[self.invID][self.id] = nil
		end
	end

	if (SERVER and !noReplication) then
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

		if (!noDelete) then
			local item = nut.item.instances[self.id]

			if (item and item.OnRemoved) then
				item:OnRemoved()
			end
			
			nut.db.query("DELETE FROM nut_items WHERE _itemID = "..self.id)
			nut.item.instances[self.id] = nil
		end
	end

	return true
end

if (SERVER) then
	function ITEM:GetEntity()
		local id = self:GetID()

		for k, v in ipairs(ents.FindByClass("nut_item")) do
			if (v.nutItemID == id) then
				return v
			end
		end
	end
	-- Spawn an item entity based off the item table.
	function ITEM:Spawn(position, angles)
		-- Check if the item has been created before.
		if (nut.item.instances[self.id]) then
			local client

			-- If the first argument is a player, then we will find a position to drop
			-- the item based off their aim.
			if (type(position) == "Player") then
				client = position
				position = position:GetItemDropPos()
			end

			-- Spawn the actual item entity.
			local entity = ents.Create("nut_item")
			entity:Spawn()
			entity:SetPos(position)
			entity:SetAngles(angles or Angle(0, 0, 0))
			-- Make the item represent this item.
			entity:SetItem(self.id)

			if (IsValid(client)) then
				entity.nutSteamID = client:SteamID()
				entity.nutCharID = client:GetChar():GetID()
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
		
		local inventory = nut.item.inventories[invID]
		local curInv = nut.item.inventories[self.invID or 0]

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
						local inventory = nut.item.inventories[0]
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
				nut.db.query("UPDATE nut_items SET _invID = 0 WHERE _itemID = "..self.id)

				if (isLogical != true) then
					return self:Spawn(client)	
				else
					local inventory = nut.item.inventories[0]
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

nut.meta.item = ITEM
