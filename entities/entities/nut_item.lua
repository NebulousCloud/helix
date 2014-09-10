AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Item"
ENT.Category = "NutScript"
ENT.Spawnable = false

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
			self:SetModel(itemTable.model)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:setNetVar("id", itemTable.uniqueID)

			if (table.Count(itemTable.data) > 0) then
				self:setNetVar("data", itemTable.data)
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

			nut.util.drawText(itemTable.name, x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)
			nut.util.drawText(itemTable.desc, x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end		
	end
end

function ENT:getItemTable()
	return nut.item.list[self:getNetVar("id", "")]
end

function ENT:getData()
	return self:getNetVar("data", {})
end