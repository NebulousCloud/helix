
local animationTime = 1
local matrixZScale = Vector(1, 1, 0.0001)

DEFINE_BASECLASS("ixSubpanelParent")
local PANEL = {}

AccessorFunc(PANEL, "bCharacterOverview", "CharacterOverview", FORCE_BOOL)

function PANEL:Init()
	if (IsValid(ix.gui.menu)) then
		ix.gui.menu:Remove()
	end

	ix.gui.menu = self

	-- properties
	self.manualChildren = {}
	self.noAnchor = CurTime() + 0.4
	self.anchorMode = true
	self.rotationOffset = Angle(0, 180, 0)
	self.projectedTexturePosition = Vector(0, 0, 6)
	self.projectedTextureRotation = Angle(-45, 60, 0)

	self.bCharacterOverview = false
	self.bOverviewOut = false
	self.overviewFraction = 0

	self.currentAlpha = 0
	self.currentBlur = 0

	-- setup
	self:SetPadding(ScreenScale(16), true)
	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetLeftOffset(self:GetWide() * 0.25 + self:GetPadding())

	-- main button panel
	self.buttons = self:Add("Panel")
	self.buttons:SetSize(self:GetWide() * 0.25, self:GetTall() - self:GetPadding() * 2)
	self.buttons:Dock(LEFT)
	self.buttons:SetPaintedManually(true)

	local close = self.buttons:Add("ixMenuButton")
	close:SetText("return")
	close:SizeToContents()
	close:Dock(BOTTOM)
	close.DoClick = function()
		self:Remove()
	end

	local characters = self.buttons:Add("ixMenuButton")
	characters:SetText("characters")
	characters:SizeToContents()
	characters:Dock(BOTTOM)
	characters.DoClick = function()
		self:Remove()
		vgui.Create("ixCharMenu")
	end

	-- @todo make a better way to avoid clicks in the padding PLEASE
	self.guard = self:Add("Panel")
	self.guard:SetPos(0, 0)
	self.guard:SetSize(self:GetPadding(), self:GetTall())

	-- tabs
	self.tabs = self.buttons:Add("Panel")
	self.tabs.buttons = {}
	self.tabs:Dock(FILL)
	self:PopulateTabs()

	self:MakePopup()
	self:OnOpened()
end

function PANEL:OnOpened()
	self:SetAlpha(0)

	self:CreateAnimation(animationTime, {
		target = {currentAlpha = 255},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.currentAlpha)
		end
	})
end

function PANEL:GetActiveTab()
	return (self:GetActiveSubpanel() or {}).subpanelName
end

function PANEL:TransitionSubpanel(id)
	local lastSubpanel = self:GetActiveSubpanel()

	-- don't transition to the same panel
	if (IsValid(lastSubpanel) and lastSubpanel.subpanelID == id) then
		return
	end

	local subpanel = self:GetSubpanel(id)

	if (IsValid(subpanel)) then
		if (!subpanel.bPopulated) then
			-- we need to set the size of the subpanel if it's a section since it will be 0, 0
			if (subpanel.sectionParent) then
				subpanel:SetSize(self:GetStandardSubpanelSize())
			end

			local info = subpanel.info
			subpanel.Paint = nil

			if (istable(info) and info.Create) then
				info:Create(subpanel)
			elseif (isfunction(info)) then
				info(subpanel)
			end

			hook.Run("MenuSubpanelCreated", subpanel.subpanelName, subpanel)
			subpanel.bPopulated = true
		end

		-- only play whoosh sound only when the menu was already open
		if (IsValid(lastSubpanel)) then
			LocalPlayer():EmitSound("Helix.Whoosh")
		end

		self:SetActiveSubpanel(id)
	end

	subpanel = self:GetActiveSubpanel()

	local info = subpanel.info
	local bHideBackground = istable(info) and (info.bHideBackground != nil and info.bHideBackground or false) or false

	if (bHideBackground) then
		self:HideBackground()
	else
		self:ShowBackground()
	end

	-- call hooks if we've changed subpanel
	if (IsValid(lastSubpanel) and istable(lastSubpanel.info) and lastSubpanel.info.OnDeselected) then
		lastSubpanel.info:OnDeselected(lastSubpanel)
	end

	if (IsValid(subpanel) and istable(subpanel.info) and subpanel.info.OnSelected) then
		subpanel.info:OnSelected(subpanel)
	end

	ix.gui.lastMenuTab = id
end

