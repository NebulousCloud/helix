local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("settings"))

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)
		self.list:DockPadding(10, 10, 10, 10)

		local notice = self:Add( "nut_NoticePanel" )
		notice:Dock( TOP )
		notice:DockMargin( 0, 0, 0, 5 )
		notice:SetType( 4 )
		notice:SetText(nut.lang.Get("settings_tip"))

		self.category = {}
		self.options = {}


		hook.Run("AddSettingOptions", self)
	end

	function PANEL:AddCategory(name)
		local cat = self.list:Add("DCollapsibleCategory")
		cat:Dock(TOP)
		cat:SetLabel(name)
		cat:SetExpanded(true)
		cat:DockMargin(5, 5, 5, 5)

		local list = vgui.Create("DPanelList")
		list:SetSpacing(5)
		list:SetAutoSize(true)
		list:EnableVerticalScrollbar(true)
		--list:SetDrawBackground(true)
		cat:SetContents(list)

		cat:InvalidateLayout(true)
		cat.list = list

		self.category[#self.category] = cat
		return cat
	end
	
	function PANEL:AddSlider(category, name, min, max, var, demc)
		if (!category or !name or !min or !max or !var ) then

			return
		end

		local slder = vgui.Create("DNumSlider")
		slder:Dock(TOP)
		slder:SetText(name)
		slder.Label:SetTextColor(Color(22, 22, 22))
		slder:SetMin( min )                
		slder:SetMax( max )
		slder:SetDecimals( demc or 0 )
		slder:SetValue(nut.config[var])
		slder:DockMargin( 10, 2, 0, 2 )

		function slder:OnValueChanged( val )
			local val = self:GetValue()
			nut.config[var] = val
		end
		category.list:AddItem( slder )

		self.options[#self.options] = slder
	end
	
	function PANEL:AddChecker( category, name, var )
		if (!category or !name or !var) then

			return
		end
		local checker = vgui.Create("DCheckBoxLabel")
		checker:Dock(TOP)
		checker:SetText(name)
		checker:SetTextColor(Color(22, 22, 22))
		checker:SetValue((nut.config[var] == true) and 1 or 0)
		checker:DockMargin( 10, 5, 0, 0 )
		checker:SetTall(20)
		function checker:OnChange(val)
			nut.config[var] = val
		end
		category.list:AddItem( checker )

		self.options[#self.options] = checker
	end

	function PANEL:SyncContents()
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Settings", PANEL, "DFrame")
