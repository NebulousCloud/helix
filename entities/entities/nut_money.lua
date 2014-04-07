AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Money"
ENT.Author = "Chessnut"
ENT.Category = "NutScript"

if (SERVER) then
	function ENT:Initialize()
		self:SetModel(nut.config.moneyModel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetNetVar("amount", 0)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:Wake()
		end

		hook.Run("MoneyEntityCreated", self)
	end

	function ENT:SetMoney(amount)
		if (amount <= 0) then
			self:Remove()
		end

		self:SetNetVar("amount", amount)
	end

	function ENT:Use(activator)
		local amount = self:GetNetVar("amount", 0)

		if (amount > 0 and IsValid(activator) and activator.character and hook.Run("PlayerCanPickupMoney", activator, self) != false) then
			if (self.owner == activator and self.charindex != activator.character.index) then
				nut.util.Notify("You can't pick up your other character's money.", activator)

				return
			end

			activator:GiveMoney(amount)
			nut.util.Notify("You have picked up "..nut.currency.GetName(amount)..".", activator)

			self:Remove()
		end
	end

	function ENT:StartTouch(entity)
		if (entity:GetClass() == "nut_money") then
			self:SetMoney(self:GetNetVar("amount", 0) + entity:GetNetVar("amount", 0))
			entity:Remove()
		end
	end
else
	function ENT:DrawTargetID(x, y, alpha)
		nut.util.DrawText(x, y, nut.currency.GetName(self:GetNetVar("amount", 0), true), Color(255, 255, 255, alpha))
	end
end