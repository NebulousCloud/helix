
local META = ix.meta.inventory or {}
META.__index = META
META.slots = META.slots or {}
META.w = META.w or 4
META.h = META.h or 4
META.vars = META.vars or {}

function META:GetID()
	return self.id or 0
end

function META:SetSize(w, h)
	self.w = w
	self.h = h
end

function META:__tostring()
	return "inventory["..(self.id or 0).."]"
end

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

function META:SetOwner(owner, fullUpdate)
	if (type(owner) == "Player" and owner:GetNetVar("char")) then
		owner = owner:GetNetVar("char")
	elseif (type(owner) != "number") then
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

function META:Remove(id, noReplication, noDelete)
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

	if (SERVER and !noReplication) then
		local receiver = self:GetReceiver()

		if (type(receiver) == "Player" and IsValid(receiver)) then
			netstream.Start(receiver, "invRm", id, self:GetID())
		else
			netstream.Start(receiver, "invRm", id, self:GetID(), self.owner)
		end

		if (!noDelete) then
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

function META:GetReceiver()
	for _, v in ipairs(player.GetAll()) do
		if (v:GetChar() and v:GetChar().id == self.owner) then
			return v
		end
	end
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
			table.insert(items, v)
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
			table.insert(items, v)
		end
	end

	return items
end

-- This function may pretty heavy.
function META:GetItems(onlyMain)
	local items = {}

	for _, v in pairs(self.slots) do
		for _, v2 in pairs(v) do
			if (v2 and !items[v2.id]) then
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
			if (v2.data) then
				local isBag = v2.data.id

				if (!table.HasValue(invs, isBag)) then
					if (isBag and isBag != self:GetID()) then
						table.insert(invs, isBag)
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

				for dataKey, dataVal in pairs(data) do
					if (itemData[dataKey] != dataVal) then
						return false
					end
				end
			end

			return v
		end
	end

	return false
end

if (SERVER) then
	function META:SendSlot(x, y, item, receiver)
		receiver = receiver or self:GetReceiver()
		local sendData = item and item.data and table.Count(item.data) > 0 and item.data or nil

		if (type(receiver) == "Player" and IsValid(receiver)) then
			netstream.Start(receiver, "invSet",
				self:GetID(), x, y, item and item.uniqueID or nil, item and item.id or nil, nil, sendData, sendData and 1 or nil)
		else
			netstream.Start(receiver, "invSet",
				self:GetID(), x, y, item and item.uniqueID or nil, item and item.id or nil, self.owner, sendData, sendData and 1 or nil)
		end

		if (item) then
			if (type(receiver) == "table") then
				for _, v in pairs(receiver) do
					item:Call("OnSendData", v)
				end
			elseif (IsValid(receiver)) then
				item:Call("OnSendData", receiver)
			end
		end
	end

	function META:Add(uniqueID, quantity, data, x, y, noReplication)
		quantity = quantity or 1

		if (quantity > 0) then
			if (type(uniqueID) != "number" and quantity > 1) then
				for _ = 1, quantity do
					self:Add(uniqueID, 1, data)
				end
			end

			local targetInv = self
			local bagInv
			if (type(uniqueID) == "number") then
				local item = ix.item.instances[uniqueID]

				if (item) then
					if (!x and !y) then
						x, y, bagInv = self:FindEmptySlot(item.width, item.height)
					end

					if (bagInv) then
						targetInv = bagInv
					end

					if (hook.Run("CanItemBeTransfered", item, ix.item.inventories[0], targetInv) == false) then
						return false, "notAllowed"
					end

					if (x and y) then
						targetInv.slots[x] = targetInv.slots[x] or {}
						targetInv.slots[x][y] = true

						item.gridX = x
						item.gridY = y
						item.invID = targetInv:GetID()

						for x2 = 0, item.width - 1 do
							for y2 = 0, item.height - 1 do
								targetInv.slots[x + x2] = targetInv.slots[x + x2] or {}
								targetInv.slots[x + x2][y + y2] = item
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

						return x, y, targetInv:GetID()
					else
						return false, "noSpace"
					end
				else
					return false, "invalidIndex"
				end
			else
				local itemTable = ix.item.list[uniqueID]

				if (!itemTable) then
					return false, "invalidItem"
				end

				if (!x and !y) then
					x, y, bagInv = self:FindEmptySlot(itemTable.width, itemTable.height)
				end

				if (bagInv) then
					targetInv = bagInv
				end

				if (hook.Run("CanItemBeTransfered", itemTable, ix.item.inventories[0], targetInv) == false) then
					return false, "notAllowed"
				end

				if (x and y) then
					targetInv.slots[x] = targetInv.slots[x] or {}
					targetInv.slots[x][y] = true

					ix.item.Instance(targetInv:GetID(), uniqueID, data, x, y, function(item)
						item.gridX = x
						item.gridY = y

						for x2 = 0, item.width - 1 do
							for y2 = 0, item.height - 1 do
								targetInv.slots[x + x2] = targetInv.slots[x + x2] or {}
								targetInv.slots[x + x2][y + y2] = item
							end
						end

						if (!noReplication) then
							targetInv:SendSlot(x, y, item)
						end
					end)

					return x, y, targetInv:GetID()
				else
					return false, "noSpace"
				end
			end
		else
			return false, "noOwner"
		end
	end

	function META:Sync(receiver, fullUpdate)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				if (item.gridX == x and item.gridY == y) then
					slots[#slots + 1] = {x, y, item.uniqueID, item.id, item.data}
				end
			end
		end

		netstream.Start(receiver, "inv",
			slots, self:GetID(), self.w, self.h, (receiver == nil or fullUpdate) and self.owner or nil, self.vars or {})

		for _, v in pairs(self:GetItems()) do
			v:Call("OnSendData", receiver)
		end
	end
end

ix.meta.inventory = META
