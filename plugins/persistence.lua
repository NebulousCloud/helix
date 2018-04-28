
local PLUGIN = PLUGIN

PLUGIN.name = "Persistence"
PLUGIN.description = "Define entities to persist through restarts."
PLUGIN.author = "alexgrist"
PLUGIN.stored = PLUGIN.stored or {}
PLUGIN.NoStaticEnts = {
	"worldspawn",
	"ix_container"
}

properties.Add("persist", {
	MenuLabel = "#makepersistent",
	Order = 400,
	MenuIcon = "icon16/link.png",

	Filter = function(self, entity, client)
		if (entity:IsPlayer()) then return false end
		if (GetConVarString("sbox_persist") == "0") then return false end
		if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end

		return !entity:GetNetVar("Persistent", false)
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, player)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, player)) then return end

		PLUGIN.stored[#PLUGIN.stored + 1] = entity

		entity:SetNetVar("Persistent", true)
	end
})

properties.Add("persist_end", {
	MenuLabel = "#stoppersisting",
	Order = 400,
	MenuIcon = "icon16/link_break.png",

	Filter = function(self, entity, client)
		if (entity:IsPlayer()) then return false end
		if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end

		return entity:GetNetVar("Persistent", false)
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, player)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, player)) then return end

		for k, v in ipairs(PLUGIN.stored) do
			if (v == entity) then
				table.remove(PLUGIN.stored, k)

				break
			end
		end

		entity:SetNetVar("Persistent", false)
	end
})

if (SERVER) then
	function PLUGIN:LoadData()
		local entities = self:GetData() or {}

		for _, v in ipairs(entities) do
			local entity = ents.Create(v.Class)
			entity:SetPos(v.Pos)
			entity:SetAngles(v.Angle)
			entity:SetModel(v.Model)
			entity:SetSkin(v.Skin)
			entity:SetColor(v.Color)
			entity:SetMaterial(v.Material)
			entity:Spawn()
			entity:Activate()
			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:EnableMotion(v.Movable)
			end

			self.stored[#self.stored + 1] = entity
			entity:SetNetVar("Persistent", true)
		end
	end

	function PLUGIN:SaveData()
		local entities = {}

		for _, v in ipairs(self.stored) do
			if (IsValid(v)) then
				local data = {}
				data.Class = v.ClassOverride or v:GetClass()
				data.Pos = v:GetPos()
				data.Angle = v:GetAngles()
				data.Model = v:GetModel()
				data.Skin = v:GetSkin()
				data.Color = v:GetColor()
				data.Material = v:GetMaterial()
				local physicsObject = v:GetPhysicsObject()

				if (IsValid(physicsObject)) then
					data.Movable = physicsObject:IsMoveable()
				end

				entities[#entities + 1] = data
			end
		end

		self:SetData(entities)
	end

	function PLUGIN:PlayerSpawnedProp(client, mdl, entity)
		if client:GetNetVar("statictoggle", false) == true then
			self.stored[#self.stored + 1] = entity

			entity:SetNetVar("Persistent", true)
		end
	end
end
ix.command.Add("StaticAdd", {
	syntax = "<none>",
	adminOnly = true,
	description = "Makes an entity or prop persistent.",
	OnRun = function(self, client)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (table.HasValue(PLUGIN.NoStaticEnts, entity:GetClass())) then
			client:Notify("You did not look at a valid entity!")
			return false
		end

		if (entity) then
			PLUGIN.stored[#PLUGIN.stored + 1] = entity

			entity:SetNetVar("Persistent", true)
			client:Notify("You have added this " .. entity:GetClass() .. " as a static prop.")
		else
			client:Notify("This " .. entity:GetClass() .. " is already static!")
		end
	end
})

ix.command.Add("StaticRemove", {
	syntax = "<none>",
	adminOnly = true,
	description = "Makes an entity or prop persistent.",
	OnRun = function(self, client)
		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if table.HasValue(PLUGIN.NoStaticEnts, entity:GetClass()) then
			client:Notify("You did not look at a valid entity!")

			return false
		end

		if (entity:GetNetVar("Persistent", false) == true) then
			for k, v in ipairs(PLUGIN.stored) do
				if (v == entity) then
					table.remove(PLUGIN.stored, k)
					break
				end
			end

			entity:SetNetVar("Persistent", false)
			client:Notify("You have removed this " .. entity:GetClass() .. " as a static prop.")
		else
			client:Notify("This " .. entity:GetClass() .. " is not static!")
		end
	end
})
ix.command.Add("StaticToggle", {
	syntax = "<none>",
	adminOnly = true,
	description = "Toggle Staticing PROPS that you spawn..",
	OnRun = function(self, client)
		if (client:GetNetVar("statictoggle")) then
			client:SetNetVar("statictoggle", false)
			client:Notify("You have toggled staticing, newly spawned props will no longer static.")
		else
			client:SetNetVar("statictoggle", true)
			client:Notify("You have toggled staticing, all newly spawned props will now static.")
		end
	end
})
