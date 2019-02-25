
local animationTime = 1

-- panel meta
do
	local PANEL = FindMetaTable("Panel")
	local ixChangeTooltip = ChangeTooltip
	local ixRemoveTooltip = RemoveTooltip
	local tooltip
	local lastHover

	function PANEL:SetHelixTooltip(callback)
		self:SetMouseInputEnabled(true)
		self.ixTooltip = callback
	end

	function ChangeTooltip(panel, ...) -- luacheck: globals ChangeTooltip
		if (!panel.ixTooltip) then
			return ixChangeTooltip(panel, ...)
		end

		RemoveTooltip()

		timer.Create("ixTooltip", 0.1, 1, function()
			if (!IsValid(panel) or lastHover != panel) then
				return
			end

			tooltip = vgui.Create("ixTooltip")
			panel.ixTooltip(tooltip)
			tooltip:SizeToContents()
		end)

		lastHover = panel
	end

	function RemoveTooltip() -- luacheck: globals RemoveTooltip
		if (IsValid(tooltip)) then
			tooltip:Remove()
			tooltip = nil
		end

		timer.Remove("ixTooltip")
		lastHover = nil

		return ixRemoveTooltip()
	end
end

-- tooltip row
DEFINE_BASECLASS("DLabel")
local PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "maxWidth", "MaxWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "bNoMinimal", "MinimalHidden", FORCE_BOOL)

function PANEL:Init()
	self:SetFont("ixSmallFont")
	self:SetText(L("unknown"))
	self:SetTextColor(color_white)
	self:SetTextInset(4, 0)
	self:SetContentAlignment(4)
	self:Dock(TOP)

	self.maxWidth = ScrW() * 0.2
	self.bNoMinimal = false
	self.bMinimal = false
end

function PANEL:IsMinimal()
	return self.bMinimal
end

-- changes font and background color to reduce repetition for titles
function PANEL:SetImportant()
	self:SetFont("ixSmallTitleFont")
	self:SetExpensiveShadow(1, color_black)
	self:SetBackgroundColor(ix.config.Get("color"))
end

function PANEL:SetBackgroundColor(color)
	color = table.Copy(color)
	color.a = math.min(color.a or 255, 100)

	self.backgroundColor = color
end

function PANEL:SizeToContents()
	local contentWidth, contentHeight = self:GetContentSize()
	contentWidth = contentWidth + 4
	contentHeight = contentHeight + 4

	if (contentWidth > self.maxWidth) then
		self:SetWide(self.maxWidth - 4) -- to account for text inset
		self:SetTextInset(4, 0)
		self:SetWrap(true)

		self:SizeToContentsY()
		self:SetWide(self:GetContentSize())
	else
		self:SetSize(contentWidth, contentHeight)
	end
end

function PANEL:SizeToContentsY()
	BaseClass.SizeToContentsY(self)
	self:SetTall(self:GetTall() + 4)
end

-- easy method in case paint is overridden
function PANEL:PaintBackground(width, height)
	if (self.backgroundColor) then
		derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, self.backgroundColor)
	end
end

function PANEL:Paint(width, height)
	self:PaintBackground(width, height)
end

vgui.Register("ixTooltipRow", PANEL, "DLabel")

-- tooltip
DEFINE_BASECLASS("Panel")
PANEL = {}

AccessorFunc(PANEL, "entity", "Entity")
AccessorFunc(PANEL, "mousePadding", "MousePadding", FORCE_NUMBER)
AccessorFunc(PANEL, "bDrawArrow", "DrawArrow", FORCE_BOOL)
AccessorFunc(PANEL, "arrowColor", "ArrowColor")
AccessorFunc(PANEL, "bHideArrowWhenRaised", "HideArrowWhenRaised", FORCE_BOOL)
AccessorFunc(PANEL, "bArrowFollowEntity", "ArrowFollowEntity", FORCE_BOOL)

function PANEL:Init()
	self.fraction = 0
	self.mousePadding = 16
	self.arrowColor = ix.config.Get("color")
	self.bHideArrowWhenRaised = true
	self.bArrowFollowEntity = true
	self.bMinimal = false

	self.lastX, self.lastY = self:GetCursorPosition()
	self.arrowX, self.arrowY = ScrW() * 0.5, ScrH() * 0.5

	self:SetAlpha(0)
	self:SetSize(0, 0)
	self:SetDrawOnTop(true)

	self:CreateAnimation(animationTime, {
		index = 1,
		target = {fraction = 1},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.fraction * 255)
		end
	})
end

function PANEL:IsMinimal()
	return self.bMinimal
end

-- ensure all children are painted manually
function PANEL:Add(...)
	local panel = BaseClass.Add(self, ...)
	panel:SetPaintedManually(true)

	return panel
