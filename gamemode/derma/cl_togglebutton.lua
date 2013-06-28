local PANEL = {}
	function PANEL:Init()
		self:SetDark(false)
	end

	function PANEL:DoClickInternal()
		self.toggled = !self.toggled
	end

	function PANEL:SetToggled(status)
		self.toggled = status
	end

	function PANEL:GetToggled()
		return self.toggled
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawOutlinedRect(0, 0, w, h)

		if (self.toggled) then
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
	end
vgui.Register("nut_ToggleButton", PANEL, "DButton")