local PLUGIN = PLUGIN

PLUGIN.name = "Persistence"
PLUGIN.description = "Define entities to persist through restarts."
PLUGIN.author = "alexgrist & Beelzebub"

-- disable default sbox persistence (because we override Get/SetPersistent behaivor)
function PLUGIN:OnLoaded()
	self._PersistenceSave = self._PersistenceSave or (hook.GetTable().PersistenceSave or {}).PersistenceSave
	self._PersistenceLoad = self._PersistenceLoad or (hook.GetTable().PersistenceLoad or {}).PersistenceLoad

	hook.Remove("PersistenceSave", "PersistenceSave")
	hook.Remove("PersistenceLoad", "PersistenceLoad")
end

-- restore it
function PLUGIN:OnUnload()
	if self._PersistenceSave then
		hook.Add("PersistenceSave", "PersistenceSave", self._PersistenceSave)
	end
	if self._PersistenceLoad then
		hook.Add("PersistenceLoad", "PersistenceLoad", self._PersistenceLoad)
	end
end

local function GetRealModel(entity)
	return entity:GetClass() == "prop_effect" and entity.AttachedEntity:GetModel() or entity:GetModel()
end

properties.Add("persist", {
	MenuLabel = "#makepersistent",
	Order = 400,
	MenuIcon = "icon16/link.png",

	Filter = function(self, entity, client)
		if (entity:IsPlayer() or entity:IsVehicle() or entity.bNoPersist) then return false end
		if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end

		return !entity:GetPersistent()
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		entity:SetPersistent(true)
		ix.log.Add(client, "persist", GetRealModel(entity), true)
	end
})

properties.Add("persist_end", {
	MenuLabel = "#stoppersisting",
	Order = 400,
	MenuIcon = "icon16/link_break.png",

	Filter = function(self, entity, client)
		if (entity:IsPlayer()) then return false end
		if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end

		return entity:GetPersistent()
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		entity:SetPersistent(false)

		ix.log.Add(client, "persist", GetRealModel(entity), false)
	end
})

if (SERVER) then
	function PLUGIN:LoadData()
		local data = self:GetData()
		if !(data and data.Entities) then return end

		local entities = duplicator.Paste(nil, data.Entities, data.Constraints)

		for _, ent in pairs(entities) do
			ent:SetPersistent(true)
		end
	end

	function PLUGIN:SaveData()
		local data = {Entities = {}, Constraints = {}}

		for _, ent in ipairs(ents.GetAll()) do
			if (!ent:GetPersistent()) then continue end

			local tmpEntities = {}
			duplicator.GetAllConstrainedEntitiesAndConstraints(ent, tmpEntities, data.Constraints)

			for k, v in pairs(tmpEntities) do
				data.Entities[k] = duplicator.CopyEntTable(v)
			end
		end

		self:SetData(data)
	end

	ix.log.AddType("persist", function(client, ...)
		local arg = {...}
		return string.format("%s has %s persistence for '%s'.", client:Name(), arg[2] and "enabled" or "disabled", arg[1])
	end)
end
