
-- entity menu button
local PANEL = {}

AccessorFunc(PANEL, "callback", "Callback")

function PANEL:Init()
	self:SetTall(ScrH() * 0.1)
	self:Dock(TOP)
end

function PANEL:DoClick()
	local bStatus = true
	local parent = self:GetParent()
	local entity = parent:GetEntity()

	if (isfunction(self.callback)) then
		bStatus = self.callback()
	end

	if (bStatus != false and IsValid(entity)) then
		netstream.Start("ixEntityMenuSelect", entity, self:GetText())
	end

	parent:Remove()
end

vgui.Register("ixEntityMenuButton", PANEL, "DButton")

-- entity menu
DEFINE_BASECLASS("EditablePanel")
PANEL = {}

AccessorFunc(PANEL, "entity", "Entity")

function PANEL:Init()
	if (IsValid(ix.menu.panel)) then
		self:Remove()
		return
	end

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:DockPadding(64, 64, 64, 64)

	self.options = {}

	self:MakePopup()
	ix.menu.panel = self
end

function PANEL:SetOptions(options)
	for k, v in pairs(options) do
		local panel = self:Add("ixEntityMenuButton")
		panel:SetText(k)
		panel:SetCallback(v)

		self.options[#self.options + 1] = panel
	end
end

function PANEL:Paint(width, height)
	ix.util.DrawBlur(self, 10)
end

function PANEL:OnMousePressed(code)
	if (code == MOUSE_LEFT) then
		self:Remove()
	end
end

function PANEL:Remove()
	ix.menu.panel = nil
	BaseClass.Remove(self)
end

vgui.Register("ixEntityMenu", PANEL, "EditablePanel")
