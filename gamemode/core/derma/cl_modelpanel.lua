local PANEL = {}
	local MODEL_ANGLE = Angle(0, 45, 0)

	function PANEL:Init()
		self.brightness = 1

		self:SetCursor("none")
		self.OldSetModel = self.SetModel
		self.SetModel = function(self, model)
			self:OldSetModel(model)

			local entity = self.Entity
			local sequence = entity:LookupSequence("idle")

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_subtle")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("batonidle2")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_unarmed")
			end

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle01")
			end

			if (sequence > 0) then
				entity:ResetSequence(sequence)
			end

			entity:SetIK(false)
		end
	end

	function PANEL:LayoutEntity()
		local scrW, scrH = ScrW(), ScrH()
		local xRatio = gui.MouseX() / scrW
		local yRatio = gui.MouseY() / scrH
		local x, y = self:LocalToScreen(self:GetWide() / 2)
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
		local curparent = self
		local rightx = self:GetWide()
		local leftx = 0
		local topy = 0
		local bottomy = self:GetTall()
		local previous = curparent

		while(curparent:GetParent() != nil) do
			curparent = curparent:GetParent()
			local x,y = previous:GetPos()
			topy = math.Max(y, topy+y)
			leftx = math.Max(x, leftx+x)
			bottomy = math.Min(y+previous:GetTall(), bottomy + y)
			rightx = math.Min(x+previous:GetWide(), rightx + x)
			previous = curparent
		end

		render.SetScissorRect(leftx,topy,rightx, bottomy, true)
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
				hook.Run("DrawNutModelView", self, self.Entity)
			end
			
			self.Entity:DrawModel()
		render.SetScissorRect(0,0,0,0, false)
	end

	function PANEL:OnMousePressed()
	end
vgui.Register("nutModelPanel", PANEL, "DModelPanel")