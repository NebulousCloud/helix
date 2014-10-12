AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Item"
ENT.Category = "NutScript"
ENT.Spawnable = false
ENT.RenderGroup 		= RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:setItem(itemID)
		local itemTable = nut.item.instances[itemID]

		if (itemTable) then
			self:SetSkin(itemTable.skin or 0)
			self:SetModel(itemTable.model)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:setNetVar("id", itemTable.uniqueID)
			self.nutItemID = itemID

			if (table.Count(itemTable.data) > 0) then
				self:setNetVar("data", itemTable.data)
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
		end
	end
else
	function ENT:onShouldDrawEntityInfo()
		return true
	end

	function ENT:onDrawEntityInfo(alpha)
		local itemTable = self:getItemTable()

		if (itemTable) then
			local position = self:LocalToWorld(self:OBBCenter()):ToScreen()
			local x, y = position.x, position.y
			
			itemTable.entity = self
				nut.util.drawText(itemTable.name, x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)
				nut.util.drawText(type(itemTable.desc) == "function" and itemTable.desc(itemTable) or itemTable.desc, x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
			itemTable.entity = nil
		end		
	end

	function ENT:DrawTranslucent()
		local itemTable = self:getItemTable()

		if (itemTable.drawEntity) then
			itemTable:drawEntity(self, itemTable)
		end
	end
end

function ENT:getItemTable()
	return nut.item.list[self:getNetVar("id", "")]
end

function ENT:getData(key, default)
	local data = self:getNetVar("data", {})

	return data[key] or default
end