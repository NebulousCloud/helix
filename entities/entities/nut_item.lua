AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Item"
ENT.Category = "NutScript"
ENT.Author = "Chessnut"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "InternalData")
	self:NetworkVar("String", 1, "ItemID")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:EnableMotion(true)
			physicsObject:Wake()
		else
			self:PhysicsInitBox( Vector( -2, -2, -2 ), Vector( 2, 2, 2 ) )
		end
	end

	function ENT:Use(activator)
		netstream.Start(activator, "nut_ItemMenu", self)
	end
end

function ENT:GetData()
	if (self:GetInternalData()) then
		if (!self.realData) then
			self.realData = von.deserialize(self:GetInternalData())
		end

		return self.realData
	end
end

function ENT:GetItemTable()
	if (self:GetItemID()) then
		if (!self.itemTable) then
			self.itemTable = nut.item.Get(self:GetItemID())
		end

		return self.itemTable
	end
end

if (CLIENT) then
	function ENT:DrawTargetID(x, y, alpha)
		local mainColor = nut.config.mainColor
		local itemTable = self:GetItemTable()

		if (itemTable) then
			local color = Color(mainColor.r, mainColor.g, mainColor.b, alpha)
			local data = self:GetData()

			if itemTable.color != nil then
				color = Color(itemTable.color.r, itemTable.color.g, itemTable.color.b, alpha)
			end

			nut.util.DrawText(x, y, itemTable.name, color)

			y = y + nut.config.targetTall
			color = Color(255, 255, 255, alpha)

			nut.util.DrawText(x, y, string.gsub(itemTable:GetDesc(data), "\n", " "), color, "nut_TargetFontSmall")

			if (itemTable.Paint) then
				itemTable.data = data
					itemTable:Paint(self, x, y + nut.config.targetTall, color)
				itemTable.data = nil
			end
		end
	end

	netstream.Hook("nut_ItemMenu", function(entity)
		if (IsValid(entity) and entity:GetPos():Distance(LocalPlayer():GetPos()) <= 72) then
			nut.item.OpenEntityMenu(entity)
		end
	end)
end
