
DEFINE_BASECLASS("EditablePanel")

local PANEL = {}
local gradient = ix.util.GetMaterial("vgui/gradient-u")
local alpha = 80

function PANEL:Init()
	if (IsValid(ix.gui.menu)) then
		ix.gui.menu:Remove()
	end

	ix.gui.menu = self

	self:SetSize(ScrW(), ScrH())
	self:SetAlpha(0)
	self:AlphaTo(255, 0.25, 0)
	self:SetPopupStayAtBack(true)

	self.tabs = self:Add("DHorizontalScroller")
	self.tabs:SetWide(0)
	self.tabs:SetTall(86)

	self.panel = self:Add("EditablePanel")
	self.panel:SetSize(ScrW() * 0.6, ScrH() * 0.65)
	self.panel:Center()
	self.panel:SetPos(self.panel.x, self.panel.y + 72)
	self.panel:SetAlpha(0)

	self.title = self:Add("DLabel")
	self.title:SetPos(self.panel.x, self.panel.y - 80)
	self.title:SetTextColor(color_white)
	self.title:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self.title:SetFont("ixTitleFont")
	self.title:SetText("")
	self.title:SetAlpha(0)
	self.title:SetSize(self.panel:GetWide(), 72)

	local tabs = {}

	hook.Run("CreateMenuButtons", tabs)

	self.tabList = {}

	for name, callback in SortedPairs(tabs) do
		if (type(callback) == "string") then
			local body = callback

			if (body:sub(1, 4) == "http") then
				callback = function(panel)
					local html = panel:Add("DHTML")
					html:Dock(FILL)
					html:OpenURL(body)
				end
			else
				callback = function(panel)
					local html = panel:Add("DHTML")
					html:Dock(FILL)
					html:SetHTML(body)
				end
			end
		end

		local tab = self:AddTab(L(name), callback, name)
		self.tabList[name] = tab
	end

	self.noAnchor = CurTime() + .4
	self.anchorMode = true
	self:MakePopup()

	if (self.tabList[ix.gui.lastMenuTab]) then
		self:SetActiveTab(ix.gui.lastMenuTab)
	else
		self:SetActiveTab("you")
	end
end

function PANEL:OnKeyCodePressed(key)
	self.noAnchor = CurTime() + .5

	if (key == KEY_TAB) then
		self:Remove()
	end
end

function PANEL:Think()
	local key = input.IsKeyDown(KEY_TAB)

	if (key and (self.noAnchor or CurTime() + .4) < CurTime() and self.anchorMode == true) then
		self.anchorMode = false
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	if (!self.anchorMode) then
		if (IsValid(self.info) and self.info.description:IsEditing()) then
			return
		end

		if (!key) then
			self:Remove()
		end
	end

	if (gui.IsGameUIVisible()) then
		self:Remove()
	end
end

local color_bright = Color(240, 240, 240, 180)

function PANEL:Paint(w, h)
	ix.util.DrawBlur(self, 12)

	surface.SetDrawColor(0, 0, 0)
	surface.SetMaterial(gradient)
	surface.DrawTexturedRect(0, 0, w, h)

	surface.SetDrawColor(30, 30, 30, alpha)
	surface.DrawRect(0, 0, w, 78)

	surface.SetDrawColor(color_bright)
	surface.DrawRect(0, 78, w, 8)
end

function PANEL:AddTab(name, callback, uniqueID)
	name = L(name)

	local function PaintTab(tab, w, h)
		if (self.activeTab == tab) then
			surface.SetDrawColor(ColorAlpha(ix.config.Get("color"), 200))
			surface.DrawRect(0, h - 8, w, 8)
		elseif (tab.Hovered) then
			surface.SetDrawColor(0, 0, 0, 50)
			surface.DrawRect(0, h - 8, w, 8)
		end
	end

	surface.SetFont("ixMenuButtonLightFont")
	local w = surface.GetTextSize(name)

	local tab = self.tabs:Add("DButton")
		tab:SetSize(0, self.tabs:GetTall())
		tab:SetText(name)
		tab:SetPos(self.tabs:GetWide(), 0)
		tab:SetTextColor(Color(250, 250, 250))
		tab:SetFont("ixMenuButtonLightFont")
		tab:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		tab:SizeToContentsX()
		tab:SetWide(w + 32)
		tab.Paint = PaintTab
		tab.DoClick = function(this)
			if (IsValid(ix.gui.info)) then
				ix.gui.info:Remove()
			end

			self.panel:Clear()

			self.title:SetVisible(true)
			self.title:SetText(this:GetText())
			self.title:SizeToContentsY()
			self.title:AlphaTo(255, 0.5)
			self.title:MoveAbove(self.panel, 8)

			self.panel:AlphaTo(255, 0.5, 0.1)
			self.activeTab = this

			if (uniqueID != "Characters") then
				ix.gui.lastMenuTab = uniqueID
			end

			if (callback) then
				callback(self.panel, this, self)
			end
		end
	self.tabs:AddPanel(tab)

	self.tabs:SetWide(math.min(self.tabs:GetWide() + tab:GetWide(), ScrW()))
	self.tabs:SetPos((ScrW() * 0.5) - (self.tabs:GetWide() * 0.5), 0)

	return tab
end

function PANEL:SetActiveTab(key)
	if (IsValid(self.tabList[key])) then
		self.tabList[key]:DoClick()
	end
end

function PANEL:OnRemove()
end

function PANEL:Remove()
	CloseDermaMenus()

	if (!self.closing) then
		self:AlphaTo(0, 0.25, 0, function()
			BaseClass.Remove(self)
		end)
		self.closing = true
	end
end

vgui.Register("ixMenu", PANEL, "EditablePanel")

if (IsValid(ix.gui.menu)) then
	vgui.Create("ixMenu")
end

ix.gui.lastMenuTab = nil
