
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Shipment"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.ShowPlayerInteraction = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "DeliveryTime")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/Items/item_item_crate.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:PrecacheGibs()

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end

		self:SetDeliveryTime(CurTime() + 120)

		timer.Simple(120, function()
			if (IsValid(self)) then
				self:Remove()
			end
		end)
	end

	function ENT:Use(activator)
		activator:PerformInteraction(ix.config.Get("itemPickupTime", 0.5), self, function(client)
			if (client:GetCharacter() and client:GetCharacter():GetID() == self:GetNetVar("owner", 0)
			and hook.Run("CanPlayerOpenShipment", client, self) != false) then
				client.ixShipment = self

				net.Start("ixShipmentOpen")
					net.WriteEntity(self)
					net.WriteTable(self.items)
				net.Send(client)
			end
		end)
	end

	function ENT:SetItems(items)
		self.items = items
	end

	function ENT:GetItemCount()
		local count = 0

		for _, v in pairs(self.items) do
			count = count + math.max(v, 0)
		end

		return count
	end

	function ENT:OnRemove()
		self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(1, 3)..".wav")

		local position = self:LocalToWorld(self:OBBCenter())

		local effect = EffectData()
			effect:SetStart(position)
			effect:SetOrigin(position)
			effect:SetScale(3)
		util.Effect("GlassImpact", effect)
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
	end
else
	ENT.PopulateEntityInfo = true

	local size = 150
	local tempMat = Material("particle/warp1_warp", "alphatest")

	function ENT:Draw()
		local pos, ang = self:GetPos(), self:GetAngles()

		self:DrawModel()

		pos = pos + self:GetUp() * 25
		pos = pos + self:GetForward() * 1
		pos = pos + self:GetRight() * 3

		local delTime = math.max(math.ceil(self:GetDeliveryTime() - CurTime()), 0)

		local func = function()
			surface.SetMaterial(tempMat)
			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawTexturedRect(-size / 2, -size / 2 - 10, size, size)

			ix.util.DrawText("k", 0, 0, color_white, 1, 4, "ixIconsBig")
			ix.util.DrawText(delTime, 0, -10, color_white, 1, 5, "ixBigFont")
		end

		cam.Start3D2D(pos, ang, .15)
			func()
		cam.End3D2D()

		ang:RotateAroundAxis(ang:Right(), 180)
		pos = pos - self:GetUp() * 26

		cam.Start3D2D(pos, ang, .15)
			func()
		cam.End3D2D()
	end

	function ENT:OnPopulateEntityInfo(container)
		local owner = ix.char.loaded[self:GetNetVar("owner", 0)]

		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("shipment"))
		name:SizeToContents()

		if (owner) then
			local description = container:AddRow("description")
			description:SetText(L("shipmentDesc", owner:GetName()))
			description:SizeToContents()
		end
	end
end
