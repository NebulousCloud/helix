
local animationTime = 0.75

-- notice manager
-- this manages positions/animations for notice panels
local PANEL = {}

AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)

function PANEL:Init()
	self:SetSize(ScrW() * 0.4, ScrH())
	self:SetPos(ScrW() - ScrW() * 0.4, 0)
	self:SetZPos(-99999)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)

	self.notices = {}
	self.padding = 4
end

function PANEL:GetAll()
	return self.notices
end

function PANEL:Clear()
	for _, v in ipairs(self.notices) do
		self:RemoveNotice(v)
	end
end

function PANEL:AddNotice(text, bError)
	if (IsValid(ix.gui.characterMenu) and !ix.gui.characterMenu.bClosing) then
		return
	end

	local panel = self:Add("ixNotice")
	panel:SetText(text)
	panel:SetError(bError or text:sub(#text, #text) == "!")
	panel:SizeToContents()
	panel.currentY = -panel:GetTall()
	panel:SetPos(self.padding, panel.currentY)

	-- setup duration timer
	panel:CreateAnimation(ix.option.Get("noticeDuration", 8), {
		index = 2,
		target = {duration = 1},
		bIgnoreConfig = true,

		OnComplete = function(animation, this)
			self:RemoveNotice(this)
		end
	})

	table.insert(self.notices, 1, panel)
	self:Organize()

	-- remove old notice if we've hit the limit of notices
	if (#self.notices > ix.option.Get("noticeMax", 4)) then
		for i = #self.notices, 1, -1 do
			local notice = self.notices[i]

			if (IsValid(notice) and !notice.bClosing) then
				self:RemoveNotice(notice)
				break
			end
		end
	end

	return panel
end

function PANEL:RemoveNotice(panel)
	panel.bClosing = true
	panel:CreateAnimation(animationTime, {
		index = 3,
		target = {outAnimation = 0},
		easing = "outQuint",

		OnComplete = function(animation, this)
			local toRemove

			for k, v in ipairs(self.notices) do
				if (v == this) then
					toRemove = k
					break
				end
			end

			if (toRemove) then
				table.remove(self.notices, toRemove)
			end

			this:SetText("") -- (hack) text remains for a frame after remove is called, so let's make sure we don't draw it
			this:Remove()
		end
	})
end

-- update target Y positions and animations
function PANEL:Organize()
	local currentTarget = self.padding

	for _, v in ipairs(self.notices) do
		v:CreateAnimation(animationTime, {
			index = 1,
			target = {currentY = currentTarget},
			easing = "outElastic",

			Think = function(animation, panel)
				panel:SetPos(
					self:GetWide() - panel:GetWide() - self.padding,
					math.min(panel.currentY + 1, currentTarget) -- easing eventually hits subpixel movement so we level it off
				)
			end
		})

		currentTarget = currentTarget + self.padding + v:GetTall()
	end
end

vgui.Register("ixNoticeManager", PANEL, "Panel")

-- notice panel
-- these do not manage their own enter/exit animations or lifetime
DEFINE_BASECLASS("DLabel")
PANEL = {}

AccessorFunc(PANEL, "bError", "Error", FORCE_BOOL)
AccessorFunc(PANEL, "padding", "Padding", FORCE_NUMBER)

function PANEL:Init()
	self:SetSize(256, 36)
	self:SetContentAlignment(5)
	self:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	self:SetFont("ixNoticeFont")
	self:SetTextColor(color_white)
	self:SetDrawOnTop(true)
	self:DockPadding(0, 0, 0, 0)
	self:DockMargin(0, 0, 0, 0)

	self.bError = false
	self.bHovered = false

	self.errorAnimation = 0
	self.padding = 8
	self.currentY = 0
	self.duration = 0
	self.outAnimation = 1
	self.alpha = 255

	LocalPlayer():EmitSound("Helix.Notify")
end

function PANEL:SetError(bValue)
	self.bError = tobool(bValue)

	if (bValue) then
		self.errorAnimation = 1
		self:CreateAnimation(animationTime, {
			index = 5,
			target = {errorAnimation = 0},
			easing = "outQuint"
		})
	end
end

function PANEL:SizeToContents()
	local contentWidth, contentHeight = self:GetContentSize()
	contentWidth = contentWidth + self.padding * 2
	contentHeight = contentHeight + self.padding * 2

	local manager = ix.gui.notices
	local maxWidth = math.min(IsValid(manager) and (manager:GetWide() - manager:GetPadding() * 2) or ScrW(), contentWidth)

	if (contentWidth > maxWidth) then
		self:SetWide(maxWidth)
		self:SetTextInset(self.padding * 2, 0)
		self:SetWrap(true)

		self:SizeToContentsY()
		self:SetWide(self:GetContentSize())
	else
		self:SetSize(contentWidth, contentHeight)
	end
end

function PANEL:SizeToContentsY()
	BaseClass.SizeToContentsY(self)
	self:SetTall(self:GetTall() + self.padding * 2)
end

function PANEL:OnMouseHover()
	self:CreateAnimation(animationTime * 0.5, {
		index = 4,
		target = {alpha = 0},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.alpha)
		end
	})
end

function PANEL:OnMouseLeave()
	self:CreateAnimation(animationTime * 0.5, {
		index = 4,
		target = {alpha = 255},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetAlpha(panel.alpha)
		end
	})
end

function PANEL:Paint(width, height)
	if (self.outAnimation < 1) then
		local x, y = self:LocalToScreen(0, 0)
		render.SetScissorRect(x, y, x + self:GetWide(), y + (self:GetTall() * self.outAnimation), true)
	end

	local x, y = self:LocalToScreen(0, 0)
	local mouseX, mouseY = gui.MousePos()

	if (mouseX >= x and mouseX <= x + width and
		mouseY >= y and mouseY <= y + height) then
		if (!self.bHovered) then
			self.bHovered = true
			self:OnMouseHover()
		end
	elseif (self.bHovered) then
		self.bHovered = false
		self:OnMouseLeave()
	end

	ix.util.DrawBlur(self)

	if (self.errorAnimation > 0) then
		local color = derma.GetColor("Error", self)

		surface.SetDrawColor(
			color.r * self.errorAnimation,
			color.g * self.errorAnimation,
			color.b * self.errorAnimation,
			self.errorAnimation * 255 + ((1 - self.errorAnimation) * 66)
		)
	else
		surface.SetDrawColor(0, 0, 0, 66)
	end

	surface.DrawRect(0, 0, width, height)

	surface.SetDrawColor(self.bError and derma.GetColor("Error", self) or ix.config.Get("color"))
	surface.DrawRect(0, height - 1, width * self.duration, 1)
end

function PANEL:PaintOver(width, height)
	render.SetScissorRect(0, 0, 0, 0, false)
end

vgui.Register("ixNotice", PANEL, "DLabel")

if (IsValid(ix.gui.notices)) then
	ix.gui.notices:Remove()
	ix.gui.notices = vgui.Create("ixNoticeManager")
else
	ix.gui.notices = vgui.Create("ixNoticeManager")
end
