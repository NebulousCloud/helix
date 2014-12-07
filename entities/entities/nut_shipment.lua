--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Shipment"
ENT.Category = "NutScript"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/Items/item_item_crate.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:Use(activator)
		print(activator)
		if (activator:getChar() and activator:getChar():getID() == self:getNetVar("owner", 0) and hook.Run("PlayerCanOpenShipment", activator, self) != false) then
			netstream.Start(activator, "openShp", self, self.items)
		end
	end

	function ENT:setItems(items)
		self.items = items
	end

	function ENT:Break()
		local e = EffectData()
		e:SetStart(self:GetPos() + self:OBBCenter())
		util.Effect( "nutShipment", e )
		self:EmitSound(Format("physics/wood/wood_crate_break%s.wav", math.random(1, 5)))
		self:Remove()
	end
else
	local EFFECT = {}
	EFFECT.Debris = {
		"models/Gibs/wood_gib01a.mdl",
		"models/Gibs/wood_gib01b.mdl",
		"models/Gibs/wood_gib01c.mdl",
		"models/Gibs/wood_gib01d.mdl",
		"models/Gibs/wood_gib01e.mdl",
	}

	function EFFECT:Init( data ) 
		self:SetNoDraw(true)
		local pos = data:GetStart()	
		self.emitter = ParticleEmitter(Vector(0, 0, 0))

		for i = 0, 15 do
			local smoke = self.emitter:Add( "particle/smokesprites_000"..math.random(1,9), pos + VectorRand()*10)
			smoke:SetVelocity(VectorRand()*100)
			smoke:SetDieTime(math.Rand(.5,.9))
			smoke:SetStartAlpha(math.Rand(222,255))
			smoke:SetEndAlpha(0)
			smoke:SetStartSize(math.random(0,5))
			smoke:SetEndSize(math.random(22,44))
			smoke:SetRoll(math.Rand(180,480))
			smoke:SetRollDelta(math.Rand(-3,3))
			smoke:SetColor(80, 60, 0)
			smoke:SetGravity( Vector( 0, 0, 20 ) )
			smoke:SetAirResistance(250)
		end

		self.DebrisEnt = {}
		for i = 1, 5 do
			local debris = ClientsideModel(table.Random(self.Debris))
			local vec = Vector(10, 1, 2)
			local rand = math.Rand(.6, .7)
			debris:SetPos(pos + VectorRand()*15)
			debris:PhysicsInitBox( -vec*rand, vec*rand )
			debris.lifeTime = CurTime() + 1
			debris.alpha = 255
			debris:SetModelScale(debris:GetModelScale()*rand, 0)
			debris:SetAngles(AngleRand())
			debris:SetRenderMode(RENDERMODE_TRANSALPHA)

			local p = debris:GetPhysicsObject()
			if( p and p:IsValid()) then
				p:SetVelocity(VectorRand()*150)
				p:AddAngleVelocity(VectorRand()*500)
			end

			timer.Simple(2, function()
				if debris:IsValid() then
					debris:Remove()
				end
			end)
		end
	end
	effects.Register( EFFECT, "nutShipment" )

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:DrawTranslucent()
		
	end

	function ENT:onShouldDrawEntityInfo()
		return true
	end

	function ENT:onDrawEntityInfo(alpha)
		local position = self:LocalToWorld(self:OBBCenter()):ToScreen()
		local x, y = position.x, position.y
		local owner = nut.char.loaded[self:getNetVar("owner", 0)]

		nut.util.drawText(L"shipment", x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (owner) then
			nut.util.drawText(L("shipmentDesc", owner:getName()), x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end
	end
end