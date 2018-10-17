
local animationTime = 1
local padding = 32

-- entity menu button
DEFINE_BASECLASS("ixMenuButton")
local PANEL = {}

AccessorFunc(PANEL, "callback", "Callback")

function PANEL:Init()
	self:SetTall(ScrH() * 0.1)
	self:Dock(TOP)
end

function PANEL:DoClick()
	local bStatus = true
	local parent = ix.menu.panel
	local entity = parent:GetEntity()

	if (parent.bClosing) then
		return
	end

	if (isfunction(self.callback)) then
		bStatus = self.callback()
	end

	if (bStatus != false) then
		ix.menu.NetworkChoice(entity, self.originalText, bStatus)
	end

	parent:Remove()
end

function PANEL:SetText(text)
	self.originalText = text
	BaseClass.SetText(self, text)
end

vgui.Register("ixEntityMenuButton", PANEL, "ixMenuButton")

-- entity menu list
DEFINE_BASECLASS("EditablePanel")
PANEL = {}

function PANEL:Init()
	self.list = {}
end

function PANEL:AddOption(text, callback)
	local panel = self:Add("ixEntityMenuButton")
	panel:SetText(text)
	panel:SetCallback(callback)
	panel:Dock(TOP)

	if (self.bPaintedManually) then
		panel:SetPaintedManually(true)
	end

	self.list[#self.list + 1] = panel
end

function PANEL:SizeToContents()
	local height = 0

	for i = 1, #self.list do
		height = height + self.list[i]:GetTall()
	end

	self:SetSize(ScrW() * 0.5 - padding * 2, height)
end

function PANEL:Center()
	local parent = self:GetParent()

	self:SetPos(
		ScrW() * 0.5 + padding,
		parent:GetTall() * 0.5 - self:GetTall() * 0.5
	)
end

function PANEL:SetPaintedManually(bValue)
	if (bValue) then
		for i = 1, #self.list do
			self.list[i]:SetPaintedManually(true)
		end

		self.bPaintedManually = true
	end

	BaseClass.SetPaintedManually(self, bValue)
end

function PANEL:PaintManual()
	BaseClass.PaintManual(self)
	local list = self.list

	for i = 1, #list do
		list[i]:PaintManual()
	end
end

vgui.Register("ixEntityMenuList", PANEL, "EditablePanel")

-- entity menu
DEFINE_BASECLASS("EditablePanel")
PANEL = {}

AccessorFunc(PANEL, "entity", "Entity")
AccessorFunc(PANEL, "bClosing", "IsClosing", FORCE_BOOL)
AccessorFunc(PANEL, "desiredHeight", "DesiredHeight", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.menu.panel)) then
		self:Remove()
		return
	end

	-- close entity tooltip if it's open
	if (IsValid(ix.gui.entityInfo)) then
		ix.gui.entityInfo:Remove()
	end

	ix.menu.panel = self

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)

	self.list = self:Add("ixEntityMenuList")
	self.list:SetPaintedManually(true)

	self.desiredHeight = 0
	self.blur = 0
	self.alpha = 1
	self.bClosing = false
	self.lastPosition = vector_origin

	self:CreateAnimation(animationTime, {
		target = {blur = 1},
		easing = "outQuint"
	})

	self:MakePopup()
end

function PANEL:SetOptions(options)
	for k, v in pairs(options) do
		self.list:AddOption(k, v)
	end

	self.list:SizeToContents()
	self.list:Center()
end

function PANEL:GetApproximateScreenHeight(entity, distanceSqr)
	return IsValid(entity) and
		(entity:BoundingRadius() * (entity:IsPlayer() and 1.5 or 1) or 0) / math.sqrt(distanceSqr) * self:GetTall() or 0
end

function PANEL:Think()
	local entity = self.entity
	local distance = 0

	if (IsValid(entity)) then
		local position = entity:GetPos()
		distance = LocalPlayer():GetShootPos():DistToSqr(position)

		if (distance > 65536) then
			self:Remove()
			return
		end

		self.lastPosition = position
	end

	self.desiredHeight = math.max(self.list:GetTall() + padding * 2, self:GetApproximateScreenHeight(entity, distance))
end

function PANEL:Paint(width, height) -- luacheck: ignore 312
	local selfHalf = self:GetTall() * 0.5
	local entity = self.entity

	height = self.desiredHeight + padding * 2
	width = self.blur * width

	local y = selfHalf - height * 0.5

	DisableClipping(true) -- for cheap blur
	render.SetScissorRect(0, y, width, y + height, true)
		if (IsValid(entity)) then
			cam.Start3D()
				ix.util.ResetStencilValues()
				render.SetStencilEnable(true)
				cam.IgnoreZ(true)
					render.SetStencilWriteMask(1)
					render.SetStencilTestMask(1)
					render.SetStencilReferenceValue(1)

					render.SetStencilCompareFunction(STENCIL_ALWAYS)
					render.SetStencilPassOperation(STENCIL_REPLACE)
					render.SetStencilFailOperation(STENCIL_KEEP)
					render.SetStencilZFailOperation(STENCIL_KEEP)

					entity:DrawModel()

					render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
					render.SetStencilPassOperation(STENCIL_KEEP)

					cam.Start2D()
						ix.util.DrawBlur(self, 10)
					cam.End2D()
				cam.IgnoreZ(false)
				render.SetStencilEnable(false)
			cam.End3D()
		else
			ix.util.DrawBlur(self, 10)
		end
	render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)

	-- scissor again because 3d rendering messes with the clipping apparently?
	render.SetScissorRect(0, y, width, y + height, true)
		surface.SetDrawColor(ix.config.Get("color"))
		surface.DrawRect(ScrW() * 0.5, y + padding, 1, height - padding * 2)

		self.list:PaintManual()
	render.SetScissorRect(0, 0, 0, 0, false)
end

function PANEL:GetOverviewInfo(origin, angles)
	local entity = self.entity

	if (IsValid(entity)) then
		local radius = entity:BoundingRadius() * (entity:IsPlayer() and 0.5 or 1)
		local center = entity:LocalToWorld(entity:OBBCenter()) + LocalPlayer():GetRight() * radius

		return LerpAngle(self.bClosing and self.alpha or self.blur, angles, (center - origin):Angle())
	end

	return angles
end

function PANEL:OnMousePressed(code)
	if (code == MOUSE_LEFT) then
		self:Remove()
	end
end

function PANEL:Remove()
	if (self.bClosing) then
		return
	end

	self.bClosing = true

	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	gui.EnableScreenClicker(false)

	self:CreateAnimation(animationTime * 0.5, {
		target = {alpha = 0},
		index = 2,
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.alpha * 255)
		end,

		OnComplete = function(animation, panel)
			ix.menu.panel = nil
			BaseClass.Remove(self)
		end
	})
end

vgui.Register("ixEntityMenu", PANEL, "EditablePanel")
