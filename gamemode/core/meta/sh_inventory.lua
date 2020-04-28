
--[[--
Holds items within a grid layout.

Inventories are an object that contains `Item`s in a grid layout. Every `Character` will have exactly one inventory attached to
it, which is the only inventory that is allowed to hold bags - any item that has its own inventory (i.e a suitcase). Inventories
can be owned by a character, or it can be individually interacted with as a standalone object. For example, the container plugin
attaches inventories to props, allowing for items to be stored outside of any character inventories and remain "in the world".
]]
-- @classmod Inventory

local META = ix.meta.inventory or {}
META.__index = META
META.slots = META.slots or {}
META.w = META.w or 4
META.h = META.h or 4
META.vars = META.vars or {}
META.receivers = META.receivers or {}

--- Returns a string representation of this inventory
-- @realm shared
-- @treturn string String representation
-- @usage print(ix.item.inventories[1])
-- > "inventory[1]"
function META:__tostring()
	return "inventory["..(self.id or 0).."]"
end

--- Returns this inventory's database ID. This is guaranteed to be unique.
-- @realm shared
-- @treturn number Unique ID of inventory
function META:GetID()
	return self.id or 0
end

--- Sets the grid size of this inventory.
-- @internal
-- @realm shared
-- @number width New width of inventory
-- @number height New height of inventory
function META:SetSize(width, height)
	self.w = width
	self.h = height
end

--- Returns the grid size of this inventory.
-- @realm shared
-- @treturn number Width of inventory
-- @treturn number Height of inventory
function META:GetSize()
	return self.w, self.h
end

-- this is pretty good to debug/develop function to use.
function META:Print(printPos)
	for k, v in pairs(self:GetItems()) do
		local str = k .. ": " .. v.name

		if (printPos) then
			str = str .. " (" .. v.gridX .. ", " .. v.gridY .. ")"
		end

		print(str)
	end
end

-- finds errors for stacked items
function META:FindError()
	for _, v in pairs(self:GetItems()) do
		if (v.width == 1 and v.height == 1) then
			continue
		end

		print("Finding error: " .. v.name)
		print("Item Position: " .. v.gridX, v.gridY)

		for x = v.gridX, v.gridX + v.width - 1 do
			for y = v.gridY, v.gridY + v.height - 1 do
				local item = self.slots[x][y]

				if (item and item.id != v.id) then
					print("Error Found: ".. item.name)
				end
			end
		end
	end
end

-- For the debug/item creation purpose
function META:PrintAll()
	print("------------------------")
		print("INVID", self:GetID())
		print("INVSIZE", self:GetSize())

		if (self.slots) then
			for x = 1, self.w do
				for y = 1, self.h do
					local item = self.slots[x] and self.slots[x][y]
					if (item and item.id) then
						print(item.name .. "(" .. item.id .. ")", x, y)
					end
				end
			end
		end

		print("INVVARS")
		PrintTable(self.vars or {})
	print("------------------------")
end

--- Returns the player that owns this inventory.
-- @realm shared
-- @treturn[1] player Owning player
-- @treturn[2] nil If no connected player owns this inventory
function META:GetOwner()
	for _, v in ipairs(player.GetAll()) do
		if (v:GetCharacter() and v:GetCharacter().id == self.owner) then
			return v
		end
	end
end

function META:SetOwner(owner, fullUpdate)
	if (type(owner) == "Player" and owner:GetNetVar("char")) then
		owner = owner:GetNetVar("char")
	elseif (!isnumber(owner)) then
		return
	end

	if (SERVER) then
		if (fullUpdate) then
			for _, v in ipairs(player.GetAll()) do
				if (v:GetNetVar("char") == owner) then
					self:Sync(v, true)

					break
				end
			end
		end

		local query = mysql:Update("ix_inventories")
			query:Update("character_id", owner)
			query:Where("inventory_id", self:GetID())
		query:Execute()
	end

	self.owner = owner
end

