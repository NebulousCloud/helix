local PANEL = {}
local width = 64*5+10
local margin = 75

function PANEL:Init()
	--self:ParentToHUD()
	self:SetSize(width, 10)
	self:SetDrawBackground(false)

	hook.Run("CreateQuickMenu", self)
end

function PANEL:PerformLayout()
	--self:SetPos(margin, ScrH() - margin - self:GetTall())
	local tall = ScrH() - margin - self:GetTall()
	self:SetPos(margin, tall)
	local x, y = self:ChildrenSize()
	self:SetTall(y)
end

local gradient = surface.GetTextureID("vgui/gradient-r")

vgui.Register("nut_QuickMenu", PANEL, "DPanel")	

hook.Add("OnContextMenuOpen", "nut_QuickMenu", function()
	nut.gui.quickmenu = vgui.Create("nut_QuickMenu")
	nut.gui.quickmenu:MakePopup()
	gui.EnableScreenClicker(true)
end)

hook.Add("OnContextMenuClose", "nut_QuickMenu", function()
	if (nut.gui.quickmenu) then
		nut.gui.quickmenu:Remove()
	end
	gui.EnableScreenClicker(false)
end)