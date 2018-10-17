
local PLUGIN = PLUGIN

PLUGIN.name = "Containers"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Provides the ability to store items."
PLUGIN.definitions = PLUGIN.definitions or {}

ix.util.Include("sh_definitions.lua")

for k, v in pairs(PLUGIN.definitions) do
	if (v.name and v.width and v.height) then
		ix.item.RegisterInv("container:" .. k:lower(), v.width, v.height)
	else
		ErrorNoHalt("[Helix] Container for '"..k.."' is missing all inventory information!\n")
		PLUGIN.definitions[k] = nil
	end
end

ix.config.Add("containerSave", true, "Whether or not containers will save after a server restart.", nil, {
	category = "Containers"
})

ix.config.Add("containerOpenTime", 0.7, "How long it takes to open a container.", nil, {
	data = {min = 0, max = 50},
	category = "Containers"
})

if (SERVER) then
	util.AddNetworkString("ixContainerPassword")

	function PLUGIN:PlayerSpawnedProp(client, model, entity)
		model = tostring(model):lower()
		local data = self.definitions[model:lower()]

		if (data) then
			if (hook.Run("CanPlayerSpawnContainer", client, model, entity) == false) then return end

			local container = ents.Create("ix_container")
			container:SetPos(entity:GetPos())
			container:SetAngles(entity:GetAngles())
			container:SetModel(model)
			container:Spawn()

			ix.item.NewInv(0, "container:" .. model, function(inventory)
				-- we'll technically call this a bag since we don't want other bags to go inside
				inventory.vars.isBag = true
				inventory.vars.isContainer = true

				if (IsValid(container)) then
					container:SetInventory(inventory)
				end
			end)

			self:SaveContainer()
			entity:Remove()
		end
	end

	function PLUGIN:CanSaveContainer(entity, inventory)
		return ix.config.Get("containerSave", true)
	end

	function PLUGIN:SaveContainer()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_container")) do
			if (hook.Run("CanSaveContainer", v, v:GetInventory()) != false) then
				local inventory = v:GetInventory()

				if (inventory) then
					data[#data + 1] = {
						v:GetPos(),
						v:GetAngles(),
						inventory:GetID(),
						v:GetModel(),
						v.password,
						v.name,
						v:GetMoney()
					}
				end
			else
				local index = v:GetNetVar("id")

				local query = mysql:Delete("ix_items")
					query:Where("inventory_id", index)
				query:Execute()

				query = mysql:Delete("ix_inventories")
					query:Where("inventory_id", index)
				query:Execute()
			end
		end

		self:SetData(data)
	end

	function PLUGIN:SaveData()
		self:SaveContainer()
	end

	function PLUGIN:ContainerRemoved(entity, inventory)
		self:SaveContainer()
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local data2 = self.definitions[v[4]:lower()]

				if (data2) then
					local entity = ents.Create("ix_container")
					entity:SetPos(v[1])
					entity:SetAngles(v[2])
					entity:Spawn()
					entity:SetModel(v[4])
					entity:SetSolid(SOLID_VPHYSICS)
					entity:PhysicsInit(SOLID_VPHYSICS)

					if (v[5]) then
						entity.password = v[5]
						entity:SetNetVar("locked", true)
						entity.Sessions = {}
					end

					if (v[6]) then
						entity.name = v[6]
						entity:SetNetVar("name", v[6])
					end

					if (v[7]) then
						entity:SetMoney(v[7])
					end

					ix.item.RestoreInv(v[3], data2.width, data2.height, function(inventory)
						inventory.vars.isBag = true
						inventory.vars.isContainer = true

						if (IsValid(entity)) then
							entity:SetInventory(inventory)
						end
					end)

					local physObject = entity:GetPhysicsObject()

					if (physObject) then
						physObject:EnableMotion()
					end
				end
			end
		end
	end

	net.Receive("ixContainerPassword", function(length, client)
		local entity = net.ReadEntity()
		local password = net.ReadString()
		local dist = entity:GetPos():DistToSqr(client:GetPos())

		if (dist < 16384 and password) then
			if (entity.password and entity.password == password) then
				entity:OpenInventory(client)
			else
				client:NotifyLocalized("wrongPassword")
			end
		end
	end)

	ix.log.AddType("containerPassword", function(client, ...)
		local arg = {...}
		return string.format("%s has %s the password for '%s'.", client:Name(), arg[3] and "set" or "removed", arg[1], arg[2])
	end)

	ix.log.AddType("containerName", function(client, ...)
		local arg = {...}

		if (arg[3]) then
			return string.format("%s has set container %d name to '%s'.", client:Name(), arg[2], arg[1])
		else
			return string.format("%s has removed container %d name.", client:Name(), arg[2])
		end
	end)

	ix.log.AddType("openContainer", function(client, ...)
		local arg = {...}
		return string.format("%s opened the '%s' #%d container.", client:Name(), arg[1], arg[2])
	end, FLAG_NORMAL)

	ix.log.AddType("closeContainer", function(client, ...)
		local arg = {...}
		return string.format("%s closed the '%s' #%d container.", client:Name(), arg[1], arg[2])
	end, FLAG_NORMAL)
else
	net.Receive("ixContainerPassword", function(length)
		local entity = net.ReadEntity()

		Derma_StringRequest(
			L("containerPasswordWrite"),
			L("containerPasswordWrite"),
			"",
			function(val)
				net.Start("ixContainerPassword")
					net.WriteEntity(entity)
					net.WriteString(val)
				net.SendToServer()
			end
		)
	end)
end

properties.Add("container_setpassword", {
	MenuLabel = "Set Password",
	Order = 400,
	MenuIcon = "icon16/lock_edit.png",

	Filter = function(self, entity, client)
		if (entity:GetClass() != "ix_container") then return false end
		if (!gamemode.Call("CanProperty", client, "container_setpassword", entity)) then return false end

		return true
	end,

	Action = function(self, entity)
		Derma_StringRequest(L("containerPasswordWrite"), "", "", function(text)
			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(text)
			self:MsgEnd()
		end)
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		local password = net.ReadString()

		entity.Sessions = {}

		if (password:len() != 0) then
			entity:SetNetVar("locked", true)
			entity.password = password

			client:NotifyLocalized("containerPassword", password)
		else
			entity:SetNetVar("locked", nil)
			entity.password = nil

			client:NotifyLocalized("containerPasswordRemove")
		end

		local definition = PLUGIN.definitions[entity:GetModel():lower()]
		local name = entity:GetNetVar("name", definition.name)
		local inventory = entity:GetInventory()

		ix.log.Add(client, "containerPassword", name, inventory:GetID(), password:len() != 0)
	end
})

properties.Add("container_setname", {
	MenuLabel = "Set Name",
	Order = 400,
	MenuIcon = "icon16/tag_blue_edit.png",

	Filter = function(self, entity, client)
		if (entity:GetClass() != "ix_container") then return false end
		if (!gamemode.Call("CanProperty", client, "container_setname", entity)) then return false end

		return true
	end,

	Action = function(self, entity)
		Derma_StringRequest(L("containerNameWrite"), "", "", function(text)
			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(text)
			self:MsgEnd()
		end)
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		local name = net.ReadString()

		if (name:len() != 0) then
			entity:SetNetVar("name", name)
			entity.name = name

			client:NotifyLocalized("containerName", name)
		else
			entity:SetNetVar("name", nil)
			entity.name = nil

			client:NotifyLocalized("containerNameRemove")
		end

		local inventory = entity:GetInventory()

		ix.log.Add(client, "containerName", name, inventory:GetID(), name:len() != 0)
	end
})
