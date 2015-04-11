local PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.info)) then
			nut.gui.info:Remove()
		end

		nut.gui.info = self

		self:SetSize(ScrW() * 0.6, ScrH() * 0.7)
		self:Center()

		self.model = self:Add("nutModelPanel")
		self.model:SetWide(ScrW() * 0.25)
		self.model:Dock(LEFT)
		self.model:SetFOV(50)
		self.model.enableHook = true
		self.model.copyLocalSequence = true

		self.info = self:Add("DPanel")
		self.info:SetWide(ScrW() * 0.4)
		self.info:Dock(RIGHT)
		self.info:SetDrawBackground(false)
		self.info:DockMargin(150, ScrH() * 0.2, 0, 0)

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

		self.time = self.info:Add("DLabel")
		self.time:SetFont("nutMediumFont")
		self.time:SetTall(28)
		self.time:Dock(TOP)
		self.time:SetTextColor(color_white)
		self.time:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		
		self.money = self.info:Add("DLabel")
		self.money:Dock(TOP)
		self.money:SetFont("nutMediumFont")
		self.money:SetTextColor(color_white)
		self.money:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.money:DockMargin(0, 10, 0, 0)

		self.faction = self.info:Add("DLabel")
		self.faction:Dock(TOP)
		self.faction:SetFont("nutMediumFont")
		self.faction:SetTextColor(color_white)
		self.faction:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.faction:DockMargin(0, 10, 0, 0)

		local class = nut.class.list[LocalPlayer():getChar():getClass()]
		
		if (class) then
			self.class = self.info:Add("DLabel")
			self.class:Dock(TOP)
			self.class:SetFont("nutMediumFont")
			self.class:SetTextColor(color_white)
			self.class:SetExpensiveShadow(1, Color(0, 0, 0, 150))
			self.class:DockMargin(0, 10, 0, 0)
		end

		hook.Run("CreateCharInfoText", self)

		self.attribName = self.info:Add("DLabel")
		self.attribName:Dock(TOP)
		self.attribName:SetFont("nutMediumFont")
		self.attribName:SetTextColor(color_white)
		self.attribName:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.attribName:DockMargin(0, 10, 0, 0)
		self.attribName:SetText(L"attribs")

		self.attribs = self.info:Add("DScrollPanel")
		self.attribs:Dock(FILL)
		self.attribs:DockMargin(0, 10, 0, 0)

		hook.Run("CreateCharInfo", self)
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
		self.money:SetText(L("charMoney", nut.currency.get(LocalPlayer():getChar():getMoney())))
		self.faction:SetText(L("charFaction", L(team.GetName(LocalPlayer():Team()))))
		
		local format = "%A, %d %B %Y %X"
		
		self.time:SetText(L("curTime", os.date(format, nut.date.get())))
		self.time.Think = function(this)
			if ((this.nextTime or 0) < CurTime()) then
				this:SetText(L("curTime", os.date(format, nut.date.get())))
				this.nextTime = CurTime() + 0.5
			end
		end

		local class = nut.class.list[LocalPlayer():getChar():getClass()]
		if (class) then
			self.class:SetText(L("charClass", L(class.name)))
		end
		
		self.model:SetModel(LocalPlayer():GetModel())
		self.model.Entity:SetSkin(LocalPlayer():GetSkin())

		for k, v in ipairs(LocalPlayer():GetBodyGroups()) do
			self.model.Entity:SetBodygroup(v.id, LocalPlayer():GetBodygroup(v.id))
		end

		local ent = self.model.Entity
		if (ent and IsValid(ent)) then
			local mats = LocalPlayer():GetMaterials()
			for k, v in pairs(mats) do
				ent:SetSubMaterial(k - 1, LocalPlayer():GetSubMaterial(k - 1))
			end
		end

		for k, v in SortedPairsByMemberValue(nut.attribs.list, "name") do
			local bar = self.attribs:Add("nutAttribBar")
			bar:Dock(TOP)
			bar:DockMargin(0, 0, 0, 3)
			bar:setValue(LocalPlayer():getChar():getAttrib(k, 0))
			bar:setMax(nut.config.get("maxAttribs"))
			bar:setReadOnly()
			bar:setText(L(v.name))
		end

		hook.Run("OnCharInfoSetup", self)
	end

	function PANEL:Paint(w, h)
	end
vgui.Register("nutCharInfo", PANEL, "EditablePanel")