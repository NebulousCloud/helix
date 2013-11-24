local PANEL = {}
	function PANEL:Init()
		self:SetPos(ScrW() * 0.375, ScrH() * 0.125)
		self:SetSize(ScrW() * nut.config.menuWidth, ScrH() * nut.config.menuHeight)
		self:MakePopup()
		self:SetTitle(nut.lang.Get("classes"))

		self.list = self:Add("DScrollPanel")
		self.list:Dock(FILL)
		self.list:SetDrawBackground(true)

		for k, v in SortedPairs(nut.class.GetByFaction(LocalPlayer():Team())) do
			if (LocalPlayer():CharClass() != k and v:PlayerCanJoin(LocalPlayer())) then
				local item = self.list:Add("nut_ClassItem")
				item:DockMargin(3, 3, 3, 0)
				item:Dock(TOP)
				item:SetClass(k)
			end
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

		nut.gui.classes = vgui.Create("nut_Classes", parent)
	end
vgui.Register("nut_Classes", PANEL, "DFrame")

local PANEL = {}
	function PANEL:Init()
		self:SetTall(48)

		self.icon = vgui.Create("SpawnIcon", self)
		self.icon:SetPos(4, 4)
		self.icon:SetSize(40, 40)
		self.icon:SetModel("models/error.mdl")
		self.icon:SetToolTip("No class set!")

		self.name = vgui.Create("DLabel", self)
		self.name:SetPos(48, 4)
		self.name:SetText("Class name")
		self.name:SetDark(true)
		self.name:SetFont("DermaDefaultBold")

		self.desc = vgui.Create("DLabel", self)
		self.desc:SetPos(48, 20)
		self.desc:SetText("Class desc")
		self.desc:SetDark(true)
	end

	function PANEL:SetClass(index)
		local class = nut.class.Get(index)

		if (!class) then
			return
		end

		self.class = class

		local model = class:GetModel()

		if (!model and class.faction) then
			local faction = nut.faction.GetByID(class.faction)
			local gender = LocalPlayer().character:GetVar("gender", "male")

			model = table.Random(faction[gender.."Models"])
		end

		if (model) then
			self.icon:SetModel(model, class:GetSkin())
		end

		self.name:SetText(class.name)
		self.name:SizeToContents()

		self.desc:SetText(class.desc or nut.lang.Get("no_desc"))
		self.desc:SizeToContents()

		self.icon:SetToolTip("Click to join the "..class.name.." class.")
		self.icon.DoClick = function(panel)
			netstream.Start("nut_ChooseClass", index)

			timer.Simple(0.25, function()
				nut.gui.classes:Reload()
			end)
		end
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(40, 40, 40, 60)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(100, 100, 100, 20)
		surface.DrawRect(0, 0, w, h)
	end
vgui.Register("nut_ClassItem", PANEL, "DPanel")