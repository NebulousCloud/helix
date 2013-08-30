local PANEL = {}
	function PANEL:Init()
		local width = ScrW() * 0.3

		self:SetSize(width, ScrH())
		self:SetPos(-width, 0)
		self:SetPaintBackground(false)
		self:MakePopup()
		self:MoveTo(0, 0, 0.25, 0, 0.15)

		self.buttonList = self:Add("DScrollPanel")
		self.buttonList:Dock(LEFT)
		self.buttonList:SetWide(ScrW() * 0.2)
		self.buttonList.Paint = function(panel, w, h)
			surface.SetDrawColor(25, 25, 25, 253)
			surface.DrawRect(0, 0, w, h)
		end

		self.close = self.buttonList:Add("nut_MenuButton")
		self.close:SetText(nut.lang.Get("return"))
		self.close:SetTall(48)
		self.close.OnClick = function()
			self:MoveTo(-width, 0, 0.25, 0, 0.15)

			if (IsValid(self.currentMenu)) then
				local width = self.currentMenu:GetWide()
				local x, y = self.currentMenu:GetPos()

				self.currentMenu:MoveTo(-width, y, 0.225, 0, 0.125)
			end

			gui.EnableScreenClicker(false)

			timer.Create("nut_CloseMenu", 0.25, 1, function()
				self:SetVisible(false)
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

			self:Remove()
		end)

		self.currentMenu = NULL

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
	end

	local gradient = surface.GetTextureID("gui/gradient")

	function PANEL:SetCurrentMenu(panel)
		if (IsValid(self.currentMenu)) then
			self.currentMenu:Remove()
		end

		if (IsValid(panel)) then
			self.currentMenu = panel
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

net.Receive("nut_ShowMenu", function(length)
	if (IsValid(nut.gui.menu)) then
		nut.gui.menu:Remove()
	end

	nut.gui.menu = vgui.Create("nut_Menu")
end)