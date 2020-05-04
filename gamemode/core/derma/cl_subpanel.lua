
local DEFAULT_PADDING = ScreenScale(32)
local DEFAULT_ANIMATION_TIME = 1
local DEFAULT_SUBPANEL_ANIMATION_TIME = 0.5

-- parent subpanel
local PANEL = {}

function PANEL:Init()
	local parent = self:GetParent()
	local padding = parent.GetPadding and parent:GetPadding() or DEFAULT_PADDING

	self:SetSize(parent:GetWide() - (padding * 2), parent:GetTall() - (padding * 2))
	self:Center()
end

function PANEL:SetTitle(text, bNoTranslation, bNoUpper)
	if (text == nil) then
		if (IsValid(self.title)) then
			self.title:Remove()
		end

		return
	elseif (!IsValid(self.title)) then
		self.title = self:Add("DLabel")
		self.title:SetFont("ixTitleFont")
		self.title:SizeToContents()
		self.title:SetTextColor(ix.config.Get("color") or color_white)
		self.title:Dock(TOP)
	end

	local newText = bNoTranslation and text or L(text)
	newText = bNoUpper and newText or newText:utf8upper()

	self.title:SetText(newText)
	self.title:SizeToContents()
end

function PANEL:SetLeftPanel(panel)
	self.left = panel
end

function PANEL:GetLeftPanel()
	return self.left
end

function PANEL:SetRightPanel(panel)
	self.right = panel
end

function PANEL:GetRightPanel()
	return self.right
end

function PANEL:OnSetActive()
end

vgui.Register("ixSubpanel", PANEL, "EditablePanel")

-- subpanel parent
DEFINE_BASECLASS("EditablePanel")
PANEL = {}

AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "subpanelAnimationTime", "SubpanelAnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "leftOffset", "LeftOffset", FORCE_NUMBER)

function PANEL:Init()
	self.subpanels = {}
	self.childPanels = {}

	self.currentSubpanelX = DEFAULT_PADDING
	self.targetSubpanelX = DEFAULT_PADDING
	self.padding = DEFAULT_PADDING
	self.leftOffset = 0

	self.animationTime = DEFAULT_ANIMATION_TIME
	self.subpanelAnimationTime = DEFAULT_SUBPANEL_ANIMATION_TIME
end

function PANEL:SetPadding(amount, bSetDockPadding)
	self.currentSubpanelX = amount
	self.targetSubpanelX = amount
	self.padding = amount

	if (bSetDockPadding) then
		self:DockPadding(amount, amount, amount, amount)
	end
end

function PANEL:Add(name)
	local panel = BaseClass.Add(self, name)

	if (panel.SetPaintedManually) then
		panel:SetPaintedManually(true)
		self.childPanels[#self.childPanels + 1] = panel
	end

	return panel
end

function PANEL:AddSubpanel(name)
	local id = #self.subpanels + 1
	local panel = BaseClass.Add(self, "ixSubpanel")
	panel.subpanelName = name
	panel.subpanelID = id
	panel:SetTitle(name)

	self.subpanels[id] = panel
	self:SetupSubpanelReferences()

	return panel
end

function PANEL:SetupSubpanelReferences()
	local lastPanel

	for i = 1, #self.subpanels do
		local panel = self.subpanels[i]
		local nextPanel = self.subpanels[i + 1]

		if (IsValid(lastPanel)) then
			lastPanel:SetRightPanel(panel)
			panel:SetLeftPanel(lastPanel)
		end

		if (IsValid(nextPanel)) then
			panel:SetRightPanel(nextPanel)
		end

		lastPanel = panel
	end
end

function PANEL:SetSubpanelPos(id, x)
	local currentPanel = self.subpanels[id]

	if (!currentPanel) then
		return
	end

	local _, oldY = currentPanel:GetPos()
	currentPanel:SetPos(x, oldY)

	-- traverse left
	while (IsValid(currentPanel)) do
		local left = currentPanel:GetLeftPanel()

		if (IsValid(left)) then
			left:MoveLeftOf(currentPanel, self.padding + self.leftOffset)
		end

		currentPanel = left
	end

	currentPanel = self.subpanels[id]

	-- traverse right
	while (IsValid(currentPanel)) do
		local right = currentPanel:GetRightPanel()

		if (IsValid(right)) then
			right:MoveRightOf(currentPanel, self.padding)
		end

		currentPanel = right
	end
end

function PANEL:SetActiveSubpanel(id, length)
	if (isstring(id)) then
		for i = 1, #self.subpanels do
			if (self.subpanels[i].subpanelName == id) then
				id = i
				break
			end
		end
	end

	local activePanel = self.subpanels[id]

	if (!activePanel) then
		return false
	end

	if (length == 0 or !self.activeSubpanel) then
		self:SetSubpanelPos(id, self.padding + self.leftOffset)
	else
		local x, _ = activePanel:GetPos()
		local target = self.targetSubpanelX + self.leftOffset
		self.currentSubpanelX = x + self.padding + self.leftOffset

		self:CreateAnimation(length or self.subpanelAnimationTime, {
			index = 420,
			target = {currentSubpanelX = target},
			easing = "outQuint",

			Think = function(animation, panel)
				panel:SetSubpanelPos(id, panel.currentSubpanelX)
			end,

			OnComplete = function(animation, panel)
				panel:SetSubpanelPos(id, target)
			end
		})
	end

	self.activeSubpanel = id
	activePanel:OnSetActive()

	return true
end

function PANEL:GetSubpanel(id)
	return self.subpanels[id]
end

function PANEL:GetActiveSubpanel()
	return self.subpanels[self.activeSubpanel]
end

function PANEL:GetActiveSubpanelID()
	return self.activeSubpanel
end

function PANEL:Slide(direction, length, callback, bIgnoreConfig)
	local _, height = self:GetParent():GetSize()
	local x, _ = self:GetPos()
	local targetY = direction == "up" and 0 or height

	self:SetVisible(true)

	if (length == 0) then
		self:SetPos(x, targetY)
	else
		length = length or self.animationTime
		self.currentY = direction == "up" and height or 0

		self:CreateAnimation(length or self.animationTime, {
			index = -1,
			target = {currentY = targetY},
			easing = "outExpo",
			bIgnoreConfig = bIgnoreConfig,

			Think = function(animation, panel)
				local currentX, _ = panel:GetPos()

				panel:SetPos(currentX, panel.currentY)
			end,

			OnComplete = function(animation, panel)
				if (direction == "down") then
					panel:SetVisible(false)
				end

				if (callback) then
					callback(panel)
				end
			end
		})
	end
end

function PANEL:SlideUp(...)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	self:OnSlideUp()
	self:Slide("up", ...)
end

function PANEL:SlideDown(...)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)

	self:OnSlideDown()
	self:Slide("down", ...)
end

function PANEL:OnSlideUp()
end

function PANEL:OnSlideDown()
end

function PANEL:Paint(width, height)
	for i = 1, #self.childPanels do
		self.childPanels[i]:PaintManual()
	end
end

function PANEL:PaintSubpanels(width, height)
	for i = 1, #self.subpanels do
		self.subpanels[i]:PaintManual()
	end
end

-- ????
PANEL.Remove = BaseClass.Remove

vgui.Register("ixSubpanelParent", PANEL, "EditablePanel")
