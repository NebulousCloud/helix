local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)

		self.amount = 0
		self.max = 10
		self.min = 0

		self.deltaWidth = 0

		self.minus = self:Add("DButton")
		self.minus:Dock(LEFT)
		self.minus:SetText("")
		self.minus:SetSize(24, 24)
		self.minus:SetImage("icon16/delete.png")
		self.minus.OnMousePressed =  function(panel)
			panel.pressed = true

			if (self.OnPressed) then
				self:OnPressed()
			end
		end
		self.minus.OnMouseReleased = function(panel)
			panel.pressed = false

			if (self.OnReleased) then
				self:OnReleased()
			end
		end
		self.minus.OnCursorExited = function(panel)
			panel.pressed = false
		end
		self.minus.Think = function(panel)
			if ((panel.nextTick or 0) < CurTime()) then
				if (panel.pressed) then
					if (self.amount - 1 >= self.min and self:CanChange(true)) then
						self.amount = self.amount - 1
						self:OnChanged(true)
					end
				end

				panel.nextTick = CurTime() + 0.15
			end
		end
		self.minus.Paint = function() end

		local border = 3

		self.content = self:Add("DPanel")
		self.content:Dock(FILL)
		self.content.Paint = function(panel, w, h)
			surface.SetDrawColor(5, 5, 5, 40)
			surface.DrawRect(1, 1, w - 2, h - 2)

			if (self.max == 0) then
				self.max = 1
			end

			local newWidth = w * (self.amount / self.max)
				self.deltaWidth = math.Approach(self.deltaWidth, newWidth, FrameTime() * 500)
			local width = self.deltaWidth
			local change = 0

			if (newWidth != self.deltaWidth) then
				change = 20
			end

			local color = nut.config.mainColor

			surface.SetDrawColor(color.r + change, color.g + change, color.b + change, 225 + (change / 2))
			surface.DrawRect(1 + border, 1 + border, width - (2 + border*2), h - (2 + border*2))
		end

		self.plus = self:Add("DButton")
		self.plus:Dock(RIGHT)
		self.plus:SetText("")
		self.plus:SetSize(24, 24)
		self.plus:SetImage("icon16/add.png")
		self.plus.OnMousePressed =  function(panel)
			panel.pressed = true

			if (self.OnPressed) then
				self:OnPressed()
			end
		end
		self.plus.OnCursorExited = function(panel)
			panel.pressed = false
		end
		self.plus.OnMouseReleased = function(panel)
			panel.pressed = false

			if (self.OnReleased) then
				self:OnReleased()
			end
		end
		self.plus.Think = function(panel)
			if ((panel.nextTick or 0) < CurTime()) then
				if (panel.pressed) then
					if (self.amount + 1 <= self.max and self:CanChange()) then
						self.amount = self.amount + 1
						self:OnChanged()
					end
				end

				panel.nextTick = CurTime() + 0.15
			end
		end
		self.plus.Paint = function() end

		self.label = self.content:Add("DLabel")
		self.label:SetText("")
		self.label:SetTextColor(color_white)
		self.label:SetContentAlignment(5)
		self.label:Dock(FILL)
		self.label:SetExpensiveShadow(1, color_black)
	end

	function PANEL:SetText(text)
		self.label:SetText(text)
	end

	function PANEL:SetMax(max)
		self.max = max
	end

	function PANEL:SetMin(min)
		self.min = min
	end

	function PANEL:SetValue(value)
		self.amount = value
	end

	function PANEL:GetValue()
		return self.amount
	end

	function PANEL:OnChanged()
	end

	function PANEL:CanChange()
		return true
	end
vgui.Register("nut_AttribBar", PANEL, "DPanel")
local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)

		self.amount = 0
		self.max = 10
		self.min = 0

		self.deltaWidth = 0

		local border = 3

		self.content = self:Add("DPanel")
		self.content:Dock(FILL)
		self.content.Paint = function(panel, w, h)
			surface.SetDrawColor(5, 5, 5, 40)
			surface.DrawRect(1, 1, w - 2, h - 2)

			if (self.max == 0) then
				self.max = 1
			end

			local newWidth = w * (self.amount / self.max)
				self.deltaWidth = math.Approach(self.deltaWidth, newWidth, FrameTime() * 500)
			local width = self.deltaWidth
			local change = 0

			if (newWidth != self.deltaWidth) then
				change = 20
			end

			local color = nut.config.mainColor

			surface.SetDrawColor(color.r + change, color.g + change, color.b + change, 225 + (change / 2))
			surface.DrawRect(1 + border, 1 + border, width - (2 + border*2), h - (2 + border*2))
		end

		self.label = self.content:Add("DLabel")
		self.label:SetText("")
		self.label:SetTextColor(color_black)
		self.label:SetContentAlignment(5)
		self.label:Dock(FILL)
		--self.label:SetExpensiveShadow(1, color_black)
	end

	function PANEL:SetText(text)
		self.label:SetText(text)
	end

	function PANEL:SetMax(max)
		self.max = max
	end

	function PANEL:SetMin(min)
		self.min = min
	end

	function PANEL:SetValue(value)
		self.amount = value
	end

	function PANEL:GetValue()
		return self.amount
	end

	function PANEL:OnChanged()
	end

	function PANEL:CanChange()
		return true
	end
vgui.Register("nut_AttribBarVisOnly", PANEL, "DPanel")