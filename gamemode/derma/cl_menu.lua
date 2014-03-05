local PANEL = {}
	function PANEL:Init()
		local width = ScrW() * 0.3

		self:SetSize(width, ScrH())
		self:SetPos(-width, 0)
		self:SetPaintBackground(false)
		self:MakePopup()
		self:MoveTo(0, 0, 0.25, 0, 0.15)
		self.closeGrace = RealTime() + 0.5

		self.buttonList = self:Add("DScrollPanel")
		self.buttonList:Dock(LEFT)
		self.buttonList:SetWide(ScrW() * 0.2)
		self.buttonList.Paint = function(panel, w, h)
			surface.SetDrawColor(25, 25, 25, 253)
			surface.DrawRect(0, 0, w, h)
		end

		self.side = vgui.Create("nut_MenuSide")
		
		self.close = self.buttonList:Add("nut_MenuButton")
		self.close:SetText(nut.lang.Get("return"))
		self.close:SetTall(48)
		self.close.OnClick = function()
			self:MoveTo(-width, 0, 0.25, 0, 0.5)

			if (IsValid(self.side)) then
				self.side:SlideOut()
			end

			if (IsValid(self.currentMenu)) then
				local x, y = self.currentMenu:GetPos()

				self.currentMenu:MoveTo(x, ScrH(), 0.225, 0, 0.125)
			end

			gui.EnableScreenClicker(false)

			timer.Create("nut_CloseMenu", 0.25, 1, function()
				if (IsValid(self)) then
					self:SetVisible(false)

					if (IsValid(self.currentMenu)) then
						self.currentMenu:Remove()
					end
				end
			end)
		end
		self.close:DockMargin(0, 0, 0, 64)

		local function addButton(id, text, onClick)
			local button = self.buttonList:Add("nut_MenuButton")
			button:SetText(text)
			button:DockMargin(0, 0, 0, 4)
			button:SetTall(48)
			button.OnClick = onClick

			self[id] = button
		end

		
		addButton("char", nut.lang.Get("characters"), function()
			nut.gui.charMenu = vgui.Create("nut_CharMenu")

			if (IsValid(self.side)) then
				self.side:SlideOut()
			end
			
			self:Remove()
		end)

		self.currentMenu = NULL

		addButton("att", nut.lang.Get("attribute"), function()
			nut.gui.att = vgui.Create("nut_Attribute", self)
			self:SetCurrentMenu(nut.gui.att)
		end)
		
		if (nut.config.businessEnabled and nut.schema.Call("PlayerCanSeeBusiness")) then
			addButton("business", nut.lang.Get("business"), function()
				nut.gui.business = vgui.Create("nut_Business", self)
				self:SetCurrentMenu(nut.gui.business)
			end)
		end

		local count = 0

		for k, v in SortedPairs(nut.class.GetByFaction(LocalPlayer():Team())) do
			if (LocalPlayer():CharClass() != k and v:PlayerCanJoin(LocalPlayer())) then
				count = count + 1
			end
		end

		if (count > 0) then
			addButton("classes", nut.lang.Get("classes"), function()
				nut.gui.classes = vgui.Create("nut_Classes", self)
				self:SetCurrentMenu(nut.gui.classes)
			end)
		end

		addButton("inv", nut.lang.Get("inventory"), function()
			nut.gui.inv = vgui.Create("nut_Inventory", self)
			self:SetCurrentMenu(nut.gui.inv)
		end)

		addButton("help", nut.lang.Get("help"), function()
			nut.gui.help = vgui.Create("nut_Help", self)
			self:SetCurrentMenu(nut.gui.help)
		end)

		nut.schema.Call("CreateMenuButtons", self, addButton)

		addButton("settings", nut.lang.Get("settings"), function()
			nut.gui.settings = vgui.Create("nut_Settings", self)
			self:SetCurrentMenu(nut.gui.settings)
		end)

	end

	local gradient = surface.GetTextureID("gui/gradient")

	function PANEL:OnKeyCodePressed(key)
		if (self.closeGrace <= RealTime() and key == KEY_F1) then
			self.close.OnClick()
		end
	end

	function PANEL:SetCurrentMenu(panel, noAnim)
		if (noAnim) then
			self.currentMenu = panel
		else
			local transitionTime = 0.2

			if (IsValid(self.currentMenu)) then
				local x, y = self.currentMenu:GetPos()
				local menu = self.currentMenu

				menu:MoveTo(x, ScrH(), transitionTime, 0, 0.5)

				timer.Simple(0.25, function()
					if (IsValid(menu)) then
						menu:Remove()
					end
				end)
			end

			if (IsValid(panel)) then
				local x, y = panel:GetPos()
				local w, h = panel:GetSize()

				panel:SetPos(x, -h)
				panel:MoveTo(x, y, transitionTime, 0.15, 0.5)

				self.currentMenu = panel
			end
		end
	end

	function PANEL:Paint(w, h)
		local x, y = self:GetPos()
		x = x + ScrW() * 0.2

		surface.SetDrawColor(0, 0, 0, 200)
		surface.SetTexture(gradient)
		surface.DrawTexturedRect(x, y, ScrW() * 0.1, ScrH())
	end
vgui.Register("nut_Menu", PANEL, "DPanel")

netstream.Hook("nut_ShowMenu", function()
	if (IsValid(nut.gui.menu)) then
		nut.gui.menu:Remove()
	end

	nut.gui.menu = vgui.Create("nut_Menu")
end)