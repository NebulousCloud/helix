
-- area entry
DEFINE_BASECLASS("Panel")
local PANEL = {}

AccessorFunc(PANEL, "text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "tickSound", "TickSound", FORCE_STRING)
AccessorFunc(PANEL, "tickSoundRange", "TickSoundRange")
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "expireTime", "ExpireTime", FORCE_NUMBER)
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)

function PANEL:Init()
	self:DockPadding(4, 4, 4, 4)
	self:SetSize(self:GetParent():GetWide(), 0)

	self.label = self:Add("DLabel")
	self.label:Dock(FILL)
	self.label:SetFont("ixMediumLightFont")
	self.label:SetTextColor(color_white)
	self.label:SetExpensiveShadow(1, color_black)
	self.label:SetText("Area")

	self.text = ""
	self.tickSound = "ui/buttonrollover.wav"
	self.tickSoundRange = {190, 200}
	self.backgroundAlpha = 255
	self.expireTime = 8
	self.animationTime = 2

	self.character = 1
	self.createTime = RealTime()
	self.currentAlpha = 255
	self.currentHeight = 0
	self.nextThink = RealTime()
end

function PANEL:Show()
	self:CreateAnimation(0.5, {
		index = -1,
		target = {currentHeight = self.label:GetTall() + 8},
		easing = "outQuint",

		Think = function(animation, panel)
			panel:SetTall(panel.currentHeight)
		end
	})
end

function PANEL:SetFont(font)
	self.label:SetFont(font)
end

function PANEL:SetText(text)
	if (text:sub(1, 1) == "@") then
		text = L(text:sub(2))
	end

	self.label:SetText(text)
	self.text = text
	self.character = 1
end

function PANEL:Think()
	local time = RealTime()

	if (time >= self.nextThink) then
		if (self.character < self.text:utf8len()) then
			self.character = self.character + 1
			self.label:SetText(string.utf8sub(self.text, 1, self.character))

			LocalPlayer():EmitSound(self.tickSound, 100, math.random(self.tickSoundRange[1], self.tickSoundRange[2]))
		end

		if (time >= self.createTime + self.expireTime and !self.bRemoving) then
			self:Remove()
		end

		self.nextThink = time + 0.05
	end
end

function PANEL:SizeToContents()
	self:SetWide(self:GetParent():GetWide())

	self.label:SetWide(self:GetWide())
	self.label:SizeToContentsY()
end

function PANEL:Paint(width, height)
	self.backgroundAlpha = math.max(self.backgroundAlpha - 200 * FrameTime(), 0)

	derma.SkinFunc("PaintAreaEntry", self, width, height)
end

function PANEL:Remove()
	if (self.bRemoving) then
		return
	end

	self:CreateAnimation(self.animationTime, {
		target = {currentAlpha = 0},

		Think = function(animation, panel)
			panel:SetAlpha(panel.currentAlpha)
		end,

		OnComplete = function(animation, panel)
			panel:CreateAnimation(0.5, {
				index = -1,
				target = {currentHeight = 0},
				easing = "outQuint",

				Think = function(_, sizePanel)
					sizePanel:SetTall(sizePanel.currentHeight)
				end,

				OnComplete = function(_, sizePanel)
					sizePanel:OnRemove()
					BaseClass.Remove(sizePanel)
				end
			})
		end
	})

	self.bRemoving = true
end

function PANEL:OnRemove()
end

vgui.Register("ixAreaEntry", PANEL, "Panel")

-- main panel
PANEL = {}

function PANEL:Init()
	local chatWidth, _ = chat.GetChatBoxSize()
	local _, chatY = chat.GetChatBoxPos()

	self:SetSize(chatWidth, chatY)
	self:SetPos(32, 0)
	self:ParentToHUD()

	self.entries = {}
	ix.gui.area = self
end

function PANEL:AddEntry(entry, color)
	color = color or ix.config.Get("color")

	local id = #self.entries + 1
	local panel = entry

	if (isstring(entry)) then
		panel = self:Add("ixAreaEntry")
		panel:SetText(entry)
	end

	panel:SetBackgroundColor(color)
	panel:SizeToContents()
	panel:Dock(BOTTOM)
	panel:Show()
	panel.OnRemove = function()
		for k, v in pairs(self.entries) do
			if (v == panel) then
				table.remove(self.entries, k)
				break
			end
		end
	end

	self.entries[id] = panel
	return id
end

function PANEL:GetEntries()
	return self.entries
end

vgui.Register("ixArea", PANEL, "Panel")
