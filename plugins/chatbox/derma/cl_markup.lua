local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)
	end

	function PANEL:setMarkup(text, onDrawText)
		local object = nut.markup.parse(text, self:GetWide())
		object.onDrawText = onDrawText

		self:SetTall(object:getHeight())
		self.Paint = function(this, w, h)
			object:draw(0, 0)
		end
	end
vgui.Register("nutMarkupPanel", PANEL, "DPanel")