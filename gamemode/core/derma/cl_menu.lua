local PANEL = {}
	local gradient = nut.util.getMaterial("vgui/gradient-u")
	local gradient2 = nut.util.getMaterial("vgui/gradient-d")

	function PANEL:Init()
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:Remove()
		end

		nut.gui.menu = self

		self:SetSize(ScrW(), ScrH())
		self:ParentToHUD()
		self:SetAlpha(0)
		self:AlphaTo(255, 0.25, 0)
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.SetMaterial(gradient)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	function PANEL:remove()
		if (!self.closing) then
			self:AlphaTo(0, 0.25, 0, function()
				self:Remove()
			end)
			self.closing = true
		end
	end
vgui.Register("nutMenu", PANEL, "EditablePanel")

if (IsValid(nut.gui.menu)) then
	vgui.Create("nutMenu")
end