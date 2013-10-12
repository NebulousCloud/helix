local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle("Moderator")

		self.list = self:Add("DCategoryList")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		self.catCommands = self.list:Add("Commands")
		self.catCommands:SetExpanded(false)

		self.catUsers = self.list:Add("Users")
		self.catUsers:SetExpanded(false)

		self.catBans = self.list:Add("Bans")
		self.catBans:SetExpanded(false)
	end

	function PANEL:Think()
		if (!self:IsActive()) then
			self:MakePopup()
		end
	end
vgui.Register("nut_Moderator", PANEL, "DFrame")

function PLUGIN:CreateMenuButtons(menu, addButton)
	addButton("mod", "Moderator", function()
		nut.gui.mod = vgui.Create("nut_Moderator", menu)
		menu:SetCurrentMenu(nut.gui.mod)
	end)
end