end

function PANEL:AddRow(id)
	local panel = self:Add("ixTooltipRow")
	panel.id = id
	panel:SetZPos(#self:GetChildren() * 10)

	return panel
end

function PANEL:AddRowAfter(after, id)
	local panel = self:AddRow(id)
	after = self:GetRow(after)

	if (!IsValid(after)) then
		return panel
	end

	panel:SetZPos(after:GetZPos() + 1)

	return panel
end

function PANEL:SetEntity(entity)
	if (!IsValid(entity)) then
		self.bEntity = false
		return
	end

	-- don't show entity tooltips if we have an entity menu open
	if (IsValid(ix.menu.panel)) then
		self:Remove()
		return
	end

	if (entity:IsPlayer()) then
		local character = entity:GetCharacter()

		if (character) then
			-- we want to group things that will most likely have backgrounds (e.g name/health status)
			hook.Run("PopulateImportantCharacterInfo", entity, character, self)
			hook.Run("PopulateCharacterInfo", entity, character, self)
		end
	else
		if (entity.OnPopulateEntityInfo) then
			entity:OnPopulateEntityInfo(self)
		else
			hook.Run("PopulateEntityInfo", entity, self)
		end
	end

	self:SizeToContents()

	self.entity = entity
	self.bEntity = true
end

function PANEL:PaintUnder(width, height)
end

function PANEL:Paint(width, height)
	self:PaintUnder()

	-- directional arrow
	self.bRaised = LocalPlayer():IsWepRaised()

	if (!self.bClosing) then
		if (self.bEntity and IsValid(self.entity) and self.bArrowFollowEntity) then
			local entity = self.entity
			local position = select(1, entity:GetBonePosition(entity:LookupBone("ValveBiped.Bip01_Spine") or -1)) or
				entity:LocalToWorld(entity:OBBCenter())

			position = position:ToScreen()
			self.arrowX = math.Clamp(position.x, 0, ScrW())
			self.arrowY = math.Clamp(position.y, 0, ScrH())
		end
	end

	-- arrow
	if (self.bDrawArrow or (self.bDrawArrow and self.bRaised and !self.bHideArrowWhenRaised)) then
		local x, y = self:ScreenToLocal(self.arrowX, self.arrowY)

		DisableClipping(true)
			surface.SetDrawColor(self.arrowColor)
			surface.DrawLine(0, 0, x * self.fraction, y * self.fraction)
			surface.DrawRect((x - 2) * self.fraction, (y - 2) * self.fraction, 4, 4)
		DisableClipping(false)
	end

	-- contents
	local x, y = self:GetPos()

	render.SetScissorRect(x, y, x + width * self.fraction, y + height, true)
		derma.SkinFunc("PaintTooltipBackground", self, width, height)

		for _, v in ipairs(self:GetChildren()) do
			if (IsValid(v)) then
				v:PaintManual()
			end
		end
	render.SetScissorRect(0, 0, 0, 0, false)
end

function PANEL:GetCursorPosition()
	local width, height = self:GetSize()
	local mouseX, mouseY = gui.MousePos()

	return math.Clamp(mouseX + self.mousePadding, 0, ScrW() - width), math.Clamp(mouseY, 0, ScrH() - height)
end

function PANEL:Think()
	if (!self.bEntity) then
		if (!vgui.CursorVisible()) then
			self:SetPos(self.lastX, self.lastY)

			-- if the cursor isn't visible then we don't really need the tooltip to be shown
			if (!self.bClosing) then
				self:Remove()
			end
		else
			local newX, newY = self:GetCursorPosition()

			self:SetPos(newX, newY)
			self.lastX, self.lastY = newX, newY
		end

		self:MoveToFront() -- dragging a panel w/ tooltip will push the tooltip beneath even the menu panel(???)
	elseif (IsValid(self.entity) and !self.bClosing) then
		if (self.bRaised) then
			self:SetPos(
				ScrW() * 0.5 - self:GetWide() * 0.5,
				math.min(ScrH() * 0.5 + self:GetTall() + 32, ScrH() - self:GetTall())
			)
		else
			local entity = self.entity
			local min, max = entity:GetRotatedAABB(entity:OBBMins() * 0.5, entity:OBBMaxs() * 0.5)
			min = entity:LocalToWorld(min):ToScreen().x
			max = entity:LocalToWorld(max):ToScreen().x

			self:SetPos(
				math.Clamp(math.max(min, max), ScrW() * 0.5 + 32, ScrW() * 0.66 - self:GetWide()),
				ScrH() * 0.5 - self:GetTall() * 0.5
			)
		end
	end
end

function PANEL:GetRow(id)
	for _, v in ipairs(self:GetChildren()) do
		if (IsValid(v) and v.id == id) then
			return v
		end
	end
end

function PANEL:SizeToContents()
	local height = 0
	local width = 0

	for _, v in ipairs(self:GetChildren()) do
		if (v:GetWide() > width) then
			width = v:GetWide()
		end

		height = height + v:GetTall()
	end

	self:SetSize(width, height)
end

function PANEL:Remove()
	if (self.bClosing) then
		return
	end

	self.bClosing = true
	self:CreateAnimation(animationTime * 0.5, {
		target = {fraction = 0},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.fraction * 255)
		end,

		OnComplete = function(animation, panel)
			BaseClass.Remove(panel)
		end
	})