--- Checks whether a player has access to an inventory
-- @realm shared
-- @internal
-- @player client Player to check access for
-- @treturn bool Whether or not the player has access to the inventory
function META:OnCheckAccess(client)
	local bAccess = false

	for _, v in ipairs(self:GetReceivers()) do
		if (v == client) then
			bAccess = true
			break
		end
	end

	return bAccess
end

function META:CanItemFit(x, y, w, h, item2)
	local canFit = true

	for x2 = 0, w - 1 do
		for y2 = 0, h - 1 do
			local item = (self.slots[x + x2] or {})[y + y2]

			if ((x + x2) > self.w or item) then
				if (item2) then
					if (item and item.id == item2.id) then
						continue
					end
				end

				canFit = false
				break
			end
		end

		if (!canFit) then
			break
		end
	end

	return canFit
end

function META:GetFilledSlotCount()
	local count = 0

	for x = 1, self.w do
		for y = 1, self.h do
			if ((self.slots[x] or {})[y]) then
				count = count + 1
			end
		end
	end

	return count
end

function META:FindEmptySlot(w, h, onlyMain)
	w = w or 1
	h = h or 1

	if (w > self.w or h > self.h) then
		return
	end

	for y = 1, self.h - (h - 1) do
		for x = 1, self.w - (w - 1) do
			if (self:CanItemFit(x, y, w, h)) then
				return x, y
			end
		end
	end

	if (onlyMain != true) then
		local bags = self:GetBags()

		if (#bags > 0) then
			for _, invID in ipairs(bags) do
				local bagInv = ix.item.inventories[invID]

				if (bagInv) then
					local x, y = bagInv:FindEmptySlot(w, h)

					if (x and y) then
						return x, y, bagInv
					end
				end
			end
		end
	end
end

function META:GetItemAt(x, y)
	if (self.slots and self.slots[x]) then
		return self.slots[x][y]
	end
end

function META:Remove(id, bNoReplication, bNoDelete, bTransferring)
	local x2, y2

	for x = 1, self.w do
		if (self.slots[x]) then
			for y = 1, self.h do
				local item = self.slots[x][y]

				if (item and item.id == id) then
					self.slots[x][y] = nil

					x2 = x2 or x
					y2 = y2 or y
				end
			end
		end
	end

	if (SERVER and !bNoReplication) then
		local receivers = self:GetReceivers()

		if (istable(receivers)) then
			net.Start("ixInventoryRemove")
				net.WriteUInt(id, 32)
				net.WriteUInt(self:GetID(), 32)
			net.Send(receivers)
		end

		-- we aren't removing the item - we're transferring it to another inventory
		if (!bTransferring) then
			hook.Run("InventoryItemRemoved", self, ix.item.instances[id])
		end

		if (!bNoDelete) then
			local item = ix.item.instances[id]

			if (item and item.OnRemoved) then
				item:OnRemoved()
			end

			local query = mysql:Delete("ix_items")
				query:Where("item_id", id)
			query:Execute()

			ix.item.instances[id] = nil
		end
	end

	return x2, y2
end

function META:AddReceiver(client)
	self.receivers[client] = true
end

function META:RemoveReceiver(client)
	self.receivers[client] = nil
end

function META:GetReceivers()
	local result = {}

	if (self.receivers) then
		for k, _ in pairs(self.receivers) do
			if (IsValid(k) and k:IsPlayer()) then
				result[#result + 1] = k
			end
		end
	end

	return result
end

function META:GetItemCount(uniqueID, onlyMain)
	local i = 0

	for _, v in pairs(self:GetItems(onlyMain)) do
		if (v.uniqueID == uniqueID) then
			i = i + 1
		end
	end

	return i
end

function META:GetItemsByUniqueID(uniqueID, onlyMain)
	local items = {}

	for _, v in pairs(self:GetItems(onlyMain)) do
		if (v.uniqueID == uniqueID) then
			items[#items + 1] = v
		end
	end

	return items
end

function META:GetItemsByBase(baseID, bOnlyMain)
	local items = {}

	for _, v in pairs(self:GetItems(bOnlyMain)) do
		if (v.base == baseID) then
			items[#items + 1] = v
		end
	end

	return items
end

function META:GetItemByID(id, onlyMain)
	for _, v in pairs(self:GetItems(onlyMain)) do
		if (v.id == id) then
			return v
		end
	end
end

function META:GetItemsByID(id, onlyMain)
	local items = {}

	for _, v in pairs(self:GetItems(onlyMain)) do
		if (v.id == id) then
			items[#items + 1] = v
		end
	end

	return items
end

-- This function may pretty heavy.
function META:GetItems(onlyMain)
	local items = {}

	for _, v in pairs(self.slots) do
		for _, v2 in pairs(v) do
			if (istable(v2) and !items[v2.id]) then
				items[v2.id] = v2

				v2.data = v2.data or {}
				local isBag = v2.data.id
				if (isBag and isBag != self:GetID() and onlyMain != true) then
					local bagInv = ix.item.inventories[isBag]

					if (bagInv) then
						local bagItems = bagInv:GetItems()

						table.Merge(items, bagItems)
					end
				end
			end
		end
	end

	return items
end

function META:GetBags()
	local invs = {}

	for _, v in pairs(self.slots) do
		for _, v2 in pairs(v) do
			if (istable(v2) and v2.data) then
				local isBag = v2.data.id

				if (!table.HasValue(invs, isBag)) then
					if (isBag and isBag != self:GetID()) then
						invs[#invs + 1] = isBag
					end
				end
			end
		end
	end

	return invs
end

function META:HasItem(targetID, data)
	local items = self:GetItems()

	for _, v in pairs(items) do
		if (v.uniqueID == targetID) then
			if (data) then
				local itemData = v.data
				local bFound = true

				for dataKey, dataVal in pairs(data) do
					if (itemData[dataKey] != dataVal) then
						bFound = false
						break
					end
				end

				if (!bFound) then
					continue
				end
			end

			return v
		end
	end

	return false
end

function META:HasItems(targetIDs)
	local items = self:GetItems()
	local count = #targetIDs -- assuming array
	targetIDs = table.Copy(targetIDs)

	for _, v in pairs(items) do
		for k, targetID in ipairs(targetIDs) do
			if (v.uniqueID == targetID) then
				table.remove(targetIDs, k)
				count = count - 1

				break
			end
		end
	end

	return count <= 0, targetIDs
end

function META:HasItemOfBase(baseID, data)
	local items = self:GetItems()

	for _, v in pairs(items) do
		if (v.base == baseID) then
			if (data) then
				local itemData = v.data
				local bFound = true

				for dataKey, dataVal in pairs(data) do
					if (itemData[dataKey] != dataVal) then
						bFound = false
						break
					end
				end

				if (!bFound) then
					continue
				end
			end

			return v
		end
	end

	return false
end

if (SERVER) then
	function META:SendSlot(x, y, item)
		local receivers = self:GetReceivers()
		local sendData = item and item.data and !table.IsEmpty(item.data) and item.data or {}

		net.Start("ixInventorySet")
			net.WriteUInt(self:GetID(), 32)
			net.WriteUInt(x, 6)
			net.WriteUInt(y, 6)
			net.WriteString(item and item.uniqueID or "")
			net.WriteUInt(item and item.id or 0, 32)
			net.WriteUInt(self.owner or 0, 32)
			net.WriteTable(sendData)
		net.Send(receivers)

		if (item) then
			for _, v in pairs(receivers) do
				item:Call("OnSendData", v)
			end
		end
	end

	function META:Add(uniqueID, quantity, data, x, y, noReplication)
		quantity = quantity or 1

		if (quantity < 1) then
			return false, "noOwner"
		end

		if (!isnumber(uniqueID) and quantity > 1) then
			for _ = 1, quantity do
				local bSuccess, error = self:Add(uniqueID, 1, data)

				if (!bSuccess) then
					return false, error
				end
			end

			return true
		end

		local client = self.GetOwner and self:GetOwner() or nil
		local item = isnumber(uniqueID) and ix.item.instances[uniqueID] or ix.item.list[uniqueID]
		local targetInv = self
		local bagInv

		if (!item) then
			return false, "invalidItem"
		end

		if (isnumber(uniqueID)) then
			local oldInvID = item.invID

			if (!x and !y) then
				x, y, bagInv = self:FindEmptySlot(item.width, item.height)
			end

			if (bagInv) then
				targetInv = bagInv
			end

			-- we need to check for owner since the item instance already exists
			if (!item.bAllowMultiCharacterInteraction and IsValid(client) and client:GetCharacter() and
				item:GetPlayerID() == client:SteamID64() and item:GetCharacterID() != client:GetCharacter():GetID()) then
				return false, "itemOwned"
			end

			if (hook.Run("CanTransferItem", item, ix.item.inventories[0], targetInv) == false) then
				return false, "notAllowed"
			end

			if (x and y) then
				targetInv.slots[x] = targetInv.slots[x] or {}
				targetInv.slots[x][y] = true

				item.gridX = x
				item.gridY = y
				item.invID = targetInv:GetID()

				for x2 = 0, item.width - 1 do
					local index = x + x2

					for y2 = 0, item.height - 1 do
						targetInv.slots[index] = targetInv.slots[index] or {}
						targetInv.slots[index][y + y2] = item
					end
				end

				if (!noReplication) then
					targetInv:SendSlot(x, y, item)
				end

				if (!self.noSave) then
					local query = mysql:Update("ix_items")
						query:Update("inventory_id", targetInv:GetID())
						query:Update("x", x)
						query:Update("y", y)
						query:Where("item_id", item.id)
					query:Execute()
				end

				hook.Run("InventoryItemAdded", ix.item.inventories[oldInvID], targetInv, item)

				return x, y, targetInv:GetID()
			else
				return false, "noFit"
			end
		else
			if (!x and !y) then
				x, y, bagInv = self:FindEmptySlot(item.width, item.height)
			end

			if (bagInv) then
				targetInv = bagInv
			end

			if (hook.Run("CanTransferItem", item, ix.item.inventories[0], targetInv) == false) then
				return false, "notAllowed"
			end

			if (x and y) then
				for x2 = 0, item.width - 1 do
					local index = x + x2

					for y2 = 0, item.height - 1 do
						targetInv.slots[index] = targetInv.slots[index] or {}
						targetInv.slots[index][y + y2] = true
					end
				end

				local characterID
				local playerID

				if (self.owner) then
					local character = ix.char.loaded[self.owner]

					if (character) then
						characterID = character.id
						playerID = character.steamID
					end
				end

				ix.item.Instance(targetInv:GetID(), uniqueID, data, x, y, function(newItem)
					newItem.gridX = x
					newItem.gridY = y

					for x2 = 0, newItem.width - 1 do
						local index = x + x2

						for y2 = 0, newItem.height - 1 do
							targetInv.slots[index] = targetInv.slots[index] or {}
							targetInv.slots[index][y + y2] = newItem
						end
					end

					if (!noReplication) then
						targetInv:SendSlot(x, y, newItem)
					end

					hook.Run("InventoryItemAdded", nil, targetInv, newItem)
				end, characterID, playerID)

				return x, y, targetInv:GetID()
			else
				return false, "noFit"
			end
		end
	end

	function META:Sync(receiver, fullUpdate)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				if (istable(item) and item.gridX == x and item.gridY == y) then
					slots[#slots + 1] = {x, y, item.uniqueID, item.id, item.data}
				end
			end
		end

		net.Start("ixInventorySync")
			net.WriteTable(slots)
			net.WriteUInt(self:GetID(), 32)
			net.WriteUInt(self.w, 6)
			net.WriteUInt(self.h, 6)
			net.WriteType((receiver == nil or fullUpdate) and self.owner or nil)
			net.WriteTable(self.vars or {})
		net.Send(receiver)

		for _, v in pairs(self:GetItems()) do
			v:Call("OnSendData", receiver)
		end
	end
end

ix.meta.inventory = META
