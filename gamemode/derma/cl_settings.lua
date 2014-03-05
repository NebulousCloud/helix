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

		local notice = self:Add("nut_NoticePanel")
		notice:Dock(TOP)
		notice:DockMargin(0, 0, 0, 5)
		notice:SetType(4)
		notice:SetText(nut.lang.Get("settings_tip"))

		self.category = {}
		self.options = {}

		hook.Run("AddSettingOptions", self)
	end

	function PANEL:AddCategory(name)
		local category = self.list:Add("DCollapsibleCategory")
		category:Dock(TOP)
		category:SetLabel(name)
		category:SetExpanded(true)
		category:DockMargin(5, 5, 5, 5)

		local list = vgui.Create("DPanelList")
		list:SetSpacing(5)
		list:SetAutoSize(true)
		list:EnableVerticalScrollbar(true)
		
		category:SetContents(list)
		category:InvalidateLayout(true)
		category.list = list

		self.category[#self.category] = category

		return category
	end
	
	function PANEL:AddSlider(category, name, min, max, var, demc)
		if (!category or !name or !min or !max or !var) then
			return
		end

		local slider = vgui.Create("DNumSlider")
		slider:Dock(TOP)
		slider:SetText(name)
		slider.Label:SetTextColor(Color(22, 22, 22))
		slider:SetMin(min)                
		slider:SetMax(max)
		slider:SetDecimals(demc or 0)
		slider:SetValue(nut.config[var])
		slider:DockMargin(10, 2, 0, 2)

		function slider:OnValueChanged(value)
			local value = self:GetValue()
			nut.config[var] = value
		end

		category.list:AddItem(slider)

		self.options[#self.options] = slider
	end
	
	function PANEL:AddChecker(category, name, var)
		if (!category or !name or !var) then
			return
		end

		local checker = vgui.Create("DCheckBoxLabel")
		checker:Dock(TOP)
		checker:SetText(name)
		checker:SetTextColor(Color(22, 22, 22))
		checker:SetValue((nut.config[var] == true) and 1 or 0)
		checker:DockMargin(10, 5, 0, 0)
		checker:SetTall(20)

		function checker:OnChange(value)
			nut.config[var] = value
		end

		category.list:AddItem(checker)

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
