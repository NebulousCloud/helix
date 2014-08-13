local _R = debug.getregistry()

local META = setmetatable({}, {})
META.__index = META
META.slots = {}
META.w = 4
META.h = 4
META.owner = NULL
META.receiver = META.owner

function META:setSize(w, h)
	self.w = w
	self.h = h
end

function META:getSize()
	return self.w, self.h
end

function META:setOwner(owner)
	if (type(owner) == "Player" and owner:getNetVar("charID")) then
		owner = owner:getNetVar("charID")
	elseif (type(owner) != "number") then
		return
	end

	self.owner = owner
end

function META:findEmptySlot(w, h)
	w = w or 1
	h = h or 1

	if (w > self.w or h > self.h) then
		return
	end

	local canFit = true

	for y = 1, (self.h - h) + 1 do
		for x = 1, (self.w - w) + 1 do
			canFit = true

			for x2 = 0, w do
				for y2 = 0, h do
					if (self.slots[x + x2] and !self.slots[x + x2][y + y2]) then
						canFit = false
						break
					end
				end

				if (!canFit) then
					break
				end
			end

			if (canFit) then
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

if (SERVER) then
	function META:add(uniqueID, quantity, data, x, y, noReplication)
		quantity = quantity or 1

		if (self.owner and quantity > 0) then
			if (quantity > 1) then
				for i = 1, quantity do
					self:add(uniqueID, 1, data)
				end

				return
			end

			local itemTable = nut.item.list[uniqueID]

			if (!itemTable) then
				return false, "invalid"
			end

			if (!x and !y) then
				x, y = self:findEmptySlot(itemTable.width or 1, itemTable.height or 1)
			end

			if (x and y) then
				nut.item.instance(self.owner, uniqueID, data, x, y, function(item)
					self.slots[x] = self.slots[x] or {}
					self.slots[x][y] = item

					if (!noReplication) then
						if (type(self.receiver) == "number") then
							netstream.Start(self.receiver, "invSet", uniqueID, item.id, x, y)
						else
							netstream.Start(self.receiver, "invSet", uniqueID, item.id, x, y, self.owner)
						end
					end
				end)

				return x, y
			else
				return false, "no space"
			end
		end
	end

	function META:setReceiver(receiver)
		self.receiver = receiver
	end

	function META:sync(receiver)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				slots[#slots + 1] = {x, y, item.uniqueID, item.id}
			end
		end

		netstream.Start(receiver, "inv", slots, self.w, self.h, receiver == nil and self.owner or nil)
	end
end

_R.Inventory = META