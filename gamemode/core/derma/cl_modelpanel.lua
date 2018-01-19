
DEFINE_BASECLASS("DModelPanel")

local PANEL = {}
local MODEL_ANGLE = Angle(0, 45, 0)

function PANEL:Init()
	self.brightness = 1
	self:SetCursor("none")
end

function PANEL:SetModel(model)
	BaseClass.SetModel(self, model)

	local entity = self.Entity

	if (IsValid(entity)) then
		local sequence = entity:SelectWeightedSequence(ACT_IDLE)

		if (sequence <= 0) then
			sequence = entity:LookupSequence("idle_unarmed")
		end

		if (sequence > 0) then
			entity:ResetSequence(sequence)
		else
			local found = false

			for _, v in ipairs(entity:GetSequenceList()) do
				if ((v:lower():find("idle") or v:lower():find("fly")) and v != "idlenoise") then
					entity:ResetSequence(v)
					found = true

					break
				end
			end

			if (!found) then
				entity:ResetSequence(4)
			end
		end

		entity:SetIK(false)
	end
end

function PANEL:LayoutEntity()
	local scrW, scrH = ScrW(), ScrH()
	local xRatio = gui.MouseX() / scrW
	local yRatio = gui.MouseY() / scrH
	local x, _ = self:LocalToScreen(self:GetWide() / 2)
	local xRatio2 = x / scrW
	local entity = self.Entity

	entity:SetPoseParameter("head_pitch", yRatio*90 - 30)
	entity:SetPoseParameter("head_yaw", (xRatio - xRatio2)*90 - 5)
	entity:SetAngles(MODEL_ANGLE)
	entity:SetIK(false)

	if (self.copyLocalSequence) then
		entity:SetSequence(LocalPlayer():GetSequence())
		entity:SetPoseParameter("move_yaw", 360 * LocalPlayer():GetPoseParameter("move_yaw") - 180)
	end

	self:RunAnimation()
end

function PANEL:DrawModel()
	local brightness = self.brightness * 0.4
	local brightness2 = self.brightness * 1.5

	render.SetModelLighting(0, brightness2, brightness2, brightness2)

	for i = 1, 4 do
		render.SetModelLighting(i, brightness, brightness, brightness)
	end

	local fraction = (brightness / 1) * 0.1

	render.SetModelLighting(5, fraction, fraction, fraction)

	-- Excecute Some stuffs
	if (self.enableHook) then
		hook.Run("DrawHelixModelView", self, self.Entity)
	end

	self.Entity:DrawModel()
end

function PANEL:OnMousePressed()
end

vgui.Register("ixModelPanel", PANEL, "DModelPanel")
