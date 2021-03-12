
AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Item"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.ShowPlayerInteraction = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ItemID")
end

if (SERVER) then
	local invalidBoundsMin = Vector(-8, -8, -8)
	local invalidBoundsMax = Vector(8, 8, 8)

	util.AddNetworkString("ixItemEntityAction")

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
	end

	function ENT:Use(activator, caller)
		local itemTable = self:GetItemTable()

		if (IsValid(caller) and caller:IsPlayer() and caller:GetCharacter() and itemTable) then
			itemTable.player = caller
			itemTable.entity = self

			if (itemTable.functions.take.OnCanRun(itemTable)) then
				caller:PerformInteraction(ix.config.Get("itemPickupTime", 0.5), self, function(client)
					if (!ix.item.PerformInventoryAction(client, "take", self)) then
						return false -- do not mark dirty if interaction fails
					end
				end)
			end

			itemTable.player = nil
			itemTable.entity = nil
		end
	end

	function ENT:SetItem(itemID)
		local itemTable = ix.item.instances[itemID]

		if (itemTable) then
			local material = itemTable:GetMaterial(self)

			self:SetSkin(itemTable:GetSkin())
			self:SetModel(itemTable:GetModel())

			if (material) then
				self:SetMaterial(material)
			end

			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetItemID(itemTable.uniqueID)
			self.ixItemID = itemID

			if (!table.IsEmpty(itemTable.data)) then
				self:SetNetVar("data", itemTable.data)
			end

			local physObj = self:GetPhysicsObject()

			if (!IsValid(physObj)) then
				self:PhysicsInitBox(invalidBoundsMin, invalidBoundsMax)
				self:SetCollisionBounds(invalidBoundsMin, invalidBoundsMax)
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

	function ENT:OnDuplicated(entTable)
		local itemID = entTable.ixItemID
		local itemTable = ix.item.instances[itemID]

		ix.item.Instance(0, itemTable.uniqueID, itemTable.data, 1, 1, function(item)
			self:SetItem(item:GetID())
		end)
	end

	function ENT:OnTakeDamage(damageInfo)
		local itemTable = ix.item.instances[self.ixItemID]

		if (itemTable.OnEntityTakeDamage
		and itemTable:OnEntityTakeDamage(self, damageInfo) == false) then
			return
		end

		local damage = damageInfo:GetDamage()
		self:SetHealth(self:Health() - damage)

		if (self:Health() <= 0 and !self.ixIsDestroying) then
			self.ixIsDestroying = true
			self.ixDamageInfo = {damageInfo:GetAttacker(), damage, damageInfo:GetInflictor()}
			self:Remove()
		end
	end

	function ENT:OnRemove()
		if (!ix.shuttingDown and !self.ixIsSafe and self.ixItemID) then
			local itemTable = ix.item.instances[self.ixItemID]

			if (itemTable) then
				if (self.ixIsDestroying) then
					self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(1, 3)..".wav")
					local position = self:LocalToWorld(self:OBBCenter())

					local effect = EffectData()
						effect:SetStart(position)
						effect:SetOrigin(position)
						effect:SetScale(3)
					util.Effect("GlassImpact", effect)

					if (itemTable.OnDestroyed) then
						itemTable:OnDestroyed(self)
					end

					ix.log.Add(self.ixDamageInfo[1], "itemDestroy", itemTable:GetName(), itemTable:GetID())
				end

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

		if (!itemTable) then
			self:Remove()
		end

		if (itemTable.Think) then
			itemTable:Think(self)
		end

		return true
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
	end

	net.Receive("ixItemEntityAction", function(length, client)
		ix.item.PerformInventoryAction(client, net.ReadString(), net.ReadEntity())
	end)
else
	ENT.PopulateEntityInfo = true

	local shadeColor = Color(0, 0, 0, 200)
	local blockSize = 4
	local blockSpacing = 2

	function ENT:OnPopulateEntityInfo(tooltip)
		local item = self:GetItemTable()

		if (!item) then
			return
		end

		local oldData = item.data

		item.data = self:GetNetVar("data", {})
		item.entity = self

		ix.hud.PopulateItemTooltip(tooltip, item)

		local name = tooltip:GetRow("name")
		local color = name and name:GetBackgroundColor() or ix.config.Get("color")

		-- set the arrow to be the same colour as the title/name row
		tooltip:SetArrowColor(color)

		if ((item.width > 1 or item.height > 1) and
			hook.Run("ShouldDrawItemSize", item) != false) then

			local sizeHeight = item.height * blockSize + item.height * blockSpacing
			local size = tooltip:Add("Panel")
			size:SetWide(tooltip:GetWide())

			if (tooltip:IsMinimal()) then
				size:SetTall(sizeHeight)
				size:Dock(TOP)
				size:SetZPos(-999)
			else
				size:SetTall(sizeHeight + 8)
				size:Dock(BOTTOM)
			end

			size.Paint = function(sizePanel, width, height)
				if (!tooltip:IsMinimal()) then
					surface.SetDrawColor(ColorAlpha(shadeColor, 60))
					surface.DrawRect(0, 0, width, height)
				end

				local x, y = width * 0.5 - 1, height * 0.5 - 1
				local itemWidth = item.width - 1
				local itemHeight = item.height - 1
				local heightDifference = ((itemHeight + 1) * blockSize + blockSpacing * itemHeight)

				x = x - (itemWidth * blockSize + blockSpacing * itemWidth) * 0.5
				y = y - heightDifference * 0.5

				for i = 0, itemHeight do
					for j = 0, itemWidth do
						local blockX, blockY = x + j * blockSize + j * blockSpacing, y + i * blockSize + i * blockSpacing

						surface.SetDrawColor(shadeColor)
						surface.DrawRect(blockX + 1, blockY + 1, blockSize, blockSize)

						surface.SetDrawColor(color)
						surface.DrawRect(blockX, blockY, blockSize, blockSize)
					end
				end
			end

			tooltip:SizeToContents()
		end

		item.entity = nil
		item.data = oldData
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
		if (k == "take" or k == "combine") then
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
				net.Start("ixItemEntityAction")
					net.WriteString(k)
					net.WriteEntity(self)
				net.SendToServer()
			end

			-- don't run callbacks since we're handling it manually
			return false
		end
	end

	itemTable.player = nil
	itemTable.entity = nil

	return options
end

function ENT:GetItemTable()
	return ix.item.list[self:GetItemID()]
end

function ENT:GetData(key, default)
	local data = self:GetNetVar("data", {})

	return data[key] or default
end
