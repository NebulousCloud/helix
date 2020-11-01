
-- overrides standard derma panels to add/change functionality

local PANEL = {}
local OVERRIDES = {}

-- @todo remove me when autorefresh support is no longer needed
local function OverridePanel(name, func)
	PANEL = vgui.GetControlTable(name)

	if (!istable(PANEL)) then
		return
	end

	OVERRIDES = {}
	func()

	for k, _ in pairs(PANEL) do
		local overrideName = "ix" .. k

		if (PANEL[overrideName] and !OVERRIDES[k]) then
			print("unhooking override ", overrideName)

			PANEL[k] = PANEL[overrideName]
			PANEL[overrideName] = nil
		end
	end
end

local function Override(name)
	local oldMethod = "ix" .. name
	OVERRIDES[name] = true

	if (PANEL[oldMethod]) then
		return
	end

	PANEL[oldMethod] = PANEL[name]
end

OverridePanel("DMenuOption", function()
	function PANEL:PerformLayout()
		self:SizeToContents()
		self:SetWide(self:GetWide() + 30)

		local w = math.max(self:GetParent():GetWide(), self:GetWide())

		self:SetSize(w, self:GetTall() + 4)

		if (self.SubMenuArrow) then
			self.SubMenuArrow:SetSize(15, 15)
			self.SubMenuArrow:CenterVertical()
			self.SubMenuArrow:AlignRight(4)
		end

		DButton.PerformLayout(self)
	end
end)

OverridePanel("DMenu", function()
	local animationTime = 0.33

	Override("Init")
	function PANEL:Init(...)
		self:ixInit(...)

		self.ixAnimation = 0
	end

	function PANEL:SetFont(font)
		for _, v in pairs(self:GetCanvas():GetChildren()) do
			v:SetFont(font)
			v:SizeToContents()
		end

		-- reposition for the new font
		self:InvalidateLayout(true)
		self:Open(self.ixX, self.ixY, false, self.ixOwnerPanel)
	end

	Override("SetSize")
	function PANEL:SetSize(width, height)
		self:ixSetSize(width, height)
		self.ixTargetHeight = height
	end

	Override("PerformLayout")
	function PANEL:PerformLayout(...)
		self:ixPerformLayout(...)

		if (self.ixAnimating) then
			self.VBar:SetAlpha(0) -- setvisible doesn't seem to work here
			self:SetTall(self.ixAnimation * self.ixTargetHeight)
		else
			self.VBar:SetAlpha(255)
		end
	end

	Override("OnMouseWheeled")
	function PANEL:OnMouseWheeled(delta)
		self:ixOnMouseWheeled(delta)

		-- don't allow the input event to fall through
		return true
	end

	Override("AddOption")
	function PANEL:AddOption(...)
		local panel = self:ixAddOption(...)

		panel:SetTextColor(derma.GetColor("MenuLabel", self, color_black))
		panel:SetTextInset(6, 0) -- there is no icon functionality in DComboBoxes

		return panel
	end

	Override("AddSubMenu")
	function PANEL:AddSubMenu(...)
		local menu, panel = self:ixAddSubMenu(...)

		panel:SetTextColor(derma.GetColor("MenuLabel", self, color_black))
		panel:SetTextInset(6, 0) -- there is no icon functionality in DComboBoxes

		return menu, panel
	end

	Override("Open")
	function PANEL:Open(x, y, bSkipAnimation, ownerPanel)
		self.ixX, self.ixY, self.ixOwnerPanel = x, y, ownerPanel
		self:ixOpen(x, y, bSkipAnimation, ownerPanel)

		if (ix.option.Get("disableAnimations")) then
			return
		end

		-- remove pac3 derma menu hooks since animations don't play nicely
		hook.Remove("CloseDermaMenus", self)
		hook.Remove("Think", self)

		self.ixAnimating = true
		self:CreateAnimation(animationTime, {
			index = 1,
			target = {ixAnimation = 1},
			easing = "outQuint",

			Think = function(animation, panel)
				panel:InvalidateLayout(true)
			end,

			OnComplete = function(animation, panel)
				panel.ixAnimating = nil
			end
		})
	end

	Override("Hide")
	function PANEL:Hide()
		if (ix.option.Get("disableAnimations")) then
			self:ixHide()
			return
		end

		self.ixAnimating = true
		self:SetVisible(true)
		self:CreateAnimation(animationTime * 0.5, {
			index = 1,
			target = {ixAnimation = 0},
			easing = "outQuint",

			Think = function(animation, panel)
				panel:InvalidateLayout(true)
			end,

			OnComplete = function(animation, panel)
				panel.ixAnimating = false
				panel:ixHide()
			end
		})
	end

	Override("Remove")
	function PANEL:Remove()
		if (self.ixRemoving) then
			return
		end

		if (ix.option.Get("disableAnimations")) then
			self:ixRemove()
			return
		end

		self.ixAnimating = true
		self.ixRemoving = true
		self:SetVisible(true)

		self:CreateAnimation(animationTime * 0.5, {
			index = 1,
			target = {ixAnimation = 0},
			easing = "outQuint",

			Think = function(animation, panel)
				panel:InvalidateLayout(true)
			end,

			OnComplete = function(animation, panel)
				panel:ixRemove()
			end
		})
	end
end)

OverridePanel("DComboBox", function()
	Override("OpenMenu")
	function PANEL:OpenMenu()
		self:ixOpenMenu()

		if (IsValid(self.Menu)) then
			local _, y = self.Menu:LocalToScreen(self.Menu:GetPos())

			self.Menu:SetFont(self:GetFont())
			self.Menu:SetMaxHeight(ScrH() - y)
		end
	end
end)

OverridePanel("DScrollPanel", function()
	Override("ScrollToChild")
	function PANEL:ScrollToChild(panel)
		-- docked panels required InvalidateParent in order to retrieve their position correctly
		if (panel:GetDock() != NODOCK) then
			panel:InvalidateParent(true)
		else
			self:PerformLayout()
		end

		local _, y = self.pnlCanvas:GetChildPosition(panel)

		y = y + panel:GetTall() * 0.5
		y = y - self:GetTall() * 0.5

		self.VBar:SetScroll(y)
	end
end)
