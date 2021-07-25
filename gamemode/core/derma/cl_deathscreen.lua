
local PANEL = {}

function PANEL:Init()
	local scrW, scrH = ScrW(), ScrH()

	self:SetSize(scrW, scrH)
	self:SetPos(0, 0)

	local text = string.utf8upper(L("youreDead"))

	surface.SetFont("ixMenuButtonHugeFont")
	local textW, textH = surface.GetTextSize(text)

	self.label = self:Add("DLabel")
	self.label:SetPaintedManually(true)
	self.label:SetPos(scrW * 0.5 - textW * 0.5, scrH * 0.5 - textH * 0.5)
	self.label:SetFont("ixMenuButtonHugeFont")
	self.label:SetText(text)
	self.label:SizeToContents()

	self.progress = 0

	self:CreateAnimation(ix.config.Get("spawnTime", 5), {
		bIgnoreConfig = true,
		target = {progress = 1},

		OnComplete = function(animation, panel)
			if (!panel:IsClosing()) then
				panel:Close()
			end
		end
	})
end

function PANEL:Think()
	self.label:SetAlpha(((self.progress - 0.3) / 0.3) * 255)
end

function PANEL:IsClosing()
	return self.bIsClosing
end

function PANEL:Close()
	self.bIsClosing = true

	self:CreateAnimation(2, {
		index = 2,
		bIgnoreConfig = true,
		target = {progress = 0},

		OnComplete = function(animation, panel)
			panel:Remove()
		end
	})
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintDeathScreenBackground", self, width, height, self.progress)
		self.label:PaintManual()
	derma.SkinFunc("PaintDeathScreen", self, width, height, self.progress)
end

vgui.Register("ixDeathScreen", PANEL, "Panel")
