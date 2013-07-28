local PANEL = {}
	local HOVER_ALPHA = 150

	function PANEL:Init()
		surface.SetFont("nut_MenuButtonFont")
		local _, height = surface.GetTextSize("W")

		self:SetTall(height + 16)
		self:DockMargin(0, 0, 0, 8)
		self:Dock(TOP)
		self:SetDrawBackground(false)
		self:SetFont("nut_MenuButtonFont")
		self:SetTextColor(Color(240, 240, 240))
		self:SetExpensiveShadow(1, color_black)
		self.alphaApproach = 15
		self.alpha = self.alphaApproach
	end

	function PANEL:OnCursorEntered()
		surface.PlaySound("ui/buttonrollover.wav")
		self.alpha = HOVER_ALPHA
	end

	function PANEL:OnCursorExited()
		self.alpha = 15
	end
	
	function PANEL:DoClick()
		if (self.OnClick) then
			local result = self:OnClick()

			if (result == false) then
				surface.PlaySound("buttons/button8.wav")
			else
				surface.PlaySound("ui/buttonclick.wav")
				self.alphaApproach = HOVER_ALPHA + 150
			end
		end
	end

	local sin = math.sin

	function PANEL:Paint(w, h)
		self.alphaApproach = math.Approach(self.alphaApproach, self.alpha, FrameTime() * 150)

		local blink = 0

		if (self.alphaApproach == HOVER_ALPHA) then
			blink = sin(RealTime() * 5) * 10
		end

		local color = nut.config.mainColor

		surface.SetDrawColor(color.r, color.g, color.b, self.alphaApproach + blink)
		surface.DrawRect(0, 0, w, h)
	end
vgui.Register("nut_MenuButton", PANEL, "DButton")