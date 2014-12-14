local PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.info)) then
			nut.gui.info:Remove()
		end

		nut.gui.info = self

		self:SetSize(780, 540)
		self:Center()
		self:MakePopup()
		self:SetVisible(false)
		self:ShowCloseButton(false)
		self:SetTitle("")

		self.model = self:Add("nutModelPanel")
		self.model:SetWide(250)
		self.model:Dock(LEFT)
		self.model:SetFOV(32)

		self.info = self:Add("DPanel")
		self.info:SetWide(512)
		self.info:Dock(RIGHT)
		self.info:SetDrawBackground(false)
		self.info:DockMargin(0, 36, 0, 0)

		self.name = self.info:Add("DLabel")
		self.name:SetFont("nutHugeFont")
		self.name:SetTall(60)
		self.name:Dock(TOP)
		self.name:SetTextColor(color_white)
		self.name:SetExpensiveShadow(1, Color(0, 0, 0, 150))

		self.desc = self.info:Add("DTextEntry")
		self.desc:Dock(TOP)
		self.desc:SetFont("nutMediumLightFont")
		self.desc:SetTall(28)
	end

	function PANEL:setup()
		self.desc:SetText(LocalPlayer():getChar():getDesc())
		self.desc.OnEnter = function(this, w, h)
			nut.command.send("chardesc", this:GetText())
		end

		self.name:SetText(LocalPlayer():Name())
		self.name.Think = function(this)
			this:SetText(LocalPlayer():Name())
		end
		self.model:SetModel(LocalPlayer():GetModel())
	end

	function PANEL:Paint(w, h)
	end

	function PANEL:Think()
		if (IsValid(g_ContextMenu) and !g_ContextMenu:IsVisible() and self:IsVisible() and !self.desc:IsEditing()) then
			self:SetVisible(false)
		end
	end
vgui.Register("nutCharInfo", PANEL, "DFrame")

if (IsValid(nut.gui.info)) then
	vgui.Create("nutCharInfo")
end