function PANEL:SetCharacterOverview(bValue, length)
	bValue = tobool(bValue)
	length = length or animationTime

	if (bValue) then
		if (!IsValid(self.projectedTexture)) then
			self.projectedTexture = ProjectedTexture()
		end

		local faction = ix.faction.indices[LocalPlayer():Team()]
		local color = faction and faction.color or color_white

		self.projectedTexture:SetEnableShadows(false)
		self.projectedTexture:SetNearZ(12)
		self.projectedTexture:SetFarZ(64)
		self.projectedTexture:SetFOV(90)
		self.projectedTexture:SetColor(color)
		self.projectedTexture:SetTexture("effects/flashlight/soft")

		self:CreateAnimation(length, {
			index = 3,
			target = {overviewFraction = 1},
			easing = "outQuint",
			bIgnoreConfig = true
		})

		self.bOverviewOut = false
		self.bCharacterOverview = true
	else
		self:CreateAnimation(length, {
			index = 3,
			target = {overviewFraction = 0},
			easing = "outQuint",
			bIgnoreConfig = true,

			OnComplete = function(animation, panel)
				panel.bCharacterOverview = false

				if (IsValid(panel.projectedTexture)) then
					panel.projectedTexture:Remove()
				end
			end
		})

		self.bOverviewOut = true
	end
end

function PANEL:GetOverviewInfo(origin, angles, fov)
	local originAngles = Angle(0, angles.yaw, angles.roll)
	local target = LocalPlayer():GetObserverTarget()
	local fraction = self.overviewFraction
	local bDrawPlayer = ((fraction > 0.2) or (!self.bOverviewOut and (fraction > 0.2))) and !IsValid(target)
	local forward = originAngles:Forward() * 58 - originAngles:Right() * 16
	forward.z = 0

	local newOrigin

	if (IsValid(target)) then
		newOrigin = target:GetPos() + forward
	else
		newOrigin = origin - LocalPlayer():OBBCenter() * 0.6 + forward
	end

	local newAngles = originAngles + self.rotationOffset
	newAngles.pitch = 5
	newAngles.roll = 0

	return LerpVector(fraction, origin, newOrigin), LerpAngle(fraction, angles, newAngles), Lerp(fraction, fov, 90), bDrawPlayer
end

function PANEL:HideBackground()
	self:CreateAnimation(animationTime, {
		index = 2,
		target = {currentBlur = 0},
		easing = "outQuint"
	})
end

function PANEL:ShowBackground()
	self:CreateAnimation(animationTime, {
		index = 2,
		target = {currentBlur = 1},
		easing = "outQuint"
	})
end

function PANEL:GetStandardSubpanelSize()
	return ScrW() * 0.75 - self:GetPadding() * 3, ScrH() - self:GetPadding() * 2
end

function PANEL:SetupTab(name, info, sectionParent)
	local bTable = istable(info)
	local buttonColor = (bTable and info.buttonColor) or (ix.config.Get("color") or Color(140, 140, 140, 255))
	local bDefault = (bTable and info.bDefault) or false
	local qualifiedName = sectionParent and (sectionParent.name .. "/" .. name) or name

	-- setup subpanels without populating them so we can retain the order
	local subpanel = self:AddSubpanel(qualifiedName, true)
	local id = subpanel.subpanelID
	subpanel.info = info
	subpanel.sectionParent = sectionParent and qualifiedName
	subpanel:SetPaintedManually(true)
	subpanel:SetTitle(nil)

	if (sectionParent) then
		-- hide section subpanels if they haven't been populated to seeing more subpanels than necessary
		-- fly by as you navigate tabs in the menu
		subpanel:SetSize(0, 0)
	else
		subpanel:SetSize(self:GetStandardSubpanelSize())

		-- this is called while the subpanel has not been populated
		subpanel.Paint = function(panel, width, height)
			derma.SkinFunc("PaintPlaceholderPanel", panel, width, height)
		end
	end

	local button

	if (sectionParent) then
		button = sectionParent:AddSection(L(name))
		name = qualifiedName
	else
		button = self.tabs:Add("ixMenuSelectionButton")
		button:SetText(L(name))
		button:SizeToContents()
		button:Dock(TOP)
		button:SetButtonList(self.tabs.buttons)
		button:SetBackgroundColor(buttonColor)
	end

	button.name = name
	button.id = id
	button.OnSelected = function()
		self:TransitionSubpanel(id)
	end

	if (bTable and info.PopulateTabButton) then
		info:PopulateTabButton(button)
	end

	-- don't allow sections in sections
	if (sectionParent or !bTable or !info.Sections) then
		return bDefault, button, subpanel
	end

	-- create button sections
	for sectionName, sectionInfo in pairs(info.Sections) do
		self:SetupTab(sectionName, sectionInfo, button)
	end

	return bDefault, button, subpanel
end

