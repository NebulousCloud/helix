local _R = debug.getregistry()

local ITEM = _R.Item or setmetatable({}, {__tostring = function(self) return "item["..self.uniqueID.."]["..self.id.."]" end})
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.desc = "An item that is undefined."
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"
ITEM.data = {}

function ITEM:getID()
	return self.id
end

-- Dev Buddy. You don't have to print the item data with PrintData();
function ITEM:print(detail)
	if (detail == true) then
		print(Format("[%s]%s: >> [%s](%s,%s)", self.id, self.uniqueID, self.owner, self.gridX, self.gridY))
	else
		print(Format("[%s]%s)", self.id, self.uniqueID))
	end
end

-- Dev Buddy, You don't have to make another function to print the item Data.
function ITEM:printData()
	self:print(true)
	print("ITEM DATA:")
	for k, v in pairs(self.data) do
		print(Format("[%s] = %s", k, v))
	end
end

function ITEM:call(method, client, entity, ...)
	self.player = self.player or client
	self.entity = self.entity or entity

	if (self.functions[method]) then
		local results = {self.functions[method](self, ...)}

		self.player = nil
		self.entity = nil

		return unpack(results)
	end

	self.player = nil
	self.entity = nil
end

function ITEM:getOwner()
	local id = self:getID()

	for k, v in ipairs(player.GetAll()) do
		local character = v:getChar()

		if (character and character:getInv():getItemByID(id)) then
			return v
		end
	end
end

function ITEM:setData(key, value, receivers, noSave, checkEntity)
	self.data[key] = value

	if (SERVER) then
		if (checkEntity) then
			local ent = self:getEntity()

			if (IsValid(ent)) then
				local data = ent:getNetVar("data")
				data[key] = value

				ent:setNetVar("data", data)
			end
		end
	end

	if (receivers != false) then
		if (self:getOwner()) then
			netstream.Start(receivers or self:getOwner(), "invData", self:getID(), key, value)
		end
	end

	if (!noSave) then
		if (nut.db) then
			nut.db.updateTable({_data = self.data}, nil, "items", "_itemID = "..self:getID())
		end
	end	
end

function ITEM:getData(key, default)
	local value = self.data[key]

	if (value == nil) then
		return default
	else
		return value
	end
end

function ITEM:hook(name, func)
	if (name and func) then
		self.hooks[name] = func
	end
end

if (SERVER) then
	function ITEM:getEntity()
		local id = self:getID()

		for k, v in ipairs(ents.FindByClass("nut_item")) do
			if (v.nutItemID == id) then
				return v
			end
		end
	end
	-- Spawn an item entity based off the item table.
	function ITEM:spawn(position, angles)
		-- Check if the item has been created before.
		if (nut.item.instances[self.id]) then
			-- If the first argument is a player, then we will find a position to drop
			-- the item based off their aim.
			if (type(position) == "Player") then
				-- Start a trace.
				local data = {}
					-- The trace starts behind the player in case they are looking at a wall.
					data.start = position:GetShootPos() - position:GetAimVector()*64
					-- The trace finishes 86 units infront of the player.
					data.endpos = position:GetShootPos() + position:GetAimVector()*86
					-- Ignore the actual player.
					data.filter = position
				-- Get the end position of the trace.
				position = util.TraceLine(data).HitPos
			end

			-- Spawn the actual item entity.
			local entity = ents.Create("nut_item")
			entity:SetPos(position)
			entity:SetAngles(angles or Angle(0, 0, 0))
			-- Make the item represent this item.
			entity:setItem(self.id)

			-- Return the newly created entity.
			return entity
		end
	end
end

_R.Item = ITEM