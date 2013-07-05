PLUGIN.name = "Door System"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides ability to purchase doors and defining unownable doors."

nut.config.doorCost = 50
nut.config.doorSellAmount = 25

if (SERVER) then
	function PLUGIN:DoorSetUnownable(entity)
		self.data = nut.util.ReadTable("doors")

		local title = entity:GetNetVar("title", "Unownable Door")

		for k, v in pairs(self.data) do
			if (v.position == entity:GetPos()) then
				v.title = title

				return
			end
		end

		self.data[#self.data + 1] = {title = title, position = entity:GetPos()}
		nut.util.WriteTable("doors", self.data)

		entity:SetNetVar("unownable", true)
	end

	function PLUGIN:LockDoor(entity)
		if (entity.locked) then
			return
		end

		entity:Fire("close")
		entity:Fire("lock")
		entity.locked = true
	end

	function PLUGIN:UnlockDoor(entity)
		if (!entity.locked) then
			return
		end

		entity:Fire("unlock")
		entity.locked = false
	end

	function PLUGIN:DoorSetOwnable(entity)
		self.data = nut.util.ReadTable("doors")

		for k, v in pairs(self.data) do
			if (v.position == entity:GetPos()) then
				entity:SetNetVar("unownable", nil)
				table.remove(self.data, k)

				nut.util.WriteTable("doors", self.data)

				return
			end
		end
	end

	function PLUGIN:LoadData()
		self.data = nut.util.ReadTable("doors")

		for k, v in pairs(self.data) do
			local entities = ents.FindInSphere(v.position, 4)
			local entity = entities[1]

			if (IsValid(entity)) then
				entity:SetNetVar("title", v.title)
				entity:SetNetVar("unownable", true)
			end
		end
	end
end

nut.util.Include("sh_hooks.lua")
nut.util.Include("sh_commands.lua")