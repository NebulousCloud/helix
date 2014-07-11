PLUGIN.name = "Door System"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Provides ability to purchase doors and defining unownable doors."

nut.config.doorCost = 50
nut.config.doorSellAmount = 25

if (SERVER) then
	function PLUGIN:DoorSetUnownable(entity)
		entity:SetNetVar("unownable", true)
		self:SaveData()
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
		entity:SetNetVar("unownable", nil)
		self:SaveData()
	end

	function PLUGIN:DoorSetHidden(entity, hidden)
		entity:SetNetVar("hidden", hidden)
		self:SaveData()
	end

	function PLUGIN:LoadData()
		self.data = self:ReadTable()

		for k, v in pairs(self.data) do
			local entity

			if (v.position) then
				entity = ents.FindInSphere(v.position, 10)[1]
			elseif (v.index) then
				for k2, v2 in pairs(ents.GetAll()) do
					if (nut.util.GetCreationID(v2) == v.index) then
						entity = v2

						break
					end
				end
			end

			if (IsValid(entity)) then
				entity:SetNetVar("title", v.title)
				entity:SetNetVar("unownable", v.own)

				if (v.hidden) then
					entity:SetNetVar("hidden", true)
				end
			end
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in pairs(ents.GetAll()) do
			if (IsValid(v)) then
				local title = v:GetNetVar("title", "")

				if (v:IsDoor() and (v:GetNetVar("unownable") or v:GetNetVar("hidden") or (title and title != "" and title != "Door for Sale"))) then
					data[#data + 1] = {
						index = nut.util.GetCreationID(v),
						title = v:GetNetVar("title"),
						own = v:GetNetVar("unownable"),
						hidden = v:GetNetVar("hidden", false)
					}
				end
			end
		end

		self:WriteTable(data)
	end
end

nut.util.Include("sh_hooks.lua")
nut.util.Include("sh_commands.lua")