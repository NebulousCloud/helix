ENT.Type = "anim"
ENT.PrintName = "Radio"
ENT.Author = "Chessnut"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "NutScript"

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_lab/citizenradio.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(activator)
		self:SetNetVar("active", !self:GetNetVar("active", false))
	end
else
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	local COLOR_ACTIVE = Color(0, 255, 0)
	local COLOR_INACTIVE = Color(255, 0, 0)

	function ENT:Draw()
		self:DrawModel()

		local position = self:GetPos() + self:GetForward() * 10 + self:GetUp() * 11 + self:GetRight() * 9.5

		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(position, 14, 14, self:GetNetVar("active") and COLOR_ACTIVE or COLOR_INACTIVE)
	end
end