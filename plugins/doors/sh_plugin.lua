PLUGIN.name = "Doors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "A simple door system."

DOOR_OWNER = 3
DOOR_TENANT = 2
DOOR_GUEST = 1
DOOR_NONE = 0

nut.util.include("sv_plugin.lua")
nut.util.include("cl_plugin.lua")
nut.util.include("sh_commands.lua")

do
	local entityMeta = FindMetaTable("Entity")

	function entityMeta:checkDoorAccess(client, access)
		if (!self:isDoor()) then
			return false
		end

		access = access or DOOR_GUEST

		local parent = self.nutParent

		if (IsValid(parent)) then
			return parent:checkDoorAccess(client, access)
		end

		if (hook.Run("CanPlayerAccessDoor", client, self, access)) then
			return true
		end

		if (self.nutAccess and (self.nutAccess[client] or 0) >= access) then
			return true
		end

		return false
	end

	if (SERVER) then
		function entityMeta:removeDoorAccessData()
			for k, v in pairs(self.nutAccess or {}) do
				netstream.Start(k, "doorMenu")
			end
			
			self.nutAccess = {}
			self:setNetVar("owner", nil)
		end
	end
end

-- Configurations for door prices.
nut.config.add("doorCost", 10, "The price to purchase a door.", nil, {
	data = {min = 0, max = 500},
	category = "dConfigName"
})
nut.config.add("doorSellRatio", 0.5, "How much of the door price is returned when selling a door.", nil, {
	form = "Float",
	data = {min = 0, max = 1.0},
	category = "dConfigName"
})
nut.config.add("doorLockTime", 1, "How long it takes to (un)lock a door.", nil, {
	form = "Float",
	data = {min = 0, max = 10.0},
	category = "dConfigName"
})