local SKIN = {}
	function SKIN:PaintFrame(panel)
		self:DrawGenericBackground(0, 0, panel:GetWide(), panel:GetTall())

		surface.SetDrawColor(0, 0, 0, 55)
		surface.DrawRect(0, 0, panel:GetWide(), 24)
	end

	function SKIN:DrawGenericBackground(x, y, w, h)
		surface.SetDrawColor(45, 45, 45, 240)
		surface.DrawRect(x, y, w, h)

		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawOutlinedRect(x, y, w, h)

		surface.SetDrawColor(100, 100, 100, 25)
		surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2)
	end

	function SKIN:PaintPanel(panel)
		if (panel:GetPaintBackground()) then
			local w, h = panel:GetWide(), panel:GetTall()

			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	function SKIN:PaintButton(panel)
		if (panel:GetPaintBackground()) then
			local w, h = panel:GetWide(), panel:GetTall()
			local alpha = 50

			if (panel:GetDisabled()) then
				alpha = 10
			elseif (panel.Depressed) then
				alpha = 180
			elseif (panel.Hovered) then
				alpha = 75
			end

			surface.SetDrawColor(30, 30, 30, alpha)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(0, 0, 0, 180)
			surface.DrawOutlinedRect(0, 0, w, h)

			surface.SetDrawColor(180, 180, 180, 2)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
		end
	end
derma.DefineSkin("nutscript", "The base skin for the NutScript framework.", SKIN)
derma.RefreshSkins()