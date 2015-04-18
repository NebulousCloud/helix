local PANEL = {}
	function PANEL:Init()
		nut.gui.quick = self

		self:SetSize(400, 36)
		self:SetPos(ScrW() - 36, -36)
		self:MakePopup()
		self:SetKeyBoardInputEnabled(false)
		self:SetZPos(999)
		self:SetMouseInputEnabled(true)
		
		self.title = self:Add("DLabel")
		self.title:SetTall(36)
		self.title:Dock(TOP)
		self.title:SetFont("nutMediumFont")
		self.title:SetText(L"quickSettings")
		self.title:SetContentAlignment(4)
		self.title:SetTextInset(44, 0)
		self.title:SetTextColor(Color(250, 250, 250))
		self.title:SetExpensiveShadow(1, Color(0, 0, 0, 175))
		self.title.Paint = function(this, w, h)
			surface.SetDrawColor(nut.config.get("color"))
			surface.DrawRect(0, 0, w, h)
		end

		self.expand = self:Add("DButton")
		self.expand:SetContentAlignment(5)
		self.expand:SetText("`")
		self.expand:SetFont("nutIconsMedium")
		self.expand:SetDrawBackground(false)
		self.expand:SetTextColor(color_white)
		self.expand:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.expand:SetSize(36, 36)
		self.expand.DoClick = function(this)
			if (self.expanded) then
				self:SizeTo(self:GetWide(), 36, 0.15, nil, nil, function()
					self:MoveTo(ScrW() - 36, 0, 0.15)
				end)

				self.expanded = false
			else
				self:MoveTo(ScrW() - 400, 0, 0.15, nil, nil, function()
					local height = 0

					for k, v in pairs(self.items) do
						if (IsValid(v)) then
							height = height + v:GetTall() + 1
						end
					end

					self:SizeTo(self:GetWide(), 36 + height, 0.15)
				end)

				self.expanded = true
			end
		end

		self.scroll = self:Add("DScrollPanel")
		self.scroll:SetPos(0, 36)
		self.scroll:SetSize(self:GetWide(), ScrH() * 0.5)
		
		self:MoveTo(self.x, 0, 0.05)

		self.items = {}

		hook.Run("SetupQuickMenu", self)
	end

	local function paintButton(button, w, h)
		local alpha = 0

		if (button.Depressed or button.m_bSelected) then
			alpha = 5
		elseif (button.Hovered) then
			alpha = 2
		end

		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(0, 0, w, h)
	end

	function PANEL:addButton(text, callback)
		local button = self.scroll:Add("DButton")
		button:SetText(text)
		button:SetTall(36)
		button:Dock(TOP)
		button:DockMargin(0, 1, 0, 0)
		button:SetFont("nutMediumLightFont")
		button:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		button:SetContentAlignment(4)
		button:SetTextInset(8, 0)
		button:SetTextColor(color_white)
		button.Paint = paintButton

		if (callback) then
			button.DoClick = callback
		end

		self.items[#self.items + 1] = button

		return button
	end

	function PANEL:addSpacer()
		local panel = self.scroll:Add("DPanel")
		panel:SetTall(1)
		panel:Dock(TOP)
		panel:DockMargin(0, 1, 0, 0)
		panel.Paint = function(this, w, h)
			surface.SetDrawColor(255, 255, 255, 10)
			surface.DrawRect(0, 0, w, h)
		end

		self.items[#self.items + 1] = panel

		return panel
	end

	local color_dark = Color(255, 255, 255, 5)

	function PANEL:addCheck(text, callback, checked)
		local x, y
		local color

		local button = self:addButton(text, function(panel)
			panel.checked = !panel.checked

			if (callback) then
				callback(panel, panel.checked)
			end
		end)
		button.PaintOver = function(this, w, h)
			x, y = w - 8, h * 0.5

			if (this.checked) then
				color = nut.config.get("color")
			else
				color = color_dark
			end

			draw.SimpleText(self.icon or "F", "nutIconsSmall", x, y, color, 2, 1)
		end
		button.checked = checked

		return button
	end

	function PANEL:setIcon(char)
		self.icon = char
	end

	function PANEL:Paint(w, h)
		nut.util.drawBlur(self)

		surface.SetDrawColor(nut.config.get("color"))
		surface.DrawRect(0, 0, w, 36)

		surface.SetDrawColor(255, 255, 255, 5)
		surface.DrawRect(0, 0, w, h)
	end
vgui.Register("nutQuick", PANEL, "EditablePanel")