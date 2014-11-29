--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

local _R = debug.getregistry()

local META = _R.Inventory or {}
META.__index = META
META.slots = META.slots or {}
META.w = META.w or 4
META.h = META.h or 4

function META:getID()
	return self.id or 0
end

function META:setSize(w, h)
	self.w = w
	self.h = h
end

function META:__tostring()
	return "inventory["..(self.id or 0).."]"
end

function META:getSize()
	return self.w, self.h
end

-- this is pretty good to debug/develop function to use.
function META:print(printPos)
	for k, v in pairs(self:getItems()) do
		local str = k .. ": " .. v.name

		if (printPos) then
			str = str .. " (" .. v.gridX .. ", " .. v.gridY .. ")"
		end

		print(str)
	end
end

-- find out stacked shit
function META:findError()
	for k, v in pairs(self:getItems()) do
		if (v.width == 1 and v.height == 1) then
			continue
		end

		print("Finding error: " .. v.name )
		print("Item Position: " .. v.gridX, v.gridY )
		local x, y;
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
function META:printAll()
	print("------------------------")
		print("INVID", self:getID())
		print("INVSIZE", self:getSize())

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
	print("------------------------")
end

function META:setOwner(owner)
	if (type(owner) == "Player" and owner:getNetVar("charID")) then
		owner = owner:getNetVar("charID")
	elseif (type(owner) != "number") then
		return
	end

	self.owner = owner
end

function META:canItemFit(x, y, w, h, item2)
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

function META:findEmptySlot(w, h)
	w = w or 1
	h = h or 1

	if (w > self.w or h > self.h) then
		return
	end

	local canFit = false

	for y = 1, self.h - (h - 1) do
		for x = 1, self.w - (w - 1) do
			if (self:canItemFit(x, y, w, h)) then
				return x, y
			end
		end
	end
end

function META:getItemAt(x, y)
	if (self.slots and self.slots[x]) then
		return self.slots[x][y]
	end
end

function META:remove(id, noReplication, noDelete)
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
		local receiver = self:getReceiver()

		if (IsValid(receiver) and receiver:getChar() and self.owner == receiver:getChar():getID()) then
			netstream.Start(receiver, "invRm", id, self:getID())
		else
			netstream.Start(receiver, "invRm", id, self:getID(), self.owner)
		end

		if (!noDelete) then
			local item = nut.item.instances[id]

			if (item and item.onRemoved) then
				item:onRemoved()
			end
			
			nut.db.query("DELETE FROM nut_items WHERE _itemID = "..id)
			nut.item.instances[id] = nil
		end
	end

	return x2, y2
end

function META:getReceiver()
	for k, v in ipairs(player.GetAll()) do
		if (v:getChar() and v:getChar().id == self.owner) then
			return v
		end
	end
end

function META:getItemByID(id)
	for k, v in pairs(self.slots) do
		for k2, v2 in pairs(v) do
			if (v2.id == id) then
				return k, k2
			end
		end
	end
end

function META:getItems()
	local items = {}

	for k, v in pairs(self.slots) do
		for k2, v2 in pairs(v) do
			if (!items[v2.id]) then
				items[v2.id] = v2
			end
		end
	end

	return items
end

function META:hasItem(targetID, data)
	local items = self:getItems()
	
	for k, v in pairs(items) do
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
	function META:sendSlot(x, y, item)
		local receiver = self:getReceiver()

		if (IsValid(receiver) and receiver:getChar() and self.owner == receiver:getChar():getID()) then
			netstream.Start(receiver, "invSet", self:getID(), x, y, item and item.uniqueID or nil, item and item.id or nil)
		else
			netstream.Start(receiver, "invSet", self:getID(), x, y, item and item.uniqueID or nil, item and item.id or nil, self.owner)
		end
	end

	function META:add(uniqueID, quantity, data, x, y, noReplication)
		quantity = quantity or 1

		if (quantity > 0) then
			if (type(uniqueID) != "number" and quantity > 1) then
				for i = 1, quantity do
					self:add(uniqueID, 1, data)
				end

				return
			end

			if (type(uniqueID) == "number") then
				local item = nut.item.instances[uniqueID]

				if (item) then
					if (!x and !y) then
						x, y = self:findEmptySlot(item.width, item.height)
					end

					if (x and y) then
						self.slots[x] = self.slots[x] or {}
						self.slots[x][y] = true

						item.gridX = x
						item.gridY = y
						item.invID = self:getID()

						for x2 = 0, item.width - 1 do
							for y2 = 0, item.height - 1 do
								self.slots[x + x2] = self.slots[x + x2] or {}
								self.slots[x + x2][y + y2] = item
							end
						end

						if (!noReplication) then
							self:sendSlot(x, y, item)
						end

						nut.db.query("UPDATE nut_items SET _invID = "..self:getID()..", _x = "..x..", _y = "..y.." WHERE _itemID = "..item.id)

						return x, y
					else
						return false, "no space"
					end
				else
					return false, "invalid index"
				end
			else
				local itemTable = nut.item.list[uniqueID]

				if (!itemTable) then
					return false, "invalid item"
				end

				if (!x and !y) then
					x, y = self:findEmptySlot(itemTable.width, itemTable.height)
				end
				
				if (x and y) then
					self.slots[x] = self.slots[x] or {}
					self.slots[x][y] = true

					nut.item.instance(self:getID(), uniqueID, data, x, y, function(item)
						item.gridX = x
						item.gridY = y

						for x2 = 0, item.width - 1 do
							for y2 = 0, item.height - 1 do
								self.slots[x + x2] = self.slots[x + x2] or {}
								self.slots[x + x2][y + y2] = item
							end
						end

						if (!noReplication) then
							self:sendSlot(x, y, item)
						end
					end)

					return x, y
				else
					return false, "no space"
				end
			end
		else
			return false, "invalid owner"
		end
	end

	function META:sync(receiver, fullUpdate)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				if (item.gridX == x and item.gridY == y) then
					slots[#slots + 1] = {x, y, item.uniqueID, item.id, item.data}
				end
			end
		end

		netstream.Start(receiver, "inv", slots, self:getID(), self.w, self.h, (receiver == nil or fullUpdate) and self.owner or nil)
	end
end

_R.Inventory = META