
AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Item"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.ShowPlayerInteraction = true
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self.health = 50

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end

		hook.Run("OnItemSpawned", self)
	end

	function ENT:Use(activator, caller)
		if (IsValid(caller) and caller:IsPlayer() and caller:GetChar() and self.ixItemID) then
			caller:PerformInteraction(ix.config.Get("itemPickupTime", 0.5), self, function(client)
				ix.item.PerformInventoryAction(client, "take", self)
			end)
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		local damage = dmginfo:GetDamage()
		self:SetHealth(self:Health() - damage)

		if (self:Health() <= 0 and !self.OnBreak) then
			self.OnBreak = true
			self:Remove()
		end
	end

	function ENT:SetItem(itemID)
		local itemTable = ix.item.instances[itemID]

		if (itemTable) then
			local model = itemTable.OnGetDropModel and itemTable:OnGetDropModel(self) or itemTable.model

			self:SetSkin(itemTable.skin or 0)
			if (itemTable.worldModel) then
				self:SetModel(itemTable.worldModel == true and "models/props_junk/cardboard_box004a.mdl" or itemTable.worldModel)
			else
				self:SetModel(model)
			end
			self:SetModel(model)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetNetVar("id", itemTable.uniqueID)
			self.ixItemID = itemID

			if (table.Count(itemTable.data) > 0) then
				self:SetNetVar("data", itemTable.data)
			end

			local physObj = self:GetPhysicsObject()

			if (!IsValid(physObj)) then
				local min, max = Vector(-8, -8, -8), Vector(8, 8, 8)

				self:PhysicsInitBox(min, max)
				self:SetCollisionBounds(min, max)
			end

			if (IsValid(physObj)) then
				physObj:EnableMotion(true)
				physObj:Wake()
			end

			if (itemTable.OnEntityCreated) then
				itemTable:OnEntityCreated(self)
			end
		end
	end

	function ENT:OnRemove()
		if (!ix.shuttingDown and !self.ixIsSafe and self.ixItemID) then
			local itemTable = ix.item.instances[self.ixItemID]

			if (self.OnBreak) then
				self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(1, 3)..".wav")
				local position = self:LocalToWorld(self:OBBCenter())

				local effect = EffectData()
					effect:SetStart(position)
					effect:SetOrigin(position)
					effect:SetScale(3)
				util.Effect("GlassImpact", effect)

				if (itemTable.OnDestoryed) then
					itemTable:OnDestoryed(self)
				end
			end

			if (itemTable) then
				if (itemTable.OnRemoved) then
					itemTable:OnRemoved()
				end

				local query = mysql:Delete("ix_items")
					query:Where("item_id", self.ixItemID)
				query:Execute()
			end
		end
	end

	function ENT:Think()
		local itemTable = self:GetItemTable()

		if (itemTable.Think) then
			itemTable:Think(self)
		end

		return true
	end
else
	ENT.DrawEntityInfo = true

	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha

	function ENT:OnDrawEntityInfo(alpha)
		local itemTable = self.GetItemTable(self)

		if (itemTable) then
			local oldData = itemTable.data
			itemTable.data = self.GetNetVar(self, "data", {})
			itemTable.entity = self

			local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
			local x, y = position.x, position.y
			local description = itemTable.GetDescription(itemTable)

			if (description != self.description) then
				self.description = description
				self.markup = ix.markup.Parse("<font=ixItemDescFont>" .. description .. "</font>", ScrW() * 0.7)
			end

			ix.util.DrawText(
				itemTable.GetName and itemTable:GetName() or L(itemTable.name),
				x, y, colorAlpha(ix.config.Get("color"), alpha), 1, 1, nil, alpha * 0.65
			)

			y = y + 12

			if (self.markup) then
				self.markup:draw(x, y, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, alpha)
			end

			hook.Run("DrawItemDescription", self, x, y, colorAlpha(color_white, alpha), alpha * 0.65)

			itemTable.entity = nil
			itemTable.data = oldData
		end
	end

	function ENT:DrawTranslucent()
		local itemTable = self:GetItemTable()

		if (itemTable and itemTable.DrawEntity) then
			itemTable:DrawEntity(self)
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:GetItemID()
	return self:GetNetVar("id", "")
end

function ENT:GetItemTable()
	return ix.item.list[self:GetItemID()]
end

function ENT:GetData(key, default)
	local data = self:GetNetVar("data", {})

	return data[key] or default
end
