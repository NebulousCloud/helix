local _R = debug.getregistry()

local ITEM = _R.Item or setmetatable({}, {__tostring = function(self) return "item["..self.uniqueID.."]["..self.id.."]" end})
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.desc = "An item that is undefined."
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"
ITEM.data = ITEM.data or {}

function ITEM:call(method, client, entity, ...)
	self.player = self.player or client
	self.entity = self.entity or entity

	if (self.functions[method]) then
		return self.functions[method](self, ...)
	end
end

if (SERVER) then
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