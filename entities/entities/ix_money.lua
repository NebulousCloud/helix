AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Money"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.ShowPlayerInteraction = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Amount")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_lab/box01a.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		else
			local min, max = Vector(-8, -8, -8), Vector(8, 8, 8)

			self:PhysicsInitBox(min, max)
			self:SetCollisionBounds(min, max)
		end
	end

	function ENT:Use(activator)
		if (self.ixSteamID and self.ixCharID) then
			local char = activator:GetCharacter()

			if (char and self.ixCharID != char:GetID() and self.ixSteamID == activator:SteamID()) then
				activator:NotifyLocalized("itemOwned")
				return false
			end
		end

		activator:PerformInteraction(ix.config.Get("itemPickupTime", 0.5), self, function(client)
			if (hook.Run("OnPickupMoney", client, self) != false) then
				self:Remove()
			end
		end)
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
	end
else
	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(container)
		local text = container:AddRow("name")
		text:SetImportant()
		text:SetText(ix.currency.Get(self:GetAmount()))
		text:SizeToContents()
	end
end
