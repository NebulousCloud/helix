local SKIN = {}
	SKIN.fontFrame = "BudgetLabel"
	SKIN.fontTab = "ixSmallFont"
	SKIN.fontButton = "ixSmallFont"
	SKIN.Colours = table.Copy(derma.SkinList.Default.Colours)
	SKIN.Colours.Window.TitleActive = Color(0, 0, 0)
	SKIN.Colours.Window.TitleInactive = Color(255, 255, 255)

	SKIN.Colours.Button.Normal = Color(80, 80, 80)
	SKIN.Colours.Button.Hover = Color(255, 255, 255)
	SKIN.Colours.Button.Down = Color(180, 180, 180)
	SKIN.Colours.Button.Disabled = Color(0, 0, 0, 100)

	function SKIN:PaintFrame(panel)
		ix.util.DrawBlur(panel, 10)

		surface.SetDrawColor(45, 45, 45, 200)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())

		surface.SetDrawColor(ix.config.Get("color"))
		surface.DrawRect(0, 0, panel:GetWide(), 24)

		surface.SetDrawColor(ix.config.Get("color"))
		surface.DrawOutlinedRect(0, 0, panel:GetWide(), panel:GetTall())

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
		if (panel.m_bBackground) then
			local w, h = panel:GetWide(), panel:GetTall()

			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	function SKIN:PaintButton(panel)
		if (panel.m_bBackground) then
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

	-- I don't think we gonna need minimize button and maximize button.
	function SKIN:PaintWindowMinimizeButton( panel, w, h )
	end

	function SKIN:PaintWindowMaximizeButton( panel, w, h )
	end

derma.DefineSkin("helix", "The base skin for the Helix framework.", SKIN)
derma.RefreshSkins()
