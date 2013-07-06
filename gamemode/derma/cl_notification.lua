local PANEL = {}
	function PANEL:Init()
		self:SetTall(48)
	end
vgui.Register("nut_Notification", PANEL, "DPanel")