end

vgui.Register("ixTooltip", PANEL, "Panel")

-- legacy tooltip row

PANEL = {}

function PANEL:Init()
	self.bMinimal = true
	self.ixAlpha = 0 -- to avoid conflicts if we're animating a non-tooltip panel

	self:SetExpensiveShadow(1, color_black)
	self:SetContentAlignment(5)
end

function PANEL:SetImportant()
	self:SetFont("ixMinimalTitleFont")
	self:SetBackgroundColor(ix.config.Get("color"))
end

-- background color will affect text instead in minimal tooltips
function PANEL:SetBackgroundColor(color)
	color = table.Copy(color)
	color.a = math.min(color.a or 255, 100)

	self:SetTextColor(color)
	self.backgroundColor = color
end

function PANEL:PaintBackground()
end

vgui.Register("ixTooltipMinimalRow", PANEL, "ixTooltipRow")

-- legacy tooltip
DEFINE_BASECLASS("ixTooltip")
PANEL = {}

function PANEL:Init()
	self.bMinimal = true

	-- we don't want to animate the alpha since children will handle their own animation, but we want to keep the fraction
	-- for the background to animate
	self:CreateAnimation(animationTime, {
		index = 1,
		target = {fraction = 1},
		easing = "outQuint",
	})

	self:SetAlpha(255)
end

-- we don't need the children to be painted manually
function PANEL:Add(...)
	local panel = BaseClass.Add(self, ...)
	panel:SetPaintedManually(false)

	return panel
end

function PANEL:AddRow(id)
	local panel = self:Add("ixTooltipMinimalRow")
	panel.id = id
	panel:SetZPos(#self:GetChildren() * 10)

	return panel
end

function PANEL:Paint(width, height)
	self:PaintUnder()

	derma.SkinFunc("PaintTooltipMinimalBackground", self, width, height)
end

function PANEL:Think()
end

function PANEL:SizeToContents()
	-- remove any panels that shouldn't be shown in a minimal tooltip
	for _, v in ipairs(self:GetChildren()) do
		if (v.bNoMinimal) then
			v:Remove()
		end
	end

	BaseClass.SizeToContents(self)
	self:SetPos(ScrW() * 0.5 - self:GetWide() * 0.5, ScrH() * 0.5 + self.mousePadding)

	-- we create animation here since this is the only function that usually gets called after all the rows are populated
	local children = self:GetChildren()

	-- sort by z index so we can animate them in order
	table.sort(children, function(a, b)
		return a:GetZPos() < b:GetZPos()
	end)

	local i = 1
	local count = table.Count(children)

	for _, v in ipairs(children) do
		v.ixAlpha = v.ixAlpha or 0

		v:CreateAnimation((animationTime / count) * i, {
			easing = "inSine",
			target = {ixAlpha = 255},
			Think = function(animation, panel)
				panel:SetAlpha(panel.ixAlpha)
			end
		})

		i = i + 1
	end
end

DEFINE_BASECLASS("Panel")
function PANEL:Remove()
	if (self.bClosing) then
		return
	end

	self.bClosing = true

	-- we create animation here since this is the only function that usually gets called after all the rows are populated
	local children = self:GetChildren()

	-- sort by z index so we can animate them in order
	table.sort(children, function(a, b)
		return a:GetZPos() > b:GetZPos()
	end)

	local duration = animationTime * 0.5
	local i = 1
	local count = table.Count(children)

	for _, v in ipairs(children) do
		v.ixAlpha = v.ixAlpha or 255

		v:CreateAnimation(duration / count * i, {
			target = {ixAlpha = 0},
			Think = function(animation, panel)
				panel:SetAlpha(panel.ixAlpha)
			end
		})

		i = i + 1
	end

	self:CreateAnimation(duration, {
		target = {fraction = 0},
		OnComplete = function(animation, panel)
			BaseClass.Remove(panel)
		end
	})
end

vgui.Register("ixTooltipMinimal", PANEL, "ixTooltip")
