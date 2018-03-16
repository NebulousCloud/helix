
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

			if (itemTable.material) then
				self:SetMaterial(itemTable.material)
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
	local shadeColor = Color(0, 0, 0, 200)
	local blockSize = 4
	local blockSpacing = 2

	function ENT:DrawItemSize(itemTable, x, y, alpha)
		local width = itemTable.width - 1
		local height = itemTable.height - 1
		local heightDifference = ((height + 1) * blockSize + blockSpacing * height)

		x = x - (width * blockSize + blockSpacing * width) * 0.5
		y = y - heightDifference * 0.5

		for i = 0, height do
			for j = 0, width do
				local blockX, blockY = x + j * blockSize + j * blockSpacing, y + i * blockSize + i * blockSpacing
				local blockAlpha = Lerp(alpha / 255, 0, 255 + (i + j) * 100)

				surface.SetDrawColor(ColorAlpha(shadeColor, blockAlpha))
				surface.DrawRect(blockX + 1, blockY + 1, blockSize, blockSize)

				surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), blockAlpha))
				surface.DrawRect(blockX, blockY, blockSize, blockSize)
			end
		end

		return heightDifference + 4
	end

	function ENT:OnDrawEntityInfo(alpha)
		local itemTable = self:GetItemTable()

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

			if ((itemTable.width > 1 or itemTable.height > 1) and
				hook.Run("ShouldDrawItemSize", itemTable) != false) then
				y = y + self:DrawItemSize(itemTable, x, y, alpha)
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

function ENT:GetEntityMenu(client)
	local itemTable = self:GetItemTable()
	local options = {}

	if (!itemTable) then
		return false
	end

	itemTable.player = client
	itemTable.entity = self

	for k, v in SortedPairs(itemTable.functions) do
		if (k == "take") then
			continue
		end

		if (v.OnCanRun and v.OnCanRun(itemTable) == false) then
			continue
		end

		-- we keep the localized phrase since we aren't using the callbacks - the name won't matter in this case
		options[L(v.name or k)] = function()
			local send = true

			if (v.OnClick) then
				send = v.OnClick(itemTable)
			end

			if (v.sound) then
				surface.PlaySound(v.sound)
			end

			if (send != false) then
				netstream.Start("invAct", k, self)
			end

			-- don't run callbacks since we're handling it manually
			return false
		end
	end

	itemTable.player = nil
	itemTable.entity = nil

	return options
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
