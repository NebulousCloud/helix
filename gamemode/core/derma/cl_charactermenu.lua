
-- base panel for the character menu
local PANEL = {}

function PANEL:Init()
	self.bClosing = false
end

function PANEL:SetClosing(bValue)
	self.bClosing = tobool(bValue)
end

function PANEL:IsClosing()
	return self.bClosing
end

vgui.Register("ixCharacterMenuBase", PANEL, "EditablePanel")
