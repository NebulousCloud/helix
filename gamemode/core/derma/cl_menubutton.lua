
local buttonPadding = ScreenScale(14) * 0.5
local animationTime = 0.5

-- base menu button
DEFINE_BASECLASS("DButton")
local PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha")

function PANEL:Init()
	self:SetFont("ixMenuButtonFont")
	self:SetTextColor(color_white)
	self:SetPaintBackground(false)
	self:SetContentAlignment(4)
	self:SetTextInset(buttonPadding, 0)

	self.padding = {32, 12, 32, 12} -- left, top, right, bottom
	self.backgroundColor = Color(0, 0, 0)
	self.backgroundAlpha = 128
	self.currentBackgroundAlpha = 0
end

function PANEL:GetPadding()
	return self.padding
end

function PANEL:SetPadding(left, top, right, bottom)
	self.padding = {
		left or self.padding[1],
		top or self.padding[2],
		right or self.padding[3],
		bottom or self.padding[4]
	}
end

function PANEL:SetText(text, noTranslation)
	BaseClass.SetText(self, noTranslation and text:utf8upper() or L(text):utf8upper())
end

function PANEL:SizeToContents()
	BaseClass.SizeToContents(self)

	local width, height = self:GetSize()
	self:SetSize(width + self.padding[1] + self.padding[3], height + self.padding[2] + self.padding[4])
end

function PANEL:PaintBackground(width, height)
	surface.SetDrawColor(ColorAlpha(self.backgroundColor, self.currentBackgroundAlpha))
	surface.DrawRect(0, 0, width, height)
end

function PANEL:Paint(width, height)
	self:PaintBackground(width, height)
	BaseClass.Paint(self, width, height)
end

function PANEL:SetTextColorInternal(color)
	BaseClass.SetTextColor(self, color)
	self:SetFGColor(color)
end

function PANEL:SetTextColor(color)
	self:SetTextColorInternal(color)
	self.color = color
end

function PANEL:SetDisabled(bValue)
	local color = self.color

	if (bValue) then
		self:SetTextColorInternal(Color(math.max(color.r - 60, 0), math.max(color.g - 60, 0), math.max(color.b - 60, 0)))
	else
		self:SetTextColorInternal(color)
	end

	BaseClass.SetDisabled(self, bValue)
end

function PANEL:OnCursorEntered()
	if (self:GetDisabled()) then
		return
	end

	local color = self:GetTextColor()
	self:SetTextColorInternal(Color(math.max(color.r - 25, 0), math.max(color.g - 25, 0), math.max(color.b - 25, 0)))

	self:CreateAnimation(0.15, {
		target = {currentBackgroundAlpha = self.backgroundAlpha}
	})

	LocalPlayer():EmitSound("Helix.Rollover")
end

function PANEL:OnCursorExited()
	if (self:GetDisabled()) then
		return
	end

	if (self.color) then
		self:SetTextColor(self.color)
	else
		self:SetTextColor(color_white)
	end

	self:CreateAnimation(0.15, {
		target = {currentBackgroundAlpha = 0}
	})
end

function PANEL:OnMousePressed(code)
	if (self:GetDisabled()) then
		return
	end

	if (self.color) then
		self:SetTextColor(self.color)
	else
		self:SetTextColor(ix.config.Get("color"))
	end

	LocalPlayer():EmitSound("Helix.Press")

	if (code == MOUSE_LEFT and self.DoClick) then
		self:DoClick(self)
	elseif (code == MOUSE_RIGHT and self.DoRightClick) then
		self:DoRightClick(self)
	end
end

function PANEL:OnMouseReleased(key)
	if (self:GetDisabled()) then
		return
	end

	if (self.color) then
		self:SetTextColor(self.color)
	else
		self:SetTextColor(color_white)
	end
end

vgui.Register("ixMenuButton", PANEL, "DButton")

