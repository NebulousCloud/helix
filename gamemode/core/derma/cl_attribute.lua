local PANEL = {}
	local gradient = nut.util.getMaterial("vgui/gradient-u")
	local gradient2 = nut.util.getMaterial("vgui/gradient-d")

	function PANEL:Init()
		self:SetTall(20)

		self.add = self:Add("DImageButton")
		self.add:SetSize(16, 16)
		self.add:Dock(RIGHT)
		self.add:DockMargin(2, 2, 2, 2)
		self.add:SetImage("icon16/add.png")
		self.add.OnMousePressed = function()
			self.pressing = 1
			self:doChange()
			self.add:SetAlpha(150)
		end
		self.add.OnMouseReleased = function()
			if (self.pressing) then
				self.pressing = nil
				self.add:SetAlpha(255)
			end
		end
		self.add.OnCursorExited = self.add.OnMouseReleased

		self.sub = self:Add("DImageButton")
		self.sub:SetSize(16, 16)
		self.sub:Dock(LEFT)
		self.sub:DockMargin(2, 2, 2, 2)
		self.sub:SetImage("icon16/delete.png")
		self.sub.OnMousePressed = function()
			self.pressing = -1
			self:doChange()
			self.sub:SetAlpha(150)
		end
		self.sub.OnMouseReleased = function()
			if (self.pressing) then
				self.pressing = nil
				self.sub:SetAlpha(255)
			end
		end
		self.sub.OnCursorExited = self.sub.OnMouseReleased

		self.value = 0
		self.deltaValue = self.value
		self.max = 10

		self.bar = self:Add("DPanel")
		self.bar:Dock(FILL)
		self.bar.Paint = function(this, w, h)
			surface.SetDrawColor(35, 35, 35, 250)
			surface.DrawRect(0, 0, w, h)

			w, h = w - 4, h - 4

			local value = self.deltaValue / self.max

			if (value > 0) then
				local color = nut.config.get("color")
				local add = 0

				if (self.deltaValue != self.value) then
					add = 35
				end

				surface.SetDrawColor(color.r + add, color.g + add, color.b + add, 230)
				surface.DrawRect(2, 2, w * value, h)

				surface.SetDrawColor(255, 255, 255, 35)
				surface.SetMaterial(gradient)
				surface.DrawTexturedRect(2, 2, w * value, h)
			end

			surface.SetDrawColor(255, 255, 255, 5)
			surface.SetMaterial(gradient2)
			surface.DrawTexturedRect(2, 2, w, h)
		end

		self.label = self.bar:Add("DLabel")
		self.label:Dock(FILL)
		self.label:SetExpensiveShadow(1, Color(0, 0, 60))
		self.label:SetContentAlignment(5)
	end

	function PANEL:Think()
		if (self.pressing) then
			if ((self.nextPress or 0) < CurTime()) then
				self:doChange()
			end
		end

		self.deltaValue = math.Approach(self.deltaValue, self.value, FrameTime() * 7.5)
	end

	function PANEL:doChange()
		if ((self.value == 0 and self.pressing == -1) or (self.value == self.max and self.pressing == 1)) then
			return
		end
		
		self.nextPress = CurTime() + 0.2
		
		if (self:onChanged(self.pressing) != false) then
			self.value = math.Clamp(self.value + self.pressing, 0, self.max)
		end
	end

	function PANEL:onChanged(difference)
	end

	function PANEL:getValue()
		return self.value
	end

	function PANEL:setValue(value)
		self.value = value
	end

	function PANEL:setMax(max)
		self.max = max
	end

	function PANEL:setText(text)
		self.label:SetText(text)
	end

	function PANEL:setReadOnly()
		self.sub:Remove()
		self.add:Remove()
	end
vgui.Register("nutAttribBar", PANEL, "DPanel")