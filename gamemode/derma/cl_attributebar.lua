local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)

		self.amount = 0
		self.max = 10
		self.min = 0

		self.deltaWidth = 0

		self.minus = self:Add("DButton")
		self.minus:Dock(LEFT)
		self.minus:SetText("-")
		self.minus:SetSize(24, 24)
		self.minus.Paint = function(panel, w, h)
			surface.SetDrawColor(255, 255, 255, 200)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
		self.minus.DoClick =  function(panel, w, h)
			if (self.amount - 1 >= self.min and self:CanChange(true)) then
				self.amount = self.amount - 1
				self:OnChanged(true)
			end
		end

		local border = 3

		self.content = self:Add("DPanel")
		self.content:Dock(FILL)
		self.content.Paint = function(panel, w, h)
			surface.SetDrawColor(255, 255, 255, 100)
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
		self.plus:SetText("+")
		self.plus:SetSize(24, 24)
		self.plus.Paint = function(panel, w, h)
			surface.SetDrawColor(255, 255, 255, 200)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
		self.plus.DoClick = function(panel)
			if (self.amount + 1 <= self.max and self:CanChange()) then
				self.amount = self.amount + 1
				self:OnChanged()
			end
		end

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

concommand.Add("test_bar", function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() * 0.5, ScrH() * 0.7)
	frame:MakePopup()
	frame:Center()

	for i = 1, 10 do
		local bar = frame:Add("nut_AttribBar")
		bar:Dock(TOP)
		bar:SetToolTip("Affects "..i)
	end
end)