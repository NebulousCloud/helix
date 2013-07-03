local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("help"))

		local data = {}
		local help = {}

		function data:AddHelp(key, callback)
			help[key] = callback
		end

		hook.Run("BuildHelpOptions", data)

		local header = [[<body bgcolor="F7F7F7" style="font-family: Trebuchet MS">]]

		self.choice = self:Add("DComboBox")
		self.choice:DockMargin(1, 1, 1, 1)
		self.choice:Dock(TOP)
		self.choice.OnSelect = function(panel, index, value, data)
			if (help[value]) then
				local content = help[value]()

				self.html:SetHTML(header.."<h2>"..value.."</h2>"..content)
			end
		end

		self.html = self:Add("DHTML")
		self.html:Dock(FILL)
		self.html:DockMargin(2, 2, 2, 2)

		local first = true

		for k, v in SortedPairs(help) do
			self.choice:AddChoice(k, nil, first)

			first = false
		end
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Help", PANEL, "DFrame")