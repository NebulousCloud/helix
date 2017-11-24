local PANEL = {}
	function PANEL:Init()
		self:SetDrawBackground(false)
	end

	function PANEL:SetMarkup(text, onDrawText)
		local object = ix.markup.parse(text, self:GetWide())
		object.onDrawText = onDrawText

		self:SetTall(object:GetHeight())
		self.Paint = function(this, w, h)
			object:draw(0, 0)
		end
	end
vgui.Register("ixMarkupPanel", PANEL, "DPanel")
