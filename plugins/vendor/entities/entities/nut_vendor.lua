AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Author = "Chessnut"
ENT.Spawnable = true
ENT.Category = "NutScript"

function ENT:Initialize()
	if (SERVER) then
		self:SetModel("models/Humans/Group01/Female_01.mdl")
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
		self:DrawShadow(true)
		self:PhysicsInit(SOLID_BBOX)
		self:DropToFloor()
	else
		self:CreateBubble()
	end

	self:SetAnim("idle_angry")
end

function ENT:SetAnim(sequence)
	local index = self:LookupSequence(sequence)

	if (index and index != -1) then
		self:ResetSequence(index)
	end
end

if (CLIENT) then
	function ENT:CreateBubble()
		self.bubble = ClientsideModel("models/extras/info_speech.mdl", RENDERGROUP_OPAQUE)
		self.bubble:SetPos(self:GetPos() + Vector(0, 0, 84))
		self.bubble:SetModelScale(0.6, 0)
	end

	function ENT:Think()
		if (!IsValid(self.bubble)) then
			self:CreateBubble()
		end

		if (CLIENT) then
			self:SetEyeTarget(LocalPlayer():GetPos())
		end
	end

	function ENT:Draw()
		local bubble = self.bubble

		if (IsValid(bubble)) then
			local realTime = RealTime()

			bubble:SetAngles(Angle(0, realTime * 120, 0))
			bubble:SetRenderOrigin(self:GetPos() + Vector(0, 0, 84 + math.sin(realTime * 3) * 0.03))
		end

		self:DrawModel()
	end

	function ENT:OnRemove()
		if (IsValid(self.bubble)) then
			self.bubble:Remove()
		end
	end

	net.Receive("nut_Vendor", function(length)
		if (IsValid(nut.gui.vendor)) then
			nut.gui.vendor:Remove()

			return
		end

		nut.gui.vendor = vgui.Create("nut_Vendor")
	end)
else
	util.AddNetworkString("nut_Vendor")

	function ENT:Use(activator)
		net.Start("nut_Vendor")
		net.Send(activator)
	end
end