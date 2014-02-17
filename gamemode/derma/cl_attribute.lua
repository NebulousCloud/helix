local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("attribute"))

		local noticePanel = self:Add( "nut_NoticePanel" )
		noticePanel:Dock( TOP )
		noticePanel:DockMargin( 0, 0, 0, 5 )
		noticePanel:SetType( 4 )
		noticePanel:SetText( nut.lang.Get("attribute_tip") )
		
		local noticePanel = self:Add( "nut_NoticePanel" )
		noticePanel:Dock( TOP )
		noticePanel:DockMargin( 0, 0, 0, 5 )
		noticePanel:SetType( 4 )
		noticePanel:SetText( nut.lang.Get("attribute_tip2") )

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.bars = {}

		for k, attribute in ipairs(nut.attribs.GetAll()) do
			local level = LocalPlayer():GetAttrib(k, 0)
			local bar = self.list:Add("nut_AttribBarVisOnly")
			bar:Dock(TOP)
			bar:DockMargin( 8, 10, 8, 0 )
			bar:SetMax(nut.config.startingPoints)
			bar:SetText(attribute.name)
			bar:SetToolTip(attribute.desc)
			bar:SetValue( level )
			bar:SetMax( nut.config.maximumPoints )
			self.bars[k] = bar
		end
	
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end

	function PANEL:Reload()
		local parent = self:GetParent()
		self:Remove()
		nut.gui.att = vgui.Create("nut_Attribute", parent)
		nut.gui.menu:SetCurrentMenu(nut.gui.att, true)
	end
vgui.Register("nut_Attribute", PANEL, "DFrame")