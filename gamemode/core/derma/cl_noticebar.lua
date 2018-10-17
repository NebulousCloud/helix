
local PANEL = {
	types = {
		"Info", -- info
		"Success", -- success
		"Error" -- error
	}
}

AccessorFunc(PANEL, "type", "Type", FORCE_NUMBER)
AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)
AccessorFunc(PANEL, "length", "Length", FORCE_NUMBER)
AccessorFunc(PANEL, "hidden", "Hidden", FORCE_BOOL)

function PANEL:Init()
	self.type = 1
	self.padding = 8
	self.length = 4
	self.currentY = 0
	self.hidden = true

	self.text = self:Add("DLabel")
	self.text:SetFont("ixNoticeFont")
	self.text:SetContentAlignment(5)
	self.text:SetTextColor(color_white)
	self.text:SizeToContents()
	self.text:Dock(FILL)

	self:SetSize(self:GetParent():GetWide() - (self.padding * 4), self.text:GetTall() + (self.padding * 2))
	self:SetPos(self.padding * 2, -self:GetTall() - self.padding)
end

function PANEL:SetFont(value)
	self.text:SetFont(value)
	self.text:SizeToContents()
end

function PANEL:SetText(text)
	self.text:SetText(text)
	self.text:SizeToContents()
end

function PANEL:Slide(direction, length)
	direction = direction or "up"
	length = length or 0.5

	timer.Remove("ixNoticeBarAnimation")

	local x, _ = self:GetPos()
	local baseY = direction == "up" and self.padding * 2 or (-self:GetTall() - self.padding)
	local targetY = direction == "up" and (-self:GetTall() - self.padding) or self.padding * 2
	local easing = direction == "up" and "outQuint" or "outElastic"

	self:SetPos(x, baseY)
	self.currentY = baseY
	self.hidden = direction == "up"

	self:CreateAnimation(length, {
		target = {currentY = targetY},
		easing = easing,

		Think = function(animation, panel)
			local lastX, _ = panel:GetPos()
			panel:SetPos(lastX, panel.currentY)
		end
	})
end

function PANEL:Show(bRemove)
	self:Slide("down")

	timer.Create("ixNoticeBarAnimation", self.length - 0.5, 1, function()
		if (!IsValid(self)) then
			return
		end

		self:Slide("up")
	end)
end

function PANEL:Paint(width, height)
	local color = derma.GetColor(self.types[self.type], self)

	surface.SetDrawColor(color)
	surface.DrawRect(0, 0, width, height)
end

vgui.Register("ixNoticeBar", PANEL, "Panel")
