local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW(), ScrH())
		self:SetPaintBackground(false)
		self:MakePopup()

		self.buttonList = self:Add("DScrollPanel")
		self.buttonList:Dock(LEFT)
		self.buttonList:SetWide(ScrW() * 0.2)
		self.buttonList:DockMargin(64, 64, 64, 64)

		self.close = self.buttonList:Add("nut_MenuButton")
		self.close:SetText(nut.lang.Get("return"))
		self.close.OnClick = function()
			self:SetVisible(false)
		end
		self.close:DockMargin(0, 0, 0, 64)

		self.char = self.buttonList:Add("nut_MenuButton")
		self.char:SetText(nut.lang.Get("characters"))
		self.char:DockMargin(0, 0, 0, 8)
		self.char.OnClick = function()
			nut.gui.charMenu = vgui.Create("nut_CharMenu")

			self:Remove()
		end

		self.currentMenu = NULL

		if (nut.config.businessEnabled and nut.schema.Call("PlayerCanSeeBusiness")) then
			self.business = self.buttonList:Add("nut_MenuButton")
			self.business:SetText(nut.lang.Get("business"))
			self.business:DockMargin(0, 0, 0, 8)
			self.business.OnClick = function()
				nut.gui.business = vgui.Create("nut_Business", self)
				self:SetCurrentMenu(nut.gui.business)
			end
		end

		local count = 0

		for k, v in SortedPairs(nut.class.GetByFaction(LocalPlayer():Team())) do
			if (LocalPlayer():CharClass() != k and v:PlayerCanJoin(LocalPlayer())) then
				count = count + 1
			end
		end

		if (count > 0) then
			self.classes = self.buttonList:Add("nut_MenuButton")
			self.classes:SetText(nut.lang.Get("classes"))
			self.classes:DockMargin(0, 0, 0, 8)
			self.classes.OnClick = function()
				nut.gui.classes = vgui.Create("nut_Classes", self)
				self:SetCurrentMenu(nut.gui.classes)
			end
		end
		
		self.inv = self.buttonList:Add("nut_MenuButton")
		self.inv:SetText(nut.lang.Get("inventory"))
		self.inv:DockMargin(0, 0, 0, 8)
		self.inv.OnClick = function()
			nut.gui.inv = vgui.Create("nut_Inventory", self)
			self:SetCurrentMenu(nut.gui.inv)
		end

		self.help = self.buttonList:Add("nut_MenuButton")
		self.help:SetText(nut.lang.Get("help"))
		self.help:DockMargin(0, 0, 0, 8)
		self.help.OnClick = function()
			nut.gui.help = vgui.Create("nut_Help", self)
			self:SetCurrentMenu(nut.gui.help)
		end

		self.settings = self.buttonList:Add("nut_MenuButton")
		self.settings:SetText(nut.lang.Get("settings"))
		self.settings:DockMargin(0, 0, 0, 8)
		self.settings.OnClick = function()
			nut.gui.settings = vgui.Create("nut_Settings", self)
			self:SetCurrentMenu(nut.gui.settings)
		end

		nut.schema.Call("CreateMenuButtons", self.buttonList)
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
		surface.SetDrawColor(0, 0, 0, 245)
		surface.SetTexture(gradient)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end
vgui.Register("nut_Menu", PANEL, "DPanel")

net.Receive("nut_ShowMenu", function(length)
	if (IsValid(nut.gui.menu)) then
		nut.gui.menu:Remove()
	end

	nut.gui.menu = vgui.Create("nut_Menu")
end)