function PANEL:PopulateTabs()
	local default
	local tabs = {}

	hook.Run("CreateMenuButtons", tabs)

	for name, info in SortedPairs(tabs) do
		local bDefault, button = self:SetupTab(name, info)

		if (bDefault) then
			default = button
		end
	end

	if (ix.gui.lastMenuTab) then
		for i = 1, #self.tabs.buttons do
			local button = self.tabs.buttons[i]

			if (button.id == ix.gui.lastMenuTab) then
				default = button
				break
			end
		end
	end

	if (!IsValid(default) and #self.tabs.buttons > 0) then
		default = self.tabs.buttons[1]
	end

	if (IsValid(default)) then
		default:SetSelected(true)
		self:SetActiveSubpanel(default.id, 0)
	end

	self.buttons:MoveToFront()
	self.guard:MoveToBefore(self.buttons)
end

function PANEL:AddManuallyPaintedChild(panel)
	panel:SetParent(self)
	panel:SetPaintedManually(panel)

	self.manualChildren[#self.manualChildren + 1] = panel
end

function PANEL:OnKeyCodePressed(key)
	self.noAnchor = CurTime() + 0.5

	if (key == KEY_TAB) then
		self:Remove()
	end
end

function PANEL:Think()
	if (IsValid(self.projectedTexture)) then
		local forward = LocalPlayer():GetForward()
		forward.z = 0

		local right = LocalPlayer():GetRight()
		right.z = 0

		self.projectedTexture:SetBrightness(self.overviewFraction * 4)
		self.projectedTexture:SetPos(LocalPlayer():GetPos() + right * 16 - forward * 8 + self.projectedTexturePosition)
		self.projectedTexture:SetAngles(forward:Angle() + self.projectedTextureRotation)
		self.projectedTexture:Update()
	end

	if (self.bClosing) then
		return
	end

	local bTabDown = input.IsKeyDown(KEY_TAB)

	if (bTabDown and (self.noAnchor or CurTime() + 0.4) < CurTime() and self.anchorMode) then
		self.anchorMode = false
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	if ((!self.anchorMode and !bTabDown) or gui.IsGameUIVisible()) then
		self:Remove()
	end
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintMenuBackground", self, width, height, self.currentBlur)

	local bShouldScale = self.currentAlpha != 255

	if (bShouldScale) then
		local currentScale = Lerp(self.currentAlpha / 255, 0.9, 1)
		local matrix = Matrix()

		matrix:Scale(matrixZScale * currentScale)
		matrix:Translate(Vector(
			ScrW() * 0.5 - (ScrW() * currentScale * 0.5),
			ScrH() * 0.5 - (ScrH() * currentScale * 0.5),
			1
		))

		cam.PushModelMatrix(matrix)
	end

	BaseClass.Paint(self, width, height)
	self:PaintSubpanels(width, height)
	self.buttons:PaintManual()

	for i = 1, #self.manualChildren do
		self.manualChildren[i]:PaintManual()
	end

	if (IsValid(ix.gui.inv1) and ix.gui.inv1.childPanels) then
		for i = 1, #ix.gui.inv1.childPanels do
			local panel = ix.gui.inv1.childPanels[i]

			if (IsValid(panel)) then
				panel:PaintManual()
			end
		end
	end

	if (bShouldScale) then
		cam.PopModelMatrix()
	end
end

function PANEL:PerformLayout()
	self.guard:SetSize(self.tabs:GetWide() + self:GetPadding() * 2, self:GetTall())
end

function PANEL:Remove()
	self.bClosing = true
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	self:SetCharacterOverview(false, animationTime * 0.5)

	-- remove input from opened child panels since they grab focus
	if (IsValid(ix.gui.inv1) and ix.gui.inv1.childPanels) then
		for i = 1, #ix.gui.inv1.childPanels do
			local panel = ix.gui.inv1.childPanels[i]

			if (IsValid(panel)) then
				panel:SetMouseInputEnabled(false)
				panel:SetKeyboardInputEnabled(false)
			end
		end
	end

	CloseDermaMenus()
	gui.EnableScreenClicker(false)

	self:CreateAnimation(animationTime * 0.5, {
		index = 2,
		target = {currentBlur = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(animationTime * 0.5, {
		target = {currentAlpha = 0},
		easing = "outQuint",

		-- we don't animate the blur because blurring doesn't draw things
		-- with amount < 1 very well, resulting in jarring transition
		Think = function(animation, panel)
			panel:SetAlpha(panel.currentAlpha)
		end,

		OnComplete = function(animation, panel)
			if (IsValid(panel.projectedTexture)) then
				panel.projectedTexture:Remove()
			end

			BaseClass.Remove(panel)
		end
	})
end

vgui.Register("ixMenu", PANEL, "ixSubpanelParent")

if (IsValid(ix.gui.menu)) then
	ix.gui.menu:Remove()
end

ix.gui.lastMenuTab = nil
