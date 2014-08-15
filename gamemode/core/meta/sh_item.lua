local _R = debug.getregistry()

local ITEM = _R.Item or setmetatable({}, {__tostring = function(self) return "item["..self.uniqueID.."]["..self.id.."]" end})
ITEM.__index = ITEM
ITEM.name = "Undefined"
ITEM.desc = "An item that is undefined."
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"
ITEM.data = ITEM.data or {}
ITEM.functions = {}

function ITEM:call(method, client, entity, ...)
	self.player = self.player or client
	self.entity = self.entity or entity

	if (self.functions[method]) then
		return self.functions[method](self, ...)
	end
end

function ITEM:spawn(position, angles)
end

_R.Item = ITEM