-- selection menu button
DEFINE_BASECLASS("ixMenuButton")
PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "selected", "Selected", FORCE_BOOL)
AccessorFunc(PANEL, "buttonList", "ButtonList")

function PANEL:Init()
	self.backgroundColor = color_white
	self.selected = false
	self.buttonList = {}
	self.sectionPanel = nil -- sub-sections this button has; created only if it has any sections
end

function PANEL:PaintBackground(width, height)
	local alpha = self.selected and 255 or self.currentBackgroundAlpha

	derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, ColorAlpha(self.backgroundColor, alpha))
end

function PANEL:SetSelected(bValue, bSelectedSection)
	self.selected = bValue

	if (bValue) then
		self:OnSelected()

		if (self.sectionPanel) then
			self.sectionPanel:Show()
		elseif (self.sectionParent) then
			self.sectionParent.sectionPanel:Show()
		end
	elseif (self.sectionPanel and self.sectionPanel:IsVisible() and !bSelectedSection) then
		self.sectionPanel:Hide()
	end
end

function PANEL:SetButtonList(list, bNoAdd)
	if (!bNoAdd) then
		list[#list + 1] = self
	end

	self.buttonList = list
end

function PANEL:GetSectionPanel()
	return self.sectionPanel
end

function PANEL:AddSection(name)
	if (!IsValid(self.sectionPanel)) then
		-- add section panel to regular button list
		self.sectionPanel = vgui.Create("ixMenuSelectionList", self:GetParent())
		self.sectionPanel:Dock(self:GetDock())
		self.sectionPanel:SetParentButton(self)
	end

	return self.sectionPanel:AddButton(name, self.buttonList)
end

function PANEL:OnMousePressed(key)
	for _, v in pairs(self.buttonList) do
		if (IsValid(v) and v != self) then
			v:SetSelected(false, self.sectionParent == v)
		end
	end

	self:SetSelected(true)
	BaseClass.OnMousePressed(self, key)
end

function PANEL:OnSelected()
end

vgui.Register("ixMenuSelectionButton", PANEL, "ixMenuButton")

-- collapsable list for menu button sections
PANEL = {}
AccessorFunc(PANEL, "parent", "ParentButton")

function PANEL:Init()
	self.parent = nil -- button that is responsible for controlling this list
	self.height = 0
	self.targetHeight = 0

	self:DockPadding(0, 1, 0, 1)
	self:SetVisible(false)
	self:SetTall(0)
end

function PANEL:AddButton(name, buttonList)
	assert(IsValid(self.parent), "attempted to add button to ixMenuSelectionList without a ParentButton")
	assert(buttonList ~= nil, "attempted to add button to ixMenuSelectionList without a buttonList")

	local button = self:Add("ixMenuSelectionButton")
	button.sectionParent = self.parent
	button:SetTextInset(buttonPadding * 2, 0)
	button:SetPadding(nil, 8, nil, 8)
	button:SetFont("ixMenuButtonFontSmall")
	button:Dock(TOP)
	button:SetText(name)
	button:SizeToContents()
	button:SetButtonList(buttonList)
	button:SetBackgroundColor(self.parent:GetBackgroundColor())

	self.targetHeight = self.targetHeight + button:GetTall()
	return button
end

function PANEL:Show()
	self:SetVisible(true)

	self:CreateAnimation(animationTime, {
		index = 1,
		target = {
			height = self.targetHeight + 2 -- +2 for padding
		},
		easing = "outQuart",

		Think = function(animation, panel)
			panel:SetTall(panel.height)
		end
	})
end

function PANEL:Hide()
	self:CreateAnimation(animationTime, {
		index = 1,
		target = {
			height = 0
		},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetTall(panel.height)
		end,

		OnComplete = function(animation, panel)
			panel:SetVisible(false)
		end
	})
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(Color(255, 255, 255, 33))
	surface.DrawRect(0, 0, width, 1)
	surface.DrawRect(0, height - 1, width, 1)
end

vgui.Register("ixMenuSelectionList", PANEL, "Panel")
